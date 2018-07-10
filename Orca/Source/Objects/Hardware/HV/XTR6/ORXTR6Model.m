//
//  ORXTR6Model.m
//  Orca
//
//  Created by Mark Howe on Jan 15, 2014 2003.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
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
#import "ORXTR6Model.h"
#import "ORUSBInterface.h"          //USB
#import "NetSocket.h"               //IP
#import "ORSerialPortAdditions.h"   //Serial

NSString* ORXTR6ModelOnOffStateChanged          = @"ORXTR6ModelOnOffStateChanged";
NSString* ORXTR6ModelCurrentChanged             = @"ORXTR6ModelCurrentChanged";
NSString* ORXTR6ModelVoltageChanged             = @"ORXTR6ModelVoltageChanged";
NSString* ORXTR6ModelTargetVoltageChanged       = @"ORXTR6ModelTargetVoltageVoltageChanged";
NSString* ORXTR6ModelChannelAddressChanged      = @"ORXTR6ModelChannelAddressChanged";
NSString* ORXTR6ModelCanChangeProtocolChanged   = @"ORXTR6ModelCanChangeProtocolChanged";
NSString* ORXTR6ModelSerialNumberChanged        = @"ORXTR6ModelSerialNumberChanged";
NSString* ORXTR6ModelIpConnectedChanged         = @"ORXTR6ModelIpConnectedChanged";
NSString* ORXTR6ModelIpAddressChanged           = @"ORXTR6ModelIpAddressChanged";
NSString* ORXTR6ModelConnectionProtocolChanged  = @"ORXTR6ModelConnectionProtocolChanged";
NSString* ORXTR6USBInConnection                 = @"ORXTR6USBInConnection";
NSString* ORXTR6USBNextConnection               = @"ORXTR6USBNextConnection";
NSString* ORXTR6ModelUSBInterfaceChanged        = @"ORXTR6ModelUSBInterfaceChanged";
NSString* ORXTR6ModelConnectionError            = @"ORXTR6ModelConnectionError";
NSString* ORXTR6Lock                            = @"ORXTR6Lock";

@interface ORXTR6Model (private)
- (void) addCmdToQueue:(NSString*)aCmd;
- (void) processOneCommandFromQueue;
- (void) processResponse:(NSString*)theResponse forCommand:(NSString*)aCommand;
@end

@implementation ORXTR6Model

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
	if(![[ self connectors ] objectForKey:ORXTR6USBInConnection]){
		ORConnector* connectorObj1 = [[ ORConnector alloc ] 
									  initAt: NSMakePoint( 0, 0 )
									  withGuardian: self];
		[[ self connectors ] setObject: connectorObj1 forKey: ORXTR6USBInConnection ];
		[ connectorObj1 setConnectorType: 'USBI' ];
		[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to USB outputs
		[connectorObj1 setOffColor:[NSColor yellowColor]];
		[ connectorObj1 release ];
	}
	
	if(![[ self connectors ] objectForKey:ORXTR6USBNextConnection]){
		ORConnector* connectorObj2 = [[ ORConnector alloc ] 
									  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, 0 )
									  withGuardian: self];
		[[ self connectors ] setObject: connectorObj2 forKey: ORXTR6USBNextConnection ];
		[ connectorObj2 setConnectorType: 'USBO' ];
		[ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to USB inputs
		[connectorObj2 setOffColor:[NSColor yellowColor]];
		[ connectorObj2 release ];
	}
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
	[self checkNoUsbAlarm];
}

- (void) adjustConnectors:(BOOL)force
{
	if(canChangeConnectionProtocol || force){
        [self removeConnectorForKey:ORXTR6USBInConnection];
        [self removeConnectorForKey:ORXTR6USBNextConnection];
		if(connectionProtocol == kHPXTR6UseUSB) {
			[self makeUSBConnectors];
		}
	}
}

- (void) makeMainController
{
    [self linkToController:@"ORXTR6Controller"];
}

