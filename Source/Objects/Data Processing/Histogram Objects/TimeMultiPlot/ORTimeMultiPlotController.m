//
//  ORTimeMultiPlotController.m
//  Orca
//

//  Created by Mark Howe on Fri May 16, 2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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
#import "ORTimeMultiPlotController.h"
#import "ORTimeMultiPlot.h"
#import "ORTimeSeriesPlot.h"
#import "ORPlotView.h"
#import "ORCompositePlotView.h"
#import "ORAxis.h"


@implementation ORTimeMultiPlotController

#pragma mark •••Initialization

-(id)init
{
    self = [super initWithWindowNibName:@"TimeMultiPlot"];
    return self;
}


- (void) awakeFromNib
{
    [super awakeFromNib];
	[[plotView yAxis] setInteger:NO];
    [[plotView yAxis] setRngLimitsLow:-5E9 withHigh:5E9 withMinRng:2];

}

- (void) plotNameChanged:(NSNotification*)aNote
{
	if(![model plotName])[model setPlotName:@"TimeMultiPlot"];
	[plotNameField setStringValue:[model plotName]];
	[plotNameField resignFirstResponder];
	[[self window] setTitle:[model plotName]];
}

- (void) setUpPlots
{
	[plotView removeAllPlots];
	int n = [model cachedCount];
    int i;
    for(i=0;i<n;i++){
		
		NSColor* theColor;
		switch (i%10){
			case 0: theColor = [NSColor redColor]; break;
			case 1: theColor = [NSColor blueColor]; break;
			case 2: theColor = [NSColor purpleColor]; break;
			case 3: theColor = [NSColor brownColor]; break;
			case 4: theColor = [NSColor greenColor]; break;
			case 5: theColor = [NSColor blackColor]; break;
			case 6: theColor = [NSColor cyanColor]; break;
			case 7: theColor = [NSColor orangeColor]; break;
			case 8: theColor = [NSColor magentaColor]; break;
			case 9: theColor = [NSColor yellowColor]; break;
			default: theColor = [NSColor redColor]; break;
		}
		if([[model cachedObjectAtIndex:i] isKindOfClass:NSClassFromString(@"ORTimeSeriesPlot")]){
			ORTimeSeriesPlot* aPlot = [[ORTimeSeriesPlot alloc] initWithTag:i andDataSource:self];
			[aPlot setLineColor:theColor];
			[aPlot setRoi: [[model rois:i] objectAtIndex:0]];
			[plotView addPlot: aPlot];
			[aPlot release];
		}
	}
	[self setLegend];
}

@end