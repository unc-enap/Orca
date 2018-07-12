//
//  SNOController.m
//  Orca
//
//  Created by H S  Wan Chan Tseung on 11/18/11.
//  Copyright (c) 2011 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "SNOController.h"
#import "SNOModel.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORSNOConstants.h"
#import "ORRunModel.h"
#import "ORCompositePlotView.h"
#import "ORTimeLinePlot.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"
#import "SNOConnection.h"

@implementation SNOController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"SNO"];
    return self;
}

- (void) dealloc
{
    [blankView release];
    [super dealloc];
}

-(void) awakeFromNib
{
	runControlSize		= NSMakeSize(465,260);
	detectorSize        = NSMakeSize(1120,700);
	slowControlSize		= NSMakeSize(600,650);

	[[self window] setContentSize:runControlSize];
    blankView = [[NSView alloc] init];

    ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[ratePlot addPlot: aPlot];
	[(ORTimeAxis*)[ratePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
    
    [[ratePlot yAxis] setRngLimitsLow:0 withHigh:5000000 withMinRng:1];
    
    ORTimeLinePlot* dataPlot = [[ORTimeLinePlot alloc] initWithTag:1 andDataSource:self];
	[totalRatePlot addPlot: dataPlot];
	[(ORTimeAxis*)[totalRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[dataPlot release];    
    
    [[totalRatePlot yAxis] setRngLimitsLow:0 withHigh:5000000 withMinRng:1];
    
	[[SNOMonitoredHardware sharedSNOMonitoredHardware] readCableDBDocumentFromOrcaDB];

	[self findRunControl];
    [super awakeFromNib];
	[selectionStringTextView setFont:[NSFont fontWithName:@"Monaco" size:9]];
}

#pragma mark •••Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    /*[notifyCenter addObserver : self
                     selector : @selector(colorAttributesChanged:)
                         name : ORSNORateColorBarChangedNotification
                       object : model];*/
    
    [notifyCenter addObserver : self
                     selector : @selector(secondaryColorAxisAttributesChanged:)
                         name : ORAxisRangeChangedNotification
                       object : [secondaryColorScale colorAxis]];

    [notifyCenter addObserver : self
					 selector : @selector(updateRunInfo:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
	[notifyCenter addObserver: self
                     selector: @selector(elapsedTimeChanged:)
                         name: ORRunElapsedTimesChangedNotification
                       object: nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectionStringChanged:)
						 name : selectionStringChanged
					   object : detectorView];
	
    [notifyCenter addObserver : self
					 selector : @selector(slowControlTableChanged:)
						 name : slowControlTableChanged
					   object : model];	

	[notifyCenter addObserver : self
					 selector : @selector(slowControlConnectionStatusChanged:)
						 name : slowControlConnectionStatusChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(morcaDBRead:)
						 name : morcaDBRead
					   object : [SNOMonitoredHardware sharedSNOMonitoredHardware]];
    
	[notifyCenter addObserver : self
					 selector : @selector(updateRatePlot:)
						 name : newValueAvailable
					   object : detectorView];   
    
    [notifyCenter addObserver : self
					 selector : @selector(updateTotalRatePlot:)
						 name : totalRatePlotChanged
					   object : model];   
    
	[notifyCenter addObserver : self
					 selector : @selector(disablePlotButton:)
						 name : plotButtonDisabled
					   object : detectorView];    
}

#pragma mark •••Data Source For Plots
- (int) numberPointsInPlot:(id)aPlotter
{
	int tag = (int)[aPlotter tag];
	if(tag == 0){ 
		return (int)[[model parameterRate] count];
	} else if (tag ==1){
        return (int)[[model totalDataRate] count];
    }
	else return 0;
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	double aValue = 0;
	int tag = (int)[aPlotter tag];
	if(tag == 0){ 
		int count = (int)[[model parameterRate] count];
		int index = count-i-1;
		if(count==0) aValue = 0;
		else		 aValue = [[model parameterRate] valueAtIndex:index];
		*xValue = [[model parameterRate] timeSampledAtIndex:index];
		*yValue = aValue;
	} else if (tag == 1){
		int count = (int)[[model totalDataRate] count];
		int index = count-i-1;
		if(count==0) aValue = 0;
		else		 aValue = [[model totalDataRate] valueAtIndex:index];
		*xValue = [[model totalDataRate] timeSampledAtIndex:index];
		*yValue = aValue;        
    }
}

#pragma mark •••Actions
- (void) secondaryColorAxisAttributesChanged:(NSNotification*)aNotification
{
	//BOOL isLog = [[secondaryColorScale colorAxis] isLog];
	//[secondaryColorAxisLogCB setState:isLog];
    [detectorView setColorAxisChanged:YES];
	[detectorView setColorBarAxisAttributes:[[secondaryColorScale colorAxis] attributes]];
    [detectorView updateSNODetectorView];
    //[detectorView setColorAxisChanged:NO];
}

//Run control action
- (void) findRunControl
{
	runControl = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORRunModel,1"];
	if(!runControl){
        runControl = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORRemoteRunModel,1"];	
	}
	[self updateRunInfo:nil];
    [self getRunTypes];
	//	[startRunButton setEnabled:runControl!=nil];
	//	[timedRunCB setEnabled:runControl!=nil];
	//	[runModeMatrix setEnabled:runControl!=nil];
    //[self updateWindow];
}

- (IBAction) startRunAction:(id) sender
{
	if([runControl isRunning]){
		//if ([startRunButton state]==0) [startRunButton setState:1]; 
		[runControl restartRun];
        [model stopTotalXL3RatePoll];
        [model startTotalXL3RatePoll];
	}else{
		[runControl startRun];
        [model startTotalXL3RatePoll];
	}
}

- (IBAction) stopRunAction:(id) sender
{
	//if ([startRunButton state]==1) [startRunButton setState:0];
	[runControl haltRun];
    [model stopTotalXL3RatePoll];
}

- (void) updateRunInfo:(NSNotification*)aNote
{
	if(runControl)	{
		[runStatusField setStringValue:[runControl shortStatus]];
		[runNumberField setIntegerValue:[runControl runNumber]];
		
		if([runControl isRunning]){
			[startRunButton setState:1];
			[runBar setIndeterminate:!([runControl timedRun] && ![runControl remoteControl])];
			[runBar setDoubleValue:0];
			[runBar startAnimation:self];
			
		}
		else if (![runControl isRunning]){
			[startRunButton setState:0];
			[elapsedTimeField setStringValue:@"---"];
			[runBar setDoubleValue:0];
			[runBar stopAnimation:self];
			[runBar setIndeterminate:NO];
		}
	}
	else {
		[runStatusField setStringValue:@"---"];
		[runNumberField setStringValue:@"---"];
		[elapsedTimeField setStringValue:@"---"];
	}
}

- (void) getRunTypes
{
    NSMutableArray *runTypeList = [[NSMutableArray alloc] init];
    [model getRunTypesFromOrcaDB:runTypeList];
    int i;
    for(i=0;i<[runTypeList count];++i){
        NSMenuItem *runType = [[NSMenuItem alloc] initWithTitle:[runTypeList objectAtIndex:i] action:nil keyEquivalent:@""];
        [[runTypeButton menu] addItem:runType];
        [runType release];
    }
    [runTypeList release];
}

- (void) setRunTypeAction:(id)sender
{
    [model setRunTypeName:[[sender selectedItem] title]];
    if ([[[sender selectedItem] title] isEqualToString:@"AmBe"]) {
        [sourceNotesButton setEnabled:YES];
    }else{
        [sourceNotesButton setEnabled:NO];
    }
}

- (IBAction) sourceNotesAction:(id)sender
{
    //NSLog(@"%@\n",[sourceNotesField stringValue]);
//    [model writeNewRunTypeDocument:[sourceNotesField stringValue]];
    [runNotesDrawer close];
}

-(void) elapsedTimeChanged:(NSNotification*)aNotification
{
	if(runControl)[elapsedTimeField setStringValue:[runControl elapsedRunTimeString]];
	else [elapsedTimeField setStringValue:@"---"];
	if([runControl timedRun]){
		double timeLimit = [runControl timeLimit];
		double elapsedRunTime = [runControl elapsedRunTime];
		[runBar setDoubleValue:100*elapsedRunTime/timeLimit];
	}
}

- (IBAction) showTotalDataRate:(id) sender;
{
	[totalDataRateWindow makeKeyAndOrderFront:sender];
}

- (IBAction) showMonitorWindow:(id) sender;
{
	[detectorView updateSNODetectorView];
	[monitorWindow makeKeyAndOrderFront:sender];
}

//detector view actions

- (void) viewSelectionAction:(id)sender
{ 
	if ([[sender selectedItem] tag]==0){
		[detectorView setViewType:YES];		
	} else if ([[sender selectedItem] tag]==1) {
		[detectorView setViewType:NO];
	}
	
	[detectorView updateSNODetectorView];
}

- (void) parameterDisplayAction:(id)sender
{
    if ([[[sender selectedItem] title] isEqualToString:@"FEC Voltages"] ||
        [[[sender selectedItem] title] isEqualToString:@"XL3 Voltages"]){
        [[selectionModeButton itemWithTitle:@"Tube"] setEnabled:NO];
        [[selectionModeButton itemWithTitle:@"Card"] setEnabled:NO];
        [[selectionModeButton itemWithTitle:@"Crate"] setEnabled:NO];
        [[selectionModeButton itemWithTitle:@"Voltage"] setEnabled:YES];
        [selectionModeButton selectItemWithTitle:@"Voltage"];
        [[viewSelectionButton itemWithTitle:@"PSUP view"] setEnabled:NO];
        [viewSelectionButton selectItemWithTitle:@"Crate view"];
        [detectorView setViewType:NO];
    }else if ([[[sender selectedItem] title] isEqualToString:@"Data Rates"]){
        [[selectionModeButton itemWithTitle:@"Tube"] setEnabled:NO];
        [[selectionModeButton itemWithTitle:@"Card"] setEnabled:NO];
        [[selectionModeButton itemWithTitle:@"Crate"] setEnabled:YES];
        [[selectionModeButton itemWithTitle:@"Voltage"] setEnabled:NO];
        [selectionModeButton selectItemWithTitle:@"Crate"];
        [[viewSelectionButton itemWithTitle:@"PSUP view"] setEnabled:YES];
        [detectorView setSelectionMode:(int)[[selectionModeButton itemWithTitle:@"Crate"] tag]];
    }else if ([[[sender selectedItem] title] isEqualToString:@"FIFO"]){
        [[selectionModeButton itemWithTitle:@"Tube"] setEnabled:NO];
        [[selectionModeButton itemWithTitle:@"Card"] setEnabled:YES];
        [[selectionModeButton itemWithTitle:@"Crate"] setEnabled:NO];
        [[selectionModeButton itemWithTitle:@"Voltage"] setEnabled:NO];
        [selectionModeButton selectItemWithTitle:@"Card"];
        [[viewSelectionButton itemWithTitle:@"PSUP view"] setEnabled:YES];
        [detectorView setSelectionMode:(int)[[selectionModeButton itemWithTitle:@"Card"] tag]];
    }else {
        [[selectionModeButton itemWithTitle:@"Tube"] setEnabled:YES];
        [[selectionModeButton itemWithTitle:@"Card"] setEnabled:YES];
        [[selectionModeButton itemWithTitle:@"Crate"] setEnabled:YES];
        [[selectionModeButton itemWithTitle:@"Voltage"] setEnabled:NO];
        [[viewSelectionButton itemWithTitle:@"PSUP view"] setEnabled:YES];
    }
	[detectorView setParameterToDisplay:(int)[[sender selectedItem] tag]];
    [detectorView setDetectorTitleString:[[sender selectedItem] title]];
	[model getDataFromMorca];
}

- (void) selectionModeAction:(id)sender
{
	[detectorView setSelectionMode:(int)[[sender selectedItem] tag]];
	//[model getDataFromMorca];
	[detectorView updateSNODetectorView];
}

- (void) readMorca:(id)sender
{
	[model getDataFromMorca];
}

- (void) setXl3PollingAction:(id)sender
{
	[model setXl3Polling:(int)[[sender selectedItem] tag]];
}

- (void) startXl3PollingAction:(id)sender
{
    if ([[xl3PollingButton selectedItem] tag] > 0) [detectorView setPollingInProgress:YES];
	[model startXl3Polling];
}

- (void) stopXl3PollingAction:(id)sender
{
    [detectorView setPollingInProgress:NO];
	[model stopXl3Polling];
}

- (void) plotVariableAction:(id)sender
{
    if (![model isPlottingGraph]) [model collectSelectedVariable];
}

//slow control actions
- (IBAction) setSlowControlPollingAction:(id)sender
{
	[model setSlowControlPolling:(int)[[sender selectedItem] tag]];
}

- (IBAction) startSlowControlPollingAction:(id)sender
{
    if ([slowControlPollingButton selectedTag] != 0) [connectToIOServerButton setEnabled:NO];
	[model startSlowControlPolling];
}

- (IBAction) stopSlowControlPollingAction:(id)sender
{
	[model stopSlowControlPolling];
    [connectToIOServerButton setEnabled:YES];
}

- (IBAction) setIosPasswd:(id)sender
{
    //NSLog(@"pw %@\n",[sender stringValue]);
    [model setIoserverPasswd:[sender stringValue]];
}

- (IBAction) setIosUsername:(id)sender
{
    //NSLog(@"un %@\n",[sender stringValue]);
    [model setIoserverUsername:[sender stringValue]];
}

- (IBAction) connectToIOServerAction:(id)sender
{
	[model connectToIOServer];
    [startSlowControlMonitorButton setEnabled:YES];
    [stopSlowControlMonitorButton setEnabled:YES];
}

- (IBAction) setSlowControlParameterThresholdsAction:(id)sender
{
	[model setSlowControlParameterThresholds];
}

- (IBAction) setSlowControlChannelGainAction:(id)sender
{
	[model setSlowControlChannelGain];
}

- (IBAction) enableSlowControlParameterAction:(id)sender
{
	[model enableSlowControlParameter];
}

- (IBAction) setSlowControlMappingAction:(id)sender
{
	[model setSlowControlMapping];
}

#pragma mark •••Interface Management
- (void) updateWindow
{
    [super updateWindow];
}

- (void) updateRatePlot:(NSNotification *)aNote
{
    if (![plotVariableButton isEnabled]){
        [plotVariableButton setEnabled:YES];
    } else {
        [ratePlot setNeedsDisplay:YES];
    }
}

- (void) updateTotalRatePlot:(NSNotification *)aNote
{
    NSString *value = [NSString stringWithFormat:@"%f Hz",[model totalRate]];
    [totalXL3RateField setStringValue:value];
    [totalRatePlot setNeedsDisplay:YES];
    [totalXL3RateField setNeedsDisplay:YES];
}

- (void) disablePlotButton:(NSNotification *)aNote
{
    [plotVariableButton setEnabled:NO];
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
    /*
	float toolBarOffset = 0;
	BOOL toolBarVisible = [[monitorWindow toolbar] isVisible];
	if(toolBarVisible){
		switch([[monitorWindow toolbar] sizeMode]){
			case NSToolbarSizeModeRegular:	toolBarOffset = 60; break;
			case NSToolbarSizeModeSmall:	toolBarOffset = 50; break;
			default:						toolBarOffset = 60; break;
		}
	}*/
	if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[monitorWindow setContentView:blankView];
		NSSize newSize = detectorSize;
		//newSize.height += toolBarOffset;
		[monitorWindow setContentSize:newSize];
		//[self resizeWindowToSize:newSize];
		[monitorWindow setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[monitorWindow setContentView:blankView];
		NSSize newSize = slowControlSize;
		//newSize.height += toolBarOffset;
		[monitorWindow setContentSize:newSize];
		//[self resizeWindowToSize:newSize];
		[monitorWindow setContentView:tabView];
    }
//	int index = [tabView indexOfTabViewItem:tabViewItem];
//   [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.SNOController.selectedtab"];
}

- (void) selectionStringChanged:(NSNotification*)aNote
{
	[selectionStringTextView setString:[detectorView selectionString]];
}

- (void) slowControlTableChanged:(NSNotification*)aNote
{
	[slowControlParameterTable reloadData];
}

- (void) slowControlConnectionStatusChanged:(NSNotification*)aNote
{
	[slowControlMonitorStatus setStringValue:[model getSlowControlMonitorStatusString]];
	[slowControlMonitorStatus setTextColor:[model getSlowControlMonitorStatusStringColor]];
}

- (void) morcaDBRead:(NSNotification*)aNote
{
	[detectorView updateSNODetectorView];
}

#pragma mark •••Table Data Source
//- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
//{
//	return ![gSecurity isLocked:[model experimentMapLock]];;
//}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
//	NSLog(@"%@\n",[[tableEntries objectAtIndex:rowIndex] valueForKey:[aTableColumn identifier]]);
	NSString *columnName = [aTableColumn identifier];
	if ([columnName isEqualToString:@"parameterSelected"]){
	    //return [[tableEntries objectAtIndex:rowIndex] valueForKey:columnName];
		BOOL isSelected = [[[model getSlowControlVariable:(int)rowIndex] valueForKey:columnName] boolValue];
		return [NSNumber numberWithInteger:(isSelected ? NSOnState : NSOffState)];
	}else {
		return [[model getSlowControlVariable:(int)rowIndex] valueForKey:columnName];
	}
}

- (void) tableView:(NSTableView*)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *status = [[model getSlowControlVariable:(int)rowIndex] parameterStatus];
	NSString *columnName = [aTableColumn identifier];
						
	if ([[model getSlowControlVariable:(int)rowIndex] isSlowControlParameterChanged] &&
		![columnName isEqualToString:@"parameterSelected"]) {
		[aCell setTextColor:[NSColor redColor]];
	} else if ([columnName isEqualToString:@"parameterStatus"]) {
		if ([status isEqualToString:@"LoLo"] || [status isEqualToString:@"HiHi"]) {
			[aCell setTextColor:[NSColor redColor]];
		}else if ([status isEqualToString:@"Hi"] || [status isEqualToString:@"Lo"]) {
			[aCell setTextColor:[NSColor orangeColor]];
		}else if ([status isEqualToString:@"OK"]) {
			[aCell setTextColor:[NSColor greenColor]];
		}else{
			[aCell setTextColor:[NSColor blackColor]];
		}
	}else if ([columnName isEqualToString:@"parameterSelected"]){
	}else{
		[aCell setTextColor:[NSColor blackColor]];
	}
		
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return kNumSlowControlParameters;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{	
	NSString *columnName = [aTableColumn identifier];
	SNOSlowControl *slowControlVariable=[model getSlowControlVariable:(int)rowIndex];
	
	if ([columnName isEqualToString:@"parameterName"]) {
		[slowControlVariable setParameterName:anObject];
	}else if ([columnName isEqualToString:@"parameterLoThreshold"]){
		if ([slowControlVariable parameterLoThreshold] != [anObject floatValue]) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}		
		[slowControlVariable setLoThresh:[anObject floatValue]];
	}else if ([columnName isEqualToString:@"parameterHiThreshold"]) {
		if ([slowControlVariable parameterHiThreshold] != [anObject floatValue]) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}
		[slowControlVariable setHiThresh:[anObject floatValue]];
	}else if ([columnName isEqualToString:@"parameterLoLoThreshold"]){
		if ([slowControlVariable parameterLoLoThreshold] != [anObject floatValue]) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}		
		[slowControlVariable setLoLoThresh:[anObject floatValue]];
	}else if ([columnName isEqualToString:@"parameterHiHiThreshold"]) {
		if ([slowControlVariable parameterHiHiThreshold] != [anObject floatValue]) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}		
		[slowControlVariable setHiHiThresh:[anObject floatValue]];		
	}else if ([columnName isEqualToString:@"parameterGain"]) {
		if ([slowControlVariable parameterGain] != [anObject floatValue]) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}		
		[slowControlVariable setChannelGain:[anObject floatValue]];
	}else if ([columnName isEqualToString:@"parameterIOS"]){
        if ([slowControlVariable parameterIOS] != anObject){
            [slowControlVariable setSlowControlParameterChanged:YES];
        }
        [slowControlVariable setIosName:anObject];
    }else if ([columnName isEqualToString:@"parameterCard"]) {
		if ([slowControlVariable parameterCard] != anObject) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}	
		[slowControlVariable setCardName:anObject];
	}else if ([columnName isEqualToString:@"parameterChannel"]) {
		if ([slowControlVariable parameterChannel] != [anObject intValue]) {
			[slowControlVariable setSlowControlParameterChanged:YES];
		}	
		[slowControlVariable setChannelNumber:[anObject intValue]];
	}else if ([columnName isEqualToString:@"parameterSelected"]){
		[slowControlVariable setSelected:[anObject boolValue]];
	}
}

- (void) tableView:(NSTableView*)aTableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	BOOL AllSelected=YES;
	
	int i;
	for(i=0;i<kNumSlowControlParameters;++i){
		if (![[model getSlowControlVariable:i] parameterSelected]) {
			AllSelected=NO;
			break;
		}
	}
	
	//NSString *columnName = [tableColumn identifier];
	if (AllSelected) {
		for(i=0;i<kNumSlowControlParameters;++i){
			[[model getSlowControlVariable:i] setSelected:NO];
		}
	}else if (!AllSelected) {
		for(i=0;i<kNumSlowControlParameters;++i){
			[[model getSlowControlVariable:i] setSelected:YES];
		}
	}
	
	[slowControlParameterTable reloadData];
}

@end
