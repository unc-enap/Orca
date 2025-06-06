/*
 *  ORMTCModel.h
 *  Orca
 *
 *  Created by Mark Howe on Fri, May 2, 2008
 *  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
 *
 */
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

#import "ORVmeIOCard.h"
#import "RedisClient.h"
#import "ORPQResult.h"
#include <stdint.h>

@class ORMTC_DB;
@class ORReadOutList;

#define MTCLockOutWidth @"MTCLockOutWidth"
#define FIRST_MTC_THRESHOLD_INDEX 0
#define MTC_N100_LO_THRESHOLD_INDEX  0
#define MTC_N100_MED_THRESHOLD_INDEX 1
#define MTC_N100_HI_THRESHOLD_INDEX  2
#define MTC_N20_THRESHOLD_INDEX      3
#define MTC_N20LB_THRESHOLD_INDEX    4
#define MTC_ESUML_THRESHOLD_INDEX    5
#define MTC_ESUMH_THRESHOLD_INDEX    6
#define MTC_OWLN_THRESHOLD_INDEX     7
#define MTC_OWLELO_THRESHOLD_INDEX   8
#define MTC_OWLEHI_THRESHOLD_INDEX   9
#define LAST_MTC_THRESHOLD_INDEX 9
#define MTC_NUM_THRESHOLDS 14  // The number of thresholds that exist
#define MTC_NUM_USED_THRESHOLDS 10 // The number of thresholds that are actually used

#define MTC_RAW_UNITS 1
#define MTC_mV_UNITS 2
#define MTC_NHIT_UNITS 3

//This defines the order at which the MTC server and database expects MTCA thresholds
#define SERVER_N100L_INDEX 0
#define SERVER_N100M_INDEX 1
#define SERVER_N100H_INDEX 2
#define SERVER_N20_INDEX   3
#define SERVER_N20LB_INDEX 4
#define SERVER_ESUML_INDEX 5
#define SERVER_ESUMH_INDEX 6
#define SERVER_OWLN_INDEX  7
#define SERVER_OWLEL_INDEX 8
#define SERVER_OWLEH_INDEX 9


@interface ORMTCModel :  ORVmeIOCard
{
@private
    uint16_t                lockoutWidth;
    uint16_t                pedestalWidth;
    float                   pgtRate;
    uint32_t                gtMask;
    uint32_t                GTCrateMask;
    uint32_t                pedCrateMask;
    uint16_t                prescaleValue;
    int                     fineDelay;
    int                     coarseDelay;

    //basic ops
    int                     selectedRegister;
    uint32_t			memoryOffset;
    uint32_t			writeValue;
    short					repeatOpCount;
    unsigned short			repeatDelay;
    int						useMemory;
    uint32_t			workingCount;
    BOOL				doReadOp;
    BOOL				autoIncrement;
    BOOL				basicOpsRunning;
    BOOL				isPulserFixedRate;
    uint32_t			fixedPulserRateCount;
    float				fixedPulserRateDelay;
    BOOL _isPedestalEnabledInCSR;
    BOOL _pulserEnabled;
    
    //MTCA+ crate masks
    uint32_t _mtcaN100Mask;
    uint32_t _mtcaN20Mask;
    uint32_t _mtcaEHIMask;
    uint32_t _mtcaELOMask;
    uint32_t _mtcaOELOMask;
    uint32_t _mtcaOEHIMask;
    uint32_t _mtcaOWLNMask;

    int tubRegister;

    uint16_t mtca_thresholds[MTC_NUM_THRESHOLDS];
    uint16_t mtca_baselines[MTC_NUM_THRESHOLDS];
    float mtca_dac_per_nhit[MTC_NUM_THRESHOLDS]; //Let the ESUMs have a conversion in case we ever need it
    float mtca_dac_per_mV[MTC_NUM_THRESHOLDS];
    BOOL mtca_conversion_is_valid[MTC_NUM_THRESHOLDS];
    RedisClient *mtc;
}

@property (nonatomic,assign) uint16_t lockoutWidth;
@property (nonatomic,assign) uint16_t pedestalWidth;
@property (nonatomic,assign) float    pgtRate;
@property (nonatomic,assign) int      fineDelay;
@property (nonatomic,assign) int      coarseDelay;
@property (nonatomic,assign) uint32_t gtMask;
@property (nonatomic,assign) uint16_t prescaleValue;
@property (nonatomic,assign) uint32_t GTCrateMask;
@property (nonatomic,assign) uint32_t pedCrateMask;

