//
//  ORXL3Model.h
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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
#import "ORSNOCard.h"
#import "PacketTypes.h"
#import "SNOPModel.h"
#import "ORPQResult.h"

typedef struct  {
	NSString*	regName;
	uint32_t	address;
} Xl3RegNamesStruct; 

enum {
	kXl3SelectReg,
	kXl3DataAvailReg,
	kXl3CsReg,
	kXl3MaskReg,
	kXl3ClockReg,
	kXl3HvRelayReg,
	kXl3XilinxReg,
	kXl3TestReg,
	kXl3HvCsReg,
	kXl3HvSetPointReg,
	kXl3HvVoltageReg,
	kXl3HvCurrentReg,
	kXl3VmReg,
	kXl3VrReg,
	kXl3NumRegisters //must be last
};

/* shiftRegOnly parameter to crate init */
#define SHIFT_AND_DAC 2

/* XL3 modes */
#define INIT_MODE 1
#define NORMAL_MODE 2

@class XL3_Link;
@class ORCommandList;
@class ORCouchDB;


@interface ORXL3Model : ORSNOCard
{
	XL3_Link*       xl3Link;
	uint32_t	_xl3MegaBundleDataId;
	uint32_t	_cmosRateDataId;
	uint32_t	_pmtBaseCurrentDataId;
    uint32_t   _xl3FifoDataId;
    uint32_t   _xl3HvDataId;
    uint32_t   _xl3VltDataId;
    uint32_t   _fecVltDataId;
	short           selectedRegister;
	BOOL            basicOpsRunning;
	BOOL            autoIncrement;	
	unsigned short	repeatDelay;
	short           repeatOpCount;
	BOOL            doReadOp;
	uint32_t   workingCount;
	uint32_t   writeValue;
	unsigned int    xl3Mode;
	uint32_t   selectedSlotMask;
	BOOL            xl3ModeRunning;
	uint32_t   xl3RWAddressValue;
    uint32_t   xl3RWDataValue;
	NSMutableDictionary* xl3OpsRunning;
	uint32_t   xl3PedestalMask;
    uint32_t   xl3ChargeInjMask;
    unsigned char   xl3ChargeInjCharge;
    unsigned short  pollXl3Time;
    BOOL            isPollingXl3;
    BOOL            isPollingCMOSRates;
    unsigned short  pollCMOSRatesMask;
    BOOL            isPollingPMTCurrents;
    unsigned short  pollPMTCurrentsMask;
    BOOL            isPollingFECVoltages;
    unsigned short  pollFECVoltagesMask;
    BOOL            isPollingXl3Voltages;
    BOOL            isPollingHVSupply;
    BOOL            isPollingXl3WithRun;
    BOOL            isPollingVerbose;
    BOOL            isPollingForced;
    NSString*       pollStatus;
    NSThread*       pollThread;
    
    uint64_t  relayMask;
    uint64_t  relayViewMask;
    NSString* relayStatus;
    BOOL hvASwitch;
    BOOL hvBSwitch;
    BOOL hvARamping;
    BOOL hvBRamping;
    BOOL hvAQueryWaiting;
    BOOL hvBQueryWaiting;
    BOOL hvAFromDB;
    BOOL hvBFromDB;
    BOOL hvEverUpdated;
    BOOL hvSwitchEverUpdated;
    BOOL hvANeedsUserIntervention;
    BOOL hvBNeedsUserIntervention;
    BOOL isLoaded; //Whether the experiment is open or not (false to start, false at end)
    
    BOOL _isTriggerON;
    
    uint32_t _hvNominalVoltageA;
    float _hvReadbackCorrA;
    float _hvramp_a_up;
    float _hvramp_a_down;
    float _vsetalarm_a_vtol;
    float _ilowalarm_a_vmin;
    float _ilowalarm_a_imin;
    float _vhighalarm_a_vmax;
    float _ihighalarm_a_imax;
    
