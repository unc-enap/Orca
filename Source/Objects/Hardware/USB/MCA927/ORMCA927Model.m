//
//  ORMCA927Model.m
//  Orca
//
//  USB Relay I/O Interface
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


#pragma mark •••Imported Files
#import "ORMCA927Model.h"
#import "ORUSBInterface.h"
#import "ORDataTypeAssigner.h"
#import "ORDataSet.h"

NSString* ORMCA927ModelCommentChanged	    = @"ORMCA927ModelCommentChanged";
NSString* ORMCA927ModelRunOptionsChanged	= @"ORMCA927ModelRunOptionsChanged";
NSString* ORMCA927ModelSelectedChannelChanged = @"ORMCA927ModelSelectedChannelChanged";
NSString* ORMCA927ModelLiveTimeStatusChanged= @"ORMCA927ModelLiveTimeStatusChanged";
NSString* ORMCA927ModelRealTimeStatusChanged= @"ORMCA927ModelRealTimeStatusChanged";
NSString* ORMCA927ModelLiveTimeChanged		= @"ORMCA927ModelLiveTimeChanged";
NSString* ORMCA927ModelRealTimeChanged		= @"ORMCA927ModelRealTimeChanged";
NSString* ORMCA927ModelLtPresetChanged		= @"ORMCA927ModelLtPresetChanged";
NSString* ORMCA927ModelUseCustomFileChanged = @"ORMCA927ModelUseCustomFileChanged";
NSString* ORMCA927ModelFpgaFilePathChanged  = @"ORMCA927ModelFpgaFilePathChanged";
NSString* ORMCA927ModelSerialNumberChanged	= @"ORMCA927ModelSerialNumberChanged";
NSString* ORMCA927ModelUSBInterfaceChanged	= @"ORMCA927ModelUSBInterfaceChanged";
NSString* ORMCA927ModelControlRegChanged	= @"ORMCA927ModelControlRegChanged";
NSString* ORMCA927ModelPresetCtrlRegChanged	= @"ORMCA927ModelPresetCtrlRegChanged";
NSString* ORMCA927ModelRTPresetChanged		= @"ORMCA927ModelRTPresetChanged";
NSString* ORMCA927ModelRoiPresetChanged		= @"ORMCA927ModelRoiPresetChanged";
NSString* ORMCA927ModelRoiPeakPresetChanged	= @"ORMCA927ModelRoiPeakPresetChanged";
NSString* ORMCA927ModelConvGainChanged		= @"ORMCA927ModelConvGainChanged";
NSString* ORMCA927ModelLowerDiscriminatorChanged	= @"ORMCA927ModelLowerDiscriminatorChanged";
NSString* ORMCA927ModelUpperDiscriminatorChanged	= @"ORMCA927ModelUpperDiscriminatorChanged";
NSString* ORMCA927ModelStatusParamsChanged	= @"ORMCA927ModelStatusParamsChanged";
NSString* ORMCA927ModelRunningStatusChanged	= @"ORMCA927ModelRunningStatusChanged";
NSString* ORMCA927ModelAutoClearChanged		= @"ORMCA927ModelAutoClearChanged";
NSString* ORMCA927ModelZdtModeChanged		= @"ORMCA927ModelZdtModeChanged";

NSString* ORMCA927USBInConnection			= @"ORMCA927USBInConnection";
NSString* ORMCA927USBNextConnection			= @"ORMCA927USBNextConnection";
NSString* ORMCA927ModelLock					= @"ORMCA927ModelLock";

static MCA927Registers reg[kNumberMCA927Registers] = {
	{@"CtlReg",			0x00}, 
	{@"AuxReg",			0x01}, 
	{@"ConvGain",		0x03}, 
	{@"ZDTMode",		0x04}, 
	{@"PresetCtl",		0x05},
	{@"LtPreset",		0x06}, 
	{@"RtPreset",		0x07}, 
	{@"RoiPeakPreset",	0x08}, 
	{@"RoiPreset",		0x09}, 
	{@"AcqStatus",		0x0A}, 
	{@"LiveTime",		0x0B}, 
	{@"RealTime",		0x0C}, 
	{@"Aux0Counter",	0x0D}, 
	{@"Aux1Counter",	0x0E}, 
	{@"kCtlRegMirror",	0x0F}, 
	{@"Version",		0x11}, 
	{@"StopAcq",		0x1F}
};

#define kReadSpectrum0Cmd		0x00000000
#define kReadSpectrum1Cmd		0x00008000
#define kReadZDT0Cmd			0x00004000
#define kReadZDT1Cmd			0x0000C000
#define kWriteSpectrum0Cmd		((1L<<24) | 0x00000000)
#define kWriteSpectrum1Cmd		((1L<<24) | 0x00008000)
#define kReadZDTSpectrum0Cmd	0x00004000
#define kReadZDTSpectrum1Cmd	0x0000c000
#define kWriteMemoryCmd			0x01000000
#define kReadRegCmd				0x00040000
#define kWriteRegCmd			0x01040000

@interface ORMCA927Model (private)
- (void) checkForResponseError:(unsigned char*)buffer;
- (void) sendLowSpeedCommand:(int)cmd;
- (NSData*) fpgaFileData;
- (void) pollStatus;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(unsigned long*)anArray forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray forKey:(NSString*)aKey;
- (void) ship:(ORDataPacket*)aDataPacket spectra:(int)index;
@end

@implementation ORMCA927Model

- (void) makeConnectors
{
	ORConnector* connectorObj1 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( 0, [self frame].size.height/2- kConnectorSize/2 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj1 forKey: ORMCA927USBInConnection ];
	[ connectorObj1 setConnectorType: 'USBI' ];
	[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to gpib outputs
	[connectorObj1 setOffColor:[NSColor yellowColor]];
	[ connectorObj1 release ];
	
	ORConnector* connectorObj2 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, [self frame].size.height/2- kConnectorSize/2)
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj2 forKey: ORMCA927USBNextConnection ];
	[ connectorObj2 setConnectorType: 'USBO' ];
	[ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to gpib inputs
	[connectorObj2 setOffColor:[NSColor yellowColor]];
	[ connectorObj2 release ];
}

- (void) makeMainController
{
    [self linkToController:@"ORMCA927Controller"];
}

