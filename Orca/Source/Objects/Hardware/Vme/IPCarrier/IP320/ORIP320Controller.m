//
//  ORIP320Controller.m
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORIP320Controller.h"
#import "ORIP320Model.h"
#import "ORIP320Channel.h"
#import "ORTimeMultiPlot.h"
#import "ORDataSet.h"

@implementation ORIP320Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"IP320"];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [blankView release];
    [super dealloc];
}

- (void) awakeFromNib
{
    adcValueSize    = NSMakeSize(380,452);
    calibrationSize = NSMakeSize(520,430);
    alarmSize       = NSMakeSize(490,443);
	dataSize        = NSMakeSize(390,443);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORIP320%d%d%d.selectedtab",[model crateNumber],[model slot],[model slotConv]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	
    [[[valueTable1 tableColumnWithIdentifier:k320ChannelReadEnabled ]dataCell]setControlSize:NSSmallControlSize];
    [[[valueTable2 tableColumnWithIdentifier:k320ChannelReadEnabled ]dataCell]setControlSize:NSSmallControlSize];
	
	
    [[[alarmTable1 tableColumnWithIdentifier:k320ChannelAlarmEnabled ]dataCell]setControlSize:NSSmallControlSize];
    [[[alarmTable2 tableColumnWithIdentifier:k320ChannelAlarmEnabled ]dataCell]setControlSize:NSSmallControlSize];
	
    
    [[[calibrationTable1 tableColumnWithIdentifier:k320ChannelGain ]dataCell]setControlSize:NSSmallControlSize];
    [[[calibrationTable2 tableColumnWithIdentifier:k320ChannelGain ]dataCell]setControlSize:NSSmallControlSize];
    [[[calibrationTable1 tableColumnWithIdentifier:k320ChannelGain ]dataCell]setFont:[NSFont systemFontOfSize:10]];
    [[[calibrationTable2 tableColumnWithIdentifier:k320ChannelGain ]dataCell]setFont:[NSFont systemFontOfSize:10]];
    
    
    int i;
    int val = 1;
    for(i=0;i<4;i++){
        id popupCell = [[calibrationTable1 tableColumnWithIdentifier:k320ChannelGain ]dataCell];
        [popupCell addItemWithTitle:[NSString stringWithFormat:@"%d",val]];
        popupCell = [[calibrationTable2 tableColumnWithIdentifier:k320ChannelGain ]dataCell];
        [popupCell addItemWithTitle:[NSString stringWithFormat:@"%d",val]];
        val *= 2;
	}
	
    [outlineView setDoubleAction:@selector(doubleClick:)];
    [multiPlotView setDoubleAction:@selector(doubleClickMultiPlot:)];
	[splitView loadLayoutWithName:[NSString stringWithFormat:@"IP320-%lu",[model uniqueIdNumber]]];
	[plotGroupButton setEnabled:NO];    
	
    [super awakeFromNib];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(pollingStateChanged:)
                         name : ORIP320PollingStateChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(valuesChanged:)
                         name : ORIP320AdcValueChangedNotification
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORVmeCardSlotChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(displayRawChanged:)
                         name : ORIP320ModelDisplayRawChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(modeChanged:)
                         name : ORIP320ModelModeChanged
						object: model];
    [notifyCenter addObserver : self
                     selector : @selector(logToFileChanged:)
                         name : ORIP320ModelLogToFileChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(logFileChanged:)
                         name : ORIP320ModelLogFileChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(shipRecordsChanged:)
                         name : ORIP320ModelShipRecordsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(cardJumperSettingChanged:)
                         name : ORIP320ModelCardJumperSettingChanged
						object: model];
	
    
    [notifyCenter addObserver : self
                     selector : @selector(multiPlotsChanged:)
                         name : ORIP320ModelMultiPlotsChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(multiPlotsChanged:)
                         name : ORMultiPlotDataSetItemsChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(multiPlotsChanged:)
                         name : ORMultiPlotNameChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(outlineViewSelectionDidChange:)
                         name : NSOutlineViewSelectionDidChangeNotification
                       object : outlineView];
	
	[notifyCenter addObserver : self
                     selector : @selector(dataChanged:)
                         name : ORDataSetDataChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(calibrationDateChanged:)
                         name : ORIP320ModelCalibrationDateChanged
						object: model];
	
}


