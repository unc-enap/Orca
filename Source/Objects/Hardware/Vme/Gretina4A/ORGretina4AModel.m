//-------------------------------------------------------------------------
//  ORGretina4AModel.m
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

#pragma mark - Imported Files
#import "ORGretina4AModel.h"
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

#define kCurrentFirmwareVersion 0x1
#define kFPGARemotePath @"GretinaFPGA.bin"

//===Register Notifications===
NSString* ORGretina4AExtDiscrimitorSrcChanged           = @"ORGretina4AExtDiscrimitorSrcChanged";
NSString* ORGretina4AHardwareStatusChanged              = @"ORGretina4AHardwareStatusChanged";
NSString* ORGretina4AUserPackageDataChanged             = @"ORGretina4AUserPackageDataChanged";
NSString* ORGretina4AWindowCompMinChanged               = @"ORGretina4AWindowCompMinChanged";
NSString* ORGretina4AWindowCompMaxChanged               = @"ORGretina4AWindowCompMaxChanged";
//---channel control parts---
NSString* ORGretina4APileupWaveformOnlyModeChanged      = @"ORGretina4APileupWaveformOnlyModeChanged";
NSString* ORGretina4APileupExtensionModeChanged         = @"ORGretina4APileupExtensionModeChanged";
NSString* ORGretina4ADiscCountModeChanged               = @"ORGretina4ADiscCountModeChanged";
NSString* ORGretina4AAHitCountModeChanged               = @"ORGretina4AAHitCountModeChanged";
NSString* ORGretina4AEventCountModeChanged              = @"ORGretina4AEventCountModeChanged";
NSString* ORGretina4ADroppedEventCountModeChanged       = @"ORGretina4ADroppedEventCountModeChanged";
//NSString* ORGretina4AWriteFlagChanged                   = @"ORGretina4AWriteFlagChanged";
NSString* ORGretina4ADecimationFactorChanged            = @"ORGretina4ADecimationFactorChanged";
NSString* ORGretina4ATriggerPolarityChanged             = @"ORGretina4ATriggerPolarityChanged";
NSString* ORGretina4APileupModeChanged                  = @"ORGretina4APileupModeChanged";
NSString* ORGretina4AEnabledChanged                     = @"ORGretina4AEnabledChanged";
//---------
NSString* ORGretina4ALedThreshold0Changed               = @"ORGretina4ALedThreshold0Changed";
NSString* ORGretina4ARawDataLengthChanged               = @"ORGretina4ARawDataLengthChanged";
NSString* ORGretina4ARawDataWindowChanged               = @"ORGretina4ARawDataWindowChanged";
NSString* ORGretina4ADWindowChanged                     = @"ORGretina4ADWindowChanged";
NSString* ORGretina4AKWindowChanged                     = @"ORGretina4AKWindowChanged";
NSString* ORGretina4AMWindowChanged                     = @"ORGretina4AMWindowChanged";
NSString* ORGretina4AD3WindowChanged                    = @"ORGretina4AD3WindowChanged";
NSString* ORGretina4ADiscWidthChanged                   = @"ORGretina4ADiscWidthChanged";
NSString* ORGretina4ABaselineStartChanged               = @"ORGretina4ABaselineStart0Changed";
NSString* ORGretina4AP1WindowChanged                     = @"ORGretina4AP1WindowChanged";
NSString* ORGretina4AP2WindowChanged                     = @"ORGretina4AP2WindowChanged";
//---DAC Config---
NSString* ORGretina4ADacChannelSelectChanged            = @"ORGretina4ADacChannelSelectChanged";
NSString* ORGretina4ADacAttenuationChanged              = @"ORGretina4ADacAttenuationChanged";
//------
NSString* ORGretina4AChannelPulseControlChanged         = @"ORGretina4AChannelPulseControlChanged";
NSString* ORGretina4ADiagMuxControlChanged              = @"ORGretina4ADiagMuxControlChanged";
NSString* ORGretina4ADownSampleHoldOffTimeChanged       = @"ORGretina4ADownSampleHoldOffTimeChanged";
NSString* ORGretina4ADownSamplePauseEnableChanged       = @"ORGretina4ADownSamplePauseEnableChanged";
NSString* ORGretina4AHoldOffTimeChanged                 = @"ORGretina4AHoldOffTimeChanged";
NSString* ORGretina4APeakSensitivityChanged             = @"ORGretina4APeakSensitivityChanged";
NSString* ORGretina4AAutoModeChanged                    = @"ORGretina4AAutoModeChanged";
//---Baseline Delay---
NSString* ORGretina4ABaselineDelayChanged               = @"ORGretina4ABaselineDelayChanged";
NSString* ORGretina4ATrackingSpeedChanged               = @"ORGretina4ATrackingSpeedChanged";
NSString* ORGretina4ABaselineStatusChanged              = @"ORGretina4ABaselineStatusChanged";
//---ORGretina4ABaselineStatusChanged//------
NSString* ORGretina4ADiagInputChanged                   = @"ORGretina4ADiagInputChanged";
NSString* ORGretina4ADiagChannelEventSelChanged         = @"ORGretina4ADiagChannelEventSelChanged";
NSString* ORGretina4AExtDiscriminatorModeChanged        = @"ORGretina4AExtDiscriminatorModeChanged";
NSString* ORGretina4ARj45SpareIoDirChanged              = @"ORGretina4ARj45SpareIoDirChanged"; //<<some more
NSString* ORGretina4ARj45SpareIoMuxSelChanged           = @"ORGretina4ARj45SpareIoMuxSelChanged";
NSString* ORGretina4ALedStatusChanged                   = @"ORGretina4ALedStatusChanged";
NSString* ORGretina4AVetoGateWidthChanged               = @"ORGretina4AVetoGateWidthChanged";
//---Master Logic Status
NSString* ORGretina4ADiagIsyncChanged                   = @"ORGretina4ADiagIsyncChanged";//<<some more
NSString* ORGretina4AOverflowFlagChanChanged            = @"ORGretina4AOverflowFlagChanChanged";
NSString* ORGretina4ASerdesSmLostLockChanged            = @"ORGretina4ASerdesSmLostLockChanged";
//------
NSString* ORGretina4ATriggerConfigChanged               = @"ORGretina4ATriggerConfigChanged";
NSString* ORGretina4APhaseErrorCountChanged             = @"ORGretina4APhaseErrorCountChanged";
NSString* ORGretina4APhaseStatusChanged                 = @"ORGretina4APhaseStatusChanged";
NSString* ORGretina4ASerdesPhaseValueChanged            = @"ORGretina4ASerdesPhaseValueChanged";
NSString* ORGretina4AMjrCodeRevisionChanged             = @"ORGretina4AMjrCodeRevisionChanged";
NSString* ORGretina4AMinCodeRevisionChanged             = @"ORGretina4AMinCodeRevisionChanged";
NSString* ORGretina4ACodeDateChanged                    = @"ORGretina4ACodeDateChanged";
NSString* ORGretina4ACodeRevisionChanged                 = @"ORGretina4ACodeRevisionChanged";
NSString* ORGretina4AFwTypeChanged                      = @"ORGretina4AFwTypeChanged";
//---sd_config Reg
NSString* ORGretina4ASdPemChanged                       = @"ORGretina4ASdPemChanged";
NSString* ORGretina4ASdSmLostLockFlagChanged            = @"ORGretina4ASdSmLostLockFlagChanged";
//------
NSString* ORGretina4AVmeStatusChanged                   = @"ORGretina4AVmeStatusChanged";
NSString* ORGretina4AConfigMainFpgaChanged              = @"ORGretina4AConfigMainFpgaChanged";
NSString* ORGretina4AClkSelect0Changed                  = @"ORGretina4AClkSelect0Changed";
NSString* ORGretina4AClkSelect1Changed                  = @"ORGretina4AClkSelect1Changed";
NSString* ORGretina4AFlashModeChanged                   = @"ORGretina4AFlashModeChanged";
NSString* ORGretina4ASerialNumChanged                   = @"ORGretina4ASerialNumChanged";
NSString* ORGretina4ABoardRevNumChanged                 = @"ORGretina4ABoardRevNumChanged";
NSString* ORGretina4AVhdlVerNumChanged                  = @"ORGretina4AVhdlVerNumChanged";
//---AuxIO--
NSString* ORGretina4AAuxIoReadChanged                   = @"ORGretina4AAuxIoReadChanged";
NSString* ORGretina4AAuxIoWriteChanged                  = @"ORGretina4AAuxIoWriteChanged";
NSString* ORGretina4AAuxIoConfigChanged                 = @"ORGretina4AAuxIoConfigChanged";
//===Notifications for Low-Level Reg Access===
NSString* ORGretina4ARegisterIndexChanged               = @"ORGretina4ARegisterIndexChanged";
NSString* ORGretina4ASelectedChannelChanged             = @"ORGretina4ASelectedChannelChanged";
NSString* ORGretina4ARegisterWriteValueChanged          = @"ORGretina4ARegisterWriteValueChanged";
NSString* ORGretina4ASPIWriteValueChanged               = @"ORGretina4ASPIWriteValueChanged";
//===Notifications for Firmware Loading===
NSString* ORGretina4AFpgaDownProgressChanged            = @"ORGretina4AFpgaDownProgressChanged";
NSString* ORGretina4AMainFPGADownLoadStateChanged		= @"ORGretina4AMainFPGADownLoadStateChanged";
NSString* ORGretina4AFpgaFilePathChanged				= @"ORGretina4AFpgaFilePathChanged";
NSString* ORGretina4AModelFirmwareStatusStringChanged	= @"ORGretina4AModelFirmwareStatusStringChanged";
NSString* ORGretina4AMainFPGADownLoadInProgressChanged	= @"ORGretina4AMainFPGADownLoadInProgressChanged";
//====General
NSString* ORGretina4ARateGroupChangedNotification       = @"ORGretina4ARateGroupChangedNotification";
NSString* ORGretina4AFIFOCheckChanged                   = @"ORGretina4AFIFOCheckChanged";
NSString* ORGretina4AModelInitStateChanged              = @"ORGretina4AModelInitStateChanged";
NSString* ORGretina4ACardInited                         = @"ORGretina4ACardInited";
NSString* ORGretina4AForceFullCardInitChanged           = @"ORGretina4AForceFullCardInitChanged";
NSString* ORGretina4AForceFullInitChanged               = @"ORGretina4AForceFullInitChanged";
NSString* ORGretina4ALockChanged                        = @"ORGretina4ALockChanged";
NSString* ORGretina4ASettingsLock                       = @"ORGretina4ASettingsLock";
NSString* ORGretina4ARegisterLock                       = @"ORGretina4ARegisterLock";
NSString* ORGretina4ADoHwCheckChanged                   = @"ORGretina4ADoHwCheckChanged";
NSString* ORGretina4AModelRateSpiked                    = @"ORGretina4AModelRateSpiked";
NSString* ORGretina4AModelRAGChanged                    = @"ORGretina4AModelRAGChanged";
NSString* ORGretina4AClockSourceChanged                 = @"ORGretina4AClockSourceChanged";
//=====Counters
NSString* ORGretina4ATSErrCntCtrlChanged                = @"ORGretina4ATSErrCntCtrlChanged";
NSString* ORGretina4ATSErrorCountChanged                = @"ORGretina4ATSErrorCountChanged";
NSString* ORGretina4AAHitCountChanged                   = @"ORGretina4AAHitCountChanged";
NSString* ORGretina4ADroppedEventCountChanged           = @"ORGretina4ADroppedEventCountChanged";
NSString* ORGretina4ADiscCountChanged                   = @"ORGretina4ADiscCountChanged";
NSString* ORGretina4AAcceptedEventCountChanged          = @"ORGretina4AAcceptedEventCountChanged";






@interface ORGretina4AModel (private)
//firmware loading
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
@end


@implementation ORGretina4AModel


#pragma mark - Boilerplate
- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self loadCardDefaults];
    unsigned short aChan;
    for(aChan=0;aChan<kNumGretina4AChannels;aChan++){
        [self loadChannelDefaults:aChan];
    }
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
    NSImage* aCachedImage = [NSImage imageNamed:@"Gretina4ACard"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
    int chan;
    float y=73;
    float dy=3;
    NSColor* enabledColor  = [NSColor colorWithCalibratedRed:0.4 green:0.7 blue:0.4 alpha:1];
    NSColor* disabledColor = [NSColor clearColor];
    for(chan=0;chan<kNumGretina4AChannels/2;chan++){
        if(enabled[chan])  [enabledColor  set];
        else			  [disabledColor set];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(5,y,4,dy)] fill];
        
        if(enabled[chan+5])[enabledColor  set];
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
    [self linkToController:@"ORGretina4AController"];
}

- (NSString*) helpURL
{
    return @"VME/Gretina4A.html";
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

- (void) openPreampDialog
{
    [[[spiConnector connector]objectLink] makeMainController];
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

- (uint32_t) baseAddress   { return (([self slot]+1)&0x1f)<<20; }

- (ORConnector*)  linkConnector { return linkConnector; }
- (void) setLinkConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [linkConnector release];
    linkConnector = aConnector;
}

- (ORConnector*) spiConnector   {   return spiConnector;    }
- (void) setSpiConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [spiConnector release];
    spiConnector = aConnector;
}

#pragma mark ***Access Methods
- (BOOL) doHwCheck { return doHwCheck; }
- (void) setDoHwCheck:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoHwCheck:doHwCheck];
    doHwCheck = aFlag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADoHwCheckChanged object:self];
}

- (uint32_t) spiWriteValue { return spiWriteValue; }
- (void) setSPIWriteValue:(uint32_t)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSPIWriteValue:spiWriteValue];
    spiWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASPIWriteValueChanged object:self];
}

- (short) registerIndex { return registerIndex; }
- (void) setRegisterIndex:(int)aRegisterIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterIndex:registerIndex];
    registerIndex = aRegisterIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARegisterIndexChanged object:self];
}

- (uint32_t) registerWriteValue { return registerWriteValue; }
- (void) setRegisterWriteValue:(uint32_t)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterWriteValue:registerWriteValue];
    registerWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARegisterWriteValueChanged object:self];
}

- (uint32_t) selectedChannel { return selectedChannel;}
- (void) setSelectedChannel:(unsigned short)aChannel
{
    if(aChannel >= kNumGretina4AChannels) aChannel = kNumGretina4AChannels - 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannel:selectedChannel];
    selectedChannel = aChannel;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASelectedChannelChanged object:self];
}

