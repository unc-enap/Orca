//
//  ORDGF4cController.m
//  Orca
//
//  Created by Mark Howe on Wed Dec 29 2004.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORDGF4cController.h"
#import "ORPlot.h"
#import "ORPlotView.h"
#import "ORAxis.h"
#import "ORTimedTextField.h"
#import "ORCompositePlotView.h"

@interface ORDGF4cController (private)
- (void) doUpdate;
@end


// methods
@implementation ORDGF4cController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"DGF4c"];
	
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{
	[plotter setUseGradient:YES];
	[[plotter xAxis] setRngLimitsLow:0 withHigh:8192 withMinRng:25];
	[[plotter xAxis] setRngDefaultsLow:0 withHigh:8192];
	[[plotter yAxis] setRngLimitsLow:-65535 withHigh:65535 withMinRng:10];
	[[plotter yAxis] setRngDefaultsLow:-65535 withHigh:65535];
	[[plotter yAxis] setRngLow:-65535 withHigh:65535];
	
	NSColor* theColors[4] =
	{
		[NSColor redColor],
		[NSColor blueColor],
		[NSColor blackColor],
		[NSColor greenColor]	
	};
	int i;
	for(i=0;i<4;i++){
		ORPlot* aPlot = [[ORPlot alloc] initWithTag:i andDataSource:self];
		[aPlot setLineColor:theColors[i]];
		[plotter addPlot: aPlot];
		[aPlot release];
	}
	
	[super awakeFromNib];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORCamacCardSlotChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(firmWarePathChanged:)
                         name : ORDFG4cFirmWarePathChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(dspCodePathChanged:)
                         name : ORDFG4cDSPCodePathChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(paramChanged:)
                         name : ORDFG4cParamChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORDFG4cDSPSettingsLock
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(channelChanged:)
                         name : ORDFG4cChannelChangedNotification
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(revisionChanged:)
                         name : ORDFG4cRevisionChangedNotification
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(decimationChanged:)
                         name : ORDFG4cDecimationChangedNotification
                        object: model];
    
	
    [notifyCenter addObserver : self
                     selector : @selector(oscChanEnableChanged:)
                         name : ORDFG4cOscEnabledMaskChangedNotification
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(tauChanged:)
                         name : ORDGF4cModelTauChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(tauSigmaChanged:)
                         name : ORDGF4cModelTauSigmaChanged
                        object: model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(binFactorChanged:)
                         name : ORDGF4cModelBinFactorChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(eMinChanged:)
                         name : ORDGF4cModelEMinChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(psaEndChanged:)
                         name : ORDGF4cModelPsaEndChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(psaStartChanged:)
                         name : ORDGF4cModelPsaStartChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(traceDelayChanged:)
                         name : ORDGF4cModelTraceDelayChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(traceLengthChanged:)
                         name : ORDGF4cModelTraceLengthChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(vOffsetChanged:)
                         name : ORDGF4cModelVOffsetChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(vGainChanged:)
                         name : ORDGF4cModelVGainChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(triggerThresholdChanged:)
                         name : ORDGF4cModelTriggerThresholdChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(triggerFlatTopChanged:)
                         name : ORDGF4cModelTriggerFlatTopChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(triggerRiseTimeChanged:)
                         name : ORDGF4cModelTriggerRiseTimeChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(energyFlatTopChanged:)
                         name : ORDGF4cModelEnergyFlatTopChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(energyRiseTimeChanged:)
                         name : ORDGF4cModelEnergyRiseTimeChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(runTaskChanged:)
                         name : ORDGF4cModelRunTaskChanged
                        object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(sampleWaveformsChanged:)
                         name : ORDFG4cSampleWaveformChangedNotification
                        object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(updateOsc:)
                         name : ORDFG4cWaveformChangedNotification
                        object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(xwaitChanged:)
                         name : ORDGF4cModelXwaitChanged
                        object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(runBehaviorChanged:)
                         name : ORDGF4cModelRunBehaviorMaskChanged
                        object: model];
	
}

#pragma mark ¥¥¥Interface Management

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
	[self firmWarePathChanged:nil];
	[self dspCodePathChanged:nil];
    [dspParamTableView reloadData];
    [dspChanTableView reloadData];
    [self settingsLockChanged:nil];
    [self channelChanged:nil];
    [self revisionChanged:nil];
    [self decimationChanged:nil];
	[self oscChanEnableChanged:nil];
	[self sampleWaveformsChanged:nil];
    [self updateDisplayOnlyParams];
    [self updateUserParams:nil];
	
}

