//
//  ORAugerFLTModel.h
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
#import "ORAugerCard.h"
#import "ORAugerFireWireCard.h"
#import "ORHWWizard.h"
#import "ORDataTaker.h"
#import "ORAugerFLTDefs.h"
#import "ORAdcInfoProviding.h"

@class ORFireWireInterface;

#pragma mark ¥¥¥Forward Definitions
@class ORDataPacket;
@class ORTimeRate;
@class ORFireWireInterface;
@class ORTestSuit;

#define kNumAugerFLTTests 7
#define kAugerFLTBufferSizeLongs 1024
#define kAugerFLTBufferSizeShorts 1024/2

/** Access to the first level trigger board of the IPE-DAQ electronics.
  * The board contains ADCs for 22 channels and digital logic (FPGA) for 
  * for implementation experiment specific trigger logic. 
  * 
  * @section hwaccess Access to hardware  
  * There can be only a single adapter connected to the firewire bus. 
  * In the Auger implementation this is the Slt board. The Flt has to refer
  * this interface. 
  *
  * Every time a run is started the stored configuratiation is written to the
  * hardware before recording the data.
  *
  * The interface to the graphical configuration dialog is implemented in ORAugerFLTController.
  *
  * The Flt will produce three types of data objects depending on the run mode:
  *   - events containing timestamp and energy
  *   - events with an additional adc data trace of up to 6.5ms length
  *   - threshold and hitrate pairs from the threshold scan.   
  * 
  * @section readout Readout
  * The class implements two types of readout loops: Event by event and a periodic mode.
  * The eventswise readout is used in run and debug mode. For every event the time stamp
  * as well as energy, channel map and a hardware id are stored. The hardware id is 
  * 10bit event is that is used to detect missing events in the readout process.
  * In run mode the hardware stores all events in a events buffer for 512 events.
  * The debug mode is not intended for loss less event recording. After every event 
  * the recording has to be restarted. The reset time stamp keeps the time when the 
  * For the threshold scan in measure mode the hitrates are periodically read. After each 
  * hitrate recording the threhold is incremented until the hitrate reaches zero.
  * From the scan data it is possible to calculate the energy distribution of the 
  * source signal as well.
  *
  */ 
@interface ORAugerFLTModel : ORAugerCard <ORDataTaker,ORHWWizard,ORHWRamping,ORAdcInfoProviding>
{
    // Hardware configuration
    int				fltRunMode;		//!< Run modes: 0 = debug, 1 = run, 2 = measure, 3=test
    NSMutableArray* thresholds;     //!< Array to keep the threshold of all 22 channel
    NSMutableArray* gains;			//!< Aarry to keep the 
    unsigned long	dataId;         //!< Id used to identify energy data set (run mode)
	unsigned long	waveFormId;		//!< Id used to identify energy+trace data set (debug mode)
	unsigned long   hitRateId;		//!< Id used to identify the data from the threshold scan (measure mode)
    NSMutableArray* triggersEnabled;	//!< Array to keep the activated channel for the trigger
    NSMutableArray* shapingTimes;		//!< Length of the triangular filter
	NSMutableArray* hitRatesEnabled;	//!< Array to store the activated trigger rate measurement
    unsigned short	hitRateLength;		//!< Sampling time of the hitrate measurement (1..32 seconds)
	float			hitRate[kNumFLTChannels];	//!< Actual value of the trigger rate measurement
	BOOL			hitRateOverFlow[kNumFLTChannels];	//!< Overflow of hardware trigger rate register
	float			hitRateTotal;	//!< Sum trigger rate of all channels 
	unsigned short  readoutPages;	//!< Number of pages to read in debug mode
    int             energyShift[kNumFLTChannels];    //!< Shift to get constant energy values independend from the shaping time 
	
	// Parameters for event triggered readout mode
    BOOL			broadcastTime;
	BOOL			firstTime;		//!< Event loop: Flag to identify the first readout loop for initialization purpose
	unsigned long   nextEventPage;	//!< Event loop: Address of the last event in the hardware page buffer
	unsigned long   lastEventId;	//!< Event  loop: Id of the last event. Used to search for missing events in run mode
	int				generateTrigger;	//!< Event  loop: Flag to generate a software trigger in the next readout loop cycle
	unsigned long	nLoops;			//!< Event  loop: Number of cycles
	unsigned long	nEvents;		//!< Event loop: Number of recorded events
	unsigned long	nSkippedEvents;	//!< Event loop: Number of skipped events
	unsigned long	nMissingEvents;	//!< Event  loop: 
	BOOL            overflowDetected;	//!< Event  loop: Flag to indicate an event buffer overflow in the current run
	float           nBuffer;		//!< Event loop: Number of pages in the hardware event buffer 
    unsigned long   resetSec;		//!< Event loop: Time stamp of the last reset..  
	unsigned long   resetSubSec;	//!< Event loop: Time stmp of the last reset
	bool			useResetTimestamp; //!< Event loop: Flag to indicate that the current hardwarde version supports reset time stamps

