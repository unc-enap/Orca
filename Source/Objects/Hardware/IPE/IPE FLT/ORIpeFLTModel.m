//
//  ORIpeFLTModel.m
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

#import "ORIpeFLTModel.h"
#import "ORIpeSLTModel.h"
#import "ORIpeCrateModel.h"
#import "ORIpeFireWireCard.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORDataTypeAssigner.h"
#import "ORTimeRate.h"
#import "ORFireWireInterface.h"
#import "ORIpeFireWireCard.h"
#import "ORTest.h"

NSString* ORIpeFLTModelDataMaskChanged = @"ORIpeFLTModelDataMaskChanged";
NSString* ORIpeFLTModelThresholdOffsetChanged	= @"ORIpeFLTModelThresholdOffsetChanged";
NSString* ORIpeFLTModelLedOffChanged			= @"ORIpeFLTModelLedOffChanged";
NSString* ORIpeFLTModelInterruptMaskChanged		= @"ORIpeFLTModelInterruptMaskChanged";
NSString* ORIpeFLTModelTModeChanged				 = @"ORIpeFLTModelTModeChanged";
NSString* ORIpeFLTModelTestParamChanged			 = @"ORIpeFLTModelTestParamChanged";
NSString* ORIpeFLTModelHitRateLengthChanged		 = @"ORIpeFLTModelHitRateLengthChanged";
NSString* ORIpeFLTModelTriggersEnabledChanged	 = @"ORIpeFLTModelTriggersEnabledChanged";
NSString* ORIpeFLTModelGainsChanged				 = @"ORIpeFLTModelGainsChanged";
NSString* ORIpeFLTModelThresholdsChanged		 = @"ORIpeFLTModelThresholdsChanged";
NSString* ORIpeFLTModelModeChanged				 = @"ORIpeFLTModelModeChanged";
NSString* ORIpeFLTSettingsLock					 = @"ORIpeFLTSettingsLock";
NSString* ORIpeFLTChan							 = @"ORIpeFLTChan";
NSString* ORIpeFLTModelTestPatternsChanged		 = @"ORIpeFLTModelTestPatternsChanged";
NSString* ORIpeFLTModelGainChanged				 = @"ORIpeFLTModelGainChanged";
NSString* ORIpeFLTModelThresholdChanged			 = @"ORIpeFLTModelThresholdChanged";
NSString* ORIpeFLTModelTriggerEnabledChanged	 = @"ORIpeFLTModelTriggerEnabledChanged";
NSString* ORIpeFLTModelHitRateEnabledChanged	 = @"ORIpeFLTModelHitRateEnabledChanged";
NSString* ORIpeFLTModelHitRatesArrayChanged		 = @"ORIpeFLTModelHitRatesArrayChanged";
NSString* ORIpeFLTModelHitRateChanged			 = @"ORIpeFLTModelHitRateChanged";
NSString* ORIpeFLTModelTestsRunningChanged		 = @"ORIpeFLTModelTestsRunningChanged";
NSString* ORIpeFLTModelTestEnabledArrayChanged	 = @"ORIpeFLTModelTestEnabledChanged";
NSString* ORIpeFLTModelTestStatusArrayChanged	 = @"ORIpeFLTModelTestStatusChanged";
NSString* ORIpeFLTModelEventMaskChanged			 = @"ORIpeFLTModelEventMaskChanged";
NSString* ORIpeFLTModelReadoutPagesChanged		 = @"ORIpeFLTModelReadoutPagesChanged"; // ak, 2.7.07
NSString* ORIpeFLTModelIntegrationTimeChanged	 = @"ORIpeFLTModelIntegrationTimeChanged";
NSString* ORIpeFLTModelCoinTimeChanged			 = @"ORIpeFLTModelCoinTimeChanged";

enum {
	kFLTControlReg,
	kFLTPixelStatus1Reg,
	kFLTPixelStatus2Reg,
	kFLTPixelStatus3Reg,
	kFLTDisOnCntrlReg,
	kFLTMarginsLReg,
	kFLTMarginsHReg,
	kFLTCheckSumDReg,
	kFLTTestPulsMemReg,
	kFLTHitRateMemReg,
	kFLTGainReg,
	kFLTPeriphStatusReg,
	kFLTStaticSetReg,
	kFLTThresholdReg,
	kFLTSumXReg,
	kFLTSumX2Reg,
	kFLTChannelOnOffReg,
	kFLTAdcMemory,
};

struct ipeReg {
	uint32_t address;
	uint32_t space;
}ipeReg[kNumFLTChannels] = {
{0x0L, 0x0L},	//kFLTControlReg
{0x1L, 0x0L},	//kFLTPixelStatus1Reg
{0x2L, 0x0L},	//kFLTPixelStatus2Reg
{0x3L, 0x0L},	//kFLTPixelStatus3Reg
{0x4L, 0x0L},	//kFLTDisOnCntrlReg
{0x5L, 0x0L},	//kFLTMarginsLReg
{0x6L, 0x0L},	//kFLTMarginsHReg
{0x7L, 0x0L},	//kFLTCheckSumDReg
{0x8L, 0x0L},	//kFLTTestPulsMemReg
{0x8L, 0x1L},	//kFLTHitRateMemReg
{0x9L, 0x1L},	//kFLTGainReg
{0x0L, 0x1L},	//kFLTPeriphStatusReg
{0x1L, 0x1L},	//kFLTStaticSetReg
{0x2L, 0x1L},	//kFLTThresholdReg
{0x3L, 0x1L},	//kFLTSumXReg
{0x5L, 0x1L},	//kFLTSumX2Reg
{0x6L, 0x1L},	//kFLTChannelOnOffReg
{0x0L, 0x2L}	//kFLTAdcMemory
};

static int trigChanConvFLT[4][6]={
{ 0,  2,  4,  6,  8, 10},	//FPGA-1
{12, 14, 16, 18, 20, 22},	//FPGA-2
{ 1,  3,  5,  7,  9, 11},	//FPGA-3
{13, 15, 17, 19, 21, 23},	//FPGA-4
};



static NSString* fltTestName[kNumIpeFLTTests]= {
@"Run Mode",
@"Ram",
@"Threshold/Gain",
@"Speed",
@"Event",
};

@interface ORIpeFLTModel (private)
- (NSAttributedString*) test:(int)testName result:(NSString*)string color:(NSColor*)aColor;
- (void) enterTestMode;
- (void) leaveTestMode;
@end

@implementation ORIpeFLTModel

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [testEnabledArray release];
    [testStatusArray release];
	[testSuit release];
    [triggersEnabled release];
	[thresholds release];
	[gains release];
	[totalRate release];
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"IpeFLTCard"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORIpeFLTController"];
}


#pragma mark ¥¥¥Accessors

- (uint32_t) dataMask
{
    return dataMask;
}

- (void) setDataMask:(uint32_t)aDataMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDataMask:dataMask];
    
    dataMask = aDataMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelDataMaskChanged object:self];
}

- (BOOL) partOfEvent:(short)chan
{
	return (eventMask & (1L<<chan)) != 0;
}

- (uint32_t) eventMask
{
	return eventMask;
}

- (void) eventMask:(uint32_t)aMask
{
	eventMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelEventMaskChanged object:self];
}


- (int) thresholdOffset
{
    return thresholdOffset;
}

- (void) setThresholdOffset:(int)aThresholdOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThresholdOffset:thresholdOffset];
    
    thresholdOffset = aThresholdOffset;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelThresholdOffsetChanged object:self];
}

- (BOOL) ledOff
{
    return ledOff;
}

