//  Orca
//  ORFlashCamCard.m
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

#import "ORFlashCamCard.h"
#import "ORFlashCamReadoutModel.h"

NSString* ORFlashCamCardSlotChangedNotification = @"ORFlashCamCardSlotChangedNotification";
NSString* ORFlashCamCardEthConnector            = @"ORFlashCamCardEthConnector";
NSString* ORFlashCamCardAddressChanged          = @"ORFlashCamCardAddressChanged";
NSString* ORFlashCamCardPROMSlotChanged         = @"ORFlashCamCardPROMSlotChanged";
NSString* ORFlashCamCardFirmwareVerRequest      = @"ORFlashCamCardFirmwareVerRequest";
NSString* ORFlashCamCardFirmwareVerChanged      = @"ORFlashCamCardFirmwareVerChanged";
NSString* ORFlashCamCardExceptionCountChanged   = @"ORFlashCamCardExceptionCountChanged";
NSString* ORFlashCamCardStatusChanged           = @"ORFlashCamCardStatusChanged";
NSString* ORFlashCamCardSettingsLock            = @"ORFlashCamCardSettingsLock";

@implementation ORFlashCamCard

#pragma mark •••Accessors

- (id) init
{
    self = [super init]; //MAH 9/18/22 need to assign self to init 
    [[self undoManager] disableUndoRegistration];
    [self setCardAddress:0];
    [self setPROMSlot:0];
    boardRevision = 0;
    hardwareID    = 0;
    ethConnector  = nil;
    trigConnector = nil;
    firmwareVer = [[NSMutableArray array] retain];
    taskdata = nil;
    fcioID      = 0;
    status      = 0;
    statusEvent = 0;
    statusPPS   = 0;
    statusTicks = 0;
    totalErrors = 0;
    envErrors   = 0;
    ctiErrors   = 0;
    linkErrors  = 0;
    otherErrors = 0;
    for(unsigned int i=0; i<kFlashCamCardNTemps; i++){
        tempHistory[i] = [[ORTimeRate alloc] init]; //MAH 10/1/22 removed retain
        [tempHistory[i] setLastAverageTime:[NSDate date]];
        [tempHistory[i] setSampleTime:10];
    }
    for(unsigned int i=0; i<kFlashCamCardNVoltages; i++){
        voltageHistory[i] = [[ORTimeRate alloc] init]; //MAH 10/1/22 removed retain
        [voltageHistory[i] setLastAverageTime:[NSDate date]];
        [voltageHistory[i] setSampleTime:10];
    }
    currentHistory = [[ORTimeRate alloc] init];//MAH 10/1/22 removed retain
    [currentHistory setLastAverageTime:[NSDate date]];
    [currentHistory setSampleTime:10];
    humidityHistory = [[ORTimeRate alloc] init];//MAH 10/1/22 removed retain
    [humidityHistory setLastAverageTime:[NSDate date]];
    [humidityHistory setSampleTime:10];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) releaseFirmwareVer
{
//    if(firmwareVer){
//        for(NSUInteger i=0; i<[firmwareVer count]; i++) [[firmwareVer objectAtIndex:i] release];
//        [firmwareVer release];
//    }
    
    [firmwareVer release]; //MAH 9/18/22 no need to release each object in array
    firmwareVer = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamCardFirmwareVerChanged object:self];
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if(ethConnector)  [ethConnector  release];
    if(trigConnector) [trigConnector release];
    [self releaseFirmwareVer];
    if(taskdata) [taskdata release];
    for(unsigned int i=0; i<kFlashCamCardNTemps;    i++) [tempHistory[i]    release];
    for(unsigned int i=0; i<kFlashCamCardNVoltages; i++) [voltageHistory[i] release];
    [currentHistory  release];
    [humidityHistory release];
    [super dealloc];
}

- (id) adapter
{
    id anAdapter = [guardian adapter];
    if(anAdapter) return anAdapter;
    else [NSException raise:@"No adapter" format:@"You must place a FlashCam adaptor card into the crate."];
    return nil;
}

