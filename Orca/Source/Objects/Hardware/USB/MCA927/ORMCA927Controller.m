//
//  ORHPMCA927Controller.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 26 2007.
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


#import "ORMCA927Controller.h"
#import "ORMCA927Model.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"
#import "ORAxis.h"
#import "ORCompositePlotView.h"
#import "OR1DHistoPlot.h"

@interface ORMCA927Controller (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) clearSpectaSheetDidEnd:(id)sheet
				  returnCode:(int)returnCode 
				 contextInfo:(NSDictionary*)userInfo;
#endif
- (void) populateInterfacePopup:(ORUSB*)usb;

@end

@implementation ORMCA927Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"MCA927" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceAdded
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceRemoved
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORMCA927ModelSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORMCA927ModelUSBInterfaceChanged
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORMCA927ModelLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(fpgaFilePathChanged:)
                         name : ORMCA927ModelFpgaFilePathChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useCustomFileChanged:)
                         name : ORMCA927ModelUseCustomFileChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(controlRegChanged:)
                         name : ORMCA927ModelControlRegChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(presetCtrlRegChanged:)
                         name : ORMCA927ModelPresetCtrlRegChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ltPresetChanged:)
                         name : ORMCA927ModelLtPresetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(rtPresetChanged:)
                         name : ORMCA927ModelRTPresetChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(roiPresetChanged:)
                         name : ORMCA927ModelRoiPresetChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(roiPeakPresetChanged:)
                         name : ORMCA927ModelRoiPeakPresetChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(statusParamsChanged:)
                         name : ORMCA927ModelStatusParamsChanged
						object: model];
		
	[notifyCenter addObserver : self
                     selector : @selector(liveTimeChanged:)
                         name : ORMCA927ModelLiveTimeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(realTimeChanged:)
                         name : ORMCA927ModelRealTimeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(convGainChanged:)
                         name : ORMCA927ModelConvGainChanged
						object: model];
		
    [notifyCenter addObserver : self
                     selector : @selector(lowerDiscriminatorChanged:)
                         name : ORMCA927ModelLowerDiscriminatorChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(upperDiscriminatorChanged:)
                         name : ORMCA927ModelUpperDiscriminatorChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(selectedChannelChanged:)
                         name : ORMCA927ModelSelectedChannelChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(runningStatusChanged:)
                         name : ORMCA927ModelRunningStatusChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(runOptionsChanged:)
                         name : ORMCA927ModelRunOptionsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(autoClearChanged:)
                         name : ORMCA927ModelAutoClearChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(zdtModeChanged:)
                         name : ORMCA927ModelZdtModeChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(commentChanged:)
                         name : ORMCA927ModelCommentChanged
						object: model];

}

- (void) awakeFromNib
{
	[self populateInterfacePopup:[model getUSBController]];
	[super awakeFromNib];
    [[plotter yAxis] setRngLimitsLow:0 withHigh:5E9 withMinRng:25];
	
	int i;
	for(i=0;i<4;i++){
		OR1DHistoPlot* aPlot;
		aPlot= [[OR1DHistoPlot alloc] initWithTag:i andDataSource:self];
		[plotter addPlot: aPlot];
		[aPlot setLineColor:[self colorForDataSet:i]];		
		[aPlot release];
	}	
}

- (void) updateWindow
{
    [ super updateWindow ];
    
	[self selectedChannelChanged:nil];
	[self serialNumberChanged:nil];
    [self lockChanged:nil];
	[self fpgaFilePathChanged:nil];
	[self useCustomFileChanged:nil];
	[self statusParamsChanged:nil];
	[self updateChannelParams];
	[self runningStatusChanged:nil];
	[self runOptionsChanged:nil];
    [self miscAttributesChanged:nil];
	[self commentChanged:nil];
}

- (void) commentChanged:(NSNotification*)aNote
{
	[commentField setStringValue: [model comment]];
}

- (void) updateChannelParams
{
	[self controlRegChanged:nil];
	[self presetCtrlRegChanged:nil];
	[self ltPresetChanged:nil];
	[self liveTimeChanged:nil];
	[self realTimeChanged:nil];	
	[self rtPresetChanged:nil];
	[self roiPresetChanged:nil];
	[self roiPeakPresetChanged:nil];
	[self convGainChanged:nil];	
	[self zdtModeChanged:nil];
	[self autoClearChanged:nil];
}

