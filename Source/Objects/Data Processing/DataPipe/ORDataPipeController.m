//
//  ORDataPipeController.m
//  Orca
//
//  Created by Mark Howe on Wed Feb 15, 2017.
//  Copyright (c) 2017 University of North Carolina. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORDataPipeController.h"
#import "ORDataPipeModel.h"
#import "ORRunModel.h"

@implementation ORDataPipeController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"DataPipe"];
	return self;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORDataPipeLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(pipeNameChanged:)
                         name : ORDataPipeNameChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(readerPathChanged:)
                         name : ORDataPipeReaderPathChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateStatus:)
                         name : ORDataPipeUpdate
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(setupRunTypeNames:)
                         name : ORDataPipeLoadRunTypeNames
                       object : nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runTypeChanged:)
                         name: ORDataPipeTypeChangedNotification
                       object: model];
    
}

- (void) awakeFromNib
{
     [super awakeFromNib];

    int i=0;
    int row;
    int column;
    for(row=0;row<4;row++){
        for(column=0;column<4;column++){
            [[runTypeMatrix cellAtRow:row column:column] setTag:i];
            i++;
        }
    }
}

- (void) runTypeChanged:(NSNotification *)notification
{
    uint32_t runType = [model runType];
    int i;
    for(i=0;i<32;i++){
        [[runTypeMatrix cellWithTag:i] setState:(runType &(1L<<i))!=0];
    }
}

- (void) setupRunTypeNames:(NSNotification*)aNote
{
    NSArray* theNames = [[model runModel] runTypeNames];
    NSUInteger n = [theNames count];
    int i;
    [[runTypeMatrix cellWithTag:0] setTitle:@"DAQExpertMode"];
    if(n){
        for(i=1;i<n;i++){
            [[runTypeMatrix cellWithTag:i] setTitle:[theNames objectAtIndex:i]];
        }
    }
    else {
        for(i=1;i<32;i++){
            [[runTypeMatrix cellWithTag:i] setTitle:[NSString stringWithFormat:@"Bit %d",i]];
        }
    }
}

#pragma mark •••Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self pipeNameChanged:nil];
    [self readerPathChanged:nil];
    [self updateStatus:nil];
    [self runTypeChanged:nil];
    [self setupRunTypeNames:nil];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORDataPipeLock];
    BOOL runInProgress  = [gOrcaGlobals runInProgress];
    [lockButton setState: locked];
    [pipeNameField setEnabled:!locked && !runInProgress];
    [readerPathField setEnabled:!locked && !runInProgress];
    [runTypeMatrix setEnabled:!locked && !runInProgress];
}

- (void) updateStatus:(NSNotification*)aNotification
{
    float rate = [model sendRate];
    if(rate>1E6)[byteCountField setStringValue:[NSString stringWithFormat:@"%.2f MB/s",rate/1E6]];
    else if(rate>1E3)[byteCountField setStringValue:[NSString stringWithFormat:@"%.2f KB/s",rate/1E3]];
    else [byteCountField setStringValue:[NSString stringWithFormat:@"%.2f B/s",rate]];
    if(![model validRunType]) [runTypeValidField setStringValue:@"Run Type Prohibits Sending"];
    else                      [runTypeValidField setStringValue:@""];
    [runStatusField setStringValue: [model runInProgress]?@"Running":@"NOT Running"];
    BOOL readerRunning = [model readerIsRunning];
    [readerStatusField setStringValue:readerRunning?@"Running":@"NOT Running"];
}

- (void) pipeNameChanged:(NSNotification*)aNotification
{
    [pipeNameField setStringValue:[model pipeName]];
}

- (void) readerPathChanged:(NSNotification*)aNotification
{
    [readerPathField setStringValue:[model readerPath]];
}

#pragma mark •••Actions
- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORDataPipeLock to:secure];
    [lockButton setEnabled:secure];
}
- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORDataPipeLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) readerPathAction:(id) sender
{
    [model setReaderPath:[sender stringValue]];
}

- (IBAction) pipeNameAction:(id) sender
{
    [model setPipeName:[sender stringValue]];
}

- (IBAction) runTypeAction:(id)sender
{
    uint32_t aMask = 0;
    int i;
    for(i=0;i<32;i++){
        if([[runTypeMatrix cellWithTag:i] intValue])aMask |= (1<<i);
    }
    [model setRunType:aMask];
}

@end
