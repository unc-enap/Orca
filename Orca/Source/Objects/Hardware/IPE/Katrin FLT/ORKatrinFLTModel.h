//
//  ORKatrinFLTModel.h
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
#import "ORKatrinFLTDefs.h"
#import "ORAdcInfoProviding.h"

@class ORFireWireInterface;

#pragma mark ¥¥¥Forward Definitions
@class ORDataPacket;
@class ORTimeRate;
@class ORFireWireInterface;
@class ORTestSuit;

#define kNumKatrinFLTTests 7
#define kKatrinFLTBufferSizeLongs 1024
#define kKatrinFLTBufferSizeShorts 1024/2

/** Access to the first level trigger board of the IPE-DAQ electronics.
  * The board contains ADCs for 22 channels and digital logic (FPGA) for 
  * for implementation experiment specific trigger logic. 
  * 
  * @section hwaccess Access to hardware  
  * There can be only a single adapter connected to the firewire bus. 
  * In the Katrin implementation this is the Slt board. The Flt has to refer
  * this interface. 
  *
  * Every time a run is started the stored configuratiation is written to the
  * hardware before recording the data.
  *
  * The interface to the graphical configuration dialog is implemented in ORKatrinFLTController.
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
@interface ORKatrinFLTModel : ORIpeCard <ORDataTaker,ORHWWizard,ORHWRamping,ORAdcInfoProviding>
{
    // Hardware configuration
    int				fltRunMode;		//!< Run modes: 0 = debug, 1 = run, 2 = measure, 3=test
    int				daqRunMode;		//!< Run modes: 0 = Energy+Trace, 1 = Energy, 2 = Hitrate, 3 = Threshold Scan, 4=Test
    NSMutableArray* thresholds;     //!< Array to keep the threshold of all 22 channel
    NSMutableArray* gains;			//!< Array to keep the gains.
    unsigned long	dataId;         //!< Id used to identify energy data set (daq run mode)
	unsigned long	waveFormId;		//!< Id used to identify energy+trace data set (daq debug mode)
	unsigned long   hitRateId;		//!< Id used to identify the data from the hitrate data set (daq hitrate mode)
	unsigned long   thresholdScanId;		//!< Id used to identify the data from the threshold scan (daq measure mode)
	unsigned long   histogramId;		//!< Id used to identify the data from the hardware histogram (daq histogram mode)
	unsigned long   vetoId;		        //!< Id used to identify the data from the veto mode (daq veto mode)
    NSMutableArray* triggersEnabled;	//!< Array to keep the activated channel for the trigger
    NSMutableArray* shapingTimes;		//!< Length of the triangular filter
	NSMutableArray* hitRatesEnabled;	//!< Array to store the activated trigger rate measurement
    unsigned short	hitRateLength;		//!< Sampling time of the hitrate measurement (1..32 seconds)
	float			hitRate[kNumFLTChannels];	//!< Actual value of the trigger rate measurement
	BOOL			hitRateOverFlow[kNumFLTChannels];	//!< Overflow of hardware trigger rate register
	float			hitRateTotal;	//!< Sum trigger rate of all channels 
	unsigned short  readoutPages;	//!< Number of pages to read in debug mode
    int             energyShift[kNumFLTChannels];    //!< Shift to get constant energy values independend from the shaping time 
    int             filterGap;      //!< Value of the HW filter gap register/filter gap popup.
    int             filterGapBins;  //!< Size of the HW filter gap.
	
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
	int             overflowDetectedCounter;	//!< @see #overflowDetected; counts the  event buffer overflows
	float           nBuffer;		//!< Event loop: Number of pages in the hardware event buffer 
    unsigned long   resetSec;		//!< Event loop: Time stamp of the last reset..  
	unsigned long   resetSubSec;	//!< Event loop: Time stmp of the last reset
	bool			useResetTimestamp; //!< Event loop: Flag to indicate that the current hardwarde version supports reset time stamps

	// Parameters for periodic readout mode
	unsigned long	lastSec;		//!< Periodic readout: Buffer for the last second in periodically readout mode
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
    BOOL checkEnergyEnabled;
    
    // Parameters for hardware histogramming (stored in .Orca file) -tb- 2008-02-08
    int histoBinWidth;    //!< The bin width of the @e hardware @e histogramming bins.
    unsigned int histoMinEnergy;    //!< The minimum energy for the @e hardware @e histogramming. In GUI: Offset ...
    unsigned int histoMaxEnergy;    //!< The maximum energy for the @e hardware @e histogramming.
    unsigned int histoFirstBin;     //!< The first bin (of 1024) not equal zero.
    unsigned int histoLastBin;      //!< The last bin (of 1024) not equal zero.
    unsigned int histoRunTime;      //!< The length of the time loop (0=endless, not 0: length in sec). In GUI: RefreshTime
    unsigned int histoRecordingTime;  //!< The recording time since start of time loop (in sec).
    int histoSelfCalibrationPercent;  //!< The percentage for the histogramming self calibration.
    // Internal parameters for hardware histogramming -tb- 
    NSMutableArray* histogramData;    //!< Array of NSData objects to keep the hardware histogram.
    int histogramDataFirstBin[kNumFLTChannels];
    int histogramDataLastBin[kNumFLTChannels];
    int histogramDataRecTimeSec[kNumFLTChannels]; // obsolete 2008-07 -tb-
    int histogramDataSum[kNumFLTChannels];
    int histoStartTimeSec;   //!< Start time (sec) of the test @e hardware @e histogram.
    int histoStartTimeUSec;  //!< Start time (usec) of the test @e hardware @e histogram.
    int histoStopTimeSec;    //!< Stop time (sec) of the test @e hardware @e histogram.
    int histoStopTimeUSec;   //!< Stop time (usec) of the test @e hardware @e histogram.
    int histoLastSecStrobeSec;   //!<  time (sec) of last second strobe.
    int histoLastSecStrobeUSec;  //!<  time (usec) of last second strobe.
    int histoLastPageToggleSec;   //!<  time (sec) of last page toggle.
    int histoLastPageToggleUSec;  //!<  time (usec) of last page toggle.
    int histoPreToggleSec;             //!<  time (sec) of last pre toggle cycle.
    int histoPreToggleUSec;            //!<  time (usec) of last pre toggle cycle.
    double lastDiffTime;               //!<used for timing of histogramming
    int lastDelayTime;               //!<used for timing: number of 0.1 (0delayTime) seconds since histoStartTimeSec/USec
    int currentDelayTime;               //!<used for timing: number of 0.1 (0delayTime) seconds since histoStartTimeSec/USec
    int histoLastActivePage;         //!<  number (0/1) of last active memory page
    
    BOOL histoCalibrationIsRunning;  //!< Used for calibration run and normal run - TRUE if intentionally  running
    int  histoSelfCalibrationCounter; //!< Flag and counter for the self calibration feature.
    double histoCalibrationElapsedTime;
    unsigned int histoCalibrationChan;  //!< The currently selected channel for histogramming calibration.
    int savedDaqRunMode;  /*!< Saves the daq run mode during histogram calibration run; ==-1 means 'undefined', 
                               otherwise == kKatrinFlt_DaqHistogram_Mode etc.*/
    BOOL showHitratesDuringHistoCalibration;   //!<"Show hitrates" check mark (will not be saved in the .Orca file -tb-)
	BOOL histoClearAtStart ; //!< HW histogramming clear bit (HistStatusReg)
	BOOL histoClearAfterReadout ; //!< HW histogramming clear flag (software)
	BOOL histoStopIfNotCleared ;//!< HW histogramming mode bit (HistParamReg)
    BOOL histoStartWaitingForPageToggle;
    

    BOOL histoWaitForPageToggle;//!<internal parameter
    // Parameters for low-level register readout
    int readWriteRegisterChan;    //!< The channel/group currently selected in the low-level tab -tb-
    NSString *readWriteRegisterName; //!< The register name currently selected in the low-level tab -tb-
    
	//place to cache some values so they don't have to be calculated every time thru the run loop.
	unsigned long	statusAddress;
	unsigned long	triggerMemAddress;
	unsigned long	memoryAddress;
	unsigned long	locationWord;
	BOOL			usingPBusSimulation;
	/** Reference to the Slt board for hardware access */
	ORIpeFireWireCard* fireWireCard; 
    
    //Parameters for the post trigger time handling -tb- 2008-03-07
    int postTriggerTime;        //!< number of values read out after trigger bin (default: 511) 
    BOOL dataAquisitionStopped; //!< hardware flag
    BOOL dataAquisitionIsRestarting;//!< hardware flag

    //Parameters for the FPGA configuration: version, revision, application ID ("features")
    unsigned long versionRegister;//!< The raw 32-bit version register content
    BOOL versionRegisterIsUptodate;
    BOOL stdFeatureIsAvailable;
    BOOL vetoFeatureIsAvailable;
    BOOL histoFeatureIsAvailable;
    BOOL filterGapFeatureIsAvailable;

}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) serviceChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;

