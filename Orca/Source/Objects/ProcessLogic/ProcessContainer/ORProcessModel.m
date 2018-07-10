//
//  ORProcessModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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

#pragma mark ¥¥¥Imported Files
#import "ORProcessElementModel.h"
#import "ORProcessModel.h"
#import "ORProcessThread.h"
#import "ORProcessCenter.h"
#import "ORMailer.h"
#import "ORCouchDBModel.h"
#import "ORAdcModel.h"

NSString* ORProcessModelMasterProcessChanged = @"ORProcessModelMasterProcessChanged";
NSString* ORProcessModelSendOnStopChanged			= @"ORProcessModelSendOnStopChanged";
NSString* ORProcessModelSendOnStartChanged			= @"ORProcessModelSendOnStartChanged";
NSString* ORProcessModelHeartBeatIndexChanged		= @"ORProcessModelHeartBeatIndexChanged";
NSString* ORProcessModelEmailListChanged			= @"ORProcessModelEmailListChanged";
NSString* ORProcessModelHistoryFileChanged			= @"ORProcessModelHistoryFileChanged";
NSString* ORProcessModelKeepHistoryChanged			= @"ORProcessModelKeepHistoryChanged";
NSString* ORProcessModelSampleRateChanged			= @"ORProcessModelSampleRateChanged";
NSString* ORProcessTestModeChangedNotification      = @"ORProcessTestModeChangedNotification";
NSString* ORProcessRunningChangedNotification       = @"ORProcessRunningChangedNotification";
NSString* ORProcessModelCommentChangedNotification  = @"ORProcessModelCommentChangedNotification";
NSString* ORProcessModelShortNameChangedNotification= @"ORProcessModelShortNameChangedNotification";
NSString* ORProcessModelUseAltViewChanged			= @"ORProcessModelUseAltViewChanged";
NSString* ORProcessModelNextHeartBeatChanged		= @"ORProcessModelNextHeartBeatChanged";
NSString* ORProcessModelRunNumberChanged			= @"ORProcessModelRunNumberChanged";
NSString* ORForceProcessPollNotification			= @"ORForceProcessPollNotification";

@interface ORProcessModel (private)
- (void) setSendStartNoticeNextReadAfterDelay;
@end

@implementation ORProcessModel

@synthesize lastReportContent,lastReportTime;

#pragma mark ¥¥¥initialization
- (id) init
{
	self = [super init];
	sampleRate = 10;
	return self;
}

- (void) dealloc
{
    [emailList release];
    [historyFile release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[self stopRun];
	[comment release];
	[nextHeartbeat release];
	[shortName release];
	[testModeAlarm clearAlarm];
    [testModeAlarm release];
    [lastReportContent release];
    [lastReportTime release];
	[super dealloc];
}

- (void) sleep
{
	[self stopRun];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super sleep];
}
- (void) wakeUp
{
	[super wakeUp];
	if([self heartbeatSeconds]){
		[self performSelector:@selector(sendHeartbeat) withObject:nil afterDelay:[self heartbeatSeconds]];
	}	
}

- (NSString*) helpURL
{
	return @"Process_Control/Process_Container.html";
}

- (void) awakeAfterDocumentLoaded
{
	[super awakeAfterDocumentLoaded];
	if(wasRunning){
		[self performSelector:@selector(startRun) withObject:nil afterDelay:3];
	}
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{	
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver:self];
	
    [notifyCenter addObserver: self
                     selector: @selector(runNow:)
                         name: ORForceProcessPollNotification
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(outOfRangeLowChanged:)
                         name: ORAdcModelOutOfRangeLow
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(outOfRangeHiChanged:)
                         name: ORAdcModelOutOfRangeHi
                       object: nil];
}

- (void) outOfRangeLowChanged:(NSNotification*)aNote
{
    if([[aNote object] guardian]==self){
        outOfRangeLowCount++;
    }
}

- (void) outOfRangeHiChanged:(NSNotification*)aNote
{
    if([[aNote object] guardian]==self){
        outOfRangeHiCount++;
    }
}

#pragma mark ***Accessors

- (BOOL) masterProcess
{
    return masterProcess;
}

- (void) setMasterProcess:(BOOL)aMasterProcess
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMasterProcess:masterProcess];
    
    if(masterProcess && !aMasterProcess){
        NSLogColor([NSColor redColor],@"Process '%@' was removed from 'Master' status\n",[self shortName]);
    }
    
    masterProcess = aMasterProcess;
    if(masterProcess){
        NSLog(@"Process '%@' is now at 'Master' status\n",[self shortName]);
    }
    if(masterProcess && updateImageForMasterChange){
        NSArray* processes = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:[self class]];
        for(id aProcess in processes){
            if(aProcess == self) continue;
            if([aProcess masterProcess]) {
                [aProcess setMasterProcess:NO];
                [aProcess setUpImage];
            }
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelMasterProcessChanged object:self];
}

- (BOOL) sendOnStop
{
    return sendOnStop;
}

- (void) setSendOnStop:(BOOL)aSendOnStop
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSendOnStop:sendOnStop];
    sendOnStop = aSendOnStop;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelSendOnStopChanged object:self];
}