- (NSString*) helpURL
{
	return @"USB/MCA927.html";
}

- (void) dealloc
{
    [comment release];
    [lastFile release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
 	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[fpgaFilePath release];
	
	[usbInterface release];
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [serialNumber release];
	[localLock release];
	[dataSet release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		[self connectionChanged];
	}
	@catch(NSException* localException) {
	}
	
}

- (void) connectionChanged
{
	NSArray* interfaces = [[self getUSBController] interfacesForVender:[self vendorID] product:[self productID]];
	NSString* sn = serialNumber;
	if([interfaces count] == 1 && ![sn length]){
		sn = [[interfaces objectAtIndex:0] serialNumber];
	}
	[self setSerialNumber:sn]; //to force usbinterface at doc startup
	[self checkUSBAlarm];
	[[self objectConnectedTo:ORMCA927USBNextConnection] connectionChanged];
}

-(void) setUpImage
{
	
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
	NSImage* aCachedImage = [NSImage imageNamed:@"MCA927"];
    if(!usbInterface || ![self getUSBController]){
		NSSize theIconSize = [aCachedImage size];
		
		NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
		[i lockFocus];
		
        [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];		
		NSBezierPath* path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(5,0)];
		[path lineToPoint:NSMakePoint(20,20)];
		[path moveToPoint:NSMakePoint(5,20)];
		[path lineToPoint:NSMakePoint(20,0)];
		[path setLineWidth:3];
		[[NSColor redColor] set];
		[path stroke];
		
		[i unlockFocus];
		
		[self setImage:i];
		[i release];
    }
	else {
		[ self setImage: aCachedImage];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
	
}

- (NSString*) title 
{
	return [NSString stringWithFormat:@"MCA927 (Serial# %@)",[usbInterface serialNumber]];
}

- (NSUInteger) vendorID
{
	return 0x0A2D; //MCA927
}

- (NSUInteger) productID
{
	return 0x0019;	//MCA927
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORMCA927USBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

#pragma mark ***Accessors

- (NSString*) comment
{
	if(!comment)return @"";
    else return comment;
}

- (void) setComment:(NSString*)aComment
{
	if(!aComment)aComment = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setComment:comment];
    
    [comment autorelease];
    comment = [aComment copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelCommentChanged object:self];
}

- (NSString*) lastFile
{
    return lastFile;
}

- (void) setLastFile:(NSString*)aLastFile
{
    [lastFile autorelease];
    lastFile = [aLastFile copy];    
}

- (BOOL) startedFromMainRunControl:(int)index
{
	if(index>=0 && index<2) return startedFromMainRunControl[index];
	else return 0;
}

- (BOOL) autoClear:(int)index
{
	if(index>=0 && index<2) return autoClear[index];
	else return 0;
}
- (void) setAutoClear:(int)index withValue:(BOOL)aValue
{
	if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setAutoClear:index withValue:autoClear[index]];
		autoClear[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelAutoClearChanged object:self];
	}
}

- (unsigned long) runOptions:(int)index
{
	if(index>=0 && index<2) return runOptions[index];
	else return 0;
}

- (void) setRunOptions:(int)index withValue:(unsigned long)optionMask
{
	if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setRunOptions:index withValue:runOptions[index]];
		runOptions[index] = optionMask;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelRunOptionsChanged object:self];
	}
}


- (int) selectedChannel
{
    return selectedChannel;
}

- (void) setSelectedChannel:(int)aSelectedChannel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedChannel:selectedChannel];
    selectedChannel = aSelectedChannel;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelSelectedChannelChanged object:self];
}

- (unsigned long) upperDiscriminator:(int)index
{
	if(index>=0 && index<2) return upperDiscriminator[index];
	else return 0;
}

- (void) setUpperDiscriminator:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		if(aValue>0x3fff)aValue = 0x3fff;
		[[[self undoManager] prepareWithInvocationTarget:self] setUpperDiscriminator:index withValue:upperDiscriminator[index]];
		upperDiscriminator[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelUpperDiscriminatorChanged object:self];
	}
}

- (unsigned long) lowerDiscriminator:(int)index
{
	if(index>=0 && index<2) return lowerDiscriminator[index];
	else return 0;
}

- (void) setLowerDiscriminator:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		if(aValue>0x3fff)aValue = 0x3fff;
		[[[self undoManager] prepareWithInvocationTarget:self] setLowerDiscriminator:index withValue:lowerDiscriminator[index]];
		lowerDiscriminator[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelLowerDiscriminatorChanged object:self];
	}
}
- (unsigned long) zdtMode:(int)index
{
	if(index>=0 && index<2) return zdtMode[index];
	else return 0;
}

- (void) setZdtMode:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		if(aValue>0x3fff)aValue = 0x3fff;
		[[[self undoManager] prepareWithInvocationTarget:self] setZdtMode:index withValue:zdtMode[index]];
		zdtMode[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelZdtModeChanged object:self];
	}
}

- (unsigned long) rtPreset:(int)index
{
	if(index>=0 && index<2) return rtPreset[index];
	else return 0;
}

- (void) setRtPreset:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setRtPreset:index withValue:rtPreset[index]];
		rtPreset[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelRTPresetChanged object:self];
	}
}

- (unsigned long) roiPreset:(int)index
{
	if(index>=0 && index<2) return roiPreset[index];
	else return 0;
}

- (void) setRoiPreset:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setRoiPreset:index withValue:roiPreset[index]];
		roiPreset[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelRoiPresetChanged object:self];
	}
}

- (unsigned long) roiPeakPreset:(int)index
{
	if(index>=0 && index<2) return roiPeakPreset[index];
	else return 0;
}

- (void) setRoiPeakPreset:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setRoiPeakPreset:index withValue:roiPeakPreset[index]];
		roiPeakPreset[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelRoiPeakPresetChanged object:self];
	}
}

- (unsigned long) realTime:(int)index
{
	if(index>=0 && index<2) return realTime[index];
	else return 0;
}

- (void) setRealTime:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setRealTime:index withValue:realTime[index]];
		realTime[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelRealTimeChanged object:self];
	}
}
- (unsigned long) realTimeStatus:(int)index
{
	if(index>=0 && index<2) return realTimeStatus[index];
	else return 0;
}

