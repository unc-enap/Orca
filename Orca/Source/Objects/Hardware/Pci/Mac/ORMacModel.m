//
//  ORMacModel.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORMacModel.h"
#import "ORVmeAdapter.h"
#import "ORSerialPortList.h"
#import "ORSerialPortAdditions.h"

#import "ORFireWireInterface.h"
#import "ORCrate.h"
#import "ORFireWireBus.h"
#import "ORUSB.h"

NSString* ORMacModelEolTypeChanged       = @"ORMacModelEolTypeChanged";
NSString* ORMacModelSerialPortsChanged   = @"ORMacModelSerialPortsChanged";
NSString* ORMacModelUSBChainVerified     = @"ORMacModelUSBChainVerified";

static NSString *ORMacFireWireConnection = @"ORMacFireWireConnection";
static NSString *ORMacUSBConnection		 = @"ORMacUSBConnection";


void registryChanged(
					 id	sender,
					 io_service_t			service,
					 natural_t				messageType,
					 void *					messageArgument )
{
	// only update when root goes not busy
	//if(messageArgument == 0)[(NSNotificationCenter*)[ NSNotificationCenter defaultCenter ] postNotificationName:@"test" object:sender ];
}

@implementation ORMacModel

#pragma mark ¥¥¥initialization
- (id) init
{
	self = [super init];
	usb = [ORUSB sharedUSB];
	[self registerNotifications];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[fwBus release];
    [lastStringReceived release];
    [super dealloc];
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
	if(aGuardian){
		[usb searchForDevices];
		[self registerNotifications];
	}
	else {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[usb removeAllObjects];
	}
}

- (void) registerNotifications
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter  removeObserver:self];
	
	[notifyCenter  addObserver : self
                      selector : @selector(objectsAdded:)
                          name : ORGroupObjectsAdded
                        object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(objectsRemoved:)
                         name : ORGroupObjectsRemoved
                       object : nil];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		id anObj = [[[self connectors] objectForKey:ORMacFireWireConnection] connectedObject];
		[anObj setCrateNumber:0];
	}
	@catch(NSException* localException) {
	}
	
}

- (int) crateNumber
{
	return 0;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Mac"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORMacController"];
}

- (NSString*) helpURL
{
	return @"Mac_Pci/Mac.html";
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"%@ %d",[self className],[self tag]];
}

-(void)makeConnectors
{
	//we  have three permanent connectors. The rest we manage for the pci objects.
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize - 2, 2*kConnectorSize+2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORMacFireWireConnection];
    [aConnector setOffColor:[NSColor magentaColor]];
    [aConnector setConnectorType:'FWrO'];
	[ aConnector addRestrictedConnectionType: 'FWrI' ]; //can only connect to FireWire Inputs
    [aConnector release];
	
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize - 2, kConnectorSize+1) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORMacUSBConnection];
    [aConnector setOffColor:[NSColor yellowColor]];
    [aConnector setConnectorType:'USBO'];
	[ aConnector addRestrictedConnectionType: 'USBI' ]; //can only connect to USB Inputs
    [aConnector release];
}

- (void) positionConnector:(ORConnector*)aConnector forCard:(id)aCard
{
	//position our managed connectors.
	NSRect aFrame = [aConnector localFrame];
	aFrame.origin = NSMakePoint([self frame].size.width - kConnectorSize - 2 , 3*(kConnectorSize+2) + [aCard slot]*(kConnectorSize+2));
	[aConnector setLocalFrame:aFrame];
}

- (BOOL) solitaryObject
{
    return YES;
}


#pragma mark ¥¥¥Accessors
- (void) turnOnAllOutputBuffer:(BOOL)state
{
    useAllOutputBuffer = state;
    [self clearAllOutput];
}

- (NSString*) lastStringReceived
{
    return lastStringReceived;
}

- (void) setLastStringReceived:(NSString*)aLastStringReceived
{
    [lastStringReceived autorelease];
    lastStringReceived = [aLastStringReceived copy];
    @synchronized (self) {
        if(useAllOutputBuffer){
            if(!allOutput) allOutput = [[NSMutableString string]retain];
            [allOutput appendString:aLastStringReceived];
        }
    }
}

