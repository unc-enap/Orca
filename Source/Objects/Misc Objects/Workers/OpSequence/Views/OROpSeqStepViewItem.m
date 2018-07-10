//
//  ScriptStepCollectionViewItem.m
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

#import "OROpSeqStepViewItem.h"
#import "OROpSeqStepView.h"
#import "OROpSeqStep.h"

@implementation OROpSeqStepViewItem

- (void)dealloc
{
	[self setRepresentedObject:nil];
	[super dealloc];
}

- (void)setSelected:(BOOL)flag
{
    [super setSelected:flag];
    [(OROpSeqStepView*)[self view] setSelected:flag];
}

- (void)updateStateForView
{
	OROpSeqStep*     step = [self representedObject];
	OROpSeqStepView* view = (OROpSeqStepView*)[self view];
    
    [view setState:[step state]];
    [view setErrorsString:[step finalStateString]];
 }

//
// setRepresentedObject:
//
// When the represented object changes, begin observing the new object
//
// Parameters:
//    representedObject - the new object
//
- (void)setRepresentedObject:(OROpSeqStep *)representedObject
{
	OROpSeqStep *previous = [self representedObject];
	if (previous) {
		[previous removeObserver:self forKeyPath:@"isExecuting"];
		[previous removeObserver:self forKeyPath:@"isFinished"];
	}
	
	[super setRepresentedObject:representedObject];
	
	if (representedObject) {
		[representedObject addObserver:self forKeyPath:@"isExecuting" options:0 context:NULL];
		[representedObject addObserver:self forKeyPath:@"isFinished" options:0 context:NULL];
	}

	[self updateStateForView];
}

//
// observeValueForKeyPath:ofObject:change:context:
//
// When elements affecting view state change on the represented object, pass
// these on to the view
//
// Parameters:
//    keyPath - the property
//    object - the object
//    change - the change
//    context - the context
//
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
	change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"isExecuting"] ||
		[keyPath isEqual:@"isFinished"]){
		[self updateStateForView];
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change
		context:context];
}

@end
