//
//  ORAugerCard.h
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

#define kAugerRegReadable	0x1
#define kAugerRegWriteable	0x2

/** Helper function for logging with mono spaced fonts */
void NSLogMono(NSString *msg, ...); // ak, 21.9.07

typedef struct AugerRegisterNamesStruct {
	NSString*       regName;
	unsigned long 	addressOffset;
	int				length;
	short			accessType;
} AugerRegisterNamesStruct; 


@interface ORAugerCard : ORCard {
    NSMutableArray* registers;
	unsigned long   exceptionCount;
    BOOL		    present;
}

#pragma mark ¥¥¥Accessors
- (BOOL) present;
- (void) setPresent:(BOOL)aPresent;
- (id) theRegister:(unsigned int)index;
- (void) addRegister:(id)aRegister atIndex:(unsigned int)index;
- (NSMutableArray*) registers;
- (void) setRegisters:(NSMutableArray*)aRegisters;
- (int) tagBase;
- (Class) guardianClass;
- (NSString*) cardSlotChangedNotification;
- (NSString*) identifier;
- (int) stationNumber;
- (unsigned long)   exceptionCount;
- (void)clearExceptionCount;
- (void)incExceptionCount;
- (int) displayedSlotNumber;

- (void) checkPresence;

#pragma mark ¥¥¥archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark ¥¥¥HW Access
- (unsigned long) read:(unsigned long) address;

- (void)		  write:(unsigned long)address 
						 value:(unsigned long)aValue;
						
- (void) writeBitsAtAddress:(unsigned long)anAddress 
					   value:(unsigned long)dataWord
					   mask:(unsigned long)aMask 
					shifted:(int)shiftAmount;

- (void) setBitsLowAtAddress:(unsigned long)anAddress 
						mask:(unsigned long)aMask;
						
- (void) setBitsHighAtAddress:(unsigned long)anAddress 
						 mask:(unsigned long)aMask;

- (void) readRegisterBlock:(unsigned long)  anAddress 
				dataBuffer:(unsigned long*) aDataBuffer
					length:(unsigned long)  length 
				 increment:(unsigned long)  incr
			   numberSlots:(unsigned long)  nSlots 
			 slotIncrement:(unsigned long)  incrSlots;


- (void) readBlock:(unsigned long)  anAddress 
		dataBuffer:(unsigned long*) aDataBuffer
			length:(unsigned long)  length 
		 increment:(unsigned long)  incr;

- (void) writeBlock:(unsigned long)  anAddress 
		 dataBuffer:(unsigned long*) aDataBuffer
			 length:(unsigned long)  length 
		  increment:(unsigned long)  incr;

- (void) clearBlock:(unsigned long)  anAddress 
			pattern:(unsigned long) aPattern
			 length:(unsigned long)  length 
		  increment:(unsigned long)  incr;


@end

#pragma mark ¥¥¥Extern Definitions
extern NSString* ORAugerCardPresentChanged;
extern NSString* ORAugerCardSlotChangedNotification;
extern NSString* ORAugerCardExceptionCountChanged;