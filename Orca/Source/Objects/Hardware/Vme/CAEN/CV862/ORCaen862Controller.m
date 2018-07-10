/*
 *  ORCaen862Controller.m
 *  Orca
 *
 *  Created by Mark Howe on Thurs May 29 2008.
 *  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
 *
 */
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

#import "ORCaen862Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen862Model.h"

@implementation ORCaen862Controller

#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"Caen862" ];
    return self;
}

- (NSSize) thresholdDialogSize
{
    return NSMakeSize(570,580);
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(iPedChanged:)
                         name : ORCaen862ModelIPedChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(eventCounterIncChanged:)
                         name : ORCaen862ModelEventCounterIncChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(slidingScaleEnableChanged:)
                         name : ORCaen862ModelSlidingScaleEnableChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(slideConstantChanged:)
                         name : ORCaen862ModelSlideConstantChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(zeroSuppressEnableChanged:)
                         name : ORCaen862ModelZeroSuppressEnableChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(zeroSuppressThresResChanged:)
                         name : ORCaen862ModelZeroSuppressThresResChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overflowSuppressEnableChanged:)
                         name : ORCaen862ModelOverflowSuppressEnableChanged
                        object: model];

}

#pragma mark ***Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self iPedChanged:nil];
    [self eventCounterIncChanged:nil];
    [self slidingScaleEnableChanged:nil];
    [self slideConstantChanged:nil];
    [self zeroSuppressEnableChanged:nil];
    [self zeroSuppressThresResChanged:nil];
    [self overflowSuppressEnableChanged:nil];
}

- (void) iPedChanged:(NSNotification*)aNote
{
    [iPedField setIntValue:[model iPed]];
}

- (void) eventCounterIncChanged:(NSNotification*)aNote
{
    [eventCounterIncMatrix selectCellWithTag: [model eventCounterInc]];
}
- (void) slideConstantChanged:(NSNotification*)aNote
{
    [slideConstantField setIntValue: [model slideConstant]];
}

- (void) slidingScaleEnableChanged:(NSNotification*)aNote
{
    [slidingScaleEnableMatrix selectCellWithTag: [model slidingScaleEnable]];
    [self setUpButtons];
}

- (void) zeroSuppressThresResChanged:(NSNotification*)aNote
{
    [zeroSuppressThresResMatrix selectCellWithTag: [model zeroSuppressThresRes]];
}

- (void) zeroSuppressEnableChanged:(NSNotification*)aNote
{
    [zeroSuppressEnableMatrix selectCellWithTag: [model zeroSuppressEnable]];
}

- (void) overflowSuppressEnableChanged:(NSNotification*)aNote
{
    [overflowSuppressEnableMatrix selectCellWithTag: [model overflowSuppressEnable]];
}

- (void) thresholdLockChanged:(NSNotification*)aNotification
{
    [self setUpButtons];
}

- (void) setUpButtons
{
    BOOL runInProgress              = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self thresholdLockName]];
    BOOL locked                     = [gSecurity isLocked:[self thresholdLockName]];
    
    [thresholdLockButton setState: locked];
    
    [thresholdA setEnabled:!lockedOrRunningMaintenance];
    [stepperA setEnabled:!lockedOrRunningMaintenance];
    
    [thresholdWriteButton setEnabled:!lockedOrRunningMaintenance];
    [thresholdReadButton setEnabled:!lockedOrRunningMaintenance];
    
    [eventCounterIncMatrix        setEnabled: !lockedOrRunningMaintenance];
    [iPedField                    setEnabled: !lockedOrRunningMaintenance];
    [slideConstantField           setEnabled: !lockedOrRunningMaintenance && ![model slidingScaleEnable]];
    [slidingScaleEnableMatrix     setEnabled: !lockedOrRunningMaintenance];
    [zeroSuppressThresResMatrix   setEnabled: !lockedOrRunningMaintenance];
    [zeroSuppressEnableMatrix     setEnabled: !lockedOrRunningMaintenance];
    [overflowSuppressEnableMatrix setEnabled: !lockedOrRunningMaintenance];

    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:[self thresholdLockName]])s = @"Not in Maintenance Run.";
    }
    [thresholdLockDocField setStringValue:s];
}

#pragma mark ***Interface Management - Module specific
- (NSString*) thresholdLockName {return @"ORCaen862ThresholdLock";}
- (NSString*) basicLockName     {return @"ORCaen862BasicLock";}

#pragma mark •••Actions
- (IBAction) iPedAction:(id)sender
{
    [model setIPed:[sender intValue]];
}

- (IBAction) eventCounterIncAction:(id)sender
{
    [model setEventCounterInc:[[sender selectedCell]tag]];
}
- (IBAction) slideConstantAction:(id)sender
{
    [model setSlideConstant:[sender intValue]];
}
- (IBAction) slidingScaleEnableAction:(id)sender
{
    [model setSlidingScaleEnable:[[sender selectedCell]tag]];
}
- (IBAction) zeroSuppressThresResAction:(id)sender
{
    [model setZeroSuppressThresRes:[[sender selectedCell]tag]];
}
- (IBAction) zeroSuppressEnableAction:(id)sender
{
    [model setZeroSuppressEnable:[[sender selectedCell]tag]];
}

- (IBAction) overflowSuppressEnableAction:(id)sender
{
    [model setOverflowSuppressEnable:[[sender selectedCell]tag]];
}
@end
