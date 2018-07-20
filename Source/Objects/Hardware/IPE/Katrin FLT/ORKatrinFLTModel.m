//
//  ORKatrinFLTModel.m
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


#import "ORKatrinFLTDefs.h"
#import "ORKatrinFLTModel.h"
#import "ORKatrinSLTModel.h"
#import "ORIpeSLTModel.h"
#import "ORIpeCrateModel.h"
#import "ORIpeFireWireCard.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORDataTypeAssigner.h"
#import "ORAxis.h"
#import "ORTimeRate.h"
#import "ORFireWireInterface.h"
#import "ORIpeFireWireCard.h"
#import "ORTest.h"

/** The hardware returns the product energy times filter length
 * Using the define energy shift will remove the filter length dependancy.
 * For a filter lenght shorter than 128 (maximum) the histogram will 
 * have whole as with a shorter filter length the resotution goes down. 
 * The mode might be useful for experiemts that need to change the filter lenght
 * and want to have the energy pulse and thresholds in the same range.  
 */


//#define USE_ENERGY_SHIFT

// -tb-
#ifdef __ORCA_DEVELOPMENT__CONFIGURATION__
#define USE_TILLS_DEBUG_MACRO //<--- to switch on/off debug output use/comment out this line -tb-
#ifdef USE_TILLS_DEBUG_MACRO
#define    DebugTB(x) x
#else
#define    DebugTB(x) 
#endif
#else
#define    DebugTB(x) 
#endif

NSString* ORKatrinFLTModelVersionRevisionChanged     = @"ORKatrinFLTModelVersionRevisionChanged";
NSString* ORKatrinFLTModelAvailableFeaturesChanged   = @"ORKatrinFLTModelAvailableFeaturesChanged";
NSString* ORKatrinFLTModelCheckWaveFormEnabledChanged= @"ORKatrinFLTModelCheckWaveFormEnabledChanged";
NSString* ORKatrinFLTModelCheckEnergyEnabledChanged  = @"ORKatrinFLTModelCheckEnergyEnabledChanged";
NSString* ORKatrinFLTModelTestPatternCountChanged	 = @"ORKatrinFLTModelTestPatternCountChanged";
NSString* ORKatrinFLTModelTModeChanged				 = @"ORKatrinFLTModelTModeChanged";
NSString* ORKatrinFLTModelTestParamChanged			 = @"ORKatrinFLTModelTestParamChanged";
NSString* ORKatrinFLTModelBroadcastTimeChanged		 = @"ORKatrinFLTModelBroadcastTimeChanged";
NSString* ORKatrinFLTModelHitRateLengthChanged		 = @"ORKatrinFLTModelHitRateLengthChanged";
NSString* ORKatrinFLTModelShapingTimesChanged		 = @"ORKatrinFLTModelShapingTimesChanged";
NSString* ORKatrinFLTModelTriggersEnabledChanged	 = @"ORKatrinFLTModelTriggersEnabledChanged";
NSString* ORKatrinFLTModelGainsChanged				 = @"ORKatrinFLTModelGainsChanged";
NSString* ORKatrinFLTModelThresholdsChanged			 = @"ORKatrinFLTModelThresholdsChanged";
NSString* ORKatrinFLTModelFilterGapChanged			 = @"ORKatrinFLTModelFilterGapChanged";
NSString* ORKatrinFLTModelFilterGapBinsChanged		 = @"ORKatrinFLTModelFilterGapBinsChanged";
NSString* ORKatrinFLTModelFltRunModeChanged			 = @"ORKatrinFLTModelFltRunModeChanged";
NSString* ORKatrinFLTModelDaqRunModeChanged			 = @"ORKatrinFLTModelDaqRunModeChanged";
NSString* ORKatrinFLTSettingsLock					 = @"ORKatrinFLTSettingsLock";
NSString* ORKatrinFLTModelPostTriggerTimeChanged	 = @"ORKatrinFLTModelPostTriggerTimeChanged";
NSString* ORKatrinFLTChan							 = @"ORKatrinFLTChan";
NSString* ORKatrinFLTModelTestPatternsChanged		 = @"ORKatrinFLTModelTestPatternsChanged";
NSString* ORKatrinFLTModelGainChanged				 = @"ORKatrinFLTModelGainChanged";
NSString* ORKatrinFLTModelThresholdChanged			 = @"ORKatrinFLTModelThresholdChanged";
NSString* ORKatrinFLTModelTriggerEnabledChanged		 = @"ORKatrinFLTModelTriggerEnabledChanged";
NSString* ORKatrinFLTModelShapingTimeChanged		 = @"ORKatrinFLTModelShapingTimeChanged";
NSString* ORKatrinFLTModelHitRateEnabledChanged		 = @"ORKatrinFLTModelHitRateEnabledChanged";
NSString* ORKatrinFLTModelHitRatesArrayChanged		 = @"ORKatrinFLTModelHitRatesArrayChanged";
NSString* ORKatrinFLTModelHitRateChanged			 = @"ORKatrinFLTModelHitRateChanged";
NSString* ORKatrinFLTModelTestsRunningChanged		 = @"ORKatrinFLTModelTestsRunningChanged";
NSString* ORKatrinFLTModelTestEnabledArrayChanged	 = @"ORKatrinFLTModelTestEnabledChanged";
NSString* ORKatrinFLTModelTestStatusArrayChanged	 = @"ORKatrinFLTModelTestStatusChanged";

NSString* ORKatrinFLTModelReadoutPagesChanged		 = @"ORKatrinFLTModelReadoutPagesChanged"; // ak, 2.7.07

//hardware histogramming -tb- 2008-02-08
NSString* ORKatrinFLTModelHistoBinWidthChanged		 = @"ORKatrinFLTModelHistoBinWidthChanged";
NSString* ORKatrinFLTModelHistoMinEnergyChanged      = @"ORKatrinFLTModelHistoMinEnergyChanged";
NSString* ORKatrinFLTModelHistoMaxEnergyChanged      = @"ORKatrinFLTModelHistoMaxEnergyChanged";
NSString* ORKatrinFLTModelHistoFirstBinChanged       = @"ORKatrinFLTModelHistoFirstBinChanged";
NSString* ORKatrinFLTModelHistoLastBinChanged        = @"ORKatrinFLTModelHistoLastBinChanged";
NSString* ORKatrinFLTModelHistoRunTimeChanged        = @"ORKatrinFLTModelHistoRunTimeChanged";
NSString* ORKatrinFLTModelHistoRecordingTimeChanged  = @"ORKatrinFLTModelHistoRecordingTimeChanged";
NSString* ORKatrinFLTModelHistoSelfCalibrationPercentChanged  = @"ORKatrinFLTModelHistoSelfCalibrationPercentChanged";
NSString* ORKatrinFLTModelHistoCalibrationValuesChanged   = @"ORKatrinFLTModelHistoCalibrationValuesChanged";
NSString* ORKatrinFLTModelHistoCalibrationPlotterChanged  = @"ORKatrinFLTModelHistoCalibrationPlotterChanged";
NSString* ORKatrinFLTModelHistoCalibrationChanChanged     = @"ORKatrinFLTModelHistoCalibrationChanChanged";
NSString* ORKatrinFLTModelHistoPageNumChanged             = @"ORKatrinFLTModelHistoPageNumChanged";
NSString* ORKatrinFLTModelShowHitratesDuringHistoCalibrationChanged     = @"ORKatrinFLTModelShowHitratesDuringHistoCalibrationChanged";
NSString* ORKatrinFLTModelHistoClearAtStartChanged     = @"ORKatrinFLTModelHistoClearAtStartChanged";
NSString* ORKatrinFLTModelHistoClearAfterReadoutChanged    = @"ORKatrinFLTModelHistoClearAfterReadoutChanged";
NSString* ORKatrinFLTModelHistoStopIfNotClearedChanged     = @"ORKatrinFLTModelHistoStopIfNotClearedChanged";

NSString* ORKatrinFLTModelReadWriteRegisterChanChanged     = @"ORKatrinFLTModelReadWriteRegisterChanChanged";
NSString* ORKatrinFLTModelReadWriteRegisterNameChanged     = @"ORKatrinFLTModelReadWriteRegisterNameChanged";

enum {
	kFLTControlRegCode			= 0x0L,
	kFLTTimeCounterCode			= 0x1L,
	kFLTTriggerControlCode		= 0x2L,
	kFLTThresholdCode			= 0x3L,
	kFLTHitRateSettingCode		= 0x4L,
	kFLTHitRateCode				= 0x4L,
	kFLTGainCode				= 0x4L,
	kFLTTestPatternCode			= 0x4L,
	kFLTTriggerDataCode			= 0x5L,
	kFLTTriggerEnergyCode		= 0x6L,
	kFLTAdcDataCode				= 0x7L
};

static int trigChanConvFLT[4][6]={
{ 0,  2,  4,  6,  8, 10},	//FPG6-A
{ 1,  3,  5,  7,  9, 11},	//FPG6-B
{12, 14, 16, 18, 20, -1},	//FPG6-C
{13, 15, 17, 19, 21, -1},	//FPG6-D
};

static NSString* fltTestName[kNumKatrinFLTTests]= {
@"Run Mode",
@"Ram",
@"Pattern",
@"Broadcast",
@"Threshold/Gain",
@"Speed",
@"Event",
};

@interface ORKatrinFLTModel (private)
- (NSAttributedString*) test:(int)testName result:(NSString*)string color:(NSColor*)aColor;
- (void) enterTestMode;
- (void) leaveTestMode;
- (void) checkWaveform:(short*)waveFormPtr;
@end

@implementation ORKatrinFLTModel

/** Read the flt "VersionRevision" register and set version and feature vars and flags.
 * 
 * If no version can be detected, version 2 is emulated.
 * Old versions (before 2008) usually can be recognized and are versioned with ver 1.
 */
- (void)	initVersionRevision;
{
    sltmodel = [[self crate] adapter];
	if(![[sltmodel fireWireInterface] serviceAlive]){
        NSLog(@"FLT %i: initVersionRevision: no firewire service \n",[self slot]+1  );
        //NSLog(@"FLT %i: initVersionRevision: no firewire service (pointers: sltmodel %p, firewireInterface %p)\n",[self slot]+1,sltmodel,[sltmodel fireWireInterface] );
	}
    uint32_t oldVersionRegister = versionRegister;
    //NSLog(@"FLT %i: read Version+Revision Register\n",[self slot]+1 );
    //NSLog(@"   (Current value: 0x%08x)\n",[self versionRegister] );
    @try {
        versionRegister = 	[self readVersionRevision];
        if(versionRegister==0){// probably no firewire
            NSLog(@"FLT %i:  Version+Revision Register is 0 - probably firewire not yet established!\n",[self slot]+1 );
            // is below in default part ... [self setStdFeatureIsAvailable:     TRUE];//in this case we allow everything -tb-
            //[self setHistoFeatureIsAvailable:   TRUE]; 
            //[self setVetoFeatureIsAvailable:    TRUE]; 
        }
        //check for old versions
        uint32_t test = 0xa0 | [self slot];
        if(     ((versionRegister >> 24)         == test) 
		   && (((versionRegister >> 20) & 0x0f) != 0x3 )   ){
            // probably old version (no posttrigger and no status bits in ContStatReg)
            // in this case [self readVersionRevision] returns the ControlStatusRegister
            // (reason: has the same Func number in bits 23..21 "Denis")
            // -tb-
            NSLog(@"Version: VersionRevisionReg (raw) 0x%x is not valid!\n",versionRegister );
            NSLog(@"    You probably use an old FPGA configuration version; version register reset to 1.\n");
            NSLog(@"    You should set posttrigger time to 511 manually!\n");
            versionRegister = 0x00100000;
        }
    }
	@catch(NSException* localException) {
        versionRegister = 0x00200000;//  in simulation mode this will emulate version 3.x -tb- 2008-04-21
        NSLog(@"FLT %i: reading Version+Revision Register failed - emulate ver. %i\n",[self stationNumber]/*[self slot]+1*/,[self versionRegHWVersion] );
		versionRegisterIsUptodate=FALSE;
        //versionRegister = 0;
	}
    
    if([self slot]==0){// a new created FLT - not yet dropped into a slot
        versionRegisterIsUptodate=FALSE;
        return;
    }
    
    if([self versionRegHWVersion]==1){// old version - no posttrigger
        [self setPostTriggerTime:511];// the default
    }
    
    if([self versionRegHWVersionHex] >= 0x30){// in v3: "histo version" has no "standard version"!
        if(([self versionRegApplicationID] & 0x2))
			[self setStdFeatureIsAvailable:   FALSE];// std is always available (maybe for reduced number of channels)
        else                                        // NO, this is not true any more ... -tb- 2008-05 (e.g. energy mode=standard is not available in histogramming)
			[self setStdFeatureIsAvailable:   TRUE];// std is always available (maybe for reduced number of channels)
    }
    
    if([self versionRegHWVersion]>=0x3){
        [self setVetoFeatureIsAvailable:  ([self versionRegApplicationID] & 0x1)];
        [self setHistoFeatureIsAvailable: ([self versionRegApplicationID] & 0x2)];
    }else{  //default
        //In KatrinFLTController;;versionRevisionChanged (via notification at the end of this function) the checkboxes will be enabled ... -tb-
        ////[self setVetoFeatureIsAvailable:  NO];  //use this to use histo config. as default
        ////[self setHistoFeatureIsAvailable: YES];
        //[self setStdFeatureIsAvailable:  YES];
        //[self setVetoFeatureIsAvailable: YES];
        //[self setHistoFeatureIsAvailable:YES];
    }
    
    //set filter gap feature (dont change it, if HWVersion <= 2 ... )
    if([self versionRegHWVersion]>=0x3){
        if([self versionRegApplicationID]==0 && [self versionRegFPGA6Version]>=0x04 ){//only in standard fpga since FPGA6>=4
            [self setFilterGapFeatureIsAvailable: YES];
        }else  if([self versionRegApplicationID]==2 && [self versionRegFPGA6Version]>=0x06 ){//since may 2009 in HistoFirmware (FPGA6>=6)
            [self setFilterGapFeatureIsAvailable: YES];
        }else{
            [self setFilterGapFeatureIsAvailable: NO];
        }
    }
    
    //warnings (only if a FPGA configuration was (probably) detected)
    if([self versionRegHWVersion]>=0x3){
        if( (oldVersionRegister!=versionRegister)){
            //message if: 1. register changed, 2. first call
            sltmodel = [[self crate] adapter];
            ORAlarm *alarm = [sltmodel fltFPGAConfigurationAlarm];
            //TODO: could move this all to SLT funtcion; memory management? -tb- 2008-05-29
            if(!alarm){
			    alarm = [[ORAlarm alloc] initWithName:@"FLT FPGA change detected." severity:kInformationAlarm];
			    [alarm setSticky:NO];
                [alarm setHelpString:@"See Status Log for details."];
                [sltmodel setFltFPGAConfigurationAlarm: alarm];
		    }
            [alarm setAcknowledged:NO];
		    [alarm postAlarm];
            
            if([self stdFeatureIsAvailable]){
                NSLogColor([NSColor redColor],@"========================================\n");
                NSLogColor([NSColor redColor],@"FLT Slot %i: STANDARD FPGA configuration detected!\n",[self stationNumber]);
                NSLogColor([NSColor redColor],@"========================================\n");
                NSLogColor([NSColor redColor],@"Available features in this configuration: PostTrigger, 20 channels\n");
                NSLogColor([NSColor redColor],@"Not available: hardware histogramming, veto mode\n");
                NSLogColor([NSColor redColor],@"----------------------------------------\n");
            }
            if([self histoFeatureIsAvailable]){
                NSLogColor([NSColor redColor],@"========================================\n");
                NSLogColor([NSColor redColor],@"FLT Slot %i: HISTOGRAMMING FPGA configuration detected!\n",[self stationNumber]);
                NSLogColor([NSColor redColor],@"========================================\n");
                NSLogColor([NSColor redColor],@"Available features in this configuration: hardware histogram, 4 channels\n");
                NSLogColor([NSColor redColor],@"Not available: energy daq mode, veto mode\n");
                NSLogColor([NSColor redColor],@"----------------------------------------\n");
            }
            if([self vetoFeatureIsAvailable]){
                NSLogColor([NSColor redColor],@"========================================\n");
                NSLogColor([NSColor redColor],@"FLT Slot %i: VETO FPGA configuration detected!\n",[self stationNumber]);
                NSLogColor([NSColor redColor],@"========================================\n");
                NSLogColor([NSColor redColor],@"Available features in this configuration: veto functions, 20 channels\n");
                NSLogColor([NSColor redColor],@"Not available: hardware histogram\n");
                NSLogColor([NSColor redColor],@"----------------------------------------\n");
            }
        }
    }
    
    //updates for GUI:
    [self recalcHistoMaxEnergy];
    //send out notification
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelVersionRevisionChanged object:self];
    versionRegisterIsUptodate=TRUE;
}

- (void) showVersionRevision
{
	//NSLog(@"Version: VersionRevisionReg (raw) 0x%x\n",versionRegister );
	//NSLog(@"Version 0x%x, Revision 0x%x (%u=0x%x)\n",(versionRegister & 0xffff0000) >>16,(versionRegister & 0x0000ffff),versionRegister,versionRegister );
	//NSLog(@"Version %i, Revision %i (%u=0x%x)\n",(versionRegister & 0xffff0000) >>16,(versionRegister & 0x0000ffff),versionRegister,versionRegister );
	NSLog(@"Version+Revision Register of FLT %i: 0x%08x \n",[self stationNumber],[self  versionRegister] );
	NSLog(@"    Version: FPGA firmware version   0x%02x  (major %i, minor %i)\n", [self versionRegHWVersionHex], [self versionRegHWVersion], [self versionRegHWSubVersion]);
#ifdef __ORCA_DEVELOPMENT__CONFIGURATION__
	NSLog(@"    Version: application/feature ID 0x%x\n", [self versionRegApplicationID]);
	NSLog(@"    Version: CFPGA version 0x%02x\n", [self versionRegCFPGAVersion]);
	NSLog(@"    Version: FPGA6 version 0x%02x\n", [self versionRegFPGA6Version]);
#endif
}

- (uint32_t) versionRegister
{return versionRegister;}

- (void) setVersionRegister:(uint32_t)aValue
{
    versionRegister=aValue;
}

//! Controls available features (applications).
- (int) versionRegApplicationID {return  (versionRegister >> 24) & 0xff;}

//see .h file for more information
- (int) versionRegHWVersionHex  {return  (versionRegister >> 16) & 0xff;}
- (int) versionRegHWVersion     {return  (versionRegister >> 20) & 0x0f;}//TODO: rename to 'major' and 'minor' ... version ??? -tb-
- (int) versionRegHWSubVersion  {return  (versionRegister >> 16) & 0x0f;}
- (int) versionRegCFPGAVersion  {return  (versionRegister >>  8) & 0xff;}
- (int) versionRegFPGA6Version  {return  (versionRegister      ) & 0xff;}

- (BOOL) stdFeatureIsAvailable   {return stdFeatureIsAvailable;}   // this is always true, could remove it -tb-
- (BOOL) vetoFeatureIsAvailable  {return vetoFeatureIsAvailable;}
- (BOOL) histoFeatureIsAvailable {return histoFeatureIsAvailable;}
- (BOOL) filterGapFeatureIsAvailable {return filterGapFeatureIsAvailable;}

- (void) setStdFeatureIsAvailable:(BOOL)aBool
{
    stdFeatureIsAvailable=aBool;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelAvailableFeaturesChanged object:self];
}

/** For version 3 veto and histogram feature are not available at the same time.
 * As this is not critical I don't care about this. See: #setHistoFeatureIsAvailable:
 */
- (void) setVetoFeatureIsAvailable:(BOOL)aBool
{
    vetoFeatureIsAvailable=aBool;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelAvailableFeaturesChanged object:self];
}

- (void) setHistoFeatureIsAvailable:(BOOL)aBool
{
    histoFeatureIsAvailable=aBool;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelAvailableFeaturesChanged object:self];
}

- (void) setFilterGapFeatureIsAvailable:(BOOL)aBool
{
    filterGapFeatureIsAvailable=aBool;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelAvailableFeaturesChanged object:self];
    [self updateFilterGapBins];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelFilterGapChanged object:self];
}


- (id) init
{
    //NSLog(@"ORKatrinFLTModel::init\n" ); //TODO : WHEN IS THIS METHOD CALLED ? -tb- 2008-03-13
	//answer: at least when dragging a new card from catalog to the crate -tb-
	// - so we reallay need to init the most important settings e.g. strings -tb-
    self = [super init];
    
#ifdef __ORCA_DEVELOPMENT__CONFIGURATION__
    {//in init: and initWithCoder:
        static bool firstTimeCalled=TRUE;
        if(firstTimeCalled){
            firstTimeCalled=FALSE;
            NSLog(@"ORKatrinFLTModel: WARNING: You are using a development version of Orca!\n");
            NSLog(@"    Debug code may slow down the measurement loop.\n");
            NSLog(@"    (In XCode, we recommend to switch the Active Build Configuration to 'Deployment Configuration' and recompile Orca.)\n" );
        }
    }
#endif
    
    //init: read version register of flt and itentify the available applications:
    versionRegisterIsUptodate=FALSE;
    //[self initVersionRevision];//if called here, usually firewire is not yest available  (see initWithCoder) -tb-
    postTriggerTime=511;//TODO : initialization; is this the right place? -tb- 2008-03-07 --- yes! see comment above -tb-
    readWriteRegisterName=@"ControlStatus";
#if 0
    [self histoSetStandard];
#else
	histoClearAtStart = YES ; 
    histoClearAfterReadout = YES  ; 
    histoStopIfNotCleared  = NO ; 
#endif
    [self setHistoBinWidth:1];
    [self setHistoRunTime:5]; //histoRunTime = 5; //the HW histogramming refresh time
    return self;
}

- (void) dealloc
{	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [testPatterns release];
    [testEnabledArray release];
    [testStatusArray release];
	[testSuit release];
    [shapingTimes release];
    [triggersEnabled release];
	[thresholds release];
	[gains release];
	[totalRate release];
    [histogramData release]; //do I need to release the NSMutableDate in this array? no; I already released it -tb-
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"KatrinFLTCard"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORKatrinFLTController"];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(serviceChanged:)
                         name : @"ORFireWireInterfaceServiceAliveChanged" //copied from ORKatrinSLTModel.m -tb- 2008-03-13
                       object : [[[self crate] adapter] fireWireInterface]];//SLT is [[self crate] adapter] -tb-
    
    [notifyCenter addObserver : self
                     selector : @selector(serviceChanged:)
                         name : @"ORIpeSLTModelHW_ResetChanged" //copied from ORKatrinSLTModel.m -tb- 2008-03-13
                       object : [[self crate] adapter] ];//SLT is [[self crate] adapter] -tb-
    
#if 0
    //notify this to check for the fpga configuration after slot change -tb-
    //  instead I overwrite setSlot:(int)aSlot - there I can access the old slot number -tb-
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORIpeCardSlotChangedNotification
					   object : self];
#endif
	
}

- (void) serviceChanged:(NSNotification*)aNote
{
	//----
	//moved this to the SLT code. MAH 06/10/08
    //NSLog(@"ORKatrinFLTModel::Received Notification serviceChanged or HW_Reset<---\n");
    //[self initVersionRevision]; // -tb- 2008-03-13
	//if([fireWireInterface serviceAlive]){
	//	//[self checkAndLoadFPGAs];
	//	[self readVersion];
	//}
}

/** OBSOLETE: 
 * The FLT waits for this notification 'cause inserting a new FLT card into the crate will assign
 * slot number 0 first and then change to the selected slot - this way we can detect when a new FLT was
 * created and can read the FPGA configuration.
 * (Instead of waiting for the notification we could overwrite the method and call [super setSlot:...] of ORCard?) -tb-
 *
 * Also moving a FLT icon into a slot without real FLT counterpart will result in a change of the detected
 * configuration.
 */
- (void) slotChanged:(NSNotification*)aNote
{
    NSLog(@"ORKatrinFLTModel::Received Notification slotChanged <--- new slot is %i (this is OBSOLETE)\n",[self slot]);
    [self initVersionRevision]; // -tb- 2008-03-13
	//if([fireWireInterface serviceAlive]){
	//	//[self checkAndLoadFPGAs];
	//	[self readVersion];
	//}
}

/** The FLT waits for this notification 'cause inserting a new FLT card into the crate will assign
 * slot number 0 first and then change to the selected slot - this way we can detect when a new FLT was
 * created and can read the FPGA configuration.
 * (Instead of waiting for the notification we could overwrite the method and call [super setSlot:...] of ORCard?) -tb-
 *
 * Also moving a FLT icon into a slot without real FLT counterpart will result in a change of the detected
 * configuration.
 *
 * Overwritten from ORCard.
 
 */
- (void) 	setSlot:(int)aSlot
{
    int oldSlot = [self slot];
    //NSLog(@"This is FLT %i: setSlot:(int)aSlot - calling super ... move to slot %i\n",[self slot]+1,aSlot+1 );
    [super setSlot:aSlot];
    if(oldSlot != [self slot]){
        //NSLog(@"This is FLT %i: the slot really changed!\n",[self slot]+1  );
        [self initVersionRevision]; // -tb- 2008-03-13
	}
}


#pragma mark ¥¥¥Accessors

- (BOOL) checkWaveFormEnabled
{
    return checkWaveFormEnabled;
}

- (void) setCheckWaveFormEnabled:(BOOL)aCheckWaveFormEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCheckWaveFormEnabled:checkWaveFormEnabled];
    
    checkWaveFormEnabled = aCheckWaveFormEnabled;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelCheckWaveFormEnabledChanged object:self];
}

- (BOOL) checkEnergyEnabled
{
    return checkEnergyEnabled;
}

- (void) setCheckEnergyEnabled:(BOOL)aCheck
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCheckEnergyEnabled:checkEnergyEnabled];
    
    checkEnergyEnabled = aCheck;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelCheckEnergyEnabledChanged object:self];
}

- (int) testPatternCount
{
    return testPatternCount;
}

- (void) setTestPatternCount:(int)aTestPatternCount
{
	if(aTestPatternCount<=0)     aTestPatternCount = 1;
	else if(aTestPatternCount>24)aTestPatternCount = 24;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setTestPatternCount:testPatternCount];
    
    testPatternCount = aTestPatternCount;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestPatternCountChanged object:self];
}

- (unsigned short) tMode
{
    return tMode;
}

- (void) setTMode:(unsigned short)aTMode
{
	aTMode &= 0x3;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setTMode:tMode];
    
    tMode = aTMode;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTModeChanged object:self];
}

- (int) page
{
    return page;
}

- (void) setPage:(int)aPage
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPage:page];
    
    page = aPage;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestParamChanged object:self];
}

- (int) iterations
{
    return iterations;
}

- (void) setIterations:(int)aIterations
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIterations:iterations];
    
    iterations = aIterations;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestParamChanged object:self];
}

- (int) endChan
{
    return endChan;
}

- (void) setEndChan:(int)aEndChan
{
	if(aEndChan>21)aEndChan = 21;
	if(aEndChan<0)aEndChan = 0;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setEndChan:endChan];
    
    endChan = aEndChan;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestParamChanged object:self];
}

- (int) startChan
{
    return startChan;
}

- (void) setStartChan:(int)aStartChan
{
	if(aStartChan>21)aStartChan = 21;
	if(aStartChan<0)aStartChan = 0;
    [[[self undoManager] prepareWithInvocationTarget:self] setStartChan:startChan];
    
    startChan = aStartChan;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestParamChanged object:self];
}

- (BOOL) broadcastTime
{
    return broadcastTime;
}

- (void) setBroadcastTime:(BOOL)aBroadcastTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBroadcastTime:broadcastTime];
    
    broadcastTime = aBroadcastTime;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelBroadcastTimeChanged object:self];
}

- (void) setTotalRate:(ORTimeRate*)newTimeRate
{
	[totalRate autorelease];
	totalRate=[newTimeRate retain];
}

- (ORTimeRate*) totalRate
{
	return totalRate;
}


- (unsigned short) hitRateLength
{
    return hitRateLength;
}

- (void) setHitRateLength:(unsigned short)aHitRateLength
{
	if(aHitRateLength<1)aHitRateLength = 1;
	else if(aHitRateLength>8)aHitRateLength = 8;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateLength:hitRateLength];
    
    hitRateLength = aHitRateLength;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHitRateLengthChanged object:self];
}

- (NSMutableArray*) shapingTimes
{
    return shapingTimes;
}

- (void) setShapingTimes:(NSMutableArray*)aShapingTimes
{
    [aShapingTimes retain];
    [shapingTimes release];
    shapingTimes = aShapingTimes;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelShapingTimesChanged object:self];
}


- (NSMutableArray*) triggersEnabled
{
    return triggersEnabled;
}

- (void) setTriggersEnabled:(NSMutableArray*)aTriggersEnabled
{
    [aTriggersEnabled retain];
    [triggersEnabled release];
    triggersEnabled = aTriggersEnabled;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTriggersEnabledChanged object:self];
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (uint32_t) waveFormId { return waveFormId; }
- (void) setWaveFormId: (uint32_t) aWaveFormId
{
    waveFormId = aWaveFormId;
}


- (uint32_t) hitRateId {
	return hitRateId; 
}
- (void) setHitRateId: (uint32_t) aHitRateId
{
    hitRateId = aHitRateId;
}

- (uint32_t) thresholdScanId { return thresholdScanId; }
- (void) setThresholdScanId: (uint32_t) athresholdScanId
{
    thresholdScanId = athresholdScanId;
}

- (uint32_t) histogramId { return histogramId; }
- (void) setHistogramId: (uint32_t) aValue
{
    histogramId = aValue;
}

- (uint32_t) vetoId { return vetoId; }
- (void) setVetoId: (uint32_t) aValue
{
    vetoId = aValue;
}

/*! Assign the data IDs which are needed to identify the type of encoded data sets.
 They are needed in:
 the takeData methods
 - (NSDictionary*) dataRecordDescription
 */ //-tb- 2008-02-6
- (void) setDataIds:(id)assigner
{
    dataId            = [assigner assignDataIds:kLongForm];
    waveFormId        = [assigner assignDataIds:kLongForm];
	hitRateId         = [assigner assignDataIds:kLongForm]; // new ... -tb- 2008-01-29
	thresholdScanId   = [assigner assignDataIds:kLongForm];
	histogramId       = [assigner assignDataIds:kLongForm];
	vetoId            = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:     [anotherCard dataId]];
    [self setWaveFormId: [anotherCard waveFormId]];
	[self setHitRateId:  [anotherCard hitRateId]]; // new ... -tb- 2008-01-29
	[self setThresholdScanId: [anotherCard thresholdScanId]];
	[self setHistogramId: [anotherCard histogramId]];
	[self setVetoId:      [anotherCard vetoId]];
}

- (NSMutableArray*) hitRatesEnabled
{
    return hitRatesEnabled;
}

- (void) setHitRatesEnabled:(NSMutableArray*)anArray
{
	[anArray retain];
	[hitRatesEnabled release];
    hitRatesEnabled = anArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHitRatesArrayChanged object:self];
}

- (NSMutableArray*) gains
{
    return gains;
}

- (void) setGains:(NSMutableArray*)aGains
{
	[aGains retain];
	[gains release];
    gains = aGains;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelGainsChanged object:self];
}

- (NSMutableArray*) thresholds
{
    return thresholds;
}

- (void) setThresholds:(NSMutableArray*)aThresholds
{
	[aThresholds retain];
	[thresholds release];
    thresholds = aThresholds;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelThresholdsChanged object:self];
}

-(unsigned short) threshold:(unsigned short) aChan
{
    return [[thresholds objectAtIndex:aChan] shortValue];
}


-(unsigned short) gain:(unsigned short) aChan
{
    return [[gains objectAtIndex:aChan] shortValue];
}


-(void) setThreshold:(unsigned short) aChan withValue:(unsigned short) aThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
	//if(aThreshold>1200)aThreshold = 1200;
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aThreshold]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORKatrinFLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORKatrinFLTModelThresholdChanged
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}


- (unsigned short)shapingTime:(unsigned short) aGroup
{
	if(aGroup < 4){
		return [[shapingTimes objectAtIndex:aGroup] shortValue];
	}
	else {
		return 0;
	}
}

- (void)setShapingTime:(unsigned short) aGroup withValue:(unsigned short)aShapingTime
{
	if(aGroup < 4){
		[[[self undoManager] prepareWithInvocationTarget:self] setShapingTime:aGroup withValue:[self shapingTime:aGroup]];
		[shapingTimes replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:aShapingTime]];
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:aGroup] forKey: ORKatrinFLTChan];
		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:ORKatrinFLTModelShapingTimeChanged
		 object:self
		 userInfo: userInfo];
	}
}

- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain
{
	if(aGain>255)aGain = 255;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:aChan withValue:[self gain:aChan]];
	[gains replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aGain]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORKatrinFLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORKatrinFLTModelGainChanged
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

/** This is the filter gap FLT register setting.
 */ //-tb-
- (int) filterGap
{ return filterGap; }

- (void) setFilterGap:(int) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFilterGap:filterGap];
    filterGap = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelFilterGapChanged object:self];
    [self updateFilterGapBins];
}

/** Recomputes the value of #filterGapBins, which depends on #filterGap and #filterGapFeatureIsAvailable.
 Returns the new value of #filterGapBins.
 */ //-tb-
- (int) updateFilterGapBins
{   
    if(filterGapFeatureIsAvailable){
        //filterGapBins = 2*filterGap; //this is for the first implementation of the filter gap feature
        [self setFilterGapBins: 2*filterGap];
    }else{
        //filterGapBins = 1; //the standard for older FPGA versions (without gap)
        [self setFilterGapBins: 1];
    }
    return filterGapBins;
}

- (int) filterGapBins
{ return filterGapBins; }

- (void) setFilterGapBins:(int) aValue
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setFilterGapBins:filterGapBins];
    filterGapBins = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelFilterGapBinsChanged object:self];
}




//ORAdcInfoProviding protocol requirement
- (void) postAdcInfoProvidingValueChanged
{
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORAdcInfoProvidingValueChanged
	 object:self
	 userInfo: nil];
}


- (NSMutableArray*)testPatterns
{
	return testPatterns;
}

- (void) setTestPatterns:(NSMutableArray*) aPattern
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestPatterns:[self testPatterns]];
	[aPattern retain];
	[testPatterns release];
	testPatterns = aPattern;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORKatrinFLTModelTestPatternsChanged
	 object:self
	 userInfo: nil];
}



-(BOOL) triggerEnabled:(unsigned short) aChan
{
    return [[triggersEnabled objectAtIndex:aChan] boolValue];
}

//ORAdcInfoProviding protocol 
- (BOOL)onlineMaskBit:(int)bit
{
	//translate back to the triggerEnabled Bit
	return [self triggerEnabled:bit];
}

-(void) setTriggerEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerEnabled:aChan withValue:[self triggerEnabled:aChan]];
    [triggersEnabled replaceObjectAtIndex:aChan withObject:[NSNumber numberWithBool:aState]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORKatrinFLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORKatrinFLTModelTriggerEnabledChanged
	 object:self
	 userInfo: userInfo];
}

- (BOOL) hitRateEnabled:(unsigned short) aChan
{
    return [[hitRatesEnabled objectAtIndex:aChan] boolValue];
}


- (void) setHitRateEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateEnabled:aChan withValue:[self hitRateEnabled:aChan]];
    [hitRatesEnabled replaceObjectAtIndex:aChan withObject:[NSNumber numberWithBool:aState]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORKatrinFLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORKatrinFLTModelHitRateEnabledChanged
	 object:self
	 userInfo: userInfo];
}


- (int) fltRunMode
{
    return fltRunMode;
}

- (void) setFltRunMode:(int)aMode
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setDaqRunMode:daqRunMode];
    fltRunMode = aMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelFltRunModeChanged object:self];
}

- (int) daqRunMode
{
    return daqRunMode;
}

- (void) setDaqRunMode:(int)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDaqRunMode:daqRunMode];
    daqRunMode = aMode;
	
    // daq mode --> hw mode
    switch(aMode){
			//TODO: replace by names -tb- 2008-02-04
		case kKatrinFlt_DaqEnergyTrace_Mode:    [self setFltRunMode:kKatrinFlt_Debug_Mode];  break;
		case kKatrinFlt_DaqEnergy_Mode:         [self setFltRunMode:kKatrinFlt_Run_Mode];  break;
		case kKatrinFlt_DaqHitrate_Mode:
		case kKatrinFlt_DaqThresholdScan_Mode:  [self setFltRunMode:kKatrinFlt_Measure_Mode];  break;
		case kKatrinFlt_DaqTest_Mode:           [self setFltRunMode:kKatrinFlt_Test_Mode];  break;
		case kKatrinFlt_DaqHistogram_Mode:      [self setFltRunMode:kKatrinFlt_Run_Mode];  break;
			//TODO: for VETO ... -tb- case kKatrinFlt_DaqVeto_Mode:           [self setFltRunMode:kKatrinFlt_Run_Mode];  break;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelDaqRunModeChanged  object:self];
}

- (int) postTriggerTime// -tb- 2008-03-07
{
    return postTriggerTime;
}

- (void) setPostTriggerTime:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerTime:postTriggerTime];
    postTriggerTime = aValue;
    if(postTriggerTime<0) postTriggerTime=0;
    if(postTriggerTime>0xffff) postTriggerTime=0xffff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelPostTriggerTimeChanged object:self];
}





- (void) enableAllHitRates:(BOOL)aState
{
	int chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[self setHitRateEnabled:chan withValue:aState];
	}
}

- (void) setHitRateTotal:(float)newTotalValue
{
	hitRateTotal = newTotalValue;
	if(!totalRate){
		[self setTotalRate:[[[ORTimeRate alloc] init]autorelease]];
	}
	[totalRate addDataToTimeAverage:hitRateTotal];
}

- (float) hitRateTotal
{
	return hitRateTotal;
}

- (float) hitRate:(unsigned short)aChan
{
	if(aChan<kNumFLTChannels)return hitRate[aChan];
	else return 0;
}

- (float) rate:(int)aChan
{
	return [self hitRate:aChan];
}

- (BOOL) hitRateOverFlow:(unsigned short)aChan
{
	if(aChan<kNumFLTChannels)return hitRateOverFlow[aChan];
	else return NO;
}


// Added parameter for length of adc traces, ak 2.7.07
- (unsigned short) readoutPages
{
    return readoutPages;
}


- (void) setReadoutPages:(unsigned short)aReadoutPage
{
    // At maximum there are 64 pages
	if(aReadoutPage<1)aReadoutPage = 1;
	else if(aReadoutPage>64)aReadoutPage = 64;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setReadoutPages:readoutPages];
    
    readoutPages = aReadoutPage;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelReadoutPagesChanged object:self];
}



#pragma mark ¥¥¥HW Access


- (void) writePostTriggerTime:(unsigned int)aValue
{
    postTriggerTime= aValue;
    unsigned int func  = 0x2; // = b010
    unsigned int LAddr0 = 0x01; // UNUSED   0x01 is postTrigg
    unsigned int Pixel = 0; // we assume that all pixels have the same E_min, E_max, ...
    // debug output -tb- NSLog(@"writeEMax: Pbus register is 0x%x, TRun is %i\n",
    // debug output -tb-    [self read:([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)], TRun  ); 	
	
	[self write:   ([self slot] << 24) | (func << 21) | (LAddr0) value: postTriggerTime];
	//	[self write: 0x09c02000 value: EMin];
    Pixel = 1;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr0) value: postTriggerTime];
    Pixel = 2;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr0) value: postTriggerTime];
    Pixel = 3;
	[self write:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr0) value: postTriggerTime];
}


- (void) readPostTriggerTime
{
    //TODO: write a function with channel as parameter -tb-
    int val;
	
    unsigned int func  = 0x2; // = b010
    unsigned int LAddr0 = 0x01; // UNUSED   0x01 is postTrigg
    unsigned int Pixel = 0; // we assume that all pixels have the same E_min, E_max, ...
    // debug output -tb- NSLog(@"writeEMax: Pbus register is 0x%x, TRun is %i\n",
    // debug output -tb-    [self read:([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)], TRun  ); 	
	
	val = (int)[self read:   ([self slot] << 24) | (func << 21) | (LAddr0)];
    NSLog(@"reading in HW  postTriggTime  FPGA %i is %i\n",Pixel,val);
	
	//	[self write: 0x09c02000 value: EMin];
    Pixel = 1;
	val = (int)[self read:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr0)];
    NSLog(@"reading in HW  postTriggTime  FPGA %i is %i\n",Pixel,val);
    Pixel = 2;
	val = (int)[self read:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr0)];
    NSLog(@"reading in HW  postTriggTime  FPGA %i is %i\n",Pixel,val);
    Pixel = 3;
	val = (int)[self read:   ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr0)];
    NSLog(@"reading in HW  postTriggTime  FPGA %i is %i\n",Pixel,val);
}


/** Read out the filter gap of fpga 0 (they all should be the same).
 * There is no function '- (void) writeFilterGap:(int)aValue'
 * as it is part of the trigger control register which is set by the
 * writeTriggerControl function.
 *
 * New since fpga6 version 4 (2008-07-11).
 */ //-tb-
- (void) readFilterGap
{
    uint32_t triggControlReg;
    int gap;
    int fpga=0;
    triggControlReg = [self readTriggerControl: fpga];
    gap=(triggControlReg >> 4) & 0x3;
    NSLog(@"KatrinFLT %i: read FilterGap: %i ( triggCtrlReg 0x%4x)\n",[self stationNumber],gap,triggControlReg);
    //NSLog(@"readFilterGap: %i\n",gap);
}


- (void) checkPresence
{
	@try {
		[self readCardId];
		[self setPresent:YES];
	}
	@catch(NSException* localException) {
		[self setPresent:NO];
	}
}

//*! The revision bits in the Status Control Register are obsolete since FPGA firmware versions 3.xx (since begin of 2008).
- (int)  readVersion
{	
	uint32_t data = [self readControlStatus];
	return (data >> kKatrinFlt_Cntl_Version_Shift) & kKatrinFlt_Cntl_Version_Mask; // 3bit
}

//*! Read out the version/revision/feature register. New since FPGA firmware versions 3.xx (since begin of 2008).
- (uint32_t)  readVersionRevision
{	
    unsigned int func  = 0x0; // = b000
    unsigned int LAddr0 = 0x01; // 0x01 is version.revision register
	
	uint32_t data = [self read:   ([self slot] << 24) | (func << 21) |  (LAddr0)];
    //NSLog(@"Version 0x%x, Revision 0x%x (%u=0x%x)\n",(data & 0xffff0000) >>16,(data & 0x0000ffff),data,data );
    //NSLog(@"Version %i, Revision %i (%u=0x%x)\n",(data & 0xffff0000) >>16,(data & 0x0000ffff),data,data );
	return  data ; 
	//return (data >> kKatrinFlt_Cntl_Version_Shift) & kKatrinFlt_Cntl_Version_Mask; // 3bit
}

//*! The version bits in the Trigger Control Register are obsolete since FPGA firmware versions 3.xx (since begin of 2008).
-(int) readFPGAVersion:(int) fpga
{
	uint32_t data = [self readTriggerControl:fpga];
	return((data >> 14) & 0x3); // 2bit
}


- (int)  readCardId
{
 	uint32_t data = [self readControlStatus];
	return (data >> kKatrinFlt_Cntrl_CardID_Shift) & kKatrinFlt_Cntrl_CardID_Mask; // 5bit
}

- (BOOL)  readHasData
{
 	uint32_t data = [self readControlStatus];
	return (((data >> kKatrinFlt_Cntrl_BufState_Shift) & 0x3) == 0x1);
}

- (BOOL)  readIsOverflow
{
 	uint32_t data = [self readControlStatus];
	return (((data >> kKatrinFlt_Cntrl_BufState_Shift) & 0x3) == 0x3);
}


/** Read the value from hardware.*/
- (int)  readMode
{
	uint32_t data = [self readControlStatus];
    int value = (data >> kKatrinFlt_Cntrl_Mode_Shift) & kKatrinFlt_Cntrl_Mode_Mask; // 4bit
	//-tb- [self setFltRunMode: (data >> kKatrinFlt_Cntrl_Mode_Shift) & kKatrinFlt_Cntrl_Mode_Mask]; // 4bit
    //NSLog(@"readMode: hw=%d, daq=%d \n",fltRunMode,daqRunMode); 
	return value;
}

- (void)  writeMode:(int) aValue 
{
	//uint32_t buffer = [self readControlStatus];
	//buffer =(buffer & ~(kKatrinFlt_Cntrl_Mode_Mask<<kKatrinFlt_Cntrl_Mode_Shift) ) | (aValue << kKatrinFlt_Cntrl_Mode_Shift);
    [self writeControlStatus:(aValue&kKatrinFlt_Cntrl_Mode_Mask) << kKatrinFlt_Cntrl_Mode_Shift];
}

- (uint32_t)  getReadPointer
{
	uint32_t data = [self readControlStatus];
	return data & 0x1ff; // 9bit
}

- (uint32_t)  getWritePointer
{
	uint32_t data = [self readControlStatus];
	return (data >> 11) & 0x1ff; // 9bit
}


//this is a method of the ORDataTaker protocol! -tb-
- (void)  reset
{
	//reset the W/R pointers
	uint32_t buffer = (fltRunMode << kKatrinFlt_Cntrl_Mode_Shift) | 0x1;
	[self writeControlStatus:buffer];
}


/** This is a test:
 * using 2 doxygen comments for the same method. It works! -tb-*/
- (void)  trigger
{
    //uint32_t addr;
	
	NSLog(@"Generating software trigger\n" );		
	
    generateTrigger = 1;
   	
	// Generate a software trigger
	//addr =  (21 << 24) | (0x1 << 18) | 0x0f12; // Slt Generate Software Trigger
    //[self write:addr value:0];
	
	
}


/** Write the selected thresholds and gains from Orca to the hardware/FLT.
 * For the histogramming FPGA versions we write the allowed thresholds and gains
 * in a own loop.
 */
- (void) loadThresholdsAndGains
{
	int i;
	for(i=0;i<kNumFLTChannels;i++){
		[self writeThreshold:i value:[self threshold:i]];
		[self writeGain:i value:[self gain:i]]; 
	}
    if([self histoFeatureIsAvailable]){
        // in this case we write the allowed values again to be sure ... -tb-
        // (reason: e.g. chan0 and chan10 write to the same register, so chan10 would overwrite chan0-values, see FLT manual)
	    for(i=0;i<kNumFLTChannels;i++){
            if(-1==[self histoChanToGroupMap:i]) continue;//if chan. i is allowed, group will be not -1
	    	[self writeThreshold:i value:[self threshold:i]];
		    [self writeGain:i value:[self gain:i]]; 
	    }
    }
}


- (void) initBoard
{
	[self loadTime];					//set the time on the flts to mac time
	[self writeMode:fltRunMode];
	[self loadThresholdsAndGains];
	[self writeHitRateMask];			//set the hit rate masks
}

- (uint32_t) readControlStatus
{
	return  [self read: ([self slot] << 24) ];
}

- (void) writeControlStatus:(uint32_t)aValue
{
	[self write: ([self slot] << 24) value:aValue];
}

- (void) printStatusReg
{
	uint32_t status = [self readControlStatus];
	NSLog(@"FLT %d status Reg: 0x%08x\n",[self stationNumber],status);
	NSLog(@"Revision: %d\n",(status>>kKatrinFlt_Cntl_Version_Shift) & kKatrinFlt_Cntl_Version_Mask);
	NSLog(@"SlotID  : %d\n",(status>>kKatrinFlt_Cntrl_CardID_Shift) & kKatrinFlt_Cntrl_CardID_Mask);
	NSLog(@"Has Data: %@\n",(((status>>kKatrinFlt_Cntrl_BufState_Shift) & kKatrinFlt_Cntrl_BufState_Mask) == 0x1)?@"YES":@"NO");
	NSLog(@"OverFlow: %@\n",(((status>>kKatrinFlt_Cntrl_BufState_Shift) & kKatrinFlt_Cntrl_BufState_Mask) == 0x3)?@"YES":@"NO");
	NSLog(@"Mode    : %d\n",((status>>kKatrinFlt_Cntrl_Mode_Shift) & kKatrinFlt_Cntrl_Mode_Mask));
	NSLog(@"WritePtr: %d\n",((status>>kKatrinFlt_Cntrl_Write_Shift) & kKatrinFlt_Cntrl_Write_Mask));
	NSLog(@"ReadPtr : %d\n",((status>>kKatrinFlt_Cntrl_ReadPtr_Shift) & kKatrinFlt_Cntrl_ReadPtr_Mask));
}


- (void) writeThreshold:(int)i value:(unsigned short)aValue
{
#ifdef USE_ENERGY_SHIFT											
    // Calculate the energy shift due to the shapingTime
	int fpga = i%2 + 2 * (i/12);
    energyShift[i] = 7 - [[shapingTimes objectAtIndex:fpga] intValue] & 0x7;
	
	//[self write:([self slot] << 24) | (kFLTThresholdCode << FLT_ADDRSP) | ((i&0x01f)<<FLT_CHADDR) value:(aValue>>energyShift[i])]; // E : T = 1
	[self write:([self slot] << 24) | (kFLTThresholdCode << kKatrinFlt_AddressSpace) | ((i&0x01f)<<kKatrinFlt_ChannelAddress) value:(aValue>>energyShift[i])]; // E : T = 1
#else
	
    // Take ration between threshold and energy into account.
	// Changed to 1, ak 21.9.07
	//[self write:([self slot] << 24) | (kFLTThresholdCode << FLT_ADDRSP) | ((i&0x01f)<<FLT_CHADDR) value:(aValue>>1)];  // E : T = 2
	//[self write:([self slot] << 24) | (kFLTThresholdCode << FLT_ADDRSP) | ((i&0x01f)<<FLT_CHADDR) value:(aValue)]; // E : T = 1
	[self write:([self slot] << 24) | (kFLTThresholdCode << kKatrinFlt_AddressSpace) | ((i&0x01f)<<kKatrinFlt_ChannelAddress) value:(aValue)]; // E : T = 1
#endif	
}

- (unsigned short) readThreshold:(int)i
{
    // Calculate the energy shift due to the shapingTime
#ifdef USE_ENERGY_SHIFT											
	int fpga = i%2 + 2 * (i/12);
    energyShift[i] = 7 - [[shapingTimes objectAtIndex:fpga] intValue] & 0x7;
	
	//return [self read:([self slot] << 24) | (kFLTThresholdCode << FLT_ADDRSP) | ((i&0x01f)<<FLT_CHADDR)] << energyShift[i];	// E : T = 1
	return [self read:([self slot] << 24) | (kFLTThresholdCode << kKatrinFlt_AddressSpace) | ((i&0x01f)<<kKatrinFlt_ChannelAddress)] << energyShift[i];
#else
	
    // Take ration between threshold and energy into account.
	// Changed to 1, ak 21.9.07
	//return [self read:([self slot] << 24) | (kFLTThresholdCode << FLT_ADDRSP) | ((i&0x01f)<<FLT_CHADDR)] >> 1;	 // E : T = 2
	//return [self read:([self slot] << 24) | (kFLTThresholdCode << FLT_ADDRSP) | ((i&0x01f)<<FLT_CHADDR)];	// E : T = 1
	return [self read:([self slot] << 24) | (kFLTThresholdCode << kKatrinFlt_AddressSpace) | ((i&0x01f)<<kKatrinFlt_ChannelAddress)];
#endif	
}

- (void) writeGain:(int)i value:(unsigned short)aValue
{
	// invert the gain scale, ak 20.7.07
	[self write:([self slot] << 24) | (kFLTGainCode << kKatrinFlt_AddressSpace) | ((i&0x01f)<<kKatrinFlt_ChannelAddress) | 0x1 value:(255-aValue)]; 
}

- (void) clear:(int)aChan page:(int)aPage value:(unsigned short)aValue
{
	uint32_t aPattern;
	
	aPattern =  aValue;
	aPattern = ( aPattern << 16 ) + aValue;
	
	// While emulating the block transfer by a loop of single transfers
	// it is nec. to increment the address pointer by 2
	[self clearBlock:([self slot] << 24) | (kFLTAdcDataCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress)	| (aPage << kKatrinFlt_PageNumber) 
			 pattern:aPattern
			  length:kKatrinFlt_Page_Size / 2
		   increment:2];
}

- (void) broadcast:(int)aPage dataBuffer:(unsigned short*)aDataBuffer
{
	// While emulating the block transfer by a loop of single transfers
	// it is nec. to increment the address pointer by 2
	[self writeBlock:([self slot] << 24) | (kFLTAdcDataCode << kKatrinFlt_AddressSpace) | (kKatrinFlt_ChannelAddress_All << kKatrinFlt_ChannelAddress)	| (aPage << kKatrinFlt_PageNumber) 
		  dataBuffer:(uint32_t*) aDataBuffer
			  length:kKatrinFlt_Page_Size / 2
		   increment:2];
}

- (void) writeMemoryChan:(int)aChan page:(int)aPage value:(unsigned short)aValue
{
	[self write:([self slot] << 24) | (kFLTAdcDataCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress) | (aPage << kKatrinFlt_PageNumber) value:aValue];
}

- (void) writeMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
	[self writeBlock: ([self slot] << 24) | (kFLTAdcDataCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress)	| (aPage << kKatrinFlt_PageNumber) 
		  dataBuffer: (uint32_t*)aPageBuffer
			  length: kKatrinFlt_Page_Size/2
		   increment: 2];
}

- (void) readMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
	
	[self readBlock: ([self slot] << 24) |(kFLTAdcDataCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress) | (aPage << kKatrinFlt_PageNumber) 
		 dataBuffer: (uint32_t*)aPageBuffer
			 length: kKatrinFlt_Page_Size/2
		  increment: 2];
}

- (uint32_t) readMemoryChan:(int)aChan page:(int)aPage
{
	return [self read:([self slot] << 24) | (kFLTAdcDataCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress) | (aPage << kKatrinFlt_PageNumber)];
}

- (void) writeHitRateMask
{
	uint32_t hitRateEnabledMask = 0;
	int chan;
	for(chan = 0;chan<kNumFLTChannels;chan++){
		if([[hitRatesEnabled objectAtIndex:chan] intValue]){
			hitRateEnabledMask |= (0x1L<<chan);
		}
	}
	
	// Code from 0 to n --> 1sec to n+1 sec
	// ak, 15.6.07
	hitRateEnabledMask |= ((hitRateLength-1) &0xf)<<24;  
	
	[self write:([self slot] << 24) | (kFLTHitRateSettingCode << kKatrinFlt_AddressSpace) value:hitRateEnabledMask];
}



- (unsigned short) readGain:(int)i
{
    // invert the gain scale, ak 20.7.07
	return (255-[self read:([self slot] << 24) | (kFLTGainCode << kKatrinFlt_AddressSpace) | 0x1 | ((i&0x01f)<<kKatrinFlt_ChannelAddress)]);
}

- (void) writeTriggerControl
{
	uint32_t aValue = 0;
	int fpga;
	for(fpga=0;fpga<4;fpga++){
		aValue = [[shapingTimes objectAtIndex:fpga] intValue] & 0x7;	//fold in the shaping time
		int chan;
		for(chan = 0;chan<6;chan++){
			if(trigChanConvFLT[fpga][chan] >= 0 && trigChanConvFLT[fpga][chan]<22){
				if([[triggersEnabled objectAtIndex:trigChanConvFLT[fpga][chan]] intValue]){
					aValue |= (0x1L<<chan)<<8;								//fold in the trigger enabled bit.
				}
			}
		}
		
        // set the filter gap
        if(filterGapFeatureIsAvailable){
            aValue &=  0xffffffcf;//clear bit 4-5
            aValue |=  (filterGap << 4);
        }
		
		[self write:([self slot] << 24) | (kFLTTriggerControlCode << kKatrinFlt_AddressSpace) | (trigChanConvFLT[fpga][0]<<kKatrinFlt_ChannelAddress)  value:aValue];
		uint32_t checkValue = [self read:([self slot] << 24) | (kFLTTriggerControlCode << kKatrinFlt_AddressSpace) | (trigChanConvFLT[fpga][0]<<kKatrinFlt_ChannelAddress)];
		
		aValue	   &= 0x3f07;
		checkValue &= 0x3f07;
		
        if (!usingPBusSimulation){	
			if(aValue != checkValue)
				NSLog(@"FLT %d FPGA %d Trigger control write/read mismatch <0x%08x:0x%08x>\n",
					  [self stationNumber],fpga,aValue,checkValue);
        }				  
	}
	
}


- (void) disableTrigger
{
	uint32_t aValue = 0;
	int fpga;
	for(fpga=0;fpga<4;fpga++){
		aValue = [[shapingTimes objectAtIndex:fpga] intValue] & 0x7;	//fold in the shaping time
		
		[self write:([self slot] << 24) | (kFLTTriggerControlCode << kKatrinFlt_AddressSpace) | (trigChanConvFLT[fpga][0]<<kKatrinFlt_ChannelAddress)  value:aValue];
		//uint32_t checkValue = [self read:([self slot] << 24) | (kFLTTriggerControlCode << kKatrinFlt_AddressSpace) | (trigChanConvFLT[fpga][0]<<kKatrinFlt_ChannelAddress)];
		//	
		//aValue	   &= 0x3f07;
		//checkValue &= 0x3f07;
		//
		//if(aValue != checkValue)NSLog(@"FLT %d FPGA %d Trigger control write/read mismatch <0x%08x:0x%08x>\n",[self stationNumber],fpga,aValue,checkValue);
	}
	
}


- (unsigned short) readTriggerControl:(int) fpga
{	
	return [self read:([self slot] << 24) | (kFLTTriggerControlCode << kKatrinFlt_AddressSpace) | (trigChanConvFLT[fpga][0]<<kKatrinFlt_ChannelAddress)];
}

- (void) loadTime:(uint32_t)aTime
{
	uint32_t addr = ([self slot] << 24) | (kFLTTimeCounterCode << kKatrinFlt_AddressSpace) ;
	if(broadcastTime){
		addr |= kKatrinFlt_Select_All_Slots;
	}
	[self write:addr value:aTime];
}

- (uint32_t) readTime
{
    if (usingPBusSimulation){
		return( (uint32_t)[NSDate timeIntervalSinceReferenceDate]);
    } 
	else {
		return [self read:([self slot] << 24) | (kFLTTimeCounterCode << kKatrinFlt_AddressSpace)];
    }	
}

- (uint32_t) readTimeSubSec
{
	uint32_t addr;
	uint32_t raw;
	
	
	// TODO: Use Slt implementation [firewirecard readSubSecond]
	// ak 31.7.07
	addr = (21 << 24) | (0x1 << 18) | 0x0502; // Slt SubSecCounter 
	raw = [self read:addr];
	
	// Calculate the KATRIN subsecton counter from the auger one
	return (((raw >> 11) & 0x3fff) * 2000 + (raw & 0x7ff)) / 2;
	
}

- (void) readHitRates
{
	@try {
		uint32_t aValue;
		float measurementAge;
		
		BOOL oneChanged = NO;
		float newTotal = 0;
		int chan;
		for(chan=0;chan<kNumFLTChannels;chan++){
			
			aValue = [self read:([self slot] << 24) | (kFLTHitRateCode << kKatrinFlt_AddressSpace) | (chan<<kKatrinFlt_ChannelAddress)];
			measurementAge = (aValue >> 28) & 0xf;
			aValue = aValue & 0x3fffff;
			hitRateOverFlow[chan] = (aValue >> 23) & 0x1;
			
			if(aValue != hitRate[chan]){
				
				// The hitrate counter has to be scaled by the counting time 
				// ak, 15.6.07
				if (hitRateLength!=0){  
				    hitRate[chan] = aValue/ (float) hitRateLength; 
				}
				else {
					hitRate[chan] = 0;
				}
				if(hitRateOverFlow[chan]){
					hitRate[chan] = 0;
				}
				
				oneChanged = YES;
			}
			if(!hitRateOverFlow[chan]){
				newTotal += hitRate[chan];
			}
		}
		
		[self setHitRateTotal:newTotal];
		
		if(oneChanged){
		    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHitRateChanged object:self];
		}
	}
	@catch(NSException* localException) {
	}
	
	[self performSelector:@selector(readHitRates) withObject:nil afterDelay:[self hitRateLength]];
}

- (NSString*) rateNotification
{
	return ORKatrinFLTModelHitRateChanged;
}

- (BOOL) isInRunMode
{
	return [self readMode] == kKatrinFlt_Run_Mode;
}

- (BOOL) isInTestMode
{
	return [self readMode] == kKatrinFlt_Test_Mode;
}

- (BOOL) isInDebugMode
{
	return [self readMode] == kKatrinFlt_Debug_Mode;
}

- (void) loadTime
{
    //debug output -tb- NSLog(@"This is method: %@ ::  %@ (self: %p)  STARTING\n",  NSStringFromClass([self class]) ,NSStringFromSelector(_cmd),  self);
	//attempt to the load time as close as possible to a seconds boundary
	NSDate* then = [NSDate date];
	while(1){
		NSDate* now = [NSDate date];
		uint32_t delta = [now timeIntervalSinceDate:then];	
		if(delta >= 1){
			uint32_t timeToLoad = (uint32_t)[NSDate timeIntervalSinceReferenceDate];
			[self loadTime:timeToLoad];
			uint32_t timeLoaded = [self readTime];
			NSLog(@"loaded FLT %d with time:%@\n",[self stationNumber],[NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)timeLoaded]);
			if(timeToLoad == timeLoaded) NSLog(@"time read back OK\n");
			else						 NSLogColor([NSColor redColor],@"readBack mismatch. Time load FAILED.\n");
			break;
		}
	}
    //debug output -tb- NSLog(@"This is method: %@ ::  %@ (self: %p)  STOPPING\n",  NSStringFromClass([self class]) ,NSStringFromSelector(_cmd),  self);
}

//testpattern stuff
- (void) rewindTP
{
	[self write:([self slot] << 24) | (kFLTTestPatternCode << kKatrinFlt_AddressSpace) | 0x2 
		  value:kKatrinFlt_TP_Control | 
	 kKatrinFlt_TestPattern_Reset | 
	 (tMode & 0x3)];
}

- (void) writeTestPatterns
{
	[self rewindTP];
	
	[self write:([self slot] << 24) | (kFLTTestPatternCode << kKatrinFlt_AddressSpace) | 0x2 
		  value:kKatrinFlt_TP_Control | kKatrinFlt_Ec2 | kKatrinFlt_Ec1 |(tMode & 0x3)];
	
	//write the mode and reset the r/w pointers
	[self write:([self slot] << 24) | (kFLTTestPatternCode << kKatrinFlt_AddressSpace) | 0x2 
		  value:kKatrinFlt_TP_Control | 
	 kKatrinFlt_TestPattern_Reset | 
	 (tMode & 0x3)];
	
	
	NSLog(@"Writing Test Patterns\n");
	int i;
	for(i= 0;i<testPatternCount;i++){
		int theValue = kKatrinFlt_PatternMask &  [[testPatterns objectAtIndex:i] intValue];
		if(i == testPatternCount-1)theValue |= kKatrinFlt_TP_End;
		
		[self write:([self slot] << 24) | (kFLTTestPatternCode << kKatrinFlt_AddressSpace) | ((i&0x01f)<<kKatrinFlt_ChannelAddress) | 0x2 
			  value:theValue];
		NSLog(@"%2d: 0x%x\n",i,theValue);
		if(i == testPatternCount-1)break;
	}
	
	[self rewindTP];
	
}



- (void) restartRun
{	
    // TODO: Read ADC traces starting from Reset Time Stamp
	
	// Disable trigger for the recording time
	// Q: Is the recording still active?
	[self disableTrigger]; 
	
	// Reset access pointers
	[self reset];
	
	nextEventPage = 0;
	
	// Sleep for the recording interval
	// Times of 100us windows (max 6.4ms)
	usleep(100*readoutPages); 
	
	// Enable trigger again and wait
	[self writeTriggerControl];
	
	//NSLog(@"Reset  %x  - Pages: %d %d\n", aValue, page0, page1 ); 	
}

#pragma mark ¥¥¥¥hw histogram access

// this is for testing and debugging the hardware histogramming (espec. timing) -tb- 2008-04-11
#ifdef __ORCA_DEVELOPMENT__CONFIGURATION__

#define USE_TILLS_HISTO_DEBUG_MACRO //<--- to switch on/off debug output use/comment out this line -tb-
#ifdef USE_TILLS_HISTO_DEBUG_MACRO
#define    DebugHistoTB(x) x
#else
#define    DebugHistoTB(x) 
#endif

#else
#define    DebugHistoTB(x) 
#endif
/** In the v3 crate version we have histogramming for the first channel of a group 
 * (ch 0,1,12,13= group 0,1,2,3)(ch 2,3,14,15= group 0,1,2,3).
 * This method translates channel number to group number. If the channel is not available,
 * -1 is returned.
 *
 * This is only used to check for the available channels - the registers need the full channel names.
 */ //-tb-
