//
//  ORIpeV4SLTModel.m
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
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

//#import "ORIpeDefs.h"
#import "ORGlobal.h"
#import "ORCrate.h"
#import "ORIpeV4SLTModel.h"
//#import "ORIpeFLTModel.h"
//#import "ORIpeCrateModel.h"
#import "ORIpeV4CrateModel.h"
#import "ORIpeV4SLTDefs.h"
#import "ORKatrinV4FLTModel.h"
#import "ORReadOutList.h"
#import "unistd.h"
#import "TimedWorker.h"
#import "ORDataTypeAssigner.h"
#import "PMC_Link.h"
#import "SLTv4_HW_Definitions.h"
#import "ORPMCReadWriteCommand.h"
#import "SLTv4GeneralOperations.h"

#import "ORTaskSequence.h"
#import "ORFileMover.h"

#if 0
//IPE V4 register definitions
//MOVED TO .h FILE !!!!!!!!!!!!!!!!     <---------------- NOTE!
enum IpeV4Enum {
	kSltV4ControlReg,
	kSltV4StatusReg,
	kSltV4CommandReg,
	kSltV4InterruptReguestReg,
	kSltV4InterruptMaskReg,
	kSltV4RequestSemaphoreReg,
	kSltV4HWRevisionReg,
	kSltV4PixelBusErrorReg,
	kSltV4PixelBusEnableReg,
	kSltV4PixelBusTestReg,
	kSltV4AuxBusTestReg,
	kSltV4DebugStatusReg,
	kSltV4VetoCounterHiReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4VetoCounterLoReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4DeadTimeCounterHiReg,	//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4DeadTimeCounterLoReg,	//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
								//TODO: and dead time and veto time counter are confused, too -tb-
	kSltV4RunCounterHiReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4RunCounterLoReg,		//TODO: the LSB and MSB part of this SLT registers is confused (according to the SLT doc 2.13/2010-May) -tb-
	kSltV4SecondSetReg,
	kSltV4SecondCounterReg,
	kSltV4SubSecondCounterReg,
	kSltV4PageManagerReg,
	kSltV4TriggerTimingReg,
	kSltV4PageSelectReg,
	kSltV4NumberPagesReg,
	kSltV4PageNumbersReg,
	kSltV4EventStatusReg,
	kSltV4ReadoutCSRReg,
	kSltV4BufferSelectReg,
	kSltV4ReadoutDefinitionReg,
	kSltV4TPTimingReg,
	kSltV4TPShapeReg,
	kSltV4i2cCommandReg,
	kSltV4epcsCommandReg,
	kSltV4BoardIDLoReg,
	kSltV4BoardIDHiReg,
	kSltV4PROMsControlReg,
	kSltV4PROHiufferReg,
	kSltV4TriggerDataReg,
	kSltV4ADCDataReg,




//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
	kSltV4FIFOCsrReg,
	kSltV4FIFOxRequestReg,
	kSltV4FIFOMaskReg,


	kSltV4NumRegs //must be last
};
#endif


