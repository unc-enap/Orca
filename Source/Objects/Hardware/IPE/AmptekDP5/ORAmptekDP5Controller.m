//
//  ORAmptekDP5Controller.m
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
#import "ORAmptekDP5Controller.h"
#import "ORAmptekDP5Model.h"
#import "TimedWorker.h"
#import "ORValueBarGroupView.h"
#import "ORAxis.h"
//#import "SBC_Link.h"

//Amptek ASCII Commands




#define kFltNumberTriggerSources 5

NSString* fltEdelweissV4TriggerSourceNamesXXX[2][kFltNumberTriggerSources] = {
{
	@"Software",
	@"Right",
	@"Left",
	@"Mirror",
	@"External",
},
{
	@"Software",
	@"N/A",
	@"N/A",
	@"Multiplicity",
	@"External",
}
};

@interface ORAmptekDP5Controller (private)

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) calibrationSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
- (void) do:(SEL)aSelector name:(NSString*)aName;
@end

@implementation ORAmptekDP5Controller

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"AmptekDP5"];
    
    return self;
}

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Initialization
- (void) dealloc
{
	[xImage release];
	[yImage release];
    [super dealloc];
}

- (void) awakeFromNib
{
	controlSize			= NSMakeSize(750,670);
    statusSize			= NSMakeSize(650,670);
    lowLevelSize		= NSMakeSize(650,500);
    networkConnectionSize	= NSMakeSize(650,500);
    testSize    		= NSMakeSize(650,650);
    aboutSize		    = NSMakeSize(650,470);
	
	[[self window] setTitle:@"Amptek DP5"];	//TODO: use enumbering
	
    [super awakeFromNib];
    [self updateWindow];
	
	[self populatePullDown];
    
    // command table view
	//[self  populateCommandTableView];
    
    [[commandQueueValueBar xAxis] setRngLimitsLow:0 withHigh:30 withMinRng:3];
    [[commandQueueValueBar xAxis] setRngDefaultsLow:0 withHigh:100];
    
}

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
	
	[notifyCenter addObserver : self
                     selector : @selector(hwVersionChanged:)
                         name : ORAmptekDP5ModelHwVersionChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(statusRegChanged:)
                         name : ORAmptekDP5ModelStatusRegChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(controlRegChanged:)
                         name : ORAmptekDP5ModelControlRegChanged
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORAmptekDP5SelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORAmptekDP5WriteValueChanged
					   object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(pulserAmpChanged:)
                         name : ORAmptekDP5PulserAmpChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pulserDelayChanged:)
                         name : ORAmptekDP5PulserDelayChanged
                       object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : ORAmptekDP5ModelPageSizeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : ORAmptekDP5ModelDisplayEventLoopChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : ORAmptekDP5ModelDisplayTriggerChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(nextPageDelayChanged:)
                         name : ORAmptekDP5ModelNextPageDelayChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollRateChanged:)
                         name : TimedWorkerTimeIntervalChangedNotification
                       object : [model poller]];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollRunningChanged:)
                         name : TimedWorkerIsRunningChangedNotification
                       object : [model poller]];
	
    [notifyCenter addObserver : self
                     selector : @selector(patternFilePathChanged:)
                         name : ORAmptekDP5ModelPatternFilePathChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(clockTimeChanged:)
                         name : ORAmptekDP5ModelClockTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sltScriptArgumentsChanged:)
                         name : ORAmptekDP5ModelSltScriptArgumentsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPCommandPortChanged:)
                         name : ORAmptekDP5ModelCrateUDPCommandPortChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPCommandIPChanged:)
                         name : ORAmptekDP5ModelCrateUDPCommandIPChanged
						object: model];




#if 0
    [notifyCenter addObserver : self
                     selector : @selector(interruptMaskChanged:)
                         name : ORAmptekDP5ModelInterruptMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(crateUDPReplyPortChanged:)
                         name : ORAmptekDP5ModelCrateUDPReplyPortChanged
						object: model];
#endif



                

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPCommandChanged:)
                         name : ORAmptekDP5ModelCrateUDPCommandChanged
						object: model];

    //[notifyCenter addObserver : self
    //                 selector : @selector(isListeningOnServerSocketChanged:)
    //                     name : ORAmptekDP5ModelIsListeningOnServerSocketChanged
	//					object: model];

    [notifyCenter addObserver : self
                     selector : @selector(openCommandSocketChanged:)
                         name : ORAmptekDP5ModelIsListeningOnServerSocketChanged
						object: model];
#if 0
    [notifyCenter addObserver : self
                     selector : @selector(selectedFifoIndexChanged:)
                         name : ORAmptekDP5ModelSelectedFifoIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pixelBusEnableRegChanged:)
                         name : ORAmptekDP5ModelPixelBusEnableRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(eventFifoStatusRegChanged:)
                         name : ORAmptekDP5ModelEventFifoStatusRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPDataPortChanged:)
                         name : ORAmptekDP5ModelCrateUDPDataPortChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPDataIPChanged:)
                         name : ORAmptekDP5ModelCrateUDPDataIPChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPDataReplyPortChanged:)
                         name : ORAmptekDP5ModelCrateUDPDataReplyPortChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isListeningOnDataServerSocketChanged:)
                         name : ORAmptekDP5ModelIsListeningOnDataServerSocketChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(numRequestedUDPPacketsChanged:)
                         name : ORAmptekDP5ModelNumRequestedUDPPacketsChanged
						object: model];
#endif




//TODO: rm   slt - - 
#if 0
    [notifyCenter addObserver : self
                     selector : @selector(openDataCommandSocketChanged:)
                         name : ORAmptekDP5ModelOpenCloseDataCommandSocketChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cmdWArg1Changed:)
                         name : ORAmptekDP5ModelCmdWArg1Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cmdWArg2Changed:)
                         name : ORAmptekDP5ModelCmdWArg2Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cmdWArg3Changed:)
                         name : ORAmptekDP5ModelCmdWArg3Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cmdWArg4Changed:)
                         name : ORAmptekDP5ModelCmdWArg4Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(BBCmdFFMaskChanged:)
                         name : ORAmptekDP5ModelBBCmdFFMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(crateUDPDataCommandChanged:)
                         name : ORAmptekDP5ModelCrateUDPDataCommandChanged
						object: model];


#endif



    [notifyCenter addObserver : self
                     selector : @selector(sltDAQModeChanged:)
                         name : ORAmptekDP5ModelSltDAQModeChanged
						object: model];




//TODO: rm   slt - - 
#if 0
    [notifyCenter addObserver : self
                     selector : @selector(takeUDPstreamDataChanged:)
                         name : ORAmptekDP5ModelTakeUDPstreamDataChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(takeEventDataChanged:)
                         name : ORAmptekDP5ModelTakeEventDataChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(idBBforWCommandChanged:)
                         name : ORAmptekDP5ModelIdBBforWCommandChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useBroadcastIdBBChanged:)
                         name : ORAmptekDP5ModelUseBroadcastIdBBChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(chargeBBFileChanged:)
                         name : ORAmptekDP5ModelChargeBBFileChanged
						object: model];
                        
    [notifyCenter addObserver : self
                     selector : @selector(statusLowRegChanged:)
                         name : ORAmptekDP5ModelStatusRegLowChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(statusHighRegChanged:)
                         name : ORAmptekDP5ModelStatusRegHighChanged
						object: model];

#endif








    [notifyCenter addObserver : self
                     selector : @selector(takeRawUDPDataChanged:)
                         name : ORAmptekDP5ModelTakeRawUDPDataChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(takeADCChannelDataChanged:)
                         name : ORAmptekDP5ModelTakeADCChannelDataChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lowLevelRegInHexChanged:)
                         name : ORAmptekDP5ModelLowLevelRegInHexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(resetEventCounterAtRunStartChanged:)
                         name : ORAmptekDP5ModelResetEventCounterAtRunStartChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(textCommandChanged:)
                         name : ORAmptekDP5ModelTextCommandChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(numSpectrumBinsChanged:)
                         name : ORAmptekDP5ModelNumSpectrumBinsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(spectrumRequestTypeChanged:)
                         name : ORAmptekDP5ModelSpectrumRequestTypeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(spectrumRequestRateChanged:)
                         name : ORAmptekDP5ModelSpectrumRequestRateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isPollingSpectrumChanged:)
                         name : ORAmptekDP5ModelIsPollingSpectrumChanged
						object: model];


    [notifyCenter addObserver : self
                     selector : @selector(commandTableChanged:)
                         name : ORAmptekDP5ModelCommandTableChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(commandQueueCountChanged:)
                         name : ORAmptekDP5ModelCommandQueueCountChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(autoReadbackSetpointChanged:)
                         name : ORAmptekDP5ModelAutoReadbackSetpointChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dropFirstSpectrumChanged:)
                         name : ORAmptekDP5ModelDropFirstSpectrumChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(acquisitionTimeChanged:)
                         name : ORAmptekDP5ModelAcquisitionTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(realTimeChanged:)
                         name : ORAmptekDP5ModelRealTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fastCounterChanged:)
                         name : ORAmptekDP5ModelFastCounterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(slowCounterChanged:)
                         name : ORAmptekDP5ModelSlowCounterChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(boardTemperatureChanged:)
                         name : ORAmptekDP5ModelBoardTemperatureChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(deviceIDChanged:)
                         name : ORAmptekDP5ModelDeviceIDChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(detectorTemperatureChanged:)
                         name : ORAmptekDP5ModelDetectorTemperatureChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(FirmwareFPGAVersionChanged:)
                         name : ORAmptekDP5ModelFirmwareFPGAVersionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORAmptekDP5ModelSerialNumberChanged
						object: model];

}

