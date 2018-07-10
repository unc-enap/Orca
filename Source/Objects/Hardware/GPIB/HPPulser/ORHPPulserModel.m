//
//  ORHPPulserModel.m
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
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
#import "ORHPPulserModel.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"

#import <math.h>

#define kMaxLengthOfReply		128
#define kMaxLengthOfShortMessage	64
#define theMin				-1
#define theMax				1

#define kLogAmpVoltage  	750
#define kLogAmpPulseWidth  	7.8  //can't have it exactly 8 because of a bug in the HP pulser
#define kLogAmpBurstRate  	3.0
#define kBitResolution      0x3FFF


#define PI  3.141592

#pragma mark •••Notification Strings
NSString* ORHPPulserModelVerboseChanged = @"ORHPPulserModelVerboseChanged";
NSString* ORHPPulserModelNegativePulseChanged = @"ORHPPulserModelNegativePulseChanged";
NSString* ORHPPulserModelLockGUIChanged = @"ORHPPulserModelLockGUIChanged";
NSString* ORHPPulserVoltageChangedNotification		= @"HP Pulser Voltage Changed";
NSString* ORHPPulserVoltageOffsetChangedNotification		= @"HP Pulser Voltage Offset Changed";
NSString* ORHPPulserFrequencyChangedNotification		= @"HP Pulser Frequency Changed";
NSString* ORHPPulserBurstRateChangedNotification	= @"HP Pulser Burst Rate Changed";
NSString* ORHPPulserBurstPhaseChangedNotification	= @"HP Pulser Burst Phase Changed";
NSString* ORHPPulserBurstCyclesChangedNotification	= @"HP Pulser Burst Cycles Changed";
//NSString* ORHPPulserTotalWidthChangedNotification       = @"HP Pulser Total Width Changed";
NSString* ORHPPulserSelectedWaveformChangedNotification = @"HP Pulser Selected Waveform";
NSString* ORHPPulserWaveformLoadStartedNotification     = @"HP Pulser Waveform Load Started";
NSString* ORHPPulserWaveformLoadProgressingNotification = @"HP Pulser Waveform Load Progressing";
NSString* ORHPPulserWaveformLoadFinishedNotification	= @"HP Pulser Waveform Load Finished";
NSString* ORHPPulserWaveformLoadingNonVoltileNotification = @"ORHPPulserWaveformLoadingNonVoltileNotification";
NSString* ORHPPulserWaveformLoadingVoltileNotification = @"ORHPPulserWaveformLoadingVoltileNotification";
NSString* ORHPPulserTriggerModeChangedNotification	= @"ORHPPulserTriggerModeChangedNotification";
NSString* ORHPPulserEnableRandomChangedNotification = @"ORHPPulserEnableRandomChangedNotification";
NSString* ORHPPulserMinTimeChangedNotification		= @"ORHPPulserMinTimeChangedNotification";
NSString* ORHPPulserMaxTimeChangedNotification		= @"ORHPPulserMaxTimeChangedNotification";
NSString* ORHPPulserRandomCountChangedNotification	= @"ORHPPulserRandomCountChangedNotification";

static HPPulserCustomWaveformStruct waveformData[kNumWaveforms] = {
{ @"Sine Wave",         @"SIN",      NO , YES },
{ @"Square Wave",       @"SQU",      NO , YES },
{ @"Ramp",              @"RAMP",     NO , YES },
{ @"Pulse Wave",        @"PULS",     NO , YES },
{ @"Noise",             @"NOIS",     NO , YES },
{ @"DC Wave",           @"DC",       NO , YES },
{ @"Built-in Sinc Wave",@"SINC",     NO , NO },
{ @"Built-in Neg Ramp", @"NEG_RAMP", NO , NO },
{ @"Built-in Exp Rise", @"EXP_RISE", NO , NO },
{ @"Built-in Exp Fall", @"EXP_FALL", NO , NO },
{ @"Cardiac Wave",      @"CARDIAC",  NO , NO },
{ @"Square Wave 1",     @"",         NO , NO },
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
{ @"Script Defined",    @"",         NO , NO },
};


@interface ORHPPulserModel (private)
- (void) firePulserRandom;
- (void) startDownloadThread;
@end

@implementation ORHPPulserModel

#pragma mark ***Initialization
//--------------------------------------------------------------------------------
/*!\method  init
 * \brief	Called first time class is initialized.  Used to set basic
 *			default values first time object is created.
 * \note
 */
