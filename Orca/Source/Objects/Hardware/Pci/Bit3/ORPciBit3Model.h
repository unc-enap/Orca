/*

File:       ORPciBit3Model.h
From:		CVmeContrl620.h

Usage:		Class Definition for the Bit3 Bit3 PCI VME
I/O Kit Kernel Extension (KEXT) Functions

Author:		FM

Copyright:		Copyright 2001-2002 F. McGirt.  All rights reserved.

Change History:	1/22/02, 2/2/02, 2/12/02,
3/1/02  - number of transfers <= 4096 bytes
3/4/02 - transfers > 4096 bytes done in chunks

According to Apple, currently the IOKit and IOUserClient
(IOConnectMethodxx) do not support the transfer of single
blocks larger than 4096 bytes (a memory page) between user
space and kernel space.  Thus any larger block must be
transferred in chunks of 4096 bytes or less.

5/21/02 - IOServiceClose added in destructor to match
IOServiceOpen

5/22/02 - Open/Close calls to User Client methods added
5/29/02 - direct mapping of Bit3 address spaces from user
space added, single transfers up to 64768 32 bit
items allowed
6/5/02 - added comments and some cleanup
8/7/02 - additional cleanup
11/20/02 - added error returns to selected functions
11/3/04  - MAH CENPA. converted to generic Bit3 controller


Notes:		Bit3 PCI Matching is done with
Vendor ID 0x108a and Device IDs of the Bit3 cards.

This task would have be much easier had there been an
IOKit PCI family library available from Apple.  Since
one cannot inherit from an IOKit provided family for
PCI, one must write the required methods using the raw
tools that IOKit provide.  Hopefully, at some point
this situation will improve.


-----------------------------------------------------------
	This program was prepared for the Regents of the University of 
	Washington at the Center for Experimental Nuclear Physics and 
	Astrophysics (CENPA) sponsored in part by the United States 
	Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
	The University has certain rights in the program pursuant to 
	the contract and the program should not be copied or distributed 
	outside your organization.  The DOE and the University of 
	Washington reserve all rights in the program. Neither the authors,
	University of Washington, or U.S. Government make any warranty, 
	express or implied, or assume any liability or responsibility 
	for the use of this software.
-------------------------------------------------------------*/

#pragma mark ¥¥¥Imported Files
#import <mach/mach.h>
#import <mach/mach_error.h>

#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOTypes.h>
#import <IOKit/iokitmig.h>
#import <IOKit/IOKitLib.h>
#import <ApplicationServices/ApplicationServices.h>
#import "ORPciCard.h"
#import "ORLAMhosting.h"
#import "OROrderedObjHolding.h"

@class ORAlarm;
@class ORCommandList;

#pragma mark ¥¥¥Type Defs
typedef struct PCIConfigStructUser
{
    UInt32 int32[64];
} PCIConfigStructUser;


typedef struct MapRegisterStructUser
{
    UInt32 *userAddress;
    UInt32 vmeAddress;
    UInt32 numberBytes;
    UInt16 addressModifier;
    UInt16 addressSpace; 
    UInt8 accessWidth;
} MapRegisterStructUser;


enum {
    kIOPCIConfigVendorID			= 0x00,
    kIOPCIConfigDeviceID			= 0x02,
    kIOPCIConfigCommand				= 0x04,
    kIOPCIConfigStatus				= 0x06,
    kIOPCIConfigRevisionID			= 0x08,
    kIOPCIConfigClassCode			= 0x09,
    kIOPCIConfigCacheLineSize		= 0x0C,
    kIOPCIConfigLatencyTimer		= 0x0D,
    kIOPCIConfigHeaderType			= 0x0E,
    kIOPCIConfigBIST				= 0x0F,
    kIOPCIConfigBaseAddress0		= 0x10,
    kIOPCIConfigBaseAddress1		= 0x14,
    kIOPCIConfigBaseAddress2		= 0x18,
    kIOPCIConfigBaseAddress3		= 0x1C,
    kIOPCIConfigBaseAddress4		= 0x20,
    kIOPCIConfigBaseAddress5		= 0x24,
    kIOPCIConfigCardBusCISPtr		= 0x28,
    kIOPCIConfigSubSystemVendorID	= 0x2C,
    kIOPCIConfigSubSystemID			= 0x2E,
    kIOPCIConfigExpansionROMBase	= 0x30,
    kIOPCIConfigCapabilitiesPtr		= 0x34,
    kIOPCIConfigInterruptLine		= 0x3C,
    kIOPCIConfigInterruptPin		= 0x3D,
    kIOPCIConfigMinimumGrant		= 0x3E,
    kIOPCIConfigMaximumLatency		= 0x3F
};

