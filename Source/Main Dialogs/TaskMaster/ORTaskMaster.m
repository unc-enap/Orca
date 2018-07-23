//
//  ORTaskMaster.m
//  Orca
//
//  Created by Mark Howe on Thu Nov 06 2003.
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


#import "ORTaskMaster.h"
#import "ORTask.h"
#import "SynthesizeSingleton.h"

@implementation ORTaskMaster

SYNTHESIZE_SINGLETON_FOR_ORCLASS(TaskMaster);

- (id) init
{
    self = [super initWithWindowNibName:@"TaskMaster"];
	[self setWindowFrameAutosaveName:@"TaskMaster"];
	[self registerNotificationObservers];
    return self;
}

- (void) dealloc
{
	sharedTaskMaster = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
}

#pragma mark ¥¥¥Accessors
- (NSView*) taskContentView
{
    return taskContentView;
}

- (void)addTask:(ORTask*)aTask
{
    NSArray*    subViews = [taskContentView subviews];
    if(![subViews containsObject:[aTask view]]){
        [taskContentView addSubview: [aTask view]];
        [self tileTaskViews];
        [[aTask view] setNeedsDisplay:YES];
    }
}

- (void) removeTask:(ORTask*)aTask
{
    if(![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(removeTask:) withObject:aTask waitUntilDone:YES];
        return;
    }
    [[aTask view] removeFromSuperview];
    [self tileTaskViews];
}

- (void) tileTaskViews
{
    NSArray* subViews   = [taskContentView subviews];
    float extraSpace         = 65;
    float totalHeightNeeded = 0;
    for (NSView* aView in subViews){
        totalHeightNeeded += [aView frame].size.height+5;
    }
    [taskContentView setFrameSize: NSMakeSize([taskContentView frame].size.width,totalHeightNeeded)];

    NSPoint origin = NSMakePoint(10,[taskContentView frame].size.height);
    for (NSView* aView in subViews){
        NSRect viewRect = [aView frame];
        origin.y -= (viewRect.size.height+5);
        [aView setFrameOrigin: origin];
    }

    if([subViews count]){
        NSSize minSize = [[subViews objectAtIndex:0] frame].size;
        minSize.width += 15;
        minSize.height += 35;
        
        [[self window] setMinSize:minSize];
    }
    NSRect windowRect = [[self window] frame];
    float oldHeight = windowRect.size.height;
    
    windowRect.size.height = totalHeightNeeded+extraSpace;
    windowRect.origin.y += (oldHeight-totalHeightNeeded-extraSpace);
    [[self window] setFrame:windowRect display:YES];
    if([subViews count]){
        NSRect aRect = [[subViews objectAtIndex:0]frame];
        aRect.origin.y +=5;
        [taskContentView scrollRectToVisible:aRect];
        [[self window] display];
    }

}



#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(documentClosed:)
                         name : ORDocumentClosedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(taskStarted:)
                         name : ORTaskDidStartNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(taskStopped:)
                         name : ORTaskDidFinishNotification
                       object : nil];
    
}

- (void) taskStarted:(NSNotification*)aNote
{
	if(!runningTasks)runningTasks = [[NSMutableArray alloc] init];
	[runningTasks addObject:[aNote object]];
	[self postRunningTaskList];
}

- (void) taskStopped:(NSNotification*)aNote
{
	[runningTasks removeObject:[aNote object]];
	if([runningTasks count] == 0){
		[runningTasks release];
		runningTasks = nil;
	}
	[self postRunningTaskList];
}

- (void) postRunningTaskList
{
	NSString* taskList = [NSString string];
	for(id aTask in runningTasks){
		taskList = [taskList stringByAppendingFormat:@"%@,",[aTask title]];
	}
	//take off the trailing ','
	taskList = [taskList stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
    [[NSNotificationCenter defaultCenter]
                postNotificationName:@"Running Tasks"
							  object:taskList];
}

- (void) documentClosed:(NSNotification*)aNote
{
	[[self window] performClose:self];
}


- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[(ORAppDelegate*)[NSApp delegate]document]  undoManager];
}


#pragma mark ¥¥¥Archival
//static NSString *ORCmdCenterDestinationObjs 	= @"ORCmdCenterDestinationObjs";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [self registerNotificationObservers];
    
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
}

- (IBAction) saveDocument:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocument:sender]; 
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocumentAs:sender];
}

@end