- (void) setLedOff:(BOOL)aState
{
    
    ledOff = aState;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelLedOffChanged object:self];
}


- (uint32_t) coinTime
{
	return coinTime;
}

- (void) setCoinTime:(uint32_t)aValue
{
	if(aValue<4)aValue=4;
	if(aValue>515)aValue=515;
    [[[self undoManager] prepareWithInvocationTarget:self] setCoinTime:coinTime];
    
    coinTime = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelCoinTimeChanged object:self];
}

- (uint32_t) integrationTime
{
	return integrationTime;
}

- (void) setIntegrationTime:(uint32_t)aValue
{
	if(aValue<1)aValue=1;
	if(aValue>16)aValue=16;
    [[[self undoManager] prepareWithInvocationTarget:self] setIntegrationTime:integrationTime];
    
    integrationTime = aValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelIntegrationTimeChanged object:self];
}


- (uint32_t) interruptMask
{
    return interruptMask;
}

- (void) setInterruptMask:(uint32_t)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    
    interruptMask = aInterruptMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelInterruptMaskChanged object:self];
}

- (int) page
{
    return page;
}

- (void) setPage:(int)aPage
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPage:page];
    
    page = aPage;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelTestParamChanged object:self];
}

- (int) iterations
{
    return iterations;
}

- (void) setIterations:(int)aIterations
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIterations:iterations];
    
    iterations = aIterations;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelTestParamChanged object:self];
}

- (int) endChan
{
    return endChan;
}

- (void) setEndChan:(int)aEndChan
{
	if(aEndChan>21)aEndChan = 21;
	if(aEndChan<0)aEndChan = 0;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setEndChan:endChan];
    
    endChan = aEndChan;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelTestParamChanged object:self];
}

- (int) startChan
{
    return startChan;
}

- (void) setStartChan:(int)aStartChan
{
	if(aStartChan>21)aStartChan = 21;
	if(aStartChan<0)aStartChan = 0;
    [[[self undoManager] prepareWithInvocationTarget:self] setStartChan:startChan];
    
    startChan = aStartChan;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelTestParamChanged object:self];
}

- (void) setTotalRate:(ORTimeRate*)newTimeRate
{
	[totalRate autorelease];
	totalRate=[newTimeRate retain];
}

- (ORTimeRate*) totalRate
{
	return totalRate;
}


- (unsigned short) hitRateLength
{
    return hitRateLength;
}

- (void) setHitRateLength:(unsigned short)aHitRateLength
{
	if(aHitRateLength<1)aHitRateLength = 1;
	else if(aHitRateLength>32)aHitRateLength = 32;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateLength:hitRateLength];
    
    hitRateLength = aHitRateLength;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelHitRateLengthChanged object:self];
}

- (NSMutableArray*) triggersEnabled
{
    return triggersEnabled;
}

- (void) setTriggersEnabled:(NSMutableArray*)aTriggersEnabled
{
    [aTriggersEnabled retain];
    [triggersEnabled release];
    triggersEnabled = aTriggersEnabled;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelTriggersEnabledChanged object:self];
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (uint32_t) waveFormId { return waveFormId; }
- (void) setWaveFormId: (uint32_t) aWaveFormId
{
    waveFormId = aWaveFormId;
}

- (void) setDataIds:(id)assigner
{
    dataId      = [assigner assignDataIds:kLongForm];
    waveFormId  = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
    [self setWaveFormId:[anotherCard waveFormId]];
}

- (NSMutableArray*) hitRatesEnabled
{
    return hitRatesEnabled;
}

- (void) setHitRatesEnabled:(NSMutableArray*)anArray
{
	[anArray retain];
	[hitRatesEnabled release];
    hitRatesEnabled = anArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelHitRatesArrayChanged object:self];
}

- (NSMutableArray*) gains
{
    return gains;
}

- (void) setGains:(NSMutableArray*)aGains
{
	[aGains retain];
	[gains release];
    gains = aGains;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelGainsChanged object:self];
}

- (NSMutableArray*) thresholds
{
    return thresholds;
}

- (void) setThresholds:(NSMutableArray*)aThresholds
{
	[aThresholds retain];
	[thresholds release];
    thresholds = aThresholds;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelThresholdsChanged object:self];
}

-(unsigned short) threshold:(unsigned short) aChan
{
    return [[thresholds objectAtIndex:aChan] shortValue];
}


-(unsigned short) gain:(unsigned short) aChan
{
    return [[gains objectAtIndex:aChan] shortValue];
}


-(void) setThreshold:(unsigned short) aChan withValue:(unsigned short) aThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
	if(aThreshold>32000)aThreshold = 32000;
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aThreshold]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORIpeFLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeFLTModelThresholdChanged
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain
{
	if(aGain>255)aGain = 255;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:aChan withValue:[self gain:aChan]];
	[gains replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aGain]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORIpeFLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeFLTModelGainChanged
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

//ORAdcInfoProviding protocol requirement
- (void) postAdcInfoProvidingValueChanged
{
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORAdcInfoProvidingValueChanged
	 object:self
	 userInfo: nil];
}



-(BOOL) triggerEnabled:(unsigned short) aChan
{
    return [[triggersEnabled objectAtIndex:aChan] boolValue];
}

//ORAdcInfoProviding protocol 
- (BOOL)onlineMaskBit:(int)bit
{
	//translate back to the triggerEnabled Bit
	return [self triggerEnabled:bit];
}

-(void) setTriggerEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerEnabled:aChan withValue:[self triggerEnabled:aChan]];
    [triggersEnabled replaceObjectAtIndex:aChan withObject:[NSNumber numberWithBool:aState]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORIpeFLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeFLTModelTriggerEnabledChanged
	 object:self
	 userInfo: userInfo];
}

- (BOOL) hitRateEnabled:(unsigned short) aChan
{
    return [[hitRatesEnabled objectAtIndex:aChan] boolValue];
}


- (void) setHitRateEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateEnabled:aChan withValue:[self hitRateEnabled:aChan]];
    [hitRatesEnabled replaceObjectAtIndex:aChan withObject:[NSNumber numberWithBool:aState]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORIpeFLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIpeFLTModelHitRateEnabledChanged
	 object:self
	 userInfo: userInfo];
}


- (int) fltRunMode
{
    return fltRunMode;
}

- (void) setFltRunMode:(int)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFltRunMode:fltRunMode];
    fltRunMode = aMode;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelModeChanged object:self];
}

- (void) enableAllHitRates:(BOOL)aState
{
	int chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[self setHitRateEnabled:chan withValue:aState];
	}
}

- (void) enableAllTriggers:(BOOL)aState
{
	int chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[self setTriggerEnabled:chan withValue:aState];
	}
}


- (void) setHitRateTotal:(float)newTotalValue
{
	hitRateTotal = newTotalValue;
	if(!totalRate){
		[self setTotalRate:[[[ORTimeRate alloc] init]autorelease]];
	}
	[totalRate addDataToTimeAverage:hitRateTotal];
}

- (float) hitRateTotal
{
	return hitRateTotal;
}

- (float) hitRate:(unsigned short)aChan
{
	if(aChan<kNumFLTChannels)return hitRate[aChan];
	else return 0;
}

- (float) rate:(int)aChan
{
	return [self hitRate:aChan];
}

- (BOOL) hitRateOverFlow:(unsigned short)aChan
{
	if(aChan<kNumFLTChannels)return hitRateOverFlow[aChan];
	else return NO;
}


// Added parameter for length of adc traces, ak 2.7.07

