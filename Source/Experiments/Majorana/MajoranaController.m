//
//  MajoranaController.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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
#import "MajoranaController.h"
#import "MajoranaModel.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORDetectorSegment.h"
#import "ORSegmentGroup.h"
#import "ORTimeLinePlot.h"
#import "ORTimeAxis.h"
#import "OR1DHistoPlot.h"
#import "ORPlotView.h"
#import "ORCompositePlotView.h"
#import "ORiSegHVCard.h"
#import "ORMJDInterlocks.h"
#import "ORMJDSource.h"
#import "ORTimedTextField.h"

@implementation MajoranaController
#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Majorana"];
    return self;
}
- (void) dealloc
{
    [blankView release];
    [super dealloc];
}

- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/MJDDetectorMap";
}

- (NSString*) defaultSecondaryMapFilePath
{
	return @"~/MJDVetoMap";
}

- (void) awakeFromNib
{
	detectorSize		 = NSMakeSize(770,740);
	detailsSize			 = NSMakeSize(560,600);
	subComponentViewSize = NSMakeSize(590,665);
	detectorMapViewSize	 = NSMakeSize(900,760);
    vetoMapViewSize		 = NSMakeSize(580,565);
    calibrationViewSize	 = NSMakeSize(580,340);
    
    [module1InterlockTable setFocusRingType:NSFocusRingTypeNone];
    [module2InterlockTable setFocusRingType:NSFocusRingTypeNone];
    
    [secondaryTableView setFocusRingType:NSFocusRingTypeNone];
    [stringMapTableView setFocusRingType:NSFocusRingTypeNone];
    [specialChannelsTableView setFocusRingType:NSFocusRingTypeNone];

    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	[subComponentsView setGroup:model];

    [super awakeFromNib];
	
    if([[model segmentGroup:1] colorAxisAttributes])[[secondaryColorScale colorAxis] setAttributes:[[[[model segmentGroup:1] colorAxisAttributes] mutableCopy] autorelease]];
    
	[[secondaryColorScale colorAxis] setRngLimitsLow:0 withHigh:128000000 withMinRng:5];
    [[secondaryColorScale colorAxis] setRngDefaultsLow:0 withHigh:128000000];
    [[secondaryColorScale colorAxis] setOppositePosition:YES];
	[[secondaryColorScale colorAxis] setNeedsDisplay:YES];
    
	[self populateClassNamePopup:secondaryAdcClassNamePopup];

    [primaryAdcClassNamePopup   selectItemAtIndex:1];
    [secondaryAdcClassNamePopup selectItemAtIndex:1];
    
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:1 andDataSource:self];
	[aPlot setLineColor:[NSColor blueColor]];
	[ratePlot addPlot: aPlot];
	[aPlot release];
	
	OR1DHistoPlot* aPlot1 = [[OR1DHistoPlot alloc] initWithTag:11 andDataSource:self];
	[aPlot1 setLineColor:[NSColor blueColor]];
    [aPlot1 setName:@"Veto"];
	[valueHistogramsPlot addPlot: aPlot1];
	[aPlot1 release];
    [(ORPlot*)[valueHistogramsPlot plotWithTag: 10] setName:@"Detectors"];
    [valueHistogramsPlot setShowLegend:YES];
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORMajoranaModelPollTimeChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(viewTypeChanged:)
                         name : ORMajoranaModelViewTypeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(secondaryColorAxisAttributesChanged:)
                         name : ORAxisRangeChangedNotification
                       object : [secondaryColorScale colorAxis]];
    
    [notifyCenter addObserver : self
                     selector : @selector(secondaryAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
						object: [model segmentGroup:1]];
    
    [notifyCenter addObserver : self
                     selector : @selector(secondaryMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
						object: [model segmentGroup:1]];
    
    [notifyCenter addObserver : self
                     selector : @selector(vetoMapLockChanged:)
                         name : [model vetoMapLock]
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(vetoMapLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(auxTablesChanged:)
                         name : ORMJDAuxTablesChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ignorePanicOnAChanged:)
                         name : MajoranaModelIgnorePanicOnAChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ignorePanicOnBChanged:)
                         name : MajoranaModelIgnorePanicOnBChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(ignoreBreakdownCheckOnAChanged:)
                         name : MajoranaModelIgnoreBreakdownCheckOnAChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(ignoreBreakdownCheckOnBChanged:)
                         name : MajoranaModelIgnoreBreakdownCheckOnBChanged
                        object: model];
 
    [notifyCenter addObserver : self
                     selector : @selector(ignoreBreakdownPanicOnAChanged:)
                         name : MajoranaModelIgnoreBreakdownPanicOnAChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(ignoreBreakdownPanicOnBChanged:)
                         name : MajoranaModelIgnoreBreakdownPanicOnBChanged
                        object: model];

    
    [notifyCenter addObserver : self
                     selector : @selector(updateInterlockStates:)
                         name : ORMJDInterlocksStateChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateLastConstraintCheck:)
                         name : ORMajoranaModelLastConstraintCheckChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(sourceStateChanged:)
                         name : ORMJDSourceStateChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(sourceIsMovingChanged:)
                         name : ORMJDSourceIsMovingChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(sourceIsConnectedChanged:)
                         name : ORMJDSourceIsConnectedChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(sourceModeChanged:)
                         name : ORMJDSourceModeChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(sourcePatternChanged:)
                         name : ORMJDSourcePatternChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(sourceGatevalveChanged:)
                         name : ORMJDSourceGateValveChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(calibrationLockChanged:)
                         name : [model calibrationLock]
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(sourceIsInChanged:)
                         name : ORMJDSourceIsInChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(breakdownDetectedChanged:)
                         name : ORMajoranaModelUpdateSpikeDisplay
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(maxNonCalibrationRateChanged:)
                         name : ORMajoranaModelMaxNonCalibrationRate
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(verboseDiagnosticsChanged:)
                         name : ORMajoranaModelVerboseDiagnosticsChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(minNumDetsToAlertExpertsChanged:)
                         name : ORMajoranaModelMinNumDetsToAlertExperts
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(calibrationStatusChanged:)
                         name : ORMajoranaModelCalibrationStatusChanged
                       object : nil];
}