//--------------------------------------------------------------------------------
- (id) init
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setVoltage:kLogAmpVoltage];
    [self setBurstRate:kLogAmpBurstRate];
	//    [self setTotalWidth:kLogAmpPulseWidth];
    [self setVoltageOffset:0];
    [self setFrequency:1000.0];
    [self setBurstCycles:1];
    [self setBurstPhase:0];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

//--------------------------------------------------------------------------------
/*!\method  dealloc
 * \brief	Deletes anything on the heap.
 * \note
 */
//--------------------------------------------------------------------------------
- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [waveform release];
	[fileName release];
    [super dealloc];
}

//--------------------------------------------------------------------------------
/*!\method  setUpImage
 * \brief	Sets the image used by this device.
 * \note
 */
//--------------------------------------------------------------------------------
- (void) setUpImage
{
    [self setImage: [NSImage imageNamed: @"HPPulserIcon"]];
}


- (NSString*) title 
{
	return [@"33120 Pulser " stringByAppendingString: [super title]];
}


- (void) makeMainController
{
    [self linkToController:@"ORHPPulserController"];
}

- (NSString*) helpURL
{
	return @"GPIB/Aglient_33120a.html";
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
}

- (void) runStatusChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
	if(!runInProgress){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(firePulserRandom)  object:nil];
	}
	else {
		if(enableRandom && triggerSource == kSoftwareTrigger){
			if([gOrcaGlobals runRunning]){
				[self setRandomCount:0];
				if(minTime>maxTime){
					[[self undoManager] disableUndoRegistration];
					float temp = minTime;
					[self setMinTime:maxTime];
					[self setMaxTime:temp];
					[[self undoManager] enableUndoRegistration];
				}
				srand((NSUInteger)(time(0)));		
				float deltaTime = random_range((int)(minTime*10),(int)(maxTime*10))/10000.;
				[self performSelector:@selector(firePulserRandom) withObject:nil afterDelay:deltaTime];
			}
		}
	}
}


#pragma mark •••Accessors

- (BOOL) verbose
{
    return verbose;
}

- (void) setVerbose:(BOOL)aVerbose
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVerbose:verbose];
    
    verbose = aVerbose;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORHPPulserModelVerboseChanged object:self];
}

- (BOOL) negativePulse
{
    return negativePulse;
}

- (void) setNegativePulse:(BOOL)aNegativePulse
{
    [[[self undoManager] prepareWithInvocationTarget:self] setNegativePulse:negativePulse];
    
    negativePulse = aNegativePulse;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHPPulserModelNegativePulseChanged object:self];
}

- (BOOL) lockGUI
{
    return lockGUI;
}

- (void) setLockGUI:(BOOL)aLockGUI
{
    lockGUI = aLockGUI;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHPPulserModelLockGUIChanged object:self];
}

- (BOOL) enableRandom
{
	return enableRandom;
}
- (void) setEnableRandom:(BOOL)aNewEnableRandom
{
	[[[self undoManager] prepareWithInvocationTarget:self] setEnableRandom:enableRandom];
    
	enableRandom = aNewEnableRandom;
    
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORHPPulserEnableRandomChangedNotification 
	 object: self ];
}

- (float) minTime
{
	return minTime;
}
- (void) setMinTime:(float)aNewMinTime
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMinTime:minTime];
    
	minTime = aNewMinTime;
    
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORHPPulserMinTimeChangedNotification 
	 object: self ];
}

- (float) maxTime
{
	return maxTime;
}
- (void) setMaxTime:(float)aNewMaxTime
{
	[[[self undoManager] prepareWithInvocationTarget:self] setMaxTime:maxTime];
    
	maxTime = aNewMaxTime;
    
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORHPPulserMaxTimeChangedNotification 
	 object: self ];
}
- (unsigned long) randomCount
{
	return randomCount;
}
- (void) setRandomCount:(unsigned long)aNewRandomCount
{
	randomCount = aNewRandomCount;
    
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORHPPulserRandomCountChangedNotification 
	 object: self ];
}

- (int) burstCycles
{
    return burstCycles;	
}

- (void) setBurstCycles:(int)newCycles
{
    [[[self undoManager] prepareWithInvocationTarget: self]
	 setBurstCycles: [self burstCycles]];
    burstCycles = newCycles;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName: ORHPPulserBurstCyclesChangedNotification
	 object: self];
}

- (int) burstPhase
{
    return burstPhase;	
}

