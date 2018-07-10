//
//  ORSubPlotController.h
//  Orca
//
//  Created by Mark Howe on Mon Nov 03 2003.
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

@class ORCompositePlotView;
@class ORPlotView;

@interface ORSubPlotController : NSObject 
{
    @private
        IBOutlet NSView*                view;
        IBOutlet ORCompositePlotView*	plotView;
        NSArray*                        topLevelObjects;
}

+ (ORSubPlotController*) panel;
// This method takes the stores the nib name and the owner of the object.
- (id)init;

// The nib file's have an outlet on the file's owner connected to the view.  This method 
// returns that view.
- (NSView*)view;
- (ORPlotView*) plotView;

- (void) setModel:(id)aModel;
- (void) registerNotificationObservers;
- (void) dataChanged:(NSNotification*)aNotification;

- (IBAction) centerOnPeak:(id)sender;
- (IBAction) autoScaleX:(id)sender;
- (IBAction) autoScaleY:(id)sender;
- (IBAction) toggleLog:(id)sender;

@end
