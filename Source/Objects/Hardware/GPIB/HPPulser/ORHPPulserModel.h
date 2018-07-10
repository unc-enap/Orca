//
//  ORHPPulserModel.h
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORGpibDeviceModel.h"
#import "ORDataTaker.h"

// Structure used to describe characteristics of hardware register.
typedef struct HPPulserCustomWaveformStruct {
	NSString*       waveformName;
	NSString*       storageName;
	bool			tryToStore;
    bool            builtInFunction;
} HPPulserCustomWaveformStruct;

#define kCalibrationWidth 	7.8  //can't set exactly to 8 because of a bug in the HP pulser
#define kCalibrationVoltage 	750
#define kCalibrationBurstRate 	3.0 

#define kPadSize 100

@class ORDataPacket;

@interface ORHPPulserModel : ORGpibDeviceModel {
	NSMutableData*  waveform;
	float           voltage;
	float           burstRate;
	//float           totalWidth;	
	float           frequency;
	float           voltageOffset;
	int             burstCycles;
	int             selectedWaveform;
	int             burstPhase;
	int             burstNCycles;
	NSString*       fileName;
	int             downloadIndex;
	BOOL            loading;
    int             triggerSource;
	BOOL			enableRandom;
	float			minTime;
	float			maxTime;
	unsigned long	randomCount;
	unsigned long   pulserDataId;
	int				savedTriggerSource;
    BOOL			lockGUI;
    BOOL			negativePulse;
    BOOL            verbose;
	
	enum {
        kBuiltInSine,
        kBuiltInSquare,
        kBuiltInRamp,
        kBuiltInPulse,
        kBuiltInNoise,
        kBuiltInDC,
		kBuiltInSinc,
		kBuiltInNegRamp,
		kBuiltInExpRise,
		kBuiltInExpFall,
		kBuiltInCardiac,
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
        kWaveformFromScript,
		kNumWaveforms   //must be last
    } userWaveformConsts;
	
	enum {
		kNumBuiltInTypes = 11
	} numBuiltInTypes;
	
	enum {
		kVPP,
		kVRMS,
		kDBM,
		kDEF
	} voltageTypes;
	
	enum {
		kSine,
		kSquare,
		kTriangle,
		kRamp,
		kNoise,
		kDC,
		kUser
	} builtInFunctions;
	
	enum {
		kMaxNumWaveformPoints = 16000
	} maxNumWaveformPoints;
    
	enum {
        kInternalTrigger,
        kExternalTrigger,
        kSoftwareTrigger 
	} triggerTypes;
}

#pragma mark ***Initialization
- (id) 		init;
- (void) 	dealloc;
- (void)	setUpImage;
- (void)	makeMainController;
- (void) registerNotificationObservers;
- (void) runStatusChanged:(NSNotification*)aNotification;
- (void) waveFormWasSent;
- (void) updateLoadProgress;

#pragma mark •••Accessors
- (BOOL) verbose;
- (void) setVerbose:(BOOL)aVerbose;
- (BOOL) negativePulse;
- (void) setNegativePulse:(BOOL)aNegativePulse;
- (BOOL) lockGUI;
- (void) setLockGUI:(BOOL)aLockGUI;
- (NSString *) fileName;
- (void)  setFileName:(NSString *)newFileName;

- (int)	  selectedWaveform;
- (void)  setSelectedWaveform:(int)newSelectedWaveform;
- (NSMutableData*) waveform;
- (void)  setWaveform:(NSMutableData* )newWaveform;
- (float) frequency;
- (void)  setFrequency:(float)newFrequency;
- (float) voltage;
- (void)  setVoltage:(float)newVoltage;
- (float) voltageOffset;
- (void)  setVoltageOffset:(float)newVoltageOffset;
- (float) burstRate;
- (void)  setBurstRate:(float)aValue;
- (int)   burstPhase;
- (void)  setBurstPhase:(int)aValue;
- (int)   burstCycles;
- (void)  setBurstCycles:(int)aValue;
- (float) totalWidth;
- (void)  setTotalWidth:(float)aValue;

- (int)	 triggerSource;
- (void) setTriggerSource:(short)aValue;

- (int)  downloadIndex;
- (void) stopDownload;
- (BOOL) loading;
- (void) setLoading:(BOOL)aLoad;
- (BOOL) enableRandom;
- (void) setEnableRandom:(BOOL)aNewEnableRandom;
- (float) minTime;
- (void) setMinTime:(float)aNewMinTime;
- (float) maxTime;
- (void) setMaxTime:(float)aNewMaxTime;
- (unsigned long) randomCount;
- (void) setRandomCount:(unsigned long)aNewRandomCount;
- (unsigned long)   pulserDataId;
- (void)   setPulserDataId:(unsigned long)aValue;
- (id)  dialogLock;
- (unsigned int) maxNumberOfWaveformPoints;