IpeRegisterNamesStruct regSLTV4[kSltV4NumRegs] = {
{@"Control",			0xa80000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Status",				0xa80004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Command",			0xa80008,		1,			kIpeRegWriteable },
{@"Interrupt Reguest",	0xA8000C,		1,			kIpeRegReadable },
{@"Interrupt Mask",		0xA80010,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Request Semaphore",	0xA80014,		3,			kIpeRegReadable },
{@"HWRevision",			0xa80020,		1,			kIpeRegReadable },
{@"Pixel Bus Error",	0xA80024,		1,			kIpeRegReadable },			
{@"Pixel Bus Enable",	0xA80028,		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Pixel Bus Test",		0xA8002C, 		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Aux Bus Test",		0xA80030, 		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Debug Status",		0xA80034,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Veto Counter (MSB)",	0xA80080, 		1,			kIpeRegReadable },	
{@"Veto Counter (LSB)",	0xA80084,		1,			kIpeRegReadable },	
{@"Dead Counter (MSB)",	0xA80088, 		1,			kIpeRegReadable },	
{@"Dead Counter (LSB)",	0xA8008C, 		1,			kIpeRegReadable },	
{@"Run Counter  (MSB)",	0xA80090,		1,			kIpeRegReadable },	
{@"Run Counter  (LSB)",	0xA80094, 		1,			kIpeRegReadable },	
{@"Second Set",			0xB00000,  		1, 			kIpeRegReadable | kIpeRegWriteable }, 
{@"Second Counter",		0xB00004, 		1,			kIpeRegReadable },
{@"Sub-second Counter",	0xB00008, 		1,			kIpeRegReadable }, 
{@"Page Manager",		0xB80000,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Trigger Timing",		0xB80004,  		1, 			kIpeRegReadable | kIpeRegWriteable },
{@"Page Select",		0xB80008, 		1,			kIpeRegReadable },
{@"Number of Pages",	0xB8000C, 		1,			kIpeRegReadable },
{@"Page Numbers",		0xB81000,		64, 		kIpeRegReadable | kIpeRegWriteable },
{@"Event Status",		0xB82000,		64,			kIpeRegReadable },
{@"Readout CSR",		0xC00000,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Buffer Select",		0xC00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Readout Definition",	0xC10000,	  2048,			kIpeRegReadable | kIpeRegWriteable },			
{@"TP Timing",			0xC80000,	   128,			kIpeRegReadable | kIpeRegWriteable },	
{@"TP Shape",			0xC81000,	   512,			kIpeRegReadable | kIpeRegWriteable },	
{@"I2C Command",		0xD00000,		1,			kIpeRegReadable },
{@"EPC Command",		0xD00004,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"Board ID (LSB)",		0xD00008,		1,			kIpeRegReadable },
{@"Board ID (MSB)",		0xD0000C,		1,			kIpeRegReadable },
{@"PROMs Control",		0xD00010,		1,			kIpeRegReadable | kIpeRegWriteable },
{@"PROMs Buffer",		0xD00100,		256,		kIpeRegReadable | kIpeRegWriteable },
{@"Trigger Data",		0xD80000,	  14000,		kIpeRegReadable | kIpeRegWriteable },
{@"ADC Data",			0xE00000,	 0x8000,		kIpeRegReadable | kIpeRegWriteable },
//{@"Data Block RW",		0xF00000 Data Block RW
//{@"Data Block Length",	0xF00004 Data Block Length 
//{@"Data Block Address",	0xF00008 Data Block Address



//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
//TODO: WARNING - ONLY FOR 2013-KATRIN-SLT-FIRMWARE -tb-
{@"FIFO Csr",		    0xE00010,	    1,	    	kIpeRegReadable | kIpeRegWriteable },
{@"FIFOx Request",		0xE00014,	    1,	    	kIpeRegReadable | kIpeRegWriteable },
{@"FIFO Mask",		    0xE00018,	    1,	    	kIpeRegReadable | kIpeRegWriteable },




};

#pragma mark ***External Strings

NSString* ORIpeV4SLTModelSecondsSetSendToFLTsChanged = @"ORIpeV4SLTModelSecondsSetSendToFLTsChanged";
NSString* ORIpeV4SLTModelSecondsSetInitWithHostChanged = @"ORIpeV4SLTModelSecondsSetInitWithHostChanged";
NSString* ORIpeV4SLTModelSltScriptArgumentsChanged = @"ORIpeV4SLTModelSltScriptArgumentsChanged";
NSString* ORIpeV4SLTModelCountersEnabledChanged = @"ORIpeV4SLTModelCorntersEnabledChanged";
NSString* ORIpeV4SLTModelClockTimeChanged = @"ORIpeV4SLTModelClockTimeChanged";
NSString* ORIpeV4SLTModelRunTimeChanged = @"ORIpeV4SLTModelRunTimeChanged";
NSString* ORIpeV4SLTModelVetoTimeChanged = @"ORIpeV4SLTModelVetoTimeChanged";
NSString* ORIpeV4SLTModelDeadTimeChanged = @"ORIpeV4SLTModelDeadTimeChanged";
NSString* ORIpeV4SLTModelSecondsSetChanged		= @"ORIpeV4SLTModelSecondsSetChanged";
NSString* ORIpeV4SLTModelStatusRegChanged		= @"ORIpeV4SLTModelStatusRegChanged";
NSString* ORIpeV4SLTModelControlRegChanged		= @"ORIpeV4SLTModelControlRegChanged";
NSString* ORIpeV4SLTModelFanErrorChanged		= @"ORIpeV4SLTModelFanErrorChanged";
NSString* ORIpeV4SLTModelVttErrorChanged		= @"ORIpeV4SLTModelVttErrorChanged";
NSString* ORIpeV4SLTModelGpsErrorChanged		= @"ORIpeV4SLTModelGpsErrorChanged";
NSString* ORIpeV4SLTModelClockErrorChanged		= @"ORIpeV4SLTModelClockErrorChanged";
NSString* ORIpeV4SLTModelPpsErrorChanged		= @"ORIpeV4SLTModelPpsErrorChanged";
NSString* ORIpeV4SLTModelPixelBusErrorChanged	= @"ORIpeV4SLTModelPixelBusErrorChanged";
NSString* ORIpeV4SLTModelHwVersionChanged		= @"ORIpeV4SLTModelHwVersionChanged";

NSString* ORIpeV4SLTModelPatternFilePathChanged		= @"ORIpeV4SLTModelPatternFilePathChanged";
NSString* ORIpeV4SLTModelInterruptMaskChanged		= @"ORIpeV4SLTModelInterruptMaskChanged";
NSString* ORIpeV4SLTPulserDelayChanged				= @"ORIpeV4SLTPulserDelayChanged";
NSString* ORIpeV4SLTPulserAmpChanged				= @"ORIpeV4SLTPulserAmpChanged";
NSString* ORIpeV4SLTSettingsLock					= @"ORIpeV4SLTSettingsLock";
NSString* ORIpeV4SLTStatusRegChanged				= @"ORIpeV4SLTStatusRegChanged";
NSString* ORIpeV4SLTControlRegChanged				= @"ORIpeV4SLTControlRegChanged";
NSString* ORIpeV4SLTSelectedRegIndexChanged			= @"ORIpeV4SLTSelectedRegIndexChanged";
NSString* ORIpeV4SLTWriteValueChanged				= @"ORIpeV4SLTWriteValueChanged";
NSString* ORIpeV4SLTModelNextPageDelayChanged		= @"ORIpeV4SLTModelNextPageDelayChanged";
NSString* ORIpeV4SLTModelPollRateChanged			= @"ORIpeV4SLTModelPollRateChanged";

NSString* ORIpeV4SLTModelPageSizeChanged			= @"ORIpeV4SLTModelPageSizeChanged";
NSString* ORIpeV4SLTModelDisplayTriggerChanged		= @"ORIpeV4SLTModelDisplayTrigerChanged";
NSString* ORIpeV4SLTModelDisplayEventLoopChanged	= @"ORIpeV4SLTModelDisplayEventLoopChanged";
NSString* ORSLTV4cpuLock							= @"ORSLTV4cpuLock";

@interface ORIpeV4SLTModel (private)
- (unsigned long) read:(unsigned long) address;
- (void) write:(unsigned long) address value:(unsigned long) aValue;
@end

@implementation ORIpeV4SLTModel

- (id) init
{
    self = [super init];
	ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];	
	[self setReadOutGroup:readList];
    [self makePoller:0];
	[readList release];
	pmcLink = [[PMC_Link alloc] initWithDelegate:self];
	[self setSecondsSetInitWithHost: YES];
	[self setSecondsSetSendToFLTs: YES];

	[self registerNotificationObservers];
    return self;
}

-(void) dealloc
{
    [sltScriptArguments release];
    [patternFilePath release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[readOutGroup release];
    [poller stop];
    [poller release];
	[pmcLink setDelegate:nil];
	[pmcLink release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
	[pmcLink wakeUp];
    [super wakeUp];
    if(![gOrcaGlobals runInProgress]){
        [poller runWithTarget:self selector:@selector(readAllStatus)];
    }
}

- (void) sleep
{
    [super sleep];
	[pmcLink sleep];
    [poller stop];
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

- (void) setUpImage			{ [self setImage:[NSImage imageNamed:@"IpeV4SLTCard"]]; }
- (void) makeMainController	{ [self linkToController:@"ORIpeV4SLTController"];		}
- (Class) guardianClass		{ return NSClassFromString(@"ORIpeV4CrateModel");		}

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
                     selector : @selector(runIsAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(runStarted:)
                         name : ORRunStartedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(runIsStopped:)
                         name : ORRunStoppedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runIsBetweenSubRuns:)
                         name : ORRunBetweenSubRunsNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runIsStartingSubRun:)
                         name : ORRunStartSubRunNotification
                       object : nil];

   //TODO: testing the sequence of notifications -tb- 2013-05-15
   [notifyCenter addObserver : self
                    selector : @selector(runIsAboutToChangeState:)
                        name : ORRunAboutToChangeState
                      object : nil];



//-tb- test -> is sent whenever a card in the crate object was added
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
    

}


- (void) viewChanged:(NSNotification*)aNotification
{
	//NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    //[super viewChanged: aNotification];
}

#pragma mark •••Accessors

- (bool) secondsSetSendToFLTs
{
    return secondsSetSendToFLTs;
}

- (void) setSecondsSetSendToFLTs:(bool)aSecondsSetSendToFLTs
{
    if(secondsSetSendToFLTs == aSecondsSetSendToFLTs) return;

    [[[self undoManager] prepareWithInvocationTarget:self] setSecondsSetSendToFLTs:secondsSetSendToFLTs];
    
    secondsSetSendToFLTs = aSecondsSetSendToFLTs;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelSecondsSetSendToFLTsChanged object:self];
	
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelSecondsSetInitWithHostChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelSltScriptArgumentsChanged object:self];
	
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelCountersEnabledChanged object:self];
}

- (unsigned long) clockTime
{
    return clockTime;
}

- (void) setClockTime:(unsigned long)aClockTime
{
    clockTime = aClockTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelClockTimeChanged object:self];
}

- (unsigned long long) runTime
{
    return runTime;
}

- (void) setRunTime:(unsigned long long)aRunTime
{
    runTime = aRunTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelRunTimeChanged object:self];
}

- (unsigned long long) vetoTime
{
    return vetoTime;
}

- (void) setVetoTime:(unsigned long long)aVetoTime
{
    vetoTime = aVetoTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelVetoTimeChanged object:self];
}

- (unsigned long long) deadTime
{
    return deadTime;
}

- (void) setDeadTime:(unsigned long long)aDeadTime
{
    deadTime = aDeadTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelDeadTimeChanged object:self];
}


- (unsigned long) secondsSet
{
    return secondsSet;
}

- (void) setSecondsSet:(unsigned long)aSecondsSet
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSecondsSet:secondsSet];
    secondsSet = aSecondsSet;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelSecondsSetChanged object:self];
}

- (unsigned long) statusReg
{
    return statusReg;
}

- (void) setStatusReg:(unsigned long)aStatusReg
{
    statusReg = aStatusReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelStatusRegChanged object:self];
}

- (unsigned long) controlReg
{
    return controlReg;
}

- (void) setControlReg:(unsigned long)aControlReg
{
    [[[self undoManager] prepareWithInvocationTarget:self] setControlReg:controlReg];
    controlReg = aControlReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelControlRegChanged object:self];
}

- (unsigned long) projectVersion  { return (hwVersion & kRevisionProject)>>28;}
- (unsigned long) documentVersion { return (hwVersion & kDocRevision)>>16;}
- (unsigned long) implementation  { return hwVersion & kImplemention;}

- (void) setHwVersion:(unsigned long) aVersion
{
	hwVersion = aVersion;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelHwVersionChanged object:self];	
}

