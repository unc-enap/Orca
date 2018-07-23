//
//  OREdelweissFLTModel.m
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

#import "OREdelweissFLTModel.h"
//#import "ORIpeV4SLTModel.h"
#import "OREdelweissSLTModel.h"
#import "ORIpeCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORDataTypeAssigner.h"
#import "ORTimeRate.h"
#import "ORTest.h"
#import "SBC_Config.h"
#import "EdelweissSLTv4_HW_Definitions.h"
#import "ORCommandList.h"

#import "ORSNMP.h"


#import "ipe4structure.h"
#import "ipe4tbtools.h"

//#import "ipe4tbtools.cpp"

NSString* OREdelweissFLTModelSaveIonChanFilterOutputRecordsChanged = @"OREdelweissFLTModelSaveIonChanFilterOutputRecordsChanged";
NSString* OREdelweissFLTModelRepeatSWTriggerDelayChanged = @"OREdelweissFLTModelRepeatSWTriggerDelayChanged";
NSString* OREdelweissFLTModelHitrateLimitIonChanged = @"OREdelweissFLTModelHitrateLimitIonChanged";
NSString* OREdelweissFLTModelHitrateLimitHeatChanged = @"OREdelweissFLTModelHitrateLimitHeatChanged";
NSString* OREdelweissFLTModelChargeFICFileChanged = @"OREdelweissFLTModelChargeFICFileChanged";
NSString* OREdelweissFLTModelProgressOfChargeFICChanged = @"OREdelweissFLTModelProgressOfChargeFICChanged";
NSString* OREdelweissFLTModelFicCardTriggerCmdChanged = @"OREdelweissFLTModelFicCardTriggerCmdChanged";
NSString* OREdelweissFLTModelFicCardADC23CtrlRegChanged = @"OREdelweissFLTModelFicCardADC23CtrlRegChanged";
NSString* OREdelweissFLTModelFicCardADC01CtrlRegChanged = @"OREdelweissFLTModelFicCardADC01CtrlRegChanged";
NSString* OREdelweissFLTModelFicCardCtrlReg2Changed = @"OREdelweissFLTModelFicCardCtrlReg2Changed";
NSString* OREdelweissFLTModelFicCardCtrlReg1Changed = @"OREdelweissFLTModelFicCardCtrlReg1Changed";
NSString* OREdelweissFLTModelPollBBStatusIntervallChanged = @"OREdelweissFLTModelPollBBStatusIntervallChanged";
NSString* OREdelweissFLTModelProgressOfChargeBBChanged = @"OREdelweissFLTModelProgressOfChargeBBChanged";
NSString* OREdelweissFLTModelChargeBBFileForFiberChanged = @"OREdelweissFLTModelChargeBBFileForFiberChanged";
NSString* OREdelweissFLTModelBB0x0ACmdMaskChanged = @"OREdelweissFLTModelBB0x0ACmdMaskChanged";
NSString* OREdelweissFLTModelChargeBBFileChanged = @"OREdelweissFLTModelChargeBBFileChanged";
NSString* OREdelweissFLTModelIonToHeatDelayChanged = @"OREdelweissFLTModelIonToHeatDelayChanged";
NSString* OREdelweissFLTModelHeatTriggerMaskChanged = @"OREdelweissFLTModelHeatTriggerMaskChanged";
NSString* OREdelweissFLTModelIonTriggerMaskChanged = @"OREdelweissFLTModelIonTriggerMaskChanged";
NSString* OREdelweissFLTModelTriggerParameterChanged = @"OREdelweissFLTModelTriggerParameterChanged";
NSString* OREdelweissFLTModelTriggerEnabledMaskChanged = @"OREdelweissFLTModelTriggerEnabledMaskChanged";
NSString* OREdelweissFLTModelLowLevelRegInHexChanged = @"OREdelweissFLTModelLowLevelRegInHexChanged";
NSString* OREdelweissFLTModelWriteToBBModeChanged = @"OREdelweissFLTModelWriteToBBModeChanged";
NSString* OREdelweissFLTModelWCmdArg2Changed = @"OREdelweissFLTModelWCmdArg2Changed";
NSString* OREdelweissFLTModelWCmdArg1Changed = @"OREdelweissFLTModelWCmdArg1Changed";
NSString* OREdelweissFLTModelWCmdCodeChanged = @"OREdelweissFLTModelWCmdCodeChanged";
NSString* OREdelweissFLTModelAdcRtChanged = @"OREdelweissFLTModelAdcRtChanged";
NSString* OREdelweissFLTModelD2Changed = @"OREdelweissFLTModelD2Changed";
NSString* OREdelweissFLTModelD3Changed = @"OREdelweissFLTModelD3Changed";
NSString* OREdelweissFLTModelDacbChanged = @"OREdelweissFLTModelDacbChanged";
NSString* OREdelweissFLTModelSignbChanged = @"OREdelweissFLTModelSignbChanged";
NSString* OREdelweissFLTModelDacaChanged = @"OREdelweissFLTModelDacaChanged";
NSString* OREdelweissFLTModelSignaChanged = @"OREdelweissFLTModelSignaChanged";
NSString* OREdelweissFLTModelStatusBitsBBDataChanged = @"OREdelweissFLTModelStatusBitsBBDataChanged";
NSString* OREdelweissFLTModelAdcRtForBBAccessChanged = @"OREdelweissFLTModelAdcRtForBBAccessChanged";
NSString* OREdelweissFLTModelAdcRgForBBAccessChanged = @"OREdelweissFLTModelAdcRgForBBAccessChanged";
NSString* OREdelweissFLTModelAdcValueForBBAccessChanged = @"OREdelweissFLTModelAdcValueForBBAccessChanged";
NSString* OREdelweissFLTModelPolarDacChanged = @"OREdelweissFLTModelPolarDacChanged";
NSString* OREdelweissFLTModelTriDacChanged = @"OREdelweissFLTModelTriDacChanged";
NSString* OREdelweissFLTModelRectDacChanged = @"OREdelweissFLTModelRectDacChanged";
NSString* OREdelweissFLTModelAdcMultForBBAccessChanged = @"OREdelweissFLTModelAdcMultForBBAccessChanged";
NSString* OREdelweissFLTModelAdcFreqkHzForBBAccessChanged = @"OREdelweissFLTModelAdcFreqkHzForBBAccessChanged";
NSString* OREdelweissFLTFiber = @"OREdelweissFLTFiber";
NSString* OREdelweissFLTIndex = @"OREdelweissFLTIndex";
NSString* OREdelweissFLTModelUseBroadcastIdforBBAccessChanged = @"OREdelweissFLTModelUseBroadcastIdforBBAccessChanged";
NSString* OREdelweissFLTModelIdBBforBBAccessChanged = @"OREdelweissFLTModelIdBBforBBAccessChanged";
NSString* OREdelweissFLTModelFiberSelectForBBAccessChanged = @"OREdelweissFLTModelFiberSelectForBBAccessChanged";
NSString* OREdelweissFLTModelRelaisStatesBBChanged = @"OREdelweissFLTModelRelaisStatesBBChanged";
NSString* OREdelweissFLTModelFiberSelectForBBStatusBitsChanged = @"OREdelweissFLTModelFiberSelectForBBStatusBitsChanged";
NSString* OREdelweissFLTModelFiberOutMaskChanged = @"OREdelweissFLTModelFiberOutMaskChanged";
NSString* OREdelweissFLTModelTpixChanged = @"OREdelweissFLTModelTpixChanged";
NSString* OREdelweissFLTModelSwTriggerIsRepeatingChanged = @"OREdelweissFLTModelSwTriggerIsRepeatingChanged";
NSString* OREdelweissFLTModelRepeatSWTriggerModeChanged = @"OREdelweissFLTModelRepeatSWTriggerModeChanged";
NSString* OREdelweissFLTModelControlRegisterChanged = @"OREdelweissFLTModelControlRegisterChanged";
NSString* OREdelweissFLTModelTotalTriggerNRegisterChanged = @"OREdelweissFLTModelTotalTriggerNRegisterChanged";
NSString* OREdelweissFLTModelStatusRegisterChanged = @"OREdelweissFLTModelStatusRegisterChanged";
NSString* OREdelweissFLTModelFastWriteChanged = @"OREdelweissFLTModelFastWriteChanged";
NSString* OREdelweissFLTModelFiberDelaysChanged = @"OREdelweissFLTModelFiberDelaysChanged";
NSString* OREdelweissFLTModelStreamMaskChanged = @"OREdelweissFLTModelStreamMaskChanged";
NSString* OREdelweissFLTModelSelectFiberTrigChanged = @"OREdelweissFLTModelSelectFiberTrigChanged";
NSString* OREdelweissFLTModelBBv1MaskChanged = @"OREdelweissFLTModelBBv1MaskChanged";
NSString* OREdelweissFLTModelFiberEnableMaskChanged = @"OREdelweissFLTModelFiberEnableMaskChanged";
NSString* OREdelweissFLTModelFltModeFlagsChanged = @"OREdelweissFLTModelFltModeFlagsChanged";
NSString* OREdelweissFLTModelTargetRateChanged			= @"OREdelweissFLTModelTargetRateChanged";
NSString* OREdelweissFLTModelStoreDataInRamChanged		= @"OREdelweissFLTModelStoreDataInRamChanged";
NSString* OREdelweissFLTModelFilterLengthChanged		= @"OREdelweissFLTModelFilterLengthChanged";
NSString* OREdelweissFLTModelGapLengthChanged			= @"OREdelweissFLTModelGapLengthChanged";
NSString* OREdelweissFLTModelPostTriggerTimeChanged		= @"OREdelweissFLTModelPostTriggerTimeChanged";
NSString* OREdelweissFLTModelFifoBehaviourChanged		= @"OREdelweissFLTModelFifoBehaviourChanged";
NSString* OREdelweissFLTModelAnalogOffsetChanged		= @"OREdelweissFLTModelAnalogOffsetChanged";
NSString* OREdelweissFLTModelLedOffChanged				= @"OREdelweissFLTModelLedOffChanged";
NSString* OREdelweissFLTModelInterruptMaskChanged		= @"OREdelweissFLTModelInterruptMaskChanged";
NSString* OREdelweissFLTModelTModeChanged				= @"OREdelweissFLTModelTModeChanged";
NSString* OREdelweissFLTModelHitRateLengthChanged		= @"OREdelweissFLTModelHitRateLengthChanged";
NSString* OREdelweissFLTModelHitRateEnabledMaskChanged	= @"OREdelweissFLTModelHitRateEnabledMaskChanged";
NSString* OREdelweissFLTModelTriggersEnabledChanged		= @"OREdelweissFLTModelTriggersEnabledChanged";
NSString* OREdelweissFLTModelGainsChanged				= @"OREdelweissFLTModelGainsChanged";
NSString* OREdelweissFLTModelThresholdsChanged			= @"OREdelweissFLTModelThresholdsChanged";
NSString* OREdelweissFLTModelModeChanged				= @"OREdelweissFLTModelModeChanged";
NSString* OREdelweissFLTSettingsLock					= @"OREdelweissFLTSettingsLock";
NSString* OREdelweissFLTChan							= @"OREdelweissFLTChan";
NSString* OREdelweissFLTModelTestPatternsChanged		= @"OREdelweissFLTModelTestPatternsChanged";
NSString* OREdelweissFLTModelGainChanged				= @"OREdelweissFLTModelGainChanged";
NSString* OREdelweissFLTModelThresholdChanged			= @"OREdelweissFLTModelThresholdChanged";
NSString* OREdelweissFLTModelHitRateChanged				= @"OREdelweissFLTModelHitRateChanged";
NSString* OREdelweissFLTModelTestsRunningChanged		= @"OREdelweissFLTModelTestsRunningChanged";
NSString* OREdelweissFLTModelTestEnabledArrayChanged	= @"OREdelweissFLTModelTestEnabledChanged";
NSString* OREdelweissFLTModelTestStatusArrayChanged		= @"OREdelweissFLTModelTestStatusChanged";
NSString* OREdelweissFLTModelEventMaskChanged			= @"OREdelweissFLTModelEventMaskChanged";

NSString* OREdelweissFLTSelectedRegIndexChanged			= @"OREdelweissFLTSelectedRegIndexChanged";
NSString* OREdelweissFLTWriteValueChanged				= @"OREdelweissFLTWriteValueChanged";
NSString* OREdelweissFLTSelectedChannelValueChanged		= @"OREdelweissFLTSelectedChannelValueChanged";
NSString* OREdelweissFLTNoiseFloorChanged				= @"OREdelweissFLTNoiseFloorChanged";
NSString* OREdelweissFLTNoiseFloorOffsetChanged			= @"OREdelweissFLTNoiseFloorOffsetChanged";

static NSString* fltTestName[kNumEdelweissFLTTests]= {
	@"Run Mode",
	@"Ram",
	@"Threshold/Gain",
	@"Speed",
	@"Event",
};

// data for low-level page (IPE V4 electronic definitions)
enum IpeFLTV4Enum{
	kFLTV4StatusReg,
	kFLTV4ControlReg,
	kFLTV4CommandReg,
	kFLTV4VersionReg,
//HEAT	kFLTV4pVersionReg,
//	kFLTV4BoardIDLsbReg,
//	kFLTV4BoardIDMsbReg,
	kFLTV4RunControlReg,
	kFLTV4ThreshAdjustReg,
	kFLTV4FiberOutMaskReg,
	kFLTV4InterruptMaskReg,
	kFLTV4InterruptRequestReg,
	/*kFLTV4HrMeasEnableReg,
	kFLTV4EventFifoStatusReg,
	kFLTV4PixelSettings1Reg,
	kFLTV4PixelSettings2Reg,
	kFLTV4RunControlReg,*/
	kFLTV4FiberSet_1Reg,
	kFLTV4FiberSet_2Reg,   
	kFLTV4StreamMask_1Reg,
	kFLTV4StreamMask_2Reg,
	kFLTV4IonTriggerMask_1Reg,
	kFLTV4IonTriggerMask_2Reg,
//	kFLTV4HistgrSettingsReg,
	kFLTV4Ion2HeatDelayReg,
	kFLTV4AccessTestReg,
//	kFLTV4SecondCounterReg,
    /*
	kFLTV4HrControlReg,
	kFLTV4HistMeasTimeReg,
	kFLTV4HistRecTimeReg,
	kFLTV4HistNumMeasReg,
	kFLTV4PostTrigger,
	*/
	kFLTV4HeatTriggerMask_1Reg,     	
	kFLTV4HeatTriggerMask_2Reg,   	
	kFLTV4HeatTriggParReg, 	
	kFLTV4IonTriggParReg,		
		
	kFLTV4HeatThresholdsReg,
	kFLTV4IonThresholdsReg,
	//kFLTV4ThresholdReg,

	kFLTV4TriggChannelsReg,
	kFLTV4ReadPageNumReg,
	kFLTV4TriggEnergyReg,
	kFLTV4TotalTriggerNReg,

	kFLTV4Delays120meas,

	kFLTV4HitRateReg,
	
	kFLTV4BBStatusReg,
	
	kFLTV4RAMDataReg,
    
	kFLTV4NumRegs //must be last
};

static IpeRegisterNamesStruct regV4[kFLTV4NumRegs] = {
	//2nd column is PCI register address shifted 2 bits to right (the two rightmost bits are always zero) -tb-
	{@"Status",				0x000000>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"Control",			0x000004>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"Command",			0x000008>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"CFPGAVersion",		0x00000c>>2,		-1,				kIpeRegReadable},
//HEAT	{@"FPGA8Version",		0x000010>>2,		-1,				kIpeRegReadable},
//	{@"BoardIDLSB",         0x000014>>2,		-1,				kIpeRegReadable},
//	{@"BoardIDMSB",         0x000018>>2,		-1,				kIpeRegReadable},
	{@"RunControl",         0x000010>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"ThreshAdjust",       0x000014>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"FiberOutMask",       0x000018>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},

	{@"InterruptMask",      0x00001C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"InterruptRequest",   0x000020>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	/*
	{@"HrMeasEnable",       0x000024>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"EventFifoStatus",    0x00002C>>2,		-1,				kIpeRegReadable},
	{@"PixelSettings1",     0x000030>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"PixelSettings2",     0x000034>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"RunControl",         0x000038>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	*/
	{@"FiberSet_1",			0x000024>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"FiberSet_2",         0x000028>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"StreamMask_1",		0x00002C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"StreamMask_2",		0x000030>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"IonTriggerMask_1",	0x000034>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"IonTriggerMask_2",   0x000038>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	
	//{@"HistgrSettings",     0x00003c>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"Ion2HeatDelay",      0x00003c>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"AccessTest",         0x000040>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},

//	{@"SecondCounter",      0x000044>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
    /*
	{@"HrControl",          0x000048>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HistMeasTime",       0x00004C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HistRecTime",        0x000050>>2,		-1,				kIpeRegReadable},
	{@"HistNumMeas",         0x000054>>2,		-1,				kIpeRegReadable},
	{@"PostTrigger",		0x000058>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	*/
	{@"HeatTriggerMask_1",  0x000048>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HeatTriggerMask_2",  0x00004C>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"HeatTriggPar",       0x000050>>2,		 6,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},
	{@"IonTriggPar",		0x000054>>2,		12,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},

	{@"HeatThresholds",     0x000058>>2,		 6,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},
	{@"IonThresholds",      0x00005C>>2,		12,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},
	//{@"Threshold",          0x002080>>2,		-1,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},
	
	{@"TriggerChannels",	0x000078>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},
	{@"ReadPageNum",     	0x00007c>>2,		16,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},
	{@"TriggerEnergy",  	0x000080>>2,		12,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},
	{@"TotalTriggerN",		0x000084>>2,		-1,				kIpeRegReadable | kIpeRegWriteable},

	{@"Delays120meas",		0x000088>>2,		-1,				kIpeRegReadable },

	{@"HitRate",		    0x001000>>2,		18,				kIpeRegReadable | kIpeRegNeedsChannel},

	{@"BBStatus",		    0x001400>>2,		30,				kIpeRegReadable | kIpeRegNeedsChannel},

	{@"RAMData",		    0x003000>>2,		1024,				kIpeRegReadable | kIpeRegWriteable | kIpeRegNeedsChannel},

};

@interface OREdelweissFLTModel (private)
- (NSAttributedString*) test:(int)testName result:(NSString*)string color:(NSColor*)aColor;
- (void) enterTestMode;
- (void) leaveTestMode;
- (void) stepNoiseFloor;
@end

@implementation OREdelweissFLTModel

- (id) init
{
    self = [super init];
	ledOff = YES;
   	if(!statusBitsBBData){
		[self setStatusBitsBBData: [NSMutableData dataWithLength: 4 * kNumEWFLTFibers * kNumBBStatusBufferLength32]];
	}

    int i;
	if(!thresholds){
		[self setThresholds: [NSMutableArray array]];
		for(i=0;i<kNumEWFLTHeatIonChannels;i++) [thresholds addObject:[NSNumber numberWithInt:50]];
	}
	if(!triggerParameter){
		[self setTriggerParameter: [NSMutableArray array]];
		for(i=0;i<kNumEWFLTHeatIonChannels;i++) [triggerParameter addObject:[NSNumber numberWithInt:0]];
	}
    
    repeatSWTriggerDelay = 1.0;//default

    [self registerNotificationObservers];

    return self;
}

- (void) dealloc
{	
    [chargeFICFile release];
    [chargeBBFileForFiber[0] release];//sorry, this is awfuel, but it was a quick hack -tb-
    [chargeBBFileForFiber[1] release]; 
    [chargeBBFileForFiber[2] release];
    [chargeBBFileForFiber[3] release];
    [chargeBBFileForFiber[4] release];
    [chargeBBFileForFiber[5] release];
    [chargeBBFile release];
    [statusBitsBBData release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [testEnabledArray release];
    [testStatusArray release];
	[testSuit release];
	[thresholds release];
	[triggerParameter release];
	[gains release];
	[totalRate release];
   	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"EdelweissFLTCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"OREdelweissFLTController"];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORIpeV4CrateModel");
}

- (BOOL) partOfEvent:(short)chan
{
	return (eventMask & (1L<<chan)) != 0;
}

- (int) stationNumber //counts FLT #: 1, 2, 3, ... (slot: 0, 1, ... SLT gap ... )
{
	//is it a minicrate?
	if([[[self crate] class]  isSubclassOfClass: NSClassFromString(@"ORIpeV4MiniCrateModel")]){
		if([self slot]<3)return [self slot]+1;
		else return [self slot]; //there is a gap at slot 3 (for the SLT) -tb-
	}
	//... or a full crate?
	if([[[self crate] class]  isSubclassOfClass: NSClassFromString(@"ORIpeV4CrateModel")]){
		if([self slot]<11)return [self slot]+1;
		else return [self slot]; //there is a gap at slot 11 (for the SLT) -tb-
	}
	//fallback
	return [self slot]+1;
}

- (ORTimeRate*) totalRate   { return totalRate; }
- (short) getNumberRegisters{ return kFLTV4NumRegs; }





#pragma mark •••Notifications
- (void) registerNotificationObservers
{

    return; //currently unused -tb-
    
//
//
//
//    //NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
//
//    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
//     [notifyCenter removeObserver:self]; //guard against a double register
//
//    //[super registerNotificationObservers]; ORIpeV4FLTModel does not implement it ... -tb-
//
//    [notifyCenter addObserver : self
//                     selector : @selector(runIsAboutToStart:)
//                         name : ORRunAboutToStartNotification
//                       object : nil];
//
//    #if 0
//    [notifyCenter addObserver : self
//                     selector : @selector(XXXXsettingsLockChanged:)
//                         name : ORRunStatusChangedNotification
//                       object : nil];
//
//    [notifyCenter addObserver : self
//                     selector : @selector(runIsAboutToStop:)
//                         name : ORRunAboutToStopNotification
//                       object : nil];
//
//    [notifyCenter addObserver : self
//                     selector : @selector(runIsAboutToChangeState:)
//                         name : ORRunAboutToChangeState
//                       object : nil];
//    #endif
    
}

#if 0
//#define SHOW_RUN_NOTIFICATIONS_AND_CALLS 1
- (void) runIsAboutToStop:(NSNotification*)aNote
{
    #if SHOW_RUN_NOTIFICATIONS_AND_CALLS
        //DEBUG
                 NSLog(@"%@::%@   --- FLT #%i<---------N\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self stationNumber]);//DEBUG -tb-
    #endif
    //NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    //reset the 'sync with subruns' facility (should not be necessary without 'sending  eRunStarting twice' bug)
	runControlState = eRunStopping;
	syncWithRunControlCounterFlag = 0;
}
#endif



- (void) runIsAboutToStart:(NSNotification*)aNote
{
         //DEBUG
                 NSLog(@"%@::%@   --- FLT #%i<---------N\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self stationNumber]);//DEBUG -tb-
    
        //a test:
        testVariable = 25;
    
    if(![self isPartOfRun]) return;
        //read FPGA firmware version and status register for ... addParametersToDictionary:(NSMutableDictionary*) ...
        //this is called ater runTaskStarted:..., so these values will go into the Orca run file -tb-
        uint32_t status = [self readReg: kFLTV4StatusReg ]; //[self readStatus] would call both, but calls a NSLog..., too, which I do not want here -tb-
	    [self setStatusRegister:status];
    
        CFPGAVersion = [self readVersion];

}



- (void) runIsAboutToChangeState:(NSNotification*)aNote
{
    int state = [[[aNote userInfo] objectForKey:@"State"] intValue];

         //DEBUG
                 NSLog(@"%@::%@ Called runIsAboutToChangeState --- FLT #%i [self isPartOfRun] %i<----------------state:%i---------N\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self stationNumber],[self isPartOfRun],state);//DEBUG -tb-
                
    
    //is FLT  in data taker list of data task manager?
    if(![self isPartOfRun]) return;
    

    if(state==eRunStarting){
        //DEBUG
        NSLog(@"%@::%@ FLT#%i: run is starting, read back statusReg and FPGA version\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self stationNumber],hitRateEnabledMask);//DEBUG -tb-
	    //TODO: [self addRunWaitWithReason:@"FLTv4: wait for next hitrate event."];
        //a test:
        testVariable = 24;
    
        //read FPGA firmware version and status register for ... addParametersToDictionary:(NSMutableDictionary*) ...
        //this is called ater runTaskStarted:..., so these values will go into the Orca run file -tb-
        uint32_t status = [self readReg: kFLTV4StatusReg ]; //[self readStatus] would call both, but calls a NSLog..., too, which I do not want here -tb-
	    [self setStatusRegister:status];
    
        CFPGAVersion = [self readVersion];       }

	//we need to care about the following cases:
	// 1. no run active, system going to start run:
    //    (old state: eRunStopping/0  , new state: eRunStarting)
	// 2. run active, system going to change state:
	//    possible cases:
    //    old state: eRunStarting        , new state: eRunStopping ->stop run
    //    old state: eRunBetweenSubRuns  , new state: eRunStopping ->stop run (from 'between subruns')
    //    old state: eRunStarting        , new state: eRunBetweenSubRuns ->stop subrun, stay 'between subruns'
    //    old state: eRunBetweenSubRuns  , new state: eRunStarting ->start new subrun (from 'between subruns')



	/*
	id rc =  [aNote object];
    NSLog(@"Calling object %@\n",NSStringFromClass([rc class]));//DEBUG -tb-
	switch (state) {
		case eRunStarting://=2
            NSLog(@"   Notification: go to  %@\n",@"eRunStarting");//DEBUG -tb-
			break;
		case eRunBetweenSubRuns://=4
            NSLog(@"   Notification: go to  %@\n",@"eRunBetweenSubRuns");//DEBUG -tb-
			break;
		case eRunStopping://=3
            NSLog(@"   Notification: go to  %@\n",@"eRunStopping");//DEBUG -tb-
			break;
		default:
			break;
	}
	*/

}

- (BOOL) preRunChecks;
{
         //DEBUG                 NSLog(@"%@::%@   --- FLT #%i<---------N\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self stationNumber]);//DEBUG -tb-
                 return true;
}





#pragma mark ‚Ä¢‚Ä¢‚Ä¢Accessors

- (BOOL) saveIonChanFilterOutputRecords
{
    return saveIonChanFilterOutputRecords;
}

- (void) setSaveIonChanFilterOutputRecords:(BOOL)aSaveIonChanFilterOutputRecords
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSaveIonChanFilterOutputRecords:saveIonChanFilterOutputRecords];
    
    saveIonChanFilterOutputRecords = aSaveIonChanFilterOutputRecords;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelSaveIonChanFilterOutputRecordsChanged object:self];
}

- (int) hitrateLimitIon
{
    return hitrateLimitIon;
}

- (void) setHitrateLimitIon:(int)aHitrateLimitIon
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHitrateLimitIon:hitrateLimitIon];
    
    hitrateLimitIon = aHitrateLimitIon;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelHitrateLimitIonChanged object:self];
}

- (int) hitrateLimitHeat
{
    return hitrateLimitHeat;
}

- (void) setHitrateLimitHeat:(int)aHitrateLimitHeat
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHitrateLimitHeat:hitrateLimitHeat];
    
    hitrateLimitHeat = aHitrateLimitHeat;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelHitrateLimitHeatChanged object:self];
}