- (uint32_t) readRegister:(unsigned int)index channel:(int)aChannel
{
    if (index >= kNumberOfGretina4ARegisters) return -1;
    if (![Gretina4ARegisters regIsReadable:index]) return -1;
    uint32_t theValue = 0;
    uint32_t theAddress = [Gretina4ARegisters address:[self baseAddress] forReg:index];
    if([Gretina4ARegisters hasChannels:index]){
        theAddress += aChannel*0x04;
    }

    [[self adapter] readLongBlock:&theValue
                        atAddress:theAddress
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue;
}

- (uint32_t) readRegister:(unsigned int)index
{
    if (index >= kNumberOfGretina4ARegisters) return -1;
    if (![Gretina4ARegisters regIsReadable:index]) return -1;
    uint32_t theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[Gretina4ARegisters address:[self baseAddress] forReg:index]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue;
}

- (void) writeRegister:(unsigned int)index withValue:(uint32_t)value
{
    if (index >= kNumberOfGretina4ARegisters) return;
    if (![Gretina4ARegisters regIsWriteable:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[Gretina4ARegisters address:[self baseAddress] forReg:index]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
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

- (uint32_t) readFPGARegister:(unsigned int)index;
{
    if (index >= kNumberOfFPGARegisters) return -1;
    if (![Gretina4AFPGARegisters regIsReadable:index]) return -1;
    uint32_t theValue = 0;
    [[self adapter] readLongBlock:&theValue
                        atAddress:[Gretina4AFPGARegisters address:[self baseAddress] forReg:index]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return theValue;
}

- (void) writeFPGARegister:(unsigned int)index withValue:(uint32_t)value
{
    if (index >= kNumberOfFPGARegisters) return;
    if (![Gretina4AFPGARegisters regIsWriteable:index]) return;
    [[self adapter] writeLongBlock:&value
                         atAddress:[Gretina4AFPGARegisters address:[self baseAddress] forReg:index]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}
- (void) snapShotRegisters
{
    NSLog(@"Did Snapshot for %@ channel: %d\n",[self fullID],[self selectedChannel]);

    int i;
    for(i=0;i<kNumberOfGretina4ARegisters;i++){
        snapShot[i] = [self readRegister:i channel:(int)[self selectedChannel]];
    }
    
    for(i=0;i<kNumberOfFPGARegisters;i++){
        fpgaSnapShot[i] = [self readFPGARegister:i];
    }
}

- (void) compareToSnapShot
{
    NSFont* aFont = [NSFont fontWithName:@"Monaco" size:10.0];
    NSLog(@"-------------Snapshot comparison----------------\n");
    NSLog(@"%@ channel: %d\n",[self fullID],[self selectedChannel]);
    NSLogFont(aFont,@"offset   snapshot        newest\n");
    
    int i;
    for(i=0;i<kNumberOfGretina4ARegisters;i++){
        uint32_t theValue = [self readRegister:i  channel:(int)[self selectedChannel]];
        if(snapShot[i] != theValue){
            NSLogFont(aFont,@"0x%04x 0x%08x != 0x%08x %@\n",[Gretina4ARegisters offsetforReg:i],snapShot[i],theValue,[Gretina4ARegisters registerName:i]);
            
        }
    }
    
    for(i=0;i<kNumberOfFPGARegisters;i++){
        uint32_t theValue = [self readFPGARegister:i];
        if(fpgaSnapShot[i] != theValue){
            NSLogFont(aFont,@"0x%04x 0x%08x != 0x%08x %@\n",[Gretina4AFPGARegisters offsetforReg:i],fpgaSnapShot[i],theValue,[Gretina4AFPGARegisters registerName:i]);
            
        }
    }
    NSLog(@"------------------------------------------------\n");
}

- (void) dumpAllRegisters
{
    NSFont* aFont = [NSFont fontWithName:@"Monaco" size:10.0];
    NSLog(@"------------------------------------------------\n");
    NSLog(@"Register Values for Channel #%d\n",[self selectedChannel]);
    int i;
    for(i=0;i<kNumberOfGretina4ARegisters;i++){
        uint32_t theValue = [self readRegister:i channel:(int)[self selectedChannel]];
        NSLogFont(aFont,@"0x%04x 0x%08x %10lu %@\n",[Gretina4ARegisters offsetforReg:i],theValue,theValue,[Gretina4ARegisters registerName:i]);
        snapShot[i] = theValue;
        if(i == kBoardId)           [self dumpBoardIdDetails:theValue];
        if(i == kProgrammingDone)   [self dumpProgrammingDoneDetails:theValue];
        if(i == kHardwareStatus)    [self dumpHardwareStatusDetails:theValue];
        if(i == kExternalDiscSrc)   [self dumpExternalDiscSrcDetails:theValue];
        if(i == kChannelControl)    [self dumpChannelControlDetails:theValue];
        if(i == kHoldoffControl)    [self dumpHoldoffControlDetails:theValue];
        if(i == kBaselineDelay)     [self dumpBaselineDelayDetails:theValue];
        if(i == kExternalDiscMode)  [self dumpExtDiscModeDetails:theValue];
        if(i == kMasterLogicStatus) [self dumpMasterStatusDetails:theValue];
        
    }
    NSLog(@"------------------------------------------------\n");
    
    for(i=0;i<kNumberOfFPGARegisters;i++){
        uint32_t theValue = [self readFPGARegister:i];
        NSLogFont(aFont,@"0x%04x 0x%08x %@\n",[Gretina4AFPGARegisters offsetforReg:i],theValue,[Gretina4AFPGARegisters registerName:i]);
        
        fpgaSnapShot[i] = theValue;
    }
}

- (void) dumpCounters
{
    NSLog(@"Dropped Event Count: %u\n",[self readRegister:kDroppedEventCount]);
    NSLog(@"Accept Event Count: %u\n",[self readRegister:kAcceptedEventCount]);
    NSLog(@"AHit Couynt: %u\n",[self readRegister:kAhitCount]);
    NSLog(@"Disc Count: %u\n",[self readRegister:kDiscCount]);
    NSLog(@"TS ErrorCount: %u\n",[self readRegister:kTSErrorCount]);
}

- (void) dumpBoardIdDetails:(uint32_t)aValue
{
    NSFont* aFont = [NSFont fontWithName:@"Monaco" size:10.0];
    NSLogFont(aFont,@"Firmware: 0x%08x Geo_addr: 0x%08x\n",aValue>>16,(aValue>>4)&0x1F);
}

- (void) dumpProgrammingDoneDetails:(uint32_t)aValue
{
    NSFont* aFont = [NSFont fontWithName:@"Monaco" size:10.0];
    NSLogFont(aFont,@"     Master FIFO Reset: %@\n", ((aValue>>27)&0x1)?@"Reset":@"Run");
    NSLogFont(aFont,@"     fifo_fulla       : %@\n", ((aValue>>26)&0x1)?@"Empty":@"Full");
    NSLogFont(aFont,@"     fifo_fullb       : %@\n", ((aValue>>25)&0x1)?@"Empty":@"Full");
    NSLogFont(aFont,@"     fifo_almost_full : %@\n", ((aValue>>24)&0x1)?@"Almost Full":@"-");
    NSLogFont(aFont,@"     fifo_half_full   : %@\n", ((aValue>>23)&0x1)?@"Half Full":@"-");
    NSLogFont(aFont,@"     fifo_almost_empty: %@\n", ((aValue>>22)&0x1)?@"Almost Empty":@"-");
    NSLogFont(aFont,@"     fifo_emptya      : %@\n", ((aValue>>21)&0x1)?@"Empty":@"NOT Empty");
    NSLogFont(aFont,@"     fifo_emptyb      : %@\n", ((aValue>>20)&0x1)?@"Empty":@"NOT Empty");
    NSLogFont(aFont,@"     fifo depth       : %d\n",  (aValue>> 0)&0xfffff);
}

- (void) dumpHardwareStatusDetails:(uint32_t)aValue
{
    NSFont* aFont = [NSFont fontWithName:@"Monaco" size:10.0];
    NSLogFont(aFont,@"     fbus_thottle          : %d\n",  (aValue>>0)&0x1);
    NSLogFont(aFont,@"     fbus_serdes sm locked : %d\n",  (aValue>>1)&0x1);
    NSLogFont(aFont,@"     aux din 4-7           : 0x%x\n",(aValue>>4)&0xf);
    NSLogFont(aFont,@"     ph_success            : %@\n", ((aValue>>8)&0x1)?@"ClkSuccess":@"0");
    NSLogFont(aFont,@"     ph_failure            : %@\n", ((aValue>>9)&0x1)?@"PH_Fail":@"0");
    NSLogFont(aFont,@"     ph_hunting_up         : %d\n",  (aValue>>10)&0x1);
    NSLogFont(aFont,@"     ph_hunting_down       : %d\n",  (aValue>>11)&0x1);
    NSLogFont(aFont,@"     ph_checking           : %d\n",  (aValue>>12)&0x1);
    NSLogFont(aFont,@"     acq_dcm_lock          : %@\n", ((aValue>>20)&0x1)?@"Lock":@"0");
    NSLogFont(aFont,@"     acq_dcm_reset         : %@\n", ((aValue>>21)&0x1)?@"Reset":@"0");
    NSLogFont(aFont,@"     acq_ph_shift_overflow : %@\n", ((aValue>>22)&0x1)?@"Overflow":@"0");
    NSLogFont(aFont,@"     acq_dcm_clk_stopped   : %@\n", ((aValue>>23)&0x1)?@"Clk Stop":@"0");
    NSLogFont(aFont,@"     adc_dcm_lock          : %@\n", ((aValue>>28)&0x1)?@"Lock":@"0");
    NSLogFont(aFont,@"     adc_dcm_reset         : %@\n", ((aValue>>29)&0x1)?@"Reset":@"0");
    NSLogFont(aFont,@"     adc_ph_shift_overflow : %@\n", ((aValue>>30)&0x1)?@"Overflow":@"0");
    NSLogFont(aFont,@"     adc_dcm_clk_stopped   : %@\n", ((aValue>>31)&0x1)?@"ClkStop":@"0");
}

- (void) dumpExternalDiscSrcDetails:(uint32_t)aValue
{
    NSFont* aFont = [NSFont fontWithName:@"Monaco" size:10.0];
    NSString* name[8] = {
        @"Slv to Ch 0",
        @"Front Bus",
        @"Aux IO",
        @"Timestamp",
        @"Pulsed_Ctrl",
        @"Main Trigger",
        @"Ge_preamp_kill",
        @"undef"};
    int  i = (int)[self selectedChannel];
    int index = (aValue>>(i*3))&0x7;
    NSLogFont(aFont,@"     %d: %@\n",i,name[index]);
}

- (void) dumpChannelControlDetails:(uint32_t)aValue
{
    NSFont* aFont = [NSFont fontWithName:@"Monaco" size:10.0];
    NSString* trigPolarity[4] = {
        @"Disabled",
        @"Rising Edge",
        @"Falling Edge",
        @"Both"
    };

    NSLogFont(aFont,@"     Channel Enabled     : %@\n", ((aValue>>0)&0x1)?@"Enabled" : @"Disabled");
    NSLogFont(aFont,@"     Pileup Mode         : %@\n", ((aValue>>2)&0x1)?@"Accept"  : @"Reject");
    NSLogFont(aFont,@"     Trigger Polarity    : %@\n", trigPolarity[(aValue>>10)&0x3]);
    NSLogFont(aFont,@"     Decimation          : x%d\n", (int)pow(2.,(double)((aValue>>12)&0x7)));
    NSLogFont(aFont,@"     Write Flag          : %@\n", (aValue>>15)&0x1 ? @"Shift Data":@"Normal");
    NSLogFont(aFont,@"     Dropped EVent Mode  : %@\n", ((aValue>>20)&0x1)?@"Count" : @"Rate");
    NSLogFont(aFont,@"     Event Count Mode    : %@\n", ((aValue>>21)&0x1)?@"Count" : @"Rate");
    NSLogFont(aFont,@"     aHit Count Mode     : %@\n", ((aValue>>22)&0x1)?@"Count" : @"Rate");
    NSLogFont(aFont,@"     Disc Count Mode     : %@\n", ((aValue>>23)&0x1)?@"Count" : @"Rate");
    NSLogFont(aFont,@"     Pileup Ext Mode     : %@\n", ((aValue>>26)&0x1)?@"Enabled" : @"Disabled");
    NSLogFont(aFont,@"     Counter Reset       : %@\n", ((aValue>>27)&0x1)?@"Reset"  : @"Run");
    NSLogFont(aFont,@"     Pileup Waveform Only: %@\n", ((aValue>>30)&0x1)?@"Enabled": @"Disabled");
}


- (void) dumpHoldoffControlDetails:(uint32_t)aValue
{
    NSFont* aFont = [NSFont fontWithName:@"Monaco" size:10.0];
    NSLogFont(aFont,@"     Holdoff Time     : %d\n", (aValue>>0) & 0x1ff);
    NSLogFont(aFont,@"     Peak Sensitivity : %d\n", (aValue>>9) & 0x7);
    NSLogFont(aFont,@"     Auto Mode        : %@\n", ((aValue>>12)& 0x1)?@"Enabled" : @"Disabled");
}
- (void) dumpBaselineDelayDetails:(uint32_t)aValue
{
    NSFont* aFont = [NSFont fontWithName:@"Monaco" size:10.0];
    NSLogFont(aFont,@"     Delay          : %d\n", (aValue>>0) & 0xf);
    NSLogFont(aFont,@"     Tracking Speed : %d\n", (aValue>>9) & 0x7);
    NSLogFont(aFont,@"     Status         : %d\n", ((aValue>>(12+[self selectedChannel]))& 0x1));
}

- (void) dumpExtDiscModeDetails:(uint32_t)aValue
{
    NSFont* aFont = [NSFont fontWithName:@"Monaco" size:10.0];
    NSString* descSel[4] = {
        @"Disc ONLY",
        @"Disc OR Ext",
        @"Disc AND Ext",
        @"Ext ONLY"
    };
    NSString* descTsSel[8] = {
        @"0.75 Hz",
        @" 6.0 Hz",
        @" 23.8 Hz",
        @" 95.4 Hz",
        @" 1.5 kHz",
        @" 48.4 kHz",
        @"195 kHz",
        @"OFF"
    };
    int  i = (int)[self selectedChannel];
    NSLogFont(aFont,@"     Ext Disc Sel    : %@\n", descSel[(aValue>>2+i)&0x3]);
    NSLogFont(aFont,@"     Ext Dixc TS Sel : %@\n", descTsSel[(aValue>>27)&0x7]);
}

- (void) dumpMasterStatusDetails:(uint32_t)aValue
{
    NSFont* aFont = [NSFont fontWithName:@"Monaco" size:10.0];
    int  i = (int)[self selectedChannel];
    NSLogFont(aFont,@"     Master Logic Enable  : %@\n", (aValue>>0)&0x1?@"Enabled":@"Reset");
    NSLogFont(aFont,@"     Diag isync           : %@\n", (aValue>>1)&0x1?@"Run":@"ImpSync");
    NSLogFont(aFont,@"     Counter Mode         : %@\n", (aValue>>4)&0x1?@"Internal":@"SERDES");
    NSLogFont(aFont,@"     Master Counter Reset : %@\n", (aValue>>5)&0x1?@"Reset":@"Run");
    NSLogFont(aFont,@"     BGO discbit sel      : %@\n", (aValue>>7)&0x1?@"All":@"Accepted Only");
    NSLogFont(aFont,@"     Veto enable          : %@\n", (aValue>>8)&0x1?@"Enabled":@"Disabled");
    NSLogFont(aFont,@"     PU Time Err          : %@\n", (aValue>>16)&0x1?@"Error":@"OK");
    NSLogFont(aFont,@"     Serdes lock          : %@\n", (aValue>>17)&0x1?@"Lock":@"Unlock");
    NSLogFont(aFont,@"     Serdes sm locked     : %@\n", (aValue>>18)&0x1?@"Lock":@"Unlock");
    NSLogFont(aFont,@"     Serdes sm lost lock  : %@\n", (aValue>>19)&0x1?@"Lost":@"OK");
    NSLogFont(aFont,@"     Overflow flag        : %@\n", ((aValue>>(22+i))& 0x1)?@"Lost Mind":@"OK");
}

- (void) loadCardDefaults
{
    extDiscriminatorSrc = 0x00; //a mask for all channels
    windowCompMin   = 256;
    windowCompMax   = 32000;
    rawDataLength   = 500;
    rawDataWindow   = 0x7fc;
    p2Window        = 0;
    holdOffTime     = 160;
    baselineDelay   = 511;
    trackingSpeed   = 5;
    peakSensitivity = 7;
    autoMode        = NO;
    vetoGateWidth   = 10;
}

- (void) loadChannelDefaults:(unsigned short) aChan
{
    pileupMode[aChan]             = NO;
    triggerPolarity[aChan]        = 1;
    decimationFactor[aChan]       = 0;
    pileupExtensionMode[aChan]    = NO;
    pileupWaveformOnlyMode[aChan] = NO;
    ledThreshold[aChan]           = 300;
    dWindow[aChan]                = 16;
    kWindow[aChan]                = 100;
    mWindow[aChan]                = 200;
    p1Window[aChan]               = 0;
    discWidth[aChan]              = 10;
    baselineStart[aChan]          = 100;

}
#pragma mark - Counters
- (void) readaHitCounts
{
    [[self adapter] readLongBlock:aHitCounter
                        atAddress:[self baseAddress]+[Gretina4ARegisters offsetforReg:kAhitCount]
                        numToRead:kNumGretina4AChannels
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAHitCountChanged object:self];
}

- (void) readDroppedEventCounts
{
    [[self adapter] readLongBlock:droppedEventCount
                        atAddress:[self baseAddress]+[Gretina4ARegisters offsetforReg:kDroppedEventCount]
                        numToRead:kNumGretina4AChannels
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADroppedEventCountChanged object:self];
}
- (void) readAcceptedEventCounts
{
    [[self adapter] readLongBlock:acceptedEventCount
                        atAddress:[self baseAddress]+[Gretina4ARegisters offsetforReg:kAcceptedEventCount]
                        numToRead:kNumGretina4AChannels
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAcceptedEventCountChanged object:self];
}

- (void) readDiscriminatorCounts
{
    [[self adapter] readLongBlock:discriminatorCount
                        atAddress:[self baseAddress]+[Gretina4ARegisters offsetforReg:kDiscCount]
                        numToRead:kNumGretina4AChannels
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiscCountChanged object:self];
}

- (void) clearCounters
{
    int chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        uint32_t old = [self readLongFromReg:kChannelControl channel:chan];
        //toggle the reset bit
        old |= (0x1<<27);
        [self writeLong:old toReg:kChannelControl channel:chan];
        old ^= (0x1<<27);
        [self writeLong:old toReg:kChannelControl channel:chan];
    }
    
    [self readaHitCounts];
    [self readDroppedEventCounts];
    [self readAcceptedEventCounts];
    [self readDiscriminatorCounts];
}


#pragma mark - Firmware loading
- (BOOL) downLoadMainFPGAInProgress
{
    return downLoadMainFPGAInProgress;
}

- (void) setDownLoadMainFPGAInProgress:(BOOL)aState
{
    downLoadMainFPGAInProgress = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AMainFPGADownLoadInProgressChanged object:self];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AMainFPGADownLoadStateChanged object:self];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFpgaFilePathChanged object:self];
}

- (void) startDownLoadingMainFPGA
{
    if(!progressLock)progressLock = [[NSLock alloc] init];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFpgaDownProgressChanged object:self];
    
    stopDownLoadingMainFPGA = NO;
    
    //to minimize disruptions to the download thread we'll check and update the progress from the main thread via a timer.
    fpgaDownProgress = 0;
    
    if(![self controllerIsSBC]){
        [self setDownLoadMainFPGAInProgress: YES];
        [self updateDownLoadProgress];
        NSLog(@"Gretina4A (%d) beginning firmware load via Mac, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
        
        [NSThread detachNewThreadSelector:@selector(fpgaDownLoadThread:) toTarget:self withObject:[NSData dataWithContentsOfFile:fpgaFilePath]];
    }
    else {
        if([[[self adapter]sbcLink]isConnected]){
            [self setDownLoadMainFPGAInProgress: YES];
            NSLog(@"Gretina4A (%d) beginning firmware load via SBC, File: %@\n",[self uniqueIdNumber],fpgaFilePath);
            [self copyFirmwareFileToSBC:fpgaFilePath];
        }
        else {
            [self setDownLoadMainFPGAInProgress: NO];
            NSLog(@"Gretina4A (%d) unable to load firmware. SBC not connected.\n",[self uniqueIdNumber]);
        }
    }
}

- (void) tasksCompleted: (NSNotification*)aNote
{
}

- (BOOL) queueIsRunning
{
    return [fileQueue operationCount];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AModelFirmwareStatusStringChanged object:self];
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
        NSLog(@"Gretina4A (%d) firmware load job in SBC finished (%@)\n",[self uniqueIdNumber],[jobStatus finalStatus]?@"Success":@"Failed");
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


#pragma mark - rates
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
     postNotificationName:ORGretina4ARateGroupChangedNotification
     object:self];
}