- (BOOL) sendOnStart
{
    return sendOnStart;
}

- (void) setSendOnStart:(BOOL)aSendOnStart
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSendOnStart:sendOnStart];
    sendOnStart = aSendOnStart;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelSendOnStartChanged object:self];
}

- (int) heartBeatIndex
{
    return heartBeatIndex;
}

- (void) setHeartBeatIndex:(int)aHeartBeatIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHeartBeatIndex:heartBeatIndex];
    heartBeatIndex = aHeartBeatIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelHeartBeatIndexChanged object:self];

	if([self heartbeatSeconds]){
		[self performSelector:@selector(sendHeartbeat) withObject:nil afterDelay:[self heartbeatSeconds]];
	}
	[self setNextHeartbeatString];
	[self setUpImage];
}

- (NSMutableArray*) emailList
{
    return emailList;
}

- (void) setEmailList:(NSMutableArray*)aEmailList
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEmailList:emailList];
    
    [aEmailList retain];
    [emailList release];
    emailList = aEmailList;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelEmailListChanged object:self];
}

- (void) addAddress:(id)anAddress atIndex:(int)anIndex
{
	if(!emailList) emailList= [[NSMutableArray array] retain];
	if([emailList count] == 0)anIndex = 0;
	anIndex = MIN(anIndex,[emailList count]);
	
	[[[self undoManager] prepareWithInvocationTarget:self] removeAddressAtIndex:anIndex];
	[emailList insertObject:anAddress atIndex:anIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelEmailListChanged object:self];
}

- (void) removeAddressAtIndex:(int) anIndex
{
	id anAddress = [emailList objectAtIndex:anIndex];
	[[[self undoManager] prepareWithInvocationTarget:self] addAddress:anAddress atIndex:anIndex];
	[emailList removeObjectAtIndex:anIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelEmailListChanged object:self];
}

- (NSString*) historyFile
{
	if([historyFile length])return historyFile;
	else return @"";
}

- (void) setHistoryFile:(NSString*)aHistoryFile
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistoryFile:historyFile];
    
    [historyFile autorelease];
    historyFile = [aHistoryFile copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelHistoryFileChanged object:self];
}

- (BOOL) keepHistory
{
    return keepHistory;
}

- (void) setKeepHistory:(BOOL)aKeepHistory
{
    [[[self undoManager] prepareWithInvocationTarget:self] setKeepHistory:keepHistory];
    
    keepHistory = aKeepHistory;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelKeepHistoryChanged object:self];
    [self setUpImage];

}
- (void) setProcessIDs
{
	for(OrcaObject* obj in [self orcaObjects]){
		[self assignProcessID:obj];
	}
}

- (void)assignProcessID:(OrcaObject*)objToGetID
{
	if(![objToGetID respondsToSelector:@selector(processID)])return;
	if(![objToGetID processID]){
		unsigned long anId = 1;
		do {
			BOOL idAlreadyUsed = NO;
			for(OrcaObject* anObj in [self orcaObjects]){
				if(anObj == objToGetID)continue;
				if([anObj processID] == anId){
					anId++;
					idAlreadyUsed = YES;
					break;
				}
			}
			if(!idAlreadyUsed){
				[objToGetID setProcessID:anId];
				break;
			}
		}while(1);
	}
}

- (BOOL) useAltView
{
	return useAltView;
}

- (void) setUseAltView:(BOOL)aState
{
	BOOL deselectIcons = NO;
	if(aState != useAltView)deselectIcons = YES;
	useAltView = aState;
	for(OrcaObject* obj in [self orcaObjects]){
		if([obj respondsToSelector:@selector(setUseAltView:)]){
			[obj setUseAltView:useAltView];
			if(deselectIcons)[obj setHighlighted:NO];
		}
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelUseAltViewChanged object:self];
}

- (float) sampleRate
{
    return sampleRate;
}

- (void) setSampleRate:(float)aSampleRate
{
	if(aSampleRate<=0.001)aSampleRate = 0.001;
	else if(aSampleRate>10)  aSampleRate = 10;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleRate:sampleRate];
    
    sampleRate = aSampleRate;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelSampleRateChanged object:self];
}

- (NSString*) elementName
{
	if([shortName length])return [self shortName];
	else return [NSString stringWithFormat:@"Process %lu",[self uniqueIdNumber]];
}


- (id) stateValue
{
    NSString* stateString = @"Idle";
    if(processRunning){
        if(inTestMode)stateString = @"Testing";
        else stateString = @"Running";
    }
    return stateString;
}

- (NSString*) fullHwName
{
    return @"";
}

- (NSString*) shortName
{
	NSString* s;
	@synchronized(self){
		s = [[shortName retain] autorelease];
	}
	return s;
}
- (void) setShortName:(NSString*)aComment
{
    if(!aComment)aComment = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setShortName:shortName];
    
    [shortName autorelease];
    shortName = [aComment copy];
    [self setUpImage];
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORProcessModelShortNameChangedNotification
                              object:self];
}


