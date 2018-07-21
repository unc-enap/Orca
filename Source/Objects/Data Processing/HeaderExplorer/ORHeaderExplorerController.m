//
//  ORHeaderExplorerController.m
//  Orca
//
//  Created by Mark Howe on Tue Feb 26.
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


#pragma mark •••Imported Files
#import "ORHeaderExplorerController.h"
#import "ORHeaderExplorerModel.h"
#import "ORHeaderItem.h"
#import "ORDataSet.h"
#import "ORDataExplorerModel.h"

@interface ORHeaderExplorerController (private)
- (void) addDirectoryContents:(NSString*)path toArray:(NSMutableArray*)anArray;
- (void) processFileList:(NSArray*)filenames;
@end

@implementation ORHeaderExplorerController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"HeaderExplorer"];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) awakeFromNib
{		
    NSString* key = [NSString stringWithFormat: @"orca.ORHeaderExplorer%u.selectedtab",[model uniqueIdNumber]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];

    [fileListView registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	[runSummaryTextView setFont:[NSFont fontWithName:@"Monaco" size:10]];
	[progressIndicatorBottom setIndeterminate:NO];
	[fileListView setDoubleAction:@selector(doubleClick:)];

    [searchKeyTableView registerForDraggedTypes: [NSArray arrayWithObject:NSStringPboardType] ];
    [headerView registerForDraggedTypes: [NSArray arrayWithObject:NSStringPboardType] ];
	[searchKeyTableView reloadData];
	
	[self setRunBoundaryTimes];
    [super awakeFromNib];    
}


#pragma  mark •••Actions

- (IBAction) useFilterAction:(id)sender
{
	[self endEditing];
	[model setUseFilter:[sender intValue]];	
	[model loadHeader];
}

- (IBAction) plotFilteredData:(id)sender
{
	NSIndexSet* selectedSet = [searchKeyTableView selectedRowIndexes];
	if([selectedSet count]){
		NSInteger i = [selectedSet firstIndex];
		while (i != NSNotFound){
			[model assembleDataForPlotting:(int)i];
			i = [selectedSet indexGreaterThanIndex: i];
		}

	}
}

- (IBAction) doubleClick:(id)sender
{
	if(sender == fileListView || sender==runTimeView){
		int index = (int)[fileListView selectedRow];
		NSArray* files = [model filesToProcess];
		if(index>=0 && index<[files count]){
			id selectedFile = [files objectAtIndex: [fileListView selectedRow]];
            NSFileManager* fm = [NSFileManager defaultManager];
            BOOL isDirectory;
            if([fm fileExistsAtPath:selectedFile isDirectory:&isDirectory]){
                NSArray* objects = [[model document] collectObjectsOfClass:NSClassFromString(@"ORDataExplorerModel")];
                if([objects count]){
                    ORDataExplorerModel* explorer = [objects objectAtIndex:0]; //just use the first one
                    [[self undoManager] disableUndoRegistration];
                    [explorer setFileToExplore:selectedFile];
                    [[self undoManager] enableUndoRegistration];
                    [explorer makeMainController];
                    [explorer parseFile];
                }
                else NSLog(@"Header Explorer: No DataExplorer in configuration\n");
            }
            else NSLog(@"Header Explorer: %@ no longer exists.\n",selectedFile);

		}
	}
}

- (IBAction) autoProcessAction:(id)sender
{
	[model setAutoProcess:[sender intValue]];	
}

- (IBAction) selectButtonAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setPrompt:@"Choose"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model lastFilePath]){
        startDir = [[model lastFilePath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* filePath = [[[openPanel URLs] objectAtIndex:0]path];
            [model setLastFilePath:filePath];
            NSMutableArray* array = [NSMutableArray array];
            for(id aURL in [openPanel URLs]){
                [array addObject:[aURL path]];
            }
            [self processFileList:array];
       }
    }];
}

- (IBAction) addSearchKeys:(id)sender
{
	[model addSearchKeys:[NSMutableArray arrayWithObject:@""]];
}

