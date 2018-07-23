//
//  ORKatrinV4FLTModel.h
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


#pragma mark •••Imported Files
#import "ORIpeCard.h"
#import "ORIpeV4FLTModel.h"
#import "KatrinV4_HW_Definitions.h"
#import "ORHWWizard.h"
#import "ORDataTaker.h"
#import "ORKatrinV4FLTDefs.h"
#import "ORAdcInfoProviding.h"


#pragma mark •••Forward Definitions
@class ORDataPacket;
@class ORTimeRate;
@class ORTestSuit;
@class ORCommandList;
@class ORRateGroup;

#define kNumKatrinV4FLTTests            5
#define kKatrinV4FLTBufferSizeLongs     1024
#define kKatrinV4FLTBufferSizeShorts    1024/2

/** Access to the first level trigger board of the IPE-DAQ V4 electronics.
 * The board contains ADCs for 24 channels and digital logic (FPGA) 
 * for implementation experiment specific trigger logic. 
 * 
 * @section hwaccess Access to hardware  
 * There can be only a single adapter connected to the firewire bus. 
 * In the Ipe implementation this is the Slt board. The Flt has to refer
 * this interface. example: [[self crate] aapter] is the slt object.
 *
 * Every time a run is started the stored configuratiation is written to the
 * hardware before recording the data.
 *
 * The interface to the graphical configuration dialog is implemented in ORKatrinV4FLTController.
 *
 * The Flt will produce several types of data objects depending on the run mode:
 *   - events containing timestamp and energy
 *   - events with an additional adc data trace of to 102.4 usec length (2048 samples)
 * 
 * @section readout Readout
 * The class implements two types of readout loops: Event by event (list mode in KATRIN
 * collaboration terms) and a periodic mode.
 * The event readout is used in energy and trace mode. For every event the time stamp
 * and a hardware id are stored. 
 * The periodic mode is the histogram mode. A histogram is filled on the hardware according
 * to the occured events and this histogram is read out frequently.
 *
 */ 

//
//@interface ORKatrinV4FLTModel : ORIpeCard <ORDataTaker,ORHWWizard,ORHWRamping,ORAdcInfoProviding>
//
// 2010-04-25 -tb-
// I started subclassing ORKatrinV4FLTModel from ORIpeV4FLTModel.
// Necessary changes were:
// - comment out all data members (see below); the KATRIN related should move here
// - (void) dealloc: just needs to call the super dealloc; change acording to the data members in the future!
// - (void)encodeWithCoder:
// - initWithCoder:     these two were called twice; change acording to the data members in the future!
// - in ORKatrinV4FLTDefs.h ipeFltHitRateDataStruct already was known from ORIpeV4FLTDefs.h
// - in Interface Builder: File's Owner need to be changed to ORKatrinV4FLTModel (was ORIpeV4FLTModel)

static enum  {
    eInitializing,
    eSetThresholds,
    eIntegrating,
    eCheckRates,
    eFinishing,
    eNothingToDo,
    eManualAbort
} eKatrinV4ThresFinderStates;

@interface ORKatrinV4FLTModel : ORIpeV4FLTModel <ORDataTaker,ORHWWizard,ORHWRamping,ORAdcInfoProviding>
{
    // Hardware configuration
    int shipSumHistogram;
    int fifoLength;
    int filterShapingLength;  
	BOOL activateDebuggingDisplays;
	unsigned char fifoFlags[kNumV4FLTChannels];
    int receivedHistoChanMap;
    int receivedHistoCounter;
    int customVariable;
    int poleZeroCorrection;
    double decayTime;
    int runControlState;
	ORAlarm* fltV4useDmaBlockReadAlarm;
    int useDmaBlockRead;
    int boxcarLength;
    int hitRateMode;
    uint64_t  lostEvents;
    uint64_t  lostEventsTr;

