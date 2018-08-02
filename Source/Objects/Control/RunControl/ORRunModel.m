//
//  ORRunModel.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 24 2002.
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
#import "ORRunModel.h"
#import "ORDataProcessing.h"
#import "ORDataTaker.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"
#import "ORRunScriptModel.h"
#import "ORDecoder.h"

#pragma mark ¥¥¥Definitions

NSString* ORRunModelSelectedRunTypeScriptChanged = @"ORRunModelSelectedRunTypeScriptChanged";
NSString* ORRunModelShutDownScriptStateChanged	= @"ORRunModelShutDownScriptStateChanged";
NSString* ORRunModelStartScriptStateChanged		= @"ORRunModelStartScriptStateChanged";
NSString* ORRunModelShutDownScriptChanged		= @"ORRunModelShutDownScriptChanged";
NSString* ORRunModelStartScriptChanged			= @"ORRunModelStartScriptChanged";
NSString* ORRunRemoteInterfaceChangedNotification = @"ORRunRemoteInterfaceChangedNotification";
NSString* ORRunTimedRunChangedNotification      = @"RunModel TimedRun? Changed";
NSString* ORRunRepeatRunChangedNotification 	= @"RunModel RepeatRun? Changed";
NSString* ORRunTimeLimitChangedNotification 	= @"RunModel Time Limit Changed";
NSString* ORRunTimeToGoChangedNotification      = @"RunModel Time To Go Changed";
NSString* ORRunElapsedTimesChangedNotification	= @"RunModel Elapsed Times Changed";
NSString* ORRunStartTimeChangedNotification     = @"RunModel Start Time Changed";
NSString* ORRunNumberChangedNotification		= @"RunModel RunNumber Changed";
NSString* ORRunNumberDirChangedNotification     = @"The RunNumber Dir Changed";
NSString* ORRunModelExceptionCountChanged       = @"ORRunModelExceptionCountChanged";
NSString* ORRunTypeChangedNotification			= @"ORRunTypeChangedNotification";
NSString* ORRunRemoteControlChangedNotification = @"ORRunRemoteControlChangedNotification";
NSString* ORRunQuickStartChangedNotification    = @"ORRunQuickStartChangedNotification";
NSString* ORRunDefinitionsFileChangedNotification    = @"ORRunDefinitionsFileChangedNotification";
NSString* ORRunNumberLock						= @"ORRunNumberLock";
NSString* ORRunTypeLock							= @"ORRunTypeLock";
NSString* ORRunOfflineRunNotification			= @"ORRunOfflineRunNotification";
NSString* ORRunModelRunHalted                   = @"ORRunModelRunHalted";
NSString* ORRunModelNumberOfWaitsChanged        = @"ORRunModelNumberOfWaitsChanged";

static NSString *ORRunModelRunControlConnection = @"Run Control Connector";

#define kHeartBeatTime 30.0

@interface ORRunModel (private)
- (void) startRun:(BOOL)doInit;
- (void) waitOnObjects1:(NSNumber*)doInitBool;
- (void) continueWithRunStart:(NSNumber*)doInitBool;
- (void) startRunStage0:(NSNumber*)doInitBool;
- (void) startRunStage1:(NSNumber*)doInitBool;
- (void) startRunStage2:(NSNumber*)doInitBool;
- (void) startRunStage3:(NSNumber*)doInitBool;
- (void) stopRunStage1;
- (void) stopRunStage2;
- (void) startNewSubRunStage1;
- (void) startNewSubRunStage2;
- (void) prepareForNewSubRunStage1;
- (void) prepareForNewSubRunStage2;
- (void) waitForRunToStop;
- (void) finishRunStop;
@end

@implementation ORRunModel

#pragma mark ¥¥¥Initialization
- (id)init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setTimeLimit:3600];
    [self setDirName:@"~"];
	[self registerNotificationObservers];

    [[self undoManager] enableUndoRegistration];
    
    _ignoreMode = YES;

    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [objectsRequestingStateChangeWait release];
    [objectsRequestingRunStartAbort release];
    [shutDownScriptState release];
    [startScriptState release];
    [shutDownScript release];
    [startScript release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [timer invalidate];
    [timer release];
    timer = nil;
    
    [heartBeatTimer invalidate];
    [heartBeatTimer release];
    heartBeatTimer = nil;
	
    [dataPacket release];
	[runInfo release];
    [dirName release];
    [startTime release];
    [definitionsFilePath release];
    
    [runFailedAlarm clearAlarm];
    [runFailedAlarm release];
    
    [productionAlarm clearAlarm];
    [productionAlarm release];

    [runStoppedByVetoAlarm clearAlarm];
	[runStoppedByVetoAlarm release];
    
    [subRunStartTime release];
    [subRunEndTime release];
    [dataTypeAssigner release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
	[self setOfflineRun:[[ORGlobal sharedGlobal] runMode]];
}	

- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(postProductionAlarm) object:nil];
	runModeCache = [self offlineRun];
	[self setOfflineRun:NO];
    
    [productionAlarm clearAlarm];
    [productionAlarm release];
    productionAlarm = nil;
    
    [runStoppedByVetoAlarm clearAlarm];
    [runStoppedByVetoAlarm release];
    runStoppedByVetoAlarm = nil;

	[super sleep];
}

- (void) awakeAfterDocumentLoaded
{
	//[self setOfflineRun:[[ORGlobal sharedGlobal] runMode]];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self x]+[self frame].size.width - kConnectorSize,[self y]) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORRunModelRunControlConnection];
    [aConnector setOffColor:[NSColor purpleColor]];
    [aConnector setConnectorType:'RUNC'];
    [aConnector release];
}

- (void) makeMainController
{
    [self linkToController:@"ORRunController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Run_Control.html";
}

#define kRunStartStopIconRect NSMakeRect(3,3,25,25)
- (void) doShiftCmdClick:(id)sender atPoint:(NSPoint)aPoint
{
    if(enableIconControls){
        if(NSPointInRect(NSMakePoint(aPoint.x-[self frame].origin.x,aPoint.y-[self frame].origin.y),kRunStartStopIconRect)){
            if([self isRunning]) [self haltRun];
            else [self startRun];
        }
    }

}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage;
	if(![[ORGlobal sharedGlobal] anyVetosInPlace]){
		aCachedImage = [NSImage imageNamed:@"RunControl"];
	}
	else {
		aCachedImage = [NSImage imageNamed:@"RunControlVetoed"];
	}
    NSSize theIconSize = [aCachedImage size];
    NSPoint theOffset = NSZeroPoint;
    NSImage* netConnectIcon = nil;
    if(remoteControl){
        netConnectIcon = [NSImage imageNamed:@"NetConnect"];
        theIconSize.width += 10;
    }
    
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    if(remoteControl){
        [netConnectIcon drawAtPoint:NSZeroPoint fromRect:[netConnectIcon imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
        theOffset.x += 10;
    }
    [aCachedImage drawAtPoint:theOffset fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    if([[ORGlobal sharedGlobal] runMode] == kOfflineRun && !_ignoreMode){
        NSImage* aNoticeImage = [NSImage imageNamed:@"notice"];
        [aNoticeImage drawAtPoint:NSMakePoint(theOffset.x/2.+[i size].width/2-[aNoticeImage size].width/2 ,[i size].height/2-[aNoticeImage size].height/2) fromRect:[aNoticeImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    }
    
    if(enableIconControls){
        
        NSImage* theImage = nil;
        if([self isRunning])                                theImage = [NSImage imageNamed:@"Stop"];
        else if(![[ORGlobal sharedGlobal] anyVetosInPlace]) theImage = [NSImage imageNamed:@"Play"];
        
        [theImage drawInRect:kRunStartStopIconRect fromRect:[theImage imageRect] operation:NSCompositingOperationSourceOver fraction:1];
    }

	
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORForceRedraw
	 object: self];
    
}

#pragma mark ¥¥¥Accessors

- (NSInteger) selectedRunTypeScript
{
    return selectedRunTypeScript;
}

- (void) setSelectedRunTypeScript:(NSInteger)aSelectedRunTypeScript
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRunTypeScript:selectedRunTypeScript];
    [self setIgnoreSelectedScript:NO];
    selectedRunTypeScript = aSelectedRunTypeScript;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunModelSelectedRunTypeScriptChanged object:self];
}

- (void) selectRunTypeScriptByName:(NSString*)aName
{
    int i = 1; //zero is the standard run -- no script there
    NSArray* scriptList = [self runScriptList];
    for(NSString* scriptName in scriptList){
        if([scriptName isEqualToString: aName]){
            [self setSelectedRunTypeScript:i];
            break;
        }
        i++;
    }
}


- (NSString*) fullRunNumberString
{
	NSString* rn;
	if([self subRunNumber] > 0){
		rn = [NSString stringWithFormat:@"%u.%d",[self runNumber],[self subRunNumber]];
	}
	else {
		rn = [NSString stringWithFormat:@"%u",[self runNumber]];
	}
	return rn;
}

- (int) subRunNumber
{
    return subRunNumber;
}

- (void) setSubRunNumber:(int)aSubRunNumber
{
    subRunNumber = aSubRunNumber;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunNumberChangedNotification object:self];
}

- (NSString*) shutDownScriptState
{
	if(!shutDownScriptState)return @"---";
	else  return shutDownScriptState;
}

- (void) setShutDownScriptState:(NSString*)aShutDownScriptState
{
	if(!aShutDownScriptState)aShutDownScriptState = @"---";
    [shutDownScriptState autorelease];
    shutDownScriptState = [aShutDownScriptState copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunModelShutDownScriptStateChanged object:self];
}

- (NSString*) startScriptState
{
	if(!startScriptState)return @"---";
    return startScriptState;
}

- (void) setStartScriptState:(NSString*)aStartScriptState
{
	if(!aStartScriptState)aStartScriptState = @"---";
    [startScriptState autorelease];
    startScriptState = [aStartScriptState copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunModelStartScriptStateChanged object:self];
}

