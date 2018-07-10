//
//  ORADU200Model.m
//  Orca
//
//  USB Relay I/O Interface
//
//  Created by Mark Howe on Thurs Jan 26 2007.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORADU200Model.h"
#import "ORUSBInterface.h"
#import "NetSocket.h"

NSString* ORADU200ModelPollTimeChanged		= @"ORADU200ModelPollTimeChanged";
NSString* ORADU200ModelDebounceChanged		= @"ORADU200ModelDebounceChanged";
NSString* ORADU200ModelEventCounterChanged	= @"ORADU200ModelEventCounterChanged";
NSString* ORADU200ModelPortAChanged			= @"ORADU200ModelPortAChanged";
NSString* ORADU200ModelSerialNumberChanged	= @"ORADU200ModelSerialNumberChanged";
NSString* ORADU200ModelUSBInterfaceChanged	= @"ORADU200ModelUSBInterfaceChanged";
NSString* ORADU200ModelRelayChanged			= @"ORADU200ModelRelayChanged";
NSString* ORADU200ModelLock					= @"ORADU200ModelLock";

NSString* ORADU200USBInConnection			= @"ORADU200USBInConnection";
NSString* ORADU200USBNextConnection			= @"ORADU200USBNextConnection";

#define kADU200DriverPath @"/System/Library/Extensions/ADU200.kext"

@implementation ORADU200Model

- (void) makeConnectors
{
	ORConnector* connectorObj1 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( 0, [self frame].size.height-20 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj1 forKey: ORADU200USBInConnection ];
	[ connectorObj1 setConnectorType: 'USBI' ];
	[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to gpib outputs
	[connectorObj1 setOffColor:[NSColor yellowColor]];
	[ connectorObj1 release ];
	
	ORConnector* connectorObj2 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, 10 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj2 forKey: ORADU200USBNextConnection ];
	[ connectorObj2 setConnectorType: 'USBO' ];
	[ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to gpib inputs
	[connectorObj2 setOffColor:[NSColor yellowColor]];
	[ connectorObj2 release ];
}

- (void) makeMainController
{
    [self linkToController:@"ORADU200Controller"];
}

- (NSString*) helpURL
{
	return @"USB/ADU200.html";
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
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
		if(![fm fileExistsAtPath:kADU200DriverPath]){
			NSLogColor([NSColor redColor],@"*** Unable To Locate ADU200 Driver ***\n");
			if(!noDriverAlarm){
				noDriverAlarm = [[ORAlarm alloc] initWithName:@"No ADU200 Driver Found" severity:0];
				[noDriverAlarm setSticky:NO];
				[noDriverAlarm setHelpStringFromFile:@"NoADU200DriverHelp"];
			}                      
			[noDriverAlarm setAcknowledged:NO];
			[noDriverAlarm postAlarm];
		}
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
	[[self objectConnectedTo:ORADU200USBNextConnection] connectionChanged];
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
    
	NSImage* aCachedImage = [NSImage imageNamed:@"ADU200"];
    if(!usbInterface){
		NSSize theIconSize = [aCachedImage size];
		
		NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
		[i lockFocus];
		
		[aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
		
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
	return [NSString stringWithFormat:@"ADU200 (Serial# %@)",[usbInterface serialNumber]];
}

- (NSUInteger) vendorID
{
	return 0x0a07; //Ontrak ID
}

- (NSUInteger) productID
{
	return 0x00C8;	//ADU200 ID
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORADU200USBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

#pragma mark ***Accessors
- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    
    pollTime = aPollTime;
	
	[self pollHardware];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADU200ModelPollTimeChanged object:self];
}

- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0 )return;
    [[self undoManager] disableUndoRegistration];
	[self queryAll];
    [[self undoManager] enableUndoRegistration];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (int) debounce
{
    return debounce;
}

- (void) setDebounce:(int)aDebounce
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDebounce:debounce];
    
    debounce = aDebounce;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADU200ModelDebounceChanged object:self];
}

- (unsigned short) eventCounter:(unsigned short)index
{
	if(index<4)return eventCounter[index];
	return 0;
}

