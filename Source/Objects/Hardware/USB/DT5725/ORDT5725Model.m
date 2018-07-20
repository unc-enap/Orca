//
//  ORDT5725Model.m
//  Orca
//
//  Created by Mark Howe on Wed Jun 29,2016.
//  Copyright (c) 2016 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina at the Center sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "ORDT5725Model.h"
#import "ORUSBInterface.h"
#import "ORDataTypeAssigner.h"
#import "ORDataSet.h"
#import "ORRateGroup.h"
#import "ORSafeCircularBuffer.h"


//connector names
NSString* ORDT5725USBInConnection                       = @"ORDT5725USBInConnection";
NSString* ORDT5725USBNextConnection                     = @"ORDT5725USBNextConnection";

//USB Notifications
NSString* ORDT5725ModelUSBInterfaceChanged              = @"ORDT5725ModelUSBInterfaceChanged";
NSString* ORDT5725ModelLock                             = @"ORDT5725ModelLock";
NSString* ORDT5725ModelSerialNumberChanged              = @"ORDT5725ModelSerialNumberChanged";

//Notifications
NSString* ORDT5725ModelInputDynamicRangeChanged         = @"ORDT5725ModelInputDynamicRangeChanged";
NSString* ORDT5725ModelSelfTrigPulseWidthChanged        = @"ORDT5725ModelSelfTrigPulseWidthChanged";
NSString* ORDT5725ThresholdChanged                      = @"ORDT5725ThresholdChanged";
NSString* ORDT5725ModelSelfTrigLogicChanged             = @"ORDT5725ModelSelfTrigLogicChanged";
NSString* ORDT5725ModelSelfTrigPulseTypeChanged         = @"ORDT5725ModelSelfTrigPulseTypeChanged";
NSString* ORDT5725ModelDCOffsetChanged                  = @"ORDT5725ModelDCOffsetChanged";
NSString* ORDT5725ModelTrigOnUnderThresholdChanged      = @"ORDT5725ModelTrigOnUnderThresholdChanged";
NSString* ORDT5725ModelTestPatternEnabledChanged        = @"ORDT5725ModelTestPatternEnabledChanged";
NSString* ORDT5725ModelTrigOverlapEnabledChanged        = @"ORDT5725ModelTrigOverlapEnabledChanged";
NSString* ORDT5725ModelEventSizeChanged                 = @"ORDT5725ModelEventSizeChanged";
NSString* ORDT5725ModelClockSourceChanged               = @"ORDT5725ModelClockSourceChanged";
NSString* ORDT5725ModelCountAllTriggersChanged          = @"ORDT5725ModelCountAllTriggersChanged";
NSString* ORDT5725ModelStartStopRunModeChanged          = @"ORDT5725ModelStartStopRunModeChanged";
NSString* ORDT5725ModelMemFullModeChanged               = @"ORDT5725ModelMemFullModeChanged";
NSString* ORDT5725ModelSoftwareTrigEnabledChanged       = @"ORDT5725ModelSoftwareTrigEnabledChanged";
NSString* ORDT5725ModelExternalTrigEnabledChanged       = @"ORDT5725ModelExternalTrigEnabledChanged";
NSString* ORDT5725ModelCoincidenceWindowChanged         = @"ORDT5725ModelCoincidenceWindowChanged";
NSString* ORDT5725ModelCoincidenceLevelChanged          = @"ORDT5725ModelCoincidenceLevelChanged";
NSString* ORDT5725ModelTriggerSourceMaskChanged         = @"ORDT5725ModelTriggerSourceMaskChanged";
NSString* ORDT5725ModelSwTrigOutEnabledChanged          = @"ORDT5725ModelSwTrigOutEnabledChanged";
NSString* ORDT5725ModelExtTrigOutEnabledChanged         = @"ORDT5725ModelExtTrigOutEnabledChanged";
NSString* ORDT5725ModelTriggerOutMaskChanged            = @"ORDT5725ModelTriggerOutMaskChanged";
NSString* ORDT5725ModelTriggerOutLogicChanged           = @"ORDT5725ModelTriggerOutLogicChanged";
NSString* ORDT5725ModelTrigOutCoincidenceLevelChanged   = @"ORDT5725ModelTrigOutCoincidenceLevelChanged";
NSString* ORDT5725ModelPostTriggerSettingChanged        = @"ORDT5725ModelPostTriggerSettingChanged";
NSString* ORDT5725ModelFpLogicTypeChanged               = @"ORDT5725ModelFpLogicTypeChanged";
NSString* ORDT5725ModelFpTrigInSigEdgeDisableChanged    = @"ORDT5725ModelFpTrigInSigEdgeDisableChanged";
NSString* ORDT5725ModelFpTrigInToMezzaninesChanged      = @"ORDT5725ModelFpTrigInToMezzaninesChanged";
NSString* ORDT5725ModelFpForceTrigOutChanged            = @"ORDT5725ModelFpForceTrigOutChanged";
NSString* ORDT5725ModelFpTrigOutModeChanged             = @"ORDT5725ModelTrigOutModeChanged";
NSString* ORDT5725ModelFpTrigOutModeSelectChanged       = @"ORDT5725ModelTrigOutModeSelectChanged";
NSString* ORDT5725ModelFpMBProbeSelectChanged           = @"ORDT5725ModelFpMBProbeSelectChanged";
NSString* ORDT5725ModelFpBusyUnlockSelectChanged        = @"ORDT5725ModelFpBusyUnlockSelectChanged";
NSString* ORDT5725ModelFpHeaderPatternChanged           = @"ORDT5725ModelFpHeaderPatternChanged";
NSString* ORDT5725ModelEnabledMaskChanged               = @"ORDT5725ModelEnabledMaskChanged";
NSString* ORDT5725ModelFanSpeedModeChanged              = @"ORDT5725ModelFanSpeedModeChanged";
NSString* ORDT5725ModelAlmostFullLevelChanged           = @"ORDT5725ModelAlmostFullLevelChanged";
NSString* ORDT5725ModelRunDelayChanged                  = @"ORDT5725ModelRunDelayChanged";

NSString* ORDT5725Chnl                                  = @"ORDT5725Chnl";
NSString* ORDT5725SelectedRegIndexChanged               = @"ORDT5725SelectedRegIndexChanged";
NSString* ORDT5725SelectedChannelChanged                = @"ORDT5725SelectedChannelChanged";
NSString* ORDT5725WriteValueChanged                     = @"ORDT5725WriteValueChanged";

NSString* ORDT5725BasicLock                             = @"ORDT5725BasicLock";
NSString* ORDT5725LowLevelLock                          = @"ORDT5725LowLevelLock";
NSString* ORDT5725RateGroupChanged                      = @"ORDT5725RateGroupChanged";
NSString* ORDT5725ModelBufferCheckChanged               = @"ORDT5725ModelBufferCheckChanged";



static DT5725RegisterNamesStruct reg[kNumberDT5725Registers] = {
//  {regName            addressOffset, accessType, hwReset, softwareReset, clr},
    {@"Dynamic Ranges",         0x1028,	kReadWrite, true,	true, 	false},
    {@"Trigger Pulse Width",    0x1070, kReadWrite, true,   true,   false},
    {@"Thresholds",             0x1080,	kReadWrite, true,	true, 	false},
    {@"Self-Trigger Logic",     0x1084,	kReadWrite, true,	true, 	false},
    {@"Status",                 0x1088,	kReadOnly,  true,	true, 	false},
    {@"AMC Revision",           0x108C,	kReadOnly,  false,	false, 	false},
    {@"Buffer Occupancy",       0x1094, kReadOnly,  true,   true,   true},
    {@"DC Offset",              0x1098,	kReadWrite, true,	true, 	false},
    {@"Adc Temp",               0x10A8,	kReadOnly,  true,	true, 	false},
    {@"Board Config",           0x8000,	kReadWrite, true,	true, 	false},
    {@"Board Config Bit Set",   0x8004,	kWriteOnly, true,	true, 	false},
    {@"Board Config Bit Clr",   0x8008, kWriteOnly, true,	true, 	false},
    {@"Buffer Organization",    0x800C,	kReadWrite, true,	true, 	false},
    {@"Custom Size",            0x8020,	kReadWrite, true,	true, 	false},
    {@"Adc Calibration",        0x809C,	kWriteOnly, true,	true, 	false},
    {@"Acq Control",            0x8100,	kReadWrite, true,	true, 	false},
    {@"Acq Status",             0x8104,	kReadOnly,  false,	false, 	false},
    {@"Software Trigger",       0x8108, kWriteOnly, true,   true,   false},
    {@"Trig Src Enbl Mask",     0x810C,	kReadWrite, true,	true, 	false},
    {@"FP Trig Out Enbl Mask",  0x8110, kReadWrite, true,   true, 	false},
    {@"Post Trig Setting",      0x8114,	kReadWrite, true,	true, 	false},
    {@"FP I/O Control",         0x811C,	kReadWrite, true,	true, 	false},
    {@"Chan Enable Mask",       0x8120,	kReadWrite, true,	true, 	false},
    {@"ROC FPGA Version",       0x8124,	kReadOnly,  false,	false, 	false},
    {@"Event Stored",           0x812C,	kReadOnly,  true,	true, 	true},
    {@"Board Info",             0x8140,	kReadOnly,  false,	false, 	false},
    {@"Event Size",             0x814C,	kReadOnly,  true,	true, 	true},
    {@"Fan Speed Control",      0x8168,	kReadWrite, true,	true, 	false},
    {@"Buffer Almost Full",     0x816C,	kReadWrite, true,	true, 	false},
    {@"Run Delay",              0x8170, kReadWrite, true,   true,   false},
    {@"Board Failure",          0x8178,	kReadOnly,  true,	true, 	false},
    {@"Readout Status",         0xEF04,	kReadOnly,  true,	true, 	false},
    {@"BLT Event Num",          0xEF1C,	kReadWrite, true,	true, 	false},
    {@"Scratch",                0xEF20,	kReadWrite, true,	true, 	false},
    {@"SW Reset",               0xEF24,	kWriteOnly, false,	false, 	false},
    {@"SW Clear",               0xEF28,	kWriteOnly, false,	false, 	false},
    {@"ConfigReload",           0xEF34,	kWriteOnly, false,	false, 	false},
    {@"Config ROM Ver",         0xF030,	kReadOnly,  false,	false, 	false},
    {@"Config ROM Board2",      0xF034,	kReadOnly,  false,	false, 	false}
};


static NSString* DT5725StartStopRunModeString[4] = {
    @"Register Controlled",
    @"GPI Controlled",
    @"First Trigger Controlled"
};

#define FBLT        0x0C    // Ver. 2.3
#define FPBLT       0x0F    // Ver. 2.3

@interface ORDT5725Model (private)
- (void) dataWorker:(NSDictionary*)arg;
@end


@implementation ORDT5725Model