#pragma mark ‚Äö√Ñ¬¢‚Äö√Ñ¬¢‚Äö√Ñ¬¢Interface Management

- (void) serialNumberChanged:(NSNotification*)aNote
{
	[serialNumberTextField setIntValue: [model serialNumber]];
}

- (void) FirmwareFPGAVersionChanged:(NSNotification*)aNote
{
	//[FirmwareFPGAVersionTextField setIntValue: [model FirmwareFPGAVersion]];
    int v=[model FirmwareFPGAVersion];
	[FirmwareFPGAVersionTextField setStringValue: [NSString stringWithFormat: @"%i.%i - %i.%i",(v>>12)&0xf, (v>>8)&0xf, (v>>4)&0xf, (v)&0xf ]];
}

- (void) detectorTemperatureChanged:(NSNotification*)aNote
{
	[detectorTemperatureTextField setIntValue: [model detectorTemperature]];
}

- (void) deviceIDChanged:(NSNotification*)aNote
{
    if([model deviceId] == 0) [deviceIDTextField setStringValue: @"0 (DP5)"];
    else
    if([model deviceId] == 1) [deviceIDTextField setStringValue: @"1 (PX5)"];
    else
    if([model deviceId] == 2) [deviceIDTextField setStringValue: @"2 (DP5G)"];
    else
    if([model deviceId] == 3) [deviceIDTextField setStringValue: @"3 (MCA8000D)"];
    else
    if([model deviceId] == 4) [deviceIDTextField setStringValue: @"4 (TB5)"];
    else
	[deviceIDTextField setIntegerValue: [model deviceId]];
}

- (void) boardTemperatureChanged:(NSNotification*)aNote
{
	[boardTemperatureTextField setIntValue: [model boardTemperature]];
}

- (void) slowCounterChanged:(NSNotification*)aNote
{
	[slowCounterTextField setIntValue: [model slowCounter]];
}

- (void) fastCounterChanged:(NSNotification*)aNote
{
	[fastCounterTextField setIntValue: [model fastCounter]];
}

- (void) realTimeChanged:(NSNotification*)aNote
{
	[realTimeTextField setIntValue: [model realTime]];
}

- (void) acquisitionTimeChanged:(NSNotification*)aNote
{
	[acquisitionTimeTextField setIntValue: [model acquisitionTime]];
}

- (void) dropFirstSpectrumChanged:(NSNotification*)aNote
{
    //DEBUG         NSLog(@"Called %@::%@! [model dropFirstSpectrum] %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[model dropFirstSpectrum]);//TODO: DEBUG -tb-
	[dropFirstSpectrumCB setIntValue: [model dropFirstSpectrum]];
}

- (void) autoReadbackSetpointChanged:(NSNotification*)aNote
{
	[autoReadbackSetpointCB setIntValue: [model autoReadbackSetpoint]];
}

// command table view
//----------------------
- (void) populateCommandTableView
{ //unused
}





