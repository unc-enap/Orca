
//
//  ORProcessController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
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
#import "ORProcessController.h"
#import "ORProcessModel.h"
#import "ORProcessOutConnector.h"
#import "ORProcessElementModel.h"
#import "ORProcessCenter.h"

NSInteger sortUpFunction(id element1,id element2, void* context){ return [element1 compareStringTo:element2 usingKey:context];}
NSInteger sortDnFunction(id element1,id element2, void* context){return [element2 compareStringTo:element1 usingKey:context];}

@implementation ORProcessController

#pragma mark ¥¥¥Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"Process"];
    return self;
}

- (void) dealloc
{
	[ascendingSortingImage release];
	[descendingSortingImage release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

-(void) awakeFromNib
{
    [super awakeFromNib];
    
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"orca.Process%u.selectedtab",[model uniqueIdNumber]]];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];	
    [tableView setDoubleAction:@selector(doubleClick:)];
    
    ascendingSortingImage  = [[NSImage imageNamed:@"NSAscendingSortIndicator"] retain];
    descendingSortingImage = [[NSImage imageNamed:@"NSDescendingSortIndicator"] retain];
	
	[tableView setAutosaveTableColumns:YES];
	[tableView setAutosaveName:@"ORProcessControllerTableView"];    
    scheduledForUpdate = NO;
}

#pragma mark ¥¥¥Interface Management

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    [notifyCenter addObserver : self
                     selector : @selector(elementStateChanged:)
                         name : ORProcessElementStateChangedNotification
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(doUpdate:)
                         name : ORProcessElementForceUpdateNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(testModeChanged:)
                         name : ORProcessTestModeChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(processRunningChanged:)
                         name : ORProcessTestModeChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(processRunningChanged:)
                         name : ORProcessRunningChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(commentChanged:)
                         name : ORProcessCommentChangedNotification
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(shortNameChanged:)
                         name : ORProcessModelShortNameChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(detailsChanged:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : tableView];
    
    [notifyCenter addObserver : self
                     selector : @selector(sampleRateChanged:)
                         name : ORProcessModelSampleRateChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(useAltViewChanged:)
                         name : ORProcessModelUseAltViewChanged
						object: model];	

	[notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsAdded
						object: nil];	
	
    [notifyCenter addObserver : self
                     selector : @selector(keepHistoryChanged:)
                         name : ORProcessModelKeepHistoryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(historyFileChanged:)
                         name : ORProcessModelHistoryFileChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(emailListChanged:)
                         name : ORProcessModelEmailListChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(heartBeatIndexChanged:)
                         name : ORProcessModelHeartBeatIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sendOnStartChanged:)
                         name : ORProcessModelSendOnStartChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sendOnStopChanged:)
                         name : ORProcessModelSendOnStopChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(nextHeartBeatChanged:)
                         name : ORProcessModelNextHeartBeatChanged
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(processRunNumberChanged:)
                         name : ORProcessModelRunNumberChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(masterProcessChanged:)
                         name : ORProcessModelMasterProcessChanged
						object: nil];

}

- (void) updateWindow
{
    [super updateWindow];
    [self testModeChanged:nil];
    [self shortNameChanged:nil];
    [self detailsChanged:nil];
    [self processRunningChanged:nil];
	[self sampleRateChanged:nil];
	[self useAltViewChanged:nil];
	[self keepHistoryChanged:nil];
	[self historyFileChanged:nil];
	[self emailListChanged:nil];
	[self heartBeatIndexChanged:nil];
	[self sendOnStartChanged:nil];
	[self sendOnStopChanged:nil];
	[self nextHeartBeatChanged:nil];
	[self processRunNumberChanged:nil];
	[self masterProcessChanged:nil];
}

- (void) masterProcessChanged:(NSNotification*)aNote
{
	[masterProcessCB setIntValue: [model masterProcess]];
    [model setUpImage];
    [self updateButtons];
}

- (void) sendOnStopChanged:(NSNotification*)aNote
{
	[sendOnStopCB setIntValue: [model sendOnStop]];
}

