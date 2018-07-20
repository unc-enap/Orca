//
//  ORnEDMCoilController.m
//  Orca
//
//  Created by Michael Marino 15 Mar 2012 
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


#pragma mark •••Imported Files
#import "ORnEDMCoilController.h"
#import "ORnEDMCoilModel.h"
#import "ORAdcProcessing.h"
#import "ORTTCPX400DPModel.h"
#import "ORVXI11HardwareFinder.h"


@interface ORnEDMCoilController (private)
- (void) _buildPopUpButtons;
- (void) _readFile:(id)sender withSelector:(SEL)asel withMessage:(NSString*)message;
- (void) _saveFile:(id)sender withSelector:(SEL)asel withMessage:(NSString*)message;
@end

@implementation ORnEDMCoilController

- (id) init
{
    self = [super initWithWindowNibName:@"nEDMCoil"];
    return self;
}

- (void) dealloc
{
	[blankView release];
    [startingDirectory release];
	[super dealloc];
}

- (void) awakeFromNib
{
    
	[groupView setGroup:model];
    
    controlSize		= NSMakeSize(840,640);
    powerSupplySize	= NSMakeSize(450,549);
    adcSize         = NSMakeSize(350,589);
    configSize      = NSMakeSize(760,640);
    
    blankView = [[NSView alloc] init];
    [coilText setFrameCenterRotation:90];// CGAffineTransformMakeRotation(M_PI/4);
    //[self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

    [super awakeFromNib];

}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
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
                     selector : @selector(documentLockChanged:)
                         name : ORDocumentLock
                        object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(documentLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];

	[notifyCenter addObserver : self
					 selector : @selector(runRateChanged:)
						 name : ORnEDMCoilPollingFrequencyChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(proportionalTermChanged:)
						 name : ORnEDMCoilProportionalTermChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(integralTermChanged:)
						 name : ORnEDMCoilIntegralTermChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(feedbackThresholdChanged:)
						 name : ORnEDMCoilFeedbackThresholdChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(regularizationParameterChanged:)
						 name : ORnEDMCoilRegularizationParameterChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(runCommentChanged:)
						 name : ORnEDMCoilRunCommentChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(runStatusChanged:)
						 name : ORnEDMCoilPollingActivityChanged
					   object : nil];

    [notifyCenter addObserver : self
					 selector : @selector(modelADCListChanged:)
						 name : ORnEDMCoilADCListChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(channelMapChanged:)
						 name : ORnEDMCoilHWMapChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(sensitivityMapChanged:)
						 name : ORnEDMCoilSensitivityMapChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(sensorInfoChanged:)
						 name : ORnEDMCoilSensorInfoChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(objectsAdded:)
						 name : ORGroupObjectsAdded
					   object : nil];   
    
    [notifyCenter addObserver : self
					 selector : @selector(objectsAdded:)
						 name : ORGroupObjectsRemoved
					   object : nil];   
    
    [notifyCenter addObserver : self
					 selector : @selector(debugRunningChanged:)
						 name : ORnEDMCoilDebugRunningHasChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(dynamicModeChanged:)
						 name : ORnEDMCoilDynamicModeHasChanged
					   object : nil];

    [notifyCenter addObserver : self
					 selector : @selector(refreshIPAddressesDone:)
						 name : ORHardwareFinderAvailableHardwareChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(processVerboseAction:)
						 name : ORnEDMCoilVerboseHasChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(realProcessFrequencyChanged:)
						 name : ORnEDMCoilRealProcessTimeHasChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(postDataToDBChanged:)
						 name : ORnEDMCoilPostDataToDBHasChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(postToPathChanged:)
						 name : ORnEDMCoilPostToPathHasChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(postToDBPeriodChanged:)
						 name : ORnEDMCoilPostDataToDBPeriodHasChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(targetFieldChanged:)
						 name : ORnEDMCoilTargetFieldHasChanged
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(startCurrentChanged:)
						 name : ORnEDMCoilStartCurrentHasChanged
					   object : nil];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSSize temp;
    switch ([tabView indexOfTabViewItem:tabViewItem]) {
        case 0:
            temp = controlSize;
            break;
        case 1:
            temp = powerSupplySize;
            break;
        case 2:
            temp = adcSize;
            break;
        case 3:
            temp = configSize;
            break;
        default:
            return;
    }
    [[self window] setContentView:blankView];
    [self resizeWindowToSize:temp];
    [[self window] setContentView:tabView];
    
	
    NSString* key = @"orca.nEDMExperiment%d.selectedtab";
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

