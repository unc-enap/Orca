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
    uint32_t extDiscriminatorSrc;
    uint32_t extDiscriminatorMode;
    uint32_t hardwareStatus;
    uint32_t userPackageData;
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
    uint32_t aHitCounter[kNumGretina4AChannels];
    uint32_t droppedEventCount[kNumGretina4AChannels];
    uint32_t acceptedEventCount[kNumGretina4AChannels];
    uint32_t discriminatorCount[kNumGretina4AChannels];
    
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
    uint32_t       registerWriteValue;
    int                 registerIndex;
    uint32_t       spiWriteValue;
    ORFileMoverOp*      fpgaFileMover;
	BOOL                isRunning;
    NSString*           firmwareStatusString;
    BOOL                locked;
    uint32_t       snapShot[kNumberOfGretina4ARegisters];
    uint32_t       fpgaSnapShot[kNumberOfFPGARegisters];
    
    //rates
    ORRateGroup*    waveFormRateGroup;
    uint32_t   waveFormCount[kNumGretina4AChannels];
    ORRunningAverageGroup* rateRunningAverages; //initialized in initWithCoder, start by runstart

    //clock sync
    int             initializationState;
    
    //data taker
    uint32_t   dataId;
    uint32_t   dataBuffer[kG4MDataPacketSize];
    uint32_t   location;           //cache value
    id              theController;      //cache value
    uint32_t   fifoAddress;        //cache value
    uint32_t   fifoStateAddress;   //cache value
    int             fifoState;
    int				fifoEmptyCount;
    int             fifoResetCount;
    ORAlarm*        fifoFullAlarm;
    uint32_t   serialNumber;
    
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
    uint32_t   p2Window;
    short           dacChannelSelect;
    short           dacAttenuation;
    
    unsigned short baselineDelay;
    unsigned short trackingSpeed;
    unsigned short baselineStatus;
    uint32_t  channelPulsedControl;
    uint32_t  diagMuxControl;
    

    unsigned short  downSampleHoldOffTime;
    BOOL            downSamplePauseEnable;
    unsigned short  holdOffTime;
    unsigned short  peakSensitivity;
    BOOL            autoMode;
    unsigned short  diagInput;
    unsigned short  diagChannelEventSel;
    unsigned short  vetoGateWidth;
    
    uint32_t   rj45SpareIoMuxSel;
    BOOL            rj45SpareIoDir;
    uint32_t   ledStatus;
    BOOL            diagIsync;
    BOOL            serdesSmLostLock;
    BOOL            overflowFlagChan[kNumGretina4AChannels];
    unsigned short  triggerConfig;
    uint32_t   phaseErrorCount;
    uint32_t   phaseStatus;
    uint32_t   serdesPhaseValue;
    uint32_t   codeRevision;
    uint32_t   codeDate;
    uint32_t   tSErrCntCtrl;
    uint32_t   tSErrorCount;
    uint32_t   auxIoRead;
    uint32_t   auxIoWrite;
    uint32_t   auxIoConfig;
    uint32_t   sdPem;
    BOOL            sdSmLostLockFlag;
    BOOL            configMainFpga;
    uint32_t   vmeStatus;
    BOOL            clkSelect0;
    BOOL            clkSelect1;
    BOOL            flashMode;
    uint32_t   serialNum;
    uint32_t   boardRevNum;
    uint32_t   vhdlVerNum;
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
- (uint32_t)   baseAddress;
- (ORConnector*)    linkConnector;
- (void)            setLinkConnector:(ORConnector*)aConnector;
- (ORConnector*)    spiConnector;
- (void)            setSpiConnector:(ORConnector*)aConnector;
- (void)            openPreampDialog;

