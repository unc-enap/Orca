//
//  ORDT5720Model.m
//  Orca
//
//  Created by Mark Howe on Wed Mar 12,2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
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
#import "ORDT5720Model.h"
#import "ORUSBInterface.h"
#import "ORDataTypeAssigner.h"
#import "ORDataSet.h"
#import "ORRateGroup.h"
#import "ORSafeCircularBuffer.h"

//connector names
NSString* ORDT5720USBInConnection                     = @"ORDT5720USBInConnection";
NSString* ORDT5720USBNextConnection                   = @"ORDT5720USBNextConnection";

//USB Notifications
NSString* ORDT5720ModelUSBInterfaceChanged            = @"ORDT5720ModelUSBInterfaceChanged";
NSString* ORDT5720ModelLock                           = @"ORDT5720ModelLock";
NSString* ORDT5720ModelSerialNumberChanged            = @"ORDT5720ModelSerialNumberChanged";

//Notifications
NSString* ORDT5720ModelLogicTypeChanged             = @"ORDT5720ModelLogicTypeChanged";
NSString* ORDT5720ZsThresholdChanged                = @"ORDT5720ZsThresholdChanged";
NSString* ORDT5720NumOverUnderZsThresholdChanged    = @"ORDT5720NumOverUnderZsThresholdChanged";
NSString* ORDT5720NlbkChanged                       = @"ORDT5720NlbkChanged";
NSString* ORDT5720NlfwdChanged                      = @"ORDT5720NlfwdChanged";
NSString* ORDT5720ThresholdChanged                  = @"ORDT5720ThresholdChanged";
NSString* ORDT5720NumOverUnderThresholdChanged      = @"ORDT5720NumOverUnderThresholdChanged";
NSString* ORDT5720DacChanged                        = @"ORDT5720DacChanged";
NSString* ORDT5720ModelZsAlgorithmChanged           = @"ORDT5720ModelZsAlgorithmChanged";
NSString* ORDT5720ModelPackedChanged                = @"ORDT5720ModelPackedChanged";
NSString* ORDT5720ModelTrigOnUnderThresholdChanged  = @"ORDT5720ModelTrigOnUnderThresholdChanged";
NSString* ORDT5720ModelTestPatternEnabledChanged    = @"ORDT5720ModelTestPatternEnabledChanged";
NSString* ORDT5720ModelTrigOverlapEnabledChanged    = @"ORDT5720ModelTrigOverlapEnabledChanged";
NSString* ORDT5720ModelEventSizeChanged             = @"ORDT5720ModelEventSizeChanged";
NSString* ORDT5720ModelClockSourceChanged           = @"ORDT5720ModelClockSourceChanged";
NSString* ORDT5720ModelCountAllTriggersChanged      = @"ORDT5720ModelCountAllTriggersChanged";
NSString* ORDT5720ModelGpiRunModeChanged            = @"ORDT5720ModelGpiRunModeChanged";
NSString* ORDT5720ModelTriggerSourceMaskChanged     = @"ORDT5720ModelTriggerSourceMaskChanged";
NSString* ORDT5720ModelExternalTrigEnabledChanged   = @"ORDT5720ModelExternalTrigEnabledChanged";
NSString* ORDT5720ModelSoftwareTrigEnabledChanged   = @"ORDT5720ModelSoftwareTrigEnabledChanged";
NSString* ORDT5720ModelCoincidenceLevelChanged      = @"ORDT5720ModelCoincidenceLevelChanged";
NSString* ORDT5720ModelEnabledMaskChanged           = @"ORDT5720ModelEnabledMaskChanged";
NSString* ORDT5720ModelFpSoftwareTrigEnabledChanged = @"ORDT5720ModelFpSoftwareTrigEnabledChanged";
NSString* ORDT5720ModelFpExternalTrigEnabledChanged = @"ORDT5720ModelFpExternalTrigEnabledChanged";
NSString* ORDT5720ModelTriggerOutMaskChanged        = @"ORDT5720ModelTriggerOutMaskChanged";
NSString* ORDT5720ModelPostTriggerSettingChanged    = @"ORDT5720ModelPostTriggerSettingChanged";
NSString* ORDT5720ModelGpoEnabledChanged            = @"ORDT5720ModelGpoEnabledChanged";
NSString* ORDT5720ModelTtlEnabledChanged            = @"ORDT5720ModelTtlEnabledChanged";

NSString* ORDT5720Chnl                                    = @"ORDT5720Chnl";
NSString* ORDT5720SelectedRegIndexChanged                 = @"ORDT5720SelectedRegIndexChanged";
NSString* ORDT5720SelectedChannelChanged                  = @"ORDT5720SelectedChannelChanged";
NSString* ORDT5720WriteValueChanged                       = @"ORDT5720WriteValueChanged";

NSString* ORDT5720BasicLock                               = @"ORDT5720BasicLock";
NSString* ORDT5720LowLevelLock                            = @"ORDT5720LowLevelLock";
NSString* ORDT5720RateGroupChanged                        = @"ORDT5720RateGroupChanged";
NSString* ORDT5720ModelBufferCheckChanged                 = @"ORDT5720ModelBufferCheckChanged";



