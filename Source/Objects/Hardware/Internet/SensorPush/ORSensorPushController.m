//-------------------------------------------------------------------------
//  ORSensorPushController.h
//
//  Created by Mark Howe on Friday 08/04/2023.
//  Copyright (c) 2023 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORSensorPushController.h"
#import "ORSensorPushModel.h"

@implementation ORSensorPushController

-(id)init
{
    self = [super initWithWindowNibName:@"SensorPush"];
    return self;
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle: [NSString stringWithFormat:@"SensorPush %u",[model uniqueIdNumber]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(userNameChanged:)
                         name : ORSensorPushUserNameChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(passwordChanged:)
                         name : ORSensorPushPasswordChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORSensorPushLock
                       object : model];
 
    [notifyCenter addObserver : self
                     selector : @selector(sensorListChanged:)
                         name : ORSensorPushListChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(sensorDataChanged:)
                         name : ORSensorPushDataChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(pollingTimesChanged:)
                         name : ORSensorPushPollingTimesChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(runningChanged:)
                         name : ORSensorPushThreadRunningChanged
                        object: model];
    
    
}

- (void) updateWindow
{
	[super updateWindow];
	[self userNameChanged:nil];
	[self passwordChanged:nil];
    [self sensorListChanged:nil];
    [self sensorDataChanged:nil];
    [self pollingTimesChanged:nil];
    [self runningChanged:nil];

    [self lockChanged:nil];
}

#pragma mark •••Interface Management

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked            = [gSecurity isLocked:ORSensorPushLock];
    [userNameField setEnabled:!locked];
    [passwordField setEnabled: !locked];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORSensorPushLock to:secure];
    [lockButton setEnabled: secure];
}

- (void) runningChanged:(NSNotification*)aNote
{
    [pollingField setStringValue:[model isRunning]?@"Polling":@""];
}

- (void) passwordChanged:(NSNotification*)aNote
{
	[passwordField setStringValue: [model password]];
}

- (void) userNameChanged:(NSNotification*)aNote
{
	[userNameField setStringValue: [model userName]];
}

- (void) pollingTimesChanged:(NSNotification*)aNote
{
    [lastPolledField setObjectValue:[model lastTimePolled]];
    [nextPollField setObjectValue:[model nextPollScheduled]];
}

- (void) sensorListChanged:(NSNotification*)aNote
{
    [sensorList reloadData];
}

- (void) sensorDataChanged:(NSNotification*)aNote
{
    [sensorTable reloadData];
}

#pragma mark •••TableView Data Source Methods
//NSDictionary *firstParent = @{@"parent": @"Foo", @"children": @[@"Foox", @"Fooz"]};
//NSDictionary *secondParent = @{@"parent": @"Bar", @"children": @[@"Barx", @"Barz"]};
//NSArray *list = @[firstParent, secondParent];

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [model numOfSensors];
}

- (id) tableView:(NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)i
{
    id obj = [model getSensor:i value:[tableColumn identifier]];
    return obj;
}

#pragma mark •••Outline Data Source Methods
-(BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([item isKindOfClass:[ORNode class]])return [item count]>0;
    else return NO;
}

-(NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) { //item is nil for root level items
        return [[model sensorTree] count];
    }
    else if ([item isKindOfClass:[ORNode class]]) {
        return [item count];
    }
    else return 0;
}

-(id) outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(ORNode*)item
{
    if (item == nil) { //item is nil when the outline view wants to inquire for root level items
        return [[model sensorTree] childAt:index];
    }
    else if ([item isKindOfClass:[ORNode class]]) {
        return [item childAt:index];
    }
    return nil;
}

-(id) outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)theColumn byItem:(id)item
{
    if([[theColumn identifier] isEqualToString:@"name"]){
        return [item name];
    }
    else {
        return [item description];
    }
}

#pragma mark •••Actions

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORSensorPushLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) passwordAction:(id)sender
{
	[model setPassword:[sender stringValue]];
}

- (IBAction) userNameAction:(id)sender
{
	[model setUserName:[sender stringValue]];
}

- (IBAction) requestSensorData:(id)sender
{
    [model requestSensorData];
}


- (IBAction) requestGatewaysAction:(id)sender
{
    [model requestGatewayList];
}
@end

