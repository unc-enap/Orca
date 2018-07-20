//-------------------------------------------------------------------------
//  ORGretinaTriggerModel.m
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORGretinaTriggerModel.h"
#import "ORVmeCrateModel.h"
#import "ORFileMoverOp.h"
#import "MJDCmds.h"
#import "ORRunModel.h"
#import "ORAlarm.h"
#import "ORGretinaTriggerProtocol.h"
#import "ORDataPacket.h"


NSString* ORGretinaTriggerModelNumTimesToRetryChanged   = @"ORGretinaTriggerModelNumTimesToRetryChanged";
NSString* ORGretinaTriggerModelDoNotLockChanged         = @"ORGretinaTriggerModelDoNotLockChanged";
NSString* ORGretinaTriggerModelVerboseChanged           = @"ORGretinaTriggerModelVerboseChanged";
NSString* ORGretinaTriggerModelIsMasterChanged          = @"ORGretinaTriggerModelIsMasterChanged";
NSString* ORGretinaTriggerSettingsLock                  = @"ORGretinaTriggerSettingsLock";
NSString* ORGretinaTriggerRegisterLock                  = @"ORGretinaTriggerRegisterLock";
NSString* ORGretinaTriggerRegisterIndexChanged          = @"ORGretinaTriggerRegisterIndexChanged";
NSString* ORGretinaTriggerRegisterWriteValueChanged     = @"ORGretinaTriggerRegisterWriteValueChanged";
NSString* ORGretinaTriggerFpgaDownProgressChanged       = @"ORGretinaTriggerFpgaDownProgressChanged";
NSString* ORGretinaTriggerMainFPGADownLoadStateChanged	= @"ORGretinaTriggerMainFPGADownLoadStateChanged";
NSString* ORGretinaTriggerFpgaFilePathChanged			= @"ORGretinaTriggerFpgaFilePathChanged";
NSString* ORGretinaTriggerMainFPGADownLoadInProgressChanged = @"ORGretinaTriggerMainFPGADownLoadInProgressChanged";
NSString* ORGretinaTriggerFirmwareStatusStringChanged	= @"ORGretinaTriggerFirmwareStatusStringChanged";
NSString* ORGretinaTriggerModelInputLinkMaskChanged     = @"ORGretinaTriggerModelInputLinkMaskChanged";
NSString* ORGretinaTriggerSerdesTPowerMaskChanged       = @"ORGretinaTriggerSerdesTPowerMaskChanged";
NSString* ORGretinaTriggerSerdesRPowerMaskChanged       = @"ORGretinaTriggerSerdesRPowerMaskChanged";
NSString* ORGretinaTriggerLvdsPreemphasisCtlMask        = @"ORGretinaTriggerLvdsPreemphasisCtlMask";
NSString* ORGretinaTriggerMiscCtl1RegChanged            = @"ORGretinaTriggerMiscCtl1RegChanged";
NSString* ORGretinaTriggerMiscStatRegChanged            = @"ORGretinaTriggerMiscStatRegChanged";
NSString* ORGretinaTriggerLinkLruCrlRegChanged          = @"ORGretinaTriggerLinkLruCrlRegChanged";
NSString* ORGretinaTriggerLinkLockedRegChanged          = @"ORGretinaTriggerLinkLockedRegChanged";
NSString* ORGretinaTriggerClockUsingLLinkChanged        = @"ORGretinaTriggerClockUsingLLinkChanged";
NSString* ORGretinaTriggerModelInitStateChanged         = @"ORGretinaTriggerModelInitStateChanged";
NSString*  ORGretinaTriggerLockChanged                  = @"ORGretinaTriggerLockChanged";
NSString*  ORGretinaTriggerTimeStampChanged             = @"ORGretinaTriggerTimeStampChanged";

#define kFPGARemotePath @"GretinaFPGA.bin"
#define kCurrentFirmwareVersion 0x107
#define kTriggerInitDelay  0.02

@interface ORGretinaTriggerModel (private)
- (void) programFlashBuffer:(NSData*)theData;
- (void) programFlashBufferBlock:(NSData*)theData address:(uint32_t)address numberBytes:(uint32_t)numberBytesToWrite;
- (void) blockEraseFlash;
- (void) programFlashBuffer:(NSData*)theData;
- (BOOL) verifyFlashBuffer:(NSData*)theData;
- (void) reloadMainFPGAFromFlash;
- (void) setProgressStateOnMainThread:(NSString*)aState;
- (void) updateDownLoadProgress;
- (void) downloadingMainFPGADone;
- (void) fpgaDownLoadThread:(NSData*)dataFromFile;
- (void) copyFirmwareFileToSBC:(NSString*)firmwarePath;
- (BOOL) controllerIsSBC;
- (void) setFpgaDownProgress:(short)aFpgaDownProgress;
- (void) loadFPGAUsingSBC;
- (void) postCouchDBRecord;
@end

@implementation ORGretinaTriggerModel
#pragma mark •••Static Declarations

typedef struct {
	uint32_t offset; //from the base address
	NSString* name;
	BOOL accessType;
	BOOL hwType;
} GretinaTriggerRegisterInformation;


#define kReadOnly           0x1
#define kWriteOnly          0x2
#define kReadWrite          0x4
#define kMasterAndRouter    0x1
#define kMasterOnly         0x2
#define kRouterOnly         0x4
#define kDataGenerator      0x8

#define kGretinaTriggerFlashMaxWordCount	0xF
#define kGretinaTriggerFlashBlockSize		(128 * 1024)
#define kGretinaTriggerFlashBlocks          128
#define kGretinaTriggerUsedFlashBlocks      32
#define kGretinaTriggerFlashBufferBytes     32
#define kGretinaTriggerTotalFlashBytes      (kGretinaTriggerFlashBlocks * kGretinaTriggerFlashBlockSize)
#define kFlashBusy                          0x80
#define kGretinaTriggerFlashEnableWrite     0x10
#define kGretinaTriggerFlashDisableWrite	0x0
#define kGretinaTriggerFlashConfirmCmd      0xD0
#define kGretinaTriggerFlashWriteCmd		0xE8
#define kGretinaTriggerFlashBlockEraseCmd	0x20
#define kGretinaTriggerFlashReadArrayCmd	0xFF
#define kGretinaTriggerFlashStatusRegCmd	0x70
#define kGretinaTriggerFlashClearSRCmd      0x50

#define kGretinaTriggerResetMainFPGACmd     0x30
#define kGretinaTriggerReloadMainFPGACmd	0x3
#define kGretinaTriggerMainFPGAIsLoaded     0x41


