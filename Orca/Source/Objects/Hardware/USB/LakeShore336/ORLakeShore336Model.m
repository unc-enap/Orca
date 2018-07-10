//
//  ORLakeShore336Model.m
//  Orca
//
//  Created by Mark Howe on Mon, May 6, 2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
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


#pragma mark •••Imported Files
#import "ORLakeShore336Model.h"
#import "ORUSBInterface.h"
#import "NetSocket.h"
#import "ORSafeQueue.h"
#import "ORLakeShore336Input.h"
#import "ORLakeShore336Heater.h"

#define kMaxNumberOfPoints33220 0xFFFF

NSString* ORLakeShore336SerialNumberChanged     = @"ORLakeShore336SerialNumberChanged";
NSString* ORLakeShore336CanChangeConnectionProtocolChanged = @"ORLakeShore336CanChangeConnectionProtocolChanged";
NSString* ORLakeShore336IpConnectedChanged      = @"ORLakeShore336IpConnectedChanged";
NSString* ORLakeShore336UsbConnectedChanged     = @"ORLakeShore336UsbConnectedChanged";
NSString* ORLakeShore336IpAddressChanged        = @"ORLakeShore336IpAddressChanged";
NSString* ORLakeShore336ConnectionProtocolChanged = @"ORLakeShore336ConnectionProtocolChanged";
NSString* ORLakeShore336USBInConnection         = @"ORLakeShore336USBInConnection";
NSString* ORLakeShore336USBNextConnection       = @"ORLakeShore336USBNextConnection";
NSString* ORLakeShore336USBInterfaceChanged     = @"ORLakeShore336USBInterfaceChanged";
NSString* ORLakeShore336Lock                    = @"ORLakeShore336Lock";
NSString* ORLakeShore336IsValidChanged			= @"ORLakeShore336IsValidChanged";
NSString* ORLakeShore336PortClosedAfterTimeout	= @"ORLakeShore336PortClosedAfterTimeout";
NSString* ORLakeShore336TimeoutCountChanged     = @"ORLakeShore336TimeoutCountChanged";
NSString* ORLakeShore336PollTimeChanged         = @"ORLakeShore336PollTimeChanged";

@interface ORLakeShore336Model (private)
- (void) processOneCommandFromQueue;
- (void) process_response:(NSString*)theResponse;
- (void) mainThreadSocketWrite:(NSString*)aCommand;
- (void) postCouchDBRecord;
@end

@implementation ORLakeShore336Model

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[cmdQueue release];
	[lastRequest release];
	[timeoutAlarm clearAlarm];
	[timeoutAlarm release];
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [serialNumber release];
	[ipAddress release];
	[socket close];
    [socket setDelegate:nil];
	[socket release];
    [inputs release];
    [heaters release];
    [super dealloc];
}

- (void) sleep
{
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
	noUSBAlarm = nil;
	[super sleep];
}

- (void) wakeUp 
{
    if([self aWake])return;
	[super wakeUp];
	[self checkNoUsbAlarm];
}

- (void) makeConnectors
{
	[self adjustConnectors:YES];
}

