//
//  TUBiiController.m
//  Orca
//
//  Created by Ian Coulter on 9/15/15.
//
//

#import "TUBiiController.h"
#import "TUBiiModel.h"
//Defs to map between tab number and tab name
#define TUBII_GUI_TUBII_TAB_NUM 0
#define TUBII_GUI_PULSER_TAB_NUM 1
#define TUBII_GUI_TRIGGER_TAB_NUM 2
#define TUBII_GUI_SPEAKER_TAB_NUM 5
#define TUBII_GUI_ANALOG_TAB_NUM 3
#define TUBII_GUI_GTDELAY_TAB_NUM 4
#define TUBII_GUI_CLOCK_TAB_NUM 6

@implementation TUBiiController

- (id)init{
    // Initialize by launching the GUI, referenced by the name of the xib/nib file
    self = [super initWithWindowNibName:@"TUBii"];
    return self;
}
- (void) awakeFromNib
{
    Tubii_size = NSMakeSize(450, 400);
    PulserAndDelays_size = NSMakeSize(500, 350);
    Triggers_size = NSMakeSize(600, 680);
    Analog_size = NSMakeSize(615, 445);
    GTDelays_size = NSMakeSize(500, 250);
    SpeakerCounter_size_small = NSMakeSize(575,550);
    SpeakerCounter_size_big = NSMakeSize(575,650);
    ClockMonitor_size = NSMakeSize(500, 175);
    blankView = [[NSView alloc] init];
    [tabView setFocusRingType:NSFocusRingTypeNone];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
    
    [super awakeFromNib];
    [self tubiiCurrentModelStateChanged:nil];
    [tabView setDelegate:self];

    [CounterAdvancedOptionsBox setHidden:YES];
    [caenChannelSelect_3 setEnabled:NO];//Not currently working on board
    [self updateWindow];

}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    //we don't want this notification
    [notifyCenter removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(tubiiLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(tubiiLockChanged:)
                         name : ORTubiiLockNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(tubiiCurrentModelStateChanged:)
                         name : ORTubiiSettingsChangedNotification
                       object : nil];

}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORTubiiLockNotification to:secure];
    [tubiiLockButton setEnabled:secure];
}

