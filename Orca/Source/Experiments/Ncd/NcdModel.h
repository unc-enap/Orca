//
//  NcdModel.h
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
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


#pragma mark ¥¥¥Imported Files
#import "ORDataTaker.h"

@class NcdDetector;
@class ORDataPacket;
@class ORTask;
@class NcdPDSStepTask;
@class NcdLogAmpTask;
@class NcdLinearityTask;
@class NcdThresholdTask;
@class NcdCableCheckTask;
@class ORHPPulserModel;
@class NcdPulseChannelsTask;

@interface NcdModel :  OrcaObject
{
    @private
        NSMutableDictionary* colorBarAttributes;
        NSDictionary*       xAttributes;
        NSDictionary*       yAttributes;


        unsigned long displayOptionMask;

        unsigned long pulserDataId;
        unsigned long logAmpDataId;
        unsigned long linearityDataId;
        unsigned long thresholdDataId;
        unsigned long stepPDSDataId;
        unsigned long cableCheckDataId;
		unsigned long pulseChannelsDataId;
		
        //task stuff
        NcdPDSStepTask* ncdPDSStepTask;
        NcdLogAmpTask* ncdLogAmpTask;
        NcdLinearityTask* ncdLinearityTask;
        NcdThresholdTask* ncdThresholdTask;
        NcdCableCheckTask* ncdCableCheckTask;
        NcdPulseChannelsTask* ncdPulseChannelsTask;

        int hardwareCheck;
        int shaperCheck;
        int muxCheck;
        int triggerCheck;
        NSDate* captureDate;
        NSMutableArray* problemArray;
        ORAlarm*    failedHardwareCheckAlarm;
        ORAlarm*    failedShaperCheckAlarm;
        ORAlarm*    failedTriggerCheckAlarm;
        ORAlarm*    failedMuxCheckAlarm;
        ORAlarm*    noDispatcherAlarm;
        ORAlarm*    builderNotConnectedAlarm;

        unsigned long sourceMask;
        BOOL        muxMementosExist;
        NSMutableArray* altMuxThresholds;
		NSMutableArray* fullEfficiencyMuxThresholds;
        BOOL		allDisabled;
		
		NSString*	nominalSettingsFile;
		float		currentMuxEfficiency;
		BOOL runningAtReducedEfficiency;
		NSDate* reducedEfficiencyDate;
}


- (void) installTasks:(NSNotification*)aNote;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) registerForShaperRates;
- (void) registerForMuxRates;
- (void) configurationChanged:(NSNotification*)aNote;
- (void) runStatusChanged:(NSNotification*)aNote;
- (void) registerForRates;

#pragma mark ¥¥¥Accessors
- (NSDate*) reducedEfficiencyDate;
- (void) setReducedEfficiencyDate:(NSDate*)aReducedEfficiencyDate;
- (BOOL) runningAtReducedEfficiency;
- (void) setRunningAtReducedEfficiency:(BOOL)aRunningAtReducedEfficiency;
- (float) currentMuxEfficiency;
- (void) setCurrentMuxEfficiency:(float)aCurrentMuxEfficiency;
- (NSString*) nominalSettingsFile;
- (void) setNominalSettingsFile:(NSString*)aNominalSettingsFile;
- (BOOL)allDisabled;
- (void)setAllDisabled:(BOOL)flag;
- (NSMutableArray *)altMuxThresholds;
- (void)setAltMuxThresholds:(NSMutableArray *)anArray;
- (NSMutableArray *)fullEfficiencyMuxThresholds;
- (void)setFullEfficiencyMuxThresholds:(NSMutableArray *)anArray;

- (id) dependentTask:(ORTask*)aTask;
- (NSMutableDictionary*) colorBarAttributes;
- (NSDictionary*)   xAttributes;
- (void) setYAttributes:(NSMutableDictionary*)someAttributes;
- (NSDictionary*)   yAttributes;
- (void) setXAttributes:(NSMutableDictionary*)someAttributes;
- (void) setColorBarAttributes:(NSMutableDictionary*)newColorBarAttributes;
- (NcdDetector*) detector;
- (void) collectRates;
- (unsigned long) displayOptionMask;
- (void) setDisplayOptionMask: (unsigned long) aDisplayOptionMask;
- (void) setDisplayOption:(short)optionTag state:(BOOL)aState;
- (BOOL) displayOptionState:(int)optionTag;
- (BOOL) drawTubeLabel;
- (void) standAloneMode:(BOOL)state;
- (unsigned long) pulserDataId;
- (NSDate *) captureDate;
- (void) setCaptureDate: (NSDate *) aCaptureDate;