- (void) writePageSelect:(unsigned long)aPageNum		{ [self writeReg:kSltV4PageSelectReg value:aPageNum]; }
- (void) writeSetInhibit		{ [self writeReg:kSltV4CommandReg value:kCmdSetInh]; }
- (void) writeClrInhibit		{ [self writeReg:kSltV4CommandReg value:kCmdClrInh]; }
- (void) writeTpStart			{ [self writeReg:kSltV4CommandReg value:kCmdTpStart];   }
- (void) writeFwCfg				{ [self writeReg:kSltV4CommandReg value:kCmdFwCfg];   }
- (void) writeSltReset			{ [self writeReg:kSltV4CommandReg value:kCmdSltReset];   }
- (void) writeFltReset			{ [self writeReg:kSltV4CommandReg value:kCmdFltReset];   }
- (void) writeSwRq				{ [self writeReg:kSltV4CommandReg value:kCmdSwRq];   }
- (void) writeClrCnt			{ [self writeReg:kSltV4CommandReg value:kCmdClrCnt];   }
- (void) writeEnCnt				{ [self writeReg:kSltV4CommandReg value:kCmdEnCnt];   }
- (void) writeDisCnt			{ [self writeReg:kSltV4CommandReg value:kCmdDisCnt];   }
- (void) writeReleasePage		{ [self writeReg:kSltV4PageManagerReg value:kPageMngRelease];   }
- (void) writePageManagerReset	{ [self writeReg:kSltV4PageManagerReg value:kPageMngReset];   }
- (void) clearAllStatusErrorBits{ [self writeReg:kSltV4StatusReg value:kStatusClearAllMask];   }


- (id) controllerCard		{ return self;	  }
- (SBC_Link*)sbcLink		{ return pmcLink; } 
- (bool)sbcIsConnected      { return [pmcLink isConnected]; }
- (TimedWorker *) poller	{ return poller;  }

- (void) setPoller: (TimedWorker *) aPoller
{
    if(aPoller == nil){
        [poller stop];
    }
    [aPoller retain];
    [poller release];
    poller = aPoller;
}

- (void) setPollingInterval:(float)anInterval
{
	[self readAllStatus];
    if(!poller){
        [self makePoller:(float)anInterval];
    }
    else [poller setTimeInterval:anInterval];
    
	[poller stop];
    [poller runWithTarget:self selector:@selector(readAllStatus)];
}


- (void) makePoller:(float)anInterval
{
    [self setPoller:[TimedWorker TimeWorkerWithInterval:anInterval]];
}



//#define SHOW_RUN_NOTIFICATIONS_AND_CALLS 1
- (void) runIsAboutToStart:(NSNotification*)aNote
{
    #if SHOW_RUN_NOTIFICATIONS_AND_CALLS
        //DEBUG
                 NSLog(@"%@::%@  <-----------------N\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    #endif
	//TODO: reset of timers probably should be done here -tb-2011-01
	#if 0 
		NSLog(@"%@::%@  called!  <---N\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug -tb-
	#endif
}

- (void) runStarted:(NSNotification*)aNote
{
    #if SHOW_RUN_NOTIFICATIONS_AND_CALLS
        //DEBUG
                 NSLog(@"%@::%@  <-----------------N\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    #endif
	#if 0
		NSLog(@"%@::%@  called!  <----N\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug -tb-
	#endif
}

- (void) runIsStopped:(NSNotification*)aNote
{	
    #if SHOW_RUN_NOTIFICATIONS_AND_CALLS
        //DEBUG
                 NSLog(@"%@::%@  <-----------------N\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    #endif
	//NSLog(@"%@::%@  [readOutGroup count] is %i!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[readOutGroup count]);//TODO: debug -tb-

	//writing the SLT time counters is done in runTaskStopped:userInfo:   -tb-
	//see SBC_Link.m, runIsStopping:userInfo:: if(runInfo.amountInBuffer > 0)... this is data sent out during 'Stop()...' of readout code, e.g.
	//the histogram (2060 int32_t's per histogram and one extra word) -tb-

	// Stop all activities by software inhibit
	//if([readOutGroup count] == 0){//TODO: I don't understand this - remove it? -tb-
	//	[self writeSetInhibit];
	//}
	
}

- (void) runIsBetweenSubRuns:(NSNotification*)aNote
{
    #if SHOW_RUN_NOTIFICATIONS_AND_CALLS
        //DEBUG
                 NSLog(@"%@::%@  <-----------------N\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    #endif
	//NSLog(@"%@::%@  called!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: debug -tb-
	[self shipSltSecondCounter: kStopSubRunType];
	[self shipSltRunCounter: kStopSubRunType];
	//TODO: I could set inhibit to measure the 'netto' run time precisely -tb-
}


- (void) runIsStartingSubRun:(NSNotification*)aNote
{
    #if SHOW_RUN_NOTIFICATIONS_AND_CALLS
        //DEBUG
                 NSLog(@"%@::%@  <-----------------N\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    #endif
	//NSLog(@"%@::%@  called!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	[self shipSltSecondCounter: kStartSubRunType];
	[self shipSltRunCounter: kStartSubRunType];
}


- (void) runIsAboutToChangeState:(NSNotification*)aNote
{
    #if SHOW_RUN_NOTIFICATIONS_AND_CALLS
        //DEBUG
                 NSLog(@"%@::%@ Called runIsAboutToChangeState --- SLT <-------------------------N\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    #endif
                 
    //int state = [[[aNote userInfo] objectForKey:@"State"] intValue];
    
    //NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    //NSLog(@"Called %@::%@   aNote:>>>%@<<<\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aNote);//DEBUG -tb-
	//aNote: >>>NSConcreteNotification 0x5a552d0 {name = ORRunAboutToChangeState; object = (ORRunModel,1) Decoders: ORRunDecoderForRun
    // Connectors: "Run Control Connector"  ; userInfo = {State = 4;}}<<<
	// states: 2,3,4: 2=starting, 3=stopping, 4=between subruns (0 = eRunStopped, 1 = eRunInProgress); see ORGlobal.h, enum 'eRunState'

    #if SHOW_RUN_NOTIFICATIONS_AND_CALLS
	/**/
	id rc =  [aNote object];
    NSLog(@"%@::%@ Calling object %@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),NSStringFromClass([rc class]));//DEBUG -tb-
	switch (state) {
		case eRunStarting://=2
            NSLog(@"   Notification: go to  %@\n",@"eRunStarting");//DEBUG -tb-
			break;
		case eRunBetweenSubRuns://=4
            NSLog(@"   Notification: go to  %@\n",@"eRunBetweenSubRuns");//DEBUG -tb-
			break;
		case eRunStopping://=3
            NSLog(@"   Notification: go to  %@\n",@"eRunStopping");//DEBUG -tb-
			break;
		default:
			break;
	}
	/**/
    #endif

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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelPatternFilePathChanged object:self];
}

- (unsigned long) nextPageDelay
{
	return nextPageDelay;
}

- (void) setNextPageDelay:(unsigned long)aDelay
{	
	if(aDelay>102400) aDelay = 102400;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setNextPageDelay:nextPageDelay];
    
    nextPageDelay = aDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelNextPageDelayChanged object:self];
	
}

- (unsigned long) interruptMask
{
    return interruptMask;
}

- (void) setInterruptMask:(unsigned long)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    interruptMask = aInterruptMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelInterruptMaskChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTPulserDelayChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTPulserAmpChanged object:self];
}

- (short) getNumberRegisters			
{ 
    return kSltV4NumRegs; 
}

- (NSString*) getRegisterName: (short) anIndex
{
    return regSLTV4[anIndex].regName;
}

- (unsigned long) getAddress: (short) anIndex
{
    return( regSLTV4[anIndex].addressOffset>>2);
}

- (short) getAccessType: (short) anIndex
{
	return regSLTV4[anIndex].accessType;
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
	 postNotificationName:ORIpeV4SLTSelectedRegIndexChanged
	 object:self];
}

- (unsigned long) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    
    writeValue = aValue;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeV4SLTWriteValueChanged
	 object:self];
}


- (BOOL) displayTrigger
{
	return displayTrigger;
}

- (void) setDisplayTrigger:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayTrigger:displayTrigger];
	displayTrigger = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelDisplayTriggerChanged object:self];
	
}