- (int) histoChanToGroupMap:(int)aChannel
{
    switch(aChannel){
		case   31:  return 31; //the broadcast to all channels/groups
		case   0:  return 0;
			//case   2:  return 2;//TODO: remove - test -tb-
			//case   3:  return 3;
		case   1:  return 1;
		case  12:  return 2;
		case  13:  return 3;
#if 0
			// we use the 4 "true" channels
		case   0: case 2: return 0;
		case   1: case 3: return 1;
		case 12: case 14: return 2;
		case 13: case 15: return 3;
#endif
		default: return -1;
    }
}

//hardware histogramming -tb- 2008-02-08
/** This is the setter for ORKatrinFLTModel::histoBinWidth.
 *
 * It serves as example of the general task of inserting new configuration variables to the model. <br>
 * Following steps are needed: 
 * - a new attribute in the class definition (interface)  in the model.h file
 * - a setter in the model (preparing the undo manager AND posting the notification with the according notification name string)
 * - a getter in the model
 * - a notification name string declaration in the model.h file
 * - the notification name string definition in the model.m file
 * - an entry in - (id)initWithCoder:(NSCoder*)decoder (for RW attributes only) (reading/writing to the .Orca file)
 * - an entry in  - (void)encodeWithCoder:(NSCoder*)encoder (for RW attributes only) (reading/writing to the .Orca file)
 * - a setter (changer) in controller.m/.h getting the current value from the model
 * - an entry in  - (void) registerNotificationObservers in controller.m
 * - an entry in - (void) updateWindow in controller.m (for the startup!)
 * - and the usual IBActions and outlets in the controller
 * - and the necessary connections in the interface builder
 * - finally RO attributs need a init section (in initWithCoder?)
 * - for the hardware wizard entries add  a section in - (NSArray*) ORKatrinFLTModel::wizardParameters
 * - for loading header parameters add a section in - (NSNumber*) ORKatrinFLTModel::extractParam:from:forChannel: 
 * - for writing the variable to the XML header of the Orca data file add it to - (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
 * - ...
 ***/
- (int) histoBinWidth
{
    return histoBinWidth;
}

/**  The getter for ORKatrinFLTModel::histoBinWidth (see ORKatrinFLTModel::histoBinWidth).
 */
- (void) setHistoBinWidth:(int)aHistoBinWidth
{
    //debug -tb- NSLog(@"Calling setHistoBinWidth %i ...\n",aHistoBinWidth);
    [[[self undoManager] prepareWithInvocationTarget:self] setHistoBinWidth:histoBinWidth];
    histoBinWidth = aHistoBinWidth;
	
    //debug -tb- NSLog(@"Sending notification ...\n");
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoBinWidthChanged object:self];
	
    //adjust max histo energy
    [self recalcHistoMaxEnergy];
}


- (unsigned int) histoMinEnergy
{    return histoMinEnergy;    }

- (void) setHistoMinEnergy:(unsigned int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistoMinEnergy:histoMinEnergy];
    //if(aValue>=0 && aValue<=histoMaxEnergy ){    // for now histoMaxEnergy is unused -tb- 2008-03-06
    histoMinEnergy = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoMinEnergyChanged object:self];
	
    //adjust max histo energy
    [self recalcHistoMaxEnergy];
}



- (unsigned int) histoMaxEnergy
{    return histoMaxEnergy;    }

- (void) setHistoMaxEnergy:(unsigned int)aValue
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setHistoMaxEnergy:histoMaxEnergy];
    if(histoMinEnergy<=aValue ){
        histoMaxEnergy = aValue;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoMaxEnergyChanged object:self];
}

/** Recalculate Emax by the current values of Emin (the offset) and bin size.
 */
- (void) recalcHistoMaxEnergy
{
    // compute max possible energy in histogram
    int numBins;
    if([self versionRegHWVersion]==0x2){
        numBins=1024;
        [self setHistoMaxEnergy: (histoMinEnergy+ ((1<<histoBinWidth)*numBins))];  // temporary ? -tb- 2008-03-06
        return;
    }
    numBins=512;
    //[self setHistoMaxEnergy: (histoMinEnergy+ ((1<<histoBinWidth)*numBins)/2)];  // temporary ? -tb- 2008-03-06
    [self setHistoMaxEnergy: [self getHistoEnergyOfBin: numBins withOffsetEMin: histoMinEnergy binSize: histoBinWidth]];
}

//! This is the first bin value which will be displayed on the GUI.
- (unsigned int) histoFirstBin
{    return histoFirstBin;    }


- (void) setHistoFirstBin:(unsigned int)aValue
{
    histoFirstBin = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoFirstBinChanged object:self];
}

//! This is the last bin value which will be displayed on the GUI.
- (unsigned int) histoLastBin
{    return histoLastBin;    }

- (void) setHistoLastBin:(unsigned int)aValue
{
    histoLastBin = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoLastBinChanged object:self];
}

/** The Histgrm:T_Run FLT register (RefreshTime in the GUI).
 *  
 */
- (unsigned int) histoRunTime
{    return histoRunTime;    }

/** Sets the Histgrm:T_Rec FLT register (RefreshTime in the GUI).
 * Values:  minimum 2 (recommended), maximum 16 bit or 32 bit?
 */
- (void) setHistoRunTime:(unsigned int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHistoRunTime:histoRunTime];
    histoRunTime = aValue;
    if(histoRunTime<1) histoRunTime=1;
    if(histoRunTime>65535) histoRunTime=65535;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoRunTimeChanged object:self];
}

- (unsigned int) histoRecordingTime
{    return histoRecordingTime;    }

- (void) setHistoRecordingTime:(unsigned int)aValue
{
    histoRecordingTime = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoRecordingTimeChanged object:self];
}

- (int) histoSelfCalibrationPercent
{    return histoSelfCalibrationPercent;    }

- (void) setHistoSelfCalibrationPercent:(int)aValue
{
    if(aValue<0) aValue=0;
    if(aValue>100) aValue=100;
    histoSelfCalibrationPercent = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoSelfCalibrationPercentChanged object:self];
}


- (BOOL)   histoCalibrationIsRunning
{    return histoCalibrationIsRunning;    }

- (void)   setHistoCalibrationIsRunning: (BOOL)aValue
{
    histoCalibrationIsRunning = aValue;
    // send notification to GUI
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
}


- (double) histoCalibrationElapsedTime
{    return histoCalibrationElapsedTime;    }

- (void)   setHistoCalibrationElapsedTime: (double)aTime
{
    histoCalibrationElapsedTime=floor(aTime*1000.0)/1000.0;// 3 digits after . are enough -tb-
    // send notification to GUI
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
}

- (unsigned int) histoCalibrationChan
{    return histoCalibrationChan;    }

- (void) setHistoCalibrationChan:(unsigned int)aValue
{
    histoCalibrationChan = aValue;
    [self setHistoFirstBin:histogramDataFirstBin[aValue]];//TODO: init with 511 -tb-
    [self setHistoLastBin:histogramDataLastBin[aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationChanChanged object:self];
}

- (BOOL) showHitratesDuringHistoCalibration {return showHitratesDuringHistoCalibration;}

- (void) setShowHitratesDuringHistoCalibration:(BOOL)aValue
{
    showHitratesDuringHistoCalibration=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelShowHitratesDuringHistoCalibrationChanged object:self];
}

- (BOOL) histoClearAtStart {return histoClearAtStart;}

- (void) setHistoClearAtStart:(BOOL)aValue
{
    histoClearAtStart=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoClearAtStartChanged object:self];
}

- (BOOL) histoClearAfterReadout {return histoClearAfterReadout;}

- (void) setHistoClearAfterReadout:(BOOL)aValue
{
    histoClearAfterReadout=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoClearAfterReadoutChanged object:self];
}


- (BOOL) histoStopIfNotCleared
{return histoStopIfNotCleared;}
- (void) setHistoStopIfNotCleared:(BOOL)aValue
{
    histoStopIfNotCleared=aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoStopIfNotClearedChanged object:self];
}

/** This is the 'Set Standard' button in the 'Histogram' tab.
 */
- (void) histoSetStandard
{
    [self setHistoClearAtStart: YES];
    [self setHistoClearAfterReadout: YES];
    [self setHistoStopIfNotCleared: NO];
}



//!< Returns the array of NSData objects keeping the hardware histogram.
- (NSMutableArray*) histogramData
{return histogramData;}

- (unsigned int) getHistogramData: (int)index forChan:(int)aChan
{
    if(histogramData){
        unsigned int *dataPtr=0; //place where the data is stored
        dataPtr=(unsigned int *)[[histogramData objectAtIndex:aChan] bytes];
        if(dataPtr) return dataPtr[index];
        else{
            NSLog(@"ERROR in getHistogramData:forChan: bad data pointer\n");
            return 42;
        }
    }
    return 23;
}


//!< Write aValue to the histogram data array for given channel at given index (index with range check => slow!).
- (void) setHistogramData: (int)index forChan:(int)aChan value:(int) aValue
{
    if(histogramData && index>=0 && index<1024){
        unsigned int *dataPtr=0; //place where the data is stored
        dataPtr=(unsigned int *)[[histogramData objectAtIndex:aChan] bytes];
        if(dataPtr)  dataPtr[index]=aValue;
        else{
            NSLog(@"ERROR in getHistogramData:forChan: bad data pointer\n");
        }
    }
}

//!< Add aValue to the histogram data array for given channel at given index (index with range check => slow!).
- (void) addHistogramData: (int)index forChan:(int)aChan value:(int) aValue
{
    if(histogramData && index>=0 && index<1024){
        unsigned int *dataPtr=0; //place where the data is stored
        dataPtr=(unsigned int *)[[histogramData objectAtIndex:aChan] bytes];
        if(dataPtr)  dataPtr[index]+=aValue;
        else{
            NSLog(@"ERROR in addHistogramData:forChan: bad data pointer\n");
        }
    }
}

//!< Clear (fill with 0) the histogram data array for given channel.
- (void) clearHistogramDataForChan:(int)aChan
{
    //if(histogramData && ([self histoChanToGroupMap:aChan] !=-1)){
    if(histogramData){
        unsigned int *dataPtr=0; //place where the data is stored
        dataPtr=(unsigned int *)[[histogramData objectAtIndex:aChan] bytes];
        if(dataPtr){
            int i;
            for(i=0;i< 1024 ;i++) dataPtr[i]=0;  // the buffer length is fixed to 1024, maybe change in V4 -tb-
        }
    }
}

/** Read EMin for the #histoCalibrationChan .*/
- (uint32_t) readEMin
{
    return [self readEMinForChan: [self histoCalibrationChan]];
}

- (uint32_t) readEMinForChan:(int)aChan
{
    int group = [self histoChanToGroupMap:aChan];
	// we assume that all pixels have the same E_min, E_max, ... during a run
    // debug output NSLog(@"readEMin: Pbus register is 0x%x\n", [self read:([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)]  ); 	
    if(group==-1 || aChan<0 || aChan>kNumFLTChannels-1) return 0xffffffff; //aChan unguilty
	
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x2; //0x2 is E_min
	return [self read: ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12)];
	
	
	
	// return [self readEMinForGroup: aChan];
}



/** Write the EMin to all allowed channels. Calls #writeEMin:forChan: and broadcast.*/
- (void) writeEMin:(int)EMin
{
    [self writeEMin:EMin forChan:31];// BROADCAST to all channels
}

/** Write the EMin to the given channel.  The FPGA hardware register needs EMin/2. */
- (void) writeEMin:(int)EMin forChan:(int)aChan
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x2; //0x2 is E_min
	[self write:   ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12) value: EMin/2];// write EMin/2 -tb-
	[self write:   ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12) value: EMin];// since May 2009 Emin/2 is not necessary any more -tb-
}


/** Read EMax for the #histoCalibrationChan . Better use readEMaxForChan: */ 
- (uint32_t) readEMax
{
	return [self readEMaxForChan:  [self histoCalibrationChan]  ];
}

- (uint32_t) readEMaxForChan:(int)aChan;
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x3; //0x3 is E_max
	return [self read: ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12)];
}

/** OBSOLETE. Write the EMax to all allowed channels. Calls #writeEMax:forGroup: 31*/
- (void) writeEMax:(int)EMax
{
	[self writeEMax:EMax forChan:31];// BROADCAST to all channels
}

/** OBSOLETE. */
- (void) writeEMax:(int)EMax forChan:(int)aChan
{
	NSLog(@"WARNING: you called writeEMax; this method is obsolete -tb-\n");
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x3; //0x3 is E_max
	[self write:   ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12) value: EMax];
}

/** Read TRun for the #histoCalibrationChan .*/
- (uint32_t) readTRun
{
	return [self readTRunForChan: [self histoCalibrationChan] ];
}

- (uint32_t) readTRunForChan:(int)aChan;
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x4; //0x4 is TRun
	return [self read: ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12)];
}


/** Write TRun to all allowed channels. Calls #writeTRun:forGroup: */
- (void) writeTRun:(int)TRun
{
    [self writeTRun:TRun forChan:31];
    // BROADCAST to all channels
}

- (void) writeTRun:(int)TRun forChan:(int)aChan
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x4; //0x4 is TRun
	[self write:   ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12) value: TRun];
}


/** Set the bin width and the start bit for hardware histogramming (all pixels).
 * Calls #writeStartHistogram:forGroup:
 * Groups are: 0 = chan 0,1,12,13,  1 = chan 2,3,14,15
 *
 * For FPGA version <3.x
 */  //-tb-
- (void) writeStartHistogram:(unsigned int)aHistoBinWidth
{
    int chan,group;
    for(chan=0; chan < kNumFLTChannels;chan++){
        group=[self histoChanToGroupMap:chan];
        if(group != -1) [self writeStartHistogram:histoBinWidth forChan:chan];
    }
}

//** For FPGA version <3.x -tb-
- (void) writeStartHistogram:(unsigned int)aHistoBinWidth    forChan:(int)aChan
{
    //HistControlReg
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x1; //0x1 is Histogrm:ControlReg
    unsigned int numBins = 0x3ff;         // N of Bins: 10 bit value, all to 1 => 0x3ff = 1023
    unsigned int eSample = aHistoBinWidth; // BW = E_Sample (observed energy is shifted by E_Sample:
	//                obsEnergy >> E_Sample, possible val. 0...8)
    unsigned int startBit = 0x1;
    unsigned int numBit = 0x0;
    switch(aChan){
		case 0: case 1: case 12: case 13: numBit = 0x0; break;
		case 3: case 4: case 14: case 15: numBit = 0x1; break;
    }
    
    unsigned int regVal= (numBins << 6) | (eSample << 2) | (numBit << 1) | (startBit);
    //NSLog(@"readLastBinForChan:%i Pbus register is %x\n",aGroup, ([self slot] << 24) | (func << 21) | (aGroup << 16) | (LAddr12 <<12)  ); 	
	[self write:   ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12) value: regVal];
}



/** This version is dedicated for FPGA version >=3.x. Since then the HistoControlRegister
 * contains only CLR bit and start/stop bit (and the unused 'select #-channels' bit).
 * Standard is: use the CLEAR bit.
 */
- (void) writeStartHistogramForChan:(int)aChan withClear:(BOOL)clear
{
    //HistControlReg
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x1; //0x1 is Histogrm:ControlReg
    unsigned int CLRBit = 0x0;  // the clear bit 
    unsigned int startBit = 0x1;
    unsigned int numBit = 0x0;
    switch(aChan){
		case 0: case 1: case 12: case 13:  case 31: numBit = 0x0; break;
		case 3: case 4: case 14: case 15:           numBit = 0x1; break;// this is obsolete/unused -tb-
    }
    if(clear) CLRBit = 0x1;
    
    unsigned int regVal= (CLRBit << 8) | (numBit << 1) | (startBit);
    //NSLog(@"readLastBinForChan:%i Pbus register is %x\n",aGroup, ([self slot] << 24) | (func << 21) | (aGroup << 16) | (LAddr12 <<12)  ); 	
	[self write:   ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12) value: regVal];
}

/** This version is dedicated for FPGA version >=3.x. Since then we have the HistoSettingsRegister
 * containing bin width and mode.
 @param aMode '0' = continous, '1' = stop if not cleared before
 */
- (void) writeHistogramSettingsForChan:(int)aChan mode:(unsigned int)aMode binWidth:(unsigned int)aHistoBinWidth
{
    //HistControlReg
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x3; //0x3 is Histogrm:H_Param = HistoSettingsReg
    unsigned int eSample = aHistoBinWidth; // BW = E_Sample (observed energy is shifted by E_Sample:
	//                obsEnergy >> E_Sample, possible val. 0...8)
    unsigned int modeBit = (aMode ? 0x1 : 0x0);
	
    uint32_t regVal=   (modeBit << 8) | eSample ;
    //NSLog(@"readLastBinForChan:%i Pbus register is %x\n",aGroup, ([self slot] << 24) | (func << 21) | (aGroup << 16) | (LAddr12 <<12)  ); 	
	[self write:   ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12) value: regVal];
}



/** Calls #writeStopHistogramForGroup for all allowed channels.
 */  //-tb-
- (void) writeStopHistogram
{
    //or use broadcast:  ...writeStopHistogramForChan:31... -tb-
    int chan,group;
    for(chan=0; chan < kNumFLTChannels;chan++){
        group=[self histoChanToGroupMap:chan];
        if(group != -1) [self writeStopHistogramForChan:chan];
    }
}

/** Write the stop bit for hardware histogramming (all pixels). Reads the current register contents,
 * flips the stop bit and write it back (so all other settings stay unchanged).
 * For old FPGA versions AND for versions >= 3.x.
 */  //-tb-
- (void) writeStopHistogramForChan:(int)aChan
{
    //stop histogramming
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x1; //0x1 is Histogrm:ControlReg
    unsigned int adress;//  = ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12);
    unsigned int regVal;
    unsigned int numBit = 0x0;
    switch(aChan){
		case 0: case 1: case 12: case 13: numBit = 0x0; break;
		case 3: case 4: case 14: case 15: numBit = 0x1; break;
    }
    
    adress  = ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12);
    if([self versionRegHWVersion]<0x3){
        //old version (<3.0): we had only one HistTrigg ControlReg
        regVal = (int)[self read: adress];// read  HistogrmControlReg
        regVal &= 0xfffffffc;// set the start/stop bit0 to 0=stop and prepare bit1 to 0
        regVal |= (numBit << 1) ; //
    }else{
        //new version (>=3.0): we use only the first bit in HistTriggControlReg
        regVal = (numBit << 1) ; //we use only numBit == 0 but to be sure ... -tb-
    }
	[self write: adress value: regVal];
}



/** Read TRec for the #histoCalibrationChan .*/
- (uint32_t) readTRec
{
	return [self readTRecForChan:  [self histoCalibrationChan] ];
}

- (uint32_t) readTRecForChan:(int)aChan
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x5; //0x5 is T_Rec
    // debug output -tb- NSLog(@"readTRec: Pbus register is 0x%x\n", [self read:([self slot] << 24) | (func << 21) | (aGroup << 16) | (LAddr12 <<12)  ]); 	
	return [self read: ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12)];
}


- (uint32_t) readFirstBinForChan:(int)aChan
{
    //int group = [self histoChanToGroupMap:aChan];
	//if(group==-1)	return 0xffffffff;
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x6; //0x6 is FirstBin
    // debug output -tb- NSLog(@"readTRec: Pbus register is 0x%x\n", [self read:([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12)  ]); 	
	return [self read: ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12)];
	
}


- (uint32_t) readLastBinForChan:(int)aChan
{
    //int group = [self histoChanToGroupMap:aChan];
	//if(group==-1) return 0xffffffff;
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x7; //0x7 is LastBin
	return [self read: ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12)];
}


/** Returns the histogram bin the given energy falls in for the given offset emin and bin size bs.
 * energy will be in "EnergyMode" units, emin and bs in "user interface" units.
 energy is double as for the binsize 1/2 the energy can be given in 1/5 steps/units.
 */ //-tb-
- (int) getHistoBinOfEnergy:(double) energy withOffsetEMin:(int) emin binSize:(int) bs
{
    int ienergy = (energy-emin)*2;
    return (ienergy) >> (bs);
    //return ((energy-emin)*2) >> (bs);  //this would give a comb shape -tb-
}

/** Returns the energy (at left end of the bin)  the given histogram bin contains for the given offset emin and bin size bs.
 * energy will be in "EnergyMode" units, emin and bs in "user interface" units.
 * For bs == 0 (i.e. binsize 1/2) the energy will be rounded down (to be a int value).
 *
 * Update for Histogram Version 2009-May:
 * The binsize scale has been "shifted" one step (bs=2 -> "user interface" =1)
 * Smallest bs is 2 so "user interface" binsize is  2^(bs-2) ((the exponent never is <0)
 */ //-tb-
- (int) getHistoEnergyOfBin:(int) bin  withOffsetEMin:(int) emin binSize:(int) bs
{
     // this code is used in ORKatrinFLTDecoder for the histogram decoder -tb-
    return ( ((bin) << (bs-2)) )   + emin; //since  May 2009 -tb-
    //return ( ((bin) << (bs))/4 )   + emin; //since  May 2009 -tb-
    //return ( ((bin) << (bs))/2 )   + emin; before May 2009
    //return (emin+ ((1<<bs)*bin)/2)];
}

/** Write some data to the histogram buffer of the given channel (for simulation mode).
 */ //-tb-
- (void) histoSimulateReadHistogramDataForChan:(int)aChan
{
    //DebugHistoTB(  NSLog(@"   histoSimulateReadHistogramDataForChan: chan %i\n",aChan);  )
    int val=aChan+1;
    int i,energy,bin,sum=0,firstBin=511, lastBin=0;
    if([self histoClearAfterReadout])
		for(i=0;i<1024;i++){//TODO: use something like bufferMaxIndex ... -tb-
			[self setHistogramData: i forChan:aChan value: 0];
		}
	
    for(i=0;i<200*val;i++){
        energy=val*400+i;
        bin=[self getHistoBinOfEnergy: (0.5*energy) withOffsetEMin:histoMinEnergy binSize:histoBinWidth];
        if(bin<0) bin=0;
        if(bin>511) bin=511;
        if(i==0) firstBin=bin;
        if(i>190*val) lastBin=bin;
        [self addHistogramData: bin forChan:aChan value: val];
        //DebugHistoTB(  NSLog(@"   SIM: writing: bin %i (energy %f) chan %i value %i\n",bin,(0.5*energy), aChan, val);  )
        sum += val;
    }
	// buffer all data for later readout and display
    histogramDataFirstBin[aChan]=firstBin;
    histogramDataLastBin[aChan]=lastBin;
    histogramDataSum[aChan]=sum;
    histogramDataRecTimeSec[aChan]=histoRecordingTime;
	
}


/** Start hardware histogramming test run ... usually called from GUI.
 *
 * We call the manually started histogramming run 'calibration run' or 'calibration histogram'.
 * The according methods have similar names: #startCalibrationHistogramOfChan,
 * #checkCalibrationHistogram, #stopCalibrationHistogram.
 */ //-tb-
- (void) startCalibrationHistogramOfChan:(int)aPixel
{
	fireWireCard			  = [[self crate] adapter];
  	usingPBusSimulation		  = [fireWireCard pBusSim];
    //BEGIN -  - of (pbus) simulatin mode -tb- 2008-04-06
    if(usingPBusSimulation){
		histoLastPageToggleSec=0;  // in simulation mode used for counting to TRun/RefreshTime
		[self setHistoCalibrationIsRunning:TRUE];
		[self setHistoRecordingTime:0];
		histoStartTimeSec = (int)[self readTime];
		[self setHistoCalibrationElapsedTime: 0];
		[self performSelector:@selector(checkCalibrationHistogram) withObject:nil afterDelay:0.1 /*0.1 sec*/];
		return;
    }
    //END   - of (pbus) simulatin mode -tb- 2008-04-06
	
    if([self versionRegHWVersion]>=0x3){
        //this is for FPGA version >= 3 (since April 2008), with new feature "paging" etc. -tb-
        int grouptest = 0;
        grouptest = [self histoChanToGroupMap:aPixel];
        //aPixel should be == histoCalibrationChan
        if(-1 == grouptest){
            NSLog(@"WARNING: Histogram Calibration Run: NOT STARTED (bad channel %i)\n",aPixel);
            return;
        }
        
        //check that we can actually run: is the run mode as needed?
        if(kKatrinFlt_DaqHistogram_Mode != [self daqRunMode]){ 
            savedDaqRunMode = [self daqRunMode];
            [self setDaqRunMode: kKatrinFlt_DaqHistogram_Mode];
            NSLog(@"WARNING: Histogram Calibration Run: switched DAQ Run Mode to 'Histogram' mode\n");
            //return;
        }else{
            savedDaqRunMode=-1;
        }
        
        
        if(![[[self crate] adapter] serviceIsAlive]){
            NSLog(@"WARNING: Histogram Calibration Run: NOT STARTED (no firewire)\n");
            [NSException raise:@"No FireWire Service" format:@"startHistogramOfPixel: Check Crate Power and FireWire Cable."]; 
        }
        
        NSLog(@"---------------------------------------------------------------\n");
        NSLog(@"Histogram Calibration Run: STARTED\n");
        
        //stop histogramming (maybe histogramming is still running from a previous run)
        if([self histogrammingIsActiveForChan:aPixel]){
            NSLog(@"Histogramming is still running: cold restart!\n");
            [self writeStopHistogramForChan:aPixel];
            //version <3.x ... [self writeHistogramControlRegisterOfPixel:aPixel value:([self readHistogramControlRegisterOfPixel:aPixel]&0xfffffffe)];
            usleep(1000000);
        }
        
        histoStartWaitingForPageToggle = FALSE;
        
        //write configuration:
        //set gains, thresholds, shaping
        [self loadThresholdsAndGains];
        //writeTriggerControl: see below ...
        if([self showHitratesDuringHistoCalibration]){
            //copied from runTaskStarted ... -tb-      
            [self writeHitRateMask];			//set the hit rate masks
            [self performSelector:@selector(readHitRates) 
                       withObject:nil 
                       afterDelay:[self hitRateLength]];		//start reading out the rates
            //needs stop with 	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
            
        }
        
        //set to energy mode (fltRunMode = 1)
        //[self setFltRunMode: kKatrinFlt_Run_Mode]; //is set by daq mode -tb-
        [self writeMode: fltRunMode]; //TODO : HANDLE EXCEPTION -TB- DONE!
        //NSLog(@"startHistogramOfPixel: WARNING: setFltRunMode to %x (was %x)\n",kKatrinFlt_Run_Mode,oldFltRunModeMode);
        
        //SLT: release SW inhibit
        sltmodel = [[self crate] adapter];
        [sltmodel releaseSwInhibit];
        
        { // write trigger settings, give warning message -tb-
            //enable trigger - see - (void) writeTriggerControl
            [self writeTriggerControl];
            if(![[triggersEnabled objectAtIndex:aPixel] intValue]){
                NSLog(@"WARNING: Histogram Calibration Run: trigger NOT enabled for selected channel (see Settings)\n");
            }
            //NSLog(@"startHistogramOfPixel: WARNING: triggerControl for current pixel is %i\n",
            //    [[triggersEnabled objectAtIndex:aPixel] intValue] );
            //NSLog(@"startHistogramOfPixel: WARNING: triggerControl for current pixel is 0x%x\n",
            //    [self readTriggerControl: aPixel]);
        }
        
        
        //histogramming registers (now I use a broadcast)
        [self writeEMin:histoMinEnergy forChan: 31 /*aPixel*/];
        //[self writeEMax:histoMaxEnergy forChan:aPixel];
        [self writeTRun:histoRunTime forChan: 31 /*aPixel*/];
        
        //clear the pages: (clears the pages in a 2 second "pre run")
        //    set TRun to 1, start histogramming with CLEAR bit, wait 1.1 sec or until page 1 is active, clear page, set TRun back
        if(histoClearAtStart){
            sltmodel = [[self crate] adapter];
            [self writeTRun:1 forChan: 31 /*aPixel*/];
            [sltmodel setSwInhibit];// suppress events -tb-
            [self writeStartHistogramForChan: 31 /*aPixel*/ withClear: histoClearAtStart];
            // will be cleared at start ... [self clearCurrentHistogramPageForChan:aPixel];// clear page 0 ...
            usleep(100000);
            while([self readCurrentHistogramPageNum] == 0){//wait until page 1 is active
                usleep(100000);
                NSLog(@"Waiting to clear page 1 (now %i)\n",[self readCurrentHistogramPageNum]);
            }
            [self clearCurrentHistogramPageForChan: 31 /*aPixel*/];// clear page 1
            [self writeStopHistogramForChan: 31 /*aPixel*/];       //stop 'clear' run
            //usleep(1000001);
            [sltmodel releaseSwInhibit];// allow events -tb-
            //restore TRun
            [self writeTRun:histoRunTime forChan: 31 /*aPixel*/];
        }
        
        //START HISTOGRAMMING:
        //  write HistSettingsReg
        //[self writeHistogramSettingsForChan:aPixel mode: histoStopIfNotCleared  binWidth: histoBinWidth ];
        //broadcast
        [self writeHistogramSettingsForChan:31 mode: histoStopIfNotCleared  binWidth: histoBinWidth ];
		
        //  start procedure: (needs carefull timing)
        struct timeval t;
        //wait after second strobe to give FPGA time to clear the histogram, so it has at least 1 sec until next page toggle
        //  (I also could read subseconds with readTimeSubSec and start immediatly if >0.1 sec before sec strobe)
        gettimeofday(&t,NULL);
        histoLastSecStrobeSec = (int)t.tv_sec;
        histoLastSecStrobeUSec = (int)t.tv_usec;
        int lastSecStrobe = (int)[self readTime];
        DebugHistoTB(  NSLog(@"lastSecStrobe is %i\n",lastSecStrobe);  )
        int sec;
        do{
            histoLastSecStrobeSec = (int)t.tv_sec;
            histoLastSecStrobeUSec = (int)t.tv_usec;
            sec = (int)[self readTime];
            gettimeofday(&t,NULL);
        }while(sec==lastSecStrobe);
        DebugHistoTB(  NSLog(@"sec is %i \n",sec);  )
		
        //starting - write HistControlReg
        //[self writeStartHistogramForChan:aPixel withClear: histoClearAtStart];
        // broadcast
        [self writeStartHistogramForChan:31 withClear: histoClearAtStart];
        //wait again until next sec strope - THEN histogramming will start
        gettimeofday(&t,NULL);
        histoLastSecStrobeSec = (int)t.tv_sec;
        histoLastSecStrobeUSec = (int)t.tv_usec;
        lastSecStrobe = (int)[self readTime];// lastSecStrobe=sec;
        do{
            histoLastSecStrobeSec = (int)t.tv_sec;
            histoLastSecStrobeUSec = (int)t.tv_usec;
            sec = (int)[self readTime];
            gettimeofday(&t,NULL);
        }while(sec==lastSecStrobe);
        DebugHistoTB(  NSLog(@"sec is %i\n",sec);  )
		
        //remember active page
        histoLastActivePage = [self readCurrentHistogramPageNum];
        //set vars
        [self setHistoCalibrationElapsedTime: 0.0];
        [self setHistoCalibrationIsRunning:TRUE];
        histoStartWaitingForPageToggle = FALSE;
        histoLastPageToggleSec = histoLastSecStrobeSec;   //used for timing of page toggle.
        histoLastPageToggleUSec= histoLastSecStrobeUSec;  //  ''
        histoPreToggleSec      = histoLastSecStrobeSec; 
        histoPreToggleUSec     = histoLastSecStrobeUSec; 
        
        //remember the start time 
        // there are (Auger) methods readTime and readTimeSubSec (from self), do they work for Katrin? -tb-
        //struct timeval t;//    struct timezone tz; is obsolete ... -tb-
        gettimeofday(&t,NULL);
        histoStartTimeSec = (int)t.tv_sec;
        histoStartTimeUSec = (int)t.tv_usec;
        
        // start delayed timing ...
        [self performSelector:@selector(checkCalibrationHistogram) withObject:nil afterDelay:0.1 /*sec*/];
        return;
    }
	
	
    //BEGIN - this is obsolete but left for downward compatibility for older FPGA configurations -tb- 2008-04-06
    //this is for old versions < 3 (between Nov 2007 and April 2008), first test versions -tb-
    if([self versionRegHWVersion]<0x3){
		//I keep the code for testing -tb-
        int groupt = 0;
        groupt = [self histoChanToGroupMap:aPixel];
        //aPixel should be == histoCalibrationChan
        if(-1 == groupt){
            NSLog(@"WARNING: Histogram Calibration Run: NOT STARTED (bad channel %i)\n",aPixel);
            return;
        }
        
        //check that we can actually run: is the run mode as needed?
        if(kKatrinFlt_DaqHistogram_Mode != [self daqRunMode]){
            savedDaqRunMode = [self daqRunMode];
            [self setDaqRunMode: kKatrinFlt_DaqHistogram_Mode];
            NSLog(@"WARNING: Histogram Calibration Run: switched DAQ Run Mode to 'Histogram' mode\n");
            //return;
        }else{
            savedDaqRunMode=-1;
        }
        
        
        if(![[[self crate] adapter] serviceIsAlive]){
            NSLog(@"WARNING: Histogram Calibration Run: NOT STARTED (no firewire)\n");
            [NSException raise:@"No FireWire Service" format:@"startHistogramOfPixel: Check Crate Power and FireWire Cable."]; 
        }
        
        NSLog(@"---------------------------------------------------------------\n");
        NSLog(@"Histogram Calibration Run: STARTED\n");
        
        //stop histogramming (maybe histogramming is still running from a previous run)
        //TODO: temporarily disabled -tb- 2008-04-01
        //[self writeStopHistogramForChan:aPixel];
        [self writeHistogramControlRegisterOfPixel:aPixel value:([self readHistogramControlRegisterOfPixel:aPixel]&0xfffffffe)];
        
        //write configuration:
        //set gains, thresholds, shaping
        [self loadThresholdsAndGains];
        //writeTriggerControl: see below ...
        
        
        //set to energy mode (fltRunMode = 1)
        //[self setFltRunMode: kKatrinFlt_Run_Mode]; //is set by daq mode -tb-
        [self writeMode: fltRunMode]; //TODO : HANDLE EXCEPTION -TB- DONE!
        //NSLog(@"startHistogramOfPixel: WARNING: setFltRunMode to %x (was %x)\n",kKatrinFlt_Run_Mode,oldFltRunModeMode);
        
        //SLT: release SW inhibit
        sltmodel = [[self crate] adapter];
        [sltmodel releaseSwInhibit];
        
        { // write trigger settings, give warning message -tb-
            //enable trigger - see - (void) writeTriggerControl
            [self writeTriggerControl];
            if(![[triggersEnabled objectAtIndex:aPixel] intValue]){
                NSLog(@"WARNING: Histogram Calibration Run: trigger NOT enabled for selected channel (see Settings)\n");
            }
            //NSLog(@"startHistogramOfPixel: WARNING: triggerControl for current pixel is %i\n",
            //    [[triggersEnabled objectAtIndex:aPixel] intValue] );
            //NSLog(@"startHistogramOfPixel: WARNING: triggerControl for current pixel is 0x%x\n",
            //    [self readTriggerControl: aPixel]);
        }
        
        
        //histogramming registers
        [self writeEMin:histoMinEnergy forChan:aPixel];
        [self writeEMax:histoMaxEnergy forChan:aPixel];
        [self writeTRun:histoRunTime forChan:aPixel];
        
        //start histogramming
        //HistControlReg
        [self writeStartHistogram:histoBinWidth forChan:aPixel];
        
        //set vars
        [self setHistoCalibrationElapsedTime: 0.0];
        [self setHistoCalibrationIsRunning:TRUE];
        
        //remember the start time
        // there are (Auger) methods readTime and readTimeSubSec (from self), do they work for Katrin? -tb-
        struct timeval t;//    struct timezone tz; is obsolete ... -tb-
        gettimeofday(&t,NULL);
        histoStartTimeSec = (int)t.tv_sec;
        histoStartTimeUSec = (int)t.tv_usec;
        
        // start delayed timing ...
        [self performSelector:@selector(checkCalibrationHistogram) withObject:nil afterDelay:0.1 /*sec*/];
    }
    //END - this is obsolete but left for downward compatibility for older FPGA configurations -tb- 2008-04-06
    
}


