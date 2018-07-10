//
//  ORHPNplHVController.m
//  Orca
//
//  Created by Mark Howe on Thurs Dec 6 2007
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORNplHVController.h"
#import "ORNplHVModel.h"

@implementation ORNplHVController
- (id) init
{
    self = [ super initWithWindowNibName: @"NplHV" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    basicOpsSize	= NSMakeSize(320,320);
    rampOpsSize		= NSMakeSize(570,750);
    blankView		= [[NSView alloc] init];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORNplHV%d.selectedtab",[model uniqueIdNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];

}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORNplHVLock
						object: nil];
}


- (void) updateWindow
{
    [ super updateWindow ];
    
    [self lockChanged:nil];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:basicOpsSize];    break;
		case  1: [self resizeWindowToSize:rampOpsSize];	    break;
    }
    [[self window] setContentView:totalView];
            
    NSString* key = [NSString stringWithFormat: @"orca.ORNplHV%d.selectedtab",[model uniqueIdNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORNplHVLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self setButtonStates];
}

- (void) updateButtons
{
}




#pragma mark •••Notifications

- (void) setButtonStates
{
    //BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORNplHVLock];
	int  ramping		= [model runningCount]>0;

    [lockButton setState: locked];
	[sendButton setEnabled:!locked && !ramping];
	[super setButtonStates];
}

- (NSString*) windowNibName
{
	return @"NplHV";
}

- (NSString*) rampItemNibFileName
{
	//subclasses can specify a differant RampItem nib file if needed.
	return @"HVRampItem";
}

#pragma mark •••Actions

- (IBAction) sendCmdAction:(id)sender
{
	[self endEditing];
	[model sendCmd];
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORNplHVLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) version:(id)sender
{
	[model revision];
}

- (IBAction) initBoard:(id) sender
{
	[model initBoard];
}

@end
