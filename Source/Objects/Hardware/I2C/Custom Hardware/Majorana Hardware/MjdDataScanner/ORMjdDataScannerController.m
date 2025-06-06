//
//  ORMjdDataScannerController.m
//
//  Created by Mark Howe on 08/4/2015.
//  Copyright 2015 University of North Carolina. All rights reserved.
//
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "ORMjdDataScannerController.h"
#import "ORMjdDataScannerModel.h"
#import "ORHeaderItem.h"
#import "ORDataSet.h"

@interface ORMjdDataScannerController (private)
- (void) addDirectoryContents:(NSString*)path toArray:(NSMutableArray*)anArray;
- (void) processFileList:(NSArray*)filenames;
@end

@implementation ORMjdDataScannerController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"MjdDataScanner"];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    [fileListView registerForDraggedTypes: [NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
	[progressIndicatorBottom setIndeterminate:NO];
    [super awakeFromNib];    
}

#pragma mark •••Accessors


#pragma  mark •••Actions
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
        if (result == NSFileHandlingPanelOKButton) {
            NSString* filePath = [[[openPanel URLs] objectAtIndex:0]path];
            [model setLastFilePath:filePath];
            NSMutableArray* fileNames = [NSMutableArray array];
            for(id aURL in [openPanel URLs]){
                [fileNames addObject:[aURL path]];
            }
            [self processFileList:fileNames];
        }
    }];
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
	NSIndexSet* selectedSet = [fileListView selectedRowIndexes];
	[fileListView deselectAll:self];

    [model removeFilesWithIndexes:selectedSet];
    
    [fileListView reloadData];
}


- (IBAction) replayButtonAction:(id)sender
{
    if(![model isReplaying]){
        [model replayFiles];
    }
    else {
        [model stopReplay];
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
        if (result == NSFileHandlingPanelOKButton) {
            NSString* listPath = [[savePanel URL] path];
            [model setLastListPath:listPath];
            [[model filesToReplay] writeToFile:listPath atomically:YES];
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
        if (result == NSFileHandlingPanelOKButton) {
            NSString* listPath = [[[openPanel URLs] objectAtIndex:0] path];
            NSMutableArray* theList = [NSMutableArray arrayWithContentsOfFile:listPath];
            if(theList){
                [model removeAll];
                [model addFilesToReplay:theList];
                [fileListView reloadData];
            }
            else NSLog(@"<%@> replay list is empty\n",listPath);
        }
    }];
}


#pragma mark •••Interface Management
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(fileListChanged:)
                         name : ORMjdDataScannerFileListChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(started:)
                         name : ORMjdDataScannerRunningNotification
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stopped:)
                         name : ORMjdDataScannerStoppedNotification
                        object: model];
		
    [notifyCenter addObserver : self
                     selector : @selector(fileChanged:)
                         name : ORMjdDataScannerFileChangedNotification
                        object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(tableViewSelectionDidChange:)
                         name : NSTableViewSelectionDidChangeNotification
                        object: nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(progressChanged:)
                         name : ORMjdDataScannerProgressChangedNotification
                        object: nil];	
}

- (void) updateWindow
{
    [self fileListChanged:nil];
    [self fileChanged:nil];
    [self progressChanged:nil];
	[workingOnField setStringValue:@""];
}

- (void)started:(NSNotification *)aNotification
{
	[fileListView setEnabled:NO];
	[replayButton setEnabled:YES];
	[selectButton setEnabled:NO];
	[replayButton setTitle:@"Stop"];
	[progressIndicator startAnimation:self];
	[progressField setStringValue:@"In Progress"];
}

- (void) progressChanged:(NSNotification *)aNotification
{
    [progressIndicatorBottom setDoubleValue:[model percentComplete]];
}

- (void)stopped:(NSNotification *)aNotification
{
	[fileListView setEnabled:YES];
	[replayButton setEnabled:YES];
	[selectButton setEnabled:YES];
	[replayButton setTitle:@"Start Replay"];
	[progressIndicator stopAnimation:self];
	[progressField setStringValue:@""];
	[workingOnField setStringValue:@""];
	[progressIndicatorBottom setDoubleValue:0.0];
	[progressIndicatorBottom stopAnimation:self];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([aNotification object] == fileListView){
		if(![model isReplaying]){
			[self loadHeader];
		}
	}
}

