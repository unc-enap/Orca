//
//SNOCaenModel.m
//Orca
//
//Created by Mark Howe on Mon Apr 14 2008.
//Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//
//-------------------------------------------------------------
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

#import "SNOCaenModel.h"
#import "ORVmeCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORRateGroup.h"
#import "VME_HW_Definitions.h"
#import "ORRunModel.h"
#import "ORPQModel.h"
#import "SNOPModel.h"

// Address information for this unit.
#define k792DefaultBaseAddress 		0xa00000
#define k792DefaultAddressModifier 	0x09
#define kNumberBLTEventsToReadout   12 //most BLTEvent numbers don't make sense, make sure you know what you change

NSString* SNOCaenModelEventSizeChanged = @"SNOCaenModelEventSizeChanged";
static NSString* Caen1720RunModeString[4] = {
@"Register-Controlled",
@"S-In Controlled",
@"S-In Gate",
@"Multi-Board Sync",
};
// Define all the registers available to this unit.
static Caen1720RegisterNamesStruct reg[kNumRegisters] = {
{@"Output Buffer",      true,	true, 	true,	0x0000,		kReadOnly}, //not implemented in HW yet
{@"ZS_Thres",			false,	true, 	true,	0x1024,		kReadWrite}, //not implemented in HW yet
{@"ZS_NsAmp",			false,	true, 	true,	0x1028,		kReadWrite},
{@"Thresholds",			false,	true, 	true,	0x1080,		kReadWrite},
{@"Num O/U Threshold",	false,	true, 	true,	0x1084,		kReadWrite},
{@"Status",				false,	true, 	true,	0x1088,		kReadOnly},
{@"Firmware Version",	false,	false, 	false,	0x108C,		kReadOnly},
{@"Buffer Occupancy",	true,	true, 	true,	0x1094,		kReadOnly},
{@"Dacs",				false,	true, 	true,	0x1098,		kReadWrite},
{@"Adc Config",			false,	true, 	true,	0x109C,		kReadWrite},
{@"Chan Config",		false,	true, 	true,	0x8000,		kReadWrite},
{@"Chan Config Bit Set",false,	true, 	true,	0x8004,		kWriteOnly},
{@"Chan Config Bit Clr",false,	true, 	true,	0x8008,		kWriteOnly},
{@"Buffer Organization",false,	true, 	true,	0x800C,		kReadWrite},
{@"Buffer Free",		false,	false, 	false,	0x8010,		kReadWrite},
{@"Custom Size",		false,	true, 	true,	0x8020,		kReadWrite},
{@"Acq Control",		false,	true, 	true,	0x8100,		kReadWrite},
{@"Acq Status",			false,	false, 	false,	0x8104,		kReadOnly},
{@"SW Trigger",			false,	false, 	false,	0x8108,		kWriteOnly},
{@"Trig Src Enbl Mask",	false,	true, 	true,	0x810C,		kReadWrite},
{@"FP Trig Out Enbl Mask",false,true, 	true,	0x8110,		kReadWrite},
{@"Post Trig Setting",	false,	true, 	true,	0x8114,		kReadWrite},
{@"FP I/O Data",		false,	true, 	true,	0x8118,		kReadWrite},
{@"FP I/O Control",		false,	true, 	true,	0x811C,		kReadWrite},
{@"Chan Enable Mask",	false,	true, 	true,	0x8120,		kReadWrite},
{@"ROC FPGA Version",	false,	false, 	false,	0x8124,		kReadOnly},
{@"Event Stored",		true,	true, 	true,	0x812C,		kReadOnly},
{@"Set Monitor DAC",	false,	true, 	true,	0x8138,		kReadWrite},
{@"Board Info",			false,	false, 	false,	0x8140,		kReadOnly},
{@"Monitor Mode",		false,	true, 	true,	0x8144,		kReadWrite},
{@"Event Size",			true,	true, 	true,	0x814C,		kReadOnly},
{@"VME Control",		false,	false, 	true,	0xEF00,		kReadWrite},
{@"VME Status",			false,	false, 	false,	0xEF04,		kReadOnly},
{@"Board ID",			false,	true, 	true,	0xEF08,		kReadWrite},
{@"MultCast Base Add",	false,	false, 	true,	0xEF0C,		kReadWrite},
{@"Relocation Add",		false,	false, 	true,	0xEF10,		kReadWrite},
{@"Interrupt Status ID",false,	false, 	true,	0xEF14,		kReadWrite},
{@"Interrupt Event Num",false,	true, 	true,	0xEF18,		kReadWrite},
{@"BLT Event Num",		false,	true, 	true,	0xEF1C,		kReadWrite},
{@"Scratch",			false,	true, 	true,	0xEF20,		kReadWrite},
{@"SW Reset",			false,	false, 	false,	0xEF24,		kWriteOnly},
{@"SW Clear",			false,	false, 	false,	0xEF28,		kWriteOnly}
//	{@"Flash Enable",		false,	false, 	true,	0xEF2C,		kReadWrite},
//	{@"Flash Data",			false,	false, 	true,	0xEF30,		kReadWrite},
//	{@"Config Reload",		false,	false, 	false,	0xEF34,		kWriteOnly},
//	{@"Config ROM",			false,	false, 	false,	0xF000,		kReadOnly}
};

#define kEventReadyMask 0x8