- (ORRunScriptModel*) shutDownScript
{
    return shutDownScript;
}

- (void) setShutDownScript:(ORRunScriptModel*)aShutDownScript
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShutDownScript:shutDownScript];
    
    [aShutDownScript retain];
    [shutDownScript release];
    shutDownScript = aShutDownScript;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunModelShutDownScriptChanged object:self];
}

- (ORRunScriptModel*) startScript
{
    return startScript;
}

- (void) setStartScript:(ORRunScriptModel*)aStartScript
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartScript:startScript];
    
    [aStartScript retain];
    [startScript release];
    startScript = aStartScript;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunModelStartScriptChanged object:self];
}

- (BOOL) runPaused
{
	return runPaused;
}

- (void) setRunPaused:(BOOL)aFlag
{    
	runPaused = aFlag;
	
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithInt:runningState], ORRunStatusValue,
							  runState[runningState],				 ORRunStatusString,
							  [NSNumber numberWithLong:runType],	 ORRunTypeMask,
							  [NSNumber numberWithInt:runPaused],	@"ORRunPaused",
							  nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunStatusChangedNotification object: self userInfo: userInfo];

}

- (BOOL) remoteInterface
{
	return remoteInterface;
}
- (void) setRemoteInterface:(BOOL)aRemoteInterface
{
	[[[self undoManager] prepareWithInvocationTarget:self] setRemoteInterface:remoteInterface];
    
	remoteInterface = aRemoteInterface;
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunRemoteInterfaceChangedNotification
	 object:self];
}

- (NSArray*) runTypeNames
{
    if(definitionsFilePath && !runTypeNames){
        [self readRunTypeNames];
    }
    return runTypeNames;
}

- (void) setRunTypeNames:(NSMutableArray*)aRunTypeNames
{
    [aRunTypeNames retain];
    [runTypeNames release];
    runTypeNames = aRunTypeNames;
}

- (uint32_t)getCurrentRunNumber
{
    if(!remoteControl || remoteInterface){
        NSString* fullFileName = [[[self dirName]stringByExpandingTildeInPath] stringByAppendingPathComponent:@"RunNumber"];
        NSString* s = [NSString stringWithContentsOfFile:fullFileName encoding:NSASCIIStringEncoding error:nil];
        runNumber = (uint32_t)[s integerValue];
    }
    
    return runNumber;
}

- (uint32_t)runNumber
{
    return runNumber;
}

- (void) setRunNumber:(uint32_t)aRunNumber
{
    runNumber = aRunNumber;
    
    if(!remoteControl || remoteInterface){
        NSString* fullFileName = [[[self dirName]stringByExpandingTildeInPath] stringByAppendingPathComponent:@"RunNumber"];
        NSFileManager* fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:fullFileName] == NO){
            if([fileManager createFileAtPath:fullFileName contents:nil attributes:nil]){
                NSLog(@"created <%@>\n",fullFileName);
            }
            else NSLog(@"Could NOT create <%@>\n",fullFileName);
        }
        NSFileHandle* file = [NSFileHandle fileHandleForWritingAtPath:fullFileName];
        NSString* s = [NSString stringWithFormat:@"%u",runNumber];
        
        [file writeData:[NSData dataWithBytes:[s cStringUsingEncoding:NSASCIIStringEncoding] length:[s length]+1]];
        [file closeFile];
        
    }
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunNumberChangedNotification
	 object: self];
}

- (BOOL) isRunning
{
	return [self runningState] != eRunStopped;
}

- (BOOL) isStopped
{
    return [self runningState] == eRunStopped;
}

- (BOOL) isRunInProgress
{
    return [self runningState] == eRunInProgress;
}

- (BOOL) isRunBetweenSubRuns
{
    return [self runningState] == eRunBetweenSubRuns;
}

- (NSString*) startTimeAsString
{
    return [startTime description];
}

- (NSDate*)startTime
{
    return startTime;
}

- (void) setStartTime:(NSDate*)aDate
{
    [aDate retain];
    [startTime release];
    startTime = aDate;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunStartTimeChangedNotification
	 object: self];
}

- (NSDate*)subRunStartTime
{
    return subRunStartTime;
}

- (void) setSubRunStartTime:(NSDate*)aDate
{
    [aDate retain];
    [subRunStartTime release];
    subRunStartTime = aDate;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunStartTimeChangedNotification
	 object: self];
}
- (NSDate*)subRunEndTime
{
    return subRunEndTime;
}

- (void) setSubRunEndTime:(NSDate*)aDate
{
    [aDate retain];
    [subRunEndTime release];
    subRunEndTime = aDate;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunStartTimeChangedNotification
	 object: self];
}

- (NSString*) elapsedRunTimeString
{
	return [self elapsedTimeString:[self elapsedRunTime]];
}

- (NSString*) elapsedTimeString:(NSTimeInterval) aTimeInterval;

{
	if([self isRunning]){
		int hr = aTimeInterval/3600;
		int min =(aTimeInterval - hr*3600)/60;
		int sec = aTimeInterval - hr*3600 - min*60;
		return [NSString stringWithFormat:@"%02d:%02d:%02d",hr,min,sec];
	}
	else return @"---";
}

- (NSTimeInterval) elapsedRunTime
{
    return elapsedRunTime;
}

- (NSString*) endOfRunState
{
	if([self isRunning]){
		if(timedRun){
			if(repeatRun){
				return @"Until Repeating";
			}
			else return @"Until Stopping";
		}
		else return @"";

	}
	else return @"";
}

- (void) setElapsedRunTime:(NSTimeInterval)aValue
{
    elapsedRunTime = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunElapsedTimesChangedNotification
	 object: self];
}


- (NSTimeInterval)  elapsedSubRunTime
{
	return elapsedSubRunTime;
}

- (void)	setElapsedSubRunTime:(NSTimeInterval) aValue
{
    elapsedSubRunTime = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunElapsedTimesChangedNotification
	 object: self];
}

- (NSTimeInterval)  elapsedBetweenSubRunTime
{
	return elapsedBetweenSubRunTime;
}

- (void)	setElapsedBetweenSubRunTime:(NSTimeInterval) aValue
{
    elapsedBetweenSubRunTime = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunElapsedTimesChangedNotification
	 object: self];
}


- (NSTimeInterval) timeToGo
{
    return timeToGo;
}

- (void) setTimeToGo:(NSTimeInterval)aValue
{
    timeToGo = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunTimeToGoChangedNotification
	 object: self];
}

- (BOOL)timedRun
{
    return timedRun;
}

- (void) setTimedRun:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimedRun:[self timedRun]];
    timedRun = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunTimedRunChangedNotification
	 object: self];
}

- (BOOL)repeatRun
{
    return repeatRun;
}

- (void) setRepeatRun:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatRun:[self repeatRun]];
    repeatRun = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunRepeatRunChangedNotification
	 object: self];
}

- (NSTimeInterval) timeLimit
{
    return timeLimit;
}

- (void) setTimeLimit:(NSTimeInterval)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeLimit:[self timeLimit]];
    timeLimit = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunTimeLimitChangedNotification
	 object: self];
}


- (ORDataPacket*)dataPacket
{
    return dataPacket;
}

- (void) setDataPacket:(ORDataPacket*)aDataPacket
{
    [aDataPacket retain];
    [dataPacket release];
    dataPacket = aDataPacket;
}


- (void) setDirName:(NSString*)aDirName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDirName:[self dirName]];
    
    [dirName autorelease];
    dirName = [aDirName copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunNumberDirChangedNotification
	 object: self];
    
}

- (NSString*)dirName
{
    return dirName;
}

- (uint32_t)	runType
{
    return runType;
}

- (void) setMaintenanceRuns:(BOOL)aState
{
	uint32_t aMask = [self runType];
	if(aState)aMask |= eMaintenanceRunType;
	else      aMask &= ~eMaintenanceRunType;
	[self setRunType:aMask];
}

- (void) setRunType:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunType:runType];
    runType = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunTypeChangedNotification object: self];
}

- (void) setRunTypeAndModifySavedRunType:(uint32_t)aMask
{
    //find which bits user set or cleared
    int i;
    for(i=0;i<32;i++){
        BOOL newBit = (BOOL)((aMask   >> i) & 0x1);
        BOOL oldBit = (BOOL)((runType >> i) & 0x1);
        if(!oldBit && newBit){
            userSetRunTypes     |= (0x1<<i);
            userClearedRunTypes &= ~(0x1<<i);
        }
        else if(oldBit && !newBit){
            userClearedRunTypes |= (0x1<<i);
            userSetRunTypes     &= ~(0x1<<i);
        }
    }
    [self setRunType:aMask];
}

- (void) restoreSavedRunType
{
    savedRunType |= userSetRunTypes;
    savedRunType &= ~userClearedRunTypes;
    
    runType = savedRunType;
    
    userSetRunTypes = 0x0;
    userClearedRunTypes = 0x0;
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ORRunTypeChangedNotification
     object: self];
    
}

- (BOOL)remoteControl
{
    return remoteControl;
}
- (void) setRemoteControl:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRemoteControl:remoteControl];
    remoteControl = aState;
    if(remoteControl)NSLog(@"Remote Run Control.\n");
    else NSLog(@"Local Run Control.\n");
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunRemoteControlChangedNotification
	 object: self];
    
    if([self isRunning] && (remoteControl == NO)){
        _ignoreRunTimeout = YES;
    }
    [self setUpImage];
}


- (BOOL) quickStart
{
    return quickStart;
}

- (void) setQuickStart:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setQuickStart:quickStart];
    quickStart = flag;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunQuickStartChangedNotification
	 object: self];
    
}


- (uint32_t)  exceptionCount
{
    return exceptionCount;
}

- (void) clearExceptionCount
{
    exceptionCount = 0;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunModelExceptionCountChanged
	 object:self];
    
}

- (void) incExceptionCount
{
    ++exceptionCount;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunModelExceptionCountChanged
	 object:self];
}


