
//
//  OREdelweissSLTController.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
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


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Imported Files
#import "OREdelweissSLTModel.h"
#import "SBC_LinkController.h"

@interface OREdelweissSLTController : SBC_LinkController {
	@private
	
    //BB commands
    IBOutlet   NSTextField* eventFifoStatusRegTextField;
	IBOutlet   NSButton* saveIonChanFilterOutputRecordsCB;
	IBOutlet   NSButton* resetEventCounterAtRunStartCB;
	IBOutlet   NSTextField* statusHighRegTextField;
	IBOutlet   NSTextField* statusLowRegTextField;
	IBOutlet   NSButton* useBroadcastIdBBCB;
	IBOutlet   NSTextField* idBBforWCommandTextField;
	IBOutlet   NSTextField* crateUDPDataCommandTextField;
	IBOutlet   NSTextField* BBCmdFFMaskTextField;
    IBOutlet   NSMatrix*		BBCmdFFMaskMatrix;
	IBOutlet   NSTextField* cmdWArg4TextField;
	IBOutlet   NSTextField* cmdWArg3TextField;
	IBOutlet   NSTextField* cmdWArg2TextField;
	IBOutlet   NSTextField* cmdWArg1TextField;
    
        //DAQ mode
	    IBOutlet   NSTextField* sltDAQModeTextField;
		IBOutlet NSPopUpButton* sltDAQModePU;
	IBOutlet   NSButton* takeEventDataCB;
	IBOutlet   NSButton* takeUDPstreamDataCB;
	IBOutlet   NSButton* takeADCChannelDataCB;
	IBOutlet   NSButton* takeRawUDPDataCB;
        
        //UDP Data tab ----
	IBOutlet   NSTextField* numRequestedUDPPacketsTextField;
	IBOutlet   NSTextField* chargeBBFileTextField;
    
        //control reg tab
		IBOutlet NSButton*		writeControlRegButton;
	    IBOutlet NSTextField*   controlRegNumFifosTextField;
	    IBOutlet NSMatrix*		pixelBusEnableRegMatrix;
	    IBOutlet NSTextField*	pixelBusEnableRegTextField;
		
	    // UDP K-Cmd tab   -----
	    //udp connection
		IBOutlet NSButton*		startUDPCommandConnectionButton;
		IBOutlet NSButton*		stopUDPCommandConnectionButton;
		//listener (server)
	    IBOutlet NSTextField*   crateUDPReplyPortTextField;
		IBOutlet NSButton*		startListeningForReplyButton;
		IBOutlet NSButton*		stopListeningForReplyButton;
	    IBOutlet NSProgressIndicator*   listeningForReplyIndicator;
		//command sender (client)
		IBOutlet NSButton*		openCommandSocketButton;
		IBOutlet NSButton*		closeCommandSocketButton;
	    IBOutlet   NSTextField* crateUDPCommandTextField;
	    IBOutlet NSTextField*   crateUDPCommandIPTextField;
	    IBOutlet NSTextField*   crateUDPCommandPortTextField;
	    IBOutlet NSProgressIndicator*   openCommandSocketIndicator;


	    // UDP Data Packet reader tab -----
		//(P) command sender (client)
	    IBOutlet   NSTextField* crateUDPDataIPTextField;
	    IBOutlet   NSTextField* crateUDPDataPortTextField;
	      IBOutlet   NSPopUpButton* fifoForUDPDataPortPU;
	      IBOutlet   NSButton* useStandardUDPDataPortsCB;
		IBOutlet NSButton*		openDataCommandSocketButton;
		IBOutlet NSButton*		closeDataCommandSocketButton;
	    IBOutlet NSProgressIndicator*   openDataCommandSocketIndicator;
		//listener (server)
	    IBOutlet   NSTextField* crateUDPDataReplyPortTextField;
		IBOutlet NSButton*		startListeningForDataReplyButton;
		IBOutlet NSButton*		stopListeningForDataReplyButton;
	    IBOutlet NSProgressIndicator*   listeningForDataReplyIndicator;
		
		
		IBOutlet NSTextField*	hwVersionField;
		IBOutlet NSTextField*	sltScriptArgumentsTextField;
		IBOutlet NSMatrix*		countersMatrix;
		IBOutlet NSButton*		hwVersionButton;
	
		//control reg
		IBOutlet NSMatrix*		testPatternEnableMatrix;
		IBOutlet NSMatrix*		miscCntrlBitsMatrix;
	