- (void) updateUserParams:(NSNotification*)aNote
{
	[self runTaskChanged:nil];
	[self runBehaviorChanged:nil];
	[self tauChanged:nil];
	[self tauSigmaChanged:nil];
	[self binFactorChanged:nil];
	[self eMinChanged:nil];
	[self psaEndChanged:nil];
	[self psaStartChanged:nil];
	[self traceDelayChanged:nil];
	[self traceLengthChanged:nil];
	[self vOffsetChanged:nil];
	[self vGainChanged:nil];
	[self triggerThresholdChanged:nil];
	[self triggerFlatTopChanged:nil];
	[self triggerRiseTimeChanged:nil];
	[self energyFlatTopChanged:nil];
	[self energyRiseTimeChanged:nil];
	[self xwaitChanged:nil];
}

- (void) updateDisplayOnlyParams
{
    [self registersChanged:nil];
    [self liveTimeChanged:nil];
    [self inputCountsChanged:nil];
    [self timeChanged:nil];
    [self chanCSRAChanged:nil];
}

- (void) channelChanged:(NSNotification*)aNote
{
	[channelField setIntValue:[model channel]];
	[channelStepper setIntValue:[model channel]];
	[self registersChanged:nil];
	[self liveTimeChanged:nil];
	[self inputCountsChanged:nil];
	[self timeChanged:nil];
	[self chanCSRAChanged:nil];
	[self updateUserParams:aNote];
}


- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"DGF4c (Station %d)",(int)[model stationNumber]]];
}
- (void) tauChanged:(NSNotification*)aNotification 
{
	float aValue = [model tau:[model channel]];
	[[calibrateStepperMatrix cellWithTag:2] setFloatValue:aValue];
	[[calibrateFieldMatrix cellWithTag:2]   setFloatValue:aValue];
}

- (void) tauSigmaChanged:(NSNotification*)aNotification 
{
	float aValue = [model tauSigma:[model channel]];
	[[calibrateStepperMatrix cellWithTag:3] setFloatValue:aValue];
	[[calibrateFieldMatrix cellWithTag:3]   setFloatValue:aValue];
}

- (void) binFactorChanged:(NSNotification*)aNotification 
{
	unsigned short aValue = [model binFactor:[model channel]];
	[[histogramStepperMatrix cellWithTag:1] setIntValue:aValue];
	[[histogramFieldMatrix cellWithTag:1]   setIntValue:aValue];
}

- (void) eMinChanged:(NSNotification*)aNotification 
{
	unsigned short aValue = [model eMin:[model channel]];
	[[histogramStepperMatrix cellWithTag:0] setIntValue:aValue];
	[[histogramFieldMatrix cellWithTag:0]   setIntValue:aValue];
}

- (void) psaEndChanged:(NSNotification*)aNotification 
{
	float aValue = [model psaEnd:[model channel]];
	[[pulseShapeStepperMatrix cellWithTag:3] setFloatValue:aValue];
	[[pulseShapeFieldMatrix cellWithTag:3]   setFloatValue:aValue];
}

- (void) psaStartChanged:(NSNotification*)aNotification 
{
	float aValue = [model psaStart:[model channel]];
	[[pulseShapeStepperMatrix cellWithTag:2] setFloatValue:aValue];
	[[pulseShapeFieldMatrix cellWithTag:2]   setFloatValue:aValue];
}

- (void) traceDelayChanged:(NSNotification*)aNotification 
{
	float aValue = [model traceDelay:[model channel]];
	[[pulseShapeStepperMatrix cellWithTag:1] setFloatValue:aValue];
	[[pulseShapeFieldMatrix cellWithTag:1]   setFloatValue:aValue];
}

- (void) traceLengthChanged:(NSNotification*)aNotification 
{
	unsigned short aValue = [model traceLength:[model channel]];
	[[pulseShapeStepperMatrix cellWithTag:0] setIntValue:aValue];
	[[pulseShapeFieldMatrix cellWithTag:0]   setIntValue:aValue];
}

