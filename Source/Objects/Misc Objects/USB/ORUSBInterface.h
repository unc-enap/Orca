/*
	File:		ORUSBInterface.h

	Synopsis: 	C++ class to represent an device on the FireWire bus. Corresponds
				to IOUSBDeviceInterface.

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
#import <IOKit/usb/IOUSBLib.h>
#include <IOKit/IOCFPlugIn.h>

typedef struct  {
		unsigned char messageID;
		unsigned char bTag;
		unsigned char bTagInverse;
		unsigned char reserved1;
		uint32_t transferLength;
		unsigned char eom; //bit 0 = 1 if last byte is end of message
		unsigned char reserved2;
		unsigned char reserved3;
		unsigned char reserved4;
	} USB488Header;

@interface ORUSBInterface : NSObject
{
	@private
		id							callBackObject;
		id							registeredObject;
		IOUSBInterfaceInterface197**	interface; 
		uint8_t							transferType;
		unsigned char				inPipes[8];
		unsigned char				outPipes[8];
		unsigned char				controlPipes[8];
		unsigned char				interruptInPipes[8];
		unsigned char				interruptOutPipes[8];
		NSString*					deviceName;
		uint32_t						locationID;
		uint16_t						vendor;
		uint16_t						product;
		io_object_t					notification;
		NSString*				    connectionState;
		NSString*					serialNumber;
		char						receiveBuffer[1024];
		unsigned char				tag;
		NSRecursiveLock*			usbLock;
}
		
- (void) dealloc;

#pragma mark ¥¥¥Accessors
- (id)			callBackObject;
- (void)		setCallBackObject:(id)anObj;
- (void)		setUsePipeType:(uint8_t)aTransferType;
- (uint8_t)		usingPipeType;
- (void)		writeString:(NSString*)aCommand;
- (void)		writeUSB488Command:(NSString*)aCommand eom:(BOOL)eom;
- (int)			readUSB488:(char*)resultData length:(uint32_t)amountRead;
- (void)		writeBytes:(void*)bytes length:(uint32_t)length pipe:(uint32_t)aPipeIndex;
- (int)			readBytes:(void*)bytes length:(uint32_t)length pipe:(int)aPipeIndex;
- (void)		writeBytes:(void*)bytes length:(uint32_t)length;
- (int)			readBytes:(void*)bytes length:(uint32_t)amountToRead;
- (int)			readBytesFastNoThrow:(void*)bytes length:(uint32_t)amountToRead;
- (void)		setRegisteredObject:(id)anObj;
- (id)			registeredObject;
- (uint16_t)		product;
- (void)		setProduct:(uint16_t)aProduct;
- (uint16_t)		vendor;
- (void)		setVendor:(uint16_t)aVendor;
- (uint32_t)		locationID;
- (void)		setLocationID:(uint32_t)aLocationID;
- (NSString*)	deviceName;
- (void)		setDeviceName:(NSString*)aDeviceName;
- (NSString*)	serialNumber;
- (void)		setSerialNumber:(NSString*)aSerialString;
- (io_object_t) notification;
- (void)		setNotification:(io_object_t)aNotification;
- (void)		setInterface:(IOUSBInterfaceInterface197**)anInterface;
- (IOUSBInterfaceInterface197**) interface;
- (void)		setInPipes:(unsigned char*)aPipeRef  numberPipes:(int)n;
- (void)		setOutPipes:(unsigned char*)aPipeRef numberPipes:(int)n;
- (void)		setControlPipes:(unsigned char*)aPipeRef numberPipes:(int)n;
- (void)		setInterruptInPipes:(unsigned char*)aPipeRef numberPipes:(int)n;
- (void)		setInterruptOutPipes:(unsigned char*)aPipeRef numberPipes:(int)n;
- (NSString*)   connectionState;
- (void)		setConnectionState:(NSString*)aState;
- (void)		interruptRecieved:(IOReturn) result length:(int) len;
- (void)		startReadingInterruptPipe;
- (int)			readBytesOnInterruptPipeNoLock:(void*)bytes length:(uint32_t)amountRead;

- (int) readBytesOnInterruptPipe:(void*)bytes length:(uint32_t)amountRead;
- (void) writeBytesOnInterruptPipe:(void*)bytes length:(uint32_t)amountRead;

@end

extern NSString* ORUSBRegisteredObjectChanged;