		IBOutlet NSButton*		initBoardButton;
		IBOutlet NSButton*		initBoard1Button;
		IBOutlet NSButton*		readBoardButton;
		IBOutlet NSMatrix*		interruptMaskMatrix;
		IBOutlet NSPopUpButton* secStrobeSrcPU;
		IBOutlet NSTextField*   pageSizeField;
		IBOutlet NSStepper*     pageSizeStepper;
		IBOutlet NSButton*      displayTriggerButton;
		IBOutlet NSButton*      displayEventLoopButton;
		
		//status reg
		IBOutlet NSMatrix*		statusMatrix;
		IBOutlet NSButton*		resetPageManagerButton;
        
        //low level
		IBOutlet NSPopUpButton*	registerPopUp;
		IBOutlet NSStepper* 	regWriteValueStepper;
		IBOutlet NSTextField* 	regWriteValueTextField;
		IBOutlet NSFormatter* 	regWriteValueTextFieldFormatter;
	    IBOutlet NSPopUpButton* lowLevelRegInHexPU;
		IBOutlet NSButton*		regWriteButton;
		IBOutlet NSButton*		regReadButton;
		//IBOutlet NSPopUpButton*	indexPopUp;
	    IBOutlet NSPopUpButton* selectedFifoIndexPU;
		IBOutlet NSButton*		setSWInhibitButton;
		IBOutlet NSButton*		relSWInhibitButton;
		IBOutlet NSButton*		forceTriggerButton;
		IBOutlet NSButton*		setSWInhibit1Button;
		IBOutlet NSButton*		relSWInhibit1Button;
		IBOutlet NSButton*		forceTrigger1Button;

		IBOutlet NSButton*		resetHWButton;
		IBOutlet NSButton*		definePatternFileButton;
		IBOutlet NSTextField*	patternFilePathField;
		IBOutlet NSButton*		loadPatternFileButton;

		IBOutlet NSSlider*		nextPageDelaySlider;
		IBOutlet NSTextField*	nextPageDelayField;
		
		//pulser
		IBOutlet NSTextField*	pulserAmpField;
		IBOutlet NSTextField*	pulserDelayField;


        IBOutlet NSPopUpButton*	pollRatePopup;
        IBOutlet NSProgressIndicator*	pollRunningIndicator;
				
		NSImage* xImage;
		NSImage* yImage;

		NSSize					controlSize;
		NSSize					statusSize;
		NSSize					lowLevelSize;
		NSSize					cpuManagementSize;
		NSSize					cpuTestsSize;
		NSSize					udpKCmdSize;
		NSSize					streamingSize;
		NSSize					udpDReadSize;
};

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Notifications
- (void) registerNotificationObservers;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Interface Management
- (void) saveIonChanFilterOutputRecordsChanged:(NSNotification*)aNote;
- (void) fifoForUDPDataPortChanged:(NSNotification*)aNote;
- (void) useStandardUDPDataPortsChanged:(NSNotification*)aNote;
- (void) resetEventCounterAtRunStartChanged:(NSNotification*)aNote;
- (void) lowLevelRegInHexChanged:(NSNotification*)aNote;
- (void) statusHighRegChanged:(NSNotification*)aNote;
- (void) statusLowRegChanged:(NSNotification*)aNote;
- (void) takeADCChannelDataChanged:(NSNotification*)aNote;
- (void) takeRawUDPDataChanged:(NSNotification*)aNote;
- (void) chargeBBFileChanged:(NSNotification*)aNote;
- (void) useBroadcastIdBBChanged:(NSNotification*)aNote;
- (void) idBBforWCommandChanged:(NSNotification*)aNote;
- (void) takeEventDataChanged:(NSNotification*)aNote;
- (void) takeUDPstreamDataChanged:(NSNotification*)aNote;
- (void) crateUDPDataCommandChanged:(NSNotification*)aNote;
- (void) BBCmdFFMaskChanged:(NSNotification*)aNote;
- (void) cmdWArg4Changed:(NSNotification*)aNote;
- (void) cmdWArg3Changed:(NSNotification*)aNote;
- (void) cmdWArg2Changed:(NSNotification*)aNote;
- (void) cmdWArg1Changed:(NSNotification*)aNote;
- (void) sltDAQModeChanged:(NSNotification*)aNote;
- (void) numRequestedUDPPacketsChanged:(NSNotification*)aNote;
- (void) crateUDPDataReplyPortChanged:(NSNotification*)aNote;
- (void) crateUDPDataIPChanged:(NSNotification*)aNote;
- (void) crateUDPDataPortChanged:(NSNotification*)aNote;
- (void) eventFifoStatusRegChanged:(NSNotification*)aNote;
- (void) pixelBusEnableRegChanged:(NSNotification*)aNote;
- (void) selectedFifoIndexChanged:(NSNotification*)aNote;
- (void) isListeningOnServerSocketChanged:(NSNotification*)aNote;
- (void) isListeningOnDataServerSocketChanged:(NSNotification*)aNote;
- (void) crateUDPCommandChanged:(NSNotification*)aNote;
- (void) crateUDPCommandIPChanged:(NSNotification*)aNote;
- (void) crateUDPCommandPortChanged:(NSNotification*)aNote;
- (void) openCommandSocketChanged:(NSNotification*)aNote;
- (void) openDataCommandSocketChanged:(NSNotification*)aNote;
- (void) crateUDPReplyPortChanged:(NSNotification*)aNote;
- (void) sltScriptArgumentsChanged:(NSNotification*)aNote;
- (void) clockTimeChanged:(NSNotification*)aNote;
- (void) statusRegChanged:(NSNotification*)aNote;
- (void) controlRegChanged:(NSNotification*)aNote;
- (void) hwVersionChanged:(NSNotification*) aNote;

