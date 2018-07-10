//-------------------------------------------------------------------------
//  ORSIS3801Model.h
//
//  Created by Mark A. Howe on Thursday 6/9/11.
//  Copyright (c) 2011 CENPA. University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORSIS3801Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORCommandList.h"
#import "ORVmeReadWriteCommand.h"

NSString* ORSIS3801ModelShowDeadTimeChanged			 = @"ORSIS3801ModelShowDeadTimeChanged";
NSString* ORSIS3801ModelDeadTimeRefChannelChanged	 = @"ORSIS3801ModelDeadTimeRefChannelChanged";
NSString* ORSIS3801ModelShipAtRunEndOnlyChanged		 = @"ORSIS3801ModelShipAtRunEndOnlyChanged";
NSString* ORSIS3801ModelIsCountingChanged			 = @"ORSIS3801ModelIsCountingChanged";
NSString* ORSIS3801ModelSyncWithRunChanged			 = @"ORSIS3801ModelSyncWithRunChanged";
NSString* ORSIS3801ModelClearOnRunStartChanged		 = @"ORSIS3801ModelClearOnRunStartChanged";
NSString* ORSIS3801ModelEnableReferencePulserChanged = @"ORSIS3801ModelEnableReferencePulserChanged";
NSString* ORSIS3801ModelEnableInputTestModeChanged	 = @"ORSIS3801ModelEnableInputTestModeChanged";
NSString* ORSIS3801ModelEnable25MHzPulsesChanged	 = @"ORSIS3801ModelEnable25MHzPulsesChanged";
NSString* ORSIS3801ModelLemoInModeChanged			 = @"ORSIS3801ModelLemoInModeChanged";
NSString* ORSIS3801ModelCountEnableMaskChanged		 = @"ORSIS3801ModelCountEnableMaskChanged";
NSString* ORSIS3801SettingsLock						 = @"ORSIS3801SettingsLock";
NSString* ORSIS3801ModelIDChanged					 = @"ORSIS3801ModelIDChanged";
NSString* ORSIS3801CountersChanged					 = @"ORSIS3801CountersChanged";
NSString* ORSIS3801ModelOverFlowMaskChanged			 = @"ORSIS3801ModelOverFlowMaskChanged";
NSString* ORSIS3801PollTimeChanged					 = @"ORSIS3801PollTimeChanged";
NSString* ORSIS3801ChannelNameChanged				 = @"ORSIS3801ChannelNameChanged";

//general register offsets
#define kControlStatus				 0x000	
#define kModuleIDReg				 0x004	
#define kCopyDisable				 0x00C
#define kWriteToFIFO				 0x010
#define kClearFIFO					 0x020
#define kVMENextClock				 0x024
#define kEnableNextClockLogic		 0x028
#define kDisableNextClockLogic		 0x02C
#define kEnableReferencePulserChan1  0x050
#define kDisableReferencePulserChan1 0x054
#define kGlobalReset				 0x060
#define kTestPulse					 0x068
#define kPrescaleFactor				 0x080
#define kFifoBuffer					 0x100
 

//bits in the status reg
#define kStatusUserLED				(1L<<0)
#define kStatusFifoTestMode		    (1L<<1)
#define kStatusInputModeBit0		(1L<<2)
#define kStatusInputModeBit1		(1L<<3)
#define kStatus25MHzTestPulses		(1L<<4)
#define kStatusInputTestMode		(1L<<5)
#define kStatus10MHztoLNEPrescaler	(1L<<6)
#define kStatusEnableLNEPrescaler	(1L<<7)
#define kFifoFlagEmpty				(1L<<8)
#define kFifoFlagAlmostEmpty		(1L<<9)
#define kFifoFlagHalfFull			(1L<<10)
#define kFifoFlagAlmostFull			(1L<<11)
#define kFifoFlagFull				(1L<<12)
#define kStatusEnableRefPulserChan1	(1L<<13)
//bit 14 == 0
#define kStatusEnableNextLogic		(1L<<15)
#define kStatusEnableExternalNext	(1L<<16)
#define kStatusEnableExternalClear	(1L<<17)
#define kStatusExternalDisable		(1L<<18)
#define kSoftwareDisableCountingBit	(1L<<19) //(0=count enable, 1=count disable)
#define kStatusVMEIRQEnableBitSrc0	(1L<<20)
#define kStatusVMEIRQEnableBitSrc1	(1L<<21)
#define kStatusVMEIRQEnableBitSrc2	(1L<<22)
#define kStatusVMEIRQEnableBitSrc3	(1L<<23)
//bit 24 == 0
//bit 25 == 0
#define kInternalVMEIRQ				(1L<<26)
#define kVMEIRQ						(1L<<27)
#define kStatusVMEIRQBitSrc0		(1L<<28)
#define kStatusVMEIRQBitSrc1		(1L<<29)
#define kStatusVMEIRQBitSrc2		(1L<<30)
#define kStatusVMEIRQBitSrc3		(1L<<31)


