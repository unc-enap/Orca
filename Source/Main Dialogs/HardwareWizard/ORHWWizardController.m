//
//  ORHWWizardController.m
//
//  Created by Mark Howe on Tue Dec 02 2003.
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


#import "ORHWWizardController.h"
#import "ORHWizActionController.h"
#import "ORHWizSelectionController.h"
#import "ORHWWizard.h"
#import "ORHWWizSelection.h"
#import "ORHWUndoManager.h"
#import "SynthesizeSingleton.h"
#import "ORDecoder.h"

NSString* ORHWWizCountsChangedNotification  = @"ORHWWizCountsChangedNotification";

NSString* ORHWWizGroupActionStarted         = @"ORHWWizGroupActionStarted";
NSString* ORHWWizGroupActionFinished        = @"ORHWWizGroupActionFinished";
NSString* ORHWWizSelectorActionStarted      = @"ORHWWizSelectorActionStarted";
NSString* ORHWWizSelectorActionFinished     = @"ORHWWizSelectorActionFinished";

NSString* ORHWWizActionFinalNotification    = @"ORHWWizActionFinalNotification";
NSString* ORHWWizardLock					= @"ORHWWizardLock";

#define kRestoreFailed @"Restore Failed"

@interface ORHWWizardController (private)
- (void) _delayedExecute;
- (void) _delayedRestoreAllFileRequest;
- (void) _executeActionController:(id) actionController;
- (void) _executeController:(id)actionController container:(id)container;
- (void) _restoreAll;
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _restoreAllSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _doItSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _doItWithMarkSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _clearMarksSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _clearUndoSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
@end

@implementation ORHWWizardController

SYNTHESIZE_SINGLETON_FOR_ORCLASS(HWWizardController);

+ (BOOL) exists
{
    return sharedHWWizardController != nil;
}

- (id) init
{
    if (self = [super initWithWindowNibName:@"HWWizard"]) {
        [self setWindowFrameAutosaveName:@"HardwareWizard"];
        [self setHwUndoManager: [ORHWUndoManager hwUndoManager]]; 
        [[self window] setTitle:@"Hardware Wizard"]; //a call to 'window' to force the nib to actually load.
    }
    return self;
}
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[selectionViewController setDelegate: nil];
	[selectionViewController release];
	
    [actionViewController setDelegate: nil];
    [actionViewController release];
	
    [actionControllers release];
    [selectionControllers release];
    [controlArray release];
    [objects release];
	[fileHeader release];
    [hwUndoManager release];
    
    [super dealloc];
}

- (void) awakeFromNib
{
    // Creating the actionViewController
    actionViewController = [[SubviewTableViewController controllerWithViewColumn: actionColumn] retain];
    [actionViewController setDelegate: self];
    
    selectionViewController = [[SubviewTableViewController controllerWithViewColumn: selectionColumn] retain];
    [selectionViewController setDelegate: self];
    
    
    // Setup cell for add column
    NSButtonCell *buttonCell = [[[NSButtonCell alloc] init] autorelease];
    [buttonCell setBezelStyle: NSCircularBezelStyle];
    [buttonCell setControlSize: NSSmallControlSize];
    [buttonCell setTarget: self];
    [buttonCell setAction: @selector(addAction:)];
    [addActionColumn setDataCell: buttonCell];
    
    // Setup cell for remove column
    buttonCell = [[buttonCell copy] autorelease];
    [buttonCell setAction: @selector(removeAction:)];
    [removeActionColumn setDataCell: buttonCell];
    
    buttonCell = [[buttonCell copy] autorelease];
    [buttonCell setAction: @selector(removeSelection:)];
    [removeSelectionColumn setDataCell: buttonCell];
    
    buttonCell = [[buttonCell copy] autorelease];
    [buttonCell setAction: @selector(addSelection:)];
    [addSelectionColumn setDataCell: buttonCell];
    
    // Start out with one row in the table view
    [[self undoManager] disableUndoRegistration];
    [self installObjects:[self scanForObjects]];
    [self addAction:nil];
    [self addSelection:nil];
    [[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];
    [self makeControlStruct:nil];
    
    [undoButton setEnabled:[hwUndoManager canUndo]];
    [redoButton setEnabled:[hwUndoManager canRedo]];
    [clearUndoButton setEnabled:[redoButton isEnabled] || [undoButton isEnabled]];
    
    [self marksChanged];
    [self countChanged:nil];
    [self securityStateChanged:nil];
    [self actionChanged:nil];
    
    [actionTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    [actionTableView setAllowsMultipleSelection:NO];
    
    [selectionTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    [selectionTableView setAllowsMultipleSelection:NO];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [[notification object] deselectAll:nil];
}

- (SubviewTableViewController *)actionViewController
{
    return actionViewController; 
}

- (void)setActionViewController:(SubviewTableViewController *)anActionViewController
{
    [anActionViewController retain];
    [actionViewController release];
    actionViewController = anActionViewController;
}


- (void)setActionControllers:(NSMutableArray *)anActionControllers
{
    [anActionControllers retain];
    [actionControllers release];
    actionControllers = anActionControllers;
}

- (SubviewTableViewController *)selectionViewController
{
    return selectionViewController; 
}

- (void) setFileHeader:(NSMutableDictionary*)aHeader
{
	[aHeader retain];
	[fileHeader release];
	fileHeader = aHeader;
}

- (void)setSelectionViewController:(SubviewTableViewController *)aSelectionViewController
{
    [aSelectionViewController retain];
    [selectionViewController release];
    selectionViewController = aSelectionViewController;
}

- (void)setSelectionControllers:(NSMutableArray *)aSelectionControllers
{
    [aSelectionControllers retain];
    [selectionControllers release];
    selectionControllers = aSelectionControllers;
}
- (NSMutableArray *) actionControllers
{
    if (actionControllers == nil) {
        actionControllers = [[NSMutableArray alloc] init];
    }
    
    return actionControllers;
}

- (NSMutableArray *) selectionControllers
{
    if (selectionControllers == nil) {
        selectionControllers = [[NSMutableArray alloc] init];
    }
    
    return selectionControllers;
}

- (NSDictionary *)objects
{
    return objects; 
}

- (void)setObjects:(NSMutableDictionary *)anObjects
{
    [anObjects retain];
    [objects release];
    objects = anObjects;
}

- (int)objectTag
{
    return objectTag;
}

- (void)setObjectTag:(int)anObjectTag
{
    objectTag = anObjectTag;
}

- (NSMutableArray *)controlArray
{
    return controlArray; 
}

- (void)setControlArray:(NSMutableArray *)aControlArray
{
    [aControlArray retain];
    [controlArray release];
    controlArray = aControlArray;
}

- (BOOL) useMark
{
    return useMark;
}

- (void) setUseMark: (BOOL) flag
{
    useMark = flag;
}

- (short)containerCount {
    
    return containerCount;
}

- (void)setContainerCount:(short)aContainerCount {
    containerCount = aContainerCount;
    [[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORHWWizCountsChangedNotification 
	 object: self];
}

- (short)objectCount {
    
    return objectCount;
}

- (void)setObjectCount:(short)anObjectCount {
    objectCount = anObjectCount;
    [[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORHWWizCountsChangedNotification 
	 object: self];
}

- (short)chanCount {
    
    return chanCount;
}

- (void)setChanCount:(short)aChanCount 
{
    chanCount = aChanCount;
    [[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORHWWizCountsChangedNotification 
	 object: self];
}

- (ORHWUndoManager *) hwUndoManager
{
    return hwUndoManager; 
}

- (void) setHwUndoManager: (ORHWUndoManager *) aHwUndoManager
{
    [aHwUndoManager retain];
    [hwUndoManager release];
    hwUndoManager = aHwUndoManager;
}

- (NSUndoManager *)undoManager
{
    return [[(ORAppDelegate*)[NSApp delegate]document]  undoManager];
}

- (void) notOkToContinue
{
    okToContinue = false;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsAdded:)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsRemoved:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectTagChanged:)
                         name : ORTagChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(makeControlStruct:)
                         name : ORSelectionControllerSelectionChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(makeControlStruct:)
                         name : ORSelectionControllerSelectionValueChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(countChanged:)
                         name : ORHWWizCountsChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(statusTextChanged:)
                         name : ORStatusTextChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(wizardLockChanged:)
                         name : ORHWWizardLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(securityStateChanged:)
                         name : ORGlobalSecurityStateChanged
                        object: nil];
    
    [notifyCenter addObserver : self
                      selector: @selector(actionChanged:)
                          name: ORActionControllerActionChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(wizardLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(documentClosed:)
                         name : ORDocumentClosedNotification
                       object : nil];
}

- (void) securityStateChanged:(NSNotification*)aNotification
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORHWWizardLock to:secure];
    [wizardLockButton setEnabled:secure];
}

- (void) documentClosed:(NSNotification*)aNotification
{
	[[self window] performClose:self];
}

- (void) wizardLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORHWWizardLock];
    BOOL locked = [gSecurity isLocked:ORHWWizardLock];
	
    [wizardLockButton setState: locked];
    [doitButton setEnabled:!lockedOrRunningMaintenance && objectsAvailiable];
    [markAnDoitButton setEnabled:!lockedOrRunningMaintenance && objectsAvailiable];
	[objectPU setEnabled:objectsAvailiable];
    [advancedButton setEnabled:!lockedOrRunningMaintenance];
    [restoreAllButton setEnabled:!lockedOrRunningMaintenance && objectsAvailiable];
    
    if(![advancedButton isEnabled]){
        [advancedDrawer close];
    }
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORHWWizardLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
    
}

