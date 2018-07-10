//
//  ORAppDelegate.h
//  Orca
//
//  Created by Mark Howe on Tue Dec 03 2002.
//  Copyright  © 2002 CENPA, University of Washington. All rights reserved.
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

@class ORAlarmCollection;
@class MemoryWatcher;
@class ORSplashWindowController;
@class ORHelpCenter;
@class ORWindowSaveSet;

@interface ORAppDelegate : NSObject {
    id					document;
    ORAlarmCollection*	alarmCollection;
    MemoryWatcher*		memoryWatcher;
    ORSplashWindowController* theSplashController;
	IBOutlet ORHelpCenter*	  helpCenter;
	IBOutlet ORWindowSaveSet* windowSaveSet;
	NSString* ethernetHardwareAddress;
	BOOL configLoadedOK;
	NSOperationQueue* queue;
	unsigned long heartbeatCount;
	BOOL delayTermination;
}

- (BOOL)   inDebugger;
- (MemoryWatcher*) memoryWatcher;
- (void) setMemoryWatcher:(MemoryWatcher*)aWatcher;
- (ORAlarmCollection*) alarmCollection;
- (void) setAlarmCollection:(ORAlarmCollection*)someAlarms;
- (void) mailCrashLogs;
- (void) deleteCrashLogs;
- (void) closeSplashWindow;
- (ORHelpCenter*) helpCenter;
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
- (NSString*) ethernetHardwareAddress;
- (BOOL) configLoadedOK;
- (void) delayTermination;
- (void) delayedTermination;
- (void) restart:(id)sender withConfig:(NSString*)aConfig;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) applicationDidFinishLaunching:(NSNotification*)aNotification;
- (void) heartbeatEnabledChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) showProcessCenter:(id)sender;
- (IBAction) showAlarms:(id)sender;
- (IBAction) showTaskMaster:(id)sender;
- (IBAction) showHardwareWizard:(id)sender;
- (IBAction) showStatusLog:(id)sender;
- (IBAction) newDocument:(id)sender;
- (IBAction) openDocument:(id)sender;
- (IBAction) terminate:(id)sender;
- (IBAction) showCommandCenter:(id)sender;
- (IBAction) showCatalog:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (IBAction) showMemoryWatcher:(id)sender;
- (IBAction) showWindowList:(id)sender;
- (IBAction) showORCARootServiceController:(id)sender;
- (IBAction) showTemplates:(id)sender;
- (IBAction) openRecentDocument:(id)sender;
- (IBAction) showAutoTester:(id)sender;
- (IBAction) restoreToCmdOneSet:(id)sender;
- (IBAction) showArchive:(id)sender;
- (IBAction) showHardwareFinder:(id)sender;

#pragma mark ¥¥¥Accessors
- (id) document;
- (void) setDocument:(id)aDocument;
- (NSUndoManager*) undoManager;

- (void) doHeartBeatAfterDelay;
- (void) doHeartBeat;
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context;

@end

NSString* OROrcaAboutToQuitNotice;
NSString* OROrcaFinalQuitNotice;


@interface ORHeartBeatOp : NSOperation
{
	unsigned long heartbeatCount;
}
- (id) init:(unsigned long)aCount;
- (void) main;
@end

