//
//  ORPulser33500Model.m
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
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


#pragma mark •••Imported Files
#import "ORPulser33500Model.h"
#import "ORUSBInterface.h"
#import "NetSocket.h"
#import "ORPulser33500Chan.h"


NSString* ORPulser33500SerialNumberChanged			= @"ORPulser33500SerialNumberChanged";
NSString* ORPulser33500CanChangeConnectionProtocolChanged = @"ORPulser33500CanChangeConnectionProtocolChanged";
NSString* ORPulser33500IpConnectedChanged			= @"ORPulser33500IpConnectedChanged";
NSString* ORPulser33500UsbConnectedChanged			= @"ORPulser33500UsbConnectedChanged";
NSString* ORPulser33500IpAddressChanged				= @"ORPulser33500IpAddressChanged";
NSString* ORPulser33500ConnectionProtocolChanged	= @"ORPulser33500ConnectionProtocolChanged";
NSString* ORPulser33500USBInConnection				= @"ORPulser33500USBInConnection";
NSString* ORPulser33500USBNextConnection			= @"ORPulser33500USBNextConnection";
NSString* ORPulser33500USBInterfaceChanged			= @"ORPulser33500USBInterfaceChanged";
NSString* ORPulser33500LoadingChanged				= @"ORPulser33500LoadingChanged";
NSString* ORPulser33500Lock							= @"ORPulser33500Lock";
NSString* ORPulser33500ShowInKHzChanged				= @"ORPulser33500ShowInKHzChanged";


@implementation ORPulser33500Model
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self makeChannels];
    [[self undoManager] enableUndoRegistration];
    return self;
}
- (void) dealloc
{
    [channels release];   
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [serialNumber release];
	[ipAddress release];
	[socket close];
    [socket setDelegate:nil];
	[socket release];
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
	if(![[ self connectors ] objectForKey:ORPulser33500USBInConnection]){
		ORConnector* connectorObj1 = [[ ORConnector alloc ] 
									  initAt: NSMakePoint( 2, 2 )
									  withGuardian: self];
		[[ self connectors ] setObject: connectorObj1 forKey: ORPulser33500USBInConnection ];
		[ connectorObj1 setConnectorType: 'USBI' ];
		[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to gpib outputs
		[connectorObj1 setOffColor:[NSColor yellowColor]];
		[ connectorObj1 release ];
	}
	
	if(![[ self connectors ] objectForKey:ORPulser33500USBNextConnection]){
		ORConnector* connectorObj2 = [[ ORConnector alloc ] 
									  initAt: NSMakePoint( [self frame].size.width-kConnectorSize-2, 2 )
									  withGuardian: self];
		[[ self connectors ] setObject: connectorObj2 forKey: ORPulser33500USBNextConnection ];
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
		if(connectionProtocol == kPulser33500UseGPIB) {
			[self removeConnectorForKey:ORPulser33500USBInConnection];
			[self removeConnectorForKey:ORPulser33500USBNextConnection];
			[self makeGPIBConnectors];
		}
		else if(connectionProtocol == kPulser33500UseUSB) {
			[self removeConnectorForKey:ORGpibConnection];
			[self removeConnectorForKey:ORGpibConnectionToNextDevice];
			[self makeUSBConnectors];
		}
		else { //kPulser33500UseIP
			[self removeConnectorForKey:ORPulser33500USBInConnection];
			[self removeConnectorForKey:ORPulser33500USBNextConnection];
			[self removeConnectorForKey:ORGpibConnection];
			[self removeConnectorForKey:ORGpibConnectionToNextDevice];
		}
	}
}

- (void) makeChannels
{
    [self setChannels:[NSMutableArray arrayWithCapacity:2]];
    int i;
    for(i=0;i<2;i++){
        ORPulser33500Chan* aChannel = [[ORPulser33500Chan alloc] initWithPulser:self channelNumber:i+1];
        [channels addObject:aChannel];
        [aChannel release];
    }
}


- (void) makeMainController
{
    [self linkToController:@"ORPulser33500Controller"];
}

- (NSString*) helpURL
{
	return @"GPIB/Aglient_33500.html";
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
	if([self objectConnectedTo:ORPulser33500USBInConnection] || [self objectConnectedTo:ORPulser33500USBNextConnection] ||
	   [self objectConnectedTo:ORGpibConnection] || [self objectConnectedTo:ORGpibConnectionToNextDevice]){
		[self setCanChangeConnectionProtocol:NO];
	}
	else {
		[self setCanChangeConnectionProtocol:YES];
	}
	NSArray* interfaces = [[self getUSBController] interfacesForVenders:[self vendorIDs] products:[self productIDs]];
	NSString* sn = serialNumber;
	if([interfaces count] == 1 && ![sn length]){
		sn = [[interfaces objectAtIndex:0] serialNumber];
	}
	[self setSerialNumber:sn]; //to force usbinterface at doc startup
	[self checkNoUsbAlarm];	
	[[self objectConnectedTo:ORPulser33500USBNextConnection] connectionChanged];
	[self setUpImage];
}


-(void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"Pulser33500Icon"];
	
    NSSize theIconSize = [aCachedImage size];
    NSPoint theOffset = NSZeroPoint;
    NSImage* netConnectIcon = nil;
    if(connectionProtocol == kPulser33500UseIP){
        netConnectIcon = [NSImage imageNamed:@"NetConnect"];
        theIconSize.width += 10;
    }
    
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    if(connectionProtocol == kPulser33500UseIP){
        [netConnectIcon drawAtPoint:NSZeroPoint fromRect:[netConnectIcon imageRect] operation:NSCompositeSourceOver fraction:1.0];
        theOffset.x += 10;
    }
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];	
    if(connectionProtocol == kPulser33500UseUSB && (!usbInterface || ![self getUSBController])){
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
    
}