- (void) statusTextChanged:(NSNotification*)aNotification
{
    if([[(ORAppDelegate*)[NSApp delegate] document] statusText])[statusTextField setStringValue:[[(ORAppDelegate*)[NSApp delegate] document] statusText]];		
}

- (void) actionChanged:(NSNotification*)aNotification
{
    [self performSelector:@selector(setFileSelectionText) withObject:nil afterDelay:.1];
}

- (void) setFileSelectionText
{
    NSEnumerator* e = [actionControllers objectEnumerator];
    id actionController;
    while(actionController = [e nextObject]){
        if([actionController actionTag] == kAction_Restore || [actionController actionTag] == kAction_Restore_All){
            [fileSelectionTextField setStringValue:@"A Run File will be requested."];
            return;
        }
    }
    [fileSelectionTextField setStringValue:@""];
}


- (void) objectsAdded:(NSNotification*)aNote
{
    NSArray* theConformingObjects = [self conformingObjectsInArray:[[aNote userInfo] objectForKey:ORGroupObjectList]];
    if([[objects allKeys] count]){
        if([theConformingObjects count]){
            //are ALL of the objects found already in our list?
            NSEnumerator* e = [theConformingObjects objectEnumerator];
            id obj;
            while(obj = [e nextObject]){
                NSString* theClassName = NSStringFromClass([obj class]);
                if([objects objectForKey:theClassName] == nil){
                    //add one that was NOT already in the list.
                    [objects setObject:theClassName forKey:theClassName];
                    [objectPU addItemWithTitle:theClassName];
                }
            }
        }
    }
    else {
        //we had nothing in our list so add all conforming objects.
        [self installObjects:theConformingObjects];
		objectTag = -1; //force a reselect
		[self selectObject:nil];
    }
	if([theConformingObjects count]) objectsAvailiable = YES;
	
    [self clearUndoStacks];
    [self makeControlStruct:nil];
	
	[self wizardLockChanged:aNote];
}

- (void) marksChanged
{
    if([hwUndoManager numberOfMarks] == 0){
        [marksPU removeAllItems];
        [marksPU setEnabled:NO];
        [clearMarksButton setEnabled:NO];
        [goToMarkButton setEnabled:NO];
    }
    else {
        [marksPU setEnabled:YES];
        [clearMarksButton setEnabled:YES];
        [goToMarkButton setEnabled:YES];
        int selectedItem = [marksPU indexOfSelectedItem];
        [marksPU removeAllItems];
        int n = [hwUndoManager numberOfMarks];
        int i;
        for(i=0;i<n;i++){
            [marksPU insertItemWithTitle:[NSString stringWithFormat:@"%d",i] atIndex:i];
        }
        if(selectedItem != -1)[marksPU selectItemAtIndex:selectedItem];
        else [marksPU selectItemAtIndex:0];
    }
}

- (void) countChanged:(NSNotification*)aNote
{
    if((aNote == nil || [aNote object] == self )){
        [chanTextField setIntValue:[self chanCount]];
        
        BOOL hasContainer = NO;
        NSArray* selectionOptions = [self selectedObjectsSelectionOptions];
        NSEnumerator* e = [selectionOptions objectEnumerator];
        ORHWWizSelection* selection;
        while(selection = [e nextObject]){
            if([selection level] == kContainerLevel){
				if(![[selection name] isEqualToString:@"---"]){
					[containerLabel setStringValue:[NSMutableString stringWithFormat:@"%@s:",[selection name]]];
				}
				else {
					[containerLabel setStringValue:[NSMutableString stringWithFormat:@"%@ :",[selection name]]];
				}
                [containerTextField setIntValue:[self containerCount]];
                hasContainer = YES;
            }
            else if([selection level] == kObjectLevel){
                [objectLabel setStringValue:[NSMutableString stringWithFormat:@"%@s:",[selection name]]];
                [objectTextField setIntValue:[self objectCount]];
            }
        }
        if(!hasContainer){
            [containerLabel setStringValue:@"Top Level"];
            [containerTextField  setStringValue:@""];
        }
    }
}

