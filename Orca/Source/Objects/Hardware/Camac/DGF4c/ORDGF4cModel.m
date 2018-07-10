//
//  ORDGF4cModel.m
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
#import "ORDGF4cModel.h"
#import "ORDataTypeAssigner.h"

#import "ORCamacControllerCard.h"
#import "ORCamacBusProtocol.h"
#import "ORPCICamacCommands.h"
#import "ORHWWizSelection.h"
#import "ORHWWizParam.h"
#import <math.h>
#import "xiaUtilities.h"

// definitions
NSString* ORDGF4cModelRunBehaviorMaskChanged		= @"ORDGF4cModelRunBehaviorMaskChanged";
NSString* ORDGF4cModelXwaitChanged                  = @"ORDGF4cModelXwaitChanged";
NSString* ORDGF4cModelRunTaskChanged				= @"ORDGF4cModelRunTaskChanged";
NSString* ORDGF4cModelTauChanged                    = @"ORDGF4cModelTauChanged";
NSString* ORDGF4cModelTauSigmaChanged               = @"ORDGF4cModelTauSigmaChanged";
NSString* ORDGF4cModelBinFactorChanged              = @"ORDGF4cModelBinFactorChanged";
NSString* ORDGF4cModelEMinChanged                   = @"ORDGF4cModelEMinChanged";
NSString* ORDGF4cModelPsaEndChanged                 = @"ORDGF4cModelPsaEndChanged";
NSString* ORDGF4cModelPsaStartChanged               = @"ORDGF4cModelPsaStartChanged";
NSString* ORDGF4cModelTraceDelayChanged             = @"ORDGF4cModelTraceDelayChanged";
NSString* ORDGF4cModelTraceLengthChanged            = @"ORDGF4cModelTraceLengthChanged";
NSString* ORDGF4cModelVOffsetChanged                = @"ORDGF4cModelVOffsetChanged";
NSString* ORDGF4cModelVGainChanged                  = @"ORDGF4cModelVGainChanged";
NSString* ORDGF4cModelTriggerThresholdChanged       = @"ORDGF4cModelTriggerThresholdChanged";
NSString* ORDGF4cModelTriggerFlatTopChanged         = @"ORDGF4cModelTriggerFlatTopChanged";
NSString* ORDGF4cModelTriggerRiseTimeChanged        = @"ORDGF4cModelTriggerRiseTimeChanged";
NSString* ORDGF4cModelEnergyFlatTopChanged          = @"ORDGF4cModelEnergyFlatTopChanged";
NSString* ORDGF4cModelEnergyRiseTimeChanged         = @"ORDGF4cModelEnergyRiseTimeChanged";
NSString* ORDFG4cFirmWarePathChangedNotification    = @"ORDFG4cFirmWarePathChangedNotification";
NSString* ORDFG4cDSPCodePathChangedNotification     = @"ORDFG4cDSPCodePathChangedNotification";
NSString* ORDFG4cParamChangedNotification           = @"ORDFG4cParamChangedNotification";
NSString* ORDFG4cDSPSettingsLock                    = @"ORDFG4cDSPSettingsLock";
NSString* ORDFG4cChannelChangedNotification         = @"ORDFG4cChannelChangedNotification";
NSString* ORDFG4cRevisionChangedNotification		= @"ORDFG4cRevisionChangedNotification";
NSString* kDGF4cParamNotFound                       = @"kDGF4cParamNotFound Exception";
NSString* ORDFG4cDecimationChangedNotification		= @"ORDFG4cDecimationChangedNotification";
NSString* ORDFG4cOscEnabledMaskChangedNotification	= @"ORDFG4cOscEnabledMaskChangedNotification";
NSString* ORDFG4cSampleWaveformChangedNotification	= @"ORDFG4cSampleWaveformChangedNotification";
NSString* ORDFG4cWaveformChangedNotification		= @"ORDFG4cWaveformChangedNotification";

enum {
	kSetDACs							= 0,
	kConnectInputs						= 1,
	kDisconnectInputs					= 2,
	kRampOffsetDAC						= 3,
	kUntriggeredTraces					= 4,
	kProgramFiPPI						= 5,
	kMeasureBaselines					= 6,
	kReadHistogramMemoryPage1			= 9,
	kReadHistogramMemoryNextPages		= 10,
	kWriteHistogramMemoryPage1			= 11,
	kWriteHistogramMemoryNextPages		= 12,
	kFirstADCCalibration				= 20,
	kNextAdcCalibration					= 21
};

enum {
	kRunEnableCSRBit		= 0x0001,
	kNewRunCSRBit			= 0x0002,
	kEnableLAMCSRBit		= 0x0008,
	kDSPResetCSRBit			= 0x0010,
	kDSPErrorCSRBit			= 0x1000,
	kActiveCSRBit			= 0x2000,
	kLAMStateCSRBit			= 0x4000
};


@interface ORDGF4cModel (private)
- (void) setComputableParams;
- (void) calcUserParams;
- (NSArray*) collectChanNames:(NSString*)nameString list:(NSMutableArray*)theLines;
- (unsigned short) getDSPParamAddress:(NSString*)aName;
- (void) generateLookUpTable;
- (void) constraintViolated:(NSString*)reasonString;
- (long) computeMaxEvents:(long) runType;
- (void) sampleWaveforms:(unsigned long*)recordPtr;
- (BOOL) multipleCardEnvironment;
- (void) updateOsc;
@end

@implementation ORDGF4cModel
#pragma mark ¥¥¥Initialization
- (id) init
{		
    self = [super init];
	oscLock = [[NSLock alloc] init];
	paramLoadLock = [[NSLock alloc] init];
    [self loadDefaults];
    return self;
}

- (void) dealloc
{
	[oscLock release];
	[paramLoadLock release];
    [firmWarePath release];
    [dspCodePath release];
    [params release];
    [lastParamPath release];
    [lastNewSetPath release];
    [lookUpTable release];
    [super dealloc];
}


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"DGF4cCard"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORDGF4cController"];
}

- (NSString*) helpURL
{
	return @"CAMAC/DGF4c.html";
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"DGF4c";
}

- (unsigned long) runBehaviorMask
{
    return runBehaviorMask;
}

- (void) setRunBehaviorMask:(unsigned long)aRunBehaviorMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunBehaviorMask:runBehaviorMask];
    
    runBehaviorMask = aRunBehaviorMask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelRunBehaviorMaskChanged object:self];
}

- (void) setSyncWait:(BOOL)state
{
	unsigned long theMask = runBehaviorMask;
	if(state)theMask |= 0x1;
	else theMask &= ~0x1;
	[self setRunBehaviorMask:theMask];
}

- (BOOL) syncWait
{
	return runBehaviorMask & 0x1;
}

- (void) setInSync:(BOOL)state
{
	unsigned long theMask = runBehaviorMask;
	if(state)theMask |= 0x2;
	else theMask &= ~0x2;
	[self setRunBehaviorMask:theMask];
}

- (BOOL) inSync
{
	return (runBehaviorMask & 0x2) >> 1;
}

- (unsigned short) xwait:(short)chan
{
    return xwait[chan];
}

- (void) setXwait:(short)chan withValue:(unsigned short)aXwait
{
    [[[self undoManager] prepareWithInvocationTarget:self] setXwait:chan withValue:xwait[chan]];
    
    xwait[chan] = aXwait;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelXwaitChanged object:self];
}

- (BOOL) sampleWaveforms
{
	return sampleWaveforms;
}

- (void) setSampleWaveforms:(BOOL)state
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleWaveforms:sampleWaveforms];
    
    sampleWaveforms = state;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDFG4cSampleWaveformChangedNotification object:self];
}

- (unsigned short) runTask
{
    return runTask;
}

- (void) setRunTask:(unsigned short)aRunTask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunTask:runTask];
    
    runTask = aRunTask;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelRunTaskChanged object:self];
}

- (double) tau:(short)chan
{
    return tau[chan];
}

- (void) setTau:(short)chan withValue:(double)aTau
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTau:chan withValue:tau[chan]];
    
    tau[chan] = aTau;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelTauChanged object:self];
}

- (double) tauSigma:(short)chan
{
    return tauSigma[chan];
}

- (void) setTauSigma:(short)chan withValue:(double)aTauSigma
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTauSigma:chan withValue:tauSigma[chan]];
    
    tauSigma[chan] = aTauSigma;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelTauSigmaChanged object:self];
}


- (unsigned short) binFactor:(short)chan
{
    return binFactor[chan];
}

- (void) setBinFactor:(short)chan withValue:(unsigned short)aBinFactor
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBinFactor:chan withValue:binFactor[chan]];
    
    if(aBinFactor < 1)       aBinFactor = 1;
    else if(aBinFactor > 6)  aBinFactor = 6;
	
    binFactor[chan] = aBinFactor;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelBinFactorChanged object:self];
}

- (unsigned short) eMin:(short)chan
{
    return eMin[chan];
}

- (void) setEMin:(short)chan withValue:(unsigned short)aEMin
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEMin:chan withValue:eMin[chan]];
    
    if(aEMin > 32768)  aEMin = 32768;
    
    eMin[chan] = aEMin;
	
	//compute the value that will be written to HW.
    [self setParam:@"ENERGYLOW" value:eMin[chan] channel:chan];
	
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelEMinChanged object:self];
}

- (float) psaEnd:(short)chan
{
    return psaEnd[chan];
}

- (void) setPsaEnd:(short)chan withValue:(float)aPsaEnd
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPsaEnd:chan withValue:psaEnd[chan]];
    
    if(aPsaEnd > 100)aPsaEnd = 100;
    
    psaEnd[chan] = aPsaEnd;
	
	//compute the value that will be written to HW.
    [self setParam:@"PSALENGTH" value: psaEnd[chan]-psaStart[chan] channel:chan];
	
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelPsaEndChanged object:self];
}

- (float) psaStart:(short)chan
{
    return psaStart[chan];
}

- (void) setPsaStart:(short)chan withValue:(float)aPsaStart
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPsaStart:chan withValue:psaStart[chan]];
    
    if(aPsaStart > 100)aPsaStart = 100;
	
    psaStart[chan] = aPsaStart;
	
	//compute the value that will be written to HW.
    [self setParam:@"PSAOFFSET" value: psaStart[chan] channel:chan];
	
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelPsaStartChanged object:self];
}

- (float) traceDelay:(short)chan
{
    return traceDelay[chan];
}

- (void) setTraceDelay:(short)chan withValue:(float)aTraceDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTraceDelay:chan withValue:traceDelay[chan]];
    
    if(aTraceDelay > 4096)  aTraceDelay = 4096;
	
    traceDelay[chan] = aTraceDelay;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelTraceDelayChanged object:self];
}

- (float) traceLength:(short)chan
{
    return traceLength[chan];
}

- (void) setTraceLength:(short)chan withValue:(unsigned short)aTraceLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTraceLength:chan withValue:traceLength[chan]];
    
    if(aTraceLength > 4096)  aTraceLength = 4096;
	
    traceLength[chan] = aTraceLength;
	
    [self setParam:@"TRACELENGTH" value: traceLength[chan] channel:chan];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelTraceLengthChanged object:self];
}

- (float) vOffset:(short)chan
{
    return vOffset[chan];
}

- (void) setVOffset:(short)chan withValue:(float)aVOffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVOffset:chan withValue:vOffset[chan]];
    
    if(aVOffset < -3)       aVOffset = -3;
    else if(aVOffset > 3)  aVOffset = 3;
	
    vOffset[chan] = aVOffset;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelVOffsetChanged object:self];
}

- (float) vGain:(short)chan
{
    return vGain[chan];
}

- (void) setVGain:(short)chan withValue:(float)aVGain
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVGain:chan withValue:vGain[chan]];
    
    if(aVGain < 0)        aVGain = 0;
    else if(aVGain > 16)  aVGain = 16;
	
    vGain[chan] = aVGain;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelVGainChanged object:self];
}

- (float) triggerThreshold:(short)chan
{
    return triggerThreshold[chan];
}

- (void) setTriggerThreshold:(short)chan withValue:(float)aTriggerThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerThreshold:chan withValue:triggerThreshold[chan]];
    
	float fastLength = [self paramValue:@"FASTLENGTH"];
	float upperLimit = 4095;
	if(fastLength)upperLimit = 4095./(float)[self paramValue:@"FASTLENGTH"];
	if(aTriggerThreshold < 0)          aTriggerThreshold = 0;
	else if(aTriggerThreshold > upperLimit)  aTriggerThreshold = upperLimit;
	
    triggerThreshold[chan] = aTriggerThreshold;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelTriggerThresholdChanged object:self];
}

- (float) triggerFlatTop:(short)chan
{
    return triggerFlatTop[chan];
}

- (void) setTriggerFlatTop:(short)chan withValue:(float)aTriggerFlatTop
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerFlatTop:chan withValue:triggerFlatTop[chan]];
    
    if(aTriggerFlatTop < 0)          aTriggerFlatTop = 0;
    else if(aTriggerFlatTop > 0.75)  aTriggerFlatTop = 0.75;
	
    triggerFlatTop[chan] = aTriggerFlatTop;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelTriggerFlatTopChanged object:self];
}

- (float) triggerRiseTime:(short)chan
{
    return triggerRiseTime[chan];
}

