//
//  ORMCA927Model.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 26 2007.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files

#import "ORUsbDeviceModel.h"
#import "ORUSB.h"
#import "ORDataTaker.h"

@class ORUSBInterface;
@class ORAlarm;
@class ORDataSet;

enum {
	kCtlReg,
	kAuxReg, 
	kConvGain,
	kZDTMode,
	kPresetCtl,
	kLtPreset,
	kRtPreset, 
	kRoiPeakPreset, 
	kRoiPreset, 
	kAcqStatus, 
	kLiveTime,
	kRealTime, 
	kAux0Counter,
	kAux1Counter, 
	kCtlRegMirror,
	kVersion,  
	kStopAcq,
	kNumberMCA927Registers
};

#define kGateCoinMask		(0x1<<29)
#define kGateEnableMask		(0x1<<28)
#define kDisableULMask		(0x1<<5)
#define kEnableTriggerMask	(0x1<<4)
#define kStartMask			(0x1<<0)

#define kEnableRoiPeakMask	(0x1<<5)
#define kEnableRoiMask		(0x1<<4)
#define kEnableLiveTimeMask	(0x1<<3)
#define kEnableRealTimeMask	(0x1<<2)
#define kEnableOverFlowMask	(0x1<<1)

#define kChannelEnabledMask  (0x1<<0)
#define kChannelAutoStopMask (0x1<<1)

#define kZDTMask			(0x3<<4)
#define kEnableZDTMask		(0x1<<4)
#define kZDTModeMask		(0x1<<5)
#define kZDTSpeedMask		0xf

typedef struct MCA927Registers {
	NSString*       regName;
	unsigned long 	addressOffset;
} MCA927Registers;

@interface ORMCA927Model : ORUsbDeviceModel <USBDevice,ORDataTaker> {
	unsigned long   dataId;
	NSLock*			localLock;
	ORUSBInterface* usbInterface;
    NSString*		serialNumber;
	ORAlarm*		noUSBAlarm;
    NSString*		fpgaFilePath;
    BOOL			useCustomFile;
    int				selectedChannel;
    BOOL			runningStatus[2];
    unsigned long liveTimeStatus[2];
    unsigned long realTimeStatus[2];
    unsigned long liveTime[2];
    unsigned long realTime[2];
	unsigned long controlReg[2];
	unsigned long presetCtrlReg[2];
    unsigned long ltPreset[2];
    unsigned long roiPreset[2];
    unsigned long rtPreset[2];
    unsigned long roiPeakPreset[2];
    unsigned long convGain[2];
    unsigned long upperDiscriminator[2];
    unsigned long lowerDiscriminator[2];
    unsigned long zdtMode[2];
	unsigned long spectrum[4][0x4000];
    unsigned long runOptions[2];
    BOOL		  autoClear[2];
	BOOL		  startedFromMainRunControl[2];
	BOOL		  mainRunIsStopping;
	ORDataSet*    dataSet;
	NSString*	  lastFile;
    NSString*	  comment;
}

#pragma mark ***Accessors
- (NSString*) comment;
- (void) setComment:(NSString*)aComment;
- (NSString*) lastFile;
- (void) setLastFile:(NSString*)aLastFile;
- (BOOL) startedFromMainRunControl:(int)index;
- (BOOL) autoClear:(int)index;
- (void) setAutoClear:(int)index withValue:(BOOL)aValue;
- (unsigned long) runOptions:(int)index;
- (void) setRunOptions:(int)index withValue:(unsigned long)optionMask;
- (int) selectedChannel;
- (void) setSelectedChannel:(int)aSelectedChannel;
- (unsigned long) upperDiscriminator:(int)index;
- (void) setUpperDiscriminator:(int)index withValue:(unsigned long)aValue;
- (unsigned long) lowerDiscriminator:(int)index;
- (void) setLowerDiscriminator:(int)index withValue:(unsigned long)aValue;
- (unsigned long) zdtMode:(int)index;
- (void) setZdtMode:(int)index withValue:(unsigned long)aValue;
- (BOOL) runningStatus:(int)index;
- (void) setRunningStatus:(int)index withValue:(BOOL)aValue;
- (void) writeSpectrum:(int)index toFile:(NSString*)aFilePath;

