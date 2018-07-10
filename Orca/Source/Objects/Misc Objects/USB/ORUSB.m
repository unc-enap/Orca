 //
//  ORUSB.m
//  Orca
//
//  Created by Mark Howe on 9/7/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORUSB.h"
#import "ORUSBInterface.h"
#import "SupportedUSBDevices.h"
#import "SynthesizeSingleton.h"
#import "ORSerialPortList.h"

NSString* ORUSBDevicesAdded		= @"ORUSBDevicesAdded";
NSString* ORUSBDevicesRemoved	= @"ORUSBDevicesRemoved";
NSString* ORUSBInterfaceRemoved	= @"ORUSBInterfaceRemoved";
NSString* ORUSBInterfaceAdded	= @"ORUSBInterfaceAdded";

static void _deviceAdded( void * refcon, io_service_t service)
{
	[(ORUSB*)refcon  deviceAdded:service];
}

static void DeviceNotification(void* refCon, io_service_t service, natural_t messageType, void* messageArgument)
{
	[[((ORUSBInterface*)refCon) callBackObject]  deviceNotification:refCon service:service messageType:messageType messageArgument:messageArgument];
}

@implementation ORUSB

#pragma mark ¥¥¥initialization

SYNTHESIZE_SINGLETON_FOR_ORCLASS(USB);

- (id) init
{
	self = [super init];	
	return self;
}

- (void) dealloc
{
	NSEnumerator* e = [interfaces objectEnumerator];
	while([e nextObject]){
		[[NSNotificationCenter defaultCenter] postNotificationName:ORUSBInterfaceRemoved object:self userInfo:nil];
	}
	
	e = [devices objectEnumerator];
	id device;
	while(device = [e nextObject]){
		[[NSNotificationCenter defaultCenter] removeObserver:device];
	}
	IONotificationPortDestroy(_notifyPort);
	[devices release];
	[interfaces release];
	if(_deviceAddedIter)IOObjectRelease(_deviceAddedIter);
	if(_deviceRemovedIter)IOObjectRelease(_deviceRemovedIter);
	[super dealloc];
}


- (void) awakeAfterDocumentLoaded
{	
	@try {
		[self searchForDevices];
	}
	@catch(NSException* localException) {
	}
}

- (void) searchForDevices
{
	NSArray* allDevices = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsConformingTo:@protocol(USBDevice)];
	devices = [NSMutableArray arrayWithArray:allDevices];
	[devices retain];
	[devices makeObjectsPerformSelector:@selector(registerWithUSB:) withObject:self];
	[self startMatching];
}

- (void) registerForUSBNotifications:(id)anObj
{
	if([devices containsObject: anObj]){
		[[NSNotificationCenter defaultCenter] removeObserver:anObj name:ORUSBInterfaceAdded object:self];
		[[NSNotificationCenter defaultCenter] removeObserver:anObj name:ORUSBInterfaceRemoved object:self];
		[[NSNotificationCenter defaultCenter] addObserver:anObj selector:@selector(interfaceAdded:)   name:ORUSBInterfaceAdded object:self];
		[[NSNotificationCenter defaultCenter] addObserver:anObj selector:@selector(interfaceRemoved:) name:ORUSBInterfaceRemoved object:self];
	}
}

- (void) removeAllObjects
{
	[self objectsRemoved:[NSArray arrayWithArray:devices]]; 
}

- (void) objectsAdded:(NSArray*)newObjects
{
	//first register the objects as needed
	BOOL anythingAdded = NO;
	NSEnumerator* e = [newObjects objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		if([obj conformsToProtocol:@protocol(USBDevice)]){
			if(![devices containsObject:obj]){
				[devices addObject:obj];
				[obj registerWithUSB:self]; 
				anythingAdded = YES;
			}
		}
	}
	
	if(anythingAdded){
		//tell the world
		[[NSNotificationCenter defaultCenter] postNotificationName:ORUSBDevicesAdded object:self userInfo:nil];
	}
}

