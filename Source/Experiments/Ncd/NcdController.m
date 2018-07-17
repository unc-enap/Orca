//
//  NcdController.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "NcdController.h"
#import "NcdModel.h"
#import "ORVmeCrateModel.h"
#import "NcdDetector.h"
#import "NcdTube.h"
#import "ORShaperModel.h"
#import "ORColorScale.h"
#import "ORTimeLinePlot.h"
#import "ORTimeAxis.h"
#import "ORPlotView.h"
#import "ORTimeRate.h"
#import "ORValidatePassword.h"
#import "BiStateView.h"
#import "SourceMask.h"


@implementation NcdController

#pragma mark ¥¥¥Initialization


-(id)init
{
    self = [super initWithWindowNibName:@"Ncd"];
    return self;
}

- (void) dealloc
{
    [ascendingSortingImage release];
    [descendingSortingImage release];
    
    [super dealloc];
}

-(void) awakeFromNib
{
    ascendingSortingImage = [[NSImage imageNamed:@"NSAscendingSortIndicator"] retain];
    descendingSortingImage = [[NSImage imageNamed:@"NSDescendingSortIndicator"] retain];
    
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: @"orca.NcdController.selectedtab"];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
    
    [[[hwTableView tableColumnWithIdentifier:@"kCableCheck"]dataCell] setControlSize:NSControlSizeSmall];
    
    if([model xAttributes])[[ratePlot xScale] setAttributes:[[[model xAttributes] mutableCopy] autorelease]];
    if([model yAttributes])[[ratePlot yScale] setAttributes:[[[model yAttributes] mutableCopy] autorelease]];
    
    [super awakeFromNib];
    
 	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[ratePlot addPlot: aPlot];
	[(ORTimeAxis*)[ratePlot xScale] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	
	[ratePlot orderChanged];
	
    [tubeInfoView setFont:[NSFont fontWithName:@"Monaco" size:9]];
}

#pragma mark ¥¥¥Accessors

- (NSArray *)sourceMasks
{
    return [SourceMask allSourceMasks];
}

- (NSView*) detectorView
{
    return detectorView;
}

- (ORPlotView*) ratePlot
{
    return ratePlot;
}
- (NSMutableArray *)altMuxThresholds
{
    return [model altMuxThresholds];
}

- (void)setAltMuxThresholds:(NSMutableArray *)anArray
{
    [model setAltMuxThresholds:anArray];
}

- (unsigned int)countOfAltMuxThresholds 
{
    return (unsigned int)[[model altMuxThresholds] count];
}


- (id)objectInAltMuxThresholdsAtIndex:(unsigned int)index 
{
    return [[model altMuxThresholds] objectAtIndex:index];
}

- (void)removeObjectFromAltMuxThresholdsAtIndex:(unsigned int)index
{
    [[model altMuxThresholds] removeObjectAtIndex:index];
}

- (void)insertObject:(id)anObject inAltMuxThresholdsAtIndex:(unsigned int)index 
{
    [[model altMuxThresholds] insertObject:anObject atIndex:index];
}

