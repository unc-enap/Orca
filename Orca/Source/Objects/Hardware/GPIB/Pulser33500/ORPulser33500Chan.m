//
//  ORPulser33500Chan.m
//  Orca
//
//  Created by Mark Howe on Thurs, Oct 25 2012.
//  Copyright (c) 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORPulser33500Chan.h"
#import "ORPulser33500Model.h"

NSString* ORPulser33500ChanVoltageChanged				= @"ORPulser33500ChanVoltageChanged";
NSString* ORPulser33500ChanVoltageOffsetChanged			= @"ORPulser33500ChanVoltageOffsetChanged";
NSString* ORPulser33500ChanDutyCycleChanged             = @"ORPulser33500ChanDutyCycleChanged";
NSString* ORPulser33500ChanFrequencyChanged             = @"ORPulser33500ChanFrequencyChanged";
NSString* ORPulser33500ChanBurstRateChanged				= @"ORPulser33500ChanBurstRateChanged";
NSString* ORPulser33500ChanBurstCountChanged			= @"ORPulser33500ChanBurstCountChanged";
NSString* ORPulser33500ChanTriggerSourceChanged			= @"ORPulser33500ChanTriggerSourceChanged";
NSString* ORPulser33500ChanTriggerTimerChanged			= @"ORPulser33500ChanTriggerTimerChanged";
NSString* ORPulser33500ChanBurstPhaseChanged			= @"ORPulser33500ChanBurstPhaseChanged";
NSString* ORPulser33500ChanSelectedWaveformChanged		= @"ORPulser33500ChanSelectedWaveformChanged";
NSString* ORPulser33500WaveformLoadingNonVoltile		= @"ORPulser33500WaveformLoadingNonVoltile";
NSString* ORPulser33500WaveformLoadProgressing			= @"ORPulser33500WaveformLoadProgressing";
NSString* ORPulser33500WaveformLoadFinished				= @"ORPulser33500WaveformLoadFinished";
NSString* ORPulser33500NegativePulseChanged             = @"ORPulser33500NegativePulseChanged";
NSString* ORPulser33500BurstModeChanged                 = @"ORPulser33500BurstModeChanged";
NSString* ORPulser33500WaveformLoadStarted				= @"ORPulser33500WaveformLoadStarted";
NSString* ORPulser33500WaveformLoadingVoltile			= @"ORPulser33500WaveformLoadingVoltile";

#define kMaxNumberOfPoints33500 0xFFFF
#define kPadSize				100
#define PI						3.141592
#define theMin					-1
#define theMax					1
#define kBitResolution			0x3FFF

static Pulser33500CustomWaveformStruct waveformData[kNumWaveforms] = {
	{ @"Sinusoid",			@"SIN",      NO , YES },
	{ @"Square",			@"SQU",      NO , YES },
	{ @"Triangle",			@"TRI",      NO , YES },
	{ @"Ramp",              @"RAMP",     NO , YES },
	{ @"Pulse Wave",        @"PULS",     NO , YES },
	{ @"Pseudo Random",     @"PRBS",     NO , YES },
	{ @"Noise",             @"NOIS",     NO , YES },
	{ @"DC Wave",           @"DC",       NO , YES },
	{ @"Square Wave 1",     @"SQU1",     NO , NO },
	{ @"Single Sin 1",      @"SGLSIN",   YES, NO },
	{ @"Single Sin 2",      @"SGLSI2",   YES, NO },
	{ @"Square Wave 2",     @"SQW2",     YES, NO },
	{ @"Double Sin Wave",   @"DBLSIN",   YES, NO },
	{ @"LogAmp Calib",      @"CALIB",    YES, NO },
	{ @"LogAmp Calib/2",    @"CALI1",    NO , NO },
	{ @"LogAmp Calib/4",    @"CALI2",    NO , NO },
	{ @"Double LogAmp",     @"DBLLOG",   YES, NO },
	{ @"Triple LogAmp",     @"TRPLOG",   YES, NO },
	{ @"LogAmp Adj",        @"AMPADJ",   YES, NO },
	{ @"Gaussian",          @"GSSIAN",   NO , NO },
	{ @"Pin Diode",         @"PINDD",    NO , NO },
	{ @"Needle",            @"NEEDLE",   NO , NO },
	{ @"GermaniumHighE",    @"GEHIGHE",  NO , NO },
	{ @"GermaniumLowE",     @"GELOWE",   NO , NO },
	{ @"From File",         @"",         NO , NO },
};