/** This implements the histogramming "test run loop".
 * Updates the GUI with the current histogramming parameters.
 * Check whether hardware histogramming still runs (histoTestIsRunning is TRUE)  ... if yes restart itself ...
 *
 */ //-tb-
- (void) checkCalibrationHistogram
{
  	//usingPBusSimulation		  = [fireWireCard pBusSim];
    //BEGIN -  - of (pbus) simulatin mode -tb- 2008-04-06
    if(usingPBusSimulation){
        unsigned int chan=[self histoCalibrationChan];
        static double delayTime = 0.1; // in sec.: its a kind of 'local const' -tb-
        uint32_t tRun;
        uint32_t tRec;
        tRun = histoRunTime;
        if(tRun != 0){// we are in "restart mode": read out the histogram when tRun elapsed
            tRec = histoLastPageToggleSec;
            if(  tRec >= tRun){//after tRun seconds write a histogram and reset timer
                DebugHistoTB(  NSLog(@"ORKatrinFLT %02d: emulate readout in histogram mode (cal.).\n",[self stationNumber]);  )
                //copied from TakeDataHistogramMode ... readOutHistogramDataV3 ... -tb-
                [self histoSimulateReadHistogramDataForChan: chan];
                //update GUI
                [self setHistoFirstBin: histogramDataFirstBin[chan]];
                [self setHistoLastBin:  histogramDataLastBin[chan]];
                [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationPlotterChanged object:self];
                histoLastPageToggleSec=0;
                if(histoSelfCalibrationCounter) histoSelfCalibrationCounter++;
                if(histoSelfCalibrationCounter>4){
                    DebugHistoTB(  NSLog(@"ORKatrinFLT %i: Histogramming: should stop self calibration.\n",[self stationNumber]);  )
                    [self stopCalibrationHistogram];
                    //histoSelfCalibrationCounter=0;
                    [self histoAnalyseSelfCalibrationRun];
                }
            }
        }//else if TRun == 0 we have to emulate the "read out" after run stop i.e. in runTaskStopped
        // Wait for the second strobe
        uint32_t sec = [self readTime];   //QUESTION is this the crate time? format? yes; full seconds -tb- 2008-02-26
        [self setHistoCalibrationElapsedTime: sec - histoStartTimeSec];
        if ( sec-lastSec >=1 ) {  // 2 = every  3 seconds
            DebugHistoTB(  NSLog(@"This is   takeDataHistogramMode heartbeat: %i\n",sec);  )
            // send notification to GUI
            [self setHistoRecordingTime:histoLastPageToggleSec];
            histoLastPageToggleSec ++; //increase every second to emulate the TRun counter on the board
            //[self setHistoFirstBin:[self readFirstBinForChan:aPixel]];//TODO: testing with pixel 0 -tb-
            //[self setHistoLastBin:[self readLastBinForChan:aPixel]];
            //[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
            lastSec = sec; // Store the  actual second counter
            // Found second counter
            //NSLog(@"Time %d\n", sec);
        }
        if(histoCalibrationIsRunning){
            //restart timing ...
            [self performSelector:@selector(checkCalibrationHistogram) withObject:nil afterDelay:delayTime /*0.1 sec*/];
        }
        return;
    }
    //END   - of (pbus) simulatin mode -tb- 2008-04-06
	
    if([self versionRegHWVersion]>=0x3){
		
        //check that we can actually run  TODO : do I need it here ? -tb- I think yes, to be safe -tb-
        if(![[[self crate] adapter] serviceIsAlive]){
            [self setHistoCalibrationIsRunning:FALSE];
            [NSException raise:@"No FireWire Service" format:@"checkCalibrationHistogram: Check Crate Power and FireWire Cable."]; 
        }
        
        //vars
        static double delayTime = 0.1; // in sec.: its a kind of 'local const' -tb-
        unsigned int aPixel=[self histoCalibrationChan];
        int histoCurrentActivePage=0;
        int currentSec;
        int currentUSec;
        struct timeval t;//    struct timezone tz; is obsolete ... -tb-
        //timing
        gettimeofday(&t,NULL);
        currentSec = (int)t.tv_sec;
        currentUSec = (int)t.tv_usec;
        double diffTime = (double)(currentSec  - histoLastPageToggleSec) +
		((double)(currentUSec - histoLastPageToggleUSec)) * 0.000001;
		
        DebugHistoTB(
					 histoCurrentActivePage = [self readCurrentHistogramPageNum]; 
					 NSLog(@"Time since last paging; %f     (page %i,TRec %i, status %i)\n",
						   diffTime,histoCurrentActivePage,[self histoRecordingTime],[self readHistogramControlRegisterOfPixel:aPixel]);
					 )
        
        //TEST, IF HISTOGRAMMING IS STILL RUNNING: (check before histoLastActivePage = histoCurrentActivePage;)
        //if TRun was set, maybe the run already stopped ... or we are in "stop if not cleared" mode ...
        //or somebody clicked Run Start, then SLT resets allFLTs = stops histogramming
        //if(histoCalibrationIsRunning  &&  !([self readHistogramControlRegisterOfPixel:aPixel] & 0x1)  ){
        if(histoCalibrationIsRunning){
            //int flag= [self readHistogramControlRegisterOfPixel:aPixel] &0x1;
            int flag= [self readHistogramControlRegisterOfPixel:aPixel] &0x1;
            if(flag==0){
                [self stopCalibrationHistogram];
                //NSLog(@"---CONTINUE3----- FLAG is %i (%i)\n",flag,[self readHistogramControlRegisterOfPixel:aPixel]);
                return;
            }
        }
        
        
        //START waiting/testing FOR the PAGE TOGGLE if there are about 0.2 sec left to cycle end (TRun)
        //    (if TRun is 0, we will immediately start waiting for the page toggling)
        if(!histoStartWaitingForPageToggle   && ((double)[self histoRunTime]) - diffTime <= 2.0*delayTime){/*0.1 sec*/
            histoStartWaitingForPageToggle = TRUE;
            histoCurrentActivePage = [self readCurrentHistogramPageNum];
            DebugHistoTB(  NSLog(@"    Prepare to wait for second strobe/page (old %i, curr %i) toggle to readout histogram.\n",histoLastActivePage,histoCurrentActivePage);  )
        }
        //TODO: test the time
        //if  ((double)[self histoRunTime]) - diffTime < 0 ) then: something wrong with toggle bit
		// if(TRec == 0) restart anyway
		// ...
        //waiting for toggle to readout the histogram
        gettimeofday(&t,NULL);
        if(histoStartWaitingForPageToggle){
            histoCurrentActivePage = [self readCurrentHistogramPageNum];
            if(histoCurrentActivePage != histoLastActivePage){//TODO: I could additionally check if TRun elapsed -tb-
                // yes, there was the toggle, read out the page/histogram
                DebugHistoTB(  NSLog(@"READ HISTOGRAM\n");  )
                [self readHistogramDataForChan:aPixel];
                //now display it, care not to clear the display in the next lines ...
                [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationPlotterChanged object:self];
                //first bin/last bin needs display now, they will be cleared afterwards
                [self setHistoFirstBin: histogramDataFirstBin[aPixel]];
                [self setHistoLastBin:  histogramDataLastBin[aPixel]];
                // dont read again from hardware [self setHistoFirstBin:[self readFirstBinForChan:aPixel]];
                //[self setHistoLastBin: [self readLastBinForChan:aPixel]];
                
                //handle the self calibration run
                if(histoSelfCalibrationCounter) histoSelfCalibrationCounter++;
                if(histoSelfCalibrationCounter>4){ //after 4 runs all buffers were cleared
                    DebugHistoTB(  NSLog(@"ORKatrinFLT %i: Histogramming: should stop self calibration.\n",[self stationNumber]);  )
                    [self stopCalibrationHistogram];
                    //histoSelfCalibrationCounter=0;
                    [self histoAnalyseSelfCalibrationRun];
                    return;
                }
				
                //CLEAR
                if([self histoClearAfterReadout]){
                    DebugHistoTB(  NSLog(@"CLEAR HISTOGRAM\n");  )
                    //[self clearCurrentHistogramPageForChan:aPixel];
                    //TODO: broadcast
                    [self clearCurrentHistogramPageForChan: 31];
                }
                //reset flags etc
                histoStartWaitingForPageToggle = FALSE;
                histoLastActivePage = histoCurrentActivePage;
                histoLastPageToggleSec = histoPreToggleSec;   //used for timing of page toggle.
                histoLastPageToggleUSec= histoPreToggleUSec;  //  ''
				//maybe the time from last call would be better
            } // else continue ... waiting for toggle ...
        }
        //remember for next call
        histoPreToggleSec      = currentSec; 
        histoPreToggleUSec     = currentUSec; 
        
        
        
        //HANDLE THE GUI (the KatrinFLTController)
        //NSLog(@"This is checkHistogramOfPixel: %i\n",aPixel  ); 	
        //update time
        int histoCurrTimeSec; 
        int histoCurrTimeUSec; 
        //gettimeofday(&t,NULL);
        //histoCurrTimeSec = t.tv_sec;  
        //histoCurrTimeUSec = t.tv_usec; 
        histoCurrTimeSec = currentSec;  
        histoCurrTimeUSec = currentUSec; 
        [self setHistoCalibrationElapsedTime: (double)(histoCurrTimeSec - histoStartTimeSec) + 0.000001 * (double)(histoCurrTimeUSec - histoStartTimeUSec)];
        //NSLog(@"This is checkHistogramOfPixel:       %20i %20i \n",  histoCurrTimeSec,histoCurrTimeUSec); 	
        //NSLog(@"This is checkHistogramOfPixel:       %20.12f \n",  histoTestElapsedTime); 	
        
        // recording time etc. from FLT
        [self setHistoRecordingTime:(int)[self readTRec]];//TODO: which one for multiple pixel ? -tb-
		//TODO: use ch 0 and use broadcasts
		//TODO:  broadcasts
        //[self setHistoFirstBin:[self readFirstBinForChan:aPixel]];
        //[self setHistoLastBin: [self readLastBinForChan:aPixel]];
        
        // send notification to GUI
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
        
        // update page textfield TODO: make more elegant? -tb- (write setter/getter etc...)
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoPageNumChanged object:self];
        
        if(histoCalibrationIsRunning){
            //restart timing ...
            [self performSelector:@selector(checkCalibrationHistogram) withObject:nil afterDelay:delayTime /*0.1 sec*/];
        }
    }
    
    
    
    
    
    //BEGIN - this is obsolete but left for downward compatibility for older FPGA configurations -tb- 2008-04-06
    if([self versionRegHWVersion] < 0x3){
        
        //check that we can actually run  TODO: do I need it here ? -tb-
        if(![[[self crate] adapter] serviceIsAlive]){
            [self setHistoCalibrationIsRunning:FALSE];
            [NSException raise:@"No FireWire Service" format:@"checkHistogramOfPixel: Check Crate Power and FireWire Cable."]; 
        }
        
        
        unsigned int aPixel=[self histoCalibrationChan];   //TODO: for release version check all pixels ? -tb-
        
        //NSLog(@"This is checkHistogramOfPixel: %i\n",aPixel  ); 	
        //update time
        int histoCurrTimeSec; 
        int histoCurrTimeUSec; 
        struct timeval t;//    struct timezone tz; is obsolete ... -tb-
        gettimeofday(&t,NULL);
        histoCurrTimeSec = (int)t.tv_sec;
        histoCurrTimeUSec = (int)t.tv_usec;
        [self setHistoCalibrationElapsedTime: (double)(histoCurrTimeSec - histoStartTimeSec) + 0.000001 * (double)(histoCurrTimeUSec - histoStartTimeUSec)];
        //NSLog(@"This is checkHistogramOfPixel:       %20i %20i \n",  histoCurrTimeSec,histoCurrTimeUSec); 	
        //NSLog(@"This is checkHistogramOfPixel:       %20.12f \n",  histoTestElapsedTime); 	
        
        // recording time etc. from FLT
        [self setHistoRecordingTime:(int)[self readTRec]];//TODO: which one for multiple pixel ? -tb-
        [self setHistoFirstBin:(int)[self readFirstBinForChan:aPixel]];
        [self setHistoLastBin:(int)[self readLastBinForChan:aPixel]];
        
        // send notification to GUI
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
        
        // update page textfield TODO: make more elegant? -tb- (write setter/getter etc...)
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoPageNumChanged object:self];
        
        //if TRun was set, maybe the run already stopped ...
        //or somebody clicked Run Start, then SLT resets allFLTs = stops histogramming
        //if(histoCalibrationIsRunning  &&  !([self readHistogramControlRegisterOfPixel:aPixel] & 0x1)  ){
        if(histoCalibrationIsRunning){
            //int flag= [self readHistogramControlRegisterOfPixel:aPixel] &0x1;
            int flag= [self readHistogramControlRegisterOfPixel:aPixel] &0x1;
            if(flag==0){
                [self stopCalibrationHistogram];
                NSLog(@"---CONTINUE3----- FLAG is %i (%i)\n",flag,[self readHistogramControlRegisterOfPixel:aPixel]);
                return;
                
            }
        }
        
        if(histoCalibrationIsRunning){
            //restart timing ...
            [self performSelector:@selector(checkCalibrationHistogram) withObject:nil afterDelay:0.1 /*sec*/];
        }
    }
    //END - this is obsolete but left for downward compatibility for older FPGA configurations -tb- 2008-04-06
    
	
}


/** Stop hardware histogramming test run, which was started by #startCalibrationHistogramOfPixel  ...
 *
 */ //-tb-
- (void) stopCalibrationHistogram
{
  	//usingPBusSimulation		  = [fireWireCard pBusSim];
    //BEGIN -  - of (pbus) simulatin mode -tb- 2008-04-06
    if(usingPBusSimulation){
        [self setHistoCalibrationIsRunning:NO];
        //NSLog(@"Recording time was: %i\n",[self readTRec]);
        // to be safe ... cancel delayed timer ...
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkCalibrationHistogram) object:nil];
        
        NSLog(@"Histogram Calibration Run: FINISHED\n");
        NSLog(@"---------------------------------------------------------------\n");
        return;
    }
    //END   - of (pbus) simulatin mode -tb- 2008-04-06
	
    if([self versionRegHWVersion]>=0x3){
        //this is for FPGA version >= 3 (since April 2008), with new feature "paging" etc. -tb-
		
        //to update the GUI
        [self setHistoRecordingTime:(int)[self readTRec]];
        //first/last bin is updated after page toggle, see below
        
        //set vars
        [self setHistoCalibrationIsRunning:FALSE];
        histoStartWaitingForPageToggle = FALSE;
        // to be safe ... cancel delayed timer ...
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkCalibrationHistogram) object:nil];
		
        unsigned int Pixel = [self histoCalibrationChan];        //this is for FPGA version >= 3 (since April 2008), with new feature "paging" etc. -tb-
        
        //stop histogramming
        //[self writeStopHistogramForChan:Pixel];
		//TODO: broadcast
        [self writeStopHistogramForChan:31];
		
        //stop hitrate display  ... copied from runTaskStarted ... -tb-      
        if([self showHitratesDuringHistoCalibration]) 
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
        
        //TIMING
        //remember the stop time TODO: work in progress -tb- 2008-02-18
        // there are (Auger) methods readTime and readTimeSubSec (from self), do they work for Katrin? -tb-
        struct timeval t;//    struct timezone tz; is obsolete ... -tb-
        gettimeofday(&t,NULL);
        histoStopTimeSec = (int)t.tv_sec;
        histoStopTimeUSec = (int)t.tv_usec;
        [self setHistoCalibrationElapsedTime:(histoStopTimeSec - histoStartTimeSec) + 0.000001 * (histoStopTimeUSec - histoStartTimeUSec)];
        
        //SLT: set SW inhibit
        sltmodel = [[self crate] adapter];
        [sltmodel setSwInhibit];
        
        //wait until the page toggled that we can readout
        int histoCurrentActivePage ;
        DebugHistoTB(  NSLog(@"Waiting for page toggle (curr is %i)\n",histoLastActivePage);  )
        int i;
        for(i=0;i<10000;i++){
            histoCurrentActivePage= [self readCurrentHistogramPageNum];
            if(histoLastActivePage!=histoCurrentActivePage) break;
            usleep(100);
        }
        DebugHistoTB(  NSLog(@"Waited until i=%i (x 100 usecs) for page toggle\n",i);  )
        //usleep(1000011);
        
        //Update GUI:
        //[self checkCalibrationHistogram]; // NO! TRec is 0 after stop, see above -tb-
        [self readHistogramDataForChan:Pixel];
        // send notification to GUI
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationPlotterChanged object:self];
        
        // send notifications to GUI to show some values (MAC Time, progress bar, re-enable some elements ...
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
        // update page textfield TODO: make more elegant? -tb- (write setter/getter etc...)
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoPageNumChanged object:self];
        [self setHistoFirstBin:(int)[self readFirstBinForChan:Pixel]];
        [self setHistoLastBin:(int)[self readLastBinForChan:Pixel]];
		
        if(savedDaqRunMode != -1){
            [self setDaqRunMode: savedDaqRunMode];
            savedDaqRunMode = -1;
        }
        
        histoSelfCalibrationCounter = 0;
        
        NSLog(@"Recording time was: %i\n",[self readTRec]);
        
        NSLog(@"Histogram Calibration Run: FINISHED\n");
        NSLog(@"---------------------------------------------------------------\n");
    }
    
    
    
    //BEGIN - this is obsolete but left for downward compatibility for older FPGA configurations -tb- 2008-04-06
    if([self versionRegHWVersion] < 0x3){
        //set vars
        [self setHistoCalibrationIsRunning:FALSE];
        unsigned int Pixel = [self histoCalibrationChan];
        //stop histogramming
        [self writeStopHistogramForChan:Pixel];
        if([self versionRegHWVersion]>=0x3){
            //this is for FPGA version >= 3 (since April 2008), with new feature "paging" etc. -tb-
            //stop hitrate display  ... copied from runTaskStarted ... -tb-      
            if([self showHitratesDuringHistoCalibration]) 
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
        }
        //TIMING
        //remember the stop time TODO: work in progress -tb- 2008-02-18
        // there are (Auger) methods readTime and readTimeSubSec (from self), do they work for Katrin? -tb-
        struct timeval t;//    struct timezone tz; is obsolete ... -tb-
        gettimeofday(&t,NULL);
        histoStopTimeSec  = (int)t.tv_sec;
        histoStopTimeUSec = (int)t.tv_usec;
        [self setHistoCalibrationElapsedTime:(histoStopTimeSec - histoStartTimeSec) + 0.000001 * (histoStopTimeUSec - histoStartTimeUSec)];
        //SLT: set SW inhibit
        sltmodel = [[self crate] adapter];
        [sltmodel setSwInhibit];
        //wait one second (HW histogramming is every second strobe) then display histogram ...
#if 0
        [self performSelector:@selector(oneSecAfterStopHistogramOfPixel) withObject:nil afterDelay:1.01 /*sec*/];
#else
        usleep(1000011);
        [self checkCalibrationHistogram];
        [self readHistogramDataForChan:Pixel];
        // send notification to GUI
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationPlotterChanged object:self];
#endif
        if(savedDaqRunMode != -1){
            [self setDaqRunMode: savedDaqRunMode];
            savedDaqRunMode = -1;
        }
        NSLog(@"Recording time was: %i\n",[self readTRec]);
        NSLog(@"Histogram Calibration Run: FINISHED\n");
        NSLog(@"---------------------------------------------------------------\n");
    }
    //END - this is obsolete but left for downward compatibility for older FPGA configurations -tb- 2008-04-06
}


/** Self calibration of histogramming settings.
 * This is done in the following steps:
 * - set E_Min =0
 * - Bin Size = fit according to the shaping time (so that the full range fits into hw histogram)
 * - calibration run starten (TRun Ÿbernehmen, wenn TRun != 0, sonst TRun = 10)
 * - cut given percentage of hits (from left and right) and  adjust EMin and BinSize, so that remaining counts fit into hw histogram
 */  //-tb-
- (void) histoRunSelfCalibration
{
    NSLog(@"Self Calibration is still under construction!\n");
    // 0. Set Standard settings
	[self histoSetStandard];
    // 1. Emin=0
    [self setHistoMinEnergy:0];
    // 2. adjust bin size according to shaping time (1.+2. is to assure all energies will fit into histogram)
    int shapingT = [self shapingTime: [self histoChanToGroupMap:histoCalibrationChan]];
	//NSLog(@"histoRunSelfCalibration: shapingTime is %i (of ch %i)\n",shapingT,histoCalibrationChan);
    int max=((0x1 << shapingT) * 4096) /8;  // this is the max energy in energy mode
    int maxhisto;
    int numbinsize=16;
    int numBins=512;
    int bs; // the bin size
    for(bs=0;bs<numbinsize-1;bs++){
        //maxhisto=(histoMinEnergy+ ((1<<bs)*numBins)/2);
        maxhisto=[self getHistoEnergyOfBin: numBins withOffsetEMin: histoMinEnergy binSize: bs];
        //NSLog(@"Compare maxhisto %i (%i) with max %i\n",maxhisto,[self getHistoEnergyOfBin: numBins withOffsetEMin: 0 binSize: bs],max);
        if(maxhisto>=max) break;
    }
    [self setHistoBinWidth:bs];
    // 3. set the RefreshTime
    if(histoRunTime == 0  ||  histoRunTime <5) [self setHistoRunTime: 5];
    
    // x. start histogramming
    histoSelfCalibrationCounter = 1;
    [self startCalibrationHistogramOfChan:[self histoCalibrationChan]];
    //final analysis is in - (void) histoAnalyseSelfCalibrationRun called in checkHisto...
}

/** "Cut" histoSelfCalibrationPercent*0.5 from left and right, fit the remaining histogram into the 512 bins.
 *
 */
- (void) histoAnalyseSelfCalibrationRun
{
    DebugHistoTB(    NSLog(@"histoAnalyseSelfCalibrationRun: analyse results of run!\n" );   )
    int aChan=[self histoCalibrationChan];
    unsigned int *dataPtr=0; //place where the data is stored
    dataPtr=(unsigned int *)[[histogramData objectAtIndex:aChan] bytes];
    int i,sum=0, num=1024;
    for(i=0;i< num ;i++) sum += dataPtr[i];
    if(sum==0){
        NSLog(@"WARNING: Histogramming Self Calibration Run:  there were no events!\n"); 
        goto clean_up_mark;
    }
    double p2 = 0.005*((100-histoSelfCalibrationPercent)*sum);// 0.005 = 0.01 / 2 ; ps is the number of hits to be cut away left and right
    DebugHistoTB(   NSLog(@"histoAnalyseSelfCalibrationRun:  histosum %i p2 %f \n", sum ,p2);   )
    //the indices left and right are the border bins to fit into the histogram
    int left=0,right=num-1;
    sum=0;
    for(i=0;i< num ;i++){
        left=i;
        sum += dataPtr[i];
		DebugHistoTB(  if(i<3 || sum>0)  NSLog(@"histoAnalyseSelfCalibrationRun: indices: left %i right %i sum %i p2 %f \n",left, right,sum ,p2);   )
        if(sum>p2) break;
    }
    sum=0;
    for(i=num-1;i>=0 ;i--){
        right=i;
        sum += dataPtr[i];
		DebugHistoTB(   if((i>num-4) || sum>0)   NSLog(@"histoAnalyseSelfCalibrationRun: indices: left %i right %i sum %i p2 %f \n",left, right,sum ,p2);   )
        if(sum>p2) break;
    }
    DebugHistoTB(    NSLog(@"histoAnalyseSelfCalibrationRun: indices: left %i right %i\n",left, right );   )
    
    //compute leftenergy, rightenergy
    int leftenergy, rightenergy, emin,binsize;
    emin = [self histoMinEnergy];
    binsize = [self histoBinWidth];
    leftenergy =  [self getHistoEnergyOfBin:left withOffsetEMin: emin binSize: binsize];
    rightenergy = [self getHistoEnergyOfBin:right withOffsetEMin: emin binSize: binsize];
    //DebugHistoTB(    NSLog(@"histoAnalyseSelfCalibrationRun: leftenergy %i rightenergy %i\n",leftenergy, rightenergy );   )
    //now compute bin size so that (rightenergy-leftenergy) will fit into histogram
    {// copy from histoRunSelfCalibration
        int max= (rightenergy-leftenergy);
        int maxhisto;
        int numbinsize=16;
        int numBins=512;
        int bs; // the bin size
        for(bs=0;bs<numbinsize-1;bs++){
            //maxhisto=(histoMinEnergy+ ((1<<bs)*numBins)/2);
            maxhisto=[self getHistoEnergyOfBin: numBins withOffsetEMin: 0 binSize: bs];
            //NSLog(@"Compare maxhisto %i (%i) with max %i\n",maxhisto,[self getHistoEnergyOfBin: numBins withOffsetEMin: 0 binSize: bs],max);
            if(maxhisto>=max) break;
        }
        DebugHistoTB(    NSLog(@"Histo Self calibration suggestion: bin size %i, min energy %i\n",bs,leftenergy);  )
        leftenergy = (leftenergy/10)*10; //round down
        if(bs==0) bs=1;//we prefer 1
        DebugHistoTB(    NSLog(@"Histo Self calibration:  take: bin size %i, min energy %i\n",bs,leftenergy);  )
        [self setHistoBinWidth:bs];
        // ... and set EMin to leftenergy
        [self setHistoMinEnergy:leftenergy];
    }
    
clean_up_mark:
    //clean up
    histoSelfCalibrationCounter=0;
}


/** Returns the histogram data  address for the read access to the crate.
 * @param aBin the bin; if aBin==0 the base address (=address of bin 0) is returned.
 * This adress is ORed with the bin number to get the value of the according bin.
 * @param aGroup there is no range check! 
 */
- (unsigned int) histogramDataAdress:(int)aBin forChan:(int)aChan;
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0xC; //0xC is Histogrm:HDATA
    return ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12) | aBin;
}

/** This will read the histogram from the hardware and store all data in a buffer (data, firstBin, lastBin).
 * This is called at the end of a histogramming calibration run, when pressing the button
 * "Read Histogram Data". Or after a histogram page toggle (in continous run or at run stop)
 */
- (void) readHistogramDataForChan:(unsigned int)aPixel 
{
    unsigned int i,firstBin, lastBin, currVal, sum;
    //int group = [self histoChanToGroupMap:aPixel];
    firstBin = (unsigned int)[self readFirstBinForChan:aPixel];
    lastBin  = (unsigned int)[self readLastBinForChan:aPixel];
    DebugHistoTB(
				 int thepage = [self readCurrentHistogramPageNum];
				 NSLog(@"readHistogramDataForChan  %u ( page %i): has range %u ... %u \n",
					   aPixel, thepage, firstBin , lastBin); 
				 )
	
    unsigned int adress  = [self histogramDataAdress:0 forChan: aPixel];
    unsigned int *dataPtr=0; //place where to store the data
    //clear memory
    if(histogramData){//new version
        //int countHD=[histogramData count];  REMOVE THIS -tb-
        //NSLog(@"histogramData count is %i\n",countHD);
        //NSMutableData * md= (NSMutableData *)[histogramData objectAtIndex:aPixel];
        dataPtr=(unsigned int *)[[histogramData objectAtIndex:aPixel] bytes];
        for(i=0; i<1024; i++){
            dataPtr[i]= 0;
        }
    }
#if 0 //TODO: OBSOLETE - REMOVE IT -tb-
    if(histogramDataUI)//first version
        for(i=0; i<1024; i++){
            histogramDataUI[i]= 0;
        }
    if(histogramMutableData){//2nd/test version
		unsigned int * p =(unsigned int *)[histogramMutableData  mutableBytes];
		int j;
		for(j=0;j<1024;j++){ p[j]=0; }
    }
#endif
    sum = 0;
    
    DebugHistoTB(  NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];   )
	DebugHistoTB(  NSLogFont(aFont,@"-----------------------\n");          )
	
    //TODO: could read in one block from first bin to last bin
    for(i=firstBin; i<=lastBin; i++){
        currVal =  (unsigned int)[self read: adress | i];
        sum += currVal;
        DebugHistoTB(  if(currVal) NSLogFont(aFont,@"    bin %4u: %6u \n",i , currVal); 	 )
        //[[histogramData objectAtIndex:i] setIntValue:currVal];
        // obsolete - if(histogramDataUI) histogramDataUI[i]= currVal;
        if(dataPtr!=0) {
                dataPtr[i]= currVal;
        }
        // obsolete - if(histogramMutableData){ ((unsigned int*)[histogramMutableData mutableBytes])[i]=currVal;}
    }
    DebugHistoTB(  NSLogFont(aFont,@"sum (of page %i): %4u \n",thepage,sum); 	)
    
    // buffer all data for later readout and display
    histogramDataFirstBin[aPixel]=firstBin;
    histogramDataLastBin[aPixel]=lastBin;
    histogramDataSum[aPixel]=sum;
    
    //need to read out TRec BEFORE stopping/page toggle - otherwise it will be always 0 -tb-
    //histgramDataRecTimeSec[aPixel]=[self readTRecForChan:aPixel];
    //DebugHistoTB(  NSLogFont(aFont,@"TRec: %8u \n", histgramDataRecTimeSec[aPixel]); 	)
}

