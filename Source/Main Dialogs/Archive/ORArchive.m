//
//  ORArchive.m
//  Orca
//
//  Created by Mark Howe on Thu Nov 28 2002.
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


#pragma mark ¥¥¥Imported Files
#import "ORArchive.h"
#import "SynthesizeSingleton.h"
#import "ORTimedTextField.h"

#define kOldBinaryPath @"~/OldOrcaBinaries"
#define kFallBackDir @"FallBackConfigs"
#define kFallBackDirNew @"FallBacksModified"
#define kDefaultSrcPath @"~/Dev/Orca"

NSString*  ArchiveLock = @"ArchiveLock";

@implementation ORArchive

#pragma mark ¥¥¥Inialization

SYNTHESIZE_SINGLETON_FOR_ORCLASS(Archive);
-(id) init
{
    self = [super initWithWindowNibName:@"Archive"];
    if (self) {
        [self setWindowFrameAutosaveName:@"Archive"];
    }
    return self;
}

- (void) dealloc
{
	[queue removeObserver:self forKeyPath:@"operations"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[queue cancelAllOperations];
	[queue release];
	[super dealloc];
}

- (void) awakeFromNib 
{
    [self registerNotificationObservers];
	[self securityStateChanged:nil];
	[self lockChanged:nil];
	[fallBackMatrix selectCellWithTag:useFallBackConfig];
	
	if(!queue){
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:1]; //can only do one at a time
		[queue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
	}
}

- (NSString*) binPath
{
    return appPath();
}

- (BOOL) deploymentVersion
{
    NSString* binPath = appPath();
    if([binPath rangeOfString:@"Deployment" options:NSCaseInsensitiveSearch].location != NSNotFound){
        return YES;
    }
    else {
        return NO;
    }
}
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == queue && [keyPath isEqual:@"operations"]) {
        if ([[queue operations] count] == 0) {
			[self performSelectorOnMainThread:@selector(resetStatusTimer) withObject:nil waitUntilDone:NO];
        }
		[self performSelectorOnMainThread:@selector(lockChanged:) withObject:nil waitUntilDone:NO];

    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object 
                               change:change context:context];
    }
}
- (void) resetStatusTimer
{
	[operationStatusField setTimeOut:3];
	[operationStatusField setStringValue: [operationStatusField stringValue]];
}

- (NSOperationQueue*) queue
{
	return queue;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self];
    
	[notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ArchiveLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(securityStateChanged:)
                         name : ORGlobalSecurityStateChanged
                        object: nil];
	
	//we don't want this notification
	[notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window
{
    return [[(ORAppDelegate*)[NSApp delegate]document]  undoManager];
}

- (void) securityStateChanged:(NSNotification*)aNote
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ArchiveLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNote
{
    BOOL locked			= [gSecurity isLocked:ArchiveLock];
	BOOL runInProgress	= [gOrcaGlobals runInProgress];
	int busy			= [[queue operations]count]!=0;
	[lockButton setState: locked];
	[runStatusField setStringValue:runInProgress?@"Run In Progress":@""];
	[archiveOrcaButton setEnabled: !locked & !runInProgress & !busy];
	[unarchiveRestartButton setEnabled:!locked & !runInProgress & !busy];
	[updateButton setEnabled:!locked & !runInProgress & !busy];
	[fallBackMatrix setEnabled:!locked & !runInProgress & !busy];
}

- (IBAction) updateWithSvn:(id)sender
{
    
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Full Update and Restart"];
    [alert setInformativeText:@"Really do an Archive, SVN Update, Clean Build, and Restart?\n\nThis can take awhile."];
    [alert addButtonWithTitle:@"Yes/Do It"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [self doTheSvnUpdate];
        }
    }];
