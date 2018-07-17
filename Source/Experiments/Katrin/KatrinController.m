//
//  KatrinController.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
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
#import "KatrinController.h"
#import "KatrinModel.h"
#import "KatrinConstants.h"
#import "ORColorScale.h"
#import "ORTimeAxis.h"
#import "ORDetectorSegment.h"
#import "ORSegmentGroup.h"
#import "ORPlotView.h"
#import "ORTimeLinePlot.h"
#import "OR1DHistoPlot.h"
#import "ORBasicOpenGLView.h"



@implementation KatrinController
#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Katrin"];
    return self;
}

- (void) dealloc
{
    [blankView release];
    [super dealloc];
}

- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/FocalPlaneMap";
}
- (NSString*) defaultSecondaryMapFilePath
{
	return @"~/VetoMap";
}


-(void) awakeFromNib
{
	
	detectorSize		= NSMakeSize(800,770);
	slowControlsSize    = NSMakeSize(525,320);
	detailsSize			= NSMakeSize(655,589);
	focalPlaneSize		= NSMakeSize(827,589);
	vetoSize			= NSMakeSize(663,589);
	
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

	[self populateClassNamePopup:secondaryAdcClassNamePopup];

    [super awakeFromNib];
	
	if([[model segmentGroup:1] colorAxisAttributes])[[secondaryColorScale colorAxis] setAttributes:[[[[model segmentGroup:1] colorAxisAttributes] mutableCopy] autorelease]];

	[[secondaryColorScale colorAxis] setRngLimitsLow:0 withHigh:128000000 withMinRng:5];
    [[secondaryColorScale colorAxis] setRngDefaultsLow:0 withHigh:128000000];
    [[secondaryColorScale colorAxis] setOppositePosition:YES];
	[[secondaryColorScale colorAxis] setNeedsDisplay:YES];

	NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
	[formatter setFormat:@"#0.000"];	
	int i;
	for(i=0;i<2;i++){
		[[maxValueMatrix cellAtRow:i column:0]	setTag:i];
		[[lowLimitMatrix cellAtRow:i column:0]	setTag:i];
		[[hiLimitMatrix cellAtRow:i column:0]	setTag:i];
		
		[[maxValueMatrix cellAtRow:i column:0] setFormatter:formatter];
		[[lowLimitMatrix cellAtRow:i column:0] setFormatter:formatter];
		[[hiLimitMatrix cellAtRow:i column:0] setFormatter:formatter];
	}
	
	
	
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:1 andDataSource:self];
	[aPlot setLineColor:[NSColor blueColor]];
	[ratePlot addPlot: aPlot];
	[aPlot release];
	
	OR1DHistoPlot* aPlot1 = [[OR1DHistoPlot alloc] initWithTag:11 andDataSource:self];
	[valueHistogramsPlot addPlot: aPlot1];
	[aPlot1 release];
}

- (NSView*) viewToDisplay
{
    if([model viewType]==kUse3DView)return openGlView;
    else return detectorView;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
					   
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
                     selector : @selector(slowControlIsConnectedChanged:)
                         name : KatrinModelSlowControlIsConnectedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(slowControlNameChanged:)
                         name : KatrinModelSlowControlNameChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(viewTypeChanged:)
                         name : ORKatrinModelViewTypeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(snTablesChanged:)
                         name : ORKatrinModelSNTablesChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(maxValueChanged:)
                         name : ORKatrinModelMaxValueChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(lowLimitChanged:)
                         name : ORKatrinModelLowLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(hiLimitChanged:)
                         name : ORKatrinModelHiLimitChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(vetoMapLockChanged:)
                         name : [model vetoMapLock]
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(vetoMapLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(fpdOnlyModeChanged:)
                         name : KatrinModelFPDOnlyModeChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];

	//detector
    [self secondaryColorAxisAttributesChanged:nil];

	//hw map
    [self vetoMapLockChanged:nil];
	[self secondaryMapFileChanged:nil];
	[self secondaryAdcClassNameChanged:nil];

	//details
	[secondaryValuesView reloadData];
	
	[self slowControlIsConnectedChanged:nil];
	[self slowControlNameChanged:nil];
	[self viewTypeChanged:nil];
	[self snTablesChanged:nil];
	
	[self lowLimitChanged:nil];
	[self hiLimitChanged:nil];
	[self maxValueChanged:nil];
	
	[self fpdOnlyModeChanged:nil];
}