- (void) 	setSlot:(int)aSlot;

#pragma mark ¥¥¥Accessors
- (void) showVersionRevision;
- (unsigned long) versionRegister;//!< The raw 32-bit version register content
- (void) setVersionRegister:(unsigned long)aValue;
- (int) versionRegApplicationID;
- (int) versionRegHWVersionHex;
/** Since version 3 we have the version register. 
  * (0 means: no hardware detected, 2 means: probably old version detected).
  * @see versionRegister
  */ //-tb-
- (int) versionRegHWVersion;
- (int) versionRegHWSubVersion;
- (int) versionRegCFPGAVersion;
- (int) versionRegFPGA6Version;
- (BOOL) stdFeatureIsAvailable;
- (BOOL) vetoFeatureIsAvailable;
- (BOOL) histoFeatureIsAvailable;
- (BOOL) filterGapFeatureIsAvailable;
- (void) setStdFeatureIsAvailable:(BOOL)aBool;
- (void) setVetoFeatureIsAvailable:(BOOL)aBool;
- (void) setHistoFeatureIsAvailable:(BOOL)aBool;
- (void) setFilterGapFeatureIsAvailable:(BOOL)aBool;
- (BOOL) checkWaveFormEnabled;
- (void) setCheckWaveFormEnabled:(BOOL)aCheckWaveFormEnabled;
- (BOOL) checkEnergyEnabled;
- (void) setCheckEnergyEnabled:(BOOL)aCheck;
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
- (unsigned long) thresholdScanId;
- (void) setThresholdScanId: (unsigned long) athresholdScanId;
- (unsigned long) histogramId;
- (void) setHistogramId: (unsigned long) aValue;
- (unsigned long) vetoId;
- (void) setVetoId: (unsigned long) aValue;

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
- (int) filterGap;
- (void) setFilterGap:(int) aValue;
- (int) filterGapBins;
- (void) setFilterGapBins:(int) aValue;
- (int) updateFilterGapBins;

