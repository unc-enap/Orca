/*
 *  ORTriggerModel.cpp
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
#import "ORTriggerModel.h"

#import "ORVmeCrateModel.h"
#import "ORReadOutList.h"
#import "ORDataTypeAssigner.h"

#pragma mark ¥¥¥Definitions
#define kDefaultAddressModifier		    0x29
#define kDefaultBaseAddress		    0x0007000

#pragma mark ¥¥¥Notification Strings
NSString* ORTriggerGtidLowerChangedNotification 	= @"OR Trigger GTID Lower Changed Notification";
NSString* ORTriggerGtidUpperChangedNotification		= @"OR Trigger GTID Upper Changed Notification";

NSString* ORTriggerShipEvt1ClkChangedNotification	= @"ORTriggerShipEvt1ClkChangedNotification";
NSString* ORTriggerShipEvt2ClkChangedNotification	= @"ORTriggerShipEvt2ClkChangedNotification";
NSString* ORTriggerShipGtErrorCountChangedNotification  = @"ORTriggerShipGtErrorCountChangedNotification";
NSString* ORTriggerInitMultiBoardChangedNotification    = @"ORTriggerInitMultiBoardChangedNotification";
NSString* ORTriggerInitTrig2ChangedNotification         = @"ORTriggerInitTrig2ChangedNotification";

NSString* ORTriggerUseSoftwareGtIdChangedNotification   = @"ORTriggerUseSoftwareGtIdChangedNotification";
NSString* ORTriggerUseNoHardwareChangedNotification     = @"ORTriggerUseNoHardwareChangedNotification";
NSString* ORTriggerSoftwareGtIdChangedNotification      = @"ORTriggerSoftwareGtIdChangedNotification";

//NSString* ORTriggerVmeClkLowerChangedNotification	= @"OR Trigger Clk Lower Changed Notification";
//NSString* ORTriggerVmeClkMiddleChangedNotification	= @"OR Trigger Clk Middle Changed Notification";
//NSString* ORTriggerVmeClkUpperChangedNotification	= @"OR Trigger Clk Upper Changed Notification";

NSString* ORTrigger1NameChangedNotification             = @"ORTrigger1NameChangedNotification";
NSString* ORTrigger2NameChangedNotification             = @"ORTrigger2NameChangedNotification";
NSString* ORTriggerMSAMChangedNotification		= @"ORTriggerMSAMChangedNotification";

NSString* ORTriggerSettingsLock				= @"ORTriggerSettingsLock";
NSString* ORTriggerSpecialLock				= @"ORTriggerSpecialLock";


#pragma mark ¥¥¥Private Implementation
@interface ORTriggerModel (private)
- (void) _readOutChildren:(NSArray*)children dataPacket:(ORDataPacket*)aDataPacket withGTID:(unsigned long)gtid isMSAMEvent:(BOOL)isMSAMEvent;
@end

@implementation ORTriggerModel

- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setBaseAddress:kDefaultBaseAddress];
    [self setAddressModifier:kDefaultAddressModifier];
    
    [self setTrigger1Name:@"Trigger1"];
    [self setTrigger2Name:@"Trigger2"];
    
    ORReadOutList* r1 = [[ORReadOutList alloc] initWithIdentifier:trigger1Name];
    [self setTrigger1Group:r1];
    [r1 release];
    
    ORReadOutList* r2 = [[ORReadOutList alloc] initWithIdentifier:trigger2Name];
    [self setTrigger2Group:r2];
    [r2 release];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) dealloc
{
    [trigger1Group release];
    [trigger2Group release];
    [softwareGtIdAlarm clearAlarm];
    [softwareGtIdAlarm release];
	
    [useNoHardwareAlarm clearAlarm];
    [useNoHardwareAlarm release];
	
    [super dealloc];
}

- (void) sleep
{
    [super sleep];
    [softwareGtIdAlarm clearAlarm];
    [softwareGtIdAlarm release];
    softwareGtIdAlarm = nil;
	
    [useNoHardwareAlarm clearAlarm];
    [useNoHardwareAlarm release];
    useNoHardwareAlarm = nil;
    
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"TriggerCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORTriggerController"];
}

- (NSString*) helpURL
{
	return @"VME/Trigger.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x2a);
}

#pragma mark ¥¥¥Accessors
- (unsigned short) gtidLower
{
    return gtidLower;
}

- (void) setGtidLower:(unsigned short)newGtidLower
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGtidLower:[self gtidLower]];
    
    gtidLower=newGtidLower;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTriggerGtidLowerChangedNotification
                                                        object:self];
}


- (unsigned short) gtidUpper
{
    return gtidUpper;
}

- (void) setGtidUpper:(unsigned short)newGtidUpper
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGtidUpper:[self gtidUpper]];
    
    gtidUpper=newGtidUpper;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTriggerGtidUpperChangedNotification
                                                        object:self];
}

- (ORReadOutList*) trigger1Group
{
    return trigger1Group;
}
- (void) setTrigger1Group:(ORReadOutList*)newTrigger1Group
{
    [trigger1Group autorelease];
    trigger1Group=[newTrigger1Group retain];
}

- (ORReadOutList*) trigger2Group
{
    return trigger2Group;
}
- (void) setTrigger2Group:(ORReadOutList*)newTrigger2Group
{
    [trigger2Group autorelease];
    trigger2Group=[newTrigger2Group retain];
}

- (BOOL) shipEvt1Clk
{
    return shipEvt1Clk;
}

- (BOOL) shipEvt2Clk
{
    return shipEvt2Clk;
}

- (void) setShipEvt1Clk:(BOOL)state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipEvt1Clk:shipEvt1Clk];
    shipEvt1Clk = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTriggerShipEvt1ClkChangedNotification
                                                        object:self];
    if(state)NSLog(@"ORTriggerModel: Data Shipping: Set to Ship Event Clock 1\n");
    else NSLog(@"ORTriggerModel: Data Shipping: Set to NOT Ship Event Clock 1\n");
}

- (void) setShipEvt2Clk:(BOOL)state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipEvt2Clk:shipEvt2Clk];
    shipEvt2Clk = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTriggerShipEvt2ClkChangedNotification
                                                        object:self];
    if(state)NSLog(@"ORTriggerModel: Data Shipping: Set to Ship Event Clock 2\n");
    else NSLog(@"ORTriggerModel: Data Shipping: Set to NOT Ship Event Clock 2\n");
}

- (BOOL) initWithMultiBoardEnabled
{
    return initWithMultiBoardEnabled;
}
- (void) setInitWithMultiBoardEnabled:(BOOL)newInitWithMultiBoardEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInitWithMultiBoardEnabled:initWithMultiBoardEnabled];
    initWithMultiBoardEnabled=newInitWithMultiBoardEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTriggerInitMultiBoardChangedNotification
                                                        object:self];
    if(initWithMultiBoardEnabled) NSLog(@"ORTriggerModel: Set with Multiboard Enabled\n");
    else NSLog(@"ORTriggerModel: Set with Multiboard Disabled\n");
}

- (BOOL) initWithTrig2InhibitEnabled
{
    return initWithTrig2InhibitEnabled;
}
- (void) setInitWithTrig2InhibitEnabled:(BOOL)newInitWithTrig2InhibitEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInitWithTrig2InhibitEnabled:initWithTrig2InhibitEnabled];
    initWithTrig2InhibitEnabled=newInitWithTrig2InhibitEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTriggerInitTrig2ChangedNotification
                                                        object:self];
    if(initWithTrig2InhibitEnabled) NSLog(@"ORTriggerModel: Set with Trigger 2 Inhibit Enabled\n");
    else NSLog(@"ORTriggerModel: Set with Trigger 2 Inhibit Disabled\n");
}



- (unsigned long) gtErrorCount
{
    return gtErrorCount;
}
- (void) setGtErrorCount:(unsigned long)count
{
    gtErrorCount = count;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTriggerShipGtErrorCountChangedNotification
                                                        object:self];
    
}

- (BOOL) useSoftwareGtId
{
    return useSoftwareGtId;
}
- (void) setUseSoftwareGtId:(BOOL)newUseSoftwareGtId
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseSoftwareGtId:useSoftwareGtId];
    useSoftwareGtId=newUseSoftwareGtId;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTriggerUseSoftwareGtIdChangedNotification
                                                        object:self];
    
    [self checkSoftwareGtIdAlarm];
    [self checkUseNoHardwareAlarm];
    
}

- (BOOL) useNoHardware
{
    return useNoHardware;
}

- (void) setUseNoHardware:(BOOL)newUseNoHardware
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseNoHardware:useNoHardware];
    useNoHardware=newUseNoHardware;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTriggerUseNoHardwareChangedNotification
                                                        object:self];
    
    [self checkUseNoHardwareAlarm];
    
}


- (unsigned long) softwareGtId
{
    return softwareGtId;
}
- (void) setSoftwareGtId:(unsigned long)newSoftwareGtId
{
    softwareGtId=newSoftwareGtId;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTriggerSoftwareGtIdChangedNotification
                                                        object:self];
}

- (void) incrementSoftwareGtId
{
    if(++softwareGtId > 0x00ffffff)softwareGtId = 0;
    [self setSoftwareGtId: softwareGtId];
}

// ----------------------------------------------------------
// - trigger1Name:
// ----------------------------------------------------------
- (NSString *) trigger1Name
{
    return trigger1Name;
}

// ----------------------------------------------------------
// - setTrigger1Name:
// ----------------------------------------------------------
- (void) setTrigger1Name: (NSString *) aTrigger1Name
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger1Name:trigger1Name];
    [trigger1Name autorelease];
    trigger1Name = [aTrigger1Name copy];
    
    [trigger1Group setIdentifier:trigger1Name];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger1NameChangedNotification
                                                        object:self];
    
    
}

// ----------------------------------------------------------
// - trigger2Name:
// ----------------------------------------------------------
- (NSString *) trigger2Name
{
    return trigger2Name;
}

// ----------------------------------------------------------
// - setTrigger2Name:
// ----------------------------------------------------------
- (void) setTrigger2Name: (NSString *) aTrigger2Name
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger2Name:trigger2Name];
    [trigger2Name autorelease];
    trigger2Name = [aTrigger2Name copy];
    
    [trigger2Group setIdentifier:trigger2Name];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger2NameChangedNotification
                                                        object:self];
}

- (BOOL)useMSAM
{
    return useMSAM;
}

- (void)setUseMSAM:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseMSAM:useMSAM];
    useMSAM = flag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTriggerMSAMChangedNotification
                                                        object:self];
}

#pragma mark ¥¥¥Hardware Access
- (unsigned short) 	readBoardID;
{
    unsigned short val = 0;
    [[self adapter] readWordBlock:&val
                        atAddress:[self baseAddress]+kBoardIDRegister
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return val;
}

- (unsigned short) 	readStatus
{
    unsigned short val = 0;
    [[self adapter] readWordBlock:&val
                        atAddress:[self baseAddress]+kStatusRegister
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return val;
}

- (void) reset
{
    unsigned short val = 0;
    [[self adapter] writeWordBlock:&val
                         atAddress:[self baseAddress]+kResetRegister
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) enableBusyOutput:(BOOL)enable
{
    unsigned short val = enable;
    [[self adapter] writeWordBlock:&val
                         atAddress:[self baseAddress]+kBusyEnable
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) resetGtEvent1
{
    unsigned short val = 1;
    [[self adapter] writeWordBlock:&val
                         atAddress:[self baseAddress]+kEvent1Reset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) resetGtEvent2
{
    unsigned short val = 1;
    [[self adapter] writeWordBlock:&val
                         atAddress:[self baseAddress]+kEvent2Reset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) enableMultiBoardOutput:(BOOL) enable
{
    unsigned short val = enable;
    [[self adapter] writeWordBlock:&val
                         atAddress:[self baseAddress]+kMultiBoardOutputEnable
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (unsigned short) 	readLowerEvent1GtId
{
    unsigned short val = 0;
    [[self adapter] readWordBlock:&val
                        atAddress:[self baseAddress]+kLowerEvent1GtIdRegister
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return val;
}

- (unsigned short) 	readUpperEvent1GtId
{
    unsigned short val = 0;
    [[self adapter] readWordBlock:&val
                        atAddress:[self baseAddress]+kUpperEvent1GtIdRegister
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return val;
}

- (unsigned short) 	readLowerEvent2GtId
{
    unsigned short val = 0;
    [[self adapter] readWordBlock:&val
                        atAddress:[self baseAddress]+kLowerEvent2GtIdRegister
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return val;
}

- (unsigned short) 	readUpperEvent2GtId
{
    unsigned short val = 0;
    [[self adapter] readWordBlock:&val
                        atAddress:[self baseAddress]+kUpperEvent2GtIdRegister
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    return val;
}

- (unsigned long) getGtId1
{
    if(useNoHardware || useSoftwareGtId)  return softwareGtId;
    else return (([self readUpperEvent1GtId] & 0x00ff)<<16) | [self readLowerEvent1GtId];;
}

- (unsigned long) getGtId2
{
    if(useNoHardware || useSoftwareGtId)  return softwareGtId;
    else return (([self readUpperEvent2GtId] & 0x00ff)<<16) | [self readLowerEvent2GtId];
}

-(void) loadLowerGtId:(unsigned short)  aVal
{
    [[self adapter] writeWordBlock:&aVal
                         atAddress:[self baseAddress]+kLoadLowerGtId
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) loadUpperGtId:(unsigned short)  aVal
{
    [[self adapter] writeWordBlock:&aVal
                         atAddress:[self baseAddress]+kLoadUpperGtId
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}


- (void) softGT
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:[self baseAddress]+kSoftGtTrig
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (void) syncClear
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:[self baseAddress]+kSoftSynClr
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) softGTSyncClear
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:[self baseAddress]+kSoftGtTrigSynClr
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (void) syncClear24
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:[self baseAddress]+kSoftSynClr24
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) clearMSAM
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:[self baseAddress]+kClrMSAMEnable
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) testLatchGtId1
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:[self baseAddress]+kTestLatchGtId1
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) testLatchGtId2
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:[self baseAddress]+kTestLatchGtId2
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (BOOL) anEvent:(unsigned short)  aVal
{
    return aVal & kEventMask;
}


- (BOOL) eventBit1Set:(unsigned short)  aVal
{
    return aVal & kEvent1Mask;
}

- (BOOL) eventBit2Set:(unsigned short)  aVal
{
    return aVal & kEvent2Mask;
}

- (BOOL) validEvent1GtBitSet:(unsigned short)  aVal
{
    return aVal & kValidEvent1GtMask;
}
- (BOOL) validEvent2GtBitSet:(unsigned short)  aVal
{
    return aVal & kValidEvent2GtMask;
}

- (BOOL) countErrorBitSet:(unsigned short)  aVal
{
    return aVal & kCountErrorMask;
}

//- (BOOL) clockEnabledBitSet:(unsigned short)  aVal
//{
//	return aVal & kClockEnabledMask;
//}


- (NSMutableArray*) children {
    //methods exists to give common interface across all objects for display in lists
    return [NSMutableArray arrayWithObjects:trigger1Group,trigger2Group,nil];
}


#pragma mark ¥¥¥Archival
static NSString *ORTriggerGtIdLower 		= @"Trigger GTID Lower";
static NSString *ORTriggerGtIdUpper 		= @"Trigger GTID Upper";
//static NSString *ORTriggerVmeClkLower         = @"Trigger VME CLOCK Lower";
//static NSString *ORTriggerVmeClkMiddle        = @"Trigger VME CLOCK Middle";
//static NSString *ORTriggerVmeClkUpper         = @"Trigger VME CLOCK Upper";
static NSString *ORTriggerGroup1                = @"ORTrigger Group 1";
static NSString *ORTriggerGroup2                = @"ORTrigger Group 2";
static NSString *ORTriggerShipEvt1Clk		= @"ORTriggerShipEvt1Clk";
static NSString *ORTriggerShipEvt2Clk		= @"ORTriggerShipEvt2Clk";
static NSString *ORTriggerInitWithMultiBoardEnabled = @"ORTriggerInitWithMultiBoardEnabled";
static NSString *ORTriggerInitWithTrig2InhibitEnabled = @"ORTriggerInitWithTrig2InhibitEnabled";
static NSString *ORTriggerUseSoftwareGtId       = @"ORTriggerUseSoftwareGtId";
static NSString *ORTriggerNoHardware       	= @"ORTriggerNoHardware";
static NSString *ORTriggerSoftwareGtId          = @"ORTriggerSoftwareGtId32";
static NSString *ORTrigger1Name                 = @"ORTrigger1Name";
static NSString *ORTrigger2Name                 = @"ORTrigger2Name";
static NSString *ORTriggerUseMSAM		= @"ORTriggerUseMSAM";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setGtidLower:[decoder decodeIntForKey:ORTriggerGtIdLower]];
    [self setGtidUpper:[decoder decodeIntForKey:ORTriggerGtIdUpper]];
    
    //[self setVmeClkLower:[decoder decodeIntForKey:ORTriggerVmeClkLower]];
    //[self setVmeClkMiddle:[decoder decodeIntForKey:ORTriggerVmeClkMiddle]];
    //[self setVmeClkUpper:[decoder decodeIntForKey:ORTriggerVmeClkUpper]];
    
    [self setTrigger1Group:[decoder decodeObjectForKey:ORTriggerGroup1]];
    [self setTrigger2Group:[decoder decodeObjectForKey:ORTriggerGroup2]];
    
    [self setShipEvt1Clk:[decoder decodeBoolForKey:ORTriggerShipEvt1Clk]];
    [self setShipEvt2Clk:[decoder decodeBoolForKey:ORTriggerShipEvt2Clk]];
    [self setInitWithMultiBoardEnabled:[decoder decodeBoolForKey:ORTriggerInitWithMultiBoardEnabled]];
    [self setInitWithTrig2InhibitEnabled:[decoder decodeBoolForKey:ORTriggerInitWithTrig2InhibitEnabled]];
    
    [self setUseSoftwareGtId:[decoder decodeBoolForKey:ORTriggerUseSoftwareGtId]];
    [self setSoftwareGtId:[decoder decodeInt32ForKey:ORTriggerSoftwareGtId]];
    
    [self setTrigger1Name:[decoder decodeObjectForKey:ORTrigger1Name]];
    [self setTrigger2Name:[decoder decodeObjectForKey:ORTrigger2Name]];
    
    [self setUseNoHardware:[decoder decodeBoolForKey:ORTriggerNoHardware]];
    [self setUseMSAM:[decoder decodeBoolForKey:ORTriggerUseMSAM]];
    
    if(trigger1Name == nil || [trigger1Name length]==0){
        [self setTrigger1Name:@"Trigger1"];
    }
    
    if(trigger2Name == nil || [trigger2Name length]==0){
        [self setTrigger2Name:@"Trigger2"];
    }
    
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:[self gtidLower] forKey:ORTriggerGtIdLower];
    [encoder encodeInt:[self gtidUpper] forKey:ORTriggerGtIdUpper];
    
    //[encoder encodeInt:[self vmeClkLower] forKey:ORTriggerVmeClkLower];
    //[encoder encodeInt:[self vmeClkMiddle] forKey:ORTriggerVmeClkMiddle];
    //[encoder encodeInt:[self vmeClkUpper] forKey:ORTriggerVmeClkUpper];
    
    [encoder encodeObject:[self trigger1Group] forKey:ORTriggerGroup1];
    [encoder encodeObject:[self trigger2Group] forKey:ORTriggerGroup2];
    [encoder encodeBool:[self shipEvt1Clk] forKey:ORTriggerShipEvt1Clk];
    [encoder encodeBool:[self shipEvt2Clk] forKey:ORTriggerShipEvt2Clk];
    [encoder encodeBool:[self initWithMultiBoardEnabled] forKey:ORTriggerInitWithMultiBoardEnabled];
    [encoder encodeBool:[self initWithTrig2InhibitEnabled] forKey:ORTriggerInitWithTrig2InhibitEnabled];
    
    [encoder encodeBool:[self useSoftwareGtId] forKey:ORTriggerUseSoftwareGtId];
    [encoder encodeInt32:[self softwareGtId] forKey:ORTriggerSoftwareGtId];
    
    [encoder encodeObject:[self trigger1Name] forKey:ORTrigger1Name];
    [encoder encodeObject:[self trigger2Name] forKey:ORTrigger2Name];
    [encoder encodeBool:[self useNoHardware] forKey:ORTriggerNoHardware];
    [encoder encodeBool:[self useMSAM] forKey:ORTriggerUseMSAM];
    
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];    
    [objDictionary setObject:[NSNumber numberWithBool:shipEvt1Clk] forKey:@"shipEvt1Clk"];
    [objDictionary setObject:[NSNumber numberWithBool:shipEvt2Clk] forKey:@"shipEvt2Clk"];
    [objDictionary setObject:[NSNumber numberWithBool:initWithMultiBoardEnabled] forKey:@"initWithMultiBoardEnabled"];
    [objDictionary setObject:[NSNumber numberWithBool:initWithTrig2InhibitEnabled] forKey:@"initWithTrig2InhibitEnabled"];
    [objDictionary setObject:[NSNumber numberWithBool:useSoftwareGtId] forKey:@"useSoftwareGtId"];
    [objDictionary setObject:[NSNumber numberWithBool:useMSAM] forKey:@"useMSAM"];
    [objDictionary setObject:[NSNumber numberWithBool:useNoHardware] forKey:@"useNoHardware"];
    
    return objDictionary;
}


#pragma mark ¥¥¥Board ID Decoders
-(NSString*) boardIdString
{
    unsigned short aBoardId = [self readBoardID];
    unsigned short id 		= [self decodeBoardId:aBoardId];
    unsigned short type 	= [self decodeBoardType:aBoardId];
    unsigned short rev 		=  [self decodeBoardRev:aBoardId];
    NSString* name 			= [NSString stringWithString:[self decodeBoardName:aBoardId]];
    
    return [NSString stringWithFormat:@"id:%d type:%d rev:%d name:%@",id,type,rev,name];
}


-(unsigned short) decodeBoardId:(unsigned short) aBoardIDWord
{
    return aBoardIDWord & 0x00FF;
}

-(unsigned short) decodeBoardType:(unsigned short) aBoardIDWord
{
    return (aBoardIDWord & 0x0700) >> 8;
}

-(unsigned short) decodeBoardRev:(unsigned short) aBoardIDWord
{
    return (aBoardIDWord & 0xF800) >> 11;	// updated to post Jan 02 definitions
}

-(NSString*) decodeBoardName:(unsigned short) aBoardIDWord
{
    switch( [self decodeBoardType:aBoardIDWord] ) {
        case 0: 	return @"Test";
        case 1: 	return @"EMIT";
        case 2: 	return @"NCD";
        case 3: 	return @"Time Tag";
        default: 	return @"Unknown";
    }
}

- (unsigned long) clockDataId { return clockDataId; }
- (void) setClockDataId: (unsigned long) aClockDataId
{
    clockDataId = aClockDataId;
}


- (unsigned long) gtidDataId { return gtidDataId; }
- (void) setGtidDataId: (unsigned long) aGtidDataId
{
    gtidDataId = aGtidDataId;
}

- (void) setDataIds:(id)assigner
{
    gtidDataId       = [assigner assignDataIds:kShortForm]; //short form preferred
    clockDataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setGtidDataId:[anotherObj gtidDataId]];
    [self setClockDataId:[anotherObj clockDataId]];
}


- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORTriggerDecoderFor100MHzClockRecord",    @"decoder",
								 [NSNumber numberWithLong:clockDataId],      @"dataId",
								 [NSNumber numberWithBool:NO],               @"variable",
								 [NSNumber numberWithLong:3],                @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"100MHz Clock Record"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORTriggerDecoderForGTIDRecord",                   @"decoder",
				   [NSNumber numberWithLong:gtidDataId],               @"dataId",
				   [NSNumber numberWithBool:NO],                       @"variable",
				   [NSNumber numberWithLong:IsShortForm(gtidDataId)?1:2],@"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"GTID Record"];
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	NSMutableArray* eventGroup1 = [NSMutableArray array];
	if([trigger1Group count]){
		aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"GTID",								@"name",
					   [NSNumber numberWithLong:gtidDataId],   @"dataId",
					   IsShortForm(gtidDataId)?[NSNumber numberWithLong:0]:[NSNumber numberWithLong:1], @"secondaryIdWordIndex",
					   [NSNumber numberWithLong:1],		@"value",
					   [NSNumber numberWithLong:0x3L<<24], @"mask",
					   [NSNumber numberWithLong:24],		@"shift",
					   nil];
		[eventGroup1 addObject:aDictionary];
		
		if([self shipEvt1Clk]){
			aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
						   @"100MHz Clock Record",					@"name",
						   [NSNumber numberWithLong:clockDataId],  @"dataId",
						   [NSNumber numberWithLong:1],			@"secondaryIdWordIndex",
						   [NSNumber numberWithLong:1],		@"value",
						   [NSNumber numberWithLong:0x3L<<24], @"mask",
						   [NSNumber numberWithLong:24],		@"shift",
						   nil];
			[eventGroup1 addObject:aDictionary];
		}
		
		NSMutableDictionary* aDictionary = [NSMutableDictionary dictionary];
		[trigger1Group appendEventDictionary:aDictionary topLevel:topLevel];
		if([aDictionary count])[eventGroup1 addObject:aDictionary];
		[anEventDictionary setObject:eventGroup1 forKey:@"ORTrigger Trigger1"];
	}
	
	NSMutableArray* eventGroup2 = [NSMutableArray array];
	if([trigger2Group count]){
		aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"GTID",								@"name",
					   [NSNumber numberWithLong:gtidDataId],    @"dataId",
					   IsShortForm(gtidDataId)?[NSNumber numberWithLong:0]:[NSNumber numberWithLong:1], @"secondaryIdWordIndex",
					   [NSNumber numberWithLong:2],		@"value",
					   [NSNumber numberWithLong:0x3L<<24], @"mask",
					   [NSNumber numberWithLong:24],		@"shift",
					   nil];
		[eventGroup2 addObject:aDictionary];
		
		if([self shipEvt2Clk]){
			aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
						   @"100MHz Clock Record",					@"name",
						   [NSNumber numberWithLong:clockDataId],   @"dataId",
						   [NSNumber numberWithLong:1],			@"secondaryIdWordIndex",
						   [NSNumber numberWithLong:2],		@"value",
						   [NSNumber numberWithLong:0x3L<<24], @"mask",
						   [NSNumber numberWithLong:24],		@"shift",
						   nil];
			[eventGroup2 addObject:aDictionary];
		}
		
		NSMutableDictionary* aDictionary = [NSMutableDictionary dictionary];
		[trigger2Group appendEventDictionary:aDictionary topLevel:topLevel];
		if([aDictionary count])[eventGroup2 addObject:aDictionary];
		[anEventDictionary setObject:eventGroup2 forKey:@"ORTrigger Trigger2"];
	}	
}


//----------------Clock Word------------------------------------
// two long words
// word #1:
// 0000 0000 0000 0000 0000 0000 0000 0000   32 bit unsigned long
// ^^^^ ^------------------------------------ kTrigTimeRecordType             [bits 26-31]
//       ^----------------------------------- spare
//        ^^--------------------------------- latch register ID (0-4)         [bits 24-25]
//           ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^--- 24 bits holding upper clock reg [bits 0-23]
//
// word #2:
// 0000 0000 0000 0000 0000 0000 0000 0000   32 bits holding middle and lower clock reg
//--------------------------------------------------------------

//-------------------GTID record--------------------------------
// 0000 0000 0000 0000 0000 0000 0000 0000   32 bit unsigned long
// ^^^^ ^------------------------------------ kGTIDRecordType                 [bits 27-31]
//       ^----------------------------------- sync clear err                  [bits 26]
//        ^^--------------------------------- spare                           [bits 24-25]
//           ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^--- 24 bits for gtid                [bits 0-23]
//--------------------------------------------------------------

#pragma mark ¥¥¥DataTaker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    
    [[self undoManager] disableUndoRegistration];
    [self setSoftwareGtId:0];
    [[self undoManager] enableUndoRegistration];
    
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORTriggerModel"];
    
    if(!useNoHardware){
        [self reset];
        [self resetGtEvent1];
        [self resetGtEvent2];
    }
    
    dataTakers1 = [[trigger1Group allObjects] retain];	//cache of data takers.
    dataTakers2 = [[trigger2Group allObjects] retain];			//cache of data takers.
    
    NSEnumerator* e = [dataTakers1 objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
    
    e = [dataTakers2 objectEnumerator];
    while(obj = [e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
    
    if(!useNoHardware){
        //[self resetClock];
        //[self enableClock:YES];
        [self enableMultiBoardOutput:[self initWithMultiBoardEnabled]];
        [self enableBusyOutput:[self initWithTrig2InhibitEnabled]];
    }
    [self clearExceptionCount];
    [self setGtErrorCount:0];
    
    [self checkSoftwareGtIdAlarm];
    [self checkUseNoHardwareAlarm];
    
    timer = [[ORTimer alloc] init];
    [timer start];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	struct timeval timeValue;
	struct timezone timeZone;
	unsigned long long doeTime  ;
    
    unsigned long gtid = 0;
    unsigned long data[2];
    unsigned long len;
    NSString* errorLocation = @"";
    
    unsigned short statusReg;
    BOOL isMSAMEvent = NO;
    @try {
        // read the status register to check for an event and save the value since
        // we will reset the event when the gtid register is read.
        // Note that we force events if in the nohardware mode.
        errorLocation = @"Reading Status Reg";
        if(!useNoHardware)  {
            statusReg = [self readStatus];
            [timer reset];
        }
        else                statusReg = kValidEvent1GtMask | kValidEvent2GtMask | kEventMask;
        
        //Note for debugging. EVERY variable in the following block should have a '1' in it if is referring to
        //an event, gtid, or placeholder.
        if((statusReg & kEvent1Mask)){
            
            BOOL removePlaceHolders = NO;
            
            if(!(statusReg & kValidEvent1GtMask)){
                long deltaTime = [timer microseconds]*1000;
                if(deltaTime < 1500){
                    //there should have been a gtid bit set.
                    //try to read it again after a delay of up to 1.5 microseconds
                    struct timespec ts;
                    ts.tv_sec = 0;
                    ts.tv_nsec = 1500-deltaTime;
                    nanosleep(&ts, NULL); //sleep for 1 micro sec.
                }
                statusReg = [self readStatus];
                //if it's still not set, an error will be flagged below when
                //there is no gtid data.
            }
            
            if(statusReg & kValidEvent1GtMask){
                //read the gtid. This will return a software generated gtid if in the useSoftwareGtId mode.
                //Will reset the event 1 bit if the gtid hw is actually read.
                errorLocation = @"Reading Event1 GtID";
                gtid = [self getGtId1];
                if(useSoftwareGtId || useNoHardware){
                    //using the software generated gtid, so this is a special case to keep from flooding the
                    //data stream with garbage gtid data. put a placeholder into the data object. We will
                    //replace it with a real gtid data word below if data is actually generated.
                    eventPlaceHolder1 = [aDataPacket reserveSpaceInFrameBuffer:IsShortForm(gtidDataId)?1:2];
                    if(shipEvt1Clk)timePlaceHolder1 = [aDataPacket reserveSpaceInFrameBuffer:3];
                    removePlaceHolders = YES;
                    //in software gtid mode, so must reset the event 1 bit before reading the children.
                }
                else {
                    //pack the gtid
                    if(IsShortForm(gtidDataId)){
                        len = 1;
                        data[0] = gtidDataId | (0x01<<24) | (0x00ffffff&gtid);
                    }
                    else {
                        len = 2;
                        data[0] = gtidDataId | len;
                        data[1] = (0x01<<24) | (0x00ffffff&gtid);
                    }
                    //put the gtid into the data object
                    [aDataPacket addLongsToFrameBuffer:data length:len];
					
                    if(shipEvt1Clk){
						gettimeofday(&timeValue,&timeZone);
						doeTime = timeValue.tv_sec;
						doeTime = doeTime * 10000000 + timeValue.tv_usec*10;
						
						unsigned long data[3];
						data[0] = clockDataId | 3;
						data[1] = (0x1<<24) | (unsigned long)(doeTime>>32);
						data[2] = (unsigned long)(doeTime&0x00000000ffffffff);
						[aDataPacket addLongsToFrameBuffer:data length:len];
                    }
                }
            }
            
            if(!useNoHardware){
                errorLocation = @"Resetting Event1";
                [self resetGtEvent1];
            }
            
            //keep track if data is taken if in the useSoftware GtId mode.
            int lastDataCount = 0;
            if(useSoftwareGtId || useNoHardware){
                lastDataCount = [aDataPacket dataCount];
            }
            
            if(useMSAM && !useNoHardware){
                //MSAM is a special bit that is set if a trigger 1 has occurred within 15 microseconds after a trigger2
                errorLocation = @"Reading Trigger M_SAM";
                if((statusReg & kValidEvent1GtMask) && !(statusReg & kMSAM_Mask)){
                    long deltaTime = [timer microseconds];
                    if(deltaTime < 15){
                        struct timespec ts;
                        ts.tv_sec = 0;
                        ts.tv_nsec = 15000 - (deltaTime*1000);
                        nanosleep(&ts, NULL);
                    }
                    statusReg = [self readStatus];
                }
                if(statusReg & kMSAM_Mask){
                    isMSAMEvent = YES;
                }
                [self clearMSAM];
            }	
            
            //OK finally go out and read all the data takers scheduled to be read out with a trigger 1 event.
            errorLocation = @"Reading Event1 Children";
            [self _readOutChildren:dataTakers1 dataPacket:aDataPacket withGTID:gtid isMSAMEvent:isMSAMEvent];
            
            if(useSoftwareGtId || useNoHardware){
                //all of this is done here only so that we can control when the software gtid is incremented.
                if([aDataPacket dataCount]>lastDataCount){
                    [self incrementSoftwareGtId];
                    
                    if(IsShortForm(gtidDataId)){
                        len = 1;
                        data[0] = gtidDataId | (0x01<<24) | (0x00ffffff&gtid);
                    }
                    else {
                        len = 2;
                        data[0] = gtidDataId | len;
                        data[1] = (0x01<<24) | (0x00ffffff&gtid);
					}
					[aDataPacket replaceReservedDataInFrameBufferAtIndex:eventPlaceHolder1 withLongs:data length:len];
                    if(shipEvt1Clk){
						gettimeofday(&timeValue,&timeZone);
						doeTime = timeValue.tv_sec;
						doeTime = doeTime * 10000000 + timeValue.tv_usec*10;
						
						unsigned long data[3];
						data[0] = clockDataId | 3;
						data[1] = (0x1<<24) | (unsigned long)(doeTime>>32);
						data[2] = (unsigned long)(doeTime&0x00000000ffffffff);
						[aDataPacket replaceReservedDataInFrameBufferAtIndex:timePlaceHolder1 withLongs:data length:3];
                    }
                    removePlaceHolders = NO;
                }
            }
            
            if(removePlaceHolders){
                //no data so remove the place holder.
                [aDataPacket removeReservedLongsFromFrameBuffer:NSMakeRange(eventPlaceHolder1,IsShortForm(gtidDataId)?1:2)];
                if(shipEvt1Clk)[aDataPacket removeReservedLongsFromFrameBuffer:NSMakeRange(timePlaceHolder1,3)];
            }
            
            
        }
        
        
        //Note for debugging. EVERY variable in the following block should have a '2' in it if is referring to
        //an event, gtid, or placeholder.
        if(statusReg & kEvent2Mask){
            //event mask 2 is special and requires that the children's hw be readout BEFORE the GTID
            //word is read. Reading the GTID clears the event 2 bit in the status word and can cause
            //a lockout of the hw.
            
            //put a placeholder into the data object because we must ship the gtid before the data
            //We will replace the placeholder with a real gtid data word below.
			eventPlaceHolder2 = [aDataPacket reserveSpaceInFrameBuffer:IsShortForm(gtidDataId)?1:2];
            
            //ship the clock if the ship bit is set.
            if(shipEvt2Clk){
				timePlaceHolder2 = [aDataPacket reserveSpaceInFrameBuffer:3];
            }
            
            
            //go out and read all the data takers scheduled to be read out with a trigger 2 event.
            //also we keep track if any data was actually taken
            int lastDataCount = [aDataPacket frameIndex];
            errorLocation = @"Reading Event2 Children";
            [self _readOutChildren:dataTakers2 dataPacket:aDataPacket withGTID:0  isMSAMEvent:isMSAMEvent]; //don't know the gtid so pass 0
            BOOL dataWasTaken = [aDataPacket frameIndex]>lastDataCount;
            
            if(!(statusReg & kValidEvent2GtMask)){
                long deltaTime = [timer microseconds]*1000;
                if(deltaTime < 1500){
                    //there should have been a gtid bit set.
                    //try to read it again after a delay of up to 1.5 microseconds
                    struct timespec ts;
                    ts.tv_sec = 0;
                    ts.tv_nsec = 1500-deltaTime;
                    nanosleep(&ts, NULL); //sleep for 1 micro sec.
                }
                statusReg = [self readStatus];
                //if it's still not set, an error will be flagged below when
                //there is no gtid data.
            }
            if(statusReg & kValidEvent2GtMask){
                errorLocation = @"Reading Event2 GtId";
                gtid = [self getGtId2];
                if(dataWasTaken){
                    if(useSoftwareGtId){
                        [self incrementSoftwareGtId];
                        if(!useNoHardware){
                            //we are in the software gtid mode but no using hw so
                            //we have to clear the event bit.
                            errorLocation = @"Resetting Event2";
                            [self resetGtEvent2];
                        }
                    }
                    //OK there was some data some pack the gtid.
                    
                    if(IsShortForm(gtidDataId)){
                        len = 1;
                        data[0] = gtidDataId | (0x01<<25) | (0x00ffffff&gtid);
                    }
                    else {
                        len = 2;
                        data[0] = gtidDataId | len;
                        data[1] = (0x01<<25) | (0x00ffffff&gtid);
					}
					[aDataPacket replaceReservedDataInFrameBufferAtIndex:eventPlaceHolder2 withLongs:data length:len];
					if(shipEvt2Clk){
						gettimeofday(&timeValue,&timeZone);
						doeTime = timeValue.tv_sec;
						doeTime = doeTime * 10000000 + timeValue.tv_usec*10;
						
						unsigned long data[3];
						data[0] = clockDataId | 3;
						data[1] = (0x1<<25) | (unsigned long)(doeTime>>32);
						data[2] = (unsigned long)(doeTime&0x00000000ffffffff);
						[aDataPacket replaceReservedDataInFrameBufferAtIndex:timePlaceHolder2 withLongs:data length:3];
					}
				}
				else {
					//no data so remove the place holder.
					[aDataPacket removeReservedLongsFromFrameBuffer:NSMakeRange(eventPlaceHolder2,IsShortForm(gtidDataId)?1:2)];
					if(shipEvt2Clk) [aDataPacket removeReservedLongsFromFrameBuffer:NSMakeRange(timePlaceHolder2,3)];
				}
            }
            else {
                //no data so remove the place holder.
				[aDataPacket removeReservedLongsFromFrameBuffer:NSMakeRange(eventPlaceHolder2,IsShortForm(gtidDataId)?1:2)];
				if(shipEvt2Clk) [aDataPacket removeReservedLongsFromFrameBuffer:NSMakeRange(timePlaceHolder2,3)];
            }
        }
        
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"Trigger Card Error",errorLocation,nil);
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    NSEnumerator* e = [dataTakers1 objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStopped:aDataPacket userInfo:userInfo];
    }
    
    e = [dataTakers2 objectEnumerator];
    while(obj = [e nextObject]){
        [obj runTaskStopped:aDataPacket userInfo:userInfo];
    }
    
    [dataTakers1 release];
    [dataTakers2 release];
    
    [timer release];
    timer = nil;
}

- (void) checkSoftwareGtIdAlarm
{
    if(!useSoftwareGtId){
        [softwareGtIdAlarm clearAlarm];
    }
    else {
        if(!softwareGtIdAlarm){
            softwareGtIdAlarm = [[ORAlarm alloc] initWithName:@"Using Software Generated GTID" severity:kSetupAlarm];
            [softwareGtIdAlarm setSticky:YES];
            [softwareGtIdAlarm setHelpString:@"This is just a notification that the trigger card is set to use a software generated GTID."];
        }
        [softwareGtIdAlarm setAcknowledged:NO];
        [softwareGtIdAlarm postAlarm];
    }
}

- (void) checkUseNoHardwareAlarm
{
    if(!useNoHardware){
        [useNoHardwareAlarm clearAlarm];
    }
    else {
        if(!useNoHardwareAlarm){
            useNoHardwareAlarm = [[ORAlarm alloc] initWithName:@"Trigger Card Using NO Hardware" severity:kSetupAlarm];
            [useNoHardwareAlarm setHelpString:@"This is just a notification that the trigger card is set to NOT use hardware."];
            [useNoHardwareAlarm setSticky:YES];
        }
        [useNoHardwareAlarm setAcknowledged:NO];
        [useNoHardwareAlarm postAlarm];
    }
}


- (int) load_eCPU_HW_Config_Structure:(VME_crate_config*)configStruct index:(int)index
{
    configStruct->total_cards++;
    configStruct->card_info[index].hw_type_id = 'LCLC'; //should be unique
    configStruct->card_info[index].hw_mask[0] = gtidDataId; //better be unique
    configStruct->card_info[index].add_mod 	 = [self addressModifier];
    configStruct->card_info[index].base_add  = [self baseAddress];
    
    configStruct->card_info[index].num_Trigger_Indexes = 2;
    
    int nextIndex = index+1;
    
    NSEnumerator* e = [dataTakers1 objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        if([obj respondsToSelector:@selector(load_eCPU_HW_Config_Structure:index:)]){
            int savedIndex = nextIndex;
            nextIndex = [obj load_eCPU_HW_Config_Structure:configStruct index:nextIndex];
            if(obj == [dataTakers1 lastObject]){
                configStruct->card_info[savedIndex].next_Card_Index = -1; //make the last object a leaf node
            }
        }
    }
    
    e = [dataTakers2 objectEnumerator];
    while(obj = [e nextObject]){
        if([obj respondsToSelector:@selector(load_eCPU_HW_Config_Structure:index:)]){
            int savedIndex = nextIndex;
            nextIndex = [obj load_eCPU_HW_Config_Structure:configStruct index:nextIndex];
            if(obj == [dataTakers2 lastObject]){
                configStruct->card_info[savedIndex].next_Card_Index = -1; //make the last object a leaf node
            }
        }
    }
    
    configStruct->card_info[index].next_Card_Index 	 = nextIndex;
    
    return nextIndex;
}


- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [trigger1Group saveUsingFile:aFile];
    [trigger2Group saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setTrigger1Group:[[[ORReadOutList alloc] initWithIdentifier:@"Trigger 1"]autorelease]];
    [self setTrigger2Group:[[[ORReadOutList alloc] initWithIdentifier:@"Trigger 2"]autorelease]];
    [trigger1Group loadUsingFile:aFile];
    [trigger2Group loadUsingFile:aFile];
}

#pragma mark ¥¥¥GTID Generator
- (unsigned long)  requestGTID
{
    return [self getGtId1]; //this is not quite right, but included for compatiblitily with new trigger cards.
}


#pragma mark ¥¥¥Private Methods
- (void) _readOutChildren:(NSArray*)children dataPacket:(ORDataPacket*)aDataPacket withGTID:(unsigned long)gtid isMSAMEvent:(BOOL)isMSAMEvent
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithLong:gtid] forKey:@"GTID"];
    if(useMSAM && !useNoHardware){
        [params setObject:[NSNumber numberWithBool:isMSAMEvent] forKey:@"MSAMEvent"];
    }
    NSEnumerator* e = [children objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj takeData:aDataPacket userInfo:params];
    }
}


@end