- (void) setBurstPhase:(int)newPhase
{
    [[[self undoManager] prepareWithInvocationTarget: self]
	 setBurstPhase: [self burstPhase]];
    burstPhase = newPhase;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName: ORHPPulserBurstPhaseChangedNotification
	 object: self];
}

- (float) frequency
{
    return frequency;	
}

- (void) setFrequency:(float)newFrequency
{
    [[[self undoManager] prepareWithInvocationTarget: self]
	 setFrequency: [self frequency]];
    frequency = newFrequency;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName: ORHPPulserFrequencyChangedNotification
	 object: self];
}

- (float)	voltage
{
    return voltage;
}

- (void) setVoltage:(float)newVoltage
{
    [[[self undoManager] prepareWithInvocationTarget: self]
	 setVoltage: [self voltage]];
    voltage = newVoltage;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName: ORHPPulserVoltageChangedNotification
	 object: self];
}

- (float)	voltageOffset
{
    return voltageOffset;
}

- (void) setVoltageOffset:(float)newVoltageOffset
{
    [[[self undoManager] prepareWithInvocationTarget: self]
	 setVoltageOffset: [self voltageOffset]];
    voltageOffset = newVoltageOffset;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName: ORHPPulserVoltageOffsetChangedNotification
	 object: self];
}


- (float) burstRate
{
    return burstRate;
}

- (void) setBurstRate:(float)newBurstRate
{
    [[[self undoManager] prepareWithInvocationTarget: self]
	 setBurstRate: [self burstRate]];
    burstRate = newBurstRate;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName: ORHPPulserBurstRateChangedNotification
	 object: self];
}

- (float) totalWidth
{
    float theWidth;
	if (frequency != 0) {
        theWidth = (float)(([self numPoints] - kPadSize)/(float)[self numPoints]) * 1/frequency;
    } else {
        theWidth = 0.;
    }
    return theWidth;
}

- (void) setTotalWidth:(float)newTotalWidth
{
    [self setFrequency:[self calculateFreq:newTotalWidth]];
}

- (int)	triggerSource
{
    return triggerSource;
}

- (void) setTriggerSource:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget: self]
	 setTriggerSource: [self triggerSource]];
    triggerSource = aValue;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName: ORHPPulserTriggerModeChangedNotification
	 object: self];
}

- (void) trigger
{
    if([self isConnected]){
        [self writeToGPIBDevice:@"*TRG"];
    }
}

- (int) selectedWaveform
{
    return selectedWaveform;
}

- (void) setSelectedWaveform:(int)newSelectedWaveform
{
    if(newSelectedWaveform<0)newSelectedWaveform = 0;
    else if(newSelectedWaveform>=kNumWaveforms)newSelectedWaveform = kNumWaveforms-1;
    
    [[[self undoManager] prepareWithInvocationTarget: self]
	 setSelectedWaveform: [self selectedWaveform]];
    selectedWaveform = newSelectedWaveform;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName: ORHPPulserSelectedWaveformChangedNotification
	 object: self];
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

- (NSString *) fileName
{
    return fileName;
}

- (void) setFileName:(NSString *)newFileName
{
    [fileName autorelease];
    fileName = [newFileName copy];
}

- (unsigned long)   pulserDataId {return pulserDataId;}
- (void)   setPulserDataId:(unsigned long)aValue
{
    pulserDataId = aValue;
}