#pragma mark ***Access Methods for Low-Level Access
- (uint32_t)   spiWriteValue;
- (void)            setSPIWriteValue:(uint32_t)aWriteValue;
- (short)           registerIndex;
- (void)            setRegisterIndex:(int)aRegisterIndex;
- (uint32_t)   registerWriteValue;
- (void)            setRegisterWriteValue:(uint32_t)aWriteValue;
- (uint32_t)   selectedChannel;
- (void)            setSelectedChannel:(unsigned short)aChannel;
- (uint32_t)   readRegister:(unsigned int)index channel:(int)aChannel;
- (uint32_t)   readRegister:(unsigned int)index;
- (void)            writeRegister:(unsigned int)index withValue:(uint32_t)value;
- (void)            writeToAddress:(uint32_t)anAddress aValue:(uint32_t)aValue;
- (uint32_t)   readFromAddress:(uint32_t)anAddress;
- (uint32_t)   readFPGARegister:(unsigned int)index;
- (void)            writeFPGARegister:(unsigned int)index withValue:(uint32_t)value;
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
- (uint32_t) getCounter:(short)counterTag forGroup:(short)groupTag;

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
- (uint32_t)   extDiscriminatorSrc;
- (void)            setExtDiscriminatorSrc:(uint32_t)aValue;
- (uint32_t)   extDiscriminatorMode;
- (void)            setExtDiscriminatorMode:(uint32_t)aValue;
- (uint32_t)   hardwareStatus;
- (void)            setHardwareStatus:      (uint32_t)aValue;
- (uint32_t)   userPackageData;
- (void)            setUserPackageData:     (uint32_t)aValue;
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
- (uint32_t)   channelPulsedControl;
- (void)            setChannelPulsedControl:(uint32_t)aValue;
- (uint32_t)   diagMuxControl;
- (void)            setDiagMuxControl:      (uint32_t)aValue;
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
- (uint32_t)   extDiscriminatorMode;
- (void)            setExtDiscriminatorMode:(uint32_t)aValue;
- (unsigned short)  diagInput;
- (void)            setDiagInput:           (unsigned short)aValue;
- (unsigned short)  vetoGateWidth;
- (void)            setVetoGateWidth:       (unsigned short)aValue;
- (unsigned short)   diagChannelEventSel;
- (void)            setDiagChannelEventSel: (unsigned short)aValue;
- (uint32_t)   rj45SpareIoMuxSel;
- (void)            setRj45SpareIoMuxSel:   (uint32_t)aValue;
- (BOOL)            rj45SpareIoDir;
- (void)            setRj45SpareIoDir:      (BOOL)aValue;
- (uint32_t)   ledStatus;
- (void)            setLedStatus:           (uint32_t)aValue;
- (BOOL)            diagIsync;
- (void)            setDiagIsync:           (BOOL)aValue;
- (BOOL)            serdesSmLostLock;
- (void)            setSerdesSmLostLock:    (BOOL)aValue;
- (BOOL)            overflowFlagChan:       (unsigned short)chan;
- (void)            setOverflowFlagChan:    (unsigned short)chan withValue:(BOOL)aValue;
- (unsigned short)  triggerConfig;
- (void)            setTriggerConfig:       (unsigned short)aValue;
- (uint32_t)   phaseErrorCount;
- (void)            setPhaseErrorCount:     (uint32_t)aValue;
- (uint32_t)   phaseStatus;
- (void)            setPhaseStatus:         (uint32_t)aValue;
- (uint32_t)   serdesPhaseValue;
- (void)            setSerdesPhaseValue:    (uint32_t)aValue;
- (uint32_t)   codeRevision;
- (void)            setCodeRevision:        (uint32_t)aValue;
- (uint32_t)   codeDate;
- (void)            setCodeDate:            (uint32_t)aValue;
- (uint32_t)   tSErrCntCtrl;
- (void)            setTSErrCntCtrl:        (uint32_t)aValue;
- (uint32_t)   tSErrorCount;
- (void)            setTSErrorCount:        (uint32_t)aValue;
- (uint32_t)   droppedEventCount:      (unsigned short)chan;
- (uint32_t)   acceptedEventCount:     (unsigned short)chan;
- (uint32_t)   aHitCount:              (unsigned short)chan;
- (uint32_t)   discCount:              (unsigned short)chan;
- (uint32_t)   auxIoRead;
- (void)            setAuxIoRead:           (uint32_t)aValue;
- (uint32_t)   auxIoWrite;
- (void)            setAuxIoWrite:          (uint32_t)aValue;
- (uint32_t)   auxIoConfig;
- (void)            setAuxIoConfig:         (uint32_t)aValue;
- (uint32_t)   sdPem;
- (void)            setSdPem:               (uint32_t)aValue;
- (BOOL)            sdSmLostLockFlag;
- (void)            setSdSmLostLockFlag:    (BOOL)aValue;
- (BOOL)            configMainFpga;
- (void)            setConfigMainFpga:      (BOOL)aValue;
- (uint32_t)   vmeStatus;
- (void)            setVmeStatus:           (uint32_t)aValue;
- (BOOL)            clkSelect0;
- (void)            setClkSelect0:          (BOOL)aValue;
- (BOOL)            clkSelect1;
- (void)            setClkSelect1:          (BOOL)aValue;
- (BOOL)            flashMode;
- (void)            setFlashMode:           (BOOL)aValue;
- (uint32_t)   serialNum;
- (void)            setSerialNum:           (uint32_t)aValue;
- (uint32_t)   boardRevNum;
- (void)            setBoardRevNum:         (uint32_t)aValue;
- (uint32_t)   vhdlVerNum;
- (void)            setVhdlVerNum:          (uint32_t)aValue;
- (short)           clockSource;
- (void)            setClockSource:(short)aClockSource;

