//
//  ORXL3Model.m
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
#import "XL3_Link.h"
#import "PacketTypes.h"
#import "Registers.h"
#import "ORXL3Model.h"
#import "ORSNOCrateModel.h"
#import "ORSNOConstants.h"
#import "ORFec32Model.h"
#import "ORFecDaughterCardModel.h"
#import "OROrderedObjManager.h"
#import "ObjectFactory.h"
#import "ORDataTypeAssigner.h"
#import "ORCouchDB.h"
#import "ORPQModel.h"
#import "ORPQResult.h"
#import "RunTypeWordBits.hh"
#import "math.h"

static Xl3RegNamesStruct reg[kXl3NumRegisters] = {
	{ @"SelectReg",		RESET_REG },
	{ @"DataAvailReg",	DATA_AVAIL_REG },
	{ @"CtrlStatReg",	XL3_CS_REG },
	{ @"SlotMaskReg",	XL3_MASK_REG},
	{ @"ClockReg",		XL3_CLOCK_REG},
	{ @"HVRelayReg",	RELAY_REG},
	{ @"XilinxReg",		XL3_XLCON_REG},
	{ @"TestReg",		TEST_REG},
	{ @"HVCtrlStatReg",	HV_CS_REG},
	{ @"HVSetPointReg",	HV_SETPOINTS},
	{ @"HVVltReadReg",	HV_VR_REG},
	{ @"HVCrntReadReg",	HV_CR_REG},
	{ @"XL3VMReg",		XL3_VM_REG},
	{ @"XL3VRReg",		XL3_VR_REG}
};


#pragma mark •••Definitions

#define kDebugDbEcalDocGot  @"kDebugDbEcalDocGot"

NSString* ORXL3ModelSelectedRegisterChanged =	@"ORXL3ModelSelectedRegisterChanged";
NSString* ORXL3ModelRepeatCountChanged =		@"ORXL3ModelRepeatCountChanged";
NSString* ORXL3ModelRepeatDelayChanged =		@"ORXL3ModelRepeatDelayChanged";
NSString* ORXL3ModelAutoIncrementChanged =		@"ORXL3ModelAutoIncrementChanged";
NSString* ORXL3ModelBasicOpsRunningChanged =	@"ORXL3ModelBasicOpsRunningChanged";
NSString* ORXL3ModelWriteValueChanged =			@"ORXL3ModelWriteValueChanged";
NSString* ORXL3ModelXl3ModeChanged =			@"ORXL3ModelXl3ModeChanged";
NSString* ORXL3ModelSlotMaskChanged =			@"ORXL3ModelSlotMaskChanged";
NSString* ORXL3ModelXl3ModeRunningChanged =		@"ORXL3ModelXl3ModeRunningChanged";
NSString* ORXL3ModelXl3RWAddressValueChanged =	@"ORXL3ModelXl3RWAddressValueChanged";
NSString* ORXL3ModelXl3RWDataValueChanged =		@"ORXL3ModelXl3RWDataValueChanged";
NSString* ORXL3ModelXl3OpsRunningChanged =		@"ORXL3ModelXl3OpsRunningChanged";
NSString* ORXL3ModelXl3PedestalMaskChanged =	@"ORXL3ModelXl3PedestalMaskChanged";
NSString* ORXL3ModelXl3ChargeInjChanged =       @"ORXL3ModelXl3ChargeInjChanged";
NSString* ORXL3ModelPollXl3TimeChanged =        @"ORXL3ModelPollXl3TimeChanged";
NSString* ORXL3ModelIsPollingXl3Changed =       @"ORXL3ModelIsPollingXl3Changed";
NSString* ORXL3ModelIsPollingCMOSRatesChanged =     @"ORXL3ModelIsPollingCMOSRatesChanged";
NSString* ORXL3ModelPollCMOSRatesMaskChanged =      @"ORXL3ModelPollCMOSRatesMaskChanged";
NSString* ORXL3ModelIsPollingPMTCurrentsChanged =   @"ORXL3ModelIsPollingPMTCurrentsChanged";
NSString* ORXL3ModelPollPMTCurrentsMaskChanged  =   @"ORXL3ModelPollPMTCurrentsMaskChanged";
NSString* ORXL3ModelIsPollingFECVoltagesChanged =   @"ORXL3ModelIsPollingFECVoltagesChanged";
NSString* ORXL3ModelPollFECVoltagesMaskChanged =    @"ORXL3ModelPollFECVoltagesMaskChanged";
NSString* ORXL3ModelIsPollingXl3VoltagesChanged =   @"ORXL3ModelIsPollingXl3VoltagesChanged";
NSString* ORXL3ModelIsPollingHVSupplyChanged =      @"ORXL3ModelIsPollingHVSupplyChanged";
NSString* ORXL3ModelIsPollingXl3WithRunChanged =    @"ORXL3ModelIsPollingXl3WithRunChanged";
NSString* ORXL3ModelPollStatusChanged =             @"ORXL3ModelPollStatusChanged";
NSString* ORXL3ModelIsPollingVerboseChanged =       @"ORXL3ModelIsPollingVerboseChanged";
NSString* ORXL3ModelRelayMaskChanged = @"ORXL3ModelRelayMaskChanged";
NSString* ORXL3ModelRelayStatusChanged = @"ORXL3ModelRelayStatusChanged";
NSString* ORXL3ModelHvStatusChanged = @"ORXL3ModelHvStatusChanged";
NSString* ORXL3ModelTriggerStatusChanged = @"ORXL3ModelTriggerStatusChanged";
NSString* ORXL3ModelHVTargetValueChanged = @"ORXL3ModelHVTargetValueChanged";
NSString* ORXL3ModelHVNominalVoltageChanged = @"ORXL3ModelHVNominalVoltageChanged";
NSString* ORXL3ModelHVCMOSRateLimitChanged = @"ORXL3ModelHVCMOSRateLimitChanged";
NSString* ORXL3ModelHVCMOSRateIgnoreChanged = @"ORXL3ModelHVCMOSRateIgnoreChanged";
NSString* ORXL3ModelXl3VltThresholdChanged = @"ORXL3ModelXl3VltThresholdChanged";
NSString* ORXL3ModelXl3VltThresholdInInitChanged = @"ORXL3ModelXl3VltThresholdInInitChanged";
NSString* ORXL3Lock = @"ORXL3Lock";
NSString* ORXL3ModelStateChanged = @"ORXL3ModelStateChanged";

@interface ORXL3Model (private)
- (void) doBasicOp;
- (NSString*) stringDate;
- (void) _pollXl3;
- (void) _hvInit;
- (void) _hvXl3;
- (void) _setPedestalInParallelWorker;
- (void) _post_heartbeat:(int)crate;
- (void) _trigger_edge_alarm:(int)alarmid;
- (void) _update_level_alarm:(int)alarmid level:(bool)state;
- (void) _hv_a_dbparams:(ORPQResult*)result;
- (void) _hv_b_dbparams:(ORPQResult*)result;
@end

@implementation ORXL3Model

@synthesize
xl3MegaBundleDataId = _xl3MegaBundleDataId,
pmtBaseCurrentDataId = _pmtBaseCurrentDataId,
cmosRateDataId = _cmosRateDataId,
xl3FifoDataId = _xl3FifoDataId,
xl3HvDataId = _xl3HvDataId,
xl3VltDataId = _xl3VltDataId,
fecVltDataId = _fecVltDataId,
isPollingForced,
calcCMOSRatesFromCounts = _calcCMOSRatesFromCounts,
hvANextStepValue = _hvANextStepValue,
hvBNextStepValue = _hvBNextStepValue,
hvReadbackCorrA = _hvReadbackCorrA,
hvramp_a_up = _hvramp_a_up,
hvramp_a_down = _hvramp_a_down,
vsetalarm_a_vtol = _vsetalarm_a_vtol,
ilowalarm_a_vmin = _ilowalarm_a_vmin,
ilowalarm_a_imin = _ilowalarm_a_imin,
vhighalarm_a_vmax = _vhighalarm_a_vmax,
ihighalarm_a_imax = _ihighalarm_a_imax,
hvReadbackCorrB = _hvReadbackCorrB,
hvramp_b_up = _hvramp_b_up,
hvramp_b_down = _hvramp_b_down,
vsetalarm_b_vtol = _vsetalarm_b_vtol,
ilowalarm_b_vmin = _ilowalarm_b_vmin,
ilowalarm_b_imin = _ilowalarm_b_imin,
vhighalarm_b_vmax = _vhighalarm_b_vmax,
ihighalarm_b_imax = _ihighalarm_b_imax,
hvCMOSReadsCounter = _hvCMOSReadsCounter,
xl3LinkTimeOut = _xl3LinkTimeOut,
xl3InitInProgress = _xl3InitInProgress,
ecal_received = _ecal_received,
ecalToOrcaInProgress = _ecalToOrcaInProgress,
isTriggerON = _isTriggerON,
snotDb = _snotDb,
hvAQueryWaiting = hvAQueryWaiting,
hvBQueryWaiting = hvBQueryWaiting,
isLoaded = isLoaded;


#pragma mark •••Initialization
- (id) init
{
	self = [super init];
    hvInitLock = [[NSLock alloc] init];
	return self;
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"XL3Card"]];
}

- (void) dealloc
{
    [xl3Link release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (pollThread) [pollThread release];
    if (hvThread) [hvThread release];
    if (relayStatus) [relayStatus release];
    [xl3DateFormatter release];
    [hvInitLock release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
    if (xl3Link) [xl3Link awakeAfterDocumentLoaded];
}

- (void) wakeUp 
{
	[super wakeUp];
	[xl3Link wakeUp];
}

- (void) sleep 
{
	[super sleep];
	if (xl3Link) {
		[xl3Link release];
		xl3Link = nil;
	}
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(connectionStateChanged)
                         name : XL3_LinkConnectionChanged
                       object : xl3Link];
    
    [notifyCenter addObserver : self
                     selector : @selector(documentLoaded)
                         name : ORDocumentLoadedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(documentClosed)
                         name : ORDocumentClosedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(detectorStateChanged:)
                         name : ORPQDetectorStateChanged
                       object : nil];
}

- (void) documentLoaded
{
    self.isLoaded = true;
}

- (void) documentClosed
{
    self.isLoaded = false;
    if (hvThread) {
        //NSThread doesn't have api to wait until done!?
        while (![hvThread isFinished]) {
            sleep(1);
        }
    }
}

- (void) connectionStateChanged
{
    /* If we just connected, find out if Xilinx has been loaded or not. */
    if ([xl3Link isConnected]) {
        [self updateXl3Mode];
    } else {
        /* If we disconnected, assume we don't know the state any more. */
        initialized = FALSE;
        stateUpdated = FALSE;
    }
}

- (void) detectorStateChanged:(NSNotification*)aNote
{
    ORPQDetectorDB *detDB = [aNote object];

    if (!detDB) return;

    PQ_Crate *pqCrate = (PQ_Crate *)[detDB getCrate:[self crateNumber] ];

    if (!pqCrate || !pqCrate->valid[kCrate_exists]) return; // nothing to do if crate doesn't exist in the current state

    @try {
        [[self undoManager] disableUndoRegistration];
        
        if (pqCrate->valid[kCrate_ctcDelay]) {
            // currently this is always 0, but write this if we ever add it to the GUI
        }
        if (pqCrate->valid[kCrate_hvRelayMask1] && pqCrate->valid[kCrate_hvRelayMask2]) {
            uint64_t mask = ((uint64_t)pqCrate->hvRelayMask2 << 32) | pqCrate->hvRelayMask1;
            [self setRelayMask:mask];
            [self setRelayStatus:@"status: set"];
        }
        if (pqCrate->valid[kCrate_hvAOn]) {
            // don't set this
        }
        if (pqCrate->valid[kCrate_hvBOn]) {
            // don't set this
        }
        if (pqCrate->valid[kCrate_hvDacA]) {
            // don't set this [self setHvAVoltageDACSetValue:pqCrate->hvDacA];
        }
        if (pqCrate->valid[kCrate_hvDacB]) {
            // don't set this [self setHvBVoltageDACSetValue:pqCrate->hvDacB];
        }
        if (pqCrate->valid[kCrate_xl3ReadoutMask]) {
            [self setSlotMask:pqCrate->xl3ReadoutMask]; // note that this affects all GUI slot operations, not only readout
        }
        if (pqCrate->valid[kCrate_xl3Mode]) {
            [self setXl3Mode:pqCrate->xl3Mode];
        }
        // (voltage alarm thresholds aren't currently used)
        // (don't change HV setpoints)
        // (pedestal mask is set in the FEC32)
    }
    @finally {
        [[self undoManager] enableUndoRegistration];
    }
}

- (int) initAtRunStart
{
    /* Load the XL3 settings to hardware at the run start. This function
     * will launch a thread to set the settings so that they can be set
     * in parallel. */
    int slot, i, hv;
    ORFec32Model *fec;

    /* Before the run starts, we make sure that all channels with HV on
     * have their sequencers enabled, and all channels with HV off have
     * their triggers turned off. Turning the sequencers on for channels
     * with HV is to make sure that we don't have a blind flasher. Turning
     * triggers off for channels without HV is to prevent trigger dropout
     * due to a bug in the CMOS chip. Quoting Josh:
     *
     * "The problem here is that pickup will generate runt pulses into the
     *  SNOD, and the CMOS chip has a logical bug which then will latch
     *  the trigger signal without resetting it, creating dropout. Turning
     *  the thresholds to maximum will mitigate the pickup, but even then I'd
     *  only want to do that for a fixed (short) period of time."
     *
     * Note that we only set these in the model, but immediately after
     * call initCrate so all these settings are loaded to hardware shortly
     * after and before the run starts. */

    for (slot = 0; slot < 16; slot++) {
        fec = [[OROrderedObjManager for:[self guardian]] objectInSlot:16-slot];

        if (!fec) continue;

        for (i = 0; i < 32; i++) {
            hv = ([self relayMask] >> (slot*4 + (3-i/8))) & 0x1;

            if (hv) {
                if ([fec seqDisabled:i]) {
                    NSLogColor([NSColor redColor], @"%02d/%02d/%02d HV is on, turning sequencer on!\n", [self crateNumber], slot, i);
                    [fec setSeq:i enabled:YES];
                }
            } else {
                if ([fec trigger100nsEnabled:i]) {
                    NSLogColor([NSColor redColor], @"%02d/%02d/%02d HV is off, turning N100 trigger off!\n", [self crateNumber], slot, i);
                    [fec setTrigger100ns:i enabled:NO];
                }
                if ([fec trigger20nsEnabled:i]) {
                    NSLogColor([NSColor redColor], @"%02d/%02d/%02d HV is off, turning N20 trigger off!\n", [self crateNumber], slot, i);
                    [fec setTrigger20ns:i enabled:NO];
                }
            }
        }
    }

    /* Post a notification telling ORCA not to start the run until we've
     * finished initializing */
    if ([[self xl3Link] isConnected]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object:self];
        [self loadHardwareWithSlotMask: [self getSlotsPresent] withCallback: @selector(runStartDone:) target:self];
    }

    return 0;
}

- (void) zeroPedestalMasksAtRunStart
{
    /* Zero the pedestal masks at the start of a run. Normally, this will only
     * be called at the beginning of a physics run. The reason for doing this
     * is that it was noticed that the noise on the trigger signal seemed to
     * depend on how many channels had their pedestal enabled.
     *
     * See this shift report for more details:
     * http://snopl.us/shift/view/9e1ff17e58704756a99f947ec2509f39. */
    int slot;
    ORFec32Model *fec;

    /* First, set the pedestal mask in the GUI to zero. */
    for (slot = 0; slot < 16; slot++) {
        fec = [[OROrderedObjManager for:[self guardian]] objectInSlot:16-slot];

        if (!fec) continue;

        [fec setPedEnabledMask:0];
    }

    /* Post a notification telling ORCA not to start the run until we've
     * finished setting the pedestal masks. */
    if ([[self xl3Link] isConnected]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object:self];
        /* Actually zero the pedestal masks in a separate thread so that they
         * can be done in parallel at the start of a run. */
        [NSThread detachNewThreadSelector:@selector(_zeroPedestalMasksAtRunStart)
                                 toTarget:self
                               withObject:nil];
    }
}

- (void) _zeroPedestalMasksAtRunStart
{
    /* This function sets the pedestal mask at the start of the run, and then
     * posts a notification telling the run model that the run can start. */
    @autoreleasepool {
        [self setPedestals];

        /* Tell ORCA that we have finished setting the pedestal masks. */
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORReleaseRunStateChangeWait object:self];
    }
}

- (void) runStartDone: (CrateInitResults *) results
{
    if (results == NULL) {
        NSLogColor([NSColor redColor], @"%@: crate init failed\n",
                        [[self xl3Link] crateName]);
    }

    free(results);

    /* Tell ORCA that we have finished initializing */
    [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object:self];
}

- (void) makeMainController
{
	[self linkToController:@"XL3_LinkController"];
}

#pragma mark •••Accessors

- (BOOL) isTriggerON
{
    return _isTriggerON;
}

- (void) setIsTriggerON: (BOOL) isTriggerON
{
    if (isTriggerON != _isTriggerON) {
        _isTriggerON = isTriggerON;

	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelTriggerStatusChanged object:self];        
    }
}

- (NSString*) shortName
{
	return @"XL3";
}

- (bool) initialized
{
    return initialized;
}

- (bool) stateUpdated
{
    return stateUpdated;
}

- (id) controllerCard
{
	return self;
}

- (XL3_Link*) xl3Link
{
	return xl3Link;
}

- (void) setXl3Link:(XL3_Link*) aXl3Link
{
    if (xl3Link != aXl3Link) {
        [aXl3Link retain];
        [xl3Link release];
        xl3Link = aXl3Link;
    }
}

- (void) setGuardian:(id)aGuardian
{
	id oldGuardian = guardian;
	[super setGuardian:aGuardian];
	if (guardian){
		if (!xl3Link) {
			xl3Link = [[XL3_Link alloc] init];
		}
		[xl3Link setCrateName:[NSString stringWithFormat:@"XL3 crate %d", [self crateNumber]]];
		[xl3Link setIPNumber:[guardian iPAddress]];
		[xl3Link setPortNumber:[guardian portNumber]];	
	}
	
	if(oldGuardian != aGuardian){
		[oldGuardian setAdapter:nil];	//old crate can't use this card any more
	}
	
	if (!guardian) {
		[xl3Link setCrateName:[NSString stringWithFormat:@"XL3 crate ---"]];
		[xl3Link setIPNumber:[NSString stringWithFormat:@"0.0.0.0"]];
		[xl3Link setPortNumber:0];
		if ([xl3Link isConnected]) {
			[xl3Link disconnectSocket];
		}
		[xl3Link release];
		xl3Link = 0;
	}
	[aGuardian setAdapter:self];		//our new crate will use this card for hardware access
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    
    [self postNotificationName:ORSNOCardSlotChanged];
}

- (short) getNumberRegisters
{
	return kXl3NumRegisters;
}

- (NSString*) getRegisterName:(short) anIndex
{
	return reg[anIndex].regName;
}

- (uint32_t) getRegisterAddress: (short) anIndex
{
	return reg[anIndex].address;
}

- (BOOL) basicOpsRunning
{
	return basicOpsRunning;
}

- (void) setBasicOpsRunning:(BOOL)aBasicOpsRunning
{
	basicOpsRunning = aBasicOpsRunning;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelBasicOpsRunningChanged object:self];
}

- (BOOL) compositeXl3ModeRunning
{
	return xl3ModeRunning;
}

- (void) setCompositeXl3ModeRunning:(BOOL)aCompositeXl3ModeRunning
{
	xl3ModeRunning = aCompositeXl3ModeRunning;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3ModeRunningChanged object:self];
}

- (uint32_t) slotMask
{
	return selectedSlotMask;
}

- (void) setSlotMask:(uint32_t)aSlotMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setSlotMask:selectedSlotMask];
	selectedSlotMask = aSlotMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelSlotMaskChanged object:self];
}

- (BOOL) autoIncrement
{
	return autoIncrement;
}

- (void) setAutoIncrement:(BOOL)aAutoIncrement
{
	[[[self undoManager] prepareWithInvocationTarget:self] setAutoIncrement:autoIncrement];
	autoIncrement = aAutoIncrement;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelAutoIncrementChanged object:self];
}

- (unsigned short) repeatDelay
{
	return repeatDelay;
}

- (void) setRepeatDelay:(unsigned short)aRepeatDelay
{
	if(aRepeatDelay<=0)aRepeatDelay = 1;
	[[[self undoManager] prepareWithInvocationTarget:self] setRepeatDelay:repeatDelay];
	
	repeatDelay = aRepeatDelay;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelRepeatDelayChanged object:self];
}

- (short) repeatOpCount
{
	return repeatOpCount;
}

- (void) setRepeatOpCount:(short)aRepeatCount
{
	if(aRepeatCount<=0)aRepeatCount = 1;
	[[[self undoManager] prepareWithInvocationTarget:self] setRepeatOpCount:repeatOpCount];
	
	repeatOpCount = aRepeatCount;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelRepeatCountChanged object:self];
}

- (uint32_t) writeValue
{
	return writeValue;
}

- (void) setWriteValue:(uint32_t)aWriteValue
{
	[[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:writeValue];
	
	writeValue = aWriteValue;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelWriteValueChanged object:self];
}	


- (int) selectedRegister
{
	return selectedRegister;
}

- (void) setSelectedRegister:(int)aSelectedRegister
{
	[[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegister:selectedRegister];	
	selectedRegister = aSelectedRegister;	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelSelectedRegisterChanged object:self];
}

- (NSString*) xl3LockName
{
	return @"ORXL3Lock";
}

- (unsigned int) xl3Mode
{
	return xl3Mode;
}

- (void) setXl3Mode:(unsigned int)aXl3Mode
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3Mode:xl3Mode];
	xl3Mode = aXl3Mode;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3ModeChanged object:self];
}	

- (BOOL) xl3ModeRunning
{
	return xl3ModeRunning;
}

- (void) setXl3ModeRunning:(BOOL)anXl3ModeRunning
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3ModeRunning:xl3ModeRunning];
	xl3ModeRunning = anXl3ModeRunning;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3ModeRunningChanged object:self];
}

- (uint32_t) xl3RWAddressValue
{
	return xl3RWAddressValue;
}

- (void) setXl3RWAddressValue:(uint32_t)anXl3RWAddressValue
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3RWAddressValue:xl3RWAddressValue];
	xl3RWAddressValue = anXl3RWAddressValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3RWAddressValueChanged object:self];
}

- (uint32_t) xl3RWDataValue
{
	return xl3RWDataValue;
}

- (void) setXl3RWDataValue:(uint32_t)anXl3RWDataValue;
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3RWDataValue:xl3RWDataValue];
	xl3RWDataValue = anXl3RWDataValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3RWDataValueChanged object:self];
}

- (BOOL) xl3OpsRunningForKey:(id)aKey
{
	return [[xl3OpsRunning objectForKey:aKey] boolValue];
}

- (void) setXl3OpsRunning:(BOOL)anXl3OpsRunning forKey:(id)aKey
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3OpsRunning:NO forKey:aKey];
	[xl3OpsRunning setObject:[NSNumber numberWithBool:anXl3OpsRunning] forKey:aKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3OpsRunningChanged object:self];
}

- (uint32_t) xl3PedestalMask
{
	return xl3PedestalMask;
}

- (void) setXl3PedestalMask:(uint32_t)anXl3PedestalMask;
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3PedestalMask:xl3PedestalMask];
	xl3PedestalMask = anXl3PedestalMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3PedestalMaskChanged object:self];
}
 

- (uint32_t) xl3ChargeInjMask
{
    return xl3ChargeInjMask;
}

- (void) setXl3ChargeInjMask:(uint32_t)aXl3ChargeInjMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3ChargeInjMask:xl3ChargeInjMask];
	xl3ChargeInjMask = aXl3ChargeInjMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3ChargeInjChanged object:self];
    
}

- (unsigned char) xl3ChargeInjCharge
{
    return xl3ChargeInjCharge;
}

- (void) setXl3ChargeInjCharge:(unsigned char)aXl3ChargeInjCharge
{
	[[[self undoManager] prepareWithInvocationTarget:self] setXl3ChargeInjCharge:xl3ChargeInjCharge];
	xl3ChargeInjCharge = aXl3ChargeInjCharge;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3ChargeInjChanged object:self];    
}

- (unsigned short) pollXl3Time
{
    return pollXl3Time;
}

- (void) setPollXl3Time:(unsigned short)aPollXl3Time
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollXl3Time:pollXl3Time];
    pollXl3Time = aPollXl3Time;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelPollXl3TimeChanged object:self];    
}

- (BOOL) isPollingXl3
{
    return isPollingXl3;
}

- (void) setIsPollingXl3:(BOOL)aIsPollingXl3
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingXl3:isPollingXl3];
    isPollingXl3 = aIsPollingXl3;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingXl3Changed object:self];
    if (isPollingXl3) {
        [self setPollStatus:@"Polling loop running"];
        [self setCalcCMOSRatesFromCounts:NO];
        [self performSelector:@selector(pollXl3:) withObject:nil afterDelay:0.1];
    }    
    else {
        [self setPollStatus:@"Polling loop stopped."];
        if (pollThread && ![pollThread isFinished]) [pollThread cancel];
    }
}

- (BOOL) isPollingCMOSRates
{
    return isPollingCMOSRates;
}

- (void) setIsPollingCMOSRates:(BOOL)aIsPollingCMOSRates
{
    if (isPollingCMOSRates != aIsPollingCMOSRates) {
        [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingCMOSRates:isPollingCMOSRates];
        isPollingCMOSRates = aIsPollingCMOSRates;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingCMOSRatesChanged object:self];
        [self setCalcCMOSRatesFromCounts:NO];
    }
}

- (unsigned short) pollCMOSRatesMask
{
    return pollCMOSRatesMask;
}

- (void) setPollCMOSRatesMask:(unsigned short)aPollCMOSRatesMask
{
    if (pollCMOSRatesMask != aPollCMOSRatesMask) {
        [[[self undoManager] prepareWithInvocationTarget:self] setPollCMOSRatesMask:pollCMOSRatesMask];
        pollCMOSRatesMask = aPollCMOSRatesMask;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelPollCMOSRatesMaskChanged object:self];
        [self setCalcCMOSRatesFromCounts:NO];
    }
}

- (BOOL) isPollingPMTCurrents
{
    return isPollingPMTCurrents;
}

- (void) setIsPollingPMTCurrents:(BOOL)aIsPollingPMTCurrents
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingPMTCurrents:isPollingPMTCurrents];
    isPollingPMTCurrents = aIsPollingPMTCurrents;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingPMTCurrentsChanged object:self];        
}

- (unsigned short) pollPMTCurrentsMask
{
    return pollPMTCurrentsMask;
}

- (void) setPollPMTCurrentsMask:(unsigned short)aPollPMTCurrentsMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollPMTCurrentsMask:pollPMTCurrentsMask];
    pollPMTCurrentsMask = aPollPMTCurrentsMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelPollPMTCurrentsMaskChanged object:self];    
}

- (BOOL) isPollingFECVoltages
{
    return isPollingFECVoltages;
}

- (void) setIsPollingFECVoltages:(BOOL)aIsPollingFECVoltages
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingFECVoltages:isPollingFECVoltages];
    isPollingFECVoltages = aIsPollingFECVoltages;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingFECVoltagesChanged object:self];        
}

- (unsigned short) pollFECVoltagesMask
{
    return pollFECVoltagesMask;
}

- (void) setPollFECVoltagesMask:(unsigned short)aPollFECVoltagesMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollFECVoltagesMask:pollFECVoltagesMask];
    pollFECVoltagesMask = aPollFECVoltagesMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelPollFECVoltagesMaskChanged object:self];    
}

- (BOOL) isPollingXl3Voltages
{
    return isPollingXl3Voltages;
}