    uint32_t   oldTriggerEnabledMask; //!< mask to temporarially store the enabled mask for later reuse.
    unsigned short lastHitRateLength;
    BOOL isBetweenSubruns;//temp variable used for shipping sum histograms -tb-
    int useBipolarEnergy;
    uint32_t bipolarEnergyThreshTest;
    int skipFltEventReadout;
    BOOL forceFLTReadout;  //new for bipolar firmware (SLT readout is now recommended) 2016-07 -tb-
    int energyOffset;
    uint32_t inhibitDuringLastHitrateReading;
    uint32_t runStatusDuringLastHitrateReading;
    uint32_t lastSltSecondCounter;
    uint32_t nHitrateCount;
    BOOL initializing;

    uint32_t lastHistReset; //< indicates if the histogramm parameter have been changed
    uint32_t   oldHitRateMask;
    unsigned short  oldHitRateLength;
    int             oldHitRateMode;
    float lowerThresholdBound[kNumV4FLTChannels];
    float upperThresholdBound[kNumV4FLTChannels];
    float lastThresholdWithNoRate[kNumV4FLTChannels];
    float thresholdToTest[kNumV4FLTChannels];
    float oldThresholds[kNumV4FLTChannels];
    int   doneChanCount;
    int   workingChanCount;

    struct timeval findert0;
    struct timeval findert1;
    
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (short) getNumberRegisters;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) runIsAboutToStop:(NSNotification*)aNote;
- (void) runIsAboutToChangeState:(NSNotification*)aNote;
- (void) betweenSubRun:(NSNotification*)aNote;
- (void) startSubRun:(NSNotification*)aNote;

#pragma mark •••Accessors
- (int) energyOffset;
- (void) setEnergyOffset:(int)aEnergyOffset;
- (BOOL) forceFLTReadout;
- (void) setForceFLTReadout:(BOOL)aForceFLTReadout;
- (int) skipFltEventReadout;
- (void) setSkipFltEventReadout:(int)aSkipFltEventReadout;
- (uint32_t) bipolarEnergyThreshTest;
- (void) setBipolarEnergyThreshTest:(uint32_t)aBipolarEnergyThreshTest;
- (int) useBipolarEnergy;
- (void) setUseBipolarEnergy:(int)aUseBipolarEnergy;
- (int) useSLTtime;
- (void) updateUseSLTtime;
//- (void) setUseSLTtime:(int)aUseSLTtime;
- (int) boxcarLength;
- (void) setBoxcarLength:(int)aBoxcarLength;
- (int) useDmaBlockRead;
- (void) setUseDmaBlockRead:(int)aUseDmaBlockRead;
- (double) decayTime;
- (void) setDecayTime:(double)aDecayTime;
- (int) poleZeroCorrection;
- (void) setPoleZeroCorrection:(int)aPoleZeroCorrection;
- (double) poleZeroCorrectionHint;
- (int) poleZeroCorrectionSettingHint:(double)attenuation;
- (int) customVariable;
- (void) setCustomVariable:(int)aCustomVariable;
- (int) receivedHistoCounter;
- (void) setReceivedHistoCounter:(int)aReceivedHistoCounter;
- (void) clearReceivedHistoCounter;
- (int) receivedHistoChanMap;
- (void) setReceivedHistoChanMap:(int)aReceivedHistoChanMap;
- (BOOL) activateDebuggingDisplays;
- (void) setActivateDebuggingDisplays:(BOOL)aState;
- (int) fifoLength;
- (void) setFifoLength:(int)aFifoLength;
- (int) shipSumHistogram;
- (void) setShipSumHistogram:(int)aShipSumHistogram;
- (int) targetRate;
- (void) setTargetRate:(int)aTargetRate;
- (int) histEMax;
- (void) setHistEMax:(int)aHistMaxEnergy;
- (int) histPageAB;
- (void) setHistPageAB:(int)aHistPageAB;
- (int) runMode;
- (void) setRunMode:(int)aRunMode;
- (void) setToDefaults;
- (BOOL) storeDataInRam;
- (void) setStoreDataInRam:(BOOL)aStoreDataInRam;
- (int) filterShapingLength;
- (int) filterShapingLengthInBins;
- (int) filterLengthInBins;
- (void) setFilterShapingLengthOnInit:(int)aFilterShapingLength;
- (void) setFilterShapingLength:(int)aFilterShapingLength;
- (int) gapLength;
- (void) setGapLength:(int)aGapLength;
- (uint32_t) postTriggerTime;
- (void) setPostTriggerTime:(uint32_t)aPostTriggerTime;
- (int) fifoBehaviour;
- (void) setFifoBehaviour:(int)aFifoBehaviour;
- (int) analogOffset;
- (void) setAnalogOffset:(int)aAnalogOffset;
- (BOOL) ledOff;
- (void) setLedOff:(BOOL)aledOff;
- (uint32_t) interruptMask;
- (void) setInterruptMask:(uint32_t)aInterruptMask;
- (unsigned short) hitRateLength;
- (void) setHitRateLength:(unsigned short)aHitRateLength;
- (BOOL) noiseFloorRunning;
- (void) findNoiseFloors;
- (NSString*) noiseFloorStateString;