- (void) objectTagChanged:(NSNotification*)aNote
{
    if([NSStringFromClass([[aNote object] class]) isEqualToString:[[objectPU selectedItem] title]]){
        [self makeControlStruct:aNote];
    }
}

- (void) objectsRemoved:(NSNotification*)aNote
{
    NSArray* theObjects = [self scanForObjects];
    NSEnumerator* e = [theObjects objectEnumerator];
    NSMutableDictionary* objectsToRemove = [NSMutableDictionary dictionaryWithDictionary:objects];
    id obj;
    while(obj = [e nextObject]){
        NSString* theClassName = NSStringFromClass([obj class]);
        id objInBoth = [objects objectForKey:theClassName];
        if(objInBoth!=nil){
            [objectsToRemove removeObjectForKey:theClassName];
        }
    }
    
    e = [objectsToRemove keyEnumerator];
    id key;
    while(key = [e nextObject]){
        [objects removeObjectForKey:key];
        [objectPU removeItemWithTitle:key];
    }
    
    [self clearUndoStacks];
    [self makeControlStruct:nil];
	objectsAvailiable = [theObjects count] != 0;
	if(!objectsAvailiable) {
		[objectPU addItemWithTitle:@"None Available"];
		objectTag = -1; //force a reselect
		[self selectObject:nil];
	}
	[self wizardLockChanged:aNote];
}


- (void) addActionController:(id) obj atIndex:(int) index
{
    if (index < [actionControllers count]-1) [[self actionControllers] insertObject: obj atIndex: (index + 1)];
    else	    [[self actionControllers] addObject: obj];
    [actionViewController reloadTableView];
    [self adjustActionSize:1];
    
    [[[self undoManager] prepareWithInvocationTarget:self] removeActionControllerAtIndex:index+1];
}

- (void) removeActionControllerAtIndex:(int) index
{
    id obj = [[self actionControllers] objectAtIndex:index];
    [[[self undoManager] prepareWithInvocationTarget:self] addActionController:obj atIndex:index-1];
    [[self actionControllers] removeObjectAtIndex: index];
    [actionViewController reloadTableView];
    [self adjustActionSize:-1];
}


- (void) addSelectionController:(id) obj atIndex:(int) index
{
    if (index < [selectionControllers count]-1) [[self selectionControllers] insertObject: obj atIndex: (index + 1)];
    else	    [[self selectionControllers] addObject: obj];
    [selectionViewController reloadTableView];
    [self adjustSelectionSize:1];
    [[[self undoManager] prepareWithInvocationTarget:self] removeSelectionControllerAtIndex:index+1];
}

- (void) removeSelectionControllerAtIndex:(int) index
{
    id obj = [[self selectionControllers] objectAtIndex:index];
    [[[self undoManager] prepareWithInvocationTarget:self] addSelectionController:obj atIndex:index-1];
    [[self selectionControllers] removeObjectAtIndex: index];
    [selectionViewController reloadTableView];
    [self adjustSelectionSize:-1];
}

- (void) adjustActionSize:(int)amount
{
    NSRect aRect = [actionView frame];    
    float delta = amount * ([actionTableView rowHeight]+2);
    aRect.size.height += delta;
    //aRect.origin.y -= delta;
    [actionView setFrame:aRect];  
    NSRect windowFrame = [[self window] frame];
    windowFrame.size.height += delta;
    windowFrame.origin.y -= delta;
    [[self window] setFrame:windowFrame display:YES];
}

- (void) adjustSelectionSize:(int)amount
{
    NSRect aRect = [selectionView frame];    
    float delta = amount * ([selectionTableView rowHeight]+2);
    aRect.size.height += delta;
    //aRect.origin.y -= delta;
    [selectionView setFrame:aRect];  
    
    NSPoint actionOrigin = [actionView frame].origin; 
    actionOrigin.y += delta;   
    [actionView setFrameOrigin:actionOrigin];  
    
    
    NSRect windowFrame = [[self window] frame];
    windowFrame.size.height += delta;
    windowFrame.origin.y -= delta;
    [[self window] setFrame:windowFrame display:YES];
}

- (IBAction) doItWithMark:(id)sender
{
    if(![[self window] makeFirstResponder:[self window]]){
	    [[self window] endEditingFor:nil];		
    }
    
    NSString* s = [NSString stringWithFormat:@"Hardware Wizard About to Run After Marking the CURRENT State!\n\nYou will be able to return to the CURRENT state using the return point marked: %d",[hwUndoManager numberOfMarks]];
    
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s];
    [alert setInformativeText:[NSString stringWithFormat:@"Really Execute This HardwareWizard Set on %i channels?",chanCount]];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if(result == NSAlertFirstButtonReturn){
            [self setUseMark:YES];
            [self makeControlStruct:nil];
            [self performSelector:@selector(_delayedExecute) withObject:nil afterDelay:.1];
        }      }];
#else
    NSBeginAlertSheet(s,
                      @"Yes",
                      @"Cancel",
                      nil,[self window],
                      self,
                      @selector(_doItWithMarkSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,[NSString stringWithFormat:@"Really Execute This HardwareWizard Set on %i channels?",chanCount]);
#endif
}

- (IBAction) doIt:(id) sender
{
    if(![[self window] makeFirstResponder:[self window]]){
	    [[self window] endEditingFor:nil];		
    }
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Hardware Wizard About to Run!"];
    [alert setInformativeText:[NSString stringWithFormat:@"Really Execute This HardwareWizard Set on %i channels?",chanCount]];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [self setUseMark:NO];
            [self makeControlStruct:nil];
            [self performSelector:@selector(_delayedExecute) withObject:nil afterDelay:.1];
         }
    }];
#else
    NSBeginAlertSheet(@"Hardware Wizard About to Run!",
                      @"Yes",
                      @"Cancel",
                      nil,[self window],
                      self,
                      @selector(_doItSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,[NSString stringWithFormat:@"Really Execute This HardwareWizard Set on %i channels?",chanCount]);
#endif
    
}

- (BOOL) needToRestore
{
    NSEnumerator* e = [actionControllers objectEnumerator];
    id actionController;
    while(actionController = [e nextObject]){
        if([actionController actionTag] == kAction_Restore || [actionController actionTag] == kAction_Restore_All){
            return YES;
        }
    }
    return NO;    
}

