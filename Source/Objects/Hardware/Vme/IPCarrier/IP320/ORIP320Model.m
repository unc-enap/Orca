//
//  ORIP320Model.cp
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
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
#import "ORIP320Model.h"
#import "ORIPCarrierModel.h"
#import "ORVmeCrateModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORTimer.h"
#import "ORDataSet.h"
#import "ORIP320Channel.h"
#include <math.h>

#define KDelayTime .00005 //50 microsecond delay to allow for the 8.5 microsecond settling time of the input

#pragma mark ¥¥¥Notification Strings
NSString* ORIP320ModelCalibrationDateChanged		= @"ORIP320ModelCalibrationDateChanged";
NSString* ORIP320ModelCardJumperSettingChanged		= @"ORIP320ModelCardJumperSettingChanged";
NSString* ORIP320ModelShipRecordsChanged			= @"ORIP320ModelShipRecordsChanged";
NSString* ORIP320ModelLogFileChanged				= @"ORIP320ModelLogFileChanged";
NSString* ORIP320ModelLogToFileChanged				= @"ORIP320ModelLogToFileChanged";
NSString* ORIP320ModelDisplayRawChanged				= @"ORIP320ModelDisplayRawChanged";
NSString* ORIP320GainChangedNotification			= @"ORIP320GainChangedNotification";
NSString* ORIP320ModeChangedNotification			= @"ORIP320ModeChangedNotification";
NSString* ORIP320AdcValueChangedNotification 		= @"ORIP320AdcValueChangedNotification";
NSString* ORIP320ModelMultiPlotsChangedNotification = @"ORIP320ModelMultiPlotsChangedNotification";

NSString* ORIP320WriteValueChangedNotification		= @"IP320 WriteValue Changed Notification";
NSString* ORIP320ReadMaskChangedNotification 		= @"IP320 ReadMask Changed Notification";
NSString* ORIP320ReadValueChangedNotification		= @"IP320 ReadValue Changed Notification";
NSString* ORIP320PollingStateChangedNotification	= @"ORIP320PollingStateChangedNotification";
NSString* ORIP320ModelModeChanged					= @"ORIP320ModelModeChanged";


static struct {
    NSString* regName;
    uint32_t addressOffset;
}reg[kNum320Registers]={
{@"Control Reg",  0x0000},
{@"Convert Cmd",  0x0010},
{@"ADC Data Reg", 0x0020},		
};

@interface ORIP320Model (private)
- (void) _setUpPolling:(BOOL)verbose;
- (void) _stopPolling;
- (void) _startPolling;
- (void) _pollAllChannels;
- (void) _callibrateIP320;
@end

@implementation ORIP320Model

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setChanObjs:[NSMutableArray array]];
    int i=0;
    for(i=0;i<kNumIP320Channels;i++){
        [chanObjs addObject:[[[ORIP320Channel alloc] initWithAdc:self channel:i]autorelease]];
    }
    [[self undoManager] enableUndoRegistration];
    return self;
}

-(void)dealloc
{
    [calibrationDate release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [multiPlots makeObjectsPerformSelector:@selector(invalidateDataSource) withObject:nil];
    [multiPlots release];
    [logFile release];
    [dataSet release];
	[self _stopPolling];
    [chanObjs release];
    [super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
        [self _setUpPolling:NO];
		if(logToFile){
			[self performSelector:@selector(writeLogBufferToFile) withObject:nil afterDelay:60];		
		}
    }
    [super wakeUp];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"IP320"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORIP320Controller"];
}

- (NSString*) helpURL
{
	return @"VME/IP320.html";
}

#pragma mark ¥¥¥Accessors
- (NSDate*) calibrationDate
{
    return calibrationDate;
}

- (void) setCalibrationDate:(NSDate*)aCalibrationDate
{
    [aCalibrationDate retain];
    [calibrationDate release];
    calibrationDate = aCalibrationDate;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIP320ModelCalibrationDateChanged object:self];
}

- (ORDataSet*) dataSet
{
	return dataSet;
}

- (void) setDataSet:(ORDataSet*)aDataSet
{
    [aDataSet retain];
    [dataSet release];
    dataSet = aDataSet;
    
    [multiPlots makeObjectsPerformSelector:@selector(setDataSource:) withObject:dataSet];
    
}

- (NSMutableArray *) multiPlots
{
    return multiPlots; 
}

- (void) setMultiPlots: (NSMutableArray *) aMultiPlots
{
    [aMultiPlots retain];
    [multiPlots release];
    multiPlots = aMultiPlots;
}

