//
//  ORHP4405AModel.m
//  Orca
//
//  Created by Mark Howe on Wed Jul28, 2010.
//  Copyright 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina at the UNC Physics Dept sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------#import "ORGpibEnetModel.h"
#import "ORGpibDeviceModel.h"
#import "ORHP4405AModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"

#define kPowerSummary		0x0008
#define kFreqSummary		0x0020
#define kCalibrationSummary	0x0100
#define kIntegritySummary	0x0200


NSString* ORHP4405AModelDataTypeChanged = @"ORHP4405AModelDataTypeChanged";
NSString* ORHP4405AModelStatusOperationRegChanged = @"ORHP4405AModelStatusOperationRegChanged";
NSString* ORHP4405AModelQuestionablePowerRegChanged = @"ORHP4405AModelQuestionablePowerRegChanged";
NSString* ORHP4405AModelQuestionableIntegrityRegChanged = @"ORHP4405AModelQuestionableIntegrityRegChanged";
NSString* ORHP4405AModelQuestionableFreqRegChanged = @"ORHP4405AModelQuestionableFreqRegChanged";
NSString* ORHP4405AModelQuestionableEventRegChanged = @"ORHP4405AModelQuestionableEventRegChanged";
NSString* ORHP4405AModelQuestionableConditionRegChanged = @"ORHP4405AModelQuestionableConditionRegChanged";
NSString* ORHP4405AModelQuestionableCalibrationRegChanged = @"ORHP4405AModelQuestionableCalibrationRegChanged";
NSString* ORHP4405AModelStandardEventRegChanged = @"ORHP4405AModelStandardEventRegChanged";
NSString* ORHP4405AModelStatusRegChanged = @"ORHP4405AModelStatusRegChanged";
NSString* ORHP4405AModelContinuousMeasurementChanged = @"ORHP4405AModelContinuousMeasurementChanged";
NSString* ORHP4405AModelOptimizePreselectorFreqChanged = @"ORHP4405AModelOptimizePreselectorFreqChanged";
NSString* ORHP4405AModelInputMaxMixerPowerChanged = @"ORHP4405AModelInputMaxMixerPowerChanged";
NSString* ORHP4405AModelInputGainEnabledChanged = @"ORHP4405AModelInputGainEnabledChanged";
NSString* ORHP4405AModelInputAttAutoEnabledChanged = @"ORHP4405AModelInputAttAutoEnabledChanged";
NSString* ORHP4405AModelInputAttenuationChanged = @"ORHP4405AModelInputAttenuationChanged";
NSString* ORHP4405AModelDetectorGainEnabledChanged = @"ORHP4405AModelDetectorGainEnabledChanged";
NSString* ORHP4405AModelBurstPulseDiscrimEnabledChanged = @"ORHP4405AModelBurstPulseDiscrimEnabledChanged";
NSString* ORHP4405AModelBurstModeAbsChanged = @"ORHP4405AModelBurstModeAbsChanged";
NSString* ORHP4405AModelBurstModeSettingChanged = @"ORHP4405AModelBurstModeSettingChanged";
NSString* ORHP4405AModelBurstFreqEnabledChanged = @"ORHP4405AModelBurstFreqEnabledChanged";
NSString* ORHP4405AModelTriggerDelayUnitsChanged = @"ORHP4405AModelTriggerDelayUnitsChanged";
NSString* ORHP4405AModelTriggerSourceChanged = @"ORHP4405AModelTriggerSourceChanged";
NSString* ORHP4405AModelTriggerOffsetEnabledChanged = @"ORHP4405AModelTriggerOffsetEnabledChanged";
NSString* ORHP4405AModelTriggerOffsetChanged	= @"ORHP4405AModelTriggerOffsetChanged";
NSString* ORHP4405AModelTriggerSlopeChanged	= @"ORHP4405AModelTriggerSlopeChanged";
NSString* ORHP4405AModelTriggerDelayEnabledChanged	= @"ORHP4405AModelTriggerDelayEnabledChanged";
NSString* ORHP4405AModelTriggerDelayChanged = @"ORHP4405AModelTriggerDelayChanged";
NSString* ORHP4405AModelFreqStepDirChanged	= @"ORHP4405AModelFreqStepDirChanged";
NSString* ORHP4405ALock						= @"ORHP4405ALock";
NSString* ORHP4405AGpibLock					= @"ORHP4405AGpibLock";
NSString* ORHP4405AModelFreqStepSizeChanged = @"ORHP4405AModelFreqStepSizeChanged";
NSString* ORHP4405AModelUnitsChanged		= @"ORHP4405AModelUnitsChanged";
NSString* ORHP4405AModelStopFreqChanged		= @"ORHP4405AModelStopFreqChanged";
NSString* ORHP4405AModelStartFreqChanged	= @"ORHP4405AModelStartFreqChanged";
NSString* ORHP4405AModelCenterFreqChanged	= @"ORHP4405AModelCenterFreqChanged";
NSString* ORHP4405AModelTrace1Changed		= @"ORHP4405AModelTrace1Changed";
NSString* ORHP4405AModelMeasurementInProgressChanged	= @"ORHP4405AModelMeasurementInProgressChanged";
NSString* ORHP4405AModelTraceChanged		= @"ORHP4405AModelTraceChanged";

