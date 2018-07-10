/*
 *  ORL4532Model.cpp
 *  Orca
 *
 * LeCroy 4532 32 Input Majority Logic Unit
 * 
 *  Created by Mark Howe on Fri Sept 29, 2006.
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
#import "ORL4532Model.h"
#import "ORCamacControllerCard.h"
#import "ORCamacCrateModel.h"
#import "ORReadOutList.h"
#import "ORDataTypeAssigner.h"

NSString* ORL4532ModelNumberTriggersChanged   = @"ORL4532ModelNumberTriggersChanged";
NSString* ORL4532ModelIncludeTimingChanged    = @"ORL4532ModelIncludeTimingChanged";
NSString* ORL4532ModelInputRegisterChanged	  = @"ORL4532ModelInputRegisterChanged";
NSString* ORL4532SettingsLock				  = @"ORL4532SettingsLock";
NSString* ORL4532ModelDelaysChanged			  = @"ORL4532ModelDelaysChanged";
NSString* ORL4532ModelDelayEnableMaskChanged  = @"ORL4532ModelDelayEnableMaskChanged";
NSString* ORL4532ModelTriggerNamesChanged	  = @"ORL4532ModelTriggerNamesChanged";

@implementation ORL4532Model

#pragma mark ¥¥¥Initialization
- (id) init
{
	[super init];
	int i;
	for(i=0;i<32;i++){
		ORReadOutList* r1 = [[ORReadOutList alloc] initWithIdentifier:[NSString stringWithFormat:@"Trigger %d",i]];
		[self setTrigger:i group:r1];
		[r1 release];
	}
	return self;
}

- (void) dealloc
{
    [triggerNames release];
    [delays release];
	int i;
	for(i=0;i<32;i++){
		[triggerGroup[i] release];
	}
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"L4532"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORL4532Controller"];
}

- (NSString*) helpURL
{
	return @"CAMAC/L4532.html";
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"L4532";
}
- (NSArray*) triggerNames
{
    return triggerNames;
}

- (void) setTriggerNames:(NSMutableArray*)aTriggerNames
{
    [aTriggerNames retain];
    [triggerNames release];
    triggerNames = aTriggerNames;
}

- (NSString*) triggerName:(int)index
{
	return [triggerNames objectAtIndex:index];
}

- (unsigned long) delayEnableMask
{
    return delayEnableMask;
}

- (void) setDelayEnableMask:(unsigned long)anEnableMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDelayEnableMask:delayEnableMask];
	
    delayEnableMask = anEnableMask;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORL4532ModelDelayEnableMaskChanged
	 object:self];    
}

- (NSArray*) delays
{
    return delays;
}

- (void) setDelays:(NSMutableArray*)aDelays
{
    [aDelays retain];
    [delays release];
    delays = aDelays;
}

- (int) delay:(int)index
{
	return [[delays objectAtIndex:index] intValue];
}

- (void) setTrigger:(int)index withName:(NSString*)aName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrigger:index withName:[triggerNames objectAtIndex:index]];
	[triggerNames replaceObjectAtIndex:index withObject:aName];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL4532ModelTriggerNamesChanged object:self];
	
    [triggerGroup[index] setIdentifier:aName];
	
}

- (void) setDelayEnabledMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned long aMask = delayEnableMask;
	if(aValue)aMask |= (1L<<bit);
	else aMask &= ~(1L<<bit);
	[self setDelayEnableMask:aMask];
}	

- (void) setDelay:(int)index withValue:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDelay:index withValue:[[delays objectAtIndex:index] intValue]];
	[delays replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL4532ModelDelaysChanged object:self];
}



- (int) numberTriggers
{
    return numberTriggers;
}

- (void) setNumberTriggers:(int)aNumberTriggers
{
	if(aNumberTriggers<1)aNumberTriggers = 1;
	if(aNumberTriggers>32)aNumberTriggers = 32;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setNumberTriggers:numberTriggers];
    
    numberTriggers = aNumberTriggers;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL4532ModelNumberTriggersChanged object:self];
	//also post the following to force a redraw of any lists that are displaying our info
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGroupObjectsAdded object:self];
}

- (BOOL) includeTiming
{
    return includeTiming;
}

- (void) setIncludeTiming:(BOOL)aIncludeTiming
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIncludeTiming:includeTiming];
    
    includeTiming = aIncludeTiming;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL4532ModelIncludeTimingChanged object:self];
}


- (unsigned long) triggerId { return triggerId; }
- (void) setTriggerId: (unsigned long) aTriggerId
{
    triggerId = aTriggerId;
}

- (unsigned long) channelTriggerId { return channelTriggerId; }
- (void) setChannelTriggerId: (unsigned long) aChannelTriggerId
{
    channelTriggerId = aChannelTriggerId;
}

#pragma mark ¥¥¥Hardware functions
- (unsigned long) readInputPattern
{
	unsigned short bits1_16 = 0;
	unsigned short bits17_32 = 0;
	[[self adapter] camacShortNAF:[self stationNumber] a:0 f:0 data:&bits1_16];
	if(numberTriggers>16)[[self adapter] camacShortNAF:[self stationNumber] a:1 f:0 data:&bits17_32];
	unsigned long bits17_32L = bits17_32;
	return (bits17_32L<<16) | bits1_16;
}

- (unsigned short) readStatusRegister
{
	unsigned long theRawValue;
	[[self adapter] camacLongNAF:[self stationNumber] a:0 f:1 data:&theRawValue];
	return theRawValue;
}

- (unsigned long) readInputPatternClearMemoryAndLAM
{
	unsigned long bits1_16 = 0;
	unsigned long bits17_32 = 0;
	[[self adapter] camacLongNAF:[self stationNumber] a:0 f:2 data:&bits1_16];
	[[self adapter] camacLongNAF:[self stationNumber] a:1 f:2 data:&bits17_32];
	bits1_16 &= 0xffff;
	bits17_32 &= 0xffff;
	return (bits17_32<<16) | bits1_16;
}

- (BOOL) testLAM
{
	unsigned long dummy;
	unsigned short result = [[self adapter] camacLongNAF:[self stationNumber] a:0 f:8 data:&dummy];
	return isQbitSet(result);
}

- (void) clearMemoryAndLAM
{
	unsigned long dummy;
	[[self adapter] camacLongNAF:[self stationNumber] a:0 f:9 data:&dummy];
}

- (BOOL) testAndClearLAM
{
	unsigned long dummy;
	unsigned short result = [[self adapter] camacLongNAF:[self stationNumber] a:0 f:10 data:&dummy];
	return isQbitSet(result);
}


#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setTriggerNames:[decoder decodeObjectForKey:@"ORL4532ModelTriggerNames"]];
    [self setDelayEnableMask:[decoder decodeInt32ForKey:@"ORL4532ModelDelayEnableMask"]];
    [self setDelays:[decoder decodeObjectForKey:@"ORL4532ModelDelays"]];
    [self setNumberTriggers:[decoder decodeIntForKey:@"ORL4532ModelNumberTriggers"]];
    [self setIncludeTiming:[decoder decodeBoolForKey:@"ORL4532ModelIncludeTiming"]];
	int i;
	for(i=0;i<32;i++){
		[self setTrigger:i group:[decoder decodeObjectForKey:[NSString stringWithFormat:@"Trigger %d",i]]];
	}
	if(!delays){
		[self setDelays:[NSMutableArray array]];
		for(i=0;i<32;i++){
			[delays addObject:[NSNumber numberWithInt:0]];
		}
	}
	
	if(!triggerNames){
		[self setTriggerNames:[NSMutableArray array]];
		for(i=0;i<32;i++){
			[triggerNames addObject:[NSString stringWithFormat:@"Trigger %d",i]];
		}
	}
	
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];	
    [encoder encodeObject:triggerNames forKey:@"ORL4532ModelTriggerNames"];
    [encoder encodeInt32:delayEnableMask forKey:@"ORL4532ModelDelayEnableMask"];
    [encoder encodeObject:delays forKey:@"ORL4532ModelDelays"];
    [encoder encodeInt:numberTriggers forKey:@"ORL4532ModelNumberTriggers"];
    [encoder encodeBool:includeTiming forKey:@"ORL4532ModelIncludeTiming"];
	int i;
	for(i=0;i<32;i++){
		[encoder encodeObject:triggerGroup[i] forKey:[NSString stringWithFormat:@"Trigger %d",i]];
	}
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:delays forKey:@"delays"];
    [objDictionary setObject:[NSNumber numberWithInt:delayEnableMask] forKey:@"delayEnableMask"];
    
	return objDictionary;
}


- (void) saveReadOutList:(NSFileHandle*)aFile
{
	int i;
	for(i=0;i<32;i++){
		[triggerGroup[i] saveUsingFile:aFile];
	}
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
	int i;
	for(i=0;i<32;i++){
		[self setTrigger:i group:[[[ORReadOutList alloc] initWithIdentifier:[NSString stringWithFormat:@"Trigger %d",i]] autorelease]];
		[triggerGroup[i] loadUsingFile:aFile];
	}
}

#pragma mark ¥¥¥DataTaker
- (void) setDataIds:(id)assigner
{
    triggerId		 = [assigner assignDataIds:kLongForm];
	channelTriggerId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setTriggerId:[anotherCard triggerId]];
    [self setChannelTriggerId:[anotherCard channelTriggerId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORL4532DecoderForTrigger",		@"decoder",
								 [NSNumber numberWithLong:triggerId],@"dataId",
								 [NSNumber numberWithBool:YES],		@"variable",
								 [NSNumber numberWithLong:-1],		@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"mainTrigger"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORL4532DecoderForChannelTrigger",			@"decoder",
				   [NSNumber numberWithLong:channelTriggerId],	@"dataId",
				   [NSNumber numberWithBool:NO],				@"variable",
				   [NSNumber numberWithLong:3],				@"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"channelTrigger"];
    return dataDictionary;
}

- (ORReadOutList*) triggerGroup:(int)index
{
	return triggerGroup[index];
}

- (void) setTrigger:(int)index group:(ORReadOutList*)newTriggerGroup
{
    [triggerGroup[index] autorelease];
    triggerGroup[index] = [newTriggerGroup retain];
	
}

- (NSMutableArray*) children {
    //methods exists to give common interface across all objects for display in lists
	NSMutableArray* array = [NSMutableArray array];
	int i;
	for(i=0;i<numberTriggers;i++){
		if(triggerGroup[i])[array addObject:triggerGroup[i]];
	}
    return array;
}


- (void) reset
{
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	
    if(![self adapter]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI-CAMAC Controller (i.e. a CC32)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORL4532Model"];    
    
    //----------------------------------------------------------------------------------------
    controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
    unChangingDataPart   = (([self crateNumber]&0xf)<<21) | (([self stationNumber]& 0x0000001f)<<16); //doesn't change so do it here.
	if(includeTiming)unChangingDataPart |= (0x1<<25);
	cachedStation = [self stationNumber];
    [self clearExceptionCount];
    [self readStatusRegister];
	eventCounter = 0;
	triggerMask = 0;
	
	int i;
	for(i=0;i<numberTriggers;i++){
		triggerMask |= (1<<i);
	    dataTakers[i] = [[triggerGroup[i] allObjects] retain];	//cache of data takers.
		NSEnumerator* e = [dataTakers[i] objectEnumerator];
		id obj;
		while(obj = [e nextObject]){
			if([obj respondsToSelector:@selector(setCAMACMode:)]){
				[obj setCheckLAM:NO];
			}
			[obj runTaskStarted:aDataPacket userInfo:userInfo];
		}
	}
	[self readInputPatternClearMemoryAndLAM];
	
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	
    @try {
		//test if data ready to be read out
		
		if(isQbitSet([controller camacShortNAF:cachedStation a:0 f:8])){

			//data is ready to be readout
			unsigned short bits1_16 = 0;
			unsigned short bits17_32 = 0;
			[controller camacShortNAF:cachedStation a:0 f:0 data:&bits1_16];
			if(numberTriggers>16)[controller camacShortNAF:cachedStation a:1 f:0 data:&bits17_32];
			unsigned long bits17_32L = bits17_32;
			unsigned long inputMask =  (bits17_32L<<16) | bits1_16;
			
			if(inputMask & triggerMask){
				eventCounter++;
				//grab the event time as reference from Jan 1, 2004.
				theTimeRef.asTimeInterval = [NSDate timeIntervalSinceReferenceDate];
				int triggerRecordLength = includeTiming?5:3;
				unsigned long triggerRecord[5];
				triggerRecord[0] = triggerId | triggerRecordLength;
				triggerRecord[1] = eventCounter;
				triggerRecord[2] = unChangingDataPart;
				if(includeTiming){
					triggerRecord[3] = theTimeRef.asLongs[1];
					triggerRecord[4] = theTimeRef.asLongs[0];
				}
				
				[aDataPacket addLongsToFrameBuffer:triggerRecord length:triggerRecordLength];
				
				
				//read out the children for each input bit that's set
				int i;
				for(i=0;i<numberTriggers;i++){
					if(inputMask & (0x1L<<i)){
						unsigned long channelRecord[3];
						channelRecord[0] = channelTriggerId | 3;
						channelRecord[1] = unChangingDataPart;
						channelRecord[2] = inputMask & (0x1L<<i);
						[aDataPacket addLongsToFrameBuffer:channelRecord length:3];
						if(delayEnableMask & (1L<<i)){
							[ORTimer delay:[[delays objectAtIndex:i] intValue]*1E-6];
						}
						
						NSEnumerator* e = [dataTakers[i] objectEnumerator];
						id obj;
						while(obj = [e nextObject]){
							[obj takeData:aDataPacket userInfo:userInfo];
						}
					}
				}
			}
			//clear memory and LAM
			[controller camacShortNAF:cachedStation a:0 f:9];

		}
	}
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
	
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	int i;
	for(i=0;i<numberTriggers;i++){
		NSEnumerator* e = [dataTakers[i] objectEnumerator];
		id obj;
		while(obj = [e nextObject]){
			[obj runTaskStopped:aDataPacket userInfo:userInfo];
		}
		[dataTakers[i] release];
	}
	
}

@end
