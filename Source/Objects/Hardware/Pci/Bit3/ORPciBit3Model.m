/*
 
 File:		CVmeContrl620.cpp
 
 Usage:		Implementation for the Bit3 620 PCI VME
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
 
 5/21/02 - IOServiceClose() added in destructor to match
 IOServiceOpen()
 
 5/22/02 - Open/Close calls to User Client methods added
 5/29/02 - direct mapping of 620 address spaces from user
 space added, single transfers up to 64768 32 bit
 items allowed
 6/5/02 - added comments and some cleanup
 8/7/02 - additional cleanup
 11/20/02 - added error returns to selected functions
 11/20/02 - MAH CENPA. converted to Obj-C 
 11/03/04  - MAH CENPA. converted to generic Bit3 Model
 
 
 Notes:		620 PCI Matching is done with
 Vendor ID 0x108a and Device IDs of the Bit3 devices.
 
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
 -------------------------------------------------------------
 
 
 */


#pragma mark ¥¥¥Imported Files
#import "ORPciBit3Model.h"
#import "ORRateGroup.h"
#import "ORAxis.h"
#import "ORPciBit3Commands.h"
#import "ORCommandList.h"
#import "ORVmeReadWriteCommand.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORPciBit3ModelRangeChanged						= @"ORPciBit3ModelRangeChanged";
NSString* ORPciBit3ModelDoRangeChanged						= @"ORPciBit3ModelDoRangeChanged";
NSString* ORPciBit3DualPortAddresChangedNotification        = @"ORPciBit3DualPortAddresChangedNotification";
NSString* ORPciBit3DualPortRamSizeChangedNotification       = @"ORPciBit3DualPortRamSizeChangedNotification";
NSString* ORPciBit3RWAddressChangedNotification             = @"ORPciBit3RWAddressChangedNotification";
NSString* ORPciBit3WriteValueChangedNotification            = @"ORPciBit3WriteValueChangedNotification";
NSString* ORPciBit3RWAddressModifierChangedNotification     = @"ORPciBit3RWAddressModifierChangedNotification";
NSString* ORPciBit3RWIOSpaceChangedNotification             = @"ORPciBit3RWIOSpaceChangedNotification";
NSString* ORPciBit3RWTypeChangedNotification                = @"ORPciBit3RWTypeChangedNotification";
NSString* ORPciBit3RateGroupChangedNotification             = @"ORPciBit3RateGroupChangedNotification";
NSString* ORPciBit3ErrorRateXChangedNotification            = @"ORPciBit3ErrorRateXChangedNotification";
NSString* ORPciBit3ErrorRateYChangedNotification			= @"ORPciBit3ErrorRateYChangedNotification";
NSString* ORPciBit3DeviceNameChangedNotification            = @"ORPciBit3DeviceNameChangedNotification";

NSString* ORPciBit3Lock										= @"ORPciBit3Lock";

#pragma mark ¥¥¥Macros
// swap 16 bit quantities in 32 bit value ( |2| |1| -> |1| |2| )
#define Swap16Bits(x)    ((((x) & 0xffff0000) >> 16) | (((x) & 0x0000ffff) << 16))

// swap 8 bit quantities in 32 bit value ( |4| |3| |2| |1| -> |1| |2| |3| |4| )
#define Swap8Bits(x)	(((x) & 0x000000FF) << 24) |	\
(((x) & 0x0000FF00) <<  8) |	\
(((x) & 0x00FF0000) >>  8) |	\
(((x) & 0xFF000000) >> 24)


#pragma mark ¥¥¥Definitions
#define kNumPciDevices 3

struct {
    NSString* deviceName;
    unsigned short deviceID;
}pciDevices[kNumPciDevices]={
{@"617",            0x0001},
{@"618/620/622",    0x0010},
{@"810",            0x0040}
};

#pragma mark ¥¥¥Private Methods
@interface ORPciBit3Model (ORPciBit3Private)

- (BOOL) _findDevice;
- (void) _resetNoRaise;

- (kern_return_t) _openUserClient:(io_service_t) serviceObject
                     withDataPort:(io_connect_t) dataPort;
- (kern_return_t) _closeUserClient:(io_connect_t) dataPort;

- (void) _setupMapping: (uint32_t)remoteAddress
              numBytes: (uint32_t)numberBytes
                addMod: (uint16_t)addModifier
              addSpace: (uint16_t)addressSpace;

- (void) _setupMapping_Byte: (uint32_t)remoteAddress
                   numBytes: (uint32_t)numberBytes
                     addMod: (uint16_t)addModifier
                   addSpace: (uint16_t)addressSpace;

@end
//-------------------------------------------------------------------------


@implementation ORPciBit3Model

#pragma mark ¥¥¥Inialization

- (id) init
{
    self = [super init];
    
    [self setDualPortAddress:kDualPortAddress];
    [self setDualPortRamSize:kDualPortSize];
    [self setErrorRateGroup:[[[ORRateGroup alloc] initGroup:3 groupTag:0] autorelease]];
    [errorRateGroup setIntegrationTime:5];
    
    
    masterPort 	 = 0;
    bit3Device = 0;
    
    theHWLock = [[NSLock alloc] init];    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [errorRateGroup quit];
    [errorRateGroup release];
    [theHWLock release];
    [noHardwareAlarm clearAlarm];
    [noHardwareAlarm release];
    [noDriverAlarm clearAlarm];
    [noDriverAlarm release];
    [deviceName release];
    [super dealloc];
}


- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the real owner later.
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self];
    [self setConnector: aConnector];
    [aConnector setOffColor:[NSColor orangeColor]];
    [aConnector setConnectorType:'VMEA'];
    [aConnector release];
}

- (void) setUpImage
{
    [self loadImage:@"PciBit3Card"];
}

- (NSString*) helpURL
{
	return @"Mac_Pci/Bit_3.html";
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    if( !hardwareExists){
        if([self _findDevice]){
            hardwareExists = YES;
            driverExists    = YES;
            NSLog(@"%@ Driver found.\n",[self driverPath]);
            NSLog(@"PCI Hardware found.\n");
            NSLog(@"Bridge Client Created\n");
        }
        else {
            if(!driverExists){
                NSLogColor([NSColor redColor],@"*** Unable To Locate %@ ***\n",[self driverPath]);
                if(!noDriverAlarm){
                    noDriverAlarm = [[ORAlarm alloc] initWithName:@"No SBS-Bit3 Driver Found" severity:0];
                    [noDriverAlarm setSticky:NO];
                    [noDriverAlarm setHelpStringFromFile:@"NoBit3DriverHelp"];
                }                      
                [noDriverAlarm setAcknowledged:NO];
                [noDriverAlarm postAlarm];
            }
            if(!hardwareExists){
                
                [self setDeviceName:@"Bit3"];
                NSLogColor([NSColor redColor],@"*** Unable To Locate SBS-Bit3 Device ***\n");
                if(!noHardwareAlarm){
                    noHardwareAlarm = [[ORAlarm alloc] initWithName:@"No Physical SBS-Bit3 Found" severity:0];
                    [noHardwareAlarm setHelpStringFromFile:@"NoPciHardwareHelp"];
                    
                    [noHardwareAlarm setSticky:YES];
                }                      
                [noHardwareAlarm setAcknowledged:NO];
                [noHardwareAlarm postAlarm];
            }
        }
    }
    if(hardwareExists) {
        PCIConfigStructUser pciData;
        unsigned  maxAddress = 0x3f;
        [self getPCIConfigurationData:maxAddress withDataPtr:&pciData];
        unsigned short deviceID = (unsigned short)Swap16Bits(pciData.int32[0]);
        
        unsigned char cdata;
        [self getPCIDeviceNumber:&cdata];
        [self setDeviceName: [self decodeDeviceName:deviceID]];
        NSLog(@"%@ device found in slot %d\n",deviceName,cdata-1);
        
        if(cdata-1 != [self slot] && totalDevicesFound == 1){
            NSLog(@"%@ Hardware is in slot %d, but software object being used is in slot %d.\n",deviceName,cdata-1,[self slot]);
            NSLog(@"Since only one device found, this will not be a problem.\n");
        }
        
        @try {
            [self resetContrl];
            NSLog(@"Reset %@ Controller\n",deviceName);
        }
		@catch(NSException* localException) {
            NSLogColor([NSColor redColor],@"*** Unable to send %@ reset ***\n",deviceName);
            NSLogColor([NSColor redColor],@"*** Check VME bus power and/or cables ***\n");
            if(okToShowResetWarning) ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
													 localException);
        }
    }
	[self setUpImage];
}

- (void)sleep
{
    [super sleep];
    
    [noHardwareAlarm clearAlarm];
    [noHardwareAlarm release];
    noHardwareAlarm = nil;
	
    [noDriverAlarm clearAlarm];
    [noDriverAlarm release];
    noDriverAlarm = nil;
	
    
    // unmap Bit3 address spaces
    IOConnectUnmapMemory(dataPort, 1, mach_task_self(), CSRRegisterAddress);
    IOConnectUnmapMemory(dataPort, 2, mach_task_self(), mapRegisterAddress);
    IOConnectUnmapMemory(dataPort, 3, mach_task_self(), remMemRegisterAddress);
    
    // release user client resources
    // call close method in user client - but currently appears to do nothing
    [self _closeUserClient:dataPort];
    
    // close connection to user client and release service
    // connection handle (io_connect_t object)
    // calls clientClose() in user client
    IOServiceClose(dataPort);
    dataPort = 0;
    
    // release device (io_service_t object)
    if( bit3Device ) {
        IOObjectRelease(bit3Device);
        bit3Device = 0;
    }
	
    // release master port to IOKit
    if( masterPort ) {
        mach_port_deallocate(mach_task_self(), masterPort);
        masterPort = 0;
    }
}