- (NSString*) allOutput
{
    NSString* s;
    @synchronized (self) {
        s = [allOutput stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    }
    return s;
}

- (void) clearAllOutput
{
    @synchronized (self) {
        [allOutput release];
        allOutput = nil;
    }
}

- (BOOL) allOutputHasSubstring:(NSString*)s
{
    return [allOutput rangeOfString:s].location != NSNotFound;
}

- (NSString*) commandByAppendingEOL:(NSString*) aCmd
{
	NSString* theCmd  = [aCmd removeNLandCRs];
	switch(eolType){
		case 1: theCmd = [theCmd stringByAppendingString:@"\r"]; break;
		case 2: theCmd = [theCmd stringByAppendingString:@"\n"]; break;
		case 3: theCmd = [theCmd stringByAppendingString:@"\r\n"]; break;
	}
	return theCmd;
}

- (int) eolType
{
    return eolType;
}

- (void) setEolType:(int)aEolType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEolType:eolType];
    
    eolType = aEolType;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMacModelEolTypeChanged object:self];
}

#pragma mark ¥¥¥Serial Ports

- (void) sendOnPort:(int)index anArray:(NSArray*)someData
{
	ORSerialPort* aPort = [[ORSerialPortList sharedSerialPortList] objectAtIndex:index];
	[aPort setDelegate:self];
	if(aPort){
		NSMutableData* theData = [NSMutableData data];
		int i;
		for(i=0;i<[someData count];i++){
			unsigned char aByte = [[someData objectAtIndex:i] unsignedCharValue];
			[theData appendBytes:&aByte length:1];
		}
		[aPort writeDataInBackground:theData];
	}
}

- (void) serialPortWriteProgress:(NSDictionary *)dataDictionary
{
}


#pragma mark ¥¥¥FireWire
- (id) getFireWireInterface:(NSUInteger) aVenderID
{
	if(!fwBus){
		fwBus = [[ORFireWireBus alloc] init];
	}
	return [fwBus getFireWireInterface:aVenderID];
}

#pragma mark ¥¥¥USB

- (id) getUSBController
{
	return usb;
}

- (void) objectsAdded:(NSNotification*)aNote
{
	[usb objectsAdded:[[aNote userInfo] objectForKey:ORGroupObjectList]];
}

- (void) objectsRemoved:(NSNotification*)aNote
{
	[usb objectsRemoved:[[aNote userInfo] objectForKey:ORGroupObjectList]];
}

- (NSUInteger) usbDeviceCount
{
	return [usb deviceCount];
}

- (id) usbDeviceAtIndex:(NSUInteger)index;
{
	return [usb deviceAtIndex:index];
}


#pragma mark ¥¥¥IP
- (NSString*) ipAddress:(int)desiredNetwork
{
	//desiredNetwork == 0 for main network
	//desiredNetwork == 1 for first found private network
	//desiredNetwork == 2 for next private network,
	//...
	
	NSString* theResult = @"";
	NSArray* names =  [[NSHost currentHost] addresses];
	NSEnumerator* e = [names objectEnumerator];
	id aName;
	int index = 0;
	while(aName = [e nextObject]){
		if([aName rangeOfString:@"::"].location == NSNotFound){
			if(desiredNetwork == 0 && [aName rangeOfString:@".0.0."].location == NSNotFound){
				theResult = aName;
				break;
			}
			else if(desiredNetwork == index){
				theResult =  aName;
				break;
			}
			index++;
		}
	}
	return theResult;
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];

    [[self undoManager] disableUndoRegistration];
    [self setEolType:[decoder decodeIntForKey:@"ORMacModelEolType"]];
    [[self undoManager] enableUndoRegistration];
	
	usb = [ORUSB sharedUSB];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt:eolType forKey:@"ORMacModelEolType"];
    [super encodeWithCoder:encoder];	
}

#pragma mark ¥¥¥OROrderedObjHolding Protocol
- (int) maxNumberOfObjects	{ return 4; }
- (int) objWidth			{ return 20; }
- (int) groupSeparation		{ return 0; }
- (NSString*) nameForSlot:(int)aSlot	{ return [NSString stringWithFormat:@"PCI Slot %d",aSlot]; }

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj { return NO;}

- (NSRange) legalSlotsForObj:(id)anObj
{
	return NSMakeRange(0,[self maxNumberOfObjects]);
}

- (int) slotAtPoint:(NSPoint)aPoint 
{
	return floor(((int)aPoint.y)/[self objWidth]);
}

- (NSPoint) pointForSlot:(int)aSlot 
{
	return NSMakePoint(0,aSlot*[self objWidth]);
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
	[anObj setSlot: aSlot];
	[anObj moveTo:[self pointForSlot:aSlot]];
}
- (int) slotForObj:(id)anObj
{
	return [anObj slot];
}

- (int) numberSlotsNeededFor:(id)anObj
{
	return [anObj numberSlotsUsed];
}
@end

