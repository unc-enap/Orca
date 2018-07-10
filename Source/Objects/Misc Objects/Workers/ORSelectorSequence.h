//
//  ORSelectorSequence.h
//  Orca
//
//  Created by Mark Howe on 10/3/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
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

@interface ORSelectorSequence : NSObject {
	@private
		id  delegate;
		int	tag;
		int startCount;
	
		NSMutableArray*			selectors;
		NSMutableDictionary*	nextSelector;
}

+ (id) selectorSequenceWithDelegate:(id)aDelegate;
- (id) initWithDelegate:(id)aDelegate;
- (void) dealloc;
- (id) forTarget:(id)aTarget;
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
- (void) forwardInvocation:(NSInvocation *)invocation;

- (void) startSequence;
- (void) stopSequence;
@end

@interface NSObject (ORSelectorSequence)
- (void) sequenceCompleted:(id)sender;
@end

extern NSString* ORSequenceRunning;
extern NSString* ORSequenceStopped;
extern NSString* ORSequenceProgress;
