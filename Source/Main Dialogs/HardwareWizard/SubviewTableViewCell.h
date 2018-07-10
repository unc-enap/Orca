//
//  SubviewTableViewCell.h
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

SubviewTableViewCell

Overview:

This is a very simple cell subclass used as the table data cell in the column
where the custom view will be used. It is responsible for ensuring that the
custom view is inserted into the table view, and of proper size and position.

*****************************************************************************/

@interface SubviewTableViewCell : NSCell
{
    @private

    NSView *subview;
}

// The view is not retained by the cell!
- (void) addSubview:(NSView *) view;

@end
