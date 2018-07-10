/*
 *  ORTrigger32Model.cpp
 *  Orca
 *
 *  Created by Mark Howe on Tue May 4, 2004.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */

#pragma mark ¥¥¥Imported Files
#import "ORTrigger32Model.h"
#import "StatusLog.h"
#import "ORParamItem.h"
#import "ORDataDescriptionItem.h"
#import "ORHeaderSection.h"
#import "ORVmeCrateModel.h"
#import "ORReadOutList.h"
#import "ORAlarm.h"
#import "ORTimer.h"
#import "ORGlobal.h"
#import "ORDataTypeAssigner.h"
#import <sys/time.h>

#pragma mark ¥¥¥Definitions
#define kDefaultAddressModifier		    0x29
#define kDefaultBaseAddress		    0x0007000

#pragma mark ¥¥¥Notification Strings
NSString* ORTrigger32TestValueChangedNotification       = @"ORTrigger32TestValueChangedNotification";
NSString* ORTrigger32GtIdValueChangedNotification 	= @"ORTrigger32GtIdValueChangedNotification";
NSString* ORTrigger32LowerTimeValueChangedNotification	= @"ORTrigger32LowerTimeValueChangedNotification";
NSString* ORTrigger32UpperTimeValueChangedNotification	= @"ORTrigger32UpperTimeValueChangedNotification";

NSString* ORTrigger32ShipEvt1ClkChangedNotification	= @"ORTrigger32ShipEvt1ClkChangedNotification";
NSString* ORTrigger32ShipEvt2ClkChangedNotification	= @"ORTrigger32ShipEvt2ClkChangedNotification";
NSString* ORTrigger32GtErrorCountChangedNotification    = @"ORTrigger32GtErrorCountChangedNotification";
NSString* ORTrigger32Trigger2EventEnabledNotification   = @"ORTrigger32Trigger2EventEnabledNotification";
NSString* ORTrigger32Trigger2BusyEnabledNotification    = @"ORTrigger32Trigger2BusyEnabledNotification";
NSString* ORTrigger32UseSoftwareGtIdChangedNotification = @"ORTrigger32UseSoftwareGtIdChangedNotification";
NSString* ORTrigger32UseNoHardwareChangedNotification   = @"ORTrigger32UseNoHardwareChangedNotification";
NSString* ORTrigger32SoftwareGtIdChangedNotification    = @"ORTrigger32SoftwareGtIdChangedNotification";
NSString* ORTrigger321NameChangedNotification		= @"ORTrigger321NameChangedNotification";
NSString* ORTrigger322NameChangedNotification		= @"ORTrigger322NameChangedNotification";
NSString* ORTrigger32MSAMChangedNotification		= @"ORTrigger32MSAMChangedNotification";
NSString* ORTrigger32SettingsLock			= @"ORTrigger32SettingsLock";
NSString* ORTrigger32SpecialLock			= @"ORTrigger32SpecialLock";
NSString* ORTrigger32Trigger1GTXorChangedNotification   = @"ORTrigger32Trigger1GTXorChangedNotification";
NSString* ORTrigger32Trigger2GTXorChangedNotification   = @"ORTrigger32Trigger2GTXorChangedNotification";
NSString* ORTrigger32ClockEnabledChangedNotification    = @"ORTrigger32ClockEnabledChangedNotification";
NSString* ORTrigger32MSamPrescaleChangedNotification		= @"ORTrigger32MSamPrescaleChangedNotification";
NSString* ORTrigger32LiveTimeEnabledChangedNotification = @"ORTrigger32LiveTimeEnabledChangedNotification";
NSString* ORTrigger32LiveTimeCalcRunningChangedNotification     = @"ORTrigger32LiveTimeCalcRunningChangedNotification";

#pragma mark ¥¥¥Private Implementation
@interface ORTrigger32Model (private)
- (void) _readOutChildren:(NSArray*)children dataPacket:(ORDataPacket*)aDataPacket  useParams:(BOOL)useParams withGTID:(unsigned long)gtid isMSAMEvent:(BOOL)isMSAMEvent;
- (NSData*) getTimeData:(ORDataPacket*)aDataPacket  statusReg:(unsigned short)statusReg eventMask:(unsigned long)aEventMask trigger:(short)trigger;
- (void) _calculateLiveTime;
@end

@implementation ORTrigger32Model

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
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(shipLiveTimeMidRun) object:nil];

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
    [self setImage:[NSImage imageNamed:@"Trigger32Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORTrigger32Controller"];
}

#pragma mark ¥¥¥Accessors
- (BOOL) liveTimeCalcRunning
{
    return liveTimeCalcRunning;
}

- (void) setLiveTimeCalcRunning: (BOOL) flag
{
    liveTimeCalcRunning = flag;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORTrigger32LiveTimeCalcRunningChangedNotification
                      object:self
                    userInfo: [NSDictionary dictionaryWithObject: self
                                                          forKey:ORNotificationSender]];
}

- (unsigned long) clockDataId { return clockDataId; }
- (void) setClockDataId: (unsigned long) aClockDataId
{
    clockDataId = aClockDataId;
}


- (unsigned long) gtid1DataId { return gtid1DataId; }
- (void) setGtid1DataId: (unsigned long) aGtidDataId
{
    gtid1DataId = aGtidDataId;
}

- (unsigned long) gtid2DataId { return gtid2DataId; }
- (void) setGtid2DataId: (unsigned long) aGtidDataId
{
    gtid2DataId = aGtidDataId;
}

- (unsigned long) liveTimeDataId { return liveTimeDataId; }
- (void) setLiveTimeDataId: (unsigned long) aLiveTimeDataId
{
    liveTimeDataId = aLiveTimeDataId;
}

- (void) setDataIds:(id)assigner
{
    gtid1DataId       = [assigner assignDataIds:kShortForm]; //short form preferred
    gtid2DataId       = [assigner assignDataIds:kShortForm]; //short form preferred
    clockDataId       = [assigner assignDataIds:kLongForm];
    liveTimeDataId    = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setGtid1DataId:[anotherObj gtid1DataId]];
    [self setGtid2DataId:[anotherObj gtid2DataId]];
    [self setClockDataId:[anotherObj clockDataId]];
    [self setLiveTimeDataId:[anotherObj liveTimeDataId]];
}

- (int) mSamPrescale
{
    return mSamPrescale;
}

- (void) setMSamPrescale:(int)aValue
{
    
    [[[self undoManager] prepareWithInvocationTarget:self] setMSamPrescale:mSamPrescale];
    
    mSamPrescale = aValue;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORTrigger32MSamPrescaleChangedNotification
                      object:self
                    userInfo: [NSDictionary dictionaryWithObject: self
                                                          forKey:ORNotificationSender]];
    
}

- (unsigned long)testRegisterValue
{
    return testRegisterValue;
}

