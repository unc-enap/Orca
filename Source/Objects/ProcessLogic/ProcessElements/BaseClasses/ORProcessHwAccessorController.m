//
//  ORProcessHwAccessorController.m
//  Orca
//
//  Created by Mark Howe on 11/20/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORProcessHwAccessorController.h"
#import "ORProcessHWAccessor.h"
#import "ORBitProcessing.h"
#import "ORVmeCard.h"
#import "ORProcessThread.h"
#import "ORProcessModel.h"

@implementation ORProcessHwAccessorController
#pragma mark ¥¥¥Initialization

- (void) awakeFromNib
{
	[super awakeFromNib];
}

- (void) populateObjPU
{
    [interfaceObjPU removeAllItems];
    [interfaceObjPU addItemWithTitle:@"Not Used"];
    NSArray* validObjs = [model validObjects];    
    id obj;
    NSEnumerator* e = [validObjs objectEnumerator];
    while(obj = [e nextObject]){
        [interfaceObjPU addItemWithTitle:[obj processingTitle]];
    }
    
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
        
    [notifyCenter addObserver : self
                     selector : @selector(interfaceObjectChanged:)
                         name : ORProcessHWAccessorHwObjectChangedNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(hwNameChanged:)
                         name : ORProcessHWAccessorHwNameChangedNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(bitChanged:)
                         name : ORProcessHWAccessorBitChangedNotification
                       object : model];

    [ notifyCenter addObserver: self
                      selector: @selector( objectsRemoved: )
                          name: ORGroupObjectsRemoved
                        object: nil];

    [ notifyCenter addObserver: self
                      selector: @selector( objectsAdded: )
                          name: ORGroupObjectsAdded
                        object: nil];

    [ notifyCenter addObserver: self
                      selector: @selector( slotChanged: )
                          name: ORVmeCardSlotChangedNotification
                        object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(hwAccessLockChanged:)
                         name: ORHWAccessLock
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(hwAccessLockChanged:)
                         name: ORProcessRunningChangedNotification
                       object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(displayFormatChanged:)
                         name : ORProcessHWAccessorDisplayFormatChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(customLabelChanged:)
                         name : ORProcessHWAccessorCustomLabelChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(labelTypeChanged:)
                         name : ORProcessHWAccessorLabelTypeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(viewIconTypeChanged:)
                         name : ORProcessHWAccessorViewIconTypeChanged
						object: model];
	
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self hwAccessLockChanged:nil];
    [self populateObjPU];
	[self bitChanged:nil];
    [self interfaceObjectChanged:nil];
    [self hwNameChanged:nil];
	[self displayFormatChanged:nil];
	[self customLabelChanged:nil];
	[self labelTypeChanged:nil];
	[self viewIconTypeChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORHWAccessLock to:secure];
    [hwAccessLockButton setEnabled:secure];
}

- (void) hwAccessLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORHWAccessLock];
    [hwAccessLockButton setState: locked];
	[self setButtonStates];
}

- (void)setButtonStates
{
    BOOL locked = [gSecurity isLocked:ORHWAccessLock];
    BOOL running = [ORProcessThread isRunning];
    [interfaceObjPU setEnabled: !locked && !running];
    [channelField setEnabled: !locked && !running];
	[commentField setEnabled: !locked];
	[displayFormatField setEnabled: !locked ];
	[viewIconTypePU setEnabled: !locked ];
	[labelTypeMatrix setEnabled: !locked ];
	[customLabelField setEnabled: !locked ];
}

- (void) displayFormatChanged:(NSNotification*)aNote
{
	[displayFormatField setStringValue: [model displayFormat]];
	[model setUpImage];
}


- (void) viewIconTypeChanged:(NSNotification*)aNote
{
	[viewIconTypePU selectItemAtIndex: [model viewIconType]];
	[model setUpImage];
}

- (void) labelTypeChanged:(NSNotification*)aNote
{
	[labelTypeMatrix selectCellWithTag: [model labelType]];
	[model setUpImage];
}

- (void) customLabelChanged:(NSNotification*)aNote
{
	[customLabelField setStringValue: [model customLabel]];
	[model setUpImage];
}

- (void) hwNameChanged:(NSNotification*) aNotification
{
	if([model hwName]) [currentSourceField setStringValue:[model hwName]];
	else [currentSourceField setStringValue:@"---"];
	if(![model hwObject] && [model hwName])[currentSourceStateField setStringValue:@"HW Missing!"];
	else [currentSourceStateField setStringValue:@""];
}

- (void) slotChanged:(NSNotification*) aNotification
{
    [self populateObjPU];
    [self interfaceObjectChanged:nil];
}

- (void) objectsRemoved:(NSNotification*) aNotification
{
    [self populateObjPU];
    [self interfaceObjectChanged:nil];

}

- (void) objectsAdded:(NSNotification*) aNotification
{
    [self populateObjPU];
    [self interfaceObjectChanged:nil];
}


- (void) interfaceObjectChanged:(NSNotification*)aNotification
{
	BOOL ok = NO;
	NSArray* validObjs = [model validObjects];  
	NSString* nameOfObjectModelIsUsing = [[model hwObject] processingTitle];  
	id obj;
	NSEnumerator* e = [validObjs objectEnumerator];
	while(obj = [e nextObject]){
		if([nameOfObjectModelIsUsing isEqualToString:[obj processingTitle]]){
			[interfaceObjPU selectItemWithTitle:nameOfObjectModelIsUsing];
			ok = YES;
			break;
		}
	}
	if(!ok)[interfaceObjPU selectItemAtIndex:0];
	if(![model hwObject] && [model hwName]){
		[currentSourceStateField setStringValue:@"HW Missing!"];
		[viewSourceButton setEnabled:NO];
	}
	else {
		[currentSourceStateField setStringValue:@""];
		[viewSourceButton setEnabled:YES];
	}
}

- (void) bitChanged:(NSNotification*)aNotification
{
	[channelField setIntValue:[model bit]];
}

#pragma mark ¥¥¥Actions
-(IBAction)hwAccessLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORHWAccessLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) interfaceObjPUAction:(id)sender
{
    [model useHWObjectWithName:[sender titleOfSelectedItem]];
}

- (IBAction) channelFieldAction:(id)sender
{
    [model setBit:[sender intValue]];
}

- (IBAction) viewSourceAction:(id)sender
{
    [model viewSource];	
}
- (IBAction) viewIconTypeAction:(id)sender
{
	[model setViewIconType:[sender indexOfSelectedItem]];	
}

- (IBAction) labelTypeAction:(id)sender
{
	[model setLabelType:[[sender selectedCell]tag]];	
}

- (IBAction) customLabelAction:(id)sender
{
	[model setCustomLabel:[sender stringValue]];	
}

- (IBAction) displayFormatAction:(id)sender
{
	[model setDisplayFormat:[sender stringValue]];	
}

@end
