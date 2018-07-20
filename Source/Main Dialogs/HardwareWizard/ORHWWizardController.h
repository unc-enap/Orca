//
//  ORHWWizardController.h
//  SubviewTableViewRuleEditor
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



#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORHWWizard.h"
#import "ORHWWizParam.h"
#import "SubviewTableViewController.h"

@class ORWizActionController;
@class ORHWUndoManager;
@class ORDataPacket;

@interface ORHWWizardController : NSWindowController < SubviewTableViewControllerDataSourceProtocol >
{
    @private
    
    IBOutlet NSView*        actionView;
    IBOutlet NSTableView*   actionTableView;
    IBOutlet NSTableColumn* actionColumn;
    IBOutlet NSTableColumn* removeActionColumn;
    IBOutlet NSTableColumn* addActionColumn;

    IBOutlet NSView*        selectionView;
    IBOutlet NSTableView*   selectionTableView;
    IBOutlet NSTableColumn* selectionColumn;
    IBOutlet NSTableColumn* removeSelectionColumn;
    IBOutlet NSTableColumn* addSelectionColumn;
    IBOutlet NSButton*      advancedButton;
    IBOutlet NSButton*      doitButton;
    IBOutlet NSButton*      markAnDoitButton;

    IBOutlet NSPopUpButton* objectPU;
    IBOutlet NSButton*      goToMarkButton;
    IBOutlet NSButton*      clearMarksButton;
    IBOutlet NSPopUpButton* marksPU;

    IBOutlet NSTextField*   containerLabel;
    IBOutlet NSTextField*   objectLabel;
    IBOutlet NSTextField*   containerTextField;
    IBOutlet NSTextField*   objectTextField;
    IBOutlet NSTextField*   chanTextField;

    IBOutlet NSDrawer*      advancedDrawer;
    IBOutlet NSButton*      undoButton;
    IBOutlet NSButton*      redoButton;
    IBOutlet NSButton*      clearUndoButton;
    IBOutlet NSTextField*   statusTextField;
    IBOutlet NSButton*      wizardLockButton;
    IBOutlet NSTextField*   fileSelectionTextField;
    IBOutlet NSTextField*   settingLockDocField;
	IBOutlet NSButton*      restoreAllButton;
   
    SubviewTableViewController* actionViewController;
    NSMutableArray*			    actionControllers;

    SubviewTableViewController *selectionViewController;
    NSMutableArray *selectionControllers;

    NSMutableDictionary *objects;
    NSMutableDictionary *fileHeader;

    NSInteger objectTag;
    NSMutableArray* controlArray;
    BOOL containerExists;
    
    short containerCount;
    short objectCount;
    short chanCount;

    ORHWUndoManager* hwUndoManager;
    BOOL    useMark;
    BOOL    objectsAvailiable;

    BOOL    okToContinue;
}

+ (BOOL) exists;
+ (ORHWWizardController*) sharedHWWizardController;

- (SubviewTableViewController *)actionViewController;
- (void)setActionViewController:(SubviewTableViewController *)anActionViewController;
- (NSMutableArray *)actionControllers;
- (void)setActionControllers:(NSMutableArray *)anActionControllers;
- (SubviewTableViewController *)selectionViewController;
- (void)setSelectionViewController:(SubviewTableViewController *)aSelectionViewController;
- (NSMutableArray *)selectionControllers;
- (void)setSelectionControllers:(NSMutableArray *)aSelectionControllers;
- (NSDictionary *)objects;
- (void)setObjects:(NSMutableDictionary *)anObjects;
- (NSInteger)objectTag;
- (void)setObjectTag:(int)anObjectTag;
- (NSMutableArray *)controlArray;
- (void)setControlArray:(NSMutableArray *)aControlArray;
- (short)containerCount;
- (void)setContainerCount:(short)aContainerCount;
- (short)objectCount;
- (void)setObjectCount:(short)anObjectCount;
- (short)chanCount;
- (void)setChanCount:(short)aChanCount;
- (BOOL) useMark;
- (void) setUseMark: (BOOL) flag;
- (void) setFileHeader:(NSMutableDictionary*)aHeader;

