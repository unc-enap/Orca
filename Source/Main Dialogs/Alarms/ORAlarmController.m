//
//  ORAlarmController.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 17 2003.
//  Copyright © 2003 CENPA, University of Washington. All rights reserved.
//
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
#import "ORAlarmController.h"
#import "SynthesizeSingleton.h"

@implementation ORAlarmController

#pragma mark •••Inialization

SYNTHESIZE_SINGLETON_FOR_ORCLASS(AlarmController);

-(id)init
{
    self = [super initWithWindowNibName:@"AlarmWindow"];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
    
    if([[self alarmCollection] alarmCount]){
        [[self window] orderFront:self];
    }
    [self tableViewSelectionDidChange:nil];

	[addressList reloadData];
	[self eMailEnabledChanged:nil];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[(ORAppDelegate*)[NSApp delegate]document]  undoManager];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(alarmsChanged:)
                         name : ORAlarmWasPostedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmsChanged:)
                         name : ORAlarmWasClearedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(alarmsChanged:)
                         name : ORAlarmWasChangedNotification
                       object : nil];
  
    [notifyCenter addObserver : self
                     selector : @selector(severitySelectionChanged:)
                         name : ORAlarmSeveritySelectionChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(addressChanged:)
                         name : ORAlarmAddressChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(documentLoaded:)
                         name : ORDocumentLoadedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(eMailEnabledChanged:)
                         name : ORAlarmCollectionEmailEnabledChanged
                       object : [self alarmCollection]];

	[notifyCenter addObserver : self
                     selector : @selector(addressAdded:)
                         name : ORAlarmCollectionAddressAdded
                       object : [self alarmCollection]];	
	
    [notifyCenter addObserver : self
                     selector : @selector(addressRemoved:)
                         name : ORAlarmCollectionAddressRemoved
                       object : [self alarmCollection]];
    
    [notifyCenter addObserver : self
                     selector : @selector(reloadAddressList:)
                         name : ORAlarmCollectionReloadAddressList
                       object : [self alarmCollection]];
    
    [notifyCenter addObserver: self
                     selector: @selector(editingDidEnd:)
                         name: NSControlTextDidEndEditingNotification
                       object: addressList];
}


#pragma mark •••Accessors
- (NSButton*) acknowledgeButton
{
    return acknowledgeButton;
}

- (NSButton*) helpButton
{
    return helpButton;
}

- (ORAlarmCollection*) alarmCollection
{
    return [(ORAppDelegate*)[NSApp delegate] alarmCollection];
}

#pragma mark •••Delegate Methods
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == tableView || aNotification == nil){
		int selectedIndex = (int)[tableView selectedRow];
		if(selectedIndex>=0){
			[self setUpHelpText];
			//[helpDrawer open];
			[helpButton setEnabled:YES];
			[acknowledgeButton setEnabled:YES];
		}
		else {
			[helpDrawer close];
			[helpButton setEnabled:NO];
			[acknowledgeButton setEnabled:NO];
		}
	}
	if([aNotification object] == addressList || aNotification == nil){
		int selectedIndex = (int)[addressList selectedRow];
		[removeAddressButton setEnabled:selectedIndex>=0];
		if(selectedIndex>=0){
			[addressField setEnabled:YES];
			[severityMatrix setEnabled:YES];
			
			id addressObj = [[self alarmCollection] addressAtIndex:selectedIndex];
			[addressField setStringValue:[addressObj mailAddress]];
			
			int i;
			uint32_t aMask = [addressObj severityMask];
			for(i=0;i<kNumAlarmSeverityTypes;i++){
				[[severityMatrix cellWithTag:i] setState:(aMask & (0x1L<<i))!=0];
			}

		}
		else {
			[addressField setStringValue:@""];
			int i;
			for(i=0;i<kNumAlarmSeverityTypes;i++){
				[[severityMatrix cellWithTag:i] setState:NSOffState];
			}
			[addressField setEnabled:NO];
			[severityMatrix setEnabled:NO];
		}
	}
}

- (void) editingDidEnd:(NSNotification*)aNote
{
    [[ORAlarmCollection sharedAlarmCollection] postAGlobalNotification];
}

- (void)drawerWillOpen:(NSNotification *)notification
{
    [self setUpHelpText];
}

- (void) setUpHelpText
{
    if([tableView numberOfSelectedRows] == 1){
        int selectedIndex = (int)[tableView selectedRow];
        ORAlarm* selectedAlarm = [[self alarmCollection] objectAtIndex:selectedIndex];
        [helpTextView setString:[selectedAlarm helpString]];
    }
    else {
        [helpTextView setString:@"\n -Select one alarm for more info.\n -Acknowledge an alarm to silence or remove it (Depends on the alarm)."];
    }
}

#pragma mark •••Actions

