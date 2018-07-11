//
//  ORDataTaskContoller.m
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
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
#import "ORDataTaskController.h"
#import "ORDataTaskModel.h"
#import "ORDataTaker.h"
#import "ORReadOutList.h"
#import "ORValueBar.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"
#import "ORPlotView.h"
#import "OR1DHistoPlot.h"
#import "ORAxis.h"
#import "ORGroupView.h"

#define ORDataTakerItem @"ORDataTaker Drag Item"
#define kManualRefresh 1E10

@implementation ORDataTaskController
- (id) init
{
    self = [super initWithWindowNibName:@"DataTask"];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    //-------------------------------------------------------------------------------------------
    [NSObject cancelPreviousPerformRequestsWithTarget:plotter];
    [[NSNotificationCenter defaultCenter] removeObserver:plotter];
	[plotter release];
    //-------------------------------------------------------------------------------------------

    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
	[plotter setUseGradient:YES];
	
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: @"orca.ORDataTaker.selectedtab"];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
    
    [readoutListView registerForDraggedTypes:[NSArray arrayWithObjects:ORDataTakerItem, nil]];
    [removeButton setEnabled:NO];
    [removeAllButton setEnabled:NO];
    
    [totalListView setDoubleAction:@selector(tableDoubleClick:)];
    [readoutListView setDoubleAction:@selector(tableDoubleClick:)];
    [readoutListView setAction:@selector(tableClick:)];
    
    [[queueBarGraph xAxis] setRngLow:0 withHigh:(double)[model queueMaxSize]];
    [[queueBarGraph xAxis] setLog:YES];
    
    [[plotter yAxis] setRngLimitsLow:0 withHigh:1e10 withMinRng:10];
    [[plotter yAxis] setRngLow:0 withHigh:2000];
    [[plotter yAxis] setLog:NO];
    [[plotter xAxis] setRngLimitsLow:0 withHigh:kTimeHistoSize withMinRng:10];
    [[plotter xAxis] setRngLow:0 withHigh:kTimeHistoSize];
    [[plotter xAxis] setLog:NO];

    [totalListView setVerticalMotionCanBeginDrag:YES];
    [readoutListView setVerticalMotionCanBeginDrag:YES];
	
	
	OR1DHistoPlot* aPlot = [[OR1DHistoPlot alloc] initWithTag:0 andDataSource:self];
	[plotter addPlot: aPlot];
	[aPlot release]; 
	
	OR1DHistoPlot* aPlot1 = [[OR1DHistoPlot alloc] initWithTag:1 andDataSource:self];
	[aPlot1 setLineColor:[NSColor blueColor]];
	[plotter addPlot: aPlot1];
	[aPlot1 release]; 
	
	//we would not normally retain an IB object, but in this cause we are doing doing some delayed refreshed
	//from this object. We need to make sure that the plotter sticks around if we are closed with a delayed
	//refresh pending.
	[plotter retain];
	
    [self updateWindow];
}


#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(reloadObjects:)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(reloadObjects:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(reloadObjects:)
                         name : OROrcaObjectMoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(reloadObjects:)
                         name : NSReadOutListChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(queueCountChanged:)
                         name : ORDataTaskQueueCountChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(timeScalerChanged:)
                         name : ORDataTaskTimeScalerChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(listLockChanged:)
                         name : ORDataTaskListLock
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(listLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(cycleRateChanged:)
                         name : ORDataTaskCycleRateChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(refreshRateChanged:)
                         name : ORDataTaskModelRefreshRateChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(refreshRateChanged:)
                         name : ORDataTaskModelTimerEnableChanged
						object: model];
}

- (void) listLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORDataTaskListLock];
    [listLockButton setState: locked];
    
    [saveAsButton setEnabled:![gSecurity runInProgressOrIsLocked:ORDataTaskListLock]];
    [loadListButton setEnabled:![gSecurity runInProgressOrIsLocked:ORDataTaskListLock]];
    if(locked){
        [totalListViewDrawer close];
        [readoutListView deselectAll:self];
    }
    [self setButtonStates];
    BOOL runInProgress = [gOrcaGlobals runRunning];
    if(runInProgress && [model timerEnabled] && (refreshDelay!=kManualRefresh)){
		[self doTimedRefresh];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doTimedRefresh) object:nil];
	}
}

- (void) cycleRateChanged:(NSNotification*)aNote
{
	[cycleRateField setIntegerValue: [model cycleRate]];
}

