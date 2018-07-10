
//
//  ORAmptekDP5Controller.h
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


#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Imported Files
#import "ORAmptekDP5Model.h"
//#import "SBC_LinkController.h"
@class ORValueBarGroupView;


@interface ORAmptekDP5Controller : OrcaObjectController {
    // status table view
	IBOutlet   NSTextField* slowCounterTextField;
	IBOutlet   NSTextField* serialNumberTextField;
	IBOutlet   NSTextField* FirmwareFPGAVersionTextField;
	IBOutlet   NSTextField* detectorTemperatureTextField;
	IBOutlet   NSTextField* deviceIDTextField;
	IBOutlet   NSTextField* boardTemperatureTextField;
	IBOutlet   NSTextField* fastCounterTextField;
	IBOutlet   NSTextField* realTimeTextField;
	IBOutlet   NSTextField* acquisitionTimeTextField;
    // command table view
	IBOutlet NSTableView*			commandTableView;
	IBOutlet NSButton*              dropFirstSpectrumCB;
	IBOutlet NSButton*              autoReadbackSetpointCB;
    IBOutlet ORValueBarGroupView*   commandQueueValueBar;
    IBOutlet   NSTextField*         commandQueueCountField;

	IBOutlet NSTabView*				tabView;
	IBOutlet NSPopUpButton*         spectrumRequestRatePU;
    IBOutlet NSProgressIndicator*   isPollingSpectrumIndicator;
    
    //AmpTek DP5
	IBOutlet   NSPopUpButton* spectrumRequestTypePU;
	IBOutlet   NSPopUpButton* numSpectrumBinsPU;
	IBOutlet   NSTextField* textCommandTextField;
    
	@private
	
    //BB commands
//TODO: rm   slt - -    IBOutlet   NSTextField* eventFifoStatusRegTextField;
	IBOutlet   NSButton* resetEventCounterAtRunStartCB;
	IBOutlet   NSTextField* statusHighRegTextField;
	IBOutlet   NSTextField* statusLowRegTextField;
//TODO: rm   slt - - 	IBOutlet   NSButton* useBroadcastIdBBCB;
//TODO: rm   slt - - 	IBOutlet   NSTextField* idBBforWCommandTextField;
//TODO: rm   slt - - 	IBOutlet   NSTextField* crateUDPDataCommandTextField;
//TODO: rm   slt - - 	IBOutlet   NSTextField* BBCmdFFMaskTextField;
//TODO: rm   slt - -     IBOutlet   NSMatrix*		BBCmdFFMaskMatrix;
//TODO: rm   slt - - 	IBOutlet   NSTextField* cmdWArg4TextField;
//TODO: rm   slt - - 	IBOutlet   NSTextField* cmdWArg3TextField;
//TODO: rm   slt - - 	IBOutlet   NSTextField* cmdWArg2TextField;
//TODO: rm   slt - - 	IBOutlet   NSTextField* cmdWArg1TextField;
    
        //DAQ mode
	    IBOutlet   NSTextField* sltDAQModeTextField;
		IBOutlet NSPopUpButton* sltDAQModePU;
//TODO: rm   slt - - 	IBOutlet   NSButton* takeEventDataCB;
//TODO: rm   slt - - 	IBOutlet   NSButton* takeUDPstreamDataCB;
	IBOutlet   NSButton* takeADCChannelDataCB;
	IBOutlet   NSButton* takeRawUDPDataCB;
        
        //UDP Data tab ----
//TODO: rm   slt - - 	IBOutlet   NSTextField* numRequestedUDPPacketsTextField;
//TODO: rm   slt - - 	IBOutlet   NSTextField* chargeBBFileTextField;
    
        //control reg tab
		IBOutlet NSButton*		writeControlRegButton;
	    IBOutlet NSTextField*   controlRegNumFifosTextField;
//TODO: rm   slt - -	    IBOutlet NSMatrix*		pixelBusEnableRegMatrix;
//TODO: rm   slt - -	    IBOutlet NSTextField*	pixelBusEnableRegTextField;
		
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
        IBOutlet NSTextField*   openCommandSocketTextField;