- (void) setTriggerRiseTime:(short)chan withValue:(float)aTriggerRiseTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerRiseTime:chan withValue:triggerRiseTime[chan]];
    
    if(aTriggerRiseTime < 0.025)      aTriggerRiseTime = 0.025;
    else if(aTriggerRiseTime > 0.775) aTriggerRiseTime = 0.775;
	
    triggerRiseTime[chan] = aTriggerRiseTime;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelTriggerRiseTimeChanged object:self];
}

- (float) energyFlatTop:(short)chan
{
    return energyFlatTop[chan];
}

- (void) setEnergyFlatTop:(short)chan withValue:(float)aEnergyFlatTop
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyFlatTop:chan withValue:energyFlatTop[chan]];
    
    energyFlatTop[chan] = aEnergyFlatTop;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelEnergyFlatTopChanged object:self];
}

- (float) energyRiseTime:(short)chan
{
    return energyRiseTime[chan];
}

- (void) setEnergyRiseTime:(short)chan withValue:(float)aEnergyRiseTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnergyRiseTime:chan withValue:energyRiseTime[chan]];
    
	
    energyRiseTime[chan] = aEnergyRiseTime;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDGF4cModelEnergyRiseTimeChanged object:self];
}

- (unsigned short) oscEnabledMask
{
	return oscEnabledMask;
}

- (void) setOscEnabledMask:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOscEnabledMask:oscEnabledMask];
    
    oscEnabledMask = aMask;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDFG4cOscEnabledMaskChangedNotification
	 object:self];
	
}

- (void) setOscChanEnabledBit:(short)aBit withValue:(BOOL)aValue
{
	unsigned short aMask = oscEnabledMask;
	if(aValue) aMask |= 1<<aBit;
	else       aMask &= ~(1<<aBit);
	[self setOscEnabledMask:aMask];
}

- (short) decimation
{
    return decimation;
}

- (void) setDecimation:(short)aDecimation
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDecimation:decimation];
    
	if(aDecimation<=0)     aDecimation = 1;
	else if(aDecimation>6) aDecimation = 6;
	
    decimation = aDecimation;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDFG4cDecimationChangedNotification
	 object:self];
    
}

- (unsigned long) dataId 
{ 
    return dataId; 
}

- (void) setDataId: (unsigned long) aDataId
{
    dataId = aDataId;
}

- (unsigned long) liveTimeId 
{ 
    return liveTimeId; 
}

- (void) setLiveTimeId: (unsigned long) aDataId
{
    liveTimeId = aDataId;
}

- (unsigned long) mcaDataId 
{ 
    return mcaDataId; 
}

- (void) setMcaDataId: (unsigned long) aDataId
{
    mcaDataId = aDataId;
}


- (short) revision
{
	return revision;
}
- (void) setRevision:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRevision:revision];
	revision = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDFG4cRevisionChangedNotification
	 object:self];
}

- (NSMutableDictionary *)lookUpTable
{
    return [[lookUpTable retain] autorelease]; 
}
- (void)setLookUpTable:(NSMutableDictionary *)aLookUpTable
{
    [aLookUpTable retain];
    [lookUpTable release];
    lookUpTable = aLookUpTable;
    
}

- (short)channel
{
    return channel;
}
- (void)setChannel:(short)aChannel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setChannel:channel];
    channel = aChannel;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDFG4cChannelChangedNotification
	 object:self];
}

- (NSString *) firmWarePath
{
    return firmWarePath; 
}

- (void) setFirmWarePath: (NSString *) aFirmWarePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFirmWarePath:firmWarePath];
	
    [firmWarePath autorelease];
    firmWarePath = [aFirmWarePath copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDFG4cFirmWarePathChangedNotification
	 object:self];
}

- (NSString *) dspCodePath
{
    return dspCodePath; 
}

- (void) setDSPCodePath: (NSString *) aDSPCodePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDSPCodePath:aDSPCodePath];
    
    [dspCodePath autorelease];
    dspCodePath = [aDSPCodePath copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDFG4cDSPCodePathChangedNotification
	 object:self];
}


- (NSMutableDictionary *) params
{
    return params; 
}

- (void) setParams: (NSMutableDictionary *) aParams
{
    [aParams retain];
    [params release];
    params = aParams;
	
    [self generateLookUpTable];
}

- (NSString *) lastParamPath
{
    return lastParamPath; 
}

- (void) setLastParamPath: (NSString *) aLastParamPath
{
    [lastParamPath release];
    lastParamPath = [aLastParamPath copy];
}

- (NSString *)lastNewSetPath
{
    return [[lastNewSetPath retain] autorelease]; 
}
- (void)setLastNewSetPath:(NSString *)aLastNewSetPath
{
    if (lastNewSetPath != aLastNewSetPath) {
        [lastNewSetPath release];
        lastNewSetPath = [aLastNewSetPath copy];
    }
}

- (unsigned short) paramValue:(NSString*)aParamName channel:(int)aChannel
{
    id array  = [[lookUpTable objectForKey:aParamName] objectForKey:@"array"];
    int index = [[[lookUpTable objectForKey:aParamName] objectForKey:@"index"] intValue];
    return [[[array objectAtIndex:index] objectForKey:[NSString stringWithFormat:@"value%d",aChannel]] intValue];
}