- (void) updateWindow
{
    [super updateWindow];
	[self pollTimeChanged:nil];
	[self viewTypeChanged:nil];
    //detector
    [self secondaryColorAxisAttributesChanged:nil];
    [self auxTablesChanged:nil];
    [self maxNonCalibrationRateChanged:nil];
    
	//veto hw map
    [self vetoMapLockChanged:nil];
	[self secondaryMapFileChanged:nil];
	[self secondaryAdcClassNameChanged:nil];
    
	//details
	[secondaryValuesView reloadData];
	[self ignorePanicOnAChanged:nil];
	[self ignorePanicOnBChanged:nil];
    [self ignoreBreakdownCheckOnAChanged:nil];
    [self ignoreBreakdownCheckOnBChanged:nil];
    [self ignoreBreakdownPanicOnAChanged:nil];
    [self ignoreBreakdownPanicOnBChanged:nil];

    
    //interlocks
    [self groupChanged:nil];
    [module1InterlockTable reloadData];
    [module2InterlockTable reloadData];
    [self updateLastConstraintCheck:nil];
    [self breakdownDetectedChanged:nil];
    [self sourceStateChanged:nil];
    [self verboseDiagnosticsChanged:nil];
    [self minNumDetsToAlertExpertsChanged:nil];
    
    //Source
    [self calibrationLockChanged:nil];
    [self sourceIsMovingChanged:nil];
    [self sourceIsConnectedChanged:nil];
    [self sourceModeChanged:nil];
    [self sourcePatternChanged:nil];
    [self sourceGatevalveChanged:nil];
    [self sourceIsInChanged:nil];
    [self calibrationStatusChanged:nil];
}

- (void) calibrationStatusChanged:(NSNotification*)aNote
{
    [calibrationStatusField setTimeOut:10];
    [calibrationStatusField setStringValue:[model calibrationStatus]];
}

- (void) minNumDetsToAlertExpertsChanged:(NSNotification*)aNote
{
    [minNumDetsToAlertExpertsField setIntValue:[model minNumDetsToAlertExperts]];
}
- (void) verboseDiagnosticsChanged:(NSNotification*)aNote
{
    [verboseDiagnosticsCB setState:[model verboseDiagnostics]];
}

- (void) sourceIsInChanged:(NSNotification*)aNote
{
    if(!aNote){
        [sourceIsInField1 setStringValue:[self sourceIsInState:0]];
        [sourceIsInField0 setStringValue:[self sourceIsInState:1]];
    }
    else {
        if([aNote object] == [model mjdSource:0])[sourceIsInField0 setStringValue:[self sourceIsInState:0]];
        else                                     [sourceIsInField1 setStringValue:[self sourceIsInState:1]];
    }
    [self updateCalibrationButtons];
}

- (void) sourceGatevalveChanged:(NSNotification*)aNote
{
    if(!aNote){
        [gateValveStateField0 setStringValue:[self sourceGateValveState:0]];
        [gateValveStateField1 setStringValue:[self sourceGateValveState:1]];
    }
    else {
        if([aNote object] == [model mjdSource:0])[gateValveStateField0 setStringValue:[self sourceGateValveState:0]];
        else                                     [gateValveStateField1 setStringValue:[self sourceGateValveState:1]];
    }
    [self updateCalibrationButtons];
}

- (void) sourcePatternChanged:(NSNotification*)aNote
{
    if(!aNote){
        [patternField0 setStringValue:[self order:0]];
        [patternField1 setStringValue:[self order:1]];
    }
    else {
        if([aNote object] == [model mjdSource:0])[patternField0 setStringValue:[self order:0]];
        else                                     [patternField1 setStringValue:[self order:1]];
    }
}

- (NSString*) sourceIsInState:(int)index
{
    return [[model mjdSource:index] sourceIsInState];
}


- (NSString*) sourceGateValveState:(int)index
{
    return [[model mjdSource:index] gateValveState];
}

- (NSString*) order:(int)index
{
    ORMJDSource* sourceObj = [model mjdSource:index];
    NSString* order = [sourceObj order];
    if([order length]==0)order = @"";
    if([order length]>30)order = [order substringFromIndex:[order length]-30];
    return order;
}

- (void) sourceModeChanged:(NSNotification*)aNote
{
    if(!aNote){
        [modeField0 setStringValue:[[model mjdSource:0] modeString]];
        [modeField1 setStringValue:[[model mjdSource:1] modeString]];
    }
    else {
        if([aNote object] == [model mjdSource:0])[modeField0 setStringValue:[[model mjdSource:0] modeString]];
        else                                     [modeField1 setStringValue:[[model mjdSource:1] modeString]];
    }
    
    [self updateCalibrationButtons];
}

- (void) sourceIsMovingChanged:(NSNotification*)aNote
{
    if(!aNote){
        [isMovingField0 setStringValue:[[model mjdSource:0] movingState]];
        [isMovingField1 setStringValue:[[model mjdSource:1] movingState]];
        if([[model mjdSource:0] isMoving] == kMJDSource_True)   [progress0 startAnimation:nil];
        else                                                    [progress0 stopAnimation:nil];
        if([[model mjdSource:1] isMoving] == kMJDSource_True)   [progress1 startAnimation:nil];
        else                                                    [progress1 stopAnimation:nil];
    }
    else {
        if([aNote object] == [model mjdSource:0]){
            [isMovingField0 setStringValue:[[model mjdSource:0] movingState]];
            if([[model mjdSource:0] isMoving] == kMJDSource_True)   [progress0 startAnimation:nil];
            else                                                    [progress0 stopAnimation:nil];
        }
        else {
            [isMovingField1 setStringValue:[[model mjdSource:1] movingState]];
            if([[model mjdSource:1] isMoving] == kMJDSource_True)   [progress1 startAnimation:nil];
            else                                                    [progress1 stopAnimation:nil];
        }
    }
    [self updateCalibrationButtons];
}

