//
//  ORKatrinV4SLTModel.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the progrkKatrinV4SLTam should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORGlobal.h"
#import "ORCrate.h"
#import "ORKatrinV4SLTModel.h"
#import "ORIpeV4CrateModel.h"
#import "ORKatrinV4SLTDefs.h"
#import "ORKatrinV4FLTModel.h"
#import "ORReadOutList.h"
#import "unistd.h"
#import "TimedWorker.h"
#import "ORDataTypeAssigner.h"
#import "PMC_Link.h"
#import "KatrinV4_HW_Definitions.h"
#import "ORPMCReadWriteCommand.h"
#import "SLTv4GeneralOperations.h"
#import "ORTaskSequence.h"
#import "ORFileMover.h"
#import "ORAlarm.h"

#import "ORRunModel.h"
#import <objc/runtime.h>


#pragma mark ***Notification Strings
NSString* ORKatrinV4SLTModelPixelBusEnableRegChanged        = @"ORKatrinV4SLTModelPixelBusEnableRegChanged";
NSString* ORKatrinV4SLTModelSecondsSetSendToFLTsChanged     = @"ORKatrinV4SLTModelSecondsSetSendToFLTsChanged";
NSString* ORKatrinV4SLTModelSecondsSetInitWithHostChanged   = @"ORKatrinV4SLTModelSecondsSetInitWithHostChanged";
NSString* ORKatrinV4SLTModelSltScriptArgumentsChanged       = @"ORKatrinV4SLTModelSltScriptArgumentsChanged";
NSString* ORKatrinV4SLTModelCountersEnabledChanged          = @"ORKatrinV4SLTModelCorntersEnabledChanged";
NSString* ORKatrinV4SLTModelClockTimeChanged                = @"ORKatrinV4SLTModelClockTimeChanged";
NSString* ORKatrinV4SLTModelRunTimeChanged                  = @"ORKatrinV4SLTModelRunTimeChanged";
NSString* ORKatrinV4SLTModelVetoTimeChanged                 = @"ORKatrinV4SLTModelVetoTimeChanged";
NSString* ORKatrinV4SLTModelDeadTimeChanged                 = @"ORKatrinV4SLTModelDeadTimeChanged";
NSString* ORKatrinV4SLTModelLostEventsChanged               = @"ORKatrinV4SLTModelLostEventsChanged";
NSString* ORKatrinV4SLTModelLostFltEventsChanged            = @"ORKatrinV4SLTModelLostFltEventsChanged";
NSString* ORKatrinV4SLTModelLostFltEventsTrChanged            = @"ORKatrinV4SLTModelLostFltEventsTrChanged";
NSString* ORKatrinV4SLTModelSecondsSetChanged               = @"ORKatrinV4SLTModelSecondsSetChanged";
NSString* ORKatrinV4SLTModelStatusRegChanged                = @"ORKatrinV4SLTModelStatusRegChanged";
NSString* ORKatrinV4SLTModelControlRegChanged               = @"ORKatrinV4SLTModelControlRegChanged";
NSString* ORKatrinV4SLTModelFanErrorChanged                 = @"ORKatrinV4SLTModelFanErrorChanged";
NSString* ORKatrinV4SLTModelVttErrorChanged                 = @"ORKatrinV4SLTModelVttErrorChanged";
NSString* ORKatrinV4SLTModelGpsErrorChanged                 = @"ORKatrinV4SLTModelGpsErrorChanged";
NSString* ORKatrinV4SLTModelClockErrorChanged               = @"ORKatrinV4SLTModelClockErrorChanged";
NSString* ORKatrinV4SLTModelPpsErrorChanged                 = @"ORKatrinV4SLTModelPpsErrorChanged";
NSString* ORKatrinV4SLTModelPixelBusErrorChanged            = @"ORKatrinV4SLTModelPixelBusErrorChanged";
NSString* ORKatrinV4SLTModelHwVersionChanged                = @"ORKatrinV4SLTModelHwVersionChanged";

NSString* ORKatrinV4SLTModelPatternFilePathChanged          = @"ORKatrinV4SLTModelPatternFilePathChanged";
NSString* ORKatrinV4SLTModelInterruptMaskChanged            = @"ORKatrinV4SLTModelInterruptMaskChanged";
NSString* ORKatrinV4SLTPulserDelayChanged                   = @"ORKatrinV4SLTPulserDelayChanged";
NSString* ORKatrinV4SLTPulserAmpChanged                     = @"ORKatrinV4SLTPulserAmpChanged";
NSString* ORKatrinV4SLTSettingsLock                         = @"ORKatrinV4SLTSettingsLock";
NSString* ORKatrinV4SLTStatusRegChanged                     = @"ORKatrinV4SLTStatusRegChanged";
NSString* ORKatrinV4SLTControlRegChanged                    = @"ORKatrinV4SLTControlRegChanged";
NSString* ORKatrinV4SLTSelectedRegIndexChanged              = @"ORKatrinV4SLTSelectedRegIndexChanged";
NSString* ORKatrinV4SLTWriteValueChanged                    = @"ORKatrinV4SLTWriteValueChanged";
NSString* ORKatrinV4SLTPollTimeChanged                      = @"ORKatrinV4SLTPollTimeChanged";
NSString* ORKatrinV4SLTModelMinimizeDecodingChanged         = @"ORKatrinV4SLTModelMinimizeDecodingChanged";

NSString* ORKatrinV4SLTcpuLock                              = @"ORKatrinV4SLTcpuLock";

@interface ORKatrinV4SLTModel (private)
- (uint32_t) read:(uint32_t) address;
- (void) write:(uint32_t) address value:(uint32_t) aValue;
@end

@implementation ORKatrinV4SLTModel

- (id) init
{
    self = [super init];
	ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];	
	[self setReadOutGroup:readList];
	[readList release];
	pmcLink = [[PMC_Link alloc] initWithDelegate:self];
	[self setSecondsSetInitWithHost: YES];
	[self setSecondsSetSendToFLTs: YES];
    [self setDefaults];
	[self registerNotificationObservers];
    
    runStartSec = 0;
    sltSecondRunStop = 0;

    return self;
}

-(void) dealloc
{
    [sltScriptArguments release];
    [patternFilePath release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[readOutGroup release];
	[pmcLink setDelegate:nil];
	[pmcLink release];
    [swInhibitDisabledAlarm clearAlarm];
    [swInhibitDisabledAlarm release];
    [pixelTriggerDisabledAlarm clearAlarm];
    [pixelTriggerDisabledAlarm release];
    [noPPSAlarm clearAlarm];
    [noPPSAlarm release];
    [badPPSStatusAlarm clearAlarm];
    [badPPSStatusAlarm release];

    
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
	[pmcLink wakeUp];
    [super wakeUp];
    if(pollTime){
        [self performSelector:@selector(readAllStatus) withObject:nil afterDelay:2];
    }
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[pmcLink sleep];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		if(!pmcLink){
			pmcLink = [[PMC_Link alloc] initWithDelegate:self];
		}
		[pmcLink connect];
	}
	@catch(NSException* localException) {
	}
}

- (void) setUpImage			{ [self setImage:[NSImage imageNamed:@"KatrinV4SLTCard"]];  }
- (void) makeMainController	{ [self linkToController:@"ORKatrinV4SLTController"];		}
- (Class) guardianClass		{ return NSClassFromString(@"ORIpeV4CrateModel");           }

- (void) setGuardian:(id)aGuardian //-tb-
{
	if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self]; //TODO: aGuardian is usually a ORCrate; if inserting the SLT AFTER the FLTs, need to update "useSLTtime" flag NOW  -tb-			
		}
	}
	else {
		[[self guardian] setAdapter:nil];
	}
	[super setGuardian:aGuardian];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver:self];
	
    [notifyCenter addObserver : self
                     selector : @selector(runIsBetweenSubRuns:)
                         name : ORRunBetweenSubRunsNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runIsStartingSubRun:)
                         name : ORRunStartSubRunNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(cardsChanged:)
                         name : ORGroupObjectsRemoved
                       object : [self guardian]];
    
    [notifyCenter addObserver : self
                     selector : @selector(cardsChanged:)
                         name : ORGroupObjectsAdded
                       object : [self guardian]];
    
    [notifyCenter addObserver : self
                     selector : @selector(runIsAboutToChangeState:)
                         name : ORRunAboutToChangeState
                       object : nil];
}

- (void) cardsChanged:(NSNotification*) aNote
{
    if([aNote object] == [self guardian]){
        NSArray* allCards = [[self guardian] children];
        uint32_t aMask = 0x0;
        for(id aCard in allCards){
            if(![[aCard className] isEqualToString:[self className]]){
                // Energy mode requires pixel bus
                if ([aCard runMode] == kKatrinV4Flt_EnergyDaqMode){
                    int n = (int)[aCard stationNumber]-1;
                    aMask |= (0x1<<n);
                }
            }
        }
        [[self undoManager] disableUndoRegistration];
        //
        // Warning: This overwrites the settings saved in the configuration
        //      The advantage is, that standard configuration is active at startup
        //
 //       [self setPixelBusEnableReg:aMask];
        [[self undoManager] enableUndoRegistration];
    }
}

- (void) setDefaults
{
    //SW Inhibit enabled
    //Run enabled
    uint32_t defaultMask = (1L<<kCtrlInhEnShift) | kCtrlRunMask;
    [self setControlReg:defaultMask];
}


