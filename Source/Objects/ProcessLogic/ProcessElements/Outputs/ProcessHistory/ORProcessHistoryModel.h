//
//  ORProcessHistoryModel.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "OROutputElement.h"

@class ORTimeRate;

@interface ORProcessHistoryModel :  OROutputElement 
{
	ORTimeRate* inputValue[4];
	NSDate* lastEval;
	int lastValue[4];	
    BOOL showInAltView;
	BOOL scheduledToRedraw;
}

#pragma mark ***Accessors
- (BOOL) showInAltView;
- (void) setShowInAltView:(BOOL)aShowInAltView;

- (void) dealloc;
- (void)makeConnectors;
- (void) setUpImage;
- (void) makeMainController;
- (NSString*) elementName;
- (void) processIsStarting;
- (id) eval;
- (void) postUpdate;
- (void) updateIcon;

- (NSColor*) plotColor:(int)plotIndex;

#pragma mark ¥¥¥Plot Data Source
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

#pragma mark ¥¥¥Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


@interface NSObject (ProcessHistory)
-(float) evalAndReturnAnalogValue;
@end

extern NSString* ORProcessHistoryModelShowInAltViewChanged;
extern NSString* ORProcessHistoryModelHistoryLabelChanged;
extern NSString* ORHistoryElementIn1Connection;
extern NSString* ORHistoryElementIn2Connection;
extern NSString* ORHistoryElementIn3Connection;
extern NSString* ORHistoryElementIn4Connection;
extern NSString* ORHistoryElementDataChanged;
