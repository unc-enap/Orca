//
//  ORCouchDBListenerModel.m
//  Orca
//
//  Created by Thomas Stolz on 05/20/13.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORCouchDBListenerModel.h"
#import "ORCouchDB.h"
#import "Utilities.h"
#import "NSNotifications+Extensions.h"
#import "NSString+Extensions.h"
#import "NSInvocation+Extensions.h"
#import "NSArray+Extensions.h"
#import "NSDictionary+Extensions.h"
#import "ORScriptRunner.h"
//#import <YAJL/NSObject+YAJL.h>
//#import <YAJL/YAJLDocument.h>

#define kListDB             @"kListDB"
#define kChangesfeed        @"kChangesfeed"
#define kCommandDocCheck    @"kCommandDocCheck"
#define kCmdUploadDone      @"kCmdUploadDone"
#define kDesignUploadDone   @"kDesignUploadDone"

#define kCouchDBPort 5984
#define kCouchDBSubmitHeartbeatsPeriod 10

NSString* ORCouchDBListenerModelDatabaseListChanged    = @"ORCouchDBListenerModelDatabaseListChanged";
NSString* ORCouchDBListenerModelListeningChanged       = @"ORCouchDBListenerModelListeningChanged";
NSString* ORCouchDBListenerModelObjectListChanged      = @"ORCouchDBListenerModelObjectListChanged";
NSString* ORCouchDBListenerModelCommandsChanged        =@"ORCouchDBListenerModelCommandsChanged";
NSString* ORCouchDBListenerModelStatusLogChanged       =@"ORCouchDBListenerModelStatusLogChanged";
NSString* ORCouchDBListenerModelHostChanged            = @"ORCouchDBListenerModelHostChanged";
NSString* ORCouchDBListenerModelPortChanged            = @"ORCouchDBListenerModelPortChanged"; 
NSString* ORCouchDBListenerModelDatabaseChanged        = @"ORCouchDBListenerModelDatabaseChanged";
NSString* ORCouchDBListenerModelUsernameChanged        = @"ORCouchDBListenerModelUsernameChanged";
NSString* ORCouchDBListenerModelPasswordChanged            = @"ORCouchDBListenerModelPasswordChanged";
NSString* ORCouchDBListenerModelListeningStatusChanged = @"ORCouchDBListenerModelListeningStatusChanged";
NSString* ORCouchDBListenerModelHeartbeatChanged       = @"ORCouchDBListenerModelHeartbeatChanged";
NSString* ORCouchDBListenerModelUpdatePathChanged      = @"ORCouchDBListenerModelUpdatePathChanged";
NSString* ORCouchDBListenerModelStatusLogAppended      = @"ORCouchDBListenerModelStatusLogAppended";
NSString* ORCouchDBListenerModelListenOnStartChanged   = @"ORCouchDBListenerModelListenOnStartChanged";
NSString* ORCouchDBListenerModelSaveHeartbeatsWhileListeningChanged = @"ORCouchDBListenerModelSaveHeartbeatsWhileListeningChanged";

@interface ORCouchDBListenerModel (private)
- (void) _uploadCmdDesignDocument;
- (void) _fetchDocument:(NSString*)docName;
- (void) _uploadCmdSection;
- (void) _createCmdDict;
- (void) _processCmdDocument:(NSDictionary*) doc;
- (void) _uploadAllSections;
- (BOOL) checkSyntax:(NSString*) key;
- (id) _convertInvocationReturn:(NSInvocation*)inv;
- (void) _saveHeartbeat;
- (ORCouchDB*) statusDBRef:(NSString*)db_name;
- (ORCouchDB*) statusDBRef;
@end

@implementation ORCouchDBListenerModel (private)

- (void) _uploadCmdDesignDocument
{
    
    [self log:@"Uploading _design/orcacommand document..."];
    NSString* filterString = @"function (doc, req)"
                              "{"
                              "   if (doc.type && doc.type == 'command' && !doc.response) { return true; }"
                              "   return false;"
                              "}";
    NSDictionary* filterDict = [NSDictionary dictionaryWithObjectsAndKeys:filterString,@"execute_commands", nil];
    NSDictionary* dict=[NSDictionary dictionaryWithObjectsAndKeys:filterDict,@"filters",nil];
    
    [[self statusDBRef]updateDocument:dict
                            documentId:@"_design/orcacommand"
                                   tag:kDesignUploadDone
                     informingDelegate:YES];
}

