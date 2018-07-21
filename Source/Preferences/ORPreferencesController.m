//
//  ORPreferencesController.m
//  Orca
//
//  Created by Mark Howe on Sat Dec 28 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORPreferencesController.h"
#import "SynthesizeSingleton.h"

#define kLocked 1
#define kUnlocked 0

@interface ORPreferencesController (private)
- (void) _openValidatePassWordPanel;
- (void) _openSetNewPassWordPanel;
- (void) _shakeIt;
- (void) _setPassWordButtonText;
@end;

@implementation ORPreferencesController

#pragma mark ¥¥¥Initialization

SYNTHESIZE_SINGLETON_FOR_ORCLASS(PreferencesController);

-(id)init
{
    self = [super initWithWindowNibName:@"ORPreferences"];
    if (self) {
        [self setWindowFrameAutosaveName:@"ORPreferences"];
    }	
	return self;
}

#pragma mark ¥¥¥Window Management
-(void)windowDidLoad
{
    NSUserDefaults* defaults 	= [NSUserDefaults standardUserDefaults];
    NSColor*	    color       = [NSColor whiteColor];

    NSData*	    colorAsData		= [defaults objectForKey: ORBackgroundColor];
    if(colorAsData != nil){
        color = colorForData(colorAsData);
    }
    [backgroundColorWell setColor:color];

    colorAsData = [defaults objectForKey: ORLineColor];
    color       = [NSColor blackColor]; //default
    if(colorAsData != nil)color = colorForData(colorAsData);
    [lineColorWell setColor:color];

    int tag = [[defaults objectForKey: OROpeningDocPreferences] intValue];
    [openingDocPrefMatrix selectCellWithTag: tag ];

    tag = [[defaults objectForKey: OROpeningDialogPreferences] intValue];
    [openingDialogMatrix selectCellWithTag: tag ];

    int lineType = [[defaults objectForKey: ORLineType] intValue];
    [lineTypeMatrix selectCellWithTag: lineType ];

    [self setLockButtonState:[[defaults objectForKey: OROrcaSecurityEnabled] boolValue]];

    [sendBugReportButton setState:[[defaults objectForKey: ORMailBugReportFlag] boolValue]];
    if([defaults objectForKey: ORMailBugReportEMail]){
		[bugReportEMailField setString:[defaults objectForKey: ORMailBugReportEMail]];
    }

    color			= [NSColor whiteColor]; //default
    colorAsData		= [defaults objectForKey: ORScriptBackgroundColor];
    if(colorAsData != nil)color = colorForData(colorAsData);
    [scriptBackgroundColorWell setColor:color];

    color			= [NSColor redColor]; //default
    colorAsData		= [defaults objectForKey: ORScriptCommentColor];
    if(colorAsData != nil)color = colorForData(colorAsData);
    [scriptCommentColorWell setColor:color];

    color			= [NSColor greenColor]; //default
    colorAsData		= [defaults objectForKey: ORScriptStringColor];
    if(colorAsData != nil)color = colorForData(colorAsData);
    [scriptStringColorWell setColor:color];

    color			= [NSColor blueColor]; //default
    colorAsData		= [defaults objectForKey: ORScriptIdentifier1Color];
    if(colorAsData != nil)color = colorForData(colorAsData);
    [scriptIdentifier1ColorWell setColor:color];

    color			= [NSColor grayColor]; //default
    colorAsData		= [defaults objectForKey: ORScriptIdentifier2Color];
    if(colorAsData != nil)color = colorForData(colorAsData);
    [scriptIdentifier2ColorWell setColor:color];

    color			= [NSColor orangeColor]; //default
    colorAsData		= [defaults objectForKey: ORScriptConstantsColor];
    if(colorAsData != nil)color = colorForData(colorAsData);
    [scriptConstantsColorWell setColor:color];

    [bugReportEMailField setDelegate:self];
    [nextTimeTextField setStringValue:@" "];
    [self _setPassWordButtonText];

    tag = [[defaults objectForKey: ORHelpFilesUseDefault] intValue];
    [helpFileLocationMatrix selectCellWithTag: tag ];
	[helpFileLocationPathField setStringValue:[defaults objectForKey: ORHelpFilesPath]];
	[helpFileLocationPathField setEnabled:tag];
	[helpFileLocationPathField setNeedsDisplay:YES];
	
	[heartbeatPathField setStringValue:[[defaults objectForKey: ORPrefHeartBeatPath] stringByAbbreviatingWithTildeInPath]];
	[activateHeartbeatCB setIntValue:[[defaults objectForKey: ORPrefHeartBeatEnabled] intValue]];

    //-----mail preferences --------
    tag = [[defaults objectForKey: ORMailSelectionPreference] intValue];
    [mailSelectionMatrix selectCellWithTag: tag ];
    NSString* ser = [defaults objectForKey: ORMailServer];
    if(ser)[mailServerField setStringValue: ser];
    NSString* add = [defaults objectForKey: ORMailAddress];
    if(add)[mailAddressField setStringValue: add];
    NSString* pw = [defaults objectForKey: ORMailPassword];
    if(pw)[mailPasswordField setStringValue:pw];

    [mailServerField   setEnabled: tag == 1];
    [mailAddressField  setEnabled: tag == 1];
    [mailPasswordField setEnabled: tag == 1];
    
}

