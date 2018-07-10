//-------------------------------------------------------------------------
//  ORGretina4AModel.h
//
//  Created by Mark A. Howe on Wednesday 11/20/14.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//Washington sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "SBC_Config.h"
#import "AutoTesting.h"
#import "ORAdcInfoProviding.h"
#import "SBC_Link.h"
#import "ORGretina4ARegisters.h"
#import "ORGretinaTriggerProtocol.h"

@class ORRateGroup;
@class ORConnector;
@class ORFileMoverOp;
@class ORRunningAverageGroup;
@class ORConnector;

#define kG4MDataPacketSize 2048+2  //waveforms have max size, ORCA header is 2

@interface ORGretina4AModel : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,AutoTesting,ORAdcInfoProviding,ORGretinaTriggerProtocol>
{
  @private
    //connectors
    ORConnector* spiConnector;  //we won't draw this connector but need a reference to it
    ORConnector* linkConnector; //we won't draw this connector but need a reference to it
    
    //registerValues
    unsigned long extDiscriminatorSrc;
    unsigned long extDiscriminatorMode;
    unsigned long hardwareStatus;
    unsigned long userPackageData;
    unsigned short windowCompMin;
    unsigned short windowCompMax;
    //control reg bits
    BOOL  enabled[kNumGretina4AChannels];
    BOOL  pileupMode[kNumGretina4AChannels];
    short triggerPolarity[kNumGretina4AChannels];
    short decimationFactor[kNumGretina4AChannels];
    BOOL  droppedEventCountMode[kNumGretina4AChannels];
    BOOL  eventCountMode[kNumGretina4AChannels];
    BOOL  aHitCountMode[kNumGretina4AChannels];
    BOOL  discCountMode[kNumGretina4AChannels];
    BOOL  pileupWaveformOnlyMode[kNumGretina4AChannels];
    short ledThreshold[kNumGretina4AChannels];
    //counters
    unsigned long aHitCounter[kNumGretina4AChannels];
    unsigned long droppedEventCount[kNumGretina4AChannels];
    unsigned long acceptedEventCount[kNumGretina4AChannels];
    unsigned long discriminatorCount[kNumGretina4AChannels];
    
    //firmware loading
    NSThread*	fpgaProgrammingThread;
    NSString*   mainFPGADownLoadState;
    NSString*   fpgaFilePath;
	BOOL        stopDownLoadingMainFPGA;
	BOOL        downLoadMainFPGAInProgress;
    int         fpgaDownProgress;
	NSLock*     progressLock;
	
    //low-level registers and diagnostics
    NSOperationQueue*	fileQueue;
    unsigned short      selectedChannel;
    unsigned long       registerWriteValue;
    int                 registerIndex;
    unsigned long       spiWriteValue;
    ORFileMoverOp*      fpgaFileMover;
	BOOL                isRunning;
    NSString*           firmwareStatusString;
    BOOL                locked;
    unsigned long       snapShot[kNumberOfGretina4ARegisters];
    unsigned long       fpgaSnapShot[kNumberOfFPGARegisters];
    
    //rates
    ORRateGroup*    waveFormRateGroup;
    unsigned long   waveFormCount[kNumGretina4AChannels];
    ORRunningAverageGroup* rateRunningAverages; //initialized in initWithCoder, start by runstart

    //clock sync
    int             initializationState;
    
    //data taker
    unsigned long   dataId;
    unsigned long   dataBuffer[kG4MDataPacketSize];
    unsigned long   location;           //cache value
    id              theController;      //cache value
    unsigned long   fifoAddress;        //cache value
    unsigned long   fifoStateAddress;   //cache value
    int             fifoState;
    int				fifoEmptyCount;
    int             fifoResetCount;
    ORAlarm*        fifoFullAlarm;
    unsigned long   serialNumber;
    
    //hardware params
    BOOL			forceFullInit[kNumGretina4AChannels];
    BOOL            forceFullCardInit;
    
    BOOL            pileupExtensionMode[kNumGretina4AChannels];
    short           rawDataLength;
    short           rawDataWindow;
    short           dWindow[kNumGretina4AChannels];
    short           kWindow[kNumGretina4AChannels];
    short           mWindow[kNumGretina4AChannels];
    short           d3Window[kNumGretina4AChannels];
    short           discWidth[kNumGretina4AChannels];
    short           baselineStart[kNumGretina4AChannels];
    short           p1Window[kNumGretina4AChannels];
    unsigned long   p2Window;
    short           dacChannelSelect;
    short           dacAttenuation;
    
