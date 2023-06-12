//
//  ORLNGSSlowControlsController.m
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORLNGSSlowControlsController.h"
#import "ORLNGSSlowControlsModel.h"
#
@implementation ORLNGSSlowControlsController
- (id) init
{
    self = [super initWithWindowNibName: @"LNGSSlowControls" ];
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) awakeFromNib
{
    [statusTable reloadData];
    [self reloadDataTables:nil];
	[super awakeFromNib];
}

- (void) reloadDataTables:(NSNotification*)aNote
{
    [muonTable   reloadData];
    [siPMTable   reloadData];
    [diodeTable  reloadData];
    [sourceTable reloadData];
    
    [LlamaField setStringValue:[[model cmd:@"Llama"   dataAtRow:0 column:0] isEqualToString:@"1"]?@"ON":@"OFF"];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORLNGSSlowControlsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORLNGSSlowControlsPollTimeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(userNameChanged:)
                         name : ORL200SlowControlsUserNameChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(cmdPathChanged:)
                         name : ORL200SlowControlsCmdPathChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORL200SlowControlsIPAddressChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(statusChanged:)
                         name : ORL200SlowControlsStatusChanged
                        object: model];
 
    [notifyCenter addObserver : self
                     selector : @selector(reloadDataTables:)
                         name : ORL200SlowControlsDataChanged
                        object: model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(inFluxAvailablityChanged:)
                         name : ORL200SlowControlsInFluxChanged
                       object : nil];
}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
    [self userNameChanged:nil];
    [self cmdPathChanged:nil];
    [self pollTimeChanged:nil];
    [self ipAddressChanged:nil];
    [self statusChanged:nil];
    [self inFluxAvailablityChanged:nil];
	[self updateButtons];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORLNGSSlowControlsLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) inFluxAvailablityChanged:(NSNotification*)aNote
{
    bool influxDBAvailable = [model inFluxDBAvailable];
    [inFluxAvailableField setStringValue:influxDBAvailable?@"Available":@"Not in Config"];
    [inFluxAvailableField setTextColor:influxDBAvailable?[NSColor greenColor]:[NSColor redColor]];
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePopup selectItemWithTag: [model pollTime]];
	if([model pollTime])[pollingProgress startAnimation:self];
	else [pollingProgress stopAnimation:self];
}

- (void) statusChanged:(NSNotification*)aNote
{
    [statusTable reloadData];
}

- (void) userNameChanged:(NSNotification*)aNote
{
    [userNameField setStringValue:[model userName]];
}

- (void) cmdPathChanged:(NSNotification*)aNote
{
    [cmdPathField setStringValue:[model cmdPath]];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
    [ipAddressField setStringValue:[model ipAddress]];
}

#pragma mark •••Notifications

- (void) updateButtons
{
    //BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORLNGSSlowControlsLock];
	
    [lockButton setState: locked];
	
    [userNameField      setEnabled: !locked];
    [cmdPathField       setEnabled: !locked];
    [ipAddressField     setEnabled: !locked];
    [pollTimePopup      setEnabled: !locked];
    [pollNowButton      setEnabled: !locked];
}

- (NSString*) windowNibName
{
	return @"LNGSSlowControls";
}

#pragma mark •••Actions
- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:(int)[[sender selectedItem] tag]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORLNGSSlowControlsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) pollNowAction:(id)sender
{
	[model pollHardware];
}

- (IBAction) userNameAction:(id)sender
{
    [model setUserName:[userNameField stringValue]];
}

- (IBAction) cmdPathAction:(id)sender
{
    [model setCmdPath:[cmdPathField stringValue]];
}

- (IBAction) ipAddressAction:(id)sender
{
    [model setIPAddress:[ipAddressField stringValue]];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
    if(aTableView == statusTable){
        id aCmd = [model cmdAtIndex:rowIndex];
        if([[aTableColumn identifier] isEqualToString:@"name"]){
            return aCmd;
        }
        else {
            return [model cmdValue:aCmd key:[aTableColumn identifier]];
        }
    }
    else {
        int col = (int)[[aTableView tableColumns] indexOfObject:aTableColumn];
        if(     aTableView == muonTable)   return [model cmd:@"Muon"   dataAtRow:(int)rowIndex column:col];
        else if(aTableView == diodeTable)  return [model cmd:@"Diode"  dataAtRow:(int)rowIndex column:col];
        else if(aTableView == siPMTable)   return [model cmd:@"SiPM"   dataAtRow:(int)rowIndex column:col];
        else if(aTableView == sourceTable) return [model cmd:@"Source" dataAtRow:(int)rowIndex column:col];
        else return @"";
    }
    return @"";
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == statusTable)      return [model cmdListCount];
    else if(aTableView == muonTable)   return [[model cmdValue:@"Muon"   key:kCmdData]count];
    else if(aTableView == diodeTable)  return [[model cmdValue:@"Diode"  key:kCmdData]count];
    else if(aTableView == siPMTable)   return [[model cmdValue:@"SiPM"   key:kCmdData]count];
    else if(aTableView == sourceTable) return [[model cmdValue:@"Source" key:kCmdData]count];
    return 0;
}
@end