#pragma mark ¥¥¥Accessors
- (void) setModel:(id)aModel
{    
    [super setModel:aModel];
    [outlineView setDoubleAction:@selector(doubleClick:)];
    [multiPlotView setDoubleAction:@selector(doubleClickMultiPlot:)];
    [outlineView setDataSource:aModel];
    [self updateWindow];
}


#pragma mark ¥¥¥Interface Management

- (void) calibrationDateChanged:(NSNotification*)aNote
{
	[calibrationDateField setObjectValue: [model calibrationDate]];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    if([notification object] == outlineView){
        NSMutableArray *selection = [NSMutableArray arrayWithArray:[outlineView allSelectedItems]];
		
        int validCount = 0;
        int i;
        for(i=0;i<[selection count];i++){
            id aDataSet = [selection objectAtIndex:i];
            if([aDataSet leafNode]){
                id obj = [aDataSet data];
                if([obj canJoinMultiPlot]){
                    validCount++;
                }
            }
        }
        [plotGroupButton setEnabled:validCount];
    }
}
- (void) multiPlotsChanged:(NSNotification*)aNotification
{
	[multiPlotView reloadData];
}

- (void) dataChanged:(NSNotification*)aNotification
{
    if(!scheduledToUpdate2){
        [self performSelector:@selector(doDataUpdate) withObject:nil afterDelay:1.0];
        scheduledToUpdate2 = YES;
    }
}

- (void) doDataUpdate
{
    scheduledToUpdate2 = NO;
    [outlineView reloadData];
    [multiPlotView reloadData];
    //[outlineView reloadItem:[model dataSet] reloadChildren:YES];
}

- (void) doUpdate
{
    scheduledToUpdate1 = NO;
    [outlineView reloadData];
    [multiPlotView reloadData];
    //[outlineView reloadItem:[model dataSet] reloadChildren:YES];
}

- (void) shipRecordsChanged:(NSNotification*)aNote
{
	[shipRecordsButton setIntValue: [model shipRecords]];
}

- (void) logFileChanged:(NSNotification*)aNote
{
	if([model logFile])[logFileTextField setStringValue: [model logFile]];
	else [logFileTextField setStringValue: @"---"];
}

- (void) logToFileChanged:(NSNotification*)aNote
{
	[logToFileButton setIntValue: [model logToFile]];
}

- (void) displayRawChanged:(NSNotification*)aNote
{
	[displayRawCB setIntValue: [model displayRaw]];
	[valueTable1 reloadData];
	[valueTable2 reloadData];
}

- (void) updateWindow
{
    [super updateWindow];
    [self modelChanged:nil];
    [self dataChanged:nil];
    [self pollingStateChanged:nil];
	[self valuesChanged:nil];
	[self slotChanged:nil];
	[self modeChanged:nil];
	[self displayRawChanged:nil];
	[self logToFileChanged:nil];
	[self logFileChanged:nil];
	[self shipRecordsChanged:nil];
	[self cardJumperSettingChanged:nil];
	[self calibrationDateChanged:nil];
}

- (void) modelChanged:(NSNotification*)aNotification
{
    if(!aNotification || [aNotification object] == self){
        //[outlineView reloadItem:[model dataSet] reloadChildren:YES];
        [outlineView reloadData];
        [multiPlotView reloadData];
    }
}

- (void) cardJumperSettingChanged:(NSNotification*)aNotification
{
	[jumperSettingsPU selectItemWithTag:[model cardJumperSetting]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"IP320 (%@)",[model identifier]]];
}

- (void) modeChanged:(NSNotification*)aNotification
{
	[modePopUpButton selectItemWithTag:[model mode]];
	[valueTableScrollView setHidden:![model mode]];
	[calibrationTableScrollView setHidden:![model mode]];
	[alarmTableScrollView setHidden:![model mode]];
	
}

- (void) valuesChanged:(NSNotification*)aNotification
{
    if(!scheduledToUpdate1){
        [self performSelector:@selector(reloadData) withObject:nil afterDelay:1.0];
        scheduledToUpdate1 = YES;
    }
}