    unsigned short baselineDelay;
    unsigned short trackingSpeed;
    unsigned short baselineStatus;
    unsigned long  channelPulsedControl;
    unsigned long  diagMuxControl;
    

    unsigned short  downSampleHoldOffTime;
    BOOL            downSamplePauseEnable;
    unsigned short  holdOffTime;
    unsigned short  peakSensitivity;
    BOOL            autoMode;
    unsigned short  diagInput;
    unsigned short  diagChannelEventSel;
    unsigned short  vetoGateWidth;
    
    unsigned long   rj45SpareIoMuxSel;
    BOOL            rj45SpareIoDir;
    unsigned long   ledStatus;
    BOOL            diagIsync;
    BOOL            serdesSmLostLock;
    BOOL            overflowFlagChan[kNumGretina4AChannels];
    unsigned short  triggerConfig;
    unsigned long   phaseErrorCount;
    unsigned long   phaseStatus;
    unsigned long   serdesPhaseValue;
    unsigned long   codeRevision;
    unsigned long   codeDate;
    unsigned long   tSErrCntCtrl;
    unsigned long   tSErrorCount;
    unsigned long   auxIoRead;
    unsigned long   auxIoWrite;
    unsigned long   auxIoConfig;
    unsigned long   sdPem;
    BOOL            sdSmLostLockFlag;
    BOOL            configMainFpga;
    unsigned long   vmeStatus;
    BOOL            clkSelect0;
    BOOL            clkSelect1;
    BOOL            flashMode;
    unsigned long   serialNum;
    unsigned long   boardRevNum;
    unsigned long   vhdlVerNum;
    BOOL            firstTime;
    BOOL            doHwCheck;
    short           clockSource;

}

#pragma mark - Boilerplate
- (id)          init;
- (void)        dealloc;
- (void)        setUpImage;
- (void)        makeMainController;
- (NSString*)   helpURL;
- (Class)       guardianClass;
- (NSRange)     memoryFootprint;


- (void) makeConnectors;
- (void) setSlot:(int)aSlot;
- (void) positionConnector:(ORConnector*)aConnector;
- (void) setGuardian:(id)aGuardian;
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;
- (void) disconnect;
- (unsigned long)   baseAddress;
- (ORConnector*)    linkConnector;
- (void)            setLinkConnector:(ORConnector*)aConnector;
- (ORConnector*)    spiConnector;
- (void)            setSpiConnector:(ORConnector*)aConnector;
- (void)            openPreampDialog;

#pragma mark ***Access Methods for Low-Level Access
- (unsigned long)   spiWriteValue;
- (void)            setSPIWriteValue:(unsigned long)aWriteValue;
- (short)           registerIndex;
- (void)            setRegisterIndex:(int)aRegisterIndex;
- (unsigned long)   registerWriteValue;
- (void)            setRegisterWriteValue:(unsigned long)aWriteValue;
- (unsigned long)   selectedChannel;
- (void)            setSelectedChannel:(unsigned short)aChannel;
- (unsigned long)   readRegister:(unsigned int)index channel:(int)aChannel;
- (unsigned long)   readRegister:(unsigned int)index;
- (void)            writeRegister:(unsigned int)index withValue:(unsigned long)value;
- (void)            writeToAddress:(unsigned long)anAddress aValue:(unsigned long)aValue;
- (unsigned long)   readFromAddress:(unsigned long)anAddress;
- (unsigned long)   readFPGARegister:(unsigned int)index;
- (void)            writeFPGARegister:(unsigned int)index withValue:(unsigned long)value;
- (void)            snapShotRegisters;
- (void)            compareToSnapShot;
- (void)            dumpAllRegisters;

#pragma mark - Firmware loading
- (BOOL)        downLoadMainFPGAInProgress;
- (void)        setDownLoadMainFPGAInProgress:(BOOL)aState;
- (short)       fpgaDownProgress;
- (NSString*)   mainFPGADownLoadState;
- (void)        setMainFPGADownLoadState:(NSString*)aMainFPGADownLoadState;
- (NSString*)   fpgaFilePath;
- (void)        setFpgaFilePath:(NSString*)aFpgaFilePath;
- (void)        startDownLoadingMainFPGA;
- (void)        tasksCompleted: (NSNotification*)aNote;
- (BOOL)        queueIsRunning;
- (NSString*)   firmwareStatusString;
- (void)        setFirmwareStatusString:(NSString*)aState;
- (void)        flashFpgaStatus:(ORSBCLinkJobStatus*) jobStatus;
- (void)        stopDownLoadingMainFPGA;

