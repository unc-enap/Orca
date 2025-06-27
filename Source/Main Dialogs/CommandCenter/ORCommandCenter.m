//
//  ORCommandCenter.m
//  Orca
//
//  Created by Mark Howe on Thu Nov 06 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORCommandCenter.h"
#import "ORScriptIDEModel.h"
#import "ORCommandClient.h"
#import "NetSocket.h"
#import "ORAlarmCollection.h"
#import "ORTaskMaster.h"
#import "ORScriptRunner.h"
#import "SynthesizeSingleton.h"

NSString* ORCommandPortChangedNotification		= @"ORCommandPortChangedNotification";
NSString* ORCommandClientsChangedNotification	= @"ORCommandClientsChangedNotification";
NSString* ORCommandScriptChanged				= @"ORCommandScriptChanged";
NSString* ORCommandScriptCommentsChanged		= @"ORCommandScriptCommentsChanged";
NSString* ORCommandArgsChanged					= @"ORCommandArgsChanged";
NSString* ORCommandCommandChangedNotification	= @"ORCommandCommandChangedNotification";
NSString* ORCommandLastFileChangedNotification	= @"ORCommandLastFileChangedNotification";

@implementation ORCommandCenter

SYNTHESIZE_SINGLETON_FOR_ORCLASS(CommandCenter);

- (id) init
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    NSInteger port = [[NSUserDefaults standardUserDefaults] integerForKey: @"orca.CommandCenter.ListeningPort"];
    if(port==0)port = kORCommandPort;
	
    NSString* theScript = [[NSUserDefaults standardUserDefaults] objectForKey: @"orca.CommandCenter.script"];
    if(theScript)[self setScript:theScript];
	else [self setScript:@"function main()\n{\nprint \"hello\";\n}\n"];
	
	NSString* theComments = [[NSUserDefaults standardUserDefaults] objectForKey: @"orca.CommandCenter.scriptComments"];
    [self setScriptComments:theComments];
	
	//NSMutableArray* theArgs = [[[[NSUserDefaults standardUserDefaults] objectForKey: @"orca.CommandCenter.args"] mutableCopy] autorelease];
	//if(!theArgs){
	//	theArgs = [NSMutableArray arrayWithObjects:[NSDecimalNumber zero],[NSDecimalNumber zero],[NSDecimalNumber zero],
	//	[NSDecimalNumber zero],[NSDecimalNumber zero],nil];
	//}

    
    [self setSocketPort:(int)port];
    [self setClients:[NSMutableArray array]];
    [[self undoManager] enableUndoRegistration];
    NSArray* objectsToRegister = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsRespondingTo:@selector(commandID)];
    NSEnumerator* e = [objectsToRegister objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [self addDestination:obj];
    }
    [self registerNotificationObservers];
    
    if(socketPort)[self serve];
	
    return self;
}

- (void) dealloc
{
	//should never get here ... we are a singleton!
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [heartBeatTimer invalidate];
    [heartBeatTimer release];
    
    [clients release];
    [script release];
    [scriptComments release];
    [serverSocket setDelegate:nil];
    [serverSocket release];
    [destinationObjects release];
	[history release];
    [super dealloc];
}


#pragma mark •••Accessors


- (NSUndoManager *)undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

- (NSString*) script
{
	return script;
}

- (void) setScript:(NSString*)aString
{
	if(!aString)aString= @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setScript:script];
    [script autorelease];
    script = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCommandScriptChanged object:self];
    [[NSUserDefaults standardUserDefaults] setObject:script forKey:@"orca.CommandCenter.script"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*) scriptComments
{
	return scriptComments;
}

- (void) setScriptComments:(NSString*)aString
{
	if(!aString)aString= @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setScriptComments:scriptComments];
    [scriptComments autorelease];
    scriptComments = [aString copy];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCommandScriptCommentsChanged object:self];
    [[NSUserDefaults standardUserDefaults] setObject:scriptComments forKey:@"orca.CommandCenter.scriptComments"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) setScriptNoNote:(NSString*)aString
{
    [script autorelease];
    script = [aString copy];	
}

- (NSDictionary*) destinationObjects
{
    return destinationObjects;
}