- (unsigned short) readoutPages
{
    return readoutPages;
}


- (void) setReadoutPages:(unsigned short)aReadoutPage
{
    // At maximum there are 64 pages
	if(aReadoutPage<1)aReadoutPage = 1;
	else if(aReadoutPage>64)aReadoutPage = 64;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setReadoutPages:readoutPages];
    
    readoutPages = aReadoutPage;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelReadoutPagesChanged object:self];
}

#pragma mark ¥¥¥Calibration
- (void) autoCalibrate
{
	[self autoCalibrate:thresholdOffset];
}

- (void) autoCalibrate:(int)theEndingOffset
{
	
    // There is no need to load any kind of hitrate measurement of 
	// control parameters if the thresholds shold be set in a fixed 
	// distance to the mean ADC value
	
    // If the gains should be adjusted to have equal peak height
	// the test pulser can be used to compensate differences in the 
	// channel. In this case the ADC pedestal is needed and the result 
	// of the testpulse (needs data aquisition task).
    // ak, 7.10.07
	
	
    // Init board
	[self initBoard];
    usleep(100);
	
    // Set threshold to ADC + offset
	double pedestal;
	double var;
	
	// Get the integration time
	// ADC * T_int = Threshold
	uint32_t status = [self readReg: kFLTPeriphStatusReg];	
	int t_Int = (status>>20) & 0xf; // default: 10
	
	uint32_t hitRateEnabledMask = 0x0;
	int chan;
	for(chan = 0;chan<kNumFLTChannels;chan++){
		if([[hitRatesEnabled objectAtIndex:chan] intValue]){
			hitRateEnabledMask |= (0x1L<<chan);
		}
	}
	
	for(chan=0;chan<kNumFLTChannels;chan++){
		// Get the ADC pedestal
		[self getStatistics:chan mean:&pedestal var:&var]; 
		
		// Set
		if(hitRateEnabledMask & (1L<<chan)){
			int val = pedestal*t_Int + theEndingOffset; 
			[self setThreshold:chan withValue:val];
			[self writeThreshold:chan value:val];
		}
	}
	
    // Adjust gains
	// Not implemented now, ak 7.10.07
	
}

- (void) loadAutoCalbrateTestPattern
{
	[self rewindTestPattern];
	[self writeNextPattern:0x8000];
	int j;
	for(j=0;j<256;j++){
		[self writeNextPattern:0x0];
	}
	[self rewindTestPattern];	
}

#pragma mark ¥¥¥HW Access
- (void) checkPresence
{
	@try {
		[self readCardId];
		[self setPresent:YES];
	}
	@catch(NSException* localException) {
		[self setPresent:NO];
	}
}

- (int)  readVersion
{	
	uint32_t data = [self readControlStatus];
	return (data >> kIpeFlt_Cntl_Version_Shift) & kIpeFlt_Cntl_Version_Mask;
}

- (int)  readCardId
{
 	uint32_t data = [self readControlStatus];
	int realSlot =  1+(data >> kIpeFlt_Cntl_CardID_Shift) & kIpeFlt_Cntl_CardID_Mask;
	if(realSlot != [self stationNumber]){
		NSLogError(@"IPE Crate %d configuration has FLT %d in the wrong slot! (Should be slot %d)\n",[self crateNumber], [self stationNumber], realSlot); 
	}
	return realSlot;
}


- (int)  readMode
{
	uint32_t data = [self readControlStatus];
	[self setFltRunMode: (data >> kIpeFlt_Cntl_Mode_Shift) & kIpeFlt_Cntl_Mode_Mask];
	return fltRunMode;
}

- (void) loadThresholdsAndGains
{
	int i;
	for(i=0;i<kNumFLTChannels;i++){
		[self writeThreshold:i value:[self threshold:i]];
		[self writeGain:i value:[self gain:i]]; 
	}
}

- (void) enableStatistics
{
    uint32_t aValue;
	bool enabled = true;
	uint32_t adc_guess = 150;			// This are parameter that work with the standard Auger-type boards
	uint32_t n = 65000;				// There is not really a need to make them variable. ak 7.10.07
	
    aValue =     (  ( (uint32_t) (enabled  &   0x1) ) << 31)
	| (  ( (uint32_t) (adc_guess   & 0x3ff) ) << 16)
	|    ( (uint32_t) ( (n-1)  & 0xffff) ) ; // 16 bit !
	
	// Broadcast to all channel	(pseudo channel 0x1f)     
	[self writeReg:kFLTStaticSetReg channel:0x1f value:aValue]; 
	
	// Save parameter for calculation of mean and variance
	statisticOffset = adc_guess;
	statisticN = n;
}


- (void) getStatistics:(int)aChannel mean:(double *)aMean  var:(double *)aVar 
{
    uint32_t data;
	int32_t sum;
    uint32_t sumSq;
	
    // Read Statistic parameter
    data = [self  readReg:kFLTStaticSetReg channel:aChannel];
	statisticOffset = (data  >> 16) & 0x3ff;
	statisticN = (data & 0xffff) +1;
	
	
    // Read statistics
	// The sum is a 25bit signed number.
	sum = [self readReg:kFLTSumXReg channel:aChannel];
	// Move the sign
	sum = (sum & 0x01000000) ? (sum | 0xFE000000) : (sum & 0x00FFFFFF);
	
    // Read the sum of squares	
	sumSq = [self readReg:kFLTSumX2Reg channel:aChannel];
	
	//NSLog(@"data = %x Offset = %d, n = %d, sum = %08x, sum2 = %08x\n", data, statisticOffset, statisticN, sum, sumSq);
	
	// Calculate mean and variance
	if (statisticN > 0){
		*aMean = (double) sum / statisticN + statisticOffset;
		*aVar = (double) sumSq / statisticN 
		- (double) sum / statisticN * sum / statisticN;
    } else {
		*aMean = -1; 
		*aVar = -1;
	}
	
}


- (void) initBoard
{
	[self writeControlStatus];
	[self writePeriphStatus];
	[self loadThresholdsAndGains];
	[self writeTriggerControl];			//set trigger mask
	[self writeHitRateMask];			//set hitRage control mask
	[self enableStatistics];			//enable hardware ADC statistics, ak 7.1.07
	
	[self writeReg:kFLTDisOnCntrlReg value:0];
}

- (uint32_t) readControlStatus
{
	uint32_t value =   [self readReg: kFLTControlReg ];
	[self setLedOff: ((value & kIpeFlt_Cntl_LedOff_Mask) >> kIpeFlt_Cntl_LedOff_Shift)];
	return value;
}

- (void) writeControlStatus
{
	uint32_t aValue =	(interruptMask  & kIpeFlt_Cntl_InterruptMask_Mask) << kIpeFlt_Cntl_InterruptMask_Shift  |
	(ledOff			& kIpeFlt_Cntl_LedOff_Mask)		   << kIpeFlt_Cntl_LedOff_Shift			| 
	(hitRateLength  & kIpeFlt_Cntl_HitRateLength_Mask) << kIpeFlt_Cntl_HitRateLength_Shift  |
	(fltRunMode		& kIpeFlt_Cntl_Mode_Mask)		   << kIpeFlt_Cntl_Mode_Shift;
	
	[self writeReg: kFLTControlReg value:aValue];
}