- (void) makeUSBConnectors
{
	if(![[ self connectors ] objectForKey:ORLakeShore336USBInConnection]){
		ORConnector* connectorObj1 = [[ ORConnector alloc ] 
									  initAt: NSMakePoint( 0, 0 )
									  withGuardian: self];
		[[ self connectors ] setObject: connectorObj1 forKey: ORLakeShore336USBInConnection ];
		[ connectorObj1 setConnectorType: 'USBI' ];
		[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to gpib outputs
		[connectorObj1 setOffColor:[NSColor yellowColor]];
		[ connectorObj1 release ];
	}
	
	if(![[ self connectors ] objectForKey:ORLakeShore336USBNextConnection]){
		ORConnector* connectorObj2 = [[ ORConnector alloc ] 
									  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, 0 )
									  withGuardian: self];
		[[ self connectors ] setObject: connectorObj2 forKey: ORLakeShore336USBNextConnection ];
		[ connectorObj2 setConnectorType: 'USBO' ];
		[ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to gpib inputs
		[connectorObj2 setOffColor:[NSColor yellowColor]];
		[ connectorObj2 release ];
	}
}

- (void) makeGPIBConnectors
{
	[super makeConnectors];
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
	[self checkNoUsbAlarm];
}

- (void) adjustConnectors:(BOOL)force
{
	if(canChangeConnectionProtocol || force){
		if(connectionProtocol == kLakeShore336UseUSB) {
			[self makeUSBConnectors];
		}
		else { //kLakeShore336UseIP
			[self removeConnectorForKey:ORLakeShore336USBInConnection];
			[self removeConnectorForKey:ORLakeShore336USBNextConnection];
		}
	}
}

- (void) makeMainController
{
    [self linkToController:@"ORLakeShore336Controller"];
}

//- (NSString*) helpURL
//{
//	return @"GPIB/Aglient_33220a.html";
//}


- (void) awakeAfterDocumentLoaded
{
	@try {
		[self connect];
		okToCheckUSB = YES;
		[self connectionChanged];
	}
	@catch(NSException* localException) {
	}
}

- (void) connectionChanged
{
	if([self objectConnectedTo:ORLakeShore336USBInConnection] || [self objectConnectedTo:ORLakeShore336USBNextConnection]){
		[self setCanChangeConnectionProtocol:NO];
	}
	else {
		[self setCanChangeConnectionProtocol:YES];
	}
	NSArray* interfaces = [[self getUSBController] interfacesForVender:[self vendorID] product:[self productID]];
	NSString* sn = serialNumber;
	if([interfaces count] == 1 && ![sn length]){
		sn = [[interfaces objectAtIndex:0] serialNumber];
	}
	[self setSerialNumber:sn]; //to force usbinterface at doc startup
	[self checkNoUsbAlarm];	
	[[self objectConnectedTo:ORLakeShore336USBNextConnection] connectionChanged];
	[self setUpImage];
}


-(void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"LakeShore336"];
	
    NSSize theIconSize = [aCachedImage size];
    NSPoint theOffset = NSZeroPoint;
    NSImage* netConnectIcon = nil;
    if(connectionProtocol == kLakeShore336UseIP){
        netConnectIcon = [NSImage imageNamed:@"NetConnect"];
        theIconSize.width += 10;
        theIconSize.height += 30;
    }
    
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    if(connectionProtocol == kLakeShore336UseIP){
        [netConnectIcon drawAtPoint:NSZeroPoint fromRect:[netConnectIcon imageRect] operation:NSCompositeSourceOver fraction:1.0];
        theOffset.x += 10;
        theOffset.y += 15;
    }
    [aCachedImage drawAtPoint:theOffset fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];	
    if(connectionProtocol == kLakeShore336UseUSB && (!usbInterface || ![self getUSBController])){
        NSBezierPath* path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(20,2)];
        [path lineToPoint:NSMakePoint(40,22)];
        [path moveToPoint:NSMakePoint(40,2)];
        [path lineToPoint:NSMakePoint(20,22)];
        [path setLineWidth:3];
        [[NSColor redColor] set];
        [path stroke];
    }    
	
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
    
}


- (id)  dialogLock
{
	return @"ORLakeShore336Lock";
}

- (NSString*) title 
{
	switch (connectionProtocol){
		case kLakeShore336UseUSB:	return [NSString stringWithFormat:@"LakeShore336 (Serial# %@)",[usbInterface serialNumber]];
		case kLakeShore336UseIP:	return [NSString stringWithFormat:@"LakeShore336 (%@)",[self ipAddress]];
	}
	return [NSString stringWithFormat:@"33220 Pulser (%d)",[self tag]];
}

- (NSUInteger) vendorID
{
	return 0x1fb9;
}