- (void) runRateChanged:(NSNotification *)aNote
{
    [runRateField setFloatValue:[model pollingFrequency]];
}

- (void) proportionalTermChanged:(NSNotification *)aNote
{
    [proportionalTermField setFloatValue:[model proportionalTerm]];
}

- (void) integralTermChanged:(NSNotification *)aNote
{
    [integralTermField setFloatValue:[model integralTerm]];
}

- (void) feedbackThresholdChanged:(NSNotification *)aNote
{
    [feedbackThresholdField setFloatValue:[model feedbackThreshold]];
}

- (void) regularizationParameterChanged:(NSNotification *)aNote
{
    [regularizationParameterField setFloatValue:[model regularizationParameter]];
}

- (void) runCommentChanged:(NSNotification *)aNote
{
    [runCommentField setStringValue:[model runComment]];
}

- (void) runStatusChanged:(NSNotification *)aNote
{
    if ([model isRunning]) {
        [startStopButton setTitle:@"Stop Process"];
        [processIndicate startAnimation:self];
        [realProcessFrequencyField setHidden:NO];
    } else {
        [startStopButton setTitle:@"Start Process"];
        [processIndicate stopAnimation:self];
        [realProcessFrequencyField setHidden:YES];
    }
    
    [startStopButton setEnabled:YES];
}

- (void) viewChanged:(NSNotification*)aNotification
{
    [model performSelector:@selector(setUpImage) withObject:nil afterDelay:0];
}

- (void) debugRunningChanged:(NSNotification*)aNote
{
    [debugModeButton setState:[model debugRunning]];
}

- (void) dynamicModeChanged:(NSNotification*)aNote
{
    [dynamicModeButton setState:[model dynamicMode]];
}

- (void) processVerboseChanged:(NSNotification *)aNote
{
    [processVerbose setState:[model verbose]];
}

- (void) postDataToDBChanged:(NSNotification*)aNote
{
    BOOL postData = [model postDataToDB];
    [postDataToDBButton setState:postData];
    [postDatabaseNameText setEnabled:postData];
    [postDatabaseDesignDocText setEnabled:postData];
    [postDatabaseDesignUpdateText setEnabled:postData];
    [postDatabasePeriodText setEnabled:postData];

}

- (void) postToPathChanged:(NSNotification*)aNote
{
    NSString* updatePath = [model postToPath];
    if ([updatePath length] == 0) {
        [postDatabaseDesignDocText setStringValue:@""];
        [postDatabaseDesignUpdateText setStringValue:@""];
        [postDatabaseNameText setStringValue:@""];
    } else {
        NSArray* components = [updatePath componentsSeparatedByString:@"/"];
        NSUInteger count = [components count];
        if (count != 1 && count != 5) return;
        [postDatabaseNameText setStringValue:[components objectAtIndex:0]];
        if (count > 1) {
            [postDatabaseDesignDocText setStringValue:[components objectAtIndex:2]];
            [postDatabaseDesignUpdateText setStringValue:[components objectAtIndex:4]];
        }
    }
}