enum {
    kByteRetryIndex,
    kWordRetryIndex,
    kLongRetryIndex,
    kNumRetryIndexes
};

// dma mapping register offset	
#define	DMA_MAPPING_REGISTER_OFFSET		0x0000c000
#define	ACCESS_REMOTE_IO		0x01
#define	ACCESS_REMOTE_RAM		0x02
#define	ACCESS_REMOTE_DPRAM		0x03

#pragma mark ¥¥¥Exceptions
#define OExceptionNoBit3Driver			@"No Bit3 Driver"
#define OExceptionNoVmeCratePower		@"No Vme Crate Power"
#define OExceptionVmeAccessError		@"Vme Access Error"
#define OExceptionVmeUnableToClear		@"Vme Unable To Clear Error"
#define OExceptionVmeCSRAccessError		@"Vme CSR Access Error"
#define OExceptionVmeBadCSROffset		@"Vme Bad CSRReg Offset"
#define CExceptionVmeLongBlockReadErr   @"Vme Long Block Read Error"
#define CExceptionVmeLongBlockWriteErr  @"Vme Long Block Write Error"

#pragma mark ¥¥¥Forward Declarations
@class ORRateGroup;

// class definition
@interface ORPciBit3Model : ORPciCard <ORLAMhosting,OROrderedObjHolding>
{
    @private
        NSLock *theHWLock;
        mach_port_t masterPort;
        io_object_t device;
        io_object_t bit3Device;
        io_connect_t dataPort;
        io_service_t dataService;
        vm_address_t CSRRegisterAddress;
        vm_size_t CSRRegisterLength;
        vm_address_t mapRegisterAddress;
        vm_size_t mapRegisterLength;
        vm_address_t remMemRegisterAddress;
        vm_size_t remMemRegisterLength;    
		unsigned char* fVStatusReg;
        NSString*       deviceName;
        unsigned int 	rwAddress;
        unsigned int 	writeValue;
        unsigned int	readWriteType;
        unsigned int 	rwAddressModifier;
        unsigned int 	readWriteIOSpace;
        
        unsigned int 	dualPortAddress;
        unsigned int 	dualPortRamSize;
        
        ORAlarm*	noHardwareAlarm;
        ORAlarm*    noDriverAlarm;
        int		errorCount;

        
        NSDictionary* errorRateXAttributes;
        NSDictionary* errorRateYAttributes;
        ORRateGroup*    errorRateGroup;
        unsigned long   retryCount[3];
        unsigned long   retryFailedCount[3];
        int totalDevicesFound;
		unsigned timeOutErrors;
		unsigned remoteBusErrors;
		BOOL doRange;
		unsigned short rangeToDo;
		BOOL powerWasOff;
}

- (unsigned short) vendorID;
- (const char*) serviceClassName;
- (NSString*) driverPath;
- (void) setUpImage;

- (void) registerNotificationObservers;
- (void) runEnded:(NSNotification*)aNote;

