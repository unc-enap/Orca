//
//  ORTask.m
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


#import "ORTask.h"
#import "ORTaskMaster.h"


NSString* ORTaskDidStartNotification    = @"ORTaskDidStartNotification";
NSString* ORTaskDidStepNotification     = @"ORTaskDidStepNotification";
NSString* ORTaskDidFinishNotification   = @"ORTaskDidFinishNotification";

@implementation ORTask

#pragma mark •••Initializers

-(void)	sleep
{     
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (delegate)[[NSNotificationCenter defaultCenter] removeObserver:delegate name:nil object:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(continueTask) object:nil];
    [[ORTaskMaster sharedTaskMaster] removeTask:self];
}

- (void) wakeUp
{
    [runStateField setStringValue:@"Idle"];
    [self setMessage:@"Idle"];
    [[ORTaskMaster sharedTaskMaster] addTask:self];
    if (delegate)[self setDelegate:delegate];
    [self updateButtons];
}

-(id)	init
{
    if( self = [super init] ){
#if !defined(MAC_OS_X_VERSION_10_9)
        [NSBundle loadNibNamed:@"ORTask" owner:self];
#else
        [[NSBundle mainBundle] loadNibNamed:@"ORTask" owner:self topLevelObjects:&topLevelObjects];
#endif

        [topLevelObjects retain];
		[self setTaskState:eTaskStopped];
    }
    return self;
}

-(void)	dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if(taskState != eTaskStopped){
        [self stopTask];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (delegate){
        [[NSNotificationCenter defaultCenter] removeObserver:delegate name:nil object:self];
        delegate = nil;
    }
    
    if(![NSThread isMainThread]){
        [view performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];
        [extraView performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];
    }
    else {
        [view removeFromSuperview];
        [extraView removeFromSuperview];
    }
    [title release];
    [[ORTaskMaster sharedTaskMaster] removeTask:self];
    [topLevelObjects release];

    [super dealloc];
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
    [self setMessage:@"Idle"];
}

-(void)registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter removeObserver:self];
    [notifyCenter addObserver: self
                     selector: @selector(updateButtons)
                         name: ORRunStatusChangedNotification
                       object: nil];
    
}

#pragma mark •••Accessors
-(NSView*) view
{
    return view;
}

- (NSString*) title
{
    return title;
}

- (void) setTitle:(NSString*)aString
{
    [title release];
    title = [aString copy];
    if(aString!=nil){
        [titleField setStringValue:aString];
    }
}

- (ORTaskState)taskState
{
    return taskState;
}

- (void)setTaskState:(ORTaskState)aState
{
    if(taskState!=aState){
        [[NSNotificationCenter defaultCenter] postNotificationName:ORTaskStateChangedNotification
                                                            object:self];
    }
    
    taskState = aState;
    if(taskState<eMaxTaskState){
        if(isSlave) {
			[runStateField setStringValue:@"Slave"];
		}
        else {
			[runStateField setStringValue:ORTaskStateName[taskState]];
		}
    }
    else {
        [runStateField setStringValue:@"?"];
    }
    [self updateButtons];
}


- (NSTimeInterval)timeDelay
{
    return timeDelay;
}

- (void)setTimeDelay:(NSTimeInterval)aTimeDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeDelay:timeDelay];
    timeDelay = aTimeDelay;
    [timeDelayStepper setIntValue:timeDelay];
    [timeDelayField setIntValue:timeDelay];
}

- (NSTimeInterval)timeInterval
{
    return timeInterval;
}

- (void)setTimeInterval:(NSTimeInterval)aTimeInterval
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeInterval:timeInterval];
    timeInterval = aTimeInterval;
    [timeIntervalStepper setIntValue:timeInterval];
    [timeIntervalField setIntValue:timeInterval];
}

- (BOOL)startIsDelayed
{
    return startIsDelayed;
}

- (void)setStartIsDelayed:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartIsDelayed:startIsDelayed];
    startIsDelayed = flag;
    [delayStartCB setState:!startIsDelayed];
    [self updateButtons];
}