- (void) setDestinationObjects:(NSMutableDictionary*)newDestinationObjects
{
    [destinationObjects autorelease];
    destinationObjects=[newDestinationObjects retain];
}

- (void) addDestination:(id)obj
{
    if(!destinationObjects){
        [self setDestinationObjects:[NSMutableDictionary dictionary]];
    }
    if([[obj commandID] length]!=0){
        [destinationObjects setObject:obj forKey:[obj commandID]];
    }
}

- (void) removeDestination:(id)obj
{
    if([[obj commandID] length]!=0){
        [destinationObjects removeObjectForKey:[obj commandID]];
    }
}

- (int) socketPort
{
    return socketPort;
}

- (void) setSocketPort:(int)aPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSocketPort:socketPort];
    
    socketPort = aPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCommandPortChangedNotification
                                                        object:self];
    [[NSUserDefaults standardUserDefaults] setInteger:socketPort forKey:@"orca.CommandCenter.ListeningPort"];
}

- (NSArray*)clients
{
    return clients;
}

- (void) setClients:(NSMutableArray*)someClients
{
    [someClients retain];
    [clients release];
    clients = someClients;
}

- (BOOL) clientWithNameExists:(NSString*)aName
{
    NSEnumerator* e = [clients objectEnumerator];
    ORCommandClient* theClient;
    while(theClient = [e nextObject]){
        if([[theClient name] isEqualToString:aName])return YES;
    }
	return NO;
}

- (NSUInteger) clientCount
{
    return [clients count];
}


- (void)serve
{
    if(serverSocket && ![self clientCount]){
        [serverSocket release];
        serverSocket = nil;
    }
    serverSocket = [[NetSocket netsocketListeningOnPort:socketPort] retain];
    [serverSocket scheduleOnCurrentRunLoop];
    [serverSocket setDelegate:self];
    
    NSLog( @"Orca Command: Ready for connections on port %d\n",socketPort );
}

#pragma mark •••Delegate Methods
- (void) clientChanged:(id)aClient
{
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:aClient forKey:@"client"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCommandClientsChangedNotification
                                                        object:self
													  userInfo:userInfo];
}

- (void)netsocket:(NetSocket*)inNetSocket connectionAccepted:(NetSocket*)inNewNetSocket
{
    
    //NSLog( @"ORCommand: New connection established\n" );
    
    ORCommandClient* client = [[[ORCommandClient alloc] initWithNetSocket:inNewNetSocket] autorelease];
    [client setDelegate:self];
    [client setTimeConnected:[NSDate date]];
    [self sendCurrentAlarms:client];
    [self sendCurrentRunStatus:client];
    
    if(!heartBeatTimer) {
        heartBeatTimer = [[NSTimer scheduledTimerWithTimeInterval:15.0 target:self selector:@selector(timeToBeat:) userInfo:nil repeats:YES]retain];
        [self sendHeartBeat:client];
    }
    [clients addObject:client];
    [self clientChanged:client];
}

- (void) clientDisconnected:(id)aClient
{
    [clients removeObject:aClient];
    [self clientChanged:aClient];
    
    if([clients count] == 0) {
        [heartBeatTimer invalidate];
        [heartBeatTimer release];
        heartBeatTimer = nil;
    }
    
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(objectsAdded:)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsRemoved:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmWasPosted:)
                         name : ORAlarmWasPostedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmWasCleared:)
                         name : ORAlarmWasClearedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(documentClosed:)
						 name : ORDocumentClosedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(taskListChanged:)
						 name : @"Running Tasks"
					   object : nil];
}

- (void) documentClosed:(NSNotification*)aNotification
{
    [heartBeatTimer invalidate];
    [heartBeatTimer release];
    heartBeatTimer = nil;
}

- (void) taskListChanged:(NSNotification*)aNotification
{
    NSEnumerator* e = [clients objectEnumerator];
    ORCommandClient* theClient;
    while(theClient = [e nextObject]){
        [theClient sendCmd:@"orcaTaskList" withString:[aNotification object]];
    }
}

- (void) objectsAdded:(NSNotification*)aNotification
{
    NSArray* theObjects = [[aNotification userInfo] objectForKey: ORGroupObjectList];
    NSEnumerator* e = [theObjects objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [self addDestination:obj];
    }
}

