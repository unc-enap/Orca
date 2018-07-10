//
//  ORProcessCenter.m
//  Orca
//
//  Created by Mark Howe on Sun Dec 11, 2005.
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
#import "ORProcessModel.h"
#import "ORProcessElementModel.h"
#import "ORProcessCenter.h"
#import "SynthesizeSingleton.h"

int sortUpFunc(id element1,id element2, void* context){ return [element1 compareStringTo:element2 usingKey:context];}
int sortDnFunc(id element1,id element2, void* context){return [element2 compareStringTo:element1 usingKey:context];}

@implementation ORProcessCenter

#pragma mark ¥¥¥Inialization

SYNTHESIZE_SINGLETON_FOR_ORCLASS(ProcessCenter);

-(id)init
{
    self = [super initWithWindowNibName:@"ProcessCenter"];
    [self setWindowFrameAutosaveName:@"ProcessCenterX"];
    return self;
}

- (void) dealloc
{
	//should never get here since we are a sigleton, but....
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[ascendingSortingImage release];
	[descendingSortingImage release];
    [processorList release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    ascendingSortingImage = [[NSImage imageNamed:@"NSAscendingSortIndicator"] retain];
    descendingSortingImage = [[NSImage imageNamed:@"NSDescendingSortIndicator"] retain];
	[processView setAutosaveTableColumns:YES];
	[processView setAutosaveName:@"ORProcessCenterOutlineView"];   
	
    [[[(ORAppDelegate*)[NSApp delegate]document] undoManager] disableUndoRegistration];
	[self setProcessMode:0];
    [[[(ORAppDelegate*)[NSApp delegate]document] undoManager] enableUndoRegistration];
	
    [processView setDoubleAction:@selector(doubleClick:)];
	[self findObjects];
}

- (void) findObjects
{
    [processorList release];
    processorList = [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORProcessModel")] mutableCopy];
    [processView reloadData];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[(ORAppDelegate*)[NSApp delegate]document]  undoManager];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsAdded:)
                         name : ORGroupObjectsAdded
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(objectsRemoved:)
                         name : ORGroupObjectsRemoved
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessModelCommentChangedNotification
                       object : nil];
					   
    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessModelShortNameChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessCommentChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessElementStateChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessTestModeChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessTestModeChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(doReload:)
                         name : ORProcessRunningChangedNotification
                       object : nil];
}

- (void) awakeAfterDocumentLoaded
{
    [self registerNotificationObservers];
    [self findObjects];
}

- (int) numberRunningProcesses
{
	int processCount = 0;
	for(id aProcess in processorList){
		if([aProcess processRunning]) processCount++;
	}
	return processCount;
}

- (void) doReload:(NSNotification*)aNote
{
    [processView reloadData];
}

- (void) objectsAdded:(NSNotification*)aNote
{
    if([[aNote object] isKindOfClass:NSClassFromString(@"ORGroup")]){
        [self findObjects];
    }
}

- (void) objectsRemoved:(NSNotification*)aNote
{
    if([[aNote object] isKindOfClass:NSClassFromString(@"ORGroup")]){
        [self findObjects];
    }
}

#pragma mark ¥¥¥Accessors
- (void) setProcessMode:(int)aMode
{
    [[[[(ORAppDelegate*)[NSApp delegate]document] undoManager] prepareWithInvocationTarget:self] setProcessMode:processMode];
    
	processMode = aMode;
	
	[modeSelectionButton selectCellWithTag:processMode];
}

- (int) processMode
{
	return processMode;
}


//the full description mostly used for debugging
- (NSString*) description 
{
	NSString* theContent = @"";
	for(id aProcess in processorList){
		theContent = [theContent stringByAppendingFormat:@"%@\n",[aProcess description]];
	}
	return theContent;
}

//a sort of summary report suitable for email or printing
- (NSString*) report 
{
	NSString* theContent = @"";
	for(id aProcess in processorList){
		theContent = [theContent stringByAppendingFormat:@"%@\n",[aProcess report]];
	}
	return theContent;
}

#pragma mark ¥¥¥Actions