- (NSString*)comment
{
    return comment;
}
- (void) setComment:(NSString*)aComment
{
    if(!aComment)aComment = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setComment:comment];
    
    [comment autorelease];
    comment = [aComment copy];
    
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORProcessModelCommentChangedNotification
                              object:self];
    
}

- (BOOL) processRunning
{
    return processRunning;
}
- (void) setProcessRunning:(BOOL)aState
{
    [self setHighlighted:NO];
	
    processRunning = aState;

    [self setUpImage];
	
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORProcessRunningChangedNotification
					  object:self];
	
	if(aState)sampleGateOpen = YES; //force the first sample

}

- (void) putInTestMode
{
	[[self undoManager] disableUndoRegistration];
	[self setInTestMode:YES];
	[[self undoManager] enableUndoRegistration];
}

- (void) putInRunMode
{
	[[self undoManager] disableUndoRegistration];
	[self setInTestMode:NO];
	[[self undoManager] enableUndoRegistration];
}

- (BOOL) inTestMode
{
    return inTestMode;
}

- (void) setInTestMode:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInTestMode:inTestMode];

	
    inTestMode = aState;

    [self setUpImage];
	
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORProcessTestModeChangedNotification
					  object:self];
    

	if(!inTestMode && processRunning)		[self clearTestAlarm];
	else if(inTestMode && processRunning)	[self postTestAlarm];

}

- (void) postTestAlarm
{
	if(inTestMode){
		if(!testModeAlarm){
			testModeAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Process %lu in TestMode",[self uniqueIdNumber]] severity:kInformationAlarm];
			[testModeAlarm setHelpString:@"The Process is in test mode. This means that hardware will NOT be touched. Input relays can be switched by a Cmd-Click"];

		}
		[testModeAlarm postAlarm];
	}
}

- (void) clearTestAlarm
{
	[testModeAlarm clearAlarm];
	[testModeAlarm release];
	testModeAlarm = nil;
}