- (void) vOffsetChanged:(NSNotification*)aNotification 
{
	float aValue = [model vOffset:[model channel]];
	[[calibrateStepperMatrix cellWithTag:1] setFloatValue:aValue];
	[[calibrateFieldMatrix cellWithTag:1]   setFloatValue:aValue];
}

- (void) vGainChanged:(NSNotification*)aNotification 
{
	float aValue = [model vGain:[model channel]];
	[[calibrateStepperMatrix cellWithTag:0] setFloatValue:aValue];
	[[calibrateFieldMatrix cellWithTag:0]   setFloatValue:aValue];
}

- (void) triggerThresholdChanged:(NSNotification*)aNotification 
{
	float aValue = [model triggerThreshold:[model channel]];
	[[triggerFilterStepperMatrix cellWithTag:2] setFloatValue:aValue];
	[[triggerFilterFieldMatrix cellWithTag:2]   setFloatValue:aValue];
}

- (void) triggerFlatTopChanged:(NSNotification*)aNotification 
{
	float aValue = [model triggerFlatTop:[model channel]];
	[[triggerFilterStepperMatrix cellWithTag:1] setFloatValue:aValue];
	[[triggerFilterFieldMatrix cellWithTag:1]   setFloatValue:aValue];
}

- (void) triggerRiseTimeChanged:(NSNotification*)aNotification 
{
	float aValue = [model triggerRiseTime:[model channel]];
	[[triggerFilterStepperMatrix cellWithTag:0] setFloatValue:aValue];
	[[triggerFilterFieldMatrix cellWithTag:0]   setFloatValue:aValue];
}

- (void) energyFlatTopChanged:(NSNotification*)aNotification 
{
	float aValue = [model energyFlatTop:[model channel]];
	[[energyFilterStepperMatrix cellWithTag:1] setFloatValue:aValue];
	[[energyFilterFieldMatrix cellWithTag:1]   setFloatValue:aValue];
}

- (void) energyRiseTimeChanged:(NSNotification*)aNotification
{
	float aValue = [model energyRiseTime:[model channel]];
	[[energyFilterStepperMatrix cellWithTag:0] setFloatValue:aValue];
	[[energyFilterFieldMatrix cellWithTag:0]   setFloatValue:aValue];
} 

- (void) oscChanEnableChanged:(NSNotification*)aNotification
{
	short i;
	unsigned char theMask = [model oscEnabledMask];
	for(i=0;i<4;i++){
		BOOL bitSet = (theMask&(1<<i))>0;
		[[ocsChanEnableMatrix cellWithTag:i] setState:bitSet];
	}
}


- (void) xwaitChanged:(NSNotification*)aNotification
{
	[xwaitField setIntValue:[model xwait:[model channel]]];
	[xwaitStepper setIntValue:[model xwait:[model channel]]];
}

- (void) sampleWaveformsChanged:(NSNotification*)aNote
{
	[sampleWaveformsButton setState:[model sampleWaveforms]];
	if([model sampleWaveforms]){
		[samplingWarning setStringValue:@"Sampling Waveforms"];
	}
	else [samplingWarning setStringValue:@""];
}

- (void) runTaskChanged:(NSNotification*)aNote
{
	unsigned short aValue = [model runTask];
	int n = (int)[runTypePopup numberOfItems];
	int i;
	for(i=0;i<n;i++){
		if([[runTypePopup itemAtIndex:i] tag] == aValue){
			[self updatePopUpButton:runTypePopup setting:i];
			return;
		}
	}
	[self updatePopUpButton:runTypePopup setting:0];
	[self runTypeAction:runTypePopup];
}

- (void) runBehaviorChanged:(NSNotification*)aNote
{
	uint32_t theRunBehaviorMask = [model runBehaviorMask];
	[[runBehaviorMatrix cellWithTag:0] setState: theRunBehaviorMask&0x1];	 //synwait
	[[runBehaviorMatrix cellWithTag:1] setState: (theRunBehaviorMask&0x2)>>1];	 //insynch
}


- (void) registersChanged:(NSNotification*)aNote
{
	unsigned short aValue;        
	NSString* theParamName = [[aNote userInfo] objectForKey:@"ParamName"];
	
	if(!aNote || [theParamName isEqualToString:@"MODCSRA"]){
		aValue = [model paramValue:@"MODCSRA"];
		[[registerFieldMatrix cellWithTag:0]   setIntValue:aValue];
	}
	
	if(!aNote || [theParamName isEqualToString:@"CHANCSRA"]){
		aValue = [model paramValue:@"CHANCSRA" channel:[model channel]];
		[[registerFieldMatrix cellWithTag:1]   setIntValue:aValue];
	}
	
	if(!aNote || [theParamName isEqualToString:@"COINCPATTERN"]){
		aValue = [model paramValue:@"COINCPATTERN"];
		[[registerFieldMatrix cellWithTag:2]   setIntValue:aValue];
	}
}

