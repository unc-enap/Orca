//
//  ORDocumentController.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 03 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORDocumentController.h"
#import "ORStatusController.h"
#import "ORAlarmController.h"
#import "ORCatalogController.h"
#import "ORHelpCenter.h"
#import "ORHWWizardController.h"
#import "ORPreferencesController.h"
#import "ORCommandCenterController.h"
#import "ORDataTaker.h"
#import "ORReadOutList.h"
#import "ORTemplates.h"
#import "ORArchive.h"
#import "ORVXI11HardwareFinderController.h"

NSInteger sortListUpFunc(id element1,id element2, void* context){ return [element1 compareStringTo:element2 usingKey:context];}
NSInteger sortListDnFunc(id element1,id element2, void* context){return [element2 compareStringTo:element1 usingKey:context];}

#define ORDataTakerItem @"ORDataTaker Drag Item"

@implementation ORDocumentController

#pragma mark ¥¥¥Intialization

- (id) init
{
    if(self = [super initWithWindowNibName:@"Document"]){
        [self setShouldCloseDocument:YES];
        [self setWindowFrameAutosaveName:@"Document"];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartUpMessage"
																object:self
																userInfo:[NSDictionary dictionaryWithObject:@"Preloading Catalog..." forKey:@"Message"]];
		[self preloadCatalog];

    }
    return self;
}

- (void) awakeFromNib
{
	ascendingSortingImage = [[NSImage imageNamed:@"NSAscendingSortIndicator"] retain];
    descendingSortingImage = [[NSImage imageNamed:@"NSDescendingSortIndicator"] retain];

    [self registerNotificationObservers];
    [groupView setGroup:[self group]];
    [self updateWindow];
        
    [outlineView setDoubleAction:@selector(doubleClick:)];
    [self securityStateChanged:nil];
    [self scaleFactorChanged:nil];
	
	if([[self group] count] == 0){
		[templates performSelector:@selector(showPanel) withObject:nil afterDelay:0];
	}
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[ascendingSortingImage release];
	[descendingSortingImage release];
    [super dealloc];
}

- (void) preloadCatalog
{
	[[ORCatalogController sharedCatalogController] window];
}

#pragma mark ¥¥¥Accessors

- (ORGroup *)group
{
    return [[self document] group];
}

- (ORGroupView *)groupView
{
    return [[self document] groupView];
}