//a fake action from the scale object
- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter yAxis]attributes] forKey:@"PlotterYAttributes"];
	}
	else if(aNotification == nil || [aNotification object] == [plotter xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter xAxis]attributes] forKey:@"PlotterXAttributes"];
	}
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"PlotterYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"PlotterYAttributes"];
		if(attrib){
			[(ORAxis*)[plotter yAxis] setAttributes:attrib];
			[plotter setNeedsDisplay:YES];
			[[plotter yAxis] setNeedsDisplay:YES];
			[logCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	else if(aNote == nil || [key isEqualToString:@"PlotterXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"PlotterXAttributes"];
		if(attrib){
			[(ORAxis*)[plotter xAxis] setAttributes:attrib];
			[plotter setNeedsDisplay:YES];
			[[plotter xAxis] setNeedsDisplay:YES];
		}
	}
}

- (void) runOptionsChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<2;i++){
		unsigned long optionsMask = [model runOptions:i];
		[[runOptionsMatrix cellAtRow:0 column:i] setIntValue: (optionsMask&kChannelEnabledMask) != 0];
		[[runOptionsMatrix cellAtRow:1 column:i] setIntValue: (optionsMask&kChannelAutoStopMask) != 0];
	}
}

- (void) runningStatusChanged:(NSNotification*)aNote
{
	[startChannelButton setEnabled:![model runningStatus:[model selectedChannel]] && ![model startedFromMainRunControl:[model selectedChannel]]];
	[stopChannelButton setEnabled:[model runningStatus:[model selectedChannel]]   && ![model startedFromMainRunControl:[model selectedChannel]]];
	[startAllButton setEnabled:(![model runningStatus:0] || ![model runningStatus:1]) ];
	[stopAllButton setEnabled:([model runningStatus:0] || [model runningStatus:1]) ];
}

- (void) selectedChannelChanged:(NSNotification*)aNote
{
	[selectedChannelMatrix selectCellWithTag: [model selectedChannel]];
	[self updateChannelParams];
	[self runningStatusChanged:nil];
}

- (void) autoClearChanged:(NSNotification*)aNote
{
	[autoClearCB setIntValue:[model autoClear:[model selectedChannel]]];
}

- (void) zdtModeChanged:(NSNotification*)aNote
{
	unsigned long zdtMode = [model zdtMode:[model selectedChannel]];
	[zdtSpeedPU selectItemWithTag:zdtMode & kZDTSpeedMask];
	[[zdtModeMatrix cellWithTag:0] setIntValue: (zdtMode & kEnableZDTMask)!=0];
	[[zdtModeMatrix cellWithTag:1] setIntValue: (zdtMode & kZDTModeMask)!=0];
	[self lockChanged:nil];
}

- (void) lowerDiscriminatorChanged:(NSNotification*)aNote
{
	int raw = [model lowerDiscriminator:[model selectedChannel]];
	int n = [model numChannels:[model selectedChannel]];
	[lowerDiscriminatorField setIntValue:raw*n/16384.];	
	[lowerDiscriminatorPercentField setFloatValue:raw/16384.];	
}

- (void) upperDiscriminatorChanged:(NSNotification*)aNote
{
	int raw = [model upperDiscriminator:[model selectedChannel]];
	int n = [model numChannels:[model selectedChannel]];
	[upperDiscriminatorField setIntValue:raw*n/16384.];
	[upperDiscriminatorPercentField setFloatValue:raw/16384.];	
}

- (void) convGainChanged:(NSNotification*)aNote
{
	[convGainPopup selectItemAtIndex:[model convGain:[model selectedChannel]]];
	[self lowerDiscriminatorChanged:nil];
	[self upperDiscriminatorChanged:nil];
}

- (void) rtPresetChanged:(NSNotification*)aNote
{
	[rtPresetField setFloatValue: [model rtPreset:[model selectedChannel]]*0.02];
}

- (void) roiPresetChanged:(NSNotification*)aNote
{
	[roiPresetField setIntValue: [model roiPreset:[model selectedChannel]]];
}

- (void) roiPeakPresetChanged:(NSNotification*)aNote
{
	[roiPeakPresetField setIntValue: [model roiPeakPreset:[model selectedChannel]]];
}