- (Class) guardianClass
{
    return NSClassFromString(@"ORFlashCamCrate");
}

- (NSString*) cardSlotChangedNotification
{
    return ORFlashCamCardSlotChangedNotification;
}

#pragma mark •••Accessors

- (unsigned int) cardAddress
{
    return cardAddress;
}

- (unsigned int) promSlot
{
    return promSlot;
}

- (uint8_t) boardRevision
{
    return boardRevision;
}

- (uint64_t) hardwareID
{
    return hardwareID;
}

- (NSString*) uniqueHWID
{
    return [NSString stringWithFormat:@"%hhx-%llx", [self boardRevision], [self hardwareID]];
}

- (ORConnector*) ethConnector
{
    return ethConnector;
}

- (ORConnector*) trigConnector
{
    return trigConnector;
}

- (NSArray*) firmwareVer
{
    return firmwareVer;
}

- (NSString*) firmwareVerType
{
    if(!firmwareVer) return @"";
    if([firmwareVer count] != kFlashCamFirmwareVerLen) return @"";
    return [firmwareVer objectAtIndex:0];
}

- (NSString*) firmwareVerRev
{
    if(!firmwareVer) return @"";
    if([firmwareVer count] != kFlashCamFirmwareVerLen) return @"";
    return [firmwareVer objectAtIndex:1];
}

- (NSString*) firmwareVerDate
{
    if(!firmwareVer) return @"";
    if([firmwareVer count] != kFlashCamFirmwareVerLen) return @"";
    return [firmwareVer objectAtIndex:2];
}

- (NSString*) firmwareVerTag
{
    if(!firmwareVer) return @"";
    if([firmwareVer count] != kFlashCamFirmwareVerLen) return @"";
    return [firmwareVer objectAtIndex:3];
}

- (unsigned int) fcioID
{
    return fcioID;
}

- (unsigned int) status
{
    return status;
}

- (unsigned int) statusEvent
{
    return statusEvent;
}

- (unsigned int) statusPPS
{
    return statusPPS;
}

- (unsigned int) statusTicks
{
    return statusTicks;
}

- (unsigned int) totalErrors
{
    return totalErrors;
}

- (unsigned int) envErrors
{
    return envErrors;
}

- (unsigned int) ctiErrors
{
    return ctiErrors;
}

- (unsigned int) linkErrors
{
    return linkErrors;
}

- (unsigned int) otherErrors
{
    return otherErrors;
}

- (unsigned int) nTempHistories
{
    return kFlashCamCardNTemps;
}

- (unsigned int) nVoltageHistories
{
    return kFlashCamCardNVoltages;
}

- (ORTimeRate*) tempHistory:(unsigned int)index
{
    if(index >= kFlashCamCardNTemps) return nil;
    return tempHistory[index];
}

- (ORTimeRate*) voltageHistory:(unsigned int)index
{
    if(index >= kFlashCamCardNVoltages) return nil;
    return voltageHistory[index];
}

- (ORTimeRate*) currentHistory
{
    return currentHistory;
}

- (ORTimeRate*) humidityHistory
{
    return humidityHistory;
}

- (void) setCardAddress:(unsigned int)addr
{
    if(addr == cardAddress) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setCardAddress:cardAddress];
    cardAddress = addr;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamCardAddressChanged object:self];
}

- (void) setPROMSlot:(unsigned int)slot
{
    if(slot == promSlot || slot > 2) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setPROMSlot:promSlot];
    promSlot = slot;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamCardPROMSlotChanged object:self];
}

- (void) setBoardRevision:(uint8_t)revision
{
    boardRevision = revision;
}

- (void) setHardwareID:(uint64_t)hwid
{
    hardwareID = hwid;
}