- (id) rateObject:(short)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
    //we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
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
     postNotificationName:ORGretina4AModelRAGChanged
     object:self];
}
- (void) rateSpikeChanged:(NSNotification*)aNote
{
    ORRunningAveSpike* spikeObj = [[aNote userInfo] objectForKey:@"SpikeObject"];
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              spikeObj,@"spikeInfo",
                              [NSNumber numberWithInt:[self crateNumber]],  @"crate",
                              [NSNumber numberWithInt:[self slot]],         @"card",
                              [NSNumber numberWithInteger:[spikeObj tag]],      @"channel",
                              nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AModelRateSpiked object:self userInfo:userInfo];
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

- (uint32_t) getCounter:(short)counterTag forGroup:(short)groupTag
{
    if(groupTag == 0){
        if(counterTag>=0 && counterTag<kNumGretina4AChannels){
            return waveFormCount[counterTag];
        }
        else return 0;
    }
    else return 0;
}

- (float) getRate:(short)channel
{
    if(channel>=0 && channel<kNumGretina4AChannels){
        return [[self rateObject:channel] rate]; //the rate
    }
    return 0;
}

#pragma mark - Initialization
//---functions to allow the MJD threshold fineder script to work
- (void) setForceFullInitCard:(BOOL)aValue { [self setForceFullCardInit:aValue]; }
- (void) setTrapThreshold:(unsigned short)chan withValue:(unsigned short)aValue
{
    [self setLedThreshold:chan withValue:aValue];
}
- (short) trapThreshold:(unsigned short)chan
{
    return [self ledThreshold:chan];
}

- (void) writeTrapThreshold:(unsigned short)aChan
{
    [self writeLedThreshold:aChan];
}
- (BOOL) trapEnabled:(int)aChan { return YES; }
//----------------------------------------------------------------

- (BOOL) forceFullCardInit		{ return forceFullCardInit; }
- (void) setForceFullCardInit:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setForceFullCardInit:forceFullCardInit];
    forceFullCardInit = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AForceFullCardInitChanged object:self];
}

- (BOOL) forceFullInit:(short)chan		{ return forceFullInit[chan]; }
- (void) setForceFullInit:(short)chan withValue:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setForceFullInit:chan withValue:forceFullInit[chan]];
    forceFullInit[chan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AForceFullInitChanged object:self];
}

#pragma mark - Persistant Register Values

- (short) clockSource
{
    return clockSource;
}

- (void) setClockSource:(short)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = aClockSource;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AClockSourceChanged object:self];
}

//------------------- Address = 0x0008  Bit Field = 32..0 ---------------
- (uint32_t) extDiscriminatorSrc { return extDiscriminatorSrc ;}
- (void)  setExtDiscriminatorSrc:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setExtDiscriminatorSrc:extDiscriminatorSrc];
    extDiscriminatorSrc = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AExtDiscrimitorSrcChanged object:self];
}

//------------------- Address = 0x0020  Bit Field = 31 ---------------
- (uint32_t) hardwareStatus { return hardwareStatus; }
- (void)          setHardwareStatus:(uint32_t)aValue
{
    hardwareStatus = aValue & 0xfff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AHardwareStatusChanged object:self];
}

//------------------- Address = 0x0024  Bit Field = 11..0 ---------------
- (uint32_t) userPackageData { return userPackageData; }
- (void) setUserPackageData:(uint32_t)aValue
{
    if(aValue>0xFFF)aValue = 0xFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setUserPackageData:userPackageData];
    userPackageData = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AUserPackageDataChanged object:self];
}

//------------------- Address = 0x0028  Bit Field = 15..0 ---------------
- (unsigned short) windowCompMin { return windowCompMin; }
- (void)           setWindowCompMin:(unsigned short)aValue
{
    if(aValue>0xFFFF)aValue = 0xFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setWindowCompMin:windowCompMin];
    windowCompMin = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AWindowCompMinChanged object:self];
}

//------------------- Address = 0x002C  Bit Field = 15..0 ---------------
- (unsigned short) windowCompMax    { return windowCompMax; }
- (void)           setWindowCompMax:(unsigned short)aValue
{
    if(aValue>0xFFFF)aValue = 0xFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setWindowCompMax:windowCompMax];
    windowCompMax = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AWindowCompMaxChanged object:self];
}

//------------------- Address = 0x0040  Bit Field = 15..0 ---------------
//------------------- kChannelControl  Bit Field = 0 ---------------
- (BOOL) enabled:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels)return enabled[chan];
    else return NO;
}
- (void) setEnabled:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan<kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:chan withValue:enabled[chan]];
        enabled[chan] = aValue;
        [self setUpImage];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AEnabledChanged object:self];
        [self postAdcInfoProvidingValueChanged];
    }
}
//------------------- kChannelControl  Bit Field = 2 ---------------
- (BOOL) pileupMode:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels)return pileupMode[chan];
    else return NO;
}

- (void) setPileupMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setPileupMode:chan withValue:pileupMode[chan]];
        pileupMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APileupModeChanged object:self];
    }
}


//------------------- kChannelControl  Bit Field = 10..11 ---------------
- (short) triggerPolarity:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels ) return triggerPolarity[chan] & 0x3;
    else                            return 0;
}

- (void) setTriggerPolarity:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue > 0x3)aValue = 0x3;
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setTriggerPolarity:chan withValue:triggerPolarity[chan]];
        triggerPolarity[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATriggerPolarityChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 12..14 ---------------
- (short) decimationFactor:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels) return decimationFactor[chan] & 0x7;
    else                             return 0;
}

- (void) setDecimationFactor:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0x7)aValue = 0x7;
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setDecimationFactor:chan withValue:decimationFactor[chan]];
        decimationFactor[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADecimationFactorChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 20 ---------------
- (BOOL) droppedEventCountMode:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels)return droppedEventCountMode[chan];
    else return NO;
}

- (void) setDroppedEventCountMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels)) {
        [[[self undoManager] prepareWithInvocationTarget:self] setDroppedEventCountMode:chan withValue:droppedEventCountMode[chan]];
        droppedEventCountMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADroppedEventCountModeChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 21 ---------------
- (BOOL) eventCountMode:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels ) return eventCountMode[chan];
    else                              return NO;
}

- (void) setEventCountMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setEventCountMode:chan withValue:eventCountMode[chan]];
        eventCountMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AEventCountModeChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 22 ---------------
- (BOOL)  aHitCountMode:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels) return aHitCountMode[chan];
    else                             return NO;
}

- (void)  setAHitCountMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setAHitCountMode:chan withValue:aHitCountMode[chan]];
        aHitCountMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAHitCountModeChanged object:self];
    }
}

//------------------- kChannelControl  Bit Field = 23 ---------------
- (BOOL)  discCountMode:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels) return discCountMode[chan];
    else                           return NO;
    
}
- (void)  setDiscCountMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setDiscCountMode:chan withValue:discCountMode[chan]];
        discCountMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiscCountModeChanged object:self];
    }
}


//------------------- kChannelControl  Bit Field = 26 ---------------
- (BOOL)  pileupExtensionMode:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels )return pileupExtensionMode[chan];
    else                             return NO;
}

- (void) setPileupExtensionMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setPileupExtensionMode:chan withValue:pileupExtensionMode[chan]];
        pileupExtensionMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APileupExtensionModeChanged object:self];
    }
}
//------------------- count_Reset  Bit Field = 27    ---------------
//------------------- Reserved  Bit Field    = 28-29 ---------------

//------------------- kChannelControl  Bit Field = 30 ---------------
- (BOOL) pileupWaveformOnlyMode:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels )return pileupWaveformOnlyMode[chan];
    else                             return NO;
}
- (void) setPileupWaveformOnlyMode:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setPileupWaveformOnlyMode:chan withValue:pileupWaveformOnlyMode[chan]];
        pileupWaveformOnlyMode[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APileupWaveformOnlyModeChanged object:self];
    }
}

//------------------- Address = 0x0080 ---------------
- (void) setThreshold:(unsigned short)chan withValue:(int)aValue
{
    [self setLedThreshold:chan withValue:aValue];
}

- (short) ledThreshold:(unsigned short)chan
{
    if(chan<0 || chan>kNumGretina4AChannels )return 0;
    return ledThreshold[chan];
}

- (void) setLedThreshold:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0x3FFF)aValue = 0x3FFF;
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setLedThreshold:chan withValue:ledThreshold[chan]];
        ledThreshold[chan] = aValue;
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ALedThreshold0Changed object:self userInfo:userInfo];
    }
}



//------------------- Address = 0x0100 ---------------
//Sets the (maximum) size of the event packets.  Packet will be 4 bytes longer than the value written to this register. (10ns per count)
//same value for all channels
- (short) rawDataLength
{
    return rawDataLength;
}

- (void) setRawDataLength:(unsigned short)aValue
{
    //same value for all channels
    if(aValue>0x7FF)aValue = 0x7FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setRawDataLength:rawDataLength];
    rawDataLength = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARawDataLengthChanged object:self];
}

//Waveform offset value. (10 ns per count)
//same value for all channels
- (short) rawDataWindow
{
    return rawDataWindow;
}

- (void) setRawDataWindow:(unsigned short)aValue
{
    //same value for all channels
    if(aValue>0x7FC)aValue = 0x7FC;
    aValue = (aValue/2)*2; //make it even
    [[[self undoManager] prepareWithInvocationTarget:self] setRawDataWindow:rawDataWindow];
    rawDataWindow = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARawDataWindowChanged object:self];
}

//------------------- Address = 0x0180  Bit Field = 6..0 ---------------
- (short) dWindow:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels)return dWindow[chan];
    else return 0;
}

- (void) setDWindow:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0x7F)aValue = 0x7F;
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setDWindow:chan withValue:dWindow[chan]];
        dWindow[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADWindowChanged object:self];
    }
}

//------------------- Address = 0x01C0  Bit Field = 6..0 ---------------
- (short) kWindow:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels)return kWindow[chan];
    else return 0;
}

- (void) setKWindow:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0x7F)aValue = 0x7F;
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setKWindow:chan withValue:kWindow[chan]];
        kWindow[chan] = aValue;
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AKWindowChanged object:self userInfo:userInfo];
    }
}
//------------------- Address = 0x0200  Bit Field = 6..0 ---------------
- (short) mWindow:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels)return mWindow[chan];
    else return 0;
}

- (void) setMWindow:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0x3FF)aValue = 0x3FF;
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setMWindow:chan withValue:mWindow[chan]];
        mWindow[chan] = aValue;
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AMWindowChanged object:self userInfo:userInfo];
    }
}

//------------------- Address = 0x0240  Bit Field = 6..0 ---------------
- (short) d3Window:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels)return d3Window[chan];
    else return 0;
}

- (void) setD3Window:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0x7F)aValue = 0x7F;
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setD3Window:chan withValue:d3Window[chan]];
        d3Window[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AD3WindowChanged object:self];
    }
}

//------------------- Address = 0x0280  Bit Field = N/A ---------------
- (short) discWidth:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels)return discWidth[chan];
    else  return 0;
}

- (void) setDiscWidth:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0x3F)aValue = 0x3F;
    if((chan <kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setDiscWidth:chan withValue:discWidth[0]];
        discWidth[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiscWidthChanged object:self];
    }
}

//------------------- Address = 0x02C0  Bit Field = 13..0 ---------------
- (short) baselineStart:(unsigned short)chan
{
    if(chan <kNumGretina4AChannels)return baselineStart[chan];
    else return 0;
}

- (void) setBaselineStart:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0x3FFF)aValue = 0x3FFF;
    if((chan <kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setBaselineStart:chan withValue:baselineStart[chan]];
        baselineStart[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ABaselineStartChanged object:self];
    }
}

//------------------- Address = 0x0300  Bit Field = 3 .. 0 ---------------
- (short) p1Window:(unsigned short)chan
{
    if(chan < 10) return p1Window[chan];
    else          return 0;
}

- (void) setP1Window:(unsigned short)chan withValue:(unsigned short)aValue
{
    if(aValue>0xF)aValue = 0xF;
    if((chan < kNumGretina4AChannels)){
        [[[self undoManager] prepareWithInvocationTarget:self] setP1Window:chan withValue:p1Window[chan]];
        p1Window[chan] = aValue;
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AP1WindowChanged object:self userInfo:userInfo];
    }
}

//------------------- Address = 0x0400  Bit Field = 3..0 ---------------
- (short) dacChannelSelect { return dacChannelSelect; }
- (void) setDacChannelSelect:(unsigned short)aValue
{
    if(aValue>0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDacChannelSelect:dacChannelSelect];
    dacChannelSelect = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADacChannelSelectChanged object:self];
}

//------------------- Address = 0x0400  Bit Field = 7..0 ---------------
- (short) dacAttenuation { return dacAttenuation; }
- (void) setDacAttenuation:(unsigned short)aValue
{
    if(aValue>0xFF)aValue = 0xFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDacAttenuation:dacAttenuation];
    dacAttenuation = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADacAttenuationChanged object:self];
}

