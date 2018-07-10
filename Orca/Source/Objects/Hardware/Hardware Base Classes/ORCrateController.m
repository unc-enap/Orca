//
//  ORCrateController.m
//  Orca
//
//  Created by Mark Howe on 9/30/05.
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


#import "ORCrate.h"
#import "ORCrateController.h"
#import "ORCrateLabelView.h"

@implementation ORCrateController

- (id) init
{
    self = [super init];
    return self;
}

- (void) awakeFromNib
{
	[groupView setGroup:model];
    [groupView setDrawSlotNumbers:YES];
	[super awakeFromNib];
}


#pragma mark •••Accessors
- (ORGroupView *)groupView
{
    return [self groupView];
}

- (void) setModel:(OrcaObject*)aModel
{
    [super setModel:aModel];
    [groupView setGroup:(ORGroup*)model];
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(documentLockChanged:)
                         name : ORDocumentLock
                        object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(documentLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(showLabelsChanged:)
                         name : ORCrateModelShowLabelsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateNumberChanged:)
                         name : ORCrateModelCrateNumberChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateView:)
                         name : OROrcaObjectImageChanged
                        object: model];

    [notifyCenter addObserver:self
                      selector:@selector(movementLockChanged:)
                          name:ORCrateModelLockMovementChanged
                        object:nil];
    
}
- (void) updateView:(NSNotification*)aNotification
{
    if([aNotification object] == model){
        [groupView setNeedsDisplay:YES];
    }
}

- (void) isNowKeyWindow:(NSNotification*)aNotification
{
	[[self window] makeFirstResponder:(NSResponder*)groupView];
}

- (void) crateNumberChanged:(NSNotification*)aNote
{
	[self setCrateTitle];
}

- (void) setCrateTitle
{
	[[self window] setTitle:[NSString stringWithFormat:@"Crate %d",[model crateNumber]]];
}

- (void) powerFailed:(NSNotification*)aNotification
{
    if([aNotification object] == [model controllerCard]){
		[powerField setStringValue:@"No Pwr"];
	}
}

- (void) powerRestored:(NSNotification*)aNotification
{
    if([aNotification object] == [model controllerCard]){
		[powerField setStringValue:@""];
	}
}

- (void) documentLockChanged:(NSNotification*)aNotification
{
    if([gSecurity isLocked:ORDocumentLock]) [lockDocField setStringValue:@"Document is locked."];
    else if([gOrcaGlobals runInProgress])   [lockDocField setStringValue:@"Run In Progress"];
    else				    [lockDocField setStringValue:@""];
}


-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[model setUpImage];
		[self updateWindow];
	}
}

- (void) movementLockChanged:(NSNotification*)note
{
    [movementLockButton setIntValue:[model lockMovement]];
    [groupView setDragLocked:[model lockMovement]];
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	return [groupView validateMenuItem:menuItem];
}

#pragma mark •••Interface Management

- (void) showLabelsChanged:(NSNotification*)aNote
{
	[showLabelsButton setIntValue: [model showLabels]];
	[labelView setShowLabels:[model showLabels]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self documentLockChanged:nil];
    [groupView setNeedsDisplay:YES];
	[labelView forceRedraw];
    [self showLabelsChanged:nil];
    [self movementLockChanged:nil];
}


#pragma mark •••Actions
- (IBAction) showLabelsAction:(id)sender
{
	[model setShowLabels:[sender intValue]];
}

- (IBAction) movementLockAction:(id)sender
{
    [model setLockMovement:[sender intValue]];
}

//---------------------------------------------------------------
//these last actions are here only to work around a strange 
//first responder problem that occurs after cut followed by undo
- (IBAction)delete:(id)sender   { [groupView delete:sender]; }
- (IBAction)cut:(id)sender      { [groupView cut:sender]; }
- (IBAction)paste:(id)sender    { [groupView paste:sender]; }
- (IBAction)selectAll:(id)sender{ [groupView selectAll:sender]; }
//-----------------------------------------------------------------
@end