- (void)replaceObjectInAltMuxThresholdsAtIndex:(unsigned int)index withObject:(id)anObject;
{
    [[model altMuxThresholds] replaceObjectAtIndex:index withObject:anObject];
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORVmeCardSlotChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORShaperRateGroupChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(colorAttributesChanged:)
                         name : ORNcdRateColorBarChangedNotification
                       object : model];
    
    //a fake action for the scale objects
    [notifyCenter addObserver : self
                     selector : @selector(scaleAction:)
                         name : ORAxisRangeChangedNotification
                       object : nil];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(totalRateChanged:)
                         name : ORRateAverageChangedNotification
                       object : nil];
    
    
    
    [notifyCenter addObserver : self
                     selector : @selector(tubeRateChanged:)
                         name : ORNcdTubeRateChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(displayOptionsChanged:)
                         name : ORNcdDisplayOptionMaskChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(mapFileNameChanged:)
                         name : ORNcdTubeMapNameChangedNotification
                       object : [NcdDetector sharedInstance]];
    
    [notifyCenter addObserver : self
                     selector : @selector(mapFileRead:)
                         name : ORNcdTubeMapReadNotification
                       object : [NcdDetector sharedInstance]];
    
    [notifyCenter addObserver : self
                     selector : @selector(tubeParamChanged:)
                         name : ORNcdTubeParamChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(tubeSelectionChanged:)
                         name : ORNcdTubeSelectionChangedNotification
                       object : nil];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(tubeParamChanged:)
                         name : ORNcdTubeAddedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(tubeParamChanged:)
                         name : ORNcdTubeRemovedNotification
                       object : nil];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(selectionChanged:)
                         name : NSTableViewSelectionIsChangingNotification
                       object : hwTableView];
    
    [notifyCenter addObserver : self
                     selector : @selector(specialLockChanged:)
                         name : ORNcdSpecialLock
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(tubeMapLockChanged:)
                         name : ORNcdTubeMapLock
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(nominalSettingsLockChanged:)
                         name : ORNcdNominalSettingsLock
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(nominalSettingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];


    [notifyCenter addObserver : self
                     selector : @selector(detectorLockChanged:)
                         name : ORNcdDetectorLock
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(specialLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
                       
    [notifyCenter addObserver : self
                     selector : @selector(detectorLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(tubeMapLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(hardwareCheckChanged:)
                         name : ORNcdHardwareCheckChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(shaperCheckChanged:)
                         name : ORNcdShaperCheckChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(muxCheckChanged:)
                         name : ORNcdMuxCheckChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(triggerCheckChanged:)
                         name : ORNcdTriggerCheckChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(captureDateChanged:)
                         name : ORNcdCaptureDateChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(allDisabledChanged:)
                         name : ORNcdRateAllDisableChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(muxEfficiencyChanged:)
                         name : NcdModelCurrentMuxEfficiencyChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runningAtReducedMuxEfficiencyChanged:)
                         name : NcdModelRunningAtReducedEfficiencyChanged
                       object : nil];
    

    [notifyCenter addObserver : self
                     selector : @selector(nominalSettingsFileChanged:)
                         name : NcdModelNominalSettingsFileChanged
                       object : nil];

}



#pragma mark ¥¥¥Actions
- (IBAction) allDisabledAction:(id)sender
{
    [model setAllDisabled:[(NSButton*)sender state]];
}

- (IBAction) captureStateAction:(id)sender
{
    [model captureState];
}

- (IBAction) reportConfigAction:(id)sender
{
    [model printProblemSummary];
}


- (IBAction) standAloneAction:(id)sender
{
    [model standAloneMode:YES];
}

- (IBAction) showCrate:(id)sender
{
    NSArray* anArray = [self collectObjectsOfClass:NSClassFromString(@"ORVmeCrateModel")];
    if([anArray count])[[anArray objectAtIndex:0] showMainInterface];
}

- (IBAction) showMac:(id)sender
{
    NSArray* anArray = [self collectObjectsOfClass:NSClassFromString(@"ORMacModel")];
    if([anArray count])[[anArray objectAtIndex:0] showMainInterface];
}

- (IBAction) showPulser:(id)sender
{
    NSArray* anArray = [self collectObjectsOfClass:NSClassFromString(@"ORHPPulserModel")];
    if([anArray count])[[anArray objectAtIndex:0] showMainInterface];
}

- (IBAction) showEnetGpib:(id)sender
{
    NSArray* anArray = [self collectObjectsOfClass:NSClassFromString(@"ORGpibEnetModel")];
    if([anArray count])[[anArray objectAtIndex:0] showMainInterface];
}

- (IBAction) showHVMaster:(id)sender
{
    NSArray* anArray = [self collectObjectsOfClass:NSClassFromString(@"ORHVRampModel")];
    if([anArray count])[[anArray objectAtIndex:0] showMainInterface];
}

- (IBAction) showScopeA:(id)sender
{
    NSArray* anArray = [self collectObjectsOfClass:NSClassFromString(@"ORTek754DModel")];
    if([anArray count]){
        [[anArray objectAtIndex:0] showMainInterface];
    }
}

- (IBAction) showScopeB:(id)sender
{
    NSArray* anArray = [self collectObjectsOfClass:NSClassFromString(@"ORTek754DModel")];
    if([anArray count] == 2){
        [[anArray objectAtIndex:1] showMainInterface];
    }
}

- (IBAction) showMux:(id)sender
{
    NSArray* anArray = [self collectObjectsOfClass:NSClassFromString(@"NcdMuxBoxModel")];
    NSEnumerator* e = [anArray objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        if([obj tag] == [sender tag]){
            [obj showMainInterface];
        }
    }
}

- (IBAction) colorBarUsesLogAction:(id)sender
{
    NSMutableDictionary* attributes = [[detectorColorBar colorAxis]attributes];
    [attributes setObject:[NSNumber numberWithBool:[(NSButton*)sender state]] forKey:ORAxisUseLog];
    [model setColorBarAttributes:attributes];
}

- (IBAction) setDisplayOptionAction:(id)sender
{
    [model setDisplayOption:[[sender selectedCell]tag] state:[(NSButton*)[sender selectedCell]state]];
}

- (IBAction) readMapFileAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
    if([[NcdDetector sharedInstance] mapFileName]){
        startingDir = [[[NcdDetector sharedInstance] mapFileName]stringByDeletingLastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
    }
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            [[NcdDetector sharedInstance] setMapFileName:[[openPanel URL] path]];
            [[NcdDetector sharedInstance] readMap];
        }
    }];
}