- (void) colorScaleTypeChanged:(NSNotification*)aNote
{
    [super colorScaleTypeChanged:aNote];
    [secondaryColorScale setUseRainBow:[model colorScaleType]==0];
    [secondaryColorScale setStartColor:[primaryColorScale startColor]];
    [secondaryColorScale setEndColor:[primaryColorScale endColor]];
}

- (void) lowLimitChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<2;i++){
		[[lowLimitMatrix cellWithTag:i] setFloatValue:[model lowLimit:i]];
	}
}

- (void) hiLimitChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<2;i++){
		[[hiLimitMatrix cellWithTag:i] setFloatValue:[model hiLimit:i]];
	}

}

- (void) maxValueChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<2;i++){
		[[maxValueMatrix cellWithTag:i] setFloatValue:[model maxValue:i]];
	}

}

- (void) primaryMapFileChanged:(NSNotification*)aNote
{
	[super primaryMapFileChanged:aNote];
	NSString* s = [[[model segmentGroup:0] mapFile] stringByAbbreviatingWithTildeInPath];
	if(s) {
		s = [s stringByDeletingPathExtension];
		[fltOrbSNField	 setStringValue:[FLTORBSNFILE(s) lastPathComponent]];
		[osbSNField		 setStringValue:[OSBSNFILE(s) lastPathComponent]];
		[preampSNField	 setStringValue:[PREAMPSNFILE(s) lastPathComponent]];
		[sltWaferSNField setStringValue:[SLTWAFERSNFILE(s) lastPathComponent]];
	}
	else {
		[fltOrbSNField setStringValue:@"--"];	
		[osbSNField setStringValue:@"--"];	
		[preampSNField setStringValue:@"--"];	
		[sltWaferSNField setStringValue:@"--"];	
	}
}

- (void) refreshSegmentTables:(NSNotification*)aNote
{
	[super refreshSegmentTables:aNote];
	[secondaryTableView reloadData];
}

- (void) snTablesChanged:(NSNotification*)aNote
{
	[fltSNTableView reloadData];
	[preAmpSNTableView reloadData];
	[osbSNTableView reloadData];
	[otherSNTableView reloadData];
}

- (void) mapFileRead:(NSNotification*)mapFileRead
{
	[super mapFileRead:mapFileRead];
	[self snTablesChanged:nil];
}

- (void) viewTypeChanged:(NSNotification*)aNote
{
	[viewTypePU selectItemAtIndex:[model viewType]];
	[detectorView setViewType:[model viewType]];
	[detectorView makeAllSegments];
    if([model viewType] == kUse3DView){
        [viewTabView selectTabViewItemAtIndex:1];
        [[focalPlaneColorScale colorAxis] setViewToScale: openGlView];
    }
    else {
        [viewTabView selectTabViewItemAtIndex:0];
        [[focalPlaneColorScale colorAxis] setViewToScale: detectorView];
  
    }

}

- (ORSegmentGroup*) segmentGroup:(int)aSet
{
    return [model segmentGroup:aSet];
}

- (int) displayType
{
    return [model displayType];
}

#pragma mark ¥¥¥Actions
- (IBAction) fpdOnlyModeAction:(id)sender
{
    BOOL fpdOnlyMode = [model fpdOnlyMode];
 
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:fpdOnlyMode?@"Reenable Veto Channels?":@"Disable ALL Veto channels?"];
    [alert setInformativeText:fpdOnlyMode?@"This will re-enable veto channels to the state they were before.":@"This will disable ALL Veto channels. The current state will be saved until ORCA quits."];
    [alert addButtonWithTitle:@"Yes,Do It"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model toggleFPDOnlyMode];
        }
    }];