- (void) sourceIsConnectedChanged:(NSNotification*)aNote
{
    if(!aNote){
        [isConnectedField0 setStringValue:[[model mjdSource:0] movingState]];
        [isConnectedField1 setStringValue:[[model mjdSource:1] movingState]];
    }
    else {
        if([aNote object] == [model mjdSource:0]) [isConnectedField0 setStringValue:[[model mjdSource:0] connectedState]];
        else                                      [isConnectedField1 setStringValue:[[model mjdSource:1] connectedState]];
    }
    [self updateCalibrationButtons];
}

- (void) sourceStateChanged:(NSNotification*)aNote
{
    if(!aNote){
        [sourceStateField0 setStringValue:[[model mjdSource:0] currentStateName]];
        [sourceStateField1 setStringValue:[[model mjdSource:1] currentStateName]];
    }
    else {
        if([aNote object] == [model mjdSource:0])[sourceStateField0 setStringValue:[[model mjdSource:0] currentStateName]];
        else                                     [sourceStateField1 setStringValue:[[model mjdSource:1] currentStateName]];
    }
    [self updateCalibrationButtons];
 }

- (void) updateLastConstraintCheck:(NSNotification*)aNote
{
    if([model lastConstraintCheck]) [lastTimeCheckedField setStringValue:[[model lastConstraintCheck] stdDescription]];
    else [lastTimeCheckedField setStringValue:@"Never"];
}

- (void) updateInterlockStates:(NSNotification*)aNote
{
    if([aNote object] == [model mjdInterlocks:0]){
        [module1InterlockTable reloadData];
    }
    else {
        [module2InterlockTable setNeedsDisplay:YES];
   }
}

- (void) breakdownDetectedChanged:(NSNotification*)aNote
{
#define kIgnore 2
    [rate1BiState     setState:[model ignoreBreakdownCheckOnB]?kIgnore:![model rateSpikes:0]];
    [rate2BiState     setState:[model ignoreBreakdownCheckOnA]?kIgnore:![model rateSpikes:1]];
    [baseline1BiState setState:[model ignoreBreakdownCheckOnB]?kIgnore:![model baselineExcursions:0]];
    [baseline2BiState setState:[model ignoreBreakdownCheckOnA]?kIgnore:![model baselineExcursions:1]];
    [vac1BiState      setState:[model ignoreBreakdownCheckOnB]?kIgnore:![model vacuumSpike:0]];
    [vac2BiState      setState:[model ignoreBreakdownCheckOnA]?kIgnore:![model vacuumSpike:1]];
    
    if([model ignoreBreakdownCheckOnB]){
        [breakdown1Field setStringValue:@"Skipped"];
        [filling1Field   setStringValue:@"Skipped"];
    }
    else {
        if([model fillingLN:0])             [filling1Field setStringValue:@"YES"];
        else                                [filling1Field setStringValue:@"NO"];
        if([model breakdownAlarmPosted:0])  [breakdown1Field setStringValue:@"YES"];
        else                                [breakdown1Field setStringValue:@"NO"];
    }

    if([model ignoreBreakdownCheckOnA]){
        [breakdown2Field setStringValue:@"Skipped"];
        [filling2Field   setStringValue:@"Skipped"];
    }
    else {
        if([model fillingLN:1])     [filling2Field setStringValue:@"YES"];
        else                        [filling2Field setStringValue:@"NO"];
        if([model breakdownAlarmPosted:1])  [breakdown2Field setStringValue:@"YES"];
        else                                [breakdown2Field setStringValue:@"NO"];
    }
  
}

- (void) auxTablesChanged:(NSNotification*)aNote
{
	[stringMapTableView reloadData];
    [specialChannelsTableView reloadData];
    [detectorView makeAllSegments];
}

- (void) checkGlobalSecurity
{
    [super checkGlobalSecurity];
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:[model vetoMapLock] to:secure];
    [vetoMapLockButton setEnabled: secure];
    [gSecurity setLock:[model calibrationLock] to:secure];
    [calibrationLockButton setEnabled: secure];
}

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[subComponentsView setNeedsDisplay:YES];
	}
}

- (void) pollTimeChanged:(NSNotification*)aNotification
{
	[pollTimePopup selectItemAtIndex:[model pollTime]];
}

- (void) vetoMapLockChanged:(NSNotification*)aNotification
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model vetoMapLock]];
    //BOOL runningOrLocked = [gSecurity runInProgressOrIsLocked:ORPrespectrometerLock];
    BOOL locked = [gSecurity isLocked:[model vetoMapLock]];
    [vetoMapLockButton setState: locked];
    
    if(locked){
		[secondaryTableView deselectAll:self];
	}
    [readSecondaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
    [saveSecondaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
	[secondaryAdcClassNamePopup setEnabled:!lockedOrRunningMaintenance];
}

- (void) calibrationLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:[model calibrationLock]];
    [calibrationLockButton setState: locked];
    [self updateCalibrationButtons];
}

- (void) secondaryAdcClassNameChanged:(NSNotification*)aNote
{
	[secondaryAdcClassNamePopup selectItemWithTitle: [[model segmentGroup:1] adcClassName]];
}

- (void) secondaryMapFileChanged:(NSNotification*)aNote
{
	NSString* s = [[[model segmentGroup:1] mapFile]stringByAbbreviatingWithTildeInPath];
	if(!s) s = @"--";
	[secondaryMapFileTextField setStringValue: s];
}