- (void) makeMainController
{
    [self linkToController:@"ORPciBit3Controller"];
}

- (unsigned short) vendorID
{
	//should be the same for all SBS PCI boards, but subclasses can override if needed.
	return 0x108a;
}

- (const char*) serviceClassName
{
	//subclasses will have different sevices to match against.
	return "edu_washington_npl_driver_PCIBit3Driver";
}

- (NSString*) driverPath
{
	//subclasses will have different drivers.
	return @"/System/Library/Extensions/PCIBit3Driver.kext";
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(runEnded:)
                         name : ORRunStoppedNotification
                       object : nil];
}

- (void) runEnded:(NSNotification*)aNote
{
    if(guardian!=nil){
        [self printErrorSummary];
        int i;
        for(i=0;i<kNumRetryIndexes;i++){
            retryCount[i]       =   0;
            retryFailedCount[i] =   0;
        }
    }
	timeOutErrors = 0;
	remoteBusErrors = 0;
}

#pragma mark ¥¥¥Accessors
- (unsigned short) rangeToDo
{
    return rangeToDo;
}

- (void) setRangeToDo:(unsigned short)aRange
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRangeToDo:rangeToDo];
    
    rangeToDo = aRange;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPciBit3ModelRangeChanged object:self];
}

- (BOOL) doRange
{
    return doRange;
}

- (void) setDoRange:(BOOL)aDoRange
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoRange:doRange];
    
    doRange = aDoRange;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPciBit3ModelDoRangeChanged object:self];
}

- (NSString *) deviceName
{
    return deviceName; 
}

- (void) setDeviceName: (NSString *) aDeviceName
{
    [deviceName autorelease];
    deviceName = [aDeviceName copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORPciBit3DeviceNameChangedNotification
	 object:self];
    
}

- (uint32_t) rwAddress
{
    return rwAddress;
}

- (void) setRwAddress:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRwAddress:[self rwAddress]];
    rwAddress = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORPciBit3RWAddressChangedNotification
	 object:self];
    
}

- (uint32_t) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    writeValue = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORPciBit3WriteValueChangedNotification
	 object:self];
    
}

- (unsigned int) rwAddressModifier
{
    return rwAddressModifier;
}

- (void) setRwAddressModifier:(unsigned int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRwAddressModifier:[self rwAddressModifier]];
    rwAddressModifier = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORPciBit3RWAddressModifierChangedNotification
	 object:self];
    
}

- (unsigned int) readWriteIOSpace
{
    return readWriteIOSpace;
}

- (void) setReadWriteIOSpace:(unsigned int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setReadWriteIOSpace:[self readWriteIOSpace]];
    readWriteIOSpace = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORPciBit3RWIOSpaceChangedNotification
	 object:self];
    
}

- (unsigned int) readWriteType
{
    return readWriteType;
}

- (void) setReadWriteType:(unsigned int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setReadWriteType:readWriteType];
    readWriteType = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORPciBit3RWTypeChangedNotification
	 object:self];
    
}


- (unsigned short) rwAddressModifierValue
{
    
    static unsigned int addressModTrans[3] = {
        kRemoteIOAddressModifier,
        kRemoteRAMAddressModifier,
        kRemoteDualPortAddressModifier
    };
    if([self rwAddressModifier]<=3)return addressModTrans[rwAddressModifier];
    else return kRemoteIOAddressModifier;
}

- (unsigned short) rwIOSpaceValue
{
    return readWriteIOSpace+1;
}


-(void) setDualPortAddress:(unsigned int) theAddress
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDualPortAddress:dualPortAddress];
    dualPortAddress = theAddress;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORPciBit3DualPortAddresChangedNotification
	 object:self];
}

-(unsigned int) dualPortAddress
{
    return dualPortAddress;
}

-(void) setDualPortRamSize:(unsigned int) theSize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDualPortRamSize:dualPortRamSize];
    dualPortRamSize = theSize;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORPciBit3DualPortRamSizeChangedNotification
	 object:self];
}

-(unsigned int) dualPortRamSize
{
    return dualPortRamSize;
}

- (ORRateGroup*) errorRateGroup
{
	return errorRateGroup;
}
- (void) setErrorRateGroup:(ORRateGroup*)newErrorRateGroup
{
	[newErrorRateGroup retain];
	[errorRateGroup release];
	errorRateGroup = newErrorRateGroup;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORPciBit3RateGroupChangedNotification
	 object:self];    
}

- (void) setIntegrationTime:(double)newIntegrationTime
{
    if(newIntegrationTime<1)newIntegrationTime=1;
    else if(newIntegrationTime>60)newIntegrationTime=60;
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setIntegrationTime:[errorRateGroup integrationTime]];
    [errorRateGroup setIntegrationTime:newIntegrationTime];
}

- (NSDictionary*) errorRateXAttributes
{
	return errorRateXAttributes;
}
- (void) setErrorRateXAttributes:(NSDictionary*)newErrorRateXAttributes
{
    [errorRateXAttributes release];
    errorRateXAttributes = [newErrorRateXAttributes copy];
}

- (NSDictionary*) errorRateYAttributes
{
	return errorRateYAttributes;
}
- (void) setErrorRateYAttributes:(NSDictionary*)newErrorRateYAttributes
{
    [errorRateYAttributes release];
    errorRateYAttributes = [newErrorRateYAttributes copy];
}


#pragma mark ¥¥¥Hardware Access
// return system assigned PCI bus number
- (kern_return_t) getPCIBusNumber:(unsigned char *) data
{
    kern_return_t result = 0;
    [theHWLock lock];   //-----begin critical section
    if(hardwareExists){
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
		//10.4
		result = IOConnectMethodScalarIScalarO(dataPort,		// service
                                               kBit3GetPCIBusNumber,	// method index
                                               0,			// number of scalar input values
                                               1,			// number of scalar output values
                                               data		// scalar output value
                                               );
#else
		//10.5
		uint64_t output_64;
		uint32_t outputCount = 1;
		result = IOConnectCallScalarMethod(dataPort,				// connection
										   kBit3GetPCIBusNumber,	// selector
										   NULL,					// input values
										   0,						// number of scalar input values														
										   &output_64,				// output values
										   &outputCount				// number of scalar output values
										   );
		*data = (char) output_64;
		
#endif
    }
    [theHWLock unlock];   //-----end critical section
    return result;
}


