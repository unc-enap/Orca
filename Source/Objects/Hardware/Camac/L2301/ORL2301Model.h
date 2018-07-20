/*
 *  ORL2301Model.h
 *  Orca
 *
 *  Created by Sam Meijer, Jason Detwiler, and David Miller, July 2012.
 *  Adapted from AD811 code by Mark Howe, written Sat Nov 16 2002.
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
#import "ORCamacListProtocol.h"

@class ORDataPacket;

enum L2301Constants {
    kNBins = 1024,
    kMaxDataLen = 1028,
    kHalfMaxCounts = 32768,
    kMaxCounts = 65536
};

@interface ORL2301Model : ORCamacIOCard <ORDataTaker> {
@private
	BOOL includeTiming;
	uint32_t dataId;
	
	BOOL suppressZeros;
	BOOL allowOverflow;
	
	// place to cache some stuff for alittle more speed.
	uint32_t 	unChangingDataPart;
	unsigned short cachedStation;
	
	// used during data taking
	unsigned short cachedCounts[kNBins];
	uint32_t dataBuffer[kMaxDataLen];
    
    NSDate *lastDataTS;
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;
        

#pragma mark ¥¥¥Accessors
- (BOOL) includeTiming;
- (void) setIncludeTiming:(BOOL)aIncludeTiming;
- (uint32_t) dataId;
- (void) setDataId:(uint32_t)DataId;
- (BOOL) suppressZeros;
- (void) setSuppressZeros:(BOOL)aFlag;
- (BOOL) allowOverflow;
- (void) setAllowOverflow:(BOOL)aFlag;
- (NSDate *) lastDataTS;
- (void) setLastDataTS: (NSDate *) aLastDataTS;


#pragma mark ¥¥¥Hardware Test functions
- (unsigned short) readQVT;                   // F(2)
- (unsigned short) readQVTAt:(unsigned short)bin;
- (void) readHistIntoDataBuffer;
- (void) clearQVT;                            // F(9)
- (void) writeQVT:(unsigned short)counts;     // F(16)
- (void) writeQVT:(unsigned short)counts atBin:(unsigned short)bin;
- (void) setReadWriteBin:(unsigned short)bin; // F(17)
- (void) stopQVT;                             // F(24)
- (void) incrementQVT;                        // F(25)
- (void) incrementQVTAt:(unsigned short)bin;
- (void) startQVT;                            // F(26)
- (unsigned short) readStatusRegister;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) shipHistogram:(ORDataPacket*)aDataPacket;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORL2301ModelIncludeTimingChanged;
extern NSString* ORL2301SettingsLock;
extern NSString* ORL2301SuppressZerosChangedNotification;
extern NSString* ORL2301AllowOverflowChangedNotification;
