/*
 *  ORCCUSBModel.m
 *  Orca
 *
 *  Created by Mark Howe on Tues May 30 2006.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */

#import "ORCCUSBModel.h"
#import "ORPCICamacModel.h"
#import "ORCamacCrateModel.h"

#import "ORUSB.h"
#import "ORUSBInterface.h"
#import "ORReadOutList.h"
#import "ORCamacListProtocol.h"

NSString* ORCCUSBModelCustomStackChanged		= @"ORCCUSBModelCustomStackChanged";
NSString* ORCCUSBModelUseDataModifierChanged	= @"ORCCUSBModelUseDataModifierChanged";
NSString* ORCCUSBModelDataWordChanged			= @"ORCCUSBModelDataWordChanged";
NSString* ORCCUSBModelDataModifierBitsChanged	= @"ORCCUSBModelDataModifierBitsChanged";
NSString* ORCCUSBModelNafModBitsChanged			= @"ORCCUSBModelNafModBitsChanged";
NSString* ORCCUSBModelFValueChanged				= @"ORCCUSBModelFValueChanged";
NSString* ORCCUSBModelAValueChanged				= @"ORCCUSBModelAValueChanged";
NSString* ORCCUSBModelNValueChanged				= @"ORCCUSBModelNValueChanged";
NSString* ORCCUSBModelUsbTransferSetupChanged	= @"ORCCUSBModelUsbTransferSetupChanged";
NSString* ORCCUSBModelLAMMaskChanged			= @"ORCCUSBModelLAMMaskChanged";
NSString* ORCCUSBModelScalerBChanged			= @"ORCCUSBModelScalerBChanged";
NSString* ORCCUSBModelScalerAChanged			= @"ORCCUSBModelScalerAChanged";
NSString* ORCCUSBModelDelayAndGateExtChanged	= @"ORCCUSBModelDelayAndGateExtChanged";
NSString* ORCCUSBModelDelayAndGateBChanged		= @"ORCCUSBModelDelayAndGateBChanged";
NSString* ORCCUSBModelDelayAndGateAChanged		= @"ORCCUSBModelDelayAndGateAChanged";
NSString* ORCCUSBModelScalerReadoutChanged		= @"ORCCUSBModelScalerReadoutChanged";
NSString* ORCCUSBModelUserDeviceSelectorChanged = @"ORCCUSBModelUserDeviceSelectorChanged";
NSString* ORCCUSBModelUserNIMSelectorChanged	= @"ORCCUSBModelUserNIMSelectorChanged";
NSString* ORCCUSBModelUserLEDSelectorChanged	= @"ORCCUSBModelUserLEDSelectorChanged";
NSString* ORCCUSBModelDelaysChanged				= @"ORCCUSBModelDelaysChanged";
NSString* ORCCUSBModelGlobalModeChanged			= @"ORCCUSBModelGlobalModeChanged";
NSString* ORCCUSBModelRegisterValueChanged		= @"ORCCUSBModelRegisterValueChanged";
NSString* ORCCUSBModelInternalRegSelectionChanged = @"ORCCUSBModelInternalRegSelectionChanged";
NSString* ORCCUSBSettingsLock					= @"ORCCUSBSettingsLock";
NSString* ORCCUSBInterfaceChanged				= @"ORCCUSBInterfaceChanged";
NSString* ORCCUSBSerialNumberChanged			= @"ORCCUSBSerialNumberChanged";

#define kNumInternalRegs 16
#define R	0
#define W	1
#define RW	2

struct {
	NSString*	regName;
	int			mask;
	int			readWrite;
} ccusbRegs[kNumInternalRegs] = {
	{@"Firmware ID",				 0xffffffff,		R,},
	{@"Global Mode",				 0x0000ffff,		RW},
	{@"Delays",						 0x0000ffff,		RW},
	{@"Scaler ReadOut Control",		 0x00ffffff,		RW},
	{@"User LED Source Selection",	 0xffffffff,		RW},
	{@"User NIM Output Source",		 0xffffffff,		RW},
	{@"Source Selector User Devices",0xffffffff,		RW},
	{@"Delay and Gate Generator A",  0xffffffff,		RW},
	{@"Delay and Gate Generator B",  0xffffffff,		RW},
	{@"LAM Mask",					 0xffffffff,		RW},
	{@"CAMAC LAM",					 0x00ffffff,		R},
	{@"Scaler A",					 0xffffffff,		R},
	{@"Scaler B",					 0xffffffff,		R},
	{@"Extended Delay Register",	 0xffffffff,		RW},
	{@"USB Buffer Setup",			 0xffffffff,		RW},
	{@"Broadcast Map",				 0x00ffffff,		R},
};

