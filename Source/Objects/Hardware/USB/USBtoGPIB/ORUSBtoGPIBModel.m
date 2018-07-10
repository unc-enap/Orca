//
//  ORUSBtoGPIBModel.m
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
//Department of Energy (DOE) under Grant #DE-FG03-97ER41020/A000. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark ¥¥¥Imported Files
#import "ORUSBtoGPIBModel.h"
#import "ORUSBInterface.h"

NSString* ORUSBtoGPIBModelCommandChanged		= @"ORUSBtoGPIBModelCommandChanged";
NSString* ORUSBtoGPIBModelAddressChanged		= @"ORUSBtoGPIBModelAddressChanged";
NSString* ORUSBtoGPIBModelSerialNumberChanged	= @"ORUSBtoGPIBModelSerialNumberChanged";
NSString* ORUSBtoGPIBModelUSBInterfaceChanged	= @"ORUSBtoGPIBModelUSBInterfaceChanged";

NSString* ORUSBtoGPIBUSBInConnection			= @"ORUSBtoGPIBUSBInConnection";
NSString* ORUSBtoGPIBNextConnection				= @"ORUSBtoGPIBNextConnection";
NSString* ORUSBtoGPIBUSBOutConnection			= @"ORUSBtoGPIBUSBOutConnection";

#define kUSBtoGPIBDriverPath @"/System/Library/Extensions/USBtoGPIB.kext"

@implementation ORUSBtoGPIBModel
- (id) init {
	self = [super init];
	theHWLock = [[NSRecursiveLock alloc] init];
	return self;
}

- (void) makeConnectors
{
	ORConnector* connectorObj1 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2)
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj1 forKey: ORUSBtoGPIBUSBInConnection ];
	[ connectorObj1 setConnectorType: 'USBI' ];
	[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to gpib outputs
	[connectorObj1 setOffColor:[NSColor yellowColor]];
	[ connectorObj1 release ];
	
	ORConnector* connectorObj2 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, [self frame].size.height-15 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj2 forKey: ORUSBtoGPIBNextConnection ];
	[ connectorObj2 setConnectorType: 'GPI2' ];
	[ connectorObj2 addRestrictedConnectionType: 'GPI1' ]; //can only connect to gpib inputs
	[ connectorObj2 release ];
	
	ORConnector* connectorObj3 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, 5 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj3 forKey: ORUSBtoGPIBUSBOutConnection ];
	[ connectorObj3 setConnectorType: 'USBO' ];
	[ connectorObj3 addRestrictedConnectionType: 'USBI' ]; //can only connect to gpib inputs
	[connectorObj3 setOffColor:[NSColor yellowColor]];
	[ connectorObj3 release ];
	
}

- (void) makeMainController
{
    [self linkToController:@"ORUSBtoGPIBController"];
}

- (void) dealloc
{
	[theHWLock release];
    [command release];
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
	}
	@catch(NSException* localException) {
	}
}


