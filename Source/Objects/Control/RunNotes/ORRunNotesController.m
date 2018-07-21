//
//  ORRunNotesContoller.m
//  Orca
//
//  Created by Mark Howe on Tues Feb 09 2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORRunNotesController.h"
#import "ORRunNotesModel.h"

@implementation ORRunNotesController
- (id) init
{
    self = [super initWithWindowNibName:@"RunNotes"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
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
                         name : ORRunNotesListLock
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(listLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(commentsChanged:)
                         name : ORRunNotesCommentsChanged
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(textDidChange:)
                         name : NSTextDidChangeNotification
						object: commentsView];
	
    [notifyCenter addObserver : self
                     selector : @selector(ignoreValuesChanged:)
                         name : ORRunNotesModelIgnoreValuesChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(doNotOpenChanged:)
                         name : ORRunNotesModelDoNotOpenChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(modalChanged:)
                         name : ORRunNotesModelModalChanged
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : notesListView];	
	
	[notifyCenter addObserver : self
                     selector : @selector(itemsAdded:)
                         name : ORRunNotesItemsAdded
                       object : model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(itemsRemoved:)
                         name : ORRunNotesItemsRemoved
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(itemsRemoved:)
                         name : ORRunNotesItemChanged
                       object : model];    
	
    [notifyCenter addObserver : self
                     selector : @selector(definitionsFilePathChanged:)
                         name : ORRunNotesModelDefinitionsFilePathChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
	[self commentsChanged:nil];
	[self ignoreValuesChanged:nil];
	[self doNotOpenChanged:nil];
    [self tableViewSelectionDidChange:nil];
	[notesListView reloadData];
	[self definitionsFilePathChanged:nil];
}

- (void) itemChanged:(NSNotification*)aNote
{
    [notesListView reloadData];

}

- (void) modalChanged:(NSNotification*)aNote
{
	[NSApp stopModalWithCode:1];
	if(![model isModal]){
		[[self window] close];
	}
	else {
		[self listLockChanged:nil];
	}
}

- (void) listLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORRunNotesListLock];
 
    [listLockButton setState: locked];
	[self setButtonStates];
 }

- (void) textDidChange:(NSNotification*)aNote
{
	if([aNote object] == commentsView) [model setCommentsNoNote:[commentsView string]];
}

- (void) setButtonStates
{
	BOOL modal = [model isModal];
	BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:ORRunNotesListLock];
	
	[continueRunButton setEnabled:!runInProgress && modal];
	[cancelRunButton setEnabled:!runInProgress && modal];
	[addItemButton setEnabled:!locked];
	[removeItemButton setEnabled:!locked];
	[readDefFileButton setEnabled:!locked];
}

- (void) itemsAdded:(NSNotification*)aNote
{
	int index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
	index = MIN(index,(int)[model itemCount]);
	index = MAX(index,0);
	[notesListView reloadData];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
	[notesListView selectRowIndexes:indexSet byExtendingSelection:NO];
	
    [self setButtonStates];
}

- (void) itemsRemoved:(NSNotification*)aNote
{
	int index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
	index = MIN(index,(int)[model itemCount]-1);
	index = MAX(index,0);
	[notesListView reloadData];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
	[notesListView selectRowIndexes:indexSet byExtendingSelection:NO];
				
    [self setButtonStates];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [notesListView selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [notesListView selectedRow] >= 0;
    }
	[super validateMenuItem:menuItem];
	return YES;
}

#pragma mark •••Delegate Methods
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == notesListView || aNotification == nil){
		int selectedIndex = (int)[notesListView selectedRow];
		[removeItemButton setEnabled:selectedIndex>=0];
	}
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item
{
    if([gSecurity isLocked:ORRunNotesListLock])return NO;
	else return YES;
}

- (BOOL) windowShouldClose:(NSNotification *)aNote
{
	return ![model isModal];
}

#pragma mark •••Interface Management

- (void) definitionsFilePathChanged:(NSNotification*)aNote
{
	[definitionsFilePathField setStringValue: [[model definitionsFilePath] stringByAbbreviatingWithTildeInPath]];
}

- (void) doNotOpenChanged:(NSNotification*)aNote
{
	[doNotOpenButton setIntValue: [model doNotOpen]];
	[self checkNotice];
}