enum {
	kFirmwareIDReg					= 0,
	kGlobalModeReg					= 1,
	kDelaysReg						= 2,
	kScalerReadoutControlReg		= 3,
	kUserLEDSourceReg				= 4,
	kNIMOutputReg					= 5,
	kSourceSelectorUserDevicesReg	= 6,
	kDelayAndGateGeneratorAReg		= 7,
	kDelayAndGateGeneratorBReg		= 8,
	kLamMaskReg						= 9,
	kCAMACLamReg					= 10,
	kScalerAReg						= 11,
	kScalerBReg						= 12,
	kExtendedDelayReg				= 13,
	kusbBufferSetupReg				= 14,
	kBroadcastMapReg				= 15
};


@implementation ORCCUSBModel
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    		
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) dealloc
{
    [lastStackFilePath release];
    [customStack release];
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"CCUSB"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCCUSBController"];
}

- (id) controller
{
	return self; //for now
}

- (void)  checkCratePower
{   
	[self checkInterface];
}

- (void) makeConnectors
{	
   //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    [connector setOffColor:[NSColor yellowColor]];
	[connector setConnectorType: 'USBI' ];
	[connector addRestrictedConnectionType: 'USBO' ]; //can only connect to usb output
}

- (unsigned short) camacStatus
{
//    unsigned short theStatus = [[self controller] camacStatus];
//    [self decodeStatus:theStatus];
    return 0;
}

- (NSString*) title 
{
	return [NSString stringWithFormat:@"CC-USB (Serial# %@)",[usbInterface serialNumber]];
}

- (NSString*) helpURL
{
	return @"CAMAC/CCUSB.html";
}

#pragma mark ¥¥¥USB Protocol
- (id) getUSBController
{
	return [[self crate] usbController];
}

- (ORUSBInterface*) usbInterface
{
	return usbInterface;
}

- (NSString*) serialNumber
{
    return serialNumber;
}

- (void) setSerialNumber:(NSString*)aSerialNumber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerialNumber:serialNumber];
    
    [serialNumber autorelease];
    serialNumber = [aSerialNumber copy];    

	if(!serialNumber){
		[[self getUSBController] releaseInterfaceFor:self];
	}
	else [[self getUSBController] claimInterfaceWithSerialNumber:serialNumber for:self];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBSerialNumberChanged object:self];
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface
{
	[usbInterface release];
	usbInterface = anInterface;
	[usbInterface retain];	

	[[NSNotificationCenter defaultCenter]
			postNotificationName: ORCCUSBInterfaceChanged
						  object: self];


}

- (void) interfaceAdded:(NSNotification*)aNote
{
	[[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
	@try {
		[self checkInterface];
	}
@catch(NSException* localException) {
	}
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
	//was it our interface?
	if(usbInterface){
		id anInterface =  [[[aNote object] interfacesForVender:[self vendorID] product:[self productID]] objectAtIndex:0];
		
		if(anInterface == usbInterface || !anInterface){
			[usbInterface release];
			usbInterface = nil;
		}
		
		@try {
			[self checkInterface];
		}
@catch(NSException* localException) {
		}
	}
}


- (NSString*) usbInterfaceDescription
{
	if(usbInterface)return [usbInterface description];
	else return @"?";
}

- (void) registerWithUSB:(id)usb
{
	[usb registerForUSBNotifications:self];
}

- (NSUInteger) vendorID
{
	return 0x16DC;
}

- (NSUInteger) productID
{
	return 0x1;
}

- (NSString*) hwName
{
	if(usbInterface)return [usbInterface deviceName];
	else return @"?";
}

- (NSString*) settingsLock
{
	return ORCCUSBSettingsLock;
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"CC-USB";
}

- (NSString*) lastStackFilePath
{
    return lastStackFilePath;
}

- (void) setLastStackFilePath:(NSString*)aLastStackFilePath
{
    [lastStackFilePath autorelease];
    lastStackFilePath = [aLastStackFilePath copy];    
}

- (NSMutableArray*) customStack
{
    return customStack;
}

- (void) setCustomStack:(NSMutableArray*)aCustomStack
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCustomStack:customStack];

    [aCustomStack retain];
    [customStack release];
    customStack = aCustomStack;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelCustomStackChanged object:self];
}

- (BOOL) useDataModifier
{
    return useDataModifier;
}

- (void) setUseDataModifier:(BOOL)aUseDataModifier
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseDataModifier:useDataModifier];
    
    useDataModifier = aUseDataModifier;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelUseDataModifierChanged object:self];
}