static GretinaTriggerRegisterInformation register_information[kNumberOfGretinaTriggerRegisters] = {
    {0x0800,    @"Input Link Mask",     kReadWrite, kMasterAndRouter},
    {0x0804,    @"LED Register",        kReadWrite, kMasterAndRouter},
    {0x0808,    @"Skew Ctl A",          kReadWrite, kMasterAndRouter},
    {0x080D,    @"Skew Ctl B",          kReadWrite, kMasterAndRouter},
    {0x0810,    @"Skew Ctl C",          kReadWrite, kMasterAndRouter},
    {0x0814,    @"Misc Clk Crl",        kReadWrite, kMasterAndRouter},
    {0x0818,    @"Aux IO Crl",          kReadWrite, kMasterAndRouter},
    {0x081C,    @"Aux IO Data",         kReadWrite, kMasterAndRouter},
    {0x0820,    @"Aux Input Select",    kReadWrite, kMasterAndRouter},
    {0x0824,    @"Aux Trigger Width",   kReadWrite, kMasterOnly},
    
    {0x0828,    @"Serdes TPower",       kReadWrite, kMasterAndRouter},
    {0x082C,    @"Serdes RPower",       kReadWrite, kMasterAndRouter},
    {0x0830,    @"Serdes Local Le",     kReadWrite, kMasterAndRouter},
    {0x0834,    @"Serdes Line Le",      kReadWrite, kMasterAndRouter},
    {0x0838,    @"Lvds PreEmphasis",    kReadWrite, kMasterAndRouter},
    {0x083C,    @"Link Lru Crl",        kReadWrite, kMasterAndRouter},
    {0x0840,    @"Misc Ctl1",           kReadWrite, kMasterAndRouter},
    {0x0844,    @"Misc Ctl2",           kReadWrite, kMasterAndRouter},
    {0x0848,    @"Generic Test Fifo",   kReadWrite, kMasterAndRouter},
    {0x084C,    @"Diag Pin Crl",        kReadWrite, kMasterAndRouter},
    
    {0x0850,    @"Trig Mask",           kReadWrite, kMasterOnly},
    {0x0854,    @"Trig Dist Mask",      kReadWrite, kMasterOnly},
    {0x0860,    @"Serdes Mult Thresh",  kReadWrite, kMasterOnly},
    {0x0864,    @"Tw Ethresh Crl",      kReadWrite, kMasterOnly},
    {0x0868,    @"Tw Ethresh Low",      kReadWrite, kMasterOnly},
    {0x086C,    @"Tw Ethresh Hi",       kReadWrite, kMasterOnly},
    {0x0870,    @"Raw Ethresh low",     kReadWrite, kMasterOnly},
    {0x0874,    @"Raw Ethresh Hi",      kReadWrite, kMasterOnly},
    //------
    //Next blocks are define differently in Master and Router
    {0x0878,    @"Isomer Thresh1",      kReadWrite, kMasterOnly},
    {0x087C,    @"Isomer Thresh2",      kReadWrite, kMasterOnly},
    
    {0x0880,    @"Isomer Time Window",  kReadWrite, kMasterOnly},
    {0x0884,    @"Fifo Raw Esum Thresh",kReadWrite, kMasterOnly},
    {0x0888,    @"Fifo Tw Esum Thresh", kReadWrite, kMasterOnly},
    //-------
    {0x0878,    @"CC Pattern1",         kReadWrite, kRouterOnly},
    {0x087C,    @"CC Pattern2",         kReadWrite, kRouterOnly},
    {0x0880,    @"CC Pattern3",         kReadWrite, kRouterOnly},
    {0x0884,    @"CC Pattern4",         kReadWrite, kRouterOnly},
    {0x0888,    @"CC Pattern5",         kReadWrite, kRouterOnly},
    {0x088C,    @"CC Pattern6",         kReadWrite, kRouterOnly},
    {0x0890,    @"CC Pattern7",         kReadWrite, kRouterOnly},
    
    {0x0894,    @"CC Pattern8",         kReadWrite, kRouterOnly},
    //End of Split
    //----------
    {0x08A0,    @"Mon1 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08A4,    @"Mon2 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08A8,    @"Mon3 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08AC,    @"Mon4 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08B0,    @"Mon5 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08B4,    @"Mon6 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08B8,    @"Mon7 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08BC,    @"Mon8 Fifo Sel",       kReadWrite, kMasterAndRouter},
    {0x08C0,    @"Chan Fifo Crl",       kReadWrite, kMasterAndRouter},
    
    {0x08C4,    @"Dig Misc Bits",       kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08C8,    @"Dig DiscBit Src",     kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08CC,    @"Den Bits",            kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08D0,    @"Ren Bits",            kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08D4,    @"Sync Bits",           kReadWrite, kDataGenerator}, //spare in Master and Router
    {0x08E0,    @"Pulsed Ctl1",         kReadWrite, kMasterAndRouter},
    {0x08E4,    @"Pulsed Ctl2",         kReadWrite, kMasterAndRouter},
    {0x08F0,    @"Fifo Resets",         kReadWrite, kMasterAndRouter},
    {0x08F4,    @"Async Cmd Fifo",      kReadWrite, kMasterAndRouter},
    {0x08F8,    @"Aux Cmd Fifo",        kReadWrite, kMasterAndRouter},
    
    {0x08FC,    @"Debug Cmd Fifo",      kReadWrite, kMasterAndRouter},
    {0xA000,    @"Mask",                kReadWrite, kMasterAndRouter},
    {0xE000,    @"Fast Strb Thresh",    kReadWrite, kMasterAndRouter},
    {0x0100,    @"Link Locked",         kReadOnly, kMasterAndRouter},
    {0x0104,    @"Link Den",            kReadOnly, kMasterAndRouter},
    {0x0108,    @"Link Ren",            kReadOnly, kMasterAndRouter},
    {0x010C,    @"Link Sync",           kReadOnly, kMasterAndRouter},
    {0x0110,    @"Chan Fifo Stat",      kReadOnly, kMasterAndRouter},
    {0x0114,    @"TimeStamp A",         kReadOnly, kMasterAndRouter},
    {0x0118,    @"TimeStamp B",         kReadOnly, kMasterAndRouter},
    
    {0x011C,    @"TimeStamp C",         kReadOnly, kMasterAndRouter},
    {0x0120,    @"MSM State",           kReadOnly, kMasterOnly},
    //------
    //Next blocks are define differently in Master and Router
    {0x0124,    @"Chan Pipe Status",    kReadOnly, kMasterOnly},
    //-------
    {0x0124,    @"Rc State",            kReadOnly, kRouterOnly},
    //End of Split
    //----------
    {0x0128,    @"Misc Status",         kReadOnly, kMasterAndRouter},
    {0x012C,    @"Diagnostic A",        kReadOnly, kMasterAndRouter},
    {0x0130,    @"Diagnostic B",        kReadOnly, kMasterAndRouter},
    {0x0134,    @"Diagnostic C",        kReadOnly, kMasterAndRouter},
    {0x0138,    @"Diagnostic D",        kReadOnly, kMasterAndRouter},
    {0x013C,    @"Diagnostic E",        kReadOnly, kMasterAndRouter},
    
    {0x0140,    @"Diagnostic F",        kReadOnly, kMasterAndRouter},
    {0x0144,    @"Diagnostic G",        kReadOnly, kMasterAndRouter},
    {0x0148,    @"Diagnostic H",        kReadOnly, kMasterAndRouter},
    {0x014C,    @"Diag Stat",           kReadOnly, kMasterAndRouter},
    {0x0154,    @"Run Raw Esum",        kReadOnly, kMasterOnly},
    {0x0158,    @"Code Mode Date",      kReadOnly, kMasterAndRouter},
    {0x015C,    @"Code Revision",       kReadOnly, kMasterAndRouter},
    {0x0160,    @"Mon1 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0164,    @"Mon2 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0168,    @"Mon3 Fifo",           kReadOnly, kMasterAndRouter},
    
    {0x016C,    @"Mon4 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0170,    @"Mon5 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0174,    @"Mon6 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0178,    @"Mon7 Fifo",           kReadOnly, kMasterAndRouter},
    {0x017C,    @"Mon8 Fifo",           kReadOnly, kMasterAndRouter},
    {0x0180,    @"Chan1 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0184,    @"Chan2 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0188,    @"Chan3 Fifo",          kReadOnly, kMasterAndRouter},
    {0x018C,    @"Chan4 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0190,    @"Chan5 Fifo",          kReadOnly, kMasterAndRouter},
    
    {0x0194,    @"Chan6 Fifo",          kReadOnly, kMasterAndRouter},
    {0x0198,    @"Chan7 Fifo",          kReadOnly, kMasterAndRouter},
    {0x019C,    @"Chan8 Fifo",          kReadOnly, kMasterAndRouter},
    {0x01A0,    @"Mon Fifo State",      kReadOnly, kMasterAndRouter},
    {0x01A4,    @"Chan Fifo State",     kReadOnly, kMasterAndRouter},
    {0xA004,    @"Total Multiplicity",  kReadOnly, kMasterOnly},
    {0xA010,    @"RouterA Multiplicity",kReadOnly, kMasterOnly},
    {0xA014,    @"RouterB Multiplicity",kReadOnly, kMasterOnly},
    {0xA018,    @"RouterC Multiplicity",kReadOnly, kMasterOnly},
    {0xA01C,    @"RouterD Multiplicity",kReadOnly, kMasterOnly},
};

static GretinaTriggerRegisterInformation fpga_register_information[kTriggerNumberOfFPGARegisters] = {
    {0x900,	@"Main Digitizer FPGA configuration register"   ,kReadWrite, kMasterAndRouter},
    {0x904,	@"Main Digitizer FPGA status register"          ,kReadOnly, kMasterAndRouter},
    {0x908,	@"Voltage and Temperature Status"               ,kReadOnly, kMasterAndRouter},
    {0x910,	@"General Purpose VME Control Settings"         ,kReadWrite, kMasterAndRouter},
    {0x914,	@"VME Timeout Value Register"                   ,kReadWrite, kMasterAndRouter},
    {0x920,	@"VME Version/Status"                           ,kReadOnly, kMasterAndRouter},
    {0x930,	@"VME FPGA Sandbox Register 1"                  ,kReadWrite, kMasterAndRouter},
    {0x934,	@"VME FPGA Sandbox Register 2"                  ,kReadWrite, kMasterAndRouter},
    {0x938,	@"VME FPGA Sandbox Register 3"                  ,kReadWrite, kMasterAndRouter},
    {0x93C,	@"VME FPGA Sandbox Register 4"                  ,kReadWrite, kMasterAndRouter},
    {0x980,	@"Flash Address"                                ,kReadWrite, kMasterAndRouter},
    {0x984,	@"Flash Data with Auto-increment address"       ,kReadWrite, kMasterAndRouter},
    {0x988,	@"Flash Data"                                   ,kReadWrite, kMasterAndRouter},
    {0x98C,	@"Flash Command Register"                       ,kReadWrite, kMasterAndRouter}
};

#define kMasterState 0
#define kRouterState 1

typedef struct {
	int state;
    int stateType;
	NSString* name;
}GretinaTriggerStateInfo;

//do NOT change this list without changing the enum states in the .h file
static GretinaTriggerStateInfo master_state_info[kNumMasterTriggerStates] = {
    { kMasterIdle,              kMasterState,   @"Idle"},
    { kMasterSetup,             kMasterState,   @"Setup"},
    { kWaitOnRouterSetup,       kMasterState,   @"Wait On Router Setup"},
    { kSetInputLinkMask,        kMasterState,   @"Set Input Link Mask"},
    { kSetMasterTRPower,        kMasterState,   @"Set SerDes T/R Power"},
    { kSetMasterPreEmphCtrl,    kMasterState,   @"Set Pre-Emphassis Control"},
    { kReleaseLinkInit,         kMasterState,   @"Release Link-Init"},
    { kCheckMiscStatus,         kMasterState,   @"Check Misc Status"},
    { kStartRouterTRPowerUp,    kMasterState,   @"Running Router T/R Powerup"},
    { kWaitOnRouterTRPowerUp,   kMasterState,   @"Waiting on Router T/R Powerup"},
    { kReadLinkLock,            kMasterState,   @"Read Link Lock"},
    { kVerifyLinkState,         kMasterState,   @"Verify Link State"},
    { kSetClockSource,          kMasterState,   @"Setting Router Clock Src"},
    { kWaitOnSetClockSource,    kMasterState,   @"Waiting on Routers"},
    { kCheckWaitAckState,       kMasterState,   @"Check WAIT_ACK State"},
    { kMasterSetClearAckBit,    kMasterState,   @"Set and Clear ACK Bit"},
    { kVerifyAckMode,           kMasterState,   @"Verify ACKED Mode"},
    { kSendNormalData,          kMasterState,   @"Send Normal Data"},
    { kRunRouterDataCheck,      kMasterState,   @"Running Router/Gretina Setup"},
    { kWaitOnRouterDataCheck,   kMasterState,   @"Waiting on Routers and Digitizers"},
    { kFinalCheck,              kMasterState,   @"Final Check"},
    { kReleaseImpSync,          kMasterState,   @"Ensure Imp Sync Bit State"},
    { kFinalReset,              kMasterState,   @"Final Reset of Clocks"},
    { kMasterError,             kMasterState,   @""}
};

//do NOT change this list without changing the enum states in the .h file
static GretinaTriggerStateInfo router_state_info[kNumRouterTriggerStates] = {
    { kRouterIdle,              kRouterState,   @"Idle"},
    { kRouterSetup,             kRouterState,   @"Setup"},
    { kDigitizerSetup,          kRouterState,   @"Running Digitizer Setup"},
    { kDigitizerSetupWait,      kRouterState,   @"Waiting For Digitizer SerDes Setup"},
    { kSetRouterTRPower,        kRouterState,   @"Set SerDes T/R Power"},
    { SetLLinkDenRenSync,       kRouterState,   @"L Link DEN,REN,SYNC"},
    { kSetRouterPreEmphCtrl,    kRouterState,   @"Set Pre-Emphassis Control"},
    { KSetRouterClockSource,    kRouterState,   @"Set Router Clock Source"},
    { kRouterDataChecking,      kRouterState,   @"Router Stringent Data Checking"},
    { kMaskUnusedRouterChans,   kRouterState,   @"Mask Unused Router Channels"},
    { kSetTRPowerBits,          kRouterState,   @"Set TPower and RPower Bits"},
    { kReleaseLintInitReset,    kRouterState,   @"Release LINK_INIT Reset"},
    { kRunDigitizerInit,        kRouterState,   @"Running Digitizer Init"},
    { kWaitOnDigitizerInit,     kRouterState,   @"Waiting For Digitizer init"},
    { kRouterSetClearAckBit,    kRouterState,   @"Set and Clear ACK Bit"},
    { kRouterError,             kRouterState,   @""}
};

#pragma mark ***Initialization
- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    int i;
    for(i=0;i<9;i++){
        [linkConnector[i] release];
    }
    [mainFPGADownLoadState release];
    [fpgaFilePath release];
	[progressLock release];
    [fileQueue cancelAllOperations];
    [fileQueue release];
    [stateStatus release];
    [errorString release];
    [noClockAlarm clearAlarm];
    [noClockAlarm release];
    noClockAlarm = nil;
    [linkLostAlarm clearAlarm];
    [linkLostAlarm release];
    linkLostAlarm = nil;
    [super dealloc];
}

- (void)sleep
{
    [super sleep];
    [noClockAlarm clearAlarm];
    [noClockAlarm release];
    noClockAlarm = nil;
    [linkLostAlarm clearAlarm];
    [linkLostAlarm release];
    linkLostAlarm = nil;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"GretinaTrigger"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORGretinaTriggerController"];
}

//- (NSString*) helpURL
//{
//	return @"VME/GretinaTrigger.html"; //TBD
//}

- (Class) guardianClass
{
	return NSClassFromString(@"ORVme64CrateModel");
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,baseAddress+0xffff);
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORVmeCardSlotChangedNotification
	 object: self];
}