- (void) postToDBPeriodChanged:(NSNotification *)aNote
{
    [postDatabasePeriodText setFloatValue:[model postDataToDBPeriod]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self populateListADCs];
    [self _buildPopUpButtons];
    [self modelADCListChanged:nil];
    [self channelMapChanged:nil];
    [self sensitivityMapChanged:nil];
    [self sensorInfoChanged:nil];
    //[self documentLockChanged:nil];
	[self viewChanged:nil];
	[self runRateChanged:nil];
    [self proportionalTermChanged:nil];
    [self integralTermChanged:nil];
    [self feedbackThresholdChanged:nil];
    [self regularizationParameterChanged:nil];
    [self runCommentChanged:nil];
	[self runStatusChanged:nil];
    [self debugRunningChanged:nil];
    [self dynamicModeChanged:nil];
    [self processVerboseChanged:nil];
    [self postToPathChanged:nil];
    [self postDataToDBChanged:nil];
    [self realProcessFrequencyChanged:nil];
    [self postToDBPeriodChanged:nil];
    [groupView setNeedsDisplay:YES];
}

- (void) documentLockChanged:(NSNotification*)aNotification
{
    if([gSecurity isLocked:ORDocumentLock]) [lockDocField setStringValue:@"Document is locked."];
    else if([gOrcaGlobals runInProgress])   [lockDocField setStringValue:@"Run In Progress"];
    else				    [lockDocField setStringValue:@""];
}

- (void) modelADCListChanged:(NSNotification*)aNote
{
    [listOfRegisteredADCs reloadData];
    [self populateListADCs];
}

- (void) channelMapChanged:(NSNotification*)aNote
{
    // Make sure the buttons have the correct titles
    if ([model orientationMatrix] == nil) {
        [orientationMatrixButton setTitle:@"Load Orientation Matrix"];
    } else {
        [orientationMatrixButton setTitle:@"Reset Orientation Matrix"];
    }
    if ([model magnetometerMap] == nil) {
        [magnetometerMapButton setTitle:@"Load Magn. Channel Map"];
    } else {
        [magnetometerMapButton setTitle:@"Reset Magn. Channel Map"];
    }

    
    [hardwareMap reloadData];
    [feedbackMatrix reloadData];
    [orientationMatrix reloadData];
}

- (void) sensitivityMapChanged:(NSNotification*)aNote
{
    // Make sure the buttons have the correct titles
    if ([model sensitivityMatData] == nil) {
        [sensitivityMapButton setTitle:@"Load Sensitivity Map"];
    } else {
        [sensitivityMapButton setTitle:@"Reset Sensitivity Map"];
    }
    if ([model activeChannelMap] == nil) {
        [activeChannelMapButton setTitle:@"Load Active Ch Map"];
    } else {
        [activeChannelMapButton setTitle:@"Reset Active Ch Map"];
    }
    
    [sensitivityMatrix reloadData];
    [activeChannelMap reloadData];
}

- (void) sensorInfoChanged:(NSNotification*)aNote
{
    //Make sure the buttons have the correct title
    if ([model sensorInfo] == nil || [model sensorDirectInfo] == nil) {
        [loadSensorInformationButton setTitle:@"Load Sensorinformation"];
    } else {
        [loadSensorInformationButton setTitle:@"Reset Sensorinformation"];
    }
    [sensorInfo reloadData];
    [sensorDirectInfo reloadData];
}

#pragma mark •••Table View protocol


- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSUInteger nChannel = [model numberOfChannels];
    NSUInteger nCoil = [model numberOfCoils];
    if (aTableView == listOfRegisteredADCs) return [[model listOfADCs] count];
    if (aTableView == hardwareMap) return [[model magnetometerMap] count];
    if (aTableView == activeChannelMap) return [[model activeChannelMap] count];
    if (aTableView == sensorInfo) return [[model sensorInfo] count];
    if (aTableView == orientationMatrix) return [[model orientationMatrix] count];
    if (aTableView == currentValues) return [model coilChannels];
    if (aTableView == fieldValues || aTableView == targetFieldValues) return nChannel;
    if (aTableView == currentValues || aTableView == startCurrentValues) return nCoil;
    if (aTableView == feedbackMatrix) {
        if ([aTableView numberOfColumns] != nChannel) {
            while ([aTableView numberOfColumns] > nChannel &&
                   [aTableView numberOfColumns] > 1) {
                
                [aTableView removeTableColumn:[[aTableView tableColumns] objectAtIndex:[aTableView numberOfColumns]-1]];
            }
            NSTableColumn* firstColumn = [[aTableView tableColumns] objectAtIndex:0];
            [firstColumn setIdentifier:@"0"];
            [[[firstColumn dataCell] formatter] setMaximumFractionDigits:3];
            while ([aTableView numberOfColumns] < nChannel) {
                NSTableColumn* newColumn = [[NSTableColumn alloc]
                                            initWithIdentifier:[NSString stringWithFormat:@"%d",(int)[aTableView numberOfColumns]]];
                [newColumn setWidth:[firstColumn width]];
                [newColumn setDataCell:[firstColumn dataCell]];
                [[newColumn headerCell] setStringValue:[newColumn identifier]];
                [aTableView addTableColumn:newColumn];
                [newColumn release]; //fix memory leak. MAH 11/29/13
            }
        }
        return nCoil;
    }
    if (aTableView == sensitivityMatrix) {
        if ([aTableView numberOfColumns] != nCoil) {
            while ([aTableView numberOfColumns] > nCoil &&
                   [aTableView numberOfColumns] > 1) {
                
                [aTableView removeTableColumn:[[aTableView tableColumns] objectAtIndex:[aTableView numberOfColumns]-1]];
            }
            NSTableColumn* firstColumn = [[aTableView tableColumns] objectAtIndex:0];
            [firstColumn setIdentifier:@"0"];
            [[[firstColumn dataCell] formatter] setMaximumFractionDigits:3];
            while ([aTableView numberOfColumns] < nCoil) {
                NSTableColumn* newColumn = [[NSTableColumn alloc]
                                            initWithIdentifier:[NSString stringWithFormat:@"%d",(int)[aTableView numberOfColumns]]];
                [newColumn setWidth:[firstColumn width]];
                [newColumn setDataCell:[firstColumn dataCell]];
                [[newColumn headerCell] setStringValue:[newColumn identifier]];
                [aTableView addTableColumn:newColumn];
                [newColumn release]; //fix memory leak. MAH 11/29/13
            }
        }
        return nChannel;
    }
