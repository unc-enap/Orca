//
//  ORIpeCard.m
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
#import "ORIpeCard.h"
#import "ORCrate.h"

#import "ORIpeFLTDefs.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORIpeCardPresentChanged = @"ORIpeCardPresentChanged";
NSString* ORIpeCardSlotChangedNotification 	= @"Ipe Card Slot Changed";
NSString* ORIpeCardExceptionCountChanged		= @"ORIpeCardExceptionCountChanged";

@implementation ORIpeCard

- (void) dealloc
{
    [registers release];
    [super dealloc];
}

#pragma mark ¥¥¥Accessors
- (BOOL) isPartOfRun
{
    return isPartOfRun;
}

- (void) setIsPartOfRun:(BOOL)aPartOfRun
{
    isPartOfRun=aPartOfRun;
}

- (BOOL) present
{
    return present;
}

- (void) setPresent:(BOOL)aPresent
{
    present = aPresent;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORIpeCardPresentChanged object:self];
}

- (id) theRegister:(unsigned int)index
{
	return [registers objectAtIndex:index];
}

- (void) addRegister:(id)aRegister atIndex:(unsigned int)index
{
	if(!registers)registers = [[NSMutableArray array] retain];
	if(index > [registers count]){
		NSUInteger i;
		for(i=[registers count];i<index;i++){
			[registers addObject:[NSNull null]];
		}
	}
	[registers insertObject:aRegister atIndex:index];
}



- (NSMutableArray*) registers
{
    return registers;
}

- (void) setRegisters:(NSMutableArray*)aRegisters
{
    [aRegisters retain];
    [registers release];
    registers = aRegisters;
}

- (NSUInteger) tagBase
{
    return 1;
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORIpeCrateModel");
}
- (NSString*) fullID
{
    return [NSString stringWithFormat:@"%@,%d,%d",NSStringFromClass([self class]),(int)[self crateNumber], (int)[self stationNumber]];
}

- (NSString*) cardSlotChangedNotification
{
    return ORIpeCardSlotChangedNotification;
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"station %d",[self stationNumber]];
}

- (int) stationNumber
{
    return (int)[self tag]+1;
}
- (int) displayedSlotNumber
{
	return (int)[self stationNumber];
}

- (uint32_t)   exceptionCount
{
    return exceptionCount;
}

- (void)clearExceptionCount
{
    exceptionCount = 0;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORIpeCardExceptionCountChanged
					   object:self]; 
    
}

- (void)incExceptionCount
{
    ++exceptionCount;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORIpeCardExceptionCountChanged
					   object:self]; 
}


- (void) checkPresence
{
	//subclasses should override
}

#pragma mark ¥¥¥HW Access
- (uint32_t) read:(uint32_t) address
{
	return [[[self crate] adapter] read:address];
}

- (void) write:(uint32_t)address value:(uint32_t)aValue
{
	[[[self crate] adapter] write:address value:aValue];
}

- (void) writeBitsAtAddress:(uint32_t)anAddress value:(uint32_t)dataWord mask:(uint32_t)aMask shifted:(int)shiftAmount
{
	[[[self crate] adapter] writeBitsAtAddress:anAddress value:dataWord mask:aMask shifted:shiftAmount];
}

- (void) setBitsLowAtAddress:(uint32_t)anAddress mask:(uint32_t)aMask
{
	[[[self crate] adapter]  setBitsLowAtAddress:anAddress mask:aMask];
}

- (void) setBitsHighAtAddress:(uint32_t)anAddress mask:(uint32_t)aMask
{
	[[[self crate] adapter]  setBitsHighAtAddress:anAddress mask:aMask];
}

- (void) readRegisterBlock:(uint32_t)  anAddress 
				dataBuffer:(uint32_t*) aDataBuffer
					length:(uint32_t)  length 
				 increment:(uint32_t)  incr
			   numberSlots:(uint32_t)  nSlots 
			 slotIncrement:(uint32_t)  incrSlots
 {
	[[[self crate] adapter]  readRegisterBlock: anAddress 
									dataBuffer: aDataBuffer
										length: length 
									 increment:  incr
								   numberSlots:  nSlots 
								 slotIncrement:  incrSlots];
 }

- (void) readBlock:(uint32_t)  anAddress 
		dataBuffer:(uint32_t*) aDataBuffer
			length:(uint32_t)  length 
		 increment:(uint32_t)  incr
{
	[[[self crate] adapter]  readBlock: anAddress 
									dataBuffer: aDataBuffer
										length: length 
									 increment:  incr];
 }


- (void) writeBlock:(uint32_t)  anAddress 
		 dataBuffer:(uint32_t*) aDataBuffer
			 length:(uint32_t)  length 
		  increment:(uint32_t)  incr
{
	[[[self crate] adapter]  writeBlock: anAddress 
							 dataBuffer: aDataBuffer
								 length: length 
							  increment:  incr];
}

- (void) clearBlock:(uint32_t)  anAddress 
			pattern:(uint32_t) aPattern
			 length:(uint32_t)  length 
		  increment:(uint32_t)  incr
{
	[[[self crate] adapter]  clearBlock: anAddress 
								pattern: aPattern
								 length: length 
							  increment:  incr];
}

- (void)	initVersionRevision
{
	//subclass responsiblity
}

#pragma mark ¥¥¥archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    //[self setRegisters:[decoder decodeObjectForKey:@"ORIpeCardRegisters"]];

    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    //[encoder encodeObject:registers forKey:@"ORIpeCardRegisters"];
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithInteger:[self stationNumber]] forKey:@"Card"];
    [dictionary setObject:objDictionary forKey:[self identifier]];
    return objDictionary;
}
@end