@synthesize isDataWorkerRunning,isTimeToStopDataWorker;

- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self setEnabledMask:0xFF];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) makeConnectors
{
	ORConnector* connectorObj1 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( 0, [self frame].size.height/2- kConnectorSize/2 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj1 forKey: ORDT5725USBInConnection ];
	[ connectorObj1 setConnectorType: 'USBI' ];
	[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to gpib outputs
	[connectorObj1 setOffColor:[NSColor yellowColor]];
	[ connectorObj1 release ];
	
	ORConnector* connectorObj2 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, [self frame].size.height/2- kConnectorSize/2)
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj2 forKey: ORDT5725USBNextConnection ];
	[ connectorObj2 setConnectorType: 'USBO' ];
	[ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to gpib inputs
	[connectorObj2 setOffColor:[NSColor yellowColor]];
	[ connectorObj2 release ];
}

- (void) makeMainController
{
    [self linkToController:@"ORDT5725Controller"];
}

- (NSString*) helpURL
{
	return @"USB/DT5725.html";
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [usbInterface release];
    [waveFormRateGroup release];
    [serialNumber release];
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [bufferFullAlarm clearAlarm];
    [bufferFullAlarm release];
    [lastTimeByteTotalChecked release];
    [circularBuffer release];
    [serialNumber release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		[self connectionChanged];
	}
	@catch(NSException* localException) {
	}
	
}

- (void) connectionChanged
{
	NSArray* interfaces = [[self getUSBController] interfacesForVender:[self vendorID] product:[self productID]];
	NSString* sn = serialNumber;
	if([interfaces count] == 1 && ![sn length]){
		sn = [[interfaces objectAtIndex:0] serialNumber];
	}
	[self setSerialNumber:sn]; //to force usbinterface at doc startup
	[self checkUSBAlarm];
	[[self objectConnectedTo:ORDT5725USBNextConnection] connectionChanged];
}

-(void) setUpImage
{
	
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
	NSImage* aCachedImage = [NSImage imageNamed:@"DT5725"];
    if(!usbInterface || ![self getUSBController]){
		NSSize theIconSize = [aCachedImage size];
		
		NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
		[i lockFocus];
		
        [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];		
		NSBezierPath* path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(15,8)];
		[path lineToPoint:NSMakePoint(30,28)];
		[path moveToPoint:NSMakePoint(15,28)];
		[path lineToPoint:NSMakePoint(30,8)];
		[path setLineWidth:3];
		[[NSColor yellowColor] set];
		[path stroke];
		
		[i unlockFocus];
		
		[self setImage:i];
		[i release];
    }
	else {
		[ self setImage: aCachedImage];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
	
}

- (NSString*) title 
{
	return [NSString stringWithFormat:@"DT5725 (Serial# %@)",[usbInterface serialNumber]];
}

- (NSUInteger) vendorID
{
	return 0x21E1UL; //DT5725
}

- (NSUInteger) productID
{
	return 0x0000UL; //DT5725
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORDT5725USBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

#pragma mark ***USB
- (ORUSBInterface*) usbInterface
{
	return usbInterface;
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
	[self checkUSBAlarm];
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface
{	
	if(anInterface != usbInterface){
		[usbInterface release];
		usbInterface = anInterface;
		[usbInterface retain];
		[usbInterface setUsePipeType:kUSBInterrupt];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: ORDT5725ModelUSBInterfaceChanged object: self];

		[self checkUSBAlarm];
	}
}

- (void)checkUSBAlarm
{
	if((usbInterface && [self getUSBController]) || !guardian){
		[noUSBAlarm clearAlarm];
		[noUSBAlarm release];
		noUSBAlarm = nil;
	}
	else {
		if(guardian){
			if(!noUSBAlarm){
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for DT5725"] severity:kHardwareAlarm];
				[noUSBAlarm setSticky:YES];		
			}
			[noUSBAlarm setAcknowledged:NO];
			[noUSBAlarm postAlarm];
		}
	}
    
	[self setUpImage];
	
}

- (float) totalByteRate
{
    return totalByteRate;
}
    
- (void) interfaceAdded:(NSNotification*)aNote
{
	[[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
	ORUSBInterface* theInterfaceRemoved = [[aNote userInfo] objectForKey:@"USBInterface"];
	if((usbInterface == theInterfaceRemoved) && serialNumber){
		[self setUsbInterface:nil];
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

- (NSString*) hwName
{
	if(usbInterface)return [usbInterface deviceName];
	else return @"?";
}

- (void) makeUSBClaim:(NSString*)aSerialNumber
{	
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
	else {
		[[self getUSBController] claimInterfaceWithSerialNumber:serialNumber for:self];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelSerialNumberChanged object:self];
	[self checkUSBAlarm];
}

#pragma mark Accessors
//------------------------------
//Reg Channel n Input Dynamic Range (0x1n28)
- (unsigned short) inputDynamicRange:(unsigned short) i
{
    if(i<kNumDT5725Channels)return inputDynamicRange[i];
    else return 0;
}

- (void) setInputDynamicRange:(unsigned short) i withValue:(unsigned short) aValue
{
    if(i<kNumDT5725Channels && aValue!=inputDynamicRange[i]){
        [[[self undoManager] prepareWithInvocationTarget:self] setInputDynamicRange:i withValue:[self inputDynamicRange:i]];

        inputDynamicRange[i] = aValue;

        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5725Chnl];

        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelInputDynamicRangeChanged 
                                                            object:self
                                                          userInfo:userInfo];
    }
}
//------------------------------
//Reg Channel n Trigger Pulse Width (0x1n70)
- (unsigned short) selfTrigPulseWidth:(unsigned short) i
{
    if(i<kNumDT5725Channels)return selfTrigPulseWidth[i];
    else return 0;
}

- (void) setSelfTrigPulseWidth:(unsigned short) i withValue:(unsigned short) aValue;
{
    if(i<kNumDT5725Channels && aValue!=selfTrigPulseWidth[i]){
        [[[self undoManager] prepareWithInvocationTarget:self] setSelfTrigPulseWidth:i withValue:[self selfTrigPulseWidth:i]];

        selfTrigPulseWidth[i] = aValue;

        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5725Chnl];

        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelSelfTrigPulseWidthChanged
                                                             object:self
                                                          userInfo:userInfo];
    }
}
//------------------------------
//Reg Channel n Threshold (0x1n80)
- (unsigned short) threshold:(unsigned short) i
{
    if(i<kNumDT5725Channels)return thresholds[i];
    else return 0;
}

- (void) setThreshold:(unsigned short) i withValue:(unsigned short) aValue
{
    if(i<kNumDT5725Channels && aValue!=thresholds[i]){
        [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:i withValue:[self threshold:i]];
    
        thresholds[i] = aValue;
    
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5725Chnl];
    
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ThresholdChanged
                                                            object:self
                                                          userInfo:userInfo];
    }
}
//------------------------------
//Reg Self-trigger Logic (0x1n84) 
//  because the channels are paired this only accepts the values 0, 2, 4, 6 (unlike the normal 0-8)
- (unsigned short) selfTrigLogic:(unsigned short) i
{
    if(i<kNumDT5725Channels/2)return selfTrigLogic[i];
    else return 0;
}

- (void) setSelfTrigLogic:(unsigned short) i withValue:(unsigned short) aValue
{
    if(aValue > 0x3)aValue = 0x3;
    if(i<kNumDT5725Channels/2 && aValue!=selfTrigLogic[i]){
        [[[self undoManager] prepareWithInvocationTarget:self] setSelfTrigLogic:i withValue:[self selfTrigLogic:i]];

        selfTrigLogic[i] = aValue;

        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5725Chnl];

        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelSelfTrigLogicChanged
                                                            object:self
                                                          userInfo:userInfo];
    }
}

- (unsigned short) selfTrigPulseType:(unsigned short) i
{
    if(i<kNumDT5725Channels)return selfTrigPulseType[i];
    else return 0;
}

- (void) setSelfTrigPulseType:(unsigned short) i withValue:(unsigned short) aValue
{
    if(i<kNumDT5725Channels && aValue!=selfTrigPulseType[i]){
        [[[self undoManager] prepareWithInvocationTarget:self] setSelfTrigPulseType:i withValue:[self selfTrigPulseType:i]];

        selfTrigPulseType[i] = aValue;

        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5725Chnl];

        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelSelfTrigPulseTypeChanged
                                                            object:self
                                                          userInfo:userInfo];
    }
}
//------------------------------
//Reg Channel n DC Offset (0x1n98)
- (unsigned short) dcOffset:(unsigned short) i
{
    if(i<kNumDT5725Channels)return dcOffset[i];
    else return 0;
}

- (void) setDCOffset:(unsigned short) i withValue:(unsigned short) aValue
{
    if(i<kNumDT5725Channels && aValue!=dcOffset[i]){
        [[[self undoManager] prepareWithInvocationTarget:self] setDCOffset:i withValue:[self dcOffset:i]];

        dcOffset[i] = aValue;

        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5725Chnl];

        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelDCOffsetChanged
                                                            object:self
                                                          userInfo:userInfo];
    }
}
//------------------------------
//Reg Channel Configuration (0x8000)
- (BOOL) trigOnUnderThreshold
{
    return trigOnUnderThreshold;
}

- (void) setTrigOnUnderThreshold:(BOOL)aTrigOnUnderThreshold
{
    if(aTrigOnUnderThreshold!=trigOnUnderThreshold){
        [[[self undoManager] prepareWithInvocationTarget:self] setTrigOnUnderThreshold:trigOnUnderThreshold];
        trigOnUnderThreshold = aTrigOnUnderThreshold;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelTrigOnUnderThresholdChanged object:self];
    }
}

- (BOOL) testPatternEnabled
{
    return testPatternEnabled;
}

- (void) setTestPatternEnabled:(BOOL)aTestPatternEnabled
{
    if(aTestPatternEnabled!=testPatternEnabled){
        [[[self undoManager] prepareWithInvocationTarget:self] setTestPatternEnabled:testPatternEnabled];
        testPatternEnabled = aTestPatternEnabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelTestPatternEnabledChanged object:self];
    }
}

- (BOOL) trigOverlapEnabled
{
    return trigOverlapEnabled;
}

- (void) setTrigOverlapEnabled:(BOOL)aTrigOverlapEnabled
{
    if(aTrigOverlapEnabled!=trigOverlapEnabled){
        [[[self undoManager] prepareWithInvocationTarget:self] setTrigOverlapEnabled:trigOverlapEnabled];
        trigOverlapEnabled = aTrigOverlapEnabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelTrigOverlapEnabledChanged object:self];
    }
}

//------------------------------
//Reg Custom Size (0x8020)
- (uint32_t) eventSize
{
    return eventSize;
}