- (void) askForFileAndExecute
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Restore"];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSFileHandle* theFile = [NSFileHandle fileHandleForReadingAtPath:[[openPanel URL]path]];
            [self setFileHeader:[ORDecoder readHeader:theFile]];
            [self executeControlStruct];
            [theFile closeFile];
        }
    }];
}


- (IBAction) undoToMark:(id) sender
{
    [hwUndoManager undoToMark:[marksPU indexOfSelectedItem]];
    [undoButton setEnabled:[hwUndoManager canUndo]];
    [redoButton setEnabled:[hwUndoManager canRedo]];
}

- (IBAction) clearMarks:(id) sender
{
    if(![[self window] makeFirstResponder:[self window]]){
	    [[self window] endEditingFor:nil];		
    }
    
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Clearing ALL return points!"];
    [alert setInformativeText:@"Really Clear them? You will not be able to undo to the mark points."];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [hwUndoManager clearMarks];
            [self marksChanged];
       }
    }];
#else
    NSBeginAlertSheet(@"Clearing ALL return points!",
                      @"Yes",
                      @"Cancel",
                      nil,[self window],
                      self,
                      @selector(_clearMarksSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really Clear them? You will not be able to undo to the mark points.");
#endif
}


- (IBAction) clearUndo:(id) sender
{
    if(![[self window] makeFirstResponder:[self window]]){
	    [[self window] endEditingFor:nil];		
    }
    
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Clearing Hardware Wizard Undo/Redo Stack!"];
    [alert setInformativeText:@"Really clear them? You will not be able to undo."];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [self clearUndoStacks];
       }
    }];
#else
    NSBeginAlertSheet(@"Clearing Hardware Wizard Undo/Redo Stack!",
                      @"Yes",
                      @"Cancel",
                      nil,[self window],
                      self,
                      @selector(_clearUndoSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really clear them? You will not be able to undo.");
#endif
}

- (void) clearUndoStacks
{
    [hwUndoManager clearUndoList];
    [undoButton setEnabled:[hwUndoManager canUndo]];
    [redoButton setEnabled:[hwUndoManager canRedo]];
    [clearUndoButton setEnabled:NO];
}

- (IBAction) undo:(id) sender
{
    [hwUndoManager undo];
    [undoButton setEnabled:[hwUndoManager canUndo]];
    [redoButton setEnabled:[hwUndoManager canRedo]];
    [clearUndoButton setEnabled:[redoButton isEnabled] || [undoButton isEnabled]];
    
}

- (IBAction) redo:(id) sender
{
    [hwUndoManager redo];
    [undoButton setEnabled:[hwUndoManager canUndo]];
    [redoButton setEnabled:[hwUndoManager canRedo]];
    [clearUndoButton setEnabled:[redoButton isEnabled] || [undoButton isEnabled]];
    
}

- (IBAction) wizardLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORHWWizardLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) saveDocument:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocumentAs:sender];
}

- (IBAction) selectObject:(id) sender
{
    if([sender indexOfSelectedItem] != objectTag){
        NSArray* parameters = [self selectedObjectsParameters];
        NSEnumerator* e = [actionControllers objectEnumerator];
        ORHWizActionController* actionCon;
        while(actionCon = [e nextObject]){
            [actionCon installParamArray:parameters];
        }
        
        NSArray* selectionOptions = [self selectedObjectsSelectionOptions];
        e = [selectionControllers objectEnumerator];
        ORHWizSelectionController* selectionCon;
        while(selectionCon = [e nextObject]){
            [selectionCon installSelectionArray:selectionOptions];
        }
        objectTag = [sender indexOfSelectedItem];
        
        [self makeControlStruct:nil];
        
        e = [selectionControllers objectEnumerator];
        while(selectionCon = [e nextObject]){
            [selectionCon setupSelection];
        }
    }
}

- (IBAction) addAction:(id) sender
{
    [[self undoManager] setActionName:@"Add HW Wizard Action"];
    ORHWizActionController* actionCon = [ORHWizActionController controller];
    [self addActionController: actionCon atIndex: [actionTableView clickedRow]];
    [actionCon installParamArray:[self selectedObjectsParameters]];
}

- (IBAction) removeAction:(id) sender
{
    [[self undoManager] setActionName:@"Remove HW Wizard Action"];
    [self removeActionControllerAtIndex: [actionTableView clickedRow]];
}

- (IBAction) addSelection:(id) sender
{
    [[self undoManager] setActionName:@"Add HW Wizard Selection"];
    ORHWizSelectionController* selectionCon = [ORHWizSelectionController controller];
    [self addSelectionController: selectionCon atIndex: [selectionTableView clickedRow]];
    [selectionCon installSelectionArray:[self selectedObjectsSelectionOptions]];
    [self makeControlStruct:nil];
}

- (IBAction) removeSelection:(id) sender
{ 
    [[self undoManager] setActionName:@"Remove HW Wizard Selection"];
    [self removeSelectionControllerAtIndex: [selectionTableView clickedRow]];
    [self makeControlStruct:nil];
}



- (BOOL) tableView:(NSTableView *) tableView canRemoveRow:(int) row
{
    return ([self numberOfRowsInTableView: tableView] > 1);
}

- (BOOL) tableView:(NSTableView *) tableView canAddRow:(int) row
{
    return ([self numberOfRowsInTableView: tableView] < 10);
}

// Methods from SubviewTableViewDataSourceProtocol

- (NSView *) tableView:(NSTableView *) tableView viewForRow:(int) row
{
    if(tableView == actionTableView){
        return [[[self actionControllers] objectAtIndex: row] view];
    }
    else {
        return [[[self selectionControllers] objectAtIndex: row] view];
    }
}

// Methods from NSTableViewDelegate category


- (void) tableView:(NSTableView *) tableView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tableColumn row:(int) row
{
    if(tableView == actionTableView){
        if (tableColumn == removeActionColumn) {
            [cell setTitle: @"-"];
            [cell setEnabled: ([self tableView: tableView canRemoveRow: row])];
            [cell setTag:row];
        }
        else if (tableColumn == addActionColumn) {
            [cell setTitle: @"+"];
            [cell setEnabled: ([self tableView: tableView canAddRow: row])];
            [cell setTag:row];
        }
    }
    else {
        [[selectionControllers objectAtIndex:row] enableForRow:row];
        if (tableColumn == removeSelectionColumn) {
            [cell setTitle: @"-"];
            [cell setEnabled: ([self tableView: tableView canRemoveRow: row])];
            [cell setTag:row];
        }
        else if (tableColumn == addSelectionColumn) {
            [cell setTitle: @"+"];
            [cell setEnabled: ([self tableView: tableView canAddRow: row])];
            [cell setTag:row];
        }
    }
}