- (void) addMultiPlot:(id)aMultiPlot
{
    if(!multiPlots){
        [self setMultiPlots:[NSMutableArray array]];
    }
    
    [[[self undoManager] prepareWithInvocationTarget:self] removeMultiPlot:aMultiPlot];
    
    [multiPlots addObject:aMultiPlot];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIP320ModelMultiPlotsChangedNotification
	 object: self ];
}

- (void) removeMultiPlot:(id)aMultiPlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] addMultiPlot:aMultiPlot];
    
    [aMultiPlot removeFrom:multiPlots];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIP320ModelMultiPlotsChangedNotification
	 object: self ];
}

- (int) cardJumperSetting
{
    return cardJumperSetting;
}

- (void) setCardJumperSetting:(int)aCardJumperSetting
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCardJumperSetting:cardJumperSetting];
    
    cardJumperSetting = aCardJumperSetting;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIP320ModelCardJumperSettingChanged object:self];
}

- (BOOL) shipRecords
{
    return shipRecords;
}

- (void) setShipRecords:(BOOL)aShipRecords
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipRecords:shipRecords];
    
    shipRecords = aShipRecords;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIP320ModelShipRecordsChanged object:self];
}

- (NSString*) logFile
{
    return logFile;
}

- (void) setLogFile:(NSString*)aLogFile
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLogFile:logFile];
	
    [logFile autorelease];
    logFile = [aLogFile copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIP320ModelLogFileChanged object:self];
}

- (BOOL) logToFile
{
    return logToFile;
}

- (void) setLogToFile:(BOOL)aLogToFile
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLogToFile:logToFile];
    
    logToFile = aLogToFile;
	
	if(logToFile)[self performSelector:@selector(writeLogBufferToFile) withObject:nil afterDelay:60];
	else [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(writeLogBufferToFile) object:nil];
	
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIP320ModelLogToFileChanged object:self];
}

- (void) setOpMode:(int)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOpMode:opMode];
    
    opMode = aMode;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIP320ModelModeChanged object:self];
	
}

- (int) opMode
{
	return opMode;
}

- (BOOL) displayRaw
{
    return displayRaw;
}

- (void) setDisplayRaw:(BOOL)aDisplayRaw
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDisplayRaw:displayRaw];
    
    displayRaw = aDisplayRaw;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORIP320ModelDisplayRawChanged object:self];
}

- (void) writeLogBufferToFile
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(writeLogBufferToFile) object:nil];
	if(logToFile && [logBuffer count] && [logFile length]){
		if(![[NSFileManager defaultManager] fileExistsAtPath:[logFile stringByExpandingTildeInPath]]){
			[[NSFileManager defaultManager] createFileAtPath:[logFile stringByExpandingTildeInPath] contents:nil attributes:nil];
		}
		
		NSFileHandle* fh = [NSFileHandle fileHandleForUpdatingAtPath:[logFile stringByExpandingTildeInPath]];
		[fh seekToEndOfFile];
		
		int i;
		int n = (int)[logBuffer count];
		for(i=0;i<n;i++){
			[fh writeData:[[logBuffer objectAtIndex:i] dataUsingEncoding:NSASCIIStringEncoding]];
		}
		[fh closeFile];
		[logBuffer removeAllObjects];
	}
	[self performSelector:@selector(writeLogBufferToFile) withObject:nil afterDelay:60];
}

- (void) reportCardCalibration
{
	switch(cardJumperSetting){
		case(kMinus5to5):NSLog(@"IP320 Card is set to -5 to 5 Volts\n");		break;
		case(kMinus10to10):NSLog(@"IP320 Card is set to -10 to 10 Volts\n");	break;
		case(k0to10):NSLog(@"IP320 Card is set to 0 to 10 Volts\n");			break;
		case(kUncalibrated):NSLog(@"IP320 Card is uncalibrated\n");				break;
	}
}

// ===========================================================
// - chanObjs:
// ===========================================================
- (NSMutableArray *)chanObjs
{
    return chanObjs; 
}

// ===========================================================
// - setChanObjs:
// ===========================================================
- (void)setChanObjs:(NSMutableArray *)aChanArray 
{
    [aChanArray retain];
    [chanObjs release];
    chanObjs = aChanArray;
}


- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) aDataId
{
    dataId = aDataId;
}
- (uint32_t) convertedDataId { return convertedDataId; }
- (void) setConvertedDataId: (uint32_t) aDataId
{
    convertedDataId = aDataId;
}
- (void) setPollingState:(NSTimeInterval)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollingState:pollingState];
    
    pollingState = aState;
    
    [self performSelector:@selector(_startPolling) withObject:nil afterDelay:0.5];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIP320PollingStateChangedNotification
	 object: self];
    
}

