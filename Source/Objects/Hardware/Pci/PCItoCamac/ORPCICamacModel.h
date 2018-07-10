/*

File:		CCamacContrlPCICamac.h

Usage:		Class Definition for the ARW PCI-CAMAC
I/O Kit Kernel Extension (KEXT) Functions

Author:		F. McGirt

Copyright:		Copyright 2003 F. McGirt.  All rights reserved.

Change History:	1/20/03
07/29/03 MAH CENPA. Converted to Obj-C for the ORCA project.


Notes:		PCI Matching is done with
Vendor ID 0x10b5 and Device ID 0x2258
Subsystem Vendor ID 0x9050
Subsystem Device ID 0x2258


There are two "features" of the ARE PCI-CAMAC hardware to
be aware of:

The hardware as delivered may come configured for use with
MS-DOS and force all memory accesses to lie below 1MB. This
will not work for either Mac or Win OSs and must be changed
using the PLX tools for re-programming the EEPROM on board
the PCI card.

The PCI-CAMAC hardware forces all NAF command writes to set
the F16 bit to a 1 and all NAF command reads to set the F16
bit to 0.  Therefore all F values from F0 through F15 MUST
be used with CAMAC bus read accesses and all F values from
F16 through F31 MUST be used with CAMAC bus write accesses.


At times delays must be used between a sequence
of NAF commands or the PCICamac status returns
will not reflect the current status - but usually
that of the previous NAF command.  (See the
									CCamacContrlPCICamacTest object.)  This may possibly
be due to the design of the controller hardware, 
the speed of the PowerMac G4, or to the use of an
optimizing compiler which may relocate memory
accesses.   In an effort to alleviate this problem
all variables used to access PCI-CAMAC memory spaces
are declared volatile.


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
-------------------------------------------------------------


	*/

#pragma mark ¥¥¥Imported Files
#import "ORPciCard.h"
#import "ORPCICamacCommands.h"

#import <mach/mach.h>
#import <mach/mach_error.h>
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOTypes.h>
#import <IOKit/iokitmig.h>
#import <IOKit/IOKitLib.h>
#import <ApplicationServices/ApplicationServices.h>
#import "ORCamacExceptions.h"

// definitions
#define kLCRIntCSROffset		19			// 0x4c / 4 = 0x13 = 19
#define kLCDControlOffset		20			// 0x50 / 4 = 0x14 = 20
#define kInitialControlStatus	0x4986
#define kPowerControlStatus		0x4900

@class ORAlarm;

/* Definitions of PCI Config Registers */
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

// class definition
@interface ORPCICamacModel : ORPciCard
{
	@private
    NSRecursiveLock* theHWLock;
    NSLock*          theStatusLock;
    NSRecursiveLock* thePowerLock;
    NSLock*          theLCLock;
    ORAlarm*          noHardwareAlarm;
    ORAlarm*        noDriverAlarm;
	
    mach_port_t 	masterPort;
    CFDictionaryRef camacMatch;
    io_iterator_t 	iter;
    io_object_t 	device;
    io_object_t 	camacDevice;
    io_connect_t 	dataPort;
    io_service_t 	dataService;
    vm_address_t 	mapLCRegisterAddress;
    vm_size_t 		mapLCRegisterLength;
    vm_address_t 	mapPCICamacMemoryAddress;
    vm_size_t 		mapPCICamacMemoryLength;
	BOOL powerOK;
}

- (kern_return_t)  getPCIConfigurationData:(unsigned int) maxAddress data:(PCIConfigStruct*)pciData;
- (kern_return_t)  readPCIConfigRegister:(unsigned int) address data:(unsigned int*)data;
- (kern_return_t)  getPCIBusNumber:(unsigned char*) data;
- (kern_return_t)  getPCIDeviceNumber:(unsigned char*) data;
- (kern_return_t)  getPCIFunctionNumber:(unsigned char*) data;
- (void)		   checkStatusReturn:(unsigned short)theStatus station:(unsigned short) n;

- (void)            writeLCRegister:(unsigned short)regOffSet data:(unsigned short) data;
- (unsigned short)  readLCRegister: (unsigned short) regOffSet;

- (unsigned long)   readLEDs;
- (unsigned short)  camacStatus;		// get status
- (void)            checkCratePower;	// check crate power
- (void)            checkStatusErrors;	// check controller status
- (BOOL)			powerOK;
- (void)            lock;               //so others can lock blocks of access
- (void)            unlock;

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f;
								
- (unsigned short) camacShortNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(unsigned short*) data;

- (unsigned short) camacShortNAFBlock:(unsigned short)n 
									a:(unsigned short)a 
									f:(unsigned short)f
								 data:(unsigned short*) data 
							   length:(unsigned long) numWords;

- (unsigned short)  camacLongNAF:(unsigned short)n 
							   a:(unsigned short) a 
							   f:(unsigned short) f;
- (unsigned short)  camacLongNAF:(unsigned short)n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(unsigned long*) data;

- (unsigned short) camacLongNAFBlock:(unsigned short)n 
									a:(unsigned short)a 
									f:(unsigned short)f
								 data:(unsigned long*) data 
							   length:(unsigned long) numWords;

- (void) delay:(float)delayValue;
- (void) printConfigurationData;


@end