- (void) setDataIds:(id)assigner
{
    pulserDataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherPulser
{
    [self setPulserDataId:[anotherPulser pulserDataId]];
}

- (int) downloadIndex
{
    return downloadIndex;
}

- (BOOL) loading
{
    return loading;
}

- (void) setLoading:(BOOL)aLoad
{
	loading = aLoad;
}

- (void) insert:(unsigned short) numPoints value:(float) theValue;
{
	if ([self numPoints] >= [self maxNumberOfWaveformPoints]) return;
    unsigned short i;
    for(i=0;i<numPoints;i++){
        [waveform appendBytes:&theValue length:sizeof(float)];
    }
}

- (void) insertNegativeFullSineWave:(unsigned short)numPoints amplitude:(float) theAmplitude phase:(float) thePhase
{
    double theAngleStepSize = (2*PI)/(float)numPoints;
    double anAngle = thePhase*2*PI/360.;
    unsigned short i;
	int inverter = negativePulse?1:-1;
    for(i=0;i<numPoints;i++){
        float number = inverter*0.5*fabs(theAmplitude)*(sin(anAngle) - 1);
        [waveform appendBytes:&number length:sizeof(float)];
        anAngle += theAngleStepSize;
    }
}

- (void) insertGaussian:(unsigned short)numPoints amplitude:(float) theAmplitude
{
    unsigned short i;
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
    unsigned short i;
	int inverter = negativePulse?1:-1;
    for(i=0;i<numPoints;i++){
		float number = -inverter*theAmplitude*expf(-i/((float)numPoints/10.));
        [waveform appendBytes:&number length:sizeof(float)];
    }
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

-(unsigned short) numPoints
{
    return [waveform length]/sizeof(float);
}


- (id)  dialogLock
{
	return @"ORHPPulserLock";
}

- (unsigned int) maxNumberOfWaveformPoints
{
	return kMaxNumWaveformPoints;
}

#pragma mark •••Hardware Access
-(NSString*) readIDString
{
    if([self isConnected]){
        char  reply[256];
        long n = [self writeReadGPIBDevice: @"*IDN?"
                                      data: reply
                                 maxLength: 256 ];
        reply[n] = "\n";
        NSString* s =  [NSString stringWithCString:reply encoding:NSASCIIStringEncoding];
        long nlPos = [s rangeOfString:@"\n"].location;
        if(nlPos != NSNotFound){
            s = [s substringWithRange:NSMakeRange(0,nlPos)];
        }

		return s;
    }
    else {
        return @"Not Connected";
    }
}

-(void) resetAndClear
{
    if([self isConnected]){
        [self writeToGPIBDevice:@"*RST;*CLS"];
    }
}

- (void) systemTest
{
    if([self isConnected]){
		[self writeToGPIBDevice:@"*TST?"];
        if(verbose)NSLog(@"HP Pulser Test.\n");
    }
}

- (void) writeVoltageLow:(unsigned short)value
{
    [self writeToGPIBDevice:@"VOLT:UNIT VPP"];
    [self logSystemResponse];
    [self writeToGPIBDevice:[NSString stringWithFormat:@"VOLT:LOW %dE-3",value]];
    [self logSystemResponse];
    if(verbose)NSLog(@"HP Pulser Voltage LOW PP set to %d\n",value);
}

- (void) writeVoltageHigh:(unsigned short)value
{
    [self writeToGPIBDevice:@"VOLT:UNIT VPP"];
    [self logSystemResponse];
    [self writeToGPIBDevice:[NSString stringWithFormat:@"VOLT:HIGH %dE-3",value]];
    [self logSystemResponse];
    if(verbose)NSLog(@"HP Pulser Voltage LOW PP set to %d\n",value);
}

- (void) writeOutput:(BOOL)aState
{
    [self writeToGPIBDevice:[NSString stringWithFormat:@"OUTPUT %@",aState?@"ON":@"OFF"]];
    [self logSystemResponse];
    if(verbose)NSLog(@"HP Pulser Output %@\n",aState?@"ON":@"OFF");
}

- (void) writeSync:(BOOL)aState
{
    [self writeToGPIBDevice:[NSString stringWithFormat:@"OUTPUT:SYNC %@",aState?@"ON":@"OFF"]];
    [self logSystemResponse];
    if(verbose)NSLog(@"HP Pulser Sync %@\n",aState?@"ON":@"OFF");
}

- (void) writePulsePeriod:(float)aValue
{
    if(aValue<200E-9)aValue=200E-9;
    else if(aValue>2000)aValue = 2000;
    [self writeToGPIBDevice:[NSString stringWithFormat:@"PULSE:PERIOD %E",aValue]];
    [self logSystemResponse];
    if(verbose)NSLog(@"HP Pulser Pulse Period %E\n",aValue);
}

- (void) writePulseWidth:(float)aValue
{
    if(aValue<200E-9)aValue=200E-9;
    else if(aValue>2000)aValue = 2000;
    [self writeToGPIBDevice:[NSString stringWithFormat:@"FUNC:PULSE:WIDT %E",aValue]];
    [self logSystemResponse];
    if(verbose)NSLog(@"HP Pulser Pulse Width %E\n",aValue);
}

- (void) writePulseDutyCycle:(unsigned short)aValue
{
    if(aValue>100)aValue = 100;
    [self writeToGPIBDevice:[NSString stringWithFormat:@"FUNC:PULSE:DCYC %d",aValue]];
    [self logSystemResponse];
    if(verbose)NSLog(@"HP Pulser Pulse Duty Cycle %d\n",aValue);
}

- (void) writePulseEdgeTime:(float)aValue
{
    if(aValue<5E-9)aValue=5E-9;
    else if(aValue>100E-9)aValue = 100E-9;
    [self writeToGPIBDevice:[NSString stringWithFormat:@"FUNC:PULSE:TRAN %E",aValue]];
    [self logSystemResponse];
    if(verbose)NSLog(@"HP Pulser Pulse Edge Time %E\n",aValue);
}

- (void) writeVoltage:(unsigned short)value
{
    [self writeToGPIBDevice:@"VOLT:UNIT VPP"];
    [self logSystemResponse];
    [self writeToGPIBDevice:[NSString stringWithFormat:@"VOLT %dE-3",value]];
    [self logSystemResponse];
    if(verbose)NSLog(@"HP Pulser Voltage PP set to %dE-3\n",value);
}

- (void) writeVoltageOffset:(short)value
{
    [self writeToGPIBDevice:[NSString stringWithFormat:@"VOLT:OFFS %dE-3",value]];
	[self logSystemResponse];
	if(verbose)NSLog(@"HP Pulser Voltage Offset set to %dE-3\n",value);
}

- (void) writeFrequency:(float)value
{
    [self writeToGPIBDevice:[NSString stringWithFormat:@"FREQ %E",value]];
	[self logSystemResponse];
	if(verbose)NSLog(@"HP Pulser Frequency set to %E\n",value);
}

- (void) writeBurstRate:(float)value
{
    [self writeToGPIBDevice:[NSString stringWithFormat:@"BM:INT:RATE %f",value]];
    [self logSystemResponse];
    [self writeToGPIBDevice:@"BM:SOUR INT"];
    [self logSystemResponse];
    if(verbose)NSLog(@"HP Pulser Burst Rate set to %f\n",value);
}

- (void) writeBurstState:(BOOL)value
{
    if(value) [self writeToGPIBDevice:@"BM:STAT ON"];
    else	  [self writeToGPIBDevice:@"BM:STAT OFF"];
    [self logSystemResponse];
}

- (void) writeBurstCycles:(int)value
{
    [self writeToGPIBDevice:[NSString stringWithFormat:@"BM:NCYC %d",value]];
    [self logSystemResponse];
    if(verbose)NSLog(@"HP Pulser Burst Cycles set to %d\n",value);
}

- (void) writeBurstPhase:(int)value
{
    [self writeToGPIBDevice:[NSString stringWithFormat:@"BM:PHAS %d",value]];
    [self logSystemResponse];
    if(verbose)NSLog(@"HP Pulser Burst Phase set to %d\n",value);
}

- (void) writeTriggerSource:(int)value
{
    switch(value){
        case kInternalTrigger:
            [self writeToGPIBDevice:@"TRIG:SOUR IMM"];
			[self logSystemResponse];
           break;
        case kExternalTrigger:
            [self writeToGPIBDevice:@"TRIG:SOUR EXT"];
			[self logSystemResponse];
            break;
        case kSoftwareTrigger:
            [self writeToGPIBDevice:@"TRIG:SOUR BUS"];
			[self logSystemResponse];
            break;
        default:
            NSLog(@"ORHPPulserModel:writeTriggerSource - The selection %s, is not valid.  1 = Internal, 2 = External, 3 = Bus\n",value);
            break;
    }
}

/*
 - (void) writeTotalWidth:(float)width
 {
 
 //each Predefined pulse may have a different number of total points and non-zero points
 //thereby needing a different frequency in order to generate a similar pulse width
 float theFreq = 0;
 if(width !=0){
 //theFreq =  1/(width*1e-6);
 theFreq = [self calculateFreq:width*1e-6];
 //Note that since the Number of Bursts per cycle is hardcoded in SetBurstRate to be 1, theFreq
 //must be less than 1 MHz and greater than 10 mHz
 if(theFreq>10e-3 && theFreq<1e+6){
 [self writeToGPIBDevice:[NSString stringWithFormat:@"FREQ %10.4f",theFreq]];
 [self logSystemResponse];
 NSLog(@"HP Pulser Total Width set to %f (Freg: %f)\n",width,theFreq);
 }
 else {
 NSBeep();
 NSLog(@"Your Requested Pulse width requires a Frequency not between 10 mHz and 1 MHz (Pulser limitation)\n");
 }
 }
 else NSLog(@"HP Pulser: Can't set width to zero!\n");
 
 }*/

- (void) logSystemResponse
{
	return;   //stopped asking for response because of device time-outs and errors. MAH 12/18/09
    char reply[1024];
    long n = [self writeReadGPIBDevice:@"SYST:ERR?" data:reply maxLength:1024];
    if(n && [[NSString stringWithCString:reply encoding:NSASCIIStringEncoding] rangeOfString:@"No error"].location == NSNotFound){
        NSLog(@"%s\n",reply);
    }
}

- (void) downloadWaveform
{
    if([self isConnected]){
		if(loading){
			[self stopDownload];
			[self performSelector:@selector(startDownloadThread) withObject:nil afterDelay:3];
		}
		else [self startDownloadThread];
	}
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
    //get list of waveforms already in pulser
    char reply[1024];
    long n = [self writeReadGPIBDevice:@"Data:CAT?" data:reply maxLength:1024];
    if(n>0)reply[n-1]='\0';
    NSString* replyString = [[[NSString stringWithCString:reply encoding:NSASCIIStringEncoding] componentsSeparatedByString:@"\""] componentsJoinedByString:@""];
    replyString = [replyString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [replyString componentsSeparatedByString:@","];
}


- (void) emptyVolatileMemory
{
    @try {
        NSArray* allInMemory = [self getLoadedWaveforms];
        for(NSString* aName in allInMemory){
            if( ![self inBuiltInList:aName] && [self inCustomList:aName]){
                [self writeToGPIBDevice:[NSString stringWithFormat:@"*RST;*CLS;DATA:DEL %@",aName]];
            }
        }
        
	}
	@catch(NSException* localException) {
	}
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
        [self enableEOT:NO];
        [self writeToGPIBDevice:@"DATA VOLATILE,"];
        
        const float* ptr = (const float*)[waveform bytes];
        for(downloadIndex=0;downloadIndex<[self numPoints]-1;downloadIndex++){
            if(!loading)break;
			if (ptr[downloadIndex]==0) {
				[self writeToGPIBDevice:@"0.0001,"];
			} else {
				[self writeToGPIBDevice:[NSString stringWithFormat:@"%6.5f,",ptr[downloadIndex]]];
			}
            if(!(downloadIndex%10)){
				[self performSelectorOnMainThread:@selector(updateLoadProgress) withObject:nil waitUntilDone:NO];
            }
        }
        [self enableEOT:YES];
		if (ptr[downloadIndex]==0) {
			[self writeToGPIBDevice:@"0\n;*WAI"];
		} else {
			[self writeToGPIBDevice:[NSString stringWithFormat:@"%6.5f\n;*WAI",ptr[downloadIndex]]];
		}
        if(loading){
            [self logSystemResponse];
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
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ORHPPulserWaveformLoadProgressingNotification
	 object: self];
}

- (void) waveFormWasSent
{
	loading = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName: ORHPPulserWaveformLoadFinishedNotification object: self];
	[self writeTriggerSource:savedTriggerSource];
	NSLog(@"Waveform Download Complete\n");
}

- (void) stopDownload
{
    loading = NO;
    NSLog(@"Waveform Download Stopped\n");
}

- (void) loadFromNonVolativeMemory
{
    if([self isConnected]){
	if (waveformData[selectedWaveform].builtInFunction) {
        	[self writeToGPIBDevice:[NSString stringWithFormat:@"FUNC %@",waveformData[selectedWaveform].storageName]];
        	[self logSystemResponse];

	} else {
        	[self writeToGPIBDevice:[NSString stringWithFormat:@"FUNC:USER %@",waveformData[selectedWaveform].storageName]];
        	[self logSystemResponse];
        	[self writeToGPIBDevice:@"FUNC:SHAP USER"];
        	[self logSystemResponse];
	}
        [self outputWaveformParams];
    }
}

- (void) loadFromVolativeMemory
{
    if([self isConnected]){
        if(waveformData[selectedWaveform].tryToStore){
            @try {
                [self writeToGPIBDevice:[NSString stringWithFormat:@"DATA:COPY %@",waveformData[selectedWaveform].storageName]];
            }
			@catch(NSException* localException) {
			}
        }
		[self writeToGPIBDevice:@"FUNC:USER VOLATILE;*WAI"];
		[self logSystemResponse];
		[self writeToGPIBDevice:@"FUNC:SHAP USER;*WAI"];
		[self logSystemResponse];
		[self outputWaveformParams];
    }
}

- (void) outputWaveformParams
{
    if([self isConnected]){
        if(selectedWaveform == kLogCalibrationWaveform){
            [self writeVoltage:kCalibrationVoltage];
            [self writeBurstCycles:1];
            [self writeBurstRate:kCalibrationBurstRate];
			[self writeFrequency:[self frequency]];
        }
        else {
            [self writeVoltage:[self voltage]];
            [self writeVoltageOffset:[self voltageOffset]];
			[self writeFrequency:[self frequency]];
            [self writeBurstCycles:[self burstCycles]];
            [self writeBurstRate:[self burstRate]];
        }
        
        [self writeBurstPhase:[self burstPhase]];
        [self writeTriggerSource:[self triggerSource]];
        [self writeBurstState:YES];
        
    }
}


#pragma mark •••Helpers

- (float) calculateFreq:(float)width
{
	float theFreq = (float)(([self numPoints] - kPadSize)/(float)[self numPoints]) * 1/width;
	
	return theFreq;
}

- (void) buildWave
{
    if(selectedWaveform != kWaveformFromScript){
        [self setWaveform: [NSMutableData dataWithCapacity:[self maxNumberOfWaveformPoints] *sizeof(float)]];
    }
    
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
            
        case kWaveformFromScript:
            NSLog(@"Will load waveform from script\n");
            break;
        default:
            break;
            
    }
	    
    //count = [self numPoints];
    
}

#pragma mark •••Archival
static NSString* HPTriggerMode      = @"HPTriggerMode";
static NSString* HPVoltage          = @"HPVoltageFloat";
static NSString* HPVoltageOffset    = @"HPVoltageOffsetFloat";
static NSString* HPFrequency        = @"HPFrequency";
static NSString* HPBurstCycles      = @"HPBurstCycles";
static NSString* HPBurstRate 		= @"HPBurstRate";
static NSString* HPBurstPhase 		= @"HPBurstPhase";
//static NSString* HPTotalWidth 		= @"HPTotalWidth";
static NSString* HPSelectedWaveform  = @"HPSelectedWaveform";
static NSString* ORHPPulserEnableRandom = @"ORHPPulserEnableRandom";
static NSString* ORHPPulserMinTime = @"ORHPPulserMinTime";
static NSString* ORHPPulserMaxTime = @"ORHPPulserMaxTime";

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self setVerbose:[aDecoder decodeBoolForKey:@"verbose"]];
    [self setNegativePulse:[aDecoder decodeBoolForKey:@"ORHPPulserModelNegativePulse"]];
    [self loadMemento:aDecoder];
	
    [self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)anEncoder
{
    [super encodeWithCoder:anEncoder];
    [self saveMemento:anEncoder];
    
}
- (void)loadMemento:(NSCoder*)aDecoder
{
    [[self undoManager] disableUndoRegistration];
    [self setTriggerSource: [aDecoder decodeIntForKey: HPTriggerMode]];
    [self setVoltage: [aDecoder decodeFloatForKey: HPVoltage]];
    [self setVoltageOffset: [aDecoder decodeFloatForKey: HPVoltageOffset]];
    [self setFrequency: [aDecoder decodeFloatForKey: HPFrequency]];
    [self setBurstRate: [aDecoder decodeFloatForKey: HPBurstRate]];
    [self setBurstPhase: [aDecoder decodeIntForKey: HPBurstPhase]];
    [self setBurstCycles: [aDecoder decodeIntForKey: HPBurstCycles]];
	//    [self setTotalWidth: [aDecoder decodeFloatForKey: HPTotalWidth]];
    [self setSelectedWaveform: [aDecoder decodeIntForKey: HPSelectedWaveform]];
	[self setEnableRandom:[aDecoder decodeBoolForKey:ORHPPulserEnableRandom]];
	[self setMinTime:[aDecoder decodeFloatForKey:ORHPPulserMinTime]];
	[self setMaxTime:[aDecoder decodeFloatForKey:ORHPPulserMaxTime]];
    
    [[self undoManager] enableUndoRegistration];
}