@property (nonatomic,assign) BOOL isPulserFixedRate;
@property (nonatomic,assign) uint32_t fixedPulserRateCount;
@property (nonatomic,assign) float fixedPulserRateDelay;

@property (nonatomic,assign) uint32_t mtcaN100Mask;
@property (nonatomic,assign) uint32_t mtcaN20Mask;
@property (nonatomic,assign) uint32_t mtcaEHIMask;
@property (nonatomic,assign) uint32_t mtcaELOMask;
@property (nonatomic,assign) uint32_t mtcaOELOMask;
@property (nonatomic,assign) uint32_t mtcaOEHIMask;
@property (nonatomic,assign) uint32_t mtcaOWLNMask;
@property (nonatomic,assign) BOOL isPedestalEnabledInCSR;
@property (nonatomic,assign) BOOL pulserEnabled;

// The TUB register is no longer used in SNO+
// but maybe someday it will be. So I'll leave it in here.
@property (nonatomic,assign) int tubRegister;

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (BOOL) solitaryObject;

- (void) setMTCPort: (int) port;
- (void) setMTCHost: (NSString *) host;

- (void) awakeAfterDocumentLoaded;

- (void) registerNotificationObservers;
- (int) initAtRunStart: (int) loadTriggers;
- (void) detectorStateChanged:(NSNotification*)aNote;

// DB Access
- (void) getLatestTriggerScans;
- (void) updateTriggerThresholds;

- (int) triggerScanNameToIndex:(NSString*) name;
- (void) waitForTriggerScan: (ORPQResult *) result;
- (void) waitForThresholds: (ORPQResult *) result;

#pragma mark •••Accessors
- (RedisClient *) mtc;
- (BOOL) basicOpsRunning;
- (void) setBasicOpsRunning:(BOOL)aBasicOpsRunning;
- (BOOL) autoIncrement;
- (void) setAutoIncrement:(BOOL)aAutoIncrement;
- (int) useMemory;
- (void) setUseMemory:(int)aUseMemory;
- (unsigned short) repeatDelay;
- (void) setRepeatDelay:(unsigned short)aRepeatDelay;
- (short) repeatOpCount;
- (void) setRepeatOpCount:(short)aRepeatCount;
- (uint32_t) writeValue;
- (void) setWriteValue:(uint32_t)aWriteValue;
- (uint32_t) memoryOffset;
- (void) setMemoryOffset:(uint32_t)aMemoryOffset;
- (int) selectedRegister;
- (void) setSelectedRegister:(int)aSelectedRegister;
- (uint32_t) memBaseAddress;
- (uint32_t) memAddressModifier;
- (uint32_t) baseAddress;

- (float) getThresholdOfType:(int) type inUnits:(int) units;
- (void) setThresholdOfType:(int) type fromUnits: (int) units toValue:(float) aThreshold;

- (uint16_t) getBaselineOfType:(int) type;
- (void) setBaselineOfType:(int) type toValue:(uint16_t) _val;

- (float) dacPerNHit:(int) type;
- (void) setDacPerNHit:(int) type toValue:(float) _val;

- (float) DacPerMilliVoltOfType:(int) type;
- (void) setDacPerMilliVoltOfType:(int) type toValue:(float) _val;

- (BOOL) ConversionIsValidForThreshold:(int) type;
- (void) setConversionIsValidForThreshold:(int) type isValid:(BOOL) _val;


- (NSString*) stringForThreshold:(int) threshold_index;
- (id) objectFromSerialization: (NSMutableDictionary*) serial withKey:(NSString*)str;
- (void) loadFromSerialization:(NSMutableDictionary*) serial;
- (NSMutableDictionary*) serializeToDictionary;

- (BOOL) thresholdIndexIsValid:(int) index;
- (BOOL) thresholdIsNHit:(int) index;