- (NSString*) title 
{
	switch (connectionProtocol){
		case kPulser33500UseGPIB:	return [NSString stringWithFormat:@"33500 Pulser (GPIB %d)",[self primaryAddress]];
		case kPulser33500UseUSB:	return [NSString stringWithFormat:@"33500 Pulser (Serial# %@)",[usbInterface serialNumber]];
		case kPulser33500UseIP:	return [NSString stringWithFormat:@"33500 Pulser (%@)",[self ipAddress]];
	}
	return [NSString stringWithFormat:@"33500 Pulser (%d)",[self tag]];
}

- (NSArray*) vendorIDs
{
    return @[@0x0957,@0x0957];
}

- (NSArray*) productIDs
{
    return @[@0x2307,@0x2c07];
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORPulser33500USBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

#pragma mark ***Accessors
- (BOOL) showInKHz
{
    return showInKHz;
}

- (void) setShowInKHz:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowInKHz:showInKHz];
    
    showInKHz = aFlag;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33500ShowInKHzChanged object:self];

}

- (BOOL) loading
{
	return loading;
}
- (void) setLoading:(BOOL)aState
{
	loading = aState;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33500LoadingChanged object:self];
}

- (BOOL) waitForGetWaveformsLoadedDone
{
	return waitForGetWaveformsLoadedDone;
}
- (void) setWaitForGetWaveformsLoadedDone:(BOOL)aState
{
	waitForGetWaveformsLoadedDone = aState;
}

- (BOOL) waitForAsyncDownloadDone
{
	return waitForAsyncDownloadDone;
}
- (void) setWaitForAsyncDownloadDone:(BOOL)aState
{
	waitForAsyncDownloadDone = aState;
}

- (NSMutableArray*)channels
{	
    return channels;
}

- (void) setChannels:(NSMutableArray*)someChannels
{
    [someChannels retain];
    [channels release];
    channels = someChannels;
}

- (NSString*) serialNumber
{
	if(!serialNumber)return @"";
    else return serialNumber;
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33500SerialNumberChanged object:self];
}

- (BOOL) canChangeConnectionProtocol
{
    return canChangeConnectionProtocol;
}

- (void) setCanChangeConnectionProtocol:(BOOL)aCanChangeConnectionProtocol
{
    canChangeConnectionProtocol = aCanChangeConnectionProtocol;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33500CanChangeConnectionProtocolChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33500IpConnectedChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33500UsbConnectedChanged object:self];
}

- (NSString*) ipAddress
{
	if(!ipAddress)return @"";
    else return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
	if(!aIpAddress)aIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
    
    [ipAddress autorelease];
    ipAddress = [aIpAddress copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33500IpAddressChanged object:self];
}

- (int) connectionProtocol
{
    return connectionProtocol;
}

- (void) setConnectionProtocol:(int)aConnectionProtocol
{
	[[[self undoManager] prepareWithInvocationTarget:self] setConnectionProtocol:connectionProtocol];
	
	connectionProtocol = aConnectionProtocol;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33500ConnectionProtocolChanged object:self];
	[self setUpImage];
}