- (BOOL) nextRunWillQuickStart
{
    return _nextRunWillQuickStart;
}

- (void) setNextRunWillQuickStart:(BOOL)state
{
    _nextRunWillQuickStart = state;
}

- (int) runningState
{
	int theState = 0;
	@synchronized(self){
		theState =  runningState;
	}
	return theState;
}

- (void) postProductionAlarm
{
    if(!productionAlarm){
        productionAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Production Run Stopped"] severity:kDataFlowAlarm];
        [productionAlarm setSticky:NO];
        [productionAlarm setHelpString:@"Data production has stopped."];
    }
    [productionAlarm setAcknowledged:NO];
    [productionAlarm postAlarm];

}
- (void) clearProductionAlarm
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(postProductionAlarm) object:nil];
    [productionAlarm clearAlarm];
    [productionAlarm release];
    productionAlarm = nil;
}

- (void) setRunningState:(int)aRunningState
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(postProductionAlarm) object:nil];
    if([[ORGlobal sharedGlobal]inProductionMode]){
        if(aRunningState == eRunInProgress) [self clearProductionAlarm];
        else {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(postProductionAlarm) object:nil];
            [self performSelector:@selector(postProductionAlarm) withObject:nil afterDelay:60*5];
        }
    }
    else [self clearProductionAlarm];
    
    runningState = aRunningState;
    
    [self setUpImage];
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithInt:runningState], ORRunStatusValue,
							  runState[runningState],				 ORRunStatusString,
							  [NSNumber numberWithLong:runType],	 ORRunTypeMask,
							  nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunStatusChangedNotification object: self userInfo: userInfo];
}

- (void) letRunStart
{
    //this should only be called from a runscript if they want to continue running while the run is in progress
    if(selectedRunTypeScript){
        NSArray* theScripts = [self collectObjectsOfClass:[ORRunScriptModel class]];
        for (ORRunScriptModel* aScript in theScripts){
            if([aScript selectionIndex] == selectedRunTypeScript){
                [aScript runOKSelectorNow]; //force the script to make it look like it finished OK
                break;
            }
        }
    }
}
- (void) quitSelectedRunScript
{
    if(selectedRunTypeScript){
        NSArray* theScripts = [self collectObjectsOfClass:[ORRunScriptModel class]];
        for (ORRunScriptModel* aScript in theScripts){
            if([aScript selectionIndex] == selectedRunTypeScript){
                [aScript stopScript]; //force the script to make it look like it finished OK
                break;
            }
        }
    }
  
}

//not private, but don't call
- (void) setForceRestart:(BOOL)aState
{
    [self setNextRunWillQuickStart:YES];
    _forceRestart = aState;
}

- (NSString *)definitionsFilePath
{
    return definitionsFilePath;
}

- (void) setDefinitionsFilePath:(NSString *)aDefinitionsFilePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDefinitionsFilePath:definitionsFilePath];
    
    [definitionsFilePath autorelease];
    definitionsFilePath = [aDefinitionsFilePath copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRunDefinitionsFileChangedNotification
	 object: self];
    
}

- (ORDataTypeAssigner *) dataTypeAssigner 
{ 
    return dataTypeAssigner; 
}

- (void) setDataTypeAssigner: (ORDataTypeAssigner *) aDataTypeAssigner
{
    [aDataTypeAssigner retain];
    [dataTypeAssigner release];
    dataTypeAssigner = aDataTypeAssigner;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

#pragma mark ¥¥¥Run Modifiers

//secret methods for dangerous uses in run scripts
- (void) startFromRunScript
{
    [self startRun];
}

- (void) stopFromRunScript
{
    [self stopRun];
}


- (void) startNoScriptRun
{
    [self setSelectedRunTypeScript:0];
    [self startRun];
}

- (void) startRun
{
	if([self runningState] == eRunStarting){
		NSLog(@"Start Run message received and ignored because run is already staring.\n");
	}
 	else if([self runningState] == eRunStopping){
		NSLog(@"Start Run message received and ignored because run is stopping.\n");
	}
	else if(![self isRunning]){
		[self setNextRunWillQuickStart:quickStart];
		id nextObject = [self objectConnectedTo:ORRunModelRunControlConnection];
		if([nextObject runModals]){
			[self startRun:!quickStart];
		}
		else {
			if([self isRunning])[self stopRun];
			else [self setRunningState:eRunStopped];
		}
	}
	else {
		NSLog(@"Start Run message received and ignored because run is not stopped.\n");
	}
}

- (void) restartRun
{
    [self setNextRunWillQuickStart:YES];
    if([self isRunning]){
        _forceRestart = YES;
       [self stopRun];
    }
    else [self startRun:!quickStart];
}

- (void) remoteStartRun:(uint32_t)aRunNumber
{
	if([[self document] isDocumentEdited])return;
	
	[self setRemoteInterface:NO];
    [self setNextRunWillQuickStart:NO];
    if(aRunNumber==0xffffffff){
        [self setRemoteControl:NO];
        [self getCurrentRunNumber];
        [self setRunNumber:[self runNumber]+1];
        [self setRemoteControl:YES];
    }
    else {
        [self setRemoteControl:YES];
        [self setRunNumber:aRunNumber];
    }
    if([self isRunning]){
        _forceRestart = YES;
        [self stopRun];
    }
    else {
        [self startRun:YES];
    }
}

- (void) remoteRestartRun:(uint32_t)aRunNumber
{
	[self setRemoteInterface:NO];
    if(aRunNumber==0xffffffff){
        [self setRemoteControl:NO];
        [self getCurrentRunNumber];
        [self setRunNumber:[self runNumber]+1];
        [self setRemoteControl:YES];
    }
    else {
        [self setRemoteControl:YES];
        [self setRunNumber:aRunNumber];
    }
    [self setNextRunWillQuickStart:YES];
    [self setRunNumber:aRunNumber];
    if([self isRunning]){
        _forceRestart = YES;
        [self stopRun];
    }
    else {
        [self startRun:NO];
    }    
}


- (void) prepareForNewSubRun
{
	if([self runningState] == eRunStarting){
		NSLog(@"Prepare for new subrun ignored because run is already staring.\n");
	}
 	else if([self runningState] == eRunStopping){
		NSLog(@"Prepare for new subrun ignored because run is stopping.\n");
	}
    else if([self runningState] == eRunBetweenSubRuns){
		NSLog(@"Prepare for new subrun ignored because run is already between sub runs.\n");
    }
	else if(![self isRunning] ){
		NSLog(@"Prepare for new subrun ignored -- no run in progress\n");
	}
	else {
        NSLog(@"Run %@ preparing for a new sub-run\n",[self fullRunNumberString]);
        [[NSNotificationCenter defaultCenter] postNotificationName:ORRunAboutToChangeState
                                                            object: self
                                                          userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:eRunBetweenSubRuns] forKey:@"State"]];
        [self prepareForNewSubRunStage1];
    }
}
- (void) prepareForNewSubRunStage1
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(prepareForNewSubRunStage1) object:nil];
    if([self waitRequestersCount]==0){
        [self prepareForNewSubRunStage2];
    }
    else {
        [self performSelector:@selector(prepareForNewSubRunStage1) withObject:nil afterDelay:0];
    }

}
- (void) prepareForNewSubRunStage2
{
    [self setRunningState:eRunBetweenSubRuns];
    [self setSubRunEndTime:[NSDate date]];
    [self setElapsedBetweenSubRunTime:0];
    //ship between sub run record
    //get the time(UT!)
    time_t	ut_time;
    time(&ut_time);
    //struct tm* theTimeGMTAsStruct = gmtime(&theTime);
    //time_t ut_time = mktime(theTimeGMTAsStruct);
    
    uint32_t data[4];
    data[0] = dataId | 4;
    data[1] = 0x10 | ([self subRunNumber]&0xffff)<<16;
    data[2] = lastRunNumberShipped;
    data[3] = (uint32_t)ut_time;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
                                                        object:[NSData dataWithBytes:data length:4*sizeof(int32_t)]];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunBetweenSubRunsNotification
                                                        object: self
                                                      userInfo: nil];
    
    
}
- (void) startNewSubRun
{
	if([self runningState] == eRunStarting){
		NSLog(@"Start new subrun ignored because run is still starting.\n");
	}
 	else if([self runningState] == eRunStopping){
		NSLog(@"Start for new subrun ignored because run is stopping.\n");
	}
	else if([self runningState]!=eRunBetweenSubRuns){
		NSLog(@"Start new subrun Ignored -- not between subruns\n");
	}
	else {
        [[NSNotificationCenter defaultCenter] postNotificationName:ORRunAboutToChangeState
                                                            object: self
                                                          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    [NSNumber numberWithInt:eRunStarting],@"State",
                                                                    [NSNumber numberWithBool:YES],        @"StartingSubRun",
                                                                    nil]];
    
        [self startNewSubRunStage1];
    }
}

- (void) startNewSubRunStage1
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startNewSubRunStage1) object:nil];
    if([self waitRequestersCount]==0){
        [self startNewSubRunStage2];
    }
    else {
        [self performSelector:@selector(startNewSubRunStage1) withObject:nil afterDelay:0];
    }
}


