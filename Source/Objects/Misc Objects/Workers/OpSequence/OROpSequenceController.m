//
//  OROpSequenceController
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

#import "OROpSequenceController.h"
#import "OROpSequenceQueue.h"
#import "OROpSequence.h"
#import "OROpSeqStep.h"

@implementation OROpSequenceController

- (void)dealloc
{
	[[[owner model] scriptModel:idIndex] cancel:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [topLevelObjects release];

	[super dealloc];
}

- (void) setIdIndex:(int)aValue;
{
    idIndex = aValue;
}

- (int) idIndex { return idIndex;}

- (void)awakeFromNib
{
    if(!portControlsContent){
#if !defined(MAC_OS_X_VERSION_10_9)
        if ([NSBundle loadNibNamed:@"OpSequence" owner:self]){
#else
        if ([[NSBundle mainBundle] loadNibNamed:@"OpSequence" owner:self topLevelObjects:&topLevelObjects]){
#endif
            [topLevelObjects retain];
			[portControlsView setContentView:portControlsContent];
		}
		else NSLog(@"Failed to load SerialPortControls.nib");
	}

 	[self updateProgressDisplayChanged:nil];
    
    [self registerNotificationObservers];
    
	[collectionView setMinItemSize:NSMakeSize(150, 40)];
	[collectionView setMaxItemSize:NSMakeSize(CGFLOAT_MAX, 40)];
    [collectionView setBackgroundColors:[NSArray arrayWithObject:[NSColor clearColor]]];
}

- (void) registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter addObserver : self
                     selector : @selector(stepsChanged:)
                         name : OROpSeqStepsChanged
                       object : nil];
    
	[notifyCenter addObserver : self
                     selector : @selector(updateProgressDisplayChanged:)
                         name : ORSequenceQueueCountChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(allowedToRunChanged:)
                         name : OROpSequenceAllowedToRunChanged
                       object : nil];
    

}

- (void) allowedToRunChanged:(NSNotification*)aNote
{
    OROpSequence* seq   = [[owner model] scriptModel:idIndex];

    [cancelButton setEnabled:[seq allowedToRun]];
}


- (void) stepsChanged:(NSNotification*)aNote
{
    [stepsController setContent:[self steps]];
}

//
// start
//
// Calls the ScriptSteps function to get the array of script steps and then
// adds them all to the queue.
//
- (IBAction)start:(id)sender
{
    [[[owner model] scriptModel:idIndex] start];
}

- (NSArray*)steps
{
    return [[[owner model] scriptModel:idIndex] steps];
}

//
// updateProgressDisplay
//
// Update the progress text and progress indicator. Possibly update the
// cancel/restart button if we've reached the end of the queue
//
- (void)updateProgressDisplayChanged:(NSNotification*)aNote
{
    OROpSequence* seq   = [[owner model] scriptModel:idIndex];
    if([aNote object] != seq) return;
    else [self updateProgressDisplay:seq];
}

- (void) updateProgressDisplay:(OROpSequence*)aSeq
{

    NSArray*  steps      = [aSeq steps];
	NSInteger total      = [steps count];
	NSArray*  operations = [aSeq operations];
	NSInteger remaining  = [operations count];
	
	//
	// Try to get the remaining count as it corresponds to the "steps" array as
	// the actual scriptQueue may have changed due to cancelled steps or other
	// dynamic changes.
	//
	if (remaining > 0){
		NSInteger stepsIndex = [steps indexOfObject:[operations objectAtIndex:0]];
		if (stepsIndex != NSNotFound){
			remaining = total - stepsIndex;
		}
	}
	
	if (remaining == 0) {
		switch ([(OROpSequence*)[[owner model] scriptModel:idIndex]state]){
			case kOpSeqQueueRunning:
			case kOpSeqQueueFinished:
                {
                    [progressLabel setStringValue:[NSString stringWithFormat:@"Done @ %@",[[NSDate date] descriptionFromTemplate:@"HH:mm:ss"]]];
                }
				break;
			case kOpSeqQueueFailed:
				[progressLabel setStringValue:@"Failed with error."];
				break;
			case kOpSeqQueueCancelled:
				[progressLabel setStringValue:@"Cancelled."];
				break;
            case kOpSeqQueueNeverRun:
				[progressLabel setStringValue:@"Has Never Run"];
				break;
		}
		[progressIndicator setDoubleValue:0];
		[cancelButton setTitle:@"Run"];
	}
	else {
		[cancelButton setTitle:@"Cancel"];
		[progressLabel setStringValue: [NSString stringWithFormat:
                                            @"Finished %ld/%d",
                                            total - remaining,
                                            (int32_t)total]];
		[progressIndicator setMaxValue:   (double) total];
		[progressIndicator setDoubleValue:(double) (total - remaining)];
	}
	
	//
	// If the step that just finished was selected, advance the selection to the
	// next running step
	//
	if ([stepsController selectionIndex] == lastKnownStepIndex &&
		remaining != 0) {
		[stepsController setSelectionIndex:total - remaining];
	}
	lastKnownStepIndex = total - remaining;
}

//
// cancel:
//
// Cancels the queue (if operations count is > 0) and waits for all operations
// to be cleared correctly.
// If operations count == 0, restarts the queue.
//
// Parameters:
//    parameter - this method may be invoked in 3 situations (distinguished by
//		this parameter)
//		1) Notification from the ScriptQueue that cancelAllOperations was invoked
//			(generally due to error)
//		2) NSButton (user action). This may restart the queue.
//		3) nil (when the window controller is being deleted)
//
- (IBAction)cancel:(id)parameter
{
    OROpSequence* seq = [[owner model] scriptModel:idIndex];
    [seq cancel:parameter];
    [self updateProgressDisplay:seq];
}

@end