#pragma mark - Hardware Access
- (void)            writeLong:          (uint32_t)aValue toReg:(int)aReg;
- (void)            writeLong:          (uint32_t)aValue toReg:(int)aReg channel:(int)aChan;
- (uint32_t)   readLongFromReg:    (int)aReg;
- (uint32_t)   readLongFromReg:    (int)aReg channel:(int)aChan;
- (short)           readBoardIDReg;
- (BOOL)            checkFirmwareVersion;
- (BOOL)            checkFirmwareVersion:(BOOL)verbose;
- (BOOL)            fifoIsEmpty;
- (void)            resetSingleFIFO;
- (void)            resetFIFO;
- (void)            writeThresholds;
- (uint32_t)   readExtDiscriminatorSrc;
- (void)            writeExtDiscriminatorSrc;
- (uint32_t)   readExtDiscriminatorMode;
- (void)            writeExtDiscriminatorMode;
- (uint32_t)   readHardwareStatus;
- (uint32_t)   readUserPackageData;
- (void)            writeUserPackageData;
- (uint32_t)   readWindowCompMin;
- (void)            writeWindowCompMin;
- (uint32_t)   readWindowCompMax;
- (void)            writeWindowCompMax;
- (void)            clearCounters;
- (uint32_t)   readControlReg:     (unsigned short)channel;
- (void)            writeControlReg:    (unsigned short)chan enabled:(BOOL)forceEnable;
- (uint32_t)   readLedThreshold:   (unsigned short)channel;
- (void)            writeLedThreshold:  (unsigned short)channel;
- (uint32_t)   readRawDataLength:  (unsigned short)channel;
- (void)            writeRawDataLength: (unsigned short)channel;
- (uint32_t)   readRawDataWindow:  (unsigned short)channel;
- (void)            writeRawDataWindow: (unsigned short)channel;
- (uint32_t)   readDWindow:        (unsigned short)channel;
- (void)            writeDWindow:       (unsigned short)channel;
- (uint32_t)   readKWindow:        (unsigned short)channel;
- (void)            writeKWindow:       (unsigned short)channel;
- (uint32_t)   readMWindow:        (unsigned short)channel;
- (void)            writeMWindow:       (unsigned short)channel;
- (uint32_t)   readD3Window:       (unsigned short)channel;
- (void)            writeD3Window:      (unsigned short)channel;
- (uint32_t)   readDiscWidth:      (unsigned short)channel;
- (void)            writeDiscWidth:     (unsigned short)channel;
- (uint32_t)   readBaselineStart:  (unsigned short)channel;
- (void)            writeBaselineStart: (unsigned short)channel;
- (uint32_t)   readP1Window:        (unsigned short)channel;
- (void)            writeP1Window:       (unsigned short)channel;
- (uint32_t)   readP2Window;
- (void)            writeP2Window;
- (void)            loadBaselines;
- (void)            loadDelays;
- (uint32_t)   readBaselineDelay;
- (void)            writeBaselineDelay;
- (uint32_t)   readDownSampleHoldOffTime;
- (void)            writeDownSampleHoldOffTime;
- (uint32_t)   readHoldoffControl;
- (void)            writeHoldoffControl;
- (uint64_t) readLiveTimeStamp;
- (uint64_t) readLatTimeStamp;
- (uint32_t)   readVetoGateWidth;
- (void)            writeVetoGateWidth;
- (void)            writeMasterLogic:(BOOL)enable;
- (uint32_t)   readTriggerConfig;
- (void)            writeTriggerConfig;
- (void)            readFPGAVersions;
- (uint32_t)   readVmeAuxStatus;
- (void)            readCodeRevision;
- (void)            readaHitCounts;
- (void)            readDroppedEventCounts;
- (void)            readAcceptedEventCounts;
- (void)            readDiscriminatorCounts;
- (void)            clearCounters;
- (short)           readClockSource;
- (void)            writeClockSource: (uint32_t) clocksource;
- (void)            writeClockSource;
- (void)            resetBoard;
- (void)            resetMainFPGA;
- (void)            initBoard;
- (void)            initBoard:(BOOL)doChannelEnable;
- (void)            dumpCounters;
- (void)            dumpBoardIdDetails:         (uint32_t)aValue;
- (void)            dumpProgrammingDoneDetails: (uint32_t)aValue;
- (void)            dumpHardwareStatusDetails:  (uint32_t)aValue;
- (void)            dumpExternalDiscSrcDetails: (uint32_t)aValue;
- (void)            dumpChannelControlDetails:  (uint32_t)aValue;
- (void)            dumpHoldoffControlDetails:  (uint32_t)aValue;
- (void)            dumpBaselineDelayDetails:   (uint32_t)aValue;
- (void)            dumpExtDiscModeDetails:     (uint32_t)aValue;
- (void)            dumpMasterStatusDetails:    (uint32_t)aValue;

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
- (uint32_t)   dataId;
- (void)            setDataId:      (uint32_t) DataId;
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
- (uint32_t) writeAuxIOSPI:(uint32_t)spiData;

#pragma mark - AdcProviding Protocol
- (BOOL)            onlineMaskBit:(int)bit;
- (BOOL)            partOfEvent:(unsigned short)aChannel;
- (uint32_t)   waveFormCount:(short)aChannel;
- (uint32_t)   eventCount:(int)aChannel;
- (uint32_t)   thresholdForDisplay:(unsigned short) aChan;
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
