//
//  ORUnivVoltModel.h
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
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
#import "ORCard.h"

#define UVkChnlNumParameters 11 //see below for list.
#define UVkNumChannels 12

enum hveStatus {eHVUEnabled = 1, eHVURampingUp = 2, eHVURampingDown = 4, evHVUTripForSupplyLimits = 16,
                eHVUTripForUserCurrent = 32, eHVUTripForHVError = 64, eHVUTripForHVLimit= 128};
typedef enum hveStatus hveStatus;

@class ORCircularBufferUV;

@interface ORUnivVoltModel : ORCard 
{
	id						adapter;
	NSMutableArray*			mChannelArray;		// Stores dictionary objects (one for each channel) of the parameter values for that channel.
	NSDate*					mTimeStamp;			// Time of last reading.
	NSMutableDictionary*	mParams;			//Dictionary of HV unit parameters indicating type of parameter and whether it is R or R/W. 
	NSMutableArray*			mCommands;			//Crate commands for HV Unit
	NSMutableArray*			mCircularBuffers;	// Array holding circular buffers of data one for each channel.  Used for
												// plotting.
	long					mPoints;			// number of points in each channel-data circular buffer.
	NSNumber*				mPollTimeMins; 
	NSNumber*				mPlotterPoints;		// number of points in histogram displays.
	ORAlarm*				mHVValueLmtsAlarm;	// If set have exceeded MVDZ window around demand voltage
	ORAlarm*				mHVCurrentLmtsAlarm;// If set have exceeded MCDZ window around current.
	int						mWParams;
	bool					mPollTaskIsRunning;
	bool					mAlarmsEnabled;
	bool					mUpdateFirst[ UVkNumChannels];	// If true have done at least one update to load values.
	
	double					mHVValues[ UVkNumChannels ];
}

#pragma mark ••• Notifications
- (void) registerNotificationObservers;

#pragma mark ••• Send Commands
- (void) getValues: (int) aCurrentChnl;
- (void)  loadValues: (int) aCurrentChnl;
- (NSString *) createCommand: (int) aCurChnl
                dictParamObj: (NSDictionary *) aDictParamObj
				     command: (NSString *) aCommand
					 loadAll: (bool) aLoadAllValues;
					 
#pragma mark ••• Polling
- (float) pollTimeMins;
- (void) setPollTimeMins: (float) aPollTimeMins;
- (void) startPolling;
- (void) stopPolling;
- (void) pollTask;
- (bool) isPollingTaskRunning;

#pragma mark •••Accessors
- (NSMutableArray*) channelArray;
- (void) setChannelArray:(NSMutableArray*)anArray;
- (ORCircularBufferUV*) circularBuffer: (int) aChnl;
- (long) circularBufferSize: (int) aChnl;
- (NSMutableDictionary*) channelDictionary: (int) aCurrentChnl;
- (void)  setChannelEnabled: (int) anEnabled chnl: (int) aCurrentChnl;
- (int)   chnlEnabled: (int) aCurrentChnl;
- (float) measuredCurrent: (int) aCurrentChnl;
- (float) measuredHV: (int) aCurrentChnl;
- (float) demandHV: (int) aCurrentChnl;
- (void)  setDemandHV: (float) aDemandHV chnl: (int) aCurrentChnl;
- (float) tripCurrent: (int) aCurrentChnl;
- (void)  setTripCurrent: (float) aTripCurrent chnl: (int) aCurrentChnl;
- (float) rampUpRate: (int) aCurrentChnl;
- (void)  setRampUpRate: (float) aRampUpRate chnl: (int) aCurrentChnl;
- (float) rampDownRate: (int) aCurrentChnl;
- (void)  setRampDownRate: (float) aRampDownRate chnl: (int) aCurrentChnl;
- (NSString*) status: (int) aCurrentChnl;
- (void) setStatus: (int) aCurrentChnl status: (NSString*) aStatus;
- (float) MVDZ: (int) aCurrentChnl;
- (void)  setMVDZ: (float) aMCDZ chnl: (int) aCurrentChnl;
- (float) MCDZ: (int) aCurrentChnl;
- (void)  setMCDZ: (float) aMCDZ chnl: (int) aCurrentChnl;
- (float)  HVLimit: (int) aCurrentChnl;
- (bool) areAlarmsEnabled;
- (void) enableAlarms: (bool) aFlag;
- (int) stationNumber;
- (int) numPointsInCB: (int)aChnl; //mah -- added to get the actual number of plots in CB rather
- (bool) updateFirst: (int) aCurrentChnl;

#pragma mark •••Interpret data
- (void) interpretDataReturn: (NSNotification*) aNote;
- (void) interpretDMPReturn: (NSDictionary*) aReturnData channel: (int) aCurChnl;
- (void) interpretLDReturn: (NSDictionary*) aReturnData;

#pragma mark •••Utilities
- (void) printDictionary: (int) aCurrentChnl;
- (NSDictionary*) createChnlRetDict: (int) aCurrentChnl;
- (void) fakeData: (int) aSlot channel: (int) aCurrentChnl;
- (int) numChnlsEnabled;

#pragma mark ***Archival
- (id) initWithCoder: (NSCoder*) decoder;
- (void) encodeWithCoder: (NSCoder*) encoder;
@end

extern NSString* UVChnlEnabledChanged;
extern NSString* UVChnlDemandHVChanged;
extern NSString* UVChnlMeasuredHVChanged;
extern NSString* UVChnlMeasuredCurrentChanged;
extern NSString* UVChnlSlotChanged;
extern NSString* UVChnlRampUpRateChanged;
extern NSString* UVChnlRampDownRateChanged;
extern NSString* UVChnlTripCurrentChanged;
extern NSString* UVChnlStatusChanged;
extern NSString* UVChnlMVDZChanged;
extern NSString* UVChnlMCDZChanged;
extern NSString* UVChnlHVLimitChanged;
extern NSString* UVChnlChanged;
extern NSString* UVCardSlotChanged;

extern NSString* UVChnlHVValuesChanged;

extern NSString* UVPollTimeMinsChanged;
extern NSString* UVLastPollTimeChanged;
extern NSString* UVPlotterDataChanged;
extern NSString* UVStatusPollTaskChanged;

extern NSString* UVAlarmChanged;

extern NSString* HVkLastPollTimeMins;

//extern NSString* UVErrorNotification;

extern NSString* HVkChannel;

// HV unit Parameters
// Data is stored as dictionary objects in mChannelArray.
extern NSString* HVkParam;			// The parameters
extern NSString* HVkChannelEnabled;		//1
extern NSString* HVkMeasuredCurrent;	//2
extern NSString* HVkMeasuredHV;			//3
extern NSString* HVkDemandHV;		    //4
extern NSString* HVkRampUpRate;			//5
extern NSString* HVkRampDownRate;		//6
extern NSString* HVkTripCurrent;		//7
extern NSString* HVkStatus;				//8
extern NSString* HVkMVDZ;				//9
extern NSString* HVkMCDZ;				//10
extern NSString* HVkHVLimit;			//11

extern NSString* HVkCurChnl;			// Current channel

//extern NSString* ORUnivVoltLock;