- (void) setUniqueHWID:(NSString*)uid
{
    NSArray* a = [uid componentsSeparatedByString:@"-"];
    bool success = true;
    if([a count] == 2){
        if([[a objectAtIndex:0] length]  !=  2 ||
           [[a objectAtIndex:1] length]  != 16) success = false;
        else{
            @try{
                unsigned int br;
                NSScanner* scan = [NSScanner scannerWithString:[a objectAtIndex:0]];
                [scan scanHexInt:&br];
                boardRevision = (uint8_t) (br & 0xFF);
                scan = [NSScanner scannerWithString:[a objectAtIndex:1]];
                [scan scanHexLongLong:&hardwareID];
            }
            @catch(NSException* e){
                success = false;
            }
        }
    }
    else success = false;
    if(!success)
        NSLogColor([NSColor redColor], @"ORFlashCamCard: could not parse unique hw id %@"
                   " for card address 0x%x\n", uid, cardAddress);
}

- (void) setEthConnector:(ORConnector*)connector
{
    [connector retain];
    [ethConnector release];
    ethConnector = connector;
}

- (void) setTrigConnector:(ORConnector*)connector
{
    [connector retain];
    [trigConnector release];
    trigConnector = connector;
}


- (uint32_t) exceptionCount
{
    return exceptionCount;
}

- (void) clearExceptionCount
{
    exceptionCount = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamCardExceptionCountChanged object:self];
}

- (void) incExceptionCount
{
    ++exceptionCount;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamCardExceptionCountChanged object:self];
}

- (void) setFCIOID:(unsigned int)fcid
{
    fcioID = fcid;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamCardStatusChanged object:self];
}


#pragma mark •••Commands

// If this card is connected to an ORFlashCamReadoutModel object either directly or through
// an ORFlashCamEthLink, get the object and run the firmware loading program with flags to
// simply check the firmware version.
- (void) requestFirmwareVersion
{
    if(!ethConnector) return [self releaseFirmwareVer];
    else if(![ethConnector isConnected]){
        NSLog(@"ORFlashCamCard - must connect to FlashCamReadout object to get firmware version\n");
        return [self releaseFirmwareVer];
    }
    id obj = [ethConnector connectedObject];
    if(!obj){
        NSLog(@"ORFlashCamCard - unable to get connected FlashCam object\n");
        return [self releaseFirmwareVer];
    }
    if([[obj className] isEqualToString:@"ORFlashCamEthLinkModel"]){
        NSMutableArray* arr = [obj connectedObjects:@"ORFlashCamReadoutModel"];
        if([arr count] == 0){
            NSLog(@"ORFlashCamCard - must connect to FlashCamReadout object to get firmware version\n");
            return [self releaseFirmwareVer];
        }
        else if([arr count] > 1){
            NSLog(@"ORFlashCamCard - error, multiple FlashCamReadout objects connected\n");
            return [self releaseFirmwareVer];
        }
        obj = [arr objectAtIndex:0];
    }
    else if(![[obj className] isEqualToString:@"ORFlashCamReadoutModel"]){
        NSLog(@"ORFlashCamCard - must connect to FlashCamReadout object to get firmware version\n");
        return [self releaseFirmwareVer];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamCardFirmwareVerRequest object:self];
    [obj getFirmwareVersion:self];
}

// If this card is connected to an ORFlashCamReadoutModel object either directly or through
// an ORFlashCamEthLink, get the object and run the firmware loading program with flags to reboot.
- (void) requestReboot
{
    if(!ethConnector) return [self releaseFirmwareVer];
    else if(![ethConnector isConnected]){
        NSLog(@"ORFlashCamCard - must connect to FlashCamReadout object to reboot\n");
        return;
    }
    id obj = [ethConnector connectedObject];
    if(!obj){
        NSLog(@"ORFlashCamCard - unable to get connected FlashCam object\n");
        return;
    }
    if([[obj className] isEqualToString:@"ORFlashCamEthLinkModel"]){
        NSMutableArray* arr = [obj connectedObjects:@"ORFlashCamReadoutModel"];
        if([arr count] == 0){
            NSLog(@"ORFlashCamCard - must connect to FlashCamReadout object to reboot\n");
            return;
        }
        else if([arr count] > 1){
            NSLog(@"ORFlashCamCard - error, multiple FlashCamReadout objects connected\n");
            return;
        }
        obj = [arr objectAtIndex:0];
    }
    else if(![[obj className] isEqualToString:@"ORFlashCamReadoutModel"]){
        NSLog(@"ORFlashCamCard - must connect to FlashCamReadout object to reboot\n");
        return [self releaseFirmwareVer];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamCardFirmwareVerRequest object:self];
    [obj rebootCard:self];
}

