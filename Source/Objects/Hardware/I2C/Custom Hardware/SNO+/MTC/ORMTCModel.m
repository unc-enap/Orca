/*
 *  ORMTCModel.cpp
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
#import "ORMTCModel.h"
#import "ORVmeCrateModel.h"
#import "ORMTC_Constants.h"
#import "NSDictionary+Extensions.h"
#import "SNOCmds.h"
#import "ORSelectorSequence.h"
#import "ORRunModel.h"
#import "ORRunController.h"
#import "ORPQModel.h"
#import "SNOPModel.h"

#pragma mark •••Definitions
NSString* GTMaskSerializationString             = @"MTC_GTMask";
NSString* PrescaleValueSerializationString      = @"MTC_PrescaleValue";
NSString* PulserRateSerializationString         = @"MTC_PulserRate";
NSString* PGT_PED_Mode_SerializationString      = @"MTC_PulserMode";
NSString* PulserEnabledSerializationString      = @"MTC_PulserEnabled";
NSString* LockOutWidthSerializationString       = @"MTC_LockoutWidth";
NSString* ORMTCSettingsChanged                  = @"ORMTCSettingsChanged";
NSString* ORMTCModelBasicOpsRunningChanged      = @"ORMTCModelBasicOpsRunningChanged";
NSString* ORMTCABaselineChanged                 = @"ORMTCABaselineChanged";
NSString* ORMTCAThresholdChanged                = @"ORMTCAThresholdChanged";
NSString* ORMTCAConversionChanged               = @"ORMTCAConversionChanged";
NSString* ORMTCModelAutoIncrementChanged        = @"ORMTCModelAutoIncrementChanged";
NSString* ORMTCModelUseMemoryChanged            = @"ORMTCModelUseMemoryChanged";
NSString* ORMTCModelRepeatDelayChanged          = @"ORMTCModelRepeatDelayChanged";
NSString* ORMTCModelRepeatCountChanged          = @"ORMTCModelRepeatCountChanged";
NSString* ORMTCModelWriteValueChanged           = @"ORMTCModelWriteValueChanged";
NSString* ORMTCModelMemoryOffsetChanged         = @"ORMTCModelMemoryOffsetChanged";
NSString* ORMTCModelSelectedRegisterChanged     = @"ORMTCModelSelectedRegisterChanged";
NSString* ORMTCModelIsPulserFixedRateChanged	= @"ORMTCModelIsPulserFixedRateChanged";
NSString* ORMTCModelFixedPulserRateCountChanged = @"ORMTCModelFixedPulserRateCountChanged";
NSString* ORMTCModelFixedPulserRateDelayChanged = @"ORMTCModelFixedPulserRateDelayChanged";
NSString* ORMtcTriggerNameChanged               = @"ORMtcTriggerNameChanged";
NSString* ORMTCBasicLock                        = @"ORMTCBasicLock";
NSString* ORMTCStandardOpsLock                  = @"ORMTCStandardOpsLock";
NSString* ORMTCSettingsLock                     = @"ORMTCSettingsLock";
NSString* ORMTCTriggersLock                     = @"ORMTCTriggersLock";
NSString* ORMTCModelMTCAMaskChanged             = @"ORMTCModelMTCAMaskChanged";
NSString* ORMTCModelIsPedestalEnabledInCSR      = @"ORMTCModelIsPedestalEnabledInCSR";
NSString* ORMTCPulserRateChanged                = @"ORMTCPulserRateChanged";
NSString* ORMTCGTMaskChanged                    = @"ORMTCGTMaskChanged";


#define kMTCRegAddressBase		0x00007000
#define kMTCRegAddressModifier	0x29
#define kMTCRegAddressSpace		0x01
#define kMTCMemAddressBase		0x03800000
#define kMTCMemAddressModifier	0x09
#define kMTCMemAddressSpace		0x02

static SnoMtcNamesStruct reg[kMtcNumRegisters] = {
{ @"ControlReg"	    , 0   ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //0
{ @"SerialReg"		, 4   ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //1
{ @"DacCntReg"		, 8   ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //2
{ @"SoftGtReg"		, 12  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //3
{ @"Pedestal Width"	, 16  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //4
{ @"Coarse Delay"	, 20  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //5
{ @"Fine Delay"		, 24  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //6
{ @"ThresModReg"	, 28  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //7
{ @"PmskReg"		, 32  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //8
{ @"ScaleReg"		, 36  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //9
{ @"BwrAddOutReg"	, 40  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //10
{ @"BbaReg"		, 44  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //11
{ @"GtLockReg"		, 48  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //12
{ @"MaskReg"		, 52  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //13
{ @"XilProgReg"		, 56  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //14
{ @"GmskReg"		, 60  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //15
{ @"OcGtReg"		, 128 ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //16
{ @"C50_0_31Reg"	, 132 ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //17
{ @"C50_32_42Reg"	, 136  ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //18
{ @"C10_0_31Reg"	, 140 ,kMTCRegAddressModifier, kMTCRegAddressSpace },   //19
{ @"C10_32_52Reg"	, 144 ,kMTCRegAddressModifier, kMTCRegAddressSpace }	//20
};


@interface ORMTCModel (private)
- (void) doBasicOp;
- (void) setupDefaults;
@end

@implementation ORMTCModel

@synthesize
pulserEnabled = _pulserEnabled,
tubRegister;

- (id) init //designated initializer
{
    self = [super init];

    [self registerNotificationObservers];

    /* initialize our connection to the MTC server */
    mtc = [[RedisClient alloc] init];
    [[self undoManager] disableUndoRegistration];

    [[self undoManager] enableUndoRegistration];
	[self setFixedPulserRateCount: 1];
	[self setFixedPulserRateDelay: 10];
    [self setupDefaults];

    /* We need to sync the MTC server hostname and port with the SNO+ model.
     * Usually this is done in the awakeAfterDocumentLoaded function, because
     * there we are guaranteed that the SNO+ model already exists.
     * We call updateSettings here too though to cover the case that this
     * object was added to an already existing experiment in which case
     * awakeAfterDocumentLoaded is not called. */
    [self updateSettings];
    return self;
}

- (void) updateSettings
{
    NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOPModel")];

    SNOPModel* sno;
    if ([objs count] == 0) return;

    sno = [objs objectAtIndex:0];
    [self setMTCHost:[sno mtcHost]];
    [self setMTCPort:[sno mtcPort]];

    for (int i = 0; i < MTC_NUM_THRESHOLDS; i++) {
        mtca_conversion_is_valid[i] = NO;
    }
}

- (void) awakeAfterDocumentLoaded
{
    [self updateSettings];
    [self getLatestTriggerScans];
}

- (void) setMTCPort: (int) port
{
    [mtc setPort:port];
    [mtc disconnect];
}

- (void) setMTCHost: (NSString *) host
{
    [mtc setHost:host];
    [mtc disconnect];
}

- (void) dealloc
{
    [mtc release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MTCCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORMTCController"];
}

- (void) wakeUp
{
    [super wakeUp];
}

- (BOOL) solitaryObject
{
    return YES;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(detectorStateChanged:)
                         name : ORPQDetectorStateChanged
                       object : nil];
}

- (int) initAtRunStart:(int) loadTriggers
{
    /* Initialize all hardware from the model at run start. If loadTriggers
     * is true, then load the GT mask, otherwise, clear the GT mask.
     * Returns 0 on success, -1 on failure. */

    @try {
        /* Setup MTCD pedestal/pulser settings */
        if ([self isPedestalEnabledInCSR]) {
            [self enablePedestal];
        } else {
            [self disablePedestal];
        }
        if ([self pulserEnabled]) [self enablePulser];

        [self loadCoarseDelayToHardware];
        [self loadFineDelayToHardware];
        /* Temporary hack to make sure we don't run with a lockout width of
         * 5100 after a power cycle. Eventually, the lockout width should be in
         * the standard run definition. */
        [self setLockoutWidth:420];
        [self loadLockOutWidthToHardware];
        [self loadPedWidthToHardware];
        [self loadPulserRateToHardware];
        [self loadPrescaleValueToHardware];
        /* Setup Pedestal Crate Mask */
        [self loadPedestalCrateMaskToHardware];

        /* Setup GT Crate Mask */
        [self loadGTCrateMaskToHardware];
        /* Clear the GT mask before setting the trigger thresholds because
         * we've noticed that changing the thresholds results in a brief
         * burst of events. */
        [self clearGlobalTriggerWordMask];

        /* Setup MTCA Thresholds */
        [self loadTheMTCADacs];

        /* Update the mapping between crates and channels on the front of the
         * MTCA+s from the detector state database. */
        [self loadMTCACrateMapping];

        /* Setup MTCA relays */
        [self mtcatLoadCrateMasks];

        if (loadTriggers) {
            /* Setup the GT mask */
            [self setSingleGTWordMask: [self gtMask]];
        }
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"error loading MTC hardware at run start: %@\n", [e reason]);
        return -1;
    }

    return 0;
}

