//
//  ORLabJackModel.m
//  Orca
//
//  Created by Mark Howe on Tues Nov 09,2010.
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
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
#import "ORLabJackModel.h"
#import "ORUSBInterface.h"
#import "NSNotifications+Extensions.h"
#import "ORDataTypeAssigner.h"

NSString* ORLabJackModelDeviceSerialNumberChanged = @"ORLabJackModelDeviceSerialNumberChanged";
NSString* ORLabJackModelInvolvedInProcessChanged = @"ORLabJackModelInvolvedInProcessChanged";
NSString* ORLabJackModelAOut1Changed			= @"ORLabJackModelAOut1Changed";
NSString* ORLabJackModelAOut0Changed			= @"ORLabJackModelAOut0Changed";
NSString* ORLabJackShipDataChanged				= @"ORLabJackShipDataChanged";
NSString* ORLabJackDigitalOutputEnabledChanged	= @"ORLabJackDigitalOutputEnabledChanged";
NSString* ORLabJackCounterChanged				= @"ORLabJackCounterChanged";
NSString* ORLabJackSerialNumberChanged			= @"ORLabJackSerialNumberChanged";
NSString* ORLabJackUSBInterfaceChanged			= @"ORLabJackUSBInterfaceChanged";
NSString* ORLabJackUSBInConnection				= @"ORLabJackUSBInConnection";
NSString* ORLabJackUSBNextConnection			= @"ORLabJackUSBNextConnection";
NSString* ORLabJackLock							= @"ORLabJackLock";
NSString* ORLabJackChannelNameChanged			= @"ORLabJackChannelNameChanged";
NSString* ORLabJackChannelUnitChanged			= @"ORLabJackChannelUnitChanged";
NSString* ORLabJackAdcChanged					= @"ORLabJackAdcChanged";
NSString* ORLabJackGainChanged					= @"ORLabJackGainChanged";
NSString* ORLabJackDoNameChanged				= @"ORLabJackDoNameChanged";
NSString* ORLabJackIoNameChanged				= @"ORLabJackIoNameChanged";
NSString* ORLabJackDoDirectionChanged			= @"ORLabJackDoDirectionChanged";
NSString* ORLabJackIoDirectionChanged			= @"ORLabJackIoDirectionChanged";
NSString* ORLabJackDoValueOutChanged			= @"ORLabJackDoValueOutChanged";
NSString* ORLabJackIoValueOutChanged			= @"ORLabJackIoValueOutChanged";
NSString* ORLabJackDoValueInChanged				= @"ORLabJackDoValueInChanged";
NSString* ORLabJackIoValueInChanged				= @"ORLabJackIoValueInChanged";
NSString* ORLabJackPollTimeChanged				= @"ORLabJackPollTimeChanged";
NSString* ORLabJackHiLimitChanged				= @"ORLabJackHiLimitChanged";
NSString* ORLabJackLowLimitChanged				= @"ORLabJackLowLimitChanged";
NSString* ORLabJackAdcDiffChanged				= @"ORLabJackAdcDiffChanged";
NSString* ORLabJackSlopeChanged					= @"ORLabJackSlopeChanged";
NSString* ORLabJackInterceptChanged				= @"ORLabJackInterceptChanged";
NSString* ORLabJackMinValueChanged				= @"ORLabJackMinValueChanged";
NSString* ORLabJackMaxValueChanged				= @"ORLabJackMaxValueChanged";

#define kLabJackU12DriverPath @"/System/Library/Extensions/LabJackU12.kext"
@interface ORLabJackModel (private)
- (void) readPipeThread;
- (void) firstWrite;
- (void) writeData:(unsigned char*) data;
- (void) pollHardware;
- (void) sendIoControl;
- (void) readAdcValues;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(int*)anArray forKey:(NSString*)aKey;
@end

#define kLabJackDataSize 17

@implementation ORLabJackModel
- (id)init
{
	self = [super init];
	int i;
	for(i=0;i<8;i++){
		lowLimit[i] = -10;
		hiLimit[i]  = 10;
		minValue[i] = -10;
		maxValue[i]  = 10;
		//default to range from -10 to +10 over adc range of 0 to 4095
		slope[i] = 1;
		intercept[i] = 0;
	}
		
	return self;	
}