- (void) objectsRemoved:(NSArray*)deletedObjects
{
	//first remove notifications for the delectedObjects
	NSEnumerator* e = [deletedObjects objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		[[NSNotificationCenter defaultCenter] removeObserver:obj];
	}
	
	//release the interface claims (if any) held by those objects
	e = [interfaces objectEnumerator];
	id anInterface;
	while(anInterface = [e nextObject]){
		if([deletedObjects containsObject:[anInterface registeredObject]]){
			[anInterface setRegisteredObject:nil];
		}
	}
	//clean up the devices array.
	[devices removeObjectsInArray:deletedObjects];
	//tell the world
	[[NSNotificationCenter defaultCenter] postNotificationName:ORUSBDevicesRemoved object:self userInfo:nil];
}

- (void) claimInterfaceWithSerialNumber:(NSString*)serialNumber for:(id)obj
{
    NSArray* someInterfaces = nil;
    if([obj respondsToSelector:@selector(vendorIDs)] && [obj respondsToSelector:@selector(productIDs)]){
        someInterfaces = [self interfacesForVenders:[obj vendorIDs] products:[obj productIDs]];
    }
    else if([obj respondsToSelector:@selector(vendorID)] && [obj respondsToSelector:@selector(productID)]){
        someInterfaces = [self interfacesForVender:[obj vendorID] product:[obj productID]];
    }
	NSEnumerator* e = [someInterfaces objectEnumerator];
	id anInterface;
	while(anInterface = [e nextObject]){
		if([[anInterface serialNumber] isEqualToString: serialNumber]){
			id oldObj = [anInterface registeredObject];
			if(oldObj!=obj){
				[oldObj setUsbInterface:nil];
				[anInterface setRegisteredObject:obj];
				[obj setUsbInterface:anInterface];
			}
		}
	}
}

- (void) claimInterfaceWithVendor:(unsigned long)aVendorID product:(NSUInteger) aProductID for:(id)obj
{
	//just grab the first one....someday this will probably have to be fixed
    NSArray* someInterfaces;
    if([obj respondsToSelector:@selector(vendorIDs)] && [obj respondsToSelector:@selector(productIDs)]){
        someInterfaces = [self interfacesForVenders:[obj vendorIDs] products:[obj productIDs]];
    }
    else someInterfaces = [self interfacesForVender:[obj vendorID] product:[obj productID]];
	id anInterface = [someInterfaces objectAtIndex:0];
	id oldObj = [anInterface registeredObject];
	[oldObj setUsbInterface:nil];
	[anInterface setRegisteredObject:obj];
	[obj setUsbInterface:anInterface];
}


- (void) releaseInterfaceFor:(id)obj
{
    NSArray* someInterfaces;
    if([obj respondsToSelector:@selector(vendorIDs)] && [obj respondsToSelector:@selector(productIDs)]){
        someInterfaces = [self interfacesForVenders:[obj vendorIDs] products:[obj productIDs]];
    }
    else someInterfaces = [self interfacesForVender:[obj vendorID] product:[obj productID]];
	NSEnumerator* e = [someInterfaces objectEnumerator];
	id anInterface;
	while(anInterface = [e nextObject]){
		if([anInterface registeredObject] == obj){
			[anInterface setRegisteredObject:nil];
			[obj setUsbInterface:nil];
			break;
		}
	}
}


#pragma mark ¥¥¥accessors
- (NSUInteger) deviceCount
{
	return [devices count];
}

- (NSUInteger) interfaceCount
{
	return [interfaces count];
}

- (NSArray*) interfaces
{
	return interfaces;
}
- (id) deviceAtIndex:(NSUInteger)index
{
	return [devices objectAtIndex:index];
}

- (ORUSBInterface*) getUSBInterface:(unsigned long)aVendorID productID:(NSUInteger) aProductID
{
	id intf;
	NSEnumerator* e = [interfaces objectEnumerator];
	while(intf = [e nextObject]){
		if([intf vendor] == aVendorID && [intf product] == aProductID){
			return intf;
		}
	}
	return nil;
}