- (void) writePeriphStatus
{
	int fpga;
	for(fpga=0;fpga<4;fpga++){
		uint32_t aValue = (!fltRunMode &kIpeFlt_Periph_Mode_Mask) << kIpeFlt_Periph_Mode_Shift |
		(coinTime & kIpeFlt_Periph_CoinTme_Mask) << kIpeFlt_Periph_CoinTme_Shift |    
		(0 & kIpeFlt_Periph_LedOff_Mask) <<kIpeFlt_Periph_LedOff_Shift |
		(1 & kIpeFlt_Periph_ThresDelta_Mask) <<kIpeFlt_Periph_ThresDelta_Shift |
		(integrationTime & kIpeFlt_Periph_Integration_Mask) <<kIpeFlt_Periph_Integration_Shift;  // ak 5.10.07
		
		[self writeReg: kFLTPeriphStatusReg channel:trigChanConvFLT[fpga][0] value:aValue];
	}
}

- (void) printPixelRegs
{
	uint32_t aValue;
	int j;
	
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	for(j=0;j<3;j++){
		int regIndex;
		if(j==0)		regIndex = kFLTPixelStatus1Reg;
		else if(j==1)	regIndex = kFLTPixelStatus2Reg;
		else			regIndex = kFLTPixelStatus3Reg;
		
		aValue = [self readReg:regIndex];
		NSLogFont(aFont,@"FLT %d Pixel%d Reg (address:0x%08x): 0x%08x\n",[self stationNumber], j+1,[self regAddress:regIndex],aValue);
		NSMutableString* s = [NSMutableString stringWithString:@"Bits 21 - 0: "];
		int i=0;
		for(i=21;i>=0;i--){
			if(aValue & (1L<<i))[s appendString:@"1 "];
			else [s appendString:@"0 "];
		}
		NSLogFont(aFont,@"%@\n",s);
	}
	int fpga;
	for(fpga=0;fpga<4;fpga++){
		aValue = [self read:[self regAddress:kFLTChannelOnOffReg channel:trigChanConvFLT[fpga][0]]];
		NSLogFont(aFont,@"FLT %d ChanOnOff Reg (address:0x%08x, fpga%d): 0x%08x\n",[self stationNumber],[self regAddress:kFLTChannelOnOffReg channel:trigChanConvFLT[fpga][0]],fpga+1,aValue);
		NSMutableString* s = [NSMutableString stringWithString:@"Bits 11 - 0: "];
		int i=0;
		for(i=11;i>=0;i--){
			if(aValue & (1L<<i))[s appendString:@"1 "];
			else [s appendString:@"0 "];
		}
		NSLogFont(aFont,@"%@\n",s);
	}
}


- (void) printStatusReg
{
	uint32_t status = [self readControlStatus];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"FLT %d status Reg (address:0x%08x): 0x%08x\n", [self stationNumber],[self regAddress:kFLTControlReg],status);
	NSLogFont(aFont,@"SlotID         : %d\n",1+(status>>kIpeFlt_Cntl_CardID_Shift) & kIpeFlt_Cntl_CardID_Mask);
	NSLogFont(aFont,@"Version        : %d\n",(status>>kIpeFlt_Cntl_Version_Shift) & kIpeFlt_Cntl_Version_Mask);
	NSLogFont(aFont,@"Run Mode       : %d\n",((status>>kIpeFlt_Cntl_Mode_Shift) & kIpeFlt_Cntl_Mode_Mask));
	NSLogFont(aFont,@"Led Enabled    : %@\n",((status>>kIpeFlt_Cntl_LedOff_Shift) & kIpeFlt_Cntl_LedOff_Mask)?@"YES":@"NO");
	NSLogFont(aFont,@"Interrupt Mask : %d\n",((status>>kIpeFlt_Cntl_InterruptMask_Shift) & kIpeFlt_Cntl_InterruptMask_Mask));
	short maskValue = ((status>>kIpeFlt_Cntl_InterruptSources_Shift) & kIpeFlt_Cntl_InterruptSources_Mask);
	NSLogFont(aFont,@"Interrupt Src  : %d\n",maskValue);
	
	NSLogFont(aFont,@"     CountErr1 : %d\n",maskValue & 0x1);
	NSLogFont(aFont,@"     CountErr2 : %d\n",maskValue>>1 & 0x1);
	NSLogFont(aFont,@"     CountErr3 : %d\n",maskValue>>3 & 0x1);
	NSLogFont(aFont,@"     CountErr4 : %d\n",maskValue>>4 & 0x1);
	NSLogFont(aFont,@"     ORT       : %d\n",maskValue>>5 & 0x1);
	NSLogFont(aFont,@"     HR_Error  : %d\n",maskValue>>6 & 0x1);
	NSLogFont(aFont,@"     GainError : %d\n",maskValue>>7 & 0x1);
	NSLogFont(aFont,@"     MakeIntrpt: %d\n",maskValue>>8 & 0x1);
}

- (void) printPeriphStatusReg
{
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	uint32_t status = [self readReg: kFLTPeriphStatusReg];
	NSLogFont(aFont,@"FLT %d PeriphStatus Reg (address:0x%08x): 0x%08x\n", [self stationNumber],[self regAddress:kFLTPeriphStatusReg],status);
	NSLogFont(aFont,@"Version         : %d\n",(status>>28) & 0xf);
	NSLogFont(aFont,@"Bits in BoxCar  : %d\n",(status>>24) & 0xf);
	NSLogFont(aFont,@"Integration Time: %d\n",(status>>20) & 0xf);
	NSLogFont(aFont,@"LED state       : %d\n",((status>>15) & 0x1));
	NSLogFont(aFont,@"Run/Test Mode   : %d\n",((status>>14) & 0x1));
	NSLogFont(aFont,@"Coincidence time: %d\n",((status>>0) & 0xff));
}


- (void) printStatistics
{
    int j;
	double mean;
	double var;
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
    NSLogFont(aFont,@"Statistics      :\n");
	for (j=0;j<kNumFLTChannels;j++){
		[self getStatistics:j mean:&mean var:&var];
		NSLogFont(aFont,@"  %2d -- %10.2f +/-  %10.2f\n", j, mean, var);
	}
}

- (uint32_t) regAddress:(int)aReg channel:(int)aChannel
{
	return ([self slot] << 24) | (ipeReg[aReg].space << kIpeFlt_AddressSpace) | ((aChannel&0x01f)<<kIpeFlt_ChannelAddress) | ipeReg[aReg].address;
}

- (uint32_t) regAddress:(int)aReg
{
	return ([self slot] << 24) | (ipeReg[aReg].space << kIpeFlt_AddressSpace)  | ipeReg[aReg].address;
}

- (uint32_t) adcMemoryChannel:(int)aChannel page:(int)aPage
{
	return ([self slot] << 24) | (0x2 << kIpeFlt_AddressSpace) | (aChannel << kIpeFlt_ChannelAddress)	| (aPage << kIpeFlt_PageNumber);
}

- (uint32_t) readReg:(int)aReg
{
	return [self read:[self regAddress:aReg]];
}

- (uint32_t) readReg:(int)aReg channel:(int)aChannel
{
	return [self read:[self regAddress:aReg channel:aChannel]];
}

- (void) writeReg:(int)aReg value:(uint32_t)aValue
{
	[self write:[self regAddress:aReg] value:aValue];
}

- (void) writeReg:(int)aReg channel:(int)aChannel value:(uint32_t)aValue
{
	[self write:[self regAddress:aReg channel:aChannel] value:aValue];
}



- (void) writeThreshold:(int)i value:(unsigned short)aValue
{
	[self writeReg:kFLTThresholdReg channel:i value:aValue];
}

- (unsigned short) readThreshold:(int)i
{
	return [self readReg:kFLTThresholdReg channel:i];
}

