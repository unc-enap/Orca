//-------------------------------------------------------------------------
//  ORGretina4MModel.m
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
#import "ORGretina4MModel.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"
#import "ORFileMoverOp.h"
#import "MJDCmds.h"
#import "ORRunModel.h"
#import "ORRunningAverageGroup.h"

#define kCurrentFirmwareVersion 0x107
#define kFPGARemotePath @"GretinaFPGA.bin"

NSString* ORGretina4MModelBaselineRestoredDelayChanged = @"ORGretina4MModelBaselineRestoredDelayChanged";
NSString* ORGretina4MModelFirmwareStatusStringChanged = @"ORGretina4MModelFirmwareStatusStringChanged";
NSString* ORGretina4MNoiseWindowChanged         = @"ORGretina4MNoiseWindowChanged";
NSString* ORGretina4MIntegrateTimeChanged		= @"ORGretina4MIntegrateTimeChanged";
NSString* ORGretina4MCollectionTimeChanged      = @"ORGretina4MCollectionTimeChanged";
NSString* ORGretina4MExtTrigLengthChanged       = @"ORGretina4MExtTrigLengthChanged";
NSString* ORGretina4MPileUpWindowChanged        = @"ORGretina4MPileUpWindowChanged";
NSString* ORGretina4MExternalWindowChanged      = @"ORGretina4MExternalWindowChanged";
NSString* ORGretina4MClockSourceChanged         = @"ORGretina4MClockSourceChanged";
NSString* ORGretina4MClockPhaseChanged         = @"ORGretina4MClockPhaseChanged";
NSString* ORGretina4MDownSampleChanged			= @"ORGretina4MDownSampleChanged";
NSString* ORGretina4MRegisterIndexChanged		= @"ORGretina4MRegisterIndexChanged";
NSString* ORGretina4MRegisterWriteValueChanged	= @"ORGretina4MRegisterWriteValueChanged";
NSString* ORGretina4MSPIWriteValueChanged	    = @"ORGretina4MSPIWriteValueChanged";
NSString* ORGretina4MFpgaDownProgressChanged	= @"ORGretina4MFpgaDownProgressChanged";
NSString* ORGretina4MMainFPGADownLoadStateChanged		= @"ORGretina4MMainFPGADownLoadStateChanged";
NSString* ORGretina4MFpgaFilePathChanged				= @"ORGretina4MFpgaFilePathChanged";
NSString* ORGretina4MNoiseFloorIntegrationTimeChanged	= @"ORGretina4MNoiseFloorIntegrationTimeChanged";
NSString* ORGretina4MNoiseFloorOffsetChanged	= @"ORGretina4MNoiseFloorOffsetChanged";
NSString* ORGretina4MRateGroupChangedNotification = @"ORGretina4MRateGroupChangedNotification";
NSString* ORGretina4MModelRAGChanged            = @"ORGretina4MModelRAGChanged";
NSString* ORGretina4MNoiseFloorChanged			= @"ORGretina4MNoiseFloorChanged";
NSString* ORGretina4MFIFOCheckChanged           = @"ORGretina4MFIFOCheckChanged";

NSString* ORGretina4MTrapEnabledChanged         = @"ORGretina4MTrapEnabledChanged";

NSString* ORGretina4MForceFullInitChanged       = @"ORGretina4MForceFullInitChanged";
NSString* ORGretina4MEnabledChanged             = @"ORGretina4MEnabledChanged";
NSString* ORGretina4MPoleZeroEnabledChanged     = @"ORGretina4MPoleZeroEnabledChanged";
NSString* ORGretina4MPoleZeroMultChanged        = @"ORGretina4MPoleZeroMultChanged";
NSString* ORGretina4MPZTraceEnabledChanged      = @"ORGretina4MPZTraceEnabledChanged";
NSString* ORGretina4MBaselineRestoreEnabledChanged = @"ORGretina4MBaselineRestoreEnabledChanged";
NSString* ORGretina4MDebugChanged               = @"ORGretina4MDebugChanged";
NSString* ORGretina4MPileUpChanged              = @"ORGretina4MPileUpChanged";
NSString* ORGretina4MTriggerModeChanged         = @"ORGretina4MTriggerModeChanged";
NSString* ORGretina4MLEDThresholdChanged        = @"ORGretina4MLEDThresholdChanged";
NSString* ORGretina4MMainFPGADownLoadInProgressChanged		= @"ORGretina4MMainFPGADownLoadInProgressChanged";
NSString* ORGretina4MCardInited                 = @"ORGretina4MCardInited";
NSString* ORGretina4MSettingsLock				= @"ORGretina4MSettingsLock";
NSString* ORGretina4MRegisterLock				= @"ORGretina4MRegisterLock";
NSString* ORGretina4MSetEnableStatusChanged     = @"ORGretina4MSetEnableStatusChanged";
NSString* ORGretina4MMrpsrtChanged              = @"ORGretina4MMrpsrtChanged";
NSString* ORGretina4MFtCntChanged               = @"ORGretina4MFtCntChanged";
NSString* ORGretina4MMrpsdvChanged              = @"ORGretina4MMrpsdvChanged";
NSString* ORGretina4MChpsrtChanged              = @"ORGretina4MChpsrtChanged";
NSString* ORGretina4MChpsdvChanged              = @"ORGretina4MChpsdvChanged";
NSString* ORGretina4MPrerecntChanged            = @"ORGretina4MPrerecntChanged";
NSString* ORGretina4MPostrecntChanged           = @"ORGretina4MPostrecntChanged";
NSString* ORGretina4MTpolChanged                = @"ORGretina4MTpolChanged";
NSString* ORGretina4MPresumEnabledChanged       = @"ORGretina4MPresumEnabledChanged";
NSString* ORGretina4ModelTrapThresholdChanged	= @"ORGretina4ModelTrapThresholdChanged";
NSString* ORGretina4MEasySelectedChanged        = @"ORGretina4MEasySelectedChanged";
NSString* ORGretina4MModelHistEMultiplierChanged= @"ORGretina4MModelHistEMultiplierChanged";
NSString* ORGretina4MModelInitStateChanged      = @"ORGretina4MModelInitStateChanged";
NSString* ORGretina4MForceFullInitCardChanged   = @"ORGretina4MForceFullInitCardChanged";
NSString* ORGretina4MDoHwCheckChanged           = @"ORGretina4MDoHwCheckChanged";

NSString* ORGretina4MLockChanged                = @"ORGretina4MLockChanged";
NSString* ORGretina4MModelRateSpiked            = @"ORGretina4MModelRateSpiked";


@interface ORGretina4MModel (private)
- (void) programFlashBuffer:(NSData*)theData;
- (void) programFlashBufferBlock:(NSData*)theData address:(unsigned long)address numberBytes:(unsigned long)numberBytesToWrite;
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
@end


@implementation ORGretina4MModel
#pragma mark •••Static Declarations
//offsets from the base address
typedef struct {
	unsigned long offset;
	NSString* name;
	BOOL canRead;
	BOOL canWrite;
	BOOL hasChannels;
	BOOL displayOnMainGretinaPage;
} Gretina4MRegisterInformation;
	
static Gretina4MRegisterInformation register_information[kNumberOfGretina4MRegisters] = {
    {0x00,  @"Board ID", YES, NO, NO, NO},                         
    {0x04,  @"Programming done", YES, YES, NO, NO},                
    {0x08,  @"External Window",  YES, YES, NO, YES},               
    {0x0C,  @"Pileup Window", YES, YES, NO, YES},                  
    {0x10,  @"Noise Window", YES,YES, NO, YES},
    {0x14,  @"External trigger sliding length", YES, YES, NO, YES},
    {0x18,  @"Collection time", YES, YES, NO, YES},                
    {0x1C,  @"Integration time", YES, YES, NO, YES},               
    {0x20,  @"Hardware Status", YES, YES, NO, NO},  
    {0x24,	@"Data Package user defined data", YES,	YES, NO, NO}, //new for version 102b
    {0x28,	@"Collection time low resolution", YES, YES, NO, NO}, //new for version 102b
    {0x2C,	@"Integration time low resolution", YES, YES, NO, NO}, //new for version 102b
    {0x30,	@"External FIFO monitor", YES, NO, NO, NO}, //new for version 102b
    {0x40,  @"Control/Status", YES, YES, YES, YES},                
    {0x80,  @"LED Threshold", YES, YES, YES, YES},
    {0x100, @"Window Timing", YES, YES, YES, YES},
    {0x140, @"Rising Edge Window", YES, YES, YES, YES},        
    {0x1C0, @"TRAP Threshold", YES, YES, YES, YES},         // undocumented.
    {0x400, @"DAC", YES, YES, NO, NO},
    {0x480, @"Slave Front bus status", YES, YES, NO, NO},          
    {0x484, @"Channel Zero time stamp LSB", YES, YES, NO, NO},     
    {0x488, @"Channel Zero time stamp MSB",  YES, YES, NO, NO}, 
    {0x48C,	@"Central contact time stamp LSB", YES, YES, NO, NO}, //new for version 102b
    {0x490,	@"Central contact time stamp MSB", YES, YES, NO, NO}, //new for version 102b
    {0x494, @"Slave Sync counter", YES, YES, NO, NO}, //new for version 102b
    {0x498, @"Slave Imperative sync counter", YES, YES, NO, NO}, //new for version 102b
    {0x49C, @"Slave Latch status counter", YES, YES, NO, NO}, //new for version 102b
    {0x4A0, @"Slave Header memory validate counter", YES, YES, NO, NO}, //new for version 102b
    {0x4A4,	@"Slave Header memory read slow data counter", YES, YES, NO, NO}, //new for version 102b
    {0x4A8, @"Slave Front end reset and calibration inject counters", YES, YES, NO, NO}, //new for version 102b
    {0x4AC, @"Slave Front Bus Send Box 10 - 1", YES, YES, NO, NO}, //modifed address for version 102b Q: why hasChannels == NO?
    {0x4D4, @"Slave Front bus register 0 - 10", YES, YES, NO, NO}, //Q: why hasChannels == NO?
    {0x500, @"Master Logic Status", YES, YES, NO, NO},             
    {0x504, @"SlowData CCLED timers", YES, YES, NO, NO},           
    {0x508, @"DeltaT155_DeltaT255 (3)", YES, YES, NO, NO},         
    {0x514, @"SnapShot ", YES, YES, NO, NO},                       
    {0x518, @"XTAL ID ", YES, YES, NO, NO},                        
    {0x51C, @"Length of Time to get Hit Pattern", YES, YES, NO, NO},
    {0x520, @"Front Side Bus Register", YES, YES, NO, NO},  //This is a debug register
    {0x524, @"Test digitizer Tx TTCL", YES, YES, NO, NO}, //new for version 102b
    {0x528, @"Test digitizer Rx TTCL", YES, YES, NO, NO}, //new for version 102b
    {0x52C, @"Slave Front Bus send box 10-1", YES, YES, NO, NO}, //new for version 102b
    {0x554, @"FrontBus Registers 0-10", YES, YES, NO, NO}, //modifed address for version 102b     
    {0x580, @"Master logic sync counter", YES, YES, NO, NO}, //new for version 102b
    {0x584, @"Master logic imperative sync counter", YES, YES, NO, NO}, //new for version 102b
    {0x588, @"Master logic latch status counter", YES, YES, NO, NO}, //new for version 102b
    {0x58C, @"Master logic header memory validate counter", YES, YES, NO, NO}, //new for version 102b
    {0x590,	@"Master logic header memory read slow data counter", YES, YES, NO, NO}, //new for version 102b
    {0x594, @"Master logic front end reset and calibration inject counters", YES, YES, NO, NO}, //new for version 102b
    {0x598, @"Master front bus sync counter", YES, YES, NO, NO}, //new for version 102b
    {0x59C, @"Master front bus imperative sync counter", YES, YES, NO, NO}, //new for version 102b
    {0x5A0, @"Master front bus latch status counter", YES, YES, NO, NO}, //new for version 102b
    {0x5A4, @"Master front bus header memory validate counter", YES, YES, NO, NO}, //new for version 102b
    {0x5A8,	@"Master front bus header memory read slow data counter", YES, YES, NO, NO}, //new for version 102b
    {0x5AC, @"Master front bus front end reset and calibration inject counters", YES, YES, NO, NO}, //new for version 102b
    {0x5B0, @"Serdes data package error", YES, YES, NO, NO}, //new for version 102b
    {0x5B4, @"CC_LED enable", YES, YES, NO, NO}, //new for version 102b
    {0x780, @"Debug data buffer address", YES, YES, NO, NO},       
    {0x784, @"Debug data buffer data", YES, YES, NO, NO},          
    {0x788, @"LED flag window", YES, YES, NO, NO},                 
    {0x800, @"Aux io read", YES, YES, NO, NO},                     
    {0x804, @"Aux io write", YES, YES, NO, NO},                    
    {0x808, @"Aux io config", YES, YES, NO, NO},                   
    {0x820, @"FB_Read", YES, YES, NO, NO},                         
    {0x824, @"FB_Write", YES, YES, NO, NO},                        
    {0x828, @"FB_Config", YES, YES, NO, NO},                       
    {0x840, @"SD_Read", YES, YES, NO, NO},                         
    {0x844, @"SD_Write", YES, YES, NO, NO},                        
    {0x848, @"SD_Config", YES, YES, NO, NO},                       
    {0x84C, @"Adc config", YES, YES, NO, NO},                      
    {0x860, @"self trigger enable", YES, YES, NO, NO},             
    {0x864, @"self trigger period", YES, YES, NO, NO},             
    {0x868, @"self trigger count", YES, YES, NO, NO}, 
    {0x870, @"FIFOInterfaceSMReg", YES, YES, NO, NO}, 
    {0x874, @"Test signals register", YES, YES, NO, NO},
};
                                      
static Gretina4MRegisterInformation fpga_register_information[kNumberOfFPGARegisters] = {
    {0x900,	@"Main Digitizer FPGA configuration register", YES, YES, NO, NO},  
    {0x904,	@"Main Digitizer FPGA status register", YES, NO, NO, NO},          
    {0x908,	@"Voltage and Temperature Status", YES, NO, NO, NO},               
    {0x910,	@"General Purpose VME Control Settings", YES, YES, NO, NO},        
    {0x914,	@"VME Timeout Value Register", YES, YES, NO, NO},                  
    {0x920,	@"VME Version/Status", YES, NO, NO, NO},                           
    {0x930,	@"VME FPGA Sandbox Register Block", YES, YES, NO, NO},             
    {0x980,	@"Flash Address", YES, YES, NO, NO},                               
    {0x984,	@"Flash Data with Auto-increment address", YES, YES, NO, NO},      
    {0x988,	@"Flash Data", YES, YES, NO, NO},                                  
    {0x98C,	@"Flash Command Register", YES, YES, NO, NO}                       
};                                                        


