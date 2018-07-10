//
//  CocoaScriptWindowController.h
//  CocoaScript
//
//  Created by Matt Gallagher on 2010/11/01.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <Cocoa/Cocoa.h>
@class OROpSequence;

@interface OROpSequenceController : NSObject
{
    IBOutlet id  owner;
	IBOutlet NSArrayController* stepsController;
	IBOutlet NSCollectionView*  collectionView;
	IBOutlet NSTextField*       progressLabel;
	IBOutlet NSProgressIndicator* progressIndicator;
	IBOutlet NSButton*          cancelButton;
    IBOutlet NSView*            portControlsContent;
	IBOutlet NSBox*             portControlsView;
	NSInteger                   lastKnownStepIndex;
    int                         idIndex;
    NSArray*                    topLevelObjects;
}

- (void) allowedToRunChanged:(NSNotification*)aNote;
- (void) stepsChanged:(NSNotification*)aNote;
- (void) updateProgressDisplay:(OROpSequence*)aSeq;
- (void) updateProgressDisplayChanged:(NSNotification*)aNote;;
- (void) setIdIndex:(int)idIndex;
- (int)  idIndex;
- (IBAction)start:(id)sender;
- (IBAction)cancel:(id)sender;
- (NSArray*)steps;
- (void) registerNotificationObservers;

@end

@interface NSObject (CocoaScriptController)
- (id) model;
- (id) scriptModel:(int)anIndex;
@end