- (void) writeGain:(int)i value:(unsigned short)aValue
{
	// invert the gain scale, ak 20.7.07
	[self writeReg:kFLTGainReg channel:i value:(255-aValue)]; 
}

- (void) writeTestPattern:(uint32_t*)mask length:(int)len
{
	[self rewindTestPattern];
	[self writeNextPattern:0];
	int i;
	for(i=0;i<len;i++){
		[self writeNextPattern:mask[i]];
		NSLog(@"%d: %@\n",i,mask[i]?@".":@"-");
	}
	[self rewindTestPattern];
}

- (void) rewindTestPattern
{
	[self writeReg:kFLTTestPulsMemReg value: kIpeFlt_TP_Control | kIpeFlt_TestPattern_Reset];
}

- (void) writeNextPattern:(uint32_t)aValue
{
	[self writeReg:kFLTTestPulsMemReg value:aValue];
}

- (void) clear:(int)aChan page:(int)aPage value:(unsigned short)aValue
{
	uint32_t aPattern;
	
	aPattern =  aValue;
	aPattern = ( aPattern << 16 ) + aValue;
	
	// While emulating the block transfer by a loop of single transfers
	// it is nec. to increment the address pointer by 2
	[self clearBlock:[self adcMemoryChannel:aChan page:aPage]
			 pattern:aPattern
			  length:kIpeFlt_Page_Size / 2
		   increment:2];
}

- (void) writeMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
	[self writeBlock: [self adcMemoryChannel:aChan page:aPage] 
		  dataBuffer: (uint32_t*)aPageBuffer
			  length: kIpeFlt_Page_Size/2
		   increment: 2];
}

- (void) readMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
	
	[self readBlock: [self adcMemoryChannel:aChan page:aPage]
		 dataBuffer: (uint32_t*)aPageBuffer
			 length: kIpeFlt_Page_Size/2
		  increment: 2];
}

- (uint32_t) readMemoryChan:(int)aChan page:(int)aPage
{
	return [self read:[self adcMemoryChannel:aChan page:aPage]];
}

- (void) writeHitRateMask
{
	uint32_t hitRateEnabledMask = 0x0;
	int chan;
	for(chan = 0;chan<kNumFLTChannels;chan++){
		if([[hitRatesEnabled objectAtIndex:chan] intValue]){
			hitRateEnabledMask |= (0x1L<<chan);
		}
	}
	
	[self writeReg:kFLTPixelStatus3Reg value:hitRateEnabledMask];
}

- (unsigned short) readGain:(int)i
{
    // invert the gain scale, ak 20.7.07
	return 255-[self readReg:kFLTGainReg channel:i];
}

- (void) disableAllTriggers
{
	[self writeReg:kFLTPixelStatus1Reg value:0x3ffffff];
}

- (void) writeTriggerControl
{
	uint32_t pixelStatus1Mask = 0x0;
	int chan;
	for(chan = 0;chan<kNumFLTChannels;chan++){
		if(![[triggersEnabled objectAtIndex:chan] intValue]){ // ak 5.10.07
			pixelStatus1Mask |= (0x1L<<chan);
		}
	}
	
	[self writeReg:kFLTPixelStatus1Reg value:pixelStatus1Mask];
	[self writeReg:kFLTPixelStatus2Reg value:0x0];
}


- (void) disableTrigger
{
	uint32_t aValue = 0x555; //all triggers off
	int fpga;
	for(fpga=0;fpga<4;fpga++){
		
		[self writeReg:kFLTChannelOnOffReg channel:trigChanConvFLT[fpga][0]  value:aValue];
		uint32_t checkValue = [self readReg:kFLTChannelOnOffReg channel:trigChanConvFLT[fpga][0]];
		
		aValue	   &= 0xfff;
		checkValue &= 0xfff;
		
		if(aValue != checkValue)NSLog(@"FLT %d FPGA %d Trigger control write/read mismatch <0x%08x:0x%08x>\n",[self stationNumber],fpga,aValue,checkValue);
	}
	
}


- (unsigned short) readTriggerControl:(int) fpga
{	
	return [self readReg:kFLTChannelOnOffReg channel:trigChanConvFLT[fpga][0]];
}

- (void) readHitRates
{
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
	
	@try {
		uint32_t aValue;
		BOOL overflow;
		float measurementAge;
		
		BOOL oneChanged = NO;
		float newTotal = 0;
		int chan;
		for(chan=0;chan<kNumFLTChannels;chan++){
			
			aValue = [self readReg:kFLTHitRateMemReg channel:chan];
			measurementAge = (aValue >> 12) & 0x1f;
			overflow = (aValue >> 10) & 0x1;
			aValue = aValue & 0x3FF;
			
			if(aValue != hitRate[chan] || overflow != hitRateOverFlow[chan]){
				// The hitrate counter has to be scaled by the counting time 
				// ak, 15.6.07
				if (hitRateLength!=0){  
				    hitRate[chan] = aValue/ (float) hitRateLength; 
				}
				else {
					hitRate[chan] = 0;
				}
				if(hitRateOverFlow[chan]){
					hitRate[chan] = 0;
				}
				
				hitRateOverFlow[chan] = overflow;
				
				oneChanged = YES;
			}
			if(!hitRateOverFlow[chan]){
				newTotal += hitRate[chan];
			}
		}
		
		[self setHitRateTotal:newTotal];
		
		if(oneChanged){
		    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelHitRateChanged object:self];
		}
	}
	@catch(NSException* localException) {
	}
	
	[self performSelector:@selector(readHitRates) withObject:nil afterDelay:[self hitRateLength]];
}

- (NSString*) rateNotification
{
	return ORIpeFLTModelHitRateChanged;
}

- (BOOL) isInRunMode
{
	return [self readMode] == kIpeFlt_Run_Mode;
}

- (BOOL) isInTestMode
{
	return [self readMode] == kIpeFlt_Test_Mode;
}