- (unsigned short) dataWord
{
    return dataWord;
}

- (void) setDataWord:(unsigned short)aDataWord
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDataWord:dataWord];
    
    dataWord = aDataWord;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelDataWordChanged object:self];
}

- (unsigned short) dataModifierBits
{
    return dataModifierBits;
}

- (void) setDataModifierBits:(short)aDataModifierBits
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDataModifierBits:dataModifierBits];
    
    dataModifierBits = aDataModifierBits;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelDataModifierBitsChanged object:self];
}

- (short) nafModBits
{
    return nafModBits;
}

- (void) setNafModBits:(short)aNafModBits
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNafModBits:nafModBits];
    
    nafModBits = aNafModBits;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelNafModBitsChanged object:self];
}

- (short) fValue
{
    return fValue;
}

- (void) setFValue:(short)aFValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFValue:fValue];
    
    fValue = aFValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelFValueChanged object:self];
}

- (short) aValue
{
    return aValue;
}

- (void) setAValue:(short)aAValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAValue:aValue];
    
    aValue = aAValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelAValueChanged object:self];
}

- (short) nValue
{
    return nValue;
}

- (void) setNValue:(short)aNValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNValue:nValue];
    
    nValue = aNValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelNValueChanged object:self];
}

- (unsigned short) usbTransferSetup
{
    return usbTransferSetup;
}

- (void) setUsbTransferSetup:(unsigned short)aUsbTransferSetup
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUsbTransferSetup:usbTransferSetup];
    
    usbTransferSetup = aUsbTransferSetup;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelUsbTransferSetupChanged object:self];
}

- (unsigned long) LAMMaskValue
{
    return LAMMaskValue;
}

- (void) setLAMMaskValue:(unsigned long)aLAMMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLAMMaskValue:LAMMaskValue];
    
    LAMMaskValue = aLAMMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelLAMMaskChanged object:self];
}

- (unsigned long) scalerB
{
    return scalerB;
}

- (void) setScalerB:(unsigned long)aScalerB
{
    [[[self undoManager] prepareWithInvocationTarget:self] setScalerB:scalerB];
    
    scalerB = aScalerB;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelScalerBChanged object:self];
}

- (unsigned long) scalerA
{
    return scalerA;
}

- (void) setScalerA:(unsigned long)aScalerA
{
    [[[self undoManager] prepareWithInvocationTarget:self] setScalerA:scalerA];
    
    scalerA = aScalerA;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelScalerAChanged object:self];
}

- (unsigned long) delayAndGateExt
{
    return delayAndGateExt;
}

- (void) setDelayAndGateExt:(unsigned long)aDelayAndGateExt
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDelayAndGateExt:delayAndGateExt];
    
    delayAndGateExt = aDelayAndGateExt;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelDelayAndGateExtChanged object:self];
}

- (unsigned long) delayAndGateB
{
    return delayAndGateB;
}

- (void) setDelayAndGateB:(unsigned long)aDelayAndGateB
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDelayAndGateB:delayAndGateB];
    
    delayAndGateB = aDelayAndGateB;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelDelayAndGateBChanged object:self];
}

- (unsigned long) delayAndGateA
{
    return delayAndGateA;
}

- (void) setDelayAndGateA:(unsigned long)aDelayAndGateA
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDelayAndGateA:delayAndGateA];
    
    delayAndGateA = aDelayAndGateA;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelDelayAndGateAChanged object:self];
}

- (unsigned long) scalerReadout
{
    return scalerReadout;
}

- (void) setScalerReadout:(unsigned long)aScalerReadout
{
    [[[self undoManager] prepareWithInvocationTarget:self] setScalerReadout:scalerReadout];
    
    scalerReadout = aScalerReadout;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelScalerReadoutChanged object:self];
}

- (unsigned long) userDeviceSelector
{
    return userDeviceSelector;
}

- (void) setUserDeviceSelector:(unsigned long)aUserDeviceSelector
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUserDeviceSelector:userDeviceSelector];
    
    userDeviceSelector = aUserDeviceSelector;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelUserDeviceSelectorChanged object:self];
}

- (unsigned long) userNIMSelector
{
    return userNIMSelector;
}

- (void) setUserNIMSelector:(unsigned long)aUserNIMSelector
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUserNIMSelector:userNIMSelector];
    
    userNIMSelector = aUserNIMSelector;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelUserNIMSelectorChanged object:self];
}

- (unsigned long) userLEDSelector
{
    return userLEDSelector;
}

