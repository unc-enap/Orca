//
//  ORXL1Controller.m
//  Orca
//
//  Created by Mark Howe on 10/30/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
//
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

#import "ORXL1Controller.h"
#import "ORXL1Model.h"

#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
@interface ORXL1Controller (private)
- (void) setClockFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) setXilinxFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
- (void) setCableFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
@end
#endif

@implementation ORXL1Controller

-(id)init
{
    self = [super initWithWindowNibName:@"XL1"];
    return self;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
					 selector : @selector(xlinixFileChanged:)
						 name : ORXL1XilinxFileChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(clockFileChanged:)
                         name : ORXL1ClockFileChanged
						object: model];

	[notifyCenter addObserver : self
			 selector : @selector(cableFileChanged:)
			     name : ORXL1CableFileChanged
			   object : model];

	[notifyCenter addObserver : self
					 selector : @selector(adcClockChanged:)
						 name : ORXL1AdcClockChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(sequencerClockChanged:)
						 name : ORXL1SequencerClockChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(memoryClockChanged:)
						 name : ORXL1MemoryClockChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(memoryClockChanged:)
						 name : ORXL1AlowedErrorsChanged
					   object : model];

	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORXL1Lock
						object: nil];


}
- (void) updateWindow
{
    [super updateWindow];
    [self lockChanged:nil];
	[self adcClockChanged:nil];
	[self sequencerClockChanged:nil];
	[self memoryClockChanged:nil];
	[self xlinixFileChanged:nil];
	[self clockFileChanged:nil];
	[self cableFileChanged:nil];
	[self updateButtons];
}

- (void) clockFileChanged:(NSNotification*)aNote
{
	[clockFileTextField setStringValue: [[model clockFile] stringByAbbreviatingWithTildeInPath]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORXL1Lock to:secure];
    [lockButton setEnabled:secure];
 	[self updateButtons];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORXL1Lock];
    [lockButton setState: locked];	
}

- (void) updateButtons
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORXL1Lock];
	[xlinixSelectFileButton	setEnabled: !lockedOrRunningMaintenance];
	[clockSelectFileButton	setEnabled: !lockedOrRunningMaintenance];
	[cableSelectFileButton	setEnabled: !lockedOrRunningMaintenance];
	[adcClockField			setEnabled: !lockedOrRunningMaintenance];
	[adcClockStepper		setEnabled: !lockedOrRunningMaintenance];
	[sequencerClockField	setEnabled: !lockedOrRunningMaintenance];
	[sequencerClockStepper	setEnabled: !lockedOrRunningMaintenance];
	[memoryClockField		setEnabled: !lockedOrRunningMaintenance];
	[memoryClockStepper		setEnabled: !lockedOrRunningMaintenance];
}

- (void) xlinixFileChanged:(NSNotification*)aNote
{
	[xlinixFileField setStringValue:[[model xilinxFile] stringByAbbreviatingWithTildeInPath]];
}

- (void) cableFileChanged:(NSNotification*)aNote
{
	[cableFileTextField setStringValue:[[model cableFile] stringByAbbreviatingWithTildeInPath]];
}

- (void) adcClockChanged:(NSNotification*)aNote
{
	[adcClockField setFloatValue:[model adcClock]];
	[adcClockStepper setFloatValue:[model adcClock]];
}

- (void) sequencerClockChanged:(NSNotification*)aNote
{
	[sequencerClockField setFloatValue:[model sequencerClock]];
	[sequencerClockStepper setFloatValue:[model sequencerClock]];
}

- (void) memoryClockChanged:(NSNotification*)aNote
{
	[memoryClockField setFloatValue:[model memoryClock]];
	[memoryClockStepper setFloatValue:[model memoryClock]];
}

#pragma mark •••Actions

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORXL1Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) xlinixFileAction:(id) sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	
	NSString* fullPath = [[model xilinxFile] stringByExpandingTildeInPath];
    if(fullPath)	startingDir = [[model xilinxFile] stringByDeletingLastPathComponent];
    else			startingDir = NSHomeDirectory();
	
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setXilinxFile:[[openPanel URL] path]];
            NSLog(@"FEC Xilinx default file set to: %@\n",[[[[openPanel URL] path] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]);
       }
    }];
#else 	
    [openPanel beginSheetForDirectory:startingDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(setXilinxFileDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
#endif
}

- (IBAction) clockFileAction:(id) sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
	
	NSString* fullPath = [[model clockFile] stringByExpandingTildeInPath];
    if(fullPath)	startingDir = [[model clockFile] stringByDeletingLastPathComponent];
    else			startingDir = NSHomeDirectory();
	
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setClockFile:[[openPanel URL] path]];
            NSLog(@"FEC Clock default file set to: %@\n",[[[[openPanel URL] path] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]);
        }
    }];
#else 	
    [openPanel beginSheetForDirectory:startingDir
                                 file:nil
                                types:nil
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(setClockFileDidEnd:returnCode:contextInfo:)
                          contextInfo:NULL];
#endif
}

- (IBAction) cableFileAction:(id) sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Choose"];
	NSString* startingDir;
	
	NSString* fullPath = [[model cableFile] stringByExpandingTildeInPath];
	if(fullPath)	startingDir = [[model cableFile] stringByDeletingLastPathComponent];
	else			startingDir = NSHomeDirectory();
	
#if defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setCableFile:[[openPanel URL] path]];
            NSLog(@"CableDB.h default file set to: %@\n",[[[[openPanel URL] path] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]);
        }
    }];
#else 
    [openPanel beginSheetForDirectory:startingDir
				     file:nil
				    types:nil
			   modalForWindow:[self window]
			    modalDelegate:self
			   didEndSelector:@selector(setCableFileDidEnd:returnCode:contextInfo:)
			      contextInfo:NULL];
#endif
}


- (IBAction) adcClockAction:(id) sender
{
	[model setAdcClock:[sender floatValue]];
}

- (IBAction) sequencerClockAction:(id) sender
{
	[model setSequencerClock:[sender floatValue]];
}

- (IBAction) memoryClockAction:(id) sender
{
	[model setMemoryClock:[sender floatValue]];
}

@end

#if !defined(MAC_OS_X_VERSION_10_6) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6 // 10.6-specific
@implementation ORXL1Controller (private)
- (void) setXilinxFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model setXilinxFile:[[sheet filenames] objectAtIndex:0]];
		NSLog(@"FEC Xilinx default file set to: %@\n",[[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]);
    }
}


- (void) setClockFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode){
        [model setClockFile:[[sheet filenames] objectAtIndex:0]];
		NSLog(@"FEC Clock default file set to: %@\n",[[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]);
    }
}


- (void) setCableFileDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if(returnCode){
		[model setCableFile:[[sheet filenames] objectAtIndex:0]];
		NSLog(@"CableDB.h default file set to: %@\n",[[[[sheet filenames] objectAtIndex:0] stringByAbbreviatingWithTildeInPath] stringByDeletingPathExtension]);
	}
}
@end
#endif