- (void) setEventSize:(uint32_t)aEventSize
{
    //customSize < bufferOrganization
    if(aEventSize!=eventSize){
        [[[self undoManager] prepareWithInvocationTarget:self] setEventSize:eventSize];
        eventSize = aEventSize;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelEventSizeChanged object:self];
    }
}
//------------------------------
//Reg Acquistion Control (0x8100)
- (BOOL) clockSource
{
    return clockSource;
}

- (void) setClockSource:(BOOL)aClockSource
{
    if(aClockSource!=clockSource){
        [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
        clockSource = aClockSource;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelClockSourceChanged object:self];
    }
}
- (BOOL) countAllTriggers
{
    return countAllTriggers;
}

- (void) setCountAllTriggers:(BOOL)aCountAllTriggers
{
    if(aCountAllTriggers!=countAllTriggers){
        [[[self undoManager] prepareWithInvocationTarget:self] setCountAllTriggers:countAllTriggers];
        countAllTriggers = aCountAllTriggers;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelCountAllTriggersChanged object:self];
    }
}

- (unsigned short) startStopRunMode
{
    return startStopRunMode;
}

- (void) setStartStopRunMode:(BOOL) aStartStopRunMode;
{
    if(aStartStopRunMode!=startStopRunMode){
        [[[self undoManager] prepareWithInvocationTarget:self] setStartStopRunMode:startStopRunMode];
        startStopRunMode = aStartStopRunMode;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelStartStopRunModeChanged object:self];
    }
}

- (BOOL) memFullMode
{
    return memFullMode;
}

- (void) setMemFullMode:(BOOL) aMemFullMode;
{
    if(aMemFullMode!=memFullMode){
        [[[self undoManager] prepareWithInvocationTarget:self] setMemFullMode:memFullMode];
        memFullMode = aMemFullMode;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelMemFullModeChanged object:self];
    }
}

//------------------------------
//Reg Trigger Source Enable Mask (0x810C)
- (BOOL) softwareTrigEnabled
{
    return softwareTrigEnabled;
}

- (void) setSoftwareTrigEnabled:(BOOL)aSoftwareTrigEnabled
{
    if(aSoftwareTrigEnabled!=softwareTrigEnabled){
        [[[self undoManager] prepareWithInvocationTarget:self] setSoftwareTrigEnabled:softwareTrigEnabled];
        softwareTrigEnabled = aSoftwareTrigEnabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelSoftwareTrigEnabledChanged object:self];
    }
}

- (BOOL) externalTrigEnabled
{
    return externalTrigEnabled;
}

- (void) setExternalTrigEnabled:(BOOL)aExternalTrigEnabled
{
    if(aExternalTrigEnabled!=externalTrigEnabled){
        [[[self undoManager] prepareWithInvocationTarget:self] setExternalTrigEnabled:externalTrigEnabled];
        externalTrigEnabled = aExternalTrigEnabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelExternalTrigEnabledChanged object:self];
    }
}

- (unsigned short) coincidenceWindow
{
    return coincidenceWindow;
}

- (void) setCoincidenceWindow:(unsigned short)aCoincidenceWindow
{
    if(aCoincidenceWindow!=coincidenceWindow){
        [[[self undoManager] prepareWithInvocationTarget:self] setCoincidenceWindow:coincidenceWindow];
        coincidenceWindow = aCoincidenceWindow;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelCoincidenceWindowChanged object:self];
    }
}

- (unsigned short) coincidenceLevel
{
    return coincidenceLevel;
}

- (void) setCoincidenceLevel:(unsigned short)aCoincidenceLevel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCoincidenceLevel:coincidenceLevel];
    coincidenceLevel = aCoincidenceLevel;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelCoincidenceLevelChanged object:self];
}
- (uint32_t) triggerSourceMask
{
    return triggerSourceMask;
}

 - (void) setTriggerSourceMask:(uint32_t)aTriggerSourceMask
{
    if(aTriggerSourceMask>0xf)aTriggerSourceMask = 0xf;
    if(aTriggerSourceMask!=triggerSourceMask){
        [[[self undoManager] prepareWithInvocationTarget:self] setTriggerSourceMask:triggerSourceMask];
        triggerSourceMask = aTriggerSourceMask;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelTriggerSourceMaskChanged object:self];
    }
}

//------------------------------
//Reg Front Panel Trigger Out Enable Mask (0x8110)
- (BOOL) swTrigOutEnabled
{
    return swTrigOutEnabled;
}

- (void) setSwTrigOutEnabled:(BOOL)aSwTrigOutEnabled
{
    if(aSwTrigOutEnabled!=swTrigOutEnabled){
        [[[self undoManager] prepareWithInvocationTarget:self] setSwTrigOutEnabled:swTrigOutEnabled];
        swTrigOutEnabled = aSwTrigOutEnabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelSwTrigOutEnabledChanged object:self];
    }
}

- (BOOL) extTrigOutEnabled
{
    return extTrigOutEnabled;
}

- (void) setExtTrigOutEnabled:(BOOL)aExtTrigOutEnabled
{
    if(aExtTrigOutEnabled!=extTrigOutEnabled){
        [[[self undoManager] prepareWithInvocationTarget:self] setExtTrigOutEnabled:extTrigOutEnabled];
        extTrigOutEnabled = aExtTrigOutEnabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelExtTrigOutEnabledChanged object:self];
    }
}

- (uint32_t) triggerOutMask
{
    return triggerOutMask;
}

- (void) setTriggerOutMask:(uint32_t)aTriggerOutMask
{
    if(aTriggerOutMask>0x4)aTriggerOutMask = 0xf;
    if(aTriggerOutMask!=triggerOutMask){
        [[[self undoManager] prepareWithInvocationTarget:self] setTriggerOutMask:triggerOutMask];
        triggerOutMask = aTriggerOutMask;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelTriggerOutMaskChanged object:self];
    }
}

- (unsigned short) triggerOutLogic;
{
    return triggerOutLogic;
}

- (void) setTriggerOutLogic:(unsigned short)aTriggerOutLogic
{
    if(aTriggerOutLogic!=triggerOutLogic){
        [[[self undoManager] prepareWithInvocationTarget:self] setTriggerOutLogic:triggerOutLogic];
        triggerOutLogic = aTriggerOutLogic;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelTriggerOutLogicChanged object:self];
    }
}

- (unsigned short) trigOutCoincidenceLevel
{
    return trigOutCoincidenceLevel;
}

- (void) setTrigOutCoincidenceLevel:(unsigned short)aTrigOutCoincidenceLevel
{
    if(aTrigOutCoincidenceLevel!=trigOutCoincidenceLevel){
        [[[self undoManager] prepareWithInvocationTarget:self] setTrigOutCoincidenceLevel:trigOutCoincidenceLevel];
        trigOutCoincidenceLevel = aTrigOutCoincidenceLevel;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelTrigOutCoincidenceLevelChanged object:self];
    }
}

//------------------------------
//Reg Post Trigger Setting (0x8114)
- (uint32_t) postTriggerSetting
{
    return postTriggerSetting;
}

- (void) setPostTriggerSetting:(uint32_t)aPostTriggerSetting
{
    if(aPostTriggerSetting!=postTriggerSetting){
        [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerSetting:postTriggerSetting];
        postTriggerSetting = aPostTriggerSetting;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelPostTriggerSettingChanged object:self];
    }
}
//------------------------------
//Reg Front Panel I/O Setting (0x811C)
- (BOOL) fpLogicType
{
    return fpLogicType;
}

- (void) setFpLogicType:(BOOL)aFpLogicType
{
    if(aFpLogicType!=fpLogicType){
        [[[self undoManager] prepareWithInvocationTarget:self] setFpLogicType:fpLogicType];
        fpLogicType = aFpLogicType;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelFpLogicTypeChanged object:self];
    }
}

- (BOOL) fpTrigInSigEdgeDisable
{
    return fpTrigInSigEdgeDisable;
}

- (void) setFpTrigInSigEdgeDisable:(BOOL)aFpTrigInSigEdgeDisable
{
    if(aFpTrigInSigEdgeDisable!=fpTrigInSigEdgeDisable){
        [[[self undoManager] prepareWithInvocationTarget:self] setFpTrigInSigEdgeDisable:fpTrigInSigEdgeDisable];
        fpTrigInSigEdgeDisable = aFpTrigInSigEdgeDisable;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelFpTrigInSigEdgeDisableChanged object:self];
    }
}

- (BOOL) fpTrigInToMezzanines
{
    return fpTrigInToMezzanines;
}

- (void) setFpTrigInToMezzanines:(BOOL)aFpTrigInToMezzanines
{
    if(aFpTrigInToMezzanines!=fpTrigInToMezzanines){
        [[[self undoManager] prepareWithInvocationTarget:self] setFpTrigInToMezzanines:fpTrigInToMezzanines];
        fpTrigInToMezzanines = aFpTrigInToMezzanines;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelFpTrigInToMezzaninesChanged object:self];
    }
}

- (BOOL) fpForceTrigOut
{
    return fpForceTrigOut;
}

- (void) setFpForceTrigOut:(BOOL)aFpForceTrigOut
{
    if(aFpForceTrigOut!=fpForceTrigOut){
        [[[self undoManager] prepareWithInvocationTarget:self] setFpForceTrigOut:fpForceTrigOut];
        fpForceTrigOut = aFpForceTrigOut;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelFpForceTrigOutChanged object:self];
    }
}

- (BOOL) fpTrigOutMode
{
    return fpTrigOutMode;
}

- (void) setFpTrigOutMode:(BOOL)aFpTrigOutMode
{
    if(aFpTrigOutMode!=fpTrigOutMode){
        [[[self undoManager] prepareWithInvocationTarget:self] setFpTrigOutMode:fpTrigOutMode];
        fpTrigOutMode = aFpTrigOutMode;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelFpTrigOutModeChanged object:self];
    }
}

- (unsigned short) fpTrigOutModeSelect
{
    return fpTrigOutModeSelect;
}

- (void) setFpTrigOutModeSelect:(unsigned short)aFpTrigOutModeSelect
{
    if(aFpTrigOutModeSelect!=fpTrigOutModeSelect){
        [[[self undoManager] prepareWithInvocationTarget:self] setFpTrigOutModeSelect:fpTrigOutModeSelect];
        fpTrigOutModeSelect = aFpTrigOutModeSelect;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelFpTrigOutModeSelectChanged object:self];
    }
}

- (unsigned short) fpMBProbeSelect
{
    return fpMBProbeSelect;
}

- (void) setFpMBProbeSelect:(unsigned short)aFpMBProbeSelect
{
    if(aFpMBProbeSelect!=fpMBProbeSelect){
        [[[self undoManager] prepareWithInvocationTarget:self] setFpMBProbeSelect:fpMBProbeSelect];
        fpMBProbeSelect = aFpMBProbeSelect;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelFpMBProbeSelectChanged object:self];
    }
}

- (BOOL) fpBusyUnlockSelect
{
    return fpBusyUnlockSelect;
}