- (NSUInteger) productID
{
	return 0x301;
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORLakeShore336USBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
	return [super acceptsGuardian:aGuardian] ||
    [aGuardian isMemberOfClass:NSClassFromString(@"ORMJDVacuumModel")];
}

#pragma mark ***Accessors
- (BOOL) anyInputsUsingTimeRate:(id)aTimeRate
{
    for(id anInput in inputs){
        if([anInput timeRate] == aTimeRate)return YES;
    }
    return NO;
}
- (BOOL) anyHeatersUsingTimeRate:(id)aTimeRate
{
    for(id aHeater in heaters){
        if([aHeater timeRate] == aTimeRate)return YES;
    }
    return NO;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336PollTimeChanged object:self];
}

- (void) setTimeoutCount:(int)aValue
{
    timeoutCount=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336TimeoutCountChanged object:self];
    
}

- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0)return;
	[self queryAll];
    [self postCouchDBRecord];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}


- (void) queryAll
{
    [self addCmdToQueue:@"KRDG? A"];
    [self addCmdToQueue:@"KRDG? B"];
    [self addCmdToQueue:@"KRDG? C"];
    [self addCmdToQueue:@"KRDG? D"];
    [self addCmdToQueue:@"HTR? 1"];
    [self addCmdToQueue:@"HTR? 2"];    
}

- (int) timeoutCount
{
	return timeoutCount;
}

- (id) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(id)aCmd
{
	[aCmd retain];
	[lastRequest release];
	lastRequest = aCmd;
}

- (BOOL) isValid
{
	if([self isConnected] && isValid) return YES;
	else return NO;
}

- (void) setIsValid:(BOOL)aState
{
	if(isValid!=aState){
		isValid = aState;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336IsValidChanged object:self];
	}
	
	if(isValid){
        [self setTimeoutCount:0];
		[self clearTimeoutAlarm];
	}
}

- (NSString*) serialNumber
{
    return serialNumber;
}

- (void) setSerialNumber:(NSString*)aSerialNumber
{
	if(!aSerialNumber)aSerialNumber = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setSerialNumber:serialNumber];
    
    [serialNumber autorelease];
    serialNumber = [aSerialNumber copy];    
	
	if(!serialNumber){
		[[self getUSBController] releaseInterfaceFor:self];
	}
	else [[self getUSBController] claimInterfaceWithSerialNumber:serialNumber for:self];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336SerialNumberChanged object:self];
}

- (BOOL) canChangeConnectionProtocol
{
    return canChangeConnectionProtocol;
}

- (void) setCanChangeConnectionProtocol:(BOOL)aCanChangeConnectionProtocol
{
    
    canChangeConnectionProtocol = aCanChangeConnectionProtocol;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336CanChangeConnectionProtocolChanged object:self];
}

- (NetSocket*) socket
{
	return socket;
}
- (void) setSocket:(NetSocket*)aSocket
{
	if(aSocket != socket)[socket close];
	[aSocket retain];
	[socket release];
	socket = aSocket;
    [socket setDelegate:self];
}

- (BOOL) ipConnected
{
    return ipConnected;
}

- (void) setIpConnected:(BOOL)aIpConnected
{
    ipConnected = aIpConnected;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336IpConnectedChanged object:self];
}

- (BOOL) usbConnected
{
    return usbConnected;
}

- (ORUSBInterface*) usbInterface
{
	return usbInterface;
}

- (void) setUsbConnected:(BOOL)aUsbConnected
{
    usbConnected = aUsbConnected;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336UsbConnectedChanged object:self];
}

- (NSString*) ipAddress
{
    return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
	if(!aIpAddress)aIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
    
    [ipAddress autorelease];
    ipAddress = [aIpAddress copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336IpAddressChanged object:self];
}

- (int) connectionProtocol
{
    return connectionProtocol;
}