@interface ORHP4405AModel (private)
- (void) pollStatus;
- (void) doMeasurement;
@end

@implementation ORHP4405AModel

#pragma mark ***initialization
- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[trace1 release];
    [super dealloc];
}

- (void) sleep 	
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super sleep];
}

- (void) setUpImage
{
    [self setImage: [NSImage imageNamed: @"HP4405A"]];
}

- (void) makeMainController
{
    [ self linkToController: @"ORHP4405AController" ];
}

#pragma mark •••Accessors

- (int) dataType
{
    return dataType;
}

- (void) setDataType:(int)aDataType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDataType:dataType];
    
    dataType = [self limitIntValue:aDataType min:0 max:3];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelDataTypeChanged object:self];
}

- (unsigned short) statusOperationReg
{
    return statusOperationReg;
}

- (void) setStatusOperationReg:(unsigned short)aStatusOperationReg
{
    statusOperationReg = aStatusOperationReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelStatusOperationRegChanged object:self];
}

- (unsigned short) questionablePowerReg
{
    return questionablePowerReg;
}

- (void) setQuestionablePowerReg:(unsigned short)aQuestionablePowerReg
{
    questionablePowerReg = aQuestionablePowerReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelQuestionablePowerRegChanged object:self];
}

- (unsigned short) questionableIntegrityReg
{
    return questionableIntegrityReg;
}

- (void) setQuestionableIntegrityReg:(unsigned short)aQuestionableIntegrityReg
{
    questionableIntegrityReg = aQuestionableIntegrityReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelQuestionableIntegrityRegChanged object:self];
}

- (unsigned short) questionableFreqReg
{
    return questionableFreqReg;
}

- (void) setQuestionableFreqReg:(unsigned short)aQuestionableFreqReg
{
    questionableFreqReg = aQuestionableFreqReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelQuestionableFreqRegChanged object:self];
}

- (unsigned short) questionableEventReg
{
    return questionableEventReg;
}

- (void) setQuestionableEventReg:(unsigned short)aQuestionableEventReg
{
    questionableEventReg = aQuestionableEventReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelQuestionableEventRegChanged object:self];
}

- (unsigned short) questionableConditionReg
{
    return questionableConditionReg;
}

- (void) setQuestionableConditionReg:(unsigned short)aQuestionableConditionReg
{
    questionableConditionReg = aQuestionableConditionReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelQuestionableConditionRegChanged object:self];
}

- (unsigned short) questionableCalibrationReg
{
    return questionableCalibrationReg;
}

- (void) setQuestionableCalibrationReg:(unsigned short)aQuestionableCalibrationReg
{
    questionableCalibrationReg = aQuestionableCalibrationReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelQuestionableCalibrationRegChanged object:self];
}

- (unsigned char) standardEventReg
{
    return standardEventReg;
}

- (void) setStandardEventReg:(unsigned char)aStandardEventReg
{
    standardEventReg = aStandardEventReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelStandardEventRegChanged object:self];
}

- (unsigned char) statusReg
{
    return statusReg;
}

- (void) setStatusReg:(unsigned char)aStatusReg
{
    statusReg = aStatusReg;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelStatusRegChanged object:self];
}

- (BOOL) measurementInProgress
{
	return measurementInProgress;
}

- (void) setMeasurementInProgress:(BOOL)aState
{
    measurementInProgress = aState;
	if(measurementInProgress){
		//[self pollStatus];
	}

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelMeasurementInProgressChanged object:self];
}

- (BOOL) continuousMeasurement
{
    return continuousMeasurement;
}