- (void) runIsAboutToChangeState:(NSNotification*)aNote
{
    uint32_t subseconds;
    uint32_t seconds;
    uint32_t subsec2;
    //uint32_t status;

    int state = [[[aNote userInfo] objectForKey:@"State"] intValue];
    BOOL isSubRun = [[[aNote userInfo] objectForKey:@"StartingSubRun"] boolValue];

    id rc =  [aNote object];
    NSLog(@"%@::%@ Calling object %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),NSStringFromClass([rc class]));
    switch (state) {
        case eRunStarting:
            if (isSubRun){
                NSLog(@"--- Notification: go to  %@\n",@"eSubRunStarting");
            
                // Define the start of the subrun here; there is no inhibit used
                // during subruns, but still phases change only at the second strobe
                subseconds = [self readSubSecondsCounter];
                seconds = [self readSecondsCounter];
                subsec2 = (subseconds >> 11) & 0x3fff;
                NSLog(@"SLT %i.%03i - waiting for second strobe %i\n", seconds, subsec2/10, seconds+1);
                
                secondToWaitFor = seconds + 1;
                waitForSubRunStart = true;

                // Tell run control to wait
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                          @"waiting for second strobe",
                                          @"Reason",
                                          nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object: self userInfo: userInfo];
                
                // Ship announcement of subrun as early as possible;
                // at high rates it's impossible to put them at the right place?!
                [self shipSecondCounter: kStartSubRunType sec:secondToWaitFor];
                
            } else {
                NSLog(@"--- Notification: go to  %@\n",@"eRunStarting");
            }
            break;
            
        case eRunBetweenSubRuns:
            NSLog(@"--- Notification: go to  %@\n",@"eRunBetweenSubRuns");
            
            // Define the end of the subrun here; there is no inhibit used
            // during subruns, but still phases change only at the second strobe
            subseconds = [self readSubSecondsCounter];
            seconds = [self readSecondsCounter];
            subsec2 = (subseconds >> 11) & 0x3fff;
            NSLog(@"SLT %i.%03i - waiting for second strobe %i\n", seconds, subsec2/10, seconds+1);
            
            secondToWaitFor = seconds + 1;
            waitForSubRunEnd = true;
            
            // Tell run control to wait
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"waiting for second strobe",
                                      @"Reason",
                                      nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object: self userInfo: userInfo];

            // Ship end of subrun announcement as early as possible;
            // at high rates it's impossible to put them at the right place?!
            [self shipSecondCounter: kStopSubRunType sec:secondToWaitFor];

            break;
            
        case eRunStopping:
            NSLog(@"--- Notification: go to  %@\n",@"eRunStopping");
            break;
            
        default:
            break;
    }
    
}


#pragma mark •••Accessors
- (BOOL) minimizeDecoding
{
    return minimizeDecoding;
}
- (void) setMinimizeDecoding:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMinimizeDecoding:minimizeDecoding];
    minimizeDecoding = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelMinimizeDecodingChanged object:self];
}
- (uint32_t) pixelBusEnableReg
{
    return pixelBusEnableReg;
}

- (void) setPixelBusEnableReg:(uint32_t)aPixelBusEnableReg
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPixelBusEnableReg:pixelBusEnableReg];
    pixelBusEnableReg = aPixelBusEnableReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelPixelBusEnableRegChanged object:self];
    [self checkPixelTrigger];

}

- (void) enablePixelBus:(int)aStationNumber
{
    uint32_t pixelBus = [self pixelBusEnableReg];
    pixelBus = pixelBus | (0x1 << (aStationNumber -1));
    [self setPixelBusEnableReg: pixelBus];
}

- (void) disablePixelBus:(int)aStationNumber
{
    uint32_t pixelBus = [self pixelBusEnableReg];
    pixelBus = pixelBus & ( 0xfffff ^ (0x1 << (aStationNumber -1)));
    [self setPixelBusEnableReg: pixelBus];
}

- (bool) secondsSetSendToFLTs
{
    return secondsSetSendToFLTs;
}

- (void) setSecondsSetSendToFLTs:(bool)aSecondsSetSendToFLTs
{
    if(secondsSetSendToFLTs == aSecondsSetSendToFLTs) return;

    [[[self undoManager] prepareWithInvocationTarget:self] setSecondsSetSendToFLTs:secondsSetSendToFLTs];
    
    secondsSetSendToFLTs = aSecondsSetSendToFLTs;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelSecondsSetSendToFLTsChanged object:self];
	
	//change settings for all FLTs
	[[self crate] updateKatrinV4FLTs];
}

- (BOOL) secondsSetInitWithHost
{
    return secondsSetInitWithHost;
}

- (void) setSecondsSetInitWithHost:(BOOL)aSecondsSetInitWithHost
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSecondsSetInitWithHost:secondsSetInitWithHost];
    secondsSetInitWithHost = aSecondsSetInitWithHost;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelSecondsSetInitWithHostChanged object:self];
}

- (NSString*) sltScriptArguments
{
	if(!sltScriptArguments)return @"";
    return sltScriptArguments;
}

- (void) setSltScriptArguments:(NSString*)aSltScriptArguments
{
	if(!aSltScriptArguments)aSltScriptArguments = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setSltScriptArguments:sltScriptArguments];
    
    [sltScriptArguments autorelease];
    sltScriptArguments = [aSltScriptArguments copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelSltScriptArgumentsChanged object:self];
	
	//NSLog(@"%@::%@  is %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),sltScriptArguments);//TODO: debug -tb-
}

- (BOOL) countersEnabled
{
    return countersEnabled;
}

- (void) setCountersEnabled:(BOOL)aCountersEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCountersEnabled:countersEnabled];
    
    countersEnabled = aCountersEnabled;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelCountersEnabledChanged object:self];
}

- (uint32_t) clockTime
{
    return clockTime;
}

- (void) setClockTime:(uint32_t)aClockTime
{
    clockTime = aClockTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelClockTimeChanged object:self];
}

- (uint64_t) runTime
{
    return runTime;
}

- (void) setRunTime:(uint64_t)aRunTime
{
    runTime = aRunTime;
    if([NSThread isMainThread]){
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelRunTimeChanged object:self];
    }
}

- (uint64_t) vetoTime
{
    return vetoTime;
}

- (void) setVetoTime:(uint64_t)aVetoTime
{
    vetoTime = aVetoTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelVetoTimeChanged object:self];
}

- (uint64_t) deadTime
{
    return deadTime;
}

- (void) setDeadTime:(uint64_t)aDeadTime
{
    deadTime = aDeadTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelDeadTimeChanged object:self];
}

- (uint64_t) lostEvents
{
    return lostEvents;

}

- (void) setLostEvents:(uint64_t)aValue
{
    lostEvents = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelLostEventsChanged object:self];
}

- (uint64_t) lostFltEvents
{
    return lostFltEvents;
    
}

- (void) setLostFltEvents:(uint64_t)aValue
{
    lostFltEvents = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelLostFltEventsChanged object:self];
}

- (uint64_t) lostFltEventsTr
{
    return lostFltEventsTr;
    
}

- (void) setLostFltEventsTr:(uint64_t)aValue
{
    lostFltEventsTr = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelLostFltEventsTrChanged object:self];
}

- (uint32_t) secondsSet
{
    return secondsSet;
}

- (void) setSecondsSet:(uint32_t)aSecondsSet
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSecondsSet:secondsSet];
    secondsSet = aSecondsSet;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelSecondsSetChanged object:self];
}

- (uint32_t) statusReg
{
    return statusReg;
}

- (void) setStatusReg:(uint32_t)aStatusReg
{
    statusReg = aStatusReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelStatusRegChanged object:self];
    [self checkPPSStatus];
}

- (uint32_t) controlReg
{
    return controlReg;
}

- (void) checkPPSEnabled
{
    if((controlReg & kCtrlPPSMask) != kCtrlPPSMask){
        if(!noPPSAlarm){
            noPPSAlarm = [[ORAlarm alloc] initWithName:@"External PPS DISABLED" severity:kSetupAlarm];
            [noPPSAlarm setSticky:YES];
            [noPPSAlarm setHelpString:@"Check the 'Ext PPS' option in the SLT Control Registor section. It should be enabled for synchronized runs"];
        }
         if(![noPPSAlarm isPosted])[noPPSAlarm postAlarm];
    }
    else {
        [noPPSAlarm clearAlarm];
        [noPPSAlarm release];
        noPPSAlarm = nil;
    }
}

- (void) checkPPSStatus
{
    // Todo: Implement test of time shift between Slt colock and Mac instead
    
/*
    if((statusReg & kCtrlPPSMask) != kCtrlPPSMask){
        if(!badPPSStatusAlarm){
            badPPSStatusAlarm = [[ORAlarm alloc] initWithName:@"SLT Not Synced (bad PPS bit)" severity:kHardwareAlarm];
            [badPPSStatusAlarm setSticky:YES];
            [badPPSStatusAlarm setHelpString:@"Check the 'PPS' status in the SLT status section. It indicates the crate is not synced"];
        }
        if(![badPPSStatusAlarm isPosted])[badPPSStatusAlarm postAlarm];
    }
    else {
        [badPPSStatusAlarm clearAlarm];
        [badPPSStatusAlarm release];
        badPPSStatusAlarm = nil;
    }
 */
}


- (void) checkPixelTrigger
{
    // The pixel mode should be enabled in all energy modes
    // but not in trace and especially not in histogram mode.
    // This would spoil the readout performance
    
    NSArray* allCards = [[self guardian] children];
    uint32_t aMask = 0x0;
    for(id aCard in allCards){
        if(![[aCard className] isEqualToString:[self className]]){
            int n = (int)[aCard stationNumber]-1;
            int runMode = [aCard runMode];
            if ((runMode == kKatrinV4Flt_EnergyDaqMode)
                    || (runMode == kKatrinV4Flt_VetoEnergyDaqMode)
                    || (runMode == kKatrinV4Flt_BipolarEnergyDaqMode))
                aMask |= (0x1<<n);
        }
    }
    
    if(((controlReg & kCtrlRunMask)==0) || (aMask != pixelBusEnableReg)){
        if(!pixelTriggerDisabledAlarm){
            pixelTriggerDisabledAlarm = [[ORAlarm alloc] initWithName:@"Pixel Trigger (partially) Deactivated" severity:kSetupAlarm];
            [pixelTriggerDisabledAlarm setSticky:YES];
            [pixelTriggerDisabledAlarm setHelpString:@"Check the 'Run' check box in the SLT Misc Ctrl Flags section and/or the Pixelbus setup for the available FLTs"];
            if(![pixelTriggerDisabledAlarm isPosted])[pixelTriggerDisabledAlarm postAlarm];
        }
    }
    else {
        [pixelTriggerDisabledAlarm clearAlarm];
        [pixelTriggerDisabledAlarm release];
        pixelTriggerDisabledAlarm = nil;
    }
    
}