//------------------- Address = 0x0404  Bit Field = N/A ---------------
- (short) p2Window { return p2Window; }
- (void) setP2Window:(short)aValue
{
    if(aValue>0x2FF)aValue = 0x3FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setP2Window:p2Window];
    p2Window = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AP2WindowChanged object:self];
}

//------------------- Address = 0x040C  ---------------
- (uint32_t) channelPulsedControl { return channelPulsedControl; }
- (void) setChannelPulsedControl:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannelPulsedControl:channelPulsedControl];
    channelPulsedControl = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AChannelPulseControlChanged object:self];
}

//------------------- Address = 0x0410  ---------------
- (uint32_t) diagMuxControl { return diagMuxControl; }
- (void) setDiagMuxControl:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDiagMuxControl:diagMuxControl];
    diagMuxControl = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiagMuxControlChanged object:self];
}

//------------------- Address = 0x0414  Bit Field = 8..0 ---------------
- (unsigned short) holdOffTime { return holdOffTime; }
- (void) setHoldOffTime:(unsigned short)aValue
{
    if(aValue>0x3FF)aValue = 0x3FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setHoldOffTime:holdOffTime];
    holdOffTime = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AHoldOffTimeChanged object:self];
}

//------------------- Address = 0x0414  Bit Field = 9..11 ---------------
- (unsigned short) peakSensitivity { return peakSensitivity; }
- (void) setPeakSensitivity:(unsigned short)aValue
{
    if(aValue>0x7)aValue = 0x7;
    [[[self undoManager] prepareWithInvocationTarget:self] setPeakSensitivity:peakSensitivity];
    peakSensitivity = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APeakSensitivityChanged object:self];
}

//------------------- Address = 0x0414  Bit Field = bit 12 ---------------
- (BOOL) autoMode { return autoMode; }
- (void) setAutoMode:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoMode:autoMode];
    autoMode = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAutoModeChanged object:self];
}

//------------------- Address = 0x0418  Bit Field = 13..0 ---------------
- (unsigned short) baselineDelay { return baselineDelay; }
- (void) setBaselineDelay:(unsigned short)aValue
{
    if(aValue > 0x1FF)aValue = 0x1FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setBaselineDelay:baselineDelay];
    baselineDelay = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ABaselineDelayChanged object:self];
}

//------------------- Address = 0x0418  Bit Field = 10..8 ---------------
- (unsigned short) trackingSpeed { return trackingSpeed; }
- (void) setTrackingSpeed:(unsigned short)aValue
{
    if(aValue > 0x7)aValue = 0x7;
    [[[self undoManager] prepareWithInvocationTarget:self] setTrackingSpeed:trackingSpeed];
    trackingSpeed = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATrackingSpeedChanged object:self];
}

//------------------- Address = 0x0418  Bit Field = 16..23 Display only---------------
- (unsigned short) baselineStatus { return trackingSpeed; }
- (void) setBaselineStatus:(unsigned short)aValue
{
    if(aValue > 0xff)aValue = 0xff;
    baselineStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ABaselineStatusChanged object:self];
}

//------------------- Address = 0x041C  Bit Field = 13..0 ---------------
- (unsigned short) diagInput { return diagInput; }
- (void) setDiagInput:(unsigned short)aValue
{
    if(aValue>0x3FFF)aValue = 0x3FFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDiagInput:diagInput];
    diagInput = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiagInputChanged object:self];
}

//------------------- Address = 0x0420 ---------------
- (uint32_t)   extDiscriminatorMode { return extDiscriminatorMode; }
- (void)    setExtDiscriminatorMode:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setExtDiscriminatorMode:extDiscriminatorMode];
    extDiscriminatorMode = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AExtDiscriminatorModeChanged object:self];
}

//------------------- Address = 0x0420  Bit Field Bit Field = 29..27 ---------------
- (unsigned short) diagChannelEventSel { return diagChannelEventSel; }
- (void) setDiagChannelEventSel:(unsigned short)aValue
{
    if(aValue>0x7)aValue = 0x7;
    [[[self undoManager] prepareWithInvocationTarget:self] setDiagChannelEventSel:diagChannelEventSel];
    diagChannelEventSel = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiagChannelEventSelChanged object:self];
}

//------------------- Address = 0x0424  Bit Field = 3..0 ---------------
- (uint32_t) rj45SpareIoMuxSel { return rj45SpareIoMuxSel; }
- (void) setRj45SpareIoMuxSel:(uint32_t)aValue
{
    if(aValue>0xF)aValue = 0xF;
    [[[self undoManager] prepareWithInvocationTarget:self] setRj45SpareIoMuxSel:rj45SpareIoMuxSel];
    rj45SpareIoMuxSel = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARj45SpareIoMuxSelChanged object:self];
}

//------------------- Address = 0x0424  Bit Field = 4 ---------------
- (BOOL) rj45SpareIoDir { return rj45SpareIoDir; }
- (void) setRj45SpareIoDir:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRj45SpareIoDir:rj45SpareIoDir];
    rj45SpareIoDir = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ARj45SpareIoDirChanged object:self];
}

//------------------- Address = 0x0428 ---------------
- (uint32_t) ledStatus { return ledStatus; }
- (void) setLedStatus:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLedStatus:ledStatus];
    ledStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ALedStatusChanged object:self];
}
//------------------- Address = 0x0434 ---------------
- (unsigned short) downSampleHoldOffTime { return downSampleHoldOffTime; }
- (void) setDownSampleHoldOffTime:(unsigned short)aValue
{
    if(aValue>0x3FF)aValue = 0x3FF;
    [[[self undoManager] prepareWithInvocationTarget:self] setDownSampleHoldOffTime:downSampleHoldOffTime];
    downSampleHoldOffTime = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADownSampleHoldOffTimeChanged object:self];
}

- (BOOL) downSamplePauseEnable {return downSamplePauseEnable;}
- (void) setDownSamplePauseEnable:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDownSamplePauseEnable:downSamplePauseEnable];
    downSamplePauseEnable = aFlag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADownSamplePauseEnableChanged object:self];
  
}

//------------------- Address = 0x048C  Bit Field = 31..0 ---------------
//------------------- Address = 0x0490  Bit Field = 15..0 ---------------
//------------------- Address = 0x0494  Bit Field = 15..0 ---------------

- (unsigned short) vetoGateWidth { return vetoGateWidth; }
- (void) setVetoGateWidth:(unsigned short)aValue
{
    if(aValue > 0xFF)aValue = 0xFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setVetoGateWidth:vetoGateWidth];
    vetoGateWidth = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AVetoGateWidthChanged object:self];
}

//------------------- Address = 0x0500  Bit Field = 1 ---------------
- (BOOL) diagIsync { return diagIsync; }
- (void) setDiagIsync:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDiagIsync:diagIsync];
    diagIsync = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ADiagIsyncChanged object:self];
}

//------------------- Address = 0x0500  Bit Field = 19 ---------------
- (BOOL) serdesSmLostLock { return serdesSmLostLock; }
- (void) setSerdesSmLostLock:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerdesSmLostLock:serdesSmLostLock];
    serdesSmLostLock = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASerdesSmLostLockChanged object:self];
}

//------------------- Address = 0x0500  Bit Field = 22,23,24,25,26,27,28,29,30,31 ---------------
- (BOOL) overflowFlagChan:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels) return overflowFlagChan[chan];
    else return 0;
}

- (void) setOverflowFlagChan:(unsigned short)chan withValue:(BOOL)aValue
{
    if(chan < kNumGretina4AChannels){
        [[[self undoManager] prepareWithInvocationTarget:self] setOverflowFlagChan:chan withValue:aValue];
        overflowFlagChan[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AOverflowFlagChanChanged object:self];
    }
}

//------------------- Address = 0x0504  Bit Field = N/A ---------------
- (unsigned short) triggerConfig { return triggerConfig; }
- (void) setTriggerConfig:(unsigned short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerConfig:triggerConfig];
    triggerConfig = aValue & 0x3;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATriggerConfigChanged object:self];
}

//------------------- Address = 0x0508  Bit Field = N/A ---------------
- (uint32_t) phaseErrorCount { return phaseErrorCount; }
- (void) setPhaseErrorCount:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPhaseErrorCount:phaseErrorCount];
    phaseErrorCount = aValue & 0xffff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhaseErrorCountChanged object:self];
}

//------------------- Address = 0x050C  Bit Field = 15..0 ---------------
- (uint32_t) phaseStatus { return phaseStatus; }
- (void) setPhaseStatus:(uint32_t)aValue
{
    if(aValue > 0xFFFF)aValue = 0xFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setPhaseStatus:phaseStatus];
    phaseStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4APhaseStatusChanged object:self];
}

//------------------- Address = 0x051C  Bit Field = N/A ---------------
- (uint32_t) serdesPhaseValue { return serdesPhaseValue; }
- (void) setSerdesPhaseValue:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerdesPhaseValue:serdesPhaseValue];
    serdesPhaseValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASerdesPhaseValueChanged object:self];
}

//------------------- Address = 0x0600  Bit Field = 15..12  ---------------
- (uint32_t) codeRevision { return codeRevision; }
- (void) setCodeRevision:(uint32_t)aValue
{
    codeRevision = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ACodeRevisionChanged object:self];
}

//------------------- Address = 0x0604  Bit Field = 31..0 ---------------
- (uint32_t) codeDate { return codeDate; }
- (void) setCodeDate:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCodeDate:codeDate];
    codeDate = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ACodeDateChanged object:self];
}

//------------------- Address = 0x0608  Bit Field = N/A ---------------
- (uint32_t) tSErrCntCtrl { return tSErrCntCtrl;}
- (void) setTSErrCntCtrl:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTSErrCntCtrl:tSErrCntCtrl];
    tSErrCntCtrl = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATSErrCntCtrlChanged object:self];
}

//------------------- Address = 0x060C  Bit Field = N/A ---------------
- (uint32_t) tSErrorCount { return tSErrorCount; }
- (void) setTSErrorCount:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTSErrorCount:tSErrorCount];
    tSErrorCount = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ATSErrorCountChanged object:self];
}

//------------------- Address = 0x0700  Bit Field = 31..0 ---------------
- (uint32_t) droppedEventCount:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels)return droppedEventCount[chan];
    else return 0;
}


//------------------- Address = 0x0740  Bit Field = 31..0 ---------------
- (uint32_t) acceptedEventCount:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels )return acceptedEventCount[chan];
    else return 0;
}


//------------------- Address = 0x0780  Bit Field = 31..0 ---------------
- (uint32_t) aHitCount:(unsigned short)chan
{
    if(chan<kNumGretina4AChannels )return aHitCounter[chan];
    else return 0;
}

//------------------- Address = 0x07C0  Bit Field = 31..0 ---------------
- (uint32_t) discCount:(unsigned short)chan
{
    if(chan < kNumGretina4AChannels )return discriminatorCount[chan];
    else return 0;
}


//------------------- Address = 0x0800  Bit Field = 31..0 ---------------
- (uint32_t) auxIoRead { return auxIoRead; }
- (void) setAuxIoRead:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAuxIoRead:auxIoRead];
    auxIoRead = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAuxIoReadChanged object:self];
}

//------------------- Address = 0x0804  Bit Field = 31..0 ---------------
- (uint32_t) auxIoWrite { return auxIoWrite; }
- (void) setAuxIoWrite:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAuxIoWrite:auxIoWrite];
    auxIoWrite = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAuxIoWriteChanged object:self];
}

//------------------- Address = 0x0808  Bit Field = 31..0 ---------------
- (uint32_t) auxIoConfig { return auxIoConfig; }
- (void) setAuxIoConfig:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAuxIoConfig:auxIoConfig];
    auxIoConfig = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AAuxIoConfigChanged object:self];
}

//------------------- Address = 0x0848  Bit Field = 2..3 ---------------
- (uint32_t) sdPem { return sdPem; }
- (void) setSdPem:(uint32_t)aValue
{
    if(aValue > 0x0)aValue = 0x0;
    [[[self undoManager] prepareWithInvocationTarget:self] setSdPem:sdPem];
    sdPem = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASdPemChanged object:self];}

//------------------- Address = 0x0848  Bit Field = 9 ---------------
- (BOOL) sdSmLostLockFlag {return sdSmLostLockFlag; }
- (void) setSdSmLostLockFlag:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSdSmLostLockFlag:sdSmLostLockFlag];
    sdSmLostLockFlag = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASdSmLostLockFlagChanged object:self];
}

//------------------- Address = 0x0900  Bit Field = 0 ---------------
- (BOOL) configMainFpga { return configMainFpga; }
- (void) setConfigMainFpga:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setConfigMainFpga:configMainFpga];
    configMainFpga = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AConfigMainFpgaChanged object:self];
}

//------------------- Address = 0x0908  Bit Field = 0 ---------------
- (uint32_t) vmeStatus { return vmeStatus; }
- (void) setVmeStatus:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVmeStatus:vmeStatus];
    vmeStatus = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AVmeStatusChanged object:self];
}

//------------------- Address = 0x0910  Bit Field = 0 ---------------
- (BOOL) clkSelect0 { return clkSelect0; }
- (void) setClkSelect0:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClkSelect0:clkSelect0];
    clkSelect0 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AClkSelect0Changed object:self];
}

//------------------- Address = 0x0910  Bit Field = 1 ---------------
- (BOOL) clkSelect1 { return clkSelect1; }
- (void) setClkSelect1:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClkSelect1:clkSelect1];
    clkSelect1 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AClkSelect1Changed object:self];
}

//------------------- Address = 0x0910  Bit Field = 4 ---------------
- (BOOL) flashMode { return flashMode; }
- (void) setFlashMode:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFlashMode:flashMode];
    flashMode = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFlashModeChanged object:self];
}

//------------------- Address = 0X0920  Bit Field = 15..0 ---------------
- (uint32_t) serialNum { return serialNum; }
- (void) setSerialNum:(uint32_t)aValue
{
    if(aValue > 0xFFFF)aValue = 0xFFFF;
    serialNum = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ASerialNumChanged object:self];
}

//------------------- Address = 0X0920  Bit Field = 23..16 ---------------
- (uint32_t) boardRevNum { return boardRevNum; }
- (void) setBoardRevNum:(uint32_t)aValue
{
    if(aValue > 0xFF)aValue = 0xFF;
    boardRevNum = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ABoardRevNumChanged object:self];
}

//------------------- Address = 0X0920  Bit Field = 31..24 ---------------
- (uint32_t) vhdlVerNum { return vhdlVerNum; }
- (void) setVhdlVerNum:(uint32_t)aValue
{
    if(aValue > 0xFF)aValue = 0xFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setVhdlVerNum:vhdlVerNum];
    vhdlVerNum = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AVhdlVerNumChanged object:self];
}


#pragma mark - Hardware Access
//=============================================================================
//------------------------- low level calls------------------------------------
- (void) writeLong:(uint32_t)aValue toReg:(int)aReg
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress: [Gretina4ARegisters address:[self baseAddress] forReg:aReg]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeLong:(uint32_t)aValue toReg:(int)aReg channel:(int)aChan
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[Gretina4ARegisters address:[self baseAddress] forReg:aReg chan:aChan]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (uint32_t) readLongFromReg:(int)aReg
{
    uint32_t aValue = 0;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[Gretina4ARegisters address:[self baseAddress] forReg:aReg]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return aValue;
}

- (uint32_t) readLongFromReg:(int)aReg channel:(int)aChan
{
    uint32_t aValue = 0;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[Gretina4ARegisters address:[self baseAddress] forReg:aReg chan:aChan]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return aValue;
}

//------------------------- kBoardId Reg------------------------------------
- (short)readBoardIDReg         { return [self readLongFromReg:kBoardId]; }
- (BOOL) checkFirmwareVersion   { return [self checkFirmwareVersion:NO];  }