    uint32_t _hvNominalVoltageB;
    float _hvReadbackCorrB;
    float _hvramp_b_up;
    float _hvramp_b_down;
    float _vsetalarm_b_vtol;
    float _ilowalarm_b_vmin;
    float _ilowalarm_b_imin;
    float _vhighalarm_b_vmax;
    float _ihighalarm_b_imax;
    

    uint32_t hvAVoltageDACSetValue;
    uint32_t hvBVoltageDACSetValue;
    float _hvAVoltageReadValue;
    float _hvBVoltageReadValue;
    float _hvACurrentReadValue;
    float _hvBCurrentReadValue;
    uint32_t _hvAVoltageTargetValue;
    uint32_t _hvBVoltageTargetValue;
    BOOL _calcCMOSRatesFromCounts;
    uint32_t _hvCMOSReadsCounter;
    uint32_t _hvACMOSRateLimit;
    uint32_t _hvBCMOSRateLimit;
    uint32_t _hvACMOSRateIgnore;
    uint32_t _hvBCMOSRateIgnore;
    uint32_t _hvANextStepValue;
    uint32_t _hvBNextStepValue;
    NSLock* hvInitLock;
    NSThread* hvInitThread;
    NSThread* hvThread;
    NSDateFormatter* xl3DateFormatter;
    float _xl3VltThreshold[12];
    BOOL _isXl3VltThresholdInInit;
    int _xl3LinkTimeOut;
    BOOL _xl3InitInProgress;
    id <snotDbDelegate> _snotDb;
    
    MB safe_bundle[16];
    MB ecal_bundle[16];
    MB hw_bundle[16];
    MB ui_bundle[16];
    uint32_t _ecal_received;
    bool _ecalToOrcaInProgress;

    bool initialized;
    bool stateUpdated;

    BOOL changingPedMask;
}

@property (nonatomic,assign) uint32_t xl3MegaBundleDataId;
@property (nonatomic,assign) uint32_t pmtBaseCurrentDataId;
@property (nonatomic,assign) uint32_t cmosRateDataId;
@property (nonatomic,assign) uint32_t xl3FifoDataId;
@property (nonatomic,assign) uint32_t xl3HvDataId;
@property (nonatomic,assign) uint32_t xl3VltDataId;
@property (nonatomic,assign) uint32_t fecVltDataId;

@property (nonatomic,assign) uint32_t xl3ChargeInjMask;
@property (nonatomic,assign) unsigned char xl3ChargeInjCharge;
@property (nonatomic,assign) unsigned short pollXl3Time;
@property (nonatomic,assign) BOOL isPollingXl3;
@property (nonatomic,assign) BOOL isPollingCMOSRates;
@property (nonatomic,assign) unsigned short pollCMOSRatesMask;
@property (nonatomic,assign) BOOL isPollingPMTCurrents;
@property (nonatomic,assign) unsigned short pollPMTCurrentsMask;
@property (nonatomic,assign) BOOL isPollingFECVoltages;
@property (nonatomic,assign) unsigned short pollFECVoltagesMask;
@property (nonatomic,assign) BOOL isPollingXl3Voltages;
@property (nonatomic,assign) BOOL isPollingHVSupply;
@property (nonatomic,assign) BOOL isPollingXl3WithRun;
@property (nonatomic,assign) BOOL isPollingVerbose;
@property (nonatomic,copy) NSString* pollStatus;
@property (nonatomic,assign) BOOL isPollingForced;