- (void) makeConnectors
{
    //make and cache our connector. However these connectors will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    int i;
    for(i=0;i<9;i++){
        [self setLink:i connector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
        [linkConnector[i] setSameGuardianIsOK:YES];
        [linkConnector[i] setConnectorImageType:kSmallDot];
        if(i<8){
            [linkConnector[i] setConnectorType: 'LNKO' ];
            [linkConnector[i] addRestrictedConnectionType: 'LNKI' ];
        }
        else {
            [linkConnector[i] setConnectorType: 'LNKI' ];
            [linkConnector[i] addRestrictedConnectionType: 'LNKO' ];
        }
        [linkConnector[i] setOffColor:[NSColor colorWithCalibratedRed:1 green:1 blue:.3 alpha:1.]];
        if(i<8)[linkConnector[i] setIdentifer:'A'+i];
        else   [linkConnector[i] setIdentifer:'L'];
    }
}

- (void) positionConnector:(ORConnector*)aConnector
{
    NSRect aFrame = [aConnector localFrame];
    int i;
    for(i=0;i<9;i++){
        if(aConnector == linkConnector[i]){
            float x =  17 + [self slot] * 16*.62 ;
            float y =  95 - (kConnectorSize-4)*i;
            if(i==8)y -= 10;
            aFrame.origin = NSMakePoint(x,y);
            [aConnector setLocalFrame:aFrame];
            break;
        }
    }
}

- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
	
	[super setGuardian:aGuardian];
	
    int i;
    if(oldGuardian != aGuardian){
        for(i=0;i<9;i++){
            [oldGuardian removeDisplayOf:linkConnector[i]];
        }
    }
	
    for(i=0;i<9;i++){
        [aGuardian assumeDisplayOf:linkConnector[i]];
    }
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    int i;
    for(i=0;i<9;i++){
        [aGuardian positionConnector:linkConnector[i] forCard:self];
    }
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    int i;
    for(i=0;i<9;i++){
        [aGuardian removeDisplayOf:linkConnector[i]];
    }
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    int i;
    for(i=0;i<9;i++){
        [aGuardian assumeDisplayOf:linkConnector[i]];
    }
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter removeObserver:self];
    [notifyCenter addObserver : self
                     selector : @selector(runInitialization:)
                         name : ORRunInitializationNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(startPollingLock:)
                         name : ORRunAboutToStartNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(endPollingLock:)
                         name : ORRunAboutToStopNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStarted:)
                         name : ORRunStartedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runStopped:)
                         name : ORRunStoppedNotification
                       object : nil];

}

- (void) startPollingLock:(NSNotification*)aNote
{
    //only poll the state if we are master and the user wants to lock
    if([self isMaster] && !doNotLock){
        @try {
            //double check that we can reach the card by reading the boardID. If an exception
            //is thrown, then we won't actually start polling

            [self pollLock];
        }
        @catch(NSException* e){
            NSLog(@"%@:%@ Exception: %@\n",[self fullID],NSStringFromSelector(_cmd),e);
            NSLog(@"%@ not polling system lock because of exception\n",[self fullID]);
        }
    }
}

- (void) endPollingLock:(NSNotification*)aNote
{
    if([self isMaster]){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollLock) object:nil];
        BOOL doInit = [[[aNote userInfo] objectForKey:@"doinit"] boolValue];
        if(doInit){
            uint32_t aValue = [self readRegister:kMiscCtl1];
            [self writeRegister:kMiscCtl1 withValue:aValue |= (0x1<<6)]; //set the Imp Syn
            [self setMiscCtl1Reg:       [self readRegister:kMiscCtl1]];  //display it
        }
     }
}
- (void) runStarted:(NSNotification*)aNote
{
    if([self isMaster]){
        [self shipDataRecord];
    }
}

- (void) runStopped:(NSNotification*)aNote
{
    if([self isMaster]){
        [self shipDataRecord];
    }
}

- (void) resetTimeStamps
{
    //to reset the clocks set bit 6 of the MISC_CTRL reg
    //When this bit is set, the timestamp counter is held reset with value of zero
    //Since there is just a couple of operations here and we want to be fast just
    //send the commands without going thru a state machine.
    uint32_t aValue = [self readRegister:kMiscCtl1];
    [self writeRegister:kMiscCtl1 withValue:aValue |= (0x1<<6)];//set imp sync to hold clocks in reset
    [self resetScalerTimeStamps];
    [self writeRegister:kMiscCtl1 withValue:aValue &= ~(0x1<<6)];//release imp sync

    //    [self writeRegister:kPulsedCtl2 withValue:0x1000]; //send one imp syn
    [self readDisplayRegs];
}

- (void) pollLock
{
    @try {
        if([self isMaster]){
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollLock) object:nil];
            [self readDisplayRegs];
            [self checkSystemLock];
            [self readTimeStamps];
            int i;
            for(i=0;i<8;i++){
                ORConnector* otherConnector = [linkConnector[i] connector];
                if([otherConnector identifer] == 'L'){
                    ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
                    [routerObj readTimeStamps];
                }
            }
            [self checkForLostLinkCondition];
            [self performSelector:@selector(pollLock) withObject:nil afterDelay:10];
        }
    }
    @catch (NSException* e){
        
    }
}

- (int) tryNumber
{
    return tryNumber;
}

- (void) runInitialization:(NSNotification*)aNote
{
    tryNumber = 0;
    if(!doNotLock){
        if([self isMaster]){
            @try {
                [self readRegister:kLEDRegister]; //throws if can't reach board
               // [self pulseNIMOutput];
                if(![(ORRunModel*)[aNote object] quickStart] || doLockRecoveryInQuckStart){
                    [self initClockDistribution];
                }
                else {
                    //quick start, but check if transistional run
                    if(([(ORRunModel*)[aNote object] runType] & 0x10000) == 0x10000){
                        [self resetTimeStamps];
                    }
                }
            }
            @catch(NSException* e){
                NSLog(@"%@:%@ Exception: %@\n",[self fullID],NSStringFromSelector(_cmd),e);
                NSLog(@"%@ Did not init the clock because of exception\n",[self fullID]);
            }
        }
    }
    else {
        NSLogColor([NSColor redColor],@"%@: Will NOT distribute clock pulses (User Option)\n",[self fullID]);
        if(!noClockAlarm){
            noClockAlarm = [[ORAlarm alloc] initWithName:@"No Clock Distribution (User Option)" severity:kInformationAlarm];
            [noClockAlarm setSticky:NO];
            [noClockAlarm setHelpString:@"User has opted to NOT distribute clock pulses from the Gretina trigger master. This alarm will go away if you acknowledge it."];
        }
        [noClockAlarm setAcknowledged:NO];
        [noClockAlarm postAlarm];
        [self setToInternalClock];
    }
}

- (void) pulseNIMOutput
{
    //this routine will send out a single pulse on both NIM outputs
    //if(!setupNIMOutputDone){
        setupNIMOutputDone = YES;
        unsigned short regValue = [self readRegister:kAuxIOCrl]; //get the orginal value
        regValue |= 0x5000; //set both NIM outputs to Any Trigger b0101
        [self writeRegister:kAuxIOCrl withValue:regValue];

        [self writeRegister:kTrigMask withValue:0x1];
        [self writeRegister:kAuxTriggerWidth withValue:0xff]; //set to max width ~50µs
   // }
    
    [self writeRegister:kPulsedCtl1 withValue:0x8000]; //generate 1 manual trigger)
    
}

#pragma mark ***Accessors

- (uint64_t) timeStamp
{
    return ((int64_t)timeStampA)<<24 | ((int64_t)timeStampB)<<16 | timeStampB;
}

- (unsigned short) numTimesToRetry
{
    return numTimesToRetry;
}

- (void) setNumTimesToRetry:(unsigned short)aNumTimesToRetry
{
    if(aNumTimesToRetry<1)      aNumTimesToRetry=1;
    else if(aNumTimesToRetry>10)aNumTimesToRetry=10;
    [[[self undoManager] prepareWithInvocationTarget:self] setNumTimesToRetry:numTimesToRetry];
    
    numTimesToRetry = aNumTimesToRetry;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelNumTimesToRetryChanged object:self];
}

- (BOOL) doNotLock
{
    return doNotLock;
}

- (void) setDoNotLock:(BOOL)aDoNotLock
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoNotLock:doNotLock];
    
    doNotLock = aDoNotLock;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelDoNotLockChanged object:self];
}

- (int) digitizerCount      {return digitizerCount;}
- (int) digitizerLockCount  {return digitizerLockCount;}

- (void) setErrorString:(NSString*)aString
{
    [errorString autorelease];
    errorString = [aString copy];
    NSLog(@"%@\n",errorString);
}

- (NSString*) errorString
{
    return errorString;
}

- (BOOL) verbose
{
    return verbose;
}

- (void) setVerbose:(BOOL)aVerbose
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVerbose:verbose];
    
    verbose = aVerbose;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelVerboseChanged object:self];
}

- (NSString*) firmwareStatusString
{
    if(!firmwareStatusString)return @"--";
    else return firmwareStatusString;
}

- (void) setFirmwareStatusString:(NSString*)aState
{
	if(!aState)aState = @"--";
    [firmwareStatusString autorelease];
    firmwareStatusString = [aState copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerFirmwareStatusStringChanged object:self];
}
- (BOOL) downLoadMainFPGAInProgress
{
	return downLoadMainFPGAInProgress;
}

- (void) setDownLoadMainFPGAInProgress:(BOOL)aState
{
	downLoadMainFPGAInProgress = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerMainFPGADownLoadInProgressChanged object:self];
}

- (short) fpgaDownProgress
{
	int temp;
	[progressLock lock];
    temp = fpgaDownProgress;
	[progressLock unlock];
    return temp;
}

- (NSString*) mainFPGADownLoadState
{
	if(!mainFPGADownLoadState) return @"--";
    else return mainFPGADownLoadState;
}

- (void) setMainFPGADownLoadState:(NSString*)aMainFPGADownLoadState
{
	if(!aMainFPGADownLoadState) aMainFPGADownLoadState = @"--";
    [mainFPGADownLoadState autorelease];
    mainFPGADownLoadState = [aMainFPGADownLoadState copy];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerMainFPGADownLoadStateChanged object:self];
}

- (NSString*) fpgaFilePath
{
    if(fpgaFilePath) return fpgaFilePath;
    else return @"";
}

- (void) setFpgaFilePath:(NSString*)aFpgaFilePath
{
	if(!aFpgaFilePath)aFpgaFilePath = @"";
    [fpgaFilePath autorelease];
    fpgaFilePath = [aFpgaFilePath copy];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerFpgaFilePathChanged object:self];
}

- (unsigned short) inputLinkMask         { return inputLinkMask & 0xffff; }
- (unsigned short) serdesTPowerMask      { return serdesTPowerMask & 0xffff; }
- (unsigned short) serdesRPowerMask      { return serdesRPowerMask & 0xffff; }
- (unsigned short) lvdsPreemphasisCtlMask { return lvdsPreemphasisCtlMask; }
- (unsigned short) miscCtl1Reg           { return miscCtl1Reg; }
- (unsigned short) miscStatReg           { return miscStatReg; }
- (unsigned short) linkLruCrlReg         { return linkLruCrlReg; }
- (unsigned short) linkLockedReg         { return linkLockedReg; }
- (BOOL)          clockUsingLLink        { return clockUsingLLink; }


- (void) setClockUsingLLink:(BOOL)aValue
{
    clockUsingLLink = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerClockUsingLLinkChanged object:self];
    
}

- (void) setLinkLockedReg:(unsigned short)aValue
{
    linkLockedReg = aValue & 0x7ff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerLinkLockedRegChanged object:self];
    
}

- (void) setInputLinkMask:(unsigned short)aMask
{
    inputLinkMask = aMask & 0xffff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelInputLinkMaskChanged object:self];
}


- (void) setSerdesTPowerMask:(unsigned short)aMask
{
    serdesTPowerMask = aMask & 0xffff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerSerdesTPowerMaskChanged object:self];
}


- (void) setSerdesRPowerMask:(unsigned short)aMask
{
    serdesRPowerMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerSerdesRPowerMaskChanged object:self];
}

- (void) setLvdsPreemphasisCtlMask:(unsigned short)aMask
{
    lvdsPreemphasisCtlMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerLvdsPreemphasisCtlMask object:self];
    
}
- (void) setMiscCtl1Reg:(unsigned short)aValue
{
    miscCtl1Reg = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerMiscCtl1RegChanged object:self];
}
- (void) setMiscStatReg:(unsigned short)aValue
{
    miscStatReg = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerMiscStatRegChanged object:self];
    
}
- (void) setLinkLruCrlReg:(unsigned short)aValue
{
    linkLruCrlReg = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerLinkLruCrlRegChanged object:self];
}


