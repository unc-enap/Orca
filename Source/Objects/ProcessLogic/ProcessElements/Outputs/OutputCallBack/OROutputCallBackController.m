//
//  OROutputCallBackController.m
//  Orca
//
//  Created by Mark Howe on Mon April 9.
//  Copyright (c) 2012 University of Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Carolina reserve all rights in the program. Neither the authors,
//University of Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "OROutputCallBackController.h"
#import "OROutputCallBackModel.h"
#import "ORProcessThread.h"

@implementation OROutputCallBackController
-(id)init
{
    self = [super initWithWindowNibName:@"OutputCallBack"];
    return self;
}

- (void) populateCallBackObjPU
{
    [callBackObjPU removeAllItems];
    [callBackObjPU addItemWithTitle:@"Not Used"];
    NSArray* validObjs = [model validCallBackObjects];    
    id obj;
    NSEnumerator* e = [validObjs objectEnumerator];
    while(obj = [e nextObject]){
        [callBackObjPU addItemWithTitle:[obj processingTitle]];
    }
    
}
#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(callBackObjectChanged:)
                         name : ORCallBackObjectChangedNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(callBackChannelChanged:)
                         name : ORCallBackChannelChangedNotification
                       object : model];

	[notifyCenter addObserver : self
                     selector : @selector(callBackNameChanged:)
                         name : ORCallBackNameChangedNotification
                       object : model];

	[notifyCenter addObserver : self
                     selector : @selector(callBackCustomLabelChanged:)
                         name : ORCallBackCustomLabelChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(callBackLabelTypeChanged:)
                         name : ORCallBackLabelTypeChanged
						object: model];
	
}
- (void) updateWindow
{
    [super updateWindow];
    [self populateCallBackObjPU];
	[self callBackNameChanged:nil];
    [self callBackObjectChanged:nil];
    [self callBackChannelChanged:nil];
    [self callBackLabelTypeChanged:nil];
    [self callBackCustomLabelChanged:nil];
}	

- (void) callBackLabelTypeChanged:(NSNotification*)aNote
{
	[callBackLabelTypeMatrix selectCellWithTag: [model callBackLabelType]];
	[model setUpImage];
}

- (void) callBackCustomLabelChanged:(NSNotification*)aNote
{
	[callBackCustomLabelField setStringValue: [model callBackCustomLabel]];
	[model setUpImage];
}

- (void)setButtonStates
{
	[super setButtonStates];
    BOOL locked = [gSecurity isLocked:ORHWAccessLock];
	BOOL running = [ORProcessThread isRunning];
	[callBackObjPU setEnabled: !locked && !running];
    [callBackChannelField setEnabled: !locked && !running];
}

- (void) callBackChannelChanged:(NSNotification*)aNotification
{
	[callBackChannelField setIntValue:[model callBackChannel]];
}
- (void) callBackNameChanged:(NSNotification*) aNotification
{
	if([model callBackName]) [callBackSourceField setStringValue:[model callBackName]];
	else [callBackSourceField setStringValue:@"---"];
	if(![model callBackObject] && [model callBackName])[callBackSourceStateField setStringValue:@"Missing!"];
	else [callBackSourceStateField setStringValue:@""];
}

- (void) objectsRemoved:(NSNotification*) aNotification
{
	[super objectsRemoved:aNotification];
    [self populateCallBackObjPU];
    [self callBackObjectChanged:nil];
	
}

- (void) objectsAdded:(NSNotification*) aNotification
{
	[super objectsAdded:aNotification];
    [self populateCallBackObjPU];
    [self callBackObjectChanged:nil];
}


- (void) callBackObjectChanged:(NSNotification*)aNotification
{
	BOOL ok = NO;
	NSArray* validObjs = [model validCallBackObjects];  
	NSString* nameOfObjectModelIsUsing = [[model callBackObject] processingTitle];
	id obj;
	NSEnumerator* e = [validObjs objectEnumerator];
	while(obj = [e nextObject]){
		if([nameOfObjectModelIsUsing isEqualToString:[obj processingTitle]]){
			[callBackObjPU selectItemWithTitle:nameOfObjectModelIsUsing];
			ok = YES;
			break;
		}
	}
	if(!ok)[callBackObjPU selectItemAtIndex:0];
	if(![model callBackObject] && [model callBackName]){
		[callBackSourceStateField setStringValue:@"CallBack Missing!"];
		[viewCallBackSourceButton setEnabled:NO];
	}
	else {
		[callBackSourceStateField setStringValue:@""];
		[viewCallBackSourceButton setEnabled:YES];
	}
}

#pragma mark •••Actions
- (IBAction) callBackObjPUAction:(id)sender
{
	[model useCallBackObjectWithName: [sender titleOfSelectedItem] ];
}
- (IBAction) callBackChannelAction:(id)sender
{
	[model setCallBackChannel:[sender intValue]];
}
- (IBAction) viewCallBackSourceAction:(id)sender
{
	[model viewCallBackSource];
}

- (IBAction) callBackLabelTypeAction:(id)sender
{
	[model setCallBackLabelType:[[sender selectedCell]tag]];	
}

- (IBAction) callBackCustomLabelAction:(id)sender
{
	[model setCallBackCustomLabel:[sender stringValue]];	
}
@end