- (void) reloadData
{
    scheduledToUpdate1 = NO;
	[valueTable1 reloadData];
	[valueTable2 reloadData];
    [outlineView reloadData];
    [multiPlotView reloadData];
}

- (void) pollingStateChanged:(NSNotification*)aNotification
{
	[pollingButton selectItemAtIndex:[pollingButton indexOfItemWithTag:[model pollingState]]];
}


- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [outlineView selectedRow] >= 0 || [multiPlotView selectedRow]>=0;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [outlineView selectedRow] >= 0 || [multiPlotView selectedRow]>=0;
    }    
    else if ([menuItem action] == @selector(copy:)) {
        return NO;
    }
    else  return [super validateMenuItem:menuItem];
}

#pragma mark ¥¥¥Actions
- (IBAction)delete:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction)cut:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction) removeItemAction:(id)sender
{ 
    if([[self window] firstResponder] == outlineView){
        NSArray *selection = [outlineView allSelectedItems];
        NSEnumerator* e = [selection objectEnumerator];
        id item;
        while(item = [e nextObject]){
            [model removeDataSet:item];
        }
        [[model dataSet] recountTotal];
        [outlineView deselectAll:self];
        [outlineView reloadData];
    }
    else {
        NSArray *selection = [multiPlotView allSelectedItems];
        NSEnumerator* e = [selection objectEnumerator];
        id item;
        while(item = [e nextObject]){
            if([item isKindOfClass:[ORTimeMultiPlot class]]){
                [model removeMultiPlot:item];
            }
            else {//if([item isKindOfClass:[ORMultiPlotDataItem class]]){
                [item removeSelf];
            }
        }
        [multiPlotView deselectAll:self];
        [multiPlotView reloadData];
    }
}

- (IBAction) doubleClickMultiPlot:(id)sender
{
    id selectedObj = [multiPlotView itemAtRow:[multiPlotView selectedRow]];
    [selectedObj doDoubleClick:sender];
}

- (IBAction) doubleClick:(id)sender
{
    id selectedObj = [outlineView itemAtRow:[outlineView selectedRow]];
    [selectedObj doDoubleClick:sender];
}

- (IBAction) plotGroupAction:(id)sender
{
    NSMutableArray *selection = [NSMutableArray arrayWithArray:[outlineView allSelectedItems]];
    //launch the multiplot for the selection array...
    ORTimeMultiPlot* newMultiPlot = [[ORTimeMultiPlot alloc] init];
    
    NSEnumerator* e = [selection objectEnumerator];
    ORDataSet* aDataSet;
    int validCount = 0;
    while(aDataSet = [e nextObject]){
        if([aDataSet leafNode]){
            id obj = [aDataSet data];
            if([obj canJoinMultiPlot]){
                [newMultiPlot addDataSetName:[[aDataSet data] shortName]];
                validCount++;
				if(![newMultiPlot dataSet]){
					[newMultiPlot setDataSet:[model dataSet]];
				}
            }
        }
    }
    if(validCount){
        [newMultiPlot setDataSource:[model dataSet]];
        [newMultiPlot doDoubleClick:nil];
        [model addMultiPlot:newMultiPlot];
    }
    [newMultiPlot release];
    [multiPlotView reloadData];
    [outlineView deselectAll:self];
    [outlineView reloadData];
	
}

- (IBAction) shipRecordsAction:(id)sender
{
	[model setShipRecords:[sender intValue]];	
}

- (IBAction) enablePollAllAction:(id)sender
{
	[model enablePollAll:YES];
	[valueTable1 reloadData];
	[valueTable2 reloadData];
}

- (IBAction) enablePollNoneAction:(id)sender
{
	[model enablePollAll:NO];
	[valueTable1 reloadData];
	[valueTable2 reloadData];
}

- (IBAction) enableAlarmAllAction:(id)sender
{
	[model enableAlarmAll:YES];
	[alarmTable1 reloadData];
	[alarmTable2 reloadData];
}

- (IBAction) enableAlarmNoneAction:(id)sender
{
	[model enableAlarmAll:NO];
	[alarmTable1 reloadData];
	[alarmTable2 reloadData];
}

