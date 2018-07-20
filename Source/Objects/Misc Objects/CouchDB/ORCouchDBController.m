//
//  ORCouchDBController.m
//  Orca
//
//  Created by Mark Howe on 10/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORCouchDBController.h"
#import "ORCouchDBModel.h"
#import "ORCouchDB.h"
#import "ORValueBarGroupView.h"

@interface ORCouchDBController (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) createActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) deleteActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) stealthActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) historyActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
@end

@implementation ORCouchDBController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"CouchDB"];
    return self;
}

- (void) dealloc
{
    [[[ORCouchDBQueue sharedCouchDBQueue] queue]            removeObserver:self forKeyPath:@"operationCount"];
    [[[ORCouchDBQueue sharedCouchDBQueue] lowPriorityQueue] removeObserver:self forKeyPath:@"operationCount"];
	[super dealloc];
}

-(void) awakeFromNib
{
	[super awakeFromNib];
    [[[ORCouchDBQueue sharedCouchDBQueue]queue]            addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    [[[ORCouchDBQueue sharedCouchDBQueue]lowPriorityQueue] addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    [queueValueBars setNumber:2 height:10 spacing:5];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
	NSOperationQueue* queue = [[ORCouchDBQueue sharedCouchDBQueue] queue];
    NSOperationQueue* lowPriorityQueue = [[ORCouchDBQueue sharedCouchDBQueue] lowPriorityQueue];
    if (object == queue && [keyPath isEqual:@"operationCount"]) {
		NSNumber* n = [NSNumber numberWithInteger:[[[ORCouchDBQueue queue] operations] count]];
		[self performSelectorOnMainThread:@selector(setQueCount:) withObject:n waitUntilDone:NO];
    }
    else if (object == lowPriorityQueue && [keyPath isEqual:@"operationCount"]) {
        NSNumber* n = [NSNumber numberWithInteger:[[[ORCouchDBQueue lowPriorityQueue] operations] count]];
        [self performSelectorOnMainThread:@selector(setLowPriorityQueCount:) withObject:n waitUntilDone:NO];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) setQueCount:(NSNumber*)n
{
    [[queueCountsMatrix cellAtRow:0 column:0] setIntValue:[n intValue]];
	[queueValueBars setNeedsDisplay:YES];
}

- (void) setLowPriorityQueCount:(NSNumber*)n
{
    [[queueCountsMatrix cellAtRow:1 column:0] setIntValue:[n intValue]];
    [queueValueBars setNeedsDisplay:YES];
}

#pragma mark •••Registration
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(remoteHostNameChanged:)
                         name : ORCouchDBRemoteHostNameChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(localHostNameChanged:)
                         name : ORCouchDBLocalHostNameChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(userNameChanged:)
                         name : ORCouchDBUserNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(passwordChanged:)
                         name : ORCouchDBPasswordChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(portChanged:)
                         name : ORCouchDBPortNumberChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(couchDBLockChanged:)
                         name : ORCouchDBLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(couchDBLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(stealthModeChanged:)
                         name : ORCouchDBModelStealthModeChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(useHttpsChanged:)
                         name : ORCouchDBModeUseHttpsChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataBaseInfoChanged:)
                         name : ORCouchDBModelDBInfoChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(keepHistoryChanged:)
                         name : ORCouchDBModelKeepHistoryChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(replicationRunningChanged:)
                         name : ORCouchDBModelReplicationRunningChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(usingUpdateHandlerChanged:)
                         name : ORCouchDBModelUsingUpdateHandleChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(alertMessageChanged:)
                         name : ORCouchDBModelAlertMessageChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(alertTypeChanged:)
                         name : ORCouchDBModelAlertTypeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(skipDataSetsChanged:)
                         name : ORCouchDBModelSkipDataSetsChanged
                        object: model];

}

- (void) updateWindow
{
    [super updateWindow];
    [self alertMessageChanged:nil];
    [self alertTypeChanged:nil];
    [self remoteHostNameChanged:nil];
	[self localHostNameChanged:nil];
	[self userNameChanged:nil];
	[self passwordChanged:nil];
	[self portChanged:nil];
	[self dataBaseNameChanged:nil];
    [self couchDBLockChanged:nil];
	[self stealthModeChanged:nil];
    [self useHttpsChanged:nil];
	[self keepHistoryChanged:nil];
	[self replicationRunningChanged:nil];
    [self usingUpdateHandlerChanged:nil];
    [self skipDataSetsChanged:nil];
}

- (void) skipDataSetsChanged:(NSNotification*)aNote
{
    [skipDataSetsCB setIntValue:[model skipDataSets]];
}


- (void) alertMessageChanged:(NSNotification*)aNote
{
    [alertMessageField setStringValue:[model alertMessage]];
}

- (void) alertTypeChanged:(NSNotification*)aNote
{
    [alertTypePU selectItemAtIndex:[model alertType]];
}

- (void) usingUpdateHandlerChanged:(NSNotification*)aNote
{
	[usingUpdateHandlerField setStringValue: [model usingUpdateHandler]?@"Using Update Handler":@""];
}


- (void) replicationRunningChanged:(NSNotification*)aNote
{
	[replicationRunningTextField setStringValue: [model replicationRunning]?@"Replicating":@"NOT Replicating"];
}

- (void) keepHistoryChanged:(NSNotification*)aNote
{
	[keepHistoryCB setIntValue: [model keepHistory]];
	[keepHistoryStatusField setStringValue:([model keepHistory] & ![model stealthMode])?@"":@"Disabled"];
}

- (void) useHttpsChanged:(NSNotification*)aNote
{
    [useHttpsCB setIntValue: [model useHttps]];
}

- (void) stealthModeChanged:(NSNotification*)aNote
{
	[stealthModeButton setIntValue: [model stealthMode]];
	[dbStatusField setStringValue:![model stealthMode]?@"":@"Disabled"];
	[keepHistoryStatusField setStringValue:([model keepHistory] & ![model stealthMode])?@"":@"Disabled"];
}

- (void) remoteHostNameChanged:(NSNotification*)aNote
{
	if([model remoteHostName])[remoteHostNameField setStringValue:[model remoteHostName]];
}

- (void) localHostNameChanged:(NSNotification*)aNote
{
	if([model localHostName])[localHostNameField   setStringValue:[model localHostName]];
}

- (void) userNameChanged:(NSNotification*)aNote
{
	if([model userName])[userNameField setStringValue:[model userName]];
}

- (void) passwordChanged:(NSNotification*)aNote
{
	if([model password])[passwordField setStringValue:[model password]];
}

- (void) portChanged:(NSNotification*)aNote
{
    [portField setIntegerValue:[model portNumber]];
}

- (void) dataBaseNameChanged:(NSNotification*)aNote
{
	[dataBaseNameField setStringValue:[model databaseName]];
	[historyDataBaseNameField setStringValue:[model historyDatabaseName]];
}

- (void) couchDBLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORCouchDBLock];
    [couchDBLockButton   setState: locked];
    
    [remoteHostNameField setEnabled:!locked];
    [localHostNameField  setEnabled:!locked];
    [userNameField       setEnabled:!locked];
    [passwordField       setEnabled:!locked];
    [portField           setEnabled:!locked];
    [keepHistoryCB       setEnabled:!locked];
    [stealthModeButton   setEnabled:!locked];
    [skipDataSetsCB      setEnabled:!locked];
    [useHttpsCB          setEnabled:!locked];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORCouchDBLock to:secure];
    [couchDBLockButton setEnabled: secure];
}