- (void) patternFilePathChanged:(NSNotification*)aNote;
- (void) interruptMaskChanged:(NSNotification*)aNote;
- (void) nextPageDelayChanged:(NSNotification*)aNote;
- (void) pageSizeChanged:(NSNotification*)aNote;
- (void) displayEventLoopChanged:(NSNotification*)aNote;
- (void) displayTriggerChanged:(NSNotification*)aNote;
- (void) populatePullDown;
- (void) updateWindow;
- (void) checkGlobalSecurity;
- (void) settingsLockChanged:(NSNotification*)aNote;

- (void) endAllEditing:(NSNotification*)aNote;
- (void) controlRegChanged:(NSNotification*)aNote;
- (void) selectedRegIndexChanged:(NSNotification*) aNote;
- (void) writeValueChanged:(NSNotification*) aNote;

- (void) pulserAmpChanged:(NSNotification*) aNote;
- (void) pulserDelayChanged:(NSNotification*) aNote;
- (void) pollRateChanged:(NSNotification*)aNote;
- (void) pollRunningChanged:(NSNotification*)aNote;

- (void) enableRegControls;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Actions
- (IBAction) saveIonChanFilterOutputRecordsCBAction:(id)sender;
- (IBAction) fifoForUDPDataPortPUAction:(id)sender;
- (IBAction) useStandardUDPDataPortsCBAction:(id)sender;
- (IBAction) resetEventCounterAtRunStartCBAction:(id)sender;
- (IBAction) lowLevelRegInHexPUAction:(id)sender;
- (IBAction) statusHighRegTextFieldAction:(id)sender;
- (IBAction) statusLowRegTextFieldAction:(id)sender;
- (IBAction) chargeBBFileTextFieldAction:(id)sender;
- (IBAction) useBroadcastIdBBCBAction:(id)sender;
- (IBAction) idBBforWCommandTextFieldAction:(id)sender;
- (IBAction) takeEventDataCBAction:(id)sender;
- (IBAction) takeUDPstreamDataCBAction:(id)sender;
- (IBAction) takeADCChannelDataCBAction:(id)sender;
- (IBAction) takeRawUDPDataCBAction:(id)sender;
- (IBAction) crateUDPDataCommandTextFieldAction:(id)sender;
- (IBAction) BBCmdFFMaskTextFieldAction:(id)sender;
- (IBAction) BBCmdFFMaskMatrixAction:(id)sender;
- (IBAction) cmdWArg4TextFieldAction:(id)sender;
- (IBAction) cmdWArg3TextFieldAction:(id)sender;
- (IBAction) cmdWArg2TextFieldAction:(id)sender;
- (IBAction) cmdWArg1TextFieldAction:(id)sender;
- (IBAction) sltDAQModePUAction:(id)sender;
- (IBAction) sltDAQModeTextFieldAction:(id)sender;
- (IBAction) readAllControlSettingsFromHWButtonAction:(id)sender;

- (IBAction) eventFifoStatusRegTextFieldAction:(id)sender;
- (IBAction) pixelBusEnableRegTextFieldAction:(id)sender;
- (IBAction) pixelBusEnableRegMatrixAction:(id)sender;
- (IBAction) writePixelBusEnableRegButtonAction:(id)sender;
- (IBAction) readPixelBusEnableRegButtonAction:(id)sender;
- (IBAction) writeControlRegButtonAction:(id)sender;
- (IBAction) readControlRegButtonAction:(id)sender;