#pragma mark ¥¥¥HW access
- (void) startMatching
{
	if(matching)return;
	matching = YES;
	mach_port_t                 masterPort;
	CFMutableDictionaryRef      matchingDict;
	kern_return_t               kr;
	
	if (_runLoopSource) return;
	
	// first create a master_port for my task
	kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
	if (kr || !masterPort) {
		NSLog(@"ERR: Couldn't create a master IOKit Port(%08x)\n", kr);
		return;
	}
	
	// Set up the matching criteria for the devices we're interested in
	matchingDict = IOServiceMatching(kIOUSBDeviceClassName);    // Interested in instances of class IOUSBDevice and its subclasses
	if (!matchingDict) {
		NSLog(@"Can't create a USB matching dictionary\n");
		//mach_port_deallocate(mach_task_self(), masterPort);
		return;
	}
	
	// Create a notification port and add its run loop event source to our run loop
	// This is how async notifications get set up.
	_notifyPort = IONotificationPortCreate(masterPort);
	_runLoopSource = IONotificationPortGetRunLoopSource(_notifyPort);
	
	CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopDefaultMode);
	
	// Retain additional references because we use this same dictionary with two calls to
	// IOServiceAddMatchingNotification, each of which consumes one reference.
	//matchingDict = (CFMutableDictionaryRef) CFRetain(matchingDict);
   	
	// Now set up two more notifications, one to be called when a device is first matched by I/O Kit, and the other to be
	// called when the device is terminated.
	IOServiceAddMatchingNotification(  _notifyPort,
										  kIOFirstMatchNotification,
										  matchingDict,
										  _deviceAdded,
										  self,
										  &_deviceAddedIter);
	
	[self deviceAdded:_deviceAddedIter]; // Iterate once to get already-present devices and arm the notification
	
	// Now done with the master_port
	mach_port_deallocate(mach_task_self(), masterPort);
	masterPort = 0;
}

