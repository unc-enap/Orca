//
//  ORIpeSLTModel.m
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


#import "../IPE Base Classes/ORIpeDefs.h"
#import "ORCrate.h"
#import "ORIpeSLTModel.h"
#import "ORIpeFLTModel.h"
#import "ORFireWireInterface.h"
#import "ORIpeCrateModel.h"
#import "ORIpeSLTDefs.h"
#import "ORReadOutList.h"
#import "unistd.h"
#import "TimedWorker.h"
#import "ORDataTypeAssigner.h"

enum {
	kSLTControlReg,
	kSLTStatusReg,
	kSLTIRStatus,
	kSLTIRMask,
	kSLTIRVector,
	kSLTThresh_Wr,
	kSLTThresh_Rd,
	kSLTSwNextPage,
	kSLTSwSltTrigger,
	kSLTSwSetInhibit,
	kSLTSwRelInhibit,
	kSLTSwTestpulsTrigger,
	kSLTSwReadADC,
	kSLTSwSecondStrobe,
	kSLTConfSltFPGAs,
	kSLTConfFltFPGAs,
	kSLTActResetFlt,
	kSLTRelResetFlt,
	kSLTActResetSlt,
	kSLTRelResetSlt,
	kPageStatusLow,
	kPageStatusHigh,
	kSLTActualPage,
	kSLTNextPage,
	kSLTSetPageFree,
	kSLTSetPageNoUse,
	kSLTTimingMemory,
	kSLTTestpulsAmpl,
	kSLTTestpulsStartSec,
	kSLTTestpulsStartSubSec,
	kSLTSetSecCounter,
	kSLTSecCounter,
	kSLTSubSecCounter,
	kSLTT1,
	kSLTIRInput,
	kSLTVersion,
	kSLTVetoTimeLow,
	kSLTVetoTimeHigh,
	kSLTDeadTimeLow,
	kSLTDeadTimeHigh,
	kSLTResetDeadTime,
	kSLTSensorMask,
	kSLTSensorStatus,
	kSLTPageTimeStamp,
	kSLTLastTriggerTimeStamp,
	kSLTTestpulsTiming,
	kSLTSensorData,
	kSLTSensorConfig,
	kSLTSensorUpperThresh,
	kSLTSensorLowerThresh,
	kSLTWatchDogMask,
	kSLTWatchDogStatus,
	kSLTNumRegs //must be last
};

static IpeRegisterNamesStruct reg[kSLTNumRegs] = {
{@"Control",			0x0f00,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"Status",				0x0f02,		-1,				kIpeRegReadable},
{@"IRStatus",			0x0f04,		-1,				kIpeRegReadable},
{@"IRMask",				0x0f05,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"IRVector",			0x0f06,		-1,				kIpeRegReadable},
{@"Thresh_Wr",			0x0f0d,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"Thresh_Rd",			0x0f0e,		-1,				kIpeRegReadable},
{@"SwNextPage",			0x0f10,		-1,				kIpeRegWriteable},
{@"SwSltTrigger",		0x0f12,		-1,				kIpeRegWriteable},
{@"SwSetInhibit",		0x0f13,		-1,				kIpeRegWriteable},
{@"SwRelInhibit",		0x0f14,		-1,				kIpeRegWriteable},
{@"SwTestpulsTrigger",	0x0f20,		-1,				kIpeRegWriteable},
{@"SwReadADC",			0x0f40,		-1,				kIpeRegWriteable},
{@"SwSecondStrobe",		0x0f50,		-1,				kIpeRegWriteable},
{@"ConfSltFPGAs",		0x0f51,		-1,				kIpeRegWriteable},
{@"ConfFltFPGAs",		0x0f61,		-1,				kIpeRegWriteable},
{@"ActResetFlt",		0x0f80,		-1,				kIpeRegWriteable},
{@"RelResetFlt",		0x0f81,		-1,				kIpeRegWriteable},
{@"ActResetSlt",		0x0f90,		-1,				kIpeRegWriteable},
{@"RelResetSlt",		0x0f91,		-1,				kIpeRegWriteable},
{@"PageStatusLow",		0x0100,		-1,				kIpeRegReadable},
{@"PageStatusHigh",		0x0101,		-1,				kIpeRegReadable},
{@"ActualPage",			0x0102,		-1,				kIpeRegReadable},
{@"NextPage",			0x0103,		-1,				kIpeRegReadable},
{@"SetPageFree",		0x0105,		-1,				kIpeRegWriteable},
{@"SetPageNoUse",		0x0106,		-1,				kIpeRegWriteable},
{@"TimingMemory",		0x0200,		0xff,			kIpeRegReadable | kIpeRegWriteable},
{@"TestpulsAmpl",		0x0300,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"TestpulsStartSec",	0x0301,		-1,				kIpeRegReadable},
{@"TestpulsStartSubSec",0x0302,		-1,				kIpeRegReadable},
{@"SetSecCounter",		0x0500,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"SecCounter",			0x0501,		-1,				kIpeRegReadable},
{@"SubSecCounter",		0x0502,		-1,				kIpeRegReadable},
{@"T1",					0x0503,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"IRInput",			0x0f07,		-1,				kIpeRegReadable},
{@"SltVersion",			0x0f08,		-1,				kIpeRegReadable},
{@"VetoTimeLow",		0x0f0a,		-1,				kIpeRegReadable},
{@"VetoTimeHigh",		0x0f09,		-1,				kIpeRegReadable},
{@"DeadTimeLow",		0x0f0c,		-1,				kIpeRegReadable},
{@"DeadTimeHigh",		0x0f0b,		-1,				kIpeRegReadable},
{@"ResetDeadTime",		0x0f11,		-1,				kIpeRegReadable},
{@"SensorMask",			0x0f20,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"SensorStatus",		0x0f21,		-1,				kIpeRegReadable},
{@"PageTimeStamp",		0x0000,		-1,				kIpeRegReadable},
{@"LastTriggerTimeStamp",0x0080,	-1,				kIpeRegReadable},
{@"TestpulsTiming",		0x0200,		256,			kIpeRegReadable | kIpeRegWriteable},
{@"SensorData",			0x0400,		8,				kIpeRegReadable},
{@"SensorConfig",		0x0408,		8,				kIpeRegReadable},
{@"SensorUpperThresh",	0x0410,		8,				kIpeRegReadable},
{@"SensorLowerThresh",	0x0418,		8,				kIpeRegReadable},
{@"WatchDogMask",		0x0420,		-1,				kIpeRegReadable | kIpeRegWriteable},
{@"WatchDogStatus",		0x0421,		-1,				kIpeRegReadable},
};

#define SLTID 21
#define SLT_REG_ADDRESS(A) ((SLTID << 24) + ((0x1) << 18) + reg[(A)].addressOffset)

//status reg bit positions
#define SLT_CRATEID				22
#define SLT_SLOTID				27
#define SLT_VETO				20
#define SLT_EXTINHIBIT			19

#define SLT_NOPGINHIBIT			18
#define SLT_SWINHIBIT			17
#define SLT_INHIBIT				16