//    if (aTableView == sensorInfo) {
//        if ([aTableView numberOfColumns] != [[[model sensorInfo] objectAtIndex:0] count]) {
//            while ([aTableView numberOfColumns] > [[[model sensorInfo] objectAtIndex:0] count] &&
//                   [aTableView numberOfColumns] > 1) {
//
//                [aTableView removeTableColumn:[[aTableView tableColumns] objectAtIndex:[aTableView numberOfColumns]-1]];
//            }
//            NSTableColumn* firstColumn = [[aTableView tableColumns] objectAtIndex:0];
//            [firstColumn setIdentifier:@"0"];
//            [[[firstColumn dataCell] formatter] setMaximumFractionDigits:3];
//            while ([aTableView numberOfColumns] < [[[model sensorInfo] objectAtIndex:0] count]) {
//                NSTableColumn* newColumn = [[NSTableColumn alloc]
//                                            initWithIdentifier:[NSString stringWithFormat:@"%d",[aTableView numberOfColumns]]];
//                [newColumn setWidth:[firstColumn width]];
//                [newColumn setDataCell:[firstColumn dataCell]];
//                [[newColumn headerCell] setStringValue:[newColumn identifier]];
//                [aTableView addTableColumn:newColumn];
//                [newColumn release]; //fix memory leak. MAH 11/29/13
//            }
//        }
//        return [[model sensorInfo] count];
//    }
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if (aTableView == listOfRegisteredADCs) return [[[model listOfADCs] objectAtIndex:rowIndex] processingTitle];
    if (aTableView == hardwareMap) {
        NSString* ident = [aTableColumn identifier];
        if ([ident isEqualToString:@"kSegmentNumber"]) return [NSNumber numberWithInteger:rowIndex];
        if ([ident isEqualToString:@"kCardSlot"]) return [NSNumber numberWithInteger:rowIndex];
        if ([ident isEqualToString:@"kChannel"]) return [NSNumber numberWithInteger:[model mappedChannelAtChannel:(int)rowIndex]];
    }
    if (aTableView == orientationMatrix) {
        NSString* ident = [aTableColumn identifier];        
        if ([ident isEqualToString:@"kChannel"]) return [NSNumber numberWithInteger:rowIndex];
        if ([ident isEqualToString:@"kOrientation"]) return [[model orientationMatrix] objectAtIndex:rowIndex];
    }
    if (aTableView == feedbackMatrix) {
        return [NSNumber numberWithDouble:[model conversionMatrix:[[aTableColumn identifier] intValue] coil:(int)rowIndex]];
    }
    if (aTableView == currentValues) {
        NSString* ident = [aTableColumn identifier];
        if ([ident isEqualToString:@"kChannel"]) return [NSNumber numberWithInteger:(int)rowIndex];
        if ([ident isEqualToString:@"kValues"]) return [NSNumber numberWithFloat:[model getCurrent:(int)rowIndex]];
    }
    if (aTableView == fieldValues) {
        NSString* ident = [aTableColumn identifier];
        if ([ident isEqualToString:@"kChannel"]) return [NSNumber numberWithInteger:rowIndex];
        if ([ident isEqualToString:@"kValues"]) return [NSNumber numberWithFloat:[model fieldAtMagnetometer:(int)rowIndex]];
    }
    if (aTableView == targetFieldValues) {
        NSString* ident = [aTableColumn identifier];
        if ([ident isEqualToString:@"kChannel"]) return [NSNumber numberWithInteger:rowIndex];
        if ([ident isEqualToString:@"kValues"]) return [NSNumber numberWithFloat:[model targetFieldAtMagnetometer:(int)rowIndex]];
    }
    if (aTableView == startCurrentValues) {
        NSString* ident = [aTableColumn identifier];
        if ([ident isEqualToString:@"kChannel"]) return [NSNumber numberWithInteger:rowIndex];
        if ([ident isEqualToString:@"kValues"]) return [NSNumber numberWithFloat:[model startCurrentAtCoil:(int)rowIndex]];
    }
    if (aTableView == sensitivityMatrix) {
        return [NSNumber numberWithDouble:[model sensitivityMatrix:[[aTableColumn identifier] intValue] channel:(int)rowIndex]];
    }
    if (aTableView == activeChannelMap) {
        NSString* ident = [aTableColumn identifier];
        if ([ident isEqualToString:@"kChannel"]) return [NSNumber numberWithInteger:rowIndex];
        if ([ident isEqualToString:@"kScaling"]) return [NSNumber numberWithFloat:[model activeChannelAtChannel:(int)rowIndex]];
    }
    if (aTableView == sensorInfo) {
        NSString* ident = [aTableColumn identifier];
        if ([ident isEqualToString:@"kChannel"])return [NSNumber numberWithInteger:rowIndex];
        if ([ident isEqualToString:@"kx (m)"]) return [NSNumber numberWithFloat:[model xPositionAtChannel:(int)rowIndex]];
        if ([ident isEqualToString:@"ky (m)"]) return [NSNumber numberWithFloat:[model yPositionAtChannel:(int)rowIndex]];
        if ([ident isEqualToString:@"kz (m)"]) return [NSNumber numberWithFloat:[model zPositionAtChannel:(int)rowIndex]];
        if ([ident isEqualToString:@"kField Direction"]) return [NSString stringWithString:[model fieldDirectionAtChannel:(int)rowIndex]];
    }
    
    return @"";
}

- (void) tableViewSelectionDidChange:(NSNotification*)aNotification
{
    if ([listOfRegisteredADCs numberOfSelectedRows] == 0){
        [deleteADCButton setEnabled:NO];
    } else {
        [deleteADCButton setEnabled:YES];
    }
}

- (void) realProcessFrequencyChanged:(NSNotification *)aNote
{
    NSTimeInterval atime = [model realProcessingTime];
    if (atime == 0.0) {
        [realProcessFrequencyField setStringValue:[NSString stringWithFormat:@"%.1f Hz",0.0]];
    } else {
        [realProcessFrequencyField setStringValue:[NSString stringWithFormat:@"%.1f Hz",1./atime]];
    }
}