- (IBAction) deleteSearchKeys:(id)sender
{
	if([searchKeyTableView selectedRow]!=-1){
		NSIndexSet* selectedSet = [searchKeyTableView selectedRowIndexes];
		[searchKeyTableView deselectAll:self];
		[model removeSearchKeysWithIndexes:selectedSet];
		[searchKeyTableView reloadData];
	}
}

- (IBAction) copy:(id)sender
{
	if([[self window] firstResponder] == headerView){
		[self copyHeader:(ORHeaderItem*)[headerView selectedItem] toPasteBoard:[NSPasteboard generalPasteboard]];
	}
}

- (IBAction) incRunSelection:(id)sender
{
	int i = [model selectedRunIndex];
	[model setSelectedRunIndex:i+1];
}

- (IBAction) decRunSelection:(id)sender
{
	int i = [model selectedRunIndex];
	[model setSelectedRunIndex:i-1];
}

- (void) copyHeader:(ORHeaderItem*)item toPasteBoard:(NSPasteboard*)pboard
{
	if(item){
		NSString* thePath = [item path];
		if([thePath hasPrefix:@"Root"] || [thePath hasPrefix:@"Key"]){
			thePath = [thePath substringFromIndex:[thePath rangeOfString:@"/"].location+1];
		}
		if([thePath hasPrefix:@"Root"] || [thePath hasPrefix:@"Key"]){
			thePath = [thePath substringFromIndex:[thePath rangeOfString:@"/"].location+1];
		}
		NSMutableArray* parts = [[[thePath componentsSeparatedByString:@"/"] mutableCopy] autorelease];
		thePath = [parts componentsJoinedByString:@"/"];

		NSArray *types   = [NSArray arrayWithObjects: NSStringPboardType, nil];
		[pboard declareTypes:types owner:self];
		[pboard setString:thePath forType:NSStringPboardType];
		
		NSPasteboard* pb = [NSPasteboard generalPasteboard];
		[pb declareTypes:types owner:self];
		[pb setString:thePath forType:NSStringPboardType];
	}
}
- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationCopy;
}

- (IBAction) delete:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction) cut:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction) removeItemAction:(id)sender
{ 
	if([[self window] firstResponder] == fileListView){
		NSIndexSet* selectedSet = [fileListView selectedRowIndexes];
		[fileListView deselectAll:self];
		[model removeFilesWithIndexes:selectedSet];

        int lastIndex = (int)[selectedSet lastIndex];
        [model setSelectedFileIndex:lastIndex];
		[fileListView reloadData];
		[headerView reloadData];
	}
	else if([[self window] firstResponder] == searchKeyTableView){
		NSIndexSet* selectedSet = [searchKeyTableView selectedRowIndexes];
		[searchKeyTableView deselectAll:self];
		[model removeSearchKeysWithIndexes:selectedSet];
		[searchKeyTableView reloadData];
	}
}


- (IBAction) replayButtonAction:(id)sender
{
	[self endEditing];
    if(![model isProcessing]){
        if([model readHeaders])[replayButton setEnabled:NO];
    }
    else {
        [model stopProcessing];
    }
}

- (IBAction) saveListAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model lastListPath]){
        startDir = [[model lastListPath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* listPath = [[savePanel URL]path];
            [model setLastListPath:listPath];
            [[model filesToProcess] writeToFile:listPath atomically:YES];
        }
    }];
}

- (IBAction) loadListAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setPrompt:@"Choose"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model lastListPath]){
        startDir = [[model lastListPath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* listPath = [[[openPanel URLs] objectAtIndex:0]path];
            NSMutableArray* theList = [NSMutableArray arrayWithContentsOfFile:listPath];
            if(theList){
                [model removeAll];
                [model addFilesToProcess:theList];
                [fileListView reloadData];
            }
            else NSLog(@"<%@> replay list is empty\n",listPath);
        }
    }];
}

- (IBAction) selectionDateAction:(id)sender
{
	sliderDrag = YES;
	[model setSelectionDate:[selectionDateSlider maxValue]-[sender intValue]];
	[model findSelectedRunByDate];
	sliderDrag = NO;
}

