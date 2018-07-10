
//
//  ORLabelController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
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
#import "ORLabelController.h"
#import "ORLabelModel.h"

@implementation ORLabelController

#pragma mark ¥¥¥Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"Label"];
    return self;
}


#pragma mark ¥¥¥Interface Management

- (void) controllerStringChanged:(NSNotification*)aNote
{
	[controllerStringField setStringValue: [model controllerString]];
}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    
    [notifyCenter addObserver: self
                     selector: @selector(labelLockChanged:)
                         name: ORLabelLock
                       object: model];

    [notifyCenter addObserver: self
                     selector: @selector(textSizeChanged:)
                         name: ORLabelModelTextSizeChanged
                       object: model];

    [notifyCenter addObserver: self
                     selector: @selector(textDidChange:)
                         name: NSTextDidChangeNotification
                       object: labelField];
	
    [notifyCenter addObserver: self
                     selector: @selector(textDidChange:)
                         name: NSTextDidChangeNotification
                       object: displayFormatField];
	
	[notifyCenter addObserver: self
                     selector: @selector(labelTypeChanged:)
                         name: ORLabelModelLabelTypeChanged
                       object: model];
	
	[notifyCenter addObserver: self
                     selector: @selector(updateIntervalChanged:)
                         name: ORLabelModelUpdateIntervalChanged
                       object: model];
	
	[notifyCenter addObserver: self
                     selector: @selector(displayFormatChanged:)
                         name: ORLabelModelFormatChanged
                       object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(controllerStringChanged:)
                         name : ORLabelModelControllerStringChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(labelChanged:)
                         name : ORLabelModelLabelChangedNotification
						object: model];
	
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[labelField setString:[model label]];
	[labelField setFont:[NSFont fontWithName:@"Monaco" size:12]];
	[displayFormatField setFont:[NSFont fontWithName:@"Monaco" size:12]];
}

- (void) updateWindow
{
	[super updateWindow];
    [self textSizeChanged:nil];
    [self labelChanged:nil];
    [self labelLockChanged:nil];
    [self labelTypeChanged:nil];
    [self updateIntervalChanged:nil];
	[self displayFormatChanged:nil];
	[self controllerStringChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORLabelLock to:secure];
    [labelLockButton setEnabled:secure];
}

- (void) updateIntervalChanged:(NSNotification*)aNotification
{
	[updateIntervalPU selectItemWithTag:[model updateInterval]];
}

- (void) labelLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORLabelLock];
    [labelLockButton setState: locked];
    [labelField setEditable: !locked];
    [textSizeField setEnabled: !locked];
    [labelTypeMatrix setEnabled: !locked];
    [controllerStringField setEnabled: !locked];
    [updateIntervalPU setEnabled: !locked && [model labelType] == kDynamicLabel];
    [displayFormatField setEditable: !locked && [model labelType] == kDynamicLabel];
}

- (void) labelChanged:(NSNotification*)notification
{
	[labelField setString:[model label]];
}

- (void) textDidChange:(NSNotification*)notification
{
	if([notification object] == labelField){
		[model setLabelNoNotify:[labelField string]];
	}
	else {
		[model setFormatNoNotify:[displayFormatField string]];
	}
}

- (void) textSizeChanged:(NSNotification*)aNote
{
	[textSizeField setIntValue:[model textSize]];
}

- (void) labelTypeChanged:(NSNotification*)aNote
{
	[labelTypeMatrix selectCellWithTag:[model labelType]];
	[self labelLockChanged:nil];
}

- (void) displayFormatChanged:(NSNotification*)aNote
{
	[displayFormatField setString:[model displayFormat]];
}


#pragma mark ¥¥¥Actions
- (IBAction) openAltDialogAction:(id)sender
{
	[self  endEditing];	
	[model openAltDialog:model];
}

- (IBAction) applyAction:(id)sender
{
	[self  endEditing];	
}

- (IBAction) controllerStringAction:(id)sender
{
	[model setControllerString:[sender stringValue]];	
}

- (IBAction) displayFormatAction:(id)sender
{
	[model setDisplayFormat:[sender stringValue]];
}

- (IBAction) updateIntervalAction:(id)sender
{
	[model setUpdateInterval:[[sender selectedItem] tag]];
}

- (IBAction) textSizeAction:(id)sender
{
	[model setTextSize:[sender intValue]];
}

- (IBAction) labelTypeAction:(id)sender
{
	[model setLabelType:[[sender selectedCell] tag]];
}

- (IBAction)labelLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORLabelLock to:[sender intValue] forWindow:[self window]];
}

@end
