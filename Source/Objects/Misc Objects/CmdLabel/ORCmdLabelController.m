
//
//  ORCmdLabelController.m
//  Orca
//
//  Created by Mark Howe on Tuesday Apr 6,2009.
//  Copyright © 20010 University of North Carolina. All rights reserved.
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
#import "ORCmdLabelController.h"
#import "ORCmdLabelModel.h"

@implementation ORCmdLabelController

#pragma mark •••Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"CmdLabel"];
    return self;
}


#pragma mark •••Interface Management

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    
    [notifyCenter addObserver: self
                     selector: @selector(labelLockChanged:)
                         name: ORLabelLock
                       object: model];
		
	[notifyCenter addObserver : self
                     selector : @selector(commandSelectionChanged:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : commandTable];

	[notifyCenter addObserver : self
                     selector : @selector(detailsChanged:)
                         name : ORCmdLableDetailsChanged
                       object : model];
	

}

- (void) updateWindow
{
	[super updateWindow];
	[self commandSelectionChanged:nil];
    [self labelLockChanged:nil];
    [self detailsChanged:nil];
}

- (void) labelLockChanged:(NSNotification*)aNotification
{
	[super labelLockChanged:aNotification];
	
    BOOL locked = [gSecurity isLocked:ORLabelLock];
    [commandTable setEnabled: !locked];
    [objectField setEnabled: !locked];
    [loadField setEnabled: !locked];
    [setSelectorField setEnabled: !locked];
    [formatField setEnabled: !locked];
    [argField setEnabled: !locked];
	[okButton setEnabled: !locked];;
	[okAllButton setEnabled: !locked];;
	[removeButton setEnabled: !locked];;
	[addButton setEnabled: !locked];;
	
}

- (void) detailsChanged:(NSNotification*)aNote
{	
	[self fillItemCount];
	[commandTable reloadData];
}

- (void) commandSelectionChanged:(NSNotification*)aNote
{
	NSIndexSet* theSelectedSet =  [commandTable selectedRowIndexes];
	if(theSelectedSet){
		int rowIndex = (int)[theSelectedSet firstIndex];
		id obj = [model commandAtIndex:rowIndex];
		[objectField setStringValue: [obj objectForKey:@"Object"]];
		[setSelectorField setStringValue: [obj objectForKey:@"SetSelector"]];
		[formatField setStringValue: [obj objectForKey:@"DisplayFormat"]];
		[loadField setStringValue: [obj objectForKey:@"LoadSelector"]];
		[argField setStringValue: [obj objectForKey:@"Value"]];
	}
	[self fillItemCount];
}
- (void) fillItemCount
{
	NSIndexSet* theSelectedSet =  [commandTable selectedRowIndexes];
	if(theSelectedSet){
		int rowIndex = (int)[theSelectedSet firstIndex];
		[itemCountField setStringValue:[NSString stringWithFormat:@"%d of %d",rowIndex+1,(int)[model commandCount]]];
	}
	else [itemCountField setStringValue:@""];
}

#pragma mark •••Actions
- (IBAction) okAction:(id)sender
{
	[self endEditing];
	NSIndexSet* theSelectedSet =  [commandTable selectedRowIndexes];
	if(theSelectedSet){
		int rowIndex = (int)[theSelectedSet firstIndex];
		[model executeCommand:rowIndex];
	}
	[warningField setStringValue:@"Executed"];
}

- (IBAction) okAllAction:(id)sender
{
	[self endEditing];
	int n = (int)[model commandCount];
	int i;
	for(i=0;i<n;i++){
		[model executeCommand:i];
	}
	[warningField setStringValue:@"Executed"];

}

- (IBAction) checkSyntaxAction:(id)sender
{
	[self endEditing];
	NSIndexSet* theSelectedSet =  [commandTable selectedRowIndexes];
	if(theSelectedSet){
		int rowIndex = (int)[theSelectedSet firstIndex];
		if(![model checkSyntax:rowIndex]){
			[warningField setStringValue:@"Problems: see status log"];
			id cmd = [model commandAtIndex:rowIndex];
			NSLogColor([NSColor redColor],@"Command %d appears to have problems\n",rowIndex);
			if(![cmd objectForKey:@"ObjectOK"])		NSLogColor([NSColor redColor],@"Target Object <%@> not found\n",[cmd objectForKey:@"Object"]);
			if(![cmd objectForKey:@"SetSelectorOK"])NSLogColor([NSColor redColor],@"Target object doesn't have: <%@>\n",[cmd objectForKey:@"SetSelector"]);
			if(![cmd objectForKey:@"LoadSelectorOK"])NSLogColor([NSColor redColor],@"Target object doesn't have: <%@>\n",[cmd objectForKey:@"LoadSelector"]);
		}
		else {
			NSLog(@"Command %d appears OK\n",rowIndex);
			[warningField setStringValue:@"Appears OK"];
		}
	}
}

- (IBAction) labelLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORLabelLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) detailsAction:(id)sender
{
	NSIndexSet* theSelectedSet =  [commandTable selectedRowIndexes];
	if(theSelectedSet){
		
		int rowIndex = (int)[theSelectedSet firstIndex];
		id obj = [model commandAtIndex:rowIndex];
		
		NSString* s;
		
		s = [objectField stringValue];
		[obj setObject:s?s:@"" forKey:@"Object"];
		
		s = [setSelectorField stringValue];
		[obj setObject:s?s:@"" forKey:@"SetSelector"];
		
		s = [formatField stringValue];
		[obj setObject:s?s:@"" forKey:@"DisplayFormat"];

		s = [loadField stringValue];
		[obj setObject:s?s:@"" forKey:@"LoadSelector"];
		
		s = [argField stringValue];
		[obj setObject:s?s:@"" forKey:@"Value"];
		
		[model postDetailsChanged];
	}
}

- (IBAction) addCommandAction:(id)sender
{
	[model addCommand];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:[model commandCount]-1];
	[commandTable selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (IBAction) removeCommandAction:(id)sender
{
	NSIndexSet* theSelectedSet =  [commandTable selectedRowIndexes];
	if(theSelectedSet){
		int index = (int)[theSelectedSet firstIndex];
		[model removeCommand:index];
		if(index>1)index--;
		else index = (int)[model commandCount]-1;
		NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
		[commandTable selectRowIndexes:indexSet byExtendingSelection:NO];
		[model postDetailsChanged];
	}
}

#pragma mark •••DataSource
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [model commandCount];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
    id obj = [model commandAtIndex:(int)rowIndex];
    return [obj valueForKey:[aTableColumn identifier]];
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    id obj = [model commandAtIndex:(int)rowIndex];
	[obj setObject:anObject forKey:[aTableColumn identifier]];
	[self commandSelectionChanged:nil];
	[model postDetailsChanged];
}


@end
