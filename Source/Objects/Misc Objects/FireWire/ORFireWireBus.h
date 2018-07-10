//
//  ORFireWireBus.h
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
#import <IOKit/firewire/IOFireWireLib.h>
#import <mach/mach.h>

@class ORFireWireInterface;

@interface ORFireWireBus : NSObject {
	@private
		NSMutableDictionary* devices;
}
#pragma mark ¥¥¥initialization
- (id) init;
- (void) dealloc;

#pragma mark ¥¥¥accessors
- (NSMutableDictionary*) devices;
- (void) setDevices:(NSMutableDictionary*)aDeviceDict;

#pragma mark ¥¥¥HW access
- (ORFireWireInterface*) getFireWireInterface:(unsigned long)aVendorID;
- (void) getDevicesWithVenderID:(unsigned long)aVendorID;
@end