//
//  ORIpeV4FLTModel.h
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
#import "ORIpeV4SLTModel.h"
#import "ORHWWizard.h"
#import "ORDataTaker.h"
#import "ORIpeV4FLTDefs.h"
#import "ORAdcInfoProviding.h"


#pragma mark •••Forward Definitions
@class ORDataPacket;
@class ORTimeRate;
@class ORTestSuit;
@class ORCommandList;
@class ORRateGroup;

#define kNumIpeV4FLTTests 5
#define kIpeV4FLTBufferSizeLongs 1024
#define kIpeV4FLTBufferSizeShorts 1024/2

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
 * The interface to the graphical configuration dialog is implemented in ORIpeV4FLTController.
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
@interface ORIpeV4FLTModel : ORIpeCard <ORDataTaker,ORHWWizard,ORHWRamping,ORAdcInfoProviding>
{
    // Hardware configuration
    int				fltRunMode;		//!< Run modes: 0=standby, 1=standard, 2=histogram, 3=test
    NSMutableArray* thresholds;     //!< Array to keep the threshold of all 24 channel
    NSMutableArray* gains;			//!< Aarry to keep the gains
    uint32_t	triggerEnabledMask;	//!< mask to keep the activated channel for the trigger
	uint32_t	hitRateEnabledMask;	//!< mask to store the activated trigger rate measurement
    uint32_t	dataId;         //!< Id used to identify energy data set (run mode)
	uint32_t	waveFormId;		//!< Id used to identify energy+trace data set (debug mode)
	uint32_t	hitRateId;
	uint32_t	histogramId;
	unsigned short	hitRateLength;		//!< Sampling time of the hitrate measurement (1..32 seconds)
	float			hitRate[kNumV4FLTChannels];	//!< Actual value of the trigger rate measurement
	uint32_t	hitRateOverFlow[kNumV4FLTChannels];	//!< Overflow of hardware trigger rate register
	float			hitRateTotal;	//!< Sum trigger rate of all channels 
	
	BOOL			firstTime;		//!< Event loop: Flag to identify the first readout loop for initialization purpose
	
	ORTimeRate*		totalRate;
    int				analogOffset;
	uint32_t   statisticOffset; //!< Offset guess used with by the hardware statistical evaluation
	uint32_t   statisticN;		 //!< Number of samples used for statistical evaluation
	uint32_t   eventMask;		 //!<Bits set for last channels hit.
	
	//testing
	NSMutableArray* testStatusArray;
	NSMutableArray* testEnabledArray;
	BOOL testsRunning;
	ORTestSuit* testSuit;
	int savedMode;
	int savedLed;
	BOOL usingPBusSimulation;
    BOOL ledOff;
    uint32_t interruptMask;
	    
	// Register information (low level tab)
    unsigned short  selectedRegIndex;
    uint32_t   writeValue;
    uint32_t   selectedChannelValue;
    // fields for event readout
    int fifoBehaviour;
    uint32_t postTriggerTime;
    int gapLength;
    int filterLength;  //for ORKatrinV4FLTModel we use filterShapingLength from 2011-04/Orca:svnrev5050 on -tb- 
    BOOL storeDataInRam;
    BOOL runBoxCarFilter;
    BOOL readWaveforms;
    int runMode;        //!< This is the daqRunMode (not the fltRunMode on the hardware).
    
    // fields for histogram readout
    uint32_t histRecTime;  //!<the histogram refresh time
    uint32_t histMeasTime; //!<the per-cycle second counter
    uint32_t histNofMeas;  //!<number of histo measurement cycles (0..63)
    uint32_t histEMin;     //!< the energy offset of the histogram
    uint32_t histEBin;     //!<the bin size setting (histBinWidth = 2^histEBin)
    int histEMax;
    int histMode;
    int histClrMode;
    uint32_t histFirstEntry;
    uint32_t histLastEntry;
    int histPageAB;
	
	BOOL noiseFloorRunning;
	int noiseFloorState;
	int noiseFloorOffset;
    int targetRate;
	int32_t noiseFloorLow[kNumV4FLTChannels];
	int32_t noiseFloorHigh[kNumV4FLTChannels];
	int32_t noiseFloorTestValue[kNumV4FLTChannels];
	BOOL oldEnabled[kNumV4FLTChannels];
	int32_t oldThreshold[kNumV4FLTChannels];
	int32_t newThreshold[kNumV4FLTChannels];
	
