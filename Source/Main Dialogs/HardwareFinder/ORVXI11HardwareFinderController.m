//
//  ORVXI11HardwareFinderController.m
//  Orca
//
//  Created by Michael Marino on 6 Nov 2011
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORVXI11HardwareFinderController.h"
#import "ORVXI11HardwareFinder.h"
#import "SynthesizeSingleton.h"
#import "ORGroup.h"
#import "ObjectFactory.h"
@class NSDraggingSession;

#define ORVXI11SupportedHardwarePlist @"edu.washington.npl.orca.VXIHardware"

@interface ORVXI11HardwareFinderController (private)
- (void) _setCreatedObjects:(NSArray*)objs;
- (void) _releaseCreatedObjects;
- (NSString*) _stringOfClassToBuildOfDevice:(NSString*) manufacturer model:(NSString*) model;
@end

@implementation ORVXI11HardwareFinderController

SYNTHESIZE_SINGLETON_FOR_ORCLASS(VXI11HardwareFinderController);

-(id)init
{
    self = [super initWithWindowNibName:@"VXI11HardwareFinder"];
    [self setWindowFrameAutosaveName:@"VXI11HardwareFinder"];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self _releaseCreatedObjects];
    [supportedVXIObjects release];
    [super dealloc];
}

- (void) awakeFromNib
{
	
    [self registerNotificationObservers];
    [self updateWindow];
    
    // Register the table view as being a drag source
    [availableHardware setDraggingSourceOperationMask:NSDragOperationCopy forLocal:YES];
    //[availableHardware registerForDraggedTypes:[NSArray arrayWithObject:ORGroupDragBoardItem] ];  
}

- (void) _setCreatedObjects:(NSArray *)objs
{
    [objs retain];
    [createdObjects release];
    createdObjects = objs;
}

- (void) _releaseCreatedObjects
{
    NSInteger i;
    for (i=0; i<[createdObjects count]; i++) {
        [[createdObjects objectAtIndex:i] release];
    }
    [self _setCreatedObjects:nil];
}

- (NSString*) _stringOfClassToBuildOfDevice:(NSString*) manufacturer model:(NSString*) model
{
    if (!supportedVXIObjects) {
        // Get the dictionary from the plist file
        NSString*   vxiSupportedDevicesPlistPath = [[NSBundle mainBundle] pathForResource:ORVXI11SupportedHardwarePlist ofType: @"plist"];
        supportedVXIObjects = [[NSDictionary dictionaryWithContentsOfFile: vxiSupportedDevicesPlistPath] retain];
    }
    return [[supportedVXIObjects objectForKey:manufacturer] objectForKey:model];
}

#pragma mark •••Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver:self
					 selector:@selector(hardwareChanged:)
						 name:ORHardwareFinderAvailableHardwareChanged
					   object:[ORVXI11HardwareFinder sharedVXI11HardwareFinder]];     
}

#pragma mark •••Actions

- (void) refreshHardwareAction:(id)sender
{
    [[ORVXI11HardwareFinder sharedVXI11HardwareFinder] refresh];
    [refreshButton setEnabled:NO];
    [refreshIndicate startAnimation:self];
}

#pragma mark •••Interface Management
- (void) updateWindow
{
}

- (void) hardwareChanged:(NSNotification *)aNote
{
    [refreshIndicate stopAnimation:self];
    [refreshButton setEnabled:YES];
    [availableHardware reloadData];
}

#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
    NSDictionary* aDict = [[ORVXI11HardwareFinder sharedVXI11HardwareFinder] availableHardware];
    ORVXI11IPDevice* dev = [aDict objectForKey:[[aDict allKeys] objectAtIndex:rowIndex]];
    NSString* ident = [aTableColumn identifier];
    if ([ident isEqualToString:@"IP"]) return [dev ipAddress];
    if ([ident isEqualToString:@"Manufacturer"]) return [dev manufacturer];
    if ([ident isEqualToString:@"Model"]) return [dev model];
    if ([ident isEqualToString:@"Serial Number"]) return [dev serialNumber];
    if ([ident isEqualToString:@"Version"]) return [dev version];         
    return @"";
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[[ORVXI11HardwareFinder sharedVXI11HardwareFinder] availableHardware] count];
}
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    return YES;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
}

#pragma mark •••Drag and Drop Methods
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{

    NSMutableArray* pointerArray = [NSMutableArray array];    
    NSDictionary* aDict = [[ORVXI11HardwareFinder sharedVXI11HardwareFinder] availableHardware];    
    NSArray* selectedObjects = [aDict objectsForKeys:[[aDict allKeys] objectsAtIndexes:rowIndexes]
                                                                        notFoundMarker:[ORVXI11IPDevice deviceForString:@""]];
    
    //load the saved objects pointers into the paste board.    
    int i;
    for (i=0;i<[selectedObjects count];i++)
    {
        ORVXI11IPDevice* dev = [selectedObjects objectAtIndex:i];
        NSString* className = [self _stringOfClassToBuildOfDevice:[dev manufacturer] model:[dev model]];
        if (!className) continue;
        id obj = [[ObjectFactory makeObject:className] retain];
        if ([obj respondsToSelector:@selector(setIpAddress:)]) {
            [obj setIpAddress:[dev ipAddress]];
        }
        NSNumber* num = [NSNumber numberWithUnsignedInteger:(NSUInteger)obj];
        [pointerArray addObject:num];
    }
    if ([pointerArray count] == 0) return NO;
    
    [pboard declareTypes:[NSArray arrayWithObjects:ORGroupDragBoardItem, nil] owner:self];
    [pboard setData:[NSData data] forType:ORObjArrayPtrPBType];    
    [self _setCreatedObjects:pointerArray];
    return YES;
}


- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
	//load the saved objects pointers into the paste board.

    NSMutableData *itemData = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:itemData];
    [archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
    [archiver encodeObject:createdObjects forKey:ORObjArrayPtrPBType];
    [archiver finishEncoding];
    [archiver release];
    
    [sender setData:itemData forType:@"ORGroupDragBoardItem"];
}

- (void) tableView:(NSTableView*)tableView draggingSession:(NSDraggingSession *)session
      endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    // The dragging session has ended, we can release the objects we had.
    [self _releaseCreatedObjects];
}

@end
