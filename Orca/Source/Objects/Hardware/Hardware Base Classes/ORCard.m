//
//  ORCard.m
//  Orca
//
//  Created by Mark Howe on Mon Nov 18 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORCard.h"
#import "ORAdcInfoProviding.h"
#import "ORDataPacket.h"


@implementation ORCard

#pragma mark ¥¥¥Accessors
- (id) crate
{
    return guardian;
}

- (int) crateNumber
{
    return [guardian crateNumber];
}

- (short) numberSlotsUsed
{
    return 1; //default. override if needed.
}

- (NSString*) cardSlotChangedNotification
{
    return @""; //override.
}

- (Class) guardianClass
{
	return nil; //override.
}

- (void) connected
{
	//nothing to do.. subclasses can override
}

- (void) disconnected
{
	//nothing to do.. subclasses can override
}

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return [aGuardian isKindOfClass:[self guardianClass]];
}

- (id) rateObject:(int)channel
{
	//subsclasses should override as needed.
	return self;
}

- (float) rate:(int)index
{
	//subsclasses should override as needed.
	return 0;
}

- (NSString*) rateNotification
{
	//subsclasses should override as needed.
	return nil;
}

- (int) 	slot
{
    return [self tag];    
}

- (int) displayedSlotNumber
{
	return [self slot];
}

- (void) 	setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self tag]];
    [self setTag:aSlot];
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:self forKey: ORMovedObject];
    
    [[NSNotificationCenter defaultCenter]
         postNotificationName:[self cardSlotChangedNotification]
                       object:self
                     userInfo: userInfo];

    [[NSNotificationCenter defaultCenter]
         postNotificationName:ORAdcInfoProvidingValueChanged
                       object:self
                     userInfo: userInfo];
}

- (NSString*) fullID
{
    return [NSString stringWithFormat:@"%@,%d,%d",[self className],[self crateNumber], [self slot]];
}

- (NSString*) identifier
{

  return [NSString stringWithFormat:@"crate %d, slot %d",[self crateNumber],[self slot]];
}


- (NSComparisonResult)	slotCompare:(id)otherCard
{
    return [self tag] - [otherCard tag];
}


- (NSComparisonResult)sortCompare:(OrcaObject*)anObj
{
    return [self slotCompare:anObj];
}

- (void) positionConnector:(ORConnector*)aConnector
{
}

- (NSString*) shortName
{
	NSString* shortName =  [self className];
	if([shortName hasPrefix:@"OR"])shortName = [shortName substringFromIndex:2];
	if([shortName hasSuffix:@"Model"]) shortName = [shortName substringToIndex:[shortName length] - 5];
	return shortName;
}

#pragma mark ¥¥¥Archival
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithInt:[self slot]] forKey:@"Card"];
    [dictionary setObject:objDictionary forKey:[self identifier]];
    return objDictionary;
}

- (void) addObjectInfoToArray:(NSMutableArray*)anArray
{
	NSMutableDictionary* stateDictionary = [NSMutableDictionary dictionary];
	[self addParametersToDictionary:stateDictionary];
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	NSEnumerator* e = [stateDictionary keyEnumerator];
	id aKey;
	while(aKey = [e nextObject]){
		NSDictionary* d = [stateDictionary objectForKey:aKey];
		[dictionary addEntriesFromDictionary:d];
	}							
	
	[anArray addObject:dictionary];
}

- (NSDictionary*) findCardDictionaryInHeader:(NSDictionary*)fileHeader
{
	NSDictionary* crateDictionary;
	NSDictionary* cardDictionary;
	//could be old style
	crateDictionary = [fileHeader objectForKey:     [NSString stringWithFormat:@"crate %d",[[self crate] tag]]];
	cardDictionary  = [crateDictionary objectForKey:[NSString stringWithFormat:@"card %d",[self slot]]];
	if(!cardDictionary){
		//nope, new style -- a little harder....
		NSDictionary* objectInfo = [fileHeader objectForKey:@"ObjectInfo"];
		NSArray* crates = [objectInfo objectForKey:@"Crates"];
		//have to match the crate class and crate number
		int i;
		for(i=0;i<[crates count];i++){
			NSDictionary* aCrateDictionary = [crates objectAtIndex:i];
			int firstSlot = [[aCrateDictionary objectForKey:@"FirstSlot"] intValue];
			NSString* testClassName = [aCrateDictionary objectForKey:@"ClassName"];
			if([testClassName isEqualToString:[[self guardian] className]]){
				int testCrateNumber = [[aCrateDictionary objectForKey:@"CrateNumber"] intValue];
				if(testCrateNumber == [self crateNumber]){
					//OK, we found the right crate. Search for the right card dictionary
					NSArray* cards = [aCrateDictionary objectForKey:@"Cards"];
					int card;
					for(card=0;card<[cards count];card++){
						NSDictionary* aCardDictionary = [cards objectAtIndex:card];
						NSString* testClassName = [aCardDictionary objectForKey:@"Class Name"];
						if([testClassName isEqualToString:[self className]]){
							int testSlot = [[aCardDictionary objectForKey:@"Card"] intValue] + firstSlot;
							int slotWeAreLookingFor;
							SEL selector = NSSelectorFromString(@"stationNumber");
							if([self respondsToSelector:selector]){
								//this avoids a compiler warning
								slotWeAreLookingFor = (int)[self performSelector:selector];
							}
							else slotWeAreLookingFor = [self slot];
							if(testSlot == slotWeAreLookingFor){
								//yeah, we found it.
								return aCardDictionary;
							}
						}
					}
				}
			}
		}
	}
	return cardDictionary;
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	//subclasses can override
}
@end
