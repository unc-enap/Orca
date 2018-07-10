//
//ORCaen1724Model.m
//Orca
//
//Created by Mark Howe on Mon Mar 14, 2011.
//Copyright (c) 2011 University of North Carolina. All rights reserved.
//
//-------------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORCaen1724Model.h"
#import "ORVmeCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORRateGroup.h"
#import "VME_HW_Definitions.h"


// Address information for this unit.
#define k792DefaultBaseAddress 		0xa00000
#define k792DefaultAddressModifier 	0x09
NSString* ORCaen1724ModelEventSizeChanged = @"ORCaen1724ModelEventSizeChanged";
static NSString* Caen1724RunModeString[4] = {
@"Register-Controlled",
@"S-In Controlled",
@"S-In Gate",
@"Multi-Board Sync",
};
// Define all the registers available to this unit.
static Caen1724RegisterNamesStruct reg[kNumRegisters] = {
	{@"Output Buffer",      true,	true, 	true,	0x0000,		kReadOnly}, 
	{@"ZS_Thres",			false,	true, 	true,	0x1024,		kReadWrite},
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
	{@"Polarity and Shift",	true,	true, 	false,	0x802A,		kReadWrite},
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
	{@"DownSample Factor",	true,	true, 	false,	0x8128,		kReadWrite},
	{@"Event Stored",		true,	true, 	true,	0x812C,		kReadOnly},
	{@"Set Monitor DAC",	false,	true, 	true,	0x8138,		kReadWrite},
	{@"Board Info",			false,	false, 	false,	0x8140,		kReadOnly},
	{@"Monitor Mode",		false,	true, 	true,	0x8144,		kReadWrite},
	{@"Event Size",			true,	true, 	true,	0x814C,		kReadOnly},
	{@"Analog Monitor",		true,	true, 	false,	0x8150,		kReadWrite},
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
};

#define kEventReadyMask 0x8

NSString* ORCaen1724ModelEnabledMaskChanged                 = @"ORCaen1724ModelEnabledMaskChanged";
NSString* ORCaen1724ModelPostTriggerSettingChanged          = @"ORCaen1724ModelPostTriggerSettingChanged";
NSString* ORCaen1724ModelTriggerSourceMaskChanged           = @"ORCaen1724ModelTriggerSourceMaskChanged";
NSString* ORCaen1724ModelCoincidenceLevelChanged            = @"ORCaen1724ModelCoincidenceLevelChanged";
NSString* ORCaen1724ModelAcquisitionModeChanged             = @"ORCaen1724ModelAcquisitionModeChanged";
NSString* ORCaen1724ModelCountAllTriggersChanged            = @"ORCaen1724ModelCountAllTriggersChanged";
NSString* ORCaen1724ModelCustomSizeChanged                  = @"ORCaen1724ModelCustomSizeChanged";
NSString* ORCaen1724ModelIsFixedSizeChanged		    = @"ORCaen1724ModelIsFixedSizeChanged";
NSString* ORCaen1724ModelChannelConfigMaskChanged           = @"ORCaen1724ModelChannelConfigMaskChanged";
NSString* ORCaen1724ModelNumberBLTEventsToReadoutChanged    = @"ORCaen1724ModelNumberBLTEventsToReadoutChanged";
NSString* ORCaen1724ChnlDacChanged                          = @"ORCaen1724ChnlDacChanged";
NSString* ORCaen1724OverUnderThresholdChanged               = @"ORCaen1724OverUnderThresholdChanged";
NSString* ORCaen1724Chnl                                    = @"ORCaen1724Chnl";
NSString* ORCaen1724ChnlThresholdChanged                    = @"ORCaen1724ChnlThresholdChanged";
NSString* ORCaen1724SelectedChannelChanged                  = @"ORCaen1724SelectedChannelChanged";
NSString* ORCaen1724SelectedRegIndexChanged                 = @"ORCaen1724SelectedRegIndexChanged";
NSString* ORCaen1724WriteValueChanged                       = @"ORCaen1724WriteValueChanged";
NSString* ORCaen1724BasicLock                               = @"ORCaen1724BasicLock";
NSString* ORCaen1724SettingsLock                            = @"ORCaen1724SettingsLock";
NSString* ORCaen1724RateGroupChanged                        = @"ORCaen1724RateGroupChanged";
NSString* ORCaen1724ModelBufferCheckChanged                 = @"ORCaen1724ModelBufferCheckChanged";