- (IBAction) saveMapFileAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    //[savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
    if([[NcdDetector sharedInstance] mapFileName]){
        startingDir = [[[NcdDetector sharedInstance] mapFileName]stringByDeletingLastPathComponent];
        defaultFile = [[[NcdDetector sharedInstance] mapFileName]lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"TubeMapData";
        
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldStringValue:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            [[NcdDetector sharedInstance] saveMapFileAs:[[savePanel URL]path]];
        }
    }];

}

- (IBAction) delete:(id)sender
{
    [[NcdDetector sharedInstance] removeTubeAtIndex:[hwTableView selectedRow]];
}

- (IBAction) cut:(id)sender
{
    [[NcdDetector sharedInstance] removeTubeAtIndex:[hwTableView selectedRow]];
    [hwTableView reloadData];
}

- (IBAction) addTubeAction:(id)sender
{
    [[NcdDetector sharedInstance] addTube:nil atIndex:0];
}

- (IBAction) specialLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORNcdSpecialLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) tubeMapLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORNcdTubeMapLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) detectorLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORNcdDetectorLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) nominalSettingsLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORNcdNominalSettingsLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) muxEfficiencyAction:(id)sender
{
	[model setCurrentMuxEfficiency:[[sender selectedCell] tag]];
}

- (IBAction) setMuxEfficiencyAction:(id)sender
{
	NSString* s = [NSString stringWithFormat:@"Reducing mux efficiency to: %.0f%%",[model currentMuxEfficiency] ];
	BOOL cancel = ORRunAlertPanel(s,@"Is this really what you want?\n",@"Cancel",@"Yes, Do it",nil);
	if(!cancel){
		[model modifiyMuxEfficiency];
	}	
}

- (IBAction) restoreEfficiencyAction:(id)sender
{
	BOOL cancel = ORRunAlertPanel(@"Restoring mux thresholds to previous values",@"Is this really what you want?\n",@"Cancel",@"Yes, Do it",nil);
	if(!cancel){
		[model restoreMuxEfficiency];
	}	
}

- (IBAction) captureNominalSettingsAction:(id)sender
{
	BOOL ok= YES;
	if([model nominalSettingsFile]){
		BOOL cancel = ORRunAlertPanel(@"Capturing mux and threshold settings to a NEW nominal settings file!",@"Is this really what you want?\n",@"Cancel",@"Yes, Do it",nil);
		if(!cancel){
			ok = YES;
		}
		else ok = NO;
	}
	if(ok){
		NSString* startingDir = NSHomeDirectory(); //default to home
		NSString* defaultFileName = @"NominalMuxShaperSettings";
		if([model nominalSettingsFile]){
			startingDir = [[model nominalSettingsFile] stringByDeletingLastPathComponent];
			if([startingDir length] == 0)startingDir = NSHomeDirectory();
			defaultFileName = [[model nominalSettingsFile] lastPathComponent];
		}
        NSSavePanel* savePanel = [NSSavePanel savePanel];
        [savePanel setNameFieldStringValue:defaultFileName];
        [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
        [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                [model saveNominalSettingsTo:[[savePanel URL]path]];
            }
        }];

	}
}