- (BOOL) displayEventLoop
{
	return displayEventLoop;
}

- (void) setDisplayEventLoop:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayEventLoop:displayEventLoop];
	
	displayEventLoop = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelDisplayEventLoopChanged object:self];
	
}

- (unsigned long) pageSize
{
	return pageSize;
}

- (void) setPageSize: (unsigned long) aPageSize
{
	
	[[[self undoManager] prepareWithInvocationTarget:self] setPageSize:pageSize];
	
    if (aPageSize > 100) pageSize = 100;
	else pageSize = aPageSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeV4SLTModelPageSizeChanged object:self];
	
}  

/*! Send a script to the PrPMC which will configure the PrPMC.
 *
 */
- (void) sendSimulationConfigScriptON
{
	NSLog(@"%@::%@: invoked.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	//example code to send a script:  SBC_Link.m: - (void) installDriver:(NSString*)rootPwd 
	
	//[self sendPMCCommandScript: @"SimulationConfigScriptON"];
	[self sendPMCCommandScript: [NSString stringWithFormat:@"%@ %i",@"SimulationConfigScriptON",[pmcLink portNumber]]];//send the port number, too

	#if 0
	NSString *scriptName = @"IpeV4SLTScript";
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
		
		//NSString* scriptRunPath = [NSString stringWithFormat:@"/home/%@/%@",[pmcLink userName],scriptName];
		NSString* scriptRunPath = [NSString stringWithFormat:@"~/%@",scriptName];
NSLog(@"  scriptRunPath: %@ \n" , scriptRunPath);		
		[aSequence addTask:[resourcePath stringByAppendingPathComponent:@"loginScript"] 
				 arguments:[NSArray arrayWithObjects:[pmcLink userName],[pmcLink passWord],[pmcLink IPNumber],scriptRunPath,
				 //@"arg1",@"arg2",nil]];
				 //@"shellcommand",@"ls",@"&&",@"date",@"&&",@"ps",nil]];
				 //@"shellcommand",@"ls",@"-laF",nil]];
				 @"shellcommand",@"ls",@"-l",@"-a",@"-F",nil]];  //limited to 6 arguments (see loginScript)
				 //TODO: use sltScriptArguments -tb-
		
		[aSequence launch];
		#endif

}

/*! Send a script to the PrPMC which will configure the PrPMC.
 */
- (void) sendSimulationConfigScriptOFF
{
	//NSLog(@"%@::%@: invoked.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	//example code to send a script:  SBC_Link.m: - (void) installDriver:(NSString*)rootPwd 
	
	[self sendPMCCommandScript: @"SimulationConfigScriptOFF"];
}

- (void) sendLinkWithDmaLibConfigScriptON
{
	NSLog(@"%@::%@: invoked.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));
	//example code to send a script:  SBC_Link.m: - (void) installDriver:(NSString*)rootPwd 
	
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
	
	NSString *scriptName = @"IpeV4SLTScript";
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
		unsigned long time[256];
		unsigned long mask[20][256];
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
			ORIpeFLTModel* cards[20];//TODO: ORIpeV4SLTModel -tb-
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
					if(mask[j][i] != 0x1000000)[line appendFormat:@"%3s",mask[j][i]?"•":"-"];
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

- (void) writeReg:(int)index value:(unsigned long)aValue
{
	[self write: [self getAddress:index] value:aValue];
}

- (void)		  rawWriteReg:(unsigned long) address  value:(unsigned long)aValue
//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
{
    [self write: address value: aValue];
}

- (unsigned long) rawReadReg:(unsigned long) address
//TODO: FOR TESTING AND DEBUGGING ONLY -tb-
{
	return [self read: address];

}

- (unsigned long) readReg:(int) index
{
	return [self read: [self getAddress:index]];

}

- (id) writeHardwareRegisterCmd:(unsigned long) regAddress value:(unsigned long) aValue
{
	return [ORPMCReadWriteCommand writeLongBlock:&aValue
									   atAddress:regAddress
									  numToWrite:1];
}

- (id) readHardwareRegisterCmd:(unsigned long) regAddress
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
	//[self readControlReg];
	[self readPageSelectReg];
	[self readStatusReg];
	//[self readReadOutControlReg];
	[self readDeadTime];
	[self readVetoTime];
	[self readRunTime];
	[self getSeconds];
}

- (unsigned long) readPageSelectReg
{
	unsigned long data = [self readReg:kSltV4PageSelectReg];
	return data;
}

- (unsigned long) readStatusReg
{
	unsigned long data = [self readReg:kSltV4StatusReg];
	[self setStatusReg:data];
	return data;
}

- (void) printStatusReg
{
	unsigned long data = [self readStatusReg];
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

- (long) getSBCCodeVersion
{
	long theVersion = 0;
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

- (long) getFdhwlibVersion
{
	long theVersion = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetFdhwLibVersion numToRead:1];
	}
	return theVersion;
}

- (long) getSltPciDriverVersion
{
	long theVersion = 0;
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	else {
		[pmcLink readGeneral:&theVersion operation:kGetSltPciDriverVersion numToRead:1];
	}
	return theVersion;
}

- (long) getSltkGetIsLinkedWithPCIDMALib  //TODO: write a all purpose method for generalRead!!! -tb-
{
	long theVersion = 0;
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
		[pmcLink writeGeneral:(long*)&args operation:kSetHostTimeToFLTsAndSLT numToWrite:2];
		//[pmcLink writeGeneral:&args operation:kSetHostTimeToFLTsAndSLT numToWrite:2];
            //WARNING:
            //this produced a compiler warning; I did NOT remove it to not forget that we expect uint32_t on the SBCs
            //in Orca, sizeof(long) is 4 byte; SBCs may be 64 bit machines -> sizeof(long) is 8 byte!  -tb- 2012-12
	}
}


- (void) readEventStatus:(unsigned long*)eventStatusBuffer
{
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pmcLink readLongBlockPmc:eventStatusBuffer
					 atAddress:regSLTV4[kSltV4EventStatusReg].addressOffset
					 numToRead: 3];
	
}

- (unsigned long long) readBoardID
{
	unsigned long low = [self readReg:kSltV4BoardIDLoReg];
	unsigned long hi  = [self readReg:kSltV4BoardIDHiReg];
	BOOL crc =(hi & 0x80000000)==0x80000000;
	if(crc){
		return (unsigned long long)(hi & 0xffff)<<32 | low;
	}
	else return 0;
}

- (unsigned long) readControlReg
{
	return [self readReg:kSltV4ControlReg];
}

