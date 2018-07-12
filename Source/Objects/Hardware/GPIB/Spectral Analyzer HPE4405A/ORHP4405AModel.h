//
//  ORHP4405AModel.h
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
//-------------------------------------------------------------

#import "ORGpibDeviceModel.h"

@interface ORHP4405AModel : ORGpibDeviceModel {
	
	NSMutableArray* trace1;
	
	unsigned long dataId;
	BOOL  measurementInProgress;
	float centerFreq;
    float startFreq;
    float stopFreq;
    int   units;
    float freqStepSize;
    BOOL  freqStepDir;
	
    BOOL  triggerDelayEnabled;
    BOOL  triggerOffsetEnabled;
    float triggerOffset;
    float triggerDelay;
    int   triggerSource;
    int   triggerSlope;
	
    BOOL burstFreqEnabled;
    int  burstModeSetting;
    BOOL burstModeAbs;
    BOOL burstPulseDiscrimEnabled;
	
    BOOL detectorGainEnabled;
    BOOL inputAttAutoEnabled;
    BOOL inputGainEnabled;
    int  inputAttenuation;
    int  inputMaxMixerPower;
    int  optimizePreselectorFreq;
    BOOL continuousMeasurement;
	
	//status
    unsigned char statusReg;
    unsigned char standardEventReg;
    unsigned short questionableCalibrationReg;
    unsigned short questionableConditionReg;
    unsigned short questionableEventReg;
    unsigned short questionableFreqReg;
    unsigned short questionableIntegrityReg;
    unsigned short questionablePowerReg;
    unsigned short statusOperationReg;
    int dataType;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anOtherObj;

#pragma mark •••Accessors
- (int) dataType;
- (void) setDataType:(int)aDataType;
- (unsigned short) statusOperationReg;
- (void) setStatusOperationReg:(unsigned short)aStatusOperationReg;
- (unsigned short) questionablePowerReg;
- (void) setQuestionablePowerReg:(unsigned short)aQuestionablePowerReg;
- (unsigned short) questionableIntegrityReg;
- (void) setQuestionableIntegrityReg:(unsigned short)aQuestionableIntegrityReg;
- (unsigned short) questionableFreqReg;
- (void) setQuestionableFreqReg:(unsigned short)aQuestionableFreqReg;
- (unsigned short) questionableEventReg;
- (void) setQuestionableEventReg:(unsigned short)aQuestionableEventReg;
- (unsigned short) questionableConditionReg;
- (void) setQuestionableConditionReg:(unsigned short)aQuestionableConditionReg;
- (unsigned short) questionableCalibrationReg;
- (void) setQuestionableCalibrationReg:(unsigned short)aQuestionableCalibrationReg;
- (unsigned char) standardEventReg;
- (void) setStandardEventReg:(unsigned char)aStandardEventReg;
- (unsigned char) statusReg;
- (void) setStatusReg:(unsigned char)aStatusReg;

- (BOOL) continuousMeasurement;
- (void) setContinuousMeasurement:(BOOL)aContinuousMeasurement;
- (int) optimizePreselectorFreq;
- (void) setOptimizePreselectorFreq:(int)aOptimizePreselectorFreq;
- (int) inputMaxMixerPower;
- (void) setInputMaxMixerPower:(int)aInputMaxMixerPower;
- (BOOL) inputGainEnabled;
- (void) setInputGainEnabled:(BOOL)aInputGainEnabled;
- (BOOL) inputAttAutoEnabled;
- (void) setInputAttAutoEnabled:(BOOL)aInputAttAutoEnabled;
- (int) inputAttenuation;
- (void) setInputAttenuation:(int)aInputAttenuation;
- (BOOL) detectorGainEnabled;
- (void) setDetectorGainEnabled:(BOOL)aDetectorGainEnabled;
- (BOOL) burstPulseDiscrimEnabled;
- (void) setBurstPulseDiscrimEnabled:(BOOL)aBurstPulseDiscrimEnabled;
- (BOOL) burstModeAbs;
- (void) setBurstModeAbs:(BOOL)aBurstModeAbs;
- (BOOL) burstModeSetting;
- (void) setBurstModeSetting:(BOOL)aBurstModeSetting;
- (BOOL) burstFreqEnabled;
- (void) setBurstFreqEnabled:(BOOL)aBurstFreqEnabled;
- (int) triggerSource;
- (void) setTriggerSource:(int)aTriggerSource;
- (BOOL) triggerOffsetEnabled;
- (void) setTriggerOffsetEnabled:(BOOL)aTriggerOffsetEnabled;
- (float) triggerOffset;
- (void) setTriggerOffset:(float)aTriggerOffset;
- (int) triggerSlope;
- (void) setTriggerSlope:(int)aTriggerSlope;
- (BOOL) triggerDelayEnabled;
- (void) setTriggerDelayEnabled:(BOOL)aTriggerDelayEnabled;
- (float) triggerDelay;
- (void) setTriggerDelay:(float)aTriggerDelay;
- (BOOL) freqStepDir;
- (void) setFreqStepDir:(BOOL)aFreqStepDir;
- (float) freqStepSize;
- (void) setFreqStepSize:(float)aFreqStepSize;
- (int) units;
- (void) setUnits:(int)aUnits;

- (float) stopFreq;
- (void) setStopFreq:(float)aStopFreq;
- (float) startFreq;
- (void) setStartFreq:(float)aStartFreq;
- (float) centerFreq;
- (void) setCenterFreq:(float)aCenterFreq;
- (void) setTrace1:(NSData*)someData;

- (BOOL) measurementInProgress;
- (void) setMeasurementInProgress:(BOOL)aState;

#pragma mark ***Hardware - General
- (void)			reset;
- (void)			loadFormat;
- (void)			loadUnits;
- (void)			setTime;
- (unsigned long)	getPowerOnTime;
- (void)			loadTriggerSettings;
- (void)			loadFreqSettings;
- (void)			loadRFBurstSettings;
- (void)			loadInputPortSettings;

- (void)			startMeasurement;
- (void)			pauseMeasurement;
- (void)			restartMeasurement;
- (void)			resumeMeasurement;

- (void)		   checkStatus;
- (unsigned short) readStatusOperationReg;
- (unsigned short) readQuestionableCalibrationReg;
- (unsigned short) readQuestionableConditionReg;
- (unsigned short) readQuestionableEventReg;
- (unsigned short) readQuestionableFreqReg;
- (unsigned short) readQuestionableIntegrityReg;
- (unsigned short) readQuestionablePowerReg;
- (void) getTrace1;

#pragma mark ***DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted: (ORDataPacket*) aDataPacket userInfo: (id) anUserInfo;
- (void) takeDataTask: (id) notUsed;
- (void) runTaskStopped: (ORDataPacket*) aDataPacket userInfo: (id) anUserInfo;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***Helpers
- (float) limitFloatValue:(float)aValue min:(float)aMin max:(float)aMax;
- (float) limitIntValue:(int)aValue min:(float)aMin max:(float)aMax;
- (int) numPoints;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
- (NSString*) triggerSourceName:(int)anIndex;
- (NSString*) dataTypeName:(int)anIndex;
- (NSString*) unitName:(int)anIndex;
- (NSString*) unitFullName:(int)anIndex;
- (int) dataSize:(int)anIndex;
@end

extern NSString* ORHP4405AModelTraceChanged;
extern NSString* ORHP4405AModelDataTypeChanged;
extern NSString* ORHP4405AModelStatusOperationRegChanged;
extern NSString* ORHP4405AModelQuestionablePowerRegChanged;
extern NSString* ORHP4405AModelQuestionableIntegrityRegChanged;
extern NSString* ORHP4405AModelQuestionableFreqRegChanged;
extern NSString* ORHP4405AModelQuestionableEventRegChanged;
extern NSString* ORHP4405AModelQuestionableConditionRegChanged;
extern NSString* ORHP4405AModelQuestionableCalibrationRegChanged;
extern NSString* ORHP4405AModelStandardEventRegChanged;
extern NSString* ORHP4405AModelStatusRegChanged;
extern NSString* ORHP4405AModelMeasurementInProgressChanged;
extern NSString* ORHP4405AModelContinuousMeasurementChanged;
extern NSString* ORHP4405AModelOptimizePreselectorFreqChanged;
extern NSString* ORHP4405AModelInputMaxMixerPowerChanged;
extern NSString* ORHP4405AModelInputGainEnabledChanged;
extern NSString* ORHP4405AModelInputAttAutoEnabledChanged;
extern NSString* ORHP4405AModelInputAttenuationChanged;
extern NSString* ORHP4405AModelDetectorGainEnabledChanged;
extern NSString* ORHP4405AModelTrace1Changed;
extern NSString* ORHP4405AModelBurstPulseDiscrimEnabledChanged;
extern NSString* ORHP4405AModelBurstModeAbsChanged;
extern NSString* ORHP4405AModelBurstModeSettingChanged;
extern NSString* ORHP4405AModelBurstFreqEnabledChanged;
extern NSString* ORHP4405AModelTriggerSourceChanged;
extern NSString* ORHP4405AModelTriggerOffsetEnabledChanged;
extern NSString* ORHP4405AModelTriggerOffsetChanged;
extern NSString* ORHP4405AModelTriggerSlopeChanged;
extern NSString* ORHP4405AModelTriggerDelayEnabledChanged;
extern NSString* ORHP4405AModelTriggerDelayChanged;
extern NSString* ORHP4405AModelFreqStepDirChanged;
extern NSString* ORHP4405AModelFreqStepSizeChanged;
extern NSString* ORHP4405AModelUnitsChanged;
extern NSString* ORHP4405AModelStopFreqChanged;
extern NSString* ORHP4405AModelStartFreqChanged;
extern NSString* ORHP4405AModelCenterFreqChanged;
extern NSString* ORHP4405ALock;
extern NSString* ORHP4405AGpibLock;