//others
//-------
- (void) commandTableChanged:(NSNotification*)aNote
{
    //DEBUG    
        NSLog(@"Called %@::%@  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    [commandTableView  reloadData];
}


- (void) commandQueueCountChanged:(NSNotification*)aNotification
{
    //DEBUG    
        NSLog(@"Called %@::%@  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[commandQueueCountField setIntValue:[model commandQueueCount]];
    [commandQueueValueBar setNeedsDisplay:YES];
}



- (void) isPollingSpectrumChanged:(NSNotification*)aNote
{
	//[isPollingSpectrumIndicator setIntValue: [model isPollingSpectrum]];
    if([model isPollingSpectrum]){
	    [isPollingSpectrumIndicator  startAnimation: nil];
    }else{
	    [isPollingSpectrumIndicator  stopAnimation: nil];
    }
}

- (void) spectrumRequestRateChanged:(NSNotification*)aNote
{
	//[spectrumRequestRatePU setIntValue: [model spectrumRequestRate]];
	[spectrumRequestRatePU selectItemWithTag: [model spectrumRequestRate]];
}

- (void) spectrumRequestTypeChanged:(NSNotification*)aNote
{
	//[spectrumRequestTypePU setIntValue: [model spectrumRequestType]];
	[spectrumRequestTypePU selectItemAtIndex: [model spectrumRequestType]-1];
}

- (void) numSpectrumBinsChanged:(NSNotification*)aNote
{
	//[numSpectrumBinsPU setIntValue: [model numSpectrumBins]];
    int val=[model numSpectrumBins];
    val = val >> 8;//minimum is 256 = 0x100
    int i,index=0;
    for(i=0; i<6;i++){
        if(val & 0x1) break;
        index++;
        val = val >> 1;
    }
    if(index==6)     NSLog(@"ERROR in %@::%@! numBins larger than 8192!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-

	[numSpectrumBinsPU selectItemAtIndex: index];
}

- (void) textCommandChanged:(NSNotification*)aNote
{
	[textCommandTextField setStringValue: [model textCommand]];
}

- (void) resetEventCounterAtRunStartChanged:(NSNotification*)aNote
{
	[resetEventCounterAtRunStartCB setIntValue: [model resetEventCounterAtRunStart]];
}

- (void) lowLevelRegInHexChanged:(NSNotification*)aNote
{
	//[lowLevelRegInHexPU setIntValue: [model lowLevelRegInHex]];
    [self endEditing];
	[lowLevelRegInHexPU selectItemAtIndex: [model lowLevelRegInHex]];
    if([model lowLevelRegInHex]){
        [regWriteValueTextField setFormatter: regWriteValueTextFieldFormatter];
    }else {
        [regWriteValueTextField setFormatter: nil];
    }

    [self writeValueChanged:nil];
}

- (void) statusHighRegChanged:(NSNotification*)aNote
{
            //DEBUG OUTPUT:
            static int debFlag=1;if(debFlag) NSLog(@"   %@::%@: UNDER CONSTRUCTION \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));debFlag=0;//TODO: DEBUG testing ...-tb-
return;
//TODO: rm   slt - - 	[statusHighRegTextField setIntValue: [model statusHighReg]];
}

- (void) statusLowRegChanged:(NSNotification*)aNote
{
            //DEBUG OUTPUT:
            static int debFlag=1;if(debFlag) NSLog(@"   %@::%@: UNDER CONSTRUCTION \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));debFlag=0;//TODO: DEBUG testing ...-tb-
return;
//TODO: rm   slt - - 	[statusLowRegTextField setIntValue: [model statusLowReg]];
}

- (void) takeADCChannelDataChanged:(NSNotification*)aNote
{
	[takeADCChannelDataCB setIntValue: [model takeADCChannelData]];
}

- (void) takeRawUDPDataChanged:(NSNotification*)aNote
{
	[takeRawUDPDataCB setIntValue: [model takeRawUDPData]];
}



//TODO: remove
#if 0
- (void) chargeBBFileChanged:(NSNotification*)aNote
{
	[chargeBBFileTextField setStringValue: [model chargeBBFile]];
}

- (void) useBroadcastIdBBChanged:(NSNotification*)aNote
{
	//debug     NSLog(@"Called %@::%@! %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[model useBroadcastIdBB]);//TODO: DEBUG -tb-
	[useBroadcastIdBBCB setIntValue: [model useBroadcastIdBB]];
}

- (void) idBBforWCommandChanged:(NSNotification*)aNote
{
	//debug     NSLog(@"Called %@::%@! %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[model idBBforWCommand]);//TODO: DEBUG -tb-
	[idBBforWCommandTextField setIntValue: [model idBBforWCommand]];
}

- (void) takeEventDataChanged:(NSNotification*)aNote
{
	[takeEventDataCB setIntValue: [model takeEventData]];
}

- (void) takeUDPstreamDataChanged:(NSNotification*)aNote
{
	[takeUDPstreamDataCB setIntValue: [model takeUDPstreamData]];
}

- (void) crateUDPDataCommandChanged:(NSNotification*)aNote
{
	[crateUDPDataCommandTextField setStringValue: [model crateUDPDataCommand]];
}

- (void) BBCmdFFMaskChanged:(NSNotification*)aNote
{
	[BBCmdFFMaskTextField setIntValue: [model BBCmdFFMask]];
   	int i;
	for(i=0;i<8;i++){
		//[[BBCmdFFMaskMatrix cellWithTag:i] setIntValue: ([model BBCmdFFMask] & (0x1 <<i))];//cellWithTag:i is not defined for all i, but it works anyway
	}    

}

- (void) cmdWArg4Changed:(NSNotification*)aNote
{
	[cmdWArg4TextField setIntValue: [model cmdWArg4]];
}

- (void) cmdWArg3Changed:(NSNotification*)aNote
{
	[cmdWArg3TextField setIntValue: [model cmdWArg3]];
}

- (void) cmdWArg2Changed:(NSNotification*)aNote
{
	[cmdWArg2TextField setIntValue: [model cmdWArg2]];
}

- (void) cmdWArg1Changed:(NSNotification*)aNote
{
	[cmdWArg1TextField setIntValue: [model cmdWArg1]];
}
#endif













- (void) sltDAQModeChanged:(NSNotification*)aNote
{
	//[sltDAQModeTextField setIntValue: [model sltDAQMode]];
	//[sltDAQModePU setIntValue: [model sltDAQMode]];
    //[sltDAQModePU selectItemWithTag:[model sltDAQMode]];
    //[sltDAQModePU selectItemWithTag:0];
    [sltDAQModePU selectItemWithTag:0];
}




//TODO: rm   slt - - 
#if 0

- (void) numRequestedUDPPacketsChanged:(NSNotification*)aNote
{
	[numRequestedUDPPacketsTextField setIntValue: [model numRequestedUDPPackets]];
}



- (void) crateUDPDataReplyPortChanged:(NSNotification*)aNote
{
	[crateUDPDataReplyPortTextField setIntValue: [model crateUDPDataReplyPort]];
}

- (void) crateUDPDataIPChanged:(NSNotification*)aNote
{
	[crateUDPDataIPTextField setStringValue: [model crateUDPDataIP]];
}

- (void) crateUDPDataPortChanged:(NSNotification*)aNote
{
	[crateUDPDataPortTextField setIntValue: [model crateUDPDataPort]];
}
- (void) eventFifoStatusRegChanged:(NSNotification*)aNote
{
	//[eventFifoStatusRegTextField setIntValue: [model eventFifoStatusReg]];
	//[countersMatrix setIntValue: [model eventFifoStatusReg]];
	//[[countersMatrix cellWithTag:0] setStringValue: [NSString stringWithFormat:@"%qu",[model clockTime]]];
	[[countersMatrix cellWithTag:0] setIntValue:  ([model eventFifoStatusReg]&0x7ff) ];
	if([model eventFifoStatusReg]&0x400) [[countersMatrix cellWithTag:1] setStringValue:  @"EMPTY" ];
	else if([model eventFifoStatusReg]&0x800) [[countersMatrix cellWithTag:1] setStringValue:  @"OVFL" ];
	else  [[countersMatrix cellWithTag:1] setStringValue:  @"0" ];
}

- (void) pixelBusEnableRegChanged:(NSNotification*)aNote
{
	[pixelBusEnableRegTextField setIntValue: [model pixelBusEnableReg]];
	int i;
	for(i=0;i<20;i++){
		[[pixelBusEnableRegMatrix cellWithTag:i] setIntValue: ([model pixelBusEnableReg] & (0x1 <<i))];
	}    


}

- (void) selectedFifoIndexChanged:(NSNotification*)aNote
{
	[selectedFifoIndexPU selectItemWithTag: [model selectedFifoIndex]];
}
#endif







- (void) isListeningOnServerSocketChanged:(NSNotification*)aNote//used for AmpTek DP5???
{
    if([model isListeningOnServerSocket]){
	    [listeningForReplyIndicator  startAnimation: nil];
		[startListeningForReplyButton setEnabled:NO];
		[stopListeningForReplyButton setEnabled:YES];
	}
    else
	{
	    [listeningForReplyIndicator  stopAnimation: nil];
		[startListeningForReplyButton setEnabled:YES];
		[stopListeningForReplyButton setEnabled:NO];
	}
}





#if 0
- (void) isListeningOnDataServerSocketChanged:(NSNotification*)aNote
{
	//[isListeningOnDataServerSocketNo Outlet setIntValue: [model isListeningOnDataServerSocket]];
	//TODO:  START PROGRESS INDICATOR etc
    if([model isListeningOnDataServerSocket]){
	    [listeningForDataReplyIndicator  startAnimation: nil];
		[startListeningForDataReplyButton setEnabled:NO];
		[stopListeningForDataReplyButton setEnabled:YES];
	}
    else
	{
	    [listeningForDataReplyIndicator  stopAnimation: nil];
		[startListeningForDataReplyButton setEnabled:YES];
		[stopListeningForDataReplyButton setEnabled:NO];
	}
}


#endif





- (void) crateUDPCommandChanged:(NSNotification*)aNote
{
	[crateUDPCommandTextField setStringValue: [model crateUDPCommand]];
}



#if 0
- (void) crateUDPReplyPortChanged:(NSNotification*)aNote
{
	[crateUDPReplyPortTextField setIntValue: [model crateUDPReplyPort]];
}
#endif









- (void) crateUDPCommandIPChanged:(NSNotification*)aNote
{
	[crateUDPCommandIPTextField setStringValue: [model crateUDPCommandIP]];
}

- (void) crateUDPCommandPortChanged:(NSNotification*)aNote
{
	[crateUDPCommandPortTextField setIntValue: [model crateUDPCommandPort]];
}


- (void) openCommandSocketChanged:(NSNotification*)aNote//used for AmpTek DP5
{
    if([model isOpenCommandSocket]){
	    [openCommandSocketIndicator  startAnimation: nil];
        [openCommandSocketTextField setStringValue:@"Connected"];
		[openCommandSocketButton setEnabled:NO];
		[closeCommandSocketButton setEnabled:YES];
	}
    else
	{
	    [openCommandSocketIndicator  stopAnimation: nil];
        [openCommandSocketTextField setStringValue:@"Not Connected"];
		[openCommandSocketButton setEnabled:YES];
		[closeCommandSocketButton setEnabled:NO];
	}

}



#if 0
- (void) openDataCommandSocketChanged:(NSNotification*)aNote
{
    if([model isOpenDataCommandSocket]){
	    [openDataCommandSocketIndicator  startAnimation: nil];
		[openDataCommandSocketButton setEnabled:NO];
		[closeDataCommandSocketButton setEnabled:YES];
	}
    else
	{
	    [openDataCommandSocketIndicator  stopAnimation: nil];
		[openDataCommandSocketButton setEnabled:YES];
		[closeDataCommandSocketButton setEnabled:NO];
	}

}
#endif






- (void) sltScriptArgumentsChanged:(NSNotification*)aNote
{
	[sltScriptArgumentsTextField setStringValue: [model sltScriptArguments]];
}


- (void) clockTimeChanged:(NSNotification*)aNote
{
 	//NSLog(@"   %@::%@:   clockTime: 0x%016qx   \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[model clockTime]);//TODO: DEBUG testing ...-tb-
	//[[countersMatrix cellWithTag:3] setIntValue:[model clockTime]];  //setIntValue seems not to work for 64-bit integer? -tb-
	[[countersMatrix cellWithTag:3] setStringValue: [NSString stringWithFormat:@"%qu",[model clockTime]]];
}



- (void) statusRegChanged:(NSNotification*)aNote
{
	uint32_t statusReg = [model statusReg];
//DEBUG OUTPUT:  NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! status reg: 0x%08x\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),statusReg);//TODO: DEBUG testing ...-tb-
	
	[[statusMatrix cellWithTag:0] setStringValue: IsBitSet(statusReg,kEWStatusIrq)?@"1":@"0"];
	[[statusMatrix cellWithTag:1] setStringValue: IsBitSet(statusReg,kEWStatusPixErr)?@"1":@"0"];

	[[statusMatrix cellWithTag:2] setStringValue: [NSString stringWithFormat:@"0x%04x",ExtractValue(statusReg,0xffff,0)]];

}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	//[super tabView:aTabView didSelectTabViewItem:tabViewItem];   //TODO: SBC_LinkController ist als Klasse dazwischengeschoben und bekommt hierdurch message-Kopie -tb-
	
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:controlSize];			break;
		case  1: [self resizeWindowToSize:statusSize];			break;
		case  2: [self resizeWindowToSize:lowLevelSize];	    break;
		case  3: [self resizeWindowToSize:networkConnectionSize];	break;
		case  4: [self resizeWindowToSize:testSize];	    break;
		case  5: [self resizeWindowToSize:aboutSize];				break;
		default: [self resizeWindowToSize:controlSize];	            break;
    }
}

- (void) patternFilePathChanged:(NSNotification*)aNote
{
	NSString* thePath = [[model patternFilePath] stringByAbbreviatingWithTildeInPath];
	if(!thePath)thePath = @"---";
	[patternFilePathField setStringValue: thePath];
}

- (void) pollRateChanged:(NSNotification*)aNotification
{
    if(aNotification== nil || [aNotification object] == [model poller]){
        [pollRatePopup selectItemAtIndex:[pollRatePopup indexOfItemWithTag:[[model poller] timeInterval]]];
    }
}

- (void) pollRunningChanged:(NSNotification*)aNotification
{
    if(aNotification== nil || [aNotification object] == [model poller]){
        if([[model poller] isRunning])[pollRunningIndicator startAnimation:self];
        else [pollRunningIndicator stopAnimation:self];
    }
}

- (void) nextPageDelayChanged:(NSNotification*)aNote
{
	[nextPageDelaySlider setIntegerValue:100-[model nextPageDelay]];
	[nextPageDelayField  setFloatValue:[model nextPageDelay]*102.3/100.];
}


- (void) pageSizeChanged:(NSNotification*)aNote
{
	[pageSizeField setIntegerValue: [model pageSize]];
	[pageSizeStepper setIntegerValue: [model pageSize]];
}


- (void) updateWindow
{
    [super updateWindow];
    [self setWindowTitle];
	[self hwVersionChanged:nil];
	[self controlRegChanged:nil];
    [self writeValueChanged:nil];
    [self pulserAmpChanged:nil];
    [self pulserDelayChanged:nil];
    [self selectedRegIndexChanged:nil];
	[self pageSizeChanged:nil];	
	[self displayEventLoopChanged:nil];	
	[self displayTriggerChanged:nil];	
	[self nextPageDelayChanged:nil];
    [self pollRateChanged:nil];
    [self pollRunningChanged:nil];
	[self patternFilePathChanged:nil];
	[self statusRegChanged:nil];
	[self clockTimeChanged:nil];
	[self sltScriptArgumentsChanged:nil];
	[self crateUDPCommandPortChanged:nil];
	[self crateUDPCommandIPChanged:nil];
	[self crateUDPCommandChanged:nil];
	[self isListeningOnServerSocketChanged:nil];
    
    [self openCommandSocketChanged:nil];
    
    
    
#if 0
	[self selectedFifoIndexChanged:nil];
	[self pixelBusEnableRegChanged:nil];
	[self eventFifoStatusRegChanged:nil];
    
    
    [self openDataCommandSocketChanged:nil];
	[self crateUDPDataPortChanged:nil];
	[self crateUDPDataIPChanged:nil];
	[self crateUDPDataReplyPortChanged:nil];
	[self isListeningOnDataServerSocketChanged:nil];
#endif



	[self sltDAQModeChanged:nil];
//TODO: rm   slt - - 
#if 0
	[self crateUDPDataCommandChanged:nil];
	[self numRequestedUDPPacketsChanged:nil];
	[self cmdWArg1Changed:nil];
	[self cmdWArg2Changed:nil];
	[self cmdWArg3Changed:nil];
	[self cmdWArg4Changed:nil];
	[self BBCmdFFMaskChanged:nil];
	[self takeUDPstreamDataChanged:nil];
	[self takeEventDataChanged:nil];
	[self idBBforWCommandChanged:nil];
	[self useBroadcastIdBBChanged:nil];
	[self chargeBBFileChanged:nil];
	[self statusLowRegChanged:nil];
	[self statusHighRegChanged:nil];
#endif
	[self takeRawUDPDataChanged:nil];
	[self takeADCChannelDataChanged:nil];
	[self lowLevelRegInHexChanged:nil];
	[self resetEventCounterAtRunStartChanged:nil];
	[self textCommandChanged:nil];
	[self numSpectrumBinsChanged:nil];
	[self spectrumRequestTypeChanged:nil];
	[self spectrumRequestRateChanged:nil];
	[self isPollingSpectrumChanged:nil];
	[self autoReadbackSetpointChanged:nil];
	[self dropFirstSpectrumChanged:nil];
	[self acquisitionTimeChanged:nil];
	[self realTimeChanged:nil];
	[self fastCounterChanged:nil];
	[self slowCounterChanged:nil];
	[self boardTemperatureChanged:nil];
	[self deviceIDChanged:nil];
	[self detectorTemperatureChanged:nil];
	[self FirmwareFPGAVersionChanged:nil];
	[self serialNumberChanged:nil];
}

- (void) setWindowTitle
{
	[[self window] setTitle: [NSString stringWithFormat:@"Amptek DP5 - %u",[model uniqueIdNumber]]];
}

- (void) checkGlobalSecurity
{
    [super checkGlobalSecurity]; 
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:[model sbcLockName] to:secure];
}


- (void) settingsLockChanged:(NSNotification*)aNotification
{
    //[super settingsLockChanged:aNotification];        //TODO: SBC_LinkController ist als Klasse dazwischengeschoben und bekommt hierdurch message-Kopie -tb-
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORAmptekDP5SettingsLock];
    BOOL locked = [gSecurity isLocked:ORAmptekDP5SettingsLock];
	BOOL isRunning = [gOrcaGlobals runInProgress];
	
	
	[hwVersionButton setEnabled:!isRunning];

	[loadPatternFileButton setEnabled:!lockedOrRunningMaintenance];
	[definePatternFileButton setEnabled:!lockedOrRunningMaintenance];
	[setSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[relSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[resetPageManagerButton setEnabled:!lockedOrRunningMaintenance];
	[forceTriggerButton setEnabled:!lockedOrRunningMaintenance];
	[initBoardButton setEnabled:!lockedOrRunningMaintenance];
	[initBoard1Button setEnabled:!lockedOrRunningMaintenance];
	[readBoardButton setEnabled:!lockedOrRunningMaintenance];
	[secStrobeSrcPU setEnabled:!lockedOrRunningMaintenance]; 
	
	[setSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[relSWInhibitButton setEnabled:!lockedOrRunningMaintenance];
	[forceTrigger1Button setEnabled:!lockedOrRunningMaintenance];

	[resetHWButton setEnabled:!isRunning];
	
	[pulserAmpField setEnabled:!locked];
		
	[pageSizeField setEnabled:!lockedOrRunningMaintenance];
	[pageSizeStepper setEnabled:!lockedOrRunningMaintenance];
	
	
	[nextPageDelaySlider setEnabled:!lockedOrRunningMaintenance];
	
	[self enableRegControls];
}

- (void) enableRegControls
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORAmptekDP5SettingsLock];
	short index = [model selectedRegIndex];
	BOOL readAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegReadable)>0;
	BOOL writeAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegWriteable)>0;
