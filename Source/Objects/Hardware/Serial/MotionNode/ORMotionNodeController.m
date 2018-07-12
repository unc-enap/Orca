//
//  ORHPMotionNodeController.m
//  Orca
//
//  Created by Mark Howe on Fri Apr 24, 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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

#import "ORMotionNodeController.h"
#import "ORMotionNodeModel.h"
#import "ORSerialPortController.h"
#import "ORSerialPort.h"
#import "ORPlotView.h"
#import "ORXYPlot.h"
#import "ORAxis.h"
#import "ORLongTermView.h"
#import "ORCompositePlotView.h"
#import "ORTimeLinePlot.h"
#import "ORTimeAxis.h"

@implementation ORMotionNodeController
- (id) init
{
    self = [ super initWithWindowNibName: @"MotionNode" ];
    return self;
}


- (void) awakeFromNib
{
	[[tracePlot xScale] setRngLow:0 withHigh:kModeNodeTraceLength];
	[[tracePlot xScale] setRngLimitsLow:0 withHigh:kModeNodeTraceLength withMinRng:kModeNodeTraceLength];
	[[tracePlot yScale] setLabel:@"Accel (g)"];
	[[tracePlot yScale]  setInteger:NO];
	[[tracePlot yScale]  setRngDefaultsLow:-3.0 withHigh:3.0];
	[[tracePlot yScale] setRngLow:-3.0 withHigh:1.0];
	[[tracePlot yScale] setRngLimitsLow:-3.0 withHigh:3.0 withMinRng:.01];
	
	ORXYPlot* aPlot;
	aPlot = [[ORXYPlot alloc] initWithTag:0 andDataSource:self];
	[aPlot setLineColor:[NSColor redColor]];
	[tracePlot addPlot: aPlot];
	[aPlot release];
	
	aPlot = [[ORXYPlot alloc] initWithTag:1 andDataSource:self];
	[aPlot setLineColor:[NSColor greenColor]];
	[tracePlot addPlot: aPlot];
	[aPlot release];
	
	aPlot = [[ORXYPlot alloc] initWithTag:2 andDataSource:self];
	[aPlot setLineColor:[NSColor blueColor]];
	[tracePlot addPlot: aPlot];
	[aPlot release];
	
	aPlot = [[ORXYPlot alloc] initWithTag:3 andDataSource:self];
	[aPlot setLineColor:[NSColor redColor]];
	[tracePlot addPlot: aPlot];
	[aPlot release];
	
    [[plotter0 yAxis] setRngDefaultsLow:-5E-3 withHigh:+5E-3];
    [[plotter0 yAxis] setInteger:NO];
    [[plotter0 yAxis] setRngLimitsLow:-2 withHigh:2 withMinRng:.0001];
    
    double maxPoints = [model maxHistoryLength];
    [[plotter0 xAxis] setRngDefaultsLow:0.0 withHigh:maxPoints];
    [[plotter0 xAxis] setRngLimitsLow:0.0 withHigh:maxPoints withMinRng:5];
    
    ORTimeLinePlot* historyPlot= [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
    [plotter0 addPlot: historyPlot];
    [historyPlot release];
    
    
    [(ORTimeAxis*)[plotter0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];

	[super awakeFromNib];
}
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORMotionNodeModelLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORMotionNodeModelSerialNumberChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(versionChanged:)
                         name : ORMotionNodeModelVersionChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(isAccelOnlyChanged:)
                         name : ORMotionNodeModelIsAccelOnlyChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(packetLengthChanged:)
                         name : ORMotionNodeModelPacketLengthChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(traceIndexChanged:)
                         name : ORMotionNodeModelTraceIndexChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(nodeRunningChanged:)
                         name : ORMotionNodeModelNodeRunningChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : [model serialPort]];
    
    [notifyCenter addObserver : self
                     selector : @selector(temperatureChanged:)
                         name : ORMotionNodeModelTemperatureChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(dispayComponentsChanged:)
                         name : ORMotionNodeModelDisplayComponentsChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(showDeltaFromAveChanged:)
                         name : ORMotionNodeModelShowDeltaFromAveChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateLongTermView:)
                         name : ORMotionNodeModelUpdateLongTermTrace
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(startTimeChanged:)
                         name : ORMotionNodeModelStartTimeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(longTermSensitivityChanged:)
                         name : ORMotionNodeModelLongTermSensitivityChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(showLongTermDeltaChanged:)
                         name : ORMotionNodeModelShowLongTermDeltaChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(keepHistoryChanged:)
                         name : ORMotionNodeModelKeepHistoryChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(autoStartChanged:)
                         name : ORMotionNodeModelAutoStartChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(autoStartWithOrcaChanged:)
                         name : ORMotionNodeModelAutoStartWithOrcaChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(shipThresholdChanged:)
                         name : ORMotionNodeModelShipThresholdChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(shipExcursionsChanged:)
                         name : ORMotionNodeModelShipExcursionsChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(outOfBandChanged:)
                         name : ORMotionNodeModelOutOfBandChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lastRecordShippedChanged:)
                         name : ORMotionNodeModelLastRecordShippedChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(totalShippedChanged:)
                         name : ORMotionNodeModelTotalShippedChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(historyFolderChanged:)
                         name : ORMotionNodeModelHistoryFolderChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateHistoryPlot:)
                         name : ORMotionNodeModelUpdateHistoryPlot
                        object: model];
    
    [serialPortController registerNotificationObservers];
    
}

