//
//  ORPulserDistribController.m
//  Orca
//
//  Created by Mark Howe on Thurs Feb 20 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORPulserDistribController.h"
#import "ORPulserDistribModel.h"


#pragma mark ¥¥¥Definitions

@implementation ORPulserDistribController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"PulserDistrib"];
	
	return self;
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{	
	
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
					 selector : @selector(patternChanged:)
						 name : ORPulserDistribPatternChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(patternChanged:)
						 name : ORPulserDistribPatternBitChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(disableForPulserChanged:)
						 name : ORPulserDisableForPulserChangedNotification
					   object : model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(noisyEnvBroadcastEnabledChanged:)
                         name : ORPulserDistribNoisyEnvBroadcastEnabledChanged
						object: model];
	
}
- (void) disableForPulserChanged:(NSNotification*)aNotification
{
	[disableForPulserCB setState:[model disableForPulser]];
}

- (void) patternChanged:(NSNotification*)aNotification
{
	uint32_t patternMask = (int32_t)[[[model patternArray] objectAtIndex:0] longValue];
	short bit;
	for(bit=0;bit< [patternMatrix0 numberOfColumns];bit++){
		[[patternMatrix0 cellWithTag:bit] setState:(patternMask&(1L<<bit)) > 0L];
	}
	
	patternMask = (int32_t)[[[model patternArray] objectAtIndex:1] longValue];
	for(bit=0;bit< [patternMatrix1 numberOfColumns];bit++){
		[[patternMatrix1 cellWithTag:bit] setState:(patternMask&(1L<<bit)) > 0L];
	}
	patternMask = (int32_t)[[[model patternArray] objectAtIndex:2] longValue];
	for(bit=0;bit< [patternMatrix2 numberOfColumns];bit++){
		[[patternMatrix2 cellWithTag:bit] setState:(patternMask&(1L<<bit)) > 0L];
	}
	patternMask = (int32_t)[[[model patternArray] objectAtIndex:3] longValue];
	for(bit=0;bit< [patternMatrix3 numberOfColumns];bit++){
		[[patternMatrix3 cellWithTag:bit] setState:(patternMask&(1L<<bit)) > 0L];
	}
	
}

#pragma mark ¥¥¥Interface Management

- (void) noisyEnvBroadcastEnabledChanged:(NSNotification*)aNote
{
	[noisyEnvBroadcastEnabledButton setState: [model noisyEnvBroadcastEnabled]];
}
- (void) updateWindow
{
    [self patternChanged:nil];
    [self disableForPulserChanged:nil];
	[self noisyEnvBroadcastEnabledChanged:nil];
}


#pragma mark ¥¥¥Actions

- (IBAction) noisyEnvBroadcastEnabledButtonAction:(id)sender
{
	[model setNoisyEnvBroadcastEnabled:[sender state]];	
}

- (IBAction) loadAction:(id)sender
{
	@try {
	    NSLog(@"Loading Pulser Distribution Data\n");
	    [model loadHardware:[model patternArray]];
	}
	@catch(NSException* localException) {
	    NSLog(@"Load of Pulser Distribution Data FAILED.\n");
	    ORRunAlertPanel([localException name], @"%@\nLoad of Pulser Distribution Data FAILED", @"OK", nil, nil,
                        localException);
		
	}
}

- (IBAction) patternAction:(id)sender
{
	uint32_t aMask = 0; 
	int bit;
	for(bit=0;bit< [sender numberOfColumns];bit++){
		if([[sender cellWithTag:bit] state]){
			aMask |= (1L<<bit);
		}
	}
	[model setPatternMaskForArray:(int)[sender tag] to:aMask];
}

- (IBAction) allColAction:(id)sender
{
	[model setPatternMaskForArray:(int)[sender selectedTag] to:0xffffffff];
}

- (IBAction) noneColAction:(id)sender
{
	[model setPatternMaskForArray:(int)[sender selectedTag] to:0x0];
}

- (IBAction) disableForPulserAction:(id)sender
{
	[model setDisableForPulser:[sender state]];
	
}


@end
