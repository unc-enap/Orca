/*
 *  OR4ChanModel.cpp
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
#import "OR4ChanTriggerModel.h"

#import "ORVmeCrateModel.h"
#import "ORReadOutList.h"
#import "ORDataTypeAssigner.h"

#pragma mark ¥¥¥Definitions
#define kDefaultAddressModifier		    0x29
#define kDefaultBaseAddress		    0x0007000

#pragma mark ¥¥¥Notification Strings
NSString* OR4ChanTriggerModelShipFirstLastChanged = @"OR4ChanTriggerModelShipFirstLastChanged";
NSString* OR4ChanLowerClockChangedNotification       = @"OR4ChanLowerClockChangedNotification";
NSString* OR4ChanUpperClockChangedNotification		 = @"OR4ChanUpperClockChangedNotification";
NSString* OR4ChanShipClockChangedNotification        = @"OR4ChanShipClockChangedNotification";
NSString* OR4ChanNameChangedNotification             = @"OR4ChanNameChangedNotification";
NSString* OR4ChanErrorCountChangedNotification       = @"OR4ChanErrorCountChangedNotification";
NSString* OR4ChanEnableClockChangedNotification      = @"OR4ChanEnableClockChangedNotification";

NSString* OR4ChanSettingsLock				= @"OR4ChanSettingsLock";
NSString* OR4ChanSpecialLock				= @"OR4ChanSpecialLock";


#pragma mark ¥¥¥Private Implementation
@interface OR4ChanTriggerModel (private)
- (void) _readOutChildren:(NSArray*)children dataPacket:(ORDataPacket*)aDataPacket;
@end

@implementation OR4ChanTriggerModel

- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setBaseAddress:kDefaultBaseAddress];
    [self setAddressModifier:kDefaultAddressModifier];
    [self setTriggerNames:[NSMutableArray array]];
    
    [self setTriggerGroups:[NSMutableArray array]];
    int i;
    for(i=0;i<4;i++){
        ORReadOutList* r = [[ORReadOutList alloc] initWithIdentifier:[self triggerName:i]];
        [triggerGroups addObject:r];
        [r release];
        [self setTriggerName:[NSString stringWithFormat:@"Trigger%d",i] index:i];
    }
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) dealloc
{
    [triggerGroups release];
	[triggerNames release];	
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"4ChanTriggerCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"OR4ChanTriggerController"];
}

- (NSString*) helpURL
{
	return @"VME/Trigger%284_Chan%29.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x68);
}

#pragma mark ¥¥¥Accessors

- (BOOL) shipFirstLast
{
    return shipFirstLast;
}

- (void) setShipFirstLast:(BOOL)aShipFirstLast
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipFirstLast:shipFirstLast];
    
    shipFirstLast = aShipFirstLast;

    [[NSNotificationCenter defaultCenter] postNotificationName:OR4ChanTriggerModelShipFirstLastChanged object:self];
}

- (uint32_t) lowerClock
{
    return lowerClock;
}

- (void) setLowerClock:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowerClock:lowerClock];
    
    lowerClock = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OR4ChanLowerClockChangedNotification
                                                        object:self];
}


- (uint32_t) upperClock
{
    return upperClock;
}

- (void) setUpperClock:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUpperClock:upperClock];
    
    upperClock=aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OR4ChanUpperClockChangedNotification
                                                        object:self];
}

- (NSArray*) triggerGroups
{
    return triggerGroups;
}

- (void) setTriggerGroups:(NSMutableArray*)anArray
{
    [anArray retain];
    [triggerGroups release];
    triggerGroups = anArray;
}

- (void) setShipClockMask:(int)aValue
{
    shipClockMask = aValue;
}

- (BOOL) shipClock:(int)index
{
    return (shipClockMask >> index) & 0x01 ;
}


- (void) setShipClock:(int)index state:(BOOL)state;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipClock:index state:[self shipClock:index]];
    if(state) shipClockMask |= (0x01<<index);
    else shipClockMask &= ~(0x01<<index);
    [[NSNotificationCenter defaultCenter] postNotificationName:OR4ChanShipClockChangedNotification
                                                        object:self
                                                      userInfo: [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:@"Channel"]];                                                      
}

- (uint32_t) errorCount
{
    return errorCount;
}
- (void) setErrorCount:(uint32_t)count
{
    errorCount = count;
    [[NSNotificationCenter defaultCenter] postNotificationName:OR4ChanErrorCountChangedNotification
                                                        object:self];
}

- (void) setTriggerNames:(NSMutableArray*)anArray
{
    [anArray retain];
    [triggerNames release];
    triggerNames = anArray;
    
    if(![triggerNames count]){
        [triggerNames addObject:[NSNull null]];
        [triggerNames addObject:[NSNull null]];
        [triggerNames addObject:[NSNull null]];
        [triggerNames addObject:[NSNull null]];
    }
}

- (NSString *) triggerName:(int)index
{
    return [triggerNames objectAtIndex:index];
}

- (void) setTriggerName:(NSString *)aTriggerName index:(int)index
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerName:[triggerNames objectAtIndex:index] index:index];
    [triggerNames replaceObjectAtIndex:index withObject:aTriggerName];
    
    [[triggerGroups objectAtIndex:index] setIdentifier:aTriggerName];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OR4ChanNameChangedNotification
                                                        object:self];
}


- (BOOL) enableClock
{
    return enableClock;
}

- (void) setEnableClock: (BOOL) flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableClock:enableClock];
    enableClock = flag;
    [[NSNotificationCenter defaultCenter] postNotificationName:OR4ChanEnableClockChangedNotification
                                                        object:self];
}

#pragma mark ¥¥¥Hardware Access
- (unsigned short) 	readBoardID;
{
    uint32_t val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:[self baseAddress]+kBoardIdReg
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return val;
}

- (unsigned short) 	readStatus
{
    uint32_t val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:[self baseAddress]+kStatusReg
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

- (void) resetClock
{
    unsigned short val = 1;
    [[self adapter] writeWordBlock:&val
                         atAddress:[self baseAddress]+kResetCounter
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeEnableClock:(BOOL)state
{
    unsigned short aValue = state;
    [[self adapter] writeWordBlock:&aValue
                         atAddress:[self baseAddress]+kCounterEnable
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (void) softLatch
{
    unsigned short aValue = 1;
    [[self adapter] writeWordBlock:&aValue
                         atAddress:[self baseAddress]+kLatchTimeReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}


- (uint32_t) readLowerClock:(int)index;
{
    int regOffsetList[] = {kReg0LowerReg,kReg1LowerReg,kReg2LowerReg,kReg3LowerReg,kReg4LowerReg};
    uint32_t val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:[self baseAddress]+regOffsetList[index]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return val;
}

- (uint32_t) readUpperClock:(int)index;
{
    int regOffsetList[] = {kReg0UpperReg,kReg1UpperReg,kReg2UpperReg,kReg3UpperReg,kReg4UpperReg};
    uint32_t val = 0;
    [[self adapter] readLongBlock:&val
                        atAddress:[self baseAddress]+regOffsetList[index]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return val&0x00FFFF;
}



- (void) loadLowerClock:(uint32_t)aValue
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress]+kLoadLowerClkReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) loadUpperClock:(uint32_t)aValue
{
    [[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress]+kLoadUpperClkReg
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}


- (NSMutableArray*) children {
    //methods exists to give common interface across all objects for display in lists
    return [NSMutableArray arrayWithObjects:
			[triggerGroups objectAtIndex:0],
			[triggerGroups objectAtIndex:1],
			[triggerGroups objectAtIndex:2],
			[triggerGroups objectAtIndex:3],
			nil];
}


#pragma mark ¥¥¥Archival
static NSString *OR4ChanLowerClock 		= @"OR4ChanLowerClock";
static NSString *OR4ChanUpperClock 		= @"OR4ChanUpperClock";
static NSString *OR4ChanGroups          = @"OR4ChanGroups";
static NSString *OR4ChanShipClockMask   = @"OR4ChanShipClockMask";
static NSString *OR4ChanTriggerNames    = @"OR4ChanTriggerNames";
static NSString *OR4ChanEnableClock     = @"OR4ChanEnableClock";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setShipFirstLast:[decoder decodeBoolForKey:@"shipFirstLast"]];
    [self setLowerClock:[decoder decodeIntForKey:OR4ChanLowerClock]];
    [self setUpperClock:[decoder decodeIntForKey:OR4ChanUpperClock]];
    [self setTriggerGroups:[decoder decodeObjectForKey:OR4ChanGroups]];
    [self setTriggerNames:[decoder decodeObjectForKey:OR4ChanTriggerNames]];
    [self setShipClockMask:[decoder decodeIntForKey:OR4ChanShipClockMask]];
	[self setEnableClock:[decoder decodeIntegerForKey:OR4ChanEnableClock]];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:shipFirstLast forKey:@"shipFirstLast"];
    [encoder encodeInt:lowerClock forKey:OR4ChanLowerClock];
    [encoder encodeInt:upperClock forKey:OR4ChanUpperClock];
    [encoder encodeObject:triggerGroups forKey:OR4ChanGroups];
    [encoder encodeObject:triggerNames forKey:OR4ChanTriggerNames];
    [encoder encodeInteger:shipClockMask forKey:OR4ChanShipClockMask];
    [encoder encodeInteger:enableClock forKey:OR4ChanEnableClock];
    
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];    
    [objDictionary setObject:[NSNumber numberWithInt:shipClockMask] forKey:@"shipClockMask"];
    [objDictionary setObject:[NSNumber numberWithInt:shipFirstLast] forKey:@"shipFirstLast"];
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
        case 1: 	return @"Four Channel";
        case 2: 	return @"NCD";
        case 3: 	return @"Time Tag";
        default: 	return @"Unknown";
    }
}

- (uint32_t) clockDataId { return clockDataId; }
- (void) setClockDataId: (uint32_t) aClockDataId
{
    clockDataId = aClockDataId;
}

- (void) setDataIds:(id)assigner
{
    clockDataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setClockDataId:[anotherObj clockDataId]];
}


- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"OR4ChanTriggerDecoderFor100MHzClock",   @"decoder",
								 [NSNumber numberWithLong:clockDataId],    @"dataId",
								 [NSNumber numberWithBool:NO],             @"variable",
								 [NSNumber numberWithLong:3],              @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"100MHz Clock"];
    
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	int i;
	for(i=0;i<4;i++){
		if([dataTakers objectAtIndex:i]){
			NSMutableArray* eventGroup = [NSMutableArray array];
			if([self shipClock:i]){
				NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
											 [NSString stringWithFormat: @"100MHz Clock Record%d",i], @"name",
											 [NSNumber numberWithLong:clockDataId],  @"dataId",
											 [NSNumber numberWithLong:1],			@"secondaryIdWordIndex",
											 [NSNumber numberWithLong:i],			@"value",
											 [NSNumber numberWithLong:0x7L<<24],		@"mask",
											 [NSNumber numberWithLong:24],			@"shift",
											 nil];
				[eventGroup addObject:aDictionary];
			}
			NSMutableDictionary* aDictionary = [NSMutableDictionary dictionary];
			[[dataTakers objectAtIndex:i] appendEventDictionary:aDictionary topLevel:topLevel];
			if([aDictionary count])[eventGroup addObject:aDictionary];
			
			[anEventDictionary setObject:eventGroup forKey:@"OR4ChanTrigger Trigger"];	
		}
	}
	
}



#pragma mark ¥¥¥DataTaker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"OR4ChanModel"];
    
    //cache the data takers for alittle more speed
    dataTakers = [[NSArray arrayWithObjects:
				   [[triggerGroups objectAtIndex:0] allObjects],
				   [[triggerGroups objectAtIndex:1] allObjects],
				   [[triggerGroups objectAtIndex:2] allObjects],
				   [[triggerGroups objectAtIndex:3] allObjects],
				   nil] retain];
    
    controller = [[self adapter] controllerCard]; //cache the controller for alittle bit more speed.
    
    int i;
    for(i=0;i<4;i++){
        NSEnumerator* e = [[dataTakers objectAtIndex:i] objectEnumerator];
        id obj;
        while(obj = [e nextObject]){
            [obj runTaskStarted:aDataPacket userInfo:userInfo];
        }
    }
    
    [self clearExceptionCount];
    [self setErrorCount:0];
    
    [self writeEnableClock:NO];
    [self loadUpperClock:0];
    [self loadLowerClock:0];
	[self reset];
	for(i=0;i<5;i++){
		[self readLowerClock:i];
	}
    [self writeEnableClock:enableClock];
	for(i=0;i<4;i++){
		gotFirstClk[i] = NO;
	}
}


//----------------Clock Word------------------------------------
// three int32_t words
// word #1:
// 0000 0000 0000 0000 0000 0000 0000 0000   
// ^^^^ ^^^^ ^^^^ ^^------------------------- record id
//                  ^^ ^^^^ ^^^^ ^^^^ ^^^^--- length (should be 3)
// word #2:
// 0000 0000 0000 0000 0000 0000 0000 0000   
// ^^^^-^------------------------------------ spare
//       ^^^--------------------------------- clock index ID (0-4)
//           ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^--- 24 bits holding upper clock reg
//
// word #3:
// 0000 0000 0000 0000 0000 0000 0000 0000   32 bits holding  lower clock reg
//--------------------------------------------------------------

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    NSString* errorLocation = @"";
    
    @try {
        // read the status register to check for an event
		//there are four data child data takers. The status reg, however, starts with a 
		//software latch at status bit 1. that's why the i+1 stuff below, because we never
		//ship the software clock. 
        errorLocation = @"Reading Status Reg";
        uint32_t statusReg;
		[controller readLongBlock:&statusReg
                        atAddress:baseAddress+kStatusReg
                        numToRead:1
                       withAddMod:addressModifier
                    usingAddSpace:0x01];
        
        if(statusReg){
            int i;
            for(i=0;i<4;i++){
                if(statusReg & (0x1<<(i+1))){
					uint32_t eventPlaceHolder = 0;
					BOOL ship = shipClockMask & (0x1<<(i+1)) || (shipFirstLast && !gotFirstClk[i]);
					if(ship)eventPlaceHolder = [aDataPacket reserveSpaceInFrameBuffer:3];
                    [self _readOutChildren:[dataTakers objectAtIndex:i] dataPacket:aDataPacket];
					
                    //must read the clock to reset the status bit.
                    //status bit is reset when the lower reg is read.
                    uint32_t upper = [self readUpperClock:i+1];
                    uint32_t lower = [self readLowerClock:i+1];
                    if(ship){
  						gotFirstClk[i] = YES;
						uint32_t data[3];
                        data[0] = clockDataId | 3;                          //id and length
                        data[1] = ((i&0x7)<<24) | (0x00ffffff&upper);   //index and upper clock
                        data[2] = lower;                               //lower clock
						[aDataPacket replaceReservedDataInFrameBufferAtIndex:eventPlaceHolder withLongs:data length:3];
                    }
                }
            }
        }
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"Four Channel Trigger Card Error",errorLocation,nil);
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	if(shipFirstLast){
		int i;
		for(i=0;i<4;i++){
			uint32_t upper = [self readUpperClock:i+1];
			uint32_t lower = [self readLowerClock:i+1];
			uint32_t data[3];
			data[0] = clockDataId | 3;                     //id and length
			data[1] = ((i&0x7)<<24) | (0x00ffffff&upper);  //index and upper clock
			data[2] = lower;                               //lower clock
			[aDataPacket addLongsToFrameBuffer:data length:3];
		}
	}
    
    int i;
    for(i=0;i<4;i++){
        NSEnumerator* e = [[dataTakers objectAtIndex:i] objectEnumerator];
        id obj;
        while(obj = [e nextObject]){
            [obj runTaskStopped:aDataPacket userInfo:userInfo];
        }
    }    
    
    [dataTakers release];
    dataTakers = nil;
    
}

- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [triggerGroups makeObjectsPerformSelector:@selector(saveUsingFile:) withObject:(id)aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [triggerGroups removeAllObjects];
    
    int i;
    for(i=0;i<4;i++){
        ORReadOutList* r = [[ORReadOutList alloc] initWithIdentifier:[self triggerName:i]];
        [triggerGroups addObject:r];
        [r release];
    }
    [triggerGroups makeObjectsPerformSelector:@selector(loadUsingFile:) withObject:(id)aFile];
}


@end

@implementation OR4ChanTriggerModel (private)
#pragma mark ¥¥¥Private Methods
- (void) _readOutChildren:(NSArray*)children dataPacket:(ORDataPacket*)aDataPacket
{
    int n =  (int)[children count];
    int i;
    for(i=0;i<n;i++){
        [[children objectAtIndex:i] takeData:aDataPacket userInfo:nil];
    }
}


@end