- (unsigned long) convGain:(int)index;
- (void) setConvGain:(int)index withValue:(unsigned long)aValue;
- (unsigned long) liveTime:(int)index;
- (void) setLiveTime:(int)index withValue:(unsigned long)aValue;
- (unsigned long) realTime:(int)index;
- (void) setRealTime:(int)index withValue:(unsigned long)aValue;
- (unsigned long) liveTimeStatus:(int)index;
- (void) setLiveTimeStatus:(int)index withValue:(unsigned long)aValue;
- (unsigned long) realTimeStatus:(int)index;
- (void) setRealTimeStatus:(int)index withValue:(unsigned long)aValue;
- (unsigned long) roiPreset:(int)index;
- (void) setRoiPreset:(int)index withValue:(unsigned long)aValue;
- (unsigned long) rtPreset:(int)index;
- (void) setRtPreset:(int)index withValue:(unsigned long)aValue;
- (unsigned long) roiPeakPreset:(int)index;
- (void) setRoiPeakPreset:(int)index withValue:(unsigned long)aValue;
- (unsigned long) spectrum:(int)index valueAtChannel:(int)x;

- (unsigned long) ltPreset:(int)index;
- (void) setLtPreset:(int)index withValue:(unsigned long)aValue;
- (BOOL) useCustomFile;
- (void) setUseCustomFile:(BOOL)aUseCustomFile;
- (NSString*) fpgaFilePath;
- (void) setFpgaFilePath:(NSString*)aFpgaFilePath;
- (id) getUSBController;
- (ORUSBInterface*) usbInterface;
- (void) setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*) serialNumber;
- (void) setSerialNumber:(NSString*)aSerialNumber;
- (NSUInteger) vendorID;
- (NSUInteger) productID;
- (NSString*) usbInterfaceDescription;
- (void) interfaceAdded:(NSNotification*)aNote;
- (void) interfaceRemoved:(NSNotification*)aNote;
- (unsigned long) controlReg:(int)index;
- (void) setControlReg:(int)index withValue:(unsigned long)aValue;
- (unsigned long) presetCtrlReg:(int)index;
- (void) setPresetCtrlReg:(int)index withValue:(unsigned long)aValue;
- (int) numChannels:(int)index;
- (const char*) convGainLabel:(int)aValue;
- (BOOL) viewSpectrum0;
- (BOOL) viewSpectrum1;
- (BOOL) viewZDT0;
- (BOOL) viewZDT1;

#pragma mark ***Comm methods
//all throw on error
- (void) startFPGA;
- (void) initFPGA;
- (void) loadFPGA;
- (void) testFPGA;
- (void) disableFirmwareLoop;
- (void) enableFirmwareLoop;
- (void) testPresets;
- (void) resetMDA;
- (void) resetFPGA;
- (void) getFirmwareVersion;
- (void) checkUSBAlarm;

- (void) writeReg:(int)aReg adc:(int)adcIndex value:(unsigned long)aValue;
- (unsigned long) readReg:(int)aReg adc:(int)adcIndex;
- (void) report;
- (void) sync;
- (void) report:(BOOL)verbose;
- (void) initBoard:(int)index;
- (void) startAcquisition:(int)index;
- (void) stopAcquisition:(int)index;
- (void) loadDiscriminators:(int) index;
- (void) clearSpectrum:(int)index;
- (void) clearZDT:(int)index;
- (void) readSpectrum:(int)index;
- (void) readZDT:(int)index;

#pragma mark •••Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORMCA927ModelCommentChanged;
extern NSString* ORMCA927ModelRunOptionsChanged;
extern NSString* ORMCA927ModelSelectedChannelChanged;
extern NSString* ORMCA927ModelLowerDiscriminatorChanged;
extern NSString* ORMCA927ModelUpperDiscriminatorChanged;
extern NSString* ORMCA927ModelLiveTimeStatusChanged;
extern NSString* ORMCA927ModelRealTimeStatusChanged;
extern NSString* ORMCA927ModelStatusParamsChanged;
extern NSString* ORMCA927ModelLiveTimeChanged;
extern NSString* ORMCA927ModelRealTimeChanged;
extern NSString* ORMCA927ModelUseCustomFileChanged;
extern NSString* ORMCA927ModelFpgaFilePathChanged;
extern NSString* ORMCA927ModelSerialNumberChanged;
extern NSString* ORMCA927ModelUSBInterfaceChanged;
extern NSString* ORMCA927ModelLock;
extern NSString* ORMCA927ModelControlRegChanged;
extern NSString* ORMCA927ModelPresetCtrlRegChanged;
extern NSString* ORMCA927ModelLtPresetChanged;
extern NSString* ORMCA927ModelRTPresetChanged;
extern NSString* ORMCA927ModelRoiPresetChanged;
extern NSString* ORMCA927ModelRoiPeakPresetChanged;
extern NSString* ORMCA927ModelConvGainChanged;
extern NSString* ORMCA927ModelRunningStatusChanged;
extern NSString* ORMCA927ModelAutoClearChanged;
extern NSString* ORMCA927ModelZdtModeChanged;