#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self initParams];
    [self setAddressModifier:0x09];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [firmwareStatusString release];
    [spiConnector release];
    [linkConnector release];
    [mainFPGADownLoadState release];
    [fpgaFilePath release];
    [waveFormRateGroup release];
    [rateRunningAverages release];
	[fifoFullAlarm clearAlarm];
	[fifoFullAlarm release];
	[progressLock release];
    [fileQueue cancelAllOperations];
    [fileQueue release];
    [super dealloc];
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"Gretina4MCard"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    int chan;
    float y=73;
    float dy=3;
    NSColor* enabledColor  = [NSColor colorWithCalibratedRed:0.4 green:0.7 blue:0.4 alpha:1];
    NSColor* disabledColor = [NSColor clearColor];
    for(chan=0;chan<kNumGretina4MChannels;chan+=2){
        if(enabled[chan])  [enabledColor  set];
        else			  [disabledColor set];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(5,y,4,dy)] fill];
        
        if(enabled[chan+1])[enabledColor  set];
        else			  [disabledColor set];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(9,y,4,dy)] fill];
        y -= dy;
    }
    [i unlockFocus];
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:OROrcaObjectImageChanged
     object:self];
}

- (void) makeMainController
{
    [self linkToController:@"ORGretina4MController"];
}

- (NSString*) helpURL
{
	return @"VME/Gretina4M.html";
}

- (Class) guardianClass
{
	return NSClassFromString(@"ORVme64CrateModel");
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,baseAddress+0x1000+0xffff);
}

- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setSpiConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    
	[spiConnector setConnectorImageType:kSmallDot]; 
	[spiConnector setConnectorType: 'SPIO' ];
	[spiConnector addRestrictedConnectionType: 'SPII' ]; //can only connect to SPI inputs
	[spiConnector setOffColor:[NSColor colorWithCalibratedRed:0 green:.68 blue:.65 alpha:1.]];

    [self setLinkConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    
    [linkConnector setSameGuardianIsOK:YES];
	[linkConnector setConnectorImageType:kSmallDot];
	[linkConnector setConnectorType: 'LNKI' ];
	[linkConnector addRestrictedConnectionType: 'LNKO' ]; //can only connect to Link inputs
	[linkConnector setOffColor:[NSColor colorWithCalibratedRed:1 green:1 blue:.3 alpha:1.]];
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

- (void) positionConnector:(ORConnector*)aConnector
{
    NSRect aFrame = [aConnector localFrame];
    if(aConnector == spiConnector){
        float x =  17 + [self slot] * 16*.62 ;
        float y =  78;
        aFrame.origin = NSMakePoint(x,y);
        [aConnector setLocalFrame:aFrame];
    }
    else if(aConnector == linkConnector){
        float x =  17 + [self slot] * 16*.62 ;
        float y =  100;
        aFrame.origin = NSMakePoint(x,y);
        [aConnector setLocalFrame:aFrame];
    }
}

- (void) disconnect
{
    [spiConnector disconnect];
    [linkConnector disconnect];
    [super disconnect];
}

- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
	
	[super setGuardian:aGuardian];
	
    if(oldGuardian != aGuardian){
        [oldGuardian removeDisplayOf:spiConnector];
        [oldGuardian removeDisplayOf:linkConnector];
    }
	
    [aGuardian assumeDisplayOf:spiConnector];
    [aGuardian assumeDisplayOf:linkConnector];
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [aGuardian positionConnector:spiConnector forCard:self];
    [aGuardian positionConnector:linkConnector forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:spiConnector];
    [aGuardian removeDisplayOf:linkConnector];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:spiConnector];
    [aGuardian assumeDisplayOf:linkConnector];
}

#pragma mark ***Accessors
- (BOOL) doHwCheck
{
    return doHwCheck;
}

- (void) setDoHwCheck:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoHwCheck:doHwCheck];
    doHwCheck = aFlag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MDoHwCheckChanged object:self];
}

- (BOOL) forceFullInitCard
{
    return forceFullInitCard;
}

- (void) setForceFullInitCard:(BOOL)aForceFullInitCard
{
    [[[self undoManager] prepareWithInvocationTarget:self] setForceFullInitCard:forceFullInitCard];
    forceFullInitCard = aForceFullInitCard;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MForceFullInitCardChanged object:self];
}

- (short) histEMultiplier
{
    return histEMultiplier;
}

- (void) setHistEMultiplier:(short)aHistEMultiplier
{
    if(aHistEMultiplier<1)aHistEMultiplier=1;
    else if(aHistEMultiplier>100)aHistEMultiplier = 100;
    [[[self undoManager] prepareWithInvocationTarget:self] setHistEMultiplier:histEMultiplier];
    histEMultiplier = aHistEMultiplier;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MModelHistEMultiplierChanged object:self];
}

- (unsigned short) baselineRestoredDelay
{
    return baselineRestoredDelay;
}

- (void) setBaselineRestoredDelay:(long)aBaselineRestoredDelay
{
    if (aBaselineRestoredDelay < 0) {
        aBaselineRestoredDelay = 0;
    }
    
    if(aBaselineRestoredDelay > 0xFFFF)
        aBaselineRestoredDelay = 0xFFFF;

    [[[self undoManager] prepareWithInvocationTarget:self] setBaselineRestoredDelay:baselineRestoredDelay];
    
    baselineRestoredDelay = aBaselineRestoredDelay;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MModelBaselineRestoredDelayChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MModelFirmwareStatusStringChanged object:self];
}
- (ORConnector*) linkConnector
{
    return linkConnector;
}

- (void) setLinkConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [linkConnector release];
    linkConnector = aConnector;
}

- (short) noiseWindow
{
    return noiseWindow;
}

- (void) setNoiseWindow:(short)aNoiseWindow
{
    if(aNoiseWindow>0x7f) aNoiseWindow = 0x7f;
    else if(aNoiseWindow<0) aNoiseWindow = 0;
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseWindow:noiseWindow];
    
    noiseWindow = aNoiseWindow;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MNoiseWindowChanged object:self];
}

- (short) integrateTime
{
    return integrateTime;
}

- (void) setIntegrateTime:(short)aIntegrateTime
{
    if(aIntegrateTime>0x1ff)
        aIntegrateTime = 0x1ff;
    else if(aIntegrateTime<0)
        aIntegrateTime = 0;
    [[[self undoManager] prepareWithInvocationTarget:self] setIntegrateTime:integrateTime];
    
    integrateTime = aIntegrateTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MIntegrateTimeChanged object:self];
}

- (short) collectionTime
{
    return collectionTime;
}

- (void) setCollectionTime:(short)aCollectionTime
{
    if(aCollectionTime>0x1ff)
        aCollectionTime = 0x1ff;
    else if(aCollectionTime<0)
        aCollectionTime = 0;
    [[[self undoManager] prepareWithInvocationTarget:self] setCollectionTime:collectionTime];
    
    collectionTime = aCollectionTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MCollectionTimeChanged object:self];
}

- (short) extTrigLength
{
    return extTrigLength;
}

- (void) setExtTrigLength:(short)aExtTrigLength
{
    if(aExtTrigLength>0x7ff)aExtTrigLength = 0x7ff;
    else if(aExtTrigLength<0) aExtTrigLength = 0;
    [[[self undoManager] prepareWithInvocationTarget:self] setExtTrigLength:extTrigLength];
    
    extTrigLength = aExtTrigLength;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MExtTrigLengthChanged object:self];
}

- (short) pileUpWindow
{
    return pileUpWindow;
}

- (void) setPileUpWindow:(short)aPileUpWindow
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPileUpWindow:pileUpWindow];
//  This should be masked, but I don't know the max value. -SJM
    if (pileUpWindow<0) {pileUpWindow=0;}
    pileUpWindow = aPileUpWindow;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MPileUpWindowChanged object:self];
}

- (short) externalWindow
{
    return externalWindow;
}

- (void) setExternalWindow:(short)aExternalWindow
{
    if(aExternalWindow>0x7ff) aExternalWindow = 0x7ff;
    else if(aExternalWindow<0) aExternalWindow = 0;
    [[[self undoManager] prepareWithInvocationTarget:self] setExternalWindow:externalWindow];
    
    externalWindow = aExternalWindow;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MExternalWindowChanged object:self];
}

- (short) clockSource
{
    return clockSource;
}

- (void) setClockSource:(short)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = aClockSource;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MClockSourceChanged object:self];
}

- (short) clockPhase
{
    return clockPhase;
}

- (void) setClockPhase:(short)aClockPhase
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockPhase:clockPhase];
    clockPhase = aClockPhase;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MClockPhaseChanged object:self];

}

- (ORConnector*) spiConnector
{
    return spiConnector;
}

- (void) setSpiConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [spiConnector release];
    spiConnector = aConnector;
}

- (short) downSample
{
    return downSample;
}

- (void) setDownSample:(short)aDownSample
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDownSample:downSample];
    
    downSample = aDownSample;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MDownSampleChanged object:self];
}

- (short) registerIndex
{
    return registerIndex;
}

- (void) setRegisterIndex:(int)aRegisterIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterIndex:registerIndex];
    registerIndex = aRegisterIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MRegisterIndexChanged object:self];
}

- (unsigned long) registerWriteValue
{
    return registerWriteValue;
}

- (void) setRegisterWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterWriteValue:registerWriteValue];
    registerWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MRegisterWriteValueChanged object:self];
}

- (unsigned long) spiWriteValue
{
    return spiWriteValue;
}


- (void) setSPIWriteValue:(unsigned long)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSPIWriteValue:spiWriteValue];
    spiWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MSPIWriteValueChanged object:self];
}

- (NSString*) registerNameAt:(unsigned int)index
{
	if (index >= kNumberOfGretina4MRegisters) return @"";
	return register_information[index].name;
}

- (unsigned short) registerOffsetAt:(unsigned int)index
{
	if (index >= kNumberOfGretina4MRegisters) return 0;
	return register_information[index].offset;
}

- (NSString*) fpgaRegisterNameAt:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return @"";
	return fpga_register_information[index].name;
}

- (unsigned short) fpgaRegisterOffsetAt:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return 0;
	return fpga_register_information[index].offset;
}

- (unsigned long) readRegister:(unsigned int)index
{
	if (index >= kNumberOfGretina4MRegisters) return -1;
	if (![self canReadRegister:index]) return -1;
	unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[index].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}

- (void) writeRegister:(unsigned int)index withValue:(unsigned long)value
{
	if (index >= kNumberOfGretina4MRegisters) return;
	if (![self canWriteRegister:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + register_information[index].offset
                         numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];	
}

- (void) writeToAddress:(unsigned long)anAddress aValue:(unsigned long)aValue
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + anAddress
                        numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
    
}
- (unsigned long) readFromAddress:(unsigned long)anAddress
{
    unsigned long value = 0;
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + anAddress
                        numToRead:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
    return value;
}

- (BOOL) canReadRegister:(unsigned int)index
{
	if (index >= kNumberOfGretina4MRegisters) return NO;
	return register_information[index].canRead;
}

- (BOOL) canWriteRegister:(unsigned int)index
{
	if (index >= kNumberOfGretina4MRegisters) return NO;
	return register_information[index].canWrite;
}

- (BOOL) displayRegisterOnMainPage:(unsigned int)index
{
	if (index >= kNumberOfGretina4MRegisters) return NO;
	return register_information[index].displayOnMainGretinaPage;
}

- (unsigned long) readFPGARegister:(unsigned int)index;
{
	if (index >= kNumberOfFPGARegisters) return -1;
	if (![self canReadFPGARegister:index]) return -1;
	unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + fpga_register_information[index].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}

- (void) writeFPGARegister:(unsigned int)index withValue:(unsigned long)value
{
	if (index >= kNumberOfFPGARegisters) return;
	if (![self canWriteFPGARegister:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + fpga_register_information[index].offset
                         numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];	
}

- (BOOL) canReadFPGARegister:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return NO;
	return fpga_register_information[index].canRead;
}

- (BOOL) canWriteFPGARegister:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return NO;
	return fpga_register_information[index].canWrite;
}

- (BOOL) displayFPGARegisterOnMainPage:(unsigned int)index
{
	if (index >= kNumberOfFPGARegisters) return NO;
	return fpga_register_information[index].displayOnMainGretinaPage;
}

- (BOOL) downLoadMainFPGAInProgress
{
	return downLoadMainFPGAInProgress;
}

- (void) setDownLoadMainFPGAInProgress:(BOOL)aState
{
	downLoadMainFPGAInProgress = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MMainFPGADownLoadInProgressChanged object:self];	
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MMainFPGADownLoadStateChanged object:self];
}

- (NSString*) fpgaFilePath
{
    return fpgaFilePath;
}

- (void) setFpgaFilePath:(NSString*)aFpgaFilePath
{
	if(!aFpgaFilePath)aFpgaFilePath = @"";
    [fpgaFilePath autorelease];
    fpgaFilePath = [aFpgaFilePath copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MFpgaFilePathChanged object:self];
}

- (float) noiseFloorIntegrationTime
{
    return noiseFloorIntegrationTime;
}

- (void) setNoiseFloorIntegrationTime:(float)aNoiseFloorIntegrationTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorIntegrationTime:noiseFloorIntegrationTime];
	
    if(aNoiseFloorIntegrationTime<.01)aNoiseFloorIntegrationTime = .01;
	else if(aNoiseFloorIntegrationTime>5)aNoiseFloorIntegrationTime = 5;
	
    noiseFloorIntegrationTime = aNoiseFloorIntegrationTime;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MNoiseFloorIntegrationTimeChanged object:self];
}

- (short) fifoState
{
    return fifoState;
}

- (void) setFifoState:(short)aFifoState
{
    fifoState = aFifoState;
}

- (void) printThresholds
{
    NSLog(@"Thresholds entered in dialog for %@\n",[self fullID]);
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        NSLogFont([NSFont fontWithName:@"Monaco" size:11],@"%d:%6d\n",i,[self trapEnabled:i]?[self trapThreshold:i]:[self ledThreshold:i]);
    }
}

- (short) noiseFloorOffset
{
    return noiseFloorOffset;
}

- (void) setNoiseFloorOffset:(short)aNoiseFloorOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorOffset:noiseFloorOffset];
    
    noiseFloorOffset = aNoiseFloorOffset;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MNoiseFloorOffsetChanged object:self];
}

- (ORRateGroup*) waveFormRateGroup
{
    return waveFormRateGroup;
}

- (void) setWaveFormRateGroup:(ORRateGroup*)newRateGroup
{
    [newRateGroup retain];
    [waveFormRateGroup release];
    waveFormRateGroup = newRateGroup;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORGretina4MRateGroupChangedNotification
	 object:self];    
}

- (ORRunningAverageGroup*) rateRunningAverages
{
    return rateRunningAverages;
}