- (void) colorScaleTypeChanged:(NSNotification*)aNote
{
    [super colorScaleTypeChanged:aNote];
    [secondaryColorScale setUseRainBow:[model colorScaleType]==0];
    [secondaryColorScale setStartColor:[primaryColorScale startColor]];
    [secondaryColorScale setEndColor:[primaryColorScale endColor]];
}


- (void) viewTypeChanged:(NSNotification*)aNote
{
	[viewTypePU selectItemAtIndex:[model viewType]];
	[detectorView setViewType:[model viewType]];
    [detectorView makeAllSegments];
}

- (void) maxNonCalibrationRateChanged:(NSNotification*)aNote
{
    [maxNonCalibrationRateField setFloatValue:[model maxNonCalibrationRate]];
}


#pragma mark ¥¥¥Interface Management
- (void) ignorePanicOnBChanged:(NSNotification*)aNote
{
	[ignorePanicOnBCB setIntValue: [model ignorePanicOnB]];
    [ignore1Field setStringValue: [model ignorePanicOnB]?@"HV Ramp will be IGNORED":@""];
}

- (void) ignorePanicOnAChanged:(NSNotification*)aNote
{
	[ignorePanicOnACB setIntValue: [model ignorePanicOnA]];
    [ignore2Field setStringValue: [model ignorePanicOnA]?@"HV Ramp will be IGNORED":@""];
}

- (void) ignoreBreakdownCheckOnBChanged:(NSNotification*)aNote
{
    [ignoreBreakdownCheckOnBCB setIntValue: ![model ignoreBreakdownCheckOnB]];
    [ignoreBreakdownCheck1Field setStringValue: [model ignoreBreakdownCheckOnB]?@"Breakdown checks SKIPPED":@""];
    [self breakdownDetectedChanged:nil];
}

- (void) ignoreBreakdownCheckOnAChanged:(NSNotification*)aNote
{
    [ignoreBreakdownCheckOnACB setIntValue: ![model ignoreBreakdownCheckOnA]];
    [ignoreBreakdownCheck2Field setStringValue: [model ignoreBreakdownCheckOnA]?@"Breakdown checks SKIPPED":@""];
    [self breakdownDetectedChanged:nil];
}
- (void) ignoreBreakdownPanicOnBChanged:(NSNotification*)aNote
{
    [ignoreBreakdownPanicOnBCB setIntValue: [model ignoreBreakdownPanicOnB]];
    [ignoreBreakdownPanic1Field setStringValue: [model ignoreBreakdownPanicOnB]?@"Panic on breakdown Disabled":@""];
    [self breakdownDetectedChanged:nil];
}

- (void) ignoreBreakdownPanicOnAChanged:(NSNotification*)aNote
{
    [ignoreBreakdownPanicOnACB setIntValue: [model ignoreBreakdownPanicOnA]];
    [ignoreBreakdownPanic2Field setStringValue: [model ignoreBreakdownPanicOnA]?@"Panic on breakdown Disabled":@""];
    [self breakdownDetectedChanged:nil];
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[secondaryTableView reloadData];
	[secondaryValuesView reloadData];
    [specialChannelsTableView reloadData];
}

- (void) segmentGroupChanged:(NSNotification*)aNote
{
	[super segmentGroupChanged:aNote];
    [detectorView makeAllSegments];
}

- (void) setDetectorTitle
{	
	switch([model displayType]){
		case kDisplayRates:			[detectorTitle setStringValue:@"Rates"];        break;
		case kDisplayThresholds:	[detectorTitle setStringValue:@"Thresholds"];	break;
		case kDisplayTotalCounts:	[detectorTitle setStringValue:@"Total Counts"];	break;
		default: break;
	}
}

- (void) newTotalRateAvailable:(NSNotification*)aNotification
{
	[super newTotalRateAvailable:aNotification];
	[secondaryRateField setFloatValue:[[model segmentGroup:1] rate]];
}

- (void) secondaryColorAxisAttributesChanged:(NSNotification*)aNotification
{
	BOOL isLog = [[secondaryColorScale colorAxis] isLog];
	[secondaryColorAxisLogCB setState:isLog];
	[[model segmentGroup:1] setColorAxisAttributes:[[secondaryColorScale colorAxis] attributes]];
}

- (void) mapFileRead:(NSNotification*)mapFileRead
{
	[super mapFileRead:mapFileRead];
	[self auxTablesChanged:nil];
    int n = [[model segmentGroup:0] numSegments];
    int i;
    for(i=0;i<n;i++){
        [self forceHVUpdate:i];
    }
}

#pragma mark ¥¥¥Calibration Interface Management
- (void) updateCalibrationButtons
{
    //BOOL locked         = [gSecurity isLocked:[model calibrationLock]];
    BOOL locked         = NO; //at Ralph's request
    
    BOOL running0       = [[model mjdSource:0] currentState]!= kMJDSource_Idle;
    BOOL isDeploying0   = [[model mjdSource:0] isDeploying];
    BOOL isRetacting0   = [[model mjdSource:0] isRetracting];
    BOOL sourceIn0      = [[model mjdSource:0] sourceIsIn] == kMJDSource_True;
    BOOL gvStateKnown0  = [[model mjdSource:0] gateValveIsOpen]!=kMJDSource_Unknown;
  
    BOOL running1       = [[model mjdSource:1] currentState]!= kMJDSource_Idle;
    BOOL isRetacting1   = [[model mjdSource:1] isRetracting];
    BOOL isDeploying1   = [[model mjdSource:1] isDeploying];
    BOOL sourceIn1      = [[model mjdSource:1] sourceIsIn] == kMJDSource_True;
    BOOL gvStateKnown1  = [[model mjdSource:1] gateValveIsOpen]!=kMJDSource_Unknown;
   
    [deploySourceButton0    setEnabled:!locked && (!running0 || (!isDeploying0 && isRetacting0))];
    [retractSourceButton0   setEnabled:!locked && (!running0 || (isDeploying0 && !isRetacting0))];
    [stopSourceButton0      setEnabled:!locked && (isDeploying0 || isRetacting0)];
    [checkSourceGateValveButton0 setEnabled:!locked && !running0 && !isDeploying0 && !isRetacting0];
    [closeGVButton0         setEnabled:!locked && !sourceIn0 && !running0 && !isDeploying0 && !isRetacting0 && gvStateKnown0];
     
    [deploySourceButton1    setEnabled:!locked && (!running1 || (!isDeploying1 && isRetacting1))];
    [retractSourceButton1   setEnabled:!locked && (!running1 || (isDeploying1 && !isRetacting1))];
    [stopSourceButton1      setEnabled:!locked && (isDeploying1 || isRetacting1)];
    [checkSourceGateValveButton1 setEnabled:!locked && !running1 && !isDeploying1 && !isRetacting1];
    [closeGVButton1         setEnabled:!locked && !sourceIn1 && !running1 && !isDeploying1 && !isRetacting1 && gvStateKnown1];
}

