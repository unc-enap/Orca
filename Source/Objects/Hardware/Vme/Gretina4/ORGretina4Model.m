//-------------------------------------------------------------------------
//  ORGretina4Model.m
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
#import "ORGretina4Model.h"
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

#define kCurrentFirmwareVersion 0x106
#define kFPGARemotePath @"GretinaFPGA.bin"

NSString* ORGretina4ModelDownSampleChanged			= @"ORGretina4ModelDownSampleChanged";
NSString* ORGretina4ModelHistEMultiplierChanged			= @"ORGretina4ModelHistEMultiplierChanged";
NSString* ORGretina4ModelRegisterIndexChanged		= @"ORGretina4ModelRegisterIndexChanged";
NSString* ORGretina4ModelRegisterWriteValueChanged	= @"ORGretina4ModelRegisterWriteValueChanged";
NSString* ORGretina4ModelSPIWriteValueChanged	    = @"ORGretina4ModelSPIWriteValueChanged";
NSString* ORGretina4ModelFpgaDownProgressChanged	= @"ORGretina4ModelFpgaDownProgressChanged";
NSString* ORGretina4ModelMainFPGADownLoadStateChanged		= @"ORGretina4ModelMainFPGADownLoadStateChanged";
NSString* ORGretina4ModelFpgaFilePathChanged				= @"ORGretina4ModelFpgaFilePathChanged";
NSString* ORGretina4ModelNoiseFloorIntegrationTimeChanged	= @"ORGretina4ModelNoiseFloorIntegrationTimeChanged";
NSString* ORGretina4ModelNoiseFloorOffsetChanged	= @"ORGretina4ModelNoiseFloorOffsetChanged";
NSString* ORGretina4CardInfoUpdated					= @"ORGretina4CardInfoUpdated";
NSString* ORGretina4RateGroupChangedNotification	= @"ORGretina4RateGroupChangedNotification";

NSString* ORGretina4NoiseFloorChanged			= @"ORGretina4NoiseFloorChanged";
NSString* ORGretina4ModelFIFOCheckChanged		= @"ORGretina4ModelFIFOCheckChanged";

NSString* ORGretina4ModelEnabledChanged			= @"ORGretina4ModelEnabledChanged";
NSString* ORGretina4ModelCFDEnabledChanged		= @"ORGretina4ModelCFDEnabledChanged";
NSString* ORGretina4ModelPoleZeroEnabledChanged	= @"ORGretina4ModelPoleZeroEnabledChanged";
NSString* ORGretina4ModelPoleZeroMultChanged	= @"ORGretina4ModelPoleZeroMultChanged";
NSString* ORGretina4ModelPZTraceEnabledChanged= @"ORGretina4ModelPZTraceEnabledChanged";
NSString* ORGretina4ModelDebugChanged			= @"ORGretina4ModelDebugChanged";
NSString* ORGretina4ModelPileUpChanged			= @"ORGretina4ModelPileUpChanged";
NSString* ORGretina4ModelPolarityChanged		= @"ORGretina4ModelPolarityChanged";
NSString* ORGretina4ModelTriggerModeChanged		= @"ORGretina4ModelTriggerModeChanged";
NSString* ORGretina4ModelLEDThresholdChanged	= @"ORGretina4ModelLEDThresholdChanged";
NSString* ORGretina4ModelCFDDelayChanged		= @"ORGretina4ModelCFDDelayChanged";
NSString* ORGretina4ModelCFDFractionChanged		= @"ORGretina4ModelCFDFractionChanged";
NSString* ORGretina4ModelCFDThresholdChanged	= @"ORGretina4ModelCFDThresholdChanged";
NSString* ORGretina4ModelDataDelayChanged		= @"ORGretina4ModelDataDelayChanged";
NSString* ORGretina4ModelDataLengthChanged		= @"ORGretina4ModelDataLengthChanged";
NSString* ORGretina4ModelMainFPGADownLoadInProgressChanged		= @"ORGretina4ModelMainFPGADownLoadInProgressChanged";
NSString* ORGretina4CardInited					= @"ORGretina4CardInited";
NSString* ORGretina4SettingsLock				= @"ORGretina4SettingsLock";
NSString* ORGretina4RegisterLock				= @"ORGretina4RegisterLock";
NSString* ORGretina4odelSetEnableStatusChanged		= @"ORGretina4odelSetEnableStatusChanged";
NSString* ORGretina4ModelFirmwareStatusStringChanged= @"ORGretina4ModelFirmwareStatusStringChanged";
NSString* ORGretina4ClockSourceChanged         = @"ORGretina4ClockSourceChanged";
NSString* ORGretina4ModelInitStateChanged      = @"ORGretina4ModelInitStateChanged";
NSString* ORGretina4LockChanged                 = @"ORGretina4LockChanged";

@interface ORGretina4Model (private)
- (void) blockEraseFlash;
- (void) programFlashBuffer:(NSData*)theData;
- (void) programFlashBufferBlock:(NSData*)theData address:(uint32_t)anAddress numberBytes:(uint32_t)aNumber;
- (BOOL) verifyFlashBuffer:(NSData*)theData;
- (void) reloadMainFPGAFromFlash;
- (void) setProgressStateOnMainThread:(NSString*)aState;
- (void) updateDownLoadProgress;
- (void) downloadingMainFPGADone;
- (void) fpgaDownLoadThread:(NSData*)dataFromFile;
- (void) fileMoverIsDone;
- (void) loadFPGAUsingSBC;
- (void) setFpgaDownProgress:(int)aFpgaDownProgress;
@end


@implementation ORGretina4Model
#pragma mark ¥¥¥Static Declarations
//offsets from the base address
typedef struct {
	uint32_t offset;
	NSString* name;
	BOOL canRead;
	BOOL canWrite;
	BOOL hasChannels;
	BOOL displayOnMainGretinaPage;
} Gretina4RegisterInformation;
	
static Gretina4RegisterInformation register_information[kNumberOfGretina4Registers] = {
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
{0xC0,  @"CFD Parameters", YES, YES, YES, YES},                
{0x100, @"Raw data sliding length", YES, YES, YES, YES},       
{0x140, @"Raw data window length", YES, YES, YES, YES},        
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
{0x1C0, @"Trapezoidal trigger settings", NO, YES, YES, YES}
};
                                      
static Gretina4RegisterInformation fpga_register_information[kNumberOfFPGARegisters] = {
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

enum {
    kExternalWindowIndex,
    kPileUpWindowIndex,
    kNoiseWindowIndex,
    kExtTrigLengthIndex,
    kCollectionTimeIndex,
    kIntegrationTimeIndex
};

static struct {
    NSString*	name;
    NSString*	units;
    uint32_t	regOffset;
    unsigned short	mask; 
    unsigned short	initialValue;
    float		ratio; //conversion constants
} cardConstants[kNumGretina4CardParams] = {
{@"External Window",	@"us",	0x08,	0x7FF,	0x190, 4./(float)0x190},
{@"Pileup Window",		@"us",	0x0C,	0x7FF,	0x0400,	10./(float)0x400},
{@"Noise Window",		@"ns",	0x10,	0x07F,	0x0040,	640./(float)0x40},
{@"Ext Trigger Length", @"us",	0x14,	0x7FF,	0x0190,	4.0/(float)0x190},
{@"Collection Time",	@"us",	0x18,	0x01FF,	0x01C2,	4.5/(float)0x1C2},
{@"Integration Time",	@"us",	0x1C,	0x03FF,	0x01C2,	4.5/(float)0x1C2},
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
    [spiConnector release];
    [linkConnector release];
    [mainFPGADownLoadState release];
    [fpgaFilePath release];
    [waveFormRateGroup release];
    [cardInfo release];
	[fifoFullAlarm clearAlarm];
	[fifoFullAlarm release];
	[progressLock release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"Gretina4Card"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    int chan;
    float y=73;
    float dy=3;
    NSColor* enabledColor  = [NSColor colorWithCalibratedRed:0.4 green:0.7 blue:0.4 alpha:1];
    NSColor* disabledColor = [NSColor clearColor];
    for(chan=0;chan<kNumGretina4Channels;chan+=2){
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
    [self linkToController:@"ORGretina4Controller"];
}

- (NSString*) helpURL
{
	return @"VME/Gretina.html";
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

- (void) disconnect
{
    [spiConnector disconnect];
    [linkConnector disconnect];
    [super disconnect];
}

#pragma mark ***Accessors
- (short) initState {return initializationState;}
- (void) setInitState:(short)aState
{
    initializationState = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelInitStateChanged object:self];
}
- (short) clockSource
{
    return clockSource;
}

- (void) setClockSource:(short)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = aClockSource;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ClockSourceChanged object:self];
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
- (int) downSample
{
    return downSample;
}

- (void) setDownSample:(int)aDownSample
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDownSample:downSample];
    
    downSample = aDownSample;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelDownSampleChanged object:self];
}

- (int) histEMultiplier
{
    return histEMultiplier;
}

- (void) setHistEMultiplier:(int)aHistEMultiplier
{
    if(aHistEMultiplier<1)aHistEMultiplier=1;
    else if(aHistEMultiplier>100)aHistEMultiplier = 100;
    [[[self undoManager] prepareWithInvocationTarget:self] setHistEMultiplier:histEMultiplier];
    histEMultiplier = aHistEMultiplier;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelHistEMultiplierChanged object:self];
}