#pragma mark •••Hardware Access
- (NSString*) readIDString;
- (void) resetAndClear;
- (void) systemTest;
- (void) logSystemResponse;
- (void) writeVoltage:(unsigned short)value;
- (void) writeVoltageOffset:(short)value;
- (void) writeFrequency:(float)value;
- (void) writeBurstRate:(float)rate;
- (void) writeBurstPhase:(int)phase;
- (void) writeBurstCycles:(int)cycles;
- (void) writeBurstState:(BOOL)value;
- (void) writeTriggerSource:(int)value;
- (void) writeVoltageLow:(unsigned short)value;
- (void) writeVoltageHigh:(unsigned short)value;
- (void) writeOutput:(BOOL)aState;
- (void) writeSync:(BOOL)aState;
- (void) writePulsePeriod:(float)aValue;
- (void) writePulseWidth:(float)aValue;
- (void) writePulseDutyCycle:(unsigned short)aValue;
- (void) writePulseEdgeTime:(float)aValue;
- (void) downloadWaveform;
- (void) downloadWaveformWorker;
- (void) copyWaveformWorker;
- (void) outputWaveformParams;


#pragma mark •••NonVolatile Memory Management
- (void) loadFromVolativeMemory;
- (void) loadFromNonVolativeMemory;
- (BOOL) isWaveformInNonVolatileMemory;
- (void) emptyVolatileMemory;
- (NSArray*) getLoadedWaveforms;

- (NSDictionary*) dataRecordDescription;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark •••Waveform Building
- (void) insert:(unsigned short) numPoints value:(float) theValue;
- (void) insertNegativeFullSineWave:(unsigned short)numPoints amplitude:(float) theAmplitude phase:(float) thePhase;
- (void) insertGaussian:(unsigned short)numPoints amplitude:(float) theAmplitude;
- (void) insertPinDiode:(unsigned short)numPoints amplitude:(float) theAmplitude;
- (void) loadWaveformFile:(NSString*) theWavefile;
- (void) normalizeWaveform;
- (unsigned short) numPoints;
- (void) trigger;

#pragma mark •••Helpers
- (void) buildWave;
- (BOOL) inCustomList:(NSString*)aName;
- (BOOL) inBuiltInList:(NSString*)aName;
- (float) calculateFreq:(float)width;
- (unsigned int) numberOfWaveforms;
- (NSString*) nameOfWaveformAt:(unsigned int)position;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)aDecoder;
- (void)encodeWithCoder:(NSCoder*)anEncoder;
- (void)loadMemento:(NSCoder*)decoder;
- (void)saveMemento:(NSCoder*)anEncoder;
- (NSData*) memento;
- (void) restoreFromMemento:(NSData*)aMemento;

@end

extern NSString* ORHPPulserModelVerboseChanged;
extern NSString* ORHPPulserModelNegativePulseChanged;
extern NSString* ORHPPulserModelLockGUIChanged;
extern NSString* ORHPPulserVoltageChangedNotification;
extern NSString* ORHPPulserVoltageOffsetChangedNotification;
extern NSString* ORHPPulserFrequencyChangedNotification;
extern NSString* ORHPPulserBurstRateChangedNotification;
extern NSString* ORHPPulserBurstPhaseChangedNotification;
extern NSString* ORHPPulserBurstCyclesChangedNotification;
//extern NSString* ORHPPulserTotalWidthChangedNotification;
extern NSString* ORHPPulserSelectedWaveformChangedNotification;
extern NSString* ORHPPulserWaveformLoadStartedNotification;
extern NSString* ORHPPulserWaveformLoadProgressingNotification;
extern NSString* ORHPPulserWaveformLoadFinishedNotification;
extern NSString* ORHPPulserWaveformLoadingNonVoltileNotification;
extern NSString* ORHPPulserWaveformLoadingVoltileNotification;
extern NSString* ORHPPulserTriggerModeChangedNotification;
extern NSString* ORHPPulserEnableRandomChangedNotification;
extern NSString* ORHPPulserMinTimeChangedNotification;
extern NSString* ORHPPulserMaxTimeChangedNotification;
extern NSString* ORHPPulserRandomCountChangedNotification;
