//
//  ORIpeFLTModel.h
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


#pragma mark ¥¥¥Imported Files
#import "ORIpeCard.h"
#import "ORIpeFireWireCard.h"
#import "ORHWWizard.h"
#import "ORDataTaker.h"
#import "ORIpeFLTDefs.h"
#import "ORAdcInfoProviding.h"

@class ORFireWireInterface;

#pragma mark ¥¥¥Forward Definitions
@class ORDataPacket;
@class ORTimeRate;
@class ORFireWireInterface;
@class ORTestSuit;

#define kNumIpeFLTTests 5
#define kIpeFLTBufferSizeLongs 1024
#define kIpeFLTBufferSizeShorts 1024/2

/** Access to the first level trigger board of the IPE-DAQ electronics.
  * The board contains ADCs for 22 channels and digital logic (FPGA) for 
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
  * The interface to the graphical configuration dialog is implemented in ORIpeFLTController.
  *
  * The Flt will produce three types of data objects depending on the run mode:
  *   - events containing timestamp and energy
  *   - events with an additional adc data trace of up to 6.5ms length
  *   - threshold and hitrate pairs from the threshold scan.   
  * 
  * @section readout Readout
  * The class implements two types of readout loops: Event by event and a periodic mode.
  * The eventswise readout is used in run and debug mode. For every event the time stamp
  * and a hardware id are stored. 
  *
  */ 
@interface ORIpeFLTModel : ORIpeCard <ORDataTaker,ORHWWizard,ORHWRamping,ORAdcInfoProviding>
{
    // Hardware configuration
    int				fltRunMode;		//!< Run modes: 0 = run, 1=test
    NSMutableArray* thresholds;     //!< Array to keep the threshold of all 22 channel
    NSMutableArray* gains;			//!< Aarry to keep the gains
    unsigned long	dataId;         //!< Id used to identify energy data set (run mode)
	unsigned long	waveFormId;		//!< Id used to identify energy+trace data set (debug mode)
    NSMutableArray* triggersEnabled;	//!< Array to keep the activated channel for the trigger
	NSMutableArray* hitRatesEnabled;	//!< Array to store the activated trigger rate measurement
    unsigned short	hitRateLength;		//!< Sampling time of the hitrate measurement (1..32 seconds)
	float			hitRate[kNumFLTChannels];	//!< Actual value of the trigger rate measurement
	BOOL			hitRateOverFlow[kNumFLTChannels];	//!< Overflow of hardware trigger rate register
	float			hitRateTotal;	//!< Sum trigger rate of all channels 
	unsigned short  readoutPages;	//!< Number of pages to read in debug mode

	BOOL			firstTime;		//!< Event loop: Flag to identify the first readout loop for initialization purpose
	
	ORTimeRate*		totalRate;
    int				thresholdOffset;
	unsigned long   statisticOffset; //!< Offset guess used with by the hardware statistical evaluation
	unsigned long   statisticN;		//! Number of samples used for statistical evaluation
	unsigned long   eventMask;		//!Bits set for last channels hit.
	unsigned long   coinTime;
	unsigned long   integrationTime;
	
	//testing
	NSMutableArray* testStatusArray;
	NSMutableArray* testEnabledArray;
	BOOL testsRunning;
	ORTestSuit* testSuit;
    int startChan;
    int endChan;
    int iterations;
    int page;
	int savedMode;
	int savedLed;
	BOOL usingPBusSimulation;
    BOOL ledOff;
    unsigned long interruptMask;
	unsigned long pageSize; //< Size of the readout pages - defined in slt dialog
    unsigned long dataMask;

