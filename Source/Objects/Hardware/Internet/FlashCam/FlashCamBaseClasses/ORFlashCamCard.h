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
#import "ORTimeRate.h"
#import "fcio.h"

#define kFlashCamFirmwareVerLen 4
#define kFlashCamCardNTemps     7
#define kFlashCamCardNVoltages  6

@interface ORFlashCamCard : ORCard {
    unsigned int cardAddress;
    unsigned int promSlot;
    uint8_t boardRevision;
    uint64_t hardwareID;
    ORConnector* ethConnector;
    ORConnector* trigConnector;
    NSArray* firmwareVer;
    NSMutableArray* taskdata;
    uint32_t exceptionCount;
    unsigned int fcioID;
    unsigned int status;
    unsigned int statusEvent;
    unsigned int statusPPS;
    unsigned int statusTicks;
    unsigned int totalErrors;
    unsigned int envErrors;
    unsigned int ctiErrors;
    unsigned int linkErrors;
    unsigned int otherErrors;
    ORTimeRate* tempHistory[kFlashCamCardNTemps];
    ORTimeRate* voltageHistory[kFlashCamCardNVoltages];
    ORTimeRate* currentHistory;
    ORTimeRate* humidityHistory;
}

#pragma mark •••Accessors
- (id) init;
- (void) dealloc;
- (id) adapter;
- (Class) guardianClass;
- (NSString*) cardSlotChangedNotification;
- (unsigned int) cardAddress;
- (unsigned int) promSlot;
- (uint8_t) boardRevision;
- (uint64_t) hardwareID;
- (NSString*) uniqueHWID;
- (ORConnector*) ethConnector;
- (ORConnector*) trigConnector;
- (NSArray*) firmwareVer;
- (NSString*) firmwareVerType;
- (NSString*) firmwareVerRev;
- (NSString*) firmwareVerDate;
- (NSString*) firmwareVerTag;
- (unsigned int) fcioID;
- (unsigned int) status;
- (unsigned int) statusEvent;
- (unsigned int) statusPPS;
- (unsigned int) statusTicks;
- (unsigned int) totalErrors;
- (unsigned int) envErrors;
- (unsigned int) ctiErrors;
- (unsigned int) linkErrors;
- (unsigned int) otherErrors;
- (unsigned int) nTempHistories;
- (unsigned int) nVoltageHistories;
- (ORTimeRate*) tempHistory:(unsigned int)index;
- (ORTimeRate*) voltageHistory:(unsigned int)index;
- (ORTimeRate*) currentHistory;
- (ORTimeRate*) humidityHistory;
- (void) setCardAddress:(unsigned int)addr;
- (void) setPROMSlot:(unsigned int)slot;
- (void) setBoardRevision:(uint8_t)revision;
- (void) setHardwareID:(uint64_t)hwid;
- (void) setUniqueHWID:(NSString*)uid;
- (void) setEthConnector:(ORConnector*)connector;
- (void) setTrigConnector:(ORConnector*)connector;
- (uint32_t) exceptionCount;
- (void) incExceptionCount;
- (void) clearExceptionCount;
- (void) setFCIOID:(unsigned int)fcid;

#pragma mark •••Commands
- (void) requestFirmwareVersion;
- (void) requestReboot;
- (void) readStatus:(fcio_status*)fcstatus atIndex:(unsigned int)index;
- (void) taskData:(NSDictionary*)taskData;
- (void) taskFinished:(id)task;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

@end

extern NSString* ORFlashCamCardSlotChangedNotification;
extern NSString* ORFlashCamCardEthConnector;
extern NSString* ORFlashCamCardAddressChanged;
extern NSString* ORFlashCamCardPROMSlotChanged;
extern NSString* ORFlashCamCardFirmwareVerRequest;
extern NSString* ORFlashCamCardFirmwareVerChanged;
extern NSString* ORFlashCamCardExceptionCountChanged;
extern NSString* ORFlashCamCardStatusChanged;
extern NSString* ORFlashCamCardSettingsLock;

@interface NSObject (ORFlashCamCard)
- (void) postUpdateList:(NSArray*)cmds;
@end