	    // UDP Data Packet reader tab -----
		//(P) command sender (client)
        #if 0
        //removed - remained from SLT
	    IBOutlet   NSTextField* crateUDPDataIPTextField;
	    IBOutlet   NSTextField* crateUDPDataPortTextField;
		IBOutlet NSButton*		openDataCommandSocketButton;
		IBOutlet NSButton*		closeDataCommandSocketButton;
	    IBOutlet NSProgressIndicator*   openDataCommandSocketIndicator;
		//listener (server)
	    IBOutlet   NSTextField* crateUDPDataReplyPortTextField;
		IBOutlet NSButton*		startListeningForDataReplyButton;
		IBOutlet NSButton*		stopListeningForDataReplyButton;
	    IBOutlet NSProgressIndicator*   listeningForDataReplyIndicator;
		#endif
		
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
//TODO: rm   slt 		IBOutlet NSMatrix*		interruptMaskMatrix;
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
//slt - - 	    IBOutlet NSPopUpButton* selectedFifoIndexPU;
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
		NSSize					networkConnectionSize;
		NSSize					testSize;
		NSSize					aboutSize;
};

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;


#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Notifications
- (void) registerNotificationObservers;

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Interface Management
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) FirmwareFPGAVersionChanged:(NSNotification*)aNote;
- (void) detectorTemperatureChanged:(NSNotification*)aNote;
- (void) deviceIDChanged:(NSNotification*)aNote;
- (void) boardTemperatureChanged:(NSNotification*)aNote;
- (void) slowCounterChanged:(NSNotification*)aNote;
- (void) fastCounterChanged:(NSNotification*)aNote;
- (void) realTimeChanged:(NSNotification*)aNote;
- (void) acquisitionTimeChanged:(NSNotification*)aNote;
- (void) dropFirstSpectrumChanged:(NSNotification*)aNote;
- (void) autoReadbackSetpointChanged:(NSNotification*)aNote;

// command table view
- (void) populateCommandTableView;

- (void) commandTableChanged:(NSNotification*)aNote;
- (void) commandQueueCountChanged:(NSNotification*)aNotification;

- (void) isPollingSpectrumChanged:(NSNotification*)aNote;
- (void) spectrumRequestRateChanged:(NSNotification*)aNote;
- (void) spectrumRequestTypeChanged:(NSNotification*)aNote;
- (void) numSpectrumBinsChanged:(NSNotification*)aNote;
- (void) textCommandChanged:(NSNotification*)aNote;
- (void) resetEventCounterAtRunStartChanged:(NSNotification*)aNote;
- (void) lowLevelRegInHexChanged:(NSNotification*)aNote;
- (void) statusHighRegChanged:(NSNotification*)aNote;
- (void) statusLowRegChanged:(NSNotification*)aNote;
- (void) takeADCChannelDataChanged:(NSNotification*)aNote;
- (void) takeRawUDPDataChanged:(NSNotification*)aNote;
//TODO: rm   slt - - - (void) chargeBBFileChanged:(NSNotification*)aNote;
//TODO: rm   slt - - - (void) useBroadcastIdBBChanged:(NSNotification*)aNote;
//TODO: rm   slt - - - (void) idBBforWCommandChanged:(NSNotification*)aNote;
//TODO: rm   slt - - - (void) takeEventDataChanged:(NSNotification*)aNote;
//TODO: rm   slt - - - (void) takeUDPstreamDataChanged:(NSNotification*)aNote;
//TODO: rm   slt - - - (void) crateUDPDataCommandChanged:(NSNotification*)aNote;
//TODO: rm   slt - - - (void) BBCmdFFMaskChanged:(NSNotification*)aNote;
//TODO: rm   slt - - - (void) cmdWArg4Changed:(NSNotification*)aNote;
//TODO: rm   slt - - - (void) cmdWArg3Changed:(NSNotification*)aNote;
//TODO: rm   slt - - - (void) cmdWArg2Changed:(NSNotification*)aNote;
//TODO: rm   slt - - - (void) cmdWArg1Changed:(NSNotification*)aNote;
- (void) sltDAQModeChanged:(NSNotification*)aNote;
//TODO: rm   slt - - - (void) numRequestedUDPPacketsChanged:(NSNotification*)aNote;