- (void)saveMemento:(NSCoder*)anEncoder
{
    [anEncoder encodeBool:verbose forKey:@"verbose"];
    [anEncoder encodeBool:negativePulse forKey:@"ORHPPulserModelNegativePulse"];
    [anEncoder encodeInt: [self triggerSource] forKey: HPTriggerMode];
    [anEncoder encodeFloat: [self voltage] forKey: HPVoltage];
	[anEncoder encodeFloat: [self voltageOffset] forKey: HPVoltageOffset];
    [anEncoder encodeFloat: [self burstRate] forKey: HPBurstRate];
    [anEncoder encodeFloat: [self frequency] forKey: HPFrequency];
    [anEncoder encodeInt: [self burstCycles] forKey: HPBurstCycles];
    [anEncoder encodeInt: [self burstPhase] forKey: HPBurstPhase];
	//    [anEncoder encodeFloat: [self totalWidth] forKey: HPTotalWidth];
    [anEncoder encodeInt: [self selectedWaveform] forKey: HPSelectedWaveform];
	[anEncoder encodeBool:enableRandom forKey:ORHPPulserEnableRandom];
	[anEncoder encodeFloat:minTime forKey:ORHPPulserMinTime];
	[anEncoder encodeFloat:maxTime forKey:ORHPPulserMaxTime];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    
    [objDictionary setObject:[NSNumber numberWithInt:triggerSource] forKey:@"triggerMode"];
    [objDictionary setObject:[NSNumber numberWithFloat:voltage] forKey:@"voltage"];
    [objDictionary setObject:[NSNumber numberWithFloat:voltageOffset] forKey:@"voltageOffset"];
	[objDictionary setObject:[NSNumber numberWithFloat:frequency] forKey:@"frequency"];
    [objDictionary setObject:[NSNumber numberWithFloat:burstRate] forKey:@"burstRate"];
    [objDictionary setObject:[NSNumber numberWithInt:burstCycles] forKey:@"burstCycles"];
    [objDictionary setObject:[NSNumber numberWithInt:burstPhase] forKey:@"burstPhase"];
	//    [objDictionary setObject:[NSNumber numberWithFloat:totalWidth] forKey:@"totalWidth"];
    [objDictionary setObject:[NSNumber numberWithInt:selectedWaveform] forKey:@"selectedWaveform"];
    [objDictionary setObject:[NSNumber numberWithBool:enableRandom] forKey:@"enableRandom"];
    [objDictionary setObject:[NSNumber numberWithFloat:minTime] forKey:@"minTime"];
    [objDictionary setObject:[NSNumber numberWithFloat:maxTime] forKey:@"maxTime"];
    
    return objDictionary;
}


