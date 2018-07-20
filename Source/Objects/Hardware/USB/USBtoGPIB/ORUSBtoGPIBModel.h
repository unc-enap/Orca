//
//  ORUSBtoGPIBModel.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 26 2007.
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


#pragma mark ¥¥¥Imported Files

//#import "OrcaObject.h"
#import "ORUSB.h"

@class ORUSBInterface;
@class ORAlarm;

@interface ORUSBtoGPIBModel : OrcaObject <USBDevice> {
	NSRecursiveLock* theHWLock;
	ORUSBInterface* usbInterface;
    NSString* serialNumber;
	ORAlarm*  noUSBAlarm;
	ORAlarm*  noDriverAlarm;

    char gpibAddress;
    NSString* command;
	BOOL	enableEOT;
	int		lastSelectedAddress;
	int	fd;
}

- (id) getUSBController;

#pragma mark ***Accessors
- (id) getGpibController;
- (BOOL) isConnected;
- (void) enableEOT:(short)aPrimaryAddress state: (BOOL) state;
- (void) setupDevice: (short) aPrimaryAddress secondaryAddress: (short) aSecondaryAddress;
- (void) selectDevice:(short) aPrimaryAddress;
- (void) writeToDevice: (short) aPrimaryAddress command: (NSString*) aCommand;
- (int32_t) readFromDevice: (short) aPrimaryAddress data: (char*) aData maxLength: (int32_t) aMaxLength;
- (int32_t) writeReadDevice: (short) aPrimaryAddress command: (NSString*) aCommand data: (char*) aData
               maxLength: (int32_t) aMaxLength;

- (NSString*) command;
- (void) setCommand:(NSString*)aCommand;
- (char) gpibAddress;
- (void) setGpibAddress:(char)anAddress;
- (ORUSBInterface*) usbInterface;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (NSUInteger) vendorID;
- (NSUInteger) productID;
- (NSString*) usbInterfaceDescription;

- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;

#pragma mark ¥¥¥HW Access
- (void) sendCommand;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORUSBtoGPIBModelCommandChanged;
extern NSString* ORUSBtoGPIBModelAddressChanged;
extern NSString* ORUSBtoGPIBModelSerialNumberChanged;
extern NSString* ORUSBtoGPIBModelUSBInterfaceChanged;

