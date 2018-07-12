//
//  ORAlarmElementController.m
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
#import "ORAlarmElementController.h"
#import "ORAlarmElementModel.h"


@implementation ORAlarmElementController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"AlarmElement"];
    return self;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(nameFieldChanged:)
                         name : ORAlarmElementNameChangedNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(helpFieldChanged:)
                         name : ORAlarmElementHelpChangedNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(severityChanged:)
                         name : ORAlarmElementSeverityChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(noAlarmNameChanged:)
                         name : ORAlarmElementModelNoAlarmNameChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(eMailDelayChanged:)
                         name : ORAlarmElementeMailDelaChangedNotification
                        object: model];

}

#pragma mark ¥¥¥Interface Management

- (void) noAlarmNameChanged:(NSNotification*)aNote
{
	[noAlarmNameTextField setStringValue: [model noAlarmName]];
}
- (void) updateWindow
{
    [super updateWindow];
    [self nameFieldChanged:nil];
    [self helpFieldChanged:nil];
    [self severityChanged:nil];
	[self noAlarmNameChanged:nil];
    [self eMailDelayChanged:nil];
}

- (void) nameFieldChanged:(NSNotification*) aNote
{
	[nameField setStringValue:[model alarmName]];
}
- (void) eMailDelayChanged:(NSNotification*) aNote
{
    [eMailDelayField setIntValue:[model eMailDelay]];
}
- (void) helpFieldChanged:(NSNotification*) aNote
{
	[helpField setStringValue:[model alarmHelp]];
}

- (void) severityChanged:(NSNotification*) aNote
{
	[severityMatrix selectCellWithTag:[model alarmSeverity]];
}

#pragma mark ¥¥¥Actions

- (void) noAlarmNameTextFieldAction:(id)sender
{
	[model setNoAlarmName:[sender stringValue]];	
}
- (IBAction) nameAction:(id)sender
{
    [model setAlarmName:[sender stringValue]];
}

- (IBAction) helpAction:(id)sender
{
    [model setAlarmHelp:[sender stringValue]];
}

- (IBAction) severityAction:(id)sender
{
    [model setAlarmSeverity:(int)[[sender selectedCell]tag]];
}

- (IBAction) eMailDelayAction:(id)sender
{
    [model setEMailDelay:[sender intValue]];
}

@end
