//
//  ORTTCPX400DPController.m
//  Orca
//
//  Created by Michael Marino on Saturday 12 Nov 2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "OrcaObjectController.h"


@interface ORTTCPX400DPController : OrcaObjectController 
{
	IBOutlet NSButton*		lockButton;
    IBOutlet NSTextField*   ipAddressBox;
    IBOutlet NSTextField*   serialNumberBox;    
    IBOutlet NSPopUpButton* commandPopUp;
    IBOutlet NSPopUpButton* outputNumberPopUp;
    IBOutlet NSTextField*   inputValueText;    
    IBOutlet NSTextField*   readBackText;  
    IBOutlet NSButton*      connectButton;
    IBOutlet NSButton*      sendCommandButton;
    IBOutlet NSButton*      clearButton;
    IBOutlet NSButton*      resetButton;
    IBOutlet NSButton*      resetTripsButton;
    IBOutlet NSButton*      checkErrorsButton;
    
    
    IBOutlet NSButton*      syncOutButton;
    IBOutlet NSButton*      readButton;
    IBOutlet NSButton*      syncButton;
    
    IBOutlet NSTextField*   readBackVoltOne;
    IBOutlet NSTextField*   readBackVoltTripOne;    
    IBOutlet NSTextField*   readBackCurrentOne;
    IBOutlet NSTextField*   readBackCurrentTripOne;   
    
    IBOutlet NSTextField*   readBackVoltTwo;
    IBOutlet NSTextField*   readBackVoltTripTwo;    
    IBOutlet NSTextField*   readBackCurrentTwo;
    IBOutlet NSTextField*   readBackCurrentTripTwo;

    IBOutlet NSTextField*   writeVoltOne;
    IBOutlet NSTextField*   writeVoltTripOne;    
    IBOutlet NSTextField*   writeCurrentOne;
    IBOutlet NSTextField*   writeCurrentTripOne;   
    
    IBOutlet NSTextField*   writeVoltTwo;
    IBOutlet NSTextField*   writeVoltTripTwo;    
    IBOutlet NSTextField*   writeCurrentTwo;
    IBOutlet NSTextField*   writeCurrentTripTwo; 
    
    IBOutlet NSButton*      outputOnOne;
    IBOutlet NSButton*      outputOnTwo;
    IBOutlet NSButton*      verbosity;
    
    IBOutlet NSTextField*   lockText;
    IBOutlet NSTextField*   channelOneModeText;
    IBOutlet NSTextField*   channelTwoModeText;
}

#pragma mark •••Initialization
- (id)	 init;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

- (void) updateButtons;

#pragma mark ***Interface Management
- (void) lockChanged:(NSNotification*)aNote;
- (void) ipChanged:(NSNotification*)aNote;
- (void) serialChanged:(NSNotification*)aNote;
- (void) connectionChanged:(NSNotification*)aNote;
- (void) generalReadbackChanged:(NSNotification*)aNote;
- (void) readbackChanged:(NSNotification*)aNote;
- (void) setValuesChanged:(NSNotification*)aNote;
- (void) outputStatusChanged:(NSNotification*)aNote;
- (void) verbosityChanged:(NSNotification*)aNote;
- (void) hardwareErrorSeen:(NSNotification*)aNote;
- (void) channelModeChanged:(NSNotification*)aNote;

#pragma mark •••Actions
//- (IBAction) passwordFieldAction:(id)sender;
- (IBAction) lockAction:(id)sender;
- (IBAction) commandPulldownAction:(id)sender;
- (IBAction) setSerialNumberAction:(id)sender;
- (IBAction)setIPAddressAction:(id)sender;
- (IBAction) connectAction:(id)sender;
- (IBAction) sendCommandAction:(id)sender;
- (IBAction) readBackAction:(id)sender;
- (IBAction) syncValuesAction:(id)sender;
- (IBAction) changeVerbosityAction:(id)sender;
- (IBAction) writeOutputStatusAction:(id)sender;
- (IBAction) clearAction:(id)sender;
- (IBAction) resetAction:(id)sender;
- (IBAction) resetTripsAction:(id)sender;
- (IBAction) checkAndClearErrorsAction:(id)sender;

@end