- (void) setConnectionProtocol:(int)aConnectionProtocol
{
	[[[self undoManager] prepareWithInvocationTarget:self] setConnectionProtocol:connectionProtocol];
	
	connectionProtocol = aConnectionProtocol;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336ConnectionProtocolChanged object:self];
	[self setUpImage];
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface
{
	
	if(connectionProtocol == kLakeShore336UseUSB){
		
		[usbInterface release];
		usbInterface = anInterface;
		[usbInterface retain];
				
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: ORLakeShore336USBInterfaceChanged
		 object: self];
		
		[self setUpImage];
		
	}
}

- (void) interfaceAdded:(NSNotification*)aNote
{
	if(connectionProtocol == kLakeShore336UseUSB){
		[[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
		[self checkNoUsbAlarm];			
	}
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
	if(connectionProtocol == kLakeShore336UseUSB){
		ORUSBInterface* theInterfaceRemoved = [[aNote userInfo] objectForKey:@"USBInterface"];
		if((usbInterface == theInterfaceRemoved) && serialNumber){
			[self setUsbInterface:nil];
			[self checkNoUsbAlarm];			
		}
	}
}

- (void) checkNoUsbAlarm
{
	if(!okToCheckUSB) return;
	if((connectionProtocol != kLakeShore336UseUSB) || (usbInterface && [self getUSBController]) || !guardian){
		[noUSBAlarm clearAlarm];
		[noUSBAlarm release];
		noUSBAlarm = nil;
	}
	else {
		if(guardian && [self aWake]){
			if(!noUSBAlarm){
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for Pulser"] severity:kHardwareAlarm];
				[noUSBAlarm setHelpString:@"\n\nThe USB interface is no longer available for this object. This could mean the cable is disconnected or the power is off"];
				[noUSBAlarm setSticky:YES];		
			}
			[noUSBAlarm setAcknowledged:NO];
			[noUSBAlarm postAlarm];
		}
	}
	[self setUpImage];
}

- (NSArray*) usbInterfaces
{
	return [[self getUSBController]  interfacesForVender:[self vendorID] product:[self productID]];
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

- (void) logSystemResponse
{
}

- (void) connect
{
	switch(connectionProtocol){
		case kLakeShore336UseUSB:
			[self connectUSB];
			break;
		case kLakeShore336UseIP: 
			if(!ipConnected && !socket) [self connectIP]; 
			break;
	}	
}


- (BOOL) isConnected
{
	switch(connectionProtocol){
		case kLakeShore336UseUSB:
			if(!usbConnected && !usbInterface)[self connectUSB];
			return YES;	
			break;
		case kLakeShore336UseIP: 
			if(!ipConnected && !socket) [self connectIP]; 
			return ipConnected;
			break;
	}
	return NO;
}

- (void) connectUSB
{
}

- (void) connectIP
{
	if(!ipConnected){
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:kLakeShore336Port]];	
	}
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIpConnected:YES];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
    if(inNetSocket == socket){
		NSString* theString = [inNetSocket readString:NSASCIIStringEncoding];
        [self process_response:theString];
    }
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIpConnected:NO];
		[socket autorelease];
		socket = nil;
    }
}


#pragma mark •••Hardware Access
- (void) addCmdToQueue:(NSString*)aCmd
{
    if([self isConnected]){
		if(!cmdQueue)cmdQueue = [[ORSafeQueue alloc] init];
		[cmdQueue enqueue:aCmd];
		if(!lastRequest){
			[self processOneCommandFromQueue];
		}
	}
}

- (id) nextCmd
{
	return [cmdQueue dequeue];
}

- (void) cancelTimeout
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
}

- (void) startTimeout:(int)aDelay
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:aDelay];
}

- (void) readIDString
{
    [self addCmdToQueue:@"*IDN?"];
}

- (void) readInput:(int) i
{
    if(i>=0 && i<4){
        NSString* s = [NSString stringWithFormat:@"INTYPE%c?",'A'+i];
        [self addCmdToQueue:s];
    }
}

- (void) systemTest
{
    [self addCmdToQueue:@"*TST?"];
}

- (void) resetAndClear
{
    [self writeToDevice:@"*RST;*CLS"];
}