- (void) timeChanged:(NSNotification*)aNote;
{
	NSString* theParamName = [[aNote userInfo] objectForKey:@"ParamName"];
	
	if(!aNote || [theParamName isEqualToString:@"REALTIMEC"]){
		unsigned short rta = [model paramValue:@"REALTIMEA"];
		unsigned short rtb = [model paramValue:@"REALTIMEB"];
		unsigned short rtc = [model paramValue:@"REALTIMEC"];
		double realTime = (rta*pow(65536.0,2.0)+rtb*65536.0+rtc)*1.0e-6/40.;
		[[timeMatrix cellWithTag:0] setStringValue:[NSString stringWithFormat:@"%.4f",realTime]];
	}
	
	if(!aNote || [theParamName isEqualToString:@"RUNTIMEC"]){
		unsigned short rta = [model paramValue:@"RUNTIMEA"];
		unsigned short rtb = [model paramValue:@"RUNTIMEB"];
		unsigned short rtc = [model paramValue:@"RUNTIMEC"];
		double runTime = (rta*pow(65536.0,2.0)+rtb*65536.0+rtc)*1.0e-6/40.;
		[[timeMatrix cellWithTag:1] setStringValue:[NSString stringWithFormat:@"%.4f",runTime]];
	}
}

- (void) liveTimeChanged:(NSNotification*)aNote
{
	NSString* theParamName = [[aNote userInfo] objectForKey:@"ParamName"];
	
	if(!aNote || [theParamName isEqualToString:@"LIVETIMEC"]){
		int i;
		for(i=0;i<4;i++){
			unsigned short la = [model paramValue:@"LIVETIMEA" channel:i];
			unsigned short lb = [model paramValue:@"LIVETIMEB" channel:i];
			unsigned short lc = [model paramValue:@"LIVETIMEC" channel:i];
			double liveTime=(la*pow(65536.0,2.0)+lb*65536.0+lc)*16*1.0e-6/40;
			[[liveTimeMatrix cellWithTag:i] setStringValue:[NSString stringWithFormat:@"%.4f",liveTime]];
		}
	}
}

- (void) inputCountsChanged:(NSNotification*)aNote
{
	NSString* theParamName = [[aNote userInfo] objectForKey:@"ParamName"];
	
	if(!aNote || [theParamName isEqualToString:@"FASTPEAKSB"]){
		int i;
		for(i=0;i<4;i++){
			unsigned short ia = [model paramValue:@"FASTPEAKSA" channel:i];
			unsigned short ib = [model paramValue:@"FASTPEAKSB" channel:i];
			int32_t fastPeaks=(int32_t)(ia*65536.0+ib);
			[[inputCountsMatrix cellWithTag:i] setStringValue:[NSString stringWithFormat:@"%d",fastPeaks]];
		}
	}
}

- (void) revisionChanged:(NSNotification*)aNote;
{
	char rev = 'A' + [model revision];
	if(rev >= 'C')	[revisionField setStringValue:[NSString stringWithFormat:@"%c",rev]];
	else			[revisionField setStringValue:@"unKnown"]; 
}

- (void) decimationChanged:(NSNotification*)aNote;
{
	[self updatePopUpButton:decimationPopup setting:[model decimation]-1];
}


- (void) chanCSRAChanged:(NSNotification*)aNote;
{
	NSString* theParamName = [[aNote userInfo] objectForKey:@"ParamName"];
	
	if(!aNote || [theParamName isEqualToString:@"CHANCSRA"]){
		int chan;
		for(chan=0;chan<4;chan++){
			int aValue = [model paramValue:@"CHANCSRA" channel:chan];
			int j;
			for(j=0;j<12;j++){
				if(j==8 || j==9)continue;
				[[chanCSRAMatrix cellWithTag:(j*4)+chan] setState:aValue&(1<<j)];
			}
		}
	}
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORDFG4cDSPSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) paramChanged:(NSNotification*)aNotification
{
	[dspParamTableView reloadData];
	[self updateDisplayOnlyParams];
}

