//
//  ORAugerCard.m
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
#import "ORAugerCard.h"
#import "ORCrate.h"

#import "ORAugerFLTDefs.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORAugerCardPresentChanged = @"ORAugerCardPresentChanged";
NSString* ORAugerCardSlotChangedNotification 	= @"Auger Card Slot Changed";
NSString* ORAugerCardExceptionCountChanged		= @"ORAugerCardExceptionCountChanged";

@implementation ORAugerCard

- (void) dealloc
{
    [registers release];
    [super dealloc];
}


#pragma mark ¥¥¥Accessors

- (BOOL) present
{
    return present;
}

- (void) setPresent:(BOOL)aPresent
{
    present = aPresent;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORAugerCardPresentChanged object:self];
}
- (id) theRegister:(unsigned int)index
{
	return [registers objectAtIndex:index];
}

- (void) addRegister:(id)aRegister atIndex:(unsigned int)index
{
	if(!registers)registers = [[NSMutableArray array] retain];
	if(index > [registers count]){
		int i;
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

- (int) tagBase
{
    return 1;
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORAugerCrateModel");
}
- (NSString*) fullID
{
    return [NSString stringWithFormat:@"%@,%d,%d",NSStringFromClass([self class]),[self crateNumber], [self stationNumber]];
}

- (NSString*) cardSlotChangedNotification
{
    return ORAugerCardSlotChangedNotification;
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"station %d",[self stationNumber]];
}

- (int) stationNumber
{
    return [self tag]+1;
}
- (int) displayedSlotNumber
{
	return [self stationNumber];
}

- (unsigned long)   exceptionCount
{
    return exceptionCount;
}

- (void)clearExceptionCount
{
    exceptionCount = 0;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORAugerCardExceptionCountChanged
					   object:self]; 
    
}

- (void)incExceptionCount
{
    ++exceptionCount;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORAugerCardExceptionCountChanged
					   object:self]; 
}


- (void) checkPresence
{
	//subclasses should override
}

#pragma mark ¥¥¥HW Access
- (unsigned long) read:(unsigned long) address
{
	return [[[self crate] adapter] read:address];
}

- (void) write:(unsigned long)address value:(unsigned long)aValue
{
	[[[self crate] adapter] write:address value:aValue];
}

- (void) writeBitsAtAddress:(unsigned long)anAddress value:(unsigned long)dataWord mask:(unsigned long)aMask shifted:(int)shiftAmount
{
	[[[self crate] adapter] writeBitsAtAddress:anAddress value:dataWord mask:aMask shifted:shiftAmount];
}

- (void) setBitsLowAtAddress:(unsigned long)anAddress mask:(unsigned long)aMask
{
	[[[self crate] adapter]  setBitsLowAtAddress:anAddress mask:aMask];
}

- (void) setBitsHighAtAddress:(unsigned long)anAddress mask:(unsigned long)aMask
{
	[[[self crate] adapter]  setBitsHighAtAddress:anAddress mask:aMask];
}

- (void) readRegisterBlock:(unsigned long)  anAddress 
				dataBuffer:(unsigned long*) aDataBuffer
					length:(unsigned long)  length 
				 increment:(unsigned long)  incr
			   numberSlots:(unsigned long)  nSlots 
			 slotIncrement:(unsigned long)  incrSlots
 {
	[[[self crate] adapter]  readRegisterBlock: anAddress 
									dataBuffer: aDataBuffer
										length: length 
									 increment:  incr
								   numberSlots:  nSlots 
								 slotIncrement:  incrSlots];
 }

- (void) readBlock:(unsigned long)  anAddress 
		dataBuffer:(unsigned long*) aDataBuffer
			length:(unsigned long)  length 
		 increment:(unsigned long)  incr
{
	[[[self crate] adapter]  readBlock: anAddress 
									dataBuffer: aDataBuffer
										length: length 
									 increment:  incr];
 }


- (void) writeBlock:(unsigned long)  anAddress 
		 dataBuffer:(unsigned long*) aDataBuffer
			 length:(unsigned long)  length 
		  increment:(unsigned long)  incr
{
	[[[self crate] adapter]  writeBlock: anAddress 
							 dataBuffer: aDataBuffer
								 length: length 
							  increment:  incr];
}

- (void) clearBlock:(unsigned long)  anAddress 
			pattern:(unsigned long) aPattern
			 length:(unsigned long)  length 
		  increment:(unsigned long)  incr
{
	[[[self crate] adapter]  clearBlock: anAddress 
								pattern: aPattern
								 length: length 
							  increment:  incr];
}

#pragma mark ¥¥¥archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    //[self setRegisters:[decoder decodeObjectForKey:@"ORAugerCardRegisters"]];

    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    //[encoder encodeObject:registers forKey:@"ORAugerCardRegisters"];
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithInt:[self stationNumber]] forKey:@"station"];
    [dictionary setObject:objDictionary forKey:[self identifier]];
    return objDictionary;
}
@end


#pragma mark ¥¥¥¥¥Log Helper Function
void NSLogMono(NSString *msg, ...)
{
  va_list va;

  va_start(va, msg);

  NSString* s1 = [[[NSString alloc] initWithFormat:msg locale:nil  arguments:va] autorelease];
  NSLogFont([NSFont fontWithName:@"Monaco" size:12.0], s1);

  va_end(va);
}


