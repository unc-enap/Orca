//
//  ORPulser33500Chan.h
//  Orca
//
//  Created by Mark Howe on Thurs, Oct 25 2012.
//  Copyright (c) 2012 University of North Carolina. All rights reserved.
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

// Structure used to describe characteristics of waveforms.
typedef struct Pulser33500CustomWaveformStruct {
	NSString*       waveformName;
	NSString*       storageName;
	bool			tryToStore;
    bool            builtInFunction;
} Pulser33500CustomWaveformStruct; 

#define kCalibrationWidth		7.8  //can't set exactly to 8 because of a bug in the HP pulser
#define kCalibrationVoltage 	750
#define kCalibrationBurstRate 	3.0 

@interface ORPulser33500Chan : NSObject {
    id				pulser;
    int				channel;
	float			voltage;
	float			voltageOffset;
	float			frequency;
	float			burstRate;
	float			burstPhase;
	int				burstCount;
    float           dutyCycle;
	int             triggerSource;
	float			triggerTimer;
	int             selectedWaveform;
	BOOL			loading;
	NSMutableData*  waveform;
	NSArray*		allWaveFormsInMemory;
	NSString*		fileName;
	int             downloadIndex;
	int				savedTriggerSource;
	BOOL			negativePulse;
    BOOL            burstMode;
    
	enum {
        kInternalTrigger,
        kExternalTrigger,
        kTimerTrigger,
        kSoftwareTrigger 
	} triggerTypes;
	
	enum {
		kBuiltInSine,
		kBuiltInSquare,
		kBuiltInTriangle,
		kBuiltInRamp,
		kBuiltInPulse,
		kBuiltInPrbs,
		kBuiltInNoise,
		kBuiltInDC,
		kSquareWave1,
		kSingleSinWave1,
		kSingleSinWave2,
		kSquareWave2,
		kDoubleSinWave,
		kLogCalibrationWaveform,
		kLogCalibWave2,
		kLogCalibWave4,
		kDoubleLogamp,
		kTripleLogamp,
		kLogCalibWaveAdjust,
		kGaussian,
		kPinDiode,
		kNeedle,
		kGermaniumHighE,
		kGermaniumLowE,
		kWaveformFromFile,		
		kNumWaveforms   //must be last
    } userWaveformConsts;
	
	enum {
		kNumBuiltInTypes = 8
	} numBuiltInTypes;	
}

- (id) initWithPulser:(id)aPulser channelNumber:(int)aChannelNumber;

#pragma mark •••Accessors
- (int)channel;
- (id) pulser;
- (void) setPulser:(id)aPulser;
- (BOOL) burstMode;
- (void) setBurstMode:(BOOL)aFlag;
- (BOOL) negativePulse;
- (void) setNegativePulse:(BOOL)aNegativePulse;
- (float) voltage;
- (void) setVoltage:(float)aVoltage;
- (float) voltageOffset;
- (void) setVoltageOffset:(float)aVoltage;
- (float) frequency;
- (void) setFrequency:(float)aFrequency;
- (float) dutyCycle;
- (void) setDutyCycle:(float)aFrequency;
- (float) burstRate;
- (void) setBurstRate:(float)aRate; 
- (int) burstCount;
- (void) setBurstCount:(int)aRate; 
- (float) burstPhase;
- (void) setBurstPhase:(float)aRate; 
- (float) triggerTimer;
- (void) setTriggerTimer:(float)aValue;
- (void) writeTriggerSource:(int)aSource;
- (short) triggerSource;
- (void) setTriggerSource:(short)aValue;
- (int) selectedWaveform;
- (void) setSelectedWaveform:(int)newSelectedWaveform;
- (NSMutableData* )waveform;

#pragma mark •••Helpers
- (float) calculateFreq:(float)width;
- (void) buildWave;
- (NSUndoManager*) undoManager;

#pragma mark •••Hw AccessParam
- (void) initHardware;
- (void) writeVoltage;
- (void) writeVoltage:(float)aValue;
- (void) writeVoltageOffset;
- (void) writeVoltageOffset;
- (void) writeFrequency;
- (void) writeBurstRate:(float)aValue;
- (void) writeBurstRate;
- (void) writeBurstCount:(int)aValue;
- (void) writeBurstCount;
- (void) writeBurstPhase;
- (void) writeTriggerSource;
- (void) writeTriggerTimer;
- (void) writeBurstMode;
- (void) writeDutyCycle;
- (void) trigger;
- (void) emptyVolatileMemory;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Waveform Loading
- (id) calibration;
- (unsigned short) numPoints;
- (int)  downloadIndex;
- (unsigned int) maxNumberOfWaveformPoints;
- (BOOL) loading;
- (void) setLoading:(BOOL)aLoad;
- (void) downloadWaveform;
- (void) stopDownload;
- (void) loadFromNonVolativeMemory;
- (void) loadFromVolativeMemory;
- (void) waveFormWasSent;
- (void) updateLoadProgress;
- (void) downloadWaveform;
- (void) downloadWaveformWorker;
- (void) copyWaveformWorker;
- (BOOL) inBuiltInList:(NSString*)aName;
- (BOOL) inCustomList:(NSString*)aName;
- (BOOL) isWaveformInNonVolatileMemory;
- (NSArray*) getLoadedWaveforms;
- (void) emptyVolatileMemory;
- (unsigned int) numberOfWaveforms;
- (NSString*) nameOfWaveformAt:(unsigned int)position;
- (unsigned int) numberOfWaveforms;
- (NSString*) nameOfWaveformAt:(unsigned int)position;
- (NSString *) fileName;
- (void)  setFileName:(NSString *)newFileName;
- (void) waveFormWasSent;
- (void) updateLoadProgress;
- (void) insert:(unsigned short) numPoints value:(float) theValue;
- (void) insertNegativeFullSineWave:(unsigned short)numPoints amplitude:(float) theAmplitude phase:(float) thePhase;
- (void) insertGaussian:(unsigned short)numPoints amplitude:(float) theAmplitude;
- (void) insertPinDiode:(unsigned short)numPoints amplitude:(float) theAmplitude;
- (void) loadWaveformFile:(NSString*) theWavefile;
- (void) normalizeWaveform;
@end

extern NSString* ORPulser33500ChanVoltageChanged;
extern NSString* ORPulser33500ChanVoltageOffsetChanged;
extern NSString* ORPulser33500ChanFrequencyChanged;
extern NSString* ORPulser33500ChanBurstRateChanged;
extern NSString* ORPulser33500ChanBurstPhaseChanged;
extern NSString* ORPulser33500ChanBurstCountChanged;
extern NSString* ORPulser33500ChanTriggerSourceChanged;
extern NSString* ORPulser33500ChanTriggerTimerChanged;
extern NSString* ORPulser33500ChanSelectedWaveformChanged;
extern NSString* ORPulser33500WaveformLoadingNonVoltile;
extern NSString* ORPulser33500WaveformLoadProgressing;
extern NSString* ORPulser33500WaveformLoadFinished;
extern NSString* ORPulser33500NegativePulseChanged;
extern NSString* ORPulser33500BurstModeChanged;
extern NSString* ORPulser33500WaveformLoadStarted;
extern NSString* ORPulser33500WaveformLoadingVoltile;
extern NSString* ORPulser33500ChanDutyCycleChanged;