- (BOOL) checkFirmwareVersion:(BOOL)verbose
{
    //find out the Main FPGA version
    uint32_t mainVersion = ([self readLongFromReg:kBoardId] & 0xFFFF0000) >> 16;
    if(verbose)NSLog(@"Main FGPA version: 0x%x \n", mainVersion);
    
    if (mainVersion < kCurrentFirmwareVersion){
        NSLog(@"Main FPGA version does not match: 0x%x is required but 0x%x is loaded.\n", kCurrentFirmwareVersion,mainVersion);
        return NO;
    }
    else return YES;
}

- (BOOL) fifoIsEmpty
{
    uint32_t val = [self readLongFromReg:kProgrammingDone];
    return ((val>>20) & 0x3)==0x3; //both bits are high if FIFO is empty
}

//------------------------- kProgrammingDone Reg ------------------------------------
- (void) resetSingleFIFO
{
    [self resetFIFO];
}

- (void) resetFIFO
{

    uint32_t val = (0x1<<27); //all other bits are read-only.
    [self writeLong:val toReg:kProgrammingDone];
    [self writeLong:0   toReg:kProgrammingDone];
    
    if(![self fifoIsEmpty]){
        NSLogColor([NSColor redColor], @"%@ Fifo NOT reset properly\n",[self fullID]);
    }
}

//------------------------- Ext Discrim Src Reg------------------------------------
- (uint32_t) readExtDiscriminatorSrc { return [self readLongFromReg:kExternalDiscSrc] & 0x1fffffff; }
- (void) writeExtDiscriminatorSrc
{
    uint32_t theValue = (extDiscriminatorSrc & 0x3fffffff);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kExternalDiscSrc]
                       mask:0x3fffffff
                  reportKey:@"ExternalDiscSrc"
              forceFullInit:forceFullCardInit];
}

//------------------------- kHardwareStatus Reg------------------------------------
- (uint32_t) readHardwareStatus
{
    [self setHardwareStatus: [self readLongFromReg:kHardwareStatus]];
    return hardwareStatus;
}

//------------------------- kUserPackage Reg------------------------------------
- (uint32_t) readUserPackageData { return [self readLongFromReg:kUserPackageData] & 0xFFFF; }
- (void) writeUserPackageData
{
    [self writeAndCheckLong:(userPackageData & 0xFFFF)
              addressOffset:[Gretina4ARegisters offsetforReg:kUserPackageData]
                       mask:0xFFFF
                  reportKey:@"UserPackageData"
              forceFullInit:forceFullCardInit];
}

//------------------------- kWindowCompMin Reg------------------------------------
- (uint32_t) readWindowCompMin { return [self readLongFromReg:kWindowCompMin] & 0xFFFF; }
- (void) writeWindowCompMin
{
    [self writeAndCheckLong:(windowCompMin & 0xFFFF)
              addressOffset:[Gretina4ARegisters offsetforReg:kWindowCompMin]
                       mask:0xFFFF
                  reportKey:@"WindowCompMin"
              forceFullInit:forceFullCardInit];
}

//------------------------- kWindowCompMax Reg------------------------------------
- (uint32_t) readWindowCompMax { return [self readLongFromReg:kWindowCompMax] & 0xFFFF; }
- (void) writeWindowCompMax
{
    [self writeAndCheckLong:(windowCompMax & 0xFFFF)
              addressOffset:[Gretina4ARegisters offsetforReg:kWindowCompMax]
                       mask:0xFFFF
                  reportKey:@"WindowCompMax"
              forceFullInit:forceFullCardInit];
    
}
//-------------------------kChannelControl----------------------------------------
- (uint32_t) readControlReg:(unsigned short)channel { return [self readLongFromReg:kChannelControl]; }

- (void) writeControlReg:(unsigned short)chan enabled:(BOOL)forceEnable
{
    /* writeControlReg writes the current model state to the board.  If forceEnable is NO, *
     * then all the channels are disabled.  Otherwise, the channels are enabled according  *
     * to the model state.                                                                 */
    
    BOOL startStop;
    if(forceEnable)	startStop = enabled[chan];
    else			startStop = NO;

    uint32_t theValue =
    (startStop                        << 0)  |
    (!pileupMode[chan]                << 2)  |
    ((triggerPolarity[chan]  & 0x3)   << 10) |
    ((decimationFactor[chan] & 0x7)   << 12) |
    (downSamplePauseEnable            << 16) |
    (droppedEventCountMode[chan]      << 20) |
    (eventCountMode[chan]             << 21) |
    (aHitCountMode[chan]              << 22) |
    (discCountMode[chan]              << 23) |
    (pileupExtensionMode[chan]        << 26) |
    //(0x1L                             << 27) | //start counters
    (pileupWaveformOnlyMode[chan]     << 30);
    
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kChannelControl chan:chan]
                       mask:0x4ff1fc0d //mask off the reserved bits
                  reportKey:[NSString stringWithFormat:@"ControlStatus_%d",chan]
              forceFullInit:forceFullInit[chan]];
}



//-------------------------kLedThreshold Reg----------------------------------------
- (uint32_t) readLedThreshold:(unsigned short)channel
{
    if(channel<kNumGretina4AChannels){
        return [self readLongFromReg:kLedThreshold channel:channel];
    }
    else return 0;
}

- (void) writeLedThreshold:(unsigned short)aChan
{
    uint32_t theValue =  ledThreshold[aChan] & 0x3fff;
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kLedThreshold chan:aChan]
                       mask:0x03fff
                  reportKey:[NSString stringWithFormat:@"LedThreshold_%d",aChan]
              forceFullInit:forceFullInit[aChan]];
    
}

//-------------------------kRawDataLength Reg----------------------------------------
- (uint32_t) readRawDataLength:(unsigned short)aChan
{
    return [self readLongFromReg:kRawDataLength channel:aChan];
}

- (void) writeRawDataLength:(unsigned short)channel
{
    //***NOTE that we only write same value to all channels
    uint32_t theValue = (rawDataLength & 0x000003ff);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kRawDataLength chan:channel]
                       mask:0x000003ff
                  reportKey:[NSString stringWithFormat:@"RawDataLength_%d",channel]
              forceFullInit:forceFullInit[channel]];
    
}

//-------------------------kRawDataWindow Reg----------------------------------------
- (uint32_t) readRawDataWindow:(unsigned short)aChan
{
    return [self readLongFromReg:kRawDataWindow channel:aChan];
}

- (void) writeRawDataWindow:(unsigned short)aChan
{
    //***NOTE that we write same value to all
    uint32_t theValue = (rawDataWindow & 0x000007fc);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kRawDataWindow chan:aChan]
                       mask:0x000007fc
                  reportKey:[NSString stringWithFormat:@"RawDataWindow_%d",aChan]
              forceFullInit:forceFullInit[aChan]];

}


//-------------------------kDWindow Reg----------------------------------------
- (uint32_t) readDWindow:(unsigned short)aChan
{
    return [self readLongFromReg:kDWindow channel:aChan];
 }

- (void) writeDWindow:(unsigned short)aChan
{
    uint32_t theValue = (dWindow[aChan] & 0x0000007F);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kDWindow chan:aChan]
                       mask:0x0000007F
                  reportKey:[NSString stringWithFormat:@"DWindow_%d",aChan]
              forceFullInit:forceFullInit[aChan]];
}

//-------------------------kKWindow Reg----------------------------------------
- (uint32_t) readKWindow:(unsigned short)aChan
{
    return [self readLongFromReg:kKWindow channel:aChan];
}

- (void) writeKWindow:(unsigned short)aChan
{
    uint32_t theValue = (kWindow[aChan] & 0x0000007F);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kKWindow chan:aChan]
                       mask:0x0000007F
                  reportKey:[NSString stringWithFormat:@"KWindow_%d",aChan]
              forceFullInit:forceFullInit[aChan]];

}
//-------------------------kMWindow Reg----------------------------------------
- (uint32_t) readMWindow:(unsigned short)aChan
{
    if(aChan < kNumGretina4AChannels){
        return [self readLongFromReg:kMWindow channel:aChan];
    }
    else return 0;
}

- (void) writeMWindow:(unsigned short)aChan
{
    uint32_t theValue = (mWindow[aChan] & 0x0000003FF);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kMWindow chan:aChan]
                       mask:0x0000003FF
                  reportKey:[NSString stringWithFormat:@"MWindow_%d",aChan]
              forceFullInit:forceFullInit[aChan]];
    
}


//-------------------------kD3Window Reg----------------------------------------
- (uint32_t)readD3Window:(unsigned short)aChan
{
    return [self readLongFromReg:kD3Window channel:aChan];
}

- (void) writeD3Window:(unsigned short)aChan
{
        uint32_t theValue = (d3Window[aChan] & 0x0000007F);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kD3Window chan:aChan]
                       mask:0x0000007F
                  reportKey:[NSString stringWithFormat:@"D3Window_%d",aChan]
              forceFullInit:forceFullInit[aChan]];
}

//-------------------------kDiscWidth Reg----------------------------------------
- (uint32_t) readDiscWidth:(unsigned short)aChan
{
    return [self readLongFromReg:kDiscWidth channel:aChan];
}
- (void) writeDiscWidth:(unsigned short)aChan
{
    uint32_t theValue = (discWidth[aChan] & 0x0000001F);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kDiscWidth chan:aChan]
                       mask:0x0000001F
                  reportKey:[NSString stringWithFormat:@"DiscWidth%d",aChan]
              forceFullInit:forceFullInit[aChan]];
}

//-------------------------kBaselineStart Reg----------------------------------------
- (uint32_t) readBaselineStart:(unsigned short)aChan
{
    return [self readLongFromReg:kBaselineStart channel:aChan];
}

- (void) writeBaselineStart:(unsigned short)aChan
{
    uint32_t theValue = (baselineStart[aChan] & 0x00003FFF);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kBaselineStart chan:aChan]
                       mask:0x00003FFF
                  reportKey:[NSString stringWithFormat:@"BaselineStart%d",aChan]
              forceFullInit:forceFullInit[aChan]];
}

//-------------------------kP1Window Reg----------------------------------------
- (uint32_t) readP1Window:(unsigned short)aChan
{
    return [self readLongFromReg:kP1Window channel:aChan];
}

- (void) writeP1Window:(unsigned short)aChan
{
    uint32_t theValue = (p1Window[aChan] & 0x0000000F);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kP1Window chan:aChan]
                       mask:0x0000000F
                  reportKey:[NSString stringWithFormat:@"P1Window_%d",aChan]
              forceFullInit:forceFullInit[aChan]];
}

//-------------------------kP2Window Reg----------------------------------------
- (uint32_t) readP2Window
{
    return [self readLongFromReg:kP2Window];
}

- (void) writeP2Window
{
    uint32_t theValue = (p2Window & 0x0000003ff);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kP2Window]
                       mask:0x0000003ff
                  reportKey:@"P2Window"
              forceFullInit:forceFullCardInit];
}

//-------------------------kChannelPulsedControl Reg----------------------------------------
- (void) loadBaselines
{
    uint32_t theValue = 0x4;
    
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kChannelPulsedControl]
                       mask:0x0
                  reportKey:@"LoadBaselines"
              forceFullInit:forceFullCardInit];

    [self writeLong:theValue toReg:kChannelPulsedControl];
}
- (void) loadDelays
{
    uint32_t theValue = 0x1;
    
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kChannelPulsedControl]
                       mask:0x0
                  reportKey:@"LoadDelays"
              forceFullInit:forceFullCardInit];
    
    [self writeLong:theValue toReg:kChannelPulsedControl];
}

//-------------------------kBaselineDelay Reg----------------------------------------
- (uint32_t) readBaselineDelay
{
    return [self readLongFromReg:kBaselineDelay];
}

- (void) writeBaselineDelay
{
    uint32_t theValue = (baselineDelay & 0x00003fff);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kBaselineDelay]
                       mask:0x00003fff
                  reportKey:@"BaselineDelay"
              forceFullInit:forceFullCardInit];
}

//------------------------- Ext Discrim Mode Reg------------------------------------
- (uint32_t) readExtDiscriminatorMode { return [self readLongFromReg:kExternalDiscMode] & 0xfffff; }
- (void) writeExtDiscriminatorMode
{
    uint32_t theValue = (extDiscriminatorMode & 0xfffff);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kExternalDiscMode]
                       mask:0xfffff
                  reportKey:@"ExternalDiscMode"
              forceFullInit:forceFullCardInit];
}


//-------------------------kHoldoffControl Reg----------------------------------------
- (uint32_t) readHoldoffControl
{
    return [self readLongFromReg:kHoldoffControl];
}

- (void) writeHoldoffControl
{
    uint32_t theValue = ((holdOffTime     & 0x1FF) << 0) |
                             ((peakSensitivity & 0x007) << 9)  |
                             ((autoMode        & 0x001) << 12);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kHoldoffControl]
                       mask:0x00001FFF
                  reportKey:@"holdoffControl"
              forceFullInit:forceFullCardInit];
}
//-------------------------kDownSampleHoldoff Reg----------------------------------------
- (uint32_t) readDownSampleHoldOffTime
{
    return [self readLongFromReg:kDownSampleHoldOffTime];
}

- (void) writeDownSampleHoldOffTime
{
    uint32_t theValue = downSampleHoldOffTime;
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kDownSampleHoldOffTime]
                       mask:0x00003FF
                  reportKey:@"holdoffControl"
              forceFullInit:forceFullCardInit];
}

//-------------------------Timestamp Regs----------------------------------------
- (uint64_t) readLatTimeStamp
{
    uint32_t      ts1 =  [self readLongFromReg:kLatTimestampLsb];
    uint64_t ts2 =  [self readLongFromReg:kLatTimestampMsb];
    return (ts2<<32) | ts1;
}

- (uint64_t) readLiveTimeStamp
{
    uint32_t      ts1 =  [self readLongFromReg:kLiveTimestampLsb];
    uint64_t ts2 =  [self readLongFromReg:kLiveTimestampMsb];
    return (ts2<<32) | ts1;
}

//-------------------------kVetoGateWidth Reg----------------------------------------
- (uint32_t) readVetoGateWidth
{
    return [self readLongFromReg:kVetoGateWidth] & 0x00003fff;
}

- (void) writeVetoGateWidth
{
    [self writeAndCheckLong:(vetoGateWidth & 0x00003fff)
              addressOffset:[Gretina4ARegisters offsetforReg:kVetoGateWidth]
                       mask:0x00003fff
                  reportKey:@"VetoGateWidth"
              forceFullInit:forceFullCardInit];
}

//-------------------------kMasterLogicStatus Reg----------------------------------------
- (void) writeMasterLogic:(BOOL)enable
{
    uint32_t oldValue = 0x00020011;
    uint32_t newValue;
    if(enable) newValue = oldValue |  0x1;
    else       newValue = oldValue & ~0x1;
    [self writeAndCheckLong:newValue
              addressOffset:[Gretina4ARegisters offsetforReg:kMasterLogicStatus]
                       mask:0x20011 //mask off the reserved bits
                  reportKey:@"masterLogic"
              forceFullInit:YES];
}

//-------------------------kTriggerConfig Reg----------------------------------------
- (uint32_t) readTriggerConfig
{
    return [self readLongFromReg:kTriggerConfig];
}

- (void) writeTriggerConfig
{
    uint32_t theValue = (triggerConfig & 0x00000003);
    [self writeAndCheckLong:theValue
              addressOffset:[Gretina4ARegisters offsetforReg:kTriggerConfig]
                       mask:0x00000003
                  reportKey:@"TriggerConfig"
              forceFullInit:forceFullCardInit];
}

//-------------------------kCodeRevision Reg----------------------------------------
- (void) readCodeRevision
{
    uint32_t codeVersion = [self readLongFromReg:kCodeRevision];
    NSLog(@"Gretina4A %d code revisions:\n",[self slot]);
    NSLog(@"PCB : 0x%X \n",         (codeVersion >> 12) & 0xf);
    NSLog(@"FW Type: 0x%X \n",      (codeVersion >> 8)& 0xf);
    NSLog(@"Code: %02d.%02d \n",    ((codeVersion>>  4) & 0xf),(codeVersion&0xf));
}


