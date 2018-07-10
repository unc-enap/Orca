//
//  ORCircularBufferReader.h
//  Orca
//
//  Created by Mark Howe on Tue Apr 01 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORCircularBuffer.h"

#pragma mark •••Forward Declaration
@class ORDataPacket;

@interface ORCircularBufferReader : ORCircularBuffer {

}
- (void) clear;
- (void) writeControlBlockHeader:(SCBHeader*)theControlBlockHeader;
- (tCBWord) readBlockUsing:(SCBHeader*)theControlBlockHeader into:(tCBWord*)aBlockOfMemory size:(tCBWord) aLongWordsInBlock;
- (BOOL) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
@end
