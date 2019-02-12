//--------------------------------------------------------
// ORADEIControlController
// Created by A. Kopmann on Feb 8, 2019
// Copyright (c) 2017, University of North Carolina. All rights reserved.
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

#import "ORADEIControlController.h"
#import "ORADEIControlModel.h"
#import "ORValueBarGroupView.h"
#import "ORAxis.h"

#define kSecsBetween1904and1070 2082844800

@implementation ORADEIControlController

#pragma mark ***Initialization
- (id) init
{
	self = [super initWithWindowNibName:@"ADEIControl"];
	return self;
}

- (void) awakeFromNib
{
    [[queueValueBar xAxis] setRngLimitsLow:0 withHigh:300 withMinRng:10];
    [[queueValueBar xAxis] setRngDefaultsLow:0 withHigh:300];
    
	[super awakeFromNib];
}

#pragma mark ***Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];

    [notifyCenter addObserver : self
                     selector : @selector(sensorGroupChanged:)
                         name : ORADEIControlModelSensorGroupChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORADEIControlModelIpAddressChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(isConnectedChanged:)
                         name : ORADEIControlModelIsConnectedChanged
						object: model];
	   

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORADEIControlLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(setPointChanged:)
                         name : ORADEIControlModelSetPointChanged
                        object: model];
 
    [notifyCenter addObserver : self
                     selector : @selector(setPointFileChanged:)
                         name : ORADEIControlModelSetPointFileChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(measuredValuesChanged:)
                         name : ORADEIControlModelMeasuredValuesChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(setPointsReadBackChanged:)
                         name : ORADEIControlModelReadBackChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(queCountChanged:)
                         name : ORADEIControlModelQueCountChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(verboseChanged:)
                         name : ORADEIControlModelVerboseChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(showFormattedDatesChanged:)
                         name : ORADEIControlModelShowFormattedDatesChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(desiredSetPointAdded:)
                         name : ORADEIControlModelDesiredSetPointAdded
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(desiredSetPointRemoved:)
                         name : ORADEIControlModelDesiredSetPointRemoved
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updatePostRegulationTable)
                         name : ORADEIControlModelUpdatePostRegulationTable
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(postRegulationFileChanged:)
                         name : ORADEIControlModelPostRegulationFileChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORADEIControlModelPollTimeChanged
                       object : nil];
    
    
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"ADEI Control (Unit %u)",[model uniqueIdNumber]]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
    [self setPointChanged:nil];
    [self setPointFileChanged:nil];
    
    [self measuredValuesChanged:nil];
	[self setPointsReadBackChanged:nil];
	[self queCountChanged:nil];
    
    [self sensorGroupChanged:nil];
    [self ipAddressChanged:nil];
    [self verboseChanged:nil];
	[self isConnectedChanged:nil];
    [self showFormattedDatesChanged:nil];
    [self postRegulationFileChanged:nil];
    [self pollTimeChanged:nil];
}


- (void) sensorGroupChanged:(NSNotification*)aNote
{
    [sensorGroupPU selectItemWithTag:[model sensorGroup]];
}


- (void) pollTimeChanged:(NSNotification*)aNote
{
    [pollTimePU selectItemWithTag:[model pollTime]];
    if([model pollTime]){
        [progressWheel startAnimation:nil];
        [progressWheel setHidden:NO];
    }
    else                {
        [progressWheel stopAnimation:nil];
        [progressWheel setHidden:YES];
    }
}

- (void) postRegulationFileChanged:(NSNotification*)aNote
{
    [postRegulationFileField setStringValue:[[model postRegulationFile] stringByAbbreviatingWithTildeInPath] ];
}
- (void) desiredSetPointAdded:(NSNotification*)aNote
{
    [postRegulationTableView reloadData];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:[model numDesiredSetPoints]];
    [postRegulationTableView selectRowIndexes:indexSet byExtendingSelection:NO];
    [self setButtonStates];
}

- (void) desiredSetPointRemoved:(NSNotification*)aNote
{
    int index = [[[aNote userInfo] objectForKey:@"Index"] intValue];
    index = MIN(index,(int)[model numDesiredSetPoints]-1);
    index = MAX(index,0);
    [postRegulationTableView reloadData];
    NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
    [postRegulationTableView selectRowIndexes:indexSet byExtendingSelection:NO];
    [self setButtonStates];
}