// return system assigned PCI device number
- (kern_return_t) getPCIDeviceNumber:(unsigned char *)data
{
    kern_return_t result = 0;
    [theHWLock lock];   //-----begin critical section
    if(hardwareExists){
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
		//10.4
		result =  IOConnectMethodScalarIScalarO(dataPort,		// service
												kBit3GetPCIDeviceNumber,	// method index
												0,			// number of scalar input values
												1,			// number of scalar output values
												data		// scalar output value
												);
#else
		//10.5
		uint64_t output_64;
		uint32_t outputCount = 1;
		result = IOConnectCallScalarMethod(dataPort,					// connection
										   kBit3GetPCIDeviceNumber,	// selector
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
- (kern_return_t) getPCIFunctionNumber:(unsigned char *)data;
{
    kern_return_t result = 0;
    [theHWLock lock];   //-----begin critical section
    if(hardwareExists){
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
		//10.4
		result =   IOConnectMethodScalarIScalarO(dataPort,		// service
												 kBit3GetPCIFunctionNumber,	// method index
												 0,			// number of scalar input values
												 1,			// number of scalar output values
												 data		// scalar output value
												 );
#else
		//10.5
		uint64_t output_64;
		uint32_t outputCount = 1;
		result = IOConnectCallScalarMethod(dataPort,					// connection
										   kBit3GetPCIFunctionNumber,	// selector
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

// read Bit3 PCI Configuration Register
- (kern_return_t) readPCIConfigRegister:(unsigned int) address
                            withDataPtr:(unsigned int *) data;
{
    kern_return_t result = 0;
    [theHWLock lock];   //-----begin critical section
    if(hardwareExists){
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
		//10.4
		result =  IOConnectMethodScalarIScalarO(dataPort,		// service
												kBit3ReadPCIConfig,	// method index
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
		
		result = IOConnectCallScalarMethod(dataPort,					// connection
										   kBit3ReadPCIConfig,	// selector
										   &input,					// input values
										   1,							// number of scalar input values														
										   &output_64,					// output values
										   &outputCount				// number of scalar output values
										   );
		*data = (uint32_t) output_64;
#endif
    }
    [theHWLock unlock];   //-----end critical section
    return result;
}


// get Bit3 PCI Configuration Data
- (kern_return_t) getPCIConfigurationData:(unsigned int) maxAddress
                              withDataPtr:(PCIConfigStructUser *)pciData
{
    kern_return_t result = 0;
	size_t pciDataSize = sizeof(PCIConfigStruct);
	
    [theHWLock lock];   //-----begin critical section
    if(hardwareExists){
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
		//10.4
		result = IOConnectMethodScalarIStructureO(
												  dataPort,		// service
												  kBit3GetPCIConfig,	// method index
												  1,			// number of scalar input values
												  &pciDataSize,		// byte size of output structure
												  maxAddress,		// scalar input values
												  pciData			// output structure
												  );
#else
		//10.5
		uint64_t scalarI = maxAddress;
		result = IOConnectCallMethod(  dataPort,					// connection
									 kBit3GetPCIConfig,			// selector
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
    }
    [theHWLock unlock];   //-----end critical section
    return result;
}





- (kern_return_t) writeCSRRegister:(unsigned char) regOffSet
                          withData:(unsigned char) data
{
    [theHWLock lock];   //-----begin critical section
    if(hardwareExists){
        
        // check if offset is out of Bit3 csr register range
        if( regOffSet > 0x1f ) return kIOReturnBadArgument;
        
        unsigned char *address = (unsigned char *)CSRRegisterAddress;
        address += regOffSet;
        
        *address = data;
    }
    [theHWLock unlock];   //-----end critical section
    return kIOReturnSuccess;
}



// read Bit3 CSR Register
- (kern_return_t) readCSRRegister:(unsigned char) regOffSet
                      withDataPtr:(unsigned char *) data
{
    [theHWLock lock];   //-----begin critical section
    if(hardwareExists){
        
        // check if offset is out of Bit3 csr register range
        if( regOffSet > 0x1f ) return kIOReturnBadArgument;
        
        unsigned char *address = (unsigned char *)CSRRegisterAddress;
        address += regOffSet;
        
        *data = *address;
    }
    [theHWLock unlock];   //-----end critical section
    return kIOReturnSuccess;
    
}

- (kern_return_t) readCSRRegisterNoLock:(unsigned char) regOffSet
                            withDataPtr:(unsigned char *) data
{
    if(hardwareExists){
        
        // check if offset is out of Bit3 csr register range
        if( regOffSet > 0x1f ) return kIOReturnBadArgument;
        
        unsigned char *address = (unsigned char *)CSRRegisterAddress;
        address += regOffSet;
        
        *data = *address;
    }
	else *data = 0;
    return kIOReturnSuccess;
    
}



// get Bit3 adapter id
- (unsigned char) getAdapterID
{
    unsigned char data=0;
    [self readCSRRegister:PCIVME_CSR_REMOTE_ADAPTER_ID_OFFSET withDataPtr:&data];
    return data;
}


// get Bit3 local status
- (unsigned char) getLocalStatus
{
    unsigned char data=0;
    [self readCSRRegister:PCIVME_CSR_LOCAL_STATUS_OFFSET withDataPtr:&data];
    return data;
}


// clear Bit3 error bits and return local status - bus power must be on
- (unsigned char) clearErrorBits
{
    unsigned char data;
    
    // clear any hardware errors caused by power up
    [self readCSRRegister:PCIVME_CSR_REMOTE_STATUS_OFFSET withDataPtr:&data];
    
    // clear any status errors
    data = LOCAL_CMD_CLRST;
    [self writeCSRRegister:PCIVME_CSR_LOCAL_COMMAND_OFFSET withData:data];
    
    // make final check on local errors
    [self readCSRRegister:PCIVME_CSR_LOCAL_STATUS_OFFSET withDataPtr:&data];
    return data;
}

- (void)  checkCratePower
{
	if(hardwareExists){
		[self checkStatusWord:*fVStatusReg];
	}
}

- (void) checkStatusWord:(unsigned char)data
{
    if(hardwareExists){
		if(!(data & LOCAL_STATUS_NOPOWER) && powerWasOff ){
			powerWasOff = NO;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"VmePowerRestoredNotification" object:self];
		}
		if( data & LOCAL_STATUS_NOPOWER ) {		// power off
			[[NSNotificationCenter defaultCenter] postNotificationName:@"VmePowerFailedNotification" object:self];
			powerWasOff = YES;
			[NSException raise: OExceptionNoVmeCratePower format:@"%@ unable to access Vme Crate. Check Power and Cables.",deviceName];
		}
		else if( data & LOCAL_STATUS_RXPRI ) {		// unable to clear errors
			[NSException raise: OExceptionVmeUnableToClear format:@"%@ unable to access Vme Crate. Check Power and Cables.",deviceName];
		}
		else if( data & ( LOCAL_STATUS_LRC | LOCAL_STATUS_IFTO
						 | LOCAL_STATUS_VMEBERR | LOCAL_STATUS_IFPE ) ) {	// unable to access
			
			NSString* baseString = [NSString stringWithFormat:@"%@ Vme Address Exception. ",deviceName];
			NSString* details = @"";
			if(data & LOCAL_STATUS_IFTO){
				details = @"Interface TimeOut";
				NSLogError(@" ",@"Bit3 Status",details,nil);
				timeOutErrors++;
			}
			if(data & LOCAL_STATUS_VMEBERR){
				details = @"Remote Bus Error";
				NSLogError(@" ",@"Bit3 Status",details,nil);
				remoteBusErrors++;
			}
			if(data & LOCAL_STATUS_IFPE){
				details = @"Fiber Interface Error";
				NSLogError(@" ",@"Bit3 Status",details,nil);
			}
			[NSException raise: OExceptionVmeAccessError format:@"%@:%@",baseString,details];
		}
	}
}    


// check Bit3 status errors. This method Raises Exceptions!
- (void) checkStatusErrors
{    
	if(hardwareExists){
		[self checkStatusWord:*fVStatusReg];
	}
}


// reset Bit3, return YES if any error, NO otherwise
- (void) resetContrl
{
    unsigned char data=0;
    
    // check remote power on
    [self readCSRRegister:PCIVME_CSR_LOCAL_STATUS_OFFSET withDataPtr:&data];
    if( data & LOCAL_STATUS_NOPOWER ) {
        [NSException raise: OExceptionNoVmeCratePower format:@"%@ unable to access Vme Crate. Check Power and Cables.",deviceName];
    }
    
    // clear any hardware errors caused by power up
    [self readCSRRegister:PCIVME_CSR_REMOTE_STATUS_OFFSET withDataPtr:&data];
    
    // clear any status errors and pr interrupt
    data = LOCAL_CMD_CLRST | LOCAL_CMD_IE;
    [self writeCSRRegister:PCIVME_CSR_LOCAL_COMMAND_OFFSET withData:data];
    
    [theHWLock lock];   //-----begin critical section
    [self checkStatusErrors];
    [theHWLock unlock];   //-----end critical section
    
}


// send VME SYSRESET and return remote bus status in status
//	return YES if error, NO otherwise
- (void) vmeSysReset:(unsigned char *)status
{
    NSTimeInterval t0;
    
    unsigned char data;
    
    // check remote power on
    [self _resetNoRaise];
    
    // generate vme sysreset
    data = 0x80;
    [self writeCSRRegister:PCIVME_CSR_REMOTE_COMMAND_1_OFFSET withData:data];
    
    // delay two seconds
    t0 = [NSDate timeIntervalSinceReferenceDate];
    while([NSDate timeIntervalSinceReferenceDate]-t0 < 2);
    
    // return remote status
    [self readCSRRegister:PCIVME_CSR_REMOTE_STATUS_OFFSET withDataPtr:&data];
    *status = data;
    
    [theHWLock lock];   //-----begin critical section
	@try {
		[self checkStatusErrors];
	}
	@catch(NSException* localException) {
	}
	[theHWLock unlock];   //-----end critical section
	
	NSLog(@"Vme Sys Reset\n");
}




// read a int (32 bit values) block from vme
- (void) readLongBlock:(uint32_t *) readAddress
             atAddress:(uint32_t) vmeAddress
             numToRead:(unsigned int) numberLongs
            withAddMod:(unsigned short) addModifier
         usingAddSpace:(unsigned short) addressSpace
{
    @try {
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){
            [self  _setupMapping: vmeAddress
                        numBytes: 4L * numberLongs
                          addMod: addModifier
                        addSpace: addressSpace];
            
            
			//if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:status];
			// transfer data
			uint32_t *pulr = (uint32_t *)( ( vmeAddress & 0x00000fff ) +
													remMemRegisterAddress );
			uint32_t *pulb = (uint32_t *)readAddress;
			unsigned int n = numberLongs;
			for(;n--;)*pulb++ = *pulr++;
 			if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:*fVStatusReg];
            
        }
		else *readAddress = 0;
        [theHWLock unlock];   //-----end critical section
        
        
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [self _resetNoRaise];
        errorCount++;
        retryCount[kLongRetryIndex]++;
        if(errorCount<2){
            [self readLongBlock:readAddress atAddress:vmeAddress
                      numToRead:numberLongs withAddMod:addModifier
                  usingAddSpace:addressSpace];
        }
        else {
            errorCount = 0;
            retryFailedCount[kLongRetryIndex]++;
            [localException raise]; //rethrown the exception
        }
	}
	errorCount = 0;
	
}

//a special read for reading fifos that reads one address multiple times
- (void) readLong:(uint32_t *) readAddress
		atAddress:(uint32_t) vmeAddress
	  timesToRead:(unsigned int) numberLongs
	   withAddMod:(unsigned short) addModifier
	usingAddSpace:(unsigned short) addressSpace
{
    @try {
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){
            [self  _setupMapping: vmeAddress
                        numBytes: 4L
                          addMod: addModifier
                        addSpace: addressSpace];
            
            
			// transfer data
			uint32_t *pulr = (uint32_t *)( ( vmeAddress & 0x00000fff ) + remMemRegisterAddress );
			uint32_t *pulb = (uint32_t *)readAddress;
			unsigned int n = numberLongs;
			for(;n--;)*pulb++ = *pulr++;
			
			
 			if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:*fVStatusReg];
            
        }
		else *readAddress = 0;
		
        [theHWLock unlock];   //-----end critical section
        
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [self _resetNoRaise];
		[localException raise]; //rethrown the exception
	}        
}




// write a int (32 bit values) block to vme
- (void) writeLongBlock:(uint32_t *) writeAddress
              atAddress:(uint32_t) vmeAddress
             numToWrite:(unsigned int) numberLongs
             withAddMod:(unsigned short) addModifier
          usingAddSpace:(unsigned short) addressSpace
{
    
    @try {
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){            
            [self  _setupMapping: vmeAddress
                        numBytes: 4L * numberLongs
                          addMod: addModifier
                        addSpace: addressSpace];
            
			//if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:status];
			// transfer data
			uint32_t *pulr = (uint32_t *)( ( vmeAddress & 0x00000fff ) +
													remMemRegisterAddress );
			uint32_t *pulb = (uint32_t *)writeAddress;
			unsigned int n = numberLongs;
			for(;n--;)*pulr++ = *pulb++;
			if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:*fVStatusReg];
			
        }
        
        [theHWLock unlock];   //-----end critical section
        
        
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [self _resetNoRaise];
        errorCount++;
        retryCount[kLongRetryIndex]++;
        if(errorCount<2){
            [self writeLongBlock:writeAddress atAddress:vmeAddress
                      numToWrite:numberLongs withAddMod:addModifier
                   usingAddSpace:addressSpace];
        }
        else {
            retryFailedCount[kLongRetryIndex]++;
            errorCount = 0;
            [localException raise]; //rethrown the exception
        }
	}
	errorCount = 0;
	
}



// read a byte block from vme
- (void) readByteBlock:(unsigned char *) readAddress
             atAddress:(uint32_t) vmeAddress
             numToRead:(unsigned int) numberBytes
            withAddMod:(unsigned short) addModifier
         usingAddSpace:(unsigned short) addressSpace
{
    @try {
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){
            [self  _setupMapping_Byte: vmeAddress
                             numBytes: numberBytes
                               addMod: addModifier
                             addSpace: addressSpace];
            
			//if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:*fVStatusReg];
			// transfer data
			unsigned char *pulr = (unsigned char *)( ( vmeAddress & 0x00000fff ) +
													remMemRegisterAddress );
			unsigned char *pulb = (unsigned char *)readAddress;
			unsigned int n = numberBytes;
			for(;n--;)*pulb++ = *pulr++;
			if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:*fVStatusReg];
            
        }
		else *readAddress = 0;
		
        [theHWLock unlock];   //-----end critical section
        
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [self _resetNoRaise];
        errorCount++;
        retryCount[kByteRetryIndex]++;
        if(errorCount<2){
            [self readByteBlock:readAddress atAddress:vmeAddress
                      numToRead:numberBytes withAddMod:addModifier
                  usingAddSpace:addressSpace];
        }
        else {
            retryFailedCount[kByteRetryIndex]++;
            errorCount = 0;
            [localException raise]; //rethrown the exception
        }
	}
	errorCount = 0;
	
}



