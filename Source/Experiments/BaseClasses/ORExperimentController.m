//
//  ORExperimentController.m
//  Orca
//
//  Created by Mark Howe on 12/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORExperimentController.h"
#import "ORExperimentModel.h"
#import "ORColorScale.h"
#import "ORCompositePlotView.h"
#import "ORTimeRate.h"
#import "BiStateView.h"
#import "ORReplayDataModel.h"
#import "ORDetectorView.h"
#import "ORDetectorSegment.h"
#import "ORAdcInfoProviding.h"
#import "ORSegmentGroup.h"
#import "ORRunModel.h"
#import "ORTimeLinePlot.h"
#import "OR1DHistoPlot.h"
#import "ORTimeAxis.h"

#import "ORDocumentController.h"
#import "ORStatusController.h"
#import "ORAlarmController.h"
#import "ORHelpCenter.h"
#import "ORHWWizardController.h"
#import "ORPreferencesController.h"
#import "ORCommandCenterController.h"

@interface ORExperimentController (private)
- (void) scaleValueHistogram;
- (void) populatePopups;
@end


@implementation ORExperimentController
- (void) dealloc
{
	[detectorView setDelegate:nil];	
	[super dealloc];
}

-(void) awakeFromNib
{
	[detectorView setDelegate:model];	
    
	NSString* tabPrefName = [NSString stringWithFormat:@"orca.%@.selectedtab",[self className]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: tabPrefName];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
    [primaryTableView setFocusRingType:NSFocusRingTypeNone];

	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[ratePlot addPlot: aPlot];
	[(ORTimeAxis*)[ratePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];

	OR1DHistoPlot* aPlot1 = [[OR1DHistoPlot alloc] initWithTag:10 andDataSource:self];
	[aPlot1 setUseConstantColor:YES];
	[valueHistogramsPlot addPlot: aPlot1];
	[aPlot1 release];
	
	[[ratePlot yAxis] setRngLimitsLow:0 withHigh:5000000 withMinRng:1];

    [[primaryColorScale colorAxis] setNeedsDisplay:YES];
    [selectionStringTextView setFont:[NSFont fontWithName:@"Monaco" size:9]];
	
	[[primaryColorScale colorAxis] setRngLimitsLow:0 withHigh:128000000 withMinRng:5];
 	[[primaryColorScale colorAxis] setRngDefaultsLow:0 withHigh:128000000];
	
	[self populateClassNamePopup:primaryAdcClassNamePopup];

	if([model replayMode]){
		[self updateForReplayMode];
	}

	[self findRunControl:nil];
	
    [super awakeFromNib];

}

- (NSView*) viewToDisplay
{
    return detectorView;
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[detectorView setDelegate:model];
}

#pragma mark •••Subclass responsibility
- (NSString*) defaultPrimaryMapFilePath{return @"";}
- (void) setDetectorTitle{;}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(populatePopups)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(populatePopups)
                         name : ORGroupObjectsRemoved
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ExperimentDisplayUpdatedNeeded
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(findRunControl:)
                         name : ORGroupObjectsAdded
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(findRunControl:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    							
    [notifyCenter addObserver : self
                     selector : @selector(newTotalRateAvailable:)
                         name : ExperimentCollectedRates
                       object : model];
                
	[notifyCenter addObserver : self
                     selector : @selector(mapFileRead:)
                         name : ORSegmentGroupMapReadNotification
                       object : nil];
        
    [notifyCenter addObserver : self
                     selector : @selector(mapLockChanged:)
                         name : [model experimentMapLock]
					object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(detectorLockChanged:)
                         name : [model experimentDetectorLock]
                       object : nil];
                           
    [notifyCenter addObserver : self
                     selector : @selector(detectorLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(mapLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
        
    [notifyCenter addObserver : self
                     selector : @selector(hardwareCheckChanged:)
                         name : ExperimentHardwareCheckChangedNotification
                       object : nil];
                       
    [notifyCenter addObserver : self
                     selector : @selector(cardCheckChanged:)
                         name : ExperimentCardCheckChangedNotification
                       object : nil];
            
    [notifyCenter addObserver : self
                     selector : @selector(captureDateChanged:)
                         name : ExperimentCaptureDateChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(replayStarted:)
                         name : ORReplayRunningNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(replayStopped:)
                         name : ORReplayStoppedNotification
                       object : nil];    
					   
    [notifyCenter addObserver : self
                     selector : @selector(primaryAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(selectionStringChanged:)
                         name : ExperimentModelSelectionStringChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(selectionChanged:)
                         name : ExperimentModelSelectionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(primaryMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(displayTypeChanged:)
                         name : ExperimentModelDisplayTypeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(specialUpdate:)
                         name : ORAdcInfoProvidingValueChanged
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(segmentGroupChanged:)
                         name : ORSegmentGroupConfiguationChanged
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(detailsLockChanged:)
                         name : [model experimentDetailsLock]
					object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(detailsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(histogramsUpdated:)
                         name : ExperimentDisplayHistogramsUpdated
						object: nil];

	[notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(updateRunInfo:)
						 name : ORRunStatusChangedNotification
					   object : nil];


    [notifyCenter addObserver : self
					 selector : @selector(timedRunChanged:)
						 name : ORRunTimedRunChangedNotification
					   object : nil];

   [notifyCenter addObserver : self
					 selector : @selector(repeatRunChanged:)
						 name : ORRunRepeatRunChangedNotification
					   object : nil];

   [notifyCenter addObserver : self
					 selector : @selector(runTimeLimitChanged:)
						 name : ORRunTimeLimitChangedNotification
					   object : nil];

   [notifyCenter addObserver : self
					 selector : @selector(runModeChanged:)
						 name : ORRunModeChangedNotification
					   object : nil];

    [notifyCenter addObserver: self
                     selector: @selector(startTimeChanged:)
                         name: ORRunStartTimeChangedNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(elapsedTimeChanged:)
                         name: ORRunElapsedTimesChangedNotification
                       object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(selectedRunTypeScriptChanged:)
                         name : ORRunModelSelectedRunTypeScriptChanged
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(showNamesChanged:)
                         name : ORExperimentModelShowNamesChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ignoreHWChecksChanged:)
                         name : ORExperimentModelIgnoreHWChecksChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(refreshSegmentTables:)
                         name : KSegmentChangedNotification
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(specialUpdate:)
                         name : KSegmentChangedNotification
						object: nil];
   
    [notifyCenter addObserver : self
                     selector : @selector(colorScaleTypeChanged:)
                         name : ExperimentModelColorScaleTypeChanged
						object: nil];    

    [notifyCenter addObserver : self
                     selector : @selector(customColor1Changed:)
                         name : ExperimentModelCustomColor1Changed
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(customColor2Changed:)
                         name : ExperimentModelCustomColor2Changed
						object: nil];

}

- (void) updateWindow
{
    [super updateWindow];
    [self miscAttributesChanged:nil];
    [self mapLockChanged:nil];
    [self detectorLockChanged:nil];
    [self hardwareCheckChanged:nil];
    [self cardCheckChanged:nil];
    [self captureDateChanged:nil];
	[self newTotalRateAvailable:nil];
	[self selectionStringChanged:nil];
	[self primaryMapFileChanged:nil];
	[self displayTypeChanged:nil];	
	[self primaryAdcClassNameChanged:nil];
	[self selectionChanged:nil];
	[self customColor1Changed:nil];
	[self customColor2Changed:nil];

	[self timedRunChanged:nil];
	[self runModeChanged:nil];
	[self runTimeLimitChanged:nil];
	[self repeatRunChanged:nil];
    [self startTimeChanged:nil];
    [self elapsedTimeChanged:nil];
	[self populatePopups];
    [self colorScaleTypeChanged:nil];
	
		//details
	[self detailsLockChanged:nil];
	[self histogramsUpdated:nil];
	[self setValueHistogramTitle];
	[self scaleValueHistogram];
	[self showNamesChanged:nil];
	[self ignoreHWChecksChanged:nil];
	
    [valueHistogramsPlot setNeedsDisplay:YES];
    [ratePlot setNeedsDisplay:YES];
	[primaryValuesView reloadData];
}

- (void) findRunControl:(NSNotification*)aNote
{
	runControl = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORRunModel,1"];
	if(!runControl){
		runControl = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORRemoteRunModel,1"];	
	}
	[self updateRunInfo:nil];
	[startRunButton setEnabled:runControl!=nil];
	[timedRunCB setEnabled:runControl!=nil];
	[runModeMatrix setEnabled:runControl!=nil];
}

- (void) timedRunChanged:(NSNotification*)aNote
{
	[timedRunCB setIntValue:[runControl timedRun]];
	[repeatRunCB setEnabled:[runControl timedRun]];
	[timeLimitField setEnabled:[runControl timedRun]];
}

- (void) customColor1Changed:(NSNotification*)aNote
{
    [custumColorWell1 setColor: [model customColor1]];
    [primaryColorScale setStartColor: [model customColor1]];
    [[self viewToDisplay] setNeedsDisplay:YES];
}

- (void) customColor2Changed:(NSNotification*)aNote
{
    [custumColorWell2 setColor: [model customColor2]];
    [primaryColorScale setEndColor:   [model customColor2]];
    [[self viewToDisplay] setNeedsDisplay:YES];
}


- (void) colorScaleTypeChanged:(NSNotification*)aNote
{
    int colorScaleType = [model colorScaleType];
	[colorScaleMatrix selectCellWithTag: colorScaleType];
    [[self viewToDisplay] setNeedsDisplay:YES];
    switch(colorScaleType){
        case 0: /*rainbow -- nothing to do*/ break;

        case 1:
            [primaryColorScale setStartColor:[NSColor colorWithCalibratedRed:.5 green:.5 blue:1.0 alpha:1]];
            [primaryColorScale setEndColor:  [NSColor redColor]];
            break;

        case 2:
            [primaryColorScale setStartColor:[NSColor yellowColor]];
            [primaryColorScale setEndColor:  [NSColor redColor]];
        break;
            
        case 3:
            [primaryColorScale setStartColor:[NSColor orangeColor]];
            [primaryColorScale setEndColor:  [NSColor blueColor]];
        break;
            
        case 4:
            [primaryColorScale setStartColor: [model customColor1]];
            [primaryColorScale setEndColor:   [model customColor2]];
        break;

    }
    
    [custumColorWell1 setEnabled:[model colorScaleType]==4];
    [custumColorWell2 setEnabled:[model colorScaleType]==4];

    [self detectorLockChanged:nil]; //update the button status
    [primaryColorScale setUseRainBow:[model colorScaleType]==0];
}

- (void) runModeChanged:(NSNotification*)aNote
{
	[runModeMatrix selectCellWithTag: [[ORGlobal sharedGlobal] runMode]];
}

- (void) runTimeLimitChanged:(NSNotification*)aNote
{
	[timeLimitField setIntValue:[runControl timeLimit]];		
}

- (void) repeatRunChanged:(NSNotification*)aNote
{
	[repeatRunCB setIntValue:[runControl repeatRun]];
}

- (void) selectedRunTypeScriptChanged:(NSNotification*)aNote
{
	[runTypeScriptPU selectItemAtIndex: [runControl selectedRunTypeScript]];
}

- (void) startTimeChanged:(NSNotification*)aNotification
{

    if(runControl) [timeStartedField setObjectValue:[[runControl startTime] descriptionFromTemplate:@"MM/dd/yy HH:mm:ss"]];
    else [timeStartedField setStringValue:@"---"];

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


- (void) updateRunInfo:(NSNotification*)aNote
{
	if(runControl)	{
		[runStatusField setStringValue:[runControl shortStatus]];
		[runNumberField setIntegerValue:(int)[runControl runNumber]];
		
		if([runControl isRunning]){
			[runBar setIndeterminate:!([runControl timedRun] && ![runControl remoteControl])];
			[runBar setDoubleValue:0];
			[runBar startAnimation:self];

		}
		else {
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
	[stopRunButton setEnabled:[runControl isRunning]];
	[timedRunCB setEnabled:![runControl isRunning]];
	[timeLimitField setEnabled:![runControl isRunning]];
	[runModeMatrix setEnabled:![runControl isRunning]];
}


- (void) updateForReplayMode
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateForReplayMode) object:nil];
	if([model replayMode]){
		//[[model detector] loadTotalCounts];
		[[self viewToDisplay] setNeedsDisplay:YES];
		[self performSelector:@selector(updateForReplayMode) withObject:nil afterDelay:.5];
	}
}


#pragma mark •••Actions

- (IBAction) autoscaleMainColorScale:(id)sender
{
    int n = [[model segmentGroup:0] numSegments];
    int i;
    float maxValue = -99999;
    for(i=0;i<n;i++){
        float aValue = maxValue;
        if([[model segmentGroup:0] online:i]){
            switch([model displayType]){
                case kDisplayThresholds:	aValue = [[model segmentGroup:0] getThreshold:i];     break;
                case kDisplayGains:			aValue = [[model segmentGroup:0] getGain:i];          break;
                case kDisplayRates:			aValue = [[model segmentGroup:0] getRate:i];		  break;
                case kDisplayTotalCounts:	aValue = [[model segmentGroup:0] getTotalCounts:i];   break;
                default:	break;
            }
        }
        else aValue = 0;
        if(aValue>maxValue)maxValue = aValue;
    }
    if(maxValue != -99999){
        maxValue += (maxValue*.20);
        [[primaryColorScale colorAxis] setRngLow:0 withHigh:maxValue];
    }
}
- (IBAction) colorScaleTypeAction:(id)sender
{
    [model setColorScaleType:(int)[[sender selectedCell]tag]];
}

- (IBAction) customColor1Action:(id)sender
{
    [model setCustomColor1:[sender color]];
}

- (IBAction) customColor2Action:(id)sender
{
    [model setCustomColor2:[sender color]];
}

- (IBAction) ignoreHWChecksAction:(id)sender
{
	[model setIgnoreHWChecks:[sender intValue]];	
}

- (IBAction) clearAction:(id)sender
{
	[model clearTotalCounts];
}

- (IBAction) showNamesAction:(id)sender
{
	[self endEditing];
	[model setShowNames:[sender intValue]];	
}

- (IBAction) startRunAction:(id)sender
{
	[self endEditing];
	if([runControl isRunning])[runControl restartRun];
	else [runControl startRun];
}

- (IBAction) stopRunAction:(id)sender
{
	[self endEditing];
	[runControl haltRun];
}

- (IBAction) selectedRunTypeScriptPUAction:(id)sender
{
	[runControl setSelectedRunTypeScript:[sender indexOfSelectedItem]];
}

- (IBAction) timeLimitTextAction:(id)sender
{
	[runControl setTimeLimit:[sender intValue]];
}

- (IBAction) timedRunCBAction:(id)sender
{
	[self endEditing];
	[runControl setTimedRun:[sender intValue]];
}

- (IBAction) repeatRunCBAction:(id)sender
{
	[self endEditing];
	[runControl setRepeatRun:[sender intValue]];
}

- (IBAction) runModeAction:(id)sender
{
	[self endEditing];
    int tag = (int)[[runModeMatrix selectedCell] tag];
    if(tag != [[ORGlobal sharedGlobal] runMode]){
        [[ORGlobal sharedGlobal] setRunMode:tag];
    }
}

- (IBAction) displayTypeAction:(id)sender
{
	[self endEditing];
	int type = (int)[[sender selectedCell]tag];
	[model setDisplayType:type];	
	[self setValueHistogramTitle];
	[self scaleValueHistogram];
}

- (IBAction) primaryAdcClassNameAction:(id)sender
{
	[[model segmentGroup:0] setAdcClassName:[sender titleOfSelectedItem]];	
}

- (IBAction) captureStateAction:(id)sender
{
    [model captureState];
	[[self viewToDisplay] setNeedsDisplay:YES];
}

- (IBAction) reportConfigAction:(id)sender
{
    [model printProblemSummary];
}

- (IBAction) readPrimaryMapFileAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	NSString* fullPath = [[[model segmentGroup:0] mapFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
    }
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
			NSString* thePath = [model validateHWMapPath:[[openPanel URL] path]];
            [[model segmentGroup:0] readMap:thePath];
			[model readAuxFiles: thePath];
			[model handleOldPrimaryMapFormats: thePath]; //backward compatibility (temp)
            [primaryTableView reloadData];
        }
    }];
}


- (IBAction) savePrimaryMapFileAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[[model segmentGroup:0] mapFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = [self defaultPrimaryMapFilePath];
        
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:@"HW Map File:"];
	[savePanel setNameFieldStringValue:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [[model segmentGroup:0] saveMapFileAs:[[savePanel URL]path]];
			[model saveAuxFiles: [[savePanel URL]path]];
        }
    }];

}