/** Reads the histogram data for a single bin  aBin from hardware.
 */
- (unsigned int) readHistogramDataOfPixel:(unsigned int)aPixel atBin:(unsigned int)aBin 
{
    unsigned int currVal;
    unsigned int adress  = [self histogramDataAdress:aBin forChan: aPixel];
    currVal =  (unsigned int)[self read: adress ];
    return currVal;
}

/** New for FPGA version 3.x (histogramming with paging)
 */
- (int)  readCurrentHistogramPageNum
{
    //NSLog(@" [self versionRegHWVersion] %i  \n",[self versionRegHWVersion] ); 
    if(([self versionRegHWVersion]< 0x3)) return -1;
    //if(![self histoFeatureIsAvailable]) return -1;
	//uint32_t controlStatusReg = [fireWireCard read: [self slot]<<24];		//which page?
	uint32_t controlStatusReg = [self read: [self slot]<<24];		//which page?
    //NSLog(@" Current Histogramming Page %i (0x%08x)\n",(controlStatusReg >> 31) & 0x1,controlStatusReg ); 
    // before 10.April 08 ... return (controlStatusReg >> 31) & 0x1;
    return (controlStatusReg >> 30) & 0x1;
}

/** New for FPGA version 3.x (histogramming with paging). 
 * Reads register, toggles stop bit, writes value back.
 */
- (void) clearCurrentHistogramPageForChan:(unsigned int)aChan
{
    DebugHistoTB( NSLog(@"Clearing Current Histogramming Page %i \n",[self readCurrentHistogramPageNum] ); )
    uint32_t histoTriggControlReg = [self readHistogramControlRegisterOfPixel: aChan];
    histoTriggControlReg |= 0x100; // Bit 8 is CLEAR bit
    [self writeHistogramControlRegisterOfPixel: aChan value: histoTriggControlReg];
}

- (BOOL) histogrammingIsActiveForChan:(unsigned int)aChan
{
    uint32_t histControlReg = [self readHistogramControlRegisterOfPixel:aChan];
    return histControlReg & 0x1;
}

/** Read out the current status and display it on Log Window.
 */
- (void) readCurrentStatusOfPixel:(unsigned int)aPixel  //TODO: rename to histogrammingIsRunning and return a BOOL? -tb- 2008-02-27
{
    NSLog(@"Current Status Of Histogramming Calibration Run: histoCalibrationIsRunning = %i \n",histoCalibrationIsRunning ); 
    // read  HistTriggControlReg
    uint32_t regVal = [self  readHistogramControlRegisterOfPixel:aPixel];
    NSLog(@"Current Status Of Pixel:%i HistTriggControlReg register is 0x%08x\n",aPixel, regVal ); 
    if(	regVal & 0x1 ) NSLog(@"  Hardware Histogramming is: RUNNING\n");
    else NSLog(@"  Hardware Histogramming is: STOPPED\n");
    if([self versionRegHWVersion]<3) NSLog(@"  E_Sample/BW is %u\n",(regVal & 0x3c) >> 2);
}

- (uint32_t) readHistogramControlRegisterOfPixel:(unsigned int)aPixel;
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x1; //0x1 is Histogrm:ControlReg
    int group = [self histoChanToGroupMap:aPixel];
    if(group==-1) return 0xffffffff;
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (group << 16) | (LAddr12 <<12);
	
    // read  HistTriggControlReg
    uint32_t regVal;
    regVal = [self read: adress];
    return regVal;
}

/** SLT needs this for a broadcast. TOD: could/should be a static function -tb-
 */
- (void) writeHistogramControlRegisterForSlot:(int)aSlot chan:(int)aChan value:(uint32_t)aValue
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x1; //0x1 is Histogrm:ControlReg
    unsigned int adress  = ( aSlot  << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12);
	
    // write  HistTriggControlReg
    [self write: adress value: aValue];
}

- (void) writeHistogramControlRegisterOfPixel:(unsigned int)aPixel value:(uint32_t)aValue;
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x1; //0x1 is Histogrm:ControlReg
    int group=[self histoChanToGroupMap:aPixel];
    if(group == -1){
        NSLog(@"writeHistogramControlRegisterOfPixel: BAD CHANNEL %i\n", aPixel);
        return  ;
    }
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (aPixel << 16) | (LAddr12 <<12);
	
    // write  HistTriggControlReg
    [self write: adress value: aValue];
}

/**
 *
 */
- (uint32_t) readHistogramSettingsRegisterOfPixel:(unsigned int)aPixel;
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x3; //0x1 is Histogrm:H_Param = HistoSettingsReg
    int group = [self histoChanToGroupMap:aPixel];
    if(group==-1) return 0xffffffff;
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (group << 16) | (LAddr12 <<12);
	
    // read  HistTriggControlReg
    uint32_t regVal;
    regVal = [self read: adress];
    return regVal;
}

/**
 *
 */
- (void) writeHistogramSettingsRegisterOfPixel:(unsigned int)aPixel value:(uint32_t)aValue;
{
    unsigned int func  = 0x6; // = b110
    unsigned int LAddr12 = 0x3; //0x1 is Histogrm:H_Param = HistoSettingsReg
    int group=[self histoChanToGroupMap:aPixel];
    if(group == -1){
        NSLog(@"writeHistogramSettingsRegisterOfPixel: BAD CHANNEL %i\n", aPixel);
        return  ;
    }
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (group << 16) | (LAddr12 <<12);
	
    // write  HistTriggControlReg
    [self write: adress value: aValue];
}

- (void) setHistoLastPageToggleSec:(int) sec usec:(int) usec
{
    histoLastPageToggleSec=sec;
    histoLastPageToggleUSec=usec;
}

- (void) setHistoStartWaitingForPageToggle:(BOOL) aValue
{    histoStartWaitingForPageToggle = aValue;    }


- (void) setHistoLastActivePage:(int) aValue
{  histoLastActivePage=aValue  ;}




// veto stuff
- (void) setVetoEnable:(int)aState
{
    unsigned int func  = 0x0; // = b000
    unsigned int LAddr0 = 0x1; //0x1 is ControlStatusReg2
    unsigned int Pixel = 0; // TODO: for testing: ignored
    //if(aPixel == 0) Pixel=0;
    //if(aPixel == 1) Pixel=1;
    //if(aPixel == 12) Pixel=2;
    //if(aPixel == 13) Pixel=3;
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr0);
    
    //unsigned int enableBit = 0x1 ;
    unsigned int regVal= 0x1 & aState;
    
    
    //NSLog(@"readLastBinForChan:%i Pbus register is %x\n",aPixel, ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)  ); 	
    NSLog(@"  setVetoEnable: address %8x, state %8x\n",adress,regVal  ); 	
	
	[self write:   adress value: regVal];
	
}

- (int) readVetoState
{
    unsigned int func  = 0x0; // = b000
    unsigned int LAddr0 = 0x1; //0x1 is ControlStatusReg2
    unsigned int Pixel = 0; // TODO: for testing: ignored
    //if(aPixel == 0) Pixel=0;
    //if(aPixel == 1) Pixel=1;
    //if(aPixel == 12) Pixel=2;
    //if(aPixel == 13) Pixel=3;
    unsigned int adress  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr0);
    
    //unsigned int enableBit = 0x1 ;
    //unsigned int regVal= 0x1 & aState;
    int regVal ;
    
    
    //NSLog(@"readLastBinForChan:%i Pbus register is %x\n",aPixel, ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12)  ); 	
	
	regVal = (int)[self read:   adress ];
    NSLog(@"  vetoState: adress %8x, state %8x\n",adress,regVal  ); 	
    return regVal;
	
}

- (void) readVetoDataFrom:(int)fromIndex to:(int)toIndex
{
    static int max = 511; // 1024?
    if(fromIndex <0)    fromIndex =0;
    if(fromIndex >max)  fromIndex =max;
    if(toIndex <0)      toIndex   =0;
    if(toIndex >max)    toIndex   =max;
    if(fromIndex>toIndex) toIndex=fromIndex;
    unsigned int func  = 0x5; // = b101 = TriggerData
    unsigned int baseadress  = ([self slot] << 24) | (func << 21);
    unsigned int adress;
    
    uint32_t word00, word01, word10;
    int i;
    for(i=fromIndex; i<=toIndex; i++){
        adress = baseadress | (i << 2);
        word00 = [self read:   adress ];
        word01 = [self read:   adress | 1];
        word10 = [self read:   adress | 2];
        NSLog(@"    adresses: %10x, %10x, %10x\n", adress , adress |1, adress|2);
        NSLog(@"    values  : %10x, %10x, %10x\n", word00 , word01, word10);
        NSLog(@"  eventID %8i, channelmap %8x, sec:sub %8i:%8i\n",word00 & 0x3ff,word00 >>10,word10,word01  ); 	
		
    }
}


//Low-level Register Access -tb-
-(int) readWriteRegisterChan {    return readWriteRegisterChan;    }

-(void) setReadWriteRegisterChan:(int)aChan
{
    readWriteRegisterChan= aChan;   
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelReadWriteRegisterChanChanged object:self];
	
}

-(NSString *) readWriteRegisterName
{return readWriteRegisterName;}

-(void) setReadWriteRegisterName:(NSString *)aName
{
    [readWriteRegisterName release];
    readWriteRegisterName = [[NSString alloc] initWithString: aName];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelReadWriteRegisterNameChanged object:self];
}

/** Returns the adress of the FLT register with name aName. If the name is unknown, 0xffffffff
 * is returned.
 */
- (uint32_t) registerAdressWithName:(NSString *)aName  forChan:(int)aChan
{
    unsigned int func  = 0x0; // = b110
    unsigned int LAddr0 = 0x0; //0x5 is T_Rec
    unsigned int LAddr12 = 0x0; //0x5 is T_Rec
    BOOL b=FALSE;
    
    //the known names:
    if([aName isEqualToString:@"ControlStatus"]){  func = 0x0; LAddr0 = 0x0;  LAddr12 = 0x0; b=TRUE; }
    if([aName isEqualToString:@"Threshold"])    {  func = 0x3 /*b011*/; LAddr0 = 0x0;  LAddr12 = 0x0; b=TRUE; }
    if([aName isEqualToString:@"Gain"])         {  func = 0x4 /*b100*/; LAddr0 = 0x1;  LAddr12 = 0x0; b=TRUE; }
    if([aName isEqualToString:@"Energy"])       {  func = 0x6 /*b110*/; LAddr0 = 0x0;  LAddr12 = 0x0; b=TRUE; }
    if([aName isEqualToString:@"TriggControl"]) {  func = 0x2 /*b010*/; LAddr0 = 0x0;  LAddr12 = 0x0; b=TRUE; }
    if([aName isEqualToString:@"PostTriggTime"]){  func = 0x2 /*b010*/; LAddr0 = 0x1;  LAddr12 = 0x0; b=TRUE; }
    if([aName isEqualToString:@"HistControl"])  {  func = 0x6 /*b110*/; LAddr0 = 0x0;  LAddr12 = 0x1; b=TRUE; }
    if([aName isEqualToString:@"HistEMin"])     {  func = 0x6 /*b110*/; LAddr0 = 0x0;  LAddr12 = 0x2; b=TRUE; }
    if([aName isEqualToString:@"HistParam"])    {  func = 0x6 /*b110*/; LAddr0 = 0x0;  LAddr12 = 0x3; b=TRUE; }
    if([aName isEqualToString:@"HistTRun"])     {  func = 0x6 /*b110*/; LAddr0 = 0x0;  LAddr12 = 0x4; b=TRUE; }
    if([aName isEqualToString:@"HistData0"])    {  func = 0x6 /*b110*/; LAddr0 = 0x0;  LAddr12 = 0xc; b=TRUE; }
    //TODO: there are much more registers ... -tb-
    //...
    
    uint32_t adress =   0xffffffff;
    if(b) adress =   ([self slot] << 24) | (func << 21) | (aChan << 16) | (LAddr12 <<12) | (LAddr0);
    // debug output -tb- NSLog(@"registerAdressWithName: adress is 0x%x\n", adress); 	
	return adress;
	
}

/** Returns the register content of the FLT register with name aName and channel aChan. If the name is unknown, the ControlStatus
 * is returned (as default).
 */
- (uint32_t) readRegisterWithName:(NSString *)aName  forChan:(int)aChan
{
    uint32_t adress =  [self registerAdressWithName:aName forChan: aChan];
    uint32_t val =  [self read: adress];
	return val;
	
}

/** Writes aValue to the  FLT register given by name aName and channel aChan. 
 * Returns the register adress (for contol purposes;
 * if the name was not found, this will result in the return value of 0xffffffff).
 */
- (uint32_t) writeRegisterWithName:(NSString *)aName  forChan:(int)aChan value:(uint32_t) aValue
{
    uint32_t adress =  [self registerAdressWithName:aName forChan: aChan];
    //NSLog(@"Write %l (0x%0lx) to Register %@: (adress %i)\n",aValue,aName,adress);
    if(adress != 0xffffffff) [self write: adress value: aValue];
	return adress;
}



#pragma mark ¥¥¥Archival
/** Define here what to read from the .Orca file. These are e.g. state of check boxes, content of text fields (gains,
 * thresholds,...), internal state values (daqRunMode, ...),  etc. 
 *
 * This is called at creation time of this object (rather than -(void) #init).
 */ //-tb-
- (id)initWithCoder:(NSCoder*)decoder
{
    //NSLog(@"Katrin FLT Card (%i) initWithCoder <---- decoder %p\n",[self slot], decoder);
    
#ifdef __ORCA_DEVELOPMENT__CONFIGURATION__
    {//in init: and initWithCoder:
        static bool firstTimeCalled=TRUE;
        if(firstTimeCalled){
            firstTimeCalled=FALSE;
            NSLog(@"ORKatrinFLTModel: WARNING: You are using a development version of Orca!\n");
            NSLog(@"    Debug code may slow down the measurement loop.\n");
            NSLog(@"    (In XCode, we recommend to switch the Active Build Configuration to 'Deployment Configuration' and recompile Orca.)\n" );
        }
    }
#endif
	
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setCheckWaveFormEnabled:[decoder decodeBoolForKey:@"ORKatrinFLTModelCheckWaveFormEnabled"]];
    [self setCheckEnergyEnabled:  [decoder decodeBoolForKey:@"ORKatrinFLTModelCheckEnergyEnabled"]];
    [self setTestPatternCount:	[decoder decodeIntForKey:@"ORKatrinFLTModelTestPatternCount"]];
    [self setTMode:				[decoder decodeIntegerForKey:@"ORKatrinFLTModelTMode"]];
    [self setPage:				[decoder decodeIntForKey:@"ORKatrinFLTModelPage"]];
    [self setIterations:		[decoder decodeIntForKey:@"ORKatrinFLTModelIterations"]];
    [self setEndChan:			[decoder decodeIntForKey:@"ORKatrinFLTModelEndChan"]];
    [self setStartChan:			[decoder decodeIntForKey:@"ORKatrinFLTModelStartChan"]];
    [self setBroadcastTime:		[decoder decodeBoolForKey:@"ORKatrinFLTModelBroadcastTime"]];
    [self setHitRateLength:		[decoder decodeIntegerForKey:@"ORKatrinFLTModelHitRateLength"]];
    [self setShapingTimes:		[decoder decodeObjectForKey:@"ORKatrinFLTModelShapingTimes"]];
    [self setTriggersEnabled:	[decoder decodeObjectForKey:@"ORKatrinFLTModelTriggersEnabled"]];
    [self setTestPatterns:		[decoder decodeObjectForKey:@"testPatterns"]];
    [self setGains:				[decoder decodeObjectForKey:@"gains"]];
    [self setThresholds:		[decoder decodeObjectForKey:@"thresholds"]];
    [self setFltRunMode:		[decoder decodeIntForKey:@"mode"]];   // -tb- 2008-02-16  TODO: maybe fltRunMode is better?
    [self setDaqRunMode:		[decoder decodeIntForKey:@"daqRunMode"]];// -tb- 2008-01-31   was daqMode
    if(![decoder containsValueForKey:@"daqRunMode"]){// this is for backward compatibility for old files
        [self setDaqRunMode:fltRunMode];
    }
    [self setHitRatesEnabled:	[decoder decodeObjectForKey:@"hitRatesEnabled"]];
    [self setTotalRate:			[decoder decodeObjectForKey:@"totalRate"]];
	[self setTestEnabledArray:	[decoder decodeObjectForKey:@"testsEnabledArray"]];
	[self setTestStatusArray:	[decoder decodeObjectForKey:@"testsStatusArray"]];
    [self setReadoutPages:		[decoder decodeIntegerForKey:@"ORKatrinFLTModelReadoutPages"]];	// ak, 2.7.07
    [self setPostTriggerTime:	[decoder decodeIntForKey:@"postTriggerTime"]];// -tb- 2008-03-11
    if(![decoder containsValueForKey:@"postTriggerTime"]){// this is for backward compatibility for old files
        [self setPostTriggerTime:511];
    }
    //hardware histogram stuff -tb- 2008-02-08
    versionRegister = 0x00200000; // emulate "almost version 3"
    [self setHistoBinWidth:		[decoder decodeIntForKey:@"ORKatrinFLTModelHistoBinWidth"]];
    [self setHistoMinEnergy:		[decoder decodeIntForKey:@"ORKatrinFLTModelHistoMinEnergy"]];
    //[self setHistoMaxEnergy:		[decoder decodeIntegerForKey:@"ORKatrinFLTModelHistoMaxEnergy"]]; // for now: unused -tb- 2008-03-06
    //[self setHistoFirstBin:		[decoder decodeIntegerForKey:@"ORKatrinFLTModelHistoFirstBin"]];
    //[self setHistoLastBin:		[decoder decodeIntegerForKey:@"ORKatrinFLTModelHistoLastBin"]];
    [self setHistoRunTime:		[decoder decodeIntForKey:@"ORKatrinFLTModelHistoRunTime"]];
    [self setHistoCalibrationChan:		[decoder decodeIntForKey:@"ORKatrinFLTModelHistoCalibrationChan"]];
    //[self setHistoRecordingTime:		[decoder decodeIntegerForKey:@"ORKatrinFLTModelHistoRecordingTime"]];
    //NSLog(@"Decoding ORKatrinFLTModelHistoBinWidth is %i\n",[decoder decodeIntegerForKey:@"ORKatrinFLTModelHistoBinWidth"]);
    [self setReadWriteRegisterChan:	[decoder decodeIntForKey:@"ORKatrinFLTModelReadWriteRegisterChan"]];// -tb-
    if(![decoder containsValueForKey:@"ORKatrinFLTModelReadWriteRegisterChan"]){// for backward compatibility 
        [self setReadWriteRegisterChan:0];
    }
    if(![decoder containsValueForKey:@"ORKatrinFLTModelReadWriteRegisterName"]){// for backward compatibility 
        [self setReadWriteRegisterName:@"ControlStatus"];
    }else{
        [self setReadWriteRegisterName:	[decoder decodeObjectForKey:@"ORKatrinFLTModelReadWriteRegisterName"]];// -tb- 
    }
    [self setShowHitratesDuringHistoCalibration:		[decoder decodeIntegerForKey:@"ORKatrinFLTModelShowHitratesDuringHistoCalibration"]];
    [self setHistoClearAtStart:		    [decoder decodeIntegerForKey:@"ORKatrinFLTModelHistoClearAtStart"]];
    [self setHistoClearAfterReadout:	[decoder decodeIntegerForKey:@"ORKatrinFLTModelHistoClearAfterReadout"]];
    [self setHistoStopIfNotCleared:		[decoder decodeIntegerForKey:@"ORKatrinFLTModelHistoStopIfNotCleared"]];
    [self setHistoSelfCalibrationPercent:[decoder decodeIntForKey:@"ORKatrinFLTModelHistoSelfCalibrationPercent"]];
    
	
	// TODO: Get reference to Slt model
	//sltmodel = [decoder decodeObjectForKey:@"ORKatrinFLTModel"]; //NO! when you need an slt reference do:
	//sltmodel = [[self crate] adapter];
	
	//make sure these objects exist and are populated with nil objects.
	int i;
	if(!shapingTimes){
		[self setShapingTimes: [NSMutableArray array]];
		for(i=0;i<4;i++)[shapingTimes addObject:[NSNumber numberWithInt:0]];
	}
	
	if(!triggersEnabled){
		[self setTriggersEnabled: [NSMutableArray array]];
		for(i=0;i<kNumFLTChannels;i++) [triggersEnabled addObject:[NSNumber numberWithBool:YES]];
	}
	
	if(!hitRatesEnabled){
		[self setHitRatesEnabled: [NSMutableArray array]];
		for(i=0;i<kNumFLTChannels;i++) [hitRatesEnabled addObject:[NSNumber numberWithBool:YES]];
	}
	
	if(!thresholds){
		[self setThresholds: [NSMutableArray array]];
		for(i=0;i<kNumFLTChannels;i++) [thresholds addObject:[NSNumber numberWithInt:50]];
	}
	
	if(!gains){
		[self setGains: [NSMutableArray array]];
		for(i=0;i<kNumFLTChannels;i++) [gains addObject:[NSNumber numberWithInt:100]];
	}
	
	if(!testStatusArray){
		[self setTestStatusArray: [NSMutableArray array]];
		for(i=0;i<kNumKatrinFLTTests;i++) [testStatusArray addObject:@"--"];
	}
	
	if(!testPatterns){
		[self setTestPatterns: [NSMutableArray array]];
		for(i=0;i<24;i++) [testPatterns addObject:[NSNumber numberWithInt:0]];
	}
	
	if(!testEnabledArray){
		[self setTestEnabledArray: [NSMutableArray array]];
		for(i=0;i<kNumKatrinFLTTests;i++) [testEnabledArray addObject:[NSNumber numberWithBool:YES]];
	}
    
    //startup values -tb- 2008-02-11
    [self setHistoFirstBin:	511];
    [self setHistoLastBin:	0];
    [self setHistoRecordingTime:0];
    
    // test
    //histogram data: the crate returns 32-bit values = int or int32_t -tb-
	if(!histogramData){
        // use a NSMutableArray with NSMutableData / NSData
		//[self setThresholds: [NSMutableArray array]];
        //histogramData = [NSMutableArray arrayWithCapacity:kNumFLTChannels];//one array per channel
        histogramData = [[NSMutableArray allocWithZone:nil] initWithCapacity:kNumFLTChannels];//one array per channel
        // NSLog(@"Histogramm data alloc sizeof(short): %i sizeof(int): %i  (uint32_t): %i  (int32_t): %i (longlong): %i\n",
        //  sizeof(short),sizeof(int),sizeof(uint32_t) ,sizeof( int32_t),sizeof( int64_t) );
		
		for(i=0;i<kNumFLTChannels;i++){
            //TODO : could omit the unavailable channels ... -tb-
            //[histogramData addObject:[NSMutableData dataWithLength:1024]]; <- this did not work -tb-
            //NSMutableData *md = [NSMutableData dataWithLength:1024*sizeof(unsigned int)]; <- this too
            NSMutableData *md =[NSMutableData dataWithLength:1024*sizeof(unsigned int)]; //MAH 09/02/09 fixed memory leak
            // -> sizeof int32_t and unsigned int is the same (4), here I rely on it! would be more elegant to use int32_t
            // -> as longs are used to ship data to the Orca data stream -tb-
            //[md retain];  ... insertObject should do this -tb-
            //id md = [NSMutableData dataWithLength:1024*sizeof(unsigned int)];
            [histogramData insertObject:md atIndex:i];
            //TODO: makes problems ... -tb- [md release]; // let the array 'histogramData' do the final release (histogramData is released in dealloc) -tb-
        }
	}
    
	//------------------------------------------------------------------------------------------
	//Till -- a better solution here is to save the current feature set, then probe for the feature set 
	//only if the firewire service toggles or if the user pushes the version button. 
	[self setStdFeatureIsAvailable:   [decoder decodeBoolForKey:@"stdFeatureIsAvailable"]];
	[self setVetoFeatureIsAvailable:  [decoder decodeBoolForKey:@"vetoFeatureIsAvailable"]];
	[self setHistoFeatureIsAvailable: [decoder decodeBoolForKey:@"histoFeatureIsAvailable"]];
	[self setFilterGapFeatureIsAvailable: [decoder decodeBoolForKey:@"filterGapFeatureIsAvailable"]];
	[self setVersionRegister:		  [decoder decodeIntForKey:@"versionRegister"]];
    
    [self setFilterGap: [decoder decodeIntForKey:@"filterGapSetting"]];
	
	/*
	 //version control - at this time firewire is (sometimes) not available -tb- 2008-03-13
	 @try {
	 //NSLog(@"--- initWithCoder::Read from register initVersionRevision---\n");
	 [self initVersionRevision];
	 }
	 @catch(NSException* localException) {
	 versionRegisterIsUptodate=FALSE;
	 {  //set default
	 [self setStdFeatureIsAvailable:   YES];
	 [self setVetoFeatureIsAvailable:  YES];
	 [self setHistoFeatureIsAvailable: YES];
	 }
	 NSLog(@"initWithCoder::Read from register initVersionRevision FAILED\n");
	 }
	 */	
	//------------------------------------------------------------------------------------------
	
    [[self undoManager] enableUndoRegistration];
	
    [self registerNotificationObservers];
	
    return self;
}

/** Define here what to write to the .Orca file.
 */ //-tb-
- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
    [encoder encodeBool:checkWaveFormEnabled forKey:@"ORKatrinFLTModelCheckWaveFormEnabled"];
    [encoder encodeBool:checkEnergyEnabled   forKey:@"ORKatrinFLTModelCheckEnergyEnabled"];
    [encoder encodeInteger:testPatternCount     forKey:@"ORKatrinFLTModelTestPatternCount"];
    [encoder encodeInteger:tMode				forKey:@"ORKatrinFLTModelTMode"];
    [encoder encodeInteger:page					forKey:@"ORKatrinFLTModelPage"];
    [encoder encodeInteger:iterations			forKey:@"ORKatrinFLTModelIterations"];
    [encoder encodeInteger:endChan				forKey:@"ORKatrinFLTModelEndChan"];
    [encoder encodeInteger:startChan			forKey:@"ORKatrinFLTModelStartChan"];
    [encoder encodeBool:broadcastTime		forKey:@"ORKatrinFLTModelBroadcastTime"];
    [encoder encodeInteger:hitRateLength		forKey:@"ORKatrinFLTModelHitRateLength"];
    [encoder encodeObject:shapingTimes		forKey:@"ORKatrinFLTModelShapingTimes"];
    [encoder encodeObject:triggersEnabled	forKey:@"ORKatrinFLTModelTriggersEnabled"];
    [encoder encodeObject:testPatterns		forKey:@"testPatterns"];
    [encoder encodeObject:gains				forKey:@"gains"];
    [encoder encodeObject:thresholds		forKey:@"thresholds"];
    [encoder encodeObject:hitRatesEnabled	forKey:@"hitRatesEnabled"];
    [encoder encodeInteger:daqRunMode			forKey:@"daqRunMode"];// -tb- 2008-01-31
    [encoder encodeInteger:fltRunMode			forKey:@"mode"];//TODO: remove this ? -tb-
    [encoder encodeObject:totalRate			forKey:@"totalRate"];
    [encoder encodeObject:testEnabledArray	forKey:@"testEnabledArray"];
    [encoder encodeObject:testStatusArray	forKey:@"testStatusArray"];
    [encoder encodeInteger:readoutPages  		forKey:@"ORKatrinFLTModelReadoutPages"];	
    [encoder encodeInteger:postTriggerTime 		forKey:@"postTriggerTime"];	
    //hardware histogram stuff -tb- 2008-02-08
    [encoder encodeInteger:histoBinWidth  		forKey:@"ORKatrinFLTModelHistoBinWidth"];	
    [encoder encodeInteger:histoMinEnergy  		forKey:@"ORKatrinFLTModelHistoMinEnergy"];	
    //[encoder encodeInteger:histoMaxEnergy  		forKey:@"ORKatrinFLTModelHistoMaxEnergy"];	for now: unused -tb- 2008-03-06
    //[encoder encodeInteger:histoFirstBin  		forKey:@"ORKatrinFLTModelHistoFirstBin"];	
    //[encoder encodeInteger:histoLastBin  		forKey:@"ORKatrinFLTModelHistoLastBin"];	
    [encoder encodeInteger:histoRunTime  		forKey:@"ORKatrinFLTModelHistoRunTime"];	
    //[encoder encodeInteger:histoRecordingTime   forKey:@"ORKatrinFLTModelHistoRecordingTime"];	
    [encoder encodeInteger:histoCalibrationChan  forKey:@"ORKatrinFLTModelHistoCalibrationChan"];	
    [encoder encodeInteger:readWriteRegisterChan    forKey:@"ORKatrinFLTModelReadWriteRegisterChan"];	
    [encoder encodeObject:readWriteRegisterName forKey:@"ORKatrinFLTModelReadWriteRegisterName"];	
    [encoder encodeInteger:showHitratesDuringHistoCalibration     forKey:@"ORKatrinFLTModelShowHitratesDuringHistoCalibration"];	
    [encoder encodeInteger:histoClearAtStart           forKey:@"ORKatrinFLTModelHistoClearAtStart"];	
    [encoder encodeInteger:histoClearAfterReadout      forKey:@"ORKatrinFLTModelHistoClearAfterReadout"];	
    [encoder encodeInteger:histoStopIfNotCleared       forKey:@"ORKatrinFLTModelHistoStopIfNotCleared"];	
    [encoder encodeInteger:histoSelfCalibrationPercent forKey:@"ORKatrinFLTModelHistoSelfCalibrationPercent"];	
	
    [encoder encodeBool:stdFeatureIsAvailable  forKey:@"stdFeatureIsAvailable"];	
    [encoder encodeBool:vetoFeatureIsAvailable forKey:@"vetoFeatureIsAvailable"];	
    [encoder encodeBool:histoFeatureIsAvailable forKey:@"histoFeatureIsAvailable"];	
    [encoder encodeBool:filterGapFeatureIsAvailable forKey:@"filterGapFeatureIsAvailable"];	
    [encoder encodeInt:(int)versionRegister forKey:@"versionRegister"];
	
    [encoder encodeInt:filterGap forKey:@"filterGapSetting"];	
	
}



/** Define here all types of data records. Define the decoder selector with \@"decoder".
 * The "dataID" is assigned by the assigner, see setDataIds or - (void) setDataIds:(id)assigner.
 * The decoders are defined in \file ORKatrinFLTDecoder.m
 *  
 * This will go to the XML header of the data file.
 */ //-tb- 2008-02-6
- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORKatrinFLTDecoderForEnergy",      @"decoder",
								 [NSNumber numberWithLong:dataId],   @"dataId",
								 [NSNumber numberWithBool:YES],      @"variable",
								 [NSNumber numberWithLong:-1],		@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"KatrinFLT"];//TODO: rename to KatrinFLTEnergy? -tb-
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORKatrinFLTDecoderForWaveForm",		@"decoder",
				   [NSNumber numberWithLong:waveFormId],   @"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    //debug output NSLog(@"waveFormID (KatrinFLTWaveForm) is %i\n",waveFormId); //TODO: remove it -tb-
    [dataDictionary setObject:aDictionary forKey:@"KatrinFLTWaveForm"];
	
    // -tb- 2008-02-01
    //daqRunMode = TODO: fill in the mode -tb-
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORKatrinFLTDecoderForHitRate",  		@"decoder",  //in ORKatrinFLTDecoder.h/.m
				   [NSNumber numberWithLong:hitRateId],    @"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"KatrinFLTHitRate"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORKatrinFLTDecoderForThresholdScan",  @"decoder",  //renamed from ORKatrinFLTDecoderForHitRate-tb-
				   [NSNumber numberWithLong:thresholdScanId],    @"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"KatrinFLTThresholdScan"];
    
    // for the hardware histogram
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORKatrinFLTDecoderForHistogram",  	@"decoder",
				   [NSNumber numberWithLong:histogramId],  @"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"KatrinFLTHistogram"];
    
    // for the veto data
#if 0
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORKatrinFLTDecoderForVeto",  		    @"decoder",  //TODO:  will be needed for VETO  -tb-
				   [NSNumber numberWithLong:vetoId],       @"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"KatrinFLTVeto"];
#endif
    
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   [NSNumber numberWithLong:dataId],				@"dataId",
				   [NSNumber numberWithLong:kNumFLTChannels],		@"maxChannels",
				   nil];
	
	[anEventDictionary setObject:aDictionary forKey:@"KatrinFLT"];
}

