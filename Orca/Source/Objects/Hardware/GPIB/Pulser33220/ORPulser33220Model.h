//
//  ORPulser33220Model.h
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
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

#define kHPPulserUseGPIB 0
#define kHPPulserUseUSB	1
#define kHPPulserUseIP	2

#define kHPPulserPort 5025

@class NetSocket;
@class ORUSBInterface;
@class ORAlarm;

@interface ORPulser33220Model : ORHPPulserModel <USBDevice> {
	NSLock* localLock;
	ORUSBInterface* usbInterface;
    int connectionProtocol;
    NSString* ipAddress;
    BOOL ipConnected;
	NetSocket* socket;
	BOOL mEOT;
    BOOL canChangeConnectionProtocol;
	BOOL waitForAsyncDownloadDone;
	BOOL waitForGetWaveformsLoadedDone;
	NSArray* allWaveFormsInMemory;
    NSString* serialNumber;
	ORAlarm*  noUSBAlarm;
	BOOL okToCheckUSB;
}

- (void) makeUSBConnectors;
- (void) makeGPIBConnectors;
- (void) adjustConnectors:(BOOL)force;
- (id) getUSBController;
- (NSArray*) usbInterfaces;
- (void) checkNoUsbAlarm;

#pragma mark ***Accessors
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
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;
- (int) connectionProtocol;
- (void) setConnectionProtocol:(int)aConnectionProtocol;

- (NSUInteger) vendorID;
- (NSUInteger) productID;
- (NSString*) usbInterfaceDescription;


- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;
- (void) sendRemoteCommand;
- (void) sendLocalCommand;
- (void) asyncDownloadFinished;

// Overloading these functions since the command syntax has changed.
- (void) writeBurstRate:(float)value;
- (void) writeBurstState:(BOOL)value;
- (void) writeBurstCycles:(int)value;
- (void) writeBurstPhase:(int)value;
- (unsigned int) maxNumberOfWaveformPoints;

#pragma mark ***Delegate Methods
//- (void) netsocketConnected:(NetSocket*)inNetSocket;
//- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount;
//- (void) netsocketDisconnected:(NetSocket*)inNetSocket;

#pragma mark ***Utilities
- (void) connect;
- (void) connectUSB;
- (void) connectIP;
- (void) mainThreadSocketSend:(NSString*)aCommand;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORPulser33220ModelSerialNumberChanged;
extern NSString* ORPulser33220ModelCanChangeConnectionProtocolChanged;
extern NSString* ORPulser33220ModelIpConnectedChanged;
extern NSString* ORPulser33220ModelIpAddressChanged;
extern NSString* ORPulser33220ModelConnectionProtocolChanged;
extern NSString* ORPulser33220ModelUSBInterfaceChanged;