- (void) dealloc
{
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [serialNumber release];
	[ipAddress release];
	[socket close];
    [socket setDelegate:nil];
	[socket release];
    [buffer release];
    [super dealloc];
}

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
	if([self objectConnectedTo:ORXTR6USBInConnection] || [self objectConnectedTo:ORXTR6USBNextConnection]){
		[self setCanChangeConnectionProtocol:NO];
	}
	else {
		[self setCanChangeConnectionProtocol:YES];
	}
    if(connectionProtocol == kHPXTR6UseUSB){
        NSArray* interfaces = [[self getUSBController] interfacesForVender:[self vendorID] product:[self productID]];
        NSString* sn = serialNumber;
        if([interfaces count] == 1 && ![sn length]){
            sn = [[interfaces objectAtIndex:0] serialNumber];
        }
        [self setSerialNumber:sn]; //to force usbinterface at doc startup
        [[self objectConnectedTo:ORXTR6USBNextConnection] connectionChanged];
    }
    [self checkNoUsbAlarm];
	[self setUpImage];
}

-(void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"XTR6Icon"];
	
    NSSize theIconSize = [aCachedImage size];
    NSPoint theOffset = NSZeroPoint;
    NSImage* netConnectIcon = nil;
    if(connectionProtocol == kHPXTR6UseIP){
        netConnectIcon = [NSImage imageNamed:@"NetConnect"];
        NSSize netIconSize = [netConnectIcon size];
        netIconSize.height = theIconSize.height;
        netIconSize.width = 10;
        [netConnectIcon setSize:netIconSize];
        theIconSize.width += netIconSize.width;
    }
    
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    if(connectionProtocol == kHPXTR6UseIP){
        [netConnectIcon drawAtPoint:NSZeroPoint fromRect:[netConnectIcon imageRect] operation:NSCompositeSourceOver fraction:1.0];
        theOffset.x += 10;
    }
    [aCachedImage drawAtPoint:theOffset fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    if(connectionProtocol == kHPXTR6UseUSB && ![self isConnected]){
        NSBezierPath* path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(20,5)];
        [path lineToPoint:NSMakePoint(35,20)];
        [path moveToPoint:NSMakePoint(35,5)];
        [path lineToPoint:NSMakePoint(20,20)];
        [path setLineWidth:3];
        [[NSColor redColor] set];
        [path stroke];
    }    
	
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
}

- (NSString*) title 
{
	switch (connectionProtocol){
		case kHPXTR6UseRS232:	return [NSString stringWithFormat:@"XTR6 %lu",[self uniqueIdNumber]];
		case kHPXTR6UseUSB:     return [NSString stringWithFormat:@"XTR6 %lu (Serial# %@)",[self uniqueIdNumber],[usbInterface serialNumber]];
		case kHPXTR6UseIP:      return [NSString stringWithFormat:@"XTR6 %lu (%@)",[self uniqueIdNumber],[self ipAddress]];
	}
	return [NSString stringWithFormat:@"XTR6 (%d)",[self tag]];
}

#pragma mark ***Accessors

- (BOOL) onOffState
{
    return onOffState;
}

- (void) setOnOffState:(BOOL)aOnOffState
{
    onOffState = aOnOffState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXTR6ModelOnOffStateChanged object:self];
}

- (float) current
{
    return current;
}

- (void) setCurrent:(float)aCurrent
{
    current = aCurrent;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXTR6ModelCurrentChanged object:self];
}

- (float) voltage
{
    return voltage;
}

- (void) setVoltage:(float)aVoltage
{
    voltage = aVoltage;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXTR6ModelVoltageChanged object:self];
}

- (float) targetVoltage
{
    return targetVoltage;
}

- (void) setTargetVoltage:(float)aTarget
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTargetVoltage:targetVoltage];
    targetVoltage = aTarget;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXTR6ModelTargetVoltageChanged object:self];
}
- (int) channelAddress
{
    return channelAddress;
}

