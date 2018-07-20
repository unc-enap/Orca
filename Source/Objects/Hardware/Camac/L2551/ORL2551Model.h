/*
 *  ORL2551Model.h
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
#import "ORCamacIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"

#pragma mark ¥¥¥Forward Declarations
@class ORDataPacket;
@class TimedWorker;

@interface ORL2551Model : ORCamacIOCard <ORHWWizard>{
    @private
        uint32_t   dataId;
        unsigned short  onlineMask;
        uint32_t 	lastScalerCount[12];
        uint32_t 	scalerCount[12];
        float           scalerRate[12];
        NSDate*         lastTime;
        TimedWorker*    poller;
        NSMutableDictionary* rateAttributes;
        BOOL            clearOnStart;
        BOOL            doNotShipScalers;
        BOOL            pollWhenRunning;
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;

#pragma mark ¥¥¥Notifications
- (void)registerNotificationObservers;
- (void) runStopped:(NSNotification*)aNote;
- (void) runStarted:(NSNotification*)aNote;
- (void) runAboutToStart:(NSNotification*)aNote;
       
#pragma mark ¥¥¥Accessors
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (unsigned short)   onlineMask;
- (void)	    setOnlineMask:(unsigned short)anOnlineMask;
- (BOOL)	    onlineMaskBit:(int)bit;
- (void)	    setOnlineMaskBit:(int)bit withValue:(BOOL)aValue;
- (NSMutableDictionary*) rateAttributes;
- (void)		 setRateAttributes:(NSMutableDictionary*)newRateAttributes;
- (void)           setScalerCount:(unsigned short)chan value:(uint32_t)aValue;
- (uint32_t)  scalerCount:(unsigned short)chan;
- (void)           setScalerRate:(unsigned short)chan value:(float)aValue;
- (float)  scalerRate:(unsigned short)chan;
- (NSDate *) lastTime;
- (void) setLastTime: (NSDate *) aLastTime;
- (TimedWorker *) poller;
- (void) setPoller: (TimedWorker *) aPoller;
- (void) setPollingInterval:(float)anInterval;
- (void) makePoller:(float)anInterval;
- (BOOL) clearOnStart;
- (void) setClearOnStart: (BOOL) flag;
- (BOOL) doNotShipScalers;
- (void) setDoNotShipScalers: (BOOL) flag;
- (BOOL) pollWhenRunning;
- (void) setPollWhenRunning: (BOOL) flag;

#pragma mark ¥¥¥Hardware functions
- (void) readAllScalers;
- (void) readReset;
- (void) testLAM;
- (void) clearAll;
- (void) disableLAM;
- (void) enableLAM;
- (void) incAll;

- (void) calcRates;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (void) shipScalerRecords;

#pragma mark ¥¥¥HW Wizard
- (NSArray*) wizardSelections;
- (NSArray*) wizardParameters;
- (int) numberOfChannels;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

@end

extern NSString* ORL2551ScalerGroupChangedNotification;
extern NSString* ORL2551RateChangedNotification;
extern NSString* ORL2551ScalerCountChangedNotification;
extern NSString* ORL2551OnlineMaskChangedNotification;
extern NSString* ORL2551SettingsLock;
extern NSString* ORL2551PollRateChangedNotification;
extern NSString* ORL2551ShipScalersChangedNotification;
extern NSString* ORL2551ClearOnStartChangedNotification;
extern NSString* ORL2551PollWhenRunningChangedNotification;