- (void) setParam:(NSString*)aParamName value:(unsigned short)aValue channel:(int)aChannel
{
    id array  = [[lookUpTable objectForKey:aParamName] objectForKey:@"array"];
    int index = [[[lookUpTable objectForKey:aParamName] objectForKey:@"index"] intValue];
    unsigned short currentValue = [[[array objectAtIndex:index] objectForKey:[NSString stringWithFormat:@"value%d",aChannel]] intValue];
    [[[self undoManager] prepareWithInvocationTarget:self] setParam:aParamName value:currentValue channel:aChannel];
    
    [[array objectAtIndex:index] setObject:[NSNumber numberWithUnsignedShort:aValue] forKey:[NSString stringWithFormat:@"value%d",aChannel]];
    
    [[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORDFG4cParamChangedNotification
	 object:self
	 userInfo: [NSDictionary dictionaryWithObject:aParamName forKey:@"ParamName"]];
}

- (unsigned short) paramValue:(NSString*)aParamName
{
    id array  = [[lookUpTable objectForKey:aParamName] objectForKey:@"array"];
    int index = [[[lookUpTable objectForKey:aParamName] objectForKey:@"index"] intValue];
    return [[[array objectAtIndex:index] objectForKey:@"value"] intValue];
}

- (void) setParam:(NSString*)aParamName value:(unsigned short)aValue
{
    id array  = [[lookUpTable objectForKey:aParamName] objectForKey:@"array"];
    int index = [[[lookUpTable objectForKey:aParamName] objectForKey:@"index"] intValue];
    unsigned short currentValue = [[[array objectAtIndex:index] objectForKey:@"value"] intValue];
    [[[self undoManager] prepareWithInvocationTarget:self] setParam:aParamName value:currentValue];
    
    [[array objectAtIndex:index] setObject:[NSNumber numberWithUnsignedShort:aValue] forKey:@"value"];
    
    [[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORDFG4cParamChangedNotification
	 object:self
	 userInfo: [NSDictionary dictionaryWithObject:aParamName forKey:@"ParamName"]];
}

- (void) set:(NSString*)arrayName index:(NSUInteger)index toObject:(id)anObject forKey:(NSString*)aKey
{
    id array = [params objectForKey:arrayName];
    if([array count] && index<[array count]){
        id item = [array objectAtIndex:index];
        id currentValue = [item objectForKey:aKey];
        [[[self undoManager] prepareWithInvocationTarget:self] set:arrayName index:index toObject:currentValue forKey:aKey];
        [item setObject:anObject forKey:aKey];
        
        [[NSNotificationCenter defaultCenter] 
		 postNotificationName:ORDFG4cParamChangedNotification
		 object:self
		 userInfo: [NSDictionary dictionaryWithObjectsAndKeys: 
					arrayName, @"ArrayName",
					[NSNumber numberWithInt:index], @"ArrayIndex",
					[item objectForKey:@"name"], @"ParamName",
					nil]];
        
    }
}

- (id) param:(NSString*)arrayName index:(NSUInteger)index forKey:(NSString*)aKey
{
    id array = [params objectForKey:arrayName];
    if([array count] && index<[array count]){
        id item = [array objectAtIndex:index];
        return [item objectForKey:aKey];
    }
    else return @"";
}


- (NSUInteger) countForArray:(NSString*)arrayName;
{
    return [[params objectForKey:arrayName] count];
    
}


#pragma mark ¥¥¥Hardware Access
- (void) executeTask:(int)aTask
{
	[self setParam:@"RUNTASK" to:0];
	[self setParam:@"CONTROLTASK" to:aTask];
    
	[self setCSRBit:kRunEnableCSRBit];
	[self waitForNotActive:5 reason:[NSString stringWithFormat:@"Control Task %d Timeout",aTask]];
	[self setParam:@"RUNTASK" to:runTask]; //set it back
}

- (void) setCSRBit:(unsigned short)bitMask
{
	[self writeCSR:[self readCSR] | bitMask];		//write it back with the first bit set
}

- (void) clearCSRBit:(unsigned short)bitMask
{
	[self writeCSR:[self readCSR] & ~bitMask];		//write it back with the first bit set
}

- (void) waitForNotActive:(NSTimeInterval)seconds reason:(NSString*)aReason 
{
	NSTimeInterval t0 = [NSDate timeIntervalSinceReferenceDate];
	while ([self readCSR] & kActiveCSRBit) {
		if([NSDate timeIntervalSinceReferenceDate]-t0 > seconds){
			[[NSException exceptionWithName:@"DGF4cParamLoadTimeOut" reason:aReason userInfo:nil] raise];
		}
	}
}

- (unsigned short) readCSR
{
	unsigned short data;
	[[self adapter] camacShortNAF:[self stationNumber] a:0 f:1 data:&data];
	return data;
}

- (void) writeCSR:(unsigned short)aValue
{
	[[self adapter] camacShortNAF:[self stationNumber] a:0 f:17 data:&aValue];
}

- (void) writeICSR:(unsigned short)aValue
{
	[[self adapter] camacShortNAF:[self stationNumber] a:8 f:17 data:&aValue];
}

- (void) writeTSAR:(unsigned short)aValue
{
	[[self adapter] camacShortNAF:[self stationNumber] a:1 f:17 data:&aValue];
}

- (void) loadSystemFPGA:(NSString*)filePath
{
	controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
	@try {
		[controller lock];
		[self writeICSR:0x01];	//prepare to configure the system FPGA
		[ORTimer delay:0.060];	//must delay abit
		
		NSLog(@"Begining DFG4c (station %d) System Configuration\n",[self stationNumber]);
		NSData* fpgaData = [NSData dataWithContentsOfFile:filePath];
		int len = [fpgaData length];
		if(fpgaData){
			int i;
			const unsigned char* dataPtr = (unsigned char*)[fpgaData bytes];
			for(i=0;i<len;i++){
				unsigned short data = (dataPtr[i]&0x00ff);
				[controller camacShortNAF:[self stationNumber] a:10 f:17 data:&data];
			}
			NSLog(@"Loaded: <%@>\n",[filePath stringByAbbreviatingWithTildeInPath]);
			
		}
		else NSLogColor([NSColor redColor],@"Unable to open: <%@>\n",[filePath stringByAbbreviatingWithTildeInPath]);
		[controller unlock];
	}
	@catch(NSException* localException) {
		[controller unlock];
		[localException raise];
	}
}

- (BOOL) loadFilterTriggerFPGAs:(NSString*)filePath
{
	[self writeICSR:0xF0];	//configure the Trigger/Filter FPGA
	[ORTimer delay:0.060];	//delay at least 50ms
    
	NSData* fpgaData        = [NSData dataWithContentsOfFile:filePath];
	unsigned long len		= [fpgaData length];
	controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
	if(fpgaData){
		int i;
		const unsigned char* dataPtr = (unsigned char*)[fpgaData bytes];
		@try {
			[controller lock];
			for(i=0;i<len;i++){
				unsigned short data = (dataPtr[i]&0x00ff);
				[controller camacShortNAF:[self stationNumber] a:9 f:17 data:&data];
			}
			[controller unlock];
		}
		@catch(NSException* localException) {
			[controller unlock];
			[localException raise];
		}
		
		NSLog(@"Loaded: <%@>\n",[filePath stringByAbbreviatingWithTildeInPath]);
		return YES;
	}
	else {
		NSLogColor([NSColor redColor],@"Unable to open: <%@>\n",[filePath stringByAbbreviatingWithTildeInPath]);
		return NO;
	}
}

- (void) loadSystemFPGA
{
    if(!firmWarePath)return; //should throw or post alarm here.
    
	[[self undoManager] disableUndoRegistration];
	controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
	@try {
		[controller lock];
		unsigned short data;
		
		//load the configuration data
		NSString* rootName = [NSString stringWithCString:kBaseFirmwareFileName encoding:NSASCIIStringEncoding];
		NSString* filePath  = [NSString stringWithFormat:@"%@/%@.bin",firmWarePath, rootName];
		
		[self loadSystemFPGA:filePath];
        
		//get the revision 
		[controller camacShortNAF:[self stationNumber] a:13 f:1 data:&data];
		char boardRevision = 'A' + (data & 0xf); //lowest nibble has the version, i.e. D=3,E=4.
		NSLog(@"Version: <%c>\n",boardRevision);
		[self setRevision:(data & 0xf)];
		
		
		filePath		= [NSString stringWithFormat:@"%@/f%@%d%c.bin",firmWarePath,rootName,decimation,'A'+revision];
		BOOL loadedOK = [self loadFilterTriggerFPGAs:filePath];
        
		//confirm the downloads
		data = 0;
		[controller camacShortNAF:[self stationNumber] a:8 f:1 data:&data];
		if(data == 0 && loadedOK)NSLog(@"downloads successful\n");
		else {
			NSLogColor([NSColor redColor],@"downloads FAILED\n");
			if(data & 0x1)NSLogColor([NSColor redColor],@"System FPGA not configured\n");
			int i;
			for(i=0;i<4;i++){
				if(data & (0x10<<i))NSLogColor([NSColor redColor],@"Trigger/Filter FPGA for chan %d not configured\n",i);
			}
		}
		if(revision >= 3) { //revision 'D' or 'E'
			//set the switch bus
			[self writeICSR:0x2400];
			[ORTimer delay:0.060];
		}
		[[self undoManager] enableUndoRegistration];
		[controller unlock];
		
	}
	@catch(NSException* localException) {
		[controller unlock];
		[[self undoManager] enableUndoRegistration];
		[localException raise];
	}
}

- (unsigned long) readDSPProgramWord
{
	unsigned short dataWord[2];
	[controller camacShortNAF:[self stationNumber] a:0 f:0 data:&dataWord[0]];
	[controller camacShortNAF:[self stationNumber] a:0 f:0 data:&dataWord[1]];
    
	return dataWord[0]<<8 | (dataWord[1]&0x00ff);
}

- (void) writeDSPProgramWord:(unsigned long)data
{
	//data is in PC format. so swap it. The next problem is that the DSP program memory
	//is 24 bit. So load the higher 16 bits first, followed by a second write for the rest 
	//of the 24 bit word.
	unsigned long d = Swap8Bits(data);
	unsigned short dataWordHigh = (d & 0x00ffff00)>>8;
	unsigned short dataWordLow = d & 0x0000ff;
	
	[controller camacShortNAF:[self stationNumber] a:0 f:16 data:&dataWordHigh];
	[controller camacShortNAF:[self stationNumber] a:0 f:16 data:&dataWordLow];
}

- (void) bootDSP
{
	//This pretty much just follows the algorithm in the programmers guide, the only exception being 
	//the read-back and comparision of the DSP memory before starting the DSP.
    
    if(!dspCodePath)return; //should throw or post alarm here.
	
    controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
    @try {
		[controller lock];
		
        [self writeCSR:kDSPResetCSRBit];
        [ORTimer delay:0.060];
        
        [self writeTSAR:0x01];	//set the TSAR to the SECOND address--the first word must be loaded last
        [ORTimer delay:0.060];
        
        NSLog(@"Begining DFG4c (station %d) DSP load/boot\n",[self stationNumber]);
        NSData* fpgaData = [NSData dataWithContentsOfFile:dspCodePath];
        int len = [fpgaData length]/4;
        if(fpgaData && len){
            int i;
            const unsigned long* dataPtr = (unsigned long*)[fpgaData bytes];
            //load the DSP--note the first word is skipped, it must be loaded last
            for(i=1;i<len;i++){
                [self writeDSPProgramWord:dataPtr[i]];
            }
            
            //reset the TSAR for a read back comparision
            [self writeTSAR:0x01];
            [ORTimer delay:0.060];
            
            //check the values........
            long errorCount = 0;
            for(i=1;i<len;i++){
                if([self readDSPProgramWord] != Swap8Bits(dataPtr[i])){
                    errorCount++;
                }
            }
            //.......................
            
            [self writeTSAR:0x00];					//reset the TSAR to the first DSP address
            [self writeDSPProgramWord:dataPtr[0]]; //writing the first word starts the DSP
            
            NSLog(@"Loaded: <%@>\n",[dspCodePath stringByAbbreviatingWithTildeInPath]);
            NSLog(@"Readback of DSP memory shows %d errors\n",errorCount);
        }
        else  NSLog(@"**Unable to open <%@>\n",dspCodePath);
        [controller unlock];
    }
	@catch(NSException* localException) {
        [controller unlock];
        [localException raise];
    }
}

- (void) fullInit
{
	[self loadSystemFPGA];
	[self bootDSP];
	[self loadParamsWithReadBack:YES];
	[self executeTask:kConnectInputs];
}


- (void) loadParams
{
	[self loadParamsWithReadBack:NO];
}

- (void) loadParamsWithReadBack:(BOOL)readBack
{
	if(okToLoadWhileRunning && [gOrcaGlobals runInProgress])[paramLoadLock lock];
	
    [self setComputableParams];
	long errorCount = 0;
	controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
	
	@try { 
		unsigned short data;
		
		//stop the DSP runtask.
		[self clearCSRBit:kRunEnableCSRBit];
		[self waitForNotActive:5 reason:@"Run Task Stop Timed Out"];
		
		unsigned short address;
		int i;
		NSArray* paramArray;
		NSDictionary* paramDict;
		unsigned short value;
		
		//first the DSP Chan Params
		paramArray = [params objectForKey:@"DSPChanParams"];
		int n = [paramArray count];
		for(i=0;i<n;i++){
			paramDict = [paramArray objectAtIndex:i];
			int chan;
			for(chan=0;chan<4;chan++){
				address = [[paramDict objectForKey:[NSString stringWithFormat:@"address%d",chan]] intValue];
				//only the first 256 words are writable
				if(address<256){
					//load the address into the TSAR
					address += kDataStartAddress; //offset to the start of data address
					[self writeTSAR:address];
					
					//load the value
					unsigned short value = [[paramDict objectForKey:[NSString stringWithFormat:@"value%d",chan]] intValue];
					[controller camacShortNAF:[self stationNumber] a:0 f:16 data:&value];
					
					if(readBack){
						//read check
						[self writeTSAR:address];
						unsigned short outValue;
						[controller camacShortNAF:[self stationNumber] a:0 f:0 data:&outValue];
						if(outValue!=value) {
							NSLogColor([NSColor redColor],@"%@ chan: %d <%d != %d>\n",[paramDict objectForKey:@"name"],chan,value,outValue);
							NSLogError(@"",@"DFG4c Card Error",@"Param Write/Read Error",nil);
							errorCount++;
						}
					}
				}
			}
		}
		
		//next the DSP Params
		
		paramArray = [params objectForKey:@"DSPParams"];
		n = [paramArray count];
		for(i=0;i<n;i++){
			paramDict = [paramArray objectAtIndex:i];
			address  = [[paramDict objectForKey:@"address"] intValue];
			//only the first 256 words are writable
			if(address<256){
				//load the address into the TSAR
				address += kDataStartAddress; //offset to the start of data address
				[self writeTSAR:address];
				
				//load the value
				value = [[paramDict objectForKey:@"value"] intValue];
				[controller camacShortNAF:[self stationNumber] a:0 f:16 data:&value];
                
				if(readBack){
					//read it back and check it.
					[self writeTSAR:address];
					unsigned short outValue;
					[controller camacShortNAF:[self stationNumber] a:0 f:0 data:&outValue];
					if(outValue!=value) {
						NSLogColor([NSColor redColor],@"%@  %d <%d != %d>\n",[paramDict objectForKey:@"name"],value,outValue);
						NSLogError(@"",@"DFG4c Card Error",@"Param Write/Read Error",nil);
						errorCount++;
					}
				}
			}
		}
		
		if(revision == 2) { //revision 'D' only
			address = [self getDSPParamAddress:@"AOUTBUFFER"];
			int i,n=256;
			data = 0;
			for(i=0;i<n;i++){
				[self writeTSAR:address];
				[controller camacShortNAF:[self stationNumber] a:0 f:16 data:&data];
				address++;
                
			}
		}
		
 		[self executeTask:kSetDACs];
		[self executeTask:kProgramFiPPI];
		
		if(readBack){
			if(errorCount){
				NSLogColor([NSColor redColor],@"Loaded DGF4c parameter set. Read back comparision showed %d error%@\n",errorCount,errorCount>1?@"s.":@" ");
			}
			else {
				NSLog(@"Loaded DGF4c parameter set. Read back comparision matches.\n");
			}
		}
	}
	@catch(NSException* localException) {
		NSLogColor([NSColor redColor], @"%@\n",localException);
		NSLogError(@"",@"DFG4c Card Error",localException,nil);
	}
	
	if(okToLoadWhileRunning && [gOrcaGlobals runInProgress]){
		[self writeCSR:csrValueForResuming];
		[paramLoadLock unlock];
	}
}

- (void) setParam:(NSString*)paramName to:(unsigned short)aValue
{
    @try {
        unsigned short address = [self getDSPParamAddress:paramName];
		[self writeTSAR:address];
        [[self adapter] camacShortNAF:[self stationNumber] a:0 f:16 data:&aValue];
    }
	@catch(NSException* localException) {
        NSLog(@"ORDFG4cModel unable to find address for '%@' parameter\n",paramName);
    }
}

- (short) readParam:(NSString*)paramName
{
	unsigned short aValue;
    @try {
        unsigned short address = [self getDSPParamAddress:paramName];
		[self writeTSAR:address];
        [[self adapter] camacShortNAF:[self stationNumber] a:0 f:0 data:&aValue];
    }
	@catch(NSException* localException) {
        NSLog(@"ORDFG4cModel unable to find address for '%@' parameter\n",paramName);
    }
	return aValue;
}

- (void) readParams
{
    [[self undoManager] disableUndoRegistration];
	@try { 
		controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
        
		unsigned short address;
		int i;
		NSArray* paramArray;
		NSDictionary* paramDict;
		
		//first the DSP Chan Params
		paramArray = [params objectForKey:@"DSPChanParams"];
		int n = [paramArray count];
		for(i=0;i<n;i++){
			paramDict = [paramArray objectAtIndex:i];
			int chan;
			for(chan=0;chan<4;chan++){
				address = [[paramDict objectForKey:[NSString stringWithFormat:@"address%d",chan]] intValue];
				if(address >= 256){
					//load the address into the TSAR
					address += kDataStartAddress; //offset to the start of data address	
					[self writeTSAR:address];
					unsigned short outValue;
					[controller camacShortNAF:[self stationNumber] a:0 f:0 data:&outValue];
					[self setParam:[paramDict objectForKey:@"name"] value:outValue channel:chan];
				}
			}
		}
		
		//next the DSP Params
		
		paramArray = [params objectForKey:@"DSPParams"];
		n = [paramArray count];
		for(i=0;i<n;i++){
			paramDict = [paramArray objectAtIndex:i];
			address  = [[paramDict objectForKey:@"address"] intValue];
			if(address >= 256){
				//load the address into the TSAR
				address += kDataStartAddress; //offset to the start of data address
				[self writeTSAR:address];
				unsigned short outValue;
				[controller camacShortNAF:[self stationNumber] a:0 f:0 data:&outValue];
				[self setParam:[paramDict objectForKey:@"name"] value:outValue];
			}
		}
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"DFG4c Card Error",localException,nil);
	}	
	[[self undoManager] enableUndoRegistration];
}

- (void) sampleChannel:(short)aChannel
{
	if(oscEnabledMask & (1<<aChannel)){
        
		[self setParam:@"HOSTIO" to:aChannel];
		[self executeTask:kUntriggeredTraces];
        
		linearDataBufferStart	= [self readParam:@"AOUTBUFFER"];
		linearDataBufferSize	= [self readParam:@"LOUTBUFFER"];
        
		unsigned short n = MIN(kLinearBufferSize,linearDataBufferSize);
        //------------------------------------------------------------
        //  ---for testing.... write a some data to the data buffer
        //	[self writeTSAR:linearDataBufferStart];
        //	[ORTimer delay:0.060];	//must delay abit
        //	unsigned short test = 0;
        //	for(i=0;i<n;i++){
        //		[[[self adapter] controller] camacShortNAF:[self stationNumber] a:0 f:16 data:&test];
        //		test++;
        //	}
        //------------------------------------------------------------
		
		[self writeTSAR:linearDataBufferStart];
		[ORTimer delay:0.060];	//must delay abit
		[oscLock lock];
        int i;
		for(i=0;i<n;i++){
			unsigned short data;
			[[self adapter] camacShortNAF:[self stationNumber] a:0 f:0 data:&data];
			oscModeData[aChannel][i] = data;
		}
		numOscPoints = n;
		[oscLock unlock];
	}
}

- (void) runBaselineCuts
{
	int i;
	for(i=0;i<4;i++){
		[self runBaselineCut:i];
	}
}

- (void) runTauFinder:(short)chan
{
	double tauRaw;
	double sigmaTauRaw;
	double avgtau;
	double tauvalues[kNumRepeatedTauRuns];
	
	tauRaw=tau[chan]*1.0e-6;
	
	int j=0;
	int i;
	double sumtau=0.0;
	for(i=0; i<kNumRepeatedTauRuns; i++){  /* Repeated Tau Runs */
		tauRaw=[self tauFinder:tauRaw channel:chan];
		if(tauRaw>0){
			tauvalues[j]=tauRaw;
			j++;
			sumtau += tauRaw;
		}
	}
	
	avgtau=sumtau/j;  /* Average tau value */
	
	sumtau=0.0;
	for(i=0; i<j; i++){  /* To derive the sigma of tau value */
		sumtau += pow((tauvalues[i]-avgtau), 2.0);
	}
	
	sigmaTauRaw=sqrt(sumtau)/j;
	if(avgtau>0){
		[self setTau:chan withValue:avgtau/1.0e-6];
		[self setTauSigma:chan withValue:sigmaTauRaw/1.0e-6];
		NSLog(@"dgf4c station %d channel: %d tau:%.4f sigma:%.4f\n", [self stationNumber], chan, tau[chan],tauSigma[chan]);
		
		/* Update DSP parameters */
		[self setParam:@"PREAMPTAUA" value:floor(tau[chan]) channel:chan];
		[self setParam:@"PREAMPTAUB" value:floor((unsigned short)((tau[chan]-floor(tau[chan]))*65536)) channel:chan];		
		
		[self loadParamsWithReadBack:NO];
		
		[self runBaselineCut:chan];
	}
}

- (void) runBaselineCut:(short)chan
{
	NSLog(@"Running Baselines DF4c Station %d channel %d\n",[self stationNumber],chan);
	double tim;
	long k;
	unsigned short SL,SG,BLcut,LC,KeepLog,KeepHostIO;
	unsigned short buffer[kLinearBufferSize*2]={0};
	double sdev,sdevCount,val,BLsigma;
	double baseline[kLinearBufferSize/6];
	
	/* Store the DSP parameter Log2BWeight value */
	KeepLog=[self paramValue:@"LOG2BWEIGHT" channel:chan];
	[self setParam:@"LOG2BWEIGHT" value:0 channel:chan];
	
	/* Get the values of DSP parameters SlowLength, SlowGap and BLCut */
    SG = [self paramValue:@"SLOWGAP" channel:chan];
    SL = [self paramValue:@"SLOWLENGTH" channel:chan];
	
	/* Set the DSP parameter BLcut  */
	BLcut=[self paramValue:@"BLCUT" channel:chan];
	[self setParam:@"BLCUT" value:0 channel:chan];
	
	/* Set the DSP parameter HostIO  */
	KeepHostIO=[self paramValue:@"HOSTIO" channel:chan];
	[self setParam:@"HOSTIO" value:0 channel:chan ];
	
	[self loadParamsWithReadBack:NO];
	
	tim=(double)(SL+SG)*pow(2.0,(double)decimation);
	
	sdev=0;
	sdevCount=0;
	LC=0;
	do{
		/* Start Control Task 6 to collect 1365 baselines */
		[self executeTask:kMeasureBaselines];
		
		[self writeTSAR:linearDataBufferStart];
		for(k=0;k<kLinearBufferSize;k++){
			[controller camacShortNAF:cachedStation a:0 f:0 data:buffer];
		}
		
		for(k=0; k<1365; k+=1){
			baseline[k]=buffer[6*k]+buffer[6*k+1]*65536;
			baseline[k]=buffer[6*k+2]+buffer[6*k+3]*65536-exp(-tim/(tau[chan]*SYSTEM_CLOCK_MHZ))*baseline[k];
			baseline[k]/=pow(2.0,(decimation+8));
		}
		
		for(k=0; k<1364; k+=2){
			val=fabs(baseline[k]-baseline[k+1]);
			
			if(val!=0){
				if(BLcut==0){
					sdev+=val;
					sdevCount+=1;
				}
				else{
					if(val<BLcut){
						sdev+=val;
						sdevCount+=1;
					}
				}
			}
		}
		
		LC+=1;
		if(LC>10) 
			break;
		
	}while(sdevCount<1000);
	
	BLsigma=sdev*sqrt(3.1415927/2)/sdevCount;
	BLcut=(unsigned short)floor(8.0*BLsigma);
	
	/* Set the DSP parameter BLcut  */
	[self setParam:@"BLCUT" value: BLcut channel:chan];
	[self loadParamsWithReadBack:NO];
	
	sdev=0;
	sdevCount=0;
	LC=0;
	do{
		/* Start Control Task 6 to collect 1365 baselines */
		[self executeTask:kMeasureBaselines];
		
		[self writeTSAR:linearDataBufferStart];
		for(k=0;k<kLinearBufferSize;k++){
			[controller camacShortNAF:cachedStation a:0 f:0 data:buffer];
		}
		
		for(k=0; k<1365; k+=1){
			baseline[k]=buffer[6*k]+buffer[6*k+1]*65536;
			baseline[k]=buffer[6*k+2]+buffer[6*k+3]*65536-exp(-tim/(tau[chan]*SYSTEM_CLOCK_MHZ))*baseline[k];
			baseline[k]/=pow(2.0,(decimation+8));
		}
		
		for(k=0; k<1364; k+=2){
			val=fabs(baseline[k]-baseline[k+1]);
			
			if(val!=0){
				if(BLcut==0){
					sdev+=val;
					sdevCount+=1;
				}
				else{
					if(val<BLcut){
						sdev+=val;
						sdevCount+=1;
					}
				}
			}
		}
		
		LC+=1;
		if(LC>10) 
			break;
		
	}while(sdevCount<1000);
	
	BLsigma=sdev*sqrt(3.1415927/2)/sdevCount;
	BLcut=(unsigned short)floor(8.0*BLsigma);
	
	/* Set the DSP parameter BLcut  */
	[self setParam:@"BLCUT" value: BLcut channel:chan];
	
	/* Restore the DSP parameter Log2BWeight */
	[self setParam:@"LOG2BWEIGHT" value: KeepLog channel:chan];
	
	/* Restore the DSP parameter HostIO  */
	[self setParam:@"HOSTIO" value: KeepHostIO];
	
	[self loadParams];
	
	/* Update user value BLCUT  */
	//index=Find_Xact_User_Match("BLCUT");
	//Dgf4c_Devices[Chosen_Module].user_values[Chosen_Chan][index]=BLcut;
	
}


- (void) calcOffsets
{
	long j, ret;
	double a, b, abdiff, abmid;
	unsigned short adcMax = 4095;
	double coeff[2], TDACwave[kLinearBufferSize],low,high;
	double ChanGain, DACcenter, DACfifty;
	unsigned short TRACKDAC;
	double ADCtarget,baselinepercent;
	NSLog(@"Calculating Offsets DGF4c Station %d\n",[self stationNumber]);
	
	[self executeTask:kRampOffsetDAC];
	
	[self writeTSAR:linearDataBufferStart];
    controller = [self adapter];			//cache the controller and station for alittle bit more speed.
	cachedStation = [self stationNumber];
	
	for (j = 0; j < kLinearBufferSize; j++){ 
		unsigned short data;
		[controller camacShortNAF:cachedStation a:0 f:0 data:&data];
		TDACwave[j] = data;
	}
	
	/*	clean up the array by removing entries that are out of bounds, or on 
	 a constant level */
	for (j = (kLinearBufferSize - 1); j > 0; j--){
		if ((TDACwave[j] > adcMax) || (TDACwave[j] == TDACwave[j-1])){
			TDACwave[j] = 0;
		}
	}
	/* take care of the 0th element last, always lose it */
	TDACwave[0] = 0.0;
	
	/*	Another pass through the array, removing any element that is 
	 surrounded by ZEROs */
	for(j = 1; j < (kLinearBufferSize - 1); j++){
		if(TDACwave[j] != 0){	/* remove out-of-range points and failed measurements */
			if ((TDACwave[j - 1] == 0) && (TDACwave[j + 1] == 0)){
				TDACwave[j] = 0;
			}
		}
	}
	
	for( j = 0; j < 4; j ++ ){
		//check and only do good channels
		unsigned short csra = [self paramValue:@"CHANCSRA" channel:j];
		if(csra & 0x0004) { 
			/* Perform a linear fit to these data */
			low = j*2048;
			coeff[0] = low;
			high = coeff[0]+2047;
			coeff[1] = high;
			ret = linefit(TDACwave,coeff);
			if ( ret == 0 ){
				a = -coeff[0] / coeff[1];
				a = MIN(MAX(low, a), high);
				b = (adcMax - coeff[0]) / coeff[1];
				b = MIN(MAX(low, b), high);
				abdiff = (float) (fabs(b - a) / 2.);
				abmid = (b + a) / 2.;
				a = (float) (ceil(abmid - (0.25 * abdiff)));
				b = (float) (floor(abmid + (0.25 * abdiff)));
				coeff[0] = a;
				coeff[1] = b;
				
				ret = linefit(TDACwave, coeff);
				if ( ret == 0 ){
					a = -coeff[0] / coeff[1];
					a = MIN(MAX(low, a), high);
					b = (adcMax - coeff[0]) / coeff[1];
					b = MIN(MAX(low, b), high);
					abdiff = (float) (fabs(b - a) / 2.);
					abmid = (b + a) / 2.;
					a = (float) (ceil(abmid - (0.9 * abdiff)));
					b = (float) (floor(abmid + (0.9 * abdiff)));
					coeff[0] = a;
					coeff[1] = b;
					
					ret = linefit(TDACwave,coeff);
					if( ret == 0 ){
						ChanGain = coeff[1] / 6.0;
						DACfifty = (2048 - coeff[0]) / coeff[1];
						DACcenter = (DACfifty - low) * 32;
						
						/* Find baseline percent and calculate ADCtarget */
						baselinepercent=(double)[self paramValue:@"BASELINEPERCENT" channel:j];
						ADCtarget=4096*baselinepercent/100.0;
						
						TRACKDAC = (unsigned short)round(DACcenter+32*(ADCtarget-2048)/(6*ChanGain));
						
						[self setParam:@"TRACKDAC" value:TRACKDAC channel:j];
						[self setVOffset:j withValue:((32768.0-TRACKDAC)/32768.0)*3.0];
						
					}
					else NSLogColor([NSColor redColor],@"Dgf4c Station: %d channel: %d AdjustOffsets: linear fit error\n",cachedStation,j);
				}
				else NSLogColor([NSColor redColor],@"Dgf4c Station: %d channel: %d AdjustOffsets: linear fit error\n",cachedStation,j);
			}
			else NSLogColor([NSColor redColor],@"Dgf4c Station: %d channel: %d AdjustOffsets: linear fit error\n",cachedStation,j);
		}
	}
	[self loadParams];
	[self executeTask:kSetDACs];
	[self executeTask:kProgramFiPPI];
}

-(double) tauFinder:(double)Tau channel:(short)chan
{
	long Trig[8192];
	double FF[8192],FF2[8192],TimeStamp[2048];
	double dt,Xwait;    /* dt is the time between Trace samples. */
	long FL,FG;   /* fast filter times are set here */
	long ndat,k,kmin,kmax,n,tcount,MaxTimeIndex = 0;
	double threshold,t0,t1,TriggerLevelShift,avg,MaxTimeDiff;
	double localAmplitude, s1,s0; // used to determine which tau fit was best
	long TFcount;
	
	ndat=8192;
	/* Generate random indices */
	RandomSwap();
	
	/* Get FastLength, FastGap, XWait */
    FL		= [self paramValue:@"FASTLENGTH" channel:chan];
    FG		= [self paramValue:@"FASTGAP" channel:chan];
    Xwait	= [self paramValue:@"XWAIT" channel:chan];
	dt=Xwait/SYSTEM_CLOCK_MHZ*1e-6;
	
	localAmplitude=0;
	for(TFcount=0;TFcount<10;TFcount++){
		[self sampleChannel:chan];		  /* get an ADC-trace via control task 4*/
		
		/* Find threshold */
		threshold = Thresh_Finder((unsigned int*)oscModeData[chan], Tau, FF, FF2, FL, FG,Xwait);
		
		kmin=2*FL+FG;
		
		for(k=0;k<kmin;k+=1) Trig[k]= 0;
		
		/* Find average FF shift */
		avg=0.0;
		n=0;
		for(k=kmin;k<(ndat-1);k+=1){
			if(FF[k+1]-FF[k]<threshold){
				avg+=FF[k];
				n+=1;
			}
		}
		avg/=n;
		for(k=kmin;k<(ndat-1);k+=1)
			FF[k]-=avg;
		
		for(k=kmin;k<(ndat-1);k+=1)  /* look for rising edges */
			Trig[k]= (FF[k]>threshold)?1:0;
		
		tcount=0;
		for(k=kmin;k<(ndat-1);k+=1){  /* record trigger times */
			if((Trig[k+1]-Trig[k])==1)
				TimeStamp[tcount++]=k+2;  /* there are tcount triggers */
		}
		if(tcount>2){
			TriggerLevelShift=0.0;
			for(n=0; n<(tcount-1); n+=1){
				avg=0.0;
				kmin=(long)(TimeStamp[n]+2*FL+FG);
				kmax=(long)(TimeStamp[n+1]-1);
				if((kmax-kmin)>0){
					for(k=kmin;k<kmax;k+=1)
						avg+=FF2[k];
					
					TriggerLevelShift+=avg/(kmax-kmin);
				}
			}
			TriggerLevelShift/=tcount;
		}
		
		switch(tcount){
			case 0:
				continue;
				break;
			case 1:
				t0=TimeStamp[0]+2*FL+FG;
				t1=ndat-2;
				break;
			default:
				MaxTimeDiff=0.0;
				for(k=0;k<(tcount-1);k+=1){
					if((TimeStamp[k+1]-TimeStamp[k])>MaxTimeDiff){
						MaxTimeDiff=TimeStamp[k+1]-TimeStamp[k];
						MaxTimeIndex=k;
					}
				}
				
				if((ndat-TimeStamp[tcount-1])<MaxTimeDiff){
					t0=TimeStamp[MaxTimeIndex]+2*FL+FG;
					t1=TimeStamp[MaxTimeIndex+1]-1;
				}
				else{
					t0=TimeStamp[tcount-1]+2*FL+FG;
					t1=ndat-2;
				}
				
				break;
		}
		
		if(((t1-t0)*dt)<3*Tau)
			continue;
		
		t1=MIN(t1,(t0+round(6*Tau/dt+4)));
		
		s0=0;	s1=0;
		kmin=(long)t0-(2*FL+FG)-FL-1;
		for(k=0;k<FL;k++){
			s0+=oscModeData[chan][kmin+k];
			s1+=oscModeData[chan][(long)(t0+k)];
		}
		if((s1-s0)/FL > localAmplitude){
			Tau=Tau_Fit((unsigned int*)oscModeData[chan], (long)t0, (long)t1, dt);
			localAmplitude=(s1-s0)/FL;
		}
	}
	
	return Tau;   /* do fit */
	
}



#pragma mark ¥¥¥DataTaker
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
    liveTimeId   = [assigner assignDataIds:kLongForm];
    mcaDataId    = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
    [self setMcaDataId:[anotherCard mcaDataId]];
    [self setLiveTimeId:[anotherCard liveTimeId]];
}