- (int) registerIndex
{
    return registerIndex;
}

- (void) setRegisterIndex:(int)aRegisterIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterIndex:registerIndex];
    registerIndex = aRegisterIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelRegisterIndexChanged object:self];
}

- (uint32_t) registerWriteValue
{
    return registerWriteValue;
}

- (void) setRegisterWriteValue:(uint32_t)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterWriteValue:registerWriteValue];
    registerWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelRegisterWriteValueChanged object:self];
}

- (uint32_t) spiWriteValue
{
    return spiWriteValue;
}


- (void) setSPIWriteValue:(uint32_t)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSPIWriteValue:spiWriteValue];
    spiWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelSPIWriteValueChanged object:self];
}

- (NSString*) registerNameAt:(unsigned int)index
{
	if (index >= kNumberOfGretina4Registers) return @"";
	return register_information[index].name;
}
- (unsigned short) registerOffsetAt:(unsigned int)index
{
	if (index >= kNumberOfGretina4Registers) return 0;
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

- (uint32_t) readRegister:(unsigned int)index
{
	if (index >= kNumberOfGretina4Registers) return -1;
	if (![self canReadRegister:index]) return -1;
	uint32_t theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[index].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}

- (void) writeRegister:(unsigned int)index withValue:(uint32_t)value
{
	if (index >= kNumberOfGretina4Registers) return;
	if (![self canWriteRegister:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[self baseAddress] + register_information[index].offset
                         numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];	
}

- (BOOL) canReadRegister:(unsigned int)index
{
	if (index >= kNumberOfGretina4Registers) return NO;
	return register_information[index].canRead;
}

- (BOOL) canWriteRegister:(unsigned int)index
{
	if (index >= kNumberOfGretina4Registers) return NO;
	return register_information[index].canWrite;
}

- (BOOL) displayRegisterOnMainPage:(unsigned int)index
{
	if (index >= kNumberOfGretina4Registers) return NO;
	return register_information[index].displayOnMainGretinaPage;
}

- (uint32_t) readFPGARegister:(unsigned int)index;
{
	if (index >= kNumberOfFPGARegisters) return -1;
	if (![self canReadFPGARegister:index]) return -1;
	uint32_t theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + fpga_register_information[index].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue;
}

- (void) writeFPGARegister:(unsigned int)index withValue:(uint32_t)value
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelMainFPGADownLoadInProgressChanged object:self];	
}

- (int) fpgaDownProgress
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelMainFPGADownLoadStateChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelFpgaFilePathChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelNoiseFloorIntegrationTimeChanged object:self];
}

- (uint32_t) fifoState
{
    return fifoState;
}

- (void) setFifoState:(int)aFifoState
{
    fifoState = aFifoState;
}

- (int) noiseFloorOffset
{
    return noiseFloorOffset;
}

- (void) setNoiseFloorOffset:(int)aNoiseFloorOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorOffset:noiseFloorOffset];
    
    noiseFloorOffset = aNoiseFloorOffset;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelNoiseFloorOffsetChanged object:self];
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
	 postNotificationName:ORGretina4RateGroupChangedNotification
	 object:self];    
}

- (BOOL) noiseFloorRunning
{
	return noiseFloorRunning;
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
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

- (void) initParams
{
	
	int i;
	for(i=0;i<kNumGretina4Channels;i++){
		enabled[i]			= YES;
		debug[i]			= NO;
		pileUp[i]			= NO;
        cfdEnabled[i]		= NO;
		poleZeroEnabled[i]	= NO;
		poleZeroMult[i]	    = 0x600;
		pzTraceEnabled[i]	= NO;
		polarity[i]			= 0x3;
		triggerMode[i]		= 0x0;
		ledThreshold[i]		= 0x1FFFF;
		cfdDelay[i]			= 0x3f;
		cfdFraction[i]		= 0x0;
		cfdThreshold[i]		= 0x10;
		dataDelay[i]		= 0x1C2;
		dataLength[i]		= 0x3FF;
	}
	
    if(!cardInfo){
        cardInfo = [[NSMutableArray array] retain];
        int i;
        for(i=0;i<kNumGretina4CardParams;i++){
            [cardInfo addObject:[NSNumber numberWithInt:cardConstants[i].initialValue]];
        }
    }	
    fifoLostEvents = 0;
	isFlashWriteEnabled = NO;
}

- (void) cardInfo:(int)index setObject:(id)aValue
{	
    [[[self undoManager] prepareWithInvocationTarget:self] cardInfo:index setObject:[self cardInfo:index]];
    [cardInfo replaceObjectAtIndex:index withObject:aValue];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4CardInfoUpdated object:self];
}

- (id) rawCardValue:(int)index value:(id)aValue 
{	
    float theValue = [aValue floatValue];
	if (theValue < 0) theValue = 0;
    unsigned short theRawValue = theValue / cardConstants[index].ratio;
	if (theRawValue > cardConstants[index].mask) theRawValue = cardConstants[index].mask;
    return [NSNumber numberWithInt: theRawValue & cardConstants[index].mask];
}

- (id) convertedCardValue:(int)index
{	
    int theValue  = [[cardInfo objectAtIndex:index] intValue];
    float theConvertedValue = theValue * cardConstants[index].ratio;
    return [NSNumber numberWithFloat: theConvertedValue];
}


- (id) cardInfo:(int)index
{
    return [cardInfo objectAtIndex:index];
}


- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

#pragma mark ¥¥¥Rates
- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumGretina4Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}
#pragma mark ¥¥¥specific accessors
- (NSString*) firmwareStatusString
{
    if([firmwareStatusString length]==0)return @"";
    else return firmwareStatusString;
}

- (void) setFirmwareStatusString:(NSString*)aState
{
	if(!aState)aState = @"--";
    [firmwareStatusString autorelease];
    firmwareStatusString = [aState copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelFirmwareStatusStringChanged object:self];
}

- (void) setExternalWindow:(int)aValue { [self cardInfo:kExternalWindowIndex  setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setPileUpWindow:(int)aValue   { [self cardInfo:kPileUpWindowIndex    setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setNoiseWindow:(int)aValue    { [self cardInfo:kNoiseWindowIndex     setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setExtTrigLength:(int)aValue  { [self cardInfo:kExtTrigLengthIndex   setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setCollectionTime:(int)aValue { [self cardInfo:kCollectionTimeIndex  setObject:[NSNumber numberWithInt:aValue]]; }
- (void) setIntegrationTime:(int)aValue { [self cardInfo:kIntegrationTimeIndex setObject:[NSNumber numberWithInt:aValue]]; }

- (int) externalWindowAsInt		{ return [[self cardInfo:kExternalWindowIndex] intValue]; }
- (int) pileUpWindowAsInt		{ return [[self cardInfo:kPileUpWindowIndex] intValue]; }
- (int) noiseWindowAsInt		{ return [[self cardInfo:kNoiseWindowIndex] intValue]; }
- (int) extTrigLengthAsInt		{ return [[self cardInfo:kExtTrigLengthIndex] intValue]; }
- (int) collectionTimeAsInt		{ return [[self cardInfo:kCollectionTimeIndex] intValue]; }
- (int) integrationTimeAsInt	{ return [[self cardInfo:kIntegrationTimeIndex] intValue]; }

- (void) setEnabled:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:chan withValue:enabled[chan]];
	enabled[chan] = aValue;
    [self setUpImage];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelEnabledChanged object:self];
    [self postAdcInfoProvidingValueChanged];
}

- (void) setCFDEnabled:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDEnabled:chan withValue:cfdEnabled[chan]];
	cfdEnabled[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelCFDEnabledChanged object:self];
}

- (void) setPoleZeroEnabled:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setPoleZeroEnabled:chan withValue:poleZeroEnabled[chan]];
	poleZeroEnabled[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPoleZeroEnabledChanged object:self];
}

- (void) setPoleZeroMultiplier:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setPoleZeroMultiplier:chan withValue:poleZeroMult[chan]];
	poleZeroMult[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPoleZeroMultChanged object:self];
}

- (void) setPZTraceEnabled:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setPZTraceEnabled:chan withValue:pzTraceEnabled[chan]];
	pzTraceEnabled[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPZTraceEnabledChanged object:self];
}

- (void) setDebug:(short)chan withValue:(short)aValue	
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setDebug:chan withValue:debug[chan]];
	debug[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelDebugChanged object:self];
}

- (void) setPileUp:(short)chan withValue:(short)aValue		
{ 
    [[[self undoManager] prepareWithInvocationTarget:self] setPileUp:chan withValue:pileUp[chan]];
	pileUp[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPileUpChanged object:self];
}

- (void) setPolarity:(short)chan withValue:(int)aValue		
{
	if(aValue<0)aValue=0;
	else if(aValue>0x3)aValue= 0x3;
    [[[self undoManager] prepareWithInvocationTarget:self] setPolarity:chan withValue:polarity[chan]];
	polarity[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelPolarityChanged object:self];
}

- (void) setTriggerMode:(short)chan withValue:(int)aValue	
{ 
	if(aValue<0) aValue=0;
	else if(aValue>kTrapezoidalTriggerMode) aValue = kTrapezoidalTriggerMode;
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerMode:chan withValue:triggerMode[chan]];
	triggerMode[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelTriggerModeChanged object:self];
}