//-------------------------kVMEFPGAVersionStatus Reg----------------------------------------
- (void) readFPGAVersions
{
    //find out the VME FPGA version
    uint32_t vmeVersion = [self readFPGARegister:kVMEFPGAVersionStatus];
    NSLog(@"Gretina4A %d FPGA version:\n",[self slot]);
    NSLog(@"VME FPGA serial number: 0x%X \n",  ((vmeVersion >> 0) & 0xFFFF));
    NSLog(@"BOARD Revision number: 0x%X \n",   ((vmeVersion >>16) & 0xFF));
    NSLog(@"VME FPGA Version number: 0x%X \n", ((vmeVersion >>24) & 0xFF));
}

//-------------------------kVMEGPControl Reg----------------------------------------
- (short) readClockSource
{
    return [self readFPGARegister:kVMEGPControl] & 0x3;
}
- (void) writeClockSource: (uint32_t) clocksource
{
    if(clocksource == 0)return; ////temp..... Clock source might be set by the Trigger Card init code.
    [self writeAndCheckLong:clocksource
              addressOffset:[Gretina4AFPGARegisters address:[self baseAddress] forReg:kVMEGPControl]
                       mask:0x3
                  reportKey:@"ClockSource"
              forceFullInit:forceFullCardInit];
}

- (void) writeClockSource
{
    [self writeClockSource:clockSource];
}
//-------------------------kAuxStatus Reg----------------------------------------
- (uint32_t) readVmeAuxStatus
{
    return [self readFPGARegister:kAuxStatus];
}

- (void) resetBoard
{
    /* First disable all channels. This does not affect the model state,
     just the board state. */
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [self writeControlReg:i enabled:NO];
    }
    
    [self resetFIFO];
    [self resetMainFPGA];
    [ORTimer delay:6];  // 6 second delay during board reset
}

- (void) resetMainFPGA
{
    uint32_t theValue = 0x10;
    [[self adapter] writeLongBlock:&theValue
                         atAddress: [Gretina4AFPGARegisters address:[self baseAddress] forReg:kMainFPGAControl]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
    sleep(1);
    
    theValue = 0x00;
    [[self adapter] writeLongBlock:&theValue
                         atAddress:[Gretina4AFPGARegisters address:[self baseAddress] forReg:kMainFPGAControl]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) initBoard
{
    [self initBoard:YES];
}

- (void) initBoard:(BOOL)doChannelEnable
{
    //[self writeMasterLogic:NO]; //disable
   // [self writeFPGARegister:kVMEGPControl   withValue:0x1 ]; //set clock to internal  (NOT using trigger system)

    int i;
    if(doChannelEnable){
        for(i=0;i<kNumGretina4AChannels;i++) {
            [self writeControlReg:i enabled:NO];
        }
        //write the card level params
        [self writeExtDiscriminatorSrc];
        [self writeExtDiscriminatorMode];
        [self writeWindowCompMin];
        [self writeWindowCompMax];
        [self writeP2Window];
        [self writeHoldoffControl];
        [self writeDownSampleHoldOffTime];
        [self writeBaselineDelay];
        [self loadBaselines];
        [self writeVetoGateWidth];
        [self writeTriggerConfig];
        
        //write the channel level params
        for(i=0;i<kNumGretina4AChannels;i++) {
            [self writeLedThreshold:i];
            [self writeRawDataLength:i];    //only [0] is used
            [self writeRawDataWindow:i];    //only [0] is used
            [self writeDWindow:i];
            [self writeKWindow:i];
            [self writeMWindow:i];
            [self writeD3Window:i];
            [self writeDiscWidth:i];
            [self writeBaselineStart:i];
            [self writeP1Window:i];
        }
        [self loadDelays];
     
        //enable channels
        for(i=0;i<kNumGretina4AChannels;i++) {
            [self writeControlReg:i enabled:[self enabled:i]];
        }
        [self clearCounters];

        [self writeLong:(0x1<<27) toReg:kProgrammingDone]; //reset
        [self writeLong:0   toReg:kProgrammingDone];
        [self writeMasterLogic:YES];
    }

    if(doHwCheck)[self checkBoard:YES];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ACardInited object:self];
}

- (void) softwareTrigger
{
    [self writeLong:0x1<<10 toReg:kChannelPulsedControl];
}


- (void) writeThresholds
{
    NSLog(@"%@ Manual load of thresholds\n",[self fullID]);
    int i;
    for(i=0;i<kNumGretina4AChannels;i++) {
        [self writeLedThreshold:i];
    }
}
- (void) checkBoard:(BOOL)verbose
{
    BOOL extDiscriminatorSrcResult   = [self checkExtDiscriminatorSrc:verbose];
    BOOL extDiscriminatorModeResult  = [self checkExtDiscriminatorMode:verbose];
    BOOL windowCompMinResult         = [self checkWindowCompMin:verbose];
    BOOL windowCompMaxResult         = [self checkWindowCompMax:verbose];
    BOOL p2WindowResult              = [self checkP2Window:verbose];
    BOOL holdoffControlResult        = [self checkHoldoffControl:verbose];
    BOOL downSampleHoldOffTimeResult = [self checkDownSampleHoldOffTime:verbose];
    
    
    unsigned short ledThresholdResultMask   = 0xFFFF; //assume all OK
    unsigned short baselineStartResultMask  = 0xFFFF; //assume all OK
    unsigned short rawDataLengthResultMask  = 0xFFFF; //assume all OK
    unsigned short rawDataWindowResultMask  = 0xFFFF; //assume all OK
    unsigned short dWindowResultMask        = 0xFFFF; //assume all OK
    unsigned short kWindowResultMask        = 0xFFFF; //assume all OK
    unsigned short mWindowResultMask        = 0xFFFF; //assume all OK
    unsigned short d3WindowResultMask       = 0xFFFF; //assume all OK
    unsigned short discWidthResultMask      = 0xFFFF; //assume all OK
    unsigned short p1WindowResultMask       = 0xFFFF; //assume all OK

    
    int i;
    for(i=0;i<kNumGretina4AChannels;i++) {
        if([self enabled:i]){
            if(![self checkLedThreshold:i verbose:verbose])  ledThresholdResultMask  ^= (0x1<<i);
            if(![self checkBaselineStart:i verbose:verbose]) baselineStartResultMask ^= (0x1<<i);
            if(![self checkRawDataLength:i verbose:verbose]) rawDataLengthResultMask ^= (0x1<<i);
            if(![self checkRawDataWindow:i verbose:verbose]) rawDataWindowResultMask ^= (0x1<<i);
            
            if(![self checkDWindow:i verbose:verbose])  dWindowResultMask   ^= (0x1<<i);
            if(![self checkKWindow:i verbose:verbose])  kWindowResultMask   ^= (0x1<<i);
            if(![self checkMWindow:i verbose:verbose])  mWindowResultMask   ^= (0x1<<i);
            if(![self checkD3Window:i verbose:verbose]) d3WindowResultMask  ^= (0x1<<i);
            if(![self checkDiscWidth:i verbose:verbose])discWidthResultMask ^= (0x1<<i);
            if(![self checkP1Window:i verbose:verbose]) p1WindowResultMask  ^= (0x1<<i);
         }
    }
    if(verbose){
        if( extDiscriminatorSrcResult   &&
            extDiscriminatorModeResult  &&
            windowCompMinResult         &&
            windowCompMaxResult         &&
            p2WindowResult              &&
            holdoffControlResult        &&
            ledThresholdResultMask      &&
            baselineStartResultMask     &&
            dWindowResultMask           &&
            kWindowResultMask           &&
            mWindowResultMask           &&
            d3WindowResultMask          &&
            discWidthResultMask         &&
            p1WindowResultMask          &&
            downSampleHoldOffTimeResult ){
           
            NSLog(@"%@ HW registers match dialog values\n",[self fullID]);
        }
    }
}

- (BOOL) checkExtDiscriminatorSrc:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kExternalDiscSrc]& 0x3fffffff;
    if(aValue == extDiscriminatorSrc)return YES;
    else {
        if(verbose)NSLog(@"extDiscriminatorSrc mismatch: 0x%x != 0x%x\n",aValue,extDiscriminatorSrc);
        return NO;
    }
}
- (BOOL) checkExtDiscriminatorMode:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kExternalDiscMode]& 0xfffff;
    if(aValue == extDiscriminatorMode)return YES;
    else {
        if(verbose)NSLog(@"extDiscriminatorMode mismatch: 0x%x != 0x%x\n",aValue,extDiscriminatorMode);
        return NO;
    }
}

- (BOOL) checkWindowCompMin:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kWindowCompMin] & 0xFFFF;
    if(aValue == windowCompMin)return YES;
    else {
        if(verbose)NSLog(@"windowCompMin mismatch: 0x%x != 0x%x\n",aValue,windowCompMin);
        return NO;
    }
}

- (BOOL) checkWindowCompMax:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kWindowCompMax] & 0xFFFF;
    if(aValue == windowCompMax)return YES;
    else {
        if(verbose)NSLog(@"windowCompMax mismatch: 0x%x != 0x%x\n",aValue,windowCompMax);
        return NO;
    }
}

- (BOOL) checkP2Window:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kP2Window] & 0x3ff;
    if(aValue == p2Window)return YES;
    else {
        if(verbose)NSLog(@"p2Window mismatch: 0x%x != 0x%x\n",aValue,p2Window);
        return NO;
    }
}

- (BOOL) checkDownSampleHoldOffTime:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kDownSampleHoldOffTime] & 0x3ff;
    if(aValue == downSampleHoldOffTime)return YES;
    else {
        if(verbose)NSLog(@"down sample holdoff time mismatch: 0x%x != 0x%x\n",aValue,downSampleHoldOffTime);
        return NO;
    }
}

- (BOOL) checkHoldoffControl:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kHoldoffControl];
    uint32_t theValue = ((holdOffTime     & 0x1FF) << 0) |
                             ((peakSensitivity & 0x007) << 9)  |
                             ((autoMode        & 0x001) << 12);

    if( ( (aValue       & 0x1FF) == holdOffTime)     &&
        (((aValue >> 9) & 0x007) == peakSensitivity) &&
        (((aValue >>12) & 0x001) == autoMode)) return YES;
    else {
        if(verbose)NSLog(@"holdOffControl mismatch: 0x%x != 0x%x\n",aValue & (0x1FF | (0x007<<9) | (0x001<<12)),theValue);
        return NO;
    }
}

- (BOOL) checkDiscWidth:(int)aChan verbose:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kDiscWidth channel:aChan] & 0x0000001F;
    
    if(aValue == discWidth[aChan])return YES;
    else {
        if(verbose)NSLog(@"discWidth mismatch: 0x%x != 0x%x\n",aValue,discWidth[aChan]);
        return NO;
    }
}
- (BOOL) checkP1Window:(int)aChan verbose:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kP1Window channel:aChan] & 0x0000000F;
    
    if(aValue == p1Window[aChan])return YES;
    else {
        if(verbose)NSLog(@"p1Window mismatch: 0x%x != 0x%x\n",aValue,p1Window[aChan]);
        return NO;
    }
}


- (BOOL) checkDWindow:(int)aChan verbose:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kDWindow channel:aChan] & 0x0000007F;
    
    if(aValue == dWindow[aChan])return YES;
    else {
        if(verbose)NSLog(@"dWindow mismatch: 0x%x != 0x%x\n",aValue,dWindow[aChan]);
        return NO;
    }
}

- (BOOL) checkKWindow:(int)aChan verbose:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kKWindow channel:aChan] & 0x0000007F;
    
    if(aValue == kWindow[aChan])return YES;
    else {
        if(verbose)NSLog(@"kWindow mismatch: 0x%x != 0x%x\n",aValue,kWindow[aChan]);
        return NO;
    }
}
               
- (BOOL) checkMWindow:(int)aChan verbose:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kMWindow channel:aChan] & 0x0000003FF;
    
    if(aValue == mWindow[aChan])return YES;
    else {
        if(verbose)NSLog(@"mWindow mismatch: 0x%x != 0x%x\n",aValue,mWindow[aChan]);
        return NO;
    }
}
               
- (BOOL) checkD3Window:(int)aChan verbose:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kD3Window channel:aChan] & 0x0000007F;
    
    if(aValue == d3Window[aChan])return YES;
    else {
        if(verbose)NSLog(@"d3Window mismatch: 0x%x != 0x%x\n",aValue,d3Window[aChan]);
        return NO;
    }
}
    
- (BOOL) checkLedThreshold:(int)aChan verbose:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kLedThreshold channel:aChan] & 0x3fff;
    
    if(aValue == ledThreshold[aChan])return YES;
    else {
        if(verbose)NSLog(@"ledThreshold mismatch: 0x%x != 0x%x\n",aValue,ledThreshold[aChan]);
        return NO;
    }
}

- (BOOL) checkRawDataWindow:(int)aChan verbose:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kRawDataWindow channel:aChan] & 0x7fc;
    
    if(aValue == rawDataWindow)return YES;
    else {
        if(verbose)NSLog(@"rawDataWindow mismatch: 0x%x != 0x%x\n",aValue,rawDataWindow);
        return NO;
    }
}

- (BOOL) checkRawDataLength:(int)aChan verbose:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kRawDataLength channel:aChan] & 0x3fe;
    
    if(aValue == rawDataLength)return YES;
    else {
        if(verbose)NSLog(@"rawDataLength mismatch: 0x%x != 0x%x\n",aValue,rawDataLength);
        return NO;
    }
}

- (BOOL) checkBaselineStart:(int)aChan verbose:(BOOL)verbose
{
    uint32_t aValue = [self readRegister:kBaselineStart channel:aChan] & 0x3fff;
    
    if(aValue == baselineStart[aChan])return YES;
    else {
        if(verbose)NSLog(@"baselineStart mismatch: 0x%x != 0x%x\n",aValue,baselineStart[aChan]);
        return NO;
    }
}

- (BOOL) checkBaselineDelay:(BOOL)verbose
{
    uint32_t aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[Gretina4ARegisters offsetforReg:kBaselineDelay]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x00003fff) == baselineDelay)return YES;
    else {
        if(verbose)NSLog(@"baselineDelay mismatch: 0x%x != 0x%x\n",aValue & 0x00003fff,baselineDelay);
        return NO;
    }
}

- (BOOL) checkVetoGateWidth:(BOOL)verbose
{
    uint32_t aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[Gretina4ARegisters offsetforReg:kVetoGateWidth]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x00003fff) == vetoGateWidth)return YES;
    else {
        if(verbose)NSLog(@"vetoGateWidth mismatch: 0x%x != 0x%x\n",aValue & 0x00003fff,vetoGateWidth);
        return NO;
    }
}

- (BOOL) checkTriggerConfig:(BOOL)verbose
{
    uint32_t aValue = 0 ;
    [[self adapter] readLongBlock:&aValue
                        atAddress:[Gretina4ARegisters offsetforReg:kTriggerConfig]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    if((aValue & 0x00000003) == triggerConfig)return YES;
    else {
        if(verbose)NSLog(@"triggerConfig mismatch: 0x%x != 0x%x\n",aValue & 0x00000003,triggerConfig);
        return NO;
    }
}

//=========================================================================
#pragma mark - Clock Sync
- (short) initState {return initializationState;}
- (void) setInitState:(short)aState
{
    initializationState = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AModelInitStateChanged object:self];
}

- (void) stepSerDesInit
{
    int i;
    switch(initializationState){
        case kSerDesSetup:
            [self writeRegister:kMasterLogicStatus  withValue: 0x00000051]; //power up value
            [self writeRegister:kSdConfig           withValue: 0x00001231]; //T/R SerDes off, reset clock manager, reset clocks
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
            for(i=0;i<kNumGretina4AChannels;i++){
                [self writeControlReg:i enabled:NO];
            }
            
            [self resetFIFO];
            [self setInitState:kReleaseClkManager];
            break;
            
        case kReleaseClkManager:
            //SERDES still disabled, release clk manager, clocks still held at reset
            [self writeRegister:kSdConfig           withValue: 0x00000211];
            [self setInitState:kPowerUpRTPower];
            break;
            
        case kPowerUpRTPower:
            //SERDES enabled, clocks still held at reset
            [self writeRegister:kSdConfig           withValue: 0x00000200];
            [self setInitState:kSetMasterLogic];
            break;
            
        case kSetMasterLogic:
            [self writeRegister:kMasterLogicStatus  withValue: 0x00000051]; //power up value
            [self setInitState:kSetSDSyncBit];
            break;
            
        case kSetSDSyncBit:
            [self writeRegister:kSdConfig           withValue: 0x00000000]; //release the clocks
            [self writeRegister:kSdConfig           withValue: 0x00000020]; //set sd syn
            
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4ALockChanged object: self];
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


//==============================================================


#pragma mark - Data Taker
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
                                 @"ORGretina4AWaveformDecoder",           @"decoder",
                                 [NSNumber numberWithLong:dataId],        @"dataId",
                                 [NSNumber numberWithBool:YES],           @"variable",
                                 [NSNumber numberWithLong:-1],			  @"length",
                                 nil];
    [dataDictionary setObject:aDictionary forKey:@"Gretina4A"];
    
    return dataDictionary;
}