- (void) setUserLEDSelector:(unsigned long)aUserLEDSelector
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUserLEDSelector:userLEDSelector];
    
    userLEDSelector = aUserLEDSelector;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelUserLEDSelectorChanged object:self];
}

- (unsigned short) delays
{
    return delays;
}

- (void) setDelays:(unsigned short)aDelays
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDelays:delays];
    
    delays = aDelays;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelDelaysChanged object:self];
}

- (unsigned short) globalMode
{
    return globalMode;
}

- (void) setGlobalMode:(unsigned short)aGlobalMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGlobalMode:globalMode];
    
    globalMode = aGlobalMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelGlobalModeChanged object:self];
}

- (BOOL) registerWritable:(int)reg
{
	if(reg>=0 && reg<kNumInternalRegs) return ccusbRegs[reg].readWrite == W || ccusbRegs[reg].readWrite == RW;
	else return NO;
}

- (NSString*) registerName:(int)reg
{
	if(reg>=0 && reg<kNumInternalRegs) return ccusbRegs[reg].regName;
	else return @"??";
}

- (int) registerValue
{
    return registerValue;
}

- (void) setRegisterValue:(int)aRegisterValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRegisterValue:registerValue];
    
    registerValue = aRegisterValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelRegisterValueChanged object:self];
}

- (int) internalRegSelection
{
    return internalRegSelection;
}

- (void) setInternalRegSelection:(int)aInternalRegSelection
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInternalRegSelection:internalRegSelection];
    
    internalRegSelection = aInternalRegSelection;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelInternalRegSelectionChanged object:self];
}


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setLastStackFilePath:[decoder decodeObjectForKey:@"ORCCUSBModelLastStackFilePath"]];
    [self setCustomStack:[decoder decodeObjectForKey:@"ORCCUSBModelCustomStackArray"]];
    [self setUseDataModifier:[decoder decodeBoolForKey:@"ORCCUSBModelUseDataModifier"]];
    [self setDataWord:[decoder decodeIntForKey:@"ORCCUSBModelDataWord"]];
    [self setDataModifierBits:[decoder decodeIntForKey:@"ORCCUSBModelDataModifierBits"]];
    [self setNafModBits:[decoder decodeIntForKey:@"ORCCUSBModelNafModBits"]];
    [self setFValue:[decoder decodeIntForKey:@"ORCCUSBModelFValue"]];
    [self setAValue:[decoder decodeIntForKey:@"ORCCUSBModelAValue"]];
    [self setNValue:[decoder decodeIntForKey:@"ORCCUSBModelNValue"]];
    [self setUsbTransferSetup:[decoder decodeIntForKey:@"ORCCUSBModelUsbTransferSetup"]];
    [self setLAMMaskValue:[decoder decodeInt32ForKey:@"ORCCUSBModelLAMMaskValue"]];
    [self setScalerB:[decoder decodeInt32ForKey:@"ORCCUSBModelScalerB"]];
    [self setScalerA:[decoder decodeInt32ForKey:@"ORCCUSBModelScalerA"]];
    [self setDelayAndGateExt:[decoder decodeInt32ForKey:@"ORCCUSBModelDelayAndGateExt"]];
    [self setDelayAndGateB:[decoder decodeInt32ForKey:@"ORCCUSBModelDelayAndGateB"]];
    [self setDelayAndGateA:[decoder decodeInt32ForKey:@"ORCCUSBModelDelayAndGateA"]];
    [self setScalerReadout:[decoder decodeInt32ForKey:@"ORCCUSBModelScalerReadout"]];
    [self setUserDeviceSelector:[decoder decodeInt32ForKey:@"ORCCUSBModelUserDeviceSelector"]];
    [self setUserNIMSelector:[decoder decodeIntForKey:@"ORCCUSBModelUserNIMSelector"]];
    [self setUserLEDSelector:[decoder decodeIntForKey:@"ORCCUSBModelUserLEDSelector"]];
    [self setDelays:[decoder decodeIntForKey:@"ORCCUSBModelDelays"]];
    [self setGlobalMode:[decoder decodeIntForKey:@"ORCCUSBModelGlobalMode"]];
    [self setRegisterValue:[decoder decodeIntForKey:@"ORCCUSBModelRegisterValue"]];
    [self setInternalRegSelection:[decoder decodeIntForKey:@"ORCCUSBModelInternalRegSelection"]];
    [self setSerialNumber:[decoder decodeObjectForKey:@"ORCCUSBModelSerialNumber"]];
    [[self undoManager] enableUndoRegistration];    
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:lastStackFilePath forKey:@"ORCCUSBModelLastStackFilePath"];
    [encoder encodeObject:customStack forKey:@"ORCCUSBModelCustomStackArray"];
    [encoder encodeBool:useDataModifier forKey:@"ORCCUSBModelUseDataModifier"];
    [encoder encodeInt:dataWord forKey:@"ORCCUSBModelDataWord"];
    [encoder encodeInt:dataModifierBits forKey:@"ORCCUSBModelDataModifierBits"];
    [encoder encodeInt:nafModBits forKey:@"ORCCUSBModelNafModBits"];
    [encoder encodeInt:fValue forKey:@"ORCCUSBModelFValue"];
    [encoder encodeInt:aValue forKey:@"ORCCUSBModelAValue"];
    [encoder encodeInt:nValue forKey:@"ORCCUSBModelNValue"];
    [encoder encodeInt:usbTransferSetup forKey:@"ORCCUSBModelUsbTransferSetup"];
    [encoder encodeInt32:LAMMaskValue forKey:@"ORCCUSBModelLAMMaskValue"];
    [encoder encodeInt32:scalerB forKey:@"ORCCUSBModelScalerB"];
    [encoder encodeInt32:scalerA forKey:@"ORCCUSBModelScalerA"];
    [encoder encodeInt32:delayAndGateExt forKey:@"ORCCUSBModelDelayAndGateExt"];
    [encoder encodeInt32:delayAndGateB forKey:@"ORCCUSBModelDelayAndGateB"];
    [encoder encodeInt32:delayAndGateA forKey:@"ORCCUSBModelDelayAndGateA"];
    [encoder encodeInt32:scalerReadout forKey:@"ORCCUSBModelScalerReadout"];
    [encoder encodeInt32:userDeviceSelector forKey:@"ORCCUSBModelUserDeviceSelector"];
    [encoder encodeInt:userNIMSelector forKey:@"ORCCUSBModelUserNIMSelector"];
    [encoder encodeInt:userLEDSelector forKey:@"ORCCUSBModelUserLEDSelector"];
    [encoder encodeInt:delays forKey:@"ORCCUSBModelDelays"];
    [encoder encodeInt:globalMode forKey:@"ORCCUSBModelGlobalMode"];
    [encoder encodeInt:registerValue forKey:@"ORCCUSBModelRegisterValue"];
    [encoder encodeInt:internalRegSelection forKey:@"ORCCUSBModelInternalRegSelection"];
    [encoder encodeObject:serialNumber forKey:@"ORCCUSBModelSerialNumber"];
}