- (void) setChannelAddress:(int)aChannelAddress
{
    if(aChannelAddress<1)       aChannelAddress=1;
    else if(aChannelAddress>30) aChannelAddress=30;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setChannelAddress:channelAddress];
    channelAddress = aChannelAddress;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXTR6ModelChannelAddressChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXTR6ModelSerialNumberChanged object:self];
}

- (BOOL) canChangeConnectionProtocol
{
    return canChangeConnectionProtocol;
}

- (void) setCanChangeConnectionProtocol:(BOOL)aCanChangeConnectionProtocol
{
    canChangeConnectionProtocol = aCanChangeConnectionProtocol;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXTR6ModelCanChangeProtocolChanged object:self];
}



- (ORUSBInterface*) usbInterface
{
	return usbInterface;
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXTR6ModelIpAddressChanged object:self];
}

- (int) connectionProtocol
{
    return connectionProtocol;
}

- (void) setConnectionProtocol:(int)aConnectionProtocol
{
	[[[self undoManager] prepareWithInvocationTarget:self] setConnectionProtocol:connectionProtocol];
	
	connectionProtocol = aConnectionProtocol;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXTR6ModelConnectionProtocolChanged object:self];
	[self setUpImage];
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface
{
	if(connectionProtocol == kHPXTR6UseUSB){
		[usbInterface release];
		usbInterface = anInterface;
		[usbInterface retain];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: ORXTR6ModelUSBInterfaceChanged object: self];
		
		[self setUpImage];
	}
}