- (void) _fetchDocument:(NSString*)docName
{
    [[self statusDBRef] getDocumentId:docName tag:kCommandDocCheck];
}

//DB Interactions

- (void) _uploadCmdSection
{
    [self log:@"Uploading commands section..."];
    [[self statusDBRef:updatePath] addDocument:[NSDictionary dictionaryWithObjectsAndKeys:cmdDict,@"keys",nil]
                            documentId:cmdDocName
                                   tag:kCmdUploadDone];
}

- (void) _createCmdDict
{
    [cmdDict release];
    cmdDict = [[NSMutableDictionary alloc] initWithCapacity:256];
    for (id cmd in cmdTableArray) {
        NSMutableDictionary* tempdict= [NSMutableDictionary dictionaryWithDictionary:cmd];
        [tempdict removeObjectForKey:@"Label"];
        [cmdDict setObject:tempdict forKey:[cmd objectForKey:@"Label"]];
    }
    
}

- (void) _processCmdDocument:(NSDictionary*) doc
{
    
    if([[doc valueForKey:@"run"] isEqualToString:@"YES"]){
        NSString* new_script=[doc objectForKey:@"script"];
        if(YES){
            [script release];
            script=[new_script copy];
            if([scriptRunner running])
            {
                [scriptRunner stop];
                sleep(0.1);
            }
            if([self runScript:script])[self log:@"parsedOK - script started"];
            else [self log:@"parsing error\n"];
        }
    } else if([[doc valueForKey:@"run"] isEqualToString:@"NO"]) {
        if(scriptRunner){
            if([scriptRunner running]){
                [scriptRunner stop];
            }
        }
    } else {
        
        NSString* message;
        id returnVal = [NSNull null];
        NSString* key=[doc valueForKey:@"execute"];
        id val=[doc valueForKey:@"arguments"];
        
        NSDictionary* cmd=[cmdDict objectForKey:key];
        BOOL ok = NO;
        if(cmd){
            if ([self checkSyntax:key]){
                if([self executeCommand:key arguments:val returnVal:&returnVal]){
                    message=[NSString stringWithFormat:@"executed command with label '%@'",key];
                    ok = YES;
                }
                else {
                    message=@"failure while trying to execute";
                }
            }
            else{
                message=@"cmd with invalid syntax";
            }
        }
        else {
            message = @"no cmd found for this key";
        }
        [self log:message];
        NSMutableDictionary* returnDic = [NSMutableDictionary dictionaryWithDictionary:doc];
        NSMutableDictionary* response = [NSMutableDictionary dictionaryWithObjectsAndKeys:message,@"content",
                                         [[NSDate date] stdDescription],@"timestamp",returnVal,@"return",
                                         nil];
        if (ok) [response setObject:[NSNumber numberWithBool:ok] forKey:@"ok"];
        [returnDic setObject:response forKey:@"response"];
        [[self statusDBRef:updatePath] addDocument:returnDic
                                        documentId:[returnDic objectForKey:@"_id"]
                                               tag:nil];
    }
}

- (void) _uploadAllSections
{
    cmdSectionReady=NO;
    //    scriptSectionready=NO;
    [self _uploadCmdDesignDocument];
    [self _uploadCmdSection];
}

- (ORCouchDB*) statusDBRef
{
    return [self statusDBRef:nil];
}

