//
//  ORPQController.h
//
//  2016-06-01 Created by Phil Harvey (Based on ORSqlController.h by M.Howe)
//
//-------------------------------------------------------------

@class ORValueBarGroupView;

@interface ORPQController : OrcaObjectController 
{	
	IBOutlet NSTextField* hostNameField;
	IBOutlet NSButton*	  stealthModeButton;
	IBOutlet NSTextField* userNameField;
	IBOutlet NSTextField* passwordField;
	IBOutlet NSTextField* dataBaseNameField;
	IBOutlet NSTextField* connectionValidField;
    IBOutlet NSButton*    sqlLockButton;
    IBOutlet NSButton*    connectionButton;
    IBOutlet ORValueBarGroupView*  queueValueBar;

	double queueCount;
}

#pragma mark ***Interface Management
- (void) registerNotificationObservers;
- (void) stealthModeChanged:(NSNotification*)aNote;
- (void) hostNameChanged:(NSNotification*)aNote;
- (void) userNameChanged:(NSNotification*)aNote;
- (void) passwordChanged:(NSNotification*)aNote;
- (void) dataBaseNameChanged:(NSNotification*)aNote;
- (void) sqlLockChanged:(NSNotification*)aNote;
- (void) connectionValidChanged:(NSNotification*)aNote;
- (void) updateConnectionValidField;
- (void) setQueCount:(NSNumber*)n;

#pragma mark ¥¥¥Actions
- (IBAction) stealthModeAction:(id)sender;
- (IBAction) hostNameAction:(id)sender;
- (IBAction) userNameAction:(id)sender;
- (IBAction) passwordAction:(id)sender;
- (IBAction) databaseNameAction:(id)sender;
- (IBAction) sqlLockAction:(id)sender;
- (IBAction) connectionAction:(id)sender;
@end