- (void) statusParamsChanged:(NSNotification*)aNote
{
	[[statusParamsMatrix cellAtRow:0 column:0] setObjectValue:[model runningStatus:0]?@"Running":@"--"];
	[[statusParamsMatrix cellAtRow:1 column:0] setFloatValue:[model realTimeStatus:0]*0.02];
	[[statusParamsMatrix cellAtRow:2 column:0] setFloatValue:[model liveTimeStatus:0]*0.02];
	
	
	[[statusParamsMatrix cellAtRow:0 column:1] setObjectValue:[model runningStatus:1]?@"Running":@"--"];
	[[statusParamsMatrix cellAtRow:1 column:1] setFloatValue:[model realTimeStatus:1]*0.02];
	[[statusParamsMatrix cellAtRow:2 column:1] setFloatValue:[model liveTimeStatus:1]*0.02];

	[plotter setNeedsDisplay:YES];

}

- (void) realTimeChanged:(NSNotification*)aNote
{
	[realTimeField setFloatValue: [model realTime:[model selectedChannel]]*0.02];
}

- (void) liveTimeChanged:(NSNotification*)aNote
{
	[liveTimeField setFloatValue: [model liveTime:[model selectedChannel]]*0.02];
}


- (void) ltPresetChanged:(NSNotification*)aNote
{
	[ltPresetField setFloatValue: [model ltPreset:[model selectedChannel]]*0.02];
}

- (void) useCustomFileChanged:(NSNotification*)aNote
{
	[useCustomFileCB setIntValue: [model useCustomFile]];
	[self fpgaFilePathChanged:nil];
	[selectFileButton setEnabled:[model useCustomFile]];
}

- (void) fpgaFilePathChanged:(NSNotification*)aNote
{
	NSString* filePath;
	if(![model useCustomFile]) filePath = @"--ORCA copy--";
	else {
		if([[model fpgaFilePath] length]) filePath = [[model fpgaFilePath] stringByAbbreviatingWithTildeInPath];
		else filePath = @"--";
	}
	[fpgaFilePathField setStringValue: filePath];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORMCA927ModelLock to:secure];
    [lockButton setEnabled:secure];
}

#pragma mark •••Notifications
- (void) controlRegChanged:(NSNotification*)aNote
{
	unsigned long mask = [model controlReg:[model selectedChannel]];
	int i;
	for(i=0;i<32;i++){
		BOOL bitSet = (mask&(1<<i))>0;
		if(bitSet != [[controlRegMatrix cellWithTag:i] intValue]){
			[[controlRegMatrix cellWithTag:i] setState:bitSet];
		}
	}	
}

- (void) presetCtrlRegChanged:(NSNotification*)aNote
{

	unsigned long mask = [model presetCtrlReg:[model selectedChannel]];
	int i;
	for(i=0;i<32;i++){
		BOOL bitSet = (mask&(1<<i))>0;
		if(bitSet != [[presetCtrlRegMatrix cellWithTag:i] intValue]){
			[[presetCtrlRegMatrix cellWithTag:i] setState:bitSet];
		}
	}	
}

- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
	[[self window] setTitle:[model title]];
}

- (void) interfacesChanged:(NSNotification*)aNote
{
	[self populateInterfacePopup:[aNote object]];
}

- (void) lockChanged:(NSNotification*)aNote
{   
	BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:ORMCA927ModelLock];
    [lockButton setState: locked];
	[serialNumberPopup setEnabled:!locked];
	[lowerDiscriminatorField setEnabled:!locked];
	[convGainPopup setEnabled:!locked];
	[realTimeField setEnabled:!locked];
	[roiPeakPresetField setEnabled:!locked];
	[roiPresetField setEnabled:!locked];
	[rtPresetField setEnabled:!locked];
	[ltPresetField setEnabled:!locked];
	[presetCtrlRegMatrix setEnabled:!locked];
	[controlRegMatrix setEnabled:!locked];
	[liveTimeField setEnabled:!locked];
	[upperDiscriminatorField setEnabled:!locked];
	[useCustomFileCB setEnabled:!locked];
	[selectFileButton setEnabled:!locked];
	[clearAllButton setEnabled:!locked];
	[loadFpgaButton setEnabled:!locked];
	[runOptionsMatrix setEnabled:!locked && !runInProgress];
	[autoClearCB setEnabled:!locked && !runInProgress];
	
	[zdtModeMatrix setEnabled:!locked];
	[zdtSpeedPU setEnabled:!locked && ([model zdtMode:[model selectedChannel]] & kEnableZDTMask)!=0];
}

