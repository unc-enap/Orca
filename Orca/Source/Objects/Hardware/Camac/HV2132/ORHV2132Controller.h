
/*
 *  ORHV2132ModelController.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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

@interface ORHV2132Controller : OrcaObjectController {
	@private
        IBOutlet NSButton*		onButton;
        IBOutlet NSButton*		offButton;
        IBOutlet NSButton*		setButton;
        IBOutlet NSButton*		readButton;
        IBOutlet NSStepper*		hvValueStepper;
        IBOutlet NSTextField*	hvValueTextField;
        IBOutlet NSPopUpButton*	mainFramePU;
        IBOutlet NSPopUpButton*	channelPU;
 
        IBOutlet NSButton*		settingLockButton;
        IBOutlet NSTextField*   settingLockDocField;

        IBOutlet NSButton*		statusButton;
        IBOutlet NSButton*		enableL1L2Button;
        IBOutlet NSButton*		disableL1L2Button;
        IBOutlet NSButton*		clearBufferButton;
		
		IBOutlet NSTextField* hvStateDirField;

};

#pragma mark ¥¥¥Interface Management
- (void) registerNotificationObservers;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) hvValueChanged:(NSNotification*)aNotification;
- (void) mainFrameChanged:(NSNotification*)aNotification;
- (void) channelChanged:(NSNotification*)aNotification;
- (void) showError:(NSException*)anException name:(NSString*)name;
- (void) populateChannelPU;
- (void) populateMainFramePU;
- (void) dirChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) chooseDir:(id)sender;
- (IBAction) hvValueAction:(id) sender;
- (IBAction) onAction:(id) sender;
- (IBAction) offAction:(id) sender;
- (IBAction) setAction:(id)sender;
- (IBAction) readAction:(id)sender;
- (IBAction) channelAction:(id)sender;
- (IBAction) mainFrameAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) enableL1L2Action:(id) sender;
- (IBAction) disableL1L2Action:(id) sender;
- (IBAction) clearBufferAction:(id) sender;
- (IBAction) statusAction:(id) sender;

@end