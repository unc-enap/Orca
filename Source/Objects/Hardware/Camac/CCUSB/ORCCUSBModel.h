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
    uint32_t userLEDSelector;
    uint32_t userNIMSelector;
    uint32_t userDeviceSelector;
    uint32_t scalerReadout;
    uint32_t delayAndGateA;
    uint32_t delayAndGateB;
    uint32_t delayAndGateExt;
    uint32_t scalerA;
    uint32_t scalerB;
    uint32_t LAMMaskValue;
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
- (uint32_t) LAMMaskValue;
- (void) setLAMMaskValue:(uint32_t)aLAMMask;
- (uint32_t) scalerB;
- (void) setScalerB:(uint32_t)aScalerB;
- (uint32_t) scalerA;
- (void) setScalerA:(uint32_t)aScalerA;
- (uint32_t) delayAndGateExt;
- (void) setDelayAndGateExt:(uint32_t)aDelayAndGateExt;
- (uint32_t) delayAndGateB;
- (void) setDelayAndGateB:(uint32_t)aDelayAndGateB;
- (uint32_t) delayAndGateA;
- (void) setDelayAndGateA:(uint32_t)aDelayAndGateA;
- (uint32_t) scalerReadout;
- (void) setScalerReadout:(uint32_t)aScalerReadout;
- (uint32_t) userDeviceSelector;
- (void) setUserDeviceSelector:(uint32_t)aUserDeviceSelector;
- (uint32_t) userNIMSelector;
- (void) setUserNIMSelector:(uint32_t)aUserNIMSelector;
- (uint32_t) userLEDSelector;
- (void) setUserLEDSelector:(uint32_t)aUserLEDSelector;
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
							data:(uint32_t*) data;


- (unsigned short)  camacShortNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned short*) data
                                length:(uint32_t)   numWords;

- (unsigned short)  camacLongNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(uint32_t*) data
                                length:(uint32_t)    numWords;

- (void) checkStatus:(unsigned short)x station:(unsigned short)n;
- (int) flush;
- (uint32_t) readReg:(int) ireg;
- (int) writeReg:(int) ireg value:(uint32_t) value;
- (int) reset;
- (void) getStatus;
- (int) sendNAF:(int)n a:(int) a f:(int) f d24:(BOOL) d24 data:(uint32_t*) data;
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