- (IBAction) mapLockAction:(id)sender
{
    [gSecurity tryToSetLock:[model experimentMapLock] to:[sender intValue] forWindow:[self window]];
}

- (IBAction) detectorLockAction:(id)sender
{
    [gSecurity tryToSetLock:[model experimentDetectorLock] to:[sender intValue] forWindow:[self window]];
}

#pragma mark •••Toolbar
- (IBAction) openHelp:(NSToolbarItem*)item 
{
	[[(ORAppDelegate*)[NSApp delegate] helpCenter] showHelpCenter:nil];
}

- (IBAction) statusLog:(NSToolbarItem*)item 
{
    [[ORStatusController sharedStatusController] showWindow:self];
}

- (IBAction) alarmMaster:(NSToolbarItem*)item 
{
    [[ORAlarmController sharedAlarmController] showWindow:self];
}

- (IBAction) openPreferences:(NSToolbarItem*)item 
{
    [[ORPreferencesController sharedPreferencesController] showWindow:self];
}

- (IBAction) openHWWizard:(NSToolbarItem*)item 
{
    [[ORHWWizardController sharedHWWizardController] showWindow:self];
}

- (IBAction) openCommandCenter:(NSToolbarItem*)item 
{
    [[ORCommandCenterController sharedCommandCenterController] showWindow:self];
}