- (void) sendOnStartChanged:(NSNotification*)aNote
{
	[sendOnStartCB setIntValue: [model sendOnStart]];
}

- (void) heartBeatIndexChanged:(NSNotification*)aNote
{
	[heartBeatIndexPU selectItemAtIndex: [model heartBeatIndex]];
	[self setHeartbeatImage];
}

- (void) emailListChanged:(NSNotification*)aNote
{
	[emailListTable reloadData];
}

- (void) historyFileChanged:(NSNotification*)aNote
{
	[historyFileTextField setStringValue: [[model historyFile] stringByAbbreviatingWithTildeInPath]];
}

- (void) keepHistoryChanged:(NSNotification*)aNote
{
	[keepHistoryCB setIntValue: [model keepHistory]];
}

- (void) sampleRateChanged:(NSNotification*)aNote
{
	[sampleRateField setFloatValue: [model sampleRate]];
	[self updatePollingButton];
}

- (void) processRunNumberChanged:(NSNotification*)aNote
{
    [processRunNumberField setIntValue:[model processRunNumber]];
}

- (void) setHeartbeatImage
{
	if([model heartBeatIndex] == 0){
		NSImage* noHeartbeatImage = [NSImage imageNamed:@"noHeartbeat"];
		[heartbeatImage setImage:noHeartbeatImage];
	}
	else [heartbeatImage setImage:nil];
}

- (void) nextHeartBeatChanged:(NSNotification*)aNote
{
    id theObj = [aNote object];
    if(!aNote) theObj = model;
    if(theObj == model || [theObj masterProcess]){
        if([theObj heartbeatSeconds]){
            [nextHeartbeatField setStringValue:[NSString stringWithFormat:@"Next Heartbeat: %@",[theObj nextHeartbeat]]];
        }
        else [nextHeartbeatField setStringValue:@"No Heartbeat Scheduled"];
    }
}

- (void) useAltViewChanged:(NSNotification*)aNote
{
	[altViewButton setTitle:[model useAltView]?@"Edit Connections":@"Show Displays Only"];
	[groupView setNeedsDisplay:YES];
}

- (void) objectsChanged:(NSNotification*)aNote
{
	//just set the same value to force a reset of the value to all objects
	[model setUseAltView:[model useAltView]];
	//we also have to assign a processID number -- different than the uniqueID number
	[model setProcessIDs];
}

- (void) commentChanged:(NSNotification*)aNote
{
    [tableView reloadData];
}

- (void) processRunningChanged:(NSNotification*)aNote
{
	if([model processRunning]){
		[startButton setTitle:@"Stop"];
		if([model inTestMode])[statusTextField setStringValue:@"Testing This Process"];
		else [statusTextField setStringValue:@"Running This Process"];
	}
	else {
		[startButton setTitle:@"Start"];
		[statusTextField setStringValue:@"Process is Idle"];
	}
	[self updatePollingButton];
}

- (void) updatePollingButton
{
	if([model processRunning]){
		float timeBetweenSamples = 1./[model sampleRate];
		if(timeBetweenSamples>15){
			[pollNowButton setEnabled:YES];
		}
		else {
			[pollNowButton setEnabled:NO];
		}
	}
	else {
		[pollNowButton setEnabled:NO];
	}
}

- (void) testModeChanged:(NSNotification*)aNote
{
	[testModeButton setState:[model inTestMode]];
}


- (void) elementStateChanged:(NSNotification*)aNote
{
    if([[model orcaObjects] containsObject:[aNote object]]){
		if(!scheduledForUpdate){
			scheduledForUpdate = YES;
			[self performSelector:@selector(doUpdate:) withObject:aNote afterDelay:.2];
		}
	}
}

- (void) doUpdate:(NSNotification*)aNote
{
	scheduledForUpdate = NO;
	//NSRect objRect = [[aNote object] frame];
	//add in all the bounds of the lines
	//for(id aConnector in [[aNote object] connectors]){
	//	if([aConnector connector]) objRect = NSUnionRect(objRect,[aConnector lineBounds]);
	//}
	[groupView setNeedsDisplay:YES];
	[tableView reloadData];
}