//camac low level functions
- (unsigned short)  readLAMMask:(unsigned long *)mask
{
	return  [[self controller] camacLongNAF:25 a:9 f:24 data:mask];
} 


- (unsigned long) setLAMMask:(unsigned long) mask
{
	return  [[self controller] camacLongNAF:25 a:9 f:25 data:&mask];
}

- (unsigned short)  setCrateInhibit:(BOOL)state
{   
    return  [[self controller] camacShortNAF:29 a:9 f:state?24:26];
}


- (unsigned short)  executeZCycle
{
	return  [[self controller] camacShortNAF:28 a:8 f:29];
}

- (unsigned short)  executeCCycle
{
    return  [[self controller] camacShortNAF:28 a:9 f:29];
}


- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f
							 data:(unsigned short*) data
{
	unsigned long iData = 0;
	if(data) iData = *data;
	int status = [self sendNAF:n a:a f:f d24:NO data:&iData];
	if(data) *data = iData;
	return status;
}

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f;
{
	unsigned long dummy = 0;
	return  [self sendNAF:n a:a f:f d24:NO data:&dummy];
}

- (unsigned short)  camacLongNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(unsigned long*) data
{
	return [self sendNAF:n a:a f:f d24:YES data:data];
}


- (unsigned short)  camacShortNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned short*) data
                                length:(unsigned long)    numWords
{
	int i;
	for(i=0;i<numWords;i++){
		unsigned long iData = 0;
		[self sendNAF:n a:a f:f d24:NO data:&iData];
		*data++ = iData;
	}
	return 0;
}

- (unsigned short)  camacLongNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned long*) data
                                length:(unsigned long)    numWords
{
	int i;
	for(i=0;i<numWords;i++){
		unsigned long iData = 0;
		[self sendNAF:n a:a f:f d24:YES data:&iData];
		*data++ = iData;
	}
	return 0;
}