- (uint32_t) histNofMeas;
- (void) setHistNofMeas:(uint32_t)aHistNofMeas;
- (uint32_t) histMeasTime;
- (void) setHistMeasTime:(uint32_t)aHistMeasTime;
- (uint32_t) histRecTime;
- (void) setHistRecTime:(uint32_t)aHistRecTime;
- (uint32_t) histLastEntry;
- (void) setHistLastEntry:(uint32_t)aHistLastEntry;
- (uint32_t) histFirstEntry;
- (void) setHistFirstEntry:(uint32_t)aHistFirstEntry;
- (int) histClrMode;
- (void) setHistClrMode:(int)aHistClrMode;
- (int) histMode;
- (void) setHistMode:(int)aHistMode;
- (uint32_t) histEBin;
- (void) setHistEBin:(uint32_t)aHistEBin;
- (uint32_t) histEMin;
- (void) setHistEMin:(uint32_t)aHistEMin;
- (uint32_t) getLastHistReset;


- (uint32_t) dataId;
- (void) setDataId: (uint32_t)aDataId;
- (uint32_t) waveFormId;
- (void) setWaveFormId: (uint32_t) aWaveFormId;
- (uint32_t) hitRateId;
- (void) setHitRateId: (uint32_t)aHitRateId;
- (uint32_t) histogramId;
- (void) setHistogramId: (uint32_t)aHistogramId;
- (int) hitRateMode;
- (void) setHitRateMode:(int)aMode;
- (void) stopReadingHitRates;
- (void) startReadingHitRates;
- (void) clearHitRates;

- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;

- (NSMutableArray*) gains;
- (NSMutableArray*) thresholds;
- (uint32_t) triggerEnabledMask;
- (void) setTriggerEnabledMask:(uint32_t)aMask;
- (void) setGains:(NSMutableArray*)aGains;
- (void) setThresholds:(NSMutableArray*)aThresholds;
- (void) disableAllTriggers;
- (void) fireSoftwareTrigger;

- (BOOL) hitRateEnabled:(unsigned short) aChan;
- (void) setHitRateEnabled:(unsigned short) aChan withValue:(BOOL) aState;

- (float) actualFilterLength;
- (float)threshold:(unsigned short) aChan;
- (unsigned short)gain:(unsigned short) aChan;
- (BOOL) triggerEnabled:(unsigned short) aChan;
- (void) setFloatThreshold:(unsigned short) aChan withValue:(float) aThreshold;
- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain;
- (void) setTriggerEnabled:(unsigned short) aChan withValue:(BOOL) aState;

- (int) fltRunMode;
- (void) setFltRunMode:(int)aMode;
- (void) enableAllHitRates:(BOOL)aState;
- (void) enableAllTriggers:(BOOL)aState;
- (float) hitRate:(unsigned short)aChan;
- (float) rate:(int)aChan;