-(void) setUpImage
{
	
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
	NSImage* aCachedImage = [NSImage imageNamed:@"USBtoGPIB"];
    if(!usbInterface){
		NSSize theIconSize = [aCachedImage size];
		
		NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
		[i lockFocus];
		
        [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
		
		if(!usbInterface){
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
	return [NSString stringWithFormat:@"USBtoGPIB (Serial# %@)",[usbInterface serialNumber]];
}

- (NSUInteger) vendorID
{
	return 0x0403; //Ontrak ID
}

- (NSUInteger) productID
{
	return 0x6001;	//USBtoGPIB ID
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORUSBtoGPIBUSBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

#pragma mark ***Accessors
//-------------------------------------------------------------------------------------------------------
//these methods make the USGtoGPIB look like a regular GPIB object 
- (id) getGpibController
{
	return self;
}

- (BOOL) isConnected
{
	if(usbInterface)return YES;
	else return NO;
	
}

- (void) enableEOT:(short)aPrimaryAddress state: (BOOL) state
{
    @try {
		[theHWLock lock];   //-----begin critical section
		[self selectDevice:aPrimaryAddress];
		NSString* cmd = [NSString stringWithFormat:@"++eoi %d\r",state];
		if(fd){
			int n = write(fd,[cmd cStringUsingEncoding:NSASCIIStringEncoding],[cmd length]);
			if(n<=0){
				[theHWLock unlock];   //-----end critical section
				[NSException raise:@"Serial Write" format:@"ORUSBtoBPIBMode.m %u: Write to serial port <%@> failed\n", __LINE__,serialNumber];
			}
		}
		enableEOT = state;
        [theHWLock unlock];   //-----end critical section
	}
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
}

- (void) setupDevice: (short) aPrimaryAddress secondaryAddress: (short) aSecondaryAddress
{
    @try {
		[theHWLock lock];   //-----begin critical section
		[self selectDevice:aPrimaryAddress];
		
		///NSString* cmd = [NSString stringWithFormat:@"++mode 1\r++auto 0\r++eos 3\r++eoi 1\r"];
		//[usbInterface writeBytes:(char*)[cmd cStringUsingEncoding:NSASCIIStringEncoding]  length:[cmd length]];
		//flush the Controller
		//char reply[1024];
		//[self readFromDevice:aPrimaryAddress data:reply maxLength:1024];
		
		[self enableEOT:aPrimaryAddress state:YES];
        [theHWLock unlock];   //-----end critical section
	}
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
}

- (void) selectDevice:(short) aPrimaryAddress
{
    @try {
		if(aPrimaryAddress != lastSelectedAddress){
			NSString* cmd = [NSString stringWithFormat:@"++addr %d\r++mode 1\r++auto 0\r++eos 3\r++eoi 1\r",aPrimaryAddress];
			if(fd){
				int n = write(fd,[cmd cStringUsingEncoding:NSASCIIStringEncoding],[cmd length]);
				if(n<=0){
					[NSException raise:@"Serial Write" format:@"ORUSBtoBPIBMode.m %u: Write to serial port <%@> failed\n", __LINE__,serialNumber];
				}
			}
			lastSelectedAddress = aPrimaryAddress;
		}
	}
	@catch(NSException* localException) {
        [localException raise];
    }
}

- (long) writeReadDevice: (short) aPrimaryAddress command: (NSString*) aCommand data: (char*) aData
               maxLength: (long) aMaxLength
{
    long retVal = 0;
    @try {
        
        [theHWLock lock];   //-----begin critical section
        [ self writeToDevice: aPrimaryAddress command: aCommand ];
		
        retVal = [ self readFromDevice: aPrimaryAddress data: aData maxLength: aMaxLength ];
		
        [theHWLock unlock];   //-----end critical section
	}
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
    return( retVal );
}


- (void) writeToDevice: (short) aPrimaryAddress command: (NSString*) aCommand
{
	if(!fd)return;
    @try {
		[theHWLock lock];   //-----begin critical section
		[self selectDevice:aPrimaryAddress];
		NSMutableString* cmd = [NSMutableString stringWithString:aCommand];
		[cmd replaceOccurrencesOfString:@"\n" withString:@"\033\n" options:NSLiteralSearch range:NSMakeRange(0,[cmd length])];
		if(![cmd hasSuffix:@"\r"])[cmd appendString:@"\r"];
		
		int n = write(fd,[cmd cStringUsingEncoding:NSASCIIStringEncoding],[cmd length]);
		if(n<=0){
			[theHWLock unlock];   //-----end critical section
			[NSException raise:@"Serial Write" format:@"ORUSBtoBPIBMode.m %u: Write to serial port <%@> failed\n", __LINE__,serialNumber];
		}
        [theHWLock unlock];   //-----end critical section
	}
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
}

- (long) readFromDevice: (short) aPrimaryAddress data: (char*) aData maxLength: (long) aMaxLength
{
	int result = 0;
	if(!fd)return result;
    @try {
		[theHWLock lock];   //-----begin critical section
		[self selectDevice:aPrimaryAddress];
		
		NSString* readCmd = [NSString stringWithFormat:@"++read eoi\r"];
		result = write(fd,[readCmd cStringUsingEncoding:NSASCIIStringEncoding],[readCmd length]);
		if(result != [readCmd length]){
			[theHWLock unlock];   //-----end critical section
			[NSException raise:@"Serial Write" format:@"ORUSBtoBPIBMode.m %u: Write to serial port <%@> failed\n", __LINE__,serialNumber];
		}
		result = read(fd,aData,aMaxLength);
		if(result <=0 ){
			[theHWLock unlock];   //-----end critical section
			[NSException raise:@"Serial Read" format:@"ORUSBtoBPIBMode.m %u: Write to serial port <%@> failed\n", __LINE__,serialNumber];
		}
		if(result>0 && result < 1024)aData[result] = '\0';
		if(result>2 && aData[0] == 0x31 && aData[1] == 0x60){
			memmove(&aData[0],&aData[2],result-2);
			result -= 2;
		}
		
        [theHWLock unlock];   //-----end critical section
	}
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
	
	return result;
}
//-------------------------------------------------------------------------------------------------------

- (NSString*) command
{
    return command;
}

- (void) setCommand:(NSString*)aCommand
{
	if(!aCommand)aCommand = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setCommand:command];
    
    [command autorelease];
    command = [aCommand copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORUSBtoGPIBModelCommandChanged object:self];
}

- (char) gpibAddress
{
    return gpibAddress;
}

- (void) setGpibAddress:(char)aAddress
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGpibAddress:gpibAddress];
	
    if(aAddress<0)aAddress=0;
	else if(aAddress>31)aAddress = 31;
	
    gpibAddress = aAddress;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORUSBtoGPIBModelAddressChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORUSBtoGPIBModelSerialNumberChanged object:self];
}