// update MTC GUI based on current detector state
- (void) detectorStateChanged:(NSNotification*)aNote
{
    ORPQDetectorDB *detDB = [aNote object];
    PQ_MTC *pqMTC = NULL;

    if (detDB) pqMTC = (PQ_MTC *)[detDB getMTC];

    if (!pqMTC) {     // nothing to do if MTC doesn't exist in the current state
        NSLogColor([NSColor redColor], @"MTC settings not loaded!\n");
        return;
    }

    int countInvalid = 0;

    @try {
        [[self undoManager] disableUndoRegistration];

        if (pqMTC->valid[kMTC_controlReg]) {
            [self setIsPedestalEnabledInCSR:(pqMTC->controlReg & 0x01)];
        } else ++countInvalid;

        for (int i=0; i<10; ++i) {
            if (pqMTC->valid[kMTC_mtcaDacs] & (1 << i)) {
                uint32_t val = pqMTC->mtcaDacs[i];
                [self setThresholdOfType:[self server_index_to_model_index:i] fromUnits:MTC_RAW_UNITS toValue:val];
            } else ++countInvalid;
        }

        if (pqMTC->valid[kMTC_pedWidth]) {
            [self setPedestalWidth:pqMTC->pedWidth];
        } else ++countInvalid;


        if (pqMTC->valid[kMTC_fineDelay]) {
            [self setFineDelay:pqMTC->fineDelay];
        } else ++countInvalid;
        if (pqMTC->valid[kMTC_coarseDelay]) {
            [self setCoarseDelay:pqMTC->coarseDelay];
        } else ++countInvalid;

        if (pqMTC->valid[kMTC_pedMask]) {
            [self setPedCrateMask:pqMTC->pedMask];
        } else ++countInvalid;

        if (pqMTC->valid[kMTC_prescale]) {
            [self setPrescaleValue:pqMTC->prescale];
        } else ++countInvalid;

        if (pqMTC->valid[kMTC_lockoutWidth]) {
            [self setLockoutWidth:pqMTC->lockoutWidth];
        } else ++countInvalid;

        if (pqMTC->valid[kMTC_gtMask]) {
            [self setGtMask:pqMTC->gtMask];
        } else ++countInvalid;

        if (pqMTC->valid[kMTC_gtCrateMask]) {
            [self setGTCrateMask:pqMTC->gtCrateMask];
        } else ++countInvalid;

        for (int i=0; i<kNumMtcRelays; ++i) {
            if (pqMTC->valid[kMTC_mtcaRelays] & (1 << i)) {
                uint32_t val = pqMTC->mtcaRelays[i];
                switch (i) {
                    case 0:
                        [self setMtcaN100Mask:val];
                        break;
                    case 1:
                        [self setMtcaN20Mask:val];
                        break;
                    case 2:
                        [self setMtcaELOMask:val];
                        break;
                    case 3:
                        [self setMtcaEHIMask:val];
                        break;
                    case 4:
                        [self setMtcaOELOMask:val];
                        break;
                    case 5:
                        [self setMtcaOEHIMask:val];
                        break;
                    case 6:
                        [self setMtcaOWLNMask:val];
                        break;
                }
            } else ++countInvalid;
        }

        if (pqMTC->valid[kMTC_pulserRate] && pqMTC->pulserRate) { // (don't set if rate is 0)
            [self setPgtRate:pqMTC->pulserRate];
        } else ++countInvalid;
    }
    @finally {
        [[self undoManager] enableUndoRegistration];
    }
    if (countInvalid) {
        NSLogColor([NSColor redColor], @"%d MTC settings not loaded!\n", countInvalid);
    }
}

- (int) triggerScanNameToIndex:(NSString*) name
{
    int ret = -1;
    if([name isEqual:@"N100LO"]){ ret = MTC_N100_LO_THRESHOLD_INDEX; }
    else if([name isEqual:@"N100MED"]){ ret = MTC_N100_MED_THRESHOLD_INDEX; }
    else if([name isEqual:@"N100HI"]){ ret = MTC_N100_HI_THRESHOLD_INDEX; }
    else if([name isEqual:@"N20"]){ ret = MTC_N20_THRESHOLD_INDEX; }
    else if([name isEqual:@"N20LB"]){ ret = MTC_N20LB_THRESHOLD_INDEX; }
    else if([name isEqual:@"OWLN"]){ ret = MTC_OWLN_THRESHOLD_INDEX; }
    else if([name isEqual:@"ESUMLO"]){ ret = MTC_ESUML_THRESHOLD_INDEX; }
    else if([name isEqual:@"ESUMHI"]){ ret = MTC_ESUMH_THRESHOLD_INDEX; }
    else if([name isEqual:@"OWLELO"]){ ret = MTC_OWLELO_THRESHOLD_INDEX; }
    else if([name isEqual:@"OWLEHI"]){ ret = MTC_OWLEHI_THRESHOLD_INDEX; }
    else {
        [NSException raise:@"MTCControllerError" format:@"Invalid trigger scan name ( %@ ) cannot get a valid threshold id", name];
    }
    return ret;
}

- (void) waitForTriggerScan: (ORPQResult *) result
{
    uint64_t numRows, numCols;
    int threshold_index;
    int error_count = 0;
    NSString* name = nil;
    NSString* baseline = nil;
    NSString* dac_per_nhit = nil;

    if (!result) {
        NSLogColor([NSColor redColor], @"Failed to receive trigger scan results from database.\n");
        return;
    }

    numRows = [result numOfRows];
    numCols = [result numOfFields];
    if (numRows <= 0) {
        NSLogColor([NSColor redColor], @"Empty result returned from database. No trigger scans are available\n");
        return;
    }
    if (numCols != 3) {
        NSLogColor([NSColor redColor], @"Unexpected number of columns returned from database for trigger scan. Expected 3 got %i\n", numCols);
        return;
    }

    for (int i = 0; i < numRows; i++) {
        @try {
            NSDictionary* result_dict = [result fetchRowAsType:MCPTypeDictionary row:i];
            if (!result_dict) {
                error_count++;
                continue;
            }
            name = [result_dict objectForKey:@"name"];
            baseline = [[result_dict objectForKey:@"baseline"] stringValue];
            threshold_index = [self triggerScanNameToIndex:name];
            if ([self thresholdIsNHit:threshold_index]) {
                dac_per_nhit =[[result_dict objectForKey:@"adc_per_nhit"] stringValue];
                [self setDacPerNHit:threshold_index toValue:[dac_per_nhit floatValue]];
            }
            [self setBaselineOfType:threshold_index toValue:[baseline intValue]];

            // Hard code the DAC conversion to match the datasheet for the AD7243
            // http://www.analog.com/media/en/technical-documentation/data-sheets/AD7243.pdf
            // It's usage on the MTCA can be seen on page 8 of the MTCA+ schematics.
            // http://snopl.us/detector/schematics/pdf/mtcaplus.pdf
            [self setDacPerMilliVoltOfType:threshold_index toValue:-4096/10000.0];

            [self setConversionIsValidForThreshold:threshold_index isValid:YES];
        } @catch (NSException* exception) {
            NSLogColor([NSColor redColor], @"Error interpreting trigger scan result. Reason: %@\n",[exception reason]);
        }
    }

    if (error_count > 0) {
        NSLog(@"An error occurred while try to retrieve %i of the %i rows returned from the database\n",error_count,numRows);
    } else {
        NSLog(@"Successfully loaded all trigger scans from the database.\n");
    }
}

- (void) getLatestTriggerScans
{
    /* Update the dac -> nhit conversions by querying the database for the
     * latest trigger scans. */
    ORPQModel* pgsql_connec = [ORPQModel getCurrent];
    if (!pgsql_connec) {
        NSLogColor([NSColor redColor], @"Postgres connection not available. Aborting");
        return;
    }
    NSString* cmd = [NSString stringWithFormat:@"select distinct on (name) name,baseline,adc_per_nhit from trigger_scan order by name,timestamp desc"];
    [pgsql_connec dbQuery:cmd object:self selector:@selector(waitForTriggerScan:) timeout:2.0];
}

- (void) waitForThresholds: (ORPQResult *) result
{
    uint64_t numRows, numCols;

    if (!result) {
        NSLogColor([NSColor redColor], @"Failed to receive threshold results from database.\n");
        return;
    }

    numRows = [result numOfRows];
    numCols = [result numOfFields];
    if (numRows != 1) {
        NSLogColor([NSColor redColor], @"Database returned unexpected number of rows for MTC threhsolds. 1 expected, %i returned.\n",numRows);
        return;
    }
    if (numCols != 1) {
        NSLogColor([NSColor redColor], @"Database returned unexpected number of columns for MTC thresholds. 1 expected, %i returned.\n",numCols);
        return;
    }

    NSArray* result_arr = [[result fetchRowAsDictionary] objectForKey:@"mtca_dacs"];
    if (!result_arr || [result_arr count] == 0) {
        NSLogColor([NSColor redColor], @"Error while converting MTC threshold DB result to array.\n");
        return;
    }
    @try {
        // Note this could be done with a for loop, but I think this is more readable.
        [self setThresholdOfType:MTC_N100_LO_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_N100L_INDEX] floatValue]];
        [self setThresholdOfType:MTC_N100_MED_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_N100M_INDEX] floatValue]];
        [self setThresholdOfType:MTC_N100_HI_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_N100H_INDEX] floatValue]];
        [self setThresholdOfType:MTC_N20_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_N20_INDEX] floatValue]];
        [self setThresholdOfType:MTC_N20LB_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_N20LB_INDEX] floatValue]];
        [self setThresholdOfType:MTC_ESUML_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_ESUML_INDEX] floatValue]];
        [self setThresholdOfType:MTC_ESUMH_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_ESUMH_INDEX] floatValue]];
        [self setThresholdOfType:MTC_OWLN_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_OWLN_INDEX] floatValue]];
        [self setThresholdOfType:MTC_OWLELO_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_OWLEL_INDEX] floatValue]];
        [self setThresholdOfType:MTC_OWLEHI_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[result_arr objectAtIndex:SERVER_OWLEH_INDEX] floatValue]];
    } @catch(NSException* excep) {
        NSLogColor([NSColor redColor], @"Error while retrieving thresholds. Operation failed, Reason: %@\n",[excep reason]);
        return;
    }

    NSLog(@"Successfully loaded the current MTCA+ trigger thresholds from the database.\n");
}

