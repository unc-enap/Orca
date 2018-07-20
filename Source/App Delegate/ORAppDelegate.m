//
//  ORAppDelegate.m
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
#import "ORHeartBeat.h"
#import "ORAutoTester.h"
#import "ORCommandCenter.h"
#import "ORHWWizardController.h"
#import "ORStatusController.h"
#import "ORAlarmController.h"
#import "ORCommandCenterController.h"
#import "ORCatalogController.h"
#import "ORPreferencesController.h"
#import "ORTaskMaster.h"
#import "MemoryWatcherController.h"
#import "MemoryWatcher.h"
#import "ORAlarmCollection.h"
#import "ORSplashWindowController.h"
#import "ORProcessCenter.h"
#import "ORWindowListController.h"
#import "ORCARootService.h"
#import "ORCARootServiceController.h"
#import "ORMailer.h"
#import "OrcaObjectController.h"
#import "ORWindowSaveSet.h"
#import "ORArchive.h"
#import "ORVXI11HardwareFinderController.h"
#import "NSApplication+Extensions.h"
#import <WebKit/WebKit.h>
#import "ORHelpCenter.h"

#import <sys/sysctl.h>
#include <sys/types.h>
#include <unistd.h>

#if defined(MAC_OS_X_VERSION_10_9) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9)
NSString* kCrashLogDir               = @"~/Library/Logs/DiagnosticReports";
NSString* kLastCrashLog              = @"~/Library/Logs/DiagnosticReports/LastOrca.crash.log";
#else
NSString* kCrashLogDir               = @"~/Library/Logs/CrashReporter";
NSString* kLastCrashLog              = @"~/Library/Logs/CrashReporter/LastOrca.crash.log";
#endif

NSString* OROrcaAboutToQuitNotice    = @"OROrcaAboutToQuitNotice";
NSString* OROrcaFinalQuitNotice      = @"OROrcaFinalQuitNotice";

#define kORSplashScreenDelay    1
#define kHeartbeatPeriod        30 //seconds
#define kLogSnapShotPeriod      15 //minutes

@implementation ORAppDelegate

+ (void) initialize
{	
    
    static BOOL initialized = NO;
    if ( !initialized ) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *initialUserDefaults = [NSMutableDictionary dictionaryWithObject: [NSNumber numberWithBool:YES] forKey:OROpeningDocPreferences];
        [initialUserDefaults setObject:dataForColor([NSColor whiteColor])  forKey:ORBackgroundColor];
        [initialUserDefaults setObject:dataForColor([NSColor blackColor])  forKey:ORLineColor];
        [initialUserDefaults setObject:[NSNumber numberWithInt:0] forKey:ORLineType];
        
        [initialUserDefaults setObject:[NSNumber numberWithInt:0] forKey:OROpeningDialogPreferences];
        [initialUserDefaults setObject:[NSNumber numberWithBool:NO] forKey:OROrcaSecurityEnabled];
        
        [initialUserDefaults setObject:[NSNumber numberWithBool:NO] forKey:ORMailBugReportFlag];
        [initialUserDefaults setObject:@"" forKey:ORMailBugReportEMail];
        
        [initialUserDefaults setObject:dataForColor([NSColor whiteColor])  forKey:ORScriptBackgroundColor];
        [initialUserDefaults setObject:dataForColor([NSColor redColor])  forKey:ORScriptCommentColor];
        [initialUserDefaults setObject:dataForColor([NSColor brownColor])  forKey:ORScriptStringColor];//was greenColor; several users asked me to change it (however, it is changeable at preferences ...) -tb-
        [initialUserDefaults setObject:dataForColor([NSColor blueColor])  forKey:ORScriptIdentifier1Color];
        [initialUserDefaults setObject:dataForColor([NSColor grayColor])  forKey:ORScriptIdentifier2Color];
        [initialUserDefaults setObject:dataForColor([NSColor orangeColor])  forKey:ORScriptConstantsColor];
        
		[initialUserDefaults setObject:[NSNumber numberWithBool:YES]  forKey:ORHelpFilesUseDefault];
		[initialUserDefaults setObject:@"" forKey:ORHelpFilesPath];

		[initialUserDefaults setObject:[NSNumber numberWithInt:1] forKey:ORPrefHeartBeatEnabled];
		[initialUserDefaults setObject:[NSNumber numberWithInt:1] forKey:ORPrefPostLogEnabled];
		[initialUserDefaults setObject:@"" forKey:ORPrefHeartBeatPath];

        //default to using Apple Mail
        [initialUserDefaults setObject:[NSNumber numberWithBool:0] forKey:ORMailSelectionPreference];
		
        [defaults registerDefaults:initialUserDefaults];
        initialized = YES;
        
        //make some globals
        [ORGlobal sharedGlobal]; 
        [ORSecurity sharedSecurity];
    }
}