#pragma mark •••Interface Management
- (void) searchEditedChanged:(NSNotification *)aNote
{
	if(searchKeyTableView == [aNote object]){
		id tv = [[aNote userInfo] objectForKey:@"NSFieldEditor"];
		id s = [tv string];
		if([s hasSuffix:@"\n"]){
			s = [s substringWithRange:NSMakeRange(0,[s length]-1)];
		}
		int index = (int)[searchKeyTableView selectedRow];
		NSMutableArray* keys = [model searchKeys];
		if(s){	
			[keys replaceObjectAtIndex:index withObject:s];
			[model loadHeader];
		}
	}
}

- (void) useFilterChanged:(NSNotification*)aNote
{
	[useFilterCB setIntValue: [model useFilter]];
}

- (void) searchKeysChanged:(NSNotification*)aNote
{
	[searchKeyTableView reloadData];
	[useFilterCB setEnabled:[[model searchKeys] count]>0]; 	
	[model loadHeader];
}

- (void) autoProcessChanged:(NSNotification*)aNote
{
	[autoProcessCB setIntValue: [model autoProcess]];
}

- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(fileListChanged:)
                         name : ORHeaderExplorerListChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(started:)
                         name : ORHeaderExplorerProcessing
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stopped:)
                         name : ORHeaderExplorerProcessingFinished
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(processingFile:)
                         name : ORHeaderExplorerProcessingFile
                        object: model];


    [notifyCenter addObserver : self
                     selector : @selector(selectionDateChanged:)
                         name : ORHeaderExplorerSelectionDate
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(headerChanged:)
                         name : ORHeaderExplorerHeaderChanged
                        object: model];

	[notifyCenter addObserver : self
                     selector : @selector(runSelectionChanged:)
                         name : ORHeaderExplorerRunSelectionChanged
                        object: model];
						
	[notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                        object: nil];
							
						
    [notifyCenter addObserver : self
                     selector : @selector(autoProcessChanged:)
                         name : ORHeaderExplorerAutoProcessChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(searchKeysChanged:)
                         name : ORHeaderExplorerSearchKeysChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(searchEditedChanged:)
                         name : NSControlTextDidChangeNotification
						object: nil];

	[notifyCenter addObserver : self
                     selector : @selector(progressChanged:)
                         name : ORHeaderExplorerProgressChanged
                        object: nil];	
	
	[notifyCenter addObserver : self
                     selector : @selector(fileSelectionChanged:)
                         name : ORHeaderExplorerFileSelectionChanged
                        object: nil];		
}

- (void) updateWindow
{
    [self fileListChanged:nil];
    [self selectionDateChanged:nil];
    [self runSelectionChanged:nil];
    [self fileSelectionChanged:nil];
	
    [self headerChanged:nil];
	
	[progressField setStringValue:@""];
	[self autoProcessChanged:nil];
	[self useFilterChanged:nil];
	[self searchKeysChanged:nil];
	[self progressChanged:nil];
	[self tableViewSelectionDidChange:nil];
}


- (void)started:(NSNotification *)aNote
{
	[useFilterCB setEnabled:NO];
	[fileListView setEnabled:NO];
	[replayButton setEnabled:YES];
	[selectButton setEnabled:NO];
	[saveButton setEnabled:NO];
	[loadButton setEnabled:NO];
	[replayButton setTitle:@"Stop"];
	[progressIndicator startAnimation:self];
	[progressIndicatorBottom startAnimation:self];
}

- (void)stopped:(NSNotification *)aNote
{
	[useFilterCB setEnabled:YES];
	[fileListView setEnabled:YES];
	[replayButton setEnabled:YES];
	[selectButton setEnabled:YES];
	[saveButton setEnabled:YES];
	[loadButton setEnabled:YES];
	[replayButton setTitle:@"Process"];
	[progressIndicator stopAnimation:self];
	[progressIndicatorBottom setIndeterminate:NO];
	[progressIndicatorBottom stopAnimation:self];
	[progressField setStringValue:@""];
	
	[self setRunBoundaryTimes];
	[model setSelectionDate:[selectionDateSlider maxValue] - [selectionDateSlider intValue]];
	[model findSelectedRunByDate];
	[progressIndicatorBottom setDoubleValue:0.0];
	
}
- (void) setRunBoundaryTimes
{
	uint32_t absStart = [model minRunStartTime];
	uint32_t absEnd   = [model maxRunEndTime];
	if(absStart>0 && absEnd>0){
		NSDate* d = [NSDate dateWithTimeIntervalSince1970:absStart];
		[runStartField setObjectValue:[d stdDescription]];
		d = [NSDate dateWithTimeIntervalSince1970:absEnd];
		[runEndField setObjectValue:[d description]];
	}
}

