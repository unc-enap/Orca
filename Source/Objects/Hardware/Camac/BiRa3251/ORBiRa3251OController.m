/*
 *  ORBiRa3251OModelController.cpp
 *  Orca
 *
 *  Created by Mark Howe on Fri Aug 4, 2006.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORBiRa3251OController.h"

#import "ORCamacExceptions.h"

// methods
@implementation ORBiRa3251OController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"BiRa3251O"];
	
    return self;
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORCamacCardSlotChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(outputRegisterChanged:)
                         name : ORBiRa3251OModelOutputRegisterChanged
						object: model];
	
}

#pragma mark ¥¥¥Interface Management

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
	[self outputRegisterChanged:nil];
}


- (void) outputRegisterChanged:(NSNotification*)aNote
{
	unsigned short theMask = [model outputRegister];
	int i;
	for(i=0;i<12;i++){
		[[outputRegisterMatrix cellWithTag:i] setState: (theMask & (1<<i))!=0];
	}
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"BiRa3251O (Station %d)",(int)[model stationNumber]]];
}

#pragma mark ¥¥¥Actions

- (void) outputRegisterMatrixAction:(id)sender
{
	unsigned short theMask = [model outputRegister];
	int tag = (int)[[(NSMatrix*)sender selectedCell] tag];
	if(![sender intValue]) theMask &= ~(1<<tag);
	else theMask |= (1<<tag);
	[model setOutputRegister:theMask];	
}

- (IBAction) initAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model initBoard];
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Load Register"];
    }
}

- (void) showError:(NSException*)anException name:(NSString*)name
{
    NSLog(@"Failed Cmd: %@\n",name);
    if([[anException name] isEqualToString: OExceptionNoCamacCratePower]) {
        [[model crate]  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@",name]];
    }
    else {
        ORRunAlertPanel([anException name], @"%@\n%@", @"OK", nil, nil,
                        [anException name],name);
    }
}
@end