- (id) init
{
	self = [super init];
	theSplashController = [[ORSplashWindowController alloc] init];
	[theSplashController showWindow:self];
	
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
	NSString* noKill				 = [standardDefaults stringForKey:@"startup"];
	if(![noKill isEqualToString:@"NoKill"]){
        NSString* bundleID = [[NSRunningApplication currentApplication] bundleIdentifier];
        NSArray* launchedApps = nil;
        if(bundleID){
             launchedApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleID];
        }
        if([launchedApps count]>1)[NSApp terminate:self];

	}
    
    [NSThread setThreadPriority:1];

	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [alarmCollection release];
    [memoryWatcher release];
	[ethernetHardwareAddress release];
	[queue removeObserver:self forKeyPath:@"operations"];
	[queue cancelAllOperations];
	[queue release];
    [super dealloc];
}    

- (void) awakeFromNib
{
    [self registerNotificationObservers];
    [self setAlarmCollection:[[[ORAlarmCollection alloc] init] autorelease]];
    [self setMemoryWatcher:[[[MemoryWatcher alloc] init] autorelease]];
}

- (BOOL) inDebugger
{
    int                 mib[4];
    struct kinfo_proc   info;
    
    info.kp_proc.p_flag = 0;
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    size_t size = sizeof(info);
    int err = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    //In debugger if the P_TRACED flag is set.
    if(err == 0) return ((info.kp_proc.p_flag & P_TRACED) != 0);
    else         return NO; //just return NO on error
}

- (ORHelpCenter*) helpCenter
{
	return helpCenter;
}

- (MemoryWatcher*) memoryWatcher
{
    return memoryWatcher;
}

- (void) setMemoryWatcher:(MemoryWatcher*)aWatcher
{
	[aWatcher retain];
	[memoryWatcher release];
	memoryWatcher = aWatcher;
}

- (ORAlarmCollection*) alarmCollection
{
	return alarmCollection;
}

- (void) setAlarmCollection:(ORAlarmCollection*)someAlarms
{
	[someAlarms retain];
	[alarmCollection release];
	alarmCollection = someAlarms;
}
- (NSString*) ethernetHardwareAddress
{
	if(![ethernetHardwareAddress length]){
		ethernetHardwareAddress = macAddress();
		[ethernetHardwareAddress retain];
	}
	return ethernetHardwareAddress;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(heartbeatEnabledChanged:)
                         name : ORPrefHeartBeatEnabledChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(heartbeatEnabledChanged:)
                         name : ORPrefPostLogEnabledChanged
                       object : nil];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(heartbeatEnabledChanged:)
                         name : ORPrefHeartBeatPathChanged
                       object : nil];
}

- (void) heartbeatEnabledChanged:(NSNotification *)aNotification
{
    BOOL enabled   = [[[NSUserDefaults standardUserDefaults] objectForKey:ORPrefHeartBeatEnabled] intValue]; 
    enabled		   |= [[[NSUserDefaults standardUserDefaults] objectForKey:ORPrefPostLogEnabled] intValue]; 
	if(enabled){
		heartbeatCount = 0;
		[self doHeartBeat];
	}
	else {
		[queue cancelAllOperations];
	}
}