@property (nonatomic,assign) uint64_t relayMask;
@property (nonatomic,assign) uint64_t relayViewMask;
@property (nonatomic,copy) NSString* relayStatus;
@property (nonatomic,assign) BOOL hvASwitch;
@property (nonatomic,assign) BOOL hvBSwitch;
@property (nonatomic,assign) BOOL isTriggerON;
//ADC counts (3kV 12bit)
@property (nonatomic,assign) uint32_t hvAVoltageDACSetValue;
@property (nonatomic,assign) uint32_t hvBVoltageDACSetValue;
//volts
@property (nonatomic,assign) float hvAVoltageReadValue;
@property (nonatomic,assign) float hvBVoltageReadValue;
//mili amps
@property (nonatomic,assign) float hvACurrentReadValue;
@property (nonatomic,assign) float hvBCurrentReadValue;
//ADC counts (3kV 12bit)
@property (nonatomic,assign) uint32_t hvAVoltageTargetValue;
@property (nonatomic,assign) uint32_t hvBVoltageTargetValue;
//volts
@property (nonatomic,assign) uint32_t hvNominalVoltageA;
@property (nonatomic,assign) uint32_t hvNominalVoltageB;
@property (nonatomic,assign) BOOL calcCMOSRatesFromCounts;
@property (nonatomic,assign) uint32_t hvACMOSRateLimit;
@property (nonatomic,assign) uint32_t hvBCMOSRateLimit;
@property (nonatomic,assign) uint32_t hvACMOSRateIgnore;
@property (nonatomic,assign) uint32_t hvBCMOSRateIgnore;
//ADC counts (3kV 12bit)
@property (nonatomic,assign) uint32_t hvANextStepValue;
@property (nonatomic,assign) uint32_t hvBNextStepValue;
@property (nonatomic,assign) uint32_t hvCMOSReadsCounter;
@property (nonatomic,assign) BOOL isXl3VltThresholdInInit;
@property (nonatomic,assign) int xl3LinkTimeOut;
@property (nonatomic,assign) BOOL xl3InitInProgress;
@property (assign) uint32_t ecal_received; //set accross multiple threads
@property (nonatomic,assign) bool ecalToOrcaInProgress;
@property (assign) id snotDb;//I replaced 'weak' by 'assign' to get Orca compiled under 10.6 (-tb- 2013-09)


@property float hvReadbackCorrA;
@property float hvramp_a_up;
@property float hvramp_a_down;
@property float vsetalarm_a_vtol;
@property float ilowalarm_a_vmin;
@property float ilowalarm_a_imin;
@property float vhighalarm_a_vmax;
@property float ihighalarm_a_imax;

@property float hvReadbackCorrB;
@property float hvramp_b_up;
@property float hvramp_b_down;
@property float vsetalarm_b_vtol;
@property float ilowalarm_b_vmin;
@property float ilowalarm_b_imin;
@property float vhighalarm_b_vmax;
@property float ihighalarm_b_imax;

@property BOOL hvAQueryWaiting;
@property BOOL hvBQueryWaiting;
@property BOOL hvAFromDB;
@property BOOL hvBFromDB;
@property BOOL hvEverUpdated;
@property BOOL hvSwitchEverUpdated;
@property BOOL hvARamping;
@property BOOL hvBRamping;
@property BOOL hvANeedsUserIntervention;
@property BOOL hvBNeedsUserIntervention;
@property BOOL isLoaded;

#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) wakeUp;
- (void) sleep;

- (void) awakeAfterDocumentLoaded;

- (void) registerNotificationObservers;
- (void) connectionStateChanged;
- (void) documentLoaded;
- (void) documentClosed;
- (void) detectorStateChanged:(NSNotification*)aNote;
- (int) initAtRunStart;
- (void) zeroPedestalMasksAtRunStart;

