//
//  ORiTransGasSensorModel.h
//  
//
//  Created by Mark Howe on Tue May 18 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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

#import "ORiTransGasSensorModel.h"
@class ORModBusModel;
@class ORAlarm;

@interface ORiTransGasSensorModel : NSObject
{
	id  delegate;
	int baseAddress;
	int sensorType;
	int gasReading;
	int gasType;
	int statusBits;
	int lastAlarmDate;
	int lastAlarmYear;
	int rtcDate;
	int rtcYear;
	int lowAlarmSetting;
	int highAlarmSetting; 
	int calGasValue;
	int loopHighScaling; 
	int decimalPlaces;
    NSString* sensorName;
	BOOL fullRead;
	ORAlarm* gasAlarm;
    int channel;
	unsigned long timeMeasured;
	unsigned long	dataId;
}

+ (id) sensor;
- (id)init;
- (void) dealloc;
- (NSUndoManager *)undoManager;

#pragma mark ***Accessors
- (int) channel;
- (void) setChannel:(int)aChannel;
- (NSString*) sensorName;
- (void) setSensorName:(NSString*)aName;
- (void) setDelegate:(id)aDelegate;
- (int)  baseAddress;
- (void) setBaseAddress:(int)aValue;
- (int)  sensorType;
- (void) setSetSensorType:(int)aValue;
- (int)  gasReading;
- (void) setGasReading:(int)aValue;
- (int)  gasType;
- (void) setGasType:(int)aValue;
- (int)  statusBits;
- (void) setStatusBits:(int)aValue ;
- (int)  lastAlarmDate ;
- (void) setLastAlarmDate:(int)aValue ;
- (int)  lastAlarmYear ;
- (void) setLastAlarmYear:(int)aValue ;
- (int)  rtcDate ;
- (void) setRtcDate:(int)aValue ;
- (int)  rtcYear ;
- (void) setRtcYear:(int)aValue ;
- (int)  lowAlarmSetting ;
- (void) setLowAlarmSetting:(int)aValue ;
- (int)  highAlarmSetting ;
- (void) setHighAlarmSetting:(int)aValue; 
- (int)  calGasValue ;
- (void) setCalGasValue:(int)aValue ;
- (int)  decimalPlaces; 
- (void) setDecimalPlaces:(int)aValue ;
- (int)  loopHighScaling; 
- (void) setLoopHighScaling:(int)aValue ;
- (void) setFullRead:(BOOL)aState;
- (int) offsetReg:(int)aReg;
- (int) extractChanFrom:(int)aCommand;
- (void) shipDataRecords;

- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherAmi286;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSDictionary*) dataRecordDescription;

#pragma mark •••Helpers
- (NSString*) gasType:(int)aType fullName:(BOOL)full;
- (NSString*) sensorType:(int)aType fullName:(BOOL)full;
- (float) gasReadingConversion:(unsigned short)aValue;
- (NSString*) formattedGasReading;
- (void) processRegister:(int)aReg value:(int)aValue;
- (void) readValues:(ORModBusModel*)modBus;

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end
extern NSString* ORiTransGasSensorModelChannelChanged;
extern NSString* ORiTransGasSensorModelNameChanged;
extern NSString* ORiTransGasSensorBaseAddressChanged;
extern NSString* ORiTransGasSensorGasSensorTypeChanged;
extern NSString* ORiTransGasSensorGasReadingChanged;
extern NSString* ORiTransGasSensorGasTypeChanged;
extern NSString* ORiTransGasSensorStatusBitsChanged;
extern NSString* ORiTransGasSensorLastAlarmDateChanged;
extern NSString* ORiTransGasSensorLastAlarmYearChanged;
extern NSString* ORiTransGasSensorRtcDateChanged;
extern NSString* ORiTransGasSensorRtcYearChanged;
extern NSString* ORiTransGasSensorLowAlarmSettingChanged;
extern NSString* ORiTransGasSensorHighAlarmSettingChanged;
extern NSString* ORiTransGasSensorCalGasValueChanged;
extern NSString* ORiTransGasSensorLoopHighScalingChanged;
extern NSString* ORiTransRemoveGasSensor;
extern NSString* ORiTransGasDecimalPlacesChanged;