- (void) objectsRemoved:(NSNotification*)aNotification
{
    NSArray* theObjects = [[aNotification userInfo] objectForKey: ORGroupObjectList];
    NSEnumerator* e = [theObjects objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [self removeDestination:obj];
    }
}

- (void) alarmWasPosted:(NSNotification*)aNotification
{
    NSEnumerator* e = [clients objectEnumerator];
    ORCommandClient* theClient;
    while(theClient = [e nextObject]){
        [theClient sendCmd:@"postAlarm" withString:[[aNotification object] name]];
    }
}

- (void) alarmWasCleared:(NSNotification*)aNotification
{
    NSEnumerator* e = [clients objectEnumerator];
    ORCommandClient* theClient;
    while(theClient = [e nextObject]){
        [theClient sendCmd:@"clearAlarm" withString:[[aNotification object] name]];
    }
}


- (void) runStatusChanged:(NSNotification*)aNotification
{
    NSEnumerator* e = [clients objectEnumerator];
    ORCommandClient* theClient;
    while(theClient = [e nextObject]){
        [theClient sendCmd:@"runStatus" withString:[[[aNotification userInfo] objectForKey:ORRunStatusValue] stringValue]];
    }
}

- (void) timeToBeat:(NSTimer*)aTimer
{
    NSEnumerator* e = [clients objectEnumerator];
    ORCommandClient* theClient;
    while(theClient = [e nextObject]){
        [self sendHeartBeat:theClient];
    }
}

- (void) sendCmd:(NSString*)aCmd withString:(NSString*)aString
{
    NSEnumerator* e = [clients objectEnumerator];
    ORCommandClient* theClient;
    while(theClient = [e nextObject]){
        [theClient sendCmd:aCmd withString:aString];
    }
}

- (void) addCommandToHistory:(NSString*)aCommandString
{
	if(!history){
		history = [[NSMutableArray array] retain];
		historyIndex = 0;
	}
	if(aCommandString){
		[history addObject:aCommandString];
		if([history count] > 50)[history removeObjectAtIndex:0];
		historyIndex = (int)[history count]-1;
	}
}

- (void) handleLocalCommand:(NSString*)aCommandString
{
	[self addCommandToHistory:aCommandString];
	[self handleCommand:aCommandString fromClient:nil];
}