- (void) applicationWillTerminate:(NSNotification *)aNotification
{
	[queue cancelAllOperations];
    if([[[NSUserDefaults standardUserDefaults] objectForKey:ORPrefHeartBeatEnabled] intValue]){
        NSString* finalPath = [[[NSUserDefaults standardUserDefaults] objectForKey:ORPrefHeartBeatPath] stringByAppendingPathComponent:@"Heartbeat"];
        uint32_t now = (uint32_t)[[NSDate date] timeIntervalSince1970];
        NSString* contents = [NSString stringWithFormat:@"Quit:%u",now];
        [contents writeToFile:finalPath atomically:YES encoding:NSASCIIStringEncoding error:nil];
    }

	[[ORProcessCenter sharedProcessCenter] stopAll:nil];
	[ORTimer delay:0.3];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORAppTerminating" object:self];
}

#pragma mark ¥¥¥Actions
- (IBAction) showArchive:(id)sender
{
    [[ORArchive sharedArchive] showWindow:self];
}

- (IBAction) showHardwareFinder:(id)sender
{
    [[ORVXI11HardwareFinderController sharedVXI11HardwareFinderController] showWindow:self];
}

- (IBAction) restoreToCmdOneSet:(id)sender
{
	[windowSaveSet restoreToCmdOneSet:sender];
}

- (IBAction) showTemplates:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORShowTemplates" object:self];	
}

- (IBAction) showWindowList:(id)sender
{
    [[[ORWindowListController sharedWindowListController] window] orderFront:nil];
}

- (IBAction) showStatusLog:(id)sender
{
    [[[ORStatusController sharedStatusController] window] orderFront:nil];
}

- (IBAction) showCommandCenter:(id)sender
{
    [[[ORCommandCenterController sharedCommandCenterController] window] orderFront:nil];
}

- (IBAction) showAutoTester:(id)sender
{
    [[[ORAutoTester sharedAutoTester] window] orderFront:nil];
}

- (IBAction) showORCARootServiceController:(id)sender
{
    [[[ORCARootServiceController sharedORCARootServiceController] window] orderFront:nil];
}

- (IBAction) showMemoryWatcher:(id)sender
{
    MemoryWatcherController* watcher = [MemoryWatcherController sharedMemoryWatcherController];
    [watcher setMemoryWatcher:memoryWatcher];
    [[watcher window] orderFront:nil];
    
}

- (IBAction) showProcessCenter:(id)sender
{
    [[[ORProcessCenter sharedProcessCenter] window] orderFront:nil];
}

- (IBAction) showTaskMaster:(id)sender
{
    [[[ORTaskMaster sharedTaskMaster] window] orderFront:nil];
}

- (IBAction) showHardwareWizard:(id)sender
{
    [[[ORHWWizardController sharedHWWizardController] window] orderFront:nil];
}

- (IBAction) showAlarms:(id)sender
{
    [[[ORAlarmController sharedAlarmController] window] orderFront:nil];
}

- (IBAction) showCatalog:(id)sender
{
    [[[ORCatalogController sharedCatalogController] window] orderFront:nil];
}

- (IBAction) showPreferences:(id)sender
{
    [[[ORPreferencesController sharedPreferencesController] window] orderFront:nil];
}

- (IBAction) newDocument:(id)sender
{
    //we implement this method ONLY so we can do the validation of the menu item
    [[NSDocumentController sharedDocumentController] newDocument:sender];
	[[self undoManager] removeAllActions];
}

- (IBAction) openDocument:(id)sender
{
    //we implement this method ONLY so we can do the validation of the menu item
    [[NSDocumentController sharedDocumentController] openDocument:sender];
}

- (IBAction) openRecentDocument:(id)sender
{
    //we implement this method ONLY so we can do the validation of the menu item
	//nothing to do... everything is in the submenu and handled by the doc controller
}

