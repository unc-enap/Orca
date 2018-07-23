/*
	File:		ORFireWireInterface.h

	Synopsis: 	C++ class to represent an device on the FireWire bus. Corresponds
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

#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/firewire/IOFireWireLib.h>

@class ORAlarm;

@interface ORFireWireInterface : NSObject
{
	@private
		IOCFPlugInInterface**		mIOCFPlugInInterface; 
		IOFireWireLibDeviceRef		mDevice; 
		CFRunLoopRef				mIsochRunLoop; 
		
		IONotificationPortRef		mNotificationPort;
		//CFMutableDictionaryRef		mNotifications;
		io_object_t					mNotification;
		BOOL						isOpen;
		BOOL						serviceAlive;
        ORAlarm*					fireWireServiceAlarm;
		NSLock*						fwLock;
}
		
- (id) initWithService:(io_object_t) aDevice;
- (void) dealloc;

#pragma mark ¥¥¥Accessors
- (BOOL) serviceAlive;
- (void) setServiceAlive:(BOOL)aServiceAlive;
- (BOOL) isOpen;
- (void) setIsOpen:(BOOL)aIsOpen;
- (io_service_t) service;														


- (void) open;																
- (void) close;																

- (void) printConfigROM;
- (void) registerInterest;
- (void) deviceCallback:(natural_t) messageType argument:(void*)messageArgument;

- (void) unLockAndRaise;
- (void) write_raw:(uint64_t)address value:(uint32_t*)theData size:(uint32_t)len;
- (void) read_raw:(uint64_t) address data:(uint32_t*)theData size:(uint32_t)len;

- (void) write_raw:(uint64_t)address value:(uint32_t)aValue;
- (uint32_t) read_raw:(uint64_t) address;


- (void) compareSwap64:(IOFireWireLibDeviceRef) addr
		 expectedValue:(uint32_t*)expectedVal
				newVal:(uint32_t*)newVal
				oldVal:(uint32_t*)oldVal
				  size:(IOByteCount)size
				   abs:(BOOL) abs
		   failOnReset:(BOOL)failOnReset
			generation:(uint32_t)generation;	

- (void) busReset;														
- (void) getBusGeneration:(uint32_t*) generation;						
- (void) getLocalNodeIDWithGeneration:(uint32_t) checkGeneration
						  localNodeID:(unsigned short*) localNodeID;

- (void) getRemoteNodeID:(uint32_t) checkGeneration
			remoteNodeID:(unsigned short*) remoteNodeID;

- (void) getSpeedToNode:(uint32_t) checkGeneration
				  speed:(IOFWSpeed*) speed;

- (void) getSpeedBetweenNodes:(uint32_t) checkGeneration
					srcNodeId:(uint32_t) srcNodeID
				   destNodeID:(unsigned short) destNodeID
						speed:( IOFWSpeed*) speed;					
-(IOFireWireLibDeviceRef) interface;													

@end

extern NSString* ORFireWireInterfaceServiceAliveChanged;
extern NSString* ORFireWireInterfaceIsOpenChanged;