- (void) printControlReg
{
	unsigned long data = [self readControlReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Control Register %@ ----\n",[self fullID]);
	NSLogFont(aFont,@"Trigger Enable : 0x%02x\n",data & kCtrlTrgEnMask);
	NSLogFont(aFont,@"Inibit Enable  : 0x%02x\n",(data & kCtrlInhEnMask) >> 6);
	NSLogFont(aFont,@"PPS            : %@\n",IsBitSet(data,kCtrlPPSMask)?@"GPS":@"Internal");
	NSLogFont(aFont,@"TP Enable      : 0x%02x\n", ExtractValue(data,kCtrlTpEnMask,11));
	NSLogFont(aFont,@"TP Shape       : %d\n", IsBitSet(data,kCtrlShapeMask));
	NSLogFont(aFont,@"Run Mode       : %@\n", IsBitSet(data,kCtrlRunMask)?@"Normal":@"Test");
	NSLogFont(aFont,@"Test SLT       : %@\n", IsBitSet(data,kCtrlTstSltMask)?@"Enabled":@"Disabled");
	NSLogFont(aFont,@"IntA Enable    : %@\n", IsBitSet(data,kCtrlIntEnMask)?@"Enabled":@"Disabled");
}


- (void) writeControlReg
{
	[self writeReg:kSltV4ControlReg value:controlReg];
}

- (void) loadSecondsReg
{
    
    [self setHostTimeToFLTsAndSLT];
return;
    uint32_t i,sltsec,sltsubsec,sltsubsec2,sltsubsec1,sltsubsecreg;

    //everything else moved to void setHostTimeToFLTsAndSLT(int32_t* args) on SBC called by [self setHostTimeToFLTsAndSLT]; ...
    //wait until we are not at the end of a second (<0.9 sec)
	for(i=0;i<1000;i++){
	    sltsubsecreg  = [self readReg:kSltV4SubSecondCounterReg];//first read subsec counter!
	    sltsec        = [self readReg:kSltV4SecondCounterReg];
        sltsubsec1 = sltsubsecreg & 0x7ff  ;
        sltsubsec2 = (sltsubsecreg >> 11) & 0x3fff  ; //100 usec counter
        sltsubsec = sltsubsec2 * 2000 + sltsubsec1;
	    NSLog(@"%@::%@!   sec %u, sltsubsec2 %u, sltsubsec1 %u, subsec %u\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd), sltsec, sltsubsec2, sltsubsec1, sltsubsec);//TODO: DEBUG -tb-
        if(sltsubsec<18000000) break; //full second is 20000000 clocks
        usleep(1000);//this loop needs 3-8 milli seconds (with usleep(1000) and two register reads)
    }

    // add option to set system time of PrPMC/crate computer? -tb- DONE.
	unsigned long secSetpoint = secondsSet;
	if(secondsSetInitWithHost){ 
		struct timeval t;//    call with struct timezone tz; is obsolete ... -tb-
		gettimeofday(&t,NULL);
		secSetpoint = t.tv_sec;  
	}
	
	if(secondsSetSendToFLTs){
        #if 1 //TODO: broadcast to FLTs seems to nor work currently FIX IT -tb-
	    uint32_t FLTV4SecondCounterRegAddr = (0x1f << 17) | (0x000044>>2);
	    [self write: FLTV4SecondCounterRegAddr  value:secSetpoint];//(0x1f << 17) is broadcast to all FLTs -tb-
        #else
        int j;
        for(j=1;j<21;j++){
	        uint32_t FLTV4SecondCounterRegAddr = ( j << 17) | (0x000044>>2);
	        [self write: FLTV4SecondCounterRegAddr  value:secSetpoint];//(0x1f << 17) is broadcast to all FLTs -tb-
        }
        #endif
    }
	
	secSetpoint += 1;  //value will be taken after the NEXT second strobe, so we need the NEXT second
	[self writeReg:kSltV4SecondSetReg value:secSetpoint];
    
    //read back and check value:
    //Wait until next second srobe!
    for(i=0;i<10000;i++){// when the time already was set, this will leave the loop immediately
        usleep(100);
	    sltsubsecreg  = [self readReg:kSltV4SubSecondCounterReg];//first read subsec counter!
	    sltsec        = [self readReg:kSltV4SecondCounterReg];
        if(sltsec==secSetpoint) break;
    }
    if(i==10000) NSLog(@"ORIpeV4SLTModel::loadSecondsReg: ERROR: could not read back SLT time %i (is %i)!\n",secSetpoint,sltsec);
    //NSLog(@"ORIpeV4SLTModel::loadSecondsReg:  setpoint SLT time %i (is %i) loops %i!\n",secSetpoint,sltsec,i);
}

- (void) writeInterruptMask
{
	[self writeReg:kSltV4InterruptMaskReg value:interruptMask];
}

- (void) readInterruptMask
{
	[self setInterruptMask:[self readReg:kSltV4InterruptMaskReg]];
}

- (void) readInterruptRequest
{
	[self setInterruptMask:[self readReg:kSltV4InterruptReguestReg]];
}

- (void) printInterruptRequests
{
	[self printInterrupt:kSltV4InterruptReguestReg];
}

- (void) printInterruptMask
{
	[self printInterrupt:kSltV4InterruptMaskReg];
}

- (void) printInterrupt:(int)regIndex
{
	unsigned long data = [self readReg:regIndex];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	if(!data)NSLogFont(aFont,@"Interrupt Mask is Clear (No interrupts %@)\n",regIndex==kSltV4InterruptReguestReg?@"Requested":@"Enabled");
	else {
		NSLogFont(aFont,@"The following interrupts are %@:\n",regIndex==kSltV4InterruptReguestReg?@"Requested":@"Enabled");
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

- (unsigned long) readHwVersion
{
	unsigned long value=0;
	@try {
        value = [self readReg: kSltV4HWRevisionReg];
		[self setHwVersion: value];	
	}
	@catch (NSException* e){
	}
	return value;
}

- (unsigned long long) readDeadTime
{
	unsigned long low  = [self readReg:kSltV4DeadTimeCounterLoReg];
	unsigned long high = [self readReg:kSltV4DeadTimeCounterHiReg];
	[self setDeadTime:((unsigned long long)high << 32) | low];
	return deadTime;
}

- (unsigned long long) readVetoTime
{
	unsigned long low  = [self readReg:kSltV4VetoCounterLoReg];
	unsigned long high = [self readReg:kSltV4VetoCounterHiReg];
	[self setVetoTime:((unsigned long long)high << 32) | low];
	return vetoTime;
}

- (unsigned long long) readRunTime
{
	unsigned long long low  = [self readReg:kSltV4RunCounterLoReg];
	unsigned long long high = [self readReg:kSltV4RunCounterHiReg];
	unsigned long long theTime = ((unsigned long long)high << 32) | low;
	//NSLog(@"runtime lo %llx high %llx   ---   time %llx  %llu\n",low,high, theTime, theTime);
	[self setRunTime:theTime];
	return theTime;
}

- (unsigned long) readSecondsCounter
{
	return [self readReg:kSltV4SecondCounterReg];
}

- (unsigned long) readSubSecondsCounter
{
	return [self readReg:kSltV4SubSecondCounterReg];
}

- (unsigned long) getSeconds
{
	[self readSubSecondsCounter]; //must read the sub seconds to load the seconds register
	[self setClockTime: [self readSecondsCounter]];
	return clockTime;
}

- (void) initBoard
{
	if(countersEnabled)[self writeEnCnt];
	else [self writeDisCnt];
	if(countersEnabled  && !(controlReg & (0x1 << kCtrlInhEnShift))  ){
		NSLog(@"WARNING: IPE-DAQ SLTv4: you use 'Counters Enabled' but 'Inhibits Enabled SW' is not set!\n");//TODO: maybe popup Orca Alarm window? -tb-
	}
	[self loadSecondsReg];
	[self writeControlReg];
	[self writeInterruptMask];
	[self clearAllStatusErrorBits];
    
    
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
	//unsigned long long p1 = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	//[self writeReg:kSltSwRelInhibit value:0];
	//int i = 0;
	//unsigned long lTmp;
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
	unsigned long long p2  = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	if(p1 == p2) NSLog (@"No software trigger\n");
	[self writeReg:kSltSwSetInhibit value:0];
 */
//	triggerSource = savedTriggerSource;
	//inhibitSource = savedInhibitSource;
	//-----------------------------------------------
	
	[self printStatusReg];
	[self printControlReg];
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

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self setSltScriptArguments:[decoder decodeObjectForKey:@"sltScriptArguments"]];
	pmcLink = [[decoder decodeObjectForKey:@"PMC_Link"] retain];
	if(!pmcLink)pmcLink = [[PMC_Link alloc] initWithDelegate:self];
	else [pmcLink setDelegate:self];

	[self setControlReg:		[decoder decodeInt32ForKey:@"controlReg"]];
	[self setSecondsSet:		[decoder decodeInt32ForKey:@"secondsSet"]];
	if([decoder containsValueForKey:@"secondsSetInitWithHost"])
		[self setSecondsSetInitWithHost:[decoder decodeBoolForKey:@"secondsSetInitWithHost"]];
	else[self setSecondsSetInitWithHost: YES];
	[self setSecondsSetSendToFLTs:[decoder decodeBoolForKey:@"secondsSetSendToFLTs"]];
	
	[self setCountersEnabled:	[decoder decodeBoolForKey:@"countersEnabled"]];

	//status reg
	[self setPatternFilePath:		[decoder decodeObjectForKey:@"ORIpeV4SLTModelPatternFilePath"]];
	[self setInterruptMask:			[decoder decodeInt32ForKey:@"ORIpeV4SLTModelInterruptMask"]];
	[self setPulserDelay:			[decoder decodeFloatForKey:@"ORIpeV4SLTModelPulserDelay"]];
	[self setPulserAmp:				[decoder decodeFloatForKey:@"ORIpeV4SLTModelPulserAmp"]];
		
	//special
    [self setNextPageDelay:			[decoder decodeIntForKey:@"nextPageDelay"]]; // ak, 5.10.07
	
	[self setReadOutGroup:			[decoder decodeObjectForKey:@"ReadoutGroup"]];
    [self setPoller:				[decoder decodeObjectForKey:@"poller"]];
	
    [self setPageSize:				[decoder decodeIntForKey:@"ORIpeV4SLTPageSize"]]; // ak, 9.12.07
    [self setDisplayTrigger:		[decoder decodeBoolForKey:@"ORIpeV4SLTDisplayTrigger"]];
    [self setDisplayEventLoop:		[decoder decodeBoolForKey:@"ORIpeV4SLTDisplayEventLoop"]];
    	
    if (!poller)[self makePoller:0];
	
	//needed because the readoutgroup was added when the object was already in the config and so might not be in the configuration
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
	
	[encoder encodeBool:secondsSetSendToFLTs forKey:@"secondsSetSendToFLTs"];
	[encoder encodeBool:secondsSetInitWithHost forKey:@"secondsSetInitWithHost"];
	[encoder encodeObject:sltScriptArguments forKey:@"sltScriptArguments"];
	[encoder encodeBool:countersEnabled forKey:@"countersEnabled"];
	[encoder encodeInt32:secondsSet forKey:@"secondsSet"];
	[encoder encodeObject:pmcLink		forKey:@"PMC_Link"];
	[encoder encodeInt32:controlReg	forKey:@"controlReg"];
	
	//status reg
	[encoder encodeObject:patternFilePath forKey:@"ORIpeV4SLTModelPatternFilePath"];
	[encoder encodeInt32:interruptMask	 forKey:@"ORIpeV4SLTModelInterruptMask"];
	[encoder encodeFloat:pulserDelay	 forKey:@"ORIpeV4SLTModelPulserDelay"];
	[encoder encodeFloat:pulserAmp		 forKey:@"ORIpeV4SLTModelPulserAmp"];
		
	//special
    [encoder encodeInt:nextPageDelay     forKey:@"nextPageDelay"]; // ak, 5.10.07
	
	[encoder encodeObject:readOutGroup  forKey:@"ReadoutGroup"];
    [encoder encodeObject:poller         forKey:@"poller"];
	
    [encoder encodeInt:pageSize         forKey:@"ORIpeV4SLTPageSize"]; // ak, 9.12.07
    [encoder encodeBool:displayTrigger   forKey:@"ORIpeV4SLTDisplayTrigger"];
    [encoder encodeBool:displayEventLoop forKey:@"ORIpeV4SLTDisplayEventLoop"];
		
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORIpeV4SLTDecoderForEvent",				@"decoder",
								 [NSNumber numberWithLong:eventDataId],	@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:5],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeV4SLTEvent"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORIpeV4SLTDecoderForMultiplicity",			@"decoder",
				   [NSNumber numberWithLong:multiplicityId],   @"dataId",
				   [NSNumber numberWithBool:NO],				@"variable",
				   [NSNumber numberWithLong:3+20*100],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeV4SLTMultiplicity"];
    
    return dataDictionary;
}

- (unsigned long) eventDataId        { return eventDataId; }
- (unsigned long) multiplicityId	 { return multiplicityId; }
- (void) setEventDataId: (unsigned long) aDataId    { eventDataId = aDataId; }
- (void) setMultiplicityId: (unsigned long) aDataId { multiplicityId = aDataId; }

- (void) setDataIds:(id)assigner
{
    eventDataId     = [assigner assignDataIds:kLongForm];
    multiplicityId  = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setEventDataId:[anotherCard eventDataId]];
    [self setMultiplicityId:[anotherCard multiplicityId]];
}

//this goes to the Run header ...
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    //added 2013-04-29 -tb-
	[objDictionary setObject:[NSNumber numberWithLong:controlReg]				    forKey:@"ControlReg"];
	[objDictionary setObject:[NSNumber numberWithInt:countersEnabled]				forKey:@"CountersEnabled"];
	[objDictionary setObject:[NSNumber numberWithInt:secondsSetInitWithHost]		forKey:@"SecondsSetInitWithHost"];
	if(!secondsSetInitWithHost) [objDictionary setObject:[NSNumber numberWithLong:secondsSet]				    forKey:@"SecondsInitializeTo"];
	[objDictionary setObject:[NSNumber numberWithInt:secondsSetSendToFLTs]		    forKey:@"SecondsUseForFLTs"];
    //this is accessing the hardware and might fail
	@try {
	    [objDictionary setObject:[NSNumber numberWithUnsignedLong:[self readHwVersion]]		forKey:@"FPGAVersion"];
	    [objDictionary setObject:[NSString stringWithFormat:@"0x%08lx",[self readHwVersion]]		forKey:@"FPGAVersionString"];
	    [objDictionary setObject:[NSNumber numberWithLong:[self getSBCCodeVersion]]		forKey:@"SBCCodeVersion"];
	    [objDictionary setObject:[NSNumber numberWithLong:[self getSltPciDriverVersion]]		forKey:@"SLTDriverVersion"];
	    [objDictionary setObject:[NSNumber numberWithLong:[self getSltkGetIsLinkedWithPCIDMALib]]		forKey:@"LinkedWithDMALib"];
	}
	@catch (NSException* e){
	}

	return objDictionary;
}

