/*
 *  ORJADCLModel.cpp
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

#pragma mark ¥¥¥Imported Files
#import "ORJADCLModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORCamacControllerCard.h"
#import "ORCamacCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORTimeRate.h"
#import "NSNotifications+Extensions.h"

NSString* ORJADCLModelPollingStateChanged = @"ORJADCLModelPollingStateChanged";
NSString* ORJADCLModelLastReadChanged = @"ORJADCLModelLastReadChanged";
NSString* ORJADCLModelRangeIndexChanged = @"ORJADCLModelRangeIndexChanged";
NSString* ORJADCLChan					= @"ORJADCLChan";
NSString* ORJADCLModelEnabledMaskChanged = @"ORJADCLModelEnabledMaskChanged";
NSString* ORJADCLModelAlarmsEnabledMaskChanged = @"ORJADCLModelAlarmsEnabledMaskChanged";
NSString* ORJADCLModelHighLimitChanged	= @"ORJADCLModelHighLimitChanged";
NSString* ORJADCLModelLowLimitChanged	= @"ORJADCLModelLowLimitChanged";
NSString* ORJADCLModelAdcValueChanged	= @"ORJADCLModelAdcValueChanged";
NSString* ORJADCLSettingsLock			= @"ORJADCLSettingsLock";

struct {
	float lowRange;
	float highRange;
} adclRanges[5]={
{0,10.24},
{0,5.12},
{-10.24,10.24},
{-5.12,5.12},
{-2.56,2.56}
};

@interface ORJADCLModel (private)
- (void) _clearAlarms:(int)aChan;
- (void) _setUpPolling;
- (void) _pollAllChannels;
- (void) _checkAlarm:(int)aChan;
@end

@implementation ORJADCLModel

#pragma mark ¥¥¥Initialization
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
    [self setImage:[NSImage imageNamed:@"JADCLCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORJADCLController"];
}

- (NSString*) helpURL
{
	return @"CAMAC/JADCLA.html";
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"JADCL";
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJADCLModelPollingStateChanged object:self];
}

- (NSString*) lastRead
{
    return lastRead;
}

- (void) setLastRead:(NSString*)aLastRead
{
	@synchronized(self){
		[lastRead autorelease];
		lastRead = [aLastRead copy];    
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORJADCLModelLastReadChanged object:self userInfo:nil waitUntilDone:YES]; 
	}
}

- (int) rangeIndex
{
    return rangeIndex;
}

- (void) setRangeIndex:(int)aRangeIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRangeIndex:rangeIndex];
    
    rangeIndex = aRangeIndex;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJADCLModelRangeIndexChanged object:self];
}

- (unsigned short) enabledMask
{
    return enabledMask;
}

- (void) setEnabledMask:(unsigned short)aEnabledMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
    
    enabledMask = aEnabledMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJADCLModelEnabledMaskChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJADCLModelAlarmsEnabledMaskChanged object:self];
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
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORJADCLChan];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJADCLModelHighLimitChanged object:self userInfo:userInfo];
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
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORJADCLChan];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORJADCLModelLowLimitChanged object:self userInfo:userInfo];
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
		[userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORJADCLChan];
		
		[self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:ORJADCLModelAdcValueChanged object:self userInfo:userInfo] waitUntilDone:NO];
		
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
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORJADCLChan];
	
	[self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:ORJADCLModelAdcValueChanged object:self userInfo:userInfo] waitUntilDone:NO];
}



- (NSString*) identifier
{
    return [NSString stringWithFormat:@"JADC-L (Station %d) ",[self slot]];
}

#pragma mark ¥¥¥Hardware Test functions
- (BOOL) adcTooLow:(uint32_t) aRawValue
{
	return (aRawValue & 0x10000)>0;
}

- (BOOL) adcTooHigh:(uint32_t) aRawValue
{
	return (aRawValue & 0x20000)>0;
}


- (void) readAdcs:(BOOL)verbose
{
	@synchronized(self){
		if(verbose)NSLog(@"Adc values for JADC-L (station %d)\n",[self stationNumber]);
		if(enabledMask){
			int chan;
			for(chan=0;chan<16;chan++){
				if(enabledMask & (0x1L<<chan)){
					[self readAdcChannel:chan];
					if(verbose){
						NSString* s1 = @"In Range";
						if(adcRange[chan] == kAdcLRangeLow)		 s1 = @"Too low";
						else if(adcRange[chan] == kAdcLRangeHigh)s1 = @"Too High";
						NSLog(@"%2d:%.2f %@\n",chan,adcValue[chan],s1);
					}
				}
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
			uint32_t theRawValue;
			[[self adapter] camacLongNAF:[self stationNumber] a:aChan f:0 data:&theRawValue];
			BOOL tooLow = [self adcTooLow:theRawValue];
			BOOL tooHigh = [self adcTooHigh:theRawValue];
			float theValue = [self convertRawAdcToVolts:theRawValue];
			[self setAdcValue:aChan withValue:theValue];
			
			if(tooLow)		[self setAdcRange:aChan withValue:kAdcLRangeLow];
			else if(tooHigh)[self setAdcRange:aChan withValue:kAdcLRangeHigh];
			else			[self setAdcRange:aChan withValue:kAdcLRangeOK];
		}
		else {
			[self setAdcValue:aChan withValue:0];
			[self setAdcRange:aChan withValue:kAdcLRangeOK];		
		}
		[self _checkAlarm:aChan];
	}
}

- (void) readLimits
{
	@synchronized(self){
		unsigned short theLowLimit[16];
		unsigned short theHighLimit[16];
		NSLog(@"Lower and Upper limits for JADC-L (station %d)\n",[self stationNumber]);
		int chan;
		for(chan=0;chan<16;chan++){
			[[self adapter] camacShortNAF:[self stationNumber] a:chan f:4 data:&theLowLimit[chan]]; //read lower limit
			[[self adapter] camacShortNAF:[self stationNumber] a:chan f:6 data:&theHighLimit[chan]]; //read lower limit
		}
		for(chan=0;chan<16;chan++){
			NSLog(@"%2d:%.2f %.2f\n",chan,[self convertRawLimitToVolts:theLowLimit[chan]],[self convertRawLimitToVolts:theHighLimit[chan]]);
		}
	}	
}

- (float) convertRawAdcToVolts:(unsigned short)rawValue
{
	rawValue &= 0xfff;
	
	float slope     = (adclRanges[rangeIndex].highRange - adclRanges[rangeIndex].lowRange)/4096.;
	float intercept = adclRanges[rangeIndex].lowRange;
	return slope * rawValue + intercept;
}

- (float) convertRawLimitToVolts:(unsigned short)rawValue
{
	float slope     = (adclRanges[rangeIndex].highRange - adclRanges[rangeIndex].lowRange)/4096.;
	float intercept = adclRanges[rangeIndex].lowRange;
	return slope * (rawValue & 0xfff) + intercept;
}

- (unsigned short) convertVoltsToRawLimit:(float)volts
{
	float slope     = (adclRanges[rangeIndex].highRange - adclRanges[rangeIndex].lowRange)/4096.;
	float intercept = adclRanges[rangeIndex].lowRange;
	unsigned short theValue =  (unsigned short)((volts-intercept)/slope);
	if(theValue>4095)theValue = 4095;
	return theValue;
}

- (void) initBoard
{
	int chan;
	for(chan=0;chan<16;chan++){
		unsigned short value;
		value = [self convertVoltsToRawLimit:lowLimits[chan]];
		[[self adapter] camacShortNAF:[self stationNumber] a:chan f:20 data:&value];
		value = [self convertVoltsToRawLimit:highLimits[chan]];
		[[self adapter] camacShortNAF:[self stationNumber] a:chan f:22 data:&value];
	}
	unsigned short aMask = enabledMask;
	[[self adapter] camacShortNAF:[self stationNumber] a:0 f:17 data:&aMask];
}



#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setPollingState:[decoder decodeIntForKey:@"ORJADCLModelPollingState"]];
    [self setRangeIndex:[decoder decodeIntForKey:  @"ORJADCLModelRangeIndex"]];
    [self setEnabledMask:[decoder decodeIntegerForKey: @"ORJADCLModelEnabledMask"]];
    [self setAlarmsEnabledMask:[decoder decodeIntegerForKey: @"ORJADCLModelAlarmsEnabledMask"]];
	int i;
	for(i=0;i<16;i++){
		timeRates[i] = [[ORTimeRate alloc] init];
		[self setLowLimit:i withValue:[decoder decodeFloatForKey: [NSString stringWithFormat:@"ORJADCLModelLowLimit_%d",i]]];
		[self setHighLimit:i withValue:[decoder decodeFloatForKey: [NSString stringWithFormat:@"ORJADCLModelHighLimit_%d",i]]];
	}
	[self setLastRead:@"Never"];
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];	
    [encoder encodeInteger:pollingState			forKey:@"ORJADCLModelPollingState"];
    [encoder encodeInteger:rangeIndex			forKey:@"ORJADCLModelRangeIndex"];
    [encoder encodeInteger:enabledMask			forKey:	@"ORJADCLModelEnabledMask"];
    [encoder encodeInteger:alarmsEnabledMask	forKey:	@"ORJADCLModelAlarmsEnabledMask"];
	
	int i;
	for(i=0;i<16;i++){
		[encoder encodeFloat: lowLimits[i] forKey: [NSString stringWithFormat:@"ORJADCLModelLowLimit_%d",i]];
		[encoder encodeFloat: highLimits[i] forKey: [NSString stringWithFormat:@"ORJADCLModelHighLimit_%d",i]];
	}
}

#pragma mark ¥¥¥Bit Processing Protocol

//note that everything called by these routines MUST be threadsafe
- (void)processIsStarting
{
	@synchronized(self){
		[self initBoard];
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		[self setLastRead:@"Via Process Manager"];
	}
}

- (void)processIsStopping
{
	@synchronized(self){
		[self _setUpPolling];
		[self setLastRead:[[NSDate date] description]];
	}
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
    return [NSString stringWithFormat:@"%d,%u,JADC-L",(int)[self crateNumber],(int)[self  stationNumber]];
}

- (double) convertedValue:(int)channel
{
	return (double)adcValue[channel];
}

- (double) maxValueForChan:(int)channel
{
	double theMax = 0;
	@synchronized(self){
		theMax =  adclRanges[rangeIndex].highRange;
	}
	return theMax;
}
- (double) minValueForChan:(int)channel
{
	double theMin = 0;
	@synchronized(self){
		theMin =  adclRanges[rangeIndex].lowRange;
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


#pragma mark ¥¥¥HW Wizard

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
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORJADCLModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORJADCLModel"]];
    return a;
	
}


@end

@implementation ORJADCLModel (private)
- (void) _checkAlarm:(int)aChan
{
	if(alarmsEnabledMask & (1<<aChan)){
		if(adcRange[aChan] == kAdcLRangeLow){
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
		else if(adcRange[aChan] == kAdcLRangeHigh){
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
        NSLog(@"Polling JADC_L,%d,%d  every %d seconds.\n",[self crateNumber],[self stationNumber],pollingState);
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(_pollAllChannels) withObject:self afterDelay:pollingState];
        [self _pollAllChannels];
    }
    else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        NSLog(@"Not Polling JADC_L,%d,%d\n",[self crateNumber],[self stationNumber]);
    }
}
- (void) _pollAllChannels
{
    @try { 
        [self readAdcs:NO];    
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
