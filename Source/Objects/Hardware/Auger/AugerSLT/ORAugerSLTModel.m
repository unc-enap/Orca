//
//  ORAugerSLTModel.m
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


#import "ORAugerDefs.h"
#import "ORCrate.h"
#import "ORAugerSLTModel.h"
#import "ORAugerFLTModel.h"
#import "ORFireWireInterface.h"
#import "ORAugerCrateModel.h"
#import "ORAugerSLTDefs.h"

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
	kSLTPageStatus,
	kSLTNumRegs //must be last
};

static AugerRegisterNamesStruct reg[kSLTNumRegs] = {
	{@"Control",			0x0f00,		-1,				kAugerRegReadable | kAugerRegWriteable},
	{@"Status",				0x0f02,		-1,				kAugerRegReadable},
	{@"IRStatus",			0x0f04,		-1,				kAugerRegReadable},
	{@"IRMask",				0x0f05,		-1,				kAugerRegReadable | kAugerRegWriteable},
	{@"IRVector",			0x0f06,		-1,				kAugerRegReadable},
	{@"Thresh_Wr",			0x0f0d,		-1,				kAugerRegReadable | kAugerRegWriteable},
	{@"Thresh_Rd",			0x0f0e,		-1,				kAugerRegReadable},
	{@"SwNextPage",			0x0f10,		-1,				kAugerRegWriteable},
	{@"SwSltTrigger",		0x0f12,		-1,				kAugerRegWriteable},
	{@"SwSetInhibit",		0x0f13,		-1,				kAugerRegWriteable},
	{@"SwRelInhibit",		0x0f14,		-1,				kAugerRegWriteable},
	{@"SwTestpulsTrigger",	0x0f20,		-1,				kAugerRegWriteable},
	{@"SwReadADC",			0x0f40,		-1,				kAugerRegWriteable},
	{@"SwSecondStrobe",		0x0f50,		-1,				kAugerRegWriteable},
	{@"ConfSltFPGAs",		0x0f51,		-1,				kAugerRegWriteable},
	{@"ConfFltFPGAs",		0x0f61,		-1,				kAugerRegWriteable},
	{@"ActResetFlt",		0x0f80,		-1,				kAugerRegWriteable},
	{@"RelResetFlt",		0x0f81,		-1,				kAugerRegWriteable},
	{@"ActResetSlt",		0x0f90,		-1,				kAugerRegWriteable},
	{@"RelResetSlt",		0x0f91,		-1,				kAugerRegWriteable},
	{@"ActualPage",			0x0102,		-1,				kAugerRegReadable},
	{@"NextPage",			0x0103,		-1,				kAugerRegReadable},
	{@"SetPageFree",		0x0105,		-1,				kAugerRegWriteable},
	{@"SetPageNoUse",		0x0106,		-1,				kAugerRegWriteable},
	{@"TimingMemory",		0x0200,		0xff,			kAugerRegReadable | kAugerRegWriteable},
	{@"TestpulsAmpl",		0x0300,		-1,				kAugerRegReadable | kAugerRegWriteable},
	{@"TestpulsStartSec",	0x0301,		-1,				kAugerRegReadable},
	{@"TestpulsStartSubSec",0x0302,		-1,				kAugerRegReadable},
	{@"SetSecCounter",		0x0500,		-1,				kAugerRegReadable | kAugerRegWriteable},
	{@"SecCounter",			0x0501,		-1,				kAugerRegReadable},
	{@"SubSecCounter",		0x0502,		-1,				kAugerRegReadable},
	{@"T1",					0x0503,		-1,				kAugerRegReadable | kAugerRegWriteable},
	{@"IRInput",			0x0f07,		-1,				kAugerRegReadable},
	{@"SltVersion",			0x0f08,		-1,				kAugerRegReadable},
	{@"VetoTimeLow",		0x0f0a,		-1,				kAugerRegReadable},
	{@"VetoTimeHigh",		0x0f09,		-1,				kAugerRegReadable},
	{@"DeadTimeLow",		0x0f0c,		-1,				kAugerRegReadable},
	{@"DeadTimeHigh",		0x0f0b,		-1,				kAugerRegReadable},
	{@"ResetDeadTime",		0x0f11,		-1,				kAugerRegReadable},
	{@"SensorMask",			0x0f20,		-1,				kAugerRegReadable | kAugerRegWriteable},
	{@"SensorStatus",		0x0f21,		-1,				kAugerRegReadable},
	{@"PageTimeStamp",		0x0000,		SLT_PAGES,		kAugerRegReadable},
	{@"LastTriggerTimeStamp",0x0080,	SLT_PAGES,		kAugerRegReadable},
	{@"TestpulsTiming",		0x0200,		256,			kAugerRegReadable | kAugerRegWriteable},
	{@"SensorData",			0x0400,		8,				kAugerRegReadable},
	{@"SensorConfig",		0x0408,		8,				kAugerRegReadable},
	{@"SensorUpperThresh",	0x0410,		8,				kAugerRegReadable},
	{@"SensorLowerThresh",	0x0418,		8,				kAugerRegReadable},
	{@"WatchDogMask",		0x0420,		-1,				kAugerRegReadable | kAugerRegWriteable},
	{@"WatchDogStatus",		0x0421,		-1,				kAugerRegReadable},
	{@"PageStatus",			0x0100,		SLT_PAGES/32,	kAugerRegReadable},
};