- (void) checkSoftwareInhibit
{
    if((controlReg & (0x1<<kCtrlInhEnShift))==0){
        if(!swInhibitDisabledAlarm){
            swInhibitDisabledAlarm = [[ORAlarm alloc] initWithName:@"SLT Software Inhibit Deactivated" severity:kSetupAlarm];
            [swInhibitDisabledAlarm setSticky:YES];
            
        }
        if(![swInhibitDisabledAlarm isPosted])[swInhibitDisabledAlarm postAlarm];
    }
    else {
        [swInhibitDisabledAlarm clearAlarm];
        [swInhibitDisabledAlarm release];
        swInhibitDisabledAlarm = nil;
    }
}

- (void) setControlReg:(uint32_t)aControlReg
{
    [[[self undoManager] prepareWithInvocationTarget:self] setControlReg:controlReg];
    controlReg = aControlReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelControlRegChanged object:self];
    
    [self checkSoftwareInhibit];
    [self checkPixelTrigger];
    [self checkPPSEnabled];
    
}

- (uint32_t) projectVersion  { return (hwVersion & kRevisionProject)>>28;}
- (uint32_t) documentVersion { return (hwVersion & kDocRevision)>>16;}
- (uint32_t) implementation  { return hwVersion & kImplemention;}

- (void) setHwVersion:(uint32_t) aVersion
{
	hwVersion = aVersion;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelHwVersionChanged object:self];	
}

- (void) writeSetInhibit		{ [self writeReg:kKatrinV4SLTCommandReg value:kCmdSetInh];          }
- (void) writeClrInhibit		{ [self writeReg:kKatrinV4SLTCommandReg value:kCmdClrInh];          }
- (void) writeTpStart			{ [self writeReg:kKatrinV4SLTCommandReg value:kCmdTpStart];         }
- (void) writeFwCfg				{ [self writeReg:kKatrinV4SLTCommandReg value:kCmdFwCfg];           }
- (void) writeSltReset			{ [self writeReg:kKatrinV4SLTCommandReg value:kCmdSltReset];        }
- (void) writeFltReset			{ [self writeReg:kKatrinV4SLTCommandReg value:kCmdFltReset];        }
- (void) writeSwRq				{ [self writeReg:kKatrinV4SLTCommandReg value:kCmdSwRq];            }
- (void) writeClrCnt
{
    [self writeReg:kKatrinV4SLTCommandReg value:kCmdClrCnt];
    
    // Clear als Flt lost event counters
    // The sum is also displayed at the Slt dialog
    
    dataTakers = [[readOutGroup allObjects] retain];//cache of data takers.
    
    for(id obj in dataTakers){
        if([[obj class] isSubclassOfClass: NSClassFromString(@"ORKatrinV4FLTModel")]){//or ORIpeV4FLTModel
            [obj writeClrCnt];
        }
    }
}
- (void) writeEnCnt				{ [self writeReg:kKatrinV4SLTCommandReg value:kCmdEnCnt];           }
- (void) writeDisCnt			{ [self writeReg:kKatrinV4SLTCommandReg value:kCmdDisCnt];          }
- (void) clearAllStatusErrorBits{ [self writeReg:kKatrinV4SLTStatusReg  value:kStatusClearAllMask]; }
- (void) writeFIFOcsrReset      { [self writeReg:kKatrinV4SLTFIFOCsrReg value:kFIFOcsrResetMask];   }



- (id) controllerCard		{ return self;	  }
- (SBC_Link*)sbcLink		{ return pmcLink; } 
- (bool)sbcIsConnected      { return [pmcLink isConnected]; }

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:aPollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTPollTimeChanged object:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readAllStatus) object:nil];
    if(pollTime){
        [self performSelector:@selector(readAllStatus) withObject:nil afterDelay:2];
    }
}


- (void) runIsBetweenSubRuns:(NSNotification*)aNote
{
    // Handled in takeData
}


- (void) runIsStartingSubRun:(NSNotification*)aNote
{
    // Handled in takeData
}

#pragma mark •••Accessors

- (NSString*) patternFilePath
{
    return patternFilePath;
}

- (void) setPatternFilePath:(NSString*)aPatternFilePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternFilePath:patternFilePath];
	
	if(!aPatternFilePath)aPatternFilePath = @"";
    [patternFilePath autorelease];
    patternFilePath = [aPatternFilePath copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelPatternFilePathChanged object:self];
}

- (uint32_t) interruptMask
{
    return interruptMask;
}

- (void) setInterruptMask:(uint32_t)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    interruptMask = aInterruptMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTModelInterruptMaskChanged object:self];
}

- (ORReadOutList*) readOutGroup
{
	return readOutGroup;
}

- (void) setReadOutGroup:(ORReadOutList*)newReadOutGroup
{
	[readOutGroup autorelease];
	readOutGroup=[newReadOutGroup retain];
}

- (NSMutableArray*) children 
{
	//method exists to give common interface across all objects for display in lists
	return [NSMutableArray arrayWithObject:readOutGroup];
}


- (float) pulserDelay
{
    return pulserDelay;
}

- (void) setPulserDelay:(float)aPulserDelay
{
	if(aPulserDelay<100)		 aPulserDelay = 100;
	else if(aPulserDelay>3276.7) aPulserDelay = 3276.7;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setPulserDelay:pulserDelay];
    
    pulserDelay = aPulserDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTPulserDelayChanged object:self];
}

- (float) pulserAmp
{
    return pulserAmp;
}

- (void) setPulserAmp:(float)aPulserAmp
{
	if(aPulserAmp>4)aPulserAmp = 4;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setPulserAmp:pulserAmp];
    
    pulserAmp = aPulserAmp;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinV4SLTPulserAmpChanged object:self];
}

- (short) getNumberRegisters			
{ 
    return kKatrinV4SLTNumRegs; 
}

- (NSString*) getRegisterName: (short) anIndex
{
    return [katrinV4SLTRegisters registerName:anIndex];
}

- (uint32_t) getAddress: (short) anIndex
{
    return [katrinV4SLTRegisters address:anIndex];
}

- (short) getAccessType: (short) anIndex
{
	return [katrinV4SLTRegisters accessType:anIndex];
}

- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}

- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:selectedRegIndex];
    
    selectedRegIndex = anIndex;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORKatrinV4SLTSelectedRegIndexChanged
	 object:self];
}

- (uint32_t) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(uint32_t) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    
    writeValue = aValue;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORKatrinV4SLTWriteValueChanged
	 object:self];
}

/*! Send a script to the PrPMC which will configure the PrPMC.
 *
 */
- (void) sendSimulationConfigScriptON
{
	[self sendPMCCommandScript: [NSString stringWithFormat:@"%@ %i",@"SimulationConfigScriptON",[pmcLink portNumber]]];
}

/*! Send a script to the PrPMC which will configure the PrPMC.
 */
- (void) sendSimulationConfigScriptOFF
{
	[self sendPMCCommandScript: @"SimulationConfigScriptOFF"];
}