//slt - - (void) crateUDPDataReplyPortChanged:(NSNotification*)aNote;
//slt - - (void) crateUDPDataIPChanged:(NSNotification*)aNote;
//slt - - (void) crateUDPDataPortChanged:(NSNotification*)aNote;
//slt - - (void) eventFifoStatusRegChanged:(NSNotification*)aNote;
//slt - - (void) pixelBusEnableRegChanged:(NSNotification*)aNote;
//slt - - (void) selectedFifoIndexChanged:(NSNotification*)aNote;
- (void) isListeningOnServerSocketChanged:(NSNotification*)aNote; 
//slt - - (void) isListeningOnDataServerSocketChanged:(NSNotification*)aNote;
- (void) crateUDPCommandChanged:(NSNotification*)aNote;
- (void) crateUDPCommandIPChanged:(NSNotification*)aNote;
- (void) crateUDPCommandPortChanged:(NSNotification*)aNote;
- (void) openCommandSocketChanged:(NSNotification*)aNote;

//slt - (void) openDataCommandSocketChanged:(NSNotification*)aNote;
//slt - - (void) crateUDPReplyPortChanged:(NSNotification*)aNote;
- (void) sltScriptArgumentsChanged:(NSNotification*)aNote;
- (void) clockTimeChanged:(NSNotification*)aNote;
- (void) statusRegChanged:(NSNotification*)aNote;
- (void) controlRegChanged:(NSNotification*)aNote;
- (void) hwVersionChanged:(NSNotification*) aNote;

- (void) patternFilePathChanged:(NSNotification*)aNote;
//TODO: rm   slt - (void) interruptMaskChanged:(NSNotification*)aNote;
- (void) nextPageDelayChanged:(NSNotification*)aNote;
- (void) pageSizeChanged:(NSNotification*)aNote;
- (void) displayEventLoopChanged:(NSNotification*)aNote;
- (void) displayTriggerChanged:(NSNotification*)aNote;

- (void) populatePullDown;
- (void) updateWindow;
- (void) setWindowTitle;
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

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Actions
- (IBAction) dropFirstSpectrumCBAction:(id)sender;
- (IBAction) autoReadbackSetpointCBAction:(id)sender;
- (IBAction) debugButtonAction:(id)sender;
- (IBAction) clearCommandQueueButtonAction:(id)sender;
- (IBAction) sendCommandOfCommandQueueButtonAction:(id)sender;
- (IBAction) dumpCommandQueueButtonAction:(id)sender;


- (IBAction) readAllCommandSettingsButtonAction:(id)sender;
- (IBAction) writeAllCommandSettingsButtonAction:(id)sender;
- (IBAction) readSelectedCommandSettingButtonAction:(id)sender;
- (IBAction) writeSelectedCommandSettingButtonAction:(id)sender;

- (IBAction) openCommandsFromCSVFileButtonAction:(id)sender;
- (IBAction) saveCommandsAsCSVFileButtonAction:(id)sender;

- (IBAction) spectrumRequestRatePUAction:(id)sender;
- (IBAction) spectrumRequestNowButtonAction:(id)sender;
- (IBAction) spectrumRequestTypePUAction:(id)sender;
- (IBAction) numSpectrumBinsPUAction:(id)sender;
- (IBAction) textCommandTextFieldAction:(id)sender;
- (IBAction) resetEventCounterAtRunStartCBAction:(id)sender;
- (IBAction) lowLevelRegInHexPUAction:(id)sender;
- (IBAction) statusHighRegTextFieldAction:(id)sender;
- (IBAction) statusLowRegTextFieldAction:(id)sender;
//TODO: rm   slt - - - (IBAction) chargeBBFileTextFieldAction:(id)sender;
//TODO: rm   slt - - - (IBAction) useBroadcastIdBBCBAction:(id)sender;
//TODO: rm   slt - - - (IBAction) idBBforWCommandTextFieldAction:(id)sender;
//TODO: rm   slt - - - (IBAction) takeEventDataCBAction:(id)sender;
//TODO: rm   slt - - - (IBAction) takeUDPstreamDataCBAction:(id)sender;
- (IBAction) takeADCChannelDataCBAction:(id)sender;
- (IBAction) takeRawUDPDataCBAction:(id)sender;