- (void) setIsPollingXl3Voltages:(BOOL)aIsPollingXl3Voltages
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingXl3Voltages:isPollingXl3Voltages];
    isPollingXl3Voltages = aIsPollingXl3Voltages;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingXl3VoltagesChanged object:self];        
}

- (BOOL) isPollingHVSupply
{
    return isPollingHVSupply;
}

- (void) setIsPollingHVSupply:(BOOL)aIsPollingHVSupply
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingHVSupply:isPollingHVSupply];
    isPollingHVSupply = aIsPollingHVSupply;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingHVSupplyChanged object:self];        
}

- (BOOL) isPollingXl3WithRun
{
    return isPollingXl3WithRun;
}

- (void) setIsPollingXl3WithRun:(BOOL)aIsPollingXl3WithRun
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingXl3WithRun:isPollingXl3WithRun];
    isPollingXl3WithRun = aIsPollingXl3WithRun;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingXl3WithRunChanged object:self];        
}

- (BOOL) isPollingVerbose
{
    return isPollingVerbose;
}

- (void) setIsPollingVerbose:(BOOL)aIsPollingVerbose
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsPollingVerbose:isPollingVerbose];
    isPollingVerbose = aIsPollingVerbose;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelIsPollingVerboseChanged object:self];        
}

- (NSString*) pollStatus
{
    if (!pollStatus) {
        return @"Status unknown";
    }
    return pollStatus;
}

- (void) setPollStatus:(NSString*)aPollStatus
{
    if (pollStatus) [pollStatus autorelease];
    if (aPollStatus) pollStatus = [aPollStatus copy];

	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelPollStatusChanged object:self];        
}

- (BOOL) hvEverUpdated
{
    return hvEverUpdated;
    
}

/**
 * Global variable to store the state of the OWL supply
 */
BOOL owlSupplyState = false;

/**
 * Called by the owl supply to set the state. Also posts a ORXL3HVStatusChanged 
 * notification to make sure all GUIs are properly updated in the event of a change.
 */
+ (void) setOwlSupplyOn:(BOOL)isOn {
    if (owlSupplyState != isOn) {
        owlSupplyState = isOn;
        NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
        for (uint32_t i = 0; i < [objs count]; i++) {
            ORXL3Model *xl3 = [objs objectAtIndex:i];
            if ([xl3 isOwlCrate]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:xl3];
                });
            }
        }
    }
}

/**
 * Returns true if the OWL supply is on
 */
+ (BOOL) owlSupplyOn {
    return owlSupplyState;
}

/**
 * Returns true if the crate has OWL PTMs connected
 */
- (BOOL) isOwlCrate {
    uint32_t n = [self crateNumber];
    if (n == 3 || n == 13 || n == 18) {
        return true;
    }
    return false;
}

- (void) setHvEverUpdated:(BOOL)ever
{
    hvEverUpdated = ever;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];
    });
}

- (BOOL) hvSwitchEverUpdated
{
    return hvSwitchEverUpdated;
}

- (void) setHvSwitchEverUpdated:(BOOL)ever
{
    hvSwitchEverUpdated = ever;
}

- (BOOL) hvAFromDB
{
    return hvAFromDB;
}

- (void) setHvAFromDB:(BOOL)fromdb
{
    hvAFromDB = fromdb;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];
    });
}

- (BOOL) hvBFromDB
{
    return hvBFromDB;
}

- (void) setHvBFromDB:(BOOL)fromdb
{
    hvBFromDB = fromdb;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];
    });
}

- (BOOL) hvARamping
{
    return hvARamping;
}

- (void) setHvARamping:(BOOL)ramping
{
    hvARamping = ramping;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];
    });
}

- (BOOL) hvBRamping
{
    return hvBRamping;
}

- (void) setHvBRamping:(BOOL)ramping
{
    hvBRamping = ramping;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];
    });
}

- (BOOL) hvASwitch
{
    return hvASwitch;
}

- (void) setHvASwitch:(BOOL)aHvASwitch
{
    if (hvASwitch != aHvASwitch) {
        hvASwitch = aHvASwitch;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];
        });
    }
}

- (BOOL) hvBSwitch
{
    return hvBSwitch;
}

- (void) setHvBSwitch:(BOOL)aHvBSwitch
{
    if (hvBSwitch != aHvBSwitch) {
        hvBSwitch = aHvBSwitch;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
        });
    }
    if ([self crateNumber] == 16) {
        //Should be called even if the model value appears not to change to
        //properly update the GUI and keep everything consistent
        [ORXL3Model setOwlSupplyOn:aHvBSwitch];
    }
}

- (BOOL) hvANeedsUserIntervention
{
    return hvANeedsUserIntervention;
}

- (void) setHvANeedsUserIntervention:(BOOL)needs
{
    hvANeedsUserIntervention = needs;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];
    });
}

- (BOOL) hvBNeedsUserIntervention
{
    return hvBNeedsUserIntervention;
}

- (void) setHvBNeedsUserIntervention:(BOOL)needs
{
    hvBNeedsUserIntervention = needs;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];
    });
}

- (uint32_t) hvAVoltageDACSetValue
{
    return hvAVoltageDACSetValue;
}

- (void) setHvAVoltageDACSetValue:(uint32_t)aHvAVoltageDACSetValue {
    hvAVoltageDACSetValue = aHvAVoltageDACSetValue;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
    });
}

- (uint32_t) hvBVoltageDACSetValue
{
    return hvBVoltageDACSetValue;
}

- (void) setHvBVoltageDACSetValue:(uint32_t)aHvBVoltageDACSetValue {
    hvBVoltageDACSetValue = aHvBVoltageDACSetValue;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
    });
}

- (float) hvAVoltageReadValue
{
    return _hvAVoltageReadValue;
}

- (void) setHvAVoltageReadValue:(float)hvAVoltageReadValue
{
    _hvAVoltageReadValue = hvAVoltageReadValue;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
    });
}

- (float) hvBVoltageReadValue
{
    return _hvBVoltageReadValue;
}

- (void) setHvBVoltageReadValue:(float)hvBVoltageReadValue
{
    _hvBVoltageReadValue = hvBVoltageReadValue;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
    });
}

- (float) hvACurrentReadValue
{
    return _hvACurrentReadValue;
}

- (void) setHvACurrentReadValue:(float)hvACurrentReadValue
{
    _hvACurrentReadValue = hvACurrentReadValue;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
    });
}

- (float) hvBCurrentReadValue
{
    return _hvBCurrentReadValue;
}

- (void) setHvBCurrentReadValue:(float)hvBCurrentReadValue
{
    _hvBCurrentReadValue = hvBCurrentReadValue;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];        
    });
}

- (uint32_t) hvAVoltageTargetValue
{
    return _hvAVoltageTargetValue;
}

- (void) setHvAVoltageTargetValue:(uint32_t)hvAVoltageTargetValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvAVoltageTargetValue:_hvAVoltageTargetValue];
    _hvAVoltageTargetValue = hvAVoltageTargetValue;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVTargetValueChanged object:self];        
    });
}

- (uint32_t) hvBVoltageTargetValue
{
    return _hvBVoltageTargetValue;
}

- (void) setHvBVoltageTargetValue:(uint32_t)hvBVoltageTargetValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvBVoltageTargetValue:_hvBVoltageTargetValue];
    _hvBVoltageTargetValue = hvBVoltageTargetValue;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVTargetValueChanged object:self];        
    });
}

- (uint32_t) hvNominalVoltageA
{
    return _hvNominalVoltageA;
}

- (void) setHvNominalVoltageA:(uint32_t)hvNominalVoltageA
{
    _hvNominalVoltageA = hvNominalVoltageA;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVNominalVoltageChanged object:self];
    });
}

- (uint32_t) hvNominalVoltageB
{
    return _hvNominalVoltageB;
}

- (void) setHvNominalVoltageB:(uint32_t)hvNominalVoltageB
{
    _hvNominalVoltageB = hvNominalVoltageB;
    dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVNominalVoltageChanged object:self];
    });
}

- (uint32_t) hvACMOSRateLimit
{
    return _hvACMOSRateLimit;
}

- (void) setHvACMOSRateLimit:(uint32_t)hvACMOSRateLimit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvACMOSRateLimit:_hvACMOSRateLimit];
    _hvACMOSRateLimit = hvACMOSRateLimit;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVCMOSRateLimitChanged object:self];            
}

- (uint32_t) hvBCMOSRateLimit
{
    return _hvBCMOSRateLimit;
}

- (void) setHvBCMOSRateLimit:(uint32_t)hvBCMOSRateLimit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvBCMOSRateLimit:_hvBCMOSRateLimit];
    _hvBCMOSRateLimit = hvBCMOSRateLimit;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVCMOSRateLimitChanged object:self];            
}

- (uint32_t) hvACMOSRateIgnore
{
    return _hvACMOSRateIgnore;
}

- (void) setHvACMOSRateIgnore:(uint32_t)hvACMOSRateIgnore
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvACMOSRateIgnore:_hvACMOSRateIgnore];
    _hvACMOSRateIgnore = hvACMOSRateIgnore;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVCMOSRateIgnoreChanged object:self];            
}

- (uint32_t) hvBCMOSRateIgnore
{
    return _hvBCMOSRateIgnore;
}

- (void) setHvBCMOSRateIgnore:(uint32_t)hvBCMOSRateIgnore
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHvBCMOSRateIgnore:_hvBCMOSRateIgnore];
    _hvBCMOSRateIgnore = hvBCMOSRateIgnore;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHVCMOSRateIgnoreChanged object:self];            
}

- (uint64_t) relayMask
{
    return relayMask;
}

- (void) setRelayMask:(uint64_t)aRelayMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRelayMask:relayMask];
    relayMask = aRelayMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelRelayMaskChanged object:self];        
}

- (uint64_t) relayViewMask
{
    return relayViewMask;
}

- (void) setRelayViewMask:(uint64_t)aRelayViewMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRelayViewMask:relayViewMask];
    relayViewMask = aRelayViewMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelRelayMaskChanged object:self];
}


- (NSString*) relayStatus
{
    if (!relayStatus) {
        return @"status: UNKNOWN";
    }
    id result;
    @synchronized(self) {
        result = [relayStatus retain];
    }
    return [result autorelease];
}

- (void) setRelayStatus:(NSString *)aRelayStatus
{
    @synchronized(self) {
        if (relayStatus != aRelayStatus) {
            if (relayStatus) [relayStatus autorelease];
            if (aRelayStatus) relayStatus = [aRelayStatus copy];
        }
    }
    
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelRelayStatusChanged object:self];        
}

- (BOOL) isXl3VltThresholdInInit
{
    return _isXl3VltThresholdInInit;
}

- (void) setIsXl3VltThresholdInInit:(BOOL)aIs
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsXl3VltThresholdInInit:[self isXl3VltThresholdInInit]];
    _isXl3VltThresholdInInit = aIs;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3VltThresholdInInitChanged object:self];
}

- (int) slotConv
{
    return [self slot];
}

- (int) crateNumber
{
    return [guardian crateNumber];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"SNO Crate %d, card %u",(int)[self crateNumber], (int)[self stationNumber]];
}

- (NSComparisonResult)	slotCompare:(id)otherCard
{
    return [self stationNumber] - [otherCard stationNumber];
}

- (void) setCrateNumber:(int)crateNumber
{
	[[self guardian] setCrateNumber:crateNumber];
}

- (NSComparisonResult) XL3NumberCompare:(id)aCard
{
    return [self crateNumber] - [aCard crateNumber];
}

- (BOOL) changingPedMask
{
    return changingPedMask;
}

#pragma mark •••DB Helpers

#define swapLong(x) (((uint32_t)(x) << 24) | (((uint32_t)(x) & 0x0000FF00) <<  8) | (((uint32_t)(x) & 0x00FF0000) >>  8) | ((uint32_t)(x) >> 24))
#define swapShort(x) (((uint16_t)(x) <<  8) | ((uint16_t)(x)>>  8))

void SwapLongBlock(void* p, int32_t n)
{
    int32_t* lp = (int32_t*)p;
    int32_t i;
    for(i=0;i<n;i++){
        int32_t x = *lp;
        *lp =  (((x) & 0x000000FF) << 24) |    
        (((x) & 0x0000FF00) <<  8) |    
        (((x) & 0x00FF0000) >>  8) |    
        (((x) & 0xFF000000) >> 24);
        lp++;
    }
}

- (ORCouchDB*) debugDBRef
{
    SNOPModel *snop;

    NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"SNOPModel")];

	if([objs count]) {
		snop = [objs objectAtIndex:0];
    } else {
        return NULL;
    }

    return [snop debugDBRef:self];
}

- (void) synthesizeDefaultsIntoBundle:(MB*)aBundle forSlot:(unsigned short)aSlot
{
	uint16_t s_mbID[1] = {0x0000};
	uint16_t s_dbID[4] = {0x0000, 0x0000, 0x0000, 0x0000};

	//vBals are gains per channel x: [0][x] high, [1][x] low
	uint8_t s_vBal[2][32] = {{ 110, 110, 110, 110, 110, 110, 110, 110,
		 		   110, 110, 110, 110, 110, 110, 110, 110,
				   110, 110, 110, 110, 110, 110, 110, 110,
				   110, 110, 110, 110, 110, 110, 110, 110 },
				 { 110, 110, 110, 110, 110, 110, 110, 110,
				   110, 110, 110, 110, 110, 110, 110, 110,
				   110, 110, 110, 110, 110, 110, 110, 110,
				   110, 110, 110, 110, 110, 110, 110, 110 }};

	uint8_t s_vThr[32] = {	255, 255, 255, 255, 255, 255, 255, 255,
				255, 255, 255, 255, 255, 255, 255, 255,
				255, 255, 255, 255, 255, 255, 255, 255,
				255, 255, 255, 255, 255, 255, 255, 255 };


	//tDisc index definitions: 0=ch0-3, 1=ch4-7, 2=ch8-11, etc
	uint8_t s_tDisc_rmp[8] =   { 120, 120, 120, 120, 120, 120, 120, 120 }; // back edge timing ramp
	uint8_t s_tDisc_rmpup[8] = { 115, 115, 115, 115, 115, 115, 115, 115 }; // front edge timing ramp
	uint8_t s_tDisc_vsi[8] =   { 120, 120, 120, 120, 120, 120, 120, 120 }; // short integrate voltage
	uint8_t s_tDisc_vli[8] =   { 120, 120, 120, 120, 120, 120, 120, 120 }; // int32_t integrate voltage
	

	//tCmos: the following are motherboard wide constants
	aBundle->tCmos.vMax = 203; // upper TAC reference voltage
	aBundle->tCmos.tacRef = 72; // lower TAC reference voltage
	aBundle->tCmos.isetm[0] = 200; // primary timing current (0=tac0,1=tac1)
	aBundle->tCmos.isetm[1] = 200; // primary timing current (0=tac0,1=tac1)
	aBundle->tCmos.iseta[0] = 0; // secondary timing current 
	aBundle->tCmos.iseta[1] = 0; // secondary timing current 
	// TAC shift register load bits channel 0 to 31, assume same bits for all channels
	// bits go from right to left
	// TAC0-adj0  0 (1=enable), TAC0-adj1  0 (1=enable), TAC0-adj2 0 (1=enable), TAC0-main 0 (0=enable)
	// same for TAC1	
	uint8_t s_TCmosac_shift[32] = { 0, 0, 0, 0, 0, 0, 0, 0,
					  0, 0, 0, 0, 0, 0, 0, 0,
					  0, 0, 0, 0, 0, 0, 0, 0,
					  0, 0, 0, 0, 0, 0, 0, 0 };
	// vInt
	aBundle->vInt = 205; //integrator output voltage

	//chinj
	//aBundle->chinj.hv_id = 0x0000; // HV card id
	aBundle->hvRef = 0x00; // MB control voltage, charge inj value
	//aBundle->chinj.ped_time = 100; // MTCD pedestal width (DONT NEED THIS HERE)

	//tr100 width, channel 0 to 31, only bits 0 to 6 defined, bit0-5 delay, bit6 enable
	uint8_t s_Tr100delay[32] = { 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f,
					0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f,
					0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f,
					0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f };

	//uint8_t s_Tr100delay[32] = { 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f,
    //    0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f,
    //    0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f,
    //    0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f };

	//tr20 width, channel 0 to 31, only bits 0 to 5 defined, bit0-4 width, bit5 enable from PennDB
	uint8_t s_Tr20width[32] = { 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
					0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
					0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
					0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30 };

	//uint8_t s_Tr20width[32] = { 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10,
    //    0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10,
    //    0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10,
    //    0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10 };
	
	//tr20 delay, channel 0 to 31, only bits 0 to 3 defined from PennDB
	uint8_t s_Tr20delay[32] = {	0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0 }; 
	//sane defaults from DB spec
	/*
	uint8_t s_Tr20delay[32] = {	2, 2, 2, 2, 2, 2, 2, 2,
					2, 2, 2, 2, 2, 2, 2, 2,
					2, 2, 2, 2, 2, 2, 2, 2,
					2, 2, 2, 2, 2, 2, 2, 2 }; 
	*/
	
	//sCmos remaining 10 bits, channel 0 to 31, only bits 0 to 9 defined
	uint16_t s_sCmos[32] = { 0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0,
					0, 0, 0, 0, 0, 0, 0, 0 }; 

	//ch_disable bits 1 == disabled
	aBundle->disableMask = 0;
		
	memcpy(&aBundle->mbID, s_mbID, 2);
	memcpy(aBundle->dbID, s_dbID, 8);
	memcpy(aBundle->vBal, s_vBal, 64);
	memcpy(aBundle->vThr, s_vThr, 32);
	memcpy(aBundle->tDisc.rmp, s_tDisc_rmp, 8);
	memcpy(aBundle->tDisc.rmpup, s_tDisc_rmpup, 8);
	memcpy(aBundle->tDisc.vsi, s_tDisc_vsi, 8);
	memcpy(aBundle->tDisc.vli, s_tDisc_vli, 8);
	memcpy(aBundle->tCmos.tacShift, s_TCmosac_shift, 32);
    memset(aBundle->tr100.mask, 1, 32);
	memcpy(aBundle->tr100.tDelay, s_Tr100delay, 32);
    memset(aBundle->tr20.mask, 1, 32);
	memcpy(aBundle->tr20.tWidth, s_Tr20width, 32);
	memcpy(aBundle->tr20.tDelay, s_Tr20delay, 32);
	memcpy(aBundle->sCmos, s_sCmos, 64);
}

- (void) byteSwapBundle:(MB*) mb
{
    /* Byte swap a FEC bundle. Note that we only byte swap some of the
     * variables because the rest are just bytes and so don't need to
     * be swapped. */

    int i;
    
    mb->mbID = swapShort(mb->mbID);
    for (i=0; i<4; i++) {
        mb->dbID[i] = swapShort(mb->dbID[i]);
    }

    for (i=0; i<32; i++) {
        mb->sCmos[i] = swapShort(mb->sCmos[i]);
    }

    mb->disableMask = swapLong(mb->disableMask);  
}

- (void) synthesizeFECIntoBundle:(MB*) mb forSlot:(unsigned short) slot
{
    int i, dbNum, channel;
    ORFec32Model *fec;
    ORFecDaughterCardModel *db;

    [self synthesizeDefaultsIntoBundle:mb forSlot:slot];

    fec = [[OROrderedObjManager for:[self guardian]] objectInSlot:16-slot];

    if (!fec) return;

    mb->mbID = 0;
    for (i = 0; i < 4; i++) {
        mb->dbID[i] = 0;
    }

    for (dbNum = 0; dbNum < 4; dbNum++) {
        if (![fec dcPresent:dbNum]) continue;

        db = [fec dc:dbNum];

        for (channel = 0; channel < 8; channel++) {
            mb->vThr[dbNum*8+channel] = [db vt:channel];
            mb->tCmos.tacShift[dbNum*8+channel] = [db tac0trim:channel];
            mb->sCmos[dbNum*8+channel] = [db tac1trim:channel];

            /* Currently the N100 and N20 trigger masks are *not*
             * set using the mask variable. Instead the ML403 sets these
             * triggers using the delay and width variables.
             *
             * For now, we set both since the detector database uses
             * the mask fields. There will soon be a pull request to
             * the ML403 code to use the mask variables at which point
             * this warning and the code which sets the masks via
             * the delay and width fields can be deleted. */

            mb->tr100.tDelay[dbNum*8+channel] = [db ns100width:channel];

            if ([fec trigger100nsEnabled: (dbNum*8 + channel)]) {
                mb->tr100.mask[dbNum*8+channel] = 1;
            } else {
                mb->tr100.mask[dbNum*8+channel] = 0;
            }

            mb->tr20.tDelay[dbNum*8+channel] = [db ns20delay:channel];
            mb->tr20.tWidth[dbNum*8+channel] = [db ns20width:channel];

            if ([fec trigger20nsEnabled: (dbNum*8 + channel)]) {
                mb->tr20.mask[dbNum*8+channel] = 1;
            } else {
                mb->tr20.mask[dbNum*8+channel] = 0;
            }

            for (i=0; i<2; i++) {
                mb->vBal[i][dbNum*8+channel] = [db vb:i*8+channel];
            }
        }
        
        for (i=0; i<2; i++) {
            mb->tDisc.rmp[dbNum*2+i] = [db rp2:i];
            mb->tDisc.rmpup[dbNum*2+i] = [db rp1:i];
            mb->tDisc.vsi[dbNum*2+i] = [db vsi:i];
            mb->tDisc.vli[dbNum*2+i] = [db vli:i];
        }
    }

    mb->vInt = [fec vRes];
    mb->hvRef = [fec hVRef];
    
    // board related    0-ISETA1 1-ISETA0 2-ISETM1 3-ISETM0 4-TACREF 5-VMAX
    mb->tCmos.iseta[1] = [fec cmos:0];
    mb->tCmos.iseta[0] = [fec cmos:1];
    mb->tCmos.isetm[1] = [fec cmos:2];
    mb->tCmos.isetm[0] = [fec cmos:3];
    mb->tCmos.tacRef = [fec cmos:4];
    mb->tCmos.vMax = [fec cmos:5];

    mb->disableMask = (unsigned int)[fec seqDisabledMask];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    int i;
    
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];

    [self setSlot:              [decoder decodeIntForKey:@"slot"]];
    [self setSelectedRegister:  [decoder decodeIntForKey:@"ORXL3ModelSelectedRegister"]];

    xl3Link = [[decoder decodeObjectForKey:@"XL3_Link"] retain];

    [self setAutoIncrement:         [decoder decodeBoolForKey:@"ORXL3ModelAutoIncrement"]];
    [self setRepeatDelay:           [decoder decodeIntegerForKey:@"ORXL3ModelRepeatDelay"]];
    [self setRepeatOpCount:         [decoder decodeIntegerForKey:@"ORXL3ModelRepeatOpCount"]];
    [self setXl3Mode:               [decoder decodeIntForKey:@"ORXL3ModelXl3Mode"]];
    [self setSlotMask:              [decoder decodeIntForKey:@"ORXL3ModelSlotMask"]];
    [self setXl3RWAddressValue:     [decoder decodeIntForKey:@"ORXL3ModelXl3RWAddressValue"]];
    [self setXl3RWDataValue:        [decoder decodeIntForKey:@"ORXL3ModelXl3RWDataValue"]];
    [self setXl3PedestalMask:       [decoder decodeIntForKey:@"ORXL3ModelXl3PedestalMask"]];
    [self setXl3ChargeInjMask:      [decoder decodeIntForKey:@"ORXL3ModelXl3ChargeInjMask"]];
    [self setXl3ChargeInjCharge:    [decoder decodeIntegerForKey:@"ORXL3ModelXl3ChargeInjCharge"]];
    [self setPollXl3Time:           [decoder decodeIntegerForKey:@"ORXL3ModelPollXl3Time"]];
    //[self setIsPollingXl3:          [decoder decodeBoolForKey:@"ORXL3ModelIsPollingXl3"]];
    [self setIsPollingXl3:NO];
    [self setIsPollingCMOSRates:    [decoder decodeBoolForKey:@"ORXL3ModelIsPollingCMOSRates"]];
    [self setPollCMOSRatesMask:     [decoder decodeIntegerForKey:@"ORXL3ModelPollCMOSRatesMask"]];
    [self setIsPollingPMTCurrents:  [decoder decodeBoolForKey:@"ORXL3ModelIsPollingPMTCurrents"]];
    [self setPollPMTCurrentsMask:   [decoder decodeIntegerForKey:@"ORXL3ModelPollPMTCurrentsMask"]];
    [self setIsPollingFECVoltages:  [decoder decodeBoolForKey:@"ORXL3ModelIsPollingFECVoltages"]];
    [self setPollFECVoltagesMask:   [decoder decodeIntegerForKey:@"ORXL3ModelPollFECVoltagesMask"]];
    [self setIsPollingXl3Voltages:  [decoder decodeBoolForKey:@"ORXL3ModelIsPollingXl3Voltages"]];
    [self setIsPollingHVSupply:     [decoder decodeBoolForKey:@"ORXL3ModelIsPollingHVSupply"]];
    [self setIsPollingXl3WithRun:   [decoder decodeBoolForKey:@"ORXL3ModelIsPollingXl3WithRun"]];
    [self setIsPollingVerbose:      [decoder decodeBoolForKey:@"ORXL3ModelIsPollingVerbose"]];
    [self setRelayMask:[decoder decodeInt64ForKey:@"ORXL3ModelRelayMask"]];
    [self setRelayViewMask: relayMask];
    [self setHvAVoltageDACSetValue:[decoder decodeIntForKey:@"ORXL3ModelHvAVoltageDACSetValue"]];
    [self setHvBVoltageDACSetValue:[decoder decodeIntForKey:@"ORXL3ModelHvBVoltageDACSetValue"]];
    [self setHvAVoltageTargetValue:[decoder decodeIntForKey:@"ORXL3ModelhvAVoltageTargetValue"]];
    [self setHvBVoltageTargetValue:[decoder decodeIntForKey:@"ORXL3ModelhvBVoltageTargetValue"]];
    [self setHvACMOSRateLimit:  [decoder decodeIntForKey:@"ORXL3ModelhvACMOSRateLimit"]];
    [self setHvBCMOSRateLimit:  [decoder decodeIntForKey:@"ORXL3ModelhvBCMOSRateLimit"]];
    [self setHvACMOSRateIgnore: [decoder decodeIntForKey:@"ORXL3ModelhvACMOSRateIgnore"]];
    [self setHvBCMOSRateIgnore: [decoder decodeIntForKey:@"ORXL3ModelhvBCMOSRateIgnore"]];
    [self setXl3Mode:           [decoder decodeIntForKey:@"Xl3Mode"]];
    [self setIsTriggerON:       [decoder decodeBoolForKey:@"isTriggerON"]];

    initialized = FALSE;
    stateUpdated = FALSE;

    for (i=0; i<12; i++) {
        [self setXl3VltThreshold:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"ORXL3ModelVltThreshold%i", i]]];
    }
    [self setIsXl3VltThresholdInInit:[decoder decodeBoolForKey:@"ORXL3ModelXl3VltThresholdInInit"]];

    if (xl3Mode == 0) [self setXl3Mode: INIT_MODE];
    if (xl3OpsRunning == nil) xl3OpsRunning = [[NSMutableDictionary alloc] init];
    [self setXl3InitInProgress:NO];
    //if (isPollingXl3 == YES) [self setIsPollingXl3:NO];

    //fill the safe bundle for first crate init, then pull the FEC and DB IDs
    MB aConfigBundle;
    for (i=0; i<16; i++) {
        memset(&aConfigBundle, 0, sizeof(MB));
        [self synthesizeDefaultsIntoBundle:&aConfigBundle forSlot:i];
        memcpy(&safe_bundle[i], &aConfigBundle, sizeof(MB));
    }

    self.hvAQueryWaiting = false;
    self.hvBQueryWaiting = false;
    self.hvANeedsUserIntervention = false;
    self.hvBNeedsUserIntervention = false;
    self.isLoaded = false;
    
    [self safeHvInit];
     
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    int i;

    [super encodeWithCoder:encoder];
    [encoder encodeInt:selectedRegister     forKey:@"ORXL3ModelSelectedRegister"];
    [encoder encodeInt:[self slot]          forKey:@"slot"];
    [encoder encodeObject:xl3Link           forKey:@"XL3_Link"];
    [encoder encodeBool:autoIncrement       forKey:@"ORXL3ModelAutoIncrement"];
    [encoder encodeInteger:repeatDelay          forKey:@"ORXL3ModelRepeatDelay"];
    [encoder encodeInteger:repeatOpCount        forKey:@"ORXL3ModelRepeatOpCount"];
    [encoder encodeInt:xl3Mode              forKey:@"ORXL3ModelXl3Mode"];
    [encoder encodeInt:selectedSlotMask     forKey:@"ORXL3ModelSlotMask"];
    [encoder encodeInt:xl3RWAddressValue    forKey:@"ORXL3ModelXl3RWAddressValue"];
    [encoder encodeInt:xl3RWDataValue       forKey:@"ORXL3ModelXl3RWDataValue"];
    [encoder encodeInt:xl3PedestalMask      forKey:@"ORXL3ModelXl3PedestalMask"];
    [encoder encodeInt:xl3ChargeInjMask     forKey:@"ORXL3ModelXl3ChargeInjMask"];
    [encoder encodeInteger:xl3ChargeInjCharge   forKey:@"ORXL3ModelXl3ChargeInjCharge"];

    [encoder encodeInteger:pollXl3Time              forKey:@"ORXL3ModelPollXl3Time"];
    [encoder encodeBool:isPollingXl3            forKey:@"ORXL3ModelIsPollingXl3"];
    [encoder encodeBool:isPollingCMOSRates      forKey:@"ORXL3ModelIsPollingCMOSRates"];
    [encoder encodeInteger:pollCMOSRatesMask        forKey:@"ORXL3ModelPollCMOSRatesMask"];
    [encoder encodeBool:isPollingPMTCurrents    forKey:@"ORXL3ModelIsPollingPMTCurrents"];
    [encoder encodeInteger:pollPMTCurrentsMask      forKey:@"ORXL3ModelPollPMTCurrentsMask"];
    [encoder encodeBool:isPollingFECVoltages    forKey:@"ORXL3ModelIsPollingFECVoltages"];
    [encoder encodeInteger:pollFECVoltagesMask      forKey:@"ORXL3ModelPollFECVoltagesMask"];
    [encoder encodeBool:isPollingXl3Voltages    forKey:@"ORXL3ModelIsPollingXl3Voltages"];
    [encoder encodeBool:isPollingHVSupply       forKey:@"ORXL3ModelIsPollingHVSupply"];
    [encoder encodeBool:isPollingXl3WithRun     forKey:@"ORXL3ModelIsPollingXl3WithRun"];
    [encoder encodeBool:isPollingVerbose        forKey:@"ORXL3ModelIsPollingVerbose"];
    [encoder encodeInt:hvAVoltageDACSetValue    forKey:@"ORXL3ModelHvAVoltageDACSetValue"];
    [encoder encodeInt:hvBVoltageDACSetValue    forKey:@"ORXL3ModelHvBVoltageDACSetValue"];
    [encoder encodeInt:_hvAVoltageTargetValue   forKey:@"ORXL3ModelhvAVoltageTargetValue"];
    [encoder encodeInt:_hvBVoltageTargetValue   forKey:@"ORXL3ModelhvBVoltageTargetValue"];
    [encoder encodeInteger:_hvNominalVoltageA       forKey:@"ORXL3ModelHvNominalVoltageA"];
    [encoder encodeInteger:_hvNominalVoltageB       forKey:@"ORXL3ModelHvNominalVoltageB"];
    [encoder encodeInt64:relayMask              forKey:@"ORXL3ModelRelayMask"];
    [encoder encodeInteger:relayViewMask          forKey:@"ORXL3ModelRelayViewMask"];
    [encoder encodeInt:_hvACMOSRateLimit        forKey:@"ORXL3ModelhvACMOSRateLimit"];
    [encoder encodeInt:_hvBCMOSRateLimit        forKey:@"ORXL3ModelhvBCMOSRateLimit"];
    [encoder encodeInt:_hvACMOSRateIgnore       forKey:@"ORXL3ModelhvACMOSRateIgnore"];
    [encoder encodeInt:_hvBCMOSRateIgnore       forKey:@"ORXL3ModelhvBCMOSRateIgnore"];
    [encoder encodeInt:xl3Mode                  forKey:@"Xl3Mode"];
    [encoder encodeBool:_isTriggerON            forKey:@"isTriggerON"];
    
    for (i = 0; i < 12; i++) {
        [encoder encodeFloat:[self xl3VltThreshold:i] forKey:[NSString stringWithFormat:@"ORXL3ModelVltThreshold%i", i]];
    }
    [encoder encodeBool:[self isXl3VltThresholdInInit] forKey:@"ORXL3ModelXl3VltThresholdInInit"];
}