- (void) dealloc 
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	int i;
	for(i=0;i<8;i++)	[channelName[i] release];
	for(i=0;i<8;i++)	[channelUnit[i] release];
	for(i=0;i<16;i++)	[doName[i] release];
	for(i=0;i<4;i++)	[ioName[i] release];
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [noDriverAlarm clearAlarm];
    [noDriverAlarm release];
    [serialNumber release];
	[super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		[self connectionChanged];		
		//make sure the driver is installed.
		NSFileManager* fm = [NSFileManager defaultManager];
		if(![fm fileExistsAtPath:kLabJackU12DriverPath]){
			NSLogColor([NSColor redColor],@"*** Unable To Locate LabJack U12 Driver ***\n");
			if(!noDriverAlarm){
				noDriverAlarm = [[ORAlarm alloc] initWithName:@"No LabJack U12 Driver Found" severity:0];
				[noDriverAlarm setSticky:NO];
				[noDriverAlarm setHelpStringFromFile:@"kLabJackU12DriverPath"];
			}                      
			[noDriverAlarm setAcknowledged:NO];
			[noDriverAlarm postAlarm];
		}
	}
	@catch(NSException* localException) {
	}
}


- (void) makeConnectors
{
	ORConnector* connectorObj1 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( 0, [self frame].size.height-20 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj1 forKey: ORLabJackUSBInConnection ];
	[ connectorObj1 setConnectorType: 'USBI' ];
	[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to usb outputs
	[connectorObj1 setOffColor:[NSColor yellowColor]];
	[ connectorObj1 release ];
	
	ORConnector* connectorObj2 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, 10 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj2 forKey: ORLabJackUSBNextConnection ];
	[ connectorObj2 setConnectorType: 'USBO' ];
	[ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to usb inputs
	[connectorObj2 setOffColor:[NSColor yellowColor]];
	[ connectorObj2 release ];
}

- (void) makeMainController
{
    [self linkToController:@"ORLabJackController"];
}

- (NSString*) helpURL
{
	return @"USB/LabJack.html";
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
	[[self objectConnectedTo:ORLabJackUSBNextConnection] connectionChanged];
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
	[self checkUSBAlarm];

}

-(void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
	NSImage* aCachedImage = [NSImage imageNamed:@"LabJack"];
    if(!usbInterface){
		NSSize theIconSize = [aCachedImage size];
		
		NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
		[i lockFocus];
		
        [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
		
		if(!usbInterface || ![self getUSBController]){
			NSBezierPath* path = [NSBezierPath bezierPath];
			[path moveToPoint:NSMakePoint(20,10)];
			[path lineToPoint:NSMakePoint(40,30)];
			[path moveToPoint:NSMakePoint(40,10)];
			[path lineToPoint:NSMakePoint(20,30)];
			[path setLineWidth:3];
			[[NSColor redColor] set];
			[path stroke];
		}    
		
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
	return [NSString stringWithFormat:@"LabJack (Serial# %@)",[usbInterface serialNumber]];
}

- (NSUInteger) vendorID
{
	return 0x0CD5;
}

- (NSUInteger) productID
{
	return 0x0001;	//LabJack ID
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORLabJackUSBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

#pragma mark ***Accessors

- (uint32_t) deviceSerialNumber
{
    return deviceSerialNumber;
}

- (void) setDeviceSerialNumber:(uint32_t)aDeviceSerialNumber
{
    deviceSerialNumber = aDeviceSerialNumber;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackModelDeviceSerialNumberChanged object:self];
}

- (BOOL) involvedInProcess
{
    return involvedInProcess;
}

- (void) setInvolvedInProcess:(BOOL)aInvolvedInProcess
{
    involvedInProcess = aInvolvedInProcess;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackModelInvolvedInProcessChanged object:self];
}

- (unsigned short) aOut1
{
    return aOut1;
}

- (void) setAOut1:(unsigned short)aValue
{
	if(aValue>1023)aValue=1023;
    [[[self undoManager] prepareWithInvocationTarget:self] setAOut1:aOut1];
    aOut1 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackModelAOut1Changed object:self];
}

- (void) setAOut0Voltage:(float)aValue
{
	[self setAOut0:aValue*255./5.1];
}

- (void) setAOut1Voltage:(float)aValue
{
	[self setAOut1:aValue*255./5.1];
}
		 
- (unsigned short) aOut0
{
    return aOut0;
}

- (void) setAOut0:(unsigned short)aValue
{
	if(aValue>1023)aValue=1023;
    [[[self undoManager] prepareWithInvocationTarget:self] setAOut0:aOut0];
    aOut0 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackModelAOut0Changed object:self];
}

