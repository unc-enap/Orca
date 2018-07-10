/*
 *  ORShaperModel.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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

#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "VME_eCPU_Config.h"
#import "SBC_Config.h"
#import "ORHWWizard.h"
#import "ORAdcInfoProviding.h"

#define 	kNumShaperChannels 		8

#pragma mark ¥¥¥Register Definitions
enum {
    kConversionStatusRegister,			//0 	(w)
    kModeSelectRegister,			//1 	(w)
    kThresholdAddressRegister,			//2 	(w)
    kGain1Register,				//3 	(w)
    kThresholdReadRegister,			//4 	(r/w)
    kFastClearRegister,				//5     (w)
    kResetRegister,				//6 	(w)
    kScalerEnableRegister,			//7 	(w)
    kScalerSelectionRegister,			//8 	(w)
    kScalarClearRegister,			//9 	(w)
    kDiscrimOutputEnableRegister,		//10 	(w)
    kMiscRegister,				//11 	(w)
    kADC1OutputRegister,			//12 	(r)
    kADC2OutputRegister,			//13 	(r)
    kADC3OutputRegister,			//14 	(r)
    kADC4OutputRegister,			//15 	(r)
    kADC5OutputRegister,			//16 	(r)
    kADC6OutputRegister,			//17 	(r)
    kADC7OutputRegister,			//18 	(r)
    kADC8OutputRegister,			//19 	(r)
    kGainWriteRegister,				//20 	(w)
    kGainReadRegister,				//21 	(r)
    kThreshold_1_4_Register,			//22 	(w)
    kThreshold_5_8_Register,			//23 	(w)
    kThresholdConversionRegister,		//24 	(r)
    kOverAllCounter1,				//25	(r)
    kOverAllCounter2,				//26	(r)
    kScaler1,					//27	(r)
    kScaler2,					//28	(r)
    kScaler3,					//29	(r)
    kScaler4,					//30	(r)
    kScaler5,					//31	(r)
    kScaler6,					//32	(r)
    kScaler7,					//33	(r)
    kScaler8,					//34	(r)
    kBoardIdRegister,				//35	(r)
    kDacAddressMonitor,				//36	(r)
    kFloatingCounterMonitor,			//37	(r)
    kNumberOfADCSRegisters			//must be last
};

#pragma mark ¥¥¥Forward Declarations
@class ORRateGroup;


@interface ORShaperModel :  ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,ORAdcInfoProviding>
{
    @private
	
    unsigned long dataId;
    unsigned long scalerDataId;

	NSMutableArray* thresholds;
	NSMutableArray* thresholdAdcs;
	NSMutableArray* gains;
	BOOL		continous;
	BOOL		scalersEnabled;
	BOOL		multiBoardEnabled;
	BOOL		displayRaw;
	unsigned char   scalerMask;
	unsigned char   onlineMask;
	
	unsigned long	scanStart;
	unsigned long	scanDelta;
	unsigned short	scanNumber;
	
	ORRateGroup*	adcRateGroup;
	unsigned long 	adcCount[kNumShaperChannels];
	unsigned long   eventCount[kNumShaperChannels];
	ORRateGroup*	scalerRateGroup;
	unsigned short 	scalerCount[kNumShaperChannels];
		
	BOOL isRunning;
	
	//place to cache some stuff for alittle more speed.
	unsigned long 	slotMask;
    
	short savedThresholds[kNumShaperChannels];
    BOOL shipTimeStamp;
}

#pragma mark ¥¥¥Accessors
- (BOOL) shipTimeStamp;
- (void) setShipTimeStamp:(BOOL)aShipTimeStamp;
- (NSMutableArray*) thresholds;
- (void)	    setThresholds:(NSMutableArray*)someThresholds;
- (NSMutableArray*) thresholdAdcs;
- (void)	    setThresholdAdcs:(NSMutableArray*)someThresholdsAdcs;
- (NSMutableArray*) gains;
- (void)	    setGains:(NSMutableArray*)someGains;
- (unsigned short)  threshold:(unsigned short) aChan;
- (void)	    setThreshold:(unsigned short) aChan withValue:(unsigned short) aThreshold;
- (void)            setThresholdAdc:(unsigned short) aChan withValue:(unsigned short) aThreshold;
- (unsigned short)  gain:(unsigned short) aChan;
- (void)	    setGain:(unsigned short) aChan withValue:(unsigned short) aGain;
- (BOOL)	    continous;
- (void)	    setContinous:(BOOL)aValue;
- (BOOL)	    scalersEnabled;
- (void)	    setScalersEnabled:(BOOL)aValue;
- (BOOL)	    multiBoardEnabled;
- (void)	    setMultiBoardEnabled:(BOOL)aValue;
- (unsigned char)   scalerMask;
- (void)	    setScalerMask:(unsigned char) aScalerMask;
- (BOOL)	    scalerMaskBit:(int)bit;
- (void)	    setScalerMaskBit:(int)bit withValue:(BOOL)aValue;
- (unsigned char)   onlineMask;
- (void)	    setOnlineMask:(unsigned char)anOnlineMask;
- (BOOL)	    onlineMaskBit:(int)bit;
- (void)	    setOnlineMaskBit:(int)bit withValue:(BOOL)aValue;

- (unsigned long)   scanStart;
- (void)	    setScanStart:(unsigned long)value;
- (unsigned long)   scanDelta;
- (void)	    setScanDelta:(unsigned long)value;
- (unsigned short)  scanNumber;
- (void)	    setScanNumber:(unsigned short)value;
- (ORRateGroup*)    adcRateGroup;
- (void)	    setAdcRateGroup:(ORRateGroup*)newAdcRateGroup;
- (ORRateGroup*)    scalerRateGroup;
- (void)	    setScalerRateGroup:(ORRateGroup*)newScalerRateGroup;

- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (unsigned long) scalerDataId;
- (void) setScalerDataId: (unsigned long) ScalerDataId;


- (BOOL) displayRaw;
- (void) setDisplayRaw:(BOOL)newDisplayRaw;
- (void) startRates;
- (BOOL) bumpRateFromDecodeStage:(short)chan;

- (void) saveAllThresholds;
- (void) restoreAllThresholds;
- (void) setAllThresholdsTo:(NSNumber*)mvValue;

- (unsigned short) scalerCount:(unsigned short)chan;


- (void) initBoard;
- (void) loadThresholdsAndGains;

- (unsigned char)	modeMask;
- (unsigned char)	miscRegister;
- (unsigned char) 	readThreshold:(unsigned short) aChan;
- (void)		writeGain:(unsigned short) aChannel withValue:(unsigned char) aValue;
- (void)		writeThreshold:(unsigned short) aChannel withValue:(unsigned char) aValue;
- (unsigned char) 	readGain:(unsigned short) aChannel;


- (unsigned char)   readConversionReg;
- (unsigned short)  readAdc:(unsigned short) aChan;
- (unsigned short)  readBoardID;
- (unsigned short)  readScaler:(unsigned short) aChan;
- (unsigned char)   readThresholdConversion;
- (unsigned char)   readThresholdReg;
- (unsigned short)  thresholdmV:(unsigned short) aChan;
- (void)	    setThresholdmV:(unsigned short) aChan withValue:(unsigned short) aThreshold;
- (void)	    loadThresholds;
- (void)            readThresholds;
- (void)	    loadGains;
- (unsigned short)  thresholdRawtomV:(unsigned short) aRawValue;
- (unsigned short)  thresholdmVtoRaw:(unsigned short) aValueInMV;
- (unsigned short) threshold:(unsigned short) aChan;
- (unsigned short) thresholdAdc:(unsigned short) aChan;
- (unsigned short) gain:(unsigned short) aChan;
- (unsigned long) adcCount:(int)aChannel;
- (void)		clearAdcCounts;

- (void) writeFastClear:(unsigned char) aVal;
- (void) writeMode:(unsigned char) aVal;
- (void) writeScalerEnable:(unsigned char) aVal;
- (void) writeReset:(unsigned char) aVal;
- (void) writeMiscReg:(unsigned char) aVal;
- (void) writeScalerSelect:(unsigned char) aVal;
- (void) writeScalerClear:(unsigned char) aVal;
- (void) writeDiscriminatorEnable:(unsigned char) aVal;

- (unsigned char)  	readAdcDac;
- (unsigned short) 	readCounter1;
- (unsigned short) 	readCounter2;
- (unsigned short) 	readFloatingCounter;

- (void)		writeThres1_4:(unsigned char) aVal;
- (void)		writeThres5_8:(unsigned char) aVal;
- (void)		selectThresholdReg:(unsigned char) aChan;
- (void)		selectGainReg:(unsigned char) aChan;
- (void)		setThresholdAddress:(unsigned char) aChan;
- (void)		writeGainReg:(unsigned char) aChan;
- (unsigned char)   readGainReg;

- (NSString*) 		boardIdString;
- (unsigned short) 	decodeBoardId:(unsigned short) aValue;
- (unsigned short) 	decodeBoardType:(unsigned short) aValue;
- (unsigned short) 	decodeBoardRev:(unsigned short) aValue;
- (NSString *)		decodeBoardName:(unsigned short) aValue;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) scanForShapers;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;

- (int) load_eCPU_HW_Config_Structure:(VME_crate_config*)configStruct index:(int)index;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;

#pragma mark ¥¥¥RecordShipper
- (void) timedShipScalers;
- (void) shipScalerRecords;

#pragma mark ¥¥¥Rate
- (unsigned long) getCounter:(int)tag forGroup:(int)groupTag;
- (id) rateObject:(int)channel;

#pragma mark ¥¥¥Specialized storage methods
- (NSData*) gainMemento;
- (void) restoreGainsFromMemento:(NSData*)aMemento;
- (NSData*) thresholdMemento;
- (void) restoreThresholdsFromMemento:(NSData*)aMemento;


#pragma mark ¥¥¥HW Wizard
- (NSArray*) wizardSelections;
- (NSArray*) wizardParameters;
- (int) numberOfChannels;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end



#pragma mark ¥¥¥External String Definitions
extern NSString* ORShaperModelShipTimeStampChanged;
extern NSString* ORShaperChan;
extern NSString* ORShaperThresholdArrayChangedNotification;
extern NSString* ORShaperThresholdAdcArrayChangedNotification;
extern NSString* ORShaperGainArrayChangedNotification;
extern NSString* ORShaperThresholdChangedNotification;
extern NSString* ORShaperThresholdAdcChangedNotification;
extern NSString* ORShaperGainChangedNotification;
extern NSString* ORShaperContinousChangedNotification;
extern NSString* ORShaperScalersEnabledChangedNotification;
extern NSString* ORShaperMultiBoardEnabledChangedNotification;
extern NSString* ORShaperScalerMaskChangedNotification;
extern NSString* ORShaperOnlineMaskChangedNotification;

extern NSString* ORShaperScanStartChangedNotification;
extern NSString* ORShaperScanDeltaChangedNotification;
extern NSString* ORShaperScanNumChangedNotification;

extern NSString* ORShaperRateGroupChangedNotification;
extern NSString* ORShaperScalerGroupChangedNotification;

extern NSString* ORShaperDisplayRawChangedNotification;

extern NSString* ORShaperSettingsLock;