- (void) setRealTimeStatus:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		realTimeStatus[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelRealTimeStatusChanged object:self];
	}
}

- (unsigned long) convGain:(int)index
{
	if(index>=0 && index<2) return convGain[index];
	else return 0;
}

- (void) setConvGain:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setConvGain:index withValue:convGain[index]];
		convGain[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelConvGainChanged object:self];
	}
}
- (unsigned long) liveTime:(int)index
{
   if(index>=0 && index<2) return liveTime[index];
   else return 0;
}

- (void) setLiveTime:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setLiveTime:index withValue:liveTime[index]];
		liveTime[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelLiveTimeChanged object:self];
	}
}

- (unsigned long) liveTimeStatus:(int)index
{
	if(index>=0 && index<2) return liveTimeStatus[index];
	else return 0;
}

- (void) setLiveTimeStatus:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		liveTimeStatus[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelLiveTimeStatusChanged object:self];
	}
}

- (BOOL) runningStatus:(int)index
{
	if(index>=0 && index<2) return runningStatus[index];
	else return 0;
}

- (void) setRunningStatus:(int)index withValue:(BOOL)aValue;
{
	if(index>=0 && index<2 && runningStatus[index] != aValue){
		runningStatus[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelRunningStatusChanged object:self];
	}
}

- (unsigned long) ltPreset:(int)index
{
   if(index>=0 && index<2) return ltPreset[index];
   else return 0;
}

- (void) setLtPreset:(int)index withValue:(unsigned long)aLtPreset
{
	if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setLtPreset:index withValue:ltPreset[index]];
		ltPreset[index] = aLtPreset;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelLtPresetChanged object:self];
	}
}

- (unsigned long) controlReg:(int)index
{
	if(index>=0 && index<2)return controlReg[index];
	else return 0;
}

- (void) setControlReg:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setControlReg:index withValue:controlReg[index]];
		controlReg[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelControlRegChanged object:self];
	}
}

- (unsigned long) presetCtrlReg:(int)index
{
	if(index>=0 && index<2)return presetCtrlReg[index];
	else return 0;
}

- (void) setPresetCtrlReg:(int)index withValue:(unsigned long)aValue
{
	if(index>=0 && index<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setPresetCtrlReg:index withValue:presetCtrlReg[index]];
		presetCtrlReg[index] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelPresetCtrlRegChanged object:self];
	}
}

- (BOOL) useCustomFile
{
    return useCustomFile;
}

- (void) setUseCustomFile:(BOOL)aUseCustomFile
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseCustomFile:useCustomFile];
    useCustomFile = aUseCustomFile;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelUseCustomFileChanged object:self];
}


- (NSString*) fpgaFilePath
{
	if(!fpgaFilePath)return @"";
    return fpgaFilePath;
}

- (void) setFpgaFilePath:(NSString*)aFpgaFilePath
{
	if(!aFpgaFilePath)aFpgaFilePath =  @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setFpgaFilePath:fpgaFilePath];
    [fpgaFilePath autorelease];
    fpgaFilePath = [aFpgaFilePath copy];    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelFpgaFilePathChanged object:self];
}
- (NSString*) serialNumber
{
    return serialNumber;
}

- (void) setSerialNumber:(NSString*)aSerialNumber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerialNumber:serialNumber];
    
    [serialNumber autorelease];
    serialNumber = [aSerialNumber copy];    
	
	if(!serialNumber){
		[[self getUSBController] releaseInterfaceFor:self];
	}
	else {
		[[self getUSBController] claimInterfaceWithSerialNumber:serialNumber for:self];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelSerialNumberChanged object:self];
	[self checkUSBAlarm];
}

- (ORUSBInterface*) usbInterface
{
	return usbInterface;
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
	[self checkUSBAlarm];
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface
{	
	if(anInterface != usbInterface){
		[usbInterface release];
		usbInterface = anInterface;
		[usbInterface retain];
		[usbInterface setUsePipeType:kUSBInterrupt];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: ORMCA927ModelUSBInterfaceChanged object: self];

		[self checkUSBAlarm];
	}
}

- (void)checkUSBAlarm
{
	if((usbInterface && [self getUSBController]) || !guardian){
		[noUSBAlarm clearAlarm];
		[noUSBAlarm release];
		noUSBAlarm = nil;
	}
	else {
		if(guardian){
			if(!noUSBAlarm){
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for MCA927"] severity:kHardwareAlarm];
				[noUSBAlarm setSticky:YES];		
			}
			[noUSBAlarm setAcknowledged:NO];
			[noUSBAlarm postAlarm];
		}
	}
	
	[self setUpImage];
	
}

- (void) interfaceAdded:(NSNotification*)aNote
{
	[[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
	ORUSBInterface* theInterfaceRemoved = [[aNote userInfo] objectForKey:@"USBInterface"];
	if((usbInterface == theInterfaceRemoved) && serialNumber){
		[self setUsbInterface:nil];
	}
}

- (NSString*) usbInterfaceDescription
{
	if(usbInterface)return [usbInterface description];
	else return @"?";
}

- (void) registerWithUSB:(id)usb
{
	[usb registerForUSBNotifications:self];
}

- (NSString*) hwName
{
	if(usbInterface)return [usbInterface deviceName];
	else return @"?";
}

- (void) makeUSBClaim:(NSString*)aSerialNumber
{	
}

- (void) startFPGA
{
	@try {
		[self disableFirmwareLoop];
		[self initFPGA];
		[self loadFPGA];
		[self testFPGA];
		[self resetFPGA];
		[self enableFirmwareLoop];

		NSLog(@"MCA927 FPGA Loaded\n");
	}
	@catch (NSException* localException){
		NSLogColor([NSColor redColor],@"MCA927 FPGA failed to load\n");
		NSLogColor([NSColor redColor],@"%@\n",localException);
	}
}

- (void) startAcquisition:(int)index
{
	
	if(!([self readReg:kAcqStatus adc:index]&kStartMask)){
	
		[self initBoard:index];
		[self resetMDA];

		if(autoClear[index]) {
			[self clearSpectrum:index];
			[self clearZDT:index];
		}
		unsigned long mask;
		mask = controlReg[index];
		mask |= 0x1;
		[self writeReg:kCtlReg adc:index value:mask];
		[self pollStatus];
		NSLog(@"MCA927 %d Channel %d started\n",[self uniqueIdNumber], index);
	}
	else NSLog(@"MCA927 Channel %d already running... command to start ignored\n",index);
}	

- (void) stopAcquisition:(int)index
{
	if(([self readReg:kAcqStatus adc:index]&kStartMask)){
		NSLog(@"MCA927 %d Channel %d stopped\n",[self uniqueIdNumber], index);

		[self writeReg:kStopAcq adc:index value:0x1];
		[self writeReg:kStopAcq adc:index value:0x0];
		unsigned long mask;
		mask = controlReg[index];
		mask &= ~0x1;
		[self writeReg:kCtlReg adc:index value:mask];
		[self pollStatus];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollStatus) object:nil];
	}
	else NSLog(@"MCA927 Channel %d not running... command to stop ignored\n",index);
}	

