//
//  ORPxi8336MacModel.h
//  Orca
//
//  Created by Mark Howe on Thurs Aug 26 2010
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
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
#import <IOKit/IOTypes.h>
#import <IOKit/iokitmig.h>
#import <IOKit/IOKitLib.h>
#import <ApplicationServices/ApplicationServices.h>
#import "ORPciCard.h"
#import "OROrderedObjHolding.h"

#pragma mark •••Forward Definitions
@class ORAlarm;

@interface ORPxi8336MacModel : ORPciCard <OROrderedObjHolding>
{
    @private
        NSLock*			theHWLock;
		NSString*       deviceName;
        unsigned int 	rwAddress;
        unsigned int 	writeValue;
        unsigned int	readWriteType;
                
        ORAlarm*		noHardwareAlarm;
        ORAlarm*		noDriverAlarm;

		BOOL			doRange;
		unsigned short	rangeToDo;
}

#pragma mark •••Inialization
- (id) init;
- (void) dealloc;
- (void) makeConnectors;
- (void) setUpImage;
- (void) wakeUp;
- (void)sleep;
- (void) makeMainController;
- (unsigned short) vendorID;
- (const char*) serviceClassName;
- (NSString*) driverPath;

#pragma mark •••Accessors
- (void) setDeviceName: (NSString*) aDeviceName;
- (NSString *) deviceName;
- (unsigned short) rangeToDo;
- (void) setRangeToDo:(unsigned short)aRange;
- (BOOL) doRange;
- (void) setDoRange:(BOOL)aDoRange;
- (unsigned long) rwAddress;
- (void) setRwAddress:(unsigned long)aValue;
- (unsigned long) writeValue;
- (void) setWriteValue:(unsigned long)aValue;
- (unsigned int) readWriteType;
- (void) setReadWriteType:(unsigned int)aValue;

#pragma mark •••Hardware Access
- (void)  checkCratePower;
- (void) checkStatusErrors;
- (void) resetContrl;
- (void) pxiSysReset:(unsigned char *)status;

- (void) readLongBlock:(unsigned long *) readAddress
             atAddress:(unsigned long) pxiAddress
             numToRead:(unsigned int) numberLongs;

//a special read for reading fifos that reads one address multiple times
- (void) readLong:(unsigned long *) readAddress
		atAddress:(unsigned long) pxiAddress
	  timesToRead:(unsigned int) numberLongs;


- (void) writeLongBlock:(unsigned long *) writeAddress
              atAddress:(unsigned long) pxiAddress
             numToWrite:(unsigned int) numberLongs;

- (void) readByteBlock:(unsigned char *) readAddress
             atAddress:(unsigned long) pxiAddress
             numToRead:(unsigned int) numberBytes;

- (void) writeByteBlock:(unsigned char *) writeAddress
              atAddress:(unsigned long) pxiAddress
             numToWrite:(unsigned int) numberBytes;

-  (void) readWordBlock:(unsigned short *) readAddress
              atAddress:(unsigned long) pxiAddress
              numToRead:(unsigned int) numberWords;

-  (void) writeWordBlock:(unsigned short *) writeAddress
               atAddress:(unsigned long) pxiAddress
              numToWrite:(unsigned int) numberWords;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

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
extern NSString* ORPxi8336MacModelRangeChanged;
extern NSString* ORPxi8336MacModelDoRangeChanged;
extern NSString* ORPxi8336MacRWAddressChangedNotification;
extern NSString* ORPxi8336MacWriteValueChangedNotification;
extern NSString* ORPxi8336MacRWTypeChangedNotification;
extern NSString* ORPxi8336MacDeviceNameChangedNotification;
extern NSString* ORPxi8336MacLock;