#define SLTID 21
#define SLT_REG_ADDRESS(A) ((SLTID << 24) | ((0x1) << 18) | reg[(A)].addressOffset)

//status reg bit positions
#define SLT_CRATEID				22
#define SLT_SLOTID				27
#define SLT_VETO				20
#define SLT_EXTINHIBIT			19

#define SLT_NOPGINHIBIT			18
#define SLT_SWINHIBIT			17
#define SLT_INHIBIT				16

#define SLT_RESETTRGFPGA		12
#define SLT_STANDBYFLT			11
#define SLT_RESETFLT			10
#define SLT_SUSPENDPLL			9
#define SLT_SUSPENDCLK			8

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

#define SLT_NHIT					8
#define SLT_NHIT_MASK			 0xff

#define SLT_NHIT_THRESHOLD			0
#define SLT_NHIT_THRESHOLD_MASK  0xff


#pragma mark ***External Strings
NSString* ORAugerSLTModelFpgaVersionChanged		= @"ORAugerSLTModelFpgaVersionChanged";
NSString* ORAugerSLTModelNHitThresholdChanged	= @"ORAugerSLTModelNHitThresholdChanged";
NSString* ORAugerSLTModelNHitChanged			= @"ORAugerSLTModelNHitChanged";
NSString* ORAugerSLTPulserDelayChanged			= @"ORAugerSLTPulserDelayChanged";
NSString* ORAugerSLTPulserAmpChanged			= @"ORAugerSLTPulserAmpChanged";
NSString* ORAugerSLTSettingsLock				= @"ORAugerSLTSettingsLock";
NSString* ORAugerSLTStatusRegChanged			= @"ORAugerSLTStatusRegChanged";
NSString* ORAugerSLTControlRegChanged			= @"ORAugerSLTControlRegChanged";
NSString* ORAugerSLTSelectedRegIndexChanged		= @"ORAugerSLTSelectedRegIndexChanged";
NSString* ORAugerSLTWriteValueChanged			= @"ORAugerSLTWriteValueChanged";

@implementation ORAugerSLTModel

- (id) init
{
    self = [super init];
    return self;
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fireWireInterface release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"AugerSLTCard"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORAugerSLTController"];
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
            
    [notifyCenter addObserver : self
                     selector : @selector(serviceChanged:)
                         name : @"ORFireWireInterfaceServiceAliveChanged"
                       object : [self fireWireInterface]];
    

    [notifyCenter addObserver : self
                     selector : @selector(runIsAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runIsStopped:)
                         name : ORRunStoppedNotification
                       object : nil];
}

