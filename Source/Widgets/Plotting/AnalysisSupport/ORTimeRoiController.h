//
//  ORTimeRoiController.h
//  testplot
//
//  Created by Mark Howe on Tue May 18 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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
#import "ORTimeRoi.h"


@interface NSObject (ORTimeRoiControllerDataSource)
- (id)		plotter;
- (int32_t)	minChannel;
- (int32_t)	maxChannel;
- (double)	average;	
- (double)	centroid;	
- (double)	sigma;	
- (double)   peaky;	
- (double)   peakx;	
@end

@interface ORTimeRoiController : NSObject {
    IBOutlet NSTextField*       labelField;
    IBOutlet NSTextField*       roiMinField;
    IBOutlet NSTextField*       roiMaxField;
    IBOutlet NSTextField*       averageField;
    IBOutlet NSTextField*       standardDeviationField;
    IBOutlet NSTextField*       maxValueField;
    IBOutlet NSTextField*       minValueField;
    IBOutlet NSBox*             analysisView;
	id model;
    NSArray*                     topLevelObjects;
}

+ (id) panel;

- (void)	setModel:(id)aModel;
- (id)		model ;

- (id) init;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (NSView*) view;
- (void) analysisChanged:(NSNotification*)aNotification;
- (void) roiMinChanged:(NSNotification*)aNotification;
- (void) roiMaxChanged:(NSNotification*)aNotification;
@end


