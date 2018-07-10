/*
 File:		ORFireWireInterface.m
 
 Synopsis: 	ObjC class to represent an device on the FireWire bus. Corresponds
 to IOFireWireDeviceInterface.
 
 Note: converted to ObjC from the C++ version in Apples example code.
 */
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

#import "ORFireWireInterface.h"

#define kDeviceIID				(CFUUIDGetUUIDBytes(kIOFireWireDeviceInterfaceID_v6))

static void deviceInterestCallback( void * refcon, io_service_t service, natural_t messageType, void * messageArgument )
{
	[(ORFireWireInterface*)refcon deviceCallback: messageType argument:messageArgument];
}


NSString* ORFireWireInterfaceServiceAliveChanged = @"ORFireWireInterfaceServiceAliveChanged";
NSString* ORFireWireInterfaceIsOpenChanged = @"ORFireWireInterfaceIsOpenChanged";

@implementation ORFireWireInterface

- (id) initWithService:(io_object_t) aDevice
{
	self = [super init];
	IOReturn err = 0;
	SInt32	theScore;
	
	mIsochRunLoop = 0;
	fwLock = [[NSLock alloc] init];
	@try {
		
		io_name_t			className ;
		err = IOObjectGetClass( aDevice, className ) ;
		NSLog(@"creating service for <%p> %s\n",aDevice,className);
		
		// get IOCFPlugInInterface plug-in interface
		err = IOCreatePlugInInterfaceForService(aDevice, kIOFireWireLibTypeID, kIOCFPlugInInterfaceID, &mIOCFPlugInInterface, &theScore);
		if(err){
			[NSException raise:@"IOReturn" format:@"%s %u: IOCreatePlugInInterfaceForService failed for <%@>", __FILE__, __LINE__,NSStringFromClass([self class])];
		}
		// get device interface
		err = (**mIOCFPlugInInterface).QueryInterface(mIOCFPlugInInterface, kDeviceIID, (void**) &mDevice);
		
		if(err)[NSException raise:@"IOReturn" format:@"%s %u: QueryInterface <%@>", __FILE__, __LINE__,NSStringFromClass([self class])];
	}
	@catch(NSException* localException) {
		if(err) NSLogColor([NSColor redColor],@"Service NOT opened\n");
		NSLog(@"%@\n",localException);
		[localException raise];
	}
	
	return self;
}


- (void) dealloc
{ 
    [fireWireServiceAlarm clearAlarm];
    [fireWireServiceAlarm release];
	
	[self close];
	if(mNotificationPort){
		CFRunLoopSourceRef source =  IONotificationPortGetRunLoopSource( mNotificationPort );
		if(source)CFRunLoopSourceInvalidate( source ) ;
		//IONotificationPortDestroy(mNotificationPort);
		//CFRelease( source ) ;
	}
	if(mNotification)IOObjectRelease( mNotification ) ;
	
	if(mDevice)(**mDevice).Release(mDevice);
	if(mIOCFPlugInInterface) IODestroyPlugInInterface(mIOCFPlugInInterface);
	[fwLock release];
	[super dealloc];
}

#pragma mark ¥¥¥Accessors

- (BOOL) serviceAlive
{
    return serviceAlive;
}

- (void) setServiceAlive:(BOOL)aServiceAlive
{
	if(aServiceAlive != serviceAlive){
		serviceAlive = aServiceAlive;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORFireWireInterfaceServiceAliveChanged object:self];
	}
}

- (BOOL) isOpen
{
    return isOpen;
}

- (void) setIsOpen:(BOOL)aIsOpen
{
    isOpen = aIsOpen;
	[self setServiceAlive:aIsOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFireWireInterfaceIsOpenChanged object:self];
}


- (io_service_t) service															
{ 
	return (**mDevice).GetDevice(mDevice); 
}

