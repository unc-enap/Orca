//--------------------------------------------------------
// ORKJL2200IonGaugeModel
// Created by Mark  A. Howe on Fri Jul 22 2005
// Created by Mark  A. Howe on Thurs Apr 22 2010
// Copyright (c) 2010 University of North Caroline. All rights reserved.
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

#pragma mark ***Imported Files

@class ORSerialPort;
@class ORTimeRate;

#define kKJL2200IonGaugeOnMask	0x01
#define kKJL2200DegasOnMask		0x02
#define kKJL2200SetPoint1Mask	0x04
#define kKJL2200SetPoint2Mask	0x08
#define kKJL2200SetPoint3Mask	0x10
#define kKJL2200SetPoint4Mask	0x20

@interface ORKJL2200IonGaugeModel : OrcaObject
{
    @private
        NSString*       portName;
        BOOL            portWasOpen;
        ORSerialPort*   serialPort;
        uint32_t	dataId;
		uint32_t	timeMeasured;
		int				pollTime;
        NSMutableString*       buffer;
		BOOL			shipPressure;
		ORTimeRate*		timeRate;
		float			pressure;
		float			setPoint[4];
		float			setPointReadBack[4];
		int				sensitivity;
		float			emissionCurrent;
		float			degasTime;
		unsigned short	stateMask;
		int				pressureScale;
		float			pressureScaleValue;
		NSMutableArray*		cmdQueue;
		int sensitivityRead;
		float emissionRead;
		int degasTimeRead;
		NSString* lastRequest;
}

#pragma mark ***Initialization

- (id)   init;
- (void) dealloc;

- (void) registerNotificationObservers;
- (void) dataReceived:(NSNotification*)note;

#pragma mark ***Accessors
- (NSString*) lastRequest;
- (void) setLastRequest:(NSString*)aRequest;
- (int) degasTimeRead;
- (void) setDegasTimeRead:(int)aDegasTimeRead;
- (float) emissionRead;
- (void) setEmissionRead:(float)aEmissionRead;
- (int) sensitivityRead;
- (void) setSensitivityRead:(int)aSensitivityRead;
- (NSUInteger) queCount;
- (float) pressureScaleValue;
- (int) pressureScale;
- (void) setPressureScale:(int)aPressureScale;
- (void) setStateMask:(unsigned short)aMask;
- (unsigned short)stateMask;
- (int) degasTime;
- (void) setDegasTime:(int)aDegasTime;
- (float) emissionCurrent;
- (void) setEmissionCurrent:(float)aEmissionCurrent;
- (int) sensitivity;
- (void) setSensitivity:(int)aSensitivity;
- (float) setPoint:(int)index;
- (void) setSetPoint:(int)index withValue:(float)aSetPoint;
- (float) setPointReadBack:(int)index;
- (void) setSetPointReadBack:(int)index withValue:(float)aSetPoint;
- (float) pressure;
- (void) setPressure:(float)aPressure;
- (ORTimeRate*)timeRate;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (ORSerialPort*) serialPort;
- (void) setSerialPort:(ORSerialPort*)aSerialPort;
- (BOOL) portWasOpen;
- (void) setPortWasOpen:(BOOL)aPortWasOpen;
- (NSString*) portName;
- (void) setPortName:(NSString*)aPortName;
- (void) openPort:(BOOL)state;
- (uint32_t) timeMeasured;

#pragma mark ***Data Records
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSDictionary*) dataRecordDescription;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherKJL2200IonGauge;

- (BOOL) shipPressure;
- (void) setShipPressure:(BOOL)aState;
- (void) shipPressureValue;

#pragma mark ***Commands
- (void) enqueCmdData:(NSString*)aCommand;
- (void) initBoard;
- (void) readSettings;
- (void) readPressure;
- (void) pollPressure;
- (void) getStatus;
- (void) turnOn;
- (void) turnOff;
- (void) turnDegasOn;
- (void) turnDegasOff;
- (void) sendReset;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORKJL2200IonGaugeModelSetPointReadChanged;
extern NSString* ORKJL2200IonGaugeModelDegasTimeReadChanged;
extern NSString* ORKJL2200IonGaugeModelEmissionReadChanged;
extern NSString* ORKJL2200IonGaugeModelSensitivityReadChanged;
extern NSString* ORKJL2200IonGaugeModelPressureScaleChanged;
extern NSString* ORKJL2200IonGaugeModelDegasTimeChanged;
extern NSString* ORKJL2200IonGaugeModelEmissionCurrentChanged;
extern NSString* ORKJL2200IonGaugeModelSensitivityChanged;
extern NSString* ORKJL2200IonGaugeModelSetPointChanged;
extern NSString* ORKJL2200IonGaugeModelSetPointReadBackChanged;
extern NSString* ORKJL2200IonGaugePressureChanged;
extern NSString* ORKJL2200IonGaugeShipPressureChanged;
extern NSString* ORKJL2200IonGaugePollTimeChanged;
extern NSString* ORKJL2200IonGaugeSerialPortChanged;
extern NSString* ORKJL2200IonGaugeLock;
extern NSString* ORKJL2200IonGaugePortNameChanged;
extern NSString* ORKJL2200IonGaugePortStateChanged;
extern NSString* ORKJL2200IonGaugeModelStateMaskChanged;
extern NSString* ORKJL2200IonGaugeModelQueCountChanged;