- (void) postNotification:(NSNotification*)aNote
{
	[[NSNotificationCenter defaultCenter] postNotification:aNote];
}

- (NSTimeInterval)	pollingState
{
    return pollingState;
}
- (BOOL) hasBeenPolled 
{ 
    return hasBeenPolled;
}

#pragma mark ¥¥¥Hardware Access
- (uint32_t) getRegisterAddress:(short) aRegister
{
    int ip = [self slotConv];
    return [guardian baseAddress] + ip*0x100 + reg[aRegister].addressOffset;
}

- (uint32_t) getAddressOffset:(short) anIndex
{
    return reg[anIndex].addressOffset;
}

- (NSString*) getRegisterName:(short) anIndex
{
    return reg[anIndex].regName;
}

- (short) getNumRegisters;
{
    return kNum320Registers;
}

- (void) loadConstants:(unsigned short)aChannel
{
    ORIP320Channel* chanObj = [chanObjs objectAtIndex:aChannel];
    unsigned short aMask = 0;
    aMask |= (aChannel%20 & kChan_mask);//bits 0-5
	aMask |= [chanObj gain] << 6;       //bits 6-7
	aMask |= [self opMode] << 8;			//bits 8-9
	
	[[guardian adapter] writeWordBlock:&aMask
							 atAddress:[self getRegisterAddress:kControlReg]
							numToWrite:1L
							withAddMod:[guardian addressModifier]
						 usingAddSpace:kAccessRemoteIO];
}

- (void) loadConversionStart
{
	unsigned short modifier = [guardian addressModifier];
	unsigned short dummyValue = 0xFFFF;
	id cachedController = [guardian adapter];
	[cachedController writeWordBlock:&dummyValue
						   atAddress:[self getRegisterAddress:kConvertCmd]
						  numToWrite:1L
						  withAddMod:modifier
					   usingAddSpace:kAccessRemoteIO];
	
	
}

-(unsigned short) readDataBlock
{
	unsigned short value = 0;
	unsigned short modifier = [guardian addressModifier];
	id cachedController = [guardian adapter];
	[cachedController readWordBlock:(unsigned short*)&value
						  atAddress:[self getRegisterAddress:kControlReg]
						  numToRead:1L
						 withAddMod:modifier
					  usingAddSpace:kAccessRemoteIO];
	
	
	
	if((value & 0x8000) == 0x8000){
		[cachedController readWordBlock:(unsigned short*)&value
							  atAddress:[self getRegisterAddress:kADCDataReg]
							  numToRead:1L
							 withAddMod:modifier
						  usingAddSpace:kAccessRemoteIO];
		
		//the value needs to be shifted by 4 bits after the read. That's how is comes off the card....
		value=((value>>4) & 0x0fff);
	}
	return value;
}

- (unsigned short) readAdcChannel:(unsigned short)aChannel time:(time_t)aTime
//Brandon's Version
{
	int changeCount = 0;
	unsigned short value = 0;
	unsigned short corrected_value = 0;
	@synchronized(self) {
		NSString* errorLocation = @"";
		@try {
			errorLocation = @"Control Reg Setup";
			[self loadConstants:aChannel];
			[ORTimer delay:KDelayTime];
			
			errorLocation = @"Conversion Start";
			[self loadConversionStart];
			errorLocation = @"Adc Read";
			value = [self readDataBlock];
			corrected_value = [self calculateCorrectedCount:[[chanObjs objectAtIndex:aChannel] gain] countActual:value];
			if([[chanObjs objectAtIndex:aChannel] setChannelValue:corrected_value time:aTime])changeCount++;
			
		}
		@catch(NSException* localException) {
			NSLogError(@"",[NSString stringWithFormat:@"IP320 %d,%@",[self slot],[self identifier]],errorLocation,nil);
			[NSException raise:[NSString stringWithFormat:@"IP320 Read Adc Channel %d Failed",aChannel] format:@"Error Location: %@",errorLocation];
		}
		if(changeCount){
			[self performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:ORIP320AdcValueChangedNotification object:self] waitUntilDone:NO];
		}
	}
	//	NSLog(@"the corected value is %d\n",[self calculateCorrectedCount:[[chanObjs objectAtIndex:aChannel] gain] countActual:value]);
	return corrected_value;
}