- (BOOL) hitRateOverFlow:(unsigned short)aChan;
- (float) hitRateTotal;

- (ORTimeRate*) totalRate;
- (void) setTotalRate:(ORTimeRate*)newTimeRate;
- (uint64_t) lostEvents;
- (void) setLostEvents:(uint64_t)aCounter;
- (uint64_t) lostEventsTr;
//- (void) setLostTrEvents:(uint64_t)aCounter;

- (unsigned short) selectedRegIndex;
- (void) setSelectedRegIndex:(unsigned short) anIndex;
- (uint32_t) writeValue;
- (void) setWriteValue:(uint32_t) aValue;
- (unsigned short) selectedChannelValue;
- (void) setSelectedChannelValue:(unsigned short) aValue;
- (int) restrictIntValue:(int)aValue min:(int)aMinValue max:(int)aMaxValue;
- (float) restrictFloatValue:(int)aValue min:(float)aMinValue max:(float)aMaxValue;

- (void) devTest1ButtonAction;
- (void) devTest2ButtonAction;

- (void) testButtonLowLevelConfigTP;
- (void) testButtonLowLevelFireTP;
- (void) testButtonLowLevelResetTP;

#pragma mark •••HW Access
//all can raise exceptions
- (int) accessTypeOfReg:(int)aReg;
- (uint32_t) regAddress:(int)aReg channel:(int)aChannel;
- (uint32_t) regAddress:(int)aReg;
- (uint32_t) adcMemoryChannel:(int)aChannel page:(int)aPage;
- (uint32_t) readReg:(short)aReg;
- (uint32_t) readReg:(short)aReg channel:(int)aChannel;
- (void) writeReg:(short)aReg value:(uint32_t)aValue;
- (void) writeReg:(short)aReg channel:(int)aChannel value:(uint32_t)aValue;

- (void) executeCommandList:(ORCommandList*)aList;
- (id) readRegCmd:(short) aRegister channel:(short) aChannel;
- (id) writeRegCmd:(short) aRegister channel:(short) aChannel value:(uint32_t)aValue;
- (id) readRegCmd:(short) aRegister;
- (id) writeRegCmd:(short) aRegister value:(uint32_t)aValue;

- (uint32_t)  readSeconds;
- (void)  writeSeconds:(uint32_t)aValue;
- (void) setTimeToMacClock;

- (uint32_t) readVersion;
- (uint32_t) readpVersion;
- (uint32_t) readBoardIDLow;
- (uint32_t) readBoardIDHigh;
- (int)			  readSlot;

- (int)		readMode;

- (void) writeClrCnt;
- (void) loadThresholdsAndGains;
- (void) initBoard;
- (void) writeHitRateMask;
- (void) writeInterruptMask;
- (uint32_t) hitRateEnabledMask;
- (void) setHitRateEnabledMask:(uint32_t)aMask;
- (void) readHitRates;
- (void) readHistogrammingStatus;
- (void) writeTestPattern:(uint32_t*)mask length:(int)len;
- (void) writeNextPattern:(uint32_t)aValue;
- (uint32_t) readStatus;
- (uint32_t) readControl;
- (uint32_t) readHitRateMask;
- (void) writeControl;
- (void) writeControlWithFltRunMode:(int)aMode;
- (void) writeControlWithStandbyMode;
- (void) printStatusReg;
- (void) printPStatusRegs;
- (void) printVersions;
- (void) printValueTable;
- (void) printEventFIFOs;
- (void) writeHistogramControl;
- (void) resetHistogramMode;
- (BOOL) waitOnBusyFlag;