NSString* SNOCaenModelEnabledMaskChanged                 = @"SNOCaenModelEnabledMaskChanged";
NSString* SNOCaenModelPostTriggerSettingChanged          = @"SNOCaenModelPostTriggerSettingChanged";
NSString* SNOCaenModelTriggerSourceMaskChanged           = @"SNOCaenModelTriggerSourceMaskChanged";
NSString* SNOCaenModelTriggerOutMaskChanged		    = @"SNOCaenModelTriggerOutMaskChanged";
NSString* SNOCaenModelFrontPanelControlMaskChanged	    = @"SNOCaenModelFrontPanelControlMaskChanged";
NSString* SNOCaenModelCoincidenceLevelChanged            = @"SNOCaenModelCoincidenceLevelChanged";
NSString* SNOCaenModelAcquisitionModeChanged             = @"SNOCaenModelAcquisitionModeChanged";
NSString* SNOCaenModelCountAllTriggersChanged            = @"SNOCaenModelCountAllTriggersChanged";
NSString* SNOCaenModelCustomSizeChanged                  = @"SNOCaenModelCustomSizeChanged";
NSString* SNOCaenModelIsCustomSizeChanged                = @"SNOCaenModelIsCustomSizeChanged";
NSString* SNOCaenModelIsFixedSizeChanged                 = @"SNOCaenModelIsFixedSizeChanged";
NSString* SNOCaenModelChannelConfigMaskChanged           = @"SNOCaenModelChannelConfigMaskChanged";
NSString* SNOCaenModelNumberBLTEventsToReadoutChanged    = @"SNOCaenModelNumberBLTEventsToReadoutChanged";
NSString* SNOCaenChnlDacChanged                          = @"SNOCaenChnlDacChanged";
NSString* SNOCaenOverUnderThresholdChanged               = @"SNOCaenOverUnderThresholdChanged";
NSString* SNOCaenChnl                                    = @"SNOCaenChnl";
NSString* SNOCaenChnlThresholdChanged                    = @"SNOCaenChnlThresholdChanged";
NSString* SNOCaenSelectedChannelChanged                  = @"SNOCaenSelectedChannelChanged";
NSString* SNOCaenSelectedRegIndexChanged                 = @"SNOCaenSelectedRegIndexChanged";
NSString* SNOCaenWriteValueChanged                       = @"SNOCaenWriteValueChanged";
NSString* SNOCaenBasicLock                               = @"SNOCaenBasicLock";
NSString* SNOCaenSettingsLock                            = @"SNOCaenSettingsLock";
NSString* SNOCaenRateGroupChanged                        = @"SNOCaenRateGroupChanged";
NSString* SNOCaenModelBufferCheckChanged                 = @"SNOCaenModelBufferCheckChanged";
NSString* SNOCaenModelContinuousModeChanged              = @"SNOCaenModelContinuousModeChanged";

@implementation SNOCaenModel

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];

    [self registerNotificationObservers];

    /* initialize our connection to the MTC server */
    mtc_server = [[RedisClient alloc] init];

    [self setBaseAddress:k792DefaultBaseAddress];
    [self setAddressModifier:k792DefaultAddressModifier];
	[self setEnabledMask:0xFF];
    [self setEventSize:0xa];
    [self setNumberBLTEventsToReadout:kNumberBLTEventsToReadout];
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

- (void) updateSettings
{
    NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOPModel")];

    SNOPModel* sno;
    if ([objs count] == 0) return;

    sno = [objs objectAtIndex:0];
    [self setMTCHost:[sno mtcHost]];
    [self setMTCPort:[sno mtcPort]];
}

- (void) awakeAfterDocumentLoaded
{
    [self updateSettings];
}

- (void) setMTCPort: (int) port
{
    [mtc_server setPort:port];
    [mtc_server disconnect];
}

- (void) setMTCHost: (NSString *) host
{
    [mtc_server setHost:host];
    [mtc_server disconnect];
}

- (void) dealloc 
{
    [mtc_server release];
    [waveFormRateGroup release];
	[bufferFullAlarm release];
    [super dealloc];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0xEF28);
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(detectorStateChanged:)
                         name : ORPQDetectorStateChanged
                       object : nil];
}

- (int) initAtRunStart
{
    /* Load model settings to hardware at the run start. Returns 0 on success,
     * -1 on failure. */

    @try {
        [self initBoard];
        [self writeNumberBLTEvents:0];
        [self writeEnableBerr:0];
        [self writeEnableExtendedReadoutBuffer:1];
        [self writeAcquisitionControl:YES];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"error loading CAEN hardware: %@\n",
                   [e reason]);
        return -1;
    }

    return 0;
}

- (void) detectorStateChanged:(NSNotification*)aNote
{
    ORPQDetectorDB *detDB = [aNote object];

    if (!detDB) return;

    PQ_CAEN *pqCAEN = (PQ_CAEN *)[detDB getCAEN];

    if (!pqCAEN) return; // nothing to do if CAEN doesn't exist in the current state

    @try{
        [[self undoManager] disableUndoRegistration];

        if (pqCAEN->valid[kCAEN_channelConfiguration]) {
            [self setChannelConfigMask:pqCAEN->channelConfiguration];
        }
        if (pqCAEN->valid[kCAEN_bufferOrganization]) {
            [self setEventSize:pqCAEN->bufferOrganization];
        }
        if (pqCAEN->valid[kCAEN_customSize]) {
            [self setCustomSize:pqCAEN->customSize];
            [self setIsCustomSize:(pqCAEN->customSize ? YES : NO)];
            // (setIsFixedSize is not used)
        }
        if (pqCAEN->valid[kCAEN_acquisitionControl]) {
            [self setAcquisitionMode:pqCAEN->acquisitionControl & 0x03];
            [self setCountAllTriggers:(pqCAEN->acquisitionControl >> 3) & 0x01];
        }
        if (pqCAEN->valid[kCAEN_triggerMask]) {
            [self setTriggerSourceMask:(pqCAEN->triggerMask & 0xffffffff)]; // for bits 0-7 and 30-31
            [self setCoincidenceLevel:((pqCAEN->triggerMask >> 24) & 0x7)]; // for bits 24-26
        }
        if (pqCAEN->valid[kCAEN_triggerOutMask]) {
            [self setTriggerOutMask:pqCAEN->triggerOutMask];
        }
        if (pqCAEN->valid[kCAEN_postTrigger]) {
            [self setPostTriggerSetting:pqCAEN->postTrigger];
        }
        if (pqCAEN->valid[kCAEN_frontPanelIoControl]) {
            [self setFrontPanelControlMask:pqCAEN->frontPanelIoControl];
        }
        if (pqCAEN->valid[kCAEN_channelMask]) {
            [self setEnabledMask:pqCAEN->channelMask];
        }
        for (int i=0; i<kNumCaenChannelDacs; ++i) {
            if (pqCAEN->valid[kCAEN_channelDacs] & (1 << i)) {
                [self setDac:i withValue:pqCAEN->channelDacs[i]];
                // (we don't currently use the thresholds because we use an external trigger,
                //  so don't yet call setThreshold and setOverUnderThreshold)
            }
        }
        // setNumberBLTEventsToReadout (not used)
    }
    @finally {
        [[self undoManager] enableUndoRegistration];
    }
}