- (void) setUpImage
{
    if(![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(setUpImage) withObject:nil waitUntilDone:YES];
        return;
    }
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each Process can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"Process"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];    
	
    if([self uniqueIdNumber]){
        NSString* stateString = @"Idle";
        if(processRunning){
            if(inTestMode)stateString = @"Testing";
            else stateString          = @"Running";
        }
				
        NSAttributedString* n = [[NSAttributedString alloc] 
                                initWithString:[NSString stringWithFormat:@"%lu %@",[self uniqueIdNumber],stateString] 
                                    attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:12] forKey:NSFontAttributeName]];
        
        [n drawInRect:NSMakeRect(10,[i size].height-18,[i size].width-20,16)];
        [n release];
		if(masterProcess){
            NSAttributedString* n = [[NSAttributedString alloc]
                                     initWithString:[NSString stringWithFormat:@"%@",masterProcess?@"Master":@""]
                                     attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:12] forKey:NSFontAttributeName]];
           
            NSSize theIconSize = [[self image] size];
            NSSize textSize = [n size];
            float x = theIconSize.width/2 - textSize.width/2 + 30;
            [n drawInRect:NSMakeRect(x,[i size].height-18,textSize.width,textSize.height)];


            [n release];
        }
		if(keepHistory && [historyFile length]){
			NSAttributedString* n = [[NSAttributedString alloc] 
									 initWithString:@"History" 
									 attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:12] forKey:NSFontAttributeName]];
			
			[n drawInRect:NSMakeRect([i size].width-[n size].width-10,[i size].height-18,[i size].width-20,16)];
			[n release];
		}
		if(outOfRangeLowCount && processRunning){
			NSAttributedString* n = [[NSAttributedString alloc]
									 initWithString:[NSString stringWithFormat:@"%d Lo",outOfRangeLowCount]
									 attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont labelFontOfSize:12],NSFontAttributeName,[NSColor redColor],NSForegroundColorAttributeName,nil] ];
			
            [n drawInRect:NSMakeRect(80,[i size].height-18,[i size].width-20,16)];
			[n release];
		}
		if(outOfRangeHiCount && processRunning){
			NSAttributedString* n = [[NSAttributedString alloc]
									 initWithString:[NSString stringWithFormat:@"%d Hi",outOfRangeHiCount]
									 attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont labelFontOfSize:12],NSFontAttributeName,[NSColor redColor],NSForegroundColorAttributeName,nil] ];
			
            [n drawInRect:NSMakeRect(120,[i size].height-18,[i size].width-20,16)];
			[n release];
		}

    }

    if([shortName length]){
        NSAttributedString* n = [[NSAttributedString alloc] 
                                initWithString:shortName
                                    attributes:[NSDictionary dictionaryWithObject:[NSFont labelFontOfSize:12] forKey:NSFontAttributeName]];
        
		NSSize theIconSize = [[self image] size];
        NSSize textSize = [n size];
        float x = theIconSize.width/2 - textSize.width/2;
        [n drawInRect:NSMakeRect(x,5,textSize.width,textSize.height)];
		[n release];
    }



    if(processRunning && inTestMode){
        NSImage* aNoticeImage = [NSImage imageNamed:@"notice"];
        [aNoticeImage drawAtPoint:NSMakePoint(0,0)fromRect:[aNoticeImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
        
    }
    if(processRunning){
        NSImage* aLockedImage = [NSImage imageNamed:@"smallLock"];
        [aLockedImage drawAtPoint:NSMakePoint([self frame].size.width - [aLockedImage size].width,0) fromRect:[aLockedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    }
	
	if([self heartBeatIndex] == 0){
        NSImage* noHeartbeatImage = [NSImage imageNamed:@"noHeartbeat"];
		float x;
		if(processRunning && inTestMode) x = 22;
		else x = 0;
        [noHeartbeatImage drawAtPoint:NSMakePoint(x,0) fromRect:[noHeartbeatImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
	}
	

    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
                postNotificationName:OROrcaObjectImageChanged
                              object:self];

}

- (void) makeMainController
{
    [self linkToController:@"ORProcessController"];
}

- (int) compareStringTo:(id)anElement usingKey:(NSString*)aKey
{
    NSString* ourKey   = [self valueForKey:aKey];
    NSString* theirKey = [anElement valueForKey:aKey];
    if(!ourKey && theirKey)         return 1;
    else if(ourKey && !theirKey)    return -1;
    else if(!ourKey || !theirKey)   return 0;
    return [ourKey compare:theirKey];
}

- (void) startRun
{
	//@synchronized(self){
		
		[self registerNotificationObservers];
		
        NSArray* outputNodes = [self collectObjectsRespondingTo:@selector(isTrueEndNode)];

        if([outputNodes count] == 0){
            NSLog(@"%@ has no output nodes. Process NOT started... nothing to do!\n",shortName);
            return;
        }
        
        if(![[ORProcessThread  sharedProcessThread] nodesRunning:outputNodes]){
            [[ORProcessThread  sharedProcessThread] startNodes:outputNodes];
            [self setProcessRunning:YES];
            NSString* t = inTestMode?@"(Test Mode)":@"";
            if([shortName length])NSLog(@"%@ Started %@\n",shortName,t);
            else NSLog(@"Process %d Started %@\n",[self uniqueIdNumber],t);
            
            writeHeader = YES;
            [self incrementProcessRunNumber];
            
            if(inTestMode){
                [self postTestAlarm];
            }
            else {
                if(sendOnStart){
                    [self performSelector:@selector(setSendStartNoticeNextReadAfterDelay) withObject:nil afterDelay:20];
                }
            }
        }
   // }
}

- (void) stopRun
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver:self];

	NSArray* outputNodes = [self collectObjectsRespondingTo:@selector(isTrueEndNode)];
	//NSArray* outputNodes = [self collectObjectsOfClass:NSClassFromString(@"ORProcessEndNode")];
    if([[ORProcessThread  sharedProcessThread] nodesRunning:outputNodes]){
		[self clearTestAlarm];
		[[ORProcessThread  sharedProcessThread] stopNodes:outputNodes];
		[self setProcessRunning:NO];
		NSString* t = inTestMode?@"(Test Mode)":@"";
		if([shortName length])NSLog(@"%@ Stopped %@\n",shortName,t);
		else NSLog(@"Process %d Stopped %@\n",[self uniqueIdNumber],t);
		
		if(!inTestMode && sendOnStop){
			[self sendStartStopNotice:NO];
		}
	}
}

- (void) incrementProcessRunNumber
{
    NSUserDefaults* defaults 	= [NSUserDefaults standardUserDefaults];
    NSString* aKey = [NSString stringWithFormat:@"Process%luRunNumber",[self uniqueIdNumber]];
    int n = [[defaults objectForKey:aKey] intValue];
    [defaults setObject:[NSNumber numberWithInt:n+1] forKey:aKey];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelRunNumberChanged object: self];
}

- (int) processRunNumber
{
    NSUserDefaults* defaults 	= [NSUserDefaults standardUserDefaults];
    NSString* aKey = [NSString stringWithFormat:@"Process%luRunNumber",[self uniqueIdNumber]];
    return [[defaults  objectForKey:aKey] intValue];
}

- (void) startStopRun
{
	NSArray* outputNodes = [self collectObjectsRespondingTo:@selector(isTrueEndNode)];
//    NSArray* outputNodes = [self collectObjectsOfClass:NSClassFromString(@"ORProcessEndNode")];
    if([[ORProcessThread  sharedProcessThread] nodesRunning:outputNodes]){
		[self clearTestAlarm];
		[self stopRun];
    }
    else {
		if(inTestMode){
			[self postTestAlarm];
		}
		[self startRun];
    }
}

- (BOOL) changesAllowed
{
    return ![gSecurity isLocked:ORDocumentLock] && ![self processRunning];
}

- (Class) guardianClass 
{
    return NSClassFromString(@"ORGroup");
}
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return [aGuardian isMemberOfClass:NSClassFromString(@"ORGroup")] ||
		   [aGuardian isMemberOfClass:NSClassFromString(@"ORContainerModel")];
}

- (void) setUniqueIdNumber :(unsigned long)aNumber
{
    [super setUniqueIdNumber:aNumber];
    [self setUpImage];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORForceRedraw
                      object: self];
}


