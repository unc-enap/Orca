//  Orca
//  ORFlashCamCard.h
//
//  Created by Tom Caldwell on Monday Dec 16,2019
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORCard.h"
#import "ORConnector.h"

#define kFlashCamFirmwareVerLen 4

@interface ORFlashCamCard : ORCard {
    unsigned int cardAddress;
    ORConnector* ethConnector;
    NSArray* firmwareVer;
    NSMutableArray* taskdata;
    uint32_t exceptionCount;
}

#pragma mark •••Accessors
- (id) init;
- (void) dealloc;
- (id) adapter;
- (Class) guardianClass;
- (NSString*) cardSlotChangedNotification;
- (unsigned int) cardAddress;
- (NSArray*) firmwareVer;
- (NSString*) firmwareVerType;
- (NSString*) firmwareVerRev;
- (NSString*) firmwareVerDate;
- (NSString*) firmwareVerTag;
- (void) setCardAddress:(unsigned int)addr;
- (uint32_t) exceptionCount;
- (void) incExceptionCount;
- (void) clearExceptionCount;

#pragma mark •••Commands
- (void) requestFirmwareVersion;
- (void) taskData:(NSDictionary*)taskData;
- (void) taskFinished:(id)task;

@end

extern NSString* ORFlashCamCardSlotChangedNotification;
extern NSString* ORFlashCamCardEthConnector;
extern NSString* ORFlashCamCardAddressChanged;
extern NSString* ORFlashCamCardFirmwareVerRequest;
extern NSString* ORFlashCamCardFirmwareVerChanged;
extern NSString* ORFlashCamCardExceptionCountChanged;

@interface NSObject (ORFlashCamCard)
- (void) postUpdateList:(NSArray*)cmds;
@end