- (void) updateTriggerThresholds
{
    /* Get the current MTCA+ thresholds from the detector database and update
     * the model. */
    ORPQModel* pgsql_connec = [ORPQModel getCurrent];
    if (!pgsql_connec) {
        NSLogColor([NSColor redColor], @"Postgres connection not available. Aborting");
        return;
    }
    NSString* db_cmd = [NSString stringWithFormat:@"select mtca_dacs from mtc where key=0"];
    [pgsql_connec dbQuery:db_cmd object:self selector:@selector(waitForThresholds:) timeout:2.0];
}

#pragma mark •••Accessors

- (RedisClient *) mtc
{
    return mtc;
}

- (unsigned short) addressModifier
{
	return 0x29;
}

- (BOOL) basicOpsRunning
{
    return basicOpsRunning;
}

- (void) setBasicOpsRunning:(BOOL)aBasicOpsRunning
{
    basicOpsRunning = aBasicOpsRunning;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelBasicOpsRunningChanged object:self];
}

- (BOOL) autoIncrement
{
    return autoIncrement;
}

- (void) setAutoIncrement:(BOOL)aAutoIncrement
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoIncrement:autoIncrement];
    
    autoIncrement = aAutoIncrement;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelAutoIncrementChanged object:self];
}

- (int) useMemory
{
    return useMemory;
}

- (void) setUseMemory:(int)aUseMemory
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseMemory:useMemory];
    
    useMemory = aUseMemory;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelUseMemoryChanged object:self];
}

- (unsigned short) repeatDelay
{
    return repeatDelay;
}

- (void) setRepeatDelay:(unsigned short)aRepeatDelay
{
	if (aRepeatDelay <= 0) aRepeatDelay = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatDelay:repeatDelay];
    
    repeatDelay = aRepeatDelay;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelRepeatDelayChanged object:self];
}

- (short) repeatOpCount
{
    return repeatOpCount;
}

- (void) setRepeatOpCount:(short)aRepeatCount
{
	if (aRepeatCount <= 0) aRepeatCount = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatOpCount:repeatOpCount];
    
    repeatOpCount = aRepeatCount;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelRepeatCountChanged object:self];
}

- (uint32_t) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(uint32_t)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:writeValue];
    
    writeValue = aWriteValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelWriteValueChanged object:self];
}

- (uint32_t) memoryOffset
{
    return memoryOffset;
}

- (void) setMemoryOffset:(uint32_t)aMemoryOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMemoryOffset:memoryOffset];
    
    memoryOffset = aMemoryOffset;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMemoryOffsetChanged object:self];
}

- (int) selectedRegister
{
    return selectedRegister;
}

- (void) setSelectedRegister:(int)aSelectedRegister
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegister:selectedRegister];
    
    selectedRegister = aSelectedRegister;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelSelectedRegisterChanged object:self];
}

- (BOOL) isPulserFixedRate
{
	return isPulserFixedRate;
}

- (void) setIsPulserFixedRate:(BOOL) aIsPulserFixedRate
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIsPulserFixedRate:isPulserFixedRate];
	
	isPulserFixedRate = aIsPulserFixedRate;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelIsPulserFixedRateChanged object:self];
	
}

- (uint32_t) fixedPulserRateCount
{
	return fixedPulserRateCount;
}

- (void) setFixedPulserRateCount:(uint32_t) aFixedPulserRateCount
{
	[[[self undoManager] prepareWithInvocationTarget:self] setFixedPulserRateCount:aFixedPulserRateCount];

	fixedPulserRateCount = aFixedPulserRateCount;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelFixedPulserRateCountChanged object:self];	
}

- (float) fixedPulserRateDelay
{
	return fixedPulserRateDelay;
}

- (void) setFixedPulserRateDelay:(float) aFixedPulserRateDelay
{
	[[[self undoManager] prepareWithInvocationTarget:self] setFixedPulserRateDelay:aFixedPulserRateDelay];
	
	fixedPulserRateDelay = aFixedPulserRateDelay;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelFixedPulserRateDelayChanged object:self];
}

- (void) setGtMask:(uint32_t)_mask
{
    @synchronized(self) {
        if (gtMask != _mask) {
            gtMask = _mask;
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORMTCGTMaskChanged object:self];
        }
    }
}

- (uint32_t) gtMask
{
    return gtMask;
}

- (void) setPgtRate:(float)rate
{
    @synchronized(self) {
        if (pgtRate != rate) {
            pgtRate = rate;
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORMTCPulserRateChanged object:self];
        }
    }
}

- (float) pgtRate
{
    return pgtRate;
}

- (int) coarseDelay
{
    return coarseDelay;
}

- (void) setCoarseDelay:(int) delay
{
    @synchronized(self) {
        if (coarseDelay != delay) {
            coarseDelay = delay;
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORMTCSettingsChanged object:self];
        }
    }
}

- (int) fineDelay
{
    return fineDelay;
}

- (void) setFineDelay:(int)delay
{
    @synchronized(self) {
        if (fineDelay != delay) {
            fineDelay = delay;
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORMTCSettingsChanged object:self];
        }
    }
}

- (void) setPrescaleValue:(uint16_t)newVal
{
    @synchronized(self) {
        if (prescaleValue != newVal) {
            prescaleValue = newVal;
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORMTCSettingsChanged object:self];
        }
    }
}

- (uint16_t) prescaleValue
{
    return prescaleValue;
}

//hardcoded base addresses (unlikely to ever change)
- (uint32_t) memBaseAddress
{
    return kMTCMemAddressBase;
}

- (uint32_t) memAddressModifier
{
	return kMTCMemAddressModifier;
}

- (uint32_t) baseAddress
{
    return kMTCRegAddressBase;
}

- (uint32_t) mtcaN100Mask
{
    return _mtcaN100Mask;
}

- (void) setMtcaN100Mask:(uint32_t)aMtcaN100Mask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaN100Mask:[self mtcaN100Mask]];
    _mtcaN100Mask = aMtcaN100Mask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (uint32_t) mtcaN20Mask
{
    return _mtcaN20Mask;
}

- (void) setMtcaN20Mask:(uint32_t)aMtcaN20Mask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaN20Mask:[self mtcaN20Mask]];
    _mtcaN20Mask = aMtcaN20Mask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (uint32_t) mtcaEHIMask
{
    return _mtcaEHIMask;
}

- (void) setMtcaEHIMask:(uint32_t)aMtcaEHIMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaEHIMask:[self mtcaEHIMask]];
    _mtcaEHIMask = aMtcaEHIMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (uint32_t) mtcaELOMask
{
    return _mtcaELOMask;
}

- (void) setMtcaELOMask:(uint32_t)aMtcaELOMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaELOMask:[self mtcaELOMask]];
    _mtcaELOMask = aMtcaELOMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (uint32_t) mtcaOELOMask
{
    return _mtcaOELOMask;
}

- (void) setMtcaOELOMask:(uint32_t)aMtcaOELOMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaOELOMask:[self mtcaOELOMask]];
    _mtcaOELOMask = aMtcaOELOMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (uint32_t) mtcaOEHIMask
{
    return _mtcaOEHIMask;
}

- (void) setMtcaOEHIMask:(uint32_t)aMtcaOEHIMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaOEHIMask:[self mtcaOEHIMask]];
    _mtcaOEHIMask = aMtcaOEHIMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (uint32_t) mtcaOWLNMask
{
    return _mtcaOWLNMask;
}

- (void) setMtcaOWLNMask:(uint32_t)aMtcaOWLNMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMtcaOWLNMask:[self mtcaOWLNMask]];
    _mtcaOWLNMask = aMtcaOWLNMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelMTCAMaskChanged object:self];
}

- (BOOL) isPedestalEnabledInCSR
{
    return _isPedestalEnabledInCSR;
}

- (void) setIsPedestalEnabledInCSR:(BOOL)isPedestalEnabledInCSR
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIsPedestalEnabledInCSR:[self isPedestalEnabledInCSR]];
    _isPedestalEnabledInCSR = isPedestalEnabledInCSR;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMTCModelIsPedestalEnabledInCSR object:self];
}

- (void) setLockoutWidth:(uint16_t)width
{
    @synchronized(self) {
        if (lockoutWidth != width) {
            lockoutWidth = width;
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORMTCSettingsChanged object:self];
        }
    }
}

- (uint16_t) lockoutWidth
{
    return lockoutWidth;
}

- (void) setPedestalWidth:(uint16_t) width
{
    @synchronized(self) {
        if (pedestalWidth != width) {
            pedestalWidth = width;
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORMTCSettingsChanged object:self];
        }
    }
}

- (uint16_t) pedestalWidth
{
    return pedestalWidth;
}