#else
    NSBeginAlertSheet(@"Full Update and Restart",
                      @"Cancel",
                      @"Yes/Do it",
                      nil,[self window],
                      self,
                      @selector(_toggleSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really do an Archive, SVN Update, Clean Build, and Restart?\n\nThis can take awhile.");
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _toggleSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
        [self doTheSvnUpdate];
    }
}
#endif
- (void) doTheSvnUpdate
{
	[operationStatusField setTimeOut:1000];

	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* dir = [kDefaultSrcPath stringByExpandingTildeInPath];
	if([fm fileExistsAtPath:dir]){
		[self deferedSvnUpdate:kDefaultSrcPath];
	}
	else {	
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setCanChooseFiles:NO];
		[openPanel setAllowsMultipleSelection:NO];
		[openPanel setPrompt:@"Choose ORCA Location"];

        [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton){
                [self performSelector:@selector(deferedSvnUpdate:) withObject:[[openPanel URL] path] afterDelay:0];
            }
        }];

	}
}

- (void) deferedSvnUpdate:(NSString *)anUpdatePath
{
	[[(ORAppDelegate*)[NSApp delegate] document] saveDocument:self];
	if([self checkOldBinariesFolder]){
		[self archiveCurrentBinary];
	}
	
	ORUpdateOrcaWithSvnOp* anOp = [[ORUpdateOrcaWithSvnOp alloc] initAtPath:anUpdatePath delegate:self];
	[queue addOperation:anOp];
	[anOp release];

    ORCleanOrcaOp* aCleanOp = [[ORCleanOrcaOp alloc] initAtPath:anUpdatePath delegate:self];
	[queue addOperation:aCleanOp];
	[aCleanOp release];

	ORBuildOrcaOp* aBuildOp = [[ORBuildOrcaOp alloc] initAtPath:anUpdatePath delegate:self];
	[queue addOperation:aBuildOp];
	[aBuildOp release];
    
    [self restart:launchPath()];
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ArchiveLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) saveDocument:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocument:sender];
}

- (IBAction) saveDocumentAs:(id)sender
{
    [[(ORAppDelegate*)[NSApp delegate]document] saveDocumentAs:sender];
}

- (IBAction) archiveThisOrca:(id)sender
{
	[operationStatusField setTimeOut:1000];
	if([self checkOldBinariesFolder]){
		[self archiveCurrentBinary];
	}
}

- (IBAction) fallBackAction:(id)sender
{
	useFallBackConfig = [[sender selectedCell] tag];
}

- (IBAction) startOldOrca:(id)sender
{
	[operationStatusField setTimeOut:1000];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Choose"];
	
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:[kOldBinaryPath stringByExpandingTildeInPath]]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [self performSelector:@selector(deferedStartOldOrca:) withObject:[[openPanel URL] path] afterDelay:0];
        }
    }];

}

- (void) updateStatus:(NSString*)aString
{
	[operationStatusField performSelectorOnMainThread:@selector(setStringValue:) withObject:aString waitUntilDone:YES];
}

- (void) deferedStartOldOrca:(NSString*)anOldOrcaPath
{
	[[(ORAppDelegate*)[NSApp delegate] document] saveDocument:self];
	if([self checkOldBinariesFolder]){
		[self archiveCurrentBinary];
		[self unArchiveBinary:anOldOrcaPath];
		NSString* configFile = nil;
		if(useFallBackConfig){
			NSString* lastPart = [anOldOrcaPath lastPathComponent];
			NSString* firstPart = [anOldOrcaPath stringByDeletingLastPathComponent];
			if([lastPart hasPrefix:@"Orca"]){
				NSString* s = [lastPart stringByReplacingCharactersInRange:NSMakeRange(0,4) withString:@"Config"];
				s = [kFallBackDir stringByAppendingPathComponent:s];
				configFile = [firstPart stringByAppendingPathComponent:s];
				configFile = [configFile stringByDeletingPathExtension];
				configFile = [configFile stringByAppendingPathExtension:@"Orca"];
				NSFileManager* fm = [NSFileManager defaultManager];
				if(![fm fileExistsAtPath:configFile]){
					configFile = nil;
				}
			}
		}
		[self restart:launchPath() config:configFile];
	}		
}