#pragma mark •••Hardware Access

- (void) nominalSettingsCallback: (ORPQResult *) result
{
    int i, slot, channel;
    int n100, n20, sequencer, hv, resistor_pulled;
    NSInteger nrows,ncols;
    ORFec32Model *fec;

    if (!result) {
        NSLogColor([NSColor redColor], @"crate %02d: database request for nominal settings failed!\n", [self crateNumber]);
        return;
    }

    nrows = [result numOfRows];
    ncols = [result numOfFields];

    if (ncols != 6) {
        NSLogColor([NSColor redColor], @"crate %02d: expected 5 columns from the database, but got %i!\n", [self crateNumber], ncols);
        return;
    }

    if (nrows != 512) {
        NSLogColor([NSColor redColor], @"crate %02d: expected 512 rows from the database, but got %i!\n", [self crateNumber], nrows);
        return;
    }

    for (i = 0; i < nrows; i++) {
        slot = (int)[result getInt64atRow:i column:0];
        channel = (int)[result getInt64atRow:i column:1];
        n100 = (int)[result getInt64atRow:i column:2];
        n20 = (int)[result getInt64atRow:i column:3];
        sequencer = (int)[result getInt64atRow:i column:4];
        resistor_pulled = (int)[result getInt64atRow:i column:5];

        fec = [[OROrderedObjManager for:[self guardian]] objectInSlot:16-slot];

        if (!fec) continue;

        /* Check if the relay is open. */
        hv = !resistor_pulled && (([self relayMask] >> (slot*4 + (3-channel/8))) & 0x1);

        if (hv) {
            [fec setTrigger100ns:channel enabled:n100];
            [fec setTrigger20ns:channel enabled:n20];
            if (!sequencer) {
                NSLogColor([NSColor redColor], @"%02d/%02d/%02d HV is on, "
                    "turning sequencer on even though nominal state is off!\n",
                    [self crateNumber], slot, channel);
            }
            /* Turn sequencer on regardless of the nominal state if this
             * channel has HV on. */
            [fec setSeq:channel enabled:1];
        } else {
            [fec setTrigger100ns:channel enabled:NO];
            [fec setTrigger20ns:channel enabled:NO];
            [fec setSeq:channel enabled:sequencer];
        }
    }

    /* Set the hardware state. */
    [self loadTriggersAndSequencers];
}

- (void) loadNominalSettings
{
    /* Set the channel triggers and sequencers according to the nominal
     * settings from the database. */
    ORPQModel *db = [ORPQModel getCurrent];

    if (!db) {
        NSLog(@"Postgres object not found, please add it to the experiment!\n");
        return;
    }

    NSString *query = [NSString stringWithFormat:
        @"SELECT current_nominal_settings.slot, "
         "current_nominal_settings.channel, "
         "current_nominal_settings.n100, "
         "current_nominal_settings.n20, "
         "current_nominal_settings.sequencer, "
         "current_channel_status.resistor_pulled FROM "
         "current_nominal_settings, current_channel_status WHERE "
         "current_nominal_settings.crate   = current_channel_status.crate   AND "
         "current_nominal_settings.slot    = current_channel_status.slot    AND "
         "current_nominal_settings.channel = current_channel_status.channel AND "
         "current_nominal_settings.crate = %i",
         [self crateNumber]];

    [db dbQuery:query object:self selector:@selector(nominalSettingsCallback:) timeout:10.0];
}

- (void) _loadTriggersAndSequencers
{
    /* Function to actually load the current GUI channel trigger and sequencer
     * settings. This should be called in a separate thread since it will
     * block. Any exceptions will be caught and logged. */
    @try {
        [self loadTriggers];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"crate %02d: failed to set triggers. error: %@ reason: %@\n",
                   [self crateNumber], [e name], [e reason]);
    }

    @try {
        [self loadSequencers];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"crate %02d: failed to set sequencers. error: %@ reason: %@\n",
                   [self crateNumber], [e name], [e reason]);
    }
}

- (void) loadTriggersAndSequencers
{
    /* Loads the current GUI channel trigger and sequencer settings to the
     * hardware asynchronously. */
    if (![[self xl3Link] isConnected]) {
        NSLogColor([NSColor redColor], @"xl3 %02d is not connected!\n",
                    [self crateNumber]);
        return;
    }

    [NSThread detachNewThreadSelector:@selector(_loadTriggersAndSequencers)
        toTarget:self
        withObject:nil];
}

- (void) loadTriggers
{
    /* Loads the current GUI channel trigger settings to the hardware. This
     * function will block and so should only be called on a separate thread.
     * This function will raise an exception if any error occurs. */
    int slot, dbNum, channel;
    char payload[XL3_PAYLOAD_SIZE];
    ORFec32Model *fec;

    memset(&payload, 0, sizeof(payload));

    MultiSetCrateTriggersArgs *args = (MultiSetCrateTriggersArgs *) payload;

    args->slotMask = 0;

    for (slot = 0; slot < 16; slot++) {
        args->tr100Masks[slot] = 0;
        args->tr20Masks[slot] = 0;
    }

    for (slot = 0; slot < 16; slot++) {
        fec = [[OROrderedObjManager for:[self guardian]] objectInSlot:16-slot];

        if (!fec) continue;

        args->slotMask |= 1 << slot;

        if ([self isTriggerON]) {
            for (dbNum = 0; dbNum < 4; dbNum++) {
                if (![fec dcPresent:dbNum]) continue;

                for (channel = 0; channel < 8; channel++) {
                    if ([fec trigger100nsEnabled: (dbNum*8 + channel)]) {
                        args->tr100Masks[slot] |= 1 << (dbNum*8+channel);
                    }

                    if ([fec trigger20nsEnabled: (dbNum*8 + channel)]) {
                        args->tr20Masks[slot] |= 1 << (dbNum*8+channel);
                    }
                }
            }
        }
    }

    /* Convert args to network byte order. */
    args->slotMask = htonl(args->slotMask);

    for (slot = 0; slot < 16; slot++) {
        args->tr100Masks[slot] = htonl(args->tr100Masks[slot]);
        args->tr20Masks[slot] = htonl(args->tr20Masks[slot]);
    }

    [[self xl3Link] sendCommand:MULTI_SET_CRATE_TRIGGERS_ID withPayload:payload expectResponse:YES];

    MultiSetCrateTriggersResults *results = (MultiSetCrateTriggersResults *) payload;

    if (ntohl(results->errorMask)) {
        NSException *e = [NSException exceptionWithName:@"loadTriggersError"
                          reason:@"failed to load channel triggers"
                          userInfo:nil];
        [e raise];
    }
}

- (void) loadTriggersWithCrateMask:(NSMutableArray*)aXL3Mask
{
    /* Loads to the hardware an AND of the current GUI channel trigger settings
     * and a given mask. This function will block and so should only be called
     * on a separate thread. This function will raise an exception if any error
     * occurs. */
    int slot, dbNum, channel;
    char payload[XL3_PAYLOAD_SIZE];
    ORFec32Model *fec;

    memset(&payload, 0, sizeof(payload));

    MultiSetCrateTriggersArgs *args = (MultiSetCrateTriggersArgs *) payload;

    args->slotMask = 0;

    for (slot = 0; slot < 16; slot++) {
        args->tr100Masks[slot] = 0;
        args->tr20Masks[slot] = 0;
    }

    for (slot = 0; slot < 16; slot++) {
        fec = [[OROrderedObjManager for:[self guardian]] objectInSlot:16-slot];

        if (!fec) continue;

        args->slotMask |= 1 << slot;

        if ([self isTriggerON]) {
            for (dbNum = 0; dbNum < 4; dbNum++) {
                if (![fec dcPresent:dbNum]) continue;

                for (channel = 0; channel < 8; channel++) {
                    if ([fec trigger100nsEnabled: (dbNum*8 + channel)]) {
                        args->tr100Masks[slot] |= 1 << (dbNum*8+channel);
                    }

                    if ([fec trigger20nsEnabled: (dbNum*8 + channel)]) {
                        args->tr20Masks[slot] |= 1 << (dbNum*8+channel);
                    }
                }
            }
        }
    }

    /* AND with given mask */
    for (slot = 0; slot < 16; slot++) {
        unsigned int mask = [[aXL3Mask objectAtIndex:slot] unsignedIntValue];
        args->tr100Masks[slot] &= mask;
        args->tr20Masks[slot] &= mask;
    }

    /* Convert args to network byte order. */
    args->slotMask = htonl(args->slotMask);

    for (slot = 0; slot < 16; slot++) {
        args->tr100Masks[slot] = htonl(args->tr100Masks[slot]);
        args->tr20Masks[slot] = htonl(args->tr20Masks[slot]);
    }

    [[self xl3Link] sendCommand:MULTI_SET_CRATE_TRIGGERS_ID withPayload:payload expectResponse:YES];

    MultiSetCrateTriggersResults *results = (MultiSetCrateTriggersResults *) payload;

    if (ntohl(results->errorMask)) {
        NSException *e = [NSException exceptionWithName:@"loadTriggersError"
                                                 reason:@"failed to load channel triggers"
                                               userInfo:nil];
        [e raise];
    }
}

- (void) disableTriggers
{
    /* Turns off all channel level triggers. This function does *not* update
     * the GUI so once this function is called, the GUI will most likely be in
     * an inconsistent state. This can be useful in certain situations like ECA
     * runs where you want to disable channel triggers but then load them back
     * at the end of the run. This function will block until the operation
     * completes. This function will raise an exception if any error occurs. */
    int slot;
    char payload[XL3_PAYLOAD_SIZE];

    memset(&payload, 0, sizeof(payload));

    MultiSetCrateTriggersArgs *args = (MultiSetCrateTriggersArgs *) payload;

    args->slotMask = [self getSlotsPresent];

    for (slot = 0; slot < 16; slot++) {
        args->tr100Masks[slot] = 0;
        args->tr20Masks[slot] = 0;
    }

    /* Convert args to network byte order. */
    args->slotMask = htonl(args->slotMask);

    for (slot = 0; slot < 16; slot++) {
        args->tr100Masks[slot] = htonl(args->tr100Masks[slot]);
        args->tr20Masks[slot] = htonl(args->tr20Masks[slot]);
    }

    [[self xl3Link] sendCommand:MULTI_SET_CRATE_TRIGGERS_ID withPayload:payload expectResponse:YES];

    MultiSetCrateTriggersResults *results = (MultiSetCrateTriggersResults *) payload;

    if (ntohl(results->errorMask)) {
        NSException *e = [NSException exceptionWithName:@"loadTriggersError"
                          reason:@"failed to load channel triggers"
                          userInfo:nil];
        [e raise];
    }
}

- (void) loadSequencers
{
    /* Loads the current GUI channel sequencer settings to the hardware. This
     * function will block and so should only be called on a separate thread.
     * This function will raise an exception if any error occurs. */
    int slot;
    char payload[XL3_PAYLOAD_SIZE];
    ORFec32Model *fec;

    memset(&payload, 0, sizeof(payload));

    MultiSetCrateSequencersArgs *args = (MultiSetCrateSequencersArgs *) payload;

    args->slotMask = 0;

    for (slot = 0; slot < 16; slot++) {
        args->channelMasks[slot] = 0;
    }

    for (slot = 0; slot < 16; slot++) {
        fec = [[OROrderedObjManager for:[self guardian]] objectInSlot:16-slot];

        if (!fec) continue;

        args->slotMask |= 1 << slot;

        args->channelMasks[slot] = ~(unsigned int)[fec seqDisabledMask];
    }

    /* Convert args to network byte order. */
    args->slotMask = htonl(args->slotMask);

    for (slot = 0; slot < 16; slot++) {
        args->channelMasks[slot] = htonl(args->channelMasks[slot]);
    }

    [[self xl3Link] sendCommand:MULTI_SET_CRATE_SEQUENCERS_ID withPayload:payload expectResponse:YES];

    MultiSetCrateSequencersResults *results = (MultiSetCrateSequencersResults *) payload;

    if (ntohl(results->errorMask)) {
        NSException *e = [NSException exceptionWithName:@"loadSequencersError"
                          reason:@"failed to load channel sequencers"
                          userInfo:nil];
        [e raise];
    }
}

- (void) deselectCards
{
	[[self xl3Link] sendCommand:DESELECT_FECS_ID expectResponse:YES];
}

- (void) selectCards:(uint32_t) selectBits
{
	//??? xl2 compatibility
	//[self writeToXL2Register:XL2_SELECT_REG value: selectBits]; // select the cards by writing to the XL2 REG 0 
}


- (void) select:(ORSNOCard*) aCard
{
	//???xl2 compatibility
	/*
	uint32_t selectBits;
	if(aCard == self)	selectBits = 0; //XL2_SELECT_XL2;
	else				selectBits = (1L<<[aCard stationNumber]);
	//NSLog(@"selectBits for card in slot %d: 0x%x\n", [aCard slot], selectBits);
	[self selectCards:selectBits];
	*/
}

- (void) writeHardwareRegister:(uint32_t)regAddress value:(uint32_t) aValue
{
	uint32_t address = (uint32_t)(regAddress | WRITE_REG);
    uint32_t value = (uint32_t)aValue;

	@try {
		[xl3Link sendCommand:0UL toAddress:address withData:&value];
	}
	@catch (NSException* e) {
		NSLog(@"XL3 writeHadwareRegister at address: 0x%08x failed\n", regAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
}

- (uint32_t) readHardwareRegister:(uint32_t)regAddress
{
	uint32_t xl3Address = (uint32_t)(regAddress | READ_REG);
	uint32_t aValue = 0UL;

	@try {
		[xl3Link sendCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"XL3 readHadwareRegister at address: 0x%08x failed\n", regAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
	
	return aValue;
}

- (void) writeHardwareMemory:(uint32_t)memAddress value:(uint32_t)aValue
{
	uint32_t address = (uint32_t)(memAddress | WRITE_MEM);
    uint32_t value = (uint32_t)aValue;

	@try {
		[xl3Link sendCommand:0UL toAddress:(uint32_t)address withData:&value];
	}
	@catch (NSException* e) {
		NSLog(@"XL3 writeHadwareMemory at address: 0x%08x failed\n", memAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
}

- (uint32_t) readHardwareMemory:(uint32_t) memAddress
{
	uint32_t xl3Address = (uint32_t)(memAddress | READ_MEM);
	uint32_t aValue = 0UL;
	@try {
		[xl3Link sendCommand:0UL toAddress:(uint32_t)xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"XL3 readHadwareMemory at address: 0x%08x failed\n", memAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
	return aValue;
}

- (void) writeXL3Register:(short)aRegister value:(uint32_t)aValue
{
	if (aRegister >= kXl3NumRegisters) {
		NSLog(@"Error writing XL3 register out of range\n");
		return;
	}
	
	uint32_t address = XL3_SEL | [self getRegisterAddress:aRegister] | WRITE_REG;
	[self writeHardwareRegister:address value:aValue];
	return;
}


- (uint32_t) readXL3Register:(short)aRegister
{
	if (aRegister >= kXl3NumRegisters) {
		NSLog(@"Error reading XL3 register out of range\n");
		return 0;
	}

	uint32_t address = XL3_SEL | [self getRegisterAddress:aRegister] | READ_REG;
	uint32_t value = [self readHardwareRegister:address];
	return value;
}


//multi command calls
- (id) writeHardwareRegisterCmd:(uint32_t) aRegister value:(uint32_t) aBitPattern
{
	//return [[self xl1] writeHardwareRegisterCmd:aRegister value:aBitPattern];
	return self;
}

- (id) readHardwareRegisterCmd:(uint32_t) regAddress
{
	//return [[self xl1] readHardwareRegisterCmd:regAddress];
	return self;
}

- (id) delayCmd:(uint32_t) milliSeconds
{
	//return [[self xl1] delayCmd:milliSeconds]; 
	return self;
}

- (void) executeCommandList:(ORCommandList*)aList
{
	//[[self xl1] executeCommandList:aList];		
}

- (int) updateXl3Mode
{
    /* Update the model with the current XL3 state. */
    char payload[XL3_PAYLOAD_SIZE];
    memset(payload, 0, XL3_PAYLOAD_SIZE);
    
    CheckXL3StateResults* results = (CheckXL3StateResults*) payload;
    
    @try {
        [[self xl3Link] sendCommand:CHECK_XL3_STATE_ID withPayload:payload expectResponse:YES];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],
            @"xl3 %02d: failed to check XL3 state.\n", [self crateNumber]);
        return -1;
    }

    results->mode = ntohl(results->mode);
    results->debuggingMode = ntohl(results->debuggingMode);
    results->dataAvailMask = ntohl(results->dataAvailMask);
    results->xl3Clock = ntohl(results->xl3Clock);
    results->initialized = ntohl(results->initialized);

    if (results->initialized) {
        initialized = TRUE;
    } else {
        initialized = FALSE;
    }

    stateUpdated = TRUE;

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORXL3ModelStateChanged object:self userInfo:nil];

    [[self undoManager] disableUndoRegistration];
    [self setXl3Mode: results->mode];
    [[self undoManager] enableUndoRegistration];

    return 0;
}
    
- (int) setSequencerMask: (uint32_t) mask forSlot: (int) slot
{
     /* Returns -1 on error, 0 on success.
      Sets the sequencer mask for a single FEC */

    char payload[XL3_PAYLOAD_SIZE];
    memset(payload, 0, XL3_PAYLOAD_SIZE);

    SetSequencerArgs* data = (SetSequencerArgs*) payload;

    SetSequencerResults* results = (SetSequencerResults*)payload;


    data->slot = htonl((uint32_t) slot);
    data->channelMask = htonl(mask);

    @try {
        [[self xl3Link] sendCommand:SET_SEQUENCER_ID withPayload:payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLogColor([NSColor redColor],@"%@ error sending SET SEQUENCER command.\n",[[self xl3Link] crateName]);
        return -1;
    }

    if(htonl(results->errors)) {
        NSLogColor([NSColor redColor],@"XL3 error occured while setting sequencer\n");
        return -1;
    }

    return 0;
}

- (void) initCrate
{
    /* Do a full crate init */
    [self initCrateAsync: [self getSlotsPresent]
         withCallback: @selector(initCrateDone:)
         target: self];
}

- (void) loadHardware
{
    /* Load current ORCA settings to every single FEC */
    [self initCrateAsync: [self getSlotsPresent] withCallback:NULL target:NULL];
}

- (void) loadHardwareWithSlotMask: (uint32_t) slotMask
{
    /* Load current ORCA settings to select FECs */
    [self initCrateAsync: slotMask withCallback:NULL target:NULL];
}

- (void) loadHardwareWithSlotMask: (uint32_t) slotMask withCallback: (SEL) callback target: (id) target
{
    /* Load current ORCA settings to select FECs, and call `callback` with
     * the results. The callback should look like:
     *
     * - (void) callback: (CrateInitResults *) r
     *
     * If the crate init failed, the results pointer will be NULL. */

    [self initCrateAsync: slotMask withCallback:callback target:target];
}

- (void) resetCrateAsync
{
    /* Reset the crate in a new thread. */
    if (![[self xl3Link] isConnected]) {
        NSLogColor([NSColor redColor], @"xl3 %02d is not connected!\n",
                    [self crateNumber]);
        return;
    }
    
    [NSThread detachNewThreadSelector:@selector(resetCrate)
        toTarget:self withObject:nil];
}

- (void) resetCrate
{
    char payload[XL3_PAYLOAD_SIZE];
    ResetCrateArgs *args;
    ResetCrateResults *results;
    int i, j;

    /* Check that HV Relays for XL3 are open if performing a full crate init. */
    if ([self hvEverUpdated] && ([self hvASwitch] || [self hvBSwitch])) {
        NSLogColor([NSColor redColor], @"XL3 %02d has high voltage on.  HV must be turned off before a crate reset.\n", [self crateNumber]);
        return;
    }

    memset(payload, 0, XL3_PAYLOAD_SIZE);
    args = (ResetCrateArgs *) payload;

    /* Set xilFile to 1 to load normal xilinx file. Any other number will load
     * charge injection xilinx file. */
    args->xilFile = htonl(1);

    @try {
        [[self xl3Link] sendCommand:RESET_CRATE_ID withPayload:payload expectResponse:YES];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"Crate %02d reset failed. error: %@ reason: %@\n", [self crateNumber], [e name], [e reason]);
    }

    results = (ResetCrateResults *) payload;

    /* Swap back to native byte order. */
    results->errors = ntohl(results->errors);

    if (results->errors) {
        NSLogColor([NSColor redColor],
                   @"crate reset failed with errors for crate %02d.\n",
                   [self crateNumber]);
    }

    results->fecPresent = ntohl(results->fecPresent);

    for (i = 0; i < 16; i++) {
        results->hwareVals[i].mbID = ntohs(results->hwareVals[i].mbID);
        results->hwareVals[i].pmticID = ntohs(results->hwareVals[i].pmticID);
        for (j = 0; j < 4; j++) {
            results->hwareVals[i].dbID[j] = ntohs(results->hwareVals[i].dbID[j]);
        }
    }

    if ([NSThread isMainThread]) {
        [self checkCrateConfig:results];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self checkCrateConfig:results];
        });
    }

    /* Need to update the buttons on the GUI to disable the reset crate button
     * and enable the load hardware button. */
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateXl3Mode];
    });
}

- (void) initCrateAsync: (uint32_t) slotMask withCallback: (SEL) callback target: (id) target
{
    /* Initialize the crate in a separate thread and call the selector
     * `callback` when done. */
    int slot, channel;

    if (![[self xl3Link] isConnected]) {
        NSLogColor([NSColor redColor], @"xl3 %02d is not connected!\n",
                    [self crateNumber]);
        return;
    }
    
    MB* mbs = (MB *) calloc(16, sizeof(MB)); //move to avoid memory leak on early return. MAH

    for (slot = 0; slot < 16; slot++) {
        if ((slotMask & (1 << slot)) == 0) continue;

        [self synthesizeFECIntoBundle:&mbs[slot] forSlot:slot];
    }

    /* If the triggers OFF button has been pressed, turn off N100 and N20
     * triggers */
    if (![self isTriggerON]) {
        for (slot = 0; slot < 16; slot++) {
            if ((slotMask & (1 << slot)) == 0) continue;

            for (channel = 0; channel < 32; channel++) {
                mbs[slot].tr100.mask[channel] = 0;
                mbs[slot].tr20.mask[channel] = 0;
            }
        }
    }

    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:slotMask], @"slotmask",
                            [NSValue valueWithPointer:callback], @"callback",
                            [NSValue valueWithPointer:mbs], @"mbs",
                            target, @"target",
                             nil];
    [NSThread detachNewThreadSelector:@selector(initCrateAsyncThread:)
        toTarget:self withObject:args];
}