- (IBAction) selectedFifoIndexPUAction:(id)sender;

//ADC data UDP connection
- (IBAction) startUDPDataConnectionButtonAction:(id)sender;
- (IBAction) stopUDPDataConnectionButtonAction:(id)sender;
- (IBAction) crateUDPDataReplyPortTextFieldAction:(id)sender;
- (IBAction) crateUDPDataIPTextFieldAction:(id)sender;
- (IBAction) crateUDPDataPortTextFieldAction:(id)sender;
- (IBAction) openDataCommandSocketButtonAction:(id)sender;
- (IBAction) closeDataCommandSocketButtonAction:(id)sender;
- (IBAction) startListeningForDataReplyButtonAction:(id)sender;
- (IBAction) stopListeningForDataReplyButtonAction:(id)sender;
- (IBAction) crateUDPDataRequestDataPCommandSendButtonAction:(id)sender;
- (IBAction) crateUDPDataChargeBBFileCommandSendButtonAction:(id)sender;
- (IBAction) numRequestedUDPPacketsTextFieldAction:(id)sender;
- (IBAction) testUDPDataConnectionButtonAction:(id)sender;
- (IBAction) crateUDPDataSendWCommandButtonAction:(id)sender;//send BB Command

- (IBAction) sendUDPDataTab0x0ACommandAction:(id)sender;//send 0x0A Command
- (IBAction) UDPDataTabSendBloqueCommandButtonAction:(id)sender;
- (IBAction) UDPDataTabSendDebloqueCommandButtonAction:(id)sender;
- (IBAction) UDPDataTabSendDemarrageCommandButtonAction:(id)sender;

- (IBAction) crateUDPDataCommandSendButtonAction:(id)sender;


//K command UDP connection
- (IBAction) stopUDPCommandConnectionButtonAction:(id)sender;
- (IBAction) startUDPCommandConnectionButtonAction:(id)sender;
- (IBAction) startListeningForReplyButtonAction:(id)sender;
- (IBAction) stopListeningForReplyButtonAction:(id)sender;
- (IBAction) crateUDPReplyPortTextFieldAction:(id)sender;

- (IBAction) crateUDPCommandSendButtonAction:(id)sender;
- (IBAction) crateUDPCommandTextFieldAction:(id)sender;
- (IBAction) crateUDPCommandIPTextFieldAction:(id)sender;
- (IBAction) crateUDPCommandPortTextFieldAction:(id)sender;
- (IBAction) openCommandSocketButtonAction:(id)sender;
- (IBAction) closeCommandSocketButtonAction:(id)sender;

- (IBAction) sltScriptArgumentsTextFieldAction:(id)sender;
- (IBAction) miscCntrlBitsAction:(id)sender;
- (IBAction) hwVersionAction: (id) sender;

- (IBAction) dumpPageStatus:(id)sender;
- (IBAction) pollRateAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;
- (IBAction) readStatus:(id)sender;
- (IBAction) nextPageDelayAction:(id)sender;
- (IBAction) interruptMaskAction:(id)sender;
- (IBAction) pageSizeAction:(id)sender;
- (IBAction) displayTriggerAction:(id)sender;
- (IBAction) displayEventLoopAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) selectRegisterAction:(id) sender;
- (IBAction) writeValueAction:(id) sender;
- (IBAction) readRegAction: (id) sender;
- (IBAction) writeRegAction: (id) sender;
- (IBAction) pulserAmpAction: (id) sender;
- (IBAction) pulserDelayAction: (id) sender;
- (IBAction) loadPulserAction: (id) sender;
- (IBAction) initBoardAction:(id)sender;
- (IBAction) reportAllAction:(id)sender;
- (IBAction) definePatternFileAction:(id)sender;
- (IBAction) loadPatternFile:(id)sender;
- (IBAction) calibrateAction:(id)sender;


- (IBAction) configureFPGAsAction:(id)sender;
- (IBAction) resetFLTAction:(id)sender;
- (IBAction) resetSLTAction:(id)sender;
- (IBAction) evResAction:(id)sender;

- (IBAction) installIPE4readerAction:(id)sender;
- (IBAction) installAndCompileIPE4readerAction:(id)sender;
- (IBAction) sendCommandScript:(id)sender;
- (IBAction) sendSimulationConfigScriptON:(id)sender;
- (IBAction) sendSimulationConfigScriptOFF:(id)sender;
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _SLTv4killCrateAndStartSimDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
@end
