//
//  ORHPPulserController.m
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORHPPulserController.h"
#import "ORHPPulserModel.h"
#import "ORPlot.h"
#import "ORAxis.h"
#import "ORCompositePlotView.h"

@interface ORHPPulserController (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
- (void) systemTest;

@end

@implementation ORHPPulserController
- (id) init
{
    self = [ super initWithWindowNibName: @"HPPulser" ];
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[[plotter yAxis] setRngLimitsLow:-1 withHigh:1 withMinRng:2];
	[plotter setShowGrid:NO];
	ORPlot* aPlot;
	aPlot= [[ORPlot alloc] initWithTag:0 andDataSource:self];
	[plotter addPlot: aPlot];
	[aPlot release];
}


- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(triggerModeChanged:)
                         name : ORHPPulserTriggerModeChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(frequencyChanged:)
                         name : ORHPPulserFrequencyChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(burstPhaseChanged:)
                         name : ORHPPulserBurstPhaseChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(burstCyclesChanged:)
                         name : ORHPPulserBurstCyclesChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(voltageChanged:)
                         name : ORHPPulserVoltageChangedNotification
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(voltageOffsetChanged:)
                         name : ORHPPulserVoltageOffsetChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(burstRateChanged:)
                         name : ORHPPulserBurstRateChangedNotification
                       object : model];
    
	/*    [notifyCenter addObserver : self
	 selector : @selector(totalWidthChanged:)
	 name : ORHPPulserTotalWidthChangedNotification
	 object : model];*/
    
    
    [notifyCenter addObserver : self
                     selector : @selector(selectedWaveformChanged:)
                         name : ORHPPulserSelectedWaveformChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORHPPulserFrequencyChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORHPPulserBurstCyclesChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORHPPulserBurstPhaseChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORHPPulserVoltageChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORHPPulserVoltageOffsetChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORHPPulserBurstRateChangedNotification
                       object : model];
    
	/*    [notifyCenter addObserver : self
	 selector : @selector(loadConstantsChanged:)
	 name : ORHPPulserTotalWidthChangedNotification
	 object : model];*/
    
    
    [notifyCenter addObserver : self
                     selector : @selector(loadConstantsChanged:)
                         name : ORHPPulserSelectedWaveformChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(waveformLoadStarted:)
                         name : ORHPPulserWaveformLoadStartedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(waveformLoadProgressing:)
                         name : ORHPPulserWaveformLoadProgressingNotification
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(waveformLoadFinished:)
                         name : ORHPPulserWaveformLoadFinishedNotification
                       object : model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( lockChanged: )
                          name: ORRunStatusChangedNotification
                        object: nil];
    
    [ notifyCenter addObserver: self
                      selector: @selector( nonVolatileChanged: )
                          name: ORHPPulserWaveformLoadingNonVoltileNotification
                        object: model];
    
    [ notifyCenter addObserver: self
                      selector: @selector( volatileChanged: )
                          name: ORHPPulserWaveformLoadingVoltileNotification
                        object: model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : [model dialogLock]
                        object: nil];
    
	
	[notifyCenter addObserver : self
					  selector: @selector(enableRandomChanged:)
						  name: ORHPPulserEnableRandomChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(minTimeChanged:)
						  name: ORHPPulserMinTimeChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(maxTimeChanged:)
						  name: ORHPPulserMaxTimeChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(randomCountChanged:)
						  name: ORHPPulserRandomCountChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(lockChanged:)
						  name: ORHPPulserModelLockGUIChanged
					   object : model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(negativePulseChanged:)
                         name : ORHPPulserModelNegativePulseChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(verboseChanged:)
                         name : ORHPPulserModelVerboseChanged
						object: model];

}

- (void) updateWindow
{
    [ super updateWindow ];
    
    [self voltageChanged:nil];
    [self frequencyChanged:nil];
    [self voltageOffsetChanged:nil];
    [self burstRateChanged:nil];
    [self burstPhaseChanged:nil];
    [self burstCyclesChanged:nil];
	//    [self totalWidthChanged:nil];
    [self selectedWaveformChanged:nil];
    [self loadConstantsChanged:nil];
    [self lockChanged:nil];
    [self enableRandomChanged:nil];
    [self minTimeChanged:nil];
    [self maxTimeChanged:nil];
    [self randomCountChanged:nil];
    [self triggerModeChanged:nil];
    [self negativePulseChanged:nil];
	[self verboseChanged:nil];
}