- (IBAction) doubleClick:(id)sender
{
    [(OrcaObject*)[processView selectedItem] doDoubleClick:sender];
}

- (IBAction) saveDocument:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocumentAs:sender];
}

- (IBAction) startAll:(id)sender
{
	if(processMode == 0)		[processorList makeObjectsPerformSelector:@selector(putInRunMode)];
	else if(processMode ==1)	[processorList makeObjectsPerformSelector:@selector(putInTestMode)];
    [processorList makeObjectsPerformSelector:@selector(startRun)];
}

- (IBAction) stopAll:(id)sender
{
    [processorList makeObjectsPerformSelector:@selector(stopRun)];
}

- (IBAction) startSelected:(id)sender
{
	NSArray* selectedItems = [processView allSelectedItems];
	NSEnumerator* e = [selectedItems objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		if([obj respondsToSelector:@selector(startRun)]){
			if(processMode == 0)		[obj putInRunMode];
			else if(processMode ==1)	[obj putInTestMode];
			[obj startRun];
		}
	}	
}

- (IBAction) stopSelected:(id)sender
{
	NSArray* selectedItems = [processView allSelectedItems];
	NSEnumerator* e = [selectedItems objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		if([obj respondsToSelector:@selector(stopRun)]){
			[obj stopRun];
		}
	}
}

- (IBAction) modeAction:(id)sender
{
	[self setProcessMode:[[sender selectedCell] tag]]; 
}

#pragma mark ¥¥¥OutlineView Data Source
- (id)   outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    return item==nil?[processorList objectAtIndex:index]:[[item children] objectAtIndex:index];
}

- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [[item children] count];
}

- (int)  outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return item == nil?[processorList count]:[[item children] count];
}

- (id)  outlineView:(NSOutlineView *)outlineView  objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString* columnID =  [tableColumn identifier];
    return [item valueForKey:columnID];
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn byItem:(id)item;
{
    [item setValue:anObject forKey:[aTableColumn identifier]];
}

- (void) outlineView:(NSOutlineView*)tv didClickTableColumn:(NSTableColumn *)tableColumn
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
    [processView reloadData];
}

- (void) updateTableHeaderToMatchCurrentSort
{
    BOOL isDescending = [self sortIsDescending];
    NSString *key = [self sortColumn];
    NSArray *a = [processView tableColumns];
    NSTableColumn *column = [processView tableColumnWithIdentifier:key];
    unsigned i = [a count];
    
    while (i-- > 0) [processView setIndicatorImage:nil inTableColumn:[a objectAtIndex:i]];
    
    if (key) {
        [processView setIndicatorImage:(isDescending ? ascendingSortingImage:descendingSortingImage) inTableColumn:column];
        
        [processView setHighlightedTableColumn:column];
    }
    else {
        [processView setHighlightedTableColumn:nil];
    }
}

-(void)setSortColumn:(NSString *)identifier {
    if (![identifier isEqualToString:_sortColumn]) {
        [_sortColumn release];
        _sortColumn = [identifier copyWithZone:[self zone]];
    }
}

- (NSString *)sortColumn
{
    return _sortColumn;
}

- (void)setSortIsDescending:(BOOL)whichWay {
    if (whichWay != _sortIsDescending) {
        _sortIsDescending = whichWay;
    }
}

- (void) stopAllAndNotify
{
	[self stopAll:nil];
}

- (BOOL)sortIsDescending
{
    return _sortIsDescending;
}

- (void) sort
{
    if(_sortIsDescending){
		[processorList sortUsingFunction:sortDnFunc context: _sortColumn];
	}
    else {
		[processorList sortUsingFunction:sortUpFunc context: _sortColumn];
	}
	NSEnumerator* mainEnummy = [processorList objectEnumerator];
	ORProcessElementModel* objFromProcessorList;
	while(objFromProcessorList = [mainEnummy nextObject]){
		NSMutableArray* theKids = [objFromProcessorList children];
		if(_sortIsDescending){
			[theKids sortUsingFunction:sortDnFunc context: _sortColumn];
		}
		else {
			[theKids sortUsingFunction:sortUpFunc context: _sortColumn];
		}
	}
}

@end