- (IBAction) selectDifferentNominalSettingsFileAction:(id)sender
{
	BOOL ok= YES;
	if([model nominalSettingsFile]){
		BOOL cancel = ORRunAlertPanel(@"Selecting a different nominal settings file!",@"Is this really what you want?\n",@"Cancel",@"Yes, Do it",nil);
		if(!cancel){
			ok = YES;
		}
		else ok = NO;
	}
	if(ok){
		NSString* startDir = NSHomeDirectory(); //default to home
		if([model nominalSettingsFile]){
			startDir = [[model nominalSettingsFile] stringByDeletingLastPathComponent];
			if([startDir length] == 0){
				startDir = NSHomeDirectory();
			}
		}
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setCanChooseDirectories:NO];
		[openPanel setCanChooseFiles:YES];
		[openPanel setAllowsMultipleSelection:NO];
		[openPanel setPrompt:@"Choose"];
        [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
        [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                [model setNominalSettingsFile: [[openPanel URL]path]];
            }
        }];
	}
}

- (IBAction) restoreAllToNominal:(id)sender
{
	BOOL cancel = ORRunAlertPanel(@"Restoring mux and shaper settings to to nominal values",@"Is this really what you want?\n",@"Cancel",@"Yes, Do it",nil);
	if(!cancel){
		[model restoreToNomional];
	}	
}
- (IBAction) restoreMuxesToNominal:(id)sender
{
	BOOL cancel = ORRunAlertPanel(@"Restoring mux settings to to nominal values",@"Is this really what you want?\n",@"Cancel",@"Yes, Do it",nil);
	if(!cancel){
		[model restoreMuxesToNomional];
	}	
}
- (IBAction) restoreShapersToNominal:(id)sender
{
	BOOL cancel = ORRunAlertPanel(@"Restoring shaper settings to to nominal values",@"Is this really what you want?\n",@"Cancel",@"Yes, Do it",nil);
	if(!cancel){
		[model restoreShapersToNominal];
	}	
}
- (IBAction) restoreShaperGainsToNominal:(id)sender
{
	BOOL cancel = ORRunAlertPanel(@"Restoring shaper gain settings to to nominal values",@"Is this really what you want?\n",@"Cancel",@"Yes, Do it",nil);
	if(!cancel){
		[model restoreShaperGainsToNominal];
	}	
}
- (IBAction) restoreShaperThresoldsToNominal:(id)sender
{
	BOOL cancel = ORRunAlertPanel(@"Restoring shaper thresholds settings to to nominal values",@"Is this really what you want?\n",@"Cancel",@"Yes, Do it",nil);
	if(!cancel){
		[model restoreShaperThresholdsToNominal];
	}	
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self totalRateChanged:nil];
    [self colorAttributesChanged:nil];
    [self tubeRateChanged:nil];
    [self displayOptionsChanged:nil];
    [self mapFileNameChanged:nil];
    [self specialLockChanged:nil];
    [self tubeMapLockChanged:nil];
    [self detectorLockChanged:nil];
    [self nominalSettingsLockChanged:nil];
    [self hardwareCheckChanged:nil];
    [self shaperCheckChanged:nil];
    [self muxCheckChanged:nil];
    [self triggerCheckChanged:nil];
    [self captureDateChanged:nil];
    [self allDisabledChanged:nil];
    [self muxEfficiencyChanged:nil];
	[self runningAtReducedMuxEfficiencyChanged:nil];
	[self nominalSettingsFileChanged:nil];
    [ratePlot setNeedsDisplay:YES];
}

- (void) setNeedsDisplay:(BOOL)state
{
    [detectorView setNeedsDisplay:state];
}

//a fake action from the scale object
- (void) scaleAction:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [detectorColorBar colorAxis]){
        [model setColorBarAttributes:[[detectorColorBar colorAxis]attributes]];
    }
	if(aNotification == nil || [aNotification object] == [ratePlot yScale]){
		[model setMiscAttributes:[(ORAxis*)[ratePlot yScale] attributes] forKey: @"NCDYAttributes"];
	};
	
	
}

- (void) colorAttributesChanged:(NSNotification*)aNote
{        
	[(ORAxis*)[detectorColorBar colorAxis] setAttributes:[model colorBarAttributes]];
	[detectorColorBar setNeedsDisplay:YES];
	[[detectorColorBar colorAxis]setNeedsDisplay:YES];
	
	BOOL state = [[[model colorBarAttributes] objectForKey:ORAxisUseLog] boolValue];
	[colorBarLogCB setState:state];
}

