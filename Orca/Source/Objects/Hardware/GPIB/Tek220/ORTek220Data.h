//
//  ORTek220Data.h
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
#pragma mark ***Imported Files

#import "ORDataPacket.h"

#define kSizeTek220Header 	500

@class OROscBaseModel;

// Header information from T220D oscilloscope.
struct T220Header
{
    long			nrPts;   			// Number of points in waveform
    float			yOff;				// Vertical position of the waveform.
    float			yMult;				// Vertical scale factor in yUnit/data point value.
    float			xIncr;				// Time sampling interval.
    long			ptOff;				// Trigger point in waveform
    char			xUnit[ 20 ];		// Time units.
    char			yUnit[ 20 ];		// Vertical units.
};

@interface ORTek220Data : NSObject {
    OROscBaseModel*     mModel;
    struct T220Header	mHeader;					// Header information.
    char				mHeaderChar[ kSizeTek220Header ];	// Header information as char.
    NSMutableData*		mGtid;						// Pointer to gtid data.
    NSMutableData*		mData;						// Pointer to actual waveform data
    NSMutableData*		mTime;						// Pointer to time packet.
    long				mMaxSizeWaveform;			// Size of mData
    long				mActualSizeWaveform;		// Actual size of waveform stored in mData.
    short				mAddress;					// GPIB Primary address.
    short				mChannel;					// The channel number.
    unsigned long long  timeInSecs;
}

#pragma mark ***Initialization
- (id)				initWithWaveformModel: (OROscBaseModel*) aModel channel: (short) aChannel;
- (void)			dealloc;

#pragma mark ***Accessors
- (unsigned long long) timeInSecs;
- (void) setTimeInSecs:(unsigned long long)aTime;
- (long) 			actualWaveformSize;
- (void)			setActualWaveformSize: (unsigned long) aWaveformSize;
- (long)			maxWaveformSize;
- (NSMutableData*)	rawData;
- (NSMutableData*)	timeData;
- (char*)			rawHeader;

#pragma mark ***Data Routines
//- (void)			clearAcquisition;
- (void)			setGtid: (unsigned long) aGtid;
- (char*)			createDataStorage;
- (void) 			setDataPacketData: (ORDataPacket*) aDataPacket timeData: (NSData*) aTimeData
                                                                includeGTID: (BOOL) aFlag;
- (NSData*)			timePacketData: (ORDataPacket*) aDataPacket channel: (unsigned short) aChannel;
//- (void)			setAcquisition;

#pragma mark ***Misc
- (void)			convertHeader;
	

@end