#pragma mark ¥¥¥Sample Timing Control
- (void) runNow:(NSNotification*)aNote
{
	if(processRunning){
		sampleGateOpen = YES;
		[self startProcessCycle];
		[self endProcessCycle];
	}
}

- (void) pollNow
{
	if(processRunning){
		sampleGateOpen = YES;
	}
}

- (BOOL) sampleGateOpen
{
	return sampleGateOpen;
}

- (void)processIsStarting
{
	@synchronized(self){
		[lastSampleTime release];
		lastSampleTime = [[NSDate date] retain];
	}
}

- (void) startProcessCycle
{
    outOfRangeHiCount=0;
    outOfRangeLowCount=0;
    
	if(processRunning){
		if(!sampleGateOpen){
			NSDate* now = [NSDate date];
			if([now timeIntervalSinceDate:lastSampleTime] >= 1.0/sampleRate){
				sampleGateOpen  = YES;
			}
		}
	}
}

- (void) endProcessCycle
{
	if(processRunning){
		if(sampleGateOpen){
			@synchronized(self){
				[lastSampleTime release];
				lastSampleTime = [[NSDate date] retain];
				
				if(sendStartNoticeNextRead){
					sendStartNoticeNextRead = NO;
					[self sendStartStopNotice:YES];
				}
			}
		}
		sampleGateOpen = NO;
        
		if(lastOutOfRangeLowCount!=outOfRangeLowCount || lastOutOfRangeHiCount!=outOfRangeHiCount){
            if(lastOutOfRangeLowCount!=outOfRangeLowCount){
                lastOutOfRangeLowCount=outOfRangeLowCount;
            }
            if(lastOutOfRangeHiCount!=outOfRangeHiCount){
                lastOutOfRangeHiCount=outOfRangeHiCount;
            }
            [self setUpImage];
        }
        @synchronized(self){
            if(keepHistory && [historyFile length]){
                NSString* header = @"# SampleTime";
                if(writeHeader){
                    for(id anObj in [self orcaObjects]){
                        if([anObj isKindOfClass:NSClassFromString(@"ORAdcModel")]){
                            header = [header stringByAppendingFormat:@"\t%@",[anObj iconLabel]];
                        }
                    }
                    header = [header stringByAppendingString:@"\n"];
                }
                
                NSString* s = @"";
                for(id anObj in [self orcaObjects]){
                    if([anObj isKindOfClass:NSClassFromString(@"ORAdcModel")]){
                        NSString* theValue = [anObj iconValue];
                        theValue = [theValue trimSpacesFromEnds];
                        int firstSpace = [theValue rangeOfString:@" "].location;
                        if(firstSpace!=NSNotFound) theValue = [theValue substringToIndex:firstSpace];
                        
                        s = [s stringByAppendingFormat:@"\t%@",theValue ];
                    }
                }
                if([s length]){
                    //get the time(UT!)
                    time_t	ut_Time;
                    time(&ut_Time);
                    if(ut_Time - lastHistorySample >= 10){
                        lastHistorySample = ut_Time;
                        NSString* finalString = [NSString stringWithFormat:@"%lu%@\n",ut_Time,s];
                        if(writeHeader){
                            finalString = [header stringByAppendingString:finalString];
                            writeHeader = NO;
                        }
                        NSString* fullPath = [[historyFile stringByExpandingTildeInPath] stringByAppendingFormat:@"_%d",[self processRunNumber]];
                        NSFileManager* fm = [NSFileManager defaultManager];
                        if(![fm fileExistsAtPath: fullPath]){
                            [finalString writeToFile:fullPath atomically:NO encoding:NSASCIIStringEncoding error:nil];
                        }
                        else {
                            NSFileHandle* fh = [NSFileHandle fileHandleForUpdatingAtPath:fullPath];
                            [fh seekToEndOfFile];
                            [fh writeData:[finalString dataUsingEncoding:NSASCIIStringEncoding]];
                            [fh closeFile];
                            [self checkForAchival];
                        }
                    }
                }
            }
        }
	}
    else {
        lastOutOfRangeLowCount=0;
        lastOutOfRangeHiCount=0;
        outOfRangeLowCount=0;
        outOfRangeHiCount=0;
    }
}

