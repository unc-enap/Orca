//
//  ORPulser33500Model.h
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

#pragma mark •••Imported Files

#import "ORGpibDeviceModel.h"
#import "ORUSB.h"

#define kPulser33500UseGPIB	0
#define kPulser33500UseUSB	1
#define kPulser33500UseIP		2

#define kPulser33500Port 5025

@class NetSocket;
@class ORUSBInterface;
@class ORAlarm;


@interface ORPulser33500Model : ORGpibDeviceModel <USBDevice> 
{
	ORUSBInterface* usbInterface;
    NSMutableArray* channels;
    int				connectionProtocol;
    NSString*		ipAddress;
    BOOL			usbConnected;
    BOOL			ipConnected;
	NetSocket*		socket;
	BOOL			mEOT;
    BOOL			canChangeConnectionProtocol;
    NSString*		serialNumber;
	ORAlarm*		noUSBAlarm;
	BOOL			okToCheckUSB;
	BOOL			waitForAsyncDownloadDone;
	BOOL			waitForGetWaveformsLoadedDone;
	BOOL			loading;
    BOOL            showInKHz;
}

- (void) makeUSBConnectors;
- (void) makeGPIBConnectors;
- (void) adjustConnectors:(BOOL)force;
- (id) getUSBController;
- (NSArray*) usbInterfaces;
- (void) checkNoUsbAlarm;
- (void) makeChannels;

#pragma mark ***Accessors
- (BOOL) showInKHz;
- (void) setShowInKHz:(BOOL)aFlag;
- (BOOL) loading;
- (void) setLoading:(BOOL)aState;
- (NSMutableArray*)channels;
- (void) setChannels:(NSMutableArray*)someChannels;
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
- (BOOL) waitForGetWaveformsLoadedDone;
- (void) setWaitForGetWaveformsLoadedDone:(BOOL)aState;
- (void) asyncDownloadFinished;

- (BOOL) waitForAsyncDownloadDone;
- (void) setWaitForAsyncDownloadDone:(BOOL)aState;

- (NSArray*) vendorIDs;
- (NSArray*) productIDs;
- (NSString*) usbInterfaceDescription;
- (void) logSystemResponse;

- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;

#pragma mark •••HW Commands
- (NSString*) readIDString;
- (void) resetAndClear;
- (void) systemTest;
- (void) writeToDevice: (NSString*) aCommand;
- (void) initHardware;

#pragma mark ***Delegate Methods
//- (void) netsocketConnected:(NetSocket*)inNetSocket;
//- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount;
//- (void) netsocketDisconnected:(NetSocket*)inNetSocket;

#pragma mark ***Comm methods
- (int32_t) writeReadDevice: (NSString*) aCommand data: (char*) aData maxLength: (uint32_t) aMaxLength;
- (int32_t) readFromDevice: (char*) aData maxLength: (uint32_t) aMaxLength;
- (void) writeToDevice: (NSString*) aCommand;

#pragma mark ***Utilities
- (void) connect;
- (void) connectUSB;
- (void) connectIP;
- (void) mainThreadSocketSend:(NSString*)aCommand;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORPulser33500SerialNumberChanged;
extern NSString* ORPulser33500CanChangeConnectionProtocolChanged;
extern NSString* ORPulser33500IpConnectedChanged;
extern NSString* ORPulser33500UsbConnectedChanged;
extern NSString* ORPulser33500IpAddressChanged;
extern NSString* ORPulser33500ConnectionProtocolChanged;
extern NSString* ORPulser33500USBInterfaceChanged;
extern NSString* ORPulser33500LoadingChanged;
extern NSString* ORPulser33500ShowInKHzChanged;
extern NSString* ORPulser33500Lock;