///usb specific stuff
/********************************************************************/
- (int) flush
{
	int count, rd;
	char buf[16*1024];
	
	for (count=0; count<1000; count++){
		rd = [usbInterface readBytes:buf length:sizeof(buf)];
		if (rd < 0)return 0;
		
		NSLog(@"flush: count=%d, rd=%d, buf: 0x%02x 0x%02x 0x%02x 0x%02x\n",count,rd,buf[0],buf[1],buf[2],buf[3]);
	}
	
	[self getStatus];
	
	NSLog(@"flush: CCUSB is babbling. Please reset it by cycling power on the CAMAC crate.\n");
	
	//musb_reset(myusbcrate);
	
	//ccusb_status(myusbcrate);
		
	return -1;
}

- (long) readReg:(int) ireg
{
	unsigned long lValue; 
	[self camacLongNAF:25 a:ireg f:0 data:&lValue];
	return  lValue & ccusbRegs[ireg].mask;
}

- (int) writeReg:(int) ireg value:(int) value
{
	unsigned long lValue = ccusbRegs[ireg].mask & value;
	return [self camacLongNAF:25 a:ireg f:16 data:&lValue];
}

-(int) reset
{
	char cmd[512];

	cmd[0] = 255;
	cmd[1] = 255;
	cmd[2] = 0;
	cmd[3] = 0;
	[usbInterface writeBytes:cmd length:2];
	NSLog(@"CCUSB reset\n");
	return -1;
}

/********************************************************************/
- (void) getStatus
{
	NSLog(@"CCUSB status:\n");
	int reg;
	for(reg= 0;reg<kNumInternalRegs;reg++){
		long value = [self readReg:reg];
		NSLog(@"Reg%d  %@: 0x%08lx\n",reg,ccusbRegs[reg].regName,value);
		if(reg == 1){
			NSLog(@"     BuffOpt=%d\n",   value&7);
			NSLog(@"     EvtSepOpt=%d\n",(value>>6)&1);
			NSLog(@"     HeaderOpt=%d\n",(value>>8)&1);
			NSLog(@"     WdgFrq=%d\n",	 (value>>9)&7);
			NSLog(@"     Arbitr=%d\n",	 (value>>12)&1);
			NSLog(@"\n");
		}
	}
}

/********************************************************************/

-(int) sendNAF:(int)n a:(int) a f:(int) f d24:(BOOL) d24 data:(unsigned long*) data
{
	
	int rd, bcount;
	
	int naf = nafGen(n,a,f);
	
	if(d24) naf |= 0x4000;
	
	unsigned char cmd[16];
	unsigned char buf[16];
	bcount = 6;
	cmd[0] = 12; // address for cnf generator = 8 + 4 (for write op) = 12;
	cmd[1] = 0;
	cmd[2] = 1;  // word count
	cmd[3] = 0;
	cmd[4] = (naf&0x00FF);       // NAF low bits
	cmd[5] = (naf&0xFF00) >> 8;  // NAF high bits
		
	if ((f & 0x18) == 0x10){ // send data for write commands
		bcount = 10;
		//cmd[0] = 12; // address for cnf generator = 8 + 4 (for write op) = 12;
		cmd[2] = 3;
		cmd[6] = (*data&0x00FF);      // write data, low 8 bits
		cmd[7] = (*data&0xFF00) >> 8; // write data, high 8 bits
		cmd[8] = (*data&0xFF0000) >> 16; // write data, next 8 bits
		cmd[9] = (*data&0xFF000000) >> 24; // write data, highest 8 bits
		//cmd[10] = 0;
    }

	[usbInterface writeBytes:cmd length:bcount];
	
	//there is always a result, read it.
	rd = [usbInterface readBytes:buf length:sizeof(buf)];
	int result = 0;
	int i;
	int shift=0;
	for(i=0;i<rd;i++){
		result |= buf[i]<<shift;
		shift += 8;
	}
	BOOL q,x;
	if ((f & 0x18) == 0x10 || f==8 || f==27) { 
		//write returns a single word holding q,x
		q = (result & 1);
		x = (result & 2) >> 1;
		if(q)result |= 0x8; //q bit where ORCA expects it
		if(x)result |= 0x4; //x bit	where ORCA expects it
		*data = 0;          //there is no data for write response
	}
	else {
		q = (result>>24)&0x1;
		x = (result>>25)&0x1;
		*data = (result & 0xffffffff);   //24-bit word 
		result = 0;
		if(q)result |= 0x8; //q bit
		if(x)result |= 0x4; //x bit	
	}

	//x response doesn't work????
	//[self checkStatus:x station:n];

	return result;
}

- (void) checkStatus:(unsigned short)x station:(unsigned short)n
{
		NSLogError(@"CAMAC Exception", [NSString stringWithFormat:@"Station %d",n],@"Bad X Response",nil);
		[NSException raise: @"CAMAC Exception" format:@"CAMAC Exception (station %d)",n];
}