#pragma mark ¥¥¥Details Interface Management
- (void) refreshSegmentTables:(NSNotification*)aNote
{
	[super refreshSegmentTables:aNote];
	[secondaryTableView reloadData];
}

- (void) detailsLockChanged:(NSNotification*)aNotification
{
	[super detailsLockChanged:aNotification];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetailsLock]];
    BOOL locked = [gSecurity isLocked:[model experimentDetailsLock]];

	[detailsLockButton setState: locked];
    [initButton setEnabled:     !lockedOrRunningMaintenance];
    [initVetoButton setEnabled: !lockedOrRunningMaintenance];
}

#pragma mark ***Actions
- (IBAction) maxNonCalibrationRateAction:(id)sender;
{
    [model setMaxNonCalibrationRate:[sender floatValue]];
}
- (IBAction) ignorePanicOnAAction:(id)sender
{
    [self confirmIgnoreForModule:0];
}
- (IBAction) ignorePanicOnBAction:(id)sender
{
    [self confirmIgnoreForModule:1];
}
- (IBAction) ignoreBreakdownCheckOnAAction:(id)sender
{
    [self confirmIgnoreBreakdownCheckForModule:0];
}

- (IBAction) ignoreBreakdownCheckOnBAction:(id)sender
{
    [self confirmIgnoreBreakdownCheckForModule:1];
}
- (IBAction) ignoreBreakdownPanicOnAAction:(id)sender
{
    [self confirmIgnoreBreakdownPanicForModule:0];
}

- (IBAction) ignoreBreakdownPanicOnBAction:(id)sender
{
    [self confirmIgnoreBreakdownPanicForModule:1];
}


- (void) confirmIgnoreForModule:(int)module
{
	BOOL currentState;
    if(module == 0) currentState = [model ignorePanicOnA];
    else            currentState = [model ignorePanicOnB];
    
    NSString* s1 = [NSString stringWithFormat:@"Really Turn %@ Constraint Checking for Module %d HV?",!currentState?@"OFF":@"ON",module==0?2:1];
    if(!currentState)s1 = [s1 stringByAppendingFormat:@"\n\n(HV will NOT ramp down if vac is bad)"];
    else            s1 = [s1 stringByAppendingFormat:@"\n\n(HV will ramp down on next check if vac is bad)"];
    
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s1];
    [alert setInformativeText:@""];
    [alert addButtonWithTitle:[NSString stringWithFormat:@"YES/Turn %@ HV Checks",!currentState?@"OFF":@"ON"]];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if(result == NSAlertFirstButtonReturn){
            if(module == 0) [model setIgnorePanicOnA:!currentState];
            else            [model setIgnorePanicOnB:!currentState];
        }
        else {
            if(module == 0) [model setIgnorePanicOnA:currentState];
            else            [model setIgnorePanicOnB:currentState];
        }
    }];
#else
    NSDictionary* context = [[NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:module],@"module",
                              [NSNumber numberWithInt:currentState],@"currentState",
                              nil] retain]; //release in confirmDidFinish()
    NSBeginAlertSheet(s1,
                      [NSString stringWithFormat:@"YES/Turn %@ HV Checks",!currentState?@"OFF":@"ON"],
					  @"Cancel",
					  nil,[self window],
					  self,
					  @selector(confirmDidFinish:returnCode:contextInfo:),
					  nil,
					  context,
					  @"");
#endif
}

- (void) confirmIgnoreBreakdownCheckForModule:(int)module
{
    BOOL currentState;
    if(module == 0) currentState = [model ignoreBreakdownCheckOnA];
    else            currentState = [model ignoreBreakdownCheckOnB];
    
    NSString* s1 = [NSString stringWithFormat:@"Really %@ Breakdown Checks for Module %d?",!currentState?@"SKIP":@"Resume",module==0?2:1];
    if(!currentState)s1 = [s1 stringByAppendingFormat:@"\n\n(Breakdown checking will be SKIPPED!)"];
    else             s1 = [s1 stringByAppendingFormat:@"\n\n(Breakdown checking will be resumed)"];
    
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s1];
    [alert setInformativeText:@""];
    if(currentState)[alert addButtonWithTitle:[NSString stringWithFormat:@"YES/Resume Breakdown Checks"]];
    else            [alert addButtonWithTitle:[NSString stringWithFormat:@"YES/Skip Breakdown Checks"]];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if(result == NSAlertFirstButtonReturn){
            if(module == 0) [model setIgnoreBreakdownCheckOnA:!currentState];
            else            [model setIgnoreBreakdownCheckOnB:!currentState];
        }
        else {
            if(module == 0) [model setIgnoreBreakdownCheckOnA:currentState];
            else            [model setIgnoreBreakdownCheckOnB:currentState];
        }
    }];