//Calibration routines
- (void) loadCALHIControReg:(unsigned short)gain
{
	unsigned short aMaskCALHI = 0x0000;
	if((cardJumperSetting==kMinus5to5 && gain==0)||(cardJumperSetting==kMinus10to10&&gain<=1)||(cardJumperSetting==k0to10&&gain<=1)){
		calibrationConstants[gain].kVoltCALHI=kCAL0_volt;
		aMaskCALHI|=kCAL0_mask;
		aMaskCALHI|=(gain<<6);	
	}
	else if((cardJumperSetting==kMinus5to5 && gain==1)||(cardJumperSetting==kMinus10to10&&gain==2)||(cardJumperSetting==k0to10&&gain==2)){
		calibrationConstants[gain].kVoltCALHI=kCAL1_volt;
		aMaskCALHI|=kCAL1_mask;
		aMaskCALHI|=(gain<<6);	
	}
	else if((cardJumperSetting==kMinus5to5 && gain==2)||(cardJumperSetting==kMinus10to10&&gain==3)||(cardJumperSetting==k0to10&&gain==3)){
		calibrationConstants[gain].kVoltCALHI=kCAL2_volt;
		aMaskCALHI|=kCAL2_mask;
		aMaskCALHI|=(gain<<6);	
	}
	else if(cardJumperSetting==kMinus5to5 && gain==3){
		calibrationConstants[gain].kVoltCALHI=kCAL3_volt;
		aMaskCALHI|=kCAL3_mask;
		aMaskCALHI|=(gain<<6);	
	}
	[[guardian adapter] writeWordBlock:&aMaskCALHI
							 atAddress:[self getRegisterAddress:kControlReg]
							numToWrite:1L
							withAddMod:[guardian addressModifier]
						 usingAddSpace:kAccessRemoteIO];
	
	
}

- (void) loadCALLOControReg:(unsigned short)gain
{
	unsigned short aMaskCALLO = 0;
	
	//Find CountCALLO
	if(cardJumperSetting==k0to10){
		calibrationConstants[gain].kVoltCALLO=kCAL3_volt;
		aMaskCALLO|=kCAL3_mask;
		aMaskCALLO|=(gain<<6);
	}
	else {
		calibrationConstants[gain].kVoltCALLO=kAUTOZERO_volt;
		aMaskCALLO|=kAUTOZERO_mask;
		aMaskCALLO|=(gain<<6);
		
	}
	[[guardian adapter] writeWordBlock:&aMaskCALLO
							 atAddress:[self getRegisterAddress:kControlReg]
							numToWrite:1L
							withAddMod:[guardian addressModifier]
						 usingAddSpace:kAccessRemoteIO];
}

-(void) calculateCalibrationSlope:(unsigned short)gain
{ 
	float slope;
	slope=pow(2,gain)*(calibrationConstants[gain].kVoltCALHI-calibrationConstants[gain].kVoltCALLO)/(calibrationConstants[gain].kCountCALHI-calibrationConstants[gain].kCountCALLO);
	calibrationConstants[gain].kSlope_m=slope;
}

-(unsigned short) calculateCorrectedCount:(unsigned short)gain countActual:(unsigned short)countActual
{
	unsigned short corrected_count;
	
	if(cardJumperSetting==kUncalibrated) { corrected_count=countActual; }
	else {
		corrected_count=countActual;
		corrected_count+=((calibrationConstants[gain].kVoltCALLO*pow(2,gain))-calibrationConstants[gain].kIdeal_Zero)/calibrationConstants[gain].kSlope_m;
		corrected_count= corrected_count-calibrationConstants[gain].kCountCALLO;
		corrected_count=corrected_count*(4096*calibrationConstants[gain].kSlope_m)/calibrationConstants[gain].kIdeal_Volt_Span;
	}
	return corrected_count;
	
}

- (void) calibrate
{
	[self setCalibrationDate:[NSDate date]];
	int countergain=0;
	switch(cardJumperSetting){
		case(kMinus5to5):
			for(countergain=0;countergain<kNumGainSettings;countergain++){
				calibrationConstants[countergain].kIdeal_Volt_Span=10.000;
				calibrationConstants[countergain].kIdeal_Zero=-5.0000;
			}
			[self _callibrateIP320];
			NSLog(@"Calibrated IP320 for -5 to 5 Voltage Range\n");
			break;
			
		case(kMinus10to10):
			for(countergain=0;countergain<kNumGainSettings;countergain++){
				calibrationConstants[countergain].kIdeal_Volt_Span=20.000;
				calibrationConstants[countergain].kIdeal_Zero=-10.0000;
			}
			[self _callibrateIP320];
			NSLog(@"Calibrated IP320 for -10 to 10 Voltage Range\n");
			break;
			
		case(k0to10):
			for(countergain=0;countergain<kNumGainSettings;countergain++){
				calibrationConstants[countergain].kIdeal_Volt_Span=10.000;
				calibrationConstants[countergain].kIdeal_Zero=0.0000;
			}
			[self _callibrateIP320];
			NSLog(@"Calibrated IP320 for 0 to 10 Voltage Range\n");
			break;
			
		case(kUncalibrated):
			//NSLog(@"IP320 returns uncorrected value.\n");
			break;
	}
}