- (void) checkInterface
{
	if(!usbInterface){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CamacPowerFailedNotification" object:self];
		[NSException raise: @"CamacPowerFailedNotification" format:@"Unable to access CAMAC Crate. Check Power and USB Cables."];
    }
    else {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"CamacPowerRestoredNotification" object:self];
    }
}

- (BOOL) writeStackData:(short*)intbuf
{ 

	char buf[2048];

    if (intbuf[0]==0){
		NSLogColor([NSColor redColor], @"USB_CC List Stack is empty.. nothing to do.\n");
		return NO;
	}
	buf[0] = 2+4; //CDS write op
    buf[1] = 0;
	
    int lDataLen=(short)(intbuf[0] & 0xFFF);
    buf[2]=(char)(lDataLen & 0xFF);
    lDataLen = lDataLen >> 8;
    buf[3] = (char)(lDataLen & 0xF);
	int i;
    for (i=1; i <= intbuf[0]; i++){
        buf[2+2*i] = (char)(intbuf[i] & 255);
        buf[3+2*i] = (char)((intbuf[i] >>8) & 255);
	}
	[usbInterface writeBytes:buf length:intbuf[0]*2 + 4];

	short checkBuf[2048];
	int rd = [self readStackData:checkBuf];
	if(rd && (intbuf[0] == checkBuf[0])){
		for(i=0;i<checkBuf[0];i++){
			if(intbuf[i] != checkBuf[i]) {
				NSLogColor([NSColor redColor], @"USB_CC List Stack load failed.. read shows errors.\n");
				NSLogColor([NSColor redColor], @"%d: 0x%x != 0x%x\n",i,intbuf[i],checkBuf[i]);
				return NO;
			}
		}
		NSLog(@"USB_CC List Stack loaded.. read back shows no errors.\n");
	}
	else {
		NSLogColor([NSColor redColor], @"USB_CC List Stack load failed.. read shows wrong stack count.\n");
	}
	return YES;
}

- (int) readStackData:(short*) intbuf
{ 
    char buf[2048];
	
    buf[0] = 2; //CDS address
    buf[1] = 0;
	[usbInterface writeBytes:buf length:2];

	int rd = [usbInterface readBytes:buf length:2048];
	if (rd>0) {
		int ii = 0;
		int i;
		for (i=0; i < rd; i+=2){
			intbuf[ii++] = (((unsigned short)buf[i])&0xff) | (unsigned short)(buf[i+1])<<8;
		}
	}
	return rd/2; //return # words
}


#pragma mark ¥¥¥Test Methods
- (void) test
{
	NSLog(@"USB interface: %@\n",usbInterface?@"valid":@"NOT valid");
	if(!usbInterface){
		NSLogColor([NSColor redColor],@"****** Controller Not Available ******\n");
        NSLogColor([NSColor redColor],@"****** Check Crate Power and Cable ******\n");
		return;
	}
		
    NSLog(@"Execute C Cycle - CC32 Status: 0x%04x\n",[self executeCCycle]);
    NSLog(@"Execute Z Cycle - CC32 Status: 0x%04x\n",[self executeZCycle]);
    NSLog(@"Assert Crate Inhibit - CC32 Status: 0x%04x\n",[self setCrateInhibit:YES]);
    NSLog(@"Deassert Crate Inhibit - CC32 Status: 0x%04x\n",[self setCrateInhibit:NO]);
	
    // generate Q & X
	int statusCC32 = [self camacShortNAF:12 a:0 f:16];
	[self decodeStatus:statusCC32];
    NSLog(@"Generate Q & X, Q:%d, X:%d, I:%d, LAM:%d\n", cmdResponse, cmdAccepted, inhibit, lookAtMe);
    
    NSLog(@"Set LAM Mask - CC32 Status: 0x%08x\n",[self setLAMMask:0x00ffffff]);
        
    unsigned long theMask;
    unsigned int status = [self  readLAMMask:&theMask];
    NSLog(@"LAM Mask: 0x%08x, CC32 Status: 0x%04x\n",theMask,status);
        
    [self getStatus];
    // execute C cycle
    NSLog(@"Execute C Cycle - CC32 Status: 0x%04x\n",[self executeCCycle]);
    NSLog(@"Execute Z Cycle - CC32 Status: 0x%04x\n",[self executeZCycle]);
}

