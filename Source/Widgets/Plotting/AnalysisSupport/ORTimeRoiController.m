//
//  ORTimeRoiController.m
//  
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


#import "ORTimeRoiController.h"
#import "ORTimeLinePlot.h"
#import "ORTimeLine.h"
#import "ORCompositePlotView.h"

@implementation ORTimeRoiController

+ (id) panel
{
    return [[[ORTimeRoiController alloc] init]autorelease];
}

-(id) init
{
    self = [super init];
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"TimeRoi" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"TimeRoi" owner:self topLevelObjects:&topLevelObjects];
#endif
    [topLevelObjects retain];
    
    return self;
}


- (void)awakeFromNib
{	
	[self updateWindow];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [topLevelObjects release];

    [super dealloc];
}

- (NSView*) view
{
    return analysisView;
}

- (void) setModel:(id)aModel 
{
	model= aModel; 
    if(model){
		[self registerNotificationObservers];
	}
	else {
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		[self updateWindow];
	}
}

- (id) model { return model; }

- (void) registerNotificationObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	if(!model)return;
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
        
    [notifyCenter addObserver : self
                     selector : @selector(roiMinChanged:)
                         name : ORTimeRoiMinChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(roiMaxChanged:)
                         name : ORTimeRoiMaxChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(analysisChanged:)
                         name : ORTimeRoiAnalysisChanged
                       object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(analysisChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
	[self updateWindow];

}

- (void) updateWindow
{
    [self roiMinChanged:nil];
    [self roiMaxChanged:nil];
    [self analysisChanged:nil];
}

- (void) roiMinChanged:(NSNotification*)aNotification
{
	if(model){
		id ds = [model dataSource];
		
		ORTimeLine* axis = (ORTimeLine*)[[ds plotView] xAxis];
		NSTimeInterval startTime = [axis startTime];
		NSDate *aDate = [NSDate dateWithTimeIntervalSince1970:startTime-[model minChannel]];
		[roiMinField setStringValue: [aDate description]];
	}
	else {
		[roiMinField setStringValue:@"---"];	
	}
	
}

- (void) roiMaxChanged:(NSNotification*)aNotification
{
	if(model){
		id ds = [model dataSource];
		
		ORTimeLine* axis = (ORTimeLine*)[[ds plotView] xAxis];
		NSTimeInterval startTime = [axis startTime];
		NSDate* aDate = [NSDate dateWithTimeIntervalSince1970:startTime-[model maxChannel]];
		[roiMaxField setStringValue: [aDate description]];
	}
	else {          
		[roiMaxField setStringValue:@"---"];	
	}
}

- (void) analysisChanged:(NSNotification*)aNotification
{
	if(model){
		[labelField		setStringValue:	[model label]];
		[averageField	setFloatValue:	[model average]];
		[minValueField	setFloatValue:	[model minValue]];
		[maxValueField	setFloatValue:	[model maxValue]];
		[standardDeviationField setFloatValue: [model standardDeviation]];
	}
	else {
		[labelField		setStringValue:@"--"];
		[averageField	setFloatValue:0];
		[minValueField	setFloatValue:0];
		[maxValueField	setFloatValue:0];
		[standardDeviationField setFloatValue: 0];
	}
}

@end