- (void) processingFile:(NSNotification *)aNote
{
	NSString* theFileName = [model fileToProcess];
	if(theFileName)[progressField setStringValue:[NSString stringWithFormat:@"Reading:%@",[theFileName stringByAbbreviatingWithTildeInPath]]];
	else [progressField setStringValue:@""];

	//uint32_t total = [model total];
    //if(total>0)[progressIndicatorBottom setDoubleValue:100. - (100.*[model numberLeft]/(double)total)];
}

- (void) progressChanged:(NSNotification *)aNotification
{
    [progressIndicatorBottom setDoubleValue:[model percentComplete]];
}


#pragma mark •••Interface Management
- (void) selectionDateChanged:(NSNotification*)note
{
	//if(!sliderDrag)
		[selectionDateSlider setIntValue:[selectionDateSlider maxValue] - [model selectionDate]];
	
	uint32_t absStart		= [model minRunStartTime];
	uint32_t absEnd		= [model maxRunEndTime];
	uint32_t selectionDate	= absStart + ((absEnd - absStart) * [model selectionDate]/[selectionDateSlider maxValue]);
	if(absStart && absEnd){
		NSDate* d = [NSDate dateWithTimeIntervalSince1970:selectionDate];
		[selectionDateField setObjectValue:[d description]];
	}
	[runTimeView setNeedsDisplay:YES];
}

- (void) fileSelectionChanged:(NSNotification*)aNote
{
	[fileListView selectRowIndexes:[NSIndexSet indexSetWithIndex: [model selectedFileIndex]] byExtendingSelection:NO] ;
}

- (void) runSelectionChanged:(NSNotification*)aNote
{
	uint32_t absStart		= [model minRunStartTime];
	uint32_t absEnd		= [model maxRunEndTime];
	if(absStart>0 && absEnd>0 && [model selectedRunIndex]>=0){
		NSDictionary* runDictionary = [model runDictionaryForIndex:[model selectedRunIndex]];
		if(runDictionary && [model selectedRunIndex]>=0){
			NSString* units = @"Bytes";
			float fileSize = [[runDictionary objectForKey:@"FileSize"] floatValue];
			if(fileSize>1000000){
				fileSize /= 1000000.;
				units = @"MBytes";
			}
			else if(fileSize>1000){
				fileSize /=1000.;
				units = @"KBytes";
			}
			NSString* problem = [runDictionary objectForKey:@"Failed"];
			NSString* s;
			if(!problem){
				s = [NSString stringWithFormat:@"Run Summary\nRun Number: %@",[runDictionary objectForKey:@"RunNumber"]];
				BOOL subRunsUsed = [[runDictionary objectForKey:@"UseSubRun"] boolValue];
				NSString* sub = [runDictionary objectForKey:@"SubRunNumber"];
				if(sub && subRunsUsed)	s = [s stringByAppendingFormat:@".%@\n",sub];
				else s = [s stringByAppendingString:@"\n"];

				NSDate* startTime = [NSDate dateWithTimeIntervalSince1970:[[runDictionary objectForKey:@"RunStart"] unsignedLongValue]];
				s = [s stringByAppendingFormat:@"Started   : %@\n",startTime];
				s = [s stringByAppendingFormat:@"Run Length: %@ sec\n",[runDictionary objectForKey:@"RunLength"]];
				s = [s stringByAppendingFormat:@"File Size : %.2f %@",fileSize,units];
				[runSummaryTextView setString:s];
			}
			else [runSummaryTextView setString:problem];
						
		}
		else {
			[runSummaryTextView setString:@"no valid selection"];
		}
	}
	else {
		[runSummaryTextView setString:@"no valid selection"];
	}
	[runTimeView setNeedsDisplay:YES];
}