- (void) sendLinkWithDmaLibConfigScriptON
{
	NSLog(@"%@::%@: invoked.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));	
	[self sendPMCCommandScript: @"LinkWithDMALibConfigScriptON"];
}

- (void) sendLinkWithDmaLibConfigScriptOFF
{
	[self sendPMCCommandScript: @"LinkWithDMALibConfigScriptOFF"];
}

/*! Send a script to the PrPMC which will configure the PrPMC.
 *
 */
- (void) sendPMCCommandScript: (NSString*)aString;
{
	NSLog(@"%@::%@: invoked.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	//example code to send a script:  SBC_Link.m: - (void) installDriver:(NSString*)rootPwd 

	NSArray *scriptcommands = nil;//limited to 6 arguments (see loginScript)
	if(aString) scriptcommands = [aString componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if([scriptcommands count] >6) NSLog(@"WARNING: too much arguments in sendPMCConfigScript:\n");
	
	NSString *scriptName = @"KatrinV4SLTScript";
    ORTaskSequence* aSequence;
    aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
    
    NSString* driverCodePath; //[pmcLink ]
    if([pmcLink loadMode])driverCodePath = [[pmcLink filePath] stringByAppendingPathComponent:[self sbcLocalCodePath]];
    else driverCodePath = [resourcePath stringByAppendingPathComponent:[self codeResourcePath]];
    //driverCodePath = [driverCodePath stringByAppendingPathComponent:[delegate driverScriptName]];
    driverCodePath = [driverCodePath stringByAppendingPathComponent: scriptName];
    ORFileMover* driverScriptFileMover = [[ORFileMover alloc] init];//TODO: keep it as object in the class variables -tb-
    [driverScriptFileMover setDelegate:aSequence];
    NSLog(@"loadMode: %i driverCodePath: %@ \n",[pmcLink loadMode], driverCodePath);
    [driverScriptFileMover setMoveParams:[driverCodePath stringByExpandingTildeInPath]
                                    to:@"" 
                            remoteHost:[pmcLink IPNumber] 
                              userName:[pmcLink userName] 
                              passWord:[pmcLink passWord]];
    [driverScriptFileMover setVerbose:YES];
    [driverScriptFileMover doNotMoveFilesToSentFolder];
    [driverScriptFileMover setTransferType:eUseSCP];
    [aSequence addTaskObj:driverScriptFileMover];
    [driverScriptFileMover release];
    
    //NSString* scriptRunPath = [NSString stringWithFormat:@"/home/%@/%@",[pmcLink userName],scriptName];
    NSString* scriptRunPath = [NSString stringWithFormat:@"~/%@",scriptName];
    NSLog(@"  scriptRunPath: %@ \n" , scriptRunPath);

    //prepare script commands/arguments
    NSMutableArray *arguments = nil;
    arguments = [NSMutableArray arrayWithObjects:[pmcLink userName],[pmcLink passWord],[pmcLink IPNumber],scriptRunPath,nil];
    [arguments addObjectsFromArray:	scriptcommands];
    NSLog(@"  arguments: %@ \n" , arguments);

    //add task
    [aSequence addTask:[resourcePath stringByAppendingPathComponent:@"loginScript"] 
             arguments: arguments];  //limited to 6 arguments (see loginScript)

    
    [aSequence launch];

}


- (int) numberOfActiveThresholdFinder
{
    int nActive;
    
    dataTakers = [[readOutGroup allObjects] retain];//cache of data takers.
    
    nActive = 0;
    for(id obj in dataTakers){
        if([[obj class] isSubclassOfClass: NSClassFromString(@"ORKatrinV4FLTModel")]){//or ORIpeV4FLTModel
            //NSLog(@"FLT %i threshold finder %i\n", [obj stationNumber], [obj noiseFloorRunning]);
            if([obj noiseFloorRunning]) nActive = nActive + 1;
        }
    }

    return(nActive);
}

- (void) restoreInhibitStatus
{
    //NSLog(@"Restore inhibit status %i\n", savedInhibitStatus);
    if (savedInhibitStatus == 0){
         [self writeClrInhibit];
    } else {
         [self writeSetInhibit];
    }
}

- (void) saveInhibitStatus
{
    savedInhibitStatus = [self readStatusReg] & kStatusInh;
}


#pragma mark ***HW Access
- (void) checkPresence
{
	@try {
		[self readStatusReg];
		[self setPresent:YES];
	}
	@catch(NSException* localException) {
		[self setPresent:NO];
	}
}
/*
- (void) loadPatternFile
{
	NSString* contents = [NSString stringWithContentsOfFile:patternFilePath encoding:NSASCIIStringEncoding error:nil];
	if(contents){
		NSLog(@"loading Pattern file: <%@>\n",patternFilePath);
		NSScanner* scanner = [NSScanner scannerWithString:contents];
		int amplitude;
		[scanner scanInt:&amplitude];
		int i=0;
		int j=0;
		uint32_t time[256];
		uint32_t mask[20][256];
		int len = 0;
		BOOL status;
		while(1){
			status = [scanner scanHexInt:(unsigned*)&time[i]];
			if(!status)break;
			if(time[i] == 0){
				break;
			}
			for(j=0;j<20;j++){
				status = [scanner scanHexInt:(unsigned*)&mask[j][i]];
				if(!status)break;
			}
			i++;
			len++;
			if(i>256)break;
			if(!status)break;
		}
		
		@try {
			//collect all valid cards
			ORIpeFLTModel* cards[20];//TODO: ORKatrinV4SLTModel -tb-
			int i;
			for(i=0;i<20;i++)cards[i]=nil;
			
			NSArray* allFLTs = [[self crate] orcaObjects];
			NSEnumerator* e = [allFLTs objectEnumerator];
			id aCard;
			while(aCard = [e nextObject]){
				if([aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")])continue;//TODO: is this still true for v4? -tb-
				int index = [aCard stationNumber] - 1;
				if(index<20){
					cards[index] = aCard;
				}
			}
			for(i=0;i<20;i++){
				[cards[i] setFltRunMode: kIpeFlt_Test_Mode];
			}
			
			
			[self writeReg:kSltTestpulsAmpl value:amplitude];
			[self writeBlock:SLT_REG_ADDRESS(kSltTimingMemory) 
				  dataBuffer:time
					  length:len
				   increment:1];
			
			
			int j;
			for(j=0;j<20;j++){
				[cards[j] writeTestPattern:mask[j] length:len];
			}
			
			[self swTrigger];
			
			NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n");			
			NSLogFont(aFont,@"Index|  Time    | Mask                              Amplitude = %5d\n",amplitude);			
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n");			
			NSLogFont(aFont,@"     |    delta |  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20\n");			
			unsigned int delta = time[0];
			for(i=0;i<len;i++){
				NSMutableString* line = [NSMutableString stringWithFormat:@"  %2d |=%4d=%4d|",i,delta,time[i]];
				delta += time[i];
				for(j=0;j<20;j++){
					if(mask[j][i] != 0x1000000)[line appendFormat:@"%3s",mask[j][i]?"‚Ä¢":"-"];
					else [line appendFormat:@"%3s","="];
				}
				NSLogFont(aFont,@"%@\n",line);
			}
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n",amplitude);			
			
			
			for(i=0;i<20;i++){
				[cards[i] setFltRunMode: kIpeFltV4Katrin_Run_Mode];
			}
			
			
		}
		@catch(NSException* localException) {
			NSLogColor([NSColor redColor],@"Couldn't load Pattern file <%@>\n",patternFilePath);
		}
	}
	else NSLogColor([NSColor redColor],@"Couldn't open Pattern file <%@>\n",patternFilePath);
}

- (void) swTrigger
{
	[self writeReg:kSltSwTestpulsTrigger value:0];
}
*/

- (void) writeReg:(int)index value:(uint32_t)aValue
{
	[self write: [self getAddress:index] value:aValue];
}

- (void)		  rawWriteReg:(uint32_t) address  value:(uint32_t)aValue
//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
{
    [self write: address value: aValue];
}

- (uint32_t) rawReadReg:(uint32_t) address
//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
{
	return [self read: address];

}

- (uint32_t) readReg:(int) index
{
	return [self read: [self getAddress:index]];

}

- (id) writeHardwareRegisterCmd:(uint32_t) regAddress value:(uint32_t) aValue
{
	return [ORPMCReadWriteCommand writeLongBlock:&aValue
									   atAddress:regAddress
									  numToWrite:1];
}

- (id) readHardwareRegisterCmd:(uint32_t) regAddress
{
	return [ORPMCReadWriteCommand readLongBlockAtAddress:regAddress
									  numToRead:1];
}

- (void) executeCommandList:(ORCommandList*)aList
{
	[pmcLink executeCommandList:aList];
}

- (void) readAllStatus
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readAllStatus) object:nil];

	//[self readControlReg];
	[self readStatusReg];
    [self getSeconds];

    // Read only during run
    if ([gOrcaGlobals runInProgress]) {
        [self readDeadTime];
        [self readLostEvents];
        [self readLostFltEvents];
        [self readLostFltEventsTr];
        [self readVetoTime];
        [self readRunTime];
    }
    
    if(pollTime){
        [self performSelector:@selector(readAllStatus) withObject:nil afterDelay:pollTime];
    }
}


- (uint32_t) readStatusReg
{
	uint32_t data = [self readReg:kKatrinV4SLTStatusReg];
	[self setStatusReg:data];
	return data;
}

- (void) printStatusReg
{
	uint32_t data = [self readStatusReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Status Register %@ ----\n",[self fullID]);
	NSLogFont(aFont,@"WatchDogError : %@\n",IsBitSet(data,kStatusWDog)?@"YES":@"NO");
	NSLogFont(aFont,@"PixelBusError : %@\n",IsBitSet(data,kStatusPixErr)?@"YES":@"NO");
	NSLogFont(aFont,@"PPSError      : %@\n",IsBitSet(data,kStatusPpsErr)?@"YES":@"NO");
	NSLogFont(aFont,@"Clock         : 0x%02x\n",ExtractValue(data,kStatusClkErr,4));
	NSLogFont(aFont,@"VttError      : %@\n",IsBitSet(data,kStatusVttErr)?@"YES":@"NO");
	NSLogFont(aFont,@"GPSError      : %@\n",IsBitSet(data,kStatusGpsErr)?@"YES":@"NO");
	NSLogFont(aFont,@"FanError      : %@\n",IsBitSet(data,kStatusFanErr)?@"YES":@"NO");
}

- (int32_t) getSBCCodeVersion
{
	int32_t theVersion = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetSoftwareVersion numToRead:1];
		//implementation is in HW_Readout.cc, void doGeneralReadOp(SBC_Packet* aPacket,uint8_t reply)  ... -tb-
	}
	[pmcLink setSbcCodeVersion:theVersion];
	return theVersion;
}

- (int32_t) getFdhwlibVersion
{
	int32_t theVersion = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetFdhwLibVersion numToRead:1];
	}
	return theVersion;
}

- (int32_t) getSltPciDriverVersion
{
	int32_t theVersion = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetSltPciDriverVersion numToRead:1];
	}
	return theVersion;
}

- (int32_t) getSltkGetIsLinkedWithPCIDMALib  //TODO: write a all purpose method for generalRead!!! -tb-
{
	int32_t theVersion = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetIsLinkedWithPCIDMALib numToRead:1];
	}
	return theVersion;
}

- (void) setHostTimeToFLTsAndSLT
{
    uint32_t args[2];
	args[0] = 0; //flags
        if(secondsSetInitWithHost)  args[0] |= kSecondsSetInitWithHostFlag;
        if(secondsSetSendToFLTs)    args[0] |= kSecondsSetSendToFLTsFlag;
	args[1] = secondsSet; //time to write
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink writeGeneral:(int32_t*)&args operation:kSetHostTimeToFLTsAndSLT numToWrite:2];
	}
}

- (uint64_t) readBoardID
{
	uint32_t low = [self readReg:kKatrinV4SLTBoardIDLoReg];
	uint32_t hi  = [self readReg:kKatrinV4SLTBoardIDHiReg];
	BOOL crc =(hi & 0x80000000)==0x80000000;
	if(crc){
		return (uint64_t)(hi & 0xffff)<<32 | low;
	}
	else return 0;
}

- (uint32_t) readControlReg
{
	return [self readReg:kKatrinV4SLTControlReg];
}