#pragma mark •••HW Commands
- (NSString*) readIDString
{
    if([self isConnected]){
        char reply[1024];
        reply[0]='\0';
        long n = [self writeReadDevice:@"*IDN?" data:reply maxLength:1024];
        if(n>0)reply[n-1]='\0';
        NSMutableString* rs =  [NSMutableString stringWithCString:reply encoding:NSASCIIStringEncoding];
		if(rs){
			NSInteger lfPos = [rs rangeOfString:@"\n"].location;
			if(lfPos != NSNotFound)return [rs substringToIndex:lfPos ];
		}
		return rs;
    }
    else {
        return @"Not Connected";
    }
}

- (void) resetAndClear
{
    if([self isConnected]){
        [self writeToDevice:@"*RST;*CLS"];
    }
}

- (void) systemTest
{
    if([self isConnected]){
		[self writeToDevice:@"*TST?"];
        NSLog(@"33500 Pulser Test.\n");
    }
}



- (void) initHardware
{
    if([self isConnected]){
		if([channels count]==2){
			int i;
			for(i=0;i<2;i++){
				[[channels objectAtIndex:i] initHardware];
			} 
		}
    }
}


- (void) setUsbInterface:(ORUSBInterface*)anInterface
{
	
	if(connectionProtocol == kPulser33500UseUSB){
		
		[self enableEOT:YES];
		[usbInterface release];
		usbInterface = anInterface;
		[usbInterface retain];
		
		[usbInterface writeUSB488Command:@"SYST:COMM:RLST REM;*WAI" eom:YES];
		[usbInterface writeUSB488Command:@"OUTPUT 1;*WAI" eom:YES];
		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: ORPulser33500USBInterfaceChanged
		 object: self];
		
		[self setUpImage];
		
	}
}