- (ORCouchDB*) statusDBRef:(NSString*)db_name;
{
    NSString* dbName = [databaseName stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    if ([db_name length] != 0) {
        dbName = [dbName stringByAppendingFormat:@"/%@",db_name];
    }
    return [ORCouchDB couchHost:hostName port:portNumber username:userName pwd:password database:dbName delegate:self];
}

- (BOOL) checkSyntax:(NSString*) key
{
	BOOL syntaxOK = YES;
    id aCommand = [cmdDict objectForKey:key];
	if(aCommand){
		NSString* objID = [aCommand objectForKey:@"Object"];
		id obj = [[self document] findObjectWithFullID:objID];
		if(obj){
			[aCommand setObject:@"OK" forKey:@"ObjectOK"];
			NSString* s	= [aCommand objectForKey:@"Selector"];
			if([obj respondsToSelector:[NSInvocation makeSelectorFromString:s]]){
				[aCommand setObject:@"OK" forKey:@"SelectorOK"];
			}
			else {
				syntaxOK = NO;
				[aCommand removeObjectForKey:@"SelectorOK"];
			}
		}
		else {
			syntaxOK = NO;
			[aCommand removeObjectForKey:@"ObjectOK"];
		}
	}
	return syntaxOK;
}

- (id) _convertInvocationReturn:(NSInvocation*)inv
{
    const char* the_type = [[inv methodSignature] methodReturnType];
    if (strcmp(@encode(void),the_type) == 0) return [NSNull null];

    NSUInteger returnLength = [[inv methodSignature] methodReturnLength];
    NSMutableData* buffer = [NSMutableData dataWithCapacity:returnLength];
    void* data = (void*)[buffer bytes];
    [inv getReturnValue:data];

    // Now deal with the type
    // If it's just an object, return it.  Maybe it works...
    if (strcmp(@encode(id),the_type) == 0) return *((id*) data);

    // now handle C scalar types.  We don't bother with anything more complicated.
#define HANDLE_NUMBER_TYPE(capAType, atype)        \
if (strcmp(@encode(atype), the_type) == 0)     \
{ return [NSNumber numberWith ## capAType:*((atype*) data)]; }

    HANDLE_NUMBER_TYPE(Bool, BOOL)
    HANDLE_NUMBER_TYPE(Double, double)
    HANDLE_NUMBER_TYPE(Float, float)
    HANDLE_NUMBER_TYPE(Char, char)
    HANDLE_NUMBER_TYPE(Int, int)
    HANDLE_NUMBER_TYPE(Long, int32_t)
    HANDLE_NUMBER_TYPE(LongLong, int64_t)
    HANDLE_NUMBER_TYPE(Short, short)
    HANDLE_NUMBER_TYPE(UnsignedChar, unsigned char)
    HANDLE_NUMBER_TYPE(UnsignedInt, unsigned int)
    HANDLE_NUMBER_TYPE(UnsignedLong, uint32_t)
    HANDLE_NUMBER_TYPE(UnsignedLongLong, uint64_t)
    HANDLE_NUMBER_TYPE(UnsignedShort, unsigned short)
    return [NSNull null];
}

- (void) _saveHeartbeat
{
    if (![self isListening] || !saveHeartbeatsWhileListening) return;
    [[self statusDBRef:updatePath] addDocument:[NSDictionary dictionaryWithObjectsAndKeys:@"heartbeat",@"type",nil]
                                           tag:@""];

    [self performSelector:@selector(_saveHeartbeat)
               withObject:self
               afterDelay:kCouchDBSubmitHeartbeatsPeriod];
}

@end

@implementation ORCouchDBListenerModel

#pragma mark ***Initialization
- (id) init
{
	self=[super init];
	[self registerNotificationObservers];
    [self setHeartbeat:5000];
    [self setHostName:@"localhost"];
    [self setPortNumber:kCouchDBPort];
    commonMethodsOnly=YES;
    [self setDefaults];
    [self setStatusLog:@""];
	return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [statusLogString release];
    [databaseName release];
    [userName release];
    [password release];
    [hostName release];
    [objectList release];
    [databaseList release];
    [cmdTableArray release];
    [cmdDict release];
	[super dealloc];
}

- (void) wakeUp
{
    [super wakeUp];
    
    cmdDocName=@"commands";
    scriptDocName=@"Orca Scripts";
    commandDoc = @"control";
    runningChangesfeed=nil;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Changesfeed"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCouchDBListenerController"];
}

- (void) registerNotificationObservers
{
	
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqual:@"isFinished"]){
        if([change objectForKey:NSKeyValueChangeNewKey]){ //this means the changesfeed operation has finished
            [runningChangesfeed release];
            runningChangesfeed=nil;
            [self log:@"Changesfeed operation finished"];
            [[NSNotificationCenter defaultCenter]
             postNotificationOnMainThreadWithName:ORCouchDBListenerModelListeningChanged
             object:self];
        }
        
    }
}