- (void) firmWarePathChanged:(NSNotification*)aNotification
{
	if([model firmWarePath]){
		[firmWarePathField setStringValue:[[model firmWarePath] stringByAbbreviatingWithTildeInPath]];
	}
}

- (void) dspCodePathChanged:(NSNotification*)aNotification
{
	if([model dspCodePath]){
		[dspCodePathField setStringValue:[[model dspCodePath] stringByAbbreviatingWithTildeInPath]];
	}
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORDFG4cDSPSettingsLock];
    BOOL locked = [gSecurity isLocked:ORDFG4cDSPSettingsLock];
	
    [settingLockButton setState: locked];
	
    [loadDefaultsButton setEnabled:!lockedOrRunningMaintenance];
    [saveSetButton setEnabled:!lockedOrRunningMaintenance];
    [loadSetButton setEnabled:!lockedOrRunningMaintenance];
    [mergeSetButton setEnabled:!lockedOrRunningMaintenance];
	
    [dspCodePathButton setEnabled:!lockedOrRunningMaintenance];
    [bootDSPButton setEnabled:!locked && !runInProgress];
	
    [firmWarePathButton setEnabled:!lockedOrRunningMaintenance];
    [loadFirmWareButton setEnabled:!locked && !runInProgress];
	
	
    [sampleContinousButton setEnabled:!locked && !runInProgress];
    [ocsChanEnableMatrix setEnabled:!locked];
    [sampleWaveformsButton setEnabled:!locked];
	
    [runTypePopup setEnabled:!locked && !runInProgress];
    [decimationPopup setEnabled:!lockedOrRunningMaintenance];
    [triggerFilterFieldMatrix setEnabled:!lockedOrRunningMaintenance];
    [triggerFilterStepperMatrix setEnabled:!lockedOrRunningMaintenance];
    [energyFilterFieldMatrix setEnabled:!lockedOrRunningMaintenance];
    [energyFilterStepperMatrix setEnabled:!lockedOrRunningMaintenance];
	
    [pulseShapeFieldMatrix setEnabled:!lockedOrRunningMaintenance];
    [pulseShapeStepperMatrix setEnabled:!lockedOrRunningMaintenance];
	
    [registerFieldMatrix setEnabled:!lockedOrRunningMaintenance];
	
    [calibrateFieldMatrix setEnabled:!lockedOrRunningMaintenance];
    [calibrateStepperMatrix setEnabled:!lockedOrRunningMaintenance];
	
    [histogramFieldMatrix setEnabled:!lockedOrRunningMaintenance];
    [histogramStepperMatrix setEnabled:!lockedOrRunningMaintenance];
	
    [chanCSRAMatrix setEnabled:!lockedOrRunningMaintenance];
	
    [loadParamsToHWButton setEnabled:!lockedOrRunningMaintenance];
    [loadParamsToHWButton2 setEnabled:!lockedOrRunningMaintenance];
    [sampleButton setEnabled:!locked && !runInProgress];
	
    [baselineCutButton setEnabled:!locked && !runInProgress];
    [offsetButton setEnabled:!locked && !runInProgress];
	
    [autoTauFindButton setEnabled:!locked && !runInProgress];
    
    [xwaitField setEnabled:!lockedOrRunningMaintenance];
    [xwaitStepper setEnabled:!lockedOrRunningMaintenance];
	
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORDFG4cDSPSettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
	if(runInProgress && sampling){
		//if running and sampling, turn off sampling
		sampling = NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(takeSample) object:nil];
		[sampleButton setTitle:sampling?@"Stop":@"Sample"];
	}
	
}

#pragma mark ¥¥¥Actions
- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORDFG4cDSPSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) bootDSPAction:(id) sender;
{
    @try {
        [model bootDSP];
    }
	@catch(NSException* localException) {
    }
}

- (IBAction) loadFirmWareAction:(id) sender;
{
    @try {
        [model loadSystemFPGA];
    }
	@catch(NSException* localException) {
    }
}

- (IBAction) loadDefaults:(id) sender;
{
    [model loadDefaults];
}


- (IBAction) firmWarePathAction:(id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose DGF4c Firmware Folder"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model firmWarePath]){
        startDir = [[model firmWarePath]stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setFirmWarePath:[[openPanel URL]path]];
        }
    }];
}