- (void) targetFieldChanged:(NSNotification*)aNote
{
    [targetFieldValues reloadData];
}

- (void) startCurrentChanged:(NSNotification*)aNote
{
    [startCurrentValues reloadData];
}

#pragma mark •••Accessors
- (ORGroupView *)groupView
{
    return groupView;
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [groupView setGroup:(ORGroup*)model];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];

}

-(void) groupChanged:(NSNotification*)note
{
	if(note == nil || [note object] == model || [[note object] guardian] == model){
		[model setUpImage];
		[self updateWindow];
	}
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	return [groupView validateMenuItem:menuItem];
}

#pragma mark •••Interface Management
- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) objectsAdded:(NSNotification*)aNote
{
    [self populateListADCs];
    [self _buildPopUpButtons];
}

- (void) populateListADCs
{
    [listOfAdcs removeAllItems];
    [listOfAdcs addItemWithTitle:@"Not Used"];
    NSArray* validObjs = [model validObjects];    
    id obj, obj1;
    NSEnumerator* e = [validObjs objectEnumerator];
    while(obj = [e nextObject]){
        NSEnumerator* alreadyIn = [[model listOfADCs] objectEnumerator];        
        BOOL objectExists = NO;
        while(obj1 = [alreadyIn nextObject]){        
            if ([[obj1 processingTitle] isEqualToString:[obj processingTitle]]) {
                objectExists = YES;
                break;
            }
        }
        if (!objectExists) [listOfAdcs addItemWithTitle:[obj processingTitle]];
    }
    [self handleToBeAddedADC:nil];

}

- (void) isNowKeyWindow:(NSNotification*)aNotification
{
	[[self window] makeFirstResponder:(NSResponder*)groupView];
}

- (void) refreshIPAddressesDone:(NSNotification*)aNote
{
    [refreshIPsButton setEnabled:YES];
    [refreshIPIndicate stopAnimation:self];
}

- (void) runAction:(id)sender
{
    [sender setEnabled:NO];
    [model toggleRunState];
}

- (void) runRateAction:(id)sender
{
    [model setPollingFrequency:[sender floatValue]];
}

- (void) proportionalTermAction:(id)sender
{
    [model setProportionalTerm:[sender floatValue]];
}

- (void) integralTermAction:(id)sender
{
    [model setIntegralTerm:[sender floatValue]];
}

- (void) feedbackThresholdAction:(id)sender
{
    [model setFeedbackThreshold:[sender floatValue]];
}

- (void) regularizationParameterAction:(id)sender
{
    [model setRegularizationParameter:[sender floatValue]];
}

- (void) runCommentAction:(id)sender
{
    [model setRunComment:[runCommentField stringValue]];
}

- (void) addADCAction:(id)sender
{
    NSString* adcName = [[listOfAdcs selectedItem] title];
    NSArray* validObjs = [model validObjects];    
    id obj;
    NSEnumerator* e = [validObjs objectEnumerator];
    while(obj = [e nextObject]){
        if ([adcName isEqualToString:[obj processingTitle]]) {
            [model addADC:obj];
            break;
        }
    }    
    
}

- (IBAction) refreshIPsAction:(id)sender
{
    [sender setEnabled:NO];
    [refreshIPIndicate startAnimation:self];
    [[ORVXI11HardwareFinder sharedVXI11HardwareFinder] refresh];
}

- (void) _readFile:(id)sender withSelector:(SEL)asel withMessage:(NSString*)message
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"plist",nil]];    
    [openPanel setPrompt:@"Choose"];
    [openPanel setMessage:message];
    
    NSString* startingDir = (startingDirectory!=nil) ? startingDirectory: NSHomeDirectory();
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model performSelector:asel withObject:[[openPanel URL] path]];
            // Also reset the starting directory if this was successful
            [startingDirectory release];
            startingDirectory = [[[[openPanel URL] path] stringByDeletingLastPathComponent] retain];
        }
    }];
    
}