- (void) setEventCounter:(unsigned short)index withValue:(unsigned short)aEventCounter
{
	if(index<4){
		eventCounter[index] = aEventCounter;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORADU200ModelEventCounterChanged object:self];
	}
}

- (unsigned short) portA
{
	return portA;
}

- (void) setPortA:(unsigned short)aValue;
{
	portA = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORADU200ModelPortAChanged object:self];
}


- (void) setRelayState:(unsigned short)index withValue:(BOOL)aState
{
	if(index<4)relayState[index] = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADU200ModelRelayChanged object:self];
}

- (BOOL) relayState:(unsigned short)index
{
	if(index<4)return relayState[index];
	return NO;
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
		[self performSelector:@selector(queryRelays) withObject:self afterDelay:.1];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADU200ModelSerialNumberChanged object:self];
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
	 postNotificationName: ORADU200ModelUSBInterfaceChanged
	 object: self];
	[self checkUSBAlarm];
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
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for ADU200"] severity:kHardwareAlarm];
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

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setPollTime:[decoder decodeIntForKey:@"ORADU200ModelPollTime"]];
    [self setDebounce:[decoder decodeIntForKey:@"ORADU200ModelDebounce"]];
    [self setSerialNumber:[decoder decodeObjectForKey:@"ORADU200ModelSerialNumber"]];
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:pollTime forKey:@"ORADU200ModelPollTime"];
    [encoder encodeInt:debounce forKey:@"ORADU200ModelDebounce"];
    [encoder encodeObject:serialNumber forKey:@"ORADU200ModelSerialNumber"];
}

#pragma mark ***Comm methods

- (void) formatCommand:(NSString*)aCommand buffer:(char*)data
{
	memset(data,0,8);
	data[0] = 0x1;
	int i;
	for(i=0;i<MIN([aCommand length],7);i++){
		data[i+1] = [aCommand characterAtIndex:i];
	}
}

- (void) writeCommand:(NSString*)aCommand
{
	if(usbInterface && [self getUSBController]){
		char data[8];
		[self formatCommand:aCommand buffer:data];
		[usbInterface writeBytesOnInterruptPipe:data length:8];
		if(data[1] == 'R' || [aCommand isEqualToString:@"PK"] || [aCommand isEqualToString:@"PA"] || [aCommand isEqualToString:@"DB"]){
			int amountRead = [usbInterface readBytesOnInterruptPipe:data length:8];
			if(amountRead == 8){
				NSString* s = [[[NSString alloc] initWithBytes:&data[1] length:7 encoding:NSASCIIStringEncoding] autorelease];
				NSLog(@"Response to command: %@ = %@\n",aCommand,s);
			}
		}
	}
}

- (void) toggleRelay:(unsigned int)index
{
	if(index<4){
		if(relayState[index])[self openRelay:index];
		else [self closeRelay:index];
		[self queryRelay:index];
	}
}

- (void) closeRelay:(unsigned int)index
{
	if(index<4){
		NSString* aCommand = [NSString stringWithFormat:@"SK%d",index];
		char data[8];
		[self formatCommand:aCommand buffer:data];
		if(usbInterface && [self getUSBController]){
			[usbInterface writeBytesOnInterruptPipe:data length:8];
		}
	}
}

- (void) openRelay:(unsigned int)index
{
	if(index<4){
		if(usbInterface && [self getUSBController]){
			NSString* aCommand = [NSString stringWithFormat:@"RK%d",index];
			char data[8];
			[self formatCommand:aCommand buffer:data];
			[usbInterface writeBytesOnInterruptPipe:data length:8];
		}
	}
}

- (void) queryAll
{
	
	[self queryRelays];
	[self queryPortA];
	[self queryEventCounters];
	[self queryDebounce];
}

- (void) queryRelays
{
	if(usbInterface && [self getUSBController]){
		int i;
		for(i=0;i<4;i++){
			[self queryRelay:i];
		}
	}
}