/** This will go to the XML header of the data file.
 */ //-tb- 2008-02-6
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:thresholds			forKey:@"thresholds"];
    [objDictionary setObject:gains				forKey:@"gains"];
    [objDictionary setObject:hitRatesEnabled	forKey:@"hitRatesEnabled"];
    [objDictionary setObject:triggersEnabled	forKey:@"triggersEnabled"];
    [objDictionary setObject:shapingTimes		forKey:@"shapingTimes"];
    [objDictionary setObject:[NSNumber numberWithInt:daqRunMode]    		forKey:@"daqRunMode"];
	//TODO: maybe a string is better?(!) or both? -tb- 2008-02-27
    [objDictionary setObject:[NSNumber numberWithInt: filterGap]    		forKey:@"filterGapSetting"];
    
    
	return objDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
#ifdef __ORCA_DEVELOPMENT__CONFIGURATION__
    //NSLog(@"---- ORKatrinFLTModel::runTaskStarted (%i)----\n", [self slot]);
#endif
	
	firstTime = YES;
    nLoops = 0; // Counter for the readout loops
    nEvents = 0;
	
	
    [self clearExceptionCount];
	
	//check that we can actually run
    if(![[[self crate] adapter] serviceIsAlive]){
		[NSException raise:@"No FireWire Service" format:@"Check Crate Power and FireWire Cable."];
        //return;  //TODO: ??? -tb-
    }
	
    // Don't start run, if histogramming test is active
    // TODO: SLT resets the hardware in ["SLT runIsAboutToStart ..."], so if we come here, histogramming already has been terminated by SLT -tb-
    // TODO: how should we handle this? -tb-
    // TODO: answer (2008-07-16): move this check to SLT! -tb-
    if ([self histoCalibrationIsRunning]) {
		[NSException raise:@"Histogramming calibration is running" format:@"Stop calibration run and select proper histogramming parameters"]; 
        return; 
    }
	
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORKatrinFLTModel"];    
    //----------------------------------------------------------------------------------------	
	
	//check which mode to use
	BOOL ratesEnabled = NO;
	int i;
	for(i=0;i<kNumFLTChannels;i++){
		if([self hitRateEnabled:i]){
			ratesEnabled = YES;
			break;
		}
	}
	
    //TODO: runTaskStarted:
    /** @todo  following code commented out since last update (r694) - needs to be checked -tb- 
	 * @code
	 * if([[userInfo objectForKey:@"doinit"]intValue]){
	 *	[self initBoard];					
	 *  }
	 * @endcode
	 */
    //TODO: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    //if([[userInfo objectForKey:@"doinit"]intValue]){
	//	[self initBoard];					
	//}
	
	if(fltRunMode == kKatrinFlt_Debug_Mode)	[self restartRun]; //reset the trigger //TODO: we probably should check the daqRunMode instead of the fltMode -tb- 2008-02-29
	else                                    [self reset];      //reset the r/w pointer
	
    //see 5 lines above: initBoard calles loadTime, writeMode:fltRunMode, loadThresholdsAndGains, writeHitRateMask ... -tb-
    //is this necessary before calling restartRun or reset ? why writeTriggerControl is missing in initBoard? ... -tb-
    if([[userInfo objectForKey:@"doinit"]intValue]){ // this produced a delay of 1 sec per FLT, so only for cold start necessary ... -tb- 2009-03
	    [self loadTime];					//set the time on the flts to mac time (if doinit==1 [SLT initBoard] was called, reloading time is necessary ... -tb-)
	}
	[self writeMode:fltRunMode];
	[self writeHitRateMask];			//set the hit rate masks
	[self writeTriggerControl];			//set trigger mask
	[self loadThresholdsAndGains];
    
    //TODO: WORKAROUND: -tb-
    if([self versionRegHWVersionHex] >= 0x30)
        [self writePostTriggerTime:postTriggerTime];
	[self writeTriggerControl]; //TODO: I set it here again - could be corrupted by writing the postTrigger
	//TODO: Denis should fix this -tb-
    /*!@todo TODO: at Run Start the postTriggTime gets resetted somewhere to the default, should be checked somewhen -tb-
     * <br>... could be software (SLT?) or hardware; Denis already tried to find it in hardware, I tried to find it in software ...
     * <br> ... quite sure that it is in SLT ... -tb-2008-03-14
     *
     * (Could be fixed by removing init after runIsAboutToStart
     */
    //debug output -tb- NSLog(@"1\n");[self readPostTriggerTime];//TODO: debugging - remove it -tb-
	
    //the filter gap setting will be written to FLT by [self writeTriggerControl], test it ... -tb-
#ifdef __ORCA_DEVELOPMENT__CONFIGURATION__
    // set the filter gap
    if(filterGapFeatureIsAvailable){
        [self readFilterGap];
    }
#endif
	
    
	if(ratesEnabled){
		[self performSelector:@selector(readHitRates) 
				   withObject:nil 
				   afterDelay:[self hitRateLength]];		//start reading out the rates
	}
	
	//cache some addresses for speed in the dataTaking loop.
	uint32_t theSlotPart = [self slot]<<24;
	statusAddress			  = theSlotPart;
	triggerMemAddress		  = theSlotPart | (kFLTTriggerDataCode << kKatrinFlt_AddressSpace); 
	memoryAddress			  = theSlotPart | (kFLTAdcDataCode << kKatrinFlt_AddressSpace); 
	fireWireCard			  = [[self crate] adapter];
	locationWord			  = (uint32_t)((([self crateNumber]&0x0f)<<21) | ([self stationNumber]& 0x0000001f)<<16);
  	usingPBusSimulation		  = [fireWireCard pBusSim];
	
    // Class member to store the last handled page, ak 15.6.07
	nextEventPage = 0; // Start with page 0
	lastEventId = 8888; // Unknown
	
	generateTrigger = 0;
	nMissingEvents = 0;
	nSkippedEvents = 0;
	overflowDetected = false;
	overflowDetectedCounter = 0;
	nBuffer = 0;
	
	// Information for measurement mode
    lastSec = 0; 
	activeChMap = 0;
	for (i=0;i<22;i++){
		if([self hitRateEnabled:i] && [self triggerEnabled:i]) 
			activeChMap = activeChMap | (0x1 << i);
		
		// Set initial thresholds
		actualThreshold[i] = [self threshold:i]; 
		savedThreshold[i]  = [self threshold:i]; 
		lastThreshold[i]   = [self threshold:i]; 
		stepThreshold[i]   = 2;
		
		maxHitrate[i]  = 0;
		lastHitrate[i] = 0;
		nNoChanges[i]  = 0;
	}
	
	if(fltRunMode == kKatrinFlt_Measure_Mode){	
		// TODO: Set hitrate length always to one
	}
	
    if(usingPBusSimulation){
		activeChMap = 0x25; // Three testing channels
	} 
	
 	//[self writeControlStatus:kKatrinFlt_Intack];
	
    // TODO: Check if reset counters are availabe
	//set to false for now so we can use ORCARoot MAH 7/20/07
	useResetTimestamp = true;
	//----------------
	
    @try {
		resetSec = [self read:([self slot] << 24) | (kFLTTimeCounterCode << kKatrinFlt_AddressSpace) | 0x01 ] ;		
	}
	@catch(NSException* localException) {
		useResetTimestamp = NO;
		NSLog(@"Warning: Old design - reset timestamps not available");
	}	
	
    //THE HARDWARE HISTOGRAMMING PART
    // write the options for hardware histogramming and activate histogramming -tb- 2008-03-05
    if(daqRunMode == kKatrinFlt_DaqHistogram_Mode){	
        //see startCalibrationHistogramOfChan ...
        //pbus simulation mode
        if(usingPBusSimulation){
            histoLastPageToggleSec=0;  // in simulation mode used for counting to TRun/RefreshTime
            [self setHistoCalibrationIsRunning:TRUE];
            [self setHistoRecordingTime:0];
            histoStartTimeSec = (int)[self readTime];
            [self setHistoCalibrationElapsedTime: 0];
            return;
        }
        //this is for new FPGA versions >= 3.x (between Nov 2007 and April 2008), first test versions -tb-
        if([self versionRegHWVersion]>=0x3){
#if 0  //MOVED TO SLT -tb-
            //stop histogramming (maybe histogramming is still running by some reason)
            if([self histogrammingIsActiveForChan:0]){// I test the first pixel (0), could test any -tb-
                NSLog(@"Histogramming is still running: cold restart!\n");
                [self writeStopHistogramForChan:31];
                //version <3.x ... [self writeHistogramControlRegisterOfPixel:aPixel value:([self readHistogramControlRegisterOfPixel:aPixel]&0xfffffffe)];
                usleep(1000000);
            }
#endif
            
            //BEGIN INIT (this should have be done before, but of some reasons trigger control is necessary here  -tb-)
            {
                //write configuration:
#if 0
                //set gains, thresholds, shaping
                [self loadThresholdsAndGains];
                //set to energy mode (fltRunMode = 1)
                //[self setFltRunMode: kKatrinFlt_Run_Mode]; //is set by daq mode -tb-
                [self writeMode: fltRunMode]; //TODO : == 1
                //SLT: release SW inhibit
                sltmodel = [[self crate] adapter];
                [sltmodel releaseSwInhibit];
#endif
                { // write trigger settings, give warning message -tb-
                    //enable trigger - see - (void) writeTriggerControl
					//>>>> TODO: check this -tb-
                    [self writeTriggerControl];
                }
            }
            //END   INIT  
            
#if 0  //MOVED TO SLT -tb-
            // write TRun, EMin, BinWidth
            histoStartWaitingForPageToggle = FALSE;
            //histogramming registers (now I use a broadcast)
            [self writeEMin:histoMinEnergy forChan: 31 /*aPixel*/];
            //[self writeEMax:histoMaxEnergy forChan:aPixel];
            [self writeTRun:histoRunTime forChan: 31 /*aPixel*/];
            //clear the pages: (clears the pages in a 2 second "pre run")
            //    moved to SLT ... -tb-
            //  write HistSettingsReg
            [self writeHistogramSettingsForChan:31 mode: histoStopIfNotCleared  binWidth: histoBinWidth ];
#endif
			
            //  start procedure: (needs carefull timing)
            struct timeval t;
            //wait after second strobe to give FPGA time to clear the histogram, so it has at least 1 sec until next page toggle
            //  (I also could read subseconds with readTimeSubSec and start immediatly if >0.1 sec before sec strobe)
            gettimeofday(&t,NULL);
            histoLastSecStrobeSec = (int)t.tv_sec;
            histoLastSecStrobeUSec = (int)t.tv_usec;
#if 0 //MOVED TO SLT -tb-
            int lastSecStrobe = [self readTime];
            DebugHistoTB(  NSLog(@"lastSecStrobe is %i\n",lastSecStrobe);  )
            int sec = lastSecStrobe;
            do{
                histoLastSecStrobeSec = t.tv_sec;  
                histoLastSecStrobeUSec = t.tv_usec;  
                sec = [self readTime];
                gettimeofday(&t,NULL);
            }while(sec==lastSecStrobe);
            DebugHistoTB(  NSLog(@"sec is %i \n",sec);  )
            
            //START HISTOGRAMMING:
            //starting - write HistControlReg
            //[self writeStartHistogramForChan:aPixel withClear: histoClearAtStart];
            // broadcast
            [self writeStartHistogramForChan:31 withClear: histoClearAtStart];
            //wait again until next sec strope - THEN histogramming will start
            gettimeofday(&t,NULL);
            histoLastSecStrobeSec = t.tv_sec;  
            histoLastSecStrobeUSec = t.tv_usec;  
            lastSecStrobe = [self readTime];// lastSecStrobe=sec;
            do{
                histoLastSecStrobeSec = t.tv_sec;  
                histoLastSecStrobeUSec = t.tv_usec;  
                sec = [self readTime];
                gettimeofday(&t,NULL);
            }while(sec==lastSecStrobe);
            DebugHistoTB(  NSLog(@"sec is %i\n",sec);  )
#endif
            
			//remember active page
			histoLastActivePage = [self readCurrentHistogramPageNum];//now in SLT -tb-???
			lastDiffTime = 0.0;
			//set vars
			[self setHistoCalibrationElapsedTime: 0.0];
			[self setHistoCalibrationIsRunning:TRUE];
			
			
#if 0  //MOVED TO SLT -tb-
			histoStartWaitingForPageToggle = FALSE;
			histoLastPageToggleSec = histoLastSecStrobeSec;   //used for timing of page toggle.
			histoLastPageToggleUSec= histoLastSecStrobeUSec;  //  ''
			histoPreToggleSec      = histoLastSecStrobeSec; 
			histoPreToggleUSec     = histoLastSecStrobeUSec; 
#endif
			
			//remember the start time (for display in GUI) TODO: work in progress -tb- 2008-02-18
			// there are (Auger) methods readTime and readTimeSubSec (from self), do they work for Katrin? -tb-
			//struct timeval t;//    struct timezone tz; is obsolete ... -tb-
			gettimeofday(&t,NULL);
			histoStartTimeSec = (int)t.tv_sec;
			histoStartTimeUSec = (int)t.tv_usec;
			lastDelayTime = 0;//I use this to call takeDataHistogramMode only every 0.1 sec (see takeDataHistogramMode) -tb-
			
			// start delayed timing ... stuff from checkCalibrationHistogram is in takeDataHistogramMode
			//[self performSelector:@selector(checkCalibrationHistogram) withObject:nil afterDelay:0.1 /*sec*/];
			//return;
			
			// send notification to GUI
			[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
			
			
#if 0
            //write configuration:
            //set gains, thresholds, shaping
            [self loadThresholdsAndGains];
            [self writeMode: fltRunMode]; //TODO: HANDLE EXCEPTION -TB-
            //SLT: release SW inhibit
            sltmodel = [[self crate] adapter];
            [sltmodel releaseSwInhibit];
            //enable trigger - see - (void) writeTriggerControl
            [self writeTriggerControl];
#endif
            
            
            
        }
        
        
        //BEGIN - this is obsolete but left for downward compatibility for older FPGA configurations -tb- 2008-04-06
        //this is for old versions < 3 (between Nov 2007 and April 2008), first test versions -tb-
        if([self versionRegHWVersion]<0x3){
            NSLog(@"  runTaskStarted: using old code!OBSOLETE!\n");
            //I keep the code for testing -tb-
            // write TRun, EMin, EMax, BinWidth
            //stop histogramming (maybe histogramming is still running from a previous run)
            [self writeStopHistogram];
            usleep(1000000);
            [self writeEMin:histoMinEnergy];
            //[self writeEMax:histoMaxEnergy];
            [self writeTRun:histoRunTime];
            //write HistControlReg to set bin width and to start histogramming
            //[self writeStartHistogram:histoBinWidth forChan:0];
            [self writeStartHistogram:histoBinWidth forChan:31];
            // send notification to GUI
            [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
        }
    }
    
}


//**************************************************************************************
// Function:	

// Description: Read data from a card
//****************************g**********************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{	
    @try {	
	   	
		if(!firstTime){
			if (generateTrigger > 0){
				/*			   
				 // Set inhibit before generating the trigger
				 // wait and release
				 // Test of inhibit feature for Monitor Detector, ak 16.7.07
				 addr =  (21 << 24) | (0x1 << 18) | 0x0f13;
				 [self write:addr value:0];
				 
				 usleep(100); // Inhibit for 100us ?!
				 addr =  (21 << 24) | (0x1 << 18) | 0x0f14;
				 [self write:addr value:0];
				 */			
				
				int i;
				uint32_t addr =  (21 << 24) | (0x1 << 18) | 0x0105; // Set pages free
				for (i=0;i<63;i++) [self write:addr value:i];
				
				addr =  (21 << 24) | (0x1 << 18) | 0x0f12; // Slt Generate Software Trigger
				[self write:addr value:0];
				
				generateTrigger = 0;
			}
			
			switch(daqRunMode){ //was fltMode  -tb- 2008-02-12
				case kKatrinFlt_DaqHitrate_Mode: // new -tb-
					[self takeDataHitrateMode: aDataPacket];
					break;
				case kKatrinFlt_DaqThresholdScan_Mode: // was kKatrinFlt_Measure_Mode -tb-
					[self takeDataMeasureMode: aDataPacket];
					break;
					
				case kKatrinFlt_DaqEnergy_Mode: // was kKatrinFlt_Run_Mode or kKatrinFlt_Debug_Mode
				case kKatrinFlt_DaqEnergyTrace_Mode:	
					[self takeDataRunOrDebugMode: aDataPacket]; 
					break;
				case kKatrinFlt_DaqHistogram_Mode:  //new mode 2008-02-26 -tb-
					[self takeDataHistogramMode: aDataPacket];
					break;
				case kKatrinFlt_DaqVeto_Mode:  //new mode 2008-02-26 -tb-
					[self takeDataVetoMode: aDataPacket];
					break;
			}
		}
		else {
			
			firstTime = NO;
			
			// Read first second counter
			// The first hitrate will be taken from the first completely measured interval
			lastSec = [self readTime] + 1;  
			
			
			// Start dead time counting	
			uint32_t addr =  (21 << 24) | (0x1 << 18) | 0x0f11; // ResetDeadTimeCounters
			[self write:addr value:0];			
			
			// Release inhibit when DAq has started!
			addr =  (21 << 24) | (0x1 << 18) | 0x0f14; // SwRelInhibit
			[self write:addr value:0];
		}
		
	}
	@catch(NSException* localException) {
		
        //TODO: CRASH: in case of exceptions and in trace mode we should stop the run (?) -tb- 2008-02-27
		NSLogError(@"",@"Katrin FLT Card Error",[NSString stringWithFormat:@"Card%d",(int)[self stationNumber]],@"Data Readout",nil);
		[self incExceptionCount];
		[localException raise];
		
	}
}



/** Called in Energy+Trace and in Energy mode (former/hardware names: Debug and Run mode).
 * For event based data taking
 */
- (void) takeDataRunOrDebugMode:(ORDataPacket*) aDataPacket
{
	nLoops++;
	
	uint32_t statusWord = [fireWireCard read:statusAddress];		//is there any data?
    //TODO: needs to check the FPGA version: this is valid ONLY for CFPGA version >= 0x06 or HW vers >= 0x30 -tb-
    dataAquisitionStopped      = ((statusWord >>31) & 0x1);
    dataAquisitionIsRestarting = ((statusWord >>29) & 0x1);
    
    // check the hardware: TODO: in pBusSimulation mode ??? --> Andreas -tb- 2008-03-12
    if(usingPBusSimulation){ //do nothing
    }else
		if([self versionRegHWVersion]>= 0x3){//dataAquisitionStopped flag available since v0x3 -tb-
			if((fltRunMode ==  kKatrinFlt_Debug_Mode) && (!dataAquisitionStopped)){
				//NSLog(@"Skipped readout, HW still busy (flag dataAquisitionStopped = %i) (status 0x%x)\n",dataAquisitionStopped,statusWord);
				//usleep(10000);//for debugging: to not overfill the log window -tb-
				return;	//post trigger readout is still busy
			}
		}
    //NSLog(@"takeDataRunOrDebugMode:READOUT (flag dataAquisitionStopped = %i) (status 0x%x)\n",dataAquisitionStopped,statusWord);
    
	
	// Determine the pages to be read
	// The eventlop (this class) stores the next page to be read in the
	// variable nextEventPage. The page number actually written is read from 
	// the status register.
	// ak 15.6.07
	uint32_t page0 = nextEventPage; // Next page to be read
	uint32_t page1 = (statusWord >> 11) & 0x1ff;	// Get write page pointer
	
	if(usingPBusSimulation){
		// In simulation mode generate a trigger from time to time...
		// ak 11.7.07
		page1 = nextEventPage;
		usleep(1);
		
		// Generate event every 2 sec
	    uint32_t sec = [self readTime];
	    if (sec > lastSec + 1) {
   		    lastSec = sec; // Store the  actual second counter		
			page1 = (nextEventPage + 1) % 512;
			//NSLog(@"Pages: %d %d (last %d, loops %d)\n", page0, page1, nextEventPage, nLoops);
			usleep(100); 
		}
	}    
	
	// Read the the trigger data of all events in one block. 
	// The energy value have to be read one by one. 
	// (Denis was not able to store all the data in the same place)
	// ak, 20.7.07
	uint32_t dataBuffer[2048];
	uint32_t *data;
	
    int nPagesHw = (512 + page1 - page0) %512; 
	int nPages = nPagesHw;			
	
    
	// Read the event data for a complete block of events
    //NSLog(@"dataAquisitionStopped = %i, dataAquisitionIsRestarting = %i\n",dataAquisitionStopped,dataAquisitionIsRestarting);usleep(1000);
	if (nPages > 0){
        
		// Calculate the mean buffer hardware buffer load
		nBuffer = 0.95 * nBuffer + 0.05 * ((512+page1-page0)%512);
		
		// Don't wrap around the end of the buffer
		if (page1 < page0) {
			page1 = 0; 
			nPages = (512 + page1 - page0) %512; // Recalculate
		}	
        
        // Maximal block size is 128 x 4 = 512 (by Firewire) ak 2008-08-01
        if (nPages > 128) {
			page1 = (512 + page1 - (nPages - 128)) %512;
			nPages = 128;
        }
        
        // check the nPages ... -tb-
        if(checkEnergyEnabled){
            if(nPages > 128) NSLog(@"ERROR: takeDataRunOrDebugMode:nPages exceeds maximum firewire block size!\n");
        }
        
		
		uint32_t pageAddress = triggerMemAddress + (page0<<2);				
		data = dataBuffer;
        [fireWireCard read:pageAddress data:data size:nPages*4*sizeof(int32_t)];
		
	    // Determine the readout address for all ADC traces
		// The first trigger stops the recording of the ADC traces
		// 		
		// Calculate start bin
		// Note: The Flt uses a fixed post trigger time of 512 bin
		//       This time is different from the central nextpage delay used by the Slt
		//       ak, 29.2.08
        //       the post trigger time is now a free parameter -tb- 2008-06-xx
		uint32_t firstEventSubSec = data[1];
		//int startBin = firstEventSubSec - (512 + (readoutPages-1) * 1024);
		uint32_t startBin = firstEventSubSec - (readoutPages  * 1024) + postTriggerTime;// -tb- 2008-03-10
        startBin = 0x10000 + startBin;
		
		
		if( (fltRunMode == kKatrinFlt_Debug_Mode) && checkWaveFormEnabled){
			if (nPages > 1) 
				NSLog(@"nEvents=%8d (%12d,%8d) nPages=%3d\n", nEvents+1, data[2], data[1], nPages);//TODO: REMOVE IT -tb-
		}
		
        int nPagesHandled = 0; 
		while(page0 != page1){    // TODO: avoid multiple trigger readout - should be improved -tb- 2008-03-12
			//if(page0 != page1){
			katrinDebugDataStruct theDebugEvent;
			
			nEvents++;
			
			// Move the pointer to the next page	
			page0 = (page0 + 1) % 512;	// Go to the next page 
			nPages = (512 + page1 - page0) %512;
			nextEventPage = page0; // Store the page pointer for the next readout call
			
			//read the event from the trigger memory and format into an event structure
			uint32_t channelMap = (data[0] >> 10)  & 0x3fffff;
			katrinEventDataStruct theEvent;
			theEvent.channelMap = channelMap;
			int eventId = data[0] & 0x3ff;
			//theEvent.eventID	= (nPages << 16) | eventId;
			theEvent.eventID	= ((nPagesHw - nPagesHandled) << 16) | eventId;
			theEvent.subSec     = data[1];
			theEvent.sec        = data[2];
			
			// Go to the next data block
			data = data + 4;
			
			// Check for missing events
			// ak 19.7.07
			if (lastEventId < 8888) {
				int diffId = (1024 + eventId - lastEventId) % 1024; 
				if (diffId > 1){
					nMissingEvents = nMissingEvents + diffId - 1; // -1 is a small correction for the current ID: the ID is other than expected, 
					// but from here we will read out again correctly -tb-
					if (!overflowDetected){
						//NSLogError(@"",@"Katrin FLT Card Error",[NSString stringWithFormat:@"Card%d",[self stationNumber]],@"OverFlow",nil);
						//NSLog(@"Event %d  -  EventId check failed: %d - %d = %d\n", nEvents, eventId, lastEventId, diffId);
						//NSLog(@"Ev %6d ,page %4d / %4d, EventId %4d - %4d = %4d | err %6d\n", 
						//      nEvents, actualPage, page1-actualPage, lastEventId, eventId, diffId, nMissingEvents);
					}  
				}
			}  
			lastEventId = eventId;
			
			// Check for buffer overflow
			// 
			uint32_t bufState =  (statusWord >> kKatrinFlt_Cntrl_BufState_Shift) & 0x3;
			//NSLog(@"Buffer state :  %x\n", bufState);
			if(bufState == 0x3){
                overflowDetected = true;
                overflowDetectedCounter++;
            }
			
			if(usingPBusSimulation){	
				// Test: Read a few channel?!		
				channelMap = 0x25;
				theEvent.eventID = nextEventPage; // increment the event id (only run mode)
			}		
			
			if(channelMap){
				int aChan;
				int32_t readAddress = 0; 
				for(aChan=0;aChan<kNumFLTChannels;aChan++){
					if( (1L<<aChan) & channelMap){
						
						theEvent.channelMap =  (aChan << 24) | channelMap;
						
						locationWord &= 0xffff0000;
						locationWord |= (aChan&0xff)<<8; // New: There is a place for the channel in the header?!
						
						if(fltRunMode == kKatrinFlt_Run_Mode){
							//the event energy address is computed from the subSec part of the trigger data
#if 1
                            //DEBUG INFO: this is the original code -tb- 2008-03-18:
                        	readAddress = memoryAddress | (aChan << kKatrinFlt_ChannelAddress) | (theEvent.subSec & 0xffff);
#else
                            //DEBUG INFO: DISABLE THIS - debugging (reads energy from energy register)!!! ((keep it for debugging)) -tb-
							readAddress = statusAddress | (kFLTTriggerEnergyCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress);
#endif
						} 
						else if (fltRunMode == kKatrinFlt_Debug_Mode){		
							// Read the energy from TriggerEnergy register
							readAddress = statusAddress | (kFLTTriggerEnergyCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress);
						}							
						
						// Extra information for debug mode
						// Reset / restart time stamp
						if(fltRunMode == kKatrinFlt_Debug_Mode){
							// Read the reset time
							if (useResetTimestamp){
								uint32_t addr = statusAddress | (kFLTTimeCounterCode << kKatrinFlt_AddressSpace) | 1;
								resetSec    = [fireWireCard read:addr ];
								addr = addr + 1;
								resetSubSec = [fireWireCard read:addr ];
								
								theDebugEvent.resetSec  = resetSec;
								theDebugEvent.resetSubSec = resetSubSec;
								
								// Check if the data is continuous
								// Recording time
								// t_ev - t_reset > readoutPages * 1024 * 100ns										
								int32_t recTime = (theEvent.sec - theDebugEvent.resetSec) * 10000000 +
								(theEvent.subSec - theDebugEvent.resetSubSec);		// 100ns bins
								if (recTime < 1024 * 	readoutPages) {
									//NSLog(@"Event %d: The reording time is short than readout windows\n", nEvents);
									//NSLog(@"Recording time %d x 100ns <  %d x 100us\n", recTime, readoutPages);
								}		
								
								//NSLog(@"Reset (addr = %08x): %d, %d\n", addr, resetSec, resetSubSec);
							}
						}				
						
						// In debug and run mode the basic event information is transmitted 
						// to the data handler
						// ak 15.6.07							
						// The hardware returns the product of energy and filter length
						// The energy values are shifted to remove the effect of the filter length
						// ak 24.9.07	
#ifdef USE_ENERGYSHIFT											
						theEvent.energy	= ([fireWireCard read:readAddress] & 0xffff) << energyShift[aChan];
#else				
						theEvent.energy	= ([fireWireCard read:readAddress] & 0xffff);
#endif
						
#if 1
#if 0 // old check -tb-
						if(checkEnergyEnabled){//check the "trigger enabled"
							static BOOL triggEnabled=TRUE;
							unsigned short triggEnabledChan0 = ([self readTriggerControl:0 /* fpga 0 */] >> 8) &0x1;
							unsigned short triggEnabledChan1 = ([self readTriggerControl:1 /* fpga 1 */] >> 8) &0x1;
							if( (((nLoops/100)*100) % 2000) == 0)
							{// show the flags every 1000 events
								//NSLog(@"nLoops is %i, mod %i\n",   nLoops,nLoops % 1000);
								NSLog(@"nLoops is %i: trigg-flags: flag0 %i flag1 %i \n",   nLoops,triggEnabledChan0,triggEnabledChan1 );
							}
							if(triggEnabled && !triggEnabledChan0){
								triggEnabled=FALSE;
								NSLog(@"TriggerEnableBit (ch0) was set to FALSE; sec %i subsec %i\n",
									  theEvent.sec, theEvent.subSec);
							}
						}
#endif
						if(checkEnergyEnabled)
						{// TODO: debugging - REMOVE or make "Additional energy test ..." flag -tb- ... OK, done -tb-
							// 1.read energy from energy register
							// 2.read status register, extract write pointer
							// 3.if write pointer did not change, the energy value from energy memory and from
							//   energy register should be the same ...
							uint32_t statusWord3 = [fireWireCard read:statusAddress];		//is there any data?
							int page3 = (statusWord3 >> 11) & 0x1ff;	// Get write page pointer
							// DEBUG INFO: REMOVE or comment out this: for debugging (reads energy from energy register)!!!
							int32_t readAddress3 = statusAddress | (kFLTTriggerEnergyCode << kKatrinFlt_AddressSpace) | (aChan << kKatrinFlt_ChannelAddress);
							uint32_t energy3	= ([fireWireCard read:readAddress3] & 0xffff);
							//NSLog(@"TESTING: page3 (%i) nextEventPage (%i), Ereg (%i) Emem (%i), sec %i subsec %i\n",
							//                             page3,nextEventPage,energy3,theEvent.energy, theEvent.sec, theEvent.subSec);
							if(page3==nextEventPage){
								if(energy3!=theEvent.energy){
									NSLog(@"ENERGY register (%i) and ENERGY memory are different (%i), sec %i subsec %i\n",
										  energy3,theEvent.energy, theEvent.sec, theEvent.subSec);
								}
								
							}//else{there was another write access}
							
						}//END OF DEBUGGING PART
#endif
						if(fltRunMode == kKatrinFlt_Run_Mode){
							uint32_t totalLength = 2 + (sizeof(katrinEventDataStruct)/sizeof(int32_t));
							NSMutableData* theEnergyData = [NSMutableData dataWithCapacity:totalLength*sizeof(int32_t)];
							uint32_t header = dataId | totalLength;	//total event size + the two ORCA header words (in longs!).
							
							[theEnergyData appendBytes:&header length:4];							//ORCA header word
							[theEnergyData appendBytes:&locationWord length:4];						//which crate, which card info
							[theEnergyData appendBytes:&theEvent length:sizeof(katrinEventDataStruct)];
							[aDataPacket addData:theEnergyData];									//ship the energy record
#if 0
                            //DEBUGGING PART >>>>>>>>>>>>>>>
                            if([self checkEnergyEnabled])
                            {//for debugging ... REMOVE IT in release version -tb- 2008-03-17
                                if(theEvent.energy <670){
                                    NSLog(@"ENERGY TOO SMALL (%i), sec %i subsec %i\n",
                                          theEvent.energy, theEvent.sec, theEvent.subSec);
#if 0
                                    NSLog(@"   more info...: page3 (%i) nextEventPage (%i), Ereg (%i) Emem (%i), sec %i subsec %i\n",
                                          page3,nextEventPage,energy3,theEvent.energy, theEvent.sec, theEvent.subSec);
#endif
                                }
                            }
                            //DEBUGGING PART <<<<<<<<<<<<<<<<<<
#endif
						}
						
						// Readout of ADC-Traces available only in debug-mode
						// ak, 15.6.07												
						else if(fltRunMode == kKatrinFlt_Debug_Mode){
							
							uint32_t totalLength = (2 + (sizeof(katrinEventDataStruct)/sizeof(int32_t)) 
														 + (sizeof(katrinDebugDataStruct)/sizeof(int32_t))
														 + readoutPages*512);	// longs (1 page=1024 shorts [16 bit] are stored in 512 longs [32 bit])
							NSMutableData* theWaveFormData = [NSMutableData dataWithCapacity:totalLength*sizeof(int32_t)];
							uint32_t header = waveFormId | totalLength;
							
							[theWaveFormData appendBytes:&header length:4];				           //ORCA header word
							[theWaveFormData appendBytes:&locationWord length:4];		           //which crate, which card info
							[theWaveFormData appendBytes:&theEvent length:sizeof(katrinEventDataStruct)];
							[theWaveFormData appendBytes:&theDebugEvent length:sizeof(katrinDebugDataStruct)];									
							
							
							// Use block read mode.
							// With every 32bit (int32_t word) two 12bit ADC values are transmitted
							// ak 19.6.07
							[theWaveFormData setLength:totalLength*sizeof(int32_t)]; //we're going to dump directly into the NSData object so
							//we have to set the total size first. (Note: different than 'Capacity')
							int j;
							uint32_t addr =  (startBin & 0xffff);
							short* waveFormPtr = ((short*)[theWaveFormData bytes]) + (4*sizeof(short))
							+ (sizeof(katrinEventDataStruct)/sizeof(short))
							+ (sizeof(katrinDebugDataStruct)/sizeof(short)); //point to start of waveform
							
							uint32_t *lPtr = (uint32_t *) waveFormPtr;
 							for (j=0;j<readoutPages;j++){
								
								uint32_t readAddress =  memoryAddress | (aChan << kKatrinFlt_ChannelAddress) | addr;
								[fireWireCard read:readAddress data:lPtr size:512*sizeof(int32_t)];														
								
								addr = (addr + 1024) % 0x10000;
								lPtr = lPtr + 512;
							}
							
							if(usingPBusSimulation){
								// Add trigger for simulation mode								  
								waveFormPtr[(readoutPages-1)*1024+510] = waveFormPtr[(readoutPages-1)*1024+510] | 0x8000;
							}   
							
							if(checkWaveFormEnabled){
								[self checkWaveform:waveFormPtr];
							}
							
							// Check if the data is completely in the buffer
							// In case of a second strobe the recording is not continuos at the 
							// end of the buffer.
							// TODO: Implement a more intelligent readout for traces in the beginning of the second, ak 29.2.08
							if (theEvent.subSec > 1024 * readoutPages){
								[aDataPacket addData:theWaveFormData]; //ship the waveform
							} 
							else {
								nSkippedEvents++;
								nEvents--;
							}
							
						}
						
					} // end of channel readout
				} // end of loop over all channel
				
			}
			
		    nPagesHandled +=1;
		} // end of while	
		
		// Reset after readout req. to start data aquisition in debug mode again	
		// ak, 15.6.07			
		// If the recording is stopped there can be even more than one event be 
		// available - all channels can trigger synchronously!
		// Give reset only if all events have be processed
		// ak, 21.9.07		
		if(fltRunMode ==  kKatrinFlt_Debug_Mode){
			[self restartRun];	//reset the trigger
		}				
		
		
	} // end of if pages available
}

