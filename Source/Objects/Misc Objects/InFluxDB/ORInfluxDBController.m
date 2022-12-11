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
    self = [super initWithWindowNibName:@"InFlux"];
    return self;
}

- (void) dealloc
{
    [[[ORInFluxDBQueue sharedInFluxDBQueue] queue]            removeObserver:self forKeyPath:@"operationCount"];
 	[super dealloc];
}

-(void) awakeFromNib
{
	[super awakeFromNib];
    [[[ORInFluxDBQueue sharedInFluxDBQueue]queue]            addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    [queueValueBars setNumber:1 height:10 spacing:5];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
	NSOperationQueue* queue = [[ORInFluxDBQueue sharedInFluxDBQueue] queue];
    if (object == queue && [keyPath isEqual:@"operationCount"]) {
		NSNumber* n = [NSNumber numberWithInteger:[[[ORInFluxDBQueue queue] operations] count]];
		[self performSelectorOnMainThread:@selector(setQueCount:) withObject:n waitUntilDone:NO];
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
                     selector : @selector(hostNameChanged:)
                         name : ORInFluxDBHostNameChanged
                       object : model];
    	
    [notifyCenter addObserver : self
                     selector : @selector(portChanged:)
                         name : ORInFluxDBPortNumberChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(authTokenChanged:)
                         name : ORInFluxDBAuthTokenChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(orgChanged:)
                         name : ORInFluxDBOrgChanged
                       object : model];
 
    [notifyCenter addObserver : self
                     selector : @selector(bucketChanged:)
                         name : ORInFluxDBBucketChanged
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
    [self hostNameChanged:nil];
    [self portChanged:nil];
    [self authTokenChanged:nil];
    [self orgChanged:nil];
    [self bucketChanged:nil];
    [self InFluxDBLockChanged:nil];
}

- (void) hostNameChanged:(NSNotification*)aNote
{
	[hostNameField setStringValue:[model hostName]];
}

- (void) portChanged:(NSNotification*)aNote
{
    [portField setIntegerValue:[model portNumber]];
}
- (void) orgChanged:(NSNotification*)aNote
{
    [orgField setStringValue:[model org]];
}
- (void) bucketChanged:(NSNotification*)aNote
{
    [bucketField setStringValue:[model bucket]];
}
- (void) authTokenChanged:(NSNotification*)aNote
{
    [authTokenField setStringValue:[model authToken]];
}

- (void) InFluxDBLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORInFluxDBLock];
    [InFluxDBLockButton   setState: locked];
    [hostNameField        setEnabled:!locked];
    [portField            setEnabled:!locked];
    [authTokenField       setEnabled:!locked];
    [orgField             setEnabled:!locked];
    [bucketField          setEnabled:!locked];
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

- (IBAction) hostNameAction:(id)sender
{
	[model setHostName:[sender stringValue]];
}

- (IBAction) portAction:(id)sender
{
	[model setPortNumber:[sender integerValue]];
}

- (IBAction) authTokenAction:(id)sender
{
    [model setAuthToken:[sender stringValue]];
}

- (IBAction) orgAction:(id)sender
{
    [model setOrg:[sender stringValue]];
}

- (IBAction) bucketAction:(id)sender
{
    [model setBucket:[sender stringValue]];
}

- (IBAction) testAction:(id)sender
{
    [model testPost];
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