- (void) updateWindow
{
    [ super updateWindow ];
	[self serialNumberChanged:nil];
	[self versionChanged:nil];
	[self isAccelOnlyChanged:nil];
	[self packetLengthChanged:nil];
	[self traceIndexChanged:nil];
	[self nodeRunningChanged:nil];
    [self lockChanged:nil];
	[self temperatureChanged:nil];
	[self dispayComponentsChanged:nil];
	[self showDeltaFromAveChanged:nil];
	[self updateLongTermView:nil];
	[self startTimeChanged:nil];
	[self longTermSensitivityChanged:nil];
	[self showLongTermDeltaChanged:nil];
    [self keepHistoryChanged:nil];
    [self autoStartChanged:nil];
    [self autoStartWithOrcaChanged:nil];
	[self shipThresholdChanged:nil];
	[self shipExcursionsChanged:nil];
	[self outOfBandChanged:nil];
	[self lastRecordShippedChanged:nil];
	[self totalShippedChanged:nil];
    [self historyFolderChanged:nil];
    [self updateHistoryPlot:nil];
	[serialPortController updateWindow];

}
- (void) updateHistoryPlot:(NSNotification*)aNote
{
    [plotter0 setNeedsDisplay:YES];
}

- (void) totalShippedChanged:(NSNotification*)aNote
{
	[totalShippedField setIntValue: [model totalShipped]];
}

- (void) lastRecordShippedChanged:(NSNotification*)aNote
{
	[lastRecordShippedField setObjectValue: [model lastRecordShipped]?(id)[model lastRecordShipped]:@"--"];
}

- (void) outOfBandChanged:(NSNotification*)aNote
{
	[outOfBandField setObjectValue: [model outOfBand]?@"X":@""];
}

- (void) shipExcursionsChanged:(NSNotification*)aNote
{
	[shipExcursionsCB setIntValue: [model shipExcursions]];
	[self updateButtons];
}

- (void) shipThresholdChanged:(NSNotification*)aNote
{
	[shipThresholdSlider setFloatValue: [model shipThreshold]];
	[shipThresholdField setFloatValue: [model shipThreshold]];
}
- (void) keepHistoryChanged:(NSNotification*)aNote
{
    [keepHistoryCB setIntValue: [model keepHistory]];
}

- (void) autoStartChanged:(NSNotification*)aNote
{
	[autoStartCB setIntValue: [model autoStart]];
}
- (void) autoStartWithOrcaChanged:(NSNotification*)aNote
{
    [autoStartWithOrcaCB setIntValue: [model autoStartWithOrca]];
}
- (void) showLongTermDeltaChanged:(NSNotification*)aNote
{
	[showLongTermDeltaCB setIntValue: [model showLongTermDelta]];
	[longTermView setNeedsDisplay:YES];
}

- (void) longTermSensitivityChanged:(NSNotification*)aNote
{
	[sensitivitySlider setIntValue: [model longTermSensitivity]];
	[sensitivityField setIntValue:[model longTermSensitivity]];
}