- (void) reset
{
	[self loadSystemFPGA];
	[self bootDSP];
	[self loadParamsWithReadBack:YES]; //load all params to HW
}

- (long) oscData:(short)chan value:(short)index
{
	[oscLock lock];
	long val =  oscModeData[chan][index];
	[oscLock unlock];
	return val;
}

- (long) numOscPoints
{
	[oscLock lock];
	long val = numOscPoints;
	[oscLock unlock];
	return val;
}


- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORDGF4cDecoderForWaveform",       @"decoder",
								 [NSNumber numberWithLong:mcaDataId],@"dataId",
								 [NSNumber numberWithBool:YES],      @"variable",
								 [NSNumber numberWithLong:-1],       @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORDGF4cDecoderForEvent",			@"decoder",
				   [NSNumber numberWithLong:dataId],   @"dataId",
				   [NSNumber numberWithBool:YES],      @"variable",
				   [NSNumber numberWithLong:-1],       @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"Event"];
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORDGF4cDecoderForLiveTime",        @"decoder",
				   [NSNumber numberWithLong:liveTimeId],@"dataId",
				   [NSNumber numberWithBool:NO],        @"variable",
				   [NSNumber numberWithLong:19],        @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"LiveTime"];
	
	
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"Waveform",						@"name",
				   [NSNumber numberWithLong:dataId],   @"dataId",
				   [NSNumber numberWithLong:4],		@"maxChannels",
				   nil];
	
	[anEventDictionary setObject:aDictionary forKey:@"ORDGF4cModel"];
}


- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	
	memset(oscModeData,0,4*8192*sizeof(short));
	[self performSelectorOnMainThread:@selector(updateOsc) withObject:nil waitUntilDone:NO];
	
    if(![self adapter]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI-CAMAC Controller (i.e. a CC32)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORDGF4cModel"];    
    
    //----------------------------------------------------------------------------------------
    controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
    unChangingDataPart   = (([self crateNumber]&0xf)<<21) | (([self stationNumber]& 0x0000001f)<<16); //doesn't change so do it here.
	cachedStation = [self stationNumber];
    [self clearExceptionCount];
    
    if([[userInfo objectForKey:@"doinit"]intValue]){
		[self loadSystemFPGA];
        [self bootDSP];
    }
	[self executeTask:kConnectInputs];
	
	[self setParam:@"MODNUM" value:[self stationNumber]];
	
    firstTime = YES;
	okToLoadWhileRunning = ![gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORDFG4cDSPSettingsLock];
	
	linearDataBufferStart	= [self readParam:@"AOUTBUFFER"];
	linearDataBufferSize	= [self readParam:@"LOUTBUFFER"];
	
    [self setComputableParams]; //have to do this before computeMaxEvents
	maxEvents = [self computeMaxEvents:runTask];
	if(maxEvents >=0){
		[self loadParamsWithReadBack:YES]; //load all params to HW
	}
	else {
		[NSException raise:@"Trace Length Too long" format:@"DGF4c station %d",[self stationNumber]];
	}
}


//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    BOOL locked = NO;
    @try {
        if(!firstTime){
			unsigned short csr;
			if(okToLoadWhileRunning)[paramLoadLock lock];
			[controller camacShortNAF:cachedStation a:0 f:1 data:&csr];
            if(!(csr & kActiveCSRBit)){
				if((csr & kLAMStateCSRBit) == kLAMStateCSRBit){
					[controller lock];  //begin special global critical section
                    locked = YES;
					unsigned short numWordsInBuffer;
					unsigned short numLongsInBuffer;
					BOOL padIt = NO;				
					[controller camacShortNAF:cachedStation a:2 f:1 data:&numWordsInBuffer];
					
					//numWordsInBuffer--; // The number of words in the buffer includes this word
					if((numWordsInBuffer & 0x1) == 0){
						numLongsInBuffer = 2+(numWordsInBuffer/2);
					}
					else {
						//must pad to long word boundary
						numLongsInBuffer = 2+((numWordsInBuffer+1)/2);
						padIt = YES;
					}
					
					NSMutableData* theData = [[NSMutableData allocWithZone:nil] initWithLength:numLongsInBuffer*sizeof(long)];
					unsigned long* ptr     = (unsigned long*)[theData mutableBytes];
					ptr[0] = dataId | (kLongFormLengthMask & numLongsInBuffer); //note size in longs
					ptr[1] = unChangingDataPart;
					unsigned short* sptr = (unsigned short*)(&ptr[2]);
					[self writeTSAR:linearDataBufferStart];
					int i;
					for(i=0;i<numWordsInBuffer;i++){
						[controller camacShortNAF:cachedStation a:0 f:0 data:sptr++];
						//	[ORTimer delayNanoseconds:100];
					}
					if(padIt){
						*sptr = 0;	
					}
					//ship the data
					[aDataPacket addData:theData];
					
					if(sampleWaveforms){
						[self sampleWaveforms:(unsigned long*)[theData bytes]];
					}
					//[aDataPacket addLongsToFrameBuffer:ptr length:2+numLongsInBuffer];
					[theData release];
					
					//resume
					[self writeCSR:csrValueForResuming];
                    [controller unlock];    //end special global critical section
                    locked = NO;
					
				}
				
				
				if((csr & kDSPErrorCSRBit) == kDSPErrorCSRBit){
					NSLogError(@"",@"DFG4c Card Error",@"DSP Error",nil);
				}
			}
			if(okToLoadWhileRunning)[paramLoadLock unlock];
			
		}
        else {
			unsigned short csr = [self readCSR];
			csr = csr | kRunEnableCSRBit | kNewRunCSRBit | kEnableLAMCSRBit;
			[self writeCSR:csr];
			csrValueForResuming = csr & ~kNewRunCSRBit;
            firstTime = NO;
		}
		
	}
	@catch(NSException* localException) {
		if(locked)[controller unlock];//end special global critical section (after exception)
		NSLogError(@"",@"DFG4c Card Error",@"Take Data Loop",nil);
		[self incExceptionCount];
		[localException raise];
	}
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	//stop the run without overwritting other bits.
	[self clearCSRBit:kRunEnableCSRBit];
	NSTimeInterval t0 = [NSDate timeIntervalSinceReferenceDate];
	while([self readCSR] & kActiveCSRBit) {
		if([NSDate timeIntervalSinceReferenceDate]-t0 > 1){
			NSLogColor([NSColor redColor],@"Time-out waiting for DGF4c %d to stop run\n",[self stationNumber]);
			break;
		}
	}
	
	int i;
	for(i=0;i<4;i++){
		[self readMCA:aDataPacket channel:i];
	}
	
	//[self executeTask:kDisconnectInputs];
	[self readParams];
	
	[self shipLiveTime];
	
}

- (void) shipLiveTime
{      
	//this routine assumes that the params have been read from the board
	unsigned long liveTimeData[19];
	
	
	liveTimeData[0] = liveTimeId | 19;		//old version == 13 new version == 19
	liveTimeData[1] = 0;					//spare
	liveTimeData[2] = (([self crateNumber]&0xf)<<21) | (([self stationNumber]& 0x0000001f)<<16);
	
	int chan;
	
	unsigned long rta = [self paramValue:@"REALTIMEA"];
	unsigned long rtb = [self paramValue:@"REALTIMEB"];
	unsigned long rtc = [self paramValue:@"REALTIMEC"];
	//double realTime = (rta*pow(65536.0,2.0)+rtb*65536.0+rtc)*1.0e-6/40.;
	//packedDGF4LiveTime.asDouble = realTime;
	liveTimeData[3] = rta;
	liveTimeData[4] = rtb<<16 | rtc;
	
	rta = [self paramValue:@"RUNTIMEA"];
	rtb = [self paramValue:@"RUNTIMEB"];
	rtc = [self paramValue:@"RUNTIMEC"];
	//double runTime = (rta*pow(65536.0,2.0)+rtb*65536.0+rtc)*1.0e-6/40.;
	//packedDGF4LiveTime.asDouble = runTime;
	liveTimeData[5] = rta;
	liveTimeData[6] = rtb<<16 | rtc;
	
	int index = 7;
	for(chan = 0;chan<4;chan++){
		
		rta = [self paramValue:@"LIVETIMEA" channel:chan];
		rtb = [self paramValue:@"LIVETIMEB" channel:chan];
		rtc = [self paramValue:@"LIVETIMEC" channel:chan];
		//double liveTime=(la*pow(65536.0,2.0)+lb*65536.0+lc)*16*1.0e-6/40.;
		//packedDGF4LiveTime.asDouble = liveTime;
		liveTimeData[index++] = rta;
		liveTimeData[index++] = rtb<<16 | rtc;
		
		
		unsigned short na = [self paramValue:@"FASTPEAKSA" channel:chan];
		unsigned short nb = [self paramValue:@"FASTPEAKSB" channel:chan];
		liveTimeData[index++] = na*65536 + nb; //total number of events for this channel
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
														object:[NSData dataWithBytes:liveTimeData length:19*sizeof(long)]];
}

