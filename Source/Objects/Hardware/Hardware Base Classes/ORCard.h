//
//  ORCard.h
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


@interface ORCard : ORGroup {
}

#pragma mark ¥¥¥Accessors
- (id) crate;
- (int) crateNumber;
- (Class) guardianClass;
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian;
- (short) numberSlotsUsed;
- (int) 	slot;
- (void) 	setSlot:(int)aSlot;
- (NSString*) identifier;
- (NSComparisonResult)	slotCompare:(id)otherCard;
- (NSComparisonResult)sortCompare:(OrcaObject*)anObj;
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian;
- (void) positionConnector:(ORConnector*)aConnector;
- (int) displayedSlotNumber;
- (id) rateObject:(int)channel;
- (float) rate:(int)index;
- (NSString*) shortName;
- (void) connected;
- (void) disconnected;

#pragma mark ¥¥¥Archival
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) addObjectInfoToArray:(NSMutableArray*)anArray;
- (NSDictionary*) findCardDictionaryInHeader:(NSDictionary*)fileHeader;

@end

