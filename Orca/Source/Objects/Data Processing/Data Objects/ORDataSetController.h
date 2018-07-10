//
//  ORDataSetController.h
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


@interface ORDataSetController : OrcaObjectController  {
    @private
        IBOutlet NSView*    view;
        IBOutlet NSTextField* maxXValueField;
        IBOutlet NSTextField* minXValueField;
        IBOutlet NSTextField* maxYValueField;
        IBOutlet NSTextField* minYValueField;
        NSMutableArray* subControllers;
        BOOL inited;
}

#pragma mark ¥¥¥Accessors
- (NSMutableArray*) subControllers;
- (void) setSubControllers:(NSMutableArray*)newSubControllers;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) modelChanged:(NSNotification*)aNotification;
- (void) dataSetRemoved:(NSNotification*)aNote;
- (void) forcedLimitsMinXChanged:(NSNotification*)aNote;
- (void) forcedLimitsMinYChanged:(NSNotification*)aNote;
- (void) forcedLimitsMaxXChanged:(NSNotification*)aNote;
- (void) forcedLimitsMaxYChanged:(NSNotification*)aNote;
- (void) setXLimits;
- (void) setYLimits;

#pragma mark ¥¥¥Actions
- (IBAction) reLoad:(id)sender;
- (IBAction) centerOnPeak:(id)sender;
- (IBAction) toggleLog:(id)sender;
- (IBAction) autoScaleX:(id)sender;
- (IBAction) autoScaleY:(id)sender;
- (IBAction) forceLimitsAction:(id)sender;
- (IBAction) forceLimitsNowAction:(id)sender;
@end