- (void) printControlReg
{
	uint32_t data = [self readControlReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Control Register %@ ----\n",[self fullID]);
	NSLogFont(aFont,@"Trigger Enable : 0x%02x\n",data & kCtrlTrgEnMask);
	NSLogFont(aFont,@"Inibit Enable  : 0x%02x\n",(data & kCtrlInhEnMask) >> 6);
	NSLogFont(aFont,@"PPS            : %@\n",IsBitSet(data,kCtrlPPSMask)?@"GPS":@"Internal");
	NSLogFont(aFont,@"TP Enable      : 0x%02x\n", ExtractValue(data,kCtrlTpEnMask,11));
	NSLogFont(aFont,@"TP Shape       : %d\n", IsBitSet(data,kCtrlShapeMask));
	NSLogFont(aFont,@"Run Mode       : %@\n", IsBitSet(data,kCtrlRunMask)?@"ON":@"OFF");
	NSLogFont(aFont,@"Test SLT       : %@\n", IsBitSet(data,kCtrlTstSltMask)?@"Enabled":@"Disabled");
	NSLogFont(aFont,@"IntA Enable    : %@\n", IsBitSet(data,kCtrlIntEnMask)?@"Enabled":@"Disabled");
}

- (void) writeControlReg
{
	[self writeReg:kKatrinV4SLTControlReg value:controlReg];
    [self readStatusReg];
}

- (void) writeControlRegRunFlagOn:(BOOL) aState
{
    uint32_t controlRegValue = [self readControlReg];
    if(aState) controlRegValue |= kCtrlRunMask;
    else       controlRegValue &= ~kCtrlRunMask;
	[self writeReg:kKatrinV4SLTControlReg value:controlRegValue];
    usleep(2);
    [self readStatusReg];
}

- (void) writePixelBusEnableReg
{
	[self writeReg:kKatrinV4SLTPixelBusEnableReg value: [self pixelBusEnableReg]];
}

- (void) readPixelBusEnableReg
{
    uint32_t val;
	val = [self readReg:kKatrinV4SLTPixelBusEnableReg];
	[self setPixelBusEnableReg:val];	
}


//for test purposes: read a single event from event FIFO -tb-
- (void) readSLTEventFifoSingleEvent
{
    uint32_t mode = [self readReg:kKatrinV4SLTFIFOModeReg];
    NSLog(@"FIFO entries: %i events (words: %i) (reg 0x%08x) \n",(mode & 0x3fffff) / 6, mode & 0x3fffff, mode);//DEBUG -tb-
    if(mode & 0x3fffff){
    	uint32_t f1 = [self readReg:kKatrinV4SLTDataFIFOReg];
	    uint32_t f2 = [self readReg:kKatrinV4SLTDataFIFOReg];
	    uint32_t f3 = [self readReg:kKatrinV4SLTDataFIFOReg];
        uint32_t f4 = [self readReg:kKatrinV4SLTDataFIFOReg];
        uint32_t f5 = [self readReg:kKatrinV4SLTDataFIFOReg];
        uint32_t f6 = [self readReg:kKatrinV4SLTDataFIFOReg];
    
        NSLog(@"FIFO entry: 0x%08x, 0x%08x, 0x%08x, 0x%08x   \n",f1,f2,f3,f4,f5,f6 );//DEBUG -tb-
        
        uint32_t p       = (f1 >> 28) & 0x1;
        uint32_t subsec  = f1  & 0x1ffffff;
        uint32_t sec     = f2;
        uint32_t flt     = (f3 >> 24) & 0x1f;
        uint32_t chan    = (f3 >> 19) & 0x1f;
        uint32_t multiplicity  = (f3 >> 14) & 0x1f;
        uint32_t evID    = f3 & 0x7ff;
        uint32_t tPeak  = f4  & 0x1ff;
        uint32_t aPeak  = f4  & 0x1ff;
        uint32_t tValley  = f5  & 0xfff;
        uint32_t aValley  = f4  & 0xfff;

        uint32_t energy  = f6  & 0xfffff;
        
        NSLog(@"FIFO entry:  flt:    %u  chan: %u    energy: %u    sec: %u    subsec: %u\n",flt,chan,energy,sec,subsec );
        NSLog(@"FIFO entry:  multi.: %u   p: %u    evID: %u\n",multiplicity,p,evID );
        NSLog(@"FIFO entry:  tPeak:  %u  tValley: %u    aPeak: %u    aValley: %u\n",tPeak,tValley,aPeak,aValley );
        NSLog(@"-------------------------------------------------------------\n" );

    }
}

- (void) loadSecondsReg
{
    [self setHostTimeToFLTsAndSLT];
    
    return;
}

- (void) writeInterruptMask
{
	[self writeReg:kKatrinV4SLTInterruptMaskReg value:interruptMask];
}

- (void) readInterruptMask
{
	[self setInterruptMask:[self readReg:kKatrinV4SLTInterruptMaskReg]];
}

- (void) readInterruptRequest
{
	[self setInterruptMask:[self readReg:kKatrinV4SLTInterruptReguestReg]];
}

- (void) printInterruptRequests
{
	[self printInterrupt:kKatrinV4SLTInterruptReguestReg];
}

- (void) printInterruptMask
{
	[self printInterrupt:kKatrinV4SLTInterruptMaskReg];
}

- (void) printInterrupt:(int)regIndex
{
	uint32_t data = [self readReg:regIndex];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	if(!data)NSLogFont(aFont,@"Interrupt Mask is Clear (No interrupts %@)\n",regIndex==kKatrinV4SLTInterruptReguestReg?@"Requested":@"Enabled");
	else {
		NSLogFont(aFont,@"The following interrupts are %@:\n",regIndex==kKatrinV4SLTInterruptReguestReg?@"Requested":@"Enabled");
		NSString* s = @"";
		if(data & (1<<0))s = [s stringByAppendingString: @" FLT Rq |"];
		if(data & (1<<1))s = [s stringByAppendingString: @" WDog |"];
		if(data & (1<<2))s = [s stringByAppendingString: @" Pixel Err |"];
		if(data & (1<<3))s = [s stringByAppendingString: @" PPS Err |"];
		if(data & (1<<4))s = [s stringByAppendingString: @" Clk 0 Err |"];
		if(data & (1<<5))s = [s stringByAppendingString: @" Clk 1 Err |"];
		if(data & (1<<6))s = [s stringByAppendingString: @" Clk 2 Err |"];
		if(data & (1<<7))s = [s stringByAppendingString: @" Clk 3 Err |"];
		if(data & (1<<8))s = [s stringByAppendingString: @" GPS Err |"];
		if(data & (1<<9))s = [s stringByAppendingString: @" VTT Err |"];
		if(data & (1<<10))s = [s stringByAppendingString:@" Fan Err |"];
		if(data & (1<<11))s = [s stringByAppendingString:@" SW Rq Err |"];
		if(data & (1<<12))s = [s stringByAppendingString:@" Event Ready |"];
		if(data & (1<<13))s = [s stringByAppendingString:@" Page Ready |"];
		if(data & (1<<14))s = [s stringByAppendingString:@" Page Full |"];
		if(data & (1<<15))s = [s stringByAppendingString:@" Flt Timeout |"];
		NSLogFont(aFont,@"%@\n",[s substringToIndex:[s length]-1]);
	}
}

- (uint32_t) readHwVersion
{
	uint32_t value=0;
	@try {
        value = [self readReg: kKatrinV4SLTHWRevisionReg];
		[self setHwVersion: value];	
	}
	@catch (NSException* e){
	}
	return value;
}
- (uint64_t) readLostEvents
{
    uint32_t high = [self readReg:kKatrinV4SLTLostEventsCountHiReg];
    uint32_t low  = [self readReg:kKatrinV4SLTLostEventsCountLoReg];
    [self setLostEvents:((uint64_t)high << 32) | low];
    return lostEvents;
}

- (uint64_t) readLostFltEvents
{
    uint64_t sum = 0;
    for(id flt in dataTakers){
        sum += [flt readLostEvents];
    }
    [self setLostFltEvents:sum];

    return(sum);
}

- (uint64_t) readLostFltEventsTr
{
    uint64_t sum = 0;
    for(id flt in dataTakers){
        sum += [flt readLostEventsTr];
    }
    [self setLostFltEventsTr:sum];
    
    return(sum);
}

- (uint64_t) readDeadTime
{
	uint32_t low  = [self readReg:kKatrinV4SLTDeadTimeCounterLoReg];
	uint32_t high = [self readReg:kKatrinV4SLTDeadTimeCounterHiReg];
	[self setDeadTime:((uint64_t)high << 32) | low];
	return deadTime;
}

- (uint64_t) readVetoTime
{
	uint32_t low  = [self readReg:kKatrinV4SLTVetoCounterLoReg];
	uint32_t high = [self readReg:kKatrinV4SLTVetoCounterHiReg];
	[self setVetoTime:((uint64_t)high << 32) | low];
	return vetoTime;
}

- (uint64_t) readRunTime
{
	uint64_t low  = [self readReg:kKatrinV4SLTRunCounterLoReg];
	uint64_t high = [self readReg:kKatrinV4SLTRunCounterHiReg];
	uint64_t theTime = ((uint64_t)high << 32) | low;
	[self setRunTime:theTime];
	return theTime;
}

- (void) clearRunTime
{
    [self writeReg:kKatrinV4SLTRunCounterLoReg value:0]; //clears hi and lo
    [self setRunTime:0];
}

- (double) readTime
{
    double time; // in secs
    uint32_t subsec = [self readSubSecondsCounter];
    uint32_t sec = [self readSecondsCounter];
    
    time = sec + ((double) ((subsec  >> 11) & 0x3fff)) / 10000;

    return (time);
}

- (uint32_t) readSecondsCounter
{
	return [self readReg:kKatrinV4SLTSecondCounterReg];
}

- (uint32_t) readSubSecondsCounter
{
	return [self readReg:kKatrinV4SLTSubSecondCounterReg];
}

- (uint32_t) getSeconds
{
	[self readSubSecondsCounter]; //must read the sub seconds to load the seconds register
	[self setClockTime: [self readSecondsCounter]];
	return clockTime;
}

- (uint32_t) getRunStartSecond
{
    return runStartSec;
}

- (uint32_t) getRunEndSecond
{
    return sltSecondRunStop;
}
    
- (void) initBoard
{
    // Todo: Check that all Slt parameters are included
    [self writeFIFOcsrReset];

    if (countersEnabled) [self writeEnCnt];
    else                 [self writeDisCnt];
    [self loadSecondsReg];
    [self writeControlReg];
    [self writeInterruptMask];
    [self clearAllStatusErrorBits];
    [self writePixelBusEnableReg];
    [self clearRunTime];

    //-----------------------------------------------
	//board doesn't appear to start without this stuff
	//[self writeReg:kSltActResetFlt value:0];
	//[self writeReg:kSltActResetSlt value:0];
	//usleep(10);
	//[self writeReg:kSltRelResetFlt value:0];
	//[self writeReg:kSltRelResetSlt value:0];
	//[self writeReg:kSltSwSltTrigger value:0];
	//[self writeReg:kSltSwSetInhibit value:0];
	
	//usleep(100);
	
//	int savedTriggerSource = triggerSource;
//	int savedInhibitSource = inhibitSource;
//	triggerSource = 0x1; //sw trigger only
//	inhibitSource = 0x3; 
//	[self writePageManagerReset];
	//uint64_t p1 = ((uint64_t)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	//[self writeReg:kSltSwRelInhibit value:0];
	//int i = 0;
	//uint32_t lTmp;
    //do {
	//	lTmp = [self readReg:kSltStatusReg];
		//NSLog(@"waiting for inhibit %x i=%d\n", lTmp, i);
		//usleep(10);
		//i++;
   // } while(((lTmp & 0x10000) != 0) && (i<10000));
	
   // if (i>= 10000){
		//NSLog(@"Release inhibit failed\n");
		//[NSException raise:@"SLT error" format:@"Release inhibit failed"];
	//}
/*	
	uint64_t p2  = ((uint64_t)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	if(p1 == p2) NSLog (@"No software trigger\n");
	[self writeReg:kSltSwSetInhibit value:0];
 */
//	triggerSource = savedTriggerSource;
	//inhibitSource = savedInhibitSource;
	//-----------------------------------------------
	
	//[self printStatusReg];
	//[self printControlReg];
}
- (void) initAllBoards
{
    [self initBoard];
    for(id obj in dataTakers){
        [obj initBoard];
    }
}

- (void) reset
{
	[self hw_config];
	[self hw_reset];
}

- (void) hw_config
{
	NSLog(@"SLT: HW Configure\n");
	[ORTimer delay:1.5];
	[ORTimer delay:1.5];
	//[self readReg:kSltStatusReg];
	[guardian checkCards];
}

- (void) hw_reset
{
	NSLog(@"SLT: HW Reset\n");
	//[self writeReg:kSltSwRelInhibit value:0];
	//[self writeReg:kSltActResetFlt value:0];
	//[self writeReg:kSltActResetSlt value:0];
	usleep(10);
	//[self writeReg:kSltRelResetFlt value:0];
	//[self writeReg:kSltRelResetSlt value:0];
	//[self writeReg:kSltSwSltTrigger value:0];
	//[self writeReg:kSltSwSetInhibit value:0];				
}

/*
- (void) loadPulseAmp
{
	unsigned short theConvertedAmp = pulserAmp * 4095./4.;
	[self writeReg:kSltTestpulsAmpl value:theConvertedAmp];
	NSLog(@"Wrote %.2fV to SLT pulser Amplitude\n",pulserAmp);
}

- (void) loadPulseDelay
{
	//delay goes from 100ns to 3276.8us
	//writing 0x00 to hw gives longest delay. 
	//conversion equation:  hwValue = -10.0*delay + 32768.
	unsigned short theConvertedDelay = pulserDelay * -10.0 + 32768.;
	[self write:SLT_REG_ADDRESS(kSltTestpulsTiming)+0 value:theConvertedDelay];
	[self write:SLT_REG_ADDRESS(kSltTestpulsTiming)+1 value:theConvertedDelay];
	int i; //load the rest of the pulser memory with 0's
	for (i=2;i<256;i++) [self write:SLT_REG_ADDRESS(kSltTestpulsTiming)+i value:theConvertedDelay];
}

- (void) loadPulserValues
{
	[self loadPulseAmp];
	[self loadPulseDelay];
}
*/

- (void) setCrateNumber:(unsigned int)aNumber
{
	[guardian setCrateNumber:aNumber];
}


- (BOOL) compareRegisters:(BOOL)verbose
{
    BOOL differencesExist = NO;
    for(id obj in dataTakers){
        differencesExist |= [obj compareRegisters:verbose];
    }
    
    return differencesExist;
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
    pmcLink = [[decoder decodeObjectForKey:@"PMC_Link"] retain];
    if(!pmcLink)pmcLink = [[PMC_Link alloc] initWithDelegate:self];
    else                  [pmcLink setDelegate:self];

    
    [self setMinimizeDecoding:       [decoder decodeBoolForKey:  @"minimizeDecoding"]];
	[self setPixelBusEnableReg:     [decoder decodeIntForKey:@"pixelBusEnableReg"]];
	[self setSltScriptArguments:    [decoder decodeObjectForKey:@"sltScriptArguments"]];
	[self setControlReg:            [decoder decodeIntForKey:@"controlReg"]];
	[self setSecondsSet:            [decoder decodeIntForKey:@"secondsSet"]];
	[self setSecondsSetSendToFLTs:  [decoder decodeBoolForKey:@"secondsSetSendToFLTs"]];
	[self setCountersEnabled:       [decoder decodeBoolForKey:@"countersEnabled"]];
	[self setPatternFilePath:		[decoder decodeObjectForKey:@"ORKatrinV4SLTModelPatternFilePath"]];
	[self setInterruptMask:			[decoder decodeIntForKey:@"ORKatrinV4SLTModelInterruptMask"]];
	[self setPulserDelay:			[decoder decodeFloatForKey:@"ORKatrinV4SLTModelPulserDelay"]];
	[self setPulserAmp:				[decoder decodeFloatForKey:@"ORKatrinV4SLTModelPulserAmp"]];
	[self setReadOutGroup:			[decoder decodeObjectForKey:@"ReadoutGroup"]];
    [self setPollTime:				[decoder decodeIntForKey:@"pollTime"]];
    
	
	//These were added when the object was already in the config and so might not availale if old config is read
    if([decoder containsValueForKey:@"secondsSetInitWithHost"]){
        [self setSecondsSetInitWithHost:[decoder decodeBoolForKey:@"secondsSetInitWithHost"]];
    }
    else [self setSecondsSetInitWithHost: YES];
	if(!readOutGroup){
		ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
		[self setReadOutGroup:readList];
		[readList release];
	}

	[[self undoManager] enableUndoRegistration];
    
	[self registerNotificationObservers];
		
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	
	[encoder encodeInt:pixelBusEnableReg        forKey:@"pixelBusEnableReg"];
    [encoder encodeBool:minimizeDecoding        forKey:@"minimizeDecoding"];
	[encoder encodeBool:secondsSetSendToFLTs    forKey:@"secondsSetSendToFLTs"];
	[encoder encodeBool:secondsSetInitWithHost  forKey:@"secondsSetInitWithHost"];
	[encoder encodeObject:sltScriptArguments    forKey:@"sltScriptArguments"];
	[encoder encodeBool:countersEnabled         forKey:@"countersEnabled"];
	[encoder encodeInt:secondsSet             forKey:@"secondsSet"];
	[encoder encodeObject:pmcLink               forKey:@"PMC_Link"];
	[encoder encodeInt:controlReg             forKey:@"controlReg"];
	[encoder encodeObject:patternFilePath       forKey:@"ORKatrinV4SLTModelPatternFilePath"];
	[encoder encodeInt:interruptMask          forKey:@"ORKatrinV4SLTModelInterruptMask"];
	[encoder encodeFloat:pulserDelay            forKey:@"ORKatrinV4SLTModelPulserDelay"];
	[encoder encodeFloat:pulserAmp              forKey:@"ORKatrinV4SLTModelPulserAmp"];
	[encoder encodeObject:readOutGroup          forKey:@"ReadoutGroup"];
    [encoder encodeInteger:pollTime                 forKey:@"pollTime"];
		
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORKatrinV4SLTDecoderForEvent",		@"decoder",
								 [NSNumber numberWithLong:eventDataId],	@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:5],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"KatrinV4SLTEvent"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORKatrinV4SLTDecoderForMultiplicity",		@"decoder",
				   [NSNumber numberWithLong:multiplicityId],    @"dataId",
				   [NSNumber numberWithBool:NO],				@"variable",
				   [NSNumber numberWithLong:3+20*100],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"KatrinV4SLTMultiplicity"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORKatrinV4SLTDecoderForEventFifo",			@"decoder",
				   [NSNumber numberWithLong:eventFifoId],       @"dataId",
				   [NSNumber numberWithBool:YES],				@"variable",
				   [NSNumber numberWithLong:-1],			    @"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"KatrinV4SLTEventFifo"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORKatrinV4SLTDecoderForEnergy",			@"decoder",
				   [NSNumber numberWithLong:energyId],          @"dataId",
				   [NSNumber numberWithBool:YES],				@"variable",
				   [NSNumber numberWithLong:-1],			    @"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"KatrinV4SLTEnergy"];
    
    return dataDictionary;
}