- (void) initCrateAsyncThread: (NSDictionary *) args
{
    /* NSThread requires a function with only one argument, so we
     * pass the arguments in a dictionary and call them here.
     * Ugh...
     */
    [self initCrate: [[args objectForKey:@"mbs"] pointerValue]
         slotMask: [[args objectForKey:@"slotmask"] intValue]
         withCallback: [[args objectForKey:@"callback"] pointerValue]
         target: [args objectForKey:@"target"]];
}

- (uint32_t) getSlotsPresent
{
    /* Returns a bitmask of which slots ORCA thinks are plugged in. */
    int slot;
    ORFec32Model *fec;

    uint32_t slotMask = 0;

    for (slot = 0; slot < 16; slot++) {
        fec = [[OROrderedObjManager for:[self guardian]] objectInSlot:16-slot];

        if (!fec) continue;

        slotMask |= (1 << slot);
    }

    return slotMask;
}

- (void) initCrate: (MB *) mbs slotMask: (uint32_t) slotMask withCallback: (SEL) callback target: (id) target
{
    /* Initialize the crate with a callback. The callback should look like:
     *
     * - (void) callback: (CrateInitResults *) r
     *
     * If the crate init failed, the results pointer will be NULL.
     *
     * The callback is called on the main thread.
     *
     * Note: The callback must call free() on the results pointer. */
    CrateInitResults *r = (CrateInitResults *) malloc(sizeof(CrateInitResults));

    if ([self initCrate: mbs slotMask: slotMask results: r]) {
        free(r);
        r = NULL;
    }

    if (callback) {
        /* We have to do this craziness with NSInvocation because
         * performSelector() can only call selectors which take NSObjects as
         * parameters. */
        NSInvocation *method = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:callback]];
        [method setSelector:callback];
        [method setTarget:target];
        [method setArgument:&r atIndex:2];
        [method performSelectorOnMainThread:@selector(invoke) withObject:nil
            waitUntilDone:NO];
    } else {
        if (r) free(r);
    }
}

- (int) initCrate: (MB *) mbs slotMask: (uint32_t) slotMask results: (CrateInitResults *) results
{
    /* Low level function to perform a crate init (load hardware settings).
     *
     * Note that this function will call free(mbs), so mbs should be a heap
     * allocated array of 16 MB structs.
     *
     * This function is thread safe (should only call sendCommand on the
     * XL3_Link which has the proper locks.
     *
     * Returns 0 on success, -1 on error. */
    int slot;
    char payload[XL3_PAYLOAD_SIZE];
    CrateInitSetupArgs *setupArgs;
    CrateInitArgs *crateInitArgs;

    /* Send the first 16 packets which have the FEC settings. Note that
     * no hardware is updated until we send one more CrateInitArgs packet */
    for (slot = 0; slot < 16; slot++) {
        if ((slotMask & (1 << slot)) == 0) continue;

        memset(payload, 0, XL3_PAYLOAD_SIZE);
        setupArgs = (CrateInitSetupArgs *) payload;
        setupArgs->mbNum = slot;
        setupArgs->settings = mbs[slot];
        
        if ([xl3Link needToSwap]) {
            setupArgs->mbNum = swapLong(setupArgs->mbNum);
            [self byteSwapBundle:&setupArgs->settings];
        }

        @try {
            [[self xl3Link] sendCommand:CRATE_INIT_ID withPayload:payload expectResponse:NO];
        } @catch (NSException* e) {
            NSLog(@"%@ Init crate failed; error: %@ reason: %@\n",[[self xl3Link] crateName], [e name], [e reason]);
            goto err;
        }
    }

    crateInitArgs = (CrateInitArgs *) payload;

    /* XL3 is big endian. So we convert all ints to network byte order
     * using htonl(). */
    /* mbNum > 16 means this is the final packet to perform crate init */
    crateInitArgs->mbNum = htonl(0xff);
    crateInitArgs->slotMask = htonl(slotMask);
    crateInitArgs->ctcDelay = htonl(0);

    @try {
        [[self xl3Link] sendCommand:CRATE_INIT_ID withPayload:payload expectResponse:YES];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"%@: crate init failed. error: %@ reason:%@\n", [[self xl3Link] crateName], [e name], [e reason]);
        goto err;
    }

    if (results) *results = *((CrateInitResults *) payload);

    free(mbs);

    return 0;

err:
    free(mbs);
    return -1;
}

- (void) initCrateDone: (CrateInitResults *)r
{
    /* Checks the hardware configuration sent back from the XL3 after
     * a full crate init. */

    int slot, i;
    FECConfiguration *fec;

    if (r == NULL) {
        /* crate init failed */
        return;
    }

    if (r->errorFlags) {
        free(r);
        return;
    }

    for (slot = 0; slot < 16; slot++) {
        fec = &r->hwareVals[slot];
        fec->mbID = swapShort(fec->mbID);

        for (i = 0; i < 4; i++) {
            fec->dbID[i] = swapShort(fec->dbID[i]);
        }
    }

    // update XL3 alarm levels on safe init
    if ([self isXl3VltThresholdInInit]) [self setVltThreshold];

    free(r);
}

- (void) checkCrateConfig: (ResetCrateResults *)r
{
    int slot, i;
    ORFec32Model *fec;
    ORFecDaughterCardModel *db;
    FECConfiguration fec_config;

    if (r == NULL) {
        NSLogColor([NSColor redColor], @"checkCrateConfig: config results is NULL!\n");
        return;
    }

    @synchronized(self) {
        for (slot = 0; slot < 16; slot++) {
            fec_config = r->hwareVals[slot];
            fec = [[OROrderedObjManager for:[self guardian]] objectInSlot:16-slot];

            if (fec) {
                [fec checkConfig:&fec_config];
            } else {
                if (fec_config.mbID) {
                    NSLogColor([NSColor redColor], @"adding fec to ORCA\n");

                    fec = [ObjectFactory makeObject:@"ORFec32Model"];
                    [fec setBoardID:[NSString stringWithFormat:@"%x", fec_config.mbID]];

                    [[self guardian] addObject:fec];
                    [[self guardian] place:fec intoSlot:16-slot];

                    for (i = 0; i < 4; i++) {
                        db = [ObjectFactory makeObject:@"ORFecDaughterCardModel"];
                        [db setBoardID:[NSString stringWithFormat:@"%x", fec_config.dbID[i]]];

                        [fec addObject:db];
                        [fec place:db intoSlot:i];
                    }
                }
            }
        }
    }
}

- (void) fetchECALSettings
{
    unsigned short slot;
    ORCouchDB *couch;

    if ((couch = [self debugDBRef]) == NULL) {
        NSLog(@"ecalToOrca: couldn't get CouchDB from SNOPModel!");
        return;
    }

    [self setEcal_received:0UL];
    for (slot=0; slot<16; slot++) {
        NSString* requestString = [NSString stringWithFormat:@"_design/penn_daq_views/_view/get_fec_by_generated?descending=true&startkey=[%d,%d,{}]&endkey=[%d,%d,\"\"]&limit=1",[self crateNumber], slot, [self crateNumber], slot];
        NSString* tagString = [NSString stringWithFormat:@"%@.%d.%d", kDebugDbEcalDocGot, [self crateNumber], slot];
        //NSLog(@"%@ slot %hd request: %@ tag: %@\n", [[self xl3Link] crateName], slot, requestString, tagString);
        [couch getDocumentId:requestString tag:tagString];
    }
    NSLog(@"%@ ECAL docs requested from debugDB\n", [[self xl3Link] crateName]);
    [self setEcalToOrcaInProgress:YES];
    [self performSelector:@selector(ecalToOrcaDocumentsReceived) withObject:nil afterDelay:10.0];
}

- (void) ecalToOrcaDocumentsReceived
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(ecalToOrcaDocumentsReceived) object:nil];
    if (![self ecalToOrcaInProgress]) { //killed already
        return;
    }
    
    if ([self ecal_received] != 0xffff) {
        NSMutableString* msg = [[NSMutableString alloc] initWithFormat:
                                @"%@ didn't receive all the ECAL documents.\nMissing slots: ", [[self xl3Link] crateName]];

        unsigned short slot;
        //NSLog(@"ecal_received mask: 0x%08x\n", [self ecal_received]);
        for (slot=0; slot<16; slot++) {
            if (!([self ecal_received] & 0x1UL << slot)) {
                [msg appendFormat:@"%d, ", slot];
            }
        }
        [msg appendFormat:@"\n"];
        NSLog(msg);
        [msg release];
        msg = nil;
    }
    else {
        NSLog(@"%@ received all the ECAL documents requested.\n", [[self xl3Link] crateName]);
        NSLog(@"%@ updated ORCA with ECAL data.\n", [[self xl3Link] crateName]);
    }
    
    [self setEcal_received:0UL];
    [self setEcalToOrcaInProgress:NO];
}

- (void) parseEcalDocument:(NSDictionary*)aResult
{
    NSArray* keyArray = [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"key"];
    NSDictionary* ecalDoc = [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"value"];
    NSString* docId = [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"id"];

    unsigned int crate_num = [[keyArray objectAtIndex:0] intValue];
    unsigned int slotNum = [[keyArray objectAtIndex:1] intValue];

    NSLog(@"key array crate: %d slot: %d time: %@, id: %@\n", crate_num, slotNum, [keyArray objectAtIndex:2], docId);
    
    if ([self crateNumber] != crate_num) {
        NSLog(@"%@ error parsing ECAL document, the crate number in the key array doesn't match: %d\n",
              [[self xl3Link] crateName], crate_num);
        return;
    }

    NSDictionary* hwDic = [ecalDoc objectForKey:@"hw"];
    if (!hwDic) {
        NSLog(@"%@ error parsing ECAL document, the hw dictionary missing for slot: %d\n",
              [[self xl3Link] crateName], slotNum);
        return;
    }

    MB aConfigBundle;
    memset(&aConfigBundle, 0, sizeof(MB));
    
    unsigned short i, j;
    aConfigBundle.mbID = 0;
    for (i=0; i<4; i++) {
        aConfigBundle.dbID[i] = 0;
    }
    
    for (i=0; i<2; i++) {
        for (j=0; j<32; j++) {
            aConfigBundle.vBal[i][j] = [[[[hwDic objectForKey:@"vbal"] objectAtIndex:i] objectAtIndex:j] intValue];
        }
    }
    
    for (i=0; i<32; i++) {
        aConfigBundle.vThr[i] = [[[hwDic objectForKey:@"vthr"] objectAtIndex:i] intValue];
    }
    
    for (i=0; i<8; i++) {
        aConfigBundle.tDisc.rmp[i] = [[[[hwDic objectForKey:@"tdisc"] objectForKey:@"rmp"] objectAtIndex:i] intValue];
        aConfigBundle.tDisc.rmpup[i] = [[[[hwDic objectForKey:@"tdisc"] objectForKey:@"rmpup"] objectAtIndex:i] intValue];
        aConfigBundle.tDisc.vsi[i] = [[[[hwDic objectForKey:@"tdisc"] objectForKey:@"vsi"] objectAtIndex:i] intValue];
        aConfigBundle.tDisc.vli[i] = [[[[hwDic objectForKey:@"tdisc"] objectForKey:@"vli"] objectAtIndex:i] intValue];
    }
    
    aConfigBundle.tCmos.vMax = [[[hwDic objectForKey:@"tcmos"] objectForKey:@"vmax"] intValue];
    aConfigBundle.tCmos.tacRef = [[[hwDic objectForKey:@"tcmos"] objectForKey:@"vtacref"] intValue];
    for (i=0; i<2; i++) {
        aConfigBundle.tCmos.isetm[i] = [[[[hwDic objectForKey:@"tcmos"] objectForKey:@"isetm"] objectAtIndex:i] intValue];
        aConfigBundle.tCmos.iseta[i] = [[[[hwDic objectForKey:@"tcmos"] objectForKey:@"iseta"] objectAtIndex:i] intValue];
    }
    for (i=0; i<32; i++) {
        aConfigBundle.tCmos.tacShift[i] = [[[[hwDic objectForKey:@"tcmos"] objectForKey:@"tac_trim"] objectAtIndex:i] intValue];
    }

    aConfigBundle.vInt = [[hwDic objectForKey:@"vint"] intValue];
    aConfigBundle.hvRef = [[hwDic objectForKey:@"hvref"] intValue];

    for (i=0; i<32; i++) {
        aConfigBundle.tr100.mask[i] = [[[[hwDic objectForKey:@"tr100"] objectForKey:@"mask"] objectAtIndex:i] intValue];
        aConfigBundle.tr100.tDelay[i] = [[[[hwDic objectForKey:@"tr100"] objectForKey:@"delay"] objectAtIndex:i] intValue];
    }

    for (i=0; i<32; i++) {
        aConfigBundle.tr20.mask[i] = [[[[hwDic objectForKey:@"tr20"] objectForKey:@"mask"] objectAtIndex:i] intValue];
        aConfigBundle.tr20.tDelay[i] = [[[[hwDic objectForKey:@"tr20"] objectForKey:@"delay"] objectAtIndex:i] intValue];
        aConfigBundle.tr20.tWidth[i] = [[[[hwDic objectForKey:@"tr20"] objectForKey:@"width"] objectAtIndex:i] intValue];
    }

    for (i=0; i<32; i++) {
        aConfigBundle.sCmos[i] = [[[[hwDic objectForKey:@"tr20"] objectForKey:@"scmos"] objectAtIndex:i] intValue];
    }

	aConfigBundle.disableMask = 0;

    memcpy(&ecal_bundle[slotNum], &aConfigBundle, sizeof(MB));
    [self updateUIFromEcalBundle:hwDic slot:slotNum];
    [self synthesizeFECIntoBundle:&hw_bundle[slotNum] forSlot:slotNum];
    
    [self setEcal_received:(uint32_t)([self ecal_received] | 1UL << slotNum)];
    //NSLog(@"ecal received mask: 0x%08x\n", [self ecal_received]);
    if ([self ecal_received] == 0xffffUL) {
        [self ecalToOrcaDocumentsReceived];
    }    
}

//todo give links to debugDB documents
- (void) updateUIFromEcalBundle:(NSDictionary*)hwDic slot:(unsigned int)aSlot;
{
    ORFec32Model* fec = [[OROrderedObjManager for:[self guardian]] objectInSlot:16-aSlot];
    if (!fec) {
        return;
    }
    
    unsigned short dbNum;
    for (dbNum=0; dbNum<4; dbNum++) {
        if (![fec dcPresent:dbNum]) {
            NSLog(@"%@ FEC %d DB %d NOT updated from ECAL, it's missing\n", [[self xl3Link] crateName], aSlot, dbNum);
        }
    }
    
    for (dbNum=0; dbNum<4; dbNum++) {
        if ([fec dcPresent:dbNum]) {
            unsigned short channel;
            unsigned short itg;

            for (channel=0; channel<8; channel++) {
                [[fec dc:dbNum] setVt_ecal:channel
                                 withValue:[[[hwDic objectForKey:@"vthr"] objectAtIndex:dbNum*8+channel] intValue]];
                [[fec dc:dbNum] setVt_zero:channel
                                 withValue:[[[hwDic objectForKey:@"vthr_zero"] objectAtIndex:dbNum*8+channel] intValue]];

                [[fec dc:dbNum] setTac0trim:channel
                                  withValue:[[[[hwDic objectForKey:@"tcmos"] objectForKey:@"tac_trim"] objectAtIndex:dbNum*8+channel] intValue]];

                [[fec dc:dbNum] setTac1trim:channel
                                  withValue:[[[[hwDic objectForKey:@"tr20"] objectForKey:@"scmos"] objectAtIndex:dbNum*8+channel] intValue]];
                
                for (itg=0; itg<2; itg++) {
                    [[fec dc:dbNum] setVb:itg*8+channel
                                withValue:[[[[hwDic objectForKey:@"vbal"] objectAtIndex:itg] objectAtIndex:dbNum*8+channel] intValue]];
                }
                
                [[fec dc:dbNum] setNs100width:channel
                                    withValue:[[[[hwDic objectForKey:@"tr100"] objectForKey:@"delay"] objectAtIndex:dbNum*8+channel] intValue]];

                [[fec dc:dbNum] setNs20width:channel
                                    withValue:[[[[hwDic objectForKey:@"tr20"] objectForKey:@"width"] objectAtIndex:dbNum*8+channel] intValue]];

                [[fec dc:dbNum] setNs20delay:channel
                                   withValue:[[[[hwDic objectForKey:@"tr20"] objectForKey:@"delay"] objectAtIndex:dbNum*8+channel] intValue]];
            }
            
            for (itg=0; itg<2; itg++) {
                [[fec dc:dbNum] setRp2:itg
                             withValue:[[[[hwDic objectForKey:@"tdisc"] objectForKey:@"rmp"] objectAtIndex:dbNum*2+itg] intValue]];

                [[fec dc:dbNum] setRp1:itg
                             withValue:[[[[hwDic objectForKey:@"tdisc"] objectForKey:@"rmpup"] objectAtIndex:dbNum*2+itg] intValue]];
                
                [[fec dc:dbNum] setVli:itg
                             withValue:[[[[hwDic objectForKey:@"tdisc"] objectForKey:@"vli"] objectAtIndex:dbNum*2+itg] intValue]];

                [[fec dc:dbNum] setVsi:itg
                             withValue:[[[[hwDic objectForKey:@"tdisc"] objectForKey:@"vsi"] objectAtIndex:dbNum*2+itg] intValue]];
                
            }            
        }
    }
    
    [fec setVRes:[[hwDic objectForKey:@"vint"] intValue]];
    [fec setHVRef:[[hwDic objectForKey:@"hvref"] intValue]];

    //unsigned char	cmos[6];	//board related	0-ISETA1 1-ISETA0 2-ISETM1 3-ISETM0 4-TACREF 5-VMAX
    [fec setCmos:0 withValue:[[[[hwDic objectForKey:@"tcmos"] objectForKey:@"iseta"] objectAtIndex:1] intValue]];
    [fec setCmos:1 withValue:[[[[hwDic objectForKey:@"tcmos"] objectForKey:@"iseta"] objectAtIndex:0] intValue]];
    [fec setCmos:2 withValue:[[[[hwDic objectForKey:@"tcmos"] objectForKey:@"isetm"] objectAtIndex:1] intValue]];
    [fec setCmos:3 withValue:[[[[hwDic objectForKey:@"tcmos"] objectForKey:@"isetm"] objectAtIndex:0] intValue]];
    [fec setCmos:4 withValue:[[[hwDic objectForKey:@"tcmos"] objectForKey:@"vtacref"] intValue]];
    [fec setCmos:5 withValue:[[[hwDic objectForKey:@"tcmos"] objectForKey:@"vmax"] intValue]];
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
	@synchronized(self){
		if([aResult isKindOfClass:[NSDictionary class]]){
			NSString* message = [aResult objectForKey:@"Message"];
			if(message){
				if([aTag rangeOfString:kDebugDbEcalDocGot].location != NSNotFound){
					NSLog(@"CouchDB Message getting an ECAL doc:");
				}
				[aResult prettyPrint:@"CouchDB Message:"];
			}
			else {
				if([aTag rangeOfString:kDebugDbEcalDocGot].location != NSNotFound){
                    //int key = [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"key"];
                    if ([[aResult objectForKey:@"rows"] count] && [[[aResult objectForKey:@"rows"] objectAtIndex:0] objectForKey:@"key"]){
                        //NSLog(@"got ECAL doc: %@\n", aTag);
                        [self parseEcalDocument:aResult];
                    }
                    else {
                        //no ecal doc found
                    }
				}
				else if([aTag isEqualToString:@"Message"]){
					[aResult prettyPrint:@"CouchDB Message:"];
				}
				else {
					[aResult prettyPrint:@"CouchDB"];
				}
			}
		}
		else if([aResult isKindOfClass:[NSArray class]]){
            /*
             if([aTag isEqualToString:kListDB]){
             [aResult prettyPrint:@"CouchDB List:"];
             else [aResult prettyPrint:@"CouchDB"];
             */
            [aResult prettyPrint:@"CouchDB"];
		}
		else {
			NSLog(@"DebugDB %@ %@\n",[[self xl3Link] crateName], aResult);
		}
	}
}

- (BOOL) isRelayClosedForSlot:(unsigned int)slot pc:(unsigned int)aPC
{
    BOOL isClosed = YES;
    
    if (([self relayMask] & 0x1ULL << (slot*4 + (3-aPC))) == 0) {
        isClosed = NO;
    }

    return isClosed;
}

#pragma mark •••Basic Ops
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

- (void) reportStatus
{
	NSLog(@"not yet implemented\n");
	//that what we did for MTC
	//NSLog(@"Mtc control reg: 0x%0x\n", [self getMTC_CSR]);
	//parse csr to human friendly output, e.g. 0x3 firing pedestals...
}


#pragma mark •••Composite HW Functions