- (void) setRateRunningAverages:(ORRunningAverageGroup*)newRunningAverageGroup
{
    [newRunningAverageGroup retain];
    [rateRunningAverages release];
    rateRunningAverages = newRunningAverageGroup;
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ORGretina4MModelRAGChanged
     object:self];
}
//-----------------------------------------------------
//----for testing some of the rate spike logic
- (void) fakeASpike:(int) channel started:(BOOL)start
{
    ORRunningAveSpike* aSpike = [[[ORRunningAveSpike alloc] init] autorelease];
    aSpike.spiked       = start;
    aSpike.tag          = channel;
    aSpike.ave          = 2;
    aSpike.spikeValue   = 10;
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:aSpike forKey:@"SpikeObject"];
    NSNotification* aNote  = [NSNotification notificationWithName:ORSpikeStateChangedNotification object:self userInfo:userInfo];
    [self rateSpikeChanged:aNote];

}
//-----------------------------------------------------

- (void) rateSpikeChanged:(NSNotification*)aNote
{
    ORRunningAveSpike* spikeObj = [[aNote userInfo] objectForKey:@"SpikeObject"];
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              spikeObj,@"spikeInfo",
                              [NSNumber numberWithInt:[self crateNumber]],  @"crate",
                              [NSNumber numberWithInt:[self slot]],         @"card",
                              [NSNumber numberWithInt:[spikeObj tag]],      @"channel",
                              nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MModelRateSpiked object:self userInfo:userInfo];
 
    
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self name:ORRunningAverageChangedNotification object:nil];
    
    ORRunningAverageGroup* run_ave=[self rateRunningAverages];
    if(run_ave){
    
        [notifyCenter addObserver : self
                         selector : @selector(rateSpikeChanged:)
                             name : ORSpikeStateChangedNotification
                           object : run_ave];
    }
}

- (id) rateObject:(short)channel{
    return [waveFormRateGroup rateObject:channel];
}

- (BOOL) noiseFloorRunning
{
	return noiseFloorRunning;
}

- (int) nMaxChannels
{
    return kNumGretina4MChannels;
}
- (void) initParams
{
	
	int i;
	for(i=0;i<kNumGretina4MChannels;i++){
		enabled[i]			= YES;
		easySelected[i]		= NO;
		trapEnabled[i]		= NO;
		debug[i]			= NO;
		pileUp[i]			= NO;
		poleZeroEnabled[i]	= NO;
		poleZeroMult[i]	    = 0x600;
        baselineRestoreEnabled[i]= NO;
		pzTraceEnabled[i]	= NO;
		triggerMode[i]		= 0x0;
		ledThreshold[i]		= 0x1FFFF;//spec default: maximum (0x1FFFF)
		mrpsrt[i]           = 0x0;//spec default: 0
		ftCnt[i]            = 252;//spec default: 256
		mrpsdv[i]           = 0x0;//spec default: 0
		chpsrt[i]           = 0x0;//spec default: 0
		chpsdv[i]           = 0x0;//spec default: 0
		prerecnt[i]         = 499;//spec default: 512
		postrecnt[i]        = 530;//spec default: 512
		tpol[i]             = 0x3;//spec default: 0
		presumEnabled[i]    = 0x0;
		trapThreshold[i]	= 0x10;
	}
    
    clockPhase      = 0x0;
    
    noiseWindow     = 0x40;//spec default: 0x40
    externalWindow  = 0x190;//spec default: 0x190
    pileUpWindow    = 0x400;//spec default: 0x400
    extTrigLength   = 0x190;//spec default: 0x190
    collectionTime  = 0x1C2;//spec default: 0x1C2
    integrateTime = 0x1C2;//spec default: 0x1C2
	
    fifoResetCount = 0;
}



- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

#pragma mark ••• Instance count
- (unsigned long) getCounter:(short)counterTag forGroup:(short)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumGretina4MChannels){
			return waveFormCount[counterTag];
		}	
	}
	return 0;
}

- (float) getRate:(short)channel
{
    if(channel>=0 && channel<kNumGretina4MChannels){
        return [[self rateObject:channel] rate]; //the rate
    }
    return 0;
}

#pragma mark •••specific accessors
- (void) setEasySelected:(short)chan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEasySelected:chan withValue:easySelected[chan]];
	easySelected[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MEasySelectedChanged object:self];
}


- (void) setEnabled:(short)chan withValue:(BOOL)aValue
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:chan withValue:enabled[chan]];
	enabled[chan] = aValue;
    [self setUpImage];
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MEnabledChanged object:self userInfo:userInfo];
    [self postAdcInfoProvidingValueChanged];
    
}

- (void) setForceFullInit:(short)chan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setForceFullInit:chan withValue:forceFullInit[chan]];
    forceFullInit[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MForceFullInitChanged object:self userInfo:userInfo];
}


- (void) setTrapEnabled:(short)chan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrapEnabled:chan withValue:trapEnabled[chan]];
	trapEnabled[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MTrapEnabledChanged object:self userInfo:userInfo];
}


- (void) setPoleZeroEnabled:(short)chan withValue:(BOOL)aValue		
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPoleZeroEnabled:chan withValue:poleZeroEnabled[chan]];
	poleZeroEnabled[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MPoleZeroEnabledChanged object:self userInfo:userInfo];
}

- (void) setPoleZeroMultiplier:(short)chan withValue:(short)aValue
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setPoleZeroMultiplier:chan withValue:poleZeroMult[chan]];
	poleZeroMult[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MPoleZeroMultChanged object:self userInfo:userInfo];
}

- (void) setPZTraceEnabled:(short)chan withValue:(BOOL)aValue
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setPZTraceEnabled:chan withValue:pzTraceEnabled[chan]];
	pzTraceEnabled[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MPZTraceEnabledChanged object:self userInfo:userInfo];
}

- (void) setBaselineRestoreEnabled:(short)chan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBaselineRestoreEnabled:chan withValue:baselineRestoreEnabled[chan]];
	baselineRestoreEnabled[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MBaselineRestoreEnabledChanged object:self userInfo:userInfo];
}

- (void) setDebug:(short)chan withValue:(BOOL)aValue
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setDebug:chan withValue:debug[chan]];
	debug[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MDebugChanged object:self userInfo:userInfo];
}

- (void) setPileUp:(short)chan withValue:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPileUp:chan withValue:pileUp[chan]];
	pileUp[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MPileUpChanged object:self userInfo:userInfo];
}

- (void) setTriggerMode:(short)chan withValue:(short)aValue	
{ 
	if(aValue<0) aValue=0;
    else if(aValue>=1)aValue=1;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerMode:chan withValue:triggerMode[chan]];
	triggerMode[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MTriggerModeChanged object:self userInfo:userInfo];
}

- (void) setLEDThreshold:(short)chan withValue:(int)aValue 
{ 
	if(aValue<0) aValue=0;
    else if(aValue>0x1FFFF) aValue = 0x1FFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setLEDThreshold:chan withValue:ledThreshold[chan]];
	ledThreshold[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MLEDThresholdChanged object:self userInfo:userInfo];
	[self postAdcInfoProvidingValueChanged];
}

- (void) setTrapThreshold:(short)chan withValue:(unsigned long)aValue
{
    if(aValue>0xFFFFFF)aValue = 0xFFFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setTrapThreshold:chan withValue:trapThreshold[chan]];
	trapThreshold[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelTrapThresholdChanged object:self userInfo:userInfo];
    [self postAdcInfoProvidingValueChanged];
}


- (void) setMrpsrt:(short)chan withValue:(short)aValue
{
	if(aValue<0)aValue=0;
	else if(aValue>0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setMrpsrt:chan withValue:mrpsrt[chan]];
	mrpsrt[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MMrpsrtChanged object:self userInfo:userInfo];
}

- (void) setChpsdv:(short)chan withValue:(short)aValue
{
	if(aValue<0)aValue=0;
	else if(aValue>0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setChpsdv:chan withValue:chpsdv[chan]];
	chpsdv[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MChpsdvChanged object:self userInfo:userInfo];
}

- (void) setMrpsdv:(short)chan withValue:(short)aValue
{
	if(aValue<0)aValue=0;
	else if(aValue>0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setMrpsdv:chan withValue:mrpsdv[chan]];
	mrpsdv[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MMrpsdvChanged object:self userInfo:userInfo];
}

- (void) setChpsrt:(short)chan withValue:(short)aValue
{
	if(aValue<0)aValue=0;
	else if(aValue>0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setChpsrt:chan withValue:chpsrt[chan]];
	chpsrt[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MChpsrtChanged object:self userInfo:userInfo];
}

- (void) setPrerecnt:(short)chan withValue:(short)aValue
{
	if(aValue<kPreAdjust)aValue=kPreAdjust;
	else if(aValue>0x7ff-kPreAdjust)aValue = 0x7ff-kPreAdjust; //HW = user+13
    [[[self undoManager] prepareWithInvocationTarget:self] setPrerecnt:chan withValue:prerecnt[chan]];
	prerecnt[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MPrerecntChanged object:self userInfo:userInfo];
}

- (void) setPostrecnt:(short)chan withValue:(short)aValue
{
	if(aValue<18)aValue=18;
	else if(aValue>0x7ff+kPostAdjust)aValue = 0x7ff+kPostAdjust; //HW = user-18
    [[[self undoManager] prepareWithInvocationTarget:self] setPostrecnt:chan withValue:postrecnt[chan]];
	postrecnt[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MPostrecntChanged object:self userInfo:userInfo];
}

- (void) setFtCnt:(short)chan withValue:(short)aValue
{
	if(aValue<0)aValue=0;
	else if(aValue>0x7ff-kFtAdjust)aValue = 0x7ff-kFtAdjust; //HW = user + 4
    [[[self undoManager] prepareWithInvocationTarget:self] setFtCnt:chan withValue:ftCnt[chan]];
	ftCnt[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MFtCntChanged object:self userInfo:userInfo];
}

- (int) baseLineLength:(int)chan
{
    return 2018-(postrecnt[chan]+prerecnt[chan]+ftCnt[chan]);
}

- (void) setTpol:(short)chan withValue:(short)aValue
{
	if(aValue<0)aValue=0;
	else if(aValue>0x3)aValue = 0x3;
    [[[self undoManager] prepareWithInvocationTarget:self] setTpol:chan withValue:tpol[chan]];
	tpol[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MTpolChanged object:self userInfo:userInfo];
}

- (void) setPresumEnabled:(short)chan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPresumEnabled:chan withValue:presumEnabled[chan]];
	presumEnabled[chan] = aValue;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MPresumEnabledChanged object:self userInfo:userInfo];
}


- (BOOL) forceFullInit:(short)chan		{ return forceFullInit[chan]; }
- (BOOL) enabled:(short)chan			{ return enabled[chan]; }
- (BOOL) trapEnabled:(short)chan        { return trapEnabled[chan]; }
- (BOOL) poleZeroEnabled:(short)chan	{ return poleZeroEnabled[chan]; }
- (short) poleZeroMult:(short)chan      { return poleZeroMult[chan]; }
- (BOOL) baselineRestoreEnabled:(short)chan	{ return baselineRestoreEnabled[chan]; }
- (BOOL) pzTraceEnabled:(short)chan     { return pzTraceEnabled[chan]; }
- (BOOL) debug:(short)chan              { return debug[chan]; }
- (BOOL) pileUp:(short)chan             { return pileUp[chan];}
- (short) triggerMode:(short)chan		{ return triggerMode[chan];}
- (int) ledThreshold:(short)chan		{ return ledThreshold[chan]; }
- (unsigned long) trapThreshold:(short)chan       { return trapThreshold[chan]; }
- (short) mrpsrt:(short)chan            { return mrpsrt[chan]; }
- (short) ftCnt:(short)chan             { return ftCnt[chan]; }
- (short) mrpsdv:(short)chan            { return mrpsdv[chan]; }
- (short) chpsrt:(short)chan            { return chpsrt[chan]; }
- (short) chpsdv:(short)chan            { return chpsdv[chan]; }
- (short) prerecnt:(short)chan          { return prerecnt[chan]; }
- (short) postrecnt:(short)chan         { return postrecnt[chan]; }
- (short) tpol:(short)chan              { return tpol[chan]; }
- (BOOL) presumEnabled:(short)chan      { return presumEnabled[chan]; }
- (BOOL) easySelected:(short)chan		{ return easySelected[chan]; }


- (float) poleZeroTauConverted:(short)chan  { return poleZeroMult[chan]>0 ? 0.01*pow(2., 23)/poleZeroMult[chan] : 0; } //convert to us
- (float) noiseWindowConverted      { return noiseWindow    * 640./(float)0x40; }		//convert to ¬¨¬µs
- (float) externalWindowConverted	{ return externalWindow * 4/(float)0x190;   }		//convert to ¬¨¬µs
- (float) pileUpWindowConverted     { return pileUpWindow * 10/(float)0x400;  }		//convert to ¬¨¬µs
- (float) BLRDelayConverted         { return baselineRestoredDelay * 10/(float)0x400;  }		//convert to ¬¨¬µs
- (float) extTrigLengthConverted    { return extTrigLength  * 4/(float)0x190;   }		//convert to ¬¨¬µs
- (float) collectionTimeConverted   { return collectionTime * 4.5/(float)0x1C2; }		//convert to ¬¨¬µs
- (float) integrateTimeConverted    { return integrateTime  * 4.5/(float)0x1C2; }		//convert to ¬¨¬µs


- (void) setPoleZeroTauConverted:(short)chan withValue:(float)aValue 
{
    if(aValue > 0) aValue = 0.01*pow(2., 23)/aValue;
	[self setPoleZeroMultiplier:chan withValue:aValue]; 	//us -> raw
}
- (void) setNoiseWindowConverted:(float)aValue      { [self setNoiseWindow:     aValue*0x40/640.]; } //ns -> raw
- (void) setExternalWindowConverted:(float)aValue   { [self setExternalWindow:  aValue*0x190/4.0]; } //us -> raw
- (void) setPileUpWindowConverted:(float)aValue     { [self setPileUpWindow:    aValue*0x400/10.0];  } //us -> raw
- (void) setBLRDelayConverted:(float)aValue         { [self setBaselineRestoredDelay:aValue*0x400/10.0];} //us -> raw
- (void) setExtTrigLengthConverted:(float)aValue    { [self setExtTrigLength:   aValue*0x190/4.0];  } //us -> raw
- (void) setCollectionTimeConverted:(float)aValue   { [self setCollectionTime:  aValue*0x1C2/4.5]; } //us -> raw
- (void) setIntegrateTimeConverted:(float)aValue    { [self setIntegrateTime:   aValue*0x1C2/4.5];  } //us -> raw

#pragma mark •••Hardware Access
- (unsigned long) baseAddress
{
	return (([self slot]+1)&0x1f)<<20;
}

- (void) readFPGAVersions
{
    //find out the VME FPGA version
	unsigned long vmeVersion = 0x00;
	[[self adapter] readLongBlock:&vmeVersion
                        atAddress:[self baseAddress] + fpga_register_information[kVMEFPGAVersionStatus].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
	NSLog(@"VME FPGA serial number: 0x%x \n", (vmeVersion & 0x0000FFFF));
	NSLog(@"BOARD Revision number: 0x%x \n", ((vmeVersion & 0x00FF0000) >> 16));
	NSLog(@"VME FPGA Version number: 0x%x \n", ((vmeVersion & 0xFF000000) >> 24));
}

- (short) readBoardID
{
    unsigned long theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kBoardID].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue & 0xfff;
}