- (NSString*) chargeFICFile
{
    if(!chargeFICFile) return @"";
    return chargeFICFile;
}

- (void) setChargeFICFile:(NSString*)aChargeFICFile
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChargeFICFile:chargeFICFile];
    
    [chargeFICFile autorelease];
    chargeFICFile = [aChargeFICFile copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelChargeFICFileChanged object:self];
}

- (int) progressOfChargeFIC
{
    return progressOfChargeFIC;
}

- (void) setProgressOfChargeFIC:(int)aProgressOfChargeFIC
{
    progressOfChargeFIC = aProgressOfChargeFIC;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelProgressOfChargeFICChanged object:self];
}

- (uint32_t) ficCardTriggerCmdForFiber:(int)aFiber
{
    return ficCardTriggerCmd[aFiber];
}

- (void) setFicCardTriggerCmd:(uint32_t)aFicCardTriggerCmd  forFiber:(int)aFiber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFicCardTriggerCmd:ficCardTriggerCmd[aFiber] forFiber:aFiber];
    
    ficCardTriggerCmd[aFiber] = aFicCardTriggerCmd;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFicCardTriggerCmdChanged object:self];
}

- (uint32_t) ficCardADC23CtrlRegForFiber:(int)aFiber
{
    return ficCardADC23CtrlReg[aFiber];
}

- (void) setFicCardADC23CtrlReg:(uint32_t)aFicCardADC23CtrlReg forFiber:(int)aFiber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFicCardADC23CtrlReg:ficCardADC23CtrlReg[aFiber] forFiber:aFiber];
    
    ficCardADC23CtrlReg[aFiber] = aFicCardADC23CtrlReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFicCardADC23CtrlRegChanged object:self];
}

- (uint32_t) ficCardADC01CtrlRegForFiber:(int)aFiber
{
    return ficCardADC01CtrlReg[aFiber];
}

- (void) setFicCardADC01CtrlReg:(uint32_t)aFicCardADC01CtrlReg forFiber:(int)aFiber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFicCardADC01CtrlReg:ficCardADC01CtrlReg[aFiber] forFiber:aFiber];
    
    ficCardADC01CtrlReg[aFiber] = aFicCardADC01CtrlReg;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFicCardADC01CtrlRegChanged object:self];
}

- (uint32_t) ficCardCtrlReg2ForFiber:(int)aFiber
{
    return ficCardCtrlReg2[aFiber];
}

- (void) setFicCardCtrlReg2:(uint32_t)aFicCardCtrlReg2 forFiber:(int)aFiber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFicCardCtrlReg2:ficCardCtrlReg2[aFiber] forFiber:aFiber];
    
    ficCardCtrlReg2[aFiber] = aFicCardCtrlReg2;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFicCardCtrlReg2Changed object:self];
}

- (void) setFicCardCtrlReg2AddrOffs:(uint32_t)aOffset forFiber:(int)aFiber
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setFicCardCtrlReg2:ficCardCtrlReg2[aFiber] forFiber:aFiber];
    uint32_t aFicCardCtrlReg2 = ficCardCtrlReg2[aFiber];
    aFicCardCtrlReg2 = (aFicCardCtrlReg2 & 0xff00) |  (aOffset & 0x00ff);
    [self setFicCardCtrlReg2: aFicCardCtrlReg2 forFiber: aFiber];
    //[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFicCardCtrlReg2Changed object:self];
}

- (uint32_t) ficCardCtrlReg1ForFiber:(int)aFiber
{
    return ficCardCtrlReg1[aFiber];
}

- (void) setFicCardCtrlReg1:(uint32_t)aFicCardCtrlReg1 forFiber:(int)aFiber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFicCardCtrlReg1:ficCardCtrlReg1[aFiber] forFiber:aFiber];
    
    ficCardCtrlReg1[aFiber] = aFicCardCtrlReg1;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFicCardCtrlReg1Changed object:self];
}

- (int) pollBBStatusIntervall
{
    return pollBBStatusIntervall;
}

- (void) setPollBBStatusIntervall:(int)aPollBBStatusIntervall
{
    if(pollBBStatusIntervall!=0 && aPollBBStatusIntervall==0){//change from >0 to 0
	    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollBBStatus) object:nil];
    }
        //DEBUG OUTPUT:                   NSLog(@"%@::%@: aPollBBStatusIntervall %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aPollBBStatusIntervall);//TODO : DEBUG testing ...-tb-
    [[[self undoManager] prepareWithInvocationTarget:self] setPollBBStatusIntervall:pollBBStatusIntervall];
    pollBBStatusIntervall = aPollBBStatusIntervall;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelPollBBStatusIntervallChanged object:self];
    
    if(pollBBStatusIntervall>0){//change from 0 to >0
	    [self pollBBStatus];
    }
}

- (int) progressOfChargeBB
{
    return progressOfChargeBB;
}

- (void) setProgressOfChargeBB:(int)aProgressOfChargeBB
{
    progressOfChargeBB = aProgressOfChargeBB;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelProgressOfChargeBBChanged object:self];
}

- (NSString*) chargeBBFileForFiber:(int) aFiber
{
    aFiber=[self restrictIntValue:   aFiber   min:0 max:5];
    if(!chargeBBFileForFiber[aFiber]) return @"";
    return chargeBBFileForFiber[aFiber];
}

- (void) setChargeBBFile:(NSString*)aChargeBBFileForFiber forFiber:(int) aFiber
{
    aFiber=[self restrictIntValue:   aFiber   min:0 max:5];
    if(!aChargeBBFileForFiber) aChargeBBFileForFiber=@"";
    [[[self undoManager] prepareWithInvocationTarget:self] setChargeBBFile:chargeBBFileForFiber[aFiber] forFiber: aFiber];
    
    //Mark, what is better? I found both implementations ... Till (2013-08)
    #if 1
    [chargeBBFileForFiber[aFiber] autorelease];
    chargeBBFileForFiber[aFiber] = [aChargeBBFileForFiber copy];    
    #else
    [aChargeBBFileForFiber retain]; 
    [chargeBBFileForFiber[aFiber] release];
    chargeBBFileForFiber[aFiber] = aChargeBBFileForFiber;    
    #endif

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelChargeBBFileForFiberChanged object:self];
}


- (int) chargeBBWithDataFromFile:(NSString*)aFilename  //should move this to "HW access"? -tb-
{
    NSLog(@"%@::%@  \n", NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	NSData* theData = [NSData dataWithContentsOfFile:aFilename];
	if(![theData length]){
		//[NSException raise:@"No BB FPGA Configuration Data" format:@"Couldn't open BB ConfigurationFile: %@",[aFilename stringByAbbreviatingWithTildeInPath]];
		NSLog(@"%@::%@ ERROR: No BB FPGA Configuration Data - Couldn't open BB ConfigurationFile: %@\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),[aFilename stringByAbbreviatingWithTildeInPath]);
		return 0;
	}
    
    OREdelweissSLTModel *slt=0;
    slt=[[self crate] adapter];

    [slt chargeBBusingSBCinBackgroundWithData:theData forFLT:self];


    return (int)[theData length];
}


- (uint32_t) BB0x0ACmdMask
{
    return BB0x0ACmdMask;
}

- (void) setBB0x0ACmdMask:(uint32_t)aBB0x0ACmdMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBB0x0ACmdMask:BB0x0ACmdMask];
    BB0x0ACmdMask = aBB0x0ACmdMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelBB0x0ACmdMaskChanged object:self];
}

- (NSString*) chargeBBFile
{
	if(!chargeBBFile) return @"";
    return chargeBBFile;
}

- (void) setChargeBBFile:(NSString*)aChargeBBFile
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChargeBBFile:chargeBBFile];
    
    [chargeBBFile autorelease];
    chargeBBFile = [aChargeBBFile copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelChargeBBFileChanged object:self];
}

- (int) ionToHeatDelay
{
    return ionToHeatDelay;
}

- (void) setIonToHeatDelay:(int)aIonToHeatDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIonToHeatDelay:ionToHeatDelay];
    ionToHeatDelay = [self restrictIntValue:aIonToHeatDelay min:0 max:2047];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelIonToHeatDelayChanged object:self];
}
- (int) lowLevelRegInHex
{
    return lowLevelRegInHex;
}

- (void) setLowLevelRegInHex:(int)aLowLevelRegInHex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowLevelRegInHex:lowLevelRegInHex];
    
    lowLevelRegInHex = aLowLevelRegInHex;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelLowLevelRegInHexChanged object:self];
}

- (int) writeToBBMode
{
    return writeToBBMode;
}

- (void) setWriteToBBMode:(int)aWriteToBBMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteToBBMode:writeToBBMode];
    
    writeToBBMode = aWriteToBBMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelWriteToBBModeChanged object:self];
}

- (void) setDefaultsToBB:(int)fiber
{
    int i;
    int defaultTriRect=0;
    for(i=0; i<6; i++){
        //[[ self undoManager ] setActionName: @"Set BB Defaults Tri+Rect" ]; 			// set name of undo
        [self setTriDacForFiber: fiber atIndex:i to:defaultTriRect];
        [self setRectDacForFiber: fiber atIndex:i to:defaultTriRect];
    }
    int defaultPolar=0;
    for(i=0; i<11; i++){
        [self setPolarDacForFiber: fiber atIndex:i to:defaultPolar];
    }
    
    [self setDacaForFiber:fiber atIndex:0 to:1];
    [self setDacaForFiber:fiber atIndex:1 to:3];
    [self setDacaForFiber:fiber atIndex:2 to:5];
    [self setDacaForFiber:fiber atIndex:3 to:7];
    
    [self setD2ForFiber:fiber to:200];
    [self setD3ForFiber:fiber to:500];
    
	[self setAdcOnOffForBBAccessForFiber:fiber to:0xf];
	[self setRefForBBAccessForFiber:fiber to:0x1];

}

- (void) writeDefaultsToBB:(int)fiber
{
    //DEBUG    
    NSLog(@"%@::%@  \n", NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG testing ...-tb-

    int i;
    for(i=0; i<6; i++){
        //[[ self undoManager ] setActionName: @"Set BB Defaults Tri+Rect" ]; 			// set name of undo
        [self writeTriDacForFiber: fiber atIndex:i];
        [self writeRectDacForFiber: fiber atIndex:i];
    }

    for(i=0; i<11; i++){
        [self writePolarDacForFiber: fiber atIndex:i];
    }
    
    [self writeAdcRgForBBAccessForFiber:fiber atIndex:0];//writes: daca, signa, dacb,signb, Rg
    [self writeAdcRgForBBAccessForFiber:fiber atIndex:1];//writes: daca, signa, dacb,signb, Rg
    [self writeAdcRgForBBAccessForFiber:fiber atIndex:2];//writes: daca, signa, dacb,signb, Rg
    [self writeAdcRgForBBAccessForFiber:fiber atIndex:3];//writes: daca, signa, dacb,signb, Rg
    
    [self writeD2ForBBAccessForFiber:fiber];
    [self writeD3ForBBAccessForFiber:fiber];
    
	[self writeRelaisStatesForBBAccessForFiber:fiber];//writes Ref, ADCSon/off,relais1+2,mez


}

- (void) writeAllToBB:(int)fiber
{
    //DEBUG    
    NSLog(@"%@::%@  \n", NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG testing ...-tb-
    [self writeDefaultsToBB:fiber];

    [self writeAdcRgForBBAccessForFiber: fiber atIndex:4];//writes: daca, signa, dacb,signb, Rg
    [self writeAdcRgForBBAccessForFiber: fiber atIndex:5];//writes: daca, signa, dacb,signb, Rg
        
    int i;
    for(i=0; i<6; i++){
        [self writeAdcFilterForBBAccessForFiber: fiber atIndex:i];//writes: freq, gain
    }

    [self writeRgRtForBBAccessForFiber: fiber];
    [self writePolarDacForFiber: fiber atIndex:11];

}


- (unsigned int) wCmdArg2
{
    return wCmdArg2;
}

- (void) setWCmdArg2:(unsigned int)aWCmdArg2
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWCmdArg2:wCmdArg2];
    
    wCmdArg2 = aWCmdArg2;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelWCmdArg2Changed object:self];
}

- (unsigned int) wCmdArg1
{
    return wCmdArg1;
}

- (void) setWCmdArg1:(unsigned int)aWCmdArg1
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWCmdArg1:wCmdArg1];
    
    wCmdArg1 = aWCmdArg1;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelWCmdArg1Changed object:self];
}

- (unsigned int) wCmdCode
{
    return wCmdCode;
}

- (void) setWCmdCode:(unsigned int)aWCmdCode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWCmdCode:wCmdCode];
    
    wCmdCode = aWCmdCode;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelWCmdCodeChanged object:self];
}

- (NSMutableData*) statusBitsBBData
{
    return statusBitsBBData;
}

- (void) setStatusBitsBBData:(NSMutableData*)aStatusBitsBBData
{
    [aStatusBitsBBData retain];
    [statusBitsBBData release];
    statusBitsBBData = aStatusBitsBBData;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelStatusBitsBBDataChanged object:self];
}





- (int) dacbForFiber:(int)aFiber atIndex:(int)aIndex
{
    //return dacb;
    int off = kBBstatusRg;
    uint16_t mask = 0xf000;
    int shift = 12;
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: (off + aIndex)];
    return (currVal & mask) >> shift;
}

- (void) setDacbForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aDacb
{
    //undo
    int oldVal = [self signaForFiber:aFiber atIndex:aIndex];
    [[[self undoManager] prepareWithInvocationTarget:self] setDacbForFiber: aFiber atIndex:aIndex to: oldVal];
    
    int off = kBBstatusRg;
    uint16_t mask = 0xf000;
    int shift = 12;
    
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:aIndex mask:mask shift:shift to:aDacb];
    
    //notification
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aIndex] forKey: OREdelweissFLTIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelDacbChanged object:self  userInfo: userInfo];
}

- (int) signbForFiber:(int)aFiber atIndex:(int)aIndex
{
    //return signb;
    int off = kBBstatusRg;
    uint16_t mask = 0x0020;
    int shift = 5;
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: (off + aIndex)];
    return (currVal & mask) >> shift;
}

- (void) setSignbForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aSignb
{
    //undo
    int oldVal = [self signaForFiber:aFiber atIndex:aIndex];
    [[[self undoManager] prepareWithInvocationTarget:self] setSignbForFiber: aFiber atIndex:aIndex to: oldVal];
    
    int off = kBBstatusRg;
    uint16_t mask = 0x0020;
    int shift = 5;
    
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:aIndex mask:mask shift:shift to:aSignb];
    
    //notification
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aIndex] forKey: OREdelweissFLTIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelSignbChanged object:self  userInfo: userInfo];
}

- (int) dacaForFiber:(int)aFiber atIndex:(int)aIndex
{
    //return daca;
    int off = kBBstatusRg;
    uint16_t mask = 0x0f00;
    int shift = 8;
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: (off + aIndex)];
    return (currVal & mask) >> shift;
}

- (void) setDacaForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aDaca
{
    //undo
    int oldVal = [self dacaForFiber:aFiber atIndex:aIndex];
    [[[self undoManager] prepareWithInvocationTarget:self] setDacaForFiber: aFiber atIndex:aIndex to: oldVal];
    
    int off = kBBstatusRg;
    uint16_t mask = 0x0f00;
    int shift = 8;
    
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:aIndex mask:mask shift:shift to:aDaca];
    
    //notification
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aIndex] forKey: OREdelweissFLTIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelDacaChanged object:self  userInfo: userInfo];
}

- (int) signaForFiber:(int)aFiber atIndex:(int)aIndex
{
    //return signa;
    int off = kBBstatusRg;
    uint16_t mask = 0x0010;
    int shift = 4;
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: (off + aIndex)];
    return (currVal & mask) >> shift;
}

- (void) setSignaForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aSigna
{
    //undo
    int oldVal = [self signaForFiber:aFiber atIndex:aIndex];
    [[[self undoManager] prepareWithInvocationTarget:self] setSignaForFiber: aFiber atIndex:aIndex to: oldVal];
    
    int off = kBBstatusRg;
    uint16_t mask = 0x0010;
    int shift = 4;
    
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:aIndex mask:mask shift:shift to:aSigna];
    
    //notification
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aIndex] forKey: OREdelweissFLTIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelSignaChanged object:self  userInfo: userInfo];
}

- (int) adcRgForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex
{
    int off = kBBstatusRg;
    uint16_t mask = 0x000f;
    int shift = 0;
    
    //return adcRgForBBAccess;
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: (off + aIndex)];
    return (currVal & mask) >> shift;
}

- (void) setAdcRgForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aAdcRgForBBAccess
{
    //undo
    int oldVal = [self adcRgForBBAccessForFiber:aFiber atIndex:aIndex];
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcRgForBBAccessForFiber: aFiber atIndex:aIndex to: oldVal];
    
    int off = kBBstatusRg;
    uint16_t mask = 0x000f;
    int shift = 0;
    
    //set new value
    #if 1
    [self setStatusBB16forFiber:aFiber atOffset:off index:aIndex mask:mask shift:shift to:aAdcRgForBBAccess];
    #else
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: (kBBstatusRg + aIndex)];
    uint16_t newVal = (aAdcRgForBBAccess << shift) & mask ;// 
    newVal = (currVal & ~(mask))    |    newVal;
    [self setStatusBB16forFiber:aFiber atIndex:(off + aIndex) to:newVal];
    #endif
    
    //notification
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aIndex] forKey: OREdelweissFLTIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelAdcRgForBBAccessChanged object:self  userInfo: userInfo];
}

//dont confuse adcRg with Rg! -tb-
//writeAdcRg writes: daca, signa, dacb,signb, Rg
- (void) writeAdcRgForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex//HW access
{
    uint16_t val = [self statusBB16forFiber: aFiber atIndex: (kBBstatusRg + aIndex)];
    
    int idBB = 0xff;
    if(![self useBroadcastIdforBBAccess])  idBB=[self idBBforBBAccessForFiber:aFiber];
    int cmd = kBBcmdSetRg+aIndex;
    int arg1 = (val >> 8) & 0xff;
    int arg2 = val & 0xff;
    
    [self sendWCommandIdBB:idBB cmd:cmd arg1:arg1  arg2: arg2];

}


//dont confuse adcRg with Rg! -tb-
- (int) RgForFiber:(int)aFiber
{
    //return adcRt;
    int off = kBBstatusRt;
    uint16_t mask = 0x0f00;
    int shift = 8;
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: off];
    return (currVal & mask) >> shift;
} 

- (void) setRgForFiber:(int)aFiber to:(int)aAdcRg
{
    //undo
    int oldVal = [self RgForFiber:aFiber];
    [[[self undoManager] prepareWithInvocationTarget:self] setRgForFiber: aFiber to: oldVal];
    
    int off = kBBstatusRt;
    uint16_t mask = 0x0f00;
    int shift = 8;
    
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift to:aAdcRg];

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelAdcRtChanged object:self];
}

- (int) RtForFiber:(int)aFiber
{
    //return adcRt;
    int off = kBBstatusRt;
    uint16_t mask = 0x000f;
    int shift = 0;
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: off];
    return (currVal & mask) >> shift;
}

- (void) setRtForFiber:(int)aFiber to:(int)aAdcRt
{
    //undo
    int oldVal = [self RtForFiber:aFiber];
    [[[self undoManager] prepareWithInvocationTarget:self] setRtForFiber: aFiber to: oldVal];
    
    int off = kBBstatusRt;
    uint16_t mask = 0x000f;
    int shift = 0;
    
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift to:aAdcRt];

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelAdcRtChanged object:self];
}


- (void) writeRgRtForBBAccessForFiber:(int)aFiber//HW access
{
    uint16_t val = [self statusBB16forFiber: aFiber atIndex: (kBBstatusRt)];
    
    int idBB = 0xff;
    if(![self useBroadcastIdforBBAccess]) idBB=[self idBBforBBAccessForFiber:aFiber];
    int cmd = kBBcmdSetRt;
    int arg1 = (val >> 8) & 0xff;
    int arg2 = val & 0xff;
    
    [self sendWCommandIdBB:idBB cmd:cmd arg1:arg1  arg2: arg2];

}



- (int) D2ForFiber:(int)aFiber
{
    //return adcRt;
    int off = kBBstatusD2;
    uint16_t mask = 0xffff;
    int shift = 0;
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: off];
    return (currVal & mask) >> shift;
}

- (void) setD2ForFiber:(int)aFiber to:(int)aValue
{
    //undo
    int oldVal = [self D2ForFiber:aFiber];
    [[[self undoManager] prepareWithInvocationTarget:self] setD2ForFiber: aFiber to: oldVal];
    
    int off = kBBstatusD2;
    uint16_t mask = 0xffff;
    int shift = 0;
    
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift to:aValue];

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelD2Changed object:self];
}


- (void) writeD2ForBBAccessForFiber:(int)aFiber//HW access
{
    uint16_t val = [self statusBB16forFiber: aFiber atIndex: (kBBstatusD2)];
    
    int idBB = 0xff;
    if(![self useBroadcastIdforBBAccess]) idBB=[self idBBforBBAccessForFiber:aFiber];
    int cmd = kBBcmdSetD2;
    int arg1 = (val >> 8) & 0xff;
    int arg2 = val & 0xff;
    
    [self sendWCommandIdBB:idBB cmd:cmd arg1:arg1  arg2: arg2];

}




- (int) D3ForFiber:(int)aFiber
{
    //return adcRt;
    int off = kBBstatusD3;
    uint16_t mask = 0xffff;
    int shift = 0;
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: off];
    return (currVal & mask) >> shift;
}

- (void) setD3ForFiber:(int)aFiber to:(int)aValue
{
    //undo
    int oldVal = [self D3ForFiber:aFiber];
    [[[self undoManager] prepareWithInvocationTarget:self] setD3ForFiber: aFiber to: oldVal];
    
    int off = kBBstatusD3;
    uint16_t mask = 0xffff;
    int shift = 0;
    
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift to:aValue];

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelD3Changed object:self];
}


- (void) writeD3ForBBAccessForFiber:(int)aFiber//HW access
{
    uint16_t val = [self statusBB16forFiber: aFiber atIndex: (kBBstatusD3)];
    
    int idBB = 0xff;
    if(![self useBroadcastIdforBBAccess]) idBB=[self idBBforBBAccessForFiber:aFiber];
    int cmd = kBBcmdSetD3;
    int arg1 = (val >> 8) & 0xff;
    int arg2 = val & 0xff;
    
    [self sendWCommandIdBB:idBB cmd:cmd arg1:arg1  arg2: arg2];

}




- (int) adcValueForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex
{
    //return adcValueForBBAccess;
    int currVal = [self statusBB16forFiber: aFiber atIndex: (kBBstatusADCValue + aIndex)];
    currVal -= 0x8000; //Edelweiss 16 bit mapping: mapping reg. value 0x0000...0xffff to phys. value -0x8000...0x7fff(=-32768...32767)
    return currVal;
}

//TODO: the adc values are read only ... -tb-
- (void) setAdcValueForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aAdcValueForBBAccess
{
    int oldVal = [self adcValueForBBAccessForFiber:aFiber atIndex:aIndex];
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcValueForBBAccessForFiber: aFiber atIndex:aIndex to: oldVal];
    
    aAdcValueForBBAccess=[self restrictIntValue:   aAdcValueForBBAccess   min:-0x8000 max:0x7fff];
    [self setStatusBB16forFiber:aFiber atIndex:(kBBstatusADCValue + aIndex) to: aAdcValueForBBAccess+0x8000];

    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aIndex] forKey: OREdelweissFLTIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelAdcValueForBBAccessChanged object:self userInfo: userInfo];
}


//adc value is read only!
- (void) writeAdcValueForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex  //HW access 
{
/*
    uint16_t val = [self statusBB16forFiber: aFiber atIndex: (kBBstatusADCValue + aIndex)];
    
    int idBB = 0xff;
    if(![self useBroadcastIdforBBAccess])  idBB=[self idBBforBBAccessForFiber:aFiber];
    int cmd = XXXXXXXXX+aIndex;
    int arg1 = (val >> 8) & 0xff;
    int arg2 = val & 0xff;
    
    [self sendWCommandIdBB:idBB cmd:cmd arg1:arg1  arg2: arg2];
*/
}

//Gain
- (int) adcMultForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex
{
    //return adcMultForBBAccess;
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: (kBBstatusFilter + aIndex)];
    return currVal  & 0xf;;
}