- (void) setContinuousMeasurement:(BOOL)aContinuousMeasurement
{
    [[[self undoManager] prepareWithInvocationTarget:self] setContinuousMeasurement:continuousMeasurement];
    
    continuousMeasurement = aContinuousMeasurement;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelContinuousMeasurementChanged object:self];
}

- (int) optimizePreselectorFreq
{
    return optimizePreselectorFreq;
}

- (void) setOptimizePreselectorFreq:(int)aOptimizePreselectorFreq
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOptimizePreselectorFreq:optimizePreselectorFreq];
    
    optimizePreselectorFreq = aOptimizePreselectorFreq;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelOptimizePreselectorFreqChanged object:self];
}

- (int) inputMaxMixerPower
{
    return inputMaxMixerPower;
}

- (void) setInputMaxMixerPower:(int)aInputMaxMixerPower
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInputMaxMixerPower:inputMaxMixerPower];
    
    inputMaxMixerPower = aInputMaxMixerPower;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelInputMaxMixerPowerChanged object:self];
}

- (BOOL) inputGainEnabled
{
    return inputGainEnabled;
}

- (void) setInputGainEnabled:(BOOL)aInputGainEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInputGainEnabled:inputGainEnabled];
    
    inputGainEnabled = aInputGainEnabled;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelInputGainEnabledChanged object:self];
}

- (BOOL) inputAttAutoEnabled
{
    return inputAttAutoEnabled;
}

- (void) setInputAttAutoEnabled:(BOOL)aInputAttAutoEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInputAttAutoEnabled:inputAttAutoEnabled];
    
    inputAttAutoEnabled = aInputAttAutoEnabled;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelInputAttAutoEnabledChanged object:self];
}

- (int) inputAttenuation
{
    return inputAttenuation;
}

- (void) setInputAttenuation:(int)aInputAttenuation
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInputAttenuation:inputAttenuation];
    
    inputAttenuation = aInputAttenuation;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelInputAttenuationChanged object:self];
}

- (BOOL) detectorGainEnabled
{
    return detectorGainEnabled;
}

- (void) setDetectorGainEnabled:(BOOL)aDetectorGainEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDetectorGainEnabled:detectorGainEnabled];
    
    detectorGainEnabled = aDetectorGainEnabled;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelDetectorGainEnabledChanged object:self];
}

- (BOOL) burstPulseDiscrimEnabled
{
    return burstPulseDiscrimEnabled;
}

- (void) setBurstPulseDiscrimEnabled:(BOOL)aBurstPulseDiscrimEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBurstPulseDiscrimEnabled:burstPulseDiscrimEnabled];
    
    burstPulseDiscrimEnabled = aBurstPulseDiscrimEnabled;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelBurstPulseDiscrimEnabledChanged object:self];
}

- (BOOL) burstModeAbs
{
    return burstModeAbs;
}

- (void) setBurstModeAbs:(BOOL)aBurstModeAbs
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBurstModeAbs:burstModeAbs];
    
    burstModeAbs = aBurstModeAbs;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelBurstModeAbsChanged object:self];
}

- (BOOL) burstModeSetting
{
    return burstModeSetting;
}

- (void) setBurstModeSetting:(BOOL)aBurstModeSetting
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBurstModeSetting:burstModeSetting];
    
    burstModeSetting = aBurstModeSetting;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelBurstModeSettingChanged object:self];
}

- (BOOL) burstFreqEnabled
{
    return burstFreqEnabled;
}

- (void) setBurstFreqEnabled:(BOOL)aBurstFreqEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBurstFreqEnabled:burstFreqEnabled];
    
    burstFreqEnabled = aBurstFreqEnabled;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelBurstFreqEnabledChanged object:self];
}

- (int) triggerSource
{
    return triggerSource;
}

- (void) setTriggerSource:(int)aTriggerSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerSource:triggerSource];
    
    triggerSource = aTriggerSource;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelTriggerSourceChanged object:self];
}

- (BOOL) triggerOffsetEnabled
{
    return triggerOffsetEnabled;
}

- (void) setTriggerOffsetEnabled:(BOOL)aTriggerOffsetEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerOffsetEnabled:triggerOffsetEnabled];
    
    triggerOffsetEnabled = aTriggerOffsetEnabled;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelTriggerOffsetEnabledChanged object:self];
}

- (float) triggerOffset
{
    return triggerOffset;
}

