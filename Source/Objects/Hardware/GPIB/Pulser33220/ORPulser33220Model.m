//
//  ORPulser33220Model.m
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


#pragma mark ¥¥¥Imported Files
#import "ORPulser33220Model.h"
#import "ORUSBInterface.h"
#import "NetSocket.h"

#define kMaxNumberOfPoints33220 0xFFFF

NSString* ORPulser33220ModelSerialNumberChanged = @"ORPulser33220ModelSerialNumberChanged";
NSString* ORPulser33220ModelCanChangeConnectionProtocolChanged = @"ORPulser33220ModelCanChangeConnectionProtocolChanged";
NSString* ORPulser33220ModelIpConnectedChanged	= @"ORPulser33220ModelIpConnectedChanged";
NSString* ORPulser33220ModelIpAddressChanged	= @"ORPulser33220ModelIpAddressChanged";
NSString* ORPulser33220ModelConnectionProtocolChanged = @"ORPulser33220ModelConnectionProtocolChanged";
NSString* ORPulserUSBInConnection				= @"ORPulserUSBInConnection";
NSString* ORPulserUSBNextConnection				= @"ORPulserUSBNextConnection";
NSString* ORPulser33220ModelUSBInterfaceChanged = @"ORPulser33220ModelUSBInterfaceChanged";

@implementation ORPulser33220Model
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
	if(![[ self connectors ] objectForKey:ORPulserUSBInConnection]){
		ORConnector* connectorObj1 = [[ ORConnector alloc ] 
									  initAt: NSMakePoint( 2, 2 )
									  withGuardian: self];
		[[ self connectors ] setObject: connectorObj1 forKey: ORPulserUSBInConnection ];
		[ connectorObj1 setConnectorType: 'USBI' ];
		[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to gpib outputs
		[connectorObj1 setOffColor:[NSColor yellowColor]];
		[ connectorObj1 release ];
	}
	
	if(![[ self connectors ] objectForKey:ORPulserUSBNextConnection]){
		ORConnector* connectorObj2 = [[ ORConnector alloc ] 
									  initAt: NSMakePoint( [self frame].size.width-kConnectorSize-2, 2 )
									  withGuardian: self];
		[[ self connectors ] setObject: connectorObj2 forKey: ORPulserUSBNextConnection ];
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
		if(connectionProtocol == kHPPulserUseGPIB) {
			[self removeConnectorForKey:ORPulserUSBInConnection];
			[self removeConnectorForKey:ORPulserUSBNextConnection];
			[self makeGPIBConnectors];
		}
		else if(connectionProtocol == kHPPulserUseUSB) {
			[self removeConnectorForKey:ORGpibConnection];
			[self removeConnectorForKey:ORGpibConnectionToNextDevice];
			[self makeUSBConnectors];
		}
		else { //kHPPulserUseIP
			[self removeConnectorForKey:ORPulserUSBInConnection];
			[self removeConnectorForKey:ORPulserUSBNextConnection];
			[self removeConnectorForKey:ORGpibConnection];
			[self removeConnectorForKey:ORGpibConnectionToNextDevice];
		}
	}
}

- (void) makeMainController
{
    [self linkToController:@"ORPulser33220Controller"];
}

- (NSString*) helpURL
{
	return @"GPIB/Aglient_33220a.html";
}

- (void) dealloc
{
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [serialNumber release];
	[allWaveFormsInMemory release];
	[ipAddress release];
	[socket close];
    [socket setDelegate:nil];
	[socket release];
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
	if([self objectConnectedTo:ORPulserUSBInConnection] || [self objectConnectedTo:ORPulserUSBNextConnection] ||
	   [self objectConnectedTo:ORGpibConnection] || [self objectConnectedTo:ORGpibConnectionToNextDevice]){
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
	[[self objectConnectedTo:ORPulserUSBNextConnection] connectionChanged];
	[self setUpImage];
}


-(void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"Pulser33220Icon"];
	
    NSSize theIconSize = [aCachedImage size];
    NSPoint theOffset = NSZeroPoint;
    NSImage* netConnectIcon = nil;
    if(connectionProtocol == kHPPulserUseIP){
        netConnectIcon = [NSImage imageNamed:@"NetConnect"];
        theIconSize.width += 10;
    }
    
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    if(connectionProtocol == kHPPulserUseIP){
        [netConnectIcon drawAtPoint:NSZeroPoint fromRect:[netConnectIcon imageRect] operation:NSCompositeSourceOver fraction:1.0];
        theOffset.x += 10;
    }
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];	
    if(connectionProtocol == kHPPulserUseUSB && (!usbInterface || ![self getUSBController])){
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


- (id)  dialogLock
{
	return @"ORPulser33220Lock";
}

- (NSString*) title 
{
	switch (connectionProtocol){
		case kHPPulserUseGPIB:	return [NSString stringWithFormat:@"33220 Pulser (GPIB %d)",[self primaryAddress]];
		case kHPPulserUseUSB:	return [NSString stringWithFormat:@"33220 Pulser (Serial# %@)",[usbInterface serialNumber]];
		case kHPPulserUseIP:	return [NSString stringWithFormat:@"33220 Pulser (%@)",[self ipAddress]];
	}
	return [NSString stringWithFormat:@"33220 Pulser (%d)",[self tag]];
}

- (NSUInteger) vendorID
{
	return 0x0957;
}

- (NSUInteger) productID
{
	return 0x0407;
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORPulserUSBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

#pragma mark ***Accessors

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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33220ModelSerialNumberChanged object:self];
}