//control reg defs
#define SLT_TRIGGER_LOW       0
#define SLT_TRIGGER_MASK   0x1f

#define SLT_INHIBIT_LOW       5
#define SLT_INHIBIT_MASK   0x07

#define SLT_TESTPULS_LOW      8
#define SLT_TESTPULS_MASK  0x03

#define SLT_SECSTROBE_LOW    10
#define SLT_SECSTROBE_MASK 0x01

#define SLT_WATCHDOGSTART_LOW      11
#define SLT_WATCHDOGSTART_MASK   0x03

#define SLT_DEADTIMECOUNTERS      13
#define SLT_DEADTIMECOUNTERS_MASK   0x01

#define SLT_LOWERLED      14
#define SLT_LOWERLED_MASK   0x01

#define SLT_UPPERLED      15
#define SLT_UPPERLED_MASK   0x01

#define SLT_NHIT					0
#define SLT_NHIT_MASK			 0xff

#define SLT_NHIT_THRESHOLD			8
#define SLT_NHIT_THRESHOLD_MASK  0x7f


#pragma mark ***External Strings
NSString* ORIpeSLTModelPatternFilePathChanged   = @"ORIpeSLTModelPatternFilePathChanged";
NSString* ORIpeSLTModelInterruptMaskChanged		= @"ORIpeSLTModelInterruptMaskChanged";
NSString* ORIpeSLTModelFpgaVersionChanged		= @"ORIpeSLTModelFpgaVersionChanged";
NSString* ORIpeSLTModelNHitThresholdChanged		= @"ORIpeSLTModelNHitThresholdChanged";
NSString* ORIpeSLTModelNHitChanged				= @"ORIpeSLTModelNHitChanged";
NSString* ORIpeSLTPulserDelayChanged			= @"ORIpeSLTPulserDelayChanged";
NSString* ORIpeSLTPulserAmpChanged				= @"ORIpeSLTPulserAmpChanged";
NSString* ORIpeSLTSettingsLock					= @"ORIpeSLTSettingsLock";
NSString* ORIpeSLTStatusRegChanged				= @"ORIpeSLTStatusRegChanged";
NSString* ORIpeSLTControlRegChanged				= @"ORIpeSLTControlRegChanged";
NSString* ORIpeSLTSelectedRegIndexChanged		= @"ORIpeSLTSelectedRegIndexChanged";
NSString* ORIpeSLTWriteValueChanged				= @"ORIpeSLTWriteValueChanged";
NSString* ORIpeSLTModelNextPageDelayChanged		= @"ORIpeSLTModelNextPageDelayChanged";
NSString* ORIpeSLTModelPageStatusChanged		= @"ORIpeSLTModelPageStatusChanged";
NSString* ORIpeSLTModelPollRateChanged			= @"ORIpeSLTModelPollRateChanged";
NSString* ORIpeSLTModelReadAllChanged			= @"ORIpeSLTModelReadAllChanged";

NSString* ORIpeSLTModelPageSizeChanged			= @"ORIpeSLTModelPageSizeChanged";
NSString* ORIpeSLTModelDisplayTriggerChanged	= @"ORIpeSLTModelDisplayTrigerChanged";
NSString* ORIpeSLTModelDisplayEventLoopChanged	= @"ORIpeSLTModelDisplayEventLoopChanged";

NSString* ORIpeSLTModelHW_ResetChanged          = @"ORIpeSLTModelHW_ResetChanged";

@implementation ORIpeSLTModel

- (id) init
{
    self = [super init];
	ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];	
	[self setReadOutGroup:readList];
    [self makePoller:0];
	[readList release];
    [self registerNotificationObservers];
    return self;
}

-(void) dealloc
{
    [patternFilePath release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[readOutGroup release];
    [fireWireInterface release];
    [poller stop];
    [poller release];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    if(![gOrcaGlobals runInProgress]){
        [poller runWithTarget:self selector:@selector(readAllStatus)];
    }
}

- (void) sleep
{
    [super sleep];
    [poller stop];
}


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"IpeSLTCard"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORIpeSLTController"];
}


- (void) setGuardian:(id)aGuardian
{
	if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self];			
		}
		[self findInterface];
	}
	else {
		[self setFireWireInterface:nil];
		[[self guardian] setAdapter:nil];
	}
	[super setGuardian:aGuardian];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver:self];
	
    [notifyCenter addObserver : self
                     selector : @selector(serviceChanged:)
                         name : @"ORFireWireInterfaceServiceAliveChanged"
                       object : [self fireWireInterface]];

    #if 0
    //Calls initBoard, which will be called from runTaskStarted again. So we dont need this notification.
    [notifyCenter addObserver : self
                     selector : @selector(runIsAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
    #endif
	
    [notifyCenter addObserver : self
                     selector : @selector(runIsStopped:)
                         name : ORRunStoppedNotification
                       object : nil];
}

- (void) releaseSwInhibit
{
	[self writeReg:kSLTSwRelInhibit value:0];
}

- (void) setSwInhibit
{
	[self writeReg:kSLTSwSetInhibit value:0];
}

- (void) releaseAllPages
{
	int i;
	for(i=0;i<64;i++){
		[self writeReg:kSLTSetPageFree value:i];
	}
}

- (TimedWorker *) poller
{
    return poller; 
}

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


- (void) runIsAboutToStart:(NSNotification*)aNote
{
    //Note: ORRunModel sends out ORRunAboutToStartNotification (in -(void)runStarted:...) -tb- 2008-03-28
    //Note: SLT should not init the board without check whether we can run, e.g. check if calibration run is active -tb- 2008-03-28
    //Note: why is it not in runTaskStarted: ... ??????? -tb- 
    
    //I removed the calling notification, initBoard is called from runTaskStarted. -tb- 2009-08-28
    // (Maybe I could reuse it for FLT function loadTime?) -tb-
    
	if([readOutGroup count] == 0){//TODO: [readOutGroup count]: what is this?????????????? -tb- 2008-03-28
		[self initBoard];
	}	
}

- (void) runIsStopped:(NSNotification*)aNote
{	
	// Stop all activities by software inhibit
	if([readOutGroup count] == 0){
		[self setSwInhibit];
	}
	
	// TODO: Save dead time counters ?!
	// Is it sensible to send a new package here?
	// ak 18.7.07
	
	NSLog(@"Deadtime: %lld\n", [self readDeadTime]);
}

- (void) serviceChanged:(NSNotification*)aNote
{
	if([fireWireInterface serviceAlive]){
		[self checkAndLoadFPGAs];
		[self readVersion];
		@try {
			NSArray* cards = [[self crate] orcaObjects];
			NSEnumerator* e = [cards objectEnumerator];
			id card;
			while (card = [e nextObject]){
				if([card isKindOfClass:NSClassFromString(@"ORIpeCard")]){
					[card initVersionRevision];
				}
			}
		}
		@catch(NSException* localException) {
			NSLogColor([NSColor redColor],@"SLT failed FLT FPGA load attempt\n");
		}
	}
}

- (void) checkAndLoadFPGAs
{
	BOOL doLoad = NO;
	@try {
		NSArray* cards = [[self crate] orcaObjects];
		NSEnumerator* e = [cards objectEnumerator];
		id card;
		while (card = [e nextObject]){
			if([card isKindOfClass:NSClassFromString(@"ORIpeCard")] &&
			   ![card isKindOfClass:[self class]]){
				//try to access a card. if it throws then we have to load the FPGAs
				[card readControlStatus];
				break;	//only need to try one
			}
		}
	}
	@catch(NSException* localException) {
		doLoad = YES;
	}
	
	@try {
		if(doLoad){
			[self writeControlReg];
			[self hw_reset];
			NSLog(@"SLT loaded FLT FPGAs\n");
		}
	}
	@catch(NSException* localException) {
		NSLogColor([NSColor redColor],@"SLT failed FLT FPGA load attempt\n");
	}
}

#pragma mark ¥¥¥Accessors

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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTModelPatternFilePathChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTModelNextPageDelayChanged object:self];
	
}