- (uint32_t) eventDataId                       { return eventDataId; }
- (uint32_t) multiplicityId                    { return multiplicityId; }
- (uint32_t) eventFifoId                       { return eventFifoId; }
- (uint32_t) energyId                          { return energyId; }
- (void) setEventDataId:    (uint32_t) aDataId { eventDataId = aDataId; }
- (void) setMultiplicityId: (uint32_t) aDataId { multiplicityId = aDataId; }
- (void) setEventFifoId:    (uint32_t) aDataId { eventFifoId = aDataId; }
- (void) setEnergyId:       (uint32_t) aDataId { energyId = aDataId; }

- (void) setDataIds:(id)assigner
{
    eventDataId     = [assigner assignDataIds:kLongForm];
    multiplicityId  = [assigner assignDataIds:kLongForm];
    eventFifoId     = [assigner assignDataIds:kLongForm];
    energyId        = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setEventDataId:   [anotherCard eventDataId]];
    [self setMultiplicityId:[anotherCard multiplicityId]];
    [self setEventFifoId:   [anotherCard eventFifoId]];
    [self setEnergyId:      [anotherCard energyId]];
}

//this goes to the Run header ...
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    //added 2013-04-29 -tb-
	[objDictionary setObject:[NSNumber numberWithLong:controlReg]				    forKey:@"ControlReg"];
	[objDictionary setObject:[NSNumber numberWithInt:countersEnabled]				forKey:@"CountersEnabled"];
	[objDictionary setObject:[NSNumber numberWithInt:secondsSetInitWithHost]		forKey:@"SecondsSetInitWithHost"];
	if(!secondsSetInitWithHost) [objDictionary setObject:[NSNumber numberWithLong:secondsSet] forKey:@"SecondsInitializeTo"];
	[objDictionary setObject:[NSNumber numberWithInt:secondsSetSendToFLTs]		    forKey:@"SecondsUseForFLTs"];
    //this is accessing the hardware and might fail
	@try {
	    [objDictionary setObject:[NSNumber numberWithUnsignedLong:[self readHwVersion]]           forKey:@"FPGAVersion"];
	    [objDictionary setObject:[NSString stringWithFormat:@"0x%08x",[self readHwVersion]]      forKey:@"FPGAVersionString"];
	    [objDictionary setObject:[NSNumber numberWithLong:[self getSBCCodeVersion]]               forKey:@"SBCCodeVersion"];
	    [objDictionary setObject:[NSNumber numberWithLong:[self getSltPciDriverVersion]]          forKey:@"SLTDriverVersion"];
	    [objDictionary setObject:[NSNumber numberWithLong:[self getSltkGetIsLinkedWithPCIDMALib]] forKey:@"LinkedWithDMALib"];
	}
	@catch (NSException* e){
	}

	return objDictionary;
}

