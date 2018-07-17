//
//  HaloController.m
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


#pragma mark •••Imported Files
#import "HaloController.h"
#import "HaloModel.h"
#import "ORDetectorSegment.h"
#import "ORSegmentGroup.h"
#import "HaloSentry.h"
#import "OR1DHistoPlot.h"
#import "ORCompositePlotView.h"

@implementation HaloController
#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Halo"];
    return self;
}

- (NSString*) defaultPrimaryMapFilePath
{
	return @"~/Halo";
}

- (NSString*) defaultSecondaryMapFilePath
{
	return @"~/TestMap";
}

- (void) dealloc
{
    [blankView release];
    [super dealloc];
}

-(void) awakeFromNib
{
	
	detectorSize		= NSMakeSize(620,595);
	detailsSize			= NSMakeSize(550,589);
	focalPlaneSize		= NSMakeSize(740,589);
	testDectorSize      = NSMakeSize(740,300);
	sentrySize          = NSMakeSize(700,500);
	
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

    [self populateClassNamePopup:secondaryAdcClassNamePopup];

    [super awakeFromNib];

    OR1DHistoPlot* aPlot1 = [[OR1DHistoPlot alloc] initWithTag:11 andDataSource:self];
	[valueHistogramsPlot addPlot: aPlot1];
    [aPlot1 setLineColor:[NSColor blueColor]];
 	[aPlot1 setUseConstantColor:YES];
    [aPlot1 setName:@"Test Tubes"];
	[aPlot1 release];
    
    OR1DHistoPlot* aPlot0 = [valueHistogramsPlot plot:0];
    [aPlot0 setLineColor:[NSColor redColor]];
    [aPlot0 setName:@"Detector"];
    
    [valueHistogramsPlot setShowLegend:YES];
}


#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];

    [notifyCenter addObserver : self
                     selector : @selector(secondaryAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
						object: [model segmentGroup:1]];
    
    [notifyCenter addObserver : self
                     selector : @selector(secondaryMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
						object: [model segmentGroup:1]];

    
    [notifyCenter addObserver : self
                     selector : @selector(viewTypeChanged:)
                         name : HaloModelViewTypeChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerNotificationObservers)
                         name : HaloModelHaloSentryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ipNumberChanged:)
                         name : HaloSentryIpNumber1Changed
						object: [model haloSentry]];
    
    [notifyCenter addObserver : self
                     selector : @selector(ipNumberChanged:)
                         name : HaloSentryIpNumber2Changed
						object: [model haloSentry]];
 
    [notifyCenter addObserver : self
                     selector : @selector(sentryTypeChanged:)
                         name : HaloSentryTypeChanged
						object: [model haloSentry]];
    
    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : HaloSentryStateChanged
						object: [model haloSentry]];

    [notifyCenter addObserver : self
                     selector : @selector(remoteStateChanged:)
                         name : HaloSentryRemoteStateChanged
						object: [model haloSentry]];

    [notifyCenter addObserver : self
                     selector : @selector(stealthMode1Changed:)
                         name : HaloSentryStealthMode1Changed
						object: [model haloSentry]];

    [notifyCenter addObserver : self
                     selector : @selector(stealthMode2Changed:)
                         name : HaloSentryStealthMode2Changed
						object: [model haloSentry]];
    
    [notifyCenter addObserver : self
                     selector : @selector(sentryIsRunningChanged:)
                         name : HaloSentryIsRunningChanged
						object: [model haloSentry]];   

    [notifyCenter addObserver : self
                     selector : @selector(sentryLockChanged:)
                         name : HaloModelSentryLock
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(remoteStateChanged:)
                         name : HaloSentryMissedHeartbeat
						object: [model haloSentry]];
   
    [notifyCenter addObserver : self
                     selector : @selector(sbcPasswordChanged:)
                         name : HaloSentrySbcRootPwdChanged
						object: [model haloSentry]];

    [notifyCenter addObserver : self
                     selector : @selector(emailListChanged:)
                         name : HaloModelEmailListChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(heartBeatIndexChanged:)
                         name : HaloModelNextHeartBeatChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(nextHeartBeatChanged:)
                         name : HaloModelNextHeartBeatChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(runStateChanged:)
                         name : ORRunStatusChangedNotification
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(secondaryMapLockChanged:)
                         name : [model secondaryMapLock]
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(secondaryMapLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(toggleIntervalChanged:)
                         name : HaloSentryToggleIntervalChanged
                       object : nil];
   
}