@implementation ORCaen1724Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k792DefaultBaseAddress];
    [self setAddressModifier:k792DefaultAddressModifier];
	[self setEnabledMask:0xFF];
    [self setEventSize:0xa];
    [self setNumberBLTEventsToReadout:1];
    [[self undoManager] enableUndoRegistration];
    
	
    return self;
}

- (void) dealloc 
{
    [waveFormRateGroup release];
	[bufferFullAlarm release];
    [super dealloc];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0xEF28);
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1724ModelEventSizeChanged object:self];
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
	 postNotificationName:ORCaen1724RateGroupChanged
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
	 postNotificationName:ORCaen1724SelectedRegIndexChanged
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
	 postNotificationName:ORCaen1724SelectedChannelChanged
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
	 postNotificationName:ORCaen1724WriteValueChanged
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1724ModelEnabledMaskChanged object:self];
}

- (unsigned long) postTriggerSetting
{
    return postTriggerSetting;
}

- (void) setPostTriggerSetting:(unsigned long)aPostTriggerSetting
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerSetting:postTriggerSetting];
    
    postTriggerSetting = aPostTriggerSetting;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1724ModelPostTriggerSettingChanged object:self];
}

- (unsigned long) triggerSourceMask
{
    return triggerSourceMask;
}

- (void) setTriggerSourceMask:(unsigned long)aTriggerSourceMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerSourceMask:triggerSourceMask];
    
    triggerSourceMask = aTriggerSourceMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1724ModelTriggerSourceMaskChanged object:self];
}

- (unsigned short) coincidenceLevel
{
    return coincidenceLevel;
}

- (void) setCoincidenceLevel:(unsigned short)aCoincidenceLevel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCoincidenceLevel:coincidenceLevel];
    
    coincidenceLevel = aCoincidenceLevel;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1724ModelCoincidenceLevelChanged object:self];
}

- (unsigned short) acquisitionMode
{
    return acquisitionMode;
}

- (void) setAcquisitionMode:(unsigned short)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAcquisitionMode:acquisitionMode];
    
    acquisitionMode = aMode;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1724ModelAcquisitionModeChanged object:self];
}

- (BOOL) countAllTriggers
{
    return countAllTriggers;
}

- (void) setCountAllTriggers:(BOOL)aCountAllTriggers
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCountAllTriggers:countAllTriggers];
    
    countAllTriggers = aCountAllTriggers;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1724ModelCountAllTriggersChanged object:self];
}

- (unsigned long) customSize
{
    return customSize;
}

- (void) setCustomSize:(unsigned long)aCustomSize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCustomSize:customSize];
    
    customSize = aCustomSize;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1724ModelCustomSizeChanged object:self];
}

- (BOOL) isFixedSize
{
	return isFixedSize;
}

- (void) setIsFixedSize:(BOOL)aIsFixedSize
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIsFixedSize:isFixedSize];
	
	isFixedSize = aIsFixedSize;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1724ModelIsFixedSizeChanged object:self];
}

- (unsigned short) channelConfigMask
{
    return channelConfigMask;
}