- (void) deselectComposite
{
	[self setXl3OpsRunning:YES forKey:@"compositeDeselect"];
	NSLog(@"%@ Deselect FECs...\n",[[self xl3Link] crateName]);
	@try {
		[[self xl3Link] sendCommand:DESELECT_FECS_ID expectResponse:YES];
		NSLog(@"ok\n");
	}
	@catch (NSException * e) {
		NSLog(@"Deselect FECs failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
	[self setXl3OpsRunning:NO forKey:@"compositeDeselect"];
}

- (void) writeXl3Mode: (uint32_t) mode
{
    /* Set the XL3 mode and set the data available mask to whichever cards
     * ORCA thinks are present. */

    [self writeXl3Mode: mode withSlotMask: [self getSlotsPresent]];
}

- (void) writeXl3Mode: (uint32_t) mode withSlotMask: (uint32_t) slotMask
{
    /* Change the mode of the XL3. In init mode, the XL3 does not read out
     * the front end cards, while in normal mode it reads out whichever
     * front end cards are specified in the dataAvailMask. Here we set the
     * dataAvailMask to whichever cards ORCA thinks are present. */

    char payload[XL3_PAYLOAD_SIZE];
    ChangeModeArgs* args = (ChangeModeArgs *) payload;

    args->mode = htonl(mode);
    args->dataAvailMask = htonl(slotMask);

    [self setXl3ModeRunning:YES];
    @try {
        [[self xl3Link] sendCommand:CHANGE_MODE_ID withPayload:payload
                             expectResponse:YES];
        NSLog(@"xl3 %02d set to %s mode.\n", [self crateNumber],
                (xl3Mode == INIT_MODE) ? "INIT" : "NORMAL");
    } @catch (NSException* e) {
        NSLogColor([NSColor redColor],
                    @"Set XL3 mode failed; error: %@ reason: %@\n",
                    [e name], [e reason]);
    }
    [self setXl3ModeRunning:NO];
}

- (void) compositeXl3RW
{
	uint32_t aValue = (uint32_t)[self xl3RWDataValue];
	NSLog(@"%@ XL3_rw to address: 0x%08x with data: 0x%08x\n",[[self xl3Link] crateName], [self xl3RWAddressValue], aValue);
	[self setXl3OpsRunning:YES forKey:@"compositeXl3RW"];
	
	@try {
		[xl3Link sendCommand:0UL toAddress:(uint32_t)[self xl3RWAddressValue] withData:&aValue];
		NSLog(@"XL3_rw returned data: 0x%08x\n", aValue);
	}
	@catch (NSException* e) {
		NSLog(@"XL3_rw failed; error: %@ reason: %@\n", [e name], [e reason]);
	}

	[self setXl3OpsRunning:NO forKey:@"compositeXl3RW"];
}

- (void) compositeQuit
{
	char payload[XL3_PAYLOAD_SIZE];
	uint32_t* data = (uint32_t*) payload;
	
	if ([xl3Link needToSwap]) {
		data[0] = 0x20657942UL;
		data[1] = 0x00334C58UL;
	}
	else {
		data[0] = 0x42796520UL;
		data[1] = 0x584C3300UL;
	}
	
	[self setXl3OpsRunning:YES forKey:@"compositeQuit"];
	NSLog(@"%@ Send XL3 Quit ...\n", [[self xl3Link] crateName]);
	@try {
		[[self xl3Link] sendCommand:DAQ_QUIT_ID withPayload:payload expectResponse:NO];
		NSLog(@"ok\n");
	}
	@catch (NSException* e) {
		NSLog(@"Send XL3 Quit failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
	[self setXl3OpsRunning:NO forKey:@"compositeQuit"];
}

- (int) setPedestals
{
    /* Set the pedestal mask. Returns 0 on success, -1 on error. */
    int i;
    char payload[XL3_PAYLOAD_SIZE];
    MultiSetCratePedsArgs *args;
    MultiSetCratePedsResults *results;

    memset(&payload, 0, XL3_PAYLOAD_SIZE);

    args = (MultiSetCratePedsArgs *) payload;

    NSArray* fecs = [[self guardian]
                     collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];

    args->slotMask = 0;

    for (id aFec in fecs) {
        args->slotMask |= 1 << [aFec stationNumber];
        args->channelMasks[[aFec stationNumber]] = (uint32_t)[aFec pedEnabledMask];
    }

    args->slotMask = htonl(args->slotMask);

    for (i = 0; i < 16; i++) {
        args->channelMasks[i] = htonl(args->channelMasks[i]);
    }

    @try {
        [[self xl3Link] sendCommand:MULTI_SET_CRATE_PEDS_ID withPayload:payload
                        expectResponse:YES];
    } @catch (NSException *e) {
        return -1;
    }

    results = (MultiSetCratePedsResults *) payload;

    if (ntohl(results->errorMask)) {
        return -1;
    }

    return 0;
}

- (int) multiSetPedestalMask: (uint32_t) slotMask patterns: (uint32_t[16]) patterns
{
    /* Similar to setPedestalMask except any slots not in the slot mask will
     * not have their pedestal mask changed. */
    int i;
    char payload[XL3_PAYLOAD_SIZE];
    MultiSetCratePedsArgs *args;
    MultiSetCratePedsResults *results;

    memset(&payload, 0, XL3_PAYLOAD_SIZE);

    args = (MultiSetCratePedsArgs *) payload;

    args->slotMask = htonl(slotMask);

    for (i = 0; i < 16; i++) {
        args->channelMasks[i] = htonl(patterns[i]);
    }

    @try {
        [[self xl3Link] sendCommand:MULTI_SET_CRATE_PEDS_ID withPayload:payload
                        expectResponse:YES];
    } @catch (NSException *e) {
        return -1;
    }

    results = (MultiSetCratePedsResults *) payload;

    if (ntohl(results->errorMask)) {
        return -1;
    }

    return 0;
}

- (int) setPedestalMask: (uint32_t) slotMask pattern: (uint32_t) pattern
{
    /* Set the pedestal mask for a given slot mask. Any slots not in the mask
     * will have pedestals disabled. Returns 0 on success, -1 on error. */
    char payload[XL3_PAYLOAD_SIZE];
    SetCratePedestalsArgs *args;
    SetCratePedestalsResults *results;

    memset(&payload, 0, XL3_PAYLOAD_SIZE);

    args = (SetCratePedestalsArgs *) payload;

    args->slotMask = htonl(slotMask);
    args->pattern = htonl(pattern);

    @try {
        [[self xl3Link] sendCommand:SET_CRATE_PEDESTALS_ID withPayload:payload
                        expectResponse:YES];
    } @catch (NSException *e) {
        return -1;
    }

    results = (SetCratePedestalsResults *) payload;

    if (ntohl(results->errorMask)) {
        return -1;
    }

    return 0;
}

- (void) compositeSetPedestal
{
	char payload[XL3_PAYLOAD_SIZE];
	uint32_t* data = (uint32_t*) payload;

	if ([xl3Link needToSwap]) {
		data[0] = swapLong([self slotMask]);
		data[1] = swapLong([self xl3PedestalMask]);
	}
	else {
		data[0] = [self slotMask];
		data[1] = [self xl3PedestalMask];
	}
	
	[self setXl3OpsRunning:YES forKey:@"compositeSetPedestal"];
	NSLog(@"%@ Set Pedestal ...\n", [[self xl3Link] crateName]);
	@try {
		[[self xl3Link] sendCommand:SET_CRATE_PEDESTALS_ID withPayload:payload expectResponse:YES];
		if ([xl3Link needToSwap]) *data = swapLong(*data);
		if (*data == 0) NSLog(@"ok\n");
		else NSLog(@"failed with XL3 error: 0x%08x\n", *data);
	}
	@catch (NSException* e) {
		NSLog(@"%@ Set Pedestal failed; error: %@ reason: %@\n", [[self xl3Link] crateName],[e name], [e reason]);
	}
	[self setXl3OpsRunning:NO forKey:@"compositeSetPedestal"];
}

- (void) setPedestalInParallel
{
    if (![[self xl3Link] isConnected]) {
        return;
    }

    [NSThread detachNewThreadSelector:@selector(_setPedestalInParallelWorker) toTarget:self withObject:nil];
}

//used by OrcaScript for ECA
- (void) zeroPedestalMasks
{
    if (![[self xl3Link] isConnected]) {
        return;
    }

    NSArray* fecs = [[self guardian] collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];
    unsigned int slotMaskPresent = 0;
    for (id aFec in fecs) {
        slotMaskPresent |= 1 << [aFec stationNumber];
    }
    
    uint32_t slotMaskSet = [self slotMask];
    [self setSlotMask:slotMaskPresent];
    [self setXl3PedestalMask:0];
    [self compositeSetPedestal];
    [self setSlotMask:slotMaskSet];
}

- (unsigned short) getBoardIDForSlot:(unsigned short)aSlot chip:(unsigned short)aChip
{
	char payload[XL3_PAYLOAD_SIZE];
	uint32_t* data = (uint32_t*) payload;
	
	data[0] = aSlot;
	data[1] = aChip;
	data[2] = 15;
	
	if ([xl3Link needToSwap]) {
		data[0] = swapLong(data[0]);
		data[1] = swapLong(data[1]);
		data[2] = swapLong(data[2]);
	}

	@try {
		[[self xl3Link] sendCommand:BOARD_ID_READ_ID withPayload:payload expectResponse:YES];
		if ([xl3Link needToSwap]) *data = swapLong(*data);
	}
	@catch (NSException* e) {
		NSLog(@"Get Board ID failed; error: %@ reason: %@\n", [e name], [e reason]);
		*data = 0;
	}

	return (unsigned short) *data;
}

- (void) getBoardIDs
{
	unsigned short i, j, val;
	uint32_t msk;
	NSString* bID[6];
	
	[self setXl3OpsRunning:YES forKey:@"compositeBoardID"];
	NSLog(@"%@ Get Board IDs ...\n", [[self xl3Link] crateName]);

	msk = [self slotMask];
	for (i=0; i < 16; i++) {
		if (1 << i & msk) {
			//HV chip not yet available
			//for (j = 0; j < 6; j++) {
			for (j = 0; j < 5; j++) {
				val = [self getBoardIDForSlot:i chip:(j+1)];
				if (val == 0x0) bID[j] = @"----";
				else bID[j] = [NSString stringWithFormat:@"0x%04x", val];
			}
			
			//NSLog(@"slot: %02d: MB: %@ DB1: %@ DB2:%@ DB3: %@ DB4: %@ HV: %@\n",
			//      i+1, bID[0], bID[1], bID[2], bID[3], bID[4], bID[5]);
			NSLog(@"slot: %02d: MB: %@ DB1: %@ DB2:%@ DB3: %@ DB4: %@\n",
			      i, bID[0], bID[1], bID[2], bID[3], bID[4]);
		}
	}

	[self setXl3OpsRunning:NO forKey:@"compositeBoardID"];	
}

- (void) compositeResetCrate
{
	//XL2_CONTROL_CRATE_RESET	0x80
	//XL2_CONTROL_DONE_PROG		0x100

	[self setXl3OpsRunning:YES forKey:@"compositResetCrate"];
	NSLog(@"Reset crate keep Xilinx code.\n");

	@try {
		[self deselectCards];
		//read XL3 select register
		uint32_t aValue = [self readXL3Register:kXl3CsReg];
		if ((aValue & 0x100UL) == 0) { 
			NSLog(@"Xilinx doesn't seem to be loaded, keeping it anyway!\n");
		}
		
		[[self xl3Link] newMultiCmd];
		[[self xl3Link] addMultiCmdToAddress:(XL3_SEL | [self getRegisterAddress:kXl3CsReg] | WRITE_REG) withValue:0x100UL]; //prog done
		[[self xl3Link] addMultiCmdToAddress:(XL3_SEL | [self getRegisterAddress:kXl3CsReg] | WRITE_REG) withValue:0x180UL]; //prog done | reset
		[[self xl3Link] addMultiCmdToAddress:(XL3_SEL | [self getRegisterAddress:kXl3CsReg] | WRITE_REG) withValue:0x100UL]; //prog done
		[[self xl3Link] executeMultiCmd];
		[self deselectCards];
		
		if ([[self xl3Link] multiCmdFailed]) NSLog(@"reset failed: XL3 bus error.\n");
	}
	@catch (NSException* e) {
		NSLog(@"reset failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
	
	[self setXl3OpsRunning:NO forKey:@"compositeResetCrate"];
}

- (void) compositeResetCrateAndXilinX
{
	[self setXl3OpsRunning:YES forKey:@"compositResetCrateAndXilinX"];
	NSLog(@"Reset crate and XilinX code.\n");
	
	@try {
		[self deselectCards];
		[[self xl3Link] newMultiCmd];
		[[self xl3Link] addMultiCmdToAddress:(XL3_SEL | [self getRegisterAddress:kXl3CsReg] | WRITE_REG) withValue:0x00UL];
		[[self xl3Link] addMultiCmdToAddress:(XL3_SEL | [self getRegisterAddress:kXl3CsReg] | WRITE_REG) withValue:0x80UL]; //reset
		[[self xl3Link] addMultiCmdToAddress:(XL3_SEL | [self getRegisterAddress:kXl3CsReg] | WRITE_REG) withValue:0x00UL]; //done
		[[self xl3Link] executeMultiCmd];
		[self deselectCards];
		
		if ([[self xl3Link] multiCmdFailed]) NSLog(@"reset failed: XL3 bus error.\n");
	}
	@catch (NSException* e) {
		NSLog(@"reset failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
	
	[self setXl3OpsRunning:NO forKey:@"compositeResetCrateAndXilinX"];
}

- (void) compositeResetFIFOAndSequencer
{
	[self setXl3OpsRunning:YES forKey:@"compositResetFIFOAndSeuencer"];
	NSLog(@"Reset FIFO and Sequencer to be implemented.\n");
	//slot mask?
	uint32_t xl3Address = (uint32_t)(XL3_SEL | [self getRegisterAddress:kXl3SelectReg] | WRITE_REG);
	uint32_t aValue = 0xffffffffUL;
    
	@try {
		[xl3Link sendCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"%@ SW reset failed.\n",[[self xl3Link] crateName]);
        @throw e;
	}
    
	[self setXl3OpsRunning:NO forKey:@"compositeResetFIFOAndSequencer"];
}

- (void) compositeResetXL3StateMachine
{
	[self setXl3OpsRunning:YES forKey:@"compositResetXL3StateMachine"];
	NSLog(@"Reset XL3 State Machine.\n");

	@try {
		[[self xl3Link] sendCommand:STATE_MACHINE_RESET_ID expectResponse:YES];
        //we don't care about the response, but clean it from the array
	}
	@catch (NSException* e) {
		NSLog(@"Send XL3 command failed; error: %@ reason: %@\n", [e name], [e reason]);
	}
	[self setXl3OpsRunning:NO forKey:@"compositeResetXL3StateMachine"];
}

- (void) reset
{
	@try {
		[self deselectCards];
		//uint32_t readValue = 0; //[self readFromXL2Register: XL2_CONTROL_STATUS_REG];
/*
		if (readValue & XL2_CONTROL_DONE_PROG) {
			NSLog(@"XilinX code found in the crate, keeping it.\n");
			[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: XL2_CONTROL_DONE_PROG]; 
			[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: (XL2_CONTROL_CRATE_RESET | XL2_CONTROL_DONE_PROG)];
			[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: XL2_CONTROL_DONE_PROG];
		}
		else {
			//do not set the dp bit if the xilinx hasn't been loaded
			[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: 0UL]; 
			[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: XL2_CONTROL_CRATE_RESET];
			[self writeToXL2Register:XL2_CONTROL_STATUS_REG value: 0UL];
		}
*/
		[self deselectCards];
		
	}
	@catch(NSException* localException) {
		NSLog(@"Failure during reset of XL2 Crate %d Slot %d.\n", [self crateNumber], [self stationNumber]);
		[NSException raise:@"XL2 Reset Failed" format:@"%@",localException];
	}		
	
}

- (void) compositeEnableChargeInjection
{
	[self setXl3OpsRunning:YES forKey:@"compositeEnableChargeInjection"];

    NSLog(@"%@, charge injection setup...\n", [[self xl3Link] crateName]);
    unsigned int i;
    uint32_t msk = [self slotMask];
    for (i=0; i < 16; i++) {
		if (1 << i & msk) {
            //NSLog(@"%d ", i);
            [self enableChargeInjectionForSlot:i channelMask:[self xl3ChargeInjMask]];
        }
    }    
	NSLog(@"%@ charge injection enabled.\n", [[self xl3Link] crateName]);
    
	[self setXl3OpsRunning:NO forKey:@"compositeEnableChargeInjection"];
}


- (void) enableChargeInjectionForSlot:(unsigned short) aSlot channelMask:(uint32_t) aChannelMask
{
    //borrowed from penn_daq EnableChargeInjection
    
    uint32_t aValue = 0;
    uint32_t xl3Value = 0;
    uint32_t xl3Address = FEC_SEL * aSlot | 0x26 | WRITE_REG; //FEC HV CSR
    const int HV_BIT_COUNT = 40;
    
    @try {
        int bit_iter = 0;
        for (bit_iter = HV_BIT_COUNT;bit_iter>0;bit_iter--){
            if (bit_iter > 32){
                aValue = 0x0;
            }else{
                // set bit iff it is set in amask
                aValue = ((0x1 << (bit_iter -1)) & aChannelMask) ? HV_CSR_DATIN : 0x0;
            }
            xl3Value = aValue;
            [xl3Link sendCommand:0UL toAddress:xl3Address withData:&xl3Value];
            //[[self xl3Link] addMultiCmdToAddress:xl3Address withValue:xl3Value];

            xl3Value = aValue | HV_CSR_CLK;
            [xl3Link sendCommand:0UL toAddress:xl3Address withData:&xl3Value];
            //[[self xl3Link] addMultiCmdToAddress:xl3Address withValue:xl3Value];
        } // end loop over bits

        aValue = 0;
		[xl3Link sendCommand:0UL toAddress:xl3Address withData:&aValue];
        //[[self xl3Link] addMultiCmdToAddress:xl3Address withValue:aValue];
        aValue = HV_CSR_LOAD;
		[xl3Link sendCommand:0UL toAddress:xl3Address withData:&aValue];
        //[[self xl3Link] addMultiCmdToAddress:xl3Address withValue:xl3Value];

        /*
        [[self xl3Link] executeMultiCmd];
    
        if ([[self xl3Link] multiCmdFailed]) {
            NSLog(@"Enable charge injection failed: XL3 bus error.\n");
            return;
        }
         */
        
        [self loadSingleDacForSlot:aSlot dacNum:136 dacVal:[self xl3ChargeInjCharge]];
        //[self loadSingleDacForSlot:aSlot dacNum:136 dacVal:0xff];
    }
	@catch (NSException* e) {
		NSLog(@"%@ enable charge injection failed; error: %@ reason: %@\n",
              [[self xl3Link] crateName], [e name], [e reason]);
	}

    
//    NSLog(@"%@ enabled charge injection for slot %d with channel mask 0x%08x\n",
//          [[self xl3Link] crateName], aSlot, aChannelMask);
        
/*
    
	char payload[XL3_PAYLOAD_SIZE];
	memset(payload, 0, XL3_PAYLOAD_SIZE);
	uint32_t* data = (uint32_t*) payload;
    
    uint32_t slot = aSlot;
    uint32_t mask = aChannelMask;
    
    if ([xl3Link needToSwap]) {
        slot = swapLong(slot);
        mask = swapLong(mask);
    }

    data[0] = slot;
    data[1] = mask;

    @try {
        [[self xl3Link] sendCommand:SETUP_CHARGE_INJ_ID withPayload:payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"error sending ChargeInjection command.\n");
    }

    if (*(unsigned int*)payload != 0) {
        NSLog(@"XL3 error in enableChargeInjectionForSlot.\n");
    }

    //NSLog(@"%@: enabled charge injection for slot: %d, for channels: 0x%08x\n", [[self xl3Link] crateName], aSlot, aChannelMask);
*/
/*
	@try {
        int index;
		//[[self xl3Link] newMultiCmd];
		for (index = 0; index < 16; index++){
			//[[self xl3Link] addMultiCmdToAddress:(FEC_SEL*aSlot | kFecHVCcsr | WRITE_REG) withValue:0x0UL];
			//[[self xl3Link] addMultiCmdToAddress:(FEC_SEL*aSlot | kFecHVCcsr | WRITE_REG) withValue:PMTI_CLOCK_HIGH];
		}
		//[[self xl3Link] executeMultiCmd];
		
		//if ([[self xl3Link] multiCmdFailed]) {
		//	NSLog(@"Enable charge injection failed: XL3 bus error.\n");
		//	return;
		//}
	}
	@catch (NSException* e) {
		NSLog(@"Enable charge injection failed; error: %@ reason: %@\n", [e name], [e reason]);
	}		
*/
}

#pragma mark •••HV
- (void) readCMOSCountWithArgs:(CheckTotalCountArgs*)aArgs counts:(CheckTotalCountResults*)aCounts;
{
	char payload[XL3_PAYLOAD_SIZE];
	memset(payload, 0, XL3_PAYLOAD_SIZE);
    
	CheckTotalCountArgs* data = (CheckTotalCountArgs*) payload;
    memcpy(data, aArgs, sizeof(CheckTotalCountArgs));
    
    //max 8 slots may be masked in
    unsigned int v = data->slotMask;
    unsigned int c;
    for (c = 0; v; c++) v &= v - 1;
    if (c > 8) {
        NSLog(@"%@ error in readCMOSCountWithArgs: more than 8 slots were masked in, ask less.\n", [[self xl3Link] crateName]);
        @throw [NSException exceptionWithName:@"readCMOSCount error" reason:@"More than 8 slots were masked in slotMask" userInfo:nil];
    }
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(CheckTotalCountArgs)/4);
    }
    
    @try {
        [[self xl3Link] sendCommand:CHECK_TOTAL_COUNT_ID withPayload:payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending CHECK_TOTAL_COUNT_ID command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(CheckTotalCountResults)/4);
    }
    
    memcpy(aCounts, data, sizeof(CheckTotalCountResults));
}

- (void) readCMOSCountForSlot:(unsigned short)aSlot withChannelMask:(uint32_t)aChannelMask
{
    CheckTotalCountArgs args;
    CheckTotalCountResults results;
    
    args.slotMask |= 0x1 << aSlot;
    args.channelMasks[aSlot] = (uint32_t)aChannelMask;
    
    @try {
        [self readCMOSCountWithArgs:&args counts:&results];
    }
    @catch (NSException *exception) {
        ;
    }
    
    if (results.errorFlags != 0) {
        NSLog(@"%@ error in readCMOSCountForSlot, errorFlags: 0x%08x.\n",[[self xl3Link] crateName], results.errorFlags);
    }
    else{
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ CMOS counts for slot: %d\n", [[self xl3Link] crateName], aSlot];
        unsigned int i;
        for (i=0; i<32; i++) {
            if (aChannelMask & 1 << i) {
                [msg appendFormat:@"%d: %u\n", i, results.count[i]];
            }
        }
        NSLog(msg);
    }
}

- (void) readCMOSCount
{
    //all slots, all channels, two shots
    CheckTotalCountArgs args_lo;
    CheckTotalCountArgs args_hi;
    CheckTotalCountResults results_lo;
    CheckTotalCountResults results_hi;
    
    memset(&args_lo, 0, sizeof(CheckTotalCountArgs));
    memset(&args_hi, 0, sizeof(CheckTotalCountArgs));
    memset(&results_lo, 0, sizeof(CheckTotalCountResults));
    memset(&results_hi, 0, sizeof(CheckTotalCountResults));
    
    unsigned char i;
    NSLog(@"%@ error in readCMOSCount, errorFlags_lo: 0x%08x, errorFlags_hi: 0x%08x\n",
          [[self xl3Link] crateName], results_lo.errorFlags, results_hi.errorFlags);
    
    args_lo.slotMask = 0xff;
    for (i = 0; i < 8; i++) args_lo.channelMasks[i] = 0xffffffff;
    
    args_hi.slotMask = 0xff00;
    for (i = 8; i < 16; i++) args_hi.channelMasks[i] = 0xffffffff;
    
    @try {
        [self readCMOSCountWithArgs:&args_lo counts:&results_lo];
        [self readCMOSCountWithArgs:&args_hi counts:&results_hi];
    }
    @catch (NSException *exception) {
        ;
    }
    
    if (results_lo.errorFlags != 0 || results_hi.errorFlags != 0) {
        NSLog(@"%@ error in readCMOSCount, errorFlags_lo: 0x%08x, errorFlags_hi: 0x%08x\n",
              [[self xl3Link] crateName], results_lo.errorFlags, results_hi.errorFlags);
    }
    else{
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ CMOS counts:\n", [[self xl3Link] crateName]];
        unsigned char j;
        for (i=0; i<32; i++) {
            [msg appendFormat:@"slot %d, ch%2d-%2d:", i/4, i%4 * 8, (i%4 + 1) * 8 - 1];
            for (j=0; j<8; j++) {
                [msg appendFormat:@"%u ", results_lo.count[i*8 + j]];
            }
            [msg appendFormat:@"\n"];
        }
        for (i=0; i<32; i++) {
            [msg appendFormat:@"slot %d, ch%2d-%2d:", i/4 + 8, i%4 * 8, (i%4 + 1) * 8 - 1];
            for (j=0; j<8; j++) {
                [msg appendFormat:@"%u ", results_hi.count[i*8 + j]];
            }
            [msg appendFormat:@"\n"];
        }
        NSLog(msg);
    }    
}

- (void) readCMOSRateWithArgs:(CrateNoiseRateArgs*)aArgs rates:(CrateNoiseRateResults*)aRates;
{
	char payload[XL3_PAYLOAD_SIZE];
	memset(payload, 0, XL3_PAYLOAD_SIZE);
    
	CrateNoiseRateArgs* data = (CrateNoiseRateArgs*) payload;
    memcpy(data, aArgs, sizeof(CrateNoiseRateArgs));

    //max 8 slots may be masked in
    unsigned int v = data->slotMask;
    unsigned int c;
    for (c = 0; v; c++) v &= v - 1;
    if (c > 8) {
        NSLog(@"%@ error in readCMOSRateWithArgs: more than 8 slots were masked in, ask less.\n", [[self xl3Link] crateName]);
        @throw [NSException exceptionWithName:@"readCMOSRate error" reason:@"More than 8 slots were masked in slotMask" userInfo:nil];
    }
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(CrateNoiseRateArgs)/4);
    }
    
    @try {
        [[self xl3Link] sendCommand:CRATE_NOISE_RATE_ID withPayload:payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending CRATE_NOISE_RATE_ID command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(CrateNoiseRateResults)/4);
    }
    
    memcpy(aRates, data, sizeof(CrateNoiseRateResults));
}

- (void) readCMOSRateForSlot:(unsigned short)aSlot withChannelMask:(uint32_t)aChannelMask withDelay:(uint32_t)aDelay
{
    CrateNoiseRateArgs args;
    CrateNoiseRateResults results;
    
    args.slotMask |= 0x1 << aSlot;
    args.channelMask[aSlot] = (uint32_t)aChannelMask;
    args.period = (uint32_t)aDelay;
    
    @try {
        [self readCMOSRateWithArgs:&args rates:&results];
    }
    @catch (NSException *exception) {
        ;
    }
    
    if (results.errorFlags != 0) {
        NSLog(@"%@ error in readCMOSCRateForSlot, errorFlags: 0x%08x.\n",[[self xl3Link] crateName], results.errorFlags);
    }
    else{
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ CMOS rates for slot: %d\n", [[self xl3Link] crateName], aSlot];
        unsigned int i;
        for (i=0; i<32; i++) {
            if (aChannelMask & 1 << i) {
                [msg appendFormat:@"%d: %f\n", i, results.rates[i]];
            }
        }
        NSLog(msg);
    }
}

- (void) readCMOSRate
{
    CheckTotalCountArgs args_lo;
    CheckTotalCountArgs args_hi;
    CheckTotalCountResults results_lo;
    CheckTotalCountResults results_hi;
    unsigned char i;

	unsigned int msk = 0UL;
    for (id anObj in [[self guardian] orcaObjects]) { 
        if ([anObj class] == NSClassFromString(@"ORFec32Model")) {
            msk |= 1 << [anObj stationNumber];
        }
	}
    unsigned int msk_full = msk;
    
    if (isPollingXl3 || isPollingForced) {
        msk &= pollCMOSRatesMask;
    }
    
    unsigned int v = msk;
    unsigned int num_slots;
    for (num_slots = 0; v; num_slots++) v &= v - 1;
    
    if (num_slots > 8) {
        args_lo.slotMask = msk & 0xff;
        args_hi.slotMask = msk & 0xff00;
    }
    else {
        args_lo.slotMask = msk;
    }
    
    for (i = 0; i < 16; i++) {
        args_lo.channelMasks[i] = 0xffffffff;
        args_hi.channelMasks[i] = 0xffffffff;
    }

    @try {
        [self readCMOSCountWithArgs:&args_lo counts:&results_lo];
        if (num_slots > 8) [self readCMOSCountWithArgs:&args_hi counts:&results_hi];
    }
    @catch (NSException *exception) {
        if (isPollingXl3) {
            NSLog(@"%@ Polling loop stopped because reading CMOS rates failed\n", [[self xl3Link] crateName]);
            [self setIsPollingXl3:NO];
        }
        return;
    }
    
    if (results_lo.errorFlags != 0 || (num_slots > 8 &&  results_hi.errorFlags != 0)) {
        NSLog(@"%@ error in readCMOSCountWithArgs, errorFlags_lo: 0x%08x, errorFlags_hi: 0x%08x\n",
              [[self xl3Link] crateName], results_lo.errorFlags, results_hi.errorFlags);
        return;
    }
    else {
        unsigned char slot_idx = 0;
        uint32_t counts[32];
        
        CrateNoiseRateResults rates_lo;
        CrateNoiseRateResults rates_hi;
        
        if (num_slots > 8) {
            slot_idx = 0;
            unsigned char j = 0;
            for (i=0; i<8; i++) {
                if ((msk >> i) & 0x1) {
                    //NSLog(@"slot %d:\n", i);
                    for (j=0; j<32; j++) {
                        counts[j] = results_lo.count[slot_idx*32 + j];
                        //NSLog(@"channel: %d cnt: %d\n", j, counts[j]);
                    }
                    ORFec32Model* fec=nil;
                    for (id anObj in [[self guardian] orcaObjects]) { 
                        if ([anObj class] == NSClassFromString(@"ORFec32Model") && [anObj stationNumber] == i) {
                            fec = anObj;
                            break;
                        }
                    }
                    [fec processCMOSCounts:counts calcRates:[self calcCMOSRatesFromCounts] withChannelMask:args_lo.channelMasks[i]];
                    for (j=0; j<32; j++) {
                        rates_lo.rates[slot_idx*32 + j] = [fec cmosRate:j];
                    }                    
                    slot_idx++;
                }
            }
            slot_idx=0;
            for (i=0; i<8; i++) {
                if ((msk >> (i + 8)) & 0x1) {
                    //NSLog(@"slot %d:\n", i+8);
                    for (j=0; j<32; j++) {
                        counts[j] = results_hi.count[slot_idx*32 + j];
                        //NSLog(@"channel: %d cnt: %d\n", j, counts[j]);
                    }
                    ORFec32Model* fec = nil;
                    for (id anObj in [[self guardian] orcaObjects]) { 
                        if ([anObj class] == NSClassFromString(@"ORFec32Model") && [anObj stationNumber] == i + 8) {
                            fec = anObj;
                            break;
                        }
                    }
                    [fec processCMOSCounts:counts calcRates:[self calcCMOSRatesFromCounts] withChannelMask:args_hi.channelMasks[i]];
                    for (j=0; j<32; j++) {
                        rates_hi.rates[slot_idx*32 + j] = [fec cmosRate:j];
                    }                    
                    slot_idx++;
                }
            }
        }
        else {
            slot_idx = 0;
            unsigned char j = 0;
            for (i=0; i<16; i++) {
                if ((msk >> i) & 0x1) {
                    for (j=0; j<32; j++) {
                        counts[j] = results_lo.count[slot_idx*32 + j];
                    }
                    ORFec32Model* fec=nil;
                    for (id anObj in [[self guardian] orcaObjects]) { 
                        if ([anObj class] == NSClassFromString(@"ORFec32Model") && [anObj stationNumber] == i) {
                            fec = anObj;
                            break;
                        }
                    }
                    [fec processCMOSCounts:counts calcRates:[self calcCMOSRatesFromCounts] withChannelMask:args_lo.channelMasks[i]];
                    for (j=0; j<32; j++) {
                        rates_lo.rates[slot_idx*32 + j] = [fec cmosRate:j];
                    }                    
                    slot_idx++;
                }
            }
        }
        
        if ((!isPollingXl3 || isPollingVerbose) && [self calcCMOSRatesFromCounts]) {
            NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ CMOS rates:\n", [[self xl3Link] crateName]];
            unsigned char slot_idx = 0;

            if (msk < msk_full) {
                [msg appendFormat:@"slots masked out: "];
                unsigned int msk_missing = msk_full & ~msk;
                for (i=0; i<16; i++) {
                    if (msk_missing & (1UL << i)) {
                        [msg appendFormat:@"%d, ", i];
                    }
                }
                [msg appendFormat:@"\n"];
            }
         
            if (num_slots > 8) {
                slot_idx = 0;
                unsigned char j = 0;
                for (i=0; i<8; i++) {
                    if ((msk >> i) & 0x1) {
                        [msg appendFormat:@"slot: %2d\n", i];
                        [msg appendFormat:@"ch00-07:"];
                        for (j=0; j<8; j++) [msg appendFormat:@"%9.0f ", rates_lo.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\nch08-15:"];
                        for (j=8; j<16; j++) [msg appendFormat:@"%9.0f ", rates_lo.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\nch16-23:"];
                        for (j=16; j<24; j++) [msg appendFormat:@"%9.0f ", rates_lo.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\nch24-31:"];
                        for (j=24; j<32; j++) [msg appendFormat:@"%9.0f ", rates_lo.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\n"];
                        slot_idx++;
                    }
                }
                slot_idx=0;
                for (i=0; i<8; i++) {
                    if ((msk >> (i + 8)) & 0x1) {
                        [msg appendFormat:@"slot: %2d\n", i+8];
                        [msg appendFormat:@"ch00-07:"];
                        for (j=0; j<8; j++) [msg appendFormat:@"%9.0f ", rates_hi.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\nch08-15:"];
                        for (j=8; j<16; j++) [msg appendFormat:@"%9.0f ", rates_hi.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\nch16-23:"];
                        for (j=16; j<24; j++) [msg appendFormat:@"%9.0f ", rates_hi.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\nch24-31:"];
                        for (j=24; j<32; j++) [msg appendFormat:@"%9.0f ", rates_hi.rates[slot_idx*32 + j]];
                        [msg appendFormat:@"\n"];
                        slot_idx++;
                    }
                }
            }
            else {
                slot_idx = 0;
                unsigned char j = 0;
                for (i=0; i<16; i++) {
                     if ((msk >> i) & 0x1) {
                         [msg appendFormat:@"slot: %2d\n", i];
                         [msg appendFormat:@"ch00-07:"];
                         for (j=0; j<8; j++) [msg appendFormat:@"%9.0f ", rates_lo.rates[slot_idx*32 + j]];
                         [msg appendFormat:@"\nch08-15:"];
                         for (j=8; j<16; j++) [msg appendFormat:@"%9.0f ", rates_lo.rates[slot_idx*32 + j]];
                         [msg appendFormat:@"\nch16-23:"];
                         for (j=16; j<24; j++) [msg appendFormat:@"%9.0f ", rates_lo.rates[slot_idx*32 + j]];
                         [msg appendFormat:@"\nch24-31:"];
                         for (j=24; j<32; j++) [msg appendFormat:@"%9.0f ", rates_lo.rates[slot_idx*32 + j]];
                         [msg appendFormat:@"\n"];
                         slot_idx++;
                     }
                }
            }
            [msg appendFormat:@"\n"];
            NSLogFont([NSFont userFixedPitchFontOfSize:10], msg);
        }

        //data packet
        if (isPollingXl3 && [[ORGlobal sharedGlobal] runInProgress]) {
            uint32_t data[21+8*32+6];
            data[0] = [self cmosRateDataId] | (21+8*32+6);
            data[1] = [self crateNumber];
            data[2] = args_lo.slotMask;
            memcpy(data+3, args_lo.channelMasks, 16*4);
            data[19] = 0;
            data[20] = results_lo.errorFlags;
            memcpy(data+21, results_lo.count, 8*32*4);
            const char* timestamp = [[self stringDate] cStringUsingEncoding:NSASCIIStringEncoding];
            memcpy(data+21+8*32, timestamp, 6*4);
            NSData* cmosData = [[NSData alloc] initWithBytes:data length:sizeof(int32_t)*(21+8*32+6)];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification object:cmosData];
            [cmosData release];
            cmosData = nil;

            if (num_slots > 8) {
                data[2] = args_hi.slotMask;
                data[20] = results_hi.errorFlags;
                memcpy(data+21, results_hi.count, 8*32*4);
                cmosData = [[NSData alloc] initWithBytes:data length:sizeof(int32_t)*(21+8*32+6)];
                [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification object:cmosData];
                [cmosData release];
                cmosData = nil;
            }
        }
        [self setCalcCMOSRatesFromCounts:YES];
        [self setHvCMOSReadsCounter:[self hvCMOSReadsCounter]+1];
    }
}

- (void) readPMTBaseCurrentsWithArgs:(ReadPMTCurrentArgs*)aArgs currents:(ReadPMTCurrentResults*)result
{
	char payload[XL3_PAYLOAD_SIZE];
	memset(payload, 0x0, XL3_PAYLOAD_SIZE);
    
	ReadPMTCurrentArgs* data = (ReadPMTCurrentArgs*) payload;
    memcpy(data, aArgs, sizeof(ReadPMTCurrentArgs));
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(ReadPMTCurrentArgs)/4);
    }
    
    @try {
        [[self xl3Link] sendCommand:READ_PMT_CURRENT_ID withPayload:payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending readPMTBaseCurrentForSlot command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, 1);
    }
    
    memcpy(result, data, sizeof(ReadPMTCurrentResults));
}



- (void) readPMTBaseCurrentsForSlot:(unsigned short)aSlot withChannelMask:(uint32_t)aChannelMask
{
    ReadPMTCurrentArgs args;
    ReadPMTCurrentResults results;

    args.slotMask |= 0x1 << aSlot;
    args.channelMask[aSlot] = (uint32_t)aChannelMask;
    
    @try {
        [self readPMTBaseCurrentsWithArgs:&args currents:&results];
    }
    @catch (NSException *exception) {
        ;
    }

    if (results.errorFlags != 0) {
        NSLog(@"%@ error in readPMTBaseCurrentsForSlot, errorFlags: 0x%08x.\n",[[self xl3Link] crateName], results.errorFlags);
    }
    else {
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ PMT base currents for slot: %d\n", [[self xl3Link] crateName], aSlot];
        unsigned int i;
        for (i=0; i<32; i++) {
            if (aChannelMask & 0x1 << i) {
                [msg appendFormat:@"%d: %d\n", i, results.pmtCurrent[aSlot*32 + i]];
            }
        }
        NSLog(msg);
    }
}

//used from polling loop and/or ORCA script
- (void) readPMTBaseCurrents
{
    ReadPMTCurrentArgs args;
    ReadPMTCurrentResults results;
    unsigned char i;

	unsigned int msk = 0UL;
    for (id anObj in [[self guardian] orcaObjects]) { 
        if ([anObj class] == NSClassFromString(@"ORFec32Model")) {
            msk |= 1 << [anObj stationNumber];
        }
	}

    //if monitoring restrict to present, let scripts do what they wish
    unsigned int msk_full = msk;
    if (isPollingXl3 || isPollingForced) {
        msk &= pollPMTCurrentsMask;
    }
    
    args.slotMask = msk;
    for (i=0; i<16; i++) {
        args.channelMask[i] = 0xffffffff;
    }
    
    @try {
        [self readPMTBaseCurrentsWithArgs:&args currents:&results];
    }
    @catch (NSException *exception) {
        if (isPollingXl3) {
            NSLog(@"%@ Polling loop stopped becaused reading PMT based currents failed\n", [[self xl3Link] crateName]);
            [self setIsPollingXl3:NO];
        }
        return;
    }
    
    if (results.errorFlags != 0) {
        NSLog(@"%@ error in readPMTBaseCurrentsForSlot, errorFlags: 0x%08x.\n",[[self xl3Link] crateName], results.errorFlags);
        return;
    }
    else if (!isPollingXl3 || isPollingVerbose) {    
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ PMT base currents:\n", [[self xl3Link] crateName]];
        if (msk < msk_full) {
            [msg appendFormat:@"slots masked out: "];
            unsigned int msk_missing = msk_full & ~msk;
            for (i=0; i<16; i++) {
                if (msk_missing & (1UL << i)) {
                    [msg appendFormat:@"%d, ", i];
                }
            }
            [msg appendFormat:@"\n"];
        }

        [msg appendFormat:@"slot :    0    1    2    3    4    5    6    7 "];
        [msg appendFormat:@"   8    9   10   11   12   13   14   15\n"];
        [msg appendFormat:@"-----------------------------------------------"];
        [msg appendFormat:@"---------------------------------------\n"];
        unsigned char ch, sl;
        for (ch=0; ch<32; ch++) {
            [msg appendFormat:@"ch %2d: ", ch];
            for (sl=0; sl<16; sl++) {
                if ((msk >> sl) & 0x1) {
                    if (results.busyFlags[sl*32 + ch]) {
                        [msg appendFormat:@" BSY "];
                    }
                    else {
                        [msg appendFormat:@"%4d ", results.pmtCurrent[sl*32 + ch] - 127];
                    }
                }
                else [msg appendFormat:@" --- "];
            }
            [msg appendFormat:@"\n"];
        }
        [msg appendFormat:@"\n"];
        NSLogFont([NSFont userFixedPitchFontOfSize:10], msg);
    }
    
    //data packet
    const unsigned short packet_length = 20+16*8+16*8+6;
    if (isPollingXl3 && [[ORGlobal sharedGlobal] runInProgress]) {
        uint32_t data[packet_length];
        data[0] = [self pmtBaseCurrentDataId] | packet_length;
        data[1] = [self crateNumber];
        data[2] = args.slotMask;
        memcpy(data+3, args.channelMask, 16*4);
        data[19] = results.errorFlags;
        memcpy(data+20, results.pmtCurrent, 16*32);
        memcpy(data+20+16*8, results.busyFlags, 16*32);
        const char* timestamp = [[self stringDate] cStringUsingEncoding:NSASCIIStringEncoding];
        memcpy(data+20+16*8+16*8, timestamp, 6*4);
        NSData* pdata = [[NSData alloc] initWithBytes:data length:sizeof(int32_t)*(packet_length)];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification object:pdata];
        [pdata release];
        pdata = nil;
    }
}

// This will reset the HV control logic completely.
// Call this to wait for an XL3 to connect, read back the status, and get the
// gui into the correct state.
- (void) safeHvInit
{
    //Make sure we only have one init cycle going
    [hvInitLock lock];
    
    //Free the HV Init thread if it exists
    if (hvInitThread) {
        if (![hvInitThread isFinished]) {
            //Already created the thread and it is running
            return;
        }
        [hvInitThread release];
        hvInitThread = nil;
    }
    
    //Kill the HV thread if it exists
    if (hvThread) {
        if (![hvThread isFinished]) {
            [hvThread cancel];
        }
        [hvThread release];
        hvThread = nil;
    }
    
    //Set the HV control to a safe state
    [self setHvEverUpdated:NO];
    [self setHvSwitchEverUpdated:NO];
    
    //Start thread to wait for the XL3 to connect and be initilized
    hvInitThread = [[NSThread alloc] initWithTarget:self selector:@selector(_hvInit) object:nil];
    [hvInitThread start];
    
    [hvInitLock unlock];
}

- (void) readHVStatus:(HVReadbackResults*)status
{
	char payload[XL3_PAYLOAD_SIZE];
	memset(payload, 0, XL3_PAYLOAD_SIZE);

    @try {
        [[self xl3Link] sendCommand:HV_READBACK_ID withPayload:payload expectResponse:YES];
        //[[self xl3Link] sendCommand:GET_HV_STATUS_ID withPayload:payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLogColor([NSColor redColor],@"%@ error sending readHVStatus command.\n", [[self xl3Link] crateName]);
        @throw exception;
    }

    if ([xl3Link needToSwap]) {
        SwapLongBlock(payload, sizeof(HVReadbackResults)/4);
    }
    memcpy(status, payload, sizeof(HVReadbackResults));
}

- (void) readHVStatus
{
    /* Read back the HV value and current for supplies A and B and update the
     * model. */
    @synchronized(self) {
        if (![[self xl3Link] isConnected]) {
            NSLogColor([NSColor redColor], @"xl3 %i: readHVStatus called, "
                       "but XL3 is not connected!\n", [self crateNumber]);
            return;
        }

        HVReadbackResults status;
        @try {
            [self readHVStatus:&status];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"xl3 %i: Failed to read HV status: "
                       "%@\n", [self crateNumber], [e reason]);
            return;
        }

        [self setHvAVoltageReadValue:status.voltageA * 300. * self.hvReadbackCorrA];
        [self setHvBVoltageReadValue:status.voltageB * 300. * self.hvReadbackCorrB];
        [self setHvACurrentReadValue:status.currentA * 10.];
        [self setHvBCurrentReadValue:status.currentB * 10.];

        if (![self hvEverUpdated] &&
            ([self hvAVoltageReadValue] < ([self hvNominalVoltageA] - 100)) &&
            [self isTriggerON]) {
            /* If this is the first time we've read back HV, the crate is not
             * at nominal voltage, and the triggers are enabled, we prompt the
             * user to disable triggers. */
            dispatch_sync(dispatch_get_main_queue(), ^{
                BOOL result = ORRunAlertPanel([NSString stringWithFormat:@"Crate %i HV is not at nominal voltage, but triggers are currently enabled.", [self crateNumber]], @"Would you like to disable triggers?", @"Yes", @"No", nil);

                if (result) {
                    [self setIsTriggerON:NO];
                    NSLog(@"Crate %02d disabling triggers\n.", [self crateNumber]);
                    return;
                }
            });
        }

        [self setHvEverUpdated:YES];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:ORXL3ModelHvStatusChanged object:self];
        });
    }
}

- (void) hvUserIntervention:(BOOL)forA
{
    if (forA) {
        [self setHvAVoltageDACSetValue:(int)([self hvAVoltageReadValue]/3000.*4096.)];
        [self setHvANextStepValue:[self hvAVoltageDACSetValue]];
        [self setHvANeedsUserIntervention:false];
    } else {
        [self setHvBVoltageDACSetValue:(int)([self hvBVoltageReadValue]/3000.*4096.)];
        [self setHvBNextStepValue:[self hvBVoltageDACSetValue]];
        [self setHvBNeedsUserIntervention:false];
    }
    @try {
        [self setHVDacA:[self hvAVoltageDACSetValue] dacB:[self hvBVoltageDACSetValue]];
    }
    @catch (NSException *exception) {
        NSLogColor([NSColor redColor],@"%@ HV failed to set HV!\n", [[self xl3Link] crateName]);
    }
}

- (void) setHVRelays:(uint64_t)aRelayMask error:(uint32_t*)aError
{
	char payload[XL3_PAYLOAD_SIZE];
	memset(payload, 0, XL3_PAYLOAD_SIZE);

    uint32_t* data = (uint32_t*)payload;
    data[0] = aRelayMask & 0xffffffffUL; //mask1 bottom
    data[1] = aRelayMask >> 32;          //mask2 top

    NSLog(@"mask top: %x\n", data[1]);
    NSLog(@"mask bot: %x\n", data[0]);
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, 2);
    }

    @try {
        [[self xl3Link] sendCommand:SET_HV_RELAYS_ID withPayload:payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLogColor([NSColor redColor],@"%@ error sending setHVRelays command.\n",[[self xl3Link] crateName]);
        *aError = 0xFFFFFFFF;
        @throw exception;
    }
    
    *aError = data[0];
    
    if ([xl3Link needToSwap]) {
        *aError = swapLong(*aError);
    }    
}

- (void) setHVRelays:(uint64_t)aRelayMask
{
    uint32_t error;
    
    @try {
        [self setHVRelays:aRelayMask error:&error];
    }
    @catch (NSException *exception) {
    }
    
    if (error != 0) {
        NSLogColor([NSColor redColor],@"%@ error in setHVRelays relays were NOT set.\n",[[self xl3Link] crateName]);
    } else {
        NSLog(@"%@ HV relays set.\n",[[self xl3Link] crateName]);
    }
}

- (void) readHVRelays:(uint64_t*) _relayMask isKnown:(BOOL*)isKnown {
    char payload[XL3_PAYLOAD_SIZE];

    memset(payload, 0, XL3_PAYLOAD_SIZE);
    GetHVRelaysResults* data = (GetHVRelaysResults*) payload;

    [[self xl3Link] sendCommand:GET_HV_RELAYS_ID withPayload:payload expectResponse:YES];

    uint32_t mask1 = data->mask1;
    uint32_t mask2 = data->mask2;
    uint32_t known = data->relays_known;

    if ([xl3Link needToSwap]) {
        mask1 = swapLong(data->mask1);
        mask2 = swapLong(data->mask2);
        known = swapLong(data->relays_known);
    }
    *_relayMask = mask1 + ((uint64_t)mask2 << 32);
    *isKnown = (known != 0);

    if(!known) {
        [self setRelayStatus:@"status: UNKNOWN"];
    }
    else {
        [self setRelayMask:*_relayMask];
        [self setRelayStatus:@"status: SET"];

    }
}

- (void) closeHVRelays
{
    uint32_t error;
    
    @try {
        [self setHVRelays:relayMask error:&error];
    }
    @catch (NSException *exception) {
        [self setRelayStatus:@"status: UNKNOWN"];
    }
    
    if (error != 0) {
        NSLogColor([NSColor redColor],@"%@ error in setHVRelays relays were NOT set.\n",[[self xl3Link] crateName]);
        [self setRelayStatus:@"status: UNKNOWN"];
    }
    else{
        NSLog(@"%@ HV relays closed.\n",[[self xl3Link] crateName]);
        [self setRelayStatus:@"relays SET"];
    }
}

- (void) openHVRelays
{
    uint32_t error;
    
    [self setRelayMask:0ULL];
    
    @try {
        [self setHVRelays:0ULL error:&error];
    }
    @catch (NSException *exception) {
        [self setRelayStatus:@"status: UNKNOWN"];
    }
    
    if (error != 0) {
        NSLogColor([NSColor redColor],@"%@ error in openHVRelays relays were NOT set.\n",[[self xl3Link] crateName]);
        [self setRelayStatus:@"status: UNKNOWN"];
    }
    else{
        NSLog(@"%@ HV relays open.\n",[[self xl3Link] crateName]);
        [self setRelayStatus:@"relays OPENED"];
    }
}

- (void) setHVSwitchOnForA:(BOOL)aIsOn forB:(BOOL)bIsOn
{
	uint32_t xl3Address = (uint32_t)(XL3_SEL | [self getRegisterAddress:kXl3HvCsReg] | WRITE_REG);
	uint32_t aValue = 0UL;

    if (aIsOn) aValue |= 1UL;
    if (bIsOn) aValue |= 0x10000UL;
    
	@try {
		[xl3Link sendCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"%@ error writing XL3 HV CS register\n",[[self xl3Link] crateName]);
        @throw e;
	}
}

- (void) readHVSwitchOnForA:(BOOL*)aIsOn forB:(BOOL*)bIsOn
{
	uint32_t xl3Address = (uint32_t)(XL3_SEL | [self getRegisterAddress:kXl3HvCsReg] | READ_REG);
	uint32_t aValue = 0UL;
    
	@try {
		[xl3Link sendCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"%@ error reading XL3 HV CS register\n",[[self xl3Link] crateName]);
        @throw e;
	}
    
    *aIsOn = aValue & 0x1;
    *bIsOn = (aValue >> 16) & 0x1;
    
    [self setHvSwitchEverUpdated:YES];
    
}

- (void) readHVSwitchOn
{
    BOOL switchAIsOn;
    BOOL switchBIsOn;
    
    @try {
        [self readHVSwitchOnForA:&switchAIsOn forB:&switchBIsOn];
    }
    @catch (NSException *exception) {
        NSLogColor([NSColor redColor],@"%@ error in readHVSwitchOn\n", [[self xl3Link] crateName]);
        return;
    }
    
    [self setHvASwitch:switchAIsOn];
    [self setHvBSwitch:switchBIsOn];

    NSLog(@"%@ switch A is %@, switch B is %@.\n",[[self xl3Link] crateName], switchAIsOn?@"ON":@"OFF", switchBIsOn?@"ON":@"OFF");
}
- (uint32_t) checkRelays:(uint64_t)relays {
    // Returns a bit mask of which slots have issues with their relays
    // Currently just checks that any missing slots also have open relays
    // Could be expanded in the future.

    uint32_t bad_slots = 0;
    uint32_t slots = [self getSlotsPresent];
    for (int i=0;i<16;i++) {
        // If slot is missing
        if((slots & 1<<i) == 0) {
            // And if the 4 relays for that slot aren't all 0 (open)
            uint64_t mask = (uint64_t)0xF << i*4;
            if((mask & relays) != 0)
                //Then set a bit in bad_slots
                bad_slots |= 1<<i;
        }
    }
    return bad_slots;
}

- (BOOL) isHVAdvisable:(unsigned char) sup {
    BOOL interlockIsGood = false;
    BOOL relaysKnown = false;
    BOOL relaysGood = true; // Start true b/c if relaysKnown doesn't pass this won't be checked.
    BOOL modeGood = false;
    uint64_t relays;

    if ([self crateNumber] == 16 && sup != 0) { //16B
        //Checks interlocks for any crates with connected OWL tubes
        //Assumes that all relevant crates are represented in the open experiment
        uint32_t checkedCrates = 0;
        uint32_t goodInterlocks = 0;
        uint32_t knownRelays = 0;
        uint32_t goodRelays = 0;
        uint32_t goodModes = 0;

        NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
        for (uint32_t i = 0; i < [objs count]; i++) {
            ORXL3Model *xl3 = [objs objectAtIndex:i];
            if ([xl3 isOwlCrate]) {
                checkedCrates++;
                BOOL good = false;
                // First check the interlocks
                @try {
                    [xl3 readHVInterlockGood:&good];
                    if (good) {
                        goodInterlocks++;
                    } else {
                        NSLogColor([NSColor redColor],@"%@ HV interlock BAD\n",[[xl3 xl3Link] crateName]);
                    }
                }
                @catch (NSException *exception) {
                    NSLogColor([NSColor redColor],@"%@ error in readHVInterlock\n",[[xl3 xl3Link] crateName]);
                }
                // Now check the relays
                @try {
                    [xl3 readHVRelays:&relays isKnown:&good];
                    if (good) {
                        knownRelays++;
                        // If the relays are known make sure slot 15's are open if the FEC is missing
                        uint32_t bad_relays = [xl3 checkRelays:relays];
                        if((bad_relays & 1<<15) == 0) {
                            goodRelays++;
                        }
                        else {
                            NSLogColor([NSColor redColor], @"%@ HV relays for slot 15 are closed but FEC is missing!\n",[[self xl3Link] crateName]);
                        }

                    } else {
                        NSLogColor([NSColor redColor],@"%@ HV Relays unknown\n",[[xl3 xl3Link] crateName]);
                    }
                }
                @catch (NSException *exception) {
                    NSLogColor([NSColor redColor],@"%@ error in readHVRelays. Error: %@ Reason: %@\n",[[xl3 xl3Link] crateName],[exception name], [exception reason]);
                }

                // Finally make sure the XL3s are reading out
                if([xl3 xl3Mode] == NORMAL_MODE) {
                    goodModes++;
                } else {
                    NSLogColor([NSColor redColor],@"%@ NOT in normal mode\n",[[xl3 xl3Link] crateName]);
                }
            }
        }

        interlockIsGood = checkedCrates == goodInterlocks;
        relaysKnown     = checkedCrates == knownRelays;
        modeGood        = checkedCrates == goodModes;
        relaysGood      = knownRelays   == goodRelays;
    } else {
        //Checks the state for this crate only
        @try {
            [self readHVInterlockGood:&interlockIsGood];
            if (!interlockIsGood) NSLogColor([NSColor redColor],@"%@ HV interlock BAD\n",[[self xl3Link] crateName]);
        }
        @catch (NSException *exception) {
            NSLogColor([NSColor redColor],@"%@ error in readHVInterlock. Error: %@ Reason %@\n",[[self xl3Link] crateName],[exception name], [exception reason]);
        }

        @try {
            [self readHVRelays:&relays isKnown:&relaysKnown];
            if (!relaysKnown){
                NSLogColor([NSColor redColor],@"%@ HV relays unknown\n",[[self xl3Link] crateName]);
            }
        }
        @catch (NSException *exception) {
            NSLogColor([NSColor redColor],@"%@ error in readHVRelays. Error: %@ Reason: %@\n",[[self xl3Link] crateName],[exception name], [exception reason]);
        }

        // Make sure the relays are open for all slots that are missing
        if(relaysKnown) {
            uint32_t badRelays = [self checkRelays:relays];
            relaysGood = (badRelays == 0);
            if(!relaysGood) {
                NSLogColor([NSColor redColor], @"%@ has missing slots with closed relays!\n", [[self xl3Link] crateName]);
            }
        }

        // Check that the XL3 Mode is not INIT
        modeGood = [self xl3Mode] == NORMAL_MODE;
        if(!modeGood){
            NSLogColor([NSColor redColor], @"%@ is not in NORMAL mode!\n", [[self xl3Link] crateName]);
        }
    }

    return interlockIsGood && relaysKnown && modeGood && relaysGood;

}
- (void) setHVSwitch:(BOOL)aOn forPowerSupply:(unsigned char)sup
{
    @synchronized(self) {
    BOOL xl3SwitchA, xl3SwitchB;

    @try {
        [self readHVSwitchOnForA:&xl3SwitchA forB:&xl3SwitchB];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error in readHVSwitch\n", [[self xl3Link] crateName]);
        return;
    }

    [self setHvASwitch:xl3SwitchA];
    [self setHvBSwitch:xl3SwitchB];

    BOOL hv_advisable = [self isHVAdvisable:sup];

    if (!hv_advisable) {
        if (aOn) {
            NSLog(@"%@ NOT turning ON the HV power supply.\n",[[self xl3Link] crateName]);
            return;
        } else {
            NSLog(@"%@ continuing to turn OFF the HV power supply.\n",[[self xl3Link] crateName]);
        }
    }
        
    @try {
        [self readHVStatus];
    }
    @catch (NSException *exception) {
        NSLogColor([NSColor redColor],@"%@ error in readHVStatus\n",[[self xl3Link] crateName]);
        return;
    }

    @try {
        if (sup == 0) { //A
            [self setHVSwitchOnForA:aOn forB:hvBSwitch];
        }
        else {
            [self setHVSwitchOnForA:hvASwitch forB:aOn];
        }
    }
    @catch (NSException *exception) {
        NSLogColor([NSColor redColor],@"%@ error in setting the HV switch.",[[self xl3Link] crateName]);
        return;
    }
        
    //let's believe it worked
    if (sup == 0) { //A
        [self setHvASwitch:aOn];
    }
    else {
        [self setHvBSwitch:aOn];
    }
    
    usleep(10000);
    @try {
        [self readHVSwitchOnForA:&xl3SwitchA forB:&xl3SwitchB];
    }
    @catch (NSException *exception) {
        NSLogColor([NSColor redColor],@"%@ error in readHVSwitch\n", [[self xl3Link] crateName]);
        return;
    }
    
    [self setHvASwitch:xl3SwitchA];
    [self setHvBSwitch:xl3SwitchB];

    @try {
        [self readHVStatus];
    }
    @catch (NSException *exception) {
        NSLogColor([NSColor redColor],@"%@ error in readHVStatus\n",[[self xl3Link] crateName]);
        return;
    }
    
    }//synchronized
}

- (void) _hvPanicDown
{
    /* Panic down method which is called in a separate thread. */
    XL3Packet packet;
    memset(packet.payload, 0, XL3_PAYLOAD_SIZE);

    DoPanicDownResults* result = (DoPanicDownResults*) packet.payload;

    @try {
        [[self xl3Link] sendCommand:DO_PANIC_DOWN withPayload:packet.payload expectResponse:YES];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],@"crate %02d: error while performing panic down; error: %@ reason: %@\n",
                   [self crateNumber], [e name], [e reason]);
        goto err;
    }

    result->errorFlags = ntohl(result->errorFlags);

    if (result->errorFlags) {
        NSLogColor([NSColor redColor], @"crate %02d: There was a problem performing panic down. Try again or ramp crate manually",
                   [self crateNumber]);
        goto err;
    }

    /* Restart the HV thread. Need to post on the main thread. */
    dispatch_async(dispatch_get_main_queue(), ^{
        [self safeHvInit];
    });

    NSLog(@"crate %02d: panic down completed.\n", [self crateNumber]);

    return;

err:
    /* Restart the HV thread. Need to post on the main thread. */
    dispatch_async(dispatch_get_main_queue(), ^{
        [self safeHvInit];
    });
}