// --- client methods
- (void) open 																
{ 
	if(mDevice && !isOpen) {
		IOReturn error = (**mDevice).Open(mDevice); 
		if(error==kIOReturnSuccess){
			[self registerInterest];
			[self setIsOpen:YES];
			[self setServiceAlive:YES];
		}
		else {
            NSLogError(@" ",@"FireWire",@"write error",nil);
			[NSException raise:@"ORFireWireInterface" format:@"Write Error"];
		}
	}
}

- (void) close																
{ 
	if(mDevice) {
		(**mDevice).Close(mDevice);  
		[self setIsOpen:NO];
		[self setServiceAlive:NO];
	}
}

- (void) registerInterest
{
	mach_port_t		masterPort = 0 ;
	IOReturn 		error = IOMasterPort(MACH_PORT_NULL, &masterPort) ;
	if ( !error ) {
		if(mNotificationPort){
			CFRelease(mNotificationPort);
			mNotificationPort = 0;
		}
		if (0 == (mNotificationPort = IONotificationPortCreate(masterPort))){
			error = kIOReturnError ;	// there may be a better error code we can return
		}
	}
	//
	// Get a run loop event source from the notification port
	// and add it to our (default) runloop
	//
	if (!error){		
		CFRunLoopSourceRef source =  IONotificationPortGetRunLoopSource( mNotificationPort );
		CFRunLoopAddSource( CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode );
		
		// the run loop has the source, so we release it.
		//CFRelease( source ) ;
		
		IOServiceAddInterestNotification( mNotificationPort, [self service], kIOGeneralInterest, &deviceInterestCallback, self, &mNotification ) ;
	}
}