- (void) releaseSwInhibit
{
	[self write:SLT_REG_ADDRESS(kSLTSwRelInhibit) value:0];
}

- (void) setSwInhibit
{
	[self write:SLT_REG_ADDRESS(kSLTSwSetInhibit) value:0];
}


- (void) runIsAboutToStart:(NSNotification*)aNote
{

    // Configure Slt
    // Write actual control register values to the hardware
	[self writeControlReg];

	// T1 = 0, no next page delay
	[self write:SLT_REG_ADDRESS(kSLTT1) value:0];	

	// Clear deadtime counters
	// Moved to the readout loop (see ORAugerFltModel.m)
	//[self write:SLT_REG_ADDRESS(kSLTResetDeadTime) value:0];		
	
	// Start data aquisition by central signal
	// Moved to the readout loop (see ORAugerFltModel.m)
	//[self releaseSwInhibit];
}

- (void) runIsStopped:(NSNotification*)aNote
{	
	// Stop all activities by software inhibit
	[self setSwInhibit];
	//[self write:SLT_REG_ADDRESS(kSLTSwSetInhibit) value:0];
	
	// TODO: Save dead time counters ?!
	// Is it sensible to send a new package here?
	// ak 18.7.07
	
	NSLogMono(@"----------------------------------------\n");
	NSLogMono(@"Crate/Card     : %2d / %2d\n", [self crateNumber], [self stationNumber]);
	NSLogMono(@"Deadtime       : %lld\n", [self readDeadTime]);
	
	
}

- (void) serviceChanged:(NSNotification*)aNote
{
	if([fireWireInterface serviceAlive]){
		[self checkAndLoadFPGAs];
		[self readVersion];
	}
}

- (void) checkAndLoadFPGAs
{
	BOOL doLoad = NO;
	NS_DURING
		NSArray* cards = [[self crate] orcaObjects];
		NSEnumerator* e = [cards objectEnumerator];
		id card;
		while (card = [e nextObject]){
			if([card isKindOfClass:NSClassFromString(@"ORAugerFLTModel")]){
				//try to access a card. if it throws then we have to load the FPGAs
				[card readControlStatus];
				break;	//only need to try one
			}
		}
	NS_HANDLER
		doLoad = YES;
	NS_ENDHANDLER

	NS_DURING
		if(doLoad){
			[self hw_config];
			[self hw_reset];
			NSLog(@"SLT loaded FLT FPGAs\n");
		}
	NS_HANDLER
		NSLogColor([NSColor redColor],@"SLT failed FLT FPGA load attempt\n");
	NS_ENDHANDLER
}


#pragma mark ¥¥¥Accessors
- (BOOL) usingNHitTriggerVersion
{
	if(fpgaVersion == 3.6)return YES;
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTModelFpgaVersionChanged object:self];
}

- (unsigned short) nHitThreshold
{
    return nHitThreshold;
}

- (void) setNHitThreshold:(unsigned short)aNHitThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNHitThreshold:nHitThreshold];
	
	if(aNHitThreshold>255)aNHitThreshold=255;
    
    nHitThreshold = aNHitThreshold;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTModelNHitThresholdChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTModelNHitChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTPulserDelayChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTPulserAmpChanged object:self];
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
        postNotificationName:ORAugerSLTSelectedRegIndexChanged
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
        postNotificationName:ORAugerSLTWriteValueChanged
                      object:self];
}

- (void) findInterface
{
	NS_DURING
		[self setFireWireInterface:[[self crate] getFireWireInterface:0x108]];
	NS_HANDLER
	NS_ENDHANDLER
}

//status reg values
- (BOOL) suspendClock
{
    return suspendClock;
}

- (void) setSuspendClock:(BOOL)aSuspendClock
{
	suspendClock = aSuspendClock;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTStatusRegChanged object:self];
}

- (BOOL) suspendPLL
{
    return suspendPLL;
}