#pragma mark •••Data Taker

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    #if SHOW_RUN_NOTIFICATIONS_AND_CALLS
        //DEBUG
                 NSLog(@"%@::%@ Called runTaskStarted --- SLT <-------------------------\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    #endif
    
    [self setIsPartOfRun: YES];

    [self clearExceptionCount];
	
	//check that we can actually run
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Check the SLT connection"];
	}
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORIpeV4SLTModel"];    
    //----------------------------------------------------------------------------------------	
	
	pollingWasRunning = [poller isRunning];
	if(pollingWasRunning) [poller stop];
	
	[self writeSetInhibit];  //TODO: maybe move to readout loop to avoid dead time -tb-
	
        //DEBUG         [self dumpSltSecondCounter:@"vor initBoard"];
        
        
	dataTakers = [[readOutGroup allObjects] retain];		//cache of data takers.
    
    //check: are there FLTs in histogram mode?
	int runMode=0, countHistoMode=0, countNonHistoMode=0;
    //DEBUG         [self dumpSltSecondCounter:@"FLT-runTaskStarted:"];
    //loop over Readout List
	for(id obj in dataTakers){
        if([obj respondsToSelector:@selector(runMode)]){
            runMode=[obj runMode];
            if(runMode == kIpeFltV4_Histogram_DaqMode) countHistoMode++; else countNonHistoMode++;
        }
    }
    //DEBUG         NSLog(@"%@::%@  countHistoMode:%i  countNonHistoMode:%i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),countHistoMode,countNonHistoMode);//DEBUG -tb-
    //DEBUG         [self dumpSltSecondCounter:nil];
        
        
    //THIS IS A WORKAROUND FOR THE start-histo FLT BUG
    //   (start-histo FLT BUG is: the FIRST histogram already starts recording BEFORE the next second strobe/1PPS, if the 'set standby mode' command was within this second)
    //   (workaround: I set standby mode for all FLTs in histo-mode, then I will wait for the next second strobe  ---> this will produce a additional gap/delay of 1 second at beginning of run)
    // -tb- 2013-05-24
    //if there are FLTs in histogramming mode, I start them right before releasing inhibit -> now -tb-
    if(countHistoMode){
	    for(id obj in dataTakers){
            if([[obj class] isSubclassOfClass: NSClassFromString(@"ORKatrinV4FLTModel")]){//or ORIpeV4FLTModel
            //if([obj respondsToSelector:@selector(runMode)]){
                runMode=[obj runMode];
                if(runMode == kIpeFltV4_Histogram_DaqMode) [obj writeControlWithStandbyMode];// -> set the run mode
            }
        }
        usleep(1000000);
	}	
        
        
    //if cold start (not 'quick start' in RunControl) ...
    if([[userInfo objectForKey:@"doinit"]intValue]){
		[self initBoard];
        // 	initBoard does:
        //    -	enable counters (if enabled in GUI)
        //    -	load second register (may delay 1 second ...)
        //    -	write control register (e.g. enable SW inhibit, GPS clock, etc.)
        //    -	write interrupt mask (in low-level-tab) (currently unused)
        //    -	clear status error bits
        //    - print status and control reg
	}	
	

    //loop over Readout List
	for(id obj in dataTakers){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];//configure FLTs (sets run mode for non-histo-FLTs), set histogramming FLTs to standby mode etc -tb-
    }

    //if there are FLTs in non-histogramming mode, the filter will start after next 1PPs - wait for it ... -tb-
    if(countNonHistoMode && [[userInfo objectForKey:@"doinit"]intValue]){
        //wait for next second strobe/1PPs
		uint32_t i,subsec0, subsec1 = 0;
		subsec0 = [self readSubSecondsCounter];
        for(i=0; i<1000; i++){
		    subsec1 = [self readSubSecondsCounter];
            //DEBUG 
            if(i==0) NSLog(@"%@::%@ waiting for second strobe: i:%i  subsec:%i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),i,subsec1);//DEBUG -tb-
            if(subsec1<subsec0) break;
            usleep(1000);
        }				
        //DEBUG
                 NSLog(@"%@::%@ waiting for second strobe: i:%i  subsec:%i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),i,subsec1);//DEBUG -tb-
	}	
    
        //DEBUG         [self dumpSltSecondCounter:@"histoFLT-writeControl:"];
        
    //if there are FLTs in histogramming mode, I start them right before releasing inhibit -> now -tb-
    if(countHistoMode){
	    for(id obj in dataTakers){
            if([[obj class] isSubclassOfClass: NSClassFromString(@"ORKatrinV4FLTModel")]){//or ORIpeV4FLTModel
            //if([obj respondsToSelector:@selector(runMode)]){
                runMode=[obj runMode];
                if(runMode == kIpeFltV4_Histogram_DaqMode) [obj writeControl];// -> set the run mode
            }
        }
	}	

	
	if(countersEnabled)[self writeClrCnt];//If enabled run counter will be reset to 0 at run start -tb-
	
	[self readStatusReg];
	actualPageIndex = 0;
	eventCounter    = 0;
	first = YES;
	lastDisplaySec = 0;
	lastDisplayCounter = 0;
	lastDisplayRate = 0;
	lastSimSec = 0;
	
	//load all the data needed for the eCPU to do the HW read-out.
	[self load_HW_Config];
	[pmcLink runTaskStarted:aDataPacket userInfo:userInfo];//method of SBC_Link.m: init alarm handling; send kSBC_StartRun to SBC/PrPMC -tb-
	
    //next  takeData:userInfo: will be called, which will release inhibit in the first cycle -tb-
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	if(!first){
		//event readout controlled by the SLT cpu now. ORCA reads out 
		//the resulting data from a generic circular buffer in the pmc code.
		[pmcLink takeData:aDataPacket userInfo:userInfo];
	}
	else {// the first time
    #if SHOW_RUN_NOTIFICATIONS_AND_CALLS
        //DEBUG
                 NSLog(@"%@::%@   <------- \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    #endif
		//TODO: -tb- [self writePageManagerReset];
		//TODO: -tb- [self writeClrCnt];
        
        //DEBUG         [self dumpSltSecondCounter:@"SLT-takeData-vor RelInhibit:"];
        
		unsigned long long runcount = [self readRunTime];
		[self shipSltEvent:kRunCounterType withType:kStartRunType eventCt:0 high: (runcount>>32)&0xffffffff low:(runcount)&0xffffffff ];
		[self writeClrInhibit]; //TODO: maybe move to readout loop to avoid dead time -tb-

        //DEBUG         [self dumpSltSecondCounter:@"SLT-takeData-nach RelInhibit:"];

		[self shipSltSecondCounter: kStartRunType];
		first = NO;
	}
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    #if SHOW_RUN_NOTIFICATIONS_AND_CALLS
        //DEBUG NSLog(@"%@::%@   <------- \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
        //DEBUG
                 NSLog(@"%@::%@ Called runIsStopping --- SLT <-------------------------\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    #endif

    for(id obj in dataTakers){
        [obj runIsStopping:aDataPacket userInfo:userInfo];
    }
	[pmcLink runIsStopping:aDataPacket userInfo:userInfo];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    #if SHOW_RUN_NOTIFICATIONS_AND_CALLS
        //DEBUG
                 NSLog(@"%@::%@ Called runTaskStopped --- SLT <-------------------------\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    #endif


	[self writeSetInhibit]; //TODO: maybe move to readout loop to avoid dead time -tb-
	[self shipSltSecondCounter: kStopRunType];
	unsigned long long runcount = [self readRunTime];
	[self shipSltEvent:kRunCounterType withType:kStopRunType eventCt:0 high: (runcount>>32)&0xffffffff low:(runcount)&0xffffffff ];
	
    //TODO: set a run control 'wait', if we record the hitrate counter -> wait for final hitrate event (... in change state notification callback ...) -tb-
    
    
    for(id obj in dataTakers){
		[obj runTaskStopped:aDataPacket userInfo:userInfo];
    }	
	
	[pmcLink runTaskStopped:aDataPacket userInfo:userInfo];
	
	if(pollingWasRunning) {
		[poller runWithTarget:self selector:@selector(readAllStatus)];
	}
	
	[dataTakers release];
	dataTakers = nil;

    [self setIsPartOfRun: NO];

}

- (void) dumpSltSecondCounter:(NSString*)text
{
	unsigned long subseconds = [self readSubSecondsCounter];
	unsigned long seconds = [self readSecondsCounter];
    if(text)
        NSLog(@"%@::%@   %@   sec:%i  subsec:%i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),text,seconds,subseconds);//DEBUG -tb-
    else
        NSLog(@"%@::%@    sec:%i  subsec:%i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),seconds,subseconds);//DEBUG -tb-
}

/** For the V4 SLT (Auger/KATRIN)the subseconds count 100 nsec tics! (Despite the fact that the ADC sampling has a 50 nsec base.)
  */ //-tb- 
- (void) shipSltSecondCounter:(unsigned char)aType
{
	//aType = 1 start run, =2 stop run, = 3 start subrun, =4 stop subrun, see #defines in ORIpeV4SLTDefs.h -tb-
	unsigned long subseconds = [self readSubSecondsCounter];
	unsigned long seconds = [self readSecondsCounter];
	

	[self shipSltEvent:kSecondsCounterType withType:aType eventCt:0 high:seconds low:subseconds ];
	#if 0
	unsigned long location = (([self crateNumber]&0xf)<<21) | ([self stationNumber]& 0x0000001f)<<16;
	unsigned long data[5];
			data[0] = eventDataId | 5; 
			data[1] = location | (aType & 0xf);
			data[2] = 0;	
			data[3] = seconds;	
			data[4] = subseconds;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(long)*(5)]];
	#endif
}

- (void) shipSltRunCounter:(unsigned char)aType
{
		unsigned long long runcount = [self readRunTime];
		[self shipSltEvent:kRunCounterType withType:aType eventCt:0 high: (runcount>>32)&0xffffffff low:(runcount)&0xffffffff ];
}

- (void) shipSltEvent:(unsigned char)aCounterType withType:(unsigned char)aType eventCt:(unsigned long)c high:(unsigned long)h low:(unsigned long)l
{
	unsigned long location = (([self crateNumber]&0xf)<<21) | ([self stationNumber]& 0x0000001f)<<16;
	unsigned long data[5];
			data[0] = eventDataId | 5; 
			data[1] = location | ((aCounterType & 0xf)<<4) | (aType & 0xf);
			data[2] = c;	
			data[3] = h;	
			data[4] = l;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(long)*(5)]];
}


- (BOOL) doneTakingData
{
	return [pmcLink doneTakingData];
}

- (unsigned long) calcProjection:(unsigned long *)pMult  xyProj:(unsigned long *)xyProj  tyProj:(unsigned long *)tyProj
{ 
	//temp----
	int i, j, k;
	int sltSize = pageSize * 20;	
	
	
	// Dislay the matrix of triggered pixel and timing
	// The xy-Projection is needed to readout only the triggered pixel!!!
	//unsigned long xyProj[20];
	//unsigned long tyProj[100];
	for (i=0;i<20;i++) xyProj[i] = 0;
	for (k=0;k<100;k++) tyProj[k] = 0;
	for (k=0;k<sltSize;k++){
		xyProj[k%20] = xyProj[k%20] | (pMult[k] & 0x3fffff);
	}  
	for (k=0;k<sltSize;k++){
		if (xyProj[k%20]) {
			tyProj[k/20] = tyProj[k/20] | (pMult[k] & 0x3fffff);
		}
	}
	
	int nTriggered = 0;
	for (i=0;i<20;i++){
		for(j=0;j<22;j++){
			if (((xyProj[i]>>j) & 0x1 ) == 0x1) nTriggered++;
		}
	}
	
	
	// Display trigger data
	if (displayTrigger) {	
		int i, j, k;
		NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
		
		for(j=0;j<22;j++){
			NSMutableString* s = [NSMutableString stringWithFormat:@"%2d: ",j];
			//matrix of triggered pixel
			for(i=0;i<20;i++){
				if (((xyProj[i]>>j) & 0x1) == 0x1) [s appendFormat:@"X"];
				else							   [s appendFormat:@"."];
			}
			[s appendFormat:@"  "];
			
			// trigger timing
			for (k=0;k<pageSize;k++){
				if (((tyProj[k]>>j) & 0x1) == 0x1 )[s appendFormat:@"="];
				else							   [s appendFormat:@"."];
			}
			NSLogFont(aFont, @"%@\n", s);
		}
		
		NSLogFont(aFont,@"\n");	
	}		
	return(nTriggered);
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
/*
- (void) dumpTriggerRAM:(int)aPageIndex
{
	
	//read page start address
	unsigned long lTimeL     = [self read: SLT_REG_ADDRESS(kSltLastTriggerTimeStamp) + aPageIndex];
	int iPageStart = (((lTimeL >> 10) & 0x7fe)  + 20) % 2000;
	
	unsigned long timeStampH = [self read: SLT_REG_ADDRESS(kSltPageTimeStamp) + 2*aPageIndex];
	unsigned long timeStampL = [self read: SLT_REG_ADDRESS(kSltPageTimeStamp) + 2*aPageIndex+1];
	
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
	NSLogFont(aFont,@"Reading event from page %d, start=%d:  %ds %dx100us\n", 
			  aPageIndex+1, iPageStart, timeStampH, (timeStampL >> 11) & 0x3fff);
	
	//readout the SLT pixel trigger data
	unsigned long buffer[2000];
	unsigned long sltMemoryAddress = (SLTID << 24) | aPageIndex<<11;
	[self readBlock:sltMemoryAddress dataBuffer:(unsigned long*)buffer length:20*100 increment:1];
	unsigned long reorderBuffer[2000];
	// Re-organize trigger data to get it in a continous data stream
	unsigned long *pMult = reorderBuffer;
	memcpy( pMult, buffer + iPageStart, (2000 - iPageStart)*sizeof(unsigned long));  
	memcpy( pMult + 2000 - iPageStart, buffer, iPageStart*sizeof(unsigned long));  
	
	int i;
	int j;	
	int k;	
	
	// Dislay the matrix of triggered pixel and timing
	// The xy-Projection is needed to readout only the triggered pixel!!!
	unsigned long xyProj[20];
	unsigned long tyProj[100];
	for (i=0;i<20;i++) xyProj[i] = 0;
	for (k=0;k<100;k++) tyProj[k] = 0;
	for (k=0;k<2000;k++){
		xyProj[k%20] = xyProj[k%20] | (pMult[k] & 0x3fffff);
	}  
	for (k=0;k<2000;k++){
		if (xyProj[k%20]) {
			tyProj[k/20] = tyProj[k/20] | (pMult[k] & 0x3fffff);
		}
	}
	
	
	for(j=0;j<22;j++){
		NSMutableString* s = [NSMutableString stringWithFormat:@"%2d: ",j];
		//matrix of triggered pixel
		for(i=0;i<20;i++){
			if (((xyProj[i]>>j) & 0x1) == 0x1) [s appendFormat:@"X"];
			else							   [s appendFormat:@"."];
		}
		[s appendFormat:@"  "];
		
		// trigger timing
		for (k=0;k<100;k++){
			if (((tyProj[k]>>j) & 0x1) == 0x1 )[s appendFormat:@"="];
			else							   [s appendFormat:@"."];
		}
		NSLogFont(aFont, @"%@\n", s);
	}
	
	
	NSLogFont(aFont,@"\n");			
	
	
}
*/
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
 	//nothing to do... this just removes a run-time exception
}

#pragma mark •••SBC_Linking protocol
- (NSString*) driverScriptName {return nil;} //no driver
- (NSString*) driverScriptInfo {return @"";}

- (NSString*) cpuName
{
	return [NSString stringWithFormat:@"IPE-DAQ-V4 SLT Card (Crate %d)",[self crateNumber]];
}

- (NSString*) sbcLockName
{
	return ORIpeV4SLTSettingsLock;
}

- (NSString*) sbcLocalCodePath
{
	return @"Source/Objects/Hardware/IPE/IpeV4 SLT/SLTv4_Readout_Code";
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
	configStruct->card_info[index].hw_type_id	= kSLTv4;	//should be unique
	configStruct->card_info[index].hw_mask[0] 	= eventDataId;
	configStruct->card_info[index].hw_mask[1] 	= multiplicityId;
	configStruct->card_info[index].slot			= [self stationNumber];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= 0;		//not needed for this HW
    
    //SLT specific settings BEGIN
    //"first time" flag (needed for histogram mode)
	unsigned long runFlagsMask = 0;
	runFlagsMask |= kFirstTimeFlag;          //bit 16 = "first time" flag
    if(secondsSetSendToFLTs)
        runFlagsMask |= kSecondsSetSendToFLTsFlag;//bit ...
	configStruct->card_info[index].deviceSpecificData[3] = runFlagsMask;	
    //SLT specific settings END
    


	
	configStruct->card_info[index].num_Trigger_Indexes = 1;	//Just 1 group of objects controlled by SLT
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

@implementation ORIpeV4SLTModel (private)
- (unsigned long) read:(unsigned long) address
{
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	unsigned long theData;
	[pmcLink readLongBlockPmc:&theData
					  atAddress:address
					  numToRead: 1];
	return theData;
}

- (void) write:(unsigned long) address value:(unsigned long) aValue
{
	if(![pmcLink isConnected]){
		[NSException raise:@"Not Connected" format:@"Socket not connected."];
	}
	[pmcLink writeLongBlockPmc:&aValue
					  atAddress:address
					 numToWrite:1];
}
@end