- (void) testRead
{
    unsigned long theValue1 = 0;
    unsigned long theValue2 = 0;
    unsigned long theValue3 = 0;
    
    id myAdapter = [self adapter];
    [myAdapter readLongBlock:&theValue1
                        atAddress:[self baseAddress] + register_information[kBoardID].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];

    [myAdapter readLongBlock:&theValue2
                   atAddress:0x8610
                   numToRead:1
                  withAddMod:0x29
               usingAddSpace:0x01];
    
    [myAdapter readLongBlock:&theValue3
                   atAddress:0x8610
                   numToRead:1
                  withAddMod:0x29
               usingAddSpace:0x01];
    NSLog(@"Gretina: 0x%0x   Shaper1: 0x%0x   Shaper2: 0x%0x\n",theValue1,theValue2,theValue3);
}
- (void) testReadHV
{
    unsigned long theValue1 = 0;
    unsigned long theValue2 = 0;
    unsigned long theValue3 = 0;
    
    id myAdapter = [self adapter];
    [myAdapter readLongBlock:&theValue1
                   atAddress:[self baseAddress] + register_information[kBoardID].offset
                   numToRead:1
                  withAddMod:[self addressModifier]
               usingAddSpace:0x01];
    
    [myAdapter readLongBlock:&theValue2
                   atAddress:0xDD00
                   numToRead:1
                  withAddMod:0x29
               usingAddSpace:0x01];
    
    [myAdapter readLongBlock:&theValue3
                   atAddress:0xDD00
                   numToRead:1
                  withAddMod:0x29
               usingAddSpace:0x01];
    NSLog(@"Gretina: 0x%0x   HV1: 0x%0x   HV2: 0x%0x\n",theValue1,theValue2,theValue3);
}


- (void) resetClock
{
    
	// To reset the DCM, assert bit 9 of this register. 
	unsigned long theValue;
    [[self adapter] readLongBlock:&theValue
						 atAddress:[self baseAddress] + register_information[kSDConfig].offset
                        numToRead:1
                        withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
    theValue ^= (0x1<<9);

	[[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + register_information[kSDConfig].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	sleep(1);
    theValue ^= (0x1<<9);
	[[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + register_information[kSDConfig].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) resetBoard
{
    /* First disable all channels. This does not affect the model state,
	 just the board state. */
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        [self writeControlReg:i enabled:NO];
    }
    
    [self resetFIFO];
    [self resetMainFPGA];
    [ORTimer delay:6];  // 6 second delay during board reset    
}

- (short) initState {return initializationState;}
- (void) setInitState:(short)aState
{
    initializationState = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MModelInitStateChanged object:self];
}

- (void) stepSerDesInit
{
    switch(initializationState){
        case kSerDesSetup:
            [self writeRegister:kMasterLogicStatus  withValue: 0x00000051]; //power up value
            [self writeRegister:kSDConfig           withValue: 0x00001231]; //T/R SerDes off, reset clock manager, reset clocks
            [self setInitState:kSerDesIdle];
            break;
        
        case kSetDigitizerClkSrc:
            [[self undoManager] disableUndoRegistration];
            [self setClockSource:0];                                //set to external clock (gui only!!!)
            [[self undoManager] enableUndoRegistration];
            [self writeFPGARegister:kVMEGPControl   withValue:0x00 ]; //set to external clock (in HW)
            [self setInitState:kFlushFifo];
            
            break;
            
        case kFlushFifo:
           // for(i=0;i<kNumGretina4MChannels;i++){
            //    [self writeControlReg:i enabled:NO];
           // }
            
            //[self resetFIFO];
            [self setInitState:kReleaseClkManager];
            break;
            
        case kReleaseClkManager:
            //SERDES still disabled, release clk manager, clocks still held at reset
            [self writeRegister:kSDConfig           withValue: 0x00000211];
            [self setInitState:kPowerUpRTPower];
            break;
            
        case kPowerUpRTPower:
            //SERDES enabled, clocks still held at reset
            [self writeRegister:kSDConfig           withValue: 0x00000200];
            [self setInitState:kSetMasterLogic];
            break;
            
        case kSetMasterLogic:
            [self writeRegister:kMasterLogicStatus  withValue: 0x00000051]; //power up value
            [self setInitState:kSetSDSyncBit];
            break;
            
        case kSetSDSyncBit:
            [self writeRegister:kSDConfig           withValue: 0x00000000]; //release the clocks
            [self writeRegister:kSDConfig           withValue: 0x00000020]; //set sd syn

            [self setInitState:kSerDesIdle];
            break;
            
        case kSerDesError:
            break;
    }
    if(initializationState!= kSerDesError && initializationState!= kSerDesIdle){
       [self performSelector:@selector(stepSerDesInit) withObject:nil afterDelay:.01];
    }
}

- (BOOL) isLocked
{
    BOOL lockedBitSet   = ([self readRegister:kMasterLogicStatus] & kSDLockBit)==kSDLockBit;
    //BOOL lostLockBitSet = ([self readRegister:kSDLostLockBit] & kSDLostLockBit)==kSDLostLockBit;
    [self setLocked: lockedBitSet]; //& !lostLockBitSet];
    return [self locked];
}

- (BOOL) locked
{
    return locked;
}

- (void) setLocked:(BOOL)aState
{
    locked = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MLockChanged object: self];
}

- (NSString*) serDesStateName
{
    switch(initializationState){    
        case kSerDesIdle:           return @"Idle";
        case kSerDesSetup:          return @"Reset to power up state";
        case kSetDigitizerClkSrc:   return @"Set the Clk Source";
        case kFlushFifo:            return @"Flush FIFO";
 
        case kPowerUpRTPower:       return @"Power up T/R Power";
        case kSetMasterLogic:       return @"Write Master Logic = 0x20051";
        case kSetSDSyncBit:         return @"Write SD Sync Bit";
        case kSerDesError:          return @"Error";
        default:                    return @"?";
    }
}

- (void) resetMainFPGA
{
	unsigned long theValue = 0x10;
	[[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + fpga_register_information[kMainFPGAControl].offset
                        numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	sleep(1);
	
	/*
	NSDate* startDate = [NSDate date];
    while(1) {
        // Wait for the SD and DCM to lock 
        [[self adapter] readLongBlock:&theValue
                            atAddress:[self baseAddress] + register_information[kHardwareStatus].offset
                            numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		
        if ((theValue & 0x7) == 0x7) break;
		if([[NSDate date] timeIntervalSinceDate:startDate] > 1) {
			NSLog(@"Initializing SERDES timed out (slot %d). \n",[self slot]);
			return;
		}
    }
	*/
	
	theValue = 0x00;
	[[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + fpga_register_information[kMainFPGAControl].offset
                        numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}



- (BOOL) checkFirmwareVersion
{
    return [self checkFirmwareVersion:NO];
}

- (BOOL) checkFirmwareVersion:(BOOL)verbose
{
	//find out the Main FPGA version
	unsigned long mainVersion = 0x00;
	[[self adapter] readLongBlock:&mainVersion
						atAddress:[self baseAddress] + register_information[kBoardID].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	//mainVersion = (mainVersion & 0xFFFF0000) >> 16;
	mainVersion = (mainVersion & 0xFFFFF000) >> 12;
	if(verbose)NSLog(@"Main FPGA version: 0x%x \n", mainVersion);
    
	if (mainVersion < kCurrentFirmwareVersion){
		NSLog(@"Main FPGA version does not match: 0x%x is required but 0x%x is loaded.\n", kCurrentFirmwareVersion,mainVersion);
		return NO;
	}
    else return YES;
}

- (void) clockManagerReset
{
//    The reset sequence suggested by Thorsten
//    "the reset sequence for the clock managers in the FPGA and the DAQ part of the FPGA.
//    All the write go into register ox848
//    0x1C01
//    0x1801
//    0x1001
//    0x0001
//    We wait about 100ms between each write."

	unsigned long theValues[] = {0x0000, 0x1000, 0x1800, 0x1C00};
    unsigned long aValue;
    [[self adapter] readLongBlock:&aValue
                         atAddress:[self baseAddress] + register_information[kSDConfig].offset
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];

    int i;
    for (i=0; i<4; i++) {
        aValue &= 0xFF; 
        aValue |= theValues[i];
        [[self adapter] writeLongBlock:&aValue
                             atAddress:[self baseAddress] + register_information[kSDConfig].offset
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
        [ORTimer delay:0.1];
    }
}

- (void) writeClockPhase
{
    [self writeClockPhaseWithValue:clockPhase];
}

- (void) writeClockPhaseWithValue:(unsigned long)value
{
//    	unsigned long theValue =
    value &= 0x3;
    
    [self writeAndCheckLong:value
              addressOffset:register_information[kADCConfig].offset
                       mask:0x3
                  reportKey:@"ClockPhase"
              forceFullInit:forceFullInitCard];
    [ORTimer delay:0.1];
}

- (BOOL) checkClockPhase:(BOOL)verbose
{
    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + register_information[kADCConfig].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x3) == clockPhase)return YES;
    else {
        if(verbose)NSLog(@"clockPhase mismatch: 0x%x != 0x%x\n",aValue & 0x3,clockPhase);
        return NO;
    }
}

- (unsigned long) readClockPhase
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kADCConfig].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return theValue;
}

- (void) doForcedInitBoard
{
    [self clearOldUserValues];
    [self initBoard];
}

- (void) initBoard
{
    [self initBoard:YES];
}

- (void) initBoard:(BOOL)doChannelEnable
{
    int i;
    if(doChannelEnable){
        for(i=0;i<kNumGretina4MChannels;i++){
            [self writeControlReg:i enabled:NO];
        }
    
        //write the card level params
        [self writeClockSource];
        [self writeClockPhase];
        [self writeExternalWindow];
        [self writePileUpWindow];
        [self writeNoiseWindow];
        [self writeExtTrigLength];
        [self writeCollectionTime];
        [self writeIntegrateTime];
        [self writeDownSample];
        
        //write the channel level params
        for(i=0;i<kNumGretina4MChannels;i++) {
            if([self enabled:i]){
                if([self trapEnabled:i])[self writeTrapThreshold:i];
                else                    [self writeLEDThreshold:i];
                [self writeWindowTiming:i];
                [self writeRisingEdgeWindow:i];
            }
        }
        [self resetFIFO];

        for(i=0;i<kNumGretina4MChannels;i++){
            if([self enabled:i]){
                [self writeControlReg:i enabled:YES];
            }
        }
    }
    if(doHwCheck)[self checkBoard:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MCardInited object:self];
}

- (void) checkBoard:(BOOL)verbose
{
    BOOL clockPhaseResult       = [self checkClockPhase:verbose];
    BOOL externalWindowResult   = [self checkExternalWindow:verbose];
    BOOL pileUpWindowResult     = [self checkPileUpWindow:verbose];
    BOOL noiseWindowResult      = [self checkNoiseWindow:verbose];
    BOOL extTrigLengthResult    = [self checkExtTrigLength:verbose];
    BOOL collectionTimeResult   = [self checkCollectionTime:verbose];
    BOOL integrateTimeResult    = [self checkIntegrateTime:verbose];
    BOOL downSampleResult       = [self checkDownSample:verbose];
    unsigned short controlRegResultMask     = 0xFFFF; //assume all OK
    unsigned short thresholdResultMask      = 0xFFFF; //assume all OK
    unsigned short windowTimingResultMask   = 0xFFFF; //assume all OK
    unsigned short risingEdgeResultMask     = 0xFFFF; //assume all OK
    int i;
    for(i=0;i<kNumGretina4MChannels;i++) {
        if([self enabled:i]){
            if(![self checkControlReg:i verbose:verbose]) controlRegResultMask ^= (0x1<<i);
            if(![self trapEnabled:i])if(![self checkLEDThreshold:i verbose:verbose]) thresholdResultMask ^= (0x1<<i);

    
            if(![self checkWindowTiming:i verbose:verbose])     windowTimingResultMask ^= (0x1<<i);
            if(![self checkRisingEdgeWindow:i verbose:verbose]) risingEdgeResultMask ^= (0x1<<i);
        }
    }
    if(verbose){
        if( clockPhaseResult        &
            externalWindowResult    &
            pileUpWindowResult      &
            noiseWindowResult       &
            extTrigLengthResult     &
            collectionTimeResult    &
            integrateTimeResult     &
            downSampleResult        &
            controlRegResultMask    &
            thresholdResultMask     &
            windowTimingResultMask  &
            risingEdgeResultMask) {
            NSLog(@"%@ HW registers match dialog values\n",[self fullID]);
        }
    }
}



- (unsigned long) readControlReg:(short)channel
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kControlStatus].offset + 4*channel
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return theValue;
}

- (void) writeControlReg:(short)chan enabled:(BOOL)forceEnable
{
    /* writeControlReg writes the current model state to the board.  If forceEnable is NO, *
     * then all the channels are disabled.  Otherwise, the channels are enabled according  *
     * to the model state.                                                                 */
	
    BOOL startStop;
    if(forceEnable)	startStop= enabled[chan];
    else			startStop = NO;
    
    unsigned long theValue = ((baselineRestoreEnabled[chan] & 0x1 ) << 22)  | //the baselinerestorer enable was tied to the polezero enable
                             ((pzTraceEnabled[chan]         & 0x1 ) << 14)  |
                             ((poleZeroEnabled[chan]        & 0x1 ) << 13)  |
                             ((tpol[chan]                   & 0x3 ) << 10)  |
                             ((triggerMode[chan]            & 0x1 ) << 4)   |
							 ((presumEnabled[chan]          & 0x1 ) << 3)   |
							 ((pileUp[chan]                 & 0x1 ) << 2)   |
                             startStop;
    
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kControlStatus].offset + 4*chan
                       mask:0x00406C1D
                  reportKey:[NSString stringWithFormat:@"ControlStatus_%d",chan]
              forceFullInit:forceFullInit[chan]];
}
    
- (BOOL) checkControlReg:(short)chan verbose:(BOOL)verbose
{
    unsigned long checkValue = ((baselineRestoreEnabled[chan] & 0x1 ) << 22)  |
    
        ((pzTraceEnabled[chan]         & 0x1 ) << 14)  |
        ((poleZeroEnabled[chan]        & 0x1 ) << 13)  |
        ((tpol[chan]                   & 0x3 ) << 10)  |
        ((triggerMode[chan]            & 0x1 ) << 4)   |
        ((presumEnabled[chan]          & 0x1 ) << 3)   |
        ((pileUp[chan]                 & 0x1 ) << 2);
    
    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + register_information[kControlStatus].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x0040641C) == checkValue){
        return YES;
    }
    else {
        if(verbose)NSLog(@"control Reg mismatch: 0x%x != 0x%x\n",aValue & 0x0040641C,checkValue);
        return NO;
    }
}