#pragma mark - rates
- (ORRateGroup*)  waveFormRateGroup;
- (void)          setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)            rateObject:(short)channel;
- (void)          setRateIntegrationTime:(double)newIntegrationTime;
- (unsigned long) getCounter:(short)counterTag forGroup:(short)groupTag;

#pragma mark - Initialization
- (BOOL) forceFullCardInit;
- (void) setForceFullCardInit:  (BOOL)aValue;
- (BOOL) forceFullInit:         (short)chan;
- (void) setForceFullInit:      (short)chan withValue:(BOOL)aValue;
- (BOOL) doHwCheck;
- (void) setDoHwCheck:          (BOOL)aFlag;

#pragma mark - Persistant Register Values
- (void)            loadCardDefaults;
- (void)            loadChannelDefaults:(unsigned short) aChan;
- (unsigned long)   extDiscriminatorSrc;
- (void)            setExtDiscriminatorSrc:(unsigned long)aValue;
- (unsigned long)   extDiscriminatorMode;
- (void)            setExtDiscriminatorMode:(unsigned long)aValue;
- (unsigned long)   hardwareStatus;
- (void)            setHardwareStatus:      (unsigned long)aValue;
- (unsigned long)   userPackageData;
- (void)            setUserPackageData:     (unsigned long)aValue;
- (unsigned short)  windowCompMin;
- (void)            setWindowCompMin:       (unsigned short)aValue;
- (unsigned short)  windowCompMax;
- (void)            setWindowCompMax:       (unsigned short)aValue;
- (BOOL)            enabled:                (unsigned short)chan;
- (void)            setEnabled:             (unsigned short)chan withValue:(BOOL)aValue;
- (BOOL)            pileupMode:             (unsigned short)chan;
- (void)            setPileupMode:          (unsigned short)chan withValue:(BOOL)aValue;
- (short)           triggerPolarity:        (unsigned short)chan;
- (void)            setTriggerPolarity:     (unsigned short)chan withValue:(unsigned short)aValue;
- (short)           decimationFactor:       (unsigned short)chan;
- (void)            setDecimationFactor:    (unsigned short)chan withValue:(unsigned short)aValue;
- (BOOL)            droppedEventCountMode:  (unsigned short)chan;
- (void)            setDroppedEventCountMode:(unsigned short)chan withValue:(BOOL)aValue;
- (BOOL)            eventCountMode:         (unsigned short)chan;
- (void)            setEventCountMode:      (unsigned short)chan withValue:(BOOL)aValue;
- (BOOL)            aHitCountMode:          (unsigned short)chan;
- (void)            setAHitCountMode:       (unsigned short)chan withValue:(BOOL)aValue;
- (BOOL)            discCountMode:          (unsigned short)chan;
- (void)            setDiscCountMode:       (unsigned short)chan withValue:(BOOL)aValue;
- (BOOL)            pileupExtensionMode:    (unsigned short)chan;
- (void)            setPileupExtensionMode: (unsigned short)chan withValue:(BOOL)aValue;
- (BOOL)            pileupWaveformOnlyMode: (unsigned short)chan;
- (void)            setPileupWaveformOnlyMode:(unsigned short)chan withValue:(BOOL)aValue;
- (void)            setThreshold:           (unsigned short)chan withValue:(int)aValue;
- (short)           ledThreshold:           (unsigned short)chan;
- (void)            setLedThreshold:        (unsigned short)chan withValue:(unsigned short)aValue;
- (short)           rawDataLength;
- (void)            setRawDataLength:       (unsigned short)aValue;
- (short)           rawDataWindow;
- (void)            setRawDataWindow:       (unsigned short)aValue;
- (short)           dWindow:                (unsigned short)chan;
- (void)            setDWindow:             (unsigned short)chan withValue:(unsigned short)aValue;
- (short)           kWindow:                (unsigned short)chan;
- (void)            setKWindow:             (unsigned short)chan withValue:(unsigned short)aValue;
- (short)           mWindow:                (unsigned short)chan;
- (void)            setMWindow:             (unsigned short)chan withValue:(unsigned short)aValue;
- (short)           d3Window:               (unsigned short)chan;
- (void)            setD3Window:            (unsigned short)chan withValue:(unsigned short)aValue;
- (short)           discWidth:              (unsigned short)chan;
- (void)            setDiscWidth:           (unsigned short)chan withValue:(unsigned short)aValue;
- (short)           baselineStart:          (unsigned short)chan;
- (void)            setBaselineStart:       (unsigned short)chan withValue:(unsigned short)aValue;
- (short)           p1Window:                (unsigned short)chan;
- (void)            setP1Window:             (unsigned short)chan withValue:(unsigned short)aValue;
- (short)            p2Window;
- (void)            setP2Window:            (short)aValue;
- (short)           dacChannelSelect;
- (void)            setDacChannelSelect:    (unsigned short)aValue;
- (short)           dacAttenuation;
- (void)            setDacAttenuation:      (unsigned short)aValue;
- (unsigned long)   channelPulsedControl;
- (void)            setChannelPulsedControl:(unsigned long)aValue;
- (unsigned long)   diagMuxControl;
- (void)            setDiagMuxControl:      (unsigned long)aValue;
- (BOOL)            downSamplePauseEnable;
- (void)            setDownSamplePauseEnable:(BOOL)aFlag;
- (unsigned short)  downSampleHoldOffTime;
- (void)            setDownSampleHoldOffTime:(unsigned short)aValue;
- (unsigned short)  holdOffTime;
- (void)            setHoldOffTime:         (unsigned short)aValue;
- (unsigned short)  peakSensitivity;
- (void)            setPeakSensitivity:     (unsigned short)aValue;
- (BOOL)            autoMode;
- (void)            setAutoMode:            (BOOL)aValue;
- (unsigned short)  baselineDelay;
- (void)            setBaselineDelay:       (unsigned short)aValue;
- (unsigned short)  trackingSpeed;
- (void)            setTrackingSpeed:       (unsigned short)aValue;
- (unsigned short)  baselineStatus;
- (void)            setBaselineStatus:      (unsigned short)aValue;
- (unsigned long)   extDiscriminatorMode;
- (void)            setExtDiscriminatorMode:(unsigned long)aValue;
- (unsigned short)  diagInput;
- (void)            setDiagInput:           (unsigned short)aValue;
- (unsigned short)  vetoGateWidth;
- (void)            setVetoGateWidth:       (unsigned short)aValue;
- (unsigned short)   diagChannelEventSel;
- (void)            setDiagChannelEventSel: (unsigned short)aValue;
- (unsigned long)   rj45SpareIoMuxSel;
- (void)            setRj45SpareIoMuxSel:   (unsigned long)aValue;
- (BOOL)            rj45SpareIoDir;
- (void)            setRj45SpareIoDir:      (BOOL)aValue;
- (unsigned long)   ledStatus;
- (void)            setLedStatus:           (unsigned long)aValue;
- (BOOL)            diagIsync;
- (void)            setDiagIsync:           (BOOL)aValue;
- (BOOL)            serdesSmLostLock;
- (void)            setSerdesSmLostLock:    (BOOL)aValue;
- (BOOL)            overflowFlagChan:       (unsigned short)chan;
- (void)            setOverflowFlagChan:    (unsigned short)chan withValue:(BOOL)aValue;
- (unsigned short)  triggerConfig;
- (void)            setTriggerConfig:       (unsigned short)aValue;
- (unsigned long)   phaseErrorCount;
- (void)            setPhaseErrorCount:     (unsigned long)aValue;
- (unsigned long)   phaseStatus;
- (void)            setPhaseStatus:         (unsigned long)aValue;
- (unsigned long)   serdesPhaseValue;
- (void)            setSerdesPhaseValue:    (unsigned long)aValue;
- (unsigned long)   codeRevision;
- (void)            setCodeRevision:        (unsigned long)aValue;
- (unsigned long)   codeDate;
- (void)            setCodeDate:            (unsigned long)aValue;
- (unsigned long)   tSErrCntCtrl;
- (void)            setTSErrCntCtrl:        (unsigned long)aValue;
- (unsigned long)   tSErrorCount;
- (void)            setTSErrorCount:        (unsigned long)aValue;
- (unsigned long)   droppedEventCount:      (unsigned short)chan;
- (unsigned long)   acceptedEventCount:     (unsigned short)chan;
- (unsigned long)   aHitCount:              (unsigned short)chan;
- (unsigned long)   discCount:              (unsigned short)chan;
- (unsigned long)   auxIoRead;
- (void)            setAuxIoRead:           (unsigned long)aValue;
- (unsigned long)   auxIoWrite;
- (void)            setAuxIoWrite:          (unsigned long)aValue;
- (unsigned long)   auxIoConfig;
- (void)            setAuxIoConfig:         (unsigned long)aValue;
- (unsigned long)   sdPem;
- (void)            setSdPem:               (unsigned long)aValue;
- (BOOL)            sdSmLostLockFlag;
- (void)            setSdSmLostLockFlag:    (BOOL)aValue;
- (BOOL)            configMainFpga;
- (void)            setConfigMainFpga:      (BOOL)aValue;
- (unsigned long)   vmeStatus;
- (void)            setVmeStatus:           (unsigned long)aValue;
- (BOOL)            clkSelect0;
- (void)            setClkSelect0:          (BOOL)aValue;
- (BOOL)            clkSelect1;
- (void)            setClkSelect1:          (BOOL)aValue;
- (BOOL)            flashMode;
- (void)            setFlashMode:           (BOOL)aValue;
- (unsigned long)   serialNum;
- (void)            setSerialNum:           (unsigned long)aValue;
- (unsigned long)   boardRevNum;
- (void)            setBoardRevNum:         (unsigned long)aValue;
- (unsigned long)   vhdlVerNum;
- (void)            setVhdlVerNum:          (unsigned long)aValue;
- (short)           clockSource;
- (void)            setClockSource:(short)aClockSource;