//a simple command parser. Turns a string into a selector and executes it.
- (void) handleCommand:(NSString*)aCommandString fromClient:(id)aClient
{
    NSCharacterSet* whiteset     = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet* delimiterset = [NSCharacterSet characterSetWithCharactersInString:@": "];
    NSCharacterSet* quoteSet = [NSCharacterSet characterSetWithCharactersInString:@"\""];
    NSCharacterSet* plistStartSet = [NSCharacterSet characterSetWithCharactersInString:@"{"];
    NSCharacterSet* plistEndSet = [NSCharacterSet characterSetWithCharactersInString:@"}"];
    NSCharacterSet* inverteddelimiterset = [delimiterset invertedSet];
    NSCharacterSet* trimSet = [NSCharacterSet characterSetWithCharactersInString:@" [];\n\r\t"];
	
    aCommandString = [[aCommandString componentsSeparatedByString:@"@\""] componentsJoinedByString:@"\""];
    
	//preprocess for plists
	NSString* theProcessedString = @"";
	NSMutableArray* embeddedPLists	= [NSMutableArray array];
	NSScanner* 	scanner  = [NSScanner scannerWithString:aCommandString];
	while(![scanner isAtEnd]) {
		NSString* embeddedPList;
		NSString* part;
		if([scanner scanUpToCharactersFromSet:plistStartSet intoString:&part]){
			if([scanner isAtEnd]){
				theProcessedString = [theProcessedString stringByAppendingString:@" "];
				theProcessedString = [theProcessedString stringByAppendingString:part];
			}
			else {
				theProcessedString = [theProcessedString stringByAppendingString:part];
				[scanner scanString:@"{" intoString:&part];
				theProcessedString = [theProcessedString stringByAppendingString:part];
				if([scanner scanUpToCharactersFromSet:plistEndSet intoString:&embeddedPList]){
					[scanner scanString:@"}" intoString:&part];
					theProcessedString = [theProcessedString stringByAppendingString:part];
					NSString* aPlist = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\r<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\r<plist version=\"1.0\">";
					aPlist = [aPlist stringByAppendingString:embeddedPList];
					aPlist = [aPlist stringByAppendingString:@"\r</plist>"];
					NSPropertyListFormat format;
					NSError *errorDesc = nil;
                    
                    
                    id anObj  = [NSPropertyListSerialization propertyListWithData:[aPlist dataUsingEncoding:NSASCIIStringEncoding]
                                                                           options: NSPropertyListMutableContainersAndLeaves
																		   format: &format 
                                                                            error: &errorDesc];
					if(anObj){
						[embeddedPLists addObject:anObj];
					}
					else {
						NSLogError(@"Invalid plist",@"Command Center",nil);
						return;
					}
				}
			}
		}
	}
	
	aCommandString = theProcessedString;

	//preprocess for strings with embedded quotes which cause a problem if there are colons in the string
	theProcessedString = @"";
	NSMutableArray* embeddedStrings	= [NSMutableArray array];
	scanner  = [NSScanner scannerWithString:aCommandString];
	while(![scanner isAtEnd]) {
		NSString* embeddedString;
		NSString* part;
		if([scanner scanUpToCharactersFromSet:quoteSet intoString:&part]){
			if([scanner isAtEnd]){
				theProcessedString = [theProcessedString stringByAppendingString:@" "];
				theProcessedString = [theProcessedString stringByAppendingString:part];
			}
			else {
				theProcessedString = [theProcessedString stringByAppendingString:part];
				[scanner scanString:@"\"" intoString:&part];
				theProcessedString = [theProcessedString stringByAppendingString:part];
				if([scanner scanUpToCharactersFromSet:quoteSet intoString:&embeddedString]){
					[scanner scanString:@"\"" intoString:&part];
					theProcessedString = [theProcessedString stringByAppendingString:part];
					theProcessedString = [theProcessedString stringByAppendingString:@" "];
					[embeddedStrings addObject:embeddedString];
				}
			}
		}
	}
	
	aCommandString = theProcessedString;

    NSArray*        allCmds         = [aCommandString componentsSeparatedByString:@";"];
    
    NSString* returnStringCode = nil;
    for(NSString* string in allCmds){
        returnStringCode = nil;
        if([string length]){
            NSArray* parts = [string componentsSeparatedByString:@"="];
            if([parts count] == 2){
                returnStringCode = [[parts objectAtIndex:0] stringByTrimmingCharactersInSet:trimSet] ;
                string = [parts objectAtIndex:1];
            }
            NSString*       oneCmd  = [string stringByTrimmingCharactersInSet:trimSet];
            
            if([oneCmd length] == 0)continue;
            
            NSScanner* 	scanner  = [NSScanner scannerWithString:oneCmd];
            
            NSMutableArray* cmdItems = [NSMutableArray array];
            
            //parse a string of the form [obj method:var1 name:var2 ....]
            NSString* objName;
            [scanner scanUpToCharactersFromSet:whiteset intoString:&objName];                       //get the objName
            
            while(![scanner isAtEnd]) {
                NSString*  result = [NSString string];
                [scanner scanUpToCharactersFromSet:inverteddelimiterset intoString:nil];            //skip leading delimiters
				if([scanner scanUpToCharactersFromSet:delimiterset intoString:&result]){            //store up to next delimiter
                    if([result length]){
                        [cmdItems addObject:result];
                    }
                }
            }
            
            //turn the array into a selector
            SEL theSelector = [NSInvocation makeSelectorFromArray:cmdItems];
            NSMutableArray* allObjs = [NSMutableArray array];
            id theObj = nil;
            if([objName isEqualToString:@"self"]){
                if(aClient) theObj = aClient;
                else        theObj = self;
                [allObjs addObject:theObj];
            }
            else {
                //find the destination for the command
                if([objName isEqualToString:@"ORTaskMaster"]){
                    theObj = [ORTaskMaster sharedTaskMaster];
                }
                else if([objName isEqualToString:@"ORAlarmCollection"]){
                    theObj = [ORAlarmCollection sharedAlarmCollection];
                }
                else theObj = [destinationObjects objectForKey:objName];
                if(!theObj){
                    //OK, the obj isn't one of the preloaded objects. It might be an object fullID identifier.
                    theObj = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:objName];
                    if(theObj){
                        [allObjs addObject:theObj];
                    }
                    else {
                        //finally, maybe it's just an object class name...send to all
                        [allObjs addObjectsFromArray:[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(objName)]];
                    }
                }
                else [allObjs addObject:theObj];
            }
            
            NSEnumerator* e = [allObjs objectEnumerator];
            while(theObj = [e nextObject]){
                if([theObj respondsToSelector:theSelector]){
                    NSMethodSignature* theSignature = [theObj methodSignatureForSelector:theSelector];
                    NSInvocation* theInvocation = [NSInvocation invocationWithMethodSignature:theSignature];
                    [theInvocation setSelector:theSelector];
                    int n = (int)[theSignature numberOfArguments]-2; //first two are hidden
                    int i;
                    int argI;
                    BOOL ok = YES;
					int argStringCount = 0;
					int argPListCount = 0;
                    for(i=1,argI=0 ; i<=n*2 ; i+=2,argI++){
						NSString* aCmdItem = [cmdItems objectAtIndex:i];
						if([aCmdItem isEqualToString:@"\"\""]){
							if(argStringCount < [embeddedStrings count]){
								aCmdItem = [embeddedStrings objectAtIndex:argStringCount];
								argStringCount++;
							}
						}
						else if([aCmdItem isEqualToString:@"{}"]){
							if(argPListCount < [embeddedPLists count]){
								aCmdItem = [embeddedPLists objectAtIndex:argPListCount];
								argPListCount++;
							}
						}
						
                        if(![theInvocation setArgument:argI to:aCmdItem]){
                            ok = NO;
                            break;
                        }
                    }
                    if(ok){
                        
                        [[self undoManager] disableUndoRegistration];
                        [theInvocation invokeWithTarget:theObj];
                        [[self undoManager] enableUndoRegistration];
                        
                        if(returnStringCode){
                            NSString* returnValueAsString = [NSString stringWithFormat:@"%@",[theInvocation returnValue]];
                            
                            if(aClient && aClient!=self)[aClient sendCmd:returnStringCode withString:returnValueAsString];
                            else NSLog(@"%@: %@\n",returnStringCode,returnValueAsString);
                        }
                        else {
                          if(aClient && aClient!=self)[aClient sendCmd:@"Success" withString:@"1"];
                        }
                    }
                }
                else {
                    [aClient sendCmd:@"Error" withString:@"Cmd Not Found"];
                    NSLog(@"Command not recognized: <%@>.\n",NSStringFromSelector(theSelector));
                }
            }
            if([allObjs count]==0){
                [aClient sendCmd:@"Error" withString:@"Obj Not Found"];
                NSLog(@"Comm Center: unable to process (%@)  \n",oneCmd);
            }
        }
    }
}