- (short) readClockSource
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + fpga_register_information[kVMEGPControl].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue & 0X3;
}

- (void) writeClockSource: (unsigned long) clocksource
{
    if(clocksource == 0)return; ////temp..... Clock source might be set by the Trigger Card init code.
    [self writeAndCheckLong:clocksource
              addressOffset:fpga_register_information[kVMEGPControl].offset
                       mask:0x3
                  reportKey:@"ClockSource"
              forceFullInit:forceFullInitCard];
}

- (void) writeClockSource
{
    [self writeClockSource:clockSource];
}


- (void) writeNoiseWindow
{
    [self writeAndCheckLong:noiseWindow
              addressOffset:register_information[kNoiseWindow].offset
                       mask:0x7f
                  reportKey:@"NoiseWindow"
              forceFullInit:forceFullInitCard];

}

- (BOOL) checkNoiseWindow:(BOOL)verbose
{
    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + register_information[kNoiseWindow].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x7f) == noiseWindow){
        return YES;
    }
    else {
        if(verbose)NSLog(@"noiseWindow mismatch: 0x%x != 0x%x\n",aValue & 0x7f,noiseWindow);
        return NO;
    }
}

- (void) writeExternalWindow
{
    [self writeAndCheckLong:externalWindow
              addressOffset:register_information[kExternalWindow].offset
                       mask:0x7ff
                  reportKey:@"ExternalWindow"
              forceFullInit:forceFullInitCard];
}

- (BOOL) checkExternalWindow:(BOOL)verbose
{
    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + register_information[kExternalWindow].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x7ff) == externalWindow){
        return YES;
    }
    else {
        if(verbose)NSLog(@"externalWindow mismatch: 0x%x != 0x%x\n",aValue & 0x7ff,externalWindow);
        return NO;
    }
}

- (void) writePileUpWindow
{
    unsigned long theValue = (baselineRestoredDelay<<16) |  pileUpWindow;
 
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kPileupWindow].offset
                       mask:0xffffffff
                  reportKey:@"PileupWindow"
              forceFullInit:forceFullInitCard];
}

- (BOOL) checkPileUpWindow:(BOOL)verbose
{
    unsigned long checkValue = (baselineRestoredDelay<<16) |  pileUpWindow;
    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + register_information[kPileupWindow].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0xffffffff) == checkValue) return YES;
    else {
        if(verbose)NSLog(@"pileUpWindow mismatch: 0x%x != 0x%x\n",aValue & 0xffffffff,checkValue);
        return NO;
    }
}

- (void) writeExtTrigLength
{
    [self writeAndCheckLong:extTrigLength
              addressOffset:register_information[kExtTrigSlidingLength].offset
                       mask:0x7ff
                  reportKey:@"ExtTrigLength"
              forceFullInit:forceFullInitCard];
}

- (BOOL) checkExtTrigLength:(BOOL)verbose
{
    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + register_information[kExtTrigSlidingLength].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x7ff) == extTrigLength) return YES;
    else {
        if(verbose)NSLog(@"extTrigLength mismatch: 0x%x != 0x%x\n",aValue & 0x7ff,extTrigLength);
        return NO;
    }
}


- (void) writeCollectionTime
{
    [self writeAndCheckLong:collectionTime
              addressOffset:register_information[kCollectionTime].offset
                       mask:0x1ff
                  reportKey:@"CollectionTime"
              forceFullInit:forceFullInitCard];

}
- (BOOL) checkCollectionTime:(BOOL)verbose
{
    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + register_information[kCollectionTime].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x1ff) == collectionTime) return YES;
    else {
        if(verbose)NSLog(@"collectionTime mismatch: 0x%x != 0x%x\n",aValue & 0x1ff,collectionTime);
        return NO;
    }
}


- (void) writeIntegrateTime
{
    [self writeAndCheckLong:integrateTime
              addressOffset:register_information[kIntegrateTime].offset
                       mask:0x1ff
                  reportKey:@"IntegrationTime"
              forceFullInit:forceFullInitCard];


}
- (BOOL) checkIntegrateTime:(BOOL)verbose
{
    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + register_information[kIntegrateTime].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x1ff) == integrateTime) return YES;
    else {
        if(verbose)NSLog(@"integrateTime mismatch: 0x%x != 0x%x\n",aValue & 0x1ff,integrateTime);
        return NO;
    }
}

- (void) writeLEDThreshold:(short)channel
{
    unsigned long theValue = (  (poleZeroMult[channel] & 0xFFF) << 20) |
                                (ledThreshold[channel] & 0x1FFFF);
    
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kLEDThreshold].offset + 4*channel
                       mask:0xfff1ffff
                  reportKey:[NSString stringWithFormat:@"LEDThreshold_%d",channel]
              forceFullInit:forceFullInit[channel]];

}

- (BOOL) checkLEDThreshold:(short)channel verbose:(BOOL)verbose
{
    unsigned long checkValue = ((poleZeroMult[channel] & 0xFFF) << 20) |
                                (ledThreshold[channel] & 0x1FFFF);
    
    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] +register_information[kLEDThreshold].offset + 4*channel
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0xfff1ffff) == checkValue) return YES;
    else {
        if(verbose)NSLog(@"channel %d ledThreshold mismatch: 0x%x != 0x%x\n",channel,aValue & 0xfff1ffff,checkValue);
        return NO;
    }
}

- (void) writeTrapThreshold:(int)channel
{
    /* 
        Not in the documenation, but the trap threshold is bits 23:0, at address 0x1C0.
        This seems to work.
     */
    unsigned long theValue =    (trapEnabled[channel] << 31) |
                                (trapThreshold[channel] & 0xFFFFFF);
    
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kTrapThreshold].offset + 4*channel
                       mask:0x80ffffff
                  reportKey:[NSString stringWithFormat:@"TrapThreshold_%d",channel]
              forceFullInit:forceFullInit[channel]];
    
}
- (BOOL) checkTrapThreshold:(short)channel verbose:(BOOL)verbose
{
    unsigned long checkValue =  (trapEnabled[channel] << 31) |
                                (trapThreshold[channel] & 0xFFFFFF);
    
    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] +register_information[kTrapThreshold].offset + 4*channel
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x80ffffff) == checkValue) return YES;
    else {
        if(verbose)NSLog(@"channel %d trapThreshold mismatch: 0x%x != 0x%x\n",channel,aValue & 0x80ffffff,checkValue);
        return NO;
    }
}

- (void) writeWindowTiming:(short)channel
{    
    unsigned long theValue = (((ftCnt[channel]+kFtAdjust)&0x7ff)<<16) |
                             ((mrpsrt[channel]&0xf)<<12) |
                             ((mrpsdv[channel]&0xf)<<8) |
                             ((chpsrt[channel]&0xf)<<4) |
                              (chpsdv[channel] & 0xf);
    
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kWindowTiming].offset + 4*channel
                       mask:0x07ffffff
                  reportKey:[NSString stringWithFormat:@"WindowTiming_%d",channel]
              forceFullInit:forceFullInit[channel]];

}


- (BOOL) checkWindowTiming:(short)channel verbose:(BOOL)verbose
{
    unsigned long checkValue = (((ftCnt[channel]+kFtAdjust)&0x7ff)<<16) |
                                            ((mrpsrt[channel]&0xf)<<12) |
                                            ((mrpsdv[channel]&0xf)<<8)  |
                                            ((chpsrt[channel]&0xf)<<4)  |
                                            (chpsdv[channel] & 0xf);
    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                    atAddress:[self baseAddress] +register_information[kWindowTiming].offset + 4*channel
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x07ffffff) == checkValue) return YES;
    else {
        if(verbose)NSLog(@"channel %d windowTiming mismatch: 0x%x != 0x%x\n",channel,aValue & 0x07ffffff,checkValue);
        return NO;
    }
}


- (void) writeRisingEdgeWindow:(short)channel
{    
	unsigned long theValue = (((prerecnt[channel]+kPreAdjust)&0x7ff)<<12) | (((postrecnt[channel]+kPostAdjust)&0x7ff));
    
    [self writeAndCheckLong:theValue
              addressOffset:register_information[kRisingEdgeWindow].offset + 4*channel
                       mask:0x007ff7ff
                  reportKey:[NSString stringWithFormat:@"RisingEdgeWindow_%d",channel]
              forceFullInit:forceFullInit[channel]];

}
- (BOOL) checkRisingEdgeWindow:(short)channel verbose:(BOOL)verbose
{
    unsigned long checkValue = (((prerecnt[channel]+kPreAdjust)&0x7ff)<<12) | (((postrecnt[channel]+kPostAdjust)&0x7ff));

    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] +register_information[kRisingEdgeWindow].offset + 4*channel
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x007ff7ff) == checkValue) return YES;
    else {
        if(verbose)NSLog(@"channel %d risingEdgeWindow mismatch: 0x%x != 0x%x\n",channel,aValue & 0x007ff7ff,checkValue);
        return NO;
    }
}


- (unsigned short) readFifoState
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if((theValue & kGretina4MFIFOEmpty)!=0)             return kEmpty;
    else if((theValue & kGretina4MFIFOAllFull)!=0)		return kFull;
    else if((theValue & kGretina4MFIFOAlmostFull)!=0)	return kAlmostFull;
    else if((theValue & kGretina4MFIFOAlmostEmpty)!=0)	return kAlmostEmpty;
    else						return kHalfFull;
}

- (void) writeDownSample
{
    unsigned long theValue = ((downSample & 0xF) << 28);
    [self writeAndCheckLong:theValue
              addressOffset:[self baseAddress] + register_information[kProgrammingDone].offset
                       mask:0x70000000
                  reportKey:@"downSample"
              forceFullInit:forceFullInitCard];
}

- (BOOL) checkDownSample:(BOOL)verbose
{
    unsigned long checkValue = ((downSample & 0xF) << 28);
    unsigned long aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x70000000) == checkValue) return YES;
    else {
        if(verbose)NSLog(@"downSample mismatch: 0x%x != 0x%x\n",aValue & 0x70000000,checkValue);
        return NO;
    }
}

- (short) readExternalWindow
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kExternalWindow].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue & 0x7ff;
}

- (short) readNoiseWindow
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kNoiseWindow].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue & 0x7f;
}



- (short) readPileUpWindow
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kPileupWindow].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue & 0xffff;
}

- (short) readExtTrigLength
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kExtTrigSlidingLength].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue & 0x7ff;
}

- (short) readCollectionTime
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kCollectionTime].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue & 0x1ff;
}

- (short) readIntegrateTime
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kIntegrateTime].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue & 0x1ff;
}

- (short) readDownSample
{
    unsigned long theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue >> 28;
}



- (void) resetFIFO
{

    [self resetSingleFIFO];
    [self resetSingleFIFO];

    if(![self fifoIsEmpty]){
        NSLogColor([NSColor redColor], @"%@ Fifo NOT reset properly\n",[self fullID]);
    }
    
}

- (void) resetSingleFIFO
{
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    val |= (0x1<<27);
    
    [[self adapter] writeLongBlock:&val
                         atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    val &= ~(0x1<<27);
    
    [[self adapter] writeLongBlock:&val
                         atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (BOOL) fifoIsEmpty
{
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                       atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                       numToRead:1
                      withAddMod:[self addressModifier]
                   usingAddSpace:0x01];
    
    return ((val>>20) & 0x1); //bit is high if FIFO is empty
}

- (void) findNoiseFloors
{
	if(noiseFloorRunning){
		noiseFloorRunning = NO;
        int i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [self setEnabled:i       withValue:oldEnabled[i]];
            [self setTestThreshold:i withValue:newThreshold[i]];
        }
        [self initBoard];
	}
	else {
		noiseFloorState = 0;
		noiseFloorRunning = YES;
		[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:0];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MNoiseFloorChanged object:self];
}

- (void) setTestThreshold:(short)chan withValue:(int)aValue
{
    if([self trapEnabled:chan]) [self setTrapThreshold:chan withValue:aValue];
    else                        [self setLEDThreshold:chan withValue:aValue];
}

- (unsigned long) testThreshold:(short)chan
{
    if([self trapEnabled:chan]) return [self trapThreshold:chan];
    else                        return [self ledThreshold:chan];
}

- (unsigned long) maxTestThreshold:(short)chan
{
    if([self trapEnabled:chan]) return 0xffffff;
    else                        return 0x01ffff;
}

- (void) writeTestThreshold:(short)chan
{
    if([self trapEnabled:chan]) [self writeTrapThreshold:chan];
    else                        [self writeLEDThreshold:chan];
}

- (void) openPreampDialog
{
    [[[spiConnector connector]objectLink] makeMainController];
}

- (void) stepNoiseFloor
{
	[[self undoManager] disableUndoRegistration];
	
    @try {
		unsigned long val;
        int i;

		switch(noiseFloorState){
			case 0: //init
				//disable all channels
				for(i=0;i<kNumGretina4MChannels;i++){
					oldEnabled[i] = [self enabled:i];
					[self setEnabled:i withValue:NO];
					[self writeControlReg:i enabled:NO];
					oldThreshold[i] = [self testThreshold:i];
                    [self setTestThreshold:i withValue:[self maxTestThreshold:i]];
                    newThreshold[i] = [self testThreshold:i];
				}
				[self initBoard];
				noiseFloorWorkingChannel = -1;
            
				//find first channel
				for(i=0;i<kNumGretina4MChannels;i++){
					if(oldEnabled[i]){
						noiseFloorWorkingChannel = i;
						break;
					}
				}
				if(noiseFloorWorkingChannel>=0){
					noiseFloorLow		= 0;
					noiseFloorHigh		= [self maxTestThreshold:noiseFloorWorkingChannel];
					noiseFloorTestValue	= noiseFloorHigh/2;              //Initial probe position
					[self setTestThreshold:noiseFloorWorkingChannel withValue:noiseFloorHigh];
					[self writeTestThreshold:noiseFloorWorkingChannel];
					[self setEnabled:noiseFloorWorkingChannel withValue:YES];
					[self writeControlReg:noiseFloorWorkingChannel enabled:YES];
					[self resetFIFO];
					noiseFloorState = 1;
				}
				else {
					noiseFloorState = 2; //nothing to do
				}
				break;
				
			case 1:
                if(noiseFloorLow <= noiseFloorHigh) {
					[self setTestThreshold:noiseFloorWorkingChannel withValue:noiseFloorTestValue];
					[self writeTestThreshold:noiseFloorWorkingChannel];
					noiseFloorState = 2;	//go check for data
				}
				else {
					newThreshold[noiseFloorWorkingChannel] = noiseFloorTestValue + noiseFloorOffset;
					[self setEnabled:noiseFloorWorkingChannel withValue:NO];
					[self writeControlReg:noiseFloorWorkingChannel enabled:NO];
					[self setTestThreshold:noiseFloorWorkingChannel withValue:[self maxTestThreshold:noiseFloorWorkingChannel]];
					[self writeTestThreshold:noiseFloorWorkingChannel];
					noiseFloorState = 3;	//done with this channel
				}
				break;
				
			case 2:
				//read the fifo state
				[[self adapter] readLongBlock:&val
									atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
									numToRead:1
								   withAddMod:[self addressModifier]
								usingAddSpace:0x01];
				
				if((val & kGretina4MFIFOEmpty) == 0){
					//there's some data in fifo so we're too low with the threshold
					[self setTestThreshold:noiseFloorWorkingChannel withValue:[self maxTestThreshold:noiseFloorWorkingChannel]];
					[self writeTestThreshold:noiseFloorWorkingChannel];
					[self resetFIFO];
					noiseFloorLow = noiseFloorTestValue + 1;
				}
				else noiseFloorHigh = noiseFloorTestValue - 1;										//no data so continue lowering threshold
				noiseFloorTestValue = noiseFloorLow+((noiseFloorHigh-noiseFloorLow)/2);     //Next probe position.
				noiseFloorState = 1;	//continue with this channel
				break;
				
			case 3:
				//go to next channel
				//find first channel
                noiseFloorLow		= 0;
				int startChan = noiseFloorWorkingChannel+1;
				noiseFloorWorkingChannel = -1;
				for(i=startChan;i<kNumGretina4MChannels;i++){
					if(oldEnabled[i]){
						noiseFloorWorkingChannel = i;
						break;
					}
				}
                noiseFloorHigh		= [self maxTestThreshold:noiseFloorWorkingChannel];
                noiseFloorTestValue	= noiseFloorHigh/2;              //Initial probe position
				if(noiseFloorWorkingChannel >= startChan){
					[self setEnabled:noiseFloorWorkingChannel withValue:YES];
					[self writeControlReg:noiseFloorWorkingChannel enabled:YES];
					noiseFloorState = 1;
				}
				else {
					noiseFloorState = 4;
				}
				break;
				
			case 4: //finish up	
				//load new results
				for(i=0;i<kNumGretina4MChannels;i++){
					[self setEnabled:i       withValue:oldEnabled[i]];
					[self setTestThreshold:i withValue:newThreshold[i]];
				}
				[self initBoard];
               
				noiseFloorRunning = NO;
				break;
		}
		if(noiseFloorRunning){
			[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:noiseFloorIntegrationTime];
		}
		else {
			[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MNoiseFloorChanged object:self];
		}
    }
	@catch(NSException* localException) {
        int i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [self setEnabled:i withValue:oldEnabled[i]];
            [self setTestThreshold:i withValue:oldThreshold[i]];
        }
		NSLog(@"Gretina4M LED threshold finder quit because of exception\n");
    }
	[[self undoManager] enableUndoRegistration];
}