- (void) readMCA:(ORDataPacket*)aDataPacket channel:(short)aChannel
{
	if([self paramValue:@"CHANCSRA" channel:aChannel] & 0x0004){
		unsigned short bufferAddress = [self readParam:@"AOUTBUFFER"];
		unsigned long bufferLength   = [self readParam:@"LOUTBUFFER"]; //number of shorts
		
		[self setParam:@"HOSTIO" to:aChannel];
		
		//reconstructed data (size in longs + extra head stuff
		NSMutableData* mcaData = [NSMutableData dataWithLength:(8*2*bufferLength)+2*sizeof(long)];
		unsigned long* mcaPtr = (unsigned long*)[mcaData bytes];
		
		long wordCount = 2;
		
		controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
		cachedStation = [self stationNumber];
		
		@try {
			[controller lock];
			int numPage;
			for(numPage=0;numPage<8;numPage++){
				if(numPage==0) [self executeTask:kReadHistogramMemoryPage1];
				else     [self executeTask:kReadHistogramMemoryNextPages];
				
				[self writeTSAR:bufferAddress];
				unsigned short data[2];
				int k;
				for(k=0;k<bufferLength;k+=2){
					[controller camacShortNAF:cachedStation a:0 f:0 data:&data[0] ];
					[controller camacShortNAF:cachedStation a:0 f:0 data:&data[1] ];
					mcaPtr[wordCount++] =  (unsigned int)(data[1]*0x10000+data[0]);
				}
			}
			[controller unlock];
		}
		@catch(NSException* localException) {
			[controller unlock];
			[localException raise];
		}
		
		mcaPtr[0] = mcaDataId | wordCount; //len in longs!
		mcaPtr[1] = unChangingDataPart | (aChannel<<12);
		
		[aDataPacket addData:mcaData];
	}	
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    
    [self setRunBehaviorMask: [decoder decodeInt32ForKey :@"ORDGF4cModelRunBehaviorMask"]];
    [self setRunTask		: [decoder decodeIntForKey	 :@"ORDGF4cModelRunTask"]];
    [self setFirmWarePath   : [decoder decodeObjectForKey:@"firmWarePath"]];
    [self setDSPCodePath    : [decoder decodeObjectForKey:@"dspCodePath"]];
    [self setParams         : [decoder decodeObjectForKey:@"params"]];
    [self setLastParamPath  : [decoder decodeObjectForKey:@"lastParamPath"]];
    [self setLastNewSetPath : [decoder decodeObjectForKey:@"lastNewSetPath"]];
    [self setChannel        : [decoder decodeIntForKey   :@"channel"]];
    [self setRevision       : [decoder decodeIntForKey   :@"revision"]];
    [self setDecimation     : [decoder decodeIntForKey   :@"decimation"]];
    [self setOscEnabledMask : [decoder decodeIntForKey   :@"oscEnabledMask"]];
    [[self undoManager] enableUndoRegistration];
    
    
    if(!params){
        NSBundle* mainBundle = [NSBundle mainBundle];
        NSString* path       = [mainBundle pathForResource: @"dfg4cDSPParams" ofType: @"plist"];
        if([[NSFileManager defaultManager] fileExistsAtPath:path]){
            NSMutableDictionary* tempDict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
            if([tempDict count]){
                [self setParams:tempDict];
            }
        }
    }
	
#   define NAME(xx) [NSString stringWithFormat:(xx),i]
    int i;
    for(i=0;i<4;i++){
        [self setTau:i withValue:[decoder decodeDoubleForKey:NAME(@"ORDGF4cModelTauD%d")]];
        [self setTauSigma:i withValue:[decoder decodeDoubleForKey:NAME(@"ORDGF4cModelTauSigma%d")]];
        [self setBinFactor:i withValue:[decoder decodeIntForKey:NAME(@"ORDGF4cModelBinFactor%d")]];
        [self setEMin:i withValue:[decoder decodeIntForKey:NAME(@"ORDGF4cModelEMin%d")]];
        [self setPsaEnd:i withValue:[decoder decodeFloatForKey:NAME(@"ORDGF4cModelPsaEndF%d")]];
        [self setPsaStart:i withValue:[decoder decodeFloatForKey:NAME(@"ORDGF4cModelPsaStartF%d")]];
        [self setTraceDelay:i withValue:[decoder decodeFloatForKey:NAME(@"ORDGF4cModelTraceDelayF%d")]];
        [self setTraceLength:i withValue:[decoder decodeIntForKey:NAME(@"ORDGF4cModelTraceLength%d")]];
        [self setVOffset:i withValue:[decoder decodeFloatForKey:NAME(@"ORDGF4cModelVOffset%d")]];
        [self setVGain:i withValue:[decoder decodeFloatForKey:NAME(@"ORDGF4cModelVGain%d")]];
        [self setTriggerThreshold:i withValue:[decoder decodeFloatForKey:NAME(@"ORDGF4cModelTriggerThreshold%d")]];
        [self setTriggerFlatTop:i withValue:[decoder decodeFloatForKey:NAME(@"ORDGF4cModelTriggerFlatTop%d")]];
        [self setTriggerRiseTime:i withValue:[decoder decodeFloatForKey:NAME(@"ORDGF4cModelTriggerRiseTime%d")]];
        [self setEnergyFlatTop:i withValue:[decoder decodeFloatForKey:NAME(@"ORDGF4cModelEnergyFlatTop%d")]];
        [self setEnergyRiseTime:i withValue:[decoder decodeFloatForKey:NAME(@"ORDGF4cModelEnergyRiseTime%d")]];
        [self setXwait:i withValue:[decoder decodeIntForKey:NAME(@"ORDGF4cModelXwait%d")]];
    }
	//[self calcUserParams];
    [self setComputableParams];
	
	oscLock			= [[NSLock alloc] init];
	paramLoadLock	= [[NSLock alloc] init];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [super encodeWithCoder:coder];
    [coder encodeInt32:runBehaviorMask forKey:@"ORDGF4cModelRunBehaviorMask"];
    [coder encodeInt:runTask forKey:@"ORDGF4cModelRunTask"];
    [coder encodeObject: firmWarePath forKey:@"firmWarePath"];
    [coder encodeObject: dspCodePath forKey:@"dspCodePath"];
    [coder encodeObject: params forKey: @"params"];
    [coder encodeObject: lastParamPath forKey: @"lastParamPath"];
    [coder encodeObject: lastNewSetPath forKey: @"lastNewSetPath"];
    [coder encodeInt:channel forKey:@"channel"];
    [coder encodeInt:revision forKey:@"revision"];
    [coder encodeInt:decimation forKey:@"decimation"];
	[coder encodeInt:oscEnabledMask forKey:@"oscEnabledMask"];
    int i;
    for(i=0;i<4;i++){
        [coder encodeDouble:tau[i] forKey:NAME(@"ORDGF4cModelTauD%d")];
        [coder encodeDouble:tauSigma[i] forKey:NAME(@"ORDGF4cModelTauSigma%d")];
        [coder encodeInt:binFactor[i] forKey:NAME(@"ORDGF4cModelBinFactor%d")];
        [coder encodeInt:eMin[i] forKey:NAME(@"ORDGF4cModelEMin%d")];
        [coder encodeFloat:psaEnd[i] forKey:NAME(@"ORDGF4cModelPsaEndF%d")];
        [coder encodeFloat:psaStart[i] forKey:NAME(@"ORDGF4cModelPsaStartF%d")];
        [coder encodeFloat:traceDelay[i] forKey:NAME(@"ORDGF4cModelTraceDelayF%d")];
        [coder encodeInt:traceLength[i] forKey:NAME(@"ORDGF4cModelTraceLength%d")];
        [coder encodeFloat:vOffset[i] forKey:NAME(@"ORDGF4cModelVOffset%d")];
        [coder encodeFloat:vGain[i] forKey:NAME(@"ORDGF4cModelVGain%d")];
        [coder encodeFloat:triggerThreshold[i] forKey:NAME(@"ORDGF4cModelTriggerThreshold%d")];
        [coder encodeFloat:triggerFlatTop[i] forKey:NAME(@"ORDGF4cModelTriggerFlatTop%d")];
        [coder encodeFloat:triggerRiseTime[i] forKey:NAME(@"ORDGF4cModelTriggerRiseTime%d")];
        [coder encodeFloat:energyFlatTop[i] forKey:NAME(@"ORDGF4cModelEnergyFlatTop%d")];
        [coder encodeFloat:energyRiseTime[i] forKey:NAME(@"ORDGF4cModelEnergyRiseTime%d")];
        [coder encodeInt:xwait[i] forKey:NAME(@"ORDGF4cModelXwait%d")];
    }
    
}

- (NSArray*) valueArrayFor:(SEL)sel
{
	
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:sel]];
    [invocation setSelector:sel];
    [invocation setTarget:self];
	
	NSMutableArray* theValues = [NSMutableArray arrayWithCapacity:4];
	int i;
	for(i=0;i<4;i++){
		const char *theArg = [[self methodSignatureForSelector:sel] methodReturnType];
		[invocation setArgument:&i atIndex:2];
		[invocation invoke];
		if(*theArg == 'f'){
			float fValue;
			[invocation getReturnValue:&fValue];
			[theValues addObject:[NSNumber numberWithFloat:fValue]];
		}
		else if(*theArg == 'd'){
			double dValue;
			[invocation getReturnValue:&dValue];
			[theValues addObject:[NSNumber numberWithDouble:dValue]];
		}
		else if(*theArg == 'i' || *theArg == 'S' || *theArg == 's'){
			int iValue;
			[invocation getReturnValue:&iValue];
			[theValues addObject:[NSNumber numberWithInt:iValue]];
		}
		
		
	}
	return theValues;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithLong:runBehaviorMask] forKey:@"runBehavior"];
    [objDictionary setObject:[self valueArrayFor:@selector(triggerRiseTime:)] forKey:@"triggerRiseTime"];
    [objDictionary setObject:[self valueArrayFor:@selector(triggerFlatTop:)] forKey:@"triggerFlatTop"];
    [objDictionary setObject:[self valueArrayFor:@selector(triggerThreshold:)] forKey:@"triggerThreshold"];
    [objDictionary setObject:[self valueArrayFor:@selector(energyRiseTime:)] forKey:@"energyRiseTime"];
    [objDictionary setObject:[self valueArrayFor:@selector(energyFlatTop:)] forKey:@"energyFlatTop"];
    [objDictionary setObject:[self valueArrayFor:@selector(traceLength:)] forKey:@"traceLength"];
    [objDictionary setObject:[self valueArrayFor:@selector(traceDelay:)] forKey:@"traceDelay"];
    [objDictionary setObject:[self valueArrayFor:@selector(psaStart:)] forKey:@"psaStart"];
    [objDictionary setObject:[self valueArrayFor:@selector(psaEnd:)] forKey:@"psaEnd"];
    [objDictionary setObject:[self valueArrayFor:@selector(vGain:)] forKey:@"vGain"];
    [objDictionary setObject:[self valueArrayFor:@selector(vOffset:)] forKey:@"vOffset"];
    [objDictionary setObject:[self valueArrayFor:@selector(tau:)] forKey:@"tau"];
    [objDictionary setObject:[self valueArrayFor:@selector(tauSigma:)] forKey:@"tauSigma"];
    [objDictionary setObject:[self valueArrayFor:@selector(binFactor:)] forKey:@"binFactor"];
    [objDictionary setObject:[self valueArrayFor:@selector(eMin:)] forKey:@"cutoffEmin"];
    [objDictionary setObject:[self valueArrayFor:@selector(xwait:)] forKey:@"xwait"];
    [objDictionary setObject:[NSNumber numberWithBool:[self syncWait]] forKey:@"syncWait"];
    [objDictionary setObject:[NSNumber numberWithBool:[self inSync]] forKey:@"inSync"];
	
	return objDictionary;
}



- (void) loadDefaults
{
    NSBundle* mainBundle = [NSBundle mainBundle];
	NSString*   path = [mainBundle pathForResource: kDefaultParamFile ofType: @"plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        if(dict){
			[self setParams:dict];
			[self calcUserParams];
			[self setComputableParams];
		}
    }    
}

- (void) createNewVarList:(NSString*)aFilePath
{
    //read in the var list
    NSString* contents = [NSString stringWithContentsOfFile:aFilePath encoding:NSASCIIStringEncoding error:nil];
    
    //fix up the line ends to be just '\n'
    contents = [[contents componentsSeparatedByString:@"\r"]   componentsJoinedByString:@"\n"];
    contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
    
    //break up into separate lines
    NSMutableArray* theLines = [[[contents componentsSeparatedByString:@"\n"] mutableCopy] autorelease];
    
    //create dictionaries
    NSMutableArray* dspArray     = [NSMutableArray array];
    NSMutableArray* dspChanArray = [NSMutableArray array];
    
    
    int numLines = [theLines count];
    int i;
    for(i=0;i<numLines;i++){
        NSString* lineNoSpaces = [[theLines objectAtIndex:i] removeExtraSpaces];
        [theLines replaceObjectAtIndex:i withObject:lineNoSpaces];
    }
    
    while([theLines count]){
        NSString* aLine = [theLines objectAtIndex:0];
        NSArray*  parts = [aLine componentsSeparatedByString:@" "];
        if([parts count] != 2){
            //remove lines with no defined parameter
            [theLines removeObjectAtIndex:0];
            continue; 
        }
        
        //sort into the proper dictionary
        NSString* addressString = [parts objectAtIndex:0];
        NSString* nameString    = [parts objectAtIndex:1];
        
        NSArray* chanParamArray = [self collectChanNames:nameString list:theLines];
        
        if([chanParamArray count] == 4){
            
            [theLines removeObjectsInArray:chanParamArray];
            
            int chan;
            NSMutableDictionary* aDict = [NSMutableDictionary dictionary];
            //set the root name for the param group
            [aDict setObject: [nameString substringToIndex:[nameString length]-1] forKey:@"name"];
            
            for(chan=0;chan<4;chan++){
                NSString* chanLine = [chanParamArray objectAtIndex:chan];
                NSArray*  parts = [chanLine componentsSeparatedByString:@" "];
                NSString* addressString = [parts objectAtIndex:0];
                
                //set the chan adddress
                [aDict setObject:[NSNumber numberWithInt:[addressString intValue]] 
                          forKey:[NSString stringWithFormat:@"address%d",chan]];
                
                //set the chan value
                [aDict setObject:[NSNumber numberWithInt:0] 
                          forKey:[NSString stringWithFormat:@"value%d",chan]];
                
            }
            [dspChanArray addObject:aDict];
            
        } 
        else {
            [dspArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:[addressString intValue]], @"address",
								 nameString, @"name",
								 [NSNumber numberWithInt:0], @"value",
								 nil]];
            
            [theLines removeObjectAtIndex:0];
        }
    }
    
    //now load the current values into the new dictionary as best we can. any new params 
    //will end up being set to zero.
    { //--start a new scope so no conflict with above code
        NSArray* dspParams = [params objectForKey:@"DSPParams"];
        int count = [dspParams count];
        int i;
        for(i=0;i<count;i++){
            NSDictionary* item = [dspParams objectAtIndex:i];
            NSString* name  = [item objectForKey:@"name"];
            NSNumber* value = [item objectForKey:@"value"];
            int j;
            for(j=0;j<[dspArray count];j++){
                NSMutableDictionary* newItem  = [dspArray objectAtIndex:j];
                NSString* newItemName  = [newItem objectForKey:@"name"];
                if([newItemName isEqualToString:name]){
                    [newItem setObject:value forKey:@"value"];
                    break;
                }
            }
        }
    }
    
    { //--start a new scope so no conflict with above code
        
        NSArray* dspChanParams = [params objectForKey:@"DSPChanParams"];
        int count = [dspChanParams count];
        int i;
        for(i=0;i<count;i++){
            NSDictionary* item = [dspChanParams objectAtIndex:i];
            NSString* name  = [item objectForKey:@"name"];
            NSNumber* value0 = [item objectForKey:@"value0"];
            NSNumber* value1 = [item objectForKey:@"value1"];
            NSNumber* value2 = [item objectForKey:@"value2"];
            NSNumber* value3 = [item objectForKey:@"value3"];
            int j;
            for(j=0;j<[dspChanArray count];j++){
                NSMutableDictionary* newItem  = [dspChanArray objectAtIndex:j];
                NSString* newItemName  = [newItem objectForKey:@"name"];
                if(newItemName && [newItemName isEqualToString:name]){
                    [newItem setObject:value0 forKey:@"value0"];
                    [newItem setObject:value1 forKey:@"value1"];
                    [newItem setObject:value2 forKey:@"value2"];
                    [newItem setObject:value3 forKey:@"value3"];
                    break;
                }
            }
        }
    }
    
    NSMutableDictionary* newParams = [NSMutableDictionary dictionary];
    [newParams setObject:dspChanArray forKey:@"DSPChanParams"];
    [newParams setObject:dspArray forKey:@"DSPParams"];
    
    [self setParams:newParams];
	[self calcUserParams];
    [self setComputableParams];
}