	uint32_t eventCount[kNumV4FLTChannels];
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (short) getNumberRegisters;

#pragma mark •••Accessors
- (int) targetRate;
- (void) setTargetRate:(int)aTargetRate;
- (int) histEMax;
- (void) setHistEMax:(int)aHistMaxEnergy;
- (int) histPageAB;
- (void) setHistPageAB:(int)aHistPageAB;
- (int) runMode;
- (void) setRunMode:(int)aRunMode;
- (void) setToDefaults;
- (BOOL) runBoxCarFilter;
- (void) setRunBoxCarFilter:(BOOL)aRunBoxCarFilter;
- (BOOL) storeDataInRam;
- (void) setStoreDataInRam:(BOOL)aStoreDataInRam;
- (int) filterLength;
- (void) setFilterLength:(int)aFilterLength;
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
- (int) noiseFloorOffset;
- (void) setNoiseFloorOffset:(int)aNoiseFloorOffset;
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

- (uint32_t) dataId;
- (void) setDataId: (uint32_t)aDataId;
- (uint32_t) waveFormId;
- (void) setWaveFormId: (uint32_t) aWaveFormId;
- (uint32_t) hitRateId;
- (void) setHitRateId: (uint32_t)aHitRateId;
- (uint32_t) histogramId;
- (void) setHistogramId: (uint32_t)aHistogramId;

- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;

- (NSMutableArray*) gains;
- (NSMutableArray*) thresholds;
- (uint32_t) triggerEnabledMask;
- (void) setTriggerEnabledMask:(uint32_t)aMask;
- (void) setGains:(NSMutableArray*)aGains;
- (void) setThresholds:(NSMutableArray*)aThresholds;
- (void) disableAllTriggers;

- (BOOL) hitRateEnabled:(unsigned short) aChan;
- (void) setHitRateEnabled:(unsigned short) aChan withValue:(BOOL) aState;

- (uint32_t)threshold:(unsigned short) aChan;
- (unsigned short)gain:(unsigned short) aChan;
- (BOOL) triggerEnabled:(unsigned short) aChan;
- (void) setThreshold:(unsigned short) aChan withValue:(uint32_t) aThreshold;
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

- (NSString*) getRegisterName: (short) anIndex;
- (uint32_t) getAddressOffset: (short) anIndex;
- (short) getAccessType: (short) anIndex;

- (unsigned short) selectedRegIndex;
- (void) setSelectedRegIndex:(unsigned short) anIndex;
- (uint32_t) writeValue;
- (void) setWriteValue:(uint32_t) aValue;
- (unsigned short) selectedChannelValue;
- (void) setSelectedChannelValue:(unsigned short) aValue;
- (int) restrictIntValue:(int)aValue min:(int)aMinValue max:(int)aMaxValue;
- (float) restrictFloatValue:(int)aValue min:(float)aMinValue max:(float)aMaxValue;


#pragma mark •••HW Access
//all can raise exceptions
- (uint32_t) regAddress:(short)aReg channel:(int)aChannel;
- (uint32_t) regAddress:(short)aReg;
- (uint32_t) adcMemoryChannel:(short)aChannel page:(int)aPage;
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

- (void) loadThresholdsAndGains;
- (void) initBoard;
- (void) writeHitRateMask;
- (void) writeInterruptMask;
- (uint32_t) hitRateEnabledMask;
- (void) setHitRateEnabledMask:(uint32_t)aMask;
- (void) readHitRates;
- (void) readHistogrammingStatus;
- (void) writeTestPattern:(uint32_t*)mask length:(int)len;
- (void) rewindTestPattern;
- (void) writeNextPattern:(uint32_t)aValue;
- (uint32_t) readStatus;
- (uint32_t) readControl;
- (uint32_t) readHitRateMask;
- (void) writeControl;
- (void) printStatusReg;
- (void) printPStatusRegs;
- (void) printVersions;
- (void) printValueTable;
- (void) printEventFIFOs;
- (void) writeHistogramControl;

/** Print result of hardware statistics for all channels */
- (void) printStatistics; // ak, 7.10.07
- (void) writeThreshold:(int)i value:(unsigned int)aValue;
- (unsigned int) readThreshold:(int)i;
- (void) writeGain:(int)i value:(unsigned short)aValue;
- (unsigned short) readGain:(int)i;
- (void) writeTriggerControl;
- (BOOL) partOfEvent:(short)chan;
- (uint32_t) eventMask;
- (void) eventMask:(uint32_t)aMask;
- (NSString*) boardTypeName:(int)aType;
- (NSString*) fifoStatusString:(int)aType;

/** Enable the statistic evaluation of sum and sum square of the 
 * ADC signals in all channels.  */
- (void) enableStatistics; // ak, 7.10.07

/** Get statistics of a single channel */
- (void) getStatistics:(int)aChannel mean:(double *)aMean  var:(double *)aVar; // ak, 7.10.07

- (uint32_t) readMemoryChan:(int)chan page:(int)aPage;
- (void) readMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer;
- (void) clear:(int)aChan page:(int)aPage value:(unsigned short)aValue;

- (uint32_t) eventCount:(int)aChannel;
- (void)		  clearEventCounts;
- (BOOL) bumpRateFromDecodeStage:(short)channel;

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


- (void) testReadHisto;

@end

@interface ORIpeV4FLTModel (tests)
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

extern NSString* ORIpeV4FLTModelTargetRateChanged;
extern NSString* ORIpeV4FLTModelHistMaxEnergyChanged;
extern NSString* ORIpeV4FLTModelHistPageABChanged;
extern NSString* ORIpeV4FLTModelHistLastEntryChanged;
extern NSString* ORIpeV4FLTModelHistFirstEntryChanged;
extern NSString* ORIpeV4FLTModelHistClrModeChanged;
extern NSString* ORIpeV4FLTModelHistModeChanged;
extern NSString* ORIpeV4FLTModelHistEBinChanged;
extern NSString* ORIpeV4FLTModelHistEMinChanged;
extern NSString* ORIpeV4FLTModelRunModeChanged;
extern NSString* ORIpeV4FLTModelRunBoxCarFilterChanged;
extern NSString* ORIpeV4FLTModelStoreDataInRamChanged;
extern NSString* ORIpeV4FLTModelFilterLengthChanged;
extern NSString* ORIpeV4FLTModelGapLengthChanged;
extern NSString* ORIpeV4FLTModelHistNofMeasChanged;
extern NSString* ORIpeV4FLTModelHistMeasTimeChanged;
extern NSString* ORIpeV4FLTModelHistRecTimeChanged;
extern NSString* ORIpeV4FLTModelPostTriggerTimeChanged;
extern NSString* ORIpeV4FLTModelFifoBehaviourChanged;
extern NSString* ORIpeV4FLTModelAnalogOffsetChanged;
extern NSString* ORIpeV4FLTModelLedOffChanged;
extern NSString* ORIpeV4FLTModelInterruptMaskChanged;
extern NSString* ORIpeV4FLTModelTestsRunningChanged;
extern NSString* ORIpeV4FLTModelTestEnabledArrayChanged;
extern NSString* ORIpeV4FLTModelTestStatusArrayChanged;
extern NSString* ORIpeV4FLTModelHitRateChanged;
extern NSString* ORIpeV4FLTModelHitRateLengthChanged;
extern NSString* ORIpeV4FLTModelHitRateEnabledMaskChanged;
extern NSString* ORIpeV4FLTModelTriggerEnabledMaskChanged;
extern NSString* ORIpeV4FLTModelGainChanged;
extern NSString* ORIpeV4FLTModelThresholdChanged;
extern NSString* ORIpeV4FLTChan;
extern NSString* ORIpeV4FLTModelGainsChanged;
extern NSString* ORIpeV4FLTModelThresholdsChanged;
extern NSString* ORIpeV4FLTModelModeChanged;
extern NSString* ORIpeV4FLTSettingsLock;
extern NSString* ORIpeV4FLTModelEventMaskChanged;
extern NSString* ORIpeV4FLTNoiseFloorChanged;
extern NSString* ORIpeV4FLTNoiseFloorOffsetChanged;

extern NSString* ORIpeSLTModelName;

extern NSString* ORIpeV4FLTSelectedRegIndexChanged;
extern NSString* ORIpeV4FLTWriteValueChanged;
extern NSString* ORIpeV4FLTSelectedChannelValueChanged;