- (void) hvPanicDown
{
    /* Asynchronously send a panic down command to the XL3. The panic down
     * command will turn triggers off and then ramp down the HV. */
    [self setIsPollingXl3:NO];

    [NSThread detachNewThreadSelector:@selector(_hvPanicDown) toTarget:self withObject:nil];
}

- (void) hvTriggersON
{
    if (![[self xl3Link] isConnected]) {
        NSLog(@"%@ triggers ON ignored, xl3 is not connected.\n", [[self xl3Link] crateName]);
        return;
    }

    if (![self hvEverUpdated]) {
        BOOL result = ORRunAlertPanel([NSString stringWithFormat:@"Crate %i HV status is unknown", [self crateNumber]], @"Are you sure you want to enable triggers for this crate?", @"Yes", @"No", nil);

        if (!result) {
            NSLog(@"Crate %02d cancelling triggers ON\n.", [self crateNumber]);
            return;
        }
    } else if ([self hvAVoltageReadValue] < ([self hvNominalVoltageA] - 100)) {
        BOOL result = ORRunAlertPanel([NSString stringWithFormat:@"Crate %i HV is not at nominal voltage", [self crateNumber]], @"Are you sure you want to enable triggers for this crate?", @"Yes", @"No", nil);

        if (!result) {
            NSLog(@"Crate %02d cancelling triggers ON\n.", [self crateNumber]);
            return;
        }
    }

    [self setIsTriggerON:YES];
    [self loadTriggersAndSequencers];
    NSLog(@"%@ triggers ON\n", [[self xl3Link] crateName]);
}