- (void) displayFPGAError
{
	[checkFPGAField setStringValue:@"Check/Load FPGA"];
}

#pragma mark •••Actions

- (void) commentAction:(id)sender
{
	[model setComment:[sender stringValue]];	
}

- (IBAction) viewSpectrum0Action:(id)sender
{
	if(![model viewSpectrum0]){
		[noDataWarningField setStringValue:@"No Data To Show"];
	}
	else [noDataWarningField setStringValue:@""];

}

- (IBAction) viewSpectrum1Action:(id)sender
{
	if(![model viewSpectrum1]){
		[noDataWarningField setStringValue:@"No Data To Show"];
	}
	else [noDataWarningField setStringValue:@""];
}

- (IBAction) viewZDT0Action:(id)sender
{
	if(![model viewZDT0]){
		[noDataWarningField setStringValue:@"No Data To Show"];
	}
	else [noDataWarningField setStringValue:@""];
	
}

- (IBAction) viewZDT1Action:(id)sender
{
	if(![model viewZDT1]){
		[noDataWarningField setStringValue:@"No Data To Show"];
	}
	else [noDataWarningField setStringValue:@""];
}


- (IBAction) runOptionsAction:(id)sender
{
	int i;
	unsigned long optionsMask[2] = {0,0};
	for(i=0;i<2;i++){
		if([[runOptionsMatrix cellAtRow:0 column:i] intValue]) optionsMask[i] |= kChannelEnabledMask;
		if([[runOptionsMatrix cellAtRow:1 column:i] intValue]) optionsMask[i] |= kChannelAutoStopMask;
	}
	for(i=0;i<2;i++){
		[model setRunOptions:i withValue:optionsMask[i]];	
	}
}

- (IBAction) autoClearAction:(id)sender
{
	[model setAutoClear:[model selectedChannel] withValue:[sender intValue]];	
}

- (IBAction) selectedChannelAction:(id)sender
{
	[self endEditing];
	[model setSelectedChannel:[[sender selectedCell] tag]];	
}

- (IBAction) clearSpectrumAction:(id)sender;
{
	
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Clearing all spectra!"];
    [alert setInformativeText:@"Is this really what you want?"];
    [alert addButtonWithTitle:@"Yes, Clear All"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            @try {
                [model clearSpectrum:0];
                [model clearSpectrum:1];
                [model clearZDT:0];
                [model clearZDT:1];
                [model readSpectrum:0];
                [model readSpectrum:1];
                [model readZDT:0];
                [model readZDT:1];
                [plotter setNeedsDisplay:YES];
            }
            @catch (NSException* localException){
                [self displayFPGAError];
                NSLogColor([NSColor redColor],@"MCA927 failed to clear spectrum\n");
                NSLogColor([NSColor redColor],@"%@\n",localException);
            }
 
        }
    }];
#else
    NSBeginAlertSheet(@"Clearing all spectra!",
                      @"Cancel",
                      @"Yes, Clear All",
                      nil,[self window],
                      self,
                      @selector(clearSpectaSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Is this really what you want?");
#endif
}

- (IBAction) writeSpectrumAction:(id)sender;
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
	NSString* fullPath = [[model lastFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"Untitled";
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            int i = [model selectedChannel];
            [model writeSpectrum:i toFile:[[savePanel URL]path]];
        }
    }];
}

- (IBAction) readSpectrumAction:(id)sender
{
	@try {
		[model readSpectrum:0];	
		[model readSpectrum:1];	
		if([model zdtMode:0] & kEnableZDTMask) [model readZDT:0];	
		if([model zdtMode:1] & kEnableZDTMask) [model readZDT:1];	
		[plotter setNeedsDisplay:YES];
	}
	@catch (NSException* localException){
		[self displayFPGAError];
		NSLogColor([NSColor redColor],@"MCA927 failed to read spectrum\n");
		NSLogColor([NSColor redColor],@"%@\n",localException);
	}
}

- (IBAction) startAllAcquistionAction:(id)sender
{
	@try {
		[self endEditing];
		[model startAcquisition:0];	
		[model startAcquisition:1];	
	}
	@catch (NSException* localException){
		[self displayFPGAError];
		NSLogColor([NSColor redColor],@"MCA927 failed to start\n");
		NSLogColor([NSColor redColor],@"%@\n",localException);
	}
}