- (IBAction) openTaskMaster:(NSToolbarItem*)item 
{
    [(ORAppDelegate*)[NSApp delegate] showTaskMaster:self];
}


#pragma mark •••Details Actions
- (IBAction) initAction:(id)sender;
{
	[model initHardware];
	[self  specialUpdate:nil];
}

- (IBAction) detailsLockAction:(id)sender
{
    [gSecurity tryToSetLock:[model experimentDetailsLock] to:[sender intValue] forWindow:[self window]];
}

#pragma mark •••Interface Management

- (void) ignoreHWChecksChanged:(NSNotification*)aNote
{
	[ignoreHWChecksCB setIntValue: [model ignoreHWChecks]];
}

- (void) showNamesChanged:(NSNotification*)aNote
{
	[showNamesCB setIntValue: [model showNames]];
	[[self viewToDisplay] setNeedsDisplay:YES];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [ratePlot xAxis]){
		ORAxis* xAxis = [ratePlot xAxis];
		NSMutableDictionary* attrib = [xAxis attributes];
		[model setMiscAttributes:attrib forKey:@"XAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [ratePlot yAxis]){
		ORAxis* yAxis = [ratePlot yAxis];
		NSMutableDictionary* attrib = [yAxis attributes];
		[model setMiscAttributes:attrib forKey:@"YAttributes"];
	};
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes"];
		if(attrib){
			ORAxis* xAxis = [ratePlot xAxis];
			[xAxis setAttributes:attrib];
			[ratePlot setNeedsDisplay:YES];
			[[ratePlot xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes"];
		if(attrib){
			ORAxis* yAxis = [ratePlot yAxis];
			[yAxis setAttributes:attrib];
			[ratePlot setNeedsDisplay:YES];
			[[ratePlot yAxis] setNeedsDisplay:YES];
			[rateLogCB setState:[[ratePlot yAxis] isLog]];
		}
	}
}

- (void) refreshSegmentTables:(NSNotification*)aNote
{
	[primaryTableView reloadData];
    [[self viewToDisplay] setNeedsDisplay:YES];
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[model compileHistograms];
	[[self viewToDisplay] setNeedsDisplay:YES];
	[primaryValuesView reloadData];
	[primaryTableView reloadData];
	[valueHistogramsPlot setNeedsDisplay:YES];
}

- (void) segmentGroupChanged:(NSNotification*)aNote
{
}

- (void) selectionChanged:(NSNotification*)aNote
{
}

- (void) displayTypeChanged:(NSNotification*)aNote
{
	[displayTypePU selectItemWithTag: [model displayType]];
	[displayTypePU1 selectItemWithTag: [model displayType]];
	[model compileHistograms];
	[[self viewToDisplay] setNeedsDisplay:YES];
	[valueHistogramsPlot setNeedsDisplay:YES];
	[self setDetectorTitle];
	[self detectorLockChanged:nil];
}

- (void) primaryMapFileChanged:(NSNotification*)aNote
{
	NSString* s = [[[model segmentGroup:0] mapFile] stringByAbbreviatingWithTildeInPath];
	if(s)[primaryMapFileTextField setStringValue: s];
	else [primaryMapFileTextField setStringValue: @"--"];
}

- (void) selectionStringChanged:(NSNotification*)aNote
{
	[selectionStringTextView setString: [model selectionString]];
}

- (void) primaryAdcClassNameChanged:(NSNotification*)aNote
{
	[primaryAdcClassNamePopup selectItemWithTitle: [[model segmentGroup:0] adcClassName]];
}

- (void) mapFileRead:(NSNotification*)aNote
{
    if(aNote == nil || [aNote object] == model){
        [primaryTableView reloadData];
    }
}

- (void) newTotalRateAvailable:(NSNotification*)aNotification
{
	[primaryRateField setFloatValue:[[model segmentGroup:0] rate]];
	[ratePlot setNeedsDisplay:YES];
	[[self viewToDisplay] setNeedsDisplay:YES];
	[valueHistogramsPlot setNeedsDisplay:YES];
}


- (void) objectsChanged:(NSNotification*)aNote
{
	[[self viewToDisplay] setNeedsDisplay:YES];
}

- (void) mapLockChanged:(NSNotification*)aNotification
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentMapLock]];
    BOOL locked = [gSecurity isLocked:[model experimentMapLock]];
    [mapLockButton setState: locked];
    
    if(locked)[primaryTableView deselectAll:self];
    [readPrimaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
    [savePrimaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
	[primaryAdcClassNamePopup setEnabled:!lockedOrRunningMaintenance]; 
}

- (void) detectorLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:[model experimentDetectorLock]];
    [detectorLockButton setState: locked];
    [captureStateButton setEnabled: !locked];
    [clearButton setEnabled: [model displayType] == kDisplayTotalCounts];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    //add setLock calls here as new lock buttons
    //are added to this dialog.
    [gSecurity setLock:[model experimentMapLock] to:secure];
    [gSecurity setLock:[model experimentDetectorLock] to:secure];
    [gSecurity setLock:[model experimentDetailsLock] to:secure];
    [mapLockButton setEnabled: secure];
    [detectorLockButton setEnabled: secure];
    [detailsLockButton setEnabled: secure];
    
}