- (void) _callibrateIP320
{
	int gain =0;
	unsigned short ReadNumber = 10;
	@synchronized(self) {
		NSString* errorLocation = @"";
		@try {
			for(gain=0;gain<=3;gain++){
				
				errorLocation = @"CountCALHI Control Reg Setup";
				[self loadCALHIControReg:gain];
				[ORTimer delay:0.01];
				unsigned short CountCALHI=0;
				int i=0;
				for(i=0;i<ReadNumber;i++){
					errorLocation = @"CountCALHI Conversion Start";
					[self loadConversionStart];
					errorLocation = @"CountCALHI Adc Read";
					CountCALHI+=[self readDataBlock];
				}
				CountCALHI=CountCALHI/ReadNumber;
				calibrationConstants[gain].kCountCALHI=CountCALHI;
				
				errorLocation = @"CountCALLO Control Reg Setup";
				[self loadCALLOControReg:gain];
				[ORTimer delay:KDelayTime];
				
				unsigned short CountCALLO=0;
				for(i=0;i<ReadNumber;i++){
					errorLocation = @"CountCALLO Conversion Start";
					[self loadConversionStart];
					errorLocation = @"CountCALLO Adc Read";
					CountCALLO+=[self readDataBlock];
				}
				CountCALLO=CountCALLO/ReadNumber;
				calibrationConstants[gain].kCountCALLO=CountCALLO;
				[self calculateCalibrationSlope:gain];
				
				NSLog(@"Calibraton Slope at gain %f is %f\n",pow(2,gain),calibrationConstants[gain].kSlope_m);
			}
			
			
		}
		@catch(NSException* localException) {
			NSLogError(@"",[NSString stringWithFormat:@"IP320 %d,%@",[self slot],[self identifier]],errorLocation,nil);
			//[NSException raise:[NSString stringWithFormat:@"IP320 Calibration Failed"] format:@"Error Location: %@",errorLocation];
		}
	}
	
}

- (void) readAllAdcChannels
{
	@synchronized(self) {
		if(!calibrationLoaded){
			[self calibrate];
			calibrationLoaded = YES;
		}
		//get the time(UT!)
		time_t		ut_time;
		time(&ut_time);
		//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		//time_t ut_time = mktime(theTimeGMTAsStruct);
		
		NSString*   outputString = nil;
		if(logToFile) {
			outputString = [NSString stringWithFormat:@"%lu ",ut_time];
		}
		
		short chan;
		for(chan=0;chan<kNumIP320Channels;chan++){
			if([[chanObjs objectAtIndex:chan] readEnabled]){
				if(opMode == 0 && chan>=20)break;	//if differential, don't read chan >= 20
				[self readAdcChannel:chan time:ut_time];
				if(logToFile)outputString = [outputString stringByAppendingFormat:@"%6.3f ",[self convertedValue:chan]];
			}
			else if(logToFile) outputString = [outputString stringByAppendingString:@"0 "];
		}
		
		if(logToFile){
			outputString = [outputString stringByAppendingString:@"\n"];
			//accumulate into a buffer, we'll write the file later
			if(!logBuffer)logBuffer = [[NSMutableArray arrayWithCapacity:1024] retain];
			if([outputString length]){
				[logBuffer addObject:outputString];
			}
		}
		
		readCount++;		
	}
}

- (void) _pollAllChannels
{
    @try { 
        [self readAllAdcChannels]; 
		if(shipRecords){
			[self shipRawValues]; 
			[self shipConvertedValues]; 
		}
    }
	@catch(NSException* localException) { 
		//catch this here to prevent it from falling thru, but nothing to do.
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
	if(pollingState!=0){
		[self performSelector:@selector(_pollAllChannels) withObject:nil afterDelay:pollingState];
	}
}


- (void) enablePollAll:(BOOL)state
{
    short chan;
    for(chan=0;chan<kNumIP320Channels;chan++){
        [(ORIP320Channel*)[chanObjs objectAtIndex:chan] setObject:[NSNumber numberWithBool:state] forKey:k320ChannelReadEnabled];
    }
}

- (void) enableAlarmAll:(BOOL)state
{
    short chan;
    for(chan=0;chan<kNumIP320Channels;chan++){
        [(ORIP320Channel*)[chanObjs objectAtIndex:chan] setObject:[NSNumber numberWithBool:state] forKey:k320ChannelAlarmEnabled];
    }
}

#pragma mark ¥¥¥Polling
- (void) _stopPolling
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
	pollRunning = NO;
}