- (void) interfaceAdded:(NSNotification*)aNote
{
	if(connectionProtocol == kHPXTR6UseUSB){
		[[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
		[self checkNoUsbAlarm];			
	}
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
	if(connectionProtocol == kHPXTR6UseUSB){
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
	if((connectionProtocol != kHPXTR6UseUSB) || (usbInterface && [self getUSBController]) || !guardian){
		[noUSBAlarm clearAlarm];
		[noUSBAlarm release];
		noUSBAlarm = nil;
	}
	else {
		if(guardian && [self aWake]){
			if(!noUSBAlarm){
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for XTR6"] severity:kHardwareAlarm];
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

- (void) connect
{
	switch(connectionProtocol){
		case kHPXTR6UseUSB: 
			[self connectUSB];
			break;
		case kHPXTR6UseIP: 
			if(!ipConnected && !socket) [self connectIP]; 
			break;
	}	
}

- (BOOL) isConnected
{
	switch(connectionProtocol){
		case kHPXTR6UseRS232:
			return [serialPort isOpen];
			break;
            
		case kHPXTR6UseUSB: 
			if(!usbInterface)[self connectUSB];
			return (usbInterface && [self getUSBController]);	
			break;
            
		case kHPXTR6UseIP: 
			if(!ipConnected && !socket) [self connectIP]; 
			return ipConnected;
			break;
	}
	return NO;
}

#pragma mark ***RS232 Methods
- (void) setUpPort
{
	[serialPort setSpeed:9600];
	[serialPort setParityNone];
	[serialPort setStopBits2:NO];
	[serialPort setDataBits:8];
}

- (void) dataReceived:(NSNotification*)note
{
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		
        NSString* theString = [[[[NSString alloc] initWithData:[[note userInfo] objectForKey:@"data"]
												      encoding:NSASCIIStringEncoding] autorelease] uppercaseString];
        
		//the serial port may break the data up into small chunks, so we have to accumulate the chunks until
		//we get a full piece.
        
        if(!buffer)buffer = [[NSMutableString string] retain];
        [buffer appendString:theString];
		
        do {
            NSRange lineRange = [buffer rangeOfString:@"\n"];
            if(lineRange.location!= NSNotFound){
                NSString* theResponse = [[[buffer substringToIndex:lineRange.location+1] copy] autorelease];
                [buffer deleteCharactersInRange:NSMakeRange(0,lineRange.location+1)];      //take the cmd out of the buffer
				
                [self processResponse:theResponse forCommand:lastRequest];
                [self setLastRequest:nil];			 //clear the last request
                [self processOneCommandFromQueue];	 //do the next command in the queue
                
            }
        } while([buffer rangeOfString:@"\r"].location!= NSNotFound);
	}
}

- (void) addCmdToQueue:(NSString*)aCmd
{
	if([serialPort isOpen]){
		[self enqueueCmd:aCmd];
		
		if(!lastRequest){
			[self processOneCommandFromQueue];
		}
	}
	else NSLog(@"XTR6 (%d): Serial Port not open. Cmd Ignored.\n",[self uniqueIdNumber]);
}

- (void) processOneCommandFromQueue
{
	NSString* aCmd = [self nextCmd];
    if(!aCmd)return;
    
    if([aCmd rangeOfString:@"?"].location != NSNotFound){
        [self startTimeout:3];
        [self setLastRequest:aCmd];
    }
    else {
        [self setLastRequest:nil];
    }
    [self writeToDevice:aCmd];
    
    if(!lastRequest){
        [self processOneCommandFromQueue];
    }
}


#pragma mark ***USB Methods
- (NSUInteger) vendorID
{
	return 0x403; //XTR6 vendorID
}

- (NSUInteger) productID
{
	return 0x6001; //XTR6 productID
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORXTR6USBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

- (void) connectUSB
{
}

- (void) makeUSBClaim:(NSString*)aSerialNumber
{
}

#pragma mark ***IP Methods
- (void) connectIP
{
	if(!ipConnected){
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:kXTR6Port]];
	}
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXTR6ModelIpConnectedChanged object:self];
}

#pragma mark ***Delegate Methods (IP connection)
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIpConnected:[socket isConnected]];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
    if(inNetSocket == socket){
        NSString* theResponse = [[inNetSocket readString:NSASCIIStringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self processResponse:theResponse forCommand:lastRequest];
    }
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIpConnected:[socket isConnected]];
        [self setIpConnected:NO];
		[socket autorelease];
		socket = nil;
    }
}


#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setTargetVoltage:     [decoder decodeFloatForKey:  @"targetVoltage"]];
    [self setChannelAddress:    [decoder decodeIntForKey:    @"channelAddress"]];
    [self setSerialNumber:      [decoder decodeObjectForKey: @"ORXTR6ModelSerialNumber"]];
	[self setIpAddress:         [decoder decodeObjectForKey: @"ORXTR6ModelIpAddress"]];
    [self setConnectionProtocol:[decoder decodeIntForKey:    @"ORXTR6ModelConnectionProtocol"]];
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:targetVoltage      forKey:@"targetVoltage"];
    [encoder encodeInt:channelAddress       forKey:@"channelAddress"];
    [encoder encodeObject:serialNumber      forKey:@"ORXTR6ModelSerialNumber"];
    [encoder encodeObject:ipAddress         forKey:@"ORXTR6ModelIpAddress"];
    [encoder encodeInt:connectionProtocol   forKey:@"ORXTR6ModelConnectionProtocol"];
}

#pragma mark ***Comm methods

- (void) readFromDevice: (char*) aData maxLength: (long) aMaxLength
{
	switch(connectionProtocol){
		case kHPXTR6UseRS232:
			//nothing to do... all incoming data is initiated by us and we'll be notified
			//when any data arrives in the dataAvailable method
            break;
		case kHPXTR6UseUSB:  
			if(usbInterface && [self getUSBController]){
				[usbInterface readBytes:aData length:aMaxLength];;
			}
			else {
				NSString *errorMsg = @"Must establish connection prior to issuing command\n";
				[ NSException raise: ORXTR6ModelConnectionError format: @"%@",errorMsg ];
				
			}
			break;
		case kHPXTR6UseIP: 
			//nothing to do... all incoming data is initiated by us and we'll be notified 
			//when any data arrives in the  netsocket:dataAvailable: method
			break;
	}
}