- (BOOL) checkOldBinariesFolder
{
	NSError* error;
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* dir = [kOldBinaryPath stringByExpandingTildeInPath];
	if(![fm fileExistsAtPath:dir]){
		if(![fm createDirectoryAtPath:dir withIntermediateDirectories:NO attributes:nil error:&error]){
			NSLogColor([NSColor redColor],@"Unable to access/create %@\n",dir);
			NSLogColor([NSColor redColor],@"%@\n",error);
			return NO;
		}		
	}
	NSString* fallBackDir = [dir stringByAppendingPathComponent:kFallBackDir];
	if(![fm fileExistsAtPath:fallBackDir]){
		if(![fm createDirectoryAtPath:fallBackDir withIntermediateDirectories:NO attributes:nil error:&error]){
			NSLogColor([NSColor redColor],@"Unable to access/create %@\n",fallBackDir);
			NSLogColor([NSColor redColor],@"%@\n",error);
			return NO;
		}
	}	
	NSString* fallBackDirNew = [dir stringByAppendingPathComponent:kFallBackDirNew];
	if(![fm fileExistsAtPath:fallBackDirNew]){
		if(![fm createDirectoryAtPath:fallBackDirNew withIntermediateDirectories:NO attributes:nil error:&error]){
			NSLogColor([NSColor redColor],@"Unable to access/create %@\n",fallBackDirNew);
			NSLogColor([NSColor redColor],@"%@\n",error);
			return NO;
		}
	}	
	return YES;
}

- (void) archiveCurrentBinary
{
	ORArchiveOrcaOp* anOp1 = [[ORArchiveOrcaOp alloc] initWithDelegate:self];
	[queue addOperation:anOp1];
	[anOp1 release];
	
	ORArchiveConfigurationOp* anOp2 = [[ORArchiveConfigurationOp alloc] initWithDelegate:self];
	[queue addOperation:anOp2];
	[anOp2 release];
}

- (void) unArchiveBinary:(NSString*)fileToUnarchive
{
	ORUnarchiveOrcaOp* anOp = [[ORUnarchiveOrcaOp alloc] initWithFile:fileToUnarchive delegate:self];
	[queue addOperation:anOp];
	[anOp release];
}

- (void) restart:(NSString*)binPath config:(NSString*)aConfigPath
{
	ORRestartOrcaOp* anOp = [[ORRestartOrcaOp alloc] initWithPath:binPath config:aConfigPath delegate:self];
	[queue addOperation:anOp];
	[anOp release];
}

- (void) restart:(NSString*)binPath
{
	[self restart:binPath config:nil];
}


@end

@implementation ORArchiveOrcaOp
- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
    return self;
}

- (void) main
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		NSString* binPath = appPath();
		NSString* dir = [kOldBinaryPath stringByExpandingTildeInPath];
		if(binPath){
            NSLog(@"Archiving:%@\n",binPath);

			NSString* archivePath = [dir stringByAppendingPathComponent:[@"Orca" stringByAppendingFormat:@"%@.tar",fullVersion()]];
			
			//check if already archived. if so, then skip this
			NSFileManager* fm = [NSFileManager defaultManager];
			if(![fm fileExistsAtPath:archivePath]){
				NSTask* task = [[NSTask alloc] init];
				[task setCurrentDirectoryPath:[binPath stringByDeletingLastPathComponent]];
				[task setLaunchPath: @"/usr/bin/tar"];
				NSArray* arguments = [NSArray arrayWithObjects: @"czf", 
									  archivePath, 
									  [[binPath lastPathComponent] stringByAppendingPathExtension:@"app"],
									  nil];
				
				[task setArguments: arguments];
				
				NSPipe* pipe = [NSPipe pipe];
				[task setStandardOutput: pipe];
				
				NSFileHandle* file = [pipe fileHandleForReading];
				[delegate updateStatus:@"Archiving this ORCA"];
				[task launch];

				NSData* data = [file readDataToEndOfFile];
				if(data){
					NSString* result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
					if([result length]) NSLog(@"tar returned:\n%@\n", result);
				}
				[delegate updateStatus:@"Archiving Done"];
				NSLog(@"Archived ORCA to: %@\n",archivePath);
				[task release];
                [file closeFile];
			}
			else {
				[delegate updateStatus:[NSString stringWithFormat:@"Archive exists: %@\n",[archivePath lastPathComponent]]];
			}
		}
	}
	@catch(NSException* e){
	}
    [pool release];
}
@end