- (void) setAdcMultForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aAdcMultForBBAccess;
{
    int oldVal = [self adcMultForBBAccessForFiber:aFiber atIndex:aIndex];
    if(  aAdcMultForBBAccess == oldVal  ) return; //same value, nothing to change ...
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcMultForBBAccessForFiber: aFiber atIndex:aIndex to: oldVal];

    uint16_t newVal = [self statusBB16forFiber: aFiber atIndex: (kBBstatusFilter + aIndex)];
    uint16_t val = (aAdcMultForBBAccess & 0xf) ;// 
    newVal = (newVal & ~(0x000f))    |    val;
    [self setStatusBB16forFiber:aFiber atIndex:(kBBstatusFilter + aIndex) to:newVal];


    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aIndex] forKey: OREdelweissFLTIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelAdcMultForBBAccessChanged object:self  userInfo: userInfo];
}




//freq values are stored from index 0x31 on (6 values)
//kBBstatusFilter is 12 ... (ipe4structure.h)
- (int) adcFreqkHzForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex
{
    //return adcFreqkHzForBBAccess;//TODO: adcFreqkHzForBBAccess is unused! remove it! -tb-
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: (kBBstatusFilter + aIndex)];
    return (currVal >> 4) & 0xf;;
}

- (void) setAdcFreqkHzForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aAdcFreqkHzForBBAccess
{
    int oldVal = [self adcFreqkHzForBBAccessForFiber:aFiber atIndex:aIndex];
        //DEBUG OUTPUT:
        NSLog(@"%@::%@: oldVal %i, fib %i, idx %i, freq %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),
        oldVal, aFiber, aIndex, aAdcFreqkHzForBBAccess);//TODO : DEBUG testing ...-tb-
    if(  aAdcFreqkHzForBBAccess == oldVal  ) return; //same value, nothing to change ...
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcFreqkHzForBBAccessForFiber: aFiber atIndex:aIndex to: oldVal];

    uint16_t newVal = [self statusBB16forFiber: aFiber atIndex: (kBBstatusFilter + aIndex)];
    uint16_t val = (aAdcFreqkHzForBBAccess & 0xf) <<4;// 
    
        NSLog(@"%@::%@: readVal 0x%x, val 0x%x, newval 0x%x , mask 0x%x\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),
                 newVal,val,(newVal & ~(0x00f0))    |    val,   ~(0x00f0));

    newVal = (newVal & ~(0x00f0))    |    val;
    [self setStatusBB16forFiber:aFiber atIndex:(kBBstatusFilter + aIndex) to:newVal];


    //    adcFreqkHzForBBAccess = aAdcFreqkHzForBBAccess;

    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aFiber] forKey: OREdelweissFLTFiber];
    [userInfo setObject:[NSNumber numberWithInt:aIndex] forKey: OREdelweissFLTIndex];


    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelAdcFreqkHzForBBAccessChanged 
                                          object:self userInfo: userInfo];
}


- (void) writeAdcFilterForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex//HW access
{
    uint16_t val = [self statusBB16forFiber: aFiber atIndex: (kBBstatusFilter + aIndex)];
    
    int idBB = 0xff;
    if(![self useBroadcastIdforBBAccess]) idBB=[self idBBforBBAccessForFiber:aFiber];
    int cmd = kBBcmdSetFilter+aIndex;
    int arg1 = (val >> 8) & 0xff;
    int arg2 = val & 0xff;
    
    [self sendWCommandIdBB:idBB cmd:cmd arg1:arg1  arg2: arg2];

}


- (int) useBroadcastIdforBBAccess
{
    return useBroadcastIdforBBAccess;
}

- (void) setUseBroadcastIdforBBAccess:(int)aUseBroadcastIdforBBAccess
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseBroadcastIdforBBAccess:useBroadcastIdforBBAccess];
    
    useBroadcastIdforBBAccess = aUseBroadcastIdforBBAccess;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelUseBroadcastIdforBBAccessChanged object:self];
}

- (int) idBBforBBAccessForFiber:(int)aFiber 
{
    //return idBBforBBAccess;
    int off = kBBstatusSerNum;
    uint16_t mask = 0x00ff;
    int shift = 0;
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: off];
    return (currVal & mask) >> shift;
}

- (void) setIdBBforBBAccessForFiber:(int)aFiber to:(int)aIdBBforBBAccess
{
    //undo
    int oldVal = [self idBBforBBAccessForFiber:aFiber];
    [[[self undoManager] prepareWithInvocationTarget:self] setIdBBforBBAccessForFiber: aFiber to: oldVal];
    
    int off = kBBstatusSerNum;
    uint16_t mask = 0x00ff;
    int shift = 0;
    
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift to:aIdBBforBBAccess];

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelIdBBforBBAccessChanged object:self];
}

- (int) fiberSelectForBBAccess
{
    return fiberSelectForBBAccess;
}

- (void) setFiberSelectForBBAccess:(int)aFiberSelectForBBAccess
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFiberSelectForBBAccess:fiberSelectForBBAccess];
    
    fiberSelectForBBAccess = aFiberSelectForBBAccess;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFiberSelectForBBAccessChanged object:self];
}


//relais state now contains: ref, ADC1..4,relais1/2,mez1/2
- (int) relaisStatesBBForFiber:(int)aFiber
{
    //return relaisStatesBB;
    int off = kBBstatusRelais;
    uint16_t mask = 0xffff;
    int shift = 0;
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: off];
    return (currVal & mask) >> shift;
}

- (void) setRelaisStatesBBForFiber:(int)aFiber to:(int)aRelaisStatesBB
{
    //undo
    int oldVal = [self relaisStatesBBForFiber:aFiber];
    [[[self undoManager] prepareWithInvocationTarget:self] setRelaisStatesBBForFiber: aFiber to: oldVal];
    
    int off = kBBstatusRelais;
    uint16_t mask = 0xffff;
    int shift = 0;
    
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift to:aRelaisStatesBB];

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelRelaisStatesBBChanged object:self];
}

- (void) writeRelaisStatesForBBAccessForFiber:(int)aFiber//HW access
{
    uint16_t val = [self statusBB16forFiber: aFiber atIndex: (kBBstatusRelais)];
    
    int idBB = 0xff;
    if(![self useBroadcastIdforBBAccess]) idBB=[self idBBforBBAccessForFiber:aFiber];
    int cmd = kBBcmdSetRelais;
    int arg1 = (val >> 8) & 0xff;
    int arg2 = val & 0xff;
    
    [self sendWCommandIdBB:idBB cmd:cmd arg1:arg1  arg2: arg2];

}


- (int) refForBBAccessForFiber:(int)aFiber
{
    int currVal = [self relaisStatesBBForFiber:aFiber];
    uint16_t mask = kBBRefMask;
    int shift = kBBRefShift;
    return (currVal & mask) >> shift;
}

- (void) setRefForBBAccessForFiber:(int)aFiber to:(int)aValue
{
    int oldVal = [self refForBBAccessForFiber:aFiber];
    [[[self undoManager] prepareWithInvocationTarget:self] setRefForBBAccessForFiber: aFiber to: oldVal];
    
    int off = kBBstatusRelais;
    uint16_t mask = kBBRefMask;
    int shift = kBBRefShift;
    
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift to:aValue];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelRelaisStatesBBChanged object:self];
}

- (int) adcOnOffForBBAccessForFiber:(int)aFiber
{
    #if 0
    int currVal = [self relaisStatesBBForFiber:aFiber];
    uint16_t mask = kBBADCMask;
    int shift = kBBADCShift;
    return (currVal & mask) >> shift;
    #else
    int off = kBBstatusRelais;
    uint16_t mask = kBBADCMask;
    int shift = kBBADCShift;
    return [self statusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift];
    #endif
}

- (void) setAdcOnOffForBBAccessForFiber:(int)aFiber to:(int)aValue
{
    int oldVal = [self adcOnOffForBBAccessForFiber:aFiber];
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcOnOffForBBAccessForFiber: aFiber to: oldVal];
    
    int off = kBBstatusRelais;
    uint16_t mask = kBBADCMask;
    int shift = kBBADCShift;
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift to:aValue];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelRelaisStatesBBChanged object:self];
}


- (int) relais1ForBBAccessForFiber:(int)aFiber
{
    int off = kBBstatusRelais;
    uint16_t mask = kBBRelais1Mask;
    int shift = kBBRelais1Shift;
    return [self statusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift];
}

- (void) setRelais1ForBBAccessForFiber:(int)aFiber to:(int)aValue
{
    int oldVal = [self relais1ForBBAccessForFiber:aFiber];
    [[[self undoManager] prepareWithInvocationTarget:self] setRelais1ForBBAccessForFiber: aFiber to: oldVal];

    int off = kBBstatusRelais;
    uint16_t mask = kBBRelais1Mask;
    int shift = kBBRelais1Shift;
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift to:aValue];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelRelaisStatesBBChanged object:self];
}

- (int) relais2ForBBAccessForFiber:(int)aFiber
{
    int off = kBBstatusRelais;
    uint16_t mask = kBBRelais2Mask;
    int shift = kBBRelais2Shift;
    return [self statusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift];
}

- (void) setRelais2ForBBAccessForFiber:(int)aFiber to:(int)aValue
{
    int oldVal = [self relais2ForBBAccessForFiber:aFiber];
    [[[self undoManager] prepareWithInvocationTarget:self] setRelais2ForBBAccessForFiber: aFiber to: oldVal];

    int off = kBBstatusRelais;
    uint16_t mask = kBBRelais2Mask;
    int shift = kBBRelais2Shift;
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift to:aValue];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelRelaisStatesBBChanged object:self];
}

- (int) mezForBBAccessForFiber:(int)aFiber
{
    int off = kBBstatusRelais;
    uint16_t mask = kBBMezMask;
    int shift = kBBMezShift;
    return [self statusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift];
}

- (void) setMezForBBAccessForFiber:(int)aFiber to:(int)aValue
{
    int oldVal = [self mezForBBAccessForFiber:aFiber];
    [[[self undoManager] prepareWithInvocationTarget:self] setMezForBBAccessForFiber: aFiber to: oldVal];

    int off = kBBstatusRelais;
    uint16_t mask = kBBMezMask;
    int shift = kBBMezShift;
    //set new value
    [self setStatusBB16forFiber:aFiber atOffset:off index:0 mask:mask shift:shift to:aValue];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelRelaisStatesBBChanged object:self];
}









- (int) polarDacForFiber:(int)aFiber atIndex:(int)aIndex   // DAC = polar_dac (cew_control name)
{
    //return adcValueForBBAccess;
    int currVal = [self statusBB16forFiber: aFiber atIndex: (kBBstatusDAC + aIndex)];
    if(aIndex<=7 || aIndex>=11){
        currVal -= 0x8000; //Edelweiss 16 bit mapping: mapping reg. value 0x0000...0xffff to phys. value -0x8000...0x7fff(=-32768...32767)
    }else{
        //DAC # 9,10,11: 0... 65537
    }
    return currVal;
}

- (void) setPolarDacForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aDacValue  // DAC = polar_dac (cew_control name)
{
    int oldVal = [self polarDacForFiber:aFiber atIndex:aIndex];
    [[[self undoManager] prepareWithInvocationTarget:self] setPolarDacForFiber: aFiber atIndex:aIndex to: oldVal];
    
    if(aIndex<=7 || aIndex>=11){
        aDacValue=[self restrictIntValue:   aDacValue   min:-0x8000 max:0x7fff];
        [self setStatusBB16forFiber:aFiber atIndex:(kBBstatusDAC + aIndex) to: aDacValue+0x8000];
    }else{
        //DAC # 9,10,11: 0... 65537
        aDacValue=[self restrictIntValue:   aDacValue   min:0 max:65535];
        [self setStatusBB16forFiber:aFiber atIndex:(kBBstatusDAC + aIndex) to: aDacValue];
    }
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aIndex] forKey: OREdelweissFLTIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelPolarDacChanged  object:self userInfo: userInfo];
}

- (void) writePolarDacForFiber:(int)aFiber atIndex:(int)aIndex  //HW access
{
    uint16_t val = [self statusBB16forFiber: aFiber atIndex: (kBBstatusDAC + aIndex)];
    
    int idBB = 0xff;
    if(![self useBroadcastIdforBBAccess]) idBB=[self idBBforBBAccessForFiber:aFiber];
    int cmd = kBBcmdSetDAC+aIndex;
    int arg1 = (val >> 8) & 0xff;
    int arg2 = val & 0xff;
    
    [self sendWCommandIdBB:idBB cmd:cmd arg1:arg1  arg2: arg2];

}




- (int) triDacForFiber:(int)aFiber atIndex:(int)aIndex
{
    int currVal = [self statusBB16forFiber: aFiber atIndex: (kBBstatusTri + aIndex)];
    currVal -= 0x8000; //Edelweiss 16 bit mapping: mapping reg. value 0x0000...0xffff to phys. value -0x8000...0x7fff(=-32768...32767)
    return currVal;
}

- (void) setTriDacForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aDacValue
{
    int oldVal = [self triDacForFiber:aFiber atIndex:aIndex];
    [[[self undoManager] prepareWithInvocationTarget:self] setTriDacForFiber: aFiber atIndex:aIndex to: oldVal];
    
    aDacValue=[self restrictIntValue:   aDacValue   min:-0x8000 max:0x7fff];
    [self setStatusBB16forFiber:aFiber atIndex:(kBBstatusTri + aIndex) to: aDacValue+0x8000];

    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aIndex] forKey: OREdelweissFLTIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTriDacChanged  object:self userInfo: userInfo];
}

- (void) writeTriDacForFiber:(int)aFiber atIndex:(int)aIndex//HW access
{
    uint16_t val = [self statusBB16forFiber: aFiber atIndex: (kBBstatusTri + aIndex)];
    
    int idBB = 0xff;
    if(![self useBroadcastIdforBBAccess]) idBB=[self idBBforBBAccessForFiber:aFiber];
    int cmd = kBBcmdSetTri+aIndex;
    int arg1 = (val >> 8) & 0xff;
    int arg2 = val & 0xff;
    
    [self sendWCommandIdBB:idBB cmd:cmd arg1:arg1  arg2: arg2];

}





- (int) rectDacForFiber:(int)aFiber atIndex:(int)aIndex
{
    int currVal = [self statusBB16forFiber: aFiber atIndex: (kBBstatusRect + aIndex)];
    currVal -= 0x8000; //Edelweiss 16 bit mapping: mapping reg. value 0x0000...0xffff to phys. value -0x8000...0x7fff(=-32768...32767)
    return currVal;
}

- (void) setRectDacForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aDacValue
{
    int oldVal = [self rectDacForFiber:aFiber atIndex:aIndex];
    [[[self undoManager] prepareWithInvocationTarget:self] setRectDacForFiber: aFiber atIndex:aIndex to: oldVal];
    
    aDacValue=[self restrictIntValue:   aDacValue   min:-0x8000 max:0x7fff];
    [self setStatusBB16forFiber:aFiber atIndex:(kBBstatusRect + aIndex) to: aDacValue+0x8000];

    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aIndex] forKey: OREdelweissFLTIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelRectDacChanged  object:self userInfo: userInfo];
}

- (void) writeRectDacForFiber:(int)aFiber atIndex:(int)aIndex//HW access
{
    uint16_t val = [self statusBB16forFiber: aFiber atIndex: (kBBstatusRect + aIndex)];
    
    int idBB = 0xff;
    if(![self useBroadcastIdforBBAccess]) idBB=[self idBBforBBAccessForFiber:aFiber];
    int cmd = kBBcmdSetRect+aIndex;
    int arg1 = (val >> 8) & 0xff;
    int arg2 = val & 0xff;
    
    [self sendWCommandIdBB:idBB cmd:cmd arg1:arg1  arg2: arg2];

}




- (double) temperatureBBforBBAccessForFiber:(int)aFiber 
{
    uint16_t currVal = [self statusBB16forFiber: aFiber atIndex: kBBstatusTemperature];
    return     (((double)((currVal>>4)&0xfff))/16.);
}





//BB status bit buffer

- (uint32_t) statusBB32forFiber:(int)aFiber atIndex:(int)aIndex
{
    return statusBitsBB[aFiber][aIndex];
}

- (void) setStatusBB32forFiber:(int)aFiber atIndex:(int)aIndex to:(uint32_t)aValue
{
    statusBitsBB[aFiber][aIndex]=aValue;
}

- (uint16_t) statusBB16forFiber:(int)aFiber atIndex:(int)aIndex;
{
    uint16_t *statusBitsBB16=    (uint16_t *)statusBitsBB[aFiber];
    return statusBitsBB16[aIndex];
}

- (void) setStatusBB16forFiber:(int)aFiber atIndex:(int)aIndex to:(uint16_t)aValue;
{
    uint16_t *statusBitsBB16=    (uint16_t *)statusBitsBB[aFiber];
    statusBitsBB16[aIndex]=aValue;
}


- (uint16_t) statusBB16forFiber:(int)aFiber atOffset:(int) off index:(int)aIndex mask:(uint16_t)mask shift:(int) shift
{
    uint16_t *statusBitsBB16=    (uint16_t *)statusBitsBB[aFiber];
    uint16_t currVal = statusBitsBB16[off+aIndex];
    return (currVal & mask) >> shift;
}

- (void) setStatusBB16forFiber:(int)aFiber atOffset:(int) off index:(int)aIndex mask:(uint16_t)mask shift:(int) shift to:(uint16_t)aValue
{
    uint16_t *statusBitsBB16=    (uint16_t *)statusBitsBB[aFiber];
    uint16_t currVal = statusBitsBB16[off+aIndex];
    uint16_t newVal = (aValue << shift) & mask ;
    statusBitsBB16[off+aIndex] = (currVal & ~(mask))    |    newVal;
}


- (void) dumpStatusBB16forFiber:(int)aFiber
{
		//	NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
        NSFont* aFont = [NSFont fontWithName:@"Monaco" size:9];

        NSLogFont(aFont,@"Dump stored BBStatBits of fiber #%i (idx %i)\n",fiberSelectForBBAccess+1,fiberSelectForBBAccess);

        uint16_t *statusBitsBB16=    (uint16_t *)statusBitsBB[aFiber];
        int i;
 
        NSString *s = [[NSString alloc] initWithString: @""];
        for(i=0;i<58;i++){
            //BBStatus16[i]=i*2+i*0x10000;
            s = [s stringByAppendingFormat:@"(%2i) 0x%04x; ", i,statusBitsBB16[i] ];
            if( ((i+1) % 10)== 0){
                NSLogFont(aFont,@"BBStatBits:%@\n",s);
                s=@"";
            }
        }
        if([s length]!= 0)        NSLogFont(aFont,@"BBStatBits:%@\n",s);
}




- (int) fiberSelectForBBStatusBits
{
    return fiberSelectForBBStatusBits;
}

- (void) setFiberSelectForBBStatusBits:(int)aFiberSelectForBBStatusBits
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFiberSelectForBBStatusBits:fiberSelectForBBStatusBits];
    
    fiberSelectForBBStatusBits = aFiberSelectForBBStatusBits;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFiberSelectForBBStatusBitsChanged object:self];
}

- (uint32_t) fiberOutMask
{
    return fiberOutMask;
}

- (void) setFiberOutMask:(uint32_t)aFiberOutMask
{
        //DEBUG OUTPUT: 	        NSLog(@"%@::%@: UNDER CONSTRUCTION! aFiberOutMask %x\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aFiberOutMask);//TODO : DEBUG testing ...-tb-
    [[[self undoManager] prepareWithInvocationTarget:self] setFiberOutMask:fiberOutMask];
    fiberOutMask = aFiberOutMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFiberOutMaskChanged object:self];
}


- (int) swTriggerIsRepeating
{
    return swTriggerIsRepeating;
}

- (void) setSwTriggerIsRepeating:(int)aSwTriggerIsRepeating
{
    swTriggerIsRepeating = aSwTriggerIsRepeating;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelSwTriggerIsRepeatingChanged object:self];
}

- (int) repeatSWTriggerMode
{
    return repeatSWTriggerMode;
}

- (void) setRepeatSWTriggerMode:(int)aRepeatSWTriggerMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatSWTriggerMode:repeatSWTriggerMode];
    
    repeatSWTriggerMode = aRepeatSWTriggerMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelRepeatSWTriggerModeChanged object:self];
}


- (double) repeatSWTriggerDelay
{
    return repeatSWTriggerDelay;
}

- (void) setRepeatSWTriggerDelay:(double)aRepeatSWTriggerDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatSWTriggerDelay:repeatSWTriggerDelay];
    
    repeatSWTriggerDelay = aRepeatSWTriggerDelay;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelRepeatSWTriggerDelayChanged object:self];
}












- (uint32_t) controlRegister
{
    return controlRegister;
}

- (void) setControlRegister:(uint32_t)aControlRegister
{
    [[[self undoManager] prepareWithInvocationTarget:self] setControlRegister:controlRegister];
	
    controlRegister = aControlRegister;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelControlRegisterChanged object:self];
	
	//TODO: OREdelweissFLTModelControlRegisterChanged
	//replaced
	//OREdelweissFLTModelFiberEnableMaskChanged, OREdelweissFLTModelSelectFiberTrigChanged
}

- (int) statusLatency//obsolete 2014 -tb-
{    return (controlRegister >> kEWFlt_ControlReg_StatusLatency_Shift) & kEWFlt_ControlReg_StatusLatency_Mask;   }

- (void) setStatusLatency:(int)aValue//obsolete 2014 -tb-
{
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_StatusLatency_Mask << kEWFlt_ControlReg_StatusLatency_Shift);
    cr = cr | ((aValue & kEWFlt_ControlReg_StatusLatency_Mask) << kEWFlt_ControlReg_StatusLatency_Shift);
	[self setControlRegister:cr];
}

- (int) vetoFlag
{    return (controlRegister >> kEWFlt_ControlReg_VetoFlag_Shift) & kEWFlt_ControlReg_VetoFlag_Mask;   }

- (void) setVetoFlag:(int)aValue
{
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_VetoFlag_Mask << kEWFlt_ControlReg_VetoFlag_Shift);
    cr = cr | ((aValue & kEWFlt_ControlReg_VetoFlag_Mask) << kEWFlt_ControlReg_VetoFlag_Shift);
	[self setControlRegister:cr];
}



- (uint32_t) selectFiberTrig//obsolete 2014 -tb-
{
    return (controlRegister >> kEWFlt_ControlReg_SelectFiber_Shift) & kEWFlt_ControlReg_SelectFiber_Mask;
}

- (void) setSelectFiberTrig:(int)aSelectFiberTrig//obsolete 2014 -tb-
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setSelectFiberTrig:selectFiberTrig];
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_SelectFiber_Mask << kEWFlt_ControlReg_SelectFiber_Shift);
    selectFiberTrig = aSelectFiberTrig;
    cr = cr | ((selectFiberTrig & kEWFlt_ControlReg_SelectFiber_Mask) << kEWFlt_ControlReg_SelectFiber_Shift);
	[self setControlRegister:cr];
    //[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelSelectFiberTrigChanged object:self];
}

- (int) BBv1Mask
{    return (controlRegister >> kEWFlt_ControlReg_BBv1_Shift) & kEWFlt_ControlReg_BBv1_Mask;   }
//{
//    return BBv1Mask;
//}

- (BOOL) BBv1MaskForChan:(int)i
{
    return ([self BBv1Mask] & (0x1 <<i)) != 0;
}

//TODO: OREdelweissFLTModelBBv1MaskChanged and BBv1Mask obsolete -tb-
- (void) setBBv1Mask:(int)aBBv1Mask
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setBBv1Mask:BBv1Mask];
    //BBv1Mask = aBBv1Mask;
    //[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelBBv1MaskChanged object:self];
    //BBv1Mask = aBBv1Mask;
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_BBv1_Mask << kEWFlt_ControlReg_BBv1_Shift);
    cr = cr | ((aBBv1Mask & kEWFlt_ControlReg_BBv1_Mask) << kEWFlt_ControlReg_BBv1_Shift);
	[self setControlRegister:cr];
}

- (int) fiberEnableMask
{    return (controlRegister >> kEWFlt_ControlReg_FiberEnable_Shift) & kEWFlt_ControlReg_FiberEnable_Mask;   }
//{    return fiberEnableMask;}

- (int) fiberEnableMaskForChan:(int)i
{
    return ([self fiberEnableMask] & (0x1 <<i)) != 0;
}

//TODO: OREdelweissFLTModelFiberEnableMaskChanged and fiberEnableMask obsolete -tb-
- (void) setFiberEnableMask:(int)aFiberEnableMask
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setFiberEnableMask:fiberEnableMask];
    //fiberEnableMask = aFiberEnableMask;
    //[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFiberEnableMaskChanged object:self];
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_FiberEnable_Mask << kEWFlt_ControlReg_FiberEnable_Shift);
    fiberEnableMask = aFiberEnableMask;
    cr = cr | ((aFiberEnableMask & kEWFlt_ControlReg_FiberEnable_Mask) << kEWFlt_ControlReg_FiberEnable_Shift);
	[self setControlRegister:cr];
}

- (int) fltModeFlags // this are the flags 4-6 -tb-
{    return (controlRegister >> kEWFlt_ControlReg_ModeFlags_Shift) & kEWFlt_ControlReg_ModeFlags_Mask;   }
//{    return fltModeFlags;}

- (void) setFltModeFlags:(int)aFltModeFlags
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setFltModeFlags:fltModeFlags];
    //fltModeFlags = aFltModeFlags;
    //[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFltModeFlagsChanged object:self];
    fltModeFlags = aFltModeFlags;
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_ModeFlags_Mask << kEWFlt_ControlReg_ModeFlags_Shift);
    cr = cr | ((aFltModeFlags & kEWFlt_ControlReg_ModeFlags_Mask) << kEWFlt_ControlReg_ModeFlags_Shift);
	[self setControlRegister:cr];
}



