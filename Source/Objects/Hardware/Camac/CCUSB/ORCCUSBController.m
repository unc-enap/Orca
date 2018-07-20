/*
 *  ORCCUSBController.m
 *  Orca
 *
 *  Created by Mark Howe on Tues May 30 2006.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */

#pragma mark ¥¥¥Imported Files
#import "ORCCUSBController.h"
#import "ORCCUSBModel.h"
#import "ORUSBInterface.h"

@implementation ORCCUSBController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"CCUSB"];
    return self;
}

#pragma mark ¥¥¥Initialization
- (void) awakeFromNib
{
	[self populateInterfacePopup:[model getUSBController]];
	[super awakeFromNib];
}

- (void) updateWindow
{
    [super updateWindow ];
	[self delayAndGateAChanged:nil];
	[self delayAndGateBChanged:nil];
	[self delayAndGateExtChanged:nil];
	[self scalerReadoutChanged:nil];
	[self serialNumberChanged:nil];
	[self internalRegSelectionChanged:nil];
	[self registerValueChanged:nil];
	[self globalModeChanged:nil];
	[self delaysChanged:nil];
	[self userLEDSelectorChanged:nil];
	[self userNIMSelectorChanged:nil];
	[self userDeviceSelectorChanged:nil];
	[self scalerAChanged:nil];
	[self scalerBChanged:nil];
	[self LAMMaskChanged:nil];
	[self usbTransferSetupChanged:nil];
	[self nValueChanged:nil];
	[self aValueChanged:nil];
	[self fValueChanged:nil];
	[self nafModBitsChanged:nil];
	[self dataModifierBitsChanged:nil];
	[self dataWordChanged:nil];
	[self useDataModifierChanged:nil];
	[self customStackChanged:nil];
}

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter ];    
    [super registerNotificationObservers ];
    
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
                         name : ORCCUSBSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORCCUSBInterfaceChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(internalRegSelectionChanged:)
                         name : ORCCUSBModelInternalRegSelectionChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerValueChanged:)
                         name : ORCCUSBModelRegisterValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(globalModeChanged:)
                         name : ORCCUSBModelGlobalModeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(delaysChanged:)
                         name : ORCCUSBModelDelaysChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(userLEDSelectorChanged:)
                         name : ORCCUSBModelUserLEDSelectorChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(userNIMSelectorChanged:)
                         name : ORCCUSBModelUserNIMSelectorChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(userDeviceSelectorChanged:)
                         name : ORCCUSBModelUserDeviceSelectorChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(scalerReadoutChanged:)
                         name : ORCCUSBModelScalerReadoutChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(delayAndGateAChanged:)
                         name : ORCCUSBModelDelayAndGateAChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(delayAndGateBChanged:)
                         name : ORCCUSBModelDelayAndGateBChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(delayAndGateExtChanged:)
                         name : ORCCUSBModelDelayAndGateExtChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(scalerAChanged:)
                         name : ORCCUSBModelScalerAChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(scalerBChanged:)
                         name : ORCCUSBModelScalerBChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(LAMMaskChanged:)
                         name : ORCCUSBModelLAMMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(usbTransferSetupChanged:)
                         name : ORCCUSBModelUsbTransferSetupChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(nValueChanged:)
                         name : ORCCUSBModelNValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(aValueChanged:)
                         name : ORCCUSBModelAValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(fValueChanged:)
                         name : ORCCUSBModelFValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(nafModBitsChanged:)
                         name : ORCCUSBModelNafModBitsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataModifierBitsChanged:)
                         name : ORCCUSBModelDataModifierBitsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataWordChanged:)
                         name : ORCCUSBModelDataWordChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(useDataModifierChanged:)
                         name : ORCCUSBModelUseDataModifierChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(customStackChanged:)
                         name : ORCCUSBModelCustomStackChanged
						object: model];
	
}

#pragma mark ¥¥¥Interface Management

- (void) customStackChanged:(NSNotification*)aNote
{
	[customStackTable reloadData];
}

- (void) useDataModifierChanged:(NSNotification*)aNote
{
	[useDataModifierButton setIntValue: [model useDataModifier]];
	[self setButtonStates];
}

- (void) dataWordChanged:(NSNotification*)aNote
{
	[dataWordTextField setStringValue: [NSString stringWithFormat:@"0x%04X",[model dataWord]]];
}