- (BOOL) canChangeConnectionProtocol
{
    return canChangeConnectionProtocol;
}

- (void) setCanChangeConnectionProtocol:(BOOL)aCanChangeConnectionProtocol
{
    
    canChangeConnectionProtocol = aCanChangeConnectionProtocol;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33220ModelCanChangeConnectionProtocolChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33220ModelIpConnectedChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33220ModelIpAddressChanged object:self];
}

- (int) connectionProtocol
{
    return connectionProtocol;
}

- (void) setConnectionProtocol:(int)aConnectionProtocol
{
	[[[self undoManager] prepareWithInvocationTarget:self] setConnectionProtocol:connectionProtocol];
	
	connectionProtocol = aConnectionProtocol;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33220ModelConnectionProtocolChanged object:self];
	[self setUpImage];
}

- (void) sendRemoteCommand
{
	[self writeToGPIBDevice:@"SYST:COMM:RLST REM"];
}

- (void) sendLocalCommand
{
	[self writeToGPIBDevice:@"SYST:COMM:RLST LOC"];
}

- (void) writeBurstRate:(float)value
{
    // We use period instead of rate!
    float period = 1.0/value;
    [self writeToGPIBDevice:[NSString stringWithFormat:@"BURS:INT:PER %f",period]];
    [self logSystemResponse];
    [self writeToGPIBDevice:@"BURS:MODE TRIG"];
    [self logSystemResponse];
    if([self verbose])NSLog(@"HP Pulser Burst Period set to %f\n",period);
}

- (void) writeBurstState:(BOOL)value
{
    if(value) [self writeToGPIBDevice:@"BURS:STAT ON"];
    else [self writeToGPIBDevice:@"BURS:STAT OFF"];
}

- (void) writeBurstCycles:(int)value
{
    [self writeToGPIBDevice:[NSString stringWithFormat:@"BURS:NCYC %d",value]];
    [self logSystemResponse];
    if([self verbose])NSLog(@"HP Pulser Burst Cycles set to %d\n",value);
}

- (void) writeBurstPhase:(int)value
{
    // The parent model only supports degrees, so this is coded as it is for now.
    [self writeToGPIBDevice:@"UNIT:ANGL DEG"];
    [self writeToGPIBDevice:[NSString stringWithFormat:@"BURS:PHAS %d",value]];
    [self logSystemResponse];
    if([self verbose])NSLog(@"HP Pulser Burst Phase set to %d\n",value);
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface
{
	
	if(connectionProtocol == kHPPulserUseUSB){
		
		[self enableEOT:YES];
		[usbInterface release];
		usbInterface = anInterface;
		[usbInterface retain];
		
		[usbInterface writeUSB488Command:@"SYST:COMM:RLST REM;*WAI" eom:YES];
		[usbInterface writeUSB488Command:@"OUTPUT 1;*WAI" eom:YES];
		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: ORPulser33220ModelUSBInterfaceChanged
		 object: self];
		
		[self setUpImage];
		
	}
}