static DT5720RegisterNamesStruct reg[kNumberDT5720Registers] = {
//  {regName            addressOffset, accessType, hwReset, softwareReset, clr},
    {@"ZS_Thres",               0x1024,	kReadWrite,	true,	true, 	false},
    {@"ZS_NsAmp",               0x1028,	kReadWrite, true,	true, 	false},
    {@"Thresholds",             0x1080,	kReadWrite, true,	true, 	false},
    {@"Time O/U Threshold",     0x1084,	kReadWrite, true,	true, 	false},
    {@"Status",                 0x1088,	kReadOnly,  true,	true, 	false},
    {@"Firmware Version",       0x108C,	kReadOnly,  false,	false, 	false},
    {@"Buffer Occupancy",       0x1094,	kReadOnly,  true,	true, 	true},
    {@"Dacs",                   0x1098,	kReadWrite, true,	true, 	false},
    {@"Adc Config",             0x109C,	kReadWrite, true,	true, 	false},
    {@"Chan Config",            0x8000,	kReadWrite, true,	true, 	false},
    {@"Chan Config Bit Set",    0x8004,	kWriteOnly, true,	true, 	false},
    {@"Chan Config Bit Clr",    0x8008, kWriteOnly, true,	true, 	false},
    {@"Buffer Organization",    0x800C,	kReadWrite, true,	true, 	false},
    {@"Acq Control",            0x8100,	kReadWrite, true,	true, 	false},
    {@"Acq Status",             0x8104,	kReadOnly,  false,	false, 	false},
    {@"SW Trigger",             0x8108,	kWriteOnly, false,	false, 	false},
    {@"Trig Src Enbl Mask",     0x810C,	kReadWrite, true,	true, 	false},
    {@"FP Trig Out Enbl Mask",  0x8110, kReadWrite, true,  true, 	false},
    {@"Post Trig Setting",      0x8114,	kReadWrite, true,	true, 	false},
    {@"FP I/O Control",         0x811C,	kReadWrite, true,	true, 	false},
    {@"Chan Enable Mask",       0x8120,	kReadWrite, true,	true, 	false},
    {@"ROC FPGA Version",       0x8124,	kReadOnly,  false,	false, 	false},
    {@"Event Stored",           0x812C,	kReadOnly,  true,	true, 	true},
    {@"Board Info",             0x8140,	kReadOnly,  false,	false, 	false},
    {@"Event Size",             0x814C,	kReadOnly,  true,	true, 	true},
    {@"VME Control",            0xEF00,	kReadWrite, true,	false, 	false},
    {@"VME Status",             0xEF04,	kReadOnly,  false,	false, 	false},
    {@"Interrupt Status ID",    0xEF14,	kReadWrite, true,	false, 	false},
    {@"Interrupt Event Num",    0xEF18,	kReadWrite, true,	true, 	false},
    {@"BLT Event Num",          0xEF1C,	kReadWrite, true,	true, 	false},
    {@"Scratch",                0xEF20,	kReadWrite, true,	true, 	false},
    {@"SW Reset",               0xEF24,	kWriteOnly, false,	false, 	false},
    {@"SW Clear",               0xEF28,	kWriteOnly, false,	false, 	false},
    {@"ConfigReload",           0xEF34,	kWriteOnly, false,	false, 	false},
    {@"Config ROM Ver",         0xF030,	kReadOnly,  false,	false, 	false},
    {@"Config ROM Board2",      0xF034,	kReadOnly,  false,	false, 	false}
};


static NSString* DT5720RunModeString[4] = {
    @"Register Controlled",
    @"GPI Controlled",
};

#define FBLT        0x0C    // Ver. 2.3
#define FPBLT       0x0F    // Ver. 2.3

@interface ORDT5720Model (private)
- (void) dataWorker:(NSDictionary*)arg;
@end


@implementation ORDT5720Model

@synthesize isDataWorkerRunning,isTimeToStopDataWorker;

- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self setEnabledMask:0xF];
    [self setEventSize:0xa];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) makeConnectors
{
	ORConnector* connectorObj1 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( 0, [self frame].size.height/2- kConnectorSize/2 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj1 forKey: ORDT5720USBInConnection ];
	[ connectorObj1 setConnectorType: 'USBI' ];
	[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to gpib outputs
	[connectorObj1 setOffColor:[NSColor yellowColor]];
	[ connectorObj1 release ];
	
	ORConnector* connectorObj2 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, [self frame].size.height/2- kConnectorSize/2)
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj2 forKey: ORDT5720USBNextConnection ];
	[ connectorObj2 setConnectorType: 'USBO' ];
	[ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to gpib inputs
	[connectorObj2 setOffColor:[NSColor yellowColor]];
	[ connectorObj2 release ];
}

- (void) makeMainController
{
    [self linkToController:@"ORDT5720Controller"];
}

- (NSString*) helpURL
{
	return @"USB/DT5720.html";
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[usbInterface release];
    [serialNumber release];
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [lastTimeByteTotalChecked release];
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
	[[self objectConnectedTo:ORDT5720USBNextConnection] connectionChanged];
}

-(void) setUpImage
{
	
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
	NSImage* aCachedImage = [NSImage imageNamed:@"DT5720"];
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
	return [NSString stringWithFormat:@"DT5720 (Serial# %@)",[usbInterface serialNumber]];
}

- (NSUInteger) vendorID
{
	return 0x21E1UL; //DT5720
}

- (NSUInteger) productID
{
	return 0x0000UL; //DT5720
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORDT5720USBInConnection];
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
		
		[[NSNotificationCenter defaultCenter] postNotificationName: ORDT5720ModelUSBInterfaceChanged object: self];

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
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for DT5720"] severity:kHardwareAlarm];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelSerialNumberChanged object:self];
	[self checkUSBAlarm];
}

#pragma mark Accessors
//------------------------------
//Reg Channel n ZS_Thres (0x1n24)
- (int) logicType:(unsigned short) i;
{
    return logicType[i];
}

- (void) setLogicType:(unsigned short) i withValue:(int)aLogicType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLogicType:i withValue:[self logicType:i]];
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
    logicType[i] = aLogicType;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelLogicTypeChanged object:self userInfo:userInfo];
}

- (unsigned short) zsThreshold:(unsigned short) i
{
    return zsThresholds[i];
}

- (void) setZsThreshold:(unsigned short) i withValue:(unsigned short) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setZsThreshold:i withValue:[self zsThreshold:i]];
    
    zsThresholds[i] = aValue;
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
    // Send out notification that the value has changed.
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ZsThresholdChanged
                                                        object:self
                                                      userInfo:userInfo];
}

//------------------------------
//Reg Channel n ZS_NSAmp (0x1n28)
- (unsigned short) numOverUnderZsThreshold:(unsigned short) i
{
    return numOverUnderZsThreshold[i];
}

- (void) setNumOverUnderZsThreshold:(unsigned short) i withValue:(unsigned short) aValue
{
    aValue &= 0xFFF;
    if(aValue!=numOverUnderZsThreshold[i]){
        [[[self undoManager] prepareWithInvocationTarget:self] setNumOverUnderZsThreshold:i withValue:numOverUnderZsThreshold[i]];
        numOverUnderZsThreshold[i] = aValue;
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720NumOverUnderZsThresholdChanged
                                                            object:self
                                                          userInfo:userInfo];
    }
}
- (unsigned short)	nLbk:(unsigned short) i
{
    return nLbk[i];
}

- (void) setNlbk:(unsigned short) i withValue:(unsigned short) aValue
{
    if(aValue<1)aValue=1;
    if(aValue!=nLbk[i]){

        [[[self undoManager] prepareWithInvocationTarget:self] setNlbk:i withValue:nLbk[i]];
    
        nLbk[i] = aValue;
    
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720NlbkChanged
                                                            object:self
                                                          userInfo:userInfo];
    }
}