- (ORConnector*) linkConnector:(int)index
{
    if(index>=0 && index<9)return linkConnector[index];
    else return nil;
}

- (void) setLink:(int)index connector:(ORConnector*)aConnector
{
    if(index>=0 && index<9){
        [aConnector retain];
        [linkConnector[index] release];
        linkConnector[index] = aConnector;
    }
}

- (BOOL) isMaster
{
    return isMaster;
}

- (void) setIsMaster:(BOOL)aIsMaster
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIsMaster:isMaster];
    
    isMaster = aIsMaster;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelIsMasterChanged object:self];
}
- (int) registerIndex
{
    return registerIndex;
}

- (void) setRegisterIndex:(int)aRegisterIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterIndex:registerIndex];
    registerIndex = aRegisterIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerRegisterIndexChanged object:self];
}

- (unsigned short) regWriteValue
{
    return regWriteValue;
}

- (void) setRegWriteValue:(unsigned short)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegWriteValue:regWriteValue];
    regWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerRegisterWriteValueChanged object:self];
}

- (NSString*) registerNameAt:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return @"";
	return register_information[index].name;
}

- (uint32_t) registerOffsetAt:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return 0;
	return register_information[index].offset;
}

- (unsigned short) readRegister:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return -1;
	if (![self canReadRegister:index]) return -1;
	unsigned short theValue = 0;
    [[self adapter] readWordBlock:&theValue
                        atAddress:[self baseAddress] + register_information[index].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    //NSLog(@"%@ = 0x%04x\n",register_information[index].name,theValue);
    return theValue;
}

- (void) writeRegister:(unsigned int)index withValue:(unsigned short)value
{
	if (index >= kNumberOfGretinaTriggerRegisters) return;
	if (![self canWriteRegister:index]) return;
    if(verbose)NSLog(@"%@ write 0x%04x to 0x%04x (%@)\n",[self isMaster]?@"Master":@"Router",value,register_information[index].offset,register_information[index].name);
    
    [[self adapter] writeWordBlock:&value
                         atAddress:[self baseAddress] + register_information[index].offset
                        numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) setLink:(char)linkName state:(BOOL)aState
{
    if(linkName>='A' && linkName<='U'){
        unsigned short aMask = inputLinkMask;
        int index = (int)(linkName - 'A');
        if(aState)  aMask |= (0x1 << index);
        else        aMask &= ~(0x1 << index);
        [self setInputLinkMask:aMask];
    }
}

- (BOOL) canReadRegister:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return NO;
	return (register_information[index].accessType & kReadOnly) || (register_information[index].accessType & kReadWrite);
}

- (BOOL) canWriteRegister:(unsigned int)index
{
	if (index >= kNumberOfGretinaTriggerRegisters) return NO;
	return (register_information[index].accessType & kWriteOnly) || (register_information[index].accessType & kReadWrite);
}

#pragma mark •••set up routines

- (short) initState {return initializationState;}
- (void) setInitState:(short)aState
{
    if(initializationState!=aState){
        if(initializationState < [stateStatus count]){
            NSMutableDictionary* anEntry = [NSMutableDictionary dictionary];
            if(([self isMaster] && (aState == kMasterError)) || (![self isMaster] && (aState == kRouterError))){
                [anEntry setObject:@"ERROR" forKey:@"status"];
            }
            else [anEntry setObject:@"Done" forKey:@"status"];
            [stateStatus replaceObjectAtIndex:initializationState withObject:anEntry];
        }
    }
    if(aState < [stateStatus count]){
        NSMutableDictionary* anEntry = [NSMutableDictionary dictionary];
        if(([self isMaster] && (aState == kMasterError)) || (![self isMaster] && (aState == kRouterError))){
            [anEntry setObject:@"See Status Log" forKey:@"status"];
        }
        else [anEntry setObject:@"Executing" forKey:@"status"];
        [stateStatus replaceObjectAtIndex:aState withObject:anEntry];
    }
    initializationState = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerModelInitStateChanged object:self];
    
}
- (NSString*) initialStateName
{
    return [self stateName:initializationState];
}

- (NSString*) stateName:(int)anIndex
{
    if([self isMaster]){
        if(anIndex<kNumMasterTriggerStates){
            //double check the array
            if(master_state_info[anIndex].state == anIndex){
                return master_state_info[anIndex].name;
            }
            else {
                NSLogColor([NSColor redColor],@"%@ Programmer Error: Struct entry mismatch: (enum)%d != (struct)%d\n",[self fullID],anIndex,master_state_info[anIndex].state);
                return @"Program Error";
            }
        }
        else {
            return @"";
        }
    }
    else {
        if(anIndex<kNumRouterTriggerStates){
            //double check the array
            if(router_state_info[anIndex].state == anIndex){
                return router_state_info[anIndex].name;
            }
            else {
                NSLogColor([NSColor redColor],@"%@ Programmer Error: Struct entry mismatch: (enum)%d != (struct)%d\n",[self fullID],anIndex,router_state_info[anIndex].state);
                return @"Program Error";
            }
        }
        else return @"";
    }
}

- (void) initClockDistribution
{
    [self initClockDistribution:YES];
}

- (void) initClockDistribution:(BOOL)force
{
    if([self isMaster]){
        if(!force){
            if([self checkSystemLock]){
                NSLog(@"Trigger System appears locked. No need to relock the system.\n");
                return;
            }
        }
        if(!initializationRunning && isMaster){
            [self setupStateArray];
            //a check to make sure we can reach the card
            [self readRegister:kLEDRegister]; //throws if can't reach board
            [self addRunWaitWithReason:@"Wait for Trigger Card Clock Distribution Init"];
            [self setInitState:kMasterSetup];
            connectedRouterMask = 0;
            
            [self setRoutersToIdle]; //init the router state machine

            [self stepMaster];
        }
    }
}

- (void) setRoutersToIdle
{
    int i;
    for(i=0;i<8;i++){
        ORConnector* otherConnector = [linkConnector[i] connector];
        if([otherConnector identifer] == 'L'){
            ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
            [routerObj setupStateArray];
            [routerObj setInitState:kRouterIdle];
        }
    }
}

- (void) setupStateArray
{
    [stateStatus release];
    stateStatus = [[NSMutableArray array] retain];
    int i;
    if([self isMaster]){
        for(i=0;i<kNumMasterTriggerStates;i++){
            NSMutableDictionary* anEntry = [NSMutableDictionary dictionary];
            [anEntry setObject:@"--" forKey:@"status"];
            [stateStatus addObject:anEntry];
        }
    }
    else {
        for(i=0;i<kNumRouterTriggerStates;i++){
            NSMutableDictionary* anEntry = [NSMutableDictionary dictionary];
            [anEntry setObject:@"--" forKey:@"status"];
            [stateStatus addObject:anEntry];
        }      
    }
}

- (NSString*) stateStatus:(int)aStateIndex
{
    if(aStateIndex < [stateStatus count]){
        return [(NSDictionary*)[stateStatus objectAtIndex:aStateIndex] objectForKey:@"status"];
    }
    else return @"";
}

- (void) setToInternalClock
{
    int i;
    if([self isMaster]){
        for(i=0;i<8;i++){
            ORConnector* otherConnector = [linkConnector[i] connector];
            if([otherConnector identifer] == 'L'){
                ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
                [routerObj setToInternalClock];
            }
        }
    }
    else {
        for(i=0;i<8;i++){
            if([linkConnector[i]  identifer] != 'L'){
                id<ORGretinaTriggerProtocol> digitizerObj   = [[linkConnector[i] connector] objectLink];
                if(digitizerObj){
                    [[self undoManager] disableUndoRegistration];
                    [digitizerObj setClockSource:1];
                    [[self undoManager] enableUndoRegistration];

                }
            }
        }
    }
}

- (BOOL) checkSystemLock
{
    BOOL lockState = NO; //assume the worst
    
    int i;
    if([self isMaster]){
        
        routerCount         = 0;
        digitizerCount      = 0;
        digitizerLockCount  = 0;
        
        lockState = [self isLocked]; //the master lock state
        
        //we are the master, so loop over the routers and get their state
        for(i=0;i<8;i++){
            ORConnector* otherConnector = [linkConnector[i] connector];
            if([otherConnector identifer] == 'L'){
                ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
                if(routerObj)routerCount++;
                lockState &= [routerObj isRouterLocked]; //all must be locked to have system lock
                digitizerCount      += [routerObj digitizerCount];
                digitizerLockCount  += [routerObj digitizerLockCount];
            }
        }
    }
    else {
        NSLogColor([NSColor redColor],@"Illegal call. Do not call %@ on a Router card.\n",NSStringFromSelector(_cmd));
        return lockState;
    }
    [self setLocked:lockState];
    [self postCouchDBRecord];
    return lockState;
}

- (BOOL) isRouterLocked
{
    if(![self isMaster]){
        
        BOOL lockState = [self isLocked];
        int i;
        digitizerCount      = 0;
        digitizerLockCount  = 0;
        for(i=0;i<8;i++){
            if([linkConnector[i]  identifer] != 'L'){
                id<ORGretinaTriggerProtocol> digitizerObj   = [[linkConnector[i] connector] objectLink];
                if(digitizerObj){
                    digitizerCount++;
                    BOOL localLocked = [digitizerObj isLocked];
                    lockState &= localLocked;
                    if(localLocked){
                        digitizerLockCount++;
                    }
                }
            }
        }
        [self setLocked:lockState];

        return lockState;
    }
    else {
        NSLogColor([NSColor redColor],@"Illegal call. Do not call %@ on the Master Trigger card.\n",NSStringFromSelector(_cmd));
        return NO;
    }
}

- (void) flushDigitizerFifos
{
    if(![self isMaster]){
        int i;
        for(i=0;i<8;i++){
            if([linkConnector[i]  identifer] != 'L'){
                ORConnector* otherConnector = [linkConnector[i] connector];
                id<ORGretinaTriggerProtocol> digitizerObj = [otherConnector objectLink];
                if(digitizerObj){
                    if(verbose)NSLog(@"Flush Fifo on %@\n",[digitizerObj fullID]);
                    [digitizerObj resetSingleFIFO];
                }
            }
        }
    }
}


- (void) printMasterDiagnosticReport
{
    int i;
    if([self isMaster]){
        for(i=0;i<8;i++){
            ORConnector* otherConnector = [linkConnector[i] connector];
            if([otherConnector identifer] == 'L'){
                ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
                [routerObj printRouterDiagnosticReport];
            }
        }
        [self dumpRegisters];
    }
    else {
        NSLogColor([NSColor redColor],@"Illegal call. Do not call %@ on a Router card.\n",NSStringFromSelector(_cmd));
    }
}

- (void) printRouterDiagnosticReport
{
    if(![self isMaster]){
        int i;
        for(i=0;i<8;i++){
            if([linkConnector[i]  identifer] != 'L'){
                id<ORGretinaTriggerProtocol> digitizerObj   = [[linkConnector[i] connector] objectLink];
                if(digitizerObj){
                    if(![digitizerObj isLocked]){
                        NSLogColor([NSColor redColor],@"%@: NOT Locked.\n",[digitizerObj fullID]);
                    }
                    else {
                        NSLog(@"%@: Locked.\n",[digitizerObj fullID]);
                    }
                }
            }
        }
        [self dumpRegisters];
    }
    else {
        NSLogColor([NSColor redColor],@"Illegal call. Do not call %@ on the Master Trigger card.\n",NSStringFromSelector(_cmd));
    }
}