#pragma mark ¥¥¥archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setThresholdOffset:	[decoder decodeIntForKey:@"ORIpeFLTModelThresholdOffset"]];
    [self setInterruptMask:		[decoder decodeIntForKey:@"ORIpeFLTModelInterruptMask"]];
    [self setCoinTime:			[decoder decodeIntForKey:@"coinTime"]];
    [self setIntegrationTime:	[decoder decodeIntForKey:@"integrationTime"]];
    [self setPage:				[decoder decodeIntForKey:@"ORIpeFLTModelPage"]];
    [self setIterations:		[decoder decodeIntForKey:@"ORIpeFLTModelIterations"]];
    [self setEndChan:			[decoder decodeIntForKey:@"ORIpeFLTModelEndChan"]];
    [self setStartChan:			[decoder decodeIntForKey:@"ORIpeFLTModelStartChan"]];
    [self setHitRateLength:		[decoder decodeIntegerForKey:@"ORIpeFLTModelHitRateLength"]];
    [self setTriggersEnabled:	[decoder decodeObjectForKey:@"ORIpeFLTModelTriggersEnabled"]];
    [self setGains:				[decoder decodeObjectForKey:@"gains"]];
    [self setThresholds:		[decoder decodeObjectForKey:@"thresholds"]];
    [self setFltRunMode:		[decoder decodeIntForKey:@"mode"]];
    [self setHitRatesEnabled:	[decoder decodeObjectForKey:@"hitRatesEnabled"]];
    [self setTotalRate:			[decoder decodeObjectForKey:@"totalRate"]];
	[self setTestEnabledArray:	[decoder decodeObjectForKey:@"testsEnabledArray"]];
	[self setTestStatusArray:	[decoder decodeObjectForKey:@"testsStatusArray"]];
    [self setReadoutPages:		[decoder decodeIntegerForKey:@"ORIpeFLTModelReadoutPages"]];	// ak, 2.7.07
    [self setDataMask:			[decoder decodeIntForKey:@"ORIpeFLTModelDataMask"]];
	if(dataMask ==0)dataMask=0xfff;
	//make sure these objects exist and are populated with nil objects.
	int i;	
	if(!triggersEnabled){
		[self setTriggersEnabled: [NSMutableArray array]];
		for(i=0;i<kNumFLTChannels;i++) [triggersEnabled addObject:[NSNumber numberWithBool:YES]];
	}
	
	if(!hitRatesEnabled){
		[self setHitRatesEnabled: [NSMutableArray array]];
		for(i=0;i<kNumFLTChannels;i++) [hitRatesEnabled addObject:[NSNumber numberWithBool:YES]];
	}
	
	if(!thresholds){
		[self setThresholds: [NSMutableArray array]];
		for(i=0;i<kNumFLTChannels;i++) [thresholds addObject:[NSNumber numberWithInt:50]];
	}
	
	if(!gains){
		[self setGains: [NSMutableArray array]];
		for(i=0;i<kNumFLTChannels;i++) [gains addObject:[NSNumber numberWithInt:100]];
	}
	
	if(!testStatusArray){
		[self setTestStatusArray: [NSMutableArray array]];
		for(i=0;i<kNumIpeFLTTests;i++) [testStatusArray addObject:@"--"];
	}
	
	if(!testEnabledArray){
		[self setTestEnabledArray: [NSMutableArray array]];
		for(i=0;i<kNumIpeFLTTests;i++) [testEnabledArray addObject:[NSNumber numberWithBool:YES]];
	}
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
    [encoder encodeInt:dataMask			forKey:@"ORIpeFLTModelDataMask"];
    [encoder encodeInteger:thresholdOffset		forKey:@"ORIpeFLTModelThresholdOffset"];
    [encoder encodeInt:interruptMask		forKey:@"ORIpeFLTModelInterruptMask"];
    [encoder encodeInt:coinTime			forKey:@"coinTime"];
    [encoder encodeInt:integrationTime	forKey:@"integrationTime"];
    [encoder encodeInt:page					forKey:@"ORIpeFLTModelPage"];
    [encoder encodeInteger:iterations			forKey:@"ORIpeFLTModelIterations"];
    [encoder encodeInteger:endChan				forKey:@"ORIpeFLTModelEndChan"];
    [encoder encodeInteger:startChan			forKey:@"ORIpeFLTModelStartChan"];
    [encoder encodeInteger:hitRateLength		forKey:@"ORIpeFLTModelHitRateLength"];
    [encoder encodeObject:triggersEnabled	forKey:@"ORIpeFLTModelTriggersEnabled"];
    [encoder encodeObject:gains				forKey:@"gains"];
    [encoder encodeObject:thresholds		forKey:@"thresholds"];
    [encoder encodeObject:hitRatesEnabled	forKey:@"hitRatesEnabled"];
    [encoder encodeInteger:fltRunMode			forKey:@"mode"];
    [encoder encodeObject:totalRate			forKey:@"totalRate"];
    [encoder encodeObject:testEnabledArray	forKey:@"testEnabledArray"];
    [encoder encodeObject:testStatusArray	forKey:@"testStatusArray"];
    [encoder encodeInteger:readoutPages  		forKey:@"ORIpeFLTModelReadoutPages"];	
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORIpeFLTDecoderForWaveForm",		@"decoder",
								 [NSNumber numberWithLong:waveFormId],   @"dataId",
								 [NSNumber numberWithBool:YES],			@"variable",
								 [NSNumber numberWithLong:-1],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"IpeFLTWaveForm"];
	
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   [NSNumber numberWithLong:dataId],				@"dataId",
				   [NSNumber numberWithLong:kNumFLTChannels],		@"maxChannels",
				   nil];
	
	[anEventDictionary setObject:aDictionary forKey:@"IpeFLT"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:thresholds			forKey:@"thresholds"];
    [objDictionary setObject:gains				forKey:@"gains"];
    [objDictionary setObject:hitRatesEnabled	forKey:@"hitRatesEnabled"];
    [objDictionary setObject:triggersEnabled	forKey:@"triggersEnabled"];
	
	return objDictionary;
}

- (void) reset
{
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	id slt = [[self crate] adapter];
	
	firstTime = YES;
	
    [self clearExceptionCount];
	
	//check that we can actually run
    if(![[[self crate] adapter] serviceIsAlive]){
		[NSException raise:@"No FireWire Service" format:@"Check Crate Power and FireWire Cable."];
    }
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORIpeFLTModel"];    
    //----------------------------------------------------------------------------------------	
	
	//check which mode to use
	BOOL ratesEnabled = NO;
	int i;
	for(i=0;i<kNumFLTChannels;i++){
		if([self hitRateEnabled:i]){
			ratesEnabled = YES;
			break;
		}
	}
	
    //if([[userInfo objectForKey:@"doinit"]intValue]){
	[self setLedOff:NO];
	[self initBoard];					
	//}
	
	
	if(ratesEnabled){
		[self performSelector:@selector(readHitRates) 
				   withObject:nil 
				   afterDelay:[self hitRateLength]];		//start reading out the rates
	}
	
	
	// TODO: For the auger FPGA set readoutPage always to 1
	// ak, 5.10.2007
	readoutPages = 1;
	
	//cache some addresses for speed in the dataTaking loop.
	uint32_t theSlotPart = [self slot]<<24;
	statusAddress			  = theSlotPart;
	memoryAddress			  = theSlotPart | (ipeReg[kFLTAdcMemory].space << kIpeFlt_AddressSpace); 
	fireWireCard			  = [[self crate] adapter];
	locationWord			  = (([self crateNumber]&0x0f)<<21) | (([self stationNumber]& 0x0000001f)<<16);
  	usingPBusSimulation		  = [fireWireCard pBusSim];
	pageSize                  = [slt pageSize];  //us
}


//**************************************************************************************
// Function:	

