//-------------------------------------------------------------------------
//  ORSIS3820Model.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORSIS3820Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "VME_HW_Definitions.h"
#import "ORCommandList.h"
#import "ORVmeReadWriteCommand.h"

NSString* ORSIS3820ModelShowDeadTimeChanged			 = @"ORSIS3820ModelShowDeadTimeChanged";
NSString* ORSIS3820ModelDeadTimeRefChannelChanged	 = @"ORSIS3820ModelDeadTimeRefChannelChanged";
NSString* ORSIS3820ModelInvertLemoOutChanged		 = @"ORSIS3820ModelInvertLemoOutChanged";
NSString* ORSIS3820ModelInvertLemoInChanged			 = @"ORSIS3820ModelInvertLemoInChanged";
NSString* ORSIS3820ModelLemoOutModeChanged			 = @"ORSIS3820ModelLemoOutModeChanged";
NSString* ORSIS3820ModelIsCountingChanged			 = @"ORSIS3820ModelIsCountingChanged";
NSString* ORSIS3820ModelSyncWithRunChanged			 = @"ORSIS3820ModelSyncWithRunChanged";
NSString* ORSIS3820ModelClearOnRunStartChanged		 = @"ORSIS3820ModelClearOnRunStartChanged";
NSString* ORSIS3820ModelEnableReferencePulserChanged = @"ORSIS3820ModelEnableReferencePulserChanged";
NSString* ORSIS3820ModelEnableCounterTestModeChanged = @"ORSIS3820ModelEnableCounterTestModeChanged";
NSString* ORSIS3820ModelEnable25MHzPulsesChanged	 = @"ORSIS3820ModelEnable25MHzPulsesChanged";
NSString* ORSIS3820ModelLemoInModeChanged			 = @"ORSIS3820ModelLemoInModeChanged";
NSString* ORSIS3820ModelCountEnableMaskChanged		 = @"ORSIS3820ModelCountEnableMaskChanged";
NSString* ORSIS3820SettingsLock						 = @"ORSIS3820SettingsLock";
NSString* ORSIS3820ModelIDChanged					 = @"ORSIS3820ModelIDChanged";
NSString* ORSIS3820CountersChanged					 = @"ORSIS3820CountersChanged";
NSString* ORSIS3820ModelOverFlowMaskChanged			 = @"ORSIS3820ModelOverFlowMaskChanged";
NSString* ORSIS3820PollTimeChanged					 = @"ORSIS3820PollTimeChanged";
NSString* ORSIS3820ChannelNameChanged				 = @"ORSIS3820ChannelNameChanged";
NSString* ORSIS3820ModelShipAtRunEndOnlyChanged		 = @"ORSIS3820ModelShipAtRunEndOnlyChanged";

//general register offsets
#define kControlStatus				0x00	
#define kModuleIDReg				0x04
#define kInterruptConfigReg			0x08
#define kInterruptControlReg		0x08
#define kAcquisitionPreset			0x10
#define kAcquisitionCount			0x14
#define kLNEPrescaleFactor			0x18
#define kPresetValueCounterGroup1	0x20
#define kPresetValueCounterGroup2	0x24
#define kPresetEnableAndHit			0x28
#define kCBLTBroadcastSetup			0x30
#define kSDRAMEPageReg				0x34
#define kFIFOWordCount				0x38
#define kFIFOWordCountThreshold		0x3C
#define kAcqOpMode					0x100
#define kCopyDisable				0x104
#define kLNEChannelSelect			0x108
#define kPresetChannelSelect		0x10C
#define kInhibitCountDisable		0x200
#define kCounterClear				0x204
#define kCounterOverflowRdAndClr	0x208
#define kJohnsonError				0x20C //SIS Internal Use
#define kKeyReset					0x400
#define kKeySDRAMFIFOReset			0x404
#define kKeyTestPulse				0x408
#define kKeyCounterClear			0x414
#define kKeyVmeLneClockShadow		0x410
#define kKeyOpArm					0x414
#define kKeyOpEnable				0x418
#define kKeyOpDisable				0x41C
#define kShadowRegisters			0x800	//0x800  to 0x87C
#define kCounterRegisters			0xA00	//0xA00  to 0xA7C
#define kSDRAMorFIFO				0x800000 //0x800000  to 0xfffffc