- (void) setTriggerOffset:(float)aTriggerOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerOffset:triggerOffset];
    
    triggerOffset = aTriggerOffset;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelTriggerOffsetChanged object:self];
}

- (int) triggerSlope
{
    return triggerSlope;
}

- (void) setTriggerSlope:(int)aTriggerSlope
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerSlope:triggerSlope];
    
    triggerSlope = aTriggerSlope;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelTriggerSlopeChanged object:self];
}

- (BOOL) triggerDelayEnabled
{
    return triggerDelayEnabled;
}

- (void) setTriggerDelayEnabled:(BOOL)aTriggerDelayEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerDelayEnabled:triggerDelayEnabled];
    
    triggerDelayEnabled = aTriggerDelayEnabled;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelTriggerDelayEnabledChanged object:self];
}

- (float) triggerDelay
{
    return triggerDelay;
}

- (void) setTriggerDelay:(float)aTriggerDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerDelay:triggerDelay];
    
   triggerDelay = [self limitFloatValue:aTriggerDelay min:.3E-6 max:429];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelTriggerDelayChanged object:self];
}

- (BOOL) freqStepDir
{
    return freqStepDir;
}

- (void) setFreqStepDir:(BOOL)aFreqStepDir
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFreqStepDir:freqStepDir];
    freqStepDir = aFreqStepDir;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelFreqStepDirChanged object:self];
}

- (float) freqStepSize
{
    return freqStepSize;
}

- (void) setFreqStepSize:(float)aFreqStepSize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFreqStepSize:freqStepSize];
    freqStepSize = aFreqStepSize;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelFreqStepSizeChanged object:self];
}

- (NSString*) unitName:(int)anIndex
{
	switch(anIndex){
		case 0: return @"DBM";
		case 1: return @"DBMV";
		case 2: return @"DBUV";
		case 3: return @"DBUA";
		case 4: return @"V";
		case 5: return @"W";
		case 6: return @"A";
		default: return @"?";
	}
}
- (NSString*) unitFullName:(int)anIndex
{
	switch(anIndex){
		case 0: return @"dB";
		case 1: return @"dB mV";
		case 2: return @"dB µV";
		case 3: return @"dB µA";
		case 4: return @"Volts";
		case 5: return @"Watts";
		case 6: return @"Amps";
		default: return @"?";
	}
}

- (NSString*) triggerSourceName:(int)anIndex
{
	switch(anIndex){
		case 0: return @"IMM";
		case 1: return @"LINE";
		case 2: return @"EXT";
		case 3: return @"RFB";
		default: return @"?";
	}
}

- (NSString*) dataTypeName:(int)anIndex
{
	switch(anIndex){
		case 0: return @"ASC";
		case 1: return @"INT,32";
		case 2: return @"REAL,32";
		case 3: return @"REAL,64";
		default: return @"UNIT,16";
	}
}

- (int) dataSize:(int)anIndex
{
	switch(anIndex){
		case 0: return -1;
		case 1: return 4;
		case 2: return 4;
		case 3: return 8;
		default: return 2;
	}
}

- (int) units
{
    return units;
}

- (void) setUnits:(int)aUnits
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUnits:units];
    units = aUnits;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelUnitsChanged object:self];
}

- (float) stopFreq
{
    return stopFreq;
}

- (void) setStopFreq:(float)aStopFreq
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStopFreq:stopFreq];
    stopFreq = aStopFreq;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelStopFreqChanged object:self];
}

- (float) startFreq
{
    return startFreq;
}

- (void) setStartFreq:(float)aStartFreq
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartFreq:startFreq];
    startFreq = aStartFreq;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelStartFreqChanged object:self];
}

- (float) centerFreq
{
    return centerFreq;
}

- (void) setCenterFreq:(float)aCenterFreq
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCenterFreq:centerFreq];
    centerFreq = aCenterFreq;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelCenterFreqChanged object:self];
}