- (void) setLEDThreshold:(short)chan withValue:(int)aValue 
{ 
	if(aValue<0) aValue=0;
	if(triggerMode[chan] == kTrapezoidalTriggerMode) {
      if(aValue>0xFFFFFF) aValue = 0xFFFFFF;
    }
	else {
      if(aValue>0x1FFFF) aValue = 0x1FFFF;
    }
    [[[self undoManager] prepareWithInvocationTarget:self] setLEDThreshold:chan withValue:ledThreshold[chan]];
	ledThreshold[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelLEDThresholdChanged object:self];
    [self postAdcInfoProvidingValueChanged];
}

- (void) setCFDDelay:(short)chan withValue:(int)aValue		
{
	if(aValue<0)aValue=0;
	else if(aValue>0x3F)aValue = 0x3F;
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDDelay:chan withValue:cfdDelay[chan]];
	cfdDelay[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelCFDDelayChanged object:self];
}

- (void) setCFDFraction:(short)chan withValue:(int)aValue	
{ 
	if(aValue<0)aValue=0;
	else if(aValue>0x11)aValue = 0x11;
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDFraction:chan withValue:cfdFraction[chan]];
	cfdFraction[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelCFDFractionChanged object:self];
}

- (void) setCFDThreshold:(short)chan withValue:(int)aValue  
{
	if(aValue<0)aValue=0;
	else if(aValue>0x1F)aValue = 0x1F;
    [[[self undoManager] prepareWithInvocationTarget:self] setCFDThreshold:chan withValue:cfdThreshold[chan]];
	cfdThreshold[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelCFDThresholdChanged object:self];
}

- (void) setDataDelay:(short)chan withValue:(int)aValue     
{
	if(aValue<0)aValue=0;
	else if(aValue>0x7FF)aValue = 0x7FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDataDelay:chan withValue:dataDelay[chan]];
	dataDelay[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelDataDelayChanged object:self];
}

- (void) setTraceLength:(short)chan withValue:(int)aValue
{
	[self setDataLength:chan withValue:(aValue+kGretina4HeaderLengthLongs*2)];
}

- (void) setDataLength:(short)chan withValue:(int)aValue    
{
	// The data length refers to the total length in the buffer, *NOT* the 
	// length of the trace.  That is, it includes the length of the header
	// so it can never be shorter than the header (*2 for words).
	
	if(aValue<kGretina4HeaderLengthLongs*2)aValue=kGretina4HeaderLengthLongs*2;
	else if(aValue>0x7FF)aValue = 0x7FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDataLength:chan withValue:dataLength[chan]];
	dataLength[chan] = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelDataLengthChanged object:self];
}

- (int) enabled:(short)chan			{ return enabled[chan]; }
- (int) cfdEnabled:(short)chan		{ return cfdEnabled[chan]; }
- (int) poleZeroEnabled:(short)chan	{ return poleZeroEnabled[chan]; }
- (int) poleZeroMult:(short)chan	{ return poleZeroMult[chan]; }
- (int) pzTraceEnabled:(short)chan  { return pzTraceEnabled[chan]; }
- (int) debug:(short)chan			{ return debug[chan]; }
- (int) pileUp:(short)chan			{ return pileUp[chan];}
- (int) polarity:(short)chan		{ return polarity[chan];}
- (int) triggerMode:(short)chan		{ return triggerMode[chan];}
- (int) ledThreshold:(short)chan	{ return ledThreshold[chan]; }
- (int) cfdDelay:(short)chan		{ return cfdDelay[chan]; }
- (int) cfdFraction:(short)chan		{ return cfdFraction[chan]; }
- (int) cfdThreshold:(short)chan	{ return cfdThreshold[chan]; }
- (int) dataDelay:(short)chan		{ return dataDelay[chan]; }
- (int) dataLength:(short)chan		{ return dataLength[chan]; }
- (int) traceLength:(short)chan		{ return dataLength[chan]-2*kGretina4HeaderLengthLongs; }


- (float) poleZeroTauConverted:(short)chan  { return poleZeroMult[chan]>0 ? 0.01*pow(2., 23)/poleZeroMult[chan] : 0; } //convert to us
- (float) cfdDelayConverted:(short)chan		{ return cfdDelay[chan]*630./(float)0x3F; }						//convert to ns
- (float) cfdThresholdConverted:(short)chan	{ return cfdThreshold[chan]*160./(float)0x10; }					//convert to kev
- (float) dataDelayConverted:(short)chan	{ return dataDelay[chan]*4.5/(float)0x01C2; }					//convert to Â¬Âµs
- (float) traceLengthConverted:(short)chan	{ return (dataLength[chan]-2*kGretina4HeaderLengthLongs)*10.0; }//convert to ns, making sure to remove header length

- (void) setPoleZeroTauConverted:(short)chan withValue:(float)aValue 
{
    if(aValue > 0) aValue = 0.01*pow(2., 23)/aValue;
	[self setPoleZeroMultiplier:chan withValue:aValue]; 	//us -> raw
}

- (void) setCFDDelayConverted:(short)chan withValue:(float)aValue
{
	[self setCFDDelay:chan withValue:aValue*0x3F/630.];		//ns -> raw
}

- (void) setCFDThresholdConverted:(short)chan withValue:(float)aValue
{
	[self setCFDThreshold:chan withValue:aValue*0x10/160.];		//kev -> raw
}

- (void) setDataDelayConverted:(short)chan withValue:(float)aValue;
{
	[self setDataDelay:chan withValue:aValue*0x01C2/4.5];		//Â¬Âµs -> raw
} 

- (void) setTraceLengthConverted:(short)chan withValue:(float)aValue
{
	[self setDataLength:chan withValue:(aValue/10.0 + 2*kGretina4HeaderLengthLongs)];		//ns -> raw
}  

#pragma mark ¥¥¥Hardware Access
- (uint32_t) baseAddress
{
	return (([self slot]+1)&0x1f)<<20;
}

- (short) readBoardID
{
    uint32_t theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kBoardID].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return theValue & 0xfff;
}


- (void) resetBoard
{
    /* First disable all channels. This does not affect the model state,
	 just the board state. */
    int i;
    for(i=0;i<kNumGretina4Channels;i++){
        [self writeControlReg:i enabled:NO];
    }
    
    [self resetMainFPGA];
    [ORTimer delay:6];  // 6 second delay during board reset
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
    uint32_t val = 0;
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
    uint32_t val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return ((val>>20) & 0x1); //bit is high if FIFO is empty
}