#pragma mark - Hardware Access
- (void)            writeLong:          (unsigned long)aValue toReg:(int)aReg;
- (void)            writeLong:          (unsigned long)aValue toReg:(int)aReg channel:(int)aChan;
- (unsigned long)   readLongFromReg:    (int)aReg;
- (unsigned long)   readLongFromReg:    (int)aReg channel:(int)aChan;
- (short)           readBoardIDReg;
- (BOOL)            checkFirmwareVersion;
- (BOOL)            checkFirmwareVersion:(BOOL)verbose;
- (BOOL)            fifoIsEmpty;
- (void)            resetSingleFIFO;
- (void)            resetFIFO;
- (void)            writeThresholds;
- (unsigned long)   readExtDiscriminatorSrc;
- (void)            writeExtDiscriminatorSrc;
- (unsigned long)   readExtDiscriminatorMode;
- (void)            writeExtDiscriminatorMode;
- (unsigned long)   readHardwareStatus;
- (unsigned long)   readUserPackageData;
- (void)            writeUserPackageData;
- (unsigned long)   readWindowCompMin;
- (void)            writeWindowCompMin;
- (unsigned long)   readWindowCompMax;
- (void)            writeWindowCompMax;
- (void)            clearCounters;
- (unsigned long)   readControlReg:     (unsigned short)channel;
- (void)            writeControlReg:    (unsigned short)chan enabled:(BOOL)forceEnable;
- (unsigned long)   readLedThreshold:   (unsigned short)channel;
- (void)            writeLedThreshold:  (unsigned short)channel;
- (unsigned long)   readRawDataLength:  (unsigned short)channel;
- (void)            writeRawDataLength: (unsigned short)channel;
- (unsigned long)   readRawDataWindow:  (unsigned short)channel;
- (void)            writeRawDataWindow: (unsigned short)channel;
- (unsigned long)   readDWindow:        (unsigned short)channel;
- (void)            writeDWindow:       (unsigned short)channel;
- (unsigned long)   readKWindow:        (unsigned short)channel;
- (void)            writeKWindow:       (unsigned short)channel;
- (unsigned long)   readMWindow:        (unsigned short)channel;
- (void)            writeMWindow:       (unsigned short)channel;
- (unsigned long)   readD3Window:       (unsigned short)channel;
- (void)            writeD3Window:      (unsigned short)channel;
- (unsigned long)   readDiscWidth:      (unsigned short)channel;
- (void)            writeDiscWidth:     (unsigned short)channel;
- (unsigned long)   readBaselineStart:  (unsigned short)channel;
- (void)            writeBaselineStart: (unsigned short)channel;
- (unsigned long)   readP1Window:        (unsigned short)channel;
- (void)            writeP1Window:       (unsigned short)channel;
- (unsigned long)   readP2Window;
- (void)            writeP2Window;
- (void)            loadBaselines;
- (void)            loadDelays;
- (unsigned long)   readBaselineDelay;
- (void)            writeBaselineDelay;
- (unsigned long)   readDownSampleHoldOffTime;
- (void)            writeDownSampleHoldOffTime;
- (unsigned long)   readHoldoffControl;
- (void)            writeHoldoffControl;
- (unsigned long long) readLiveTimeStamp;
- (unsigned long long) readLatTimeStamp;
- (unsigned long)   readVetoGateWidth;
- (void)            writeVetoGateWidth;
- (void)            writeMasterLogic:(BOOL)enable;
- (unsigned long)   readTriggerConfig;
- (void)            writeTriggerConfig;
- (void)            readFPGAVersions;
- (unsigned long)   readVmeAuxStatus;
- (void)            readCodeRevision;
- (void)            readaHitCounts;
- (void)            readDroppedEventCounts;
- (void)            readAcceptedEventCounts;
- (void)            readDiscriminatorCounts;
- (void)            clearCounters;
- (short)           readClockSource;
- (void)            writeClockSource: (unsigned long) clocksource;
- (void)            writeClockSource;
- (void)            resetBoard;
- (void)            resetMainFPGA;
- (void)            initBoard;
- (void)            initBoard:(BOOL)doChannelEnable;
- (void)            dumpCounters;
- (void)            dumpBoardIdDetails:         (unsigned long)aValue;
- (void)            dumpProgrammingDoneDetails: (unsigned long)aValue;
- (void)            dumpHardwareStatusDetails:  (unsigned long)aValue;
- (void)            dumpExternalDiscSrcDetails: (unsigned long)aValue;
- (void)            dumpChannelControlDetails:  (unsigned long)aValue;
- (void)            dumpHoldoffControlDetails:  (unsigned long)aValue;
- (void)            dumpBaselineDelayDetails:   (unsigned long)aValue;
- (void)            dumpExtDiscModeDetails:     (unsigned long)aValue;
- (void)            dumpMasterStatusDetails:    (unsigned long)aValue;