- (unsigned short)	nLfwd:(unsigned short) i
{
    return nLfwd[i];
    
}

- (void) setNlfwd:(unsigned short) i withValue:(unsigned short) aValue
{
    if(aValue<1)aValue=1;
    if(aValue!=nLfwd[i]){
    
        [[[self undoManager] prepareWithInvocationTarget:self] setNlfwd:i withValue:nLfwd[i]];
        nLfwd[i] = aValue;
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720NlfwdChanged
                                                            object:self
                                                          userInfo:userInfo];
    }
}
//------------------------------
//Reg Channel n Threshold (0x1n80)
- (unsigned short) threshold:(unsigned short) i
{
    return thresholds[i];
}

- (void) setThreshold:(unsigned short) i withValue:(unsigned short) aValue
{
    if(aValue!=thresholds[i]){
        [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:i withValue:[self threshold:i]];
    
        thresholds[i] = aValue;
    
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
        // Send out notification that the value has changed.
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ThresholdChanged
                                                            object:self
                                                          userInfo:userInfo];
    }
}
//------------------------------
//Reg Channel n Num Over/Under Threshold (0x1n84)
- (unsigned short) numOverUnderThreshold:(unsigned short) i
{
    return numOverUnderThreshold[i];
}

- (void) setNumOverUnderThreshold:(unsigned short) i withValue:(unsigned short) aValue
{
    aValue &= 0xFFF;
    if(aValue!=numOverUnderThreshold[i]){
        [[[self undoManager] prepareWithInvocationTarget:self] setNumOverUnderThreshold:i withValue:numOverUnderThreshold[i]];
        numOverUnderThreshold[i] = aValue;
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720NumOverUnderThresholdChanged
                                                            object:self
                                                          userInfo:userInfo];
    }
}
//------------------------------
//Reg Channel n DAC (0x1n98)
- (unsigned short) dac:(unsigned short) i
{
    return dac[i];
}

- (void) setDac:(unsigned short) i withValue:(unsigned short) aValue
{

    if(dac[i] != aValue){
        [[[self undoManager] prepareWithInvocationTarget:self] setDac:i withValue:dac[i]];
    
        dac[i] = aValue;
    
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:ORDT5720Chnl];
    
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720DacChanged
                                                            object:self
                                                          userInfo:userInfo];
    }
}

//------------------------------
//Reg Channel Configuration (0x8000)
- (int) zsAlgorithm
{
    return zsAlgorithm;
}

- (void) setZsAlgorithm:(int)aZsAlgorithm
{
    if(aZsAlgorithm!=zsAlgorithm){
        [[[self undoManager] prepareWithInvocationTarget:self] setZsAlgorithm:zsAlgorithm];
        zsAlgorithm = aZsAlgorithm;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelZsAlgorithmChanged object:self];
    }
}

- (BOOL) packed
{
    return packed;
}

- (void) setPacked:(BOOL)aPacked
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPacked:packed];
    packed = aPacked;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelPackedChanged object:self];
}

- (BOOL) trigOnUnderThreshold
{
    return trigOnUnderThreshold;
}

- (void) setTrigOnUnderThreshold:(BOOL)aTrigOnUnderThreshold
{
    if(aTrigOnUnderThreshold!=trigOnUnderThreshold){
        [[[self undoManager] prepareWithInvocationTarget:self] setTrigOnUnderThreshold:trigOnUnderThreshold];
        trigOnUnderThreshold = aTrigOnUnderThreshold;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelTrigOnUnderThresholdChanged object:self];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelTestPatternEnabledChanged object:self];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelTrigOverlapEnabledChanged object:self];
    }
}

//------------------------------
//Reg Buffer Organization (0x800C)
- (int) eventSize
{
    return eventSize;
}

- (void) setEventSize:(int)aEventSize
{
    //if(aEventSize == 0)aEventSize = 0xa; //default
    aEventSize &= 0xF;
    if(aEventSize!=eventSize){
        [[[self undoManager] prepareWithInvocationTarget:self] setEventSize:eventSize];
        eventSize = aEventSize;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelEventSizeChanged object:self];
    }
}
//------------------------------
//Reg Custom Size (0x8020)
//not supported
//------------------------------
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelClockSourceChanged object:self];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelCountAllTriggersChanged object:self];
    }
}

- (BOOL) gpiRunMode
{
    return gpiRunMode;
}

- (void) setGpiRunMode:(BOOL)aGpiRunMode
{
    if(aGpiRunMode!=gpiRunMode){
        [[[self undoManager] prepareWithInvocationTarget:self] setGpiRunMode:gpiRunMode];
        gpiRunMode = aGpiRunMode;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelGpiRunModeChanged object:self];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelSoftwareTrigEnabledChanged object:self];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelExternalTrigEnabledChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelCoincidenceLevelChanged object:self];
}
- (uint32_t) triggerSourceMask
{
    return triggerSourceMask;
}

 - (void) setTriggerSourceMask:(uint32_t)aTriggerSourceMask
{
    aTriggerSourceMask &= 0xf;
    if(aTriggerSourceMask!=triggerSourceMask){
        [[[self undoManager] prepareWithInvocationTarget:self] setTriggerSourceMask:triggerSourceMask];
        triggerSourceMask = aTriggerSourceMask;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelTriggerSourceMaskChanged object:self];
    }
}

//------------------------------
//Reg Front Panel Trigger Out Enable Mask (0x8110)
- (BOOL) fpSoftwareTrigEnabled
{
    return fpSoftwareTrigEnabled;
}

- (void) setFpSoftwareTrigEnabled:(BOOL)aFpSoftwareTrigEnabled
{
    if(aFpSoftwareTrigEnabled!=fpSoftwareTrigEnabled){
        [[[self undoManager] prepareWithInvocationTarget:self] setFpSoftwareTrigEnabled:fpSoftwareTrigEnabled];
        fpSoftwareTrigEnabled = aFpSoftwareTrigEnabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelFpSoftwareTrigEnabledChanged object:self];
    }
}

- (BOOL) fpExternalTrigEnabled
{
    return fpExternalTrigEnabled;
}

- (void) setFpExternalTrigEnabled:(BOOL)aFpExternalTrigEnabled
{
    if(aFpExternalTrigEnabled!=fpExternalTrigEnabled){
        [[[self undoManager] prepareWithInvocationTarget:self] setFpExternalTrigEnabled:fpExternalTrigEnabled];
        fpExternalTrigEnabled = aFpExternalTrigEnabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelFpExternalTrigEnabledChanged object:self];
    }
}