- (void) tubeRateChanged:(NSNotification*)aNote
{
    [detectorView setNeedsDisplay:YES];
}

- (void) displayOptionsChanged:(NSNotification*)aNote 
{
    int numberRows = (int)[displayOptionMatrix numberOfRows];
    int i;
    for(i=0;i<numberRows;i++){
        [[displayOptionMatrix cellWithTag:i] setState:[model displayOptionState:i]];
    }
    
    [detectorView setNeedsDisplay:YES];
}

- (void) mapFileNameChanged:(NSNotification*)aNote
{
    if(aNote == nil || [aNote object] == [NcdDetector sharedInstance]){
        [mapFileField setStringValue:[[[model detector] mapFileName] stringByAbbreviatingWithTildeInPath]];
    }
}

- (void) mapFileRead:(NSNotification*)aNote
{
    if(aNote == nil || [aNote object] == [NcdDetector sharedInstance]){
        [hwTableView reloadData];
    }
}

- (void) tubeSelectionChanged:(NSNotification*)aNote
{
    if([[aNote object] selected]){
        [tubeInfoView setString:[[aNote object] description]];
    }
    [detectorView setNeedsDisplay:YES];
}

- (void) tubeParamChanged:(NSNotification*)aNote
{
    [hwTableView reloadData];
}

- (void) rateGroupChanged:(NSNotification*)aNote
{
    //do we care?
    if([NSStringFromClass([aNote class]) isEqualToString:@"ORShaperModel"]){
        [model registerForShaperRates];
    }
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
    if(!aNotification || [aNotification object] == [[model detector]shaperTotalRate] ){
        [ratePlot setNeedsDisplay:YES];
        [[ratePlot xScale]setNeedsDisplay:YES];
    }
}

- (void) slotChanged:(NSNotification*)aNote
{
    //do we care?
    id obj = [[aNote userInfo]  objectForKey:ORMovedObject];
    if([NSStringFromClass([obj class]) isEqualToString:@"ORShaperModel"]){
        [model registerForShaperRates];
        [[model detector] reloadData:nil];
    }
}


- (void) objectsChanged:(NSNotification*)aNote
{
    //do we care?
    NSArray* objects = [[aNote userInfo]  objectForKey:ORGroupObjectList];
    NSEnumerator* e = [objects objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        if([NSStringFromClass([obj class]) isEqualToString:@"ORShaperModel"]) {
            [model registerForShaperRates];
            [[model detector] reloadData:nil];
            break;
        }
    }
}


- (void) tubeMapLockChanged:(NSNotification*)aNotification
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORNcdDetectorLock];
    //BOOL runningOrLocked = [gSecurity runInProgressOrIsLocked:ORNcdDetectorLock];
    BOOL locked = [gSecurity isLocked:ORNcdTubeMapLock];
    [tubeMapLockButton setState: locked];
    
    if(locked)[hwTableView deselectAll:self];
    [addTubeButton setEnabled:!lockedOrRunningMaintenance];
    [saveMapFileButton setEnabled:!lockedOrRunningMaintenance];
    [readMapFileButton setEnabled:!lockedOrRunningMaintenance];
    [self selectionChanged:nil];
    
}

- (void) specialLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORNcdSpecialLock];
    [specialLockButton setState: locked];
    [allDisabledButton setEnabled:!locked];    
    [muxThresholdView setEnabled:!locked];    
    [muxThresholdPopup setEnabled:!locked];    
    [muxEnableButton setEnabled:!locked];    
    [muxSelectButton setEnabled:!locked];    
    [muxAddButton setEnabled:!locked];    
    if(locked)[muxThresholdView deselectAll:self];
}

- (void) detectorLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORNcdDetectorLock];
    BOOL runningOrLocked = [gSecurity runInProgressOrIsLocked:ORNcdDetectorLock];
    [detectorLockButton setState: locked];
    [standAloneButton setEnabled:!runningOrLocked];
    [captureStateButton setEnabled: !locked];
}

