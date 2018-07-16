//
//  OR3DScanPlatformModel.m
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
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
#pragma mark •••Imported Files
#import "OR3DScanPlatformModel.h"
#import "ORVXMModel.h"
#import "ORVXMMotor.h"

@interface OR3DScanPlatformModel (private)

- (id) findObject:(NSString*)aClassName;
@end

NSString* OR3DScanPlatformLock  = @"OR3DScanPlatformLock";

@implementation OR3DScanPlatformModel

#pragma mark •••initialization
- (void) wakeUp
{
    [super wakeUp];
	[self registerNotificationObservers];
}

- (void) sleep
{
    [super sleep];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}


- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"3DScanPlatform.tif"]];
}

- (NSString*) helpURL
{
	return nil;
}

- (void) makeMainController
{
    [self linkToController:@"OR3DScanPlatformController"];
}

- (void) addObjects:(NSArray*)someObjects
{
	[super addObjects:someObjects];
}

- (void) removeObjects:(NSArray*)someObjects
{
	[super removeObjects:someObjects];
}

- (void) registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	ORVXMModel* motor = [self findMotorModel];
	if(motor){
		[notifyCenter addObserver : self
						 selector : @selector(motorChanged:)
							 name : ORVXMMotorPositionChanged
						   object : motor];
		
		[notifyCenter addObserver : self
						 selector : @selector(motorChanged:)
							 name : ORVXMMotorTargetChanged
						   object : motor];
	}	
	
}

- (void) motorChanged:(NSNotification*)aNote
{
	//ORVXMModel* motor = [aNote object];
}

#pragma mark ***Accessors

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
	[self registerNotificationObservers];
	
	[[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
}




#pragma mark •••CardHolding Protocol
- (int) maxNumberOfObjects	{ return 1; }	//default
- (int) objWidth			{ return 80; }	//default
- (int) groupSeparation		{ return 0; }	//default
- (NSString*) nameForSlot:(int)aSlot	
{ 
    return [NSString stringWithFormat:@"Slot %d",aSlot]; 
}

- (NSRange) legalSlotsForObj:(id)anObj
{
	if([anObj isKindOfClass:NSClassFromString(@"ORVXMModel")])return NSMakeRange(0,1);
    else return NSMakeRange(0,0);
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj 
{ 
	if(aSlot == 0      && [anObj isKindOfClass:NSClassFromString(@"ORVXMModel")])		  return NO;
    else return YES;
}

- (int) slotAtPoint:(NSPoint)aPoint 
{
	return floor(((int)aPoint.y)/[self objWidth]);
}

- (NSPoint) pointForSlot:(int)aSlot 
{
	return NSMakePoint(0,aSlot*[self objWidth]);
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
    [anObj setTag:aSlot];
	NSPoint slotPoint = [self pointForSlot:aSlot];
	[anObj moveTo:slotPoint];
}

- (int) slotForObj:(id)anObj
{
    return (int)[anObj tag];
}

- (int) numberSlotsNeededFor:(id)anObj
{
	return 1;
}

- (void) openDialogForComponent:(int)i
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj tag] == i){
			[anObj makeMainController];
			break;
		}
	}
}

- (ORVXMModel*)     findMotorModel		{ return [self findObject:@"ORVXMModel"];     }

@end


@implementation OR3DScanPlatformModel (private)

- (id) findObject:(NSString*)aClassName
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj isKindOfClass:NSClassFromString(aClassName)])return anObj;
	}
	return nil;
}
@end