#pragma mark •••Accessors
- (BOOL) isTriggerON;
- (void) setIsTriggerON: (BOOL) isTriggerON;
- (bool) initialized;
- (bool) stateUpdated;
- (NSString*) shortName;
- (id) controllerCard;
- (void) setSlot:(int)aSlot;
- (XL3_Link*) xl3Link;
- (void) setXl3Link:(XL3_Link*) aXl3Link;
- (void) setGuardian:(id)aGuardian;
- (short) getNumberRegisters;
- (NSString*) getRegisterName:(short) anIndex;
- (uint32_t) getRegisterAddress: (short) anIndex;
- (BOOL) basicOpsRunning;
- (void) setBasicOpsRunning:(BOOL)aBasicOpsRunning;
- (BOOL) compositeXl3ModeRunning;
- (void) setCompositeXl3ModeRunning:(BOOL)aCompositeXl3ModeRunning;
- (uint32_t) slotMask;
- (void) setSlotMask:(uint32_t)aSlotMask;
- (BOOL) autoIncrement;
- (void) setAutoIncrement:(BOOL)aAutoIncrement;
- (unsigned short) repeatDelay;
- (void) setRepeatDelay:(unsigned short)aRepeatDelay;
- (short) repeatOpCount;
- (void) setRepeatOpCount:(short)aRepeatCount;
- (uint32_t) writeValue;
- (void) setWriteValue:(uint32_t)aWriteValue;
- (unsigned int) xl3Mode;
- (void) setXl3Mode:(unsigned int)aXl3Mode;
- (BOOL) xl3ModeRunning;
- (void) setXl3ModeRunning:(BOOL)anXl3ModeRunning;
- (uint32_t) xl3RWAddressValue;
- (void) setXl3RWAddressValue:(uint32_t)anXl3RWAddressValue;
- (uint32_t) xl3RWDataValue;
- (void) setXl3RWDataValue:(uint32_t)anXl3RWDataValue;
- (BOOL) xl3OpsRunningForKey:(id)aKey;
- (void) setXl3OpsRunning:(BOOL)anXl3OpsRunning forKey:(id)aKey;
- (uint32_t) xl3PedestalMask;
- (void) setXl3PedestalMask:(uint32_t)anXl3PedestalMask;
- (float) xl3VltThreshold:(unsigned short)idx;
- (void) setXl3VltThreshold:(unsigned short)idx withValue:(float)aThreashold;

- (int) selectedRegister;
- (void) setSelectedRegister:(int)aSelectedRegister;
- (NSString*) xl3LockName;
- (NSComparisonResult) XL3NumberCompare:(id)aCard;
+ (void) setOwlSupplyOn:(BOOL)isOn;
+ (BOOL) owlSupplyOn;
- (BOOL) isOwlCrate;
- (BOOL) changingPedMask;

#pragma mark •••DB Helpers
- (void) synthesizeDefaultsIntoBundle:(MB*)aBundle forSlot:(unsigned short)aSlot;
- (void) byteSwapBundle:(MB*)aBundle;
- (void) synthesizeFECIntoBundle:(MB*)aBundle forSlot:(unsigned short)aSlot;
- (ORCouchDB*) debugDBRef;
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp;
- (void) fetchECALSettings;
- (void) ecalToOrcaDocumentsReceived;
- (void) parseEcalDocument:(NSDictionary*)aResult;
- (void) updateUIFromEcalBundle:(NSDictionary*)aBundle slot:(unsigned int)aSlot;
- (BOOL) isRelayClosedForSlot:(unsigned int)slot pc:(unsigned int)aPC;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Hardware Access
- (void) nominalSettingsCallback: (ORPQResult *) result;
- (void) loadNominalSettings;
- (void) _loadTriggersAndSequencers;
- (void) loadTriggersAndSequencers;
- (void) loadTriggers;
- (void) loadTriggersWithCrateMask:(NSArray*)XL3Mask;
- (void) disableTriggers;
- (void) loadSequencers;
- (void) selectCards:(uint32_t) selectBits;
- (void) deselectCards;
- (void) select:(ORSNOCard*) aCard;
- (void) writeHardwareRegister:(uint32_t) anAddress value:(uint32_t) aValue;
- (uint32_t) readHardwareRegister:(uint32_t) regAddress;
- (void) writeHardwareMemory:(uint32_t) memAddress value:(uint32_t) aValue;
- (uint32_t) readHardwareMemory:(uint32_t) memAddress;
- (void) writeXL3Register:(short)aRegister value:(uint32_t)aValue;
- (uint32_t) readXL3Register:(short)aRegister;