// write a byte block to vme
- (void) writeByteBlock:(unsigned char *) writeAddress
              atAddress:(uint32_t) vmeAddress
             numToWrite:(unsigned int) numberBytes
             withAddMod:(unsigned short) addModifier
          usingAddSpace:(unsigned short) addressSpace
{	
    @try {        
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){
            [self  _setupMapping_Byte: vmeAddress
                             numBytes: numberBytes
                               addMod: addModifier
                             addSpace: addressSpace];
            
			//if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:*fVStatusReg];
			// transfer data
			unsigned char *pulr = (unsigned char *)( ( vmeAddress & 0x00000fff ) +
													remMemRegisterAddress );
			unsigned char *pulb = (unsigned char *)writeAddress;
			unsigned int n = numberBytes;
			for(;n--;)*pulr++ = *pulb++;
			if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:*fVStatusReg];
			
        }
        [theHWLock unlock];   //-----end critical section
        
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [self _resetNoRaise];
        errorCount++;
        retryCount[kByteRetryIndex]++;
        if(errorCount<2){
            [self writeByteBlock:writeAddress atAddress:vmeAddress
                      numToWrite:numberBytes withAddMod:addModifier
                   usingAddSpace:addressSpace];
        }
        else {
            retryFailedCount[kByteRetryIndex]++;
            errorCount = 0;
            [localException raise]; //rethrown the exception
        }
	}
	errorCount = 0;
}



// read a word (16 bits) block from vme
-  (void) readWordBlock:(unsigned short *) readAddress
              atAddress:(uint32_t) vmeAddress
              numToRead:(unsigned int) numberWords
             withAddMod:(unsigned short) addModifier
          usingAddSpace:(unsigned short) addressSpace
{	
    @try {
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){
            [self  _setupMapping: vmeAddress
                        numBytes: 2L * numberWords
                          addMod: addModifier
                        addSpace: addressSpace];
            
			//if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:*fVStatusReg];
            // transfer data
			uint16_t *pulr = (uint16_t *)( ( vmeAddress & 0x00000fff ) +
									  remMemRegisterAddress );
			uint16_t *pulb = (uint16_t *)readAddress;
			unsigned short n = numberWords;
			for(;n--;)*pulb++ = *pulr++;
			if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:*fVStatusReg];
            
        }
		else *readAddress = 0;
		
        [theHWLock unlock];   //-----end critical section
        
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [self _resetNoRaise];
        errorCount++;
        retryCount[kWordRetryIndex]++;
        if(errorCount<2){
            [self readWordBlock:readAddress atAddress:vmeAddress
                      numToRead:numberWords withAddMod:addModifier
                  usingAddSpace:addressSpace];
        }
        else {
            retryFailedCount[kWordRetryIndex]++;
            errorCount = 0;
            [localException raise]; //rethrown the exception
        }
	}
	errorCount = 0;
}



// write a word (16  bits) block to vme
-  (void) writeWordBlock:(unsigned short *) writeAddress
               atAddress:(uint32_t) vmeAddress
              numToWrite:(unsigned int) numberWords
              withAddMod:(unsigned short) addModifier
           usingAddSpace:(unsigned short) addressSpace
{	
    
    @try {        
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){
            [self  _setupMapping: vmeAddress
                        numBytes: 2L * numberWords
                          addMod: addModifier
                        addSpace: addressSpace];
            
			//if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:*fVStatusReg];
			// transfer data
			uint16_t *pulr = (uint16_t *)( ( vmeAddress & 0x00000fff ) +
									  remMemRegisterAddress );
			uint16_t *pulb = (uint16_t *)writeAddress;
			unsigned int n = numberWords;
			for(;n--;)*pulr++ = *pulb++;
 			if(*fVStatusReg & STATUS_PROBLEM)[self checkStatusWord:*fVStatusReg];
			
        }
        [theHWLock unlock];   //-----end critical section
        
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [self _resetNoRaise];
        errorCount++;
        retryCount[kWordRetryIndex]++;
        if(errorCount<2){
            [self writeWordBlock:writeAddress atAddress:vmeAddress
                      numToWrite:numberWords withAddMod:addModifier
                   usingAddSpace:addressSpace];
        }
        else {
            retryFailedCount[kWordRetryIndex]++;
            errorCount = 0;
            [localException raise]; //rethrown the exception
        }
	}
	errorCount = 0;
}

//-----------------------------------------------------------------------------------------------
// private methods
//-----------------------------------------------------------------------------------------------
// call Open method in user client
- (kern_return_t) _openUserClient:(io_service_t) serviceObject
                     withDataPort:(io_connect_t) aDataPort
{
	
	kern_return_t kernResult;
	
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
	//10.4
	kernResult = IOConnectMethodScalarIScalarO(aDataPort,		// service
											   kBit3UserClientOpen,	// method index
											   0,			// number of scalar input values
											   0			// number of scalar output values
											   );
#else
	//10.5
	kernResult= IOConnectCallScalarMethod(aDataPort,		// connection
										  kBit3UserClientOpen,	// selector
										  0,			// input values
										  0,			// number of scalar input values														
										  0,			// output values
										  0			// number of scalar output values
										  );
#endif
	return kernResult;
}


// call Close method in user client - but currently appears to do nothing
- (kern_return_t) _closeUserClient:(io_connect_t) aDataPort
{
	kern_return_t kernResult;
	
#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
	//10.4
	kernResult = IOConnectMethodScalarIScalarO(aDataPort,		// service
											   kBit3UserClientClose,	// method index
											   0,			// number of scalar input values
											   0			// number of scalar output values
											   );
#else
	//10.5
	kernResult =  IOConnectCallScalarMethod( aDataPort,		// connection
											kBit3UserClientClose,	// selector
											0,			// input values
											0,			// number of scalar input values														
											0,			// output values
											0			// number of scalar output values
											);
#endif
	return kernResult;
}

// locate PCI device in the registry and open user client in driver
- (BOOL) _findDevice
{    
    //first make sure the driver is installed.
    NSFileManager* fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:[self driverPath]]){
        driverExists = NO;
        return NO;
    }
    else driverExists = YES;
    
    // create Master Mach Port which is used to initiate
    // communication with IOKit
    kern_return_t ret = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if( ret != KERN_SUCCESS ) {
        return NO;
    }
    
    // create a property list dictionary for matching driver class,
    // input string is used as the value for the IOProviderClass object
    CFDictionaryRef bit3Match = IOServiceMatching([self serviceClassName]);
    if( bit3Match == NULL ) {
        return NO;
    }        
    
    // create iterator of all instances of the driver class that exist
    // in the IORegistry - note that IOServiceGetMatchingServices is
    // documented as consuming a reference on the matching dictionary
    // so it is not necessary to release it here - very odd!!!!
	io_iterator_t iter;
    ret = IOServiceGetMatchingServices(masterPort, bit3Match, &iter);
    if( ret != KERN_SUCCESS ) {
        return NO;
    }        
    // iterate over all matching drivers in the registry to find a device
    // match - could just take the first device matched but should probably
    // check if more than one device was created since that is an error
    totalDevicesFound = 0;
    while( (device = IOIteratorNext(iter)) ) {
        if( !bit3Device )bit3Device = device;
        totalDevicesFound++;
    }
    IOObjectRelease(iter);	// release iterator since no longer needed
    
    //if(totalDevicesFound>1) return NO;
    if(!bit3Device)         return NO;
    
    // create an instance of the user client object
    dataService = bit3Device;
    ret = IOServiceOpen(dataService, mach_task_self(), 0,
                        &dataPort);
    if( ret != KERN_SUCCESS ) {
        return NO;
    }
    
    // now have a connection to the user client in the driver
    // call Open method in user client
    ret = [self _openUserClient:dataService withDataPort:dataPort];
    IOObjectRelease(dataService);	// release service since no longer needed
    dataService = 0;
    if( ret != KERN_SUCCESS ) {
        return NO;
    }
    
    // now can call methods to communicate with user client and rest of driver
    // call clientMemoryFortype() in driver user client to map Bit3 address spaces
    // map Bit3 CSR register address space
    
