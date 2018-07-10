/*
 *  ORCCUSBModel.h
 *  Orca
 *
 *  Created by Mark Howe on Tues May 30 2006.
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
#import "ORCC32Model.h"
#import "ORUSB.h"

#define kRedLEDCodeBit		0
#define kGreenLEDCodeBit	8
#define kYellowLEDCodeBit	16

#define kRedLEDLatchBit		5
#define kGreenLEDLatchBit	13
#define kYellowLEDLatchBit	21

#define kRedLEDInvertBit	 4
#define kGreenLEDInvertBit  12
#define kYellowLEDInvertBit 20

#define kNIM01CodeBit	0
#define kNIM02CodeBit	8
#define kNIM03CodeBit	16

#define kNIM03LatchBit	21
#define kNIM02LatchBit	13
#define kNIM01LatchBit	5

#define kNIM03InvertBit 20
#define kNIM02InvertBit  12
#define kNIM01InvertBit	 4

#define kBuffSizeOptBit	0
#define kLAMTimeoutBit 8
#define kTriggerDelayBit 0

#define kScalerTimeIntervalBit 16
#define kScaleNumSepEventsBit 0

#define kSclr_AEnableBit 5
#define kSclr_BEnableBit 13
#define kSclr_AResetBit 4
#define kSclr_BResetBit 12

#define kSclr_AModeBit 0
#define kSclr_BModeBit 8
#define kDGG_AModeBit 16
#define kDGG_BModeBit 24

#define kNumberBuffersBit 0
#define kTimeOutBit 8

#define kHeaderOptBit 8
#define kEvtSepOptBit 6
#define kMixedBuffOptBit 5

// class definition
@interface ORCCUSBModel : ORCC32Model <USBDevice>
{
	ORUSBInterface* usbInterface;
    NSString* serialNumber;
    int internalRegSelection;
    int registerValue;
	BOOL started;
    unsigned short globalMode;
    unsigned short delays;
    unsigned long userLEDSelector;
    unsigned long userNIMSelector;
    unsigned long userDeviceSelector;
    unsigned long scalerReadout;
    unsigned long delayAndGateA;
    unsigned long delayAndGateB;
    unsigned long delayAndGateExt;
    unsigned long scalerA;
    unsigned long scalerB;
    unsigned long LAMMaskValue;
    unsigned short usbTransferSetup;
    short nValue;
    short aValue;
    short fValue;
    unsigned short nafModBits;
    unsigned short dataModifierBits;
    unsigned short dataWord;
    BOOL useDataModifier;
    NSMutableArray* customStack;
    NSString* lastStackFilePath;
}

#pragma mark ¥¥¥USB Protocol
- (ORUSBInterface*) usbInterface;
- (id) getUSBController;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) usbInterfaceDescription;
- (void) registerWithUSB:(id)usb;
- (NSUInteger) vendorID;
- (NSUInteger) productID;
- (NSString*) title;
- (NSString*) settingsLock;
- (void) checkInterface;

#pragma mark ¥¥¥Accessors
- (NSString*) lastStackFilePath;
- (void) setLastStackFilePath:(NSString*)aLastStackFilePath;
- (NSMutableArray*) customStack;
- (void) setCustomStack:(NSMutableArray*)aCustomStack;
- (BOOL) useDataModifier;
- (void) setUseDataModifier:(BOOL)aUseDataModifier;
- (unsigned short) dataWord;
- (void) setDataWord:(unsigned short)aDataWord;
- (unsigned short) dataModifierBits;
- (void) setDataModifierBits:(short)aDataModifierBits;
- (short) nafModBits;
- (void) setNafModBits:(short)aNafModBits;
- (short) fValue;
- (void) setFValue:(short)aFValue;
- (short) aValue;
- (void) setAValue:(short)aAValue;
- (short) nValue;
- (void) setNValue:(short)aNValue;
- (unsigned short) usbTransferSetup;
- (void) setUsbTransferSetup:(unsigned short)aUsbTransferSetup;
- (unsigned long) LAMMaskValue;
- (void) setLAMMaskValue:(unsigned long)aLAMMask;
- (unsigned long) scalerB;
- (void) setScalerB:(unsigned long)aScalerB;
- (unsigned long) scalerA;
- (void) setScalerA:(unsigned long)aScalerA;
- (unsigned long) delayAndGateExt;
- (void) setDelayAndGateExt:(unsigned long)aDelayAndGateExt;
- (unsigned long) delayAndGateB;
- (void) setDelayAndGateB:(unsigned long)aDelayAndGateB;
- (unsigned long) delayAndGateA;
- (void) setDelayAndGateA:(unsigned long)aDelayAndGateA;
- (unsigned long) scalerReadout;
- (void) setScalerReadout:(unsigned long)aScalerReadout;
- (unsigned long) userDeviceSelector;
- (void) setUserDeviceSelector:(unsigned long)aUserDeviceSelector;
- (unsigned long) userNIMSelector;
- (void) setUserNIMSelector:(unsigned long)aUserNIMSelector;
- (unsigned long) userLEDSelector;
- (void) setUserLEDSelector:(unsigned long)aUserLEDSelector;
- (unsigned short) delays;
- (void) setDelays:(unsigned short)aDelays;
- (unsigned short) globalMode;
- (void) setGlobalMode:(unsigned short)aGlobalMode;
- (BOOL) registerWritable:(int)reg;
- (NSString*) registerName:(int)reg;
- (int) registerValue;
- (void) setRegisterValue:(int)aRegisterValue;
- (int) internalRegSelection;
- (void) setInternalRegSelection:(int)aInternalRegSelection;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;


#pragma mark ¥¥¥Module Cmds
- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f
							 data:(unsigned short*) data;

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f;
								
- (unsigned short)  camacLongNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(unsigned long*) data;


- (unsigned short)  camacShortNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned short*) data
                                length:(unsigned long)   numWords;

- (unsigned short)  camacLongNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned long*) data
                                length:(unsigned long)    numWords;

- (void) checkStatus:(unsigned short)x station:(unsigned short)n;
- (int) flush;
- (long) readReg:(int) ireg;
- (int) writeReg:(int) ireg value:(int) value;
- (int) reset;
- (void) getStatus;
- (int) sendNAF:(int)n a:(int) a f:(int) f d24:(BOOL) d24 data:(unsigned long*) data;
- (BOOL) writeStackData:(short*) intbuf;
- (int) readStackData:(short*) intbuf;
- (int) executeStack:(short*) intbuf;
- (void) executeCustomStack;
- (void) startList:(BOOL)state;
- (void) writeInternalRegisters;
- (void) addNAFToStack;
- (void) addDataWordToStack;
- (void) clearStack;

@end

extern NSString* ORCCUSBModelCustomStackChanged;
extern NSString* ORCCUSBModelUseDataModifierChanged;
extern NSString* ORCCUSBModelDataWordChanged;
extern NSString* ORCCUSBModelDataModifierBitsChanged;
extern NSString* ORCCUSBModelNafModBitsChanged;
extern NSString* ORCCUSBModelFValueChanged;
extern NSString* ORCCUSBModelAValueChanged;
extern NSString* ORCCUSBModelNValueChanged;
extern NSString* ORCCUSBModelUsbTransferSetupChanged;
extern NSString* ORCCUSBModelLAMMaskChanged;
extern NSString* ORCCUSBModelScalerBChanged;
extern NSString* ORCCUSBModelScalerAChanged;
extern NSString* ORCCUSBModelDelayAndGateExtChanged;
extern NSString* ORCCUSBModelDelayAndGateBChanged;
extern NSString* ORCCUSBModelDelayAndGateAChanged;
extern NSString* ORCCUSBModelScalerReadoutChanged;
extern NSString* ORCCUSBModelUserDeviceSelectorChanged;
extern NSString* ORCCUSBModelUserNIMSelectorChanged;
extern NSString* ORCCUSBModelUserLEDSelectorChanged;
extern NSString* ORCCUSBModelDelaysChanged;
extern NSString* ORCCUSBModelGlobalModeChanged;
extern NSString* ORCCUSBModelRegisterValueChanged;
extern NSString* ORCCUSBModelInternalRegSelectionChanged;
extern NSString* ORCCUSBSettingsLock;
extern NSString* ORCCUSBInterfaceChanged;
extern NSString* ORCCUSBSerialNumberChanged;