- (void) startList:(BOOL)state
{
	started = state;

	char buf[6];
	buf[0] = 1+4;	//register block 
	buf[1] = 0;
	buf[2] = 0x1;	//length = 1
	buf[3] = 0x0;
	buf[4] = 0x2 | state;	//bit 1 is start/stop
	buf[5] = 0x0;
	
	[usbInterface writeBytes:buf length:6];
}

- (void) executeCustomStack
{
    short theStack[2000];
	NSEnumerator* e = [customStack objectEnumerator];
	id aNumberString;
	short* p = theStack;
	char s[8];
	*p++ = [customStack count];
	while(aNumberString = [e nextObject]){
		[aNumberString getCString:s maxLength:8 encoding:NSASCIIStringEncoding];
		*p++ = (short)strtoul(s,0,16);
	}
	int n = [self executeStack:theStack];
	int i;
	for(i=0;i<n;i++){
		NSLog(@"%d: 0x%04x\n",i,theStack[i]);
	}
}

//execute a stack of commands. 
- (int) executeStack:(short*)intbuf
{
    char buf[2000];
    short i;
    int ii = 0;
         
    if (intbuf[0]==0) return 0;
	
    buf[0]=12; //8 + 4 naf write ops
    buf[1]=0;
    short lDataLen=(short)(intbuf[0] & 0xFFF);
    buf[2]=(char)(lDataLen & 0xFF);
    lDataLen = lDataLen >> 8;
    buf[3] = (char)(lDataLen & 0xF);
    for (i=1; i <= intbuf[0]; i++){
        buf[2+2*i] = (char)(intbuf[i] & 255);
        buf[3+2*i] = (char)((intbuf[i] >>8) & 255);
	}

	[usbInterface writeBytes:buf length:intbuf[0]*2 + 4];
	
	//lDataLen=2000;
	
	int ret = [usbInterface readBytes:buf length:sizeof(buf)];

	if (ret>0) for (i=0; i < ret; i=i+2){
	  intbuf[ii++]=(unsigned char)(buf[i]) + (unsigned char)( buf[i+1])*256;
	}
	
	[self executeCCycle];
	return ret/sizeof(short);
}

- (void) writeInternalRegisters
{
	//write all the CAMAC internal registers
	globalMode |= (1L<<kHeaderOptBit); //header opt == 1 :: the second header word has the number of events in buffer
	globalMode &= ~(1L<<kEvtSepOptBit); //event sep opt == 0 :: only 1 terminator word at end of event
	globalMode |= (1L<<kMixedBuffOptBit); //mixed buffer opt == 1 :: regular and scaler data shares the buffer
	[self writeReg:kGlobalModeReg value:globalMode]; 
	[self writeReg:kDelaysReg value:delays]; 
	[self writeReg:kScalerReadoutControlReg value:scalerReadout]; 
	[self writeReg:kUserLEDSourceReg value:userLEDSelector]; 
	[self writeReg:kNIMOutputReg value:userNIMSelector]; 
	[self writeReg:kSourceSelectorUserDevicesReg value:userDeviceSelector]; 
	[self writeReg:kDelayAndGateGeneratorAReg value:delayAndGateA]; 
	[self writeReg:kDelayAndGateGeneratorBReg value:delayAndGateB]; 
	[self writeReg:kLamMaskReg value:LAMMaskValue]; 
	[self writeReg:kExtendedDelayReg value:delayAndGateExt]; 
	[self writeReg:kusbBufferSetupReg value:usbTransferSetup]; 
}

- (void) addNAFToStack
{
	if(!customStack)[self setCustomStack:[NSMutableArray array]];
	unsigned short theNAFCmd = nafGen(nValue,aValue,fValue);
	if((useDataModifier & 0x1) && (nafModBits & 0x1)){ //continuation bit
		theNAFCmd |= (0x1<<15);
	}
	[customStack addObject:[NSString stringWithFormat:@"0x%04X",theNAFCmd]];
	if(nafModBits & 0x1){ //continuation bit
		if(useDataModifier){
			unsigned short theDataMask = dataModifierBits;
			if(theDataMask & 0x3365){
				//some of the bits require the data will follow, thus we set the continue bit
				theDataMask |=(0x1<<15);
			}
			[customStack addObject:[NSString stringWithFormat:@"0x%04X",theDataMask]];
		}
		else [customStack addObject:[NSString stringWithFormat:@"0x%04X",dataWord]];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelCustomStackChanged object:self];
}
- (void) addDataWordToStack
{
	if(!customStack)[self setCustomStack:[NSMutableArray array]];
	[customStack addObject:[NSString stringWithFormat:@"0x%04X",dataWord]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCCUSBModelCustomStackChanged object:self];
}

- (void) clearStack
{
	[self setCustomStack:nil];
}

@end