- (void) timeScalerChanged:(NSNotification*)aNote
{
	[timeScaleMatrix selectCellWithTag: [model timeScaler]];
}

- (void) queueCountChanged:(NSNotification*)aNote
{
	[queueBarGraph setNeedsDisplay:YES];		
}

- (NSArray*)draggedNodes
{ 
    return draggedNodes; 
}
- (void) dragDone
{
    [draggedNodes release];
    draggedNodes = nil;
}

- (void) setButtonStates
{
    BOOL locked = [gSecurity isLocked:ORDataTaskListLock];
    [removeAllButton setEnabled:!locked  && [readoutListView numberOfRows]>0];
    NSArray *selection = [readoutListView allSelectedItems];
    [removeButton setEnabled:!locked  && [selection count]>0];
}

- (void) reloadObjects:(NSNotification*)aNote
{
    [totalListView reloadData];
    [readoutListView reloadData];
    [self setButtonStates];
}

#pragma mark ¥¥¥Actions

- (void) refreshRateAction:(id)sender
{
	[model setRefreshRate:(int)[sender indexOfSelectedItem]];
}

- (void) doTimedRefresh
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doTimedRefresh) object:nil];
	[plotter setNeedsDisplay:YES];
	if([model timerEnabled] && [gOrcaGlobals runInProgress]){
		[self performSelector:@selector(doTimedRefresh) withObject:nil afterDelay:refreshDelay];
	}
}

- (IBAction) enableTimer:(id)sender
{
	[model setEnableTimer:[sender state]];
}

- (IBAction) timeScaleAction:(id)sender
{
   if([[sender selectedCell]tag] != [model timeScaler]){
        [[self undoManager] setActionName: @"Set Time Scaler"];
        [model setTimeScaler:[[sender selectedCell]tag]];
		[model clearTimeHistogram];		
		[plotter setNeedsDisplay:YES];
    }
}

- (IBAction) refreshTimeAction:(id)sender
{
	[plotter setNeedsDisplay:YES];
}

- (IBAction) tableDoubleClick:(id)sender
{
	NSArray *selection = [sender allSelectedItems];
	[selection makeObjectsPerformSelector:@selector(showMainInterface)];
}

- (IBAction) tableClick:(id)sender
{
	if(sender == readoutListView){
		[self setButtonStates];
	}
}


- (IBAction) removeItemAction:(id)sender
{
    NSArray *selection = [readoutListView allSelectedItems];
	[selection makeObjectsPerformSelector:@selector(removeFromOwner)];
    [readoutListView deselectAll:nil];
	[readoutListView reloadData];
	[self setButtonStates];
}


- (IBAction) removeAllAction:(id)sender
{
	[readoutListView selectAll:sender];
	[self removeItemAction:self];
}

- (IBAction) listLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORDataTaskListLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) loadListAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
    if([model lastFile]){
        startingDir = [[model lastFile] stringByDeletingLastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
    }
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setLastFile:[[openPanel URL]path]];
            [model loadReadOutListFrom:[[openPanel URL]path]];
            [self reloadObjects:nil];
        }
    }];

}

- (IBAction) saveAsAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    // [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    if([model lastFile])startingDir = [[model lastFile] stringByDeletingLastPathComponent];
    else startingDir = NSHomeDirectory();
    
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setLastFile:[[savePanel URL]path]];
            [model saveReadOutListTo:[[savePanel URL]path]];
        }
    }];
}

#pragma mark ¥¥¥Data Source Methods

#define GET_CHILDREN NSArray* children; \
ORReadOutList* guardian = nil;\
if(ov == totalListView){\
	if(!item) children = [[[[model document] group] orcaObjects] sortedArrayUsingSelector:@selector(sortCompare:)]; \
        else if([item respondsToSelector:@selector(orcaObjects)])children = [[item orcaObjects]sortedArrayUsingSelector:@selector(sortCompare:)]; \
            else children = nil;\
}\
else {\
	if(!item) {guardian = [model readOutList]; children = [guardian children];}\
	else if([[item class] isSubclassOfClass: NSClassFromString(@"ORReadOutObject")]){\
		id object = [item object]; guardian = [object guardian]; children = [object children];\
	}\
	else if([[item class] isSubclassOfClass: NSClassFromString(@"ORReadOutList")]){\
		guardian = item; children = [guardian children];\
	}\
	else {guardian = nil; children = nil;}\
}