// Methods from NSTableDataSource protocol

- (int) numberOfRowsInTableView:(NSTableView *) tableView
{
    if(tableView == actionTableView)return [[self actionControllers] count];
    else return [[self selectionControllers] count];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [self  undoManager];
}

- (NSArray*) scanForObjects
{
    return [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsConformingTo:@protocol(ORHWWizard)];
}

- (void) installObjects:(NSArray*) theObjects
{
    NSEnumerator* e = [theObjects objectEnumerator];
    id obj;
    if(!objects){
        [self setObjects:[NSMutableDictionary dictionary]];
    }
    [objectPU removeAllItems];
    if([theObjects count]){
        while(obj = [e nextObject]){
            NSString* theClassName = NSStringFromClass([obj class]);
            [objects setObject:theClassName forKey:theClassName];
        }
        [objectPU addItemsWithTitles:[objects allKeys]];
		objectsAvailiable = YES;
    }
    else {
        [objectPU addItemWithTitle:@"None Available"];
		objectsAvailiable = NO;
    }
}

- (NSArray*) selectedObjectsParameters
{
    if([[objects allKeys]count]){
        //create a temp proxy of an obj that conforms to the ORWWizard protocol.
        NSObject<ORHWWizard>* obj = [[[NSClassFromString([[objectPU selectedItem] title]) alloc]init] autorelease];
		if(!obj) return [self defaultEmptyParameterArray];
        else return [obj wizardParameters];
    }
    else return [self defaultEmptyParameterArray];
}

- (NSArray*) selectedObjectsSelectionOptions
{
    if([[objects allKeys]count]){
        //create a temp proxy of an obj that conforms to the ORWWizard protocol.
        NSObject<ORHWWizard>* obj = [[[NSClassFromString([[objectPU selectedItem] title]) alloc]init] autorelease];
        return [obj wizardSelections];
    }
    else return [self defaultEmptySelectionArray];
}


- (NSArray*) defaultEmptyParameterArray
{
    ORHWWizParam* p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"---"];
    [p setUnits:@"--"];
    return [NSArray arrayWithObject:p];
}

- (NSArray*) defaultEmptySelectionArray
{
    return [NSArray arrayWithObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"---" className:nil]];
}

- (NSArray*) conformingObjectsInArray:(NSArray*)anArray
{
    NSMutableArray* conformingObjects = [NSMutableArray array];
    NSEnumerator* e = [anArray objectEnumerator];
    id anObject;
    while(anObject = [e nextObject]){
        if([anObject conformsToProtocol:@protocol(ORHWWizard)]){
            [conformingObjects addObject:anObject];
        }
    }
    return conformingObjects;
}

- (void) makeControlStruct:(NSNotification*)aNote
{
    
    ORHWWizSelection* containerSelection = [self getSelectionAtLevel:kContainerLevel];
    ORHWWizSelection* objSelection       = [self getSelectionAtLevel:kObjectLevel];
    
    Class containerClass    = [containerSelection selectionClass];
    Class objectClass       = [objSelection selectionClass];
    int i;
    containerExists = (containerSelection != nil);
    
    //set up the container level
    //fill with nil objects at start, will fill in below.
    NSArray* containers = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:containerClass]; 
    [self setControlArray:[NSMutableArray array]];
    int maxContainerTag = 0;
    for( id containerObj in containers){
        if([containerObj stationNumber]>maxContainerTag){
            maxContainerTag = [containerObj stationNumber];
        }
    }
    
    for(i=0;i<maxContainerTag+1;i++){
        [controlArray addObject:[NSNull null]];
    }
    if(![controlArray count]){
        [controlArray addObject:[NSNull null]]; //make sure there is at least one.
    }
    
    if([containers count]){
        
        for(id containerObj in containers){
            int containerTag = [containerObj stationNumber];
            [controlArray replaceObjectAtIndex:containerTag withObject:[NSMutableArray array]]; //insert the container object
			//set up this container's objects
            NSArray* objectList = [containerObj collectObjectsOfClass:objectClass]; 
            [self addObjectList:objectList atIndex:containerTag];
        }
    }
    else {
        int containerTag = 0;
        [controlArray replaceObjectAtIndex:containerTag withObject:[NSMutableArray array]]; //insert the container object
		//set up this container's objects
        NSArray* objectList = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:objectClass]; 
        [self addObjectList:objectList atIndex:containerTag];
        
    }
    
    [self setUpMasks:nil];
    
}
- (void) countChannels
{
    int channelCount=0;
    int objCount=0;
    int conCount = 0;
    NSEnumerator* containerEnum = [controlArray objectEnumerator];
    id container;
    BOOL atLeastOne ;
    while(container = [containerEnum nextObject]){
        if([container respondsToSelector:@selector(objectEnumerator)]){
            NSEnumerator* objectEnum = [container objectEnumerator];
            id wizObject;
            atLeastOne = NO;
            while(wizObject = [objectEnum nextObject]){
                if([wizObject respondsToSelector:@selector(numberOfChannels)]){
                    int chan;
                    unsigned long mask = [wizObject wizMask];
                    BOOL atLeastOneChan = NO;
                    for(chan=0;chan<[wizObject numberOfChannels];chan++){
                        if(mask & (1<<chan)){
                            channelCount++;
                            atLeastOneChan = YES;
                        }
                    }
                    if(atLeastOneChan){
                        atLeastOne = YES;
                        objCount++;
                    }
                }
            }
            if(atLeastOne)conCount++;
        }
        
    }
    [self setContainerCount:conCount]; 
    [self setObjectCount:objCount];
    [self setChanCount:channelCount];
}

- (ORHWWizSelection*) getSelectionAtLevel:(eSelectionLevel)selectionLevel
{
    NSArray* selectionOptions = [self selectedObjectsSelectionOptions];
    NSEnumerator* e = [selectionOptions objectEnumerator];
    ORHWWizSelection* selection;
    while(selection = [e nextObject]){
        if([selection level] == selectionLevel){
            return selection;
        }
    }
    return nil;
}

- (void) addObjectList:(NSArray*)objectList atIndex:(int)containerTag
{
    ORHWWizSelection* objSelection       = [self getSelectionAtLevel:kObjectLevel];
    //set up this container's objects
    int i;
    [controlArray addObject:[NSMutableArray array]];
    id currentContainer = [controlArray objectAtIndex:containerTag];
    for(i=0;i<=[objSelection maxValue];i++){
        [currentContainer addObject:[NSNull null]];
    }
    
    OrcaObject<ORHWWizard>* obj;
    NSEnumerator* e = [objectList objectEnumerator];
    while(obj = [e nextObject]){
        [currentContainer replaceObjectAtIndex:[obj stationNumber] withObject:[ORHWWizObj hwWizObject:obj]];
    }
}