- (void) _startPolling
{
	[self _setUpPolling:YES];
}

- (void) _setUpPolling:(BOOL)verbose
{
	
	if(pollRunning)return;
	
    if(pollingState!=0){  
		readCount = 0;
		pollRunning = YES;
        if(verbose)NSLog(@"Polling IP320,%d,%d,%d  every %.0f seconds.\n",[self crateNumber],[self slot],[self slotConv],pollingState);
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
        [self performSelector:@selector(_pollAllChannels) withObject:self afterDelay:pollingState];
        [self _pollAllChannels];
    }
    else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_pollAllChannels) object:nil];
        if(verbose)NSLog(@"Not Polling IP320,%d,%d,%d\n",[self crateNumber],[self slot],[self slotConv]);
    }
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setShipRecords:				[decoder decodeBoolForKey:@"ORIP320ModelShipRecords"]];
    [self setLogFile:					[decoder decodeObjectForKey:@"ORIP320ModelLogFile"]];
    [self setLogToFile:					[decoder decodeBoolForKey:@"ORIP320ModelLogToFile"]];
    [self setDisplayRaw:				[decoder decodeBoolForKey:@"ORIP320ModelDisplayRaw"]];
    [self setChanObjs:					[decoder decodeObjectForKey:@"kORIP320chanObjs"]];
	[self setPollingState:				[decoder decodeIntegerForKey:@"kORIP320PollingState"]];
	[self setMultiPlots:				[decoder decodeObjectForKey:@"multiPlots"]];
    [self setDataSet:					[decoder decodeObjectForKey:@"dataSet"]];
    
    if(chanObjs == nil){
        [self setChanObjs:[NSMutableArray array]];
        int i;
        for(i=0;i<kNumIP320Channels;i++){
            [chanObjs addObject:[[[ORIP320Channel alloc] initWithAdc:self channel:i]autorelease]];
        }
    }
	[chanObjs makeObjectsPerformSelector:@selector(setAdcCard:) withObject:self];
    [multiPlots makeObjectsPerformSelector:@selector(setDataSource:) withObject:dataSet];
	
    [self setCalibrationDate:			[decoder decodeObjectForKey:@"calibrationDate"]];
    [self setCardJumperSetting:			[decoder decodeIntForKey:@"cardJumperSetting"]];
	int gain;
	for(gain=0;gain<kNumGainSettings;gain++){
		calibrationConstants[gain].kSlope_m			= [decoder decodeFloatForKey:[NSString stringWithFormat:@"kSlope_m%d",gain]];
		calibrationConstants[gain].kIdeal_Volt_Span = [decoder decodeFloatForKey:[NSString stringWithFormat:@"kIdeal_Volt_Span%d",gain]];
		calibrationConstants[gain].kIdeal_Zero		= [decoder decodeFloatForKey:[NSString stringWithFormat:@"kIdeal_Zero%d",gain]];
		calibrationConstants[gain].kVoltCALLO		= [decoder decodeFloatForKey:[NSString stringWithFormat:@"kVoltCALLO%d",gain]];
		calibrationConstants[gain].kCountCALLO		= [decoder decodeFloatForKey:[NSString stringWithFormat:@"kCountCALLO%d",gain]];
		calibrationConstants[gain].kVoltCALHI		= [decoder decodeFloatForKey:[NSString stringWithFormat:@"kVoltCALHI%d",gain]];
		calibrationConstants[gain].kCountCALHI		= [decoder decodeIntegerForKey:  [NSString stringWithFormat:@"kCountCALHI%d",gain]];
	}
	
	[[self undoManager] enableUndoRegistration];
	
	[[NSNotificationCenter defaultCenter] addObserver : self
											 selector : @selector(writeLogBufferToFile)
												 name : ORRunStatusChangedNotification
												object: nil]; 
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:calibrationDate	forKey:@"calibrationDate"];
    [encoder encodeObject:dataSet			forKey:@"dataSet"];
    [encoder encodeBool:shipRecords			forKey:@"ORIP320ModelShipRecords"];
    [encoder encodeObject:logFile			forKey:@"ORIP320ModelLogFile"];
    [encoder encodeBool:logToFile			forKey:@"ORIP320ModelLogToFile"];
    [encoder encodeBool:displayRaw			forKey:@"ORIP320ModelDisplayRaw"];
    [encoder encodeObject:chanObjs			forKey:@"kORIP320chanObjs"];
    [encoder encodeInteger:[self pollingState]	forKey:@"kORIP320PollingState"];
    [encoder encodeObject:multiPlots		forKey:@"multiPlots"];
	
	[encoder encodeInteger:cardJumperSetting	forKey:@"cardJumperSetting"];
	int gain;
	for(gain=0;gain<kNumGainSettings;gain++){
		[encoder encodeFloat:calibrationConstants[gain].kSlope_m			forKey:[NSString stringWithFormat:@"kSlope_m%d",gain]];
		[encoder encodeFloat:calibrationConstants[gain].kIdeal_Volt_Span	forKey:[NSString stringWithFormat:@"kIdeal_Volt_Span%d",gain]];
		[encoder encodeFloat:calibrationConstants[gain].kIdeal_Zero			forKey:[NSString stringWithFormat:@"kIdeal_Zero%d",gain]];
		[encoder encodeFloat:calibrationConstants[gain].kCountCALLO			forKey:[NSString stringWithFormat:@"kCountCALLO%d",gain]];
		[encoder encodeFloat:calibrationConstants[gain].kVoltCALHI			forKey:[NSString stringWithFormat:@"kVoltCALHI%d",gain]];
		[encoder encodeInteger:calibrationConstants[gain].kCountCALHI			forKey:[NSString stringWithFormat:@"kCountCALHI%d",gain]];		
	}
}