- (int) fltRunMode;
- (void) setFltRunMode:(int)aMode;
- (int) daqRunMode;
- (void) setDaqRunMode:(int)aMode;
- (int) postTriggerTime;// -tb- 2008-03-07
- (void) setPostTriggerTime:(int)aValue;


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
- (void) writePostTriggerTime:(unsigned int)aValue; // -tb-  
- (void) readPostTriggerTime;

- (void) readFilterGap;

- (void)	checkPresence;
- (int)		readVersion;
- (unsigned long)		readVersionRevision;
- (void)	initVersionRevision;
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

#pragma mark ¥¥¥¥Hardware Histogramming
#pragma mark ¥¥¥Hardware Histogramming Accessors
//hardware histogramming -tb- 2008-02-08
- (int) histoChanToGroupMap:(int)aChannel;
- (int) histoBinWidth;
- (void) setHistoBinWidth:(int)aHistoBinWidth;
- (unsigned int) histoMinEnergy;
- (void) setHistoMinEnergy:(unsigned int)aValue;
- (unsigned int) histoMaxEnergy;
- (void) setHistoMaxEnergy:(unsigned int)aValue;
- (void) recalcHistoMaxEnergy;
- (unsigned int) histoFirstBin;
- (void) setHistoFirstBin:(unsigned int)aValue;
- (unsigned int) histoLastBin;
- (void) setHistoLastBin:(unsigned int)aValue;
- (unsigned int) histoRunTime;
- (void) setHistoRunTime:(unsigned int)aValue;
- (unsigned int) histoRecordingTime;
- (void) setHistoRecordingTime:(unsigned int)aValue;
- (int) histoSelfCalibrationPercent;
- (void) setHistoSelfCalibrationPercent:(int)aValue;
- (BOOL)   histoCalibrationIsRunning;
- (void)   setHistoCalibrationIsRunning: (BOOL)aValue;
- (double) histoCalibrationElapsedTime;
- (void)   setHistoCalibrationElapsedTime: (double)aTime;
- (unsigned int) histoCalibrationChan;
- (void) setHistoCalibrationChan:(unsigned int)aValue;
- (BOOL) showHitratesDuringHistoCalibration;
- (void) setShowHitratesDuringHistoCalibration:(BOOL)aValue;
- (BOOL) histoClearAtStart;
- (void) setHistoClearAtStart:(BOOL)aValue;
- (BOOL) histoClearAfterReadout;
- (void) setHistoClearAfterReadout:(BOOL)aValue;
- (BOOL) histoStopIfNotCleared;
- (void) setHistoStopIfNotCleared:(BOOL)aValue;
- (void) histoSetStandard;
//
- (NSMutableArray*) histogramData;
- (unsigned int) getHistogramData: (int)index forChan:(int)aChan;
- (void) setHistogramData: (int)index forChan:(int)aChan value:(int) aValue;
- (void) addHistogramData: (int)index forChan:(int)aChan value:(int) aValue;
- (void) clearHistogramDataForChan:(int)aChan;
#pragma mark ¥¥¥Hardware Histogramming HW Access
- (unsigned long) readEMin;
- (unsigned long) readEMinForChan:(int)aChan;
- (void) writeEMin:(int)EMin;
- (void) writeEMin:(int)EMin forChan:(int)aChan;
- (unsigned long) readEMax;
- (unsigned long) readEMaxForChan:(int)aChan;
- (void) writeEMax:(int)EMax;
- (void) writeEMax:(int)EMax forChan:(int)aChan;
- (unsigned long) readTRun;
- (unsigned long) readTRunForChan:(int)aChan; 
- (void) writeTRun:(int)TRun;
- (void) writeTRun:(int)TRun  forChan:(int)aChan; 
- (void) writeStartHistogram:(unsigned int)aHistoBinWidth;
- (void) writeStartHistogram:(unsigned int)aHistoBinWidth  forChan:(int)aChan;
- (void) writeStopHistogram;
- (void) writeStopHistogramForChan:(int)aChan;
//new since histogramming ver. 3.x -tb- >>>>>>>>
- (void) writeStartHistogramForChan:(int)aChan withClear:(BOOL)clear;
- (void) writeHistogramSettingsForChan:(int)aChan mode:(unsigned int)aMode binWidth:(unsigned int)aHistoBinWidth;
//new since histogramming ver. 3.x -tb- <<<<<<<<
- (unsigned long) readTRec;
- (unsigned long) readTRecForChan:(int)aChan; 
- (unsigned long) readFirstBinForChan:(int)aChan;
- (unsigned long) readLastBinForChan:(int)aPixel;

