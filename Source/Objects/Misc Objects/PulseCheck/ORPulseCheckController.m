//
//  ORPulseCheckContoller.m
//  Orca
//
//  Created by Mark Howe on Monday Apr 4,2016.
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

#pragma mark •••Imported Files
#import "ORPulseCheckController.h"
#import "ORPulseCheckModel.h"

@implementation ORPulseCheckController
- (id) init
{
    self = [super initWithWindowNibName:@"PulseCheck"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [pulseCheckView setFocusRingType:NSFocusRingTypeNone];

    [self updateWindow];
}


#pragma mark •••Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
       
    [notifyCenter addObserver : self
                     selector : @selector(listLockChanged:)
                         name : ORPulseCheckListLock
                       object : nil];
    
	[notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : pulseCheckView];
	
	[notifyCenter addObserver : self
                     selector : @selector(machineAdded:)
                         name : ORPulseCheckMachineAdded
                       object : model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(machineRemoved:)
                         name : ORPulseCheckMachineRemoved
                       object : model];		

	[notifyCenter addObserver : self
                     selector : @selector(forceReload)
                         name : ORPulseCheckModelReloadTable
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lastFileChanged:)
                         name : ORPulseCheckModelLastFileChanged
						object: model];
    
 

}

- (void) updateWindow
{
    [super updateWindow];
    [self tableViewSelectionDidChange:nil];
	[pulseCheckView reloadData];
    [self lastFileChanged:nil];
    [self peopleNotifiedChanged:nil];
}

- (void) forceReload
{
	[pulseCheckView reloadData];
    [self setButtonStates];
}


- (void) listLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORPulseCheckListLock];
    
    [listLockButton setState: locked];
    [self setButtonStates];
}

- (void) peopleNotifiedChanged:(NSNotification*)aNote
{
    [pulseCheckView reloadData];
}

- (void) setButtonStates
{
    BOOL locked = [gSecurity isLocked:ORPulseCheckListLock];
	
	[addMachineButton setEnabled:    !locked];
	[removeMachineButton setEnabled: !locked];
	[saveButton setEnabled:         !locked];
	[restoreButton setEnabled:      !locked];
  }

- (void) machineAdded:(NSNotification*)aNote
{
	[pulseCheckView reloadData];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:[model machineCount]];
	[pulseCheckView selectRowIndexes:indexSet byExtendingSelection:NO];
	
    [self setButtonStates];
}

- (void) machineRemoved:(NSNotification*)aNote
{
	int index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
    index = (int)MIN(index,[model machineCount]-1);
	index = MAX(index,0);
	[pulseCheckView reloadData];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
	[pulseCheckView selectRowIndexes:indexSet byExtendingSelection:NO];
				
    [self setButtonStates];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [pulseCheckView selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [pulseCheckView selectedRow] >= 0;
    }
	[super validateMenuItem:menuItem];
	return YES;
}

#pragma mark •••Delegate Methods
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == pulseCheckView || aNotification == nil){
		int selectedIndex = (int)[pulseCheckView selectedRow];
		[removeMachineButton setEnabled:selectedIndex>=0];
	}
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item
{
    if([gSecurity isLocked:ORPulseCheckListLock])return NO;
	else return YES;
}

#pragma mark •••Interface Management
- (void) lastFileChanged:(NSNotification*)aNote
{
	[lastFileTextField setStringValue: [[model lastFile] stringByAbbreviatingWithTildeInPath]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORPulseCheckListLock to:secure];
    [listLockButton setEnabled:secure];
}



#pragma mark •••Actions


- (IBAction) delete:(id)sender
{
    [self removeMachineAction:nil];
}

- (IBAction) cut:(id)sender
{
    [self removeMachineAction:nil];
}

- (IBAction) addMachineAction:(id)sender
{
	[model addMachine];
}

- (IBAction) removeMachineAction:(id)sender
{
	NSIndexSet* theSet = [pulseCheckView selectedRowIndexes];
	NSUInteger current_index = [theSet firstIndex];
    if(current_index != NSNotFound){
		[model removeMachineAtIndex:current_index];
	}
	[self setButtonStates];
}

- (IBAction) listLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORPulseCheckListLock to:[sender intValue] forWindow:[self window]];
	[self setButtonStates];
}


- (IBAction) loadFileAction:(id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[model lastFile] stringByExpandingTildeInPath];
    if(fullPath) startingDir = [fullPath stringByDeletingLastPathComponent];
    else		 startingDir = NSHomeDirectory();
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model restoreFromFile:[[[openPanel URL] path]stringByAbbreviatingWithTildeInPath]];
       }
    }];
}

- (IBAction) saveFileAction:(id) sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[model lastFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"Untitled";
    }
	
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldStringValue:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [self endEditing];
            [model saveToFile:[[savePanel URL]path]];
       }
    }];
}

- (IBAction) checkNow:(id) sender
{
    [model checkMachines:nil];
}

#pragma mark Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    ORMachineToCheck* aMachine = [model machineAtIndex:rowIndex];
    return [aMachine valueForKey:[aTableColumn identifier]];
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    ORMachineToCheck* aMachine = [model machineAtIndex:rowIndex];
    [aMachine setValue:anObject forKey:[aTableColumn identifier]];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [model machineCount];
}

@end