- (void) dataBaseInfoChanged:(NSNotification*)aNote
{
	NSDictionary* dbInfo = [model dBInfo];
	uint32_t dbSize = (uint32_t)[[dbInfo objectForKey:@"disk_size"] unsignedLongValue];
	if(dbSize > 1000000000)[dbSizeField setStringValue:[NSString stringWithFormat:@"%.2f GB",dbSize/1000000000.]];
	else if(dbSize > 1000000)[dbSizeField setStringValue:[NSString stringWithFormat:@"%.2f MB",dbSize/1000000.]];
	else if(dbSize > 1000)[dbSizeField setStringValue:[NSString stringWithFormat:@"%.1f KB",dbSize/1000.]];
	else [dbSizeField setStringValue:[NSString stringWithFormat:@"%u Bytes",dbSize]];

	dbInfo = [model dBHistoryInfo];
	dbSize = (uint32_t)[[dbInfo objectForKey:@"disk_size"] unsignedLongValue];
	if(dbSize > 1000000000)[dbHistorySizeField setStringValue:[NSString stringWithFormat:@"%.2f GB",dbSize/1000000000.]];
	else if(dbSize > 1000000)[dbHistorySizeField setStringValue:[NSString stringWithFormat:@"%.2f MB",dbSize/1000000.]];
	else if(dbSize > 1000)[dbHistorySizeField setStringValue:[NSString stringWithFormat:@"%.1f KB",dbSize/1000.]];
	else [dbHistorySizeField setStringValue:[NSString stringWithFormat:@"%u Bytes",dbSize]];
	
}

#pragma mark •••Actions
- (IBAction) skipDataSetsAction:(id)sender
{
    [model setSkipDataSets:[sender intValue]];
}

- (IBAction) startReplicationAction:(id)sender
{
    [model createRemoteDataBases];
	[model startReplication];
}
- (IBAction) createRemoteDBAction:(id)sender
{
	[model createRemoteDataBases];
}

