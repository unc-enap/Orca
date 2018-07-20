/*
 *  ORAD3511Model.h
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

@class ORDataPacket;

@interface ORAD3511Model : ORCamacIOCard <ORDataTaker> {
    @private
        uint32_t dataId;
		unsigned short gain;
		unsigned short storageOffset;
		BOOL enabled;
		BOOL firstTime;
		
       //place to cache some stuff for alittle more speed.
        uint32_t 	crateAndStationId;
        unsigned short cachedStation;
    BOOL includeTiming;
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;
        
#pragma mark ¥¥¥Accessors
- (BOOL) includeTiming;
- (void) setIncludeTiming:(BOOL)aIncludeTiming;
- (BOOL) enabled;
- (void) setEnabled:(BOOL)aEnabled;
- (unsigned short) storageOffset;
- (void) setStorageOffset:(unsigned short)aStorageOffset;
- (unsigned short) gain;
- (void) setGain:(unsigned short)aGain;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) postWarning:(NSString*)aMessage;

#pragma mark ¥¥¥Hardware Test functions
- (void) initBoard;
- (void) read;
- (void) testLAM;
- (void) resetLAMandClearBuffer;
- (void) disableLAM;
- (void) enableLAM;


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

@end

extern NSString* ORAD3511ModelIncludeTimingChanged;
extern NSString* ORAD3511WarningPosted;
extern NSString* ORAD3511EnabledChanged;
extern NSString* ORAD3511StorageOffsetChanged;
extern NSString* ORAD3511GainChanged;
extern NSString* ORAD3511SettingsLock;