- (uint32_t) triggerOutMask
{
    return triggerOutMask;
}

- (void) setTriggerOutMask:(uint32_t)aTriggerOutMask
{
    aTriggerOutMask &= 0xf;
    if(aTriggerOutMask!=triggerOutMask){
        [[[self undoManager] prepareWithInvocationTarget:self] setTriggerOutMask:triggerOutMask];
        triggerOutMask = aTriggerOutMask;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelTriggerOutMaskChanged object:self];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelPostTriggerSettingChanged object:self];
    }
}
//------------------------------
//Reg Front Panel I/O Setting (0x811C)
- (BOOL) gpoEnabled
{
    return gpoEnabled;
}

- (void) setGpoEnabled:(BOOL)aGpoEnabled
{
    if(aGpoEnabled!=gpoEnabled){
        [[[self undoManager] prepareWithInvocationTarget:self] setGpoEnabled:gpoEnabled];
        gpoEnabled = aGpoEnabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelGpoEnabledChanged object:self];
    }
}

- (int) ttlEnabled
{
    return ttlEnabled;
}

- (void) setTtlEnabled:(int)aTtlEnabled
{
    if(aTtlEnabled!=ttlEnabled){
        [[[self undoManager] prepareWithInvocationTarget:self] setTtlEnabled:ttlEnabled];
        ttlEnabled = aTtlEnabled;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelTtlEnabledChanged object:self];
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
    aEnabledMask &= 0xf;
    if(aEnabledMask!=enabledMask){
        [[[self undoManager] prepareWithInvocationTarget:self] setEnabledMask:enabledMask];
        enabledMask = aEnabledMask;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelEnabledMaskChanged object:self];
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
		if(counterTag>=0 && counterTag<kNumDT5720Channels){
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
	 postNotificationName:ORDT5720RateGroupChanged
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720SelectedRegIndexChanged object:self];
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
        [[NSNotificationCenter defaultCenter]postNotificationName:ORDT5720SelectedChannelChanged object:self];
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
        [[NSNotificationCenter defaultCenter]postNotificationName:ORDT5720WriteValueChanged object:self];
    }
}

