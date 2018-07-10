/*
 *  OROrderedObjHolding.h
 *  Orca
 *
 *  Created by Mark Howe on 11/19/08.
 *  Copyright 2008 University of North Carolina. All rights reserved.
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

@protocol OROrderedObjHolding

- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) groupSeparation;
- (NSRange) legalSlotsForObj:(id)anObj;
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj;
- (NSString*) nameForSlot:(int)aSlot;
- (int) slotAtPoint:(NSPoint)aPoint;
- (NSPoint) pointForSlot:(int)aSlot;
- (void) place:(id)anObj intoSlot:(int)aSlot;
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj;
- (NSArray*)selectedObjects;
- (NSEnumerator*) objectEnumerator;
- (int) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;
@end