- (void) hardwareCheckChanged:(NSNotification*)aNotification
{
    [hardwareCheckView setState:[model hardwareCheck]]; 
}

- (void) cardCheckChanged:(NSNotification*)aNotification
{
    [cardCheckView setState:[model cardCheck]]; 
}

- (void) captureDateChanged:(NSNotification*)aNotification
{
    [captureDateField setObjectValue:[model captureDate]]; 
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	if(tableView == primaryTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == primaryValuesView){
		return ![gSecurity isLocked:[model experimentDetailsLock]];
	}
	else return YES;
}

- (void) replayStarted:(NSNotification*)aNote
{
	//[[model detector] clearAdcCounts]; 
	[model setReplayMode:YES];
	[self updateForReplayMode];
}

- (void) replayStopped:(NSNotification*)aNote
{
	[model setReplayMode:NO];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateForReplayMode) object:nil];
}



#pragma mark •••Details Interface Management
- (void) histogramsUpdated:(NSNotification*)aNote
{
	[self scaleValueHistogram];
	[valueHistogramsPlot setNeedsDisplay:YES];
}

- (void) detailsLockChanged:(NSNotification*)aNotification
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetailsLock]];
    BOOL locked = [gSecurity isLocked:[model experimentDetailsLock]];

	[detailsLockButton setState: locked];
    [initButton setEnabled: !lockedOrRunningMaintenance];

	if(locked){
		[primaryValuesView deselectAll:self];
	}
}

