//
//  ORBaseDecoder.h
//  Orca
//
//  Created by Mark Howe on 1/21/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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

#import "ORDataTypeAssigner.h"

#define ShiftAndExtract(aValue,aShift,aMask) (((aValue)>>(aShift)) & (aMask))

@class ORDataSet;

@interface ORBaseDecoder : NSObject {
    NSMutableDictionary* decoderOptions;
	@private
		NSMutableDictionary* cachedObjects;	//decoder can cache info here
		NSLock* cachedObjectsLock;
    @protected
        BOOL skipRateCounts;

}
- (void) setSkipRateCounts:(BOOL)aState;
- (BOOL) skipRateCounts;

- (NSString*) getChannelKey:(unsigned short)aChan;
- (NSString*) getCardKey:(unsigned short)aChan;
- (NSString*) getCrateKey:(unsigned short)aCrate;

- (void) swapData:(void*)someData;

- (void) registerNotifications;
- (void) runStarted:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;
- (id)   objectForNestedKey:(NSString*)firstKey,...;				//nil terminated list of keys
- (void) setObject:(id)obj forNestedKey:(NSString*)firstKey,...; //nil terminated list of keys
- (BOOL) cacheSetUp;
- (void) setUpCacheUsingHeader:(NSDictionary*)aHeader;
- (void) cacheCardLevelObject:(id)aKey fromHeader:(NSDictionary*)aHeader;

@end