- (void) tubiiLockChanged:(NSNotification*)aNotification
{
    
    //Basic ops
    BOOL locked						= [gSecurity isLocked:ORTubiiLockNotification];
    BOOL lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORTubiiLockNotification];
    
    //Tubii
    [tubiiLockButton setState: locked];
    [tubiiIPField setEnabled: !locked];
    [tubiiPortField setEnabled: !locked];
    [tubiiInitButton setEnabled: !locked];
    [tubiiDataReadoutButton setEnabled: !lockedOrNotRunningMaintenance];
    [ECA_EnableButton setEnabled: !lockedOrNotRunningMaintenance];

    //Pulsers & Delays
    [SmellieRate_TextField setEnabled: !locked];
    [SmellieWidth_TextField setEnabled: !locked];
    [SmellieNPulses_TextField setEnabled: !locked];
    [TellieRate_TextField setEnabled: !locked];
    [TellieWidth_TextField setEnabled: !locked];
    [TellieNPulses_TextField setEnabled: !locked];
    [fireSmellieButton setEnabled: !lockedOrNotRunningMaintenance];
    [stopSmellieButton setEnabled: !lockedOrNotRunningMaintenance];
    [fireTellieButton setEnabled: !lockedOrNotRunningMaintenance];
    [stopTellieButton setEnabled: !lockedOrNotRunningMaintenance];
    [SmellieDelay_TextField setEnabled: !locked];
    [TellieDelay_TextField setEnabled: !locked];
    [GenericDelay_TextField setEnabled: !locked];
    [GenericRate_TextField setEnabled: !locked];
    [GenericWidth_TextField setEnabled: !locked];
    [GenericNPulses_TextField setEnabled: !locked];
    [loadSmellieButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadTellieButton setEnabled: !lockedOrNotRunningMaintenance];
    [loadDelayButton setEnabled: !lockedOrNotRunningMaintenance];
    [firePulserButton setEnabled: !lockedOrNotRunningMaintenance];
    [stopPulserButton setEnabled: !lockedOrNotRunningMaintenance];
    
    //Triggers
    [TrigMaskSelect setEnabled: !locked];
    [sendTriggerMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [matchHWButton setEnabled: !locked];
    [BurstRate setEnabled: !locked];
    [BurstTriggerMask setEnabled: !locked];
    [sendBurstButton setEnabled: !lockedOrNotRunningMaintenance];
    [ComboEnableMask setEnabled: !locked];
    [ComboTriggerMask setEnabled: !locked];
    [sendComboButton setEnabled: !lockedOrNotRunningMaintenance];
    [PrescaleFactor setEnabled: !locked];
    [PrescaleTriggerMask setEnabled: !locked];
    [sendPrescaleButton setEnabled: !lockedOrNotRunningMaintenance];
    [TUBiiPGTRate setEnabled: !locked];
    [sendTUBiiPGTStart setEnabled: !lockedOrNotRunningMaintenance];
    [sendTUBiiPGTStop setEnabled: !lockedOrNotRunningMaintenance];
    [MTCAMimic_Slider setEnabled: !locked];
    [MTCAMimic_TextField setEnabled: !locked];
    [sendMTCAButton setEnabled: !lockedOrNotRunningMaintenance];
    [matchMTCAButton setEnabled: !locked];
    //Make sure the sync/async mask are properly disabled
    if(!locked){
        NSUInteger trigMaskVal = ([model currentModelState].syncTrigMask | [model currentModelState].asyncTrigMask);
        [self disableMask:trigMaskVal ForCheckBoxes:TrigMaskSelect FromBit:24 ToBit:48];
    }

    //Analog
    [caenChannelSelect_0 setEnabled: !locked];
    [caenChannelSelect_1 setEnabled: !locked];
    [caenChannelSelect_2 setEnabled: !locked];
    [caenChannelSelect_3 setEnabled: !locked];
    [caenGainSelect_0 setEnabled: !locked];
    [caenGainSelect_1 setEnabled: !locked];
    [caenGainSelect_2 setEnabled: !locked];
    [caenGainSelect_3 setEnabled: !locked];
    [caenGainSelect_4 setEnabled: !locked];
    [caenGainSelect_5 setEnabled: !locked];
    [caenGainSelect_6 setEnabled: !locked];
    [caenGainSelect_7 setEnabled: !locked];
    [matchAnalogButton setEnabled: !locked];
    [sendAnalogButton setEnabled: !lockedOrNotRunningMaintenance];

    //GT Delays
    [LO_SrcSelect setEnabled: !locked];
    [LO_Field setEnabled: !locked];
    [DGT_Field setEnabled: !locked];
    [LO_Slider setEnabled: !locked];
    [DGT_Slider setEnabled: !locked];
    [matchGTDelaysButton setEnabled: !locked];
    [sendGTDelaysButton setEnabled: !lockedOrNotRunningMaintenance];

    //Speaker & Counter
    [SpeakerMaskSelect_1 setEnabled: !locked];
    [SpeakerMaskSelect_2 setEnabled: !locked];
    [SpeakerMaskField setEnabled: !locked];
    [matchSpeakerButton setEnabled: !locked];
    [checkSpeakerButton setEnabled: !locked];
    [uncheckSpeakerButton setEnabled: !locked];
    [CounterMaskSelect_1 setEnabled: !locked];
    [CounterMaskSelect_2 setEnabled: !locked];
    [CounterMaskField setEnabled: !locked];
    [matchCounterButton setEnabled: !locked];
    [checkCounterButton setEnabled: !locked];
    [uncheckCounterButton setEnabled: !locked];
    [CounterLZBSelect setEnabled: !locked];
    [CounterTestModeSelect setEnabled: !locked];
    [CounterInhibitSelect setEnabled: !locked];
    [CounterModeSelect setEnabled: !locked];
    [sendSpeakerButton setEnabled: !lockedOrNotRunningMaintenance];
    [sendCounterButton setEnabled: !lockedOrNotRunningMaintenance];

    //Clock Monitor
    [DefaultClockSelect setEnabled: !locked];
    [matchClockButton setEnabled: !locked];
    [sendClockButton setEnabled: !lockedOrNotRunningMaintenance];
    [resetClockButton setEnabled: !lockedOrNotRunningMaintenance];
    
}