- (void) setSuspendPLL:(BOOL)aSuspendPLL
{
	suspendPLL = aSuspendPLL;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTStatusRegChanged object:self];
}

- (BOOL) standbyFLT
{
    return standbyFLT;
}

- (void) setStandbyFLT:(BOOL)aStandbyFLT
{
	standbyFLT = aStandbyFLT;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTStatusRegChanged object:self];
}

- (BOOL) resetFLT
{
    return resetFLT;
}

- (void) setResetFLT:(BOOL)aResetFLT
{
	resetFLT = aResetFLT;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTStatusRegChanged object:self];
}

- (BOOL) resetTriggerFPGA
{
    return resetTriggerFPGA;
}

- (void) setResetTriggerFPGA:(BOOL)aResetTriggerFPGA
{
	resetTriggerFPGA = aResetTriggerFPGA;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTStatusRegChanged object:self];
}

- (BOOL) inhibit
{
    return inhibit;
}

- (void) setInhibit:(BOOL)aInhibit
{
	inhibit = aInhibit;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTStatusRegChanged object:self];
}

- (BOOL) swInhibit
{
    return swInhibit;
}

- (void) setSwInhibit:(BOOL)aSwInhibit
{
	swInhibit = aSwInhibit;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTStatusRegChanged object:self];
}

- (BOOL) nopgInhibit
{
    return nopgInhibit;
}

- (void) setNopgInhibit:(BOOL)aNopgInhibit
{
	nopgInhibit = aNopgInhibit;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTStatusRegChanged object:self];
}

- (BOOL) extInhibit
{
    return extInhibit;
}

- (void) setExtInhibit:(BOOL)aExtInhibit
{
	extInhibit = aExtInhibit;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTStatusRegChanged object:self];
}

- (BOOL) veto
{
    return veto;
}

- (void) setVeto:(BOOL)aVeto
{
	veto = aVeto;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTStatusRegChanged object:self];
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

		[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTControlRegChanged object:self];
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

		[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTControlRegChanged object:self];
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

		[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTControlRegChanged object:self];
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

		[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTControlRegChanged object:self];
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

		[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTControlRegChanged object:self];
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

		[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTControlRegChanged object:self];
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

		[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTControlRegChanged object:self];
	}
}

- (int) triggerSource
{	
    return triggerSource;
}

- (void) setTriggerSource:(int)aTriggerSource
{
    // Added button for no trigger source selected
	// TODO: Change interface to make combinations of trigger sources possible
	// ak 5.7.07
	
	if(aTriggerSource != 0 && aTriggerSource!= 1 && aTriggerSource!= 2 
	    && aTriggerSource!= 4 && aTriggerSource!= 8 && aTriggerSource!= 16) return;
		
	if(aTriggerSource != triggerSource) {
		[[[self undoManager] prepareWithInvocationTarget:self] setTriggerSource:triggerSource];
    
		triggerSource = aTriggerSource;

		[[NSNotificationCenter defaultCenter] postNotificationName:ORAugerSLTControlRegChanged object:self];
	}
}


#pragma mark ***HW Access
- (void) checkPresence
{
	NS_DURING
		[self readStatusReg];
		[self setPresent:YES];
	NS_HANDLER
		[self setPresent:NO];
	NS_ENDHANDLER
}

- (void) writeReg:(unsigned short)index value:(unsigned long)aValue
{
	[self write:SLT_REG_ADDRESS(index) value:aValue];
}

- (unsigned long) readReg:(unsigned short) index
{
	return [self read:SLT_REG_ADDRESS(index)];
}


