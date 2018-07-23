//
//  ORIpeCard.h
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

#define kIpeRegReadable	0x1
#define kIpeRegWriteable	0x2
#define kIpeRegNeedsChannel	0x4
#define kIpeRegNeedsIndex	0x8


typedef struct IpeRegisterNamesStruct {
	NSString*       regName;
	uint32_t 	addressOffset;
	int				length;
	short			accessType;
} IpeRegisterNamesStruct; 


@interface ORIpeCard : ORCard {
    NSMutableArray* registers;
	uint32_t   exceptionCount;
    BOOL		    present;
    BOOL            isPartOfRun;
}

#pragma mark ¥¥¥Accessors
- (BOOL) isPartOfRun;
- (void) setIsPartOfRun:(BOOL)aPartOfRun;
- (BOOL) present;
- (void) setPresent:(BOOL)aPresent;
- (id) theRegister:(unsigned int)index;
- (void) addRegister:(id)aRegister atIndex:(unsigned int)index;
- (NSMutableArray*) registers;
- (void) setRegisters:(NSMutableArray*)aRegisters;
- (NSUInteger) tagBase;
- (Class) guardianClass;
- (NSString*) cardSlotChangedNotification;
- (NSString*) identifier;
- (int) stationNumber;
- (uint32_t)   exceptionCount;
- (void)clearExceptionCount;
- (void)incExceptionCount;
- (int) displayedSlotNumber;
- (void) initVersionRevision;

- (void) checkPresence;

#pragma mark ¥¥¥archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark ¥¥¥HW Access
- (uint32_t) read:(uint32_t) address;

- (void)		  write:(uint32_t)address 
						 value:(uint32_t)aValue;
						
- (void) writeBitsAtAddress:(uint32_t)anAddress 
					   value:(uint32_t)dataWord
					   mask:(uint32_t)aMask 
					shifted:(int)shiftAmount;

- (void) setBitsLowAtAddress:(uint32_t)anAddress 
						mask:(uint32_t)aMask;
						
- (void) setBitsHighAtAddress:(uint32_t)anAddress 
						 mask:(uint32_t)aMask;

- (void) readRegisterBlock:(uint32_t)  anAddress 
				dataBuffer:(uint32_t*) aDataBuffer
					length:(uint32_t)  length 
				 increment:(uint32_t)  incr
			   numberSlots:(uint32_t)  nSlots 
			 slotIncrement:(uint32_t)  incrSlots;


- (void) readBlock:(uint32_t)  anAddress 
		dataBuffer:(uint32_t*) aDataBuffer
			length:(uint32_t)  length 
		 increment:(uint32_t)  incr;

- (void) writeBlock:(uint32_t)  anAddress 
		 dataBuffer:(uint32_t*) aDataBuffer
			 length:(uint32_t)  length 
		  increment:(uint32_t)  incr;

- (void) clearBlock:(uint32_t)  anAddress 
			pattern:(uint32_t) aPattern
			 length:(uint32_t)  length 
		  increment:(uint32_t)  incr;


@end

#pragma mark ¥¥¥Extern Definitions
extern NSString* ORIpeCardPresentChanged;
extern NSString* ORIpeCardSlotChangedNotification;
extern NSString* ORIpeCardExceptionCountChanged;