#pragma mark ***Accessors

- (int) eventSize
{
    return eventSize;
}

- (void) setEventSize:(int)aEventSize
{
	//if(aEventSize == 0)aEventSize = 0xa; //default
	
    [[[self undoManager] prepareWithInvocationTarget:self] setEventSize:eventSize];
    
    eventSize = aEventSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelEventSizeChanged object:self];
}

- (int)	bufferState
{
	return bufferState;
}

- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<8){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
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
	 postNotificationName:SNOCaenRateGroupChanged
	 object:self];    
}

- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}

- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self]
	 setSelectedRegIndex:[self selectedRegIndex]];
    
    // Set the new value in the model.
    selectedRegIndex = anIndex;
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:SNOCaenSelectedRegIndexChanged
	 object:self];
}

- (unsigned short) selectedChannel
{
    return selectedChannel;
}

- (void) setSelectedChannel:(unsigned short) anIndex
{
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self]
	 setSelectedChannel:[self selectedChannel]];
    
    // Set the new value in the model.
    selectedChannel = anIndex;
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:SNOCaenSelectedChannelChanged
	 object:self];
}

- (unsigned long) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(unsigned long) aValue
{
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    
    // Set the new value in the model.
    writeValue = aValue;
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:SNOCaenWriteValueChanged
	 object:self];
}

- (unsigned short) enabledMask
{
    return enabledMask;
}

- (void) setEnabledMask:(unsigned short)aEnabledMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
    
    enabledMask = aEnabledMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelEnabledMaskChanged object:self];
}

- (unsigned long) postTriggerSetting
{
    return postTriggerSetting;
}

- (void) setPostTriggerSetting:(unsigned long)aPostTriggerSetting
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerSetting:postTriggerSetting];
    
    postTriggerSetting = aPostTriggerSetting;
	
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelPostTriggerSettingChanged object:self];
}

- (unsigned long) triggerSourceMask
{
    return triggerSourceMask;
}

- (void) setTriggerSourceMask:(unsigned long)aTriggerSourceMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerSourceMask:triggerSourceMask];
    
    triggerSourceMask = aTriggerSourceMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelTriggerSourceMaskChanged object:self];
}

- (unsigned long) triggerOutMask
{
	return triggerOutMask;
}

- (void) setTriggerOutMask:(unsigned long)aTriggerOutMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setTriggerOutMask:triggerOutMask];
	
	//do not step into the reserved area
	triggerOutMask = aTriggerOutMask & 0xc00000ff;
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelTriggerOutMaskChanged object:self];
}

- (unsigned long) frontPanelControlMask
{
	return frontPanelControlMask;
}

- (void) setFrontPanelControlMask:(unsigned long)aFrontPanelControlMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setFrontPanelControlMask:aFrontPanelControlMask];
	
	frontPanelControlMask = aFrontPanelControlMask;
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelFrontPanelControlMaskChanged object:self];
}

- (unsigned short) coincidenceLevel
{
    return coincidenceLevel;
}

- (void) setCoincidenceLevel:(unsigned short)aCoincidenceLevel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCoincidenceLevel:coincidenceLevel];
    
    coincidenceLevel = aCoincidenceLevel;
	
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelCoincidenceLevelChanged object:self];
}

- (unsigned short) acquisitionMode
{
    return acquisitionMode;
}

- (void) setAcquisitionMode:(unsigned short)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAcquisitionMode:acquisitionMode];
    
    acquisitionMode = aMode;
	
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelAcquisitionModeChanged object:self];
}

- (BOOL) countAllTriggers
{
    return countAllTriggers;
}

- (void) setCountAllTriggers:(BOOL)aCountAllTriggers
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCountAllTriggers:countAllTriggers];
    
    countAllTriggers = aCountAllTriggers;
	
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelCountAllTriggersChanged object:self];
}

- (unsigned long) customSize
{
    return customSize;
}

- (void) setCustomSize:(unsigned long)aCustomSize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCustomSize:customSize];
    
    customSize = aCustomSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelCustomSizeChanged object:self];
}

- (BOOL) isCustomSize
{
	return isCustomSize;
}

- (void) setIsCustomSize:(BOOL)aIsCustomSize
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIsCustomSize:isCustomSize];
	
	isCustomSize = aIsCustomSize;
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelIsCustomSizeChanged object:self];
}

- (BOOL) isFixedSize
{
	return isFixedSize;
}

- (void) setIsFixedSize:(BOOL)aIsFixedSize
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIsFixedSize:isFixedSize];
	
	isFixedSize = aIsFixedSize;
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelIsFixedSizeChanged object:self];
}

- (unsigned short) channelConfigMask
{
    return channelConfigMask;
}

- (void) setChannelConfigMask:(unsigned short)aChannelConfigMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannelConfigMask:channelConfigMask];
    
    channelConfigMask = aChannelConfigMask;
	
	//can't get the d form to work so just make sure that bit is cleared.
	channelConfigMask &= ~(1L<<11);

	//we do the sequential memory access only
	channelConfigMask |= (1L<<4);

    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelChannelConfigMaskChanged object:self];
}

- (unsigned long) numberBLTEventsToReadout
{
    return numberBLTEventsToReadout; 
}

- (void) setNumberBLTEventsToReadout:(unsigned long) numBLTEvents
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNumberBLTEventsToReadout:numberBLTEventsToReadout];
    
    numberBLTEventsToReadout = numBLTEvents;
    
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelNumberBLTEventsToReadoutChanged object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Caen1720Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"SNOCaenController"];
}