- (void) setGTCrateMask:(uint32_t)mask
{
    @synchronized(self) {
        if (GTCrateMask != mask) {
            GTCrateMask = mask;
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORMTCSettingsChanged object:self];
        }
    }
}

- (uint32_t) GTCrateMask
{
    return GTCrateMask;
}

- (void) setPedCrateMask:(uint32_t)mask
{
    @synchronized(self) {
        if (pedCrateMask != mask) {
            pedCrateMask = mask;
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORMTCSettingsChanged object:self];
        }
    }
}

- (uint32_t) pedCrateMask
{
    return pedCrateMask;
}

#pragma mark •••Converters
// This function converts the thresholds indices as they're ordered by
// the MTC Server to the indices used here
- (int) server_index_to_model_index:(int) server_index
{
    switch (server_index) {
        case SERVER_N100L_INDEX:
            return MTC_N100_LO_THRESHOLD_INDEX;
            break;
        case SERVER_N100M_INDEX:
            return MTC_N100_MED_THRESHOLD_INDEX;
            break;
        case SERVER_N100H_INDEX:
            return MTC_N100_HI_THRESHOLD_INDEX;
            break;
        case SERVER_N20_INDEX:
            return MTC_N20_THRESHOLD_INDEX;
            break;
        case SERVER_N20LB_INDEX:
            return MTC_N20LB_THRESHOLD_INDEX;
            break;
        case SERVER_ESUMH_INDEX:
            return MTC_ESUMH_THRESHOLD_INDEX;
            break;
        case SERVER_ESUML_INDEX:
            return MTC_ESUML_THRESHOLD_INDEX;
            break;
        case SERVER_OWLEL_INDEX:
            return MTC_OWLELO_THRESHOLD_INDEX;
            break;
        case SERVER_OWLEH_INDEX:
            return MTC_OWLEHI_THRESHOLD_INDEX;
            break;
        case SERVER_OWLN_INDEX:
            return MTC_OWLN_THRESHOLD_INDEX;
            break;
    }
    [NSException raise:@"MTCModelError" format:@"Cannot convert server index %i to model index",server_index];
    return -1;
}

// This function performs the inverse operation to server_index_to_model_index
- (int) model_index_to_server_index:(int) model_index
{
    switch (model_index) {
        case MTC_N100_LO_THRESHOLD_INDEX:
            return SERVER_N100L_INDEX;
            break;
        case MTC_N100_MED_THRESHOLD_INDEX:
            return SERVER_N100M_INDEX;
            break;
        case MTC_N100_HI_THRESHOLD_INDEX:
            return SERVER_N100H_INDEX;
            break;
        case MTC_N20_THRESHOLD_INDEX:
            return SERVER_N20_INDEX;
            break;
        case MTC_N20LB_THRESHOLD_INDEX:
            return SERVER_N20LB_INDEX;
            break;
        case MTC_ESUMH_THRESHOLD_INDEX:
            return SERVER_ESUMH_INDEX;
            break;
        case MTC_ESUML_THRESHOLD_INDEX:
            return SERVER_ESUML_INDEX;
            break;
        case MTC_OWLELO_THRESHOLD_INDEX:
            return SERVER_OWLEL_INDEX;
            break;
        case MTC_OWLEHI_THRESHOLD_INDEX:
            return SERVER_OWLEH_INDEX;
            break;
        case MTC_OWLN_THRESHOLD_INDEX:
            return SERVER_OWLN_INDEX;
            break;
    }
    [NSException raise:@"MTCModelError" format:@"Cannot convert model index %i to server index",model_index];
    return -1;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];

    [self registerNotificationObservers];

    /* initialize our connection to the MTC server */
    mtc = [[RedisClient alloc] init];

    [[self undoManager] disableUndoRegistration];
    [self setAutoIncrement:	[decoder decodeBoolForKey:		@"ORMTCModelAutoIncrement"]];
    [self setUseMemory:		[decoder decodeIntForKey:		@"ORMTCModelUseMemory"]];
    [self setRepeatDelay:	[decoder decodeIntegerForKey:		@"ORMTCModelRepeatDelay"]];
    [self setRepeatOpCount:	[decoder decodeIntegerForKey:		@"ORMTCModelRepeatCount"]];
    [self setWriteValue:	[decoder decodeIntForKey:		@"ORMTCModelWriteValue"]];
    [self setMemoryOffset:	[decoder decodeIntForKey:		@"ORMTCModelMemoryOffset"]];
    [self setSelectedRegister:[decoder decodeIntForKey:		@"ORMTCModelSelectedRegister"]];
	[self setIsPulserFixedRate:	[decoder decodeBoolForKey:	@"ORMTCModelIsPulserFixedRate"]];
	[self setFixedPulserRateCount:	[decoder decodeIntForKey:	@"ORMTCModelFixedPulserRateCount"]];
	[self setFixedPulserRateDelay:	[decoder decodeFloatForKey:	@"ORMTCModelFixedPulserRateDelay"]];

    [self setMtcaN100Mask:[decoder decodeIntForKey:@"mtcaN100Mask"]];
    [self setMtcaN20Mask:[decoder decodeIntForKey:@"mtcaN20Mask"]];
    [self setMtcaEHIMask:[decoder decodeIntForKey:@"mtcaEHIMask"]];
    [self setMtcaELOMask:[decoder decodeIntForKey:@"mtcaELOMask"]];
    [self setMtcaOELOMask:[decoder decodeIntForKey:@"mtcaOELOMask"]];
    [self setMtcaOEHIMask:[decoder decodeIntForKey:@"mtcaOEHIMask"]];
    [self setMtcaOWLNMask:[decoder decodeIntForKey:@"mtcaOWLNMask"]];
    [self setIsPedestalEnabledInCSR:[decoder decodeBoolForKey:@"isPedestalEnabledInCSR"]];
    [self setPulserEnabled:[decoder decodeBoolForKey:@"pulserEnabled"]];


    [self setLockoutWidth:[decoder decodeIntegerForKey:@"MTCLockoutWidth"]];
    [self setPedestalWidth:[decoder decodeIntegerForKey:@"MTCPedestalWidth"]];
    [self setPrescaleValue:[decoder decodeIntegerForKey:@"MTCPrescaleValue"]];
    [self setPgtRate:[decoder decodeIntegerForKey:@"MTCPulserRate"]];
    [self setFineDelay: [decoder decodeIntForKey:@"MTCPedestalFineDelay"]];
    [self setCoarseDelay: [decoder decodeIntForKey:@"MTCPedestalCoarseDelay"]];
    [self setGtMask:[decoder decodeIntForKey:@"MTCGTMask"]];
    [self setGTCrateMask: [decoder decodeIntForKey:@"MTCGTCrateMask"]];
    [self setPedCrateMask:[decoder decodeIntForKey:@"MTCPedCrateMask"]];

    [[self undoManager] enableUndoRegistration];

    /* We need to sync the MTC server hostname and port with the SNO+ model.
     * Usually this is done in the awakeAfterDocumentLoaded function, because
     * there we are guaranteed that the SNO+ model already exists.
     * We call updateSettings here too though to cover the case that this
     * object was added to an already existing experiment in which case
     * awakeAfterDocumentLoaded is not called. */
    [self updateSettings];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeBool:autoIncrement	forKey:@"ORMTCModelAutoIncrement"];
	[encoder encodeInteger:useMemory		forKey:@"ORMTCModelUseMemory"];
	[encoder encodeInteger:repeatDelay		forKey:@"ORMTCModelRepeatDelay"];
	[encoder encodeInteger:repeatOpCount	forKey:@"ORMTCModelRepeatCount"];
	[encoder encodeInt:writeValue		forKey:@"ORMTCModelWriteValue"];
	[encoder encodeInt:memoryOffset	forKey:@"ORMTCModelMemoryOffset"];
	[encoder encodeInteger:selectedRegister	forKey:@"ORMTCModelSelectedRegister"];
	[encoder encodeBool:isPulserFixedRate	forKey:@"ORMTCModelIsPulserFixedRate"];
	[encoder encodeInt:fixedPulserRateCount forKey:@"ORMTCModelFixedPulserRateCount"];
	[encoder encodeFloat:fixedPulserRateDelay forKey:@"ORMTCModelFixedPulserRateDelay"];
    [encoder encodeInt:(int32_t)[self mtcaN100Mask] forKey:@"mtcaN100Mask"];
    [encoder encodeInt:(int32_t)[self mtcaN20Mask] forKey:@"mtcaN20Mask"];
    [encoder encodeInt:(int32_t)[self mtcaEHIMask] forKey:@"mtcaEHIMask"];
    [encoder encodeInt:(int32_t)[self mtcaELOMask] forKey:@"mtcaELOMask"];
    [encoder encodeInt:(int32_t)[self mtcaOELOMask] forKey:@"mtcaOELOMask"];
    [encoder encodeInt:(int32_t)[self mtcaOEHIMask] forKey:@"mtcaOEHIMask"];
    [encoder encodeInt:(int32_t)[self mtcaOWLNMask] forKey:@"mtcaOWLNMask"];
    [encoder encodeBool:[self isPedestalEnabledInCSR] forKey:@"isPedestalEnabledInCSR"];
    
    [encoder encodeBool:[self pulserEnabled] forKey:@"pulserEnabled"];
    [encoder encodeInteger:[self lockoutWidth] forKey:@"MTCLockoutWidth"];
    [encoder encodeInteger:[self pedestalWidth] forKey:@"MTCPedestalWidth"];
    [encoder encodeInteger:[self prescaleValue] forKey:@"MTCPrescaleValue"];
    [encoder encodeInteger:[self pgtRate] forKey:@"MTCPulserRate"];
    [encoder encodeInteger:[self fineDelay] forKey:@"MTCPedestalFineDelay"];
    [encoder encodeInteger:[self coarseDelay] forKey:@"MTCPedestalCoarseDelay"];
    [encoder encodeInteger:[self gtMask] forKey:@"MTCGTMask"];
    [encoder encodeInteger:[self GTCrateMask] forKey:@"MTCGTCrateMask"];
    [encoder encodeInteger:[self pedCrateMask] forKey:@"MTCPedCrateMask"];
}