/*!Read the  data and add it to the Orca data stream (i.e. to aDataPacket) in binary format.
 \param aDataPacket is passed from Orca data taking main loop.
 
 The kind and size of the added data packet is encoded in the first 4 bytes (the header).
 The data IDs (e.g. hitRateId, waveFormId, ...) are assigned in: - (void) setDataIds:(id)assigner
 */  //-tb- 2008-02-6
- (void) takeDataHitrateMode:(ORDataPacket*)aDataPacket;
{
    struct timeval t;
    struct timezone tz;
    uint32_t data;
	uint32_t hitrate[22];
    uint32_t threshold;
	
    threshold = 50;
	
	
	// Wait for the second strobe
	uint32_t sec = [self readTime];
	if (sec > lastSec) {
		lastSec = sec; // Store the  actual second counter
		
		// Found second counter
		//NSLog(@"Time %d\n", sec);
        
 		// Read thresholds
		int i;
		for (i=0;i<22;i++){
			if ((activeChMap >> i) & 0x1) {
				
				// Get the hitrate 
				data = ([fireWireCard read:([self slot] << 24) | (kFLTHitRateCode << kKatrinFlt_AddressSpace) | (i<<kKatrinFlt_ChannelAddress)]);					
				hitrate[i] = data & 0xffffff;					
				if (usingPBusSimulation){
			        hitrate[i] = 8256+i;					
				}   
				//NSLog(@"%2d: %04x, age=%d, len=%d\n", i, hitrate[i], (data >> 24) & 0xf, data >> 28);
				
				
 				// Save threshold and hitrate data
				
				// Save the data set
				// The saved thresholds are always in ascending order
				//  The intervals are not equally spaced but depend on the hitrate change
				// 
				katrinHitRateDataStruct theRates;
				gettimeofday(&t,&tz);
				//theRates.sec = t.tv_sec;  
				theRates.sec = sec;  
				theRates.hitrate = hitrate[i];	
				if(hitrate[i]<=0) continue;
				
				DebugTB( NSLog(@"takeDataHitrateMode: ch/sec/h = rate%2d: %12d %04x\n", i, theRates.sec, theRates.hitrate);  ) //TODO : remove it -tb-
				
				locationWord &= 0xffff0000;
				locationWord |= (i&0xff)<<8; // New: There is a place for the channel in the header?!
				
				uint32_t totalLength = 2 + (sizeof(katrinHitRateDataStruct)/sizeof(int32_t));
				NSMutableData* thekatrinHitRateDataStruct = [NSMutableData dataWithCapacity:totalLength*sizeof(int32_t)];
				uint32_t header = hitRateId | totalLength;	//total event size + the two ORCA header words (in longs!).
				
				[thekatrinHitRateDataStruct appendBytes:&header length:4];		//ORCA header word
				[thekatrinHitRateDataStruct appendBytes:&locationWord length:4];	//which crate, which card info
				[thekatrinHitRateDataStruct appendBytes:&theRates length:sizeof(katrinHitRateDataStruct)];
				
				[aDataPacket addData:thekatrinHitRateDataStruct];	//ship the hitrate record
				
            }
        }
    }
	
	
	
}


- (void) takeDataMeasureMode:(ORDataPacket*)aDataPacket //TODO: rename it - maybe takeDataThresholdScanMode -tb-
{
	// Implementation of measure/histogram mode
	// Sweep through the threshold values and record the trigger rates
	// 24.7.07 ak
	
	uint32_t hitrate[22];
	bool saveData;
	
	// Wait for the second strobe
	uint32_t sec = [self readTime];
	if (sec > lastSec) {
		lastSec = sec; // Store the  actual second counter
		
		// Found second counter
		NSLog(@"Time %d\n", sec);
		
		// Read thresholds
		int i;
		for (i=0;i<22;i++){
			if ((activeChMap >> i) & 0x1) {
				saveData = true; 
				
				// Get the hitrate 
				hitrate[i] = ([fireWireCard read:([self slot] << 24) | (kFLTHitRateCode << kKatrinFlt_AddressSpace) | (i<<kKatrinFlt_ChannelAddress)] & 0xffffff);					
				if (usingPBusSimulation){
					if (actualThreshold[i] < 3920)		hitrate[i] = 8256;					
					else if (actualThreshold[i] > 3975)	hitrate[i] = 0;					
					else								hitrate[i] = 8256 - 8256 * (actualThreshold[i]-3920) / 55;
				}   
				NSLog(@"%2d: %04d, %04d -> %04x\n", i, actualThreshold[i], stepThreshold[i], hitrate[i]);
				
				// Start from the actual rate and increase by one?!
				// Find the maximum rate
				if (maxHitrate[i] == 0){
					maxHitrate[i] = hitrate[i];
					lastHitrate[i] = hitrate[i];
				}
				
				// Detect changes
				uint32_t diffHitrate = lastHitrate[i] - hitrate[i];
				if (diffHitrate < 5)	nNoChanges[i] += 1;
				else					nNoChanges[i] = 0;
				
				// Automatically reduce the step size if a hitrate change is
				// detected
				if (stepThreshold[i] > 2){ 
					
					// Decrease step size, if necessary
					if (diffHitrate > 5){
						actualThreshold[i] = actualThreshold[i] - stepThreshold[i];	// Go back to the last threshold
						stepThreshold[i] = stepThreshold[i] / 10;					// Change go with the smaller  
						saveData = false;											// Do not send the data
					}
				}  
				
				// Increase step size if the frequency does not change
				if ((nNoChanges[i] > 5) && (hitrate[i] > 0)){	
					// Increase the step size									   
					if (stepThreshold[i] < 2000){
						stepThreshold[i] = stepThreshold[i] * 10;					// Change go with the smaller 
					}	  
					
				}
				
				// Reached the end of the frequency plot
				if ((nNoChanges[i] > 5) && (hitrate[i] == 0)){										   
					// Start again
					actualThreshold[i] = savedThreshold[i]-2000; // will be incremented at the end of the loop
					stepThreshold[i] = 2000;
					maxHitrate[i] = 0;
					
					// Stop, remove the flag from the channel mask
					//activeChMap = activeChMap ^ (0x1 << i);
					
					// Don't save this sample
					saveData = false;					   
				}
				
				// Save threshold and hitrate data
				if (saveData) {
					
					// Save the data set
					// The saved thresholds are always in ascending order
					//  The intervals are not equally spaced but depend on the hitrate change
					// 
					// TODO:
					// The energy and the thresholds does not fit perfectly?!
					// Find out the relation between threshold and energy
					//
					katrinThresholdScanDataStruct theRates;
					theRates.channelMap = (i << 24) | activeChMap;
					theRates.threshold = actualThreshold[i];  // << 1;  Adjust to energy scale ??
					theRates.hitrate = hitrate[i];			
					
					locationWord &= 0xffff0000;
					locationWord |= (i&0xff)<<8; // New: There is a place for the channel in the header?!
					
					uint32_t totalLength = 2 + (sizeof(katrinThresholdScanDataStruct)/sizeof(int32_t));
					NSMutableData* thekatrinThresholdScanDataStruct = [NSMutableData dataWithCapacity:totalLength*sizeof(int32_t)];
					uint32_t header = thresholdScanId | totalLength;	//total event size + the two ORCA header words (in longs!).
					
					[thekatrinThresholdScanDataStruct appendBytes:&header length:4];		//ORCA header word
					[thekatrinThresholdScanDataStruct appendBytes:&locationWord length:4];	//which crate, which card info
					[thekatrinThresholdScanDataStruct appendBytes:&theRates length:sizeof(katrinThresholdScanDataStruct)];
					
					[aDataPacket addData:thekatrinThresholdScanDataStruct];	//ship the hitrate record
					
					
					// Only store the hitrate, if the sample was used!
					lastHitrate[i] = hitrate[i];  
					lastThreshold[i] = actualThreshold[i];					    
				}
				
				// Go the the next threshold
				actualThreshold[i] += stepThreshold[i];
				
				[self writeThreshold:i value:actualThreshold[i]];   // Hw
				[self setThreshold:i withValue:actualThreshold[i]]; // GUI
				
				// TODO: Wait for more than one second
				lastSec = sec + 1; // Wait for one second
			}		  
		}
		//since notifications are delivered to the thread they are posted in, we'll pass this one back to the main thread.
		[self performSelectorOnMainThread:@selector(postHitRateChange) withObject:nil waitUntilDone:NO];
	}
}

/** @todo FPGA-Bug
 * In histogram mode: if TRun is set to a non zero value the run stops after that time (as it is supposed to do)
 * but the firstBin, lastBin and histogram data are reset to zero immediatly.
 * (This bug report is in ORKatrinFLTModel.m  -tb- 2008-02-29 )
 */ //-tb- 2008-02-29


/*!Read the FLT hardware histogram data and add it to the Orca data stream (i.e. to aDataPacket) in binary format.
 \param aDataPacket is passed from Orca data taking main loop.
 
 The kind and size of the added data packet is encoded in the first 4 bytes (the header).
 The data IDs (e.g. hitRateId, waveFormId, ...) are assigned in: - (void) setDataIds:(id)assigner
 */  //-tb- 2008-02-26
- (void) takeDataHistogramMode:(ORDataPacket*)aDataPacket;
{
    //BEGIN -  - of (pbus) simulatin mode -tb- 2008-04-06
    if(usingPBusSimulation){
        uint32_t tRun;
        uint32_t tRec;
        tRun = histoRunTime;//[self readTRunForChan:0];//TODO : test implementation for chan 0 -tb-
        if(tRun != 0){// we are in "restart mode": read out the histogram when tRun elapsed
            tRec = histoLastPageToggleSec;
            if(  tRec >= tRun){//after tRun seconds write a histogram and reset timer
                DebugHistoTB( NSLog(@"ORKatrinFLT %02d: emulate readout in histogram mode.\n",[self stationNumber]);  )
                //write random data to the buffer and call readOutHistogramDataV3 -tb-
                {
                    int chan;
                    for(chan=0;chan<kNumFLTChannels;chan++){
                        if(  ([self histoChanToGroupMap:chan] !=-1)  && ([self triggerEnabled:chan])  ){
                            DebugHistoTB( NSLog(@"ORKatrinFLT:   emulate channel %i\n",chan);  )
                        }
                    }
                    [self readOutHistogramDataV3:aDataPacket userInfo:nil];
                }
                histoLastPageToggleSec=0;
                return;
            }
        }//else if TRun == 0 we have to emulate the "read out" after run stop i.e. in runTaskStopped
        // Wait for the second strobe
        uint32_t sec = [self readTime];   //QUESTION is this the crate time? format? yes; full seconds -tb- 2008-02-26
        [self setHistoCalibrationElapsedTime:sec - histoStartTimeSec];
        //if ( sec>lastSec  &&  (((sec+1) - lastSec)%2) == 0 ) {
        if ( sec-lastSec >=1 ) {  // 2 = every  3 seconds
            DebugHistoTB( NSLog(@"This is   takeDataHistogramMode heartbeat: %i\n",sec);  )
            // send notification to GUI
            // read recording time etc
            [self setHistoRecordingTime:histoLastPageToggleSec];
            histoLastPageToggleSec ++; //increase every second to emulate the TRun counter on the board
            //[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
            lastSec = sec; // Store the  actual second counter
            //NSLog(@"Time %d\n", sec);
        }
        return;
    }
    //END   - of (pbus) simulatin mode -tb- 2008-04-06
	
	
	
    //this is for FPGA version >= 3 (since April 2008), with new feature "paging" etc. -tb-
    if([self versionRegHWVersion]>=0x3){
        //vars
        static double delayTime = 0.1; // in sec.: its a kind of 'local const' -tb-
        unsigned int aPixel=0;// I use pixel 0, as all channels should run syncronized ... [self histoCalibrationChan];
        int histoCurrentActivePage=0;
        int32_t currentSec;
        int32_t currentUSec;
        struct timeval t;//    struct timezone tz; is obsolete ... -tb-
        //timing
        gettimeofday(&t,NULL);
        currentSec = (uint32_t)t.tv_sec;
        currentUSec = (uint32_t)t.tv_usec;  
        double diffTime = (double)(currentSec  - histoLastPageToggleSec) +
		((double)(currentUSec - histoLastPageToggleUSec)) * 0.000001;
        //I want run this method only every 0.1 sec (=delayTime) or less -tb-
        currentDelayTime = 10*               (currentSec  - histoStartTimeSec) +
		(int)(    ((double)(currentUSec - histoStartTimeUSec)) * 0.00001  );// in fact we compute (...)/delayTime!
        if(currentDelayTime <= lastDelayTime){//I could also check histoStartWaitingForPageToggle -tb-
            return ;//wait longer time
        }else{
            lastDelayTime = currentDelayTime;
            //check that we can actually run  TODO : do I need it here ? -tb- I think yes, to be safe -tb-
            if(![[[self crate] adapter] serviceIsAlive]){
                [self setHistoCalibrationIsRunning:FALSE];
                [NSException raise:@"No FireWire Service" format:@"takeDataHistogramMode: Check Crate Power and FireWire Cable."]; 
            }
        }
		
        DebugHistoTB(
					 histoCurrentActivePage = [self readCurrentHistogramPageNum]; 
					 NSLog(@"Time since last paging; %f     (page %i,TRec %i, status %i)\n",
						   diffTime,histoCurrentActivePage,[self histoRecordingTime],[self readHistogramControlRegisterOfPixel:aPixel]);
					 )
        
        //TEST, IF HISTOGRAMMING IS STILL RUNNING: (check before histoLastActivePage = histoCurrentActivePage;)
        //if TRun was set, maybe the run already stopped ... or we are in "stop if not cleared" mode ...
        //or somebody clicked Run Start, then SLT resets allFLTs = stops histogramming
        //if(histoCalibrationIsRunning  &&  !([self readHistogramControlRegisterOfPixel:aPixel] & 0x1)  ){
        if(histoCalibrationIsRunning){
            //int flag= [self readHistogramControlRegisterOfPixel:aPixel] &0x1;
            int flag= [self readHistogramControlRegisterOfPixel:aPixel] &0x1;
            if(flag==0){
                DebugHistoTB(
							 NSLog(@"HISTOGRAMMING was terminated by unknown reason.\n");
							 )
                //[self stopCalibrationHistogram];
                // histogramming was terminated by some reason (probably "stop after no clear") -tb-
                // -> wait for page toggle (max. TRun sec), read out, then do nothing (maybe warning)
                
                //set vars
                //this is a simple "stop all", needs redesign -tb-
                [self setHistoCalibrationIsRunning:FALSE];
                histoStartWaitingForPageToggle = FALSE;
                //stop histogramming (maybe other channels are running ...)
                [self writeStopHistogramForChan:31];
                //update gui. ... ??? not necessary -tb-
                return;
            }
        }
        
        
        //START waiting/testing FOR the PAGE TOGGLE if there are about 0.2 sec left to cycle end (TRun)
        //    (if TRun is 0, we will immediately start waiting for the page toggling)
        if(!histoStartWaitingForPageToggle   && ((double)[self histoRunTime]) - diffTime <= 2.0*delayTime){/*= 2.0 * 0.1 sec*/
            histoStartWaitingForPageToggle = TRUE;
            histoCurrentActivePage = [self readCurrentHistogramPageNum];
            DebugHistoTB(  NSLog(@"    Prepare to wait for second strobe/page (old %i, curr %i) toggle to readout histogram.\n",histoLastActivePage,histoCurrentActivePage);  )
            //here I should read out TRec recording time
            int chan;
            for(chan=0; chan<kNumFLTChannels;chan++){
                if([self histoChanToGroupMap:chan] != -1) histogramDataRecTimeSec[chan]=(int)[self readTRecForChan:chan];
            }
        }
        //TODO: test the time
        //if  ((double)[self histoRunTime]) - diffTime < 0 ) then: something wrong with toggle bit
		// if(TRec == 0) restart anyway
		// ...
        //waiting for toggle to readout the histogram
        gettimeofday(&t,NULL);
        if(histoStartWaitingForPageToggle){
            histoCurrentActivePage = [self readCurrentHistogramPageNum];
            if(histoCurrentActivePage != histoLastActivePage){
                // yes, there was the toggle, read out the page/histogram
                //READOUT DATA AND SHIP TO ORCA DATA STREAM
                [self readOutHistogramDataV3:aDataPacket userInfo:nil];
				
                DebugHistoTB(  NSLog(@"READ HISTOGRAM\n");  )
                aPixel = [self histoCalibrationChan]; //the selected chan of the GUI
                //[self readHistogramDataForChan:aPixel];  already done in readOutHistogramDataV3
				//[self readHistogramDataForChan:0];//should  already done in readOutHistogramDataV3
				//[self readHistogramDataForChan:1];//should  already done in readOutHistogramDataV3
				//[self readHistogramDataForChan:12];//should  already done in readOutHistogramDataV3
				//[self readHistogramDataForChan:13];//should  already done in readOutHistogramDataV3
                //now display it, care not to clear the display in the next lines ...
                [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationPlotterChanged object:self];
                //first bin/last bin needs display now, they will be cleared afterwards
                //remove -tb- [self setHistoFirstBin:[self readFirstBinForChan:aPixel]];
                //remove -tb- [self setHistoLastBin: [self readLastBinForChan:aPixel]];
                [self setHistoFirstBin: histogramDataFirstBin[aPixel] ];
                [self setHistoLastBin:  histogramDataLastBin[aPixel] ];
                //CLEAR
                if([self histoClearAfterReadout]){
                    DebugHistoTB(  NSLog(@"CLEAR HISTOGRAM\n");  )
                    //[self clearCurrentHistogramPageForChan:aPixel];
                    //replaced by broadcast -tb-
                    [self clearCurrentHistogramPageForChan: 31];
                }
                //reset flags etc
                histoStartWaitingForPageToggle = FALSE;
                histoLastActivePage = histoCurrentActivePage;
                histoLastPageToggleSec = histoPreToggleSec;   //used for timing of page toggle.
                histoLastPageToggleUSec= histoPreToggleUSec;  //  ''
				//maybe the time from last call would be better
            } // else continue ... waiting for toggle ...
        }
        //remember for next call
        histoPreToggleSec      = (int)currentSec;
        histoPreToggleUSec     = (int)currentUSec;
        
        
        
        //HANDLE THE GUI (the KatrinFLTController)
        //NSLog(@"This is checkHistogramOfPixel: %i\n",aPixel  ); 	
        //update time
        int32_t histoCurrTimeSec;
        int32_t histoCurrTimeUSec;
        //gettimeofday(&t,NULL);
        //histoCurrTimeSec = t.tv_sec;  
        //histoCurrTimeUSec = t.tv_usec; 
        histoCurrTimeSec = currentSec;  
        histoCurrTimeUSec = currentUSec; 
        [self setHistoCalibrationElapsedTime: (double)(histoCurrTimeSec - histoStartTimeSec) + 0.000001 * (double)(histoCurrTimeUSec - histoStartTimeUSec)];
        //NSLog(@"This is checkHistogramOfPixel:       %20i %20i \n",  histoCurrTimeSec,histoCurrTimeUSec); 	
        //NSLog(@"This is checkHistogramOfPixel:       %20.12f \n",  histoTestElapsedTime); 	
        
        // recording time etc. from FLT
        [self setHistoRecordingTime:(int)[self readTRecForChan:aPixel]];
        
        // send notification to GUI
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
        
        // update page textfield TODO: make more elegant? -tb- (write setter/getter etc...)
        [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoPageNumChanged object:self];
        
#if 0
        if(histoCalibrationIsRunning){
            //restart timing ...
            [self performSelector:@selector(checkCalibrationHistogram) withObject:nil afterDelay:delayTime /*0.1 sec*/];
        }
#endif
        return;
    }
	
	
	
    //BEGIN - this is obsolete but left for downward compatibility for older FPGA configurations -tb- 2008-04-06
    //this is for old versions < 3 (between Nov 2007 and April 2008), first test versions -tb-
    if([self versionRegHWVersion]<0x3){
        uint32_t tRun;
        uint32_t tRec;
        tRun = [self readTRunForChan:0];//TODO : test implementation for chan 0 -tb-
        if(tRun != 0){// we are in "restart mode": read out the histogram when tRun elapsed
            //TODO : we need to handle the "T_Run reset bug": stop and read out 1 sec before tRun elapsed -tb- 2008-03-14
            //TODO : needs refactoring after bug fix -tb- 2008-03-14
            tRec = [self readTRecForChan:0];//TODO : test implementation for chan 0 -tb-
            if(tRun - tRec <= 1){//without bug: tRun - (tRec+1) == 1   OR (tRun - tRec <= 0)
                if(tRun - tRec < 1) NSLog(@"ORKatrinFLT: probably lost data in histogram mode.\n");
                [self pauseHistogrammingAndReadOutData:aDataPacket userInfo:nil];
                //Restart histogramming:
                //write HistControlReg to set bin width and to start histogramming
                [self writeStartHistogram:histoBinWidth  forChan:0];//TODO : test implementation for chan 0 -tb-
                return;
            }
        }
        // Wait for the second strobe
        uint32_t sec = [self readTime];   //QUESTION is this the crate time? format? yes; full seconds -tb- 2008-02-26
        //if ( sec>lastSec  &&  (((sec+1) - lastSec)%2) == 0 ) {
        if ( sec-lastSec >=1 ) {  // 2 = every  3 seconds
            DebugTB( NSLog(@"This is   takeDataHistogramMode heartbeat: %i\n",sec); )
            // send notification to GUI
            // read recording time etc
            unsigned int aPixel=0;   //TODO : for release version check all pixels ? -tb- ... old firmware ... -tb-
            [self setHistoRecordingTime:(int)[self readTRecForChan:0]];
            [self setHistoFirstBin:(int)[self readFirstBinForChan:aPixel]];
            [self setHistoLastBin:(int)[self readLastBinForChan:aPixel]];
            //[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
            lastSec = sec; // Store the  actual second counter
            // Found second counter
            //NSLog(@"Time %d\n", sec);
        }
    }
    //END   - this is obsolete but left for downward compatibility for older FPGA configurations -tb- 2008-04-06
    
	
	// next: loop over all available channels (check for "trigger enabled")
#if 0    
    struct timeval t;
    struct timezone tz;
    uint32_t data;
	uint32_t hitrate[22];
    uint32_t threshold;
	
    threshold = 50;
#endif
#if 0    
    uint32_t tRun;
    uint32_t tRec;
    tRun = [self readTRunForChan:0];//TODO : test implementation for chan 0 -tb-
    if(tRun != 0){// we are in "restart mode": read out the histogram when tRun elapsed
        //TODO : we need to handle the "T_Run reset bug": stop and read out 1 sec before tRun elapsed -tb- 2008-03-14
        //TODO : needs refactoring after bug fix -tb- 2008-03-14
        tRec = [self readTRecForChan:0];//TODO : test implementation for chan 0 -tb-
        if(tRun - tRec <= 1){//without bug: tRun - (tRec+1) == 1   OR (tRun - tRec <= 0)
            if(tRun - tRec < 1) NSLog(@"ORKatrinFLT: probably lost data in histogram mode.\n");
            [self pauseHistogrammingAndReadOutData:aDataPacket userInfo:nil];
            //Restart histogramming:
            //write HistControlReg to set bin width and to start histogramming
            [self writeStartHistogram:histoBinWidth  forChan:0];//TODO : test implementation for chan 0 -tb-
            return;
        }
    }
	// Wait for the second strobe
	uint32_t sec = [self readTime];   //QUESTION is this the crate time? format? yes; full seconds -tb- 2008-02-26
	//if ( sec>lastSec  &&  (((sec+1) - lastSec)%2) == 0 ) {
	if ( sec-lastSec >=1 ) {  // 2 = every  3 seconds
        NSLog(@"This is   takeDataHistogramMode heartbeat: %i\n",sec);
        // send notification to GUI
        // read recording time etc
        unsigned int aPixel=0;   //TODO : for release version check all pixels ? -tb-
        [self setHistoRecordingTime:[self readTRecForChan:0]];
        [self setHistoFirstBin:[self readFirstBinForChan:aPixel]];//TODO : testing with pixel 0 -tb-
        [self setHistoLastBin:[self readLastBinForChan:aPixel]];
        //[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
		lastSec = sec; // Store the  actual second counter
		
		// Found second counter
		//NSLog(@"Time %d\n", sec);
        
        
#if 0
 		// 
		int i;
		for (i=0;i<22;i++){
			if ((activeChMap >> i) & 0x1) {
				
				// Get the hitrate 
				data = ([fireWireCard read:([self slot] << 24) | (kFLTHitRateCode << kKatrinFlt_AddressSpace) | (i<<kKatrinFlt_ChannelAddress)]);					
				hitrate[i] = data & 0xffffff;					
				if (usingPBusSimulation){
			        hitrate[i] = 8256+i;					
				}   
				//NSLog(@"%2d: %04x, age=%d, len=%d\n", i, hitrate[i], (data >> 24) & 0xf, data >> 28);
				
				
 				// Save threshold and hitrate data
				
				// Save the data set
				// The saved thresholds are always in ascending order
				//  The intervals are not equally spaced but depend on the hitrate change
				// 
				katrinHitRateDataStruct theRates;
				gettimeofday(&t,&tz);
				//theRates.sec = t.tv_sec;  
				theRates.sec = sec;  
				theRates.hitrate = hitrate[i];	
				if(hitrate[i]<=0) continue;
				
				NSLog(@"takeDataHitrateMode: ch/sec/h = rate%2d: %12d %04x\n", i, theRates.sec, theRates.hitrate);//TODO: remove it -tb-
				
				locationWord &= 0xffff0000;
				locationWord |= (i&0xff)<<8; // New: There is a place for the channel in the header?!
				
				uint32_t totalLength = 2 + (sizeof(katrinHitRateDataStruct)/sizeof(int32_t));
				NSMutableData* thekatrinHitRateDataStruct = [NSMutableData dataWithCapacity:totalLength*sizeof(int32_t)];
				uint32_t header = hitRateId | totalLength;	//total event size + the two ORCA header words (in longs!).
				
				[thekatrinHitRateDataStruct appendBytes:&header length:4];		//ORCA header word
				[thekatrinHitRateDataStruct appendBytes:&locationWord length:4];	//which crate, which card info
				[thekatrinHitRateDataStruct appendBytes:&theRates length:sizeof(katrinHitRateDataStruct)];
				
				[aDataPacket addData:thekatrinHitRateDataStruct];	//ship the hitrate record
				
            }
        }
#endif
    }
	
#endif
	
}


/** Stop histogramming, read histogram from hardware and write it into Orca data stream.
 *
 * For old FPGA version(s) < 0x3
 */ //-tb- 2008-03-05
- (void) pauseHistogrammingAndReadOutData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	
    //THE FOLLOWING PART WAS FOR FPGAversion <3
    NSLog(@"pauseHistogrammingAndReadOutData\n");
    katrinHistogramDataStruct theEventData;
	uint32_t stopsec = [self readTime];
	uint32_t sec ;
    // stop histogramming
    [self writeStopHistogramForChan:0];
    //after stopping we have to wait for the second strobe ...
    sec = [self readTime];
    while(stopsec == sec){
        usleep(100);
        sec = [self readTime];
        //NSLog(@"pauseHistogrammingAndReadOutData usleep 100   stopsec %i sec %i\n",stopsec,sec);
    }
	//usleep(1000001);
    //TODO : was still under construction, now obsolete ...  - for testing: read the first channel -tb-
    // now read out the histogram and write it to the Orca data stream
    theEventData.readoutSec = stopsec;
    //theEventData.recordingTimeSec = [self readTRec];
    theEventData.recordingTimeSec = histoRunTime;
    theEventData.firstBin  = [self readFirstBinForChan: 0];
    theEventData.lastBin   = [self readLastBinForChan:  0];
    theEventData.histogramLength = theEventData.lastBin - theEventData.firstBin +1;
    if(theEventData.histogramLength < 0){// we had no counts ...
        theEventData.histogramLength = 0;
    }
    //theEventData.binWidth  = histoBinWidth; // needed here? is already in the header!
    
    // the standard header
    int aPixel =0;
	locationWord &= 0xffff0000;
	locationWord |= (aPixel & 0xff)<<8; // New: There is a place for the channel in the header?!
	
    uint32_t totalLength = 2 + (sizeof(katrinHistogramDataStruct)/sizeof(int32_t)) + theEventData.histogramLength;// 2 = header + locationWord
	NSMutableData* theData = [NSMutableData dataWithCapacity:totalLength*sizeof(int32_t)];
	uint32_t header = histogramId | totalLength;	//total event size + the two ORCA header words (in longs!).
	
	[theData appendBytes:&header length:4];		//ORCA header word
	[theData appendBytes:&locationWord length:4];	//which crate, which card info
	[theData appendBytes:&theEventData length:sizeof(katrinHistogramDataStruct)];
	
    //this is mainly  from readHistogramDataOfPixel
    //unsigned int i,firstBin, lastBin, currVal, sum;
    if(theEventData.histogramLength>0){
        int sum=0;
        unsigned int func  = 0x6; // = b110
        unsigned int LAddr12 = 0xC; //0xC is Histogrm:HDATA
        unsigned int Pixel = 0; // TODO: for testing: it is not per pixel, but per FPGA
        if(aPixel == 0) Pixel=0;
        if(aPixel == 1) Pixel=1;
        if(aPixel == 12) Pixel=2;
        if(aPixel == 13) Pixel=3;
        unsigned int address  = ([self slot] << 24) | (func << 21) | (Pixel << 16) | (LAddr12 <<12);
        uint32_t i;
        uint32_t currVal;
        for(i=theEventData.firstBin; i<=theEventData.lastBin; i++){
            currVal =  [self read: address | i];
            sum += currVal;
            NSLog(@"    bin %4u: %4u \n",i , currVal); 	
            //[[histogramData objectAtIndex:i] setIntValue:currVal];
            //histogramDataUI[i]= currVal;
            [theData appendBytes:&currVal length:4];		//ORCA header word
			
        }
        NSLog(@"sum: %4u \n",sum); 	
    }
	[aDataPacket addData:theData];	//ship the histogram record
	
}

/** Read histogram from hardware and write it into Orca data stream. Then lets Orca go on.
 * Requires that we can read (does NOT care about the correct page toggle bit)!!!
 *
 * For NEW FPGA version(s) >= 0x3 ([self versionRegHWVersion]>=0x3)
 */ //-tb- 2008-03-05
