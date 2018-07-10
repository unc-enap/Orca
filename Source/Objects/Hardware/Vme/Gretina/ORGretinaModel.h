//-------------------------------------------------------------------------
//  ORGretinaModel.h
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORVmeIOCard.h";
#import "ORDataTaker.h";
#import "ORHWWizard.h";
#import "SBC_Config.h"

@class ORRateGroup;
@class ORAlarm;

#define kNumGretinaChannels			8 
#define kNumGretinaCardParams		6

#define kGretinaFIFOEmpty		0x800
#define kGretinaFIFOAlmostEmpty 0x1000
#define kGretinaFIFOHalfFull	0x2000
#define kGretinaFIFOAllFull		0x4000

#pragma mark ¥¥¥Register Definitions
enum {
	kBoardID,			//[0] 
	kProgrammingDone,		//[1] 
	kExternalWindow,                //[2] 
	kPileupWindow,			//[3] 
	kNoiseWindow,			//[4] 
	kExtTriggerSlidingLength,	//[5] 
	kCollectionTime,		//[6] 
	kIntegrationTime,		//[7]
	kControlStatus,			//[8]
	kLEDThreshold,			//[9]
	kCFDParameters,			//[10]
	kRawDataSlidingLength,		//[11]
	kRawDataWindowLength,		//[12]
	kDebugDataBufferAddress,	//[13]
	kDebugDataBufferData,		//[14]
	kNumberOfGretinaRegisters	//must be last
};

enum GretinaFIFOStates {
	kEmpty,
	kAlmostEmpty,	
	kHalfFull,
	kFull,
	kSome
};

@interface ORGretinaModel : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping>
{
  @private
	unsigned long   dataId;
	unsigned long*  dataBuffer;

	NSMutableArray* cardInfo;
    short			enabled[kNumGretinaChannels];
    short			debug[kNumGretinaChannels];
    short			pileUp[kNumGretinaChannels];
    short			polarity[kNumGretinaChannels];
    short			triggerMode[kNumGretinaChannels];
    short			ledThreshold[kNumGretinaChannels];
    short			cfdDelay[kNumGretinaChannels];
    short			cfdThreshold[kNumGretinaChannels];
    short			cfdFraction[kNumGretinaChannels];
    short			dataDelay[kNumGretinaChannels];
    short			dataLength[kNumGretinaChannels];
	
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumGretinaChannels];
	BOOL isRunning;

    int fifoState;
	ORAlarm*        fifoFullAlarm;
	int				fifoEmptyCount;

	//cach to speed takedata
	unsigned long location;
	id theController;
	unsigned long fifoAddress;
	unsigned long fifoStateAddress;

	BOOL oldEnabled[kNumGretinaChannels];
	unsigned short oldLEDThreshold[kNumGretinaChannels];
	unsigned short newLEDThreshold[kNumGretinaChannels];
	BOOL noiseFloorRunning;
	int noiseFloorState;
	int noiseFloorWorkingChannel;
	int noiseFloorLow;
	int noiseFloorHigh;
	int noiseFloorTestValue;
	int noiseFloorOffset;
    float noiseFloorIntegrationTime;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (float) noiseFloorIntegrationTime;
- (void) setNoiseFloorIntegrationTime:(float)aNoiseFloorIntegrationTime;
- (int) fifoState;
- (void) setFifoState:(int)aFifoState;
- (int) noiseFloorOffset;
- (void) setNoiseFloorOffset:(int)aNoiseFloorOffset;
- (void) initParams;
- (void) cardInfo:(int)index setObject:(id)aValue;
- (id)   cardInfo:(int)index;
- (id)   rawCardValue:(int)index value:(id)aValue;
- (id)   convertedCardValue:(int)index;

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;

#pragma mark ¥¥¥specific accessors
- (void) setExternalWindow:(int)aValue;
- (void) setPileUpWindow:(int)aValue;
- (void) setNoiseWindow:(int)aValue;
- (void) setExtTrigLength:(int)aValue;
- (void) setCollectionTime:(int)aValue;
- (void) setIntegratonTime:(int)aValue;