#else
    NSDictionary* context = [[NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:module],@"module",
                              [NSNumber numberWithInt:currentState],@"currentState",
                              nil] retain]; //release in confirmDidFinish()
    NSBeginAlertSheet(s1,
                      [NSString stringWithFormat:@"YES/%@ Checks",!currentState?@"Skip Breakdown ":@"Resume Breakdown "],
                      @"Cancel",
                      nil,[self window],
                      self,
                      @selector(breakdownIgnoreConfirmDidFinish:returnCode:contextInfo:),
                      nil,
                      context,
                      @"");
#endif
}

- (void) confirmIgnoreBreakdownPanicForModule:(int)module
{
    BOOL currentState;
    if(module == 0) currentState = [model ignoreBreakdownPanicOnA];
    else            currentState = [model ignoreBreakdownPanicOnB];
    
    NSString* s1 = [NSString stringWithFormat:@"Really %@ Breakdown Panics for Module %d?",!currentState?@"IGNORE":@"Enable",module==0?2:1];
    if(!currentState)s1 = [s1 stringByAppendingFormat:@"\n\n(Breakdown panics will be IGNORED!)"];
    else             s1 = [s1 stringByAppendingFormat:@"\n\n(Breakdown panics could happen)"];
    
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s1];
    [alert setInformativeText:@""];
    if(currentState)[alert addButtonWithTitle:[NSString stringWithFormat:@"YES/Enable Breakdown Panics"]];
    else            [alert addButtonWithTitle:[NSString stringWithFormat:@"YES/Ignore Breakdown Panics"]];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if(result == NSAlertFirstButtonReturn){
            if(module == 0) [model setIgnoreBreakdownPanicOnA:!currentState];
            else            [model setIgnoreBreakdownPanicOnB:!currentState];
        }
        else {
            if(module == 0) [model setIgnoreBreakdownPanicOnA:currentState];
            else            [model setIgnoreBreakdownPanicOnB:currentState];
        }
    }];
#else
    NSDictionary* context = [[NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:module],@"module",
                              [NSNumber numberWithInt:currentState],@"currentState",
                              nil] retain]; //release in confirmDidFinish()
    NSBeginAlertSheet(s1,
                      [NSString stringWithFormat:@"YES/%@ Checks",!currentState?@"Ignore Breakdown Panics ":@"Enable Breakdown Panics "],
                      @"Cancel",
                      nil,[self window],
                      self,
                      @selector(breakdownIgnoreConfirmDidFinish:returnCode:contextInfo:),
                      nil,
                      context,
                      @"");
#endif
}



#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) confirmDidFinish:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    int module = [[userInfo objectForKey:@"module"]intValue];
    BOOL currentState= [[userInfo objectForKey:@"currentState"]intValue];
    
	if(returnCode == NSAlertFirstButtonReturn){
        if(module == 0) [model setIgnorePanicOnA:!currentState];
        else            [model setIgnorePanicOnB:!currentState];
    }
    else {
        if(module == 0) [model setIgnorePanicOnA:currentState];
        else            [model setIgnorePanicOnB:currentState];
    }
    [userInfo release];
}

- (void) breakdownIgnoreConfirmDidFinish:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    int module = [[userInfo objectForKey:@"module"]intValue];
    BOOL currentState= [[userInfo objectForKey:@"currentState"]intValue];
    
    if(returnCode == NSAlertFirstButtonReturn){
        if(module == 0) [model setIgnoreBreakdownCheckOnA:!currentState];
        else            [model setIgnoreBreakdownCheckOnB:!currentState];
    }
    else {
        if(module == 0) [model setIgnoreBreakdownCheckOnA:currentState];
        else            [model setIgnoreBreakdownCheckOnB:currentState];
    }
    [userInfo release];
}


#endif

- (IBAction) verboseDiagnosticsAction:(id)sender;
{
    [model setVerboseDiagnostics:[sender intValue]];
}

- (IBAction) initDigitizerAction:(id)sender
{
    [model initDigitizers];
}
- (IBAction) initVetoAction:(id)sender
{
    [model initVeto];
}

- (IBAction) resetInterLocksOnModule0:(id)sender
{
    [[model mjdInterlocks:0] reset:YES];
    [model setPollTime:[model pollTime]];
}

- (IBAction) resetInterLocksOnModule1:(id)sender
{
    [[model mjdInterlocks:1] reset:YES];
    [model setPollTime:[model pollTime]];
}
- (IBAction) resetSpikeDictionariesAction:(id)sender
{
    [model resetSpikeDictionaries];
}

- (IBAction) printBreakDownReport:(id)sender    {[model printBreakDownReport];}

- (IBAction) checkSourceGateValve0:(id)sender   {[model checkSourceGateValve:0];}
- (IBAction) deploySourceAction0:(id)sender     {[model deploySource:0];}
- (IBAction) retractSourceAction0:(id)sender    {[model retractSource:0];}
- (IBAction) stopSourceAction0:(id)sender       {[model stopSource:0];}
- (IBAction) closeGateValve0:(id)sender         {[self confirmCloseGateValve:0];}

- (IBAction) checkSourceGateValve1:(id)sender   {[model checkSourceGateValve:1];}
- (IBAction) deploySourceAction1:(id)sender     {[model deploySource:1];}
- (IBAction) retractSourceAction1:(id)sender    {[model retractSource:1];}
- (IBAction) stopSourceAction1:(id)sender       {[model stopSource:1];}
- (IBAction) closeGateValve1:(id)sender         {[self confirmCloseGateValve:1];}

- (void) confirmCloseGateValve:(int)index
{
    NSString* s1 = [NSString stringWithFormat:@"Really Close Module %d Source Gatevalve?",index];
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s1];
    [alert setInformativeText:@"An attempt will be made to confirm that the source is retracted, but you should manually check its position before proceeding!"];
    [alert addButtonWithTitle:[NSString stringWithFormat:@"YES/Close It"]];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if(result == NSAlertFirstButtonReturn){
            [[model mjdSource:index] closeGateValve];
        }
    }];
  
}

