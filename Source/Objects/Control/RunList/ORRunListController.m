//
//  ORRunListContoller.m
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
#import "ORRunListController.h"
#import "ORRunListModel.h"
#import "TimedWorker.h"
#import "ORRunModel.h"

@implementation ORRunListController
- (id) init
{
    self = [super initWithWindowNibName:@"RunList"];
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
                         name : ORRunListListLock
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(listLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : itemsListView];	
	
	[notifyCenter addObserver : self
                     selector : @selector(itemsAdded:)
                         name : ORRunListItemsAdded
                       object : model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(itemsRemoved:)
                         name : ORRunListItemsRemoved
                       object : model];		

	[notifyCenter addObserver : self
                     selector : @selector(runStateChanged:)
                         name : ORRunListRunStateChanged
                       object : model];		

    [notifyCenter addObserver : self
                     selector : @selector(updateProgressBar:)
                         name : ORRunElapsedTimesChangedNotification
						object: nil];

	[notifyCenter addObserver : self
                     selector : @selector(updateProgressBar:)
                         name : ORRunListModelWorkingItemIndexChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(forceReload)
                         name : ORRunListModelReloadTable
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(runStateChanged:)
						 name : TimedWorkerIsRunningChangedNotification
						object: [model timedWorker]];	
	
    [notifyCenter addObserver : self
                     selector : @selector(randomizeChanged:)
                         name : ORRunListModelRandomizeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lastFileChanged:)
                         name : ORRunListModelLastFileChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(timesToRepeatChanged:)
                         name : ORRunListModelTimesToRepeatChanged
						object: model];
}

- (void) updateWindow
{
    [super updateWindow];
    [self tableViewSelectionDidChange:nil];
    [self runStateChanged:nil];
	[itemsListView reloadData];
	[self runStateChanged:nil];
	[self randomizeChanged:nil];
	[self lastFileChanged:nil];
	[self timesToRepeatChanged:nil];
}

- (void) forceReload
{
	[itemsListView reloadData];
}

- (void) listLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORRunListListLock];
 
    [listLockButton setState: locked];
	[self setButtonStates];
 }

- (void) setButtonStates
{
	BOOL runInProgress = [model isRunning];
    BOOL locked = [gSecurity isLocked:ORRunListListLock];
	
	[addItemButton setEnabled:!locked];
	[removeItemButton setEnabled:!locked];
	[saveButton setEnabled:!locked && !runInProgress];
	[restoreButton setEnabled:!locked && !runInProgress];
}

- (void) itemsAdded:(NSNotification*)aNote
{
	int index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
	index = MIN(index,(int)[model itemCount]);
	index = MAX(index,0);
	[itemsListView reloadData];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
	[itemsListView selectRowIndexes:indexSet byExtendingSelection:NO];
	
    [self setButtonStates];
}

- (void) itemsRemoved:(NSNotification*)aNote
{
	int index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
	index = MIN(index,(int)[model itemCount]-1);
	index = MAX(index,0);
	[itemsListView reloadData];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
	[itemsListView selectRowIndexes:indexSet byExtendingSelection:NO];
				
    [self setButtonStates];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [itemsListView selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [itemsListView selectedRow] >= 0;
    }
	[super validateMenuItem:menuItem];
	return YES;
}

#pragma mark •••Delegate Methods
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == itemsListView || aNotification == nil){
		int selectedIndex = (int)[itemsListView selectedRow];
		[removeItemButton setEnabled:selectedIndex>=0];
	}
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item
{
    if([gSecurity isLocked:ORRunListListLock])return NO;
	else return YES;
}

#pragma mark •••Interface Management
- (void) timesToRepeatChanged:(NSNotification*)aNote
{
	[timesToRepeatField setIntValue: [model timesToRepeat]];
}

- (void) lastFileChanged:(NSNotification*)aNote
{
	[lastFileTextField setStringValue: [[model lastFile] stringByAbbreviatingWithTildeInPath]];
}

- (void) randomizeChanged:(NSNotification*)aNote
{
	[randomizeCB setIntValue: [model randomize]];
}

- (void) updateProgressBar:(NSNotification*)aNote
{
	[progressBar setDoubleValue: 100. * [model accumulatedTime]/[model totalExpectedTime]];
}

- (void) runStateChanged:(NSNotification*)aNote
{
	BOOL isRunning = [model isRunning];
	if(isRunning)[progressBar startAnimation:self];
	else [progressBar stopAnimation:self];
    
    [startButton setEnabled: !isRunning];
    [pauseButton setEnabled: isRunning];
    if([model isPaused]){
        [pauseButton setTitle:@"Resume"];
        [pausedStatusField setHidden:NO];
    }
    else {
        [pauseButton setTitle:@"Pause"];
        [pausedStatusField setHidden:YES];
    }
    [stopButton  setEnabled:  isRunning];

	if(isRunning){
		int n		= [model timesToRepeat];
		int count	= [model executionCount]+1;
		
		if(n==1)  [runCountField setStringValue:@"Sequence will run once and then stop"];
		else   { 
			if(count<=n)[runCountField setStringValue:[NSString stringWithFormat:@"Execution count %d of %d",count,n]];
			else [runCountField setStringValue:@""];
		}
	}
	else [runCountField setStringValue:@""];
				
	[self setButtonStates];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORRunListListLock to:secure];
    [listLockButton setEnabled:secure];
}

#pragma mark •••Actions

- (void) timesToRepeatAction:(id)sender
{
	[model setTimesToRepeat:[sender intValue]];	
}

- (IBAction) lastFileTextFieldAction:(id)sender
{
	[model setLastFile:[sender stringValue]];	
}

- (IBAction) randomizeAction:(id)sender
{
	[model setRandomize:[sender intValue]];	
}
- (IBAction) startRunning:(id)sender
{
	if(![model isRunning])[model startRunning];
}
- (IBAction) pauseRunning:(id)sender
{
    if([model isPaused])[model restartRunning];
    else [model pauseRunning];
}
- (IBAction) stopRunning:(id)sender
{
    if([model isRunning])[model stopRunning];
}

- (IBAction) delete:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction) cut:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction) addItemAction:(id)sender
{
	[model addItem];
}

- (IBAction) removeItemAction:(id)sender
{
	NSIndexSet* theSet = [itemsListView selectedRowIndexes];
	NSUInteger current_index = [theSet firstIndex];
    if(current_index != NSNotFound){
		[model removeItemAtIndex:current_index];
	}
	[self setButtonStates];
}

- (IBAction) listLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORRunListListLock to:[sender intValue] forWindow:[self window]];
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
	if(aTableView == itemsListView){
        if((rowIndex == 0) && [[aTableColumn identifier] isEqualToString:@"SubRun"])return nil;
        id addressObj = [model itemAtIndex:rowIndex];

		return [addressObj valueForKey:[aTableColumn identifier]]; 
	}
	else return nil;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(rowIndex == 0 && [[aTableColumn identifier] isEqualToString:@"SubRun"])[aCell setEnabled:NO];
    else [aCell setEnabled:YES];
}
- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if(aTableView == itemsListView){
        if((rowIndex == 0) && [[aTableColumn identifier] isEqualToString:@"SubRun"])return;
		id addressObj = [model itemAtIndex:rowIndex];
		[addressObj setValue:anObject forKey:[aTableColumn identifier]];
	}
}

// just returns the number of items we have.
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == itemsListView){
		return [model itemCount];
	}
	else return 0;
}
@end

