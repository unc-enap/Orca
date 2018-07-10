//
//  ORXLGPSController.h
//  ORCA
//
//  Created by Jarek Kaspar on November 2, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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

#import "OrcaObjectController.h"

@interface ORXLGPSController : OrcaObjectController
{
	IBOutlet NSButton*		lockButton;
	//telnet
	IBOutlet NSComboBox*		ipNumberComboBox;
	IBOutlet NSButton*		clrHistoryButton;
	IBOutlet NSTextField*		userField;
	IBOutlet NSSecureTextField*	passwordField;
	IBOutlet NSButton*		telnetPingButton;	
	IBOutlet NSProgressIndicator*	telnetPingPI;
	IBOutlet NSButton*		telnetTestButton;	
	IBOutlet NSProgressIndicator*	telnetTestPI;
	IBOutlet NSPopUpButton*		timeOutPU;
	//basic
	IBOutlet NSButton*		basicSendButton;
	IBOutlet NSProgressIndicator*	basicSendPI;
	IBOutlet NSTextField*		commandField;
	IBOutlet NSButton*		basicTimeButton;
	IBOutlet NSProgressIndicator*	basicTimePI;
	IBOutlet NSButton*		basicLockedButton;
	IBOutlet NSProgressIndicator*	basicLockedPI;
	IBOutlet NSButton*		basicReportButton;
	IBOutlet NSProgressIndicator*	basicReportPI;
	IBOutlet NSButton*		basicSatellitesButton;
	IBOutlet NSProgressIndicator*	basicSatellitesPI;
	IBOutlet NSButton*		basicSelfTestButton;
	IBOutlet NSProgressIndicator*	basicSelfTestPI;
	//ppo
	IBOutlet NSTextField*		ppoCommandField;
	IBOutlet NSTextField*		ppoDayField;
	IBOutlet NSTextField*		ppoHourField;
	IBOutlet NSTextField*		ppoMinuteField;
	IBOutlet NSTextField*		ppoSecondField;
	IBOutlet NSButton*		ppoNowButton;
	IBOutlet NSButton*		ppoTodayButton;
	IBOutlet NSTextField*		ppoTimeOffsetField;
	IBOutlet NSTextField*		ppoPulseWidthField;
	IBOutlet NSPopUpButton*		ppoPulsePeriodPU;
	IBOutlet NSButton*		ppoRepeatsButton;
	IBOutlet NSPopUpButton*		ppsCommandPU;
	IBOutlet NSMatrix*		isPpoMatrix;
	IBOutlet NSButton*		ppoGetButton;
	IBOutlet NSProgressIndicator*	ppoGetPI;
	IBOutlet NSButton*		ppoSetButton;
	IBOutlet NSProgressIndicator*	ppoSetPI;
	IBOutlet NSButton*		ppoTurnOffButton;
	IBOutlet NSProgressIndicator*	ppoTurnOffPI;
}	

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (void) populateOps;

#pragma mark •••Interface Management
- (void) updateWindow;
- (void) checkGlobalSecurity;
- (void) lockChanged:(NSNotification*)aNote;
- (void) updateButtons;
- (void) ipNumberChanged:(NSNotification*)aNote;
- (void) userChanged:(NSNotification*)aNote;
- (void) passwordChanged:(NSNotification*)aNote;
- (void) timeOutChanged:(NSNotification*)aNote;
- (void) commandChanged:(NSNotification*)aNote;
- (void) ppoCommandChanged:(NSNotification*)aNote;
- (void) ppoTimeChanged:(NSNotification*)aNote;
- (void) ppoTimeOffsetChanged:(NSNotification*)aNote;
- (void) ppoPulseWidthChanged:(NSNotification*)aNote;
- (void) ppoPulsePeriodChanged:(NSNotification*)aNote;
- (void) ppoRepeatsChanged:(NSNotification*)aNote;
- (void) ppsCommandChanged:(NSNotification*)aNote;
- (void) isPpoChanged:(NSNotification*)aNote;
- (void) opsRunningChanged:(NSNotification*)aNote;

#pragma mark •••Helper

#pragma mark •••Actions
- (IBAction) lockAction:(id) sender;
- (IBAction) opsAction:(id) sender;
//telnet
- (IBAction) ipNumberAction:(id)sender;
- (IBAction) clearHistoryAction:(id)sender;
- (IBAction) userFieldAction:(id)sender;
- (IBAction) passwordFieldAction:(id)sender;
- (IBAction) timeOutAction:(id)sender;
//basic
- (IBAction) commandAction:(id)sender;
//ppo
- (IBAction) ppoTimeAction:(id)sender;
- (IBAction) ppoTimeOffsetAction:(id)sender;
- (IBAction) ppoTodayAction:(id)sender;
- (IBAction) ppoNowAction:(id)sender;
- (IBAction) ppoPulseWidthAction:(id)sender;
- (IBAction) ppoRepeatsAction:(id)sender;
- (IBAction) ppoPulsePeriodAction:(id)sender;
- (IBAction) ppoCommandAction:(id)sender;
- (IBAction) ppsCommandAction:(id)sender;
- (IBAction) isPpoAction:(id)sender;
@end
