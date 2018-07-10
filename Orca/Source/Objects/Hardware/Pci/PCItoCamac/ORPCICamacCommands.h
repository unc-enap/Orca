/*
    File:		ORPCICamacCommands.h
    
    Usage:		User Client Data Structures for PCICAMACFMDriver
    
    Author:		FM
    
    Copyright:		Copyright 2002-2003 F. McGirt.  All rights reserved.
    
    Change History:	11/22/02, 1/6/03 - 1.0.0d1, Initial Versions
                        
                        According to Apple, currently the IOKit and IOUserClient
                        (IOConnectMethodxx) do not support the transfer of single
                        blocks larger than 4096 bytes (a memory page) between user
                        space and kernel space.  Thus any larger block must be
                        transferred in chunks of 4096 bytes or less.
                      
                      
    Note:		PCI Matching is done with
                            Vendor ID 0x10b5 and Device ID 0x2258
                                                
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
                         

                        There are cases where IOService may leak when start() returns
                        false after calling super::start() as start()/stop() are
                        not entirely a matched pair - there is some chance that
                        allocated resources do not get deallocated before the driver
                        stops.  It is recommended that all resources be deallocated
                        as soon as possible after they are no longer needed and
                        perhaps a final deallocation sweep of all allocated resources
                        be made in free().


    Caution:		*** The Mother of all Disclaimers ***
                        Pay careful attention to any data retrieved from CAMAC or
                        written to CAMAC using this software because of potential
                        byte and word swapping problems.  Experimental data generated
                        from sources resident on CAMAC must be checked for validity
                        before use.
                        
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
    

// macros
// swap 8 bit quantities in 16 bit value ( |2| |1| -> |1| |2| )
#define Swap8BitsIn16(x) 	((((x) & 0xff00) >> 8) | (((x) & 0x00ff) << 8))

// swap 16 bit quantities in 32 bit value ( |2| |1| -> |1| |2| )
#define Swap16Bits(x)    ((((x) & 0xffff0000) >> 16) | (((x) & 0x0000ffff) << 16))

// swap 8 bit quantities in 32 bit value ( |4| |3| |2| |1| -> |1| |2| |3| |4| )
#define Swap8Bits(x)	((((Swap16Bits(x) & 0x0000ff00) >> 8) | ((Swap16Bits(x) & 0x000000ff) << 8)) \
                    | (((Swap16Bits(x) & 0xff000000) >> 8) | ((Swap16Bits(x) & 0x00ff0000) << 8)))
                    
// N A F offset
#define offsetNAF(N, A, F) (((UInt16)((N << 10) + (A << 6) + ((F & 0xf) << 2))))


// command codes
enum PCICAMACUserClientCommandCodes {
    kPCICAMACUserClientOpen,		// kIOUCScalarIScalarO,  0, 0
    kPCICAMACUserClientClose,		// kIOUCScalarIScalarO,  0, 0
    kPCICAMACReadPCIConfig,		// kIOUCScalarIScalarO,  1, 1
    kPCICAMACWritePCIConfig,		// kIOUCScalarIScalarO,  2, 0
    kPCICAMACGetPCIConfig,		// kIOUCScalarIStructO,	 1, 1
    kPCICAMACGetPCIBusNumber,		// kIOUCScalarIScalarO,  0, 1
    kPCICAMACGetPCIDeviceNumber,	// kIOUCScalarIScalarO,  0, 1
    kPCICAMACGetPCIFunctionNumber,	// kIOUCScalarIScalarO,  0, 1
    kPCICAMACNumCommands
};

// PCI configuration structure
typedef struct PCIConfigStruct
{
    uint32_t int32[64];
} PCIConfigStruct;

// driver class name
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
#define kPCICAMACServiceClassName "edu_washington_npl_driver_PCICAMACFMDriver_10_4"
#else
#define kPCICAMACServiceClassName "edu_washington_npl_driver_PCICAMACFMDriver"
#endif

// PCI definitions
#define PCI_VENDOR_ID_ARW_CAMAC			0x10b5
#define PCI_DEVICE_ID_ARW_CAMAC			0x2258
#define PCI_SUB_VENDOR_ID_ARW_CAMAC		0x9050
#define PCI_SUB_DEVICE_ID_ARW_CAMAC		0x2258