- (BOOL) readAll
{
	return readAll;
}

- (void) setReadAll:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setReadAll:readAll];
    
    readAll = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTModelReadAllChanged object:self];
}


- (unsigned long) pageStatusLow
{
	return pageStatusLow;
}

- (unsigned long) pageStatusHigh
{
	return pageStatusHigh;
}
- (unsigned long) actualPage
{
	return actualPage;
}
- (unsigned long) nextPage
{
	return nextPage;
}

- (void) setPageStatusLow:(unsigned long)loPart high:(unsigned long)hiPart actual:(unsigned long)p0 next:(unsigned long)p1
{
    
    pageStatusLow	= loPart;
    pageStatusHigh	= hiPart;
    actualPage		= p0;
    nextPage		= p1;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTModelPageStatusChanged object:self];
}


- (unsigned long) interruptMask
{
    return interruptMask;
}

- (void) setInterruptMask:(unsigned long)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    
    interruptMask = aInterruptMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTModelInterruptMaskChanged object:self];
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

- (NSMutableArray*) children {
	//method exists to give common interface across all objects for display in lists
	return [NSMutableArray arrayWithObject:readOutGroup];
}
- (BOOL) usingNHitTriggerVersion
{
	if(fpgaVersion >= 3.5)return YES;
	else return NO;
}

- (float) fpgaVersion
{
    return fpgaVersion;
}

- (void) setFpgaVersion:(float)aFpgaVersion
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFpgaVersion:fpgaVersion];
    
    fpgaVersion = aFpgaVersion;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTModelFpgaVersionChanged object:self];
}

- (unsigned short) nHitThreshold
{
    return nHitThreshold;
}

- (void) setNHitThreshold:(unsigned short)aNHitThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNHitThreshold:nHitThreshold];
	
	if(aNHitThreshold>127)aNHitThreshold=127;
    
    nHitThreshold = aNHitThreshold;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTModelNHitThresholdChanged object:self];
}

- (unsigned short) nHit
{
    return nHit;
}

- (void) setNHit:(unsigned short)aNHit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNHit:nHit];
    
	if(aNHit>255)aNHit=255;
	
    nHit = aNHit;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTModelNHitChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTPulserDelayChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTPulserAmpChanged object:self];
}

- (short) getNumberRegisters			
{ 
	return kSLTNumRegs; 
}

- (NSString*) getRegisterName: (short) anIndex
{
	return reg[anIndex].regName;
}

- (unsigned long) getAddressOffset: (short) anIndex
{
    return( reg[anIndex].addressOffset );
}

- (short) getAccessType: (short) anIndex
{
	return reg[anIndex].accessType;
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
	 postNotificationName:ORIpeSLTSelectedRegIndexChanged
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
	 postNotificationName:ORIpeSLTWriteValueChanged
	 object:self];
}

- (void) findInterface
{
	@try {
		[self setFireWireInterface:[[self crate] getFireWireInterface:0x108]];
	}
	@catch(NSException* localException) {
	}
}

//status reg values

- (BOOL) inhibit
{
    return inhibit;
}

- (void) setInhibit:(BOOL)aInhibit
{
	inhibit = aInhibit;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTStatusRegChanged object:self];
}

- (BOOL) swInhibit
{
    return swInhibit;
}

- (void) setSwInhibit:(BOOL)aSwInhibit
{
	swInhibit = aSwInhibit;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTStatusRegChanged object:self];
}

- (BOOL) nopgInhibit
{
    return nopgInhibit;
}

- (void) setNopgInhibit:(BOOL)aNopgInhibit
{
	nopgInhibit = aNopgInhibit;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTStatusRegChanged object:self];
}

- (BOOL) extInhibit
{
    return extInhibit;
}

- (void) setExtInhibit:(BOOL)aExtInhibit
{
	extInhibit = aExtInhibit;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTStatusRegChanged object:self];
}

- (BOOL) veto
{
    return veto;
}

- (void) setVeto:(BOOL)aVeto
{
	veto = aVeto;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTStatusRegChanged object:self];
}


//control reg access
- (BOOL) ledInhibit
{
	return ledInhibit;
}
- (void) setLedInhibit:(BOOL)aState
{
	if(aState != ledInhibit) {
		[[[self undoManager] prepareWithInvocationTarget:self] setLedInhibit:ledInhibit];
		
		ledInhibit = aState;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTControlRegChanged object:self];
	}
}

- (BOOL) ledVeto
{
	return ledVeto;
}
- (void) setLedVeto:(BOOL)aState
{
	if(aState != ledVeto) {
		[[[self undoManager] prepareWithInvocationTarget:self] setLedVeto:ledVeto];
		
		ledVeto = aState;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTControlRegChanged object:self];
	}
}

- (BOOL) enableDeadTimeCounter
{
    return enableDeadTimeCounter;
}

- (void) setEnableDeadTimeCounter:(BOOL)aState
{
	if(aState != enableDeadTimeCounter) {
		[[[self undoManager] prepareWithInvocationTarget:self] setEnableDeadTimeCounter:enableDeadTimeCounter];
		
		enableDeadTimeCounter = aState;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTControlRegChanged object:self];
	}
}


- (int) watchDogStart
{
    return watchDogStart;
}

- (void) setWatchDogStart:(int)aWatchDogStart
{
	if(aWatchDogStart ==  0)aWatchDogStart  = 1;
	if(aWatchDogStart!= 1 && aWatchDogStart!= 2) aWatchDogStart  = 1;
	if(aWatchDogStart != watchDogStart) {
		[[[self undoManager] prepareWithInvocationTarget:self] setWatchDogStart:watchDogStart];
		
		watchDogStart = aWatchDogStart;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTControlRegChanged object:self];
	}
}

- (int) secStrobeSource
{
    return secStrobeSource;
}

- (void) setSecStrobeSource:(int)aSecStrobeSource
{
	if(aSecStrobeSource!= 0 && aSecStrobeSource!= 1) return;
	
	if(aSecStrobeSource != secStrobeSource) {
		[[[self undoManager] prepareWithInvocationTarget:self] setSecStrobeSource:secStrobeSource];
		
		secStrobeSource = aSecStrobeSource;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTControlRegChanged object:self];
	}
}

