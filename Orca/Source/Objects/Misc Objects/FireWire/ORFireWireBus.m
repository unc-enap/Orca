//
//  ORFireWireBus.m
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


#import "ORFireWireBus.h"
#import "ORFireWireInterface.h"

@implementation ORFireWireBus

#pragma mark ¥¥¥initialization
- (id) init
{
	self = [super init];
	return self;
}
- (void) dealloc
{
	[devices release];
	[super dealloc];
}

#pragma mark ¥¥¥accessors
- (NSMutableDictionary*) devices
{
	return devices;
}

- (void) setDevices:(NSMutableDictionary*)aDeviceDict
{
	[aDeviceDict retain];
	[devices release];
	devices = aDeviceDict;
}

- (ORFireWireInterface*) getFireWireInterface:(unsigned long)aVendorID
{
	//io_object_t service = [[[devices objectForKey:[NSNumber numberWithLong:aVendorID]] objectAtIndex:0] longValue];
	//if(!service){
	[self getDevicesWithVenderID:aVendorID];
	io_object_t service = [[[devices objectForKey:[NSNumber numberWithLong:aVendorID]] objectAtIndex:0] longValue];
	//}
	if(!service)return nil;
	else return [[[ORFireWireInterface alloc] initWithService:service] autorelease];
	
}

#pragma mark ¥¥¥HW access
- (void) getDevicesWithVenderID:(unsigned long)aVendorID
{    
	mach_port_t				masterDevicePort = 0;	// Master port
	io_iterator_t			enumerator		 = 0;	// Enumerator of matching kFWDevType devices
	
	IOReturn				result;					// Result of function
	NSMutableDictionary*	matchDictionary;		// Dictionary of kFWDevType devices
	
	@try {
		// Get the master port
		result = IOMasterPort( bootstrap_port, &masterDevicePort );
		if ( result != kIOReturnSuccess ) {
			NSLog(@"Unable to access master system I/O port\n" );
			[NSException raise:@"IOKit Port Error" format:@"Unable to access master system I/O port"];
		}
		
		
		matchDictionary = (NSMutableDictionary*)IOServiceMatching("IOFireWireDevice");
		[matchDictionary setObject:[NSNumber numberWithLong:aVendorID] forKey:@"Vendor_ID"];
		
		if ( matchDictionary == nil ) {
			// No matching dictionary -- fatal error
			NSLog(@"Unable to obtain I/O matching dictionary\n" );
			[NSException raise:@"IOKit Matching Error" format:@"Unable to match firewire device vendorID %lu",aVendorID];
		}
		
		// Get a registry enumerator for all matching kFWDevType devices
		result = IOServiceGetMatchingServices( masterDevicePort, (CFMutableDictionaryRef)matchDictionary, &enumerator );
		
		if ( result != kIOReturnSuccess ) {
			// Can't get registry enumerator -- fatal error
			NSLog(@"Unable to obtain matching I/O services for FireWire Device\n" );
			[NSException raise:@"IOKit Matching Services Error" format:@"Unable to obtain matching I/O services for vendorID %lu",aVendorID];
		}
		
		// Create a list of the matched devices
		io_object_t			newDevice;			// Matched device
		NSMutableArray* deviceList = [NSMutableArray array];
		while( (newDevice = IOIteratorNext( enumerator )) ) {
			[deviceList addObject:[NSNumber numberWithLong:newDevice]];
		}
		if([deviceList count]){
			if(!devices)[self setDevices:[NSMutableDictionary dictionary]];
			[devices setObject:deviceList forKey:[NSNumber numberWithLong:aVendorID]];
		}
		
		
	}
	@catch(NSException* localException){
	}
	
    // Clean up
	if ( enumerator ) {
        IOObjectRelease( enumerator );
        enumerator = 0;
    }
    if ( masterDevicePort ) {
        mach_port_deallocate( mach_task_self(), masterDevicePort );
        masterDevicePort = 0;
    }
}

@end