- (void) _saveFile:(id)sender withSelector:(SEL)asel withMessage:(NSString*)message
{
    NSSavePanel *openPanel = [NSSavePanel savePanel];
    [openPanel setPrompt:@"Save"];
    [openPanel setMessage:message];
    [openPanel setAllowsOtherFileTypes:NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"plist",nil]];
    
    NSString* startingDir = (startingDirectory!=nil) ? startingDirectory: NSHomeDirectory();
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model performSelector:asel withObject:[[openPanel URL] path]];
            // Also reset the starting directory if this was successful
            [startingDirectory release];
            startingDirectory = [[[[openPanel URL] path] stringByDeletingLastPathComponent] retain];
        }
    }];    
}

- (IBAction)saveFeedbackMatrixAction:(id)sender{
    [self _saveFile:sender
       withSelector:@selector(saveFeedbackInPlistFile:)
        withMessage:@"Save Current Fields As"];
}

// import sensitivity matrix
- (IBAction) loadSensitivityMatrixAction:(id)sender
{
    if ([model sensitivityMatData] == nil) {
        [self _readFile:sender
           withSelector:@selector(initializeSensitivityMatrixWithPlistFile:)
            withMessage:@"Choose Sensitivity Matrix File"];
    } else [model resetSensitivityMatrix];
}

// import magnetometer channel map
- (IBAction) readPrimaryMagnetometerMapFileAction:(id)sender
{
    if ([model magnetometerMap] == nil) {
        [self _readFile:sender
           withSelector:@selector(initializeMagnetometerMapWithPlistFile:)
            withMessage:@"Choose Magnetometer Map File"];
    } else [model resetMagnetometerMap];
        
}

// import active channel map
- (IBAction) loadAcitveChannelMapAction:(id)sender
{
    if ([model activeChannelMap] == nil) {
        [self _readFile:sender
           withSelector:@selector(initializeActiveChannelMapWithPlistFile:)
            withMessage:@"Choose ActiveChannel Map File"];
    } else [model resetActiveChannelMap];
    
}

// build new Feedback Matrix
- (IBAction) buildNewFeedbackMatrixAction:(id)sender{
    // here would be a new thread useful
    [model buildFeedback];
}

// import Sensor Info Map
- (IBAction)loadSensorInformationAction:(id)sender
{
    if ([model sensorInfo] == nil){
        [self _readFile:sender
           withSelector:@selector(initializeSensorInfoWithPlistFile:)
            withMessage:@"Choose SensorInfo File"];
    } else [model resetSensorInfo];
}

// import magnetometer orientation map
- (IBAction) readPrimaryOrientationMatrixFileAction:(id)sender
{
    if ([model orientationMatrix] == nil) {
        [self _readFile:sender
           withSelector:@selector(initializeOrientationMatrixWithPlistFile:)
            withMessage:@"Choose Orientation Matrix File"];
    } else [model resetOrientationMatrix];
}

- (IBAction) sendCommandAction:(id)sender
{
    [self endEditing];
    int cmd = (int)[[commandPopUp selectedItem] tag];
    int output = (int)[[outputNumberPopUp selectedItem] tag];
    float input = [inputValueText floatValue];
    NSEnumerator* anEnum = [[self groupView] objectEnumerator];
    for (id aPowerSupply in anEnum) {    
        [aPowerSupply writeCommand:cmd withInput:input withOutputNumber:output];
    }
    //[sendCommandButton setEnabled:NO];
}

- (IBAction) debugCommandAction:(id)sender
{
    [model setDebugRunning:[debugModeButton state]];
}

- (IBAction) dynamicModeCommandAction:(id)sender
{
    [model setDynamicMode:[dynamicModeButton state]];

}

- (IBAction) connectAllAction:(id)sender
{
    [model connectAllPowerSupplies];
}

- (IBAction) removeSelectedADCs:(id)sender
{
    NSArray* objsToRemove = [[model listOfADCs] objectsAtIndexes:[listOfRegisteredADCs selectedRowIndexes]];
    for (id obj in objsToRemove) [model removeADC:obj];
    
}