- (int) getHistoBinOfEnergy:(double) energy withOffsetEMin:(int) emin binSize:(int) bs;
- (int) getHistoEnergyOfBin:(int) bin  withOffsetEMin:(int) emin binSize:(int) bs;
- (void) histoSimulateReadHistogramDataForChan:(int)aChan;
- (void) startCalibrationHistogramOfChan:(int)aChan;
- (void) checkCalibrationHistogram;
- (void) stopCalibrationHistogram;
- (void) histoRunSelfCalibration;
- (void) histoAnalyseSelfCalibrationRun;
- (unsigned int) histogramDataAdress:(int)aBin forChan:(int)aChan;
- (void) readHistogramDataForChan:(unsigned int)aPixel;
- (unsigned int) readHistogramDataOfPixel:(unsigned int)aPixel atBin:(unsigned int)aBin ;
- (void) readCurrentStatusOfPixel:(unsigned int)aPixel;
- (int)  readCurrentHistogramPageNum;
- (void) clearCurrentHistogramPageForChan:(unsigned int)aChan;
- (BOOL) histogrammingIsActiveForChan:(unsigned int)aChan;
- (unsigned long) readHistogramControlRegisterOfPixel:(unsigned int)aPixel;//TODO: rename to ...ForChan -tb-
- (void) writeHistogramControlRegisterForSlot:(int)aSlot chan:(int)aChan value:(unsigned long)aValue;
- (void) writeHistogramControlRegisterOfPixel:(unsigned int)aPixel value:(unsigned long)aValue;
- (unsigned long) readHistogramSettingsRegisterOfPixel:(unsigned int)aPixel;
- (void) writeHistogramSettingsRegisterOfPixel:(unsigned int)aPixel value:(unsigned long)aValue;

- (void) setHistoLastPageToggleSec:(int) sec usec:(int) usec;
- (void) setHistoStartWaitingForPageToggle:(BOOL) aValue;
- (void) setHistoLastActivePage:(int) aValue;

#pragma mark ¥¥¥Veto HW Access
- (void) setVetoEnable:(int)aState;
- (int)  readVetoState;
- (void) readVetoDataFrom:(int)fromIndex to:(int)toIndex;
#pragma mark ¥¥¥Low-level Register Access
//- (unsigned long) getRegisterAdress:(NSString*)aRegisterName withChan:(int)aChan;
 -(int) readWriteRegisterChan;
-(void) setReadWriteRegisterChan:(int)aChan;
-(NSString *) readWriteRegisterName;
-(void) setReadWriteRegisterName:(NSString *)aName;
- (unsigned long) registerAdressWithName:(NSString *)aName  forChan:(int)aChan;
- (unsigned long) readRegisterWithName:(NSString *)aName  forChan:(int)aChan;
- (unsigned long) writeRegisterWithName:(NSString *)aName  forChan:(int)aChan value:(unsigned long) aValue;

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
//- (void) reset; //see above -tb-