- (void) updatePostRegulationTable
{
    [postRegulationTableView reloadData];
}

- (void) isConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedTextField setStringValue: [model isConnected]?@"Connected":@"Not Connected"];
    [ipConnectButton setTitle:[model isConnected]?@"Disconnect":@"Connect"];
}

- (void) showFormattedDatesChanged:(NSNotification*)aNote
{
    [showFormattedDatesCB setIntValue: [model showFormattedDates]];
    [setPointTableView reloadData];
    [measuredValueTableView reloadData];

}
- (void) verboseChanged:(NSNotification*)aNote
{
    [verboseCB setIntValue: [model verbose]];
}
- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
	[[self window] setTitle:[model title]];
}

- (void) queCountChanged:(NSNotification*)aNotification
{
	[cmdQueCountField setIntegerValue:[model queCount]];
    [queueValueBar setNeedsDisplay:YES];
}

- (void) setPointChanged:(NSNotification*)aNote
{
	[setPointTableView reloadData];
}

- (void) setPointFileChanged:(NSNotification*)aNote
{
    [setPointFileField setStringValue:[model setPointFile]];
}

- (void) measuredValuesChanged:(NSNotification*)aNote
{
    [measuredValueTableView reloadData];
    
    [expertPCControlOnlyField setStringValue:[model expertPCControlOnly] ? @"Ony Expert PC Can Set Values":@""];
    [zeusHasControlField setStringValue:     [model zeusHasControl]      ? @"ZEUS has control":@""];
    [orcaHasControlField setStringValue:     [model orcaHasControl]      ? @"ORCA has control":@""];
}

- (void) setPointsReadBackChanged:(NSNotification*)aNote
{
	[setPointTableView reloadData];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORADEIControlLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORADEIControlLock];
    [lockButton setState: locked];
    [self setButtonStates];
}

#pragma mark ***Actions
- (IBAction) writeSetpointsAction:(id)sender
{
    [model writeSetpoints];
    [self lockChanged:nil];
}

- (IBAction) readBackSetpointsAction:(id)sender
{
    [model readBackSetpoints];
    [self lockChanged:nil];
}

- (IBAction) readMeasuredValuesAction:(id)sender
{
    [model readMeasuredValues];
    [self lockChanged:nil];
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORADEIControlLock to:[sender intValue] forWindow:[self window]];
}

- (void) ipAddressFieldAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];
}

- (IBAction) connectAction: (id) aSender
{
    [self endEditing];
    [model connect];
}

- (IBAction) addDesiredSetPoint: (id) aSender
{
    [model addDesiredSetPoint];
}

- (IBAction) removeDesiredSetPoint: (id) aSender
{
    NSIndexSet* theSet = [postRegulationTableView selectedRowIndexes];
    NSUInteger current_index = [theSet firstIndex];
    if(current_index != NSNotFound){
        [model removeDesiredSetPointAtIndex:(int)current_index];
    }
    [self setButtonStates];
}

- (void) setButtonStates
{
    BOOL locked = [gSecurity isLocked:ORADEIControlLock];
    [readPostRegulationButton           setEnabled:    !locked];
    [addDesiredSetPointButton       setEnabled:    !locked];
    [removeDesiredSetPointButton    setEnabled: !locked];
    [readSetPointFileButton             setEnabled:!locked];
    [writeAllSetPointsButton            setEnabled:!locked];
    [setPointTableView                  setEnabled:!locked];
}