- (IBAction) stopAllAcquistionAction:(id)sender
{
	@try {
		[self endEditing];
		[model stopAcquisition:0];	
		[model stopAcquisition:1];	
	}
	@catch (NSException* localException){
		[self displayFPGAError];
		NSLogColor([NSColor redColor],@"MCA927 failed to stop\n");
		NSLogColor([NSColor redColor],@"%@\n",localException);
	}
}

- (IBAction) startAcquistionAction:(id)sender
{
	@try {
		[self endEditing];
		[model startAcquisition:[model selectedChannel]];	
	}
	@catch (NSException* localException){
		[self displayFPGAError];
		NSLogColor([NSColor redColor],@"MCA927 failed to start channel %d\n",[model selectedChannel]);
		NSLogColor([NSColor redColor],@"%@\n",localException);
	}
}

- (IBAction) stopAcquistionAction:(id)sender
{
	@try {
		[self endEditing];
		[model stopAcquisition:[model selectedChannel]];	
	}
	@catch (NSException* localException){
		[self displayFPGAError];
		NSLogColor([NSColor redColor],@"MCA927 failed to stop Channel %d\n",[model selectedChannel]);
		NSLogColor([NSColor redColor],@"%@\n",localException);
	}
}

- (IBAction) realTimeAction:(id)sender
{
	[model setRealTime:[model selectedChannel] withValue:[sender floatValue]/0.02];	
}

- (IBAction) rtPresetAction:(id)sender
{
	[model setRtPreset:[model selectedChannel] withValue:[sender floatValue]/0.02];	
}

- (IBAction) roiPresetAction:(id)sender
{
	[model setRoiPreset:[model selectedChannel] withValue:[sender intValue]];	
}

- (IBAction) roiPeakPresetAction:(id)sender
{
	[model setRoiPeakPreset:[model selectedChannel] withValue:[sender intValue]];	
}

- (IBAction) convGainAction:(id)sender
{
	[model setConvGain:[model selectedChannel] withValue:[sender indexOfSelectedItem]];	
}

- (IBAction) liveTimeAction:(id)sender
{
	[model setLiveTime:[model selectedChannel] withValue:[sender floatValue]/0.02];	
}

- (IBAction) ltPresetAction:(id)sender
{
	[model setLtPreset:[model selectedChannel] withValue:[sender floatValue]/0.02];	
}

- (IBAction) lowerDiscriminatorAction:(id)sender
{
	int dialogValue = [sender intValue];
	int n = [model numChannels:[model selectedChannel]];
	[model setLowerDiscriminator:[model selectedChannel] withValue:dialogValue/(float)n*16384.];	
}

- (IBAction) upperDiscriminatorAction:(id)sender
{
	int dialogValue = [sender intValue];
	int n = [model numChannels:[model selectedChannel]];
	[model setUpperDiscriminator:[model selectedChannel] withValue:dialogValue/(float)n*16384.];	
}

- (IBAction) zdtModeAction:(id)sender
{
	unsigned long aValue = [model zdtMode:[model selectedChannel]];
	aValue &= ~kZDTMask;
	if([[sender cellWithTag:0] intValue]) aValue |= kEnableZDTMask;
	if([[sender cellWithTag:1] intValue]) aValue |= kZDTModeMask;
	[model setZdtMode:[model selectedChannel] withValue:aValue];	
}
	 
 - (IBAction) zdtSpeedAction:(id)sender
{
	unsigned long aValue = [model zdtMode:[model selectedChannel]];
	aValue &= ~kZDTSpeedMask;
	aValue |= [[sender selectedItem] tag];
	[model setZdtMode:[model selectedChannel] withValue:aValue];	
}

- (IBAction) useCustomFileAction:(id)sender
{
	[model setUseCustomFile:[sender intValue]];	
}

- (IBAction) sartFPGAAction:(id)sender
{
	[model startFPGA];
}

- (IBAction) reportAction:(id)sender
{
	@try {
		[model report];
	}
	@catch (NSException* localException) {
		[self displayFPGAError];
		NSLog(@"Report Failed\n");
		NSLog(@"%@\n",localException);
	}
}

- (IBAction) syncAction:(id)sender
{
	@try {
		[model sync];
	}
	@catch (NSException* localException) {
		[self displayFPGAError];
		NSLog(@"Report Failed\n");
		NSLog(@"%@\n",localException);
	}
}