- (int) tpix//obsolete 2014 -tb-
{    return (controlRegister >> kEWFlt_ControlReg_tpix_Shift) & kEWFlt_ControlReg_tpix_Mask;   }


- (void) setTpix:(int)aTpix//obsolete 2014 -tb-
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setTpix:tpix];
    //tpix = aTpix;
    //[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTpixChanged object:self];
    //tpix = aTpix;
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_tpix_Mask << kEWFlt_ControlReg_tpix_Shift);
    cr = cr |              ((aTpix & kEWFlt_ControlReg_tpix_Mask) << kEWFlt_ControlReg_tpix_Shift);
	[self setControlRegister:cr];
}


- (int) statusBitPos//new 2014 -tb-
{    return (controlRegister >> kEWFlt_ControlReg_statusBitPos_Shift) & kEWFlt_ControlReg_statusBitPos_Mask;   }

- (void) setStatusBitPos:(int)aValue//new 2014 -tb-
{
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_statusBitPos_Mask << kEWFlt_ControlReg_statusBitPos_Shift);
    cr = cr |              ((aValue & kEWFlt_ControlReg_statusBitPos_Mask) << kEWFlt_ControlReg_statusBitPos_Shift);
	[self setControlRegister:cr];
}

- (int) ficOnFiberMask
{    return (controlRegister >> kEWFlt_ControlReg_FIConFib_Shift) & kEWFlt_ControlReg_FIConFib_Mask;   }


- (int) ficOnFiberMaskForChan:(int)i
{
    return ([self ficOnFiberMask] & (0x1 <<i)) != 0;
}

- (void) setFicOnFiberMask:(int)aMask
{
    uint32_t cr = controlRegister & ~(kEWFlt_ControlReg_FIConFib_Mask << kEWFlt_ControlReg_FIConFib_Shift);
    cr = cr | ((aMask & kEWFlt_ControlReg_FIConFib_Mask) << kEWFlt_ControlReg_FIConFib_Shift);
	[self setControlRegister:cr];
}






- (int) totalTriggerNRegister
{
    return totalTriggerNRegister;
}

- (void) setTotalTriggerNRegister:(int)aTotalTriggerNRegister
{
    totalTriggerNRegister = aTotalTriggerNRegister;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTotalTriggerNRegisterChanged object:self];
}

- (uint32_t) statusRegister
{
    return statusRegister;
}

- (void) setStatusRegister:(uint32_t)aStatusRegister
{
    statusRegister = aStatusRegister;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelStatusRegisterChanged object:self];
}

- (int) fastWrite
{
    return fastWrite;
}

- (void) setFastWrite:(int)aFastWrite
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFastWrite:fastWrite];
    
    fastWrite = aFastWrite;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFastWriteChanged object:self];
}

- (uint64_t) fiberDelays
{
    return fiberDelays;
}

- (void) setFiberDelays:(uint64_t)aFiberDelays
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFiberDelays:fiberDelays];
    
    if(fastWrite){ 
	    //if(fiberDelays != aFiberDelays)
		{
            fiberDelays = aFiberDelays;
		    [self writeFiberDelays];
		}
	}else{
		fiberDelays = aFiberDelays;
	}

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFiberDelaysChanged object:self];
}

- (uint64_t) streamMask
{
    return streamMask;
}

- (uint32_t) streamMask1
{
    uint32_t val=0;
	val = streamMask & 0xffffffffLL;
	return (uint32_t)val;
}

- (uint32_t) streamMask2
{
    uint32_t val;
	val = (streamMask & 0xffffffff00000000LL) >> 32;
	return val;
}

- (int) streamMaskForFiber:(int)aFiber chan:(int)aChan
{
    uint64_t mask = ((0x1LL<<aChan) << (aFiber*8));
	return ((streamMask & mask) !=0);
}


- (void) setStreamMask:(uint64_t)aStreamMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStreamMask:streamMask];
    
    streamMask = aStreamMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelStreamMaskChanged object:self];
}

//- (void) setStreamMaskForFiber:(int)aFiber chan:(int)aChan value:(BOOL)val
//{
//}






- (uint64_t) ionTriggerMask
{
    return ionTriggerMask;
}

- (uint32_t) ionTriggerMask1
{
    uint32_t val=0;
	val = ionTriggerMask & 0xffffffffLL;
	return (uint32_t)val;
}

- (uint32_t) ionTriggerMask2
{
    uint32_t val;
	val = (ionTriggerMask & 0xffffffff00000000LL) >> 32;
	return val;
}

- (int) ionTriggerMaskForFiber:(int)aFiber chan:(int)aChan
{
    uint64_t mask = ((0x1LL<<aChan) << (aFiber*8));
	return ((ionTriggerMask & mask) !=0);
}



- (void) setIonTriggerMask:(uint64_t)aIonTriggerMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIonTriggerMask:ionTriggerMask];
    
    ionTriggerMask = aIonTriggerMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelIonTriggerMaskChanged object:self];
}



- (uint64_t) heatTriggerMask
{
    return heatTriggerMask;
}

- (uint32_t) heatTriggerMask1
{
    uint32_t val=0;
	val = heatTriggerMask & 0xffffffffLL;
	return (uint32_t)val;
}

- (uint32_t) heatTriggerMask2
{
    uint32_t val;
	val = (heatTriggerMask & 0xffffffff00000000LL) >> 32;
	return val;
}

- (int) heatTriggerMaskForFiber:(int)aFiber chan:(int)aChan
{
    uint64_t mask = ((0x1LL<<aChan) << (aFiber*8));
	return ((heatTriggerMask & mask) !=0);
}



- (void) setHeatTriggerMask:(uint64_t)aHeatTriggerMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHeatTriggerMask:heatTriggerMask];
    
    heatTriggerMask = aHeatTriggerMask;

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelHeatTriggerMaskChanged object:self];
}




- (int) targetRate { return targetRate; }
- (void) setTargetRate:(int)aTargetRate
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTargetRate:targetRate];
    targetRate = [self restrictIntValue:aTargetRate min:1 max:100];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTargetRateChanged object:self];
}



- (int) runMode { return runMode; }
- (void) setRunMode:(int)aRunMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunMode:runMode];
    runMode = aRunMode;
	
	readWaveforms = YES;
	
            //DEBUG OUTPUT:
            static int debFlag=1;if(debFlag) NSLog(@"%@::%@: mode 0x%016llx \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),runMode);debFlag=0;//TODO: DEBUG testing ...-tb-
	
	switch (runMode) {
		case kIpeFltV4_EventDaqMode:
			//TODO: [self setFltRunMode:kIpeFltV4Katrin_Run_Mode];
       	    readWaveforms = YES;
			break;
			
		case kIpeFltV4_MonitoringDaqMode:
			//TODO: [self setFltRunMode:kIpeFltV4Katrin_Run_Mode];
			break;
			
#if 0
		case kIpeFltV4_EnergyDaqMode:
			[self setFltRunMode:kIpeFltV4Katrin_Run_Mode];
			break;
			
		case kIpeFltV4_EnergyTraceDaqMode:
			[self setFltRunMode:kIpeFltV4Katrin_Run_Mode];
			readWaveforms = YES;
			break;
			
		case kIpeFltV4_Histogram_DaqMode:
			[self setFltRunMode:kIpeFltV4Katrin_Histo_Mode];
			//TODO: workaround - if set to kFifoStopOnFull the histogramming stops after some seconds - probably a FPGA bug? -tb-
			if(fifoBehaviour == kFifoStopOnFull){
				//NSLog(@"OREdelweissFLTModel message: due to a FPGA side effect histogramming mode should run with kFifoEnableOverFlow setting! -tb-\n");//TODO: fix it -tb-
				NSLog(@"OREdelweissFLTModel message: switched FIFO behaviour to kFifoEnableOverFlow (required for histogramming mode)\n");//TODO: fix it -tb-
				[self setFifoBehaviour: kFifoEnableOverFlow];
			}
			break;
#endif			
		default:
			break;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelModeChanged object:self];
}

- (BOOL) noiseFloorRunning { return noiseFloorRunning; }

- (int) noiseFloorOffset { return noiseFloorOffset; }
- (void) setNoiseFloorOffset:(int)aNoiseFloorOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNoiseFloorOffset:noiseFloorOffset];
    noiseFloorOffset = aNoiseFloorOffset;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTNoiseFloorOffsetChanged object:self];
}



- (BOOL) storeDataInRam { return storeDataInRam; }
- (void) setStoreDataInRam:(BOOL)aStoreDataInRam
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStoreDataInRam:storeDataInRam];
    storeDataInRam = aStoreDataInRam;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelStoreDataInRamChanged object:self];
}

- (int) filterLength { return filterLength; }
- (void) setFilterLength:(int)aFilterLength
{
	if(aFilterLength == 6 && gapLength>0){
		[self setGapLength:0];
		NSLog(@"Warning: setFilterLength: FLTv4: maximum filter length allows only gap length of 0. Gap length reset to 0!\n");
	}
    [[[self undoManager] prepareWithInvocationTarget:self] setFilterLength:filterLength];
    filterLength = [self restrictIntValue:aFilterLength min:2 max:8];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFilterLengthChanged object:self];
}

- (int) gapLength { return gapLength; }
- (void) setGapLength:(int)aGapLength
{
	if(filterLength == 6 && aGapLength>0){
		aGapLength=0;
		NSLog(@"Warning: setGapLength: FLTv4: maximum filter length allows only gap length of 0. Gap length reset to 0!\n");
	}
    [[[self undoManager] prepareWithInvocationTarget:self] setGapLength:gapLength];
    gapLength = [self restrictIntValue:aGapLength min:0 max:7];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelGapLengthChanged object:self];
}

- (uint32_t) postTriggerTime { return postTriggerTime; }
- (void) setPostTriggerTime:(uint32_t)aPostTriggerTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerTime:postTriggerTime];
    //postTriggerTime = [self restrictIntValue:aPostTriggerTime min:0 max:2047];//min 6 was found 'experimental' for KATRIN -tb-
    postTriggerTime = aPostTriggerTime & 0xffff;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelPostTriggerTimeChanged object:self];
}

- (int) fifoBehaviour { return fifoBehaviour; }
- (void) setFifoBehaviour:(int)aFifoBehaviour
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFifoBehaviour:fifoBehaviour];
    fifoBehaviour = [self restrictIntValue:aFifoBehaviour min:0 max:1];;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFifoBehaviourChanged object:self];
}

- (uint32_t) eventMask { return eventMask; }
- (void) eventMask:(uint32_t)aMask
{
	eventMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelEventMaskChanged object:self];
}

- (int) analogOffset{ return analogOffset; }
- (void) setAnalogOffset:(int)aAnalogOffset
{
	
    [[[self undoManager] prepareWithInvocationTarget:self] setAnalogOffset:analogOffset];
    analogOffset = [self restrictIntValue:aAnalogOffset min:0 max:4095];
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelAnalogOffsetChanged object:self];
}

- (BOOL) ledOff{ return ledOff; }  //TODO: remove this and OREdelweissFLTModelInterruptMaskChanged  -tb-
- (void) setLedOff:(BOOL)aState
{
    ledOff = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelLedOffChanged object:self];
}

- (uint32_t) interruptMask { return interruptMask; }
- (void) setInterruptMask:(uint32_t)aInterruptMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    interruptMask = aInterruptMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelInterruptMaskChanged object:self];
}

- (void) setTotalRate:(ORTimeRate*)newTimeRate
{
	[totalRate autorelease];
	totalRate=[newTimeRate retain];
}

- (unsigned short) hitRateLength { return hitRateLength; }
- (void) setHitRateLength:(unsigned short)aHitRateLength
{	
 	//DEBUG   -tb-   NSLog(@"%@::%@ aHitRateLength: %i   old: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aHitRateLength,hitRateLength);//TODO: DEBUG testing ...-tb-

    [[[self undoManager] prepareWithInvocationTarget:self] setHitRateLength:hitRateLength];
    hitRateLength = [self restrictIntValue:aHitRateLength min:0 max:8]; //new 2014-11: 0->1sec, 1->2, 2->4, 3->8 .... sec etc   //before 2014-11: 0->1sec, 1->2, 2->3 .... sec

    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelHitRateLengthChanged object:self];
}

- (uint32_t) hitRateEnabledMask { return hitRateEnabledMask; }
- (void) setHitRateEnabledMask:(uint32_t)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setHitRateEnabledMask:hitRateEnabledMask];
    hitRateEnabledMask = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelHitRateEnabledMaskChanged object:self];
}

- (void) setHitRateEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
	if(aChan<kNumEWFLTHeatIonChannels){
        uint32_t mask = hitRateEnabledMask;
	    if(aState) mask |= (1L<<aChan);
	    else       mask &= ~(1L<<aChan);
        [self setHitRateEnabledMask: mask];
    }
}

- (BOOL) hitRateEnabled:(unsigned short) aChan
{
	if(aChan<kNumEWFLTHeatIonChannels) return (hitRateEnabledMask >> aChan) & 0x1;
    return 0;
}




- (NSMutableArray*) gains { return gains; }
- (void) setGains:(NSMutableArray*)aGains
{
	[aGains retain];
	[gains release];
    gains = aGains;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelGainsChanged object:self];
}



- (NSMutableArray*) thresholds { return thresholds; }
- (void) setThresholds:(NSMutableArray*)aThresholds
{
	[aThresholds retain];
	[thresholds release];
    thresholds = aThresholds;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelThresholdsChanged object:self];
}

- (NSMutableArray*) triggerParameter { return triggerParameter; }
- (void) setTriggerParameter:(NSMutableArray*)aTriggerParameter
{
	[aTriggerParameter retain];
	[triggerParameter release];
    triggerParameter = aTriggerParameter;
}


- (void) readTriggerParameters
{
        NSLog(@"READ TriggerParameters\n");
        NSLog(@"----------------------------\n");
    int i;
    for(i=0;i<kNumEWFLTHeatIonChannels;i++){
        uint32_t val=[self readTriggerPar:i];
        [self setTriggerPar: i withValue: val];
        //triggerPar[i]=val;
        NSLog(@"TriggerParameter[%i]: 0x%08x\n",i,triggerPar[i]);
    }    
    
    //[[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerParameterChanged object:self];

    //TODO: make own action -tb-
    [self readThresholds];
}

- (void) writeTriggerParametersVerbose
{
        NSLog(@"WRITE TriggerParameters\n");
        NSLog(@"----------------------------\n");
    int i;
    for(i=0;i<kNumEWFLTHeatIonChannels;i++){
        NSLog(@"TriggerParameter[%i]: 0x%08x\n",i,triggerPar[i]);
        [self writeTriggerPar:i value:triggerPar[i]];
    }    

    //TODO: make own action -tb-
    [self writeThresholds];
}

- (void) writeTriggerParameters
{
    int i;
    for(i=0;i<kNumEWFLTHeatIonChannels;i++){
        //NSLog(@"TriggerParameter[%i]: 0x%08x\n",i,triggerPar[i]);
        [self writeTriggerPar:i value:triggerPar[i]];
    }    

    //TODO: make own action -tb-
    [self writeThresholds];
}

- (void) writeTriggerParametersDisableAll
{
    int i;
    for(i=0;i<kNumEWFLTHeatIonChannels;i++){
        //NSLog(@"TriggerParameter[%i]: 0x%08x\n",i,triggerPar[i]);
        [self writeTriggerPar:i value: (triggerPar[i] & 0xffff7fff)];//set ENABLE flag to zero
    }    

    //TODO: make own action -tb-
    [self writeThresholds];
}

- (void) dumpTriggerParameters
{
        NSLog(@"TriggerParameters\n");
        NSLog(@"----------------------------\n");
    int i;
    for(i=0;i<kNumEWFLTHeatIonChannels;i++){
        NSLog(@"TriggerParameter[%i]: 0x%08x\n",i,triggerPar[i]);
    }    
}

- (void) setTriggerPar:(unsigned short)chan  withValue:(uint32_t) val
{
    if(chan>=kNumEWFLTHeatIonChannels){
        //DEBUG OUTPUT:
        NSLog(@"%@::%@: chan %i out of range (0...%i) \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),chan,kNumEWFLTHeatIonChannels-1);//TODO : DEBUG testing ...-tb-
        return;
    }
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerPar:chan withValue:triggerPar[chan]];
    triggerPar[chan]=val;
    [[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerParameterChanged object:self];
    [[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerEnabledMaskChanged object:self];
}

- (uint32_t) triggerPar:(unsigned short)chan
{
    if(chan<kNumEWFLTHeatIonChannels) return triggerPar[chan];
    return 0;
}





-(uint32_t) threshold:(unsigned short) aChan
{
    return [[thresholds objectAtIndex:aChan] intValue];
}

-(unsigned short) gain:(unsigned short) aChan
{
    return [[gains objectAtIndex:aChan] shortValue];
}

-(void) setThreshold:(unsigned short) aChan withValue:(uint32_t) aThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
	aThreshold = [self restrictUnsignedIntValue:(unsigned int)aThreshold min:0 max:0xffffffff];
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithUnsignedLong:aThreshold]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithUnsignedInt:aChan] forKey: OREdelweissFLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:OREdelweissFLTModelThresholdChanged
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain
{
//DEBUG OUTPUT:
 	NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	if(aGain>0xfff) aGain = 0xfff;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:aChan withValue:[self gain:aChan]];
	[gains replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aGain]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: OREdelweissFLTChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:OREdelweissFLTModelGainChanged
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

-(BOOL) triggerEnabled:(unsigned short) aChan
{
	if(aChan<kNumEWFLTHeatIonChannels) return (triggerPar[aChan] >> kEWFlt_TriggParReg_Enable_Shift) & kEWFlt_TriggParReg_Enable_Mask;

	//if(aChan<kNumV4FLTChannels)return (triggerEnabledMask >> aChan) & 0x1;
	//else 
	return NO;
}

-(void) setTriggerEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    if(aChan>=kNumEWFLTHeatIonChannels) return ;

    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerEnabled:aChan withValue:(triggerPar[aChan] >> kEWFlt_TriggParReg_Enable_Shift) & kEWFlt_TriggParReg_Enable_Mask];
	if(aState) triggerPar[aChan] |= (1L<<kEWFlt_TriggParReg_Enable_Shift);
	else       triggerPar[aChan] &= ~(1L<<kEWFlt_TriggParReg_Enable_Shift);
	
    [[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerEnabledMaskChanged object:self];
	[self postAdcInfoProvidingValueChanged];


#if 0
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerEnabled:aChan withValue:(triggerEnabledMask>>aChan)&0x1];
	if(aState) triggerEnabledMask |= (1L<<aChan);
	else triggerEnabledMask &= ~(1L<<aChan);
	
    [[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerEnabledMaskChanged object:self];
	[self postAdcInfoProvidingValueChanged];
#endif
}

- (BOOL) negPolarity:(unsigned short) aChan
{
	if(aChan<kNumEWFLTHeatIonChannels) return (triggerPar[aChan] >> kEWFlt_TriggParReg_NegPolarity_Shift) & kEWFlt_TriggParReg_NegPolarity_Mask;
	return NO;
}

