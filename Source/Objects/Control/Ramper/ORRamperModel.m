//
//  ORRamperModel.m
//  test
//
//  Created by Mark Howe on 3/29/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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


#import "ORRamperModel.h"
#import "ORRamperController.h"
#import "ORRampItem.h"

NSString* ORRamperObjectListLock	= @"ORRamperObjectListLock";
NSString* ORRamperItemAdded		    = @"ORRamperItemAdded";
NSString* ORRamperItemRemoved		= @"ORRamperItemRemoved";
NSString* ORRamperSelectionChanged	= @"ORRamperSelectionChanged";
NSString* ORRamperNeedsUpdate		= @"ORRamperNeedsUpdate";

@implementation ORRamperModel

#pragma mark •••Initialization
- (id) init
{
	self=[super init];
	[self ensureMinimumNumberOfRampItems];
	return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[incTimer invalidate];
	[incTimer release];
	[rampItems release];
	[super dealloc];
}

- (void) wakeUp
{
	[rampItems makeObjectsPerformSelector:@selector(loadProxyObjects)];
	if([rampItems count] == 1){
//		[[rampItems objectAtIndex:0] setVisible:YES];
	}
	[super wakeUp];
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage = [NSImage imageNamed:@"Ramper"];
	
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    if([self runningCount]){
        NSImage* anImage = [NSImage imageNamed:@"RampRunning"];
        [anImage drawAtPoint:NSZeroPoint fromRect:[anImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    }
	
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORForceRedraw
	 object: self];
	
}


- (void) makeMainController
{
    [self linkToController:@"ORRamperController"];
}

- (void) ensureMinimumNumberOfRampItems
{
	if(!rampItems)[self setRampItems:[NSMutableArray array]];
	if([rampItems count] == 0){
		ORRampItem* aRampItem = [[ORRampItem alloc] initWithOwner:self];
		[rampItems addObject:aRampItem];
		[aRampItem release];
	}
}

- (void) addRampItem
{
	ORRampItem* aRampItem = [[ORRampItem alloc] initWithOwner:self];
	[rampItems addObject:aRampItem];
	[aRampItem release];
}

#pragma mark •••Accessors
- (NSMutableArray*) wayPoints
{
	return [selectedRampItem wayPoints];
}
- (float) rampTarget
{
	return [selectedRampItem rampTarget];
}

- (NSMutableArray*) rampItems
{
	return rampItems;
}

- (void) setRampItems:(NSMutableArray*)anItem
{
	[anItem retain];
	[rampItems release];
	rampItems = anItem;
}

- (void) addRampItem:(ORRampItem*)anItem afterItem:(ORRampItem*)anotherItem
{
	int index = [rampItems indexOfObject:anotherItem];
	if(![rampItems containsObject:anItem]){
		[rampItems insertObject:anItem atIndex:index];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORRamperItemAdded object:self userInfo:[NSDictionary dictionaryWithObject:anItem forKey:@"RampItem"]];
	}
}

- (void) removeRampItem:(ORRampItem*)anItem
{
	if([rampItems count] > 1){
		[anItem retain];
		[rampItems removeObject:anItem];
		if(anItem == selectedRampItem){
			if([rampItems count]){
				[self setSelectedRampItem:[rampItems lastObject]];
			}
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:ORRamperItemRemoved object:self userInfo:[NSDictionary dictionaryWithObject:anItem forKey:@"RampItem"]];
		[anItem release];
	}
}

- (ORRampItem*) selectedRampItem
{
	return selectedRampItem;
}

- (void) setSelectedRampItem:(ORRampItem*)anItem
{
	if(anItem == selectedRampItem){
		[anItem setVisible:YES];
		return;
	}
	
	[selectedRampItem setVisible:NO]; //set the old one
	[anItem retain];
	[selectedRampItem release];
	selectedRampItem = anItem;
	[selectedRampItem setVisible:YES];//set the new one
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRamperSelectionChanged object:self];
}

- (void) findSelectedItem
{
	NSEnumerator* e = [rampItems objectEnumerator];
	ORRampItem* anItem;
	while(anItem = [e nextObject]){
		if([anItem visible]){
			[self setSelectedRampItem:anItem];
			break;
		}
	}
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		[rampItems makeObjectsPerformSelector:@selector(loadProxyObjects)];
	}
	@catch(NSException* localException) {
	}
}

- (NSString*) lockName
{
	return ORRamperObjectListLock;
}

#pragma mark •••Ramping
- (int) runningCount
{
	return [rampingItems count];
}

- (int) enabledCount
{
	NSEnumerator* e =  [rampItems objectEnumerator];
	ORRampItem* anItem;
	int totalCount = 0;
	while(anItem = [e nextObject]){
		if([anItem globalEnabled])totalCount++;
	}
	return totalCount;
}

- (void) startGlobalRamp
{
	[rampItems makeObjectsPerformSelector:@selector(startGlobalRamp)];
	[self setUpImage];
}

- (void) stopGlobalRamp
{
	[rampItems makeObjectsPerformSelector:@selector(stopGlobalRamp)];
}

- (void) startGlobalPanic
{
	[rampItems makeObjectsPerformSelector:@selector(startGlobalPanic)];
}


- (void) startRamping:(ORRampItem*)anItem
{
	if(!rampingItems){
		rampingItems = [[NSMutableArray array] retain];
		incTimer = [[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(incTime) userInfo:nil repeats:YES] retain];
		[self setUpImage];
	}
	[rampingItems addObject:anItem];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRamperNeedsUpdate object: self];
	
	if(!loadSet)loadSet = [[NSMutableSet alloc] init];
	if(!loadableObjects)loadableObjects = [[NSMutableSet alloc] init];
	if(![loadableObjects containsObject:[anItem targetObject]]){
		[loadableObjects addObject:[anItem targetObject]];
		[loadSet addObject:anItem];
	}
}

- (void) incTime
{
    [[self undoManager] disableUndoRegistration];
	[rampingItems makeObjectsPerformSelector:@selector(incTime)];
	[loadSet makeObjectsPerformSelector:@selector(loadHardware)];
    [[self undoManager] enableUndoRegistration];
}

- (void) stopRamping:(ORRampItem*)anItem turnOff:(BOOL)turnOFF
{
	[rampingItems removeObject:anItem];
	if([rampingItems count] == 0){
		[rampingItems release];
		rampingItems = nil;
		[loadableObjects release];
		loadableObjects = nil;
		[loadSet release];
		loadSet = nil;
		[self setUpImage];
		[incTimer invalidate];
		[incTimer release];
		incTimer = nil;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRamperNeedsUpdate object: self];
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setRampItems:[decoder decodeObjectForKey:@"rampItems"]];
	[rampItems makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
	[self ensureMinimumNumberOfRampItems];
	
	[self findSelectedItem];
	
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:rampItems forKey:@"rampItems"];
    [encoder encodeObject:selectedRampItem forKey:@"selectedRampItem"];
}

@end