#pragma mark ¥¥¥Accessors
- (void) setLockButtonState:(BOOL)state
{
    [lockButton setState:state];
    if(state){
        [lockTextField setStringValue:@"Click the lock to disable\nOrca's security features."];
    }
    else {
        [lockTextField setStringValue:@"Click the lock to enable\nOrca's security features."];
    }
}

- (void) setLockState:(BOOL)state
{
    if(state != [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue]){
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:state] forKey:OROrcaSecurityEnabled];    

        [[NSNotificationCenter defaultCenter]
            postNotificationName:ORGlobalSecurityStateChanged
                          object:self
                        userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:state] forKey:OROrcaSecurityEnabled]];
    }
    [self setLockButtonState:[[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue]];
}


#pragma mark ¥¥¥Actions
-(IBAction)changeBackgroundColor:(id)sender
{

    [[NSUserDefaults standardUserDefaults] setObject:dataForColor([sender color]) forKey:ORBackgroundColor];
    

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORBackgroundColorChangedNotification
                      object:self
                    userInfo:nil];
}

-(IBAction)changeLineColor:(id)sender
{

    [[NSUserDefaults standardUserDefaults] setObject:dataForColor([sender color]) forKey:ORLineColor];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORLineColorChangedNotification
                      object:self
                    userInfo:nil];
}

- (IBAction) openingDocPrefAction:(id)sender
{
    NSInteger tag = [[openingDocPrefMatrix selectedCell] tag];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:tag] forKey:OROpeningDocPreferences];
}

- (IBAction) openingDialogAction:(id)sender
{
    NSInteger tag = [[openingDialogMatrix selectedCell] tag];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:tag] forKey:OROpeningDialogPreferences];
}


- (IBAction) lineTypeAction:(id)sender
{
    NSInteger tag = [[lineTypeMatrix selectedCell] tag];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:tag] forKey:ORLineType];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORLineTypeChangedNotification
                      object:self
                    userInfo:nil];
}

- (IBAction) lockAction:(id)sender
{
    BOOL newState = [(NSButton*)sender state];
    BOOL oldState = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    if(oldState == kLocked && newState == kUnlocked){
        NSString* thePassWord = [[NSUserDefaults standardUserDefaults] objectForKey:OROrcaPassword];
        if(!thePassWord || ([thePassWord length] == 0)){
            [self _openSetNewPassWordPanel];
        }
        else [self _openValidatePassWordPanel];
    }
    else {
        [self setLockState:[(NSButton*)sender state]];
        NSLog(@"Global security enabled.\n");
    }
}

- (IBAction)closePassWordPanel:(id)sender
{
    [passWordPanel orderOut:self];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    [NSApp endSheet:passWordPanel returnCode:([sender tag] == 1) ? NSModalResponseOK : NSModalResponseCancel];
#else
    [NSApp endSheet:passWordPanel returnCode:([sender tag] == 1) ? NSOKButton : NSCancelButton];
#endif
}

- (IBAction) changePassWordAction:(id)sender
{
    disallowStateChange = YES;
    NSString* thePassWord = [[NSUserDefaults standardUserDefaults] objectForKey:OROrcaPassword];
    if(!thePassWord || ([thePassWord length] == 0)){
        [self _openSetNewPassWordPanel];
     }
    else {
		[oldPassWordField setStringValue:@""];
        [newPassWordField setStringValue:@""];
        [confirmPassWordField setStringValue:@""];
        [[self window] beginSheet:changePassWordPanel completionHandler:^(NSModalResponse returnCode){
                if(returnCode == NSModalResponseOK){
                    if([[oldPassWordField stringValue] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaPassword]]){
                        if([[newPassWordField stringValue] length] == 0){
                            NSBeep();
                            NSLog(@"Orca passwords cannot have zero length.\n");
                            [self _shakeIt];
                        }
                        else if([[newPassWordField stringValue] isEqualToString:[confirmPassWordField stringValue]]){
                            [[NSUserDefaults standardUserDefaults] setObject:[newPassWordField stringValue] forKey:OROrcaPassword];
                            NSLog(@"Orca password changed.\n");
                        }
                        else {
                            NSBeep();
                            NSLog(@"The confirming password doesn't match.\n");
                            NSLog(@"Password NOT changed!\n");
                            [self _shakeIt];
                        }
                    }
                    else [self _shakeIt];
                }
            [self _setPassWordButtonText];

        }];

    }
}