- (void) checkForAchival
{
	NSFileManager* fm = [NSFileManager defaultManager];
    NSString* fullPath = [[historyFile stringByExpandingTildeInPath] stringByAppendingFormat:@"_%d",[self processRunNumber]];
	NSDictionary* attrib = [fm attributesOfItemAtPath:fullPath error:nil];
	if(attrib){
		NSDate* creationDate = [attrib objectForKey:NSFileCreationDate];
		NSTimeInterval fileAge = fabs([creationDate timeIntervalSinceNow]);	
        if(fileAge >= 60*60*24*7){
			NSDate* now = [NSDate date];
			NSFileManager* fm = [NSFileManager defaultManager];
			NSString* folderPath = [[fullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"History"];
			if(![fm fileExistsAtPath: folderPath]){
				[fm createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
			}
			
			NSString* newPath = [folderPath stringByAppendingPathComponent:[fullPath lastPathComponent]];
            newPath = [newPath stringByAppendingFormat:@"_%@",[now descriptionFromTemplate:@"yy_MM_dd_HH_mm_ss"]];
			[fm moveItemAtPath:fullPath toPath:newPath error:nil];
			writeHeader = YES;
            [self incrementProcessRunNumber];
		}
	}
}

- (NSDate*)	lastSampleTime
{
	NSDate* d;
	@synchronized(self){
		d =  [[lastSampleTime retain] autorelease];
	}
	return d;
}

- (NSMutableDictionary*) processDictionary
{
	NSMutableDictionary* aDictionary = [NSMutableDictionary dictionary];
	NSMutableArray* adcs = [NSMutableArray array];
	@synchronized(self){
		for(id anObj in [self orcaObjects]){
			if([anObj isKindOfClass:NSClassFromString(@"ORAdcModel")]){
				NSDictionary* anObjDictionary = [anObj valueDictionary];
				if([anObjDictionary count]){
					[adcs addObject:anObjDictionary];
				}
			}
		}
		if([adcs count])[aDictionary setObject:adcs forKey:@"adcs"];
	}
	return aDictionary;
}

- (NSString*) report
{
	NSString* s = @"";
	@synchronized(self){

		s =  [NSString stringWithFormat:@"\nProcess Name: %@ ",[self elementName]];
		if(processRunning){
			s = [s stringByAppendingString:@"[Running]\n"];
			s = [s stringByAppendingFormat:@"Sample Rate: %.3f Hz\n\n",sampleRate];
			
			//collect info from each type we want a report from...
			int adcCount   = 0;
			int inputCount = 0;
			int outputCount = 0;
			for(id anObj in [self orcaObjects]){
				if([anObj isKindOfClass:NSClassFromString(@"ORAdcModel")])     adcCount++;
				if([anObj isKindOfClass:NSClassFromString(@"ORInputElement")]) inputCount++;
				if([anObj isKindOfClass:NSClassFromString(@"OROutputRelayModel")]) outputCount++;
			}
			if(adcCount) {
				s = [s stringByAppendingFormat:@"--ADCs--\n"];
				for(id anObj in [self orcaObjects]){
					if([anObj isKindOfClass:NSClassFromString(@"ORAdcModel")]){
						s = [s stringByAppendingFormat:@"%@\n",[anObj report]];
					}
				}
				s= [s stringByAppendingString:@"\n"];
			}

			if(inputCount) {
				s = [s stringByAppendingFormat:@"--Binary Inputs--\n"];
				for(id anObj in [self orcaObjects]){
					if([anObj isKindOfClass:NSClassFromString(@"ORInputElement")]){
						s = [s stringByAppendingFormat:@"%@\n",[anObj report]];
					}
				}
				s= [s stringByAppendingString:@"\n"];
			}
			
			if(outputCount) {
				s = [s stringByAppendingFormat:@"--Binary Outputs--\n"];
				for(id anObj in [self orcaObjects]){
					if([anObj isKindOfClass:NSClassFromString(@"OROutputRelayModel")]){
						s = [s stringByAppendingFormat:@"%@\n",[anObj report]];
					}
				}
				s= [s stringByAppendingString:@"\n"];
			}
			if(adcCount){
				NSArray* couchObjs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORCouchDBModel")];
				if([couchObjs count]){
					ORCouchDBModel* couchObj = [couchObjs objectAtIndex:0];
					if(![couchObj replicationRunning]){
						s = [s stringByAppendingString:@"The Couch database is NOT being replicated to the remote host.\n"];
					}
					if(![couchObj keepHistory]){
						s = [s stringByAppendingString:@"The CouchDB object is NOT keeping a history.\n"];
					}
				}
			}

		}
		else {
			s = [s stringByAppendingString:@"[NOT RUNNING]\n"];
		}
		s = [s stringByAppendingString:@"\n"];
		
		
		
		
	}
	return s;
	
}

- (id) description
{
	NSString* s = @"";
	@synchronized(self){

		s =  [NSString stringWithFormat:@"\nProcess %@ ",[self elementName]];
		if(processRunning){
			s = [s stringByAppendingString:@"[Running]\n"];
			s = [s stringByAppendingFormat:@"Sample Rate: %.1f Hz\n",sampleRate];
			for(id anObj in [self orcaObjects]){
				if([anObj isKindOfClass:NSClassFromString(@"ORProcessHWAccessor")]){
					s = [s stringByAppendingFormat:@"%@\n",anObj];
				}
			}
		}
		else {
			s = [s stringByAppendingString:@"[NOT RUNNING]\n"];
		}
		s = [s stringByAppendingString:@"\n"];
	}
	return s;
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
	//after the document is loaded we use this flag to autostart
    updateImageForMasterChange = NO;
    [self setMasterProcess:[decoder decodeBoolForKey:@"masterProcess"]];
    updateImageForMasterChange = YES;
    [self setSendOnStop:[decoder decodeBoolForKey:@"sendOnStop"]];
    [self setSendOnStart:[decoder decodeBoolForKey:@"sendOnStart"]];
    [self setHeartBeatIndex:[decoder decodeIntForKey:@"heartBeatIndex"]];
    [self setEmailList:[decoder decodeObjectForKey:@"emailList"]];
    [self setHistoryFile:[decoder decodeObjectForKey:@"historyFile"]];
    [self setKeepHistory:[decoder decodeBoolForKey:@"keepHistory"]];
	wasRunning = [decoder decodeBoolForKey:@"wasRunning"];
	
    float aSampleRate = [decoder decodeFloatForKey:@"ORProcessModelSampleRate"];\
	if(aSampleRate == 0)aSampleRate = 10;
    [self setSampleRate:aSampleRate];
    [self setInTestMode:[decoder decodeIntForKey:@"inTestMode"]];
    [self setComment:[decoder decodeObjectForKey:@"comment"]];
    [self setShortName:[decoder decodeObjectForKey:@"shortName"]];
    [self setUseAltView:[decoder decodeBoolForKey:@"useAltView"]];
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:masterProcess forKey:@"masterProcess"];
    [encoder encodeBool:sendOnStop forKey:@"sendOnStop"];
    [encoder encodeBool:sendOnStart forKey:@"sendOnStart"];
    [encoder encodeInt:heartBeatIndex forKey:@"heartBeatIndex"];
    [encoder encodeObject:emailList forKey:@"emailList"];
    [encoder encodeObject:historyFile forKey:@"historyFile"];
    [encoder encodeBool:keepHistory forKey:@"keepHistory"];
    [encoder encodeFloat:sampleRate forKey:@"ORProcessModelSampleRate"];
    [encoder encodeInt:inTestMode forKey:@"inTestMode"];
    [encoder encodeObject:comment forKey:@"comment"];
    [encoder encodeObject:shortName forKey:@"shortName"];
    [encoder encodeBool:useAltView forKey:@"useAltView"];
	//store the running flag so we can auto start next time
    [encoder encodeBool:processRunning forKey:@"wasRunning"];
}

- (void) sendHeartbeatShutOffWarning
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendHeartbeatShutOffWarning) object:nil];
    
    NSArray* processes = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:[self class]];
    //check if there is another process that is the Master. If so it will handle this.
    if(![self masterProcess]){
        for(id aProcess in processes){
            if(aProcess == self) continue;
            if([aProcess masterProcess])return;
        }
    }

    
	NSString* theContent = @"";
	
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
	theContent = [theContent stringByAppendingFormat:@"Process: %@.\n",shortName];
	theContent = [theContent stringByAppendingFormat:@"The email heartbeat was shut off manually.\n"];
	theContent = [theContent stringByAppendingFormat:@"If this is unexpected you should contact the operator.\n"];
	theContent = [theContent stringByAppendingString:@"The following people received this message:\n"];
	for(id address in emailList) theContent = [theContent stringByAppendingFormat:@"%@\n",address];
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self cleanupAddresses:emailList],@"Address",theContent,@"Message",@"Shutdown",@"Shutdown",nil];
	[self sendMail:userInfo];
	
}