@implementation ORArchiveConfigurationOp
- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
    return self;
}

- (void) main
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	if(![(ORAppDelegate*)[NSApp delegate] configLoadedOK]){
		NSLog(@"You currently do not have a valid config. It was NOT archived.\n");
        [pool release];
		return;
	}
	@try {	
		NSError* error;
		NSString* dir		  = [[kOldBinaryPath stringByAppendingPathComponent:kFallBackDir] stringByExpandingTildeInPath];
		NSString* archivePath = [[dir stringByAppendingPathComponent:[@"Config" stringByAppendingString:fullVersion()]]stringByAppendingPathExtension:@"Orca"];;
		NSFileManager* fm	  = [NSFileManager defaultManager];
		if([fm fileExistsAtPath:archivePath]){
			if(![fm removeItemAtPath:archivePath error:&error]){
				NSLogColor([NSColor redColor], @"Problem deleting %@\n",archivePath);
				NSLogColor([NSColor redColor], @"%@\n",error);
			}
		}
		NSString* currentConfigPath = [[[(ORAppDelegate*)[NSApp delegate] document] fileURL] path];
		if([fm copyItemAtPath:currentConfigPath toPath:archivePath error:&error]){
			NSLog(@"Copied %@ to %@\n", currentConfigPath,archivePath);
		}
		else {
			NSLogColor([NSColor redColor], @"Problem copying %@ to %@\n", currentConfigPath,archivePath);
			NSLogColor([NSColor redColor], @"%@\n",error);
		}
	}
	@catch(NSException* e){
	}
    [pool release];
}
@end


@implementation ORUnarchiveOrcaOp
- (id) initWithFile:(NSString*)aFile delegate:(id)aDelegate
{
	self = [super init];
	fileToUnarchive = [aFile copy];
	delegate = aDelegate;
    return self;
}
- (void) dealloc
{
	[fileToUnarchive release];
	[super dealloc];
}

- (void) main
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		NSTask* task = [[NSTask alloc] init];
		NSString* binPath = appPath();
		[task setCurrentDirectoryPath:[[binPath stringByExpandingTildeInPath] stringByDeletingLastPathComponent]];
		[task setLaunchPath: @"/usr/bin/tar"];
		NSArray* arguments = [NSArray arrayWithObjects: @"xzf", 
							  [fileToUnarchive stringByExpandingTildeInPath],
							  nil];
		
		[task setArguments: arguments];
		
		NSPipe* pipe = [NSPipe pipe];
		[task setStandardOutput: pipe];
		
		NSFileHandle* file = [pipe fileHandleForReading];
		
		[delegate updateStatus:[NSString stringWithFormat:@"Unarchiving: %@",[fileToUnarchive stringByAbbreviatingWithTildeInPath]]];
		[task launch];
		
		NSData* data = [file readDataToEndOfFile];
		if(data){
			NSString* result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
			if([result length]) NSLog(@"tar returned:\n%@", result);
		}
		[delegate updateStatus:@"Archiving Done"];
		[task release];
        [file closeFile];

	}
	@catch(NSException* e){
	}
    [pool release];
}
@end