- (void) saveSetToPath:(NSString*)aPath
{
    [self setLastParamPath:aPath];
    if([params writeToFile:aPath atomically:YES]){
        NSLog(@"%@ (station %d) params saved to: <%@>\n",[self className], [self stationNumber], [aPath stringByAbbreviatingWithTildeInPath]);
    }
    else {
        NSLogColor([NSColor redColor],@"%@ (station %d) failed to save params to: <%@>\n",[self className], [self stationNumber], [aPath stringByAbbreviatingWithTildeInPath]);
    }
}

- (void) loadSetFromPath:(NSString*)aPath
{
    [self setLastParamPath:aPath];
    NSDictionary* p = [NSDictionary dictionaryWithContentsOfFile:aPath];
    [self setParams:[[p mutableCopy]autorelease]];
	[self calcUserParams];
    [self setComputableParams];
    NSLog(@"%@ (station %d) params loaded from: <%@>\n",[self className], [self stationNumber], [aPath stringByAbbreviatingWithTildeInPath]);
}

#pragma mark ¥¥¥HW Wizard

- (int) numberOfChannels
{
    return 4;
}
-(BOOL) hasParmetersToRamp
{
	return YES;
}
- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Rise Time"];
    [p setFormat:@"##0.0000" upperLimit:0.73 lowerLimit:0.3 stepSize:.01 units:@""];
    [p setSetMethod:@selector(setTriggerRiseTime:withValue:) getMethod:@selector(triggerRiseTime:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Flat Top"];
    //[p setFormatter:[[[OHexFormatter alloc] init] autorelease]];
    [p setFormat:@"##0.0000" upperLimit:0.73 lowerLimit:0.3 stepSize:.01 units:@""];
    [p setSetMethod:@selector(setTriggerFlatTop:withValue:) getMethod:@selector(triggerFlatTop:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Threshold"];
    [p setFormat:@"##0" upperLimit:65535 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTriggerThreshold:withValue:) getMethod:@selector(triggerThreshold:)];
	[p setCanBeRamped:YES];
	[p setInitMethodSelector:@selector(loadParams)];
    [a addObject:p];
	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Energy Rise Time"];
    [p setFormat:@"##0.0000" upperLimit:64 lowerLimit:0 stepSize:.01 units:@""];
    [p setSetMethod:@selector(setEnergyRiseTime:withValue:) getMethod:@selector(energyRiseTime:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Energy Flat Top"];
    [p setFormat:@"##0.0000" upperLimit:64 lowerLimit:0 stepSize:.01 units:@""];
    [p setSetMethod:@selector(setEnergyFlatTop:withValue:) getMethod:@selector(energyFlatTop:)];
    [a addObject:p];
	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trace Length"];
    //[p setFormatter:[[[OHexFormatter alloc] init] autorelease]];
    [p setFormat:@"##0" upperLimit:20 lowerLimit:0 stepSize:1 units:@"uS"];
    [p setSetMethod:@selector(setTraceLength:withValue:) getMethod:@selector(traceLength:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trace Delay"];
    //[p setFormatter:[[[OHexFormatter alloc] init] autorelease]];
    [p setFormat:@"##0.00" upperLimit:100 lowerLimit:0 stepSize:1 units:@"uS"];
    [p setSetMethod:@selector(setTraceDelay:withValue:) getMethod:@selector(traceDelay:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"PSA Start"];
    //[p setFormatter:[[[OHexFormatter alloc] init] autorelease]];
    [p setFormat:@"##0.00" upperLimit:100 lowerLimit:0 stepSize:1 units:@"uS"];
    [p setSetMethod:@selector(setPsaStart:withValue:) getMethod:@selector(psaStart:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"PSA End"];
    //[p setFormatter:[[[OHexFormatter alloc] init] autorelease]];
    [p setFormat:@"##0.00" upperLimit:100 lowerLimit:0 stepSize:1 units:@"uS"];
    [p setSetMethod:@selector(setPsaEnd:withValue:) getMethod:@selector(psaEnd:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"V Gain"];
    [p setFormat:@"##0.000" upperLimit:16 lowerLimit:0 stepSize:.1 units:@"V/V"];
    [p setSetMethod:@selector(setVGain:withValue:) getMethod:@selector(vGain:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"V Offset"];
    [p setFormat:@"##0.000" upperLimit:3 lowerLimit:-3 stepSize:.1 units:@"V"];
    [p setSetMethod:@selector(setVOffset:withValue:) getMethod:@selector(vOffset:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Tau"];
    [p setFormat:@"##0" upperLimit:10000000 lowerLimit:0 stepSize:1 units:@"uS"];
    [p setSetMethod:@selector(setTau:withValue:) getMethod:@selector(tau:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"TauSigma"];
    [p setFormat:@"##0.0000" upperLimit:10000000 lowerLimit:0 stepSize:.1 units:@"uS"];
    [p setSetMethod:@selector(setTauSigma:withValue:) getMethod:@selector(tauSigma:)];
    [a addObject:p];
	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Bin Factor"];
    [p setFormat:@"##0" upperLimit:6 lowerLimit:1 stepSize:1 units:@""];
    [p setSetMethod:@selector(setBinFactor:withValue:) getMethod:@selector(binFactor:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Cutoff Emin"];
    [p setFormat:@"##0" upperLimit:32768 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setEMin:withValue:) getMethod:@selector(eMin:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"XWait"];
    [p setFormat:@"##0" upperLimit:100 lowerLimit:0 stepSize:1 units:@"x25ns"];
    [p setSetMethod:@selector(setXwait:withValue:) getMethod:@selector(xwait:)];
    [a addObject:p];
	
    [a addObject:[ORHWWizParam boolParamWithName:@"SyncWait" setter:@selector(setSyncWait:) getter:@selector(syncWait)]];
    [a addObject:[ORHWWizParam boolParamWithName:@"InSync" setter:@selector(setInSync:) getter:@selector(inSync)]];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Calc Baselines"];
    [p setSetMethodSelector:@selector(runBaselineCuts)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Calc Offset"];
    [p setSetMethodSelector:@selector(calcOffsets)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Load Params"];
    [p setSetMethodSelector:@selector(loadParams)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Full Init"];
    [p setSetMethodSelector:@selector(fullInit)];
    [a addObject:p];
	
    return a;
}


- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORCamacCrate"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"ORDGF4cModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORDGF4cModel"]];
    return a;
	
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if(     [param isEqualToString:@"Trigger Rise Time"])return [[cardDictionary objectForKey:@"triggerRiseTime"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Trigger Flat Top"]) return [[cardDictionary objectForKey:@"triggerFlatTop"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Trigger Threshold"])return [[cardDictionary objectForKey:@"triggerThreshold"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Energy Rise Time"]) return [[cardDictionary objectForKey:@"energyRiseTime"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Energy Flat Top"])  return [[cardDictionary objectForKey:@"energyFlatTop"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Trace Length"])     return [[cardDictionary objectForKey:@"traceLength"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Trace Delay"])      return [[cardDictionary objectForKey:@"traceDelay"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"PSA Start"])        return [[cardDictionary objectForKey:@"psaStart"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"PSA End"])          return [[cardDictionary objectForKey:@"psaEnd"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"V Gain"])           return [[cardDictionary objectForKey:@"vGain"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"V Offset"])         return [[cardDictionary objectForKey:@"vOffset"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Tau"])              return [[cardDictionary objectForKey:@"tau"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"TauSigma"])         return [[cardDictionary objectForKey:@"tauSigma"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Bin Factor"])       return [[cardDictionary objectForKey:@"binFactor"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Cutoff Emin"])      return [[cardDictionary objectForKey:@"cutoffEmin"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"XWait"])            return [[cardDictionary objectForKey:@"xwait"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"syncWait"])		 return [cardDictionary objectForKey:@"syncWait"];
    else if([param isEqualToString:@"inSync"])			 return [cardDictionary objectForKey:@"inSync"];
    else if([param isEqualToString:@"noLiveTimeCorrecton"])	return [cardDictionary objectForKey:@"noLiveTimeCorrecton"];
    else return nil;
}


@end

@implementation ORDGF4cModel (private)

- (long) computeMaxEvents:(long) runType
{
	
	long k,maximumEvents;
	unsigned short bhl,ehl,chl,leventbuffer,loutputbuffer,lengthin,lengthout;
	
	/* Check InputEventSize for list modes (0x101, 0x102, 0x103)  */
	/* and must not exceed EventBufferSize; Check OutputEventSize */
	/* for all list modes.								          */
	chl				= 0;
	bhl				= kBufferHeaderLength;				//Buffer Head Length
	ehl				= kEventHeaderLength;				//Event Head Length
	leventbuffer	= kEventBufferLength;				//Event Buffer Length
	loutputbuffer	= [self readParam:@"LOUTBUFFER"];	//Output Buffer Length
	
	if(runType != kMCAMode){ /* All list modes */
		
		if((runType == kListModeCompression1) || (runType == kListModeCompression2) || (runType == kListModeCompression3)){
			
			lengthin = bhl + ehl;
			/* Set Channel Head Length */
			switch(runType){
				case kListModeCompression1: chl=9; break;
				case kListModeCompression2: chl=4; break;
				case kListModeCompression3: chl=2; break;
			}
			
			for(k = 0; k < 4; k ++){
				unsigned short csra = [self paramValue:@"CHANCSRA" channel:k];
				if(csra & 0x0004){
					unsigned short tLength = [self paramValue:@"TRACELENGTH" channel:k];
					lengthin += chl + tLength;
				}
			}
			if (lengthin > leventbuffer){
				NSLogColor([NSColor redColor],@"The event is too long for DGF4d station %d. Please shorten traces\n",[self stationNumber]);
				return -1;
			}
		}
		
		/* Check OutputEventSize for list modes and fast list modes; */
		/* must not exceed OutBufferSize; if successful, calculate   */
		/* maximumEvents.												 */
		
		/* Set Channel Head Length */
		switch(runType){
			case kListMode:
			case kListModeCompression1:
			case kFastListMode:
			case kFastListModeCompression1:
				chl = 9; break;
			case kListModeCompression2:
			case kFastListModeCompression2:
				chl = 4; break;
			case kListModeCompression3:
			case kFastListModeCompression3:
				chl = 2; break;
			default:     // invalid Run Type
				NSLogColor([NSColor redColor],@"Bad run type for DGF4d station %d.\n",[self stationNumber]);
				return -1;
		}
		
		lengthout = ehl;
		for(k = 0; k < 4; k ++){
			unsigned short csra = [self paramValue:@"CHANCSRA" channel:k];
			if(csra & 0x0004){
				if(runType == kListMode){ /* capture traces only in list mode 0x100 */
					short tLength = [self paramValue:@"TRACELENGTH" channel:k];
					lengthout += chl + tLength;
				}
				else
					lengthout += chl;
			}
		}
		
		if(lengthout > (loutputbuffer-bhl)){
			NSLogColor([NSColor redColor],@"The event is too long for DGF4d station %d. Please shorten traces\n",[self stationNumber]);
			return -1;
		}
		
		/* Calculate maximumEvents */
		maximumEvents = (long)floor((loutputbuffer-bhl)/lengthout);
	}				
	else{ /* No need to check MCA run mode 0x301 */
		maximumEvents=0;
	}
	
	/* Update the DSP parameter MAXEVENTS */
	[self setParam:@"MAXEVENTS" value:maximumEvents];
	
	return maximumEvents;
}

- (void) setComputableParams
{
    
    unsigned short val;
	
	[self setParam:@"RUNTASK"  value:runTask ];
	if([self multipleCardEnvironment]){
		[self setParam:@"SYNCHWAIT" value:runBehaviorMask&0x1];
		[self setParam:@"INSYNCH"  value:(runBehaviorMask&0x2)>>1];
	}
	else {
		[self setParam:@"SYNCHWAIT" value:0];
		[self setParam:@"INSYNCH"  value:0];
	}
	[self setParam:@"DECIMATION" value:decimation];
	
    //peaksample
    short i;
    for(i=0;i<4;i++){
		
		//XWAIT
        [self setParam:@"XWAIT" value:xwait[i] channel:i];
		
		//GAINDAC
        val = 65535.0 - (32768.0*log10(((double)vGain[i]/0.1639)));
        [self setParam:@"GAINDAC" value:val channel:i];
		
		//TRACKDAC
        val = 32768 * (1. - (vOffset[i]/3.0));
		[self setParam:@"TRACKDAC" value:val channel:i];
		
        //-------------------------------------------------------------------------
        //energy filter parameters
        //SLOWGAP
        val = energyFlatTop[i]/((pow(2.,(double)decimation))*0.025);
        [self setParam:@"SLOWGAP" value: val channel:i];
        
        //SLOWLENGTH
        unsigned short val = energyRiseTime[i]/((pow(2.,(double)decimation))*0.025);
        [self setParam:@"SLOWLENGTH" value: val channel:i];
		
        //-------------------------------------------------------------------------
        //trigger filter parameters
        //FASTGAP
        val = triggerFlatTop[i]/0.025;
        [self setParam:@"FASTGAP" value: val channel:i];
		
        //FASTLENGTH
        val = triggerRiseTime[i]/0.025;    
        [self setParam:@"FASTLENGTH" value: val channel:i];
        
		//FASTTHRES
		val = triggerThreshold[i] * val;
		[self setParam:@"FASTTHRESH" value:val channel:i];
		
		//-------------------------------------------------------------------------
		
		
        unsigned short slowLength   = [self paramValue:@"SLOWLENGTH" channel:i];
        unsigned short slowGap      = [self paramValue:@"SLOWGAP"    channel:i];
        unsigned short fastLength   = [self paramValue:@"FASTLENGTH" channel:i];
        unsigned short fastGap      = [self paramValue:@"FASTGAP"    channel:i];
        unsigned short trigDelay    = [self paramValue:@"TRIGGERDELAY"    channel:i];
		
		
        //check constraints
        if(!((slowLength + slowGap) < 32)) {
			[self constraintViolated:@"SLOWLENGTH+SLOWGAP < 32 Check Decimation!"];
			NSLog(@"Try adjusting the Energy Filter parameters (chan: %d)\n",i);
		}
        if(fastLength > 32){
			[self constraintViolated:@"FASTLENGTH < 32"];
			NSLog(@"Try adjusting the Trigger Filter rise time (chan: %d)\n",i);
		}
        if((fastGap + fastLength) > 32) {
			[self constraintViolated:@"FASTLENGTH+FASTGAP < 32"];
			NSLog(@"Try adjusting the Trigger Filter parameters (chan: %d)\n",i);
		}
		
        //PEAKSAMPLE
		unsigned short peakSample,peakSep;
        switch (decimation) {
            case 0:  peakSample = MAX(0,slowLength+slowGap-7);  peakSep = peakSample+5; break;
            case 1:  peakSample = MAX(2,slowLength+slowGap-4);  peakSep = peakSample+5; break;
            case 2:  peakSample = slowLength+slowGap-2;			peakSep = peakSample+5; break;
            default: peakSample = slowLength+slowGap-1;			peakSep = peakSample+5; break;
        }
		
		if(peakSample>33) {
			peakSep = peakSample+1;
		}
		if(peakSep-peakSample > 7){
			peakSep = peakSample+7;
		}
        [self setParam:@"PEAKSAMPLE" value:peakSample channel:i];
        [self setParam:@"PEAKSEP" value:peakSep channel:i];
		
        //MINWIDTH and MAXWIDTH
        val = triggerFlatTop[i]/0.025 + triggerRiseTime[i]/0.025 + (2.0/*micro seconds*//0.025);
		[self setParam:@"MAXWIDTH" value:val channel:i];
        if(val>255)[self setParam:@"MAXWIDTH" value:255 channel:i]; 
        [self setParam:@"MINWIDTH" value:fastLength+fastGap channel:i];
		
        //paflength       
        val = trigDelay + (traceDelay[i]*SYSTEM_CLOCK_MHZ) + 8;
        if(val > 4092)val = 4092;
        [self setParam:@"PAFLENGTH" value:val channel:i];
		
        //triggerDelay       
        val = (peakSample + 6)*pow(2.,(double)decimation);
        if(val > 4092)val = 4092;
        [self setParam:@"TRIGGERDELAY" value:val channel:i];
		
        //trace length 
		//1 sample every 25 ns. user inputs micro secs. so 40 samples/microsec     
		val = traceLength[i]*SYSTEM_CLOCK_MHZ;
        [self setParam:@"TRACELENGTH" value:val channel:i];
		
		//compute the value that will be written to HW.
		[self setParam:@"PREAMPTAUA" value: floor(tau[i]) channel:i];
		[self setParam:@"PREAMPTAUB" value: 65536*(tau[i] - floor(tau[i]))  channel:i];
		
		[self setParam:@"LOG2EBIN" value:(65536-binFactor[i]) channel:i];
		
		
    }
}

- (void) calcUserParams
{
	double UDcorr[7]={8.0,0.0,8.0,0.0,8.0,0.0,8.0};
	int chan;
	[self setDecimation:[self paramValue:@"DECIMATION"]];
	
	double dt=pow(2.0,(double)decimation)/SYSTEM_CLOCK_MHZ;
	for(chan=0;chan<4;chan++){
		
		unsigned short slowLength = [self paramValue:@"SLOWLENGTH" channel:chan];
		unsigned short slowGap    = [self paramValue:@"SLOWGAP" channel:chan];
		[self setEnergyRiseTime:chan withValue:slowLength*dt];
		[self setEnergyFlatTop:chan withValue:slowGap*dt];
		
		unsigned short fastLength = [self paramValue:@"FASTLENGTH" channel:chan];
		unsigned short fastGap    = [self paramValue:@"FASTGAP" channel:chan];
		unsigned short fastThres  = [self paramValue:@"FASTTHRESH" channel:chan];
		[self setTriggerRiseTime:chan withValue:fastLength/SYSTEM_CLOCK_MHZ];
		[self setTriggerFlatTop:chan withValue:fastGap/SYSTEM_CLOCK_MHZ];
		[self setTriggerThreshold:chan withValue:fastThres/fastLength];
		
		unsigned short rta = [self paramValue:@"PREAMPTAUA" channel:chan];
		unsigned short rtb = [self paramValue:@"PREAMPTAUB" channel:chan];
		[self setTau:chan withValue:(double)(rta+rtb/65536.0)];
		
		[self setTraceLength:chan withValue:[self paramValue:@"TRACELENGTH" channel:chan]];
		
		/*----- Get trace delay -----*/
		/* Get the DSP parameter PAFLENGTH */
		unsigned short PAFLength    = [self paramValue:@"PAFLENGTH" channel:chan];
		unsigned short triggerDelay = [self paramValue:@"TRIGGERDELAY" channel:chan];
		
		[self setTraceDelay:chan withValue:PAFLength-triggerDelay-UDcorr[decimation]];
		if(traceDelay[chan] < 0.0) {  // Ensure limit
			traceDelay[chan] = 0.0;
		}
		
		/* Get the DSP parameter PSAOFFSET */
		[self setPsaStart:chan withValue:[self paramValue:@"PSAOFFSET" channel:chan]];
		unsigned short psaLength = [self paramValue:@"PSALENGTH" channel:chan];
		[self setPsaEnd:chan withValue:psaStart[chan] + psaLength];
		
		/*----- Get Vgain -----*/
		/* Get DSP parameter GAINDAC */
		unsigned short GAINDAC			 = [self paramValue:@"GAINDAC" channel:chan];
		[self setVGain:chan withValue: 0.1639*pow(10.0,(65535.0-((double)GAINDAC))/32768.0)];
		
		/*----- Get Voffset -----*/
		/* Get DSP parameter TRACKDAC */
		unsigned short TRACKDAC			 = [self paramValue:@"TRACKDAC" channel:chan];
		[self setVOffset:chan withValue:((32768.0-TRACKDAC)/32768.0)*3.0];
		
		/* Get DSP parameter ENERGYLOW */
		[self setEMin:chan withValue:[self paramValue:@"ENERGYLOW" channel:chan]];
		[self setBinFactor:chan	withValue:[self paramValue:@"LOG2EBIN" channel:chan]];
		
		/* Get DSP parameter XWAIT */
		unsigned short XWAIT = [self paramValue:@"XWAIT" channel:chan];
		[self setXwait:chan withValue: XWAIT];
	}
}


- (NSArray*) collectChanNames:(NSString*)nameString list:(NSMutableArray*)theLines
{
    NSMutableArray* list = [NSMutableArray array];
    if([nameString hasSuffix:@"0"]){
        //OK, this may be a chan param. check that others exist as well
        NSString* rootName = [nameString substringToIndex:[nameString length]-1];
        int i;
        for(i=0;i<4;i++){
            NSEnumerator* e = [theLines objectEnumerator];
            NSString* aLine;
            while(aLine = [e nextObject]){
                NSArray*  parts         = [aLine componentsSeparatedByString:@" "];
                if([parts count] == 2){
                    NSString* nameString    = [parts objectAtIndex:1];
                    if([nameString isEqualToString:[NSString stringWithFormat:@"%@%d",rootName,i]]){
                        [list addObject: aLine];
                        break;
                    }
                }
            }
        }
    }
    return list;
}

- (unsigned short) getDSPParamAddress:(NSString*)aName
{
    NSDictionary* paramDict;
    NSArray* paramArray = [params objectForKey:@"DSPParams"];
    int n = [paramArray count];
    int i;
    for(i=0;i<n;i++){
        paramDict = [paramArray objectAtIndex:i];
        if([[paramDict objectForKey:@"name"] isEqualToString:aName]){
            return [[paramDict objectForKey:@"address"] intValue] + kDataStartAddress;
        }
    }
    
    [NSException raise: kDGF4cParamNotFound format:@"Param not found"];
    return 0;
}

- (void) generateLookUpTable
{
    if(!lookUpTable)[self setLookUpTable:[NSMutableDictionary dictionary]];
    NSMutableArray* array = [params objectForKey:@"DSPParams"];
    int n = [array count];
    int i;
    for(i=0;i<n;i++){
        NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithInt:i],@"index",
									[NSNumber numberWithBool:NO],@"channelParam",
									array,@"array",
									nil];
        
        [lookUpTable setObject:dictionary forKey:[[array objectAtIndex:i] objectForKey:@"name"]];
    }
    array = [params objectForKey:@"DSPChanParams"];
    n = [array count];
    for(i=0;i<n;i++){
        NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithInt:i],@"index",
									array,@"array",
									[NSNumber numberWithBool:YES],@"channelParam",
									nil];
        [lookUpTable setObject:dictionary forKey:[[array objectAtIndex:i] objectForKey:@"name"]];
    }
}

- (void) constraintViolated:(NSString*)reasonString
{
    NSLogError(@"",@"DFG4c Card Error",@"Param Constraint Violated",reasonString,nil);
    reasonString = [@"Violated: " stringByAppendingString:reasonString];
	
    NSLogColor([NSColor redColor],@"%@\n",reasonString);
	
	[self postWarning:reasonString];
	
}



- (void) sampleWaveforms:(unsigned long*)recordPtr
{
	[oscLock lock];
	
	if(recordPtr != NULL) {
		long totalWords			= (recordPtr[0] & kLongFormLengthMask)*2;	//length was in longs, convert to words
		unsigned short* dataPtr = (unsigned short*)&recordPtr[2];	//recast to short
		unsigned short* endDataPtr;
		
		totalWords -= 4;											//don't count the ORCA header
		unsigned short* bufferHeader = dataPtr;						//set up the bufferHeader block
		unsigned short bufNData		 = bufferHeader[0];				//number of words in the buffer
		endDataPtr = dataPtr + bufNData;
		
		//make sure that there's an event and check the length, if problem flush the rest
		if(totalWords-bufNData<0 || bufNData<=kBufferHeaderLength){
			[oscLock unlock];
			return; 
		}
		
		unsigned short task	 = bufferHeader[2]; //run task that generated this buffer, needed to determine chanheader length
		task	 &= 0x0fff;						//take off the top bit to get the true 
		
		/* use the run task to determine the channel header length */
		unsigned short chl;
		switch(task){
			case kListMode:
			case kListModeCompression1:
			case kFastListMode:
			case kFastListModeCompression1:
				chl = 9;
				break;
			case kListModeCompression2:
			case kFastListModeCompression2:
				chl = 4;
				break;
			case kListModeCompression3:
			case kFastListModeCompression3:
				chl = 2;
				break;
			default:
				[oscLock unlock];
				return; //somethings wrong, just return
				break;
		}
		
		dataPtr += kBufferHeaderLength;
		
		do {
			unsigned short* eventHeader = dataPtr;
			unsigned short evtPattern = eventHeader[0];	//get the event hit pattern
			dataPtr += kEventHeaderLength;				//the data Ptr ahead to the first channel header
			
			if( evtPattern != 0 ){
				int chan;
				for( chan = 0; chan < 4; chan++){
					if(evtPattern & (0x1<<chan)){
						unsigned short* chanHeader = dataPtr;
						if( chl == 9 ){
							unsigned short chanNData = chanHeader[0];		//number of words in the channel header (may include waveforms)
							dataPtr += chl;									//move the dataPtr ahead
							if( chanNData > chl ){
								//there is waveform data
								unsigned short* waveFormdata = dataPtr;
								int w;
								for(w=0;w<chanNData-9;w++){
									oscModeData[chan][w] = waveFormdata[w];
								}
								numOscPoints= chanNData;
								dataPtr += (chanNData-chl);
							}
						}
						else {
							//non waveform chan headers
							dataPtr += chl;				//move the dataPtr ahead
						}
					}
				}
				[self performSelectorOnMainThread:@selector(updateOsc) withObject:nil waitUntilDone:NO];
			}
		}while( dataPtr < endDataPtr );
	}
	[oscLock unlock];
}

- (void) updateOsc
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORDFG4cWaveformChangedNotification object:self];
}

- (BOOL) multipleCardEnvironment
{
	return [[guardian collectObjectsOfClass:[self class]] count] > 1;
}

@end

