//
//  ORTek220Model.h
//  test
//
//  Created by Mark Howe on Thurs Apr 2, 2009.
//  Copyright 2009 CENPA, University of Washington. All rights reserved.
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

#import "OROscBaseModel.h"
#import "ORTek220Data.h"
#import "OROscDecoder.h"

#define ORTEK220 1

// Interface description of ORTek220Model oscilloscope.
@interface ORTek220Model : OROscBaseModel {
    @private
	ORTek220Data*	mDataObj[ kMaxOscChnls ];       // Pointers channel data.
	unsigned short  mChannelMask;					// Mask of channels being acquired.
}

#pragma mark ***Initialization
- (id) 		init;
- (void) 	dealloc;
- (void)	setUpImage;
- (void)	makeMainController;

#pragma mark ***Hardware - General
- (short)	oscScopeId;
- (bool) 	oscBusy;
- (int32_t)	oscGetDateTime;
- (void)	oscSetDateTime: (time_t) aTime;
- (void)	oscLockPanel: (bool) aFlag;
- (void)	oscResetOscilloscope;
- (void)	oscSendTextMessage: (NSString*) aMessage;
- (void)	oscSetQueryFormat: (short) aFormat;
- (void)	oscSetScreenDisplay: (bool) aDisplayOn;

#pragma mark ***Hardware - Channel
- (void)	oscGetChnlAcquire: (short) aChnl;
- (void)	oscSetChnlAcquire;
- (void)	oscGetChnlCoupling: (short) aChnl;
- (void)	oscSetChnlCoupling: (short) aChnl;
- (void)	oscGetChnlPos: (short) aChnl;
- (void)	oscSetChnlPos: (short) aChnl;
- (void)	oscGetChnlScale: (short) aChnl;
- (void)	oscSetChnlScale: (short) aChnl;

#pragma mark ***Hardware - Horizontal settings
- (void)	oscGetHorizontalPos;
- (void)	oscSetHorizontalPos;
- (void)	oscGetHorizontalScale;
- (void)	oscSetHorizontalScale;
- (void)	oscGetWaveformRecordLength;
- (void)	oscSetWaveformRecordLength;

#pragma mark ***Hardware - Trigger
- (void)	oscGetTriggerCoupling;
- (void)	oscSetTriggerCoupling;
- (void)	oscGetTriggerLevel;
- (void)	oscSetTriggerLevel;
- (void)	oscGetTriggerMode;
- (void)	oscSetTriggerMode;
- (void)	oscGetTriggerPos;
- (void)	oscSetTriggerPos;
- (void)	oscGetTriggerSlopeIsPos;
- (void)	oscSetTriggerSlopeIsPos;
- (void)	oscGetTriggerSource;
- (void)	oscSetTriggerSource;

#pragma mark ***Hardware - Data Acquisition
- (BOOL)	runInProgress;
- (void)	oscArmScope;
- (void)	oscGetHeader;
- (void)	oscGetWaveform: (unsigned short) aMask;
- (void) 	oscGetWaveformTime: (unsigned short) aMask;
- (void)	oscRunOsc: (NSString*) aStartMsg;
- (void)	oscSetAcqMode: (short) aMode;
- (void)	oscSetDataReturnMode;
- (void) 	oscSet220WaveformAcq:(unsigned short)aMask;
- (void)	oscStopAcquisition;
                                                    
#pragma mark •••DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) 	runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (void)	takeDataTask:(NSDictionary*)userInfo;
- (void) 	runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark ***Specialty routines.
- (void) 	osc220ConvertTime: (uint64_t*) a10MHzTime timeToConvert: (char*) aCharTime;

@end

@interface ORTek220DecoderForScopeData : OROscDecoder
{}
@end

@interface ORTek220DecoderForScopeGTID : OROscDecoder
{} 
@end

@interface ORTek220DecoderForScopeTime : OROscDecoder
{}
@end

extern NSString* ORTek220Lock;
extern NSString* ORTek220GpibLock;