- (BOOL) isLocked
{
    [self setMiscStatReg:       [self readRegister:kMiscStatus]];
    BOOL lockState = (miscStatReg & 0x4000) == kAllLockBit;
    return lockState;
}

- (BOOL) locked
{
    return locked;
}

- (void) setLocked:(BOOL)aNewState
{
    if(locked!=aNewState){
        
        locked = aNewState;
        
        [self shipDataRecord];

        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerLockChanged object: self];
    }
}

- (void) checkForLostLinkCondition
{
    if([self isMaster]){
        //current link state
        if(locked){
            wasLocked     = YES;
            linkLostCount = 0;
            return;
        }
        else {
            //not locked now, was it locked before?
            if(wasLocked)linkLostCount++;
        }
    
        if(linkLostCount == 2){ //we just want to do the following once....
            wasLocked = NO;
            [self postLinkLostAlarm];
            NSLogColor([NSColor redColor],@"%@: Trigger card was locked but lock was lost for TWO check cycles.\n",[self fullID]);
            [self printMasterDiagnosticReport];
            
            if([gOrcaGlobals runInProgress]){
                [self shipDataRecord];
                
                NSArray*  runModelObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
                ORRunModel* aRunModel = [runModelObjects objectAtIndex:0];
                
                NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Clock Lock Lost",@"Reason",@"Master Trigger card reported lost lock",@"Details",nil];
                if([aRunModel quickStart])doLockRecoveryInQuckStart = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:ORRequestRunRestart
                                                                    object:self
                                                                  userInfo:userInfo];
            }
        }
    }
}

- (void) postLinkLostAlarm
{
    if(!linkLostAlarm){
        linkLostAlarm = [[ORAlarm alloc] initWithName:@"Clock Lock Lost" severity:kImportantAlarm];
        [linkLostAlarm setSticky:NO];
        [linkLostAlarm setHelpString:@"The trigger card clock was locked, but lost was lost. This alarm will go away if you acknowledge it."];
    }
    [linkLostAlarm setAcknowledged:NO];
    [linkLostAlarm postAlarm];

}

- (void) readDisplayRegs
{
    [self setLinkLockedReg:     [self readRegister:kLinkLocked]];
    [self setMiscStatReg:       [self readRegister:kMiscStatus]];
    [self setMiscCtl1Reg:       [self readRegister:kMiscCtl1]];
    [self setLinkLruCrlReg:     [self readRegister:kLinkLruCrl]];
    [self setInputLinkMask:     [self readRegister:kInputLinkMask]];
    [self setSerdesTPowerMask:  [self readRegister:kSerdesTPower]];
    [self setSerdesRPowerMask:  [self readRegister:kSerdesRPower]];
    [self setLvdsPreemphasisCtlMask:[self readRegister:kLvdsPreEmphasis]];
    [self readTimeStamps];
}

- (int) initializationState
{
    return initializationState;
}

- (void) stepMaster
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stepMaster) object:nil];
    
    unsigned short masterPreMask = 0;
    if(verbose) NSLog(@"\n");
    if(verbose) NSLog(@"%@ Running Step: %@\n",[self isMaster]?@"Master":@"Router",[self initialStateName]);

    [self readDisplayRegs]; //read a few registers that we will use repeatedly and display

    int i;
    unsigned short aValue;
    switch(initializationState){
            
        case kMasterSetup:
            tryNumber++;
            connectedRouterMask = [self findRouterMask];
            if(connectedRouterMask==0){
                [self setErrorString:[NSString stringWithFormat:@"HW Error. Tried to initialize %@ for clock distribution but it is not connected to any routers",[self fullID]]];
                [self setInitState:kMasterError];
            }
            else {
                [self writeRegister:kInputLinkMask withValue:~connectedRouterMask]; //A set bit disables a channel

                [self writeRegister:kMiscCtl1 withValue:0xFFC4];
                [self writeRegister:kLinkLruCrl withValue:0x0888];
                
                for(i=0;i<8;i++){
                    ORConnector* otherConnector = [linkConnector[i] connector];
                    if([otherConnector identifer] == 'L'){
                        ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
                        [routerObj setInitState:kRouterSetup];
                        [routerObj stepRouter];
                    }
                }
                
                [self setInitState:kWaitOnRouterSetup];
            }
            break;
            
        case kWaitOnRouterSetup:
            if([self allRoutersIdle]){
                [self setInitState:kSetInputLinkMask];
            }
            break;
            
        case kSetInputLinkMask: //Mask out all unused channels
            [self writeRegister:kInputLinkMask withValue:~connectedRouterMask]; //A set bit disables a channel
            [self setInputLinkMask:  [self readRegister:kInputLinkMask]];       //read it back for display
            [self setInitState:kSetMasterTRPower];
            break;
            
        case kSetMasterTRPower: //Set the matching bit in the serdes tpower and rpower registers
            [self writeRegister:kSerdesTPower withValue:connectedRouterMask];
            [self writeRegister:kSerdesRPower withValue:connectedRouterMask];
            [self setSerdesTPowerMask:[self readRegister:kSerdesTPower]]; //read it back for display
            [self setSerdesRPowerMask:[self readRegister:kSerdesRPower]]; //read it back for display
            [self setInitState:kSetMasterPreEmphCtrl];
            break;
            
        case kSetMasterPreEmphCtrl: //Turn on the driver enable bits for the used channels
            if(connectedRouterMask & 0xf)    masterPreMask |= 0x151; //Links A,B,C,D
            if(connectedRouterMask & 0x70)   masterPreMask |= 0x152; //Links E,F,G
            if(connectedRouterMask & 0x780)  masterPreMask |= 0x154; //Links H,L,R,U
            [self writeRegister:kLvdsPreEmphasis withValue:masterPreMask];
            [self setLvdsPreemphasisCtlMask:[self readRegister:kLvdsPreEmphasis]]; //read it back for display
            [self setInitState:kReleaseLinkInit];
            break;
            
        case kReleaseLinkInit: //Release the link-init machine by clearing the reset bit in the misc-ctl register
            [self writeRegister:kMiscCtl1 withValue:[self readRegister:kMiscCtl1] & ~kResetLinkInitMachBit];
            [self setInitState:kCheckMiscStatus];
            break;
            
        case kCheckMiscStatus: //verify that we are waiting to lock onto the data stream of the router
            if((([self readRegister:kMiscStatus] & kLinkInitStateMask)>>8) != 0x3){
                [self setErrorString:[NSString stringWithFormat:@"HW issue: Master Trigger %@ not waiting for data stream from Router",[self fullID]]];
                if(verbose)NSLog(@"Misc Status Reg: 0x%04x\n",miscStatReg);
                [self setInitState:kMasterError];
            }
            else {
                if(verbose)NSLog(@"Master Trigger Misc Status (0x%04x) indicates it is waiting to lock on Router data stream.\n",miscStatReg);
                [self setInitState:kStartRouterTRPowerUp];
            }
            break;
            
        case kStartRouterTRPowerUp: // pass control to the routers
            for(i=0;i<8;i++){
                ORConnector* otherConnector = [linkConnector[i] connector];
                if([otherConnector identifer] == 'L'){
                    ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
                    [routerObj setInitState:kSetRouterTRPower];
                    [routerObj stepRouter];
                }
            }
        
            [self setInitState:kWaitOnRouterTRPowerUp];
            break;
            
        case kWaitOnRouterTRPowerUp: //waiting on routers
            if([self allRoutersIdle]){
                [self setInitState:kReadLinkLock];
            }
            break;
            
        case kReadLinkLock://Read Link Locked to verify the SERDES of Master is locked the syn pattern of the Router
            if(linkLockedReg!= (~connectedRouterMask & 0x7FF)) {
                [self setErrorString:@"HW issue: the SERDES of the Master has not locked on to the synchronization pattern from the Router"];
                [self setInitState:kMasterError];
            }
            else {
                if(verbose)NSLog(@"The Link Locked Register of the Master indicates it has locked onto the synchronization pattern of the router\n");
                [self setInitState:kVerifyLinkState];
            }
            
            break;
            
        case kVerifyLinkState: //Verify that the state of the link
            [self setMiscStatReg:       [self readRegister:kMiscStatus]];
            if (((miscStatReg & kLinkInitStateMask)>>8) != 0x4) {
                [self setErrorString:[NSString stringWithFormat:@"HW issue: Master Trigger %@ has not locked on to the synchronization pattern from the Router",[self fullID]]];
                if(verbose)NSLog(@"Misc Status Reg: 0x%04x\n",miscStatReg);
                [self setInitState:kMasterError];
            }
            else if(((miscStatReg & kAllLockBit)>>14) != 0x1) {
                [self setErrorString:[NSString stringWithFormat:@"HW issue: Master Trigger %@ does not have all links locked",[self fullID]]];
                if(verbose)NSLog(@"Misc Status Reg: 0x%04x\n",miscStatReg);
                [self setInitState:kMasterError];
            }
            else {
                if(verbose)NSLog(@"Master Trigger %@ indicates it has locked on to the Router data stream.\n",[self fullID]);
                [self setInitState:kSetClockSource];
            }
            break;
       
        case kSetClockSource: //pass control to the routers
        
            for(i=0;i<8;i++){
                ORConnector* otherConnector = [linkConnector[i] connector];
                if([otherConnector identifer] == 'L'){
                    ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
                    [routerObj setInitState:KSetRouterClockSource];
                    [routerObj stepRouter];
                }
            }
        
            [self setInitState:kWaitOnSetClockSource];
            break;

        case kWaitOnSetClockSource: //wait for routers to finish
            if([self allRoutersIdle]){
                [self setInitState:kCheckWaitAckState];
            }
            break;
            
        case kCheckWaitAckState:  //Check wait ack flag
            [self setMiscStatReg:       [self readRegister:kMiscStatus]];
            if(((miscStatReg & kWaitAcknowledgeStateMask) >> 8) != 0x4) {
                [self setErrorString:[NSString stringWithFormat:@"HW Error: Master Trigger MISC_STAT register %@ indicates that it is not in WAIT_ACK mode", [self fullID]]];
                if(verbose)NSLog(@"Misc Status Reg: 0x%04x\n",miscStatReg);
                [self setInitState:kMasterError];
            }
            else {
               if(verbose) NSLog(@"Master Trigger MISC_STAT_REG %@ indicates that is is in WAIT_ACK mode.\n", [self fullID]);
                [self setInitState:kMasterSetClearAckBit];
            }
            break;
        
        case kMasterSetClearAckBit:
            aValue = [self readRegister:kMiscCtl1];
            [self writeRegister:kMiscCtl1 withValue:aValue | 0x2];
            [self writeRegister:kMiscCtl1 withValue:aValue & ~0x2];
            [self setInitState:kVerifyAckMode];
            break;
            
        case kVerifyAckMode:
            [self setMiscStatReg:       [self readRegister:kMiscStatus]];
            if (((miscStatReg & kAcknowledgedStateMask) >> 8 != 0x5)) {
                [self setErrorString:[NSString stringWithFormat:@"HW Error: Master Trigger MISC_STAT register %@ indicates that it is not in ACKED mode", [self fullID]]];
                if(verbose)NSLog(@"Misc Status Reg: 0x%04x\n",miscStatReg);
                [self setInitState:kMasterError];
            }
            else {
                if(verbose)NSLog(@"Master Trigger MISC_STAT register %@ indicates that it is in ACKED mode.\n", [self fullID]);
                [self setInitState:kSendNormalData];
            }
            break;
            
        case kSendNormalData:
            [self writeRegister:kMiscCtl1 withValue:0xFF40];
            [self setInitState:kRunRouterDataCheck];
            break;
            
        case kRunRouterDataCheck: //pass control to routers to init serdes on the gretina cards
            for(i=0;i<8;i++){
                ORConnector* otherConnector = [linkConnector[i] connector];
                if([otherConnector identifer] == 'L'){
                    ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
                    [routerObj setInitState:kRouterDataChecking];
                    [routerObj stepRouter];
                }
            }
        
            [self setInitState:kWaitOnRouterDataCheck];
            break;
            
        case kWaitOnRouterDataCheck:
            if([self allRoutersIdle]){
                [self setInitState:kFinalCheck];
            }
            break;
            
        case kFinalCheck:
            if([self checkSystemLock]){
                [self setInitState:kReleaseImpSync];
            }
            else {
                [self setInitState:kMasterError];
            }
            break;
                    
        
        case kReleaseImpSync:
            aValue = [self readRegister:kMiscCtl1];
            [self writeRegister:kMiscCtl1 withValue:aValue |= (0x1<<6)]; //ensure the imp sync is high.. clocks held in reset
            [self setInitState:kFinalReset];
            break;

        case kFinalReset:
            if(doLockRecoveryInQuckStart){
                doLockRecoveryInQuckStart = NO;
                //special case -- flush the digitizers
                int i;
                for(i=0;i<8;i++){
                    ORConnector* otherConnector = [linkConnector[i] connector];
                    if([otherConnector identifer] == 'L'){
                        ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
                        [routerObj flushDigitizerFifos];
                    }
                }
            }
            [self resetScaler];
            
            aValue = [self readRegister:kMiscCtl1];
            [self writeRegister:kMiscCtl1 withValue:aValue &= ~(0x1<<6)]; //lower imp sync to start clock
            [self setInitState:kMasterIdle];
            break;
    }
    
    [self readDisplayRegs]; //read a few registers that we will use repeatedly and display
    
    if(initializationState != kMasterError &&
       initializationState != kMasterIdle) {
        [self performSelector:@selector(stepMaster) withObject:nil afterDelay:kTriggerInitDelay];
    }

    if(initializationState == kMasterError){
        if(tryNumber<numTimesToRetry){
            [self setInitState:kMasterSetup];
            [self performSelector:@selector(stepMaster) withObject:nil afterDelay:kTriggerInitDelay];
        }
        else {
            NSLogColor([NSColor redColor],@"%@: It appears Lock was Unsuccessful after %d %@\n",[self fullID],tryNumber,tryNumber>1?@"tries":@"try");
            //there was an error, we must make sure the run doesn't continue to start
            NSString* reason = [NSString stringWithFormat:@"%@ Failed to achieve lock.",[self fullID]];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStartupAbort
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:reason,@"Reason",errorString,@"Details",nil]];
        
            [self releaseRunWait]; //we have to clear this. The above line will have aborted the run start up process.
        }
    }
    else if(initializationState == kMasterIdle){
        //OK, the lock was achieved. The run can continue to start
        NSLog(@"%@: It appears a full lock of all the clocks was successful\n",[self fullID]);
        if(tryNumber>1)NSLog(@"But it took %d tries\n",tryNumber);
        [self releaseRunWait];
    }
}

