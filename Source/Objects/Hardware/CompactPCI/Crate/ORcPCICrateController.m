
//
//  ORcPCICrateController.m
//  Orca
//
//  Created by Mark Howe on Mon Feb 6, 2006
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
#import "ORcPCICrateController.h"
#import "ORcPCICrateModel.h"

#import "ORcPCIBusProtocol.h"
//#import "ORcPCIExceptions.h"

@implementation ORcPCICrateController

- (id) init
{
    self = [super initWithWindowNibName:@"cPCICrate"];
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[self setCrateTitle];
}

- (void) setCrateTitle
{
	[[self window] setTitle:[NSString stringWithFormat:@"cPCI crate %d",[model crateNumber]]];
}

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    [notifyCenter addObserver : self
                     selector : @selector(powerFailed:)
                         name : @"cPCIPowerFailedNotification"
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"cPCIPowerRestoredNotification"
                       object : nil];
	
}


#pragma mark ¥¥¥Interface Management

#pragma mark ¥¥¥Actions
- (IBAction) showHideAction:(id)sender
{
    NSRect aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] 
                styleMask:[[self window] styleMask]];
    if([showHideButton state] == NSOnState)aFrame.size.height = 375;
    else aFrame.size.height = 305;
    [self resizeWindowToSize:aFrame.size];
}

- (void) showError:(NSException*)anException name:(NSString*)name
{
    NSLog(@"Failed Cmd: %@ \n",name);
    //if([[anException name] isEqualToString: OExceptionNocPCICratePower]) {
   //     [model  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@",name]];
    //}
    //else {
        ORRunAlertPanel([anException name], @"%@\n%@", @"OK", nil, nil,
                        [anException name],name);
   // }
}


@end
