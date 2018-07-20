//
//  ORDataExplorerController.m
//  Orca
//
//  Created by Mark Howe on Sun Dec 05 2004.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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
#import "ORDataExplorerController.h"
#import "ORDataExplorerModel.h"
#import "ORHeaderItem.h"
#import "ORDataSet.h"
#import "ORDataPacket.h"
#import "ORTimedTextField.h"

@implementation ORDataExplorerController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"DataExplorer"];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self setScanInProgress:NO];
    [detailsView setFont:[NSFont fontWithName:@"Monaco" size:10]];
    [dataCatalogView setDoubleAction:@selector(doubleClick:)];
    [super awakeFromNib];
}

#pragma mark ¥¥¥Accessors
- (void) setScanInProgress:(BOOL)state
{
    scheduledToUpdate = NO;
    scanInProgress = state;
    if(!scanInProgress){
        [[NSNotificationCenter defaultCenter]
			    postNotificationName:NSTableViewSelectionDidChangeNotification
                              object: dataView
                            userInfo: nil];
    }
    [self updateButtons];
}

#pragma  mark ¥¥¥Actions

- (IBAction) headerOnlyAction:(id)sender
{
	[model setHeaderOnly:[sender intValue]];	
}

- (IBAction) multiCatalogAction:(id)sender
{
	[model setMultiCatalog:[sender intValue]];	
}

- (IBAction) flushButtonAction:(id)sender
{
    [model flushMemory];
    [headerView reloadData];
    [dataView reloadData];
    [dataCatalogView reloadData];
    [detailsView setString:@""];
}

- (IBAction) scanNextButtonAction:(id)sender
{
    int row = (int)[dataView selectedRow];
    if(row != -1){    

        [dataView deselectAll:self];
        NSDictionary* dataDictionary = [model dataRecordAtIndex:row];
        NSString* currentDataName    = [dataDictionary objectForKey:@"Name"];
        currentSearchIndex = row+1;
        stopScan = NO;
        [self performSelector:@selector(scanForNext:) withObject:currentDataName afterDelay:0];
        [self setScanInProgress:YES];

    }
}

- (IBAction) stopScanButtonAction:(id)sender
{
    stopScan = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self setScanInProgress:NO];
}


- (void) scanForNext:(id)currentDataName
{
    uint32_t num = (uint32_t)[[model dataRecords] count];
    if(stopScan || currentSearchIndex>=num){
        [self setScanInProgress:NO];
        return;
    }
    NSDictionary* dataDictionary = [model dataRecordAtIndex:currentSearchIndex];
    [dataView selectRowIndexes:[NSIndexSet indexSetWithIndex:currentSearchIndex] byExtendingSelection:NO];

    NSString* aName = [dataDictionary objectForKey:@"Name"];
    if([currentDataName isEqualToString: aName]){
        [dataView scrollRowToVisible:currentSearchIndex];
        [self setScanInProgress:NO];
    }
    else {
        currentSearchIndex++;
        if(currentSearchIndex<= num+1){
            [self performSelector:@selector(scanForNext:) withObject:currentDataName afterDelay:0];
            if(!(currentSearchIndex % 5000)){
                [dataView scrollRowToVisible:currentSearchIndex];
            }
        }
    }
}

- (IBAction) scanPreviousButtonAction:(id)sender
{
   int row = (int)[dataView selectedRow];
    if(row >= 1){  
        
        [dataView deselectAll:self];
        NSDictionary* dataDictionary = [model dataRecordAtIndex:row];
        NSString* currentDataName    = [dataDictionary objectForKey:@"Name"];
        currentSearchIndex = row-1;
        stopScan = NO;
        [self performSelector:@selector(scanForPrevious:) withObject:currentDataName afterDelay:0];
        [self setScanInProgress:YES];
    }
}