- (BOOL) outlineView:(NSOutlineView*)ov isItemExpandable:(id)item 
{
	GET_CHILDREN; //macro: given an item, sets children array and guardian.
	if(!children || ([children count] < 1)) return NO;
	return YES;
}


- (NSUInteger)  outlineView:(NSOutlineView*)ov numberOfChildrenOfItem:(id)item
{
	GET_CHILDREN; //macro: given an item, sets children array and guardian.
	return (int)[children count];
}

- (id)   outlineView:(NSOutlineView*)ov child:(NSInteger)index ofItem:(id)item
{
	GET_CHILDREN; //macro: given an item, sets children array and guardian.
	if(!children || ([children count] <= index)) return nil;
	return [children objectAtIndex:index];
}

- (id)   outlineView:(NSOutlineView*)ov objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
	return [item valueForKey:[tableColumn identifier]];
}

// ------------------------------------
// optional data source methods - drag and drop support
#define OBJ_DRAG_TYPE @"ORObjectForDrag"
- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray*)writeItems toPasteboard:(NSPasteboard*)pboard
{
    draggedNodes = [[NSMutableArray array] retain]; 
    NSEnumerator* e = [writeItems objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        if(ov == readoutListView){
            //objects from the readoutlist are already 'wrapped'
            if([obj respondsToSelector:@selector(object)] && [[obj object] conformsToProtocol:@protocol(ORDataTaker)]){
                [draggedNodes addObject:obj];
            }
        }
        else {
            //wrap objs from the total list into a readoutobj
            if([obj conformsToProtocol:@protocol(ORDataTaker)]){
                ORReadOutObject* itemWrapper = [[ORReadOutObject alloc] initWithObject:obj];
                [draggedNodes addObject:itemWrapper];
                [itemWrapper release];
            }
        }
    }
    
    if([draggedNodes count] == 0){
        [draggedNodes release];
        draggedNodes = nil;
        return NO;
    }
    
    // Provide data for our custom type, and simple NSStrings.
    [pboard declareTypes:[NSArray arrayWithObjects:ORDataTakerItem, nil] owner:self];
    
    // the actual data doesn't matter since We're not really putting anything on the pasteboard. We are
    //using it to control the process.
    [pboard setData:[NSData data] forType:ORDataTakerItem]; 
    return YES;
    
}


- (NSUInteger)outlineView:(NSOutlineView*)ov validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    // This method is used by NSOutlineView to determine a valid drop target.  Based on the mouse position, the outline view will suggest a proposed drop location.  This method must return a value that indicates which dragging operation the data source will perform.  The data source may "re-target" a drop if desired by calling setDropItem:dropChildIndex: and returning something other than NSDragOperationNone.  One may choose to re-target for various reasons (eg. for better visual feedback when inserting into a sorted position).
    //	[ov setDropItem:item dropChildIndex:index]; // No-op?
    //	return NSOutlineViewDropOnItemIndex;
    return NSDragOperationEvery;
    // Possible return values?
    //NSDragOperationNone
    //NSDragOperationCopy
    //NSDragOperationLink
    //NSDragOperationGeneric
    //NSDragOperationPrivate
    //NSDragOperationAll
    //NSTableViewDropOn
    //NSTableViewDropAbove
    //use [ov setDropItem:item dropChildIndex:index] with NSOutlineViewDropOnItemIndex
    //NSOutlineViewDropOnItemIndex
}

- (BOOL)outlineView:(NSOutlineView*)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{

	if([gSecurity isLocked:ORDataTaskListLock]){
        [(ORGroupView*)([[info draggingSource] dataSource]) dragDone];
        return NO;
    }
    
	BOOL result = NO;
	NSArray *possibleItems = [(ORGroupView*)([[info draggingSource] dataSource]) draggedNodes];
	
	GET_CHILDREN; //macro: given an item, sets children array and guardian. 
	
	NSMutableArray* nodeItems = [NSMutableArray array];
	for(id anItem in possibleItems){
		if([guardian acceptsObject:[anItem object]]){
			[nodeItems addObject:anItem];
		}
	}
	
	if(ov == readoutListView && [nodeItems count]){
        
		if(item == nil || [[item class] isSubclassOfClass: NSClassFromString(@"ORReadOutList")]){
					
			NSUInteger realIndex;
			if(item == nil && index == NSOutlineViewDropOnItemIndex) realIndex = [[guardian children] count];
			else if (index == NSOutlineViewDropOnItemIndex)          realIndex = 0;
			else                                                     realIndex = index;
            
			if (children == nil) {
				[guardian addObjectsFromArray:nodeItems];
			} 
            else {
				// insert new children
				int i;
				for (i=((int)[nodeItems count]-1); i>=0; i--) {
                    if([guardian containsObject:[nodeItems objectAtIndex:i]]){
                        [guardian moveObject:[nodeItems objectAtIndex:i] toIndex:realIndex];
                    }
					else {
                        [guardian insertObject:[nodeItems objectAtIndex:i] atIndex:realIndex];
                    }
				}
			}
                
            [nodeItems makeObjectsPerformSelector:@selector(setOwner:) withObject:guardian];
			
			[ov reloadData];
			result = YES;
		}
	}
	[(ORGroupView*)([[info draggingSource] dataSource]) dragDone];
	return result;
}