#pragma mark •••Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    uint32_t sltsubsecreg;
    uint32_t sltsec;
    uint32_t sltsubsec2;
    double sltTime;
    
    waitForSubRunStart = false;
    waitForSubRunEnd = false;
    runStartSec = 0;
    sltSecondRunStop = 0xffffffff;
    
    [self setIsPartOfRun: YES];

    [self clearExceptionCount];
	
	//check that we can actually run
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Check the SLT connection"];
	}
	
    dataTakers = [[readOutGroup allObjects] retain];//cache of data takers.
    
    
    // Check if any of the Flts is using the threshold finder
    if ([self numberOfActiveThresholdFinder] > 0){
        NSLog(@"Wait for threshold finder to finish\n");
        [NSException raise:@"SLT error" format:@"Threshold finder blocks run"];
    }

    
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORKatrinV4SLTModel"];    
    //----------------------------------------------------------------------------------------	
	
    sltTime = [self readTime];
    NSLog(@"SLT %f - Prepare for run\n", sltTime);
    
    
    [[self sbcLink] checkSBCAccurateTime];

          
    // Stop crate
    [self saveInhibitStatus];
    [self writeSetInhibit];

    // Wait for inhibit; changes state with the next second strobe
    uint32_t lStatus;
    int i = 0;
    do {
        lStatus = [self readStatusReg];
        usleep(100000);
        i++;
    } while(((lStatus & kStatusInh) == 0) && (i<15));
    
    if (i>= 15){
        NSLog(@"Set inhibit failed\n");
        [NSException raise:@"SLT error" format:@"Set inhibit failed"];
    }

    // Make sure we start not at the very end of the secons
    sltTime = [self readTime];
    NSLog(@"SLT %f - Crate has stopped\n", sltTime);
    
    [[self sbcLink] checkSBCTime];
    
    sltsubsecreg  = [self readReg:kKatrinV4SLTSubSecondCounterReg];
    sltsubsec2    = (sltsubsecreg >> 11) & 0x3fff;
    if (sltsubsec2 > 8000) {
        usleep(205000);
    }
    [self writeControlRegRunFlagOn:FALSE];//stop run mode -> clear event buffer -tb- 2016-05

    //if cold start (not 'quick start' in RunControl) ...
    if([[userInfo objectForKey:@"doinit"]intValue]){
        [self initBoard];
    }
    //loop over Readout List and tell our children the run is starting
	for(id obj in dataTakers){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
        [obj stopReadingHitRates];
    }

    sltTime = [self readTime];
    NSLog(@"SLT %f - Data takers started\n", sltTime);

    // Clear counter and update display
    [self writeClrCnt];
    [self readAllStatus];
    
	eventCounter        = 0;
	first               = YES;
	lastDisplaySec      = 0;
	lastDisplayCounter  = 0;
	lastDisplayRate     = 0;
	lastSimSec          = 0;
    
	
	//load all the data needed for the eCPU to do the HW read-out.
	[self load_HW_Config];
	[pmcLink runTaskStarted:aDataPacket userInfo:userInfo];//method of SBC_Link.m: init alarm handling; send kSBC_StartRun to SBC/PrPMC -tb-

    uint64_t runcount = [self readRunTime];
    [self shipSltEvent:kRunCounterType withType:kStartRunType eventCt:0 high: (runcount>>32)&0xffffffff low:(runcount)&0xffffffff ];
    
    // Check finally, if the inhibit soiurce has been deactivated during config upload
    lStatus = [self readStatusReg];
    if ((lStatus & kStatusInh) == 0) {
        NSLog(@"Set inhibit failed\n");
        [NSException raise:@"SLT error" format:@"Set inhibit failed"];
    }

    // Release inhibit with the next second strobe
    [self writeClrInhibit];

    //
    // Save the first second of the run
    // Is used by hitrate readout to aviod too early storage
    //
    sltsubsecreg  = [self readReg:kKatrinV4SLTSubSecondCounterReg];
    sltsec        = [self readReg:kKatrinV4SLTSecondCounterReg];
    sltsubsec2    = (sltsubsecreg >> 11) & 0x3fff;
    
    runStartSec = sltsec + 1;
    
    // If inhibit has been released the time needs to be corrected
    lStatus = [self readStatusReg];
    if ((lStatus & kStatusInh) == 0) {
        
        sltsubsecreg  = [self readReg:kKatrinV4SLTSubSecondCounterReg];
        sltsec        = [self readReg:kKatrinV4SLTSecondCounterReg];
        sltsubsec2    = (sltsubsecreg >> 11) & 0x3fff;
        
        runStartSec = sltsec;
    }
    
    NSLog(@"SLT %i.%03i - Crate is ready for data taking, run start at %i run time %i\n",
          sltsec, sltsubsec2/10, runStartSec);

    // Write run start time; starts always with the second strobe
    [self shipSltEvent:kSecondsCounterType withType:kStartRunType eventCt:0 high:runStartSec low:0 ];

    callRunIsStopping = false;
    lastHitrateSec = runStartSec -1;
    
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    
    uint32_t subseconds;
    uint32_t seconds;
    //uint32_t subsec2;
    double sltTime;
    
    //event readout controlled by the SLT cpu now. ORCA reads out
    //the resulting data from a generic circular buffer in the pmc code.
    [pmcLink takeData:aDataPacket userInfo:userInfo];
    
    // The flag is set in doneTakingData
    // There the argument userInfo is missing
    if (callRunIsStopping){
        
        callRunIsStopping = false;
        
        for(id obj in dataTakers){
            [obj runIsStopping:aDataPacket userInfo:userInfo];
        }
        [pmcLink runIsStopping:aDataPacket userInfo:userInfo];
    }
    

    // Manage subrun status
    if (waitForSubRunStart){
        sltTime = [self readTime];
        
        if (sltTime >= secondToWaitFor) {
            waitForSubRunStart = false;
            [self shipSltRunCounter:    kStartSubRunType];
            NSLog(@"SLT %f - met second strobe %i\n", sltTime, secondToWaitFor);
            
            // Wait for second strobe or inhibit to become active
            NSLog(@"Go ahead to start subrun\n");
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORReleaseRunStateChangeWait object: self];
        }
    }
    
    
    if (waitForSubRunEnd){
        sltTime = [self readTime];
        
        if (sltTime >= secondToWaitFor) {
            waitForSubRunEnd = false;
            [self shipSltRunCounter:    kStopSubRunType];
            NSLog(@"SLT %f - met second strobe %i\n", sltTime, secondToWaitFor);
            
            // Wait for second strobe or inhibit to become active
            NSLog(@"Go ahead to terminate subrun\n");
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORReleaseRunStateChangeWait object: self];
        }
    }

    
    // Read hitrate - alternative scheduling, independant from any macOS timer
    subseconds = [self readSubSecondsCounter]; // req. to read subsec first !!!
    seconds = [self readSecondsCounter];
    //subsec2 = (subseconds >> 11) & 0x3fff;
    
    if (seconds > lastHitrateSec) {
        lastHitrateSec = seconds;
        
        //NSLog(@"SLT %i.%03i - reading hitrates from SLT\n", seconds, subsec2/10);

        // Call readHitrate in all Flt
        for(id obj in dataTakers){
            [obj performSelectorOnMainThread:@selector(readHitRates) withObject:nil waitUntilDone:NO ];
        }
    }
    
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    uint32_t sltsubsecreg;
    uint32_t sltsec;
    uint32_t sltsubsec2;
    
    @try {
        sltsubsecreg  = [self readReg:kKatrinV4SLTSubSecondCounterReg];
        sltsec        = [self readReg:kKatrinV4SLTSecondCounterReg];
        sltsubsec2    = (sltsubsecreg >> 11) & 0x3fff;
        NSLog(@"SLT %i.%03i - Stopping run; set inhibit\n", sltsec, sltsubsec2/10);
    }
    @catch(NSException* e){
        NSLog(@"SLT - runIsStopping Method: Exception reading one of the second counters. %@\n", e);
        [e raise]; //this will also be caught in Run Control
    }
    
    [self writeSetInhibit]; //TODO: maybe move to readout loop to avoid dead time -tb-
    inhibitLastCheck = 0;
}