- (void) ignoreValuesChanged:(NSNotification*)aNote
{
	[ignoreValuesButton setIntValue: [model ignoreValues]];
	[self checkNotice];
}

- (void) checkNotice
{
	if(![model ignoreValues] && ![model doNotOpen]){
        [ignoreNoticeView selectTabViewItemAtIndex:1];
    }
    else {
        [ignoreNoticeView selectTabViewItemAtIndex:0];
    }
	
}


- (void) commentsChanged:(NSNotification*)aNote
{
	[commentsView setString: [model comments]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORRunNotesListLock to:secure];
    [listLockButton setEnabled:secure];
}
#pragma mark •••Actions
- (IBAction) doNotOpenAction:(id)sender
{
	[model setDoNotOpen:[sender intValue]];	
}

- (IBAction) ignoreValuesAction:(id)sender
{
	[model setIgnoreValues:[sender intValue]];	
}

- (IBAction)delete:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction) cut:(id)sender
{
    [self removeItemAction:nil];
}


- (IBAction) removeItemAction:(id)sender
{
	NSIndexSet* theSet = [notesListView selectedRowIndexes];
	NSUInteger current_index = [theSet firstIndex];
    if(current_index != NSNotFound){
		[model removeItemAtIndex:current_index];
	}
	[self setButtonStates];
}

- (IBAction) listLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORRunNotesListLock to:[sender intValue] forWindow:[self window]];
	[self setButtonStates];
}

- (IBAction) cancelRun:(id)sender
{
	[model cancelRun];
}

- (IBAction) continueWithRun:(id)sender
{
	[model continueWithRun];
}

- (IBAction) openAddItemPanel:(id)sender
{
	[self endEditing];
    [addItemValueField setObjectValue:@""];
    [addItemNameField setObjectValue:@""];
    [[self window] beginSheet:addItemPanel completionHandler:nil];
}

- (IBAction) closeAddItemPanel:(id)sender
{
    [addItemPanel orderOut:nil];
    [NSApp endSheet:addItemPanel];
}

- (IBAction) doAddItemAction:(id)sender
{
    [self endAllEditing:nil];
    [model addObject:[addItemValueField stringValue] forKey:[addItemNameField stringValue]];
    [addItemPanel orderOut:nil];
    [NSApp endSheet:addItemPanel];
    [notesListView reloadData];
}

- (IBAction) definitionsFileAction:(id)sender
{
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model definitionsFilePath]){
        startDir = [[model definitionsFilePath]stringByDeletingLastPathComponent];
        if([startDir length] == 0)startDir = NSHomeDirectory();
    }
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setDefinitionsFilePath:[[openPanel URL]path]];
            if(![model readNamesFromFile]){
                NSLogColor([NSColor redColor],@"Unable to parse <%@> as a run notes def file.\n",[[[[openPanel URLs] objectAtIndex:0]path] stringByAbbreviatingWithTildeInPath]);
                NSLogColor([NSColor redColor],@"File must be list of items of the form: label,value\n");
                [model setDefinitionsFilePath:nil];
            }
            else {
                [self definitionsFilePathChanged:nil];
                [notesListView reloadData];
            }
        }
    }];
}

#pragma mark Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) aRowIndex
{
    int rowIndex = (int)aRowIndex;
	if(aTableView == notesListView){
		id anItem = [model itemAtIndex:rowIndex];
        NSArray* allKeys = [anItem allKeys];
        if([allKeys count] == 1){
            if([[aTableColumn identifier] isEqualToString:@"Label"]){
                return [allKeys objectAtIndex:0];
            }
            else if([[aTableColumn identifier] isEqualToString:@"Value"]){
                return [anItem objectForKey:[allKeys objectAtIndex:0]];
            }
        }
    }
    return nil;
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)aRowIndex
{
    int rowIndex = (int)aRowIndex;
	if(aTableView == notesListView){
		id anItem = [model itemAtIndex:rowIndex];
        NSArray* allKeys = [anItem allKeys];
        if([allKeys count] == 1){
            [anItem setValue:anObject forKey:[allKeys objectAtIndex:0]];
        }
	}
}

// just returns the number of items we have.
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == notesListView){
		return [model itemCount];
	}
	else return 0;
}
@end