#pragma mark ***Register - General routines
- (short) getNumberRegisters
{
    return kNumberDT5720Registers;
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
        if (theRegIndex >= kZS_Thres && theRegIndex<=kAdcConfig){
            start = theChannelIndex;
            end = theChannelIndex;
            if(theChannelIndex >= kNumDT5720Channels) {
                start = 0;
                end = kNumDT5720Channels - 1;
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
        
        if (theRegIndex >= kZS_Thres && theRegIndex<=kAdcConfig){
            start	= theChannelIndex;
            end 	= theChannelIndex;
            if(theChannelIndex >= kNumDT5720Channels){
				NSLog(@"Channel: ALL\n");
                start = 0;
                end = kNumDT5720Channels - 1;
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
	uint32_t enabled, threshold, numOU, status, bufferOccupancy, dacValue,triggerSrc;
	[self read:kChanEnableMask returnValue:&enabled];
	[self read:kTrigSrcEnblMask returnValue:&triggerSrc];
	int chan;
    NSFont* theFont = [NSFont fontWithName:@"Monaco" size:10];
	NSLogFont(theFont,@"-----------------------------------------------------------\n");
	NSLogFont(theFont,@"Chan Enabled Thres  NumOver Status Buffers  Offset trigSrc\n");
	NSLogFont(theFont,@"-----------------------------------------------------------\n");
	for(chan=0;chan<kNumDT5720Channels;chan++){
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
		NSLogFont(theFont,@"  %d     %@    %d  %d  %@  %d  %6.3f  %@\n",
				  chan, enabled&(1<<chan)?@"E":@"X",
				  threshold&0xfff, numOU&0xfff,statusString,
				  bufferOccupancy&0x7ff, [self convertDacToVolts:dacValue],
				  triggerSrc&(1<<chan)?@"Y":@"N");
	}
	NSLogFont(theFont,@"-----------------------------------------------------------\n");
	
    uint32_t zThres,nsAmp;
    NSLogFont(theFont,@"-----------------------------------------------------------\n");
    NSLogFont(theFont,@"                    Zeros Suppression                      \n");
    NSLogFont(theFont,@"Chan logic  Thres     NumOver \n");
    NSLogFont(theFont,@"-----------------------------------------------------------\n");
    for(chan=0;chan<kNumDT5720Channels;chan++){
        [self readChan:chan reg:kZS_Thres returnValue:&zThres];
        [self readChan:chan reg:kZS_NsAmp returnValue:&nsAmp];
        NSLogFont(theFont,@" %d   %@    %d    %d\n",
                  chan, zThres>>31?@"Neg":@"Pos",zThres&0xFFF,nsAmp&0xFFF);
    }
    NSLogFont(theFont,@"-----------------------------------------------------------\n");
    
	uint32_t aValue;
	[self read:kBufferOrganization returnValue:&aValue];
	NSLogFont(theFont,@"# Buffer Blocks : %d\n",(int32_t)powf(2.,(float)aValue));
	
	NSLogFont(theFont,@"Software Trigger: %@\n",triggerSrc&0x80000000?@"Enabled":@"Disabled");
	NSLogFont(theFont,@"External Trigger: %@\n",triggerSrc&0x40000000?@"Enabled":@"Disabled");
	NSLogFont(theFont,@"Trigger nHit    : %d\n",(triggerSrc >> 24) & 0x3);
	
	
	[self read:kAcqControl returnValue:&aValue];
	NSLogFont(theFont,@"Triggers Count  : %@\n",aValue&0x4?@"Accepted":@"All");
	NSLogFont(theFont,@"Run Mode        : %@\n",DT5720RunModeString[aValue&0x3]);
		
	[self read:kAcqStatus returnValue:&aValue];
	NSLogFont(theFont,@"Board Ready     : %@\n",aValue&0x100?@"YES":@"NO");
	NSLogFont(theFont,@"PLL Locked      : %@\n",aValue&0x80?@"YES":@"NO");
	NSLogFont(theFont,@"PLL Bypass      : %@\n",aValue&0x40?@"YES":@"NO");
	NSLogFont(theFont,@"Clock source    : %@\n",aValue&0x20?@"External":@"Internal");
	NSLogFont(theFont,@"Buffer full     : %@\n",aValue&0x10?@"YES":@"NO");
	NSLogFont(theFont,@"Events Ready    : %@\n",aValue&0x08?@"YES":@"NO");
	NSLogFont(theFont,@"Run             : %@\n",aValue&0x04?@"ON":@"OFF");
	
	[self read:kEventStored returnValue:&aValue];
	NSLogFont(theFont,@"Events Stored   : %d\n",aValue);
	
}

- (void) initBoard
{
    [self readConfigurationROM];
    [self writeAcquistionControl:NO]; // Make sure it's off.
    [self clearAllMemory];
    [self writeBufferOrganization];
    [self writeZSThresholds];
    [self writeZSAmplReg];
    [self writeThresholds];
    [self writeNumOverUnderThresholds];
    [self writeDacs];
	[self writeChannelConfiguration];
    [self writeTriggerSourceEnableMask];
    [self writeFrontPanelTriggerOutEnableMask];
    [self writePostTriggerSetting];
    [self writeFrontPanelIOControl];
	[self writeChannelEnabledMask];
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
        NSLog(@"DT5720 write scratch register at address: 0x%04x failed\n", reg[kScratch].addressOffset);
        return;
    }
    
    value = 0;
    err = [self readLongBlock:&value atAddress:reg[kScratch].addressOffset];
    if (err) {
        NSLog(@"DT5720 read scratch register at address: 0x%04x failed\n", reg[kScratch].addressOffset);
        return;
    }
    if (value != 0xCC00FFEE) {
        NSLog(@"DT5720 read scratch register returned bad value: 0x%08x, expected: 0xCC00FFEE\n");
        return;
    }

    //get digitizer version
    value = 0;
    err = [self readLongBlock:&value atAddress:reg[kConfigROMVersion].addressOffset];
    if (err) {
        NSLog(@"DT5720 read configuration ROM version at address: 0x%04x failed\n", reg[kConfigROMVersion].addressOffset);
        return;
    }
    switch (value & 0xFF) {
        case 0x30: //DT5720 tested. 4 Ch. 12 bit 250 MS/s Digitizer: 1.25MS/ch, C4, SE
            break;

        case 0x32:
            NSLog(@"Warning: DT5720B/C is not tested\n");
            //DT5720B is 4 Ch. 12 bit 250 MS/s Digitizer: 1.25MS/ch, C20, SE, i.e., different FPGA
            //DT5720C is 2 Ch. 12 bit 250 MS/s Digitizer: 1.25MS/ch, C20, SE
            //unlikely to work without testing
            break;

        case 0x34:
            NSLog(@"Warning: DT5720A is not tested\n");
            //DT5720A is 2 Ch. 12 bit 250 MS/s Digitizer: 1.25MS/ch, C4, SE
            //should work fine
            //todo: reduce number of channels in UI
            break;

        case 0x38:
            NSLog(@"Warning: DT5720D is not tested\n");
            //DT5720D is 4 Ch. 12 bit 250 MS/s Digitizer: 10MS/ch, C20, SE, i.e., different FPGA and RAM
            //unlikely to work
            break;

        case 0x39:
            NSLog(@"Warning: DT5720E is not tested\n");
            //DT5720E is 2 Ch. 12 bit 250 MS/s Digitizer: 10MS/ch, C20, SE; two channel version of D
            break;

        default:
            NSLog(@"Warning: unknown digitizer version read from its configuration ROM.\n");
            break;
    }
    
    //check board ID
    value = 0;
    err = [self readLongBlock:&value atAddress:reg[kConfigROMBoard2].addressOffset];
    if (err) {
        NSLog(@"DT5720 read configuration ROM Board2 at address: 0x%04x failed\n", reg[kConfigROMBoard2].addressOffset);
        return;
    }
    switch (value & 0xFF) {
        case 0x02: //DT5720x
            break;
            
        default:
            NSLog(@"Warning: unknown digitizer Board2 ID read from its configuration ROM.\n");
            break;
    }
}

#pragma mark ***HW Reg Access
- (void) writeZSThresholds
{
    short	i;
    for (i=0;i<kNumDT5720Channels;i++){
        [self writeZSThreshold:i];
    }
}

- (void) writeZSThreshold:(unsigned short) i
{
    uint32_t aValue = 0;
    aValue |= logicType[i]<<31;
    aValue |= [self zsThreshold:i] & 0xFFF;
    
    [self writeLongBlock:&aValue
               atAddress:reg[kZS_Thres].addressOffset + (i * 0x100)];
}

- (void) writeZSAmplReg
{
    short	i;
    for (i=0;i<kNumDT5720Channels;i++){
        [self writeZSAmplReg:i];
    }
}

- (void) writeZSAmplReg:(unsigned short) i
{
    
    if(zsAlgorithm == kFullSuppressionBasedOnAmplitude){
        uint32_t 	aValue = [self numOverUnderZsThreshold:i] & 0xFFFFF;
    
        [self writeLongBlock:&aValue
                   atAddress:reg[kZS_NsAmp].addressOffset + (i * 0x100)];
    }
    else if(zsAlgorithm == kZeroLengthEncoding){
        uint32_t aValue = ([self nLbk:i] & 0xFFFF)<<16 |
                               ([self nLfwd:i]& 0xFFFF);
        [self writeLongBlock:&aValue
                   atAddress:reg[kZS_NsAmp].addressOffset + (i * 0x100)];
    }

}

- (void) writeThresholds
{
    short	i;
    for (i = 0; i < kNumDT5720Channels; i++){
        [self writeThreshold:i];
    }
}

- (void) writeThreshold:(unsigned short) i
{
    uint32_t 	aValue = [self threshold:i];
    [self writeLongBlock:&aValue
               atAddress:reg[kThresholds].addressOffset + (i * 0x100)];
}

- (void) writeNumOverUnderThresholds
{
    short	i;
    for (i = 0; i < kNumDT5720Channels; i++){
        [self writeNumOverUnderThreshold:i];
    }
}
- (void) writeNumOverUnderThreshold:(unsigned short) i
{
    uint32_t 	aValue = [self numOverUnderThreshold:i];
    [self writeLongBlock:&aValue
               atAddress:reg[kNumOUThreshold].addressOffset + (i * 0x100)];
}

- (void) writeDacs
{
    short	i;
    for (i = 0; i < kNumDT5720Channels; i++){
        [self writeDac:i];
    }
    //dac take effect only when
}

- (void) writeDac:(unsigned short) i
{
    uint32_t 	aValue = [self dac:i];
    [self writeLongBlock:&aValue
               atAddress:reg[kDacs].addressOffset + (i * 0x100)];
}

- (void) writeChannelConfiguration
{
    uint32_t mask = 0;
    if(zsAlgorithm == kNoZeroSuppression)  mask |= (0x0   << 16);
    else if(zsAlgorithm == kZeroLengthEncoding) mask |= (0x2   << 16);
    else                                   mask |= (0x3   << 16);
    mask |= (packed & 0x1)                << 11;
    mask |= (trigOnUnderThreshold & 0x1)  <<  6;
    mask |= 0x1                           <<  4; //reserved bit (MUST be one)
    mask |= (testPatternEnabled & 0x1)    <<  3;
    mask |= (trigOverlapEnabled & 0x1)    <<  1;
    
    [self writeLongBlock:&mask
               atAddress:reg[kChanConfig].addressOffset];
}

- (void) writeBufferOrganization
{
    uint32_t aValue = eventSize & 0xf; //(uint32_t)pow(2.,(float)eventSize);
    [self writeLongBlock:&aValue
               atAddress:reg[kBufferOrganization].addressOffset];
}


- (void) writeAcquistionControl:(BOOL)start
{
    uint32_t aValue = 0;
    aValue |= (clockSource & 0x1)       << 6;
    aValue |= (countAllTriggers & 0x1)  << 3;
    if(start) aValue |= (0x1 << 2);
    aValue |= (gpiRunMode & 0x1)        << 0;
    
    [self writeLongBlock:&aValue
               atAddress:reg[kAcqControl].addressOffset];
    
}

- (void) trigger
{
    uint32_t aValue = 0;
    [self writeLongBlock:&aValue
               atAddress:reg[kSWTrigger].addressOffset];
   
}

- (void) writeTriggerSourceEnableMask
{
    uint32_t aValue = 0;
    aValue |= (softwareTrigEnabled & 0x1) << 31;
    aValue |= (externalTrigEnabled & 0x1) << 30;
    aValue |= (coincidenceLevel    & 0x7) << 24;
    aValue |= (triggerSourceMask   & 0xf) <<  0;
    
    [self writeLongBlock:&aValue
               atAddress:reg[kTrigSrcEnblMask].addressOffset];
}

- (void) writeFrontPanelIOControl
{
    uint32_t aValue = 0;
    aValue |= (gpoEnabled & 0x1) << 1;
    aValue |= (ttlEnabled & 0x1) << 0;
    
    [self writeLongBlock:&aValue
               atAddress:reg[kFPIOControl].addressOffset];
  
}

- (void) writeFrontPanelTriggerOutEnableMask
{
    uint32_t aValue = 0;
    aValue = (fpSoftwareTrigEnabled & 0x1) << 31;
    aValue = (fpExternalTrigEnabled & 0x1) << 30;
    aValue = (triggerOutMask        & 0xf) <<  0;
    
    [self writeLongBlock:&aValue
               atAddress:reg[kFPTrigOutEnblMask].addressOffset];
}

- (void) writePostTriggerSetting
{
    uint32_t aValue = postTriggerSetting/4;
    if(packed)aValue = aValue*1.25;
    
    [self writeLongBlock:&aValue
               atAddress:reg[kPostTrigSetting].addressOffset];
    
}

- (void) writeChannelEnabledMask
{
    uint32_t aValue = enabledMask & 0xf;
    [self writeLongBlock:&aValue
               atAddress:reg[kChanEnableMask].addressOffset];
    
}

- (void) writeNumBLTEventsToReadout
{
    uint32_t aValue = pow(2.,eventSize);
    [self writeLongBlock:&aValue
               atAddress:reg[kBLTEventNum].addressOffset];
}

- (void) softwareReset
{
    uint32_t aValue = 0;
    [self writeLongBlock:&aValue
               atAddress:reg[kSWReset].addressOffset];
    
}

- (void) clearAllMemory
{
    uint32_t aValue = 0;
    [self writeLongBlock:&aValue
               atAddress:reg[kSWClear].addressOffset];
    
}
- (void) configReload
{
    uint32_t aValue = 0;
    [self writeLongBlock:&aValue
               atAddress:reg[kSWClear].addressOffset];
    
}

- (void) checkBufferAlarm
{
    if((bufferState == kDT5720BufferFull) && isRunning){
        bufferEmptyCount = 0;
        if(!bufferFullAlarm){
            NSString* alarmName = [NSString stringWithFormat:@"Buffer FULL DT5720 (%@)",[self fullID]];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDT5720ModelBufferCheckChanged object:self];
}


#pragma mark ***Helpers
- (float) convertDacToVolts:(unsigned short)aDacValue
{
	return 2*(aDacValue/65535.) - 1.0;
}

- (unsigned short) convertVoltsToDac:(float)aVoltage
{
	return (unsigned short)(65535 * (aVoltage+1.0)/2.);
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
    for(i=0;i<kNumDT5720Channels;i++){
        waveFormCount[i]=0;
    }
}

- (void) reset
{
}

- (NSString*) identifier
{
	return [NSString stringWithFormat:@"DT5720 %u",[self uniqueIdNumber]];
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
								 @"ORDT5720Decoder", @"decoder",
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
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORDT5720Model"];    
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
    cachedPack = packed;
    
    [NSThread detachNewThreadSelector:@selector(dataWorker:) toTarget:self withObject:nil];
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(firstTime){
        firstTime = NO;
        [self writeAcquistionControl:YES];
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
    [self writeAcquistionControl:NO];

    self.isTimeToStopDataWorker = YES;
    while (self.isDataWorkerRunning) {
        [NSThread sleepForTimeInterval:.001];
    }
    [circularBuffer release];
    circularBuffer = nil;
}

- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
    [waveFormRateGroup stop];
    short i;
    for(i=0;i<kNumDT5720Channels;i++)waveFormCount[i] = 0;
    
    [self writeAcquistionControl:NO];
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
		NSLog(@"DT5720 failed write request at address: 0x%08x failed\n", anAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}

    unsigned short status = 0;
    
    int num_read = 0;
    @try {
        num_read = [[self usbInterface] readBytes:&status length:sizeof(status) pipe:0];
	}
    @catch (NSException* e) {
		NSLog(@"DT5720 failed write respond at address: 0x%08x\n", anAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
	}
    
    if (num_read != 2 || status & 0x20) {
		NSLog(@"DT5720 failed write at address: 0x%08x\n", anAddress);
		NSLog(@"DT5720 returned with bus error\n");
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
		NSLog(@"DT5720 failed read request at address: 0x%08x failed\n", anAddress);
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
		NSLog(@"DT5720 failed read respond at address: 0x%08x\n", anAddress);
		NSLog(@"Error: %@ with reason: %@\n", [e name], [e reason]);
        return -1;
	}
    
    if (num_read != 6 || (resp.status & 0x20)) {
		NSLog(@"DT5720 failed read at address: 0x%08x\n", anAddress);
		NSLog(@"DT5720 returned with bus error\n");
        return num_read;
    }
    
    *readValue = resp.value;
    return 0;
}

//returns 0 if success; -1 if request fails, and number of bytes returned by digitizer otherwise
- (int) readFifo:(char*)readBuffer numBytesToRead:(uint32_t)    numBytes
{
    uint32_t fifoAddress = 0x0000;
    
    if (numBytes == 0) return 0;
    int maxBLTSize = 0x100000; //8 MBytes
    numBytes = (numBytes + 7) & ~7UL;

    int np = (int)(numBytes/maxBLTSize);
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
        num_read = [[self usbInterface] readBytes:readBuffer length:(uint32_t)numBytes+2 pipe:0];
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
    [self setZsAlgorithm:           [aDecoder decodeIntForKey:      @"zsAlgorithm"]];
    [self setPacked:                [aDecoder decodeBoolForKey:     @"packed"]];
    [self setTrigOnUnderThreshold:  [aDecoder decodeBoolForKey:     @"trigOnUnderThreshold"]];
    [self setTestPatternEnabled:    [aDecoder decodeBoolForKey:     @"testPatternEnabled"]];
    [self setTrigOverlapEnabled:    [aDecoder decodeBoolForKey:     @"trigOverlapEnabled"]];
    [self setEventSize:             [aDecoder decodeIntForKey:      @"eventSize"]];
    [self setClockSource:           [aDecoder decodeBoolForKey:     @"clockSource"]];
    [self setCountAllTriggers:      [aDecoder decodeBoolForKey:     @"countAllTriggers"]];
    [self setGpiRunMode:            [aDecoder decodeBoolForKey:     @"gpiRunMode"]];
    [self setSoftwareTrigEnabled:   [aDecoder decodeBoolForKey:     @"softwareTrigEnabled"]];
    [self setExternalTrigEnabled:   [aDecoder decodeBoolForKey:     @"externalTrigEnabled"]];
    [self setTriggerSourceMask:     [aDecoder decodeIntForKey:      @"triggerSourceMask"]];
    [self setFpExternalTrigEnabled: [aDecoder decodeBoolForKey:     @"fpExternalTrigEnabled"]];
    [self setFpSoftwareTrigEnabled: [aDecoder decodeBoolForKey:     @"fpSoftwareTrigEnabled"]];
    [self setTriggerOutMask:        [aDecoder decodeIntForKey:      @"triggerOutMask"]];
    [self setPostTriggerSetting:    [aDecoder decodeIntForKey:    @"postTriggerSetting"]];
    [self setGpoEnabled:            [aDecoder decodeBoolForKey:     @"gpoEnabled"]];
    [self setTtlEnabled:            [aDecoder decodeIntForKey:      @"ttlEnabled"]];
    [self setEnabledMask:           [aDecoder decodeIntegerForKey:      @"enabledMask"]];

    [self setCoincidenceLevel:      [aDecoder decodeIntegerForKey:      @"coincidenceLevel"]];
    [self setWaveFormRateGroup:     [aDecoder decodeObjectForKey:   @"waveFormRateGroup"]];
    
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:8 groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	int i;
    for (i = 0; i < kNumDT5720Channels; i++){
        [self setLogicType:i    withValue:           [aDecoder decodeIntForKey:  [NSString stringWithFormat:@"logicType%d", i]]];
        [self setZsThreshold:i  withValue:           [aDecoder decodeIntegerForKey:  [NSString stringWithFormat:@"zsThreshold%d", i]]];
        [self setThreshold:i    withValue:           [aDecoder decodeIntegerForKey:  [NSString stringWithFormat:@"threshold%d", i]]];
        [self setNumOverUnderZsThreshold:i withValue:[aDecoder decodeIntegerForKey:  [NSString stringWithFormat:@"numOverUnderZsThreshold%d", i]]];
        [self setNlbk:i         withValue:           [aDecoder decodeIntegerForKey:  [NSString stringWithFormat:@"nLbk%d", i]]];
        [self setNlfwd:i        withValue:           [aDecoder decodeIntegerForKey:  [NSString stringWithFormat:@"nLfwd%d", i]]];
        [self setNumOverUnderThreshold:i withValue:  [aDecoder decodeIntegerForKey:  [NSString stringWithFormat:@"numOverUnderThreshold%d", i]]];
        [self setDac:i          withValue:           [aDecoder decodeIntegerForKey:  [NSString stringWithFormat:@"dac%d", i]]];
    }
    
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)anEncoder
{
    [super encodeWithCoder:anEncoder];
    
    [anEncoder encodeInteger: zsAlgorithm               forKey:@"zsAlgorithm"];
    [anEncoder encodeBool:packed                    forKey:@"packed"];
    [anEncoder encodeBool:trigOnUnderThreshold      forKey:@"trigOnUnderThreshold"];
    [anEncoder encodeBool:testPatternEnabled        forKey:@"testPatternEnabled"];
    [anEncoder encodeBool:trigOverlapEnabled        forKey:@"trigOverlapEnabled"];
    [anEncoder encodeInteger:eventSize                  forKey:@"eventSize"];
    [anEncoder encodeBool:clockSource               forKey:@"clockSource"];
    [anEncoder encodeBool:countAllTriggers          forKey:@"countAllTriggers"];
    [anEncoder encodeBool:gpiRunMode                forKey:@"gpiRunMode"];
    [anEncoder encodeBool:softwareTrigEnabled       forKey:@"softwareTrigEnabled"];
    [anEncoder encodeBool:externalTrigEnabled       forKey:@"externalTrigEnabled"];
    [anEncoder encodeInt:triggerSourceMask          forKey:@"triggerSourceMask"];
    [anEncoder encodeBool:fpExternalTrigEnabled     forKey:@"fpExternalTrigEnabled"];
    [anEncoder encodeBool:fpSoftwareTrigEnabled     forKey:@"fpSoftwareTrigEnabled"];
    [anEncoder encodeInt:postTriggerSetting       forKey:@"postTriggerSetting"];
    [anEncoder encodeBool:gpoEnabled                forKey:@"gpoEnabled"];
    [anEncoder encodeInteger:ttlEnabled                 forKey:@"ttlEnabled"];
    [anEncoder encodeInt:triggerOutMask             forKey:@"triggerOutMask"];
    [anEncoder encodeInteger:enabledMask                forKey:@"enabledMask"];

	[anEncoder encodeInteger:coincidenceLevel           forKey:@"coincidenceLevel"];
    [anEncoder encodeObject:waveFormRateGroup       forKey:@"waveFormRateGroup"];
    
	int i;
	for (i = 0; i < kNumDT5720Channels; i++){
        [anEncoder encodeInteger:logicType[i]               forKey:[NSString stringWithFormat:@"logicType%d", i]];
        [anEncoder encodeInteger:zsThresholds[i]            forKey:[NSString stringWithFormat:@"zsThreshold%d", i]];
        [anEncoder encodeInteger:numOverUnderZsThreshold[i] forKey:[NSString stringWithFormat:@"numOverUnderZsThreshold%d", i]];
        [anEncoder encodeInteger:nLbk[i]                    forKey:[NSString stringWithFormat:@"nLbk%d", i]];
        [anEncoder encodeInteger:nLfwd[i]                   forKey:[NSString stringWithFormat:@"nLfwd%d", i]];
        [anEncoder encodeInteger:thresholds[i]              forKey:[NSString stringWithFormat:@"threshold%d", i]];
        [anEncoder encodeInteger:numOverUnderThreshold[i]   forKey:[NSString stringWithFormat:@"numOverUnderThreshold%d", i]];
        [anEncoder encodeInteger:dac[i]                     forKey:[NSString stringWithFormat:@"dac%d", i]];
    }
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    
    [objDictionary setObject:[NSNumber numberWithInt:zsAlgorithm]           forKey:@"zsAlgorithm"];
    [objDictionary setObject:[NSNumber numberWithInt:trigOverlapEnabled]    forKey:@"trigOverlapEnabled"];
    [objDictionary setObject:[NSNumber numberWithInt:testPatternEnabled]    forKey:@"testPatternEnabled"];
    [objDictionary setObject:[NSNumber numberWithInt:trigOnUnderThreshold]  forKey:@"trigOnUnderThreshold"];
    [objDictionary setObject:[NSNumber numberWithInt:clockSource]           forKey:@"clockSource"];
    [objDictionary setObject:[NSNumber numberWithInt:packEnabled]           forKey:@"packEnabled"];
    [objDictionary setObject:[NSNumber numberWithInt:gpiRunMode]            forKey:@"gpiRunMode"];
    [objDictionary setObject:[NSNumber numberWithInt:softwareTrigEnabled]   forKey:@"softwareTrigEnabled"];
    [objDictionary setObject:[NSNumber numberWithInt:externalTrigEnabled]   forKey:@"externalTrigEnabled"];
    [objDictionary setObject:[NSNumber numberWithInt:fpExternalTrigEnabled] forKey:@"fpExternalTrigEnabled"];
    [objDictionary setObject:[NSNumber numberWithInt:fpSoftwareTrigEnabled] forKey:@"fpSoftwareTrigEnabled"];
    [objDictionary setObject:[NSNumber numberWithInt:gpoEnabled]            forKey:@"gpoEnabled"];
    [objDictionary setObject:[NSNumber numberWithInt:ttlEnabled]            forKey:@"ttlEnabled"];
    [objDictionary setObject:[NSNumber numberWithInt:(int32_t)triggerSourceMask]     forKey:@"triggerSourceMask"];
    [objDictionary setObject:[NSNumber numberWithInt:countAllTriggers]      forKey:@"countAllTriggers"];
    [objDictionary setObject:[NSNumber numberWithInt:coincidenceLevel]      forKey:@"coincidenceLevel"];
    [objDictionary setObject:[NSNumber numberWithInt:(int32_t)triggerOutMask]        forKey:@"triggerOutMask"];
    [objDictionary setObject:[NSNumber numberWithInt:(int32_t)postTriggerSetting]    forKey:@"postTriggerSetting"];
    [objDictionary setObject:[NSNumber numberWithInt:enabledMask]           forKey:@"enabledMask"];
    [objDictionary setObject:[NSNumber numberWithInt:eventSize]             forKey:@"eventSize"];
    
    [self addCurrentState:objDictionary cArray:(int32_t*)zsThresholds         forKey:@"zsThresholds"];
    [self addCurrentState:objDictionary cArray:(int32_t*)thresholds           forKey:@"thresholds"];
    [self addCurrentState:objDictionary cArray:(int32_t*)nLbk                 forKey:@"nLbk"];
    [self addCurrentState:objDictionary cArray:(int32_t*)nLfwd                forKey:@"nLfwd"];
    [self addCurrentState:objDictionary cArray:(int32_t*)logicType            forKey:@"logicType"];
    [self addCurrentState:objDictionary cArray:(int32_t*)dac                  forKey:@"dac"];
    
    [self addCurrentState:objDictionary cArray:(int32_t*)numOverUnderThreshold    forKey:@"numOverUnderThreshold"];
    [self addCurrentState:objDictionary cArray:(int32_t*)numOverUnderZsThreshold  forKey:@"numOverUnderZsThreshold"];

    
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(int32_t*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumDT5720Channels;i++){
        [ar addObject:[NSNumber numberWithLong:*anArray]];
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

@implementation ORDT5720Model (private)
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
            if((acqStatus >> 4) & 0x1) bufferState = kDT5720BufferFull;
            else                       bufferState = kDT5720BufferReady;
            
            
            uint32_t* theData = (uint32_t*)[eventData bytes];
            uint32_t num     = (uint32_t)[self readFifo:(char*)theData numBytesToRead:(uint32_t)[eventData length]];
            if(num>0){
                uint32_t index=0;
                do {
                    if((theData[index]>>28 & 0xf) == 0xA){
                        uint32_t theSize = theData[index] & 0xfffffff;
                        NSMutableData* record = [NSMutableData dataWithCapacity:(theSize+2)*sizeof(int32_t)];
                        [record setLength:(theSize+2)*sizeof(int32_t)];
                        uint32_t* theRecord = (uint32_t*)[record bytes];
                        theRecord[0]  = dataId | theSize+2;
                        theRecord[1]  = (([self uniqueIdNumber] & 0xf)<<16) |
                                        ((cachedPack            & 0x1)<< 0) ;

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
        else bufferState = kDT5720BufferEmpty;
        
        //TBD...change to a short interval
        [NSThread sleepForTimeInterval:.001];
        [workerPool release];
    }
    
    self.isDataWorkerRunning = NO;
}


@end