- (void) updateButtons
{
    NSArray* processes = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:[model class]];
    BOOL aDiffMasterExists = NO;
	BOOL anyAddresses = ([[model emailList] count]>0);
    for(id aProcess in processes){
        if(aProcess ==model)continue;
        if([aProcess masterProcess]){
            aDiffMasterExists = YES;
            anyAddresses = ([[aProcess emailList] count]>0);
            break;
        }
    }
    
    NSInteger selectedIndex = [emailListTable selectedRow];

    [emailListTable      setHidden:  aDiffMasterExists];
	[addAddressButton    setEnabled:!aDiffMasterExists];
	[removeAddressButton setEnabled:!aDiffMasterExists && (selectedIndex>=0)];
	[heartBeatIndexPU    setEnabled:anyAddresses && !aDiffMasterExists];
	[sendOnStopCB        setEnabled:anyAddresses];
	[sendOnStartCB       setEnabled:anyAddresses];
    
    NSString* s;
    if([model masterProcess])  s = @"Master EMail List";
    else if(aDiffMasterExists) s = @"Master EMail List will be used!";
    else                       s = @"Multiple EMail lists!";
    [masterInfoField setStringValue:s];

}

- (void) detailsChanged:(NSNotification*)aNote
{
    if([aNote object] == tableView){
        NSString* theDetails = @"";
        
        NSIndexSet* theSelectedSet =  [tableView selectedRowIndexes];
        if(theSelectedSet){
            NSInteger rowIndex = [theSelectedSet firstIndex];
            id item = [[model orcaObjects]objectAtIndex:rowIndex];
            theDetails = [NSString stringWithFormat:@"%@",[item description:@""]];
        }
        [detailsTextView setString:theDetails];
    }
}

- (void) shortNameChanged:(NSNotification*)aNote
{
	[shortNameField setStringValue:[model shortName]];
    [tableView reloadData];
}


#pragma mark ¥¥¥Actions

- (void) masterProcessAction:(id)sender
{
	[model setMasterProcess:[sender intValue]];
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
		[model removeAddressAtIndex:(int)current_index];
	}
	[self updateButtons];
	[emailListTable reloadData];
}

- (IBAction) sendOnStopAction:(id)sender
{
	[model setSendOnStop:[sender intValue]];	
}

- (IBAction) sendOnStartAction:(id)sender
{
	[model setSendOnStart:[sender intValue]];	
}

- (IBAction) heartBeatIndexAction:(id)sender
{
    if([sender indexOfSelectedItem] != [model heartBeatIndex]){
        [model setHeartBeatIndex:(int)[sender indexOfSelectedItem]];
        if([model heartbeatSeconds] == 0){
            [model sendHeartbeatShutOffWarning];
        }
    }
}

- (IBAction) historyFileSelectionAction:(id)sender;
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[model historyFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"Untitled";
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [self endEditing];
            [model setHistoryFile:[[savePanel URL]path]];
        }
    }];
}

- (IBAction) keepHistoryAction:(id)sender
{
	[model setKeepHistory:[sender intValue]];	
}

- (IBAction) viewProcessCenter:(id)sender
{
    [[[ORProcessCenter sharedProcessCenter] window] orderFront:nil];
}

- (IBAction) useAltViewAction:(id)sender
{
	[model setUseAltView:![model useAltView]];
}

- (IBAction) sampleRateAction:(id)sender
{
	[model setSampleRate:[sender floatValue]];	
}

- (IBAction) startProcess:(id)sender
{
	[[self window] endEditingFor:nil];		
    [model startStopRun];
	[self setDocumentEdited:YES];
	[groupView setNeedsDisplayInRect:[groupView bounds]];
}

- (IBAction) testModeAction:(id)sender
{
    [model setInTestMode:[sender intValue]];
}

- (IBAction) shortNameAction:(id)sender
{
	[model setShortName:[sender stringValue]];
}

- (IBAction) pollNow:(id)sender
{
	[model pollNow];
}

