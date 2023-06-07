//
//  ORLNGSSlowControlsController.m
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORLNGSSlowControlsController.h"
#import "ORLNGSSlowControlsModel.h"
#
@implementation ORLNGSSlowControlsController
- (id) init
{
    self = [super initWithWindowNibName: @"LNGSSlowControls" ];
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORLNGSSlowControlsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORLNGSSlowControlsPollTimeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(dataIsValidChanged:)
                         name : ORLNGSSlowControlsModelDataIsValidChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(userNameChanged:)
                         name : ORL200SlowControlsUserNameChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(passWordChanged:)
                         name : ORL200SlowControlsPassWordChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORL200SlowControlsIPAddressChanged
                        object: model];
}

- (void) updateWindow
{
    [ super updateWindow ];
    [self lockChanged:nil];
    [self userNameChanged:nil];
    [self passWordChanged:nil];
    [self pollTimeChanged:nil];
    [self ipAddressChanged:nil];
	[self dataIsValidChanged:nil];
	[self updateButtons];
}

- (void) dataIsValidChanged:(NSNotification*)aNote
{
	[self updateButtons];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORLNGSSlowControlsLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePopup selectItemWithTag: [model pollTime]];
	if([model pollTime])[pollingProgress startAnimation:self];
	else [pollingProgress stopAnimation:self];
}

- (void) userNameChanged:(NSNotification*)aNote
{
    [userNameField setStringValue:[model userName]];
}

- (void) passWordChanged:(NSNotification*)aNote
{
    [passWordField setStringValue:[model passWord]];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
    [ipAddressField setStringValue:[model ipAddress]];
}

#pragma mark •••Notifications

- (void) updateButtons
{
    //BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORLNGSSlowControlsLock];
	
    [lockButton setState: locked];
	
    [userNameField      setEnabled: !locked];
    [passWordField      setEnabled: !locked];
    [ipAddressField     setEnabled: !locked];
    [pollTimePopup      setEnabled: !locked];
	[pollNowButton		setEnabled: !locked];
}

- (NSString*) windowNibName
{
	return @"LNGSSlowControls";
}

#pragma mark •••Actions
- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:(int)[[sender selectedItem] tag]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORLNGSSlowControlsLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) pollNowAction:(id)sender
{
	//[model getAllValues];
}
- (IBAction) userNameAction:(id)sender
{
    [model setUserName:[userNameField stringValue]];
}

- (IBAction) passWordAction:(id)sender
{
    [model setPassWord:[passWordField stringValue]];
}
- (IBAction) ipAddressAction:(id)sender
{
    [model setIPAddress:[ipAddressField stringValue]];
}
@end



