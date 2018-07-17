//
//  ORSqlController.m
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


#import "ORSqlController.h"
#import "ORSqlModel.h"
#import "ORSqlConnection.h"
#import "ORValueBarGroupView.h"

@implementation ORSqlController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Sql"];
    return self;
}

- (void) dealloc
{
    [[[ORSqlDBQueue sharedSqlDBQueue] queue] removeObserver:self forKeyPath:@"operationCount"];
    [super dealloc];
}

-(void) awakeFromNib
{
	[super awakeFromNib];
	[[[ORSqlDBQueue sharedSqlDBQueue]queue] addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
}


#pragma mark ¥¥¥Registration
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(hostNameChanged:)
                         name : ORSqlHostNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(userNameChanged:)
                         name : ORSqlUserNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(passwordChanged:)
                         name : ORSqlPasswordChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataBaseNameChanged:)
                         name : ORSqlDataBaseNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(sqlLockChanged:)
                         name : ORSqlLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(sqlLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(connectionValidChanged:)
                         name : ORSqlConnectionValidChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(stealthModeChanged:)
                         name : ORSqlModelStealthModeChanged
						object: model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self hostNameChanged:nil];
	[self userNameChanged:nil];
	[self passwordChanged:nil];
	[self dataBaseNameChanged:nil];
	[self connectionValidChanged:nil];
    [self sqlLockChanged:nil];
	[self stealthModeChanged:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
	NSOperationQueue* queue = [[ORSqlDBQueue sharedSqlDBQueue] queue];
    if (object == queue && [keyPath isEqual:@"operationCount"]) {
		NSNumber* n = [NSNumber numberWithInteger:[[[ORSqlDBQueue queue] operations] count]];
		[self performSelectorOnMainThread:@selector(setQueCount:) withObject:n waitUntilDone:NO];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) setQueCount:(NSNumber*)n
{
	queueCount = [n intValue];
	[queueValueBar setNeedsDisplay:YES];
}

- (double) doubleValue
{
	return queueCount;
}

- (void) stealthModeChanged:(NSNotification*)aNote
{
	[stealthModeButton setIntValue: [model stealthMode]];
	[self updateConnectionValidField];
}

- (void) connectionValidChanged:(NSNotification*)aNote
{
	[self updateConnectionValidField];
}

- (void) updateConnectionValidField
{
	[connectionValidField setStringValue:[model stealthMode]?@"Disabled":[model connectioned]?@"Connected":@"NOT Connected"];
}

- (void) hostNameChanged:(NSNotification*)aNote
{
	if([model hostName])[hostNameField setStringValue:[model hostName]];
}

- (void) userNameChanged:(NSNotification*)aNote
{
	if([model userName])[userNameField setStringValue:[model userName]];
}

- (void) passwordChanged:(NSNotification*)aNote
{
	if([model password])[passwordField setStringValue:[model password]];
}

- (void) dataBaseNameChanged:(NSNotification*)aNote
{
	if([model dataBaseName])[dataBaseNameField setStringValue:[model dataBaseName]];
}
- 
(void) sqlLockChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORSqlLock];
    [sqlLockButton setState: locked];
    
    [hostNameField setEnabled:!locked];
    [userNameField setEnabled:!locked];
    [passwordField setEnabled:!locked];
    [dataBaseNameField setEnabled:!locked];
    [connectionButton setEnabled:!locked];
    
}
- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORSqlLock to:secure];
    [sqlLockButton setEnabled: secure];
}

#pragma mark ¥¥¥Actions
- (IBAction) stealthModeAction:(id)sender
{
	[model setStealthMode:[sender intValue]];	
	[dropAllTablesButton setEnabled:[sender intValue]];
}

- (IBAction) sqlLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORSqlLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) hostNameAction:(id)sender
{
	[model setHostName:[sender stringValue]];
}

- (IBAction) userNameAction:(id)sender
{
	[model setUserName:[sender stringValue]];
}

- (IBAction) passwordAction:(id)sender
{
	[model setPassword:[sender stringValue]];
}

- (IBAction) databaseNameAction:(id)sender
{
	[model setDataBaseName:[sender stringValue]];
}

- (IBAction) connectionAction:(id)sender
{
	[self endEditing];
	[model testConnection];
}

- (IBAction) removeEntryAction:(id)sender
{
	[model removeEntry];
}

- (IBAction) createAction:(id)sender
{
	[self endEditing];
	NSString* s = [NSString stringWithFormat:@"Really try to create a database named %@ on %@?\n",[model dataBaseName],[model hostName]];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s];
    [alert setInformativeText:@"If the database and tables already exist, this operation will do no harm."];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Yes, Create Database"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertSecondButtonReturn){
            [model createDatabase];
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
                      nil,@"If the database and tables already exist, this operation will do no harm.");
#endif
	
}

- (IBAction) dropAllTablesAction:(id)sender
{
	[self endEditing];
	NSString* s = [NSString stringWithFormat:@"Really drop all tables in %@ on %@?\n",[model dataBaseName],[model hostName]];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s];
    [alert setInformativeText:@"You can recreate the database with the 'Create Database' button"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Yes, Drop All"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertSecondButtonReturn){
            [model dropAllTables];
        }
    }];
#else
    NSBeginAlertSheet(s,
                      @"Cancel",
                      @"Yes, Drop All",
                      nil,[self window],
                      self,
                      @selector(dropActionDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"You can recreate the database with the 'Create Database' button");
#endif
	
}


#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) createActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	if(returnCode == NSAlertAlternateReturn){		
		[model createDatabase];
	}
}

- (void) dropActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo
{
	if(returnCode == NSAlertAlternateReturn){		
		[model dropAllTables];
	}
}
#endif
@end