- (const char*) convGainLabel:(int)aValue
{
	switch(aValue){
		case 0: return "16k";
		case 1: return "8k";
		case 2: return "4k";
		case 3: return "2k";
		case 4: return "1k";
		case 5: return "512";
		case 6: return "256";
		default: return "?";
	}
}
- (int) numChannels:(int)index
{
	switch(convGain[index]){
		case 0: return 16*1024;
		case 1: return 8*1024;
		case 2: return 4*1024;
		case 3: return 2*1024;
		case 4: return 1024;
		case 5: return 512;
		case 6: return 256;
		default: return 0;
	}
}

- (void) clearSpectrum:(int)index
{
	unsigned long aCommand[0x3fff+2];
	aCommand[0] =  (index==0?0x04000000:0x04008000);
	aCommand[1] = 0x3fff;	//number to write
	int i;
	for(i=0;i<0x3fff;i++){
		aCommand[2+i] = 0;	//value
	}
	[usbInterface writeBytes:aCommand  length:(0x3fff+2)*sizeof(long) pipe:1];
	long dummy;
	[usbInterface readBytes:&dummy length:4 pipe:1];
}

- (void) clearZDT:(int)index
{
	unsigned long aCommand[0x3fff+2];
	aCommand[0] =  (index==0?0x04004000:0x0400C000);
	aCommand[1] = 0x3fff;	//number to write
	int i;
	for(i=0;i<0x3fff;i++){
		aCommand[2+i] = 0;	//value
	}
	[usbInterface writeBytes:aCommand  length:(0x3fff+2)*sizeof(long) pipe:1];
	long dummy;
	[usbInterface readBytes:&dummy length:4 pipe:1];
}


- (void) readSpectrum:(int)index
{
	if(!dataSet)dataSet = [[ORDataSet alloc]initWithKey:@"System" guardian:nil];

	unsigned long aCommand[2];
	int n = [self numChannels:index];
	
	aCommand[0] =  index==0?kReadSpectrum0Cmd:kReadSpectrum1Cmd;
	aCommand[1] = n;	//number to read back
	[usbInterface writeBytes:aCommand  length:2*sizeof(long) pipe:1];
	[usbInterface readBytes:&spectrum[index] length:n*sizeof(long)+1 pipe:1];

	[dataSet loadSpectrum:[NSMutableData dataWithBytes:&spectrum[index] length:n*sizeof(long)] 
					sender:self  
				  withKeys:@"Spectra",[NSString stringWithFormat:@"Channel%d",index],nil];
	
}

- (void) readZDT:(int)index
{
	if(!dataSet)dataSet = [[ORDataSet alloc]initWithKey:@"System" guardian:nil];
	
	unsigned long aCommand[2];
	int n = [self numChannels:index];
	
	aCommand[0] =  index==0?kReadZDT0Cmd:kReadZDT1Cmd;
	aCommand[1] = n;	//number to read back
	[usbInterface writeBytes:aCommand  length:2*sizeof(long) pipe:1];
	[usbInterface readBytes:&spectrum[index+2] length:n*sizeof(long)+1 pipe:1];
	
	[dataSet loadSpectrum:[NSMutableData dataWithBytes:&spectrum[index+2] length:n*sizeof(long)] 
				   sender:self  
				 withKeys:@"ZDT",[NSString stringWithFormat:@"Channel%d",index],nil];
	
}


- (BOOL) viewSpectrum0
{
	ORDataSet* aDataSet = [dataSet dataSetWithName:@"Spectra,0"];
	if(aDataSet){
		[aDataSet doDoubleClick:self];
		return YES;
	}
	else return NO;
}

- (BOOL) viewSpectrum1
{
	ORDataSet* aDataSet = [dataSet dataSetWithName:@"Spectra,1"];
	if(aDataSet){
		[aDataSet doDoubleClick:self];
		return YES;
	}
	else return NO;
}

- (BOOL) viewZDT0
{
	ORDataSet* aDataSet = [dataSet dataSetWithName:@"ZDT,0"];
	if(aDataSet){
		[aDataSet doDoubleClick:self];
		return YES;
	}
	else return NO;
}

- (BOOL) viewZDT1
{
	ORDataSet* aDataSet = [dataSet dataSetWithName:@"ZDT,1"];
	if(aDataSet){
		[aDataSet doDoubleClick:self];
		return YES;
	}
	else return NO;
}

- (void) writeSpectrum:(int)index toFile:(NSString*)aFilePath
{
/*
 $SPEC_ID:
 Comment from user
 $SPEC_REM:
 DET# 1
 DETDESC# MCB 25
 AP# Maestro Version 6.03
 $DATE_MEA:
 05/29/2008 16:10:40
 $MEAS_TIM:
 2642 2643
 $DATA:
 0 8191
 ...data....
 $ROI
 123
 $PRESETS:
 Live Time
 180
 0
 */
	int n = [self numChannels:index];
	aFilePath = [aFilePath stringByExpandingTildeInPath];
	[self setLastFile:aFilePath];
	
	float realTimeValue = [self realTimeStatus:index]*0.02;
	float liveTimeValue = [self liveTimeStatus:index]*0.02;

	NSMutableString* s = [NSMutableString string];
	[s appendFormat:@"$SPEC_ID:\n%@\n",comment];
	[s appendFormat:@"$SPEC_REM:\nDET# 1\nDETDESC# MCB 25\nAP# ORCA (%@)\n",fullVersion()];
	[s appendFormat:@"$DATE_MEA:\n%@\n",[NSDate date]];
	[s appendFormat:@"$MEAS_TIM:\n%.02f %.02f\n",liveTimeValue,realTimeValue];
	[s appendFormat:@"$DATA:\n%d %d\n",index,n-1];
	int i;
	for(i=0;i<n;i++){
		[s appendFormat:@"%lu\n",spectrum[index][i]];
	}
	[s appendFormat:@"$ROI:\n%lu\n%lu\n",roiPeakPreset[index], roiPreset[index]];
	[s appendFormat:@"$PRESETS:\nLive Time\n%lu\n%lu\n",liveTime[index],realTime[index]];
	[s writeToFile:aFilePath atomically:NO encoding:NSASCIIStringEncoding error:nil];
}