- (void) deviceAdded:(io_iterator_t) iterator
{
    kern_return_t	kr;
    io_service_t	usbDevice;
    HRESULT			res;
	UInt16			vendor;
	UInt16			product;
	UInt16			release;
	UInt32			locationID;
	
    while ((usbDevice = IOIteratorNext(iterator))){
		IOCFPlugInInterface**	    plugInInterface=NULL;
		io_name_t				    deviceName;
		IOUSBDeviceInterface182**	deviceInterface;
		ORUSBInterface*			    usbCallbackData = 0;
		
		@try {
			
			// Get the USB device's name.
			kr = IORegistryEntryGetName(usbDevice, deviceName);
			if (KERN_SUCCESS != kr){
				[NSException raise: @"USB Exception" format:@"Failed to find device in IORegistry"];
			}
            
            NSString* deviceNameAsString = [NSString stringWithCString:deviceName encoding:NSASCIIStringEncoding];
            if([deviceNameAsString rangeOfString:@"Apple"].location           != NSNotFound) continue;
            if([deviceNameAsString rangeOfString:@"IOUSBHostDevice"].location != NSNotFound) continue;
            if([deviceNameAsString rangeOfString:@"Hub"].location             != NSNotFound) continue;
            if([deviceNameAsString rangeOfString:@"Rugged"].location          != NSNotFound) continue;
            if([deviceNameAsString rangeOfString:@"Display"].location         != NSNotFound) continue;
            if([deviceNameAsString rangeOfString:@"Host"].location         != NSNotFound) continue;

			// Add some app-specific information about this device.
			// Create a buffer to hold the data.
			usbCallbackData = [[ORUSBInterface alloc] init];
			
			// Now, get the locationID of this device. In order to do this, we need to create an IOUSBDeviceInterface182
			// for our device. This will create the necessary connections between our userland application and the 
			// kernel object for the USB Device.
			SInt32 score;
			kr = IOCreatePlugInInterfaceForService(usbDevice, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
												   &plugInInterface, &score);
			
			if ((kIOReturnSuccess != kr) || !plugInInterface){
				[NSException raise: @"USB Exception" format:@"Unable to create USB plugin"];
			}
			
			// Use the plugin interface to retrieve the device interface.
			res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID182),
													 (LPVOID) &deviceInterface);
			IODestroyPlugInInterface(plugInInterface);			// done with this
			
			if (res || !deviceInterface){
				[NSException raise: @"USB Exception" format:@"Unable to create USB device interface"];
			}
			
			// Now that we have the IOUSBDeviceInterface182, we can call the routines in IOUSBLib.h.
			// In this case, fetch the locationID. The locationID uniquely identifies the device
			// and will remain the same, even across reboots, so long as the bus topology doesn't change.
			
			kr = (*deviceInterface)->GetLocationID(deviceInterface, &locationID);
			if (KERN_SUCCESS != kr) {
				[NSException raise: @"USB Exception" format:@"Unable to get USB device location"];
			}
			
			
			kr = (*deviceInterface)->GetDeviceVendor(deviceInterface, &vendor);
			kr = (*deviceInterface)->GetDeviceProduct(deviceInterface, &product);
			kr = (*deviceInterface)->GetDeviceReleaseNumber(deviceInterface, &release);
			
			BOOL supported = NO;
			int i;
			for(i=0;i<kNumberSupportedDevices;i++){
				if(	vendor  == supportedUSBDevice[i].vendorID &&
				   product == supportedUSBDevice[i].productID   ){
					supported = YES;
					break;
				}
			}
			
			
			NSLog(@"USB: %@ added\n",deviceNameAsString);
			// Save the device's name to our private data.
			[ usbCallbackData setDeviceName:deviceNameAsString];
						
			UInt8 snsi;
			kr = (*deviceInterface)->USBGetSerialNumberStringIndex(deviceInterface, &snsi);
			char serialString[128];
			if(snsi){
				IOUSBDevRequest   req;
				req.bmRequestType = USBmakebmRequestType(kUSBIn, kUSBStandard, kUSBDevice);
				req.bRequest = kUSBRqGetDescriptor;  // See USB Spec, 9.4.3
				req.wValue = (3 << 8)|snsi;  // Which descriptor (STRING == DescriptorType 3)
				req.wIndex = 0x0409; // LangID == English?
				req.wLength = 128; // 32bit int
				req.pData = serialString;
				
				kr = (*deviceInterface)->DeviceRequest(deviceInterface, &req);
				if (kIOReturnSuccess == kr){
					NSString* s = [NSString stringWithUSBDesc:serialString];
					[usbCallbackData setSerialNumber:s];
					// mybuf now contains the string descriptor
				}
			}
			else {
				//NSString* s = [NSString stringWithFormat:@"0x%8x", locationID];
				[usbCallbackData setSerialNumber:@"0"];
				/*
				UInt8 psi;
				kr = (*deviceInterface)->USBGetProductStringIndex(deviceInterface, &psi);
				if(psi){
					IOUSBDevRequest   req;
					req.bmRequestType = USBmakebmRequestType(kUSBIn, kUSBStandard, kUSBDevice);
					req.bRequest = kUSBRqGetDescriptor;  // See USB Spec, 9.4.3
					req.wValue = (3 << 8)|psi;  // Which descriptor (STRING == DescriptorType 3)
					req.wIndex = 0x0409; // LangID == English?
					req.wLength = 128; // 32bit int
					req.pData = serialString;
					
					kr = (*deviceInterface)->DeviceRequest(deviceInterface, &req);
					if (kIOReturnSuccess == kr){
						NSString* s = [NSString stringWithUSBDesc:serialString];
						[usbCallbackData setSerialNumber:s];
						// mybuf now contains the string descriptor
					}
				}
				 */
			}
			
			//load up the private data that will be passed to the feneral interest notification
            if(supported){
                [usbCallbackData setCallBackObject:self];
                [usbCallbackData setLocationID:locationID];
                [usbCallbackData setVendor:vendor];
                [usbCallbackData setProduct:product];
                
                // need to open the device in order to change its state
                kr = (*deviceInterface)->USBDeviceOpen(deviceInterface);
                if (KERN_SUCCESS != kr){
                    [NSException raise: @"USB Exception" format:@"Unable to open USB device"];
                }
                kr = [self _configureAnchorDevice:deviceInterface];
                if (kIOReturnSuccess != kr){
                    printf("unable to configure device: %08x\n", kr);
                    (void) (*deviceInterface)->USBDeviceClose(deviceInterface);
                    [NSException raise: @"USB Exception" format:@"Unable to open configure device"];
                }
                
                (void) (*deviceInterface)->USBDeviceClose(deviceInterface);
                
                
                // Register for an interest notification of this device being removed. Use a reference to our
                // private data as the refCon which will be passed to the notification callback.
                io_object_t aNotification;
                kr = IOServiceAddInterestNotification( _notifyPort,						// notifyPort
                                                      usbDevice,						// service
                                                      kIOGeneralInterest,				// interestType
                                                      DeviceNotification,				// callback
                                                      usbCallbackData,					// refCon
                                                      &aNotification  // notification
                                                      );
                [usbCallbackData setNotification:aNotification];
                
                if (KERN_SUCCESS != kr)[NSException raise: @"USB Exception" format:@"Unable to add USB interest notification"];
                
                [self _findInterfaces:deviceInterface  userInfo:usbCallbackData supported:supported];
            }
            else { //!supported
                [[ORSerialPortList sharedSerialPortList] updatePortList];
            }

			// Done with this USB device; release the reference added by IOIteratorNext
			IOObjectRelease(usbDevice);
 		}
		@catch(NSException* localException) {
			if(plugInInterface)	(*plugInInterface)->Release(plugInInterface);
			if(usbDevice)		IOObjectRelease(usbDevice);
		}
		
		[usbCallbackData release];

    }

}