- (float) slope:(int)i
{
	if(i>=0 && i<8)return slope[i];
	else return 20./4095.;
}

- (void) setSlope:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setSlope:i withValue:slope[i]];
		
		slope[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackSlopeChanged object:self userInfo:userInfo];
		
	}
}

- (float) intercept:(int)i
{
	if(i>=0 && i<8)return intercept[i];
	else return -10;
}

- (void) setIntercept:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setIntercept:i withValue:intercept[i]];
		
		intercept[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackInterceptChanged object:self userInfo:userInfo];
		
	}
}

- (float) lowLimit:(int)i
{
	if(i>=0 && i<8)return lowLimit[i];
	else return 0;
}

- (void) setLowLimit:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:i withValue:lowLimit[i]];
		
		lowLimit[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackLowLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) hiLimit:(int)i
{
	if(i>=0 && i<8)return hiLimit[i];
	else return 0;
}

- (void) setHiLimit:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setHiLimit:i withValue:lowLimit[i]];
		
		hiLimit[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackHiLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) minValue:(int)i
{
	if(i>=0 && i<8)return minValue[i];
	else return 0;
}

- (void) setMinValue:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setMinValue:i withValue:minValue[i]];
		
		minValue[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackMinValueChanged object:self userInfo:userInfo];
		
	}
}
- (float) maxValue:(int)i
{
	if(i>=0 && i<8)return maxValue[i];
	else return 0;
}

- (void) setMaxValue:(int)i withValue:(float)aValue
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setMaxValue:i withValue:maxValue[i]];
		
		maxValue[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackMaxValueChanged object:self userInfo:userInfo];
		
	}
}


- (BOOL) shipData
{
    return shipData;
}

- (void) setShipData:(BOOL)aShipData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipData:shipData];
    shipData = aShipData;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackShipDataChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
	[self pollHardware];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackPollTimeChanged object:self];
}

- (BOOL) digitalOutputEnabled
{
    return digitalOutputEnabled;
}

- (void) setDigitalOutputEnabled:(BOOL)aDigitalOutputEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDigitalOutputEnabled:digitalOutputEnabled];
    digitalOutputEnabled = aDigitalOutputEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackDigitalOutputEnabledChanged object:self];
}

- (uint32_t) counter
{
    return counter;
}

- (void) setCounter:(uint32_t)aCounter
{
    counter = aCounter;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackCounterChanged object:self];
}

- (NSString*) channelName:(int)i
{
	if(i>=0 && i<8){
		if([channelName[i] length])return channelName[i];
		else return [NSString stringWithFormat:@"Chan %d",i];
	}
	else return @"";
}

- (void) setChannel:(int)i name:(NSString*)aName
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:i name:channelName[i]];
		
		[channelName[i] autorelease];
		channelName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackChannelNameChanged object:self userInfo:userInfo];
		
	}
}

- (NSString*) channelUnit:(int)i
{
	if(i>=0 && i<8){
		if([channelUnit[i] length])return channelUnit[i];
		else return @"V";
	}
	else return @"";
}

- (void) setChannel:(int)i unit:(NSString*)aName
{
	if(i>=0 && i<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:i unit:channelUnit[i]];
		
		[channelUnit[i] autorelease];
		channelUnit[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackChannelUnitChanged object:self userInfo:userInfo];
		
	}
}



- (NSString*) ioName:(int)i
{
	if(i>=0 && i<4){
		if([ioName[i] length])return ioName[i];
		else return [NSString stringWithFormat:@"IO%d",i];
	}
	else return @"";
}

- (void) setIo:(int)i name:(NSString*)aName
{
	if(i>=0 && i<4){
		[[[self undoManager] prepareWithInvocationTarget:self] setIo:i name:ioName[i]];
		
		[ioName[i] autorelease];
		ioName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackIoNameChanged object:self userInfo:userInfo];
		
	}
}

- (NSString*) doName:(int)i
{
	if(i>=0 && i<16){
		if([doName[i] length])return doName[i];
		else return [NSString stringWithFormat:@"DO%d",i];
	}
	else return @"";
}