- (void) writeToDevice: (NSString*) aCommand
{
    if(![self isConnected])return;
    //not sure if all protocols use \n or \r
    if(![aCommand hasSuffix:@"\n"])aCommand = [aCommand stringByAppendingString:@"\n"];
   
	switch(connectionProtocol){
		case kHPXTR6UseRS232:
            //RS232 is totally asyncronous, so we queue the commands and handle them one by one.
            [self addCmdToQueue:aCommand];
            break;
			
		case kHPXTR6UseUSB:
			if(usbInterface && [self getUSBController]){
				[usbInterface writeString:aCommand];
                if([aCommand rangeOfString:@"?"].location != NSNotFound){
                    char reply[1024];
                    reply[0]='\0';
                    [self readFromDevice: reply maxLength: 1024];
                    [self processResponse:[NSMutableString stringWithCString:reply encoding:NSASCIIStringEncoding] forCommand:aCommand];
                }
			}
			else {
				NSString *errorMsg = @"Must establish connection prior to issuing command\n";
				[ NSException raise: ORXTR6ModelConnectionError format:@"%@", errorMsg ];
				
			}
			break;
			
		case kHPXTR6UseIP: 
			if([self isConnected]){
                [self setLastRequest:aCommand];
                [socket writeString:aCommand encoding:NSASCIIStringEncoding];
			}
			else {
				NSString *errorMsg = @"Must establish IP connection prior to issuing command.\n";
				[ NSException raise: ORXTR6ModelConnectionError format: @"%@",errorMsg ];
				
			} 			
			break;
	}
}

- (void) processResponse:(NSString*)theResponse forCommand:(NSString*)aCommand
{
    if([theResponse length] != 0){
        if([aCommand rangeOfString:@":VOLT?"].location != NSNotFound){
            [self setVoltage:[theResponse floatValue]];
        }
        else if([aCommand rangeOfString:@":CURR?"].location != NSNotFound){
            [self setCurrent:[theResponse floatValue]];
        }
        else if([aCommand rangeOfString:@"OUTP?"].location != NSNotFound){
            if([theResponse rangeOfString:@"ON"].location != NSNotFound)       [self setOnOffState:YES];
            else if([theResponse rangeOfString:@"OFF"].location != NSNotFound) [self setOnOffState:NO];
        }
        else if([aCommand rangeOfString:@"*IDN?"].location != NSNotFound){
            NSLog(@"Response: %@ for command: %@\n",theResponse,aCommand);
        }
    }
}


- (void) readIDString
{
    [self writeToDevice:@"*IDN?"];
}

- (void) getVoltage
{
    [self selectDevice];
    [self writeToDevice:@"MEASure:VOLT?"];
}

- (void) getCurrent
{
    [self selectDevice];
    [self writeToDevice:@"MEAS:CURR?"];
}
- (void) getPowerState
{
    [self selectDevice];
    [self writeToDevice:@"OUTP?"];
}
- (void) turnOnPower
{
    [self selectDevice];
    [self writeToDevice:@"OUTP ON"];
}

- (void) turnOffPower
{
    [self selectDevice];
    [self writeToDevice:@"OUTP OFF"];
}

- (void) systemTest
{
    [self writeToDevice:@"*TST?"];
    [self writeToDevice:[NSString stringWithFormat:@"*ADR %d",channelAddress]]; //set the address
}

- (void) loadParams
{
    [self selectDevice];
    [self writeToDevice:[NSString stringWithFormat:@"MEASure:VOLT %.2f",[self targetVoltage]]];
}

- (void) selectDevice
{
    [self writeToDevice:[NSString stringWithFormat:@"*ADR %d",channelAddress]]; //set the address
}
@end
