
/*
 *  ORCCUSBController.h
 *  Orca
 *
 *  Created by Mark Howe on Tues May 30 2006.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */

#pragma mark ¥¥¥Imported Files

#import "ORCCUSBModel.h"
#import "ORCC32Controller.h"

@interface ORCCUSBController : ORCC32Controller {
	@private
		IBOutlet    NSTextField* fValueTextField;
		IBOutlet    NSTextField* numberOfProductTermsTextField;
		IBOutlet    NSTableView* customStackTable;
		IBOutlet	NSButton* useDataModifierButton;
		IBOutlet    NSTextField* dataWordTextField;
		IBOutlet    NSMatrix* dataModifierBitsMatrix;
		IBOutlet    NSMatrix* nafModBitsMatrix;
		IBOutlet    NSTextField* aValueTextField;
		IBOutlet    NSTextField* nValueTextField;
		
 		IBOutlet	NSTabView* tabView;
		IBOutlet	NSPopUpButton* serialNumberPopup;
		IBOutlet	NSTextField* registerValueTextField;
		IBOutlet	NSPopUpButton* internalRegSelectionPopup;
		IBOutlet	NSStepper* registerValueStepper;
		IBOutlet    NSButton* readRegButton;
		IBOutlet    NSButton* writeRegButton;
		
		IBOutlet    NSPopUpButton* bufferSizePopup;
		
		IBOutlet	NSMatrix* userLEDLatchInvertMatrix;
		IBOutlet	NSPopUpButton* redLedSourcePopup;
		IBOutlet	NSPopUpButton* greenLedSourcePopup;
		IBOutlet	NSPopUpButton* yellowLedSourcePopup;
		
		IBOutlet	NSMatrix* userNIMLatchInvertMatrix;
		IBOutlet	NSPopUpButton* nim01SourcePopup;
		IBOutlet	NSPopUpButton* nim02SourcePopup;
		IBOutlet	NSPopUpButton* nim03SourcePopup;

		IBOutlet	NSTextField* lamTimeOutField;
		IBOutlet	NSTextField* triggerDelayField;

		IBOutlet	NSTextField* timeIntervalField;
		IBOutlet	NSTextField* numSepEventsField;

		IBOutlet	NSMatrix* scalerEnableMatrix;
		IBOutlet	NSMatrix* scalerResetMatrix;
		IBOutlet	NSPopUpButton* scalerAModePopup;
		IBOutlet	NSPopUpButton* scalerBModePopup;
		IBOutlet	NSPopUpButton* dggAModePopup;
		IBOutlet	NSPopUpButton* dggBModePopup;

		IBOutlet	NSTextField* dggAGateTextField;
		IBOutlet	NSTextField* dggADelayFineTextField;
		IBOutlet	NSTextField* dggADelayCoarseTextField;

		IBOutlet	NSTextField* dggBGateTextField;
		IBOutlet	NSTextField* dggBDelayFineTextField;
		IBOutlet	NSTextField* dggBDelayCoarseTextField;
		IBOutlet	NSTextField* lamMaskValueField;
		IBOutlet	NSTextField* scalerATextField;
		IBOutlet	NSTextField* scalerBTextField;
		IBOutlet	NSTextField* timeOutTextField;
		IBOutlet	NSTextField* numBuffersTextField;
		IBOutlet	NSButton*	 writeInternalRegistersButton;
		
};
#pragma mark ¥¥¥Initialization

#pragma mark ¥¥¥Interface Management
- (void) customStackChanged:(NSNotification*)aNote;
- (void) useDataModifierChanged:(NSNotification*)aNote;
- (void) dataWordChanged:(NSNotification*)aNote;
- (void) dataModifierBitsChanged:(NSNotification*)aNote;
- (void) nafModBitsChanged:(NSNotification*)aNote;
- (void) fValueChanged:(NSNotification*)aNote;
- (void) aValueChanged:(NSNotification*)aNote;
- (void) nValueChanged:(NSNotification*)aNote;
- (void) usbTransferSetupChanged:(NSNotification*)aNote;
- (void) LAMMaskChanged:(NSNotification*)aNote;
- (void) scalerBChanged:(NSNotification*)aNote;
- (void) scalerAChanged:(NSNotification*)aNote;
- (void) delayAndGateExtChanged:(NSNotification*)aNote;
- (void) delayAndGateBChanged:(NSNotification*)aNote;
- (void) delayAndGateAChanged:(NSNotification*)aNote;
- (void) scalerReadoutChanged:(NSNotification*)aNote;
- (void) userDeviceSelectorChanged:(NSNotification*)aNote;
- (void) userNIMSelectorChanged:(NSNotification*)aNote;
- (void) userLEDSelectorChanged:(NSNotification*)aNote;
- (void) delaysChanged:(NSNotification*)aNote;
- (void) globalModeChanged:(NSNotification*)aNote;
- (void) registerValueChanged:(NSNotification*)aNote;
- (void) internalRegSelectionChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) usbTransferSetupChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) useDataModifierButtonAction:(id)sender;
- (IBAction) dataWordTextFieldAction:(id)sender;
- (IBAction) dataModifierBitsMatrixAction:(id)sender;
- (IBAction) nafModBitsMatrixAction:(id)sender;
- (IBAction) fValueTextFieldAction:(id)sender;
- (IBAction) aValueTextFieldAction:(id)sender;
- (IBAction) nValueTextFieldAction:(id)sender;
- (IBAction) userLEDInvertLatchAction:(id)sender;
- (IBAction) userLEDCodeAction:(id)sender;
- (IBAction) userNIMInvertLatchAction:(id)sender;
- (IBAction) userNIMCodeAction:(id)sender;
- (IBAction) scalerEnableAction:(id)sender;
- (IBAction) scalerResetAction:(id)sender;
- (IBAction) dggExtAction:(id)sender;
- (IBAction) dggAAction:(id)sender;
- (IBAction) dggBAction:(id)sender;
- (IBAction) scalerAndDggAction:(id)sender;
- (IBAction) timeIntervalActionAction:(id)sender;
- (IBAction) numSepEventsAction:(id)sender;
- (IBAction) lamTimeOutAction:(id)sender;
- (IBAction) triggerDelayAction:(id)sender;
- (IBAction) bufferSizeAction:(id)sender;
- (IBAction) registerValueTextFieldAction:(id)sender;
- (IBAction) internalRegSelectionAction:(id)sender;
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) getStatusAction:(id)sender;
- (IBAction) writeRegAction:(id)sender;
- (IBAction) readRegAction:(id)sender;
- (IBAction) LAMMaskValueAction:(id)sender;
- (IBAction) usbTransferSetupAction:(id)sender;
- (IBAction) writeInternalRegistersAction:(id)sender;
- (IBAction) addNAFToStack:(id)sender;
- (IBAction) addDataWordToStack:(id)sender;
- (IBAction) clearStack:(id)sender;
- (IBAction) executeListAction:(id)sender;
- (IBAction) readStackAction:(id)sender;
- (IBAction) saveStackAction:(id)sender;

- (void) populateInterfacePopup:(ORUSB*)usb;
- (void) validateInterfacePopup;

@end