- (void) loadHeader
{
    int n = (int)[fileListView numberOfSelectedRows];
    if(n <= 1){
        int index;
        if(n == 1)index = (int)[fileListView selectedRow];
        else index = 0;
        [model readHeaderForFileIndex:index];
        if([[model filesToReplay] count]){
            [viewHeaderFile setStringValue:[[[model filesToReplay] objectAtIndex:index] stringByAbbreviatingWithTildeInPath]];
        }
        else [viewHeaderFile setStringValue:@"---"];
		//[model readHeaderForFileIndex:index];
		
        [headerView reloadData];
    }
}

#pragma mark •••Interface Management
- (void) fileChanged:(NSNotification *)aNotification
{
	NSString* theFileName = [model fileToReplay];
	if(theFileName)[workingOnField setStringValue:[NSString stringWithFormat:@"Processing:%@",[theFileName stringByAbbreviatingWithTildeInPath]]];
	else [workingOnField setStringValue:@""];
}

- (void) fileListChanged:(NSNotification*)note
{
	[fileListView reloadData];
	[self loadHeader];
}

- (void) drawerDidOpen:(NSNotification *)notification
{
    [viewHeaderButton setTitle:@"Close"];
    [self loadHeader];
    [headerView reloadData];	
}

- (void) drawerDidClose:(NSNotification *)notification
{
    [viewHeaderButton setTitle:@"View Header"];
}



#pragma mark •••Data Source Methods

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item 
{
    if(outlineView == headerView){
        if(!item) return (int)[[model header] count];
        else      return (int)[(ORHeaderItem*)item count];
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

- (id)outlineView:(NSOutlineView *)outlineView child:(NSUInteger)index ofItem:(id)item 
{
    if(outlineView == headerView){
        if(!item) return [[model header] childAtIndex:index];
        else      return [(ORHeaderItem*)item childAtIndex:index];
    }
    else return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
    if(outlineView == headerView){
        if([[tableColumn identifier] isEqualToString:@"LevelName"]){
            if(item==0) return [[model header] name];
            else        return [item name];
        }
        else if([[tableColumn identifier] isEqualToString:@"Value"]){
            if(item==0){
                return [[[NSAttributedString alloc] 
                        initWithString:[NSString stringWithFormat:@"%d key/value pairs",(int)[[model header] count]]
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,nil]] autorelease];
            }
            else {
                if([item isLeafNode]){
                    return [NSString stringWithFormat:@"%@",[item object]];
                }
                else {
                    return [[[NSAttributedString alloc] 
                        initWithString:[NSString stringWithFormat:@"%d key/value pairs",(int)[(ORHeaderItem*)item count]]
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor],NSForegroundColorAttributeName,nil]] autorelease];            
                }
            }
        }
        
        else return nil;
    }
    else return nil;
}



- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
    if([[model filesToReplay] count]){
        id obj = [[model filesToReplay]  objectAtIndex:rowIndex];
        return [obj stringByAbbreviatingWithTildeInPath];
    }
    else return nil;
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    
    return [[model filesToReplay] count];
}


- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    [headerView setNeedsDisplay:YES];
    return YES;
}

- (NSDragOperation) tableView:(NSTableView *) tableView validateDrop:(id <NSDraggingInfo>) info proposedRow:(NSInteger) row proposedDropOperation:(NSTableViewDropOperation) operation
{
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard* pb = [info draggingPasteboard];
    NSData* data = [pb dataForType:NSFilenamesPboardType];
    NSFileManager* fm = [NSFileManager defaultManager];
    [fm createFileAtPath:@"OrcaJunkTemp" contents:data attributes:nil];
    [self processFileList:[NSArray arrayWithContentsOfFile:@"OrcaJunkTemp"]];
    [fm removeItemAtPath:@"OrcaJunkTemp" error:nil];
    return YES;
}


@end

@implementation ORMjdDataScannerController (private)
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
	
    [model addFilesToReplay:theFinalList];
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
            [fm fileExistsAtPath:file isDirectory:&isDirectory];
            if(!isDirectory){
                //just a file
                //if([file rangeOfString:@"Run"].location != NSNotFound){
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


