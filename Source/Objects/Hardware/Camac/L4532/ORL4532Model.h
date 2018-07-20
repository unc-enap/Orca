/*
 *  ORL4532Model.h
 *  Orca
 *
 *  Created by Mark Howe on Fri Sept 29, 2006.
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

#pragma mark ¥¥¥Forward Declarations
@class ORReadOutList;

@interface ORL4532Model : ORCamacIOCard <ORDataTaker> {	
@private
	uint32_t   triggerId;
	uint32_t   channelTriggerId;
	uint32_t   eventCounter;
	ORReadOutList*  triggerGroup[32];
	BOOL			includeTiming;
	
	NSArray*		dataTakers[32];       //cache of data takers.
	uint32_t 	unChangingDataPart;
	unsigned short  cachedStation;
	uint32_t   triggerMask;
	int				numberTriggers;
	
	NSMutableArray*	delays;
	uint32_t	delayEnableMask;
	NSMutableArray*	triggerNames;
	union {
		NSTimeInterval asTimeInterval;
		uint32_t asLongs[2];
	}theTimeRef;
	
}

#pragma mark ¥¥¥Initialization
- (void) dealloc;

#pragma mark ¥¥¥Accessors
- (NSArray*) triggerNames;
- (void) setTriggerNames:(NSMutableArray*)aTriggerNames;
- (NSString*) triggerName:(int)index;
- (uint32_t) delayEnableMask;
- (void) setDelayEnableMask:(uint32_t)anEnableMask;
- (NSArray*) delays;
- (void) setDelays:(NSMutableArray*)aDelays;
- (void) setTrigger:(int)index withName:(NSString*)aName;	
- (void) setDelayEnabledMaskBit:(int)index withValue:(BOOL)aValue;
- (void) setDelay:(int)index withValue:(int)aValue;	
- (int) delay:(int)index;


- (int) numberTriggers;
- (void) setNumberTriggers:(int)aNumberTriggers;
- (BOOL) includeTiming;
- (void) setIncludeTiming:(BOOL)aIncludeTiming;
- (uint32_t) triggerId;
- (void) setTriggerId: (uint32_t) aTriggerId;
- (uint32_t) channelTriggerId;
- (void) setChannelTriggerId: (uint32_t) aChannelTriggerId;

- (ORReadOutList*) triggerGroup:(int)index;
- (void) setTrigger:(int)index group:(ORReadOutList*)newTriggerGroup;
- (NSMutableArray*) children;

#pragma mark ¥¥¥Hardware functions
- (uint32_t)	readInputPattern;
- (unsigned short)	readStatusRegister;
- (uint32_t)	readInputPatternClearMemoryAndLAM;
- (BOOL)			testLAM;
- (void)			clearMemoryAndLAM;
- (BOOL)			testAndClearLAM;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) reset;


#pragma mark ¥¥¥Archival
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORL4532ModelTriggerNamesChanged;
extern NSString* ORL4532ModelDelayEnableMaskChanged;
extern NSString* ORL4532ModelNumberTriggersChanged;
extern NSString* ORL4532ModelIncludeTimingChanged;
extern NSString* ORL4532ModelInputRegisterChanged;
extern NSString* ORL4532SettingsLock;
extern NSString* ORL4532ModelDelaysChanged;

@interface NSObject (setCAMACMode)
- (void)setCheckLAM:(BOOL)aState;
- (void) setCAMACMode: (BOOL) aState;
@end