@interface ORPulser33500Chan (private)
- (void) startDownloadThread;
@end

@implementation ORPulser33500Chan
- (id) initWithPulser:(id)aPulser channelNumber:(int)aChannelNumber;
{	
    self = [super init];
    
    pulser  = aPulser;	//don't retain
    channel = aChannelNumber;
	
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [waveform release];
	[allWaveFormsInMemory release];
	//[fileName release];
    [super dealloc];
}

#pragma mark •••Accessors
- (int)channel
{
	return channel;
}

- (id) pulser
{
	return pulser;
}

- (void) setPulser:(id)aPulser
{
    pulser  = aPulser;	//don't retain
}

- (BOOL) negativePulse
{
    return negativePulse;
}

- (void) setNegativePulse:(BOOL)aNegativePulse
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNegativePulse:negativePulse];
    negativePulse = aNegativePulse;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33500NegativePulseChanged object:self];
}

- (BOOL) burstMode
{
    return burstMode;
}

- (void) setBurstMode:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBurstMode:burstMode];
    burstMode = aFlag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulser33500BurstModeChanged object:self];
}

- (int) selectedWaveform
{
    return selectedWaveform;
}

- (void) setSelectedWaveform:(int)newSelectedWaveform
{
    if(newSelectedWaveform<0)newSelectedWaveform = 0;
    else if(newSelectedWaveform>=kNumWaveforms)newSelectedWaveform = kNumWaveforms-1;
    
    [[[self undoManager] prepareWithInvocationTarget: self] setSelectedWaveform: selectedWaveform];
    selectedWaveform = newSelectedWaveform;
    
    [[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500ChanSelectedWaveformChanged object: self];
}

- (float) voltage
{
	return voltage;
}

- (void) setVoltage:(float)aValue 
{
	[[[self undoManager] prepareWithInvocationTarget: self] setVoltage:voltage];
	voltage = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500ChanVoltageChanged object: self];
}

- (float) voltageOffset
{
	return voltageOffset;
}

- (void) setVoltageOffset:(float)aValue 
{
	[[[self undoManager] prepareWithInvocationTarget: self] setVoltageOffset:voltageOffset];
	voltageOffset = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500ChanVoltageOffsetChanged object: self];
}

- (float) frequency;
{
	return frequency;
}

- (void) setFrequency:(float)aValue 
{
	[[[self undoManager] prepareWithInvocationTarget: self] setFrequency:frequency];
	frequency = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500ChanFrequencyChanged object: self];
}

- (float) dutyCycle;
{
    return dutyCycle;
}

- (void) setDutyCycle:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget: self] setDutyCycle:dutyCycle];
    if(aValue<0.01)       aValue = 0.01;
    else if(aValue>99.99) aValue = 99.99;
    dutyCycle = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500ChanDutyCycleChanged object: self];
}

- (float) burstRate;
{
	return burstRate;
}

- (void) setBurstRate:(float)aValue 
{
	[[[self undoManager] prepareWithInvocationTarget: self] setBurstRate:burstRate];
	burstRate = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500ChanBurstRateChanged object: self];
}

- (float) burstPhase;
{
	return burstPhase;
}

- (void) setBurstPhase:(float)aValue 
{
	[[[self undoManager] prepareWithInvocationTarget: self] setBurstPhase:burstPhase];
	burstPhase = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500ChanBurstPhaseChanged object: self];
}

- (int) burstCount;
{
	return burstCount;
}

- (void) setBurstCount:(int)aValue 
{
	[[[self undoManager] prepareWithInvocationTarget: self] setBurstCount:burstCount];
	burstCount = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500ChanBurstCountChanged object: self];
}

- (short)	triggerSource
{
    return triggerSource;
}

- (void) setTriggerSource:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget: self] setTriggerSource: triggerSource];
    triggerSource = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500ChanTriggerSourceChanged object: self];
}

- (float) triggerTimer
{
    return triggerTimer;
}

- (void) setTriggerTimer:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget: self] setTriggerTimer: triggerTimer];
    triggerTimer = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500ChanTriggerTimerChanged object: self];
}