- (int) updateXl3Mode;
- (int) setSequencerMask: (uint32_t) mask forSlot: (int) slot;
- (void) resetCrate;
- (void) resetCrateAsync;
- (void) initCrate;
- (void) initCrateDone: (CrateInitResults *)r;
- (void) loadHardware;
- (void) loadHardwareWithSlotMask: (uint32_t) slotMask;
- (void) loadHardwareWithSlotMask: (uint32_t) slotMask withCallback: (SEL) callback target: (id) target;
- (void) initCrateAsync: (uint32_t) slotMask withCallback: (SEL) callback target: (id) target;
- (void) initCrateAsyncThread: (NSDictionary *) args;
- (void) initCrate: (MB *) mbs slotMask: (uint32_t) slotMask withCallback: (SEL) callback target: (id) target;
- (int) initCrate: (MB *) mbs slotMask: (uint32_t) slotMask results: (CrateInitResults *) results;
- (void) checkCrateConfig: (ResetCrateResults *)r;

- (uint32_t) getSlotsPresent;

#pragma mark •••Basic Ops
- (void) readBasicOps;
- (void) writeBasicOps;
- (void) stopBasicOps;
- (void) reportStatus;

#pragma mark •••Composite
- (void) deselectComposite;
- (void) writeXl3Mode: (uint32_t) mode;
- (void) writeXl3Mode: (uint32_t) mode withSlotMask: (uint32_t) slotMask;
- (void) compositeXl3RW;
- (void) compositeQuit;
- (int) setPedestals;
- (int) multiSetPedestalMask: (uint32_t) slotMask patterns: (uint32_t[16]) patterns;
- (int) setPedestalMask: (uint32_t) slotMask pattern: (uint32_t) pattern;
- (void) compositeSetPedestal;
- (void) setPedestalInParallel;
- (void) zeroPedestalMasks;
- (unsigned short) getBoardIDForSlot:(unsigned short)aSlot chip:(unsigned short)aChip;
- (void) getBoardIDs;
- (void) compositeResetCrate;
- (void) compositeResetCrateAndXilinX;
- (void) compositeResetFIFOAndSequencer;
- (void) compositeResetXL3StateMachine;
- (void) compositeEnableChargeInjection;
- (void) reset;
- (void) enableChargeInjectionForSlot:(unsigned short)aSlot channelMask:(uint32_t)aChannelMask;

#pragma mark •••HV
- (void) readCMOSCountWithArgs:(CheckTotalCountArgs*)aSlot counts:(CheckTotalCountResults*)aCounts;
- (void) readCMOSCountForSlot:(unsigned short)aSlot withChannelMask:(uint32_t)aChannelMask;
- (void) readCMOSCount;

- (void) readCMOSRateWithArgs:(CrateNoiseRateArgs*)aArgs rates:(CrateNoiseRateResults*)aRates;
- (void) readCMOSRateForSlot:(unsigned short)aSlot withChannelMask:(uint32_t)aChannelMask withDelay:(uint32_t)aDelay;
- (void) readCMOSRate;

- (void) readPMTBaseCurrentsWithArgs:(ReadPMTCurrentArgs*)aArg currents:(ReadPMTCurrentResults*)result;
- (void) readPMTBaseCurrentsForSlot:(unsigned short)aSlot withChannelMask:(uint32_t)aChannelMask;
- (void) readPMTBaseCurrents;

- (void) readHVStatus:(HVReadbackResults*)status;
- (void) readHVStatus;

- (void) hvUserIntervention:(BOOL)forA;

- (void) setHVRelays:(uint64_t)relayMask error:(uint32_t*)aError;
- (void) setHVRelays:(uint64_t)relayMask;
- (void) readHVRelays:(uint64_t*) relayMask isKnown:(BOOL*)isKnown;
- (void) closeHVRelays;
- (void) openHVRelays;

- (void) setHVSwitchOnForA:(BOOL)aIsOn forB:(BOOL)bIsOn;
- (void) readHVSwitchOnForA:(BOOL*)aIsOn forB:(BOOL*)bIsOn;
- (void) readHVSwitchOn;

- (uint32_t) checkRelays:(uint64_t)relays;
- (BOOL) isHVAdvisable:(unsigned char) sup;

+ (bool) requestHVParams:(ORXL3Model *)model;
- (void) safeHvInit;
- (void) setHVSwitch:(BOOL)aOn forPowerSupply:(unsigned char)sup;
- (void) _hvPanicDown;
- (void) hvPanicDown;
- (void) hvTriggersON;
- (void) hvTriggersOFF;
- (void) readHVInterlockGood:(BOOL*)isGood;
- (void) readHVInterlock;
- (void) setHVDacA:(unsigned short)aDac dacB:(unsigned short)bDac;