- (IBAction) terminate:(id)sender
{
    BOOL cancel = NO;
    int runningProcessCount = [[ORProcessCenter sharedProcessCenter] numberRunningProcesses];
	if(runningProcessCount>0){
        NSString* s = [NSString stringWithFormat:@"Quitting will stop %d Running Process%@!",runningProcessCount,runningProcessCount>1?@"es":@""];
        cancel = ORRunAlertPanel(s, @"Is this really what you want?", @"Cancel", @"Stop Processes and Quit",nil);

	}
	if(!cancel){
        delayTermination = NO;
		[[ORCommandCenter sharedCommandCenter] closeScriptIDE];
		[ORTimer delay:1];
		
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:ORNormalShutDownFlag];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO]  forKey:ORWasInDebuggerFlag];

		[[NSUserDefaults standardUserDefaults] synchronize];

        [[NSNotificationCenter defaultCenter] postNotificationName:OROrcaAboutToQuitNotice object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:OROrcaFinalQuitNotice object:self];

        if(delayTermination){
            NSLog(@"delaying termination for 5 seconds\n");
            [self performSelector:@selector(delayedTermination) withObject:self afterDelay:5];
        }
        else [NSApp terminate:sender];
	}
}

- (void) delayedTermination
{
    [NSApp terminate:self];
}

- (void) delayTermination
{
    delayTermination = YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	return [[ORGlobal sharedGlobal] canQuitDuringRun] || ![[ORGlobal sharedGlobal] runInProgress];
}

#pragma mark ¥¥¥Accessors

- (id) document
{
	return document;
}
- (void) setDocument:(id)aDocument
{
	if(aDocument && document){
		ORRunAlertPanel(@"Experiment Already Open",@"Only one experiment can be active at a time.",nil,nil,nil);
		[NSException raise:@"Document already open" format:@""];
	}
	document = aDocument;
}

- (BOOL) configLoadedOK
{
	return configLoadedOK;
}

- (void) restart:(id)sender withConfig:(NSString*)aConfig
{
    if([aConfig length] == 0){
        aConfig = [[NSUserDefaults standardUserDefaults] objectForKey: ORLastDocumentName];
    }
    NSMutableArray* arguments = nil;
    if([aConfig length]!=0)arguments = [NSMutableArray arrayWithObjects:@"--forceLoad",aConfig,nil];
    [NSApp relaunch:sender arguments:arguments];
}

#pragma mark ¥¥¥Notification Methods
-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
	[self showStatusLog:self];
    
    bool debugging = [self inDebugger];
    NSLog(@"--------------------------------------------------------\n");
    NSLog(@"   Orca (v%@)\n",fullVersion());
    if(debugging)NSLog(@"   Running in the debugger\n");
    NSNumber* shutdownFlag = [[NSUserDefaults standardUserDefaults] objectForKey:ORNormalShutDownFlag];
    if(shutdownFlag && ([shutdownFlag boolValue]==NO)){
		NSLog(@"   Last Run ending with crash or debugger hard stop\n");
    }
#if __LP64__
    NSLog(@"   Compiled in 64-bit mode\n");
#else
    NSLog(@"   Compiled in 32-bit mode\n");
