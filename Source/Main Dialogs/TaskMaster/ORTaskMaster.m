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
#import "ORCouchDBModel.h"
#import "ORScriptInterface.h"
#import "ORScriptTaskModel.h"
#import "ORScriptRunner.h"
#import "SynthesizeSingleton.h"

@implementation ORTaskMaster

SYNTHESIZE_SINGLETON_FOR_ORCLASS(TaskMaster);

- (id) init
{
    self = [super initWithWindowNibName:@"TaskMaster"];
	[self setWindowFrameAutosaveName:@"TaskMaster"];
    postScriptsToCouchDB = NO;
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

// respond to fullID like OrcaObjects to allow posting to the CouchDB object if it is present
// should only be one task master around, so no need to keep track of unique identifier
- (NSString*) fullID
{
    return @"ORTaskMaster";
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
    
    [notifyCenter addObserver : self
                     selector : @selector(postRunningScriptsChanged:)
                         name : ORCouchDBModelPostRunningScriptsChanged
                       object : nil];
}

- (void) taskStarted:(NSNotification*)aNote
{
    // add task to list of running tasks
	if(!runningTasks)runningTasks = [[NSMutableArray alloc] init];
	[runningTasks addObject:[aNote object]];
    // if this is an ORScriptInterface, it was started from the script GUI, make the view consistent with running status
    if([[aNote object] isKindOfClass:[ORScriptInterface class]]){
        ORScriptInterface* task = [aNote object];
        [[task getStartButton] setTitle:@"Stop"];
        [[task getRunStateField] setStringValue:@"Running"];
        [[task getNextRunTimeField] setStringValue:@"Now"];
    }
    // update the running task list in the database if option is selected in couchdb
	[self postRunningTaskList];
}

- (void) taskStopped:(NSNotification*)aNote
{
    // if this is an ORScriptInterface, it was started from the script GUI, make the view consistent with running status
    if([[aNote object] isKindOfClass:[ORScriptInterface class]]){
        ORScriptInterface* task = [aNote object];
        [[task getStartButton] setTitle:@"Start"];
        [[task getRunStateField] setStringValue:@"Stopped"];
        [[task getNextRunTimeField] setStringValue:@"Not Scheduled"];
    }
    // remove object from list of running tasks
	[runningTasks removeObject:[aNote object]];
	if([runningTasks count] == 0){
		[runningTasks release];
		runningTasks = nil;
	}
    // update the running task list in the database if option is selected in couchdb
	[self postRunningTaskList];
}

- (void) postRunningScriptsChanged:(NSNotification*)note
{
    id obj = [note object];
    if(!obj) return;
    if(![obj isKindOfClass:[ORCouchDBModel class]]) return;
    postScriptsToCouchDB = [obj postRunningScripts];
    if(postScriptsToCouchDB) [self postRunningTaskList];
}

- (void) postRunningTaskList
{
	NSString* taskList = [NSString string];
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    NSMutableArray* scriptTasks = [NSMutableArray array];
	for(id aTask in runningTasks){
		taskList = [taskList stringByAppendingFormat:@"%@,",[aTask title]];
        if(postScriptsToCouchDB && [aTask isKindOfClass:[ORScriptInterface class]]){
            id script = [aTask delegate];
            if(!script) continue;
            if([script isKindOfClass:[ORScriptTaskModel class]]){
                [scriptTasks addObject:[aTask title]];
                [script addScriptToDictionary:dict];
            }
        }
	}
	//take off the trailing ','
	taskList = [taskList stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Running Tasks" object:taskList];
    // post the running script dictionaries to the database if option is set
    if(postScriptsToCouchDB){
        [dict setObject:scriptTasks forKey:@"runningTasks"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:dict];
    }
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