//bits in the control reg
#define kSwitchUserLEDOn			(1L<<0)
#define kEnableFifoTestMode			(1L<<1)
#define kSetInputModeBit0			(1L<<2)
#define kSetInputModeBit1			(1L<<3)
#define kEnable25MHzTestPulses		(1L<<4)
#define kEnableInputTestMode		(1L<<5)
#define kEnable10MhzToLNEPrescaler	(1L<<6)
#define kEnableLNEPrescaler			(1L<<7)
#define kSwitchUserLEDOff			(1L<<8)
#define kDisableFifoTestMode		(1L<<9)
#define kClearInputModeBit0			(1L<<10)
#define kClearInputModeBit1			(1L<<11)
#define kDisable25MHzTestPulses		(1L<<12)
#define kDisableIputTestMode		(1L<<13)
#define kDisable10MHzToLNEPrescaler	(1L<<14)
#define kDisableLNEPrescaler		(1L<<15)
#define kEnableExternalNext			(1L<<16)
#define kEnableExternalClear		(1L<<17)
#define kEnableExternalDisable		(1L<<18)
#define kSetSoftwareDisableCounting	(1L<<19)
#define kEnableIRQSource0			(1L<<20)
#define kEnableIRQSource1			(1L<<21)
#define kEnableIRQSource2			(1L<<22)
#define kEnableIRQSource3			(1L<<23)
#define kDisableExternalNext		(1L<<24)
#define kDisableExternalClear		(1L<<25)
#define kDisableExternalDisable		(1L<<26)
#define kClrSoftwareDisableCounting	(1L<<27)
#define kDisableIRQSource0			(1L<<28)
#define kDisableIRQSource1			(1L<<29)
#define kDisableIRQSource2			(1L<<30)
#define kDisableIRQSource3			(1L<<31)

#define kSIS3801DataLen (7+32)

@interface ORSIS3801Model (private)
- (void) shipData;
- (void) logTime;
- (void) executeCommandList:(ORCommandList*) aList;
@end

@implementation ORSIS3801Model

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x00100000];
	[self setDefaults];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	int i;
	for(i=0;i<32;i++)[channelName[i] release];
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3801Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3801Controller"];
}

- (NSString*) helpURL
{
	return @"VME/SIS3801.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x7FF);
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelShowDeadTimeChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelDeadTimeRefChannelChanged object:self];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ChannelNameChanged object:self userInfo:userInfo];
		
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelShipAtRunEndOnlyChanged object:self];
}

- (BOOL) isCounting
{
    return isCounting;
}

- (void) setIsCounting:(BOOL)aState
{
	if(aState != isCounting){
		isCounting = aState;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelIsCountingChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelSyncWithRunChanged object:self];
}

- (BOOL) clearOnRunStart
{
    return clearOnRunStart;
}

- (void) setClearOnRunStart:(BOOL)aClearOnRunStart
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClearOnRunStart:clearOnRunStart];
    clearOnRunStart = aClearOnRunStart;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelClearOnRunStartChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801PollTimeChanged object:self];
	
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
	[self readCounts:NO];
	[self shipData];
	
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelEnableReferencePulserChanged object:self];
}

- (BOOL) enableInputTestMode
{
    return enableInputTestMode;
}

- (void) setEnableInputTestMode:(BOOL)aEnableInputTestMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableInputTestMode:enableInputTestMode];
    enableInputTestMode = aEnableInputTestMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelEnableInputTestModeChanged object:self];
}

- (BOOL) enable25MHzPulses
{
    return enable25MHzPulses;
}

- (void) setEnable25MHzPulses:(BOOL)aEnable25MHzPulses
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnable25MHzPulses:enable25MHzPulses];
    enable25MHzPulses = aEnable25MHzPulses;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelEnable25MHzPulsesChanged object:self];
}

- (int) lemoInMode
{
    return lemoInMode;
}

- (void) setLemoInMode:(int)aLemoInMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoInMode:lemoInMode];
    lemoInMode = aLemoInMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelLemoInModeChanged object:self];
}

- (unsigned long) counts:(int)i
{
	if(i>=0 && i<32)return counts[i];
	else return 0;
}