- (void) fileListChanged:(NSNotification*)aNote
{
	NSUInteger n = [fileListView numberOfSelectedRows];
	if(n == 1){
		int i = (int)[fileListView selectedRow];
		[model selectFirstRunForFileIndex:i];
	}

	[fileListView reloadData];
    [self headerChanged:nil];
}

- (void) headerChanged:(NSNotification*)aNote
{
	[headerView reloadData];
}

#pragma mark •••Data Source Methods

- (NSUInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(outlineView == headerView){
        if(!item) return [[model header] count];
        else      return [item count]; 
    }
    else return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item 
{
    if(outlineView == headerView){
        if(!item) return NO;		
        else {
			if([item respondsToSelector:@selector(isLeafNode)])return ![item isLeafNode];
			else return NO;
		}
    }
    else return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item 
{
    if(outlineView == headerView){
        if(!item) return [[model header] childAtIndex:index];
        else      return [item childAtIndex:index];
    }
    else return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
    if(outlineView == headerView){
        if([[tableColumn identifier] isEqualToString:@"LevelName"]){
            if(item==0) return [[model header] name];
			else if([item respondsToSelector:@selector(name)]){
				NSString* theName = [item name];
				if([theName hasPrefix:@"Key"]){
						[outlineView performSelector:@selector(expandItem:) withObject:item afterDelay:0];
				}
				return theName;
			}
            else     return @"Value";
        }
        else if([[tableColumn identifier] isEqualToString:@"Value"]){
            if(item==0){
                return [[[NSAttributedString alloc] 
                        initWithString:[NSString stringWithFormat:@"%d key/value pairs",(uint32_t)[[model header] count]]
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,nil]]autorelease];
            }
            else {
				if([item respondsToSelector:@selector(isLeafNode)]){
					if([item isLeafNode]){
						return [NSString stringWithFormat:@"%@",[item object]];
					}
					else {
						return [[[NSAttributedString alloc] 
							initWithString:[NSString stringWithFormat:@"%d key/value pairs",(uint32_t)[item count]]
								attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,nil]] autorelease];            
					}
				}
				else return item;
            }
        }
        
        else return nil;
    }
    else return nil;
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
	if(aTableView == fileListView){
		if([[model filesToProcess] count]){
			id obj = [[model filesToProcess]  objectAtIndex:rowIndex];
			return [obj stringByAbbreviatingWithTildeInPath];
		}
	}
	else if(aTableView == searchKeyTableView){
		if([[model searchKeys] count]){
			if([[aTableColumn identifier] isEqualToString:@"index"])return [NSString stringWithFormat:@"%d",(int)rowIndex];
			else return [[model searchKeys] objectAtIndex:rowIndex];
		}
	}
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if(aTableView == searchKeyTableView){ 
		NSParameterAssert(rowIndex >= 0 && rowIndex < [[model searchKeys] count]);
		[[model searchKeys] replaceObjectAtIndex:rowIndex withObject:anObject];
	}
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == fileListView){
		return [[model filesToProcess] count];
	}
	else if(aTableView == searchKeyTableView){
		return [[model searchKeys] count];
	}
	else return 0;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	if(![model useFilter]){
		return YES;
	}
	else return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
    return [model fileHasBeenProcessed:rowIndex];
}

- (NSDragOperation) tableView:(NSTableView *) aTableView validateDrop:(id <NSDraggingInfo>) info proposedRow:(NSInteger) row proposedDropOperation:(NSTableViewDropOperation) operation
{
	if(aTableView == fileListView)return NSDragOperationEvery;
	else {
		if(![model useFilter])return NSDragOperationEvery;
		else return NSDragOperationNone;
	}
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTextFieldCell *cell = [tableColumn dataCell];
    if(![model fileHasBeenProcessed:(uint32_t)row]){
        [cell setTextColor: [NSColor lightGrayColor]];
    }
    else {
        [cell setTextColor: [NSColor blackColor]];
    }
    return cell;
}