- (void) listSupportedDevices
{
	NSFont* aFont = [NSFont fontWithName:@"Monaco" size:11];
	NSLogFont(aFont,@"--------------------------------------------\n");
	NSLogFont(aFont,@"         Supported USB devices\n");
	NSLogFont(aFont,@"--------------------------------------------\n");
	NSLogFont(aFont,@" VendorID  |  ProductID |    Object\n");
	NSLogFont(aFont,@"--------------------------------------------\n");
	int i;
	for(i=0;i<kNumberSupportedDevices;i++){
		NSLogFont(aFont,@"0x%08x | 0x%08x | %@\n",supportedUSBDevice[i].vendorID,supportedUSBDevice[i].productID,supportedUSBDevice[i].modelName);
	}
	NSLogFont(aFont,@"--------------------------------------------\n");
}

- (void) deviceNotification:(void*)refCon
					service:(io_service_t) service
				messageType:(natural_t) messageType
			messageArgument:(void*) messageArgument
{
    ORUSBInterface* usbCallbackData = (ORUSBInterface*) refCon;
    
    if (messageType == kIOMessageServiceIsTerminated){
		NSLog(@"USB: %@ removed.\n",[usbCallbackData deviceName]);
		NSDictionary* userInfo = nil;
		if(usbCallbackData) userInfo = [NSDictionary dictionaryWithObjectsAndKeys:usbCallbackData,@"USBInterface",[usbCallbackData deviceName],@"name",nil];
		[interfaces removeObject:usbCallbackData];
        
        [[ORSerialPortList sharedSerialPortList] updatePortList];

		[[NSNotificationCenter defaultCenter] postNotificationName:ORUSBInterfaceRemoved object:self userInfo:userInfo];
	}
}



-(IOReturn) _configureAnchorDevice:(IOUSBDeviceInterface182**)dev
{
    UInt8                               numConf;
    IOReturn                            kr;
    IOUSBConfigurationDescriptorPtr     confDesc;
	
    (*dev)->GetNumberOfConfigurations(dev, &numConf);
    if (!numConf)
        return kIOReturnError;
	
    // get the configuration descriptor for index 0
    kr = (*dev)->GetConfigurationDescriptorPtr(dev, 0, &confDesc);
    if (kr) {
        NSLog(@"\tunable to get config descriptor for index %d (err = %08x)\n", 0, kr);
        return kIOReturnError;
    }
    kr = (*dev)->SetConfiguration(dev, confDesc->bConfigurationValue);
    if (kr) {
        NSLog(@"\tunable to set configuration to value %d (err=%08x)\n", 0, kr);
        return kIOReturnError;
    }
	
    return kIOReturnSuccess;
}