- (void) tubiiCurrentModelStateChanged:(NSNotification *)aNote
{

    /* Change GUI to match the current state of the model */
    struct TUBiiState theTUBiiState = [model currentModelState];
    // TrigMasks
    NSUInteger trigMaskVal = (theTUBiiState.syncTrigMask | theTUBiiState.asyncTrigMask);
    NSUInteger syncMaskVal = 0xFFFFFF - theTUBiiState.asyncTrigMask;
    [self disableMask:trigMaskVal ForCheckBoxes:TrigMaskSelect FromBit:24 ToBit:48];
    [self SendBitInfo:trigMaskVal FromBit:0 ToBit:24 ToCheckBoxes:TrigMaskSelect];
    [self SendBitInfo:syncMaskVal FromBit:24 ToBit:48 ToCheckBoxes:TrigMaskSelect];
    //CAEN
    CAEN_CHANNEL_MASK ChannelMask = theTUBiiState.CaenChannelMask;
    CAEN_GAIN_MASK GainMask = theTUBiiState.CaenGainMask;
    [caenChannelSelect_0 selectCellWithTag:(ChannelMask & channelSel_0)>0];
    [caenChannelSelect_1 selectCellWithTag:(ChannelMask & channelSel_1)>0];
    [caenChannelSelect_2 selectCellWithTag:(ChannelMask & channelSel_2)>0];
    [caenChannelSelect_3 selectCellWithTag:(ChannelMask & channelSel_3)>0];
    [caenGainSelect_0 selectCellWithTag:(GainMask & gainSel_0)>0];
    [caenGainSelect_1 selectCellWithTag:(GainMask & gainSel_1)>0];
    [caenGainSelect_2 selectCellWithTag:(GainMask & gainSel_2)>0];
    [caenGainSelect_3 selectCellWithTag:(GainMask & gainSel_3)>0];
    [caenGainSelect_4 selectCellWithTag:(GainMask & gainSel_4)>0];
    [caenGainSelect_5 selectCellWithTag:(GainMask & gainSel_5)>0];
    [caenGainSelect_6 selectCellWithTag:(GainMask & gainSel_6)>0];
    [caenGainSelect_7 selectCellWithTag:(GainMask & gainSel_7)>0];
    //Speaker
    [SpeakerMaskField setStringValue:[NSString stringWithFormat:@"%@",@(theTUBiiState.speakerMask)]];
    [self SendBitInfo:theTUBiiState.speakerMask FromBit:0 ToBit:16 ToCheckBoxes:SpeakerMaskSelect_1];
    [self SendBitInfo:(theTUBiiState.speakerMask>>16) FromBit:16 ToBit:32 ToCheckBoxes:SpeakerMaskSelect_2];
    //Counter
    [CounterMaskField setStringValue:[NSString stringWithFormat:@"%@",@(theTUBiiState.counterMask)]];
    [self SendBitInfo:theTUBiiState.counterMask FromBit:0 ToBit:16 ToCheckBoxes:CounterMaskSelect_1];
    [self SendBitInfo:(theTUBiiState.counterMask>>16) FromBit:16 ToBit:32 ToCheckBoxes:CounterMaskSelect_2];
    //GTDelay
    float LO_Delay = [model LODelay_BitsToNanoSeconds:theTUBiiState.LO_Bits];
    [LO_Slider setIntValue:LO_Delay];
    [LO_Field setIntegerValue:LO_Delay];
    float DGT_Delay = [model DGT_BitsToNanoSeconds:theTUBiiState.DGT_Bits];
    [DGT_Slider setIntValue:DGT_Delay];
    [DGT_Field setIntValue:DGT_Delay];
    if ((theTUBiiState.controlReg & lockoutSel_Bit)>0){
        [LO_SrcSelect selectCellWithTag:1];
    }
    else {
        [LO_SrcSelect selectCellWithTag:2];
    }
    if([[LO_SrcSelect selectedCell] tag]==1){ //MTCD is selected
        [LO_Field setEnabled:NO];
        [LO_Slider setEnabled:NO];
    }
    else { //TUBii is selected
        [LO_Field setEnabled:YES];
        [LO_Slider setEnabled:YES];
    }
    //MTCA mimic
    float ThresholdValue = [model MTCAMimic_BitsToVolts:theTUBiiState.MTCAMimic1_ThresholdInBits];
    [MTCAMimic_Slider setFloatValue:ThresholdValue];
    [MTCAMimic_TextField setFloatValue:ThresholdValue];
    //Clock Source
    CONTROL_REG_MASK cntrl_reg = theTUBiiState.controlReg;
    if(cntrl_reg & clkSel_Bit) {
        [DefaultClockSelect selectCellWithTag:1]; //TUBii Clk is tag 1
    }
    else {
        [DefaultClockSelect selectCellWithTag:2];//TUB Clk is tag 2
    }
    //TUBiiPGT
    float rate = theTUBiiState.TUBiiPGT_Rate;
    [TUBiiPGTRate setFloatValue:rate];

}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    int tabIndex = [aTabView indexOfTabViewItem:item];
    NSSize* newSize = nil;
    switch (tabIndex) {
        case TUBII_GUI_PULSER_TAB_NUM:
            newSize = &PulserAndDelays_size;
            break;
        case TUBII_GUI_TRIGGER_TAB_NUM:
            newSize = &Triggers_size;
            break;
        case TUBII_GUI_TUBII_TAB_NUM:
            newSize = &Tubii_size;
            break;
        case TUBII_GUI_ANALOG_TAB_NUM:
            newSize = &Analog_size;
            break;
        case TUBII_GUI_GTDELAY_TAB_NUM:
            newSize = &GTDelays_size;
            break;
        case TUBII_GUI_SPEAKER_TAB_NUM:
            if([CounterAdvancedOptionsBox isHidden]) {
            newSize = &SpeakerCounter_size_small;
            }
            else {
                newSize = &SpeakerCounter_size_big;
            }
            break;
        case TUBII_GUI_CLOCK_TAB_NUM:
            newSize = &ClockMonitor_size;
            break;
        default:
            break;
    }
    if (newSize) {
        [[self window] setContentView:blankView]; //Put in a blank view for nicer transition look
        [self resizeWindowToSize:*newSize];
        [[self window] setContentView:tabView];
    }

}