- (void) setNegPolarity:(unsigned short) aChan withValue:(BOOL) aState
{
    if(aChan>=kNumEWFLTHeatIonChannels) return ;

    [[[self undoManager] prepareWithInvocationTarget:self] setNegPolarity:aChan withValue:(triggerPar[aChan] >> kEWFlt_TriggParReg_NegPolarity_Shift) & kEWFlt_TriggParReg_NegPolarity_Mask];
	if(aState) triggerPar[aChan] |= (1L<<kEWFlt_TriggParReg_NegPolarity_Shift);
	else       triggerPar[aChan] &= ~(1L<<kEWFlt_TriggParReg_NegPolarity_Shift);
	
    [[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerParameterChanged object:self];
	//??? [self postAdcInfoProvidingValueChanged];
}

- (BOOL) posPolarity:(unsigned short) aChan
{
	if(aChan<kNumEWFLTHeatIonChannels) return (triggerPar[aChan] >> kEWFlt_TriggParReg_PosPolarity_Shift) & kEWFlt_TriggParReg_PosPolarity_Mask;
	return NO;
}
- (void) setPosPolarity:(unsigned short) aChan withValue:(BOOL) aState
{
    if(aChan>=kNumEWFLTHeatIonChannels) return ;

    [[[self undoManager] prepareWithInvocationTarget:self] setPosPolarity:aChan withValue:(triggerPar[aChan] >> kEWFlt_TriggParReg_PosPolarity_Shift) & kEWFlt_TriggParReg_PosPolarity_Mask];
	if(aState) triggerPar[aChan] |= (1L<<kEWFlt_TriggParReg_PosPolarity_Shift);
	else       triggerPar[aChan] &= ~(1L<<kEWFlt_TriggParReg_PosPolarity_Shift);
	
    [[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerParameterChanged object:self];
	//??? [self postAdcInfoProvidingValueChanged];
}


- (int) gapLength:(unsigned short) aChan
{
	if(aChan<kNumEWFLTHeatIonChannels) return (triggerPar[aChan] >> kEWFlt_TriggParReg_Gap_Shift) & kEWFlt_TriggParReg_Gap_Mask;
	return 0;
}
- (void) setGapLength:(unsigned short) aChan withValue:(int) aLength
{
    if(aChan>=kNumEWFLTHeatIonChannels) return ;

    [[[self undoManager] prepareWithInvocationTarget:self] setGapLength:aChan withValue:(triggerPar[aChan] >> kEWFlt_TriggParReg_Gap_Shift) & kEWFlt_TriggParReg_Gap_Mask];
	triggerPar[aChan] &= ~(kEWFlt_TriggParReg_Gap_Mask<<kEWFlt_TriggParReg_Gap_Shift);
	triggerPar[aChan] |=  ((aLength & kEWFlt_TriggParReg_Gap_Mask)<<kEWFlt_TriggParReg_Gap_Shift);
	
    [[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerParameterChanged object:self];
	//??? [self postAdcInfoProvidingValueChanged];
}


- (int) downSampling:(unsigned short) aChan
{
	if(aChan<kNumEWFLTHeatIonChannels) return (triggerPar[aChan] >> kEWFlt_TriggParReg_DownSamp_Shift) & kEWFlt_TriggParReg_DownSamp_Mask;
	return 0;
}
- (void) setDownSampling:(unsigned short) aChan withValue:(int) aValue
{
    if(aChan>=kNumEWFLTHeatIonChannels) return ;

    [[[self undoManager] prepareWithInvocationTarget:self] setDownSampling:aChan withValue:(triggerPar[aChan] >> kEWFlt_TriggParReg_DownSamp_Shift) & kEWFlt_TriggParReg_DownSamp_Mask];
	triggerPar[aChan] &= ~(kEWFlt_TriggParReg_DownSamp_Mask<<kEWFlt_TriggParReg_DownSamp_Shift);
	triggerPar[aChan] |=  ((aValue & kEWFlt_TriggParReg_DownSamp_Mask)<<kEWFlt_TriggParReg_DownSamp_Shift);
	
    //DEBUG NSLog(@"triggerPar[aChan] (chan:%i): 0x%08x\n",aChan,triggerPar[aChan]);
    [[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerParameterChanged object:self];
	//??? [self postAdcInfoProvidingValueChanged];
}


- (int) shapingLength:(unsigned short) aChan
{
//DEBUG OUTPUT: 	NSLog(@"%@::%@: UNDER CONSTRUCTION! aChan %i,  s-length %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aChan, (triggerPar[aChan] >> kEWFlt_TriggParReg_ShapingL_Shift) & kEWFlt_TriggParReg_ShapingL_Mask);//TODO: DEBUG testing ...-tb-
	if(aChan<kNumEWFLTHeatIonChannels) return (triggerPar[aChan] >> kEWFlt_TriggParReg_ShapingL_Shift) & kEWFlt_TriggParReg_ShapingL_Mask;
	return 0;
}
- (void) setShapingLength:(unsigned short) aChan withValue:(int) aLength
{
//DEBUG OUTPUT: 	NSLog(@"%@::%@: UNDER CONSTRUCTION! aChan %i,  aLength %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aChan, aLength);//TODO: DEBUG testing ...-tb-

    if(aChan>=kNumEWFLTHeatIonChannels) return ;

    [[[self undoManager] prepareWithInvocationTarget:self] setShapingLength:aChan withValue:(triggerPar[aChan] >> kEWFlt_TriggParReg_ShapingL_Shift) & kEWFlt_TriggParReg_ShapingL_Mask];
	triggerPar[aChan] &= ~(kEWFlt_TriggParReg_ShapingL_Mask<<kEWFlt_TriggParReg_ShapingL_Shift);
	triggerPar[aChan] |=  ((aLength & kEWFlt_TriggParReg_ShapingL_Mask)<<kEWFlt_TriggParReg_ShapingL_Shift);
	
    [[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerParameterChanged object:self];
	//??? [self postAdcInfoProvidingValueChanged];
}



- (int) windowPosStart:(unsigned short) aChan
{
//DEBUG OUTPUT: 	NSLog(@"%@::%@: UNDER CONSTRUCTION! aChan %i,  winPosStart %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aChan, (triggerPar[aChan] >> kEWFlt_TriggParReg_WinStart_Shift) & kEWFlt_TriggParReg_WinStart_Mask);//TODO: DEBUG testing ...-tb-
	if(aChan<kNumEWFLTHeatChannels) return (triggerPar[aChan] >> kEWFlt_TriggParReg_WinStart_Shift) & kEWFlt_TriggParReg_WinStart_Mask;
	return 0;
}

- (void) setWindowPosStart:(unsigned short) aChan withValue:(int) aLength
{
    if(aChan>=kNumEWFLTHeatChannels) return ;

    [[[self undoManager] prepareWithInvocationTarget:self] setWindowPosStart:aChan withValue:(triggerPar[aChan] >> kEWFlt_TriggParReg_WinStart_Shift) & kEWFlt_TriggParReg_WinStart_Mask];
	triggerPar[aChan] &= ~(kEWFlt_TriggParReg_WinStart_Mask<<kEWFlt_TriggParReg_WinStart_Shift);
	triggerPar[aChan] |=  ((aLength & kEWFlt_TriggParReg_WinStart_Mask)<<kEWFlt_TriggParReg_WinStart_Shift);
	
    [[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerParameterChanged object:self];
	//??? [self postAdcInfoProvidingValueChanged];
}

- (int) windowPosEnd:(unsigned short) aChan
{
	if(aChan<kNumEWFLTHeatChannels) return (triggerPar[aChan] >> kEWFlt_TriggParReg_WinEnd_Shift) & kEWFlt_TriggParReg_WinEnd_Mask;
	return 0;
}

- (void) setWindowPosEnd:(unsigned short) aChan withValue:(int) aLength
{
    if(aChan>=kNumEWFLTHeatChannels) return ;

    [[[self undoManager] prepareWithInvocationTarget:self] setWindowPosEnd:aChan withValue:(triggerPar[aChan] >> kEWFlt_TriggParReg_WinEnd_Shift) & kEWFlt_TriggParReg_WinEnd_Mask];
	triggerPar[aChan] &= ~(kEWFlt_TriggParReg_WinEnd_Mask<<kEWFlt_TriggParReg_WinEnd_Shift);
	triggerPar[aChan] |=  ((aLength & kEWFlt_TriggParReg_WinEnd_Mask)<<kEWFlt_TriggParReg_WinEnd_Shift);
	
    [[NSNotificationCenter defaultCenter]postNotificationName:OREdelweissFLTModelTriggerParameterChanged object:self];
	//??? [self postAdcInfoProvidingValueChanged];
}






- (void) enableAllHitRates:(BOOL)aState
{
//DEBUG OUTPUT:
 	NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	[self setHitRateEnabledMask:aState?0x3ffff:0x0];
}

- (void) enableAllTriggers:(BOOL)aState
{
//DEBUG OUTPUT:
 	NSLog(@"%@::%@: aState: 0x%x - UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aState);//TODO: DEBUG testing ...-tb-
	//TODO: [self setTriggerEnabledMask:aState?0xffffff:0x0];
    int aChan;
    for(aChan=0; aChan<kNumEWFLTHeatIonChannels; aChan++)
        [self setTriggerEnabled: aChan withValue:aState];
}

- (void) setHitRateTotal:(float)newTotalValue
{
	hitRateTotal = newTotalValue;
	if(!totalRate){
		[self setTotalRate:[[[ORTimeRate alloc] init] autorelease]];
	}
	[totalRate addDataToTimeAverage:hitRateTotal];
}

- (float) hitRateTotal 
{ 
	return hitRateTotal; 
}

- (float) hitRate:(unsigned short)aChan
{
	if(aChan<kNumEWFLTHeatIonChannels){
		return hitRate[aChan];
	}
	else return 0.0;
}



- (float) rate:(int)aChan { return [self hitRate:aChan]; }
- (BOOL) hitRateOverFlow:(unsigned short)aChan
{
	if(aChan<kNumEWFLTHeatIonChannels)return hitRateOverFlow[aChan];
	else return NO;
}

- (BOOL) hitRateRegulationIsOn:(unsigned short)aChan
{    return (hitRateReg[aChan] & 0x10000)!=0;}


- (unsigned short) selectedChannelValue { return selectedChannelValue; }
- (void) setSelectedChannelValue:(unsigned short) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannelValue:selectedChannelValue];
    selectedChannelValue = aValue;
    [[NSNotificationCenter defaultCenter]	 postNotificationName:OREdelweissFLTSelectedChannelValueChanged	 object:self];
}

- (unsigned short) selectedRegIndex { return selectedRegIndex; }
- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:selectedRegIndex];
    selectedRegIndex = anIndex;
    [[NSNotificationCenter defaultCenter]	 postNotificationName:OREdelweissFLTSelectedRegIndexChanged	 object:self];
}

- (uint32_t) writeValue { return writeValue; }
- (void) setWriteValue:(uint32_t) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    writeValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTWriteValueChanged object:self];
}

- (NSString*) getRegisterName: (short) anIndex
{
    return regV4[anIndex].regName;
}

- (uint32_t) getAddressOffset: (short) anIndex
{
    return( regV4[anIndex].addressOffset );
}

- (short) getAccessType: (short) anIndex
{
	return regV4[anIndex].accessType;
}

- (void) setToDefaults
{
//TODO: setToDefaults UNDER CONSTRUCTION -tb-
//DEBUG OUTPUT:
 	NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	int i;
	for(i=0;i<kNumEWFLTHeatIonChannels;i++){
		[self setThreshold:i withValue:17000];
		[self setGain:i withValue:0];
	}
	[self setGapLength:0];
	[self setFilterLength:6];
	[self setFifoBehaviour:kFifoEnableOverFlow];// kFifoEnableOverFlow or kFifoStopOnFull
	[self setPostTriggerTime:300]; // max. filter length should fit into the range -tb-
	
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢HW Access
- (uint32_t) readFiberOutMask
{
	uint32_t value = [self readReg:kFLTV4FiberOutMaskReg];
        //DEBUG OUTPUT: 	        NSLog(@"%@::%@: UNDER CONSTRUCTION! read 0x%x\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),value);//TODO : DEBUG testing ...-tb-
    [self setFiberOutMask: value];
	return value;
}

- (void) writeFiberOutMask
{
    uint32_t aValue = fiberOutMask;
        //DEBUG OUTPUT: 	        NSLog(@"%@::%@: UNDER CONSTRUCTION!  write 0x%x\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aValue);//TODO : DEBUG testing ...-tb-
	[self writeReg: kFLTV4FiberOutMaskReg value:aValue];
}


- (uint32_t)  readVersion
{	
    #if 0 //test - currently this results in infinite recursion !  -tb-
    uint32_t val=0;
	[self readBlock: kFLTV4VersionReg dataBuffer: &val length: 1 ];
    return val;
    #endif
    #if 0 //test - currently this results in infinite recursion !  -tb-
    uint32_t val=0;
	//[self readBlock: kFLTV4VersionReg dataBuffer: &val length: 1 ];
    uint32_t address=  [self regAddress:kFLTV4VersionReg]  ;
	[self readBlock: address dataBuffer: &val length: 1  increment: 1 ];
    return val;
    #endif
	return [self readReg: kFLTV4VersionReg];
}



- (int) readMode
{
	return ([self readControl]>>16) & 0xf;
}

- (void) loadThresholdsAndGains
{
//TODO: loadThresholdsAndGains UNDER CONSTRUCTION -tb- 2012-07-19
//TODO: loadThresholdsAndGains UNDER CONSTRUCTION -tb- 2012-07-19
#if 0
	//use the command list to load all the thresholds and gains with one PMC command packet
	int i;
	ORCommandList* aList = [ORCommandList commandList];
	for(i=0;i<kNumV4FLTChannels;i++){
		uint32_t thres;
		if( !(triggerEnabledMask & (0x1<<i)) )	thres = 0xfffff;
		else									thres = [self threshold:i];
		[aList addCommand: [self writeRegCmd:kFLTV4ThresholdReg channel:i value:thres & 0xFFFFF]];
		[aList addCommand: [self writeRegCmd:kFLTV4GainReg channel:i value:[self gain:i] & 0xFFF]];
	}
	[aList addCommand: [self writeRegCmd:kFLTV4CommandReg value:kIpeFlt_Cmd_LoadGains]];
	
	[self executeCommandList:aList];
    
#endif
}

- (int) restrictIntValue:(int)aValue min:(int)aMinValue max:(int)aMaxValue
{
	if(aValue<aMinValue)	  return aMinValue;
	else if(aValue>aMaxValue) return aMaxValue;
	else					  return aValue;
}

- (unsigned int) restrictUnsignedIntValue:(unsigned int)aValue min:(unsigned int)aMinValue max:(unsigned int)aMaxValue;
{
	if(aValue<aMinValue)	  return aMinValue;
	else if(aValue>aMaxValue) return aMaxValue;
	else					  return aValue;
}

- (float) restrictFloatValue:(int)aValue min:(float)aMinValue max:(float)aMaxValue
{
	if(aValue<aMinValue)	  return aMinValue;
	else if(aValue>aMaxValue) return aMaxValue;
	else					  return aValue;
}

- (void) enableStatistics
{
#if (0)
    uint32_t aValue;
	bool enabled = true;
	uint32_t adc_guess = 150;			// This are parameter that work with the standard Auger-type boards
	uint32_t n = 65000;				// There is not really a need to make them variable. ak 7.10.07
	
    aValue =     (  ( (uint32_t) (enabled  &   0x1) ) << 31)
	| (  ( (uint32_t) (adc_guess   & 0x3ff) ) << 16)
	|    ( (uint32_t) ( (n-1)  & 0xffff) ) ; // 16 bit !
	
	// Broadcast to all channel	(pseudo channel 0x1f)     
	[self writeReg:kFLTStaticSetReg channel:0x1f value:aValue]; 
	
	// Save parameter for calculation of mean and variance
	statisticOffset = adc_guess;
	statisticN = n;
#endif
}


- (void) getStatistics:(int)aChannel mean:(double *)aMean  var:(double *)aVar 
{
#if (0)
    uint32_t data;
	signed int32_t sum;
    uint32_t sumSq;
	
    // Read Statistic parameter
    data = [self  readReg:kFLTStaticSetReg channel:aChannel];
	statisticOffset = (data  >> 16) & 0x3ff;
	statisticN = (data & 0xffff) +1;
	
	
    // Read statistics
	// The sum is a 25bit signed number.
	sum = [self readReg:kFLTSumXReg channel:aChannel];
	// Move the sign
	sum = (sum & 0x01000000) ? (sum | 0xFE000000) : (sum & 0x00FFFFFF);
	
    // Read the sum of squares	
	sumSq = [self readReg:kFLTSumX2Reg channel:aChannel];
	
	//NSLog(@"data = %x Offset = %d, n = %d, sum = %08x, sum2 = %08x\n", data, statisticOffset, statisticN, sum, sumSq);
	
	// Calculate mean and variance
	if (statisticN > 0){
		*aMean = (double) sum / statisticN + statisticOffset;
		*aVar = (double) sumSq / statisticN 
		- (double) sum / statisticN * sum / statisticN;
    } else {
		*aMean = -1; 
		*aVar = -1;
	}
#endif
}


- (void) initBoard
{
	[self writeControl];
	[self writeStreamMask];//TODO: is this necessary? we want event mode but this is for stream mode -tb-
	[self writeFiberOutMask];//TODO: is this necessary? we want event mode but this is for stream mode -tb-
	[self writeFiberDelays];
    
	
    [self initTrigger];
}

- (void) initTrigger
{
    [self writeHeatTriggerMask];
    [self writeIonTriggerMask];
    [self writeTriggerParameters];
    [self writePostTriggerTimeAndIonToHeatDelay];
    [self writeRunControl];//this is the hitrate period

}

- (void) readAll
{
	[self readControl];
	[self readStreamMask];
	[self readFiberOutMask];
	[self readFiberDelays];
}



- (uint32_t) readStatus
{
    uint32_t status = [self readReg: kFLTV4StatusReg ];
 	NSLog(@"%@::%@ status: 0x%08x\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),status);//TODO: DEBUG testing ...-tb-
	[self setStatusRegister:status];
	return status;
}

- (uint32_t) readTotalTriggerNRegister 
{
    int n = (int)[self readReg: kFLTV4TotalTriggerNReg ];
 	NSLog(@"%@::%@ status: 0x%08x\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),n);//TODO: DEBUG testing ...-tb-
	[self setTotalTriggerNRegister: n ];
	return n;
}

- (uint32_t) readControl
{
	uint32_t control = [self readReg: kFLTV4ControlReg];
    [self setControlRegister: control];
	return control;
}


//TODO: we write the hitrate regulation limits, too; currently we have only one "Write" button in the GUI ...; make a button in the future! -tb- 2014-11
- (void) writeRunControl
{
 	//DEBUG     NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-

    //  never used: uint32_t highestBit = fls(hitRateLengthSec); if(highestBit) highestBit --;
	//  never used:  uint32_t aValue = ((highestBit) & 0xf) << 16 ;
	//uint32_t aValue = ((hitRateLength-1) & 0xf) << 16 ; //before 2014-11
	uint32_t aValue = ((hitRateLength) & 0xff) << 16 ;
	aValue |= 0x80000000;//activate flag
	[self writeReg:kFLTV4RunControlReg value:aValue];	
    
                    //TODO: write the	ThreshAdjust reg (hitrate regulation limits) , too	
    aValue =  ((hitrateLimitIon & 0xff) << 16)  | (hitrateLimitHeat & 0xff) ;
	[self writeReg:kFLTV4ThreshAdjustReg value:aValue];					
}

- (void) writeControl
{
    #if 0
	//uint32_t aValue =	((fltRunMode & 0xf)<<16) | 
	//((fifoBehaviour & 0x1)<<24) |
	//((ledOff & 0x1)<<1 );
	uint32_t aMode = 0;
	switch(fltModeFlags){
	case 0: //Normal
	    aMode = 0x0;
	    break;
	case 1: //TM-Order
	    aMode = 0x1;
	    break;
	case 2: //TM-Ramp
	    aMode = 0x2;
	    break;
	case 3: //TM-PB
	    aMode = 0x4;
	    break;
	}	

	
	uint32_t aValue =	
	((selectFiberTrig & 0x7)<<28) | 
	((fiberEnableMask & 0x3f)<<16) |
	((BBv1Mask & 0x3f)<<8 ) |
	((aMode & 0x7)<<4 );
	#endif
	
	uint32_t aValue =	controlRegister;
//DEBUG OUTPUT:
 	NSLog(@"%@::%@:   kFLTV4ControlReg: 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aValue);//TODO: DEBUG testing ...-tb-
    //DEBUG OUTPUT: 	NSLog(@"%@::%@:   selectFiberTrig: 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),selectFiberTrig);//TODO: DEBUG testing ...-tb-
	
	[self writeReg: kFLTV4ControlReg value:aValue];
}



- (void) writeStreamMask
{
    //NSLog(@"%@::%@:   kFLTV4ControlReg: 0x%016qx \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self streamMask]);//TODO: DEBUG testing ...-tb-
	uint32_t aValue =	[self streamMask1];
	[self writeReg: kFLTV4StreamMask_1Reg value:aValue];
	aValue =	[self streamMask2];
	[self writeReg: kFLTV4StreamMask_2Reg value:aValue];
}

- (void) readStreamMask
{
    //DEBUG OUTPUT:
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG testing ...-tb-
    uint64_t streamMask1=[self readReg: kFLTV4StreamMask_1Reg];
    uint64_t streamMask2=[self readReg: kFLTV4StreamMask_2Reg];
	uint64_t theStreamMask = (streamMask2 << 32) | streamMask1;
	[self setStreamMask: theStreamMask];
}



- (void) writeIonTriggerMask
{
    //NSLog(@"%@::%@:   kFLTV4ControlReg: 0x%016qx \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self streamMask]);//TODO: DEBUG testing ...-tb-
	uint32_t aValue =	[self ionTriggerMask1];
	[self writeReg: kFLTV4IonTriggerMask_1Reg value:aValue];
	aValue =	[self ionTriggerMask2];
	[self writeReg: kFLTV4IonTriggerMask_2Reg value:aValue];
}

- (void) readIonTriggerMask
{
    //DEBUG OUTPUT:
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG testing ...-tb-
    uint64_t mask1=[self readReg: kFLTV4IonTriggerMask_1Reg];
    uint64_t mask2=[self readReg: kFLTV4IonTriggerMask_2Reg];
	uint64_t theMask = (mask2 << 32) | mask1;
	[self setIonTriggerMask: theMask];
}


- (void) writeHeatTriggerMask
{
    //NSLog(@"%@::%@:   kFLTV4ControlReg: 0x%016qx \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self streamMask]);//TODO: DEBUG testing ...-tb-
	uint32_t aValue =	[self heatTriggerMask1];
	[self writeReg: kFLTV4HeatTriggerMask_1Reg value:aValue];
	aValue =	[self heatTriggerMask2];
	[self writeReg: kFLTV4HeatTriggerMask_2Reg value:aValue];
}

- (void) readHeatTriggerMask
{
    //DEBUG OUTPUT:
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG testing ...-tb-
    uint64_t mask1=[self readReg: kFLTV4HeatTriggerMask_1Reg];
    uint64_t mask2=[self readReg: kFLTV4HeatTriggerMask_2Reg];
	uint64_t theMask = (mask2 << 32) | mask1;
	[self setHeatTriggerMask: theMask];
}



	
- (void) writePostTriggerTimeAndIonToHeatDelay
{
	uint32_t aValue =	((postTriggerTime & 0xffff)<<16) | (ionToHeatDelay & 0xffff);
//DEBUG OUTPUT: 	NSLog(@"%@::%@:   kFLTV4Ion2HeatDelayReg: 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),aValue);//TODO: DEBUG testing ...-tb-
	
	[self writeReg: kFLTV4Ion2HeatDelayReg value:aValue];
}

- (void) readPostTriggerTimeAndIonToHeatDelay;
{
    uint32_t aValue = 0;
	aValue = [self readReg: kFLTV4Ion2HeatDelayReg];
    [self setPostTriggerTime: aValue>>16];
    [self setIonToHeatDelay: aValue & 0xffff];
}


- (void) writeTriggerPar:(int)i value:(uint32_t)aValue
{
	//aValue &= 0xfffff;
    if(i>=0 && i<kNumEWFLTHeatChannels)
    	[self writeReg: kFLTV4HeatTriggParReg channel:i value:aValue];
    if(i>=kNumEWFLTHeatChannels && i<(kNumEWFLTHeatChannels+kNumEWFLTIonChannels))
    	[self writeReg: kFLTV4IonTriggParReg channel:i-kNumEWFLTHeatChannels value:aValue];
}

- (uint32_t) readTriggerPar:(int)i
{
    if(i>=0 && i<kNumEWFLTHeatChannels)
	    return [self readReg:kFLTV4HeatTriggParReg channel:i];
    if(i>=kNumEWFLTHeatChannels && i<(kNumEWFLTHeatChannels+kNumEWFLTIonChannels))
        return [self readReg:kFLTV4IonTriggParReg channel:i-kNumEWFLTHeatChannels];
	return 0;
}





- (void) writeFiberDelays
{
 	//NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG testing ...-tb-
    uint32_t val=0;
	val = fiberDelays & 0xffffffffLL;
	[self writeReg: kFLTV4FiberSet_1Reg value:val];
	val = (fiberDelays & 0xffffffff00000000LL) >> 32;
	[self writeReg: kFLTV4FiberSet_2Reg value:val];
}

- (void) readFiberDelays
{
    //DEBUG OUTPUT:
 	NSLog(@"%@::%@ \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd) );//TODO: DEBUG testing ...-tb-
    uint64_t fiberDelays1=[self readReg: kFLTV4FiberSet_1Reg];
    uint64_t fiberDelays2=[self readReg: kFLTV4FiberSet_2Reg];
	uint64_t thefiberDelays = (fiberDelays2 << 32) | fiberDelays1;
	[self setFiberDelays: thefiberDelays];
}


- (void) writeCommandResync
{	[self writeReg: kFLTV4CommandReg value:kIpeFlt_Cmd_resync];   }

- (void) writeCommandTrigEvCounterReset
{	[self writeReg: kFLTV4CommandReg value:kIpeFlt_Cmd_TrigEvCountRes];   }

- (void) writeCommandSoftwareTrigger
{	[self writeReg: kFLTV4CommandReg value:kIpeFlt_Cmd_SWTrig];   }



- (void) devTabButtonAction
{
    //DEBUG 	    
    NSLog(@"%@::%@  THIS IS A TEST BUTTON  \n", NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
    
	ORSNMP* ss = [[ORSNMP alloc] initWithMib: @"GUDEADS-EPC1200-MIB"];
	[ss openPublicSession:@"192.168.1.104"];
    //NSString *valueName= [NSString stringWithString:@"epc1200PortState.1"];
    //NSLog(@"Request value: %@\n",valueName);
	//NSArray* response = [ss readValue: valueName];
    

    NSArray *valueNames= [NSArray arrayWithObjects: @"epc1200PortState.1", @"epc1200PortState.2", nil];
    //NSString *valueName= [NSString stringWithString:@"epc1200PortState.1"];
    NSLog(@"Request values: %@\n",valueNames);
	NSArray* response = [ss readValues: valueNames];
	//if(verbose)
    for(id anEntry in response) NSLog(@"Reponse: %@\n",anEntry);
	[ss release];
	//[ORTimer delay:.05];
    
    
/* response of
    NSArray *valueNames= [NSArray arrayWithObjects: @"epc1200PortState.1", @"epc1200PortState.2", nil];
    NSString *valueName= [NSString stringWithString:@"epc1200PortState.1"];
    NSLog(@"Request values: %@\n",valueNames);
	NSArray* response = [ss readValues: valueNames];




    
    102813 16:54:25 Request values: (
    "epc1200PortState.1",
    "epc1200PortState.2"
)
102813 16:54:25 Reponse: {
    Mib = "GUDEADS-EPC1200-MIB";
    Name = epc1200PortState;
    SystemIndex = 0;
    Type = INTEGER;
    Value = 1;
}
102813 16:54:25 Reponse: {
    Mib = "GUDEADS-EPC1200-MIB";
    Name = epc1200PortState;
    SystemIndex = 0;
    Type = INTEGER;
    Value = 0;
}
*/

    {
	ORSNMP*  ss = [[ORSNMP alloc] initWithMib: @"GUDEADS-EPC1200-MIB"];
	[ss openSession:@"192.168.1.104"  community:@"private"];// I cannot use ORSNMPWriteOperation as I need community "private" (ORSNMPWriteOperation uses "guru") -tb- 2013
    NSString* valueName= @"epc1200PortState.1 i 0";
	NSArray*  response = [ss writeValue: valueName];
    for(id anEntry in response) NSLog(@"Reponse: %@\n",anEntry);
	[ss release];
    }




}

- (void) killChargeBBJobButtonAction
{
    //DEBUG 	    
    NSLog(@"%@::%@   \n", NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
    
    [[[self crate] adapter] killSBCJob];
}



- (void) chargeBBWithFile:(NSString*) aFile
{
    //DEBUG 	    
    NSLog(@"%@::%@  test: %@\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),aFile);//TODO: DEBUG testing ...-tb-
    char filename[4*1024+1];
    uint32_t numBytes=0;
    if([aFile getCString: filename maxLength: 4*1024 encoding:NSASCIIStringEncoding]){//or use [... cStringUsingEncoding: NSASCIIStringEncoding]
        numBytes=(uint32_t)strlen(filename)+1;//+1 : I need the terminating /0
        OREdelweissSLTModel *slt=0;
        slt=[[self crate] adapter];
        [slt   chargeBBWithFile:filename numBytes:numBytes];
        NSLog(@"%@::%@  loading %@ - BB CHARGED - DONE!\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),aFile);//TODO: DEBUG testing ...-tb-
    }else{
        NSLog(@"%@::%@  ERROR: could not convert filename: %@ - BB NOT CHARGED!\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),aFile);//TODO: DEBUG testing ...-tb-
    }
}



- (void) killChargeFICJobButtonAction
{
    //DEBUG 	    
    NSLog(@"%@::%@   \n", NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
    
    [[[self crate] adapter] killSBCJob];
}



- (int) chargeFICWithDataFromFile:(NSString*)aFilename
{
    NSLog(@"%@::%@  \n", NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
	NSData* theData = [NSData dataWithContentsOfFile:aFilename];
	if(![theData length]){
		//[NSException raise:@"No FIC FPGA Configuration Data" format:@"Couldn't open FIC ConfigurationFile: %@",[aFilename stringByAbbreviatingWithTildeInPath]];
		NSLog(@"%@::%@ ERROR: No FIC FPGA Configuration Data - Couldn't open FIC ConfigurationFile: %@\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),[aFilename stringByAbbreviatingWithTildeInPath]);
		return 0;
	}
    
    OREdelweissSLTModel *slt=0;
    slt=[[self crate] adapter];

    [slt chargeFICusingSBCinBackgroundWithData:theData forFLT:self];


    return (int)[theData length];
}






- (void) sendWCommand
{
    OREdelweissSLTModel *slt=0;
    slt=[[self crate] adapter];
    //DEBUG 	    
    NSLog(@"%@::%@  test: %@\n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),NSStringFromClass([slt class]));//TODO: DEBUG testing ...-tb-

    char bytes[16];
    int i=0;
    /*
    //a test
    bytes[i]=0xf0;     i++;
    bytes[i]=0x01;     i++;
    bytes[i]=0x02;     i++;
    bytes[i]=0x03;     i++;
    bytes[i]=0x04;     i++;
    bytes[i]=0x05;     i++;
    bytes[i]=0x23;     i++;
    */

    /*a other test: switch to IdMode
    bytes[i]='W';      i++;
    bytes[i]=0xf0;     i++;
    bytes[i]=0x11;     i++;
    bytes[i]=0x08;     i++;
    bytes[i]=0x00;     i++;
    bytes[i]=0x01;     i++; //1=IdMode on; 2=off
    */
    bytes[i]='W';      i++;
    bytes[i]=0xf0;     i++;
    if([self useBroadcastIdforBBAccess]){  bytes[i]=0xff;     i++;}
    else                                {  bytes[i]=0xff & [self idBBforBBAccessForFiber:  fiberSelectForBBAccess];     i++;}
    bytes[i]=0xff & wCmdCode;     i++;
    bytes[i]=0xff & wCmdArg1;     i++;
    bytes[i]=0xff & wCmdArg2;     i++; //1=IdMode on; 2=off
    [slt writeToCmdFIFO:bytes numBytes:i];

}

- (void) sendWCommandIdBB:(int) idBB cmd:(int) cmd arg1:(int) arg1  arg2:(int) arg2
{

    //DEBUG 	    
    NSLog(@"%@::%@  write 0x%x  0x%x  0x%x  0x%x \n", NSStringFromClass([self class]),NSStringFromSelector(_cmd),
    0xff & idBB,  0xff & cmd  ,  0xff & arg1  ,  0xff & arg2  );//TODO: DEBUG testing ...-tb-


    OREdelweissSLTModel *slt=0;
    slt=[[self crate] adapter];
    char bytes[16];
    int i=0;
    bytes[i]='W';      i++;
    bytes[i]=0xf0;     i++;
    bytes[i]=0xff & idBB;     i++;
    bytes[i]=0xff & cmd;     i++;
    bytes[i]=0xff & arg1;     i++;
    bytes[i]=0xff & arg2;     i++;
    [slt writeToCmdFIFO:bytes numBytes:i];

}


//for call from "BB Access"
- (void) readBBStatusForBBAccess
{
    int fiber = [self fiberSelectForBBAccess];

        //DEBUG OUTPUT:           NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO : DEBUG testing ...-tb-
        NSLog(@"  Read BB status bits from FLT %i, fiber in #%i\n",[self stationNumber],fiberSelectForBBAccess);//TODO : DEBUG testing ...-tb-
        
        //uint32_t BBStatus32[30];
        //uint16_t *BBStatus16 = (uint16_t *)BBStatus32;
        uint32_t *BBStatus32=statusBitsBB[fiber];
        uint16_t *BBStatus16 = (uint16_t *)&BBStatus32[0];
        
        int i;
        
        @try{//I could omit it here because I catch exceptions in the controller (see comment below) -tb-
        
        #if 0
        for(i=0;i<30;i++){
            //BBStatus32[i]=i*2+i*0x10000; // for testing without hardware
            BBStatus32[i]= [self readReg:kFLTV4BBStatusReg channel:fiberSelectForBBStatusBits  index:i];
        }
        #else
        uint32_t address = [self regAddress:kFLTV4BBStatusReg channel:fiber index:0];
        [self readBlock: address
		     dataBuffer: (uint32_t*) BBStatus32
			     length:  30 
		      increment:  0];
        #endif
        
        }
		@catch(NSException* e){
			NSLog(@"Could not read status bits because of exception -%@- with reason -%@-\n",[e name],[e reason]);
            [e raise];//give exception over to higher/calling level -tb-
            return;
		}
        
        // we re-use this notification, it will have the same effect as OREdelweissFLTModelStatusBitsBBDataChanged ...
        [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelFiberSelectForBBAccessChanged object:self];
        
        
        
		//	NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
        NSFont* aFont = [NSFont fontWithName:@"Monaco" size:9];

        NSLogFont(aFont,@"Read BBStatBits of fiber #%i \n",fiber+1);
        NSString *s = [[NSString alloc] initWithString: @""];
        for(i=0;i<58;i++){
            //BBStatus16[i]=i*2+i*0x10000;
            s = [s stringByAppendingFormat:@"(%2i) 0x%04x; ", i,BBStatus16[i] ];
            if( ((i+1) % 10)== 0){
                NSLogFont(aFont,@"BBStatBits:%@\n",s);
                s=@"";
            }
        }
        if([s length]!= 0)        NSLogFont(aFont,@"BBStatBits:%@\n",s);
        
        
        
        
}


//for call from "Low Level"
- (void) readBBStatusBits
{

static int counter=0;
        //DEBUG OUTPUT:           NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO : DEBUG testing ...-tb-
        //NSLog(@"  read from fiber in #%i\n",fiberSelectForBBStatusBits);//TODO : DEBUG testing ...-tb-
        
        uint32_t BBStatus32[30];
        uint16_t *BBStatus16 = (uint16_t *)BBStatus32;
        
        int i;
        
        @try{//I could omit it here because I catch exceptions in the controller (see comment below) -tb-
        
        #if 0
        for(i=0;i<30;i++){
            //BBStatus32[i]=i*2+i*0x10000; // for testing without hardware
            BBStatus32[i]= [self readReg:kFLTV4BBStatusReg channel:fiberSelectForBBStatusBits  index:i];
        }
        #else
        uint32_t address = [self regAddress:kFLTV4BBStatusReg channel:fiberSelectForBBStatusBits index:0];
        [self readBlock: address
		     dataBuffer: (uint32_t*) BBStatus32
			     length:  30 
		      increment:  0];
        #endif
        
        }
		@catch(NSException* e){
			NSLog(@"Could not read status bits because of exception -%@- with reason -%@-\n",[e name],[e reason]);
            [e raise];//give exception over to higher/calling level -tb-
            return;
		}
        
        
        
        
		//	NSFont* aFont = [NSFont userFixedPitchFontOfSize:9];
        NSFont* aFont = [NSFont fontWithName:@"Monaco" size:9];

        NSLogFont(aFont,@"Read BBStatBits of fiber #%i (callCode %i)\n",fiberSelectForBBStatusBits+1,counter);
counter++;
        NSString *s = [[NSString alloc] initWithString: @""];
        for(i=0;i<58;i++){
            //BBStatus16[i]=i*2+i*0x10000;
            s = [s stringByAppendingFormat:@"(%2i) 0x%04x; ", i,BBStatus16[i] ];
            if( ((i+1) % 10)== 0){
                NSLogFont(aFont,@"BBStatBits:%@\n",s);
                s=@"";
            }
        }
        if([s length]!= 0)        NSLogFont(aFont,@"BBStatBits:%@\n",s);
        
        
        
        
}

- (void) readAllBBStatusBits
{
        //DEBUG OUTPUT:         
        NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO : DEBUG testing ...-tb-
}



- (void) readTriggerData
{
//DEBUG OUTPUT:
 	NSLog(@"%@::%@: UNDER CONSTRUCTION! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO: DEBUG testing ...-tb-
    uint32_t totalTriggerN = [self readReg:kFLTV4TotalTriggerNReg];
 	NSLog(@" totalTriggerN: %i\n",totalTriggerN);//TODO: DEBUG testing ...-tb-
    uint32_t TriggChannels = [self readReg:kFLTV4TriggChannelsReg];
 	NSLog(@" TriggChannels: 0x%08x\n",TriggChannels);//TODO: DEBUG testing ...-tb-
 	NSLog(@"     adress:   0x%x\n",TriggChannels & 0x7ff);//TODO: DEBUG testing ...-tb-
 	NSLog(@"     heatMask: 0x%x\n",(TriggChannels >>12) & 0x3f);//TODO: DEBUG testing ...-tb-
 	NSLog(@"     ionMask:  0x%x\n",(TriggChannels >>18) & 0xfff);//TODO: DEBUG testing ...-tb-
    uint32_t allTriggerMask = (TriggChannels >>12) & 0x3ffff;
 	NSLog(@"     allTriggerMask:  0x%x\n",allTriggerMask);//TODO: DEBUG testing ...-tb-
 	NSLog(@" selectFiberTrig (obsolete?): %i\n",selectFiberTrig);//TODO: DEBUG testing ...-tb-
	int num=2048;//MUST be > 48 (DMA block size)! max. 2048
	int shownum=2048;//MUST be < num!
	int numChan=kNumEWFLTHeatIonChannels;
	//numChan=1;

    #if 1
    //uint32_t buf[2048];
    uint32_t  buf[2048];
    int i,chan;
    for(chan=0; chan<numChan;chan++){
        if(allTriggerMask & (0x1<<chan)){
            //-----> NSLog(@" ------------- chan: %i \n",chan);
            uint32_t energy=[self readReg: kFLTV4TriggEnergyReg channel:chan];
            uint32_t energy2=(~(0xff000000 | energy))+1;
            printf(" ------------- chan: %i -> energy %u (0x%08x) energy2 %i  (0x%08x) \n",chan,energy,energy,energy2,energy2);
            NSLog(@" ------------- chan: %i -> energy %u (0x%08x) energy2 %i  (0x%08x) \n",chan,energy,energy,energy2,energy2);
            //uint32_t address=  [self regAddress:kFLTV4RAMDataReg channel: chan index:i]  ;
            //uint32_t address=  [self regAddress:kFLTV4RAMDataReg ]  ;
            uint32_t address=  [self regAddress: kFLTV4RAMDataReg   channel: chan]  ;
	        [self readBlock: address dataBuffer: buf length: num  increment: 1 ];
    	    for (i=0; i<shownum; i++) {
 	            //-----> NSLog(@" adcval chan: %i index %i: 0x%08x\n",chan,i,buf[i]);//TODO: DEBUG testing ...-tb-
 	            printf(" adcval chan: %i index %i: 0x%08x\n",chan,i,buf[i]);//TODO: DEBUG testing ...-tb-
            }
        }
	}
    #else
	int chan = 0;
	int i;
	uint32_t adcval;
for(chan=0; chan<6;chan++)
	for (i=0; i<num; i++) {
		 adcval = [self readReg:kFLTV4RAMDataReg channel: chan index:i];
 	    NSLog(@" adcval chan: %i index %i: 0x%08x\n",chan,i,adcval);//TODO: DEBUG testing ...-tb-

	}
    
    #endif
}

- (uint32_t) regAddress:(uint32_t)aReg channel:(int)aChannel index:(int)index
{
        //DEBUG OUTPUT:         NSLog(@"%@::%@: addr is 0x%08x \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),(([self stationNumber] << 17) | (aChannel << 12)   | regV4[aReg].addressOffset) + index);//TODO : DEBUG testing ...-tb-
	return (uint32_t)(([self stationNumber] << 17) | (aChannel << 12)   | regV4[aReg].addressOffset) | index; //TODO: the channel ... -tb-   | ((aChannel&0x01f)<<kIpeFlt_ChannelAddress)
}

- (uint32_t) regAddress:(uint32_t)aReg channel:(int)aChannel
{
	return (uint32_t)(([self stationNumber] << 17) | (aChannel << 12)   | regV4[aReg].addressOffset); //TODO: the channel ... -tb-   | ((aChannel&0x01f)<<kIpeFlt_ChannelAddress)
}

- (uint32_t) regAddress:(uint32_t)aReg
{
	
	return (uint32_t)(([self stationNumber] << 17) |  regV4[aReg].addressOffset); //TODO: NEED <<17 !!! -tb-
}

- (uint32_t) adcMemoryChannel:(int)aChannel page:(int)aPage
{
	//TODO:  replace by V4 code -tb-
    //adc access now is very different from v3 -tb-
	return 0;
    //TODO: obsolete (v3) -tb-
	return ([self slot] << 24) | (0x2 << kIpeFlt_AddressSpace) | (aChannel << kIpeFlt_ChannelAddress)	| (aPage << kIpeFlt_PageNumber);
}

- (uint32_t) readReg:(uint32_t)aReg
{
	return [self read: [self regAddress:aReg]];
}

- (uint32_t) readReg:(uint32_t)aReg channel:(int)aChannel
{
	return [self read:[self regAddress:aReg channel:aChannel]];
}

- (uint32_t) readReg:(uint32_t)aReg channel:(int)aChannel  index:(int)aIndex
{
	return [self read:[self regAddress:aReg channel:aChannel index:aIndex]];
}

- (void) writeReg:(uint32_t)aReg value:(uint32_t)aValue
{
	[self write:[self regAddress:aReg] value:aValue];
}

- (void) writeReg:(uint32_t)aReg channel:(int)aChannel value:(uint32_t)aValue
{
	[self write:[self regAddress:aReg channel:aChannel] value:aValue];
}

- (void) readBlock:(uint32_t)aReg dataBuffer:(uint32_t*)aDataBuffer length:(uint32_t)length
{
    [self readBlock:[self regAddress:aReg] dataBuffer:aDataBuffer length:length increment:1];

}

- (void) writeThresholds
{
    int i;
    for(i=0;i<kNumEWFLTHeatIonChannels;i++){
        uint32_t val=[self threshold:i];
        [self writeThreshold: i value: (int)val];
    }
}

- (void) readThresholds
{
    int i;
    for(i=0;i<kNumEWFLTHeatIonChannels;i++){
        uint32_t val=[self readThreshold:i];
        [self setThreshold: i withValue: val];
    }    
}

- (void) writeThreshold:(int)i value:(unsigned int)aValue
{
	//aValue &= 0xfffff;
    if(i>=0 && i<kNumEWFLTHeatChannels)
    	[self writeReg: kFLTV4HeatThresholdsReg channel:i value:aValue];
    if(i>=kNumEWFLTHeatChannels && i<(kNumEWFLTHeatChannels+kNumEWFLTIonChannels))
    	[self writeReg: kFLTV4IonThresholdsReg channel:i-kNumEWFLTHeatChannels value:aValue];
}

- (uint32_t) readThreshold:(int)i
{
    if(i>=0 && i<kNumEWFLTHeatChannels)
	    return [self readReg:kFLTV4HeatThresholdsReg channel:i];
    if(i>=kNumEWFLTHeatChannels && i<(kNumEWFLTHeatChannels+kNumEWFLTIonChannels))
        return [self readReg:kFLTV4IonThresholdsReg channel:i-kNumEWFLTHeatChannels];
	return 0;
}


- (void) writeTestPattern:(uint32_t*)mask length:(int)len
{
	[self rewindTestPattern];
	[self writeNextPattern:0];
	int i;
	for(i=0;i<len;i++){
		[self writeNextPattern:mask[i]];
		NSLog(@"%d: %@\n",i,mask[i]?@".":@"-");
	}
	[self rewindTestPattern];
}

- (void) rewindTestPattern
{
#if (0)
    //TODO: obsolete (v3) -tb-
	[self writeReg:kFLTTestPulsMemReg value: kIpeFlt_TP_Control | kIpeFlt_TestPattern_Reset];
	
#endif
}

- (void) writeNextPattern:(uint32_t)aValue
{
#if (0)
    //TODO: obsolete (v3) -tb-
	[self writeReg:kFLTTestPulsMemReg value:aValue];
#endif
}

- (void) clear:(int)aChan page:(int)aPage value:(unsigned short)aValue
{
	uint32_t aPattern;
	
	aPattern =  aValue;
	aPattern = ( aPattern << 16 ) + aValue;
	
	// While emulating the block transfer by a loop of single transfers
	// it is nec. to increment the address pointer by 2
	[self clearBlock:[self adcMemoryChannel:aChan page:aPage]
			 pattern:aPattern
			  length:kIpeFlt_Page_Size / 2
		   increment:2];
}

- (void) writeMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
	[self writeBlock: [self adcMemoryChannel:aChan page:aPage] 
		  dataBuffer: (uint32_t*)aPageBuffer
			  length: kIpeFlt_Page_Size/2
		   increment: 2];
}

- (void) readMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer
{
	
	[self readBlock: [self adcMemoryChannel:aChan page:aPage]
		 dataBuffer: (uint32_t*)aPageBuffer
			 length: kIpeFlt_Page_Size/2
		  increment: 2];
}

- (uint32_t) readMemoryChan:(int)aChan page:(int)aPage
{
	return [self read:[self adcMemoryChannel:aChan page:aPage]];
}


- (void) writeInterruptMask
{
	[self writeReg:kFLTV4InterruptMaskReg value:interruptMask];
}



- (void) writeTriggerControl  //TODO: must be handled by readout, single pixels cannot be disabled for KATRIN ; this is fixed now, remove workaround after all crates are updated -tb-
{
//TODO: writeTriggerControl UNDER CONSTRUCTION -tb- 2012-07-19
//TODO: writeTriggerControl UNDER CONSTRUCTION -tb- 2012-07-19
//TODO: writeTriggerControl UNDER CONSTRUCTION -tb- 2012-07-19
    //PixelSetting....
	//2,1:
	//0,0 Normal
	//0,1 test pattern
	//1,0 always 0
	//1,1 always 1
	//[self writeReg:kFLTV4PixelSettings1Reg value:0]; //must be handled by readout, single pixels cannot be disabled for KATRIN - OK, FIRMWARE FIXED -tb-
	//uint32_t mask = (~triggerEnabledMask) & 0xffffff;
	//[self writeReg:kFLTV4PixelSettings2Reg value: mask];
}

- (void) pollBBStatus
{
        //DEBUG OUTPUT:                   NSLog(@"%@::%@:  \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO : DEBUG testing ...-tb-
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollBBStatus) object:nil];
    if(pollBBStatusIntervall==0) return;
    
	@try {
        //DEBUG OUTPUT:                   NSLog(@"%@::%@: reading BB status bits.\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO : DEBUG testing ...-tb-
        [self readBBStatusForBBAccess];
	}
	@catch(NSException* localException) {
        //DEBUG OUTPUT: 
                  NSLog(@"%@::%@: reading BB status failed! (Crate not connected?)\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO : DEBUG testing ...-tb-
        //[self setPollBBStatusIntervall:0];
	}
	
    int delay=0;
    switch(pollBBStatusIntervall){
    case 0: delay=0; break;//never
    case 1: delay=1; break;
    case 2: delay=2; break;
    case 3: delay=5; break;
    case 4: delay=10; break;
    case 5: delay=60; break;
    default: delay=60; break;
    }
    if(delay>0)[self performSelector:@selector(pollBBStatus) withObject:nil afterDelay:delay];
}


- (void) readHitRates
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
    
    int hitRateLengthSec = 0x1 << hitRateLength;

        //DEBUG OUTPUT:                         NSLog(@"%@::%@: UNDER CONSTRUCTION! hitRateLength: %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),hitRateLength);//TODO : DEBUG testing ...-tb-
	
	@try {
		
		BOOL oneChanged = NO;
		float newTotal = 0;
		int chan;
		float freq = 1.0/((double)hitRateLengthSec);
				
//		uint32_t location = (([self crateNumber]&0xf)<<21) | ([self stationNumber]& 0x0000001f)<<16;
//		uint32_t data[5 + kNumEWFLTHeatIonChannels];
		
		//combine all the hitrate read commands into one command packet
		ORCommandList* aList = [ORCommandList commandList];
		for(chan=0;chan<kNumEWFLTHeatIonChannels;chan++){
			if(hitRateEnabledMask & (1L<<chan)){
				[aList addCommand: [self readRegCmd:kFLTV4HitRateReg channel:chan]];
			}
        //DEBUG OUTPUT:                 NSLog(@"%@::%@: HR command for chan %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),chan);//TODO : DEBUG testing ...-tb-
		}
		
		[self executeCommandList:aList];
		
		//put the synchronized around this code to test if access to the hitrates is thread safe
		//pull out the result
		int dataIndex = 0;
		for(chan=0;chan<kNumEWFLTHeatIonChannels;chan++){
			if(hitRateEnabledMask & (1L<<chan)){
                hitRateReg[chan] = [aList longValueForCmd:dataIndex];
				uint32_t aValue = hitRateReg[chan];
				BOOL overflow = (aValue == 0xffff);//(aValue >> 31) & 0x1;
				aValue = aValue & 0xffff;
				if((aValue *freq) != hitRate[chan] || overflow != hitRateOverFlow[chan]){
					if (hitRateLengthSec!=0)	hitRate[chan] = aValue * freq;
					//if (hitRateLengthSec!=0)	hitRate[chan] = aValue; 
					else					    hitRate[chan] = 0;
                    //DEBUG OUTPUT:                 NSLog(@"%@::%@: HR  for chan %i was 0x%08x (%i)  -> %f\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),chan,aValue,aValue,hitRate[chan]);//TODO : DEBUG testing ...-tb-
					
					if(hitRateOverFlow[chan]) hitRate[chan] = 0;
					hitRateOverFlow[chan] = overflow;
					
					oneChanged = YES;
				}
				if(!hitRateOverFlow[chan]){
					newTotal += hitRate[chan];
				}
//				data[dataIndex + 5] = ((chan&0xff)<<20) | ((overflow&0x1)<<16) | aValue;// the hitrate may have more than 16 bit in the future -tb-
				dataIndex++;
			}else{
                hitRateReg[chan] = 0;
            }
            //DEBUG OUTPUT:      NSLog(@"%@::%@: chan %i   hitRateReg[chan]: 0x%x\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),chan,hitRateReg[chan]);//TODO : DEBUG testing ...-tb-
		}
#if 0
		
		if(dataIndex>0){
			time_t	ut_time;
			time(&ut_time);

			data[0] = hitRateId | (dataIndex + 5); 
			data[1] = location;
			data[2] = ut_time;	
			data[3] = hitRateLengthSec;	
			data[4] = newTotal;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(int32_t)*(dataIndex + 5)]];
			
		}
#endif
		
		[self setHitRateTotal:newTotal];
		
		if(1 || oneChanged){//TODO: need to store the hitrate regulation bit and OR together in "oneCHanged" -tb- 2014-11
		    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelHitRateChanged object:self];
		}
	}
	@catch(NSException* localException) {
	}
	


	[self performSelector:@selector(readHitRates) withObject:nil afterDelay: hitRateLengthSec];
}





//------------------
//command Lists
- (void) executeCommandList:(ORCommandList*)aList
{
	[[[self crate] adapter] executeCommandList:aList];
}

- (id) readRegCmd:(uint32_t) aRegister channel:(short) aChannel
{
	uint32_t theAddress = [self regAddress:aRegister channel:aChannel];
	return [[[self crate] adapter] readHardwareRegisterCmd:theAddress];		
}

- (id) readRegCmd:(uint32_t) aRegister
{
	return [[[self crate] adapter] readHardwareRegisterCmd:[self regAddress:aRegister]];		
}

- (id) writeRegCmd:(uint32_t) aRegister channel:(short) aChannel value:(uint32_t)aValue
{
	uint32_t theAddress = [self regAddress:aRegister channel:aChannel];
	return [[[self crate] adapter] writeHardwareRegisterCmd:theAddress value:aValue];		
}

- (id) writeRegCmd:(uint32_t) aRegister value:(uint32_t)aValue
{
	return [[[self crate] adapter] writeHardwareRegisterCmd:[self regAddress:aRegister] value:aValue];		
}
//------------------





- (NSString*) rateNotification
{
	return OREdelweissFLTModelHitRateChanged;
}

#pragma mark *** archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    
    int i;
    for(i=0; i<kNumEWFLTFibers; i++){
        //[self setSaveIonChanFilterOutputRecords:[decoder decodeBoolForKey:@"saveIonChanFilterOutputRecords"]];
        [self setRepeatSWTriggerDelay:[decoder decodeDoubleForKey:@"repeatSWTriggerDelay"]];
        [self setHitrateLimitIon:[decoder decodeIntForKey:@"hitrateLimitIon"]];
        [self setHitrateLimitHeat:[decoder decodeIntForKey:@"hitrateLimitHeat"]];
        [self setChargeFICFile:[decoder decodeObjectForKey:@"chargeFICFile"]];
        [self setFicCardTriggerCmd:[decoder decodeIntForKey: [NSString stringWithFormat: @"ficCardTriggerCmd%i",i]] forFiber:i];
        [self setFicCardADC23CtrlReg:[decoder decodeIntForKey: [NSString stringWithFormat: @"ficCardADC23CtrlReg%i",i]] forFiber:i];
        [self setFicCardADC01CtrlReg:[decoder decodeIntForKey: [NSString stringWithFormat: @"ficCardADC01CtrlReg%i",i]] forFiber:i];
        [self setFicCardCtrlReg2:[decoder decodeIntForKey: [NSString stringWithFormat: @"ficCardCtrlReg2%i",i]] forFiber:i];
        [self setFicCardCtrlReg1:[decoder decodeIntForKey: [NSString stringWithFormat: @"ficCardCtrlReg1%i",i]] forFiber:i];
    }
    [self setPollBBStatusIntervall:[decoder decodeIntForKey:@"pollBBStatusIntervall"]];
    [self setChargeBBFile:[decoder decodeObjectForKey:@"chargeBBFileForFiber0"] forFiber:0 ];
    [self setChargeBBFile:[decoder decodeObjectForKey:@"chargeBBFileForFiber1"] forFiber:1 ];
    [self setChargeBBFile:[decoder decodeObjectForKey:@"chargeBBFileForFiber2"] forFiber:2 ];
    [self setChargeBBFile:[decoder decodeObjectForKey:@"chargeBBFileForFiber3"] forFiber:3 ];
    [self setChargeBBFile:[decoder decodeObjectForKey:@"chargeBBFileForFiber4"] forFiber:4 ];
    [self setChargeBBFile:[decoder decodeObjectForKey:@"chargeBBFileForFiber5"] forFiber:5 ];
    [self setBB0x0ACmdMask:[decoder decodeIntForKey:@"BB0x0ACmdMask"]];
    [self setChargeBBFile:[decoder decodeObjectForKey:@"chargeBBFile"]];
    [self setIonToHeatDelay:[decoder decodeIntForKey:@"ionToHeatDelay"]];
    [self setLowLevelRegInHex:[decoder decodeIntForKey:@"lowLevelRegInHex"]];
    [self setWriteToBBMode:[decoder decodeIntForKey:@"writeToBBMode"]];
    [self setWCmdArg2:[decoder decodeIntForKey:@"wCmdArg2"]];
    [self setWCmdArg1:[decoder decodeIntForKey:@"wCmdArg1"]];
    [self setWCmdCode:[decoder decodeIntForKey:@"wCmdCode"]];
    
//    [self setAdcRt:[decoder decodeIntegerForKey:@"adcRt"]];
//TODO: remove it      [self setDacb:[decoder decodeIntegerForKey:@"dacb"]];
//TODO: remove it      [self setSignb:[decoder decodeIntegerForKey:@"signb"]];
//TODO: remove it      [self setDaca:[decoder decodeIntegerForKey:@"daca"]];
//TODO: remove it    [self setSigna:[decoder decodeIntegerForKey:@"signa"]];
    [self setStatusBitsBBData:[decoder decodeObjectForKey:@"statusBitsBBData"]];
	if(!statusBitsBBData){
		[self setStatusBitsBBData: [NSMutableData dataWithLength: 4 * kNumEWFLTFibers * kNumBBStatusBufferLength32]];
	}
    memcpy(&(statusBitsBB[0][0]), [statusBitsBBData bytes], 4 * kNumEWFLTFibers * kNumBBStatusBufferLength32);
    
 //   [self setAdcRtForBBAccess:[decoder decodeIntegerForKey:@"adcRtForBBAccess"]];
 //   [self setAdcRgForBBAccess:[decoder decodeIntegerForKey:@"adcRgForBBAccess"]];
 //   [self setAdcValueForBBAccess:[decoder decodeIntegerForKey:@"adcValueForBBAccess"]];
 //TODO: remove all    [self setAdcMultForBBAccess:[decoder decodeIntegerForKey:@"adcMultForBBAccess"]];
 //   [self setAdcFreqkHzForBBAccess:[decoder decodeIntegerForKey:@"adcFreqkHzForBBAccess"]];
    [self setUseBroadcastIdforBBAccess:[decoder decodeIntForKey:@"useBroadcastIdforBBAccess"]];
//    [self setIdBBforBBAccess:[decoder decodeIntegerForKey:@"idBBforBBAccess"]];
    [self setFiberSelectForBBAccess:[decoder decodeIntForKey:@"fiberSelectForBBAccess"]];
//RM    [self setRelaisStatesBB:[decoder decodeIntegerForKey:@"relaisStatesBB"]];
    [self setFiberSelectForBBStatusBits:[decoder decodeIntForKey:@"fiberSelectForBBStatusBits"]];
    [self setFiberOutMask:[decoder decodeIntForKey:@"fiberOutMask"]];
    //[self setTpix:[decoder decodeIntegerForKey:@"tpix"]];
    [self setRepeatSWTriggerMode:[decoder decodeIntForKey:@"repeatSWTriggerMode"]];
    [self setControlRegister:[decoder decodeIntForKey:@"controlRegister"]];
    [self setFastWrite:[decoder decodeIntForKey:@"fastWrite"]];
    [self setFiberDelays:[decoder decodeInt64ForKey:@"fiberDelays"]];
    [self setStreamMask:[decoder decodeInt64ForKey:@"streamMask"]];
    [self setHeatTriggerMask:[decoder decodeInt64ForKey:@"heatTriggerMask"]];
    [self setIonTriggerMask:[decoder decodeInt64ForKey:@"ionTriggerMask"]];
    [self setSelectFiberTrig:[decoder decodeIntForKey:@"selectFiberTrig"]];
    //[self setBBv1Mask:[decoder decodeIntegerForKey:@"BBv1Mask"]];
//DEBUG OUTPUT:    NSLog(@"%@::%@: UNDER CONSTRUCTION! BBv1Mask %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[decoder decodeIntegerForKey:@"BBv1Mask"]);//TODO: DEBUG testing ...-tb-
    [self setFiberEnableMask:[decoder decodeIntForKey:@"fiberEnableMask"]];
    [self setFltModeFlags:[decoder decodeIntForKey:@"fltModeFlags"]];
    [self setTargetRate:[decoder decodeIntForKey:@"targetRate"]];
	[self setRunMode:			[decoder decodeIntForKey:@"runMode"]];
    [self setStoreDataInRam:	[decoder decodeBoolForKey:@"storeDataInRam"]];
    [self setFilterLength:		[decoder decodeIntForKey:@"filterLength"]-2];//to be backward compatible with old Orca config files -tb-
    [self setGapLength:			[decoder decodeIntForKey:@"gapLength"]];
    [self setPostTriggerTime:	[decoder decodeIntForKey:@"postTriggerTime"]];
    [self setInterruptMask:		[decoder decodeIntForKey:@"interruptMask"]];
    [self setHitRateLength:		[decoder decodeIntegerForKey:@"OREdelweissFLTModelHitRateLength"]];
    [self setHitRateEnabledMask:[decoder decodeIntForKey:@"hitRateEnabledMask"]];
    [self setGains:				[decoder decodeObjectForKey:@"gains"]];
    [self setThresholds:		[decoder decodeObjectForKey:@"thresholds"]];
    [self setTriggerParameter:	[decoder decodeObjectForKey:@"triggerParameter"]];
    [self setTotalRate:			[decoder decodeObjectForKey:@"totalRate"]];
	[self setTestEnabledArray:	[decoder decodeObjectForKey:@"testsEnabledArray"]];
	[self setTestStatusArray:	[decoder decodeObjectForKey:@"testsStatusArray"]];
    [self setWriteValue:		[decoder decodeIntForKey:@"writeValue"]];
    [self setSelectedRegIndex:  [decoder decodeIntegerForKey:@"selectedRegIndex"]];
    [self setSelectedChannelValue:  [decoder decodeIntegerForKey:@"selectedChannelValue"]];
    /* unused
    //TODO: remove from call definition -tb-
    [self setFifoBehaviour:		[decoder decodeIntegerForKey:@"fifoBehaviour"]];
    [self setAnalogOffset:		[decoder decodeIntegerForKey:@"analogOffset"]];
    */
	
	//int i;
	if(!thresholds){
		[self setThresholds: [NSMutableArray array]];
		for(i=0;i<kNumEWFLTHeatIonChannels;i++) [thresholds addObject:[NSNumber numberWithInt:50]];
	}
    //TODO: this should be changed (or removed) -tb- 2013
	if([thresholds count]<kNumEWFLTHeatIonChannels){
		for(i=(int)[thresholds count];i<kNumEWFLTHeatIonChannels;i++) [thresholds addObject:[NSNumber numberWithInteger:50]];
	}
	
	if(!triggerParameter){
		[self setTriggerParameter: [NSMutableArray array]];
		for(i=0;i<kNumEWFLTHeatIonChannels;i++) [triggerParameter addObject:[NSNumber numberWithInt:0]];
	}
	if([triggerParameter count]<kNumEWFLTHeatIonChannels){
		for(i=(int)[triggerParameter count];i<kNumEWFLTHeatIonChannels;i++) [triggerParameter addObject:[NSNumber numberWithInteger:0]];
	}
	for(i=0;i<kNumEWFLTHeatIonChannels;i++) triggerPar[i] = [[triggerParameter objectAtIndex:i] unsignedIntValue];
	
    //TODO: remove it -tb- 2013
	if(!gains){
		[self setGains: [NSMutableArray array]];
		for(i=0;i<kNumEWFLTHeatIonChannels;i++) [gains addObject:[NSNumber numberWithInt:100]];
	}
	if([gains count]<kNumEWFLTHeatIonChannels){
		for(i=(int)[gains count];i<kNumEWFLTHeatIonChannels;i++) [gains addObject:[NSNumber numberWithInteger:50]];
	}
	
	if(!testStatusArray){
		[self setTestStatusArray: [NSMutableArray array]];
		for(i=0;i<kNumEdelweissFLTTests;i++) [testStatusArray addObject:@"--"];
	}
	
	if(!testEnabledArray){
		[self setTestEnabledArray: [NSMutableArray array]];
		for(i=0;i<kNumEdelweissFLTTests;i++) [testEnabledArray addObject:[NSNumber numberWithBool:YES]];
	}
	
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
        [encoder encodeDouble:repeatSWTriggerDelay forKey:@"repeatSWTriggerDelay"];
        [encoder encodeInt:hitrateLimitIon forKey:@"hitrateLimitIon"];
        [encoder encodeInt:hitrateLimitHeat forKey:@"hitrateLimitHeat"];
        [encoder encodeObject:chargeFICFile forKey:@"chargeFICFile"];
        //[encoder encodeBool:saveIonChanFilterOutputRecords forKey:@"saveIonChanFilterOutputRecords"];
        
    int i;
    for(i=0; i<kNumEWFLTFibers; i++){
        [encoder encodeInt:ficCardTriggerCmd[i] forKey: [NSString stringWithFormat: @"ficCardTriggerCmd%i",i]];
        [encoder encodeInteger:ficCardADC23CtrlReg[i] forKey: [NSString stringWithFormat: @"ficCardADC23CtrlReg%i",i]];
        [encoder encodeInt:ficCardADC01CtrlReg[i] forKey: [NSString stringWithFormat: @"ficCardADC01CtrlReg%i",i]];
        [encoder encodeInt:ficCardCtrlReg2[i] forKey: [NSString stringWithFormat: @"ficCardCtrlReg2%i",i]];
        [encoder encodeInt:ficCardCtrlReg1[i] forKey: [NSString stringWithFormat: @"ficCardCtrlReg1%i",i]];
    }
    [encoder encodeInt:pollBBStatusIntervall forKey:@"pollBBStatusIntervall"];
    [encoder encodeObject:chargeBBFileForFiber[0] forKey:@"chargeBBFileForFiber0"];
    [encoder encodeObject:chargeBBFileForFiber[1] forKey:@"chargeBBFileForFiber1"];
    [encoder encodeObject:chargeBBFileForFiber[2] forKey:@"chargeBBFileForFiber2"];
    [encoder encodeObject:chargeBBFileForFiber[3] forKey:@"chargeBBFileForFiber3"];
    [encoder encodeObject:chargeBBFileForFiber[4] forKey:@"chargeBBFileForFiber4"];
    [encoder encodeObject:chargeBBFileForFiber[5] forKey:@"chargeBBFileForFiber5"];
    [encoder encodeInt:BB0x0ACmdMask forKey:@"BB0x0ACmdMask"];
    [encoder encodeObject:chargeBBFile forKey:@"chargeBBFile"];
    [encoder encodeInt:ionToHeatDelay forKey:@"ionToHeatDelay"];
    [encoder encodeInt:lowLevelRegInHex forKey:@"lowLevelRegInHex"];
    [encoder encodeInt:writeToBBMode forKey:@"writeToBBMode"];
    [encoder encodeInt:wCmdArg2 forKey:@"wCmdArg2"];
    [encoder encodeInt:wCmdArg1 forKey:@"wCmdArg1"];
    [encoder encodeInt:wCmdCode forKey:@"wCmdCode"];
    
    //BB access tab
	if(!statusBitsBBData){
		[self setStatusBitsBBData: [NSMutableData dataWithLength: 4 * kNumEWFLTFibers * kNumBBStatusBufferLength32]];
	}
    //memcpy([statusBitsBBData bytes], &(statusBitsBB[0][0]), 4 * kNumEWFLTFibers * kNumBBStatusBufferLength32);
    NSRange range = {0, [statusBitsBBData length] };
    [statusBitsBBData replaceBytesInRange:range withBytes: &(statusBitsBB[0][0]) ];
//[encoder encodeInteger:adcRt forKey:@"adcRt"];
//TODO: remove it      [encoder encodeInteger:dacb forKey:@"dacb"];
//TODO: remove it      [encoder encodeInteger:signb forKey:@"signb"];
//TODO: remove it      [encoder encodeInteger:daca forKey:@"daca"];
//    [encoder encodeInteger:signa forKey:@"signa"];
    [encoder encodeObject:statusBitsBBData forKey:@"statusBitsBBData"];
    
//    [encoder encodeInteger:adcRtForBBAccess forKey:@"adcRtForBBAccess"];
//    [encoder encodeInteger:adcRgForBBAccess forKey:@"adcRgForBBAccess"];
//    [encoder encodeInteger:adcValueForBBAccess forKey:@"adcValueForBBAccess"];
//    [encoder encodeInteger:adcMultForBBAccess forKey:@"adcMultForBBAccess"];
//    [encoder encodeInteger:adcFreqkHzForBBAccess forKey:@"adcFreqkHzForBBAccess"];
    [encoder encodeInt:useBroadcastIdforBBAccess forKey:@"useBroadcastIdforBBAccess"];
//    [encoder encodeInteger:idBBforBBAccess forKey:@"idBBforBBAccess"];
    [encoder encodeInt:fiberSelectForBBAccess forKey:@"fiberSelectForBBAccess"];
    
    //others
//RM    [encoder encodeInteger:relaisStatesBB forKey:@"relaisStatesBB"];
    [encoder encodeInt:fiberSelectForBBStatusBits forKey:@"fiberSelectForBBStatusBits"];
    [encoder encodeInt:fiberOutMask forKey:@"fiberOutMask"];
    //[encoder encodeInteger:tpix forKey:@"tpix"];
    [encoder encodeInt:repeatSWTriggerMode forKey:@"repeatSWTriggerMode"];
    [encoder encodeInt:controlRegister forKey:@"controlRegister"];
    [encoder encodeInt:fastWrite forKey:@"fastWrite"];
    [encoder encodeInt64:fiberDelays forKey:@"fiberDelays"];
    [encoder encodeInt64:streamMask forKey:@"streamMask"];
    [encoder encodeInt64:heatTriggerMask forKey:@"heatTriggerMask"];
    [encoder encodeInt64:ionTriggerMask forKey:@"ionTriggerMask"];
    [encoder encodeInt:selectFiberTrig forKey:@"selectFiberTrig"];
//DEBUG OUTPUT: 	NSLog(@"%@::%@: UNDER CONSTRUCTION! BBv1Mask %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),BBv1Mask);//TODO: DEBUG testing ...-tb-
    //[encoder encodeInteger:BBv1Mask forKey:@"BBv1Mask"];
    [encoder encodeInt:fiberEnableMask forKey:@"fiberEnableMask"];
    [encoder encodeInt:fltModeFlags forKey:@"fltModeFlags"];
    [encoder encodeInt:targetRate			forKey:@"targetRate"];
    [encoder encodeInt:runMode				forKey:@"runMode"];
    [encoder encodeBool:runBoxCarFilter		forKey:@"runBoxCarFilter"];
    [encoder encodeBool:storeDataInRam		forKey:@"storeDataInRam"];
    [encoder encodeInt:(filterLength+2)			forKey:@"filterLength"];//to be backward compatible with old Orca config files (this is the register value)-tb-
    [encoder encodeInt:gapLength			forKey:@"gapLength"];
    [encoder encodeInt:postTriggerTime	forKey:@"postTriggerTime"];
    [encoder encodeInt:interruptMask		forKey:@"interruptMask"];
    [encoder encodeInteger:hitRateLength		forKey:@"OREdelweissFLTModelHitRateLength"];
    [encoder encodeInt:hitRateEnabledMask	forKey:@"hitRateEnabledMask"];
    [encoder encodeObject:gains				forKey:@"gains"];
    [encoder encodeObject:thresholds		forKey:@"thresholds"];
    //int i;
	for(i=0;i<kNumEWFLTHeatIonChannels;i++)    [triggerParameter replaceObjectAtIndex:i withObject:[NSNumber numberWithInteger:triggerPar[i]]];
    [encoder encodeObject:triggerParameter	forKey:@"triggerParameter"];
    [encoder encodeObject:totalRate			forKey:@"totalRate"];
    [encoder encodeObject:testEnabledArray	forKey:@"testEnabledArray"];
    [encoder encodeObject:testStatusArray	forKey:@"testStatusArray"];
    [encoder encodeInteger:writeValue           forKey:@"writeValue"];	
    [encoder encodeInteger:selectedRegIndex  	forKey:@"selectedRegIndex"];	
    [encoder encodeInteger:selectedChannelValue	forKey:@"selectedChannelValue"];	
    
    /*
    [encoder encodeInteger:fifoBehaviour		forKey:@"fifoBehaviour"];
    [encoder encodeInteger:analogOffset			forKey:@"analogOffset"];
    */
}

#pragma mark *** Data Taking
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) aDataId
{
    dataId = aDataId;
}

- (uint32_t) waveFormId { return waveFormId; }
- (void) setWaveFormId: (uint32_t) aWaveFormId
{
    waveFormId = aWaveFormId;
}

- (uint32_t) hitRateId { return hitRateId; }
- (void) setHitRateId: (uint32_t) aDataId
{
    hitRateId = aDataId;
}

- (uint32_t) histogramId { return histogramId; }
- (void) setHistogramId: (uint32_t) aDataId
{
    histogramId = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId      = [assigner assignDataIds:kLongForm];
    hitRateId   = [assigner assignDataIds:kLongForm];
    waveFormId  = [assigner assignDataIds:kLongForm];
    histogramId  = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
    [self setHitRateId:[anotherCard hitRateId]];
    [self setWaveFormId:[anotherCard waveFormId]];
    [self setHistogramId:[anotherCard histogramId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"OREdelweissFLTDecoderForEnergy",			@"decoder",
								 [NSNumber numberWithLong:dataId],		@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:7],			@"length",
								 nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissFLTEnergy"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"OREdelweissFLTDecoderForWaveForm",			@"decoder",
				   [NSNumber numberWithLong:waveFormId],	@"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissFLTWaveForm"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"OREdelweissFLTDecoderForHitRate",			@"decoder",
				   [NSNumber numberWithLong:hitRateId],		@"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissFLTHitRate"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"OREdelweissFLTDecoderForHistogram",		@"decoder",
				   [NSNumber numberWithLong:histogramId],	@"dataId",
				   [NSNumber numberWithBool:YES],			@"variable",
				   [NSNumber numberWithLong:-1],			@"length",
				   nil];
	
    [dataDictionary setObject:aDictionary forKey:@"EdelweissFLTHistogram"];
	
    return dataDictionary;
}


//this goes into the Orca run file XML header
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    //TODO:  addParametersToDictionary  -  add missing parameters -tb- 2013-06
    //TODO:  addParametersToDictionary  -  add missing parameters -tb- 2013-06
    //TODO:  addParametersToDictionary  -  add missing parameters -tb- 2013-06
    //TODO:  addParametersToDictionary  -  add missing parameters -tb- 2013-06
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];


    [objDictionary setObject:[NSNumber numberWithLong:controlRegister]		forKey:@"controlRegister"];
    [objDictionary setObject:[NSNumber numberWithLongLong:fiberDelays]		forKey:@"fiberDelays"];
    [objDictionary setObject:[NSNumber numberWithLongLong:streamMask]		forKey:@"streamMask"];
    [objDictionary setObject:[NSNumber numberWithLongLong:fiberOutMask]		forKey:@"fiberOutMask"];
    [objDictionary setObject:[NSNumber numberWithInt:testVariable]		forKey:@"testVariable"];

    [objDictionary setObject:thresholds										forKey:@"thresholds"];
    
    int i;
	for(i=0;i<kNumEWFLTHeatIonChannels;i++)    [triggerParameter replaceObjectAtIndex:i withObject:[NSNumber numberWithUnsignedLong:triggerPar[i]]];
    [objDictionary setObject:triggerParameter								forKey:@"triggerParameter"];
    [objDictionary setObject:[NSNumber numberWithLong:postTriggerTime]		forKey:@"postTriggerTime"];
    if(sizeof(uint64_t) < sizeof(int64_t)) NSLog(@"%@::%@: ERROR - WARNING - sizeof(uint64_t) < sizeof(int64_t) - cannot store: ionTriggerMask, heatTriggerMask without information loss! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//TODO : DEBUG testing ...-tb-
    //else NSLog(@"%@::%@:  sizeof(uint64_t)(%i) >= sizeof(int64_t) (%i) -  store: ionTriggerMask, heatTriggerMask - OK! \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),sizeof(uint64_t),sizeof(int64_t));//TODO : DEBUG testing ...-tb-
    //usually both are 8 ... -tb-

    [objDictionary setObject:[NSNumber numberWithLongLong:ionTriggerMask]		forKey:@"ionTriggerMask"];
    [objDictionary setObject:[NSNumber numberWithLongLong:heatTriggerMask]		forKey:@"heatTriggerMask"];
    [objDictionary setObject:[NSNumber numberWithLong:ionToHeatDelay]		forKey:@"ionToHeatDelay"];
    [objDictionary setObject:[NSNumber numberWithLong:hitRateLength]		forKey:@"hitRateLength"];
    [objDictionary setObject:[NSNumber numberWithLong:hitRateEnabledMask]	forKey:@"hitRateEnabledMask"];
    
    //if([self isPartOfRun]){ // ... is not yet set at this point ... -tb-
        uint32_t status = [self readReg: kFLTV4StatusReg ]; //[self readStatus] would call both, but calls a NSLog..., too, which I do not want here -tb-
	    [self setStatusRegister:status];
    
        CFPGAVersion = [self readVersion];
        
        [objDictionary setObject:[NSNumber numberWithLong:statusRegister]		forKey:@"statusRegister"];
        [objDictionary setObject:[NSNumber numberWithLong:CFPGAVersion]		forKey:@"CFPGAVersion"];
    //}
    
    //obsolete values -tb- 2014
    /*
    [objDictionary setObject:gains											forKey:@"gains"];
    [objDictionary setObject:[NSNumber numberWithInt:runMode]				forKey:@"runMode"];
    
    
    [objDictionary setObject:[NSNumber numberWithLong:fifoBehaviour]		forKey:@"fifoBehaviour"];
    [objDictionary setObject:[NSNumber numberWithLong:analogOffset]			forKey:@"analogOffset"];
    //TODO: obsolete for EW -tb- [objDictionary setObject:[NSNumber numberWithLong:gapLength]			forKey:@"gapLength"];
    //TODO: obsolete for EW -tb- [objDictionary setObject:[NSNumber numberWithLong:filterLength+2]			forKey:@"filterLength"];//this is the fpga register value -tb-
    */
	return objDictionary;
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(channel>=0 && channel<kNumEWFLTHeatIonChannels){
		++eventCount[channel];
	}
    return YES;
}

- (uint32_t) eventCount:(int)aChannel
{
    //TODO: is this still used? (-> remove it) -tb- 2013
    return eventCount[aChannel];
}

- (void) clearEventCounts
{
    int i;
    for(i=0;i<kNumEWFLTHeatIonChannels;i++){
		eventCount[i]=0;
    }
}

//! Write 1 to all reset/clear flags of the FLTv4 command register.
- (void) reset 
{
	//[self writeReg:kFLTV4CommandReg value:kIpeFlt_Reset_All];
}


- (void) fireRepeatedSoftwareTriggerInRun
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fireRepeatedSoftwareTriggerInRun) object:nil];
    
	//now: sw trigg.
    [self writeCommandSoftwareTrigger];

	if([self swTriggerIsRepeating] && [self repeatSWTriggerMode])[self performSelector:@selector(fireRepeatedSoftwareTriggerInRun) withObject:nil afterDelay:repeatSWTriggerDelay];

}


- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{	
//TODO: runTaskStarted UNDER CONSTRUCTION -tb- 
//TODO: runTaskStarted UNDER CONSTRUCTION -tb- 
//TODO: runTaskStarted UNDER CONSTRUCTION -tb- 
//TODO: runTaskStarted UNDER CONSTRUCTION -tb- 
        //DEBUG
                 NSLog(@"%@::%@ Called runTaskStarted -  UNDER CONSTRUCTION --- FLT #%i<-------------------------\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[self stationNumber]);//DEBUG -tb-


#if 0
    //moved to runIsAboutToChangeState
    //a test:
    testVariable = 23;
    
    //read FPGA firmware version and status register for ... addParametersToDictionary:(NSMutableDictionary*) ...
    //this is called ater runTaskStarted:..., so these values will go into the Orca run file -tb-
    uint32_t status = [self readReg: kFLTV4StatusReg ]; //[self readStatus] would call both, but calls a NSLog..., too, which I do not want here -tb-
	[self setStatusRegister:status];
    
    CFPGAVersion = [self readVersion];   
#endif
    
    [self setIsPartOfRun: YES];

	firstTime = YES;
	
    [self clearExceptionCount];
	[self clearEventCounts];
	
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"OREdelweissFLTModel"];    
    //----------------------------------------------------------------------------------------	

	//check which mode to use
	BOOL ratesEnabled = NO;
#if 1	
	int i;
	for(i=0;i<kNumEWFLTHeatIonChannels;i++){
		if([self hitRateEnabled:i]){
			ratesEnabled = YES;
			break;
		}
	}
#endif	

    [self initTrigger];//TODO: 

    if([[userInfo objectForKey:@"doinit"]intValue]){
//TODO: remove the obsolete commands -tb-    
	//[self setLedOff:NO];
	  //[self writeRunControl];     // writes theHitRatePeriod - moved to initBoard -tb- 2013-09
      //[self reset];               // Write 1 to all reset/clear flags of the FLTv4 command register.
	  [self initBoard];           // writes control reg + hr control reg + PostTrigg + thresh+gains + offset + triggControl + hr mask + enab.statistics
	}
	
	
	if(ratesEnabled){//TODO: disabled ... -tb-
		[self performSelector:@selector(readHitRates) 
				   withObject:nil
				   afterDelay:  (0x1 << hitRateLength)];		//start reading out the rates
	}
		
	if(runMode == kIpeFltV4_MonitoringDaqMode ){ ///obsolete ... kIpeFltV4_Histogram_DaqMode){
		//start polling histogramming mode status
/*		[self performSelector:@selector(readHistogrammingStatus) 
				   withObject:nil
				   afterDelay: 1];		//start reading out histogram timer and page toggle
*/
	}
	
	//Edelweiss event readout
	if([self repeatSWTriggerMode] == 1){
	    NSLog(@"Start SW Trigger\n");//TODO: debug output -tb-
		[self setSwTriggerIsRepeating: 1];  //-> call writeCommandSoftwareTrigger frequently
	    //[self performSelector:@selector(fireRepeatedSoftwareTriggerInRun) withObject:nil afterDelay:1];
	    [self performSelector:@selector(fireRepeatedSoftwareTriggerInRun) withObject:nil afterDelay:repeatSWTriggerDelay];
	}

}


//**************************************************************************************
// Function:	

// Description: Read data from a card
//***************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{	
	if(firstTime){
		firstTime = NO;
		NSLogColor([NSColor redColor],@"Readout List Error: FLT %d must be a child of an SLT in the readout list\n",[self stationNumber]);
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	[self setLedOff:YES];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHitRates) object:nil];
//	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readHistogrammingStatus) object:nil];
	int chan;
	for(chan=0;chan<kNumEWFLTHeatIonChannels;chan++){
		hitRate[chan] = 0;
	}
	[self setHitRateTotal:0];

	if([self swTriggerIsRepeating]){
	    NSLog(@"Stop SW Trigger\n");//TODO: debug output -tb-
		[self setSwTriggerIsRepeating: 0];
	    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fireRepeatedSoftwareTriggerInRun) object:nil];
	}
	//[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fireRepeatedSoftwareTriggerInRun) object:nil];

    [self writeTriggerParametersDisableAll];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelHitRateChanged object:self];
    
    [self setIsPartOfRun: NO];


}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢SBC readout control structure... Till, fill out as needed
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id	= kFLTv4EW;					//unique identifier for readout hw
	configStruct->card_info[index].hw_mask[0] 	= dataId;					//record id for energies
	configStruct->card_info[index].hw_mask[1] 	= waveFormId;				//record id for the waveforms
	configStruct->card_info[index].hw_mask[2] 	= histogramId;				//record id for the histograms
	configStruct->card_info[index].slot			= [self stationNumber];		//the PMC readout uses col 0 thru n
	configStruct->card_info[index].crate		= [self crateNumber];