- (IBAction) dspCodePathAction:(id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose DGF4c DSP Code File"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model dspCodePath]){
        startDir = [[model dspCodePath]stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setDSPCodePath:[[openPanel URL]path]];
        }
    }];
}

- (IBAction) loadSetAction:(id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Load"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model lastParamPath]){
        startDir = [[model lastParamPath]stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model loadSetFromPath:[[openPanel URL]path]]; 
        }
    }];

}

- (IBAction) saveSetAction:(id) sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save"];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"plist"]];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model lastParamPath]){
        startDir = [[model lastParamPath]stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model saveSetToPath:[[savePanel URL]path]]; 
        }
    }];

}

- (IBAction) mergeSetAction:(id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Load .var File"];
    //see if we can use the last dir for a starting point...
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model lastNewSetPath]){
        startDir = [[model lastNewSetPath]stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model createNewVarList:[[openPanel URL]path]]; 
        }
    }];

}

- (IBAction) runTypeAction:(id) sender
{
    short runType = [[runTypePopup selectedItem] tag];
	[model setRunTask:runType];
	
}

- (IBAction) runBehaviorAction:(id)sender
{
	uint32_t theRunBehaviorMask = 0;
	if([[runBehaviorMatrix cellWithTag:0] state]) theRunBehaviorMask |= 0x1; //syncwait
	if([[runBehaviorMatrix cellWithTag:1] state]) theRunBehaviorMask |= 0x2; //insynch
	[model setRunBehaviorMask:theRunBehaviorMask];
}

- (IBAction) decimationAction:(id) sender
{
    short decimation = [[decimationPopup selectedItem] tag];
    [model setDecimation:decimation];
    
    short chan = [model channel];
    [model setEnergyRiseTime:chan withValue:[model energyRiseTime:chan]];
    [model setEnergyFlatTop:chan withValue:[model energyFlatTop:chan]];
	
}

- (IBAction) sampleWaveformsAction:(id) sender
{
	[model setSampleWaveforms:[sender state]];
}


- (IBAction) xwaitAction:(id) sender
{
	[model setXwait:[model channel] withValue:[sender intValue]];
}

- (IBAction) sampleAction:(id)sender
{
	
	if(sampling){
		sampling = NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(takeSample) object:nil];
	}
	else {
		sampling = [sampleContinousButton state];
		[self performSelector:@selector(takeSample) withObject:nil afterDelay:0];
	}
	
	[sampleButton setTitle:sampling?@"Stop":@"Sample"];
}

- (void) takeSample
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(takeSample) object:nil];
	
	int i,n=4;
	for(i=0;i<n;i++){
		[model sampleChannel:i];
	}
	//[plotter autoScale:nil];
	[plotter setNeedsDisplay:YES];
	//[[plotter yAxis] setRngLimitsLow:-65535 withHigh:65535 withMinRng:10];
	
	if(sampling){
		[self performSelector:@selector(takeSample) withObject:nil afterDelay:.5];
	}
}

- (void) updateOsc:(NSNotification*)aNotification
{
    if(!scheduledToUpdate){
        [self performSelector:@selector(doUpdate) withObject:nil afterDelay:1.0];
        scheduledToUpdate = YES;
    }
}


- (IBAction) triggerFilterAction:(id) sender
{
    short aTag = [[sender selectedCell] tag];
    short channel = [model channel];
    switch(aTag){
        case 0: //rise time
            [model setTriggerRiseTime:channel withValue:[sender floatValue]];
			break;
        case 1: //flat top
            [model setTriggerFlatTop:channel withValue:[sender floatValue]];
			break;
        case 2: //threshold
            [model setTriggerThreshold:channel withValue:[sender floatValue]];
			break;
    }
}

- (IBAction) energyFilterAction:(id) sender
{
    short aTag = [[sender selectedCell] tag];
    short channel = [model channel];
    switch(aTag){
        case 0: 
            [model setEnergyRiseTime:channel withValue:[sender floatValue]];
			break;
        case 1: 
            [model setEnergyFlatTop:channel withValue:[sender floatValue]];
			break;
    }
}


