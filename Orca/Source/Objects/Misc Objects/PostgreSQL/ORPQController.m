//
//  ORPQController.m
//
//  2016-06-01 Created by Phil Harvey (Based on ORSqlController.m by M.Howe)
//
//-------------------------------------------------------------


#import "ORPQController.h"
#import "ORPQModel.h"
#import "ORPQConnection.h"
#import "ORValueBarGroupView.h"

@implementation ORPQController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"PostgreSQL"];
    return self;
}

- (void) dealloc
{
    [[[ORPQDBQueue sharedPQDBQueue] queue] removeObserver:self forKeyPath:@"operationCount"];
    [super dealloc];
}

-(void) awakeFromNib
{
	[super awakeFromNib];
	[[[ORPQDBQueue sharedPQDBQueue]queue] addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
}


#pragma mark ¥¥¥Registration
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(hostNameChanged:)
                         name : ORPQHostNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(userNameChanged:)
                         name : ORPQUserNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(passwordChanged:)
                         name : ORPQPasswordChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataBaseNameChanged:)
                         name : ORPQDataBaseNameChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(sqlLockChanged:)
                         name : ORPQLock
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(sqlLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(connectionValidChanged:)
                         name : ORPQConnectionValidChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(stealthModeChanged:)
                         name : ORPQModelStealthModeChanged
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
	NSOperationQueue* queue = [[ORPQDBQueue sharedPQDBQueue] queue];
    if (object == queue && [keyPath isEqual:@"operationCount"]) {
		NSNumber* n = [NSNumber numberWithInt:[[[ORPQDBQueue queue] operations] count]];
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
	[connectionValidField setStringValue:[model stealthMode]?@"Disabled":[model connected]?@"Connected":@"NOT Connected"];
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
    BOOL locked = [gSecurity isLocked:ORPQLock];
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
    [gSecurity setLock:ORPQLock to:secure];
    [sqlLockButton setEnabled: secure];
}

#pragma mark ¥¥¥Actions
- (IBAction) stealthModeAction:(id)sender
{
	[model setStealthMode:[sender intValue]];	
}

- (IBAction) sqlLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORPQLock to:[sender intValue] forWindow:[self window]];
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

@end