//TODO: rm   slt - -	BOOL needsIndex = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegNeedsIndex)>0;
	
	[regWriteButton setEnabled:writeAllowed];
	[regReadButton setEnabled:readAllowed];
	
	[regWriteValueStepper setEnabled:writeAllowed];
	[regWriteValueTextField setEnabled:writeAllowed];

//TODO: rm   slt - -    [selectedFifoIndexPU setEnabled: needsIndex];
}

- (void) endAllEditing:(NSNotification*)aNotification
{
}

- (void) hwVersionChanged:(NSNotification*) aNote
{
	NSString* s = [NSString stringWithFormat:@"%u,0x%x,0x%x",[model projectVersion],[model documentVersion],[model implementation]];
	[hwVersionField setStringValue:s];
}

- (void) writeValueChanged:(NSNotification*) aNote
{
	[self updateStepper:regWriteValueStepper setting:[model writeValue]];
    [regWriteValueTextField setIntegerValue:[model writeValue]];
}

- (void) displayEventLoopChanged:(NSNotification*) aNote
{
	[displayEventLoopButton setState:[model displayEventLoop]];
}

- (void) displayTriggerChanged:(NSNotification*) aNote
{
	[displayTriggerButton setState:[model displayTrigger]];
}


- (void) selectedRegIndexChanged:(NSNotification*) aNote
{
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerPopUp	 setting:index];
	
	[self enableRegControls];
}


- (void) controlRegChanged:(NSNotification*)aNote
{
	uint32_t value = [model controlReg];
	
	[[miscCntrlBitsMatrix cellWithTag:0] setIntValue:value & kCtrlInvert];
	[[miscCntrlBitsMatrix cellWithTag:1] setIntValue:value & kCtrlLedOff];
	[[miscCntrlBitsMatrix cellWithTag:2] setIntValue:value & kCtrlOnLine];
	[controlRegNumFifosTextField setIntegerValue:(value & kCtrlNumFIFOs)>>28];
}

- (void) populatePullDown
{
    short	i;
	
	// Clear all the popup items.
    [registerPopUp removeAllItems];
    
	// Populate the register popup
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerPopUp insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }



//TODO: rm   slt - -
#if 0
	// Clear all the popup items.
    [selectedFifoIndexPU removeAllItems];
    
	// Populate the register popup
    for (i = 0; i < 16; i++) {
        [selectedFifoIndexPU insertItemWithTitle: [NSString stringWithFormat: @"%i",i ] atIndex:i];
        [[selectedFifoIndexPU itemAtIndex:i] setTag: i]; //I am not using the tag ... -tb-
    }
    [selectedFifoIndexPU insertItemWithTitle: @"All" atIndex:i];
    [[selectedFifoIndexPU itemAtIndex:i] setTag: i];//TODO: do I need this??? -tb-
#endif

}

- (void) pulserAmpChanged:(NSNotification*) aNote
{
	[pulserAmpField setFloatValue:[model pulserAmp]];
}

- (void) pulserDelayChanged:(NSNotification*) aNote
{
	[pulserDelayField setFloatValue:[model pulserDelay]];
}