- (IBAction) pulseShapeAction:(id) sender
{
    short aTag = [[sender selectedCell] tag];
    short channel = [model channel];
    
    switch(aTag){
        case 0:             
            [model setTraceLength:channel withValue:[sender intValue]];
			break;
			
        case 1: 
            [model setTraceDelay:channel withValue:[sender floatValue]];
			break;
			
        case 2: 
            [model setPsaStart:channel withValue:[sender floatValue]];
			break;
        case 3: 
            [model setPsaEnd:channel withValue:[sender floatValue]];
			break;
    }
}

- (IBAction) registerAction:(id) sender
{
    short aTag = [[sender selectedCell] tag];
    short channel = [model channel];
    unsigned short aValue = [sender intValue];
	
    switch(aTag){
        case 0:             
            [model setParam:@"MODCSRA" value:aValue];
			break;
			
        case 1: 
            [model setParam:@"CHANCSRA" value:aValue channel:channel];
			break;
			
        case 2: 
            [model setParam:@"COINCPATTERN" value:aValue];
			break;
    }
}

- (IBAction) calibrateAction:(id) sender
{
    short aTag = [[sender selectedCell] tag];
    short channel = [model channel];
	
    switch(aTag){
        case 0:  
            [model setVGain:channel withValue:[sender floatValue]];
			break;
			
        case 1: 
            [model setVOffset:channel withValue:[sender floatValue]];
			break;
			
        case 2: 
            [model setTau:channel withValue:[sender floatValue]];
			break;
			
			
        case 3: 
            [model setTauSigma:channel withValue:[sender floatValue]];
			break;
			
    }
}

- (IBAction) histogramAction:(id) sender
{
    short aTag = [[sender selectedCell] tag];
    short channel = [model channel];
	
    switch(aTag){
        case 0:             
            [model setEMin:channel withValue:[sender intValue]];
			break;
			
        case 1: 
            [model setBinFactor:channel withValue:[sender intValue]];
			break;
    }
}

- (IBAction) channelAction:(id) sender
{
	[self endEditing];
    [model setChannel:[sender intValue]];
}


- (IBAction) chanCSRAAction:(id) sender
{
    short aTag        = [[sender selectedCell] tag];
    BOOL  theNewState = [[sender selectedCell] state];
    int bit  = aTag/4;
    int chan = aTag%4;
    unsigned short   crsaWord     = [model paramValue:@"CHANCSRA" channel:chan];
    if(theNewState)crsaWord |= (1<<bit);
    else crsaWord &= ~(1<<bit);
	
    [model setParam:@"CHANCSRA" value:crsaWord channel:chan];
    
}

- (IBAction) revisionAction:(id) sender
{
	[model setRevision:[[sender selectedCell] tag]];
}

- (IBAction) loadParamsToHWAction:(id) sender
{
	[self endEditing];
	[model loadParamsWithReadBack:YES];
}

- (IBAction) oscChanEnableAction:(id)sender
{
	[model setOscChanEnabledBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) baselineCutAction:(id)sender
{
    int i;
    for(i=0;i<4;i++){
        [model runBaselineCut:i];
    }
}

- (IBAction) autoFindTauAction:(id)sender
{
    int i;
    for(i=0;i<4;i++){
        [model runTauFinder:i];
    }
}

- (IBAction) offsetAction:(id)sender
{
	[model calcOffsets];
}


#pragma mark ¥¥¥Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    if(aTableView == dspParamTableView){
        return [model param:@"DSPParams" index:rowIndex forKey:[aTableColumn identifier]];
    }
    else {
        return [model param:@"DSPChanParams" index:rowIndex forKey:[aTableColumn identifier]];
    }
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == dspParamTableView){
        return [model countForArray:@"DSPParams"];
    }
    else {
        return [model countForArray:@"DSPChanParams"];
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(aTableView == dspParamTableView){
        [model set:@"DSPParams" index:rowIndex toObject:anObject forKey:[aTableColumn identifier]];
    }
    else {
        [model set:@"DSPChanParams" index:rowIndex toObject:anObject forKey:[aTableColumn identifier]];
    }
}

- (int) numberPointsInPlot:(id)aPlotter
{
	int set = (int)[aPlotter tag];
	if([model oscEnabledMask] & (1<<set)){
		return (int)[model numOscPoints];
	}
	else return 0;
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	*yValue = [model oscData:[aPlotter tag] value:i];
	*xValue = i;
}

@end

@implementation ORDGF4cController (private)
- (void) doUpdate
{
    scheduledToUpdate = NO;
    [plotter setNeedsDisplay:YES];
}
@end




