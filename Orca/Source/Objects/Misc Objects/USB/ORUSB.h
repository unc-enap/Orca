//
//  ORUSB.h
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



#import <IOKit/IOKitLib.h>
#import <IOKit/usb/IOUSBLib.h>
#import <mach/mach.h>

typedef struct  {
	UInt8 bytes[6];
}WLHardwareAddress;

typedef  struct  {
    UInt16 vendor;
    UInt16 variant;
    UInt16 major;
    UInt16 minor;
}WLIdentity;

@class ORUSBInterface;
@class ORUSBInterface;

@interface ORUSB : NSObject {
	@private
		NSMutableArray*			devices;
		NSMutableArray*			interfaces;
		CFRunLoopSourceRef		_runLoopSource;
		IONotificationPortRef	_notifyPort;
		io_iterator_t			_deviceAddedIter;
		io_iterator_t			_deviceRemovedIter;
		BOOL					matching;
}

#pragma mark ¥¥¥initialization
+ (ORUSB*) sharedUSB;
- (void) dealloc;
- (void) awakeAfterDocumentLoaded;

#pragma mark ¥¥¥accessors
- (void) registerForUSBNotifications:(id)anObj;

- (NSString*) keyForVendorID:(unsigned long)aVendorID productID:(NSUInteger) aProductID;

#pragma mark ¥¥¥HW access
- (void) startMatching;
- (void) deviceAdded:(io_iterator_t) iterator;
- (void) deviceNotification:(void*)refCon
					service:(io_service_t) service
                messageType:(natural_t) messageType
            messageArgument:(void*) messageArgument;

- (IOReturn) _configureAnchorDevice:(IOUSBDeviceInterface182**)dev;
- (IOReturn) _findInterfaces:(IOUSBDeviceInterface182**)dev userInfo:(ORUSBInterface*) usbCallbackData supported:(BOOL)supported;


- (ORUSBInterface*) getUSBInterface:(unsigned long)aVendorID productID:(NSUInteger) aProductID;
- (NSArray*) interfacesForVender:(NSUInteger) aVenderID product:(NSUInteger) aProductID;
- (NSArray*) interfacesForVenders:(NSArray*)someVendorIDs products:(NSArray*)someProductIDs;
- (NSUInteger) deviceCount;
- (NSUInteger) interfaceCount;
- (NSArray*) interfaces;
- (id) deviceAtIndex:(NSUInteger)index;
- (void) releaseInterfaceFor:(id)obj;
- (void) claimInterfaceWithSerialNumber:(NSString*)serialNumber for:(id)obj;
- (void) claimInterfaceWithVendor:(unsigned long)aVendorID product:(NSUInteger) aProductID for:(id)obj;
- (ORUSBInterface*) getUSBInterfaceWithSerialNumber:(NSString*)aSerialNumber;
- (void) removeAllObjects;
- (void) objectsAdded:(NSArray*)newObjects;
- (void) objectsRemoved:(NSArray*)deletedObjects;
- (void) listSupportedDevices;
- (void) searchForDevices;

@end

extern NSString* ORUSBDevicesAdded;
extern NSString* ORUSBDevicesRemoved;
extern NSString* ORUSBInterfaceRemoved;
extern NSString* ORUSBInterfaceAdded;

@interface NSObject (multipleIDs)
- (NSArray*) vendorIDs;
- (NSArray*) productIDs;
- (NSUInteger) vendorID;
- (NSUInteger) productID;
@end

@protocol USBDevice
- (id) getUSBController;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) usbInterfaceDescription;
- (void) registerWithUSB:(id)usb;
- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;
@end