- (id)delegate
{
    return delegate; 
}

- (void)setDelegate:(id)aDelegate
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    if (delegate)[nc removeObserver:delegate name:nil object:self];
    
    delegate = aDelegate;
    
    if ([delegate respondsToSelector:@selector(taskDidStart:)]){
        [nc addObserver:delegate selector:@selector(taskDidStart:)
                   name:ORTaskDidStartNotification object:self];
    }
    
    if ([delegate respondsToSelector:@selector(taskDidStep:)]){
        [nc addObserver:delegate selector:@selector(taskDidStep:)
                   name:ORTaskDidStepNotification object:self];
    }
    
    
    if ([delegate respondsToSelector:@selector(taskDidFinish:)]){
        [nc addObserver:delegate selector:@selector(taskDidFinish:)
                   name:ORTaskDidFinishNotification object:self];
    }
    
    
}

- (BOOL)willRepeat
{
    return willRepeat;
}

- (void)setWillRepeat:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWillRepeat:willRepeat];
    willRepeat = flag;
    [willRepeatMatrix selectCellWithTag:willRepeat];
    [self updateButtons];
}

- (void)setMessage:(NSString*)aMessage
{
    [aMessage autorelease];
    message = [aMessage copy];
    [messageField setStringValue:aMessage];
}

- (NSString*) message
{
    return message;
}

- (BOOL) isSlave
{
    return isSlave;
}

- (void) setIsSlave:(BOOL)state
{
    isSlave = state;
    [self updateButtons];
}


- (NSUndoManager*) undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}


- (void)install
{
    [[ORTaskMaster sharedTaskMaster] addTask:self];
}


- (void) addExtraPanel:(NSView*)aView
{
    if(!aView)return;
    NSArray* subViews = [taskBox subviews];
    if(![subViews containsObject:aView]){
        //don't add it twice
        NSRect aRect = [aView frame];
        float deltaHeight = aRect.size.height;
        [taskBox addSubview:aView];
        
        NSSize theNewViewSize = [taskBox frame].size;
        theNewViewSize.width += 10;
        theNewViewSize.height += deltaHeight+5;
        
        [view setFrameSize: theNewViewSize];
        [aView setFrameOrigin:NSMakePoint(15,10)];
        expandedHeight = theNewViewSize.height;
        
        [aView setAutoresizingMask:NSViewMinYMargin];
        [detailsButton setState:isExpanded];
        [self detailsAction:detailsButton];
    }
}

#pragma mark •••Actions
-(IBAction) detailsAction:(id)sender 
{
    if([sender state] == NSOnState){
        NSSize theNewViewSize = [view frame].size;
        theNewViewSize.height = expandedHeight;
        [view setFrameSize: theNewViewSize];
        isExpanded = YES;
    }
    else {
        NSSize theNewViewSize = [view frame].size;
        theNewViewSize.height = 30;
        [view setFrameSize: theNewViewSize];
        isExpanded = NO;
    }
    [[ORTaskMaster sharedTaskMaster] tileTaskViews];
    
}

-(IBAction) startAction:(id)sender
{
    [[self undoManager] disableUndoRegistration];
	@try {
		if(![[view window] makeFirstResponder:[view window]]){
			[[view window] endEditingFor:nil];		
		}
		if(taskState == eTaskStopped) {
			[startButton setTitle:@"Stop"];
			if(startIsDelayed){
				[self setTaskState:eTaskWaiting];
			}
			//start the task either right now or with a delay as specified.
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
			[self performSelector:@selector(startTask) withObject:nil afterDelay:startIsDelayed?timeDelay:0.0];
			if(startIsDelayed){
				[nextRunTimeField setObjectValue:[[NSDate date] dateByAddingTimeInterval:timeDelay]];
                [self setMessage:@"Delaying"];
			}
			else {
				[nextRunTimeField setStringValue:@"Now"];
                [self setMessage:@"Running"];
			}
			
		}
		else {
			[self stopTask];
		}
	}
	@catch(NSException* localException) {
	}
    [[self undoManager] enableUndoRegistration];
}