#pragma mark ¥¥¥Bit Processing Protocol
- (void)processIsStarting
{
	[self _stopPolling];
    readOnce = NO;
}

- (void)processIsStopping
{
	[self _startPolling];
}

//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{
    if(!readOnce){
        @try { 
            [self readAllAdcChannels]; 
            if(shipRecords){
                [self shipRawValues]; 
                [self shipConvertedValues]; 
            }
            readOnce = YES;
        }
		@catch(NSException* localException) { 
			//catch this here to prevent it from falling thru, but nothing to do.
        }
    }
}

- (void) endProcessCycle
{
	readOnce = NO;
}

- (BOOL) processValue:(int)channel
{
	return [self convertedValue:channel]!=0;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    //nothing to do
}

- (NSString*) processingTitle
{
    return [NSString stringWithFormat:@"%d,%d,%@",[self crateNumber],[guardian slot],[self identifier]];
}

- (double) convertedValue:(int)channel
{
	return [[(ORIP320Channel*)[chanObjs objectAtIndex:channel] objectForKey:k320ChannelValue] doubleValue];
}

- (double) maxValueForChan:(int)channel
{
	double theMax = 0;
	@synchronized(self){
		theMax =  [[chanObjs objectAtIndex:channel] maxValue];
	}
	return theMax;
}
- (double) minValueForChan:(int)channel
{
	return 0;
}
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		*theLowLimit = [[(ORIP320Channel*)[chanObjs objectAtIndex:channel] objectForKey:k320ChannelLowValue] doubleValue];
		*theHighLimit = [[(ORIP320Channel*)[chanObjs objectAtIndex:channel] objectForKey:k320ChannelHighValue] doubleValue];
	}		
}

- (uint32_t) lowMask
{
	int i;
	uint32_t aMask = 0;
	for(i=0;i<32;i++){
		if([[chanObjs objectAtIndex:i] readEnabled]){
			aMask |= 1L<<i;
		}
	}
	return aMask;
}

- (uint32_t) highMask
{
	uint32_t aMask = 0;
	int i;
	for(i=0;i<8;i++){
		if([[chanObjs objectAtIndex:i+32] readEnabled]){
			aMask |= 1L<<i;
		}
	}
	return aMask;
}

#pragma mark ¥¥¥Data Records

- (void) setDataIds:(id)assigner
{
    dataId			= [assigner assignDataIds:kLongForm];
    convertedDataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
    [self setConvertedDataId:[anotherCard convertedDataId]];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	int i;
	for(i=0;i<kNumIP320Channels;i++){
		[objDictionary setObject:[[chanObjs objectAtIndex:i] parameters] forKey:[NSString stringWithFormat:@"chan%d",i]];
	}	
	return objDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"IP320"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORIP320DecoderForAdc",						@"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:YES],                  @"variable",
								 [NSNumber numberWithLong:-1],					@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"IP320ADC"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORIP320DecoderForValue",						@"decoder",
				   [NSNumber numberWithLong:convertedDataId],      @"dataId",
				   [NSNumber numberWithBool:YES],                  @"variable",
				   [NSNumber numberWithLong:-1],					@"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"IP320Value"];
	
    return dataDictionary;
}

- (NSString*) getSlotKey:(unsigned short)aSlot
{
	NSString* slotName[4] = {
		@"IP D",
		@"IP C",
		@"IP B",
	@"IP A"};
	
	if(aSlot<4) return slotName[aSlot];
	else return [NSString stringWithFormat:@"IP %2d",aSlot];		
}