- (void) dataModifierBitsChanged:(NSNotification*)aNote
{
	short mask = [model dataModifierBits];
	short i;
	for(i=0;i<10;i++){
		[[dataModifierBitsMatrix cellWithTag:i] setState:mask&(1<<i)];
	}
	
	[numberOfProductTermsTextField setIntValue: (mask >> 12) & 0x3];
	
}

- (void) nafModBitsChanged:(NSNotification*)aNote
{
	short mask = [model nafModBits];
	short i=0;
	//for(i=0;i<1;i++){
		[[nafModBitsMatrix cellWithTag:i] setState:mask&(1<<i)];
	//}
	[self setButtonStates];
}

- (void) fValueChanged:(NSNotification*)aNote
{
	[fValueTextField setIntValue: [model fValue]];
}

- (void) aValueChanged:(NSNotification*)aNote
{
	[aValueTextField setIntValue: [model aValue]];
}

- (void) nValueChanged:(NSNotification*)aNote
{
	[nValueTextField setIntValue: [model nValue]];
}
- (void) usbTransferSetupChanged:(NSNotification*)aNote
{
	unsigned short regValue = [model usbTransferSetup];
	[timeOutTextField setIntValue:    (regValue >> kTimeOutBit) & 0xf];
	[numBuffersTextField setIntValue: (regValue >> kNumberBuffersBit) & 0xff];
}

- (void) scalerBChanged:(NSNotification*)aNote
{
	[scalerBTextField setIntegerValue: [model scalerB]];
}

- (void) scalerAChanged:(NSNotification*)aNote
{
	[scalerATextField setIntegerValue: [model scalerA]];
}

- (void) LAMMaskChanged:(NSNotification*)aNote
{
	[lamMaskValueField setIntegerValue: [model LAMMaskValue]];
}

- (void) delayAndGateExtChanged:(NSNotification*)aNote
{
	uint32_t regValue = [model delayAndGateExt];
	[dggADelayCoarseTextField setIntValue: regValue & 0x0000ffff];
	[dggBDelayCoarseTextField setIntValue: (regValue>>16) & 0x0000ffff];
}

- (void) delayAndGateAChanged:(NSNotification*)aNote
{
	uint32_t regValue = [model delayAndGateA];
	[dggADelayFineTextField setIntValue: regValue & 0x0000ffff];
	[dggAGateTextField setIntValue: (regValue>>16) & 0x0000ffff];
	
}

- (void) delayAndGateBChanged:(NSNotification*)aNote
{
	uint32_t regValue = [model delayAndGateB];
	[dggBDelayFineTextField setIntValue: regValue & 0x0000ffff];
	[dggBGateTextField setIntValue: (regValue>>16) & 0x0000ffff];
}



- (void) userNIMSelectorChanged:(NSNotification*)aNote
{
	uint32_t regValue = [model userNIMSelector];
	[[userNIMLatchInvertMatrix cellWithTag:0] setState:regValue & (0x1<<kNIM01LatchBit)];
	[[userNIMLatchInvertMatrix cellWithTag:1] setState:regValue & (0x1<<kNIM02LatchBit)];
	[[userNIMLatchInvertMatrix cellWithTag:2] setState:regValue & (0x1<<kNIM03LatchBit)];
	[[userNIMLatchInvertMatrix cellWithTag:3] setState:regValue & (0x1<<kNIM01InvertBit)];
	[[userNIMLatchInvertMatrix cellWithTag:4] setState:regValue & (0x1<<kNIM02InvertBit)];
	[[userNIMLatchInvertMatrix cellWithTag:5] setState:regValue & (0x1<<kNIM03InvertBit)];	
	
	[nim01SourcePopup selectItemAtIndex:(regValue >> kNIM01CodeBit) & 0x7];
	[nim02SourcePopup selectItemAtIndex:(regValue >> kNIM02CodeBit) & 0x7];
	[nim03SourcePopup selectItemAtIndex:(regValue >> kNIM03CodeBit) & 0x7];
}


