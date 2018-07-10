//
//  ORScriptController.m
//  Orca
//
//  Created by Mark Howe on Sun Sept 16, 2007.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

#pragma mark ¥¥¥Imported Files
#import "ORScriptController.h"
#import "ORScriptModel.h"

@interface ORScriptController (private)
-(void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end

@implementation ORScriptController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Script"];
    return self;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver: self
                     selector: @selector(scriptLockChanged:)
                         name: ORScriptLock
                       object: nil];

    [notifyCenter addObserver: self
                     selector: @selector(scriptPathChanged:)
                         name: ORScriptPathChanged
                       object: model];
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self scriptLockChanged:nil];
    [self scriptPathChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORScriptLock to:secure];
    [scriptLockButton setEnabled:secure];
}

- (void) scriptLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORScriptLock];
    [scriptLockButton setState: locked];
    [pathButton setEnabled: !locked];
}

- (void) scriptPathChanged:(NSNotification*)aNote
{
	[pathField setStringValue:[[model scriptPath] stringByAbbreviatingWithTildeInPath]];
}

#pragma mark ¥¥¥Actions
-(IBAction)scriptLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORScriptLock to:[sender intValue] forWindow:[self window]];
}

-(IBAction)scriptPathAction:(id)sender
{
   NSString* startDir = NSHomeDirectory(); //default to home
    if([model scriptPath]){
        startDir = [[model scriptPath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* fileName = [[[openPanel URL]path] stringByAbbreviatingWithTildeInPath];
            [model setScriptPath:fileName];
        }
    }];
}
@end