#pragma mark ***Actions

- (void) dropFirstSpectrumCBAction:(id)sender
{
    //DEBUG OUTPUT:       
     NSLog(@"   %@::%@: UNDER CONSTRUCTION %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[sender intValue]);//TODO: DEBUG testing ...-tb-

	[model setDropFirstSpectrum:[sender intValue]];	
}

- (void) autoReadbackSetpointCBAction:(id)sender
{
	[model setAutoReadbackSetpoint:[sender intValue]];	
}
- (IBAction) debugButtonAction:(id)sender
{
    //DEBUG    
        NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    NSLog(@"CommandTable:%@\n", [model commandTable]);
    
}

- (IBAction) clearCommandQueueButtonAction:(id)sender
{
    //DEBUG    
        NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    [model clearCommandQueue];
    
}

- (IBAction) sendCommandOfCommandQueueButtonAction:(id)sender
{
    //DEBUG    
        NSLog(@"Called %@::%@ calling processOneCommandFromQueue\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    [model processOneCommandFromQueue];
    
}

- (IBAction) dumpCommandQueueButtonAction:(id)sender
{
    //DEBUG    
        NSLog(@" %@::%@ Command Queue is:>%@<\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[model commandQueue]);//TODO: DEBUG -tb-
    ;
    
}


- (void) readAllCommandSettingsButtonAction:(id)sender
{
    //DEBUG            NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    [model readbackCommandTableAsTextCommand];
}

- (void) writeAllCommandSettingsButtonAction:(id)sender
{
    //DEBUG            
    NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    [model writeCommandTableSettingsAsTextCommand];
}


- (void) readSelectedCommandSettingButtonAction:(id)sender
{
    //DEBUG    
        NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    //DEBUG     
           NSLog(@"Called %@::%@! index %i [sender intValue] %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[commandTableView selectedRow],[commandTableView intValue]);//TODO: DEBUG -tb-
NSLog(@"sender: %p, commandTableView:%p\n",sender,commandTableView);
    int row=(int)[commandTableView selectedRow];
    if(row<0){
        NSLog(@"Nothing selected!\n");
        return;
    }
    [model readbackCommandOfRow:row];
}

- (void) writeSelectedCommandSettingButtonAction:(id)sender
{
    //DEBUG    
        NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    int row=(int)[commandTableView selectedRow];
    if(row<0){
        NSLog(@"Nothing selected!\n");
        return;
    }
    [model writeCommandOfRow:row];
    if([model autoReadbackSetpoint]){
        [model readbackCommandOfRow:row];
    }

}






- (IBAction) openCommandsFromCSVFileButtonAction:(id)sender
{
    //DEBUG    
        NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];   
    [openPanel setTitle: @"Open AmptekDP5 Command Table File"];
    
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString *filename = [[openPanel URL]path];
            NSLog( @"You selected filename: %@\n",filename);
            BOOL loadOK = [model loadCommandTableFile: filename];	
            if (loadOK) {
                NSLog( @"Loaded file: %@\n",filename);
                //[commandTableView  reloadData];
            }
            else{
                NSLog( @"ERROR: Could not load file: %@\n",filename);
            }
        }
    }];

}

- (IBAction) saveCommandsAsCSVFileButtonAction:(id)sender
{
    //DEBUG    
        NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-

    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
	//[op setMessage: @"Save the Config File ..."];
	[savePanel setNameFieldLabel: @"Save as:"];
	//[op setNameFieldStringValue: @"config.txt"];
	[savePanel setTitle: @"Save AmptekDP5 Command Table File"];
	[savePanel setAllowedFileTypes: nil];
	[savePanel setAllowsOtherFileTypes: YES];
	[savePanel setCanSelectHiddenExtension: YES];
    
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString *filename = [[savePanel URL]path];
            NSLog( @"You selected filename: %@\n",filename);

            BOOL saveOK = [model saveAsCommandTableFile: filename];
            if (saveOK) {
                NSLog( @"Saved file: %@\n",filename);
            }
            else{
                NSLog( @"ERROR: Could not save file: %@\n",filename);
            }
            
        }
    }];
}








- (void) spectrumRequestRatePUAction:(id)sender
{
	//[model setSpectrumRequestRate:[sender intValue]];	
	[model setSpectrumRequestRate:(int)[[spectrumRequestRatePU selectedItem] tag]];
}

- (void) spectrumRequestNowButtonAction:(id)sender
{
    [model requestSpectrum];
}


- (void) spectrumRequestTypePUAction:(id)sender
{
	[model setSpectrumRequestType:(int)[sender indexOfSelectedItem]+1];
}

- (void) numSpectrumBinsPUAction:(id)sender
{
    NSLog(@"Called %@::%@! index %i [sender intValue] %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[sender indexOfSelectedItem],[sender intValue]);//TODO: DEBUG -tb-
    int numBins=0;
    numBins = 256 << ([sender indexOfSelectedItem]);
	[model setNumSpectrumBins:numBins];	
}

- (void) textCommandTextFieldAction:(id)sender
{
	[model setTextCommand:[sender stringValue]];	
}

- (void) resetEventCounterAtRunStartCBAction:(id)sender
{
	[model setResetEventCounterAtRunStart:[sender intValue]];	
}

- (void) lowLevelRegInHexPUAction:(id)sender /*lowLevelRegInHexPU*/
{
	//[model setLowLevelRegInHex:[sender intValue]];	
	[model setLowLevelRegInHex:(int)[sender indexOfSelectedItem]];
}

- (void) statusHighRegTextFieldAction:(id)sender
{
//TODO: rm   slt - - 	[model setStatusHighReg:[sender intValue]];	
}

- (void) statusLowRegTextFieldAction:(id)sender
{
//TODO: rm   slt - - 	[model setStatusLowReg:[sender intValue]];	
}

- (void) takeADCChannelDataCBAction:(id)sender
{
	[model setTakeADCChannelData:[sender intValue]];	
}

- (void) takeRawUDPDataCBAction:(id)sender
{
	[model setTakeRawUDPData:[sender intValue]];	
}





//TODO: remove
#if 0
- (void) chargeBBFileTextFieldAction:(id)sender
{
	[model setChargeBBFile:[sender stringValue]];	
}

- (void) useBroadcastIdBBCBAction:(id)sender
{
	[model setUseBroadcastIdBB:[sender intValue]];	
}

- (void) idBBforWCommandTextFieldAction:(id)sender
{
	[model setIdBBforWCommand:[sender intValue]];	
}

- (void) takeEventDataCBAction:(id)sender
{
	[model setTakeEventData:[sender intValue]];	
}

- (void) takeUDPstreamDataCBAction:(id)sender
{
	[model setTakeUDPstreamData:[sender intValue]];	
}

- (void) crateUDPDataCommandTextFieldAction:(id)sender
{
	[model setCrateUDPDataCommand:[sender stringValue]];	
}

- (void) BBCmdFFMaskTextFieldAction:(id)sender
{
	[model setBBCmdFFMask:[sender intValue]];	
}


- (IBAction) BBCmdFFMaskMatrixAction:(id)sender
{
	//debug 
    NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	int i,val=0;
	for(i=0;i<8;i++){
        //NSLog(@"Called %@::%@   cell with tag %i, id:%p intVal:%i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),i,[sender cellWithTag:i],[[sender cellWithTag:i] intValue]);//TODO: DEBUG -tb-
        ////cellWithTag:i is not defined for all i, but it works anyway: it returns 0 and [0 intValue] is 0, so nothing is set in this case -tb-
        if([[BBCmdFFMaskMatrix cellWithTag:i] intValue]) val |= (0x1<<i);
	}
	[model setBBCmdFFMask:val];
}


- (void) cmdWArg4TextFieldAction:(id)sender
{
	[model setCmdWArg4:[sender intValue]];	
}

- (void) cmdWArg3TextFieldAction:(id)sender
{
	[model setCmdWArg3:[sender intValue]];	
}

- (void) cmdWArg2TextFieldAction:(id)sender
{
	[model setCmdWArg2:[sender intValue]];	
}

- (void) cmdWArg1TextFieldAction:(id)sender
{
	[model setCmdWArg1:[sender intValue]];	
}
#endif

- (IBAction) sltDAQModePUAction:(id)sender
{
	[model setSltDAQMode:(int)[[sltDAQModePU selectedItem] tag]];
	//[model setSltDAQMode:[[sender selectedItem] tag]];	
}





- (void) sltDAQModeTextFieldAction:(id)sender
{
	[model setSltDAQMode:[sender intValue]];	
}

- (IBAction) readAllControlSettingsFromHWButtonAction:(id)sender
{
	[model readAllControlSettingsFromHW];
}







//TODO: rm
#if 0
- (void) eventFifoStatusRegTextFieldAction:(id)sender
{
	[model setEventFifoStatusReg:[sender intValue]];	
}

- (void) pixelBusEnableRegTextFieldAction:(id)sender
{
	[model setPixelBusEnableReg:[sender intValue]];	
}


- (void) pixelBusEnableRegMatrixAction:(id)sender
{
    //debug
	NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
//	[model setPixelBusEnableReg:[sender intValue]];	
	int i, val=0;
	for(i=0;i<20;i++){
		if([[sender cellWithTag:i] intValue]) val |= (0x1<<i);
	}
	[model setPixelBusEnableReg:val];
}

- (IBAction) writePixelBusEnableRegButtonAction:(id)sender
{
	[model writePixelBusEnableReg];	
}

- (IBAction) readPixelBusEnableRegButtonAction:(id)sender
{
	[model readPixelBusEnableReg];	
}



- (IBAction) writeControlRegButtonAction:(id)sender
{
	[model writeControlReg];	
}

- (IBAction) readControlRegButtonAction:(id)sender
{
	[model readControlReg];	
}

#endif








#if 0
- (void) selectedFifoIndexPUAction:(id)sender
{
	[model setSelectedFifoIndex:[sender indexOfSelectedItem]];	//sender is selectedFifoIndexPU
}


//ADC data UDP connection
- (IBAction) startUDPDataConnectionButtonAction:(id)sender
{
    [self openDataCommandSocketButtonAction:nil];
    [self startListeningForDataReplyButtonAction:nil];
}

- (IBAction) stopUDPDataConnectionButtonAction:(id)sender
{
    [self closeDataCommandSocketButtonAction:nil];
    [self stopListeningForDataReplyButtonAction:nil];
}

- (void) crateUDPDataReplyPortTextFieldAction:(id)sender
{
	[model setCrateUDPDataReplyPort:[sender intValue]];	
}

- (void) crateUDPDataIPTextFieldAction:(id)sender
{
	[model setCrateUDPDataIP:[sender stringValue]];	
}

- (void) crateUDPDataPortTextFieldAction:(id)sender
{
	[model setCrateUDPDataPort:[sender intValue]];	
}

- (IBAction) openDataCommandSocketButtonAction:(id)sender
{
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model openDataCommandSocket];	
    //[self openDataCommandSocketChanged:nil];
}