- (NSTextField*) statusTextField
{
    return statusTextField;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
	
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(updateWindow)
                                                 name : ORGroupObjectsAdded
                                               object : nil];
	
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(updateWindow)
                                                 name : ORGroupObjectsRemoved
                                               object : nil];
	
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(updateWindow)
                                                 name : OROrcaObjectMoved
                                               object : nil];
	
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(updateWindow)
                                                 name : ORConnectionChanged
                                               object : nil];
	
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(statusTextChanged:)
                                                 name : ORStatusTextChangedNotification
                                               object : nil];
	
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(updateWindow)
                                                 name : ORRunModeChangedNotification
                                               object : nil];
	
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(updateWindow)
                                                 name : ORForceRedraw
                                               object : nil];
    
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(documentLockChanged:)
                                                 name : ORDocumentLock
                                                object: nil];
    
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(securityStateChanged:)
                                                 name : ORGlobalSecurityStateChanged
                                                object: nil];
    
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(scaleFactorChanged:)
                                                 name : ORDocumentScaleChangedNotification
                                                object: nil];

	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(remoteScaleFactorChanged:)
                                                 name : @"ScaleView"
                                                object: groupView];

    
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(numberLockedPagesChanged:)
                                                 name : ORSecurityNumberLockPagesChanged
                                                object: gSecurity];
    
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(windowOrderChanged:)
                                                 name : NSWindowDidBecomeKeyNotification
                                                object: nil];
    
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(showTemplates:)
                                                 name : @"ORShowTemplates"
                                                object: nil];
	
	[[NSNotificationCenter defaultCenter]addObserver : self
                                             selector : @selector(postLogChanged:)
                                                 name : ORPrefPostLogEnabledChanged
                                                object: nil];
    
	[[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(debuggingSessionChanged:)
                                                 name : ORDebuggingSessionChanged
                                               object : nil];
    
    [[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(lostFocus:)
                                                 name : NSWindowDidResignKeyNotification
                                               object : nil];

    [[NSNotificationCenter defaultCenter] addObserver : self
                                             selector : @selector(productionModeChanged:)
                                                 name : ORInProductionModeChanged
                                               object : nil];
}

- (void) updateWindow
{
    if(![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(updateWindow) withObject:nil waitUntilDone:YES];
        return;
    }
    [groupView setNeedsDisplay:YES];
    [self statusTextChanged:nil];
    [self productionModeChanged:nil];
    [self numberLockedPagesChanged:nil];
	[self postLogChanged:nil];
    [outlineView reloadData];
    [self debuggingSessionChanged:nil];
}

- (void) productionModeChanged:(NSNotification*)aNotification
{
    BOOL inProductionMode = [[ORGlobal sharedGlobal] inProductionMode];
    [productionModeMatrix selectCellWithTag:inProductionMode];
    [productionModeField setStringValue:inProductionMode?@"In Production":@""];
}

- (void) debuggingSessionChanged:(NSNotification*)aNotification
{
    NSUserDefaults* defaults 	= [NSUserDefaults standardUserDefaults];

    BOOL state = [[defaults objectForKey: ORDebuggingSessionState] boolValue];
    [debuggingStatusField setStringValue:state?@"Debugging Session":@""];
    
}

- (void) securityStateChanged:(NSNotification*)aNotification
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORDocumentLock to:secure];
    [documentLockButton setEnabled:secure];
    [lockAllButton setEnabled:secure && [gSecurity numberItemsUnlocked]];
}

- (void) documentLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORDocumentLock];
    [documentLockButton setState: locked];
    
}

- (void) lostFocus:(NSNotification*)aNotification
{
    //this was a bad idea... removed 1/28/14
    //id controller = [[aNotification object]windowController];
    //if([controller isKindOfClass:NSClassFromString(@"OrcaObjectController")]){
     //   [(OrcaObjectController*)controller endEditing];
   // }
   // [groupView setEnableIconControls:NO];
}

- (void) statusTextChanged:(NSNotification*)aNotification
{
    if([[self document] statusText])[[self statusTextField] setStringValue:[[self document] statusText]];		
}

- (void) scaleFactorChanged:(NSNotification*)aNotification
{
	[groupView setScalePercent:[[self document] scaleFactor]];
	[scaleFactorField setIntValue:[groupView scalePercent]];
}

- (void) remoteScaleFactorChanged:(NSNotification*)aNotification
{
	[[self document] setScaleFactor:[[[aNotification userInfo] objectForKey:@"ScaleFactor"] intValue]];
	[scaleFactorField setIntValue:[groupView scalePercent]];
}

- (void) showTemplates:(NSNotification*)aNotification
{
	if([[self group] count] == 0){
		[templates showPanel];
	}
}

- (void) postLogChanged:(NSNotification*)aNotification
{
    BOOL state = [[[NSUserDefaults standardUserDefaults] objectForKey:ORPrefPostLogEnabled] boolValue];
	if(state)	[logStatusField setStringValue:@""];
	else		[logStatusField setStringValue:@"NO Log Snapshots"];
}

- (void) windowOrderChanged:(NSNotification*)aNotification
{
    [[self document] windowMovedToFront:[[aNotification object]windowController]];
}

- (void) numberLockedPagesChanged:(NSNotification*)aNotification
{
    if([gSecurity globalSecurityEnabled]){
        int num = [gSecurity numberItemsUnlocked];
        if(num == 1)[lockStatusTextField setStringValue:[NSString stringWithFormat:@"%d item unlocked.",num]];
        else [lockStatusTextField setStringValue:[NSString stringWithFormat:@"%d items unlocked.",num]];
        [lockAllButton setEnabled:[gSecurity numberItemsUnlocked]];
    }
    else {
        [lockStatusTextField setStringValue:@"Security Disabled"];
        [lockAllButton setEnabled:NO];
    }
}

