//
//  ORVmeCarrierCard.h
//  Orca
//
//  Created by Mark Howe on 3/2/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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



#import "ORVmeIOCard.h"
#import "OROrderedObjHolding.h"

@interface ORVmeCarrierCard : ORVmeIOCard <OROrderedObjHolding> {

}

- (void) sortCards:(NSNotification*)aNotification;
- (id) cardInSlot:(int)aSlot;

#pragma mark •••Connector Management
//- (void) positionConnector:(ORConnector*)aConnector forSlot:(int)aSlot;
- (void) connector:(ORConnector*)aConnector tweakPositionByX:(float)x byY:(float)y;

- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) groupSeparation;
- (NSString*) nameForSlot:(int)aSlot;
- (NSRange) legalSlotsForObj:(id)anObj;
- (int) slotAtPoint:(NSPoint)aPoint;
- (NSPoint) pointForSlot:(int)aSlot;
- (void) place:(id)anObj intoSlot:(int)aSlot;
- (int) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;
@end



@interface NSObject (ORVmeDaughterCard)
- (void) positionConnector:(ORConnector*)aConnector forCard:(id)aCard;
- (void) calcBaseAddress;
@end