- (void) setTrace1:(NSData*)someData
{
	if(!trace1)trace1 = [[NSMutableArray array] retain];
	if([trace1 count])[trace1 removeAllObjects];
	
	unsigned char* p = (unsigned char*)[someData bytes];
	if([self dataType]>0){
		if(p[0] == '#'){
			int headerSizeBytes = 2 + (p[1] - 48);
			NSData* theData = [NSData dataWithBytes:&p[headerSizeBytes] length:[someData length] - headerSizeBytes];
			NSUInteger lenInBytes = [theData length];
			switch (dataType) {
				case 1: //Int32
				{
					int i;
					int32_t* p = (int32_t*) [theData bytes];
					for(i=0;i<lenInBytes/sizeof(int32_t);i++){
						[trace1 addObject:[NSNumber numberWithDouble:(double)p[i]]];
					}
				}
				break;
					
				case 2: //Real32
				{
					int i;
					float* p = (float*) [theData bytes];
					for(i=0;i<lenInBytes/sizeof(float);i++){
						[trace1 addObject:[NSNumber numberWithDouble:(double)p[i]]];
					}
				}
				break;
					
				case 3: //Real64
				{
					int i;
					double* p = (double*) [theData bytes];
					for(i=0;i<lenInBytes/sizeof(double);i++){
						[trace1 addObject:[NSNumber numberWithDouble:(double)p[i]]];
					}
				}
				break;
					
				case 4: //uint16_t
				{
					int i;
					unsigned short* p = (unsigned short*) [theData bytes];
					for(i=0;i<lenInBytes/sizeof(unsigned short);i++){
						[trace1 addObject:[NSNumber numberWithDouble:(double)p[i]]];
					}
				}
				break;
			}
		}
	}
	else {
		NSString* s = [[NSString alloc] initWithData:someData encoding:NSASCIIStringEncoding];
		NSArray* theNumbers = [s componentsSeparatedByString:@","];
		[s release];
		for(id aNumber in theNumbers){
			double val = [aNumber doubleValue];
			[trace1 addObject:[NSNumber numberWithDouble:val]];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORHP4405AModelTraceChanged object:self];

}

#pragma mark ***Hardware Command
- (void) reset
{    
    [self writeToGPIBDevice: @"*RST"];
}

- (void) setTime
{
	NSDate *today = [NSDate date];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
	NSDateComponents *components = [gregorian components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:today];
#else
    NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents *components = [gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:today];

#endif
    [ self writeToGPIBDevice: [ NSString stringWithFormat: @"SYST:DATE %d,%d,%d", (int)[components hour],(int)[components minute],(int)[components second]]];
}

- (uint32_t)	getPowerOnTime
{
    char reply[1024];
    int32_t n = [self writeReadGPIBDevice:@":SYST:PON:TIME?" data:reply maxLength:1024];
    if(n && [[NSString stringWithCString:reply encoding:NSASCIIStringEncoding] rangeOfString:@"No error"].location == NSNotFound){
		return (uint32_t)atol(reply);
	}
	else return 0; //inserted to get rid of compiler warnings MAH -8/06/08
}

- (void) loadFreqSettings
{
	[self writeToGPIBDevice:[NSString stringWithFormat:@":FREQ:STAR %.1f",startFreq]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":FREQ:STOP %.1f",stopFreq]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":FREQ:CENT %.1f",centerFreq]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":FREQ:CENT:STEP %.1f",freqStepSize]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":FREQ:CENT %@",freqStepDir?@"Down":@"UP"]];
}

- (void) loadTriggerSettings
{
	[self writeToGPIBDevice:[NSString stringWithFormat:@":TRIG:DEL %.6f",triggerDelay]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":TRIG:DEL:STAT %@",triggerDelayEnabled?@"ON":@"OFF"]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":TRIG:EXT:SLOP %@",triggerSlope?@"POS":@"NEG"]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":TRIG:OFFS %.6f",triggerOffset]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":TRIG:OFFS:STAT %@",triggerOffsetEnabled?@"ON":@"OFF"]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":TRIG:SOUR %@",[self triggerSourceName:triggerSource]]];
}

	 
- (void) loadRFBurstSettings
{
	[self writeToGPIBDevice:[NSString stringWithFormat:@":TRIG:RFB:FSEL %@",burstFreqEnabled?@"ON":@"OFF"]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":TRIG:RFB:LEV:TYPE %@",burstModeAbs?@"ABS":@"REL"]];
//	if(burstModeAbs)[self writeToGPIBDevice:[NSString stringWithFormat:@":TRIG:RFB:LEV:ABS",burstModeSetting]];
//	else			[self writeToGPIBDevice:[NSString stringWithFormat:@":TRIG:RFB:LEV:RL",burstModeSetting]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":TRIG:RFB:NPD %@",burstPulseDiscrimEnabled?@"ON":@"OFF"]];
}