- (IBAction) sltDAQModePUAction:(id)sender;
- (IBAction) sltDAQModeTextFieldAction:(id)sender;
- (IBAction) readAllControlSettingsFromHWButtonAction:(id)sender;

//TODO: rm   slt - -- (IBAction) eventFifoStatusRegTextFieldAction:(id)sender;
//slt - - - (IBAction) pixelBusEnableRegTextFieldAction:(id)sender;
//slt - - - (IBAction) pixelBusEnableRegMatrixAction:(id)sender;
//TODO: rm   slt - -- (IBAction) writePixelBusEnableRegButtonAction:(id)sender;
//TODO: rm   slt - -- (IBAction) readPixelBusEnableRegButtonAction:(id)sender;
//TODO: rm   slt - -- (IBAction) writeControlRegButtonAction:(id)sender;
//TODO: rm   slt - -- (IBAction) readControlRegButtonAction:(id)sender;


//slt - - - (IBAction) selectedFifoIndexPUAction:(id)sender;

#if 0
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
//TODO: rm   slt - - - (IBAction) numRequestedUDPPacketsTextFieldAction:(id)sender;
- (IBAction) testUDPDataConnectionButtonAction:(id)sender;
- (IBAction) crateUDPDataSendWCommandButtonAction:(id)sender;//send BB Command

//TODO: rm   slt - - - (IBAction) crateUDPDataCommandTextFieldAction:(id)sender;
//TODO: rm   slt - - - (IBAction) BBCmdFFMaskTextFieldAction:(id)sender;
//TODO: rm   slt - - - (IBAction) BBCmdFFMaskMatrixAction:(id)sender;
//TODO: rm   slt - - - (IBAction) cmdWArg4TextFieldAction:(id)sender;
//TODO: rm   slt - - - (IBAction) cmdWArg3TextFieldAction:(id)sender;
//TODO: rm   slt - - - (IBAction) cmdWArg2TextFieldAction:(id)sender;
//TODO: rm   slt - - - (IBAction) cmdWArg1TextFieldAction:(id)sender;


- (IBAction) sendUDPDataTab0x0ACommandAction:(id)sender;//send 0x0A Command
- (IBAction) UDPDataTabSendBloqueCommandButtonAction:(id)sender;
- (IBAction) UDPDataTabSendDebloqueCommandButtonAction:(id)sender;
- (IBAction) UDPDataTabSendDemarrageCommandButtonAction:(id)sender;   

//TODO: rm   slt - - - (IBAction) crateUDPDataCommandSendButtonAction:(id)sender;


#endif


//K command UDP connection
- (IBAction) stopUDPCommandConnectionButtonAction:(id)sender;
- (IBAction) startUDPCommandConnectionButtonAction:(id)sender;
- (IBAction) startListeningForReplyButtonAction:(id)sender;
- (IBAction) stopListeningForReplyButtonAction:(id)sender;

//slt - (IBAction) crateUDPReplyPortTextFieldAction:(id)sender;

- (IBAction) crateUDPCommandSendButtonAction:(id)sender; //TODO: rename -tb-
- (IBAction) textCommandSendButtonAction:(id)sender; //TODO: rename -tb-
- (IBAction) textCommandReadbackButtonAction:(id)sender; //TODO: rename -tb-
- (IBAction) crateUDPCommandSendBinaryButtonAction:(id)sender;
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
//TODO: rm   slt - (IBAction) interruptMaskAction:(id)sender;
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



#pragma mark •••Data Source Methods (TableView)
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
//- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
//- (BOOL) tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard;
//- (void) dragDone;



@end