#pragma mark ¥¥¥SubSets of TakeData
- (void) postHitRateChange;
- (void) takeDataHitrateMode:(ORDataPacket*)aDataPacket;
- (void) takeDataMeasureMode:(ORDataPacket*)aDataPacket;
- (void) takeDataRunOrDebugMode:(ORDataPacket*) aDataPacket;
- (void) takeDataHistogramMode:(ORDataPacket*)aDataPacket;
- (void) pauseHistogrammingAndReadOutData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) readOutHistogramDataV3:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeDataVetoMode:(ORDataPacket*)aDataPacket;

#pragma mark ¥¥¥HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

@end

@interface ORKatrinFLTModel (tests)
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

extern NSString* ORKatrinFLTModelVersionRevisionChanged;
extern NSString* ORKatrinFLTModelAvailableFeaturesChanged;
extern NSString* ORKatrinFLTModelCheckWaveFormEnabledChanged;
extern NSString* ORKatrinFLTModelCheckEnergyEnabledChanged;
extern NSString* ORKatrinFLTModelTestPatternCountChanged;
extern NSString* ORKatrinFLTModelTModeChanged;
extern NSString* ORKatrinFLTModelTestParamChanged;
extern NSString* ORKatrinFLTModelTestsRunningChanged;
extern NSString* ORKatrinFLTModelTestEnabledArrayChanged;
extern NSString* ORKatrinFLTModelTestStatusArrayChanged;
extern NSString* ORKatrinFLTModelBroadcastTimeChanged;
extern NSString* ORKatrinFLTModelHitRateChanged;
extern NSString* ORKatrinFLTModelHitRateLengthChanged;
extern NSString* ORKatrinFLTModelHitRatesArrayChanged;
extern NSString* ORKatrinFLTModelHitRateEnabledChanged;
extern NSString* ORKatrinFLTModelShapingTimeChanged;
extern NSString* ORKatrinFLTModelTriggerEnabledChanged;
extern NSString* ORKatrinFLTModelShapingTimesChanged;
extern NSString* ORKatrinFLTModelTriggersEnabledChanged;
extern NSString* ORKatrinFLTModelGainChanged;
extern NSString* ORKatrinFLTModelThresholdChanged;
extern NSString* ORKatrinFLTChan;
extern NSString* ORKatrinFLTModelGainsChanged;
extern NSString* ORKatrinFLTModelTestPatternsChanged;
extern NSString* ORKatrinFLTModelThresholdsChanged;
extern NSString* ORKatrinFLTModelFilterGapChanged;
extern NSString* ORKatrinFLTModelFilterGapBinsChanged;
extern NSString* ORKatrinFLTModelFltRunModeChanged;
extern NSString* ORKatrinFLTModelDaqRunModeChanged;
extern NSString* ORKatrinFLTSettingsLock;
extern NSString* ORKatrinFLTModelPostTriggerTimeChanged;

extern NSString* ORKatrinFLTModelReadoutPagesChanged;
extern NSString* ORKatrinSLTModelName;

extern NSString* ORKatrinFLTModelHistoBinWidthChanged;
extern NSString* ORKatrinFLTModelHistoMinEnergyChanged;
extern NSString* ORKatrinFLTModelHistoMaxEnergyChanged;
extern NSString* ORKatrinFLTModelHistoFirstBinChanged;
extern NSString* ORKatrinFLTModelHistoLastBinChanged;
extern NSString* ORKatrinFLTModelHistoRunTimeChanged;
extern NSString* ORKatrinFLTModelHistoRecordingTimeChanged;
extern NSString* ORKatrinFLTModelHistoSelfCalibrationPercentChanged;
extern NSString* ORKatrinFLTModelHistoCalibrationValuesChanged;    
extern NSString* ORKatrinFLTModelHistoCalibrationPlotterChanged;    
extern NSString* ORKatrinFLTModelShowHitratesDuringHistoCalibrationChanged;
extern NSString* ORKatrinFLTModelHistoClearAtStartChanged;
extern NSString* ORKatrinFLTModelHistoClearAfterReadoutChanged;
extern NSString* ORKatrinFLTModelHistoStopIfNotClearedChanged;
extern NSString* ORKatrinFLTModelHistoCalibrationChanChanged;
extern NSString* ORKatrinFLTModelHistoPageNumChanged;
extern NSString* ORKatrinFLTModelReadWriteRegisterChanChanged;
extern NSString* ORKatrinFLTModelReadWriteRegisterNameChanged;