- (IBAction) closeDataCommandSocketButtonAction:(id)sender
{
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model closeDataCommandSocket];	
    //[self openDataCommandSocketChanged:nil];
}


- (IBAction) startListeningForDataReplyButtonAction:(id)sender
{
    //debug 	NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model startListeningDataServerSocket];	
}

- (IBAction) stopListeningForDataReplyButtonAction:(id)sender
{
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model stopListeningDataServerSocket];	
}

- (IBAction) crateUDPDataRequestDataPCommandSendButtonAction:(id)sender
{
    [self endEditing];
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model sendUDPDataCommandRequestUDPData];	
}

- (IBAction) crateUDPDataChargeBBFileCommandSendButtonAction:(id)sender
{
    [self endEditing];
	//debug 
    NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model sendUDPDataCommandChargeBBFile];	
}

- (void) numRequestedUDPPacketsTextFieldAction:(id)sender
{
	[model setNumRequestedUDPPackets:[sender intValue]];	
}

- (IBAction) testUDPDataConnectionButtonAction:(id)sender
{
	//debug 
    NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model setRequestStoppingDataServerSocket:1];	
}


- (IBAction) crateUDPDataSendWCommandButtonAction:(id)sender
{
    [self endEditing];
	//debug 
    NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    [model sendUDPDataWCommandRequestPacket];

}

- (IBAction) sendUDPDataTab0x0ACommandAction:(id)sender //send 0x0A Command
{
    [self endEditing];
	//debug 
    NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    [model sendUDPDataTab0x0ACommand: [model BBCmdFFMask]];
}

- (IBAction) UDPDataTabSendBloqueCommandButtonAction:(id)sender
{
	//debug 
    NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    [model sendUDPDataTabBloqueCommand];
}

- (IBAction) UDPDataTabSendDebloqueCommandButtonAction:(id)sender
{
	//debug 
    NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    [model sendUDPDataTabDebloqueCommand];
}

- (IBAction) UDPDataTabSendDemarrageCommandButtonAction:(id)sender
{
	//debug 
    NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    [model sendUDPDataTabDemarrageCommand];
}




- (IBAction) crateUDPDataCommandSendButtonAction:(id)sender
{
    [self endEditing];
	//
    NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model sendUDPDataCommandString: [model crateUDPDataCommand]];	
}



#endif










//K command UDP connection
//UDP command Connection Start/Stop all
- (IBAction) startUDPCommandConnectionButtonAction:(id)sender
{
NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    
    [self openCommandSocketButtonAction:nil];
    //[self startListeningForReplyButtonAction:nil];
}

- (IBAction) stopUDPCommandConnectionButtonAction:(id)sender
{
NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
    [self closeCommandSocketButtonAction:nil];
    //[self stopListeningForReplyButtonAction:nil];
}

//reply socket (server)
- (IBAction) startListeningForReplyButtonAction:(id)sender
{
    //debug	
    NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model startListeningServerSocket];	
}


- (IBAction) stopListeningForReplyButtonAction:(id)sender
{
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model stopListeningServerSocket];	
}

- (void) crateUDPCommandPortTextFieldAction:(id)sender
{
	[model setCrateUDPCommandPort:[sender intValue]];	
}




//command socket (client)
- (IBAction) crateUDPCommandSendButtonAction:(id)sender
{
	//NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[self endEditing];
    [model sendUDPCommand];	
}

- (IBAction) textCommandSendButtonAction:(id)sender
{
	//NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[self endEditing];
	[model sendTextCommand];	
}

- (IBAction) textCommandReadbackButtonAction:(id)sender
{
	//NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[self endEditing];
	[model readbackTextCommand];	
}

- (IBAction) crateUDPCommandSendBinaryButtonAction:(id)sender
{
	NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model sendUDPCommandBinary];	
}

- (void) crateUDPCommandTextFieldAction:(id)sender
{
	[model setCrateUDPCommand:[sender stringValue]];	
}





//TODO: rm
#if 0
- (void) crateUDPReplyPortTextFieldAction:(id)sender
{
	[model setCrateUDPReplyPort:[sender intValue]];	
}
#endif





- (void) crateUDPCommandIPTextFieldAction:(id)sender
{
	[model setCrateUDPCommandIP:[sender stringValue]];	
}

- (IBAction) openCommandSocketButtonAction:(id)sender//AmpTek DP5
{
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model openCommandSocket];	
    [self openCommandSocketChanged:nil];//TODO: use a notification from model -tb-
}

- (IBAction) closeCommandSocketButtonAction:(id)sender
{
	//debug NSLog(@"Called %@::%@!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
	[model closeCommandSocket];	
    [self openCommandSocketChanged:nil];//TODO: use a notification from model -tb-
}







- (void) sltScriptArgumentsTextFieldAction:(id)sender
{
	[model setSltScriptArguments:[sender stringValue]];	
}


- (IBAction) miscCntrlBitsAction:(id)sender;
{
	uint32_t theRegValue = [model controlReg] & ~(kCtrlInvert | kCtrlLedOff | kCtrlOnLine); 
	if([[miscCntrlBitsMatrix cellWithTag:0] intValue])	theRegValue |= kCtrlInvert;
	if([[miscCntrlBitsMatrix cellWithTag:1] intValue])	theRegValue |= kCtrlLedOff;
	if([[miscCntrlBitsMatrix cellWithTag:2] intValue])	theRegValue |= kCtrlOnLine;

	[model setControlReg:theRegValue];
}

//----------------------------------



- (IBAction) dumpPageStatus:(id)sender
{
	if([[NSApp currentEvent] clickCount] >=2){
		//int pageIndex = [sender selectedRow]*32 + [sender selectedColumn];
		@try {
			//[model dumpTriggerRAM:pageIndex];
		}
		@catch(NSException* localException) {
			NSLog(@"Exception doing SLT dump trigger RAM page\n");
			ORRunAlertPanel([localException name], @"%@\nSLT%d dump trigger RAM failed", @"OK", nil, nil,
							localException,[model stationNumber]);
		}
	}
}

- (IBAction) pollNowAction:(id)sender
{
//DEBUG OUTPUT: 	NSLog(@"WARNING: %@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	[model readAllStatus];
}

- (IBAction) pollRateAction:(id)sender
{
    [model setPollingInterval:[[pollRatePopup selectedItem] tag]];
}



- (IBAction) nextPageDelayAction:(id)sender
{
	[model setNextPageDelay:100-[sender intValue]];	
}

- (IBAction) pageSizeAction:(id)sender
{
	[model setPageSize:[sender intValue]];	
}

- (IBAction) displayTriggerAction:(id)sender
{
	[model setDisplayTrigger:[sender intValue]];	
}


- (IBAction) displayEventLoopAction:(id)sender
{
	[model setDisplayEventLoop:[sender intValue]];	
}


