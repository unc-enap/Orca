/*
 *  ORJAMFModel.cpp
 *  Joerger Enterprises, Inc. 16 Channel Analog Scanning ADC
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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

#pragma mark •••Imported Files
#import "ORJAMFModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORCamacControllerCard.h"
#import "ORCamacCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORTimeRate.h"
#import "ORAxis.h"
#import "ORDataTypeAssigner.h"

NSString* ORJAMFModelShipRecordsChanged = @"ORJAMFModelShipRecordsChanged";
NSString* ORJAMFModelScanEnabledChanged = @"ORJAMFModelScanEnabledChanged";
NSString* ORJAMFModelScanLimitChanged = @"ORJAMFModelScanLimitChanged";
NSString* ORJAMFModelPollingStateChanged	= @"ORJAMFModelPollingStateChanged";
NSString* ORJAMFModelLastReadChanged		= @"ORJAMFModelLastReadChanged";
NSString* ORJAMFModelRangeIndexChanged		= @"ORJAMFModelRangeIndexChanged";
NSString* ORJAMFChan						= @"ORJAMFChan";
NSString* ORJAMFModelEnabledMaskChanged		= @"ORJAMFModelEnabledMaskChanged";
NSString* ORJAMFModelAlarmsEnabledMaskChanged = @"ORJAMFModelAlarmsEnabledMaskChanged";
NSString* ORJAMFModelHighLimitChanged		= @"ORJAMFModelHighLimitChanged";
NSString* ORJAMFModelLowLimitChanged		= @"ORJAMFModelLowLimitChanged";
NSString* ORJAMFModelAdcValueChanged		= @"ORJAMFModelAdcValueChanged";
NSString* ORJAMFSettingsLock				= @"ORJAMFSettingsLock";

struct {
	float lowRange;
	float highRange;
} adcfRanges[3]={
{-10.0,10.0},
{-5.0,5.0},
{-1.0,1.0}
};

@interface ORJAMFModel (private)
- (void) _clearAlarms:(int)aChan;
- (void) _setUpPolling;
- (void) _pollAllChannels;
- (void) _checkAlarm:(int)aChan;
@end

@implementation ORJAMFModel

#pragma mark •••Initialization
- (id) init
{		
    self = [super init];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [lastRead release];
	int chan;
	for(chan=0;chan<16;chan++){
		[lowAlarms[chan] release];
		[highAlarms[chan] release];
		[timeRates[chan] release];
	}
    [super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
        [self _setUpPolling];
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
    [self setImage:[NSImage imageNamed:@"JAMF"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORJAMFController"];
}

- (NSString*) helpURL
{
	return @"CAMAC/JAM_F.html";
}

#pragma mark •••Accessors

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (BOOL) shipRecords
{
    return shipRecords;
}

- (void) setShipRecords:(BOOL)aShipRecords
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipRecords:shipRecords];
    
    shipRecords = aShipRecords;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJAMFModelShipRecordsChanged object:self];
}

- (BOOL) scanEnabled
{
    return scanEnabled;
}

- (void) setScanEnabled:(BOOL)aScanEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setScanEnabled:scanEnabled];
    
    scanEnabled = aScanEnabled;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJAMFModelScanEnabledChanged object:self];
}

- (int) scanLimit
{
    return scanLimit;
}

- (void) setScanLimit:(int)aScanLimit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setScanLimit:scanLimit];
    
    scanLimit = aScanLimit;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJAMFModelScanLimitChanged object:self];
}

- (NSString*) shortName
{
	return @"JAMF";
}


- (ORTimeRate*)timeRate:(int)index
{
	return timeRates[index];
}

- (void) postNotification:(NSNotification*)aNote
{
	[[NSNotificationCenter defaultCenter] postNotification:aNote];
}

- (int) pollingState
{
    return pollingState;
}

- (void) setPollingState:(int)aPollingState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollingState:pollingState];
    
    pollingState = aPollingState;
    [self performSelector:@selector(_setUpPolling) withObject:nil afterDelay:0.5];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJAMFModelPollingStateChanged object:self];
}

- (NSString*) lastRead
{
    return lastRead;
}

- (void) setLastRead:(NSString*)aLastRead
{
    [lastRead autorelease];
    lastRead = [aLastRead copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJAMFModelLastReadChanged object:self];
}

- (int) rangeIndex:(int)aChan
{
	if(aChan<=0)aChan=0;
	else if(aChan>=15)aChan=15;
    return rangeIndex[aChan];
}

- (void) setRangeIndex:(int)aChan withValue:(int)aRangeIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRangeIndex:aChan withValue:rangeIndex[aChan]];
    
    rangeIndex[aChan] = aRangeIndex;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJAMFModelRangeIndexChanged object:self];
}

- (unsigned short) enabledMask
{
    return enabledMask;
}

- (void) setEnabledMask:(unsigned short)aEnabledMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
    
    enabledMask = aEnabledMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJAMFModelEnabledMaskChanged object:self];
}

- (BOOL)enabledBit:(int)bit
{
	return enabledMask&(1<<bit);
}

- (void) setEnabledBit:(int)bit withValue:(BOOL)aValue
{
	unsigned char aMask = enabledMask;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setEnabledMask:aMask];
}

- (unsigned short) alarmsEnabledMask
{
    return alarmsEnabledMask;
}

- (void) setAlarmsEnabledMask:(unsigned short)aEnabledMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAlarmsEnabledMask:alarmsEnabledMask];
    
    alarmsEnabledMask = aEnabledMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJAMFModelAlarmsEnabledMaskChanged object:self];
}

- (BOOL)alarmsEnabledBit:(int)bit
{
	return alarmsEnabledMask&(1<<bit);
}

- (void) setAlarmsEnabledBit:(int)bit withValue:(BOOL)aValue
{
	unsigned char aMask = alarmsEnabledMask;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setAlarmsEnabledMask:aMask];
}

- (float) highLimit:(unsigned short)aChan
{
	return highLimits[aChan];
}

-(void) setHighLimit:(unsigned short) aChan withValue:(float) aHighLimit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHighLimit:aChan withValue:[self highLimit:aChan]];
    
    highLimits[aChan] = aHighLimit;
	
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORJAMFChan];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJAMFModelHighLimitChanged object:self userInfo:userInfo];
}

- (float) lowLimit:(unsigned short)aChan
{
    return lowLimits[aChan];
}

-(void) setLowLimit:(unsigned short) aChan withValue:(float) aLowLimit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:aChan withValue:[self lowLimit:aChan]];
    
    lowLimits[aChan] = aLowLimit;
	
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORJAMFChan];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJAMFModelLowLimitChanged object:self userInfo:userInfo];
}

- (float) adcValue:(unsigned short)aChan
{
    return adcValue[aChan];
}

-(void) setAdcValue:(unsigned short) aChan withValue:(float) anAdcValue
{
    
	if(anAdcValue != adcValue[aChan]){
		adcValue[aChan] = anAdcValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORJAMFChan];
		
		[self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:ORJAMFModelAdcValueChanged object:self userInfo:userInfo] waitUntilDone:NO];
		
	}
	
	if(timeRates[aChan] == nil) timeRates[aChan] = [[ORTimeRate alloc] init];
	[timeRates[aChan] addDataToTimeAverage:anAdcValue];
}

- (float) adcRange:(unsigned short)aChan
{
    return adcRange[aChan];
}

-(void) setAdcRange:(unsigned short) aChan withValue:(int) anAdcRange
{    
    adcRange[aChan] = anAdcRange;
	
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORJAMFChan];
	
	[self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:ORJAMFModelAdcValueChanged object:self userInfo:userInfo] waitUntilDone:NO];
}



- (NSString*) identifier
{
    return [NSString stringWithFormat:@"JAM-F (Station %d) ",[self slot]];
}

#pragma mark •••Hardware Test functions

- (void) readAdcs:(BOOL)verbose
{
	@synchronized(self){
		if(verbose)NSLog(@"Adc values for JAM-F (station %d)\n",[self stationNumber]);
		if(enabledMask){
			int chan;
			for(chan=0;chan<16;chan++){
				if(enabledMask & (0x1L<<chan)){
					[[self adapter] camacShortNAF:[self stationNumber] a:chan f:0 data:&theRawValues[chan]];
					
					float theValue = [self convertRawAdcToVolts:theRawValues[chan]&0xfff chan:chan];
					[self setAdcValue:chan withValue:theValue];
					
					if(theValue<lowLimits[chan])		[self setAdcRange:chan withValue:kAdcFRangeLow];
					else if(theValue>highLimits[chan])[self setAdcRange:chan withValue:kAdcFRangeHigh];
					else			[self setAdcRange:chan withValue:kAdcFRangeOK];
					
					if(verbose){
						NSString* s1 = @"In Range";
						if(adcRange[chan] == kAdcFRangeLow)		 s1 = @"Too low";
						else if(adcRange[chan] == kAdcFRangeHigh)s1 = @"Too High";
						NSLog(@"%2d:%.2f %@\n",chan,adcValue[chan],s1);
					}
				}
				else {
					[self setAdcValue:chan withValue:0];
					[self setAdcRange:chan withValue:kAdcFRangeOK];		
				}
				
				[self _checkAlarm:chan];
			}
			[self setLastRead:[[NSDate date] stdDescription]];
			
		}
		else NSLog(@"nothing enabled\n");
	}
}

- (void) readAdcChannel:(int)aChan
{
	@synchronized(self){
		if(enabledMask & (0x1L<<aChan)){
			unsigned long theRawValue;
			[[self adapter] camacLongNAF:[self stationNumber] a:aChan f:0 data:&theRawValue];
			float theValue = [self convertRawAdcToVolts:theRawValue  chan:aChan];
			[self setAdcValue:aChan withValue:theValue];
			
			if(theValue<lowLimits[aChan])		[self setAdcRange:aChan withValue:kAdcFRangeLow];
			else if(theValue>highLimits[aChan])[self setAdcRange:aChan withValue:kAdcFRangeHigh];
			else			[self setAdcRange:aChan withValue:kAdcFRangeOK];
		}
		else {
			[self setAdcValue:aChan withValue:0];
			[self setAdcRange:aChan withValue:kAdcFRangeOK];		
		}
		[self _checkAlarm:aChan];
	}
}

- (float) convertRawAdcToVolts:(unsigned short)rawValue chan:(int)aChan
{
	rawValue &= 0xfff;
	
	float slope     = (adcfRanges[rangeIndex[aChan]].highRange - adcfRanges[rangeIndex[aChan]].lowRange)/4096.;
	float intercept = adcfRanges[rangeIndex[aChan]].lowRange;
	return slope * rawValue + intercept;
}

- (float) convertRawLimitToVolts:(unsigned short)rawValue chan:(int)aChan
{
	float slope     = (adcfRanges[rangeIndex[aChan]].highRange - adcfRanges[rangeIndex[aChan]].lowRange)/4096.;
	float intercept = adcfRanges[rangeIndex[aChan]].lowRange;
	return slope * (rawValue & 0xfff) + intercept;
}

- (unsigned short) convertVoltsToRawLimit:(float)volts chan:(int)aChan
{
	float slope     = (adcfRanges[rangeIndex[aChan]].highRange - adcfRanges[rangeIndex[aChan]].lowRange)/4096.;
	float intercept = adcfRanges[rangeIndex[aChan]].lowRange;
	unsigned short theValue =  (unsigned short)((volts-intercept)/slope);
	if(theValue>4095)theValue = 4095;
	return theValue;
}

- (void) initBoard
{
	unsigned short aValue;
	int chan;
	for(chan=0;chan<16;chan++){
		aValue = (rangeIndex[chan]<<7) | (scanLimit<<5) | 0x0010 | chan;
		[[self adapter] camacShortNAF:[self stationNumber] a:0 f:17 data:&aValue];
	}
	aValue = scanEnabled;
	[[self adapter] camacShortNAF:[self stationNumber] a:0 f:17 data:&aValue];
	
}

- (unsigned short) readBoardID
{
	unsigned short aValue;
	[[self adapter] camacShortNAF:[self stationNumber] a:15 f:1 data:&aValue];
	return aValue;
}


#pragma mark •••Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setShipRecords:[decoder decodeBoolForKey:@"ORJAMFModelShipRecords"]];
    [self setScanEnabled:[decoder decodeBoolForKey:@"ORJAMFModelScanEnabled"]];
    [self setScanLimit:[decoder decodeIntForKey:@"ORJAMFModelScanLimit"]];
    [self setPollingState:[decoder decodeIntForKey:@"ORJAMFModelPollingState"]];
    [self setEnabledMask:[decoder decodeIntForKey: @"ORJAMFModelEnabledMask"]];
    [self setAlarmsEnabledMask:[decoder decodeIntForKey: @"ORJAMFModelAlarmsEnabledMask"]];
	int i;
	for(i=0;i<16;i++){
		timeRates[i] = [[ORTimeRate alloc] init];
		[self setLowLimit:i withValue:[decoder decodeFloatForKey:  [NSString stringWithFormat:@"ORJAMFModelLowLimit_%d",i]]];
		[self setHighLimit:i withValue:[decoder decodeFloatForKey: [NSString stringWithFormat:@"ORJAMFModelHighLimit_%d",i]]];
		[self setRangeIndex:i withValue:[decoder decodeIntForKey:  [NSString stringWithFormat:@"ORJAMFModelRangeIndex_%d",i]]];
	}
	[self setLastRead:@"Never"];
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];	
    [encoder encodeBool:shipRecords forKey:@"ORJAMFModelShipRecords"];
    [encoder encodeBool:scanEnabled forKey:@"ORJAMFModelScanEnabled"];
    [encoder encodeInt:scanLimit forKey:@"ORJAMFModelScanLimit"];
    [encoder encodeInt:pollingState			forKey:@"ORJAMFModelPollingState"];
    [encoder encodeInt:enabledMask			forKey:	@"ORJAMFModelEnabledMask"];
    [encoder encodeInt:alarmsEnabledMask	forKey:	@"ORJAMFModelAlarmsEnabledMask"];
	
	int i;
	for(i=0;i<16;i++){
		[encoder encodeFloat: lowLimits[i] forKey: [NSString stringWithFormat:@"ORJAMFModelLowLimit_%d",i]];
		[encoder encodeFloat: highLimits[i] forKey: [NSString stringWithFormat:@"ORJAMFModelHighLimit_%d",i]];
		[encoder encodeInt:rangeIndex[i]	forKey:[NSString stringWithFormat:@"ORJAMFModelRangeIndex_%d",i]];
	}
}

#pragma mark •••Bit Processing Protocol

//note that everything called by these routines MUST be threadsafe
- (void)processIsStarting
{
	[self initBoard];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self setLastRead:@"Via Process Manager"];
}

- (void)processIsStopping
{
	[self _setUpPolling];
	[self setLastRead:[[NSDate date] description]];
}

- (void) startProcessCycle
{
	[self readAdcs:NO];
}

- (void) endProcessCycle
{
    //nothing to do
}

- (BOOL) processValue:(int)channel
{
	return [self convertedValue:channel]!=0;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    //nothing to do
}

- (NSString*) processingTitle
{
    return [NSString stringWithFormat:@"%d,%d,JAM-F",[self crateNumber],[self  stationNumber]];
}

- (double) convertedValue:(int)channel
{
	return (double)adcValue[channel];
}

- (double) maxValueForChan:(int)channel
{
	double theMax = 0;
	@synchronized(self){
		theMax =  adcfRanges[rangeIndex[channel]].highRange;
	}
	return theMax;
}
- (double) minValueForChan:(int)channel
{
	double theMin = 0;
	@synchronized(self){
		theMin =  adcfRanges[rangeIndex[channel]].lowRange;
	}
	return theMin;
}
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		*theLowLimit  = (double)[self lowLimit:channel];
		*theHighLimit = (double)[self highLimit:channel];
	}		
}


#pragma mark •••HW Wizard

- (int) numberOfChannels
{
    return 16;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Low Limit"];
    [p setFormat:@"##0.00" upperLimit:10.24 lowerLimit:-10.24 stepSize:.01 units:@"V"];
    [p setSetMethod:@selector(setLowLimit:withValue:) getMethod:@selector(lowLimit:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"High Limit"];
    [p setFormat:@"##0.00" upperLimit:10.24 lowerLimit:-10.24 stepSize:.01 units:@"V"];
    [p setSetMethod:@selector(setHighLimit:withValue:) getMethod:@selector(highLimit:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEnabledBit:withValue:) getMethod:@selector(enabledBit:)];
    [p setActionMask:kAction_Set_Mask|kAction_Restore_Mask];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Alarm Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setAlarmsEnabledBit:withValue:) getMethod:@selector(alarmsEnabledBit:)];
    [p setActionMask:kAction_Set_Mask|kAction_Restore_Mask];
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
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORCamacCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORJAMFModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORJAMFModel"]];
    return a;
	
}

#pragma mark •••Data Records

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"JAMF"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORJAMFDecoderForAdc",							@"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:YES],                  @"variable",
								 [NSNumber numberWithLong:-1],					@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"JAMFADC"];
    
    return dataDictionary;
	
}

-(void) shipValues
{
	if([gOrcaGlobals runInProgress]){
		unsigned long data[32];
		
		data[1] = (([self crateNumber]&0x01e)<<21) | (([self stationNumber]& 0x0000001f)<<16);
		
		//get the time(UT!)
		time_t	ut_time;
		time(&ut_time);
		//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		//time_t ut_time = mktime(theTimeGMTAsStruct);
		data[2] = ut_time;	//seconds since 1970
		
		int index = 3;
		int i;
		for(i=0;i<16;i++){
			if(enabledMask & (1<<i)){
				data[index++] = (i&0xff)<<16 | (theRawValues[i] & 0xffff);
			}
		}
		data[0] = dataId | index;
		
		if(index>3){
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:index*sizeof(long)]];
		}
	}
}

@end

@implementation ORJAMFModel (private)
- (void) _checkAlarm:(int)aChan
{
	if(alarmsEnabledMask & (1<<aChan)){
		if(adcRange[aChan] == kAdcFRangeLow){
			if(!lowAlarms[aChan]){
				NSString* alarmName = [NSString stringWithFormat:@"ADC %@ chan:%d Low",[self processingTitle],aChan];
				lowAlarms[aChan] = [[ORAlarm alloc] initWithName:alarmName severity:kRangeAlarm];
				[lowAlarms[aChan] setSticky:YES];
				[lowAlarms[aChan] setHelpString:[NSString stringWithFormat:@"The adc value (chan %d) has dropped below the low alarm limit of %.2f",aChan, lowLimits[aChan]]];
				[lowAlarms[aChan] postAlarm];
			}
			if(highAlarms[aChan]){
				[highAlarms[aChan] clearAlarm];
				[highAlarms[aChan] release];
				highAlarms[aChan] = nil;
			}
		}
		else if(adcRange[aChan] == kAdcFRangeHigh){
			if(!highAlarms[aChan]){
				NSString* alarmName = [NSString stringWithFormat:@"ADC %@ chan:%d High",[self processingTitle],aChan];
				highAlarms[aChan] = [[ORAlarm alloc] initWithName:alarmName severity:kRangeAlarm];
				[highAlarms[aChan] setSticky:YES];
				[highAlarms[aChan] setHelpString:[NSString stringWithFormat:@"The adc value (chan %d) has risen above the high alarm limit of %.2f",aChan, highLimits[aChan]]];
				[highAlarms[aChan] postAlarm];
			}
			if(lowAlarms[aChan]){
				[lowAlarms[aChan] clearAlarm];
				[lowAlarms[aChan] release];
				lowAlarms[aChan] = nil;
			}
		}
		else {
			[self _clearAlarms:aChan];
		}
	}
	else {
		[self _clearAlarms:aChan];
	}
}

- (void) _clearAlarms:(int)aChan
{
	if(highAlarms[aChan]){
		[highAlarms[aChan] clearAlarm];
		[highAlarms[aChan] release];
		highAlarms[aChan] = nil;
	}
	if(lowAlarms[aChan]){
		[lowAlarms[aChan] clearAlarm];
		[lowAlarms[aChan] release];
		lowAlarms[aChan] = nil;
	}
}

- (void) _setUpPolling
{
    if(pollingState!=0){        
        NSLog(@"Polling JAM_F,%d,%d  every %d seconds.\n",[self crateNumber],[self stationNumber],pollingState);
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(_pollAllChannels) withObject:self afterDelay:pollingState];
        [self _pollAllChannels];
    }
    else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        NSLog(@"Not Polling JAM_F,%d,%d\n",[self crateNumber],[self stationNumber]);
    }
}
- (void) _pollAllChannels
{
    @try { 
        [self readAdcs:NO];
		if(shipRecords) [self shipValues];    
    }
	@catch(NSException* localException) { 
        //catch this here to prevent it from falling thru, but nothing to do.
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollingState!=0){
		[self performSelector:@selector(_pollAllChannels) withObject:nil afterDelay:pollingState];
	}
}


@end