//    IOConnectMapMemory(
//                       io_connect_t        connect,
//                       uint32_t        memoryType,
//                       task_port_t        intoTask,
//                       mach_vm_address_t    *atAddress,
//                       mach_vm_size_t        *ofSize,
//                       IOOptionBits         options );
    ret = IOConnectMapMemory(dataPort,
                             1,
                             mach_task_self(),
                             &CSRRegisterAddress,
                             &CSRRegisterLength,
                             kIOMapAnywhere);
    if( ret != KERN_SUCCESS ) {
        return NO;
    }
    fVStatusReg = (unsigned char *)CSRRegisterAddress + PCIVME_CSR_LOCAL_STATUS_OFFSET;
	
    // map Bit3 mapping register address space
    ret = IOConnectMapMemory(dataPort,
                             2,
                             mach_task_self(),
                             &mapRegisterAddress,
                             &mapRegisterLength,
                             kIOMapAnywhere);
    if( ret != KERN_SUCCESS ) {
        return NO;
    }
    
    // map Bit3 remote memory register address space
    ret = IOConnectMapMemory(dataPort,
                             3,
                             mach_task_self(),
                             &remMemRegisterAddress,
                             &remMemRegisterLength,
                             kIOMapAnywhere);
    if( ret != KERN_SUCCESS ) {
        return NO;
    }        
    
    
    return YES;
}

- (void) _resetNoRaise
{
    unsigned char data;
    // clear any hardware errors caused by power up
    [self readCSRRegister:PCIVME_CSR_REMOTE_STATUS_OFFSET withDataPtr:&data];
    
    // clear any status errors and pr interrupt
    data = LOCAL_CMD_CLRST | LOCAL_CMD_IE;
    [self writeCSRRegister:PCIVME_CSR_LOCAL_COMMAND_OFFSET withData:data];
}

// setup Bit3 mapping registers
- (void) _setupMapping: (uint32_t)remoteAddress
              numBytes: (uint32_t)numberBytes
                addMod: (uint16_t)addModifier
              addSpace: (uint16_t)addressSpace
{
    
    // pick up a12-a31 address bits
    uint32_t mapValue = ((remoteAddress & 0xfffff000)
							  | ((addModifier << 6) & 0x00000fc0)  // add address modifier bits
							  | ((addressSpace << 4) & 0x00000030) // add function code bits
							  | 0x00000002)	// add swapping bit - byte swap for non-byte data enable
	& 0xfffffffe;	// clear map register invalid bit at d0 - enable PCI to VME access
    
	volatile uint32_t* mptr = (uint32_t *)(mapRegisterAddress);
	uint32_t n = numberBytes + ( remoteAddress & 0x00000fff );
	uint32_t j;
    for( j = 0L; j < n ; j += 0x00001000 ) {
		uint32_t swmap = Swap8Bits(mapValue);
        *mptr = swmap;
		//MAH Nov 2004. found that on faster machines, the mapping register does not have time
		//to settle. Add a check to verify that the value is what we set it to and if not
		//add in a time delay below. I note that when the value is read back the delay doesn't 
		//seem to be ever used, but I left it in just in case.
		if(*mptr != swmap)[ORTimer delayNanoseconds:175];
		mapValue += 0x00001000;
		++mptr;
    };
}

- (void) _setupMapping_Byte: (uint32_t)remoteAddress
                   numBytes: (uint32_t)numberBytes
                     addMod: (uint16_t)addModifier
                   addSpace: (uint16_t)addressSpace
{
    
    // pick up a12-a31 address bits
    uint32_t mapValue = ((remoteAddress & 0xfffff000)
							  | ((addModifier << 6) & 0x00000fc0) // add address modifier bits
							  | ((addressSpace << 4) & 0x00000030)// add function code bits
							  | 0x00000008)	// add swapping bit - byte swap for byte data enable
	& 0xfffffffe;	// clear map register invalid bit at d0 - enable PCI to VME access
    
    // put map value in proper mapping register(s) - note byte swapping to
    // change mac big endian value to little endian for pci
    volatile uint32_t* mptr = (uint32_t *)(mapRegisterAddress);
	uint32_t n = numberBytes + ( remoteAddress & 0x00000fff );
	uint32_t j;
    for( j = 0L; j < n ; j += 0x00001000 ) {
		uint32_t swmap = Swap8Bits(mapValue);
        *mptr = swmap;
		//MAH Nov 2004. found that on faster machines, the mapping register does not have time
		//to settle. Add a check to verify that the value is what we set it to and if not
		//add in a time delay below. I note that when the value is read back the delay doesn't 
		//seem to be ever used, but I left it in just in case.
		if(*mptr != swmap)[ORTimer delayNanoseconds:175];
        mapValue += 0x00001000;
		++mptr;
    };  
}

#pragma mark ¥¥¥DMA
// ReadVMELongBlockDMA - read a block of int32_t values from VME Bus with DMA
// NOTE - existence of hardware must be established before using this method
// NOTE - the buffer (readAddress) used for the dma read must be locked contiguous
//			physical memory and must allow this function to reserve 4 bytes (1 int32_t)
//			at the beginning of the buffer for dma flags
// NOTE - the VME address (vmeAddress) must be int32_t word aligned
- (void) readLongBlock:(uint32_t *) readAddress
			 atAddress:(uint32_t) vmeAddress
			 numToRead:(unsigned int) numberLongs
		 usingAddSpace:(unsigned short) addressSpace
		  useBlockMode:(bool) useBlockMode
{
	// setup parameters
	Boolean enableByteSwap = TRUE;
	Boolean enableWordSwap = FALSE;
	uint32_t address = vmeAddress;
	uint32_t transfers = numberLongs;
	unsigned short space = addressSpace;
	//uint32_t bytes = 4L * transfers;
	
	// setup and clear dma buffer flag area
	uint32_t *dmaBuffer = readAddress;
	uint32_t *pucb = dmaBuffer;
	uint32_t j;
	for(j = 0L; j < 4L; j++ ) *pucb++ = 0x00000000;
	
	// reserve 4 bytes (1 int32_t) at beginning of dma buffer for flags
	uint32_t *dmaFlags = dmaBuffer;
	dmaBuffer += 4L;
	uint32_t physicalAddress = (uint32_t)dmaBuffer;
	
	// start dma
	*dmaFlags = (uint32_t)0x00000000L;
	[self  startDma: address 
physicalBufferAddress: physicalAddress
	numberTransfers: transfers 
	   addressSpace: space
	 enableByteSwap: enableByteSwap 
	 enableWordSwap: enableWordSwap
	   useBlockMode: useBlockMode
		  direction: 'R'];
	
	// wait for dma to complete or done interrupt to occur
    ORTimer* timer = [[ORTimer alloc]init];
    [timer start];
	do {
		
		// need to put a reasonable delay here to prevent slowdown
		// by repeated check for dma complete
        
		int32_t elapsedTime = [timer microsecondsSinceStart];
		if( elapsedTime < 100L ) {
			continue;
		}
		if( elapsedTime > 100000L ) {  // to prevent hang
			break;
		}
		
	} while( ![self checkDmaComplete:dmaFlags] );
    [timer release];
	//uint32_t endTime = TickCount();
	//StatusPrintf("Time For %d Byte Reads = %d Ticks",bytes,
	//		(uint32_t)(endTime - startTime));
	//StatusPrintf("DmaFlags = 0x%08x",*dmaFlags); 
	
	// check for errors	
	if( ![self checkDmaErrors] ) {
		NSString* baseString = [NSString stringWithFormat:@"%@ Vme DMA Exception. ",deviceName];
		[NSException raise: CExceptionVmeLongBlockReadErr format:@"%@",baseString];
	}
}



// WriteVMELongBlockDMA - write a block of int32_t values from PCI Bus with DMA
// NOTE - existence of hardware must be established before using this method
// NOTE - the buffer (writeAddress) used for the dma write must be locked contiguous
//			physical memory and must allow this function to reserve 4 bytes (1 int32_t)
//			at the beginning of the buffer for dma flags
// NOTE - the VME address (vmeAddress) must be int32_t word aligned
- (void) writeLongBlock:(uint32_t *) writeAddress
			  atAddress:(uint32_t) vmeAddress
			 numToWrite:(unsigned int) numberLongs
		  usingAddSpace:(unsigned short) addressSpace
		   useBlockMode:(bool) useBlockMode
{
	// setup parameters
	Boolean enableByteSwap = TRUE;
	Boolean enableWordSwap = FALSE;
	uint32_t address = vmeAddress;
	uint32_t transfers = numberLongs;
	unsigned short space = addressSpace;
	//uint32_t bytes = 4L * transfers;
	
	// setup and clear dma buffer flag area
	uint32_t *dmaBuffer = writeAddress;
	uint32_t *pucb = dmaBuffer;
	uint32_t j;
	for(j = 0L; j < 4L; j++ ) {
		*pucb++ = 0x00000000;
	}
	
	// reserve 4 bytes (1 int32_t) at beginning of dma buffer for flags
	uint32_t *dmaFlags = dmaBuffer;
	dmaBuffer += 4L;
	uint32_t physicalAddress = (uint32_t)dmaBuffer;
	
	// start dma
	*dmaFlags = (uint32_t)0x00000000L;
	
	[self startDma: address 
physicalBufferAddress: physicalAddress
   numberTransfers: transfers 
	  addressSpace: space
	enableByteSwap: enableByteSwap 
	enableWordSwap: enableWordSwap
	  useBlockMode: useBlockMode
		 direction: 'W'];
	
	
	
	// wait for dma to complete or done interrupt to occur
    ORTimer* timer = [[ORTimer alloc]init];
    [timer start];
	do {
		
		// need to put a reasonable delay here to prevent slowdown
		// by repeated check for dma complete
		int32_t elapsedTime = [timer microsecondsSinceStart];
		if( elapsedTime < 10L ) {
			continue;
		}
		if( elapsedTime > 1000L ) {  // to prevent hang
			break;
		}
		
	} while( ![self checkDmaComplete:dmaFlags]);
    [timer release];
	//uint32_t endTime = TickCount();
	//StatusPrintf("Time For %d Byte Reads = %d Ticks",bytes,
	//		(uint32_t)(endTime - startTime));
	//StatusPrintf("DmaFlags = 0x%08x",*dmaFlags); 
	
	// check for errors	
	if( ![self checkDmaErrors] ) {
		NSString* baseString = [NSString stringWithFormat:@"%@ Vme DMA Exception. ",deviceName];
		[NSException raise: CExceptionVmeLongBlockWriteErr format:@"%@",baseString];
	}
}