- (void)setTestRegisterValue:(unsigned long)aTestRegisterValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestRegisterValue:aTestRegisterValue];
    testRegisterValue = aTestRegisterValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32TestValueChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (unsigned long) gtIdValue
{
    return gtIdValue;
}

- (void) setGtIdValue:(unsigned long)newGtIdValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGtIdValue:gtIdValue];
    gtIdValue=newGtIdValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32GtIdValueChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (unsigned long)lowerTimeValue
{
    return lowerTimeValue;
}

- (void)setLowerTimeValue:(unsigned long)aLowerTimeValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowerTimeValue:lowerTimeValue];
    lowerTimeValue = aLowerTimeValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32LowerTimeValueChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (unsigned long)upperTimeValue
{
    return upperTimeValue;
}

- (void)setUpperTimeValue:(unsigned long)anUpperTimeValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUpperTimeValue:upperTimeValue];
    upperTimeValue = anUpperTimeValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32UpperTimeValueChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32ShipEvt1ClkChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (void) setShipEvt2Clk:(BOOL)state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipEvt2Clk:shipEvt2Clk];
    shipEvt2Clk = state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32ShipEvt2ClkChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (BOOL) trigger2EventInputEnable
{
    return trigger2EventInputEnable;
}

- (void) setTrigger2EventInputEnable:(BOOL)state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger2EventInputEnable:trigger2EventInputEnable];
    trigger2EventInputEnable=state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32Trigger2EventEnabledNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (BOOL) trigger2BusyEnabled
{
    return trigger2BusyEnabled;
}
- (void) setTrigger2BusyEnabled:(BOOL)state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger2BusyEnabled:trigger2BusyEnabled];
    trigger2BusyEnabled=state;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32Trigger2BusyEnabledNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (unsigned long) gtErrorCount
{
    return gtErrorCount;
}
- (void) setGtErrorCount:(unsigned long)count
{
    gtErrorCount = count;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32GtErrorCountChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
    
}

- (BOOL) useSoftwareGtId
{
    return useSoftwareGtId;
}
- (void) setUseSoftwareGtId:(BOOL)newUseSoftwareGtId
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseSoftwareGtId:useSoftwareGtId];
    useSoftwareGtId=newUseSoftwareGtId;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32UseSoftwareGtIdChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
    
    [self checkSoftwareGtIdAlarm];
    [self checkUseNoHardwareAlarm];
    
}


- (BOOL)trigger1GtXor
{
    return trigger1GtXor;
}

- (void)setTrigger1GtXor:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger1GtXor:trigger1GtXor];
    trigger1GtXor = flag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32Trigger1GTXorChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (BOOL)trigger2GtXor
{
    return trigger2GtXor;
}

- (void)setTrigger2GtXor:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger2GtXor:trigger2GtXor];
    trigger2GtXor = flag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32Trigger2GTXorChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (BOOL) useNoHardware
{
    return useNoHardware;
}

- (void) setUseNoHardware:(BOOL)newUseNoHardware
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseNoHardware:useNoHardware];
    useNoHardware=newUseNoHardware;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32UseNoHardwareChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
    
    [self checkUseNoHardwareAlarm];
    
}


- (unsigned long) softwareGtId
{
    return softwareGtId;
}
- (void) setSoftwareGtId:(unsigned long)newSoftwareGtId
{
    softwareGtId=newSoftwareGtId;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32SoftwareGtIdChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (void) incrementSoftwareGtId
{
    if(++softwareGtId > 0x00ffffff)softwareGtId = 0;
    [self setSoftwareGtId: softwareGtId];
}

- (BOOL) liveTimeEnabled
{
    return liveTimeEnabled;
}
- (void) setLiveTimeEnabled:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLiveTimeEnabled:liveTimeEnabled];
    liveTimeEnabled = flag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32LiveTimeEnabledChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (BOOL)clockEnabled
{
    return clockEnabled;
}

- (void)setClockEnabled:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockEnabled:clockEnabled];
    clockEnabled = flag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32ClockEnabledChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (NSString *) trigger1Name
{
    return trigger1Name;
}

- (void) setTrigger1Name: (NSString *) aTrigger1Name
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger1Name:trigger1Name];
    [trigger1Name autorelease];
    trigger1Name = [aTrigger1Name copy];
    
    [trigger1Group setIdentifier:trigger1Name];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger321NameChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
    
    
}

- (void) standAloneMode:(BOOL)state
{
    if(state){
        [self setShipEvt1Clk:YES];
        [self setShipEvt2Clk:YES];
        [self setClockEnabled:YES];
        [self setUseSoftwareGtId:YES];
    }
    else{
        [self setShipEvt1Clk:NO];
        [self setShipEvt2Clk:NO];
        [self setClockEnabled:NO];
        [self setUseSoftwareGtId:NO];
    }
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger322NameChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

- (BOOL)useMSAM
{
    return useMSAM;
}

- (void)setUseMSAM:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseMSAM:useMSAM];
    useMSAM = flag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTrigger32MSAMChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject: self forKey:ORNotificationSender]];
}

#pragma mark ***HW Access Read commands
- (unsigned long) 	readBoardID;
{
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:baseAddress+kReadBoardID
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    return val;
}

- (unsigned long) 	readStatus
{
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:baseAddress+kReadStatusReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    
    //double t0 = [NSDate timeIntervalSinceReferenceDate];
    //while([NSDate timeIntervalSinceReferenceDate]-t0 < 5);
    return val;
}

- (unsigned long) readTrigger2GTID
{
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:baseAddress+kReadTrigger2GTID
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    return val;
}

- (unsigned long)  readTrigger1GTID
{
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:baseAddress+kReadTrigger1GTID
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    return val;
}

- (unsigned long)  readLowerTrigger2Time
{
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:baseAddress+kReadLowerTrigger2TimeReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    return val;
}

- (unsigned long)  readUpperTrigger2Time
{
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:baseAddress+kReadUpperTrigger2TimeReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    return val;
}


- (unsigned long)  readLowerTrigger1Time
{
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:baseAddress+kReadLowerTrigger1TimeReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    return val;
}

- (unsigned long)  readUpperTrigger1Time
{
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:baseAddress+kReadUpperTrigger1TimeReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    return val;
}

- (unsigned long)  readTestRegister
{
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:baseAddress+kReadTestReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    return val;
}

- (unsigned long)  readSoftGTIDRegister
{
    if(useNoHardware || useSoftwareGtId){
		[self incrementSoftwareGtId];
		return softwareGtId;
	}
	
    unsigned long val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:baseAddress+kReadSoftGTIDReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    return val;
}

#pragma mark ***HW Access Write commands