- (int) testPulseSource
{
    return testPulseSource;
}

- (void) setTestPulseSource:(int)aTestPulseSource
{
	if(aTestPulseSource ==  0)aTestPulseSource  = 1;
	if(aTestPulseSource!= 1 && aTestPulseSource!= 2) return;
	
	if(aTestPulseSource != testPulseSource) {
		[[[self undoManager] prepareWithInvocationTarget:self] setTestPulseSource:testPulseSource];
		
		testPulseSource = aTestPulseSource;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTControlRegChanged object:self];
	}
}

- (int) inhibitSource
{
    return inhibitSource;
}

- (void) setInhibitSource:(int)aInhibitSource
{
	aInhibitSource &= 0x7; //only care about the lowest 3 bits
	
	if(aInhibitSource != inhibitSource) {
		[[[self undoManager] prepareWithInvocationTarget:self] setInhibitSource:inhibitSource];
		
		inhibitSource = aInhibitSource;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTControlRegChanged object:self];
	}
}

- (int) triggerSource
{	
    return triggerSource;
}

- (void) setTriggerSource:(int)aTriggerSource
{
	if(aTriggerSource != triggerSource) {
		[[[self undoManager] prepareWithInvocationTarget:self] setTriggerSource:triggerSource];
		
		triggerSource = aTriggerSource;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTControlRegChanged object:self];
	}
}


- (BOOL) displayTrigger
{
	return displayTrigger;
}

- (void) setDisplayTrigger:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayTrigger:displayTrigger];
	
	displayTrigger = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTModelDisplayTriggerChanged object:self];
	
}

- (BOOL) displayEventLoop
{
	return displayEventLoop;
}