- (NSUndoManager*) undoManager
{
	return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

#pragma mark ***HW Access
- (void) initHardware
{
	if([pulser isConnected]){
        if(selectedWaveform == kLogCalibrationWaveform){
            [self writeVoltage:kCalibrationVoltage];
            [self writeBurstCount:1];
            [self writeBurstRate:kCalibrationBurstRate];
            [self writeFrequency];
        }
        else {
            [self writeVoltage];
            [self writeVoltageOffset];
			[self writeFrequency];
            [self writeBurstCount];
            [self writeBurstRate];
        }
        
        if(selectedWaveform == kBuiltInSquare){
            [self writeDutyCycle];
        }
        
        [self writeBurstPhase];
        [self writeTriggerSource];
        [self writeBurstMode];
     	if(triggerSource == kTimerTrigger)[self writeTriggerTimer];
    }
}

- (void) writeVoltage
{
	[self writeVoltage:voltage];
}

- (void) writeVoltage:(float)aVoltage
{
	[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:VOLT:UNIT VPP",channel]];
	[pulser logSystemResponse];
	[pulser writeToDevice:[NSString stringWithFormat:@"SOURCE%d:VOLT %.3E",channel,voltage]];
	[pulser logSystemResponse];
	NSLog(@"33500 Pulser Voltage %d Vpp set to %.3f\n",channel,aVoltage);
}

- (void) writeVoltageOffset
{
	[pulser writeToDevice:[NSString stringWithFormat:@"SOURCE%d:VOLT:OFFS %.3f",channel,voltageOffset]];
	[pulser logSystemResponse];
	NSLog(@"33500 Pulser Voltage Offset %d V set to %.3f\n",channel,voltageOffset);
}

- (void) writeFrequency
{
	[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:FREQ %.3E",channel,frequency]];
	[pulser logSystemResponse];
	NSLog(@"33500 Pulser Frequency %d set to %.3f\n",channel,frequency);
}
- (void) writeBurstPhase
{
    [pulser writeToDevice:@"UNIT:ANGL DEG"]; 
	[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:BURS:PHAS %.3f",channel,burstPhase]];
	[pulser logSystemResponse];
	NSLog(@"33500 Burst Phase %d set to %.3f\n",channel,burstPhase);
}

- (void) writeBurstRate
{
	[self writeBurstRate:burstRate];
}

- (void) writeBurstRate:(float)aValue
{
	if(aValue>0){
		// We use rate instead of period!
		float period = 1.0/burstRate;
		[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:BURS:INT:PER %.3f",channel,period]];
		[pulser logSystemResponse];
		NSLog(@"33500 Pulser Burst Period %d set to %.3f\n",channel,period);
		[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:BURS:MODE TRIG",channel]]; ///????need to fix
		[pulser logSystemResponse];
	}
}
- (void) writeBurstCount
{
	[self writeBurstCount:burstCount];
}

- (void) writeBurstCount:(int)aValue
{
	[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:BURS:NCYC %d",channel,aValue]];
	[pulser logSystemResponse];
	NSLog(@"33500 Pulser Burst Count %d set to %d\n",channel,aValue);
}

- (void) writeBurstMode
{
   [pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:BURS:STAT %d",channel,burstMode]];
    [pulser logSystemResponse];
    NSLog(@"33500 Burst Mode %d set to %@\n",channel,burstMode?@"ON":@"OFF");

}

- (void) writeDutyCycle
{
    [pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:FUNC:SQU:DCYC %.2f",channel,dutyCycle]];
    [pulser logSystemResponse];
}

- (void) writeTriggerSource
{
	[self writeTriggerSource:triggerSource];
}

- (void) writeTriggerSource:(int)aSource
{
    switch(aSource){
        case kInternalTrigger:
            [pulser writeToDevice:[NSString stringWithFormat:@"TRIG%d:SOUR IMM",channel]];
			[pulser logSystemResponse];
			break;
        case kExternalTrigger:
			[pulser writeToDevice:[NSString stringWithFormat:@"TRIG%d:SOUR EXT",channel]];
			[pulser logSystemResponse];
            break;
        case kTimerTrigger:
			[pulser writeToDevice:[NSString stringWithFormat:@"TRIG%d:SOUR TIM",channel]];
			[pulser logSystemResponse];
            break;
        case kSoftwareTrigger:
			[pulser writeToDevice:[NSString stringWithFormat:@"TRIG%d:SOUR BUS",channel]];
			[pulser logSystemResponse];
            break;
        default:
            NSLog(@"ORPulserModel:writeTriggerSource - The selection %s, is not valid.  1 = Internal, 2 = External, 3 = Timer, 4 = Bus\n",aSource);
            break;
    }
}

- (void) writeTriggerTimer
{
	[pulser writeToDevice:[NSString stringWithFormat:@"TRIG%d:TIM %.6f",channel,triggerTimer]];
	[pulser logSystemResponse];
	NSLog(@"33500 Pulser Trigger Timer %d set to %.6f\n",channel,triggerTimer);
}

- (void) trigger
{
	if([pulser isConnected]){
		[pulser writeToDevice:@"*TRG"];
	}
}

- (void) emptyVolatileMemory
{	
	if([pulser connectionProtocol] == kPulser33500UseIP){
		@try {
			[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:DATA:CLE",channel]];
		}
		@catch(NSException* localException) {
		}
	
		[pulser setWaitForGetWaveformsLoadedDone:YES];
		[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:Data:CAT?;*WAI;*OPC?",channel]];
	}
	else {
		@try {
			NSArray* allInMemory = [self getLoadedWaveforms];
			for(NSString* aName in allInMemory){
				if( ![self inBuiltInList:aName] && [self inCustomList:aName]){
					[pulser writeToDevice:[NSString stringWithFormat:@"*RST;*CLS;DATA:DEL %@",aName]];
				}
			}
		}
		@catch(NSException* localException) {
		}
	}		
}

			 
#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
 	
	channel =				[decoder decodeIntForKey:@"channel"];
	[self setVoltage:		[decoder decodeFloatForKey:@"voltage"]];
	[self setVoltageOffset:	[decoder decodeFloatForKey:@"voltageOffset"]];
    [self setFrequency:     [decoder decodeFloatForKey:@"frequency"]];
    [self setDutyCycle:     [decoder decodeFloatForKey:@"dutyCycle"]];
	[self setBurstRate:		[decoder decodeFloatForKey:@"burstRate"]];
	[self setBurstPhase:	[decoder decodeFloatForKey:@"burstPhase"]];
	[self setBurstCount:	[decoder decodeIntForKey:@"burstCount"]];
	[self setTriggerSource:	[decoder decodeIntForKey:@"triggerSource"]];
	[self setTriggerTimer:	[decoder decodeFloatForKey:@"triggerTimer"]];
    [self setSelectedWaveform:     [decoder decodeIntForKey:@"selectedWaveform"]];
    [self setBurstMode:     [decoder decodeBoolForKey:@"burstMode"]];

	if(voltage==0 && frequency==0 && burstCount==0 && burstPhase==0){
		[self setVoltage:5];
		[self setBurstRate:1];
		[self setVoltageOffset:0];
		[self setFrequency:1000.0];
		[self setBurstCount:1];
		[self setBurstPhase:0];
	}
	
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{

	[encoder encodeInt:channel			forKey:@"channel"];
	[encoder encodeFloat:voltage		forKey:@"voltage"];
	[encoder encodeFloat:voltageOffset	forKey:@"voltageOffset"];
    [encoder encodeFloat:frequency      forKey:@"frequency"];
    [encoder encodeFloat:dutyCycle      forKey:@"dutyCycle"];
	[encoder encodeFloat:burstRate		forKey:@"burstRate"];
	[encoder encodeFloat:burstPhase		forKey:@"burstPhase"];
	[encoder encodeInt:burstCount		forKey:@"burstCount"];
	[encoder encodeInt:triggerSource	forKey:@"triggerSource"];
	[encoder encodeFloat:triggerTimer	forKey:@"triggerTimer"];
    [encoder encodeInt:selectedWaveform forKey:@"selectedWaveform"];
    [encoder encodeBool:burstMode       forKey:@"burstMode"];
}

#pragma mark •••Waveform Loading
- (unsigned int) maxNumberOfWaveformPoints
{
	return kMaxNumberOfPoints33500;
}

- (int) downloadIndex
{
    return downloadIndex;
}

- (BOOL) loading
{
    return loading;
}

- (void) setLoading:(BOOL)aState
{
	loading = aState;
	[pulser setLoading:aState];
}

- (void) downloadWaveform
{
    if([pulser isConnected]){
		
		if([pulser connectionProtocol] == kPulser33500UseIP) [pulser setWaitForAsyncDownloadDone:YES];
		else												[pulser setWaitForAsyncDownloadDone:NO];
				
		if(loading){
			[self stopDownload];
			[self performSelector:@selector(startDownloadThread) withObject:nil afterDelay:3];
		}
		else [self startDownloadThread];
	}
}

- (void) stopDownload
{
    [self setLoading:NO];
    NSLog(@"Waveform Download Stopped\n");
}

- (void) loadFromNonVolativeMemory
{
    if([pulser isConnected]){
		if (waveformData[selectedWaveform].builtInFunction) {
        	[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:FUNC %@",channel,waveformData[selectedWaveform].storageName]];
        	[pulser logSystemResponse];
			
		} else {
        	[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:FUNC:ARB %@",channel,waveformData[selectedWaveform].storageName]];
        	[pulser logSystemResponse];
        	[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:OUTPUT ON",channel]];
        	[pulser logSystemResponse];
		}
        [self initHardware];
    }
}

- (void) loadFromVolativeMemory
{
    if([pulser isConnected]){
        if(waveformData[selectedWaveform].tryToStore){
            @try {
				[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:FUNC:ARB %@",channel,waveformData[selectedWaveform].storageName]];
            }
			@catch(NSException* localException) {
			}
        }
		[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:FUNC:USER VOLATILE;*WAI",channel]];
		[pulser logSystemResponse];
		[self  initHardware];
    }
}

- (BOOL) inBuiltInList:(NSString*)aName
{
    int i;
    for(i=0;i<kNumBuiltInTypes;i++){
        if([waveformData[i].storageName isEqualToString:aName]){
            return YES;
        }
    }
    return NO;
}

- (BOOL) inCustomList:(NSString*)aName
{
    int i;
    for(i=kNumBuiltInTypes;i<kNumWaveforms;i++){
        if([waveformData[i].storageName isEqualToString:aName]) {
            return YES;
        }
    }
    return NO;
}
-(unsigned short) numPoints
{
    return [waveform length]/sizeof(float);
}
- (id) calibration
{
	return nil;
}
- (void)setWaveform:(NSMutableData* )newWaveform
{
    [newWaveform retain];
    [waveform release];
    waveform = newWaveform;
}

- (NSMutableData* )waveform
{
    return waveform;
}

- (BOOL) isWaveformInNonVolatileMemory
{
	if ([self inBuiltInList:waveformData[selectedWaveform].storageName]) return YES;
    BOOL result = NO;
    @try {
        NSArray* allInMemory = [self getLoadedWaveforms];
        for(NSString* aName in allInMemory){
            //Check if our selected waveform is already in memory
            if( [aName isEqualToString:waveformData[selectedWaveform].storageName]){
                result = YES;
                break;
            }
        }
        
	}
	@catch(NSException* localException) {
		result = NO;
	}
	return  result;
}


- (NSArray*) getLoadedWaveforms
{
	if([pulser connectionProtocol] == kPulser33500UseIP ){
		[pulser setWaitForGetWaveformsLoadedDone:YES];
		[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:Data:CAT?;*WAI;*OPC?",channel]];
		return allWaveFormsInMemory;
	}
	else {
		//get list of waveforms already in pulser
		char reply[1024];
		long n = [pulser writeReadDevice:[NSString stringWithFormat:@"SOUR%d:Data:CAT?",channel] data:reply maxLength:1024];
		if(n>0)reply[n-1]='\0';
		NSString* replyString = [[[NSString stringWithCString:reply encoding:NSASCIIStringEncoding] componentsSeparatedByString:@"\""] componentsJoinedByString:@""];
		replyString = [replyString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		return [replyString componentsSeparatedByString:@","];
	}
}


- (NSString *) fileName
{
    return fileName;
}

- (void) setFileName:(NSString *)newFileName
{
    [fileName autorelease];
    fileName = [newFileName copy];
}


- (unsigned int) numberOfWaveforms
{
	return kNumWaveforms;
}

- (NSString*) nameOfWaveformAt:(unsigned int)position
{
	if (position >= [self numberOfWaveforms]) return @"";
	return waveformData[position].waveformName;
}
- (void) copyWaveformWorker
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; //threads must have their own pool
    
    @try {
        [self loadFromNonVolativeMemory];
    }
	@catch(NSException* localException) {
	}
	
	[self performSelectorOnMainThread:@selector(waveFormWasSent) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void) downloadWaveformWorker
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; //threads must have their own pool
    
    @try {
        [pulser enableEOT:NO];
        [pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:DATA:ARG %@,",channel,[self nameOfWaveformAt:selectedWaveform]]];
        
        const float* ptr = (const float*)[waveform bytes];
        for(downloadIndex=0;downloadIndex<[self numPoints]-1;downloadIndex++){
            if(!loading)break;
			if (ptr[downloadIndex]==0) {
				[pulser writeToDevice:@"0.0001,"];
			} else {
				[pulser writeToDevice:[NSString stringWithFormat:@"%6.5f,",ptr[downloadIndex]]];
			}
            if(!(downloadIndex%10)){
				[self performSelectorOnMainThread:@selector(updateLoadProgress) withObject:nil waitUntilDone:NO];
            }
        }
        [pulser enableEOT:YES];
		if (ptr[downloadIndex]==0) {
			[pulser writeToDevice:@"0\n;*WAI"];
		} else {
			[pulser writeToDevice:[NSString stringWithFormat:@"%6.5f\n;*WAI",ptr[downloadIndex]]];
		}
        if(loading){
            [pulser logSystemResponse];
            [self loadFromVolativeMemory];
        }
	}
	@catch(NSException* localException) {
	}
	
	downloadIndex = [self numPoints];
	
	[self performSelectorOnMainThread:@selector(waveFormWasSent) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void) updateLoadProgress
{
	[[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500WaveformLoadProgressing object: self];
}

- (void) waveFormWasSent
{
	if(![pulser waitForAsyncDownloadDone]){
		[self setLoading:NO];
		[[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500WaveformLoadFinished object: self];
		[self writeTriggerSource:savedTriggerSource];
		NSLog(@"Waveform Download Complete\n");
	}
	
	[pulser writeToDevice:[NSString stringWithFormat:@"SOUR%d:Output ON;*WAI",channel]];
	if([pulser connectionProtocol] == kPulser33500UseIP){
		[pulser writeToDevice:@"*OPC?"];
	}
}

#pragma mark •••Helpers
- (float) calculateFreq:(float)width
{
	float theFreq = (float)(([self numPoints] - kPadSize)/(float)[self numPoints]) * 1/width;
	
	return theFreq;
}
- (void) insert:(unsigned short) numPoints value:(float) theValue;
{
	if ([self numPoints] >= [self maxNumberOfWaveformPoints]) return;
    short i;
    for(i=0;i<numPoints;i++){
        [waveform appendBytes:&theValue length:sizeof(float)];
    }
}

- (void) insertNegativeFullSineWave:(unsigned short)numPoints amplitude:(float) theAmplitude phase:(float) thePhase
{
    double theAngleStepSize = (2*PI)/(float)numPoints;
    double anAngle = thePhase*2*PI/360.;
    short i;
	int inverter = negativePulse?1:-1;
    for(i=0;i<numPoints;i++){
        float number = inverter*0.5*fabs(theAmplitude)*(sin(anAngle) - 1);
        [waveform appendBytes:&number length:sizeof(float)];
        anAngle += theAngleStepSize;
    }
}

- (void) insertGaussian:(unsigned short)numPoints amplitude:(float) theAmplitude
{
    short i;
	int inverter = negativePulse?-1:1;
	float multipler = inverter*2.*theAmplitude*(1/sqrtf(2*3.14159));
	float x=0;
	float stepSize = .01;
	float mu = (numPoints*stepSize)/2.;
    for(i=0;i<numPoints;i++){
		float number =  multipler * expf(-powf(x-mu,2.)/2.);
		x += stepSize;
        [waveform appendBytes:&number length:sizeof(float)];
    }
}


- (void) insertPinDiode:(unsigned short)numPoints amplitude:(float) theAmplitude
{
    short i;
	int inverter = negativePulse?1:-1;
    for(i=0;i<numPoints;i++){
		float number = -inverter*theAmplitude*expf(-i/((float)numPoints/10.));
        [waveform appendBytes:&number length:sizeof(float)];
    }
}

- (void) buildWave
{
    [self setWaveform: [NSMutableData dataWithCapacity:[self maxNumberOfWaveformPoints] *sizeof(float)]];
    
    //int count = [self numPoints];
	
	int inverter = negativePulse?1:-1;
	
    switch(selectedWaveform){
        case kSquareWave1:
            [self insert:kPadSize/2 value:0];
            [self insert:400 value:theMin * inverter];
            [self insert:kPadSize/2 value:0];
            break;
            
        case kSingleSinWave1:
			[self insert:kPadSize/2 value:0];
            [self insertNegativeFullSineWave:5000 amplitude:theMax phase:90];
			[self insert:kPadSize/2 value:0];
            break;
            
		case kSingleSinWave2:
            [self insert:kPadSize/2 value:0];
            [self insert:100 value:theMin*inverter];
            [self insert:3450+200+3690 value:0];
            [self insertNegativeFullSineWave:2*1280 amplitude:theMax phase:90];
            [self insert:kPadSize/2 value:0];
            break;
            
        case kSquareWave2:
			
			[self insert:kPadSize/2 value:0];
			[self insert:100 value:theMin*inverter];	
			//[self insert:3450+200+1280+3690 value:0];
            [self insert:1000 value:0];
			[self insert:1280 value:theMin*inverter];
			[self insert:3450+200+1280+3690-1000 value:0]; 
			[self insert:kPadSize/2 value:0];
			
			break;
            
        case kDoubleSinWave:
			[self insert:kPadSize/2 value:0];
            [self insertNegativeFullSineWave:7500 amplitude:theMax phase:90];
            [self insertNegativeFullSineWave:7500 amplitude:theMax phase:90];
			[self insert:kPadSize/2 value:0];
            break;
            
        case kLogCalibrationWaveform:  //this waveform should be defined by 10,000 points + the padsize.
									   //this gaurantees that each data point is 0.78000ns wide and that the sine wave portion
									   //is 998.4ns wide
            [self insert:kPadSize/2 value:0];
            [self insert:100 value:theMin*inverter];  //was 300 points
			[self insert:3450+200+1280+3690 value:0]; //8620
            [self insertNegativeFullSineWave:1280 amplitude:theMax phase:90];
            [self insert:kPadSize/2 value:0];
            
            break;
            
		case kLogCalibWave2:  //this waveform should be defined by 10,000 points + the padsize.
							  //this gaurantees that each data point is 0.78000ns wide and that the sine wave portion
							  //is 499.22ns wide
			[self insert:kPadSize/2 value:0];
            [self insert:100 value:theMin*inverter];  //was 300 points
            [self insert:3450+200+1280+3690 value:0];
            [self insertNegativeFullSineWave:1280/2 amplitude:theMax phase:90];
			[self insertNegativeFullSineWave:1280/2 amplitude:theMax phase:90];      
			[self insert:kPadSize/2 value:0];
            
            break;
            
		case kLogCalibWave4:  //this waveform should be defined by 10,000 points + the padsize.
							  //this gaurantees that each data point is 0.78000ns wide and that the sine wave portion
							  //is 249.6ns wide
            [self insert:kPadSize/2 value:0];
            [self insert:100 value:theMin*inverter];  //was 300 points
            [self insert:3450+200+1280+3690 value:0];
            [self insertNegativeFullSineWave:1280/4 amplitude:theMax phase:90];
			[self insertNegativeFullSineWave:1280/4 amplitude:theMax phase:90];
			[self insertNegativeFullSineWave:1280/4 amplitude:theMax phase:90];
			[self insertNegativeFullSineWave:1280/4 amplitude:theMax phase:90];
            [self insert:kPadSize/2 value:0];
            
            break;
			
		case kDoubleLogamp:  //this waveform should be defined by 10,000 points + the padsize.
							 //this gaurantees that each data point is 0.78000ns wide and that the sine wave portion
							 //is 998.4ns wide
			[self insert:kPadSize/2 value:0];
            [self insert:100 value:theMin*inverter];  //was 300 points
            [self insert:3450+200+3690 value:0];
            [self insertNegativeFullSineWave:1280 amplitude:theMax phase:90];
			[self insertNegativeFullSineWave:1280 amplitude:theMax phase:90];      
			[self insert:kPadSize/2 value:0];
            
            break;
			
		case kTripleLogamp:  //this waveform should be defined by 10,000 points + the padsize.
							 //this gaurantees that each data point is 0.78000ns wide and that the sine wave portion
							 //is 998.4ns wide
			[self insert:kPadSize/2 value:0];
            [self insert:100 value:theMin*inverter];  //was 300 points
            [self insert:3450+200+3690-1280 value:0];
            [self insertNegativeFullSineWave:1280 amplitude:theMax phase:90];
			[self insertNegativeFullSineWave:1280 amplitude:theMax phase:90];  
			[self insertNegativeFullSineWave:1280 amplitude:theMax phase:90];    
			[self insert:kPadSize/2 value:0];
            
            break;
            
		case kLogCalibWaveAdjust:  //this waveform should be defined by 10,000 points + the padsize.
								   //this gaurantees that each data point is 0.78000ns wide and that the sine wave portion
								   //is 998.4ns wide.  this waveform is not the default logamp wave (although it is programmed 
								   //the same) so that the amplitude and widths can be adjusted.
            [self insert:kPadSize/2 value:0];
            [self insert:100 value:theMin*inverter];  //was 300 points
            [self insert:3450+200+1280+3690 value:0];
            [self insertNegativeFullSineWave:1280 amplitude:theMax phase:90];
            [self insert:kPadSize/2 value:0];
            break;
			
		case kGaussian:
            [self insert:kPadSize/2 value:0];
            [self insertGaussian:1280 amplitude:theMax];
            [self insert:kPadSize/2 value:0];
            break;
			
		case kPinDiode:
            [self insert:1000 value:0];
            [self insertPinDiode:4000 amplitude:theMax];
            break;
			
		case kNeedle:
			[self loadWaveformFile:@"Needle"];
			break;
			
		case kGermaniumHighE:
			[self loadWaveformFile:@"GermaniumHighE"];
			break;
			
		case kGermaniumLowE:
			[self loadWaveformFile:@"GermaniumLowE"];
			break;
			
        case kWaveformFromFile: {
            
            NSString*       contents = [NSString stringWithContentsOfFile:[fileName stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
            NSScanner*      scanner  = [NSScanner scannerWithString:contents];
            NSCharacterSet* set 	 = [NSCharacterSet characterSetWithCharactersInString:@" ,\t\r\n"];
			//[self insert:kPadSize/2 value:0];
            while(![scanner isAtEnd]) {
                NSString*  destination = [NSString string];
                [scanner scanUpToCharactersFromSet:[set invertedSet] intoString:nil];
                if([scanner scanUpToCharactersFromSet:set intoString:&destination]){
                    if([destination length]){
                        [self insert:1 value:[destination floatValue]];
                    }
                }
            }
			//[self insert:kPadSize/2 value:0];
			[self normalizeWaveform];
			
        }
			break;
            
    }
	
    //count = [self numPoints];
    
}
- (void) loadWaveformFile:(NSString*) theWavefile
{
	
	NSString* bp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:theWavefile];     
	NSString*       contents = [NSString stringWithContentsOfFile:bp encoding:NSASCIIStringEncoding error:nil];
	NSScanner*      scanner  = [NSScanner scannerWithString:contents];
	NSCharacterSet* set 	 = [NSCharacterSet characterSetWithCharactersInString:@" ,\t\r\n"];
	[self insert:kPadSize/2 value:0];
	while(![scanner isAtEnd]) {
		NSString*  destination = [NSString string];
		[scanner scanUpToCharactersFromSet:[set invertedSet] intoString:nil];
		if([scanner scanUpToCharactersFromSet:set intoString:&destination]){
			if([destination length]){
				[self insert:1 value:[destination floatValue]];
			}
		}
	}
	[self insert:kPadSize/2 value:0];
	[self normalizeWaveform];
	
}	

- (void) normalizeWaveform
{
	float* w = (float*)[waveform bytes];
	int n = [waveform length]/sizeof(float);
	int i;
	float maxValue = -9.9E10;
	float minValue = 9.9E10;
	for(i=0;i<n;i++){
		if(w[i]>maxValue)maxValue = w[i];
		if(w[i]<minValue)minValue = w[i];
	}
	
	float scaleFactor;
	if(minValue<0 && (fabs(minValue) > maxValue))scaleFactor = 1./minValue;
	else scaleFactor = 1./maxValue;
	
	for(i=0;i<n;i++){
		w[i] *= scaleFactor*(negativePulse?-1:1);
		if (fabs(w[i]) <= 1./kBitResolution) {
			w[i] = 0;
		}
	}
}


@end

@implementation ORPulser33500Chan (private)
- (void) startDownloadThread
{
	downloadIndex = 0;
    [self setLoading:YES];
	[self buildWave];
	
	savedTriggerSource = triggerSource;
	[self writeTriggerSource:kSoftwareTrigger];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500WaveformLoadStarted object: self];
	if([self isWaveformInNonVolatileMemory]){
		[[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500WaveformLoadingNonVoltile object: self];
		[NSThread detachNewThreadSelector: @selector( copyWaveformWorker ) toTarget:self withObject: nil];
	}
	else {
		//not in volatile memory so spawn off a thread, since the load can take awhile
		[[NSNotificationCenter defaultCenter] postNotificationName: ORPulser33500WaveformLoadingVoltile object: self];
		[NSThread detachNewThreadSelector: @selector( downloadWaveformWorker ) toTarget:self withObject: nil];
	}
}


@end