- (unsigned long) spectrum:(int)index valueAtChannel:(int)x
{
	return spectrum[index][x];
}

- (void) report
{
	[self report:YES];
}
- (void) sync
{
	[self report:NO];
}

- (void) report:(BOOL)verbose
{	
	NSFont* aFont = [NSFont fontWithName:@"Monaco" size:12];
	unsigned long aValue0 = [self readReg:kCtlReg adc:0];
	unsigned long aValue1 = [self readReg:kCtlReg adc:1];
	unsigned long presetCtrl0 = [self readReg:kPresetCtl adc:0];
	unsigned long presetCtrl1 = [self readReg:kPresetCtl adc:1];
	if(verbose){
		NSLog(@"MCA 927 values\n");	
		NSLogFont(aFont,@"------------------------------------------------------\n");
		NSLogFont(aFont,@"    Variable    |     Channel 0  \t |    Channel 1    \n");
		NSLogFont(aFont,@"------------------------------------------------------\n");
		NSLogFont(aFont,@"Coincidence mode|%17s |%17s\n",(aValue0&kGateCoinMask)?     "Coincident":"Aniticoincident",(aValue1&kGateCoinMask)?"Coincident":"Anitcoincident");
		NSLogFont(aFont,@"    Gate Enabled|%17s |%17s\n",(aValue0&kGateEnableMask)?   "YES":"NO",(aValue1&kGateEnableMask)?"YES":"NO");
		NSLogFont(aFont,@"UL Discriminator|%17s |%17s\n",(aValue0&kDisableULMask)?    "Disabled":"Enabled",(aValue1&kDisableULMask)?"Disabled":"Enabled");
		NSLogFont(aFont,@"         Trigger|%17s |%17s\n",(aValue0&kEnableTriggerMask)?"Enabled":"Disabled",(aValue1&kEnableTriggerMask)?"Enabled":"Disabled");
		NSLogFont(aFont,@"        ConvGain|%17s |%17s\n",[self convGainLabel:[self readReg:kConvGain adc:0]],[self convGainLabel:[self readReg:kConvGain adc:1]]);
		NSLogFont(aFont,@" LiveTime Preset|%13.2f (%1s) |%13.2f (%1s)\n",[self readReg:kLtPreset adc:0]*0.02,      (presetCtrl0&kEnableLiveTimeMask)?"X":" ",[self readReg:kLtPreset adc:1]*0.02,     (presetCtrl1&kEnableLiveTimeMask)?"X":" ");
		NSLogFont(aFont,@" RealTime Preset|%13.2f (%1s) |%13.2f (%1s)\n",[self readReg:kRtPreset adc:0]*0.02,      (presetCtrl0&kEnableRealTimeMask)?"X":" ",[self readReg:kRtPreset adc:1]*0.02,     (presetCtrl1&kEnableRealTimeMask)?"X":" ");
		NSLogFont(aFont,@" ROI Peak Preset|%13d (%1s) |%13d (%1s)\n",[self readReg:kRoiPeakPreset adc:0], (presetCtrl0&kEnableRoiPeakMask)?"X":" ", [self readReg:kRoiPeakPreset adc:1],(presetCtrl1&kEnableRoiPeakMask)?"X":" ");
		NSLogFont(aFont,@"      ROI Preset|%13d (%1s) |%13d (%1s)\n",[self readReg:kRoiPreset adc:0],     (presetCtrl0&kEnableRoiMask)?"X":" ",     [self readReg:kRoiPreset adc:1],    (presetCtrl1&kEnableRoiMask)?"X":" ");
		NSLogFont(aFont,@" OverFlow Preset|              (%1s) |              (%1s)\n",(presetCtrl0&kEnableOverFlowMask)?"X":" ",(presetCtrl1&kEnableOverFlowMask)?"X":" ");
		NSLogFont(aFont,@"       Live Time|%17.2f |%17.2f\n",[self readReg:kLiveTime adc:0]*0.02,[self readReg:kLiveTime adc:1]*0.02);
		NSLogFont(aFont,@"       Real Time|%17.2f |%17.2f\n",[self readReg:kRealTime adc:0]*0.02,[self readReg:kRealTime adc:1]*0.02);
		NSLogFont(aFont,@"------------------------------------------------------\n");
	}
	aValue0 = [self readReg:kAcqStatus adc:0];
	aValue1 = [self readReg:kAcqStatus adc:1];
	
	if(verbose){
		NSLogFont(aFont,@"      Acquistion|%17s |%17s\n",(aValue0&kStartMask)?        "Running":"Stopped",(aValue1&kStartMask)?"Running":"Stopped");
		NSLogFont(aFont,@"      Acq Status|%17s |%17s\n",aValue0&0x1?"Active":"--",aValue1&0x1?"Active":"--");
		NSLogFont(aFont,@"     Acq Trigger|%17s |%17s\n",aValue0&0x2?"Armed":"--",aValue1&0x2?"Armed":"--");
		NSLogFont(aFont,@"   Aux Counter 0|%17d |%17d\n",[self readReg:kAux0Counter adc:0],[self readReg:kAux0Counter adc:1]);
		NSLogFont(aFont,@"   Aux Counter 1|%17d |%17d\n",[self readReg:kAux1Counter adc:0],[self readReg:kAux1Counter adc:1]);
		NSLogFont(aFont,@"------------------------------------------------------\n");
		NSLog(@"Firmware Version: %d\n",[self readReg:kVersion adc:1]);
	}
	[self setRunningStatus:0 withValue:(aValue0&kStartMask)];
	[self setRunningStatus:1 withValue:(aValue1&kStartMask)];
	if((aValue0&kStartMask) || (aValue1&kStartMask)){
		[self pollStatus];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:ORMCA927ModelStatusParamsChanged object:self];

}