#pragma mark ¥¥¥Delegate Methods

- (void) drawerWillOpen:(NSNotification*)aNote
{
    if([aNote object] == totalListViewDrawer){
        [totalListView reloadData];
        [readoutListView reloadData];
    }
}

- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item
{
    if([gSecurity isLocked:ORDataTaskListLock])return NO;
    if(ov == totalListView){
        if([item conformsToProtocol:@protocol(ORDataTaker)])return YES;
        else return NO;		
    }
    else if(ov == readoutListView){
        if([[item class] isSubclassOfClass: NSClassFromString(@"ORReadOutObject")])return YES;
        else return NO;
    }
    else return NO;
}


#pragma mark ¥¥¥Interface Management

- (void) refreshRateChanged:(NSNotification*)aNote
{
	[refreshRatePU selectItemAtIndex: [model refreshRate]];
	[refreshButton setEnabled:[model refreshRate]==0];
	[clearButton   setEnabled:[model timerEnabled]];
	
	switch([model refreshRate]){
		case 0: refreshDelay = kManualRefresh; break;
		case 1: refreshDelay = 1.0; break;
		case 2: refreshDelay = 0.2; break;
		case 3: refreshDelay = 0.01; break;
	}

	if([model refreshRate]>0){
		[self performSelector:@selector(doTimedRefresh) withObject:nil afterDelay:refreshDelay];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doTimedRefresh) object:nil];
	}
	if([model timerEnabled]){
		[timerEnabledWarningField setStringValue:@"Data Queue Stats Enabled!"];
	}
	else {
		[timerEnabledWarningField setStringValue:@""];
	}
}

- (void) updateWindow
{
    [super updateWindow];
    [totalListView reloadData];
    [readoutListView reloadData];
    [self queueCountChanged:nil];
    [self timeScalerChanged:nil];
    [self cycleRateChanged:nil];
	[self refreshRateChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORDataTaskListLock to:secure];
    [listLockButton setEnabled:secure];
}

- (void)resizeWindowToSize:(NSSize)newSize
{
    NSRect aFrame;
    
    float newHeight = newSize.height;
    float newWidth = newSize.width;
    
    aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] 
                                     styleMask:[[self window] styleMask]];
    
    aFrame.origin.y += aFrame.size.height;
    aFrame.origin.y -= newHeight;
    aFrame.size.height = newHeight;
    aFrame.size.width = newWidth;
    
    aFrame = [NSWindow frameRectForContentRect:aFrame 
                                     styleMask:[[self window] styleMask]];
    
    [[self window] setFrame:aFrame display:YES animate:YES];
}

- (double) doubleValue
{
    return [model queueCount];
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)aTabItem
{
    if(aTabView == tabView){
        NSInteger index = [tabView indexOfTabViewItem:aTabItem];
        if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
        [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"orca.ORDataTaker.selectedtab"];
    }
}

- (int) numberPointsInPlot:(id)aPlotter
{
    return kTimeHistoSize;
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	NSInteger set = [aPlotter tag];
	double aValue = 0;
    if(set == 0)aValue =  [model dataTimeHist:i];
    else		aValue =  [model processingTimeHist:i];
	*yValue = aValue;
	*xValue = i;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    
    if ([menuItem action] == @selector(cut:)) {
        return [readoutListView selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [readoutListView selectedRow] >= 0 ;
    }
    else  if ([menuItem action] == @selector(copy:)) {
        return NO;
    }

    
   else  return [super validateMenuItem:menuItem];
}

- (IBAction)delete:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction)cut:(id)sender
{
    [self removeItemAction:nil];
}

- (IBAction) clearAction:(id)sender
{
	[model clearTimeHistogram];
	[plotter setNeedsDisplay:YES];
}

@end