- (void) updateWindow
{
    [super updateWindow];
	[self viewTypeChanged:nil];
	[self stateChanged:nil];
	[self sentryTypeChanged:nil];
	[self ipNumberChanged:nil];
	[self remoteStateChanged:nil];
	[self stealthMode1Changed:nil];
	[self stealthMode2Changed:nil];
	[self sentryIsRunningChanged:nil];
	[self sbcPasswordChanged:nil];
    [self heartBeatIndexChanged:nil];
	[self nextHeartBeatChanged:nil];
    [self runStateChanged:nil];
    [self sentryLockChanged:nil];
	[self secondaryMapFileChanged:nil];
	[self secondaryAdcClassNameChanged:nil];
	[self secondaryMapLockChanged:nil];
    [self toggleIntervalChanged:nil];
	[secondaryValuesView reloadData];
}

#pragma mark •••Interface Management
- (void) checkGlobalSecurity
{
    [super checkGlobalSecurity];
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:HaloModelSentryLock to:secure];
    [gSecurity setLock:[model secondaryMapLock] to:secure];
    [sentryLockButton setEnabled:secure];
    [secondaryMapLockButton setEnabled:secure];
}

- (void) runStateChanged:(NSNotification*)aNote
{
    NSString* s = [[[[ORGlobal sharedGlobal] runModeString] copy] autorelease];
    if([s length] == 0)s = @"Not Running";
    s = [s stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSRange maskRange = [s rangeOfString:@"Mask"];
    if(maskRange.location != NSNotFound){
        s = [s substringToIndex:maskRange.location];
    }
    [localRunInProgressField setStringValue:s];
}

- (void) heartBeatIndexChanged:(NSNotification*)aNote
{
	[heartBeatIndexPU selectItemAtIndex: [model heartBeatIndex]];
}

- (void) nextHeartBeatChanged:(NSNotification*)aNote
{
	if([model heartbeatSeconds]){
		[nextHeartbeatField setStringValue:[NSString stringWithFormat:@"Next Heartbeat: %@",[[model nextHeartbeat]stdDescription]]];
	}
	else [nextHeartbeatField setStringValue:@"No Heartbeat Scheduled"];
}

- (void) emailListChanged:(NSNotification*)aNote
{
	[emailListTable reloadData];
}

- (void) sentryIsRunningChanged:(NSNotification*)aNote
{
    [sentryRunningField setStringValue:[[model haloSentry] sentryIsRunning]?@"Running":@"STOPPED"];
    [self updateButtons];
}

- (void) remoteStateChanged:(NSNotification*)aNote
{
    if([[model haloSentry]state] != eIdle){
        [remoteMachineRunningField  setStringValue: [[model haloSentry] remoteMachineStatusString]];
        [connectedField             setStringValue: [[model haloSentry] connectionStatusString]];
        [remoteRunInProgressField   setStringValue: [[model haloSentry] remoteORCArunStateString]];
    }
    else {
        [remoteMachineRunningField  setStringValue:@"?"];
        [connectedField             setStringValue:@"?"];
        [remoteRunInProgressField   setStringValue:@"?"];        
    }
    [self updateButtons];
}

- (void) sentryTypeChanged:(NSNotification*)aNote
{
    [sentryTypeField setStringValue:[[model haloSentry] sentryTypeName]];
}

- (void) sbcPasswordChanged:(NSNotification*)aNote
{
    [sbcPasswordField setStringValue:[[model haloSentry] sbcRootPwd]];
}

- (void) stateChanged:(NSNotification*)aNote
{
    [stateField setStringValue:[[model haloSentry] stateName]];
    [restartCountField setIntValue:[[model haloSentry] restartCount]];
    [dropSBCConnectionCountField setIntValue:[[model haloSentry] sbcSocketDropCount]];
    [sbcPingFailedCountField setIntValue:[[model haloSentry] sbcPingFailedCount]];
    [macPingFailedCountField setIntValue:[[model haloSentry] macPingFailedCount]];
    [missedHeartBeatsCountField setIntValue:[[model haloSentry] missedHeartBeatCount]];
    [sbcRebootCountField setIntValue:[[model haloSentry] sbcRebootCount]];
}

- (void) ipNumberChanged:(NSNotification*)aNote
{
    [ip1Field setStringValue:[[model haloSentry] ipNumber1]];
    [ip2Field setStringValue:[[model haloSentry] ipNumber2]];
}

- (void) viewTypeChanged:(NSNotification*)aNote
{
	[viewTypePU selectItemAtIndex:[model viewType]];
	[detectorView setViewType:[model viewType]];
	[detectorView makeAllSegments];	
}

- (void) stealthMode2Changed:(NSNotification*)aNote
{
	[stealthMode2CB setIntValue: [[model haloSentry] stealthMode2]];
}

- (void) stealthMode1Changed:(NSNotification*)aNote
{
	[stealthMode1CB setIntValue: [[model haloSentry] stealthMode1]];
}

- (void) specialUpdate:(NSNotification*)aNote
{
	[super specialUpdate:aNote];
	[detectorView makeAllSegments];
	[secondaryTableView reloadData];
	[secondaryValuesView reloadData];
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

- (void) sentryLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:HaloModelSentryLock];
	[sentryLockButton setState: locked];
    [self updateButtons];
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

- (void) secondaryMapLockChanged:(NSNotification*)aNotification
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model secondaryMapLock]];
    //BOOL runningOrLocked = [gSecurity runInProgressOrIsLocked:ORPrespectrometerLock];
    BOOL locked = [gSecurity isLocked:[model secondaryMapLock]];
    [secondaryMapLockButton setState: locked];
    
    if(locked){
		[secondaryTableView deselectAll:self];
	}
    [readSecondaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
    [saveSecondaryMapFileButton setEnabled:!lockedOrRunningMaintenance];
	[secondaryAdcClassNamePopup setEnabled:!lockedOrRunningMaintenance];
}