- (void) loadInputPortSettings
{
	[self writeToGPIBDevice:[NSString stringWithFormat:@":POW:QPG %@",detectorGainEnabled?@"ON":@"OFF"]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":POW:ATT %d",inputAttenuation]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":POW:MIX:RANG %d",inputMaxMixerPower]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":POW:GAIN %@",inputGainEnabled?@"ON":@"OFF"]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":POW:ATT:AUTO %@",inputAttAutoEnabled?@"ON":@"OFF"]];
	[self writeToGPIBDevice:[NSString stringWithFormat:@":POW:PADJ %d",optimizePreselectorFreq]];
}

- (void) startMeasurement
{
	[self setMeasurementInProgress:YES];
	[self performSelector:@selector(doMeasurement) withObject:nil afterDelay:.1];
}


- (void) pauseMeasurement
{
	[self writeToGPIBDevice:@":INIT:PAUS"];
	[self setMeasurementInProgress:NO];
}

- (void) restartMeasurement
{
	[self writeToGPIBDevice:@":INIT:REST"];
	[self setMeasurementInProgress:YES];
}

- (void) resumeMeasurement
{
	[self writeToGPIBDevice:@":INIT:RES"];
	[self setMeasurementInProgress:YES];
}

- (void) loadFormat
{
	[self writeToGPIBDevice:@":FORM:BORD SWAP"];	//not byte swaped
	[self writeToGPIBDevice:[NSString stringWithFormat:@":FORM:DATA %@",[self dataTypeName:[self dataType]]]];
}

- (void) loadUnits
{
	[self writeToGPIBDevice:[NSString stringWithFormat:@":UNIT:POW %@",[self unitName:[self units]]]];
}

- (void) getTrace1
{
	int maxTraceLength;
	int theUnitSize = [self dataSize:[self dataType]];
	if(theUnitSize>0) maxTraceLength = (401*theUnitSize + 6 + 1);
	else maxTraceLength = 10*1024; //ascii
	
	NSMutableData* theTrace = [NSMutableData dataWithLength:maxTraceLength];
	char* p = (char*)[theTrace bytes];
    int32_t  n = [self writeReadGPIBDevice:@":TRAC:DATA? TRACE1" data:p maxLength:maxTraceLength];
    if(n){
		[theTrace setLength:n];
		[self setTrace1:theTrace];
	}
	[self setMeasurementInProgress:NO];
}

- (void) checkStatus
{
	[self readStatusOperationReg];
	
	if([self readQuestionableEventReg]){
		if(questionableEventReg & kPowerSummary){
			[self readQuestionablePowerReg];
		}
		if(questionableEventReg & kFreqSummary){
			[self readQuestionableFreqReg];
		}
		if(questionableEventReg & kCalibrationSummary){
			[self readQuestionableCalibrationReg];
		}
		if(questionableEventReg & kIntegritySummary){
			[self readQuestionableIntegrityReg];
		}
	}
}

- (unsigned char)readStandardEventReg
{
	unsigned char theResult = 0;
	char reply[1024];
	int32_t n = [self writeReadGPIBDevice:@"*ESR?" data:reply maxLength:1024];
	if(n){
		theResult = atoi(reply);
		[self setStandardEventReg:theResult];
	}
	return theResult;
}

- (unsigned char) readStatusReg
{
	unsigned char theResult = 0;
	char reply[1024];
	int32_t n = [self writeReadGPIBDevice:@"*STB?" data:reply maxLength:1024];
	if(n){
		theResult = atoi(reply);
		[self setStatusReg:theResult];
	}
	return theResult;
}

- (unsigned short) readStatusOperationReg;
{
	unsigned char theResult = 0;
	char reply[1024];
	int32_t n = [self writeReadGPIBDevice:@":STAT:OPER:COND?" data:reply maxLength:1024];
	if(n){
		theResult = atoi(reply);
		[self setStatusOperationReg:theResult];
	}
	return theResult;
}
- (unsigned short) readQuestionableEventReg
{
	unsigned char theResult = 0;
	char reply[1024];
	int32_t n = [self writeReadGPIBDevice:@":STAT:QUES?" data:reply maxLength:1024];
	if(n){
		theResult = atoi(reply);
		[self setQuestionableEventReg:theResult];
	}
	return theResult;
}

- (unsigned short)readQuestionableCalibrationReg
{
	unsigned char theResult = 0;
	char reply[1024];
	int32_t n = [self writeReadGPIBDevice:@":STAT:QUES:CAL:COND?" data:reply maxLength:1024];
	if(n){
		theResult = atoi(reply);
		[self setQuestionableConditionReg:theResult];
	}
	return theResult;
}

