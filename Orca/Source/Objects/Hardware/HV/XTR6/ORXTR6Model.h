//
//  ORXTR6Model.h
//  Orca
//
//  Created by Mark Howe on Jan 15, 2014 2003.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
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

#import "ORSerialPortWithQueueModel.h"
#import "ORUSB.h"

#define kHPXTR6UseRS232	0
#define kHPXTR6UseUSB	1
#define kHPXTR6UseIP	2

#define kXTR6Port       5025
#define kXTR6CmdTimeout 2

@class NetSocket;
@class ORUSBInterface;
@class ORAlarm;

@interface ORXTR6Model : ORSerialPortWithQueueModel <USBDevice> {
    //------RS232------
    NSMutableString* buffer;
    
    //------USB------
    NSString*       serialNumber;
	ORUSBInterface* usbInterface;
	ORAlarm*        noUSBAlarm;
	BOOL            okToCheckUSB;
    
    //------IP------
    NSString*       ipAddress;
    BOOL            ipConnected;
	NetSocket*      socket;
    
    
    //------other variables------
    int         connectionProtocol;
    BOOL        canChangeConnectionProtocol;
	NSLock*     localLock;
    int         channelAddress;
    float       targetVoltage;
    float       voltage;
    float       current;
    BOOL        onOffState;
}

- (void)     adjustConnectors:(BOOL)force;
- (id)       getUSBController;
- (NSArray*) usbInterfaces;
- (void)     checkNoUsbAlarm;
- (void)     connect;

#pragma mark ***USB
- (void)            makeUSBConnectors;
- (NSUInteger)   vendorID;
- (NSUInteger)   productID;
- (void)            connectUSB;
- (NSString*)       usbInterfaceDescription;
- (void)            interfaceAdded:(NSNotification*)aNote;
- (void)            interfaceRemoved:(NSNotification*)aNote;
- (ORUSBInterface*) usbInterface;
- (void)            setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*)       serialNumber;
- (void)            setSerialNumber:(NSString*)aSerialNumber;

#pragma mark ***IP
- (NetSocket*)  socket;
- (void)        setSocket:(NetSocket*)aSocket;
- (BOOL)        ipConnected;
- (void)        setIpConnected:(BOOL)aIpConnected;
- (NSString*)   ipAddress;
- (void)        setIpAddress:(NSString*)aIpAddress;
- (void)        connectIP;

#pragma mark ***RS232
- (void) setUpPort;

#pragma mark ***Accessors
- (BOOL)    onOffState;
- (void)    setOnOffState:(BOOL)aState;
- (float)   current;
- (void)    setCurrent:(float)aCurrent;
- (float)   voltage;
- (void)    setVoltage:(float)aVoltage;
- (float)   targetVoltage;
- (void)    setTargetVoltage:(float)aTarget;
- (int)     channelAddress;
- (void)    setChannelAddress:(int)aChannelAddress;
- (BOOL)    canChangeConnectionProtocol;
- (void)    setCanChangeConnectionProtocol:(BOOL)aCanChangeConnectionProtocol;
- (int)     connectionProtocol;
- (void)    setConnectionProtocol:(int)aConnectionProtocol;

#pragma mark ***Delegate Methods (IP)
- (void) netsocketConnected:(NetSocket*)inNetSocket;
- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount;
- (void) netsocketDisconnected:(NetSocket*)inNetSocket;
- (BOOL) isConnected;

#pragma mark ***Commands
- (void) selectDevice;
- (void) loadParams;
- (void) readIDString;
- (void) systemTest;
- (void) turnOnPower;
- (void) turnOffPower;

#pragma mark ***Low Level R/W
- (void) readFromDevice:  (char*)     aData maxLength: (long)  aMaxLength;
- (void) writeToDevice:   (NSString*) aCommand;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORXTR6ModelOnOffStateChanged;
extern NSString* ORXTR6ModelCurrentChanged;
extern NSString* ORXTR6ModelVoltageChanged;
extern NSString* ORXTR6ModelTargetVoltageChanged;
extern NSString* ORXTR6ModelChannelAddressChanged;
extern NSString* ORXTR6ModelSerialNumberChanged;
extern NSString* ORXTR6ModelCanChangeProtocolChanged;
extern NSString* ORXTR6ModelIpConnectedChanged;
extern NSString* ORXTR6ModelIpAddressChanged;
extern NSString* ORXTR6ModelConnectionProtocolChanged;
extern NSString* ORXTR6ModelUSBInterfaceChanged;
extern NSString* ORXTR6ModelConnectionError;

extern NSString* ORXTR6Lock;