- (unsigned long) readStatusReg
{
	unsigned long data = 0;

	data = [self read:SLT_REG_ADDRESS(kSLTStatusReg)];

	[self setVeto:				(data >> SLT_VETO)			& 0x1];
	[self setExtInhibit:		(data >> SLT_EXTINHIBIT)	& 0x1];	
	[self setNopgInhibit:		(data >> SLT_NOPGINHIBIT)	& 0x1];
	[self setSwInhibit:			(data >> SLT_SWINHIBIT)		& 0x1];
	[self setInhibit:			(data >> SLT_INHIBIT)		& 0x1];
	[self setResetTriggerFPGA:	(data >> SLT_RESETTRGFPGA)  & 0x1];
	[self setResetFLT:			(data >> SLT_RESETFLT)		& 0x1];
	[self setStandbyFLT:		(data >> SLT_STANDBYFLT)	& 0x1];
	[self setSuspendPLL:		(data >> SLT_SUSPENDPLL)	& 0x1];
	[self setSuspendClock:		(data >> SLT_SUSPENDCLK)	& 0x1];

	return data;
}

- (void) writeStatusReg
{
	unsigned long data = 0;
	data |= veto			 << SLT_VETO;
	data |= extInhibit		 << SLT_EXTINHIBIT;
	data |= nopgInhibit		 << SLT_NOPGINHIBIT;
	data |= swInhibit		 << SLT_SWINHIBIT;
	data |= inhibit			 << SLT_INHIBIT;
	data |= resetTriggerFPGA << SLT_RESETTRGFPGA;
	data |= resetFLT		 << SLT_RESETFLT;
	data |= standbyFLT		 << SLT_STANDBYFLT;
	data |= suspendPLL		 << SLT_SUSPENDPLL;
	data |= suspendClock	 << SLT_SUSPENDCLK;
	[self write:SLT_REG_ADDRESS(kSLTStatusReg) value:data];
}

- (unsigned long) readControlReg
{
	unsigned long data;

	data = [self read:SLT_REG_ADDRESS(kSLTControlReg)];

	[self setLedInhibit:			(data >> SLT_UPPERLED)      & SLT_UPPERLED_MASK];
	[self setLedVeto:				(data >> SLT_LOWERLED)      & SLT_LOWERLED_MASK];
	[self setTriggerSource:			(data >> SLT_TRIGGER_LOW)   & SLT_TRIGGER_MASK];
	[self setInhibitSource:			(data >> SLT_INHIBIT_LOW)   & SLT_INHIBIT_MASK];
	[self setTestPulseSource:		(data >> SLT_TESTPULS_LOW)  & SLT_TESTPULS_MASK];
	[self setSecStrobeSource:		(data >> SLT_SECSTROBE_LOW) & SLT_SECSTROBE_MASK];
	[self setWatchDogStart:		    (data >> SLT_WATCHDOGSTART_LOW) & SLT_WATCHDOGSTART_MASK];
	[self setEnableDeadTimeCounter: (data >> SLT_DEADTIMECOUNTERS)  & SLT_DEADTIMECOUNTERS_MASK];

	if(fpgaVersion == 3.5){
		data = [self read:SLT_REG_ADDRESS(kSLTThresh_Wr)];
		[self setNHit:			(data >> SLT_NHIT)			 & SLT_NHIT_MASK];
		[self setNHitThreshold:	(data >> SLT_NHIT_THRESHOLD) & SLT_NHIT_THRESHOLD_MASK];
	}
	
	return data;
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
	[self write:SLT_REG_ADDRESS(kSLTControlReg) value:data];


	if(fpgaVersion == 3.5){
		data = 0;
		data |= (nHit   & SLT_NHIT_MASK)   << SLT_NHIT;
		data |= (nHitThreshold & SLT_NHIT_THRESHOLD_MASK)   << SLT_NHIT_THRESHOLD;
		[self write:SLT_REG_ADDRESS(kSLTThresh_Wr) value:data];
	}
}

- (float) readVersion
{
	[self setFpgaVersion: [self read:SLT_REG_ADDRESS(kSLTVersion)]/10.];
	return fpgaVersion;
}

- (unsigned long long) readDeadTime
{
	unsigned long low  = [self read:SLT_REG_ADDRESS(kSLTDeadTimeLow)];
	unsigned long high = [self read:SLT_REG_ADDRESS(kSLTDeadTimeHigh)];
	return ((unsigned long long)high << 32) | low;
}