//bits in the status reg
#define kStatusUserLED					(1L<<0)
#define kStatus25MHzTestPulses			(1L<<4)
#define kStatusInputTestMode			(1L<<5)
#define kStatusReferencePulser			(1L<<6)
#define kStatusOpScalerEnabled			(1L<<16)
#define kStatusOpMCSEnabled				(1L<<17)
#define kStatusOpSDRAMFIFOEnabled		(1L<<23)
#define kStatusOpArmed					(1L<<24)
#define kStatusOverflow					(1L<<25)
#define kStatusExtInputBit1				(1L<<28)
#define kStatusExtInputBit2				(1L<<29)
#define kStatusExtLatchBit1				(1L<<30)
#define kStatusExtLatchBit2				(1L<<31)

//bits in the control reg
#define kSwitchUserLEDOn				(1L<<0)
#define kEnable25MHzTestPulses			(1L<<4)
#define kEnableCounterTestMode			(1L<<5)
#define kSwitchOnRefPulser				(1L<<6)
#define kSwitchUserLEDOff				(1L<<16)
#define kDisable25MHzTestPulses			(1L<<20)
#define kCounterTestMode				(1L<<21)
#define kSwitchOffRefPulser				(1L<<22)

#define kSIS3820DataLen (7+32)

@interface ORSIS3820Model (private)
- (void) shipData;
- (void) logTime;
- (void) executeCommandList:(ORCommandList*) aList;
@end

@implementation ORSIS3820Model

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x38000000];
	[self setPollTime:0];
	[self setDefaults];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super sleep];
}

- (void) wakeUp
{
	[super wakeUp];
	if(pollTime){
		[self timeToPoll];
	}
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3820Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3820Controller"];
}

- (NSString*) helpURL
{
	return @"VME/SIS3820.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x1000000);
}

#pragma mark ***Accessors

- (BOOL) showDeadTime
{
    return showDeadTime;
}

- (void) setShowDeadTime:(BOOL)aShowDeadTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowDeadTime:showDeadTime];
    
    showDeadTime = aShowDeadTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelShowDeadTimeChanged object:self];
}

- (int) deadTimeRefChannel
{
    return deadTimeRefChannel;
}

- (void) setDeadTimeRefChannel:(int)aDeadTimeRefChannel
{
	if(aDeadTimeRefChannel<=0)aDeadTimeRefChannel = 0;
	else if(aDeadTimeRefChannel>31)aDeadTimeRefChannel=31;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setDeadTimeRefChannel:deadTimeRefChannel];
    
    deadTimeRefChannel = aDeadTimeRefChannel;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelDeadTimeRefChannelChanged object:self];
}
- (NSString*) channelName:(int)i
{
	if(i>=0 && i<32){
		if([channelName[i] length])return channelName[i];
		else return [NSString stringWithFormat:@"Channel %2d",i];
	}
	else return @"";
}

- (void) setChannel:(int)i name:(NSString*)aName
{
	if(i>=0 && i<32){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:i name:channelName[i]];
		
		[channelName[i] autorelease];
		channelName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ChannelNameChanged object:self userInfo:userInfo];
		
	}
}

- (BOOL) shipAtRunEndOnly
{
    return shipAtRunEndOnly;
}

- (void) setShipAtRunEndOnly:(BOOL)aShipAtRunEndOnly
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipAtRunEndOnly:shipAtRunEndOnly];
    
    shipAtRunEndOnly = aShipAtRunEndOnly;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelShipAtRunEndOnlyChanged object:self];
}

- (BOOL) invertLemoOut
{
    return invertLemoOut;
}

- (void) setInvertLemoOut:(BOOL)aInvertLemoOut
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInvertLemoOut:invertLemoOut];
    
    invertLemoOut = aInvertLemoOut;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelInvertLemoOutChanged object:self];
}

- (BOOL) invertLemoIn
{
    return invertLemoIn;
}

- (void) setInvertLemoIn:(BOOL)aInvertLemoIn
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInvertLemoIn:invertLemoIn];
    
    invertLemoIn = aInvertLemoIn;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelInvertLemoInChanged object:self];
}

- (int) lemoOutMode
{
    return lemoOutMode;
}

