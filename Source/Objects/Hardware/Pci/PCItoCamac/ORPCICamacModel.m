/*
 
 File:		ORPCICamacModel.cpp
 
 Usage:		Implementation for the ARW PCI-CAMAC
 I/O Kit Kernel Extension (KEXT) Functions
 
 Author:		F. McGirt
 
 Copyright:		Copyright 2003 F. McGirt.  All rights reserved.
 
 Change History:	1/20/03
 07/29/03 MAH CENPA. Converted to Obj-C for the ORCA project.
 
 
 Notes:		617 PCI Matching is done with
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
 ORPCICamacModelTest object.)  This may possibly
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

#import "ORPCICamacModel.h"
#import "ORCC32Model.h"
#import <AvailabilityMacros.h>

// static variables
static uint32_t *fVLCReg;
static uint32_t *fVPCICamacMem;

#define OExceptionCamacPowerError    @"OExceptionCamacPowerError"
#define OExceptionCamacAccessError   @"OExceptionCamacAccessError"

#define OExceptionCamacPowerErrorDescription    @"No Camac Crate Power"
#define OExceptionCamacAccessErrorDesciption 	@"Camac Access Error"

#define kCamacDriverPath @"/System/Library/Extensions/PCICAMACFMDriver.kext"

#pragma mark ¥¥¥Private Methods
@interface ORPCICamacModel (O620Private)

- (BOOL) _findDevice;

- (kern_return_t) _openUserClient:(io_service_t) serviceObject
                     withDataPort:(io_connect_t) dataPort;
- (kern_return_t) _closeUserClient:(io_connect_t) dataPort;


@end
//-------------------------------------------------------------------------

@implementation ORPCICamacModel

// constructor
- (id) init
{
    self = [super init];
    // initialize values for kext
    masterPort = 0;
    camacMatch = 0;
    iter = 0;
    camacDevice = 0;
    theHWLock       = [[NSRecursiveLock alloc] init];
    theStatusLock   = [[NSLock alloc] init];
    thePowerLock    = [[NSRecursiveLock alloc] init];
    theLCLock       = [[NSLock alloc] init];
	hardwareExists = NO;
    return self;
}



// destructor
-(void) dealloc
{
    [theHWLock release];
    [theStatusLock release];
    [thePowerLock release];
    [theLCLock release];
    [noHardwareAlarm clearAlarm];
    [noHardwareAlarm release];
    [noDriverAlarm clearAlarm];
    [noDriverAlarm release];
    noHardwareAlarm = nil;
    [super dealloc];
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"PCICamacCard"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];    
    if(!hardwareExists){
        NSBezierPath* path = [NSBezierPath bezierPath];
        [path moveToPoint:NSZeroPoint];
        [path lineToPoint:NSMakePoint([self frame].size.width,[self frame].size.height)];
        [path moveToPoint:NSMakePoint([self frame].size.width,0)];
        [path lineToPoint:NSMakePoint(0,[self frame].size.height)];
        [path setLineWidth:.5];
        [[NSColor redColor] set];
        [path stroke];
    }
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
}


- (void) makeMainController
{
    [self linkToController:@"ORPCICamacController"];
}

- (NSString*) helpURL
{
	return @"Mac_Pci/CAMAC_PCI.html";
}

- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the YES owner later.
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self];
    [self setConnector: aConnector];
    [aConnector setOffColor:[NSColor blueColor]];
    [aConnector setConnectorType:'CamA'];
    [aConnector release];
}

- (void)wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    
    if( !hardwareExists){
        if([self _findDevice]){
            hardwareExists  = YES;
            driverExists    = YES;
            NSLog(@"PCI-Camac Driver found.\n");
            NSLog(@"PCI Hardware found.\n");
            NSLog(@"Bridge Client Created\n");
        }
        else {
            if(!driverExists){
				NSLogColor([NSColor redColor],@"*** Unable To Locate Camac Driver ***\n");
                if(!noDriverAlarm){
                    noDriverAlarm = [[ORAlarm alloc] initWithName:@"No Camac Driver Found" severity:kHardwareAlarm];
                    [noDriverAlarm setSticky:NO];
                    [noDriverAlarm setHelpStringFromFile:@"NoCamacDriverHelp"];
                }                      
                [noDriverAlarm setAcknowledged:NO];
                [noDriverAlarm postAlarm];
            }
            if(!hardwareExists){
                NSLogColor([NSColor redColor],@"*** Unable To Locate PCI-Camac Device ***\n");
                if(!noHardwareAlarm){
                    noHardwareAlarm = [[ORAlarm alloc] initWithName:@"No Physical PCI-Camac Found" severity:kHardwareAlarm];
                    [noHardwareAlarm setSticky:YES];
                    [noHardwareAlarm setHelpStringFromFile:@"NoCamacHardwareHelp"];
                }                      
                [noHardwareAlarm setAcknowledged:NO];
                [noHardwareAlarm postAlarm];
            }
        }
    }
	[self setUpImage];
}

- (void) sleep
{
    [super sleep];
    [noHardwareAlarm clearAlarm];
    [noHardwareAlarm release];
    noHardwareAlarm = nil;
	[noDriverAlarm clearAlarm];
    [noDriverAlarm release];
    noDriverAlarm = nil;
	
    // unmap pciadr address spaces
    IOConnectUnmapMemory(dataPort, 0, mach_task_self(), mapLCRegisterAddress);
    IOConnectUnmapMemory(dataPort, 3, mach_task_self(), mapPCICamacMemoryAddress);
    
    // release user client resources
    // call close method in user client - but currently appears to do nothing
    [self _closeUserClient:dataPort];
    
    // close connection to user client and release service
    // connection handle (io_connect_t object)
    // calls clientClose() in user client
    IOServiceClose(dataPort);
    dataPort = 0;
    
    // release device (io_service_t object)
    if( camacDevice ) {
        IOObjectRelease(camacDevice);
        camacDevice = 0;
    }
    
    // release iterator (io_iterator_t object)
    if( iter ) {
        IOObjectRelease(iter);
        iter = 0;
    }
    
    // release class match (dictionary reference)
    if( camacMatch ) {
        CFRelease(camacMatch);
        camacMatch = 0;
    }
    
    // release master port to IOKit
    if( masterPort ) {
        mach_port_deallocate(mach_task_self(), masterPort);
        masterPort = 0;
    }
}

// call Open method in user client
- (kern_return_t)  _openUserClient:(io_service_t) serviceObject port:(io_connect_t) aDataPort
{
	kern_return_t kernResult;
	
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
	//for 10.4
	kernResult =  IOConnectMethodScalarIScalarO( aDataPort,		// service
												kPCICAMACUserClientOpen,	// method index
												0,			// number of scalar input values
												0			// number of scalar output values
												);
#else
	//for 10.5
	kernResult = IOConnectCallScalarMethod(aDataPort,		// connection
										   kPCICAMACUserClientOpen,	// selector
										   0,			// input values
										   0,			// number of scalar input values														
										   0,			// output values
										   0			// number of scalar output values
										   );
#endif
	return kernResult;
}


// call Close method in user client - but currently appears to do nothing
- (kern_return_t)  _closeUserClient:(io_connect_t) aDataPort
{
	kern_return_t kernResult;
	
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
	//10.4
	kernResult =  IOConnectMethodScalarIScalarO( aDataPort,		// service
												kPCICAMACUserClientClose,	// method index
												0,			// number of scalar input values
												0			// number of scalar output values
												);
#else
	//10.5
	kernResult =  IOConnectCallScalarMethod( aDataPort,		// connection
											kPCICAMACUserClientClose,	// selector
											0,			// input values
											0,			// number of scalar input values														
											0,			// output values
											0			// number of scalar output values
											);
#endif
	return kernResult;
}


// locate PCI device in the registry and open user client in driver
- (BOOL)  _findDevice
{
	
    //first make sure the driver is installed.
    //NSFileManager* fm = [NSFileManager defaultManager];
    //if(![fm fileExistsAtPath:kCamacDriverPath]){
    //    driverExists = NO;
    //    return NO;
    //}
    //else driverExists = YES;
	driverExists = YES;
	
    // create Master Mach Port which is used to initiate
    // communication with IOKit
    kern_return_t ret = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if( ret != KERN_SUCCESS ) return NO;
    
    // create a property list dictionary for matching driver class,
    // input string is used as the value for the IOProviderClass object
    camacMatch = IOServiceMatching(kPCICAMACServiceClassName);
    if( camacMatch == NULL ) return NO;
    
    // create iterator of all instances of the driver class that exist
    // in the IORegistry - note that IOServiceGetMatchingServices is
    // documented as consuming a reference on the matching dictionary
    // so it is not necessary to release it here - very odd!!!!
    ret = IOServiceGetMatchingServices(masterPort, camacMatch, &iter);
    if( ret != KERN_SUCCESS ) return NO;
    
    camacMatch = 0;		// finish dictionary handoff
    
    // iterate over all matching drivers in the registry to find a device
    // match - could just take the first device matched but should probably
    // check if more than one device was created since that is an error
    while( (device = IOIteratorNext(iter)) ) {
        if( camacDevice ) {	// already have a device??
            return NO;	// not good!!
        }
        camacDevice = device;
    }
    IOObjectRelease(iter);	// release iterator since no longer needed
    iter = 0;
    if( !camacDevice ) return NO;
    
    // create an instance of the user client object
    dataService = camacDevice;
    ret = IOServiceOpen(dataService, mach_task_self(), 0,
                        &dataPort);
    if( ret != KERN_SUCCESS ) return NO;
    
    // now have a connection to the user client in the driver
    // call Open method in user client
    ret = [self _openUserClient:dataService port:dataPort];
    IOObjectRelease(dataService);	// release service since no longer needed
    dataService = 0;
    if( ret != KERN_SUCCESS ) return NO;
    
    // now can call methods to communicate with user client and rest of driver
    // call clientMemoryFortype() in driver user client to map PCIADA address spaces
    // map PCIADA LC register address space

    ret = IOConnectMapMemory(dataPort,
                             0,
                             mach_task_self(),
                             &mapLCRegisterAddress,
                             &mapLCRegisterLength,
                             kIOMapAnywhere);
    if( ret != KERN_SUCCESS ) return NO;
    
    fVLCReg = (uint32_t *)mapLCRegisterAddress;
    
    
    // map PCICamac memory address space
    ret = IOConnectMapMemory(dataPort,
                             3,
                             mach_task_self(),
                             &mapPCICamacMemoryAddress,
                             &mapPCICamacMemoryLength,
                             kIOMapAnywhere);
    if( ret != KERN_SUCCESS ) return NO;
    
    fVPCICamacMem = (uint32_t *)mapPCICamacMemoryAddress;
    
    return YES;
}



// read PCI Configuration Register
- (kern_return_t)  readPCIConfigRegister:(unsigned int) address data:(unsigned int*)data
{
	kern_return_t kernResult;
	
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4	
	//10.4
	kernResult = IOConnectMethodScalarIScalarO(
											   dataPort,		// service
											   kPCICAMACReadPCIConfig,	// method index
											   1,			// number of scalar input values
											   1,			// number of scalar output values
											   address,		// scalar input value
											   data		// scalar output value
											   );
	
#else
	//10.5
	uint64_t input = address;
	uint64_t output_64;
	uint32_t outputCount = 1;
	
	kernResult = IOConnectCallScalarMethod(dataPort,					// connection
										   kPCICAMACReadPCIConfig,	// selector
										   &input,					// input values
										   1,							// number of scalar input values														
										   &output_64,					// output values
										   &outputCount				// number of scalar output values
										   );
	*data = (uint32_t) output_64;
#endif
	
	return kernResult;
}


// get PCI Configuration Data
- (kern_return_t)  getPCIConfigurationData:(unsigned int) maxAddress data:(PCIConfigStruct*)pciData
{
    size_t pciDataSize = sizeof(PCIConfigStruct);
	kern_return_t kernResult;
	
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
	//10.4
	kernResult = IOConnectMethodScalarIStructureO(  dataPort,		// service
												  kPCICAMACGetPCIConfig,	// method index
												  1,			// number of scalar input values
												  &pciDataSize,		// byte size of output structure
												  maxAddress,		// scalar input values
												  pciData			// output structure
												  );
#else
	//10.5
	uint64_t scalarI = maxAddress;
	kernResult = IOConnectCallMethod(  dataPort,					// connection
									 kPCICAMACGetPCIConfig,		// selector
									 &scalarI,					// input values
									 1,							// number of scalar input values
									 NULL,						// Pointer to input struct
									 0,							// Size of input struct
									 NULL,						// output scalar array
									 NULL,						// pointer to number of scalar output
									 pciData,						// pointer to struct output
									 &pciDataSize					// pointer to size of struct output
									 );
	
#endif
	return kernResult;
}


// write PCIADA LC Register
- (void)  writeLCRegister:(unsigned short)regOffSet data:(unsigned short) data
{
    if(hardwareExists){
        [theLCLock lock]; //----begin critical section
		// check if offset valid
        if((regOffSet != kLCRIntCSROffset) && (regOffSet != kLCDControlOffset)) {
            [theLCLock unlock]; //----end critical section early because of exception
            [NSException raise: OExceptionBadCamacStatus format:OExceptionBadLCRArguments];
        }
        
        volatile uint16_t *address = (uint16_t *)&fVLCReg[regOffSet];
        *address = Swap8BitsIn16(data);
        [theLCLock unlock]; //----end critical section
    }
}


// read PCIADA LC Register
- (unsigned short)  readLCRegister: (unsigned short) regOffSet
{
    if(hardwareExists){
        [theLCLock lock]; //----begin critical section
		// check if offset is out of range
        if((regOffSet!=kLCRIntCSROffset) && ( regOffSet!=kLCDControlOffset)) {
            [theLCLock unlock]; //----end critical section early because of exception
            [NSException raise: OExceptionBadCamacStatus format:OExceptionBadLCRArguments];
        }
        
        volatile uint16_t *address = (uint16_t *)&fVLCReg[regOffSet];
        unsigned short temp = Swap8BitsIn16(*address);
        [theLCLock unlock]; //----end critical section
        return temp;
    }
    else return 0;    
}


- (uint32_t)  readLEDs
{
    if(hardwareExists){
        [theHWLock lock];   //----begin critical section
		uint32_t lnafOffset = (uint32_t)(offsetNAF(29,0,0) / 4);	// note divide by 4
		volatile uint32_t *lPCICamacMemBase = (uint32_t *)&fVPCICamacMem[lnafOffset];
		
		uint32_t led = Swap8Bits(*lPCICamacMemBase);
        [theHWLock unlock];   //----end critical section
		return led;
	}
	else return 0;
}

// get PCICamac status
- (unsigned short) camacStatus
{
    if(hardwareExists){
        // read status - (n = 0, a = 0, f = 0) => offset = 0
        [theStatusLock lock];   //----begin critical section
        volatile uint16_t *wPCICamacMemBase = (uint16_t *)&fVPCICamacMem[0];
        unsigned short theStatus = Swap8BitsIn16(*wPCICamacMemBase);
        [theStatusLock unlock];//----end critical section
        return theStatus;
    }
    else return 0;
}

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f
{
	unsigned short dummy;
	return [self camacShortNAF:n a:a f:f data:&dummy];
}

- (void) lock
{
    [theHWLock lock];   //----begin crital section
}

- (void) unlock
{
    [theHWLock unlock];   //----end crital section
}

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f
							 data:(unsigned short*) data
{
    unsigned short theStatus = 0;
    if(hardwareExists){
        @try {
            [theHWLock lock];   //----begin crital section
            
            // read dataway
            uint16_t wnafOffset = (uint16_t)(offsetNAF(n,a,f) / 4);	 // note divide by 4
            volatile uint16_t *wPCICamacMemBase = (uint16_t *)&fVPCICamacMem[wnafOffset];
            
            //The PCI-CAMAC hardware forces all NAF command writes to set
            //the F16 bit to a 1 and all NAF command reads to set the F16
            //bit to 0.  Therefore all F values from F0 through F15 MUST
            //be used with CAMAC bus read accesses and all F values from
            //F16 through F31 MUST be used with CAMAC bus write accesses.
			if(f < 16){
			// Read access
                if(data){
                    unsigned short temp = *wPCICamacMemBase;
                    *data = Swap8BitsIn16(temp);
                }
            }
            else {
				// Write access
				if(data)*wPCICamacMemBase = Swap8BitsIn16(*data);
				else *wPCICamacMemBase = 0;
			}
            // get status
			volatile uint16_t* statusValue = (uint16_t *)&fVPCICamacMem[0];
			theStatus = Swap8BitsIn16(*statusValue);
			[self checkStatusReturn:theStatus station:n];
            [theHWLock unlock];     //----end crital section
			
        }
		@catch(NSException* localException) {
            [theHWLock unlock]; //----end crital section because of exception
            [localException raise];
        }
    }
    return theStatus;
    
}

- (unsigned short)  camacLongNAF:(unsigned short)n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
{
	uint32_t dummy = 0;
	return [self camacLongNAF:n a:a f:f data:&dummy];
}

// write block of words to dataway
- (unsigned short) camacShortNAFBlock:(unsigned short)n 
									a:(unsigned short)a 
									f:(unsigned short)f
								 data:(unsigned short*) data 
							   length:(uint32_t) numWords;
{
    unsigned short theStatus = 0;
    if(hardwareExists && data!=nil){
        @try {
            [theHWLock lock];   //----begin crital section
            
            // write dataway
            uint16_t wnafOffset = (uint16_t)(offsetNAF(n,a,f) / 4);	 // note divide by 4
            volatile uint16_t *wCC32MemBase = (uint16_t *)&fVPCICamacMem[wnafOffset];
            unsigned short *ptrData = data;
            uint32_t ptrOffset;
            
            //The PCI-CAMAC hardware forces all NAF command writes to set
            //the F16 bit to a 1 and all NAF command reads to set the F16
            //bit to 0.  Therefore all F values from F0 through F15 MUST
            //be used with CAMAC bus read accesses and all F values from
            //F16 through F31 MUST be used with CAMAC bus write accesses.
            
			if(f < 16){
                for( ptrOffset = 0;ptrOffset < numWords; ptrOffset++ ) {
                    *ptrData++ = Swap8BitsIn16(*wCC32MemBase);
                }
            }
            else {
                for(ptrOffset = 0; ptrOffset < numWords; ptrOffset++ ) {
                    *wCC32MemBase = Swap8BitsIn16(*ptrData);
                    ptrData++;
                }
            }
			volatile uint16_t* statusValue = (uint16_t *)&fVPCICamacMem[0];
			theStatus = Swap8BitsIn16(*statusValue);
			[self checkStatusReturn:theStatus station:n];
			[theHWLock unlock];   //----end crital section
        }
		@catch(NSException* localException) {
            [theHWLock unlock]; //----end crital section because of exception
            [localException raise];
        }
    }
    return theStatus;
}

- (unsigned short)  camacLongNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(uint32_t*) data
{
    unsigned short theStatus = 0;
    if(hardwareExists){
        @try {
            [theHWLock lock];   //---begin critical section
            // read dataway
            uint32_t lnafOffset = (uint32_t)(offsetNAF(n,a,f) / 4);	 // note divide by 4
            volatile uint32_t *wPCICamacMemBase = (uint32_t *)&fVPCICamacMem[lnafOffset];
            
            //The PCI-CAMAC hardware forces all NAF command writes to set
            //the F16 bit to a 1 and all NAF command reads to set the F16
            //bit to 0.  Therefore all F values from F0 through F15 MUST
            //be used with CAMAC bus read accesses and all F values from
            //F16 through F31 MUST be used with CAMAC bus write accesses.
			if(f < 16){
                uint32_t temp = *wPCICamacMemBase;
                if(data)*data = Swap8Bits(temp);
            }
            else     *wPCICamacMemBase = Swap8Bits(*data);
			
			volatile uint16_t* statusValue = (uint16_t *)&fVPCICamacMem[0];
			theStatus = Swap8BitsIn16(*statusValue);
			[self checkStatusReturn:theStatus station:n];
			
            [theHWLock unlock]; //---end critical section
        }
		@catch(NSException* localException) {
            [theHWLock unlock]; //---end critical section because of exception
            [localException raise];
        }
    }
    // get status
    return  theStatus;
}

// write block of longs to dataway
- (unsigned short) camacLongNAFBlock:(unsigned short)n 
								   a:(unsigned short)a 
								   f:(unsigned short)f
								data:(uint32_t*) data 
							  length:(uint32_t) numWords
{
    unsigned short theStatus = 0;
    if(hardwareExists && data!=nil){
        @try {
            [theHWLock lock];   //----begin crital section
            
            // write dataway
            uint32_t wnafOffset = (uint32_t)(offsetNAF(n,a,f) / 4);	 // note divide by 4
            volatile uint32_t *wCC32MemBase = (uint32_t *)&fVPCICamacMem[wnafOffset];
            uint32_t *ptrData = (uint32_t *)data;
            uint32_t ptrOffset;
            
            //The PCI-CAMAC hardware forces all NAF command writes to set
            //the F16 bit to a 1 and all NAF command reads to set the F16
            //bit to 0.  Therefore all F values from F0 through F15 MUST
            //be used with CAMAC bus read accesses and all F values from
            //F16 through F31 MUST be used with CAMAC bus write accesses.
            
			if(f < 16){
                for( ptrOffset = 0;ptrOffset < numWords; ptrOffset++ ) {
                    *ptrData++ = Swap8BitsIn16(*wCC32MemBase);
                }
            }
            else {
                for(ptrOffset = 0; ptrOffset < numWords; ptrOffset++ ) {
                    *wCC32MemBase = Swap8BitsIn16(*ptrData);
                    ptrData++;
                }
            }
			volatile uint16_t* statusValue = (uint16_t *)&fVPCICamacMem[0];
			theStatus = Swap8BitsIn16(*statusValue);
			[self checkStatusReturn:theStatus station:n];
			[theHWLock unlock];   //----end crital section
        }
		@catch(NSException* localException) {
            [theHWLock unlock]; //----end crital section because of exception
            [localException raise];
        }
    }
    return theStatus;
}


- (void) checkStatusReturn:(unsigned short)theStatus station:(unsigned short) n
{
	if(!isXbitSet(theStatus)){
		NSLogError(@"CAMAC Exception", [NSString stringWithFormat:@"Station %d",n],@"Bad X Response",nil);
		[NSException raise: @"CAMAC Exception" format:@"CAMAC Exception (station %d)",n];
	}
}

// return system assigned PCI bus number
- (kern_return_t)  getPCIBusNumber:(unsigned char*) data
{
    kern_return_t result = 0;
    [theHWLock lock];   //-----begin critical section
    if(hardwareExists){
		
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
		//10.4
		result =  IOConnectMethodScalarIScalarO(dataPort,		// service
												kPCICAMACGetPCIBusNumber,	// method index
												0,			// number of scalar input values
												1,			// number of scalar output values
												data		// scalar output value
												);
#else 
		//10.5
		uint64_t output_64;
		uint32_t outputCount = 1;
		result = IOConnectCallScalarMethod(dataPort,					// connection
										   kPCICAMACGetPCIBusNumber,	// selector
										   NULL,					// input values
										   0,							// number of scalar input values														
										   &output_64,					// output values
										   &outputCount				// number of scalar output values
										   );
		*data = (char) output_64;
#endif
	}
    [theHWLock unlock];   //-----end critical section
    return result;
}


// return system assigned PCI device number
- (kern_return_t)  getPCIDeviceNumber:(unsigned char*) data
{
    kern_return_t result=0;
    [theHWLock lock];   //-----begin critical section
    if(hardwareExists){
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
		//10.4
		result =   IOConnectMethodScalarIScalarO(dataPort,		// service
												 kPCICAMACGetPCIDeviceNumber,	// method index
												 0,			// number of scalar input values
												 1,			// number of scalar output values
												 data		// scalar output value
												 );
#else 
		//10.5
		uint64_t output_64;
		uint32_t outputCount = 1;
		result = IOConnectCallScalarMethod(dataPort,					// connection
										   kPCICAMACGetPCIDeviceNumber,	// selector
										   NULL,						// input values
										   0,							// number of scalar input values														
										   &output_64,					// output values
										   &outputCount					// number of scalar output values
										   );
		*data = (char) output_64;
#endif
    }
    [theHWLock unlock];   //-----end critical section
    return result;
}


// return system assigned PCI function number
- (kern_return_t)  getPCIFunctionNumber:(unsigned char*) data
{
    kern_return_t result = 0;
    [theHWLock lock];   //-----begin critical section
    if(hardwareExists){
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
		//10.4
		result =  IOConnectMethodScalarIScalarO(dataPort,		// service
												kPCICAMACGetPCIFunctionNumber,	// method index
												0,			// number of scalar input values
												1,			// number of scalar output values
												data		// scalar output value
												);
#else
		//10.5
		uint64_t output_64;
		uint32_t outputCount = 1;
		result = IOConnectCallScalarMethod(dataPort,					// connection
										   kPCICAMACGetPCIFunctionNumber,	// selector
										   NULL,						// input values
										   0,							// number of scalar input values														
										   &output_64,					// output values
										   &outputCount					// number of scalar output values
										   );
		*data = (char) output_64;
#endif
    }
    [theHWLock unlock];   //-----end critical section
    return result;
}


- (void) delay:(float)delayValue
{
    [NSThread sleepUntilDate:[[NSDate date] dateByAddingTimeInterval:delayValue]];
}

// check status errors.
- (void) checkStatusErrors
{    
    [theHWLock lock];   //----begin critical section
    volatile uint16_t *address = (uint16_t *)&fVLCReg[kLCRIntCSROffset];
    unsigned short statusLCRI = Swap8BitsIn16(*address);
    if( ( statusLCRI & kInitialControlStatus ) != kInitialControlStatus ) {
        [theHWLock unlock];//----end critical section early because of exception
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CamacBadStatusNotification" object:self];
        [NSException raise: OExceptionBadCamacStatus format:OExceptionBadCamacStatus];
    }
    [theHWLock unlock]; //----end critical section
}

- (BOOL) powerOK
{
	return powerOK;
}

// check crate power & cable.
- (void)  checkCratePower
{
    [thePowerLock lock];   //----begin critical section
	//unsigned short statusLCRC = [self readLCRegister:kLCDControlOffset];
    unsigned short statusLCRC = 0;
    if(hardwareExists){
        volatile uint16_t *address = (uint16_t *)&fVLCReg[kLCDControlOffset];
        statusLCRC = Swap8BitsIn16(*address);
    }
    if( ( statusLCRC & kPowerControlStatus ) != kPowerControlStatus ) {
        [self  writeLCRegister:kLCRCntrlOffset data:kEnableCC32];
    	[self  writeLCRegister:kLCRIntCSROffset data:kDisableAllInterrupts];
		
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CamacPowerFailedNotification" object:self];
        powerOK = NO;
		
        [thePowerLock unlock];//----end critical section early because of exception
		[NSException raise: OExceptionNoCamacCratePower format:OExceptionNoCamacCratePower];
    }
    else {
		if(!powerOK){
			powerOK = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"CamacPowerRestoredNotification" object:self];
		}
    }
    [thePowerLock unlock]; //----end critical section
    
    
}

- (void) printConfigurationData
{
    unsigned int maxAddress = 0x3f;
    PCIConfigStruct pciData;
    kern_return_t ret = [self getPCIConfigurationData:maxAddress data:&pciData];
    if( ret != KERN_SUCCESS ) {
        NSLog(@"PCICamac get PCI config Cmd FAILED\n");
    }
    else {
        NSLog(@"Specific Configuration Values Follow:\n");
        unsigned short vendorID = (unsigned short)pciData.int32[0];
        NSLog(@"PCI Configuration - Vendor ID: 0x%04x\n", vendorID);
        unsigned short deviceID = (unsigned short)Swap16Bits(pciData.int32[0]);
        NSLog(@"PCI Configuration - Device ID: 0x%04x\n",deviceID);
        NSLog(@"PCI Configuration - Base Address 0: 0x%08x\n",
              (unsigned int)pciData.int32[kIOPCIConfigBaseAddress0/4]);
        NSLog(@"PCI Configuration - Base Address 1: 0x%08x\n",
              (unsigned int)pciData.int32[kIOPCIConfigBaseAddress1/4]);
        NSLog(@"PCI Configuration - Base Address 2: 0x%08x\n",
              (unsigned int)pciData.int32[kIOPCIConfigBaseAddress2/4]);
        NSLog(@"PCI Configuration - Base Address 3: 0x%08x\n",
              (unsigned int)pciData.int32[kIOPCIConfigBaseAddress3/4]);
        NSLog(@"PCI Configuration - Interrupt Line: 0x%02x\n",
              (unsigned char)pciData.int32[kIOPCIConfigInterruptLine/4]);
        NSLog(@"PCI Configuration - Interrupt Pin: 0x%02x\n",
              (unsigned char)( pciData.int32[kIOPCIConfigInterruptLine/4] >> 8 ));
        
        
        // make sure have a PCICamac card by checking Vendor & Device IDs
        if( vendorID != PCI_VENDOR_ID_ARW_CAMAC ) {
            NSLog(@"*** Invalid Vendor ID, Got: 0x%04x, Expected: 0x%04x ***\n",
                  vendorID,PCI_DEVICE_ID_ARW_CAMAC);
            return;
        }
        if( deviceID != PCI_DEVICE_ID_ARW_CAMAC ) {
            NSLog(@"*** Invalid Device ID, Got: 0x%04x, Expected: 0x%04x ***\n",
                  deviceID,PCI_DEVICE_ID_ARW_CAMAC);
            return;
        }
        
        // get PCI assigned values
        NSLog(@"Getting PCI Assigned Values:\n");
        unsigned char cdata=0;
        ret = [self getPCIBusNumber:&cdata];
        if( ret != KERN_SUCCESS ) {
            NSLog(@"*** kPCICAMACGetPCIBusNumber Cmd FAILED ***\n");
        }
        else {
            NSLog(@"PCI Assigned Bus Number: 0x%02x\n",cdata);
        }
        ret = [self getPCIDeviceNumber:&cdata];
        if( ret != KERN_SUCCESS ) {
            NSLog(@"*** kPCICAMACGetPCIDeviceNumber Cmd FAILED ***\n");
        }
        else {
            NSLog(@"PCI Assigned Device Number: 0x%02x\n",cdata);
        }
        ret = [self getPCIFunctionNumber:&cdata];
        if( ret != KERN_SUCCESS ) {
            NSLog(@"*** kPCICAMACGetPCIFunctionNumber Cmd FAILED ***\n");
        }
        else {
            NSLog(@"PCI Assigned Function Number: 0x%02x\n",cdata);
        }
    }
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    theHWLock       = [[NSRecursiveLock alloc] init];
    theStatusLock   = [[NSLock alloc] init];
    thePowerLock    = [[NSRecursiveLock alloc] init];
    theLCLock       = [[NSLock alloc] init];
    
    [[self undoManager] disableUndoRegistration];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
}

@end