- (void) readStatus:(fcio_status*)fcstatus atIndex:(unsigned int)index
{
    //@synchronized(self){ //MAH 10/24 shouldn't be needed now
        fcio_status fc_status = *fcstatus;
        status      = fc_status.data[index].status;
        statusEvent = fc_status.data[index].eventno;
        statusPPS   = fc_status.data[index].pps;
        statusTicks = fc_status.data[index].ticks;
        totalErrors = fc_status.data[index].totalerrors;
        envErrors   = fc_status.data[index].enverrors;
        ctiErrors   = fc_status.data[index].ctierrors;
        linkErrors  = fc_status.data[index].linkerrors;
        unsigned int nother = 0;
        for(unsigned int i=0; i<5; i++) nother += fc_status.data[index].othererrors[i];
        otherErrors = nother;
        for(unsigned int i=0; i<kFlashCamCardNTemps; i++)
            [tempHistory[i] addDataToTimeAverage:fc_status.data[index].environment[(i<5)?i:i+8]];
        for(unsigned int i=0; i<kFlashCamCardNVoltages; i++)
            [voltageHistory[i] addDataToTimeAverage:fc_status.data[index].environment[i+5]];
        [currentHistory  addDataToTimeAverage:fc_status.data[index].environment[11]];
        [humidityHistory addDataToTimeAverage:fc_status.data[index].environment[12]];
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORFlashCamCardStatusChanged object:self userInfo:nil waitUntilDone:NO];//MAH 10/24/22 GUI update have to be on main thread
    //}
}

// Append any data from the firmware version request task to taskdata.  If the data contains
// ORFlashCamCard, then it is the response to the expect script.  In that case, print log statement.
- (void) taskData:(NSDictionary*)taskData
{
    if(!taskData) return;
    NSString* text = [taskData objectForKey:@"Text"]; //MAH 9/18/22 no need for the retain??
    if(!text) return;
    if(!taskdata) taskdata = [[[NSMutableArray alloc] init] retain];
    [taskdata addObject:[NSString stringWithString:text]];
    NSRange r = [text rangeOfString:@"ORFlashCamCard"];
    if(r.location != NSNotFound){
        NSString* s = [text substringWithRange:NSMakeRange(r.location, [text length]-r.location)];
        r = [s rangeOfString:@" endl "];
        if(r.location != NSNotFound) NSLog(@"%@\n", [s substringWithRange:NSMakeRange(0, r.location)]);
    }
}