- (void) readOutHistogramDataV3:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    DebugHistoTB(  NSLog(@"READ HISTOGRAMS\n");  )
    int chan;
    uint32_t stopsec = [self readTime];
    for(chan=0; chan<kNumFLTChannels;chan++){
        if(  ([self histoChanToGroupMap:chan] == -1)  ) continue; //this chan is not available
        if(  (![self triggerEnabled:chan])   ) continue; //this chan is not activated
        DebugHistoTB(  NSLog(@"readOutHistogramDataV3: chan %i\n",chan);  )
        katrinHistogramDataStruct theEventData;
        
        //from checkCalibrationHistogram
        if(usingPBusSimulation){
            [self histoSimulateReadHistogramDataForChan: chan];
        }else{
            [self readHistogramDataForChan:chan]; // this writes the histogram to the buffer 'histogramData'
        }
        
        // now read out the histogram and write it to the Orca data stream
        theEventData.readoutSec = stopsec;
        //theEventData.recordingTimeSec = histoRecordingTime;
        //theEventData.recordingTimeSec = histogramDataRecTimeSec[chan];//was readout in takeDataHistogramMode[self readTRecForChan:chan];
        theEventData.recordingTimeSec =  histoRunTime; //changed 2008-07 to store the refresh time -tb-
        theEventData.firstBin  = histogramDataFirstBin[chan];//read in readHistogramDataForChan ... [self readFirstBinForChan: chan];
        theEventData.lastBin   = histogramDataLastBin[chan]; //                "                ... [self readLastBinForChan:  chan];
        theEventData.histogramLength = theEventData.lastBin - theEventData.firstBin +1;
        if(theEventData.histogramLength < 0){// we had no counts ...
            theEventData.histogramLength = 0;
        }
        theEventData.maxHistogramLength = 512; // needed here? is already in the header! yes, the decoder needs it for calibration of the plot -tb-
        theEventData.binSize    = histoBinWidth;        
        theEventData.offsetEMin = histoMinEnergy;
		
		
        // the standard header
        locationWord &= 0xffff0000;
        locationWord |= (chan & 0xff)<<8; // New: There is a place for the channel in the header?!
        
        uint32_t totalLength = 2 + (sizeof(katrinHistogramDataStruct)/sizeof(int32_t)) + theEventData.histogramLength;// 2 = header + locationWord
        // NSLog(@"(sizeof(katrinHistogramDataStruct)/sizeof(int32_t) %i  sizeof(katrinHistogramDataStruct) %i  sizeof(int32_t)  %i\n",
        //  sizeof(katrinHistogramDataStruct)/sizeof(int32_t),sizeof(katrinHistogramDataStruct),sizeof(int32_t));
        //    <-- is: 6, 24, 4 (was: 5, 20, 4 2008-04)
        NSMutableData* theData = [NSMutableData dataWithCapacity:totalLength*sizeof(int32_t)];
        uint32_t header = histogramId | totalLength;	//total event size + the two ORCA header words (in longs!).
        
        [theData appendBytes:&header length:4];		    //ORCA header word
        [theData appendBytes:&locationWord length:4];	//which crate, which card info
        [theData appendBytes:&theEventData length:sizeof(katrinHistogramDataStruct)];
        
        //this is mainly  from readHistogramDataOfPixel
        //TODO: I called [self readHistogramDataForChan:chan] so I have the data already in the buffer 'histogramData'
        if(theEventData.histogramLength>0){
            if(histogramData){
                unsigned int *dataPtr=0;
                dataPtr=(unsigned int *)[[histogramData objectAtIndex:chan] bytes];
                int32_t i,currVal;
                int sum=0;
                for(i=theEventData.firstBin; i<=theEventData.lastBin; i++){
                    currVal =  dataPtr[i];
                    sum += currVal;
                    //if(currVal) NSLog(@"    bin %4u: %4u \n",i , currVal); 	
                    //[[histogramData objectAtIndex:i] setIntValue:currVal];
                    //histogramDataUI[i]= currVal;
                    //TODO: store it in histogramData -tb-
                    [theData appendBytes:&currVal length:4];		//ORCA header word
                    
                }
                DebugHistoTB(  NSLog(@"sum: %4u \n",sum); 	 )
            }
        }
        
#if 0
        //unsigned int i,firstBin, lastBin, currVal, sum;
        if(theEventData.histogramLength>0){
            int sum=0;
            unsigned int adress  = [self histogramDataAdress: 0 forChan:chan];
            int i,currVal;
            for(i=theEventData.firstBin; i<=theEventData.lastBin; i++){
                currVal =  [self read: adress | i];
                sum += currVal;
                if(currVal) NSLog(@"    bin %4u: %4u \n",i , currVal); 	
                //[[histogramData objectAtIndex:i] setIntValue:currVal];
                //histogramDataUI[i]= currVal;
                //TODO: store it in histogramData -tb-
                [theData appendBytes:&currVal length:4];		//ORCA header word
                
            }
            NSLog(@"sum: %4u \n",sum); 	
        }
        //readHistogramDataOfPixel
#endif
        
        //if (usingPBusSimulation){
        //	 do something;				  //TODO: usingPBusSimulation for histogramming -tb-	
        //}  
        [aDataPacket addData:theData];	//ship the histogram record
    }
}


/*!Read the data when in FLT veto mode and add it to the Orca data stream (i.e. to aDataPacket) in binary format.
 \param aDataPacket is passed from Orca data taking main loop.
 
 The kind and size of the added data packet is encoded in the first 4 bytes (the header).
 The data IDs (e.g. hitRateId, waveFormId, ...) are assigned in: - (void) setDataIds:(id)assigner
 */  //-tb- 2008-02-26
- (void) takeDataVetoMode:(ORDataPacket*)aDataPacket;
{
    static int counter=0; //TODO: as a reminder -tb-
	counter++;
	if(counter>0 && counter <20) NSLog(@"This is   takeDataVetoMode:: UNDER CONSTRUCTION\n");
	
	//TODO: for the V3 Veto firmware I can reuse the Energy mode readout - the event buffer has the same structure -tb- 2010-03-17
#if 0
    struct timeval t;
    struct timezone tz;
    uint32_t data;
	uint32_t hitrate[22];
    uint32_t threshold;
	
    threshold = 50;
	
	
	// Wait for the second strobe
	uint32_t sec = [self readTime];   //TODO: QUESTION is this the crate time? format? -tb- 2008-02-26
	if (sec > lastSec) {
		lastSec = sec; // Store the  actual second counter
		
		// Found second counter
		//NSLog(@"Time %d\n", sec);
        
 		// Read thresholds
		int i;
		for (i=0;i<22;i++){
			if ((activeChMap >> i) & 0x1) {
				
				// Get the hitrate 
				data = ([fireWireCard read:([self slot] << 24) | (kFLTHitRateCode << kKatrinFlt_AddressSpace) | (i<<kKatrinFlt_ChannelAddress)]);					
				hitrate[i] = data & 0xffffff;					
				if (usingPBusSimulation){
			        hitrate[i] = 8256+i;					
				}   
				//NSLog(@"%2d: %04x, age=%d, len=%d\n", i, hitrate[i], (data >> 24) & 0xf, data >> 28);
				
				
 				// Save threshold and hitrate data
				
				// Save the data set
				// The saved thresholds are always in ascending order
				//  The intervals are not equally spaced but depend on the hitrate change
				// 
				katrinHitRateDataStruct theRates;
				gettimeofday(&t,&tz);
				//theRates.sec = t.tv_sec;  
				theRates.sec = sec;  
				theRates.hitrate = hitrate[i];	
				if(hitrate[i]<=0) continue;
				
				NSLog(@"takeDataHitrateMode: ch/sec/h = rate%2d: %12d %04x\n", i, theRates.sec, theRates.hitrate);//TODO: remove it -tb-
				
				locationWord &= 0xffff0000;
				locationWord |= (i&0xff)<<8; // New: There is a place for the channel in the header?!
				
				uint32_t totalLength = 2 + (sizeof(katrinHitRateDataStruct)/sizeof(int32_t));
				NSMutableData* thekatrinHitRateDataStruct = [NSMutableData dataWithCapacity:totalLength*sizeof(int32_t)];
				uint32_t header = hitRateId | totalLength;	//total event size + the two ORCA header words (in longs!).
				
				[thekatrinHitRateDataStruct appendBytes:&header length:4];		//ORCA header word
				[thekatrinHitRateDataStruct appendBytes:&locationWord length:4];	//which crate, which card info
				[thekatrinHitRateDataStruct appendBytes:&theRates length:sizeof(katrinHitRateDataStruct)];
				
				[aDataPacket addData:thekatrinHitRateDataStruct];	//ship the hitrate record
				
            }
        }
    }
	
	
#endif
}





- (void) postHitRateChange
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHitRateChanged object:self];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    // read the hardware histogram -tb- 2008-03-05
    if(daqRunMode == kKatrinFlt_DaqHistogram_Mode){	
        DebugHistoTB( NSLog(@"---runTaskStopped--kKatrinFlt_DaqHistogram_Mode------\n");  )
        [self setHistoCalibrationIsRunning:NO];
        //BEGIN -  - of (pbus) simulatin mode -tb- 2008-04-06
        if(usingPBusSimulation){
            return;
        }
        //END -  - of (pbus) simulatin mode -tb- 2008-04-06
		
        histoStartWaitingForPageToggle = FALSE;
        //this is for FPGA version >= 3 (since April 2008), with new feature "paging" etc. -tb-
        if([self versionRegHWVersion]>=0x3){
			int chan=0; //TODO: LOOP OVER ALL CHANNELS -tb-
#if 0 //MOVED TO SLT -tb-
            //to update the GUI
            [self setHistoRecordingTime:[self readTRec]];
            //first/last bin is updated after page toggle, see below ...
            
            //stop histogramming
            [self writeStopHistogramForChan:31];//   broadcast
            //wait until the page toggled that we can readout
            int histoCurrentActivePage ;
            DebugHistoTB(  NSLog(@"Waiting for page toggle (curr is %i)\n",histoLastActivePage);  )
            int i;
            for(i=0;i<10000;i++){
                histoCurrentActivePage= [self readCurrentHistogramPageNum];
                if(histoLastActivePage!=histoCurrentActivePage) break;
                usleep(100);
            }
            DebugHistoTB(  NSLog(@"Waited until i=%i (x 100 usecs) for page toggle\n",i);  )
            //usleep(1000011);
#endif
            
            //Update GUI:
            //[self checkCalibrationHistogram]; // NO! TRec is 0 after stop, see above -tb-
            //[self readHistogramDataForChan:chan];
            // send notification to GUI
            [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationPlotterChanged object:self];
            
            // send notifications to GUI to show some values (MAC Time, progress bar, re-enable some elements ...
            [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationValuesChanged object:self];
            // update page textfield TODO: make more elegant? -tb- (write setter/getter etc...)
            [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoPageNumChanged object:self];
			
            //READOUT DATA AND SHIP TO ORCA DATA STREAM
            [self readOutHistogramDataV3:aDataPacket userInfo:userInfo];
            
            //now display it, care not to clear the display in the next lines ...
            [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHistoCalibrationPlotterChanged object:self];
            //first bin/last bin needs display now, they will be cleared afterwards
            [self setHistoFirstBin:(int)[self readFirstBinForChan:chan]];
            [self setHistoLastBin: (int)[self readLastBinForChan:chan]];
            //CLEAR
            if([self histoClearAfterReadout]){
                DebugHistoTB(  NSLog(@"CLEAR HISTOGRAM\n");  )
                //[self clearCurrentHistogramPageForChan:aPixel];
                //TODO: broadcast
                [self clearCurrentHistogramPageForChan: 31];
            }
        }
        //this is for old versions < 3 (between Nov 2007 and April 2008), first test versions -tb-
        if([self versionRegHWVersion]<0x3){
            [self pauseHistogrammingAndReadOutData:aDataPacket userInfo:userInfo];
        }
    }
	
    // Restore the saved threshold
	int i;
	
	if(fltRunMode == kKatrinFlt_Measure_Mode){	//TODO: better check for daqRunMode in thresholdScanMode -tb-
		//this is from threshold scan ... ? -tb-
		for (i=0;i<22;i++){
			[self setThreshold:i withValue:savedThreshold[i]];
		}
    }
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
	int chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		hitRate[chan] = 0;
	}
	[self setHitRateTotal:0];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelHitRateChanged object:self];
	
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"----------------------------------------\n");
	NSLogFont(aFont,@"Katrin Crate:%d Card:%d\n",[self crateNumber], [self stationNumber]);
	NSLogFont(aFont,@"Record time    : %d\n", 0);
	NSLogFont(aFont,@"Events         : %d (readout loops %d)\n", nEvents, nLoops);
	NSLogFont(aFont,@"Trigger rate   : %d\n", 0);
	NSLogFont(aFont,@"Hw-Buffer      : %f\n", nBuffer);
    NSLogFont(aFont,@"Buffer overflow: %@\n", (overflowDetected) ? @"YES" : @"NO");
    //NSLogFont(aFont,@"Buffer overflow: %d\n", overflowDetectedCounter);
	NSLogFont(aFont,@"Missing events : %d\n", nMissingEvents);
	NSLogFont(aFont,@"Skipped events : %d\n", nSkippedEvents);
    NSLogFont(aFont,@"Maximal rate   : %d\n", 0);
}

#pragma mark ¥¥¥HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}

- (int) numberOfChannels
{
    return kNumFLTChannels;
}

/** Here all attributes are defined which are accessible via the hardware wizard.
 */ //-tb-
- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:1200 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gain"];
    [p setFormat:@"##0" upperLimit:255 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setGain:withValue:) getMethod:@selector(gain:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];  //TODO: needs to be tested -tb- 2008-02-26
    [p setName:@"(Exponent of) Shaping Time"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setShapingTime:withValue:) getMethod:@selector(shapingTime:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setTriggerEnabled:withValue:) getMethod:@selector(triggerEnabled:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"HitRate Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setHitRateEnabled:withValue:) getMethod:@selector(hitRateEnabled:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Check Waveform"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setCheckWaveFormEnabled:) getMethod:@selector(checkWaveFormEnabled)];
    [a addObject:p];
    
    //TODO:  add the same for setCheckEnergyEnabled -tb-
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init Board (low level)"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease]; //-tb-
    [p setName:@"Readout Pages"];
    [p setFormat:@"##0" upperLimit:64 lowerLimit:1 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setReadoutPages:) getMethod:@selector(readoutPages)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease]; //-tb-
    [p setName:@"PostTriggerTime"];
    [p setFormat:@"##0" upperLimit:65535 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setPostTriggerTime:) getMethod:@selector(postTriggerTime)];
    [a addObject:p];
	
    //histogramming parameters -tb-
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Histo: EnergyOffset (E_Min)"];
    [p setFormat:@"##0" upperLimit:65535 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setHistoMinEnergy:) getMethod:@selector(histoMinEnergy)];
    //[p setSetMethodSelector:@selector(setHistoMinEnergy:) ]; 
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Histo: Bin size"];
    [p setFormat:@"##0" upperLimit:15 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setHistoBinWidth:) getMethod:@selector(histoBinWidth)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Histo: Refresh time"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setHistoRunTime:) getMethod:@selector(histoRunTime)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Histo: Set Standard"];
    [p setSetMethodSelector:@selector(histoSetStandard)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORKatrinCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"ORKatrinFLTModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORKatrinFLTModel"]];
    return a;
	
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Threshold"]){
        return  [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    }
    else if([param isEqualToString:@"Gain"]){
		return [[cardDictionary objectForKey:@"gains"] objectAtIndex:aChannel];
	}
    else if([param isEqualToString:@"TriggerEnabled"]){
		return [[cardDictionary objectForKey:@"triggersEnabled"] objectAtIndex:aChannel];
	}
    else if([param isEqualToString:@"HitRateEnabled"]){
		return [[cardDictionary objectForKey:@"hitRatesEnabled"] objectAtIndex:aChannel];
	}
    else if([param isEqualToString:@"ShapingTime"]){
		return [[cardDictionary objectForKey:@"shapingTimes"] objectAtIndex:aChannel];
	}
    else return nil;
}

- (BOOL) partOfEvent:(unsigned short)aChannel
{
	//included to satisfy the protocal... change if needed
	return NO;
}

//for adcProvidingProtocol... but not used for now
- (uint32_t) eventCount:(int)channel
{
	return 0;
}
- (void) clearEventCounts
{
}
- (uint32_t) thresholdForDisplay:(unsigned short) aChan
{
	return [self threshold:aChan];
}
- (unsigned short) gainForDisplay:(unsigned short) aChan
{
	return [self gain:aChan];
}
@end

@implementation ORKatrinFLTModel (tests)
#pragma mark ¥¥¥Accessors
- (BOOL) testsRunning
{
    return testsRunning;
}

- (void) setTestsRunning:(BOOL)aTestsRunning
{
    testsRunning = aTestsRunning;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestsRunningChanged object:self];
}

- (NSMutableArray*) testEnabledArray
{
    return testEnabledArray;
}

- (void) setTestEnabledArray:(NSMutableArray*)aTestEnabledArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestEnabledArray:testEnabledArray];
    
    [aTestEnabledArray retain];
    [testEnabledArray release];
    testEnabledArray = aTestEnabledArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestEnabledArrayChanged object:self];
}

- (NSMutableArray*) testStatusArray
{
    return testStatusArray;
}

- (void) setTestStatusArray:(NSMutableArray*)aTestStatusArray
{
    [aTestStatusArray retain];
    [testStatusArray release];
    testStatusArray = aTestStatusArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestStatusArrayChanged object:self];
}

- (NSString*) testStatus:(int)index
{
	if(index<[testStatusArray count])return [testStatusArray objectAtIndex:index];
	else return @"---";
}

- (BOOL) testEnabled:(int)index
{
	if(index<[testEnabledArray count])return [[testEnabledArray objectAtIndex:index] boolValue];
	else return NO;
}

- (void) runTests
{
	if(!testsRunning){
		@try {
			[self setTestsRunning:YES];
			NSLog(@"Starting tests for FLT station %d\n",[self stationNumber]);
			
			//clear the status text array
			int i;
			for(i=0;i<kNumKatrinFLTTests;i++){
				[testStatusArray replaceObjectAtIndex:i withObject:@"--"];
			}
			
			//create the test suit
			if(testSuit)[testSuit release];
			testSuit = [[ORTestSuit alloc] init];
			if([self testEnabled:0]) [testSuit addTest:[ORTest testSelector:@selector(modeTest) tag:0]];
			if([self testEnabled:1]) [testSuit addTest:[ORTest testSelector:@selector(ramTest) tag:1]];
			if([self testEnabled:2]) [testSuit addTest:[ORTest testSelector:@selector(patternWriteTest) tag:2]];
			if([self testEnabled:3]) [testSuit addTest:[ORTest testSelector:@selector(broadcastTest) tag:3]];
			if([self testEnabled:4]) [testSuit addTest:[ORTest testSelector:@selector(thresholdGainTest) tag:4]];
			if([self testEnabled:5]) [testSuit addTest:[ORTest testSelector:@selector(speedTest) tag:5]];
			if([self testEnabled:6]) [testSuit addTest:[ORTest testSelector:@selector(eventTest) tag:6]];
			
			[testSuit runForObject:self];
		}
		@catch(NSException* localException) {
		}
	}
	else {
		NSLog(@"Tests for FLT (station: %d) stopped manually\n",[self stationNumber]);
		[testSuit stopForObject:self];
	}
}

- (void) runningTest:(int)aTag status:(NSString*)theStatus
{
	[testStatusArray replaceObjectAtIndex:aTag withObject:theStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinFLTModelTestStatusArrayChanged object:self];
}


#pragma mark ¥¥¥Tests
- (void) modeTest
{
	int testNumber = 0;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	savedMode = fltRunMode;
	@try {
		BOOL passed = YES;
		int i;
		for(i=0;i<4;i++){
			[self writeMode:i];
			if([self readMode] != i){
				[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
				passed = NO;
				break;
			}
			if(passed){
				[self writeMode:savedMode];
				if([self readMode] != savedMode){
					[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
					passed = NO;
				}
			}
		}
		if(passed){
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}
	
	[testSuit runForObject:self]; //do next test
}


- (void) ramTest
{
	int testNumber = 1;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	unsigned short pat1[kKatrinFlt_Page_Size],buf[kKatrinFlt_Page_Size];
	int i,chan;
	for(i=0;i<kKatrinFlt_Page_Size;i++)pat1[i]=i;
	
	@try {
		[self enterTestMode];
		int aPage;
		// broadcast the test pattern to all channels + pages
		for(aPage=0;aPage<32;aPage++){
			[self broadcast:aPage dataBuffer:pat1];
		}
		
		int n_error = 0;
		for (chan=startChan;chan<=endChan;chan++) {
			for(aPage=0;aPage<32;aPage++) {
				[self readMemoryChan:chan page:aPage pageBuffer:buf];
				
				if ([self compareData:buf pattern:pat1 shift:0 n:kKatrinFlt_Page_Size] != kKatrinFlt_Page_Size) n_error++;
			}
		}
		if(n_error != 0){
			[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
			NSLog(@"Errors in %d pages found\n",n_error);
		}
		else {
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
		
		[self leaveTestMode];
		
		
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
	
}

- (void) patternWriteTest
{
	int testNumber = 2;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	unsigned short pat1[kKatrinFlt_Page_Size],buf[kKatrinFlt_Page_Size];
	
	@try {
		[self enterTestMode];
		BOOL passed = YES;
		uint32_t patterns[4] = {0x1010,0x0101,0x1111,0x0000};
		int i,patternIndex;
		for(patternIndex=0;patternIndex<4;patternIndex++){
			for(i=0;i<kKatrinFlt_Page_Size;i++)pat1[i] = patterns[patternIndex];
			[self clear:startChan page:page value:patterns[patternIndex]];
			[self readMemoryChan:startChan page:page pageBuffer:buf];
			if ([self compareData:buf pattern:pat1 shift:0 n:kKatrinFlt_Page_Size] != kKatrinFlt_Page_Size){
				[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
				NSLog(@"Error: pattern set (0x%0x) for FLT %d chan %d, page %d does not work\n", patterns[i],[self stationNumber],startChan, page);
				passed = NO;
				break;
			}
		}
		
		if(passed) {
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
		
		[self leaveTestMode];
		
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
	
}

- (void) broadcastTest
{
	int testNumber = 3;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	unsigned short pat1[kKatrinFlt_Page_Size],buf[kKatrinFlt_Page_Size];
	
	@try {
		[self enterTestMode];
		uint32_t pattern = 0x1010;
		int i,chan;
		int thePage = 15; //test page
		BOOL passed = YES;
		for(i=0;i<kKatrinFlt_Page_Size;i++)pat1[i] = pattern;
		for(chan=startChan;chan<=endChan;chan++){
			[self broadcast:thePage dataBuffer:pat1];
			[self readMemoryChan:chan page:thePage pageBuffer:buf];
			if ([self compareData:buf pattern:pat1 shift:0 n:kKatrinFlt_Page_Size] != kKatrinFlt_Page_Size){
				[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
				NSLog(@"Error: broadcast (pattern: 0x%0x) FLT %d chan %d, page %d does not work\n",pattern,[self stationNumber],startChan, thePage);
				passed = NO;
			}
		}
		if(passed) {
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
		
		[self leaveTestMode];
		
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
	
}

- (void) thresholdGainTest
{
	int testNumber = 4;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	@try {
		[self enterTestMode];
		uint32_t aPattern[4] = {0x3fff,0x0,0x2aaa,0x1555};
		int chan;
		BOOL passed = YES;
		int testIndex;
		//thresholds first
		for(testIndex = 0;testIndex<4;testIndex++){
			unsigned short thePattern = aPattern[testIndex];
			for(chan=0;chan<kNumFLTChannels;chan++){
				[self writeThreshold:chan value:thePattern];
			}
			
			for(chan=0;chan<kNumFLTChannels;chan++){
				if([self readThreshold:chan] != thePattern){
					[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
					NSLog(@"Error: Threshold (pattern: 0x%0x) FLT %d chan %d does not work\n",thePattern,[self stationNumber],chan);
					passed = NO;
					break;
				}
			}
		}
		if(passed){		
			uint32_t gainPattern[4] = {0xff,0x0,0xaa,0x55};
			
			//now gains
			for(testIndex = 0;testIndex<4;testIndex++){
				unsigned short thePattern = gainPattern[testIndex];
				for(chan=0;chan<kNumFLTChannels;chan++){
					[self writeGain:chan value:thePattern];
				}
				
				for(chan=0;chan<kNumFLTChannels;chan++){
					if([self readGain:chan] != thePattern){
						[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
						NSLog(@"Error: Gain (pattern: 0x%0x) FLT %d chan %d does not work\n",thePattern,[self stationNumber],chan);
						passed = NO;
						break;
					}
				}
			}
		}
		if(passed) {
			[self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		}
		
		[self loadThresholdsAndGains];
		
		[self leaveTestMode];
		
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
	
}


- (void) speedTest
{
	int testNumber = 5;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	unsigned short buf[kKatrinFlt_Page_Size];
	ORTimer* timer = [[ORTimer alloc] init];
	[timer reset];
	
	@try {
		[self enterTestMode];		
		[timer start];
		[self readMemoryChan:startChan page:page pageBuffer:buf];
		[timer stop];
		NSLog(@"FLT %d page readout: %.2f sec\n",[self stationNumber],[timer seconds]);
		int i;
		[timer start];
		for(i=0;i<10000;i++){
			[self readMemoryChan:1 page:15];
		}
		[timer stop];
		NSLog(@"FLT %d single memory address readout: %.2f ms\n",[self stationNumber],[timer seconds]/10.);
		
		
		[self runningTest:testNumber status:@"See StatusLog"];
		
		[self leaveTestMode];
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
		
	}		
	[timer release];
	
	[testSuit runForObject:self]; //do next test
	
}

- (void) eventTest
{
	int testNumber = 6;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	@try {
		//cache some addresses.
		uint32_t theSlotPart = [self slot]<<24;
		statusAddress		= theSlotPart;
		triggerMemAddress	= theSlotPart | (kFLTTriggerDataCode << kKatrinFlt_AddressSpace); 
		memoryAddress		= theSlotPart | (kFLTAdcDataCode << kKatrinFlt_AddressSpace); 
		
		//clear the pointers, put in run mode
		uint32_t aValue = (fltRunMode<<20) | 0x1;
		[self writeControlStatus:aValue];
		[ORTimer delay:1];
		//put into test mode
		savedMode = fltRunMode;
		[self writeMode:kKatrinFlt_Test_Mode];
		if([self readMode] != kKatrinFlt_Test_Mode){
			NSLogColor([NSColor redColor],@"Could not put FLT %d into test mode\n",[self stationNumber]);
			[NSException raise:@"Ram Test Failed" format:@"Could not put FLT %d into test mode\n",(int)[self stationNumber]];
		}
		
		//[[[self crate] adapter] hw_configure];		
		[[[self crate] adapter] hw_config];
		
		
		//[[[self crate] adapter] runIsAboutToStart:nil];
		
		
		NSLog(@"FLT %d\n",[self stationNumber]);
		uint32_t statusWord = [self readControlStatus];	
		//there is some data, so get the read and write pointers
		int page0 = statusWord & 0x1ff;	//read page
		page0 = (page0 + 1) % 512;				
		int page1 = (statusWord >> 11) & 0x1ff;	//write page
		
		if(page0 != page1){
			
			NSLog(@"---Event Data---\n");
			
			uint32_t pageAddress = triggerMemAddress + (page0<<2);	
			
			//read the event from the trigger memory and format into an event structure
			katrinEventDataStruct theEvent;
			uint32_t data	= [self read:pageAddress | 0x0];
			uint32_t channelMap = (data >> 10)  & 0x3fffff;
			theEvent.eventID	= data & 0x3fff;
			theEvent.subSec		= [self read:pageAddress | 0x1];
			theEvent.sec		= [self read:pageAddress | 0x2];
			
			//the event energy address is computed from the subSec part of the trigger data
			uint32_t energyAddress = memoryAddress | (theEvent.subSec % 65536);
			if (energyAddress % 2 == 0 ) {  // even address
				theEvent.energy	= [self read:energyAddress] & 0x7fff;			//15bits??
			}
			else {
				theEvent.energy	= ([self read:energyAddress-1]>>16) & 0x7fff;	//15bits??
			}			
			
			NSDate* theDate = [NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)theEvent.sec];
			
			NSLog(@"ChannelMap: 0x%0x\n",channelMap);
			NSLog(@"EventID   : 0x%0x\n",theEvent.eventID);
			NSLog(@"Time      : %@.%d\n",theDate,theEvent.subSec);
			NSLog(@"Energy    : %d\n",theEvent.energy);
			
		}
		else NSLog(@"No Data\n");
		
		//[[[self crate] adapter] runIsStopped:nil];
		
		
		[self runningTest:testNumber status:@"See StatusLog"];
		
		[self setFltRunMode:savedMode];
		[self writeMode:savedMode];
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
		
	}		
	
	[testSuit runForObject:self]; //do next test
	
}




- (int) compareData:(unsigned short*) data
			pattern:(unsigned short*) pattern
			  shift:(int) shift
				  n:(int) n 
{
	unsigned int i, j;
	
	// Check for errors
	for (i=0;i<n;i++) {
		if (data[i]!=pattern[(i+shift)%n]) {
			for (j=(i/4);(j<i/4+3) && (j < n/4);j++){
				NSLog(@"%04x: %04x %04x %04x %04x - %04x %04x %04x %04x \n",j*4,
					  data[j*4],data[j*4+1],data[j*4+2],data[j*4+3],
					  pattern[(j*4+shift)%n],  pattern[(j*4+1+shift)%n],
					  pattern[(j*4+2+shift)%n],pattern[(j*4+3+shift)%n]  );
                if(i==0)return i;
                // check only for one error in every page!
                //(the == check prevents an XCode 9.4 warning that loop executes only once
			}
		}
	}
	
	return n;
}

@end

@implementation ORKatrinFLTModel (private)

- (void) checkWaveform:(short*)waveFormPtr
{
	// Check the ADC traces
	// Is the trigger flag in the right place - there should be not more
	// than one trigger flag!
	// ak 24.7.07									
	int nTrigger = 0;
	int j;
	for (j=0;j<readoutPages*1024;j++){
		if (waveFormPtr[j] >> 15) nTrigger += 1;
	}
	if (nTrigger>1){
		NSLogError(@"",@"Katrin FLT Card Error",[NSString stringWithFormat:@"Card%d",(int)[self stationNumber]],@"Too many triggers",nil);
		//NSLog(@"Event %d: Too many trigger flags in waveform (n=%d)\n", nEvents, nTrigger); // DEBUG: comment out -tb-
	}
	
	nTrigger = 0;
	//for (j=(readoutPages-1)*1024+500;j<(readoutPages-1)*1024+550;j++){
    int start,end;
    start=(readoutPages)*1024-postTriggerTime-10;
    end=(readoutPages)*1024-postTriggerTime+40;
    //NSLog(@"Searching trigger between %i and %i\n",start,end);
    if(start<0) start = 0;// raw error check -tb-
    if(end<0){
		NSLogError(@"",@"Katrin FLT Card Error",[NSString stringWithFormat:@"Card%d",(int)[self stationNumber]],@"Trigger flag region out of ADC trace",nil);
        return; //cannot check -tb-
    }
	for (j=start;j<end;j++){ //-tb-
		if (waveFormPtr[j] >> 15) nTrigger += 1;
	}
	if (nTrigger == 0){
		NSLogError(@"",@"Katrin FLT Card Error",[NSString stringWithFormat:@"Card%d",(int)[self stationNumber]],@"Trigger flag in wrong place",nil);
		//NSLog(@"Event %d: Trigger flag not found in right place\n", nEvents, nTrigger);								
	}																
}

- (NSAttributedString*) test:(int)testIndex result:(NSString*)result color:(NSColor*)aColor
{
	NSLogColor(aColor,@"%@ test %@\n",fltTestName[testIndex],result);
	id theString = [[NSAttributedString alloc] initWithString:result 
												   attributes:[NSDictionary dictionaryWithObject: aColor forKey:NSForegroundColorAttributeName]];
	
	[self runningTest:testIndex status:theString];
	return [theString autorelease];
}

- (void) enterTestMode
{
	//put into test mode
	savedMode = fltRunMode;
	[self writeMode:kKatrinFlt_Test_Mode];
	if([self readMode] != kKatrinFlt_Test_Mode){
		NSLogColor([NSColor redColor],@"Could not put FLT %d into test mode\n",[self stationNumber]);
		[NSException raise:@"Ram Test Failed" format:@"Could not put FLT %d into test mode\n",(int)[self stationNumber]];
	}
}

- (void) leaveTestMode
{
	[self writeMode:savedMode];
}
@end