- (ORUSBInterface*) usbInterface
{
	return usbInterface;
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface
{
	//[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[usbInterface release];
	usbInterface = anInterface;
	[usbInterface retain];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ORUSBtoGPIBModelUSBInterfaceChanged
	 object: self];
	
	if(usbInterface){
		[noUSBAlarm clearAlarm];
		[noUSBAlarm release];
		noUSBAlarm = nil;
	}
	else {
		if(!noUSBAlarm){
			noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for USBtoGPIB"] severity:kHardwareAlarm];
			[noUSBAlarm setSticky:YES];		
		}
		[noUSBAlarm setAcknowledged:NO];
		[noUSBAlarm postAlarm];
	}
	
	[self setUpImage];
	
}

- (void) interfaceAdded:(NSNotification*)aNote
{
	[[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
	//we are going to claim the interface, but we have have to use the prologix virtual com port
	//because of a strange problem when reading from GPIB devices. 
	if(fd)close(fd);
	if(serialNumber){
		const char* deviceName = [[NSString stringWithFormat:@"/dev/cu.usbserial-%@",serialNumber] cStringUsingEncoding:NSASCIIStringEncoding];
		fd = open(deviceName,O_RDWR | O_NOCTTY | O_NDELAY);
		if(fd && fd != -1){
			fcntl(fd, F_SETFL, 0);
			[noDriverAlarm clearAlarm];
			[noDriverAlarm release];
			noDriverAlarm = nil;
		}
		else {
			if(!noDriverAlarm){
				noDriverAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No Driver (Prologix)"] severity:kHardwareAlarm];
				[noDriverAlarm setSticky:YES];		
			}
			[noDriverAlarm setAcknowledged:NO];
			[noDriverAlarm postAlarm];
		}
	}
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
	if(usbInterface && serialNumber){
		[self setUsbInterface:nil];
		if(fd)close(fd);
		fd = 0;
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

#pragma mark ¥¥¥HW Access
- (void) sendCommand
{
	if(usbInterface){
		if(command){
			if([command rangeOfString:@"?"].location == NSNotFound){
				[self writeToDevice:gpibAddress command:command];
			}
			else {
				char reply[1024];
				long n = [self writeReadDevice:gpibAddress command:command data:reply maxLength:1024];
				if(n && [[NSString stringWithCString:reply encoding:NSASCIIStringEncoding] rangeOfString:@"No error"].location == NSNotFound){
					NSLog(@"%s\n",reply);
				}
			}
		}
	}
}


#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setCommand:[decoder decodeObjectForKey:@"ORUSBtoGPIBModelCommand"]];
    [self setGpibAddress:[decoder decodeIntForKey:@"ORUSBtoGPIBModelAddress"]];
    [self setSerialNumber:[decoder decodeObjectForKey:@"ORUSBtoGPIBModelSerialNumber"]];
	lastSelectedAddress = -1;
    [[self undoManager] enableUndoRegistration];    
	theHWLock = [[NSRecursiveLock alloc] init];    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:command forKey:@"ORUSBtoGPIBModelCommand"];
    [encoder encodeInt:gpibAddress forKey:@"ORUSBtoGPIBModelAddress"];
    [encoder encodeObject:serialNumber forKey:@"ORUSBtoGPIBModelSerialNumber"];
}

@end