- (void) setDisplayEventLoop:(BOOL) aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDisplayEventLoop:displayEventLoop];
	
	displayEventLoop = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTModelDisplayEventLoopChanged object:self];
	
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTModelPageSizeChanged object:self];
	
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
			ORIpeFLTModel* cards[20];
			int i;
			for(i=0;i<20;i++)cards[i]=nil;
			
			NSArray* allFLTs = [[self crate] orcaObjects];
			NSEnumerator* e = [allFLTs objectEnumerator];
			id aCard;
			while(aCard = [e nextObject]){
				if([aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")])continue;
				int index = [aCard stationNumber] - 1;
				if(index<20){
					cards[index] = aCard;
				}
			}
			for(i=0;i<20;i++){
				[cards[i] setFltRunMode: kIpeFlt_Test_Mode];
			}
			
			
			[self writeReg:kSLTTestpulsAmpl value:amplitude];
			[self writeBlock:SLT_REG_ADDRESS(kSLTTimingMemory) 
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
				NSMutableString* line = [NSMutableString stringWithFormat:@"  %2d |=%4d=%4lu|",i,delta,time[i]];
				delta += time[i];
				for(j=0;j<20;j++){
					//if(mask[j][i] != 0x1000000)[line appendFormat:@"%3s",mask[j][i]?"¥":"-"];
					if(mask[j][i] != 0x1000000)[line appendFormat:@"%3s",mask[j][i]?"*":"-"]; //fixed XCode 4.4 warning. MAH 7/29/2012
					else [line appendFormat:@"%3s","="];
				}
				NSLogFont(aFont,@"%@\n",line);
			}
			NSLogFont(aFont,@"-----------------------------------------------------------------------------\n",amplitude);			
			
			
			for(i=0;i<20;i++){
				[cards[i] setFltRunMode: kIpeFlt_Run_Mode];
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
	[self writeReg:kSLTSwTestpulsTrigger value:0];
}

- (void) writeReg:(unsigned short)index value:(unsigned long)aValue
{
	[self write:SLT_REG_ADDRESS(index) value:aValue];
}

- (unsigned long) readReg:(unsigned short) index
{
	return [self read:SLT_REG_ADDRESS(index)];
}

- (void) readAllStatus
{
	[self readPageStatus];
	[self readStatusReg];
}

- (void) readPageStatus
{
	[self setPageStatusLow:   [self readReg:kPageStatusLow] 
					  high:   [self readReg:kPageStatusHigh]
					actual: [self readReg:kSLTActualPage]
					  next:   [self readReg:kSLTNextPage]];
}

- (unsigned long) readStatusReg
{
	unsigned long data = 0;
	
	data = [self readReg:kSLTStatusReg];
	
	[self setVeto:				(data >> SLT_VETO)			& 0x1];
	[self setExtInhibit:		(data >> SLT_EXTINHIBIT)	& 0x1];	
	[self setNopgInhibit:		(data >> SLT_NOPGINHIBIT)	& 0x1];
	[self setSwInhibit:			(data >> SLT_SWINHIBIT)		& 0x1];
	[self setInhibit:			(data >> SLT_INHIBIT)		& 0x1];
	
	return data;
}

- (void) printStatusReg
{
	[self readStatusReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Status Register SLT (%d) ----\n",[self stationNumber]);
	NSLogFont(aFont,@"Veto             : %d\n",veto);
	NSLogFont(aFont,@"ExtInhibit       : %d\n",extInhibit);
	NSLogFont(aFont,@"NopgInhibit      : %d\n",nopgInhibit);
	NSLogFont(aFont,@"SwInhibit        : %d\n",swInhibit);
	NSLogFont(aFont,@"Inhibit          : %d\n",inhibit);
}

- (void) writeStatusReg
{
	unsigned long data = 0;
	data |= veto			 << SLT_VETO;
	data |= extInhibit		 << SLT_EXTINHIBIT;
	data |= nopgInhibit		 << SLT_NOPGINHIBIT;
	data |= swInhibit		 << SLT_SWINHIBIT;
	data |= inhibit			 << SLT_INHIBIT;
	[self writeReg:kSLTStatusReg value:data];
}

- (void) writeNextPageDelay
{
	//nextPageDelay stored as number from 0 - 100
	unsigned long aValue = nextPageDelay * 1999./100.; //convert to value 0 - 1999 x 50us  // ak, 5.10.07
	[self writeReg:kSLTT1 value:aValue];
}


- (unsigned long) readControlReg
{
	unsigned long data;
	
	data = [self readReg:kSLTControlReg];
	
	[self setLedInhibit:			(data >> SLT_UPPERLED)      & SLT_UPPERLED_MASK];
	[self setLedVeto:				(data >> SLT_LOWERLED)      & SLT_LOWERLED_MASK];
	[self setTriggerSource:			(data >> SLT_TRIGGER_LOW)   & SLT_TRIGGER_MASK];
	[self setInhibitSource:			(data >> SLT_INHIBIT_LOW)   & SLT_INHIBIT_MASK];
	[self setTestPulseSource:		(data >> SLT_TESTPULS_LOW)  & SLT_TESTPULS_MASK];
	[self setSecStrobeSource:		(data >> SLT_SECSTROBE_LOW) & SLT_SECSTROBE_MASK];
	[self setWatchDogStart:		    (data >> SLT_WATCHDOGSTART_LOW) & SLT_WATCHDOGSTART_MASK];
	[self setEnableDeadTimeCounter: (data >> SLT_DEADTIMECOUNTERS)  & SLT_DEADTIMECOUNTERS_MASK];
	
	if(fpgaVersion >= 3.5){
		data = [self readReg:kSLTThresh_Rd];
		[self setNHit:			(data >> SLT_NHIT)			 & SLT_NHIT_MASK];
		[self setNHitThreshold:	(data >> SLT_NHIT_THRESHOLD) & SLT_NHIT_THRESHOLD_MASK];
	}
	
	return data;
}

- (void) printControlReg
{
	unsigned long data = [self readReg:kSLTControlReg];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Control Register SLT (%d) ----\n",[self stationNumber]);
	NSLogFont(aFont,@"LedInhibit       : %d\n",(data >> SLT_UPPERLED)      & SLT_UPPERLED_MASK);
	NSLogFont(aFont,@"LedVeto          : %d\n",(data >> SLT_LOWERLED)      & SLT_LOWERLED_MASK);
	NSLogFont(aFont,@"TriggerSource    : 0x%x\n",(data >> SLT_TRIGGER_LOW)   & SLT_TRIGGER_MASK);
	NSLogFont(aFont,@"InhibitSource    : 0x%x\n",(data >> SLT_INHIBIT_LOW)   & SLT_INHIBIT_MASK);
	NSLogFont(aFont,@"TestPulseSource  : 0x%x\n",(data >> SLT_TESTPULS_LOW)  & SLT_TESTPULS_MASK);
	NSLogFont(aFont,@"SecStrobeSource  : 0x%x\n",(data >> SLT_SECSTROBE_LOW) & SLT_SECSTROBE_MASK);
	NSLogFont(aFont,@"WatchDogStart    : 0x%x\n",(data >> SLT_WATCHDOGSTART_LOW) & SLT_WATCHDOGSTART_MASK);
	NSLogFont(aFont,@"EnableDeadTimeCnt: %d\n",(data >> SLT_DEADTIMECOUNTERS)  & SLT_DEADTIMECOUNTERS_MASK);
	if(fpgaVersion >= 3.5){
		data = [self readReg:kSLTThresh_Rd];
		NSLogFont(aFont,@"Multiplicity Receive\n");
		NSLogFont(aFont,@"NHit             : %d\n",(data >> SLT_NHIT)			 & SLT_NHIT_MASK);
		NSLogFont(aFont,@"NHitThreshold    : %d\n",(data >> SLT_NHIT_THRESHOLD)	 & SLT_NHIT_THRESHOLD_MASK);
	}
}

- (void) writeControlReg
{
	unsigned long data = 0;
	data |= (ledInhibit   & SLT_UPPERLED_MASK)   << SLT_UPPERLED;
	data |= (ledVeto   & SLT_LOWERLED_MASK)   << SLT_LOWERLED;
	data |= (triggerSource   & SLT_TRIGGER_MASK)   << SLT_TRIGGER_LOW;
	data |= (inhibitSource   & SLT_INHIBIT_MASK)   << SLT_INHIBIT_LOW;
	data |= (testPulseSource  & SLT_TESTPULS_MASK)  << SLT_TESTPULS_LOW;
	data |= (secStrobeSource & SLT_SECSTROBE_MASK) << SLT_SECSTROBE_LOW;
	data |= (watchDogStart   & SLT_WATCHDOGSTART_MASK)   << SLT_WATCHDOGSTART_LOW;
	data |= (enableDeadTimeCounter  & SLT_DEADTIMECOUNTERS_MASK)  << SLT_DEADTIMECOUNTERS;
	[self writeReg:kSLTControlReg value:data];
	
	if(fpgaVersion >= 3.5){
		data = 0x8000 | 
		(nHit   & SLT_NHIT_MASK)   << SLT_NHIT | 
		(nHitThreshold & SLT_NHIT_THRESHOLD_MASK)   << SLT_NHIT_THRESHOLD;
		[self writeReg:kSLTThresh_Wr value:data];
		[self writeReg:kSLTThresh_Wr value:0];
		data = [self readReg:kSLTThresh_Rd];
		NSLog(@"M threshold = %4d  N threshold = %4d\n",(data>>8)&0x3f, data&0xff);				
	}
}

- (void) writeInterruptMask
{
	[self writeReg:kSLTIRMask value:interruptMask];
}

- (void) readInterruptMask
{
	[self setInterruptMask:[self readReg:kSLTIRMask]];
}

- (void) printInterruptMask
{
	unsigned long data = [self readReg:kSLTIRMask];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----Interrupt Mask SLT (%d) ----\n",[self stationNumber]);
	if(!data)NSLogFont(aFont,@"Interrupt Mask is Clear (No interrupts enabled)\n");
	else {
		NSLogFont(aFont,@"The following interrupts are enabled:\n");
		
		if(data & (1<<0))NSLogFont(aFont,@"\tNext Page\n");
		if(data & (1<<1))NSLogFont(aFont,@"\tAll Pages Full\n");
		if(data & (1<<2))NSLogFont(aFont,@"\tFLT Config Failure\n");
		if(data & (1<<3))NSLogFont(aFont,@"\tFLT Cmd sent after Config Failure\n");
		if(data & (1<<4))NSLogFont(aFont,@"\tWatchDog Error\n");
		if(data & (1<<5))NSLogFont(aFont,@"\tSecond Strobe Error\n");
		if(data & (1<<6))NSLogFont(aFont,@"\tParity Error\n");
		if(data & (1<<7))NSLogFont(aFont,@"\tNext Page When Full\n");
		if(data & (1<<8))NSLogFont(aFont,@"\tNext Page , Previous\n");
	}
}

- (float) readVersion
{
	[self setFpgaVersion: [self readReg:kSLTVersion]/10.];
    NSLog(@"IPE-DAQ interface version %@ (build %s %s)\n", ORIPE_VERSION, __DATE__, __TIME__);							  
	return fpgaVersion;
}

- (unsigned long long) readDeadTime
{
	unsigned long low  = [self readReg:kSLTDeadTimeLow];
	unsigned long high = [self readReg:kSLTDeadTimeHigh];
	return ((unsigned long long)high << 32) | low;
}

- (unsigned long long) readVetoTime
{
	unsigned long low  = [self readReg:kSLTVetoTimeLow];
	unsigned long high = [self readReg:kSLTVetoTimeHigh];
	return ((unsigned long long)high << 32) | low;
}

- (void) initBoard
{
	
	//-----------------------------------------------
	//board doesn't appear to start without this stuff
	[self writeReg:kSLTActResetFlt value:0];
	[self writeReg:kSLTActResetSlt value:0];
	usleep(10);
	[self writeReg:kSLTRelResetFlt value:0];
	[self writeReg:kSLTRelResetSlt value:0];
	[self writeReg:kSLTSwSltTrigger value:0];
	[self writeReg:kSLTSwSetInhibit value:0];
	
	usleep(100);
	
	int savedTriggerSource = triggerSource;
	int savedInhibitSource = inhibitSource;
	triggerSource = 0x1; //sw trigger only
	inhibitSource = 0x3; 
	[self writeControlReg];
	[self releaseAllPages];
	unsigned long long p1 = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	[self writeReg:kSLTSwRelInhibit value:0];
	int i = 0;
	unsigned long lTmp;
    do {
		lTmp = [self readReg:kSLTStatusReg];
		//NSLog(@"waiting for inhibit %x i=%d\n", lTmp, i);
		usleep(10);
		i++;
    } while(((lTmp & 0x10000) != 0) && (i<10000));
	
    if (i>= 10000){
		NSLog(@"Release inhibit failed\n");
		[NSException raise:@"SLT error" format:@"Release inhibit failed"];
	}
	
	unsigned long long p2  = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
	if(p1 == p2) NSLog (@"No software trigger\n");
	[self writeReg:kSLTSwSetInhibit value:0];
	triggerSource = savedTriggerSource;
	inhibitSource = savedInhibitSource;
	//-----------------------------------------------
	
	[self writeControlReg];
	[self writeInterruptMask];
	[self writeNextPageDelay];
	[self readControlReg];	
	//[self printStatusReg];
	//[self printControlReg];
}

- (void) reset
{
	[self hw_config];
	[self hw_reset];
}

/** This is called from ORIpeSLTControler::resetHWAction.
 */
- (void) hw_config
{
	NSLog(@"SLT: HW Configure\n");
	[self writeReg:kSLTConfFltFPGAs value:0];
	[ORTimer delay:1.5];
	[self writeReg:kSLTConfSltFPGAs value:0];
	[ORTimer delay:1.5];
	[self readReg:kSLTStatusReg];
	
	[guardian checkCards];
    
    // after HW reset the FLTs should receive a notification or we should call initVersionRevision from here
    // so they can detect new FPGA firmware  -tb- 2008-04-22
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeSLTModelHW_ResetChanged object:self];
    NSLog(@"Posting notificaton ORIpeSLTModelHW_ResetChanged with self = %p\n",self);
}

- (void) hw_reset
{
	NSLog(@"SLT: HW Reset\n");
	[self writeReg:kSLTSwRelInhibit value:0];
	[self writeReg:kSLTActResetFlt value:0];
	[self writeReg:kSLTActResetSlt value:0];
	usleep(10);
	[self writeReg:kSLTRelResetFlt value:0];
	[self writeReg:kSLTRelResetSlt value:0];
	[self writeReg:kSLTSwSltTrigger value:0];
	[self writeReg:kSLTSwSetInhibit value:0];				
}

- (void) loadPulseAmp
{
	unsigned short theConvertedAmp = pulserAmp * 4095./4.;
	[self writeReg:kSLTTestpulsAmpl value:theConvertedAmp];
	NSLog(@"Wrote %.2fV to SLT pulser Amplitude\n",pulserAmp);
}

- (void) loadPulseDelay
{
	//delay goes from 100ns to 3276.8us
	//writing 0x00 to hw gives longest delay. 
	//conversion equation:  hwValue = -10.0*delay + 32768.
	unsigned short theConvertedDelay = pulserDelay * -10.0 + 32768.;
	[self write:SLT_REG_ADDRESS(kSLTTestpulsTiming)+0 value:theConvertedDelay];
	[self write:SLT_REG_ADDRESS(kSLTTestpulsTiming)+1 value:theConvertedDelay];
	int i; //load the rest of the pulser memory with 0's
	for (i=2;i<256;i++) [self write:SLT_REG_ADDRESS(kSLTTestpulsTiming)+i value:theConvertedDelay];
}


- (void) pulseOnce
{
	//int savedTriggerSource = [self triggerSource];
	//[self setTriggerSource:0x01]; //set for sw trigger
	//[self writeControlReg];
	
	[self writeReg:kSLTSwSltTrigger value:0];	// send SW trigger
	
	//[self setTriggerSource:savedTriggerSource];
	//[self writeControlReg];
}

- (void) loadPulserValues
{
	[self loadPulseAmp];
	[self loadPulseDelay];
}

- (void) setCrateNumber:(unsigned int)aNumber
{
	[guardian setCrateNumber:aNumber];
}


#pragma mark ***Archival

- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	//status reg
	[self setPatternFilePath:		[decoder decodeObjectForKey:@"ORIpeSLTModelPatternFilePath"]];
	[self setInterruptMask:			[decoder decodeInt32ForKey:@"ORIpeSLTModelInterruptMask"]];
	[self setPulserDelay:			[decoder decodeFloatForKey:@"ORIpeSLTModelPulserDelay"]];
	[self setPulserAmp:				[decoder decodeFloatForKey:@"ORIpeSLTModelPulserAmp"]];
	[self setInhibit:				[decoder decodeBoolForKey:@"ORIpeSLTStatusInhibit"]];
	[self setSwInhibit:				[decoder decodeBoolForKey:@"ORIpeSLTStatusSwInhibit"]];
	[self setNopgInhibit:			[decoder decodeBoolForKey:@"ORIpeSLTStatusNopgInhibit"]];
	[self setExtInhibit:			[decoder decodeBoolForKey:@"ORIpeSLTStatusExtInhibit"]];
	[self setVeto:					[decoder decodeBoolForKey:@"ORIpeSLTStatusVeto"]];
	
	//control reg
	[self setTriggerSource:			[decoder decodeIntForKey:@"triggerSource"]];
	[self setInhibitSource:			[decoder decodeIntForKey:@"inhibitSource"]];
	[self setTestPulseSource:		[decoder decodeIntForKey:@"testPulseSource"]];
	[self setSecStrobeSource:		[decoder decodeIntForKey:@"secStrobeSource"]];
	[self setWatchDogStart:			[decoder decodeIntForKey:@"watchDogStart"]];
	[self setEnableDeadTimeCounter:	[decoder decodeIntForKey:@"enableDeadTimeCounter"]];
	[self setLedInhibit:			[decoder decodeBoolForKey:@"ledInhibit"]];
	[self setLedVeto:				[decoder decodeBoolForKey:@"ledVeto"]];
	
	//special
	[self setNHitThreshold:			[decoder decodeIntForKey:@"ORIpeSLTModelNHitThreshold"]];
	[self setNHit:					[decoder decodeIntForKey:@"ORIpeSLTModelNHit"]];
	[self setReadAll:				[decoder decodeBoolForKey:@"readAll"]];
    [self setNextPageDelay:			[decoder decodeIntForKey:@"nextPageDelay"]]; // ak, 5.10.07
	
	[self setReadOutGroup:			[decoder decodeObjectForKey:@"ReadoutGroup"]];
    [self setPoller:				[decoder decodeObjectForKey:@"poller"]];
	
    [self setPageSize:				[decoder decodeIntForKey:@"ORIpeSLTPageSize"]]; // ak, 9.12.07
    [self setDisplayTrigger:		[decoder decodeBoolForKey:@"ORIpeSLTDisplayTrigger"]];
    [self setDisplayEventLoop:		[decoder decodeBoolForKey:@"ORIpeSLTDisplayEventLoop"]];
	
	
    if (!poller)[self makePoller:0];
	
	//needed because the readoutgroup was added when the object was already in the config and so might not be in the configuration
	if(!readOutGroup){
		ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
		[self setReadOutGroup:readList];
		[readList release];
	}
	
	
	[[self undoManager] enableUndoRegistration];
	
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	
	//status reg
	[encoder encodeObject:patternFilePath forKey:@"ORIpeSLTModelPatternFilePath"];
	[encoder encodeInt32:interruptMask	 forKey:@"ORIpeSLTModelInterruptMask"];
	[encoder encodeFloat:pulserDelay	 forKey:@"ORIpeSLTModelPulserDelay"];
	[encoder encodeFloat:pulserAmp		 forKey:@"ORIpeSLTModelPulserAmp"];
	[encoder encodeBool:inhibit			 forKey:@"ORIpeSLTStatusInhibit"];
	[encoder encodeBool:swInhibit		 forKey:@"ORIpeSLTStatusSwInhibit"];
	[encoder encodeBool:nopgInhibit		 forKey:@"ORIpeSLTStatusNopgInhibit"];
	[encoder encodeBool:extInhibit		 forKey:@"ORIpeSLTStatusExtInhibit"];
	[encoder encodeBool:veto			 forKey:@"ORIpeSLTStatusVeto"];
	
	//control reg
	[encoder encodeInt:triggerSource	forKey:@"triggerSource"];
	[encoder encodeInt:inhibitSource	forKey:@"inhibitSource"];
	[encoder encodeInt:testPulseSource	forKey:@"testPulseSource"];
	[encoder encodeInt:secStrobeSource	forKey:@"secStrobeSource"];
	[encoder encodeInt:watchDogStart	forKey:@"watchDogStart"];
	[encoder encodeInt:enableDeadTimeCounter	forKey:@"enableDeadTimeCounter"];
	[encoder encodeBool:ledInhibit		forKey:@"ledInhibit"];
	[encoder encodeBool:ledVeto			forKey:@"ledVeto"];
	
	
	//special
	[encoder encodeInt:nHitThreshold	 forKey:@"ORIpeSLTModelNHitThreshold"];
	[encoder encodeInt:nHit				 forKey:@"ORIpeSLTModelNHit"];
	[encoder encodeBool:readAll			 forKey:@"readAll"];
    [encoder encodeInt:nextPageDelay     forKey:@"nextPageDelay"]; // ak, 5.10.07
	
	[encoder encodeObject:readOutGroup  forKey:@"ReadoutGroup"];
    [encoder encodeObject:poller         forKey:@"poller"];
	
    [encoder encodeInt:pageSize         forKey:@"ORIpeSLTPageSize"]; // ak, 9.12.07
    [encoder encodeBool:displayTrigger   forKey:@"ORIpeSLTDisplayTrigger"];
    [encoder encodeBool:displayEventLoop forKey:@"ORIpeSLTDisplayEventLoop"];
	
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORIpeSLTDecoderForEvent",				@"decoder",
								 [NSNumber numberWithLong:eventDataId],	@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:5],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeSLTEvent"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORIpeSLTDecoderForMultiplicity",			@"decoder",
				   [NSNumber numberWithLong:multiplicityId],   @"dataId",
				   [NSNumber numberWithBool:NO],				@"variable",
				   [NSNumber numberWithLong:3+20*100],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeSLTMultiplicity"];
    
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

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithInt:triggerSource]	forKey:@"triggerSource"];
    [objDictionary setObject:[NSNumber numberWithInt:inhibitSource]	forKey:@"inhibitSource"];	
    [objDictionary setObject:[NSNumber numberWithInt:nHit]			forKey:@"nHit"];	
    [objDictionary setObject:[NSNumber numberWithInt:nHitThreshold]	forKey:@"nHitThreshold"];	
    [objDictionary setObject:[NSNumber numberWithBool:readAll]		forKey:@"readAll"];	
	return objDictionary;
}