- (float) getThresholdOfType:(int) type inUnits:(int) units
{
    if (![self thresholdIndexIsValid:type]) {
        [NSException raise:@"MTCModelError" format:@"Unknown threshold index specified. Cannot continue."];
    }
    uint16_t threshold = mtca_thresholds[type];
    // The following could let an exception bubble up
    return [self convertThreshold:threshold OfType:type fromUnits:MTC_RAW_UNITS toUnits:units];
}

- (void) setThresholdOfType:(int)type fromUnits:(int)units toValue:(float) aThreshold
{
    // This function serves for all threshold setting needs. You can set any threshold in any units (provided a trigger scan was successfully gotten).
    // One can specify the thresold they'd like to set and the units they're using with the indexes #defined at the top of this file
    if (type < 0 || type > MTC_NUM_USED_THRESHOLDS) {
        [NSException raise:@"MTCModelError" format:@"Unknown threshold index specified. Cannot continue."];
    }
    uint16_t threshold_in_dac_counts = (uint16_t)[self convertThreshold:aThreshold OfType:type fromUnits:units toUnits:MTC_RAW_UNITS];
    if (mtca_thresholds[type] != threshold_in_dac_counts) {
        mtca_thresholds[type] = threshold_in_dac_counts;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMTCAThresholdChanged object:self];
    }
}
- (float) convertThreshold:(float)aThreshold OfType:(int) type fromUnits:(int)in_units toUnits:(int) out_units
{
    if (type < 0 || type > MTC_NUM_USED_THRESHOLDS) {
        [NSException raise:@"MTCModelError" format:@"Unknown threshold index specified. Cannot continue."];
    }
    if (in_units == out_units) {
        return aThreshold;
    }
    if (![self ConversionIsValidForThreshold:type]) {
        [NSException raise:@"ConversionNotValidError" format:@"Conversion for threshold %i is not valid",type];
    }
    float DAC_per_nhit = [self dacPerNHit:type];
    float DAC_per_mv = [self DacPerMilliVoltOfType:type];
    float mv_per_nhit = DAC_per_nhit/DAC_per_mv;

    if (in_units == MTC_RAW_UNITS) {
        float value_in_mv = ((aThreshold - [self getBaselineOfType:type])/DAC_per_mv);
        
        if (out_units == MTC_mV_UNITS) {
            return value_in_mv;
        } else if (out_units == MTC_NHIT_UNITS) {
            return [self convertThreshold:value_in_mv OfType:type fromUnits:MTC_mV_UNITS toUnits:out_units];
        }
    } else if (in_units == MTC_mV_UNITS) {
        if (out_units == MTC_RAW_UNITS) {
            return ((aThreshold * DAC_per_mv)+[self getBaselineOfType:type]);
        }
        else if (out_units == MTC_NHIT_UNITS) {
            return aThreshold/mv_per_nhit;
        }
    } else if (in_units == MTC_NHIT_UNITS) {
        float value_in_mv = mv_per_nhit * aThreshold;
        
        if (out_units == MTC_mV_UNITS) {
            return value_in_mv;
        } else if (out_units == MTC_RAW_UNITS) {
            return [self convertThreshold:value_in_mv OfType:type fromUnits:MTC_mV_UNITS toUnits:out_units];
        }
    }
    [NSException raise:@"MTCModelError" format:@"Unknown threshold index specified. Cannot continue."];
    return -1.0;
}

- (uint16_t) getBaselineOfType:(int) type
{
    return mtca_baselines[type];
}

- (void) setBaselineOfType:(int) type toValue:(uint16_t) _val
{
    if (mtca_baselines[type] != _val) {
        mtca_baselines[type] = _val;
        NSNotification* note = [NSNotification notificationWithName:ORMTCABaselineChanged object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }
}

- (float) dacPerNHit:(int) type
{
    return mtca_dac_per_nhit[type];
}

- (void) setDacPerNHit:(int) type toValue:(float) _val
{
    if (mtca_dac_per_nhit[type] != _val) {
        mtca_dac_per_nhit[type] = _val;
        NSNotification* note = [NSNotification notificationWithName:ORMTCAConversionChanged object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }
}

- (float) DacPerMilliVoltOfType:(int) type
{
    return mtca_dac_per_mV[type];
}

- (void) setDacPerMilliVoltOfType:(int) type toValue:(float) _val
{
    if (mtca_dac_per_mV[type] != _val) {
        mtca_dac_per_mV[type] = _val;
        NSNotification* note = [NSNotification notificationWithName:ORMTCAConversionChanged object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }
}

- (BOOL) ConversionIsValidForThreshold:(int) type
{
    return mtca_conversion_is_valid[type];
}

- (void) setConversionIsValidForThreshold:(int) type isValid:(BOOL) _val
{
    if (mtca_conversion_is_valid[type] != _val) {
        mtca_conversion_is_valid[type] = _val;
        NSNotification* note = [NSNotification notificationWithName:ORMTCAConversionChanged object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:note postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
    }
}

- (NSString*) stringForThreshold:(int) threshold_index
{
    NSString *ret;
    
    switch (threshold_index) {
        case MTC_N100_HI_THRESHOLD_INDEX:
            ret = @"MTC_N100H_Threshold";
            break;
        case MTC_N100_MED_THRESHOLD_INDEX:
            ret = @"MTC_N100M_Threshold";
            break;
        case MTC_N100_LO_THRESHOLD_INDEX:
            ret = @"MTC_N100L_Threshold";
            break;
        case MTC_N20_THRESHOLD_INDEX:
            ret = @"MTC_N20_Threshold";
            break;
        case MTC_N20LB_THRESHOLD_INDEX:
            ret = @"MTC_N20LB_Threshold";
            break;
        case MTC_ESUMH_THRESHOLD_INDEX:
            ret = @"MTC_ESUMH_Threshold";
            break;
        case MTC_ESUML_THRESHOLD_INDEX:
            ret = @"MTC_ESUML_Threshold";
            break;
        case MTC_OWLN_THRESHOLD_INDEX:
            ret = @"MTC_OWLN_Threshold";
            break;
        case MTC_OWLEHI_THRESHOLD_INDEX:
            ret = @"MTC_OWLEH_Threshold";
            break;
        case MTC_OWLELO_THRESHOLD_INDEX:
            ret = @"MTC_OWLEL_Threshold";
            break;
        default:
            ret =@"";
            [NSException raise:@"MTCModelError" format:@"Given index ( %i ) is not a valid threshold index",threshold_index];
            break;
    }
    return ret;
}

- (id) objectFromSerialization: (NSMutableDictionary*) serial withKey:(NSString*)str
{
    id obj = [serial valueForKey:str];
    return obj;
}

- (void) loadFromSerialization:(NSMutableDictionary*) serial
{
    //This function will let any exceptions from below bubble up

    [self setThresholdOfType:MTC_N100_HI_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self objectFromSerialization: serial withKey:[self stringForThreshold:MTC_N100_HI_THRESHOLD_INDEX] ] intValue]];
    [self setThresholdOfType:MTC_N100_MED_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self objectFromSerialization: serial withKey:[self stringForThreshold:MTC_N100_MED_THRESHOLD_INDEX] ] intValue]];
    [self setThresholdOfType:MTC_N100_LO_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self objectFromSerialization: serial withKey:[self stringForThreshold:MTC_N100_LO_THRESHOLD_INDEX] ] intValue]];
    [self setThresholdOfType:MTC_N20_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self objectFromSerialization: serial withKey:[self stringForThreshold:MTC_N20_THRESHOLD_INDEX] ] intValue]];
    [self setThresholdOfType:MTC_N20LB_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self objectFromSerialization: serial withKey:[self stringForThreshold:MTC_N20LB_THRESHOLD_INDEX] ] intValue]];
    [self setThresholdOfType:MTC_ESUMH_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self objectFromSerialization: serial withKey:[self stringForThreshold:MTC_ESUMH_THRESHOLD_INDEX] ] intValue]];
    [self setThresholdOfType:MTC_ESUML_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self objectFromSerialization: serial withKey:[self stringForThreshold:MTC_ESUML_THRESHOLD_INDEX] ] intValue]];
    [self setThresholdOfType:MTC_OWLN_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self objectFromSerialization: serial withKey:[self stringForThreshold:MTC_OWLN_THRESHOLD_INDEX] ] intValue]];
    [self setThresholdOfType:MTC_OWLEHI_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self objectFromSerialization: serial withKey:[self stringForThreshold:MTC_OWLEHI_THRESHOLD_INDEX] ] intValue]];
    [self setThresholdOfType:MTC_OWLELO_THRESHOLD_INDEX fromUnits:MTC_RAW_UNITS toValue:[[self objectFromSerialization: serial withKey:[self stringForThreshold:MTC_OWLELO_THRESHOLD_INDEX] ] intValue]];

    [self setPgtRate:[[self objectFromSerialization:serial withKey:PulserRateSerializationString] intValue]];
    [self setIsPedestalEnabledInCSR:[[self objectFromSerialization:serial withKey:PGT_PED_Mode_SerializationString] boolValue]];
    [self setPulserEnabled:[[self objectFromSerialization:serial withKey:PulserEnabledSerializationString] boolValue]];
    [self setPrescaleValue:[[self objectFromSerialization:serial withKey:PrescaleValueSerializationString] intValue]];
    [self setGtMask:[[self objectFromSerialization:serial withKey:GTMaskSerializationString] unsignedIntValue]];
    [self setLockoutWidth:[[self objectFromSerialization:serial withKey:LockOutWidthSerializationString] unsignedIntValue]];
}