- (void) loadHeaterParameters
{
    for(id aHeater in heaters){
        [self writeToDevice:[aHeater heaterSetupString]];
        [self writeToDevice:[aHeater pidSetupString]];
        [self writeToDevice:[aHeater outputSetupString]];
    }
}

- (void) loadInputParameters
{
    for(id anInput in inputs){
        [self writeToDevice:[anInput inputSetupString]];
        [self writeToDevice:[anInput setPointString]];
    }
    
}

- (void) setInputs:(NSMutableArray*)anArray
{
    [anArray retain];
    [inputs release];
    inputs = anArray;
}

- (void) setHeaters:(NSMutableArray*)anArray
{
    [anArray retain];
    [heaters release];
    heaters = anArray;
}

- (void) setUpArrays
{
    if(!inputs){
        inputs = [[NSMutableArray array] retain];
        int i;
        for(i=0;i<4;i++){
            ORLakeShore336Input* anInput = [[ORLakeShore336Input alloc] init];
            [anInput setChannel:i];
            [anInput setLabel:[NSString stringWithFormat:@"%c",'A'+i]];
            [inputs addObject: anInput];
            [anInput release];
        }
    }
    
    if(!heaters){
        heaters = [[NSMutableArray array] retain];
        int i;
        for(i=0;i<2;i++){
            ORLakeShore336Heater* aHeater = [[ORLakeShore336Heater alloc] init];
            [aHeater setChannel:i];
            [aHeater setLabel:[NSString stringWithFormat:@"%d",i+1]];
            [heaters addObject:aHeater];
            [aHeater release];

        }
    }
}
- (NSMutableArray*)inputs  { return inputs;  }
- (NSMutableArray*)heaters { return heaters; }

- (id)   input:(int)anIndex
{
    if(anIndex>=0 && anIndex<4) return [inputs objectAtIndex:anIndex];
    else                        return nil;
}

- (id)   heater:(int)anIndex
{
    if(anIndex>=0 && anIndex<2) return [heaters objectAtIndex:anIndex];
    else                        return nil;
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setSerialNumber:          [decoder decodeObjectForKey:    @"serialNumber"]];
	[self setIpAddress:             [decoder decodeObjectForKey:    @"ipAddress"]];
    [self setConnectionProtocol:    [decoder decodeIntForKey:       @"connectionProtocol"]];
    [self setInputs:                [decoder decodeObjectForKey:    @"inputs"]];
    [self setHeaters:               [decoder decodeObjectForKey:    @"heaters"]];
    [self setPollTime:              [decoder decodeIntForKey:       @"pollTime"]];
    [[self undoManager] enableUndoRegistration];
    
    [self setUpArrays];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:serialNumber      forKey:@"serialNumber"];
    [encoder encodeObject:ipAddress         forKey:@"ipAddress"];
    [encoder encodeInt:connectionProtocol   forKey:@"connectionProtocol"];
    [encoder encodeInt:pollTime             forKey:@"pollTime"];
    [encoder encodeObject:inputs            forKey:@"inputs"];
    [encoder encodeObject:heaters           forKey:@"heaters"];
}

#pragma mark ***Comm methods
- (void) readFromDevice
{
    if(![self isConnected])return;
	switch(connectionProtocol){
		case kLakeShore336UseUSB:
			if(usbInterface && [self getUSBController]){
                unsigned char buffer[256];
				int numCharReturned =  [usbInterface readBytes:buffer length:256];
                if(numCharReturned>0){
                    NSString* s = [[NSString alloc] initWithBytes:buffer length:numCharReturned encoding:NSASCIIStringEncoding];
                    [self process_response:s];
                    [s autorelease];
                }
			}
			else {
				NSString *errorMsg = @"Must establish connection prior to issuing command\n";
				[ NSException raise: ORLakeShore336ConnectionError format: @"%@",errorMsg ];
				
			}
			break;
		case kLakeShore336UseIP: 
			//nothing to do... we'll be notified 
			//when any data arrives in the  netsocket:dataAvailable: method
			break;
	}
}