@implementation ORRestartOrcaOp
- (id) initWithPath:(NSString*)aPath config:(NSString*)aConfig delegate:(id)aDelegate
{
	self = [super init];
	binPath		= [aPath copy];
	configFile	= [aConfig copy];
	delegate	= aDelegate;
    return self;
}
- (void) dealloc
{
	[binPath release];
	[super dealloc];
}
- (void) main
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		[[ORGlobal sharedGlobal] prepareForForcedHalt];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:ORNormalShutDownFlag];    
		[[NSUserDefaults standardUserDefaults] synchronize];

		NSString* newLocation = nil;
		if(configFile){
			newLocation = [configFile stringByReplacingOccurrencesOfString:kFallBackDir withString:kFallBackDirNew];
			NSFileManager* fm = [NSFileManager defaultManager];
			if([fm fileExistsAtPath:newLocation])[fm removeItemAtPath:newLocation error:nil];
			if(![fm copyItemAtPath:configFile toPath:newLocation error:nil]){
				newLocation = nil;
			}
		}
        //euthanize self and restart. Use main thread
        [(ORAppDelegate*)[NSApp delegate] restart:self withConfig:configFile];
	}
	@catch(NSException* e){
	}
    [pool release];
}

@end

@interface NSObject (ORUpdateCenter)
- (void) updateStatus:(NSString*)aString;
@end

@implementation ORUpdateOrcaWithSvnOp
- (id) initAtPath:(NSString*)aPath delegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
	srcPath = [[aPath stringByDeletingLastPathComponent] copy];
    return self;
}

- (void) dealloc
{
	[srcPath release];
	[super dealloc];
}

- (void) main
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		if(srcPath){
			NSTask* task = [[NSTask alloc] init];
			[task setCurrentDirectoryPath:[srcPath stringByExpandingTildeInPath]];
			[task setLaunchPath: @"/usr/bin/svn"];
			NSArray* arguments = [NSArray arrayWithObjects: @"update", 
								  @"Orca",
								  nil];
			
			[task setArguments: arguments];
			
			NSPipe* pipe = [NSPipe pipe];
			[task setStandardOutput: pipe];
			
			NSFileHandle* file = [pipe fileHandleForReading];
			[delegate updateStatus:[NSString stringWithFormat:@"Updating Src Tree %@",srcPath]];
			[task launch];
			
			NSData* data = [file readDataToEndOfFile];
			if(data){
				NSString* result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
				if([result length]) NSLog(@"svn returned:\n%@", result);
			}
			[delegate updateStatus:@"Update Finished"];
			[task release];
            [file closeFile];

		}
	}
	@catch(NSException* e){
	}
    [pool release];
}
@end
@implementation ORCleanOrcaOp
- (id) initAtPath:(NSString*)aPath delegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
	srcPath = [[aPath stringByDeletingLastPathComponent] copy];
    return self;
}

- (void) dealloc
{
	[srcPath release];
	[super dealloc];
}

- (void) main
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		if(srcPath){
			NSTask* task = [[NSTask alloc] init];
			NSString* thePath = [[srcPath stringByExpandingTildeInPath] stringByAppendingPathComponent:@"Orca"];
			[task setCurrentDirectoryPath:thePath];
            NSString* buildType;
            if([delegate deploymentVersion]){
                NSLog(@"Cleaning Deployment target\n");
                buildType = @"Deployment";
            }
            else {
                NSLog(@"Cleaning Development target\n");
                buildType = @"Development";
            }

			[task setLaunchPath: @"/usr/bin/xcodebuild"];
			NSArray* arguments = [NSArray arrayWithObjects: @"-configuration",buildType,@"clean",
								  nil];
			
			[task setArguments: arguments];
			
			NSPipe* pipe = [NSPipe pipe];
			[task setStandardOutput: pipe];
			
			NSFileHandle* file = [pipe fileHandleForReading];
			[delegate updateStatus:[NSString stringWithFormat:@"Cleaning: %@",thePath]];
			[task launch];
			
			NSData* data = [file readDataToEndOfFile];
			if(data){
				NSString* result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
				NSRange r = [result rangeOfString:@"**"];
				if(r.location != NSNotFound){
					result = [result substringFromIndex:r.location];
					[delegate updateStatus:@"Clean Finished"];
				}
				else {
					NSRange r = [result rangeOfString:@"error:"];
					if(r.location != NSNotFound){
						result = @"Clean Failed";
						NSLogColor([NSColor redColor],@"Errors detected during build. You will have to do a manual build.\n");
						[delegate updateStatus:@"Clean Failed"];
						[[delegate queue] cancelAllOperations];
					}
					else [delegate updateStatus:@"Clean Finished"];
				}
                
				if([result length]) NSLog(@"Operation returned:\n%@", result);
			}
			[task release];
            [file closeFile];

		}
	}
	@catch(NSException* e){
	}
    @finally{
        [pool release];
    }
}
@end