- (void) startTask
{
	if([self taskState] == eTaskRunning)return;
	[startButton setTitle:@"Stop"];
    NSLog(@"Starting Task: %@\n",[titleField stringValue]);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTaskDidStartNotification object:self];
    
    [self setTaskState:eTaskRunning];
    [self prepare];
    hardHalted = NO;
    [self continueTask];
}

- (void) continueTask
{
    if(taskState == eTaskWaiting){
	    NSLog(@"Task Restarting: %@\n",[titleField stringValue]);
		[[NSNotificationCenter defaultCenter] postNotificationName:ORTaskDidStartNotification object:self];
		
		[self setTaskState:eTaskRunning];
		[self prepare];
		hardHalted = NO;
    }
    
    if(	![self doWork]){	
        //OK the task is done.
        if(willRepeat && !hardHalted){
            //it will repeat so schedule a call to this method after the specified time interval.
            [self setTaskState:eTaskWaiting];
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [self performSelector:@selector(continueTask) withObject:nil afterDelay:timeInterval];
            [nextRunTimeField setObjectValue:[[NSDate date] dateByAddingTimeInterval:timeInterval]];
            [self setMessage:@"Waiting"];
            [self cleanUp];
            NSLog(@"Task Finished: %@\n",[titleField stringValue]);
            [[NSNotificationCenter defaultCenter] postNotificationName:ORTaskDidFinishNotification object:self];
        }
        else {
            //not repeating so just stop the task.
            if(!hardHalted)[self stopTask];
        }
        
    }
    else {
        //the task did not finish so schedule another call to this method asap.
        [self setTaskState:eTaskRunning];
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(continueTask) withObject:nil afterDelay:0.3];
    }
}


- (void) stopTask
{
	if([self taskState] == eTaskStopped)return;
	
    [[self undoManager] disableUndoRegistration];
	@try {
		[self setIsSlave:NO];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(continueTask) object:nil];
		if([self taskState] == eTaskRunning)NSLog(@"Task Stopped: %@\n",[titleField stringValue]);
		[self setTaskState:eTaskStopped];
		[startButton setTitle:@"Start"];
		[self finishUp];
		[nextRunTimeField setStringValue:@"Not Scheduled"];
        [self setMessage:@"Idle"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORTaskDidFinishNotification object:self];
	}
	@catch(NSException* localException) {
	}
    [[self undoManager] enableUndoRegistration];
}

- (void) hardHaltTask
{
    hardHalted = YES;
    [self stopTask];
    [self setMessage:@"Idle"];
}

-(IBAction) willRepeatAction:(id)sender
{
    [self setWillRepeat:[[willRepeatMatrix selectedCell]tag]!=0];
    [self updateButtons];
}

-(IBAction) runDelayAction:(id)sender
{
    [self setStartIsDelayed:![delayStartCB state]];
    [self updateButtons];
    
}

-(IBAction) timeDelayAction:(id)sender
{
    if([sender doubleValue] != timeDelay){
        [[self undoManager] setActionName: @"Set Task Start Delay"];
        [self setTimeDelay:[sender doubleValue]];		
    }
}

-(IBAction) timeIntervalAction:(id)sender;
{
    if([sender doubleValue] != timeInterval){
        [[self undoManager] setActionName: @"Set Task Interval"];
        [self setTimeInterval:[sender doubleValue]];		
    }
}