- (void) writeToDevice: (NSString*) aCommand
{
    if(![self isConnected])return;
    
    if(![aCommand hasSuffix:@"\r"])aCommand = [aCommand stringByAppendingString:@"\r"];

	switch(connectionProtocol){
			
		case kLakeShore336UseUSB:
			if(usbInterface && [self getUSBController]){
				[usbInterface writeString:aCommand];
			}
			else {
				NSString *errorMsg = @"Must establish connection prior to issuing command\n";
				[ NSException raise: ORLakeShore336ConnectionError format:@"%@", errorMsg ];
				
			}
			break;
			
		case kLakeShore336UseIP: 
			if([self isConnected]){
                if([aCommand length]){
                    [self performSelectorOnMainThread:@selector(mainThreadSocketWrite:) withObject:aCommand waitUntilDone:YES];
				}
			}
			else {
				NSString *errorMsg = @"Must establish IP connection prior to issuing command.\n";
				[ NSException raise: ORLakeShore336ConnectionError format: @"%@",errorMsg ];
				
			} 			
			break;
	}
}

- (void) makeUSBClaim:(NSString*)aSerialNumber
{
	
}

- (void) timeout
{
	[self setTimeoutCount: timeoutCount+1];
	if(timeoutCount>10){
		[self postTimeoutAlarm];
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"command timeout",[self fullID],nil);
	[self setIsValid:NO];
	[cmdQueue removeAllObjects];
	[self setLastRequest:nil];
	//if([serialPort isOpen]){
	//	[self recoverFromTimeout];
	//}
}

- (void) recoverFromTimeout
{
}

- (void) clearTimeoutAlarm
{
	[timeoutAlarm clearAlarm];
	[timeoutAlarm release];
	timeoutAlarm = nil;
}

- (void) postTimeoutAlarm
{
	if(!timeoutAlarm){
		NSString* alarmName = [NSString stringWithFormat:@"%@ Serial Port Timeout",[self fullID]];
		timeoutAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kHardwareAlarm];
		[timeoutAlarm setSticky:NO];
		[timeoutAlarm setHelpString:@"The serial port is not working. The port was closed. Acknowledging this alarm will clear it. You will need to reopen the serial port to try again."];
		[cmdQueue removeAllObjects];
		[self setLastRequest:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336PortClosedAfterTimeout object:self];
	}
	[timeoutAlarm postAlarm];
}
#pragma mark •••Bit Processing Protocol
- (void) processIsStarting
{
}

- (void) processIsStopping
{
}

//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{
}

- (void) endProcessCycle
{
}

- (BOOL) processValue:(int)channel
{
	return 1; //not used, just return true
}

- (void) setProcessOutput:(int)channel value:(int)value
{
}

- (NSString*) identifier
{
	NSString* s;
 	@synchronized(self){
        s =  [NSString stringWithFormat:@"LS336,%lu",[self uniqueIdNumber]];
    }
    return s;
}

- (NSString*) processingTitle
{
	NSString* s;
 	@synchronized(self){
        s =  [self identifier];
    }
    return s;
}

- (double) convertedValue:(int)aChan
{
    double theValue = 0;
 	@synchronized(self){
        if(aChan>=0 && aChan<4){
            theValue = [[inputs objectAtIndex:aChan] temperature];
        }
        else if(aChan>=4 && aChan<6){
            theValue = [[heaters objectAtIndex:aChan-4] output];
        }
    }
    return theValue;
}
- (double) maxValueForChan:(int)aChan
{
    double theValue = 0;
 	@synchronized(self){
        if(aChan>=0 && aChan<4){
            theValue = [[inputs objectAtIndex:aChan] maxValue];
        }
        else if(aChan>=4 && aChan<6){
            theValue = [[heaters objectAtIndex:aChan-4] maxValue];
        }
    }
    return theValue;
}