- (IBAction) setJumperSettings:(id)sender
{
	[model setCardJumperSetting:[[sender selectedItem] tag]];	
}

- (IBAction) calibrateAction:(id)sender
{
	[model calibrate];
}

- (IBAction) selectFileAction:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Log To File"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[model logFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"OrcaScript";
    }
	
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            [model setLogFile:[[[savePanel URL]path] stringByAbbreviatingWithTildeInPath]];
       }
    }];
}

- (IBAction) logToFileAction:(id)sender
{
	[model setLogToFile:[sender intValue]];	
}

- (IBAction) displayRawAction:(id)sender
{
	[model setDisplayRaw:[sender intValue]];		
}

- (IBAction) modeAction:(id)sender
{
	[model setMode:[[sender selectedItem] tag]];
}


- (IBAction) readAll:(id)sender
{
    @try {
        [model readAllAdcChannels];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nRead of All Channels Failed", @"OK", nil, nil,
                        localException);
    }
}
- (IBAction) setPollingAction:(id)sender
{
    [model setPollingState:(NSTimeInterval)[[sender selectedItem] tag]];
}



- (void) tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:adcValueSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:calibrationSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:alarmSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:dataSize];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.ORIP320%d%d%d.selectedtab",[model crateNumber],[model slot],[model slotConv]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}


#pragma mark ¥¥¥Data Source
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	if([model opMode] == 1)return YES;
	else {
		if( tableView == valueTable2 || 
		   tableView == calibrationTable2 ||
		   tableView == alarmTable2 ) {
			return NO;
		}
		else return YES;
	}
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    rowIndex += [aTableView tag];
    //NSParameterAssert(rowIndex >= 0 && rowIndex < kNumIP320Channels);
    ORIP320Channel* obj = [[model chanObjs] objectAtIndex:rowIndex];
	if([[aTableColumn identifier] isEqualToString:k320ChannelValue]){
		if([model displayRaw]){
			return [NSString stringWithFormat:@"0x%x",[obj rawValue]];
		}
		else {
			return [NSString stringWithFormat:@"%.3f",[[obj objectForKey:k320ChannelValue] doubleValue]];
		}
	}
    else return [obj objectForKey:[aTableColumn identifier]];
}


// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return kNumIP320Channels/2;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(anObject!=nil){
		rowIndex += [aTableView tag];
		//NSParameterAssert(rowIndex >= 0 && rowIndex < kNumIP320Channels);
		NSMutableDictionary* obj = [[model chanObjs] objectAtIndex:rowIndex];
		[[[self undoManager] prepareWithInvocationTarget:self] tableView:aTableView setObjectValue:[obj objectForKey:[aTableColumn identifier]] forTableColumn:aTableColumn row:rowIndex];
		[obj setObject:anObject forKey:[aTableColumn identifier]];
		[aTableView reloadData];
	}
}

#pragma  mark ¥¥¥Delegate Responsiblities
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}

#pragma mark ¥¥¥Data Source Methods
- (int)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item
{
    if(ov == outlineView){
        return  (item == nil) ? [model numberOfChildren]  : [item numberOfChildren];
    }
    else {
        if(!item)return [[model multiPlots] count];
        else {
            if([item respondsToSelector:@selector(count)])return [item count];
            else return 0;
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item
{
    if(ov == outlineView){
        return   (item == nil) ? [model numberOfChildren] != 0 : ([item numberOfChildren] != 0);
    }
    else {
        if(!item)return [[model multiPlots] count]!=0;
        else {
            if([item respondsToSelector:@selector(count)])return [item count]!=0;
            else return NO;
        }
    }
}

- (id)outlineView:(NSOutlineView *)ov child:(NSUInteger)index ofItem:(id)item
{
    id anObj;
    if(ov == outlineView){
        if(!item)   anObj = model;
        else        anObj = [item childAtIndex:index];
    }
    else {
        if(!item)   anObj = [[model multiPlots] objectAtIndex:index];
        else  anObj = [item objectAtIndex:index];
    }
    return anObj;
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if(ov == outlineView){
        return  ((item == nil) ? [model name] : [item name]);
    }
    else {
        if([tableColumn identifier]){
            return [item description];
        }
        else return nil;
    }
}

@end