- (unsigned long long) readVetoTime
{
	unsigned long low  = [self read:SLT_REG_ADDRESS(kSLTVetoTimeLow)];
	unsigned long high = [self read:SLT_REG_ADDRESS(kSLTVetoTimeHigh)];
	return ((unsigned long long)high << 32) | low;
}

- (void) reset
{
	[self hw_config];
	[self hw_reset];
	[self hw_configure];
}



- (void) hw_config
{
	NSLog(@"SLT: HW Configure\n");
	[self write:SLT_REG_ADDRESS(kSLTConfFltFPGAs) value:0];
	[ORTimer delay:1.5];
	[self write:SLT_REG_ADDRESS(kSLTConfSltFPGAs) value:0];
	[ORTimer delay:1.5];
	[self read:SLT_REG_ADDRESS(kSLTStatusReg)];

	[guardian checkCards];

}

- (void) hw_reset
{
	NSLog(@"SLT: HW Reset\n");
	[self write:SLT_REG_ADDRESS(kSLTActResetFlt) value:0];
	[self write:SLT_REG_ADDRESS(kSLTActResetSlt) value:0];
	[self write:SLT_REG_ADDRESS(kSLTSwSltTrigger) value:0];
	[self write:SLT_REG_ADDRESS(kSLTRelResetFlt) value:0];
	[self write:SLT_REG_ADDRESS(kSLTRelResetSlt) value:0];
	
	
	[self write:SLT_REG_ADDRESS(kSLTSwRelInhibit) value:0];
	[self write:SLT_REG_ADDRESS(kSLTSwSetInhibit) value:0];
			
	[self readStatusReg];
	[self readControlReg];
}

- (void) hw_configure
{
    // Load KATRIN compatible configuration for the Slt master board
    // The experiment uses inhibit and trigger lines for central
	// control of the Flts.
	// 
	// Q: When is this function used?!
	//
	// ak 5.7.07
	 
	[self write:SLT_REG_ADDRESS(kSLTSwSetInhibit) value:0];
	[self setInhibitSource:0x3];
	[self setTriggerSource:0x1];	                         // enable software trigger, ak 5.7.07
	[self write:SLT_REG_ADDRESS(kSLTT1) value:0];            // Remove standard next page delay, ak 5.7.07
	[self setTestPulseSource:0x1];                           // enable SW start
	[self setSecStrobeSource:0x0];
	[self write:SLT_REG_ADDRESS(kSLTSwReadADC) value:0];
	[self write:SLT_REG_ADDRESS(kSLTIRMask) value:0x1ff];
	[self write:SLT_REG_ADDRESS(kSLTSubSecCounter) value:1399];
	[self write:SLT_REG_ADDRESS(kSLTSensorMask) value:0xff];
	[self readStatusReg];
	[self readControlReg];
}