#pragma mark ¥¥¥Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
	if(aTableView == tableView){
		NSParameterAssert(rowIndex >= 0 && rowIndex < [[model orcaObjects] count]);
		NSString* columnID =  [aTableColumn identifier];
		id item = @"--";
		@try {
			item =  [[[model orcaObjects]objectAtIndex:rowIndex] valueForKey:columnID];
		}
		@catch(NSException* localException) {
		}
		return item;
	}
	else {
		if(rowIndex < [[model emailList] count]){
			id addressObj = [[model emailList] objectAtIndex:rowIndex];
			return addressObj; 
		}
		else return @"";
	}
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if(aTableView == tableView){
		NSParameterAssert(rowIndex >= 0 && rowIndex < [[model orcaObjects] count]);
		id item = [[model orcaObjects]objectAtIndex:rowIndex];
		[item setValue:anObject forKey:[aTableColumn identifier]];
	}
	else {
		if(rowIndex < [[model emailList] count]){
			[[model emailList] replaceObjectAtIndex:rowIndex withObject:anObject];
		}
	}
}

// just returns the number of items we have.
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
 	if(aTableView == tableView){
		return [[model orcaObjects] count];
	}
	else {
		return [[model emailList] count];
	}
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    NSInteger index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:[NSString stringWithFormat:@"orca.Process%u.selectedtab",[model uniqueIdNumber]]];
}

- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == emailListTable || aNotification == nil){
		NSInteger selectedIndex = [emailListTable selectedRow];
		[removeAddressButton setEnabled:selectedIndex>=0];
	}
}

- (void) tableView:(NSTableView*)tv didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSImage *sortOrderImage = [tv indicatorImageInTableColumn:tableColumn];
    NSString *columnKey = [tableColumn identifier];
    // If the user clicked the column which already has the sort indicator
    // then just flip the sort order.
    
    if (sortOrderImage || columnKey == [self sortColumn]) {
        [self setSortIsDescending:![self sortIsDescending]];
    }
    else {
        [self setSortColumn:columnKey];
    }
    [self updateTableHeaderToMatchCurrentSort];
    // now do it - doc calls us back when done
    [self sort];
    [tableView reloadData];
}

- (void) updateTableHeaderToMatchCurrentSort
{
    BOOL isDescending = [self sortIsDescending];
    NSString *key = [self sortColumn];
    NSArray *a = [tableView tableColumns];
    NSTableColumn *column = [tableView tableColumnWithIdentifier:key];
    uint32_t i = (uint32_t)[a count];
    
    while (i-- > 0) [tableView setIndicatorImage:nil inTableColumn:[a objectAtIndex:i]];
    
    if (key) {
        [tableView setIndicatorImage:(isDescending ? ascendingSortingImage:descendingSortingImage) inTableColumn:column];
        
        [tableView setHighlightedTableColumn:column];
    }
    else {
        [tableView setHighlightedTableColumn:nil];
    }
}

-(void)setSortColumn:(NSString *)identifier {
    if (![identifier isEqualToString:_sortColumn]) {
        // [[[self undoManager] prepareWithInvocationTarget:self] setSortColumn:_sortColumn];
        [_sortColumn release];
        _sortColumn = [identifier copyWithZone:[self zone]];
        //[[self undoManager] setActionName:@"Column Selection"];
    }
}

- (NSString *)sortColumn
{
    return _sortColumn;
}

- (void)setSortIsDescending:(BOOL)whichWay {
    if (whichWay != _sortIsDescending) {
        //[[[self undoManager] prepareWithInvocationTarget:self] setSortIsDescending:_sortIsDescending];
        _sortIsDescending = whichWay;
        //[[self undoManager] setActionName:@"Sort Direction"];
    }
}

- (BOOL)sortIsDescending
{
    return _sortIsDescending;
}

- (void)sort
{
    if(_sortIsDescending)[[model orcaObjects] sortUsingFunction:sortDnFunction context: _sortColumn];
    else [[model orcaObjects] sortUsingFunction:sortUpFunction context: _sortColumn];
}

- (IBAction) doubleClick:(id)sender
{
    id selectedObj = [[model orcaObjects] objectAtIndex: [tableView selectedRow]];
    [selectedObj doDoubleClick:sender];
}
@end


