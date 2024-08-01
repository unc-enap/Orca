//
//  ORSHT35Model.h
//  Orca
//
//  Created by Mark Howe on 08/1/2024.
//  Copyright 2024 University of North Carolina. All rights reserved.
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
#import "I2CProtocol.h"

@class ORTimeRate;

@interface ORSHT35Model : OrcaObject {
    uint32_t i2cAddress;
    int      temperature;
    int      humidity;
    int      updateInterval;
    ORTimeRate* temperatureRate;
    ORTimeRate* humidityRate;

    id <I2CProtocol> i2cMaster;
	BOOL running;
	BOOL timeToStop;
}

#pragma mark ***Accessors
- (int)   updateInterval;
- (void)  setUpdateInterval:(int)milliSecs;
- (void)  pollNow;
- (void)  startStopPolling;
- (uint32_t) i2cAddress;
- (void) setI2CAddress:(uint32_t)anAddress;
- (int)  temperature;
- (void) setTemperature:(int)aValue;
- (int)  humidity;
- (void) setHumidity:(int)aValue;
- (ORTimeRate*)temperatureRate;
- (ORTimeRate*)humidityRate;

#pragma mark ***HW Access
- (BOOL) running;
- (void) setRunning:(BOOL)aState;
- (void) readI2C;
- (id)   getI2CMaster;

- (void) decodeI2CData:(id)data;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORSHT35ModelI2CAddressChanged;
extern NSString* ORSHT35ModelTemperatureChanged;
extern NSString* ORSHT35ModelHumidityChanged;
extern NSString* ORSHT35ModelI2CInterfaceChanged;
extern NSString* ORSHT35ModelUpdateIntervalChanged;
extern NSString* ORSHT35ModelRunningChanged;
extern NSString* ORSHT35ModelLock;

