//
//  ORADU200Model.h
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

#import "ORHPPulserModel.h"
#import "ORUSB.h"
#import "ORBitProcessing.h"

@class ORUSBInterface;
@class ORAlarm;

@interface ORADU200Model : OrcaObject <USBDevice, ORBitProcessing> {
	NSLock* localLock;
	ORUSBInterface* usbInterface;
    NSString* serialNumber;
	ORAlarm*  noUSBAlarm;
	ORAlarm*  noDriverAlarm;
	BOOL	  relayState[4];
    unsigned short portA;
    unsigned short eventCounter[4];
    int debounce;
    int pollTime;

	//bit processing variables
	unsigned long processInputValue;  //snapshot of the inputs at start of process cycle
	unsigned long processOutputValue; //outputs to be written at end of process cycle
}

- (id) getUSBController;
- (void) checkUSBAlarm;

#pragma mark ***Accessors
- (void) formatCommand:(NSString*)aCommand buffer:(char*)data;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (int) debounce;
- (void) setDebounce:(int)aDebounce;
- (unsigned short) eventCounter:(unsigned short)index;
- (void) setEventCounter:(unsigned short)index withValue:(unsigned short)aEventCounter;
- (unsigned short) portA;
- (void) setPortA:(unsigned short)aValue;
- (ORUSBInterface*) usbInterface;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (NSUInteger) vendorID;
- (NSUInteger) productID;
- (NSString*) usbInterfaceDescription;
- (void) setRelayState:(unsigned short)index withValue:(BOOL)aState;
- (BOOL) relayState:(unsigned short)index;

- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;

#pragma mark ***Comm methods
- (void) pollHardware;
- (void) writeCommand:(NSString*)aCommand;
- (void) toggleRelay:(unsigned int)index;
- (void) closeRelay:(unsigned int)index;
- (void) openRelay:(unsigned int)index;
- (void) queryAll;
- (void) queryRelays;
- (void) queryPortA;
- (void) queryEventCounters;
- (void) sendDebounce;
- (void) queryDebounce;
- (void) readAndClear;
- (void) queryRelay:(int)i;

#pragma mark ¥¥¥Bit Processing Protocol
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORADU200ModelPollTimeChanged;
extern NSString* ORADU200ModelDebounceChanged;
extern NSString* ORADU200ModelEventCounterChanged;
extern NSString* ORADU200ModelPortAChanged;
extern NSString* ORADU200ModelSerialNumberChanged;
extern NSString* ORADU200ModelUSBInterfaceChanged;
extern NSString* ORADU200ModelRelayChanged;
extern NSString* ORADU200ModelLock;
extern NSString* ORADU200ModelSerialPortChanged;