- (NSMutableDictionary*) serializeToDictionary
{
    NSMutableDictionary *serial = [NSMutableDictionary dictionaryWithCapacity:30];
    //This function will let any exceptions from below bubble up
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_N100_HI_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self stringForThreshold:MTC_N100_HI_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_N100_MED_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self stringForThreshold:MTC_N100_MED_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_N100_LO_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self stringForThreshold:MTC_N100_LO_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_N20_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self stringForThreshold:MTC_N20_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_N20LB_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self stringForThreshold:MTC_N20LB_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_ESUMH_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self stringForThreshold:MTC_ESUMH_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_ESUML_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self stringForThreshold:MTC_ESUML_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_OWLN_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self stringForThreshold:MTC_OWLN_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_OWLEHI_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self stringForThreshold:MTC_OWLEHI_THRESHOLD_INDEX]];
    [serial setObject:[NSNumber numberWithInt:(int) [self getThresholdOfType:MTC_OWLELO_THRESHOLD_INDEX inUnits:MTC_RAW_UNITS]] forKey:[self stringForThreshold:MTC_OWLELO_THRESHOLD_INDEX]];

    [serial setObject:[NSNumber numberWithUnsignedLong:[self pgtRate]] forKey:PulserRateSerializationString];
    [serial setObject:[NSNumber numberWithBool:[self isPedestalEnabledInCSR]] forKey:PGT_PED_Mode_SerializationString];
    [serial setObject:[NSNumber numberWithBool:[self pulserEnabled] ] forKey:PulserEnabledSerializationString];
    [serial setObject:[NSNumber numberWithUnsignedShort:[self prescaleValue]] forKey:PrescaleValueSerializationString];
    [serial setObject:[NSNumber numberWithUnsignedInt: [self gtMask]] forKey:GTMaskSerializationString];
    [serial setObject:[NSNumber numberWithUnsignedInt: [self lockoutWidth]] forKey:LockOutWidthSerializationString];
    return serial;
}

- (BOOL) thresholdIndexIsValid: (int) index
{
    return index >= 0 && index < MTC_NUM_THRESHOLDS;
}

- (BOOL) thresholdIsNHit:(int)index
{
    if (![self thresholdIndexIsValid:index]) {
        [NSException raise:@"MTCModelError" format:@"Unknown threshold index specified."];
    }
    return  index != MTC_ESUML_THRESHOLD_INDEX  &&
            index != MTC_ESUMH_THRESHOLD_INDEX  &&
            index != MTC_OWLELO_THRESHOLD_INDEX &&
            index != MTC_OWLEHI_THRESHOLD_INDEX;
}

#pragma mark •••HW Access

- (short) getNumberRegisters
{
    return kMtcNumRegisters;
}

- (NSString*) getRegisterName:(short) anIndex
{
    return reg[anIndex].regName;
}

- (uint32_t) read:(int)aReg
{
	uint32_t theValue = 0;
	@try {
        theValue = (uint32_t)[mtc intCommand:"mtcd_read %d", reg[aReg].addressOffset];
	} @catch(NSException* localException) {
		NSLog(@"Couldn't read the MTC %@!\n",reg[aReg].regName);
		[localException raise];
	}
	return theValue;
}

- (void) write:(int)aReg value:(uint32_t)aValue
{
	@try {
        [mtc okCommand:"mtcd_write %d %d", reg[aReg].addressOffset, aValue];
	} @catch(NSException* localException) {
		NSLog(@"Couldn't write %d to the MTC %@!\n",aValue,reg[aReg].regName);
		[localException raise];
	}
}

- (void) setBits:(int)aReg mask:(uint32_t)aMask
{
	uint32_t old_value = [self read:aReg];
	uint32_t new_value = (old_value & ~aMask) | aMask;
	[self write:aReg value:new_value];
}

- (void) clrBits:(int)aReg mask:(uint32_t)aMask
{
	uint32_t old_value = [self read:aReg];
	uint32_t new_value = (old_value & ~aMask);
	[self write:aReg value:new_value];
}

- (void) sendMTC_SoftGt
{
	[self sendMTC_SoftGt:NO];
}

- (void) sendMTC_SoftGt:(BOOL) setGTMask
{
	@try {
        if(setGTMask) { [self setSingleGTWordMask:MTC_SOFT_GT_MASK]; }   // Step 1: set the SOFT_GT mask
        [mtc okCommand:"soft_gt"];                                       // Step 2: send soft_gt command
        if(setGTMask) { [self clearSingleGTWordMask:MTC_SOFT_GT_MASK]; } // Step 3: clear the SOFT_GT mask
	}
	@catch(NSException* localException) {
		NSLog(@"Couldn't send a MTC SOFT_GT!\n");
		NSLog(@"Exception: %@\n",localException);
	}
}

- (void) initializeMtc
{
	ORSelectorSequence* seq = [ORSelectorSequence selectorSequenceWithDelegate:self];

	@try {		
		NSLog(@"Starting MTC init process....\n");

        [[seq forTarget:self] server_init];                                         // STEP 1: Let the server init
		[[seq forTarget:self] zeroTheGTCounter];									// STEP 2: Clear the GT Counter
        [[seq forTarget:self] loadLockOutWidthToHardware];                          // STEP 3: Set the Lockout Width
		[[seq forTarget:self] loadPrescaleValueToHardware];							// STEP 4:  Load the NHIT 100 LO prescale value
		[[seq forTarget:self] loadPulserRateToHardware];                            // STEP 5: Load the Pulser
		[[seq forTarget:self] loadPedWidthToHardware];                              // STEP 6: Set the Pedestal Width
        [[seq forTarget:self] loadCoarseDelayToHardware];                         // STEP 7: Setup the Pulse GT Delays
        [[seq forTarget:self] loadFineDelayToHardware];                         // STEP 7: Setup the Pulse GT Delays
        [[seq forTarget:self] setGlobalTriggerWordMask];                            // STEP 8: Load GT mask
        [[seq forTarget:self] loadGTCrateMaskToHardware];                           // STEP 9: Load GT crate mask
        [[seq forTarget:self] loadPedestalCrateMaskToHardware];                     // STEP 10: Load ped crate mask
		[[seq forTarget:self] initializeMtcDone];
		[seq startSequence];
	} @catch(NSException* localException) {
		NSLog(@"***Initialization of the MTC (%@ Xilinx, %@ 10MHz clock) failed!***\n");
		NSLog(@"Exception: %@\n",localException);
		[seq stopSequence];
	}
}

- (void) server_init
{
    [mtc okCommand:"mtcd_init"];
}

- (void) initializeMtcDone
{
	NSLog(@"Initialization of the MTC complete.\n");
}

- (void) clearGlobalTriggerWordMask
{
    @try {
        [mtc okCommand:"set_gt_mask %u", 0];
        NSLog(@"Cleared GT Mask\n");
    } @catch(NSException* localException) {
        NSLog(@"Could not clear GT word mask!\n");
        NSLog(@"Exception: %@\n",localException);
        [localException raise];
    }
}