- (IOReturn) _findInterfaces:(IOUSBDeviceInterface182**)dev userInfo:(ORUSBInterface*) usbCallbackData supported:(BOOL)supported
{
	// UInt8                       intfClass;
    //UInt8                       intfSubClass;
	
    IOUSBFindInterfaceRequest   request;
    request.bInterfaceClass		= kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass	= kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol	= kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting	= kIOUSBFindInterfaceDontCare;
	
    io_iterator_t iterator;
    IOReturn kr = (*dev)->CreateInterfaceIterator(dev, &request, &iterator);
	
    io_service_t  usbInterface;
    while ((usbInterface = IOIteratorNext(iterator))) {
		IOUSBInterfaceInterface197** intf = NULL;
		IOCFPlugInInterface** plugInInterface = NULL;
		SInt32  score;
		IOCreatePlugInInterfaceForService(usbInterface, kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID, &plugInInterface, &score);
		kr = IOObjectRelease(usbInterface);                             // done with the usbInterface object now that I have the plugin
		if ((kIOReturnSuccess != kr) || !plugInInterface) {
			[NSException raise: @"USB Exception" format:@"unable to create a plugin (%08x)\n", kr];
		}
		
		// I have the interface plugin. I need the interface interface
		HRESULT res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID), (void**) &intf);
		(*plugInInterface)->Release(plugInInterface);                   // done with this
		if (res || !intf) {
			[NSException raise: @"USB Exception" format:@"couldn't create an IOUSBInterfaceInterface (%08lx)\n", res];
		}
		
		//kr = (*intf)->GetInterfaceClass(intf, &intfClass);
		//kr = (*intf)->GetInterfaceSubClass(intf, &intfSubClass);

		//NSLog(@"Interface class %d, subclass %d\n", intfClass, intfSubClass);
		
		// Now open the interface. This will cause the pipes to be instantiated that are
		// associated with the endpoints defined in the interface descriptor.
		kr = (*intf)->USBInterfaceOpen(intf);
		if (kIOReturnSuccess != kr) {
			if(kr != kIOReturnExclusiveAccess){
				kr = (*intf)->USBInterfaceClose(intf);				
				(void) (*intf)->Release(intf);
				[NSException raise: @"USB Exception" format:@"Interface already open for exclusive access (%08x)\n", kr];
			}
		}
		
		UInt8 intfNumEndpoints;
		kr = (*intf)->GetNumEndpoints(intf, &intfNumEndpoints);
		if (kIOReturnSuccess != kr) {
			(void) (*intf)->USBInterfaceClose(intf);
			(void) (*intf)->Release(intf);
			[NSException raise: @"USB Exception" format:@"unable to get number of endpoints (%08x)\n", kr];
		}
		
		unsigned char inPipes[8];
		unsigned char outPipes[8];
		unsigned char controlPipes[8]; //not used right now....
		unsigned char interruptInPipes[8];
		unsigned char interruptOutPipes[8];
		int inPipeCount			 = 0;
		int outPipeCount		 = 0;
		int controlPipeCount	 = 0;
		int interruptInPipeCount = 0;
		int interruptOutPipeCount= 0;
		
        if(supported){
            UInt8 pipeRef;
            for (pipeRef = 1; pipeRef <= intfNumEndpoints; pipeRef++){
                IOReturn    kr2;
                UInt8       direction;
                UInt8       number;
                UInt8       transferType;
                UInt16      maxPacketSize;
                UInt8       interval;
                
                kr2 = (*intf)->GetPipeProperties(intf, pipeRef, &direction, &number, &transferType, &maxPacketSize, &interval);
                if(kIOReturnNoDevice == kr2)     NSLog(@"no Device\n");
                else if(kIOReturnNotOpen == kr2) NSLog(@"not open\n");
                if (kIOReturnSuccess == kr2) {
                    if (transferType == kUSBBulk){
                        int kr = (*intf)->ClearPipeStallBothEnds(intf, pipeRef);
                        if(kr)NSLog(@"unable to clear pipe stall: 0x%0x\n",kr);
                        if (direction == kUSBIn)		inPipes[inPipeCount++]   = pipeRef;
                        else if (direction == kUSBOut)	outPipes[outPipeCount++] = pipeRef;
                    }
                    else if(transferType == kUSBInterrupt){
                        if (direction == kUSBIn)		interruptInPipes[interruptInPipeCount++]   = pipeRef;
                        else if (direction == kUSBOut)	interruptOutPipes[interruptOutPipeCount++] = pipeRef;
                    }
                }
                else{
                    NSLog(@"unable to get properties of pipe %d (%08x)\n", pipeRef, kr2);
                }
            }
        }
		
		// Just like with service matching notifications, we need to create an event source and add it
		//  to our run loop in order to receive async completion notifications.
		//CFRunLoopSourceRef runLoopSource;
		//kr = (*intf)->CreateInterfaceAsyncEventSource(intf, &runLoopSource);
		//if (kIOReturnSuccess != kr) {
		//	(void) (*intf)->USBInterfaceClose(intf);
		//	(void) (*intf)->Release(intf);
		//	[NSException raise: @"USB Exception" format:@"unable to create async event source (%08x)\n", kr];
		//}
		//CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
		
		//create and save an ORCA interface object with this USB interface.
		(void) (*intf)->USBInterfaceClose(intf);
        if(supported){
            [usbCallbackData setInterface:intf];
            [usbCallbackData setInPipes:inPipes		numberPipes:inPipeCount];
            [usbCallbackData setOutPipes:outPipes	numberPipes:outPipeCount];
            [usbCallbackData setControlPipes:controlPipes numberPipes:controlPipeCount];
            [usbCallbackData setInterruptInPipes:interruptInPipes	numberPipes:interruptInPipeCount];
            [usbCallbackData setInterruptOutPipes:interruptOutPipes numberPipes:interruptOutPipeCount];
        }
		if(!interfaces)interfaces	 = [[NSMutableArray array] retain];
		
		[interfaces addObject:usbCallbackData];
		
		//done with the intf, the ORCA interface has retained a ref to the interface.
		(void) (*intf)->Release(intf);
		
		//tell the world
		[[NSNotificationCenter defaultCenter] postNotificationName:ORUSBInterfaceAdded object:self userInfo:nil];
		
		if (KERN_SUCCESS != kr){
			[NSException raise: @"USB Exception" format:@"IOServiceAddInterestNotification returned %08x\n", kr];
		}
		//startUp Interrupt handling
		//        UInt32 numBytesRead = sizeof(_recieveBuffer); // leave one byte at the end for NUL termination
		//        bzero(&_recieveBuffer, numBytesRead);
		//        kr = (*intf)->ReadPipeAsync(intf, kInPipe, &_recieveBuffer, numBytesRead, (IOAsyncCallback1)_interruptRecieved, this);
		
		//        if (kIOReturnSuccess != kr) {
		//            NSLog(@"unable to do async interrupt read (%08x)\n", kr);
		//            (void) (*intf)->USBInterfaceClose(intf);
		//            (void) (*intf)->Release(intf);
		//            break;
		//        }
		
		//break; //only want the first interface
    }
	
    return kr;
}