// Description: Read data from a card
//***************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{	
    @try {	
		
		//retrieve the parameters
		int fltPageStart = [[userInfo objectForKey:@"page"] intValue];
		int lStart		 = [[userInfo objectForKey:@"lStart"] intValue];
		uint32_t pixelList = [[userInfo objectForKey:@"pixelList"] intValue]; // ak, 5.10.2007
		uint32_t fltSize = pageSize * 5; // Size in int32_t words
		
		//int eventCounter = [[userInfo objectForKey:@"eventCounter"] intValue];
		[self eventMask:pixelList];	
		
		//NSLog(@"Pixellist = %08x\n", pixelList);	
		
		int aChan;
		for(aChan=0;aChan<kNumFLTChannels;aChan++){	
		    if ((((pixelList >> aChan) & 0x1) == 0x1)) {	
			    //NSLog(@"Reading channel (%d,%d)\n", [self slot], aChan);
				
				locationWord &= 0xffff0000;
				locationWord |= (aChan&0xff)<<8;
				
				uint32_t totalLength = (2 + readoutPages * fltSize);	// longs
				//uint32_t totalLength = (2 + 500);	// longs
				NSMutableData* theWaveFormData = [NSMutableData dataWithCapacity:totalLength*sizeof(int32_t)];
				uint32_t header = waveFormId | totalLength;
				
				[theWaveFormData appendBytes:&header length:4];				           //ORCA header word¶
				[theWaveFormData appendBytes:&locationWord length:4];		           //which crate, which card info
				
				[theWaveFormData setLength:totalLength*sizeof(int32_t)]; //we're going to dump directly into the NSData object so
				//we have to set the total size first. (Note: different than 'Capacity')
				
				
				short* waveFormPtr = ((short*)[theWaveFormData bytes]) + (4*sizeof(short)); //point to start of waveform
				uint32_t* wPtr = (uint32_t*)waveFormPtr;
				
				int i;
				int j;
				int32_t addr =  memoryAddress | (aChan << kIpeFlt_ChannelAddress) | (fltPageStart<<10) | lStart; // ak, 5.10.07
				uint32_t finalDataMask = dataMask;
				if(finalDataMask==0)finalDataMask = 0x0fff;
				for (j=0;j<readoutPages;j++){
					
					// Use block read mode.
					// With every 32bit (int32_t word) two 12bit ADC values are transmitted
					// documentation says 1000 data words followed by 24 words not used
					[fireWireCard read:addr
                                  data:wPtr
                                  size:(uint32_t)fltSize*sizeof(uint32_t)];
					
					// Remove the flags
					// TODO: Add a control to enable or disable flags in the data
					//       Better: Improve the display, define a variable number of
					//               flags that can be defined and stored with the Orca settings.
					// MAH:  07/17/09 added the data mask to make Brandon Happy.
					for (i=0;i<2*fltSize;i++)
						waveFormPtr[i] = waveFormPtr[i] & finalDataMask;					
					
					wPtr += fltSize;				
					addr = (addr + 1024) % 0x10000;
				}
				
				[aDataPacket addData:theWaveFormData]; //ship the waveform
				
			}
		} // end of loop over all channel
		
	}
	@catch(NSException* localException) {
		
		NSLogError(@"",@"Ipe FLT Card Error",[NSString stringWithFormat:@"Card%d",(int)[self stationNumber]],@"Data Readout",nil);
		[self incExceptionCount];
		[localException raise];
		
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	[self setLedOff:YES];
	[self writeControlStatus];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
	int chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		hitRate[chan] = 0;
	}
	[self setHitRateTotal:0];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelHitRateChanged object:self];
}

#pragma mark ¥¥¥HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}

- (int) numberOfChannels
{
    return kNumFLTChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:32000 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gain"];
    [p setFormat:@"##0" upperLimit:255 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setGain:withValue:) getMethod:@selector(gain:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setTriggerEnabled:withValue:) getMethod:@selector(triggerEnabled:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"HitRate Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setHitRateEnabled:withValue:) getMethod:@selector(hitRateEnabled:)];
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
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORIpeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"ORIpeFLTModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORIpeFLTModel"]];
    return a;
	
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Threshold"]){
        return  [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    }
    else if([param isEqualToString:@"Gain"]){
		return [[cardDictionary objectForKey:@"gains"] objectAtIndex:aChannel];
	}
    else if([param isEqualToString:@"TriggerEnabled"]){
		return [[cardDictionary objectForKey:@"triggersEnabled"] objectAtIndex:aChannel];
	}
    else if([param isEqualToString:@"HitRateEnabled"]){
		return [[cardDictionary objectForKey:@"hitRatesEnabled"] objectAtIndex:aChannel];
	}
    else return nil;
}
//for adcProvidingProtocol... but not used for now
- (uint32_t) eventCount:(int)channel
{
	return 0;
}
- (void) clearEventCounts
{
}
- (uint32_t) thresholdForDisplay:(unsigned short) aChan
{
	return [self threshold:aChan];
}
- (unsigned short) gainForDisplay:(unsigned short) aChan
{
	return [self gain:aChan];
}
@end

@implementation ORIpeFLTModel (tests)
#pragma mark ¥¥¥Accessors
- (BOOL) testsRunning
{
    return testsRunning;
}

- (void) setTestsRunning:(BOOL)aTestsRunning
{
    testsRunning = aTestsRunning;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelTestsRunningChanged object:self];
}

- (NSMutableArray*) testEnabledArray
{
    return testEnabledArray;
}

- (void) setTestEnabledArray:(NSMutableArray*)aTestEnabledArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestEnabledArray:testEnabledArray];
    
    [aTestEnabledArray retain];
    [testEnabledArray release];
    testEnabledArray = aTestEnabledArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelTestEnabledArrayChanged object:self];
}

- (NSMutableArray*) testStatusArray
{
    return testStatusArray;
}

- (void) setTestStatusArray:(NSMutableArray*)aTestStatusArray
{
    [aTestStatusArray retain];
    [testStatusArray release];
    testStatusArray = aTestStatusArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelTestStatusArrayChanged object:self];
}

- (NSString*) testStatus:(int)index
{
	if(index<[testStatusArray count])return [testStatusArray objectAtIndex:index];
	else return @"---";
}

- (BOOL) testEnabled:(int)index
{
	if(index<[testEnabledArray count])return [[testEnabledArray objectAtIndex:index] boolValue];
	else return NO;
}

- (void) runTests
{
	if(!testsRunning){
		@try {
			[self setTestsRunning:YES];
			NSLog(@"Starting tests for FLT station %d\n",[self stationNumber]);
			
			//clear the status text array
			int i;
			for(i=0;i<kNumIpeFLTTests;i++){
				[testStatusArray replaceObjectAtIndex:i withObject:@"--"];
			}
			
			//create the test suit
			if(testSuit)[testSuit release];
			testSuit = [[ORTestSuit alloc] init];
			if([self testEnabled:0]) [testSuit addTest:[ORTest testSelector:@selector(modeTest) tag:0]];
			if([self testEnabled:1]) [testSuit addTest:[ORTest testSelector:@selector(ramTest) tag:1]];
			if([self testEnabled:2]) [testSuit addTest:[ORTest testSelector:@selector(thresholdGainTest) tag:2]];
			if([self testEnabled:3]) [testSuit addTest:[ORTest testSelector:@selector(speedTest) tag:3]];
			if([self testEnabled:4]) [testSuit addTest:[ORTest testSelector:@selector(eventTest) tag:4]];
			
			[testSuit runForObject:self];
		}
		@catch(NSException* localException) {
		}
	}
	else {
		NSLog(@"Tests for FLT (station: %d) stopped manually\n",[self stationNumber]);
		[testSuit stopForObject:self];
	}
}

- (void) runningTest:(int)aTag status:(NSString*)theStatus
{
	[testStatusArray replaceObjectAtIndex:aTag withObject:theStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeFLTModelTestStatusArrayChanged object:self];
}


