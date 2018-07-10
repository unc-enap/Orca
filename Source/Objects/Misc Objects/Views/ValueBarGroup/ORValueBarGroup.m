//  ORValueBarGroup.m
//  Orca
//
//  Created by Mark Howe on 5/20/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
//
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
#import "ORValueBarGroup.h"
#import "ORAxis.h"
#import "ORValueBar.h"

@implementation ORValueBarGroup

- (void) setTotalBars:(int) n
{
	[valueBar0 setXScale:xScale];
	[valueBar0 setDataSource:[dataSource cellAtRow:n-1 column:0]];
	ORValueBar* lastBar = valueBar0;
	NSRect theTotalFrame = [self frame];
	float extra = (theTotalFrame.size.height - ([valueBar0 frame].size.height * n))/(float)(n-1);
	float starty = [valueBar0 frame].size.height + extra;
	int i;
	for(i=0;i<n-1;i++){
		ORValueBar* aBar = [[ORValueBar alloc] initWithFrame:[valueBar0 frame]];
		NSRect oldFrame = [aBar frame];
		oldFrame.origin.y = starty;
		[aBar setFrame:oldFrame];
		starty += oldFrame.size.height + extra;
		[self addSubview:aBar];

		[aBar setXScale:xScale];
		[aBar setDataSource:[dataSource cellAtRow:n-i-2 column:0]];
		[lastBar setChainedView:aBar];
		lastBar = aBar;

		[aBar release];
	}
}

@end