- (void) deviceCallback:(natural_t) messageType argument:(void*)messageArgument
{
	switch(messageType) {
		case kIOMessageServiceIsRequestingClose:   
			NSLog(@"kIOMessageServiceIsRequestingClose\n");
			break;
		case kIOFWMessageServiceIsRequestingClose:	
			NSLog(@"kIOFWMessageServiceIsRequestingClose\n");	
			[self setServiceAlive:NO];
			
			if(!fireWireServiceAlarm){
				fireWireServiceAlarm = [[ORAlarm alloc] initWithName:@"No FireWire Service" severity:kHardwareAlarm];
				[fireWireServiceAlarm setSticky:YES];
				[fireWireServiceAlarm setHelpStringFromFile:@"NoFireWireServiceHelp"];
				
			} 
			if(![fireWireServiceAlarm isPosted]){
				[fireWireServiceAlarm setAcknowledged:NO];
				[fireWireServiceAlarm postAlarm];
			}
			break;
		case kIOMessageServiceIsTerminated:			
			[self setServiceAlive:NO];
			NSLog(@"kIOMessageServiceIsTerminated\n");			
			break;
		case kIOMessageServiceIsSuspended:	
			[self setServiceAlive:NO];
			NSLog(@"kIOMessageServiceIsSuspended\n");	
			break;
			
		case kIOMessageServiceIsResumed:			
			NSLog(@"kIOMessageServiceIsResumed\n");	
			[self setServiceAlive:YES];
			
			if(fireWireServiceAlarm){
				[fireWireServiceAlarm clearAlarm];
				[fireWireServiceAlarm release];
				fireWireServiceAlarm = nil;
			}
			break;
			
		case kIOMessageServiceIsAttemptingOpen:		NSLog(@"kIOMessageServiceIsAttemptingOpen\n");		break;
		case kIOMessageServiceWasClosed:			NSLog(@"kIOMessageServiceWasClosed\n");				break;
		case kIOMessageServiceBusyStateChange:		NSLog(@"kIOMessageServiceBusyStateChange\n");		break;
		case kIOMessageServicePropertyChange:		NSLog(@"kIOMessageServicePropertyChange\n");		break;
		case kIOMessageCanDevicePowerOff:			NSLog(@"kIOMessageCanDevicePowerOff\n");			break;
		case kIOMessageDeviceWillPowerOff:			NSLog(@"kIOMessageDeviceWillPowerOff\n");			break;
		case kIOMessageDeviceWillNotPowerOff:		NSLog(@"kIOMessageDeviceWillNotPowerOff\n");		break;
		case kIOMessageDeviceHasPoweredOn:			NSLog(@"kIOMessageDeviceHasPoweredOn\n");			break;
		case kIOMessageCanSystemPowerOff:			NSLog(@"kIOMessageCanSystemPowerOff\n");			break;
		case kIOMessageSystemWillPowerOff:			NSLog(@"kIOMessageSystemWillPowerOff\n");			break;
		case kIOMessageSystemWillNotPowerOff:		NSLog(@"kIOMessageSystemWillNotPowerOff\n");		break;
		case kIOMessageCanSystemSleep:				NSLog(@"kIOMessageCanSystemSleep\n");				break;
		case kIOMessageSystemWillSleep:				NSLog(@"kIOMessageSystemWillSleep\n");				break;
		case kIOMessageSystemHasPoweredOn:			NSLog(@"kIOMessageSystemHasPoweredOn\n");			break;
		case kIOMessageSystemWillPowerOn:			NSLog(@"kIOMessageSystemWillPowerOn\n");			break;
		case kIOMessageSystemWillRestart:			NSLog(@"kIOMessageSystemWillRestart\n");			break;
			
		case  kIOFireWireBusReset:					NSLog(@"kFWResponseBusResetError\n");				break;
		case  kIOConfigNoEntry:						NSLog(@"kIOConfigNoEntry\n");						break;
		case  kIOFireWirePending:					NSLog(@"kIOFireWirePending\n");						break;
		case  kIOFireWireLastDCLToken:				NSLog(@"(kIOFireWireLastDCLToken\n");				break;
		case  kIOFireWireConfigROMInvalid:			NSLog(@"kIOFireWireConfigROMInvalid\n");			break;
		case  kIOFireWireAlreadyRegistered:			NSLog(@"kIOFireWireAlreadyRegistered\n");			break;
		case  kIOFireWireMultipleTalkers:			NSLog(@"kIOFireWireMultipleTalkers\n");				break;
		case  kIOFireWireChannelActive:				NSLog(@"kIOFireWireChannelActive\n");				break;
		case  kIOFireWireNoListenerOrTalker:		NSLog(@"kIOFireWireNoListenerOrTalker\n");			break;
		case  kIOFireWireNoChannels:				NSLog(@"kIOFireWireNoChannels\n");					break;
		case  kIOFireWireChannelNotAvailable:		NSLog(@"kIOFireWireChannelNotAvailable\n");			break;
		case  kIOFireWireSeparateBus:				NSLog(@"kIOFireWireSeparateBus\n");					break;
		case  kIOFireWireBadSelfIDs:				NSLog(@"kIOFireWireBadSelfIDs\n");					break;
		case  kIOFireWireLowCableVoltage:			NSLog(@"kIOFireWireLowCableVoltage\n");				break;
		case  kIOFireWireInsufficientPower:			NSLog(@"kIOFireWireInsufficientPower\n");			break;
		case  kIOFireWireOutOfTLabels:				NSLog(@"kIOFireWireOutOfTLabels\n");				break;
		case  kIOFireWireBogusDCLProgram:			NSLog(@"kIOFireWireBogusDCLProgram\n");				break;
		case  kIOFireWireTalkingAndListening:		NSLog(@"kIOFireWireTalkingAndListening\n");			break;
			//case  kIOFireWireHardwareSlept:			NSLog(@"kIOFireWireHardwareSlept\n");				break;
			//case  kIOFireWireCompleting:				NSLog(@"kIOFireWireCompleting\n");					break;
		case  kIOFWMessagePowerStateChanged:		NSLog(@"kIOFWMessagePowerStateChanged\n");			break;
			//case  kIOFWMessageTopologyChanged:		NSLog(@"kIOFWMessageTopologyChanged\n");			break;
			
			
		default:
			//NSLog(@"FW Interface message: <%d>\n",messageType);
			break ;			
	}
}


