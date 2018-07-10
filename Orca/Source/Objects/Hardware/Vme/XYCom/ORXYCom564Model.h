//-------------------------------------------------------------------------
//  ORXYCom564Model.h
//
//  Created by Michael G. Marino on 10/21/1011
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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
#import "ORVmeIOCard.h"
#import "ORAdcProcessing.h"
#import "ORDataTaker.h"
#import "SBC_Config.h"
#import "SBC_Link.h"


#pragma mark •••Register Definitions
typedef enum {
    kModuleID = 0,
    kStatusControl,
    kInterruptTimer,
    kProgTimerInterruptVector,
    kAutoscanControl,
    kADMode,
    kADStatusControl,
    kEndOfConversionVector,
    kGainChannelHigh,
    kGainChannelLow,    
    kADScan,    
    kNumberOfXyCom564Registers
} EXyCom564Registers;

typedef enum {
    kA16,
    kA24
} EXyCom564ReadoutMode;

typedef enum {
    kGainOne,
    kGainTwo,
    kGainFive,
    kGainTen,
    kNumberOfGains
} EXyCom564ChannelGain;

typedef enum {
    kSingleChannel,
    kSequentialChannel,
    kRandomChannel,
    kExternalTrigger,
    kAutoscanning,
    kProgramGain,
    kNumberOfOpModes
} EXyCom564OperationMode;

typedef enum {
    k0to8,
    k0to16,
    k0to32,
    k0to64,
    kNumberOfAutoscanModes
} EXyCom564AutoscanMode;

typedef enum {
    kRawADC = 0,
    k0to5Volts,
    k0to10Volts,
    kPlusMinus5Volts,
    kPlusMinus10Volts
} EInterpretXy564ADC;

@interface ORXYCom564Model : ORVmeIOCard <ORDataTaker, ORAdcProcessing>
{
    @protected
    unsigned long          dataId;
    EXyCom564OperationMode operationMode;
    EXyCom564AutoscanMode  autoscanMode;
    EInterpretXy564ADC     interpretADC;
    BOOL                   pollCard;
    BOOL                   shipRecords;
    BOOL                   pollRunning;
    BOOL                   isRunning;
    BOOL                   pollStopRequested;
    NSTimeInterval         pollSpeed;    
    NSMutableArray*        channelGains;
    NSData*                chanADCVals;
    NSData*                chanADCAverageVals;
    NSData*                chanADCAverageValsCache;
    NSData*                readBuffer;
    int                    averageValueNumber;
    int                    currentAverageState;
    NSString*              userLocked;

}
#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (EXyCom564ReadoutMode)    readoutMode;
- (void)                    setReadoutMode:(EXyCom564ReadoutMode) aMode;
- (EXyCom564OperationMode) 	operationMode;
- (void)                    setOperationMode: (EXyCom564OperationMode) anIndex;
- (EXyCom564AutoscanMode) 	autoscanMode;
- (void)                    setAutoscanMode: (EXyCom564AutoscanMode) anIndex;
- (BOOL)                    shipRecords;
- (void)                    setShipRecords:(BOOL)ship;
- (void)                    setInterpretADC: (EInterpretXy564ADC)anInt;
- (EInterpretXy564ADC)      interpretADC;

- (void) convertedValues:(double*)ptr range:(NSRange)aRange;

- (int) averageValueNumber;
- (void) setAverageValueNumber:(int)aValue;

#pragma mark •••Hardware Access
- (void) read:(uint8_t*) aval atRegisterIndex:(EXyCom564Registers)index; 
- (void) write:(uint8_t) aval atRegisterIndex:(EXyCom564Registers)index;

- (void) setGain:(EXyCom564ChannelGain) gain channel:(unsigned short) aChannel;
- (void) setGain:(EXyCom564ChannelGain) gain;
- (EXyCom564ChannelGain) getGain:(unsigned short) aChannel;
- (uint16_t) getAdcValueAtChannel:(int)chan;
- (uint16_t) getAdcAverageValueAtChannel:(int)chan;
- (void) getAdcValues:(uint16_t*)ptr range:(NSRange)range;
- (void) getAdcAverageValues:(uint16_t*)ptr range:(NSRange)range;
- (BOOL) isPolling;
- (NSTimeInterval) pollSpeed;

- (void) initBoard;
- (void) report;
- (void) resetBoard;
- (void) programGains;
- (void) programReadoutMode;
- (void) startPollingActivity;
- (void) stopPollingActivity;

- (BOOL) userLocked;
- (NSString*) userLockedString;
- (BOOL) setUserLock:(BOOL)lock withString:(NSString*)lockString;

#pragma mark ***Card qualities
- (short) getNumberOfChannels;

#pragma mark ***Register - Register specific routines
- (short)			getNumberRegisters;
- (short)			getNumberOperationModes;
- (short)			getNumberAutoscanModes;
- (short)			getNumberGainModes;
- (NSString*) 		getRegisterName:(EXyCom564Registers) anIndex;
- (unsigned long) 	getAddressOffset: (EXyCom564Registers) anIndex;
- (NSString*) 		getOperationModeName: (EXyCom564OperationMode) anIndex;
- (NSString*) 		getAutoscanModeName: (EXyCom564AutoscanMode) aMode;
- (NSString*) 		getChannelGainName: (EXyCom564ChannelGain) aMode;

#pragma mark •••Data records
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSDictionary*) dataRecordDescription;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

#pragma mark •••External String Definitions
extern NSString* ORXYCom564Lock;
extern NSString* ORXYCom564ReadoutModeChanged;
extern NSString* ORXYCom564OperationModeChanged;
extern NSString* ORXYCom564AutoscanModeChanged;
extern NSString* ORXYCom564ChannelGainChanged;
extern NSString* ORXYCom564PollingActivityChanged;
extern NSString* ORXYCom564ADCValuesChanged;
extern NSString* ORXYCom564ShipRecordsChanged;
extern NSString* ORXYCom564AverageValueNumberHasChanged;
extern NSString* ORXYCom564PollingSpeedHasChanged;
extern NSString* ORXYCom564InterpretADCHasChanged;
