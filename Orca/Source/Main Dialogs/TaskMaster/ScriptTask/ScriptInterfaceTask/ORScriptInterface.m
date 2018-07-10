//
//  ORScriptInterface.m
//  Orca
//
//  Created by Mark Howe on Oct 8, 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORScriptInterface.h"
#import "ORScriptTaskModel.h"
#import "ORScriptRunner.h"

@implementation ORScriptInterface
-(id)	init
{
    if( self = [super init] ){
#if !defined(MAC_OS_X_VERSION_10_9)
        [NSBundle loadNibNamed:@"ScriptInterfaceTask" owner:self];
#else
        [[NSBundle mainBundle] loadNibNamed:@"ScriptInterfaceTask" owner:self topLevelObjects:&scriptInterfaceTaskObjects];
#endif
        
        [scriptInterfaceTaskObjects retain];

        
        [self setTitle:@"Orca Script"];
    }
    return self;
}

- (void) delloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [scriptInterfaceTaskObjects release];
    [super dealloc];
}


- (void) awakeFromNib
{
    [super awakeFromNib];
    [self addExtraPanel:extraView];
}

- (BOOL) okToRun
{
    return YES;
}

- (void) setDelegate:(id)aDelegate
{
	[super setDelegate:aDelegate];
	[self breakChainChanged:nil];
    [self registerNotificationObservers];
}

- (void) registerNotificationObservers
{	
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(breakChainChanged:)
                         name : ORScriptIDEModelBreakChainChanged
						object: delegate];	

    [notifyCenter addObserver : self
                     selector : @selector(nameChanged:)
                         name : ORScriptIDEModelNameChanged
						object: delegate];
	
    [notifyCenter addObserver : self
                     selector : @selector(runningChanged:)
                         name : ORScriptRunnerRunningChanged
						object: [delegate scriptRunner]];	
	
}


- (void) breakChainChanged:(NSNotification*)aNote
{
	[breakChainButton setState:[delegate breakChain]];
}

- (void) nameChanged:(NSNotification*)aNote
{
	[self setTitle:[delegate scriptName]];
}

- (void) runningChanged:(NSNotification*)aNote
{
	if([[delegate scriptRunner] running])[self setMessage:@"Running"];
	else [self setMessage:@"Idle"];
}

#pragma mark ¥¥¥Actions

- (IBAction) editAction:(id)sender
{
	[delegate showMainInterface];
}

- (IBAction) breakChainAction:(id) sender
{
	[delegate setBreakChain:[sender intValue]];
}


#pragma mark ¥¥¥Task Methods
- (void) stopTask
{
	[delegate stopScript];
	[super stopTask];
}

- (void) prepare
{
    [super prepare];
	didStart = NO;
	waitedOnce = NO;
}


- (BOOL)  doWork
{
	if(!didStart){
		[delegate runScript];
		didStart = YES;
	}
	if(waitedOnce){
		if([delegate running])return YES;
		else return NO;
	}
	waitedOnce = YES;
	return YES;
}


- (void) finishUp
{
    [super finishUp];
    
    //[self setMessage:@"Idle"];
}

- (void) cleanUp
{
   // [self setMessage:@"Idle"];
}



- (NSString*) description
{
    return @"TDB";
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [self registerNotificationObservers];
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"ScriptInterfaceTask" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"ScriptInterfaceTask" owner:self topLevelObjects:&scriptInterfaceTaskObjects];
#endif
    
    [scriptInterfaceTaskObjects retain];

    [[self undoManager] disableUndoRegistration];
 
    [[self undoManager] enableUndoRegistration];    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
}
@end