- (unsigned long) countEnableMask { return countEnableMask; }
- (void) setCountEnableMask:(unsigned long)aCountEnableMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCountEnableMask:countEnableMask];
    countEnableMask = aCountEnableMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelCountEnableMaskChanged object:self];
}

- (BOOL) countEnabled:(short)chan { return countEnableMask & (1<<chan); }
- (void) setCountEnabled:(short)chan withValue:(BOOL)aValue		
{ 
	NSLog(@"setting %d to %d\n",chan,aValue);
	unsigned long aMask = countEnableMask;
	if(aValue)aMask |= (1L<<chan);
	else aMask &= ~(1L<<chan);
	[self setCountEnableMask:aMask];
}

- (unsigned long) overFlowMask { return overFlowMask; }
- (void) setOverFlowMask:(unsigned long)aMask
{
    overFlowMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelOverFlowMaskChanged object:self];
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
- (void) readModuleID:(BOOL)verbose
{	
	unsigned long result = 0;
	[[self adapter] readLongBlock:&result
                         atAddress:[self baseAddress] + kModuleIDReg
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	moduleID = result >> 16;
	unsigned short version = (result >> 12) & 0xf;
	if(verbose)NSLog(@"SIS3801 ID: %x  Version:%x\n",moduleID,version);
	if(moduleID != 0x3801)NSLogColor([NSColor redColor],@"Slot %d has a %04x but you are using a SIS3801 object.\n",[self slot],moduleID);
	   
	[self readStatusRegister];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801ModelIDChanged object:self];
}


- (void) readStatusRegister
{		
	unsigned long aMask = 0;
	[[self adapter] readLongBlock:&aMask
                         atAddress:[self baseAddress] + kControlStatus
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	[self setIsCounting: (aMask & kSoftwareDisableCountingBit)!=kSoftwareDisableCountingBit ];
}

- (void) writeControlRegister
{
	unsigned long aMask = 0x0;
	aMask |= 
	((lemoInMode & 0x3) << 2)			|  //the '1' bits set the mode bits
	((~lemoInMode & 0x3) << 10)			|  //the '0' bits set the mode clr bits
	((enable25MHzPulses & 0x1) << 4)	|
	((~enable25MHzPulses & 0x1) << 12)	|
	((enableInputTestMode & 0x1) << 5)	|
	((~enableInputTestMode & 0x1) << 13);
			  
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) setLed:(BOOL)state
{
	unsigned long aValue;
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
	[self readStatusRegister];
	[self enableReferencePulser:enableReferencePulser];
}

- (void) readCounts:(BOOL)clear
{
	unsigned long result = 0;
	[[self adapter] readLongBlock:&result
						atAddress:[self baseAddress] + kFifoBuffer
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	NSLog(@"%d\n",result);
	/*
	ORCommandList* aList = [ORCommandList commandList];
	int i;
	for(i=0;i<32;i++){
		[aList addCommand: [ORVmeReadWriteCommand readLongBlockAtAddress: [self baseAddress] + kFifoBuffer + (4*i)
															   numToRead: 1
															  withAddMod: [self addressModifier]
														   usingAddSpace: 0x01]];
	}
	[self executeCommandList:aList];
	
	//if we get here, the results can retrieved in the same order as sent
	for(i=0;i<32;i++){
		counts[i] = [aList longValueForCmd:i];
	}
	
	[self logTime];
	*/
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801CountersChanged object:self];

}

- (void) clearFifo
{
	unsigned long aValue;
	[[self adapter] writeLongBlock:&aValue
						atAddress:[self baseAddress] + kClearFIFO
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	int i;
	for(i=0;i<32;i++){
		counts[i] = 0;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801CountersChanged object:self];	
}



- (void) clearAll
{
	int i;
	for(i=0;i<32;i++){
		counts[i] = 0;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801CountersChanged object:self];	
}

- (void) enableReferencePulser:(BOOL)state
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + (state?kEnableReferencePulserChan1:kDisableReferencePulserChan1)
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3801CountersChanged object:self];	
}

- (void) generateTestPulse
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kTestPulse
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

#pragma mark •••Data Taker
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
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
								 @"ORSIS3801DecoderForCounts",				@"decoder",
								 [NSNumber numberWithLong:dataId],			@"dataId",
								 [NSNumber numberWithBool:NO],				@"variable",
								 [NSNumber numberWithLong:kSIS3801DataLen],	@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Counts"];
    
    return dataDictionary;
}

#pragma mark •••HW Wizard