- (double) minValueForChan:(int)aChan
{
    double theValue = 0;
 	@synchronized(self){
        if(aChan>=0 && aChan<4){
            theValue = [[inputs objectAtIndex:aChan] minValue];
        }
        else if(aChan>=4 && aChan<6){
            theValue = [[heaters objectAtIndex:aChan-4] minValue];
        }
    }
    return theValue;
}

- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		if(channel>=0 && channel<4){
			*theLowLimit  = [[inputs objectAtIndex:channel] lowLimit];
			*theHighLimit = [[inputs objectAtIndex:channel] highLimit];
		}
		else if(channel>=4 && channel<6){
			*theLowLimit  = [[heaters objectAtIndex:channel-4] lowLimit];
			*theHighLimit = [[heaters objectAtIndex:channel-4] highLimit];
		}
		else {
			*theLowLimit = 0;
			*theHighLimit = 300;
		}
	}
}

@end

@implementation ORLakeShore336Model (private)
- (void) postCouchDBRecord
{
    if([inputs count]>=4){
        NSDictionary* values = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSArray arrayWithObjects:
                                 [NSNumber numberWithInt:[[inputs objectAtIndex:0]temperature]],
                                 [NSNumber numberWithInt:[[inputs objectAtIndex:1]temperature]],
                                 [NSNumber numberWithInt:[[inputs objectAtIndex:2]temperature]],
                                 [NSNumber numberWithInt:[[inputs objectAtIndex:3]temperature]],
                                  nil], @"temperatures",
                                [NSNumber numberWithInt:    pollTime],     @"pollTime",
                                nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
    }
}

- (void) processOneCommandFromQueue
{
 	@synchronized(self){
        NSString* aCmd = [self nextCmd];
        if(aCmd){
            if(![aCmd hasSuffix:@"\n"]) aCmd = [aCmd stringByAppendingString:@"\n"];
            
            [self writeToDevice: aCmd];
            if([aCmd rangeOfString:@"?"].length != NSNotFound){
                [self setLastRequest:aCmd];
                [self readFromDevice];
                [self startTimeout:3];
            }
            else {
                [self setLastRequest:nil];
                [self performSelector:@selector(processOneCommandFromQueue) withObject:self afterDelay:.01];
            }
        }
    }
}

- (void) process_response:(NSString*)theResponse
{
    [self setIsValid:YES];
    theResponse = [theResponse stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    theResponse = [theResponse stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    if([lastRequest hasPrefix:@"*IDN"])NSLog(@"%@\n",theResponse);
    else if([lastRequest hasPrefix:@"KRDG?"]){
        NSString* channel = [lastRequest substringFromIndex:6];
        if([channel hasPrefix:@"A"])[[inputs objectAtIndex:0] setTemperature:[theResponse floatValue]];
        else if([channel hasPrefix:@"B"])[[inputs objectAtIndex:1] setTemperature:[theResponse floatValue]];
        else if([channel hasPrefix:@"C"])[[inputs objectAtIndex:2] setTemperature:[theResponse floatValue]];
        else if([channel hasPrefix:@"D"])[[inputs objectAtIndex:3] setTemperature:[theResponse floatValue]];
    }
    else if([lastRequest hasPrefix:@"HTR?"]){
        NSString* channel = [lastRequest substringFromIndex:5];
        if([channel hasPrefix:@"1"])[[heaters objectAtIndex:0] setOutput:[theResponse floatValue]];
        else if([channel hasPrefix:@"2"])[[heaters objectAtIndex:1] setOutput:[theResponse floatValue]];
    }
    else if([lastRequest hasPrefix:@"INTYPE"]){
       // int i = [NSString ]
        
    }
    if([lastRequest rangeOfString:@"?"].location!=NSNotFound){
        [self cancelTimeout];
    }
    [self clearTimeoutAlarm];
    [self setLastRequest:nil];
    [self processOneCommandFromQueue];
}

- (void) mainThreadSocketWrite:(NSString*)aCommand
{
	[socket writeString:aCommand encoding:NSASCIIStringEncoding];
}
@end