#pragma mark ***Table Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
    if(setPointTableView == aTableView){
       NSString *sensorName = (NSString *)[model setPointItem:(int)rowIndex forKey:@"data"];

       if([[aTableColumn identifier] isEqualToString:@"index"]){
            return  [NSNumber numberWithInteger:rowIndex];
        }
        else {
            if([model showFormattedDates] &&
               ([[aTableColumn identifier] isEqualToString:@"readBack"] &&
               [sensorName rangeOfString:@"Timestamp"].location != NSNotFound)){
                
                NSTimeInterval s = [[model setPointItem:(int)rowIndex forKey:@"readBack"]doubleValue] - kSecsBetween1904and1070;
                if(s<1)return @"?";
                NSDate* theDate = [NSDate dateWithTimeIntervalSince1970:s];
                NSDateFormatter* dateFormat = [[[NSDateFormatter alloc] init] autorelease];
                [dateFormat setDateFormat:@"dd/MM HH:mm:ss"];
                
                return [dateFormat stringFromDate:theDate];
            }
            else return [model setPointItem:(int)rowIndex forKey:[aTableColumn identifier]];
        }
    }
    else if(measuredValueTableView == aTableView){
        NSString *sensorName = (NSString *)[model measuredValueItem:(int)rowIndex forKey:@"data"];

        if([[aTableColumn identifier] isEqualToString:@"index"]){
            return  [NSNumber numberWithInt:(int)rowIndex];
        }
        else {
            if([model showFormattedDates] &&
               ([[aTableColumn identifier] isEqualToString:@"value"] &&
               [sensorName rangeOfString:@"Timestamp"].location != NSNotFound)){

                NSTimeInterval s = [[model measuredValueItem:(int)rowIndex forKey:@"value"]doubleValue] - kSecsBetween1904and1070;
                if(s<1)return @"?";

                NSDate* theDate = [NSDate dateWithTimeIntervalSince1970:s];
                NSDateFormatter* dateFormat = [[[NSDateFormatter alloc] init] autorelease];
                [dateFormat setDateFormat:@"dd/MM HH:mm:ss"];
                return [dateFormat stringFromDate:theDate];
            }

            else return [model measuredValueItem:(int)rowIndex forKey:[aTableColumn identifier]];
        }
    }
    else if(postRegulationTableView == aTableView){
        if([[aTableColumn identifier] isEqualToString:@"index"]){
            return  [NSNumber numberWithInt:(int)rowIndex];
        }
        else {
            return [[model desiredSetPointAtIndex:(int)rowIndex] objectForKey:[aTableColumn identifier]];
        }
    }
    else return nil;
}

// just returns the number of items we have.
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(setPointTableView == aTableView)return [model numSetPoints];
    else if(measuredValueTableView == aTableView)return [model numMeasuredValues];
    else if(postRegulationTableView == aTableView)return [model numDesiredSetPoints];
	else return 0;
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(anObject == nil)return;
    
    if(setPointTableView == aTableView){
        if([[aTableColumn identifier] isEqualToString:@"item"]) return;
        if([[aTableColumn identifier] isEqualToString:@"data"]) return;
        if([[aTableColumn identifier] isEqualToString:@"readback"]) return;
        if([[aTableColumn identifier] isEqualToString:@"setPoint"]){
            [model setSetPoint:(int)rowIndex  withValue:[anObject floatValue]];
            return;
        }
    }
    else if(postRegulationTableView == aTableView){
        id aPoint = [model desiredSetPointAtIndex:(int)rowIndex];
        [aPoint setValue:anObject forKey:[aTableColumn identifier]];
    }
}


- (IBAction) sensorGroupAction: (id)sender
{
    [model setSensorGroup:(int)[[sender selectedItem]tag]];
}

- (IBAction) readSetPointFile:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[model setPointFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
    }
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model readSetPointsFile:[[openPanel URL] path]];
        }
    }];
}

- (IBAction) flushQueueAction: (id) sender
{
    [model flushQueue];
}
- (IBAction) verboseAction: (id) sender
{
    [model setVerbose:[sender intValue]];
}

- (IBAction) showFormatedDatedAction: (id) sender
{
    [model setShowFormattedDates:[sender intValue]];
}

- (IBAction) saveSetPointFile:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[model setPointFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = [model setPointFile];
        
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model saveSetPointsFile:[[savePanel URL]path]];
        }
    }];
}
- (IBAction) pushReadBacksToSetPointsAction:(id)sender
{
    [model pushReadBacksToSetPoints];
}

- (IBAction) savePostRegulationScaleFactors: (id) aSender
{
    [self endEditing];
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
    NSString* fullPath = [[model postRegulationFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = [model setPointFile];
        
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model savePostRegulationFile:[[savePanel URL]path]];
        }
    }];
}
- (IBAction) readPostRegulationScaleFactors:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
    NSString* fullPath = [[model postRegulationFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
    }
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model readPostRegulationFile:[[openPanel URL] path]];
        }
    }];
}
- (IBAction) pollTimeAction: (id) aSender
{
    [model setPollTime:(int)[[aSender selectedItem]tag]];
}

#pragma  mark ***Delegate Responsiblities
- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	return YES;
}
@end
