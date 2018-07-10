/*
 *  ORCV812Controller.m
 *  Orca
 *
 *  Created by Mark Howe on Tuesday, June 7, 2011.
 *  Copyright (c) 2011 CENPA, University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sonsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORCV812Controller.h"
#import "ORCV812Model.h"

@implementation ORCV812Controller

#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"CV812" ];
    return self;
}

- (NSString*) dialogLockName {return @"ORCV812ThresholdLock";}

#pragma mark ***Interface Management
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
	
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[notifyCenter addObserver : self
                     selector : @selector(deadTime0_7Changed:)
                         name : ORCV812ModelDeadTime0_7Changed
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(deadTime8_15Changed:)
                         name : ORCV812ModelDeadTime8_15Changed
						object: model];
}

#pragma mark ***Interface Management
- (void) updateWindow
{
	[super updateWindow];
	[self deadTime0_7Changed:nil];
	[self deadTime8_15Changed:nil];
}

- (void) deadTime0_7Changed:(NSNotification*)aNote
{
	[deadTime0_7Field setIntValue:[model deadTime0_7]];			
}

- (void) deadTime8_15Changed:(NSNotification*)aNote
{
	[deadTime8_15Field setIntValue:[model deadTime8_15]];			
}

- (void) thresholdLockChanged:(NSNotification*)aNotification
{
	[super thresholdLockChanged:aNotification];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self dialogLockName]];
	[deadTime0_7Field setEnabled:!lockedOrRunningMaintenance]; 
    [deadTime8_15Field setEnabled:!lockedOrRunningMaintenance]; 
}	


#pragma mark ***Actions
- (IBAction) deadTime0_7Action:(id)sender
{
	[model setDeadTime0_7:[sender intValue]];
}

- (IBAction) deadTime8_15Action:(id)sender
{
	[model setDeadTime8_15:[sender intValue]];
}

@end