- (void) loadPulseAmp
{
	unsigned short theConvertedAmp = pulserAmp * 4095./4.;
	[self write:SLT_REG_ADDRESS(kSLTTestpulsAmpl) value:theConvertedAmp];
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
	int savedTriggerSource = [self triggerSource];
	[self setTriggerSource:0x01]; //set for sw trigger
	[self writeControlReg];
	
	[self write:SLT_REG_ADDRESS(kSLTSwSltTrigger) value:0];	// send SW trigger
	
	[self setTriggerSource:savedTriggerSource];
	[self writeControlReg];
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
	[self setPulserDelay:			[decoder decodeFloatForKey:@"ORAugerSLTModelPulserDelay"]];
	[self setPulserAmp:				[decoder decodeFloatForKey:@"ORAugerSLTModelPulserAmp"]];
	[self setSuspendClock:			[decoder decodeBoolForKey:@"ORAugerSLTStatusSuspendClock"]];
	[self setSuspendPLL:			[decoder decodeBoolForKey:@"ORAugerSLTStatusSuspendPLL"]];
	[self setStandbyFLT:			[decoder decodeBoolForKey:@"ORAugerSLTStatusStandbyFLT"]];
	[self setResetFLT:				[decoder decodeBoolForKey:@"ORAugerSLTStatusResetFLT"]];
	[self setResetTriggerFPGA:		[decoder decodeBoolForKey:@"ORAugerSLTStatusResetTriggerFPGA"]];
	[self setInhibit:				[decoder decodeBoolForKey:@"ORAugerSLTStatusInhibit"]];
	[self setSwInhibit:				[decoder decodeBoolForKey:@"ORAugerSLTStatusSwInhibit"]];
	[self setNopgInhibit:			[decoder decodeBoolForKey:@"ORAugerSLTStatusNopgInhibit"]];
	[self setExtInhibit:			[decoder decodeBoolForKey:@"ORAugerSLTStatusExtInhibit"]];
	[self setVeto:					[decoder decodeBoolForKey:@"ORAugerSLTStatusVeto"]];

	//control reg
	[self setTriggerSource:			[decoder decodeIntForKey:@"triggerSource"]];
	[self setInhibitSource:			[decoder decodeIntForKey:@"inhibitSource"]];
	[self setTestPulseSource:		[decoder decodeIntForKey:@"testPulseSource"]];
	[self setSecStrobeSource:		[decoder decodeIntForKey:@"secStrobeSource"]];
	[self setWatchDogStart:			[decoder decodeIntForKey:@"watchDogStart"]];
	[self setEnableDeadTimeCounter:	[decoder decodeIntForKey:@"enableDeadTimeCounter"]];

	//special
	[self setNHitThreshold:			[decoder decodeIntForKey:@"ORAugerSLTModelNHitThreshold"]];
	[self setNHit:					[decoder decodeIntForKey:@"ORAugerSLTModelNHit"]];


	[[self undoManager] enableUndoRegistration];

	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	
	//status reg
	[encoder encodeFloat:pulserDelay	 forKey:@"ORAugerSLTModelPulserDelay"];
	[encoder encodeFloat:pulserAmp		 forKey:@"ORAugerSLTModelPulserAmp"];
	[encoder encodeBool:suspendClock	 forKey:@"ORAugerSLTStatusSuspendClock"];
	[encoder encodeBool:suspendPLL		 forKey:@"ORAugerSLTStatusSuspendPLL"];
	[encoder encodeBool:standbyFLT		 forKey:@"ORAugerSLTStatusStandbyFLT"];
	[encoder encodeBool:resetFLT		 forKey:@"ORAugerSLTStatusResetFLT"];
	[encoder encodeBool:resetTriggerFPGA forKey:@"ORAugerSLTStatusResetTriggerFPGA"];
	[encoder encodeBool:inhibit			 forKey:@"ORAugerSLTStatusInhibit"];
	[encoder encodeBool:swInhibit		 forKey:@"ORAugerSLTStatusSwInhibit"];
	[encoder encodeBool:nopgInhibit		 forKey:@"ORAugerSLTStatusNopgInhibit"];
	[encoder encodeBool:extInhibit		 forKey:@"ORAugerSLTStatusExtInhibit"];
	[encoder encodeBool:veto			 forKey:@"ORAugerSLTStatusVeto"];

	//control reg
	[encoder encodeInt:triggerSource	forKey:@"triggerSource"];
	[encoder encodeInt:inhibitSource	forKey:@"inhibitSource"];
	[encoder encodeInt:testPulseSource	forKey:@"testPulseSource"];
	[encoder encodeInt:secStrobeSource	forKey:@"secStrobeSource"];
	[encoder encodeInt:watchDogStart	forKey:@"watchDogStart"];
	[encoder encodeInt:enableDeadTimeCounter	forKey:@"enableDeadTimeCounter"];


	//special
	[encoder encodeInt:nHitThreshold	 forKey:@"ORAugerSLTModelNHitThreshold"];
	[encoder encodeInt:nHit				 forKey:@"ORAugerSLTModelNHit"];

}


@end