- (int) hardwareCheck;
- (void) setHardwareCheck: (int) HardwareCheck;
- (int) shaperCheck;
- (void) setShaperCheck: (int) ShaperCheck;
- (int) muxCheck;
- (void) setMuxCheck: (int) MuxCheck;
- (int) triggerCheck;
- (void) setTriggerCheck: (int) TriggerCheck;
- (void) setTriggerCheckFailed;
- (void) setShaperCheckFailed;
- (void) setMuxCheckFailed;
- (void) setHardwareCheckFailed;


- (void) setPulserDataId: (unsigned long)aPulserDataId;
- (unsigned long) logAmpDataId;
- (void) setLogAmpDataId: (unsigned long) aLogAmpDataId;
- (unsigned long) linearityDataId;
- (void) setLinearityDataId: (unsigned long) aLinearityDataId;
- (unsigned long) thresholdDataId;
- (void) setThresholdDataId: (unsigned long) aThresholdDataId;
- (unsigned long) cableCheckDataId;
- (void) setCableCheckDataId: (unsigned long) aCableCheckDataId;
- (unsigned long) stepPDSDataId;
- (void) setStepPDSDataId: (unsigned long) aStepPDSDataId;

- (void)setSourceMask:(unsigned long)aMask;

- (NSMutableDictionary*) captureState;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)aDictionary;
- (BOOL) preRunChecks;
- (void) printProblemSummary;

- (void) runAboutToStart:(NSNotification*)aNote;
- (void) runEnded:(NSNotification*)aNote;
- (void) taskDidStart:(NSNotification*)aNote;
- (void) taskDidFinish:(NSNotification*)aNote;

- (int) getLogAmpState;
- (int) getExtendedLinearityState;
- (int) getLinearityState;
- (int) getThresholdState;
- (void) startLogAmp:(BOOL)state;
- (void) startLinearity:(BOOL)state;
- (void) startExtendedLinearity:(BOOL)state;
- (void) startThreshold:(BOOL)state;
- (void) startNRE:(BOOL)state;

- (NSString*) descriptionLinearity;
- (NSString*) descriptionExtendedLinearity;
- (NSString*) descriptionCableCheck; 
- (NSString*) descriptionThreshold;  
- (NSString*) descriptionLogAmp;    


- (NSDictionary*) dataRecordDescription;
- (void) shipPulserRecord:(ORHPPulserModel*)thePulser;
- (void) shipTaskRecord:(id)aTask running:(BOOL)aState;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;


- (void) modifiyMuxEfficiency;
- (void) restoreMuxEfficiency;
- (void) saveNominalSettingsTo:(NSString*)filePath;
- (void) restoreToNomional;
- (void) restoreMuxesToNomional;
- (void) restoreShapersToNominal;
- (void) restoreShaperGainsToNominal;
- (void) restoreShaperThresholdsToNominal;

- (int) getLogAmpState;
- (int) getExtendedLinearityState;
- (int) getLinearityState;
- (int) getThresholdState;
- (int) getCableCheckState;
- (int) getPulseChannelsState;

@end

extern NSString* NcdModelReducedEfficiencyDateChanged;
extern NSString* NcdModelRunningAtReducedEfficiencyChanged;
extern NSString* NcdModelCurrentMuxEfficiencyChanged;
extern NSString* NcdModelNominalSettingsFileChanged;
extern NSString* ORNcdHardwareCheckChangedNotification;
extern NSString* ORNcdShaperCheckChangedNotification;
extern NSString* ORNcdMuxCheckChangedNotification;
extern NSString* ORNcdTriggerCheckChangedNotification;

extern NSString* ORNcdRateColorBarChangedNotification;
extern NSString* ORNcdChartXChangedNotification;
extern NSString* ORNcdChartYChangedNotification;
extern NSString* ORNcdDisplayOptionMaskChangedNotification;
extern NSString* ORNcdSpecialLock;
extern NSString* ORNcdTubeMapLock;
extern NSString* ORNcdDetectorLock;
extern NSString* ORNcdNominalSettingsLock;
extern NSString* ORNcdCaptureDateChangedNotification;
extern NSString* ORNcdMuxThresholdN16FileChangedNotification;
extern NSString* ORNcdRateAllDisableChangedNotification;