//DEBUG OUTPUT: 
	NSLog(@"    %@::%@:slot %i, crate %i \n",NSStringFromClass([self class]),NSStringFromSelector(_cmd), [self stationNumber], [self crateNumber]);//TODO: DEBUG testing ...-tb-
	
	configStruct->card_info[index].deviceSpecificData[0] = (uint32_t)postTriggerTime;	//needed to align the waveforms
	
	uint32_t eventTypeMask = 0;
	if(readWaveforms) eventTypeMask |= kReadWaveForms;
	configStruct->card_info[index].deviceSpecificData[1] = (uint32_t)eventTypeMask;
	configStruct->card_info[index].deviceSpecificData[2] = fltModeFlags;	
	
    //"first time" flag (needed for histogram mode)
	uint32_t runFlagsMask = 0;
	runFlagsMask |= kFirstTimeFlag;          //bit 16 = "first time" flag
    //if(runMode == kIpeFltV4_EnergyDaqMode | runMode == kIpeFltV4_EnergyTraceDaqMode)
    //    runFlagsMask |= kSyncFltWithSltTimerFlag;//bit 17 = "sync flt with slt timer" flag
    
	configStruct->card_info[index].deviceSpecificData[3] = (uint32_t)runFlagsMask;
//NSLog(@"RunFlags 0x%x\n",configStruct->card_info[index].deviceSpecificData[3]);

    //for all daq modes