- (int) numberOfChannels
{
    return kNumSIS3801Channels;
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
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORSIS3801Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORSIS3801Model"]];
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

	unsigned long options =	
		lemoInMode				 | 
		enable25MHzPulses<<3	 | 
		enableInputTestMode<<4	 |
		enableReferencePulser<<5 |
		clearOnRunStart<<6		 |
		syncWithRun<<7;
	
	[objDictionary setObject:[NSNumber numberWithLong:options] forKey:@"options"];
	
    return objDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3801Model"];    
    
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

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	//nothing to do for this card
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
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
 	unsigned long aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kGlobalReset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	[self readStatusRegister];

}

- (void) startCounting
{
	[self initBoard];
 //	unsigned long aValue = 0; //value doesn't matter 
 //	[[self adapter] writeLongBlock:&aValue
 //                        atAddress:[self baseAddress] + kGlobalCountEnable
 //                       numToWrite:1
 //                       withAddMod:[self addressModifier]
 //                    usingAddSpace:0x01];
 //	[self readStatusRegister];
	[self timeToPoll];
}

- (void) stopCounting
{
//	unsigned long aValue = 0; //value doesn't matter 
//	[[self adapter] writeLongBlock:&aValue
//                         atAddress:[self baseAddress] + kGlobalCountDisable
//                       numToWrite:1
//                       withAddMod:[self addressModifier]
//                    usingAddSpace:0x01];
//	[self readStatusRegister];
}

- (void) dumpCounts
{
	NSFont* aFont =[NSFont fontWithName:@"Monaco" size:11];
	NSLogFont(aFont, @"SIS3801,%d,%d Scaler Counts\n",[self crateNumber],[self slot]);
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
    [self setSyncWithRun:[decoder decodeBoolForKey:@"syncWithRun"]];
    [self setClearOnRunStart:[decoder decodeBoolForKey:@"clearOnRunStart"]];
    [self setEnableReferencePulser:[decoder decodeBoolForKey:@"enableReferencePulser"]];
    [self setEnableInputTestMode:[decoder decodeBoolForKey:@"enableInputTestMode"]];
    [self setEnable25MHzPulses:[decoder decodeBoolForKey:@"enable25MHzPulses"]];
    [self setLemoInMode:[decoder decodeIntForKey:@"lemoInMode"]];
    [self setPollTime:[decoder decodeIntForKey:@"pollTime"]];
    [self setCountEnableMask:[decoder decodeInt32ForKey:@"countEnableMask"]];
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
	[encoder encodeInt:deadTimeRefChannel forKey:@"deadTimeRefChannel"];
    [encoder encodeBool:shipAtRunEndOnly forKey:@"shipAtRunEndOnly"];
    [encoder encodeBool:syncWithRun forKey:@"syncWithRun"];
    [encoder encodeBool:clearOnRunStart forKey:@"clearOnRunStart"];
    [encoder encodeBool:enableReferencePulser forKey:@"enableReferencePulser"];
    [encoder encodeBool:enableInputTestMode forKey:@"enableInputTestMode"];
    [encoder encodeBool:enable25MHzPulses forKey:@"enable25MHzPulses"];
    [encoder encodeInt:lemoInMode forKey:@"lemoInMode"];
    [encoder encodeInt:pollTime forKey:@"pollTime"];
    [encoder encodeInt32:countEnableMask forKey:@"countEnableMask"];
	int i;
	for(i=0;i<32;i++) {
		[encoder encodeObject:channelName[i] forKey:[NSString stringWithFormat:@"channelName%d",i]];
	}
}

@end

@implementation ORSIS3801Model (private)
- (void) logTime
{
	time_t	ut_Time;
	time(&ut_Time);
	timeMeasured = ut_Time;
}

- (void) shipData
{
	if([[ORGlobal sharedGlobal] runInProgress]){
		if(!shipAtRunEndOnly || endOfRun){
			endOfRun = NO;
			unsigned long data[kSIS3801DataLen];
			data[0] = dataId | kSIS3801DataLen;
			data[1] = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
			if(moduleID == 3820)data[1] |= 1;
			
			data[2] = timeMeasured;
			data[3] = lastTimeMeasured;
			data[4] = countEnableMask;
			data[5] = overFlowMask;
			
			data[6] =	
				lemoInMode |
				enable25MHzPulses<<3 |
				enableInputTestMode<<4 |
				enableReferencePulser<<5 |
				clearOnRunStart<<6 |
				syncWithRun<<7;
			   
			int i;
			for(i=0;i<32;i++){
				data[7+i] = counts[i];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(long)*kSIS3801DataLen]];
			lastTimeMeasured = timeMeasured;
		}
	}
}

- (void) executeCommandList:(ORCommandList*) aList
{
	[[self adapter] executeCommandList:aList];
}

@end