- (void) unLockAndRaise
{
	[fwLock unlock];
	if(!mDevice)			[NSException raise:@"ORFireWireInterface" format:@"No Device"];
	else if(!serviceAlive)	[NSException raise:@"ORFireWireInterface" format:@"Check Power and Cables"];
	else					[NSException raise:@"ORFireWireInterface" format:@"Device Not Open"];
}

// bus transactions
- (void) write_raw:(unsigned long long)address value:(unsigned long *)theData size:(unsigned long)len
{ 
	FWAddress ioaddr;
	ioaddr.addressHi = address >> 32;
	ioaddr.addressLo = address & 0xffffffff;  // ak 16.10.07
	//NSLog(@"write_raw(addr=%llx, hi=%lx, lo=%lx\n", address, ioaddr.addressHi, ioaddr.addressLo);
	
    // Convert to net byte order
	// ak 16.10.07 
	int i;
    unsigned long netData[len];
    for (i=0; i<len/sizeof(unsigned long); i++)
		netData[i] = htonl(theData[i]);
	
	[fwLock lock];
	if(mDevice && serviceAlive && isOpen){
		IOReturn error = (**mDevice).Write(mDevice, (**mDevice).GetDevice(mDevice), &ioaddr, netData, &len, NO, 0);  
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"write error",nil);
			[fwLock unlock];
			[NSException raise:@"ORFireWireInterface" format:@"Write Error"];
		}
	}
	else [self unLockAndRaise];
	[fwLock unlock];
}

- (unsigned long) read_raw:(unsigned long long) address;
{ 
	unsigned long value = 0;
	FWAddress ioaddr; 
	ioaddr.addressHi = address >> 32;
	ioaddr.addressLo = address & 0xffffffff;  // ak 16.10.07
	//NSLog(@"read_raw(addr=%llx, hi=%lx, lo=%lx\n", address, ioaddr.addressHi, ioaddr.addressLo);
	
	[fwLock lock];	
	if(mDevice && serviceAlive && isOpen){
		unsigned long len = 4;
		IOReturn error = (**mDevice).Read(mDevice, (**mDevice).GetDevice(mDevice), &ioaddr, &value, &len, NO, 0);    
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"read error",nil);
			[fwLock unlock];
			[NSException raise:@"ORFireWireInterface" format:@"Read Error"];
		}
	}
	else [self unLockAndRaise];
	[fwLock unlock];
	
    // Convert network to host byte order
    value = ntohl(value); // ak 16.10.07
	
	return value;
}

- (void) write_raw:(unsigned long long)address value:(unsigned long)aValue
{ 
	FWAddress ioaddr;
	ioaddr.addressHi = address >> 32;
	ioaddr.addressLo = address & 0xffffffff;  // ak 16.10.07
	//NSLog(@"read_raw(addr=%llx, hi=%lx, lo=%lx\n", address, ioaddr.addressHi, ioaddr.addressLo);
	
    // Convert to net byte order
    unsigned long netValue;
    netValue = htonl(aValue); // ak 16.10.07
	
	[fwLock lock];
	if(mDevice && serviceAlive && isOpen){
		unsigned long len = 4;
		IOReturn error = (**mDevice).Write(mDevice, (**mDevice).GetDevice(mDevice), &ioaddr, &netValue, &len, NO, 0);  
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"write error",nil);
			[fwLock unlock];
			[NSException raise:@"ORFireWireInterface" format:@"Write Error"];
		}
	}
	else [self unLockAndRaise];
	[fwLock unlock];
}