#pragma mark ¥¥¥Actions

- (IBAction) documentLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORDocumentLock to:[sender intValue] forWindow:[self window]];
}

#pragma mark ¥¥¥Toolbar

- (IBAction) openArchive:(NSToolbarItem*)item
{
    [[ORArchive sharedArchive] showWindow:self];
}

- (IBAction) statusLog:(NSToolbarItem*)item 
{
    [[ORStatusController sharedStatusController] showWindow:self];
}

- (IBAction) alarmMaster:(NSToolbarItem*)item 
{
    [[ORAlarmController sharedAlarmController] showWindow:self];
}

- (IBAction) openCatalog:(NSToolbarItem*)item 
{
    [[ORCatalogController sharedCatalogController] showWindow:self];
}

- (IBAction) openHelp:(NSToolbarItem*)item 
{
	[[(ORAppDelegate*)[NSApp delegate] helpCenter] showHelpCenter:nil];
}

- (IBAction) openPreferences:(NSToolbarItem*)item 
{
    [[ORPreferencesController sharedPreferencesController] showWindow:self];
}

- (IBAction) openHWWizard:(NSToolbarItem*)item 
{
    [[ORHWWizardController sharedHWWizardController] showWindow:self];
}

- (IBAction) openCommandCenter:(NSToolbarItem*)item 
{
    [[ORCommandCenterController sharedCommandCenterController] showWindow:self];
}

- (IBAction) openTaskMaster:(NSToolbarItem*)item 
{
    [(ORAppDelegate*)[NSApp delegate] showTaskMaster:self];
}

- (IBAction) openORCARootService:(NSToolbarItem*)item 
{
    [(ORAppDelegate*)[NSApp delegate] showORCARootServiceController:self];
}

- (IBAction) hardwareFinder:(NSToolbarItem*)item
{
    [[ORVXI11HardwareFinderController sharedVXI11HardwareFinderController] showWindow:self];
}

- (IBAction) printDocument:(id)sender
{
    NSRect cRect = [[self window] contentRectForFrameRect: [[self window] frame]];
    cRect.origin = NSZeroPoint;
    NSView*     borderView   = [[[self window] contentView] superview];
    NSData*     pdfData		 = [borderView dataWithPDFInsideRect: cRect];
    NSImage*    tempImage = [[NSImage alloc] initWithData: pdfData];
	
	NSPrintInfo* printInfo = [NSPrintInfo sharedPrintInfo];
	NSSize imageSize = [tempImage size];
	if(imageSize.width>imageSize.height){
		[printInfo setOrientation:NSPaperOrientationLandscape];
		[printInfo setHorizontalPagination: NSFitPagination];
	}
	else {
		[printInfo setOrientation:NSPaperOrientationPortrait];
		[printInfo setVerticalPagination: NSFitPagination];
	}
	
	[printInfo setHorizontallyCentered:NO];
	[printInfo setVerticallyCentered:NO];
	[printInfo setLeftMargin:72.0];
	[printInfo setRightMargin:72.0];
	[printInfo setTopMargin:72.0];
	[printInfo setBottomMargin:90.0];
	
	NSImageView* tempView = [[[NSImageView alloc] initWithFrame: NSMakeRect(0.0, 0.0, 8.5 * 72, 11.0 * 72)] autorelease];
	[tempView setImageAlignment:NSImageAlignTopLeft];
	[tempView setImage: tempImage];
	[tempImage release];
	NSPrintOperation* printOp = [NSPrintOperation printOperationWithView:tempView printInfo:printInfo];
#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MIN_ALLOWED
    [printOp setShowPanels:YES];
#endif
	[printOp runOperation];
}


- (IBAction) scaleFactorAction:(id)sender
{
    [[self document] setScaleFactor:[sender intValue]];
}

- (IBAction) lockAllAction:(id)sender
{
    if([gSecurity globalSecurityEnabled]){
        [gSecurity lockAll];
    }
}

- (IBAction) openProductionModePanel:(id)sender;
{
    [self productionModeChanged:nil];
    [[self window] beginSheet:productionModePanel completionHandler:nil];
}