- (void) verboseChanged:(NSNotification*)aNote
{
	[verboseCB setIntValue:[model verbose]];
}

- (void) negativePulseChanged:(NSNotification*)aNote
{
	[negativePulseMatrix selectCellWithTag:[model negativePulse]];
}


#pragma mark •••Actions

- (IBAction) verboseAction:(id)sender;
{
	[model setVerbose:[sender intValue]];
}

- (IBAction) negativePulseAction:(id)sender
{
	if([[sender selectedCell] tag] != [model negativePulse]){
		[model setNegativePulse:[[sender selectedCell] tag]];
	}
}

- (IBAction) sendCommandAction:(id)sender
{
	@try {
		[self endEditing];
		NSString* cmd = [commandField stringValue];
		if(cmd){
			if([cmd rangeOfString:@"?"].location != NSNotFound){
				char reply[1024];
				long n = [model writeReadGPIBDevice:cmd data:reply maxLength:1024];
				if(n>0)reply[n-1]='\0';
				NSLog(@"%s\n",reply);
			}
			else {
				[model writeToGPIBDevice:[commandField stringValue]];
			}
		}
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
 		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
	
}

- (IBAction) clearMemory:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Clear Pulser Non-Volatile Memory"];
    [alert setInformativeText:@"Really Clear the Non-Volatile Memory in Pulser?"];
    [alert addButtonWithTitle:@"YES/Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if(result == NSAlertFirstButtonReturn){
            @try {
                [model emptyVolatileMemory];
            }
            @catch(NSException* localException) {
                NSLog( [ localException reason ] );
                ORRunAlertPanel( [ localException name ], 	// Name of panel
                                @"%@",	// Reason for error
                                @"OK",	// Okay button
                                nil,	// alternate button
                                nil,    // other button
                                [localException reason ]);
            }
        }

    }];
#else
    NSBeginAlertSheet(@"Clear Pulser Non-Volatile Memory",
                      @"YES/Do it NOW",
                      @"Canel",
                      nil,[self window],
                      self,
                      @selector(_clearSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,
                      @"Really Clear the Non-Volatile Memory in Pulser?");
#endif
    
}


