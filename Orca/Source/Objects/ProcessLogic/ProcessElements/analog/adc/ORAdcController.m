//
//  ORAdcController.m
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
#import "ORAdcController.h"
#import "ORAdcModel.h"


@implementation ORAdcController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Adc"];
    return self;
}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(minChangeChanged:)
                         name : ORAdcModelMinChangeChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(lowTextChanged:)
                         name : ORAdcModelLowTextChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(inRangeTextChanged:)
                         name : ORAdcModelInRangeTextChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(highTextChanged:)
                         name : ORAdcModelHighTextChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(trackMaxMinChanged:)
                         name : ORAdcModelTrackMaxMinChanged
						object: model];

}

- (void) updateWindow
{
	[super updateWindow];
    [self minChangeChanged:nil];
	[self lowTextChanged:nil];
	[self inRangeTextChanged:nil];
	[self highTextChanged:nil];
	[self trackMaxMinChanged:nil];
}

- (void) trackMaxMinChanged:(NSNotification*)aNote
{
	[trackMaxMinCB setIntValue: [model trackMaxMin]];
}

- (void) highTextChanged:(NSNotification*)aNote
{
	[highTextField setStringValue: [model highText]];
}

- (void) inRangeTextChanged:(NSNotification*)aNote
{
	[inRangeTextField setStringValue: [model inRangeText]];
}

- (void) lowTextChanged:(NSNotification*)aNote
{
	[lowTextField setStringValue: [model lowText]];
}


- (void) setButtonStates
{
	[super setButtonStates];
    BOOL locked = [gSecurity isLocked:ORHWAccessLock];
	[minChangeField setEnabled: !locked ];
}

- (void) minChangeChanged:(NSNotification*)aNote
{
	[minChangeField setFloatValue:[model minChange]];
}

- (void) trackMaxMinAction:(id)sender
{
	[model setTrackMaxMin:[sender intValue]];	
}

- (void) highTextAction:(id)sender
{
	[model setHighText:[sender stringValue]];	
}
- (void) inRangeTextAction:(id)sender
{
	[model setInRangeText:[sender stringValue]];	
}
- (void) lowTextAction:(id)sender
{
	[model setLowText:[sender stringValue]];	
}
- (IBAction) minChangeAction:(id)sender
{
	[model setMinChange:[sender floatValue]];
}


@end