- (void) setUpMasks:(NSNotification*)aNote
{
    int i;
    unsigned long       mask;
    eSelectionLogic	selectionLogic;
    eSelectionLevel	selectionLevel;
    eSelectionAction 	selectionAction;
    BOOL                firstObject = 1;
#define kMaskAllChannels 0xffffffff
#define kMaskChannel1 0x1
#define kMaxChannels 32
    
    /*
     ** Step 1) Create a mask of all channels to indicate which ones we want to change
     */
    /* set all channels on to start */
    [self setMaskBits];
    
    /* figure out what channels we want to change */
    NSEnumerator* selectionEnum = [selectionControllers objectEnumerator];
    ORHWizSelectionController* selectionController;
    while(selectionController = [selectionEnum nextObject]) {
        
        /* get the search menu selections */
        int levelOffset = containerExists?0:1;
        selectionLogic      = [selectionController logicalTag];
        selectionLevel      = [selectionController objTag]+levelOffset;
        selectionAction     = [selectionController selectionTag];
        
        /* must use "AND" logic for first object */
        if (firstObject) {
            selectionLogic = kSearchLogic_And;
            firstObject = false;
        }
        /* get the search edit value */
        long searchValue = [selectionController selectionValue];
        /* initialize channel mask */
        mask = 0;
        
        /* modify search parameters for special cases */
        switch (selectionAction) {
            case kSearchAction_IsAnything:
                /* change default mask to all channels on */
                mask = kMaskAllChannels;
                /* reset search object so our mask doesn't get changed */
                selectionLevel = kSelectionLevel_Null;
				break;
				
            case kSearchAction_IsMultipleOf:
                /* avoid dividing by zero -- change to kSearchAction_Is */
                if (!searchValue) selectionAction = kSearchAction_Is;
				break;
				
            case kSearchAction_IsNotMultipleOf:
                /* avoid dividing by zero -- change to kSearchAction_IsNot */
                if (!searchValue) selectionAction = kSearchAction_IsNot;
				break;
				
            default:
				break;
        }
        
        /* setup hardware parameters for searches independent of container and object level */
        int     count, shift = 0;
        unsigned long mask1 = 0;
        switch (selectionLevel) {
            case kChannelLevel:
                count = kMaxChannels;
                shift = 1;		// shift  channel mask 1 bit for next channel
                mask1 = kMaskChannel1;	// mask for firstchannel
				break;
				
            default:
                count = 0;
				break;
        }
        
        /* set default mask for searches that are independent of crate and slot number */
        if (count) switch (selectionAction) {
            case kSearchAction_Is:
                mask = mask1 << (searchValue * shift);
				break;
				
            case kSearchAction_IsNot:
                mask = ~(mask1 << (searchValue * shift));
				break;
				
            case kSearchAction_IsGreatherThan:
                for (i=searchValue+1; i<count; ++i) mask |= (mask1 << (i * shift));
				break;
				
            case kSearchAction_IsLessThan:
                for (i=searchValue-1; i>=0; --i) mask |= (mask1 << (i * shift));
				break;
				
            case kSearchAction_IsMultipleOf:
                for (i=0; i<count; ++i) {
                    if (!(i % searchValue)) mask |= (mask1 << (i * shift));
                }
				break;
				
            case kSearchAction_IsNotMultipleOf:
                for (i=0; i<count; ++i) {
                    if (i % searchValue) mask |= (mask1 << (i * shift));
                }
				break;
				
            default:
				break;
        }
		
		NSEnumerator* containerEnum = [controlArray objectEnumerator];
        id container;
        while(container = [containerEnum nextObject]){
            if([container respondsToSelector:@selector(objectEnumerator)]){
                NSEnumerator* objectEnum = [container objectEnumerator];
                id wizObject;
                while(wizObject = [objectEnum nextObject]){
                    if([wizObject respondsToSelector:@selector(target)]){
                        
                        short	index = 0, indexValid;
                        
                        /* set index for search keys that change with container and object number */
                        switch (selectionLevel) {
                            case kContainerLevel:
                                index = [controlArray indexOfObject:container];
                                indexValid = true;
								break;
								
                            case kObjectLevel:
                                index = [[wizObject target] stationNumber];
                                indexValid = true;
								break;
								
                            default:
                                indexValid = false;
								break;
                        }
                        
                        /* set the channel mask for search keys that change with slot and crate number */
                        if (indexValid) {
                            mask = 0L;		// reset mask to zero
                            switch (selectionAction) {
                                case kSearchAction_Is:
                                    if (index == searchValue) mask = kMaskAllChannels;
									break;
                                    
                                case kSearchAction_IsNot:
                                    if (index != searchValue) mask = kMaskAllChannels;
									break;
                                    
                                case kSearchAction_IsGreatherThan:
                                    if (index > searchValue) mask = kMaskAllChannels;
									break;
                                    
                                case kSearchAction_IsLessThan:
                                    if (index < searchValue) mask = kMaskAllChannels;
									break;
                                    
                                case kSearchAction_IsMultipleOf:
                                    if (!(index % searchValue)) mask = kMaskAllChannels;
									break;
                                    
                                case kSearchAction_IsNotMultipleOf:
                                    if (index % searchValue) mask = kMaskAllChannels;
									break;
									
                                default:
									break;
                            }
                        }
                        
                        /* finally, combine this mask with the current mask for this FEC */
                        unsigned long theFinalMask = [wizObject wizMask];
                        switch (selectionLogic) {
                            case kSearchLogic_And:
                                /* combine the channel masks with a logical AND and save in array */
                                theFinalMask &= mask;
                                [wizObject setWizMask:theFinalMask];	// reset bits of unselected channels
								break;
								
                            case kSearchLogic_Or:
                                /* combine the channel masks with a logical OR and save in array */
                                theFinalMask |= mask;	// set bits of selected channels
                                [wizObject setWizMask:theFinalMask];	// reset bits of unselected channels
                                
								break;
                        }
                        
                    }	// end slot loop
                }	// end crate loop
            }
        }	// end loop through search groups
    }
    [self countChannels];
    
}
- (void) setMaskBits
{
    NSEnumerator* containerEnum = [controlArray objectEnumerator];
    id container;
    while(container = [containerEnum nextObject]){
        if([container respondsToSelector:@selector(objectEnumerator)]){
            NSEnumerator* objectEnum = [container objectEnumerator];
            id wizObject;
            while(wizObject = [objectEnum nextObject]){
                if([wizObject respondsToSelector:@selector(target)]){
                    [wizObject setWizMask:0xffffffff];
                }
            }
        }
    }
}