#endif

    NSLog(@"--------------------------------------------------------\n");

    NSString *version = [[NSProcessInfo processInfo] operatingSystemVersionString];
    NSString* updateNotice = @"";
    
    #if defined(MAC_OS_X_VERSION_10_8) && MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_8
        updateNotice = @"(Note: You are using old version of MacOS. Please update)";
    #endif

    NSLog(@"Running MacOS %@ %@\n", version,updateNotice);
    NSLog(@"Mac Address: %@\n",[self ethernetHardwareAddress]);
    NSLog(@"Machine Name: %@\n",computerName());
	NSString* theAppPath = appPath();
	if(theAppPath)	NSLog(@"Launch Path: %@\n",theAppPath);

    if(shutdownFlag && ([shutdownFlag boolValue]==NO)){
        [self mailCrashLogs];
    }
	else {
        [self deleteCrashLogs];
    }
    

    NSError* fileOpenError = nil;
	configLoadedOK = NO;
    
	@try {
		if(![[NSApp orderedDocuments] count] && ![self applicationShouldOpenUntitledFile:NSApp]){
			
			NSString* lastFile = [[NSUserDefaults standardUserDefaults] stringForKey:@"forceLoad"]; //this is from relaunch argument
            BOOL relaunched = [lastFile length]!=0;
			if(![lastFile length])lastFile = [[NSUserDefaults standardUserDefaults] objectForKey: ORLastDocumentName];
			
			if([lastFile length]){
				NSLog(@"Trying to open: %@\n",lastFile);
                if(relaunched)NSLog(@"This is an auto-relaunch using [%@]\n",NSApplicationRelaunchDaemon);
                [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:lastFile]
                                                                                       display:YES
                                                                             completionHandler:^(NSDocument* document, BOOL documentWasAlreadyOpen, NSError*  anError){
                                                                                 if(anError!=nil) {
                                                                                         [self closeSplashWindow];
                                                                                         NSLogColor([NSColor redColor],@"Last File Opened By Orca Does Not Exist!\n");
                                                                                         NSLogColor([NSColor redColor],@"<%@>\n",lastFile);
                                                                                         ORRunAlertPanel(@"File Error",@"Last File Opened By Orca Does Not Exist!\n\n<%@>",nil,nil,nil,lastFile);

                                                                                     }
                                                                             }
                 
                 ];

			}
            [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"forceLoad"];
			if([[[NSUserDefaults standardUserDefaults] objectForKey: OROrcaSecurityEnabled] boolValue]){
				NSLog(@"Orca global security is enabled.\n");
			}
			else {
				NSLog(@"Orca global security is disabled.\n");
			}
		}
		configLoadedOK = YES;
	}
	@catch(NSException* localException) {
		NSLogColor([NSColor redColor],@"There was an exception thrown during load... configuration may not be complete!\n");
		if(fileOpenError)[NSApp presentError:fileOpenError];
		[self setDocument:nil];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartUpMessage"
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:@"Loading LogBook..." forKey:@"Message"]];
	[[ORStatusController sharedStatusController] loadCurrentLogBook];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORStartUpMessage"
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:@"Finishing..." forKey:@"Message"]];
    //make and register the heart beat monitor.
    [[ORCommandCenter sharedCommandCenter] addDestination:[ORHeartBeat sharedHeartBeat]];  
	
	//create an instance of the ORCARoot service and possibly connect    
    [[ORCARootService sharedORCARootService] connectAtStartUp];    
	
	[self performSelector:@selector(closeSplashWindow) withObject:self afterDelay:kORSplashScreenDelay];
	
	[[self undoManager] removeAllActions];

	NSUInteger     count  = [[ORGlobal sharedGlobal] cpuCount];
	if(count==1){
		[self closeSplashWindow];
		NSLogColor([NSColor redColor],@"Number of processors: %d\n",count);
		if([[NSUserDefaults standardUserDefaults] objectForKey:@"IgnoreSingleCPUWarning"] == nil){
			BOOL cancel = ORRunAlertPanel(@"Single CPU Warning",@"ORCA runs best on machines with multiple processors!",@"OK",@"OK/Don't remind me",nil,nil);
			if(!cancel){
				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"IgnoreSingleCPUWarning"];    
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
		}
	}
	else NSLog(@"Number of processors: %d\n",count);
	
	heartbeatCount = 0;
	[self doHeartBeat];
	
	if(getenv("NSZombieEnabled") || getenv("NSAutoreleaseFreedObjectCheckEnabled")) {
		NSLogColor([NSColor redColor],@"==============================================================================\n");
		NSLogColor([NSColor redColor],@"NSZombieEnabled/NSAutoreleaseFreedObjectCheckEnabled enabled!\n");
		NSLogColor([NSColor redColor],@"They are meant to be enabled for debugging only!\n");
		NSLogColor([NSColor redColor],@"ORCA will be slow, leak memory like crazy, and eventually bring the machine to its knees!\n");
		NSLogColor([NSColor redColor],@"==============================================================================\n");
	}
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:ORNormalShutDownFlag];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:debugging] forKey:ORWasInDebuggerFlag];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //NSLog(@"%@\n",1);

}

