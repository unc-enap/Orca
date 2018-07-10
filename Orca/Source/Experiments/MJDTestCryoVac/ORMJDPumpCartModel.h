//
//  ORMJDPumpCartModel.h
//  Orca
//
//  Created by Mark Howe on Mon Aug 13, 2012.
//  Copyright ¬© 2012 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORVacuumParts.h"
#import "OROrderedObjHolding.h"

@class ORVacuumGateValve;
@class ORVacuumPipe;
@class ORLabJackUE9Model;
@class ORAlarm;
@class ORMJDTestCryostat;

//-----------------------------------
//region definitions
#define kRegionDiaphramPump	0
#define kRegionBelowTurbo	1
#define kRegionAboveTurbo	2
#define kRegionRGA			3
#define kRegionDryN2		4
#define kRegionLeftSide		5
#define kRegionRightSide	6
#define kRegionNegPump		7
#define kRegionCryostat		8
#define kRegionTempA        9
#define kRegionTempB        10
#define kRegionTempC        11
#define kRegionTempD        12

#define kNumberRegions	    13
//-----------------------------------
//component tag numbers
#define kTurboComponent			 0
#define kRGAComponent			 1
#define kPressureGaugeComponent1 2
#define kPressureGaugeComponent2 3
#define kTemperatureComponent1   4

//-----------------------------------
@interface ORMJDPumpCartModel : ORGroup <OROrderedObjHolding>
{
	NSMutableDictionary* partDictionary;
	NSMutableDictionary* valueDictionary;
	NSMutableDictionary* statusDictionary;
	NSMutableArray*		 parts;
	BOOL				 showGrid;
	int					 leftSideConnection;
	int					 rightSideConnection;
	NSMutableArray*		 testCryostats;
	BOOL				 couchPostScheduled;
}

#pragma mark ***Accessors

- (void) setUpImage;
- (void) makeMainController;
- (NSArray*) parts;
- (BOOL) showGrid;
- (void) setShowGrid:(BOOL)aState;
- (void) toggleGrid;
- (int) stateOfGateValve:(int)aTag;
- (NSArray*) pipesForRegion:(int)aTag;
- (ORVacuumPipe*) onePipeFromRegion:(int)aTag;
- (NSArray*) gateValves;
- (ORVacuumGateValve*) gateValve:(int)aTag;
- (NSArray*) valueLabels;
- (NSArray*) statusLabels;
- (NSArray*) staticLabels;
- (NSArray*) gateValvesConnectedTo:(int)aRegion;
- (NSColor*) colorOfRegion:(int)aRegion;
- (NSString*) namesOfRegionsWithColor:(NSColor*)aColor;
- (NSString*) valueLabel:(int)region;
- (NSString*) statusLabel:(int)region;
- (void) openDialogForComponent:(int)i;
- (NSString*) regionName:(int)i;
- (ORMJDTestCryostat*) testCryoStat:(int)i;
- (int) leftSideConnection;
- (void) setLeftSideConnection:(int)aCryostat;
- (int) rightSideConnection;
- (void) setRightSideConnection:(int)aCryostat;

#pragma mark ***Notificatons
- (void) registerNotificationObservers;
- (void) turboChanged:(NSNotification*)aNote;
- (void) pressureGaugeChanged:(NSNotification*)aNote;
- (void) rgaChanged:(NSNotification*)aNote;
- (void) temperatureGaugeChanged:(NSNotification*)aNote;

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••OROrderedObjHolding Protocol
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
- (BOOL) detectorsBiased;

@end

extern NSString* ORMJDPumpCartModelShowGridChanged;
extern NSString* ORMJCTestCryoVacLock;
extern NSString* ORMJDPumpCartModelRightSideConnectionChanged;
extern NSString* ORMJDPumpCartModelLeftSideConnectionChanged;
extern NSString* ORMJDPumpCartModelConnectionChanged;

@interface NSObject (ORMHDVacuumModel)
- (double) convertedValue:(int)aChan;
@end

