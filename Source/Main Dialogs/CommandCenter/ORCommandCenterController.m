//
//  ORCommandCenterController.m
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


#import "ORCommandCenterController.h"
#import "ORCommandCenter.h"
#import "Utilities.h"
#import "SynthesizeSingleton.h"
#import "ORScriptIDEModel.h"

@implementation ORCommandCenterController

SYNTHESIZE_SINGLETON_FOR_ORCLASS(CommandCenterController);

-(id)init
{
    self = [super initWithWindowNibName:@"CommandCenter"];
    [self setWindowFrameAutosaveName:@"CommandCenter"];
    return self;
}

- (void) dealloc
{
	[cmdField setDelegate:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
	
    [self registerNotificationObservers];
    [self updateWindow];
	[cmdField setDelegate:self];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[self commandCenter]  undoManager];
}

#pragma mark •••Accessors
- (ORCommandCenter*) commandCenter
{
    return [ORCommandCenter sharedCommandCenter];
}

- (NSString *)lastPath 
{
    return lastPath;
}

- (void)setLastPath:(NSString *)aLastPath 
{
    [lastPath autorelease];
    lastPath = [aLastPath copy];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(portChanged:)
                         name : ORCommandPortChangedNotification
                       object : [self commandCenter]];
    
    [notifyCenter addObserver : self
                     selector : @selector(clientsChanged:)
                         name : ORCommandClientsChangedNotification
                       object : [self commandCenter]];
    
    [notifyCenter addObserver : self
                     selector : @selector(commandChanged:)
                         name : ORCommandCommandChangedNotification
                       object : [self commandCenter]];

    [notifyCenter addObserver : self
                     selector : @selector(portChanged:)
                         name : ORDocumentLoadedNotification
                       object : [self commandCenter]];
 
	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];

}
- (void) endEditing
{
	//commit all text editing... subclasses should call before doing their work.
	//id oldFirstResponder = [[self window] firstResponder];
	if(![[self window] makeFirstResponder:[self window]]){
		[[self window] endEditingFor:nil];		
	}
	//[[self window] makeFirstResponder:oldFirstResponder];
}


#pragma mark •••Actions

- (IBAction) setPortAction:(id) sender;
{
    if([sender intValue] != [[self commandCenter] socketPort]){
        [[self commandCenter] setSocketPort:[sender intValue]];
        [[self commandCenter] serve];
    }
}

- (IBAction) doCmdAction:(id) sender
{
    [self performSelector:@selector(sendCommand:) withObject:[cmdField stringValue] afterDelay:.01];
}

- (IBAction) processFileAction:(id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Select"];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:[self lastPath]]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSString* path = [[openPanel URL] path];
            [self setLastPath:[path stringByDeletingLastPathComponent]];
            [self sendCommand:[NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil]];
        }
    }];

}

- (void) sendCommand:(NSString*)aCmd
{
    [[self commandCenter] handleLocalCommand:aCmd];
}

- (IBAction) saveDocument:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocumentAs:sender];
}

- (IBAction) scriptIDEAction:(id) sender
{
	[[ORCommandCenter sharedCommandCenter] openScriptIDE];
}

#pragma mark •••Interface Management
- (void) updateWindow
{
    [self portChanged:nil];
    [self clientsChanged:nil];
}

- (void) commandChanged:(NSNotification*)aNote
{
	NSString* aCommand = [[aNote userInfo] objectForKey:ORCommandCommandChangedNotification];
	if(aCommand){
		[cmdField setStringValue:aCommand];
	}
}

- (void) portChanged:(NSNotification*)aNotification;
{
    if(aNotification==nil  || [aNotification object]== [self commandCenter]){
        [portField setIntValue: [[self commandCenter] socketPort]];
    }
}

- (void) clientsChanged:(NSNotification*)aNotification
{
    if(aNotification==nil  || [aNotification object]== [self commandCenter]){
        [clientListView reloadData];
        [portField setEnabled:[[self commandCenter] clientCount]==0];
		[clientCountField setIntegerValue:[[self commandCenter] clientCount]];
    }
}

- (BOOL) control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
	if (command == @selector(moveDown:)) {
		[[self commandCenter] moveInHistoryDown];
		return YES;
	}
	if (command == @selector(moveUp:)) {
		[[self commandCenter] moveInHistoryUp];	
		return YES;
	}
	return NO;
}



#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex
{
    id obj = [[[self commandCenter] clients]  objectAtIndex:rowIndex];
    return [obj valueForKey:[aTableColumn identifier]];
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[[self commandCenter] clients] count];
}

@end