- (void) setChannelConfigMask:(unsigned short)aChannelConfigMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannelConfigMask:channelConfigMask];
    
    channelConfigMask = aChannelConfigMask;
	
	//can't get the packed form to work so just make sure that bit is cleared.
	//channelConfigMask &= ~(1L<<11);
	
	//no packed mode exists, no zero suppresion so far, do not step into the reserved area, make sure these are 0
	channelConfigMask &= 0x000000FFUL;
	
	//random memory access freezes the card, make sure we do the sequential one
	channelConfigMask |= (1L<<4);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1724ModelChannelConfigMaskChanged object:self];
}

- (unsigned long) numberBLTEventsToReadout
{
    return numberBLTEventsToReadout; 
}

- (void) setNumberBLTEventsToReadout:(unsigned long) numBLTEvents
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNumberBLTEventsToReadout:numberBLTEventsToReadout];
    
    numberBLTEventsToReadout = numBLTEvents;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1724ModelNumberBLTEventsToReadoutChanged object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Caen1724Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCaen1724Controller"];
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
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:ORCaen1724Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORCaen1724ChnlDacChanged
	 object:self
	 userInfo:userInfo];
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
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:ORCaen1724Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORCaen1724OverUnderThresholdChanged
	 object:self
	 userInfo:userInfo];
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
    [[self adapter] readLongBlock:pValue
                        atAddress:[self baseAddress] + [self getAddressOffset:pReg] + chan*0x100
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
}

- (void) writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(unsigned long) pValue
{
	unsigned long theValue = pValue;
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
		[[self adapter] writeLongBlock:&theValue
							 atAddress:[self baseAddress] + [self getAddressOffset:pReg] + chan*0x100
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
		
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
    if(aValue>16384)aValue = 16384; //14 bit.
	
    // Set the undo manager action.  The label has already been set by the controller calling this method.
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChnl withValue:[self threshold:aChnl]];
    
    // Set the new value in the model.
    thresholds[aChnl] = aValue;
    
    // Create a dictionary object that stores a pointer to this object and the channel that was changed.
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:ORCaen1724Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORCaen1724ChnlThresholdChanged
	 object:self
	 userInfo:userInfo];
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
    [[self adapter] readLongBlock:pValue
                        atAddress:[self baseAddress] + [self getAddressOffset:pReg]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
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
		[[self adapter] writeLongBlock:&pValue
							 atAddress:[self baseAddress] + [self getAddressOffset:pReg]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
		
	}
	@catch(NSException* localException) {
	}
}