- (IBAction) keepHistoryAction:(id)sender
{
    if([model keepHistory]){
        NSString* s = [NSString stringWithFormat:@"Really DOs NOT keep a history: %@?\n",[model databaseName]];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:s];
        [alert setInformativeText:@"There will be NO history (only run status) kept if you deactivate this option."];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Yes, Disable History"];
        [alert setAlertStyle:NSAlertStyleWarning];
        
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
            if(result == NSAlertSecondButtonReturn){
                [model setKeepHistory:NO];
            }
            else [model setKeepHistory:YES];
        }];
#else
        NSBeginAlertSheet(s,
                          @"Cancel",
                          @"Yes, Disable History",
                          nil,[self window],
                          self,
                          @selector(historyActionDidEnd:returnCode:contextInfo:),
                          nil,
                          nil,@"There will be NO history (only run status) kept if you deactivate this option.");
#endif
    }
    else [model setKeepHistory:YES];

}

- (IBAction) useHttpsAction:(id)sender
{
    [model setUseHttps:[sender intValue]];
}

- (IBAction) stealthModeAction:(id)sender
{
    if(![model stealthMode]){
        NSString* s = [NSString stringWithFormat:@"Really disable the database: %@?\n",[model databaseName]];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:s];
        [alert setInformativeText:@"There will be NO values automatically put in to the database if you activate this option."];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Yes, Disable Database"];
        [alert setAlertStyle:NSAlertStyleWarning];
        
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
            if(result == NSAlertSecondButtonReturn){
                [model setStealthMode:YES];
            }
            else [model setStealthMode:NO];

        }];
#else
        NSBeginAlertSheet(s,
                          @"Cancel",
                          @"Yes, Disable Database",
                          nil,[self window],
                          self,
                          @selector(stealthActionDidEnd:returnCode:contextInfo:),
                          nil,
                          nil,@"There will be NO values automatically put in to the database if you activate this option.");
#endif
    }
    else [model setStealthMode:NO];
}

- (IBAction) couchDBLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORCouchDBLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) remoteHostNameAction:(id)sender
{
	[model setRemoteHostName:[sender stringValue]];
}

- (IBAction) localHostNameAction:(id)sender
{
	[model setLocalHostName:[sender stringValue]];
}

- (IBAction) userNameAction:(id)sender
{
	[model setUserName:[sender stringValue]];
}

- (IBAction) passwordAction:(id)sender
{
	[model setPassword:[sender stringValue]];
}

- (IBAction) portAction:(id)sender
{
	[model setPortNumber:[sender integerValue]];
}

- (IBAction) createAction:(id)sender
{
	[self endEditing];
	NSString* s = [NSString stringWithFormat:@"Really try to create a database named %@?\n",[model databaseName]];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s];
    [alert setInformativeText:@"If the database already exists, this operation will do no harm."];
    [alert addButtonWithTitle:@"Yes, Create Database"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model createDatabases];
        }
    }];
#else
    NSBeginAlertSheet(s,
                      @"Cancel",
                      @"Yes, Create Database",
                      nil,[self window],
                      self,
                      @selector(createActionDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"If the database already exists, this operation will do no harm.");
#endif
	
}
- (IBAction) deleteAction:(id)sender
{
	[self endEditing];
	NSString* s = [NSString stringWithFormat:@"Really delete a database named %@?\n",[model databaseName]];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s];
    [alert setInformativeText:@"If the database doesn't exist, this operation will do no harm."];
    [alert addButtonWithTitle:@"Yes, Delete Database"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model deleteDatabases];
        }
    }];
#else
    NSBeginAlertSheet(s,
                      @"Cancel",
                      @"Yes, Delete Database",
                      nil,[self window],
                      self,
                      @selector(deleteActionDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"If the database doesn't exist, this operation will do no harm.");
#endif
	
}

- (IBAction) listAction:(id)sender
{
	[model listDatabases];
}

- (IBAction) listTasks:(id)sender
{
	[model getRemoteInfo:YES];
}

- (IBAction) infoAction:(id)sender
{
	[model databaseInfo:YES];
}

- (IBAction) compactAction:(id)sender
{
	[model compactDatabase];
}


- (IBAction) alertTypeAction:(id)sender
{
    [model setAlertType:(int)[sender indexOfSelectedItem]];
}

- (IBAction) alertMessageAction:(id)sender
{
    [model setAlertMessage:[sender stringValue]];
}

- (IBAction) postAlertAction:(id)sender
{
    [self endEditing];
    [model postAlert];
}

- (IBAction) clearAlertAction:(id)sender
{
    [self endEditing];
    [model clearAlert];
}
@end

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
@implementation ORCouchDBController (private)
- (void) createActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertAlternateReturn){		
		[model createDatabases];
	}
}

- (void) deleteActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertAlternateReturn){		
		[model deleteDatabases];
	}
}

- (void) stealthActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertAlternateReturn){
		[model setStealthMode:YES];
	}
    else [model setStealthMode:NO];
}
- (void) historyActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	if(returnCode == NSAlertAlternateReturn){
		[model setKeepHistory:NO];
	}
    else [model setKeepHistory:YES];
    
}

@end
#endif