- (void) loadConvertedTimeSeries:(float)convertedValue atTime:(time_t) aTime forChannel:(int) channel
{
	if(!dataSet)[self setDataSet:[[[ORDataSet alloc] initWithKey:@"IP320" guardian:nil] autorelease]];
	[dataSet loadTimeSeries:convertedValue atTime:(uint32_t)aTime sender:self withKeys:@"IP320",@"Value",
	 [NSString stringWithFormat:@"Crate %d",[[self guardian] crateNumber]],
	 [NSString stringWithFormat:@"Slot %02d",[[self guardian] slot]],
	 [self getSlotKey:[self slot]],
	 [NSString stringWithFormat:@"Chan %02d",channel],nil];
}

- (void) loadRawTimeSeries:(float)aRawValue atTime:(time_t) aTime forChannel:(int) channel
{
	if(!dataSet)[self setDataSet:[[[ORDataSet alloc] initWithKey:@"IP320" guardian:nil] autorelease]];
	[dataSet loadTimeSeries:aRawValue atTime:(uint32_t)aTime sender:self withKeys:@"IP320",@"Raw",
	 [NSString stringWithFormat:@"Crate %d",[[self guardian] crateNumber]],
	 [NSString stringWithFormat:@"Slot %02d",[[self guardian] slot]],
	 [self getSlotKey:[self slot]],
	 [NSString stringWithFormat:@"Chan %02d",channel],nil];
}

- (void) shipRawValues
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
	
	if(runInProgress){
		uint32_t data[43];
		
		data[1] = (([self crateNumber]&0x01e)<<21) | ([guardian slot]& 0x0000001f)<<16 | ([self slot]&0xf);
		
		//get the time(UT!)
		time_t	ut_time;
		time(&ut_time);
		//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		//time_t ut_time = mktime(theTimeGMTAsStruct);
		data[2] = (uint32_t)ut_time;	//seconds since 1970
		
		int index = 3;
		int i;
		int n;
		if(opMode == 0) n = 20;
		else n = 40;
		for(i=0;i<n;i++){
			if([[chanObjs objectAtIndex:i] readEnabled]){
				int val  = [[chanObjs objectAtIndex:i] rawValue];
				data[index++] = (i&0xff)<<16 | (val & 0xfff);
			}
		}
		data[0] = dataId | index;
		
		if(index>3){
			//the full record goes into the data stream via a notification
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:index*sizeof(int32_t)]];
		}
	}
}

- (void) shipConvertedValues
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
	
	if(runInProgress){
		uint32_t data[83];
		
		data[1] = (([self crateNumber]&0x01e)<<21) | ([guardian slot]& 0x0000001f)<<16 | ([self slot]&0xf);
		
		//get the time(UT!)
		time_t	ut_time;
		time(&ut_time);
		//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		//time_t ut_time = mktime(theTimeGMTAsStruct);
		data[2] = (uint32_t)ut_time;	//seconds since 1970
		
		int index = 3;
		int n;
		if(opMode == 0) n = 20;
		else n = 40;
		
		union {
			int32_t asLong;
			float asFloat;
		} theValue;
		
		
		int i;
		for(i=0;i<n;i++){
			if([[chanObjs objectAtIndex:i] readEnabled]){
				data[index++] = i;
				theValue.asFloat =  (float)[self convertedValue:i];
				data[index++] = theValue.asLong;
			}
		}
		data[0] = convertedDataId | index;
		
		if(index>3){
			//the full record goes into the data stream via a notification
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:index*sizeof(int32_t)]];
		}
	}
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return (item == nil) ? 1  : (int)[item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return    (item == nil) ? [self numberOfChildren]!=0 : ([item numberOfChildren] != 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSUInteger)index ofItem:(id)item
{
    if(item)   return [(ORIP320Model*)item childAtIndex:index];
    else	return dataSet;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return  ((item == nil) ? @"IP320" : [(ORIP320Model*)item name]);
}

- (NSUInteger)  numberOfChildren
{
    return [dataSet count];
}

- (id)   childAtIndex:(NSUInteger)index
{
    NSEnumerator* e = [dataSet objectEnumerator];
    id obj;
    id child = nil;
    short i = 0;
    while(obj = [e nextObject]){
        if(i++ == index){
            child = [[obj retain] autorelease];
            break;
        }
    }
    return child;
}

- (BOOL) leafNode
{
	return NO;
}

- (id)   name
{
    return @"TimeSeries";
}

- (void) removeDataSet:(ORDataSet*)item
{
    if([[item name] isEqualToString: [self name]]) {
        [self setDataSet:nil];
    }
    else { 
		[dataSet removeObject:item];
	}
}


@end
