//
//  SubviewTableViewController.m
//  SubviewTableViewRuleEditor
//
//  Created by Mark Howe on Tue Dec 02 2003.
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


#import "SubviewTableViewController.h"

#import "SubviewTableViewCell.h"

@implementation SubviewTableViewController

- (id) initWithViewColumn:(NSTableColumn *) vCol
{
    if ((self = [super init]) != nil){
        // Weak references
        subviewTableColumn = vCol;
        subviewTableView = [subviewTableColumn tableView];
        
        // Setup table view delegate and data source
        [subviewTableView setDataSource: self];
        [subviewTableView setDelegate: self];
        
        // Setup cell type for views column
        [subviewTableColumn setDataCell: [[[SubviewTableViewCell alloc] init] autorelease]];
        
        // Setup column properties
        [subviewTableColumn setEditable: NO];
    }
    
    return self;
}

- (void) dealloc
{
    subviewTableView = nil;
    subviewTableColumn = nil;
    delegate = nil;
    
    [super dealloc];
}

+ (id) controllerWithViewColumn:(NSTableColumn *) vCol
{
    return [[[self alloc] initWithViewColumn: vCol] autorelease];
}

- (void) setDelegate:(id) obj
{
    // Check that the object passed to this method supports the required methods
    NSParameterAssert([obj conformsToProtocol: @protocol(SubviewTableViewControllerDataSourceProtocol)]);
    
    // Weak reference
    delegate = obj;
}

- (id) delegate
{
    return delegate;
}

- (void) reloadTableView
{
    while ([[subviewTableView subviews] count] > 0){
	[[[subviewTableView subviews] lastObject] removeFromSuperviewWithoutNeedingDisplay];
    }
        
    [subviewTableView reloadData];
}

- (BOOL) isValidDelegateForSelector:(SEL) command
{
    return (([self delegate] != nil) && [[self delegate] respondsToSelector: command]);
}

// Methods from NSTableViewDelegate category

- (BOOL) selectionShouldChangeInTableView:(NSTableView *) tableView
{
    if ([self isValidDelegateForSelector: _cmd]){
	return [[self delegate] selectionShouldChangeInTableView: tableView];
    }
    else {
	return YES;
    }
}

- (void) tableView:(NSTableView *) tableView didClickTableColumn:(NSTableColumn *) tableColumn
{
    if ([self isValidDelegateForSelector: _cmd]){
	[[self delegate] performSelector: _cmd withObject: tableView withObject: tableColumn];
    }
}

- (void) tableView:(NSTableView *) tableView didDragTableColumn:(NSTableColumn *) tableColumn
{
    if ([self isValidDelegateForSelector: _cmd]){
	[[self delegate] performSelector: _cmd withObject: tableView withObject: tableColumn];
    }
}

- (void) tableView:(NSTableView *) tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *) tableColumn
{
    if ([self isValidDelegateForSelector: _cmd]){
	[[self delegate] performSelector: _cmd withObject: tableView withObject: tableColumn];
    }
}

- (BOOL) tableView:(NSTableView *) tableView shouldEditTableColumn:(NSTableColumn *) tableColumn row:(int) row
{
    if ([self isValidDelegateForSelector: _cmd]){
	return [[self delegate] tableView: tableView shouldEditTableColumn: tableColumn row: row];
    }
    else{
	return YES;
    }
}

- (BOOL) tableView:(NSTableView *) tableView shouldSelectRow:(int) row
{
    if ([self isValidDelegateForSelector: _cmd]){
	return [[self delegate] tableView: tableView shouldSelectRow: row];
    }
    else{
	return YES;
    }
}

- (BOOL) tableView:(NSTableView *) tableView shouldSelectTableColumn:(NSTableColumn *) tableColumn
{
    if ([self isValidDelegateForSelector: _cmd]){
	return [[self delegate] tableView: tableView shouldSelectTableColumn: tableColumn];
    }
    else{
	return YES;
    }
}

- (void) tableView:(NSTableView *) tableView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tableColumn row:(int) row
{
    if (tableColumn == subviewTableColumn){
        // This is one of the few interesting things going on in this class. This is where
        // our custom cell class is assigned the custom view that should be displayed for
        // a particular row.
        
        if ([self isValidDelegateForSelector: @selector(tableView:viewForRow:)]){
	    [(SubviewTableViewCell *)cell addSubview: [[self delegate] tableView: tableView viewForRow: row]];
	}
    }
    else{
        if ([self isValidDelegateForSelector: _cmd]){
	    [[self delegate] tableView: tableView willDisplayCell: cell forTableColumn: tableColumn row: row];
	}
    }
}

- (void) tableViewColumnDidMove:(NSNotification *) notification
{
    if ([self isValidDelegateForSelector: _cmd]){
	[[self delegate] performSelector: _cmd withObject: notification];
    }
}

- (void) tableViewColumnDidResize:(NSNotification *) notification
{
    if ([self isValidDelegateForSelector: _cmd]){
	[[self delegate] performSelector: _cmd withObject: notification];
    }
}

- (void) tableViewSelectionDidChange:(NSNotification *) notification
{
    if ([self isValidDelegateForSelector: _cmd]){
	[[self delegate] performSelector: _cmd withObject: notification];
    }
}

- (void) tableViewSelectionIsChanging:(NSNotification *) notification
{
    if ([self isValidDelegateForSelector: _cmd]){
	[[self delegate] performSelector: _cmd withObject: notification];
    }
}

// Methods from NSTableDataSource protocol

- (int) numberOfRowsInTableView:(NSTableView *) tableView
{
    int count = 0;
    
    if ([self isValidDelegateForSelector: _cmd]){
	count = [[self delegate] numberOfRowsInTableView: tableView];
    }

    return count;
}

- (BOOL) tableView:(NSTableView *) tableView acceptDrop:(id <NSDraggingInfo>) info row:(int) row dropOperation:(NSTableViewDropOperation) operation
{
    if ([self isValidDelegateForSelector: _cmd]){
	return [[self delegate] tableView: tableView acceptDrop: info row: row dropOperation: operation];
    }
    else{
	return NO;
    }
}

- (id) tableView:(NSTableView *) tableView objectValueForTableColumn:(NSTableColumn *) tableColumn row:(int) row
{
    id obj = nil;

    if ((tableColumn != subviewTableColumn) && [self isValidDelegateForSelector: _cmd]){
	obj = [[self delegate] tableView: tableView objectValueForTableColumn: tableColumn row: row];
    }

    return obj;
}

- (void) tableView:(NSTableView *) tableView setObjectValue:(id) obj forTableColumn:(NSTableColumn *) tableColumn row:(int) row
{
    if ((tableColumn != subviewTableColumn) && [self isValidDelegateForSelector: _cmd]){
	[[self delegate] tableView: tableView objectValueForTableColumn: tableColumn row: row];
    }
}

- (NSDragOperation) tableView:(NSTableView *) tableView validateDrop:(id <NSDraggingInfo>) info proposedRow:(int) row proposedDropOperation:(NSTableViewDropOperation) operation
{
    if ([self isValidDelegateForSelector: _cmd]){
	return [[self delegate] tableView: tableView validateDrop: info proposedRow: row proposedDropOperation: operation];
    }
    else {
	return NO;
    }
}

- (BOOL) tableView:(NSTableView *) tableView writeRows:(NSArray *) rows toPasteboard:(NSPasteboard *) pboard
{
    if ([self isValidDelegateForSelector: _cmd]){
	return [[self delegate] tableView: tableView writeRows: rows toPasteboard: pboard];
    }
    else {
	return NO;
    }
}

@end