- (void) setValueHistogramTitle
{	
	switch([model displayType]){
		case kDisplayRates:			
			[histogramTitle setStringValue:@"Channel Rates"];
			[valueHistogramsPlot setXLabel:@"Channel"];	
			[valueHistogramsPlot setYLabel:@"Counts/Sec"];	
		break;
		case kDisplayTotalCounts:			
			[histogramTitle setStringValue:@"Total Counts Distribution"];		
			[valueHistogramsPlot setXLabel:@"Channel"];	
			[valueHistogramsPlot setYLabel:@"Total Counts"];	
		break;
		case kDisplayThresholds:	
			[histogramTitle setStringValue:@"Threshold Distribution"];	
			[valueHistogramsPlot setXLabel:@"Raw Threshold Value"];	
			[valueHistogramsPlot setYLabel:@"# Channels"];	
		break;
		case kDisplayGains:			
			[histogramTitle setStringValue:@"Gain Distribution"];		
			[valueHistogramsPlot setXLabel:@"Gain Value"];	
			[valueHistogramsPlot setYLabel:@"# Channels"];
		break;
		default: break;
	}
}

#pragma mark •••Data Source For Plots
- (int) numberPointsInPlot:(id)aPlotter
{
	int tag = (int)[aPlotter tag];
	if(tag < 10){ //rate plots
		int set = tag;
		return (int)[[[model segmentGroup:set]  totalRate] count];
	}
	else if(tag >= 10){ //value plots
		int set = tag-10;
		switch([model displayType]){
			case kDisplayRates:			return [[model segmentGroup:set] numSegments];
			case kDisplayTotalCounts:	return [[model segmentGroup:set] numSegments];
			case kDisplayThresholds:	return 32*1024;
			case kDisplayGains:			return 1024;
			default:					return 0;
		}
	}
	else return 0;
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	double aValue = 0;
	int tag = (int)[aPlotter tag];
	if(tag < 10){ //rate plots
		int set = tag;
		int count = (int)[[[model segmentGroup:set] totalRate] count];
		int index = count-i-1;
		if(count==0) aValue = 0;
		else		 aValue = [[[model segmentGroup:set] totalRate] valueAtIndex:index];
		*xValue = [[[model segmentGroup:set] totalRate] timeSampledAtIndex:index];
		*yValue = aValue;
	}
	else if(tag >= 10){ //value plots
		int set = tag-10;
		switch([model displayType]){
			case kDisplayThresholds:	aValue = [[model segmentGroup:set] thresholdHistogram:i];	break;
			case kDisplayGains:			aValue = [[model segmentGroup:set] gainHistogram:i];		break;
			case kDisplayRates:			aValue = [[model segmentGroup:set] getRate:i];				break;
			case kDisplayTotalCounts:	aValue = [[model segmentGroup:set] totalCountsHistogram:i];break;
			default:	break;
		}
		*xValue = (double)i;
		*yValue = aValue;
	}
}