- (void) read_raw:(unsigned long long) address data:(unsigned long*)theData size:(unsigned long)len;
{ 
	FWAddress ioaddr;
	ioaddr.addressHi = address >> 32;
	ioaddr.addressLo = address & 0xffffffff;  // ak 16.10.07
	//NSLog(@"read_raw(addr=%llx, hi=%lx, lo=%lx\n", address, ioaddr.addressHi, ioaddr.addressLo);
	
	[fwLock lock];
	if(mDevice && serviceAlive && isOpen){
		IOReturn error = (**mDevice).Read(mDevice, (**mDevice).GetDevice(mDevice), &ioaddr, theData, &len, NO, 0);    
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"read error",nil);
			[fwLock unlock];
			[NSException raise:@"ORFireWireInterface" format:@"Read Error"];
		}
	}
	else [self unLockAndRaise];
	[fwLock unlock];
	
    // Convert network to host byte order
	// ak 16.10.07 
	int i;
    for (i=0; i<len/sizeof(unsigned long); i++)
		theData[i] = ntohl(theData[i]);
	
	
}

- (void) compareSwap64:(const FWAddress*) addr
		 expectedValue:(unsigned long*)expectedVal
				newVal:(unsigned long*)newVal
				oldVal:(unsigned long*)oldVal
				  size:(IOByteCount)size
				   abs:(BOOL) abs
		   failOnReset:(BOOL)failOnReset
			generation:(unsigned long)generation								
{ 
	[fwLock lock];
	if(mDevice && serviceAlive && isOpen){
		IOReturn error = (**mDevice).CompareSwap64(mDevice, abs ? 0 : (**mDevice).GetDevice(mDevice), addr, expectedVal, newVal, oldVal, size, failOnReset, generation);     
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"compareSwap64 error",nil);
			[fwLock unlock];
			[NSException raise:@"ORFireWireInterface" format:@"CompareSwap64 Error"];
		}
	}
	else [self unLockAndRaise];
	[fwLock unlock];
}

// bus misc.
- (void) busReset															
{  
	[fwLock lock];
	if(mDevice && serviceAlive && isOpen){
		IOReturn error = (**mDevice).BusReset(mDevice);     
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"bus reset error",nil);
			[fwLock unlock];
			[NSException raise:@"ORFireWireInterface" format:@"Bus Reset Error"];
		}
	}
	else [self unLockAndRaise];
	[fwLock unlock];
}

// topology
- (void) getBusGeneration:(unsigned long*) generation						
{ 
	[fwLock lock];
	if(mDevice && serviceAlive && isOpen){
		IOReturn error = (**mDevice).GetBusGeneration(mDevice, generation);     
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"getBusGeneration error",nil);
			[fwLock unlock];
			[NSException raise:@"ORFireWireInterface" format:@"GetBusGeneration Error"];
		}
	}
	else [self unLockAndRaise];
	[fwLock unlock];
}

- (void) getLocalNodeIDWithGeneration:(unsigned long) checkGeneration
						  localNodeID:(unsigned short*) localNodeID								
{ 
	[fwLock lock];
	if(mDevice && serviceAlive && isOpen){
		IOReturn error = (**mDevice).GetLocalNodeIDWithGeneration(mDevice, checkGeneration, localNodeID);     
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"getLocalNodeIDWithGeneration error",nil);
			[fwLock unlock];
			[NSException raise:@"ORFireWireInterface" format:@"GetLocalNodeIDWithGeneration Error"];
		}
	}
	else [self unLockAndRaise];
	[fwLock unlock];
}

- (void) getRemoteNodeID:(unsigned long) checkGeneration
			remoteNodeID:(unsigned short*) remoteNodeID								
{ 
	[fwLock lock];
	if(mDevice && serviceAlive && isOpen){
		IOReturn error = (**mDevice).GetRemoteNodeID(mDevice, checkGeneration, remoteNodeID);     
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"getRemoteNodeID error",nil);
			[fwLock unlock];
			[NSException raise:@"ORFireWireInterface" format:@"GetRemoteNodeID Error"];
		}
	}
	[fwLock unlock];
}