- (int) externalWindow;
- (int) pileUpWindow;
- (int) noiseWindow;
- (int) extTrigLength;
- (int) collectionTime;
- (int) integrationTime; 

- (void) setPolarity:(short)chan withValue:(int)aValue;
- (void) setTriggerMode:(short)chan withValue:(int)aValue; 
- (void) setPileUp:(short)chan withValue:(short)aValue;		
- (void) setEnabled:(short)chan withValue:(short)aValue;		
- (void) setDebug:(short)chan withValue:(short)aValue;	
- (void) setLEDThreshold:(short)chan withValue:(int)aValue;
- (void) setCFDDelay:(short)chan withValue:(int)aValue;	
- (void) setCFDFraction:(short)chan withValue:(int)aValue;	
- (void) setCFDThreshold:(short)chan withValue:(int)aValue;
- (void) setDataDelay:(short)chan withValue:(int)aValue;   
- (void) setDataLength:(short)chan withValue:(int)aValue;  

- (int) enabled:(short)chan;		
- (int) debug:(short)chan;		
- (int) pileUp:(short)chan;		
- (int)	polarity:(short)chan;	
- (int) triggerMode:(short)chan;	
- (int) ledThreshold:(short)chan;	
- (int) cfdDelay:(short)chan;		
- (int) cfdFraction:(short)chan;	
- (int) cfdThreshold:(short)chan;	
- (int) dataDelay:(short)chan;		
- (int) dataLength:(short)chan;		

//conversion methods
- (float) cfdDelayConverted:(short)chan;
- (float) cfdThresholdConverted:(short)chan;
- (float) dataDelayConverted:(short)chan;
- (float) dataLengthConverted:(short)chan;

- (void) setCFDDelayConverted:(short)chan withValue:(float)aValue;	
- (void) setCFDThresholdConverted:(short)chan withValue:(float)aValue;
- (void) setDataDelayConverted:(short)chan withValue:(float)aValue;   
- (void) setDataLengthConverted:(short)chan withValue:(float)aValue;  

#pragma mark ¥¥¥Hardware Access
- (short) readBoardID;
- (void) initBoard;
- (short) readControlReg:(int)channel;
- (void) writeControlReg:(int)channel enabled:(BOOL)enabled;
- (void) writeLEDThreshold:(int)channel;
- (void) writeCFDParameters:(int)channel;
- (void) writeRawDataSlidingLength:(int)channel;
- (void) writeRawDataWindowLength:(int)channel;
- (unsigned short) readFifoState;
- (unsigned long) readFIFO:(unsigned long)offset;
- (void) writeFIFO:(unsigned long)index value:(unsigned long)aValue;
- (int) clearFIFO;
- (void) findNoiseFloors;
- (void) stepNoiseFloor;
- (BOOL) noiseFloorRunning;

#pragma mark ¥¥¥Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo;
- (unsigned long) waveFormCount:(int)aChannel;
- (void)   startRates;
- (void) clearWaveFormCounts;
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag;
- (void) checkFifoAlarm;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

#pragma mark ¥¥¥HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(short*)anArray forKey:(NSString*)aKey;
@end

extern NSString* ORGretinaModelNoiseFloorIntegrationTimeChanged;
extern NSString* ORGretinaModelNoiseFloorOffsetChanged;

extern NSString* ORGretinaModelEnabledChanged;
extern NSString* ORGretinaModelDebugChanged;
extern NSString* ORGretinaModelPileUpChanged;
extern NSString* ORGretinaModelPolarityChanged;
extern NSString* ORGretinaModelTriggerModeChanged;
extern NSString* ORGretinaModelLEDThresholdChanged;
extern NSString* ORGretinaModelCFDDelayChanged;
extern NSString* ORGretinaModelCFDFractionChanged;
extern NSString* ORGretinaModelCFDThresholdChanged;
extern NSString* ORGretinaModelDataDelayChanged;
extern NSString* ORGretinaModelDataLengthChanged;

extern NSString* ORGretinaSettingsLock;
extern NSString* ORGretinaCardInfoUpdated;
extern NSString* ORGretinaRateGroupChangedNotification;
extern NSString* ORGretinaNoiseFloorChanged;
extern NSString* ORGretinaModelFIFOCheckChanged;