#pragma mark ¥¥¥Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	
	
    [self clearExceptionCount];
	
	//check that we can actually run
    if(![[[self crate] adapter] serviceIsAlive]){
		[NSException raise:@"No FireWire Service" format:@"Check Crate Power and FireWire Cable."];
    }
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORIpeSLTModel"];    
    //----------------------------------------------------------------------------------------	
	
	pollingWasRunning = [poller isRunning];
	if(pollingWasRunning) [poller stop];
	
	
	[self setSwInhibit];
	
    if([[userInfo objectForKey:@"doinit"]intValue]){
		[self initBoard];  //TODO: I think this was already called from self runIsAboutToStart: ... -tb- 2008-03-28 ---> Andreas, Mark					
	}	
	
	dataTakers = [[readOutGroup allObjects] retain];		//cache of data takers.
	
	/*	NSArray* allFLTs = [[self crate] orcaObjects];
	 NSEnumerator* e = [allFLTs objectEnumerator];
	 id aCard;
	 while(aCard = [e nextObject]){
	 if([aCard isKindOfClass:NSClassFromString(@"ORIpeFireWireCard")])continue;
	 if([dataTakers containsObject:aCard])continue;
	 [aCard disableAllTriggers];
	 }
	 */    
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
	
	[self readStatusReg];
	actualPageIndex = 0;
	eventCounter    = 0;
	first = YES;
	lastDisplaySec = 0;
	lastDisplayCounter = 0;
	lastDisplayRate = 0;
	
  	usingPBusSimulation		  = [self pBusSim];
	lastSimSec = 0;
	
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	if(!first){
		struct timeval t0, t1;
		struct timezone tz;	
		
		
		unsigned long long lPageStatus;
		lPageStatus = ((unsigned long long)[self readReg:kPageStatusHigh]<<32) | [self readReg:kPageStatusLow];
		
		// Simulation of events every second?!
		if (usingPBusSimulation){
			gettimeofday(&t0, &tz);
			if (t0.tv_sec > lastSimSec) {
				lPageStatus = 1;
				lastSimSec = t0.tv_sec;
			}	
		}
		
		
		if(lPageStatus != 0x0){
			while((lPageStatus & (0x1LL<<actualPageIndex)) == 0){
				if(actualPageIndex>=63)actualPageIndex=0;
				else actualPageIndex++;
			}
			
			// Set start of readout 
			gettimeofday(&t0, &tz);
			
			eventCounter++;
			
			//read page start address
			unsigned long lTimeL     = [self read: SLT_REG_ADDRESS(kSLTLastTriggerTimeStamp) + actualPageIndex];
			int iPageStart = (((lTimeL >> 10) & 0x7fe)  + 20) %2000;
			
			unsigned long timeStampH = [self read: SLT_REG_ADDRESS(kSLTPageTimeStamp) + 2*actualPageIndex];
			unsigned long timeStampL = [self read: SLT_REG_ADDRESS(kSLTPageTimeStamp) + 2*actualPageIndex+1];
			//
			//			NSLog(@"Reading event from page %d, start=%d:  %ds %dx100us\n", 
			//			         actualPageIndex+1, iPageStart, timeStampH, (timeStampL >> 11) & 0x3fff);
			
			//readout the SLT pixel trigger data
			int i;
			unsigned long buffer[2000];
			unsigned long sltMemoryAddress = (SLTID << 24) | actualPageIndex<<11;
			// Split the reading of the memory in blocks according to the maximal block size
			// supported by the firewire driver	
			// TODO: Read only the relevant trigger data for smaller page sizes!
			//       Reading needs to start in this case at start address...		
			int blockSize = 500;
			int sltSize = 2000; // Allways read the full trigger memory
			int nBlocks = sltSize / blockSize;
			for (i=0;i<nBlocks;i++)
				[self read:sltMemoryAddress+i*blockSize data:buffer+i*blockSize size:blockSize*sizeof(unsigned long)];
			
			//for(i=0;i<2000;i++) buffer[i]=0; // only Test
			
            // Check result from block readout - Testing only
			//unsigned long buffer2[2000];
            //[self readBlock:sltMemoryAddress dataBuffer:(unsigned long*)buffer2 length:2000 increment:1];
			//for(i=0;i<2000;i++) if (buffer[i]!=buffer2[i]) {
			//  NSLog(@"Error reading Slt Memory\n"); 
			//  break;
			//}  
			
		    // Re-organize trigger data to get it in a continous data stream
			// There is no automatic address wrapping like in the Flts available...
			unsigned long reorderBuffer[2000];
			unsigned long *pMult = reorderBuffer;
			memcpy( pMult, buffer + iPageStart, (2000 - iPageStart)*sizeof(unsigned long));  
			memcpy( pMult + 2000 - iPageStart, buffer, iPageStart*sizeof(unsigned long));  
			
			
			if (usingPBusSimulation){
				// Write random trigger data
				for (i=0;i<2000;i++){
					pMult[i] = (eventCounter + i) & (0x3fffff);
				}
            }
			
			int nTriggered = 0;
		    unsigned long xyProj[20];
			unsigned long tyProj[100];
			nTriggered = [self calcProjection:pMult xyProj:xyProj tyProj:tyProj];
			
			//ship the start of event record
			unsigned long eventData[5];
			eventData[0] = eventDataId | 5;	
			eventData[1] = (([self crateNumber]&0x0f)<<21) | ([self stationNumber]& 0x0000001f)<<16;
			eventData[2] = eventCounter;
			eventData[3] = timeStampH; 
			eventData[4] = timeStampL;
			[aDataPacket addLongsToFrameBuffer:eventData length:5];	//ship the event record
			
			// ship the pixel multiplicity data for all 20 cards 
			// the data is send in hardware format: 100 x 1u of trigger data of all cards is collected.
			// ak 3.3.08
			// Ship trigger memory and not projection only !!!
            unsigned long multiplicityRecord[3 + 2000];
            multiplicityRecord[0] = multiplicityId | (20*pageSize + 3);
			
			multiplicityRecord[1] = (([self crateNumber]&0x0f)<<21) | ([self stationNumber]& 0x0000001f)<<16; 
			multiplicityRecord[2] = eventCounter;
			
			// Ship trigger memory and not projection only !!!
            memcpy(multiplicityRecord+3, pMult, 2000*sizeof(unsigned long));
            [aDataPacket addLongsToFrameBuffer:multiplicityRecord length:20*pageSize + 3];
			
			
			
			int lStart = (lTimeL >> 11) & 0x3ff;
			NSEnumerator* e = [dataTakers objectEnumerator];
			
			//readout the flt waveforms
			// Added pixelList as parameter to the Flt readout in order
			// to enable selective readout
			// ak 5.10.2007
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											 [NSNumber numberWithInt:actualPageIndex], @"page",
											 [NSNumber numberWithInt:lStart],		  @"lStart",
											 [NSNumber numberWithInt:eventCounter],	  @"eventCounter",
											 [NSNumber numberWithInt:pageSize],		  @"pageSize",
											 nil];
			id obj;
			while(obj = [e nextObject]){			    
				unsigned long pixelList;
				if(readAll)	pixelList = 0x3fffff;
				else		pixelList = xyProj[[obj slot] - 1];
				//NSLog(@"Datataker in slot %d, pixelList %06x\n", [obj slot], pixelList);
				[userInfo setObject:[NSNumber numberWithLong:pixelList] forKey: @"pixelList"];
				
				[obj takeData:aDataPacket userInfo:userInfo];
			}
			
			//free the page
			[self writeReg:kSLTSetPageFree value:actualPageIndex];
			
			// Set end of readout
			gettimeofday(&t1, &tz);
			
			// Display event header
			if (displayEventLoop) {
				// TODO: Display number of stored pages
				// TODO: Add control to GUI that controls the update rate
				// 7.12.07 ak
				if (t0.tv_sec > lastDisplaySec){
					NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
					int nEv = eventCounter - lastDisplayCounter;
					double rate = 0.1 * nEv / (t0.tv_sec-lastDisplaySec) + 0.9 * lastDisplayRate;
					
					unsigned long tRead = (t1.tv_sec - t0.tv_sec) * 1000000 + (t1.tv_usec - t0.tv_usec);
					if (t0.tv_sec%20 == 0) {
					    NSLogFont(aFont, @"%64s  | %16s\n", "Last event", "Interval summary"); 
						NSLogFont(aFont, @"%4s %14s %4s %14s %4s %4s %14s  |  %4s %10s\n", 
								  "No", "Actual time/s", "Page", "Time stamp/s", "Trig", 
								  "nCh", "tRead/us", "nEv", "Rate");
					}			  
					NSLogFont(aFont,   @"%4d %14d %4d %14d %4d %4d %14d  |  %4d %10.2f\n", 
							  eventCounter, t0.tv_sec, actualPageIndex, timeStampH, 0, 
							  nTriggered, tRead, nEv, rate);
					
					// Keep the last display second		  
					lastDisplaySec = t0.tv_sec;	
					lastDisplayCounter = eventCounter;
					lastDisplayRate = rate;	  
				}
			}
			
		}
	}
	else {
		[self releaseAllPages];
		[self releaseSwInhibit];
		[self writeReg:kSLTResetDeadTime value:0];
		first = NO;
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	[self setSwInhibit];
	
	dataTakers = [[readOutGroup allObjects] retain];	//cache of data takers.
    
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStopped:aDataPacket userInfo:userInfo];
    }
	[dataTakers release];
	dataTakers = nil;
	if(pollingWasRunning) {
		[poller runWithTarget:self selector:@selector(readAllStatus)];
	}
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

- (void) dumpTriggerRAM:(int)aPageIndex
{
	
	//read page start address
	unsigned long lTimeL     = [self read: SLT_REG_ADDRESS(kSLTLastTriggerTimeStamp) + aPageIndex];
	int iPageStart = (((lTimeL >> 10) & 0x7fe)  + 20) % 2000;
	
	unsigned long timeStampH = [self read: SLT_REG_ADDRESS(kSLTPageTimeStamp) + 2*aPageIndex];
	unsigned long timeStampL = [self read: SLT_REG_ADDRESS(kSLTPageTimeStamp) + 2*aPageIndex+1];
	
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

@end