- (void) startNewSubRunStage2
{
    [self setSubRunNumber:[self subRunNumber]+1];
    [self setRunningState:eRunInProgress];
    [self setSubRunStartTime:[NSDate date]];
    [self setElapsedSubRunTime:0];
    //ship new sub run record
    //get the time(UT!)
    time_t	ut_time;
    time(&ut_time);
    
    //insert a header before the start of sub-run record
    [[self dataPacket] updateHeader];
    
    NSData* headerAsData = [ORDecoder convertHeaderToData:[[self dataPacket] fileHeader]];
    NSMutableData* dataToBeInserted = [NSMutableData dataWithData:headerAsData];
    
    uint32_t data[4];
    data[0] = dataId | 4;
    data[1] = 0x20 | ([self subRunNumber]&0xffff)<<16;
    data[2] = lastRunNumberShipped;
    data[3] = (uint32_t)ut_time;
    
    [dataToBeInserted appendData:[NSMutableData dataWithBytes:data length:4*sizeof(int32_t)]];
    
    [dataPacket addData:dataToBeInserted];
    
    [runInfo setObject:[[self dataPacket]fileHeader]		  forKey:kHeader];
    [runInfo setObject:[NSNumber numberWithLong:runNumber]	  forKey:kRunNumber];
    [runInfo setObject:[NSNumber numberWithLong:subRunNumber] forKey:kSubRunNumber];
    
    id nextObject = [self objectConnectedTo:ORRunModelRunControlConnection];
    [nextObject subRunTaskStarted:runInfo];

    NSLog(@"Starting Run %@ (sub-run)\n",[self fullRunNumberString]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunStartSubRunNotification
                                                        object: self
                                                      userInfo: nil];
}

- (void) startRun:(BOOL)doInit
{
    //make sure to clear out any left overs
    [objectsRequestingRunStartAbort release];
    objectsRequestingRunStartAbort = nil;

	skipShutDownScript = NO;
    _forceRestart      = NO;
    if([self isRunning]){
        NSLogColor([NSColor redColor],@"Warning...Programming error..should not be able to\n");
        NSLogColor([NSColor redColor],@"Start a run while one is already in progress.\n");
        return;
    }

    [self setDataTypeAssigner:[[[ORDataTypeAssigner alloc] init]autorelease]];
    
    [dataTypeAssigner assignDataIds];

    //first call to see if any object needs to stop the run or do something to cause the run start process to wait
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunInitializationNotification
                                                        object: self
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:eRunStarting], @"State",
							  [NSNumber numberWithInt:doInit||forceFullInit], @"doinit",
    nil]];


    //------
    //at this stage, some object may need extra time. If so they will post a wait request
    [self waitOnObjects1:[NSNumber numberWithBool:doInit]];
}

- (void) waitOnObjects1:(NSNumber*)doInitBool
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waitOnObjects1:) object:doInitBool];
    if([self waitRequestersCount]==0){
        [self continueWithRunStart:doInitBool];
    }
    else {
        [self performSelector:@selector(waitOnObjects1:) withObject:doInitBool afterDelay:.01];
    }
}

- (void) continueWithRunStart:(NSNumber*)doInitBool
{
    if([objectsRequestingRunStartAbort count]){
        NSLog(@"Run was not started because one or more objects requested a run start abort\n");
        NSLog(@"%@\n",objectsRequestingRunStartAbort);
        
        [objectsRequestingRunStartAbort release];
        objectsRequestingRunStartAbort = nil;

        [self setRunningState:eRunStopped];
        return;
    }
    
    BOOL doInit = [doInitBool boolValue];

    
	//movedfrom startRunStage1 06/29/05 MAH to test remote run stuff
	[self getCurrentRunNumber];
	
	if([[ORGlobal sharedGlobal] runMode] == kNormalRun && (!remoteControl || remoteInterface)){
		[self setRunNumber:[self runNumber]+1];
		[self setSubRunNumber:0];
	}
	[self setRunningState:eRunStarting];
    
    [self performSelector:@selector(startRunStage0:) withObject:[NSNumber numberWithBool:doInit] afterDelay:0];
}

- (void) startRunStage0:(NSNumber*)doInitBool
{
    if(selectedRunTypeScript && !ignoreSelectedScript){
        savedRunType = runType; //run type scripts can changed the run type, but we need to change it back then at the end
        savedSelectedRunTypeScript = selectedRunTypeScript;
        NSArray* theScripts = [self collectObjectsOfClass:[ORRunScriptModel class]];
        for (ORRunScriptModel* aScript in theScripts){
            if([aScript selectionIndex] == selectedRunTypeScript){
                [aScript setSelectorOK:@selector(startRunStage1:) bad:@selector(runAbortFromScript) withObject:doInitBool target:self];
                if(![aScript runScript]){
                    [self runAbortFromScript];
                }
                break;
            }
        }
    }
    else [self performSelector:@selector(startRunStage1:) withObject:doInitBool afterDelay:0];
}

- (void) startRunStage1:(NSNumber*)doInitBool
{
    if(startScript){
        [startScript setSelectorOK:@selector(startRunStage2:) bad:@selector(runAbortFromScript) withObject:doInitBool target:self];
        [self setStartScriptState:@"Running"];
        if(![startScript runScript]){
            [self runAbortFromScript];
        }
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:ORRunSecondChanceForWait
                                                            object: self
                                                          userInfo:[NSDictionary dictionaryWithObject:doInitBool forKey:@"doinit"]];

        [self performSelector:@selector(startRunStage2:) withObject:doInitBool afterDelay:0];
    }
}

- (void) startRunStage2:(NSNumber*)doInitBool
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startRunStage2:) object:doInitBool];
    if([self waitRequestersCount]==0){
        [[NSNotificationCenter defaultCenter] postNotificationName:ORRunAboutToChangeState
                                                            object: self
                                                          userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:eRunStarting] forKey:@"State"]];
        [self startRunStage3:doInitBool];
    }
    else {
        [self performSelector:@selector(startRunStage2:) withObject:doInitBool afterDelay:0];
    }
}

- (void) startTimer
{
    [timer invalidate];
    [timer release];
    timer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(incrementTime:)userInfo:nil repeats:YES] retain];
}

- (void) startRunStage3:(NSNumber*)doInitBool
{
	if(startScript){
		[self setShutDownScriptState:@"---"];
		[self setStartScriptState:@"Done"];
	}
	
	BOOL doInit = [doInitBool boolValue];
    @try {
        [runFailedAlarm clearAlarm];
        client =  [self objectConnectedTo: ORRunModelRunControlConnection];
                
        [self runStarted:doInit];
        
        //start the threaddo
        if(dataTakingThreadRunning){
            NSLogColor([NSColor redColor],@"*****runthread still exists\n");
        }
		
		timeToStopTakingData = NO;
		
		//now declare the thread directly so we can set the stack size.
		//[NSThread detachNewThreadSelector:@selector(takeData) toTarget:self withObject:nil];
        readoutThread = [[NSThread alloc] initWithTarget:self selector:@selector(takeData) object:nil];
		[readoutThread setStackSize:5*1024*1024];
		[readoutThread start];
		 
        [self setStartTime:[NSDate date]];
	[self setSubRunStartTime:[NSDate date]];
	[self setElapsedRunTime:0];
        [self setElapsedSubRunTime:0];

        [self startTimer];
        
        [[ORGlobal sharedGlobal] checkRunMode];
        
        [self setRunningState:eRunInProgress];
		
        _ignoreRunTimeout = NO;
		
		//one final check of the vetos in case one was posted during start up
		[self checkVetos];
	}
	@catch(NSException* localException) {
        //[self stopRun];
        [self setRunningState:eRunStopped];
        
		if(!runFailedAlarm){
			runFailedAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Run %u did NOT start",[self runNumber]] severity:kRunInhibitorAlarm];
			[runFailedAlarm setSticky:YES];
		}
		[runFailedAlarm setAcknowledged:NO];
		[runFailedAlarm postAlarm];
        
        //NSLogColor([NSColor redColor],@"Run Not Started because of exception: %@\n",[localException name]);
        NSLogColor([NSColor redColor],@"Run Not Started because of exception: %@, reason: %@\n",[localException name],[localException reason]);//please show more info -tb-
        
    }
}

- (void) setOfflineRun:(BOOL)offline
{
	[[ORGlobal sharedGlobal] setRunMode:offline]; //0 = NormalRun, 1= offlineRun
    id nextObject = [self objectConnectedTo:ORRunModelRunControlConnection];
	[nextObject setRunMode:offline];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRunOfflineRunNotification
                                                        object: self
                                                      userInfo: nil];
}

- (void) setIgnoreSelectedScript:(BOOL)aFlag
{
    ignoreSelectedScript = aFlag;
}

//SV
- (void) setIgnoreRepeat:(BOOL)aFlag
{
    ignoreRepeat = aFlag;
}

- (BOOL) offlineRun
{
	return [[ORGlobal sharedGlobal] runMode];
}

- (void) remoteHaltRun
{
    if(remoteControl){
		ignoreRepeat = YES;
        [self haltRun];
    }
}

- (void) remoteStopRun:(BOOL)fullInitNextRun
{
	[self setRemoteInterface:NO];
    if(remoteControl){
		[self setNextRunWillQuickStart:fullInitNextRun];
		ignoreRepeat = YES;
        [self stopRun];
        [self setRemoteControl:NO];
    }
}

- (void) runAbortFromScript
{
	NSLogColor([NSColor redColor], @"Run startup aborted by script!\n");
	if(shutDownScript){
		NSLogColor([NSColor redColor], @"Shutdown script will NOT be run!\n");
		skipShutDownScript = YES;
	}
	[self haltRun];
}

- (void) haltRun
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunModelRunHalted object: self];
    ignoreRepeat = YES;
	[self stopRun];
}

- (void) stopRun
{
    if([self runningState] == eRunStopping){
		NSLog(@"Stop Run message received and ignored because run is already stopping.\n");
	}
	else if([self runningState] == eRunStarting && !startScript && !selectedRunTypeScript ){
		NSLog(@"Stop Run message received and ignored because run is starting.\n");
	}
	else if([self runningState] == eRunStopped){
		NSLog(@"Stop Run message received and ignored because no run in progress.\n");
	}
	else {
        [[NSNotificationCenter defaultCenter] postNotificationName:ORRunAboutToChangeState
                                                            object: self
                                                          userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:eRunStopping] forKey:@"State"]];
        [self stopRunStage1];
    }
}


