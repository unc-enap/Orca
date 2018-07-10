//
//  ORDispatcherController.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
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
#import "ORDispatcherController.h"
#import "ORDispatcherModel.h"
#import "ORVmeCrateModel.h"

@implementation ORDispatcherController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Dispatcher"];
	return self;
}



#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
    
	[notifyCenter addObserver : self
					 selector : @selector(portChanged:)
						 name : ORDispatcherPortChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(clientsChanged:)
						 name : ORDispatcherClientsChangedNotification
					   object : model];
	
	
	[notifyCenter addObserver : self
					 selector : @selector(clientsChanged:)
						 name : ORDispatcherClientDataChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(checkAllowedChanged:)
						 name : ORDispatcherCheckAllowedChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(checkRefusedChanged:)
						 name : ORDispatcherCheckRefusedChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORDispatcherLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(textDidChange:)
                         name : NSTextDidChangeNotification
						object: nil];	

}

#pragma mark ¥¥¥Actions
- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORDispatcherLock to:secure];
    [lockButton setEnabled:secure];
}
- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORDispatcherLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) setPortAction:(id) sender;
{
	if([sender intValue] != [model socketPort]){
		[[self undoManager] setActionName: @"Set Socket Port"];
		[model setSocketPort:[sender intValue]];
	}	
}

- (IBAction) setActivateAllowAction:(id) sender
{
	if([sender intValue] != [model checkAllowed]){
        [model setCheckAllowed:[sender intValue]];
    }
}

- (IBAction) setActivateRefuseAction:(id) sender
{
	if([sender intValue] != [model checkRefused]){
        [model setCheckRefused:[sender intValue]];
    }
}

- (IBAction) reportAction:(id) sender
{
    [model report];
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
	[self portChanged:nil];
	[self clientsChanged:nil];
	[self checkAllowedChanged:nil];
	[self checkRefusedChanged:nil];
	
	[self allowedListChanged:nil];
	[self refusedListChanged:nil];
	
}

- (void)textDidChange:(NSNotification *)aNotification
{
    if([aNotification object] == allowListView){
        if([[allowListView string] characterAtIndex:[[allowListView string] length]-1] == '\n'){
            [model parseAllowedList: [allowListView string]];
            [model checkConnectedClients];
        }
    }
    else if([aNotification object] == refuseListView){
        if([[refuseListView string] characterAtIndex:[[refuseListView string] length]-1] == '\n'){
            [model parseRefusedList: [refuseListView string]];
            [model checkConnectedClients];
		}
    }
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    if([aNotification object] == allowListView){
        [model parseAllowedList: [allowListView string]];
        [model checkConnectedClients];
    }
    else if([aNotification object] == refuseListView){
        [model parseRefusedList: [refuseListView string]];
        [model checkConnectedClients];
    }
}

- (void) allowedListChanged:(NSNotification*)aNotification
{
    NSString* listString = [[model allowedList] componentsJoinedByString:@"\n"];
    if(listString)[allowListView setString:listString];
}

- (void) refusedListChanged:(NSNotification*)aNotification
{
    NSString* listString = [[model refusedList] componentsJoinedByString:@"\n"];
    if(listString)[refuseListView setString:listString];
}



- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORDispatcherLock];
    [lockButton setState: locked];
    
    [checkAllowedButton setEnabled:!locked];
    [checkRefusedButton setEnabled:!locked];
    [allowListView setEditable:!locked];
    [refuseListView setEditable:!locked]; 
    [portField setEnabled:!locked];   
}


- (void) portChanged:(NSNotification*)aNotification;
{
	[portField setIntValue: [model socketPort]];
}

- (void) clientsChanged:(NSNotification*)aNotification
{
	[clientListView reloadData];
}

- (void) checkAllowedChanged:(NSNotification*)aNotification
{
	[checkAllowedButton setState:[model checkAllowed]];
	[model checkConnectedClients];
}

- (void) checkRefusedChanged:(NSNotification*)aNotification
{
	[checkRefusedButton setState:[model checkRefused]];
	[model checkConnectedClients];
}

#pragma mark ¥¥¥Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
	id obj = [[model clients]  objectAtIndex:rowIndex];
	return [obj valueForKey:[aTableColumn identifier]];
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[model clients] count];
}

@end