- (IBAction) handleToBeAddedADC:(id)sender
{
    NSInteger index = [listOfAdcs indexOfSelectedItem];
    if (index == 0 || index == -1){
        [addADCButton setEnabled:NO];
    } else {
        [addADCButton setEnabled:YES];
    }
}

- (IBAction) processVerboseAction:(id)sender
{
    [model setVerbose:[processVerbose state]];
}

- (IBAction) postDataToDBAction:(id)sender
{
    [model setPostDataToDB:[sender state]];
}

- (IBAction) postToPathAction:(id)sender
{
    NSString* dbname = [postDatabaseNameText stringValue];
    NSString* designdoc = [postDatabaseDesignDocText stringValue];
    NSString* updatename = [postDatabaseDesignUpdateText stringValue];
    if ([dbname length] == 0) {
        [model setPostToPath:nil];
    } else
    {
        if ([updatename length] != 0 && [designdoc length] != 0) {
            dbname = [dbname stringByAppendingFormat:@"/_design/%@/_update/%@",designdoc,updatename];
        }
        [model setPostToPath:dbname];
    }
}

- (IBAction) refreshCurrentAndFieldValuesAction:(id)sender
{
    [currentValues reloadData];
    [fieldValues reloadData];
}

- (IBAction) loadTargetFieldValuesAction:(id)sender
{
    [self _readFile:sender
       withSelector:@selector(loadTargetFieldWithPlistFile:)
        withMessage:@"Choose Target Field File"];
}
- (IBAction) saveCurrentFieldAsTargetFieldAction:(id)sender
{
    [self _saveFile:sender
       withSelector:@selector(saveCurrentFieldInPlistFile:)
        withMessage:@"Save Current Fields As"];
}

- (IBAction) setTargetFieldAction:(id)sender
{
    [model setTargetField];
}

- (IBAction) setTargetFieldToZeroAction:(id)sender
{
    [model setTargetFieldToZero];
}

- (IBAction) loadStartCurrentValuesAction:(id)sender
{
    [self _readFile:sender
       withSelector:@selector(loadStartCurrentWithPlistFile:)
        withMessage:@"Choose Start Current File"];
}
- (IBAction) saveCurrentStartCurrentAsStartCurrentAction:(id)sender
{
    [self _saveFile:sender
       withSelector:@selector(saveCurrentStartCurrentInPlistFile:)
        withMessage:@"Save Current Start Current As"];
}

- (IBAction) setStartCurrentToZeroAction:(id)sender
{
    [model setStartCurrentToZero];
}


- (IBAction) postToDBPeriodAction:(id)sender
{
    [model setPostDataToDBPeriod:[sender floatValue]];
}

- (IBAction)SaveFeedbackAction:(id)sender
{
    [self _saveFile:sender
       withSelector:@selector(saveFeedbackInPlistFile:)
        withMessage:@"Save new Feedback Matrix as"];
}

//---------------------------------------------------------------
//these last actions are here only to work around a strange 
//first responder problem that occurs after cut followed by undo
//- (IBAction)delete:(id)sender   { [groupView delete:sender]; }
//- (IBAction)cut:(id)sender      { [groupView cut:sender]; }
//- (IBAction)paste:(id)sender    { [groupView paste:sender]; }
//- (IBAction)selectAll:(id)sender{ [groupView selectAll:sender]; }
//-----------------------------------------------------------------

- (void) _buildPopUpButtons
{
    
    if ([[[self groupView] group] count] == 0) {
        [commandPopUp removeAllItems];            
        return;
    }
    id aPowerSupply = [[[self groupView] group] objectAtIndex:0];
    if ([commandPopUp numberOfItems] == [aPowerSupply numberOfCommands]) return;
    [commandPopUp removeAllItems];            
    int i;
    for (i=0; i<[aPowerSupply numberOfCommands]; i++) {
        [commandPopUp addItemWithTitle:[aPowerSupply commandName:i]];
        [[commandPopUp itemAtIndex:i] setTag:i];
    }    
    // Get out of the iteration, we just need to do this during the first iteration
    return;

}

@end
