//
//  ORInFluxDBController.m
//  Orca
//
// Created by Mark Howe on 12/7/2022.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORInFluxDBController.h"
#import "ORInFluxDBModel.h"
#import "ORInFluxDB.h"
#import "ORValueBarGroupView.h"

@interface ORInFluxDBController (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) createActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) deleteActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) stealthActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
@end

@implementation ORInFluxDBController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"InFluxDB"];
    return self;
}

- (void) dealloc
{
    [[[ORInFluxDBQueue sharedInFluxDBQueue] queue]            removeObserver:self forKeyPath:@"operationCount"];
    [[[ORInFluxDBQueue sharedInFluxDBQueue] lowPriorityQueue] removeObserver:self forKeyPath:@"operationCount"];
	[super dealloc];
}

-(void) awakeFromNib
{
	[super awakeFromNib];
    [[[ORInFluxDBQueue sharedInFluxDBQueue]queue]            addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    [[[ORInFluxDBQueue sharedInFluxDBQueue]lowPriorityQueue] addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    [queueValueBars setNumber:2 height:10 spacing:5];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
	NSOperationQueue* queue = [[ORInFluxDBQueue sharedInFluxDBQueue] queue];
    NSOperationQueue* lowPriorityQueue = [[ORInFluxDBQueue sharedInFluxDBQueue] lowPriorityQueue];
    if (object == queue && [keyPath isEqual:@"operationCount"]) {
		NSNumber* n = [NSNumber numberWithInteger:[[[ORInFluxDBQueue queue] operations] count]];
		[self performSelectorOnMainThread:@selector(setQueCount:) withObject:n waitUntilDone:NO];
    }
    else if (object == lowPriorityQueue && [keyPath isEqual:@"operationCount"]) {
        NSNumber* n = [NSNumber numberWithInteger:[[[ORInFluxDBQueue lowPriorityQueue] operations] count]];
        [self performSelectorOnMainThread:@selector(setLowPriorityQueCount:) withObject:n waitUntilDone:NO];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) setQueCount:(NSNumber*)n
{
    [[queueCountsMatrix cellAtRow:0 column:0] setIntValue:[n intValue]];
	[queueValueBars setNeedsDisplay:YES];
}

- (void) setLowPriorityQueCount:(NSNumber*)n
{
    [[queueCountsMatrix cellAtRow:1 column:0] setIntValue:[n intValue]];
    [queueValueBars setNeedsDisplay:YES];
}

#pragma mark •••Registration
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(remoteHostNameChanged:)
                         name : ORInFluxDBRemoteHostNameChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(localHostNameChanged:)
                         name : ORInFluxDBLocalHostNameChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(userNameChanged:)
                         name : ORInFluxDBUserNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(passwordChanged:)
                         name : ORInFluxDBPasswordChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(portChanged:)
                         name : ORInFluxDBPortNumberChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(InFluxDBLockChanged:)
                         name : ORInFluxDBLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(InFluxDBLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
}

- (void) updateWindow
{
    [super updateWindow];
    [self remoteHostNameChanged:nil];
	[self localHostNameChanged:nil];
	[self userNameChanged:nil];
	[self passwordChanged:nil];
	[self portChanged:nil];
	[self dataBaseNameChanged:nil];
    [self InFluxDBLockChanged:nil];
}

- (void) remoteHostNameChanged:(NSNotification*)aNote
{
	if([model remoteHostName])[remoteHostNameField setStringValue:[model remoteHostName]];
}

- (void) localHostNameChanged:(NSNotification*)aNote
{
	if([model localHostName])[localHostNameField   setStringValue:[model localHostName]];
}

- (void) userNameChanged:(NSNotification*)aNote
{
	if([model userName])[userNameField setStringValue:[model userName]];
}

- (void) passwordChanged:(NSNotification*)aNote
{
	if([model password])[passwordField setStringValue:[model password]];
}

- (void) portChanged:(NSNotification*)aNote
{
    [portField setIntegerValue:[model portNumber]];
}

- (void) dataBaseNameChanged:(NSNotification*)aNote
{
	[dataBaseNameField setStringValue:[model databaseName]];
}

- (void) InFluxDBLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORInFluxDBLock];
    [InFluxDBLockButton   setState: locked];
    
    [remoteHostNameField setEnabled:!locked];
    [localHostNameField  setEnabled:!locked];
    [userNameField       setEnabled:!locked];
    [passwordField       setEnabled:!locked];
    [portField           setEnabled:!locked];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORInFluxDBLock to:secure];
    [InFluxDBLockButton setEnabled: secure];
}


#pragma mark •••Actions
- (IBAction) InFluxDBLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORInFluxDBLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) remoteHostNameAction:(id)sender
{
	[model setRemoteHostName:[sender stringValue]];
}

- (IBAction) localHostNameAction:(id)sender
{
	[model setLocalHostName:[sender stringValue]];
}

- (IBAction) userNameAction:(id)sender
{
	[model setUserName:[sender stringValue]];
}

- (IBAction) passwordAction:(id)sender
{
	[model setPassword:[sender stringValue]];
}

- (IBAction) portAction:(id)sender
{
	[model setPortNumber:[sender integerValue]];
}


@end

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
@implementation ORInFluxDBController (private)
- (void) createActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertAlternateReturn){		
		[model createDatabases];
	}
}

- (void) deleteActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertAlternateReturn){		
		[model deleteDatabases];
	}
}
@end
#endif

