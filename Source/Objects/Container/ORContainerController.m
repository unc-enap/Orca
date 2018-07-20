
//
//  ORContainerController.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
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
#import "ORContainerController.h"
#import "ORContainerModel.h"

#import "ORStatusController.h"
#import "ORAlarmController.h"
#import "ORCatalogController.h"
#import "ORHWWizardController.h"
#import "ORPreferencesController.h"
#import "ORCommandCenterController.h"
#import "ORHelpCenter.h"

@implementation ORContainerController

- (id) init
{
    self = [super initWithWindowNibName:@"Container"];
    return self;
}

- (void) awakeFromNib
{
    [groupView setGroup:model];
	
	NSImage* anImage = [[NSImage alloc] initWithContentsOfFile:[[model backgroundImagePath] stringByExpandingTildeInPath]];
	[groupView setBackgroundImage:anImage];
	[anImage release];
	
    [super awakeFromNib];
}


#pragma mark ¥¥¥Accessors
- (ORGroupView *)groupView
{
    return [self groupView];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [groupView setGroup:(ORGroup*)model];
	
	NSImage* anImage = [[NSImage alloc] initWithContentsOfFile:[[model backgroundImagePath] stringByExpandingTildeInPath]];
	[groupView setBackgroundImage:anImage];
	[anImage release];
	
    NSString* theName = [self className];
    if([theName hasPrefix:@"OR"]){
        theName = [theName substringFromIndex:2];
    }
    NSRange range = [theName rangeOfString:@"Controller"];
    if(range.location != NSNotFound){
        theName = [theName substringToIndex:range.location];
    }
    [[self window] setTitle:[NSString stringWithFormat:@"%@ %u",theName,[model uniqueIdNumber]]];
    
    if([[model guardian] isKindOfClass: [model class]]){
        [goBackButton setTransparent:NO];
    } 
    else [goBackButton setTransparent:YES];
    
}

#pragma mark ¥¥¥Notifications
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
                     selector : @selector(scaleFactorChanged:)
                         name : ORContainerScaleChangedNotification
                        object: model];

	[notifyCenter addObserver : self
					 selector : @selector(remoteScaleFactorChanged:)
						 name : @"ScaleView"
						object: groupView];
	
	[notifyCenter addObserver : self
					 selector : @selector(updateWindow)
						 name : ORConnectionChanged
					   object : nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(backgroundImageChanged:)
						 name : ORContainerBackgroundImageChangedNotification
					   object : model];
	
	
}

-(void) backgroundImageChanged:(NSNotification*)note
{
	NSImage* anImage = [[NSImage alloc] initWithContentsOfFile:[[model backgroundImagePath] stringByExpandingTildeInPath]];
	[groupView setBackgroundImage:anImage];
	[anImage release];
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
		//the icon needs to be updated, but we have to wait until the next event to 
		//avoid a drawing conflict
		[model performSelector:@selector(setUpImage) withObject:nil afterDelay:0];
		[self updateWindow];
    }
}

#pragma mark ¥¥¥Interface Management
- (void) endEditing
{
}

- (void) updateWindow
{
    [super updateWindow];
    [self documentLockChanged:nil];
    [self scaleFactorChanged:nil];
    [groupView setNeedsDisplay:YES];
}

- (void) remoteScaleFactorChanged:(NSNotification*)aNotification
{
	[model setScaleFactor:[[[aNotification userInfo] objectForKey:@"ScaleFactor"] intValue]];
	[scaleFactorField setIntValue:[groupView scalePercent ]];
}

- (void) scaleFactorChanged:(NSNotification*)aNotification
{
	[groupView setScalePercent:[model scaleFactor]];
	[scaleFactorField setIntValue:[groupView scalePercent ]];
}

#pragma mark ¥¥¥Toolbar
- (IBAction) openHelp:(NSToolbarItem*)item 
{
	[[(ORAppDelegate*)[NSApp delegate] helpCenter] showHelpCenter:nil];
}
- (IBAction) statusLog:(NSToolbarItem*)item 
{
    [[ORStatusController sharedStatusController] showWindow:self];
}
- (IBAction) alarmMaster:(NSToolbarItem*)item 
{
    [[ORAlarmController sharedAlarmController] showWindow:self];
}
- (IBAction) openCatalog:(NSToolbarItem*)item 
{
    [[ORCatalogController sharedCatalogController] showWindow:self];
}


- (IBAction) openPreferences:(NSToolbarItem*)item 
{
    [[ORPreferencesController sharedPreferencesController] showWindow:self];
}

- (IBAction) openHWWizard:(NSToolbarItem*)item 
{
    [[ORHWWizardController sharedHWWizardController] showWindow:self];
}

- (IBAction) openCommandCenter:(NSToolbarItem*)item 
{
    [[ORCommandCenterController sharedCommandCenterController] showWindow:self];
}

- (IBAction) openTaskMaster:(NSToolbarItem*)item 
{
    [(ORAppDelegate*)[NSApp delegate] showTaskMaster:self];
}


- (IBAction) scaleFactorAction:(id)sender
{
    [model setScaleFactor:[sender intValue]];
}

- (NSRect)windowWillUseStandardFrame:(NSWindow*)sender defaultFrame:(NSRect)defaultFrame
{
    return [groupView normalized] ;
}

- (IBAction) goBackAction:(id)sender
{
    if([[model guardian] isKindOfClass: [model class]]){
        [[model guardian] makeMainController];
    } 
}

@end