- (void) initBoard
{
    [self initBoardPart1];
    [self initBoardPart2];
}

- (void) initBoardPart1
{
    NSString* errorLocation;
    NS_DURING
        errorLocation = @"reset";
        [self reset];
        
        errorLocation = @"setting GT Or States";
        unsigned short aMask = 0;
        if(trigger2GtXor)aMask |= 1;
        if(trigger1GtXor)aMask |= 2;
        [self enableGTOrEnable:aMask];
        
        errorLocation = @"setting Clock enable";
        [self enableTimeClockCounter:clockEnabled];
        
        errorLocation = @"setting LiveTime enable";
        [self enableLiveTime:liveTimeEnabled];
        
        
        errorLocation = [NSString stringWithFormat:@"setting %@ GT",trigger1Name];
        [self resetTrigger1GTStatusBit];
        
        errorLocation = [NSString stringWithFormat:@"setting %@ GT",trigger2Name];
        [self resetTrigger2GTStatusBit];
        
        
    NS_HANDLER
        NSLog(@"Trigger card init sequence FAILED at step: <%@>.\n",errorLocation);
        [localException raise];
    NS_ENDHANDLER
}

- (void) initBoardPart2
{
    NSString* errorLocation;
    NS_DURING
        errorLocation = [NSString stringWithFormat:@"setting %@ event input enable",trigger2Name];
        [self enableTrigger2EventInput:trigger2EventInputEnable];
        
        errorLocation = [NSString stringWithFormat:@"setting %@ BUSY output enable",trigger2Name];
        [self enableBusyOutput:trigger2BusyEnabled];
        
    NS_HANDLER
        NSLog(@"Trigger card init sequence FAILED at step: <%@>.\n",errorLocation);
        [localException raise];
    NS_ENDHANDLER
}


- (void) reset
{
    unsigned short val = 0;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kRegisterReset
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) enableTrigger2EventInput:(BOOL) enable
{
    unsigned short val = enable;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kTrigger2EventInputEnable
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) enableBusyOutput:(BOOL)enable
{
    unsigned short val = enable;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kTrigger2BusyOutputEnable
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) enableTimeClockCounter:(BOOL)enable
{
    unsigned short val = enable;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kTimeClockCounterEnable
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) resetTimeClockCounter
{
    unsigned short val = 0;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kTimeClockCounterEnable
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}


- (void) enableLiveTime:(BOOL)enable
{
    unsigned short val = enable;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kLiveTimeEnable
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}
- (void) resetLiveTime
{
    unsigned short val = 0;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kLiveTimeReset
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) latchLiveTime
{
    unsigned short val = 0;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kLatchLiveTime
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) readLiveTimeCounters
{
    [self latchLiveTime];
    
    unsigned long lower;
    unsigned long upper;
    
    [[self adapter] readLongBlock:&upper
                        atAddress:baseAddress+kUpperLiveTimeReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    
    [[self adapter] readLongBlock:&lower
                        atAddress:baseAddress+kTotalLiveTimeReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    
    total_live = ((long long)upper&0x00000000000000ff)<<32 | lower;
    
    [[self adapter] readLongBlock:&lower
                        atAddress:baseAddress+kTrigger1LiveTimeReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    
    trig1_live = ((long long)upper&0x000000000000ff00)<<24 | lower;
   
    
    
    [[self adapter] readLongBlock:&lower
                        atAddress:baseAddress+kTrigger2LiveTimeReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    
    trig2_live = ((long long)upper&0x0000000000ff0000)<<16 | lower;

    [[self adapter] readLongBlock:&lower
                        atAddress:baseAddress+kScopeLiveTimeReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
    
    scope_live = ((long long)upper&0x00000000ff000000)<<8 | lower;

    
}

- (void) dumpLiveTimeCounters
{

    [self setLiveTimeCalcRunning:YES];
    [self readLiveTimeCounters];
    
    last_total_live = total_live;
    last_trig1_live = trig1_live;
    last_trig2_live = trig2_live;
    last_scope_live = scope_live;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_calculateLiveTime) object:nil];
    [self performSelector:@selector(_calculateLiveTime) withObject:nil afterDelay:5];
}


- (void) resetTrigger2GTStatusBit
{
    unsigned short val = 1;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kTrigger2GTEventReset
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) resetTrigger1GTStatusBit
{
    unsigned short val = 1;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kTrigger1GTEventReset
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) resettrigger2EventInputEnable
{
    unsigned short val = 1;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kCountErrorReset
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) resetCountError
{
    unsigned short val = 1;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kCountErrorReset
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) resetClock
{
    unsigned short val = 1;
    [[self adapter] writeWordBlock:&val
                         atAddress:baseAddress+kTimeClockCounterReset
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) testLatchTrigger2GTID
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:baseAddress+kTestLatchTrigger2GTID
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) testLatchTrigger1GTID
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:baseAddress+kTestLatchTrigger1GTID
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}


- (void) testLatchTrigger2Time
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:baseAddress+kTestLatchTrigger2Time
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) testLatchTrigger1Time
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:baseAddress+kTestLatchTrigger1Time
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) softGT
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:baseAddress+kSoftGTRIG
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
    
}

- (void) requestSoftGTID
{
    if(useNoHardware || useSoftwareGtId)  return;
	
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:baseAddress+kRequestSoftGTID
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
    
}


- (void) syncClear
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:baseAddress+kSoftSYNCLR
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) softGTSyncClear
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:baseAddress+kSoftGTRIGandSYNCLR
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
    
}

