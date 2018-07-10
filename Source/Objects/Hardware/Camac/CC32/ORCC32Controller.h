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
#import "ORCC32Model.h"

@interface ORCC32Controller : OrcaObjectController {
	@private
        IBOutlet NSButton*       executeButton;
        IBOutlet NSPopUpButton* cmdSelectPopUp;
        IBOutlet NSTextField*   stationField;
        IBOutlet NSStepper*     stationStepper;
        IBOutlet NSTextField*   subaddressField;
        IBOutlet NSStepper*     subaddressStepper;
        IBOutlet NSTextField*   writeValueField;
        IBOutlet NSStepper*     writeValueStepper;
        IBOutlet NSTextField*   helpField;
        IBOutlet NSTextField*   moduleWriteValueField;
        
        IBOutlet NSTextField*   responseField;
        IBOutlet NSTextField*   cmdAcceptedField;
        IBOutlet NSTextField*   inhibitField;
        IBOutlet NSTextField*   lookAtMeField;
        IBOutlet NSTextField*   valueField;

        IBOutlet NSButton*     initButton;
        IBOutlet NSButton*     testButton;
        IBOutlet NSButton*     resetButton;
        IBOutlet NSButton*     inhibitOnButton;
        IBOutlet NSButton*     inhibitOffButton;
        IBOutlet NSButton*     setLamMaskButton;
        IBOutlet NSButton*     zCycleButton;
        IBOutlet NSButton*     cCycleButton;
        IBOutlet NSButton*     cICycleButton;
        IBOutlet NSButton*     zICycleButton;
        IBOutlet NSButton*     resetLamFFButton;

        IBOutlet NSButton*     readIhibitButton;
        IBOutlet NSButton*     readLamMaskButton;
        IBOutlet NSButton*     readLamStationsButton;
        IBOutlet NSButton*     readLedsButton;
        IBOutlet NSButton*     readLamFFButton;

        IBOutlet NSButton*		settingLockButton;

        NSArray* helpStrings;
};
#pragma mark ¥¥¥Initialization
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ¥¥¥Accessors
- (NSArray *) helpStrings;
- (void) setHelpStrings: (NSArray *) aHelpStrings;
- (NSString*) helpString:(int)index;

#pragma mark ¥¥¥Interface Management
- (void) setButtonStates;
- (BOOL) validateMenuItem:(NSMenuItem*)menuItem;
- (void) registerNotificationObservers;
- (void) cmdSelectedChanged:(NSNotification*)aNotification;
- (void) cmdStationChanged:(NSNotification*)aNotification;
- (void) cmdSubAddressChanged:(NSNotification*)aNotification;
- (void) cmdWriteValueChanged:(NSNotification*)aNotification;
- (void) moduleWriteValueChanged:(NSNotification*)aNotification;
- (void) reponseValuesChanged:(NSNotification*)aNotification;
- (void) settingsLockChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) settingLockAction:(id) sender;
- (IBAction) init:(id)sender;
- (IBAction) test:(id)sender;
- (IBAction) resetController:(id)sender;
- (IBAction) inhibitOnAction:(id)sender;
- (IBAction) inhibitOffAction:(id)sender;
- (IBAction) setLamMaskAction:(id)sender;
- (IBAction) zCycleAction:(id)sender;
- (IBAction) cCycleAction:(id)sender;
- (IBAction) zCycleIAction:(id)sender;
- (IBAction) cCycleIAction:(id)sender;
- (IBAction) resetLamFFAction:(id)sender;

- (IBAction) readInhibitAction:(id)sender;
- (IBAction) readLamMaskAction:(id)sender;
- (IBAction) readLamStationsAction:(id)sender;
- (IBAction) readLedsAction:(id)sender;
- (IBAction) readLamFFAction:(id)sender;


- (IBAction) cmdSelectAction:(id)sender;
- (IBAction) cmdStationAction:(id)sender;
- (IBAction) cmdSubAddressAction:(id)sender;
- (IBAction) cmdWriteValueAction:(id)sender;
- (IBAction) moduleWriteValueAction:(id)sender;
- (IBAction) execute:(id)sender;


@end