- (NSString*) keyForVendorID:(unsigned long)aVendorID productID:(NSUInteger) aProductID
{
	return [NSString stringWithFormat:@"%lu_%lu",(unsigned long)aVendorID,(unsigned long)aProductID];
}

- (NSArray*) interfacesForVender:(NSUInteger) aVenderID product:(NSUInteger) aProductID
{
    NSMutableArray* matchingInterfaces = [NSMutableArray array];
    NSEnumerator* e = [interfaces objectEnumerator];
    ORUSBInterface* anInterface;
    while(anInterface = [e nextObject]){
        if([anInterface vendor] == aVenderID && [anInterface product] == aProductID){
            [matchingInterfaces addObject:anInterface];
        }
    }
    return matchingInterfaces;
}

- (NSArray*) interfacesForVenders:(NSArray*)someVendorIDs products:(NSArray*)someProductIDs
{
    NSMutableArray* matchingInterfaces = [NSMutableArray array];

    if([someVendorIDs count] == [someProductIDs count]){
        int i;
        for(i=0;i<[someVendorIDs count];i++){
            unsigned long aVendorID  = [[someVendorIDs objectAtIndex:i] unsignedLongValue];
            unsigned long aProductID = [[someProductIDs objectAtIndex:i] unsignedLongValue];
            [matchingInterfaces addObjectsFromArray:[self interfacesForVender:aVendorID product:aProductID]];
        }
       return  matchingInterfaces;
    }
    else {
        NSLog(@"Programmer error: vendorID and ProductID lists have different number of entries\n");
        return nil;
    }
}

- (ORUSBInterface*) getUSBInterfaceWithSerialNumber:(NSString*)aSerialNumber
{
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		if([[anInterface serialNumber] isEqualToString:aSerialNumber]){
			return anInterface;
		}
	}
	return nil;
}

@end