- (BOOL) doneTakingData
{
    uint32_t lStatus;
    double sltTime;
    
    lStatus = [self readStatusReg];
    
    if ((lStatus & kStatusInh) == 0) {
        
        // Step 1: Wait for inhibit to become active here
        return false;
        
    }
    else if (inhibitLastCheck == 0) {

        // Step 2: Inhibit has been detected
        //
        
        // Save the last inhibit status
        inhibitLastCheck = lStatus & kStatusInh;
        
        // Keep the run stop second
        sltTime = [self readTime];
        NSLog(@"SLT %f - Inhibit detected\n", sltTime);

        sltSecondRunStop = (int) sltTime;
        
        // Call pmcLink runIsStopping in next takeData call
        callRunIsStopping = true;

        return false;
    }
    else {
        // Step 3: Clear readout buffers
        return [pmcLink doneTakingData];
    }
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    uint32_t sltsubsecreg;
    uint32_t sltsec;
    uint32_t sltsubsec2;
    
    for(id obj in dataTakers){
		[obj runTaskStopped:aDataPacket userInfo:userInfo];
    }	
	
    sltsubsecreg  = [self readReg:kKatrinV4SLTSubSecondCounterReg];
    sltsec        = [self readReg:kKatrinV4SLTSecondCounterReg];
    sltsubsec2    = (sltsubsecreg >> 11) & 0x3fff;
    NSLog(@"SLT %i.%03i - End of run\n", sltsec, sltsubsec2/10);

    // Ship run counter
    [self shipSltEvent:kSecondsCounterType withType:kStopRunType eventCt:0 high:sltSecondRunStop low:0 ];
    
    uint64_t runcount = [self readRunTime];
    [self shipSltEvent:kRunCounterType withType:kStopRunType eventCt:0 high: (runcount>>32)&0xffffffff low:(runcount)&0xffffffff ];
    
    // LShip lost event counters
    [self readLostEvents];
    [self readLostFltEvents];
    [self readLostFltEventsTr];
    NSLog(@"Lost events flt tr %i flt fifo %i slt fifo %i\n",
          lostFltEventsTr, lostFltEvents, lostEvents);

    [self shipSltEvent:kLostSltEventCounterType withType:kStopRunType eventCt:0 high: (lostEvents>>32)&0xffffffff low:(lostEvents)&0xffffffff ];

    [self shipSltEvent:kLostFltEventTrCounterType withType:kStopRunType eventCt:0 high: (lostFltEventsTr>>32)&0xffffffff low:(lostFltEventsTr)&0xffffffff ];

    [self shipSltEvent:kLostFltEventCounterType withType:kStopRunType eventCt:0 high: (lostFltEvents>>32)&0xffffffff low:(lostFltEvents)&0xffffffff ];
    
    // Delete unused structures
    [pmcLink runTaskStopped:aDataPacket userInfo:userInfo];

    
    // Start reading hitrates again - for interactive mode
    for(id obj in dataTakers){
        [obj startReadingHitRates];
    }

    
    [dataTakers release];
    dataTakers = nil;
    
    [self setIsPartOfRun: NO];

    //
    // Activate crate during the run pause for configuration
    // Release inhibit with the next second strobe
    //
    [self restoreInhibitStatus];


}

- (void) dumpSltSecondCounter:(NSString*)text
{
	uint32_t subseconds = [self readSubSecondsCounter];
	uint32_t seconds = [self readSecondsCounter];
    if(text) NSLog(@"%@::%@   %@   sec:%i  subsec:%i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),text,seconds,subseconds);//DEBUG -tb-
    else     NSLog(@"%@::%@    sec:%i  subsec:%i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),seconds,subseconds);//DEBUG -tb-
}

- (void) shipSecondCounter:(unsigned char)aType sec: (uint32_t ) seconds 
{
   // const char *sType[] = {"", "run start", "run stop", "subrun start", "subrun stop"};

    [self shipSltEvent:kSecondsCounterType withType:aType eventCt:0 high:seconds low:0 ];

}

- (void) shipSltSecondCounter:(unsigned char)aType
{
	//aType = 1 start run, =2 stop run, = 3 start subrun, =4 stop subrun, see #defines in ORKatrinV4SLTDefs.h -tb-
    const char *sType[] = {"", "run start", "run stop", "subrun start", "subrun stop"};
    
	uint32_t subseconds = [self readSubSecondsCounter];
	uint32_t seconds = [self readSecondsCounter];
    uint32_t subsec2 = (subseconds >> 11) & 0x3fff;
    NSLog(@"SLT %i.%03i - shipped second counter %s at %i\n", seconds, subsec2/10, sType[aType%5], seconds);

    
    if ((aType == kStartSubRunType) || (aType == kStopSubRunType) ){
        seconds = seconds + 1;
    }
    
    
	[self shipSltEvent:kSecondsCounterType withType:aType eventCt:0 high:seconds low:subseconds ];
}

- (void) shipSltRunCounter:(unsigned char)aType
{
		uint64_t runcount = [self readRunTime];
		[self shipSltEvent:kRunCounterType withType:aType eventCt:0 high: (runcount>>32)&0xffffffff low:(runcount)&0xffffffff ];
}

- (void) shipSltEvent:(unsigned char)aCounterType withType:(unsigned char)aType eventCt:(uint32_t)c high:(uint32_t)h low:(uint32_t)l
{
	uint32_t location = (uint32_t)((([self crateNumber]&0xf)<<21) | ([self stationNumber]& 0x0000001f)<<16);
	uint32_t data[5];
			data[0] = eventDataId | 5; 
			data[1] = location | ((aCounterType & 0xf)<<4) | (aType & 0xf);
			data[2] = c;	
			data[3] = h;	
			data[4] = l;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(int32_t)*(5)]];
}

- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [readOutGroup saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setReadOutGroup:[[[ORReadOutList alloc] initWithIdentifier:@"cPCI"]autorelease]];
    [readOutGroup loadUsingFile:aFile];
}

- (void) autoCalibrate
{
	NSArray* allFLTs = [[self crate] orcaObjects];
	NSEnumerator* e = [allFLTs objectEnumerator];
	id aCard;
	while(aCard = [e nextObject]){
		if(![aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")]){
			[aCard autoCalibrate];
		}
	}
}

- (void) tasksCompleted: (NSNotification*)aNote
{
	//nothing to do... this is to satisfy protocol
}

#pragma mark •••SBC_Linking protocol
- (NSString*) driverScriptName {return nil;} //no driver
- (NSString*) driverScriptInfo {return @"";}

- (NSString*) cpuName
{
	return [NSString stringWithFormat:@"KATRIN-DAQ-V4 SLT Card (Crate %d)",[self crateNumber]];
}

- (NSString*) sbcLockName
{
	return ORKatrinV4SLTSettingsLock;
}

- (NSString*) sbcLocalCodePath
{
	return @"Source/Objects/Hardware/IPE/KatrinV4SLT/KatrinSLTv4_Readout_Code";
}

- (NSString*) codeResourcePath
{
	return [[self sbcLocalCodePath] lastPathComponent];
}

#pragma mark •••SBC Data Structure Setup
- (void) load_HW_Config
{
	int index = 0;
	SBC_crate_config configStruct;
	configStruct.total_cards = 0;
	[self load_HW_Config_Structure:&configStruct index:index];
	[pmcLink load_HW_Config:&configStruct];
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kSLTv4;//TODO:    kKatrinV4SLT;	//should be unique 
	configStruct->card_info[index].hw_mask[0] 	= eventDataId;
	configStruct->card_info[index].hw_mask[1] 	= multiplicityId;
	configStruct->card_info[index].hw_mask[2] 	= eventFifoId;
	configStruct->card_info[index].hw_mask[3] 	= energyId;
	configStruct->card_info[index].slot			= (uint32_t)[self stationNumber];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= 0;		//not needed for this HW
    
    //"first time" flag (needed for histogram mode)
    uint32_t            runFlagsMask = 0;
    if (secondsSetSendToFLTs) runFlagsMask |= kSecondsSetSendToFLTsFlag;
    if (activateFltReadout)   runFlagsMask |= kActivateFltReadoutFlag;
	configStruct->card_info[index].deviceSpecificData[3] = runFlagsMask;
	configStruct->card_info[index].deviceSpecificData[6] = [self readReg: kKatrinV4SLTHWRevisionReg];
    
    //children
	configStruct->card_info[index].num_Trigger_Indexes = 1;
    int nextIndex = index+1;
    
	configStruct->card_info[index].next_Trigger_Index[0] = -1;
	for(id obj in dataTakers){
		if([obj respondsToSelector:@selector(load_HW_Config_Structure:index:)]){
			if(configStruct->card_info[index].next_Trigger_Index[0] == -1){
				configStruct->card_info[index].next_Trigger_Index[0] = nextIndex;
			}
			int savedIndex = nextIndex;
			nextIndex = [obj load_HW_Config_Structure:configStruct index:nextIndex];
			if(obj == [dataTakers lastObject]){
				configStruct->card_info[savedIndex].next_Card_Index = -1; //make the last object a leaf node
			}
		}
	}
	configStruct->card_info[index].next_Card_Index 	= nextIndex;	
	return index+1;
}

@end

@implementation ORKatrinV4SLTModel (private)
- (uint32_t) read:(uint32_t) address
{
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	uint32_t theData;
	[pmcLink readLongBlockPmc:&theData
					  atAddress:address
					  numToRead: 1];
	return theData;
}

- (void) write:(uint32_t) address value:(uint32_t) aValue
{
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pmcLink writeLongBlockPmc:&aValue
					  atAddress:address
					 numToWrite:1];
}
@end