- (void) startTimeChanged:(NSNotification*)aNote
{
    NSDate* st = [((ORMotionNodeModel*)model) startTime];
	if(st)[startTimeField setObjectValue: st];
	else [startTimeField setObjectValue: @""];
}

- (void) updateLongTermView:(NSNotification*)aNote
{
	[longTermView setNeedsDisplay:YES];
}

- (void) showDeltaFromAveChanged:(NSNotification*)aNote
{
	[showDeltaFromAveCB setIntValue: [model showDeltaFromAve]];
	[tracePlot setNeedsDisplay:YES];
}

- (void) dispayComponentsChanged:(NSNotification*)aNote
{
	[displayComponentsMatrix selectCellWithTag: [model displayComponents]];
	if([model displayComponents]){
		[xLabel setStringValue:@"Ax"];
		[yLabel setStringValue:@"Ay"];
		[zLabel setStringValue:@"Az"];
	}
	else {
		[xLabel setStringValue:@"1-Total"];
		[yLabel setStringValue:@""];
		[zLabel setStringValue:@""];
	}
	[tracePlot setNeedsDisplay:YES];
}

- (void) temperatureChanged:(NSNotification*)aNote
{
	[temperatureField setFloatValue: [model temperature]];
}

- (void) portStateChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}	
	
- (void) nodeRunningChanged:(NSNotification*)aNote
{
	if([model nodeVersion] == 0){
		[nodeRunningField setObjectValue: [model nodeRunning]?@"FLUSHING":@"NO"];
	}
	else {
		[nodeRunningField setObjectValue: [model nodeRunning]?@"YES":@"NO"];
	}
	[self updateButtons];
}

- (void) traceIndexChanged:(NSNotification*)aNote
{
	[tracePlot setNeedsDisplay:YES];
}

- (void) packetLengthChanged:(NSNotification*)aNote
{
	[packetLengthField setIntValue: [model packetLength]];
}

- (void) isAccelOnlyChanged:(NSNotification*)aNote
{
	[isAccelOnlyField setStringValue: [model isAccelOnly]?@"Acc":@"Full"];
}

- (void) versionChanged:(NSNotification*)aNote
{
	[versionField setIntValue: [model nodeVersion]];
	[self updateButtons];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMotionNodeModelLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) updateButtons
{
    BOOL locked		= [gSecurity isLocked:ORMotionNodeModelLock];
	BOOL portOpen	= [[model serialPort] isOpen];
	BOOL nodeRunning = [model nodeRunning];
	BOOL nodeValid = ([model nodeVersion] != 0);
    [lockButton setState: locked];
	[startButton setEnabled: portOpen && !locked && !nodeRunning && nodeValid];
	[stopButton setEnabled: portOpen && !locked && nodeRunning && nodeValid];
	[shipThresholdField setEnabled: portOpen && !locked && [model shipExcursions]];
	[shipThresholdSlider setEnabled: portOpen && !locked && [model shipExcursions]];
	[shipExcursionsCB setEnabled: portOpen && !locked];
    
    [setHistoryFolderButton setEnabled: !locked ];

	
	[serialPortController updateButtons:locked];
}

- (void) lockChanged:(NSNotification*)aNote
{
	[self updateButtons];
}

- (void) serialNumberChanged:(NSNotification*)aNote
{
	[[self window] setTitle:[model title]];
}

- (BOOL) portLocked
{
	return [gSecurity isLocked:ORMotionNodeModelLock];
}

- (void) historyFolderChanged:(NSNotification*)aNote
{
	[historyFolderField setStringValue: [[model historyFolder] stringByAbbreviatingWithTildeInPath]];
}


#pragma mark •••Actions

- (void) shipExcursionsAction:(id)sender
{
	[model setShipExcursions:[sender intValue]];	
}

- (void) shipThresholdAction:(id)sender
{
	[model setShipThreshold:[sender floatValue]];	
}
- (void) keepHistoryAction:(id)sender
{
    [model setKeepHistory:[sender intValue]];
}

- (void) autoStartAction:(id)sender
{
	[model setAutoStart:[sender intValue]];	
}