//SV
- (void) toggleIntervalChanged:(NSNotification*)aNotification
{
    int tag;
    switch([[model haloSentry] toggleInterval]/86400)
    {
        case 0:
            tag = 0; break;
        case 2:
            tag = 1; break;
        case 7:
            tag = 2; break;
        case 14:
            tag = 3; break;
        default:
            tag = 0; break;
    }
    [schedulerSetupPU selectItemAtIndex:tag];

    [nextToggleField setStringValue:[[model haloSentry] nextToggleTime]];
}

- (void) updateButtons
{
    BOOL locked             = [gSecurity isLocked:HaloModelSentryLock];
    BOOL sentryRunning      = [[model haloSentry] sentryIsRunning];
    BOOL aRunIsInProgress   = [[model haloSentry] runIsInProgress];
   	BOOL anyAddresses       = ([[model emailList] count]>0);
    BOOL localRunInProgress = [[ORGlobal sharedGlobal] runInProgress];
    
	[heartBeatIndexPU setEnabled:anyAddresses];
 
    [stealthMode2CB      setEnabled:!locked && !sentryRunning];
    [stealthMode1CB      setEnabled:!locked && !sentryRunning];
    [ip1Field            setEnabled:!locked && !sentryRunning];
    [ip2Field            setEnabled:!locked && !sentryRunning];
    [startButton         setEnabled:!locked];
    [startButton         setTitle:   sentryRunning?@"Stop":@"Start"];
    [toggleButton        setEnabled:!locked & aRunIsInProgress];
    [sbcPasswordField    setEnabled:!locked & aRunIsInProgress];
    [updateShapersButton setEnabled:!locked & !localRunInProgress];
}

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
		[self resizeWindowToSize:focalPlaneSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:testDectorSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 4){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:sentrySize];
		[[self window] setContentView:tabView];
    }
    
	int index = (int)[tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.HaloController.selectedtab"];
}

#pragma mark •••Actions
- (IBAction) secondaryMapLockAction:(id)sender
{
    [gSecurity tryToSetLock:[model secondaryMapLock] to:[sender intValue] forWindow:[self window]];
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
- (IBAction) addAddress:(id)sender
{
	int index = (int)[[model emailList] count];
	[model addAddress:@"<eMail>" atIndex:index];
	NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:index];
	[emailListTable selectRowIndexes:indexSet byExtendingSelection:NO];
	[self updateButtons];
	[emailListTable reloadData];
}

- (IBAction) removeAddress:(id)sender
{
	//only one can be selected at a time. If that restriction is lifted then the following will have to be changed
	//to something a lot more complicated.
	NSIndexSet* theSet = [emailListTable selectedRowIndexes];
	NSUInteger current_index = [theSet firstIndex];
    if(current_index != NSNotFound){
		[model removeAddressAtIndex:current_index];
	}
	[self updateButtons];
	[emailListTable reloadData];
}

- (IBAction) heartBeatIndexAction:(id)sender
{
	[model setHeartBeatIndex:(int)[sender indexOfSelectedItem]];
}