- (void) closeSplashWindow
{
	[theSplashController close];
	[theSplashController release];
	theSplashController = nil;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey: OROpeningDocPreferences] intValue];
}

#pragma mark ¥¥¥Menu Management
- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    BOOL documentIsOpen = [[NSApp orderedDocuments] count]>0;
    SEL theAction = [menuItem action];
    if(theAction == @selector(terminate:)){
        return [[ORGlobal sharedGlobal] canQuitDuringRun] || ![[ORGlobal sharedGlobal] runInProgress];
    }
    if(theAction == @selector(performClose:)){
        return [[ORGlobal sharedGlobal] canQuitDuringRun] || ![[ORGlobal sharedGlobal] runInProgress];
    }
    if(theAction == @selector(newDocument:)){
        return documentIsOpen ? NO : YES;
    }
    if(theAction == @selector(openDocument:)){
        return documentIsOpen ? NO : YES;
    }
    if(theAction == @selector(openRecentDocument:)){
        return documentIsOpen ? NO : YES;
    }
    if(theAction == @selector(showTemplates:)){
		if(![self document])return NO;
		else if([[[self document] group] count]==0 && ![[self document] isDocumentEdited])return YES;
        else return documentIsOpen ? NO : YES;
    }
	
    if(theAction == @selector(restoreToCmdOneSet:)){
		NSString* theSaveSetName = [[NSUserDefaults standardUserDefaults] objectForKey:@"CmdOneWindowSaveSet"]; 
		if(![theSaveSetName length])return NO;
		
		NSString* tempFolder = [[ApplicationSupport sharedApplicationSupport] applicationSupportFolder:@"WindowSets"];
		NSString* windowSetFile = [tempFolder stringByAppendingPathComponent:theSaveSetName];
		NSFileManager* fm = [NSFileManager defaultManager]; 
		if([fm fileExistsAtPath:windowSetFile])return YES;
		else return NO;
    }
	
	
    return YES;
}
- (NSUndoManager*) undoManager
{
    return [document undoManager];
}

- (void) mailCrashLogs
{
    if([[[NSUserDefaults standardUserDefaults] objectForKey: ORMailBugReportFlag] boolValue]){
        NSString* address = [[NSUserDefaults standardUserDefaults] objectForKey: ORMailBugReportEMail];
        if(address){
			NSString *filePath;
			NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: [kCrashLogDir stringByExpandingTildeInPath]];
			// iterate over all the log files
			while (filePath = [dirEnum nextObject]){
				if([filePath hasPrefix:@"Orca"]){
					NSString* contents = [NSString stringWithContentsOfFile:[[kCrashLogDir stringByExpandingTildeInPath] stringByAppendingPathComponent:filePath]encoding:NSASCIIStringEncoding error:nil];
					if(contents){
						NSAttributedString* crashLog = [[NSAttributedString alloc] initWithString:contents];
						//the address may be a list... if so it must be a comma separated list... try to make it so...
                        NSString* finalAddressList = [address stringByReplacingOccurrencesOfString:@"\n" withString:@","];
                        finalAddressList = [finalAddressList stringByReplacingOccurrencesOfString:@"\r" withString:@","];
                        finalAddressList = [finalAddressList stringByReplacingOccurrencesOfString:@" " withString:@","];
                        
                        while([finalAddressList rangeOfString:@",,"].location!=NSNotFound){
                            finalAddressList = [finalAddressList stringByReplacingOccurrencesOfString:@",," withString:@","];
                        }
                        if([finalAddressList hasPrefix:@","]) finalAddressList = [finalAddressList substringFromIndex:1];
                        if([finalAddressList hasSuffix:@","]) finalAddressList = [finalAddressList substringToIndex:[finalAddressList length]-1];
                                            
                        
                        ORMailer* mailer = [ORMailer mailer];
						[mailer setTo:finalAddressList];
						[mailer setSubject:[NSString stringWithFormat:@"ORCA Crash Log for: %@",computerName()]];
						[mailer setBody:crashLog];
						[mailer send:self];
						[crashLog release];
					}
				}
			}		
        }
		[self deleteCrashLogs];
    }
}

