//
//  ORCytecVM8Model.h
//  Orca
//
//  Created by Mark Howe on Mon 22 Aug 2016
//  Copyright © 2016, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina  sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORVmeIOCard.h"

#define kCytecVM8Number32ChannelSets 2

@interface ORCytecVM8Model :  ORVmeIOCard
{
	@private
        uint32_t writeValue;
        unsigned short boardId;
        unsigned short deviceType;
        BOOL formC;
        NSLock* hwLock;
}


#pragma mark •••Accessors
- (uint32_t) writeValue;
- (void) setWriteValue:(uint32_t)aValue;
- (unsigned short) boardId;
- (unsigned short) deviceType;
- (BOOL) formC;
- (void) setFormC:(BOOL)aFlag;

#pragma mark •••Hardware Access
- (uint32_t) readRelays;
- (uint32_t) readFormC;
- (unsigned short) readBoardId;
- (unsigned short) readDeviceType;
- (void) writeFormC:(BOOL)aValue;
- (uint32_t) read0_7;
- (uint32_t) read8_15;
- (uint32_t) read16_23;
- (uint32_t) read24_31;
- (void) writeRelays:(uint32_t) aChannelMask;
- (void) syncWithHardware;
- (void) reset;
- (void) dump;
@end

#pragma mark •••External String Definitions
extern NSString* ORCytecVM8WriteValueChanged;
extern NSString* ORCytectVM8BoardIdChanged;
extern NSString* ORCytectVM8DeviceTypeChanged;
extern NSString* ORCytectVM8FormCChanged;

