//
//  ORIP320Model.h
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORVmeIPCard.h"
#import "ORAdcProcessing.h"

@class ORDataSet;

enum {
    kControlReg,
    kConvertCmd,
    kADCDataReg,
    kNum320Registers
};

#define kCTRIG_mask  0x8000
#define kMode_mask   0x0300
#define kGain_mask   0x00c0
#define kChan_mask   0x001f

#define kCAL0_mask  0x0014
#define kCAL1_mask  0x0015
#define kCAL2_mask  0x0016
#define kCAL3_mask  0x0017
#define kAUTOZERO_mask  0x0300

#define kCAL0_volt 4.9000
#define kCAL1_volt 2.4500
#define kCAL2_volt 1.2250
#define kCAL3_volt 0.6125
#define kAUTOZERO_volt 0.0000

#define kNumIP320Channels 40

#define kMinus5to5		-5
#define kMinus10to10	-10
#define k0to10			0
#define kUncalibrated	1

#define kNumGainSettings 4

enum {
    kDiff0_19_Cal0_3,
    kSingle0_19,
    kSingle20_39,
    kAutoZero
};



@interface ORIP320Model : ORVmeIPCard <ORAdcProcessing>
{
	ORDataSet*		dataSet;
    NSMutableArray* chanObjs;
    NSTimeInterval	pollingState;
    BOOL            hasBeenPolled;
	NSLock*			hwLock;
    uint32_t   dataId;
    uint32_t   convertedDataId;
	uint32_t	readCount;
    BOOL			displayRaw;
	int				opMode;
	BOOL			pollRunning;
    BOOL			logToFile;
    NSString*		logFile;
	NSMutableArray*	logBuffer;
    BOOL			shipRecords;
    int				cardJumperSetting;
	NSMutableArray* multiPlots;
    BOOL            readOnce;
	BOOL			calibrationLoaded;
    NSDate*			calibrationDate;
    struct{
        float kSlope_m;
        float kIdeal_Volt_Span;
        float kIdeal_Zero;
        float kVoltCALLO;
        short kCountCALLO;
        float kVoltCALHI;
        short kCountCALHI;
    } calibrationConstants[kNumGainSettings];
}

#pragma mark ¥¥¥Accessors
- (NSDate*) calibrationDate;
- (void) setCalibrationDate:(NSDate*)aCalibrationDate;
- (NSString*) getSlotKey:(unsigned short)aSlot;
- (int) cardJumperSetting;
- (void) setCardJumperSetting:(int)aCardJumperSetting;
- (BOOL) shipRecords;
- (void) setShipRecords:(BOOL)aShipRecords;
- (NSString*) logFile;
- (void) setLogFile:(NSString*)aLogFile;
- (BOOL) logToFile;
- (void) setLogToFile:(BOOL)aLogToFile;
- (void) setCardJumperSetting:(int)aCardJumperSetting;
//calibration routines
- (void) calibrate;
- (void) loadCALHIControReg:(unsigned short)gain;
- (void) loadCALLOControReg:(unsigned short)gain;
- (void)  calculateCalibrationSlope:(unsigned short)gain;
- (unsigned short) calculateCorrectedCount:(unsigned short)gain countActual:(unsigned short)CountActual;
- (NSMutableArray *)    multiPlots;
- (void) setMultiPlots:(NSMutableArray *) aMultiPlots;
- (void) addMultiPlot:(id)aMultiPlot;
- (void) removeMultiPlot:(id)aMultiPlot;


- (BOOL) displayRaw;
- (void) setDisplayRaw:(BOOL)aDisplayRaw;
- (NSMutableArray *)chanObjs;
- (void)setChanObjs:(NSMutableArray *)chanObjs;

- (void) setPollingState:(NSTimeInterval)aState;
- (NSTimeInterval) pollingState;
- (BOOL) hasBeenPolled;
- (void)			setOpMode:(int)aMode;
- (int)				opMode;
- (uint32_t)  getRegisterAddress:(short) aRegister;
- (uint32_t)  getAddressOffset:(short) anIndex;
- (NSString*)      getRegisterName:(short) anIndex;
- (short)          getNumRegisters;
- (void)           loadConstants:(unsigned short)aChannel;
- (unsigned short) readAdcChannel:(unsigned short)aChannel time:(time_t)aTime;
- (void)           readAllAdcChannels;
- (void)		   enablePollAll:(BOOL)state;
- (void)		   enableAlarmAll:(BOOL)state;
- (void)		   postNotification:(NSNotification*)aNote;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (uint32_t) convertedDataId;
- (void) setConvertedDataId: (uint32_t) DataId;
- (uint32_t) lowMask;
- (uint32_t) highMask;

#pragma mark ¥¥¥Adc Processing Protocol
- (void)processIsStarting;
- (void)processIsStopping;
- (void) startProcessCycle;
- (void) endProcessCycle;
- (BOOL) processValue:(int)channel;
- (void) setProcessOutput:(int)channel value:(int)value;
- (NSString*) processingTitle;
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel;
- (double) convertedValue:(int)channel;
- (double) maxValueForChan:(int)channel;
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ¥¥¥DataRecords
- (NSDictionary*) dataRecordDescription;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (void) shipRawValues;
- (void) shipConvertedValues;
- (void) loadConvertedTimeSeries:(float)convertedValue atTime:(time_t) aTime forChannel:(int) channel;
- (void) loadRawTimeSeries:(float)convertedValue atTime:(time_t) aTime forChannel:(int) channel;
- (void) writeLogBufferToFile;


#pragma mark ¥¥¥DataSource
- (int)  outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(NSUInteger)index ofItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (NSUInteger)  numberOfChildren;
- (id)   childAtIndex:(NSUInteger)index;
- (id)   name;
- (void) removeDataSet:(ORDataSet*)aSet;
- (BOOL) leafNode;

@end

@interface NSObject (ORHistModel)
- (void) removeFrom:(NSMutableArray*)anArray;
- (void) setAdcCard:(id)aCard;
- (void) invalidateDataSource;
@end

#pragma mark ¥¥¥External String Definitions
extern NSString* ORIP320ModelCalibrationDateChanged;
extern NSString* ORIP320ModelCardJumperSettingChanged;
extern NSString* ORIP320ModelShipRecordsChanged;
extern NSString* ORIP320ModelLogFileChanged;
extern NSString* ORIP320ModelLogToFileChanged;
extern NSString* ORIP320ModelDisplayRawChanged;
extern NSString* ORIP320GainChangedNotification;
extern NSString* ORIP320ModeChangedNotification;
extern NSString* ORIP320AdcValueChangedNotification;
extern NSString* ORIP320WriteValueChangedNotification;
extern NSString* ORIP320ReadMaskChangedNotification;
extern NSString* ORIP320ReadValueChangedNotification;
extern NSString* ORIP320PollingStateChangedNotification;
extern NSString* ORIP320ModelModeChanged;
extern NSString* ORIP320ModelMultiPlotsChangedNotification;