#pragma mark •••Data Source For Tables
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
	if(aTableView == primaryTableView || aTableView == primaryValuesView){
		return [[model segmentGroup:0] segment:(int)rowIndex objectForKey:[aTableColumn identifier]];
	}
	else return nil;
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if(aTableView == primaryTableView || aTableView == primaryValuesView){
		return [[model segmentGroup:0] numSegments];
	}
	else return 0;
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	ORDetectorSegment* aSegment;
	if(aTableView == primaryTableView){
		aSegment = [[model segmentGroup:0] segment:(int)rowIndex];
		[aSegment setObject:anObject forKey:[aTableColumn identifier]];
		[[model segmentGroup:0] configurationChanged:nil];
	}
	else if(aTableView == primaryValuesView){
		aSegment = [[model segmentGroup:0] segment:(int)rowIndex];
		if([[aTableColumn identifier] isEqualToString:@"threshold"]){
			[aSegment setThreshold:anObject];
		}
		else if([[aTableColumn identifier] isEqualToString:@"gain"]){
			[aSegment setGain:anObject];
		}
	}
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    NSInteger index = [tabView indexOfTabViewItem:item];
	NSString* tabPrefName = [NSString stringWithFormat:@"orca.%@.selectedtab",[self className]];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:tabPrefName];
}