// Once the firmware version request task is complete, release the old firmware version
// strings then parse the data from the task.  In case the data is split between objects
// in the data array, merge first, then look for EfbpSearchDevice.  If the next string is
// found, then get the components of the firmware version string.
- (void) taskFinished:(id)task
{
    if(!task){
        [self releaseFirmwareVer];
        return;
    }
    [firmwareVer release]; //MAH 9/18/22 no need to release each object, just the array
    firmwareVer = nil;
    if(taskdata){
        NSString* s = [taskdata componentsJoinedByString:@" "];
        NSArray*  t = [s componentsSeparatedByString:@" "];
        NSArray* td = [t filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        NSIndexSet* index = [td indexesOfObjectsPassingTest:^(id obj, NSUInteger ids, BOOL* stop){
            return [obj containsString:@"EfbpSearchDevice"]; }];
        [index enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL* stop){
            if([td count] <= idx+15) return;
            if([[td objectAtIndex:idx+1] isEqualToString:@"found"] &&
                [[td objectAtIndex:idx+4] containsString:[NSString stringWithFormat:@"%d/0x",cardAddress]]){
                NSString* fwt = [NSString stringWithString:[td objectAtIndex:idx+7]];//MAH 9/18/22 no need for retain
                NSString* fwr = [NSString stringWithString:[td objectAtIndex:idx+9]];//MAH 9/18/22 no need for retain
                NSString* fwd = [NSString stringWithFormat:@"%@ %@ %@",
                                 [td objectAtIndex:idx+12], [td objectAtIndex:idx+11], [td objectAtIndex:idx+13]];//MAH 9/18/22 no need for retain
                NSString* fwg = [NSString stringWithString:[td objectAtIndex:idx+15]];//MAH 9/18/22 no need for retain
                [firmwareVer release];
                firmwareVer = [[NSArray arrayWithObjects:fwt, fwr, fwd, fwg, nil] retain];
                if([td count] >= idx+17){
                    if([[td objectAtIndex:idx+17] isEqualToString:@"Booting"]){
                        NSLog(@"ORFlashCamCard: rebooting card at 0x%x from PROM slot %d\n", cardAddress, promSlot);
                        NSLog(@"\t\tfirmware: %@\n", [firmwareVer componentsJoinedByString:@" / "]);
                    }
                }
                *stop = YES;
            }
        }];
        [taskdata release];
        taskdata = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamCardFirmwareVerChanged object:self];
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setCardAddress: [[decoder decodeObjectForKey:@"cardAddress"] unsignedIntValue]];
    [self setPROMSlot:    [[decoder decodeObjectForKey:@"promSlot"] unsignedIntValue]];
    [self setEthConnector: [decoder decodeObjectForKey:@"ethConnector"]];
    [self setTrigConnector:[decoder decodeObjectForKey:@"trigConnector"]];
    boardRevision = 0;
    hardwareID    = 0;
    fcioID        = 0;
    status        = 0;
    statusEvent   = 0;
    statusPPS     = 0;
    statusTicks   = 0;
    totalErrors   = 0;
    envErrors     = 0;
    ctiErrors     = 0;
    linkErrors    = 0;
    otherErrors   = 0;
    for(unsigned int i=0; i<kFlashCamCardNTemps; i++){
        [tempHistory[i] release];
        tempHistory[i] = [[ORTimeRate alloc] init]; //MAH 10/1/22 removed retain
        [tempHistory[i] setLastAverageTime:[NSDate date]];
        [tempHistory[i] setSampleTime:1];
    }
    for(unsigned int i=0; i<kFlashCamCardNVoltages; i++){
        voltageHistory[i] = [[ORTimeRate alloc] init];//MAH 10/1/22 removed retain
        [voltageHistory[i] setLastAverageTime:[NSDate date]];
        [voltageHistory[i] setSampleTime:1];
    }
    currentHistory = [[ORTimeRate alloc] init];//MAH 10/1/22 removed retain
    [currentHistory setLastAverageTime:[NSDate date]];
    [currentHistory setSampleTime:1];
    humidityHistory = [[ORTimeRate alloc] init];//MAH 10/1/22 removed retain
    [humidityHistory setLastAverageTime:[NSDate date]];
    [humidityHistory setSampleTime:1];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[NSNumber numberWithUnsignedInt:cardAddress] forKey:@"cardAddress"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInt:promSlot]    forKey:@"promSlot"];
    [encoder encodeObject:ethConnector  forKey:@"ethConnector"];
    [encoder encodeObject:trigConnector forKey:@"trigConnector"];
    taskdata = nil;
    if(!firmwareVer) firmwareVer = [[NSMutableArray array] retain];

}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* dict = [super addParametersToDictionary:dictionary];
    [dict setObject:[NSNumber numberWithInt:cardAddress] forKey:@"CardAddress"];
    return dict;
}


@end