// CheckDmaErrors - return TRUE if no errors, FALSE otherwise
- (bool) checkDmaErrors
{
	//volatile unsigned char *cptr = (unsigned char *)GetIoBaseAddress();
	volatile unsigned char *cptr = (unsigned char *)CSRRegisterAddress;
	
	unsigned char uc;
	Boolean errorStatus;
	
	// display results of dma registers
	//uc = *(cptr + PCIVME_DMA_LOCAL_REMAINDER_COUNT_OFFSET); // debug read
	//StatusPrintf("DMA Local DMA Remainder Count Register = 0x%02x",uc); // debug
	//uc = *(cptr + PCIVME_DMA_LOCAL_PACKET_COUNT_0_7_OFFSET); // debug read
	//StatusPrintf("DMA Local DMA Packet Count Register(0-7) = 0x%02x",uc); // debug
	//uc = *(cptr + PCIVME_DMA_LOCAL_PACKET_COUNT_8_15_OFFSET); // debug read
	//StatusPrintf("DMA Local DMA Packet Count Register(8-15) = 0x%02x",uc); // debug
	//uc = *(cptr + PCIVME_DMA_REMOTE_REMAINDER_COUNT_OFFSET); // debug read
	//StatusPrintf("DMA Remote DMA Remainder Count Register = 0x%02x",uc); //debug
	
	// check local status register for errors
	uc = *(cptr + PCIVME_CSR_LOCAL_STATUS_OFFSET);
	if( ( uc & 0xc7 ) == 0x00 ) {
		//StatusPrintf("DMA Completed Successfully, Local Status = 0x%02x",uc);
		errorStatus = TRUE;
	}
	else {
		//StatusPrintf("Errors During DMA, Local Status = 0x%02x",uc);
		errorStatus = FALSE;
		
		// clear any interface errors
		uc = *(cptr + PCIVME_CSR_REMOTE_STATUS_OFFSET);
		//StatusPrintf("Errors During DMA, Remote Status = 0x%02x",uc);
		
		// clear any status errors
		uc = 0x80;
		*(cptr + PCIVME_CSR_LOCAL_COMMAND_OFFSET) = uc;
	}
	
	// clear remote command reg 2
	uc = 0x00;
	*(cptr + PCIVME_CSR_REMOTE_COMMAND_2_OFFSET) = uc;
	
	return errorStatus;
}

- (bool) checkDmaComplete:(uint32_t*) checkFlag;
{
	
	// check for dma complete
#ifndef USE_INTERRUPT		// without dma done interupt
	
	//volatile unsigned char *cptr = (unsigned char *)GetIoBaseAddress();
	volatile unsigned char *cptr = (unsigned char *)CSRRegisterAddress;
	unsigned char uc;
	
	uc = *(cptr + PCIVME_DMA_LOCAL_COMMAND_OFFSET);
	if( ( uc & 0x02 ) == 0x00 ) {
		return FALSE;
	}
	else {
		return TRUE;
	}
	
#else						// with dma done interrupt
	
	if( *( checkFlag + DMA_COMPLETE_OFFSET ) == (unsigned char)0x00 ) {
		return FALSE;
	}
	else {
		return TRUE;
	}
	
#endif
}



// theDirection = 'R' for VME to PCI DMAs
// theDirection = 'W' for PCI to VME DMAs
- (void) startDma:(uint32_t) vmeAddress 
physicalBufferAddress:(uint32_t) physicalBufferAddress
  numberTransfers:(uint32_t) numberTransfers 
	 addressSpace:(unsigned short) addressSpace
   enableByteSwap:(bool) enableByteSwap 
   enableWordSwap:(bool) enableWordSwap
	 useBlockMode:(bool) useBlockMode
		direction:(char) theDirection;
{
	// seup dma map registers(s)
	uint32_t bytes = 4L * numberTransfers;
	[self setupMappingDMA: physicalBufferAddress
			  numberBytes: bytes
		   enableByteSwap: enableByteSwap 
		   enableWordSwap: enableWordSwap];
	
	// load local dma remainder count reg (8 bits)
	//volatile unsigned char *cptr = (unsigned char *)GetIoBaseAddress();
	volatile unsigned char *cptr = (unsigned char *)CSRRegisterAddress;
	unsigned char uc = (unsigned char)( bytes & 0x000000fc );
	*(cptr + PCIVME_DMA_LOCAL_REMAINDER_COUNT_OFFSET) = uc;
	//	uc = *(cptr + PCIVME_DMA_LOCAL_REMAINDER_COUNT_OFFSET); // debug read
	//	StatusPrintf("DMA Local DMA Remainder Count Register = 0x%02x",uc); // debug
	
	// local dma packet count reg (16 bits)
	unsigned short us = (unsigned short)( bytes / 256L );
	*(cptr + PCIVME_DMA_LOCAL_PACKET_COUNT_0_7_OFFSET) =
	(unsigned char)( us & 0x00ff );
	*(cptr + PCIVME_DMA_LOCAL_PACKET_COUNT_8_15_OFFSET) =
	(unsigned char)( ( us >> 8 ) & 0x00ff );
	//	uc = *(cptr + PCIVME_DMA_LOCAL_PACKET_COUNT_0_7_OFFSET); // debug read
	//	StatusPrintf("DMA Local DMA Packet Count Register(0-7) = 0x%02x",uc); // debug
	//	uc = *(cptr + PCIVME_DMA_LOCAL_PACKET_COUNT_8_15_OFFSET); // debug read
	//	StatusPrintf("DMA Local DMA Packet Count Register(8-15) = 0x%02x",uc); // debug
	
	// load local dma address reg (24 bits)
	us = (unsigned short)( physicalBufferAddress & 0x00000fff); // use address bit 0-11 and first map reg
	*(cptr + PCIVME_DMA_LOCAL_PCI_ADDRESS_0_7_OFFSET) =
	(unsigned char)( us & 0x00ff );
	*(cptr + PCIVME_DMA_LOCAL_PCI_ADDRESS_8_15_OFFSET) =
	(unsigned char)( ( us >> 8 ) & 0x00ff );
	uc = 0x00; // use first dma map register
	*(cptr + PCIVME_DMA_LOCAL_PCI_ADDRESS_16_23_OFFSET) = uc;
	//	uc = *(cptr + PCIVME_DMA_LOCAL_PCI_ADDRESS_0_7_OFFSET); // debug read
	//	StatusPrintf("DMA Local PCI Address Register(0-7) = 0x%02x",uc); // debug
	//	uc = *(cptr + PCIVME_DMA_LOCAL_PCI_ADDRESS_8_15_OFFSET); // debug read
	//	StatusPrintf("DMA Local PCI Address Register(8-15) = 0x%02x",uc); // debug
	//	uc = *(cptr + PCIVME_DMA_LOCAL_PCI_ADDRESS_16_23_OFFSET); // debug read
	//	StatusPrintf("DMA Local PCI Address Register(16-23) = 0x%02x",uc); // debug
	
	// load remote dma remainder count reg (8 bits)
	uc = (unsigned char)( bytes & 0x000000fc );
	*(cptr + PCIVME_DMA_REMOTE_REMAINDER_COUNT_OFFSET) = uc;
	//	uc = *(cptr + PCIVME_DMA_REMOTE_REMAINDER_COUNT_OFFSET); // debug read
	//	StatusPrintf("DMA Remote DMA Remainder Count Register = 0x%02x",uc); //debug
	
	// load remote dma address reg (32 bits)
	uint32_t ul = (uint32_t)vmeAddress;
	*(cptr + PCIVME_DMA_REMOTE_VME_ADDRESS_0_7_OFFSET) =
	(unsigned char)( ul & 0x000000ff );
	*(cptr + PCIVME_DMA_REMOTE_VME_ADDRESS_8_15_OFFSET) =
	(unsigned char)( ( ul >> 8 ) & 0x000000ff );
	*(cptr + PCIVME_DMA_REMOTE_VME_ADDRESS_16_23_OFFSET) =
	(unsigned char)( ( ul >> 16 ) & 0x000000ff );
	*(cptr + PCIVME_DMA_REMOTE_VME_ADDRESS_24_31_OFFSET) =
	(unsigned char)( ( ul >> 24 ) & 0x000000ff );
	//	uc = *(cptr + PCIVME_DMA_REMOTE_VME_ADDRESS_0_7_OFFSET); // debug read
	//	StatusPrintf("DMA Remote VME Address Register(0-7) = 0x%02x",uc); // debug
	//	uc = *(cptr + PCIVME_DMA_REMOTE_VME_ADDRESS_8_15_OFFSET); // debug read
	//	StatusPrintf("DMA Remote VME Address Register(8-15) = 0x%02x",uc); // debug
	//	uc = *(cptr + PCIVME_DMA_REMOTE_VME_ADDRESS_16_23_OFFSET); // debug read
	//	StatusPrintf("DMA Remote VME Address Register(16-23) = 0x%02x",uc); // debug
	//	uc = *(cptr + PCIVME_DMA_REMOTE_VME_ADDRESS_24_31_OFFSET); // debug read
	//	StatusPrintf("DMA Remote VME Address Register(24-31) = 0x%02x",uc); // debug
	
	// clear remote command reg 1
	uc = 0x00;
	*(cptr + PCIVME_CSR_REMOTE_COMMAND_1_OFFSET) = uc;
	
	// load remote command reg 2
	//uc = *(cptr + PCIVME_CSR_REMOTE_COMMAND_2_OFFSET);
	uc = 0x00;
	//uc &= 0x0f;		// save page size select mask
	uc |= 0x10;		// disable interrupt passing across cable
	if( useBlockMode ) {
		uc |= 0x20;		// use block mode
	}
	//uc |= 0x40;		// use remote am reg
	//uc |= 0x80;		// use pause mode
	*(cptr + PCIVME_CSR_REMOTE_COMMAND_2_OFFSET) = uc;
	//	uc = *(cptr + PCIVME_CSR_REMOTE_COMMAND_2_OFFSET); // debug read
	//	StatusPrintf("DMA Remote Command Register 2 = 0x%02x",uc); // debug
	
	// load remote address modifier csr reg
	unsigned short am;
	if( vmeAddress < 0x01000000 ) {
		if( useBlockMode ) {
			am = 0x3f;			// a24 - block mode
		}
		else {
			am = 0x3d;			// a24 - non block mode
		}
	}
	else {
		if( useBlockMode ) {
			am = 0x0f;			// a32 - block mode
		}
		else {
			am = 0x0d;			// a32 - non block mode
		}
	}
	uc = (unsigned char)am;
	*(cptr + PCIVME_CSR_REMOTE_VME_ADD_MOD_OFFSET) = uc;
	//	uc = *(cptr + PCIVME_CSR_REMOTE_VME_ADD_MOD_OFFSET); // debug read
	//	StatusPrintf("CSR Remote VME AM Register = 0x%02x",uc); // debug
	
	// enable dma done interrupt in local interrupt control register
#ifdef USE_INTERRUPT
	uc = 0x40;			// dma done interrupt
#else
	uc = 0x00;			// no interrupts
#endif
	*(cptr + PCIVME_CSR_LOCAL_INT_CONTROL_OFFSET) = uc;
	
	if( theDirection == 'R' ) {			// vme to pci
		
		// load local dma command reg for vme to pci dma transfers (8 bits) and
		// enable dma done interrupt
		if( addressSpace == ACCESS_REMOTE_DPRAM ) {
#ifdef USE_INTERRUPT
			uc = 0x54;	// read from VME dpram with longword transfers and interrupt
#else
			uc = 0x50;	// read from VME dpram with longword transfers
#endif
		}
		else {
#ifdef USE_INTERRUPT
			uc = 0x14;	// read from VME ram with longword transfers and interrupt
#else
			uc = 0x10;	// read from VME ram with longword transfers
#endif
		}
	}
	else {							// pci to vme
		
		// load local dma command reg for vme to pci dma transfers (8 bits) and
		// enable dma done interrupt
		if( addressSpace == ACCESS_REMOTE_DPRAM ) {
#ifdef USE_INTERRUPT
			uc = 0x74;	// read from VME dpram with longword transfers and interrupt
#else
			uc = 0x70;	// read from VME dpram with longword transfers
#endif
		}
		else {
#ifdef USE_INTERRUPT
			uc = 0x34;	// read from VME ram with longword transfers and interrupt
#else
			uc = 0x30;	// read from VME ram with longword transfers
#endif
		}
	}
	
	unsigned char startDMA = uc;
	*(cptr + PCIVME_DMA_LOCAL_COMMAND_OFFSET) = uc;
	//	uc = *(cptr + PCIVME_DMA_LOCAL_COMMAND_OFFSET); // debug read
	//	StatusPrintf("DMA Local Command Register = 0x%02x",uc); // debug
	
	// start dma
	*(cptr + PCIVME_DMA_LOCAL_COMMAND_OFFSET) = ( startDMA | 0x80 );
}