-(IBAction) readIdAction:(id)sender
{
	@try {
		NSLog(@"Pulser Id: %@\n",[model readIDString]);
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
 		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

-(IBAction) resetAction:(id)sender
{
	@try {
	    [model resetAndClear];
	    NSLog(@"HPPulser Reset and Clear successful.\n");
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

-(IBAction) testAction:(id)sender
{
	NSLog(@"Testing HP Pulser (takes a few seconds...).\n");
	[self performSelector:@selector(systemTest) withObject:nil afterDelay:0];
}


-(IBAction) loadParamsAction:(id)sender
{
    [self endEditing];
	@try {
		[model outputWaveformParams];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}


-(IBAction) downloadWaveformAction:(id)sender
{
    if([model selectedWaveform] == kWaveformFromFile){
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setCanChooseFiles:YES];
        [openPanel setAllowsMultipleSelection:NO];
        [openPanel setPrompt:@"Download"];
        
        [openPanel setDirectoryURL:[NSURL URLWithString:NSHomeDirectory()]];
        [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                NSString* fileName = [[[openPanel URL]path] stringByAbbreviatingWithTildeInPath];
                [model setFileName:fileName];
                [self performSelector:@selector(downloadWaveform) withObject:self afterDelay:0.1];
                NSLog(@"Downloading Waveform: %@\n",fileName);
           }
        }];
    }
    else {
		[self downloadWaveform];
		NSLog(@"Downloading Waveform: %@\n",[selectionPopUpButton titleOfSelectedItem]);
    }
}

-(void) downloadWaveform
{
    @try {
        [self endEditing];
        
        if(![model loading]){
            [model downloadWaveform];
            [progress setMaxValue:[model numPoints]];
            [progress setDoubleValue:0];
        }
        else {
            [downloadButton setEnabled:NO];
            [model stopDownload];
            [progress setDoubleValue:0];
        }
        
	}
	@catch(NSException* localException) {
		[model stopDownload];
		[progress stopAnimation:self];
		[progress setIndeterminate:NO];
		[progress setDoubleValue:0];
		NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

-(IBAction) triggerModeAction:(id)sender
{
	@try {
		if([[sender selectedCell]tag] != [model triggerSource]){
			[[self undoManager] setActionName: @"Set TriggerMode"];
			[model setTriggerSource:[[sender selectedCell]tag]];	
			[model writeTriggerSource:[model triggerSource]];    
		}
	}
	@catch(NSException* localException) {
		NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
	
}

- (IBAction) triggerAction:(id)sender
{
	@try {
		[model trigger];
	}
	@catch(NSException* localException) {
		NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

-(IBAction) setFrequencyAction:(id)sender
{
    if([sender floatValue] != [model frequency]){
        [[self undoManager] setActionName: @"Set Frequency"];
        [model setFrequency:[sender floatValue]];		
    }
	
}

-(IBAction) setVoltageAction:(id)sender
{
    if([sender intValue] != [model voltage]){
        [[self undoManager] setActionName: @"Set Voltage"];
        [model setVoltage:[sender intValue]];		
    }
	
}

-(IBAction) setVoltageOffsetAction:(id)sender
{
    if([sender floatValue] != [model voltageOffset]){
        [[self undoManager] setActionName: @"Set Voltage Offset"];
        [model setVoltageOffset:[sender floatValue]];		
    }
	
}

-(IBAction) setBurstPhaseAction:(id)sender
{
    if([sender intValue] != [model burstPhase]){
        [[self undoManager] setActionName: @"Set Burst Phase"];
        [model setBurstPhase:[sender intValue]];		
    }
}

-(IBAction) setBurstCyclesAction:(id)sender
{
    if([sender intValue] != [model burstCycles]){
        [[self undoManager] setActionName: @"Set Burst Cycles"];
        [model setBurstCycles:[sender intValue]];		
    }
}

-(IBAction) setBurstRateAction:(id)sender
{
    if([sender floatValue] != [model burstRate]){
        [[self undoManager] setActionName: @"Set Burst Rate"];
        [model setBurstRate:[sender floatValue]];		
    }
}

/*-(IBAction) setTotalWidthAction:(id)sender
 {
 if([sender floatValue] != [model totalWidth]){
 [[self undoManager] setActionName: @"Set Total Width"];
 [model setTotalWidth:[sender floatValue]];		
 }
 }*/

-(IBAction) selectWaveformAction:(id)sender;
{
    if([sender indexOfSelectedItem] != [model selectedWaveform]){ 	
        [[self undoManager] setActionName: @"Selected Waveform"];
        [model setSelectedWaveform:[selectionPopUpButton indexOfSelectedItem]];
    }
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:[model dialogLock] to:[sender intValue] forWindow:[self window]];
}

- (IBAction) enableRandomAction:(id)sender
{
	[model setEnableRandom:[sender state]];
}

- (IBAction) minTimeAction:(id)sender
{
	[model setMinTime:[sender floatValue]];
}

- (IBAction) maxTimeAction:(id)sender
{
	[model setMaxTime:[sender floatValue]];
}


#pragma mark •••Notifications

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:[model dialogLock] to:secure];
    
    [lockButton setEnabled:secure];
}

- (void) lockChanged: (NSNotification*) aNotification
{
	[self setButtonStates];
}

- (void) primaryAddressChanged:(NSNotification*)aNotification
{
	[super primaryAddressChanged:aNotification];
	[[self window] setTitle:[model title]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
    if(aModel){
        [[self window] setTitle:[model title]];
    }
}


- (void) triggerModeChanged:(NSNotification*)aNotification
{
	[triggerModeMatrix selectCellWithTag: [model triggerSource]];
	[self setButtonStates];
	//[model writeTriggerSource:[model triggerSource]];
}

- (void) frequencyChanged:(NSNotification*)aNotification
{
	[self updateStepper:frequencyStepper setting:[model frequency]];
	[frequencyField setFloatValue: [model frequency]];
}

- (void) voltageChanged:(NSNotification*)aNotification
{
	[self updateStepper:voltageStepper setting:[model voltage]];
	[voltageField setIntValue: [model voltage]];
}

- (void) voltageOffsetChanged:(NSNotification*)aNotification
{
	[self updateStepper:voltageOffsetStepper setting:[model voltageOffset]];
	[voltageOffsetField setFloatValue: [model voltageOffset]];
}

- (void) burstCyclesChanged:(NSNotification*)aNotification
{
	[self updateStepper:burstCyclesStepper setting:[model burstCycles]];
	[burstCyclesField setIntValue: [model burstCycles]];
}

- (void) burstPhaseChanged:(NSNotification*)aNotification
{
	[self updateStepper:burstPhaseStepper setting:[model burstPhase]];
	[burstPhaseField setIntValue: [model burstPhase]];
}

- (void) burstRateChanged:(NSNotification*)aNotification
{
	[self updateStepper:burstRateStepper setting:[model burstRate]];
	[burstRateField setFloatValue: [model burstRate]];
}

/*- (void) totalWidthChanged:(NSNotification*)aNotification
 {
 [self updateStepper:totalWidthStepper setting:[model totalWidth]];
 [totalWidthField setFloatValue: [model totalWidth]];
 }*/

- (void) selectedWaveformChanged:(NSNotification*)aNotification
{
	[selectionPopUpButton selectItemAtIndex:[model selectedWaveform]];
    [self setButtonStates];
}

- (void) volatileChanged:(NSNotification*)aNotification
{
	[progress setIndeterminate:NO];
	[progress setDoubleValue:0];
	[downloadTypeField setStringValue:@""];
}

- (void) nonVolatileChanged:(NSNotification*)aNotification
{
	[progress setIndeterminate:YES];
	[progress startAnimation:self];
	[downloadTypeField setStringValue:@"In NonVol. Mem."];
}

- (void) loadConstantsChanged:(NSNotification*)aNotification
{
	if([model selectedWaveform] == kLogCalibrationWaveform){
		[voltageDisplay setFloatValue:kCalibrationVoltage];
		//[totalWidthDisplay setFloatValue:kCalibrationWidth];
		[burstRateDisplay setFloatValue:kCalibrationBurstRate];
	}
	else {
		[voltageDisplay setFloatValue:[model voltage]];
		//[totalWidthDisplay setFloatValue:[model totalWidth]];
		[burstRateDisplay setFloatValue:[model burstRate]];
	}
}

- (void) enableRandomChanged:(NSNotification*)aNote
{
	[enableRandomButton setState:[model enableRandom]];
}

- (void) minTimeChanged:(NSNotification*)aNote
{
	[minTimeField setFloatValue:[model minTime]];
	[minTimeStepper setFloatValue:[model minTime]];
}

- (void) maxTimeChanged:(NSNotification*)aNote
{
	[maxTimeField setFloatValue:[model maxTime]];
	[maxTimeStepper setFloatValue:[model maxTime]];
}

- (void) randomCountChanged:(NSNotification*)aNote
{
	[randomCountField setIntValue:[model randomCount]];
}


- (void) waveformLoadStarted:(NSNotification*)aNotification
{        
	[self setButtonStates];
	
	int mx = [model numPoints];
	
	[[plotter yAxis] setRngLimitsLow:-1 withHigh:1 withMinRng:2];
	[[plotter yAxis] setRngLow:-1 withHigh:1];
	//[[plotter yAxis] setFullRng];
	
	[[plotter xAxis] setRngLimitsLow:0 withHigh:mx withMinRng:mx];
	[[plotter xAxis] setRngLow:0 withHigh:mx];
	//[[plotter xAxis] setFullRng];
	
	
	[[plotter yAxis] setNeedsDisplay:YES];
	[[plotter xAxis] setNeedsDisplay:YES];
	[plotter setNeedsDisplay:YES];
}

- (void) waveformLoadProgressing:(NSNotification*)aNotification
{
	[progress setDoubleValue:[model downloadIndex]]; 
}

- (void) waveformLoadFinished:(NSNotification*)aNotification
{	
	[self setButtonStates];
	
	[progress setIndeterminate:NO];
	[progress stopAnimation:self];
	[progress setMaxValue:100];
	[progress setDoubleValue:0];
}


- (int) numberPointsInPlot:(id)aPlotter
{
    return [model numPoints];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
    float* d = (float*)[[model waveform] mutableBytes];
    *yValue = (double)d[i];
	*xValue = i;
}

- (void) setButtonStates
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model dialogLock]];
    BOOL loading					= [model loading];
	BOOL runInProgress				= [gOrcaGlobals runInProgress];
	BOOL locked						= [gSecurity isLocked:[model dialogLock]];
    BOOL triggerModeIsSoftware		= [model triggerSource] == kSoftwareTrigger;
	locked |= [model lockGUI];
	
    [downloadButton setTitle: loading ? @"Stop":@"Load"];
	
	[[plotter yAxis] setNeedsDisplay:YES];
	[[plotter xAxis] setNeedsDisplay:YES];
	[plotter setNeedsDisplay:YES];
    
    
	[downloadButton setEnabled: ![model loading] &&
                                ![model lockGUI] &&
                                ([model selectedWaveform]!= kWaveformFromScript)];
	
	[downloadTypeField setStringValue:@""];
		
    [enableRandomButton setEnabled: !locked && triggerModeIsSoftware];	
    [minTimeField setEnabled: !locked && triggerModeIsSoftware];	
    [maxTimeField setEnabled: !locked && triggerModeIsSoftware];	
    [minTimeStepper setEnabled: !locked && triggerModeIsSoftware];	
    [maxTimeStepper setEnabled: !locked && triggerModeIsSoftware];	
	
    [negativePulseMatrix setEnabled:!loading &&
                                    !locked  &&
                                    ([model selectedWaveform]!= kWaveformFromScript)];
    [mPrimaryAddress setEnabled:!loading && !locked];
    [mConnectButton setEnabled:!loading && !locked];
    [readIdButton setEnabled:!loading && !locked];
    [resetButton setEnabled:!loading && !locked];
    [testButton setEnabled:!loading && !locked];
    [clearButton setEnabled:!loading && !locked];
    [selectionPopUpButton setEnabled:!loading && !locked];
    [voltageField setEnabled:!loading && !locked];
    [frequencyField setEnabled:!loading && !locked];
    [voltageStepper setEnabled:!loading && !locked];
    [frequencyStepper setEnabled:!loading && !locked];
    [voltageOffsetField setEnabled:!loading && !locked];
    [voltageOffsetStepper setEnabled:!loading && !locked];
    [burstRateField setEnabled:!loading && !locked];
    [burstRateStepper setEnabled:!loading && !locked];
    [burstCyclesField setEnabled:!loading && !locked];
    [burstCyclesStepper setEnabled:!loading && !locked];
    [burstPhaseField setEnabled:!loading && !locked];
    [burstPhaseStepper setEnabled:!loading && !locked];
    [triggerModeMatrix setEnabled:!locked && !loading];
    [triggerButton setEnabled:!locked && !loading && triggerModeIsSoftware];
    [loadParamsButton setEnabled:!locked && !loading];
    [sendCommandButton setEnabled:!locked && !loading];
    [commandField setEnabled:!locked && !loading];
    
    NSString* s = @"";
	if([model lockGUI]){
		s = @"Locked by other object";
	}
    else if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:[model dialogLock]])s = @"Not in Maintenance Run.";
    }
    [lockDocField setStringValue:s];
	
}

- (void) populatePullDownsGpibDevice
{
    [super populatePullDownsGpibDevice];
    int i;
    [selectionPopUpButton removeAllItems];
    for(i=0;i<[model numberOfWaveforms];i++) {
        [selectionPopUpButton addItemWithTitle:[model nameOfWaveformAt:i]];
    }
}

@end

@implementation ORHPPulserController (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertDefaultReturn){
		@try {
			[model emptyVolatileMemory];
		}
		@catch(NSException* localException) {
			NSLog( [ localException reason ] );
            ORRunAlertPanel( [ localException name ], 	// Name of panel
                            @"%@",	// Reason for error
                            @"OK",	// Okay button
                            nil,	// alternate button
                            nil,    // other button
                            [localException reason ]);
		}
    }
}
#endif
- (void) systemTest
{
	@try {
	    [model systemTest];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}
@end
