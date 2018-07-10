//----------------------------------------------------------
//  ORWindowSaveSet.h
//
//  Created by Mark Howe on Thurs Mar 20, 2008.
//  Copyright  © 2008 CENPA. All rights reserved.
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
#import "ORWindowSaveSet.h"
#import "ORAlarmController.h"
#import "ORStatusController.h"
#import "ORTimedTextField.h"

@implementation ORWindowSaveSet

#pragma mark ***Accessors
- (id)init
{
    if(self = [super initWithWindowNibName:@"WindowSaveSet"]){
		[self setShouldCloseDocument:NO];
	}
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[saveSetNames release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[newSetNameField setStringValue:[self suggestName]];
	NSString* theSaveSetName = [[NSUserDefaults standardUserDefaults] objectForKey:@"CmdOneWindowSaveSet"]; 
	if([theSaveSetName length])[cmdOneSetField setStringValue:theSaveSetName];
	else [cmdOneSetField setStringValue:@""];

	[self registerNotificationObservers];
	[self tableSelectionDidChange:nil];
	[savedSetsTableView setDoubleAction:@selector(restoreWindowSet:)];
}

//this method is needed so the global menu commands will be passes on correctly.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[NSApp delegate]  undoManager];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter removeObserver:self];
	
    [notifyCenter addObserver : self
                     selector : @selector(tableSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : savedSetsTableView];
}	

- (void) tableSelectionDidChange:(NSNotification *)notification
{
	NSIndexSet* selection = [savedSetsTableView selectedRowIndexes];
	[restoreButton setEnabled:[selection count]];
	[cmdOneSaveButton setEnabled:[selection count]];
}

- (id) document
{
	return [[NSApp delegate] document];
}

#pragma mark •••Actions
- (IBAction) showWindowSaveSet:(id)sender
{
    [[self window] makeKeyAndOrderFront:nil];
}

- (IBAction) saveWindowSet:(id)sender
{
	NSString* theSaveSetName = [newSetNameField stringValue];
	if([theSaveSetName length]){
		NSString* tempFolder = [[ApplicationSupport sharedApplicationSupport] applicationSupportFolder:@"WindowSets"];
		NSArray* theOpenControllers = [[self document] orcaControllers];
		NSMutableArray* windowInfoArray = [NSMutableArray array];
		NSDictionary* info;
		for(id aController in theOpenControllers){
			info = [NSDictionary dictionaryWithObjectsAndKeys:
					[[aController model] fullID],@"model",
					[[aController window] stringWithSavedFrame],@"frame",
					nil];
			[windowInfoArray addObject:info];
		}
		
		NSWindow* theWindow;
		theWindow = [[[[self document] windowControllers] objectAtIndex:0]window];
		info = [NSDictionary dictionaryWithObjectsAndKeys:@"MainWindow",@"model",[theWindow stringWithSavedFrame],@"frame",nil];
		[windowInfoArray addObject:info];
		
		theWindow = [[ORStatusController sharedStatusController] window];
		info = [NSDictionary dictionaryWithObjectsAndKeys:@"StatusLog",@"model",[theWindow stringWithSavedFrame],@"frame",nil];
		[windowInfoArray addObject:info];
		
		theWindow = [[ORAlarmController sharedAlarmController] window];
		info = [NSDictionary dictionaryWithObjectsAndKeys:@"Alarms",@"model",[theWindow stringWithSavedFrame],@"frame",[NSNumber numberWithBool:[theWindow isVisible]],@"visible", nil];
		[windowInfoArray addObject:info];	
	
		NSString* windowSetFile = [tempFolder stringByAppendingPathComponent:theSaveSetName];
		NSFileManager* fm = [NSFileManager defaultManager]; 
		if([fm fileExistsAtPath:windowSetFile])[fm removeItemAtPath:windowSetFile error:nil];
		[windowInfoArray writeToFile:windowSetFile atomically:NO];
		[savedSetsTableView reloadData];
	}
	else {
		[messageField setStringValue:@"Window Save Set Name must be provided"];
		NSLog(@"Window Save Set Name must be provided\n");
		[newSetNameField setStringValue:[self suggestName]];
	}
}

- (IBAction) setCmdOneSet:(id)sender
{
	NSIndexSet* selection = [savedSetsTableView selectedRowIndexes];
	int row = [selection firstIndex];
	if(row>=0 && row < [saveSetNames count]) {
		NSString* theSaveSetName = [[saveSetNames objectAtIndex:row] objectForKey:@"Name"];
		if([theSaveSetName length]){
			[[NSUserDefaults standardUserDefaults] setObject:theSaveSetName forKey:@"CmdOneWindowSaveSet"]; 
			[cmdOneSetField setStringValue:theSaveSetName];		
		}
		else {
			[messageField setStringValue:@"Empty ⌘-1 Set Name"];
			NSLog(@"Empty ⌘-1 Set Name\n");
		}
	}
	else {
		[messageField setStringValue:@"Nothing Selected"];
	}
}

- (IBAction) restoreToCmdOneSet:(id)sender
{
	NSString* theSaveSetName = [[NSUserDefaults standardUserDefaults] objectForKey:@"CmdOneWindowSaveSet"]; 
	[self restoreSaveSetWithName:theSaveSetName];
}

- (IBAction) restoreWindowSet:(id)sender
{
	NSIndexSet* selection = [savedSetsTableView selectedRowIndexes];
	int row = [selection firstIndex];
	if(row>=0 && row < [saveSetNames count]) {                      
		NSString* theSaveSetName = [[saveSetNames objectAtIndex:row] objectForKey:@"Name"];
		[self restoreSaveSetWithName:theSaveSetName];
		[[self window] orderFront:self];
	}
}

- (void) restoreSaveSetWithName:(NSString*) theSaveSetName
{
	if([theSaveSetName length]){
		[[self document] closeAllWindows];
		
		NSString* tempFolder = [[ApplicationSupport sharedApplicationSupport] applicationSupportFolder:@"WindowSets"];
		
		NSString* windowSetFile = [tempFolder stringByAppendingPathComponent:theSaveSetName];
		NSArray* aWindowInfoArray = [NSArray arrayWithContentsOfFile:windowSetFile];
		
		//temp force non-sharing of dialogs
		BOOL shareDialogsState = [[[NSUserDefaults standardUserDefaults] objectForKey: OROpeningDialogPreferences] intValue];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:OROpeningDialogPreferences]; 
		@try {
			for(id aDictionary in aWindowInfoArray){
				NSString* theID = [aDictionary objectForKey:@"model"];
				NSString* theFrame = [aDictionary objectForKey:@"frame"];
				//the special cases
				if([theID isEqual:@"MainWindow"]){
					NSWindow* theWindow = [[[[self document] windowControllers] objectAtIndex:0] window];
					[theWindow setFrameFromString:theFrame];
					[theWindow orderFront:self];
				}
				else if([theID isEqual:@"StatusLog"]){
					NSWindow* theWindow = [[ORStatusController sharedStatusController] window];
					[theWindow setFrameFromString:theFrame];
					[theWindow orderFront:self];
				}
				else if([theID isEqual:@"Alarms"]){
					NSWindow* theWindow = [[ORAlarmController sharedAlarmController] window];
					[theWindow setFrameFromString:theFrame];
					BOOL wasVisible = [[aDictionary objectForKey:@"visible"] boolValue];
					if(wasVisible)[theWindow orderFront:self];
				}
				else {
					//the object windows
					id theModel = [[self document] findObjectWithFullID:theID];
					if([theModel isKindOfClass:NSClassFromString(@"OrcaObject")]){
						[theModel makeMainController];
						NSArray* objControllers = [[self document] findControllersWithModel:theModel];
						if([objControllers count]){
							id theController = [objControllers objectAtIndex:0];
							[[theController window] setFrameFromString:theFrame];
							[[theController window] orderFront:self];
						}
					}
				}
			}
		}
		@catch (NSException* localException) {
		}
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:shareDialogsState] forKey:OROpeningDialogPreferences]; 		
	}
}