- (void) setDo:(int)i name:(NSString*)aName
{
	if(i>=0 && i<16){
		[[[self undoManager] prepareWithInvocationTarget:self] setDo:i name:doName[i]];
		
		[doName[i] autorelease];
		doName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackDoNameChanged object:self userInfo:userInfo];
		
	}
}

- (int) adc:(int)i
{
	unsigned short result = 0;
	@synchronized(self){
		if(i>=0 && i<8){
			result =  adc[i];
		}
	}
	return result;
}

- (void) setAdc:(int)i withValue:(int)aValue
{
	@synchronized(self){
		if(i>=0 && i<8){
			adc[i] = aValue; 
			
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackAdcChanged object:self userInfo:userInfo];
		}	
	}
}
- (int) gain:(int)i
{
	unsigned short result = 0;
	@synchronized(self){
		if(i>=0 && i<4){
			result =  gain[i];
		}
	}
	return result;
}

- (void) setGain:(int)i withValue:(int)aValue
{
	@synchronized(self){
		if(i>=0 && i<4){
			[[[self undoManager] prepareWithInvocationTarget:self] setGain:i withValue:gain[i]];
			gain[i] = aValue; 
			
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackGainChanged object:self userInfo:userInfo];
		}	
	}
}

- (unsigned short) adcDiff
{
	return adcDiff;
}

- (void) setAdcDiff:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcDiff:adcDiff];
    adcDiff = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackAdcDiffChanged object:self];
	
}

- (void) setAdcDiffBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = adcDiff;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setAdcDiff:aMask];
}

- (unsigned short) doDirection
{
    return doDirection;
}

- (void) setDoDirection:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoDirection:doDirection];
    doDirection = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackDoDirectionChanged object:self];
}


- (void) setDoDirectionBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = doDirection;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setDoDirection:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (unsigned short) ioDirection
{
    return ioDirection;
}

- (void) setIoDirection:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIoDirection:ioDirection];
    ioDirection = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackIoDirectionChanged object:self];
}

- (void) setIoDirectionBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = ioDirection;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setIoDirection:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}


- (unsigned short) doValueOut
{
    return doValueOut;
}

- (void) setDoValueOut:(unsigned short)aMask
{
	@synchronized(self){
		[[[self undoManager] prepareWithInvocationTarget:self] setDoValueOut:doValueOut];
		doValueOut = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackDoValueOutChanged object:self];
	}
}

- (void) setDoValueOutBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = doValueOut;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setDoValueOut:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (unsigned short) ioValueOut
{
    return ioValueOut;
}

- (void) setIoValueOut:(unsigned short)aMask
{
	@synchronized(self){
		[[[self undoManager] prepareWithInvocationTarget:self] setIoValueOut:ioValueOut];
		ioValueOut = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackIoValueOutChanged object:self];
	}
}

- (void) setIoValueOutBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = ioValueOut;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setIoValueOut:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (unsigned short) ioValueIn
{
    return ioValueIn;
}

- (void) setIoValueIn:(unsigned short)aMask
{
	@synchronized(self){
		ioValueIn = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackIoValueInChanged object:self];
	}
}

- (void) setIoValueInBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = ioValueIn;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setIoValueIn:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (NSString*) ioInString:(int)i
{
	if(ioDirection & (1L<<i) ) return (ioValueIn & 1L<<i) ? @"Hi":@"Lo";
	else						 return @"";
}

- (NSColor*) ioInColor:(int)i
{
	if(ioDirection & (1L<<i) ) return (ioValueIn & 1L<<i) ? 
		[NSColor colorWithCalibratedRed:0 green:.8 blue:0 alpha:1.0] :
		[NSColor colorWithCalibratedRed:.8 green:0 blue:0 alpha:1.0];
	else						 return [NSColor blackColor];
}

- (NSColor*) doInColor:(int)i
{
	if(doDirection & (1L<<i) ) return (doValueIn & 1L<<i) ? 
		[NSColor colorWithCalibratedRed:0 green:.8 blue:0 alpha:1.0] :
		[NSColor colorWithCalibratedRed:.8 green:0 blue:0 alpha:1.0];
	else						 return [NSColor blackColor];
}

- (unsigned short) doValueIn
{
    return doValueIn;
}

- (void) setDoValueIn:(unsigned short)aMask
{
	@synchronized(self){
		doValueIn = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackDoValueInChanged object:self];
	}
}