- (IBAction) controlRegAction:(id)sender
{
	unsigned long mask = [model controlReg:[model selectedChannel]];
	mask &= 0x00000001; //clear all but start bit
	int rows,columns;
	[sender getNumberOfRows:&rows columns:&columns];
	int i;
	for(i=0;i<rows;i++){
		if([[sender cellAtRow:i column:0] intValue]){
			int bit = [[sender cellAtRow:i column:0] tag];
			mask |= (0x1L<<bit);
		}
	}
	[model setControlReg:[model selectedChannel] withValue:mask];

}

- (IBAction) presetCtrlRegAction:(id)sender
{
	unsigned long mask = 0;
	int rows,columns;
	[sender getNumberOfRows:&rows columns:&columns];
	int i;
	for(i=0;i<rows;i++){
		if([[sender cellAtRow:i column:0] intValue]){
			int bit = [[sender cellAtRow:i column:0] tag];
			mask |= (0x1L<<bit);
		}
	}
	[model setPresetCtrlReg:[model selectedChannel] withValue:mask];
}


- (IBAction) selectFPGAFileAction:(id)sender
{
	NSString* startPath = [[model fpgaFilePath] stringByDeletingLastPathComponent];
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Select FPGA Binary File"];
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startPath]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setFpgaFilePath:[[openPanel URL]path]]; 
        }
    }];
}


- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORMCA927ModelLock to:[sender intValue] forWindow:[self window]];
}


- (void) validateInterfacePopup
{
	NSArray* interfaces = [[model getUSBController] interfacesForVender:[model vendorID] product:[model productID]];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([anInterface registeredObject] == nil || [serialNumber isEqualToString:[model serialNumber]]){
			[[serialNumberPopup itemWithTitle:serialNumber] setEnabled:YES];
		}
		else [[serialNumberPopup itemWithTitle:serialNumber] setEnabled:NO];
		
	}
}

- (IBAction) serialNumberAction:(id)sender
{
	if([serialNumberPopup indexOfSelectedItem] == 0){
		[model setSerialNumber:nil];
	}
	else {
		[model setSerialNumber:[serialNumberPopup titleOfSelectedItem]];
	}
	
}
- (NSColor*) colorForDataSet:(int)set
{
	if(set==0)return [NSColor redColor];
	else if(set==1)return [NSColor orangeColor];
	else if(set==2)return [NSColor blueColor];
	else return [NSColor blackColor];
}

- (int) numberPointsInPlot:(id)aPlotter
{
	int set = [aPlotter tag];
	if(set == 0 || set == 1)return [model numChannels:set];
	else {
		if(set==2){
			if([model zdtMode:0] & kEnableZDTMask)return [model numChannels:set];
			else return 0;
		}
		else if(set == 3){
			if([model zdtMode:1] & kEnableZDTMask)return [model numChannels:set];
			else return 0;
		}
	}
	return 0;
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int set = [aPlotter tag];
	*xValue = i;
	*yValue = [model spectrum:set valueAtChannel:i];
}

@end

@implementation ORMCA927Controller (private)
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) clearSpectaSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
    if(returnCode == NSAlertAlternateReturn){
		
		@try {
			[model clearSpectrum:0];	
			[model clearSpectrum:1];	
			[model clearZDT:0];	
			[model clearZDT:1];	
			[model readSpectrum:0];	
			[model readSpectrum:1];	
			[model readZDT:0];	
			[model readZDT:1];	
			[plotter setNeedsDisplay:YES];
		}
		@catch (NSException* localException){
			[self displayFPGAError];
			NSLogColor([NSColor redColor],@"MCA927 failed to clear spectrum\n");
			NSLogColor([NSColor redColor],@"%@\n",localException);
		}
	}
}
#endif

- (void) populateInterfacePopup:(ORUSB*)usb
{
    [[self undoManager] disableUndoRegistration];
	NSArray* interfaces = [usb interfacesForVender:[model vendorID] product:[model productID]];
	[serialNumberPopup removeAllItems];
	[serialNumberPopup addItemWithTitle:@"N/A"];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([serialNumber length]){
			[serialNumberPopup addItemWithTitle:serialNumber];
		}
	}
	[self validateInterfacePopup];
	if([model serialNumber]){
		[serialNumberPopup selectItemWithTitle:[model serialNumber]];
	}
	else [serialNumberPopup selectItemAtIndex:0];
    [[self undoManager] enableUndoRegistration];
	
}

@end