- (void)            setForceFullInitCard:(BOOL)aValue;
- (void)            setLedThreshold:(unsigned short)chan withValue:(unsigned short)aValue;
- (void)            writeLedThreshold:(unsigned short)aChan;
- (BOOL)            trapEnabled:(int)aChan;

- (void)            softwareTrigger;

#pragma mark - Clock Sync
- (short)           initState;
- (void)            setInitState:(short)aState;
- (void)            stepSerDesInit;
- (BOOL)            isLocked;
- (BOOL)            locked;
- (void)            setLocked:   (BOOL)aState;
- (NSString*)       serDesStateName;

#pragma mark - Data Taker
- (unsigned long)   dataId;
- (void)            setDataId:      (unsigned long) DataId;
- (void)            setDataIds:     (id)assigner;
- (void)            syncDataIdsWith:(id)anotherCard;
- (NSDictionary*)   dataRecordDescription;


#pragma mark - HW Wizard
-(BOOL)         hasParmetersToRamp;
- (int)         numberOfChannels;
- (NSArray*)    wizardParameters;
- (NSArray*)    wizardSelections;
- (NSNumber*)   extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) checkFifoAlarm;
- (void) reset;
- (void) startRates;
- (void) clearWaveFormCounts;
- (BOOL) bumpRateFromDecodeStage:(short)channel;
- (int)  load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (id) rateObject:(short)channel;
- (void) setRateIntegrationTime:(double)newIntegrationTime;
- (ORRunningAverageGroup*) rateRunningAverages;