- (void) stopRunStage1
{
	if([self runningState] == eRunStopping){
		NSLog(@"Stop Run message received and ignored because run is already stopping.\n");
	}
	else if([self runningState] == eRunStarting && !startScript && !selectedRunTypeScript){
		NSLog(@"Stop Run message received and ignored because run is starting.\n");
	}
	else if([self runningState] == eRunStopped){
		NSLog(@"Stop Run message received and ignored because no run in progress.\n");
	}
	else {
		[self setShutDownScriptState:@"---"];
		[self setStartScriptState:@"---"];
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		
		@try {
            BOOL willRestart = _forceRestart ||([self timedRun] && [self repeatRun] && !ignoreRepeat && (!remoteControl || remoteInterface));
            NSDictionary* userInfo = [NSDictionary
                                        dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithUnsignedLong:runNumber],kRunNumber,
                                        [NSNumber numberWithUnsignedLong:subRunNumber],kSubRunNumber,
                                        [NSNumber numberWithLong:[[ORGlobal sharedGlobal] runMode]],  kRunMode,
                                        [NSNumber numberWithFloat:elapsedRunTime],  kElapsedTime,
                                        [NSNumber numberWithBool:willRestart],@"willRestart",
                                        [NSNumber numberWithInt:!quickStart && willRestart], @"doinit",
                                        nil];

            [[NSNotificationCenter defaultCenter] postNotificationName:ORRunAboutToStopNotification
															object: self
														  userInfo: userInfo];
        }
        @catch(NSException* e){
            NSLog(@"Exception thrown and caught broadcasting the RunAboutToStop Notification. Apparently a HW error. %@\n",e);
        }
		
		[self setRunningState:eRunStopping];
		
		[timer invalidate];
		[heartBeatTimer invalidate];
		
		[timer release];
		timer = nil;
		
		[heartBeatTimer release];
		heartBeatTimer = nil;
		
		totalWaitTime = 0;
		
        [self stopRunStage2];
	}
}

- (void) stopRunStage2
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopRunStage2) object:nil];
    if([self waitRequestersCount]==0)[self waitForRunToStop];
    else {
        [self performSelector:@selector(stopRunStage2) withObject:nil afterDelay:0];
    }
}


- (void) needMoreTimeToStopRun:(NSNotification*)aNote
{
	totalWaitTime = 0;	
}

- (void) waitForRunToStop
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waitForRunToStop) object:nil];
    //wait for runthread to exit
    if(dataTakingThreadRunning){
		timeToStopTakingData= YES;
		totalWaitTime += .1;
		if(totalWaitTime > 15){
			NSLogColor([NSColor redColor], @"Run Thread Failed to stop.....You should stop and restart ORCA!\n");
			[self finishRunStop];
		}
		[self performSelector:@selector(waitForRunToStop) withObject:nil afterDelay:.1];
	}
	else {
		if(shutDownScript && !skipShutDownScript){
			[self setShutDownScriptState:@"Running"];
			[shutDownScript setSelectorOK:nil bad:nil withObject:nil target:self];
			[shutDownScript runScript];
		}
		[self finishRunStop];
	}
}


- (void) finishRunStop
{
	[self setStartScriptState:@"---"];
	[self setShutDownScriptState:@"---"];
	[dataTypeAssigner release];
	dataTypeAssigner = nil;
    
    
    id nextObject = [self objectConnectedTo:ORRunModelRunControlConnection];
    BOOL willRestart = _forceRestart ||([self timedRun] && [self repeatRun] && !ignoreRepeat && (!remoteControl || remoteInterface));
    
    @try {
        
		[nextObject setInvolvedInCurrentRun:NO];
        [nextObject runTaskStopped:runInfo];

		//[NSThread setThreadPriority:1];
		
	}
	@catch(NSException* localException) {
	}
	
    //SV - Moved this section from inside the try block. This way, there is always a run stopped notification
    NSDictionary* statusInfo = [NSDictionary
                                dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:eRunStopped],ORRunStatusValue,
                                [NSNumber numberWithUnsignedLong:runNumber],kRunNumber,
                                [NSNumber numberWithUnsignedLong:subRunNumber],kSubRunNumber,
                                [NSNumber numberWithLong:[[ORGlobal sharedGlobal] runMode]],  kRunMode,
                                [NSNumber numberWithFloat:elapsedRunTime],  kElapsedTime,
                                @"Not Running",ORRunStatusString,
                                [NSNumber numberWithBool:willRestart],@"willRestart",
                                [NSNumber numberWithInt:!quickStart && willRestart], @"doinit",
                                dataPacket,@"DataPacket",nil];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunStoppedNotification
                                                        object: self
                                                      userInfo: statusInfo];
    //SV - End of changes

    // If ORCA opened in the middle of a run, runInfo won't exist so must remake.
    if(!runInfo){
        runInfo = [[self runInfo] copy];
    }

    [nextObject preCloseOut:runInfo];
    
    // get the time(UT!)
    time_t ut_time;
    time(&ut_time);    
	
	uint32_t data[4];
	data[0] = dataId | 4;
	data[1] =  0;
	if(_wasQuickStart)data[1] |= 0x2;
	if(remoteControl) data[1] |= 0x4;
	data[1] |= ([self subRunNumber]&0xffff)<<16;
	data[2]  = lastRunNumberShipped;
	data[3]  = (uint32_t)ut_time;

	[dataPacket addLongsToFrameBuffer:data length:4];
    
    if(_nextRunWillQuickStart)_nextRunWillQuickStart = NO;

    // closeout run will wait until the processing thread is done.
    [nextObject closeOutRun:runInfo];

    [self setRunningState:eRunStopped];
	
    [dataTypeAssigner release];
    dataTypeAssigner = nil;
	
    [[self undoManager] disableUndoRegistration];
    if(savedSelectedRunTypeScript){
        [self restoreSavedRunType];
    }
    [[self undoManager] enableUndoRegistration];

    
    if(![self offlineRun])  NSLog(@"Run %u stopped.\n",[self runNumber]);
    else                    NSLog(@"Offline Run stopped.\n");

    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlushLogsNotification
                                                        object: self
                                                      userInfo: runInfo];

	if(willRestart){
		ignoreRepeat  = NO;
		_forceRestart = NO;
		[self restartRun];
	}
    


}

- (void) sendHeartBeat:(NSTimer*)aTimer
{
    uint32_t dataHeartBeat[4];
    
    dataHeartBeat[0] = dataId | 4; 
    dataHeartBeat[1] =         0x8; //fourth bit is the heart beat bit
    dataHeartBeat[2] = kHeartBeatTime;
    
    //get the time(UT!)
    time_t	ut_time;
    time(&ut_time);    
    dataHeartBeat[3] = (uint32_t)ut_time;
    
	[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
														object:[NSData dataWithBytes:dataHeartBeat length:4*sizeof(int32_t)]];
	
}

- (void) incrementTime:(NSTimer*)aTimer
{
    if([self isRunning]){
		if([self runningState] != eRunBetweenSubRuns){
			NSTimeInterval subRunDeltaTime = -[subRunStartTime timeIntervalSinceNow];
			[self setElapsedSubRunTime:subRunDeltaTime];
		}
		else if([self runningState] == eRunBetweenSubRuns){
			NSTimeInterval subRunDeltaTime = -[subRunEndTime timeIntervalSinceNow];
			[self setElapsedBetweenSubRunTime:subRunDeltaTime];
		}
		
        NSTimeInterval deltaTime = -[startTime timeIntervalSinceNow];
        [self setElapsedRunTime:deltaTime];
		
        if(!remoteControl || remoteInterface){
            NSTimeInterval t = (timeLimit - deltaTime)+1;
            if(t<0)t=0; //prevent negative values
            [self setTimeToGo:t];
            if(!_ignoreRunTimeout && timedRun &&(deltaTime >= timeLimit)){
                if(repeatRun){
                    [self setNextRunWillQuickStart:YES];
                    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunIsAboutToRollOver
                                                                        object:self];
                }
                [self stopRun];
            }
        }
    }
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    //get the time(UT!)
    time_t	ut_time;
    time(&ut_time);
    NSTimeInterval refTime = [NSDate timeIntervalSinceReferenceDate];
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class])            forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithLong:ut_time]          forKey:@"startTime"];
    [objDictionary setObject:[NSNumber numberWithFloat:refTime]         forKey:@"refTime"];
    [objDictionary setObject:[NSNumber numberWithBool:remoteControl]    forKey:@"remoteControl"];
    [objDictionary setObject:[NSNumber numberWithLong:runType]          forKey:@"runType"];
    [objDictionary setObject:[NSNumber numberWithBool:quickStart]       forKey:@"quickStart"];
    [objDictionary setObject:[NSNumber numberWithLong:[self runNumber]] forKey:@"RunNumber"];
    [objDictionary setObject:[NSNumber numberWithLong:[self subRunNumber]] forKey:@"SubRunNumber"];
    [dictionary setObject:objDictionary forKey:@"Run Control"];
    
    
    return objDictionary;
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORRunDecoderForRun",              @"decoder",
								 [NSNumber numberWithLong:dataId],   @"dataId",
								 [NSNumber numberWithBool:NO],       @"variable",
								 [NSNumber numberWithLong:4],        @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Run"];
    return dataDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORRunModel"];
}

- (NSDictionary*)runInfo
{
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithLong:runNumber],kRunNumber,
				[NSNumber numberWithLong:subRunNumber],kSubRunNumber,
				[NSNumber numberWithLong:[[ORGlobal sharedGlobal] runMode]],  kRunMode,
				nil];
}