- (void) setDoValueInBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = doValueIn;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setDoValueIn:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (NSString*) doInString:(int)i
{
	if(doDirection & (1L<<i) ) return (doValueIn & 1L<<i) ? @"Hi":@"Lo";
	else						 return @"";
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackSerialNumberChanged object:self];
}

- (ORUSBInterface*) usbInterface
{
	return usbInterface;
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface
{
	
	[usbInterface release];
	usbInterface = anInterface;
	[usbInterface retain];
	[usbInterface setUsePipeType:kUSBInterrupt];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ORLabJackUSBInterfaceChanged
	 object: self];
	[self checkUSBAlarm];
	[self firstWrite];
}

- (void) checkUSBAlarm
{
	if((usbInterface && [self getUSBController]) || !guardian){
		[noUSBAlarm clearAlarm];
		[noUSBAlarm release];
		noUSBAlarm = nil;
	}
	else {
		if(guardian){
			if(!noUSBAlarm){
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for LabJack"] severity:kHardwareAlarm];
				[noUSBAlarm setSticky:YES];		
			}
			[noUSBAlarm setAcknowledged:NO];
			[noUSBAlarm postAlarm];
		}
	}
	[self setUpImage];
}

- (void) interfaceAdded:(NSNotification*)aNote
{
	[[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
	[self firstWrite];
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

- (void) resetCounter
{
	doResetOfCounter = YES;
	[self sendIoControl];
}


#pragma mark ***HW Access
- (void) queryAll
{
	if(usbInterface){
		if(!queue){
			queue = [[NSOperationQueue alloc] init];
			[queue setMaxConcurrentOperationCount:1]; //can only do one at a time
		}	
		if ([[queue operations] count] == 0) {
			ORLabJackQuery* anOp = [[ORLabJackQuery alloc] initWithDelegate:self];
			[queue addOperation:anOp];
			[anOp release];
			led = !led;
		}
	}
}

#pragma mark ***Data Records
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId   = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anOtherDevice
{
    [self setDataId:[anOtherDevice dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"LabJack"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORLabJackDecoderForIOData",@"decoder",
								 [NSNumber numberWithLong:dataId],   @"dataId",
								 [NSNumber numberWithBool:NO],       @"variable",
								 [NSNumber numberWithLong:kLabJackDataSize],       @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Temperatures"];
    
    return dataDictionary;
}

- (uint32_t) timeMeasured
{
	return timeMeasured;
}


- (void) shipIOData
{
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		uint32_t data[kLabJackDataSize];
		data[0] = dataId | kLabJackDataSize;
		data[1] = ((adcDiff & 0xf) << 16) | ([self uniqueIdNumber] & 0x0000fffff);
		
		union {
			float asFloat;
			uint32_t asLong;
		} theData;
		
		int index = 2;
		int i;
		for(i=0;i<8;i++){
			theData.asFloat = [self convertedValue:i];
			data[index] = theData.asLong;
			index++;
		}
		data[index++] = counter;
		data[index++] = ((ioDirection & 0xF) << 16) | (doDirection & 0xFFFF);
		data[index++] = ((ioValueOut  & 0xF) << 16) | (doValueOut & 0xFFFF);
		data[index++] = ((ioValueIn   & 0xF) << 16) | (doValueIn & 0xFFFF);
	
		data[index++] = timeMeasured;
		data[index++] = 0; //spares
		data[index++] = 0;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(int32_t)*kLabJackDataSize]];
	}
}
#pragma mark •••Bit Processing Protocol
- (void) processIsStarting
{
	//we will control the polling loop
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
    readOnce = NO;
	[self setInvolvedInProcess:YES];
}

- (void) processIsStopping
{
	//return control to the normal loop
	[self setPollTime:pollTime];
	[self setInvolvedInProcess:NO];
}

//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{
    if(!readOnce){
        @try { 
            [self performSelectorOnMainThread:@selector(queryAll) withObject:nil waitUntilDone:NO]; 
            readOnce = YES;
        }
		@catch(NSException* localException) { 
			//catch this here to prevent it from falling thru, but nothing to do.
        }
		
		//grab the bit pattern at the start of the cycle. it
		//will not be changed during the cycle.
		processInputValue = (doValueIn | (ioValueIn & 0xf)<<16) & (~doDirection | (~ioDirection & 0xf)<<16);
		processOutputMask = (doDirection | (ioDirection & 0xf)<<16);
		
    }
}

- (void) endProcessCycle
{
	readOnce = NO;
	//don't use the setter so the undo manager is bypassed
	doValueOut = processOutputValue & 0xFFFF;
	ioValueOut = (processOutputValue >> 16) & 0xF;
}

- (BOOL) processValue:(int)channel
{
	return (processInputValue & (1L<<channel)) > 0;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
	processOutputMask |= (1L<<channel);
	if(value)	processOutputValue |= (1L<<channel);
	else		processOutputValue &= ~(1L<<channel);
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"LabJack,%u",[self uniqueIdNumber]];
}