- (void) populateClassNamePopup:(NSPopUpButton*)aPopup
{
	[aPopup removeAllItems];
	[aPopup addItemWithTitle:@"--"];
	NSArray* allCardsObservingProtocol = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsConformingTo:@protocol(ORAdcInfoProviding)];
	NSEnumerator* e = [allCardsObservingProtocol objectEnumerator];
	id aCard;
	while(aCard = [e nextObject]){
		NSString* className = NSStringFromClass([aCard class]);
		if(![aPopup itemWithTitle:className]){
			[aPopup addItemWithTitle:className];
		}
	}
}

@end

@implementation ORExperimentController (private)
- (void) populatePopups
{
	[[model undoManager] disableUndoRegistration];
	
	[runTypeScriptPU removeAllItems];
    [runTypeScriptPU addItemWithTitle:@"Standard (Manual)"];
    	
    NSArray* runTypeScripts = [runControl collectObjectsOfClass:NSClassFromString(@"ORRunScriptModel")];
    NSArray* runTypeSortedBySlot = [runTypeScripts sortedArrayUsingSelector:@selector(compare:)];
    
    int index = 1;
    for(ORRunScriptModel* obj in runTypeSortedBySlot){
		[runTypeScriptPU addItemWithTitle:[obj identifier]];
        [obj setSelectionIndex:index];
        index++;
    }
        
	[[model undoManager] enableUndoRegistration];
}

- (void) scaleValueHistogram
{
    
    [[valueHistogramsPlot xAxis] setRngLow:0 withHigh:64];
    switch([model displayType]){
        case kDisplayRates:        [[valueHistogramsPlot xAxis] setRngLow:0 withHigh:64]; break;
        case kDisplayThresholds:
        case kDisplayGains:
        case kDisplayTotalCounts:
            [valueHistogramsPlot autoScaleX:self];
            [valueHistogramsPlot autoScaleY:self];
            break;
        default: break;
    }
}
@end