- (BOOL) continuousMode
{
    return continuousMode;
}

- (void) setContinuousMode:(BOOL)aContinuousMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setContinuousMode:continuousMode];
    
    continuousMode = aContinuousMode;
    
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenModelContinuousModeChanged object:self];
}

#pragma mark ***Register - General routines
- (short) getNumberRegisters
{
    return kNumRegisters;
}

#pragma mark ***Register - Register specific routines

- (NSString*) getRegisterName:(short) anIndex
{
    return reg[anIndex].regName;
}

- (unsigned long) getAddressOffset:(short) anIndex
{
    return reg[anIndex].addressOffset;
}

- (short) getAccessType:(short) anIndex
{
    return reg[anIndex].accessType;
}

- (BOOL) dataReset:(short) anIndex
{
    return reg[anIndex].dataReset;
}

- (BOOL) swReset:(short) anIndex
{
    return reg[anIndex].softwareReset;
}

- (BOOL) hwReset:(short) anIndex
{
    return reg[anIndex].hwReset;
}


- (unsigned short) dac:(unsigned short) aChnl
{
    return dac[aChnl];
}

- (void) setDac:(unsigned short) aChnl withValue:(unsigned short) aValue
{
	
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setDac:aChnl withValue:dac[aChnl]];
    
    // Set the new value in the model.
    dac[aChnl] = aValue;
    
    // Create a dictionary object that stores a pointer to this object and the channel that was changed.
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:SNOCaenChnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenChnlDacChanged object:self userInfo:userInfo];

}

- (unsigned short) overUnderThreshold:(unsigned short) aChnl
{
    return overUnderThreshold[aChnl];
}

- (void) setOverUnderThreshold:(unsigned short) aChnl withValue:(unsigned short) aValue
{
	
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setOverUnderThreshold:aChnl withValue:overUnderThreshold[aChnl]];
    
    // Set the new value in the model.
    overUnderThreshold[aChnl] = aValue;
    
    // Create a dictionary object that stores a pointer to this object and the channel that was changed.
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:SNOCaenChnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenOverUnderThresholdChanged object:self userInfo:userInfo];

}

