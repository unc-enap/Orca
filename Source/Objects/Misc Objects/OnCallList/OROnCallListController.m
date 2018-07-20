//
//  OROnCallListContoller.m
//  Orca
//
//  Created by Mark Howe on Monday Oct 19 2015.
//  Copyright (c) 2015 University of North Carolina. All rights reserved.
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
#import "OROnCallListController.h"
#import "OROnCallListModel.h"

@implementation OROnCallListController
- (id) init
{
    self = [super initWithWindowNibName:@"OnCallList"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [messageField setFocusRingType:NSFocusRingTypeNone];
    [onCallListView setFocusRingType:NSFocusRingTypeNone];

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
                         name : OROnCallListListLock
                       object : nil];
    
	[notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : onCallListView];
	
	[notifyCenter addObserver : self
                     selector : @selector(personAdded:)
                         name : OROnCallListPersonAdded
                       object : model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(personRemoved:)
                         name : OROnCallListPersonRemoved
                       object : model];		

	[notifyCenter addObserver : self
                     selector : @selector(forceReload)
                         name : OROnCallListModelReloadTable
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lastFileChanged:)
                         name : OROnCallListModelLastFileChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(peopleNotifiedChanged:)
                         name : OROnCallListPeopleNotifiedChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(messageChanged:)
                         name : OROnCallListMessageChanged
                        object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(editingDidEnd:)
                         name: NSControlTextDidEndEditingNotification
                       object: onCallListView];

}

- (void) updateWindow
{
    [super updateWindow];
    [self tableViewSelectionDidChange:nil];
	[onCallListView reloadData];
    [self lastFileChanged:nil];
    [self peopleNotifiedChanged:nil];
    [self messageChanged:nil];
}

- (void) forceReload
{
	[onCallListView reloadData];
    [self setButtonStates];
}

- (void) editingDidEnd:(NSNotification*)aNote
{
    [model postAGlobalNotification];
}

- (void) messageChanged:(NSNotification*)aNote
{
    [messageField setStringValue:[model message]];
    [self setButtonStates];
}

- (void) listLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:OROnCallListListLock];
    
    [listLockButton setState: locked];
    [self setButtonStates];
}

- (void) peopleNotifiedChanged:(NSNotification*)aNote
{
    [onCallListView reloadData];
}

- (void) setButtonStates
{
    BOOL locked = [gSecurity isLocked:OROnCallListListLock];
	
	[addPersonButton setEnabled:    !locked];
	[removePersonButton setEnabled: !locked];
	[saveButton setEnabled:         !locked];
	[restoreButton setEnabled:      !locked];
    
    OROnCallPerson* primary     = [model primaryPerson];
   
    NSString* name = nil;
    if(primary)name = [primary name];
    else {
        OROnCallPerson* secondary   = [model secondaryPerson];
        if(secondary)name = [secondary name];
        else {
            OROnCallPerson* tertiary    = [model tertiaryPerson];
            if(tertiary)name = [tertiary name];
        }
    }
    if(name){
        [sendMessageButton setTitle:name];
        [sendMessageButton setEnabled:[[model message]length]];
    }
    else {
        [sendMessageButton setTitle:@"--"];
        [sendMessageButton setEnabled:NO];
    }
}

- (void) personAdded:(NSNotification*)aNote
{
	[onCallListView reloadData];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:[model onCallListCount]];
	[onCallListView selectRowIndexes:indexSet byExtendingSelection:NO];
	
    [self setButtonStates];
}

- (void) personRemoved:(NSNotification*)aNote
{
	int32_t index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
    index = MIN(index,[model onCallListCount]-1);
	index = MAX(index,0);
	[onCallListView reloadData];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
	[onCallListView selectRowIndexes:indexSet byExtendingSelection:NO];
				
    [self setButtonStates];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [onCallListView selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [onCallListView selectedRow] >= 0;
    }
	[super validateMenuItem:menuItem];
	return YES;
}

#pragma mark •••Delegate Methods
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == onCallListView || aNotification == nil){
		NSInteger selectedIndex = [onCallListView selectedRow];
		[removePersonButton setEnabled:selectedIndex>=0];
	}
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item
{
    if([gSecurity isLocked:OROnCallListListLock])return NO;
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
    [gSecurity setLock:OROnCallListListLock to:secure];
    [listLockButton setEnabled:secure];
}



#pragma mark •••Actions
- (IBAction) messageAction:(id)sender
{
    [model setMessage:[messageField stringValue]];
}

- (IBAction) sendMessageAction:(id)sender
{
    [self endEditing];
    [model sendMessageToOnCallPerson];
}

- (IBAction) delete:(id)sender
{
    [self removePersonAction:nil];
}

- (IBAction) cut:(id)sender
{
    [self removePersonAction:nil];
}

- (IBAction) addPersonAction:(id)sender
{
	[model addPerson];
}

- (IBAction) removePersonAction:(id)sender
{
	NSIndexSet* theSet = [onCallListView selectedRowIndexes];
	NSUInteger current_index = [theSet firstIndex];
    if(current_index != NSNotFound){
		[model removePersonAtIndex:(int)current_index];
	}
	[self setButtonStates];
}

- (IBAction) listLockAction:(id)sender
{
    [gSecurity tryToSetLock:OROnCallListListLock to:[sender intValue] forWindow:[self window]];
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


#pragma mark Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
	if(aTableView == onCallListView){
		id aPerson = [model personAtIndex:(int)rowIndex];
		return [aPerson valueForKey:[aTableColumn identifier]];
	}
	else return nil;
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if(aTableView == onCallListView){
		id aPerson = [model personAtIndex:(int)rowIndex];
		[aPerson setValue:anObject forKey:[aTableColumn identifier]];
        if([[aTableColumn identifier] isEqualToString:kPersonRole]){
            [model personTakingNewRole:aPerson];
        }
	}
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == onCallListView){
		return [model onCallListCount];
	}
	else return 0;
}


@end

