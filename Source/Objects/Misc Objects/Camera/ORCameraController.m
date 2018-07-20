
//
//  ORCameraController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORCameraController.h"
#import "ORCameraModel.h"

@interface ORCameraController (private)
- (void) populateDevicePU;
@end


@implementation ORCameraController

#pragma mark •••Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"Camera"];
    return self;
}


#pragma mark •••Interface Management

- (void) deviceIndexChanged:(NSNotification*)aNote
{
	[deviceIndexPU selectItemAtIndex: [model deviceIndex]];
}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    
    [notifyCenter addObserver: self
                     selector: @selector(cameraLockChanged:)
                         name: ORCameraLock
                       object: model];

	[notifyCenter addObserver: self
                     selector: @selector(updateIntervalChanged:)
                         name: ORCameraModelUpdateIntervalChanged
                       object: model];
	
	[notifyCenter addObserver:self 
					 selector:@selector(cameraImageChanged:) 
						 name:@"CameraImageChanged"  
					   object:model];
	
	[notifyCenter addObserver:self 
					 selector:@selector(cameraRunningChanged:) 
						 name:ORCameraModelRunningChanged  
					   object:model];

	[notifyCenter addObserver:self 
					 selector:@selector(movieChanged:) 
						 name:ORCameraModelMovieChanged  
					   object:model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(historyFolderChanged:)
                         name : ORCameraModelHistoryFolderChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(saveFileIntervalChanged:)
                         name : ORCameraModelSaveFileIntervalChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(keepFileIntervalChanged:)
                         name : ORCameraModelKeepFileIntervalChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(deviceIndexChanged:)
                         name : ORCameraModelDeviceIndexChanged
						object: model];

}

- (void) awakeFromNib
{
	[self populateDevicePU];
	[super awakeFromNib];
}

- (void) updateWindow
{
	[super updateWindow];
    [self cameraLockChanged:nil];
    [self updateIntervalChanged:nil];
	[self movieChanged:nil];
	[self historyFolderChanged:nil];
	[self saveFileIntervalChanged:nil];
	[self keepFileIntervalChanged:nil];
	[self deviceIndexChanged:nil];
	[self cameraRunningChanged:nil];
}

- (void) movieChanged:(NSNotification*)aNote
{
	[mMovieView setMovie:[(ORCameraModel*)model movie]];
}

- (void) cameraRunningChanged:(NSNotification*)aNote
{
	[runStateField setStringValue:[NSString stringWithFormat:@"%@",[model running]?@"Running":@"Idle"]];
	[startStopButton setTitle:[model running]?@"Stop":@"Start"];	
	[self setButtonStates];
}

- (void) cameraImageChanged:(NSNotification*)aNote
{
	NSImage* lastImage = [[aNote object] lastImage];
	[mCaptureView setImage:lastImage];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORCameraLock to:secure];
    [cameraLockButton setEnabled:secure];
}

- (void) updateIntervalChanged:(NSNotification*)aNotification
{
	[updateIntervalPU selectItemAtIndex:[model updateInterval]];
	[self updateMovieFileSize];
}
- (void) keepFileIntervalChanged:(NSNotification*)aNote
{
	[keepFileIntervalPU selectItemAtIndex: [model keepFileInterval]];
	[self updateMovieFileSize];
}

- (void) saveFileIntervalChanged:(NSNotification*)aNote
{
	[saveFileIntervalPU selectItemAtIndex: [model saveFileInterval]];
	[self updateMovieFileSize];
}

- (void) historyFolderChanged:(NSNotification*)aNote
{
	[historyFolderField setStringValue: [[model historyFolder] stringByAbbreviatingWithTildeInPath]];
}

- (void) cameraLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORCameraLock];
    [cameraLockButton setState: locked];
	[self setButtonStates];
}
	 
- (void) setButtonStates
{
    BOOL locked = [gSecurity isLocked:ORCameraLock];
	BOOL isRunning = [model running];
	BOOL validCamera = [[deviceIndexPU titleOfSelectedItem] length]>0;
	[startStopButton setEnabled:validCamera && !locked];
    [updateIntervalPU setEnabled: !locked ];
    [deviceIndexPU setEnabled: !locked && !isRunning];
    [updateIntervalPU setEnabled: !locked ];
    [setHistoryFolderButton setEnabled: !locked ];
    [saveFileIntervalPU setEnabled: !locked ];
    [keepFileIntervalPU setEnabled: !locked ];
    [addFrameNowButton setEnabled: isRunning ];
}

- (void) updateMovieFileSize
{
	uint32_t fileSize = [model calculatedFileSizeBytes];
	NSString* s;
	if(fileSize < 1000)				s = [NSString stringWithFormat:@"%u Bytes",fileSize];
	else if(fileSize < 1000000)		s = [NSString stringWithFormat:@"%.1f KB",fileSize/1000.];
	else if(fileSize < 1000000000)	s = [NSString stringWithFormat:@"%.1f MB",fileSize/1000000.];
	else							s = [NSString stringWithFormat:@"%.1f GB",fileSize/1000000000.];
	
	[movieSizeField setStringValue:s];
}

#pragma mark •••Actions
- (IBAction) addFrameNowAction:(id)sender
{
	[model addFrameNow];
}

- (IBAction) deviceIndexAction:(id)sender
{
	[model setDeviceIndex:[sender indexOfSelectedItem]];	
}

- (IBAction) keepFileIntervalAction:(id)sender
{
	[model setKeepFileInterval:[sender indexOfSelectedItem]];	
}

- (IBAction) saveFileIntervalAction:(id)sender
{
	[model setSaveFileInterval:[sender indexOfSelectedItem]];	
}
- (IBAction) startSession:(id)sender
{
	if([model running]) [model stopSession];
	else				[model startSession];
}

- (IBAction) updateIntervalAction:(id)sender
{
	[model setUpdateInterval:[sender indexOfSelectedItem]];
}

- (IBAction)cameraLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORCameraLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) viewPastHistoryAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
    if([model historyFolder]){
        startingDir = [model historyFolder];
    }
    else {
        startingDir = NSHomeDirectory();
    }
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* fileName = [[[openPanel URL] path] stringByAbbreviatingWithTildeInPath];
            QTMovie *newMovie = [[QTMovie alloc] initWithFile:[fileName stringByExpandingTildeInPath] error:nil];
            if (newMovie) {
                [mMovieView setMovie:newMovie];
            }
            [newMovie release];
        }
    }];

}

- (IBAction) viewCurrentAction:(id)sender
{
	[mMovieView setMovie:[(ORCameraModel*)model movie]];
}


- (IBAction) setHistoryFolderAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
	[openPanel setCanCreateDirectories:YES];
    NSString* startingDir;
    if([model historyFolder]){
        startingDir = [model historyFolder];
    }
    else {
        startingDir = NSHomeDirectory();
    }
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* folderName = [[[openPanel URL] path] stringByAbbreviatingWithTildeInPath];
            [model setHistoryFolder:folderName];
        }
    }];

}

@end

@implementation ORCameraController (private)

- (void) populateDevicePU
{
	NSArray* videoDevices = [model videoDevices];
	[deviceIndexPU removeAllItems];
	for(id aDevice in videoDevices){
		[deviceIndexPU addItemWithTitle:[aDevice description]];
	}
}

@end