- (void) runStarted:(BOOL)doInit
{
    [heartBeatTimer invalidate];
    [heartBeatTimer release];
    heartBeatTimer = nil;
    
    ignoreRepeat = NO;
    
    [self setDataPacket:[[[ORDataPacket alloc] init]autorelease]];
    [[self dataPacket] setRunNumber:[self runNumber]];
    
    [[self dataPacket] makeFileHeader];
   
    if([self remoteControl]){
        [[self dataPacket] setFilePrefix:@"R_Run"];
    }
    else {
        [[self dataPacket] setFilePrefix:@"Run"];
    }
    
    _currentRun = [self runNumber];
    
    NSArray* objs = [[self document]  collectObjectsRespondingTo:@selector(preRunChecks)];
    [objs makeObjectsPerformSelector:@selector(preRunChecks) withObject:nil];
    
	[runInfo release];
    //pack up some info about the run.
    runInfo = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
							  [dataPacket fileHeader], kHeader,
							  dataPacket,kDataPacket,
							  [NSNumber numberWithLong:runNumber],kRunNumber,
							  [NSNumber numberWithLong:subRunNumber],kSubRunNumber,
							  [NSNumber numberWithLong:[[ORGlobal sharedGlobal] runMode]],  kRunMode,
							  [NSNumber numberWithInt:doInit||forceFullInit], @"doinit",
							  nil] retain];
    
    //let others know the run is about to start
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunAboutToStartNotification
                                                        object: self
                                                      userInfo: runInfo];

    //tell them to start up
    id nextObject = [self objectConnectedTo:ORRunModelRunControlConnection];
    [nextObject runTaskStarted:runInfo];
    [nextObject setInvolvedInCurrentRun:YES];
	
    //tell them it has been started.
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunStartedNotification
                                                        object: self
                                                      userInfo: runInfo];
    
	NSLog(@"---------------------------------------\n");
    
    if([[ORGlobal sharedGlobal] runMode] == kNormalRun){
        if(!forceFullInit)NSLog(@"Run %u started(%@).\n",[self runNumber],doInit?@"cold start":@"quick start");
		else NSLog(@"Run %u started(%@).\n",[self runNumber],@"Full Init because of Pwr Failure");
    }
    else {
        NSLog(@"Offline Run started(%@).\n",doInit?@"cold start":@"quick start");
    }
    
    forceFullInit = NO;
    
    heartBeatTimer = [[NSTimer scheduledTimerWithTimeInterval:kHeartBeatTime target:self selector:@selector(sendHeartBeat:)userInfo:nil repeats:YES] retain];

	//get the time(UT!)
    time_t	ut_time;
    time(&ut_time);
 
	NSData* headerAsData = [ORDecoder convertHeaderToData:[[self dataPacket] fileHeader]];
 	[dataPacket addData:[NSMutableData dataWithData:headerAsData]];
 
    uint32_t data[4];
    
    data[0] = dataId | 4;
    data[1] = 0x01   | 0x20; //start of run and first sub run
    _wasQuickStart = !doInit;
    
    if(_wasQuickStart){
        data[1] |= 0x2;
        _nextRunWillQuickStart = NO;
    }
    if(remoteControl){
        data[1] |= 0x4;			//set the remotebit
    }
	
    data[2] = [self runNumber];
    data[3] = (uint32_t)ut_time;

	[dataPacket addData:[NSMutableData dataWithBytes:data length:4*sizeof(int32_t)]];
    
    lastRunNumberShipped	= data[2];
	
    [self sendHeartBeat:nil];
//	[NSThread setThreadPriority:1];
	
	[self setRunPaused:NO];
}


//takeData runs in the data Taking thread. It should not be called from anywhere else.
//and it should not call anything that is not thread safe.
- (void) takeData
{
	NSAutoreleasePool *outerpool = [[NSAutoreleasePool allocWithZone:nil] init];
	NSLog(@"DataTaking Thread Started\n");
	[NSThread setThreadPriority:.8];

	dataTakingThreadRunning = YES;
    [self performSelectorOnMainThread:@selector(clearExceptionCount) withObject:nil waitUntilDone:YES];

    while(!timeToStopTakingData) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:nil] init];
        @try {
			if(!runPaused){
				[client takeData:dataPacket userInfo:nil];
			}
			else {
				[NSThread sleepUntilDate:[[NSDate date] dateByAddingTimeInterval:.05]];
			}
		}
		@catch(NSException* localException) {
            NSLogError(@"Uncaught exception",@"Main Run Loop",nil);
            [self performSelectorOnMainThread:@selector(incExceptionCount) withObject:nil waitUntilDone:YES];
            [self performSelectorOnMainThread:@selector(haltRun) withObject:nil waitUntilDone:NO];
        }
        [pool release];
    }
    [runInfo setObject:[NSNumber numberWithBool:!quickStart] forKey:@"doinit"];
    @try {
        [client runIsStopping:runInfo];
    }
    @catch(NSException* e){
        NSLog(@"RunControl: runIsStopping Method: %@\n", e);
    }
	@try {
		BOOL allDone = NO;
		if(client) do {
			NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:nil] init];
			[client takeData:dataPacket userInfo:nil];
			allDone = [client doneTakingData];
			[pool release];
		}while(!allDone);
	}
	@catch(NSException* localException) {
        [self performSelectorOnMainThread:@selector(incExceptionCount) withObject:nil waitUntilDone:YES];
		NSLogError(@"Uncaught exception",@"Run Loop Cleanup",nil);
	}
	
	NSLog(@"DataTaking Thread Exited\n");
	dataTakingThreadRunning = NO;
	[outerpool release];
	
	[readoutThread release];
	readoutThread = nil;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[notifyCenter removeObserver:self];
   
    [notifyCenter addObserver: self
                     selector: @selector(runModeChanged:)
                         name: ORRunModeChangedNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(vmePowerFailed:)
                         name: @"VmePowerFailedNotification"
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(gotForceRunStopNotification:)
                         name: @"forceRunStopNotification"
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(gotRequestedRunHaltNotification:)
                         name: ORRequestRunHalt
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(gotRequestedRunStopNotification:)
                         name: ORRequestRunStop
                       object: nil];
	
    [notifyCenter addObserver: self
                     selector: @selector(gotRequestedRunRestartNotification:)
                         name: ORRequestRunRestart
                       object: nil];
	
    [notifyCenter addObserver: self
                     selector: @selector(vetosChanged:)
                         name: ORRunVetosChanged
                       object: nil];    
	
	[notifyCenter addObserver:self 
					 selector:@selector(needMoreTimeToStopRun:) 
						 name:ORNeedMoreTimeToStopRun 
					   object:nil];
    
    [notifyCenter addObserver:self 
					 selector:@selector(addRunStateChangeWait:) 
						 name:ORAddRunStateChangeWait 
					   object:nil];

    [notifyCenter addObserver:self
					 selector:@selector(addRunStartupAbort:)
						 name:ORAddRunStartupAbort
					   object:nil];

    [notifyCenter addObserver:self 
					 selector:@selector(releaseRunStateChangeWait:) 
						 name:ORReleaseRunStateChangeWait 
					   object:nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(productionModeChanged:)
                         name : ORInProductionModeChanged
                       object : nil];
}

- (void) productionModeChanged:(NSNotification*)aNote
{
    if(![[ORGlobal sharedGlobal]inProductionMode]){
        [self clearProductionAlarm];
    }
}

- (void) addRunStartupAbort:(NSNotification*)aNote
{
    @synchronized (self){
        if(!objectsRequestingRunStartAbort)objectsRequestingRunStartAbort = [[NSMutableArray array]retain];
        id obj = [aNote object];
        NSString* requester;
        if([obj respondsToSelector:@selector(fullID)]) requester = [obj fullID];
        else requester = [obj className];
        if(requester){
            NSString* reason = [[aNote userInfo] objectForKey:@"Reason"];
            if([reason length]==0)reason = @"No Reason Given";
            NSString* details = [[aNote userInfo] objectForKey:@"Details"];
            if([details length]==0)details = @"No Details Given";
            [objectsRequestingRunStartAbort addObject:[NSDictionary dictionaryWithObjectsAndKeys:requester,@"Requester",reason,@"Reason",details,@"Details", nil]];
        }
    }
}