#pragma mark •••tests
- (void) readVMONForSlot:(unsigned short)aSlot voltages:(VMonResults*)aVoltages;
- (void) readVMONForSlot:(unsigned short)aSlot;
- (void) readVMONWithMask:(unsigned short)aSlotMask;
- (void) readVMONXL3:(LocalVMonResults*)aVoltages;
- (void) readVMONXL3;
- (void) setVltThreshold;

- (void) pollXl3:(BOOL)forceFlag;

- (void) loadSingleDacForSlot:(unsigned short)aSlot dacNum:(unsigned short)aDacNum dacVal:(unsigned char)aDacVal;
- (void) setVthrDACsForSlot:(unsigned short)aSlot withChannelMask:(uint32_t)aChannelMask dac:(unsigned char)aDac;

- (id) writeHardwareRegisterCmd:(uint32_t) aRegister value:(uint32_t) aBitPattern;
- (id) readHardwareRegisterCmd:(uint32_t) regAddress;
- (void) executeCommandList:(ORCommandList*)aList;
- (id) delayCmd:(uint32_t) milliSeconds;

@end

extern NSString* ORXL3ModelSelectedRegisterChanged;
extern NSString* ORXL3ModelRepeatCountChanged;
extern NSString* ORXL3ModelRepeatDelayChanged;
extern NSString* ORXL3ModelAutoIncrementChanged;
extern NSString* ORXL3ModelBasicOpsRunningChanged;
extern NSString* ORXL3ModelWriteValueChanged;
extern NSString* ORXL3ModelXl3ModeChanged;
extern NSString* ORXL3ModelSlotMaskChanged;
extern NSString* ORXL3ModelXl3ModeRunningChanged;
extern NSString* ORXL3ModelXl3RWAddressValueChanged;
extern NSString* ORXL3ModelXl3RWDataValueChanged;
extern NSString* ORXL3ModelXl3OpsRunningChanged;
extern NSString* ORXL3ModelXl3PedestalMaskChanged;
extern NSString* ORXL3ModelXl3ChargeInjChanged;
extern NSString* ORXL3ModelPollXl3TimeChanged;
extern NSString* ORXL3ModelIsPollingXl3Changed;
extern NSString* ORXL3ModelIsPollingCMOSRatesChanged;
extern NSString* ORXL3ModelPollCMOSRatesMaskChanged;
extern NSString* ORXL3ModelIsPollingPMTCurrentsChanged;
extern NSString* ORXL3ModelPollPMTCurrentsMaskChanged;
extern NSString* ORXL3ModelIsPollingFECVoltagesChanged;
extern NSString* ORXL3ModelPollFECVoltagesMaskChanged;
extern NSString* ORXL3ModelIsPollingXl3VoltagesChanged;
extern NSString* ORXL3ModelIsPollingHVSupplyChanged;
extern NSString* ORXL3ModelIsPollingXl3WithRunChanged;
extern NSString* ORXL3ModelPollStatusChanged;
extern NSString* ORXL3ModelIsPollingVerboseChanged;
extern NSString* ORXL3ModelRelayMaskChanged;
extern NSString* ORXL3ModelRelayStatusChanged;
extern NSString* ORXL3ModelHvStatusChanged;
extern NSString* ORXL3ModelTriggerStatusChanged;
extern NSString* ORXL3ModelHVTargetValueChanged;
extern NSString* ORXL3ModelHVNominalVoltageChanged;
extern NSString* ORXL3ModelHVCMOSRateLimitChanged;
extern NSString* ORXL3ModelHVCMOSRateIgnoreChanged;
extern NSString* ORXL3ModelXl3VltThresholdChanged;
extern NSString* ORXL3ModelXl3VltThresholdInInitChanged;
extern NSString* ORXL3Lock;
extern NSString* ORXL3ModelStateChanged;