#pragma mark •••Actions
- (IBAction)tubiiLockAction:(id)sender {
    [gSecurity tryToSetLock:ORTubiiLockNotification to:[sender intValue] forWindow:[self window]];
}
- (IBAction)InitializeClicked:(id)sender {
    @try{
        [model Initialize];
    } @catch (NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)SendPing:(id)sender {
    @try{
        [model Ping];
        NSLog(@"TUBii ping successful.\n");
    } @catch (NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)DataReadoutChanged:(id)sender {
    if ([[sender selectedCell] tag] == 1) { //Data Readout On is selected
        @try{
            [model setDataReadout:YES];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else { //Data Readout Off is selected
        @try{
            [model setDataReadout:NO];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    return;
}
- (IBAction)PulserFire:(id)sender {
    //Eventually these functions should be changed to use setting the values like they were settings
    //rather then just sending them all at once.
    if ([sender tag] == 1){
        //Smellie Pulser is being fired
        @try{
            [model fireSmelliePulser_rate:[SmellieRate_TextField floatValue] pulseWidth:[SmellieWidth_TextField doubleValue] NPulses:[SmellieNPulses_TextField intValue]];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if([sender tag] == 2){
        //Tellie Pulser is being fired
        @try{
            [model fireTelliePulser_rate:[TellieRate_TextField floatValue] pulseWidth:[TellieWidth_TextField doubleValue] NPulses:[TellieNPulses_TextField intValue]];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if([sender tag] == 3){
        //Generic Pulser is being fired
        @try{
            [model firePulser_rate:[ GenericRate_TextField floatValue] pulseWidth:[GenericWidth_TextField doubleValue] NPulses:[GenericNPulses_TextField intValue]];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    return;
}
- (IBAction)PulserStop:(id)sender {
    //Stops the pulser from sending anymore pulses
    if([sender tag] == 1){
        @try{
            [model stopSmelliePulser];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if([sender tag] == 2){
        @try{
            [model stopTelliePulser];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if([sender tag] == 3){
        @try{
            [model stopPulser];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    return;
}
- (IBAction)LoadDelay:(id)sender {
    //Sends the selected delay value to TUBii
    int delay =0;
    if([sender tag] == 1){
        delay = [SmellieDelay_TextField integerValue];
        @try{
            [model setSmellieDelay:delay];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if([sender tag] == 2){
        delay = [TellieDelay_TextField integerValue];
        @try{
            [model setTellieDelay:delay];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if([sender tag] == 3){
        delay = [GenericDelay_TextField integerValue];
        @try{
            [model setGenericDelay:delay];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    return;
}
- (IBAction)TrigMaskMatchHardware:(id)sender {
    //Makes the trigger mask GUI element match TUBii's hardware state
    NSUInteger syncMask;
    NSUInteger asyncMask;
    @try {
        syncMask = [model syncTrigMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    @try {
        asyncMask = [model asyncTrigMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    [model setTrigMaskInState:syncMask setAsyncMask:asyncMask];
}

- (IBAction)TrigMaskLoad:(id)sender {
    NSUInteger syncMask = [model currentModelState].syncTrigMask;
    NSUInteger asyncMask = [model currentModelState].asyncTrigMask;
    @try{
        [model setTrigMask:syncMask setAsyncMask:asyncMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}

- (IBAction)BurstTriggerLoad:(id)sender {
    NSLog(@"Not yet implemented. :(");
}

- (IBAction)ComboTriggerLoad:(id)sender {
    NSUInteger enableMask = [ComboEnableMask integerValue];
    NSUInteger triggerMask = [ComboTriggerMask integerValue];
    @try{
        [model setComboTrigger_EnableMask:enableMask TriggerMask:triggerMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)PrescaleTriggerLoad:(id)sender {
    float factor = [PrescaleFactor floatValue];
    NSUInteger mask = [PrescaleTriggerMask integerValue];
    @try{
        [model setPrescaleTrigger_Mask:mask ByFactor:factor];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)TUBiiPGTLoad:(id)sender {
    float rate = [model currentModelState].TUBiiPGT_Rate;
    @try{
        [model setTUBiiPGT_Rate:rate];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)TUBiiPGTStop:(id)sender {
    float rate = 0;
    @try{
        [model setTUBiiPGT_Rate:rate];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}

- (IBAction)CaenMatchHardware:(id)sender {
    //Makes the CAEN GUI reflect the current hardware state
    CAEN_CHANNEL_MASK ChannelMask;
    CAEN_GAIN_MASK GainMask;
    @try {
        ChannelMask = [model caenChannelMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    @try {
        GainMask = [model caenGainMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    [model setCaenMasksInState:ChannelMask GainMask:GainMask];
}
- (IBAction)CaenLoadMask:(id)sender {
    //Sends the CAEN GUI values to TUBii
    CAEN_CHANNEL_MASK ChannelMask = [model currentModelState].CaenChannelMask;
    CAEN_GAIN_MASK GainMask=[model currentModelState].CaenGainMask;
    @try{
        [model setCaenMasks:ChannelMask GainMask:GainMask];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }

}

- (IBAction)SpeakerMatchHardware:(id)sender {
    //Makes the Speaker/Counter GUI elements match the hardware
    NSUInteger maskVal =0;
    if ([sender tag] ==1)
    {
        @try {
            maskVal = [model speakerMask];
            [model setSpeakerMaskInState:maskVal];
        } @catch(NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if ([sender tag]==2)
    {
        @try {
            maskVal = [model counterMask];
            [model setCounterMaskInState:maskVal];
        } @catch(NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
}
- (IBAction)CounterMatchHardware:(id)sender {
    [self SpeakerMatchHardware:sender]; //Bit of a hack. I should probably rename the function
    CONTROL_REG_MASK ControlRegVal;
    BOOL counter_mode;
    @try {
        ControlRegVal = [model controlReg];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    
    [CounterLZBSelect setState: (ControlRegVal & scalerLZB_Bit) > 0 ? NSOnState : NSOffState ];
    [CounterTestModeSelect setState: (ControlRegVal & scalerT_Bit) > 0 ? NSOffState : NSOnState ]; //Unchecked = bit high
    [CounterInhibitSelect setState: (ControlRegVal & scalerI_Bit) > 0 ? NSOffState : NSOnState ]; //Unchecked = bit high
    @try {
        counter_mode = [model CounterMode];
        [model setCounterModeInState:counter_mode];
    } @catch (NSException *exception) {
        [self log_error:exception];
        return;
    }
    
    if (counter_mode) {
        [CounterModeSelect selectCellWithTag:1];
    }
    else {
        [CounterModeSelect selectCellWithTag:0];
    }
}

- (IBAction)SpeakerLoadMask:(id)sender {

    if ([sender tag] ==1) {
        NSUInteger maskVal= [model currentModelState].speakerMask;
        @try{
            [model setSpeakerMask:maskVal];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else if ([sender tag] ==2)
    {
        NSUInteger maskVal= [model currentModelState].counterMask;
        @try{
            [model setCounterMask:maskVal];
        } @catch (NSException *exception) {
            [self log_error:exception];
            return;
        }
    }

}

- (IBAction)CounterLoadMask:(id)sender {
    [self SpeakerLoadMask:sender];

    CONTROL_REG_MASK newControlReg = [model currentModelState].controlReg;
    @try{
        [model setControlReg:newControlReg];
    } @catch (NSException *exception) {
        [self log_error:exception];
        return;
    }
    @try {
        [model setCounterMode:[model currentModelState].CounterMode];
    } @catch (NSException *exception) {
        [self log_error:exception];
        return;
    }
}

- (IBAction)SpeakerFieldChanged:(id)sender {
    NSUInteger maskVal =[SpeakerMaskField integerValue];
    [self SendBitInfo:maskVal FromBit:0 ToBit:16 ToCheckBoxes:SpeakerMaskSelect_1];
    [self SendBitInfo:(maskVal>>16) FromBit:16 ToBit:32 ToCheckBoxes:SpeakerMaskSelect_2];
}
- (IBAction)CounterFieldChanged:(id)sender {
    NSUInteger maskVal =[CounterMaskField integerValue];
    [self SendBitInfo:maskVal FromBit:0 ToBit:16 ToCheckBoxes:CounterMaskSelect_1];
    [self SendBitInfo:(maskVal>>16) FromBit:16 ToBit:32 ToCheckBoxes:CounterMaskSelect_2];
}

- (IBAction)SpeakerCounterCheckAll:(id)sender {
    NSUInteger maskVal;
    NSMatrix *maskSelect_1 =nil;
    NSMatrix *maskSelect_2 =nil;
    NSTextField *maskField =nil;
    if([sender tag] ==1)
    {
        maskSelect_1 = SpeakerMaskSelect_1;
        maskSelect_2 = SpeakerMaskSelect_2;
        maskField = SpeakerMaskField;
    }
    else if([sender tag] == 2)
    {
        maskSelect_1 = CounterMaskSelect_1;
        maskSelect_2 = CounterMaskSelect_2;
        maskField = CounterMaskField;
    }
    else{
        return;
    }
    [maskSelect_1 selectAll:nil];
    [maskSelect_2 selectAll:nil];
    maskVal = [self GetBitInfoFromCheckBoxes:maskSelect_1 FromBit:0 ToBit:16];
    maskVal |= [self GetBitInfoFromCheckBoxes:maskSelect_2 FromBit:16 ToBit:32]<<16;
    [maskField setStringValue:[NSString stringWithFormat:@"%@",@(maskVal)]];

    if ([sender tag] ==1) {
        [model setSpeakerMaskInState:maskVal];
    } else if ([sender tag] ==2){
        [model setCounterMaskInState:maskVal];
    }

}
- (IBAction)SpeakerCounterUnCheckAll:(id)sender {
    NSMatrix *maskSelect_1 =nil;
    NSMatrix *maskSelect_2 =nil;
    NSTextField *maskField =nil;
    if([sender tag] ==1)
    {
        maskSelect_1 = SpeakerMaskSelect_1;
        maskSelect_2 = SpeakerMaskSelect_2;
        maskField = SpeakerMaskField;
    }
    else if([sender tag] == 2)
    {
        maskSelect_1 = CounterMaskSelect_1;
        maskSelect_2 = CounterMaskSelect_2;
        maskField = CounterMaskField;
    }
    else{
        return;
    }
    [maskSelect_1 deselectAllCells];
    [maskSelect_2 deselectAllCells];

    [maskField setStringValue:[NSString stringWithFormat:@"%i",0]];

    if ([sender tag] ==1) {
        [model setSpeakerMaskInState:0];
    } else if ([sender tag] ==2){
        [model setCounterMaskInState:0];
    }

}
- (IBAction)AdvancedOptionsButtonChanged:(id)sender{
    if([sender state] == NSOffState){
        [CounterAdvancedOptionsBox setHidden:YES];
        [self resizeWindowToSize:SpeakerCounter_size_small];
    }
    else{
        [CounterAdvancedOptionsBox setHidden:NO];
        if(self.window.frame.size.height < SpeakerCounter_size_big.height){
            [self resizeWindowToSize:SpeakerCounter_size_big];
        }
    }
}

- (IBAction)GTDelaysLoadMask:(id)sender {
    float LO_Delay = [model LODelay_BitsToNanoSeconds:[model currentModelState].LO_Bits];
    float DGT_Delay = [model DGT_BitsToNanoSeconds:[model currentModelState].DGT_Bits];
    @try{
        [model setGTDelaysInNS:DGT_Delay LOValue:LO_Delay];
    } @catch (NSException* exception) {
        [self log_error:exception];
        return;
    }

    if([[LO_SrcSelect selectedCell] tag] ==1){
        //MTCD is LO Src is selected
        @try{
            [model setTUBiiIsLOSrc:NO];
        } @catch (NSException* exception) {
            [self log_error:exception];
            return;
        }
    }
    else {
        //TUBii is LO Src is selected
        @try{
            [model setTUBiiIsLOSrc:YES];
        } @catch (NSException* exception) {
            [self log_error:exception];
            return;
        }
    }
}
- (IBAction)GTDelaysMatchHardware:(id)sender {
    float LO_Delay;
    float DGT_Delay;
    CONTROL_REG_MASK controlReg;
    @try {
        DGT_Delay = [model DGTBits];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    @try {
        LO_Delay = [model LODelayBits];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    [model setGTDelaysBitsInState:DGT_Delay LOBits:LO_Delay];
    @try {
        controlReg = [model controlReg];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    [model setControlRegInState:controlReg];

}

- (IBAction)LOSrcSelectAction:(id)sender {
    if([[LO_SrcSelect selectedCell] tag] ==1){
        //MTCD is LO Src is selected
        [model setTUBiiIsLOSrcInState:NO];
    }
    else {
        //TUBii is LO Src is selected
        [model setTUBiiIsLOSrcInState:YES];
    }
}

- (IBAction)ResetClock:(id)sender {
    @try{
        [model ResetClock];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)ECAEnableChanged:(id)sender {
    if([[ECA_EnableButton selectedCell] tag]==1){ //ECA mode On is selected
        @try{
            [model setECALMode: YES];
        } @catch(NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
    else { //ECA mode Off is selected
        @try{
            [model setECALMode: NO];
        } @catch(NSException *exception) {
            [self log_error:exception];
            return;
        }
    }
}

- (IBAction)MTCAMimicMatchHardware:(id)sender {
    NSUInteger ThresholdValue;
    @try {
        ThresholdValue = [model MTCAMimic1_ThresholdInBits];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }    //Bit value of the DAC
    [model setMTCAMimic1_ThresholdInBitsInState:ThresholdValue];
}
- (IBAction)MTCAMimicLoadValue:(id)sender {
    float ThresholdValue = [model MTCAMimic_BitsToVolts:[model currentModelState].MTCAMimic1_ThresholdInBits];
    @try {
        [model setMTCAMimic1_ThresholdInVolts:ThresholdValue];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}

- (IBAction)LoadClockSource:(id)sender {
    BOOL tubii_is_default = ([[DefaultClockSelect selectedCell] tag] == 1);
    @try {
        [model setTUBiiIsDefaultClock: tubii_is_default];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
}
- (IBAction)ClockSourceMatchHardware:(id)sender {
    CONTROL_REG_MASK cntrl_reg;
    @try {
        cntrl_reg = [model controlReg];
    } @catch(NSException *exception) {
        [self log_error:exception];
        return;
    }
    [model setControlRegInState:cntrl_reg];
}

- (IBAction)trigMaskAction:(id)sender {
    NSUInteger trigMaskVal = [self GetBitInfoFromCheckBoxes:sender FromBit:0 ToBit:24];
    NSUInteger syncMaskVal = [self GetBitInfoFromCheckBoxes:sender FromBit:24 ToBit:48];
    NSUInteger syncMask=0, asyncMask=0;
    for(int i=0; i<24; i++)
    {
        if(syncMaskVal & (1<<i))
        {
            if(trigMaskVal & (1<<i))
                syncMask |= 1<<i;
            else
                syncMask &= ~(1<<i);
            asyncMask &= ~(1<<i);
        }
        else
        {
            if(trigMaskVal & (1<<i))
                asyncMask |= 1<<i;
            else
                asyncMask &= ~(1<<i);
            syncMask &= ~(1<<i);
        }
    }

    [model setTrigMaskInState:syncMask setAsyncMask:asyncMask];

}

- (IBAction)PGTRateAction:(id)sender {

    float rate = [sender floatValue];
    [model setTUBiiPGT_RateInState:rate];

}

- (IBAction)CAENMaskAction:(id)sender {

    //Sends the CAEN GUI values to TUBii
    CAEN_CHANNEL_MASK ChannelMask =0;
    CAEN_GAIN_MASK GainMask=0;
    ChannelMask |= [[caenChannelSelect_0 selectedCell] tag ]*channelSel_0;
    ChannelMask |= [[caenChannelSelect_1 selectedCell] tag ]*channelSel_1;
    ChannelMask |= [[caenChannelSelect_2 selectedCell] tag ]*channelSel_2;
    ChannelMask |= [[caenChannelSelect_3 selectedCell] tag ]*channelSel_3;
    GainMask |= [[caenGainSelect_0 selectedCell] tag ]*gainSel_0;
    GainMask |= [[caenGainSelect_1 selectedCell] tag ]*gainSel_1;
    GainMask |= [[caenGainSelect_2 selectedCell] tag ]*gainSel_2;
    GainMask |= [[caenGainSelect_3 selectedCell] tag ]*gainSel_3;
    GainMask |= [[caenGainSelect_4 selectedCell] tag ]*gainSel_4;
    GainMask |= [[caenGainSelect_5 selectedCell] tag ]*gainSel_5;
    GainMask |= [[caenGainSelect_6 selectedCell] tag ]*gainSel_6;
    GainMask |= [[caenGainSelect_7 selectedCell] tag ]*gainSel_7;
    [model setCaenMasksInState:ChannelMask GainMask:GainMask];

}

- (IBAction)SpeakerCounterMaskAction:(id)sender {

    NSUInteger maskVal=0;
    if ([sender tag] ==1){
        maskVal = [self GetBitInfoFromCheckBoxes:SpeakerMaskSelect_1 FromBit:0 ToBit:16];
        maskVal |= [self GetBitInfoFromCheckBoxes:SpeakerMaskSelect_2 FromBit:16 ToBit:32]<<16;
        [SpeakerMaskField setStringValue:[NSString stringWithFormat:@"%@",@(maskVal)]];
        [model setSpeakerMaskInState:maskVal];
    }
    else if ([sender tag]==2){
        maskVal = [self GetBitInfoFromCheckBoxes:CounterMaskSelect_1 FromBit:0 ToBit:16];
        maskVal |= ([self GetBitInfoFromCheckBoxes:CounterMaskSelect_2 FromBit:16 ToBit:32]<<16);
        [CounterMaskField setStringValue:[NSString stringWithFormat:@"%@",@(maskVal)]];
        [model setCounterMaskInState:maskVal];
    }

}

- (IBAction)CounterMaskAction:(id)sender {

    CONTROL_REG_MASK newControlReg;
    newControlReg = [model currentModelState].controlReg;
    newControlReg |=  [CounterLZBSelect intValue] ==1 ? scalerLZB_Bit : 0;
    newControlReg |=  [CounterTestModeSelect intValue] ==1 ? 0 : scalerT_Bit;
    newControlReg |=  [CounterInhibitSelect intValue] ==1 ? 0 : scalerI_Bit;

    [model setControlRegInState:newControlReg];

}

- (IBAction)CounterModeAction:(id)sender {

    if ([CounterModeSelect selectedColumn] == 0) {
        //Rate Mode is selected
        [model setCounterModeInState:YES];
    }
    else { //Totalizer Mode is selected
        [model setCounterModeInState:NO];
    }
    
}

- (IBAction)MTCAMimicAction:(id)sender {
    double value = [sender floatValue];
    [model setMTCAMimic1_ThresholdInBitsInState:[model MTCAMimic_VoltsToBits:value]];
}

- (IBAction)GTDelaysMaskAction:(id)sender {

    float LO_Delay = [LO_Field floatValue];
    float DGT_Delay = [DGT_Field floatValue];
    if([[sender className] isEqualToString:@"NSSlider"]){
        LO_Delay = [LO_Slider floatValue];
        DGT_Delay = [DGT_Slider floatValue];
    }
    [model setGTDelaysBitsInState:[model DGT_NanoSecondsToBits:DGT_Delay] LOBits:[model LODelay_NanoSecondsToBits:LO_Delay]];

}

- (IBAction)ClockSourceAction:(id)sender {
    BOOL tubii_is_default = ([[sender selectedCell] tag] == 1);
    [model setTUBiiIsDefaultClockInState:tubii_is_default];
}


#pragma mark •••Helper Functions
- (NSUInteger) GetBitInfoFromCheckBoxes: (NSMatrix*)aMatrix FromBit:(int)low ToBit: (int)high {
    //Helper function to gather a bit value from a bunch of checkboxes
    NSUInteger maskVal = 0;
    for (int i=low; i<high; i++) {
        if([[aMatrix cellWithTag:i] intValue]>0)
        {
            maskVal |= (1<<(i-low));
        }
    }
    return maskVal;
}
- (void) SendBitInfo:(NSUInteger) maskVal FromBit:(int)low ToBit:(int) high ToCheckBoxes: (NSMatrix*) aMatrix {
    //Helper function to send a bit value to a bunch of check boxes
    for (int i=low;i<high;i++)
    {
        if( (maskVal & 1<<(i-low))>0 )
        {
            [[aMatrix cellWithTag:i] setState:1];
        }
        else
        {
            [[aMatrix cellWithTag:i] setState:0];
        }
    }
}

- (void) disableMask:(NSUInteger)maskVal ForCheckBoxes:(NSMatrix*) aMatrix FromBit:(int)low ToBit:(int) high {
    //Helper function to enable/disable check boxes
    for (int i=low;i<high;i++)
    {
        if( (maskVal & 1<<(i-low))>0 )
        {
            [[aMatrix cellWithTag:i] setEnabled:1];
        }
        else
        {
            [[aMatrix cellWithTag:i] setEnabled:0];
        }
    }
}

-(void)log_error:(NSException *)e
{
    // Log an exception
    NSLogColor([NSColor redColor], @"[TUBii]: RedisClient exception from TUBii server: %@\n", [e reason]);
}
@end