- (void) syncClear24
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:baseAddress+kSoftSYNCLR24
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) enableGTOrEnable:(unsigned short)aValue
{
    [[self adapter] writeWordBlock:&aValue
                         atAddress:baseAddress+kGTOrOutputEnable
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) clearMSAM
{
    unsigned short aVal = 0;
    [[self adapter] writeWordBlock:&aVal
                         atAddress:baseAddress+kMSamEventReset
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) loadTestRegister:(unsigned long)aValue
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress:baseAddress+kLoadTestRegister
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) loadGTID:(unsigned long)  aVal
{
    [[self adapter] writeLongBlock:&aVal
                         atAddress:baseAddress+kLoadGTIDCounter
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) loadLowerTimerCounter:(unsigned long)  aVal
{
    [[self adapter] writeLongBlock:&aVal
                         atAddress:baseAddress+kLoadLowerTimeCounter
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) loadUpperTimerCounter:(unsigned long)  aVal
{
    [[self adapter] writeLongBlock:&aVal
                         atAddress:baseAddress+kLoadUpperTimeCounter
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}


- (unsigned long) getGtId1
{
    if(useNoHardware || useSoftwareGtId)  return softwareGtId;
    else return [self readTrigger1GTID];
}

- (unsigned long) getGtId2
{
    if(useNoHardware || useSoftwareGtId)  return softwareGtId;
    else return [self readTrigger2GTID];
}

- (BOOL) anEvent:(unsigned short)  aVal
{
    return aVal & kEventMask;
}


- (BOOL) eventBit1Set:(unsigned short)  aVal
{
    return aVal & kTrigger1EventMask;
}

- (BOOL) eventBit2Set:(unsigned short)  aVal
{
    return aVal & kTrigger2EventMask;
}

- (BOOL) validEvent1GtBitSet:(unsigned short)  aVal
{
    return aVal & kValidTrigger1GTClockMask;
}
- (BOOL) validEvent2GtBitSet:(unsigned short)  aVal
{
    return aVal & kValidTrigger2GTClockMask;
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
static NSString *ORTriggerGTID			= @"ORTriggerGTID";
static NSString *ORTriggerLowerClock		= @"ORTriggerLowerClock";
static NSString *ORTriggerUpperClock		= @"ORTriggerUpperClock";
static NSString *ORTriggerGroup1                = @"ORTrigger Group 1";
static NSString *ORTriggerGroup2                = @"ORTrigger Group 2";
static NSString *ORTriggerShipEvt1Clk		= @"ORTriggerShipEvt1Clk";
static NSString *ORTriggerShipEvt2Clk		= @"ORTriggerShipEvt2Clk";
static NSString *ORTriggerTrigger2EventInputEnable = @"ORTriggerTrigger2EventInputEnable";
static NSString *ORTriggerTrigger2BusyEnabled  = @"ORTriggerTrigger2BusyEnabled";
static NSString *ORTriggerUseSoftwareGtId       = @"ORTriggerUseSoftwareGtId";
static NSString *ORTriggerNoHardware       	= @"ORTriggerNoHardware";
static NSString *ORTriggerSoftwareGtId          = @"ORTriggerSoftwareGtId32";
static NSString *ORTrigger1Name                 = @"ORTrigger1Name";
static NSString *ORTrigger2Name                 = @"ORTrigger2Name";
static NSString *ORTriggerUseMSAM		= @"ORTriggerUseMSAM";
static NSString *ORTriggerClockLow		= @"ORTriggerClockLow";
static NSString *ORTriggerClockUpper		= @"ORTriggerClockUpper";
static NSString *ORTriggerTestReg		= @"ORTriggerTestReg";
static NSString *ORTriggerClockEnabled		= @"ORTriggerClockEnabled";
static NSString *ORTriggerTrigger1Xor		= @"ORTriggerTrigger1Xor";
static NSString *ORTriggerTrigger2Xor		= @"ORTriggerTrigger2Xor";
static NSString *ORTriggerMSamPrescale  = @"ORTriggerMSamPrescale";
static NSString *ORTriggerEnableLiveTime		= @"ORTriggerEnableLiveTime";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    
    [self setLowerTimeValue:[decoder decodeInt32ForKey:ORTriggerClockLow]];
    [self setUpperTimeValue:[decoder decodeInt32ForKey:ORTriggerClockUpper]];
    [self setTestRegisterValue:[decoder decodeInt32ForKey:ORTriggerTestReg]];
    [self setClockEnabled:[decoder decodeBoolForKey:ORTriggerClockEnabled]];
    [self setTrigger1GtXor:[decoder decodeBoolForKey:ORTriggerTrigger1Xor]];
    [self setTrigger1GtXor:[decoder decodeBoolForKey:ORTriggerTrigger2Xor]];
    
    [self setGtIdValue:[decoder decodeIntForKey:ORTriggerGTID]];
    [self setLowerTimeValue:[decoder decodeIntForKey:ORTriggerLowerClock]];
    [self setUpperTimeValue:[decoder decodeIntForKey:ORTriggerUpperClock]];
    
    [self setTrigger1Group:[decoder decodeObjectForKey:ORTriggerGroup1]];
    [self setTrigger2Group:[decoder decodeObjectForKey:ORTriggerGroup2]];
    
    [self setShipEvt1Clk:[decoder decodeBoolForKey:ORTriggerShipEvt1Clk]];
    [self setShipEvt2Clk:[decoder decodeBoolForKey:ORTriggerShipEvt2Clk]];
    [self setTrigger2EventInputEnable:[decoder decodeBoolForKey:ORTriggerTrigger2EventInputEnable]];
    [self setTrigger2BusyEnabled:[decoder decodeBoolForKey:ORTriggerTrigger2BusyEnabled]];
    
    [self setUseSoftwareGtId:[decoder decodeBoolForKey:ORTriggerUseSoftwareGtId]];
    [self setSoftwareGtId:[decoder decodeInt32ForKey:ORTriggerSoftwareGtId]];
    
    [self setTrigger1Name:[decoder decodeObjectForKey:ORTrigger1Name]];
    [self setTrigger2Name:[decoder decodeObjectForKey:ORTrigger2Name]];
    
    [self setUseNoHardware:[decoder decodeBoolForKey:ORTriggerNoHardware]];
    [self setUseMSAM:[decoder decodeBoolForKey:ORTriggerUseMSAM]];
    [self setMSamPrescale:[decoder decodeIntForKey:ORTriggerMSamPrescale]];
    
    [self setLiveTimeEnabled:[decoder decodeIntForKey:ORTriggerEnableLiveTime]];
    
    if(mSamPrescale == 0)mSamPrescale = 50;
    
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
    
    [encoder encodeInt32:[self lowerTimeValue] forKey:ORTriggerClockLow];
    [encoder encodeInt32:[self upperTimeValue] forKey:ORTriggerClockUpper];
    [encoder encodeInt32:[self testRegisterValue] forKey:ORTriggerTestReg];
    [encoder encodeBool:[self clockEnabled] forKey:ORTriggerClockEnabled];
    [encoder encodeBool:[self trigger1GtXor] forKey:ORTriggerTrigger1Xor];
    [encoder encodeBool:[self trigger2GtXor] forKey:ORTriggerTrigger2Xor];
    
    [encoder encodeInt:[self gtIdValue] forKey:ORTriggerGTID];
    [encoder encodeInt:[self lowerTimeValue] forKey:ORTriggerLowerClock];
    [encoder encodeInt:[self upperTimeValue] forKey:ORTriggerUpperClock];
    
    [encoder encodeObject:[self trigger1Group] forKey:ORTriggerGroup1];
    [encoder encodeObject:[self trigger2Group] forKey:ORTriggerGroup2];
    [encoder encodeBool:[self shipEvt1Clk] forKey:ORTriggerShipEvt1Clk];
    [encoder encodeBool:[self shipEvt2Clk] forKey:ORTriggerShipEvt2Clk];
    [encoder encodeBool:[self trigger2EventInputEnable] forKey:ORTriggerTrigger2EventInputEnable];
    [encoder encodeBool:[self trigger2BusyEnabled] forKey:ORTriggerTrigger2BusyEnabled];
    
    [encoder encodeBool:[self useSoftwareGtId] forKey:ORTriggerUseSoftwareGtId];
    [encoder encodeInt32:[self softwareGtId] forKey:ORTriggerSoftwareGtId];
    
    [encoder encodeObject:[self trigger1Name] forKey:ORTrigger1Name];
    [encoder encodeObject:[self trigger2Name] forKey:ORTrigger2Name];
    [encoder encodeBool:[self useNoHardware] forKey:ORTriggerNoHardware];
    [encoder encodeBool:[self useMSAM] forKey:ORTriggerUseMSAM];
    [encoder encodeInt:[self mSamPrescale] forKey:ORTriggerMSamPrescale];
    [encoder encodeInt:[self liveTimeEnabled] forKey:ORTriggerEnableLiveTime];
    
}

- (NSMutableDictionary*) captureCurrentState:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super captureCurrentState:dictionary];    
    [objDictionary setObject:[NSNumber numberWithBool:shipEvt1Clk] forKey:@"shipEvt1Clk"];
    [objDictionary setObject:[NSNumber numberWithBool:shipEvt2Clk] forKey:@"shipEvt2Clk"];
    [objDictionary setObject:[NSNumber numberWithBool:useSoftwareGtId] forKey:@"useSoftwareGtId"];
    [objDictionary setObject:[NSNumber numberWithBool:useMSAM] forKey:@"useMSAM"];
    [objDictionary setObject:[NSNumber numberWithBool:useNoHardware] forKey:@"useNoHardware"];
    [objDictionary setObject:[NSNumber numberWithBool:clockEnabled] forKey:@"clockEnabled"];
    [objDictionary setObject:[NSNumber numberWithBool:trigger1GtXor] forKey:@"trigger1GtXor"];
    [objDictionary setObject:[NSNumber numberWithBool:trigger2GtXor] forKey:@"trigger2GtXor"];
    [objDictionary setObject:[NSNumber numberWithBool:trigger2EventInputEnable] forKey:@"trigger2EventInputEnable"];
    [objDictionary setObject:[NSNumber numberWithBool:trigger2BusyEnabled] forKey:@"trigger2BusyEnabled"];
    [objDictionary setObject:[NSNumber numberWithBool:liveTimeEnabled] forKey:@"liveTimeEnabled"];

    return objDictionary;
}

#pragma mark ¥¥¥Board ID Decoders
-(NSString*) boardIdString
{
    unsigned long aBoardId  = [self readBoardID];
    unsigned short id       = [self decodeBoardId:aBoardId];
    unsigned short type     = [self decodeBoardType:aBoardId];
    unsigned short rev      = [self decodeBoardRev:aBoardId];
    NSString* name	    = [NSString stringWithString:[self decodeBoardName:aBoardId]];
    
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
    return (aBoardIDWord & 0xF800) >> 11;	// updated to post Jan 02 defions
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

- (unsigned long) optionMask
{
    unsigned long optionMask = 0L;
    if(shipEvt1Clk)     optionMask |= kShipEvt1ClkMask;
    if(shipEvt2Clk)     optionMask |= kShipEvt2ClkMask;
    if(useSoftwareGtId) optionMask |= kUseSoftwareGtIdMask;
    if(useMSAM)		optionMask |= kUseMSAMMask;
    if(useNoHardware)   optionMask |= kUseNoHardwareMask;
    if(clockEnabled)    optionMask |= kClockEnabled;
    if(trigger1GtXor)   optionMask |= kTrigger1GtXorMask;
    if(trigger2GtXor)   optionMask |= kTrigger2GtXorMask;
    if(trigger2EventInputEnable)optionMask |= kTrigger2EventInputEnableMask;
    if(trigger2BusyEnabled)     optionMask |= kTrigger2BusyEnabledMask;
    if(liveTimeEnabled)     optionMask |= kLiveTimeEnabledMask;
    return optionMask;
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
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    
    [[self undoManager] disableUndoRegistration];
    [self setSoftwareGtId:0];
    [[self undoManager] enableUndoRegistration];
    
    if(![[self adapter] controllerCard]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORTrigger32DecoderFor100MHzClockRecord",  @"decoder",
        [NSNumber numberWithLong:clockDataId],      @"dataId",
        [NSNumber numberWithBool:NO],               @"variable",
        [NSNumber numberWithLong:3],                @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"100MHz Clock Record"];

    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORTrigger32DecoderForGTID1Record",                  @"decoder",
        [NSNumber numberWithLong:gtid1DataId],               @"dataId",
        [NSNumber numberWithBool:NO],                        @"variable",
        [NSNumber numberWithLong:gtid1DataId&0x80000000?1:2],@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"GTID Record"];

    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORTrigger32DecoderForGTID2Record",               @"decoder",
        [NSNumber numberWithLong:gtid2DataId],               @"dataId",
        [NSNumber numberWithBool:NO],                        @"variable",
        [NSNumber numberWithLong:gtid2DataId&0x80000000?1:2],@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"GTID Record"];


    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORTrigger32DecoderForLiveTime",           @"decoder",
        [NSNumber numberWithLong:liveTimeDataId],   @"dataId",
        [NSNumber numberWithBool:NO],               @"variable",
        [NSNumber numberWithLong:7],                @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"LiveTime"];

    [aDataPacket addDataDescriptionItem:dataDictionary forKey:@"ORTrigger32Model"];
    

    if([[userInfo objectForKey:@"doinit"]intValue]){
        [self resetLiveTime];
    }
    if(!useNoHardware){
		[self initBoardPart1];
		[self initBoardPart2];
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
		[self initBoardPart2];
    }
    
    [self clearExceptionCount];
    [self setGtErrorCount:0];
    
    [self checkSoftwareGtIdAlarm];
    [self checkUseNoHardwareAlarm];
    
    eventPlaceHolder1 = [[NSData data] retain];
    eventPlaceHolder2 = [[NSData data] retain];
    timePlaceHolder1 = [[NSData data] retain];
    timePlaceHolder2 = [[NSData data] retain];
    timer = [[ORTimer alloc] init];
    [timer start];
	[self shipLiveTimeRecords:1];
    [self performSelector:@selector(shipLiveTimeMidRun) withObject:nil afterDelay:10*60];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    
    unsigned long gtid = 0;
    unsigned long data[2];
    unsigned long len;
    NSData* event1gtData  = nil;
    NSData* event2gtData = nil;
    NSString* errorLocation;
    
    unsigned short statusReg;
    BOOL isMSAMEvent = NO;
    NS_DURING
		// read the status register to check for an event and save the value since
		// we will reset the event when the gtid register is read.
		// Note that we force events if in the nohardware mode.
		
		errorLocation = @"Reading Status Reg";
		if(!useNoHardware)  {
			statusReg = [self readStatus];
			if([self countErrorBitSet:statusReg]){
				NSLogError(@"",@"Trigger Card Error",@"GTID Error Bit Set",nil);
				[self resetCountError];
			}
			[timer reset];
			if(useSoftwareGtId) {
				statusReg |= kValidTrigger1GTClockMask | kValidTrigger2GTClockMask;
			}
		}
		else statusReg = kValidTrigger1GTClockMask | kValidTrigger2GTClockMask | kEventMask;
		
		//Note for debugging. EVERY variable in the following block should have a '1' in it if is referring to
		//an event, gtid, or placeholder.
		if((statusReg & kTrigger1EventMask)){
			
			BOOL removePlaceHolders = NO;
			
			if(!(statusReg & kValidTrigger1GTClockMask)){
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
			
			if(statusReg & kValidTrigger1GTClockMask){
				//read the gtid. This will return a software generated gtid if in the useSoftwareGtId mode.
				//Will reset the event 1 bit if the gtid hw is actually read.
				errorLocation = @"Reading Event1 GtID";
				gtid = [self getGtId1];
				if(useSoftwareGtId || useNoHardware){
					//using the software generated gtid, so this is a special case to keep from flooding the
					//data stream with garbage gtid data. put a placeholder into the data object. We will
					//replace it with a real gtid data word below if data is actually generated.
					[aDataPacket addData:eventPlaceHolder1];
					if(shipEvt1Clk)[aDataPacket addData:timePlaceHolder1];
					removePlaceHolders = YES;
					//in software gtid mode, so must reset the event 1 bit before reading the children.
				}
				else {
					//pack the gtid and create an NSData object for it.
                    
                    if(IsShortForm(gtid1DataId)){
                        len = 1;
                        data[0] = gtid1DataId | (0x01<<24) | (0x00ffffff&gtid);
                    }
                    else {
                        len = 2;
                        data[0] = gtid1DataId | len;
                        data[1] = (0x01<<24) | (0x00ffffff&gtid);
                    }
                    event1gtData = [NSData dataWithBytes:&data length:len*sizeof(long)];

					
					//put the gtid into the data object
					[aDataPacket addData:event1gtData];
					if(shipEvt1Clk){
						//ship the clock if the ship bit is set.
						NSData* clockData = [self getTimeData:(ORDataPacket*)aDataPacket  statusReg:statusReg eventMask:kTrigger1EventMask trigger:1];
						[aDataPacket addData: clockData];
					}
				}
			}
			
			if(!useNoHardware){
				errorLocation = @"Resetting Event1";
				[self resetTrigger1GTStatusBit];
			}
			
			//keep track if data is taken if in the useSoftware GtId mode.
			int lastDataCount = 0;
			if(useSoftwareGtId || useNoHardware){
				lastDataCount = [aDataPacket dataCount];
			}
			
			if(useMSAM && !useNoHardware){
				//MSAM is a special bit that is set if a trigger 1 has occurred within 15 microseconds after a trigger2
				errorLocation = @"Reading Trigger M_SAM";
				unsigned short reReadStat = statusReg;
				if((reReadStat & kValidTrigger1GTClockMask) && !(reReadStat & kMSamEventMask)){
					long deltaTime = [timer microseconds];
					if(deltaTime < 15){
						struct timespec ts;
						ts.tv_sec = 0;
						ts.tv_nsec = 15000 - (deltaTime*1000);
						nanosleep(&ts, NULL);
					}
					reReadStat = [self readStatus];
					
				}
				if(reReadStat & kMSamEventMask){
					isMSAMEvent = YES;
				}
				[self clearMSAM];
			}
			
			//OK finally go out and read all the data takers scheduled to be read out with a trigger 1 event.
			errorLocation = @"Reading Event1 Children";
			[self _readOutChildren:dataTakers1 dataPacket:aDataPacket  useParams:YES withGTID:gtid isMSAMEvent:isMSAMEvent];
			
			if(useSoftwareGtId || useNoHardware){
				//all of this is done here only so that we can control when the software gtid is incremented.
				if([aDataPacket dataCount]>lastDataCount){
					[self incrementSoftwareGtId];
                    
                    if(IsShortForm(gtid1DataId)){
                        len = 1;
                        data[0] = gtid1DataId | (0x01<<24) | (0x00ffffff&gtid);
                    }
                    else {
                        len = 2;
                        data[0] = gtid1DataId | len;
                        data[1] = (0x01<<24) | (0x00ffffff&gtid);
                    }
                    event1gtData = [NSData dataWithBytes:&data length:len*sizeof(long)];

					[aDataPacket replaceData:eventPlaceHolder1 withData:event1gtData];
					if(shipEvt1Clk){
						NSData* clockData = [self getTimeData:(ORDataPacket*)aDataPacket  statusReg:statusReg eventMask:kTrigger1EventMask trigger:1];
						[aDataPacket replaceData:timePlaceHolder1 withData:clockData];
						
					}
					removePlaceHolders = NO;
				}
			}
			else if(!event1gtData){
				//oops, no hw gtid data was produced even tho we had a event 1 bit set in the status word.
				//this is an error, count it and reset the status bit if using hw.
				[self setGtErrorCount:gtErrorCount+1];
				
				NSLogError(@"No GTID",[NSString stringWithFormat:@"Crate %d",[self crateNumber]], @"Trigger Card",trigger1Name,nil);
				
			}
			
			if(removePlaceHolders){
				//no data so remove the place holder.
				[aDataPacket removeData:eventPlaceHolder1];
				if(shipEvt1Clk)[aDataPacket removeData:timePlaceHolder1];
			}
			
			
		}
		
		//read the status word again just in case there was a trigger2 event while we were
		//reading the trigger1 event.
		if(!(statusReg & kTrigger2EventMask)){
			if(!useNoHardware)  {
				statusReg = [self readStatus];
				if(useSoftwareGtId) {
					statusReg |= kValidTrigger1GTClockMask | kValidTrigger2GTClockMask;
				}
			}
			else statusReg = kValidTrigger1GTClockMask | kValidTrigger2GTClockMask | kEventMask;
		}
		
		
		//Note for debugging. EVERY variable in the following block should have a '2' in it if is referring to
		//an event, gtid, or placeholder.
		if(statusReg & kTrigger2EventMask){
			//event mask 2 is special and requires that the children's hw be readout BEFORE the GTID
			//word is read. Reading the GTID clears the event 2 bit in the status word and can cause
			//a lockout of the hw.
			
			//put a placeholder into the data object because we must ship the gtid before the data
			//We will replace the placeholder with a real gtid data word below.
			[aDataPacket addData:eventPlaceHolder2];
			
			//ship the clock if the ship bit is set.
			if(shipEvt2Clk){
				[aDataPacket addData:timePlaceHolder2];
			}
			
			
			//go out and read all the data takers scheduled to be read out with a trigger 2 event.
			//also we keep track if any data was actually taken
			int lastDataCount = [aDataPacket dataCount];
			errorLocation = @"Reading Event2 Children";
			[self _readOutChildren:dataTakers2 dataPacket:aDataPacket useParams:NO withGTID:0  isMSAMEvent:0]; //don't know the gtid so pass 0
			BOOL dataWasTaken = [aDataPacket dataCount]>lastDataCount;
			
			if(!(statusReg & kValidTrigger2GTClockMask)){
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
			if(statusReg & kValidTrigger2GTClockMask){
				errorLocation = @"Reading Event2 GtId";
				gtid = [self getGtId2];
				if(dataWasTaken){
					if(useSoftwareGtId){
						[self incrementSoftwareGtId];
						if(!useNoHardware){
							//we are in the software gtid mode but not using hw so
							//we have to clear the event bit.
							errorLocation = @"Resetting Event2";
							[self resetTrigger2GTStatusBit];
						}
					}
					//OK there was some data so pack the gtid.
                    if(IsShortForm(gtid2DataId)){
                        len = 1;                        
                        data[0] = gtid2DataId | (0x01<<25) | (0x00ffffff&gtid);
                    }
                    else {
                        len = 2;                        
                        data[0] = gtid2DataId | len;
                        data[1] = (0x01<<25) | (0x00ffffff&gtid);
                    }
                    event2gtData = [NSData dataWithBytes:&data length:len*sizeof(long)];
				}
			}
			
			if(dataWasTaken){
				//there was some data so replace the placeholder with the true gtid data.
				if(event2gtData){
					[aDataPacket replaceData:eventPlaceHolder2 withData:event2gtData];
					if(shipEvt2Clk){
						NSData* clockData = [self getTimeData:(ORDataPacket*)aDataPacket  statusReg:statusReg eventMask:kTrigger2EventMask trigger:2];
						[aDataPacket replaceData:timePlaceHolder2 withData:clockData];
					}
				}
				else {
					//Whoooaaa, this is an error. There was some data taken but there was no gtid, software
					//or otherwise. count the error. clear the event if using hardware because it may not have
					//been cleared.
					if(!useNoHardware){
						errorLocation = @"Resetting Event2";
						[self resetTrigger2GTStatusBit];
					}
					[self setGtErrorCount:gtErrorCount+1];
					NSLogError(@"No GTID",[NSString stringWithFormat:@"Crate %d",[self crate]], @"Trigger Card",trigger2Name,nil);
					//no gtid so remove the place holder.
					[aDataPacket removeData:eventPlaceHolder2];
					if(shipEvt2Clk) [aDataPacket removeData:timePlaceHolder2];
				}
			}
			else {
				//no data so remove the place holder.
				[aDataPacket removeData:eventPlaceHolder2];
				if(shipEvt2Clk) [aDataPacket removeData:timePlaceHolder2];
			}
		}
        
		NS_HANDLER
			NSLogError(@"",@"Trigger Card Error",errorLocation,nil);
			[self incExceptionCount];
			[localException raise];
		NS_ENDHANDLER
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(shipLiveTimeMidRun) object:nil];
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
    
    [eventPlaceHolder1 release];
    [eventPlaceHolder2 release];
    [timePlaceHolder1 release];
    [timePlaceHolder2 release];
    [timer release];
    timer = nil;
	[self shipLiveTimeRecords:0];
    
}

- (void) closeOutRun:(ORDataPacket*)aDataPacket userInfo:(id)userInfo {}

- (unsigned long)  requestGTID
{
    [self requestSoftGTID];
    return [self readSoftGTIDRegister];
}


- (void) checkSoftwareGtIdAlarm
{
    if(!useSoftwareGtId){
		[softwareGtIdAlarm clearAlarm];
    }
    else {
		if(!softwareGtIdAlarm){
			softwareGtIdAlarm = [[ORAlarm alloc] initWithName:@"Using Software Generated GTID" severity:0];
			[softwareGtIdAlarm setSticky:YES];
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
			useNoHardwareAlarm = [[ORAlarm alloc] initWithName:@"Trigger Card Using NO Hardware" severity:0];
			[useNoHardwareAlarm setSticky:YES];
		}
		[useNoHardwareAlarm setAcknowledged:NO];
		[useNoHardwareAlarm postAlarm];
    }
}


- (int) load_eCPU_HW_Config_Structure:(VME_crate_config*)configStruct index:(int)index
{
    configStruct->total_cards++;
    configStruct->card_info[index].hw_type_id = 'TR32'; //should be unique 
    configStruct->card_info[index].hw_mask[0] 	 = gtid1DataId; //better be unique
    configStruct->card_info[index].hw_mask[1] 	 = gtid2DataId; //better be unique
    configStruct->card_info[index].hw_mask[2] 	 = clockDataId; //better be unique
    configStruct->card_info[index].slot 	 = [self slot];
    configStruct->card_info[index].add_mod 	 = [self addressModifier];
    configStruct->card_info[index].base_add  = [self baseAddress];
    
	configStruct->card_info[index].deviceSpecificData[0] = 0;
    if(shipEvt1Clk)		configStruct->card_info[index].deviceSpecificData[0] |= 1<<0;
    if(shipEvt2Clk)		configStruct->card_info[index].deviceSpecificData[0] |= 1<<1;
    if(useSoftwareGtId)	configStruct->card_info[index].deviceSpecificData[0] |= 1<<2;
    if(useMSAM)			configStruct->card_info[index].deviceSpecificData[0] |= 1<<3;
    if(useNoHardware)	configStruct->card_info[index].deviceSpecificData[0] |= 1<<4;
    if(clockEnabled)	configStruct->card_info[index].deviceSpecificData[0] |= 1<<5;
    if(trigger1GtXor)	configStruct->card_info[index].deviceSpecificData[0] |= 1<<6;
    if(trigger2GtXor)	configStruct->card_info[index].deviceSpecificData[0] |= 1<<7;
	configStruct->card_info[index].deviceSpecificData[1] = mSamPrescale;
	
    configStruct->card_info[index].num_Trigger_Indexes = 2;
    int nextIndex = index+1;
    
	configStruct->card_info[index].next_Trigger_Index[0] = -1;
	NSEnumerator* e = [dataTakers1 objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		if([obj respondsToSelector:@selector(load_eCPU_HW_Config_Structure:index:)]){
			if(configStruct->card_info[index].next_Trigger_Index[0] == -1){
				configStruct->card_info[index].next_Trigger_Index[0] = nextIndex;
			}
			int savedIndex = nextIndex;
			nextIndex = [obj load_eCPU_HW_Config_Structure:configStruct index:nextIndex];
			if(obj == [dataTakers1 lastObject]){
				configStruct->card_info[savedIndex].next_Card_Index = -1; //make the last object a leaf node
			}
		}
	}
	
	configStruct->card_info[index].next_Trigger_Index[1] = -1;
    e = [dataTakers2 objectEnumerator];
    while(obj = [e nextObject]){
		if([obj respondsToSelector:@selector(load_eCPU_HW_Config_Structure:index:)]){
			if(configStruct->card_info[index].next_Trigger_Index[1] == -1){
				configStruct->card_info[index].next_Trigger_Index[1] = nextIndex;
			}
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



#pragma mark ¥¥¥Private Methods
- (void) _readOutChildren:(NSArray*)children dataPacket:(ORDataPacket*)aDataPacket useParams:(BOOL)useParams withGTID:(unsigned long)gtid isMSAMEvent:(BOOL)isMSAMEvent
{
	NSMutableDictionary* params = nil;
	if(useParams){
		params = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithLong:gtid] forKey:@"GTID"];
		if(useMSAM && !useNoHardware){
			[params setObject:[NSNumber numberWithBool:isMSAMEvent] forKey:@"MSAMEvent"];
			[params setObject:[NSNumber numberWithInt:mSamPrescale] forKey:@"MSAMPrescale"];
		}
	}
    NSEnumerator* e = [children objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
		[obj takeData:aDataPacket userInfo:params];
    }
}


- (NSData*) getTimeData:(ORDataPacket*)aDataPacket statusReg:(unsigned short)statusReg eventMask:(unsigned long)eventMask trigger: (short)trigger
{
    unsigned long data[3];
    
    if(clockEnabled){
		if(trigger == 1){
			data[0] = clockDataId | 3;
			data[1] = (1<<24) | ([self readUpperTrigger1Time] & 0x00ffffff);
			data[2] = [self readLowerTrigger1Time];
		}
		else {
			data[0] = clockDataId | 3;
			data[1] = (1<<25) | ([self readUpperTrigger2Time] & 0x00ffffff);
			data[2] = [self readLowerTrigger2Time];
		}
    }
    else {
		//grab the event time from the mac
		struct timeval timeValue;
		struct timezone timeZone;
		unsigned long long doeTime  ;
		gettimeofday(&timeValue,&timeZone);
		doeTime = timeValue.tv_sec;
		doeTime = doeTime * 10000000 + timeValue.tv_usec*10;
		
        data[0] = clockDataId | 3;
        data[1] = (unsigned long)(doeTime>>32);
        data[2] = (unsigned long)(doeTime&0x00000000ffffffff);\
		if(trigger == 1)data[1] |= (1<<24);
        else data[1] |= (1<<25);
    }
    return [[[NSMutableData allocWithZone:NULL] initWithBytes:data length:3*sizeof(long)] autorelease];
}

- (void) shipLiveTimeMidRun
{
    [self shipLiveTimeRecords:3];
    [self performSelector:@selector(shipLiveTimeMidRun) withObject:nil afterDelay:30*60];
}

- (void) shipLiveTimeRecords:(short)start
{      

    if(!liveTimeEnabled)return;
    
	NS_DURING
        
		[self latchLiveTime];
        
		unsigned long totalLiveTime;
		unsigned long upperLiveTime;
		unsigned long trig1LiveTime;
		unsigned long trig2LiveTime;
		unsigned long scopeLiveTime;
	 
		[[self adapter] readLongBlock:&upperLiveTime
                            atAddress:baseAddress+kUpperLiveTimeReg
                            numToRead:1
                           withAddMod:addressModifier
                        usingAddSpace:0x01];
        
        [[self adapter] readLongBlock:&totalLiveTime
                            atAddress:baseAddress+kTotalLiveTimeReg
                            numToRead:1
                           withAddMod:addressModifier
                        usingAddSpace:0x01];
        
        
        [[self adapter] readLongBlock:&trig1LiveTime
                            atAddress:baseAddress+kTrigger1LiveTimeReg
                            numToRead:1
                           withAddMod:addressModifier
                        usingAddSpace:0x01];
		
        
        [[self adapter] readLongBlock:&trig2LiveTime
                            atAddress:baseAddress+kTrigger2LiveTimeReg
                            numToRead:1
                           withAddMod:addressModifier
                        usingAddSpace:0x01];


        [[self adapter] readLongBlock:&scopeLiveTime
                            atAddress:baseAddress+kScopeLiveTimeReg
                            numToRead:1
                           withAddMod:addressModifier
                        usingAddSpace:0x01];
        
        
		unsigned long liveTimeData[8];
		
		unsigned long gtid = [self requestGTID];
		//NSLog(@"SoftGTID requested for live-time record: %d\n",gtid);

		unsigned long location = (start&0x3)<<16 | ([self crateNumber]&0x0000000f)<<8 | ([self slot]& 0x0000001f);
        
		liveTimeData[0] = liveTimeDataId | 8;
		liveTimeData[1] = gtid;
		liveTimeData[2] = location;
		liveTimeData[3] = upperLiveTime;
		liveTimeData[4] = totalLiveTime;
		liveTimeData[5] = trig1LiveTime;
		liveTimeData[6] = trig2LiveTime;
		liveTimeData[7] = scopeLiveTime;

		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
                                                            object:[NSData dataWithBytes:liveTimeData length:8*sizeof(long)]];
	NS_HANDLER
        NS_ENDHANDLER
}

- (void) _calculateLiveTime
{
    [self readLiveTimeCounters];

    long long total_diff = total_live-last_total_live;
    long long trig1_diff = trig1_live-last_trig1_live;
    long long trig2_diff = trig2_live-last_trig2_live;
    long long scope_diff = scope_live-last_scope_live;
    //check for rollover
    if(total_diff<0)total_diff = 0xffffffffffffffffLL - (last_total_live - total_live);
    if(trig1_diff<0)trig1_diff = 0xffffffffffffffffLL - (last_trig1_live - trig1_live);
    if(trig2_diff<0)trig2_diff = 0xffffffffffffffffLL - (last_trig2_live - trig2_live);
    if(scope_diff<0)scope_diff = 0xffffffffffffffffLL - (last_scope_live - scope_diff);
        
    NSLog(@"total livetime counter: %lld\n",total_diff);
    NSLog(@"%@ livetime counter: %lld (%.2f%%)\n",[self trigger1Name],trig1_diff,total_diff==0?0:(10000*trig1_diff/total_diff)/100.);
    NSLog(@"%@ livetime counter: %lld (%.2f%%)\n",[self trigger2Name],trig2_diff,total_diff==0?0:(10000*trig2_diff/total_diff)/100.);
    NSLog(@"scope livetime counter: %lld (%.2f%%)\n",scope_diff,total_diff==0?0:(10000*scope_diff/total_diff)/100.);


    [self setLiveTimeCalcRunning:NO];

}
@end


