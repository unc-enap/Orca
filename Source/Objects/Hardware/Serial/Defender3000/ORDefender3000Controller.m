//--------------------------------------------------------
// ORDefender3000Controller
//  Orca
//
//  Created by Mark Howe on 05/14/2024.
//  Copyright 2024 CENPA, University of North Carolina. All rights reserved.
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

#import "ORDefender3000Controller.h"
#import "ORDefender3000Model.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORTimeRate.h"

@interface ORDefender3000Controller (private)
- (void) populatePortListPopup;
@end

@implementation ORDefender3000Controller

#pragma mark ***Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"Defender3000"];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    [self populatePortListPopup];
    [[plotter0 yAxis] setRngLow:0.0 withHigh:300.];
	[[plotter0 yAxis] setRngLimitsLow:-300.0 withHigh:500 withMinRng:4];

    [[plotter0 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter0 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];

	ORTimeLinePlot* aPlot;
	aPlot= [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[plotter0 addPlot: aPlot];
	[(ORTimeAxis*)[plotter0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	
	[super awakeFromNib];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Defender 3000 (Unit %u)",[model uniqueIdNumber]]];
}

#pragma mark ***Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORDefender3000Lock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORDefender3000ModelPortNameChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
                                              
    [notifyCenter addObserver : self
                     selector : @selector(weightChanged:)
                         name : ORDefender3000WeightChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORDefender3000ModelPollTimeChanged
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(shipWeightChanged:)
                         name : ORDefender3000ModelShipWeightChanged
						object: model];

    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];

    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(updateTimePlot:)
						 name : ORRateAverageChangedNotification
					   object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(printIntervalChanged:)
                         name : ORDefender3000PrintIntervalChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(unitsChanged:)
                         name : ORDefender3000UnitsChanged
                       object : nil];
 
    [notifyCenter addObserver : self
                     selector : @selector(commandChanged:)
                         name : ORDefender3000CommandChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(tareChanged:)
                         name : ORDefender3000TareChanged
                       object : nil];
    
    
}

- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
    [self portStateChanged:nil];
    [self portNameChanged:nil];
	[self weightChanged:nil];
	[self pollTimeChanged:nil];
	[self shipWeightChanged:nil];
	[self updateTimePlot:nil];
    [self miscAttributesChanged:nil];
    [self printIntervalChanged:nil];
    [self unitsChanged:nil];
    [self commandChanged:nil];
    [self tareChanged:nil];
}

- (void) scaleAction:(NSNotification*)aNote
{
	if(aNote == nil || [aNote object] == [plotter0 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 xAxis]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNote == nil || [aNote object] == [plotter0 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 yAxis]attributes] forKey:@"YAttributes0"];
	};
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{

	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 xAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 yAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 yAxis] setNeedsDisplay:YES];
		}
	}
}

- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [model timeRate])){
		[plotter0 setNeedsDisplay:YES];
	}
}

- (void) shipWeightChanged:(NSNotification*)aNote
{
	[shipWeightButton setIntValue: [model shipWeight]];
}

- (void) printIntervalChanged:(NSNotification*)aNote
{
    [printIntervalField setIntValue: [model printInterval]];
}

- (void) tareChanged:(NSNotification*)aNote
{
    [tareField setIntValue: [model tare]];
}

- (void) unitsChanged:(NSNotification*)aNote
{
    [unitsPopup selectItemWithTag: [(ORDefender3000Model*)model units]];
}

- (void) commandChanged:(NSNotification*)aNote
{
    [commandPopup selectItemWithTag: [model command]];
}

- (void) weightChanged:(NSNotification*)aNote
{
	[weightField setFloatValue:[model weight]];
	uint32_t t = [model timeMeasured];
	NSDate* theDate;
	if(t){
		theDate = [NSDate dateWithTimeIntervalSince1970:t];
		[timeField setObjectValue:[theDate description]];
	}
	else [timeField setObjectValue:@"--"];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORDefender3000Lock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNote
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORDefender3000Lock];
    BOOL locked = [gSecurity isLocked:ORDefender3000Lock];

    [lockButton setState: locked];

    [portListPopup      setEnabled:!locked];
    [openPortButton     setEnabled:!locked];
    [pollTimePopup      setEnabled:!locked];
    
    bool portOpen = [[model serialPort] isOpen];
    [unitsPopup         setEnabled:!locked && portOpen];
    [commandPopup       setEnabled:!locked && portOpen];
    [printIntervalField setEnabled:!locked && portOpen];
    [tareField          setEnabled:!locked && portOpen];
    [shipWeightButton   setEnabled:!locked && portOpen];
    [sendAllButton      setEnabled:!locked && portOpen];

    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORDefender3000Lock])s = @"Not in Maintenance Run.";
    }
    [lockDocField setStringValue:s];

}

- (void) portStateChanged:(NSNotification*)aNote
{
    if(aNote == nil || [aNote object] == [model serialPort]){
        if([model serialPort]){
            [openPortButton setEnabled:YES];

            if([[model serialPort] isOpen]){
                [openPortButton setTitle:@"Close"];
                [portStateField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:.8 blue:0.0 alpha:1.0]];
                [portStateField setStringValue:@"Open"];
            }
            else {
                [openPortButton setTitle:@"Open"];
                [portStateField setStringValue:@"Closed"];
                [portStateField setTextColor:[NSColor redColor]];
            }
        }
        else {
            [openPortButton setEnabled:NO];
            [portStateField setTextColor:[NSColor blackColor]];
            [portStateField setStringValue:@"---"];
            [openPortButton setTitle:@"---"];
        }
    }
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePopup selectItemWithTag:[model pollTime]];
}

- (void) portNameChanged:(NSNotification*)aNote
{
    NSString* portName = [model portName];
    
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;

    [portListPopup selectItemAtIndex:0]; //the default
    while (aPort = [enumerator nextObject]) {
        if([portName isEqualToString:[aPort name]]){
            [portListPopup selectItemWithTitle:portName];
            break;
        }
	}  
    [self portStateChanged:nil];
}

#pragma mark ***Actions
- (IBAction) printIntervalAction:(id)sender
{
    [model setPrintInterval:[sender intValue]];
}

- (IBAction) tareAction:(id)sender
{
    [model setTare:[sender intValue]];
}

- (IBAction) sendCommandAction:(id)sender
{
    [model sendCommand];
}

- (IBAction) sendAllAction:(id)sender
{
    [model sendAllCommands];
}

- (void) shipWeightAction:(id)sender
{
	[model setShipWeight:[sender intValue]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORDefender3000Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:(int)[[sender selectedItem] tag]];
}
- (IBAction) unitsAction:(id)sender
{
    [model setUnits:(int)[[sender selectedItem] tag]];
}
- (IBAction) commandAction:(id)sender
{
    [model setCommand:(int)[[sender selectedItem] tag]];
}

#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
	return (int)[[model timeRate] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int count = (int)[[model timeRate] count];
	int index = count-i-1;
	*xValue = [[model timeRate] timeSampledAtIndex:index];
	*yValue = [[model timeRate] valueAtIndex:index];
}

@end

@implementation ORDefender3000Controller (private)

- (void) populatePortListPopup
{
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
    [portListPopup removeAllItems];
    [portListPopup addItemWithTitle:@"--"];

	while (aPort = [enumerator nextObject]) {
        [portListPopup addItemWithTitle:[aPort name]];
	}    
}
@end