@implementation ORBuildOrcaOp
- (id) initAtPath:(NSString*)aPath delegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
	srcPath = [[aPath stringByDeletingLastPathComponent] copy];
    return self;
}

- (void) dealloc
{
	[srcPath release];
	[super dealloc];
}

- (void) main
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		if(srcPath){
            NSString* currentAppPath = [appPath() stringByDeletingLastPathComponent];
			NSTask* task = [[NSTask alloc] init];
			NSString* thePath = [[srcPath stringByExpandingTildeInPath] stringByAppendingPathComponent:@"Orca"]; 
			[task setCurrentDirectoryPath:thePath];
			[task setLaunchPath: @"/usr/bin/xcodebuild"];
            NSString* buildType;
            if([delegate deploymentVersion]){
                NSLog(@"Building Deployment target\n");
                buildType = @"Deployment";
            }
            else {
                NSLog(@"Building Development target\n");
                buildType = @"Development";
            }
            NSString* theBuildPath = [NSString stringWithFormat:@"%@/build/%@",thePath,buildType];
            NSString* buildDir = [NSString stringWithFormat:@"CONFIGURATION_BUILD_DIR=%@/",theBuildPath];
			NSArray* arguments = [NSArray arrayWithObjects: @"-configuration",
								  buildType,
                                  buildDir,
								  nil];
			
			[task setArguments: arguments];
 			
			NSPipe* pipe = [NSPipe pipe];
			[task setStandardOutput: pipe];
			
			NSFileHandle* file = [pipe fileHandleForReading];
			[delegate updateStatus:[NSString stringWithFormat:@"Building: %@",thePath]];
			[task launch];
			
			NSData* data = [file readDataToEndOfFile];
			if(data){
				NSString* result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
				NSRange r = [result rangeOfString:@"**"];
				if(r.location != NSNotFound){
					result = [result substringFromIndex:r.location];
					[delegate updateStatus:@"Build Finished"];
                    if(![currentAppPath isEqualToString:theBuildPath]){
                        NSError* theError;
                        [[NSFileManager defaultManager] removeItemAtPath:[currentAppPath stringByDeletingLastPathComponent] error:&theError];
                        if(theError){
                            NSLog(@"Unable to remove Old Binary\n");
                        }
                     }
				}
				else {
					NSRange r = [result rangeOfString:@"error:"];
					if(r.location != NSNotFound){
						result = @"Build Failed";
						NSLogColor([NSColor redColor],@"Errors detected during build. You will have to do a manual build.\n");
						[delegate updateStatus:@"Build Failed"];
						[[delegate queue] cancelAllOperations];
					}	
					else {
                        [delegate updateStatus:@"Build Finished"];
                        if(![currentAppPath isEqualToString:theBuildPath]){
                            NSError* theError;
                            [[NSFileManager defaultManager] removeItemAtPath:[currentAppPath stringByDeletingLastPathComponent] error:&theError];
                            if(theError){
                                NSLog(@"Unable to remove Old Binary\n");
                            }

                        }
                   }
				}

				if([result length]) NSLog(@"build returned:\n%@", result);
			}
			[task release];
            [file closeFile];

		}
	}
	@catch(NSException* e){
	}
    @finally{
        [pool release];
    }
}
@end