#pragma mark ¥¥¥Tests
- (void) modeTest
{
	int testNumber = 0;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	savedMode = fltRunMode;
	@try {
		BOOL passed = YES;
		int i;
		for(i=0;i<2;i++){
			fltRunMode = i;
			[self writeControlStatus];
			if([self readMode] != i){
				[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
				passed = NO;
				break;
			}
			if(passed){
				fltRunMode = savedMode;
				[self writeControlStatus];
				if([self readMode] != savedMode){
					[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
					passed = NO;
				}
			}
		}
		if(passed){
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}
	
	[testSuit runForObject:self]; //do next test
}


- (void) ramTest
{
	int testNumber = 1;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	unsigned short pat1[kIpeFlt_Page_Size],buf[kIpeFlt_Page_Size];
	int i,chan;
	for(i=0;i<kIpeFlt_Page_Size;i++)pat1[i]=i;
	
	@try {
		[self enterTestMode];
		int aPage;
		
		int n_error = 0;
		for (chan=startChan;chan<=endChan;chan++) {
			for(aPage=0;aPage<32;aPage++) {
				[self writeMemoryChan:chan page:aPage pageBuffer:pat1];
				[self readMemoryChan:chan page:aPage pageBuffer:buf];
				
				if ([self compareData:buf pattern:pat1 shift:0 n:kIpeFlt_Page_Size] != kIpeFlt_Page_Size) n_error++;
			}
		}
		if(n_error != 0){
			[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
			NSLog(@"Errors in %d pages found\n",n_error);
		}
		else {
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
		
		[self leaveTestMode];
		
		
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
	
}


- (void) thresholdGainTest
{
	int testNumber = 2;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	@try {
		[self enterTestMode];
		uint32_t aPattern[4] = {0x3fff,0x0,0x2aaa,0x1555};
		int chan;
		BOOL passed = YES;
		int testIndex;
		//thresholds first
		for(testIndex = 0;testIndex<4;testIndex++){
			unsigned short thePattern = aPattern[testIndex];
			for(chan=0;chan<kNumFLTChannels;chan++){
				[self writeThreshold:chan value:thePattern];
			}
			
			for(chan=0;chan<kNumFLTChannels;chan++){
				if([self readThreshold:chan] != thePattern){
					[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
					NSLog(@"Error: Threshold (pattern: 0x%0x) FLT %d chan %d does not work\n",thePattern,[self stationNumber],chan);
					passed = NO;
					break;
				}
			}
		}
		if(passed){		
			uint32_t gainPattern[4] = {0xff,0x0,0xaa,0x55};
			
			//now gains
			for(testIndex = 0;testIndex<4;testIndex++){
				unsigned short thePattern = gainPattern[testIndex];
				for(chan=0;chan<kNumFLTChannels;chan++){
					[self writeGain:chan value:thePattern];
				}
				
				for(chan=0;chan<kNumFLTChannels;chan++){
					if([self readGain:chan] != thePattern){
						[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
						NSLog(@"Error: Gain (pattern: 0x%0x) FLT %d chan %d does not work\n",thePattern,[self stationNumber],chan);
						passed = NO;
						break;
					}
				}
			}
		}
		if(passed) {
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
		
		[self loadThresholdsAndGains];
		
		[self leaveTestMode];
		
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
	
}


- (void) speedTest
{
	int testNumber = 3;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	unsigned short buf[kIpeFlt_Page_Size];
	ORTimer* timer = [[ORTimer alloc] init];
	[timer reset];
	
	@try {
		[self enterTestMode];		
		[timer start];
		[self readMemoryChan:startChan page:page pageBuffer:buf];
		[timer stop];
		NSLog(@"FLT %d page readout: %.2f sec\n",[self stationNumber],[timer seconds]);
		int i;
		[timer start];
		for(i=0;i<10000;i++){
			[self readMemoryChan:1 page:15];
		}
		[timer stop];
		NSLog(@"FLT %d single memory address readout: %.2f ms\n",[self stationNumber],[timer seconds]/10.);
		
		
		[self runningTest:testNumber status:@"See StatusLog"];
		
		[self leaveTestMode];
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
		
	}		
	[timer release];
	
	[testSuit runForObject:self]; //do next test
	
}

- (void) eventTest
{
	int testNumber = 4;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	@try {
		//cache some addresses.
		statusAddress		= [self regAddress:kFLTControlReg];
		
		//flash the led
		id slt = [[self crate] adapter];
		savedMode = fltRunMode;
		savedLed  = ledOff;
		ledOff	  = NO;
		
		int i;
		for(i=0;i<10;i++){
			ledOff	  = i%2;
			[self writeControlStatus];
			[ORTimer delay:.1];
		}
		
		ledOff	  = YES;
		[self writeControlStatus];
		
		//go to test mode
		fltRunMode = kIpeFlt_Run_Mode;
		ledOff = YES;
		
		[self writeControlStatus];
		
		if([self readMode] != kIpeFlt_Run_Mode){
			NSLogColor([NSColor redColor],@"Could not put FLT %d into run mode\n",[self stationNumber]);
			[NSException raise:@"Ram Test Failed" format:@"Could not put FLT %d into test mode\n",(int)[self stationNumber]];
		}
		
		[self initBoard];
		
		NSLog(@"FLT %d\n",[self stationNumber]);
		
		[slt setSwInhibit]; 
		[slt releaseAllPages]; 
		[slt releaseSwInhibit]; 
		
		int numPulses = 10;
		for(i=0;i<numPulses;i++){
			[slt pulseOnce];
			[ORTimer delay:.1];
		}
		[slt readPageStatus];
		uint32_t lowStatus = [slt pageStatusLow];
		uint32_t highStatus = [slt pageStatusHigh];
		if(lowStatus | highStatus){
			NSLog(@"---Event Data---\n");
			int sum = 0;
			for(i=0;i<32;i++){
				if(lowStatus & (0x1<<i))sum++;
				if(highStatus & (0x1<<i))sum++;
			}
			if(sum == numPulses){
				NSLogColor([NSColor passedColor],@"Passed: %d sw triggers == %d pages used\n",numPulses,sum);
			}
			else {
				NSLogColor([NSColor failedColor],@"Passed: %d sw triggers == %d pages used\n",numPulses,sum);
				[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
			}
		}
		else NSLog(@"No Data\n");
		
		[self runningTest:testNumber status:@"See StatusLog"];
		
		fltRunMode = savedMode;
		ledOff   = savedLed;
		[self writeControlStatus];
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
		
	}		
	
	[testSuit runForObject:self]; //do next test
	
}

- (int) compareData:(unsigned short*) data
			pattern:(unsigned short*) pattern
			  shift:(int) shift
				  n:(int) n 
{
    int i, j;
	
	// Check for errors
	for (i=0;i<n;i++) {
		if (data[i]!=pattern[(i+shift)%n]) {
			for (j=(i/4);(j<i/4+3) && (j < n/4);j++){
				NSLog(@"%04x: %04x %04x %04x %04x - %04x %04x %04x %04x \n",j*4,
					  data[j*4],data[j*4+1],data[j*4+2],data[j*4+3],
					  pattern[(j*4+shift)%n],  pattern[(j*4+1+shift)%n],
					  pattern[(j*4+2+shift)%n],pattern[(j*4+3+shift)%n]  );
				if(i==0)return i; // check only for one error in every page!
			}
		}
	}
	
	return n;
}

@end

@implementation ORIpeFLTModel (private)

- (NSAttributedString*) test:(int)testIndex result:(NSString*)result color:(NSColor*)aColor
{
	NSLogColor(aColor,@"%@ test %@\n",fltTestName[testIndex],result);
	id theString = [[NSAttributedString alloc] initWithString:result 
												   attributes:[NSDictionary dictionaryWithObject: aColor forKey:NSForegroundColorAttributeName]];
	
	[self runningTest:testIndex status:theString];
	return [theString autorelease];
}

- (void) enterTestMode
{
	//put into test mode
	savedMode = fltRunMode;
	fltRunMode = kIpeFlt_Test_Mode;
	[self writeControlStatus];
	if([self readMode] != kIpeFlt_Test_Mode){
		NSLogColor([NSColor redColor],@"Could not put FLT %d into test mode\n",[self stationNumber]);
		[NSException raise:@"Ram Test Failed" format:@"Could not put FLT %d into test mode\n",(int)[self stationNumber]];
	}
}

- (void) leaveTestMode
{
	fltRunMode = savedMode;
	[self writeControlStatus];
}
@end