#pragma mark ¥¥¥Accessors
- (unsigned short) rangeToDo;
- (void) setRangeToDo:(unsigned short)aRange;
- (BOOL) doRange;
- (void) setDoRange:(BOOL)aDoRange;
- (NSString *) deviceName;
- (void) setDeviceName: (NSString *) aDeviceName;
- (unsigned long) rwAddress;
- (void) setRwAddress:(unsigned long)aValue;
- (unsigned long) writeValue;
- (void) setWriteValue:(unsigned long)aValue;
- (unsigned int) rwAddressModifier;
- (void) setRwAddressModifier:(unsigned int)aValue;
- (unsigned int) readWriteIOSpace;
- (void) setReadWriteIOSpace:(unsigned int)aValue;
- (unsigned int) readWriteType;
- (void) setReadWriteType:(unsigned int)aValue;
- (unsigned short) rwAddressModifierValue;
- (unsigned short) rwIOSpaceValue;

- (void) setDualPortAddress:(unsigned int) theAddress;
- (unsigned int) dualPortAddress;

- (void) setDualPortRamSize:(unsigned int) theSize;
- (unsigned int) dualPortRamSize;

- (ORRateGroup*)    errorRateGroup;
- (void)	    setErrorRateGroup:(ORRateGroup*)newErrorRateGroup;
- (void) setIntegrationTime:(double)newIntegrationTime;
- (NSDictionary*) errorRateXAttributes;
- (void) setErrorRateXAttributes:(NSDictionary*)newErrorRateXAttributes;
- (NSDictionary*) errorRateYAttributes;
- (void) setErrorRateYAttributes:(NSDictionary*)newErrorRateYAttributes;

#pragma mark ¥¥¥Hardware Access
- (void)  checkCratePower;
- (unsigned char) getAdapterID;
- (unsigned char) getLocalStatus;
- (unsigned char) clearErrorBits;
- (void) vmeSysReset:(unsigned char *)status;

- (kern_return_t) writeCSRRegister:(unsigned char) regOffSet
                                    withData:(unsigned char) data;

- (kern_return_t) readCSRRegister:(unsigned char) regOffSet
                                    withDataPtr:(unsigned char *) data;
	
- (kern_return_t) readCSRRegisterNoLock:(unsigned char) regOffSet
			    withDataPtr:(unsigned char *) data;
                            
- (kern_return_t) getPCIConfigurationData:(unsigned int) maxAddress
                             withDataPtr:(PCIConfigStructUser *)pciData;

- (kern_return_t) readPCIConfigRegister:(unsigned int) address
                           withDataPtr:(unsigned int *) data;


- (kern_return_t) getPCIBusNumber:(unsigned char *) data;
- (kern_return_t) getPCIDeviceNumber:(unsigned char *)data;
- (kern_return_t) getPCIFunctionNumber:(unsigned char *)data;

//----------------------------------------------------------------
//the following methods raise exceptions by reraising the exception
//raised by checkStatusErrors;
- (void) readLongBlock:(unsigned long *) readAddress
					 atAddress:(unsigned long) vmeAddress
					 numToRead:(unsigned int) numberLongs
					withAddMod:(unsigned short) addressModifier
				 usingAddSpace:(unsigned short) addressSpace;

- (void) readLong:(unsigned long *) readAddress
             atAddress:(unsigned long) vmeAddress
             timesToRead:(unsigned int) numberLongs
            withAddMod:(unsigned short) addModifier
         usingAddSpace:(unsigned short) addressSpace;

- (void) writeLongBlock:(unsigned long *) writeAddress
					  atAddress:(unsigned long) vmeAddress
					  numToWrite:(unsigned int) numberLongs
					 withAddMod:(unsigned short) addressModifier
				  usingAddSpace:(unsigned short) addressSpace;

- (void) readByteBlock:(unsigned char *) readAddress
					 atAddress:(unsigned long) vmeAddress
					 numToRead:(unsigned int) numberBytes
					withAddMod:(unsigned short) addressModifier
				 usingAddSpace:(unsigned short) addressSpace;

- (void) writeByteBlock:(unsigned char *) writeAddress
					  atAddress:(unsigned long) vmeAddress
					  numToWrite:(unsigned int) numberBytes
					 withAddMod:(unsigned short) addressModifier
				  usingAddSpace:(unsigned short) addressSpace;


