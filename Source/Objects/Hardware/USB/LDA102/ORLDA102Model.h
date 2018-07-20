//
//  ORLDA102Model.h
//  Orca
//
//  Created by Mark Howe on Wed Feb 18, 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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

#import "ORHPPulserModel.h"
#import "ORUSB.h"

@class ORUSBInterface;
@class ORAlarm;

@interface ORLDA102Model : OrcaObject <USBDevice> {
	NSLock* localLock;
	ORUSBInterface* usbInterface;
    NSString* serialNumber;
	ORAlarm*  noUSBAlarm;
	ORAlarm*  noDriverAlarm;
    float	attenuation;
    float	stepSize;
    float	rampStart;
    float	rampEnd;
    short	dwellTime;
    int		idleTime;
    BOOL	repeatRamp;
    float	rampValue;
    BOOL	rampRunning;

	//Thread variables
	BOOL threadRunning;
	BOOL timeToStop;
}

- (id) getUSBController;

#pragma mark ***Accessors
- (BOOL) rampRunning;
- (void) setRampRunning:(BOOL)aRampRunning;
- (float) rampValue;
- (void) setRampValue:(float)aRampValue;
- (BOOL) repeatRamp;
- (void) setRepeatRamp:(BOOL)aRepeatRamp;
- (int) idleTime;
- (void) setIdleTime:(int)aIdleTime;
- (short) dwellTime;
- (void) setDwellTime:(short)aDwellTime;
- (float) rampEnd;
- (void) setRampEnd:(float)aRampEnd;
- (float) rampStart;
- (void) setRampStart:(float)aRampStart;
- (float) stepSize;
- (void) setStepSize:(float)aStepSize;
- (float) attenuation;
- (void) setAttenuation:(float)aAttenuation;
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

#pragma mark ***HW Access
- (void) writeCommand:(unsigned char)cmdWord count:(unsigned char)count value:(uint32_t)aValue;
- (void) loadAttenuation;
- (void) startRamp;
- (void) stopRamp;
- (void) packData:(unsigned char*)data withLong:(uint32_t)aValue;

#pragma mark ***Thread methods
- (void) startReadThread;
- (void) stopReadThread;
- (void) decodeResponse:(unsigned char*)data;
- (void) responseThread;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORLDA102ModelRampRunningChanged;
extern NSString* ORLDA102ModelRampValueChanged;
extern NSString* ORLDA102ModelRepeatRampChanged;
extern NSString* ORLDA102ModelIdleTimeChanged;
extern NSString* ORLDA102ModelDwellTimeChanged;
extern NSString* ORLDA102ModelRampEndChanged;
extern NSString* ORLDA102ModelRampStartChanged;
extern NSString* ORLDA102ModelStepSizeChanged;
extern NSString* ORLDA102ModelAttenuationChanged;
extern NSString* ORLDA102ModelSerialNumberChanged;
extern NSString* ORLDA102ModelUSBInterfaceChanged;
extern NSString* ORLDA102ModelRelayChanged;
extern NSString* ORLDA102ModelLock;