- (void) mailSent:(NSString*)address
{
	NSLog(@"The last ORCA crash log was sent to: %@\n",address);
}

- (void) deleteCrashLogs
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* lastCrashLogPath = [kLastCrashLog stringByExpandingTildeInPath]; 
	NSString *filePath;
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: [kCrashLogDir stringByExpandingTildeInPath]];
	// iterate over all the log files
	while (filePath = [dirEnum nextObject]){
		if([filePath hasPrefix:@"Orca"]){
			NSString* fullPath = [[kCrashLogDir stringByExpandingTildeInPath] stringByAppendingPathComponent:filePath];
			if([fm fileExistsAtPath:lastCrashLogPath]){
				[fm removeItemAtPath:lastCrashLogPath error:nil];
			}
			[fm copyItemAtPath:fullPath toPath:lastCrashLogPath error:nil];
			NSLog(@"Old crash report copied to: %@\n",lastCrashLogPath);
			[fm removeItemAtPath:fullPath error:nil];
		}
	}	
}

- (void) doHeartBeatAfterDelay
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doHeartBeat) object:nil];
	[self performSelector:@selector(doHeartBeat) withObject:nil afterDelay:kHeartbeatPeriod];
}

- (void) doHeartBeat
{
    BOOL enabled   = [[[NSUserDefaults standardUserDefaults] objectForKey:ORPrefHeartBeatEnabled] intValue]; 
    enabled       |= [[[NSUserDefaults standardUserDefaults] objectForKey:ORPrefPostLogEnabled] intValue]; 
	if(enabled){
		if(!queue){
			queue = [[NSOperationQueue alloc] init];
			[queue setMaxConcurrentOperationCount:1]; //can only do one at a time
			[queue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
		}
		ORHeartBeatOp* anOp = [[ORHeartBeatOp alloc] init:heartbeatCount];
		[queue addOperation:anOp];
		[anOp release];	
		heartbeatCount++;
	}
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == queue && [keyPath isEqual:@"operations"]) {
        if ([[queue operations] count] == 0) {
			[self performSelectorOnMainThread:@selector(doHeartBeatAfterDelay) withObject:nil waitUntilDone:NO];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object 
                               change:change context:context];
    }
}
@end


@implementation ORHeartBeatOp
- (id) init:(uint32_t)aCount
{
	self = [super init];
	heartbeatCount = aCount;
	return self;
}

- (void) main
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		if([[[NSUserDefaults standardUserDefaults] objectForKey:ORPrefHeartBeatEnabled] intValue]){
			NSString* finalPath = [[[NSUserDefaults standardUserDefaults] objectForKey:ORPrefHeartBeatPath] stringByAppendingPathComponent:@"Heartbeat"]; 
			uint32_t now = (uint32_t)[[NSDate date]timeIntervalSince1970];
			NSString* contents = [NSString stringWithFormat:@"Time:%u\nNext:%u",now,now+kHeartbeatPeriod];
			[contents writeToFile:finalPath atomically:YES encoding:NSASCIIStringEncoding error:nil];
        }

		if(heartbeatCount%(kLogSnapShotPeriod*60/kHeartbeatPeriod) == 0){
			if([[[NSUserDefaults standardUserDefaults] objectForKey:ORPrefPostLogEnabled] intValue]){
                [[ORStatusController sharedStatusController] performSelectorOnMainThread:@selector(doSnapShot) withObject:nil waitUntilDone:YES];
			}
		}
	}
	@catch(NSException* e){
	}
    [pool release];
}
@end