#pragma mark - Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (void) addCurrentState:(NSMutableDictionary*)dictionary shortArray:(short*)anArray forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray forKey:(NSString*)aKey;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark - AutoTesting
- (NSArray*) autoTests;
- (void) checkBoard:(BOOL)verbose;
- (BOOL) checkExtDiscriminatorSrc:  (BOOL)verbose;
- (BOOL) checkExtDiscriminatorMode:  (BOOL)verbose;
- (BOOL) checkWindowCompMin:        (BOOL)verbose;
- (BOOL) checkWindowCompMax:        (BOOL)verbose;
- (BOOL) checkP2Window:             (BOOL)verbose;
- (BOOL) checkDownSampleHoldOffTime:(BOOL)verbose;
- (BOOL) checkHoldoffControl:       (BOOL)verbose;
- (BOOL) checkBaselineDelay:        (BOOL)verbose;
- (BOOL) checkVetoGateWidth:        (BOOL)verbose;
- (BOOL) checkTriggerConfig:        (BOOL)verbose;
- (BOOL) checkDiscWidth:    (int)aChan verbose:(BOOL)verbose;
- (BOOL) checkP1Window:     (int)aChan verbose:(BOOL)verbose;
- (BOOL) checkDWindow:      (int)aChan verbose:(BOOL)verbose;
- (BOOL) checkKWindow:      (int)aChan verbose:(BOOL)verbose;
- (BOOL) checkMWindow:      (int)aChan verbose:(BOOL)verbose;
- (BOOL) checkD3Window:     (int)aChan verbose:(BOOL)verbose;
- (BOOL) checkLedThreshold: (int)aChan verbose:(BOOL)verbose;
- (BOOL) checkRawDataWindow:(int)aChan verbose:(BOOL)verbose;
- (BOOL) checkRawDataLength:(int)aChan verbose:(BOOL)verbose;
- (BOOL) checkBaselineStart:(int)aChan verbose:(BOOL)verbose;