- (IBAction) closeChangePassWordPanel:(id)sender
{
        [changePassWordPanel orderOut:self];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    [NSApp endSheet:changePassWordPanel returnCode:([sender tag] == 1) ? NSModalResponseOK : NSModalResponseCancel];
#else
    [NSApp endSheet:changePassWordPanel returnCode:([sender tag] == 1) ? NSOKButton : NSCancelButton];
#endif
}

- (IBAction) closeSetPassWordPanel:(id)sender
{
    [setPassWordPanel orderOut:self];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
   [NSApp endSheet:setPassWordPanel returnCode:([sender tag] == 1) ? NSModalResponseOK : NSModalResponseCancel];
#else
    [NSApp endSheet:setPassWordPanel returnCode:([sender tag] == 1) ? NSOKButton : NSCancelButton];
#endif
}

- (IBAction) enableBugReportSendAction:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[(NSButton*)sender state]] forKey:ORMailBugReportFlag];    
}

- (void) textDidChange:(NSNotification*)aNote
{
    if([[aNote object] isEqualTo:bugReportEMailField]){
		[[NSUserDefaults standardUserDefaults] setObject:[[aNote object] string] forKey:ORMailBugReportEMail];    
    }
}

-(IBAction)changeScriptBackgroundColor:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:dataForColor([sender color]) forKey:ORScriptBackgroundColor];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORSyntaxColorChangedNotification
                      object:self
                    userInfo:nil];
}

- (IBAction) changeScriptCommentColor:(id)sender
{

    [[NSUserDefaults standardUserDefaults] setObject:dataForColor([sender color]) forKey:ORScriptCommentColor];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORSyntaxColorChangedNotification
                      object:self
                    userInfo:nil];
}

- (IBAction) changeScriptStringColor:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:dataForColor([sender color]) forKey:ORScriptStringColor];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORSyntaxColorChangedNotification
                      object:self
                    userInfo:nil];
}

- (IBAction) changeScriptIndentifier1Color:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:dataForColor([sender color]) forKey:ORScriptIdentifier1Color];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORSyntaxColorChangedNotification
                      object:self
                    userInfo:nil];
}

- (IBAction) changeScriptIndentifier2Color:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:dataForColor([sender color]) forKey:ORScriptIdentifier2Color];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORSyntaxColorChangedNotification
                      object:self
                    userInfo:nil];
}

- (IBAction) changeScriptConstantsColor:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:dataForColor([sender color]) forKey:ORScriptConstantsColor];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORSyntaxColorChangedNotification
                      object:self
                    userInfo:nil];
}

- (IBAction) helpFileLocationPrefAction:(id)sender
{
    NSInteger tag = [[helpFileLocationMatrix selectedCell] tag];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:tag] forKey:ORHelpFilesUseDefault];
	[helpFileLocationPathField setEnabled:tag];
	[helpFileLocationPathField setNeedsDisplay:YES];
	[[NSNotificationCenter defaultCenter]postNotificationName:ORHelpFilesPathChanged object:nil];
}

- (IBAction) helpFilePathAction:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:[sender stringValue] forKey:ORHelpFilesPath];    
	[[NSNotificationCenter defaultCenter]postNotificationName:ORHelpFilesPathChanged object:nil];
}

- (IBAction) activateHeatbeatAction:(id)sender;
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[sender intValue]] forKey:ORPrefHeartBeatEnabled];    
	[[NSNotificationCenter defaultCenter]postNotificationName:ORPrefHeartBeatEnabledChanged object:nil];
}

- (IBAction) activatePostLogAction:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[sender intValue]] forKey:ORPrefPostLogEnabled];    
	[[NSNotificationCenter defaultCenter]postNotificationName:ORPrefPostLogEnabledChanged object:nil];
}

