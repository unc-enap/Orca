//
//  OrcaObjectController.h
//  Orca
//
//  Created by Mark Howe on Sun Dec 08 2002.
//  Copyright © 2002 CENPA, Univsersity of Washington. All rights reserved.
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


#pragma mark ¥¥¥Forward Declarations
@class ORTimedTextField;

@interface OrcaObjectController : NSWindowController  {
	IBOutlet ORTimedTextField*   warningField;
    @protected
        id model;
        BOOL updatedOnce;
}

#pragma mark ¥¥¥Accessors
- (id) model;
- (void) setModel:(id)aModel;

#pragma mark ¥¥¥Interface Management
- (void) close;
- (void) isNowKeyWindow:(NSNotification*)aNotification;
- (void) endEditing;
- (void) endAllEditing:(NSNotification*)aNotification;
- (void) registerNotificationObservers;
- (void) documentClosing:(NSNotification*)aNotification;
- (void) updateWindow;
- (NSUndoManager*) undoManager;
- (NSArray*) collectObjectsOfClass:(Class)aClass;
- (NSArray*) collectObjectsConformingTo:(Protocol*)aProtocol;
- (void) resizeWindowToSize:(NSSize)newSize;
- (NSMutableDictionary*) miscAttributesForKey:(NSString*)aKey;
- (void) setMiscAttributes:(NSMutableDictionary*)someAttributes forKey:(NSString*)aKey;

#pragma mark ¥¥¥Interface Management - Generic updaters
- (void)updateTwoStateCheckbox:(NSButton *)control setting:(BOOL)inValue;
- (void)updateMixedStateCheckbox:(NSButton *)control setting:(int)inValue;
- (void)updateRadioCluster:(NSMatrix *)control setting:(int)inValue;
- (void)updatePopUpButton:(NSPopUpButton *)control setting:(int)inValue;
- (void)updateSlider:(NSSlider *)control setting:(NSInteger)inValue;
- (void)updateStepper:(NSStepper *)control setting:(NSInteger)inValue;
- (void)updateIntText:(NSTextField *)control setting:(NSInteger)inValue;
- (void) updateValueMatrix:(NSMatrix*)aMatrix getter:(SEL)aGetter;
- (void) incModelSortedBy:(SEL)aSelector;
- (void) decModelSortedBy:(SEL)aSelector;

#pragma mark ¥¥¥Notifications
- (void) checkGlobalSecurity;
- (void) uniqueIDChanged:(NSNotification*)aNotification;
- (void) warningPosted:(NSNotification*)aNotification;
- (void) setUpdatedOnce;
- (void) resetUpdatedOnce;

#pragma mark ¥¥¥Actions
- (IBAction) incDialog:(id)sender;
- (IBAction) decDialog:(id)sender;
- (IBAction) saveDocument:(id)sender;
- (IBAction) saveDocumentAs:(id)sender;
- (IBAction) printDocument:(id)sender;

- (IBAction) copy:(id)sender;

@end

@interface NSObject (OrcaObject_Cat)
- (void) duplicateDialog:(id)dialog;
@end

extern NSString* ORModelChangedNotification;