- (BOOL)tableView:(NSTableView*)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
	NSPasteboard* pb = [info draggingPasteboard];
	if(aTableView == fileListView){
		NSData* data = [pb dataForType:NSFilenamesPboardType];
		NSFileManager* fm = [NSFileManager defaultManager];
		[fm createFileAtPath:@"OrcaJunkTemp" contents:data attributes:nil];
		[self processFileList:[NSArray arrayWithContentsOfFile:@"OrcaJunkTemp"]];
		[fm removeItemAtPath:@"OrcaJunkTemp" error:nil];
		return YES;
	}
	else 	if(aTableView == searchKeyTableView	){
		if(op == NSTableViewDropOn){
			[model replace:row withSearchKey: [[info draggingPasteboard] stringForType:NSStringPboardType]];
		}
		else {
			[model insert:row withSearchKey: [[info draggingPasteboard] stringForType:NSStringPboardType]];
		}
		
		return YES;
	}
	else return NO;
}

- (void) tableViewSelectionDidChange:(NSNotification *)aNote
{
	if([aNote object] == fileListView){
		NSInteger n = [fileListView numberOfSelectedRows];
		if(n == 1){
			int i = (int)[fileListView selectedRow];
			[model setSelectedFileIndex:i];
			[model selectFirstRunForFileIndex:i];
			uint32_t absStart = [model minRunStartTime];
			uint32_t absEnd   = [model maxRunEndTime];
			
			uint32_t start = (uint32_t)[[model run:i objectForKey:@"RunStart"] unsignedLongValue];
			uint32_t end   = (uint32_t)[[model run:i objectForKey:@"RunEnd"] unsignedLongValue];
			uint32_t mid = start + (end-start)/2.;
			if(absEnd-absStart !=0){
				[model setSelectionDate:1000*(mid - absStart)/(absEnd-absStart)];
			}
		}
		else {
			[model setSelectedFileIndex:-1];
			[model selectFirstRunForFileIndex:-1];
			[headerView reloadData];
		}
	}
	if([aNote object] == searchKeyTableView || !aNote){
		int n = (int)[[searchKeyTableView selectedRowIndexes] count];
		[removeSearchKeyButton setEnabled:n>0];
		[printButton setEnabled:n>0];
	}
}

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray*)writeItems toPasteboard:(NSPasteboard*)pboard
{
	if(ov == headerView){
		[self copyHeader:[writeItems objectAtIndex:0] toPasteBoard:pboard];

		return YES;
    }
	return NO;
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSString* key = [NSString stringWithFormat: @"orca.ORHeaderExplorer%u.selectedtab",[model uniqueIdNumber]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

#pragma mark •••Data Source
- (uint32_t) minRunStartTime {return [model minRunStartTime];}
- (uint32_t) maxRunEndTime	  {return [model maxRunEndTime];}
- (int32_t) numberRuns {return [model numberRuns];}
- (id) run:(int)index objectForKey:(id)aKey { return [model run:index objectForKey:aKey]; }
- (int) selectedRunIndex { return [model selectedRunIndex]; }

- (void) setSelectionDate:(int32_t)aValue { [model setSelectionDate:aValue]; }
- (void) findSelectedRunByDate { [model findSelectedRunByDate]; }
- (NSSlider*) selectionDateSlider
{
	return selectionDateSlider;
}
@end

@implementation ORHeaderExplorerController (private)
-(void) processFileList:(NSArray*)filenames
{
    NSMutableArray* theFinalList = [NSMutableArray array];
    NSFileManager* fm = [NSFileManager defaultManager];
    NSEnumerator* e = [filenames objectEnumerator];
    BOOL isDirectory;
    id fileName;
    while(fileName = [e nextObject]){
        [fm fileExistsAtPath:fileName isDirectory:&isDirectory];
        if(!isDirectory){
            //just a file
            //if([fileName rangeOfString:@"Run"].location != NSNotFound){
                [theFinalList addObject:fileName];
           // }
        }
        else {
            //it's a directory
            [self addDirectoryContents:fileName toArray:theFinalList];
        }
    }
	
    [model addFilesToProcess:theFinalList];
    [fileListView reloadData];
}

- (void) addDirectoryContents:(NSString*)aPath toArray:(NSMutableArray*)anArray
{
    BOOL isDirectory;
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm fileExistsAtPath:aPath isDirectory:&isDirectory];
    if(isDirectory){
        NSDirectoryEnumerator* e = [fm enumeratorAtPath:aPath];
        NSString *file;
        while (file = [e nextObject]) {
			NSString* fullPath = [aPath stringByAppendingPathComponent:file];
           [fm fileExistsAtPath:fullPath isDirectory:&isDirectory];
            if(!isDirectory){
                //just a file
				// if([file rangeOfString:@"Run"].location != NSNotFound){
                    [anArray addObject:[NSString stringWithFormat:@"%@/%@",aPath,file]];
                //}
            }
            else {
                //it's a directory
                [self addDirectoryContents:file toArray:anArray];
            }
			
        }
    }
}


@end

@implementation ORRunTimeView

- (void) dealloc
{
	[selectedGradient release];
	[backgroundGradient release];
	[normalGradient release];
	[super dealloc];
}

- (void) awakeFromNib
{
	CGFloat red,green,blue;
	red = 0; green = 1; blue = 0;
	normalGradient = [[NSGradient alloc]
						initWithStartingColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1]
						               endingColor:[NSColor colorWithCalibratedRed:.5*red green:.5*green blue:.5*blue alpha:1]];


	red = 1; green = 0; blue = 0;
	selectedGradient = [[NSGradient alloc] 
						initWithStartingColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1]
						               endingColor:[NSColor colorWithCalibratedRed:.5*red green:.5*green blue:.5*blue alpha:1]];


	float gray = 1.0;
	backgroundGradient = [[NSGradient alloc]
						initWithStartingColor:[NSColor colorWithCalibratedRed:gray green:gray blue:gray alpha:1]
						               endingColor:[NSColor colorWithCalibratedRed:.7*gray green:.7*gray blue:.7*gray alpha:1]];

}