- (void) sendHeartbeat
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendHeartbeat) object:nil];
	if([self heartbeatSeconds]==0)return;
	
    NSArray* processes = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:[self class]];
    BOOL skipReport = NO;
    //check if there is another process that is the Master. If so it will do a heartbeat report.
    if(![self masterProcess]){
        for(id aProcess in processes){
            if(aProcess == self) continue;
            if([aProcess masterProcess]){
                skipReport = YES;
                break;
            }
        }
    }

    
	[self setNextHeartbeatString];
	
    if(!skipReport){
        NSString* theContent = @"";
        NSDate* theCurrentTime = [NSDate date];
        theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
        theContent = [theContent stringByAppendingFormat:@"This report was generated automatically by a process at:\n"];
        theContent = [theContent stringByAppendingFormat:@"%@ (Local time of ORCA machine)\n",theCurrentTime];
        theContent = [theContent stringByAppendingFormat:@"Unless changed in ORCA, it will be repeated at:\n"];
        theContent = [theContent stringByAppendingFormat:@"%@ (Local time of ORCA machine)\n%@ (UTC)\n",
                      nextHeartbeat, [nextHeartbeat utcDescription]];
        theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
        NSString* currentReport = [self report];

        theContent = [theContent stringByAppendingFormat:@"%@\n",currentReport];
        
        NSArray* processes = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:[self class]];
        if([self masterProcess]){
            for(id aProcess in processes){
                if(aProcess == self) continue;
                theContent = [theContent stringByAppendingFormat:@"%@\n",[aProcess report]];
            }
        }
        
        if([lastReportContent length] && (lastReportTime!=nil)){
            //append last report for comparision
            theContent = [theContent stringByAppendingString:@"\n"];
            theContent = [theContent stringByAppendingString:@"=====================================================\n"];
            theContent = [theContent stringByAppendingFormat:@"Last report sent %@ (Local ORCA Time)\n",lastReportTime];
            theContent = [theContent stringByAppendingString:@"Last report is appended for comparison.\n"];
            theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
            theContent = [theContent stringByAppendingFormat:@"%@\n",lastReportContent];
        }
        self.lastReportContent = currentReport;
        self.lastReportTime    = theCurrentTime;

        theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
        theContent = [theContent stringByAppendingString:@"The following people received this message:\n"];
        for(id address in emailList) theContent = [theContent stringByAppendingFormat:@"%@\n",address];
        theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];

        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self cleanupAddresses:emailList],@"Address",theContent,@"Message",nil];
        [self sendMail:userInfo];
    }
	
	if([self heartbeatSeconds]){
		[self performSelector:@selector(sendHeartbeat) withObject:nil afterDelay:[self heartbeatSeconds]];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendHeartbeat) object:nil];
	}
	
	for(id anObj in [self orcaObjects]){
		if([anObj isKindOfClass:NSClassFromString(@"ORAdcModel")]){
			[anObj resetReportValues];
		}
	}
}