- (void) executeControlStruct
{
    okToContinue = true;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHWWizGroupActionStarted object: self];

    // continue the execution unless interrupted by one of our notification listeners
    // (in which case they may continue execution themselves if they want)
    if (okToContinue) {
        [self continueExecuteControlStruct];
    }
}

- (void) continueExecuteControlStruct
{
    [hwUndoManager startNewUndoGroup];

    for(id actionController in actionControllers){
        [self _executeActionController:actionController];
	}
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHWWizGroupActionFinished object: self];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHWWizActionFinalNotification object: self];
    
    if(useMark){
        [hwUndoManager setMark];
        [self marksChanged];
        NSLog(@"Hardware Wizard executed with return mark = %d\n",[hwUndoManager numberOfMarks]-1);
    }
    else NSLog(@"Hardware Wizard executed.\n");
    
    [undoButton setEnabled:[hwUndoManager canUndo]];
    [redoButton setEnabled:[hwUndoManager canRedo]];
}

- (void) doAction:(eAction)actionSelection target:(id)target parameter:(ORHWWizParam*)paramObj channel:(int)chan value:(NSNumber*)aValue 
{
    BOOL skip = NO;
    NSDecimalNumber* returnValue = nil;
    //convert aValue to a NSDecimalNumber
    NSDecimalNumber* aDecimalValue = [NSDecimalNumber decimalNumberWithString:[aValue stringValue]];
    
    NSInvocation* invocationForGetter = nil;
    NSInvocation* invocationForSetter = nil;
    
    //set up the undo invocation for this action
    NSInvocation* invocationForUndo = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:[paramObj setMethodSelector]]];
    [invocationForUndo setSelector:[paramObj setMethodSelector]];
    [invocationForUndo setTarget:target];
    
    SEL setterSelector = [paramObj setMethodSelector];
    SEL getterSelector = [paramObj getMethodSelector];
    int numSetArgs = [[target methodSignatureForSelector:[paramObj setMethodSelector]] numberOfArguments]-2;
    int numGetArgs = 0;
    //convert the chan to a NSNumber
    NSNumber* theChan = [NSNumber numberWithInt:chan];
    
    //set up the invocation for the 'getter'
	if(getterSelector){
	    invocationForGetter = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:getterSelector]];
	    numGetArgs = [[target methodSignatureForSelector:getterSelector] numberOfArguments]-2;
	    //[invocationForGetter retainArguments];
	    [invocationForGetter setSelector:getterSelector];
	    [invocationForGetter setTarget:target];
        
	    if(numGetArgs)[invocationForGetter setArgument:0 to:theChan];
	    [invocationForGetter invoke];
	    returnValue = [invocationForGetter returnValue];
	}
    
    //set up the invocation for the 'setter'
    if(setterSelector){
		invocationForSetter = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:setterSelector]];
		//[invocationForSetter retainArguments];
		[invocationForSetter setSelector:setterSelector];
		[invocationForSetter setTarget:target];
    }
    
    
    if(numSetArgs == 0){
		[invocationForSetter invoke];
    }
    else {
        int valueArg;
        if(numSetArgs==1){
			if(![paramObj useValue]){
				//methods of form 'function:channel'
				aValue = theChan;
			}
			// else methods of form 'setvalue:value'

			//set up for undo
			valueArg = 0;
			[invocationForUndo setArgument:0  to:returnValue];
			[[self hwUndoManager] addToUndo:invocationForUndo withRedo:invocationForSetter];
		}
        else {
            //methods of form 'setvaluefor:chan value:value'
            [invocationForSetter setArgument:0  to:theChan];
            valueArg = 1;
			
            //set up for undo
            [invocationForUndo setArgument:0  to:theChan];
            [invocationForUndo setArgument:1  to:returnValue];
        }
        switch(actionSelection){
				
            case kAction_Set:
                [invocationForSetter setArgument:valueArg  to:aValue];
				break;
                
            case kAction_Inc:
                [invocationForSetter setArgument:valueArg  to:[returnValue decimalNumberByAdding: aDecimalValue]];
				break;
                
            case kAction_Dec:
                [invocationForSetter setArgument:valueArg  to:[returnValue decimalNumberBySubtracting: aDecimalValue]];
				break;
                
            case kAction_Scale:
                if(aValue!=0){
                    returnValue = [returnValue decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100."]];
                    [invocationForSetter setArgument:valueArg to:[returnValue decimalNumberByMultiplyingBy: aDecimalValue]];
                }
				break;
                
            case kAction_Restore:
				@try {
					NSNumber* theValue = [target extractParam:[paramObj name] from:fileHeader  forChannel:[theChan intValue]];
					if(theValue!=nil){
						[invocationForSetter setArgument:valueArg  to:theValue];
					}
					else skip = YES;
					
				}
				@catch(NSException* localException) {
				}
				
				break;
				
			case kAction_Restore_All:
			{
				ORHWWizParam* aParam;
				NSEnumerator* e = [[self selectedObjectsParameters] objectEnumerator];
				while(aParam = [e nextObject]){
					int numSetArgs = [[target methodSignatureForSelector:[aParam setMethodSelector]] numberOfArguments]-2;
					if(numSetArgs>0){
						[self doAction:kAction_Restore target:target parameter:aParam channel:chan value:aValue];
					}
				}
				skip = YES; //don't want to do the invocation again at the end
			}
				break;
				
			default: break;
		}
		
		if(!skip){
			[invocationForSetter invoke];        
			[[self hwUndoManager] addToUndo:invocationForUndo withRedo:invocationForSetter];
		}
		
	}
	[undoButton setEnabled:[hwUndoManager canUndo]];
	[redoButton setEnabled:[hwUndoManager canRedo]];
	[clearUndoButton setEnabled:[redoButton isEnabled] || [undoButton isEnabled]];
}

- (IBAction) restoreAllAction:(id) sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Hardware Wizard Restore ALL!"];
    [alert setInformativeText:@"Really Restore ALL Parameters?\n(A run file will be requested, with one more chance to cancel.)"];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [self performSelector:@selector(_delayedRestoreAllFileRequest) withObject:nil afterDelay:.1];
        }
    }];