#pragma mark ***Accessors
- (NSString*) statusLog
{
    if (!statusLogString) return @"";
    return statusLogString;
}

- (void) setStatusLog:(NSString *)log
{
    @synchronized(self) {
        [statusLogString release];
        statusLogString = [[NSMutableString stringWithString:log] retain];
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelStatusLogChanged object:self];
    }
}

- (void) appendStatusLog:(NSString *)log
{
    @synchronized(self){
        if (!statusLogString) statusLogString = [[NSMutableString string] retain];
        [statusLogString appendString:log];
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelStatusLogAppended object:log];
    }
}

- (void) log:(NSString *)message
{
    if(message){
        [self appendStatusLog:[NSString stringWithFormat:@"%@: %@\n", [NSDate date], message]];
    }
}

//Couch Config
- (void) setDatabaseName:(NSString*)name{
    [databaseName release];
    databaseName=[name copy];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelDatabaseChanged object:self];
}

- (void) setHostName:(NSString*)name{

    [hostName release];
    hostName= [name copy];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelHostChanged object:self];
}

- (void) setPortNumber:(NSUInteger)aPort
{
    portNumber=aPort;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelPortChanged object:self];
}

- (void) setUserName:(NSString*)name
{
    if ([name length]==0)
    {
        userName=nil;
        [self setPassword:nil];
    }
    else{
        [userName release];
        userName=[name copy];
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelUsernameChanged object:self];
}

- (void) setPassword:(NSString*)pwd
{
    [password release];
    password=[pwd copy];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelPasswordChanged object:self];
}

- (void) setUpdatePath:(NSString *)aPath
{
    [updatePath release];
    updatePath=[aPath copy];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelUpdatePathChanged object:self];
}

- (NSArray*) databaseList
{
    return databaseList;
}

- (NSString*) database
{
    return databaseName;
}

- (NSUInteger) heartbeat
{
    return heartbeat;
}

- (NSString*) hostName
{
    if (!hostName) return @"";
    return hostName;
}

- (NSUInteger) portNumber
{
    return portNumber;
}

- (NSString*) userName
{
    if (!userName) return @"";
    return userName;
}

- (NSString*) password
{
    if (!password) return @"";
    return password;
}

- (NSString*) updatePath
{
    if (!updatePath) return @"";
    return updatePath;
}

- (BOOL) isListening
{
    if(runningChangesfeed){
        return TRUE;
    }
    else{
        return FALSE;
    }
}

- (void) setHeartbeat:(NSUInteger)beat
{
    
    heartbeat=beat;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelHeartbeatChanged object:self];
}

- (void) setSaveHeartbeatsWhileListening:(BOOL)save
{
    if (saveHeartbeatsWhileListening == save) return;
    saveHeartbeatsWhileListening = save;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelSaveHeartbeatsWhileListeningChanged
                                                                        object:self];
}

- (BOOL) saveHeartbeatsWhileListening
{
    return saveHeartbeatsWhileListening;
}


//Command Section
- (void) setCommonMethods:(BOOL)only
{
    commonMethodsOnly=only;
}

- (BOOL) listenOnStart
{
    return listenOnStart;
}
- (void) setListenOnStart:(BOOL)alist
{
    if (alist == listenOnStart) return;
    listenOnStart = alist;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelListenOnStartChanged
                                                                        object:self];
}

- (NSArray*) objectList
{
    return objectList;
}

- (NSArray*) getMethodListForObjectID:(NSString*)objID
{
    NSString* methodString;
    id obj = [[self document] findObjectWithFullID:objID];
    if (commonMethodsOnly) methodString=commonScriptMethodsByObj(obj, YES);
    else methodString= listMethods([obj class]);
    return [methodString componentsSeparatedByString:@"\n"];
}

- (BOOL) commonMethodsOnly
{
    return commonMethodsOnly;
}

- (NSDictionary*) cmdDict
{
    [self _createCmdDict];
    return [NSDictionary dictionaryWithDictionary:cmdDict];
}

#pragma mark ***DB Access

-(void) startStopSession
{
    if (!runningChangesfeed){
        [self _createCmdDict];
        [self _uploadAllSections];
    }
    else{
        [self log:@"Changes feed cancelled"];
        [runningChangesfeed cancel];
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelListeningChanged object:self];
    }
    
}

