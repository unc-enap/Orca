//
//  ORVXI11HardwareFinder.h
//  Orca
//
//  Created by Michael Marino on 6 Nov 2011
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files

#pragma mark •••Forward Declarations
@class NetSocket;
#pragma mark •••Definitions

@interface ORVXI11HardwareFinder : NSObject
{
    NSMutableDictionary* availableHardware;
}

+ (ORVXI11HardwareFinder*) sharedVXI11HardwareFinder;

- (NSDictionary*) availableHardware;
- (void) refresh;

@end


@interface ORVXI11IPDevice : NSObject
{
    NSString* manufacturer;
    NSString* model;
    NSString* serialNumber;
    NSString* version;    
    NSString* ipAddress;
}

// Returns a device with a string
+ (id) deviceForString:(NSString*) astr;
+ (id) deviceForString:(NSString*) astr withSeparationWithString:(NSString*) sep;

@property (retain) NSString* manufacturer;
@property (retain) NSString* model;
@property (retain) NSString* serialNumber;
@property (retain) NSString* version;
@property (retain) NSString* ipAddress;

@end
extern NSString* ORHardwareFinderAvailableHardwareChanged;