#else
    NSBeginAlertSheet(@"Hardware Wizard Restore ALL!",
                      @"Yes",
                      @"Cancel",
                      nil,[self window],
                      self,
                      @selector(_restoreAllSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really Restore ALL Parameters?\n(A run file will be requested, with one more chance to cancel.)");
#endif
}

@end

@implementation ORHWWizardController (private)

- (void) _executeActionController:(id) actionController
{
	
	NSEnumerator* containerEnum = [controlArray objectEnumerator];
	id container;
	while(container = [containerEnum nextObject]){
		[self _executeController:actionController container:container];
		
	}
}

- (void) _executeController:(id)actionController container:(id)container
{
	if([container respondsToSelector:@selector(objectEnumerator)]){
		
		eAction actionSelection     = [actionController actionTag];
		eAction parameterSelection  = [actionController parameterTag];
		NSNumber* parameterValue    = [actionController parameterValue];
		
		NSEnumerator* objectEnum = [container objectEnumerator];
		id wizObject;
		while(wizObject = [objectEnum nextObject]){
			if([wizObject respondsToSelector:@selector(numberOfChannels)]){
				id target = [wizObject target];
				ORHWWizParam* paramObj = [[actionController paramArray] objectAtIndex:parameterSelection];
				
                
				SEL methodSel = [paramObj setMethodSelector];
				int numberOfSettableArguments = 0;
				if(methodSel) numberOfSettableArguments = [[target methodSignatureForSelector:methodSel] numberOfArguments]-2;
				
				if(![paramObj enabledWhileRunning] && [[ORGlobal sharedGlobal] runInProgress]){
					NSLog(@"HW Wizard selection <%@> can not be executed while running. It was skipped.\n",[paramObj name]);
					continue;
				}
                NSDictionary* wizardInfo = [NSDictionary dictionaryWithObjectsAndKeys:[paramObj name],@"ActionName",NSStringFromSelector(methodSel),@"ActionSelector", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:ORHWWizSelectorActionStarted object:target userInfo:wizardInfo];
                
				if(numberOfSettableArguments <= 1){
					if([paramObj useValue] || [paramObj oncePerCard]){
						//no channels to deal with, just do the action
						unsigned long chanMask = [wizObject wizMask];
						if(chanMask & 0xffffffff){									
							
							[self doAction:actionSelection 
									target: target
								 parameter:paramObj 
								   channel:0 
									 value:parameterValue];
						}
					}
					else {
							//loop over the channels, doing the action for each channel in the mask.
						int chan;
						int numChan = [wizObject numberOfChannels];
						unsigned long chanMask = [wizObject wizMask];
						for(chan=0;chan<numChan;chan++){
							if(chanMask & (1<<chan)){									
								[self doAction:actionSelection 
										target: target
									 parameter:paramObj 
									   channel:chan 
										 value:parameterValue];
							}
						}
					}
				}
				else {
					if([paramObj useFixedChannel]){
						if([wizObject wizMask] & (1<<[paramObj fixedChannel])){									
							[self doAction:actionSelection 
									target: target
								 parameter:paramObj 
								   channel:[paramObj fixedChannel] 
									 value:parameterValue];
						}
					}
					else {
						//loop over the channels, doing the action for each channel in the mask.
						int chan;
						int numChan = [wizObject numberOfChannels];
						unsigned long chanMask = [wizObject wizMask];
						for(chan=0;chan<numChan;chan++){
							if(chanMask & (1<<chan)){									
								[self doAction:actionSelection 
										target: target
									 parameter:paramObj 
									   channel:chan 
										 value:parameterValue];
							}
						}
					}
				}
                [[NSNotificationCenter defaultCenter] postNotificationName:ORHWWizSelectorActionFinished object:target userInfo:wizardInfo];
			}
		}
	}
}

- (void) _delayedExecute
{
	if([self needToRestore])[self askForFileAndExecute];
	else [self executeControlStruct];
    [self setUseMark:NO];
}

- (void) _delayedRestoreAllFileRequest
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Restore All"];

    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSFileHandle* theFile = [NSFileHandle fileHandleForReadingAtPath:[[openPanel URL]path]];
            [self setFileHeader:[ORDecoder readHeader:theFile]];
            [self performSelector:@selector(_restoreAll) withObject:nil afterDelay:.1];
            [theFile closeFile];
        }
    }];
}
- (void) _restoreAll
{
	int n;
	int i;
	
    [[self undoManager] disableUndoRegistration];
	
	//we'll do everything with the GUI so we remove all but one item from the lists 
	while([actionControllers count] > 1)    [self removeActionControllerAtIndex:1];
	while([selectionControllers count] > 1) [self removeSelectionControllerAtIndex:1];
	
	int oldObjectIndex = [objectPU indexOfSelectedItem];
	
    [[self undoManager] enableUndoRegistration];
	
	//loop thru all availiable objects and do a 'Restore All'
	n = [objectPU numberOfItems];
	for(i=0;i<n;i++){
		[objectPU selectItemAtIndex:i];
		[self selectObject:objectPU];
		[[actionControllers objectAtIndex:0] setActionTag:kAction_Restore_All];
		
		[self setUseMark:NO];
		[self makeControlStruct:nil];
		[self executeControlStruct];
 	}
	
    [[self undoManager] disableUndoRegistration];
	
	//restore the Wizard configuration
	objectTag = -1; //force an update
	[objectPU selectItemAtIndex:oldObjectIndex];
	[self selectObject:objectPU];
	
    [[self undoManager] enableUndoRegistration];
	
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _restoreAllSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertDefaultReturn){
        [self performSelector:@selector(_delayedRestoreAllFileRequest) withObject:nil afterDelay:.1];
    }    
}
     
- (void) _doItSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertDefaultReturn){
        [self setUseMark:NO];
        [self makeControlStruct:nil];
        [self performSelector:@selector(_delayedExecute) withObject:nil afterDelay:.1];
    }    
}
- (void) _doItWithMarkSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertDefaultReturn){
        [self setUseMark:YES];
        [self makeControlStruct:nil];
        [self performSelector:@selector(_delayedExecute) withObject:nil afterDelay:.1];
        [self setUseMark:NO];
    }    
}

- (void)_clearMarksSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertDefaultReturn){
        [hwUndoManager clearMarks];
        [self marksChanged];
    }    
}

- (void)_clearUndoSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertDefaultReturn){
        [self clearUndoStacks];
    }    
}
#endif
@end

//-------------------------------------------
@implementation ORHWWizObj

+ (id) hwWizObject:(id<ORHWWizard>)obj
{
    return [[[ORHWWizObj alloc] initWithTarget:obj] autorelease];
}

- (id) initWithTarget:(id<ORHWWizard>)obj
{
    self = [super init];
    target = obj;
    return self;
}

- (id) target
{
    return target;
}
- (unsigned long) wizMask
{
    return wizMask;
}

- (void) setWizMask:(unsigned long )aMask
{
    wizMask = aMask;
}

- (int) numberOfChannels 
{
    return [target numberOfChannels];
}

@end