	//-----------------------------------------
	//place to cache some values so they don't have to be calculated every time thru the run loop.
	//not so important in this object because of length of time it takes to readout waveforms,
	//but we'll do it anyway.
	//Caution, these variables are only valid when a run is in progress.
	unsigned long	statusAddress;
	unsigned long	memoryAddress;
	unsigned long	locationWord;
	/** Reference to the Slt board for hardware access */
	ORIpeFireWireCard* fireWireCard; 
	//-----------------------------------------
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ¥¥¥Accessors
- (unsigned long) dataMask;
- (void) setDataMask:(unsigned long)aDataMask;
- (int) thresholdOffset;
- (void) setThresholdOffset:(int)aThresholdOffset;
- (BOOL) ledOff;
- (void) setLedOff:(BOOL)aledOff;

- (unsigned long) coinTime;
- (void) setCoinTime:(unsigned long)aValue;
- (unsigned long) integrationTime;
- (void) setIntegrationTime:(unsigned long)aValue;


- (unsigned long) interruptMask;
- (void) setInterruptMask:(unsigned long)aInterruptMask;
- (int) page;
- (void) setPage:(int)aPage;
- (int) iterations;
- (void) setIterations:(int)aIterations;
- (int) endChan;
- (void) setEndChan:(int)aEndChan;
- (int) startChan;
- (void) setStartChan:(int)aStartChan;
- (unsigned short) hitRateLength;
- (void) setHitRateLength:(unsigned short)aHitRateLength;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (unsigned long) waveFormId;
- (void) setWaveFormId: (unsigned long) aWaveFormId;

- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;

- (NSMutableArray*) gains;
- (NSMutableArray*) thresholds;
- (NSMutableArray*) triggersEnabled;
- (void) setGains:(NSMutableArray*)aGains;
- (void) setThresholds:(NSMutableArray*)aThresholds;
- (void) setTriggersEnabled:(NSMutableArray*)aThresholds;
- (void) disableAllTriggers;

- (BOOL) hitRateEnabled:(unsigned short) aChan;
- (void) setHitRateEnabled:(unsigned short) aChan withValue:(BOOL) aState;

- (unsigned short)threshold:(unsigned short) aChan;
- (unsigned short)gain:(unsigned short) aChan;
- (BOOL) triggerEnabled:(unsigned short) aChan;
- (void) setThreshold:(unsigned short) aChan withValue:(unsigned short) aThreshold;
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


- (unsigned short) readoutPages; // ak, 2.7.07
- (void) setReadoutPages:(unsigned short)aReadoutPage; // ak, 2.7.07


#pragma mark ¥¥¥HW Access
//all can raise exceptions
- (unsigned long) regAddress:(int)aReg channel:(int)aChannel;
- (unsigned long) regAddress:(int)aReg;
- (unsigned long) adcMemoryChannel:(int)aChannel page:(int)aPage;
- (unsigned long) readReg:(int)aReg;
- (unsigned long) readReg:(int)aReg channel:(int)aChannel;
- (void) writeReg:(int)aReg value:(unsigned long)aValue;
- (void) writeReg:(int)aReg channel:(int)aChannel value:(unsigned long)aValue;

- (void)	checkPresence;
- (int)		readVersion;
- (int)		readCardId;
- (int)		readMode;

- (void) loadThresholdsAndGains;
- (void) initBoard;
- (BOOL) isInRunMode;
- (BOOL) isInTestMode;
- (void) writeHitRateMask;
- (NSMutableArray*) hitRatesEnabled;
- (void) setHitRatesEnabled:(NSMutableArray*)anArray;
- (void) readHitRates;
- (void) writeTestPattern:(unsigned long*)mask length:(int)len;
- (void) rewindTestPattern;
- (void) writeNextPattern:(unsigned long)aValue;
- (unsigned long) readControlStatus;
- (void) writeControlStatus;
- (void) writePeriphStatus;
- (void) printStatusReg;
- (void) printPeriphStatusReg;
- (void) printPixelRegs;
/** Print result of hardware statistics for all channels */
- (void) printStatistics; // ak, 7.10.07
- (void) writeThreshold:(int)i value:(unsigned short)aValue;
- (unsigned short) readThreshold:(int)i;
- (void) writeGain:(int)i value:(unsigned short)aValue;
- (unsigned short) readGain:(int)i;
- (void) writeTriggerControl;
- (BOOL) partOfEvent:(short)chan;
- (unsigned long) eventMask;
- (void) eventMask:(unsigned long)aMask;

/** Disable the trigger algorithm in all channels. In debug mode the ADC Traces are
  * still recorded while the recording is not stopped by any steps in the signal. 
  *
  * @todo Join writeTriggerControl and disableTrigger using a argument list */
- (void) disableTrigger; // ak, 2.7.07

/** Enable the statistic evaluation of sum and sum square of the 
  * ADC signals in all channels.  */
- (void) enableStatistics; // ak, 7.10.07

/** Get statistics of a single channel */
- (void) getStatistics:(int)aChannel mean:(double *)aMean  var:(double *)aVar; // ak, 7.10.07

- (unsigned short) readTriggerControl:(int)fpga;
- (unsigned long) readMemoryChan:(int)chan page:(int)aPage;
- (void) readMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer;
- (void) clear:(int)aChan page:(int)aPage value:(unsigned short)aValue;

#pragma mark ¥¥¥Calibration
- (void) autoCalibrate;
- (void) autoCalibrate:(int)theEndingOffset;
- (void) loadAutoCalbrateTestPattern;

#pragma mark ¥¥¥Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (NSDictionary*) dataRecordDescription;
- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark ¥¥¥Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark ¥¥¥HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

@end

@interface ORIpeFLTModel (tests)
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

extern NSString* ORIpeFLTModelDataMaskChanged;
extern NSString* ORIpeFLTModelThresholdOffsetChanged;
extern NSString* ORIpeFLTModelLedOffChanged;
extern NSString* ORIpeFLTModelInterruptMaskChanged;
extern NSString* ORIpeFLTModelTestParamChanged;
extern NSString* ORIpeFLTModelTestsRunningChanged;
extern NSString* ORIpeFLTModelTestEnabledArrayChanged;
extern NSString* ORIpeFLTModelTestStatusArrayChanged;
extern NSString* ORIpeFLTModelHitRateChanged;
extern NSString* ORIpeFLTModelHitRateLengthChanged;
extern NSString* ORIpeFLTModelHitRatesArrayChanged;
extern NSString* ORIpeFLTModelHitRateEnabledChanged;
extern NSString* ORIpeFLTModelTriggerEnabledChanged;
extern NSString* ORIpeFLTModelTriggersEnabledChanged;
extern NSString* ORIpeFLTModelGainChanged;
extern NSString* ORIpeFLTModelThresholdChanged;
extern NSString* ORIpeFLTChan;
extern NSString* ORIpeFLTModelGainsChanged;
extern NSString* ORIpeFLTModelThresholdsChanged;
extern NSString* ORIpeFLTModelModeChanged;
extern NSString* ORIpeFLTSettingsLock;
extern NSString* ORIpeFLTModelEventMaskChanged;
extern NSString* ORIpeFLTModelIntegrationTimeChanged;
extern NSString* ORIpeFLTModelCoinTimeChanged;

extern NSString* ORIpeFLTModelReadoutPagesChanged;
extern NSString* ORIpeSLTModelName;