- (void) setupMappingDMA:(uint32_t) remoteAddress
			 numberBytes:(uint32_t) numberBytes
		  enableByteSwap:(bool) enableByteSwap 
		  enableWordSwap:(bool) enableWordSwap;
{
	
	// pick up a12-a31 address bits
	uint32_t mapValue = remoteAddress & (uint32_t)0xfffff000;
	
	// add byte swap on non-byte data bit
	if( enableByteSwap ) {
		
		// add swapping bit for byte swap for non-byte data enable
		mapValue |= (uint32_t)0x00000002;
	} 
	
	// add word swap bit
	if( enableWordSwap ) {
		
		// add swapping bit for word swap
		mapValue |= (uint32_t)0x00000004;
	} 
	
	// clear map register invalid bit at d0 - enable PCI to VME access
	mapValue &= (uint32_t)0xfffffffe;
	//StatusPrintf("Starting Map Value = 0x%08lx",mapValue);
	
	// put map value in proper mapping register(s)
	//	volatile uint32_t *mptr = (uint32_t *)( (uint32_t)GetMappingBaseAddress() +
	//			 (uint32_t)DMA_MAPPING_REGISTER_OFFSET );
	
	volatile uint32_t *mptr = (uint32_t *)(mapRegisterAddress +
													 DMA_MAPPING_REGISTER_OFFSET );
	
	
	uint32_t j;
	for( j = 0L; j < numberBytes + ( remoteAddress & 0x00000fff );
		j += (uint32_t)0x00001000 ) {
		
		uint32_t swappedMapValue = Swap8Bits(mapValue);
		//StatusPrintf("j = %d,MapRegPtr = 0x%08x, MapValue = 0x%08x,SwappedMapValue = 0x%08x",j,
		//	(uint32_t)mptr,(uint32_t)mapValue,(uint32_t)swappedMapValue);
		
		*mptr++ = swappedMapValue;
		mapValue += (uint32_t)0x00001000;
	}
}

- (void) executeCommandList:(ORCommandList*)aList
{
	ORVmeReadWriteCommand* aCmd;
	NSEnumerator* e = [aList objectEnumerator];
	while(aCmd = [e nextObject]){
		unsigned char*	byteData;
		unsigned short* wordData;
		uint32_t*	longData;
		@try {
			//writes
			if([aCmd opType] == kWriteOp){
				switch([aCmd itemSize]){
					case 1:		//byte block
						byteData = (unsigned char*)[[aCmd data] bytes];
						[self writeByteBlock:byteData 
								   atAddress:[aCmd vmeAddress] 
								  numToWrite:[aCmd numberItems] 
								  withAddMod:[aCmd addressModifier] 
							   usingAddSpace:[aCmd addressSpace]];
						break;
					case 2:		//word block
						wordData = (unsigned short*)[[aCmd data] bytes];
						[self writeWordBlock:wordData 
								   atAddress:[aCmd vmeAddress] 
								  numToWrite:[aCmd numberItems] 
								  withAddMod:[aCmd addressModifier] 
							   usingAddSpace:[aCmd addressSpace]];
						break;
					case 4:		//int32_t block
						longData = (uint32_t*)[[aCmd data] bytes];
						[self writeLongBlock:longData 
								   atAddress:[aCmd vmeAddress] 
								  numToWrite:[aCmd numberItems] 
								  withAddMod:[aCmd addressModifier] 
							   usingAddSpace:[aCmd addressSpace]];
						break;
				}
			}
			else if([aCmd opType] == kReadOp){
				//reads
				switch([aCmd itemSize]){
					case 1:		//byte block
						byteData = (unsigned char*)[aCmd bytes];
						[self readByteBlock:byteData 
								  atAddress:[aCmd vmeAddress] 
								  numToRead:[aCmd numberItems] 
								 withAddMod:[aCmd addressModifier] 
							  usingAddSpace:[aCmd addressSpace]];
						break;
					case 2:		//word block
						wordData = (unsigned short*)[aCmd bytes];
						[self readWordBlock:wordData 
								  atAddress:[aCmd vmeAddress] 
								  numToRead:[aCmd numberItems] 
								 withAddMod:[aCmd addressModifier] 
							  usingAddSpace:[aCmd addressSpace]];
						break;
					case 4:		//int32_t block
						longData = (uint32_t*)[aCmd bytes];
						[self readLongBlock:longData 
								  atAddress:[aCmd vmeAddress] 
								  numToRead:[aCmd numberItems] 
								 withAddMod:[aCmd addressModifier] 
							  usingAddSpace:[aCmd addressSpace]];
						break;
				}
			}
			else if([aCmd opType] == kReadOp){
				[ORTimer delay:[aCmd milliSecondDelay]];
			}
			[aCmd setReturnCode: 1]; //must have worked since nothing was thrown
		}
		@catch (NSException* localException) {
			[aCmd setReturnCode: 0];
		}
	}
}


#pragma mark ¥¥¥Rates
- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag
{
    if(groupTag == 0){
        if(counterTag>=0 && counterTag<kNumRetryIndexes){
            return retryCount[counterTag];
        }	
        else return 0;
    }
    else return 0;
}