- (void) scanForPrevious:(id)currentDataName
{
    if(stopScan || currentSearchIndex<0){
        [self setScanInProgress:NO];
        return;
    }
    NSDictionary* dataDictionary = [model dataRecordAtIndex:currentSearchIndex];
    [dataView selectRowIndexes:[NSIndexSet indexSetWithIndex:currentSearchIndex] byExtendingSelection:NO];

    NSString* aName = [dataDictionary objectForKey:@"Name"];
    if([currentDataName isEqualToString: aName]){
        [dataView scrollRowToVisible:currentSearchIndex];
        [self setScanInProgress:NO];
    }
    else {
        currentSearchIndex--;
        if(currentSearchIndex>=0){
            [self performSelector:@selector(scanForPrevious:) withObject:currentDataName afterDelay:0];
            if(!(currentSearchIndex % 5000)){
                [dataView scrollRowToVisible:currentSearchIndex];
            }
        }
    }
}

- (IBAction) clearCountsButtonAction:(id)sender
{
    [model clearCounts];
    [dataCatalogView reloadData];
    [dataCatalogView deselectAll:self];
    [detailsView setNeedsDisplay:YES];
    [dataView reloadData];
	[model parseFile];
}

- (IBAction)delete:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction)cut:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction) removeItemAction:(id)sender
{ 
    if([[self window]firstResponder] == dataCatalogView){
        NSArray *selection = [dataCatalogView allSelectedItems];
        NSEnumerator* e = [selection objectEnumerator];
        id item;
        while(item = [e nextObject]){
            [model removeDataSet:item];
        }
        [[model dataSet] recountTotal];
        [dataCatalogView reloadData];
        [dataCatalogView deselectAll:self];
    }
}

- (IBAction) doubleClick:(id)sender
{
    if(sender == dataCatalogView){
        id selectedObj = [dataCatalogView itemAtRow:[dataCatalogView selectedRow]];
        [selectedObj doDoubleClick:sender];
    }
}

- (IBAction) selectFileButtonAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose File"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model fileToExplore]){
        startDir = [[model fileToExplore]stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            [model setFileToExplore:[[openPanel URL] path]];
        }
    }];

}

- (IBAction) parseButtonAction:(id)sender
{
    if([model parseInProgress]){
        [model stopParse];
    }
    else {
        [headerView deselectAll:sender];
        [dataView deselectAll:sender];
        [dataCatalogView deselectAll:sender];
        [[model dataSet] clear];
        [model parseFile];
		[warningField setStringValue:@""];
    }
}

- (IBAction) catalogAllAction:(id)sender
{
    if(![model dataSet])[model createDataSet];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NeedFullDecode" object:self];
	currentSearchIndex = 0;
	stopScan = NO;
    [self setScanInProgress:YES];
	[self performSelector:@selector(catalogAll) withObject:nil afterDelay:0];
}

- (void) catalogAll
{
    uint32_t num = (uint32_t)[[model dataRecords] count];
	if(num >0){
	
		if([model multiCatalog])[model setHistoErrorFlag:YES];

		if(stopScan || currentSearchIndex>=num-1){
			[self setScanInProgress:NO];
			[dataView selectRowIndexes:[NSIndexSet indexSetWithIndex:num-1] byExtendingSelection:NO];
			[dataView scrollRowToVisible:num-1];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DoneWithFullDecode" object:self];
			return;
		}

		NSTimeInterval t0 = [NSDate timeIntervalSinceReferenceDate];
		NSAutoreleasePool *pool = nil;
		while([NSDate timeIntervalSinceReferenceDate]-t0 < .5){
			pool = [[NSAutoreleasePool allocWithZone:nil] init];
			if(currentSearchIndex <= num - 1){
				[self process:currentSearchIndex];
				if(!(currentSearchIndex % 10000)){
					[dataView selectRowIndexes:[NSIndexSet indexSetWithIndex:currentSearchIndex] byExtendingSelection:NO];
					[dataView scrollRowToVisible:currentSearchIndex];
				}
				 ++currentSearchIndex;
			}
			else break;
			[pool release];
			pool = nil;
		}
		[pool release];
		pool = nil;
		[self performSelector:@selector(catalogAll) withObject:nil afterDelay:0];
	}
	else {
		[warningField setStringValue:@"Parse First!"];
		[self setScanInProgress:NO];
	}
}