- (void) addRunStateChangeWait:(NSNotification*)aNote
{
	@synchronized (self){
        if(!objectsRequestingStateChangeWait)objectsRequestingStateChangeWait = [[NSMutableArray array]retain];
        id obj = [aNote object];
        NSString* requester;
        if([obj respondsToSelector:@selector(fullID)]) requester = [obj fullID];
        else requester = [obj className];
        if(requester){
            NSString* reason = [[aNote userInfo] objectForKey:@"Reason"];
            if([reason length]==0)reason = @"No Reason Given";
            [objectsRequestingStateChangeWait addObject:[NSDictionary dictionaryWithObjectsAndKeys:requester,@"Requester",reason,@"Reason", nil]];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRunModelNumberOfWaitsChanged object:self];

}

- (void) releaseRunStateChangeWait:(NSNotification*)aNote
{
 	@synchronized (self){
        id obj = [aNote object];
        NSString* requester;
        if([obj respondsToSelector:@selector(fullID)]) requester = [obj fullID];
        else requester = [obj className];
        int i=0;
        for(id anEntry in objectsRequestingStateChangeWait){
            if([[anEntry objectForKey:@"Requester"] isEqualToString:requester]){
                [objectsRequestingStateChangeWait removeObjectAtIndex:i]; //can't use the name here because one obj may have multiple entries
                break;
            }
            i++;
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRunModelNumberOfWaitsChanged object:self];

}

- (void) forceClearWaits
{
	@synchronized (self){
        [objectsRequestingStateChangeWait removeAllObjects];
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRunModelNumberOfWaitsChanged object:self];

}

- (void) abortRunFromWait
{
    [self forceClearWaits];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORRequestRunHalt object:self];
}

- (NSUInteger) waitRequestersCount
{
    NSUInteger count;
	@synchronized (self){
        count = [objectsRequestingStateChangeWait count];
    }
    return count;
}

- (id) waitRequesterAtIdex:(NSUInteger)index
{
    id result = nil;
	@synchronized (self){
        if(index<[self waitRequestersCount]){
            result = [objectsRequestingStateChangeWait objectAtIndex:index];
        }
    }
    return result;
}

- (void) vetosChanged:(NSNotification*)aNotification
{
	if([self runningState] != eRunStarting){
		[self performSelectorOnMainThread:@selector(checkVetos) withObject:nil waitUntilDone:NO];
	}
}

- (void) checkVetos
{
	[self setUpImage];
	if([[ORGlobal sharedGlobal] anyVetosInPlace] && [self isRunning]){
		NSLogColor([NSColor redColor],@"====================================\n");
		NSLogColor([NSColor redColor],@"Run is being stopped by veto system.\n");
		[[ORGlobal sharedGlobal] listVetoReasons];
		NSLogColor([NSColor redColor],@"====================================\n");
		[self haltRun];
		if(!runStoppedByVetoAlarm){
			runStoppedByVetoAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Run %u Halted by Veto",[self runNumber]] severity:kRunInhibitorAlarm];
			[runStoppedByVetoAlarm setSticky:NO];
			[runStoppedByVetoAlarm setHelpString:@"Run stopped by Veto system. See status log for details."];
		}
		[runStoppedByVetoAlarm setAcknowledged:NO];
		[runStoppedByVetoAlarm postAlarm];
	}
}


- (void) vmePowerFailed:(NSNotification*)aNotification
{
	if(!forceFullInit){
		NSLog(@"Run Control: Full init will be forced on next run because of Vme power failure.\n");
		if([self isRunning])[self performSelectorOnMainThread:@selector(haltRun) withObject:nil waitUntilDone:NO];
        
	}
	forceFullInit = YES;
}
- (void) gotRequestedRunHaltNotification:(NSNotification*)aNotification
{
	[self performSelectorOnMainThread:@selector(requestedRunHalt:) withObject:[aNotification userInfo] waitUntilDone:NO];
}

- (void) gotForceRunStopNotification:(NSNotification*)aNotification
{
	[self performSelectorOnMainThread:@selector(forceHalt) withObject:nil waitUntilDone:NO];
}

- (void) gotRequestedRunRestartNotification:(NSNotification*)aNotification
{
	[self performSelectorOnMainThread:@selector(requestedRunRestart:) withObject:[aNotification userInfo] waitUntilDone:NO];
}

- (void) gotRequestedRunStopNotification:(NSNotification*)aNotification
{
	[self performSelectorOnMainThread:@selector(requestedRunStop:) withObject:[aNotification userInfo] waitUntilDone:NO];
}

- (void) requestedRunHalt:(NSDictionary*)userInfo
{
	if(userInfo)NSLog(@"Got halt run request:     %@\n",userInfo);
	else NSLog(@"Got halt run request (No reason given)\n");
	[self haltRun];
}

- (void) requestedRunStop:(NSDictionary*)userInfo
{
	if(userInfo)NSLog(@"Got stop run request:     %@\n",userInfo);
	else NSLog(@"Got stop run request (No reason given)\n");
	[self stopRun];
}

- (void) requestedRunRestart:(NSDictionary*)userInfo
{
	if(userInfo)NSLog(@"Got restart run request:     %@\n",userInfo);
	else NSLog(@"Got restart run request (No reason given)\n");
	[self setForceRestart:YES];
    [self performSelector:@selector(stopRun)withObject:nil afterDelay:0];

}

- (void) forceHalt
{
	if([self isRunning]){
		[self haltRun];
		if(!runFailedAlarm){
			runFailedAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Run %u did NOT start",[self runNumber]] severity:kRunInhibitorAlarm];
			[runFailedAlarm setSticky:YES];
            [runFailedAlarm setHelpStringFromFile:@"RunFailedHelp"];
            
		}
		if(![runFailedAlarm isPosted]){
			[runFailedAlarm setAcknowledged:NO];
			[runFailedAlarm postAlarm];
		}
	}
}

- (void) runModeChanged:(NSNotification*)aNotification
{
    [self setUpImage];
}

- (NSDictionary*) fullRunInfo
{
    NSArray* rtNames = [self runTypeNames];
    if([rtNames count]==0){
        rtNames = [NSArray array];
    }
	return [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithUnsignedLong:[self runNumber]],		@"run",
							 [NSNumber numberWithUnsignedLong:[self subRunNumber]],		@"subrun",
							 [NSNumber numberWithUnsignedLong:[self runningState]],		@"state",
							 [NSNumber numberWithUnsignedLong:[self elapsedRunTime]],	@"elapsedTime",
							 [NSNumber numberWithUnsignedLong:[self elapsedSubRunTime]],@"elapsedSubRunTime",
							 [NSNumber numberWithUnsignedLong:[self elapsedBetweenSubRunTime]],@"elapsedBetweenSubRunTime",
							 [NSNumber numberWithUnsignedLong:(uint32_t)[self timeToGo]],			@"timeToGo",
							 [NSNumber numberWithBool:[self quickStart]],				@"quickStart",
							 [NSNumber numberWithBool:[self repeatRun]],				@"repeatRun",
							 [NSNumber numberWithBool:[self offlineRun]],				@"offlineRun",
							 [NSNumber numberWithBool:[self timedRun]],					@"timedRun",
							 [NSNumber numberWithUnsignedLong:[self timeLimit]],		@"timeLimit",
                             [NSNumber numberWithUnsignedLong:[self runType]],          @"runType",
                             rtNames,                                                   @"runTypeNames",
                             [[self startTime] stdDescription],                         @"startTime",
                             [[self subRunStartTime] stdDescription],                   @"subRunStartTime",

							 nil];
}

#pragma mark ¥¥¥Archival
static NSString *ORRunTimeLimit		= @"Run Time Limit";
static NSString *ORRunTimedRun		= @"Run Is Timed";
static NSString *ORRunRepeatRun		= @"Run Will Repeat";
static NSString *ORRunNumberDir		= @"Run Number Dir";
static NSString *ORRunType_Mask		= @"ORRunTypeMask";
static NSString *ORRunRemoteControl = @"ORRunRemoteControl";
static NSString *ORRunQuickStart 	= @"ORRunQuickStart";
static NSString *ORRunDefinitions 	= @"ORRunDefinitions";
static NSString *ORRunTypeNames 	= @"ORRunTypeNames";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setSelectedRunTypeScript:[decoder decodeIntegerForKey:@"selectedRunTypeScript"]];
    [self setShutDownScript:[decoder decodeObjectForKey:@"shutDownScript"]];
    [self setStartScript:[decoder decodeObjectForKey:@"startScript"]];
    [self setTimeLimit:[decoder decodeIntegerForKey:ORRunTimeLimit]];
    [self setRunType:[decoder decodeIntForKey:ORRunType_Mask]];
    [self setTimedRun:[decoder decodeBoolForKey:ORRunTimedRun]];
    [self setRepeatRun:[decoder decodeBoolForKey:ORRunRepeatRun]];
    [self setQuickStart:[decoder decodeBoolForKey:ORRunQuickStart]];
    [self setDirName:[decoder decodeObjectForKey:ORRunNumberDir]];
    [self setRemoteControl:[decoder decodeBoolForKey:ORRunRemoteControl]];
    [self setRunTypeNames:[decoder decodeObjectForKey:ORRunTypeNames]];
    [self setDefinitionsFilePath:[decoder decodeObjectForKey:ORRunDefinitions]];
    [self setRemoteInterface:[decoder decodeBoolForKey:@"RemoteInterface"]];
    [[self undoManager] enableUndoRegistration];
    
    _ignoreMode = NO;
    [self registerNotificationObservers];
    
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:(int32_t)selectedRunTypeScript forKey:@"selectedRunTypeScript"];
    [encoder encodeObject:shutDownScript forKey:@"shutDownScript"];
    [encoder encodeObject:startScript forKey:@"startScript"];
    [encoder encodeInteger:[self timeLimit] forKey:ORRunTimeLimit];
    [encoder encodeInt:[self runType] forKey:ORRunType_Mask];
    [encoder encodeBool:[self timedRun] forKey:ORRunTimedRun];
    [encoder encodeBool:[self repeatRun] forKey:ORRunRepeatRun];
    [encoder encodeBool:[self quickStart] forKey:ORRunQuickStart];
    [encoder encodeObject:[self dirName] forKey:ORRunNumberDir];
    [encoder encodeBool:[self remoteControl] forKey:ORRunRemoteControl];
    [encoder encodeObject:[self runTypeNames] forKey:ORRunTypeNames];
    [encoder encodeObject:[self definitionsFilePath] forKey:ORRunDefinitions];
    [encoder encodeBool:remoteInterface forKey:@"RemoteInterface"];
}

- (NSString*)commandID
{
    return @"RunControl";
}

- (BOOL) solitaryObject
{
    return YES;
}

- (BOOL) readRunTypeNames
{
    if(definitionsFilePath){
        NSMutableArray* names = [NSMutableArray array];
        int i;
        [names addObject:[NSString stringWithFormat:@"Maintenance"]];
        [names addObject:[NSString stringWithFormat:@"Enable SubRuns"]];
        for(i=1;i<32;i++){
            [names addObject:[NSString stringWithFormat:@"Bit %d",i]];
        }
        
        NSString* contents = [NSString stringWithContentsOfFile:definitionsFilePath encoding:NSASCIIStringEncoding error:nil];
        NSArray* items;
		contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
		contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
        items = [contents componentsSeparatedByString:@"\n"];
		
        NSEnumerator* e = [items objectEnumerator];
        NSString* aLine;
        while(aLine = [e nextObject]){
			aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
			aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([aLine length] == 0)continue;
            NSArray* parts = [aLine componentsSeparatedByString:@","];
            if([parts count] == 2){
                int index = [[parts objectAtIndex:0] intValue];
                if(index>0 && index<32){
                    //note that bit 0 is predefined and is ignored if defined in the file.
                    [names replaceObjectAtIndex:index withObject:[parts objectAtIndex:1]];
                }
            }
            else {
                return NO;
            }
        }
        [self setRunTypeNames:names];
        return YES;
    }
    return YES;
}

- (NSString*) shortStatus
{
	if(runningState == eRunInProgress){
		if(!runPaused)return @"Running";
		else return @"Paused";
	}
	else if(runningState == eRunStopped){
		return @"Stopped";
	}
	else if(runningState == eRunStarting || runningState == eRunStopping){
		if(runningState == eRunStarting)return @"Starting..";
		else return @"Stopping..";
	}
	else return @"?";
}