- (void) nominalSettingsLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORNcdNominalSettingsLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORNcdNominalSettingsLock];
	BOOL runningAtReducedEfficiency = [model runningAtReducedEfficiency];
	BOOL fileExists = ([model nominalSettingsFile]!=nil);

    [nominalSettingsLockButton setState: locked];
	
   [allToNominalButton setEnabled: !lockedOrRunningMaintenance && fileExists];
   [muxToNominalButton setEnabled: !lockedOrRunningMaintenance && fileExists];
   [shaperAllToNominalButton setEnabled: !lockedOrRunningMaintenance && fileExists];
   [shaperGainsToNominalButton setEnabled: !lockedOrRunningMaintenance && fileExists];
   [shaperThresholdsToNominalButton setEnabled: !lockedOrRunningMaintenance && fileExists];
   [captureNominalFileButton setEnabled: !lockedOrRunningMaintenance];
   [selectNominalFileButton setEnabled: !lockedOrRunningMaintenance];
   
   [setMuxEfficiencyButton setEnabled: !lockedOrRunningMaintenance && !runningAtReducedEfficiency];
   [muxEfficiencyPopup setEnabled: !lockedOrRunningMaintenance && !runningAtReducedEfficiency];
   [restoreEfficiencyButton setEnabled: !lockedOrRunningMaintenance && runningAtReducedEfficiency];


}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    //add setLock calls here as new lock buttons
    //are added to this dialog.
    [gSecurity setLock:ORNcdSpecialLock to:secure];
    [gSecurity setLock:ORNcdNominalSettingsLock to:secure];
    [gSecurity setLock:ORNcdTubeMapLock to:secure];
    [gSecurity setLock:ORNcdDetectorLock to:secure];
    [specialLockButton setEnabled: secure];
    [tubeMapLockButton setEnabled: secure];
    [detectorLockButton setEnabled: secure];
    [nominalSettingsLockButton setEnabled: secure];
    
    [self selectionChanged:nil];
}

- (void) hardwareCheckChanged:(NSNotification*)aNotification
{
    [hardwareCheckView setState:[model hardwareCheck]]; 
}

- (void) shaperCheckChanged:(NSNotification*)aNotification
{
    [shaperCheckView setState:[model shaperCheck]]; 
}

- (void) muxCheckChanged:(NSNotification*)aNotification
{
    [muxCheckView setState:[model muxCheck]]; 
}

- (void) triggerCheckChanged:(NSNotification*)aNotification
{
    [triggerCheckView setState:[model triggerCheck]]; 
}


- (void) captureDateChanged:(NSNotification*)aNotification
{
    [captureDateField setObjectValue:[model captureDate]]; 
}

- (void) nominalSettingsFileChanged:(NSNotification*)aNotification
{
    if([model nominalSettingsFile])[nominalFileField setStringValue:[[model nominalSettingsFile] stringByAbbreviatingWithTildeInPath]];
	else [nominalFileField setStringValue:@"---"];
	[self nominalSettingsLockChanged:nil];
}


- (void) runningAtReducedMuxEfficiencyChanged:(NSNotification*)aNotification
{
	[self nominalSettingsLockChanged:nil];
    if([model runningAtReducedEfficiency])[muxEfficiencyField setStringValue:[NSString stringWithFormat:@"%.0f%%",[model currentMuxEfficiency]]];
	else [muxEfficiencyField setStringValue:@"Previous"];

	if([model runningAtReducedEfficiency]){
		[reducedEfficiencyDateField setObjectValue: [[NSDate  date] description]];
	}
	else [reducedEfficiencyDateField setStringValue:@"---"];

}

- (void) muxEfficiencyChanged:(NSNotification*)aNotification
{
	[muxEfficiencyPopup selectItemWithTitle:[NSString stringWithFormat:@"%.0f%%",[model currentMuxEfficiency]]];
}

- (void) allDisabledChanged:(NSNotification*)aNotification
{
    [allDisabledButton setState:[model allDisabled]]; 
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return ![gSecurity isLocked:ORNcdTubeMapLock];
}

- (void) selectionChanged:(NSNotification*)aNote
{
    BOOL runningOrLocked = [gSecurity runInProgressOrIsLocked:ORNcdTubeMapLock];
    
    [deleteTubeButton setEnabled: !runningOrLocked && [hwTableView selectedRow]>=0];
}