- (void) sendStartStopNotice:(BOOL)state
{
    
    NSArray* processes = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:[self class]];
    ORProcessModel* emailSource = self;
    if(![self masterProcess]){
        for(id aProcess in processes){
            if(aProcess == self) continue;
            if([aProcess masterProcess]){
                emailSource = aProcess;
                break;
            }
        }
    }

	NSString* theContent = @"";
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
	theContent = [theContent stringByAppendingFormat:@"Process: %@ was %@\n",[self elementName], state?@"started":@"stopped"];
/*	if(state){
		theContent = [theContent stringByAppendingString:@"Some Values may not have had time to be updated\n"];	
		theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];	
		theContent = [theContent stringByAppendingFormat:@"%@\n",[self report]];
		theContent = [theContent stringByAppendingString:@"\n\n+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];		
	}
*/					
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
	theContent = [theContent stringByAppendingString:@"The following people received this message:\n"];
	for(id address in [emailSource emailList]) theContent = [theContent stringByAppendingFormat:@"%@\n",address];
	theContent = [theContent stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];						
	
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self cleanupAddresses:[emailSource emailList]],@"Address",theContent,@"Message",nil];
	[self sendMail:userInfo];
}

- (NSString*) cleanupAddresses:(NSArray*)aListOfAddresses
{
	NSMutableArray* listCopy = [NSMutableArray array];
	for(id anAddress in aListOfAddresses){
		if([anAddress length] && [anAddress rangeOfString:@"@"].location!= NSNotFound){
			[listCopy addObject:anAddress];
		}
	}
	return [listCopy componentsJoinedByString:@","];
}

- (int) heartbeatSeconds
{
	switch(heartBeatIndex){
		case 0: return 0;
		case 1: return 30*60;
		case 2: return 60*60;
		case 3: return 2*60*60;
		case 4: return 8*60*60;
		case 5: return 12*60*60;
		case 6: return 24*60*60;
		default: return 0;
	}
	return 0;
}

- (void) setNextHeartbeatString
{
	if([self heartbeatSeconds]){
		[nextHeartbeat release];
		nextHeartbeat = [[[NSDate date] dateByAddingTimeInterval:[self heartbeatSeconds]] retain];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORProcessModelNextHeartBeatChanged object:self];
	
}

- (NSDate*) nextHeartbeat
{
	return nextHeartbeat;
}


#pragma mark ¥¥¥EMail Thread
- (void) mailSent:(NSString*)address
{
	NSLog(@"Process Center status was sent to:\n%@\n",address);
}

- (void) sendMail:(NSDictionary*)userInfo
{
	NSString* address =  [userInfo objectForKey:@"Address"];
	NSString* content = [NSString string];
	NSString* hostAddress = @"<Unable to get host address>";
	NSArray* names =  [[NSHost currentHost] addresses];
	for(id aName in names){
		if([aName rangeOfString:@"::"].location == NSNotFound){
			if([aName rangeOfString:@".0.0."].location == NSNotFound){
				hostAddress = aName;
				break;
			}
		}
	}
	content = [content stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n"];
	content = [content stringByAppendingFormat:@"ORCA Message From Host: %@\n",hostAddress];
	content = [content stringByAppendingString:@"+++++++++++++++++++++++++++++++++++++++++++++++++++++\n\n"];
	NSString* theMessage = [userInfo objectForKey:@"Message"];
	if(theMessage){
		content = [content stringByAppendingString:theMessage];
	}
	NSString* shutDownWarning = [userInfo objectForKey:@"Shutdown"];
	if(shutDownWarning){
		//generated from a manual shutdown of the email system. 
		//don't send out any other info.
	}
	
	NSAttributedString* theContent = [[NSAttributedString alloc] initWithString:content];
	ORMailer* mailer = [ORMailer mailer];
	[mailer setTo:address];
	[mailer setSubject:@"Orca Message"];
	[mailer setBody:theContent];
	[mailer send:self];
	[theContent release];
}
@end

@implementation ORProcessModel (private)
- (void) setSendStartNoticeNextReadAfterDelay
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setSendStartNoticeNextReadAfterDelay) object:nil];

	sendStartNoticeNextRead = YES;
}
@end