- (void) setFpBusyUnlockSelect:(BOOL)aFpBusyUnlockSelect
{
    if(aFpBusyUnlockSelect!=fpBusyUnlockSelect){
        [[[self undoManager] prepareWithInvocationTarget:self] setFpBusyUnlockSelect:fpBusyUnlockSelect];
        fpBusyUnlockSelect = aFpBusyUnlockSelect;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelFpBusyUnlockSelectChanged object:self];
    }
}

- (unsigned short) fpHeaderPattern
{
    return fpHeaderPattern;
}

- (void) setFpHeaderPattern:(unsigned short)aFpHeaderPattern
{
    if(aFpHeaderPattern!=fpHeaderPattern){
        [[[self undoManager] prepareWithInvocationTarget:self] setFpHeaderPattern:fpHeaderPattern];
        fpHeaderPattern = aFpHeaderPattern;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelFpHeaderPatternChanged object:self];
    }
}

//------------------------------
//Reg Channel Enable Mask (0x8120)
- (unsigned short) enabledMask
{
    return enabledMask;
}

- (void) setEnabledMask:(unsigned short)aEnabledMask
{
    aEnabledMask &= 0xff;
    if(aEnabledMask!=enabledMask){
        [[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
        enabledMask = aEnabledMask;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelEnabledMaskChanged object:self];
    }
}

//------------------------------
//Reg Fan Speed Mode (0x8168)
-(BOOL) fanSpeedMode
{
    return fanSpeedMode;
}

- (void) setFanSpeedMode:(BOOL)aFanSpeedMode
{
    if(aFanSpeedMode!=fanSpeedMode){
        [[[self undoManager] prepareWithInvocationTarget:self] setFanSpeedMode:fanSpeedMode];
        fanSpeedMode = aFanSpeedMode;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelFanSpeedModeChanged object:self];
    }
}
//------------------------------
//Reg Buffer Almost Full Level (0x816C)
- (unsigned short) almostFullLevel
{
    return almostFullLevel;
}

- (void) setAlmostFullLevel:(unsigned short)anAlmostFullLevel
{
    if(anAlmostFullLevel!=almostFullLevel){
        [[[self undoManager] prepareWithInvocationTarget:self] setAlmostFullLevel:almostFullLevel];
        almostFullLevel = anAlmostFullLevel;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelAlmostFullLevelChanged object:self];
    }
}
//------------------------------
//Reg Run Start/Stop Delay (0x8170)
- (uint32_t) runDelay
{
    return runDelay;
}

- (void) setRunDelay:(uint32_t)aRunDelay
{
    if(aRunDelay!=runDelay){
        [[[self undoManager] prepareWithInvocationTarget:self] setRunDelay:runDelay];
        runDelay = aRunDelay;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelRunDelayChanged object:self];
    }
}

//------------------------------
- (int)	bufferState
{
	return bufferState;
}

- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumDT5725Channels){
			return waveFormCount[counterTag];
		}
		else return 0;
	}
	else return 0;
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
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
	 postNotificationName:ORDT5725RateGroupChanged
	 object:self];
}

- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}

- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    if(anIndex!=selectedRegIndex){
        [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:[self selectedRegIndex]];
        selectedRegIndex = anIndex;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725SelectedRegIndexChanged object:self];
    }
}

- (unsigned short) selectedChannel
{
    return selectedChannel;
}

- (void) setSelectedChannel:(unsigned short) anIndex
{
    if(anIndex!=selectedChannel){
        [[[self undoManager] prepareWithInvocationTarget:self]setSelectedChannel:[self selectedChannel]];
        selectedChannel = anIndex;
        [[NSNotificationCenter defaultCenter]postNotificationName:ORDT5725SelectedChannelChanged object:self];
    }
}

- (uint32_t) selectedRegValue
{
    return selectedRegValue;
}

- (void) setSelectedRegValue:(uint32_t) aValue
{
    if(aValue!=selectedRegValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegValue:[self selectedRegValue]];
        selectedRegValue = aValue;
        [[NSNotificationCenter defaultCenter]postNotificationName:ORDT5725WriteValueChanged object:self];
    }
}

#pragma mark ***Register - General routines
- (short) getNumberRegisters
{
    return kNumberDT5725Registers;
}

#pragma mark ***Register - Register specific routines
- (NSString*) getRegisterName:(short) anIndex       {return reg[anIndex].regName;}
- (uint32_t) getAddressOffset:(short) anIndex  {return reg[anIndex].addressOffset;}
- (short) getAccessType:(short) anIndex             {return reg[anIndex].accessType;}
- (BOOL) dataReset:(short) anIndex                  {return reg[anIndex].dataReset;}
- (BOOL) swReset:(short) anIndex                    {return reg[anIndex].softwareReset;}
- (BOOL) hwReset:(short) anIndex                    {return reg[anIndex].hwReset;}

