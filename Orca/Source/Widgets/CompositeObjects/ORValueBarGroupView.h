//
//  ORValueBarGroupView.h
//  Orca
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of  
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
@class ORAxis;
@class ORValueBar;

@interface ORValueBarGroupView : NSView {
	ORAxis*				xAxis;
	NSMutableArray*		valueBars;
	int					numberBars;
	float 				barHeight;
	float 				barSpacing;
	id					dataSource;
	ORValueBar*			chainedView;
}
- (void) setUpViews;
- (void) setNumber:(int)n height:(float)aHeight spacing:(float)aSpacing;
- (void) adjustPositionsAndSizes;
- (void) setXLabel:(NSString*)aLabel;
- (NSArray*) valueBars;

- (IBAction) setLogX:(id)sender;

@property (retain) ORAxis*			xAxis;
@property (assign) int				numberBars;
@property (assign) float			barHeight;
@property (assign) float			barSpacing;
@property (assign) IBOutlet id		dataSource;
@property (assign) IBOutlet ORValueBar*		chainedView;
@end