- (IBAction) sbcPasswordAction:(id)sender
{
	[[model haloSentry] setSbcRootPwd:[sender stringValue]];
}

- (IBAction) stealthMode2Action:(id)sender
{
	[[model haloSentry] setStealthMode2:[sender intValue]];
}

- (IBAction) stealthMode1Action:(id)sender
{
	[[model haloSentry] setStealthMode1:[sender intValue]];	
}

- (IBAction) viewTypeAction:(id)sender
{
	[model setViewType:(int)[sender indexOfSelectedItem]];
}

- (IBAction) ip1Action:(id)sender
{
	[[model haloSentry] setIpNumber1:[sender stringValue]];
}
- (IBAction) ip2Action:(id)sender
{
	[[model haloSentry] setIpNumber2:[sender stringValue]];
}

- (IBAction) toggleSystems:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Toggle Primary Machine"];
    [alert setInformativeText:@"Really switch which machine is the one in control of the run?"];
    [alert addButtonWithTitle:@"Yes/Switch Machines"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [[model haloSentry] toggleSystems];
        }
    }];
#else
    NSBeginAlertSheet(@"Toggle Primary Machine",
                      @"Cancel",
                      @"Yes/Switch Machines",
                      nil,[self window],
                      self,
                      @selector(_toggleSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really switch which machine is the one in control of the run?");
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _toggleSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
        [[model haloSentry] toggleSystems];
    }
}
#endif
- (IBAction) updateRemoteShapersAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Update Remote Shapers"];
    [alert setInformativeText:@"Really send the Threshods and Gains to the other machine?\nThey will be loaded into HW at start of next run."];
    [alert addButtonWithTitle:@"Yes/Update"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [[model haloSentry] updateRemoteShapers];
       }
    }];
#else
    NSBeginAlertSheet(@"Update Remote Shapers",
                      @"Cancel",
                      @"Yes/Update",
                      nil,[self window],
                      self,
                      @selector(_updateShaperSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really send the Threshods and Gains to the other machine?\nThey will be loaded into HW at start of next run.");
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _updateShaperSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
        [[model haloSentry] updateRemoteShapers];
    }
}
#endif
- (IBAction) sentryLockAction:(id)sender
{
    [gSecurity tryToSetLock:HaloModelSentryLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) startStopSentry:(id)sender
{
    [self endEditing];
    if(![[model haloSentry] sentryIsRunning]){
        [[model haloSentry] start];
    }
    else {
        [[model haloSentry] stop];
    }
}

- (IBAction) clearStatsAction:(id)sender
{
    [[model haloSentry] clearStats];

}

//SV
- (IBAction)schedulerSetupChanged:(id)sender
{
    int index = (int)[sender indexOfSelectedItem];
    int seconds = 0;
    
    switch(index){
        case 0:
            seconds = 0;
            break;
        case 1:
            seconds = 2*86400;
            break;
        case 2:
            seconds = 7*86400;
            break;
        case 3:
            seconds = 14*86400;
            break;
    }

    [[model haloSentry] setToggleInterval:seconds];
}

#pragma mark •••Data Source
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == emailListTable || aNotification == nil){
		NSInteger selectedIndex = [emailListTable selectedRow];
		[removeAddressButton setEnabled:selectedIndex>=0];
	}
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
	if(aTableView == emailListTable){
		if(rowIndex < [[model emailList] count]){
			id addressObj = [[model emailList] objectAtIndex:rowIndex];
			return addressObj;
		}
		else return @"";
	}
	else if(aTableView == secondaryTableView || aTableView == secondaryValuesView){
		return [[model segmentGroup:1] segment:(int)rowIndex objectForKey:[aTableColumn identifier]];
	}
    else return [super tableView:aTableView objectValueForTableColumn:aTableColumn row:rowIndex];
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    ORDetectorSegment* aSegment;
	if(aTableView == emailListTable){
		if(rowIndex < [[model emailList] count]){
			[[model emailList] replaceObjectAtIndex:rowIndex withObject:anObject];
		}
	}
	else if(aTableView == secondaryTableView){
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
    else [super tableView:aTableView setObjectValue:anObject forTableColumn:aTableColumn row:rowIndex];
}

// just returns the number of items we have.
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
 	if(aTableView == emailListTable){
		return (NSInteger)[[model emailList] count];
    }
    else if( aTableView == secondaryTableView ||
           aTableView == secondaryValuesView)    return [[model segmentGroup:1] numSegments];

    else return [super numberOfRowsInTableView:aTableView];
}

@end