- (void) setLemoOutMode:(int)aLemoOutMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoOutMode:lemoOutMode];
    
    lemoOutMode = aLemoOutMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelLemoOutModeChanged object:self];
}

- (BOOL) isCounting
{
    return isCounting;
}

- (void) setIsCounting:(BOOL)aState
{
	if(aState != isCounting){
		isCounting = aState;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelIsCountingChanged object:self];
	}
}

- (BOOL) syncWithRun
{
    return syncWithRun;
}

- (void) setSyncWithRun:(BOOL)aSyncWithRun
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSyncWithRun:syncWithRun];
    syncWithRun = aSyncWithRun;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelSyncWithRunChanged object:self];
}

- (BOOL) clearOnRunStart
{
    return clearOnRunStart;
}

- (void) setClearOnRunStart:(BOOL)aClearOnRunStart
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClearOnRunStart:clearOnRunStart];
    clearOnRunStart = aClearOnRunStart;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelClearOnRunStartChanged object:self];
}

- (float) convertedPollTime
{
	//if you change this you have to change the popup in the dialog as well
	float convertedPollTime[8] = {0,.5,1,2,5,10,20,60};
	if(pollTime>=0 && pollTime<8){
		return convertedPollTime[pollTime];
	}
	else return 0.0;
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820PollTimeChanged object:self];
	
	if(pollTime){
		[self performSelector:@selector(timeToPoll) withObject:nil afterDelay:0];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeToPoll) object:nil];
	}
}

- (void) timeToPoll
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeToPoll) object:nil];
	@try {
		[self readCounts:NO];
		[self shipData];
	}
	@catch (NSException* e){
	}
	if(pollTime>0){
		[self performSelector:@selector(timeToPoll) withObject:nil afterDelay:[self convertedPollTime]];
	}
}

- (BOOL) enableReferencePulser
{
    return enableReferencePulser;
}

- (void) setEnableReferencePulser:(BOOL)aEnableReferencePulser
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableReferencePulser:enableReferencePulser];
    enableReferencePulser = aEnableReferencePulser;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelEnableReferencePulserChanged object:self];
}

- (BOOL) enableCounterTestMode
{
    return enableCounterTestMode;
}

- (void) setEnableCounterTestMode:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableCounterTestMode:enableCounterTestMode];
    enableCounterTestMode = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelEnableCounterTestModeChanged object:self];
}

- (BOOL) enable25MHzPulses
{
    return enable25MHzPulses;
}

- (void) setEnable25MHzPulses:(BOOL)aEnable25MHzPulses
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnable25MHzPulses:enable25MHzPulses];
    enable25MHzPulses = aEnable25MHzPulses;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelEnable25MHzPulsesChanged object:self];
}




- (int) lemoInMode
{
    return lemoInMode;
}

- (void) setLemoInMode:(int)aLemoInMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoInMode:lemoInMode];
    lemoInMode = aLemoInMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelLemoInModeChanged object:self];
}

- (uint32_t) counts:(int)i
{
	if(i>=0 && i<32)return counts[i];
	else return 0;
}

- (uint32_t) countEnableMask { return countEnableMask; }
- (void) setCountEnableMask:(uint32_t)aCountEnableMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCountEnableMask:countEnableMask];
    countEnableMask = aCountEnableMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelCountEnableMaskChanged object:self];
}

- (BOOL) countEnabled:(short)chan { return countEnableMask & (1<<chan); }
- (void) setCountEnabled:(short)chan withValue:(BOOL)aValue		
{ 
	NSLog(@"setting %d to %d\n",chan,aValue);
	uint32_t aMask = countEnableMask;
	if(aValue)aMask |= (1L<<chan);
	else aMask &= ~(1L<<chan);
	[self setCountEnableMask:aMask];
}

- (uint32_t) overFlowMask { return overFlowMask; }
- (void) setOverFlowMask:(uint32_t)aMask
{
    overFlowMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelOverFlowMaskChanged object:self];
}

- (void) setDefaults
{
	int i;
	for(i=0;i<32;i++){
		[self setCountEnabled:i withValue:YES];
	}
}

- (unsigned short) moduleID;
{
	return moduleID;
}