- (void) readChan:(unsigned short)chan reg:(unsigned short) pReg returnValue:(unsigned long*) pValue
{
    // Make sure that register is valid
    if (pReg >= [self getNumberRegisters]) {
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    // Make sure that one can read from register
    if([self getAccessType:pReg] != kReadOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (read not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    // Perform the read operation.
    *pValue = [mtc_server intCommand:"caen_read %d", [self getAddressOffset:pReg] + chan*0x100];
}

- (void) writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(unsigned long) pValue
{
    // Check that register is a valid register.
    if (pReg >= [self getNumberRegisters]){
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    // Make sure that register can be written to.
    if([self getAccessType:pReg] != kWriteOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (write not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    // Do actual write
    @try {
        [mtc_server okCommand:"caen_write %d %d", [self getAddressOffset:pReg] + chan*0x100, pValue];
	}
	@catch(NSException* localException) {
	}
}

- (unsigned short) threshold:(unsigned short) aChnl
{
    return thresholds[aChnl];
}

- (void) setThreshold:(unsigned short) aChnl withValue:(unsigned long) aValue
{
    
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChnl withValue:[self threshold:aChnl]];
    
    // Set the new value in the model.
    thresholds[aChnl] = aValue;
    
    // Create a dictionary object that stores a pointer to this object and the channel that was changed.
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:SNOCaenChnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:SNOCaenChnlThresholdChanged object:self userInfo:userInfo];

}

- (void) read
{
	short		start;
    short		end;
    short		i;   
    unsigned long 	theValue = 0;
    short theChannelIndex	 = [self selectedChannel];
    short theRegIndex		 = [self selectedRegIndex];
    
    @try {
        if (theRegIndex >= kZS_Thres && theRegIndex<=kAdcConfig){
            start = theChannelIndex;
            end = theChannelIndex;
            if(theChannelIndex >= [self numberOfChannels]) {
                start = 0;
                end = [self numberOfChannels] - 1;
            }
            
            // Loop through the thresholds and read them.
            for(i = start; i <= end; i++){
				[self readChan:i reg:theRegIndex returnValue:&theValue];
                NSLog(@"%@ %2d = 0x%04lx\n", reg[theRegIndex].regName,i, theValue);
            }
        }
		else {
			[self read:theRegIndex returnValue:&theValue];
			NSLog(@"CAEN reg [%@]:0x%04lx\n", [self getRegisterName:theRegIndex], theValue);
		}
        
	}
	@catch(NSException* localException) {
		NSLog(@"Can't Read [%@] on the %@.\n",
			  [self getRegisterName:theRegIndex], [self identifier]);
		[localException raise];
	}
}


//--------------------------------------------------------------------------------
/*!\method  write
 * \brief	Writes data out to a CAEN VME device register.
 * \note
 */
//--------------------------------------------------------------------------------
- (void) write
{
    short	start;
    short	end;
    short	i;
	
    long theValue			=  [self writeValue];
    short theChannelIndex	= [self selectedChannel];
    short theRegIndex 		= [self selectedRegIndex];
    
    @try {
        
        NSLog(@"Register is:%@\n", [self getRegisterName:theRegIndex]);
        NSLog(@"Value is   :0x%04x\n", theValue);
        
        if (theRegIndex >= kZS_Thres && theRegIndex<=kAdcConfig){
            start	= theChannelIndex;
            end 	= theChannelIndex;
            if(theChannelIndex >= [self numberOfChannels]){
				NSLog(@"Channel: ALL\n");
                start = 0;
                end = [self numberOfChannels] - 1;
            }
			else NSLog(@"Channel: %d\n", theChannelIndex);
			
            for (i = start; i <= end; i++){
                if(theRegIndex == kThresholds){
					[self setThreshold:i withValue:theValue];
				}
				[self writeChan:i reg:theRegIndex sendValue:theValue];
            }
        }
        
        // Handle all other registers
        else {
			[self write:theRegIndex sendValue: theValue];
        } 
	}
	@catch(NSException* localException) {
		NSLog(@"Can't write 0x%04lx to [%@] on the %@.\n",
			  theValue, [self getRegisterName:theRegIndex],[self identifier]);
		[localException raise];
	}
}


- (void) read:(unsigned short) pReg returnValue:(unsigned long*) pValue
{
    // Make sure that register is valid
    if (pReg >= [self getNumberRegisters]) {
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    // Make sure that one can read from register
    if([self getAccessType:pReg] != kReadOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (read not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    // Perform the read operation.
    *pValue = [mtc_server intCommand:"caen_read %d", [self getAddressOffset:pReg]];
}

- (void) write:(unsigned short) pReg sendValue:(unsigned long) pValue
{
    // Check that register is a valid register.
    if (pReg >= [self getNumberRegisters]){
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    // Make sure that register can be written to.
    if([self getAccessType:pReg] != kWriteOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (write not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    // Do actual write
    @try {
        [mtc_server okCommand:"caen_write %d %d", [self getAddressOffset:pReg], pValue];
	}
	@catch(NSException* localException) {
	}
}


- (void) writeThreshold:(unsigned short) pChan
{
    unsigned long 	threshold = [self threshold:pChan];
    
    [mtc_server okCommand:"caen_write %d %d", reg[kThresholds].addressOffset + (pChan*0x100), threshold];
}

- (void) writeOverUnderThresholds
{
	int i;
	for(i=0;i<8;i++){
		unsigned long aValue = overUnderThreshold[i];
        [mtc_server okCommand:"caen_write %d %d", reg[kNumOUThreshold].addressOffset + (i*0x100), aValue];
	}
}

- (void) readOverUnderThresholds
{
	int i;
	for(i=0;i<8;i++){
		unsigned long value = [mtc_server intCommand:"caen_read %d", reg[kNumOUThreshold].addressOffset + (i*0x100)];
        [self setOverUnderThreshold:i withValue:value];
	}
}

- (void) writeDacs
{
    short	i;
    for (i = 0; i < [self numberOfChannels]; i++){
        [self writeDac:i];
    }
}

- (void) writeDac:(unsigned short) pChan
{
    unsigned long 	aValue = [self dac:pChan];
    
    [mtc_server okCommand:"caen_write %d %d", reg[kDacs].addressOffset + (pChan*0x100), aValue];
}

- (void) generateSoftwareTrigger
{
    [self write:kSWTrigger sendValue:0];
}

- (void) writeChannelConfiguration
{
	unsigned long mask = [self channelConfigMask];
    [self write:kChanConfig sendValue:mask];
}

- (void) writeCustomSize
{
	unsigned long aValue = [self isCustomSize]?[self customSize]:0UL;
    [self write:kCustomSize sendValue:aValue];
}

- (void) report
{
	unsigned long enabled, threshold, numOU, status, bufferOccupancy, dacValue,triggerSrc;
	[self read:kChanEnableMask returnValue:&enabled];
	[self read:kTrigSrcEnblMask returnValue:&triggerSrc];
	int chan;
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"-----------------------------------------------------------\n");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Chan Enabled Thres  NumOver Status Buffers  Offset trigSrc\n");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"-----------------------------------------------------------\n");
	for(chan=0;chan<8;chan++){
		[self readChan:chan reg:kThresholds returnValue:&threshold];
		[self readChan:chan reg:kNumOUThreshold returnValue:&numOU];
		[self readChan:chan reg:kStatus returnValue:&status];
		[self readChan:chan reg:kBufferOccupancy returnValue:&bufferOccupancy];
		[self readChan:chan reg:kDacs returnValue:&dacValue];
		NSString* statusString = @"";
		if(status & 0x20)			statusString = @"Error";
		else if(status & 0x04)		statusString = @"Busy ";
		else {
			if(status & 0x02)		statusString = @"Empty";
			else if(status & 0x01)	statusString = @"Full ";
		}
		NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"  %d     %@    0x%04x  0x%04x  %@  0x%04x  %6.3f  %@\n",
				  chan, enabled&(1<<chan)?@"E":@"X",
				  threshold&0xfff, numOU&0xfff,statusString, 
				  bufferOccupancy&0x7ff, [self convertDacToVolts:dacValue], 
				  triggerSrc&(1<<chan)?@"Y":@"N");
	}
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"-----------------------------------------------------------\n");
	
	unsigned long aValue;
	[self read:kBufferOrganization returnValue:&aValue];
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"# Buffer Blocks : %d\n",(long)powf(2.,(float)aValue));
	
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Software Trigger: %@\n",triggerSrc&0x80000000?@"Enabled":@"Disabled");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"External Trigger: %@\n",triggerSrc&0x40000000?@"Enabled":@"Disabled");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Trigger nHit    : %d\n",(triggerSrc&0x00c000000) >> 24);
	
	
	[self read:kAcqControl returnValue:&aValue];
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Triggers Count  : %@\n",aValue&0x4?@"Accepted":@"All");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Run Mode        : %@\n",Caen1720RunModeString[aValue&0x3]);
	
	[self read:kCustomSize returnValue:&aValue];
	if(aValue)NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Custom Size     : %d\n",aValue);
	else      NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Custom Size     : Disabled\n");
	
	[self read:kAcqStatus returnValue:&aValue];
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Board Ready     : %@\n",aValue&0x100?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"PLL Locked      : %@\n",aValue&0x80?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"PLL Bypass      : %@\n",aValue&0x40?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Clock source    : %@\n",aValue&0x20?@"External":@"Internal");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Buffer full     : %@\n",aValue&0x10?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Events Ready    : %@\n",aValue&0x08?@"YES":@"NO");
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Run             : %@\n",aValue&0x04?@"ON":@"OFF");
	
	[self read:kEventStored returnValue:&aValue];
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Events Stored   : %d\n",aValue);
	
} 

- (void) initBoard
{
    [self softwareReset];
    [self writeAcquisitionControl:NO]; // Make sure it's off.
    [self writeThresholds];
    [self writeChannelConfiguration];
    [self writeCustomSize];
    [self writeTriggerSource];
    [self writeTriggerOut];
    [self writeFrontPanelControl];
    [self writeChannelEnabledMask];
    [self writeBufferOrganization];
    [self writeOverUnderThresholds];
    [self writeDacs];
    [self writePostTriggerSetting];
    NSLog(@"Caen 1720 Card %d inited\n",[self slot]);

}

- (float) convertDacToVolts:(unsigned short)aDacValue 
{ 
	return 2*aDacValue/65535. - 0.9999;  
    //return 2*((short)aDacValue)/65535.;  
}

- (unsigned short) convertVoltsToDac:(float)aVoltage  
{ 
	return 65535. * (aVoltage+1)/2.; 
    //return (unsigned short)((short) (65535. * (aVoltage)/2.)); 
}

- (void) writeThresholds
{
    short	i;
    for (i = 0; i < [self numberOfChannels]; i++){
        [self writeThreshold:i];
    }
}

- (void) softwareReset
{
    [self write:kSWReset sendValue:0];
}

- (void) clearAllMemory
{
    [self write:kSWClear sendValue:0];
}

- (void) writeTriggerCount
{
	unsigned long aValue = ((coincidenceLevel&0x7)<<24) | (triggerSourceMask & 0xffffffff);
    [self write:kTrigSrcEnblMask sendValue:aValue];
}


- (void) writeTriggerSource
{
	unsigned long aValue = ((coincidenceLevel&0x7)<<24) | (triggerSourceMask & 0xffffffff);
    [self write:kTrigSrcEnblMask sendValue:aValue];
}

- (void) writeTriggerOut
{
    [self write:kFPTrigOutEnblMask sendValue:triggerOutMask];
}

- (void) writeFrontPanelControl
{
    [self write:kFPIOControl sendValue:frontPanelControlMask];
}

- (void) readFrontPanelControl
{
	unsigned long aValue;
    [self read:kFPIOControl returnValue:&aValue];
	
	[self setFrontPanelControlMask:aValue];
}


- (void) writeBufferOrganization
{
    [self write:kBufferOrganization sendValue:eventSize];
}

- (void) writeChannelEnabledMask
{
    [self write:kChanEnableMask sendValue:enabledMask];
}

- (void) writePostTriggerSetting
{
    [self write:kPostTrigSetting sendValue:postTriggerSetting];
}

- (void) writeAcquisitionControl:(BOOL)start
{
	unsigned long aValue = (countAllTriggers<<3) | (start<<2) | (acquisitionMode&0x3);
    [self write:kAcqControl sendValue:aValue];
}

- (void) writeNumberBLTEvents:(BOOL)enable
{
    //we must start in a safe mode with 1 event, the numberBLTEvents is passed to SBC
    //unsigned long aValue = (enable) ? numberBLTEventsToReadout : 0;
    unsigned long aValue = (enable) ? 1 : 0;

    [self write:kBLTEventNum sendValue:aValue];
}

- (void) writeEnableExtendedReadoutBuffer:(BOOL)enable
{
    /* Enable/disable the extended readout buffer. The normal readout buffer is
     * mapped to 4kB of address space, however there is an undocumented bit in
     * the vme control register which, if enabled, extends this space to ~16MB.
     * */
    unsigned long aValue;
    [self read:kVMEControl returnValue:&aValue];

    if (enable) {
        aValue |= 0x100;
    } else {
        aValue &= 0xffffffeff;
    }

    [self write:kVMEControl sendValue:aValue];
}

- (void) writeEnableBerr:(BOOL)enable
{
    unsigned long aValue;
    [self read:kVMEControl returnValue:&aValue];

	//we set both bit4: BERR and bit5: ALIGN64 for MBLT64 to work correctly with SBC
	if ( enable ) aValue |= 0x30;
	else aValue &= 0xFFCF;
	//if ( enable ) aValue |= 0x10;
	//else aValue &= 0xFFEF;

    [self write:kVMEControl sendValue:aValue];
}

- (void) checkBufferAlarm
{
	if((bufferState == 1) && isRunning){
		bufferEmptyCount = 0;
		if(!bufferFullAlarm){
			NSString* alarmName = [NSString stringWithFormat:@"Buffer FULL V1720 (slot %d)",[self slot]];
			bufferFullAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kDataFlowAlarm];
			[bufferFullAlarm setSticky:YES];
			[bufferFullAlarm setHelpString:@"The rate is too high. Adjust the Threshold accordingly."];
			[bufferFullAlarm postAlarm];
		}
	}
	else {
		bufferEmptyCount++;
		if(bufferEmptyCount>=5){
			[bufferFullAlarm clearAlarm];
			[bufferFullAlarm release];
			bufferFullAlarm = nil;
			bufferEmptyCount = 0;
		}
	}
	if(isRunning){
		[self performSelector:@selector(checkBufferAlarm) withObject:nil afterDelay:1.5];
	}
	else {
		[bufferFullAlarm clearAlarm];
		[bufferFullAlarm release];
		bufferFullAlarm = nil;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:SNOCaenModelBufferCheckChanged object:self];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];
	
    [self registerNotificationObservers];

    /* initialize our connection to the MTC server */
    mtc_server = [[RedisClient alloc] init];
	
    [[self undoManager] disableUndoRegistration];
    [self setEventSize:[aDecoder decodeIntForKey:@"SNOCaenModelEventSize"]];
    [self setEnabledMask:[aDecoder decodeIntForKey:@"SNOCaenModelEnabledMask"]];
    [self setPostTriggerSetting:[aDecoder decodeInt32ForKey:@"SNOCaenModelPostTriggerSetting"]];
    [self setTriggerSourceMask:[aDecoder decodeInt32ForKey:@"SNOCaenModelTriggerSourceMask"]];
	[self setTriggerOutMask:[aDecoder decodeInt32ForKey:@"SNOCaenModelTriggerOutMask"]];
	[self setFrontPanelControlMask:[aDecoder decodeInt32ForKey:@"SNOCaenModelFrontPanelControlMask"]];
    [self setCoincidenceLevel:[aDecoder decodeIntForKey:@"SNOCaenModelCoincidenceLevel"]];
    [self setAcquisitionMode:[aDecoder decodeIntForKey:@"acquisitionMode"]];
    [self setCountAllTriggers:[aDecoder decodeBoolForKey:@"countAllTriggers"]];
    [self setCustomSize:[aDecoder decodeInt32ForKey:@"customSize"]];
	[self setIsCustomSize:[aDecoder decodeBoolForKey:@"isCustomSize"]];
	[self setIsFixedSize:[aDecoder decodeBoolForKey:@"isFixedSize"]];
    [self setChannelConfigMask:[aDecoder decodeIntForKey:@"channelConfigMask"]];
    [self setWaveFormRateGroup:[aDecoder decodeObjectForKey:@"waveFormRateGroup"]];
    [self setNumberBLTEventsToReadout:[aDecoder decodeInt32ForKey:@"numberBLTEventsToReadout"]];
    [self setContinuousMode:[aDecoder decodeBoolForKey:@"continuousMode"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:8 groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	int i;
    for (i = 0; i < [self numberOfChannels]; i++){
        [self setDac:i withValue:      [aDecoder decodeInt32ForKey: [NSString stringWithFormat:@"CAENDacChnl%d", i]]];
        [self setThreshold:i withValue:[aDecoder decodeInt32ForKey: [NSString stringWithFormat:@"CAENThresChnl%d", i]]];
        [self setOverUnderThreshold:i withValue:[aDecoder decodeIntForKey: [NSString stringWithFormat:@"CAENOverUnderChnl%d", i]]];
    }

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

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
	[anEncoder encodeInt:eventSize forKey:@"SNOCaenModelEventSize"];
	[anEncoder encodeInt:enabledMask forKey:@"SNOCaenModelEnabledMask"];
	[anEncoder encodeInt32:postTriggerSetting forKey:@"SNOCaenModelPostTriggerSetting"];
	[anEncoder encodeInt32:triggerSourceMask forKey:@"SNOCaenModelTriggerSourceMask"];
	[anEncoder encodeInt32:triggerOutMask forKey:@"SNOCaenModelTriggerOutMask"];
	[anEncoder encodeInt32:frontPanelControlMask forKey:@"SNOCaenModelFrontPanelControlMask"];
	[anEncoder encodeInt:coincidenceLevel forKey:@"SNOCaenModelCoincidenceLevel"];
	[anEncoder encodeInt:acquisitionMode forKey:@"acquisitionMode"];
	[anEncoder encodeBool:countAllTriggers forKey:@"countAllTriggers"];
	[anEncoder encodeInt32:customSize forKey:@"customSize"];
	[anEncoder encodeBool:isCustomSize forKey:@"isCustomSize"];
	[anEncoder encodeBool:isFixedSize forKey:@"isFixedSize"];
	[anEncoder encodeInt:channelConfigMask forKey:@"channelConfigMask"];
    [anEncoder encodeObject:waveFormRateGroup forKey:@"waveFormRateGroup"];
    [anEncoder encodeInt32:numberBLTEventsToReadout forKey:@"numberBLTEventsToReadout"];
    [anEncoder encodeBool:continuousMode forKey:@"continuousMode"];
	int i;
	for (i = 0; i < [self numberOfChannels]; i++){
        [anEncoder encodeInt32:dac[i] forKey:[NSString stringWithFormat:@"CAENDacChnl%d", i]];
        [anEncoder encodeInt32:thresholds[i] forKey:[NSString stringWithFormat:@"CAENThresChnl%d", i]];
        [anEncoder encodeInt:overUnderThreshold[i] forKey:[NSString stringWithFormat:@"CAENOverUnderChnl%d", i]];
    }
}

- (NSDictionary*) serializeToDictionary
{
    // Dump current CAEN settings into dictionary.
    // Returns NULL if there was any error.
    NSMutableDictionary* CAENStateDict = [NSMutableDictionary dictionaryWithCapacity:1];
    @try{
        [CAENStateDict setObject:[NSNumber numberWithUnsignedShort:[self channelConfigMask]] forKey:[self getStandardRunKeyForField:@"channelConfigMask" ]];
        [CAENStateDict setObject:[NSNumber numberWithInt:[self eventSize]] forKey:[self getStandardRunKeyForField:@"eventSize" ]];
        [CAENStateDict setObject:[NSNumber numberWithUnsignedLong:[self customSize]] forKey:[self getStandardRunKeyForField:@"customSize" ]];
        [CAENStateDict setObject:[NSNumber numberWithBool:[self isCustomSize]] forKey:[self getStandardRunKeyForField:@"isCustomSize" ]];
        [CAENStateDict setObject:[NSNumber numberWithUnsignedShort:[self acquisitionMode]] forKey:[self getStandardRunKeyForField:@"acquisitionMode" ]];
        [CAENStateDict setObject:[NSNumber numberWithBool:[self countAllTriggers]] forKey:[self getStandardRunKeyForField:@"countAllTriggers" ]];
        [CAENStateDict setObject:[NSNumber numberWithUnsignedLong:[self triggerSourceMask]] forKey:[self getStandardRunKeyForField:@"triggerSourceMask" ]];
        [CAENStateDict setObject:[NSNumber numberWithUnsignedShort:[self coincidenceLevel]] forKey:[self getStandardRunKeyForField:@"coincidenceLevel" ]];
        [CAENStateDict setObject:[NSNumber numberWithUnsignedLong:[self triggerOutMask]] forKey:[self getStandardRunKeyForField:@"triggerOutMask" ]];
        [CAENStateDict setObject:[NSNumber numberWithUnsignedLong:[self postTriggerSetting]] forKey:[self getStandardRunKeyForField:@"postTriggerSetting" ]];
        [CAENStateDict setObject:[NSNumber numberWithUnsignedLong:[self frontPanelControlMask]] forKey:[self getStandardRunKeyForField:@"frontPanelControlMask" ]];
        [CAENStateDict setObject:[NSNumber numberWithUnsignedShort:[self enabledMask]] forKey:[self getStandardRunKeyForField:@"enabledMask" ]];
        for (int idac=0; idac<kNumCaenChannelDacs; ++idac) {
            [CAENStateDict setObject:[NSNumber numberWithUnsignedShort:[self dac:idac]] forKey:[NSString stringWithFormat:@"%@_%i",[self getStandardRunKeyForField:@"dac"],idac]];
        }

        return CAENStateDict;

    } @catch(NSException *err){
        NSLogColor([NSColor redColor], @"CAEN: settings couldn't be saved. error: %@ reason: %@ \n", [err name], [err reason]);
        return NULL;
    }
}

- (BOOL) checkFromSerialization:(NSMutableDictionary*) dict
{
    /* Checks if the current model state is the same as the settings in the
     * dictionary. Returns NO if the settings are the same, YES otherwise.
     *
     * This is used to check if we need to reload the caen settings at the
     * start of a run. According to the documentation, the following registers
     * can't be changed while the acquisition is running:
     *
     *   - buffer organization
     *   - custom size
     *   - channel enable mask
     *
     * But to make life easier, we just check if any setting needs to be
     * changed and if so, resync the run. */
    if ([self channelConfigMask]     != [[dict objectForKey:@"CAEN_channelConfigMask"] unsignedShortValue]) return YES;
    if ([self eventSize]             != [[dict objectForKey:@"CAEN_eventSize"] intValue]) return YES;
    if ([self customSize]            != [[dict objectForKey:@"CAEN_customSize"] unsignedLongValue]) return YES;
    if ([self isCustomSize]          != [[dict objectForKey:@"CAEN_isCustomSize"] boolValue]) return YES;
    if ([self acquisitionMode]       != [[dict objectForKey:@"CAEN_acquisitionMode"] unsignedShortValue]) return YES;
    if ([self countAllTriggers]      != [[dict objectForKey:@"CAEN_countAllTriggers"] boolValue]) return YES;
    if ([self triggerSourceMask]     != [[dict objectForKey:@"CAEN_triggerSourceMask"] unsignedLongValue]) return YES;
    if ([self coincidenceLevel]      != [[dict objectForKey:@"CAEN_coincidenceLevel"] unsignedShortValue]) return YES;
    if ([self triggerOutMask]        != [[dict objectForKey:@"CAEN_triggerOutMask"] unsignedLongValue]) return YES;
    if ([self postTriggerSetting]    != [[dict objectForKey:@"CAEN_postTriggerSetting"] unsignedLongValue]) return YES;
    if ([self frontPanelControlMask] != [[dict objectForKey:@"CAEN_frontPanelControlMask"] unsignedLongValue]) return YES;
    if ([self enabledMask]           != [[dict objectForKey:@"CAEN_enabledMask"] unsignedShortValue]) return YES;
    for (int i = 0; i < kNumCaenChannelDacs; i++) {
        if ([self dac:i] != [[dict objectForKey:[NSString stringWithFormat:@"%@_%i",@"CAEN_dac",i]] unsignedShortValue]) return YES;
    }

    return NO;
}

- (void) loadFromSerialization:(NSMutableDictionary*)settingsDict
{
    [self setChannelConfigMask:[[settingsDict objectForKey:[self getStandardRunKeyForField:@"channelConfigMask"]] unsignedShortValue]];
    [self setEventSize:[[settingsDict objectForKey:[self getStandardRunKeyForField:@"eventSize"]] intValue]];
    [self setCustomSize:[[settingsDict objectForKey:[self getStandardRunKeyForField:@"customSize"]] unsignedLongValue]];
    [self setIsCustomSize:[[settingsDict objectForKey:[self getStandardRunKeyForField:@"isCustomSize"]] boolValue]];
    [self setAcquisitionMode:[[settingsDict objectForKey:[self getStandardRunKeyForField:@"acquisitionMode"]] unsignedShortValue]];
    [self setCountAllTriggers:[[settingsDict objectForKey:[self getStandardRunKeyForField:@"countAllTriggers"]] boolValue]];
    [self setTriggerSourceMask:[[settingsDict objectForKey:[self getStandardRunKeyForField:@"triggerSourceMask"]] unsignedLongValue]];
    [self setCoincidenceLevel:[[settingsDict objectForKey:[self getStandardRunKeyForField:@"coincidenceLevel"]] unsignedShortValue]];
    [self setTriggerOutMask:[[settingsDict objectForKey:[self getStandardRunKeyForField:@"triggerOutMask"]] unsignedLongValue]];
    [self setPostTriggerSetting:[[settingsDict objectForKey:[self getStandardRunKeyForField:@"postTriggerSetting"]] unsignedLongValue]];
    [self setFrontPanelControlMask:[[settingsDict objectForKey:[self getStandardRunKeyForField:@"frontPanelControlMask"]] unsignedLongValue]];
    [self setEnabledMask:[[settingsDict objectForKey:[self getStandardRunKeyForField:@"enabledMask"]] unsignedShortValue]];
    for (int idac=0; idac<kNumCaenChannelDacs; ++idac) {
        [self setDac:idac withValue:[[settingsDict objectForKey:[NSString stringWithFormat:@"%@_%i",[self getStandardRunKeyForField:@"dac"],idac]] unsignedShortValue]];
    }
}

- (NSString*) getStandardRunKeyForField:(NSString*)aField
{
    aField = [NSString stringWithFormat:@"CAEN_%@",aField];
    return aField;
}

#pragma mark •••HW Wizard
- (int) numberOfChannels
{
    return 8;
}
-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:1200 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
	[p setInitMethodSelector:@selector(writeThresholds)];
    [a addObject:p];
    
	p = [[[ORHWWizParam alloc] init] autorelease];
	[p setUseValue:NO];
	[p setName:@"Init"];
	[p setSetMethodSelector:@selector(writeThresholds)];
	[a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:NSStringFromClass([self class])]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:NSStringFromClass([self class])]];
    return a;
    
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Threshold"])return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else return nil;
}

@end