	// Parameters for periodic readout mode
	unsigned long	lastSec;		//!< Periodic readout: Buffer for the last second in preriodically readout mode
	unsigned long	activeChMap;	//!< Periodic readout: List of active channels 
	unsigned long	actualThreshold[22];//!< Periodic readout: Actually threshold during threshold scan
	unsigned long	savedThreshold[22];	//!< Periodic readout: Original threshold saved from current configuration 
	unsigned long	lastThreshold[22];	//!< Periodic readout: Last threshold during threshold scan
	int				stepThreshold[22];	//!< Periodic readout: Threshold increment for scan (1, 10, 100, 1000)
	unsigned long	maxHitrate[22];		//!< Periodic readout: Maxmal hitrate at the beginning of the scan
	unsigned long	lastHitrate[22];	//!< Periodic readout: Trigger rate of the last sample
	unsigned long	nNoChanges[22];		//!< Periodic readout: Number of samples with no changes in the hitrate. Used to control the threshol increments.
	
	
	id				sltmodel;
	
	ORTimeRate*		totalRate;

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
    NSMutableArray* testPatterns;
    unsigned short tMode;
    int testPatternCount;
    BOOL checkWaveFormEnabled;
	
	//place to cache some values so they don't have to be calculated every time thru the run loop.
	unsigned long	statusAddress;
	unsigned long	triggerMemAddress;
	unsigned long	memoryAddress;
	unsigned long	locationWord;
	BOOL			usingPBusSimulation;
	/** Reference to the Slt board for hardware access */
	ORAugerFireWireCard* fireWireCard; 
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ¥¥¥Accessors
- (BOOL) checkWaveFormEnabled;
- (void) setCheckWaveFormEnabled:(BOOL)aCheckWaveFormEnabled;
- (int) testPatternCount;
- (void) setTestPatternCount:(int)aTestPatternCount;
- (unsigned short) tMode;
- (void) setTMode:(unsigned short)aTMode;
- (int) page;
- (void) setPage:(int)aPage;
- (int) iterations;
- (void) setIterations:(int)aIterations;
- (int) endChan;
- (void) setEndChan:(int)aEndChan;
- (int) startChan;
- (void) setStartChan:(int)aStartChan;
- (BOOL) broadcastTime;
- (void) setBroadcastTime:(BOOL)aBroadcastTime;
- (unsigned short) hitRateLength;
- (void) setHitRateLength:(unsigned short)aHitRateLength;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (unsigned long) waveFormId;
- (void) setWaveFormId: (unsigned long) aWaveFormId;
- (unsigned long) hitRateId;
- (void) setHitRateId: (unsigned long) aHitRateId;

- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;

- (NSMutableArray*) shapingTimes;
- (NSMutableArray*) gains;
- (NSMutableArray*) thresholds;
- (NSMutableArray*) triggersEnabled;
- (void) setGains:(NSMutableArray*)aGains;
- (void) setThresholds:(NSMutableArray*)aThresholds;
- (void) setTriggersEnabled:(NSMutableArray*)aThresholds;
- (void) setShapingTimes:(NSMutableArray*)aShapingTimes;

- (BOOL) hitRateEnabled:(unsigned short) aChan;
- (void) setHitRateEnabled:(unsigned short) aChan withValue:(BOOL) aState;

- (unsigned short)shapingTime:(unsigned short) group;
- (unsigned short)threshold:(unsigned short) aChan;
- (unsigned short)gain:(unsigned short) aChan;
- (BOOL) triggerEnabled:(unsigned short) aChan;
- (void) setThreshold:(unsigned short) aChan withValue:(unsigned short) aThreshold;
- (NSMutableArray*) testPatterns;
- (void) setTestPatterns:(NSMutableArray*) aPattern;
- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain;
- (void) setTriggerEnabled:(unsigned short) aChan withValue:(BOOL) aState;
- (void) setShapingTime:(unsigned short) aGroup withValue:(unsigned short)aShapingTime;

- (int) fltRunMode;
- (void) setFltRunMode:(int)aMode;
- (void) loadTime;
- (void) enableAllHitRates:(BOOL)aState;
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
- (void)	checkPresence;
- (int)		readVersion;
- (int)		readFPGAVersion:(int) fpga;
- (int)		readCardId;
- (BOOL)	readHasData;
- (BOOL)	readIsOverflow;
- (int)		readMode;
- (void)	writeMode:(int) value;
- (unsigned long)  getReadPointer;
- (unsigned long)  getWritePointer;
- (void)  reset;

/** Generate a software trigger. In order to distribute it to all Flts
  * the Slt trigger mechanism is used. */
- (void)  trigger; // ak, 3.7.07

- (void) loadThresholdsAndGains;
- (void) initBoard;
- (BOOL) isInRunMode;
- (BOOL) isInTestMode;
- (BOOL) isInDebugMode;
- (void) loadTime:(unsigned long)aTime;
- (unsigned long) readTime;
- (unsigned long) readTimeSubSec;
- (void) writeHitRateMask;
- (NSMutableArray*) hitRatesEnabled;
- (void) setHitRatesEnabled:(NSMutableArray*)anArray;
- (void) readHitRates;

- (unsigned long) readControlStatus;
- (void) writeControlStatus:(unsigned long)aValue;
- (void) printStatusReg;
- (void) writeThreshold:(int)i value:(unsigned short)aValue;
- (unsigned short) readThreshold:(int)i;
- (void) writeGain:(int)i value:(unsigned short)aValue;
- (unsigned short) readGain:(int)i;
- (void) writeTriggerControl;

/** Disable the trigger algorithm in all channels. In debug mode the ADC Traces are
  * still recorded while the recording is not stopped by any steps in the signal. 
  *
  * @todo Join writeTriggerControl and disableTrigger using a argument list */
- (void) disableTrigger; // ak, 2.7.07

- (unsigned short) readTriggerControl:(int)fpga;
- (void) writeMemoryChan:(int)chan page:(int)aPage value:(unsigned short)aValue;
- (unsigned long) readMemoryChan:(int)chan page:(int)aPage;
- (void) readMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer;
- (void) broadcast:(int)aPage dataBuffer:(unsigned short*)aDataBuffer;
- (void) clear:(int)aChan page:(int)aPage value:(unsigned short)aValue;


- (void) rewindTP;
- (void) writeTestPatterns;

/** Restart run in debug mode. The function resets the read/write pointers
  * in the hardware and the last page variable of the readout loop */
- (void) restartRun;   // ak 2.7.07

#pragma mark ¥¥¥Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (NSDictionary*) dataRecordDescription;
- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark ¥¥¥Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;

#pragma mark ¥¥¥SubSets of TakeData
- (void) takeDataMeasureMode:(ORDataPacket*)aDataPacket;
- (void) takeDataRunOrDebugMode:(ORDataPacket*) aDataPacket;

#pragma mark ¥¥¥HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

@end

@interface ORAugerFLTModel (tests)
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
- (void) patternWriteTest;
- (void) modeTest;
- (void) broadcastTest;
- (void) thresholdGainTest;
- (void) speedTest;
- (void) eventTest;
- (int) compareData:(unsigned short*) data
                     pattern:(unsigned short*) pattern
					 shift:(int) shift
					 n:(int) n;
@end

extern NSString* ORAugerFLTModelCheckWaveFormEnabledChanged;
extern NSString* ORAugerFLTModelTestPatternCountChanged;
extern NSString* ORAugerFLTModelTModeChanged;
extern NSString* ORAugerFLTModelTestParamChanged;
extern NSString* ORAugerFLTModelTestsRunningChanged;
extern NSString* ORAugerFLTModelTestEnabledArrayChanged;
extern NSString* ORAugerFLTModelTestStatusArrayChanged;
extern NSString* ORAugerFLTModelBroadcastTimeChanged;
extern NSString* ORAugerFLTModelHitRateChanged;
extern NSString* ORAugerFLTModelHitRateLengthChanged;
extern NSString* ORAugerFLTModelHitRatesArrayChanged;
extern NSString* ORAugerFLTModelHitRateEnabledChanged;
extern NSString* ORAugerFLTModelShapingTimeChanged;
extern NSString* ORAugerFLTModelTriggerEnabledChanged;
extern NSString* ORAugerFLTModelShapingTimesChanged;
extern NSString* ORAugerFLTModelTriggersEnabledChanged;
extern NSString* ORAugerFLTModelGainChanged;
extern NSString* ORAugerFLTModelThresholdChanged;
extern NSString* ORAugerFLTChan;
extern NSString* ORAugerFLTModelGainsChanged;
extern NSString* ORAugerFLTModelTestPatternsChanged;
extern NSString* ORAugerFLTModelThresholdsChanged;
extern NSString* ORAugerFLTModelModeChanged;
extern NSString* ORAugerFLTSettingsLock;

extern NSString* ORAugerFLTModelReadoutPagesChanged;
extern NSString* ORAugerSLTModelName;
