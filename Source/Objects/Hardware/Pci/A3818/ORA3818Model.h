
// File:       ORA3818Model.h
// Author:		Mark A. Howe
// Copyright:	Copyright 2013.  All rights reserved

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

#pragma mark •••Type Defs
typedef struct A3818ConfigStructUser
{
    uint32_t int32[64];
} A3818ConfigStructUser;


typedef struct MapRegisterStructUser
{
    uint32_t *userAddress;
    uint32_t vmeAddress;
    uint32_t numberBytes;
    uint16_t addressModifier;
    uint16_t addressSpace; 
    uint8_t accessWidth;
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

// dma mapping register offset	
#define	DMA_MAPPING_REGISTER_OFFSET		0x0000c000
#define	ACCESS_REMOTE_IO                0x01
#define	ACCESS_REMOTE_RAM               0x02
#define	ACCESS_REMOTE_DPRAM             0x03

#pragma mark •••Exceptions
#define OExceptionNoA3818Driver			@"No A3818 Driver"
#define OExceptionNoVmeCratePower		@"No Vme Crate Power"
#define OExceptionVmeAccessError		@"Vme Access Error"
#define OExceptionVmeUnableToClear		@"Vme Unable To Clear Error"
#define OExceptionVmeCSRAccessError		@"Vme CSR Access Error"
#define OExceptionVmeBadCSROffset		@"Vme Bad CSRReg Offset"
#define CExceptionVmeLongBlockReadErr   @"Vme Long Block Read Error"
#define CExceptionVmeLongBlockWriteErr  @"Vme Long Block Write Error"

#pragma mark •••Forward Declarations
@class ORRateGroup;

// class definition
@interface ORA3818Model : ORPciCard <ORLAMhosting,OROrderedObjHolding>
{
    @private
        NSLock *theHWLock;
        mach_port_t masterPort;
        io_object_t device;
        io_object_t A3818Device;
        io_connect_t dataPort;
        io_service_t dataService;
        mach_vm_address_t CSRRegisterAddress;
        mach_vm_size_t CSRRegisterLength;
        mach_vm_address_t mapRegisterAddress;
        mach_vm_size_t mapRegisterLength;
        mach_vm_address_t remMemRegisterAddress;
        mach_vm_size_t remMemRegisterLength;    
		unsigned char* fVStatusReg;
        NSString*       deviceName;
        uint32_t 	rwAddress;
        uint32_t 	writeValue;
        uint32_t	readWriteType;
        unsigned int 	rwAddressModifier;
        unsigned int 	readWriteIOSpace;
        
        unsigned int 	dualPortAddress;
        unsigned int 	dualPortRamSize;
        
        ORAlarm*	noHardwareAlarm;
        ORAlarm*    noDriverAlarm;

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

#pragma mark •••Accessors
- (unsigned short) rangeToDo;
- (void) setRangeToDo:(unsigned short)aRange;
- (BOOL) doRange;
- (void) setDoRange:(BOOL)aDoRange;
- (NSString *) deviceName;
- (void) setDeviceName: (NSString *) aDeviceName;
- (uint32_t) rwAddress;
- (void) setRwAddress:(uint32_t)aValue;
- (uint32_t) writeValue;
- (void) setWriteValue:(uint32_t)aValue;
- (unsigned int) rwAddressModifier;
- (void) setRwAddressModifier:(unsigned int)aValue;
- (unsigned int) readWriteIOSpace;
- (void) setReadWriteIOSpace:(unsigned int)aValue;
- (uint32_t) readWriteType;
- (void) setReadWriteType:(uint32_t)aValue;
- (unsigned short) rwAddressModifierValue;
- (unsigned short) rwIOSpaceValue;

- (void) setDualPortAddress:(unsigned int) theAddress;
- (unsigned int) dualPortAddress;

- (void) setDualPortRamSize:(unsigned int) theSize;
- (unsigned int) dualPortRamSize;

#pragma mark •••Hardware Access
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
                             withDataPtr:(A3818ConfigStructUser *)pciData;

- (kern_return_t) readPCIConfigRegister:(unsigned int) address
                           withDataPtr:(unsigned int *) data;


- (kern_return_t) getPCIBusNumber:(unsigned char *) data;
- (kern_return_t) getPCIDeviceNumber:(unsigned char *)data;
- (kern_return_t) getPCIFunctionNumber:(unsigned char *)data;

//----------------------------------------------------------------
//the following methods raise exceptions by reraising the exception
//raised by checkStatusErrors;
- (void) readLongBlock:(uint32_t *) readAddress
					 atAddress:(uint32_t) vmeAddress
					 numToRead:(unsigned int) numberLongs
					withAddMod:(unsigned short) addressModifier
				 usingAddSpace:(unsigned short) addressSpace;

- (void) readLong:(uint32_t *) readAddress
             atAddress:(uint32_t) vmeAddress
             timesToRead:(unsigned int) numberLongs
            withAddMod:(unsigned short) addModifier
         usingAddSpace:(unsigned short) addressSpace;

- (void) writeLongBlock:(uint32_t *) writeAddress
					  atAddress:(uint32_t) vmeAddress
					  numToWrite:(unsigned int) numberLongs
					 withAddMod:(unsigned short) addressModifier
				  usingAddSpace:(unsigned short) addressSpace;

- (void) readByteBlock:(unsigned char *) readAddress
					 atAddress:(uint32_t) vmeAddress
					 numToRead:(unsigned int) numberBytes
					withAddMod:(unsigned short) addressModifier
				 usingAddSpace:(unsigned short) addressSpace;

- (void) writeByteBlock:(unsigned char *) writeAddress
					  atAddress:(uint32_t) vmeAddress
					  numToWrite:(unsigned int) numberBytes
					 withAddMod:(unsigned short) addressModifier
				  usingAddSpace:(unsigned short) addressSpace;


- (void) readWordBlock:(unsigned short *) readAddress
					 atAddress:(uint32_t) vmeAddress
					 numToRead:(unsigned int) numberWords
					withAddMod:(unsigned short) addressModifier
				 usingAddSpace:(unsigned short) addressSpace;

- (void) writeWordBlock:(unsigned short *) writeAddress
					  atAddress:(uint32_t) vmeAddress
					  numToWrite:(unsigned int) numberWords
					 withAddMod:(unsigned short) addressModifier
				  usingAddSpace:(unsigned short) addressSpace;

- (void) executeCommandList:(ORCommandList*)aList;

- (void) printErrorSummary;
- (void) printConfigurationData;
- (void) printStatus;
- (NSString*) decodeDeviceName:(unsigned short) deviceID;


#pragma mark •••DMA
- (void) readLongBlock:(uint32_t *) readAddress
					 atAddress:(uint32_t) vmeAddress
					 numToRead:(unsigned int) numberLongs
				 usingAddSpace:(unsigned short) addressSpace
				 useBlockMode:(bool) useBlockMode;

- (void) writeLongBlock:(uint32_t *) writeAddress
					  atAddress:(uint32_t) vmeAddress
					  numToWrite:(unsigned int) numberLongs
				  usingAddSpace:(unsigned short) addressSpace
				 useBlockMode:(bool) useBlockMode;
				 
- (bool) checkDmaErrors;

- (bool) checkDmaComplete:(uint32_t*) checkFlag;

- (void) startDma:(uint32_t) vmeAddress 
  physicalBufferAddress:(uint32_t) physicalBufferAddress
		numberTransfers:(uint32_t) numberTransfers 
		   addressSpace:(unsigned short) addressSpace
		 enableByteSwap:(bool) enableByteSwap 
		 enableWordSwap:(bool) enableWordSwap
		   useBlockMode:(bool) useBlockMode
			  direction:(char) theDirection;
			  
- (void) setupMappingDMA:(uint32_t) remoteAddress
	numberBytes:(uint32_t) numberBytes
		 enableByteSwap:(bool) enableByteSwap 
		 enableWordSwap:(bool) enableWordSwap;


//----------------------------------------------------------------
//the following methods can raise exceptions directly
- (void) resetContrl;
- (void) checkStatusErrors;
- (void) checkStatusWord:(unsigned char)dataWord;
//----------------------------------------------------------------

#pragma mark •••OROrderedObjHolding Protocol
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


#pragma mark •••External String Definitions
extern NSString* ORA3818ModelRangeChanged;
extern NSString* ORA3818ModelDoRangeChanged;
extern NSString* ORA3818DualPortAddresChangedNotification;
extern NSString* ORA3818DualPortRamSizeChangedNotification;
extern NSString* ORA3818RWAddressChangedNotification;
extern NSString* ORA3818WriteValueChangedNotification;
extern NSString* ORA3818RWAddressModifierChangedNotification;
extern NSString* ORA3818RWIOSpaceChangedNotification;
extern NSString* ORA3818RWTypeChangedNotification;
extern NSString* ORA3818RateGroupChangedNotification;
extern NSString* ORA3818ErrorRateXChangedNotification;
extern NSString* ORA3818ErrorRateYChangedNotification;
extern NSString* ORA3818DeviceNameChangedNotification;
extern NSString* ORA3818Lock;