- (void) readWordBlock:(unsigned short *) readAddress
					 atAddress:(unsigned long) vmeAddress
					 numToRead:(unsigned int) numberWords
					withAddMod:(unsigned short) addressModifier
				 usingAddSpace:(unsigned short) addressSpace;

- (void) writeWordBlock:(unsigned short *) writeAddress
					  atAddress:(unsigned long) vmeAddress
					  numToWrite:(unsigned int) numberWords
					 withAddMod:(unsigned short) addressModifier
				  usingAddSpace:(unsigned short) addressSpace;

- (void) executeCommandList:(ORCommandList*)aList;

- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag;
- (void) printErrorSummary;
- (void) printConfigurationData;
- (void) printStatus;
- (NSString*) decodeDeviceName:(unsigned short) deviceID;


#pragma mark ¥¥¥DMA
- (void) readLongBlock:(unsigned long *) readAddress
					 atAddress:(unsigned long) vmeAddress
					 numToRead:(unsigned int) numberLongs
				 usingAddSpace:(unsigned short) addressSpace
				 useBlockMode:(bool) useBlockMode;

- (void) writeLongBlock:(unsigned long *) writeAddress
					  atAddress:(unsigned long) vmeAddress
					  numToWrite:(unsigned int) numberLongs
				  usingAddSpace:(unsigned short) addressSpace
				 useBlockMode:(bool) useBlockMode;
				 
- (bool) checkDmaErrors;

- (bool) checkDmaComplete:(unsigned long*) checkFlag;

- (void) startDma:(unsigned long) vmeAddress 
  physicalBufferAddress:(unsigned long) physicalBufferAddress
		numberTransfers:(unsigned long) numberTransfers 
		   addressSpace:(unsigned short) addressSpace
		 enableByteSwap:(bool) enableByteSwap 
		 enableWordSwap:(bool) enableWordSwap
		   useBlockMode:(bool) useBlockMode
			  direction:(char) theDirection;
			  
- (void) setupMappingDMA:(unsigned long) remoteAddress
	numberBytes:(unsigned long) numberBytes
		 enableByteSwap:(bool) enableByteSwap 
		 enableWordSwap:(bool) enableWordSwap;


//----------------------------------------------------------------
//the following methods can raise exceptions directly
- (void) resetContrl;
- (void) checkStatusErrors;
- (void) checkStatusWord:(unsigned char)dataWord;
//----------------------------------------------------------------

#pragma mark ¥¥¥OROrderedObjHolding Protocol
- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) groupSeparation;
- (NSString*) nameForSlot:(int)aSlot;
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj;
- (int) slotForObject:(id)anObj;
- (NSRange) legalSlotsForObj:(id)anObj;
- (int) slotAtPoint:(NSPoint)aPoint ;
- (NSPoint) pointForSlot:(int)aSlot; 
- (void) place:(id)anObj intoSlot:(int)aSlot;
- (int) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;

@end


#pragma mark ¥¥¥External String Definitions
extern NSString* ORPciBit3ModelRangeChanged;
extern NSString* ORPciBit3ModelDoRangeChanged;
extern NSString* ORPciBit3DualPortAddresChangedNotification;
extern NSString* ORPciBit3DualPortRamSizeChangedNotification;
extern NSString* ORPciBit3RWAddressChangedNotification;
extern NSString* ORPciBit3WriteValueChangedNotification;
extern NSString* ORPciBit3RWAddressModifierChangedNotification;
extern NSString* ORPciBit3RWIOSpaceChangedNotification;
extern NSString* ORPciBit3RWTypeChangedNotification;
extern NSString* ORPciBit3RateGroupChangedNotification;
extern NSString* ORPciBit3ErrorRateXChangedNotification;
extern NSString* ORPciBit3ErrorRateYChangedNotification;
extern NSString* ORPciBit3DeviceNameChangedNotification;
extern NSString* ORPciBit3Lock;