- (void) getSpeedToNode:(unsigned long) checkGeneration
				  speed:(IOFWSpeed*) speed	
{ 
	[fwLock lock];
	if(mDevice && serviceAlive && isOpen){
		IOReturn error = (**mDevice).GetSpeedToNode(mDevice, checkGeneration, speed);     
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"getSpeedToNode error",nil);
			[fwLock unlock];
			[NSException raise:@"ORFireWireInterface" format:@"GetSpeedToNode Error"];
		}
	}
	else [self unLockAndRaise];
	[fwLock unlock];
}

- (void) getSpeedBetweenNodes:(unsigned long) checkGeneration
					srcNodeId:(unsigned long) srcNodeID
				   destNodeID:(unsigned short) destNodeID
						speed:(IOFWSpeed*) speed					
{
	[fwLock lock];
	if(mDevice && serviceAlive && isOpen){
		IOReturn error = (**mDevice).GetSpeedBetweenNodes(mDevice, checkGeneration, srcNodeID, destNodeID, speed);     
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"getSpeedBetweenNodes error",nil);
			[fwLock unlock];
			[NSException raise:@"ORFireWireInterface" format:@"GetSpeedBetweenNodes Error"];
		}
	}
	else [self unLockAndRaise];
	[fwLock unlock];
}

-(IOFireWireLibDeviceRef) interface													
{ 
	return mDevice;     
}

- (void) printConfigROM
{
	FWAddress				currentAddress ;
	unsigned long			readValue ;
	unsigned long			size ;
	
	NSLog(@"Config ROM for device = %x, service = %x\n", mDevice, [self service]);
	
	// initialize the address to read from to start of  the Config ROM
	currentAddress.addressHi = 0xffff;
	currentAddress.addressLo = 0xf0000400;
	//currentAddress.nodeID	 = 0;
	size					 = 4 ;
	
	// Read quadlet at current address
	@try {
		while(currentAddress.addressLo < 0xf00004BC){
			IOReturn error = (**mDevice).ReadQuadlet(mDevice, (**mDevice).GetDevice(mDevice), &currentAddress, &readValue, NO, 0);
	        readValue = ntohl(readValue);
			if(error != kIOReturnSuccess)break;
			// output to terminal:
			if (! (currentAddress.addressLo & 0xF)){
				if (currentAddress.addressLo & 0x10) NSLog(@"\t\t\t\t\t\t%08lX\n", readValue) ;
				else								 NSLog(@"\t\t%04X.%08lX:\t%08lX\n", currentAddress.addressHi, currentAddress.addressLo, readValue) ;
			}
			else NSLog(@"\t\t\t\t\t\t%08lX\n", readValue) ;
			
			currentAddress.addressLo += size; // move to next address
		}
	}
	@catch(NSException* localException) {
	}
	
	
	long long guid = 0;
	currentAddress.addressHi = 0xffff;
	currentAddress.addressLo = 0xf000040c;
	@try {
		unsigned long len = 4;
		IOReturn error = (**mDevice).Read(mDevice, (**mDevice).GetDevice(mDevice), &currentAddress, &readValue, &len, NO, 0);    
		readValue = ntohl(readValue);
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"read error",nil);
			[NSException raise:@"ORFireWireInterface" format:@"Read Error"];
		}
		currentAddress.addressLo = 0xf0000410;
		guid |= (long long) readValue<<32;
		error = (**mDevice).Read(mDevice, (**mDevice).GetDevice(mDevice), &currentAddress, &readValue, &len, NO, 0);    
		readValue = ntohl(readValue);
		if(error!=kIOReturnSuccess){
            NSLogError(@" ",@"FireWire",@"read error",nil);
			[NSException raise:@"ORFireWireInterface" format:@"Read Error"];
		}
		guid |= readValue;
		NSLog(@"GUID: 0x%llx\n",guid);
	}
	@catch(NSException* localException) {
	}
	
}	


#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super init];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
}

@end