//	configStruct->card_info[index].deviceSpecificData[4] = triggerEnabledMask;	
    //the daq mode (should replace the flt mode)
    configStruct->card_info[index].deviceSpecificData[5] = runMode;//the daqRunMode

    //new for Edelweiss
    configStruct->card_info[index].deviceSpecificData[10] = (uint32_t)[self selectFiberTrig];//the fiber_select (Select Fiber) setting of control register

	configStruct->card_info[index].num_Trigger_Indexes = 0;					//we can't have children
	configStruct->card_info[index].next_Card_Index 	= index+1;	

	
	return index+1;
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}

- (int) numberOfChannels
{
    return kNumEWFLTHeatIonChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Run Mode"];
    [p setFormat:@"##0" upperLimit:2 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setRunMode:) getMethod:@selector(runMode)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0xfffff lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Shaping Length"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:6 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setShapingLength:withValue:) getMethod:@selector(shapingLength:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gain"];
    [p setFormat:@"##0" upperLimit:0xfff lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setGain:withValue:) getMethod:@selector(gain:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setTriggerEnabled:withValue:) getMethod:@selector(triggerEnabled:)];
    [a addObject:p];
	
#if 0
//TODO: xxx -tb-
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"HitRate Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setHitRateEnabled:withValue:) getMethod:@selector(hitRateEnabled:)];
    [a addObject:p];
