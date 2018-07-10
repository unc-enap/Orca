/*
 *  OR4ChanModel.h
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

#import "ORVmeIOCard.h"
#import "ORDataTaker.h"

@class ORReadOutList;

#pragma mark ¥¥¥Register Definitions
enum {
    //Write Commands offsets
    kResetRegister              = 0x00,
    kLatchTimeReg               = 0x40,
    kCounterEnable              = 0x42,
    kResetCounter               = 0x44,
    kLoadLowerClkReg            = 0x50,
    kLoadUpperClkReg            = 0x54,
    kStatusReg                  = 0x68,

    //Write Commands offsets
    kBoardIdReg                 = 0x10,    
    kReg0LowerReg               = 0x40,
    kReg0UpperReg               = 0x44,
    kReg1LowerReg               = 0x48,
    kReg1UpperReg               = 0x4C,
    kReg2LowerReg               = 0x50,
    kReg2UpperReg               = 0x54,
    kReg3LowerReg               = 0x58,
    kReg3UpperReg               = 0x5C,
    kReg4LowerReg               = 0x60,
    kReg4UpperReg               = 0x64,
};

#pragma mark ¥¥¥Static Declarations
enum {
    kEvent0Mask         = 0x1<<0,	//<0x1>
    kEvent1Mask         = 0x1<<1,	//<0x2>
    kEvent2Mask         = 0x1<<2,	//<0x4>
    kEvent3Mask         = 0x1<<3,	//<0x8>
    kEvent4Mask         = 0x1<<4,	//<0x10>
};

@interface OR4ChanTriggerModel :  ORVmeIOCard <ORDataTaker>
{
    @private
        unsigned long   clockDataId;    
        unsigned long lowerClock;
        unsigned long upperClock;
        int shipClockMask;
        NSMutableArray* triggerGroups;
        NSMutableArray* triggerNames;
        unsigned long errorCount;
        BOOL enableClock;
		BOOL shipFirstLast;
		BOOL gotFirstClk[4];
        //local cache variables
        NSArray* dataTakers;	//cache of data takers.
}

#pragma mark ¥¥¥Accessors
- (BOOL) shipFirstLast;
- (void) setShipFirstLast:(BOOL)aShipFirstLast;
- (unsigned long) lowerClock;
- (void) setLowerClock:(unsigned long)newGtidLower;
- (unsigned long) upperClock;
- (void) setUpperClock:(unsigned long)newGtidUpper;

- (NSArray*) triggerGroups;
- (void) setTriggerGroups:(NSMutableArray*)anArray;

- (NSMutableArray*) children;

- (void) setShipClockMask:(int)aValue;
- (BOOL) shipClock:(int)index;
- (void) setShipClock:(int)index state:(BOOL)state;
- (BOOL) enableClock;
- (void) setEnableClock: (BOOL) flag;

- (unsigned long) errorCount;
- (void) setErrorCount:(unsigned long)count;

- (void) setTriggerNames:(NSMutableArray*)anArray;
- (NSString *) triggerName:(int)index;
- (void) setTriggerName:(NSString *)aTriggerName index:(int)index;

- (unsigned long) clockDataId;
- (void) setClockDataId: (unsigned long) ClockDataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;

#pragma mark ¥¥¥Hardware Access
- (void) reset;  
- (void) softLatch;
- (void) writeEnableClock:(BOOL)state;
- (void) resetClock;  
- (void) loadLowerClock:(unsigned long)aValue;  
- (void) loadUpperClock:(unsigned long)aValue;  

- (unsigned short) 	readBoardID;
- (unsigned short) 	readStatus;  

- (unsigned long) readLowerClock:(int)index;
- (unsigned long) readUpperClock:(int)index;

- (NSString*) 		boardIdString;
- (unsigned short) 	decodeBoardId:(unsigned short) aValue;
- (unsigned short) 	decodeBoardType:(unsigned short) aValue;
- (unsigned short) 	decodeBoardRev:(unsigned short) aValue;
- (NSString *)		decodeBoardName:(unsigned short) aValue;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end



#pragma mark ¥¥¥External String Definitions
extern NSString* OR4ChanTriggerModelShipFirstLastChanged;
extern NSString* OR4ChanLowerClockChangedNotification;
extern NSString* OR4ChanUpperClockChangedNotification;
extern NSString* OR4ChanShipClockChangedNotification;
extern NSString* OR4ChanNameChangedNotification;
extern NSString* OR4ChanErrorCountChangedNotification;
extern NSString* OR4ChanEnableClockChangedNotification;

extern NSString* OR4ChanSettingsLock;
extern NSString* OR4ChanSpecialLock;