- (void) writeThreshold:(unsigned short) pChan
{
    unsigned long 	threshold = [self threshold:pChan];
    
    [[self adapter] writeLongBlock:&threshold
                         atAddress:[self baseAddress] + reg[kThresholds].addressOffset + (pChan * 0x100)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeOverUnderThresholds
{
	int i;
	for(i=0;i<8;i++){
		unsigned long aValue = overUnderThreshold[i];
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress] + reg[kNumOUThreshold].addressOffset + (i * 0x100)
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (void) readOverUnderThresholds
{
	int i;
	for(i=0;i<8;i++){
		unsigned long value;
		[[self adapter] readLongBlock:&value
							atAddress:[self baseAddress] + reg[kNumOUThreshold].addressOffset + (i * 0x100)
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
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
    
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kDacs].addressOffset + (pChan * 0x100)
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) generateSoftwareTrigger
{
	unsigned long dummy = 0;
    [[self adapter] writeLongBlock:&dummy
                         atAddress:[self baseAddress] + reg[kSWTrigger].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeChannelConfiguration
{
	unsigned long mask = [self channelConfigMask];
	[[self adapter] writeLongBlock:&mask
                         atAddress:[self baseAddress] + reg[kChanConfig].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeCustomSize
{
	unsigned long aValue = [self customSize];
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kCustomSize].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
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
	NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"Run Mode        : %@\n",Caen1724RunModeString[aValue&0x3]);
	
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
	[self writeAcquistionControl:NO]; // Make sure it's off.
	[self clearAllMemory];
	[self softwareReset];
	[self writeThresholds];
	[self writeChannelConfiguration];
	[self writeCustomSize];
	[self writeTriggerSource];
	[self writeChannelEnabledMask];
	[self writeBufferOrganization];
	[self writeOverUnderThresholds];
	[self writeDacs];
	[self writePostTriggerSetting];
}

- (float) convertDacToVolts:(unsigned short)aDacValue 
{ 
	return 2.25*aDacValue/65535. - 1.1249;  
}

- (unsigned short) convertVoltsToDac:(float)aVoltage  
{ 
	return 65535. * (aVoltage+1.125)/2.25; 
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
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kSWReset].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) clearAllMemory
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kSWClear].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) writeTriggerCount
{
	unsigned long aValue = ((coincidenceLevel&0x7)<<24) | (triggerSourceMask & 0xffffffff);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kTrigSrcEnblMask].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) writeTriggerSource
{
	unsigned long aValue = ((coincidenceLevel&0x7)<<24) | (triggerSourceMask & 0xffffffff);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kTrigSrcEnblMask].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) writeBufferOrganization
{
	unsigned long aValue = eventSize;//(unsigned long)pow(2.,(float)eventSize);	
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kBufferOrganization].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeChannelEnabledMask
{
	unsigned long aValue = enabledMask;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kChanEnableMask].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) writePostTriggerSetting
{
	[[self adapter] writeLongBlock:&postTriggerSetting
                         atAddress:[self baseAddress] + reg[kPostTrigSetting].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) writeAcquistionControl:(BOOL)start
{
	unsigned long aValue = (countAllTriggers<<3) | (start<<2) | (acquisitionMode&0x3);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kAcqControl].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) writeNumberBLTEvents:(BOOL)enable
{
    unsigned long aValue = (enable) ? numberBLTEventsToReadout : 0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kBLTEventNum].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeEnableBerr:(BOOL)enable
{
	unsigned long aValue;
	[[self adapter] readLongBlock:&aValue
			    atAddress:[self baseAddress] + reg[kVMEControl].addressOffset
                            numToRead:1
			   withAddMod:[self addressModifier]
			usingAddSpace:0x01];

	//we set both bit4: BERR and bit5: ALIGN64 for MBLT64 to work correctly with SBC
	if ( enable ) aValue |= 0x30;
	else aValue &= 0xFFCF;
	//if ( enable ) aValue |= 0x10;
	//else aValue &= 0xFFEF;
    
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + reg[kVMEControl].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) checkBufferAlarm
{
	if((bufferState == 1) && isRunning){
		bufferEmptyCount = 0;
		if(!bufferFullAlarm){
			NSString* alarmName = [NSString stringWithFormat:@"Buffer FULL V1724 (slot %d)",[self slot]];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen1724ModelBufferCheckChanged object:self];
}

#pragma mark ***DataTaker
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
								 @"ORCaen1724WaveformDecoder",				@"decoder",
								 [NSNumber numberWithLong:dataId],           @"dataId",
								 [NSNumber numberWithBool:YES],              @"variable",
								 [NSNumber numberWithLong:-1],               @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"CAEN"];
    return dataDictionary;
}

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<8;i++){
        waveFormCount[i]=0;
    }
}

- (void) reset
{
}

- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
	if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:NSStringFromClass([self class])]; 
    
	//cache for speed    
	controller		= [self adapter]; 
	statusReg		= [self baseAddress] + reg[kAcqStatus].addressOffset;
	eventSizeReg	= [self baseAddress] + reg[kEventSize].addressOffset;
	dataReg			= [self baseAddress] + reg[kOutputBuffer].addressOffset;
	location		=  (([self crateNumber]&0x01e)<<21) | (([self slot]& 0x0000001f)<<16);
	isRunning		= NO;
    
    BOOL sbcRun = [[userInfo objectForKey:kSBCisDataTaker] boolValue];
	
    [self startRates];
    [self initBoard];
    [self setNumberBLTEventsToReadout:1];  // Hardcode this for now
    [self writeNumberBLTEvents:sbcRun];
    [self writeEnableBerr:sbcRun];
	
	
	[self writeAcquistionControl:YES];
	[self performSelector:@selector(checkBufferAlarm) withObject:nil afterDelay:1];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
{
	@try {
		unsigned long status;
		isRunning = YES; 
		
		[controller readLongBlock:&status
						atAddress:statusReg
						numToRead:1
					   withAddMod:addressModifier 
					usingAddSpace:0x01];
		bufferState = (status & 0x10) >> 4;						
		if(status & kEventReadyMask){
			//OK, at least one event is ready
			
			unsigned long theFirst;
			[controller readLongBlock:&theFirst
					atAddress:dataReg
					numToRead:1
				       withAddMod:addressModifier 
				    usingAddSpace:0x01]; //we set it to not increment the address.
			
			unsigned long theEventSize;
			//the event size is reported incorrectly by CAEN 1724
			//the first event is OK, all the others are 0 size
			//extract the event size from the first word as suggested in the user guide
			//it seems the event size is correctly reported only in the BLT mode
			/*
			[controller readLongBlock:&theEventSize
							atAddress:eventSizeReg
							numToRead:1
						   withAddMod:addressModifier 
						usingAddSpace:0x01];
			*/
			theEventSize = theFirst&0x0FFFFFFF;
			
            if ( theEventSize == 0 ) return;
			NSMutableData* theData = [NSMutableData dataWithCapacity:2+theEventSize*sizeof(long)];
			[theData setLength:(2+theEventSize)*sizeof(long)];
			unsigned long* p = (unsigned long*)[theData bytes];
			*p++ = dataId | (2 + theEventSize);
			*p++ = location;

			*p++ = theFirst;
			[controller readLongBlock:p
							atAddress:dataReg
							numToRead:theEventSize - 1
						   withAddMod:addressModifier 
						usingAddSpace:0xFF]; //we set it to not increment the address.
			
			[aDataPacket addData:theData];
			unsigned short chanMask = p[0]; //remember, the point was already inc'ed to the start of data + 1
			int i;
			for(i=0;i<8;i++){
				if(chanMask & (1<<i)) ++waveFormCount[i]; 
			}
		}
		
		
	}
	@catch(NSException* localException) {
	}
	
}

- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
    isRunning = NO;
    [waveFormRateGroup stop];
	[self writeAcquistionControl:NO];
	short i;
    for(i=0;i<8;i++)waveFormCount[i] = 0;
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
	if(isRunning)return NO;
    
    ++waveFormCount[channel];
    return YES;
}


- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 1724 (Slot %d) ",[self slot]];
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kCaen1724; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId; //better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= [self addressModifier];
	configStruct->card_info[index].base_add					= [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0]	= reg[kEventStored].addressOffset;	//Status buffer
    configStruct->card_info[index].deviceSpecificData[1]	= reg[kEventSize].addressOffset;	// "next event size" address
    configStruct->card_info[index].deviceSpecificData[2]	= reg[kOutputBuffer].addressOffset; // fifo Address
    configStruct->card_info[index].deviceSpecificData[3]	= 0x0C;								// fifo Address Modifier (A32 MBLT)
    configStruct->card_info[index].deviceSpecificData[4]	= 0xFFC;							// fifo Size
    configStruct->card_info[index].deviceSpecificData[5]	= location;
    configStruct->card_info[index].deviceSpecificData[6]	= reg[kVMEControl].addressOffset;	// VME Control address
    configStruct->card_info[index].deviceSpecificData[7]	= reg[kBLTEventNum].addressOffset;	// Num of BLT events address
    
	unsigned sizeOfEvent = 0; // number of uint32_t for DMA transfer
	if (isFixedSize) {
		unsigned long numChan = 0;
		unsigned long chanMask = [self enabledMask];
		for (; chanMask; numChan++) chanMask &= chanMask - 1;
		//if (isCustomSize) {
		//	sizeOfEvent = numChan * customSize * 2 + 4;
		//}
		//else {
			sizeOfEvent = numChan * (1UL << 20 >> [self eventSize]) / 4 + 4; //(1MB / num of blocks)
		//}
	}
	configStruct->card_info[index].deviceSpecificData[8]	= sizeOfEvent;
	
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setEventSize:[aDecoder decodeIntForKey:@"ORCaen1724ModelEventSize"]];
    [self setEnabledMask:[aDecoder decodeIntForKey:@"ORCaen1724ModelEnabledMask"]];
    [self setPostTriggerSetting:[aDecoder decodeInt32ForKey:@"ORCaen1724ModelPostTriggerSetting"]];
    [self setTriggerSourceMask:[aDecoder decodeInt32ForKey:@"ORCaen1724ModelTriggerSourceMask"]];
    [self setCoincidenceLevel:[aDecoder decodeIntForKey:@"ORCaen1724ModelCoincidenceLevel"]];
    [self setAcquisitionMode:[aDecoder decodeIntForKey:@"acquisitionMode"]];
    [self setCountAllTriggers:[aDecoder decodeBoolForKey:@"countAllTriggers"]];
    [self setCustomSize:[aDecoder decodeInt32ForKey:@"customSize"]];
	[self setIsFixedSize:[aDecoder decodeBoolForKey:@"isFixedSize"]];
    [self setChannelConfigMask:[aDecoder decodeIntForKey:@"channelConfigMask"]];
    [self setWaveFormRateGroup:[aDecoder decodeObjectForKey:@"waveFormRateGroup"]];
    [self setNumberBLTEventsToReadout:[aDecoder decodeInt32ForKey:@"numberBLTEventsToReadout"]];
    
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
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
	[anEncoder encodeInt:eventSize forKey:@"ORCaen1724ModelEventSize"];
	[anEncoder encodeInt:enabledMask forKey:@"ORCaen1724ModelEnabledMask"];
	[anEncoder encodeInt32:postTriggerSetting forKey:@"ORCaen1724ModelPostTriggerSetting"];
	[anEncoder encodeInt32:triggerSourceMask forKey:@"ORCaen1724ModelTriggerSourceMask"];
	[anEncoder encodeInt:coincidenceLevel forKey:@"ORCaen1724ModelCoincidenceLevel"];
	[anEncoder encodeInt:acquisitionMode forKey:@"acquisitionMode"];
	[anEncoder encodeBool:countAllTriggers forKey:@"countAllTriggers"];
	[anEncoder encodeInt32:customSize forKey:@"customSize"];
	[anEncoder encodeBool:isFixedSize forKey:@"isFixedSize"];
	[anEncoder encodeInt:channelConfigMask forKey:@"channelConfigMask"];
    [anEncoder encodeObject:waveFormRateGroup forKey:@"waveFormRateGroup"];
    [anEncoder encodeInt32:numberBLTEventsToReadout forKey:@"numberBLTEventsToReadout"];
	int i;
	for (i = 0; i < [self numberOfChannels]; i++){
        [anEncoder encodeInt32:dac[i] forKey:[NSString stringWithFormat:@"CAENDacChnl%d", i]];
        [anEncoder encodeInt32:thresholds[i] forKey:[NSString stringWithFormat:@"CAENThresChnl%d", i]];
        [anEncoder encodeInt:overUnderThreshold[i] forKey:[NSString stringWithFormat:@"CAENOverUnderChnl%d", i]];
    }
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
    [p setFormat:@"##0" upperLimit:16384 lowerLimit:0 stepSize:1 units:@""];
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

@implementation ORCaen1724DecoderForCAEN : ORCaenDataDecoder
- (NSString*) identifier
{
    return @"CAEN 1724 Digitizer";
}
@end