#pragma mark •••Hardware Access
- (void) generateTestPulse
{
	uint32_t aValue = 0;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kKeyTestPulse
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
}

- (void) arm
{
	uint32_t result = 0;
	[[self adapter] writeLongBlock:&result
						atAddress:[self baseAddress] + kKeyOpArm
                        numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
}

- (void) readModuleID:(BOOL)verbose
{	
	uint32_t result = 0;
	[[self adapter] readLongBlock:&result
                         atAddress:[self baseAddress] + kModuleIDReg
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	moduleID = result >> 16;
	majorRevision = (result&0xff00) >> 8;
	minorRevision = (result & 0xff) >> 0;
	if(verbose)NSLog(@"SIS3820 ID: %x  0x%02x.%d\n",moduleID,majorRevision,minorRevision);
	if(moduleID != 0x3820) {
		NSLogColor([NSColor redColor],@"Slot %d has a %04x but you are using a SIS3820 object.\n",[self slot],moduleID);
	}
	else {
		if(majorRevision != 1)NSLogColor([NSColor redColor],@"Wrong Firmware version. ORCA currently supports only the Generic 32 channel design\n");
	}

	[self readStatusRegister];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820ModelIDChanged object:self];
}

- (unsigned short) majorRevision 
{
	return majorRevision;
	
}
- (void) readStatusRegister
{		
	uint32_t aMask = 0;
	[[self adapter] readLongBlock:&aMask
                         atAddress:[self baseAddress] + kControlStatus
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	[self setIsCounting: (aMask & kStatusOpScalerEnabled)==kStatusOpScalerEnabled ];
}

- (void) writeControlRegister
{
	uint32_t aMask = 0x0;
	aMask |= 
	((enable25MHzPulses & 0x1) << 4)		|
	((enableCounterTestMode & 0x1) << 5)	|
	((enableReferencePulser & 0x1) << 6)	|
	((~enable25MHzPulses & 0x1) << 20)		|
	((~enableCounterTestMode & 0x1) << 21)	|
	((~enableReferencePulser & 0x1) << 22);
			  
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeAcquisitionRegister
{
	uint32_t aMask = 0x0;
	aMask |= ((lemoInMode  & 0x7) << 16) |
			 ((lemoOutMode & 0x3) << 20) |
			 ((invertLemoOut & 0x1) << 23) |
			 ((invertLemoIn & 0x1) << 19) |
			 0x1; //we currently default to the non-clearing mode Manual sec 14.6

	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kAcqOpMode
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) setLed:(BOOL)state
{
	uint32_t aValue;
	if(state)	aValue = kSwitchUserLEDOn;
	else		aValue = kSwitchUserLEDOff;
	
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) initBoard
{  
	[self writeControlRegister];
	[self writeAcquisitionRegister];
	[self writeCountEnableMask];
	[self readStatusRegister];
}

- (void) clockShadow
{
	uint32_t aValue = 0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kKeyVmeLneClockShadow
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) readCounts:(BOOL)clear
{
	[self clockShadow];
	ORCommandList* aList = [ORCommandList commandList];
	int i;
	for(i=0;i<32;i++){
			[aList addCommand: [ORVmeReadWriteCommand readLongBlockAtAddress: [self baseAddress] + kShadowRegisters + (4*i)
																   numToRead: 1
																  withAddMod: [self addressModifier]
															   usingAddSpace: 0x01]];
	}
	[self executeCommandList:aList];
	
	//if we get here, the results can retrieved in the same order as sent
	for(i=0;i<32;i++){
		counts[i] = [aList longValueForCmd:i];
	}
	[self readOverFlowRegister];
	if(clear){
		uint32_t aValue = 0xffffffff;
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress] + kCounterClear
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
	[self logTime];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820CountersChanged object:self];

}


- (void) readOverFlowRegister
{
	uint32_t aValue = 0;
	[[self adapter] readLongBlock:&aValue
						 atAddress:[self baseAddress] + kCounterOverflowRdAndClr
						 numToRead: 1
						withAddMod: [self addressModifier]
					 usingAddSpace: 0x01];
	
	[self setOverFlowMask:aValue];
	
	[[self adapter] readLongBlock:&aValue
						 atAddress: [self baseAddress] + kControlStatus
						 numToRead: 1
						withAddMod: [self addressModifier]
					 usingAddSpace: 0x01];
	
	[self setIsCounting: (aValue& kStatusOpScalerEnabled)==kStatusOpScalerEnabled ];
	
}

- (void) writeCountEnableMask
{
	uint32_t aValue = ~countEnableMask;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kInhibitCountDisable
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) clearAllOverFlowFlags
{
	uint32_t aMask = 0xffffffff;
	[[self adapter] writeLongBlock:&aMask
						 atAddress:[self baseAddress] + kCounterOverflowRdAndClr
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];

	[self readOverFlowRegister];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820CountersChanged object:self];	
}

- (void) clearAll
{
	uint32_t aValue = 0xffffffff;
	[[self adapter] writeLongBlock:&aValue
					atAddress:[self baseAddress] + kCounterClear
					numToWrite:1
					withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	int i;
	for(i=0;i<32;i++){
		counts[i] = 0;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820CountersChanged object:self];	
}

- (void) clearCounter:(int)i
{
	uint32_t aMask = (uint32_t)(1L<<i);
	
	[[self adapter] writeLongBlock:&aMask
						 atAddress:[self baseAddress] + kCounterClear
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	counts[i] = 0;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820CountersChanged object:self];	
}

- (void) enableReferencePulser:(BOOL)state
{
	uint32_t aValue = (state?kSwitchOnRefPulser:kSwitchOnRefPulser);

	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kControlStatus
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3820CountersChanged object:self];	
}

#pragma mark •••Data Taker
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORSIS3820DecoderForCounts",				@"decoder",
								 [NSNumber numberWithLong:dataId],			@"dataId",
								 [NSNumber numberWithBool:NO],				@"variable",
								 [NSNumber numberWithLong:kSIS3820DataLen],	@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Counts"];
    
    return dataDictionary;
}

