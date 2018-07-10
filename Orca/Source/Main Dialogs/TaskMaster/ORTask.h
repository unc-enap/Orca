//
//  ORTask.h
//  Orca
//
//  Created by Mark Howe on Wed Nov 26 2003.
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


@interface ORTask : NSObject {

    IBOutlet NSView*        view;
    IBOutlet NSView*        extraView;
    IBOutlet NSTextField*   titleField;
    IBOutlet NSButton*      startButton;
    IBOutlet NSMatrix*      willRepeatMatrix;
    IBOutlet NSButton*      delayStartCB;
    IBOutlet NSTextField*   timeDelayField;
    IBOutlet NSTextField*   timeIntervalField;
    IBOutlet NSStepper*     timeDelayStepper;
    IBOutlet NSStepper*     timeIntervalStepper;
    IBOutlet NSTextField*   runStateField;
    IBOutlet NSTextField*   nextRunTimeField;
    IBOutlet NSTextField*   messageField;
    IBOutlet NSBox*         taskBox;
    IBOutlet NSButton*      detailsButton;
    
    NSString* title;
    NSString* message;
    ORTaskState taskState;
    NSTimeInterval timeDelay;
    NSTimeInterval timeInterval;
    BOOL startIsDelayed;
    BOOL willRepeat;
    id  delegate;
    SEL taskSelector;
    SEL postRunSelector;
    BOOL hardHalted;
    BOOL isSlave;
    BOOL isExpanded;
    float expandedHeight;
    BOOL doingFinishUpWork;
    NSArray* topLevelObjects;
}

- (void) sleep;
- (void) wakeUp;
-(void)registerNotificationObservers;

#pragma mark ¥¥¥Accessors
- (NSView*)view;
- (NSString*) title;
- (void) setTitle:(NSString*)aString;
- (ORTaskState)taskState;
- (void)setTaskState:(ORTaskState)aState;
- (NSTimeInterval)timeDelay;
- (void)setTimeDelay:(NSTimeInterval)aTimeDelay;
- (NSTimeInterval)timeInterval;
- (void)setTimeInterval:(NSTimeInterval)aTimeInterval;
- (BOOL)startIsDelayed;
- (void)setStartIsDelayed:(BOOL)flag;
- (BOOL)willRepeat;
- (void)setWillRepeat:(BOOL)flag;
- (NSUndoManager*) undoManager;
- (id)delegate;
- (void)setDelegate:(id)aDelegate;
- (void)setMessage:(NSString*)aMessage;
- (NSString*)message;
- (void)install;
- (void) addExtraPanel:(NSView*)aView;
- (BOOL) isSlave;
- (void) setIsSlave:(BOOL)state;

#pragma mark ¥¥¥Actions
-(IBAction) startAction:(id)sender;
-(IBAction) willRepeatAction:(id)sender;
-(IBAction) runDelayAction:(id)sender;
-(IBAction) timeDelayAction:(id)sender;
-(IBAction) timeIntervalAction:(id)sender;
-(IBAction) detailsAction:(id)sender;

- (void) updateButtons;

#pragma mark ¥¥¥Control
- (void) startTask;
- (void) continueTask;
- (void) stopTask;
- (void) hardHaltTask;

- (void)loadMemento:(NSCoder*)decoder;
- (void)saveMemento:(NSCoder*)encoder;


#pragma mark ¥¥¥SubClass Responsiblity
- (void) prepare;
- (BOOL) doWork;
- (void) finishUp;
- (void) cleanUp;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSData*) memento;
- (void) restoreFromMemento:(NSData*)aMemento;

@end

extern NSString* ORTaskDidStartNotification;
extern NSString* ORTaskDidStepNotification;
extern NSString* ORTaskDidFinishNotification;


@interface NSObject (ORTaskCatagory)
- (BOOL) okToRun;
- (void) enableGUI:(BOOL)state;
- (void) stopTask;
- (id)   dependentTask:(ORTask*)aTask;
- (void) taskDidFinish:(NSNotification*)aNote;
- (void) taskDidStart:(NSNotification*)aNote;
- (void) taskDidStep:(NSNotification*)aNote;
@end