- (unsigned short) readQuestionableConditionReg
{
	unsigned char theResult = 0;
	char reply[1024];
	int32_t n = [self writeReadGPIBDevice:@":STAT:QUES:COND?" data:reply maxLength:1024];
	if(n){
		theResult = atoi(reply);
		[self setQuestionableConditionReg:theResult];
	}
	return theResult;
}

- (unsigned short) readQuestionableFreqReg
{
	unsigned char theResult = 0;
	char reply[1024];
	int32_t n = [self writeReadGPIBDevice:@"*STB?" data:reply maxLength:1024];
	if(n){
		theResult = atoi(reply);
		[self setQuestionableFreqReg:theResult];
	}
	return theResult;
}

- (unsigned short) readQuestionableIntegrityReg
{
	unsigned char theResult = 0;
	char reply[1024];
	int32_t n = [self writeReadGPIBDevice:@":STAT:QUES:INT:COND?" data:reply maxLength:1024];
	if(n){
		theResult = atoi(reply);
		[self setQuestionableIntegrityReg:theResult];
	}
	return theResult;
}

- (unsigned short) readQuestionablePowerReg
{
	unsigned char theResult = 0;
	char reply[1024];
	int32_t n = [self writeReadGPIBDevice:@":STAT:QUES:POW:COND?" data:reply maxLength:1024];
	if(n){
		theResult = atoi(reply);
		[self setQuestionablePowerReg:theResult];
	}
	return theResult;
}


#pragma mark ***DataTaker

- (uint32_t) dataId { return dataId; }

- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anOtherObj
{
    [self setDataId:[anOtherObj dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORHP4405ADecoderForSpectra",             @"decoder",
								 [NSNumber numberWithLong:dataId],           @"dataId",
								 [NSNumber numberWithBool:YES],              @"variable",
								 [NSNumber numberWithLong:-1],               @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Spectra"];
	
    return dataDictionary;
}

- (void) runTaskStarted: (ORDataPacket*) aDataPacket userInfo: (id) anUserInfo
{
	// Handle case where device is not connected.
    if(![self isConnected] )[NSException raise: @"Not Connected" format: @"You must connect to a GPIB Controller."];
 	// Get the controller so that it is cached
    if(![ self cacheTheController])[NSException raise: @"Not connected" format: @"Could not cache the controller."];
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORHP4405AModel"]; 
	        
}

- (void) 	takeDataTask: (id) notUsed 
{

}

- (void) runTaskStopped: (ORDataPacket*) aDataPacket userInfo: (id) anUserInfo
{
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [ super initWithCoder: decoder ];
	
    [[ self undoManager ] disableUndoRegistration ];
    [self setDataType:[decoder decodeIntForKey:@"dataType"]];
    [self setContinuousMeasurement:[decoder decodeBoolForKey:@"continuousMeasurement"]];
    [self setOptimizePreselectorFreq:[decoder decodeIntForKey:@"optimizePreselectorFreq"]];
    [self setInputMaxMixerPower:[decoder decodeIntForKey:@"inputMaxMixerPower"]];
    [self setInputGainEnabled:[decoder decodeBoolForKey:@"inputGainEnabled"]];
    [self setInputAttAutoEnabled:[decoder decodeBoolForKey:@"inputAttAutoEnabled"]];
    [self setInputAttenuation:[decoder decodeIntForKey:@"inputAttenuation"]];
    [self setDetectorGainEnabled:[decoder decodeBoolForKey:@"detectorGainEnabled"]];
    [self setBurstPulseDiscrimEnabled:[decoder decodeBoolForKey:@"burstPulseDiscrimEnabled"]];
    [self setBurstModeAbs:[decoder decodeBoolForKey:@"burstModeAbs"]];
    [self setBurstModeSetting:[decoder decodeIntegerForKey:@"burstModeSetting"]];
    [self setBurstFreqEnabled:[decoder decodeBoolForKey:@"burstFreqEnabled"]];
    [self setTriggerSource:[decoder decodeIntForKey:@"triggerSource"]];
    [self setTriggerOffsetEnabled:[decoder decodeBoolForKey:@"triggerOffsetEnabled"]];
    [self setTriggerOffset:[decoder decodeFloatForKey:@"triggerOffset"]];
    [self setTriggerSlope:[decoder decodeIntForKey:@"triggerSlope"]];
    [self setTriggerDelayEnabled:[decoder decodeBoolForKey:@"triggerDelayEnabled"]];
    [self setTriggerDelay:[decoder decodeFloatForKey:@"triggerDelay"]];
    [self setFreqStepDir:[decoder decodeBoolForKey:@"freqStepDir"]];
    [self setFreqStepSize:[decoder decodeFloatForKey:@"freqStepSize"]];
    [self setUnits:[decoder decodeIntForKey:@"units"]];
    [self setStopFreq:[decoder decodeFloatForKey:@"stopFreq"]];
    [self setStartFreq:[decoder decodeFloatForKey:@"startFreq"]];
	[self setCenterFreq:[decoder decodeFloatForKey:@"centerFreqx"]];
    [[ self undoManager ] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder: encoder];
    [encoder encodeInteger:dataType forKey:@"dataType"];
    [encoder encodeBool:continuousMeasurement forKey:@"continuousMeasurement"];
    [encoder encodeInteger:optimizePreselectorFreq forKey:@"optimizePreselectorFreq"];
    [encoder encodeInteger:inputMaxMixerPower forKey:@"inputMaxMixerPower"];
    [encoder encodeBool:inputGainEnabled forKey:@"inputGainEnabled"];
    [encoder encodeBool:inputAttAutoEnabled forKey:@"inputAttAutoEnabled"];
    [encoder encodeInteger:inputAttenuation forKey:@"inputAttenuation"];
    [encoder encodeBool:detectorGainEnabled forKey:@"detectorGainEnabled"];
    [encoder encodeBool:burstPulseDiscrimEnabled forKey:@"burstPulseDiscrimEnabled"];
    [encoder encodeBool:burstModeAbs forKey:@"burstModeAbs"];
    [encoder encodeInteger:burstModeSetting forKey:@"burstModeSetting"];
    [encoder encodeBool:burstFreqEnabled forKey:@"burstFreqEnabled"];
    [encoder encodeInteger:triggerSource forKey:@"triggerSource"];
    [encoder encodeBool:triggerOffsetEnabled forKey:@"triggerOffsetEnabled"];
    [encoder encodeFloat:triggerOffset forKey:@"triggerOffset"];
    [encoder encodeInteger:triggerSlope forKey:@"triggerSlope"];
    [encoder encodeBool:triggerDelayEnabled forKey:@"triggerDelayEnabled"];
    [encoder encodeFloat:triggerDelay forKey:@"triggerDelay"];
    [encoder encodeBool:freqStepDir forKey:@"freqStepDir"];
    [encoder encodeFloat:freqStepSize forKey:@"freqStepSize"];
    [encoder encodeInteger:units forKey:@"units"];
    [encoder encodeFloat:stopFreq forKey:@"stopFreq"];
    [encoder encodeFloat:startFreq forKey:@"startFreq"];
    [encoder encodeFloat:centerFreq forKey:@"centerFreqx"];
}
					 
- (float) limitFloatValue:(float)aValue min:(float)aMin max:(float)aMax
{
	if(aValue<aMin)return aMin;
	else if(aValue>aMax)return aMax;
	else return aValue;
}
 - (float) limitIntValue:(int)aValue min:(float)aMin max:(float)aMax
{
	if(aValue<aMin)return aMin;
	else if(aValue>aMax)return aMax;
	else return aValue;
}
	 
- (int) numPoints
{
	return (int)[trace1 count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	*yValue = [[trace1 objectAtIndex:i] doubleValue];
	*xValue = i;
}
@end

@implementation ORHP4405AModel (private)
- (void) pollStatus
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollStatus) object:nil];
	if(measurementInProgress){
		@try {
			[self checkStatus];
			if(statusOperationReg == 0x0 && ![self continuousMeasurement]){
				[self setMeasurementInProgress:NO];
			}
		}
		@catch (NSException* e){
			[self setMeasurementInProgress:NO];
			@throw;
		}
		[self performSelector:@selector(pollStatus) withObject:nil afterDelay:.1];
	}
}

- (void) doMeasurement
{
	//start/restart a measurement
	[self loadFormat];
	[self loadUnits];
	[self loadFreqSettings];
	[self loadInputPortSettings];
	[self loadTriggerSettings];
	[self writeToGPIBDevice:@":INIT:CONT 0"];
	[self writeToGPIBDevice:@":INIT:IMM;*WAI"];
	[self getTrace1];
}
@end