-(void) startChangesfeed
{
    runningChangesfeed=[[[self statusDBRef] changesFeedMode:kContinuousFeed
                                                  heartbeat:heartbeat
                                                        tag:kChangesfeed
                                                     filter:@"orcacommand/execute_commands"] retain];
    [runningChangesfeed addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:NULL];
    if (saveHeartbeatsWhileListening) {
        [self performSelectorOnMainThread:@selector(_saveHeartbeat) withObject:self waitUntilDone:NO];
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelListeningChanged object:self];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
	@synchronized(self){
		if([aResult isKindOfClass:[NSDictionary class]]){
            if([aTag isEqualToString:kChangesfeed]){
                [self _fetchDocument:[aResult objectForKey:@"id"]];
            }
            else if([aTag isEqualToString:kCommandDocCheck]){
                [self _processCmdDocument:aResult];
            }
            else if([aTag isEqualToString:kCmdUploadDone]){
                if ([aResult objectForKey:@"error"]){
                    [self log:[NSString stringWithFormat:@"Command Section upload failed: %@", [aResult objectForKey:@"reason"]]];
                }
                else if ([aResult objectForKey:@"ok"]){
                    cmdSectionReady=YES;
                    [self sectionReady];
                }
                else [self log:[NSString stringWithFormat:@"Command Section upload failed: %@", aResult]];
            }
		}
		else if([aResult isKindOfClass:[NSArray class]]){
			if([aTag isEqualToString:kListDB]){
				//[aResult prettyPrint:@"CouchDB List:"];
                [databaseList release];
                databaseList=[aResult retain];
                [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelDatabaseListChanged object:self];
            }
            else [self log:[NSString stringWithFormat:@"%@",aResult]];
        }
		else { //here is the issue
			[self log:[NSString stringWithFormat:@"%@",aResult]];
		}
	}

}


- (void) listDatabases
{
	[[self statusDBRef] listDatabases:self tag:kListDB];
}


- (void) sectionReady
{
    if (cmdSectionReady)    // && scriptSectionReady && prmSectionReady
    {
        [self startChangesfeed];
    }
}

#pragma mark ***Command Section
- (void) updateObjectList
{
    NSMutableArray* temp=[[NSMutableArray alloc] initWithCapacity:100];
    id obj;
    for (obj in [[self guardian] familyList]) {
        [temp addObject:[[[obj fullID] copy] autorelease]];
    }
    [objectList release];
    objectList = [[NSArray alloc] initWithArray:temp];
    [temp release];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCouchDBListenerModelObjectListChanged object:self];
    
}