- (void) startDownLoadingMainFPGA
{
	if(!progressLock)progressLock = [[NSLock alloc] init];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MFpgaDownProgressChanged object:self];
	
	stopDownLoadingMainFPGA = NO;
	
	//to minimize disruptions to the download thread we'll check and update the progress from the main thread via a timer.
	fpgaDownProgress = 0;
	
    if(![self controllerIsSBC]){
        [self setDownLoadMainFPGAInProgress: YES];
        [self updateDownLoadProgress];
        NSLog(@"Gretina4M (%d) beginning firmware load via Mac, File: %@\n",[self uniqueIdNumber],fpgaFilePath);

        [NSThread detachNewThreadSelector:@selector(fpgaDownLoadThread:) toTarget:self withObject:[NSData dataWithContentsOfFile:fpgaFilePath]];
    }
    else {
        if([[[self adapter]sbcLink]isConnected]){
            [self setDownLoadMainFPGAInProgress: YES];
            NSLog(@"Gretina4M (%d) beginning firmware load via SBC, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
            [self copyFirmwareFileToSBC:fpgaFilePath];
        }
        else {
            [self setDownLoadMainFPGAInProgress: NO];
            NSLog(@"Gretina4M (%d) unable to load firmware. SBC not connected.\n",[self uniqueIdNumber]);
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
        NSLog(@"Gretina4M (%d) firmware load job in SBC finished (%@)\n",[self uniqueIdNumber],[jobStatus finalStatus]?@"Success":@"Failed");
        if([jobStatus finalStatus]){
            [self readFPGAVersions];
            [self checkFirmwareVersion:YES];
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


#pragma mark •••Data Taker
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORGretina4MWaveformDecoder",             @"decoder",
								 [NSNumber numberWithLong:dataId],        @"dataId",
								 [NSNumber numberWithBool:YES],           @"variable",
								 [NSNumber numberWithLong:-1],			 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Gretina4M"];
    
    return dataDictionary;
}

#pragma mark •••HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}

- (int) numberOfChannels
{
    return kNumGretina4MChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"External Window"];
    [p setFormat:@"##0" upperLimit:0x7ff lowerLimit:0 stepSize:1 units:@"µs"];
    [p setSetMethod:@selector(setExternalWindowConverted:) getMethod:@selector(externalWindowConverted)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Noise Window"];
    [p setFormat:@"##0" upperLimit:0x7 lowerLimit:0 stepSize:1 units:@"µs"];
    [p setSetMethod:@selector(setNoiseWindowConverted:) getMethod:@selector(noiseWindowConverted)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];

    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pileup Window"];
    [p setFormat:@"##0" upperLimit:0x7ff lowerLimit:0 stepSize:1 units:@"µs"];
    [p setSetMethod:@selector(setPileUpWindowConverted:) getMethod:@selector(pileUpWindowConverted)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:0x2 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Phase"];
    [p setFormat:@"##0" upperLimit:0x3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockPhase:) getMethod:@selector(clockPhase)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Ext Trig Length"];
    [p setFormat:@"##0" upperLimit:0x7ff lowerLimit:0 stepSize:1 units:@"µs"];
    [p setSetMethod:@selector(setExtTrigLengthConverted:) getMethod:@selector(extTrigLengthConverted)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Collection Time"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:@"µs"];
    [p setSetMethod:@selector(setCollectionTimeConverted:) getMethod:@selector(collectionTimeConverted)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Integration Time"];
    [p setFormat:@"##0" upperLimit:0x1ff lowerLimit:0 stepSize:1 units:@"µs"];
    [p setSetMethod:@selector(setIntegrateTimeConverted:) getMethod:@selector(integrateTimeConverted)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CC Low Res"];
    [p setFormat:@"##0" upperLimit:0x3ff lowerLimit:0 stepSize:1 units:@""];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Mode"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTriggerMode:withValue:) getMethod:@selector(triggerMode:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pile Up"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setPileUp:withValue:) getMethod:@selector(pileUp:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEnabled:withValue:) getMethod:@selector(enabled:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Force Full Iit"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setForceFullInit:withValue:) getMethod:@selector(forceFullInit:)];
    [a addObject:p];

    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trap Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setTrapEnabled:withValue:) getMethod:@selector(trapEnabled:)];
    [a addObject:p];

    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Debug Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setDebug:withValue:) getMethod:@selector(debug:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"LED Threshold"];
    [p setFormat:@"##0" upperLimit:0x1ffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setLEDThreshold:withValue:) getMethod:@selector(ledThreshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"TRAP Threshold"];
    [p setFormat:@"##0" upperLimit:0xffffff lowerLimit:0 stepSize:1 units:@""];
	[p setCanBeRamped:YES];
    [p setSetMethod:@selector(setTrapThreshold:withValue:) getMethod:@selector(trapThreshold:)];
    [a addObject:p];

    
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Down Sample"];
    [p setFormat:@"##0" upperLimit:4 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setDownSample:) getMethod:@selector(downSample)];
    [a addObject:p];

	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Mrpsrt"];
    [p setFormat:@"##0" upperLimit:0xF lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setMrpsrt:withValue:) getMethod:@selector(mrpsrt:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Mrpsdv"];
    [p setFormat:@"##0" upperLimit:0xF lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setMrpsdv:withValue:) getMethod:@selector(mrpsdv:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"FtCnt"];
    [p setFormat:@"##0" upperLimit:0x3ff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setFtCnt:withValue:) getMethod:@selector(ftCnt:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Chpsrt"];
    [p setFormat:@"##0" upperLimit:0xF lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setChpsrt:withValue:) getMethod:@selector(chpsrt:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Chpsdv"];
    [p setFormat:@"##0" upperLimit:0xF lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setChpsdv:withValue:) getMethod:@selector(chpsdv:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Prerecnt"];
    [p setFormat:@"##0" upperLimit:0x3ff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPrerecnt:withValue:) getMethod:@selector(prerecnt:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Postrecnt"];
    [p setFormat:@"##0" upperLimit:0x3ff lowerLimit:18 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPostrecnt:withValue:) getMethod:@selector(postrecnt:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"TPol"];
    [p setFormat:@"##0" upperLimit:0x3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTpol:withValue:) getMethod:@selector(tpol:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"PreSum Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setPresumEnabled:withValue:) getMethod:@selector(presumEnabled:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Hist E Multiplier"];
    [p setFormat:@"##0" upperLimit:100 lowerLimit:1 stepSize:1 units:@""];
    [p setSetMethod:@selector(setHistEMultiplier:) getMethod:@selector(histEMultiplier)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setOncePerCard:YES];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setOncePerCard:YES];
    [p setName:@"Init (Forced)"];
    [p setSetMethodSelector:@selector(doForcedInitBoard)];
    [a addObject:p];

    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setOncePerCard:YES];
    [p setName:@"Load Thresholds"];
    [p setSetMethodSelector:@selector(loadThresholds)];
    [a addObject:p];
    return a;
}


- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORGretina4MModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORGretina4MModel"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
 	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    
    id obj = [cardDictionary objectForKey:param];
    if(obj)return obj;
    else return [[cardDictionary objectForKey:param] objectAtIndex:aChannel];
}


- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    runNumberLocal     = [[userInfo objectForKey:@"kRunNumber"] unsignedLongValue];
    subRunNumberLocal     = [[userInfo objectForKey:@"kSubRunNumber"] unsignedLongValue];

    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    if(![self checkFirmwareVersion]){
        [NSException raise:@"Wrong Firmware" format:@"You must have firmware version 0x%x installed.",kCurrentFirmwareVersion];
    }

    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORGretina4M"];    

    if(serialNumber==0){
        @try {
            [[self adapter] readLongBlock:&serialNumber
                                atAddress:[self baseAddress] + fpga_register_information[kVMEFPGAVersionStatus].offset
                                numToRead:1
                               withAddMod:[self addressModifier]
                            usingAddSpace:0x01];
            
            serialNumber = serialNumber&0xffff;
        }
        @catch(NSException* e) {
        }
    }
    
    //cache some stuff
    location        = (([self crateNumber]&0xf)<<21) | (([self slot]& 0x1f)<<16) | serialNumber;
    theController   = [self adapter];
    fifoAddress     = [self baseAddress] + 0x1000;
    fifoStateAddress= [self baseAddress] + register_information[kProgrammingDone].offset;
    
    fifoResetCount = 0;
    //NSLog(@"\n\n\n Gretina to start Rates \n\n\n");

    [self startRates];
    
    [self clearDiagnosticsReport];
    
    BOOL doChannelEnable = [[userInfo objectForKey:@"doinit"]boolValue]==1;
    [self initBoard:doChannelEnable];
    if(!doChannelEnable) NSLog(@" %@ Quick Start Enabled. Channels NOT disabled/enabled.\n",[self fullID]);
    
    if([self diagnosticsEnabled])[self briefDiagnosticsReport];
    
	[self performSelector:@selector(checkFifoAlarm) withObject:nil afterDelay:1];
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    isRunning = YES;
    NSString* errorLocation = @"";
    @try {
        if(![self fifoIsEmpty]){
            dataBuffer[0] = dataId | kG4MDataPacketSize;
            dataBuffer[1] = location;
        
            [theController readLong:&dataBuffer[2]
                          atAddress:fifoAddress 
                        timesToRead:1024
                         withAddMod:[self addressModifier] 
                      usingAddSpace:0x01];
            
            //the first word of the actual data record had better be the packet separator
            if(dataBuffer[2]==kGretina4MPacketSeparator){
                short chan = dataBuffer[3] & 0xf;
                //if(chan==1 || dataBuffer[3] & 0x7 ==1) {NSLog(@"!!!! Channel = 1 should have increase of events, while chan = %hu\n", chan);}
                if(chan < kNumGretina4MChannels){
                    ++waveFormCount[chan];  //grab the channel and increase the count
                    [aDataPacket addLongsToFrameBuffer:dataBuffer length:kG4MDataPacketSize];

                }
                else {
                    NSLogError(@"",@"Bad header--record discarded",@"GRETINA4M",[NSString stringWithFormat:@"slot %d",[self slot]], [NSString stringWithFormat:@"chan %d",1],nil);
                }
            }
            else {
                //oops... the buffer read is out of sequence
                NSLogError(@"",@"Packet Sequence Error -- FIFO reset",@"GRETINA4M",[NSString stringWithFormat:@"slot %d",[self slot]],nil);
                fifoResetCount++;
                [self resetFIFO];
            }
        }
    }
	@catch(NSException* localException) {
        NSLogError(@"",@"Gretina4M Card Error",errorLocation,nil);
        [self incExceptionCount];
        [localException raise];
    }
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    @try {
        if([[userInfo objectForKey:@"doinit"]boolValue]==1){
            int i;
            for(i=0;i<kNumGretina4MChannels;i++){
                [self writeControlReg:i enabled:NO];
            }
        }
        else {
            NSLog(@"Quick Start Enabled. %@ left running.\n",[self fullID]);
        }
	}
	@catch(NSException* e){
        [self incExceptionCount];
        NSLogError(@"",@"Gretina4M Card Error",nil);
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
    [rateRunningAverages resetCounters:0];
    
    //stop all channels
    short i;
    for(i=0;i<kNumGretina4MChannels;i++){					
		waveFormCount[i] = 0;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkFifoAlarm) object:nil];
}

- (void) checkFifoAlarm
{
	if(((fifoState & kGretina4MFIFOAlmostFull) != 0) && isRunning){
		fifoEmptyCount = 0;
		if(!fifoFullAlarm){
			NSString* alarmName = [NSString stringWithFormat:@"FIFO Almost Full Gretina4M (slot %d)",[self slot]];
			fifoFullAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kDataFlowAlarm];
			[fifoFullAlarm setSticky:YES];
			[fifoFullAlarm setHelpString:@"The rate is too high. Adjust the LED Threshold accordingly."];
			[fifoFullAlarm postAlarm];
		}
	}
	else {
		fifoEmptyCount++;
		if(fifoEmptyCount>=5){
			[fifoFullAlarm clearAlarm];
			[fifoFullAlarm release];
			fifoFullAlarm = nil;
		}
	}
	if(isRunning){
		[self performSelector:@selector(checkFifoAlarm) withObject:nil afterDelay:1.5];
	}
	else {
		[fifoFullAlarm clearAlarm];
		[fifoFullAlarm release];
		fifoFullAlarm = nil;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MFIFOCheckChanged object:self];
}

- (void) reset
{
}

- (BOOL) bumpRateFromDecodeStage:(int)channel
{
    if(channel>=0 && channel<kNumGretina4MChannels){
        ++waveFormCount[channel];
    }
    return YES;
}

- (unsigned long) waveFormCount:(short)aChannel
{
    if(aChannel>=0 && aChannel<kNumGretina4MChannels){
        return waveFormCount[aChannel];
    }
    else return 0;
}

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
    [rateRunningAverages start:self pollTime:[waveFormRateGroup integrationTime]];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        waveFormCount[i]=0;
    }
}

- (void) tasksCompleted: (NSNotification*)aNote
{
    
}
- (BOOL) queueIsRunning
{
    return [fileQueue operationCount];
}
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	
    /* The current hardware specific data is:               *
     *                                                      *
     * 0: FIFO state address                                *
     * 1: FIFO empty state mask                             *
     * 2: FIFO address                                      *
     * 3: FIFO address AM                                   *
     * 4: FIFO size                                         */

	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kGretina4M; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId; //better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= [self addressModifier];
	configStruct->card_info[index].base_add					= [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0]	= [self baseAddress] + register_information[kProgrammingDone].offset; //fifoStateAddress
    configStruct->card_info[index].deviceSpecificData[1]	= [self baseAddress] + 0x1000; // fifoAddress
    configStruct->card_info[index].deviceSpecificData[2]	= 0x0B; // fifoAM
    configStruct->card_info[index].deviceSpecificData[3]	= [self baseAddress] + 0x04; // fifoReset Address
    configStruct->card_info[index].deviceSpecificData[4]	= location; //crate, card, serial number
    configStruct->card_info[index].deviceSpecificData[5]	= runNumberLocal;
    configStruct->card_info[index].deviceSpecificData[6]	= subRunNumberLocal;

	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{

    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setBaselineRestoredDelay:     [decoder decodeIntForKey:@"baselineRestoredDelay"]];
    [self setNoiseWindow:               [decoder decodeIntForKey:@"noiseWindow"]];
    [self setIntegrateTime:             [decoder decodeIntForKey:@"integrateTime"]];
    [self setCollectionTime:            [decoder decodeIntForKey:@"collectionTime"]];
    [self setExtTrigLength:             [decoder decodeIntForKey:@"extTrigLength"]];
    [self setPileUpWindow:              [decoder decodeIntForKey:@"pileUpWindow"]];
    [self setExternalWindow:            [decoder decodeIntForKey:@"externalWindow"]];
    [self setClockSource:               [decoder decodeIntForKey:@"clockSource"]];
    [self setClockPhase:                [decoder decodeIntForKey:@"clockPhase"]];
    [self setSpiConnector:              [decoder decodeObjectForKey:@"spiConnector"]];
    [self setLinkConnector:             [decoder decodeObjectForKey:@"linkConnector"]];
    [self setDownSample:				[decoder decodeIntForKey:@"downSample"]];
    [self setRegisterIndex:				[decoder decodeIntForKey:@"registerIndex"]];
    [self setRegisterWriteValue:		[decoder decodeInt32ForKey:@"registerWriteValue"]];
    [self setSPIWriteValue:     		[decoder decodeInt32ForKey:@"spiWriteValue"]];
    [self setFpgaFilePath:				[decoder decodeObjectForKey:@"fpgaFilePath"]];
    [self setNoiseFloorIntegrationTime:	[decoder decodeFloatForKey:@"NoiseFloorIntegrationTime"]];
    [self setNoiseFloorOffset:			[decoder decodeIntForKey:@"NoiseFloorOffset"]];
    [self setHistEMultiplier:			[decoder decodeIntForKey:@"histEMultiplier"]];
    [self setForceFullInitCard:			[decoder decodeBoolForKey:@"forceFullInitCard"]];
    [self setDoHwCheck:                 [decoder decodeBoolForKey:@"doHwCheck"]];
    
    [self setWaveFormRateGroup:         [decoder decodeObjectForKey:@"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumGretina4MChannels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
   
    if(!rateRunningAverages){
        [self setRateRunningAverages:[[[ORRunningAverageGroup alloc] initGroup:kNumGretina4MChannels groupTag:0 withLength:10] autorelease]];
    }
    [rateRunningAverages setTriggerType:kRASpikeOnRatio];
    [rateRunningAverages setTriggerValue:5]; //this is ratio...  rate threshold could be changed
    
    int i;
	for(i=0;i<kNumGretina4MChannels;i++){
        
        [self setForceFullInit:i withValue:[decoder decodeIntForKey:[@"forceFullInit"	    stringByAppendingFormat:@"%d",i]]];
        [self setEnabled:i		withValue:[decoder decodeIntForKey:[@"enabled"	    stringByAppendingFormat:@"%d",i]]];
		[self setTrapEnabled:i	withValue:[decoder decodeIntForKey:[@"trapEnabled"	stringByAppendingFormat:@"%d",i]]];
		[self setDebug:i		withValue:[decoder decodeIntForKey:[@"debug"	    stringByAppendingFormat:@"%d",i]]];
		[self setPileUp:i		withValue:[decoder decodeIntForKey:[@"pileUp"	    stringByAppendingFormat:@"%d",i]]];
		[self setPoleZeroEnabled:i withValue:[decoder decodeIntForKey:[@"poleZeroEnabled" stringByAppendingFormat:@"%d",i]]];
		[self setPoleZeroMultiplier:i withValue:[decoder decodeIntForKey:[@"poleZeroMult" stringByAppendingFormat:@"%d",i]]];
		[self setBaselineRestoreEnabled:i withValue:[decoder decodeIntForKey:[@"baselineRestoreEnabled" stringByAppendingFormat:@"%d",i]]];
		[self setPZTraceEnabled:i withValue:[decoder decodeIntForKey:[@"pzTraceEnabled" stringByAppendingFormat:@"%d",i]]];
		[self setTriggerMode:i	withValue:[decoder decodeIntForKey:[@"triggerMode"	stringByAppendingFormat:@"%d",i]]];
		[self setLEDThreshold:i withValue:[decoder decodeIntForKey:[@"ledThreshold" stringByAppendingFormat:@"%d",i]]];
		[self setTrapThreshold:i withValue:[decoder decodeIntForKey:[@"trapThreshold" stringByAppendingFormat:@"%d",i]]];
		[self setMrpsrt:i       withValue:[decoder decodeIntForKey:[@"mrpsrt"       stringByAppendingFormat:@"%d",i]]];
		[self setFtCnt:i        withValue:[decoder decodeIntForKey:[@"ftCnt"        stringByAppendingFormat:@"%d",i]]];
		[self setMrpsdv:i       withValue:[decoder decodeIntForKey:[@"mrpsdv"       stringByAppendingFormat:@"%d",i]]];
		[self setChpsrt:i       withValue:[decoder decodeIntForKey:[@"chpsrt"       stringByAppendingFormat:@"%d",i]]];
		[self setChpsdv:i       withValue:[decoder decodeIntForKey:[@"chpsdv"       stringByAppendingFormat:@"%d",i]]];
		[self setPrerecnt:i     withValue:[decoder decodeIntForKey:[@"prerecnt"     stringByAppendingFormat:@"%d",i]]];
		[self setPostrecnt:i    withValue:[decoder decodeIntForKey:[@"postrecnt"    stringByAppendingFormat:@"%d",i]]];
		[self setTpol:i         withValue:[decoder decodeIntForKey:[@"tpol"         stringByAppendingFormat:@"%d",i]]];
		[self setPresumEnabled:i withValue:[decoder decodeIntForKey:[@"presumEnabled"         stringByAppendingFormat:@"%d",i]]];
        [self setEasySelected:i		withValue:[decoder decodeIntForKey:[@"easySelected"	    stringByAppendingFormat:@"%d",i]]];
	}
    
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:baselineRestoredDelay forKey:@"baselineRestoredDelay"];
    [encoder encodeInt:noiseWindow                  forKey:@"noiseWindow"];
    [encoder encodeInt:integrateTime                forKey:@"integrateTime"];
    [encoder encodeInt:collectionTime               forKey:@"collectionTime"];
    [encoder encodeInt:extTrigLength                forKey:@"extTrigLength"];
    [encoder encodeInt:pileUpWindow                 forKey:@"pileUpWindow"];
    [encoder encodeInt:externalWindow               forKey:@"externalWindow"];
    [encoder encodeInt:clockSource                  forKey:@"clockSource"];
    [encoder encodeInt:clockPhase                   forKey:@"clockPhase"];
    [encoder encodeObject:spiConnector				forKey:@"spiConnector"];
    [encoder encodeObject:linkConnector				forKey:@"linkConnector"];
    [encoder encodeInt:downSample					forKey:@"downSample"];
    [encoder encodeInt:registerIndex				forKey:@"registerIndex"];
    [encoder encodeInt32:registerWriteValue			forKey:@"registerWriteValue"];
    [encoder encodeInt32:spiWriteValue			    forKey:@"spiWriteValue"];
    [encoder encodeObject:fpgaFilePath				forKey:@"fpgaFilePath"];
    [encoder encodeFloat:noiseFloorIntegrationTime	forKey:@"NoiseFloorIntegrationTime"];
    [encoder encodeInt:noiseFloorOffset				forKey:@"NoiseFloorOffset"];
    [encoder encodeObject:waveFormRateGroup			forKey:@"waveFormRateGroup"];
    [encoder encodeInt:histEMultiplier              forKey:@"histEMultiplier"];
    [encoder encodeBool:forceFullInitCard           forKey:@"forceFullInitCard"];
    [encoder encodeBool:doHwCheck                   forKey:@"doHwCheck"];

	int i;
 	for(i=0;i<kNumGretina4MChannels;i++){
        [encoder encodeInt:forceFullInit[i]	forKey:[@"forceFullInit"		stringByAppendingFormat:@"%d",i]];
        [encoder encodeInt:enabled[i]		forKey:[@"enabled"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:trapEnabled[i]	forKey:[@"trapEnabled"  stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:debug[i]			forKey:[@"debug"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:pileUp[i]		forKey:[@"pileUp"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:poleZeroEnabled[i] forKey:[@"poleZeroEnabled" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:poleZeroMult[i]  forKey:[@"poleZeroMult" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:baselineRestoreEnabled[i] forKey:[@"baselineRestoreEnabled" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:pzTraceEnabled[i] forKey:[@"pzTraceEnabled" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:triggerMode[i]	forKey:[@"triggerMode"	stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:ledThreshold[i]	forKey:[@"ledThreshold" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:trapThreshold[i]	forKey:[@"trapThreshold" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:mrpsrt[i]        forKey:[@"mrpsrt"       stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:ftCnt[i]         forKey:[@"ftCnt"        stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:mrpsdv[i]        forKey:[@"mrpsdv"       stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:chpsrt[i]        forKey:[@"chpsrt"       stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:chpsdv[i]        forKey:[@"chpsdv"       stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:prerecnt[i]      forKey:[@"prerecnt"     stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:postrecnt[i]     forKey:[@"postrecnt"    stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:tpol[i]          forKey:[@"tpol"         stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:presumEnabled[i] forKey:[@"presumEnabled" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:easySelected[i]	forKey:[@"easySelected"		stringByAppendingFormat:@"%d",i]];
	}
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithInt:noiseWindow] forKey:@"Noise Window"];
    [objDictionary setObject:[NSNumber numberWithInt:externalWindow] forKey:@"External Window"];
    [objDictionary setObject:[NSNumber numberWithInt:pileUpWindow] forKey:@"Pile Up Window"];
    [objDictionary setObject:[NSNumber numberWithInt:extTrigLength] forKey:@"Ext Trig Length"];
    [objDictionary setObject:[NSNumber numberWithInt:collectionTime] forKey:@"Collection Time"];
    [objDictionary setObject:[NSNumber numberWithInt:integrateTime] forKey:@"Integration Time"];
    [objDictionary setObject:[NSNumber numberWithInt:serialNumber] forKey:@"Serial Number"];
    
    [self addCurrentState:objDictionary boolArray:(BOOL*)enabled       forKey:@"Enabled"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)forceFullInit forKey:@"forceFullInit"];
	[self addCurrentState:objDictionary boolArray:(BOOL*)trapEnabled   forKey:@"Trap Enabled"];
	[self addCurrentState:objDictionary boolArray:(BOOL*)debug         forKey:@"Debug Mode"];
	[self addCurrentState:objDictionary boolArray:(BOOL*)pileUp        forKey:@"Pile Up"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)poleZeroEnabled forKey:@"Pole Zero Enabled"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)pzTraceEnabled forKey:@"PZ Trace Enabled"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)presumEnabled forKey:@"PreSum Enabled"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)baselineRestoreEnabled forKey:@"Baseline Restore Enabled"];

	[self addCurrentState:objDictionary shortArray:triggerMode          forKey:@"Trigger Mode"];
	[self addCurrentState:objDictionary shortArray:poleZeroMult         forKey:@"Pole Zero Multiplier"];
	[self addCurrentState:objDictionary shortArray:mrpsrt               forKey:@"Mrpsrt"];
	[self addCurrentState:objDictionary shortArray:ftCnt                forKey:@"FtCnt"];
	[self addCurrentState:objDictionary shortArray:mrpsdv               forKey:@"Mrpsdv"];
	[self addCurrentState:objDictionary shortArray:chpsrt               forKey:@"Chpsrt"];
	[self addCurrentState:objDictionary shortArray:chpsdv               forKey:@"Chpsdv"];
	[self addCurrentState:objDictionary shortArray:prerecnt             forKey:@"Prerecnt"];
	[self addCurrentState:objDictionary shortArray:postrecnt            forKey:@"Postrecnt"];
	[self addCurrentState:objDictionary shortArray:tpol                 forKey:@"TPol"];

    NSMutableArray* ar = [NSMutableArray array];
    int i;
	for(i=0;i<kNumGretina4MChannels;i++)[ar addObject:[NSNumber numberWithLong:ledThreshold[i]]];
    [objDictionary setObject:ar forKey:@"LED Threshold"];
    
    [ar removeAllObjects];
    for(i=0;i<kNumGretina4MChannels;i++)[ar addObject:[NSNumber numberWithLong:trapThreshold[i]]];
    [objDictionary setObject:ar forKey:@"TRAP Threshold"];
    
    [objDictionary setObject:[NSNumber numberWithInt:downSample]        forKey:@"Down Sample"];
    [objDictionary setObject:[NSNumber numberWithInt:clockSource]       forKey:@"Clock Source"];
    [objDictionary setObject:[NSNumber numberWithInt:clockPhase]        forKey:@"Clock Phase"];
    [objDictionary setObject:[NSNumber numberWithInt:histEMultiplier]   forKey:@"Hist E Multiplier"];
    [objDictionary setObject:[NSNumber numberWithInt:forceFullInitCard] forKey:@"forceFullInitCard"];

	
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary shortArray:(short*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<kNumGretina4MChannels;i++){
		[ar addObject:[NSNumber numberWithShort:anArray[i]]];
	}
	[dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
        [ar addObject:[NSNumber numberWithBool:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}


- (NSArray*) autoTests 
{
	NSMutableArray* myTests = [NSMutableArray array];
	[myTests addObject:[ORVmeReadOnlyTest test:kBoardID wordSize:4 name:@"Board ID"]];
	[myTests addObject:[ORVmeReadWriteTest test:kControlStatus wordSize:4 validMask:0x000000ff name:@"Control/Status"]];
	return myTests;
}


#pragma mark •••SPI Interface
- (unsigned long) writeAuxIOSPI:(unsigned long)spiData
{
    // Set AuxIO to mode 3 and set bits 0-3 to OUT (bit 0 is under FPGA control)
    [self writeRegister:kAuxIOConfig withValue:0x3025];
    // Read kAuxIOWrite to preserve bit 0, and zero bits used in SPI protocol
    unsigned long spiBase = [self readRegister:kAuxIOWrite] & ~(kSPIData | kSPIClock | kSPIChipSelect); 
    unsigned long value;
    unsigned long readBack = 0;
	
    // set kSPIChipSelect to signify that we are starting
    [self writeRegister:kAuxIOWrite withValue:(kSPIChipSelect | kSPIClock | kSPIData)];
    // now write spiData starting from MSB on kSPIData, pulsing kSPIClock
    // each iteration
    int i;
    //NSLog(@"writing 0x%x\n", spiData);
    for(i=0; i<32; i++) {
        value = spiBase | kSPIChipSelect | kSPIData;
        if( (spiData & 0x80000000) != 0) value &= (~kSPIData);
        [self writeRegister:kAuxIOWrite withValue:value | kSPIClock];
        [self writeRegister:kAuxIOWrite withValue:value];
        readBack |= (([self readRegister:kAuxIORead] & kSPIRead) > 0) << (31-i);
        spiData = spiData << 1;
    }
    // unset kSPIChipSelect to signify that we are done
    [self writeRegister:kAuxIOWrite withValue:(kSPIClock | kSPIData)];
    //NSLog(@"readBack=%u (0x%x)\n", readBack, readBack);
    return readBack;
}

- (void) snapShotRegisters
{
    int i;
    for(i=0;i<kNumberOfGretina4MRegisters;i++){
        snapShot[i] = [self readRegister:i];
    }
    
    for(i=0;i<kNumberOfFPGARegisters;i++){        
        fpgaSnapShot[i] = [self readFPGARegister:i];
    }
}

- (void) compareToSnapShot
{
    NSLog(@"------------------------------------------------\n");
    NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"offset   snapshot        newest\n");

    int i;
    for(i=0;i<kNumberOfGretina4MRegisters;i++){
        unsigned long theValue = [self readRegister:i];
        if(snapShot[i] != theValue){
            NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"0x%04x 0x%08x != 0x%08x %@\n",register_information[i].offset,snapShot[i],theValue,register_information[i].name);
 
        }
    }
    
    for(i=0;i<kNumberOfFPGARegisters;i++){
        unsigned long theValue = [self readFPGARegister:i];
        if(fpgaSnapShot[i] != theValue){
            NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"0x%04x 0x%08x != 0x%08x %@\n",fpga_register_information[i].offset,fpgaSnapShot[i],theValue,fpga_register_information[i].name);
            
        }
    }
    NSLog(@"------------------------------------------------\n");

}


- (void) dumpAllRegisters
{
    NSLog(@"------------------------------------------------\n");
    NSLog(@"Register Values for Channel #1\n");
    int i;
    for(i=0;i<kNumberOfGretina4MRegisters;i++){
        unsigned long theValue = [self readRegister:i];
        NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"0x%04x 0x%08x %@\n",register_information[i].offset,theValue,register_information[i].name);
        snapShot[i] = theValue;

    }
    NSLog(@"------------------------------------------------\n");

    for(i=0;i<kNumberOfFPGARegisters;i++){
        unsigned long theValue = [self readFPGARegister:i];
          NSLogFont([NSFont fontWithName:@"Monaco" size:10.0],@"0x%04x 0x%08x %@\n",fpga_register_information[i].offset,theValue,fpga_register_information[i].name);
        
        fpgaSnapShot[i] = theValue;
    }

}

#pragma mark •••AdcProviding Protocol
- (BOOL) onlineMaskBit:(int)bit
{
   return [self enabled:bit];
}

- (BOOL) partOfEvent:(unsigned short)aChannel
{
	//included to satisfy the protocol... change if needed
	return NO;
}

- (unsigned long) eventCount:(int)aChannel
{
    if(aChannel>=0 && aChannel<kNumGretina4MChannels){
        return waveFormCount[aChannel];
    }
    else return 0;
}

- (void) clearEventCounts
{
    int i;
    for(i=0;i<kNumGretina4MChannels;i++){
		waveFormCount[i]=0;
    }
}

- (unsigned long) thresholdForDisplay:(unsigned short) aChan
{
    if(trapEnabled[aChan])  return [self trapThreshold:aChan];
	else                    return [self ledThreshold:aChan];
}

- (unsigned short) gainForDisplay:(unsigned short) aChan
{
	return 0;
}
- (void) postAdcInfoProvidingValueChanged
{
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORAdcInfoProvidingValueChanged
	 object:self
	 userInfo: nil];
}
- (void) setThreshold:(short)chan withValue:(int)aValue
{
    [self setLEDThreshold:chan withValue:aValue];
}
//separate manually load of thresholds
- (void) loadThresholds
{
    NSLog(@"%@ Manual load of thresholds\n",[self fullID]);
    int i;
    for(i=0;i<kNumGretina4MChannels;i++) {
        if([self enabled:i]){
            if([self trapEnabled:i]) [self writeTrapThreshold:i];
            else                     [self writeLEDThreshold:i];
        }
    }
}
@end

@implementation ORGretina4MModel (private)

- (void) updateDownLoadProgress
{
	//call only from main thread
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4MFpgaDownProgressChanged object:self];
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
				[NSException raise:@"Gretina4M Exception" format:@"Verification of flash failed."];	
			}
            else {
                //reload the fpga from flash
                [self writeToAddress:0x900 aValue:kGretina4MResetMainFPGACmd];
                [self writeToAddress:0x900 aValue:kGretina4MReloadMainFPGACmd];
                [self setProgressStateOnMainThread:  @"Finishing$Flash Memory-->FPGA"];
                uint32_t statusRegValue = [self readFromAddress:0x904];
                while(!(statusRegValue & kGretina4MMainFPGAIsLoaded)) {
                    if(stopDownLoadingMainFPGA)return;
                    statusRegValue = [self readFromAddress:0x904];
                }
                NSLog(@"Gretina4(%d): FPGA Load Finished - No Errors\n",[self uniqueIdNumber]);

            }
		}
		[self setProgressStateOnMainThread:@"Loading FPGA"];
		if(!stopDownLoadingMainFPGA) [self reloadMainFPGAFromFlash];
        else NSLog(@"Gretina4(%d): FPGA Load Manually Stopped\n",[self uniqueIdNumber]);
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
	/* We only erase the blocks currently used in the Gretina4M specification. */
    [self writeToAddress:0x910 aValue:kGretina4MFlashEnableWrite]; //Enable programming
	[self setFpgaDownProgress:0.];
    unsigned long count = 0;
    unsigned long end = (kGretina4MFlashBlocks / 4) * kGretina4MFlashBlockSize;
    unsigned long addr;
    [self setProgressStateOnMainThread:  @"Block Erase"];
    for (addr = 0; addr < end; addr += kGretina4MFlashBlockSize) {
        
		if(stopDownLoadingMainFPGA)return;
		@try {
            [self setFirmwareStatusString:       [NSString stringWithFormat:@"%lu of %d Blocks Erased",count,kGretina4MFlashBufferBytes]];
 			[self setFpgaDownProgress: 100. * (count+1)/(float)kGretina4MUsedFlashBlocks];
           
            [self writeToAddress:0x980 aValue:addr];
            [self writeToAddress:0x98C aValue:kGretina4MFlashBlockEraseCmd];
            [self writeToAddress:0x98C aValue:kGretina4MFlashConfirmCmd];
            unsigned long stat = [self readFromAddress:0x904];
            while (stat & kFlashBusy) {
                if(stopDownLoadingMainFPGA)break;
                stat = [self readFromAddress:0x904];
            }
            count++;
		}
		@catch(NSException* localException) {
			NSLog(@"Gretina4M exception erasing flash.\n");
		}
	}
    
	[self setFpgaDownProgress: 100];
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	[self setFpgaDownProgress: 0];
}

- (void) programFlashBuffer:(NSData*)theData
{
    unsigned long totalSize = [theData length];
    
    [self setProgressStateOnMainThread:@"Programming"];
    [self setFirmwareStatusString: [NSString stringWithFormat:@"FPGA File Size %lu KB",totalSize/1000]];
    [self setFpgaDownProgress:0.];

    [self writeToAddress:0x980 aValue:0x00];
    [self writeToAddress:0x98C aValue:kGretina4MFlashReadArrayCmd];
    
     unsigned long address = 0x0;
     while (address < totalSize ) {
         unsigned long numberBytesToWrite;
         if(totalSize-address >= kGretina4MFlashBufferBytes){
             numberBytesToWrite = kGretina4MFlashBufferBytes; //whole block
         }
         else {
             numberBytesToWrite = totalSize - address; //near eof, so partial block
         }
         
         [self programFlashBufferBlock:theData address:address numberBytes:numberBytesToWrite];
         
         address += numberBytesToWrite;
         if(stopDownLoadingMainFPGA)break;
         

         [self setFirmwareStatusString: [NSString stringWithFormat:@"Flashed: %lu/%lu KB",address/1000,totalSize/1000]];
         
         [self setFpgaDownProgress:100. * address/(float)totalSize];

         if(stopDownLoadingMainFPGA)break;
         
     }
     if(stopDownLoadingMainFPGA)return;

    [self writeToAddress:0x980 aValue:0x00];
    [self writeToAddress:0x98C aValue:kGretina4MFlashReadArrayCmd];
    [self writeToAddress:0x910 aValue:0x00];

    [self setProgressStateOnMainThread:@"Programming"];
}

- (void) programFlashBufferBlock:(NSData*)theData address:(unsigned long)anAddress numberBytes:(unsigned long)aNumber
{
    //issue the set-up command at the starting address
    [self writeToAddress:0x980 aValue:anAddress];
    [self writeToAddress:0x98C aValue:kGretina4MFlashWriteCmd];
    unsigned char* theDataBytes = (unsigned char*)[theData bytes];
    unsigned long statusRegValue;
	while(1) {
        if(stopDownLoadingMainFPGA)return;
		
		// Checking status to make sure that flash is ready
        unsigned long statusRegValue = [self readFromAddress:0x904];
		
		if ( (statusRegValue & kFlashBusy)  == kFlashBusy ) {
            //not ready, so re-issue the set-up command
            [self writeToAddress:0x980 aValue:anAddress];
            [self writeToAddress:0x98C aValue:kGretina4MFlashWriteCmd];
		}
        else break;
	}
    
	//Set the word count. Max is 0xF.
	unsigned long valueToWrite = (aNumber/2) - 1;
    [self writeToAddress:0x98C aValue:valueToWrite];
	
	// Loading all the words in
    /* Load the words into the bufferToWrite */
	unsigned long i;
	for ( i=0; i<aNumber; i+=4 ) {
        unsigned long* lPtr = (unsigned long*)&theDataBytes[anAddress+i];
        [self writeToAddress:0x984 aValue:lPtr[0]];
	}
	
	// Confirm the write
    [self writeToAddress:0x98C aValue:kGretina4MFlashConfirmCmd];
	
    //wait until the buffer is available again
    statusRegValue = [self readFromAddress:0x904];
    while(statusRegValue & kFlashBusy) {
        if(stopDownLoadingMainFPGA)break;
        statusRegValue = [self readFromAddress:0x904];
    }
}

- (BOOL) verifyFlashBuffer:(NSData*)theData
{
    unsigned long totalSize = [theData length];
    unsigned char* theDataBytes = (unsigned char*)[theData bytes];
    
    [self setProgressStateOnMainThread:@"Verifying"];
    [self setFirmwareStatusString: [NSString stringWithFormat:@"FPGA File Size %lu KB",totalSize/1000]];
    [self setFpgaDownProgress:0.];
    
    /* First reset to make sure it is read mode. */
    [self writeToAddress:0x980 aValue:0x0];
    [self writeToAddress:0x98C aValue:kGretina4MFlashReadArrayCmd];
    
    unsigned long errorCount =   0;
    unsigned long address    =   0;
    unsigned long valueToCompare;
    
    while ( address < totalSize ) {
        unsigned long valueToRead = [self readFromAddress:0x984];
        
        /* Now compare to file*/
        if ( address + 3 < totalSize) {
            unsigned long* ptr = (unsigned long*)&theDataBytes[address];
            valueToCompare = ptr[0];
        }
        else {
            //less than four bytes left
            unsigned long numBytes = totalSize - address - 1;
            valueToCompare = 0;
            unsigned long i;
            for ( i=0;i<numBytes;i++) {
                valueToCompare += (((unsigned long)theDataBytes[address]) << i*8) & (0xFF << i*8);
            }
        }
        if ( valueToRead != valueToCompare ) {
            [self setProgressStateOnMainThread:@"Error"];
            [self setFirmwareStatusString: @"Comparision Error"];
            [self setFpgaDownProgress:0.];
            errorCount++;
        }
        
        [self setFirmwareStatusString: [NSString stringWithFormat:@"Verified: %lu/%lu KB Errors: %lu",address/1000,totalSize/1000,errorCount]];
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
    
    [self writeToAddress:0x900 aValue:kGretina4MResetMainFPGACmd];
    [self writeToAddress:0x900 aValue:kGretina4MReloadMainFPGACmd];
	
    unsigned long statusRegValue=[self readFromAddress:0x904];

    while(!(statusRegValue & kGretina4MMainFPGAIsLoaded)) {
        if(stopDownLoadingMainFPGA)return;
        statusRegValue=[self readFromAddress:0x904];
    }
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
    //long removeReturn;
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
        p->baseAddress      = [self baseAddress];
        @try {
            NSLog(@"Gretina4M (%d) launching firmware load job in SBC\n",[self uniqueIdNumber]);

            [[[self adapter] sbcLink] send:&aPacket receive:&aPacket];
            
            [[[self adapter] sbcLink] monitorJobFor:self statusSelector:@selector(flashFpgaStatus:)];

        }
        @catch(NSException* e){
            
        }
    }
}
@end
