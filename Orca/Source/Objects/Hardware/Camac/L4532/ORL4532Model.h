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
	unsigned long   triggerId;
	unsigned long   channelTriggerId;
	unsigned long   eventCounter;
	ORReadOutList*  triggerGroup[32];
	BOOL			includeTiming;
	
	NSArray*		dataTakers[32];       //cache of data takers.
	unsigned long 	unChangingDataPart;
	unsigned short  cachedStation;
	unsigned long   triggerMask;
	int				numberTriggers;
	
	NSMutableArray*	delays;
	unsigned long	delayEnableMask;
	NSMutableArray*	triggerNames;
	union {
		NSTimeInterval asTimeInterval;
		unsigned long asLongs[2];
	}theTimeRef;
	
}

#pragma mark ¥¥¥Initialization
- (void) dealloc;

#pragma mark ¥¥¥Accessors
- (NSArray*) triggerNames;
- (void) setTriggerNames:(NSMutableArray*)aTriggerNames;
- (NSString*) triggerName:(int)index;
- (unsigned long) delayEnableMask;
- (void) setDelayEnableMask:(unsigned long)anEnableMask;
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
- (unsigned long) triggerId;
- (void) setTriggerId: (unsigned long) aTriggerId;
- (unsigned long) channelTriggerId;
- (void) setChannelTriggerId: (unsigned long) aChannelTriggerId;

- (ORReadOutList*) triggerGroup:(int)index;
- (void) setTrigger:(int)index group:(ORReadOutList*)newTriggerGroup;
- (NSMutableArray*) children;

#pragma mark ¥¥¥Hardware functions
- (unsigned long)	readInputPattern;
- (unsigned short)	readStatusRegister;
- (unsigned long)	readInputPatternClearMemoryAndLAM;
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