- (IBAction) closeProductionModePanel:(id)sender;
{
    [productionModePanel orderOut:nil];
    [NSApp endSheet:productionModePanel];
}

- (IBAction) setProductionMode:(id)sender
{     
     NSInteger tag = [[productionModeMatrix selectedCell] tag];
     if(tag != [[ORGlobal sharedGlobal] inProductionMode]){
         [[ORGlobal sharedGlobal] setInProductionMode:tag];
     }
}

- (NSRect)windowWillUseStandardFrame:(NSWindow*)sender defaultFrame:(NSRect)defaultFrame
{
    return [groupView normalized] ;
}

#pragma mark ¥¥¥Data Source
- (id)   outlineView:(NSOutlineView *)outlineView child:(NSUInteger)index ofItem:(id)item
{
	if(item==nil)return [[self group] objectAtIndex:index];
	else {
		if([item isKindOfClass:NSClassFromString(@"ORGroup")]){
			return [[item orcaObjects] objectAtIndex:index];
		}
		else return nil;
	}
}

- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if(item==nil)return [[self group] count]>0;
	else if([item isKindOfClass:NSClassFromString(@"ORGroup")])return [[item orcaObjects] count]>0;
	else return NO;
}

- (NSInteger)  outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if(item==nil)return [[self group] count];
	else if([item isKindOfClass:NSClassFromString(@"ORGroup")])return [[item orcaObjects] count];
	else return 0;
}

- (id)  outlineView:(NSOutlineView *)outlineView  objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString* columnID =  [tableColumn identifier];
    return [item valueForKey:columnID];
}

- (void) outlineView:(NSOutlineView *)outlineView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn byItem:(id)item;
{
    [item setValue:anObject forKey:[aTableColumn identifier]];
}

- (IBAction) doubleClick:(id)sender
{
    [(OrcaObject*)[outlineView selectedItem] doDoubleClick:sender];
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
    [outlineView reloadData];
}

- (void) updateTableHeaderToMatchCurrentSort
{
    BOOL isDescending = [self sortIsDescending];
    NSString *key = [self sortColumn];
    NSArray *a = [outlineView tableColumns];
    NSTableColumn *column = [outlineView tableColumnWithIdentifier:key];
    NSUInteger i = [a count];
    
    while (i-- > 0) [outlineView setIndicatorImage:nil inTableColumn:[a objectAtIndex:i]];
    
    if (key) {
        [outlineView setIndicatorImage:(isDescending ? ascendingSortingImage:descendingSortingImage) inTableColumn:column];
        
        [outlineView setHighlightedTableColumn:column];
    }
    else {
        [outlineView setHighlightedTableColumn:nil];
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

- (BOOL)sortIsDescending
{
    return _sortIsDescending;
}

- (void)sort
{
    if(_sortIsDescending){
		[[[self group] orcaObjects] sortUsingFunction:sortListDnFunc context: _sortColumn];
	}
    else {
		[[[self group] orcaObjects] sortUsingFunction:sortListUpFunc context: _sortColumn];
	}
	NSEnumerator* mainEnummy = [[[self group] orcaObjects] objectEnumerator];
	OrcaObject* obj;
	while(obj = [mainEnummy nextObject]){
		if([obj isKindOfClass:NSClassFromString(@"ORGroup")]){
			NSMutableArray* theKids = [obj children];
			if(_sortIsDescending){
				[theKids sortUsingFunction:sortListDnFunc context: _sortColumn];
			}
			else {
				[theKids sortUsingFunction:sortListUpFunc context: _sortColumn];
			}
		}
	}
}

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray*)writeItems toPasteboard:(NSPasteboard*)pboard
{
    draggedNodes = [[NSMutableArray array] retain]; 
    NSEnumerator* e = [writeItems objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        if(ov == outlineView) {           //wrap objs from the total list into a readoutobj
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

- (NSArray*)draggedNodes
{ 
    return draggedNodes; 
}
- (void) dragDone
{
    [draggedNodes release];
    draggedNodes = nil;
}

@end