- (void) queryRelay:(int)i
{
	NSString* aCommand = [NSString stringWithFormat:@"RPK%d",i];
	char data[8];
	[self formatCommand:aCommand buffer:data];
	[usbInterface writeBytesOnInterruptPipe:data length:8];
	int amountRead = [usbInterface readBytesOnInterruptPipe:data length:8];
	if(amountRead == 8){
		if(data[1] == '1')	[self setRelayState:i withValue:1];
		else				[self setRelayState:i withValue:0];
	}
}

- (void) queryEventCounters
{
	if(usbInterface && [self getUSBController]){
		int i;
		for(i=0;i<4;i++){			
			NSString* aCommand = [NSString stringWithFormat:@"RE%d",i];
			char data[8];
			[self formatCommand:aCommand buffer:data];
			[usbInterface writeBytesOnInterruptPipe:data length:8];
			int amountRead = [usbInterface readBytesOnInterruptPipe:data length:8];
			if(amountRead == 8){
				NSString* stringValue = [[[NSString alloc] initWithBytes:&data[1] length:5 encoding:NSASCIIStringEncoding] autorelease];
				[self setEventCounter:i withValue:[stringValue intValue]];
			}
		}
	}	
}

- (void) readAndClear
{
	if(usbInterface && [self getUSBController]){
		int i;
		for(i=0;i<4;i++){			
			NSString* aCommand = [NSString stringWithFormat:@"RC%d",i];
			char data[8];
			[self formatCommand:aCommand buffer:data];
			[usbInterface writeBytesOnInterruptPipe:data length:8];
			int amountRead = [usbInterface readBytesOnInterruptPipe:data length:8];
			if(amountRead == 8){
				NSString* stringValue = [[[NSString alloc] initWithBytes:&data[1] length:5 encoding:NSASCIIStringEncoding] autorelease];
				[self setEventCounter:i withValue:[stringValue intValue]];
			}
		}
	}	
}

- (void) queryPortA
{
	if(usbInterface && [self getUSBController]){
		char data[8];
		[self formatCommand:@"RPA" buffer:data];
		[usbInterface writeBytesOnInterruptPipe:data length:8];
		int amountRead = [usbInterface readBytesOnInterruptPipe:data length:8];
		if(amountRead ==8){
			int i;
			unsigned short result = 0;
			for(i=0;i<4;i++){
				if(data[i+1] == '1')result |= (0x8>>i);
			}
			[self setPortA:result];
		}
	}
}

- (void) queryDebounce
{
	if(usbInterface && [self getUSBController]){
		char data[8];
		[self formatCommand:@"DB" buffer:data];
		[usbInterface writeBytesOnInterruptPipe:data length:8];
		int amountRead = [usbInterface readBytesOnInterruptPipe:data length:8];
		if(amountRead ==8){
			[self setDebounce:2-('2'- data[1])]; //convert ascii 0,1,2 to int
		}
	}
}

- (void) sendDebounce
{
	if(usbInterface && [self getUSBController]){
		char data[8];
		NSString* aCommand = [NSString stringWithFormat:@"DB%d",debounce];
		[self formatCommand:aCommand buffer:data];
		[usbInterface writeBytesOnInterruptPipe:data length:8];
	}
}

#pragma mark ¥¥¥Bit Processing Protocol
- (void)processIsStarting
{
}

- (void)processIsStopping
{
}

- (void) startProcessCycle
{
	//grab the bit pattern at the start of the cycle. it
	//will not be changed during the cycle.
	processInputValue = 0L;
	[self queryPortA];
	processInputValue =  portA;
}

- (void) endProcessCycle
{
	if(usbInterface && [self getUSBController]){
		NSString* aCommand = [NSString stringWithFormat:@"SPK%04lx",processOutputValue & 0xf];
		char data[8];
		[self formatCommand:aCommand buffer:data];
		[usbInterface writeBytesOnInterruptPipe:data length:8];
	}
}

- (BOOL) processValue:(int)channel
{
	return (processInputValue & (1L<<channel)) > 0;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
	if(value)	processOutputValue |= (1L<<channel);
	else		processOutputValue &= ~(1L<<channel);
}

- (NSString*) processingTitle
{
    return [NSString stringWithFormat:@"ADU200,%lu",[self uniqueIdNumber]];
}

@end
