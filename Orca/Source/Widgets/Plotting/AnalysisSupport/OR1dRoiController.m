//
//  OR1dRoiController.m
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


#import "OR1dRoiController.h"
#import "OR1DHistoPlot.h"

@implementation OR1dRoiController

+ (id) panel
{
    return [[[OR1dRoiController alloc] init]autorelease];
}

-(id) init
{
    self = [super init];
    
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"1dRoi" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"1dRoi" owner:self topLevelObjects:&topLevelObjects];
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
                         name : OR1dRoiMinChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(roiMaxChanged:)
                         name : OR1dRoiMaxChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(analysisChanged:)
                         name : OR1dRoiAnalysisChanged
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
		[roiMinField setFloatValue: [model minChannel]];
		[roiWidthField setFloatValue:labs([model maxChannel]-[model minChannel])];
	}
	else {
		[roiMinField setStringValue:@"---"];	
		[roiWidthField setStringValue:@"---"];	
	}
	
}

- (void) roiMaxChanged:(NSNotification*)aNotification
{
	if(model){
		[roiMaxField setFloatValue: [model maxChannel]];
		[roiWidthField setFloatValue:labs([model maxChannel]-[model minChannel])];
	}
	else {          
		[roiMaxField setStringValue:@"---"];	
		[roiWidthField setStringValue:@"---"];	
	}
}

- (void) analysisChanged:(NSNotification*)aNotification
{
	if(model){
		[labelField		setStringValue:	[model label]];
		[totalSumField	setIntValue:	[model totalSum]];
		[centroidField	setFloatValue:	[model centroid]];
		[sigmaField		setFloatValue:	[model sigma]];
		[roiPeakXField	setIntValue:	(int)[model peakx]];
		[roiPeakYField	setIntValue:	(int)[model peaky]];
		if([model useRoiRate]){
			double theRate = [model roiRate];
			if(theRate == 0 ) [rateField	setStringValue:@"--"];
			else if(theRate > 1) [rateField	setStringValue:[NSString stringWithFormat:@"%.2f/sec",theRate]];
			else				 [rateField	setStringValue:[NSString stringWithFormat:@"%.2E/sec",theRate]];
		}
		else [rateField	setStringValue:@"N/A"];
	}
	else {
		[rateField		setStringValue:@"--"];
		[labelField		setStringValue:@"--"];
		[totalSumField	setIntValue:0];
		[centroidField	setFloatValue:0];
		[sigmaField		setFloatValue:0];
		[roiPeakXField	setIntValue:0];
		[roiPeakYField	setIntValue:0];
	}
}

@end