- (NSString*) processingTitle
{
    return [self identifier];
}

- (double) convertedValue:(int)aChan
{
	double volts = 20.0/4095.*adc[aChan] - 10.;
	unsigned short diffMask = [self adcDiff];

	if((diffMask & (1<<aChan/2)) && (aChan<7)){
		volts += (20.0/4095.*adc[aChan+1] - 10.);
	}
	
	if(aChan>=0 && aChan<8)return slope[aChan] * volts + intercept[aChan];
	else return 0;
}

- (double) maxValueForChan:(int)aChan
{
	return maxValue[aChan];
}
- (double) minValueForChan:(int)aChan
{
	return minValue[aChan];
}
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		if(channel>=0 && channel<8){
			*theLowLimit = lowLimit[channel];
			*theHighLimit =  hiLimit[channel];
		}
		else {
			*theLowLimit = -10;
			*theHighLimit = 10;
		}
	}		
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setAOut1:[decoder decodeIntegerForKey:@"aOut1"]];
    [self setAOut0:[decoder decodeIntegerForKey:@"aOut0"]];
    [self setShipData:[decoder decodeBoolForKey:@"shipData"]];
    [self setDigitalOutputEnabled:[decoder decodeBoolForKey:@"digitalOutputEnabled"]];
    [self setSerialNumber:	[decoder decodeObjectForKey:@"serialNumber"]];
	int i;
	for(i=0;i<8;i++) {
		
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"channelName%d",i]];
		if(aName)[self setChannel:i name:aName];
		else	 [self setChannel:i name:[NSString stringWithFormat:@"Chan %d",i]];
		
		NSString* aUnit = [decoder decodeObjectForKey:[NSString stringWithFormat:@"channelUnit%d",i]];
		if(aUnit)[self setChannel:i unit:aName];
		else	 [self setChannel:i unit:@"V"];
		
		[self setMinValue:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"minValue%d",i]]];
		[self setMaxValue:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"maxValue%d",i]]];
		[self setLowLimit:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"lowLimit%d",i]]];
		[self setHiLimit:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"hiLimit%d",i]]];
		[self setSlope:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"slope%d",i]]];
		[self setIntercept:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"intercept%d",i]]];
	}
	
	for(i=0;i<16;i++) {
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"DO%d",i]];
		if(aName)[self setDo:i name:aName];
		else [self setDo:i name:[NSString stringWithFormat:@"DO%d",i]];
	}
	
	for(i=0;i<4;i++) {
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"IO%d",i]];
		if(aName)[self setIo:i name:aName];
		else [self setIo:i name:[NSString stringWithFormat:@"IO%d",i]];
		[self setGain:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"gain%d",i]]];
	}
	[self setAdcDiff:	[decoder decodeIntegerForKey:@"adcDiff"]];
	[self setDoDirection:	[decoder decodeIntegerForKey:@"doDirection"]];
	[self setIoDirection:	[decoder decodeIntegerForKey:@"ioDirection"]];
    [self setPollTime:		[decoder decodeIntForKey:@"pollTime"]];

    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:aOut1 forKey:@"aOut1"];
    [encoder encodeInteger:aOut0 forKey:@"aOut0"];
    [encoder encodeBool:shipData forKey:@"shipData"];
    [encoder encodeInteger:pollTime forKey:@"pollTime"];
    [encoder encodeBool:digitalOutputEnabled forKey:@"digitalOutputEnabled"];
    [encoder encodeObject:serialNumber	forKey: @"serialNumber"];
	int i;
	for(i=0;i<8;i++) {
		[encoder encodeObject:channelUnit[i] forKey:[NSString stringWithFormat:@"unitName%d",i]];
		[encoder encodeObject:channelName[i] forKey:[NSString stringWithFormat:@"channelName%d",i]];
		[encoder encodeFloat:lowLimit[i] forKey:[NSString stringWithFormat:@"lowLimit%d",i]];
		[encoder encodeFloat:hiLimit[i] forKey:[NSString stringWithFormat:@"hiLimit%d",i]];
		[encoder encodeFloat:slope[i] forKey:[NSString stringWithFormat:@"slope%d",i]];
		[encoder encodeFloat:intercept[i] forKey:[NSString stringWithFormat:@"intercept%d",i]];
		[encoder encodeFloat:minValue[i] forKey:[NSString stringWithFormat:@"minValue%d",i]];
		[encoder encodeFloat:maxValue[i] forKey:[NSString stringWithFormat:@"maxValue%d",i]];
	}
	
	for(i=0;i<16;i++) {
		[encoder encodeObject:doName[i] forKey:[NSString stringWithFormat:@"DO%d",i]];
	}
	for(i=0;i<4;i++) {
		[encoder encodeObject:ioName[i] forKey:[NSString stringWithFormat:@"IO%d",i]];
		[encoder encodeInteger:gain[i] forKey:[NSString stringWithFormat:@"gain%d",i]];
	}

    [encoder encodeInteger:adcDiff		forKey:@"adcDiff"];
    [encoder encodeInteger:doDirection	forKey:@"doDirection"];
    [encoder encodeInteger:ioDirection	forKey:@"ioDirection"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	
	[self addCurrentState:objDictionary cArray:gain forKey:@"Gain"];
    [objDictionary setObject:[NSNumber numberWithInt:adcDiff] forKey:@"AdcDiffMask"];
	
    return objDictionary;
}
- (void) readSerialNumber
{
	if(usbInterface && [self getUSBController]){
		unsigned char data[8];
		data[0] = 0;
		data[1] = 0;
		data[2] = 0;
		data[3] = 0;
		data[4] = 0;
		data[5] = 0x50; // 0b01010000 = (read ram)
		data[6] = 0;    // most sig
		data[7] = 0;    // least sig 
		[self writeData:data];
	}
}
@end