- (IBAction) pollTimeAction:(id)sender
{
    [[model mjdInterlocks:0] reset:YES];
    [[model mjdInterlocks:1] reset:YES];
	[model setPollTime:(int)[sender indexOfSelectedItem]];
}
- (IBAction) viewTypeAction:(id)sender
{
	[model setViewType:(int)[sender indexOfSelectedItem]];
}

- (IBAction) autoscaleSecondayColorScale:(id)sender
{
    int n = [[model segmentGroup:1] numSegments];
    int i;
    float maxValue = -99999;
    for(i=0;i<n;i++){
        float aValue = maxValue;
        switch([model displayType]){
            case kDisplayThresholds:	aValue = [[model segmentGroup:1] getThreshold:i];     break;
            case kDisplayRates:			aValue = [[model segmentGroup:1] getRate:i];		  break;
            case kDisplayTotalCounts:	aValue = [[model segmentGroup:1] getTotalCounts:i];   break;
            default:	break;
        }
        if(aValue>maxValue)maxValue = aValue;
    }
    if(maxValue != -99999){
        maxValue += (maxValue*.20);
        [[secondaryColorScale colorAxis] setRngLow:0 withHigh:maxValue];
    }
}

- (IBAction) secondaryAdcClassNameAction:(id)sender
{
	[[model segmentGroup:1] setAdcClassName:[sender titleOfSelectedItem]];
}

- (IBAction) vetoMapLockAction:(id)sender
{
    [gSecurity tryToSetLock:[model vetoMapLock] to:[sender intValue] forWindow:[self window]];
}

- (IBAction) calibrationLockAction:(id)sender
{
    [gSecurity tryToSetLock:[model calibrationLock] to:[sender intValue] forWindow:[self window]];
}

- (IBAction) minNumDetsToAlertExpertsAction:(id)sender
{
    [model setMinNumDetsToAlertExperts:[sender intValue]];
}

- (IBAction) readSecondaryMapFileAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[[model segmentGroup:1] mapFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
    }
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [[model segmentGroup:1] readMap:[[openPanel URL] path]];
            [secondaryTableView reloadData];
        }
    }];

}

- (IBAction) saveSecondaryMapFileAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[[model segmentGroup:1] mapFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = [self defaultSecondaryMapFilePath];
        
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [[model segmentGroup:1] saveMapFileAs:[[savePanel URL]path]];
        }
    }];
}

#pragma mark ¥¥¥Table Data Source
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detectorSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detailsSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:subComponentViewSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:detectorMapViewSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 4){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:vetoMapViewSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 5){
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:calibrationViewSize];
        [[self window] setContentView:tabView];
    }
	NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.MajoranaController.selectedtab"];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    if( aTableView == secondaryTableView ||
       aTableView == secondaryValuesView){
        return [[model segmentGroup:1] numSegments];
    }
    else if((aTableView == module1InterlockTable) || (aTableView == module2InterlockTable) ){
        int module;
        if(aTableView == module1InterlockTable) module = 0;
        else                                    module = 1;
        ORMJDInterlocks* mjdInterLocks = [model mjdInterlocks:module];
        return [mjdInterLocks numStates];
    }
    
    else if(aTableView == stringMapTableView)       return kMaxNumStrings;
    else if(aTableView == specialChannelsTableView) return kNumSpecialChannels;
    
    
    else return [super numberOfRowsInTableView:aTableView]/2;
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) aRowIndex
{
    int rowIndex = (int)aRowIndex;
	if(aTableView == primaryTableView){
        if([[aTableColumn identifier] isEqualToString:@"kChanLo"]){
           return [[model segmentGroup:0] segment:rowIndex*2 objectForKey:@"kChannel"];
        }
        else if([[aTableColumn identifier] isEqualToString:@"kChanHi"]){
           return [[model segmentGroup:0] segment:rowIndex*2+1 objectForKey:@"kChannel"];
        }
 
        else if([[aTableColumn identifier] isEqualToString:@"kSegmentNumber"]){
            return [NSNumber numberWithInteger:rowIndex];
        }
        else {
            return [[model segmentGroup:0] segment:rowIndex*2 objectForKey:[aTableColumn identifier]];
        }
	}
    else if(aTableView == primaryValuesView){
        if([[aTableColumn identifier] isEqualToString:@"loThreshold"]){
            return [[model segmentGroup:0] segment:2*rowIndex objectForKey:@"threshold"];
        }
        else if([[aTableColumn identifier] isEqualToString:@"hiThreshold"]){
            return [[model segmentGroup:0] segment:2*rowIndex+1 objectForKey:@"threshold"];
        }
        else if([[aTableColumn identifier] isEqualToString:@"kDetectorNumber"]){
            return [model detectorLocation:2*rowIndex];
        }
        else {
            return [[model segmentGroup:0] segment:rowIndex*2 objectForKey:[aTableColumn identifier]];
        }
    }
    else if(aTableView == secondaryTableView || aTableView == secondaryValuesView){
        if([[aTableColumn identifier] isEqualToString:@"kPanelNumber"]){
            return [NSNumber numberWithInteger:rowIndex];
        }
        else if([[aTableColumn identifier] isEqualToString:@"threshold"]){
            return [[model segmentGroup:1] segment:rowIndex objectForKey:@"threshold"];
        }
		else return [[model segmentGroup:1] segment:rowIndex objectForKey:[aTableColumn identifier]];
	}
    
    else if(aTableView == stringMapTableView){
        if([[aTableColumn identifier] isEqualToString:@"kStringNum"]){
            return [NSNumber numberWithInt:rowIndex];
        }
		else return [model stringMap:rowIndex objectForKey:[aTableColumn identifier]];
	}
    
    else if(aTableView == specialChannelsTableView){
        if([[aTableColumn identifier] isEqualToString:@"kIndex"]){
            return [NSNumber numberWithInt:rowIndex];
        }
        else return [model specialMap:rowIndex objectForKey:[aTableColumn identifier]];
    }

    else if(aTableView == module1InterlockTable){
        ORMJDInterlocks* mjdInterLocks = [model mjdInterlocks:0];
        if([[aTableColumn identifier] isEqualToString:@"name"]) return [mjdInterLocks stateName:rowIndex];
        else                                                    return [mjdInterLocks stateStatus:rowIndex];
    }
    
    else if(aTableView == module2InterlockTable){
        ORMJDInterlocks* mjdInterLocks = [model mjdInterlocks:1];
        if([[aTableColumn identifier] isEqualToString:@"name"]) return [mjdInterLocks stateName:rowIndex];
        else                                                    return [mjdInterLocks stateStatus:rowIndex];
    }

	else return nil;
}