- (IBAction) initBoardAction:(id)sender
{
	@try {
		[self endEditing];
		[model initBoard];
		NSLog(@"SLT%d initialized\n",[model stationNumber]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception SLT init\n");
        ORRunAlertPanel([localException name], @"%@\nSLT%d InitBoard failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) readStatus:(id)sender
{
//TODO: rm   slt - - 	[model readStatusReg];
}

- (IBAction) reportAllAction:(id)sender
{
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont, @"SLT station# %d Report:\n",[model stationNumber]);

	@try {
    
    
//TODO: rm   
//TODO: rm   implement for Amptek!!!!
//TODO: rm  
		NSLogFont(aFont, @"Board ID: %lld\n",[model readBoardID]);
//TODO: rm   slt - - 		[model printStatusReg];
//TODO: rm   slt - - 		[model printStatusLowHighReg];
//TODO: rm   slt - -		[model printControlReg];
		NSLogFont(aFont,@"--------------------------------------\n");
		NSLogFont(aFont,@"SLT Time   : %lld\n",[model getTime]);
		//[model printInterruptMask];
		//[model printInterruptRequests];
	    int32_t fdhwlibVersion = [model getFdhwlibVersion];  //TODO: write a method [model printFdhwlibVersion];
	    int ver=(fdhwlibVersion>>16) & 0xff,maj =(fdhwlibVersion>>8) & 0xff,min = fdhwlibVersion & 0xff;
	    NSLogFont(aFont,@"%@: SBC PrPMC running with fdhwlib version: %i.%i.%i (0x%08x)\n",[model fullID],ver,maj,min, fdhwlibVersion);
	    NSLogFont(aFont,@"SBC PrPMC readout code version: %i \n", [model getSBCCodeVersion]);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT status\n");
        ORRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
	
	[self hwVersionAction: self]; //display SLT firmware version, fdhwlib ver, SLT PCI driver ver
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORAmptekDP5SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) selectRegisterAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[model undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
		[self settingsLockChanged:nil];
    }
}

- (IBAction) writeValueAction:(id) aSender
{
    //sender is regWriteValueTextField
  	//NSLog(@"   %@::%@:  regWriteValueTextField:%@ (%@)\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),regWriteValueTextField,[regWriteValueTextField stringValue]);//TODO: DEBUG testing ...-tb-
	[self endEditing];
    //uint32_t converted = strtoul([[regWriteValueTextField stringValue] UTF8String] , 0,0);
  	//NSLog(@"   %@::%@:  converted:%i (0x%x)\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),converted,converted);//TODO: DEBUG testing ...-tb-
    // -> instead I use the OHexFormatter 2013-06 -tb-
    // Make sure that value has changed.
    if ([aSender intValue] != [model writeValue]){
		[[model undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) readRegAction: (id) sender
{

//TODO: implemet it
#if 0

	int index = [registerPopUp indexOfSelectedItem];
	@try {
		//uint32_t value = [model readReg:index];
		//NSLog(@"SLT reg: %@ value: 0x%x\n",[model getRegisterName:index],value);
		uint32_t value;
        if(([model getAccessType:index] & kIpeRegNeedsIndex)){
            int fifoIndex = [model selectedFifoIndex];
		    value = [model readReg:index forFifo: fifoIndex ];
		    NSLog(@"FLTv4 reg: %@  for fifo# %i has value: 0x%x (%i)\n",[model getRegisterName:index], fifoIndex, value, value);
		    //NSLog(@"  (addr: 0x%08x = 0x%08x ... 0x%08x)  \n", ([model getAddress:index]|(fifoIndex << 14)), [model getAddress:index],  (fifoIndex << 14));
        }
		else {
		    value = [model readReg:index ];
		    NSLog(@"SLTv4 reg: %@ has value: 0x%x (%i)\n",[model getRegisterName:index],value, value);
        }
	}
	@catch(NSException* localException) {
        //localException is generated by "- (void) throwError:(int)anError address:(uint32_t)anAddress" in SBC_Link.m -tb-
		NSLog(@"Exception reading SLT reg: %@\n",[model getRegisterName:index]);
        ORRunAlertPanel([localException name], @"%@\nSLT%d Access failed (B)", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
#endif
}



- (IBAction) writeRegAction: (id) sender
{

//TODO: implemet it
#if 0

	[self endEditing];
	int index = [registerPopUp indexOfSelectedItem];
	@try {
		//[model writeReg:index value:[model writeValue]];
		//NSLog(@"wrote 0x%x to SLT reg: %@ \n",[model writeValue],[model getRegisterName:index]);
		uint32_t val = [model writeValue];
        if(([model getAccessType:index] & kIpeRegNeedsIndex)){
            int fifoIndex = [model selectedFifoIndex];
		    [model writeReg:index forFifo: fifoIndex  value:val];
    		NSLog(@"wrote 0x%x (%i) to SLTv4 reg: %@ fifo# %i\n", val, val, [model getRegisterName:index], fifoIndex);
        }
		else {
		    [model writeReg:index value:val];
		    NSLog(@"wrote 0x%x to SLT reg: %@ \n",val,[model getRegisterName:index]);
        }
	}
	@catch(NSException* localException) {
		NSLog(@"Exception writing SLT reg: %@\n",[model getRegisterName:index]);
        ORRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
#endif
}

- (IBAction) hwVersionAction: (id) sender
{
	@try {
		[model readHwVersion];
		//NSLog(@"%@ Project:%d Doc:%d Implementation:%d\n",[model fullID], [model projectVersion], [model documentVersion], [model implementation]);
		NSLog(@"%@ Project:%d Doc:0x%x Implementation:0x%x\n",[model fullID], [model projectVersion], [model documentVersion], [model implementation]);
		int32_t fdhwlibVersion = [model getFdhwlibVersion];
		int ver=(fdhwlibVersion>>16) & 0xff,maj =(fdhwlibVersion>>8) & 0xff,min = fdhwlibVersion & 0xff;
	    NSLog(@"%@: SBC PrPMC running with fdhwlib version: %i.%i.%i (0x%08x)\n",[model fullID],ver,maj,min, fdhwlibVersion);
		int32_t SltPciDriverVersion = [model getSltPciDriverVersion];
		//NSLog(@"%@: SLT PCI driver version: %i\n",[model fullID],SltPciDriverVersion);
	    if(SltPciDriverVersion<0) NSLog(@"%@: unknown SLT PCI driver version: %i\n",[model fullID],SltPciDriverVersion);
        else if(SltPciDriverVersion==0) NSLog(@"%@: SBC running with SLT PCI driver version: %i (fzk_ipe_slt)\n",[model fullID],SltPciDriverVersion);
        else if(SltPciDriverVersion==1) NSLog(@"%@: SBC running with SLT PCI driver version: %i (fzk_ipe_slt_dma)\n",[model fullID],SltPciDriverVersion);
        else if(SltPciDriverVersion==4) NSLog(@"%@: SBC running with SLT PCI driver version: %i (kit_ipe_slt)\n",[model fullID],SltPciDriverVersion);
        else NSLog(@"%@: SBC running with SLT PCI driver version: %i (fzk_ipe_slt%i)\n",[model fullID],SltPciDriverVersion,SltPciDriverVersion);
        
		uint32_t presentFLTsMap = [model getPresentFLTsMap];
        NSLog(@"%@: presentFLTsMap: 0x%08x\n",[model fullID],presentFLTsMap);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading SLT HW Model Version\n");
        ORRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

//most of these are not currently connected to anything.. used during testing..
- (IBAction) configureFPGAsAction:(id)sender	{ [self do:@selector(writeFwCfg) name:@"Config FPGAs"]; }
- (IBAction) resetFLTAction:(id)sender			{ [self do:@selector(writeFltReset) name:@"FLT Reset"]; }
- (IBAction) resetSLTAction:(id)sender			{ [self do:@selector(writeSltReset) name:@"SLT Reset"]; }
- (IBAction) evResAction:(id)sender		        { [self do:@selector(writeEvRes) name:@"EvRes"]; }

- (IBAction) installIPE4readerAction:(id)sender
{
 	//
    NSLog(@"%@::%@: still under construction\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
   	//TODO: remove SLT stuff -tb-   2014 [model installIPE4reader];  

}

- (IBAction) installAndCompileIPE4readerAction:(id)sender
{
 	//
    NSLog(@"%@::%@: still under construction\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
    //TODO: remove SLT stuff -tb-   2014 [model installAndCompileIPE4reader];  

}



- (IBAction) sendCommandScript:(id)sender
{
	[self endEditing];
	//TODO: remove SLT stuff -tb-   2014 NSString *fullCommand = [NSString stringWithFormat: @"shellcommand %@",[model sltScriptArguments]];
	//TODO: remove SLT stuff -tb-   2014 [model sendPMCCommandScript: fullCommand];  
}

- (IBAction) sendSimulationConfigScriptON:(id)sender
{
	//[self killCrateAction: nil];//TODO: this seems not to be modal ??? -tb- 2010-04-27
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"This will KILL the crate process before compiling and starting simulation mode. "
     "There may be other ORCAs connected to the crate. You need to do a 'Force reload' before."];
    [alert setInformativeText:@"Is this really what you want?"];
    [alert addButtonWithTitle:@"Yes, Kill Crate"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            NSLog(@"This is my _killCrateDidEnd: -tb-\n");
#if 0
            //TODO: remove SLT stuff -tb-   2014
            [[model sbcLink] killCrate];
            BOOL rememberState = [[model sbcLink] forceReload];
            if(rememberState) [[model sbcLink] setForceReload: NO];
            [model sendSimulationConfigScriptON];
            [[model sbcLink] startCrate];
            if(rememberState !=[[model sbcLink] forceReload]) [[model sbcLink] setForceReload: rememberState];
#endif
        }
        
    }];
#else
    NSBeginAlertSheet(@"This will KILL the crate process before compiling and starting simulation mode. "
						"There may be other ORCAs connected to the crate. You need to do a 'Force reload' before.",
                      @"Cancel",
                      @"Yes, Kill Crate",
                      nil,[self window],
                      self,
                      @selector(_SLTv4killCrateAndStartSimDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Is this really what you want?");
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _SLTv4killCrateAndStartSimDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
NSLog(@"This is my _killCrateDidEnd: -tb-\n");
#if 0
//TODO: remove SLT stuff -tb-   2014 
	//called
	if(returnCode == NSAlertAlternateReturn){		
		[[model sbcLink] killCrate]; //XCode says "No '-killCrate' method found!" but it is found during runtime!! -tb- How to get rid of this warning?
		BOOL rememberState = [[model sbcLink] forceReload];
		if(rememberState) [[model sbcLink] setForceReload: NO];
		[model sendSimulationConfigScriptON];  
		//[self connectionAction: nil];
		//[self toggleCrateAction: nil];
		//[[model sbcLink] startCrate]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
		//   [[model sbcLink] startCrateProcess]; //If "Force reload" is checked the readout code will be loaded again and overwrite the simulation mode! -tb-
		[[model sbcLink] startCrate];
		if(rememberState !=[[model sbcLink] forceReload]) [[model sbcLink] setForceReload: rememberState];
	}
#endif
}
#endif


- (IBAction) sendSimulationConfigScriptOFF:(id)sender
{
	//TODO: remove SLT stuff -tb-   2014 [model sendSimulationConfigScriptOFF];  
	NSLog(@"Sending simulation-mode-off script is still under development. If it fails just stop and force-reload-start the crate.\n");
}

- (IBAction) pulserAmpAction: (id) sender
{
	[model setPulserAmp:[sender floatValue]];
}

- (IBAction) pulserDelayAction: (id) sender
{
	[model setPulserDelay:[sender floatValue]];
}

- (IBAction) loadPulserAction: (id) sender
{
	@try {
		//[model loadPulserValues];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception loading SLT pulser values\n");
        ORRunAlertPanel([localException name], @"%@\nSLT%d load pulser failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) definePatternFileAction:(id)sender
{
    NSString* startDir = NSHomeDirectory(); //default to home
    if([model patternFilePath]){
        startDir = [[model patternFilePath] stringByDeletingLastPathComponent];
        if([startDir length] == 0){
            startDir = NSHomeDirectory();
        }
    }
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Load Pattern File"];
    
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSString* fileName = [[openPanel URL] path];
            [model setPatternFilePath:fileName];
        }
    }];
}

- (IBAction) loadPatternFile:(id)sender
{
	//[model loadPatternFile];
}

- (IBAction) calibrateAction:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Threshold Calibration"];
    [alert setInformativeText:@"Really run threshold calibration for ALL FLTs?\n This will change ALL thresholds on ALL cards."];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Yes, Delete It"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertSecondButtonReturn){
            #if 0 //TODO: remove SLT stuff -tb-   2014
                @try {
                    [model autoCalibrate];
                }
                @catch(NSException* localException) {
                }
            #endif
        }
    }];
#else
    NSBeginAlertSheet(@"Threshold Calibration",
                      @"Cancel",
                      @"Yes/Do Calibrate",
                      nil,[self window],
                      self,
                      @selector(calibrationSheetDidEnd:returnCode:contextInfo:),
                      nil,
                      nil,@"Really run threshold calibration for ALL FLTs?\n This will change ALL thresholds on ALL cards.");
#endif
}





#pragma mark •••Data Source Methods (TableView)
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
	if(tableView==commandTableView){
        return [model commandTableCount];
    }



    return 0;
#if 0
    if(tableView==itemTableView){
        return [model pollingLookUpCount];
    }
	else if(tableView == pendingRequestsTable){
		return [model pendingRequestsCount];
	}
	else if(tableView == setpointRequestsQueueTableView){
		return [model setpointRequestsQueueCount];
	}
	return 0;
#endif
}


- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
//return @"till";
    if(tableView==commandTableView){
		if(row<[model commandTableCount]){
			//NSString* theIdentifier				= [tableColumn identifier];
			NSString* theIdentifier				= [[tableColumn headerCell] stringValue];
	        //DEBUG                  NSLog(@"%@::%@  theIdentifier:%@\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd),theIdentifier);//DEBUG OUTPUT -tb-  
			if([theIdentifier isEqual:@"Name"]){
                NSDictionary* theRow = [model commandTableRow:(int)row];
                return [theRow objectForKey: @"Name"];
                //return @"name";
			}
			else if([theIdentifier isEqual:@"Setpoint"]){
                NSDictionary* theRow = [model commandTableRow:(int)row];
                return [theRow objectForKey: theIdentifier];
			}
			else if([theIdentifier isEqual:@"Value"]){
                NSDictionary* theRow = [model commandTableRow:(int)row];
                return [theRow objectForKey: @"Value"];
			}
			else if([theIdentifier isEqual:@"Init"]){
                NSDictionary* theRow = [model commandTableRow:(int)row];
                return [theRow objectForKey: @"Init"];
			}
			else if([theIdentifier isEqual:@"ID"]){
                NSDictionary* theRow = [model commandTableRow:(int)row];
                return [theRow objectForKey: @"ID"];
			}
			else if([theIdentifier isEqual:@"Comment"]){
                NSDictionary* theRow = [model commandTableRow:(int)row];
                return [theRow objectForKey: @"Comment"];
                //return @"comment";
			}
			else if([theIdentifier isEqual:@"Test"]){
                NSDictionary* theRow = [model commandTableRow:(int)row];
                return [theRow objectForKey: @"Init"];
                //return @"comment";
			}
			else return @"--";
		}
	}


    return @"-";
}


- (void) tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if(tableView==commandTableView){
		if(row<[model commandTableCount]){
	        //DEBUG      
            NSLog(@"%@::%@ called for commandTableView: row %i, col identifier %@, headerCell title %@\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd),row,[tableColumn identifier],[[tableColumn headerCell] title]);//DEBUG OUTPUT -tb-  
            //title and stringValue seems to be the same -tb-
            NSLog(@"%@::%@ called for commandTableView: row %i, col identifier %@, headerCell stringValue %@\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd),row,[tableColumn identifier],[[tableColumn headerCell] stringValue]);//DEBUG OUTPUT -tb-  
			//[topLevelDictionary setObject:object forKey:[tableColumn identifier]];
            NSLog(@"%@::%@ setObjectValue is %@ (class %@)\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd),object,NSStringFromClass([object class]));//DEBUG OUTPUT -tb-  
            NSString* key = [NSString stringWithString: [[tableColumn headerCell] title]];
#if 0
            if([key isEqual:@"Name"]){
                //[model setCommandTableRow:row setObject:object forKey:@"Init"];//-tb-: works, but this is better:
                //[model setCommandTableRow:row setObject:[NSNumber numberWithInt:[object intValue]] forKey:@"Init"];
                //DEBUG    
                NSLog(@"Called %@::%@ column 'Name' is not editable!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
                return;
            }
#else
            if([key isEqual:@"Name"]){
                //[model setCommandTableRow:row setObject:object forKey:@"Init"];//-tb-: works, but this is better:
                //[model setCommandTableRow:row setObject:[NSNumber numberWithInt:[object intValue]] forKey:@"Init"];
                //DEBUG    
                NSLog(@"WARNING in %@::%@ column 'Name' MUST be unique!\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG -tb-
            }
#endif
            if([key isEqual:@"Test"]){
                //[model setCommandTableRow:row setObject:object forKey:@"Init"];//-tb-: works, but this is better:
                [model setCommandTableRow:(int)row setObject:[NSNumber numberWithInt:[object intValue]] forKey:@"Init"];
                                [commandTableView  reloadData];

                return;
            }
            [model setCommandTableRow:(int)row setObject:object forKey:key];
		}
		//[self tableViewSelectionDidChange:nil];
    }
}





@end




@implementation ORAmptekDP5Controller (private)

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) calibrationSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
#if 0 //TODO: remove SLT stuff -tb-   2014 
    if(returnCode == NSAlertAlternateReturn){
		@try {
			[model autoCalibrate];
		}
		@catch(NSException* localException) {
		}
    }    
#endif
}
#endif
- (void) do:(SEL)aSelector name:(NSString*)aName
{
	@try { 
		[model performSelector:aSelector]; 
		NSLog(@"SLT: Manual %@\n",aName);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception doing EDELWEISS SLT %@\n",aName);
        ORRunAlertPanel([localException name], @"%@\nSLT%d %@ failed", @"OK", nil, nil,
                        localException,[model stationNumber],aName);
	}
}

@end