@implementation ORLabJackModel (private)
- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0 )return;
    [[self undoManager] disableUndoRegistration];
	[self queryAll];
    [[self undoManager] enableUndoRegistration];
	if(pollTime == -1)[self performSelector:@selector(pollHardware) withObject:nil afterDelay:1/200.];
	else [self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}


		
- (void) readAdcValues
{
	if(usbInterface && [self getUSBController]){
		unsigned char data[8];
		int group;
		for(group=0;group<2;group++){
			if(adcDiff & (group==0?0x1:0x4)){
				int chan = (group==0?0:2);
				data[0] = ((gain[chan] & 0x7)<<4) | (group==0?0x0:0x2);  //Bits 6-4 PGA, Bits 3-0 MUX 0-1/4-5Diff
				data[1] = ((gain[chan] & 0x7)<<4) | (group==0?0x0:0x2);  //Bits 6-4 PGA, Bits 3-0 MUX Dup
			}
			else {
				data[0] = 0x08 + 0 + (4*group);  //Bits 6-4 PGA, Bits 3-0 MUX first Channel
				data[1] = 0x08 + 1 + (4*group);  //Bits 6-4 PGA, Bits 3-0 MUX second Channel
			}

			if(adcDiff & (group==0?0x2:0x8)){
				int chan = (group==0?1:3);
				data[2] = ((gain[chan] & 0x7)<<4) |(group==0?0x1:0x3);  //Bits 6-4 PGA, Bits 3-0 MUX 2-3/6-7 Diff
				data[3] = ((gain[chan] & 0x7)<<4) |(group==0?0x1:0x3);  //Bits 6-4 PGA, Bits 3-0 MUX Dup
			}
			else {
				data[2] = 0x08 + 2 + (4*group);  //Bits 6-4 PGA, Bits 3-0 MUX third Channel
				data[3] = 0x08 + 3 + (4*group);  //Bits 6-4 PGA, Bits 3-0 MUX four Channel
			}
			
			data[4] = led;			//led state	
			data[5] = 0xC0;
			data[6] = 0x00;			//Don't care
			data[7] = group;		// --- this echos back so we can tell which group to decode.
			[self writeData:data];
		}
	}
}