- (void) userLEDSelectorChanged:(NSNotification*)aNote
{
	uint32_t regValue = [model userLEDSelector];
	[[userLEDLatchInvertMatrix cellWithTag:0] setState:regValue & (0x1<<kRedLEDLatchBit)];
	[[userLEDLatchInvertMatrix cellWithTag:1] setState:regValue & (0x1<<kGreenLEDLatchBit)];
	[[userLEDLatchInvertMatrix cellWithTag:2] setState:regValue & (0x1<<kYellowLEDLatchBit)];
	[[userLEDLatchInvertMatrix cellWithTag:3] setState:regValue & (0x1<<kRedLEDInvertBit)];
	[[userLEDLatchInvertMatrix cellWithTag:4] setState:regValue & (0x1<<kGreenLEDInvertBit)];
	[[userLEDLatchInvertMatrix cellWithTag:5] setState:regValue & (0x1<<kYellowLEDInvertBit)];	
	
	[redLedSourcePopup    selectItemAtIndex:(regValue >> kRedLEDCodeBit)    & 0x7];
	[greenLedSourcePopup  selectItemAtIndex:(regValue >> kGreenLEDCodeBit)  & 0x7];
	[yellowLedSourcePopup selectItemAtIndex:(regValue >> kYellowLEDCodeBit) & 0x7];
	
}

- (void) userDeviceSelectorChanged:(NSNotification*)aNote
{
	uint32_t regValue = [model userDeviceSelector];
	[[scalerEnableMatrix cellWithTag:0] setState:regValue & (0x1<<kSclr_AEnableBit)];	
	[[scalerEnableMatrix cellWithTag:1] setState:regValue & (0x1<<kSclr_BEnableBit)];	
	[[scalerResetMatrix cellWithTag:0] setState:regValue & (0x1<<kSclr_AResetBit)];	
	[[scalerResetMatrix cellWithTag:1] setState:regValue & (0x1<<kSclr_BResetBit)];	
	
	[scalerAModePopup selectItemAtIndex:(regValue >> kSclr_AModeBit) & 0x7];
	[scalerBModePopup selectItemAtIndex:(regValue >> kSclr_BModeBit) & 0x7];
	[dggAModePopup selectItemAtIndex:(regValue >> kDGG_AModeBit) & 0x7];
	[dggBModePopup selectItemAtIndex:(regValue >> kDGG_BModeBit) & 0x7];
	
}

- (void) scalerReadoutChanged:(NSNotification*)aNote
{
	uint32_t regValue = [model scalerReadout];
	[timeIntervalField setIntValue: (regValue>>kScalerTimeIntervalBit) & 0x0000ffff];
	[numSepEventsField setIntValue: (regValue>>kScaleNumSepEventsBit) & 0x0000ffff];
	
}

- (void) delaysChanged:(NSNotification*)aNote
{
	unsigned short regValue = [model delays];
	[lamTimeOutField   setIntValue: (regValue>>kLAMTimeoutBit) & 0x00ff];
	[triggerDelayField setIntValue: (regValue>>kTriggerDelayBit) & 0x00ff];
}

- (void) globalModeChanged:(NSNotification*)aNote
{
	uint32_t regValue = [model globalMode];
	[bufferSizePopup  selectItemAtIndex:(regValue >> kBuffSizeOptBit) & 0xf];	
}

- (void) registerValueChanged:(NSNotification*)aNote
{
	[registerValueTextField setIntValue: [model registerValue]];
	[registerValueStepper setIntValue: [model registerValue]];
	
}