#else
    NSBeginAlertSheet(fpdOnlyMode?@"Reenable Veto Channels?":@"Disable ALL Veto channels?",
                      @"Cancel",
                      @"Yes/Do it!",
                      nil,[self window],
                      self,
                      @selector(toggleSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,fpdOnlyMode?@"This will re-enable veto channels to the state they were before.":@"This will disable ALL Veto channels. The current state will be saved until ORCA quits.");
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) toggleSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
        [model toggleFPDOnlyMode];
    }
}
#endif
- (IBAction) autoscaleSecondayColorScale:(id)sender
{
    int n = [[model segmentGroup:1] numSegments];
    int i;
    float maxValue = -99999;
    for(i=0;i<n;i++){
        float aValue = maxValue;
        switch([model displayType]){
            case kDisplayThresholds:	aValue = [[model segmentGroup:1] getThreshold:i];     break;
            case kDisplayGains:			aValue = [[model segmentGroup:1] getGain:i];          break;
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

- (IBAction) vetoMapLockAction:(id)sender
{
    [gSecurity tryToSetLock:[model vetoMapLock] to:[sender intValue] forWindow:[self window]];
}

- (IBAction) lowLimitAction:(id)sender
{
	[model setLowLimit:(int)[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];
}

- (IBAction) hiLimitAction:(id)sender
{
	[model setHiLimit:(int)[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];
}


- (IBAction) maxValueAction:(id)sender
{
	[model setMaxValue:(int)[[sender selectedCell] tag] value:[[sender selectedCell] floatValue]];
}

- (IBAction) slowControlNameAction:(id)sender
{
	[model setSlowControlName:[sender stringValue]];	
}

- (IBAction) secondaryAdcClassNameAction:(id)sender
{
	[[model segmentGroup:1] setAdcClassName:[sender titleOfSelectedItem]];	
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

#pragma mark ¥¥¥Interface Management

- (void) fpdOnlyModeChanged:(NSNotification*)aNote
{
	[fpdOnlyModeField setStringValue:   [model fpdOnlyMode]?@"Veto Disabled":@"Veto & FPD"];
    [fpdOnlyModeButton setTitle:        [model fpdOnlyMode]?@"Reenable Veto...":@"Disable ALL Veto..."];
}

- (IBAction) viewTypeAction:(id)sender
{
	[model setViewType:(int)[sender indexOfSelectedItem]];
}


- (void) slowControlNameChanged:(NSNotification*)aNote
{
	[slowControlNameField setStringValue: [model slowControlName]];
}

- (void) slowControlIsConnectedChanged:(NSNotification*)aNote
{
	NSString* s;
	if([model slowControlIsConnected]){
		[slowControlIsConnectedField setTextColor:[NSColor blackColor]];
		[slowControlIsConnectedField1 setTextColor:[NSColor blackColor]];
		s = @"Connected";
	}
	else {
		s = @"NOT Connected";
		[slowControlIsConnectedField setTextColor:[NSColor redColor]];
		[slowControlIsConnectedField1 setTextColor:[NSColor redColor]];
	}	
	[slowControlIsConnectedField setStringValue:s];
	[slowControlIsConnectedField1 setStringValue:s];
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[secondaryTableView reloadData];
	[secondaryValuesView reloadData];
	//if([model viewType] == kUseCrateView){
		[detectorView makeAllSegments];
	//}
}

- (void) setDetectorTitle
{	
	switch([model displayType]){
		case kDisplayRates:			[detectorTitle setStringValue:@"Detector Rate"];	break;
		case kDisplayThresholds:	[detectorTitle setStringValue:@"Thresholds"];		break;
		case kDisplayGains:			[detectorTitle setStringValue:@"Gains"];			break;
		case kDisplayTotalCounts:	[detectorTitle setStringValue:@"Total Counts"];		break;
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

#pragma mark ¥¥¥HW Map Interface Management

- (void) checkGlobalSecurity
{
    [super checkGlobalSecurity];
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:[model vetoMapLock] to:secure];
    [vetoMapLockButton setEnabled: secure];    
}

- (void) detectorLockChanged:(NSNotification*)aNotification
{
    [super detectorLockChanged:aNotification];
    //BOOL locked = [gSecurity isLocked:[model experimentDetectorLock]];
    //BOOL running = [gOrcaGlobals runInProgress];
    //[fpdOnlyModeButton setEnabled: !locked & !running]; //as per Florian's request 3/19/2013
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

#pragma mark ¥¥¥Details Interface Management
- (void) detailsLockChanged:(NSNotification*)aNotification
{
	[super detailsLockChanged:aNotification];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model experimentDetailsLock]];
    BOOL locked = [gSecurity isLocked:[model experimentDetailsLock]];

	[detailsLockButton setState: locked];
    [initButton setEnabled: !lockedOrRunningMaintenance];

	if(locked){
		[secondaryValuesView deselectAll:self];
	}
}

#pragma mark ¥¥¥Table Data Source
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	if(tableView == secondaryTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == fltSNTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == preAmpSNTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == osbSNTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == otherSNTableView){
		return ![gSecurity isLocked:[model experimentMapLock]];
	}
	else if(tableView == secondaryValuesView){
		return ![gSecurity isLocked:[model experimentDetailsLock]];
	}
	else return [super tableView:tableView shouldSelectRow:row];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
	if(aTableView == secondaryTableView || aTableView == secondaryValuesView){
		return [[model segmentGroup:1] segment:(int)rowIndex objectForKey:[aTableColumn identifier]];
	}
	else if(aTableView == fltSNTableView){
		return [model fltSN:(int)rowIndex objectForKey:[aTableColumn identifier]];
	}
	else if(aTableView == preAmpSNTableView){
		return [model preAmpSN:(int)rowIndex objectForKey:[aTableColumn identifier]];
	}
	else if(aTableView == osbSNTableView){
		return [model osbSN:(int)rowIndex objectForKey:[aTableColumn identifier]];
	}
	else if(aTableView == otherSNTableView){
		return [model otherSNForKey:[aTableColumn identifier]];
	}
	else return  [super tableView:aTableView objectValueForTableColumn:aTableColumn row:rowIndex];
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if( aTableView == secondaryTableView || 
		aTableView == secondaryValuesView)    return [[model segmentGroup:1] numSegments];
	else if(aTableView == fltSNTableView)     return 8; 
	else if(aTableView == preAmpSNTableView)  return 24; 
	else if(aTableView == osbSNTableView)     return 4; 
	else if(aTableView == otherSNTableView)   return 1; 
	else								      return [super numberOfRowsInTableView:aTableView];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	ORDetectorSegment* aSegment;
	if(aTableView == secondaryTableView){
		aSegment = [[model segmentGroup:1] segment:(int)rowIndex];
		[aSegment setObject:anObject forKey:[aTableColumn identifier]];
		[[model segmentGroup:1] configurationChanged:nil];
	}
	else if(aTableView == secondaryValuesView){
		aSegment = [[model segmentGroup:1] segment:(int)rowIndex];
		if([[aTableColumn identifier] isEqualToString:@"threshold"]){
			[aSegment setThreshold:anObject];
		}
		else if([[aTableColumn identifier] isEqualToString:@"gain"]){
			[aSegment setGain:anObject];
		}
	}
	
	else if(aTableView == fltSNTableView){
		[model fltSN:(int)rowIndex setObject:anObject forKey:[aTableColumn identifier]];
	}
	else if(aTableView == preAmpSNTableView){
		[model preAmpSN:(int)rowIndex setObject:anObject forKey:[aTableColumn identifier]];
	}
	else if(aTableView == osbSNTableView){
		[model osbSN:(int)rowIndex setObject:anObject forKey:[aTableColumn identifier]];
	}
	else if(aTableView == otherSNTableView){
		[model setOtherSNObject:anObject forKey:[aTableColumn identifier]];
	}
	else [super tableView:aTableView setObjectValue:anObject forTableColumn:aTableColumn row:rowIndex];
}


- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	float toolBarOffset = 0;
	BOOL toolBarVisible = [[[self window] toolbar] isVisible];
	if(toolBarVisible){
		switch([[[self window] toolbar] sizeMode]){
			case NSToolbarSizeModeRegular:	toolBarOffset = 60; break;
			case NSToolbarSizeModeSmall:	toolBarOffset = 50; break;
			default:						toolBarOffset = 60; break;
		}
	}
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		NSSize newSize = detectorSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		NSSize newSize = slowControlsSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		NSSize newSize = detailsSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		NSSize newSize = focalPlaneSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
	else if([tabView indexOfTabViewItem:tabViewItem] == 4){
		[[self window] setContentView:blankView];
		NSSize newSize = vetoSize;
		newSize.height += toolBarOffset;
		[self resizeWindowToSize:newSize];
		[[self window] setContentView:tabView];
    }
	NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.KatrinController.selectedtab"];
}



@end