- (id) executeSimpleCommand:(NSString*)aCommandString;
{
    NSCharacterSet* whiteset     = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet* delimiterset = [NSCharacterSet characterSetWithCharactersInString:@": "];
    NSCharacterSet* inverteddelimiterset = [delimiterset invertedSet];
    NSCharacterSet* trimSet = [NSCharacterSet characterSetWithCharactersInString:@" [];\n\r\t"];
	NSString* returnValue = @"?";
	if([aCommandString length]){
				
		NSScanner* 	scanner  = [NSScanner scannerWithString:[aCommandString stringByTrimmingCharactersInSet:trimSet]];
		NSMutableArray* cmdItems = [NSMutableArray array];
		
		//parse a string of the form [obj method:var1 name:var2 ....]
		NSString* objName = nil;
		id theObj = nil;
		SEL theSelector = nil;
		if([scanner scanUpToCharactersFromSet:whiteset intoString:&objName]){                       //get the objName
			
			while(![scanner isAtEnd]) {
				NSString*  result = [NSString string];
				[scanner scanUpToCharactersFromSet:inverteddelimiterset intoString:nil];            //skip leading delimiters
				if([scanner scanUpToCharactersFromSet:delimiterset intoString:&result]){            //store up to next delimiter
					if([result length]){
						[cmdItems addObject:result];
					}
				}
			}
			
			//turn the array into a selector
			theSelector = [NSInvocation makeSelectorFromArray:cmdItems];
			theObj = [destinationObjects objectForKey:objName];
			if(!theObj){
				if([objName isEqualToString:@"self"]){
					theObj = self;
				}
				else {
					//OK, the obj isn't one of the preloaded objects. It might be an object fullID identifier.
					theObj = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:objName];
				}	
			}
		}
		if([theObj respondsToSelector:theSelector]){
			NSMethodSignature* theSignature = [theObj methodSignatureForSelector:theSelector];
			NSInvocation* theInvocation = [NSInvocation invocationWithMethodSignature:theSignature];
			[theInvocation setSelector:theSelector];
			int n = (int)[theSignature numberOfArguments]-2; //first two are hidden
			int i;
			int argI;
			BOOL ok = YES;
			for(i=1,argI=0 ; i<=n*2 ; i+=2,argI++){
				NSString* aCmdItem = [cmdItems objectAtIndex:i];
				if(![theInvocation setArgument:argI to:aCmdItem]){
					ok = NO;
					break;
				}
			}
			if(ok){
				[[self undoManager] disableUndoRegistration];
				@try {
					[theInvocation invokeWithTarget:theObj];
					returnValue = [theInvocation returnValue];
				}
				@catch (NSException* e){
				}
				[[self undoManager] enableUndoRegistration];
			}
		}
	}
	return returnValue;					
}