- (IBAction) acknowledge:(id)sender
{
    if([tableView numberOfSelectedRows]>0){
        //tricky--acknowledging an alarm may remove it from the collection of
        //alarms, so we have to collect the selected ones, then acknowledge them
        //from that array.
        NSMutableArray* theSelectedAlarms = [NSMutableArray array];
        NSIndexSet* selectedSet = [tableView selectedRowIndexes];
		NSUInteger current_index = [selectedSet firstIndex];
		while (current_index != NSNotFound){
            [theSelectedAlarms addObject:[[self alarmCollection]objectAtIndex:current_index]];
			current_index = [selectedSet indexGreaterThanIndex: current_index];
		}
		
        
        NSEnumerator* e = [theSelectedAlarms objectEnumerator];
        ORAlarm* anAlarm;
        while(anAlarm = [e nextObject]){
            [anAlarm acknowledge];
        }
        
        [tableView reloadData];
    }
}

- (IBAction) saveDocument:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocumentAs:sender];
}

- (IBAction)delete:(id)sender
{
    [self removeAddress:nil];
}

- (IBAction) cut:(id)sender
{
    [self removeAddress:nil];
}

- (IBAction) addAddress:(id)sender
{
	[[self alarmCollection] addAddress];
}

- (IBAction) removeAddress:(id)sender
{
	//only one can be selected at a time. If that restriction is lifted then the following will have to be changed
	//to something a lot more complicated.
	NSIndexSet* theSet = [addressList selectedRowIndexes];
	int current_index = (int)[theSet firstIndex];
    if(current_index != NSNotFound){
		[[self alarmCollection] removeAddressAtIndex:current_index];
	}
}

- (IBAction) severityAction:(id)sender
{
	int selectedIndex = (int)[addressList selectedRow];
	if(selectedIndex>=0) {
		id addressObj = [[self alarmCollection] addressAtIndex:selectedIndex];
		int i;
		uint32_t aMask = 0L;
		for(i=0;i<kNumAlarmSeverityTypes;i++){
			if([[severityMatrix cellWithTag:i] state] == NSOnState){
				aMask |= (0x1L<<i);
			}
		}
		[addressObj setSeverityMask:aMask];
        [[ORAlarmCollection sharedAlarmCollection] postAGlobalNotification];
	}
}

- (IBAction) addressAction:(id)sender
{
	int selectedIndex = (int)[addressList selectedRow];
	if(selectedIndex>=0) {
		id addressObj = [[self alarmCollection] addressAtIndex:selectedIndex];
		[addressObj setMailAddress:[sender stringValue]];
		[addressList reloadData];
	}
}

- (IBAction) eMailEnabledAction:(id)sender;
{
	[[self alarmCollection] setEmailEnabled:[sender state]];
}

#pragma mark •••Notifications
- (void) alarmsChanged:(NSNotification*)aNotification
{
    if(![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(alarmsChanged:) withObject:aNotification waitUntilDone:NO];
    }
    [tableView reloadData];
    if([helpDrawer state]){
        [self setUpHelpText];
    }
}

- (void) severitySelectionChanged:(NSNotification*)aNotification
{
	int selectedIndex = (int)[addressList selectedRow];
	if(selectedIndex>=0) {
		id addressObj = [[self alarmCollection] addressAtIndex:selectedIndex];
		if([aNotification object] == addressObj){
			int i;
			uint32_t aMask = [addressObj severityMask];
			for(i=0;i<kNumAlarmSeverityTypes;i++){
				[[severityMatrix cellWithTag:i] setState:(aMask & (0x1L<<i))!=0];
			}
		}
	}
}

- (void) reloadAddressList:(NSNotification*)aNote
{
    [addressList reloadData];
    
}
- (void) addressAdded:(NSNotification*)aNote
{
	NSInteger index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
	index = MIN(index,[[self alarmCollection] eMailCount]);
	index = MAX(index,0);
	[addressList reloadData];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
	[addressList selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (void) addressRemoved:(NSNotification*)aNote
{
	NSInteger index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
	index = MIN(index,[[self alarmCollection] eMailCount]-1);
	index = MAX(index,0);
	[addressList reloadData];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
	[addressList selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (void) addressChanged:(NSNotification*)aNotification
{
	int selectedIndex = (int)[addressList selectedRow];
	if(selectedIndex>=0) {
		id addressObj = [[self alarmCollection] addressAtIndex:selectedIndex];
		if([aNotification object] == addressObj){
			[addressField setStringValue:[addressObj mailAddress]];
			[addressList reloadData];
		}
	}
}

- (void) eMailEnabledChanged:(NSNotification*)aNotification
{
	[eMailEnabledButton setState:[[self alarmCollection] emailEnabled]];
}

- (void) documentLoaded:(NSNotification*)aNotification
{
	[addressList reloadData];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [addressList selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [addressList selectedRow] >= 0;
    }
	return YES;
}

#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if(aTableView == tableView){
		ORAlarm* anAlarm = [[self alarmCollection] objectAtIndex:rowIndex];
		return [anAlarm valueForKey:[aTableColumn identifier]];
	}
	else if(aTableView == addressList){
		id addressObj = [[self alarmCollection] addressAtIndex:rowIndex];
		return [addressObj valueForKey:[aTableColumn identifier]]; 
	}
	else return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(aTableView == addressList){
		id addressObj = [[self alarmCollection] addressAtIndex:rowIndex];
		[addressObj setValue:anObject forKey:[aTableColumn identifier]];
	}
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == tableView){
		return [[self alarmCollection] alarmCount];
	}
	else {
		return [[self alarmCollection] eMailCount];
	}
}
@end