- (void) writeThreshold:(int)i value:(uint32_t)aValue;
- (unsigned int) readThreshold:(int)i;
- (void) writeGain:(int)i value:(unsigned short)aValue;
- (unsigned short) readGain:(int)i;
- (void) writeTriggerControl;
- (BOOL) partOfEvent:(short)chan;
- (int) stationNumber;
- (uint32_t) eventMask;
- (void) eventMask:(uint32_t)aMask;
- (NSString*) boardTypeName:(int)aType;
- (NSString*) fifoStatusString:(int)aType;
- (unsigned char) fifoFlags:(short)aChan;
- (void) setFifoFlags:(short)aChan withValue:(unsigned char)aChan;
- (NSString*) fifoFlagString:(short)aChan;

- (uint32_t) readMemoryChan:(int)chan page:(int)aPage;
- (void) readMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer;
- (void) clear:(int)aChan page:(int)aPage value:(unsigned short)aValue;

- (uint32_t) eventCount:(int)aChannel;
- (void)		  clearEventCounts;
- (BOOL) bumpRateFromDecodeStage:(short)channel;
- (BOOL) setFromDecodeStage:(short)aChan fifoFlags:(unsigned char)flags;

- (NSString*) getRegisterName: (short) anIndex;
- (short) getAccessType: (short) anIndex;
- (uint32_t) getAddressOffset: (short) anIndex;

- (uint64_t ) readLostEventsTr;

//for sync of HW histogramming with sub-runs
- (BOOL) setFromDecodeStageReceivedHistoForChan:(short)aChan;


#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (NSDictionary*) dataRecordDescription;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark •••Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark •••HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;
- (void) setScaledThreshold:(short)aChan withValue:(float)aValue;
- (float) scaledThreshold:(short)aChan;


- (void) testReadHisto;
- (BOOL) checkForDifferencesInName:(NSString*)aName orcaValue:(uint32_t)orcaValue hwValue:(uint32_t)hwValue;
- (BOOL) compareRegisters:(BOOL)verbose;
- (BOOL) compareThresholdsAndGains:(BOOL)verbose;
- (BOOL) compareHitRateMask:(BOOL)verbose;
- (BOOL) compareFilter:(BOOL)verbose;
- (BOOL) comparePostTrigger:(BOOL)verbose;
- (BOOL) compareEnergyOffset:(BOOL)verbose;
- (BOOL) compareAnalogOffset:(BOOL)verbose;
- (BOOL) compareControlReg:(BOOL)verbose;

@end

@interface ORKatrinV4FLTModel (tests)
- (void) runTests;
- (BOOL) testsRunning;
- (void) setTestsRunning:(BOOL)aTestsRunning;
- (NSMutableArray*) testEnabledArray;
- (void) setTestEnabledArray:(NSMutableArray*)aTestsEnabled;
- (NSMutableArray*) testStatusArray;
- (void) setTestStatusArray:(NSMutableArray*)aTestStatus;
- (NSString*) testStatus:(int)index;
- (BOOL) testEnabled:(int)index;

- (void) ramTest;
- (void) modeTest;
- (void) thresholdGainTest;
- (void) speedTest;
- (void) eventTest;
- (int) compareData:(unsigned short*) data
			pattern:(unsigned short*) pattern
			  shift:(int) shift
				  n:(int) n;

@end