#pragma mark •••Update Methods
- (void) sendCurrentAlarms:(ORCommandClient*)client
{
    NSEnumerator* e = [[ORAlarmCollection sharedAlarmCollection] alarmEnumerator];
    id anAlarm;
    while (anAlarm = [e nextObject]){
        [client sendCmd:@"postAlarm" withString:[anAlarm name]];
    }
}

- (void) sendCurrentRunStatus:(ORCommandClient*)client
{
    [client sendCmd:@"runStatus" withString:[NSString stringWithFormat:@"%d",[gOrcaGlobals runInProgress]]];
}

- (ORScriptIDEModel*) scriptIDEModel
{
	return scriptIDEModel;
}

- (void) sendHeartBeat:(ORCommandClient*)client
{
    [client sendCmd:@"OrcaHeartBeat" withString:nil];
}

- (void) closeScriptIDE
{
	if(scriptIDEModel){
		[[NSUserDefaults standardUserDefaults] synchronize];
		[self setScript:[scriptIDEModel script]];
		[self setScriptComments:[scriptIDEModel comments]];
		NSArray* w = [[(ORAppDelegate*)[NSApp delegate] document] findControllersWithModel:scriptIDEModel];
		[w makeObjectsPerformSelector:@selector(setModel:) withObject:nil];
		[w makeObjectsPerformSelector:@selector(close)];
		[scriptIDEModel release];
		scriptIDEModel = nil;
	}
}

- (void) openScriptIDE
{
	if(!scriptIDEModel){
		scriptIDEModel = [[ORScriptIDEModel alloc] init];
	}	
	[scriptIDEModel makeMainController];
	[scriptIDEModel setScript:[self script]];
	[scriptIDEModel setComments:[self scriptComments]];
}

- (void) moveInHistoryDown
{
	if(historyIndex<[history count]-1)historyIndex++;
	NSString* theCommand = [history objectAtIndex:historyIndex];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCommandCommandChangedNotification 
														object:self 
													  userInfo:[NSDictionary dictionaryWithObject:theCommand forKey:ORCommandCommandChangedNotification]];	
}

- (void) moveInHistoryUp
{
	if(historyIndex>0)historyIndex--;
	NSString* theCommand = [history objectAtIndex:historyIndex];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCommandCommandChangedNotification 
														object:self 
													  userInfo:[NSDictionary dictionaryWithObject:theCommand forKey:ORCommandCommandChangedNotification]];
}


@end


@implementation NSObject (ORCommandProtocal)
- (NSString*) commandID
{
    return @"";
}
@end