#pragma mark - HW Wizard
-(BOOL) hasParmetersToRamp
{
    return YES;
}

- (int) numberOfChannels
{
    return kNumGretina4AChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setOncePerCard:YES];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEnabled:withValue:) getMethod:@selector(enabled:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pile Up Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setPileupMode:withValue:) getMethod:@selector(pileupMode:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Dropped Event Count Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setDroppedEventCountMode:withValue:) getMethod:@selector(droppedEventCountMode:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Event Count Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEventCountMode:withValue:) getMethod:@selector(eventCountMode:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"LED Threshold"];
    [p setFormat:@"##0" upperLimit:0x3fff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setLedThreshold:withValue:) getMethod:@selector(ledThreshold:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
 
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"P1 Window"];
    [p setFormat:@"##0" upperLimit:15 lowerLimit:0 stepSize:1 units:@"x10ns"];
    [p setSetMethod:@selector(setP1Window:withValue:) getMethod:@selector(p1Window:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"K Window"];
    [p setFormat:@"##0" upperLimit:127 lowerLimit:0 stepSize:1 units:@"x10ns"];
    [p setSetMethod:@selector(setKWindow:withValue:) getMethod:@selector(kWindow:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"D Window"];
    [p setFormat:@"##0" upperLimit:127 lowerLimit:0 stepSize:1 units:@"x10ns"];
    [p setSetMethod:@selector(setDWindow:withValue:) getMethod:@selector(dWindow:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"D3 Window"];
    [p setFormat:@"##0" upperLimit:127 lowerLimit:0 stepSize:1 units:@"x10ns"];
    [p setSetMethod:@selector(setD3Window:withValue:) getMethod:@selector(d3Window:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"M Window"];
    [p setFormat:@"##0" upperLimit:0x3fffff lowerLimit:0 stepSize:1 units:@"x10ns"];
    [p setSetMethod:@selector(setMWindow:withValue:) getMethod:@selector(mWindow:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
  
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Descrim Width"];
    [p setFormat:@"##0" upperLimit:0x3F lowerLimit:0 stepSize:1 units:@"x20ns"];
    [p setSetMethod:@selector(setDiscWidth:withValue:) getMethod:@selector(discWidth:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Baseline Start"];
    [p setFormat:@"##0" upperLimit:0x3fff lowerLimit:0 stepSize:1 units:@"x10ns"];
    [p setSetMethod:@selector(setBaselineStart:withValue:) getMethod:@selector(baselineStart:)];
    [p setCanBeRamped:YES];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:0x2 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];

    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Force Full Init"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setForceFullInit:withValue:) getMethod:@selector(forceFullInit:)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel  name:@"Crate"   className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel     name:@"Card"    className:@"ORGretina4AModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel    name:@"Channel" className:@"ORGretina4AModel"]];
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
    firstTime = YES;
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    if(![self checkFirmwareVersion]){
        [NSException raise:@"Wrong Firmware" format:@"You must have firmware version 0x%x installed.",kCurrentFirmwareVersion];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORGretina4A"];
    
    
    if(serialNumber==0){
        @try {
            [[self adapter] readLongBlock:&serialNumber
                                atAddress:[Gretina4AFPGARegisters address:[self baseAddress] forReg:kVMEFPGAVersionStatus]
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
    fifoStateAddress= [self baseAddress] + [Gretina4ARegisters address:[self baseAddress] forReg:kProgrammingDone];
    
    fifoResetCount = 0;
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
    //return;
    isRunning = YES;
    NSString* errorLocation = @"";
    @try {
        if(![self fifoIsEmpty]){
            short orcaHeaderLen = 2;
            uint32_t dataLength = [self rawDataWindow]/2 + 1;
            dataBuffer[0] = dataId | (orcaHeaderLen + dataLength); //length + 2 longs + orca header
            dataBuffer[1] = location;
            
            [theController readLong:&dataBuffer[2]
                          atAddress:fifoAddress
                        timesToRead:dataLength
                         withAddMod:[self addressModifier]
                      usingAddSpace:0x01];

            if(dataBuffer[2]==kGretina4APacketSeparator){
                short chan = dataBuffer[3] & 0xf;
                if(chan < 10){
                    ++waveFormCount[dataBuffer[3] & 0x7];  //grab the channel and inc the count
                    [aDataPacket addLongsToFrameBuffer:dataBuffer length:orcaHeaderLen + dataLength];
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
        NSLogError(@"",@"Gretina4A Card Error",errorLocation,nil);
        [self incExceptionCount];
        [localException raise];
    }
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{

    @try {
        if([[userInfo objectForKey:@"doinit"]boolValue]==1){
            int i;
            for(i=0;i<kNumGretina4AChannels;i++){
                [self writeControlReg:i enabled:NO];
            }
        }
        else {
            NSLog(@"Quick Start Enabled. %@ left running.\n",[self fullID]);
        }

    }
    @catch(NSException* e){
        [self incExceptionCount];
        NSLogError(@"",@"Gretina4A Card Error",nil);
    }
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
    //stop all channels
    short i;
    for(i=0;i<kNumGretina4AChannels;i++){
        waveFormCount[i] = 0;
    }
    
    //[self writeMasterLogic:NO];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkFifoAlarm) object:nil];
}

- (void) checkFifoAlarm
{
    if(((fifoState & kGretina4AFIFOAlmostFull) != 0) && isRunning){
        fifoEmptyCount = 0;
        if(!fifoFullAlarm){
            NSString* alarmName = [NSString stringWithFormat:@"FIFO Almost Full Gretina4A (slot %d)",[self slot]];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFIFOCheckChanged object:self];
}

- (void) reset { ; }

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        waveFormCount[i]=0;
    }
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(isRunning)return NO;
    ++waveFormCount[channel];
    return YES;
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
    configStruct->total_cards++;
    configStruct->card_info[index].hw_type_id				= kGretina4A; //should be unique
    configStruct->card_info[index].hw_mask[0]				= dataId; //better be unique
    configStruct->card_info[index].slot						= [self slot];
    configStruct->card_info[index].crate					= [self crateNumber];
    configStruct->card_info[index].add_mod					= [self addressModifier];
    configStruct->card_info[index].base_add					= [self baseAddress];
    configStruct->card_info[index].deviceSpecificData[0]	= [Gretina4ARegisters offsetforReg:kProgrammingDone];  //fifoStateAddress
    configStruct->card_info[index].deviceSpecificData[1]	= [Gretina4ARegisters offsetforReg:kFifo]; // fifoAddress
    configStruct->card_info[index].deviceSpecificData[2]	= [Gretina4ARegisters offsetforReg:kProgrammingDone];   // fifoReset Address
    configStruct->card_info[index].deviceSpecificData[3]	= [self rawDataWindow]/2 + 1; //longs
    configStruct->card_info[index].num_Trigger_Indexes		= 0;
    
    configStruct->card_info[index].next_Card_Index 	= index+1;
    
    return index+1;
}

#pragma mark - Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setForceFullCardInit:         [decoder decodeBoolForKey:  @"forceFullCardInit"]];
    [self setDoHwCheck:                 [decoder decodeBoolForKey:  @"doHwCheck"]];
    [self setSpiConnector:              [decoder decodeObjectForKey:@"spiConnector"]];
    [self setLinkConnector:             [decoder decodeObjectForKey:@"linkConnector"]];
    [self setRegisterIndex:				[decoder decodeIntForKey:   @"registerIndex"]];
    [self setSelectedChannel:           [decoder decodeIntegerForKey:   @"selectedChannel"]];
    [self setRegisterWriteValue:		[decoder decodeIntForKey: @"registerWriteValue"]];
    [self setSPIWriteValue:     		[decoder decodeIntForKey: @"spiWriteValue"]];
    [self setFpgaFilePath:				[decoder decodeObjectForKey:@"fpgaFilePath"]];
    [self setExtDiscriminatorSrc:       [decoder decodeIntForKey: @"extDiscriminatorSrc"]];
    [self setExtDiscriminatorMode:      [decoder decodeIntForKey: @"extDiscriminatorMode"]];
    [self setUserPackageData:           [decoder decodeIntForKey: @"userPackageData"]];
    [self setWindowCompMin:             [decoder decodeIntegerForKey:   @"windowCompMin"]];
    [self setWindowCompMax:             [decoder decodeIntegerForKey:   @"windowCompMax"]];
    [self setP2Window:                  [decoder decodeIntegerForKey:   @"p2Window"]];
    [self setDacChannelSelect:          [decoder decodeIntegerForKey:   @"dacChannelSelect"]];
    [self setDacAttenuation:            [decoder decodeIntegerForKey:   @"dacAttenuation"]];
    [self setChannelPulsedControl:      [decoder decodeIntForKey: @"channelPulsedControl"]];
    [self setDiagMuxControl:            [decoder decodeIntForKey: @"diagMuxControl"]];
    [self setHoldOffTime:               [decoder decodeIntegerForKey:   @"holdOffTime"]];
    [self setDownSampleHoldOffTime:     [decoder decodeIntegerForKey:   @"downSampleHoldOffTime"]];
    [self setDownSamplePauseEnable:     [decoder decodeBoolForKey:  @"downSamplePauseEnable"]];
    [self setPeakSensitivity:           [decoder decodeIntegerForKey:   @"peakSensitivity"]];
    [self setAutoMode:                  [decoder decodeBoolForKey:  @"autoMode"]];
    [self setTrackingSpeed:             [decoder decodeIntegerForKey:   @"trackingSpeed"]];
    [self setBaselineDelay:             [decoder decodeIntegerForKey:   @"baselineDelay"]];
    [self setDiagInput:                 [decoder decodeIntegerForKey:   @"diagInput"]];
    [self setDiagChannelEventSel:       [decoder decodeIntegerForKey: @"diagChannelEventSel"]];
    [self setRj45SpareIoDir:            [decoder decodeBoolForKey:  @"rj45SpareIoDir"]];
    [self setRj45SpareIoMuxSel:         [decoder decodeIntForKey: @"rj45SpareIoMuxSel"]];
    [self setVetoGateWidth:             [decoder decodeIntegerForKey: @"vetoGateWidth"]];
    [self setTriggerConfig:             [decoder decodeIntegerForKey:   @"triggerConfig"]];
    [self setTSErrCntCtrl:              [decoder decodeIntForKey: @"tSErrCntCtrl"]];
    [self setClkSelect0:                [decoder decodeBoolForKey:  @"clkSelect0"]];
    [self setClkSelect1:                [decoder decodeBoolForKey:  @"clkSelect1"]];
    [self setAuxIoRead:                 [decoder decodeIntForKey: @"auxIoRead"]];
    [self setAuxIoWrite:                [decoder decodeIntForKey: @"auxIoWrite"]];
    [self setAuxIoConfig:               [decoder decodeIntForKey: @"auxIoConfig"]];
    [self setRawDataLength:             [decoder decodeIntegerForKey:   @"rawDataLength"]];
    [self setRawDataWindow:             [decoder decodeIntegerForKey:   @"rawDataWindow"]];
    [self setClockSource:               [decoder decodeIntegerForKey:   @"clockSource"]];

    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [self setForceFullInit:i           withValue: [decoder decodeIntegerForKey:   [@"forceFullInit"          stringByAppendingFormat:@"%d",i]]];
        [self setPileupWaveformOnlyMode:i  withValue: [decoder decodeBoolForKey:  [@"pileupWaveformOnlyMode" stringByAppendingFormat:@"%d",i]]];
        [self setPileupExtensionMode:i     withValue: [decoder decodeBoolForKey:  [@"pileExtensionMode"      stringByAppendingFormat:@"%d",i]]];
        [self setAHitCountMode:i           withValue: [decoder decodeBoolForKey:  [@"aHitCountMode"          stringByAppendingFormat:@"%d",i]]];
        [self setDiscCountMode:i           withValue: [decoder decodeBoolForKey:  [@"discCountMode"          stringByAppendingFormat:@"%d",i]]];
        [self setEventCountMode:i          withValue: [decoder decodeBoolForKey:  [@"eventCountMode"         stringByAppendingFormat:@"%d",i]]];
        [self setDroppedEventCountMode:i   withValue: [decoder decodeBoolForKey:  [@"droppedEventCountMode"  stringByAppendingFormat:@"%d",i]]];
        [self setDecimationFactor:i        withValue: [decoder decodeIntegerForKey:   [@"decimationFactor"       stringByAppendingFormat:@"%d",i]]];
        [self setTriggerPolarity:i         withValue: [decoder decodeIntegerForKey: [@"triggerPolarity"        stringByAppendingFormat:@"%d",i]]];
        [self setPileupMode:i              withValue: [decoder decodeBoolForKey:  [@"pileupMode"             stringByAppendingFormat:@"%d",i]]];
        [self setEnabled:i                 withValue: [decoder decodeBoolForKey:  [@"enabled"                stringByAppendingFormat:@"%d",i]]];
        [self setDWindow:i                 withValue: [decoder decodeIntegerForKey:   [@"dWindow"                stringByAppendingFormat:@"%d",i]]];
        [self setKWindow:i                 withValue: [decoder decodeIntegerForKey:   [@"kWindow"                stringByAppendingFormat:@"%d",i]]];
        [self setMWindow:i                 withValue: [decoder decodeIntegerForKey:   [@"mWindow"                stringByAppendingFormat:@"%d",i]]];
        [self setD3Window:i                withValue: [decoder decodeIntegerForKey:   [@"d3Window"               stringByAppendingFormat:@"%d",i]]];
        [self setDiscWidth:i               withValue: [decoder decodeIntegerForKey:   [@"discWidth"              stringByAppendingFormat:@"%d",i]]];
        [self setBaselineStart:i           withValue: [decoder decodeIntegerForKey:   [@"baselineStart"          stringByAppendingFormat:@"%d",i]]];
        [self setP1Window:i                withValue: [decoder decodeIntegerForKey:   [@"p1Window"               stringByAppendingFormat:@"%d",i]]];
        [self setLedThreshold:i            withValue: [decoder decodeIntegerForKey:   [@"ledThreshold"           stringByAppendingFormat:@"%d",i]]];
        [self setOverflowFlagChan:i        withValue: [decoder decodeBoolForKey:  [@"overflowFlagChan"       stringByAppendingFormat:@"%d",i]]];
    }
    
    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumGretina4AChannels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
    
    [self registerNotificationObservers];
    
    if(!rateRunningAverages){
        [self setRateRunningAverages:[[[ORRunningAverageGroup alloc] initGroup:kNumGretina4AChannels groupTag:0 withLength:10] autorelease]];
    }
    [rateRunningAverages setTriggerType:kRASpikeOnRatio];
    [rateRunningAverages setTriggerValue:5]; //this is ratio...  rate threshold could be changed

    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeBool:forceFullCardInit           forKey:@"forceFullCardInit"];
    [encoder encodeBool:doHwCheck                   forKey:@"doHwCheck"];
    [encoder encodeObject:spiConnector				forKey:@"spiConnector"];
    [encoder encodeObject:linkConnector				forKey:@"linkConnector"];
    [encoder encodeInteger:registerIndex				forKey:@"registerIndex"];
    [encoder encodeInteger:selectedChannel              forKey:@"selectedChannel"];
    [encoder encodeInt:registerWriteValue			forKey:@"registerWriteValue"];
    [encoder encodeInt:spiWriteValue			    forKey:@"spiWriteValue"];
    [encoder encodeObject:fpgaFilePath				forKey:@"fpgaFilePath"];
    [encoder encodeInt:extDiscriminatorSrc        forKey:@"extDiscriminatorSrc"];
    [encoder encodeInt:extDiscriminatorMode       forKey:@"extDiscriminatorMode"];
    [encoder encodeInt:userPackageData            forKey:@"userPackageData"];
    [encoder encodeInteger:windowCompMin              forKey:@"windowCompMin"];
    [encoder encodeInteger:windowCompMax              forKey:@"windowCompMax"];
    [encoder encodeInteger:(int32_t)p2Window                     forKey:@"p2Window"];
    [encoder encodeInteger:dacChannelSelect             forKey:@"dacChannelSelect"];
    [encoder encodeInteger:dacAttenuation               forKey:@"dacAttenuation"];
    [encoder encodeInt:channelPulsedControl       forKey:@"channelPulsedControl"];
    [encoder encodeInt:diagMuxControl             forKey:@"diagMuxControl"];
    [encoder encodeInteger:holdOffTime                  forKey:@"holdOffTime"];
    [encoder encodeInteger:downSampleHoldOffTime        forKey:@"downSampleHoldOffTime"];
    [encoder encodeBool:downSamplePauseEnable       forKey:@"downSamplePauseEnable"];
    [encoder encodeInteger:peakSensitivity              forKey:@"peakSensitivity"];
    [encoder encodeBool:autoMode                    forKey:@"autoMode"];
    [encoder encodeInteger:trackingSpeed                forKey:@"trackingSpeed"];
    [encoder encodeInteger:baselineDelay                forKey:@"baselineDelay"];
    [encoder encodeInteger:diagInput                    forKey:@"diagInput"];
    [encoder encodeInteger:diagChannelEventSel        forKey:@"diagChannelEventSel"];
    [encoder encodeInt:rj45SpareIoMuxSel          forKey:@"rj45SpareIoMuxSel"];
    [encoder encodeBool:rj45SpareIoDir              forKey:@"rj45SpareIoDir"];
    [encoder encodeInteger:vetoGateWidth                forKey:@"vetoGateWidth"];
    [encoder encodeInteger:triggerConfig                forKey:@"triggerConfig"];
    [encoder encodeInt:tSErrCntCtrl               forKey:@"tSErrCntCtrl"];
    [encoder encodeBool:clkSelect0                  forKey:@"clkSelect0"];
    [encoder encodeBool:clkSelect1                  forKey:@"clkSelect1"];
    [encoder encodeInt:auxIoRead                  forKey:@"auxIoRead"];
    [encoder encodeInt:auxIoWrite                 forKey:@"auxIoWrite"];
    [encoder encodeInt:auxIoConfig                forKey:@"auxIoConfig"];
    [encoder encodeInteger:rawDataLength                forKey:@"rawDataLength"];
    [encoder encodeInteger:rawDataWindow                forKey:@"rawDataWindow"];
    [encoder encodeInteger:clockSource                  forKey:@"clockSource"];

    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [encoder encodeInteger:forceFullInit[i]           forKey:[@"forceFullInit"         stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:enabled[i]                forKey:[@"enabled"               stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:pileupMode[i]             forKey:[@"pileupMode"            stringByAppendingFormat:@"%d",i]];
        [encoder encodeInteger:triggerPolarity[i]         forKey:[@"triggerPolarity"       stringByAppendingFormat:@"%d",i]];
        [encoder encodeInteger:decimationFactor[i]        forKey:[@"decimationFactor"      stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:droppedEventCountMode[i]  forKey:[@"droppedEventCountMode" stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:eventCountMode[i]         forKey:[@"eventCountMode"        stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:aHitCountMode[i]          forKey:[@"aHitCountMode"         stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:discCountMode[i]          forKey:[@"discCountMode"         stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:pileupExtensionMode[i]    forKey:[@"pileExtensionMode"     stringByAppendingFormat:@"%d",i]];
        [encoder encodeBool:pileupWaveformOnlyMode[i] forKey:[@"pileupWaveformOnlyMode"stringByAppendingFormat:@"%d",i]];
        [encoder encodeInteger:ledThreshold[i]            forKey:[@"ledThreshold"          stringByAppendingFormat:@"%d",i]];
        [encoder encodeInteger:dWindow[i]                 forKey:[@"dWindow"               stringByAppendingFormat:@"%d",i]];
        [encoder encodeInteger:kWindow[i]                 forKey:[@"kWindow"               stringByAppendingFormat:@"%d",i]];
        [encoder encodeInteger:mWindow[i]                 forKey:[@"mWindow"               stringByAppendingFormat:@"%d",i]];
        [encoder encodeInteger:discWidth[i]               forKey:[@"discWidth"             stringByAppendingFormat:@"%d",i]];
        [encoder encodeInteger:d3Window[i]                forKey:[@"d3Window"              stringByAppendingFormat:@"%d",i]];
        [encoder encodeInteger:baselineStart[i]           forKey:[@"baselineStart"         stringByAppendingFormat:@"%d",i]];
        [encoder encodeInteger:p1Window[i]                forKey:[@"p1Window"               stringByAppendingFormat:@"%d",i]];
    }
    
    [encoder encodeObject:waveFormRateGroup			forKey:@"waveFormRateGroup"];

}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithBool:forceFullCardInit]             forKey:@"forceFullCardInit"];
    
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:extDiscriminatorSrc]  forKey:@"extDiscriminatorSrc"];
    [objDictionary setObject:[NSNumber numberWithInteger:userPackageData]               forKey:@"userPackageData"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:windowCompMin]        forKey:@"windowCompMin"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:windowCompMax]        forKey:@"windowCompMax"];
    [objDictionary setObject:[NSNumber numberWithInteger:p2Window]                      forKey:@"p2Window"];
    [objDictionary setObject:[NSNumber numberWithInt:dacChannelSelect]              forKey:@"dacChannelSelect"];
    [objDictionary setObject:[NSNumber numberWithInt:dacAttenuation]                forKey:@"dacAttenuation"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:channelPulsedControl] forKey:@"channelPulsedControl"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:diagMuxControl]       forKey:@"diagMuxControl"];
    [objDictionary setObject:[NSNumber numberWithInt:downSampleHoldOffTime]         forKey:@"downSampleHoldOffTime"];
    [objDictionary setObject:[NSNumber numberWithInt:holdOffTime]                   forKey:@"holdOffTime"];
    [objDictionary setObject:[NSNumber numberWithInt:peakSensitivity]               forKey:@"peakSensitivity"];
    [objDictionary setObject:[NSNumber numberWithBool:autoMode]                     forKey:@"autoMode"];
    [objDictionary setObject:[NSNumber numberWithInt:trackingSpeed]                 forKey:@"trackingSpeed"];
    [objDictionary setObject:[NSNumber numberWithInt:baselineDelay]                 forKey:@"baselineDelay"];
    [objDictionary setObject:[NSNumber numberWithInt:diagInput]                     forKey:@"diagInput"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:diagChannelEventSel]  forKey:@"diagChannelEventSel"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:rj45SpareIoMuxSel]    forKey:@"rj45SpareIoMuxSel"];
    [objDictionary setObject:[NSNumber numberWithBool:rj45SpareIoDir]               forKey:@"rj45SpareIoDir"];
    [objDictionary setObject:[NSNumber numberWithInt:vetoGateWidth]                 forKey:@"vetoGateWidth"];
    [objDictionary setObject:[NSNumber numberWithInt:triggerConfig]                 forKey:@"triggerConfig"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:tSErrCntCtrl]         forKey:@"tSErrCntCtrl"];
    [objDictionary setObject:[NSNumber numberWithBool:clkSelect0]                   forKey:@"clkSelect0"];
    [objDictionary setObject:[NSNumber numberWithBool:clkSelect1]                   forKey:@"clkSelect1"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:auxIoRead]            forKey:@"auxIoRead"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:auxIoWrite]           forKey:@"auxIoWrite"];
    [objDictionary setObject:[NSNumber numberWithUnsignedLong:auxIoConfig]          forKey:@"auxIoConfig"];
    [objDictionary setObject:[NSNumber numberWithInt:rawDataLength]                 forKey:@"rawDataLength"];
    [objDictionary setObject:[NSNumber numberWithInt:rawDataWindow]                 forKey:@"rawDataWindow"];
    [objDictionary setObject:[NSNumber numberWithInt:clockSource]                   forKey:@"Clock Source"];
    
    [self addCurrentState:objDictionary boolArray:(BOOL*)forceFullInit              forKey:@"forceFullInit"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)enabled                    forKey:@"enabled"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)pileupMode                 forKey:@"pileupMode"];
    [self addCurrentState:objDictionary shortArray:(short*)triggerPolarity          forKey:@"pileupMode"];
    [self addCurrentState:objDictionary shortArray:(short*)decimationFactor         forKey:@"decimationFactor"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)droppedEventCountMode      forKey:@"droppedEventCountMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)eventCountMode             forKey:@"eventCountMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)aHitCountMode              forKey:@"aHitCountMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)discCountMode              forKey:@"discCountMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)pileupExtensionMode        forKey:@"pileExtensionMode"];
    [self addCurrentState:objDictionary boolArray:(BOOL*)pileupWaveformOnlyMode     forKey:@"pileupWaveformOnlyMode"];
    [self addCurrentState:objDictionary shortArray:(short*)ledThreshold             forKey:@"ledThreshold"];
    [self addCurrentState:objDictionary shortArray:(short*)dWindow                  forKey:@"dWindow"];
    [self addCurrentState:objDictionary shortArray:(short*)kWindow                  forKey:@"kWindow"];
    [self addCurrentState:objDictionary shortArray:(short*)mWindow                  forKey:@"mWindow"];
    [self addCurrentState:objDictionary shortArray:(short*)discWidth                forKey:@"discWidth"];
    [self addCurrentState:objDictionary shortArray:(short*)d3Window                 forKey:@"d3Window"];
    [self addCurrentState:objDictionary shortArray:(short*)baselineStart            forKey:@"baselineStart"];
    [self addCurrentState:objDictionary shortArray:(short*)p1Window                 forKey:@"p1Window"];
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary shortArray:(short*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [ar addObject:[NSNumber numberWithShort:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [ar addObject:[NSNumber numberWithBool:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

#pragma mark - AutoTesting
- (NSArray*) autoTests
{
    NSMutableArray* myTests = [NSMutableArray array];
    [myTests addObject:[ORVmeReadOnlyTest test:kBoardId wordSize:4 name:@"Board ID"]];
    return myTests;
}

#pragma mark - SPI Interface
- (uint32_t) writeAuxIOSPI:(uint32_t)spiData
{
    /*
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
     */
    return 0;
}

#pragma mark - AdcProviding Protocol
- (BOOL)          onlineMaskBit:(int)bit                     { return [self enabled:bit];        }
- (BOOL)          partOfEvent:(unsigned short)aChannel       { return NO;                        }
- (uint32_t) waveFormCount:(short)aChannel              { return waveFormCount[aChannel];   }
- (uint32_t) eventCount:(int)aChannel                   { return waveFormCount[aChannel];   }
- (uint32_t) thresholdForDisplay:(unsigned short) aChan { return [self ledThreshold:aChan]; }
- (unsigned short)gainForDisplay:(unsigned short) aChan      { return 0; }

- (void) clearEventCounts
{
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
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

@implementation ORGretina4AModel (private)

- (void) updateDownLoadProgress
{
    //call only from main thread
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGretina4AFpgaDownProgressChanged object:self];
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
                [NSException raise:@"Gretina4A Exception" format:@"Verification of flash failed."];
            }
            else {
                //reload the fpga from flash
                [self writeToAddress:0x900 aValue:kGretina4AResetMainFPGACmd];
                [self writeToAddress:0x900 aValue:kGretina4AReloadMainFPGACmd];
                [self setProgressStateOnMainThread:  @"Finishing$Flash Memory-->FPGA"];
                uint32_t statusRegValue = [self readFromAddress:0x904];
                while(!(statusRegValue & kGretina4AMainFPGAIsLoaded)) {
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
    /* We only erase the blocks currently used in the Gretina4A specification. */
    [self writeToAddress:0x910 aValue:kGretina4AFlashEnableWrite]; //Enable programming
    [self setFpgaDownProgress:0.];
    uint32_t count = 0;
    uint32_t end = (kGretina4AFlashBlocks / 4) * kGretina4AFlashBlockSize;
    uint32_t addr;
    [self setProgressStateOnMainThread:  @"Block Erase"];
    for (addr = 0; addr < end; addr += kGretina4AFlashBlockSize) {
        
        if(stopDownLoadingMainFPGA)return;
        @try {
            [self setFirmwareStatusString:       [NSString stringWithFormat:@"%u of %d Blocks Erased",count,kGretina4AFlashBufferBytes]];
            [self setFpgaDownProgress: 100. * (count+1)/(float)kGretina4AUsedFlashBlocks];
            
            [self writeToAddress:0x980 aValue:addr];
            [self writeToAddress:0x98C aValue:kGretina4AFlashBlockEraseCmd];
            [self writeToAddress:0x98C aValue:kGretina4AFlashConfirmCmd];
            uint32_t stat = [self readFromAddress:0x904];
            while (stat & kFlashBusy) {
                if(stopDownLoadingMainFPGA)break;
                stat = [self readFromAddress:0x904];
            }
            count++;
        }
        @catch(NSException* localException) {
            NSLog(@"Gretina4A exception erasing flash.\n");
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
    [self writeToAddress:0x98C aValue:kGretina4AFlashReadArrayCmd];
    
    uint32_t address = 0x0;
    while (address < totalSize ) {
        uint32_t numberBytesToWrite;
        if(totalSize-address >= kGretina4AFlashBufferBytes){
            numberBytesToWrite = kGretina4AFlashBufferBytes; //whole block
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
    [self writeToAddress:0x98C aValue:kGretina4AFlashReadArrayCmd];
    [self writeToAddress:0x910 aValue:0x00];
    
    [self setProgressStateOnMainThread:@"Programming"];
}

- (void) programFlashBufferBlock:(NSData*)theData address:(uint32_t)anAddress numberBytes:(uint32_t)aNumber
{
    //issue the set-up command at the starting address
    [self writeToAddress:0x980 aValue:anAddress];
    [self writeToAddress:0x98C aValue:kGretina4AFlashWriteCmd];
    unsigned char* theDataBytes = (unsigned char*)[theData bytes];
    uint32_t statusRegValue;
    while(1) {
        if(stopDownLoadingMainFPGA)return;
        
        // Checking status to make sure that flash is ready
        uint32_t statusRegValue = [self readFromAddress:0x904];
        
        if ( (statusRegValue & kFlashBusy)  == kFlashBusy ) {
            //not ready, so re-issue the set-up command
            [self writeToAddress:0x980 aValue:anAddress];
            [self writeToAddress:0x98C aValue:kGretina4AFlashWriteCmd];
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
    [self writeToAddress:0x98C aValue:kGretina4AFlashConfirmCmd];
    
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
    [self writeToAddress:0x98C aValue:kGretina4AFlashReadArrayCmd];
    
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
    
//    [self writeToAddress:0x900 aValue:kGretina4AResetMainFPGACmd];
//    [self writeToAddress:0x900 aValue:kGretina4AReloadMainFPGACmd];
    [self writeToAddress:0x900 aValue:0x10];
    [self writeToAddress:0x900 aValue:0x20];
    
    uint32_t statusRegValue=[self readFromAddress:0x904];
    
    while(!(statusRegValue & kGretina4AMainFPGAIsLoaded)) {
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
        aPacket.cmdHeader.cmdID                 = kMJDFlashGretinaAFPGA;
        aPacket.cmdHeader.numberBytesinPayload	= sizeof(MJDFlashGretinaFPGAStruct);
        
        MJDFlashGretinaFPGAStruct* p = (MJDFlashGretinaFPGAStruct*) aPacket.payload;
        p->baseAddress      = (uint32_t)[self baseAddress];
        @try {
            NSLog(@"Gretina4A (%d) launching firmware load job in SBC\n",[self uniqueIdNumber]);
            
            [[[self adapter] sbcLink] send:&aPacket receive:&aPacket];
            
            [[[self adapter] sbcLink] monitorJobFor:self statusSelector:@selector(flashFpgaStatus:)];
            
        }
        @catch(NSException* e){
            
        }
    }
}
@end