- (void) internalRegSelectionChanged:(NSNotification*)aNote
{
	[internalRegSelectionPopup selectItemAtIndex: [model internalRegSelection]];
	
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



#pragma mark ¥¥¥Actions

- (IBAction) useDataModifierButtonAction:(id)sender
{
	[model setUseDataModifier:[sender intValue]];	
}

- (IBAction) dataWordTextFieldAction:(id)sender
{
	const char* s = [[sender stringValue] UTF8String];
	[model setDataWord:strtoul(s,0,16)];
}


- (IBAction) dataModifierBitsMatrixAction:(id)sender
{
	short mask = [model dataModifierBits];
	if([sender tag] == 0){
		short bit  = [[dataModifierBitsMatrix selectedCell] tag];
		mask &= ~(1<<bit);
		if([[dataModifierBitsMatrix selectedCell] state])mask |= (1<<bit);
	}
	else {
		short theValue = [sender intValue];
		if(theValue>3)theValue = 3;
		mask &= ~(0x3<<12);
		mask |= ((theValue&0x3)<<12);
	}
	[model setDataModifierBits:mask];
}

- (IBAction) nafModBitsMatrixAction:(id)sender
{
	short bit  = [[nafModBitsMatrix selectedCell] tag];
	short mask = [model nafModBits];
	mask &= ~(1<<bit);
	if([[nafModBitsMatrix selectedCell] state])mask |= (1<<bit);
	[model setNafModBits:mask];
}

- (IBAction) fValueTextFieldAction:(id)sender
{
	[model setFValue:[sender intValue]];	
}

- (IBAction) aValueTextFieldAction:(id)sender
{
	[model setAValue:[sender intValue]];	
}

- (IBAction) nValueTextFieldAction:(id)sender
{
	[model setNValue:[sender intValue]];	
}

- (IBAction) dggExtAction:(id)sender
{
	uint32_t regValue = [model delayAndGateExt];
	if([sender tag] == 0){
		regValue &= ~0x0000ffff;
		regValue |= ([sender intValue] & 0x0000ffff);
	}
	else if([sender tag] == 1){
		regValue &= ~(0x0000ffff << 16);
		regValue |= ((int32_t)[sender intValue] & 0x0000ffffL) << 16;
	}
	[model setDelayAndGateExt:regValue];
}

- (IBAction) dggAAction:(id)sender
{
	uint32_t regValue = [model delayAndGateA];
	if([sender tag] == 0){ //gate length
		regValue &= ~(0x0000ffff << 16);
		regValue |= ((int32_t)[sender intValue] & 0x0000ffffL) << 16;
	}
	else if([sender tag] == 1){ //fine
		regValue &= ~0x0000ffff;
		regValue |= ([sender intValue] & 0x0000ffff);
	}
	[model setDelayAndGateA:regValue];
}


- (IBAction) dggBAction:(id)sender
{
	uint32_t regValue = [model delayAndGateB];
	if([sender tag] == 0){ //gate length
		regValue &= ~(0x0000ffff << 16);
		regValue |= ((int32_t)[sender intValue] & 0x0000ffffL) << 16;
	}
	else if([sender tag] == 1){ //fine
		regValue &= ~0x0000ffff;
		regValue |= ([sender intValue] & 0x0000ffff);
	}
	[model setDelayAndGateB:regValue];
}

- (IBAction) userLEDInvertLatchAction:(id)sender
{
	uint32_t regValue = [model userLEDSelector];
	BOOL state = [[sender selectedCell] state];
	switch([[sender selectedCell] tag]){
		case 0: regValue &= ~(0x1L<<kRedLEDLatchBit);     if(state)regValue |= (0x1L<<kRedLEDLatchBit);     break;
		case 1: regValue &= ~(0x1L<<kGreenLEDLatchBit);   if(state)regValue |= (0x1L<<kGreenLEDLatchBit);   break;
		case 2: regValue &= ~(0x1L<<kYellowLEDLatchBit);  if(state)regValue |= (0x1L<<kYellowLEDLatchBit);  break;
		case 3: regValue &= ~(0x1L<<kRedLEDInvertBit);    if(state)regValue |= (0x1L<<kRedLEDInvertBit);    break;
		case 4: regValue &= ~(0x1L<<kGreenLEDInvertBit);  if(state)regValue |= (0x1L<<kGreenLEDInvertBit);  break;
		case 5: regValue &= ~(0x1L<<kYellowLEDInvertBit); if(state)regValue |= (0x1L<<kYellowLEDInvertBit); break;
	}
	[model setUserLEDSelector:regValue];
}

- (IBAction) userLEDCodeAction:(id)sender
{
	uint32_t regValue = [model userLEDSelector];
	char code = [sender indexOfSelectedItem];
	switch([sender tag]){
		case 0: regValue &= ~(0x7L<<kRedLEDCodeBit);     regValue |= (code<<kRedLEDCodeBit);     break;
		case 1: regValue &= ~(0x7L<<kGreenLEDCodeBit);   regValue |= (code<<kGreenLEDCodeBit);   break;
		case 2: regValue &= ~(0x7L<<kYellowLEDCodeBit);  regValue |= (code<<kYellowLEDCodeBit);  break;
	}
	[model setUserLEDSelector:regValue];
}

- (IBAction) userNIMInvertLatchAction:(id)sender
{
	uint32_t regValue = [model userNIMSelector];
	BOOL state = [[sender selectedCell] state];
	switch([[sender selectedCell] tag]){
		case 0: regValue &= ~(0x1L<<kNIM01LatchBit);	if(state)regValue |= (0x1L<<kNIM01LatchBit);	break;
		case 1: regValue &= ~(0x1L<<kNIM02LatchBit);	if(state)regValue |= (0x1L<<kNIM02LatchBit);	break;
		case 2: regValue &= ~(0x1L<<kNIM03LatchBit);	if(state)regValue |= (0x1L<<kNIM03LatchBit);	break;
		case 3: regValue &= ~(0x1L<<kNIM01InvertBit);   if(state)regValue |= (0x1L<<kNIM01InvertBit);   break;
		case 4: regValue &= ~(0x1L<<kNIM02InvertBit);	if(state)regValue |= (0x1L<<kNIM02InvertBit);	break;
		case 5: regValue &= ~(0x1L<<kNIM03InvertBit);	if(state)regValue |= (0x1L<<kNIM03InvertBit);	break;
	}
	[model setUserNIMSelector:regValue];
}


- (IBAction) userNIMCodeAction:(id)sender
{
	uint32_t regValue = [model userNIMSelector];
	char code = ([sender indexOfSelectedItem] & 0x7);
	switch([sender tag]){
		case 0: regValue &= ~(0x7L<<kNIM01CodeBit);  regValue |= (code<<kNIM01CodeBit);  break;
		case 1: regValue &= ~(0x7L<<kNIM02CodeBit);  regValue |= (code<<kNIM02CodeBit);  break;
		case 2: regValue &= ~(0x7L<<kNIM03CodeBit);  regValue |= (code<<kNIM03CodeBit);  break;
	}
	[model setUserNIMSelector:regValue];
}

- (IBAction) LAMMaskValueAction:(id)sender
{
	[model setLAMMaskValue:[sender intValue]];	
}

- (IBAction) usbTransferSetupAction:(id)sender
{
	unsigned short regValue = [model usbTransferSetup];
	switch([sender tag]){
		case 0: regValue &= ~(0xf<<kTimeOutBit);			regValue |= ([sender intValue] << kTimeOutBit);		 break;
		case 1: regValue &= ~(0xff<<kNumberBuffersBit);		regValue |= ([sender intValue] << kNumberBuffersBit);  break;
	}
	
	[model setUsbTransferSetup:regValue];
}

- (IBAction) scalerAndDggAction:(id)sender
{
	uint32_t regValue = [model userDeviceSelector];
	char code = ([sender indexOfSelectedItem] & 0x7);
	switch([sender tag]){
		case 0: regValue &= ~(0x7L<<kSclr_AModeBit); regValue |= (code<<kSclr_AModeBit); break;
		case 1: regValue &= ~(0x7L<<kSclr_BModeBit); regValue |= (code<<kSclr_BModeBit); break;
		case 2: regValue &= ~(0x7L<<kDGG_AModeBit);  regValue |= (code<<kDGG_AModeBit);  break;
		case 3: regValue &= ~(0x7L<<kDGG_BModeBit);  regValue |= (code<<kDGG_BModeBit);  break;
	}
	[model setUserDeviceSelector:regValue];
}

- (IBAction) scalerEnableAction:(id)sender
{
	uint32_t regValue = [model userDeviceSelector];
	BOOL state = [[sender selectedCell] state];
	switch([[sender selectedCell] tag]){
		case 0: regValue &= ~(0x1L<<kSclr_AEnableBit);   if(state)regValue |= (0x1L<<kSclr_AEnableBit);   break;
		case 1: regValue &= ~(0x1L<<kSclr_BEnableBit);   if(state)regValue |= (0x1L<<kSclr_BEnableBit);   break;
	}
	[model setUserDeviceSelector:regValue];
}

- (IBAction) scalerResetAction:(id)sender
{
	uint32_t regValue = [model userDeviceSelector];
	BOOL state = [[sender selectedCell] state];
	switch([[sender selectedCell] tag]){
		case 0: regValue &= ~(0x1L<<kSclr_AResetBit);   if(state)regValue |= (0x1L<<kSclr_AResetBit);   break;
		case 1: regValue &= ~(0x1L<<kSclr_BResetBit);   if(state)regValue |= (0x1L<<kSclr_BResetBit);   break;
	}
	[model setUserDeviceSelector:regValue];
}

- (IBAction) timeIntervalActionAction:(id)sender
{
	int theValue = [sender intValue];
	if(theValue>255)theValue = 255;
	uint32_t regValue = [model scalerReadout];
	regValue &= ~(0x0000ffff<<kScalerTimeIntervalBit);
	regValue |= ((theValue & 0x0000ffff) << kScalerTimeIntervalBit);
	[model setScalerReadout:regValue];	
}

- (IBAction) numSepEventsAction:(id)sender
{
	uint32_t regValue = [model scalerReadout];
	regValue &= ~(0xff << kScaleNumSepEventsBit);
	regValue |= (([sender intValue] & 0x0000ffff) << kScaleNumSepEventsBit);
	[model setScalerReadout:regValue];	
}


- (IBAction) lamTimeOutAction:(id)sender
{
	unsigned short regValue = [model delays];
	regValue &= ~(0xff<<kLAMTimeoutBit);
	regValue |= (([sender intValue] & 0xff) << kLAMTimeoutBit);
	[model setDelays:regValue];	
}

- (IBAction) triggerDelayAction:(id)sender
{
	unsigned short regValue = [model delays];
	regValue &= ~(0xff << kTriggerDelayBit);
	regValue |= (([sender intValue] & 0xff) << kTriggerDelayBit);
	[model setDelays:regValue];	
}

- (void) bufferSizeAction:(id)sender
{
	uint32_t regValue = [model globalMode];
	regValue &= ~(0xf << kBuffSizeOptBit);
	regValue |= [bufferSizePopup indexOfSelectedItem];
	[model setGlobalMode:regValue];	
}

- (IBAction) writeRegAction:(id)sender
{
	@try {
		[self endEditing];
		[model writeReg:[model internalRegSelection]  value:[model registerValue]];
	}
	@catch(NSException* localException) {
	}
}

- (IBAction) readRegAction:(id)sender
{
	@try {
		NSLog(@"0x%x\n",[model readReg:[model internalRegSelection]]);
	}
	@catch(NSException* localException) {
	}
	
}

- (void) registerValueTextFieldAction:(id)sender
{
	[model setRegisterValue:[sender intValue]];	
}

- (void) internalRegSelectionAction:(id)sender
{
	[model setInternalRegSelection:(int)[sender indexOfSelectedItem]];
	[self setButtonStates];
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

- (IBAction) writeInternalRegistersAction:(id)sender
{
	@try {
		[self endEditing];
		[model writeInternalRegisters];
	}
	@catch(NSException* localException) {
	}
	
}

- (IBAction) getStatusAction:(id)sender
{
	[model getStatus];
}

- (void) setButtonStates
{
	[super setButtonStates];
	
	BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[model settingsLock]];
    BOOL locked						= [gSecurity isLocked:[model settingsLock]];
	BOOL notLockedAndNotRunning		= !locked && !runInProgress;
	
	[writeRegButton setEnabled: !lockedOrRunningMaintenance && [model registerWritable:[model internalRegSelection]]];
	[readRegButton setEnabled: !lockedOrRunningMaintenance];
	[registerValueStepper setEnabled: !lockedOrRunningMaintenance];
	[internalRegSelectionPopup setEnabled: !lockedOrRunningMaintenance];
	[registerValueTextField setEnabled: !lockedOrRunningMaintenance];
	[serialNumberPopup setEnabled: !locked];
	
	[bufferSizePopup setEnabled: notLockedAndNotRunning];
	
	[userLEDLatchInvertMatrix setEnabled: notLockedAndNotRunning];
	[redLedSourcePopup setEnabled: notLockedAndNotRunning];
	[greenLedSourcePopup setEnabled: notLockedAndNotRunning];
	[yellowLedSourcePopup setEnabled: notLockedAndNotRunning];
	
	[userNIMLatchInvertMatrix setEnabled: notLockedAndNotRunning];
	[nim01SourcePopup setEnabled: notLockedAndNotRunning];
	[nim02SourcePopup setEnabled: notLockedAndNotRunning];
	[nim03SourcePopup setEnabled: notLockedAndNotRunning];
	
	[lamTimeOutField setEnabled: notLockedAndNotRunning];
	[triggerDelayField setEnabled: notLockedAndNotRunning];
	
	[timeIntervalField setEnabled: notLockedAndNotRunning];
	[numSepEventsField setEnabled: notLockedAndNotRunning];
	
	[scalerEnableMatrix setEnabled: notLockedAndNotRunning];
	[scalerResetMatrix setEnabled: notLockedAndNotRunning];
	[scalerAModePopup setEnabled: notLockedAndNotRunning];
	[scalerBModePopup setEnabled: notLockedAndNotRunning];
	[dggAModePopup setEnabled: notLockedAndNotRunning];
	[dggBModePopup setEnabled: notLockedAndNotRunning];
	
	[dggAGateTextField setEnabled: notLockedAndNotRunning];
	[dggADelayFineTextField setEnabled: notLockedAndNotRunning];
	[dggADelayCoarseTextField setEnabled: notLockedAndNotRunning];
	
	[dggBGateTextField setEnabled: notLockedAndNotRunning];
	[dggBDelayFineTextField setEnabled: notLockedAndNotRunning];
	[dggBDelayCoarseTextField setEnabled: notLockedAndNotRunning];
	[lamMaskValueField setEnabled: notLockedAndNotRunning];
	[timeOutTextField setEnabled: notLockedAndNotRunning];
	[numBuffersTextField setEnabled: notLockedAndNotRunning];
	[writeInternalRegistersButton setEnabled: notLockedAndNotRunning];
	
	short continuationBitSet = [model nafModBits] & 0x1;
	short useDataModifier = [model useDataModifier];
	[dataWordTextField setEnabled:notLockedAndNotRunning];
	[useDataModifierButton setEnabled:continuationBitSet & notLockedAndNotRunning];
	[dataModifierBitsMatrix setEnabled:continuationBitSet & notLockedAndNotRunning & useDataModifier];
	[numberOfProductTermsTextField setEnabled:continuationBitSet & notLockedAndNotRunning & useDataModifier];
}

- (IBAction) test:(id)sender
{
    unsigned short statusCC32 = 0;
    @try {
        [model test];
    }
	@catch(NSException* localException) {
        NSLog(@"CC32 Test FAILED\n");
        if([[localException name] isEqualToString: OExceptionNoCamacCratePower]) [[model crate] doNoPowerAlert:localException action:@"CC32 Test"];
        else {
            ORRunAlertPanel([localException name], @"%@\nStatus=%d\n%@", @"OK", nil, nil,
                            [localException name],statusCC32,@"Failed Test of CC32");
        }
	}
}

- (IBAction) addNAFToStack:(id)sender
{
	[self endEditing];
	[model addNAFToStack];
}
- (IBAction) addDataWordToStack:(id)sender
{
	[self endEditing];
	[model addDataWordToStack];
}

- (IBAction) executeListAction:(id)sender
{
	[model executeCustomStack];
}


- (IBAction) clearStack:(id)sender
{
	[model clearStack];
}

- (IBAction) readStackAction:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
    if([model lastStackFilePath]) startingDir = [[model lastStackFilePath] stringByDeletingLastPathComponent];
    else						  startingDir = NSHomeDirectory();
	
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setLastStackFilePath:[[openPanel URL]path]];
            NSString* theContents = [NSString stringWithContentsOfFile:[model lastStackFilePath] encoding:NSASCIIStringEncoding error:nil];
            [model setCustomStack:[[[theContents componentsSeparatedByString:@"\n"] mutableCopy] autorelease]];
        }
    }];

}

- (IBAction) saveStackAction:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    
    NSString* startingDir;
    NSString* defaultFile;
    
    if([model lastStackFilePath]){
        startingDir = [[model lastStackFilePath] stringByDeletingLastPathComponent];
        defaultFile = [[model lastStackFilePath] lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = @"CCUSBStack";
        
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setLastStackFilePath:[[savePanel URL]path]];
            NSString* theContents = [[model customStack] componentsJoinedByString:@"\n"];
            [theContents writeToFile:[[savePanel URL]path] atomically:YES encoding:NSASCIIStringEncoding error:nil];
        }
    }];

}



- (void) populateInterfacePopup:(ORUSB*)usb
{
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
	if([model serialNumber])[serialNumberPopup selectItemWithTitle:[model serialNumber]];
	else [serialNumberPopup selectItemAtIndex:0];
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

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
	if([[[tabView selectedTabViewItem]label] isEqualToString:@"Standard Ops"])return [super validateMenuItem:menuItem];
	else return YES;
}

#pragma mark ¥¥¥Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    return [[model customStack] objectAtIndex:rowIndex];
}

// just returns the number of items we have.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[model customStack]  count];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    [[model customStack]  replaceObjectAtIndex:rowIndex withObject:anObject];
}


@end

