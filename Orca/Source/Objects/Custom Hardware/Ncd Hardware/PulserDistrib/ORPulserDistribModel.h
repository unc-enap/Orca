//
//  ORPulserDistribModel.h
//  Orca
//  Created by Mark Howe on Thurs Feb 20 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORBaseDecoder.h"

#pragma mark ¥¥¥Forward Declarations
@class ORDataPacket;
@class ORDataSet;

@interface ORPulserDistribModel :  OrcaObject
{
    @private
        NSMutableArray* patternArray;
        NSMutableArray* packedArray;
        BOOL disableForPulser;
        unsigned long dataId;
		BOOL noisyEnvBroadcastEnabled;
}

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Accessors
- (BOOL) noisyEnvBroadcastEnabled;
- (void) setNoisyEnvBroadcastEnabled:(BOOL)aNoisyEnvBroadcastEnabled;
- (NSMutableArray*) patternArray;
- (void) setPatternArray:(NSMutableArray*)newPatternArray;
- (unsigned long)patternMaskForArray:(int)arrayIndex;
- (void) setPatternMaskForArray:(int)arrayIndex to:(unsigned long)aValue;
- (BOOL) disableForPulser;
- (void) setDisableForPulser: (BOOL) flag;


#pragma mark ¥¥¥Data Record
- (NSDictionary*) dataRecordDescription;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (void) shipPDSRecord:(NSArray*)aPatternArray;

#pragma mark ¥¥¥Hardware Access
- (void) loadHardware:(NSArray*)aPatternArray;
- (BOOL) waitForCompletion;

#pragma mark ¥¥¥Notifications
- (void) runStatusChanged:(NSNotification*)aNote;
- (void) pulserStartingToLoad:(NSNotification*)aNote;
- (void) pulserDoneLoading:(NSNotification*)aNote;

- (void)loadMemento:(NSCoder*)aDecoder;
- (void)saveMemento:(NSCoder*)anEncoder;
- (NSData*) memento;
- (void) restoreFromMemento:(NSData*)aMemento;
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end


@interface ORPulserDistribDecoderForPDS : ORBaseDecoder
{}
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
- (NSString*) dataRecordDescription:(unsigned long*)dataPtr;
@end


#pragma mark ¥¥¥Notification Strings
extern NSString* ORPulserDistribNoisyEnvBroadcastEnabledChanged;
extern NSString* ORPulserDistribPatternChangedNotification;
extern NSString* ORPulserDistribPatternBitChangedNotification;
extern NSString* ORPulserDisableForPulserChangedNotification;