- (void) registerNotificationObservers;
- (void) statusTextChanged:(NSNotification*)aNotification;
- (void) objectsAdded:(NSNotification*)aNote;
- (void) objectsRemoved:(NSNotification*)aNote;
- (void) objectTagChanged:(NSNotification*)aNote;
- (void) countChanged:(NSNotification*)aNote;
- (void) securityStateChanged:(NSNotification*)aNotification;
- (void) wizardLockChanged:(NSNotification*)aNote;
- (void) marksChanged;
- (void) actionChanged:(NSNotification*)aNotification;
- (void) documentClosed:(NSNotification*)aNotification;
- (void) setFileSelectionText;

- (ORHWUndoManager *) hwUndoManager;
- (void) setHwUndoManager: (ORHWUndoManager *) aHwUndoManager;

- (void) notOkToContinue;

- (IBAction) addAction:(id) sender;
- (IBAction) removeAction:(id) sender;
- (IBAction) addSelection:(id) sender;
- (IBAction) removeSelection:(id) sender;
- (IBAction) doIt:(id) sender;
- (IBAction) doItWithMark:(id) sender;
- (IBAction) selectObject:(id) sender;
- (IBAction) undo:(id) sender;
- (IBAction) redo:(id) sender;
- (IBAction) undoToMark:(id) sender;
- (IBAction) clearMarks:(id) sender;
- (IBAction) clearUndo:(id) sender;
- (IBAction) wizardLockAction:(id) sender;
- (IBAction) restoreAllAction:(id) sender;
- (void) clearUndoStacks;

- (void) removeActionControllerAtIndex:(NSInteger) index;
- (void) addActionController:(id) obj atIndex:(NSInteger) index;
- (void) addSelectionController:(id) obj atIndex:(NSInteger) index;
- (void) removeSelectionControllerAtIndex:(NSInteger) index;

- (void) adjustActionSize:(int)amount;
- (void) adjustSelectionSize:(int)amount;
- (NSUndoManager*) undoManager;
- (NSArray*) scanForObjects;
- (void) installObjects:(NSArray*) theObjects;
- (NSArray*) defaultEmptyParameterArray;
- (NSArray*) defaultEmptySelectionArray;
- (NSArray*) selectedObjectsParameters;
- (NSArray*) selectedObjectsSelectionOptions;
- (NSArray*) conformingObjectsInArray:(NSArray*)anArray;

#pragma mark ¥¥¥Object Mask Methods
- (void) makeControlStruct:(NSNotification*)aNote;
- (ORHWWizSelection*) getSelectionAtLevel:(eSelectionLevel)selectionLevel;
- (void) addObjectList:(NSArray*)objectList atIndex:(int)containerTag;
- (void) setUpMasks:(NSNotification*)aNote;
- (void) setMaskBits;
- (void) executeControlStruct;
- (void) continueExecuteControlStruct;
- (void) doAction:(eAction)actionSelection
	   target:(id)target 
	parameter:(ORHWWizParam*)paramObj
	  channel:(int)chan
	    value:(NSNumber*)aValue;
- (void) countChannels;
- (void) askForFileAndExecute;
- (BOOL) needToRestore;
- (NSInteger) numberOfRowsInTableView:(NSTableView *) tableView;

@end

extern NSString* ORHWWizCountsChangedNotification;
extern NSString* ORHWWizardLock;

extern NSString* ORHWWizGroupActionStarted;
extern NSString* ORHWWizGroupActionFinished;
extern NSString* ORHWWizSelectorActionStarted;
extern NSString* ORHWWizSelectorActionFinished;
extern NSString* ORHWWizActionFinalNotification;

@interface ORHWWizObj : NSObject
{
    uint32_t wizMask;
    id<ORHWWizard> target;
}
+ (id) hwWizObject:(id<ORHWWizard>)obj;
- (id) initWithTarget:(id<ORHWWizard>)obj;
- (id) target;
- (uint32_t) wizMask;
- (void) setWizMask:(uint32_t)aMask;
- (int) numberOfChannels;


@end