#pragma mark ¥¥¥Remote Run Control Helpers
- (NSArray*) runScriptList
{
	NSArray* theScripts = [[self document] collectObjectsOfClass:[ORRunScriptModel class]];
	ORRunScriptModel* aScript;
	NSMutableArray* theNameList = [NSMutableArray array];
	NSEnumerator* e = [theScripts objectEnumerator];
	while(aScript = [e nextObject]){
		[theNameList addObject: [aScript identifier]];
	}
	return theNameList;
}

- (NSString*) selectedStartScriptName
{
	if(!startScript) return @"---";
	else return [startScript identifier];
}

- (NSString*) selectedShutDownScriptName
{
	if(!shutDownScript) return @"---";
	else return [shutDownScript identifier];
}

- (void) setStartScriptName:(NSString*)aName
{
	[[self undoManager] disableUndoRegistration];
	
	if([aName isEqualToString:@"---"])[self setStartScript:nil];
	else {
		NSArray* theScripts = [[self document] collectObjectsOfClass:[ORRunScriptModel class]];
		ORRunScriptModel* aScript;
		NSEnumerator* e = [theScripts objectEnumerator];
		BOOL foundIt = NO;
		while(aScript = [e nextObject]){
			if([aName isEqualToString:[aScript identifier]]){
				[self setStartScript:aScript];
				NSLog(@"startup: %@\n",[aScript identifier]);
				foundIt	 = YES;
				break;
			}
		}
		if(!foundIt)[self setStartScript:nil];
	}
	[[self undoManager] enableUndoRegistration];
	
}

- (void) setShutDownScriptName:(NSString*)aName
{
	[[self undoManager] disableUndoRegistration];
	if([aName isEqualToString:@"---"])[self setShutDownScript:nil];
	else {
		NSArray* theScripts = [[self document] collectObjectsOfClass:[ORRunScriptModel class]];
		ORRunScriptModel* aScript;
		NSEnumerator* e = [theScripts objectEnumerator];
		BOOL foundIt = NO;
		while(aScript = [e nextObject]){
			if([aName isEqualToString:[aScript identifier]]){
				[self setShutDownScript:aScript];
				NSLog(@"shutDown: %@\n",[aScript identifier]);
				foundIt	 = YES;
				break;
			}
		}
		if(!foundIt)[self setShutDownScript:nil];
	}
	[[self undoManager] enableUndoRegistration];
}

- (NSString*) commonScriptMethods
{
	NSArray* selectorArray = [NSArray arrayWithObjects:
		@"isRunning",
        @"startNoScriptRun",
        @"startRun",
		@"restartRun",
		@"stopRun",
		@"prepareForNewSubRun",
		@"startNewSubRun",
		@"timedRun",
		@"repeatRun",
		@"runNumber",
		@"runType",
		@"timeLimit",
		@"setRepeatRun:(BOOL)",
		@"setTimedRun:(BOOL)",
		@"setRunType:(uint32_t)",
		@"setTimeLimit:(NSTimeInterval)",
		nil];
	
	return [selectorArray componentsJoinedByString:@"\n"];
}

#pragma mark ¥¥¥Bit Processing Protocol
- (void)processIsStarting
{
	//nothing to do in this case
}

- (void)processIsStopping
{
	//nothing to do in this case
}

- (void) startProcessCycle
{
	//nothing to do in this case
}

- (void) endProcessCycle
{
	//nothing to do in this case
}

- (BOOL) processValue:(int)channel
{
	int state = [self runningState];
	switch(channel){
		case 0: return state == eRunStopped;
		case 1: return state == eRunInProgress;
		case 2: return state == eRunStarting;
		case 3: return state == eRunStopping;
		case 4: return state == eRunBetweenSubRuns;
		default: return NO;
	}
}

- (void) setProcessOutput:(int)channel value:(int)value
{
	//nothing to do in this case
}

- (NSString*) processingTitle
{
    return @"RunControl";
}
#pragma mark ¥¥¥CardHolding Protocol
- (int) maxNumberOfObjects	{ return 32; }
- (int) objWidth			{ return 25; }	//default
- (int) groupSeparation		{ return 0; }	//default
- (NSString*) nameForSlot:(int)aSlot
{
    return [NSString stringWithFormat:@"Script %d",aSlot];
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj { return NO;}

- (NSRange) legalSlotsForObj:(id)anObj
{
	return NSMakeRange(0,[self maxNumberOfObjects]);
}

- (int) slotAtPoint:(NSPoint)aPoint
{
    float totalHeight = [self objWidth]*([self maxNumberOfObjects]-1);
	return floor(((int)(totalHeight-aPoint.y))/[self objWidth]);
}

- (NSPoint) pointForSlot:(int)aSlot
{
    float totalHeight = [self objWidth]*([self maxNumberOfObjects]-1);
	return NSMakePoint(0,totalHeight - aSlot*[self objWidth]);
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
	[anObj setSlot: aSlot];
	[anObj moveTo:[self pointForSlot:aSlot]];
}

- (int) slotForObj:(id)anObj
{
	return (int)[anObj tag];
}

- (int) numberSlotsNeededFor:(id)anObj
{
	return 1;
}

- (void) openDialogForComponent:(int)i
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj tag] == i){
			[anObj makeMainController];
			break;
		}
	}
}

- (void) drawSlotLabels
{
    float totalHeight = [self objWidth]*([self maxNumberOfObjects]-1);
    int i;
    for(i=0;i<[self maxNumberOfObjects];i++){
        NSString* s = [NSString stringWithFormat:@"%d",i];
        NSAttributedString* slotLabel = [[NSAttributedString alloc]
                                         initWithString: s
                                         attributes  : [NSDictionary dictionaryWithObjectsAndKeys:
                                                        [NSFont messageFontOfSize:8],NSFontAttributeName,
                                                        [NSColor blackColor],NSForegroundColorAttributeName,nil]];
        
        NSSize textSize = [slotLabel size];
        
		float y = totalHeight-(i*[self objWidth])+[self objWidth]/2. - textSize.height/2;
        
        [slotLabel drawInRect:NSMakeRect(2,y,textSize.width,textSize.height)];
        [slotLabel release];
        
    }
}

- (void) drawSlotBoundaries
{
    float totalHeight = [self objWidth]*([self maxNumberOfObjects]-1);
    [[NSColor lightGrayColor]set];
    int i;
    for(i=0;i<[self maxNumberOfObjects];i++){
		float y = totalHeight-(i*[self objWidth])+[self objWidth];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0,y) toPoint:NSMakePoint(150,y)];
    }
}
- (BOOL) reverseDirection
{
    return YES;
}
@end


@implementation ORRunDecoderForRun
- (uint32_t)decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t* p = (uint32_t*)someData;
	uint32_t length =  ExtractLength(p[0]); //must return number of longs processed.
    if(p[1] & 0x8){ //heart beat
        [aDataSet loadGenericData:@" " sender:self withKeys:@"Run Control",@"Heartbeat",nil];
	}
	else {
		if(p[1] & 0x1){ //end subrun
			[aDataSet loadGenericData:@" " sender:self withKeys:@"Run Control",@"Start",nil];
		}
		else if(p[1] & 0x20){ //start subrun
			[aDataSet loadGenericData:@" " sender:self withKeys:@"Run Control",@"Subrun Start",nil];
		}
		else if(p[1] & 0x10){ //end subrun
			[aDataSet loadGenericData:@" " sender:self withKeys:@"Run Control",@"Subrun End",nil];
		}
		else { //end run
			[aDataSet loadGenericData:@" " sender:self withKeys:@"Run Control",@"End",nil];
		}
	}
	
	return length;
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* runState;
    NSString* thirdWordKey;
	uint32_t subRunNumber = 0;
    NSString* init = @"";
    NSString* title= @"Run Control Record\n\n";
	BOOL showSubRun = NO;
    if(dataPtr[1] & 0x8){
        runState     = @"Type       = HeartBeat\n";
        thirdWordKey = @"Next Beat  = ";
    }
    else {
		
        thirdWordKey = @"Run Number = ";
       
        if(dataPtr[1] & 0x1){
            runState = @"Type       = Start Run\n";
            init = [NSString stringWithFormat:@"Full Init  = %@\n",(dataPtr[1]&0x2)?@"YES":@"NO"];
        }
		
        else if(dataPtr[1] & 0x10){
			runState = @"Type       = End SubRun\n";
			showSubRun = YES;
		}
        else if(dataPtr[1] & 0x20){
			runState = @"Type       = Start SubRun\n";
			showSubRun = YES;
		}
        else runState = @"Type       = End Run\n";
	}
	
	subRunNumber = dataPtr[1]>>16;

    NSString* remote     = [NSString stringWithFormat:@"Remote     = %@\n",(dataPtr[1] & 0x4)?@"YES":@"NO"];
    NSString* thirdWord  = [NSString stringWithFormat:@"%@%u",thirdWordKey,dataPtr[2]];
	if(showSubRun){
		thirdWord = [thirdWord stringByAppendingFormat:@".%d",subRunNumber];
	}
	thirdWord = [thirdWord stringByAppendingString:@"\n"];

    NSString* s;
    if(dataPtr[1] & 0x1) s= [NSString stringWithFormat:@"%@%s%@%@%@%@",title,ctime((const time_t *)(&dataPtr[3])),runState,init,remote,thirdWord]; 
    else                 s= [NSString stringWithFormat:@"%@%s%@%@%@",title,ctime((const time_t *)(&dataPtr[3])),runState,remote,thirdWord];               
	return s;
}

@end

@implementation NSObject (SpecialDataTakingFinishUp)
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	//classes can override as needed
}

- (BOOL) doneTakingData
{
	//classes can override as needed. Most classes don't need to override -- the special cases
	//would be, for example, those taking data from a circular buffer and need to empty it 
	//before declaring that they 
	return YES;
}

- (BOOL) preRunChecks
{
	return YES;
}

@end
