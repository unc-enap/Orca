//
//  SubviewTableViewController.h
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


/*****************************************************************************

SubviewTableViewController

Files:

* SubviewTableViewController.h
* SubviewTableViewCell.h

Overview:

The SubviewTableViewController (STVC) is used to create a table view like the
one used in the rules preference pane in Mail, or the new find panel in Finder.
It allows you to provide views that will be displayed instead of (really: on
top of) the usual cells in the table view.

Usage guidelines:

The table view used to hold the contents is a standard NSTableView. The table 
view needs to have a table column dedicated for the subviews. The table view 
also preferably needs to have a row height matching the height of the subviews. 
The owner of the table view should instantiate a STVC using the convenience 
method, and providing this column:

- (void) awakeFromNib
{
    tableViewController = 
    [[SubviewTableViewController controllerWithViewColumn: subviewTableColumn] 
        retain];
    [tableViewController setDelegate: self];
}

The STVC will make itself the delegate and data source of the table view, 
and will forward all data source and delegate methods to the original owner.



*****************************************************************************/
@interface SubviewTableViewController : NSObject <NSTableViewDataSource,NSTableViewDelegate>
{
    @private
    
    NSTableView *subviewTableView;
    NSTableColumn *subviewTableColumn;
    
    id delegate;
}

// Convenience factory method
+ (id) controllerWithViewColumn:(NSTableColumn *) vCol;

// The delegate is required to conform to the SubviewTableViewControllerDataSourceProtocol
- (void) setDelegate:(id) obj;
- (id) delegate;

- (void) reloadTableView;

@end

@protocol SubviewTableViewControllerDataSourceProtocol

// The view retreived will not be retained, and will be resized to fit the
// cell in the table view. Please adjust the row height and column width in
// ib (or in code) to make sure that it is appropriate for the views used.
- (NSView *) tableView:(NSTableView *) tableView viewForRow:(NSUInteger) row;

@end