extern NSString* ORKatrinV4FLTModelEnergyOffsetChanged;
extern NSString* ORKatrinV4FLTModelForceFLTReadoutChanged;
extern NSString* ORKatrinV4FLTModelSkipFltEventReadoutChanged;
extern NSString* ORKatrinV4FLTModelBipolarEnergyThreshTestChanged;
extern NSString* ORKatrinV4FLTModelUseBipolarEnergyChanged;
extern NSString* ORKatrinV4FLTModelUseSLTtimeChanged;
extern NSString* ORKatrinV4FLTModelBoxcarLengthChanged;
extern NSString* ORKatrinV4FLTModelUseDmaBlockReadChanged;
extern NSString* ORKatrinV4FLTModelDecayTimeChanged;
extern NSString* ORKatrinV4FLTModelPoleZeroCorrectionChanged;
extern NSString* ORKatrinV4FLTModelCustomVariableChanged;
extern NSString* ORKatrinV4FLTModelReceivedHistoCounterChanged;
extern NSString* ORKatrinV4FLTModelReceivedHistoChanMapChanged;
extern NSString* ORKatrinV4FLTModelFifoLengthChanged;
extern NSString* ORKatrinV4FLTModelShipSumHistogramChanged;
extern NSString* ORKatrinV4FLTModelTargetRateChanged;
extern NSString* ORKatrinV4FLTModelHistMaxEnergyChanged;
extern NSString* ORKatrinV4FLTModelHistPageABChanged;
extern NSString* ORKatrinV4FLTModelHistLastEntryChanged;
extern NSString* ORKatrinV4FLTModelHistFirstEntryChanged;
extern NSString* ORKatrinV4FLTModelHistClrModeChanged;
extern NSString* ORKatrinV4FLTModelHistModeChanged;
extern NSString* ORKatrinV4FLTModelHistEBinChanged;
extern NSString* ORKatrinV4FLTModelHistEMinChanged;
extern NSString* ORKatrinV4FLTModelStoreDataInRamChanged;
extern NSString* ORKatrinV4FLTModelFilterShapingLengthChanged;
extern NSString* ORKatrinV4FLTModelGapLengthChanged;
extern NSString* ORKatrinV4FLTModelHistNofMeasChanged;
extern NSString* ORKatrinV4FLTModelHistMeasTimeChanged;
extern NSString* ORKatrinV4FLTModelHistRecTimeChanged;
extern NSString* ORKatrinV4FLTModelPostTriggerTimeChanged;
extern NSString* ORKatrinV4FLTModelFifoBehaviourChanged;
extern NSString* ORKatrinV4FLTModelAnalogOffsetChanged;
extern NSString* ORKatrinV4FLTModelLedOffChanged;
extern NSString* ORKatrinV4FLTModelInterruptMaskChanged;
extern NSString* ORKatrinV4FLTModelTestsRunningChanged;
extern NSString* ORKatrinV4FLTModelTestEnabledArrayChanged;
extern NSString* ORKatrinV4FLTModelTestStatusArrayChanged;
extern NSString* ORKatrinV4FLTModelHitRateChanged;
extern NSString* ORKatrinV4FLTModelHitRateLengthChanged;
extern NSString* ORKatrinV4FLTModelHitRateEnabledMaskChanged;
extern NSString* ORKatrinV4FLTModelTriggerEnabledMaskChanged;
extern NSString* ORKatrinV4FLTModelGainChanged;
extern NSString* ORKatrinV4FLTModelThresholdChanged;
extern NSString* ORKatrinV4FLTChan;
extern NSString* ORKatrinV4FLTModelGainsChanged;
extern NSString* ORKatrinV4FLTModelThresholdsChanged;
extern NSString* ORKatrinV4FLTModelModeChanged;
extern NSString* ORKatrinV4FLTSettingsLock;
extern NSString* ORKatrinV4FLTModelEventMaskChanged;
extern NSString* ORKatrinV4FLTNoiseFloorChanged;
extern NSString* ORKatrinV4FLTModelActivateDebuggingDisplaysChanged;
extern NSString* ORKatrinV4FLTModelHitRateModeChanged;
extern NSString* ORKatrinV4FLTModelLostEventsChanged;
extern NSString* ORKatrinV4FLTModelLostEventsTrChanged;
extern NSString* ORKatrinV4FLTStartingUpperBoundChanged;

extern NSString* ORIpeSLTModelName;

extern NSString* ORKatrinV4FLTSelectedRegIndexChanged;
extern NSString* ORKatrinV4FLTWriteValueChanged;
extern NSString* ORKatrinV4FLTSelectedChannelValueChanged;
extern NSString* ORKatrinV4FLTModeFifoFlagsChanged;