#pragma mark •••HW Wizard

- (int) numberOfChannels
{
    return kNumSIS3820Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enable Counters"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setCountEnabled:withValue:) getMethod:@selector(countEnabled:)];
    [a addObject:p];	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORSIS3820Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORSIS3820Model"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    id obj = [cardDictionary objectForKey:param];
    if(obj)return obj;
    else return [[cardDictionary objectForKey:param] objectAtIndex:aChannel];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[objDictionary setObject:[NSNumber numberWithLong:countEnableMask] forKey:@"countEnableMask"];

	uint32_t options =	
		lemoInMode				 | 
		enable25MHzPulses<<3	 | 
		enableCounterTestMode<<4	 |
		enableReferencePulser<<5 |
		clearOnRunStart<<6		 |
		syncWithRun<<7;
	
	[objDictionary setObject:[NSNumber numberWithLong:options] forKey:@"options"];
	
    return objDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3820Model"];    
    
    //cache some stuff
  	if(!moduleID)[self readModuleID:NO];
	lastTimeMeasured = 0;
    [self initBoard];
	if([self clearOnRunStart]){
		[self clearAll];
	}
	if([self syncWithRun]){
		[self startCounting]; //also does initBoard
	}
	else [self initBoard]; 

	[self setLed:YES];
	isRunning = NO;
	endOfRun = NO;
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	//nothing to do for this card
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	if([self syncWithRun]){
		[self stopCounting];
	}
	endOfRun = YES;
	[self timeToPoll];
	[self setLed:NO];
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{	
	//we don't let the SBC do anything so no point in loading a config
	return index;
}

- (void) reset
{
 	uint32_t aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kKeyReset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	[self readStatusRegister];
}

- (void) startCounting
{
	[self initBoard];
 	uint32_t aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kKeyOpEnable
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	[self readStatusRegister];
	[self timeToPoll];
}

- (void) stopCounting
{
	uint32_t aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kKeyOpDisable
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	[self readStatusRegister];
}

- (void) dumpCounts
{
	NSFont* aFont =[NSFont fontWithName:@"Monaco" size:11];
	NSLogFont(aFont, @"SIS3820,%d,%d Scaler Counts\n",[self crateNumber],[self slot]);
	int i;
	for(i=0;i<32;i++){
		NSLogFont(aFont, @"%2d : %11u\n",i,counts[i]);
	}
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setShowDeadTime:[decoder decodeBoolForKey:@"showDeadTime"]];
    [self setDeadTimeRefChannel:[decoder decodeIntForKey:@"deadTimeRefChannel"]];
	[self setShipAtRunEndOnly:[decoder decodeBoolForKey:@"shipAtRunEndOnly"]];
	[self setInvertLemoOut:[decoder decodeBoolForKey:@"invertLemoOut"]];
    [self setInvertLemoIn:[decoder decodeBoolForKey:@"invertLemoIn"]];
    [self setLemoOutMode:[decoder decodeIntForKey:@"lemoOutMode"]];
    [self setSyncWithRun:[decoder decodeBoolForKey:@"syncWithRun"]];
    [self setClearOnRunStart:[decoder decodeBoolForKey:@"clearOnRunStart"]];
    [self setEnableReferencePulser:[decoder decodeBoolForKey:@"enableReferencePulser"]];
    [self setEnableCounterTestMode:[decoder decodeBoolForKey:@"enableCounterTestMode"]];
    [self setEnable25MHzPulses:[decoder decodeBoolForKey:@"enable25MHzPulses"]];
    [self setLemoInMode:[decoder decodeIntForKey:@"lemoInMode"]];
    [self setPollTime:[decoder decodeIntForKey:@"pollTime"]];
    [self setCountEnableMask:[decoder decodeIntForKey:@"countEnableMask"]];
	int i;
	for(i=0;i<32;i++) {
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"channelName%d",i]];
		if(aName)[self setChannel:i name:aName];
		else [self setChannel:i name:[NSString stringWithFormat:@"Channel %2d",i]];
	}
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeBool:showDeadTime forKey:@"showDeadTime"];
	[encoder encodeInteger:deadTimeRefChannel forKey:@"deadTimeRefChannel"];
	[encoder encodeBool:shipAtRunEndOnly forKey:@"shipAtRunEndOnly"];
	[encoder encodeBool:invertLemoOut forKey:@"invertLemoOut"];
    [encoder encodeBool:invertLemoIn forKey:@"invertLemoIn"];
    [encoder encodeInt:lemoOutMode forKey:@"lemoOutMode"];
    [encoder encodeBool:syncWithRun forKey:@"syncWithRun"];
    [encoder encodeBool:clearOnRunStart forKey:@"clearOnRunStart"];
    [encoder encodeBool:enableReferencePulser forKey:@"enableReferencePulser"];
    [encoder encodeBool:enableCounterTestMode forKey:@"enableCounterTestMode"];
    [encoder encodeBool:enable25MHzPulses forKey:@"enable25MHzPulses"];
    [encoder encodeInteger:lemoInMode forKey:@"lemoInMode"];
    [encoder encodeInteger:pollTime forKey:@"pollTime"];
    [encoder encodeInt:countEnableMask forKey:@"countEnableMask"];
	int i;
	for(i=0;i<32;i++) {
		[encoder encodeObject:channelName[i] forKey:[NSString stringWithFormat:@"channelName%d",i]];
	}
}

@end

@implementation ORSIS3820Model (private)
- (void) logTime
{
	time_t	ut_Time;
	time(&ut_Time);
	timeMeasured = (uint32_t)ut_Time;
}

- (void) shipData
{
	if([[ORGlobal sharedGlobal] runInProgress]){
		if(!shipAtRunEndOnly || endOfRun){
			endOfRun = NO;
			uint32_t data[kSIS3820DataLen];
			data[0] = dataId | kSIS3820DataLen;
			data[1] = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
			if(moduleID == 3820)data[1] |= 1;
			
			data[2] = timeMeasured;
			data[3] = lastTimeMeasured;
			data[4] = countEnableMask;
			data[5] = overFlowMask;
			
			data[6] =	
				lemoInMode |
				enable25MHzPulses<<3 |
				enableCounterTestMode<<4 |
				enableReferencePulser<<5 |
				clearOnRunStart<<6 |
				syncWithRun<<7;
			   
			int i;
			for(i=0;i<32;i++){
				data[7+i] = counts[i];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(int32_t)*kSIS3820DataLen]];
			lastTimeMeasured = timeMeasured;
		}
	}
}

- (void) executeCommandList:(ORCommandList*) aList
{
	[[self adapter] executeCommandList:aList];
}

@end