- (void) sendIoControl
{
	if(usbInterface && [self getUSBController]){
		
		unsigned char data[8];
		data[0] = (doDirection>>8) & 0xFF;					//D15-D8 Direction
		data[1] = doDirection	   & 0xFF;					//D7-D0 Direction
		data[2] = ((doValueOut & ~doDirection) >> 8) & 0xFF;//D15-D8 State
		data[3] =  (doValueOut & ~doDirection) & 0xFF;		//D15-D8 State
		data[4] = (ioDirection<<4) | ((ioValueOut & ~ioDirection) & 0x0F); //I0-I3 Direction and state
		
		//updateDigital, resetCounter,analog out
		unsigned short out0 = [self aOut0];
		unsigned short out1 = [self aOut1];
		data[5] = 0;
		if(digitalOutputEnabled) data[5] |= 0x10;
		data[5] |= (doResetOfCounter&0x1)<<5;
		//apparently the documentation is wrong and this is an 8-bit dac. 255 = 5V.
		//data[5] |= (((out1>>8) & 0x3) | (((out0>>8) & 0x3)<<2));
		data[6] = out0 & 0xFF;
		data[7] = out1 & 0xFF;
		[self writeData:data];
	}
	doResetOfCounter = NO;
}

- (void) readPipeThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		unsigned char data[8];
		int amountRead = [usbInterface readBytesOnInterruptPipeNoLock:data length:8];
        if(amountRead == 8){
            unsigned char data0 = data[0];
            unsigned char data1 = data[1];
            unsigned char data2 = data[2];
            unsigned char data3 = data[3];
            unsigned char data4 = data[4];
            unsigned char data5 = data[5];
            unsigned char data6 = data[6];
            unsigned char data7 = data[7];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if((data0 & 0x80)){
                    //an AIO command

                    int adcOffset = (data1 & 0x1) * 4;
                    [self setAdc:0 + adcOffset withValue:(data2&0x00f0)<<4 | data3];
                    [self setAdc:1 + adcOffset withValue:(data2&0x000f)<<8 | data4];
                    [self setAdc:2 + adcOffset withValue:(data5&0x00f0)<<4 | data6];
                    [self setAdc:3 + adcOffset withValue:(data5&0x000f)<<8 | data7];
                }
                else if((data0 & 0xC0) == 0){
                    //some digital I/O
                    [self setDoValueIn:data1<<8 | data2];
                    [self setIoValueIn:data3>>4];
                    [self setCounter:(data4<<24) | (data5<<16) | (data6<<8) | data7 ];
                    
                    //always this is the last query so timestamp here
                    time_t	ut_Time;
                    time(&ut_Time);
                    timeMeasured = (uint32_t)ut_Time;
                    
                    if(shipData) [self shipIOData];
                }
                else if((data0 & 0x50) == 0x50){
                    uint32_t n = (data1<<1) + (data2<<8) + (data3<<4) + data4;
                    [self setDeviceSerialNumber:n];
                }
            });
		}
	}
	@catch(NSException* e){
	}
	@finally {
		[pool release];
	}
}

- (void) firstWrite
{
	if(usbInterface){
		unsigned char data[8];
		data[0] = 0x00;
		data[1] = 0x00;
		data[2] = 0x00;			
		data[3] = 0x00;
		data[4] = 0x00;
		data[5] = 0x57;
		data[6] = 0x00;			
		data[7] = 0x00;
		[usbInterface writeBytesOnInterruptPipe:data length:8];
		[NSThread detachNewThreadSelector: @selector(readPipeThread) toTarget:self withObject: nil];
		[ORTimer delay:.02];
		[self readSerialNumber];
	}
	else [self setDeviceSerialNumber:0];
}

- (void) writeData:(unsigned char*) data
{
	if(usbInterface){
		[usbInterface writeBytesOnInterruptPipe:data length:8];
		[NSThread detachNewThreadSelector: @selector(readPipeThread) toTarget:self withObject: nil];
		[ORTimer delay:0.03];
	}
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(int*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<4;i++){
		[ar addObject:[NSNumber numberWithShort:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

@end

@implementation ORLabJackQuery
- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
    return self;
}

- (void) main
{
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];

	@try {
		[delegate readAdcValues];
		[delegate sendIoControl];
	}
	@catch(NSException* e){
	}
    @finally {
        [thePool release];
    }
}
@end