- (int) numberPointsInPlot:(id)aPlotter
{
 	int set = (int)[aPlotter tag];
	if(set == 0)return (int)[[[model detector]shaperTotalRate]count];
    else        return (int)[[[model detector]muxTotalRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
  	int set = (int)[aPlotter tag];
	double aValue = 0;
	if(set == 0){
        int count = (int)[[[model detector]shaperTotalRate]count];
		if(count==0) aValue = 0;
        else aValue = [[[model detector]shaperTotalRate]valueAtIndex:count-i-1];
    }
    else {
        int count = (int)[[[model detector]muxTotalRate]count];
		if(count==0) aValue = 0;
        else aValue = [[[model detector]muxTotalRate]valueAtIndex:count-i-1];
    }
	*xValue = (double)i;
    *yValue = aValue;
}

- (void) drawView:(NSView*)aView inRect:(NSRect)aRect
{
    [[model detector] drawInRect:aRect withColorBar:detectorColorBar];
}


#pragma mark ¥¥¥Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
    NSParameterAssert(rowIndex >= 0 && rowIndex < [[[NcdDetector sharedInstance]tubes] count]);
    NcdTube* tube = [[NcdDetector sharedInstance] tube:(int)rowIndex];
    return [tube objectForKey:[aTableColumn identifier]];
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[NcdDetector sharedInstance] numberOfTubes];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSParameterAssert(rowIndex >= 0 && rowIndex < [[[NcdDetector sharedInstance]tubes] count]);
    NcdTube* tube = [[NcdDetector sharedInstance] tube:(int)rowIndex];
    [tube setObject:anObject forKey:[aTableColumn identifier]];
}

- (void) tableView:(NSTableView*)tv didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSImage *sortOrderImage = [tv indicatorImageInTableColumn:tableColumn];
    NSString *columnKey = [tableColumn identifier];
    // If the user clicked the column which already has the sort indicator
    // then just flip the sort order.
    
    if (sortOrderImage || columnKey == [[NcdDetector sharedInstance] sortColumn]) {
        [[NcdDetector sharedInstance] setSortIsDescending:![[NcdDetector sharedInstance] sortIsDescending]];
    }
    else {
        [[NcdDetector sharedInstance] setSortColumn:columnKey];
    }
    [self updateTableHeaderToMatchCurrentSort];
    // now do it - doc calls us back when done
    [[NcdDetector sharedInstance] sort];
    [hwTableView reloadData];
}

- (void) updateTableHeaderToMatchCurrentSort
{
    BOOL isDescending = [[NcdDetector sharedInstance] sortIsDescending];
    NSString *key = [[NcdDetector sharedInstance] sortColumn];
    NSArray *a = [hwTableView tableColumns];
    NSTableColumn *column = [hwTableView tableColumnWithIdentifier:key];
    NSInteger i = [a count];
    
    while (i-- > 0) [hwTableView setIndicatorImage:nil inTableColumn:[a objectAtIndex:i]];
    
    if (key) {
        [hwTableView setIndicatorImage:(isDescending ? ascendingSortingImage:descendingSortingImage) inTableColumn:column];
        
        [hwTableView setHighlightedTableColumn:column];
    }
    else {
        [hwTableView setHighlightedTableColumn:nil];
    }
}


- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [hwTableView selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [hwTableView selectedRow] >= 0;
    }
    else if ([menuItem action] == @selector(copy:)) {
        return NO; //enable when cut/paste is finished
    }
    else if ([menuItem action] == @selector(paste:)) {
        return NO; //enable when cut/paste is finished
    }
    return YES;
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    NSInteger index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.NcdController.selectedtab"];
    
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint localPoint = [detectorView convertPoint:[theEvent locationInWindow] fromView:nil];
    if(NSPointInRect(localPoint,[detectorView bounds])){
        [tubeInfoView setString:@""];
        [[NcdDetector sharedInstance] handleMouseDownAt:localPoint inView:detectorView];
    }
}

- (IBAction) selectFile:(id)sender
{
    NSArray* selected = [altMuxThresholdsController selectedObjects];
    
    NSString* startDir = NSHomeDirectory(); //default to home
    if([[selected objectAtIndex:0] objectForKey:@"muxFile"]){
        startDir = [[[selected objectAtIndex:0] objectForKey:@"muxFile"] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSString* fileName = [[[openPanel URL] path] stringByAbbreviatingWithTildeInPath];
            NSArray* selected = [altMuxThresholdsController selectedObjects];
            NSEnumerator* e = [selected objectEnumerator];
            id obj;
            while(obj = [e nextObject])[obj setObject:fileName forKey:@"muxFile"];
        }
    }];
}

@end