//new code version 1 (Jing Qian)
- (void) writeClockSource
{
    if(clockSource == 0)return; ////temp..... Clock source might be set by the Trigger Card init code.
	//clock select.  0 = SerDes, 1 = ref, 2 = SerDes, 3 = Ext
	uint32_t theValue = clockSource;
    [[self adapter] writeLongBlock:&theValue
						 atAddress:[self baseAddress] + fpga_register_information[kVMEGPControl].offset
                        numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) stepSerDesInit
{
    int i;
    switch(initializationState){
        case kSerDesSetup:
        [self writeRegister:kSDConfig           withValue: 0x00001c31]; //T/R SerDes off, reset clock manager, reset clocks
        [self writeRegister:kMasterLogicStatus  withValue: 0x04420001]; //power up value
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
            for(i=0;i<kNumGretina4Channels;i++){
                [self writeControlReg:i enabled:NO];
            }
            
            [self resetFIFO];
            [self setInitState:kReleaseClkManager];
            break;
        
        case kReleaseClkManager:
        //SERDES still disabled, release clk manager, clocks still held at reset
        [self writeRegister:kSDConfig           withValue: 0x00000c11];
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
        [self writeRegister:kSDConfig           withValue: 0x00000020]; //release the clocks
        
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4LockChanged object: self];
}

- (NSString*) serDesStateName
{
    switch(initializationState){
        case kSerDesIdle:           return @"Idle";
        case kSerDesSetup:          return @"Reset to power up state";
        case kFlushFifo:            return @"Flush FIFO";
        case kSetDigitizerClkSrc:   return @"Set the Clk Source";
        case kPowerUpRTPower:       return @"Power up T/R Power";
        case kSetMasterLogic:       return @"Write Master Logic = 0x20051";
        case kSetSDSyncBit:         return @"Write SD Sync Bit";
        case kSerDesError:          return @"Error";
        default:                    return @"?";
    }
}


- (void) resetMainFPGA
{
	uint32_t theValue = 0x10;
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

- (void) initBoard:(BOOL)doEnableChannels
{
	//find out the Main FPGA version
	uint32_t mainVersion = 0x00;
	[[self adapter] readLongBlock:&mainVersion
						atAddress:[self baseAddress] + register_information[kBoardID].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	//mainVersion = (mainVersion & 0xFFFF0000) >> 16;
	mainVersion = (mainVersion & 0xFFFFF000) >> 12;
	NSLog(@"Main FPGA version: 0x%x \n", mainVersion);
		
	if (mainVersion != kCurrentFirmwareVersion){
		NSLogColor([NSColor redColor],@"Main FPGA version does not match: it should be 0x%x, but now it is 0x%x \n", kCurrentFirmwareVersion,mainVersion);
		NSLog(@"Trying again\n");
        
        [[self adapter] readLongBlock:&mainVersion
                            atAddress:[self baseAddress] + register_information[kBoardID].offset
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        //mainVersion = (mainVersion & 0xFFFF0000) >> 16;
        mainVersion = (mainVersion & 0xFFFFF000) >> 12;
       	if (mainVersion != kCurrentFirmwareVersion){
            NSLogColor([NSColor redColor],@"Main FPGA version still does not match: it should be 0x%x, but now it is 0x%x \n", kCurrentFirmwareVersion,mainVersion);
            NSLogColor([NSColor redColor],@"Continuing, but be aware of the mismatch!!\n");
       }
	}
	
	//find out the VME FPGA version
	uint32_t vmeVersion = 0x00;
	[[self adapter] readLongBlock:&vmeVersion
						 atAddress:[self baseAddress] + fpga_register_information[kVMEFPGAVersionStatus].offset
                        numToRead:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	NSLog(@"VME FPGA serial number: 0x%x \n", (vmeVersion & 0x0000FFFF));
	NSLog(@"BOARD Revision number: 0x%x \n", ((vmeVersion & 0x00FF0000) >> 16));
	NSLog(@"VHDL Version number: 0x%x \n", ((vmeVersion & 0xFF000000) >> 24));
	
	
    //write the card level params
	int i;
	for(i=0;i<kNumGretina4CardParams;i++){
		uint32_t theValue = (uint32_t)[[cardInfo objectAtIndex:i] longValue];
		[[self adapter] writeLongBlock:&theValue
							atAddress:[self baseAddress] + cardConstants[i].regOffset
							numToWrite:1
							withAddMod:[self addressModifier]
							usingAddSpace:0x01];
	}
    [self writeClockSource];

	//write the channel level params
	if (doEnableChannels) {
		for(i=0;i<kNumGretina4Channels;i++) {
			[self writeControlReg:i enabled:[self enabled:i]];
			[self writeLEDThreshold:i];
			[self writeCFDParameters:i];
			[self writeRawDataSlidingLength:i];
			[self writeRawDataWindowLength:i];
		}
	}
	else {
		for(i=0;i<kNumGretina4Channels;i++) {
			[self writeLEDThreshold:i];
			[self writeCFDParameters:i];
			[self writeRawDataSlidingLength:i];
			[self writeRawDataWindowLength:i];
		}
	}
		
	[self writeDownSample];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4CardInited object:self];
}

- (uint32_t) readControlReg:(int)channel
{
    uint32_t theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kControlStatus].offset + 4*channel
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return theValue;
}

- (void) writeControlReg:(int)chan enabled:(BOOL)forceEnable
{
    /* writeControlReg writes the current model state to the board.  If forceEnable is NO, *
     * then all the channels are disabled.  Otherwise, the channels are enabled according  *
     * to the model state.                                                                 */
	
    BOOL startStop;
    if(forceEnable)	startStop= enabled[chan];
    else			startStop = NO;

    uint32_t theValue = (pzTraceEnabled[chan] << 14) | (poleZeroEnabled[chan] << 13) | (cfdEnabled[chan] << 12) | (polarity[chan] << 10) 
	| ((triggerMode[chan] & 0x3) << 3) | (pileUp[chan] << 2) | (debug[chan] << 1) | startStop;
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_information[kControlStatus].offset + 4*chan
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    uint32_t readBackValue = [self readControlReg:chan];
    if((readBackValue & 0xC1F) != (theValue & 0xC1F)){
        NSLogColor([NSColor redColor],@"Channel %d status reg readback != writeValue (0x%x != 0x%x)\n",chan,readBackValue & 0xC1F,theValue & 0xC1F);
    }
}

- (void) writeLEDThreshold:(int)channel
{    
    uint32_t theValue = ((poleZeroMult[channel]) << 20) | (ledThreshold[channel] & 0x1FFFF);
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_information[kLEDThreshold].offset + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    theValue = 0x0;
    if(triggerMode[channel] == kTrapezoidalTriggerMode) theValue = (1 << 31) | ledThreshold[channel];
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_information[kTrapezoidalTriggerReg].offset + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeCFDParameters:(int)channel
{    
    uint32_t theValue = ((cfdDelay[channel] & 0x3F) << 7) | ((cfdFraction[channel] & 0x3) << 5) | (cfdThreshold[channel]);
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_information[kCFDParameters].offset + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (void) writeRawDataSlidingLength:(int)channel
{    
    uint32_t theValue = (uint32_t)dataDelay[channel];
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[self baseAddress] + register_information[kRawDataSlidingLength].offset + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (void) writeRawDataWindowLength:(int)channel
{    
	uint32_t aValue = dataLength[channel];
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + register_information[kRawDataWindowLength].offset + 4*channel
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}


- (unsigned short) readFifoState
{
    uint32_t theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    if((theValue & kGretina4FIFOEmpty)!=0)		return kEmpty;
    else if((theValue & kGretina4FIFOAllFull)!=0)		return kFull;
    else if((theValue & kGretina4FIFOAlmostFull)!=0)	return kAlmostFull;
    else if((theValue & kGretina4FIFOAlmostEmpty)!=0)	return kAlmostEmpty;
    else						return kHalfFull;
}

- (void) writeDownSample
{
    uint32_t theValue = (downSample << 28);
    [[self adapter] writeLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToWrite:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
}

- (int) readCardInfo:(int) index
{
    uint32_t theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + cardConstants[index].regOffset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue & cardConstants[index].mask;
}

- (int) readExternalWindow { return [self readCardInfo:kExternalWindowIndex]; }

- (int) readPileUpWindow { return [self readCardInfo:kPileUpWindowIndex]; }

- (int) readNoiseWindow { return [self readCardInfo:kNoiseWindowIndex]; }

- (int) readExtTrigLength { return [self readCardInfo:kExtTrigLengthIndex]; }

- (int) readCollectionTime { return [self readCardInfo:kCollectionTimeIndex]; }

- (int) readIntegrationTime { return [self readCardInfo:kIntegrationTimeIndex]; }

- (uint32_t) readDownSample
{
    uint32_t theValue = 0 ;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[self baseAddress] + register_information[kProgrammingDone].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue >> 28;
}


- (int) clearFIFO
{
    /* clearFIFO clears the FIFO and then resets the enabled flags on the board to whatever *
     * was currently set *ON THE BOARD*.                                                    */
	int count = 0;

    fifoStateAddress  = [self baseAddress] + register_information[kProgrammingDone].offset;
    fifoAddress       = [self baseAddress] + 0x1000;
	theController     = [self adapter];
	uint32_t  dataDump[0xffff];
	BOOL errorFound		  = NO;
	//NSDate* startDate = [NSDate date];

    short boardStateEnabled[kNumGretina4Channels];
    short modelStateEnabled[kNumGretina4Channels];
    int i;
    for(i=0;i<kNumGretina4Channels;i++) {
        /* First thing, disable all the channels so that nothing is filling the buffer. */
        /* Reading the *BOARD STATE* (i.e. *not* the *MODEL* state) */
        boardStateEnabled[i] = [self readControlReg:i] & 0x1;
        modelStateEnabled[i] = [self enabled:i];
        [self writeControlReg:i enabled:NO];
    }
    NSDate* timeStarted = [NSDate date];
    while(1){
		if([[NSDate date] timeIntervalSinceDate:timeStarted]>10){
			NSLogColor([NSColor redColor], @"%@ unable to clear FIFO -- could be a serious hw problem.\n",[self fullID]);
			[NSException raise:@"Gretina Card Could not clear FIFO" format:@"%@ unable to clear FIFO -- could be a serious hw problem.",[self fullID]];
		}
		
		uint32_t val = 0;
		//read the fifo state
		[theController readLongBlock:&val
						   atAddress:fifoStateAddress
						   numToRead:1
						  withAddMod:[self addressModifier]
					   usingAddSpace:0x01];
		if((val & kGretina4FIFOEmpty) == 0){
			//read the first longword which should be the packet separator:
			uint32_t theValue;
			[theController readLongBlock:&theValue 
							   atAddress:fifoAddress 
							   numToRead:1 
							  withAddMod:[self addressModifier] 
						   usingAddSpace:0x01];
			
			if(theValue==kGretina4PacketSeparator){
				//read the first word of actual data so we know how much to read
				[theController readLongBlock:&theValue 
								   atAddress:fifoAddress 
								   numToRead:1 
								  withAddMod:[self addressModifier] 
							   usingAddSpace:0x01];
                                if(theValue == kGretina4PacketSeparator) {
				    NSLog(@"Clearing FIFO: got two packet separators in a row. Is the FIFO corrupted? (slot %d). \n",[self slot]);
				    break;
                                }
				
				[theController readLongBlock:dataDump 
								   atAddress:fifoAddress 
								   numToRead:((theValue & kGretina4NumberWordsMask)>>16)-1  //number longs left to read
								  withAddMod:[self addressModifier] 
							   usingAddSpace:0x01];
				count++;
			} 
			else {
				if (errorFound) {
					NSLog(@"Clearing FIFO: lost place in the FIFO twice, is the FIFO corrupted? (slot %d). \n",[self slot]);
					break;
				}
                NSLog(@"Clearing FIFO: FIFO corrupted on Gretina4 card (slot %d), searching for next event... \n",[self slot]);
                count += [self findNextEventInTheFIFO];
                NSLog(@"Clearing FIFO: Next event found on Gretina4 card (slot %d), continuing to clear FIFO. \n",[self slot]);
				errorFound = YES;
			}
		} 
		else { 
            /* The FIFO has been cleared. */
            break;
        }
		
    }
	
	[[self undoManager] disableUndoRegistration];
	@try {
		for(i=0;i<kNumGretina4Channels;i++) {
			/* Now reenable all the channels that were enabled before (on the *BOARD*). */
			[self setEnabled:i withValue:boardStateEnabled[i]];
			[self writeControlReg:i enabled:YES];
			[self setEnabled:i withValue:modelStateEnabled[i]];
		}
	}
	@catch(NSException* localException){
		@throw;
	}
	@finally {
		[[self undoManager] enableUndoRegistration];	
	}
	return count;
}

- (int) findNextEventInTheFIFO
{
    /* Somehow the FIFO got corrupted and is no longer aligned along event boundaries.           *
     * This function will read through to the next boundary and read out the next full event,    *
     * leaving the FIFO aligned along an event.  The function returns the number of events lost. */
    uint32_t val;
    //read the fifo state, sanity check to make sure there is actually another event.
    NSDate* timeStarted = [NSDate date];
    while(1){
		if([[NSDate date] timeIntervalSinceDate:timeStarted]>10){
			NSLogColor([NSColor redColor], @"%@ unable to find next event in FIFO -- could be a serious hw problem.\n",[self fullID]);
			[NSException raise:@"Gretina Card Could not find next event in FIFO" format:@"%@ unable to find next event in FIFO -- could be a serious hw problem.",[self fullID]];
		}
		
        [theController readLongBlock:&val
                           atAddress:fifoStateAddress
                           numToRead:1
                          withAddMod:[self addressModifier]
                       usingAddSpace:0x01];
        
        if((val & kGretina4FIFOEmpty) != 0) {
            /* We read until the FIFO is empty, meaning we are aligned */
            return 1; // We have only lost one event.
        } else {
            /* We need to continue reading until finding the packet separator */
            //read the first longword which should be the packet separator:
            uint32_t theValue;
            [theController readLongBlock:&theValue 
                               atAddress:fifoAddress 
                               numToRead:1 
                              withAddMod:[self addressModifier] 
                           usingAddSpace:0x01];
            
            if (theValue==kGretina4PacketSeparator) {
                //read the first word of actual data so we know how much to read
                [theController readLongBlock:&theValue 
                                   atAddress:fifoAddress 
                                   numToRead:1 
                                  withAddMod:[self addressModifier] 
                               usingAddSpace:0x01];
                uint32_t numberLeftToRead = ((theValue & kGretina4NumberWordsMask)>>16)-1;
                uint32_t* dataDump = malloc(sizeof(uint32_t)*numberLeftToRead);
                [theController readLongBlock:dataDump 
								   atAddress:fifoAddress 
								   numToRead:  numberLeftToRead //number longs left to read
								  withAddMod:[self addressModifier] 
							   usingAddSpace:0x01];
                free(dataDump);
                return 2; // We have lost two events
            }
            
            /* If we've gotten here, it means we have to continue some more. */
        } 
    }
}

- (void) findNoiseFloors
{
	if(noiseFloorRunning){
		noiseFloorRunning = NO;
	}
	else {
		noiseFloorState = 0;
		noiseFloorRunning = YES;
		[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:0];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4NoiseFloorChanged object:self];
}

- (void) stepNoiseFloor
{
	[[self undoManager] disableUndoRegistration];
	
    @try {
		uint32_t val;
		
		switch(noiseFloorState){
			case 0: //init
				//disable all channels
				[self initBoard:true];
				int i;
				for(i=0;i<kNumGretina4Channels;i++){
					oldEnabled[i] = [self enabled:i];
					[self setEnabled:i withValue:NO];
					[self writeControlReg:i enabled:NO];
					oldLEDThreshold[i] = [self ledThreshold:i];
					[self setLEDThreshold:i withValue:0x7fff];
					newLEDThreshold[i] = 0x7fff;
				}
				noiseFloorWorkingChannel = -1;
				//find first channel
				for(i=0;i<kNumGretina4Channels;i++){
					if(oldEnabled[i]){
						noiseFloorWorkingChannel = i;
						break;
					}
				}
				if(noiseFloorWorkingChannel>=0){
					noiseFloorLow			= 0;
					noiseFloorHigh		= 0x7FFF;
					noiseFloorTestValue	= 0x7FFF/2;              //Initial probe position
					[self setLEDThreshold:noiseFloorWorkingChannel withValue:noiseFloorHigh];
					[self writeLEDThreshold:noiseFloorWorkingChannel];
					[self setEnabled:noiseFloorWorkingChannel withValue:YES];
					[self writeControlReg:noiseFloorWorkingChannel enabled:YES];
					[self clearFIFO];
					noiseFloorState = 1;
				}
				else {
					noiseFloorState = 2; //nothing to do
				}
				break;
				
			case 1:
				if(noiseFloorLow <= noiseFloorHigh) {
					[self setLEDThreshold:noiseFloorWorkingChannel withValue:noiseFloorTestValue];
					[self writeLEDThreshold:noiseFloorWorkingChannel];
					noiseFloorState = 2;	//go check for data
				}
				else {
					newLEDThreshold[noiseFloorWorkingChannel] = noiseFloorTestValue + noiseFloorOffset;
					[self setEnabled:noiseFloorWorkingChannel withValue:NO];
					[self writeControlReg:noiseFloorWorkingChannel enabled:NO];
					[self setLEDThreshold:noiseFloorWorkingChannel withValue:0x7fff];
					[self writeLEDThreshold:noiseFloorWorkingChannel];
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
				
				if((val & kGretina4FIFOEmpty) == 0){
					//there's some data in fifo so we're too low with the threshold
					[self setLEDThreshold:noiseFloorWorkingChannel withValue:0x7fff];
					[self writeLEDThreshold:noiseFloorWorkingChannel];
					[self clearFIFO];
					noiseFloorLow = noiseFloorTestValue + 1;
				}
				else noiseFloorHigh = noiseFloorTestValue - 1;										//no data so continue lowering threshold
				noiseFloorTestValue = noiseFloorLow+((noiseFloorHigh-noiseFloorLow)/2);     //Next probe position.
				noiseFloorState = 1;	//continue with this channel
				break;
				
			case 3:
				//go to next channel
				noiseFloorLow		= 0;
				noiseFloorHigh		= 0x7FFF;
				noiseFloorTestValue	= 0x7FFF/2;              //Initial probe position
				//find first channel
				int startChan = noiseFloorWorkingChannel+1;
				noiseFloorWorkingChannel = -1;
				for(i=startChan;i<kNumGretina4Channels;i++){
					if(oldEnabled[i]){
						noiseFloorWorkingChannel = i;
						break;
					}
				}
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
				for(i=0;i<kNumGretina4Channels;i++){
					[self setEnabled:i withValue:oldEnabled[i]];
					[self setLEDThreshold:i withValue:newLEDThreshold[i]];
				}
				[self initBoard:true];
				noiseFloorRunning = NO;
				break;
		}
		if(noiseFloorRunning){
			[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:noiseFloorIntegrationTime];
		}
		else {
			[[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4NoiseFloorChanged object:self];
		}
    }
	@catch(NSException* localException) {
        int i;
        for(i=0;i<kNumGretina4Channels;i++){
            [self setEnabled:i withValue:oldEnabled[i]];
            [self setLEDThreshold:i withValue:oldLEDThreshold[i]];
        }
		NSLog(@"Gretina4 LED threshold finder quit because of exception\n");
    }
	[[self undoManager] enableUndoRegistration];
}

- (void) startDownLoadingMainFPGA
{
    {
        if(!progressLock)progressLock = [[NSLock alloc] init];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelFpgaDownProgressChanged object:self];
        
        stopDownLoadingMainFPGA = NO;
        
        //to minimize disruptions to the download thread we'll check and update the progress from the main thread via a timer.
        fpgaDownProgress = 0;
        
        if(![self controllerIsSBC]){
            [self setDownLoadMainFPGAInProgress: YES];
            [self updateDownLoadProgress];
            NSLog(@"Gretina4 (%d) beginning firmware load via Mac, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
            [NSThread detachNewThreadSelector:@selector(fpgaDownLoadThread:) toTarget:self withObject:[NSData dataWithContentsOfFile:fpgaFilePath]];
        }
        else {
            if([[[self adapter]sbcLink]isConnected]){
                [self setDownLoadMainFPGAInProgress: YES];
                NSLog(@"Gretina4 (%d) beginning firmware load via SBC, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
                [self copyFirmwareFileToSBC:fpgaFilePath];
            }
            else {
                [self setDownLoadMainFPGAInProgress: NO];
                NSLog(@"Gretina4 (%d) unable to load firmware. SBC not connected.\n",[self uniqueIdNumber]);
            }
        }
    }
}
- (void) flashFpgaStatus:(ORSBCLinkJobStatus*) jobStatus
{
    [self setDownLoadMainFPGAInProgress: [jobStatus running]];
    [self setFpgaDownProgress:           (int)[jobStatus progress]];
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

- (void) readFPGAVersions
{
    //find out the VME FPGA version
	uint32_t vmeVersion = 0x00;
	[[self adapter] readLongBlock:&vmeVersion
                        atAddress:[self baseAddress] + fpga_register_information[kVMEFPGAVersionStatus].offset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
	NSLog(@"VME FPGA serial number: 0x%x \n", (vmeVersion & 0x0000FFFF));
	NSLog(@"BOARD Revision number: 0x%x \n", ((vmeVersion & 0x00FF0000) >> 16));
	NSLog(@"VME FPGA Version number: 0x%x \n", ((vmeVersion & 0xFF000000) >> 24));
}
- (BOOL) checkFirmwareVersion
{
    return [self checkFirmwareVersion:NO];
}

- (BOOL) checkFirmwareVersion:(BOOL)verbose
{
	//find out the Main FPGA version
	uint32_t mainVersion = 0x00;
	[[self adapter] readLongBlock:&mainVersion
						atAddress:[self baseAddress] + register_information[kBoardID].offset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	//mainVersion = (mainVersion & 0xFFFF0000) >> 16;
	mainVersion = (mainVersion & 0xFFFFF000) >> 12;
	if(verbose)NSLog(@"Main FPGA version: 0x%x \n", mainVersion);
    
	if (mainVersion != kCurrentFirmwareVersion){
		NSLog(@"Main FPGA version does not match: 0x%x is required but 0x%x is loaded.\n", kCurrentFirmwareVersion,mainVersion);
		return NO;
	}
    else return YES;
}

- (void) writeToAddress:(uint32_t)anAddress aValue:(uint32_t)aValue
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + anAddress
                        numToWrite:1
					    withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
    
}
- (uint32_t) readFromAddress:(uint32_t)anAddress
{
    uint32_t value = 0;
    [[self adapter] readLongBlock:&value
                        atAddress:[self baseAddress] + anAddress
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return value;
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


#pragma mark ¥¥¥Data Taker
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
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
								 @"ORGretina4WaveformDecoder",             @"decoder",
								 [NSNumber numberWithLong:dataId],        @"dataId",
								 [NSNumber numberWithBool:YES],           @"variable",
								 [NSNumber numberWithLong:-1],			 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Gretina4"];
    
    return dataDictionary;
}


#pragma mark ¥¥¥HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (int) numberOfChannels
{
    return kNumGretina4Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"External Window"];
    [p setFormat:@"##0" upperLimit:0x7ff lowerLimit:0 stepSize:1 units:cardConstants[kExternalWindowIndex].units];
    [p setSetMethod:@selector(setExternalWindow:) getMethod:@selector(externalWindowAsInt)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pileup Window"];
    [p setFormat:@"##0" upperLimit:0x7ff lowerLimit:0 stepSize:1 units:cardConstants[kPileUpWindowIndex].units];
    [p setSetMethod:@selector(setPileUpWindow:) getMethod:@selector(pileUpWindowAsInt)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Noise Window"];
    [p setFormat:@"##0" upperLimit:0x3f lowerLimit:0 stepSize:1 units:cardConstants[kNoiseWindowIndex].units];
    [p setSetMethod:@selector(setNoiseWindow:) getMethod:@selector(noiseWindowAsInt)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Ext Trig Length"];
    [p setFormat:@"##0" upperLimit:0x7ff lowerLimit:0 stepSize:1 units:cardConstants[kExtTrigLengthIndex].units];
    [p setSetMethod:@selector(setExtTrigLength:) getMethod:@selector(extTrigLengthAsInt)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Collection Time"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:cardConstants[kCollectionTimeIndex].units];
    [p setSetMethod:@selector(setCollectionTime:) getMethod:@selector(collectionTimeAsInt)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Integration Time"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:cardConstants[kIntegrationTimeIndex].units];
    [p setSetMethod:@selector(setIntegrationTime:) getMethod:@selector(integrationTimeAsInt)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Polarity"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPolarity:withValue:) getMethod:@selector(polarity:)];
    [a addObject:p];
    
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
    [p setName:@"Debug Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setDebug:withValue:) getMethod:@selector(debug:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"LED Threshold"];
    [p setFormat:@"##0" upperLimit:0x7fff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setLEDThreshold:withValue:) getMethod:@selector(ledThreshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CFD Delay"];
    [p setFormat:@"##0" upperLimit:630 lowerLimit:0 stepSize:1 units:@"ns"];
    [p setSetMethod:@selector(setCFDDelayConverted:withValue:) getMethod:@selector(cfdDelayConverted:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CFD Fraction"];
    [p setFormat:@"##0" upperLimit:0x3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setCFDFraction:withValue:) getMethod:@selector(cfdFraction:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"CFD Threshold"];
    [p setFormat:@"##0.0" upperLimit:160 lowerLimit:0 stepSize:1 units:@"Kev"];
	[p setCanBeRamped:YES];
    [p setSetMethod:@selector(setCFDThresholdConverted:withValue:) getMethod:@selector(cfdThresholdConverted:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:0x2 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Data Delay"];
    [p setFormat:@"##0.00" upperLimit:4.5 lowerLimit:0 stepSize:.01 units:@"us"];
    [p setSetMethod:@selector(setDataDelayConverted:withValue:) getMethod:@selector(dataDelayConverted:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Data Length"];
    [p setFormat:@"##0" upperLimit:0x7FF lowerLimit:1 stepSize:1 units:@"ns"];
    [p setSetMethod:@selector(setTraceLengthConverted:withValue:) getMethod:@selector(traceLengthConverted:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Down Sample"];
    [p setFormat:@"##0" upperLimit:4 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setDownSample:) getMethod:@selector(downSample)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Hist E Multiplier"];
    [p setFormat:@"##0" upperLimit:100 lowerLimit:1 stepSize:1 units:@""];
    [p setSetMethod:@selector(setHistEMultiplier:) getMethod:@selector(histEMultiplier)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:YES];
    [p setOncePerCard:YES];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard:)];
    [a addObject:p];
    
    return a;
}


- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORGretina4Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORGretina4Model"]];
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
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORGretina4Model"];    
 
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
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16) | serialNumber;
    theController   = [self adapter];
    fifoAddress     = [self baseAddress] + 0x1000;
    fifoStateAddress= [self baseAddress] + register_information[kProgrammingDone].offset;
    
    short i;
    for(i=0;i<kNumGretina4Channels;i++) {
        [self writeControlReg:i enabled:NO];
    }
    [self clearFIFO];
    fifoLostEvents = 0;
    dataBuffer = (uint32_t*)malloc(0xffff * sizeof(uint32_t));
    [self startRates];
    
    [self initBoard:true];
    
	[self performSelector:@selector(checkFifoAlarm) withObject:nil afterDelay:1];
    isRunning = NO;
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
        uint32_t val;
        //read the fifo state
        [theController readLongBlock:&val
                           atAddress:fifoStateAddress
                           numToRead:1
                          withAddMod:[self addressModifier]
                       usingAddSpace:0x01];
        fifoState = val;			
        if((val & kGretina4FIFOEmpty) == 0){
            uint32_t numLongs = 0;
            dataBuffer[numLongs++] = dataId | 0; //we'll fill in the length later
            dataBuffer[numLongs++] = location;
            
            //read the first longword which should be the packet separator:
            uint32_t theValue;
            [theController readLongBlock:&theValue 
                               atAddress:fifoAddress 
                               numToRead:1 
                              withAddMod:[self addressModifier] 
                           usingAddSpace:0x01];
            
            if(theValue==kGretina4PacketSeparator){
                
                //read the first word of actual data so we know how much to read
                [theController readLongBlock:&theValue 
                                   atAddress:fifoAddress 
                                   numToRead:1 
                                  withAddMod:[self addressModifier] 
                               usingAddSpace:0x01];
                
                dataBuffer[numLongs++] = theValue;
                
                ++waveFormCount[theValue & 0x7];  //grab the channel and inc the count
                
                uint32_t numLongsLeft  = ((theValue & kGretina4NumberWordsMask)>>16)-1;
                
                [theController readLong:&dataBuffer[numLongs] 
                              atAddress:fifoAddress 
                            timesToRead:numLongsLeft 
                             withAddMod:[self addressModifier] 
                          usingAddSpace:0x01];
				
                int32_t totalNumLongs = (numLongs + numLongsLeft);
                dataBuffer[0] |= totalNumLongs; //see, we did fill it in...
                [aDataPacket addLongsToFrameBuffer:dataBuffer length:totalNumLongs];
            } else {
                //oops... the buffer read is out of sequence
                NSLogError([NSString stringWithFormat:@"slot %d",[self slot]],@"Packet Sequence Error -- Looking for next event",@"Gretina4",nil);
                fifoLostEvents += [self findNextEventInTheFIFO];
                NSLogError(@"Packet Sequence Error -- Next event found",@"Gretina4",[NSString stringWithFormat:@"slot %d",[self slot]],nil);
            }
        }
		
    }
	@catch(NSException* localException) {
        NSLogError(@"",@"Gretina4 Card Error",errorLocation,nil);
        [self incExceptionCount];
        [localException raise];
    }
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    @try {
		/* Disable all channels.  The remaining buffer should be readout. */
		int i;
		for(i=0;i<kNumGretina4Channels;i++){					
			[self writeControlReg:i enabled:NO];
		}
	}
	@catch(NSException* e){
        [self incExceptionCount];
        NSLogError(@"",@"Gretina4 Card Error",nil);
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
    //stop all channels
    short i;
    for(i=0;i<kNumGretina4Channels;i++){					
		waveFormCount[i] = 0;
    }
    free(dataBuffer);
    if ( fifoLostEvents != 0 ) {
        NSLogError( [NSString stringWithFormat:@" lost events due to buffer corruption: %d",fifoLostEvents],@"Gretina4 ",[NSString stringWithFormat:@"(slot %d):",[self slot]],
				   nil);
    }
}

- (void) checkFifoAlarm
{
	if(((fifoState & kGretina4FIFOAlmostFull) != 0) && isRunning){
		fifoEmptyCount = 0;
		if(!fifoFullAlarm){
			NSString* alarmName = [NSString stringWithFormat:@"FIFO Almost Full Gretina4 (slot %d)",[self slot]];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelFIFOCheckChanged object:self];
}

- (void) reset
{
}


- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(isRunning)return NO;
    
    ++waveFormCount[channel];
    return YES;
}

- (uint32_t) waveFormCount:(int)aChannel
{
    return waveFormCount[aChannel];
}

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumGretina4Channels;i++){
        waveFormCount[i]=0;
    }
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
	configStruct->card_info[index].hw_type_id	= kGretina; //should be unique
	configStruct->card_info[index].hw_mask[0] 	=  dataId; //better be unique
	configStruct->card_info[index].slot			= [self slot];
	configStruct->card_info[index].crate		= [self crateNumber];
	configStruct->card_info[index].add_mod		= [self addressModifier];
	configStruct->card_info[index].base_add		= [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0]	= ([self baseAddress] + register_information[kProgrammingDone].offset); //fifoStateAddress
    configStruct->card_info[index].deviceSpecificData[1]	= kGretina4FIFOEmpty; // fifoEmptyMask
    configStruct->card_info[index].deviceSpecificData[2]	= ([self baseAddress] + 0x1000); // fifoAddress
    configStruct->card_info[index].deviceSpecificData[3]	= 0x0B; // fifoAM
    configStruct->card_info[index].deviceSpecificData[4]	= 0x1FFFF; // size of FIFO
    configStruct->card_info[index].deviceSpecificData[5]	= location; // crate,card,serial
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setSpiConnector:			    [decoder decodeObjectForKey:@"spiConnector"]];
    [self setLinkConnector:			    [decoder decodeObjectForKey:@"linkConnector"]];
    [self setDownSample:				[decoder decodeIntForKey:@"downSample"]];
    [self setHistEMultiplier:		    [decoder decodeIntForKey:@"histEMultiplier"]];
    [self setRegisterIndex:				[decoder decodeIntForKey:@"registerIndex"]];
    [self setRegisterWriteValue:		[decoder decodeIntForKey:@"registerWriteValue"]];
    [self setSPIWriteValue:     		[decoder decodeIntForKey:@"spiWriteValue"]];
    [self setFpgaFilePath:				[decoder decodeObjectForKey:@"fpgaFilePath"]];
    [self setNoiseFloorIntegrationTime:	[decoder decodeFloatForKey:@"NoiseFloorIntegrationTime"]];
    [self setNoiseFloorOffset:			[decoder decodeIntForKey:@"NoiseFloorOffset"]];
    cardInfo = [[decoder decodeObjectForKey:@"cardInfo"] retain];
    
    
    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumGretina4Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
    [self setClockSource:               [decoder decodeIntegerForKey:@"clockSource"]];
	
	int i;
	for(i=0;i<kNumGretina4Channels;i++){
		[self setEnabled:i		withValue:[decoder decodeIntegerForKey:[@"enabled"	    stringByAppendingFormat:@"%d",i]]];
		[self setDebug:i		withValue:[decoder decodeIntegerForKey:[@"debug"	    stringByAppendingFormat:@"%d",i]]];
		[self setPileUp:i		withValue:[decoder decodeIntegerForKey:[@"pileUp"	    stringByAppendingFormat:@"%d",i]]];
		[self setCFDEnabled:i 	withValue:[decoder decodeIntegerForKey:[@"cfdEnabled"   stringByAppendingFormat:@"%d",i]]];
		[self setPoleZeroEnabled:i withValue:[decoder decodeIntegerForKey:[@"poleZeroEnabled" stringByAppendingFormat:@"%d",i]]];
		[self setPoleZeroMultiplier:i withValue:[decoder decodeIntegerForKey:[@"poleZeroMult" stringByAppendingFormat:@"%d",i]]];
		[self setPZTraceEnabled:i withValue:[decoder decodeIntegerForKey:[@"pzTraceEnabled" stringByAppendingFormat:@"%d",i]]];
		[self setPolarity:i		withValue:[decoder decodeIntForKey:[@"polarity"     stringByAppendingFormat:@"%d",i]]];
		[self setTriggerMode:i	withValue:[decoder decodeIntForKey:[@"triggerMode"	stringByAppendingFormat:@"%d",i]]];
		[self setLEDThreshold:i withValue:[decoder decodeIntForKey:[@"ledThreshold" stringByAppendingFormat:@"%d",i]]];
		[self setCFDThreshold:i withValue:[decoder decodeIntForKey:[@"cfdThreshold" stringByAppendingFormat:@"%d",i]]];
		[self setCFDDelay:i		withValue:[decoder decodeIntForKey:[@"cfdDelay"		stringByAppendingFormat:@"%d",i]]];
		[self setCFDFraction:i	withValue:[decoder decodeIntForKey:[@"cfdFraction"	stringByAppendingFormat:@"%d",i]]];
		[self setDataDelay:i	withValue:[decoder decodeIntForKey:[@"dataDelay"	stringByAppendingFormat:@"%d",i]]];
		[self setDataLength:i	withValue:[decoder decodeIntForKey:[@"dataLength"	stringByAppendingFormat:@"%d",i]]];
	}
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:spiConnector				forKey:@"spiConnector"];
    [encoder encodeObject:linkConnector				forKey:@"linkConnector"];
    [encoder encodeInt:downSample			        forKey:@"downSample"];
    [encoder encodeInt:histEMultiplier          forKey:@"histEMultiplier"];
    [encoder encodeInt:registerIndex		    forKey:@"registerIndex"];
    [encoder encodeInt:registerWriteValue		forKey:@"registerWriteValue"];
    [encoder encodeInt:spiWriteValue			forKey:@"spiWriteValue"];
    [encoder encodeObject:fpgaFilePath				forKey:@"fpgaFilePath"];
    [encoder encodeFloat:noiseFloorIntegrationTime	forKey:@"NoiseFloorIntegrationTime"];
    [encoder encodeInt:noiseFloorOffset		    forKey:@"NoiseFloorOffset"];
    [encoder encodeObject:cardInfo					forKey:@"cardInfo"];
    [encoder encodeObject:waveFormRateGroup			forKey:@"waveFormRateGroup"];
    [encoder encodeInteger:clockSource              forKey:@"clockSource"];
	int i;
 	for(i=0;i<kNumGretina4Channels;i++){
		[encoder encodeInteger:enabled[i]		forKey:[@"enabled"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:debug[i]			forKey:[@"debug"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:pileUp[i]		forKey:[@"pileUp"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:cfdEnabled[i]  	forKey:[@"cfdEnabled"  	stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:poleZeroEnabled[i] forKey:[@"poleZeroEnabled" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:poleZeroMult[i]  forKey:[@"poleZeroMult" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:pzTraceEnabled[i] forKey:[@"pzTraceEnabled" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:polarity[i]		forKey:[@"polarity"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:triggerMode[i]	forKey:[@"triggerMode"	stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:cfdFraction[i]	forKey:[@"cfdFraction"	stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:cfdDelay[i]		forKey:[@"cfdDelay"		stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:cfdThreshold[i]	forKey:[@"cfdThreshold" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:ledThreshold[i]	forKey:[@"ledThreshold" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:dataDelay[i]		forKey:[@"dataDelay"	stringByAppendingFormat:@"%d",i]];
		[encoder encodeInteger:dataLength[i]	forKey:[@"dataLength"	stringByAppendingFormat:@"%d",i]];
	}
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    short i;
    for(i=0;i<kNumGretina4CardParams;i++){
        [objDictionary setObject:[self cardInfo:i] forKey:cardConstants[i].name];
    }  
	[self addCurrentState:objDictionary cArray:enabled forKey:@"Enabled"];
	[self addCurrentState:objDictionary cArray:debug forKey:@"Debug Mode"];
	[self addCurrentState:objDictionary cArray:pileUp forKey:@"Pile Up"];
	[self addCurrentState:objDictionary cArray:polarity forKey:@"Polarity"];
	[self addCurrentState:objDictionary cArray:triggerMode forKey:@"Trigger Mode"];
	[self addCurrentState:objDictionary cArray:cfdDelay forKey:@"CFD Delay"];
	[self addCurrentState:objDictionary cArray:cfdFraction forKey:@"CFD Fraction"];
	[self addCurrentState:objDictionary cArray:cfdThreshold forKey:@"CFD Threshold"];
	[self addCurrentState:objDictionary cArray:dataDelay forKey:@"Data Delay"];
	[self addCurrentState:objDictionary cArray:dataLength forKey:@"Data Length"];
	[self addCurrentState:objDictionary cArray:cfdEnabled forKey:@"CFD Enabled"];
	[self addCurrentState:objDictionary cArray:poleZeroEnabled forKey:@"Pole Zero Enabled"];
	[self addCurrentState:objDictionary cArray:poleZeroMult forKey:@"Pole Zero Multiplier"];
	[self addCurrentState:objDictionary cArray:pzTraceEnabled forKey:@"PZ Trace Enabled"];
    
    NSMutableArray* ar = [NSMutableArray array];
	for(i=0;i<kNumGretina4Channels;i++){
		[ar addObject:[NSNumber numberWithLong:ledThreshold[i]]];
	}
    [objDictionary setObject:ar forKey:@"LED Threshold"];
    [objDictionary setObject:[NSNumber numberWithInt:downSample] forKey:@"Down Sample"];
    [objDictionary setObject:[NSNumber numberWithInt:clockSource]       forKey:@"Clock Source"];
    [objDictionary setObject:[NSNumber numberWithInt:histEMultiplier] forKey:@"Hist E Multiplier"];
	
	
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(short*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<kNumGretina4Channels;i++){
		[ar addObject:[NSNumber numberWithShort:*anArray]];
		anArray++;
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


#pragma mark ¥¥¥SPI Interface
- (uint32_t) writeAuxIOSPI:(uint32_t)spiData
{
    // Set AuxIO to mode 3 and set bits 0-3 to OUT (bit 0 is under FPGA control)
    [self writeRegister:kAuxIOConfig withValue:0x3025];
    // Read kAuxIOWrite to preserve bit 0, and zero bits used in SPI protocol
    uint32_t spiBase = [self readRegister:kAuxIOWrite] & ~(kSPIData | kSPIClock | kSPIChipSelect); 
    uint32_t value;
    uint32_t readBack = 0;
	
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
- (BOOL) controllerIsSBC
{
    //int32_t removeReturn;
    //return NO; //<<----- temp for testing
    if([[self adapter] isKindOfClass:NSClassFromString(@"ORVmecpuModel")])return YES;
    else return NO;
}

#pragma mark ***AdcProviding Protocol
- (void) initBoard
{
    int i;
    for(i=0;i<kNumGretina4Channels;i++) {
        [self writeLEDThreshold:i];
    }
}

- (uint32_t) thresholdForDisplay:(unsigned short) aChan
{
    return [self ledThreshold:aChan];
}

- (unsigned short) gainForDisplay:(unsigned short) aChan
{
    return 0;
}

- (BOOL) onlineMaskBit:(int)bit
{
    return [self enabled:bit];
}

- (BOOL) partOfEvent:(unsigned short)aChannel
{
    //included to satisfy the protocol... change if needed
    return NO;
}

- (uint32_t) eventCount:(int)aChannel
{
    return waveFormCount[aChannel];
}

- (void) clearEventCounts
{
    int i;
    for(i=0;i<kNumGretina4Channels;i++){
        waveFormCount[i]=0;
    }
}
- (void) postAdcInfoProvidingValueChanged
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ORAdcInfoProvidingValueChanged
     object:self
     userInfo: nil];
}

@end
@implementation ORGretina4Model (private)

- (void) updateDownLoadProgress
{
	//call only from main thread
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ModelFpgaDownProgressChanged object:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:(self) selector:@selector(updateDownLoadProgress) object:nil];
	if(downLoadMainFPGAInProgress)[self performSelector:@selector(updateDownLoadProgress) withObject:nil afterDelay:.1];
}

- (void) setFpgaDownProgress:(int)aFpgaDownProgress
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
                NSLog(@"Gretina4(%d): Verification FAILED\n",[self uniqueIdNumber]);
				[NSException raise:@"Gretina4 Exception" format:@"Verification of flash failed."];
			}
            else {
                //reload the fpga from flash
                [self writeToAddress:0x900 aValue:kGretina4ResetMainFPGACmd];
                [self writeToAddress:0x900 aValue:kGretina4ReloadMainFPGACmd];
                [self setProgressStateOnMainThread:  @"Finishing$Flash Memory-->FPGA"];
                uint32_t statusRegValue = [self readFromAddress:0x904];
                while(!(statusRegValue & kGretina4MainFPGAIsLoaded)) {
                    if(stopDownLoadingMainFPGA)return;
                    statusRegValue = [self readFromAddress:0x904];
                }

                NSLog(@"Gretina4(%d): FPGA Load Finished - No Errors\n",[self uniqueIdNumber]);
            }
		}
		[self setProgressStateOnMainThread:@"Flash->FPGA"];
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
    [self writeToAddress:0x910 aValue:kGretina4FlashEnableWrite]; //Enable programming
	[self setFpgaDownProgress:0.];
    uint32_t count = 0;
    uint32_t end = (kGretina4FlashBlocks / 4) * kGretina4FlashBlockSize;
    uint32_t addr;
    [self setProgressStateOnMainThread:  @"Block Erase"];
    for (addr = 0; addr < end; addr += kGretina4FlashBlockSize) {
        
		if(stopDownLoadingMainFPGA)return;
		@try {
            [self setFirmwareStatusString:       [NSString stringWithFormat:@"%u of %d Blocks Erased",count,kGretina4FlashBufferBytes]];
 			[self setFpgaDownProgress: 100. * (count+1)/(float)kGretina4UsedFlashBlocks];
            
            [self writeToAddress:0x980 aValue:addr];
            [self writeToAddress:0x98C aValue:kGretina4FlashBlockEraseCmd];
            [self writeToAddress:0x98C aValue:kGretina4FlashConfirmCmd];
            uint32_t stat = [self readFromAddress:0x904];
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
    uint32_t totalSize =(uint32_t) [theData length];
    
    [self setProgressStateOnMainThread:@"Programming"];
    [self setFirmwareStatusString: [NSString stringWithFormat:@"FPGA File Size %u KB",totalSize/1000]];
    [self setFpgaDownProgress:0.];
    
    [self writeToAddress:0x980 aValue:0x00];
    [self writeToAddress:0x98C aValue:kGretina4FlashReadArrayCmd];
    
    uint32_t address = 0x0;
    while (address < totalSize ) {
        uint32_t numberBytesToWrite;
        if(totalSize-address >= kGretina4FlashBufferBytes){
            numberBytesToWrite = kGretina4FlashBufferBytes; //whole block
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
    [self writeToAddress:0x98C aValue:kGretina4FlashReadArrayCmd];
    [self writeToAddress:0x910 aValue:0x00];
    
    [self setProgressStateOnMainThread:@"Programming"];
}

- (void) programFlashBufferBlock:(NSData*)theData address:(uint32_t)anAddress numberBytes:(uint32_t)aNumber
{
    //issue the set-up command at the starting address
    [self writeToAddress:0x980 aValue:anAddress];
    [self writeToAddress:0x98C aValue:kGretina4FlashWriteCmd];
    unsigned char* theDataBytes = (unsigned char*)[theData bytes];
    uint32_t statusRegValue;
	while(1) {
        if(stopDownLoadingMainFPGA)return;
		
		// Checking status to make sure that flash is ready
        uint32_t statusRegValue = [self readFromAddress:0x904];
		
		if ( (statusRegValue & kFlashBusy)  == kFlashBusy ) {
            //not ready, so re-issue the set-up command
            [self writeToAddress:0x980 aValue:anAddress];
            [self writeToAddress:0x98C aValue:kGretina4FlashWriteCmd];
		}
        else break;
	}
    
	//Set the word count. Max is 0xF.
	uint32_t valueToWrite = (aNumber/2) - 1;
    [self writeToAddress:0x98C aValue:valueToWrite];
	
	// Loading all the words in
    /* Load the words into the bufferToWrite */
	uint32_t i;
	for ( i=0; i<aNumber; i+=4 ) {
        uint32_t* lPtr = (uint32_t*)&theDataBytes[anAddress+i];
        [self writeToAddress:0x984 aValue:lPtr[0]];
	}
	
	// Confirm the write
    [self writeToAddress:0x98C aValue:kGretina4FlashConfirmCmd];
	
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
    [self writeToAddress:0x98C aValue:kGretina4FlashReadArrayCmd];
    
    uint32_t errorCount =   0;
    uint32_t address    =   0;
    uint32_t valueToCompare;
    
    while ( address < totalSize ) {
        uint32_t valueToRead = [self readFromAddress:0x984];
        
        /* Now compare to file*/
        if ( address + 3 < totalSize) {
            uint32_t* ptr = (uint32_t*)&theDataBytes[address];
            valueToCompare = ptr[0];
        }
        else {
            //less than four bytes left
            uint32_t numBytes = totalSize - address - 1;
            valueToCompare = 0;
            uint32_t i;
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
    
    [self writeToAddress:0x900 aValue:kGretina4ResetMainFPGACmd];
    [self writeToAddress:0x900 aValue:kGretina4ReloadMainFPGACmd];
	
    uint32_t statusRegValue=[self readFromAddress:0x904];
    
    while(!(statusRegValue & kGretina4MainFPGAIsLoaded)) {
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
            NSLog(@"Gretina4 (%d) launching firmware load job in SBC\n",[self uniqueIdNumber]);
            
            [[[self adapter] sbcLink] send:&aPacket receive:&aPacket];
            
            [[[self adapter] sbcLink] monitorJobFor:self statusSelector:@selector(flashFpgaStatus:)];
            
        }
        @catch(NSException* e){
            
        }
    }
}

@end