- (void) autoStartWithOrcaAction:(id)sender
{
    [model setAutoStartWithOrca:[sender intValue]];
}

- (void) showLongTermDeltaAction:(id)sender
{
	[model setShowLongTermDelta:[sender intValue]];	
}

- (IBAction) longTermSensitivityAction:(id)sender
{
	[model setLongTermSensitivity:[sender intValue]];	
	[longTermView setNeedsDisplay:YES];
}

- (IBAction) showDeltaFromAveAction:(id)sender
{
	[model setShowDeltaFromAve:[sender intValue]];	
}

- (IBAction) displayComponentsAction:(id)sender
{
	[model setDisplayComponents:[[displayComponentsMatrix selectedCell] tag]];
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORMotionNodeModelLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) readOnboardMemory:(id)sender
{
	[model readOnboardMemory];
}
- (IBAction) readConnect:(id)sender
{
	[model readConnect];
}
- (IBAction) start:(id)sender
{
	[model startDevice];
}
- (IBAction) stop:(id)sender
{
	[model stopDevice];
}

- (int)	numberPointsInPlot:(id)aPlotter
{
    if(aPlotter == [plotter0 topPlot]){
        return (int)[model numPointsInOldHistory]; 
    }
    else {
        NSUInteger set = [aPlotter tag];
        if([model displayComponents]){
            if(set == 3) return 0;
            else return kModeNodeTraceLength;
        }
        else {
            if(set < 3) return 0;
            else return kModeNodeTraceLength;
        }
    }
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
    if(aPlotter == [plotter0 topPlot]){
        if(i==0){
            NSUInteger n = [model numPointsInOldHistory];
            if(n!=0){
                deltaTime           = ([model oldHistoryEndTime]-[model oldHistoryStartTime])/(NSTimeInterval)n;
                [(ORTimeAxis*)[plotter0 xAxis] setStartTime: [model oldHistoryEndTime]];
            }
        }
        *xValue = [model oldHistoryEndTime] - (i*deltaTime);
        *yValue = [model oldHistoryValue:i];
    }
    else {
        double aValue = 0;
        NSUInteger set = [aPlotter tag];
 set = [aPlotter tag];
        if([model showDeltaFromAve]){
            if(set == 0)		aValue =  [model axDeltaAveAt:i];
            else if(set == 1)	aValue =  [model ayDeltaAveAt:i];
            else if(set == 2)	aValue =  [model azDeltaAveAt:i];
            else if(set == 3)	aValue =  [model xyzDeltaAveAt:i];
        }
        else {
            if(set == 0)		aValue =  [model axAt:i];
            else if(set == 1)	aValue =  [model ayAt:i];
            else if(set == 2)	aValue =  [model azAt:i];
            else if(set == 3)	aValue =  [model totalxyzAt:i];
        }
        *xValue = i;
        *yValue = aValue;
    }
}

- (int) startingLineInLongTermView:(id)aView
{
	return [model startingLine];
}

- (int) maxLinesInLongTermView:(id)aLongTermView
{
	return [model maxLinesInLongTermView];
}

- (int) numLinesInLongTermView:(id)aLongTermView
{
	return [model numLinesInLongTermView];
}

- (int) numPointsPerLineInLongTermView:(id)aLongTermView
{
	return [model numPointsPerLineInLongTermView];
}

- (float) longTermView:(id)aLongTermView line:(int)m point:(int)i
{
	return [model longTermDataAtLine:m point:i];
}


- (IBAction) setHistoryFolderAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
	[openPanel setCanCreateDirectories:YES];
    NSString* startingDir;
    if([model historyFolder])startingDir = [model historyFolder];
    else                     startingDir = NSHomeDirectory();
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* folderName = [[[openPanel URL] path] stringByAbbreviatingWithTildeInPath];
            [model setHistoryFolder:folderName];
        }
    }];
}

- (IBAction) viewPastHistoryAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    [openPanel setCanCreateDirectories:NO];
    NSString* startingDir;
    if([model historyFolder])startingDir = [model historyFolder];
    else                     startingDir = NSHomeDirectory();
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* path = [[[openPanel URL] path] stringByAbbreviatingWithTildeInPath];
            [model viewPastHistory:path];
            [plotter0 setNeedsDisplay:YES];
        }
    }];
}

@end