- (void) resetScaler
{
    if([self isMaster]){
        //reset the scaler
        NSArray* scalers = [[(ORAppDelegate*)[NSApp delegate]document] collectObjectsOfClass:NSClassFromString(@"ORCV830Model")];
        for(id aScaler in scalers){
            [aScaler performSelector:NSSelectorFromString(@"remoteInitBoard")];
        }
    }
}
- (void) resetScalerTimeStamps
{
    if([self isMaster]){
        //reset the scaler
        NSArray* scalers = [[(ORAppDelegate*)[NSApp delegate]document] collectObjectsOfClass:NSClassFromString(@"ORCV830Model")];
        for(id aScaler in scalers){
            [aScaler performSelector:NSSelectorFromString(@"remoteResetCounters")];
        }
    }
    
}
- (BOOL) allRoutersIdle
{
    int i;
    for(i=0;i<8;i++){
        ORConnector* otherConnector = [linkConnector[i] connector];
        if([otherConnector identifer] == 'L'){
            ORGretinaTriggerModel* routerObj = [otherConnector objectLink];
            if([routerObj initState] != kRouterIdle)return NO;
        }
    }
    return YES;
}

- (void) stepRouter
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stepRouter) object:nil];
    
    if(verbose) NSLog(@"\n");
    if(verbose) NSLog(@"%@ Running Step: %@\n",[self isMaster]?@"Master":@"Router",[self initialStateName]);
    //read a few registers that we will use repeatedly and display
    [self readDisplayRegs]; //read a few registers that we will use repeatedly and display
    int i;
    switch(initializationState){
        case kRouterSetup: //force some regs to power up state
            [self writeRegister:kLinkLruCrl withValue:0x0888];
            [self writeRegister:kMiscCtl1   withValue:0xFFC4];
            [self setInitState:kDigitizerSetup];
        break;
            
        case kDigitizerSetup:
            for(i=0;i<8;i++){
                if([linkConnector[i]  identifer] != 'L'){
                    ORConnector* otherConnector = [linkConnector[i] connector];
                    id<ORGretinaTriggerProtocol> digitizerObj = [otherConnector objectLink];
                    if(digitizerObj){
                        if(verbose)NSLog(@"Init Gretina SerDes VMEGP Reg %@\n",[digitizerObj fullID]);
                        [digitizerObj setInitState:kSerDesSetup];
                        [digitizerObj stepSerDesInit];
                    }
                }
            }
            
            [self setInitState:kDigitizerSetupWait];
            
            break;
            
        case kDigitizerSetupWait:
            if([self allGretinaCardsIdle]){
                [self setInitState:kRouterIdle];
            }
            break;

            
        case kSetRouterTRPower://Power up the SerDes TPower and RPower
            
            [self writeRegister:kSerdesTPower withValue:kPowerOnLSerDes];
            [self writeRegister:kSerdesRPower withValue:kPowerOnLSerDes];
             
            [self setSerdesTPowerMask:[self readRegister:kSerdesTPower]]; //read back for display
            [self setSerdesRPowerMask:[self readRegister:kSerdesRPower]]; //read back for display
            
            [self setInitState:SetLLinkDenRenSync];
            break;
            
        case SetLLinkDenRenSync: //Turn on the DEN, REN, and SYNC for Link "L"
            [self writeRegister:kLinkLruCrl withValue:0x887];
            [self setLinkLruCrlReg:[self readRegister:kLinkLruCrl]]; //read back for display
            [self setInitState:kSetRouterPreEmphCtrl];
            break;
            
        case kSetRouterPreEmphCtrl: //PreEmphasis
            [self writeRegister:kLvdsPreEmphasis withValue:0x157];
            [self setLvdsPreemphasisCtlMask:[self readRegister:kLvdsPreEmphasis]]; //read back for display
            [self setInitState:kRouterIdle]; 
            break;
            
        case KSetRouterClockSource:
            [self writeRegister:kMiscClkCrl withValue:0x8007];
            [self setClockUsingLLink:([self readRegister:kMiscClkCrl] & kClockSourceSelectBit)!=0]; //read back for display
            [self setInitState:kRouterIdle];
            break;
            
         case kRouterDataChecking:
            [self writeRegister:kMiscCtl1 withValue:0x14];
            [self setInitState:kMaskUnusedRouterChans];
            break;
                    
       case kMaskUnusedRouterChans:
            connectedDigitizerMask = [self findDigitizerMask];
            if(connectedDigitizerMask == 0) {
                [self setErrorString:@"Rounter is not connected to any digitizers"];
                [self setInitState:kRouterError];
            }
            else {
                [self writeRegister:kInputLinkMask withValue:(~connectedDigitizerMask)];
                //[self writeRegister:kInputLinkMask withValue:0xFC];
                [self setInputLinkMask:[self readRegister:kInputLinkMask]]; // read back for display
                [self setInitState:kSetTRPowerBits];
            }
            break;
            
        case kSetTRPowerBits:
            [self writeRegister:kSerdesTPower withValue:connectedDigitizerMask];
            [self writeRegister:kSerdesRPower withValue:connectedDigitizerMask];
            //[self writeRegister:kSerdesTPower withValue:0x103];
            //[self writeRegister:kSerdesRPower withValue:0x103];
            [self setSerdesRPowerMask:[self readRegister:kSerdesRPower]]; // read back for display
            [self setSerdesTPowerMask:[self readRegister:kSerdesTPower]]; // read back for display
            [self setInitState:kReleaseLintInitReset];
            break;
            
        case kReleaseLintInitReset:
          //  [self writeRegister:kMiscCtl1 withValue:([self readRegister:kMiscCtl1] & ~kResetLinkInitMachBit)];
            [self writeRegister:kMiscCtl1 withValue:0x10];
            [self setInitState:kRunDigitizerInit];
            break;
            
            
        case kRunDigitizerInit:
            for(i=0;i<8;i++){
                if([linkConnector[i]  identifer] != 'L'){
                    ORConnector* otherConnector = [linkConnector[i] connector];
                    id<ORGretinaTriggerProtocol> digitizerObj = [otherConnector objectLink];
                    if(digitizerObj){
                        if(verbose)NSLog(@"Set up Gretina SerDes %@\n",[digitizerObj fullID]);
                        [digitizerObj setInitState:kSetDigitizerClkSrc];
                        [digitizerObj stepSerDesInit];
                    }
                }
            }
            
            [self setInitState:kWaitOnDigitizerInit];
            
            break;
            
        case kWaitOnDigitizerInit:
            if([self allGretinaCardsIdle]){
                [self setInitState:kRouterSetClearAckBit];
            }
            break;
            
            
        case kRouterSetClearAckBit:
            [self writeRegister:kMiscCtl1 withValue:0x12];
            [self writeRegister:kMiscCtl1 withValue:0x10];
            [self setInitState:kRouterIdle];
            break;
    }
    [self readDisplayRegs]; //read a few registers that we will use repeatedly and display
    
    if(initializationState != kRouterIdle){
        [self performSelector:@selector(stepRouter) withObject:nil afterDelay:kTriggerInitDelay];
    }
}

- (BOOL) allGretinaCardsIdle
{
    int i;
    for(i=0;i<8;i++){
        if([linkConnector[i]  identifer] != 'L'){
            ORConnector* otherConnector = [linkConnector[i] connector];
            id<ORGretinaTriggerProtocol> digitizerObj = [otherConnector objectLink];
            if(digitizerObj){
                if([digitizerObj initState] != kSerDesIdle)return NO;
            }
        }
    }
    return YES;
}

- (unsigned short)findRouterMask
{
    unsigned short aMask = 0x0;
    int i;
    for(i=0;i<8;i++){
        ORConnector* otherConnector = [linkConnector[i] connector];
        if([otherConnector identifer] == 'L')aMask |= (0x1<<i);
    }
    return aMask;
}

- (unsigned short)findDigitizerMask
{
    unsigned short aMask = 0x0;
    int i;
    for(i=0;i<9;i++){
        ORConnector* otherConnector = [linkConnector[i] connector];
        if([otherConnector objectLink] != nil) aMask |= (0x1<<i);
    }
    return aMask;
}

