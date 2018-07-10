//
//  TaskHandler.h
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

enum {
   TaskHandlerCouldNotBeLaunched              = -1,
   TaskHandlerNotLaunched                     = 0,
   TaskHandlerStillRunning                    = 1,
   TaskHandlerTerminationReasonExit           = 2,
   TaskHandlerTerminationReasonUncaughtSignal = 3
};

typedef NSInteger TaskHandlerTerminationReason;

@interface ORTaskHandler : NSObject
{
	NSTask*         task;
	NSMutableData*  outputData;
	id              outputReceiver;
	SEL             outputSelector;
	
	NSMutableData*  errorData;
	id              errorReceiver;
	SEL             errorSelector;

	id              terminationReceiver;
	SEL             terminationSelector;
	
	BOOL            outputClosed;
	BOOL            errorClosed;
	
	TaskHandlerTerminationReason taskState;
}

@property (nonatomic, assign) TaskHandlerTerminationReason taskState;
@property (nonatomic, retain) NSTask *task;

- (id)initWithLaunchPath:(NSString *)launchPath arguments:(NSArray *)arguments
	terminationReceiver:(id)receiver selector:(SEL)selector;
- (NSData *)outputData;
- (NSData *)errorData;
- (void)setOutputReceiver:(id)receiver selector:(SEL)selector;
- (void)setErrorReceiver:(id)receiver selector:(SEL)selector;
- (void)appendInputData:(NSData *)newData;
- (void)launch;
- (void)terminate;

- (void)standardOutNotification: (NSNotification *) aNote;
- (void)standardErrorNotification: (NSNotification *) aNote;
- (void)terminatedNotification: (NSNotification *)aNote;

@end
