//
//  ORSIS3150Model.h
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORVmeAdapter.h"
#import "ORUSB.h"

@class ORUSBInterface;

@interface ORSIS3150Model :  ORVmeAdapter <USBDevice>
{
	ORUSBInterface* usbInterface;
    NSString* serialNumber;
	ORAlarm*  noUSBAlarm;
	unsigned int 	rwAddress;
	unsigned int 	writeValue;
	unsigned int	readWriteType;
	unsigned int 	rwAddressModifier;
	unsigned int 	readWriteIOSpace;
	BOOL			doRange;
	unsigned short	rangeToDo;
	NSString* inConnectorName;
	ORConnector*  inConnector; //we won't draw this connector so we have to keep a reference to it
	NSString* outConnectorName;
	ORConnector*  outConnector; //we won't draw this connector so we have to keep a reference to it
}
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;

#pragma mark •••Accessors
- (ORConnector*) inConnector;
- (void) setInConnector:(ORConnector*)aConnector;
- (ORConnector*) outConnector;
- (void) setOutConnector:(ORConnector*)aConnector;
- (unsigned long) rwAddress;
- (void) setRwAddress:(unsigned long)aValue;
- (unsigned long) writeValue;
- (void) setWriteValue:(unsigned long)aValue;
- (unsigned int) rwAddressModifier;
- (void) setRwAddressModifier:(unsigned int)aValue;
- (unsigned int) readWriteIOSpace;
- (void) setReadWriteIOSpace:(unsigned int)aValue;
- (unsigned int) readWriteType;
- (void) setReadWriteType:(unsigned int)aValue;
- (unsigned short) rwAddressModifierValue;
- (unsigned short) rwIOSpaceValue;
- (unsigned short) rangeToDo;
- (void) setRangeToDo:(unsigned short)aRange;
- (BOOL) doRange;
- (void) setDoRange:(BOOL)aDoRange;

#pragma mark ***USB Stuff
- (id) getUSBController;
- (ORUSBInterface*) usbInterface;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (NSUInteger) vendorID;
- (NSUInteger) productID;
- (NSString*) usbInterfaceDescription;
- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;
- (void) checkUSBAlarm;
- (NSString*) title;

#pragma mark •••Hardware Access
- (id) controllerCard;
- (void) resetContrl;
- (void) checkStatusErrors;

-(void) readLongBlock:(unsigned long *) readAddress
									atAddress:(unsigned int) vmeAddress
									numToRead:(unsigned int) numberLongs
								   withAddMod:(unsigned short) anAddressModifier
					   usingAddSpace:(unsigned short) anAddressSpace;

-(void) writeLongBlock:(unsigned long *) writeAddress
										atAddress:(unsigned int) vmeAddress
										numToWrite:(unsigned int) numberLongs
									withAddMod:(unsigned short) anAddressModifier
						   usingAddSpace:(unsigned short) anAddressSpace;

-(void) readByteBlock:(unsigned char *) readAddress
									atAddress:(unsigned int) vmeAddress
									numToRead:(unsigned int) numberBytes
								   withAddMod:(unsigned short) anAddressModifier
					   usingAddSpace:(unsigned short) anAddressSpace;

-(void) writeByteBlock:(unsigned char *) writeAddress
										atAddress:(unsigned int) vmeAddress
										numToWrite:(unsigned int) numberBytes
									withAddMod:(unsigned short) anAddressModifier
						   usingAddSpace:(unsigned short) anAddressSpace;

-(void) readWordBlock:(unsigned short *) readAddress
									atAddress:(unsigned int) vmeAddress
									numToRead:(unsigned int) numberWords
								   withAddMod:(unsigned short) anAddressModifier
					   usingAddSpace:(unsigned short) anAddressSpace;

-(void) writeWordBlock:(unsigned short *) writeAddress
										atAddress:(unsigned int) vmeAddress
										numToWrite:(unsigned int) numberWords
									withAddMod:(unsigned short) anAddressModifier
						   usingAddSpace:(unsigned short) anAddressSpace;

- (int) usbTransaction: (ORUSBInterface*) device
			  outpacket: (void*)           outpacket
			   outbytes: (unsigned int)    outbytes
			   inpacket: (void*)           inpacket
				inbytes: (unsigned int)    inbytes;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORSIS3150USBInterfaceChanged;
extern NSString* ORSIS3150SerialNumberChanged;
extern NSString* ORSIS3150USBInterfaceChanged;
extern NSString* ORSIS3150RangeChanged;
extern NSString* ORSIS3150DoRangeChanged;
extern NSString* ORSIS3150RWAddressChanged;
extern NSString* ORSIS3150WriteValueChanged;
extern NSString* ORSIS3150RWAddressModifierChanged;
extern NSString* ORSIS3150RWIOSpaceChanged;
extern NSString* ORSIS3150RWTypeChanged;
extern NSString* ORSIS3150Lock;