- (void) interfaceAdded:(NSNotification*)aNote
{
	if(connectionProtocol == kHPPulserUseUSB){
		[[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
		[self checkNoUsbAlarm];			
	}
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
	if(connectionProtocol == kHPPulserUseUSB){
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
	if((connectionProtocol != kHPPulserUseUSB) || (usbInterface && [self getUSBController]) || !guardian){
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
	if(connectionProtocol == kHPPulserUseIP){
		if([self verbose])[self writeToGPIBDevice:@"SYST:ERR?"];
	}
	else [super logSystemResponse];
}


- (NSArray*) getLoadedWaveforms
{
	if(connectionProtocol == kHPPulserUseIP ){
		waitForGetWaveformsLoadedDone = YES;
		[self writeToGPIBDevice:@"Data:CAT?;*WAI;*OPC?"];
		return allWaveFormsInMemory;
	}
	else return [super getLoadedWaveforms];
}

- (void) emptyVolatileMemory
{
	if(connectionProtocol == kHPPulserUseIP){
		@try {
			NSEnumerator* e = [allWaveFormsInMemory objectEnumerator];
			NSString* aName;
			while(aName = [e nextObject]){
				if( ![self inBuiltInList:aName]){
					[self writeToGPIBDevice:[NSString stringWithFormat:@"DATA:DEL %@",aName]];
				}
			}
			
		}
		@catch(NSException* localException) {
		}
		
		
		waitForGetWaveformsLoadedDone = YES;
		[self writeToGPIBDevice:@"Data:CAT?;*WAI;*OPC?"];
	}
	else [super emptyVolatileMemory];
}


- (void) downloadWaveform
{
	if(connectionProtocol == kHPPulserUseIP) waitForAsyncDownloadDone = YES;
	else									 waitForAsyncDownloadDone = NO;
	[super downloadWaveform];
}

- (void) waveFormWasSent
{
	if(!waitForAsyncDownloadDone)[super waveFormWasSent];
	[self writeToGPIBDevice:@"Output 1;*WAI"];
	if(connectionProtocol == kHPPulserUseIP){
		[self writeToGPIBDevice:@"*OPC?"];
	}
}

- (void) asyncDownloadFinished
{
	waitForAsyncDownloadDone = NO;
	loading = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName: ORHPPulserWaveformLoadFinishedNotification object: self];
	waitForGetWaveformsLoadedDone = YES;
	[self writeToGPIBDevice:@"Data:CAT?;*WAI;*OPC?"];
}

- (void) connect
{
	switch(connectionProtocol){
		case kHPPulserUseGPIB: 
			[super connect];		
			break;
		case kHPPulserUseUSB: 
			[self connectUSB];
			break;
		case kHPPulserUseIP: 
			if(!ipConnected && !socket) [self connectIP]; 
			break;
	}	
}

- (BOOL) isConnected
{
	switch(connectionProtocol){
		case kHPPulserUseGPIB: 
			return [super isConnected];		
			break;
		case kHPPulserUseUSB: 
			if(!usbInterface)[self connectUSB];
			return (usbInterface && [self getUSBController]);	
			break;
		case kHPPulserUseIP: 
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
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:kHPPulserPort]];	
	}
}

- (unsigned int) maxNumberOfWaveformPoints
{
	return kMaxNumberOfPoints33220;
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
		[self enableEOT:YES];
        [self setIpConnected:[socket isConnected]];
		if(ipConnected){
			[self writeToGPIBDevice:@"SYST:COMM:RLST REM"];
			waitForGetWaveformsLoadedDone = YES;
			[self writeToGPIBDevice:@"Data:CAT?;*WAI;*OPC?"];
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
					[allWaveFormsInMemory release];
					allWaveFormsInMemory = [[theString componentsSeparatedByString:@","] retain];
				}
				else if(waitForAsyncDownloadDone){
					[self asyncDownloadFinished];
				}
			}
		}
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
    [self setSerialNumber:[decoder decodeObjectForKey:@"ORPulser33220ModelSerialNumber"]];
	[self setIpAddress:[decoder decodeObjectForKey:@"ORPulser33220ModelIpAddress"]];
    [self setConnectionProtocol:[decoder decodeIntForKey:@"ORPulser33220ModelConnectionProtocol"]];
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:serialNumber forKey:@"ORPulser33220ModelSerialNumber"];
    [encoder encodeObject:ipAddress forKey:@"ORPulser33220ModelIpAddress"];
    [encoder encodeInt:connectionProtocol forKey:@"ORPulser33220ModelConnectionProtocol"];
}


- (void) enableEOT: (BOOL) state
{
	if(connectionProtocol == kHPPulserUseGPIB ){
		[super enableEOT:state];
	}
	else {
		mEOT = state;
	}
}

#pragma mark ***Comm methods
- (long) readFromGPIBDevice: (char*) aData maxLength: (long) aMaxLength
{
	switch(connectionProtocol){
		case kHPPulserUseGPIB: return [super readFromGPIBDevice:aData maxLength:aMaxLength];
		case kHPPulserUseUSB:  
			if(usbInterface && [self getUSBController]){
				return [usbInterface readUSB488:aData length:aMaxLength];;
			}
			else {
				NSString *errorMsg = @"Must establish connection prior to issuing command\n";
				[ NSException raise: OExceptionGPIBConnectionError format: @"%@",errorMsg ];
				
			}
			break;
		case kHPPulserUseIP: 
			//nothing to do... all incoming data is initiated by us and we'll be notified 
			//when any data arrives in the  netsocket:dataAvailable: method
			break;
	}
	return 0;
}

- (void) writeToGPIBDevice: (NSString*) aCommand
{
	switch(connectionProtocol){
		case kHPPulserUseGPIB:  [super writeToGPIBDevice:aCommand]; break;
			
		case kHPPulserUseUSB:
			if(usbInterface && [self getUSBController]){
				if(mEOT)aCommand = [aCommand stringByAppendingString:@"\n"];
				[usbInterface writeUSB488Command:aCommand eom:mEOT];
			}
			else {
				NSString *errorMsg = @"Must establish connection prior to issuing command\n";
				[ NSException raise: OExceptionGPIBConnectionError format:@"%@", errorMsg ];
				
			}
			break;
			
		case kHPPulserUseIP: 
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