#pragma mark •••Hardware Access
- (void) dumpFpgaRegisters
{
    NSLog(@"--------------------------------------\n");
    NSLog(@"Gretina Trigger Card FPGA registers (%@)\n",[self isMaster]?@"Master":@"Router");
    int i;
    for(i=0;i<kTriggerNumberOfFPGARegisters;i++){
        unsigned short theValue;
        [[self adapter] readWordBlock:&theValue
                            atAddress:[self baseAddress] + fpga_register_information[i].offset
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        NSLog(@"0x%08x: 0x%04x %@\n",[self baseAddress] +fpga_register_information[i].offset,theValue,fpga_register_information[i].name);
        
    }
    NSLog(@"--------------------------------------\n");
}

- (void) dumpRegisters
{
    NSLog(@"--------------------------------------\n");
    NSLog(@"Gretina Trigger Card registers (%@)\n",[self isMaster]?@"Master":@"Router");
    int i;
    for(i=0;i<kNumberOfGretinaTriggerRegisters;i++){
        unsigned short theValue;
        [[self adapter] readWordBlock:&theValue
                            atAddress:[self baseAddress] + register_information[i].offset
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        NSLog(@"0x%08x: 0x%04x %@\n",[self baseAddress] +register_information[i].offset,theValue,register_information[i].name);
        
    }
    NSLog(@"--------------------------------------\n");
}


- (void) testSandBoxRegisters
{
    int i;
    for(i=0;i<4;i++){
        [self testSandBoxRegister:kTriggerVMEFPGASandbox1+i];
    }
}

- (void) testSandBoxRegister:(int)anOffset
{
    int errorCount = 0;
    int i;
    unsigned short writeValue = 0 ;
    for(i=0;i<16;i++){

        writeValue = (0x1<<i);
        [[self adapter] writeWordBlock:&writeValue
                            atAddress:[self baseAddress] + fpga_register_information[anOffset].offset
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
        
        unsigned short readValue = 0 ;
        [[self adapter] readWordBlock:&readValue
                            atAddress:[self baseAddress] + fpga_register_information[anOffset].offset
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        
        if((writeValue&0xffff) != readValue){
            NSLog(@"Sandbox Reg 0x%08x error: wrote: 0x%08x read: 0x%08x\n",[self baseAddress] + fpga_register_information[anOffset].offset,writeValue,readValue);
            errorCount++;
        }
    }
    if(!errorCount){
        NSLog(@"Sandbox Reg 0x%08x had no errors\n",[self baseAddress] + fpga_register_information[anOffset].offset);
    }
}


- (uint32_t) baseAddress
{
	return (([self slot]+1)&0x1f)<<20;
}

- (unsigned short) readCodeRevision
{
    unsigned short theValue = 0;
    [[self adapter] readWordBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kCodeRevision].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}

- (unsigned short) readCodeDate
{
    unsigned short theValue = 0;
    [[self adapter] readWordBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kCodeModeDate].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}
- (void) writeToAddress:(uint32_t)anAddress aValue:(unsigned short)aValue
{
    [[self adapter] writeWordBlock:&aValue
                         atAddress:[self baseAddress] + anAddress
                        numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
    
}
- (unsigned short) readFromAddress:(uint32_t)anAddress
{
    unsigned short value = 0;
    [[self adapter] readWordBlock:&value
                        atAddress:[self baseAddress] + anAddress
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return value;
}

- (void) readTimeStamps
{
    timeStampA = [self readRegister:kTimeStampA];
    timeStampB = [self readRegister:kTimeStampB];
    timeStampC = [self readRegister:kTimeStampC];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerTimeStampChanged object:self];

}


- (void) startDownLoadingMainFPGA
{
    {
        if(!progressLock)progressLock = [[NSLock alloc] init];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerFpgaDownProgressChanged object:self];
        
        stopDownLoadingMainFPGA = NO;
        
        //to minimize disruptions to the download thread we'll check and update the progress from the main thread via a timer.
        fpgaDownProgress = 0;
        
        if(![self controllerIsSBC]){
            [self setDownLoadMainFPGAInProgress: YES];
            [self updateDownLoadProgress];
            NSLog(@"GretinaTrigger (%d) beginning firmware load via Mac, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
            [NSThread detachNewThreadSelector:@selector(fpgaDownLoadThread:) toTarget:self withObject:[NSData dataWithContentsOfFile:fpgaFilePath]];
        }
        else {
            if([[[self adapter]sbcLink]isConnected]){
                [self setDownLoadMainFPGAInProgress: YES];
                NSLog(@"GretinaTrigger (%d) beginning firmware load via SBC, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
                [self copyFirmwareFileToSBC:fpgaFilePath];
            }
            else {
                [self setDownLoadMainFPGAInProgress: NO];
                NSLog(@"GretinaTrigger (%d) unable to load firmware. SBC not connected.\n",[self uniqueIdNumber]);
            }
        }
    }
}
- (void) flashFpgaStatus:(ORSBCLinkJobStatus*) jobStatus
{
    [self setDownLoadMainFPGAInProgress: [jobStatus running]];
    [self setFpgaDownProgress:           [jobStatus progress]];
    NSArray* parts = [[jobStatus message] componentsSeparatedByString:@"$"];
    NSString* stateString   = @"";
    NSString* verboseString = @"";
    if([parts count]>=1)stateString   = [parts objectAtIndex:0];
    if([parts count]>=2)verboseString = [parts objectAtIndex:1];
    [self setProgressStateOnMainThread:  stateString];
    [self setFirmwareStatusString:       verboseString];
	[self updateDownLoadProgress];
    if(![jobStatus running]){
        NSLog(@"GretinaTrigger (%d) firmware load job in SBC finished (%@)\n",[self uniqueIdNumber],[jobStatus finalStatus]?@"Success":@"Failed");
        if([jobStatus finalStatus]){
            // [self checkFirmwareVersion:YES];
        }
    }
    
}
- (void) stopDownLoadingMainFPGA
{
    if(downLoadMainFPGAInProgress){
        if(![self controllerIsSBC]){
            stopDownLoadingMainFPGA = YES;
        }
        else {
            SBC_Packet aPacket;
            aPacket.cmdHeader.destination			= kSBC_Process;//kSBC_Command;//kSBC_Process;
            aPacket.cmdHeader.cmdID					= kSBC_KillJob;
            aPacket.cmdHeader.numberBytesinPayload	= 0;
            
            @try {
                
                //send a kill packet. The response will be a job status record
                [[[self adapter] sbcLink] send:&aPacket receive:&aPacket];
                NSLog(@"Told SBC to stop FPGA load.\n");
                //NSLog(@"Error Code: %s\n",aPacket.message);
                //[NSException raise:@"Xilinx load failed" format:@"%d",errorCode];
                // }
                //else NSLog(@"Looks like success.\n");
            }
            @catch(NSException* localException) {
                NSLog(@"kSBC_KillJob command failed. %@\n",localException);
                [NSException raise:@"kSBC_KillJob command failed" format:@"%@",localException];
            }
            
        }
    }
}
#pragma mark •••Data Records
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    if([self isMaster]){
        [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"GretinaTriggerModel"];
    }
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    if([self isMaster]){
        NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"ORGretinaTriggerDecoder",		@"decoder",
                                     [NSNumber numberWithLong:dataId],  @"dataId",
                                     [NSNumber numberWithBool:NO],      @"variable",
                                     [NSNumber numberWithLong:5],       @"length",
                                     nil];
        [dataDictionary setObject:aDictionary forKey:@"Master"];
    }

    
    return dataDictionary;
}

- (void) shipDataRecord
{
    if([[ORGlobal sharedGlobal] runInProgress]){
        if([self isMaster]){
            time_t	ut_Time;
            time(&ut_Time);

            timeStampA = [self readRegister:kTimeStampA];
            timeStampB = [self readRegister:kTimeStampB];
            timeStampC = [self readRegister:kTimeStampC];
            
            uint32_t data[5];
            data[0] = dataId | 5;                       //Data Id
            data[1] =   locked      << 4   |            //locked
                        linkWasLost << 5   |            //link was lost
                        doNotLock   << 6   |            //do Not Lock option bit
                        ([self uniqueIdNumber]&0xf);    //Location and spare bits
            data[2] = (uint32_t)ut_Time;                          //Mac Unix time
            data[3] = timeStampA;                       //timeStampA (high bits) + 16 bits spare
            data[4] = (timeStampB<<16) | timeStampC;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification
                                                                object:[NSData dataWithBytes:data
                                                                length:sizeof(int32_t)*5]];
        }
	}
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setNumTimesToRetry:   [decoder decodeIntegerForKey:@"numTimesToRetry"]];
    [self setDoNotLock:         [decoder decodeBoolForKey:@"doNotLock"]];
    [self setInputLinkMask:     [decoder decodeIntegerForKey:@"inputLinkMask"]];
    [self setIsMaster:          [decoder decodeBoolForKey:@"isMaster"]];
    int i;
    for(i=0;i<9;i++){
        [self setLink:i connector:[decoder decodeObjectForKey:[NSString stringWithFormat:@"linkConnector%d",i]]];
    }
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:numTimesToRetry  forKey:@"numTimesToRetry"];
    [encoder encodeBool:doNotLock       forKey:@"doNotLock"];
    [encoder encodeInteger:inputLinkMask    forKey:@"inputLinkMask"];
    [encoder encodeBool:isMaster        forKey:@"isMaster"];
    int i;
    for(i=0;i<9;i++){
        [encoder encodeObject:linkConnector[i] forKey:[NSString stringWithFormat:@"linkConnector%d",i]];
    }
}
@end

@implementation ORGretinaTriggerModel (private)
- (void) updateDownLoadProgress
{
	//call only from main thread
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretinaTriggerFpgaDownProgressChanged object:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:(self) selector:@selector(updateDownLoadProgress) object:nil];
	if(downLoadMainFPGAInProgress)[self performSelector:@selector(updateDownLoadProgress) withObject:nil afterDelay:.1];
}

- (void) setFpgaDownProgress:(short)aFpgaDownProgress
{
	[progressLock lock];
    fpgaDownProgress = aFpgaDownProgress;
	[progressLock unlock];
}

- (void) setProgressStateOnMainThread:(NSString*)aState
{
	if(!aState)aState = @"--";
	//this post a notification to the GUI so it must be done on the main thread
	[self performSelectorOnMainThread:@selector(setMainFPGADownLoadState:) withObject:aState waitUntilDone:NO];
}

- (void) fpgaDownLoadThread:(NSData*)dataFromFile
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	@try {
		[dataFromFile retain];
        
		[self setProgressStateOnMainThread:@"Block Erase"];
		if(!stopDownLoadingMainFPGA) [self blockEraseFlash];
		[self setProgressStateOnMainThread:@"Programming"];
		if(!stopDownLoadingMainFPGA) [self programFlashBuffer:dataFromFile];
		[self setProgressStateOnMainThread:@"Verifying"];
        
		if(!stopDownLoadingMainFPGA) {
			if (![self verifyFlashBuffer:dataFromFile]) {
				[NSException raise:@"GretinaTrigger Exception" format:@"Verification of flash failed."];
			}
            else {
                //reload the fpga from flash
                [self writeToAddress:0x900 aValue:kGretinaTriggerResetMainFPGACmd];
                [self writeToAddress:0x900 aValue:kGretinaTriggerReloadMainFPGACmd];
                [self setProgressStateOnMainThread:  @"Finishing$Flash Memory-->FPGA"];
                uint32_t statusRegValue = [self readFromAddress:0x904];
                while(!(statusRegValue & kGretinaTriggerMainFPGAIsLoaded)) {
                    if(stopDownLoadingMainFPGA)return;
                    statusRegValue = [self readFromAddress:0x904];
                }
                NSLog(@"GretinaTrigger(%d): FPGA Load Finished - No Errors\n",[self uniqueIdNumber]);
                
            }
		}
		[self setProgressStateOnMainThread:@"Loading FPGA"];
		if(!stopDownLoadingMainFPGA) [self reloadMainFPGAFromFlash];
        else NSLog(@"GretinaTrigger(%d): FPGA Load Manually Stopped\n",[self uniqueIdNumber]);
		[self setProgressStateOnMainThread:@"--"];
	}
	@catch(NSException* localException) {
		[self setProgressStateOnMainThread:@"Exception"];
	}
	@finally {
		[self performSelectorOnMainThread:@selector(downloadingMainFPGADone) withObject:nil waitUntilDone:NO];
		[dataFromFile release];
	}
	[pool release];
}