- (BOOL) isFlipped
{
	return YES;
}

- (void) drawRect:(NSRect)aRect
{
	[NSBezierPath setDefaultLineWidth:1];
	[backgroundGradient drawInRect:[self bounds] angle:0];
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:[self bounds]];
		
	uint32_t absStart = [dataSource minRunStartTime];
	uint32_t absEnd   = [dataSource maxRunEndTime];
	int32_t n = [dataSource numberRuns];
	int32_t selectedRunIndex = [dataSource selectedRunIndex];
	int i;
	for(i=0;i<n;i++){
	
		uint32_t start = (uint32_t)[[dataSource run:i objectForKey:@"RunStart"] unsignedLongValue];
		uint32_t end   = (uint32_t)[[dataSource run:i objectForKey:@"RunEnd"] unsignedLongValue];

		if(start && end){
			float h = [self bounds].size.height;
			float y1 = h*(start-absStart)/(float)(absEnd-absStart);
			float y2 = h*(end-absStart)/(float)(absEnd-absStart);
			NSRect aRect = NSMakeRect(0,y1,[self bounds].size.width,y2-y1);
			if(i==selectedRunIndex)[selectedGradient drawInRect:aRect angle:0];
			else [normalGradient drawInRect:aRect angle:0];
			[[NSColor blackColor] set];
			[NSBezierPath strokeRect:aRect];
		}
	}
}
- (BOOL)mouseDownCanMoveWindow
{
	return NO;
}

- (void) mouseDown:(NSEvent*)anEvent
{
    NSPoint mouseLoc =  [self convertPoint:[anEvent locationInWindow] fromView:nil];
	uint32_t selectedPoint = (mouseLoc.y/[self bounds].size.height)*1000.;
	[dataSource setSelectionDate:selectedPoint];
	[dataSource findSelectedRunByDate];
	if([anEvent clickCount] >= 2){
		[dataSource doubleClick:self];
	}
}
- (BOOL) acceptsFirstResponder
{
    return YES;
}
@end