#pragma mark ¥¥¥Interface Management

- (void) headerOnlyChanged:(NSNotification*)aNote
{
	[headerOnlyCB setIntValue: [model headerOnly]];
}

- (void) multiCatalogChanged:(NSNotification*)aNote
{
	[multiCatalogCB setIntValue: [model multiCatalog]];
	[self updateButtons];
}

- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(fileNameChanged:)
                         name : ORDataExplorerFileChangedNotification
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fileParseStarted:)
                         name : ORDataExplorerParseStartedNotification
                        object: model];
                        
    [notifyCenter addObserver : self
                     selector : @selector(fileParseEnded:)
                         name : ORDataExplorerParseEndedNotification
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dataChanged:)
                         name : ORDataExplorerDataChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                       object : dataView];

    [notifyCenter addObserver : self
                     selector : @selector(multiCatalogChanged:)
                         name : ORDataExplorerModelMultiCatalogChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histoErrorFlagChanged:)
                         name : ORDataExplorerModelHistoErrorFlagChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(headerOnlyChanged:)
                         name : ORDataExplorerModelHeaderOnlyChanged
						object: model];

}

- (void) updateWindow
{
	[super updateWindow];
    [self fileNameChanged:nil];
    [self fileParseEnded:nil];
	[self multiCatalogChanged:nil];
	[self histoErrorFlagChanged:nil];
	[self headerOnlyChanged:nil];
}


- (void) updateButtons
{
    BOOL parsing = [model parseInProgress];
    [parseButton setEnabled:!scanInProgress];    
    [scanNextButton setEnabled:!scanInProgress && !parsing];
    [stopScanButton setEnabled:scanInProgress && !parsing];
    [scanPreviousButton setEnabled:!scanInProgress && !parsing];
    [clearCountsButton setEnabled:!scanInProgress && !parsing];
    [selectFileButton setEnabled:!scanInProgress && !parsing];
    [catalogAllButton setEnabled:!scanInProgress && !parsing];
    [flushButton setEnabled:!scanInProgress && !parsing];
	[multiCatalogCB setEnabled:!scanInProgress && !parsing];
	[multiCatalogWarningField setStringValue:[model histoErrorFlag]?@"Counts and Histograms will be inaccurate!":@""];
}


- (void) histoErrorFlagChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) dataChanged:(NSNotification*)aNotification
{
    if(!scheduledToUpdate){
        [self performSelector:@selector(doUpdate) withObject:nil afterDelay:0.2];
        scheduledToUpdate = YES;
    }
}

- (void) doUpdate
{
    scheduledToUpdate = NO;
    [dataCatalogView reloadData];
}

- (void) fileNameChanged:(NSNotification*)note
{
	[fileNameField setStringValue:[[model fileToExplore] stringByAbbreviatingWithTildeInPath]];
}

- (void) fileParseStarted:(NSNotification*)note
{
    [parseButton setTitle:@"Stop"];
    [self updateButtons];
    [headerView reloadData];
    [dataView reloadData];
    [dataCatalogView reloadData];
    [detailsView setString:@""];
    [parseProgressBar setMaxValue:100];
    [parseProgressBar setDoubleValue:0];
    [parseProgressBar startAnimation:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateProgress) object:nil];
    [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.2];
}

- (void) updateProgress
{
    double total = [model totalLength];
    double current = [model lengthDecoded];
    
    if(total>0)[parseProgressBar setDoubleValue:100. - (100.*current/(double)total)];
    [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.1];
}

- (void) fileParseEnded:(NSNotification*)note
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateProgress) object:nil];
    [parseProgressBar setDoubleValue:0.0];
    [parseProgressBar stopAnimation:self];
    [headerView reloadData];
    [dataView reloadData];
    [dataCatalogView reloadData];
    [self updateButtons];
    [parseButton setTitle:@"Parse"];
}