#pragma mark •••Converters
- (float) convertThreshold:(float)aThreshold OfType:(int) type fromUnits:(int)in_units toUnits:(int) out_units;
- (int) server_index_to_model_index:(int) server_index;
- (int) model_index_to_server_index:(int) model_index;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••HW Access
- (BOOL) adapterIsSBC;
- (short) getNumberRegisters;
- (NSString*) getRegisterName:(short) anIndex;
- (uint32_t) read:(int)aReg;
- (void) write:(int)aReg value:(uint32_t)aValue;
- (void) setBits:(int)aReg mask:(uint32_t)aMask;
- (void) clrBits:(int)aReg mask:(uint32_t)aMask;
- (void) sendMTC_SoftGt;
- (void) sendMTC_SoftGt:(BOOL) setGTMask;
- (void) initializeMtc;
- (void) initializeMtcDone;
- (void) server_init;
- (void) clearGlobalTriggerWordMask;
- (void) setGlobalTriggerWordMask;
- (uint32_t) getGTMaskFromHardware;
- (void) setSingleGTWordMask:(uint32_t) gtWordMask;
- (void) clearSingleGTWordMask:(uint32_t) gtWordMask;
- (void) clearPedestalCrateMask;
- (void) clearGTCrateMask;
- (uint32_t) getGTCrateMaskFromHardware;
- (void) loadPedestalCrateMaskToHardware;
- (void) loadGTCrateMaskToHardware;
- (void) clearTheControlRegister;
- (void) resetTheMemory;
- (void) setTheGTCounter:(uint32_t) theGTCounterValue;
- (void) zeroTheGTCounter;
- (void) setThe10MHzCounter:(uint64_t) newValue;
- (void) loadPrescaleValueToHardware;
- (void) loadCoarseDelayToHardware;
- (void) loadFineDelayToHardware;
- (void) loadPulserRateToHardware;
- (void) loadLockOutWidthToHardware;
- (void) loadPedWidthToHardware;
- (void) enablePulser;
- (void) disablePulser;
- (void) enablePedestal;
- (void) disablePedestal;
- (void) fireMTCPedestalsFixedRate;
- (void) continueMTCPedestalsFixedRate;
- (void) stopMTCPedestalsFixedRate;
- (void) basicMTCPedestalGTrigSetup;
- (void) fireMTCPedestalsFixedTime;
- (void) stopMTCPedestalsFixedTime;
- (void) firePedestals:(uint32_t) count withRate:(float) rate;
- (void) basicMTCReset;
- (void) validateMTCADAC:(uint16_t) dac_value;
- (void) loadTheMTCADacs;
- (void) loadMTCXilinx;
- (void) loadTubRegister;

- (void) loadMTCACrateMapping;
- (void) mtcatResetMtcat:(unsigned char) mtcat;
- (void) mtcatResetAll;
- (void) mtcatLoadCrateMasks;
- (void) mtcatClearCrateMasks;
- (void) mtcatLoadCrateMask:(uint32_t) mask toMtcat:(unsigned char) mtcat;

#pragma mark •••BasicOps
- (void) readBasicOps;
- (void) writeBasicOps;
- (void) stopBasicOps;
@end
extern NSString* GTMaskSerializationString;
extern NSString* PulserRateSerializationString;
extern NSString* PGT_PED_Mode_SerializationString;
extern NSString* PulserEnabledSerializationString;
extern NSString* PrescaleValueSerializationString;
extern NSString* ORMTCSettingsChanged;
extern NSString* ORMTCModelBasicOpsRunningChanged;
extern NSString* ORMTCABaselineChanged;
extern NSString* ORMTCAThresholdChanged;
extern NSString* ORMTCAConversionChanged;
extern NSString* ORMTCModelAutoIncrementChanged;
extern NSString* ORMTCModelUseMemoryChanged;
extern NSString* ORMTCModelRepeatDelayChanged;
extern NSString* ORMTCModelRepeatCountChanged;
extern NSString* ORMTCModelWriteValueChanged;
extern NSString* ORMTCModelMemoryOffsetChanged;
extern NSString* ORMTCModelSelectedRegisterChanged;
extern NSString* ORMTCModelIsPulserFixedRateChanged;
extern NSString* ORMTCModelFixedPulserRateCountChanged;
extern NSString* ORMTCModelFixedPulserRateDelayChanged;
extern NSString* ORMtcTriggerNameChanged;
extern NSString* ORMTCBasicLock;
extern NSString* ORMTCStandardOpsLock;
extern NSString* ORMTCSettingsLock;
extern NSString* ORMTCTriggersLock;
extern NSString* ORMTCModelMTCAMaskChanged;
extern NSString* ORMTCModelIsPedestalEnabledInCSR;
extern NSString* ORMTCPulserRateChanged;
extern NSString* ORMTCGTMaskChanged;
extern NSString* LockOutWidthSerializationString;