- (void) initBoard:(int)i
{
	[self loadDiscriminators:i];
	[self writeReg:kZDTMode adc:i value:zdtMode[i]];
	[self writeReg:kPresetCtl adc:i value:presetCtrlReg[i]];
	[self writeReg:kConvGain adc:i value:convGain[i]];
	[self writeReg:kLtPreset adc:i value:ltPreset[i]];
	[self writeReg:kRtPreset adc:i value:rtPreset[i]];
	[self writeReg:kRoiPeakPreset adc:i value:roiPeakPreset[i]];
	[self writeReg:kRoiPreset adc:i value:roiPreset[i]];
	[self writeReg:kRealTime adc:i value:realTime[i]];
	[self writeReg:kLiveTime adc:i value:liveTime[i]];
	[self writeReg:kCtlReg adc:i value:controlReg[i]];
}


- (void) initFPGA
{
	[self sendLowSpeedCommand:0x4];
}

- (void) loadDiscriminators:(int) index
{
	unsigned char aResponse[64];
	if(usbInterface && [self getUSBController]){
		unsigned char aCommand[12];
		aCommand[0] = 0x7; aCommand[1] = 0x0; aCommand[2] = 12;
		aCommand[3] = 0x0; aCommand[4] = 0x0; aCommand[5] = 0x0;
		aCommand[6] = 0x0; aCommand[8] = 0x0; aCommand[9] = 0x0;
	
		//lower
		aCommand[7] = (index == 0) ? 0x1 : 0x3; 
		aCommand[10] = (lowerDiscriminator[index] & 0xff00) >> 8;
		aCommand[11] = lowerDiscriminator[index] & 0xff;
		[usbInterface writeBytes:aCommand  length:12];
		if([usbInterface readBytes:aResponse length:64]){
			[self checkForResponseError:aResponse];
		}
		
		//upper
		aCommand[7] = (index == 0) ? 0x0 : 0x2; 
		aCommand[10] = (upperDiscriminator[index]&0xff00) >> 8;
		aCommand[11] = upperDiscriminator[index] & 0xff;
		[usbInterface writeBytes:aCommand  length:12];
		if([usbInterface readBytes:aResponse length:64]){
			[self checkForResponseError:aResponse];
		}
		
		
	}
}

- (void) loadFPGA
{
#define kChunkSize 50
	if(usbInterface && [self getUSBController]){
		unsigned char aCommand[4] = {0x5,0x0,0x2,0x0};
		unsigned char packet[kChunkSize+4]; 
		NSData* fpgaFileData = [self fpgaFileData];
		long len = [fpgaFileData length];
		if(len){
			unsigned char* p = (unsigned char*)[fpgaFileData bytes];
			do {
				int nbytes = MIN(len,kChunkSize);
				memcpy(packet,aCommand,4);			//copy in the command
				memcpy(&packet[4],p,nbytes);	//append the fpga data
				///need to change to load blocks of the fpga file
				[usbInterface writeBytes:packet  length:nbytes+4];
				unsigned char aResponse[64];
				if([usbInterface readBytes:aResponse length:64]){
					[self checkForResponseError:aResponse];
				}
				
				p += nbytes;	//move the pointer ahead
				len -= nbytes;	//how much is left?
			} while(len>0);
		}
	}
}

- (void) testFPGA			 
{ 
	if(usbInterface && [self getUSBController]){
		unsigned char aCommand[4] = {0x6,0x0,0x4,0x0};
		unsigned char aResponse[64];
		[usbInterface writeBytes:aCommand  length:4];
		if([usbInterface readBytes:aResponse length:64]){
			[self checkForResponseError:aResponse]; //throws
			NSLog(@"test FPGA: %d, %d\n",aResponse[0],aResponse[1]);
		}
	}
}
- (void) disableFirmwareLoop { [self sendLowSpeedCommand:0x8];  }
- (void) enableFirmwareLoop	 { [self sendLowSpeedCommand:0x9];  }
- (void) testPresets		 { [self sendLowSpeedCommand:0xA];  }
- (void) resetMDA			 { [self sendLowSpeedCommand:0x10]; }
- (void) resetFPGA			 { [self sendLowSpeedCommand:0x11]; }

- (void) getFirmwareVersion
{
	if(usbInterface && [self getUSBController]){
		unsigned char aCommand[4] = {0x12,0x0,0x6,0x0};
		[usbInterface writeBytes:aCommand  length:4];
		union {
			unsigned char array[4];
			int asInt;
		}version;
		unsigned char aResponse[64];
		if([usbInterface readBytes:aResponse length:64]){
			[self checkForResponseError:aResponse]; //throws on error
			int i;
			for(i=0;i<4;i++)version.array[3-i] = aResponse[2+i];
			NSLog(@"Firmware version: %d\n",version.asInt);
		}
	}
}

//high speed USB interface
- (void) writeReg:(int)aReg adc:(int)adcIndex value:(unsigned long)aValue
{
	unsigned long aCommand[3];
	aCommand[0] =  kWriteRegCmd | (reg[aReg].addressOffset + (adcIndex==0?0:0x20));
	aCommand[1] = 0x1;						//number of data words
	aCommand[2] = aValue;
	[usbInterface writeBytes:aCommand  length:3*sizeof(long) pipe:1];
	//all commands have response. read it.
	unsigned char aResponse[512];
	[usbInterface readBytes:aResponse length:512 pipe:1];
}

- (unsigned long) readReg:(int)aReg adc:(int)adcIndex
{
	unsigned long aCommand[3];
	aCommand[0] =  kReadRegCmd | (reg[aReg].addressOffset + (adcIndex==0?0:0x20));
	aCommand[1] = 0x1;	//number to read back
	[usbInterface writeBytes:aCommand  length:2*sizeof(long) pipe:1];
	unsigned long aResponse;
	[usbInterface readBytes:&aResponse length:4 pipe:1];
	return aResponse;
}

