/*
 *  ORCV830Model.cpp
 *  Orca
 *
 *  Created by Mark Howe on 06/06/2012
 *  Copyright (c) 2012 University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina,or U.S. Government make any warranty,
//express or implied,or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark •••Imported Files
#import "ORCV830Model.h"

#import "ORVmeCrateModel.h"
#import "ORDataTypeAssigner.h"
#import "VME_HW_Definitions.h"
#import "NSNotifications+Extensions.h"
#import "ORReadOutList.h"
#import "ORDataPacket.h"

#pragma mark •••Static Declarations
static RegisterNamesStruct reg[kNumberOfV830Registers] = {
	{@"Event Buffer",		0,0,0, 0x0000, kReadOnly,	kD32}, 
	{@"Counter 0",			0,0,0, 0x1000, kReadOnly,	kD32},
	{@"Counter 1",			0,0,0, 0x1004, kReadOnly,	kD32},
	{@"Counter 2",			0,0,0, 0x1008, kReadOnly,	kD32},
	{@"Counter 3",			0,0,0, 0x100C, kReadOnly,	kD32},
	{@"Counter 4",			0,0,0, 0x1010, kReadOnly,	kD32},
	{@"Counter 5",			0,0,0, 0x1014, kReadOnly,	kD32},
	{@"Counter 6",			0,0,0, 0x1018, kReadOnly,	kD32},
	{@"Counter 7",			0,0,0, 0x101C, kReadOnly,	kD32},
	{@"Counter 8",			0,0,0, 0x1020, kReadOnly,	kD32},
	{@"Counter 9",			0,0,0, 0x1024, kReadOnly,	kD32},
	{@"Counter 10",			0,0,0, 0x1028, kReadOnly,	kD32},
	{@"Counter 11",			0,0,0, 0x102C, kReadOnly,	kD32},
	{@"Counter 12",			0,0,0, 0x1030, kReadOnly,	kD32},
	{@"Counter 13",			0,0,0, 0x1034, kReadOnly,	kD32},
	{@"Counter 14",			0,0,0, 0x1038, kReadOnly,	kD32},
	{@"Counter 15",			0,0,0, 0x103C, kReadOnly,	kD32},
	{@"Counter 16",			0,0,0, 0x1040, kReadOnly,	kD32},
	{@"Counter 17",			0,0,0, 0x1044, kReadOnly,	kD32},
	{@"Counter 18",			0,0,0, 0x1048, kReadOnly,	kD32},
	{@"Counter 19",			0,0,0, 0x104C, kReadOnly,	kD32},
	{@"Counter 20",			0,0,0, 0x1050, kReadOnly,	kD32},
	{@"Counter 21",			0,0,0, 0x1054, kReadOnly,	kD32},
	{@"Counter 22",			0,0,0, 0x1058, kReadOnly,	kD32},
	{@"Counter 23",			0,0,0, 0x105C, kReadOnly,	kD32},
	{@"Counter 24",			0,0,0, 0x1060, kReadOnly,	kD32},
	{@"Counter 25",			0,0,0, 0x1064, kReadOnly,	kD32},
	{@"Counter 26",			0,0,0, 0x1068, kReadOnly,	kD32},
	{@"Counter 27",			0,0,0, 0x106C, kReadOnly,	kD32},
	{@"Counter 28",			0,0,0, 0x1070, kReadOnly,	kD32},
	{@"Counter 29",			0,0,0, 0x1074, kReadOnly,	kD32},
	{@"Counter 30",			0,0,0, 0x1078, kReadOnly,	kD32},
	{@"Counter 31",			0,0,0, 0x107C, kReadOnly,	kD32},
	{@"TestReg",			0,0,0, 0x1080, kReadWrite,	kD32},
	{@"Testlcntl",			0,0,0, 0x1090, kReadWrite,	kD16},
	{@"Testlcnth",			0,0,0, 0x1094, kReadWrite,	kD16},
	{@"Testhcntl",			0,0,0, 0x10A0, kReadWrite,	kD16},
	{@"Testhcnth",			0,0,0, 0x10A4, kReadWrite,	kD16},
	{@"ChannelEnable",		0,0,0, 0x1100, kReadWrite,	kD32},
	{@"DwellTime",			0,0,0, 0x1104, kReadWrite,	kD32},
	{@"ControlReg",			0,0,0, 0x1108, kReadWrite,	kD16},
	{@"Bit Set Reg",		0,0,0, 0x110A, kReadWrite,	kD16},
	{@"Bit Clr Reg",		0,0,0, 0x110A, kReadWrite,	kD16},
	{@"Status Reg",			0,0,0, 0x110E, kReadWrite,	kD16},
	{@"GEO Reg",			0,0,0, 0x1110, kReadWrite,	kD16},
	{@"Interrupt Level",	0,0,0, 0x1112, kReadWrite,	kD16},
	{@"Interrupt Vector",	0,0,0, 0x1114, kReadWrite,	kD16},
	{@"ADER_32",			0,0,0, 0x1116, kReadWrite,	kD16},
	{@"ADER_23",			0,0,0, 0x1118, kReadWrite,	kD16},
	{@"Enable ADER",		0,0,0, 0x111A, kReadWrite,	kD16},
	{@"MCST Base Add",		0,0,0, 0x111C, kReadWrite,	kD16},
	{@"MCST Control",		0,0,0, 0x111E, kReadWrite,	kD16},
	{@"Module Reset",		0,0,0, 0x1120, kReadWrite,	kD16},
	{@"Software Clear",		0,0,0, 0x1122, kWriteOnly,	kD16},
	{@"Software Trig",		0,0,0, 0x1124, kWriteOnly,	kD16},
	{@"Trig Counter",		0,0,0, 0x1128, kReadOnly,	kD32},
	{@"Almost Full",		0,0,0, 0x112C, kReadWrite,	kD16},	
	{@"BLT Event Num",		0,0,0, 0x1130, kReadWrite,	kD16},
	{@"Firmware",			0,0,0, 0x1132, kReadOnly,	kD16},
	{@"MEB Event Num",		0,0,0, 0x1134, kReadOnly,	kD16},
	{@"Dummy32",			0,0,0, 0x1200, kReadWrite,	kD32},
	{@"Dummy16",			0,0,0, 0x1204, kReadWrite,	kD16},
	{@"Config ROM",			0,0,0, 0x4000, kReadOnly,	kD16},
};

#pragma mark •••Notification Strings
NSString* ORCV830ModelCount0OffsetChanged = @"ORCV830ModelCount0OffsetChanged";
NSString* ORCV830ModelAutoResetChanged			= @"ORCV830ModelAutoResetChanged";
NSString* ORCV830ModelClearMebChanged			= @"ORCV830ModelClearMebChanged";
NSString* ORCV830ModelTestModeChanged			= @"ORCV830ModelTestModeChanged";
NSString* ORCV830ModelAcqModeChanged			= @"ORCV830ModelAcqModeChanged";
NSString* ORCV830ModelDwellTimeChanged			= @"ORCV830ModelDwellTimeChanged";
NSString* ORCV830ModelEnabledMaskChanged		= @"ORCV830ModelEnabledMaskChanged";
NSString* ORCV830ModelScalerValueChanged		= @"ORCV830ModelScalerValueChanged";
NSString* ORCV830ModelPollingStateChanged		= @"ORCV830ModelPollingStateChanged";
NSString* ORCV830ModelShipRecordsChanged		= @"ORCV830ModelShipRecordsChanged";
NSString* ORCV830ModelAllScalerValuesChanged	= @"ORCV830ModelAllScalerValuesChanged";

@interface ORCV830Model (private)
- (void) _setUpPolling:(BOOL)verbose;
- (void) _stopPolling;
- (void) _startPolling;
- (void) _pollAllChannels;
- (void) _shipValues;
- (void) _shipAllValues;
- (void) _postAllScalersUpdateOnMainThread;
@end

@implementation ORCV830Model

- (id) init //designated initializer
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];
	
	ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
	[self setReadOutGroup:readList];
	[readList release];
	
    [[self undoManager] enableUndoRegistration];
    [self setAddressModifier:0x09];
	scheduledForUpdate = NO;
	
    return self;
}

- (void) dealloc
{    
	[readOutGroup release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
        [self _setUpPolling:NO];
    }
    [super wakeUp];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"CV830"]];	
}


- (void) makeMainController
{
    [self linkToController:@"ORCV830Controller"];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0xFE);
}
- (NSString*) helpURL
{
	return @"VME/V830.html";
}
#pragma mark •••Accessors

- (int32_t) count0Offset
{
    return count0Offset;
}

- (void) setCount0Offset:(int32_t)aCount0Offset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCount0Offset:count0Offset];
    
    count0Offset = aCount0Offset;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV830ModelCount0OffsetChanged object:self];
}

- (BOOL) autoReset
{
    return autoReset;
}

- (void) setAutoReset:(BOOL)aAutoReset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoReset:autoReset];
    autoReset = aAutoReset;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV830ModelAutoResetChanged object:self];
}

- (BOOL) clearMeb
{
    return clearMeb;
}

- (void) setClearMeb:(BOOL)aClearMeb
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClearMeb:clearMeb];
    clearMeb = aClearMeb;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV830ModelClearMebChanged object:self];
}



- (BOOL) testMode
{
    return testMode;
}

- (void) setTestMode:(BOOL)aTestMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestMode:testMode];
    testMode = aTestMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV830ModelTestModeChanged object:self];
}

- (short) acqMode
{
    return acqMode;
}

- (void) setAcqMode:(short)aAcqMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAcqMode:acqMode];
    acqMode = aAcqMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV830ModelAcqModeChanged object:self];
}

- (uint32_t) dwellTime
{
    return dwellTime;
}

- (void) setDwellTime:(uint32_t)aDwellTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDwellTime:dwellTime];
    dwellTime = aDwellTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV830ModelDwellTimeChanged object:self];
}

#pragma mark ***Register - General routines
- (short)          getNumberRegisters	{ return kNumberOfV830Registers; }

#pragma mark ***Register - Register specific routines
- (NSString*)     getRegisterName:(short) anIndex	{ return reg[anIndex].regName; }
- (uint32_t) getAddressOffset:(short) anIndex	{ return(reg[anIndex].addressOffset); }
- (short)		  getAccessType:(short) anIndex		{ return reg[anIndex].accessType; }
- (short)         getAccessSize:(short) anIndex		{ return reg[anIndex].size; }
- (BOOL)          dataReset:(short) anIndex			{ return reg[anIndex].dataReset; }
- (BOOL)          swReset:(short) anIndex			{ return reg[anIndex].softwareReset; }
- (BOOL)          hwReset:(short) anIndex			{ return reg[anIndex].hwReset; }
- (NSString*)	  basicLockName						{ return @"ORCaen270BasicLock"; }
- (NSString*)	  thresholdLockName					{ return @"ORCaen270ThresholdLock"; }

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 830 (Slot %d) ",[self slot]];
}

- (uint32_t) scalerValue:(int)index
{
	if(index<0)return 0;
	else if(index>kNumCV830Channels)return 0;
	else return scalerValue[index];
}

- (void) setPollingState:(NSTimeInterval)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollingState:pollingState];
    
    pollingState = aState;
    
    [self performSelector:@selector(_startPolling) withObject:nil afterDelay:0.5];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORCV830ModelPollingStateChanged
	 object: self];
    
}

- (void) setScalerValue:(uint32_t)aValue index:(int)index
{
	if(index<0)return;
	else if(index>kNumCV830Channels)return;
	scalerValue[index] = aValue;
	if([NSThread isMainThread]){
		//we must be polling, so we can just post from this thread
		[[NSNotificationCenter defaultCenter] postNotificationName:ORCV830ModelScalerValueChanged 
															object:self
														  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:@"Channel"]];
	}
	else {
		if(!scheduledForUpdate){
			scheduledForUpdate = YES;
			[self performSelector:@selector(_postAllScalersUpdateOnMainThread) withObject:nil afterDelay:1];
		}
	}
}

- (void) _postAllScalersUpdateOnMainThread
{
	//update all channels
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORCV830ModelAllScalerValuesChanged object:self];
	scheduledForUpdate = NO;
}

- (BOOL) shipRecords
{
    return shipRecords;
}

- (void) setShipRecords:(BOOL)aShipRecords
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipRecords:shipRecords];
    shipRecords = aShipRecords;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV830ModelShipRecordsChanged object:self];
}

- (NSTimeInterval)	pollingState
{
    return pollingState;
}

- (void) _pollAllChannels
{
	@try { 
		[self readScalers]; 
	}
	@catch(NSException* localException) { 
		NSLogError(@"Polling Error",@"CV830",nil);
	}
	
	if(shipRecords){
		[self _shipValues]; 
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
	if(pollingState!=0){
		[self performSelector:@selector(_pollAllChannels) withObject:nil afterDelay:pollingState];
	}
}

- (void) _shipValues
{
	[self _shipAllValues];
}

- (void) _shipAllValues
{
	BOOL runInProgress = [gOrcaGlobals runInProgress];
	
	if(runInProgress){
		uint32_t data[36];
		
		data[0] = polledDataId | 36;
		data[1] = (([self crateNumber]&0x01e)<<21) | ([self slot]& 0x0000001f)<<16;
		data[2] = enabledMask;
		data[3] = (uint32_t)lastReadTime;	//seconds since 1970
		int index = 4;
		int i;
		for(i=0;i<kNumCV830Channels;i++){
			data[index++] = scalerValue[i];
		}
		
		if(index>3){
			//the full record goes into the data stream via a notification
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:index*sizeof(int32_t)]];
		}
	}
	
}

- (uint32_t) enabledMask
{
    return enabledMask;
}

- (void) setEnabledMask:(uint32_t)aEnabledMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
    enabledMask = aEnabledMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV830ModelEnabledMaskChanged object:self];
}

- (void) _stopPolling
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
	pollRunning = NO;
}

- (void) _startPolling
{
	[self _setUpPolling:YES];
}

- (void) _setUpPolling:(BOOL)verbose
{
    if(pollingState!=0){  
		pollRunning = YES;
        if(verbose)NSLog(@"Polling CV830,%d,%d  every %.0f seconds.\n",[self crateNumber],[self slot],pollingState);
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
        [self performSelector:@selector(_pollAllChannels) withObject:self afterDelay:pollingState];
        [self _pollAllChannels];
    }
    else {
		pollRunning = NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
        if(verbose)NSLog(@"Not Polling CV830,%d,%d\n",[self crateNumber],[self slot]);
    }
}

#pragma mark •••Hardware Access
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver:self];

    [notifyCenter addObserver: self
                     selector: @selector(runAboutToStop:)
                         name: ORRunAboutToStopNotification
                       object: nil];
}

	
- (void) runAboutToStop:(NSNotification*)aNote
{
	if(pollRunning){
		[self _pollAllChannels];
	}
}

- (void) readScalers
{
	int i;
	//get the time(UT!)
	time_t	ut_Time;
	time(&ut_Time);
	//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
	lastReadTime = ut_Time;
	for(i=0;i<kNumCV830Channels;i++){
		if(enabledMask & (0x1<<i)){
			uint32_t aValue = 0;
			[[self adapter] readLongBlock:&aValue
								atAddress:[self baseAddress]+[self getAddressOffset:kCounter0] + (i*0x04)
								numToRead:1
							   withAddMod:[self addressModifier]
							usingAddSpace:0x01];
			[self setScalerValue:aValue index:i];
		}
		else [self setScalerValue:0 index:i];
		
	}
}

- (void) remoteResetCounters
{
    NSLog(@"%@ Reset timestamps\n",[self fullID]);
    [self softwareClear];
    
    dataTakers = [[readOutGroup allObjects] retain];		//cache of data takers.
    for(id obj in dataTakers){
        if([obj respondsToSelector:@selector(resetEventCounter)]){
            [obj resetEventCounter];
        }
    }
    resetRollOverInSBC  = YES;  //remote datataking
    chan0RollOverCount  = 0;    //local datataking
    lastChan0Count      = 0;    //local datataking
    remoteInit          = YES;  //someone else is in control. No init locally. Continous running.
}

- (void) remoteInitBoard
{
    remoteInit  = YES;
    [self initBoard];
}

- (void) initBoard
{
	@try {
        resetRollOverInSBC  = YES;  //remote datataking
        chan0RollOverCount  = 0;    //local datataking
        lastChan0Count      = 0;    //local datataking

  		[self writeDwellTime];
        [self writeEnabledMask];
		[self writeControlReg]; //<--clears Counters,MEB, and trigger counter
	}
	@catch(NSException* localException){
		NSLogColor([NSColor redColor],@"unable to init HW for CV830,%d,%d\n",[self crateNumber],[self slot]);
		@throw;
	}
}

- (void) read
{
    short theRegIndex 		= [self selectedRegIndex];
    
    @try {
		if(theRegIndex == kEventBuffer){
			unsigned short statusValue;
			[[self adapter] readWordBlock:&statusValue
								atAddress:[self baseAddress]+[self getAddressOffset:kStatusReg]
								numToRead:1
							   withAddMod:[self addressModifier]
							usingAddSpace:0x01];
			
			if(statusValue & (0x1L << 0)){
				unsigned short numEvents = [self getNumEvents];
				if(numEvents == 0)NSLog(@"No Events\n");
				else {
					NSLog(@"%d events in buffer. First Event:\n",numEvents);
					uint32_t aValue;
					[[self adapter] readLongBlock:&aValue
										atAddress:[self baseAddress]+[self getAddressOffset:kEventBuffer]
										numToRead:1
									   withAddMod:[self addressModifier]
									usingAddSpace:0x01];
					
					NSLog(@"Header: 0X%08X\n",aValue);
					NSLog(@"Trigger Number: %d\n",aValue & 0xFFFF);
					int type = (aValue>>16)&0x3;
					if(type==0)		NSLog(@"Trigger: External\n");
					else if(type==1)NSLog(@"Trigger: Timer\n");
					else			NSLog(@"Trigger: VME\n");
					NSLog(@"Total Words in event: %d\n",(aValue>>18)&0x3F);
					
					NSLog(@"First Event Only will follow:\n");
					int numEntriesPerEvent = [self numEnabledChannels]; //note that we already read the header if needed.
					int i;
					for(i=0;i<1;i++){
						int j;
						for(j=0;j<numEntriesPerEvent;j++){
							uint32_t aValue;
							[[self adapter] readLongBlock:&aValue
												atAddress:[self baseAddress]+[self getAddressOffset:kEventBuffer]
												numToRead:1
											   withAddMod:[self addressModifier]
											usingAddSpace:0x01];
							if(i==0){
								//print out just the first event
								NSLog(@"%d\n",aValue);
							}
							
						}
					}
				}
                [self softwareClear];

			}
			else NSLog(@"Nothing in Buffer\n");
		}
		else {
			uint32_t 	theValue   = 0;
			[self read:theRegIndex returnValue:&theValue];
			NSLog(@"CAEN reg [%@]:0x%08lx\n", [self getRegisterName:theRegIndex], theValue);
		}
	}
	@catch(NSException* localException) {
		NSLog(@"Can't Read [%@] on the %@.\n",
			  [self getRegisterName:theRegIndex], [self identifier]);
		[localException raise];
	}
}

- (unsigned short) numEnabledChannels
{
	int n = 0;
	int i;
	for(i=0;i<32;i++){
		if(enabledMask & (0x1L<<i))n++;
	}
	return n;
}

- (void) writeEnabledMask
{
	uint32_t aValue = enabledMask;
    [[self adapter] writeLongBlock:&aValue
						atAddress:[self baseAddress]+[self getAddressOffset:kChannelEnable]
						numToWrite:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
}
- (unsigned short) readControlReg
{
  	unsigned short aValue;
	[[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+[self getAddressOffset:kControlReg]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return aValue;
  
}
- (void) writeControlReg
{
	unsigned short aValue = 
		(acqMode & 0x3)		|
		(testMode << 3)		|
        (0 << 4)			| //BERR disabled
        (1 << 5)			| //header MUST be enabled
        (clearMeb << 6)		|
		(autoReset << 7);
	
    [[self adapter] writeWordBlock:&aValue
						 atAddress:[self baseAddress]+[self getAddressOffset:kControlReg]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) readStatus
{
	unsigned short aValue;
	[[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+[self getAddressOffset:kStatusReg]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	NSLog(@"Status of %@:\n",[self fullID]);
	if(aValue & (0x1L << 0)){
		uint32_t n = [self getNumEvents];
		NSLog(@"Data Ready is Set. %d event%@ in the event buffer\n",n,n>1?@"s":@"");
	}
	else NSLog(@"No events in buffer\n");
	if(aValue & (0x1L << 2))		NSLog(@"Event buffer is Full\n");
	else if(aValue & (0x1L << 1))	NSLog(@"Event buffer is almost full\n");
	if(aValue & (0x1L << 5))		NSLog(@"All control Bus Terminations are ON\n");
	else							NSLog(@"Not all control Bus Terminations are ON\n");
	if(aValue & (0x1L << 6))		NSLog(@"All control Bus Terminations are OFF\n");
	else							NSLog(@"Not all control Bus Terminations are OFF\n");
}

- (unsigned short) getNumEvents
{
	unsigned short aValue = 0;
	[[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+[self getAddressOffset:kMEBEventNum]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	return aValue;
}

- (void) writeDwellTime
{
	uint32_t aValue = dwellTime;
	
    [[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress]+[self getAddressOffset:kDwellTime]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}


- (void) softwareTrigger
{
	unsigned short aValue = 0;
    [[self adapter] writeWordBlock:&aValue
						 atAddress:[self baseAddress]+[self getAddressOffset:kSoftwareTrig]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
}

- (void) softwareClear
{
	unsigned short aValue = 0;
    [[self adapter] writeWordBlock:&aValue
						 atAddress:[self baseAddress]+[self getAddressOffset:kSoftwareClear]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	[self readScalers];
	
}

- (void) softwareReset
{
	unsigned short aValue = 0;
    [[self adapter] writeWordBlock:&aValue
						 atAddress:[self baseAddress]+[self getAddressOffset:kModuleReset]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	[self readScalers];
}



#pragma mark ***DataTaker
- (void) setDataIds:(id)assigner
{
    dataId		 = [assigner assignDataIds:kLongForm];
    polledDataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
    [self setPolledDataId:[anotherObj polledDataId]];
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (uint32_t) polledDataId { return polledDataId; }
- (void) setPolledDataId: (uint32_t) DataId
{
    polledDataId = DataId;
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORCV830DecoderForEvent",			@"decoder",
								 [NSNumber numberWithLong:dataId],	@"dataId",
								 [NSNumber numberWithBool:YES],		@"variable",
								 [NSNumber numberWithLong:-1],		@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Event"];

	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORCV830DecoderForPolledRead",			@"decoder",
								 [NSNumber numberWithLong:polledDataId],	@"dataId",
								 [NSNumber numberWithBool:NO],				@"variable",
								 [NSNumber numberWithLong:36],				@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"PolledRead"];
	
	
    return dataDictionary;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	
    [objDictionary setObject: [NSNumber numberWithLong:enabledMask]		forKey:@"enabledMask"];	
	[objDictionary setObject: [NSNumber numberWithLong:dwellTime]		forKey:@"dwellTime"];
	[objDictionary setObject: [NSNumber numberWithLong:count0Offset]    forKey:@"count0Offset"];
	
    return objDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:NSStringFromClass([self class])]; 
}

- (void) reset
{	
}

- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{  
	
	[aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:NSStringFromClass([self class])]; 
	scheduledForUpdate  = NO;
	numEnabledChannels  = [self numEnabledChannels];
    BOOL doInit = [[userInfo objectForKey:@"doinit"] boolValue];
    if(!remoteInit && doInit){
        [self initBoard];
    }
    //cache the data takers for alittle more speed
	dataTakers = [[readOutGroup allObjects] retain];		//cache of data takers.
	for(id obj in dataTakers){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
	
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	@try {
		unsigned short statusRegValue;
		[[self adapter] readWordBlock:&statusRegValue
							atAddress:[self baseAddress]+[self getAddressOffset:kStatusReg]
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		BOOL dataReady = statusRegValue & (0x1L << 0);
        
		if(dataReady){
            //there is at least one event
            int totalWordsInRecord = (int)(4+numEnabledChannels + 1);
            dataRecord[0] = dataId | totalWordsInRecord;
            dataRecord[1] = (([self crateNumber]&0x01e)<<21) | ([self slot]& 0x0000001f)<<16;
            dataRecord[2] = 0; //chan 0 roll over. fill in later
            dataRecord[3] = enabledMask;
            int i;
            for(i=0;i<numEnabledChannels+1;i++){
                //read the header + the counts for the enabled channels
                [[self adapter] readLongBlock:&dataRecord[4+i]
                                    atAddress:[self baseAddress]+[self getAddressOffset:kEventBuffer]
                                    numToRead:1
                                   withAddMod:[self addressModifier]
                                usingAddSpace:0x01];
            }
            //for chan zero keep a rollover count
            if((enabledMask & 0x1)){
                if(dataRecord[4]!=0){
                    if(dataRecord[4]<lastChan0Count){
                        chan0RollOverCount++;
                    }
                    int64_t final = (chan0RollOverCount << 32) | dataRecord[4];
                    final += count0Offset;

                    lastChan0Count = dataRecord[4];
                    dataRecord[2] = (final >> 32) & 0xffffffff; //store the high word (rollover)
                    dataRecord[4] = final & 0xffffffff;         //store the low word
                }
                else {
                    //temp work around for erroronous counter transfers
                    dataRecord[2] = 0xffffffff;
                    dataRecord[4] = 0xffffffff;
                }
            }

            [aDataPacket addLongsToFrameBuffer:dataRecord length:totalWordsInRecord];

            for(id obj in dataTakers){
                [obj takeData:aDataPacket userInfo:userInfo];
            }
		}
	}
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    for(id obj in dataTakers){
        [obj runIsStopping:aDataPacket userInfo:userInfo];
    }
}

- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
    remoteInit = NO;
    for(id obj in dataTakers){
		[obj runTaskStopped:aDataPacket userInfo:userInfo];
    }	
	[dataTakers release];
	dataTakers = nil;
    controller = nil;
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id   = kCaen830; //should be unique
	configStruct->card_info[index].hw_mask[0] 	= dataId; //better be unique
	configStruct->card_info[index].slot			= [self slot];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= [self addressModifier];
	configStruct->card_info[index].base_add		= [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0] = enabledMask;
	configStruct->card_info[index].deviceSpecificData[1] = [self getAddressOffset:kStatusReg];
	configStruct->card_info[index].deviceSpecificData[2] = [self getAddressOffset:kMEBEventNum];
	configStruct->card_info[index].deviceSpecificData[3] = [self getAddressOffset:kEventBuffer];
	configStruct->card_info[index].deviceSpecificData[4] = [self numEnabledChannels];
    configStruct->card_info[index].deviceSpecificData[5] = [self count0Offset];
    configStruct->card_info[index].deviceSpecificData[6] = resetRollOverInSBC;
    
    resetRollOverInSBC = NO; //must be reset for every run
    
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	    
	configStruct->card_info[index].num_Trigger_Indexes = 1;	//Just 1 group of objects controlled by this card
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

#pragma mark •••Children
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

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setCount0Offset:  [decoder decodeIntForKey: @"count0Offset"]];
    [self setAutoReset:		[decoder decodeBoolForKey:  @"autoReset"]];
    [self setClearMeb:		[decoder decodeBoolForKey:  @"clearMeb"]];
    [self setTestMode:		[decoder decodeBoolForKey:  @"testMode"]];
    [self setAcqMode:		[decoder decodeIntegerForKey:   @"acqMode"]];
    [self setDwellTime:		[decoder decodeIntForKey: @"dwellTime"]];
	[self setPollingState:	[decoder decodeIntegerForKey:   @"pollingState"]];
	[self setShipRecords:	[decoder decodeBoolForKey:  @"shipRecords"]];
	[self setEnabledMask:	[decoder decodeIntForKey: @"enabledMask"]];
	[self setReadOutGroup:	[decoder decodeObjectForKey:@"ReadoutGroup"]];
	
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
    [self setAddressModifier:0x09];
	scheduledForUpdate = NO;
	
	//temp remove needed because the readoutgroup was added when the object was already in the config and so might not be in the configuration
	if(!readOutGroup){
		ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
		[self setReadOutGroup:readList];
		[readList release];
	}
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:count0Offset   forKey:@"count0Offset"];
    [encoder encodeBool:autoReset		forKey:@"autoReset"];
    [encoder encodeBool:clearMeb		forKey:@"clearMeb"];
    [encoder encodeBool:testMode		forKey:@"testMode"];
    [encoder encodeInteger:acqMode			forKey:@"acqMode"];
    [encoder encodeInteger:dwellTime		forKey:@"dwellTime"];
    [encoder encodeInt:pollingState     forKey:@"pollingState"];
    [encoder encodeBool:shipRecords     forKey:@"shipRecords"];
	[encoder encodeInt:enabledMask    forKey:@"enabledMask"];
	[encoder encodeObject:readOutGroup  forKey:@"ReadoutGroup"];
}
- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [readOutGroup saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setReadOutGroup:[[[ORReadOutList alloc] initWithIdentifier:@"CV830"]autorelease]];
    [readOutGroup loadUsingFile:aFile];
}

@end
