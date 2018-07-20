/*
 *  OR2228AModel.h
 *  Orca
 *
 *  Created by Mark Howe on 6/30/05.
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

@class ORDataPacket;
@class ORAlarm;

@interface OR2228AModel : ORCamacIOCard <ORDataTaker,ORHWWizard> {
    @private
        uint32_t dataId;
        unsigned short onlineMask;
        BOOL suppressZeros;
		
        //place to cache some stuff for alittle more speed.
        uint32_t 	unChangingDataPart;
        unsigned short cachedStation;
        short onlineChannelCount;
        short onlineList[8];
		BOOL firstTime;
		ORAlarm*    overflowAlarm;
       
		unsigned short overFlowCheckTime;
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;
        
#pragma mark ¥¥¥Accessors
- (unsigned short) overFlowCheckTime;
- (void) setOverFlowCheckTime:(unsigned short)aOverFlowCheckTime;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (unsigned char)   onlineMask;
- (void)	    setOnlineMask:(unsigned char)anOnlineMask;
- (BOOL)	    onlineMaskBit:(int)bit;
- (void)	    setOnlineMaskBit:(int)bit withValue:(BOOL)aValue;
- (void)		setSuppressZeros:(BOOL)aFlag;
- (BOOL)		suppressZeros;

#pragma mark ¥¥¥Hardware Test functions
- (void) readNoReset;
- (void) readReset;
- (void) testLAM;
- (void) resetLAM;
- (void) generalReset;
- (void) disableLAMEnableLatch;
- (void) enableLAMEnableLatch;
- (void) testAllChannels;


#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark ¥¥¥HW Wizard
- (NSArray*) wizardSelections;
- (NSArray*) wizardParameters;
- (int) numberOfChannels;

@end

extern NSString* OR2228AModelOverFlowCheckTimeChanged;
extern NSString* OR2228AOnlineMaskChangedNotification;
extern NSString* OR2228ASettingsLock;
extern NSString* OR2228ASuppressZerosChangedNotification;