- (void) setGlobalTriggerWordMask
{
	@try {
		[mtc okCommand:"set_gt_mask %u",[self gtMask]];
		NSLog(@"Set GT Mask: 0x%08x\n",[self gtMask]);
	} @catch(NSException* localException) {
		NSLog(@"Could not set a set GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (uint32_t) getGTMaskFromHardware
{
	uint32_t aValue = 0;
	@try {	
        aValue =  (uint32_t)[mtc intCommand:"get_gt_mask"];
	} @catch(NSException* localException) {
		NSLog(@"Could not get GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
	return (uint32_t)aValue;
}

- (void) setSingleGTWordMask:(uint32_t) gtWordMask
{	
	@try {
		[self setBits:kMtcMaskReg mask:gtWordMask];
	} @catch(NSException* localException) {
		NSLog(@"Could not set a MTC GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) clearSingleGTWordMask:(uint32_t) gtWordMask
{
	@try {
		[self clrBits:kMtcMaskReg mask:gtWordMask];
	} @catch(NSException* localException) {
		NSLog(@"Could not clear a MTC GT word mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (void) clearPedestalCrateMask
{
	@try {
        [self setPedCrateMask:0];
        [self loadPedestalCrateMaskToHardware];
        NSLog(@"Cleared Ped Mask\n");
	} @catch(NSException* localException) {
		NSLog(@"Could not clear a Ped mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}


- (void) loadPedestalCrateMaskToHardware
{
    uint32_t pedMaskValue = [self pedCrateMask];

	@try {
		[mtc okCommand:"set_ped_crate_mask %u", pedMaskValue];
		NSLog(@"Set Ped Mask: 0x%08x\n",pedMaskValue);
	} @catch(NSException* localException) {
		NSLog(@"Could not set a Ped crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (void) clearGTCrateMask
{
	@try {
        [self setGTCrateMask:0];
        [self loadGTCrateMaskToHardware];
		NSLog(@"Cleared GT Crate Mask\n");
	} @catch(NSException* localException) {
		NSLog(@"Could not clear GT crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (void) loadGTCrateMaskToHardware
{
    uint32_t gtCrateMaskValue = [self GTCrateMask];

	@try {
        [mtc okCommand:"set_gt_crate_mask %u", gtCrateMaskValue];
        NSLog(@"Set GT Crate Mask: 0x%08x\n",gtCrateMaskValue);
	} @catch(NSException* localException) {
		NSLog(@"Could not set GT crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}	
}

- (uint32_t) getGTCrateMaskFromHardware
{
	uint32_t aValue = 0;

	@try {
		aValue = (uint32_t)[mtc intCommand:"get_gt_crate_mask"];
	} @catch(NSException* localException) {
		NSLog(@"Could not get GT crate mask!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}

	return (uint32_t)aValue;	
}

- (void) clearTheControlRegister
{
	@try {
		[self write:kMtcControlReg value:0];
		NSLog(@"Cleared Control Reg\n");
	} @catch(NSException* localException) {
		NSLog(@"Could not clear control reg!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) resetTheMemory
{
	@try {
		//Clear the MTC/D memory, the fifo write pointer and the BBA Register
		[self write:kMtcBbaReg value:0];
		[self setBits:kMtcControlReg mask:MTC_CSR_FIFO_RESET];
		[self clrBits:kMtcControlReg mask:MTC_CSR_FIFO_RESET];
		NSLog(@"Reset MTC memory\n");
	} @catch(NSException* localException) {
		NSLog(@"Could not reset MTC memory!\n");					
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) setTheGTCounter:(uint32_t) theGTCounterValue
{
	@try {
        [mtc okCommand:"set_gtid %u",theGTCounterValue];
	} @catch(NSException* localException) {
		NSLog(@"Could not load the MTC GT counter!\n");			
		[localException raise];
	}
}

- (void) zeroTheGTCounter
{
	[self setTheGTCounter:0UL];
}

- (void) setThe10MHzCounter:(uint64_t) newValue
{
    @try {
        [mtc okCommand:"load_10mhz_clock %llu",newValue];
		NSLog(@"Loaded 10MHz counter\n");
	} @catch(NSException* localException) {
		NSLog(@"Could not load the 10MHz counter!\n");
		NSLog(@"Exception: %@\n",[localException reason]);
		[localException raise];
	}
}

- (void) loadLockOutWidthToHardware
{
	@try {
        [mtc okCommand:"set_lockout_width %u", [self lockoutWidth]];
        NSLog(@"Set lockout width to %u\n",[self lockoutWidth]);
	} @catch(NSException* localException) {
		NSLog(@"Could not load the MTC GT lockout width!\n");		
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) loadPedWidthToHardware
{
	@try {
        [mtc okCommand:"set_pedestal_width %u", [self pedestalWidth]];
        NSLog(@"Set ped width to %u\n",[self pedestalWidth]);
	} @catch(NSException* localException) {
		NSLog(@"Could not load the MTC pedestal width!\n");	
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) loadPrescaleValueToHardware
{
	@try {
        [mtc okCommand:"set_prescale %u", [self prescaleValue]];
        NSLog(@"Set N100Lo prescale to %u\n", [self prescaleValue]);
	} @catch(NSException* localException) {
		NSLog(@"Could not load the MTC prescale value!\n");
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) loadCoarseDelayToHardware
{
    int coarse_delay = [self coarseDelay];

    @try {
        [mtc okCommand:"set_coarse_delay %i", coarse_delay];
        NSLog(@"mtc: coarse delay %ins\n", coarse_delay);
    } @catch(NSException* localException) {
        NSLog(@"Could not set coarse delay\n");
        NSLog(@"Exception: %@\n",localException);
        [localException raise];
    }
}

- (void) loadFineDelayToHardware
{
    int fine_delay = [self fineDelay];

    @try {
        [mtc okCommand:"set_fine_delay %i", fine_delay];
        NSLog(@"mtc: fine delay %ips\n", fine_delay);
    } @catch(NSException* localException) {
        NSLog(@"Could not set fine delay\n");
        NSLog(@"Exception: %@\n",localException);
        [localException raise];
    }
}

- (void) loadPulserRateToHardware
{
    float pulserRate = [self pgtRate];

	@try {
        [mtc okCommand:"set_pulser_freq %f", pulserRate];
		NSLog(@"mtc: pulser rate set to %.2f Hz\n", pulserRate);			
	} @catch(NSException* localException) {
		NSLog(@"Could not set GT Pusler rate!\n");			
		NSLog(@"Exception: %@\n",localException);
		[localException raise];
	}
}

- (void) enablePulser
{
	@try {
        [mtc okCommand:"enable_pulser"];
        NSLog(@"Enabled Pulser.\n");
	} @catch(NSException* localException) {
		NSLog(@"Unable to enable the pulser!\n");		
		[localException raise];
	}

    [self setPulserEnabled:YES];
}

- (void) disablePulser
{
	@try {
        [mtc okCommand:"disable_pulser"];
        NSLog(@"Disabled Pulser.\n");
	} @catch(NSException* localException) {
		NSLog(@"Unable to disable the pulser!\n");		
		[localException raise];
	}

    [self setPulserEnabled:NO];
}

- (void)  enablePedestal
{
	@try {
        [mtc okCommand:"enable_pedestals"];
        NSLog(@"Enabled Pedestals.\n");
	} @catch(NSException* localException) {
		NSLog(@"Unable to enable the Pedestals!\n");		
		[localException raise];
	}
}

- (void)  disablePedestal
{
	@try {
        [mtc okCommand:"disable_pedestals"];
        NSLog(@"Disabled Pedestals.\n");
	} @catch(NSException* localException) {
		NSLog(@"Unable to disable the Pedestals!\n");		
		[localException raise];
	}
}

- (void) stopMTCPedestalsFixedRate
{
	@try {
		[self disablePulser];
	} @catch(NSException* e) {
		NSLog(@"MTC failed to stop pedestals!\n");
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
}

- (void) continueMTCPedestalsFixedRate
{
	@try {
        if ([self isPedestalEnabledInCSR]) {
            [self enablePedestal];
        } else {
            [self disablePedestal];
        }
		[self enablePulser];
	} @catch(NSException* e) {
		NSLog(@"MTC failed to continue pedestals!\n");
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
}

- (void) fireMTCPedestalsFixedRate
{
	//Fire Pedestal pulses at a pecified period in ms, with a specifed 
	//GT coarse delay, GT Lockout Width, pedestal width in ns and a 
	//specified crate mask set in MTC Databse. Trigger mask is EXT_8.
    
    @try {
		/* setup pedestals and global trigger */
        [self basicMTCPedestalGTrigSetup];
        [self loadPulserRateToHardware];
        [self enablePulser];
    } @catch(NSException* e) {
        NSLog(@"MTC failed to fire pedestals at the specified settings!\n");
        NSLog(@"fireMTCPedestalsFixedRate: %@\n", [e reason]);
    }
}

- (void) basicMTCPedestalGTrigSetup
{
	@try {
		//[self clearGlobalTriggerWordMask];							//STEP 0a:	//added 01/24/98 QRA
        if ([self isPedestalEnabledInCSR]) {
            [self enablePedestal];										// STEP 1 : Enable Pedestal
        } else {
            [self disablePedestal];
        }
		[self loadPedestalCrateMaskToHardware];							// STEP 2: Mask in crates for pedestals (PMSK)
		[self loadGTCrateMaskToHardware];								// STEP 3: Mask  Mask in crates fo GTRIGs (GMSK)
        [self loadCoarseDelayToHardware];                               // STEP 4: Set thSet the GTRIG/PED delay in ns
        [self loadFineDelayToHardware];                                 // ditto^^^
        [self loadLockOutWidthToHardware];                              // STEP 5: Set the GT lockout width in ns
        [self loadPedWidthToHardware];                                  // STEP 7: Set the width of the PED signal
		[self setSingleGTWordMask: [self gtMask]];                      // STEP 7: Mask in global trigger word(MASK)
	} @catch(NSException* localException) {
		NSLog(@"Failure during MTC pedestal setup!\n");
		[localException raise];
	}
}

- (void) fireMTCPedestalsFixedTime
{
    float cachedRate;

    @try {
		/* setup pedestals and global trigger */
        [self basicMTCPedestalGTrigSetup];

		[self clearSingleGTWordMask:MTC_SOFT_GT_MASK];

        /* set the pulser rate to 0, which will enable SOFT_GT to trigger
         * pedestals */
        cachedRate = [self pgtRate];
        [self setPgtRate:0];
        [self loadPulserRateToHardware];

        [self enablePulser];

        [mtc okCommand:"multi_soft_gt %d %f", [self fixedPulserRateCount],
                        [self fixedPulserRateDelay]];

    } @catch(NSException* e) {
        NSLog(@"MTC failed to fire pedestals at the specified settings!\n");
        NSLog(@"fireMTCPedestalsFixedRate: %@\n", [e reason]);
    }
    // Put the rate back to where we found it.
    [self setPgtRate:cachedRate];
}

- (void) stopMTCPedestalsFixedTime
{
    [mtc okCommand:"stop_multi_soft_gt"];
}

- (void) firePedestals:(uint32_t) count withRate:(float) rate
{
    /* Fires a fix number of pedestals at a specified rate in Hz.
     * This function should not be called on the main GUI thread, but
     * only by ORCA scripts since it blocks until completion */

    int32_t timeout = [mtc timeout];

    /* Temporarily increase the timeout since it might take a while */
    [mtc setTimeout:(int32_t) 1500*count/rate];

    @try {
        [mtc okCommand:"fire_pedestals %d %f", count, rate];
    } @catch (NSException *e) {
        @throw e;
    } @finally {
        [mtc setTimeout:timeout];
    }
}

- (void) basicMTCReset
{
	@try {
		[self disablePulser];
		[self clearGTCrateMask];
		[self clearPedestalCrateMask];		
		[self clearGlobalTriggerWordMask];
		[self resetTheMemory];
		[self zeroTheGTCounter];
        [self loadLockOutWidthToHardware];
		[self loadPrescaleValueToHardware];
	} @catch(NSException* localException) {
		NSLog(@"Could not perform basic MTC reset!\n");
		[localException raise];
	}
}

- (void) validateMTCADAC:(uint16_t) dac_value
{
    if (dac_value > 4095) {
        [NSException raise:@"MTCModelError" format:@"MTCA DAC value %u is not valid. DAC values must be less than 4095",dac_value];
    }
}

- (void) loadTheMTCADacs
{
    /* Load the MTCA thresholds to hardware.
     This function lets exceptions bubble up. */
    int i;
    uint16_t dacs[14];
    int server_index;

    for (i = FIRST_MTC_THRESHOLD_INDEX; i <= LAST_MTC_THRESHOLD_INDEX; i++) {
        server_index = [self model_index_to_server_index:i];
        dacs[server_index] = [self getThresholdOfType:i inUnits:MTC_RAW_UNITS];
        [self validateMTCADAC:dacs[server_index]];
    }

    /* Last four DAC values are spares? */
    for (i = 10; i < 14; i++) {
        dacs[i] = 0;
    }

    @try {
        [mtc okCommand:"load_mtca_dacs %d %d %d %d %d %d %d %d %d %d %d %d %d %d", dacs[0], dacs[1], dacs[2], dacs[3], dacs[4], dacs[5], dacs[6], dacs[7], dacs[8], dacs[9], dacs[10], dacs[11], dacs[12], dacs[13]];
    } @catch(NSException* e) {
        NSLogColor([NSColor redColor],@"failed to load the MTCA dacs: %@\n", [e reason]);
        [e raise];
    }
    NSLog(@"Successfully loaded MTCA+ thresholds\n");
}

- (BOOL) adapterIsSBC
{
	return [[self adapter] isKindOfClass:NSClassFromString(@"ORVmecpuModel")];
}

- (void) loadMTCXilinx
{
    [mtc okCommand:"load_xilinx"];
}

- (void) loadTubRegister
{
	@try {
		uint32_t aValue = [self tubRegister];
		
		uint32_t shift_value;
		uint32_t theRegValue;
		theRegValue = [self read:kMtcDacCntReg];
		short j;
		for ( j = 0; j < 32; j++) {
			shift_value = ((aValue >> j) & 0x01) == 1 ? TUB_SDATA : 0;
			theRegValue &= ~0x00001c00;   // only alter in TUB prog bits
			[self write:kMtcDacCntReg value:theRegValue];
			theRegValue |= shift_value;
			[self write:kMtcDacCntReg value:theRegValue];
			theRegValue |= TUB_SCLK;      // clock in SDATA
			[self write:kMtcDacCntReg value:theRegValue];
		}
		
		theRegValue = [self read:kMtcDacCntReg];
		theRegValue &= ~0x00001c00;
		[self write:kMtcDacCntReg value:theRegValue];
		theRegValue |= TUB_SLATCH;
		[self write:kMtcDacCntReg value:theRegValue];
		theRegValue &= ~0x00001c00;
		[self write:kMtcDacCntReg value:theRegValue];
		
		NSLog(@"0x%x was shifted into the TUB serial register\n", aValue);
	} @catch(NSException* localException) {
		NSLog(@"Failed to load Tub serial register\n");
		[localException raise];
	}
}

- (void) loadMTCACrateMapping
{
    /* Sends a command to the MTC server to update the mapping between crates
     * and channels on the MTCA+s from the detector state database. */
    @try {
        [mtc okCommand:"load_mtca_crate_mapping"];
    } @catch (NSException* e) {
        NSLogColor([NSColor redColor], @"failed to update the MTCA+ crate mappings: %@\n", [e reason]);
        [e raise];
    }
    NSLog(@"Successfully updated the MTCA+ crate mappings\n");
}

- (void) mtcatResetMtcat:(unsigned char) mtcat
{
    @try {
        [mtc okCommand:"mtca_reset %d", mtcat];
    } @catch (NSException *e) {
        NSLog(@"mtcatResetMtcat: %@\n", e.reason);
    }
}

- (void) mtcatResetAll
{
    @try {
        [mtc okCommand:"mtca_reset_all"];
    } @catch (NSException *e) {
        NSLog(@"mtcatResetAll: %@\n", e.reason);
    }
}

- (void) mtcatLoadCrateMasks
{
    [self mtcatResetAll];
    [self mtcatLoadCrateMask:[self mtcaN100Mask] toMtcat:0];
    [self mtcatLoadCrateMask:[self mtcaN20Mask] toMtcat:1];
    [self mtcatLoadCrateMask:[self mtcaELOMask] toMtcat:2];
    [self mtcatLoadCrateMask:[self mtcaEHIMask] toMtcat:3];
    [self mtcatLoadCrateMask:[self mtcaOELOMask] toMtcat:4];
    [self mtcatLoadCrateMask:[self mtcaOEHIMask] toMtcat:5];
    [self mtcatLoadCrateMask:[self mtcaOWLNMask] toMtcat:6];
}

- (void) mtcatClearCrateMasks
{
    [self mtcatResetAll];
    [self mtcatLoadCrateMask:0 toMtcat:0];
    [self mtcatLoadCrateMask:0 toMtcat:1];
    [self mtcatLoadCrateMask:0 toMtcat:2];
    [self mtcatLoadCrateMask:0 toMtcat:3];
    [self mtcatLoadCrateMask:0 toMtcat:4];
    [self mtcatLoadCrateMask:0 toMtcat:5];
    [self mtcatLoadCrateMask:0 toMtcat:6];
}

- (void) mtcatLoadCrateMask:(uint32_t) mask toMtcat:(unsigned char) mtcat
{
    if (mtcat > 7) {
        NSLog(@"MTCA load crate mask ignored, mtcat > 6\n");
        return;
    }

    @try {
        [mtc okCommand:"mtca_load_crate_mask %d %d", mtcat, mask];
    } @catch(NSException* e) {
        NSLog(@"mtcatLoadCrateMask: %@\n", e.reason);
        return;
    }

    char* mtcats[] = {"N100", "N20", "EHI", "ELO", "OELO", "OEHI", "OWLN"};
    NSLog(@"MTCA: set %s crate mask to 0x%08x\n", mtcats[mtcat], mask);
}

#pragma mark •••BasicOps
- (void) readBasicOps
{
	doReadOp = YES;
	workingCount = 0;
	[self setBasicOpsRunning:YES];
	[self doBasicOp];
}

- (void) writeBasicOps
{
	doReadOp = NO;
	workingCount = 0;
	[self setBasicOpsRunning:YES];
	[self doBasicOp];
}

- (void) stopBasicOps
{
	[self setBasicOpsRunning:NO];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doBasicOp) object:nil];
}
@end

@implementation ORMTCModel (private)

- (void) doBasicOp
{
	@try {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doBasicOp) object:nil];
		if(useMemory){
			//TBD.....
			if(doReadOp){
			}
			else {
			}
		}
		else {
			if (doReadOp) {
				NSLog(@"%@: 0x%08x\n",reg[selectedRegister].regName,[self read:selectedRegister]);
			} else {
				[self write:selectedRegister value:writeValue];
				NSLog(@"Wrote 0x%08x to %@\n",writeValue,reg[selectedRegister].regName);
			}
		}
		if (++workingCount < repeatOpCount) {
			[self performSelector:@selector(doBasicOp) withObject:nil afterDelay:repeatDelay/1000.];
		} else {
			[self setBasicOpsRunning:NO];
		}
	} @catch(NSException* localException) {
		[self setBasicOpsRunning:NO];
		NSLog(@"Mtc basic op exception: %@\n",localException);
		[localException raise];
	}
}

- (void) setupDefaults
{
    [self setLockoutWidth:420];
    [self setPedestalWidth:52];
    [self setPrescaleValue:1];
    [self setPgtRate:10];
    [self setCoarseDelay:60];
    [self setFineDelay:0];
    [self setGtMask:0];
    [self setGTCrateMask: 0];
    [self setPedCrateMask:0];
    for (int i = 0; i < MTC_NUM_THRESHOLDS; i++) {
        mtca_conversion_is_valid[i] = NO;
        mtca_thresholds[i] = 0;
    }
}
@end