- (NSData*) memento
{
    NSMutableData* memento = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:memento];
    [self saveMemento:archiver];
    [archiver finishEncoding]; 
	[archiver release];
    return memento;
}

- (void) restoreFromMemento:(NSData*)aMemento
{
	if(aMemento){
		NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:aMemento];
		[self loadMemento:unarchiver];
		[unarchiver finishDecoding];
		[unarchiver release];
		[self outputWaveformParams];
		[self downloadWaveform];
	}
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORHPPulserDecoderForPulserSettings",      @"decoder",
								 [NSNumber numberWithLong:pulserDataId],     @"dataId",
								 [NSNumber numberWithBool:NO],               @"variable",
								 [NSNumber numberWithLong:5],                @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"PulserSettings"];
    return dataDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORHPPulserModel"];
    
    
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

@end


@implementation ORHPPulserModel (private)
- (void) firePulserRandom
{
	@try {
		[self trigger];
	}
	@catch(NSException* localException) {
	}
	
	[self setRandomCount:++randomCount];
	float deltaTime = random_range((int)(minTime*10),(int)(maxTime*10))/10000.;
	[self performSelector:@selector(firePulserRandom) withObject:nil afterDelay:deltaTime];
}

- (void) startDownloadThread
{
	downloadIndex = 0;
	loading = YES;
	[self buildWave];
	
	savedTriggerSource = triggerSource;
	[self writeTriggerSource:kSoftwareTrigger];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ORHPPulserWaveformLoadStartedNotification
	 object: self];
	if([self isWaveformInNonVolatileMemory]){
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: ORHPPulserWaveformLoadingNonVoltileNotification
		 object: self];
		[NSThread detachNewThreadSelector: @selector( copyWaveformWorker ) toTarget:self withObject: nil];
	}
	else {
		//not in volatile memory so spawn off a thread, since the load can take awhile
		[[NSNotificationCenter defaultCenter]
		 postNotificationName: ORHPPulserWaveformLoadingVoltileNotification
		 object: self];
		[NSThread detachNewThreadSelector: @selector( downloadWaveformWorker ) toTarget:self withObject: nil];
	}
}



@end