#pragma mark ¥¥¥Archival
static NSString *ORPciBit3DualPortAddress		= @"Bit3 Dual Port Address";
static NSString *ORPciBit3DualPortRamSize		= @"Bit3 Dual Port Ram Size";
static NSString *ORPciBit3RWAddress				= @"Bit3 Read/Write Address";
static NSString *ORPciBit3WriteValue			= @"Bit3 Write Value";
static NSString *ORPciBit3ReadWriteType			= @"Bit3 Read/Write Type";
static NSString *ORPciBit3ReadWriteAddMod		= @"Bit3 Read/Write Address Modifier";
static NSString *ORPciBit3ReadWriteAddSpace		= @"Bit3 Read/Write Address Space";
static NSString *ORPciBit3ErrorRateGroup		= @"Bit3 Error Rate Group";
static NSString *ORPciBit3ErrorRateXAttributes  = @"Bit3 ErrorRateXAttributes";
static NSString *ORPciBit3ErrorRateYAttributes  = @"Bit3 ErrorRateYAttributes";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    theHWLock = [[NSLock alloc] init];    
    
    [[self undoManager] disableUndoRegistration];
    
    [self setRangeToDo:[decoder decodeIntegerForKey:@"ORPciBit3ModelRange"]];
    [self setDoRange:[decoder decodeBoolForKey:@"ORPciBit3ModelDoRange"]];
    [self setDualPortAddress:[decoder decodeIntForKey:ORPciBit3DualPortAddress]];
    [self setDualPortRamSize:[decoder decodeIntForKey:ORPciBit3DualPortRamSize]];
    
    [self setRwAddress:[decoder decodeIntForKey:ORPciBit3RWAddress]];
    [self setWriteValue:[decoder decodeIntForKey:ORPciBit3WriteValue]];
    [self setRwAddressModifier:[decoder decodeIntForKey:ORPciBit3ReadWriteAddMod]];
    [self setReadWriteIOSpace:[decoder decodeIntForKey:ORPciBit3ReadWriteAddSpace]];
    [self setReadWriteType:[decoder decodeIntForKey:ORPciBit3ReadWriteType]];
    [self setErrorRateGroup:[decoder decodeObjectForKey:ORPciBit3ErrorRateGroup]];
    [self setErrorRateXAttributes:[decoder decodeObjectForKey:ORPciBit3ErrorRateXAttributes]];
    [self setErrorRateYAttributes:[decoder decodeObjectForKey:ORPciBit3ErrorRateXAttributes]];
    
    
    if(!errorRateGroup){
	    [self setErrorRateGroup:[[[ORRateGroup alloc] initGroup:3 groupTag:0] autorelease]];
	    [errorRateGroup setIntegrationTime:5];
    }
    [errorRateGroup start:self];
    [errorRateGroup resetRates];
    [errorRateGroup calcRates];
    
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:rangeToDo forKey:@"ORPciBit3ModelRange"];
    [encoder encodeBool:doRange forKey:@"ORPciBit3ModelDoRange"];
    [encoder encodeInteger:dualPortAddress forKey:ORPciBit3DualPortAddress];
    [encoder encodeInteger:dualPortRamSize forKey:ORPciBit3DualPortRamSize];
    
    [encoder encodeInt:rwAddress forKey:ORPciBit3RWAddress];
    [encoder encodeInt:writeValue forKey:ORPciBit3WriteValue];
    [encoder encodeInteger:rwAddressModifier forKey:ORPciBit3ReadWriteAddMod];
    [encoder encodeInteger:readWriteIOSpace forKey:ORPciBit3ReadWriteAddSpace];
    [encoder encodeInteger:readWriteType forKey:ORPciBit3ReadWriteType];
    [encoder encodeObject:errorRateGroup forKey:ORPciBit3ErrorRateGroup];
    
    [encoder encodeObject:errorRateXAttributes forKey:ORPciBit3ErrorRateYAttributes];
    [encoder encodeObject:errorRateYAttributes forKey:ORPciBit3ErrorRateXAttributes];
}

- (void) printErrorSummary
{
	
	NSLog(@"Remote Bus Errors: %d\n",remoteBusErrors);
	NSLog(@"Time Out Erros   : %d\n",timeOutErrors);
	
	if(retryCount[0] || retryCount[1] || retryCount[2] ||
       retryFailedCount[0] || retryFailedCount[1] || retryFailedCount[2]){
		NSLog(@"%@ retry error summary\n",deviceName);
		NSLog(@"Byte access retry count: %d\n",retryCount[0]);
		NSLog(@"Word access retry count: %d\n",retryCount[1]);
		NSLog(@"Long access retry count: %d\n",retryCount[2]);
		NSLog(@"\n");
		NSLog(@"%@ retry failed error summary\n",deviceName);
		NSLog(@"Byte access retry failed count: %d\n",retryFailedCount[0]);
		NSLog(@"Word access retry failed count: %d\n",retryFailedCount[1]);
		NSLog(@"Long access retry failed count: %d\n",retryFailedCount[2]);
	}
}

-(void)printConfigurationData
{
    // read PCI configuration registers
    PCIConfigStructUser pciData = {{0}};
    
    unsigned maxAddress = 0x3f;
    [self getPCIConfigurationData:maxAddress withDataPtr:&pciData];
    
    NSLog(@"%@ Specific Configuration Values Follow:\n",deviceName);
    unsigned short vendorID = (unsigned short)pciData.int32[0];
    NSLog(@"PCI Configuration - Vendor ID: 0x%04x\n", vendorID);
    unsigned short deviceID = (unsigned short)Swap16Bits(pciData.int32[0]);
    NSLog(@"PCI Configuration - Device ID: 0x%04x\n",deviceID);
    NSLog(@"PCI Configuration - Command Register: 0x%04x\n",
          0x0000ffff&(unsigned short)pciData.int32[kIOPCIConfigCommand/4]);
    NSLog(@"PCI Configuration - Status Register: 0x%04x\n",
          (unsigned short)pciData.int32[kIOPCIConfigStatus/4]>>16);
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
    
    // make sure have a Bit3 by checking Vendor & Device IDs
    if( vendorID != [self vendorID] ) {
        NSLog(@"*** Invalid Vendor ID, Got: 0x%04x ***\n",vendorID);
    }
    else NSLog(@"Device is %@\n",[self decodeDeviceName:deviceID]);
    
    // get PCI assigned values
    NSLog(@"Getting PCI Assigned Values\n");
    unsigned char cdata = 0;
    [self getPCIBusNumber:&cdata];
    NSLog(@"PCI Assigned Bus Number: 0x%02x\n",cdata);
    
    [self getPCIDeviceNumber:&cdata];
    NSLog(@"PCI Slot: 0x%02x\n",cdata-1);
    
    [self getPCIFunctionNumber:&cdata];
    NSLog(@"PCI Assigned Function Number: 0x%02x\n",cdata);
    
}

- (NSString*) decodeDeviceName:(unsigned short) deviceID
{
    int i;
    for(i=0;i<kNumPciDevices;i++){
        if(pciDevices[i].deviceID == deviceID){
            return [NSString stringWithFormat:@"Bit3 %@",pciDevices[i].deviceName];
        }
    }
    return @"Bit3";
}

-(void)printStatus
{
    unsigned char cdata;
    
    NSString* progressString;
    
    @try {
        progressString = @"Checking Status";
        [self checkStatusErrors];
        
        // check Bit3 status
        NSLog(@"Clearing %@ Status Register & PR Interrupt\n",deviceName);
        cdata = 0xc0;
        progressString = @"Writing CSR";
        [self writeCSRRegister:PCIVME_CSR_LOCAL_COMMAND_OFFSET withData:cdata];
        
        progressString = @"Reading CSR";
        [self readCSRRegister:PCIVME_CSR_LOCAL_STATUS_OFFSET withDataPtr:&cdata];
        
        NSLog(@"Local %@ CSR Status Register Offset: 0x%02x, Data: 0x%02x\n",deviceName,PCIVME_CSR_LOCAL_STATUS_OFFSET,cdata);
        progressString = @"Checking Status";
        
        NSLog(@"*** VME Bus Power On ***\n");
        cdata = [self getAdapterID];
        NSLog(@"*** Adapter ID = 0x%02x (should be 0x83) ***\n",cdata);
        
        cdata = [self getLocalStatus];
        NSLog(@"*** Adapter Local Status = 0x%02x ***\n",cdata);
    }
	@catch(NSException* localException) {
        NSLog(@"Check Status Failed: %@");
        [localException raise];
    }
}

#pragma mark ¥¥¥NSOrderedObjHolding Protocol
- (int) maxNumberOfObjects			{ return 10; }
- (int) objWidth					{ return 16; }
- (int) groupSeparation				{ return 0; }
- (NSString*) nameForSlot:(int)aSlot	{ return [NSString stringWithFormat:@"LAM Slot %d",aSlot]; }
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj { return NO;}

- (NSRange) legalSlotsForObj:(id)anObj
{
	return NSMakeRange(0,[self maxNumberOfObjects]);
}

- (int) slotAtPoint:(NSPoint)aPoint 
{
	return floor(((int)aPoint.y)/[self objWidth]);
}

- (int) slotForObject:(id)anObj
{
	return [anObj slot];
}

- (NSPoint) pointForSlot:(int)aSlot 
{
	return NSMakePoint(0,aSlot*[self objWidth]);
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
	[anObj setSlot: aSlot];
	[anObj moveTo:[self pointForSlot:aSlot]];
}
- (int) slotForObj:(id)anObj
{
	return [anObj slot];
}
- (int) numberSlotsNeededFor:(id)anObj
{
	return [anObj numberSlotsUsed];
}

@end

