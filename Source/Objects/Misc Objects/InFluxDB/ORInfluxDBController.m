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

@implementation ORInFluxDBController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"InFlux"];
    return self;
}

- (void) dealloc
{
     [super dealloc];
}

-(void) awakeFromNib
{
    [super awakeFromNib];
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
                     selector : @selector(inFluxDBLockChanged:)
                         name : ORInFluxDBLock
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(inFluxDBLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(accessTypeChanged:)
                         name : ORInFluxDBAccessTypeChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(socketStatusChanged:)
                         name : ORInFluxDBSocketStatusChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateChanged:)
                         name : ORInFluxDBRateChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(stealthModeChanged:)
                         name : ORInFluxDBStealthModeChanged
                        object: model];
}

- (void) updateWindow
{
    [super updateWindow];
    [self hostNameChanged:nil];
    [self portChanged:nil];
    [self authTokenChanged:nil];
    [self orgChanged:nil];
    [self bucketChanged:nil];
    [self inFluxDBLockChanged:nil];
    [self accessTypeChanged:nil];
    [self socketStatusChanged:nil];
    [self rateChanged:nil];
    [self stealthModeChanged:nil];

}
- (void) stealthModeChanged:(NSNotification*)aNote
{
    [stealthModeButton setIntValue: [model stealthMode]];
    [dbStatusField setStringValue:![model stealthMode]?@"":@"Disabled"];
}
- (void) rateChanged:(NSNotification*)aNote
{
    [rateField setStringValue:[NSString stringWithFormat:@"%ld/s",[model messageRate]]];
}

- (void) socketStatusChanged:(NSNotification*)aNote
{
    short status = [model socketStatus];
    NSString* s;
    switch (status){
        case NSStreamStatusNotOpen: s = @"Closed"; break;
        case NSStreamStatusOpening: s = @"Opening";break;
        case NSStreamStatusOpen:    s = @"Open";   break;
        case NSStreamStatusClosed:  s = @"Closed"; break;
        case NSStreamStatusError:   s = @"Error";  break;
        default: s = @"";
    }
    [socketStatusField setStringValue:s];
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
- (void) accessTypeChanged:(NSNotification*)aNotification
{
    [self updateRadioCluster:accessTypeMatrix setting:(int)[model accessType]];
    
    if([model accessType]==kUseInFluxHttpProtocol){
        [authTokenField setEnabled:YES];
        [bucketField    setEnabled:YES];
        [orgField            setEnabled:YES];
    }
    else {
        [authTokenField setEnabled:NO];
        [bucketField    setEnabled:NO];
        [orgField setEnabled:NO];
    }
}
- (void) inFluxDBLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORInFluxDBLock];
    [InFluxDBLockButton   setState: locked];
    [hostNameField        setEnabled:!locked];
    [portField            setEnabled:!locked];
    [authTokenField       setEnabled:!locked];
    [orgField             setEnabled:!locked];
    [bucketField          setEnabled:!locked];
    [accessTypeMatrix     setEnabled:!locked];
    [stealthModeButton    setEnabled:!locked];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORInFluxDBLock to:secure];
    [InFluxDBLockButton setEnabled: secure];
}


#pragma mark •••Actions
- (IBAction) stealthModeAction:(id)sender
{
    if(![model stealthMode]){
        NSString* s = [NSString stringWithFormat:@"Really disable the database?\n"];
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:s];
        [alert setInformativeText:@"There will be NO values automatically put in to the database if you activate this option."];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Yes, Disable Database"];
        [alert setAlertStyle:NSAlertStyleWarning];
        
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
            if(result == NSAlertSecondButtonReturn){
                [model setStealthMode:YES];
            }
            else [model setStealthMode:NO];

        }];
    }
    else [model setStealthMode:NO];
}
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
- (IBAction) accessTypeMatrixAction:(id)sender
{
    if ([model accessType] != [sender selectedTag]){
        [model setAccessType:(unsigned int)[sender selectedTag]];
    }
}

- (IBAction) testAction:(id)sender
{
    [model testPost];
}

@end