- (NSString*) identifier
{
	return [NSString stringWithFormat:@"MCA927 %lu",[self uniqueIdNumber]];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setComment:		  [decoder decodeObjectForKey:@"comment"]];
    [self setLastFile:		  [decoder decodeObjectForKey:@"lastFile"]];
	[self setSelectedChannel: [decoder decodeIntForKey:   @"selectedChannel"]];
	[self setUseCustomFile:	  [decoder decodeBoolForKey:  @"useCustomFile"]];
    [self setFpgaFilePath:	  [decoder decodeObjectForKey:@"fpgaFilePath"]];
    [self setSerialNumber:	  [decoder decodeObjectForKey:@"serialNumber"]];
	int i;
	for(i=0;i<2;i++){
		[self setControlReg:i withValue:	[decoder decodeInt32ForKey:    [@"controlReg" stringByAppendingFormat:@"%d",i]]];
		[self setPresetCtrlReg:i withValue:	[decoder decodeInt32ForKey:	   [@"presetCtrlReg" stringByAppendingFormat:@"%d",i]]];
		[self setLiveTime:i withValue:		[decoder decodeInt32ForKey:	   [@"liveTime" stringByAppendingFormat:@"%d",i]]];
		[self setRealTime:i withValue:		[decoder decodeInt32ForKey:	   [@"realTime" stringByAppendingFormat:@"%d",i]]];
		[self setLtPreset:i withValue:		[decoder decodeInt32ForKey:	   [@"ltPreset" stringByAppendingFormat:@"%d",i]]];
		[self setRtPreset:i withValue:		[decoder decodeInt32ForKey:	   [@"rtPreset" stringByAppendingFormat:@"%d",i]]];
		[self setRoiPeakPreset:i withValue:	[decoder decodeInt32ForKey:	   [@"roiPeakPreset" stringByAppendingFormat:@"%d",i]]];
		[self setRoiPreset:i withValue:		[decoder decodeInt32ForKey:	   [@"roiPreset" stringByAppendingFormat:@"%d",i]]];
		[self setConvGain:i withValue:		[decoder decodeInt32ForKey:	   [@"convGain" stringByAppendingFormat:@"%d",i]]];
		[self setLowerDiscriminator:i withValue:[decoder decodeInt32ForKey:[@"lowerDiscriminator" stringByAppendingFormat:@"%d",i]]];
		[self setUpperDiscriminator:i withValue:[decoder decodeInt32ForKey:[@"upperDiscriminator" stringByAppendingFormat:@"%d",i]]];
		[self setRunOptions:i withValue:	[decoder decodeInt32ForKey:    [@"runOptions" stringByAppendingFormat:@"%d",i]]];
		[self setAutoClear:i withValue:		[decoder decodeBoolForKey:     [@"autoClear" stringByAppendingFormat:@"%d",i]]];
		[self setZdtMode:i withValue:		[decoder decodeInt32ForKey:	   [@"zdtMode" stringByAppendingFormat:@"%d",i]]];
	}
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject:comment		forKey:@"comment"];
	[encoder encodeObject:lastFile		forKey:@"lastFile"];
	[encoder encodeInt:selectedChannel	forKey:@"selectedChannel"];
    [encoder encodeBool:useCustomFile	forKey:@"useCustomFile"];
    [encoder encodeObject:fpgaFilePath	forKey:@"fpgaFilePath"];
    [encoder encodeObject:serialNumber	forKey:@"serialNumber"];
	int i;
	for(i=0;i<2;i++){
		[encoder encodeInt32:controlReg[i] forKey:[@"controlReg" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt32:liveTime[i] forKey:[@"liveTime" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt32:realTime[i] forKey:[@"realTime" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt32:presetCtrlReg[i] forKey:[@"presetCtrlReg" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt32:ltPreset[i] forKey:[@"ltPreset" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt32:rtPreset[i] forKey:[@"rtPreset" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt32:roiPeakPreset[i] forKey:[@"roiPeakPreset" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt32:roiPreset[i] forKey:[@"roiPreset" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt32:convGain[i] forKey:[@"convGain" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt32:lowerDiscriminator[i] forKey:[@"lowerDiscriminator" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt32:upperDiscriminator[i] forKey:[@"upperDiscriminator" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt32:runOptions[i] forKey:[@"runOptions" stringByAppendingFormat:@"%d",i]];
		[encoder encodeBool:autoClear[i] forKey:[@"autoClear" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt32:zdtMode[i] forKey:[@"zdtMode" stringByAppendingFormat:@"%d",i]];
	}
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{	
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[self addCurrentState:objDictionary cArray:runOptions forKey:@"RunOptions"];
	[self addCurrentState:objDictionary cArray:liveTime forKey:@"LiveTime"];
	[self addCurrentState:objDictionary cArray:realTime forKey:@"Debug Mode"];
	[self addCurrentState:objDictionary cArray:presetCtrlReg forKey:@"PresetCtrlReg"];
	[self addCurrentState:objDictionary cArray:ltPreset forKey:@"LtPreset"];
	[self addCurrentState:objDictionary cArray:rtPreset forKey:@"RtPreset"];
	[self addCurrentState:objDictionary cArray:roiPeakPreset forKey:@"RoiPeakPreset"];
	[self addCurrentState:objDictionary cArray:roiPreset forKey:@"RoiPreset"];
	[self addCurrentState:objDictionary cArray:convGain forKey:@"ConvGain"];
	[self addCurrentState:objDictionary cArray:lowerDiscriminator forKey:@"LowerDiscriminator"];
	[self addCurrentState:objDictionary cArray:upperDiscriminator forKey:@"UpperDiscriminator"];
	[self addCurrentState:objDictionary boolArray:autoClear forKey:@"AutoClear"];
	[self addCurrentState:objDictionary cArray:zdtMode forKey:@"ZdtMode"];
	
    return objDictionary;
}

#pragma mark •••Data Taker
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORMCA927SpectraDecoder",         @"decoder",
								 [NSNumber numberWithLong:dataId],  @"dataId",
								 [NSNumber numberWithBool:YES],     @"variable",
								 [NSNumber numberWithLong:-1],		@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Spectrum"];
    
    return dataDictionary;
}
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORMCA927Model"];    
	//----------------------------------------------------------------------------------------
	@try {
		mainRunIsStopping = NO;
		if(runOptions[0] & kChannelEnabledMask) {
			startedFromMainRunControl[0] = YES;
			[self startAcquisition:0];
		}
		if(runOptions[1] & kChannelEnabledMask){
			startedFromMainRunControl[1] = YES;
			[self startAcquisition:1];
		}
	}
	@catch(NSException* localException){
	}
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
 //nothing to do....
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	@try {
		mainRunIsStopping = YES;
		startedFromMainRunControl[0] = NO;
		startedFromMainRunControl[1] = NO;
		if(runOptions[0] & kChannelEnabledMask)[self stopAcquisition:0];
		if(runOptions[1] & kChannelEnabledMask)[self stopAcquisition:1];
		if(runOptions[0] & kChannelEnabledMask){
			[self ship:aDataPacket spectra:0];
			if(zdtMode[0] & kEnableZDTMask)[self ship:aDataPacket spectra:2];
		}
		if(runOptions[1] & kChannelEnabledMask){
			[self ship:aDataPacket spectra:1];
			if(zdtMode[1] & kEnableZDTMask)[self ship:aDataPacket spectra:3];
		}

	}
	@catch(NSException* localException){
	}
}
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	//nothing to do....
}
- (void) reset
{
	//nothing to do....
}

@end


@implementation ORMCA927Model (private)

- (void) ship:(ORDataPacket*)aDataPacket spectra:(int)index
{
	int chan = index;
	int zdt = 0;
	if(chan>=2){
		chan = chan-2;
		zdt  = 1;
	}
	
	int numLongsInSpectrum = [self numChannels:index];
	int numLongsInHeader = 10;
	NSMutableData* dataBlock = [NSMutableData dataWithLength: (numLongsInSpectrum + numLongsInHeader)*sizeof(long)];
	unsigned long* data = (unsigned long*)[dataBlock bytes];
	data[0] = dataId | (numLongsInSpectrum + numLongsInHeader);
	data[1] = (zdt<<13) | (chan<<12) | ([self uniqueIdNumber]&0xfff);
	data[2] = [self liveTimeStatus:index];
	data[3] = [self realTimeStatus:index];
	data[4] = [self zdtMode:index];
	data[5] = 0; //spare
	data[6] = 0; //spare
	data[7] = 0; //spare
	data[8] = 0; //spare
	data[9] = 0; //spare
	memcpy(&data[10],spectrum[index],numLongsInSpectrum * sizeof(long));

	[aDataPacket addLongsToFrameBuffer:data length:numLongsInSpectrum + numLongsInHeader];
	
}

- (NSData*) fpgaFileData
{
	NSString* fpgaPath;
	if(useCustomFile) fpgaPath = fpgaFilePath;
	else			  fpgaPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"FPGA_Files/M927.rbf"];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:fpgaPath]){
        NSFileHandle* fh = [NSFileHandle fileHandleForReadingAtPath:fpgaPath];
		NSData* theData =  [fh readDataToEndOfFile];
        [fh closeFile];
        return theData;
	}
	else {
		NSLogColor([NSColor redColor],@"MCA927 FPGA file <FPGA_Files/M927.rbf> not found in app resources\n");
		return nil;
	}
}

- (void) sendLowSpeedCommand:(int)cmd
{
	if(usbInterface && [self getUSBController]){
		unsigned char aCommand[4] = {0x0,0x0,0x2,0x0};
		unsigned char aResponse[64];
		aCommand[0] = cmd;
		[usbInterface writeBytes:aCommand  length:4];
		if([usbInterface readBytes:aResponse length:64]){
			[self checkForResponseError:aResponse]; //throws
		}
	}
}

- (void) checkForResponseError:(unsigned char*)buffer
{
	unsigned char errMac = buffer[0];
	unsigned char errMic = buffer[1];
	@try {
		if(errMac == 0 && errMic == 0)			return; //success
		else if(errMic == 2)					[NSException raise:@"MCA 927 Exception" format:@"Preset exceeded"];
		else if(errMac == 4 && errMic == 128)	[NSException raise:@"MCA 927 Exception" format:@"FPGA Failed/Needs Configuration"];
		else if(errMac == 129 && errMic == 132) [NSException raise:@"MCA 927 Exception" format:@"Invalid Command"];
		else									[NSException raise:@"MCA 927 Exception" format:@"Unspecified Error, (%d,%d)",errMac,errMic];
	}
	@catch (NSException* localException){
		NSLog(@"%@\n",localException);
		@throw;
	}
}

- (void) pollStatus
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollStatus) object:nil];
	[self setRunningStatus:0 withValue:([self readReg:kAcqStatus adc:0]&kStartMask)];
	[self setRunningStatus:1 withValue:([self readReg:kAcqStatus adc:1]&kStartMask)];
	unsigned long isRunning = [self runningStatus:0] || [self runningStatus:1];
		
	int i;
	for(i=0;i<2;i++){
		//aValue = [self readReg:kAcqStatus adc:i];
		[self setLiveTimeStatus:i withValue:[self readReg:kLiveTime adc:i]];
		[self setRealTimeStatus:i withValue:[self readReg:kRealTime adc:i]];
	}
	
	if([self runningStatus:0])[self readSpectrum:0];
	if([self runningStatus:1])[self readSpectrum:1];
	if([self runningStatus:0] && ([self zdtMode:0] & kEnableZDTMask))[self readZDT:0];
	if([self runningStatus:1] && ([self zdtMode:1] & kEnableZDTMask))[self readZDT:1];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: ORMCA927ModelStatusParamsChanged object: self];

	if(isRunning)[self performSelector:@selector(pollStatus) withObject:nil afterDelay:1];
	if([gOrcaGlobals runInProgress]){
		int i;
		for(i=0;i<2;i++){
			if(![self runningStatus:i] && startedFromMainRunControl[i]){
				startedFromMainRunControl[i] = NO;
				if(!mainRunIsStopping){
					if(runOptions[i] & kChannelAutoStopMask){
						[[NSNotificationCenter defaultCenter] postNotificationName: ORRequestRunStop object: self];
					}
				}
			}
		}
	}
	
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(unsigned long*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<2;i++){
		[ar addObject:[NSNumber numberWithUnsignedLong:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}
- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<2;i++){
		[ar addObject:[NSNumber numberWithBool:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

@end
