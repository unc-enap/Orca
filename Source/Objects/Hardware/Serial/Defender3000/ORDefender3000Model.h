//--------------------------------------------------------
// ORDefender3000Model
//  Orca
//
//  Created by Mark Howe on 05/14/2024.
//  Copyright 2024 CENPA, University of North Carolina. All rights reserved.
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
#pragma mark ***Imported Files

@class ORSerialPort;
@class ORTimeRate;

@interface ORDefender3000Model : OrcaObject
{
    @private
        NSString*       portName;
        BOOL            portWasOpen;
        ORSerialPort*   serialPort;
        uint32_t	    dataId;
		NSString*		lastRequest;
		NSMutableArray* cmdQueue;
		float		    weight;
		uint32_t	    timeMeasured;
		int				pollTime;
        NSMutableString* buffer;
		BOOL			shipWeight;
		ORTimeRate*		timeRate;
        uint16_t        printInterval;
        uint16_t        tare;
        uint8_t         units;
        uint8_t         command;
        uint8_t         legendData;
        uint8_t         unitData;
        uint8_t         stabilityData;
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

- (void) registerNotificationObservers;
- (void) dataReceived:(NSNotification*)note;

#pragma mark ***Accessors
- (ORSerialPort*) serialPort;
- (void) setSerialPort:(ORSerialPort*)aSerialPort;
- (BOOL) portWasOpen;
- (void) setPortWasOpen:(BOOL)aPortWasOpen;
- (NSString*) portName;
- (void) setPortName:(NSString*)aPortName;
- (ORTimeRate*)timeRate;
- (BOOL) shipWeight;
- (void) setShipWeight:(BOOL)aShipWeight;
- (int)  pollTime;
- (void) setPollTime:(int)aPollTime;
- (NSString*) lastRequest;
- (void)      setLastRequest:(NSString*)aRequest;
- (void) openPort:(BOOL)state;
- (uint32_t) timeMeasured;
- (void) setWeight:(float)aValue;
- (float) weight;
- (uint16_t) printInterval;
- (void) setPrintInterval:(uint16_t)aValue;
- (uint8_t) units;
- (void) setUnits:(uint8_t)aValue;
- (uint8_t) command;
- (void) setCommand:(uint8_t)aValue;
- (uint16_t) tare;
- (void) setTare:(uint16_t)aValue;
- (void) sendAllCommands;

#pragma mark ***Data Records
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSDictionary*) dataRecordDescription;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherDefender3000;

- (void) shipWeightData;
- (void) sendCommand;

#pragma mark ***Commands
- (void) addCmdToQueue:(NSString*)aCmd;
- (void) readWeight;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORDefender3000ModelShipWeightChanged;
extern NSString* ORDefender3000ModelPollTimeChanged;
extern NSString* ORDefender3000ModelSerialPortChanged;
extern NSString* ORDefender3000Lock;
extern NSString* ORDefender3000ModelPortNameChanged;
extern NSString* ORDefender3000ModelPortStateChanged;
extern NSString* ORDefender3000WeightArrayChanged;
extern NSString* ORDefender3000WeightChanged;
extern NSString* ORDefender3000PrintIntervalChanged;
extern NSString* ORDefender3000UnitsChanged;
extern NSString* ORDefender3000CommandChanged;
extern NSString* ORDefender3000TareChanged;