- (void) hvTriggersOFF
{
    if ([[self xl3Link] isConnected]) {
        [self setIsTriggerON:NO];
        [self loadTriggersAndSequencers];
        NSLog(@"%@ triggers OFF\n", [[self xl3Link] crateName]);
    }
    else {
        NSLog(@"%@ triggers OFF ignored, crate is not connected.\n", [[self xl3Link] crateName]);
    }
}

- (void) readHVInterlockGood:(BOOL*)isGood
{
	uint32_t xl3Address = (uint32_t)(XL3_SEL | [self getRegisterAddress:kXl3HvCsReg] | READ_REG);
	uint32_t aValue = 0UL;
    
	@try {
		[xl3Link sendCommand:0UL toAddress:xl3Address withData:&aValue];
	}
	@catch (NSException* e) {
		NSLog(@"%@ error reading XL3 HV CS register\n",[[self xl3Link] crateName]);
        @throw e;
	}
    
    *isGood = aValue & 0x4;
}

- (void) readHVInterlock
{
    BOOL isGood;
    
    @try {
        [self readHVInterlockGood:&isGood];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error in readHVInterlock\n",[[self xl3Link] crateName]);
        return;
    }
    
    NSLog(@"%@ HV interlock is %@\n",[[self xl3Link] crateName], isGood?@"GOOD":@"BAD");
}

- (void) setHVDacA:(unsigned short)aDac dacB:(unsigned short)bDac
{
    //todo a dedicated HV lock
    @synchronized (self) {
        uint32_t xl3Address = (uint32_t)(XL3_SEL | [self getRegisterAddress:kXl3HvSetPointReg] | WRITE_REG);
        uint32_t aValue = 0UL;
        
        aValue |= aDac & 0xFFFUL;
        aValue |= (bDac & 0xFFFUL) << 16;
        
        @try {
            [xl3Link sendCommand:0UL toAddress:xl3Address withData:&aValue];
        }
        @catch (NSException* e) {
            NSLog(@"%@ error writing XL3 HV CS register\n",[[self xl3Link] crateName]);
        }
    }
}

#pragma mark •••tests
- (void) readVMONForSlot:(unsigned short)aSlot voltages:(VMonResults*)aVoltages
{
    char payload[XL3_PAYLOAD_SIZE];
    memset(payload, 0, XL3_PAYLOAD_SIZE);

    VMonArgs* data = (VMonArgs*) payload;
    data->slotNum = aSlot;

    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(VMonArgs)/4);
    }

    @try {
        [[self xl3Link] sendCommand:VMON_ID withPayload:payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending VMON_ID command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }

    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(VMonResults)/4);
    }

    memcpy(aVoltages, data, sizeof(VMonResults));
}

- (void) readVMONForSlot:(unsigned short)aSlot
{
    VMonResults result;
        
    @try {
        [self readVMONForSlot:aSlot voltages:&result];
    }
    @catch (NSException *exception) {
        if (isPollingXl3) {
            NSLog(@"Polling loop stopped because reading FEC local voltages failed\n");
            [self setIsPollingXl3:NO];
        }
        return;
    }
    /*
    if (!isPollingXl3 || isPollingVerbose) {
        //it doesn't set errorFlags
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ voltages for slot: %d\n", [[self xl3Link] crateName], aSlot];
        [msg appendFormat:@" -24V Sup: %f V\n", result.voltages[0]];
        [msg appendFormat:@" -15V Sup: %f V\n", result.voltages[1]];
        [msg appendFormat:@"  VEE Sup: %f V\n", result.voltages[2]];
        [msg appendFormat:@"-3.3V Sup: %f V\n", result.voltages[3]];
        [msg appendFormat:@"-2.0V Sup: %f V\n", result.voltages[4]];
        [msg appendFormat:@" 3.3V Sup: %f V\n", result.voltages[5]];
        [msg appendFormat:@" 4.0V Sup: %f V\n", result.voltages[6]];
        [msg appendFormat:@"  VCC Sup: %f V\n", result.voltages[7]];
        [msg appendFormat:@" 6.5V Sup: %f V\n", result.voltages[8]];
        [msg appendFormat:@" 8.0V Sup: %f V\n", result.voltages[9]];
        [msg appendFormat:@"  15V Sup: %f V\n", result.voltages[10]];
        [msg appendFormat:@"  24V Sup: %f V\n", result.voltages[11]];
        [msg appendFormat:@"-2.0V Ref: %f V\n", result.voltages[12]];
        [msg appendFormat:@"-1.0V Ref: %f V\n", result.voltages[13]];
        [msg appendFormat:@" 0.8V Ref: %f V\n", result.voltages[14]];
        [msg appendFormat:@" 1.0V Ref: %f V\n", result.voltages[15]];
        [msg appendFormat:@" 4.0V Ref: %f V\n", result.voltages[16]];
        [msg appendFormat:@" 5.0V Ref: %f V\n", result.voltages[17]];
        [msg appendFormat:@"    Temp.: %f degC\n", result.voltages[18]];
        [msg appendFormat:@"  Cal DAC: %f V\n", result.voltages[19]];
        [msg appendFormat:@"  HV Curr: %f mA\n", result.voltages[20]];

        NSLog(msg);
    }
    */
    
    //update FEC
    for (id anObj in [[self guardian] orcaObjects]) {
        if ([anObj class] == NSClassFromString(@"ORFec32Model") && [anObj stationNumber] == aSlot) {
            [anObj parseVoltages:&result];
        }
    }

    //data packet
    const unsigned char packet_length = 3+21+6;
    if (isPollingXl3 && [[ORGlobal sharedGlobal] runInProgress]) {
        uint32_t data[packet_length];
        data[0] = [self fecVltDataId] | packet_length;
        data[1] = [self crateNumber];
        data[2] = aSlot;
        memcpy(&data[3], result.voltages, 21*4);
        const char* timestamp = [[self stringDate] cStringUsingEncoding:NSASCIIStringEncoding];
        memcpy(data+24, timestamp, 6*4);
        NSData* pdata = [[NSData alloc] initWithBytes:data length:sizeof(int32_t)*(packet_length)];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification object:pdata];
        [pdata release];
        pdata = nil;
    }
}

//used from the polling loop and/or ORCA script
- (void) readVMONWithMask:(unsigned short)aSlotMask
{
    unsigned int msk = 0UL;
    BOOL wasPollingXl3 = [self isPollingXl3];
    
    for (id anObj in [[self guardian] orcaObjects]) { 
        if ([anObj class] == NSClassFromString(@"ORFec32Model")) {
            msk |= 1 << [anObj stationNumber];
        }
    }
    unsigned int msk_full = msk;
    
    if (isPollingXl3 || isPollingForced) {
        msk &= aSlotMask;
    }

    VMonResults result[16];
    memset(result, 0, 16*sizeof(VMonResults));
    unsigned char slot;
    for (slot=0; slot<16; slot++) {
        if ((msk >> slot) & 0x1) {

            @try {
                [self readVMONForSlot:slot voltages:&result[slot]];
            }
            @catch (NSException *exception) {
                if (isPollingXl3) {
                    NSLog(@"Polling loop stopped because reading FEC local voltages failed\n");
                    [self setIsPollingXl3:NO];
                    return;
                }
            }

            if (wasPollingXl3) {
                if (pollThread && [pollThread isCancelled]) return;
                if (![self isPollingXl3]) return;
            }

            //update FEC
            for (id aFEC in [[self guardian] orcaObjects]) {
                if (16 - [aFEC slot] == slot) { // do not use stationNumber here
                    [aFEC parseVoltages:&result[slot]];
                }
            }
            
            //data packet
            const unsigned char packet_length = 3+21+6;
            if (isPollingXl3 && [[ORGlobal sharedGlobal] runInProgress]) {
                uint32_t data[packet_length];
                data[0] = [self fecVltDataId] | packet_length;
                data[1] = [self crateNumber];
                data[2] = slot;
                memcpy(&data[3], result[slot].voltages, 21*4);
                const char* timestamp = [[self stringDate] cStringUsingEncoding:NSASCIIStringEncoding];
                memcpy(data+24, timestamp, 6*4);
                NSData* pdata = [[NSData alloc] initWithBytes:data length:sizeof(int32_t)*(packet_length)];
                [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification object:pdata];
                [pdata release];
                pdata = nil;
            }
        }
    }


    if (!wasPollingXl3 || isPollingVerbose) {
     
        char* vlt_a[] = {" -24V Sup:", " -15V Sup:", "  VEE Sup:", "-3.3V Sup:", "-2.0V Sup:",
            " 3.3V Sup:", " 4.0V Sup:", "  VCC Sup:", " 6.5V Sup:", " 8.0V Sup:", "  15V Sup:",
            "  24V Sup:", "-2.0V Ref:", "-1.0V Ref:", " 0.8V Ref:", " 1.0V Ref:", " 4.0V Ref:",
            " 5.0V Ref:", "    Temp.:", "  Cal DAC:", "  HV Curr:"};
        
        char* vlt_b[] = {" V", " V", " V", " V", " V", " V", " V", " V", " V", " V",
            " V", " V", " V", " V", " V", " V", " V", " V", " degC", " V", " mA"};
        
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ FEC voltages:\n", [[self xl3Link] crateName]];
        
        if (msk < msk_full) {
            [msg appendFormat:@"slots masked out: "];
            unsigned int msk_missing = msk_full & ~msk;
            for (slot=0; slot<16; slot++) {
                if (msk_missing & (1UL << slot)) {
                    [msg appendFormat:@"%d, ", slot];
                }
            }
            [msg appendFormat:@"\n"];
        }
        
        slot = 0;
        unsigned int cnt;
        unsigned int msk_set = msk;
        for (cnt = 0; msk_set; cnt++) msk_set &= msk_set - 1;
        
        while (cnt) {
            unsigned int slotNum;
            if (cnt > 8) {
                slotNum = 8;
                cnt -= 8;
            }
            else {
                slotNum = cnt;
                cnt = 0;
            }
            unsigned int slot_a[slotNum];
            unsigned int slot_to_assign = 0;
            while (slot_to_assign < slotNum) {
                if (msk >> slot & 0x1) {
                    slot_a[slot_to_assign] = slot;
                    slot_to_assign++;
                }
                slot++;
            }
            unsigned char sl = 0;
            unsigned char vlt = 0;
            [msg appendFormat:@"     slot:"];
            for (sl = 0; sl < slotNum; sl++) {
                [msg appendFormat:@"%8d ", slot_a[sl]];
            }
            [msg appendFormat:@"\n"];
            for (vlt = 0; vlt < 21; vlt++) {
                [msg appendFormat:@"%s", vlt_a[vlt]];
                for (sl = 0; sl < slotNum; sl++) {
                    [msg appendFormat:@"%8.2f ", result[slot_a[sl]].voltages[vlt]];
                }
                [msg appendFormat:@"%s\n", vlt_b[vlt]];
            }
            [msg appendFormat:@"\n"];
        }

        NSLogFont([NSFont userFixedPitchFontOfSize:10], msg);
    }
}

- (void) readVMONXL3:(LocalVMonResults*)aVoltages
{
    char payload[XL3_PAYLOAD_SIZE];
    memset(payload, 0, XL3_PAYLOAD_SIZE);
    LocalVMonResults* data = (LocalVMonResults*) payload;
        
    @try {
        [[self xl3Link] sendCommand:LOCAL_VMON_ID withPayload:payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending LOCAL_VMON_ID command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(LocalVMonResults)/4);
    }
            memcpy(aVoltages, data, sizeof(LocalVMonResults));
}

//used from polling loop and/or ORCA script
- (void) readVMONXL3
{
    LocalVMonResults result;
    
    @try {
        [self readVMONXL3:&result];
    }
    @catch (NSException *exception) {
        if (isPollingXl3) {
            NSLog(@"Polling loop stopped becaused reading XL3 local voltages failed\n");
            [self setIsPollingXl3:NO];
        }
        return;
    }
    
    //unless (isPollingXl3 && !isPollingVerbose)
    if (!isPollingXl3 || isPollingVerbose) {
        //it doesn't set errorFlags
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ local voltages:\n", [[self xl3Link] crateName]];
        [msg appendFormat:@"VCC: %.2f V\n", result.voltages[0]];
        [msg appendFormat:@"VEE: %.2f V\n", result.voltages[1]];
        //[msg appendFormat:@"VP8: %f V\n", result.voltages[2]];
        [msg appendFormat:@"VP24: %.2f V\n", result.voltages[3]];
        [msg appendFormat:@"VM24: %.2f V\n", result.voltages[4]];
        [msg appendFormat:@"TMP0: %.2f degC\n", result.voltages[5]];
        [msg appendFormat:@"TMP1: %.2f degC\n", result.voltages[6]];
        [msg appendFormat:@"TMP2: %.2f degC\n", result.voltages[7]];
        NSLog(msg);
    }    
    
    //data packet
    const unsigned char packet_length = 16;
    if (isPollingXl3 && [[ORGlobal sharedGlobal] runInProgress]) {
        uint32_t data[packet_length];
        data[0] = [self xl3VltDataId] | packet_length;
        data[1] = [self crateNumber];
        memcpy(&data[2], result.voltages, 8*4);
        const char* timestamp = [[self stringDate] cStringUsingEncoding:NSASCIIStringEncoding];
        memcpy(data+10, timestamp, 6*4);
        NSData* pdata = [[NSData alloc] initWithBytes:data length:sizeof(int32_t)*(packet_length)];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification object:pdata];
        [pdata release];
        pdata = nil;
    }
}

- (float) xl3VltThreshold:(unsigned short)idx
{
    if (idx < 12) {
        return _xl3VltThreshold[idx];
    }
    return 0;
}

- (void) setXl3VltThreshold:(unsigned short)idx withValue:(float)aThreashold
{
    if (idx < 12) {
        [[[self undoManager] prepareWithInvocationTarget:self] setXl3VltThreshold:idx withValue:[self xl3VltThreshold:idx]];
        _xl3VltThreshold[idx] = aThreashold;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelXl3VltThresholdChanged object:self];

    }
}

- (void) setVltThreshold
{

    [self setXl3VltThreshold:8 withValue: -10];
    [self setXl3VltThreshold:9 withValue: 10];
    
    char payload[XL3_PAYLOAD_SIZE];
    memset(payload, 0, XL3_PAYLOAD_SIZE);

    SetAlarmLevelsArgs* data = (SetAlarmLevelsArgs*) payload;
    
    unsigned short i;
    for (i=0; i<6; i++){
        data->lowLevels[i] = [self xl3VltThreshold:2*i];
        data->highLevels[i] = [self xl3VltThreshold:2*i+1];
    }    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(SetAlarmLevelsArgs)/4);
    }
    
    @try {
        [[self xl3Link] sendCommand:SET_ALARM_LEVELS_ID withPayload:payload expectResponse:YES];
    }
    @catch (NSException *e) {
        NSLog(@"%@ error sending SET_ALARM_LEVELS_ID command.\n",[[self xl3Link] crateName]);
        NSLog(@"%@ with reason: %@\n", [e name], [e reason]);
        return;
    }

    SetAlarmLevelsResults* res = (SetAlarmLevelsResults*) payload;
    if ([xl3Link needToSwap]) {
        SwapLongBlock(res, sizeof(SetAlarmLevelsResults)/4);
    }

    if (res->errorFlags) {
        char* vlts[] = {"VCC", "VEE", "VP24", "VM24", "VP8", "TMP0"};
        NSMutableString* msg = [NSMutableString stringWithFormat:
                                @"%@: setting voltage thresholds failed for: ",[[self xl3Link] crateName]];
        for (i=0; i<6; i++) {
            if (res->errorFlags >> i & 0x1) {
                [msg appendFormat:@"%s ", vlts[i]];
            }
        }
        [msg appendFormat:@"\n"];
        NSLog(msg);
    }
    else {
        NSLog(@"%@: voltage alarm thresholds set.\n",[[self xl3Link] crateName]);
    }
}

- (void) pollXl3:(BOOL)forceFlag
{
    if (pollThread) {
        if ([pollThread isFinished]) {
            [pollThread release];
            pollThread = nil;
        }
        else return;
    }
    isPollingForced = forceFlag;
    //[NSThread detachNewThreadSelector:@selector(_pollXl3) toTarget:self withObject:nil];
    pollThread = [[NSThread alloc] initWithTarget:self selector:@selector(_pollXl3) object:nil];
    [pollThread start];
}


//TODO: pass erroflags
- (void) loadSingleDacForSlot:(unsigned short)aSlot dacNum:(unsigned short)aDacNum dacVal:(unsigned char)aDacVal
{
 	char payload[XL3_PAYLOAD_SIZE];
	memset(payload, 0, XL3_PAYLOAD_SIZE);

    LoadsDacArgs* data = (LoadsDacArgs*)payload;
    LoadsDacResults* result = (LoadsDacResults*)payload;
    data->slotNum = aSlot;
    data->dacNum = aDacNum;
    data->dacValue = aDacVal;
    
    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, 3);
    }
    
    @try {
        [[self xl3Link] sendCommand:LOADSDAC_ID withPayload:payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ error sending loadSingleDac command.\n",[[self xl3Link] crateName]);
        @throw exception;
    }
    
    if ([xl3Link needToSwap]) {
        result->errorFlags = swapLong(result->errorFlags);
    }
    
    if (result->errorFlags) {
        NSLog(@"%@ loadSingleDac failed with errorFlags: 0x%x.\n",[[self xl3Link] crateName], result->errorFlags);
    }
}

- (void) setVthrDACsForSlot:(unsigned short)aSlot withChannelMask:(uint32_t)aChannelMask dac:(unsigned char)aDac
{
    //setVthr loading single DAC at the time. works fine. takes 0.5 sec per DAC.
/*
    unsigned short i;
    for (i=0; i<32; i++) {
        if (aChannelMask & (1<<i)) {
            @try {
                [self loadSingleDacForSlot:aSlot dacNum:25+i dacVal:aDac]; 
            }
            @catch (NSException *exception) {
                NSLog(@"Error in setVthrDACsFor slot: %d in channel: %d\n", aSlot, i);
                return;
            }
        }
    }
    NSLog(@"Set VthrDACs for slot: %d\n", aSlot);
*/

 	char payload[XL3_PAYLOAD_SIZE];
	memset(payload, 0, XL3_PAYLOAD_SIZE);
    
    MultiLoadsDacArgs* data = (MultiLoadsDacArgs*)payload;
    MultiLoadsDacResults* result = (MultiLoadsDacResults*)payload;

    unsigned short i;
    for (i=0; i<32; i++) {
        if (aChannelMask & (1<<i)) {
            data->dacs[data->numDacs].slotNum = aSlot;
            data->dacs[data->numDacs].dacNum = 25+i;
            data->dacs[data->numDacs].dacValue = aDac;
            data->numDacs++;
        }
    }

    if ([xl3Link needToSwap]) {
        SwapLongBlock(data, sizeof(MultiLoadsDacArgs)/4);
    }
    
    @try {
        [[self xl3Link] sendCommand:MULTI_LOADSDAC_ID withPayload:payload expectResponse:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"Error in setVthrDACsFor slot: %d\n", aSlot);
        return;
    }
        
    if ([xl3Link needToSwap]) {
        result->errorFlags = swapLong(result->errorFlags);
    }
    
    if (result->errorFlags) {
        NSLog(@"set Vthr DACs for slot %d failed with error_flag:0x%x\n", aSlot, result->errorFlags);
    }
    else {
        NSLog(@"set Vthr DACs for slot %d\n", aSlot);
    }
}

//Static method for the XL3's to request their HV paramters from the database
//Static and synchronized to bottle neck the access to the DB from all HV threads and only
//inform the user once of a missing DB object. Each thread requires independent confirmation
//before using hardcoded values (see _hv_*_dbparams)
//N.B. this method should NEVER be called from the main thread - it could deadlock
+ (bool) requestHVParams:(ORXL3Model*)model
{
    static uint32_t nodb = 0;
    //Synchronized on the class instance (self in static method)
    @synchronized (self) {
        ORPQModel *db = [ORPQModel getCurrent];
        // If no database object and we haven't informed the user yet
        if (!db && nodb < 10) {
            nodb++;
            // inform user of missing db object
            if (nodb == 10) { //exactly how int32_t this takes depends on the number of XL3's connected - max 10s from first connect
                dispatch_sync(dispatch_get_main_queue(), ^{
                    ORRunAlertPanel(@"PostgresDB object not found",@"Cannot get the PostgresDB object, please add one to the experiment and restart ORCA.",@"OK",nil,nil);
            
                });
            }
            return false;
        }
        //We previously could not find the db object
        if (nodb >= 10) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [model _hv_a_dbparams:nil];
            });
            if ([model crateNumber] == 16) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [model _hv_b_dbparams:nil];
                });
            } else {
                //hardcode non-16 supply B values
                [model setHvBFromDB:true];
                [model setHvReadbackCorrB:1.0];
                [model setHvNominalVoltageB:0];
                [model setHvramp_b_up:10.0];
                [model setHvramp_b_down:50.0];
                [model setVsetalarm_b_vtol:100.0];
                [model setIlowalarm_b_vmin:500.0];
                [model setIlowalarm_b_imin:0.0];
                [model setIhighalarm_b_imax:0.0];
                [model setVhighalarm_b_vmax:0.0];
            }
            return true;
        }
        //DB exists, send query for supplies
        if (![model hvAFromDB] && ![model hvAQueryWaiting]) {
            [model setHvAQueryWaiting:true];
            //N.B. timeout doesn't work as I expected
            //performSelector:withObject:afterDelay requires the thread it was called on to eventually exit to its event queue
            //_ONLY_ then will the cancel selector be called assuming the timeout has expired
            //Work around: call it on the main thread
            dispatch_sync(dispatch_get_main_queue(), ^{
                [db dbQuery:[NSString stringWithFormat:@"SELECT * FROM hvparams WHERE crate=%i AND supply='A'", [model crateNumber]] object:model selector:@selector(_hv_a_dbparams:) timeout:5.0];
            });
        }
        //crate 16 is special
        if ([model crateNumber] == 16) {
            if (![model hvBFromDB] && ![model hvBQueryWaiting]) {
                [model setHvBQueryWaiting:true];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [db dbQuery:[NSString stringWithFormat:@"SELECT * FROM hvparams WHERE crate=%i AND supply='B'", [model crateNumber]] object:model selector:@selector(_hv_b_dbparams:) timeout:5.0];
            
                });
            }
        } else {
            //hardcode non-16 supply B values
            [model setHvBFromDB:true];
            [model setHvReadbackCorrB:1.0];
            [model setHvNominalVoltageB:0];
            [model setHvramp_b_up:10.0];
            [model setHvramp_b_down:50.0];
            [model setVsetalarm_b_vtol:100.0];
            [model setIlowalarm_b_vmin:500.0];
            [model setIlowalarm_b_imin:0.0];
            [model setIhighalarm_b_imax:0.0];
            [model setVhighalarm_b_vmax:0.0];
        }
        return true;
    }
}

@end


@implementation ORXL3Model (private)
- (NSString*) stringDate
{
    if (!xl3DateFormatter) {
        xl3DateFormatter = [[NSDateFormatter alloc] init];
        //keep the format length 4*6 - 1 bytes
        [xl3DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SS'Z'"];
        xl3DateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        //iso.calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
        //iso.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
    }
    NSDate* strDate = [[NSDate alloc] init];
    NSString* result = [xl3DateFormatter stringFromDate:strDate];
    [strDate release];
    strDate = nil;
    return [[result retain] autorelease];
}

- (void) doBasicOp
{
	@try {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doBasicOp) object:nil];
		if(doReadOp){
			NSLog(@"%@ %@: 0x%08x\n",[[self xl3Link] crateName], reg[selectedRegister].regName, [self readXL3Register:selectedRegister]);
		}
		else {
			[self writeXL3Register:selectedRegister value:writeValue];
			NSLog(@"%@ Wrote 0x%08x to %@\n",[[self xl3Link] crateName], writeValue, reg[selectedRegister].regName);
		}

		if(++workingCount < repeatOpCount){
			if (autoIncrement) {
				selectedRegister++;
				if (selectedRegister == kXl3NumRegisters) selectedRegister = 0;
				[self setSelectedRegister:selectedRegister];
			}
			[self performSelector:@selector(doBasicOp) withObject:nil afterDelay:repeatDelay/1000.];
		}
		else {
			[self setBasicOpsRunning:NO];
		}
	}
	@catch(NSException* localException) {
		[self setBasicOpsRunning:NO];
		NSLog(@"%@ basic op exception: %@\n",[[self xl3Link] crateName],localException);
		[localException raise];
	}	
}

//polling thread
- (void) _pollXl3
{
    //once we experienced an uncaught excpetion from the polling function
    //i couldn't find antyhing documented to throw an exception
    //the REALLY BAD below is a temporary fix to trace it down
    NSAutoreleasePool* pollPool = [[NSAutoreleasePool alloc] init];
    NSDate* pollStartDate = nil;
    NSDate* nextStartDate = nil;
    NSTimeInterval startTime;
    BOOL isTimeToQuit = NO;

    while (!isTimeToQuit) {
        if (pollStartDate) {
            [pollStartDate release];
            pollStartDate = nil;
        }
        pollStartDate = [[NSDate alloc] init];
        if ([self isPollingCMOSRates] && (![[NSThread currentThread] isCancelled] || isPollingForced)) {
            @try {
                [self readCMOSRate]; //[msec]
            }
            @catch (NSException *e) {
                NSLog(@"%@ exception in the polling loop, readCMOSRate.\n", 
                      [self xl3Link]?[[self xl3Link] crateName]:@"REALLY BAD");
                NSLog(@"Exception: %@ with reason: %@\n", [e name], [e reason]);
            }
        }
        
        if ([self isPollingPMTCurrents] && (![[NSThread currentThread] isCancelled] || isPollingForced)) {
            @try {
                [self readPMTBaseCurrents];
            }
            @catch (NSException *e) {
                NSLog(@"%@ exception in the polling loop, readPMTBaseCurrents.\n", 
                      [self xl3Link]?[[self xl3Link] crateName]:@"REALLY BAD");
                NSLog(@"Exception: %@ with reason: %@\n", [e name], [e reason]);
            }
        }
        
        if ([self isPollingFECVoltages] && (![[NSThread currentThread] isCancelled] || isPollingForced)) {
            @try {
                [self readVMONWithMask:[self pollFECVoltagesMask]];
            }
            @catch (NSException *e) {
                NSLog(@"%@ exception in the polling loop, readVMON.\n", 
                      [self xl3Link]?[[self xl3Link] crateName]:@"REALLY BAD");
                NSLog(@"Exception: %@ with reason: %@\n", [e name], [e reason]);
            }
        }
        
        if ([self isPollingXl3Voltages] && (![[NSThread currentThread] isCancelled] || isPollingForced)) {
            @try {
                [self readVMONXL3];
            }
            @catch (NSException *e) {
                NSLog(@"%@ exception in the polling loop, readVMONXL3.\n", 
                      [self xl3Link]?[[self xl3Link] crateName]:@"REALLY BAD");
                NSLog(@"Exception: %@ with reason: %@\n", [e name], [e reason]);
            }
        }

        if ([self isPollingForced] || [[NSThread currentThread] isCancelled]) isTimeToQuit = YES;

        startTime = pollXl3Time + [pollStartDate timeIntervalSinceNow];
        if (startTime < 0.1) startTime = -0.1;
        nextStartDate = [[NSDate alloc] initWithTimeIntervalSinceNow:startTime];
        while (!isTimeToQuit && [nextStartDate timeIntervalSinceNow] > 0.) {
            usleep(100000);
            if ([[NSThread currentThread] isCancelled]) isTimeToQuit = YES;
            if (![self isPollingXl3]) isTimeToQuit = YES;
        }
        [nextStartDate release];
        nextStartDate = nil;
        [self setIsPollingForced:NO];
    }
    if (pollStartDate) {
        [pollStartDate release];
        pollStartDate = nil;
    }

    [pollPool release];
}

