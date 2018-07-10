//
//  ORPlotWithROI.h
//  Orca
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
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
#import "ORPlot.h"

@interface NSObject (ORPlotWithROIDelegateMethods)
- (void) drawFit:(id)aPlotView;
- (BOOL) plotterShouldShowRoi:(id)aPlot;
- (NSMutableArray*) roiArrayForPlotter:(id)aPlot;
- (void) plotter:(id)aPlot removeRoi:(id)anRoi;
- (void) plotter:(id)aPlot addRoi:(id)anRoi;
@end

@interface ORPlotWithROI : ORPlot {
	id	roi;
	long dragStartChannel;
	BOOL roiDragInProgress;
	int dragPart;
}

#pragma mark ***Initialization 
- (void) dealloc;
- (void) setDataSource:(id)ds;

#pragma mark ***Accessors
- (id) roi;
- (void) setRoi:(id)anRoi;

#pragma mark ***Component Switching
- (BOOL) nextComponent;
- (BOOL) lastComponent;
- (void) addRoi:(id)anRoi;
- (void) removeRoi;

#pragma mark ***Event Handling
- (BOOL) redrawEvent:(NSNotification*)aNote;
- (void) keyDown:(NSEvent*)theEvent;
- (BOOL) mouseDown:(NSEvent*)theEvent;
- (void) mouseDragged:(NSEvent*)theEvent;
- (void) mouseUp:(NSEvent*)theEvent;
- (void) resetCursorRects;

#pragma mark ***Roi Management
- (id) roiAtPoint:(NSPoint)aPoint;

- (void) shiftRoiRight;
- (void) shiftRoiLeft;
- (void) moveRoiToCenter;
@end