- (void) blockEraseFlash
{
	/* We only erase the blocks currently used in the GretinaTrigger specification. */
    [self writeToAddress:0x910 aValue:kGretinaTriggerFlashEnableWrite]; //Enable programming
	[self setFpgaDownProgress:0.];
    uint32_t count = 0;
    uint32_t end = (kGretinaTriggerFlashBlocks / 4) * kGretinaTriggerFlashBlockSize;
    uint32_t addr;
    [self setProgressStateOnMainThread:  @"Block Erase"];
    for (addr = 0; addr < end; addr += kGretinaTriggerFlashBlockSize) {
        
		if(stopDownLoadingMainFPGA)return;
		@try {
            [self setFirmwareStatusString:       [NSString stringWithFormat:@"%u of %d Blocks Erased",count,kGretinaTriggerFlashBufferBytes]];
 			[self setFpgaDownProgress: 100. * (count+1)/(float)kGretinaTriggerUsedFlashBlocks];
            
            [self writeToAddress:0x980 aValue:addr];
            [self writeToAddress:0x98C aValue:kGretinaTriggerFlashBlockEraseCmd];
            [self writeToAddress:0x98C aValue:kGretinaTriggerFlashConfirmCmd];
            uint32_t stat = [self readFromAddress:0x904];
            while (stat & kFlashBusy) {
                if(stopDownLoadingMainFPGA)break;
                stat = [self readFromAddress:0x904];
            }
            count++;
		}
		@catch(NSException* localException) {
			NSLog(@"GretinaTrigger exception erasing flash.\n");
		}
	}
    
	[self setFpgaDownProgress: 100];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	[self setFpgaDownProgress: 0];
}

- (void) programFlashBuffer:(NSData*)theData
{
    uint32_t totalSize = (uint32_t)[theData length];
    
    [self setProgressStateOnMainThread:@"Programming"];
    [self setFirmwareStatusString: [NSString stringWithFormat:@"FPGA File Size %u KB",totalSize/1000]];
    [self setFpgaDownProgress:0.];
    
    [self writeToAddress:0x980 aValue:0x00];
    [self writeToAddress:0x98C aValue:kGretinaTriggerFlashReadArrayCmd];
    
    uint32_t address = 0x0;
    while (address < totalSize ) {
        uint32_t numberBytesToWrite;
        if(totalSize-address >= kGretinaTriggerFlashBufferBytes){
            numberBytesToWrite = kGretinaTriggerFlashBufferBytes; //whole block
        }
        else {
            numberBytesToWrite = totalSize - address; //near eof, so partial block
        }
        
        [self programFlashBufferBlock:theData address:address numberBytes:numberBytesToWrite];
        
        address += numberBytesToWrite;
        if(stopDownLoadingMainFPGA)break;
        
        
        [self setFirmwareStatusString: [NSString stringWithFormat:@"Flashed: %u/%u KB",address/1000,totalSize/1000]];
        
        [self setFpgaDownProgress:100. * address/(float)totalSize];
        
        if(stopDownLoadingMainFPGA)break;
        
    }
    if(stopDownLoadingMainFPGA)return;
    
    [self writeToAddress:0x980 aValue:0x00];
    [self writeToAddress:0x98C aValue:kGretinaTriggerFlashReadArrayCmd];
    [self writeToAddress:0x910 aValue:0x00];
    
    [self setProgressStateOnMainThread:@"Programming"];
}

- (void) programFlashBufferBlock:(NSData*)theData address:(uint32_t)anAddress numberBytes:(uint32_t)aNumber
{
    //issue the set-up command at the starting address
    [self writeToAddress:0x980 aValue:anAddress];
    [self writeToAddress:0x98C aValue:kGretinaTriggerFlashWriteCmd];
    unsigned char* theDataBytes = (unsigned char*)[theData bytes];
    uint32_t statusRegValue;
	while(1) {
        if(stopDownLoadingMainFPGA)return;
		
		// Checking status to make sure that flash is ready
        unsigned short statusRegValue = [self readFromAddress:0x904];
		
		if ( (statusRegValue & kFlashBusy)  == kFlashBusy ) {
            //not ready, so re-issue the set-up command
            [self writeToAddress:0x980 aValue:anAddress];
            [self writeToAddress:0x98C aValue:kGretinaTriggerFlashWriteCmd];
		}
        else break;
	}
    
	//Set the word count. Max is 0xF.
	unsigned short valueToWrite = (aNumber/2) - 1;
    [self writeToAddress:0x98C aValue:valueToWrite];
	
	// Loading all the words in
    /* Load the words into the bufferToWrite */
	unsigned short i;
	for ( i=0; i<aNumber; i+=4 ) {
        uint32_t* lPtr = (uint32_t*)&theDataBytes[anAddress+i];
        [self writeToAddress:0x984 aValue:lPtr[0]];
	}
	
	// Confirm the write
    [self writeToAddress:0x98C aValue:kGretinaTriggerFlashConfirmCmd];
	
    //wait until the buffer is available again
    statusRegValue = [self readFromAddress:0x904];
    while(statusRegValue & kFlashBusy) {
        if(stopDownLoadingMainFPGA)break;
        statusRegValue = [self readFromAddress:0x904];
    }
}

- (BOOL) verifyFlashBuffer:(NSData*)theData
{
    uint32_t totalSize = (uint32_t)[theData length];
    unsigned char* theDataBytes = (unsigned char*)[theData bytes];
    
    [self setProgressStateOnMainThread:@"Verifying"];
    [self setFirmwareStatusString: [NSString stringWithFormat:@"FPGA File Size %u KB",totalSize/1000]];
    [self setFpgaDownProgress:0.];
    
    /* First reset to make sure it is read mode. */
    [self writeToAddress:0x980 aValue:0x0];
    [self writeToAddress:0x98C aValue:kGretinaTriggerFlashReadArrayCmd];
    
    uint32_t errorCount =   0;
    uint32_t address    =   0;
    uint32_t valueToCompare;
    
    while ( address < totalSize ) {
        unsigned short valueToRead = [self readFromAddress:0x984];
        
        /* Now compare to file*/
        if ( address + 3 < totalSize) {
            uint32_t* ptr = (uint32_t*)&theDataBytes[address];
            valueToCompare = ptr[0];
        }
        else {
            //less than four bytes left
            uint32_t numBytes = totalSize - address - 1;
            valueToCompare = 0;
            unsigned short i;
            for ( i=0;i<numBytes;i++) {
                valueToCompare += (((uint32_t)theDataBytes[address]) << i*8) & (0xFF << i*8);
            }
        }
        if ( valueToRead != valueToCompare ) {
            [self setProgressStateOnMainThread:@"Error"];
            [self setFirmwareStatusString: @"Comparision Error"];
            [self setFpgaDownProgress:0.];
            errorCount++;
        }
        
        [self setFirmwareStatusString: [NSString stringWithFormat:@"Verified: %u/%u KB Errors: %u",address/1000,totalSize/1000,errorCount]];
        [self setFpgaDownProgress:100. * address/(float)totalSize];
        
        address += 4;
    }
    if(errorCount==0){
        [self setProgressStateOnMainThread:@"Done"];
        [self setFirmwareStatusString: @"No Errors"];
        [self setFpgaDownProgress:0.];
        return YES;
    }
    else {
        [self setProgressStateOnMainThread:@"Errors"];
        [self setFirmwareStatusString: @"Comparision Errors"];
        
        return NO;
    }
}

- (void) reloadMainFPGAFromFlash
{
    [self writeToAddress:0x090c aValue:0x0002];
    [self writeToAddress:0x090c aValue:0x0000];
    [self writeToAddress:0x090c aValue:0x0001];
    sleep(3);
    NSLog(@"%@ After reset: 0x902 = 0x%04x\n",[self fullID],[self readFromAddress:0x902]);
    [self writeToAddress:0x090c aValue:0x0000];
}

- (void) downloadingMainFPGADone
{
	[fpgaProgrammingThread release];
	fpgaProgrammingThread = nil;
	
	if(!stopDownLoadingMainFPGA) NSLog(@"Programming Complete.\n");
	else						 NSLog(@"Programming manually stopped before done\n");
	[self setDownLoadMainFPGAInProgress: NO];
	
}

- (void) copyFirmwareFileToSBC:(NSString*)firmwarePath
{
    if(!fileQueue){
        fileQueue = [[NSOperationQueue alloc] init];
        [fileQueue setMaxConcurrentOperationCount:1];
        [fileQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    }
    
    fpgaFileMover = [[ORFileMoverOp alloc] init];
    
    [fpgaFileMover setDelegate:self];
    
    [fpgaFileMover setMoveParams:[firmwarePath stringByExpandingTildeInPath]
                              to:kFPGARemotePath
                      remoteHost:[[[self adapter] sbcLink] IPNumber]
                        userName:[[[self adapter] sbcLink] userName]
                        passWord:[[[self adapter] sbcLink] passWord]];
    
    [fpgaFileMover setVerbose:YES];
    [fpgaFileMover doNotMoveFilesToSentFolder];
    [fpgaFileMover setTransferType:eOpUseSCP];
    [fileQueue addOperation:fpgaFileMover];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == fileQueue && [keyPath isEqual:@"operations"]) {
        if([fileQueue operationCount]==0){
        }
    }
}

- (BOOL) controllerIsSBC
{
    //int32_t removeReturn;
    //return NO; //<<----- temp for testing
    if([[self adapter] isKindOfClass:NSClassFromString(@"ORVmecpuModel")])return YES;
    else return NO;
}

- (void) fileMoverIsDone
{
    BOOL transferOK;
    if ([[fpgaFileMover task] terminationStatus] == 0) {
        NSLog(@"Transferred FPGA Code: %@ to %@:%@\n",[fpgaFileMover fileName],[fpgaFileMover remoteHost],kFPGARemotePath);
        transferOK = YES;
    }
    else {
        NSLogColor([NSColor redColor], @"Failed to transfer FPGA Code to %@\n",[fpgaFileMover remoteHost]);
        transferOK = YES;
    }
    
    [fpgaFileMover release];
    fpgaFileMover  = nil;
    
    [self setDownLoadMainFPGAInProgress: NO];
    if(transferOK){
        //the FPGA file is now on the SBC, next step is to start the flash process on the SBC
        [self loadFPGAUsingSBC];
    }
}
- (void) loadFPGAUsingSBC
{
    if([self controllerIsSBC]){
        //if an SBC is available we pass the request to flash the fpga. this assumes the .bin file is already there
        SBC_Packet aPacket;
        aPacket.cmdHeader.destination           = kMJD;
        aPacket.cmdHeader.cmdID                 = kMJDFlashGretinaFPGA;
        aPacket.cmdHeader.numberBytesinPayload	= sizeof(MJDFlashGretinaFPGAStruct);
        
        MJDFlashGretinaFPGAStruct* p = (MJDFlashGretinaFPGAStruct*) aPacket.payload;
        p->baseAddress      = (uint32_t)[self baseAddress];
        @try {
            NSLog(@"GretinaTrigger (%d) launching firmware load job in SBC\n",[self uniqueIdNumber]);
            
            [[[self adapter] sbcLink] send:&aPacket receive:&aPacket];
            
            [[[self adapter] sbcLink] monitorJobFor:self statusSelector:@selector(flashFpgaStatus:)];
            
        }
        @catch(NSException* e){
        }
    }
}

- (void) postCouchDBRecord
{
    if([self isMaster]){
        NSDictionary* values = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:routerCount],        @"routerCount",
                            [NSNumber numberWithInt:digitizerCount],     @"totalDigitizers",
                            [NSNumber numberWithInt:digitizerLockCount], @"numberDigitizersLocked",
                            [NSNumber numberWithInt:[self isLocked]],    @"systemLocked",
                                nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
    }
}
@end