#pragma mark •••Notifications
- (void) updateButtons
{
    if(taskState == eTaskRunning || taskState == eTaskWaiting){
        [willRepeatMatrix setEnabled:NO];
        [delayStartCB setEnabled:NO];
        [timeDelayField setEnabled:YES];
        [timeDelayStepper setEnabled:YES];
        [timeIntervalField setEnabled:NO];
        [timeIntervalStepper setEnabled:NO];
        [self enableGUI:NO];
    }
    else {
        [willRepeatMatrix setEnabled:YES];
        [delayStartCB setEnabled:YES];
        [timeDelayField setEnabled:startIsDelayed];
        [timeDelayStepper setEnabled:startIsDelayed];
        [timeIntervalField setEnabled:willRepeat];
        [timeIntervalStepper setEnabled:willRepeat];
        [self enableGUI:YES];
    }    
    
    if([self isSlave])[startButton setEnabled:NO];
    else [startButton setEnabled:[self okToRun]];
}

#pragma mark •••Archival
static NSString* ORTaskTimeDelay  	= @"ORTaskTimeDelay";
static NSString* ORTaskTimeInterval  	= @"ORTaskTimeInterval";
static NSString* ORTaskStartDelayed  	= @"ORTaskStartDelayed";
static NSString* ORTaskWillRepeat  	= @"ORTaskWillRepeat";
static NSString* ORTaskTitle		= @"ORTaskTitle";
static NSString* ORTaskExpanded		= @"ORTaskExpanded";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"ORTask" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"ORTask" owner:self topLevelObjects:&topLevelObjects];
#endif
    [topLevelObjects retain];

    [self loadMemento:decoder];
    [[ORTaskMaster sharedTaskMaster] addTask:self];
    
    return self;
}


- (void)encodeWithCoder:(NSCoder*)encoder
{
    [self saveMemento:encoder];
}


- (void)loadMemento:(NSCoder*)decoder
{
    [[self undoManager] disableUndoRegistration];
    
    [self setTimeDelay:[decoder decodeIntegerForKey:ORTaskTimeDelay]];
    [self setTimeInterval:[decoder decodeIntegerForKey:ORTaskTimeInterval]];
    [self setStartIsDelayed:[decoder decodeBoolForKey:ORTaskStartDelayed]];
    [self setWillRepeat:[decoder decodeBoolForKey:ORTaskWillRepeat]];
    [self setTitle:[decoder decodeObjectForKey:ORTaskTitle]];
    isExpanded = [decoder decodeBoolForKey:ORTaskExpanded];
    
    [[self undoManager] enableUndoRegistration];
}

- (void)saveMemento:(NSCoder*)encoder
{
    [encoder encodeInteger:timeDelay forKey:ORTaskTimeDelay];
    [encoder encodeInteger:timeInterval forKey:ORTaskTimeInterval];
    [encoder encodeBool:startIsDelayed forKey:ORTaskStartDelayed];
    [encoder encodeBool:willRepeat forKey:ORTaskWillRepeat];
    [encoder encodeObject:title forKey:ORTaskTitle];
    [encoder encodeBool:isExpanded forKey:ORTaskExpanded];
}

- (NSData*) memento
{
    NSMutableData* memento = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:memento];
    [self saveMemento:archiver];
    [archiver finishEncoding]; 
	[archiver release];   
    return memento;
}

- (void) restoreFromMemento:(NSData*)aMemento
{
	if(aMemento){
		NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:aMemento];
		[self loadMemento:unarchiver];
		[unarchiver finishDecoding];
		[unarchiver release];   
	}
}

- (void) prepare
{
	
    doingFinishUpWork = NO;
    
    if(![[view window] makeFirstResponder:[view window]]){
        [[view window] endEditingFor:nil];		
    }
}
- (BOOL)   doWork{return  NO;}
- (void) finishUp
{
    doingFinishUpWork = YES;  
}
- (void) cleanUp {;}

@end

@implementation NSObject (ORTaskCatagory)
//subclasses will override these
- (BOOL) okToRun {return YES;}
- (void) enableGUI:(BOOL)state{}
- (void) stopTask{}
- (id)   dependentTask:(ORTask*)aTask {return nil;}
- (void) taskDidFinish:(NSNotification*)aNote{}
- (void) taskDidStart:(NSNotification*)aNote{}
- (void) taskDidStep:(NSNotification*)aNote{}
@end