- (IBAction) selectHeartbeatPathAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Choose Heartbeat Location"];
	NSString* startPath = [[NSUserDefaults standardUserDefaults] objectForKey: ORPrefHeartBeatPath];
	if(![startPath length])startPath = [@"~" stringByExpandingTildeInPath];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startPath]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* path = [[openPanel URL]path];
            [[NSUserDefaults standardUserDefaults] setObject:path forKey:ORPrefHeartBeatPath];
            [heartbeatPathField setStringValue:[path stringByAbbreviatingWithTildeInPath]];
            
            [[NSNotificationCenter defaultCenter]postNotificationName:ORPrefHeartBeatPathChanged object:nil];
        }
    }];
}

- (IBAction) mailSelectionAction:(id)sender
{
    NSInteger tag = [[mailSelectionMatrix selectedCell] tag];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:tag] forKey:ORMailSelectionPreference];
    
    [mailServerField   setEnabled: tag == 1];
    [mailAddressField  setEnabled: tag == 1];
    [mailPasswordField setEnabled: tag == 1];
    
}

- (IBAction) mailServerAction:(id)sender
{
    [mailServerField setStringValue:[sender stringValue]];
    [[NSUserDefaults standardUserDefaults] setObject:[sender stringValue] forKey:ORMailServer];
}


- (IBAction) mailAddressAction:(id)sender
{
    [mailAddressField setStringValue:[sender stringValue]];
    [[NSUserDefaults standardUserDefaults] setObject:[sender stringValue] forKey:ORMailAddress];
}

- (IBAction) mailPasswordAction:(id)sender;
{
    [mailPasswordField setStringValue:[sender stringValue]];
    [[NSUserDefaults standardUserDefaults] setObject:[sender stringValue] forKey:ORMailPassword];
}

@end

@implementation ORPreferencesController (private)
- (void)  _openSetNewPassWordPanel     
{
    [setPassWordField setStringValue:@""];
    [confirmSetPassWordField setStringValue:@""];
    
    [[self window] beginSheet:changePassWordPanel completionHandler:^(NSModalResponse returnCode){
        if(returnCode == NSModalResponseOK){
            if([[setPassWordField stringValue] length] == 0){
                if(!disallowStateChange)[self setLockState:YES];
                NSBeep();
                NSLog(@"Orca passwords cannot have zero length.\n");
                [self _shakeIt];
            }
            else if([[setPassWordField stringValue] isEqualToString:[confirmSetPassWordField stringValue]]){
                [[NSUserDefaults standardUserDefaults] setObject:[setPassWordField stringValue] forKey:OROrcaPassword];
                
                if(!disallowStateChange)[self setLockState:NO];
                NSLog(@"Global security disabled.\n");
            }
            else {
                if(!disallowStateChange)[self setLockState:YES];
                NSBeep();
                NSLog(@"The confirming password doesn't match.\n");
                [self _shakeIt];
            }
        }
        else if(!disallowStateChange)[self setLockState:YES];
        [self _setPassWordButtonText];

    }];
}

- (void)  _openValidatePassWordPanel     
{
    [passWordField setStringValue:@""];
    
    [[self window] beginSheet:passWordPanel completionHandler:^(NSModalResponse returnCode){
        if(returnCode == NSModalResponseOK){
            if([[passWordField stringValue] isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaPassword]]){
                [self setLockState:NO];
                NSLog(@"Orca global security password entered successfully.\n");
                NSLog(@"Global security disabled.\n");
            }
            else {
                [self setLockState:YES];
                NSLog(@"Attempt to enter a global Orca security password failed.\n");
                NSLog(@"Global security remains enabled.\n");
                [self _shakeIt];
            }
        }
        else {
            [self setLockState:YES];
            NSLog(@"Global security enabled.\n");
        }
    }];
    
}

- (void) _shakeIt 
{
    NSRect theFrame = [[self window] frame];
    NSRect startingFrame = theFrame;
    int i;
    float dis = 10;
    for(i=0;i<10;i++){
        if(i%2){
            theFrame.origin.x = startingFrame.origin.x + dis;
            dis = dis - 2.;
        }
        else {
            theFrame.origin.x = startingFrame.origin.x - dis;
       }
       [[self window] setFrame:theFrame display:YES animate:YES];
  
    }
    [[self window] setFrame:startingFrame display:YES animate:YES];
}

- (void) _setPassWordButtonText
{
    NSString* thePassWord = [[NSUserDefaults standardUserDefaults] objectForKey:OROrcaPassword];
    if(!thePassWord || ([thePassWord length] == 0)){
        [passwordButton setTitle:@"Set Password"];
    }
    else {
        [passwordButton setTitle:@"Change Password"];
    }
}

@end