//hardcoded nominal voltages Dec 2016
float nominals[] = {2110.0, 2240.0, 2075.0, 2160.0, 2043.0, 2170.0, 2170.0, 2170.0,
                    2060.0, 2435.0, 2240.0, 2370.0, 2220.0, 2270.0, 1970.0, 2025.0,
                    1995.0, 1945.0, 2010.0, 2000.0}; //crates 0-19 supply a


//Callback for database access to hv params for supply a (runs on main thread)
- (void)_hv_a_dbparams:(ORPQResult*)result
{
    if (!hvAFromDB) { // Only do this once per init loop
        if (!result) { // Query failed for some reason
            BOOL res = ORRunAlertPanel(
                @"HV parameter query failed",
                [NSString stringWithFormat:@"Could not get HV parameters for supply %iA, use hardcoded defaults or try to load from DB again?", [self crateNumber]],
                @"Hardcoded Defaults",
                @"Try Again",
                nil);
            if (res) {
                NSLogColor([NSColor redColor],@"Using HARDCODED DEFAULTS for supply %iA\n", [self crateNumber]);
                [self setHvNominalVoltageA:nominals[[self crateNumber]]];
                [self setHvReadbackCorrA:1.0];
                [self setHvramp_a_up:10.0];
                [self setHvramp_a_down:50.0];
                [self setVsetalarm_a_vtol:100.0];
                [self setIlowalarm_a_vmin:100.0];
                [self setIlowalarm_a_imin:1.0];
                [self setIhighalarm_a_imax:65.0];
                [self setVhighalarm_a_vmax:nominals[[self crateNumber]]+100.0];
                [self setHvAFromDB:true];
            }
        } else { // Only do this once, assume non-nil means the request was good
            NSDictionary* dict = [result fetchRowAsDictionary];
            [self setHvNominalVoltageA:[(NSNumber*)[dict valueForKey:@"nominal"] floatValue]];
            [self setHvReadbackCorrA:[(NSNumber*)[dict valueForKey:@"readback_corr"] floatValue]];
            [self setHvramp_a_up:[(NSNumber*)[dict valueForKey:@"hvramp_up"] floatValue]];
            [self setHvramp_a_down:[(NSNumber*)[dict valueForKey:@"hvramp_down"] floatValue]];
            [self setVsetalarm_a_vtol:[(NSNumber*)[dict valueForKey:@"vsetalarm_vtol"] floatValue]];
            [self setIlowalarm_a_vmin:[(NSNumber*)[dict valueForKey:@"ilowalarm_vmin"] floatValue]];
            [self setIlowalarm_a_imin:[(NSNumber*)[dict valueForKey:@"ilowalarm_imin"] floatValue]];
            [self setVhighalarm_a_vmax:[(NSNumber*)[dict valueForKey:@"vhighalarm_vmax"] floatValue]];
            [self setIhighalarm_a_imax:[(NSNumber*)[dict valueForKey:@"ihighalarm_imax"] floatValue]];
            [self setHvAFromDB:true];
        }
    }
    [self setHvAQueryWaiting:false];
}

//Callback for database access to hv params for supply b (runs on main thread)
- (void)_hv_b_dbparams:(ORPQResult*)result
{
    if (!hvBFromDB) { // Only do this once per init loop
        if (!result) { // Query failed for some reason
            BOOL res = ORRunAlertPanel(
                @"HV parameter query failed",
                [NSString stringWithFormat:@"Could not get HV parameters for supply %iB, use hardcoded defaults or try to load from DB again?", [self crateNumber]],
                @"Hardcoded Defaults",
                @"Try Again",
                nil);
            if (res) {
                NSLogColor([NSColor redColor],@"Using HARDCODED DEFAULTS for supply %iB\n", [self crateNumber]);
                [self setHvNominalVoltageB:(int)([self crateNumber]==16 ? 2445.0 : 0.0)];
                [self setHvReadbackCorrB:1.0];
                [self setHvramp_b_up:10.0];
                [self setHvramp_b_down:50.0];
                [self setVsetalarm_b_vtol:100.0];
                [self setIlowalarm_b_vmin:100.0];
                [self setIlowalarm_b_imin:1.0];
                [self setIhighalarm_b_imax:65.0];
                [self setVhighalarm_b_vmax:(int)([self crateNumber]==16 ? 2445.0 : 0.0)+100.0];
                [self setHvBFromDB:true];
            }
        } else {
            NSDictionary* dict = [result fetchRowAsDictionary];
            [self setHvNominalVoltageB:[(NSNumber*)[dict valueForKey:@"nominal"] floatValue]];
            [self setHvReadbackCorrB:[(NSNumber*)[dict valueForKey:@"readback_corr"] floatValue]];
            [self setHvramp_b_up:[(NSNumber*)[dict valueForKey:@"hvramp_up"] floatValue]];
            [self setHvramp_b_down:[(NSNumber*)[dict valueForKey:@"hvramp_down"] floatValue]];
            [self setVsetalarm_b_vtol:[(NSNumber*)[dict valueForKey:@"vsetalarm_vtol"] floatValue]];
            [self setIlowalarm_b_vmin:[(NSNumber*)[dict valueForKey:@"ilowalarm_vmin"] floatValue]];
            [self setIlowalarm_b_imin:[(NSNumber*)[dict valueForKey:@"ilowalarm_imin"] floatValue]];
            [self setVhighalarm_b_vmax:[(NSNumber*)[dict valueForKey:@"vhighalarm_vmax"] floatValue]];
            [self setIhighalarm_b_imax:[(NSNumber*)[dict valueForKey:@"ihighalarm_imax"] floatValue]];
            [self setHvBFromDB:true];
        }
    }
    [self setHvBQueryWaiting:false];
}

// This method is started as a thread when a new ORXL3Model is created. It waits
// for the XL3 to connect AND for the XL3 to report that it the xilinx chip
// is properly initialized (necessary for HV readback) before launching the high
// voltage control thread.
- (void) _hvInit
{
    while (true) {
        //N.B. it is very important this is released before the loop continues/breaks
        NSAutoreleasePool* hvLoopPool = [[NSAutoreleasePool alloc] init];
        
        sleep(1);
        
        //Request the hv parameters (N.B. true does not mean they were loaded, check hvAFromDB and hvBFromDB)
        if ((!hvAFromDB || !hvBFromDB) && !(isLoaded && [ORXL3Model requestHVParams:self])) {
            [hvLoopPool release];
            continue;
        }
        
        //do nothing without an xl3 connected
        if ([self xl3Link] && [[self xl3Link] isConnected]) {
            if (![self stateUpdated] || ![self initialized]) {
                /* If the XL3 hasn't been initialized, then the registers are
                 * just random bytes, so we need to wait for a crate reset
                 * before checking the switches. */
                [hvLoopPool release];
                continue;
            }
            
            //Give up early if no control params yet (will not duplicate db queries)
            if (!hvAFromDB || !hvBFromDB) {
                [hvLoopPool release];
                continue;
            }
            
            //now readback the HV settings according to the XL3
            @try {
                [self readHVSwitchOn];
                [self readHVStatus];
            } @catch (NSException *e) {
                NSLogColor([NSColor redColor],@"%@ error reading XL3 hv status; error: %@ reason: %@\n", [[self xl3Link] crateName], [e name], [e reason]);
                [hvLoopPool release];
                continue; // try again later if there was an error
            }

            //the above methods can fail without an exception, but the flags never lie
            if (![self hvEverUpdated] || ![self hvSwitchEverUpdated]) {
                [hvLoopPool release];
                continue;
            }

            //set model values to hv readback or 0 if switch is off
            //N.B. readback can be arbitrarily offset from the previous setpoint
            //so we can't trust it enough to update the real setpoint. Never
            //allow setpoints over target. The first step if the HV is changed
            //will include this offset whatever it may be.
            if (!self.hvANeedsUserIntervention) {
                if ([self hvASwitch]) {
                    double next = [self hvAVoltageReadValue]*4096/3000.;
                    if (next > [self hvNominalVoltageA]*4096/3000)
                        next = [self hvNominalVoltageA]*4096/3000;
                    [self setHvAVoltageDACSetValue:next];
                    [self setHvANextStepValue:next];
                } else {
                    [self setHvAVoltageDACSetValue:0];
                    [self setHvANextStepValue:0];
                }
            }
            if (!self.hvBNeedsUserIntervention) {
                if ([self hvBSwitch]) {
                    double next = [self hvBVoltageReadValue]*4096/3000.;
                    if (next > [self hvNominalVoltageB]*4096/3000)
                        next = [self hvNominalVoltageB]*4096/3000;
                    [self setHvBVoltageDACSetValue:next];
                    [self setHvBNextStepValue:next];
                } else {
                    [self setHvBVoltageDACSetValue:0];
                    [self setHvBNextStepValue:0];
                }
            }
            
            //free the previous thread if it exists
            if (hvThread) {
                if (![hvThread isFinished]) {
                    [hvThread cancel];
                }
                [hvThread release];
                hvThread = nil;
            }
            
            // do we have control parameters?
            if (hvAFromDB && hvBFromDB) {
                hvThread = [[NSThread alloc] initWithTarget:self selector:@selector(_hvXl3) object:nil];
                [hvThread start];
            } else {
                [hvLoopPool release];
                continue;
            }
            
            //let everyone know that we now have HV control
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:ORXL3ModelHvStatusChanged object:self];
            });
            
            [hvLoopPool release];
            break; //exit loop
        }
        
    }
}

- (void) _trigger_edge_alarm:(int)alarmid
{
    @try {
        NSString* msg = [NSString stringWithFormat:@"SELECT * FROM post_alarm(%i)", alarmid];
        [[ORPQModel getCurrent] dbQuery:msg object:nil selector:nil];
    } @catch (NSException *exception) { }
}

- (void) _update_level_alarm:(int)alarmid level:(bool)level
{
    @try {
        NSString* msg;
        if (level) {
            msg = [NSString stringWithFormat:@"SELECT * FROM post_alarm(%i)", alarmid];
        } else {
            msg = [NSString stringWithFormat:@"SELECT * FROM clear_alarm(%i)", alarmid];
        }
        [[ORPQModel getCurrent] dbQuery:msg object:nil selector:nil];
    } @catch (NSException *exception) { }
}

- (void) _post_heartbeat:(int)crate
{
    @try {
        NSString* msg = [NSString stringWithFormat:@"SELECT * FROM post_heartbeat('orca_crate_%i_hv')", crate];
        [[ORPQModel getCurrent] dbQuery:msg object:nil selector:nil];
    } @catch (NSException *exception) { }
}

// This is the historical HV control and monitoring thread. It effectively ramps
// up or down towards set points (hv*NextStepValue) which are elsewhere set from 
// GUI elements or scripts.
//
// Note this will abort a ramp up and freeze the voltage if the readback differs
// by 100 volts from the last set value. Ramp down will not stop under any
// condition.
- (void) _hvXl3
{
    if (![self hvAFromDB] && ![self hvBFromDB]) {
        NSLog(@"%@ trying to start HV control thread without parameters!\n",[[self xl3Link] crateName]);
        return;
    }
    
    NSAutoreleasePool* hvPool = [[NSAutoreleasePool alloc] init];
    
    NSLog(@"%@ starting HV control thread\n",[[self xl3Link] crateName]);
    
    //Update log with new values
    [self readHVStatus];
    NSLog(@"%@ HV A Params: Nominal: %.1f V, ReadbackCorr: %.3f, RampUp: %.1f V/s, RampDown: %.1f V/s, Vtol: %.1f V, IlowVmin: %.1f V, IlowImin: %.1f mA, Ihigh: %.1f mA, Vhigh: %.1f V\n",
          [[self xl3Link] crateName], (float)[self hvNominalVoltageA], (float)[self hvReadbackCorrA], [self hvramp_a_up], [self hvramp_a_down], [self vsetalarm_a_vtol],
          [self ilowalarm_a_vmin], [self ilowalarm_a_imin], [self ihighalarm_a_imax], [self vhighalarm_a_vmax]);
    NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ HV A Status: ", [[self xl3Link] crateName]];
    [msg appendFormat:@"Setpoint: %.2f V, Voltage: %.2f V, Current: %.2f mA\n", [self hvAVoltageDACSetValue]/4096.*3000., [self hvAVoltageReadValue], [self hvACurrentReadValue]];
    NSLog(msg);
    if ([self crateNumber] == 16) {
        NSLog(@"%@ HV B Params: Nominal: %.1f V, ReadbackCorr: %.3f, RampUp: %.1f V/s, RampDown: %.1f V/s, Vtol: %.1f V, IlowVmin: %.1f V, IlowImin: %.1f mA, Ihigh: %.1f mA, Vhigh: %.1f V\n",
              [[self xl3Link] crateName], (float)[self hvNominalVoltageB], (float)[self hvReadbackCorrB], [self hvramp_b_up], [self hvramp_b_down], [self vsetalarm_b_vtol],
              [self ilowalarm_b_vmin], [self ilowalarm_b_imin], [self ihighalarm_b_imax], [self vhighalarm_b_vmax]);
        NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ HV B Status: ", [[self xl3Link] crateName]];
        [msg appendFormat:@"Setpoint: %.2f V, Voltage: %.2f V, I: %.2f mA\n", [self hvBVoltageDACSetValue]/4096.*3000., [self hvAVoltageReadValue], [self hvACurrentReadValue]];
        NSLog(msg);
    }
    
    //Remember state of alarm and only send alarm query on change
    bool lastSupplyACurrentDropout = false;
    bool lastSupplyAOverVoltage = false;
    bool lastSupplyAOverCurrent = false;
    bool lastSupplyASetpointDiscrepancy = false;
    bool lastSupplyBCurrentDropout = false;
    bool lastSupplyBOverVoltage = false;
    bool lastSupplyBOverCurrent = false;
    bool lastSupplyBSetpointDiscrepancy = false;
    //The above are updated with level alarms whenever:
    //   loopCounter = 0 to update on first loop (rolls over every 2^32 loops)
    //   the status of the alarm changes, along with updating the DB
    //Heartbeat sent on multiples of 10, incremented each loop (~1s)
    uint32_t loopCounter = 0;
    //Runs until the thread is cancelled or xl3 disconnects
    while (![[NSThread currentThread] isCancelled] && [self xl3Link] && [[self xl3Link] isConnected] && [self isLoaded]) {
        
        NSAutoreleasePool *hvLoopPool = [[NSAutoreleasePool alloc] init];
        
        //state variables
        bool aUp = false, bUp = false, achanging = false, bchanging = false;
        
        if (!self.hvANeedsUserIntervention && [self hvANextStepValue] != [self hvAVoltageDACSetValue]) {
            uint32_t aValueToSet = [self hvANextStepValue];
            achanging = true;
            
            if ([self hvANextStepValue] > [self hvAVoltageDACSetValue] + [self hvramp_a_up] / 3000. * 4096) {
                aValueToSet = [self hvAVoltageDACSetValue] + [self hvramp_a_up] / 3000. * 4096;
            }
            if ([self hvANextStepValue] < [self hvAVoltageDACSetValue] - [self hvramp_b_down] / 3000. * 4096) {
                aValueToSet = [self hvAVoltageDACSetValue] - [self hvramp_b_down] / 3000. * 4096;
            }
            if (aValueToSet > [self hvNominalVoltageA]*4096/3000) { //never go above nominal
                aValueToSet = [self hvNominalVoltageA]*4096/3000;
            }
            aUp = aValueToSet > [self hvAVoltageDACSetValue];
            @try {
                [self setHVDacA:aValueToSet dacB:[self hvBVoltageDACSetValue]];
                //assume it worked
                [self setHvAVoltageDACSetValue:aValueToSet];
            }
            @catch (NSException *exception) {
                NSLogColor([NSColor redColor],@"%@ HV failed to set HV!\n", [[self xl3Link] crateName]);
            }
        }
        
        if ([self crateNumber] == 16 && !self.hvBNeedsUserIntervention && [self hvBNextStepValue] != [self hvBVoltageDACSetValue]) {
            uint32_t aValueToSet = [self hvBNextStepValue];
            bchanging = true;
            
            if ([self hvBNextStepValue] > [self hvBVoltageDACSetValue] + [self hvramp_a_up] / 3000. * 4096) {
                aValueToSet = [self hvBVoltageDACSetValue] + [self hvramp_a_up] / 3000. * 4096;
            }
            if ([self hvBNextStepValue] < [self hvBVoltageDACSetValue] - [self hvramp_b_down] / 3000. * 4096) {
                aValueToSet = [self hvBVoltageDACSetValue] - [self hvramp_b_down] / 3000. * 4096;
            }
            if (aValueToSet > [self hvNominalVoltageB]*4096/3000) { // never go above target (?)
                aValueToSet = [self hvNominalVoltageB]*4096/3000;
            }
            bUp = aValueToSet > [self hvBVoltageDACSetValue];
            @try {
                [self setHVDacA:[self hvAVoltageDACSetValue] dacB:aValueToSet];
                //assume it worked
                [self setHvBVoltageDACSetValue:aValueToSet];
            }
            @catch (NSException *exception) {
                NSLogColor([NSColor redColor],@"%@ HV B failed to set HV!\n", [[self xl3Link] crateName]);
            }
        }

        //wait for supplies to update before doing anything
        usleep(1000000);

        //get the current status
        [self readHVStatus];

        if (achanging || bchanging) {
            if ([gOrcaGlobals runInProgress] && ([gOrcaGlobals runType] & kPhysicsRun)) {
                if (achanging) [self _trigger_edge_alarm:80500+[self crateNumber]*2+0];
                if (bchanging) [self _trigger_edge_alarm:80500+[self crateNumber]*2+1];
            }
            
            //Update log with new values
            NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ HV A Status: ", [[self xl3Link] crateName]];
            [msg appendFormat:@"Setpoint: %.2f V, Voltage: %.2f V, Current: %.2f mA\n", [self hvAVoltageDACSetValue]/4096.*3000., [self hvAVoltageReadValue], [self hvACurrentReadValue]];
            NSLog(msg);
            if ([self crateNumber] == 16) {
                NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ HV B Status: ", [[self xl3Link] crateName]];
                [msg appendFormat:@"Setpoint: %.2f V, Voltage: %.2f V, I: %.2f mA\n", [self hvBVoltageDACSetValue]/4096.*3000., [self hvBVoltageReadValue], [self hvBCurrentReadValue]];
                NSLog(msg);
            }

            //so the GUI knows what's currently happening in the control thread
            [self setHvARamping:([self hvANextStepValue] != [self hvAVoltageDACSetValue])];
            [self setHvBRamping:([self hvBNextStepValue] != [self hvBVoltageDACSetValue])];

            //check for ramps that aren't tracking the setpoints
            if ([self hvASwitch] && aUp && fabs([self hvAVoltageReadValue] - [self hvAVoltageDACSetValue]/4096.*3000.) > 100) {
                [self _trigger_edge_alarm:80100+[self crateNumber]*2+0];
                NSLogColor([NSColor redColor],@"%@ HV A read value differs from the setpoint. stopping!\nPress Ramp UP to continue.\n", [[self xl3Link] crateName]);
                [self setHvANextStepValue:[self hvAVoltageDACSetValue]];
            }
            if ([self crateNumber] == 16 && [self hvBSwitch] && bUp && fabs([self hvBVoltageReadValue] - [self hvBVoltageDACSetValue]/4096.*3000.) > 100) {
                [self _trigger_edge_alarm:80100+[self crateNumber]*2+1];
                NSLogColor([NSColor redColor],@"%@ HV B read value differs from the setpoint. stopping!\nPress Ramp UP to continue.\n", [[self xl3Link] crateName]);
                [self setHvBNextStepValue:[self hvBVoltageDACSetValue]];
            }

        } else {

            [self setHvARamping:false];
            [self setHvBRamping:false];

            //check hv setpoint alarm
            bool supplyASetpointDiscrepancy = false;
            if (self.hvANeedsUserIntervention) {
                if (fabs([self hvAVoltageReadValue] - [self hvAVoltageDACSetValue]/4096.*3000.) <= [self vsetalarm_a_vtol]) {
                    NSLogColor([NSColor redColor],@"%@ HV A read value recovered.\n", [[self xl3Link] crateName]);
                    self.hvANeedsUserIntervention = false;
                } else {
                    supplyASetpointDiscrepancy = true;
                }
            } else {
                if ([self hvASwitch] && (fabs([self hvAVoltageReadValue] - [self hvAVoltageDACSetValue]/4096.*3000.) > [self vsetalarm_a_vtol])) {
                    self.hvANeedsUserIntervention = true;
                    supplyASetpointDiscrepancy = true;
                    NSLogColor([NSColor redColor],@"%@ HV A read value differs from the setpoint! Suspending HV monitoring and control. Press 'Accept Readback' to resume.\n", [[self xl3Link] crateName]);

                    if ([self isTriggerON]) {
                        /* If the triggers are enabled, prompt the user to
                         * disable them.
                         *
                         * Note: dispatch this asynchronously so that the HV
                         * thread continues. */
                        dispatch_async(dispatch_get_main_queue(), ^{
                            BOOL result = ORRunAlertPanel([NSString stringWithFormat:@"Crate %i HV readback differs from the setpoint. This might indicate a tripped HV power supply. Triggers are currently enabled, which is not safe for the hardware unless the crate is at HV.", [self crateNumber]], @"Would you like to disable triggers?", @"Yes", @"No", nil);

                            if (result) {
                                [self hvTriggersOFF];
                                NSLog(@"Crate %02d disabling triggers\n.", [self crateNumber]);
                            }
                        });
                    }
                }
            }
            if (!loopCounter || supplyASetpointDiscrepancy != lastSupplyASetpointDiscrepancy) {
                lastSupplyASetpointDiscrepancy = supplyASetpointDiscrepancy;
                [self _update_level_alarm:80200+2*[self crateNumber]+0 level:supplyASetpointDiscrepancy];
            }
            
            if ([self crateNumber] == 16) {
                bool supplyBSetpointDiscrepancy = false;
                if (self.hvBNeedsUserIntervention) {
                    if (fabs([self hvBVoltageReadValue] - [self hvBVoltageDACSetValue]/4096.*3000.) <= [self vsetalarm_b_vtol]) {
                        NSLogColor([NSColor redColor],@"%@ HV B read value recovered.\n", [[self xl3Link] crateName]);
                        self.hvBNeedsUserIntervention = false;
                    } else {
                        supplyBSetpointDiscrepancy = true;
                    }
                } else {
                    if ([self hvBSwitch] && (fabs([self hvBVoltageReadValue] - [self hvBVoltageDACSetValue]/4096.*3000.) > 100)) {
                        self.hvBNeedsUserIntervention = true;
                        supplyBSetpointDiscrepancy = true;
                        NSLogColor([NSColor redColor],@"%@ HV B read value differs from the setpoint! Suspending HV monitoring and control. Press 'Accept Readback' to resume.\n", [[self xl3Link] crateName]);
                    }
                }
                if (!loopCounter || supplyBSetpointDiscrepancy != lastSupplyBSetpointDiscrepancy) {
                    lastSupplyBSetpointDiscrepancy = supplyBSetpointDiscrepancy;
                    [self _update_level_alarm:80200+2*[self crateNumber]+1 level:supplyBSetpointDiscrepancy];
                }
            }
        }
        
        //Voltage and current limit alarms
        bool supplyACurrentDropout = [self hvAVoltageReadValue] > [self ilowalarm_a_vmin] && [self hvACurrentReadValue] < [self ilowalarm_a_imin];
        bool supplyAOverVoltage = [self hvAVoltageReadValue] > [self vhighalarm_a_vmax];
        bool supplyAOverCurrent = [self hvACurrentReadValue] > [self ihighalarm_a_imax];
        int aoffset = 2*[self crateNumber] + 0;
        if (!loopCounter || supplyACurrentDropout != lastSupplyACurrentDropout) {
            lastSupplyACurrentDropout = supplyACurrentDropout;
            [self _update_level_alarm:80000+aoffset level:supplyACurrentDropout];
        }
        if (!loopCounter || supplyAOverCurrent != lastSupplyAOverCurrent) {
            lastSupplyAOverCurrent = supplyAOverCurrent;
            [self _update_level_alarm:80300+aoffset level:supplyAOverCurrent];
        }
        if (!loopCounter || supplyAOverVoltage != lastSupplyAOverVoltage) {
            lastSupplyAOverVoltage = supplyAOverVoltage;
            [self _update_level_alarm:80400+aoffset level:supplyAOverVoltage];
        }
        
        if ([self crateNumber] == 16) {
            bool supplyBCurrentDropout = [self hvBVoltageReadValue] > [self ilowalarm_b_vmin] && [self hvBCurrentReadValue] < [self ilowalarm_b_imin];
            bool supplyBOverVoltage = [self hvBVoltageReadValue] > [self vhighalarm_b_vmax];
            bool supplyBOverCurrent = [self hvBCurrentReadValue] > [self ihighalarm_b_imax];
            int boffset = 2*[self crateNumber] + 1;
            if (!loopCounter || supplyBCurrentDropout != lastSupplyBCurrentDropout) {
                lastSupplyBCurrentDropout = supplyBCurrentDropout;
                [self _update_level_alarm:80000+boffset level:supplyBCurrentDropout];
            }
            if (!loopCounter || supplyBOverCurrent != lastSupplyBOverCurrent) {
                lastSupplyBOverCurrent = supplyBOverCurrent;
                [self _update_level_alarm:80300+boffset level:supplyBOverCurrent];
            }
            if (!loopCounter || supplyBOverVoltage != lastSupplyBOverVoltage) {
                lastSupplyBOverVoltage = supplyBOverVoltage;
                [self _update_level_alarm:80400+boffset level:supplyBOverVoltage];
            }
        }
        
        if ((loopCounter++) % 10 == 0) [self _post_heartbeat:[self crateNumber]];
        
        [hvLoopPool release];
    }
    
    NSLog(@"%@ exiting HV control thread\n",[[self xl3Link] crateName]);
    
    //Try to restart if we can
    if ([self isLoaded]) [self safeHvInit];

    [hvPool release];
}

- (void) _setPedestalInParallelWorker
{

    @synchronized(self) {
        //Keep track of how many XL3s are changing ped mask
        changingPedMask = TRUE;

        char payload[XL3_PAYLOAD_SIZE];
        MultiSetCratePedsArgs *args;
        MultiSetCratePedsResults *results;
        int i;

        memset(&payload, 0, XL3_PAYLOAD_SIZE);

        args = (MultiSetCratePedsArgs *) payload;

        NSAutoreleasePool* pedPool = [[NSAutoreleasePool alloc] init];

        if (![[self xl3Link] isConnected]) {
            [pedPool release];
            changingPedMask = FALSE;
            return;
        }

        NSArray* fecs = [[self guardian]
                         collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];

        args->slotMask = 0;

        for (id aFec in fecs) {
            args->slotMask |= 1 << [aFec stationNumber];
            args->channelMasks[(int)[aFec stationNumber]] = (int)[aFec pedEnabledMask];
        }

        args->slotMask = htonl(args->slotMask);

        for (i = 0; i < 16; i++) {
            args->channelMasks[i] = htonl(args->channelMasks[i]);
        }

        @try {
            [[self xl3Link] sendCommand:MULTI_SET_CRATE_PEDS_ID
                            withPayload:payload expectResponse:YES];
        } @catch (NSException* e) {
            NSLog(@"%@ error setting pedestal masks. error: %@ reason: %@.\n",
                  [[self xl3Link] crateName], [e name], [e reason]);
            goto err;
        }

        results = (MultiSetCratePedsResults *) payload;

        if (results->errorMask) {
            NSLog(@"%@ error setting pedestal masks.\n",
                  [[self xl3Link] crateName]);
        }

    err:
        [pedPool release];
        changingPedMask = FALSE;
    }

}

@end