- (BOOL) executeCommand:(NSString*) key arguments:(NSArray*)val returnVal:(id*)aReturn
{
    [self _createCmdDict];
    BOOL goodToGo = NO;
    *aReturn = [NSNull null];
	id aCommand = [cmdDict objectForKey:key];
    if(aCommand){
		NSString* objID = [aCommand objectForKey:@"Object"];
		id obj = [[self document] findObjectWithFullID:objID];
		if(obj){
			@try {
				NSMutableString* setterString	= [[[aCommand objectForKey:@"Selector"] mutableCopy] autorelease];
                
                NSData* sData = [[aCommand objectForKey:@"Value"] dataUsingEncoding:NSASCIIStringEncoding];
                NSArray* theValue = [NSJSONSerialization JSONObjectWithData:sData options:NSJSONReadingMutableContainers error:nil];
                
                //NSArray* theValue = (val) ? val : [[aCommand objectForKey:@"Value"] yajl_JSON];
                if (theValue && ![theValue isKindOfClass:[NSArray class]]) {
                    [NSException raise:@"Invalid arguments"
                                format:@"Arguments must be an array (e.g. [1, 2.3]) of arguments"];
                }
				SEL theSetterSelector			= [NSInvocation makeSelectorFromString:setterString];
				
				//do the setter
				NSMethodSignature*	theSignature	= [obj methodSignatureForSelector:theSetterSelector];
				NSInvocation*		theInvocation	= [NSInvocation invocationWithMethodSignature:theSignature];
				
				[theInvocation setSelector:theSetterSelector];
				int n = (int)[theSignature numberOfArguments];
				int i;
                if ((n-2) != [theValue count]) {
                    [NSException raise:@"ORCouchDBListenerInvalidArguments"
                                format:@"Invalid argument number: (%d) seen, (%i) needed",(int)[theValue count],(n-2)];
                }
				for(i=2;i<n;i++){
                    id o = [theValue objectAtIndex:i-2];
                    const char* the_type = [theSignature getArgumentTypeAtIndex:i];
                    if (strcmp(@encode(id), the_type)==0) {
                        // It's expects an object, just try to pass it in.
                        [theInvocation setArgument:&o atIndex:i];
                    } else {
                        // Try to deal with numbers
                        if (![o isKindOfClass:[NSNumber class]]) {
                            [NSException raise:@"ORCouchDBListenerInvalidArguments"
                                        format:@"Can only handle NSNumber type, seen (%@)",[o class]];
                        }
#define HANDLE_NUMBER_ARG(capAType, atype)        \
if (strcmp(@encode(atype), the_type) == 0)         \
{ atype tmp = [o capAType ## Value]; [theInvocation setArgument:&tmp atIndex:i]; continue; }
                      
                        HANDLE_NUMBER_ARG(bool, BOOL)
                        HANDLE_NUMBER_ARG(double, double)
                        HANDLE_NUMBER_ARG(float, float)
                        HANDLE_NUMBER_ARG(int, int)
                        HANDLE_NUMBER_ARG(double, double)
                        HANDLE_NUMBER_ARG(long, long)
                        HANDLE_NUMBER_ARG(longLong, int64_t)
                        HANDLE_NUMBER_ARG(short, short)
                        HANDLE_NUMBER_ARG(unsignedChar, unsigned char)
                        HANDLE_NUMBER_ARG(unsignedInt, unsigned int)
                        HANDLE_NUMBER_ARG(unsignedLong, unsigned long)
                        HANDLE_NUMBER_ARG(unsignedLongLong, unsigned long long)
                        HANDLE_NUMBER_ARG(unsignedShort, unsigned short)
                        [NSException raise:@"ORCouchDBListenerInvalidArguments"
                                    format:@"Found invalid requested number type as argument(%s)?!",the_type];
                    }
				}
				[theInvocation setTarget:obj];
				[theInvocation performSelectorOnMainThread:@selector(invoke)
                                                withObject:nil
                                             waitUntilDone:YES];
                *aReturn = [self _convertInvocationReturn:theInvocation];
                goodToGo = YES;
			}
			@catch(NSException* localException){
				goodToGo = NO;
				NSLogColor([NSColor redColor],@"%@: <%@>\n",[self fullID],[aCommand objectForKey:@"SetSelector"]);
				NSLogColor([NSColor redColor],@"Exception: %@\n",localException);
			}
        }
    }
    return goodToGo;
}

- (void) setCommands:(NSMutableArray*)anArray
{
	[anArray retain];
	[cmdTableArray release];
	cmdTableArray = anArray;
}

- (void) setDefaults
{
    [self setCommands:[NSMutableArray array]];
}

- (NSDictionary*) commandAtIndex:(int)index
{
	if(index < [cmdTableArray count]){
		return [cmdTableArray objectAtIndex:index];
	}
	else return nil;
}

- (NSUInteger) commandCount
{
	return [cmdTableArray count];
}

- (void) addCommand:(NSString*)obj label:(NSString*)lab selector:(NSString*)sel info:(NSString*)info value:(NSString*)val
{
    @try {
        if ([[self cmdDict] objectForKey:lab]){
            [NSException raise:@"ORCouchDBListerCommand"
                        format:@"Key (%@) already in use",lab];
        }
        
        NSMutableDictionary* adic = [NSMutableDictionary dictionaryWithObjectsAndKeys:obj,@"Object",
                                     lab,@"Label",sel,@"Selector",info,@"Info",nil];
        if(val && [val length] > 0) {
            NSString* new_str = [val stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([new_str characterAtIndex:0] != '[' && [new_str characterAtIndex:[new_str length]-1] != ']') {
                new_str = [NSString stringWithFormat:@"[%@]",new_str];
            }
            NSData* sData = [new_str dataUsingEncoding:NSASCIIStringEncoding];
            NSArray* anArray = [NSJSONSerialization JSONObjectWithData:sData options:NSJSONReadingMutableContainers error:nil];

    
            if (![anArray isKindOfClass:[NSArray class]]) {
               // if (![[new_str yajl_JSON] isKindOfClass:[NSArray class]]) {
                [NSException raise:@"ORCouchDBListerCommand"
                            format:@"Value must be parsable array/list: (e.g. [ 1, 23.4 ] )"];
            }
            [adic setObject:new_str forKey:@"Value"];
        }
        [cmdTableArray addObject:adic];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBListenerModelCommandsChanged object:self];
    } @catch (NSException* exc) {
        [self log:[NSString stringWithFormat:@"Can't add command, exception: %@",[exc reason]]];
    }
    
}

- (void) removeCommand:(int)index
{
	if(index<[cmdTableArray count] && [cmdTableArray count]>1){
		[cmdTableArray removeObjectAtIndex:index];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCouchDBListenerModelCommandsChanged object:self];
}


#pragma mark ***Script Section

- (BOOL) runScript:(NSString*) aScript
{
    BOOL parsedOK = YES;
    if(!scriptRunner)scriptRunner = [[ORScriptRunner alloc] init];
    if(![scriptRunner running]){
        [scriptRunner setScriptName:@"CouchDB_remote_script"];
        //[scriptRunner setInputValue:inputValue];
        [scriptRunner parse:aScript];
        parsedOK = [scriptRunner parsedOK];
        if(parsedOK){
            if([scriptRunner scriptExists]){
                [scriptRunner setFinishCallBack:self selector:@selector(scriptRunnerDidFinish:returnValue:)];
                [scriptRunner run:nil sender:self];
            }
            else {
                [self scriptRunnerDidFinish:YES returnValue:[NSNumber numberWithInt:1]];
            }
        }
    }
    else {
        [scriptRunner stop];
    }
    return parsedOK;
}

-(void) scriptRunnerDidFinish:(BOOL)finished returnValue:(NSNumber*)val{
    [self log:@"CouchDB_remote_script finished"];
}



#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{    
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setHostName: [decoder decodeObjectForKey:@"hostName"]];
    [self setPortNumber: [decoder decodeIntegerForKey:@"port"]];
    [self setDatabaseName:[decoder decodeObjectForKey:@"dbName"]];
    [self setHeartbeat:[decoder decodeIntegerForKey:@"heartbeat"]];
	[self registerNotificationObservers];
    [self setCommands:[decoder decodeObjectForKey:@"cmdTableArray"]];
    [self setCommonMethods:[decoder decodeBoolForKey:@"commonOnly"]];
    [self setStatusLog: [decoder decodeObjectForKey:@"statusLog"]];
    [self setUserName:[decoder decodeObjectForKey:@"userName"]];
    [self setPassword:[decoder decodeObjectForKey:@"password"]];
    [self setUpdatePath:[decoder decodeObjectForKey:@"updatePath"]];
    [self setListenOnStart:[decoder decodeBoolForKey:@"listenOnStart"]];
    [self setSaveHeartbeatsWhileListening:[decoder decodeBoolForKey:@"saveHeartbeatsWhileListening"]];
    if(!cmdTableArray){
        [self setDefaults];
    }
    if (listenOnStart) {
        [self performSelector:@selector(startStopSession) withObject:self afterDelay:0.5];
    }
   return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:databaseName forKey:@"dbName"];
    [encoder encodeInteger:portNumber forKey:@"port"];
    [encoder encodeObject:hostName forKey:@"hostName"];
    [encoder encodeInteger:heartbeat forKey:@"heartbeat"];
    [encoder encodeObject:cmdTableArray forKey:@"cmdTableArray"];
    [encoder encodeBool:commonMethodsOnly forKey:@"commonOnly"];
    [encoder encodeObject:statusLogString forKey:@"statusLog"];
    [encoder encodeObject:userName forKey:@"userName"];
    [encoder encodeObject:password forKey:@"password"];
    [encoder encodeObject:updatePath forKey:@"updatePath"];
    [encoder encodeBool:listenOnStart forKey:@"listenOnStart"];
    [encoder encodeBool:saveHeartbeatsWhileListening forKey:@"saveHeartbeatsWhileListening"];
}

@end

