//
//  ORVXI11HardwareFinderController.h
//  Orca
//
//  Created by Michael Marino on 6 Nov 2011
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

#pragma mark •••Imported Files

#pragma mark •••Forward Declarations
@class ORVXI11HardwareFinder;
@class ORScriptView;

// This class is to get notification of the end of the drag.  It is only necessary
// in versions < 10.7, because 10.7 has implemented a delegate call-back for NSTableView
// Since for versions previous to 10.7, NSTableView implemented the informal NSDraggingSource
// protocol, we can derive and overload the function that is called at the end of the 
// dragging session.
// M. Marino
@interface ORTableViewWithDropNotify : NSTableView 
{
}
@end

@interface ORVXI11HardwareFinderController : NSWindowController <NSTableViewDataSource>
{
	IBOutlet NSTableView* availableHardware;
	IBOutlet NSButton* refreshButton;
    IBOutlet NSProgressIndicator* refreshIndicate;
    
    NSArray* createdObjects;
    NSDictionary* supportedVXIObjects;
}

#pragma mark •••Initialization
+ (ORVXI11HardwareFinderController*) sharedVXI11HardwareFinderController;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;


#pragma mark •••Actions
- (IBAction) refreshHardwareAction:(id)sender;

#pragma mark •••Interface Management
- (void) hardwareChanged:(NSNotification*)aNote;

@end