- (void) tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)aRowIndex
{
    if(!anObject)anObject= @"--";
    int rowIndex = (int)aRowIndex;
	ORDetectorSegment* aSegment;
	if(aTableView == primaryTableView){
        if([[aTableColumn identifier] isEqualToString:@"kChanLo"]){
            aSegment = [[model segmentGroup:0] segment:rowIndex*2];
            [aSegment setObject:anObject forKey:@"kChannel"];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex*2] forKey:@"kSegmentNumber"];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex] forKey:@"kDetector"];
            [aSegment setObject:[NSNumber numberWithInt:0] forKey:@"kGainType"];
        }
        else if([[aTableColumn identifier] isEqualToString:@"kChanHi"]){
            aSegment = [[model segmentGroup:0] segment:rowIndex*2+1];
            [aSegment setObject:anObject forKey:@"kChannel"];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex*2+1] forKey:@"kSegmentNumber"];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex] forKey:@"kDetector"];
            [aSegment setObject:[NSNumber numberWithInt:1] forKey:@"kGainType"];
        }
        else {
            aSegment = [[model segmentGroup:0] segment:rowIndex*2];
            [aSegment setObject:anObject forKey:[aTableColumn identifier]];
            if([[aTableColumn identifier] isEqualToString:@"kMaxVoltage"] ||
               [[aTableColumn identifier] isEqualToString:@"kPreAmpDigitizer"] ||
               [[aTableColumn identifier] isEqualToString:@"kPreAmpChan"]){
                [self forceHVUpdate:rowIndex*2];
            }
           [aSegment setObject:[NSNumber numberWithInt:rowIndex] forKey:@"kDetector"];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex*2] forKey:@"kSegmentNumber"];
          
            aSegment = [[model segmentGroup:0] segment:rowIndex*2+1];
            [aSegment setObject:anObject forKey:[aTableColumn identifier]];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex*2+1] forKey:@"kSegmentNumber"];
            [aSegment setObject:[NSNumber numberWithInt:rowIndex] forKey:@"kDetector"];
        }
        [[model segmentGroup:0] configurationChanged:nil];
        
	}
    
    else if(aTableView == stringMapTableView){
		[model stringMap:rowIndex setObject:anObject forKey:[aTableColumn identifier]];
	}
    else if(aTableView == specialChannelsTableView){
        [model specialMap:rowIndex setObject:anObject forKey:[aTableColumn identifier]];
    }
 
	else if(aTableView == primaryValuesView){
        if([[aTableColumn identifier] isEqualToString:@"loThreshold"]){
            aSegment = [[model segmentGroup:0] segment:rowIndex*2];
 			[aSegment setThreshold:anObject];
        }
        else if([[aTableColumn identifier] isEqualToString:@"hiThreshold"]){
            aSegment = [[model segmentGroup:0] segment:rowIndex*2+1];
 			[aSegment setThreshold:anObject];
        }

  	}
    
    else if(aTableView == secondaryTableView){
		aSegment = [[model segmentGroup:1] segment:rowIndex];
		[aSegment setObject:anObject forKey:[aTableColumn identifier]];
		[[model segmentGroup:1] configurationChanged:nil];
	}
    
	else if(aTableView == secondaryValuesView){
		aSegment = [[model segmentGroup:1] segment:rowIndex];
		if([[aTableColumn identifier] isEqualToString:@"threshold"]){
			[aSegment setThreshold:anObject];
		}
		else if([[aTableColumn identifier] isEqualToString:@"gain"]){
			[aSegment setGain:anObject];
		}
	}
}

- (void) forceHVUpdate:(int)segIndex
{
    ORDetectorSegment* aSegment = [[model segmentGroup:0] segment:segIndex];
    //find the HV card
    NSArray* hvCards = [[model document] collectObjectsOfClass:NSClassFromString(@"ORiSegHVCard")];
    for(ORiSegHVCard* aHVCard in hvCards){
        int crateNum  = [[[aSegment params] objectForKey:@"kHVCrate"] intValue];
		int cardNum   = [[[aSegment params] objectForKey:@"kHVCard"] intValue];
		int chanNum   = [[[aSegment params] objectForKey:@"kHVChan"] intValue];
        if([aHVCard crateNumber] != crateNum) continue;
        if([aHVCard slot]        != cardNum) continue;
        [aHVCard setMaxVoltage:chanNum withValue:[[[aSegment params] objectForKey:@"kMaxVoltage"] intValue] ];
        [aHVCard setChan:chanNum name:[[aSegment params] objectForKey:@"kDetectorName"]];
        
        id preAmpChan       = [[aSegment params] objectForKey:@"kPreAmpChan"];
        id preAmpDigitizer  = [[aSegment params] objectForKey:@"kPreAmpDigitizer"];
        //get here and it's a match
        if(preAmpChan && preAmpDigitizer){
            [aHVCard setCustomInfo:chanNum string:[NSString stringWithFormat:@"PreAmp: %d,%d",[preAmpDigitizer intValue],[preAmpChan intValue]]];
        }

        
        break;
    }
}
@end
