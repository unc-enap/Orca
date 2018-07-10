//
//  ORHPSyncCenterController.m
//  Orca
//
//  Created by Mark Howe on Thursday, Sept 15, 2016
//  Copyright (c) 2016 University of North Carolina. All rights reserved.
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


#import "ORSyncCenterController.h"
#import "ORSyncCenterModel.h"

@implementation ORSyncCenterController
- (id) init
{
    self = [ super initWithWindowNibName: @"SyncCenter" ];
    return self;
}
- (void) awakeFromNib
{
	[subComponentsView setGroup:model];
    [orcaListView setFocusRingType:NSFocusRingTypeNone];
    [orcaListView reloadData];
    [dialogLock setFocusRingType:NSFocusRingTypeNone];

 	[super awakeFromNib];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [orcaListView selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [orcaListView selectedRow] >= 0;
    }
    [super validateMenuItem:menuItem];
    return YES;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];

    [notifyCenter addObserver : self
                     selector : @selector(reloadData:)
                         name : ORSyncCenterModelReloadTable
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : orcaListView];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORSyncCenterLock
                        object: nil];

	[notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(orcaAdded:)
                         name : ORSyncCenterOrcaAdded
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(orcaRemoved:)
                         name : ORSyncCenterOrcaRemoved
                       object : model];
}


- (void) updateWindow
{
    [ super updateWindow ];
    [self settingsLockChanged:nil];
}

- (void) reloadData:(NSNotification*)aNote
{
    [orcaListView reloadData];
}

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[subComponentsView setNeedsDisplay:YES];
	}
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSyncCenterLock to:secure];
    [dialogLock setEnabled:secure];
}

- (void) orcaAdded:(NSNotification*)aNote
{
    NSUInteger index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
    index = MIN(index,[model orcaCount]);
    index = MAX(index,0);
    [orcaListView reloadData];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
    [orcaListView selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (void) orcaRemoved:(NSNotification*)aNote
{
    NSUInteger index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
    index = MIN(index,[model orcaCount]-1);
    index = MAX(index,0);
    [orcaListView reloadData];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
    [orcaListView selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
    if([aNotification object] == orcaListView || aNotification == nil){
        NSInteger selectedIndex = [orcaListView selectedRow];
        [removeOrcaButton setEnabled:selectedIndex>=0];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item
{
    if([gSecurity isLocked:ORSyncCenterLock])return NO;
    else return YES;
}

#pragma mark •••Notifications
- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORSyncCenterLock];
    [dialogLock         setState: locked];
    [syncButton         setEnabled: !locked];
    [removeOrcaButton   setEnabled: !locked];
    [addOrcaButton      setEnabled: !locked];
    [orcaListView       setEnabled:!  locked];
}

#pragma mark •••Actions
- (IBAction) syncAction:(id)sender;
{
    [model syncNow];
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORSyncCenterLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) addOrcaAction:(id)sender
{
    [model addOrca];
}

- (IBAction) removeOrcaAction:(id)sender
{
    //only one can be selected at a time. If that restriction is lifted then the following will have to be changed
    //to something a lot more complicated.
    NSIndexSet* theSet = [orcaListView selectedRowIndexes];
    NSUInteger current_index = [theSet firstIndex];
    if(current_index != NSNotFound){
        [model removeOrcaAtIndex:current_index];
    }
}
- (IBAction) delete:(id)sender
{
    [self removeOrcaAction:nil];
}

- (IBAction) cut:(id)sender
{
    [self removeOrcaAction:nil];
}

- (IBAction) dialogLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORSyncCenterLock to:[sender intValue] forWindow:[self window]];
}

#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    if(aTableView == orcaListView){
        id anItem = [[model orcaList] objectAtIndex:rowIndex];
        return [anItem valueForKey:[aTableColumn identifier]];
    }
    else return nil;
}

- (void) tableView:(NSTableView *) aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(aTableView == orcaListView){
        [model setIndex:rowIndex value:anObject forKey:[aTableColumn identifier]];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == orcaListView){
        return [[model orcaList] count];
    }
    else return 0;
}

@end