#pragma mark ¥¥¥Data Source Methods
- (NSUInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(outlineView == dataCatalogView){
        if(!item) return 1;
        else      return [item numberOfChildren];
    }
    else {
        if(!item) return [[model header] count];
        else      return [item count]; 
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item 
{
    if(outlineView == dataCatalogView){
        if(!item )   return YES;
        else         return ([item count] != 0);
    }
    else {
        if(!item) return NO;		
        else {
			if([item respondsToSelector:@selector(isLeafNode)])return ![item isLeafNode];
			else return NO;
		}
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item 
{
    if(outlineView == dataCatalogView){
        if(!item)   return model;
        else        return [item childAtIndex:index];
    }
    else {
        if(!item) return [[model header] childAtIndex:index];
        else      return [item childAtIndex:index];
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
    if(outlineView == dataCatalogView){
        if(!item) {return [model name];}
        else      return [item name];
    }
    else {
        if([[tableColumn identifier] isEqualToString:@"LevelName"]){
            if(item==0) return [[model header] name];
            else        return [item name];
        }
        else if([[tableColumn identifier] isEqualToString:@"Class Name"]){
            if(item==0) return [[model header] classType];
            else        return [item classType];
            
        }
        else if([[tableColumn identifier] isEqualToString:@"Value"]){
            if(item==0){
                return [[[NSAttributedString alloc] 
                        initWithString:[NSString stringWithFormat:@"%d key/value pairs",(uint32_t)[[model header] count]]
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,nil]] autorelease];
            }
            else {
                if([item isLeafNode]){
                    return [NSString stringWithFormat:@"%@",[item object]];
                }
                else {
                    return [[[NSAttributedString alloc] 
                        initWithString:[NSString stringWithFormat:@"%d key/value pairs",(uint32_t)[item count]]
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,nil]] autorelease];            
                }
            }
        }
        
        else return nil;
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
   return [[model dataRecords] count];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
    if([[aTableColumn identifier] isEqualToString: @"Number"]){
        return [NSNumber numberWithInteger:rowIndex];
    }
   else {
        NSDictionary* aDictionary = [[model dataRecords] objectAtIndex:rowIndex];
        if([[aTableColumn identifier] isEqualToString:@"Name"]){
            if([[aDictionary objectForKey:@"DecodedOnce"] boolValue]){
                return [[[NSAttributedString alloc] initWithString:[aDictionary objectForKey:@"Name"]
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,nil]]autorelease];
            }
            else {
                return [[[NSAttributedString alloc] initWithString:[aDictionary objectForKey:@"Name"]
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blackColor],NSForegroundColorAttributeName,nil]]autorelease];
            }
        }
        else return [aDictionary objectForKey:[aTableColumn identifier]];
    }
}

- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSTableView* tv = [aNotification object];
    uint32_t row = (uint32_t)[tv selectedRow];
    if(tv == dataView && row != -1){
        [self process:row];
		if([model multiCatalog])[model setHistoErrorFlag:YES];
    }
}

- (void) process:(uint32_t)row
{
    if(![model dataSet])[model createDataSet];
    NSMutableDictionary* dataDictionary = [model dataRecordAtIndex:(int)row];
    uint32_t offset = (uint32_t)[[dataDictionary objectForKey:@"StartingOffset"] longValue];
    id aKey = [dataDictionary objectForKey:@"Key"];
	BOOL alreadyDecodedOnce = [[dataDictionary objectForKey:@"DecodedOnce"] boolValue];
    if(!alreadyDecodedOnce || [model multiCatalog]){
		if(!alreadyDecodedOnce)[model byteSwapOneRecordAtOffset:offset forKey:aKey];
        [model decodeOneRecordAtOffset:offset forKey:aKey];
        [dataDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"DecodedOnce"]; 
    }
    if(!scanInProgress){
        NSString* header = [NSString stringWithFormat:@"Record %u / %lu\n",row,[[model dataRecords]count]-1];
        header = [header stringByAppendingFormat:@"%@",[model dataRecordDescription:offset forKey:aKey]];
        [detailsView setString:header];
    }

    [self dataChanged:nil];
}

#pragma mark ¥¥¥Delegate Methods
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return NO;
}
@end