#pragma mark - SPI Interface
- (unsigned long) writeAuxIOSPI:(unsigned long)spiData;

#pragma mark - AdcProviding Protocol
- (BOOL)            onlineMaskBit:(int)bit;
- (BOOL)            partOfEvent:(unsigned short)aChannel;
- (unsigned long)   waveFormCount:(short)aChannel;
- (unsigned long)   eventCount:(int)aChannel;
- (unsigned long)   thresholdForDisplay:(unsigned short) aChan;
- (unsigned short)  gainForDisplay:(unsigned short) aChan;
- (void)            clearEventCounts;
- (void)            postAdcInfoProvidingValueChanged;

- (void)            rateSpikeChanged:(NSNotification*)aNote;
- (float)           getRate:(short)channel;


@end

@interface NSObject (Gretina4A)
- (NSString*) IPNumber;
- (NSString*) userName;
- (NSString*) passWord;
- (SBC_Link*) sbcLink;
@end


//===Register Notifications===
extern NSString* ORGretina4AExtDiscrimitorSrcChanged;
extern NSString* ORGretina4AHardwareStatusChanged;
extern NSString* ORGretina4AUserPackageDataChanged;
extern NSString* ORGretina4AWindowCompMinChanged;
extern NSString* ORGretina4AWindowCompMaxChanged;
//---channel control parts---
//------
//---channel control parts---
extern NSString* ORGretina4APileupWaveformOnlyModeChanged;
extern NSString* ORGretina4APileupExtensionModeChanged;
extern NSString* ORGretina4ADiscCountModeChanged;
extern NSString* ORGretina4AAHitCountModeChanged;
extern NSString* ORGretina4AEventCountModeChanged;
extern NSString* ORGretina4ADroppedEventCountModeChanged;
extern NSString* ORGretina4ADecimationFactorChanged;
extern NSString* ORGretina4ATriggerPolarityChanged;
extern NSString* ORGretina4APileupModeChanged;
extern NSString* ORGretina4AEnabledChanged;
//---------
extern NSString* ORGretina4ALedThreshold0Changed;
extern NSString* ORGretina4ARawDataLengthChanged;
extern NSString* ORGretina4ARawDataWindowChanged;
extern NSString* ORGretina4ADWindowChanged;
extern NSString* ORGretina4AKWindowChanged;
extern NSString* ORGretina4AMWindowChanged;
extern NSString* ORGretina4AD3WindowChanged;
extern NSString* ORGretina4ADiscWidthChanged;
extern NSString* ORGretina4ABaselineStartChanged;
extern NSString* ORGretina4AP1WindowChanged;
//---DAC Config---
extern NSString* ORGretina4ADacChannelSelectChanged;
extern NSString* ORGretina4ADacAttenuationChanged;
//------
extern NSString* ORGretina4AP2WindowChanged;
extern NSString* ORGretina4AChannelPulseControlChanged;
extern NSString* ORGretina4ADiagMuxControlChanged;
extern NSString* ORGretina4ADownSampleHoldOffTimeChanged;
extern NSString* ORGretina4ADownSamplePauseEnableChanged;
extern NSString* ORGretina4AHoldOffTimeChanged;
extern NSString* ORGretina4APeakSensitivityChanged;
extern NSString* ORGretina4AAutoModeChanged;
//---Baseline Delay---
extern NSString* ORGretina4ABaselineDelayChanged;
extern NSString* ORGretina4ATrackingSpeedChanged;
extern NSString* ORGretina4ABaselineStatusChanged;
//------
extern NSString* ORGretina4ADiagInputChanged;
extern NSString* ORGretina4ADiagChannelEventSelChanged;
extern NSString* ORGretina4AExtDiscriminatorModeChanged;
extern NSString* ORGretina4ARj45SpareIoDirChanged;
extern NSString* ORGretina4ARj45SpareIoMuxSelChanged;
extern NSString* ORGretina4ALedStatusChanged;
extern NSString* ORGretina4AVetoGateWidthChanged;
//---Master Logic Status
extern NSString* ORGretina4ADiagIsyncChanged;
extern NSString* ORGretina4AOverflowFlagChanChanged;
extern NSString* ORGretina4ASerdesSmLostLockChanged;
//------

