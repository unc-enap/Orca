//
//  ORCrate.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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

#import "OROrderedObjHolding.h"

@interface ORCrate : ORGroup <OROrderedObjHolding>  {
    unsigned int	crateNumber;
    BOOL			powerOff;
	id				adapter;
    ORAlarm*        cratePowerAlarm;
	BOOL			showLabels;
    BOOL            lockMovement;

}

- (void) dealloc;
- (void) wakeUp;
- (void) sleep;
- (void) makeConnectors;
- (void) connected;
- (void) disconnected;

#pragma mark ¥¥¥Accessors
- (id) adapter;
- (void) setAdapter:(id)anAdapter;
- (id) controllerCard;
- (void) doNoPowerAlert:(NSException*)exception action:(NSString*)message;
- (uint32_t) requestGTID;
- (NSString*) adapterArchiveKey;
- (void) positionConnector:(ORConnector*)aConnector forCard:(id)aCard;
- (BOOL) showLabels;
- (void) setShowLabels:(BOOL)aState;
- (NSComparisonResult)sortCompare:(OrcaObject*)anObj;
- (NSComparisonResult) crateNumberCompare:(id)aCard;
- (BOOL) lockMovement;
- (void) setLockMovement:(BOOL)aState;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) runAboutToStart:(NSNotification*)aNotification;
- (void) runStarted:(NSNotification*)aNotification;
- (void) runAboutToStop:(NSNotification*)aNotification;
- (void) adapterChanged:(NSNotification*)aNotification;
- (void) viewChanged:(NSNotification*)aNotification;
- (void) childChanged:(NSNotification*)aNotification;

- (NSUInteger)tag;
- (int) crateNumber;
- (void) setCrateNumber: (unsigned int) aCrateNumber;
- (void) sortCards;
- (NSString*) identifier;
- (void)setPowerOff:(BOOL)state;
- (BOOL) powerOff;
- (void) pollCratePower;
- (void) checkCratePower;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (void) addObjectInfoToArray:(NSMutableArray*)anArray;

#pragma mark ¥¥¥OROrderedObjHolding Protocol
- (int) maxNumberOfObjects;
- (int) objWidth;
- (NSRange) legalSlotsForObj:(id)anObj;
- (NSString*) nameForSlot:(int)aSlot;
- (int) slotAtPoint:(NSPoint)aPoint;
- (NSPoint) pointForSlot:(int)aSlot;
- (void) place:(id)anObj intoSlot:(int)aSlot;
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj;
- (int) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;
- (void) drawSlotLabels;
@end

@interface NSObject (ORCrateModel)
- (uint32_t) requestRemoteGTID;
@end

extern NSString* ORCrateAdapterChangedNotification;
extern NSString* ORCrateAdapterConnector;
extern NSString* ORCrateModelShowLabelsChanged;
extern NSString* ORCrateModelCrateNumberChanged;
extern NSString* ORCrateModelLockMovementChanged;