- (void) interfaceAdded:(NSNotification*)aNote
{
	if(connectionProtocol == kPulser33500UseUSB){
		[[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
		[self checkNoUsbAlarm];			
	}
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
	if(connectionProtocol == kPulser33500UseUSB){
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
	if((connectionProtocol != kPulser33500UseUSB) || (usbInterface && [self getUSBController]) || !guardian){
		[noUSBAlarm clearAlarm];
		[noUSBAlarm release];
		noUSBAlarm = nil;
	}
	else {
		if(guardian && [self aWake]){
			if(!noUSBAlarm){
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for 33500 Pulser"] severity:kHardwareAlarm];
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
	return [[self getUSBController]  interfacesForVenders:[self vendorIDs] products:[self productIDs]];
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
	if(connectionProtocol == kPulser33500UseIP){
		[self writeToDevice:@"SYST:ERR?"];
	}
	else {
		return;   //stopped asking for response because of device time-outs and errors. MAH 12/18/09
		char reply[1024];
		long n = [self writeReadDevice:@"SYST:ERR?" data:reply maxLength:1024];
		if(n && [[NSString stringWithCString:reply encoding:NSASCIIStringEncoding] rangeOfString:@"No error"].location == NSNotFound){
			NSLog(@"%s\n",reply);
		}
		
	}
}

- (void) connect
{
	switch(connectionProtocol){
		case kPulser33500UseGPIB: 
			[super connect];		
			break;
		case kPulser33500UseUSB: 
			[self connectUSB];
			break;
		case kPulser33500UseIP: 
			if(!ipConnected && !socket) [self connectIP]; 
			break;
	}	
}

- (BOOL) isConnected
{
	switch(connectionProtocol){
		case kPulser33500UseGPIB: 
			return [super isConnected];		
			break;
		case kPulser33500UseUSB: 
			if(!usbConnected && !usbInterface)[self connectUSB];
			return YES;	
			break;
		case kPulser33500UseIP: 
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
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:kPulser33500Port]];	
	}
}



#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
		[self enableEOT:YES];
        [self setIpConnected:[socket isConnected]];
		if(ipConnected){
			[self writeToDevice:@"SYST:COMM:RLST REM"];
            //------
            //commented out MAH 3/25/13 -- setWaitForGetWaveformsLoadedDone: doesn't exist in the chan object... throwing an unrecognized selector exception
			//for(id aChannel in channels){
			//	[aChannel setWaitForGetWaveformsLoadedDone:YES];
			//}
            //-------
			[self writeToDevice:@"Data:CAT?;*WAI;*OPC?"];
		}
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
    if(inNetSocket == socket){
		NSString* theString = [[inNetSocket readString:NSASCIIStringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		theString = [[theString componentsSeparatedByString:@"\n"] componentsJoinedByString:@","];
		theString = [[theString componentsSeparatedByString:@";"] componentsJoinedByString:@","];
		NSArray* theParts = [theString componentsSeparatedByString:@","];
		NSEnumerator* e = [theParts objectEnumerator];
		NSString* aLine;
		if(!waitForGetWaveformsLoadedDone && !waitForAsyncDownloadDone){
			NSLog(@"%@\n",theString);
		}
		else while(aLine = [e nextObject]){
			aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([aLine isEqualToString:@"1"]){
				if(waitForGetWaveformsLoadedDone){
					waitForGetWaveformsLoadedDone = NO;
					theString = [[theString componentsSeparatedByString:@"\""] componentsJoinedByString:@""];
					theString = [theString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
					NSRange junkRange = [theString rangeOfString:@",1"];
					if(junkRange.location != NSNotFound){
						theString = [theString substringToIndex:junkRange.location];
					}
				}
				else if(waitForAsyncDownloadDone){
					[self asyncDownloadFinished];
				}
			}
		}
    }
}
- (void) asyncDownloadFinished
{
	waitForAsyncDownloadDone = NO;
	for(id aChannel in channels){
		[aChannel setLoading:NO];
	}
	waitForGetWaveformsLoadedDone = YES;
	[self writeToDevice:@"Data:CAT?;*WAI;*OPC?"];
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
    [self setSerialNumber:		 [decoder decodeObjectForKey:@"serialNumber"]];
	[self setIpAddress:			 [decoder decodeObjectForKey:@"ipAddress"]];
    [self setConnectionProtocol: [decoder decodeIntForKey:@"connectionProtocol"]];
    [self setChannels:			 [decoder decodeObjectForKey: @"channels"]];
    [self setShowInKHz:			 [decoder decodeBoolForKey: @"showInKHz"]];
	
	if(!channels)[self makeChannels];
	for(id aChannel in channels) [aChannel setPulser:self];
	
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:serialNumber		forKey:@"serialNumber"];
    [encoder encodeObject:ipAddress			forKey:@"ipAddress"];
    [encoder encodeInt:connectionProtocol	forKey:@"connectionProtocol"];
    [encoder encodeObject:channels			forKey:@"channels"];
    [encoder encodeBool:showInKHz           forKey:@"showInKHz"];
}



- (void) enableEOT: (BOOL) state
{
	if(connectionProtocol == kPulser33500UseGPIB ){
		[super enableEOT:state];
	}
	else {
		mEOT = state;
	}
}

#pragma mark ***Comm methods
- (long) writeReadDevice: (NSString*) aCommand data: (char*) aData maxLength: (long) aMaxLength
{
    [ self writeToDevice: aCommand ];
    return( [ self readFromDevice: aData maxLength: aMaxLength ] );
}
- (long) readFromDevice: (char*) aData maxLength: (long) aMaxLength
{
	switch(connectionProtocol){
		case kPulser33500UseGPIB: return [super readFromGPIBDevice:aData maxLength:aMaxLength];
		case kPulser33500UseUSB:  
			if(usbInterface && [self getUSBController]){
				return [usbInterface readUSB488:aData length:aMaxLength];;
			}
			else {
				NSString *errorMsg = @"Must establish connection prior to issuing command\n";
				[ NSException raise: OExceptionGPIBConnectionError format: @"%@",errorMsg ];
				
			}
			break;
		case kPulser33500UseIP: 
			//nothing to do... all incoming data is initiated by us and we'll be notified 
			//when any data arrives in the  netsocket:dataAvailable: method
			break;
	}
	return 0;
}

- (void) writeToDevice: (NSString*) aCommand
{
	switch(connectionProtocol){
		case kPulser33500UseGPIB:  [super writeToGPIBDevice:aCommand]; break;
			
		case kPulser33500UseUSB:
			if(usbInterface && [self getUSBController]){
				if(mEOT)aCommand = [aCommand stringByAppendingString:@"\n"];
				[usbInterface writeUSB488Command:aCommand eom:mEOT];
			}
			else {
				NSString *errorMsg = @"Must establish connection prior to issuing command\n";
				[ NSException raise: OExceptionGPIBConnectionError format:@"%@", errorMsg ];
				
			}
			break;
			
		case kPulser33500UseIP: 
			if([self isConnected]){
				if(mEOT)aCommand = [aCommand stringByAppendingString:@"\n"];
				[self performSelectorOnMainThread:@selector(mainThreadSocketSend:) withObject:aCommand waitUntilDone:YES];
				
			}
			else {
				NSString *errorMsg = @"Must establish IP connection prior to issuing command.\n";
				[ NSException raise: OExceptionGPIBConnectionError format: @"%@",errorMsg ];
				
			} 			
			break;
	}
}

- (void) mainThreadSocketSend:(NSString*)aCommand
{
	if(!aCommand)aCommand = @"";
	[socket writeString:aCommand encoding:NSASCIIStringEncoding];
}

- (void) makeUSBClaim:(NSString*)aSerialNumber
{
	
}


@end
