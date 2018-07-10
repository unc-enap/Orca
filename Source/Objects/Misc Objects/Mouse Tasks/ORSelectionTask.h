//
//  ORSelectionTask.h
//  Orca
//
//  Created by Mark Howe on Sun Apr 28 2002.
//  Copyright © 2001 CENPA, University of Washington. All rights reserved.
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

#pragma mark ¥¥¥Imported Files


#pragma mark ¥¥¥Forward Declarations
@class ORGroupView;

@interface ORSelectionTask : NSObject {
@private
    ORGroupView* 	view;
    NSRect          theSelectionRect;
    NSPoint         startLoc,currentLoc;
}

#pragma mark ¥¥¥Class Methods
+ (ORSelectionTask*) getTaskForEvent:(NSEvent *)event inView:(ORGroupView*)aView;

#pragma mark ¥¥¥Initialization
- (id)   initWithEvent:(NSEvent*)event inView:(ORGroupView*)aView;

#pragma mark ¥¥¥Mouse Events
- (void) mouseDragged:(NSEvent *)event;
- (void) mouseUp:(NSEvent *)event;

#pragma mark ¥¥¥Drawing
- (void) drawRect:(NSRect)aRect;

@end