extern NSString* ORGretina4ATriggerConfigChanged;
extern NSString* ORGretina4APhaseErrorCountChanged;
extern NSString* ORGretina4APhaseStatusChanged;
extern NSString* ORGretina4ASerdesPhaseValueChanged;
extern NSString* ORGretina4AMjrCodeRevisionChanged;
extern NSString* ORGretina4AMinCodeRevisionChanged;
extern NSString* ORGretina4ACodeDateChanged;
extern NSString* ORGretina4ACodeRevisionChanged;

//---sd_config Reg
extern NSString* ORGretina4ASdPemChanged;
extern NSString* ORGretina4ASdSmLostLockFlagChanged;
//------
extern NSString* ORGretina4AVmeStatusChanged;
extern NSString* ORGretina4AConfigMainFpgaChanged;
extern NSString* ORGretina4AClkSelect0Changed;
extern NSString* ORGretina4AClkSelect1Changed;
extern NSString* ORGretina4AFlashModeChanged;
extern NSString* ORGretina4ASerialNumChanged;
extern NSString* ORGretina4ABoardRevNumChanged;
extern NSString* ORGretina4AVhdlVerNumChanged;


//---AuxIO--
extern NSString* ORGretina4AAuxIoReadChanged;
extern NSString* ORGretina4AAuxIoWriteChanged;
extern NSString* ORGretina4AAuxIoConfigChanged;

//===Notifications for Low-Level Reg Access===
extern NSString* ORGretina4ARegisterIndexChanged;
extern NSString* ORGretina4ASelectedChannelChanged;
extern NSString* ORGretina4ARegisterWriteValueChanged;
extern NSString* ORGretina4ASPIWriteValueChanged;

//===Notifications for Firmware Loading===
extern NSString* ORGretina4AFpgaDownProgressChanged;
extern NSString* ORGretina4AMainFPGADownLoadStateChanged;
extern NSString* ORGretina4AFpgaFilePathChanged;
extern NSString* ORGretina4AModelFirmwareStatusStringChanged;
extern NSString* ORGretina4AMainFPGADownLoadInProgressChanged;

//====General
extern NSString* ORGretina4ARateGroupChangedNotification;
extern NSString* ORGretina4AFIFOCheckChanged;
extern NSString* ORGretina4AModelInitStateChanged;
extern NSString* ORGretina4ACardInited;
extern NSString* ORGretina4AForceFullCardInitChanged;
extern NSString* ORGretina4AForceFullInitChanged;
extern NSString* ORGretina4ADoHwCheckChanged;
extern NSString* ORGretina4ASettingsLock;
extern NSString* ORGretina4ARegisterLock;
extern NSString* ORGretina4ALockChanged;
extern NSString* ORGretina4AModelRateSpiked;
extern NSString* ORGretina4AModelRAGChanged;
extern NSString* ORGretina4AClockSourceChanged;

//====Counters
extern NSString* ORGretina4ATSErrCntCtrlChanged;
extern NSString* ORGretina4ATSErrorCountChanged;
extern NSString* ORGretina4AAHitCountChanged;
extern NSString* ORGretina4ADroppedEventCountChanged;
extern NSString* ORGretina4ADiscCountChanged;
extern NSString* ORGretina4AAcceptedEventCountChanged;