#endif	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Post Trigger Delay"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:2047 units:@"x10usec"];
    [p setSetMethod:@selector(setPostTriggerTime:) getMethod:@selector(postTriggerTime)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Fifo Behavior"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setFifoBehaviour:) getMethod:@selector(fifoBehaviour)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Analog Offset"];
    [p setFormat:@"##0" upperLimit:4095 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setAnalogOffset:) getMethod:@selector(analogOffset)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Hit Rate Length"];
    [p setFormat:@"##0" upperLimit:8 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setHitRateLength:) getMethod:@selector(hitRateLength)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gap Length"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setGapLength:) getMethod:@selector(gapLength)];
    [a addObject:p];			
#if 0
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"FilterLength"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:2 stepSize:1 units:@""];
    [p setSetMethod:@selector(setFilterLength:) getMethod:@selector(filterLength)];
    [a addObject:p];			
#endif
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORIpeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"OREdelweissFLTModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"OREdelweissFLTModel"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Threshold"])				return  [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Gain"])				return [[cardDictionary objectForKey:@"gains"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Trigger Enabled"])		return [[cardDictionary objectForKey:@"triggersEnabled"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"HitRate Enabled"])		return [[cardDictionary objectForKey:@"hitRatesEnabled"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Post Trigger Time"])	return [cardDictionary objectForKey:@"postTriggerTime"];
    else if([param isEqualToString:@"Run Mode"])			return [cardDictionary objectForKey:@"runMode"];
    else if([param isEqualToString:@"Fifo Behaviour"])		return [cardDictionary objectForKey:@"fifoBehaviour"];
    else if([param isEqualToString:@"Analog Offset"])		return [cardDictionary objectForKey:@"analogOffset"];
    else if([param isEqualToString:@"Hit Rate Length"])		return [cardDictionary objectForKey:@"hitRateLength"];
    else if([param isEqualToString:@"Gap Length"])			return [cardDictionary objectForKey:@"gapLength"];
    else if([param isEqualToString:@"Filter Length"])		return [cardDictionary objectForKey:@"filterLength"];
    else return nil;
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢AdcInfo Providing
- (void) postAdcInfoProvidingValueChanged
{
	//this notification is be picked up by high-level objects like the 
	//Katrin U/I that displays all the thresholds and gains in the system
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAdcInfoProvidingValueChanged object:self];
}

- (BOOL) onlineMaskBit:(int)bit
{
	return [self triggerEnabled:bit];
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Reporting

- (void) printEventFIFOs
{
//TODO: printEventFIFOs UNDER CONSTRUCTION move to SLT? -tb-
#if 0
	uint32_t status = [self readReg: kFLTV4StatusReg];
	int fifoStatus = (status>>24) & 0xf;
	if(fifoStatus != 0x03){
		
		NSLog(@"fifoStatus: 0x%0x\n",(status>>24)&0xf);
		
		uint32_t aValue = [self readReg: kFLTV4EventFifoStatusReg];
		NSLog(@"aValue: 0x%0x\n", aValue);
		NSLog(@"Read: %d\n", (aValue>>16)&0x3ff);
		NSLog(@"Write: %d\n", (aValue>>0)&0x3ff);
		
		uint32_t eventFifo1 = [self readReg: kFLTV4EventFifo1Reg];
		uint32_t channelMap = (eventFifo1>>10)&0xfffff;
		NSLog(@"Channel Map: 0x%0x\n",channelMap);
		
		uint32_t eventFifo2 = [self readReg: kFLTV4EventFifo2Reg];
		uint32_t sec =  ((eventFifo1&0x3ff)<<5) | ((eventFifo2>>27)&0x1f);
		NSLog(@"sec: %d %d\n",((eventFifo2>>27)&0x1f),eventFifo1&0x3ff);
		NSLog(@"Time: %d\n",sec);
		
		int i;
		for(i=0;i<kNumV4FLTChannels;i++){
			if(channelMap & (1<<i)){
				uint32_t eventFifo3 = [self readReg: kFLTV4EventFifo3Reg channel:i];
				uint32_t energy     = [self readReg: kFLTV4EventFifo4Reg channel:i];
				NSLog(@"channel: %d page: %d energy: %d\n\n",i, eventFifo3 & 0x3f, energy);
			}
		}
		NSLog(@"-------\n");
	}
	else NSLog(@"FIFO empty\n");
#endif
}


- (NSString*) boardTypeName:(int)aType
{
	switch(aType){
		case 0:  return @"FZK HEAT";	break;
		case 1:  return @"FZK KATRIN";	break;
		case 2:  return @"FZK USCT";	break;
		case 3:  return @"ITALY HEAT";	break;
		case 4:  return @"EDELWEISS";	break;
		default: return @"UNKNOWN";		break;
	}
}
- (NSString*) fifoStatusString:(int)aType  //TODO: OBSOLETE for EW? -tb-
{
	switch(aType){
		case 0x3:  return @"Empty";			break;
		case 0x2:  return @"Almost Empty";	break;
		case 0x4:  return @"Almost Full";	break;
		case 0xc:  return @"Full";			break;
		default:   return @"UNKNOWN";		break;
	}
}



- (void) printVersions
{
	uint32_t data;
	data = [self readVersion];
	if(0x1f000000 == data){
		NSLogColor([NSColor redColor],@"FLTv4: Could not access hardware, no version register read!\n");
		return;
	}
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"CFPGA Version %u.%u.%u.%u\n",((data>>28)&0xf),((data>>16)&0xfff),((data>>8)&0xff),((data>>0)&0xff));
	NSLogFont(aFont,@"      Version Proj:%u DocRev %u,  Vers. %u, Rev. %u\n",((data>>28)&0xf),((data>>16)&0xfff),((data>>8)&0xff),((data>>0)&0xff));

	switch ( ((data>>28)&0xf) ) {
		case 1: //AUGER
			NSLogFont(aFont,@"    This is a Auger FLTv4 firmware configuration!\n");
			break;
		case 2: //KATRIN
			NSLogFont(aFont,@"    This is a KATRIN FLTv4 firmware configuration!\n");
			break;
		case 4: //EDELWEISS
			NSLogFont(aFont,@"    This is a EDELWEISS FLTv4 firmware configuration!\n");
			break;
		default:
			NSLogFont(aFont,@"    This is a Unknown FLTv4 firmware configuration!\n");
			break;
	}
}

- (void) printStatusReg
{
    //TODO:   needs redesign, some parts remaining from KATRIN  -tb- 2014-07
    //TODO:   needs redesign, some parts remaining from KATRIN  -tb- 2014-07
    //TODO:   needs redesign, some parts remaining from KATRIN  -tb- 2014-07
    //TODO:   needs redesign, some parts remaining from KATRIN  -tb- 2014-07
    //TODO:   needs redesign, some parts remaining from KATRIN  -tb- 2014-07
    //TODO:   needs redesign, some parts remaining from KATRIN  -tb- 2014-07
    //TODO:   needs redesign, some parts remaining from KATRIN  -tb- 2014-07
    //TODO:   needs redesign, some parts remaining from KATRIN  -tb- 2014-07
    
    
	uint32_t status = [self readStatus];
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,@"FLT %d status Reg (address:0x%08x): 0x%08x\n", [self stationNumber],[self regAddress:kFLTV4StatusReg],status);
	NSLogFont(aFont,@"Power           : %@\n",	((status>>0) & 0x1) ? @"FAILED":@"OK");
	NSLogFont(aFont,@"PLL1            : %@\n",	((status>>1) & 0x1) ? @"ERROR":@"OK");
	NSLogFont(aFont,@"PLL2            : %@\n",	((status>>2) & 0x1) ? @"ERROR":@"OK");
	NSLogFont(aFont,@"10MHz Phase     : %@\n",	((status>>3) & 0x1) ? @"UNLOCKED":@"OK");
	NSLogFont(aFont,@"LED (?)         : %@\n",	((status>>15) & 0x1) ? @"OFF":@"ON");
#if 0
	NSLogFont(aFont,@"Firmware Type   : %@\n",	[self boardTypeName:((status>>4) & 0x3)]);
	NSLogFont(aFont,@"Hardware Type   : %@\n",	[self boardTypeName:((status>>6) & 0x3)]);
#endif
	NSLogFont(aFont,@"Busy            : %@\n",	((status>>8) & 0x1) ? @"BUSY":@"IDLE");
	NSLogFont(aFont,@"Interrupt Srcs  : 0x%x\n",	(status>>16) &0xff);
	//TODO: NSLogFont(aFont,@"FIFO Status     : %@\n",	[self fifoStatusString:((status>>24) & 0xf)]);
	NSLogFont(aFont,@"FIFO Status     : 0x%x\n",((status>>24) & 0xf));
	NSLogFont(aFont,@"ATo             : %d\n",	((status>>28) & 0x1));
	NSLogFont(aFont,@"HRo             : %d\n",	((status>>29) & 0x1));
	NSLogFont(aFont,@"IRQ             : %d\n",	((status>>31) & 0x1));
}

- (void) printValueTable
{
//TODO: printValueTable under construction -tb-
	NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
	NSLogFont(aFont,   @"chan | HitRate  | Gain | Threshold\n");
	NSLogFont(aFont,   @"----------------------------------\n");



#if 0
	uint32_t aHitRateMask = [self readHitRateMask];

	//grab all the thresholds and gains using one command packet
	int i;
	ORCommandList* aList = [ORCommandList commandList];
	for(i=0;i<kNumV4FLTChannels;i++){
		[aList addCommand: [self readRegCmd:kFLTV4GainReg channel:i]];
		[aList addCommand: [self readRegCmd:kFLTV4ThresholdReg channel:i]];
	}
	
	[self executeCommandList:aList];
	
	for(i=0;i<kNumV4FLTChannels;i++){
		NSLogFont(aFont,@"%4d | %@ | %4d | %4d \n",i,(aHitRateMask>>i)&0x1 ? @" Enabled":@"Disabled",[aList longValueForCmd:i*2],[aList longValueForCmd:1+i*2]);
	}
#endif
	NSLogFont(aFont,   @"---------------------------------\n");
}

- (void) printStatistics
{
	//TODO:  replace by V4 code -tb-
	NSLog(@"FLTv4: printStatistics not implemented \n");//TODO: needs implementation -tb-
	return;
//    int j;
//    double mean;
//    double var;
//    NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
//    NSLogFont(aFont,@"Statistics      :\n");
//    for (j=0;j<kNumEWFLTHeatIonChannels;j++){
//        [self getStatistics:j mean:&mean var:&var];
//        NSLogFont(aFont,@"  %2d -- %10.2f +/-  %10.2f\n", j, mean, var);
//    }
}

- (void) findNoiseFloors
{
	if(noiseFloorRunning){
		noiseFloorRunning = NO;
	}
	else {
		noiseFloorState = 0;
		noiseFloorRunning = YES;
		[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:0];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTNoiseFloorChanged object:self];
}

- (NSString*) noiseFloorStateString
{
	if(!noiseFloorRunning) return @"Idle";
	else switch(noiseFloorState){
		case 0: return @"Initializing"; 
		case 1: return @"Setting Thresholds";
		case 2: return @"Integrating";
		case 3: return @"Finishing";
		default: return @"?";
	}	
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




@implementation OREdelweissFLTModel (tests)
#pragma mark ‚Ä¢‚Ä¢‚Ä¢Accessors
- (BOOL) testsRunning { return testsRunning; }
- (void) setTestsRunning:(BOOL)aTestsRunning
{
    testsRunning = aTestsRunning;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTestsRunningChanged object:self];
}

- (NSMutableArray*) testEnabledArray { return testEnabledArray; }
- (void) setTestEnabledArray:(NSMutableArray*)aTestEnabledArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTestEnabledArray:testEnabledArray];
    
    [aTestEnabledArray retain];
    [testEnabledArray release];
    testEnabledArray = aTestEnabledArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTestEnabledArrayChanged object:self];  
}

- (NSMutableArray*) testStatusArray { return testStatusArray; }
- (void) setTestStatusArray:(NSMutableArray*)aTestStatusArray
{
    [aTestStatusArray retain];
    [testStatusArray release];
    testStatusArray = aTestStatusArray;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTestStatusArrayChanged object:self];
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
			for(i=0;i<kNumEdelweissFLTTests;i++){
				[testStatusArray replaceObjectAtIndex:i withObject:@"--"];
			}
			
			//create the test suit
			if(testSuit)[testSuit release];
			testSuit = [[ORTestSuit alloc] init];
			if([self testEnabled:0]) [testSuit addTest:[ORTest testSelector:@selector(modeTest) tag:0]];
			if([self testEnabled:1]) [testSuit addTest:[ORTest testSelector:@selector(ramTest) tag:1]];
			if([self testEnabled:2]) [testSuit addTest:[ORTest testSelector:@selector(thresholdGainTest) tag:2]];
			if([self testEnabled:3]) [testSuit addTest:[ORTest testSelector:@selector(speedTest) tag:3]];
			if([self testEnabled:4]) [testSuit addTest:[ORTest testSelector:@selector(eventTest) tag:4]];
			
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
    [[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTModelTestStatusArrayChanged object:self];
}


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Tests
- (void) modeTest
{
//TODO: TESTS DISABLED -tb-
#if 0
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
			fltRunMode = i;
			[self writeControl];
			if([self readMode] != i){
				[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
				passed = NO;
				break;
			}
			if(passed){
				fltRunMode = savedMode;
				[self writeControl];
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
#endif
}


- (void) ramTest
{
	int testNumber = 1;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	@try {
		[self test:testNumber result:@"TBD" color:[NSColor passedColor]];
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
}

- (void) thresholdGainTest
{

#if 0
	int testNumber = 2;
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
			for(chan=0;chan<kNumV4FLTChannels;chan++){
				[self writeThreshold:chan value:thePattern];
			}
			
			for(chan=0;chan<kNumV4FLTChannels;chan++){
				if([self readThreshold:chan] != thePattern){
					[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
					NSLog(@"Error: Threshold (pattern: 0x%0x) FLT %d chan %d does not work\n",thePattern,[self stationNumber],chan);
					passed = NO;
					break;
				}
			}
		}
		if(passed){		
			uint32_t gainPattern[4] = {0xfff,0x0,0xaaa,0x555};
			
			//now gains
			for(testIndex = 0;testIndex<4;testIndex++){
				unsigned short thePattern = gainPattern[testIndex];
				for(chan=0;chan<kNumV4FLTChannels;chan++){
					[self writeGain:chan value:thePattern];
				}
				
				for(chan=0;chan<kNumV4FLTChannels;chan++){
					unsigned short theValue = [self readGain:chan];
					if(theValue != thePattern){
						[self test:testNumber result:@"FAILED" color:[NSColor passedColor]];
						NSLog(@"Error: Gain (pattern: 0x%0x!=0x%0x) FLT %d chan %d does not work\n",thePattern,theValue,[self stationNumber],chan);
						passed = NO;
						break;
					}
				}
			}
		}
		if(passed){	
			uint32_t offsetPattern[4] = {0xfff,0x0,0xaaa,0x555};
			for(testIndex = 0;testIndex<4;testIndex++){
				unsigned short thePattern = offsetPattern[testIndex];
				[self writeReg:kFLTV4AnalogOffset value:thePattern];
				unsigned short theValue = [self readReg:kFLTV4AnalogOffset];
				if(theValue != thePattern){
					NSLog(@"Error: Offset (pattern: 0x%0x!=0x%0x) FLT %d does not work\n",thePattern,theValue,[self stationNumber]);
					passed = NO;
					break;
				}
			}
		}
		
		if(passed) [self test:testNumber result:@"Passed" color:[NSColor passedColor]];
		
		[self loadThresholdsAndGains]; //put the old values back
		
		[self leaveTestMode];
		
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}		
	
	[testSuit runForObject:self]; //do next test
	
#endif
}

- (void) speedTest
{
	int testNumber = 3;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	ORTimer* aTimer = [[ORTimer alloc] init];
	[aTimer start];
	
	@try {
		BOOL passed = YES;
		int numLoops = 250;
		int numPatterns = 4;
		int j;
		for(j=0;j<numLoops;j++){
			uint32_t aPattern[4] = {0xfffffff,0x00000000,0xaaaaaaaa,0x55555555};
			int i;
			for(i=0;i<numPatterns;i++){
				[self writeReg:kFLTV4AccessTestReg value:aPattern[i]];
				uint32_t aValue = [self readReg:kFLTV4AccessTestReg];
				if(aValue!=aPattern[i]){
					NSLog(@"Error: Comm Check (pattern: 0x%0x!=0x%0x) FLT %d does not work\n",aPattern,aValue,[self stationNumber]);
					passed = NO;				
				}
			}
			if(!passed)break;
		}
		[aTimer stop];
		if(passed){
			int totalOps = numLoops*numPatterns*2;
			double secs = [aTimer seconds];
			[self test:testNumber result:[NSString stringWithFormat:@"%.2f/s",totalOps/secs] color:[NSColor passedColor]];
			NSLog(@"Speed Test For FLT %d : %d accesses in %.3f sec\n",[self stationNumber], totalOps,secs);
		}
	}
	@catch(NSException* localException) {
		[self test:testNumber result:@"FAILED" color:[NSColor failedColor]];
	}	
	@finally {
		[aTimer release];
	}
	
	[testSuit runForObject:self]; //do next test
}

- (void) eventTest
{
	int testNumber = 4;
	if(!testsRunning){
		[self runningTest:testNumber status:@"stopped"];
		return;
	}
	
	@try {
		[self test:testNumber result:@"TBD" color:[NSColor passedColor]];
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
				if(i==0)return i; // check only for one error in every page!
			}
		}
	}
	
	return n;
}

@end

@implementation OREdelweissFLTModel (private)

- (void) stepNoiseFloor
{


return;
#if 0
	[[self undoManager] disableUndoRegistration];
	int i;
	BOOL atLeastOne;
    @try {
		switch(noiseFloorState){
			case 0:
				//disable all channels
				for(i=0;i<kNumV4FLTChannels;i++){
					oldEnabled[i]   = [self hitRateEnabled:i];
					oldThreshold[i] = [self threshold:i];
					[self setThreshold:i withValue:0x7fff];
					newThreshold[i] = 0x7fff;
				}
				atLeastOne = NO;
				for(i=0;i<kNumV4FLTChannels;i++){
					if(oldEnabled[i]){
						noiseFloorLow[i]			= 0;
						noiseFloorHigh[i]		= 0x7FFF;
						noiseFloorTestValue[i]	= 0x7FFF/2;              //Initial probe position
						[self setThreshold:i withValue:noiseFloorHigh[i]];
						atLeastOne = YES;
					}
				}
				
				[self initBoard];
				
				if(atLeastOne)	noiseFloorState = 1;
				else			noiseFloorState = 4; //nothing to do
			break;
				
			case 1:
				for(i=0;i<kNumV4FLTChannels;i++){
					if([self hitRateEnabled:i]){
						if(noiseFloorLow[i] <= noiseFloorHigh[i]) {
							[self setThreshold:i withValue:noiseFloorTestValue[i]];
							
						}
						else {
							newThreshold[i] = MAX(0,noiseFloorTestValue[i] + noiseFloorOffset);
							[self setThreshold:i withValue:0x7fff];
							//hitRateEnabledMask &= ~(1L<<i);
						}
					}
				}
				[self initBoard];
				
				//if(hitRateEnabledMask)	noiseFloorState = 2;	//go check for data
				//else					noiseFloorState = 3;	//done
			break;
				
			case 2:
				//read the hitrates
				[self readHitRates];
				
				for(i=0;i<kNumV4FLTChannels;i++){
					if([self hitRateEnabled:i]){
						if([self hitRate:i] > targetRate){
							//the rate is too high, bump the threshold up
							[self setThreshold:i withValue:0x7fff];
							noiseFloorLow[i] = noiseFloorTestValue[i] + 1;
						}
						else noiseFloorHigh[i] = noiseFloorTestValue[i] - 1;									//no data so continue lowering threshold
						noiseFloorTestValue[i] = noiseFloorLow[i]+((noiseFloorHigh[i]-noiseFloorLow[i])/2);     //Next probe position.
					}
				}
				
				[self initBoard];
				
				noiseFloorState = 1;
				break;
								
			case 3: //finish up	
				//load new results
				for(i=0;i<kNumV4FLTChannels;i++){
					[self setHitRateEnabled:i withValue:oldEnabled[i]];
					[self setThreshold:i withValue:newThreshold[i]];
				}
				[self initBoard];
				noiseFloorRunning = NO;
			break;
		}
		if(noiseFloorRunning){
			float timeToWait;
			if(noiseFloorState==2)	timeToWait = pow(2.,hitRateLength)* 1.5;
			else					timeToWait = 0.2;
			[self performSelector:@selector(stepNoiseFloor) withObject:self afterDelay:timeToWait];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:OREdelweissFLTNoiseFloorChanged object:self];
    }
	@catch(NSException* localException) {
        int i;
        for(i=0;i<kNumV4FLTChannels;i++){
            [self setHitRateEnabled:i withValue:oldEnabled[i]];
            [self setThreshold:i withValue:oldThreshold[i]];
			//[self reset];
			[self initBoard];
        }
		NSLog(@"FLT4 LED threshold finder quit because of exception\n");
    }
	[[self undoManager] enableUndoRegistration];
#endif
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
//TODO: TESTS DISABLED -tb-
#if 0
	//put into test mode
	savedMode = fltRunMode;
	fltRunMode = kIpeFltV4Katrin_StandBy_Mode; //TODO: test mode has changed for V4 -tb- kIpeFltV4Katrin_Test_Mode;
	[self writeControl];
	//if([self readMode] != kIpeFltV4Katrin_Test_Mode){
	if(1){//TODO: test mode has changed for V4 -tb-
		NSLogColor([NSColor redColor],@"Could not put FLT %d into test mode\n",[self stationNumber]);
		[NSException raise:@"Ram Test Failed" format:@"Could not put FLT %d into test mode\n",[self stationNumber]];
	}
#endif
}

- (void) leaveTestMode
{
//TODO: TESTS DISABLED -tb-
#if 0

	fltRunMode = savedMode;
	[self writeControl];
#endif
}
@end
