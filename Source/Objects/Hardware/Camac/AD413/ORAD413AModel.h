/*
 *  ORAD413AModel.h
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

enum {
    kEnableGate1Bit     = 0,
    kEnableGate2Bit     = 1,
    kEnableGate3Bit     = 2,
    kEnableGate4Bit     = 3,
    kMasterGateBit      = 4,
    kZeroSuppressionBit = 8,
    kECLPortEnableBit   = 9,
    kSinglesBit			= 12,	//in manual -- coincidence bit
    kRandomAccessBit    = 13,
    kLAMEnableBit       = 14,
    kOFSuppressionBit   = 15,
	
};


@interface ORAD413AModel : ORCamacIOCard <ORDataTaker,ORFeraReadout> {
    @private
        unsigned long dataId;
        unsigned short onlineMask;
		NSMutableArray* discriminators;
        
 		short vsn;
		BOOL  CAMACMode;
		BOOL lamEnable;
		BOOL  singles;
        BOOL  randomAccessMode;
		BOOL  ofSuppressionMode;
		BOOL  zeroSuppressionMode;
		BOOL  gateEnable[5];
        short onlineChannelCount;
        short onlineList[4];
	
		BOOL  checkLAM;;
		//place to cache some stuff for alittle more speed.
		unsigned long 	unChangingDataPart;
		unsigned short cachedStation;
		BOOL oldZeroSuppressionMode;
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;
        
#pragma mark ¥¥¥Accessors
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (NSMutableArray *) discriminators;
- (void) setDiscriminators: (NSMutableArray *) anArray;

- (unsigned char)   onlineMask;
- (void)	    setOnlineMask:(unsigned char)anOnlineMask;
- (BOOL)	    onlineMaskBit:(int)bit;
- (void)	    setOnlineMaskBit:(int)bit withValue:(BOOL)aValue;
- (void)        setDiscriminator:(unsigned short)aValue forChan:(int)aChan;
- (unsigned short) discriminatorForChan:(int)aChan;

//control Reg1
- (BOOL) singles;
- (void) setSingles:(BOOL)aState;
- (BOOL) randomAccessMode;
- (void) setRandomAccessMode:(BOOL)aState;
- (BOOL) zeroSuppressionMode;
- (void) setZeroSuppressionMode:(BOOL)aState;
- (BOOL) ofSuppressionMode;
- (void) setOfSuppressionMode:(BOOL)aState;
- (BOOL) CAMACMode;
- (void) setCAMACMode:(BOOL)aState;
- (BOOL) lamEnable;
- (void) setLamEnable: (BOOL) aState;

- (BOOL) gateEnable:(int)index;
- (void) setGateEnable:(int)index withValue:(BOOL) aState;
- (int) vsn;
- (void) setCheckLAM:(BOOL)aState;

#pragma mark ¥¥¥Hardware functions
- (void) readControlReg1;
- (void) readControlReg2;
- (void) writeControlReg1;
- (void) writeControlReg2;
- (void) readDiscriminators;
- (void) writeDiscriminators;
- (void) clearModule;
- (void) clearLAM;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;

#pragma mark ¥¥¥FERA
- (void) setVSN:(int)aVSN;
- (void) setFeraEnable:(BOOL)aState;
- (void) shipFeraData:(ORDataPacket*)aDataPacket data:(unsigned long)data;
- (int) maxNumChannels;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORAD413AOnlineMaskChangedNotification;
extern NSString* ORAD413ASettingsLock;
extern NSString* ORAD413ADiscriminatorChangedNotification;
extern NSString* ORAD413AControlReg1ChangedNotification;
extern NSString* ORAD413AControlReg2ChangedNotification;
