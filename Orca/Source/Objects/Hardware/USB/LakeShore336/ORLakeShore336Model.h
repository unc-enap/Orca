//
//  ORLakeShore336Model.h
//  Orca
//  Created by Mark Howe on Mon, May 6, 2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
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

#import "ORLakeShore336Model.h"
#import "ORUSB.h"
#import "ORGroup.h"
#import "ORAdcProcessing.h"

#define kLakeShore336UseUSB	0
#define kLakeShore336UseIP	1

#define ORLakeShore336ConnectionError	@"ORLakeShore336ConnectionError"
#define kLakeShore336Port 7777

@class NetSocket;
@class ORUSBInterface;
@class ORAlarm;
@class ORSafeQueue;

@interface ORLakeShore336Model : ORGroup <USBDevice,ORAdcProcessing> {
	NSLock*         localLock;
	ORUSBInterface* usbInterface;
    int             connectionProtocol;
    NSString*       ipAddress;
    BOOL            usbConnected;
    BOOL            ipConnected;
	NetSocket*      socket;
    BOOL            canChangeConnectionProtocol;
    NSString*       serialNumber;
	ORAlarm*        noUSBAlarm;
	BOOL            okToCheckUSB;
	BOOL			isValid;
	ORSafeQueue*	cmdQueue;
	id				lastRequest;
	ORAlarm*		timeoutAlarm;
	int				timeoutCount;
    int             pollTime;
   
    NSMutableArray* inputs;
    NSMutableArray* heaters;
    
}

- (id) lastRequest;
- (void) setLastRequest:(id)aCmd;
- (void) makeUSBConnectors;
- (void) makeGPIBConnectors;
- (void) adjustConnectors:(BOOL)force;
- (id) getUSBController;
- (NSArray*) usbInterfaces;
- (void) checkNoUsbAlarm;

#pragma mark ***Accessors
- (BOOL) isValid;
- (int)  pollTime;
- (void) setPollTime:(int)aPollTime;
- (ORUSBInterface*) usbInterface;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (BOOL) canChangeConnectionProtocol;
- (void) setCanChangeConnectionProtocol:(BOOL)aCanChangeConnectionProtocol;
- (NetSocket*) socket;
- (void) setSocket:(NetSocket*)aSocket;
- (BOOL) ipConnected;
- (void) setIpConnected:(BOOL)aIpConnected;
- (BOOL) usbConnected;
- (void) setUsbConnected:(BOOL)aUsbConnected;
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;
- (int) connectionProtocol;
- (void) setConnectionProtocol:(int)aConnectionProtocol;
- (void) addCmdToQueue:(NSString*)aCmd;

- (NSUInteger) vendorID;
- (NSUInteger) productID;
- (NSString*) usbInterfaceDescription;
- (void) connectionChanged;
- (void) setInputs:(NSMutableArray*)anArray;
- (void) setHeaters:(NSMutableArray*)anArray;
- (id)   input:(int)anIndex;
- (id)   heater:(int)anIndex;
- (NSMutableArray*)inputs;
- (NSMutableArray*)heaters;
- (BOOL) isConnected;
- (BOOL) anyInputsUsingTimeRate:(id)aTimeRate;
- (BOOL) anyHeatersUsingTimeRate:(id)aTimeRate;

#pragma mark •••Cmd Handling
- (id) nextCmd;
- (void) cancelTimeout;
- (void) startTimeout:(int)aDelay;
- (void) setTimeoutCount:(int)aValue;
- (void) timeout;
- (void) clearTimeoutAlarm;
- (void) postTimeoutAlarm;
- (void) recoverFromTimeout;
- (int) timeoutCount;

- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;
- (void) readFromDevice;
- (void) writeToDevice: (NSString*) aCommand;

- (void) readIDString;
- (void) systemTest;
- (void) resetAndClear;
- (void) pollHardware;
- (void) queryAll;
- (void) loadHeaterParameters;
- (void) loadInputParameters;

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket;
- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount;
- (void) netsocketDisconnected:(NetSocket*)inNetSocket;

#pragma mark ***Utilities
- (void) connect;
- (void) connectUSB;
- (void) connectIP;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Adc Processing Protocol
- (void) processIsStarting;
- (void) processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel;
- (double) convertedValue:(int)channel;
- (double) maxValueForChan:(int)channel;

@end

extern NSString* ORLakeShore336SerialNumberChanged;
extern NSString* ORLakeShore336CanChangeConnectionProtocolChanged;
extern NSString* ORLakeShore336IpConnectedChanged;
extern NSString* ORLakeShore336UsbConnectedChanged;
extern NSString* ORLakeShore336IpAddressChanged;
extern NSString* ORLakeShore336ConnectionProtocolChanged;
extern NSString* ORLakeShore336USBInterfaceChanged;
extern NSString* ORLakeShore336Lock;
extern NSString* ORLakeShore336PortClosedAfterTimeout;
extern NSString* ORLakeShore336TimeoutCountChanged;
extern NSString* ORLakeShore336IsValidChanged;
extern NSString* ORLakeShore336PollTimeChanged;