- (IBAction) cancel:(id)sender
{
	[[self window] close];
}

#pragma mark •••Table Data Source
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	return YES;
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	id item =  [[saveSetNames objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
	if(item)return item;
	else return @"";
}

// just returns the number of items we have.
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	[self loadFileNames];
	return [saveSetNames count];
}

- (void) loadFileNames
{
	[saveSetNames release];
	saveSetNames = [[NSMutableArray array] retain];
	NSString* tempFolder = [[ApplicationSupport sharedApplicationSupport] applicationSupportFolder:@"WindowSets"];

    NSFileManager* fm = [NSFileManager defaultManager];
	NSDirectoryEnumerator* e = [fm enumeratorAtPath:tempFolder];
	NSString *file;
	while (file = [e nextObject]) {
		if(![file hasPrefix:@"."]){
			NSDictionary* attributes = [fm attributesOfItemAtPath:[tempFolder stringByAppendingPathComponent:file] error:nil];
			id modDate = [attributes objectForKey:NSFileModificationDate];
			NSDictionary* item = [NSDictionary dictionaryWithObjectsAndKeys:file,@"Name",modDate,@"Date",nil];
			[saveSetNames addObject:item];
		}
	}
}

- (NSString*) suggestName 
{
	NSString* rootName = @"windowPositions";
	[self loadFileNames];
	int index = 0;
	NSString* suggestedName = [rootName stringByAppendingFormat:@"_%d",++index];
	while(1){
		BOOL allReadyUsed = NO;
		for(id item in saveSetNames){
			if([suggestedName isEqualToString:[item objectForKey:@"Name"]]){
				allReadyUsed = YES;
				suggestedName = [rootName stringByAppendingFormat:@"_%d",++index];
				break;
			}
		}
		if(!allReadyUsed)return suggestedName;
	}
}


@end