- (void) readChan:(unsigned short)chan reg:(unsigned short) pReg returnValue:(uint32_t*) pValue
{
    if (pReg >= [self getNumberRegisters]) {
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    if([self getAccessType:pReg] != kReadOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (read not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    [self  readLongBlock:pValue
               atAddress:[self getAddressOffset:pReg] + chan*0x100];
}

- (void) writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(uint32_t) pValue
{
	uint32_t theValue = pValue;
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
		[self writeLongBlock:&theValue
							 atAddress:[self getAddressOffset:pReg] + chan*0x100];
	}
	@catch(NSException* localException) {
	}
}


- (void) read
{
	short		start;
    short		end;
    short		i;
    uint32_t 	theValue = 0;
    short theChannelIndex	 = [self selectedChannel];
    short theRegIndex		 = [self selectedRegIndex];
    
    @try {
        if (theRegIndex >= kInputDyRange && theRegIndex<=kAdcTemp){
            start = theChannelIndex;
            end = theChannelIndex;
            if(theChannelIndex >= kNumDT5725Channels) {
                start = 0;
                end = kNumDT5725Channels - 1;
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


- (void) write
{
    short	start;
    short	end;
    short	i;
	
    int32_t theValue			= [self selectedRegValue];
    short theChannelIndex	= [self selectedChannel];
    short theRegIndex 		= [self selectedRegIndex];
    
    @try {
        
        NSLog(@"Register is:%@\n", [self getRegisterName:theRegIndex]);
        NSLog(@"Value is   :0x%04x\n", theValue);
        
        if (theRegIndex >= kInputDyRange && theRegIndex<=kAdcTemp){
            start	= theChannelIndex;
            end 	= theChannelIndex;
            if(theChannelIndex >= kNumDT5725Channels){
				NSLog(@"Channel: ALL\n");
                start = 0;
                end = kNumDT5725Channels - 1;
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


- (void) read:(unsigned short) pReg returnValue:(uint32_t*) pValue
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
    [self readLongBlock:pValue
                        atAddress:[self getAddressOffset:pReg]];
    
}

- (void) write:(unsigned short) pReg sendValue:(uint32_t) pValue
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
		[self writeLongBlock:&pValue
                   atAddress:[self getAddressOffset:pReg]];
		
	}
	@catch(NSException* localException) {
	}
}

- (void) report
{
	uint32_t enabled, threshold, dynRange, pulseWidth, status, dacOffset, adcTemp, triggerSrc;
    uint32_t trigLogic = 0;
	[self read:kChanEnableMask returnValue:&enabled];
	[self read:kTrigSrcEnblMask returnValue:&triggerSrc];
    NSFont* theFont = [NSFont fontWithName:@"Monaco" size:10];
	NSLogFont(theFont,@"----------------------------------------------------------------------------------------------------------------\n");
	NSLogFont(theFont,@"Chan | Enabled | Thres | Dynamic Range | Pulse Width | Self-Trigger Logic | Status | Offset | ADC Temp | trigSrc\n");
	NSLogFont(theFont,@"----------------------------------------------------------------------------------------------------------------\n");
    int chan;
    for(chan=0;chan<kNumDT5725Channels;chan++){
		[self readChan:chan reg:kThresholds returnValue:&threshold];
        [self readChan:chan reg:kInputDyRange returnValue:&dynRange];
        [self readChan:chan reg:kTrigPulseWidth returnValue:&pulseWidth];
		[self readChan:chan reg:kStatus returnValue:&status];
        [self readChan:chan reg:kDCOffset returnValue:&dacOffset];
        [self readChan:chan reg:kAdcTemp returnValue:&adcTemp];
        [self readChan:chan reg:kSelfTrigLogic returnValue:&trigLogic];

        NSString* dynRangeString = @"";
        if(dynRange & 0x1)  dynRangeString = @"0.5 V";
        else                dynRangeString = @"2 V";

		NSString* statusString = @"";
		if(status & 0x08)		statusString = [statusString stringByAppendingString:@"Calib Done-"];
        else                    statusString = [statusString stringByAppendingString:@"Calibrating-"];
		if(status & 0x04)		statusString = [statusString stringByAppendingString:@"DAC Busy-"];
        else                    statusString = [statusString stringByAppendingString:@"DAC Set-"];
		if(status & 0x02)		statusString = [statusString stringByAppendingString:@"Empty"];
		else if(status & 0x01)	statusString = [statusString stringByAppendingString:@"Full"];

        NSString* trigLogicString = @"";
        if(trigLogic & 0x03){
            if(trigLogic & 0x02){
                if(trigLogic & 0x01)    trigLogicString = @"OR";
                else                    trigLogicString = [NSString stringWithFormat: @"%d", 2*(chan/2) + 1];
            }
            else                        trigLogicString = [NSString stringWithFormat: @"%d", 2*(chan/2)];
        }
        else                            trigLogicString = @"AND";
        if(trigLogic & 0x4) trigLogicString = [trigLogicString stringByAppendingString:@"-over/under"];
        else                trigLogicString = [trigLogicString stringByAppendingString:@"-pulseWidth"];

        NSLogFont(theFont,@"%d | %@ | %d | %@ | %d | %@ | %@ | %6.3f | %@ | %@\n",
				    chan, 
                    enabled&(1<<chan)?@"E":@"X",
				    threshold&0x3fff,
                    dynRangeString,
                    pulseWidth,
                    trigLogicString,
                    statusString,
				    [self convertDacToVolts:dacOffset dynamicRange:(BOOL)dynRange],
                    [NSString stringWithFormat: @"%u ºC", adcTemp],
				    triggerSrc&(1<<(chan/2))?@"Y":@"N");
	}
	NSLogFont(theFont,@"----------------------------------------------------------------------------------------------------------------\n");
    
	NSLogFont(theFont,@"Software Trigger  : %@\n",(triggerSrc >> 31)&0x1?@"Enabled":@"Disabled");
	NSLogFont(theFont,@"External Trigger  : %@\n",(triggerSrc >> 30)&0x1?@"Enabled":@"Disabled");
	NSLogFont(theFont,@"Coincidence Level : %d\n",(triggerSrc >> 24) & 0x7);
    NSLogFont(theFont,@"Coincidence Window: %d ns\n",((triggerSrc >> 20) & 0xf)*4);
	
    uint32_t aValue;
	[self read:kAcqControl returnValue:&aValue];
	NSLogFont(theFont,@"Triggers Count    : %@\n",aValue&0x8?@"All":@"Accepted");
	NSLogFont(theFont,@"Run Mode          : %@\n",DT5725StartStopRunModeString[aValue&0x3]);
    NSLogFont(theFont,@"Memory Full Mode  : %@\n",aValue&0x10?@"OneBufferFree":@"Normal");
	
	[self read:kAcqStatus returnValue:&aValue];
    NSLogFont(theFont,@"Channel Shutdown  : %@\n",aValue&0x80000?@"ON":@"OFF");
    NSLogFont(theFont,@"Chan. 0-4 Overheat: %@\n",aValue&0x100000?@"YES":@"NO");
    NSLogFont(theFont,@"Chan. 5-8 Overheat: %@\n",aValue&0x200000?@"YES":@"NO");
	NSLogFont(theFont,@"Board Ready       : %@\n",aValue&0x100?@"YES":@"NO");
	NSLogFont(theFont,@"PLL Locked        : %@\n",aValue&0x80?@"YES":@"NO");
	NSLogFont(theFont,@"PLL Bypass        : %@\n",aValue&0x40?@"YES":@"NO");
	NSLogFont(theFont,@"Clock source      : %@\n",aValue&0x20?@"External":@"Internal");
	NSLogFont(theFont,@"Buffer full       : %@\n",aValue&0x10?@"YES":@"NO");
	NSLogFont(theFont,@"Events Ready      : %@\n",aValue&0x08?@"YES":@"NO");
	NSLogFont(theFont,@"Run               : %@\n",aValue&0x04?@"ON":@"OFF");
	
	[self read:kEventStored returnValue:&aValue];
	NSLogFont(theFont,@"Events Stored     : %d\n",aValue);

    [self read:kBFStatus returnValue:&aValue];
    NSLogFont(theFont,@"PLL Lock Loss     : %@\n",aValue&0x10?@"YES":@"NO");
    NSLogFont(theFont,@"Temp. Failure     : %@\n",aValue&0x20?@"YES":@"NO");
    NSLogFont(theFont,@"ADC Power Down    : %@\n",aValue&0x40?@"YES":@"NO");
    NSLogFont(theFont,@"Internal Timeout  : %@\n",aValue&0xff?@"YES":@"NO");
}

- (void) initBoard
{
    [self readConfigurationROM];
    [self writeAcquisitionControl:NO]; // Make sure it's off.
    [self clearAllMemory];
    [self writeDynamicRanges];
    [self writeTrigPulseWidths];
    [self writeThresholds];
    [self writeSelfTrigLogics];
    [self writeDCOffsets];
	[self writeBoardConfiguration];
    [self writeSize];
    [self writeTriggerSourceEnableMask];
    [self writeFrontPanelTriggerOutEnableMask];
    [self writePostTriggerSetting];
    [self writeFrontPanelIOControl];
	[self writeChannelEnabledMask];
    [self writeFanSpeedControl];
    [self writeBufferAlmostFull];
    [self writeRunDelay];
    [self writeNumBLTEventsToReadout];
}

- (void) readConfigurationROM
{
    uint32_t value;
    int err;
    
    //test we can write and read
    value = 0xCC00FFEE;
    err = [self writeLongBlock:&value atAddress:reg[kScratch].addressOffset];
    if (err) {
        NSLog(@"DT5725 write scratch register at address: 0x%04x failed\n", reg[kScratch].addressOffset);
        return;
    }
    
    value = 0;
    err = [self readLongBlock:&value atAddress:reg[kScratch].addressOffset];
    if (err) {
        NSLog(@"DT5725 read scratch register at address: 0x%04x failed\n", reg[kScratch].addressOffset);
        return;
    }
    if (value != 0xCC00FFEE) {
        NSLog(@"DT5725 read scratch register returned bad value: 0x%08x, expected: 0xCC00FFEE\n");
        return;
    }

    //get digitizer version
    value = 0;
    err = [self readLongBlock:&value atAddress:reg[kBoardInfo].addressOffset];
    if (err) {
        NSLog(@"DT5725 read configuration ROM version at address: 0x%04x failed\n", reg[kBoardInfo].addressOffset);
        return;
    }
    switch (value & 0xFF) {
        case 0x0E: //725 digitizer family
            break;

        case 0x0B:
            NSLog(@"Warning: 730 digitizer family not tested.\n");
            break;

        default:
            NSLog(@"Warning: Unknown digitizer family.\n");
    }

    switch ((value >> 8) & 0xFF) {
        case 0x01: //640 kS/ch.
            break;

        case 0x08:
            NSLog(@"Warning: 5.12 MS/ch. memory not tested.\n");
            break;

        default:
            NSLog(@"Warning: Unknown memory size.\n");
            break;
    }

    switch ((value >> 16) & 0xFF) {
        case 0x08: //8 Channels (DT, NIM, and 8-chan. VME)
            break;

        case 0x10: //16 Channels (VME boards)
            NSLog(@"Warning: 16 Channel VME boards not tested.\n");
            break;

        default:
            NSLog(@"Warning: Unknown number of channels.\n");
            break;
    }
    
    //check board ID
    value = 0;
    err = [self readLongBlock:&value atAddress:reg[kConfigROMBoard2].addressOffset];
    if (err) {
        NSLog(@"DT5725 read configuration ROM Board2 at address: 0x%04x failed\n", reg[kConfigROMBoard2].addressOffset);
        return;
    }
    switch (value & 0xFF) {
        case 0x02: //Desktop model
            break;
            
        default:
            NSLog(@"Warning: Non-desktop form factor not tested.\n");
            break;
    }
}

#pragma mark ***HW Reg Access
- (void) writeDynamicRanges
{
    short i;
    for (i = 0; i < kNumDT5725Channels; i++){
        [self writeDynamicRange:i];
    }
}

- (void) writeDynamicRange:(unsigned short) i
{
    uint32_t aValue = [self inputDynamicRange:i];
    [self writeLongBlock:&aValue
               atAddress:reg[kInputDyRange].addressOffset + (i * 0x100)];
}

- (void) writeTrigPulseWidths
{
    short i;
    for (i = 0; i < kNumDT5725Channels; i++){
        [self writeTrigPulseWidth:i];
    }
}

- (void) writeTrigPulseWidth:(unsigned short) i
{
    uint32_t aValue = [self selfTrigPulseWidth:i];
    [self writeLongBlock:&aValue
               atAddress:reg[kTrigPulseWidth].addressOffset + (i * 0x100)];
}

- (void) writeThresholds
{
    short	i;
    for (i = 0; i < kNumDT5725Channels; i++){
        [self writeThreshold:i];
    }
}

- (void) writeThreshold:(unsigned short) i
{
    uint32_t 	aValue = [self threshold:i];
    [self writeLongBlock:&aValue
               atAddress:reg[kThresholds].addressOffset + (i * 0x100)];
}

- (void) writeSelfTrigLogics
{
    short group;
    for (group = 0; group < kNumDT5725Channels/2; group++){
        [self writeSelfTrigLogic:group];
    }
}

- (void) writeSelfTrigLogic:(unsigned short) i
{
    uint32_t aValue = [self selfTrigLogic:i];
    aValue |= ([self selfTrigPulseType:i] & 0x1) << 2;
    [self writeLongBlock:&aValue
               atAddress:reg[kSelfTrigLogic].addressOffset + ((2*i) * 0x100)];
}

- (void) writeDCOffsets
{
    short i;
    for (i = 0; i < kNumDT5725Channels; i++){
        [self writeDCOffset:i];
    }
}

- (void) writeDCOffset:(unsigned short) i
{
    uint32_t aValue = [self dcOffset:i];
    [self writeLongBlock:&aValue
               atAddress:reg[kDCOffset].addressOffset + (i * 0x100)];
}

- (void) writeBoardConfiguration
{
    uint32_t mask = 0;
    mask |= (trigOnUnderThreshold & 0x1)  <<  6;
    mask |= 0x1                           <<  4; //reserved bit (MUST be one)
    mask |= (testPatternEnabled & 0x1)    <<  3;
    mask |= (trigOverlapEnabled & 0x1)    <<  1;
    [self writeLongBlock:&mask
               atAddress:reg[kBoardConfig].addressOffset];
}

- (void) writeSize
{
    uint32_t customSize = eventSize;
    buffCode = 0x0A;
    uint32_t memsize = 640000; //samples/ch.
    while ((customSize * 10) > (memsize/(uint32_t)pow(2., (float)buffCode) - 10)){
        buffCode -= 1;
    }
    [self writeLongBlock:&buffCode
               atAddress:reg[kBufferOrganization].addressOffset];
    [self writeLongBlock:&customSize
               atAddress:reg[kCustomSize].addressOffset];
}

- (void) adcCalibrate
{
    uint32_t aValue = 0x446F6773;
    for (int i = 0; i < kNumDT5725Channels; i++){
        uint32_t chanStatus;
        [self readLongBlock:&chanStatus 
                  atAddress:reg[kStatus].addressOffset + (i * 0x100)];
        while (chanStatus ^ 0x8);
    }
    [self writeLongBlock:&aValue
               atAddress:reg[kChanAdcCalib].addressOffset];
}

- (void) writeAcquisitionControl:(BOOL)start
{
    uint32_t aValue = 0;
    aValue |= (clockSource & 0x1)       << 6;
    aValue |= (memFullMode & 0x1)       << 5;
    aValue |= (countAllTriggers & 0x1)  << 3;
    if(start) aValue |= (0x1 << 2);
    aValue |= (startStopRunMode & 0x3)           << 0;
    [self writeLongBlock:&aValue
               atAddress:reg[kAcqControl].addressOffset];
    
}

- (void) trigger
{
    uint32_t aValue = 0x446F6773;
    [self writeLongBlock:&aValue
               atAddress:reg[kSWTrigger].addressOffset];
   
}

- (void) writeTriggerSourceEnableMask
{
    uint32_t aValue = 0;
    aValue |= (softwareTrigEnabled & 0x1) << 31;
    aValue |= (externalTrigEnabled & 0x1) << 30;
    aValue |= (coincidenceLevel    & 0x7) << 24;
    aValue |= (coincidenceWindow   & 0xf) << 20;
    aValue |= (triggerSourceMask   & 0xf) <<  0;
    [self writeLongBlock:&aValue
               atAddress:reg[kTrigSrcEnblMask].addressOffset];
}

- (void) writeFrontPanelIOControl
{
    uint32_t aValue = 0;
    aValue |= (fpHeaderPattern        & 0x3) << 21;
    aValue |= (fpBusyUnlockSelect     & 0x1) << 20;
    aValue |= (fpMBProbeSelect        & 0x3) << 18;
    aValue |= (fpTrigOutModeSelect    & 0x3) << 16;
    aValue |= (fpTrigOutMode          & 0x1) << 15;
    aValue |= (fpForceTrigOut         & 0x1) << 14;
    aValue |= (fpTrigInToMezzanines   & 0x1) << 11;
    aValue |= (fpTrigInSigEdgeDisable & 0x1) << 10;
    aValue |= (fpLogicType            & 0x1) <<  0;
    [self writeLongBlock:&aValue
               atAddress:reg[kFPIOControl].addressOffset];
  
}

- (void) writeFrontPanelTriggerOutEnableMask
{
    uint32_t aValue = 0;
    aValue |= (swTrigOutEnabled        & 0x1) << 31;
    aValue |= (extTrigOutEnabled       & 0x1) << 30;
    aValue |= (trigOutCoincidenceLevel & 0x7) << 10;
    aValue |= (triggerOutLogic         & 0x3) <<  8;
    aValue |= (triggerOutMask          & 0xf) <<  0;
    [self writeLongBlock:&aValue
               atAddress:reg[kFPTrigOutEnblMask].addressOffset];
}

- (void) writePostTriggerSetting
{
    uint32_t aValue = postTriggerSetting/2;
    [self writeLongBlock:&aValue
               atAddress:reg[kPostTrigSetting].addressOffset];
    
}

- (void) writeChannelEnabledMask
{
    uint32_t aValue = enabledMask & 0xff;
    [self writeLongBlock:&aValue
               atAddress:reg[kChanEnableMask].addressOffset];
    
}

- (void) writeFanSpeedControl
{
    uint32_t aValue = 0;
    aValue |= 0x3                  << 4; //must be 1
    aValue |= (fanSpeedMode & 0x1) << 3;
    [self writeLongBlock:&aValue
               atAddress:reg[kFanSpeed].addressOffset];
}

- (void) writeBufferAlmostFull
{
    uint32_t aValue = (almostFullLevel & 0x4f);
    [self writeLongBlock:&aValue
               atAddress:reg[kBufAlmostFull].addressOffset];
}

- (void) writeRunDelay
{
    uint32_t aValue = runDelay;
    [self writeLongBlock:&aValue
               atAddress:reg[kRunDelay].addressOffset];
}

- (void) writeNumBLTEventsToReadout
{
    uint32_t aValue = pow(2.,buffCode);
    [self writeLongBlock:&aValue
               atAddress:reg[kBLTEventNum].addressOffset];
}

- (void) softwareReset
{
    uint32_t aValue = 0x446F6773;
    [self writeLongBlock:&aValue
               atAddress:reg[kSWReset].addressOffset];
}

- (void) clearAllMemory
{
    uint32_t aValue = 0x446F6773;
    [self writeLongBlock:&aValue
               atAddress:reg[kSWClear].addressOffset];
    
}
- (void) configReload
{
    uint32_t aValue = 0x446F6773;
    [self writeLongBlock:&aValue
               atAddress:reg[kConfigReload].addressOffset];
}

- (void) checkBufferAlarm
{
    if((bufferState == kDT5725BufferFull) && isRunning){
        bufferEmptyCount = 0;
        if(!bufferFullAlarm){
            NSString* alarmName = [NSString stringWithFormat:@"Buffer FULL DT5725 (%@)",[self fullID]];
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
        [self performSelector:@selector(checkBufferAlarm) withObject:nil afterDelay:.5];
    }
    else {
        [bufferFullAlarm clearAlarm];
        [bufferFullAlarm release];
        bufferFullAlarm = nil;
    }
    
    if(lastTimeByteTotalChecked){
        NSTimeInterval delta = fabs([lastTimeByteTotalChecked timeIntervalSinceNow]);
        if(delta > 0){
            totalByteRate = totalBytesTransfered/delta;
        }
        totalBytesTransfered=0;
    }
    
    [lastTimeByteTotalChecked release];
    lastTimeByteTotalChecked = [[NSDate date]retain];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5725ModelBufferCheckChanged object:self];
}


#pragma mark ***Helpers
- (float) convertDacToVolts:(unsigned short)aDacValue dynamicRange:(BOOL)dynamicRange
{
    if(dynamicRange) return 0.5*(aDacValue/65535.) - 0.25;
    else             return 2*(aDacValue/65535.) - 1.0;
}

- (unsigned short) convertVoltsToDac:(float)aVoltage dynamicRange:(BOOL)dynamicRange
{
    if(dynamicRange) return (unsigned short)(65535. * (aVoltage + 0.25) / 0.5);
    else             return (unsigned short)(65535. * (aVoltage + 1.0)/2.);
}


#pragma mark ***DataTaker

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumDT5725Channels;i++){
        waveFormCount[i]=0;
    }
}

- (void) reset
{
}

- (NSString*) identifier
{
	return [NSString stringWithFormat:@"DT5725 %u",[self uniqueIdNumber]];
}

#pragma mark •••Data Taker
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORDT5725Decoder", @"decoder",
								 [NSNumber numberWithLong:dataId],  @"dataId",
								 [NSNumber numberWithBool:YES],     @"variable",
								 [NSNumber numberWithLong:-1],		@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"waveform"];
    
    return dataDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORDT5725Model"];    
	//----------------------------------------------------------------------------------------
    [self initBoard];
    [self startRates];

    circularBuffer = [[ORSafeCircularBuffer alloc] initWithBufferSize:10000];
    //launch data pulling thread
    self.isTimeToStopDataWorker = NO;
    self.isDataWorkerRunning    = NO;
    firstTime = YES;
    isRunning = YES;
    [self checkBufferAlarm];

    uint32_t totalDataSizeInLongs;
    uint32_t recordSizeBytes;
    uint32_t numSamplesPerEvent = 1024*1024./pow(2.,[self eventSize]);
    uint32_t numBlts = pow(2.,[self eventSize]);
    
    recordSizeBytes      = (4+numSamplesPerEvent/2)*4;
    totalDataSizeInLongs = recordSizeBytes/4 + 2;
    
    eventData = [[NSMutableData dataWithCapacity:totalDataSizeInLongs*sizeof(int32_t)]retain];
    [eventData setLength:numBlts*(totalDataSizeInLongs*sizeof(int32_t))];
    
    [NSThread detachNewThreadSelector:@selector(dataWorker:) toTarget:self withObject:nil];
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(firstTime){
        firstTime = NO;
        [self writeAcquisitionControl:YES];
    }
    else {
        if([circularBuffer dataAvailable]){
            NSData* theData = [circularBuffer readNextBlock];
            [aDataPacket addData:theData];
        }
    }
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //stop data pulling thread
    [self writeAcquisitionControl:NO];

    self.isTimeToStopDataWorker = YES;
    while (self.isDataWorkerRunning) {
        [NSThread sleepForTimeInterval:.001];
    }
    [circularBuffer release];
    circularBuffer = nil;
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [waveFormRateGroup stop];
    short i;
    for(i=0;i<kNumDT5725Channels;i++)waveFormCount[i] = 0;
    
    [self writeAcquisitionControl:NO];
    isRunning = NO;
    [eventData release];
    eventData = nil;
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    ++waveFormCount[channel];
    return YES;
}

#pragma mark ***Archival
//returns 0 if success; -1 if request fails, and number of bytes returned by digitizer in otherwise
- (int) writeLongBlock:(uint32_t*) writeValue atAddress:(uint32_t) anAddress
{
    //-----------------------------------------------
    //AM = 0x09 A32 non-priviledged access
    //dsize = 2 for 32 bit word
    //command is:
    //opcode | AM<<8  | 2<<6 | dsize<<4 | SINGLERW
    //0x8000 | 0x9<<8 | 2<<6 | 2<<4     | SINGLERW
    //= 0x89A1
    //-----------------------------------------------

    unsigned short opcode   = 0x8000 | (0x9<<8) | (2<<6) | (2<<4) | 0x1;
    unsigned char cmdBuffer[10];
    int count = 0;
    cmdBuffer[count++] = opcode & 0xFF;
    cmdBuffer[count++] = (opcode >> 8) & 0xFF;
    
    // write the address
    cmdBuffer[count++] = (char)(anAddress & 0xFF);
    cmdBuffer[count++] = (char)((anAddress >> 8) & 0xFF);
    cmdBuffer[count++] = (char)((anAddress >> 16) & 0xFF);
    cmdBuffer[count++] = (char)((anAddress >> 24) & 0xFF);

    uint32_t localData = *writeValue;
    cmdBuffer[count++] = (char)(localData & 0xFF);
    cmdBuffer[count++] = (char)((localData >> 8) & 0xFF);
    cmdBuffer[count++] = (char)((localData >> 16) & 0xFF);
    cmdBuffer[count++] = (char)((localData >> 24) & 0xFF);

    
    @try {
        [[self usbInterface] writeBytes:cmdBuffer length:10 pipe:0];
	}
    @catch (NSException* e) {
		NSLog(@"DT5725 failed write request at address: 0x%08x failed\n", anAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}

    unsigned short status = 0;
    
    int num_read = 0;
    @try {
        num_read = [[self usbInterface] readBytes:&status length:sizeof(status) pipe:0];
	}
    @catch (NSException* e) {
		NSLog(@"DT5725 failed write respond at address: 0x%08x\n", anAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
    
    if (num_read != 2 || status & 0x20) {
		NSLog(@"DT5725 failed write at address: 0x%08x\n", anAddress);
		NSLog(@"DT5725 returned with bus error\n");
        return num_read;
    }
    
    return 0;
}


//returns 0 if success, -1 if request fails, and number of bytes returned by digitizer otherwise
-(int) readLongBlock:(uint32_t*) readValue atAddress:(uint32_t) anAddress
{
    
    //-----------------------------------------------
    //command is:
    //opcode | AM<<8  | 2<<6 | dsize<<4 | SINGLERW
    //0xC000 | 0x9<<8 | 2<<6 | 2<<4     | SINGLERW
    //= 0xC9A1
    //-----------------------------------------------
    unsigned short opcode   = 0xC000 | (0x9<<8) | (2<<6) | (2<<4) | 0x1;
    unsigned char cmdBuffer[6];
    int count = 0;
    cmdBuffer[count++] = opcode & 0xFF;
    cmdBuffer[count++] = (opcode >> 8) & 0xFF;
    
    // write the address
    cmdBuffer[count++] = (char)((anAddress >>  0) & 0xFF);
    cmdBuffer[count++] = (char)((anAddress >>  8) & 0xFF);
    cmdBuffer[count++] = (char)((anAddress >> 16) & 0xFF);
    cmdBuffer[count++] = (char)((anAddress >> 24) & 0xFF);
    
    @try {
		[[self usbInterface] writeBytes:cmdBuffer length:6 pipe:0];
	}
    @catch (NSException* e) {
		NSLog(@"DT5725 failed read request at address: 0x%08x failed\n", anAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}
    
    struct {
        unsigned int   value;
        unsigned short status;
    } resp;
    
    resp.value  = 0;
    resp.status = 0;

    int num_read = 0;
    @try {
        num_read = [[self usbInterface] readBytes:&resp length:6 pipe:0];
	}
    @catch (NSException* e) {
		NSLog(@"DT5725 failed read respond at address: 0x%08x\n", anAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}
    
    if (num_read != 6 || (resp.status & 0x20)) {
		NSLog(@"DT5725 failed read at address: 0x%08x\n", anAddress);
		NSLog(@"DT5725 returned with bus error\n");
        return num_read;
    }
    
    *readValue = resp.value;
    return 0;
}

//returns 0 if success; -1 if request fails, and number of bytes returned by digitizer otherwise
- (int) readFifo:(char*)readBuffer numBytesToRead:(int)    numBytes
{
    uint32_t fifoAddress = 0x0000;
    
    if (numBytes == 0) return 0;
    int maxBLTSize = 0x100000; //8 MBytes
    numBytes = (numBytes + 7) & ~7UL;

    uint32_t np = numBytes/maxBLTSize;
    if(np*maxBLTSize != numBytes)np++;

    //request is an array of readLongBlock like requests
    unsigned char* outbuf = (unsigned char*)malloc(np * 8);
    
    unsigned short AM        = 0xC;
    unsigned short dSizeCode = 0x3;
    unsigned int   DW        = 0x8;
    unsigned int   count     = 0;
    int i;
    for(i=0;i<np;i++){
        if(i == np-1){
            //last one
            //build and write the opcode
            unsigned short flag      = 0x0002; //last one
            unsigned short opcode    = 0xC000 | (AM<<8) | (flag<<6) | (dSizeCode<<4) | FBLT;
            
            outbuf[count++] = opcode & 0xFF;
            outbuf[count++] = (opcode>>8) & 0xFF;
            
            //write the number of data cycles
            unsigned short numDataCycles = (numBytes - (np-1)*maxBLTSize)/DW;
            outbuf[count++] = numDataCycles & 0xff;
            outbuf[count++] = (numDataCycles>>8) & 0xff;
        }
        else {
            unsigned short flag      = 0x0000; //not last one
            unsigned short opcode    = 0xC000 | (AM<<8) | (flag<<6) | (dSizeCode<<4) | FPBLT;
            
            outbuf[count++] = opcode & 0xFF;
            outbuf[count++] = (opcode>>8) & 0xFF;
            
            //write the number of data cycles
            unsigned short numDataCycles = maxBLTSize/DW;
            outbuf[count++] = numDataCycles & 0xff;
            outbuf[count++] = (numDataCycles>>8) & 0xff;
        }
        //fifoAddress is zero, but go thru the motions anyway for now
        outbuf[count++] = (char)((fifoAddress  >>  0) & 0xFF);
        outbuf[count++] = (char)((fifoAddress  >>  8) & 0xFF);
        outbuf[count++] = (char)((fifoAddress  >> 16) & 0xFF);
        outbuf[count++] = (char)((fifoAddress  >> 24) & 0xFF);
        
    }
    
    //write the command block
    @try {
        [[self usbInterface] writeBytes:outbuf length:count pipe:0];
        free(outbuf);
    }
    @catch (NSException* e) {
        free(outbuf);
        NSString* name = [self fullID];
        NSLogError(@"",name,@"Fifo read failed",[e reason],nil);
        return -1;
    }
  
    int num_read = 0;
    @try {
        num_read = [[self usbInterface] readBytes:readBuffer length:numBytes+2 pipe:0];
        num_read -= 2;
        if( num_read < 0 ) {
            // -----------------------------------------------------------
            // it appears that the status word is 0x33 on a successful read
            // when transfering multiple events if you ask for more data than
            // what exists in the event buffer. Ignore the status word for now
            // and just look at the num bytes read.
            //           int status;
            //           status = readBuffer[num_read] & 0xFF;
            //           status += (readBuffer[num_read + 1] & 0xFF) << 8;
            //       }
            //       if (num_read != numBytes || (status & 0x20)) {
            // -----------------------------------------------------------
            NSString* name = [self fullID];
            NSLogError(@"",name,@"Fifo read failed",nil);
            return num_read;
        }

    }
    @catch (NSException* e) {
        NSString* name = [self fullID];
        NSLogError(@"",name,@"Fifo read failed",[e reason],nil);
        return -1;
    }

    return num_read;
}


#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [[self undoManager] disableUndoRegistration];
    [self setTrigOnUnderThreshold:      [aDecoder decodeBoolForKey:     @"trigOnUnderThreshold"]];
    [self setTestPatternEnabled:        [aDecoder decodeBoolForKey:     @"testPatternEnabled"]];
    [self setTrigOverlapEnabled:        [aDecoder decodeBoolForKey:     @"trigOverlapEnabled"]];
    [self setEventSize:                 [aDecoder decodeIntForKey:    @"eventSize"]];
    [self setClockSource:               [aDecoder decodeBoolForKey:     @"clockSource"]];
    [self setCountAllTriggers:          [aDecoder decodeBoolForKey:     @"countAllTriggers"]];
    [self setMemFullMode:               [aDecoder decodeBoolForKey:     @"memFullMode"]];
    [self setStartStopRunMode:          [aDecoder decodeBoolForKey:     @"startStopRunMode"]];
    [self setSoftwareTrigEnabled:       [aDecoder decodeBoolForKey:     @"softwareTrigEnabled"]];
    [self setExternalTrigEnabled:       [aDecoder decodeBoolForKey:     @"externalTrigEnabled"]];
    [self setTriggerSourceMask:         [aDecoder decodeIntForKey:    @"triggerSourceMask"]];
    [self setExtTrigOutEnabled:         [aDecoder decodeBoolForKey:     @"fpExternalTrigEnabled"]];
    [self setSwTrigOutEnabled:          [aDecoder decodeBoolForKey:     @"fpSoftwareTrigEnabled"]];
    [self setTriggerOutMask:            [aDecoder decodeIntForKey:      @"triggerOutMask"]];
    [self setTriggerOutLogic:           [aDecoder decodeIntegerForKey:      @"triggerOutLogic"]];
    [self setTrigOutCoincidenceLevel:   [aDecoder decodeIntegerForKey:      @"trigOutCoincidenceLevel"]];
    [self setPostTriggerSetting:        [aDecoder decodeIntForKey:    @"postTriggerSetting"]];
    [self setEnabledMask:               [aDecoder decodeIntegerForKey:      @"enabledMask"]];
    [self setFpLogicType:               [aDecoder decodeBoolForKey:     @"fpLogicType"]];
    [self setFpTrigInSigEdgeDisable:    [aDecoder decodeBoolForKey:     @"fpTrigInSigEdgeDisable"]];
    [self setFpTrigInToMezzanines:      [aDecoder decodeBoolForKey:     @"fpTrigInToMezzanines"]];
    [self setFpForceTrigOut:            [aDecoder decodeBoolForKey:     @"fpForceTrigOut"]];
    [self setFpTrigOutMode:             [aDecoder decodeBoolForKey:     @"fpTrigOutMode"]];
    [self setFpTrigOutModeSelect:       [aDecoder decodeIntegerForKey:      @"fpTrigOutModeSelect"]];
    [self setFpMBProbeSelect:           [aDecoder decodeIntegerForKey:      @"fpMBProbeSelect"]];
    [self setFpBusyUnlockSelect:        [aDecoder decodeBoolForKey:     @"fpBusyUnlockSelect"]];
    [self setFpHeaderPattern:           [aDecoder decodeIntegerForKey:      @"fpHeaderPattern"]];
    [self setFanSpeedMode:              [aDecoder decodeBoolForKey:     @"fanSpeedMode"]];
    [self setAlmostFullLevel:           [aDecoder decodeIntegerForKey:      @"almostFullLevel"]];
    [self setRunDelay:                  [aDecoder decodeIntForKey:    @"runDelay"]];
    [self setCoincidenceWindow:         [aDecoder decodeIntegerForKey:      @"coincidenceWindow"]];
    [self setCoincidenceLevel:          [aDecoder decodeIntegerForKey:      @"coincidenceLevel"]];
    [self setWaveFormRateGroup:         [aDecoder decodeObjectForKey:   @"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:8 groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	int i;
    for (i = 0; i < kNumDT5725Channels; i++){
        [self setInputDynamicRange:i    withValue:[aDecoder decodeIntegerForKey: [NSString stringWithFormat:@"inputDynamicRange%d", i]]];
        [self setSelfTrigPulseWidth:i   withValue:[aDecoder decodeIntegerForKey:  [NSString stringWithFormat:@"selfTrigPulseWidth%d", i]]];
        [self setThreshold:i            withValue:[aDecoder decodeIntegerForKey:  [NSString stringWithFormat:@"threshold%d", i]]];
        [self setSelfTrigPulseType:i    withValue:[aDecoder decodeBoolForKey: [NSString stringWithFormat:@"selfTrigPulseType%d", i]]];
        [self setDCOffset:i             withValue:[aDecoder decodeIntegerForKey:  [NSString stringWithFormat:@"dcOffset%d", i]]];
    }
    int group;
    for (group = 0; group < kNumDT5725Channels/2; group++){
        [self setSelfTrigLogic:group        withValue:[aDecoder decodeIntegerForKey:  [NSString stringWithFormat:@"selfTrigLogic%d", group]]];
    }
    
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)anEncoder
{
    [super encodeWithCoder:anEncoder];
    
    [anEncoder encodeBool:trigOnUnderThreshold      forKey:@"trigOnUnderThreshold"];
    [anEncoder encodeBool:testPatternEnabled        forKey:@"testPatternEnabled"];
    [anEncoder encodeBool:trigOverlapEnabled        forKey:@"trigOverlapEnabled"];
    [anEncoder encodeInt:eventSize       forKey:@"eventSize"];
    [anEncoder encodeBool:clockSource               forKey:@"clockSource"];
    [anEncoder encodeBool:countAllTriggers          forKey:@"countAllTriggers"];
    [anEncoder encodeBool:startStopRunMode          forKey:@"startStopRunMode"];
    [anEncoder encodeBool:memFullMode               forKey:@"memFullMode"];
    [anEncoder encodeBool:softwareTrigEnabled       forKey:@"softwareTrigEnabled"];
    [anEncoder encodeBool:externalTrigEnabled       forKey:@"externalTrigEnabled"];
    [anEncoder encodeInt:triggerSourceMask forKey:@"triggerSourceMask"];
    [anEncoder encodeBool:swTrigOutEnabled          forKey:@"swTrigOutEnabled"];
    [anEncoder encodeBool:extTrigOutEnabled         forKey:@"extTrigOutEnabled"];
    [anEncoder encodeInt:triggerOutMask  forKey:@"triggerOutMask"];
    [anEncoder encodeInteger:triggerOutLogic            forKey:@"triggerOutLogic"];
    [anEncoder encodeInteger:trigOutCoincidenceLevel    forKey:@"trigOutCoincidenceLevel"];
    [anEncoder encodeInt:postTriggerSetting       forKey:@"postTriggerSetting"];
    [anEncoder encodeInteger:enabledMask                forKey:@"enabledMask"];
    [anEncoder encodeBool:fpLogicType               forKey:@"fpLogicType"];
    [anEncoder encodeBool:fpTrigInSigEdgeDisable    forKey:@"fpTrigInSigEdgeDisable"];
    [anEncoder encodeBool:fpTrigInToMezzanines      forKey:@"fpTrigInToMezzanines"];
    [anEncoder encodeBool:fpForceTrigOut            forKey:@"fpForceTrigOut"];
    [anEncoder encodeBool:fpTrigOutMode             forKey:@"fpTrigOutMode"];
    [anEncoder encodeInteger:fpTrigOutModeSelect        forKey:@"fpTrigOutModeSelect"];
    [anEncoder encodeInteger:fpMBProbeSelect            forKey:@"fpMBProbeSelect"];
    [anEncoder encodeBool:fpBusyUnlockSelect        forKey:@"fpBusyUnlockSelect"];
    [anEncoder encodeInteger:fpHeaderPattern            forKey:@"fpHeaderPattern"];
    [anEncoder encodeBool:fanSpeedMode              forKey:@"fanSpeedMode"];
    [anEncoder encodeInteger:almostFullLevel            forKey:@"almostFullLevel"];
    [anEncoder encodeInt:runDelay        forKey:@"runDelay"];
    [anEncoder encodeInteger:coincidenceWindow          forKey:@"coincidenceWindow"];
	[anEncoder encodeInteger:coincidenceLevel           forKey:@"coincidenceLevel"];
    [anEncoder encodeObject:waveFormRateGroup       forKey:@"waveFormRateGroup"];
    
	int i;
	for (i = 0; i < kNumDT5725Channels; i++){
        [anEncoder encodeInteger:inputDynamicRange[i]       forKey:[NSString stringWithFormat:@"inputDynamicRange%d", i]];
        [anEncoder encodeInteger:selfTrigPulseWidth[i]      forKey:[NSString stringWithFormat:@"selfTrigPulseWidth%d", i]];
        [anEncoder encodeInteger:thresholds[i]              forKey:[NSString stringWithFormat:@"threshold%d", i]];
        [anEncoder encodeBool:selfTrigPulseType[i]      forKey:[NSString stringWithFormat:@"selfTrigPulseType%d", i]];
        [anEncoder encodeInteger:dcOffset[i]                forKey:[NSString stringWithFormat:@"dcOffset%d", i]];
    }
    int group;
    for (group = 0; group < kNumDT5725Channels/2; group++){
        [anEncoder encodeInteger:selfTrigLogic[group]           forKey:[NSString stringWithFormat:@"selfTrigLogic%d", group]];
    }
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    
    [objDictionary setObject:[NSNumber numberWithInt:trigOnUnderThreshold]      forKey:@"trigOnUnderThreshold"];
    [objDictionary setObject:[NSNumber numberWithInt:testPatternEnabled]        forKey:@"testPatternEnabled"];
    [objDictionary setObject:[NSNumber numberWithInt:trigOverlapEnabled]        forKey:@"trigOverlapEnabled"];
    [objDictionary setObject:[NSNumber numberWithInteger:eventSize]             forKey:@"eventSize"];
    [objDictionary setObject:[NSNumber numberWithInt:clockSource]               forKey:@"clockSource"];
    [objDictionary setObject:[NSNumber numberWithInt:countAllTriggers]          forKey:@"countAllTriggers"];
    [objDictionary setObject:[NSNumber numberWithInt:startStopRunMode]          forKey:@"startStopRunMode"];
    [objDictionary setObject:[NSNumber numberWithInt:memFullMode]               forKey:@"memFullMode"];
    [objDictionary setObject:[NSNumber numberWithInt:softwareTrigEnabled]       forKey:@"softwareTrigEnabled"];
    [objDictionary setObject:[NSNumber numberWithInt:externalTrigEnabled]       forKey:@"externalTrigEnabled"];
    [objDictionary setObject:[NSNumber numberWithInteger:triggerSourceMask]     forKey:@"triggerSourceMask"];
    [objDictionary setObject:[NSNumber numberWithInt:swTrigOutEnabled]          forKey:@"swTrigOutEnabled"];
    [objDictionary setObject:[NSNumber numberWithInt:extTrigOutEnabled]         forKey:@"extTrigOutEnabled"];
    [objDictionary setObject:[NSNumber numberWithInteger:triggerOutMask]        forKey:@"triggerOutMask"];
    [objDictionary setObject:[NSNumber numberWithInt:triggerOutLogic]           forKey:@"triggerOutLogic"];
    [objDictionary setObject:[NSNumber numberWithInt:trigOutCoincidenceLevel]   forKey:@"trigOutCoincidenceLevel"];
    [objDictionary setObject:[NSNumber numberWithInteger:postTriggerSetting]    forKey:@"postTriggerSetting"];
    [objDictionary setObject:[NSNumber numberWithInt:enabledMask]               forKey:@"enabledMask"];
    [objDictionary setObject:[NSNumber numberWithInt:fpLogicType]               forKey:@"fpLogicType"];
    [objDictionary setObject:[NSNumber numberWithInt:fpTrigInSigEdgeDisable]    forKey:@"fpTrigInSigEdgeDisable"];
    [objDictionary setObject:[NSNumber numberWithInt:fpTrigInToMezzanines]      forKey:@"fpTrigInToMezzanines"];
    [objDictionary setObject:[NSNumber numberWithInt:fpForceTrigOut]            forKey:@"fpForceTrigOut"];
    [objDictionary setObject:[NSNumber numberWithInt:fpTrigOutMode]             forKey:@"fpTrigOutMode"];
    [objDictionary setObject:[NSNumber numberWithInt:fpTrigOutModeSelect]       forKey:@"fpTrigOutModeSelect"];
    [objDictionary setObject:[NSNumber numberWithInt:fpMBProbeSelect]           forKey:@"fpMBProbeSelect"];
    [objDictionary setObject:[NSNumber numberWithInt:fpBusyUnlockSelect]        forKey:@"fpBusyUnlockSelect"];
    [objDictionary setObject:[NSNumber numberWithInt:fpHeaderPattern]           forKey:@"fpHeaderPatter"];
    [objDictionary setObject:[NSNumber numberWithInt:fanSpeedMode]              forKey:@"fanSpeedMode"];
    [objDictionary setObject:[NSNumber numberWithInt:almostFullLevel]           forKey:@"almostFullLevel"];
    [objDictionary setObject:[NSNumber numberWithInteger:runDelay]              forKey:@"runDelay"];
    [objDictionary setObject:[NSNumber numberWithInt:coincidenceWindow]         forKey:@"coincidenceWindow"];
    [objDictionary setObject:[NSNumber numberWithInt:coincidenceLevel]          forKey:@"coincidenceLevel"];
    
    [self addCurrentState:objDictionary uShortArray:(unsigned short*)inputDynamicRange         forKey:@"inputDynamicRange"];
    [self addCurrentState:objDictionary uShortArray:(unsigned short*)selfTrigPulseWidth        forKey:@"selfTrigPulseWidth"];
    [self addCurrentState:objDictionary uShortArray:(unsigned short*)thresholds                forKey:@"thresholds"];
    [self addCurrentState:objDictionary uShortArray:(unsigned short*)selfTrigLogic             forKey:@"selfTrigLogic"];
    [self addCurrentState:objDictionary uShortArray:(unsigned short*)selfTrigPulseType         forKey:@"selfTrigPulseType"];
    [self addCurrentState:objDictionary uShortArray:(unsigned short*)dcOffset                  forKey:@"dcOffset"];

    
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary longArray:(int32_t*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumDT5725Channels;i++){
        [ar addObject:[NSNumber numberWithLong:*anArray]];
        anArray++;
    }
    [dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary uShortArray:(unsigned short*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumDT5725Channels;i++){
        [ar addObject:[NSNumber numberWithUnsignedShort:*anArray]];
        anArray++;
    }
    [dictionary setObject:ar forKey:aKey];
}

#pragma mark ***DataSource
- (void) getQueMinValue:(uint32_t*)aMinValue maxValue:(uint32_t*)aMaxValue head:(uint32_t*)aHeadValue tail:(uint32_t*)aTailValue
{
    *aMinValue  = 0;
    *aMaxValue  = [circularBuffer bufferSize];
    *aHeadValue = [circularBuffer writeMark];
    *aTailValue = [circularBuffer readMark];
}

@end

@implementation ORDT5725Model (private)
//take the data, break it up into events, and pass it to the data taking thread with a circular buffer
- (void) dataWorker:(NSDictionary*)arg
{
    self.isDataWorkerRunning = YES;

    while (!self.isTimeToStopDataWorker) {
        NSAutoreleasePool* workerPool = [[NSAutoreleasePool alloc] init];
        uint32_t acqStatus = 0;
        [self read:kAcqStatus returnValue:&acqStatus];
        BOOL isDataAvailable = (acqStatus >> 3) & 0x1;
        if(isDataAvailable){
            if((acqStatus >> 4) & 0x1) bufferState = kDT5725BufferFull;
            else                       bufferState = kDT5725BufferReady;
            
            
            uint32_t* theData = (uint32_t*)[eventData bytes];
            int num     = [self readFifo:(char*)theData numBytesToRead:(int)[eventData length]];
            if(num>0){
                uint32_t index=0;
                do {
                    if((theData[index]>>28 & 0xf) == 0xA){
                        uint32_t theSize = theData[index] & 0x0fffffff;
                        NSMutableData* record = [NSMutableData dataWithCapacity:(theSize+2)*sizeof(int32_t)];
                        [record setLength:(theSize+2)*sizeof(int32_t)];
                        uint32_t* theRecord = (uint32_t*)[record bytes];
                        theRecord[0]  = dataId | theSize+2;
                        theRecord[1]  = (([self uniqueIdNumber] & 0xf)<<16);
                        [record replaceBytesInRange:NSMakeRange(8, theSize*sizeof(int32_t))
                                          withBytes:(char*)&theData[index]
                                             length:theSize*sizeof(int32_t)];
                        [circularBuffer writeData:record];
                        index += theSize;
                        totalBytesTransfered += theSize*sizeof(int32_t);
                    }
                    else break;
                }while(index<num/4);
                
            }
        }
        else bufferState = kDT5725BufferEmpty;
        
        //TBD...change to a short interval
        [NSThread sleepForTimeInterval:.001];
        [workerPool release];
    }
    
    self.isDataWorkerRunning = NO;
}


@end

