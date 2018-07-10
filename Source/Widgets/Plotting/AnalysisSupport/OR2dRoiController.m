//
//  OR2dRoiController.m
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


#import "OR2dRoiController.h"
#import "OR1DHistoPlot.h"

@implementation OR2dRoiController

+ (id) panel
{
    return [[[OR2dRoiController alloc] init]autorelease];
}

-(id) init
{
    self = [super init];
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"2dRoi" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"2dRoi" owner:self topLevelObjects:&topLevelObjects];
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
                     selector : @selector(analysisChanged:)
                         name : OR2dRoiAnalysisChanged
                       object : model];
	[self updateWindow];

}

- (void) updateWindow
{
    [self analysisChanged:nil];
}

- (void) analysisChanged:(NSNotification*)aNotification
{
	if(model){
		[labelField		setStringValue:	[model label]];
		[totalSumField	setIntValue:	[model totalSum]];
		[averageField	setFloatValue:	[model average]];
		[peakXField	setIntValue:	(int)[model peakx]];
		[peakYField	setIntValue:	(int)[model peaky]];
	}
	else {
		[labelField		setStringValue:@"--"];
		[totalSumField	setIntValue:0];
		[averageField	setFloatValue:0];
		[peakXField	setIntValue:0];
		[peakYField	setIntValue:0];
	}
}

@end
