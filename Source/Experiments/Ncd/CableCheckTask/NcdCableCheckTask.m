//
//  NcdCableCheckTask.m
//  Orca
//
//  Created by Mark Howe on Oct 8, 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


#import "NcdCableCheckTask.h"
#import "ORPulserDistribModel.h"
#import "NcdModel.h"
#import "ORHPPulserModel.h"

#import "NcdPDSStepTask.h"
#import "NcdTube.h"
#import "NcdDetector.h"
#import "ORShaperModel.h"
#import "NcdMuxBoxModel.h"
#import "OROscBaseModel.h"

@interface NcdCableCheckTask (private)
- (void) findShaperForCurrentTube;
- (void) checkCurrentShaper;
- (void) checkCurrentMux;
- (void) checkCurrentScope;
- (void) findMuxForCurrentTube;
- (void) findScopeForCurrentTube;
- (void) setCurrentShaper:(ORShaperModel*)aShaper channel:(int)aChannel;
- (void) setCurrentMux:(NcdMuxBoxModel*)aMux channel:(int)aChannel;
- (void) setCurrentScopes:(NSArray*)someScopes channel:(int)aChannel;
- (void) postFailedAlarm;
- (void) clearFailedAlarm;
- (void) loadPDSForCurrentTube;
- (void) pulsePulser;
- (void) restoreOldValues;
- (void) setNewValues;
- (BOOL) _doWork;
@end

enum {
    kFindObjects,
    kWait,
    kCheckObjects
};
enum {
    kFailed,
    kPassed,
    kNoObject,
    kPDSOutOfRange
};

@implementation NcdCableCheckTask
-(id)	init
{
    if( self = [super init] ){
#if !defined(MAC_OS_X_VERSION_10_9)
        [NSBundle loadNibNamed:@"NcdCableCheckTask" owner:self];
#else
        [[NSBundle mainBundle] loadNibNamed:@"NcdCableCheckTask" owner:self topLevelObjects:&ncdCableCheckTaskObjects];
#endif
        [ncdCableCheckTaskObjects retain];

        [self setTitle:@"Cable Check"];
        [self setDefaults];
    }
    return self;
}

- (void) delloc
{
    [failedAlarm clearAlarm];    
    [failedAlarm release];
    [lastTime release];
    [thePDSModel release];
    [thePulserModel release];
    [currentTube release];
    [currentScopes release];
    [currentMux release];
    [currentShaper release];
    [pulserMemento release];
    [pdsMemento release];
    [tubeArray release];
    [ncdCableCheckTaskObjects release];

    [super dealloc];
}


- (void) awakeFromNib
{
    [super awakeFromNib];
    [self addExtraPanel:extraView];
}

- (BOOL) okToRun
{
    return [[ORGlobal sharedGlobal] runInProgress];
}

- (NSArray *) currentScopes
{
    return currentScopes; 
}

- (void) setCurrentScopes: (NSArray *) aCurrentScopes
{
    [aCurrentScopes retain];
    [currentScopes release];
    currentScopes = aCurrentScopes;
}


- (NcdMuxBoxModel *) currentMux
{
    return currentMux; 
}

- (void) setCurrentMux: (NcdMuxBoxModel *) aCurrentMux
{
    [aCurrentMux retain];
    [currentMux release];
    currentMux = aCurrentMux;
}


- (ORShaperModel *) currentShaper
{
    return currentShaper; 
}

- (void) setCurrentShaper: (ORShaperModel *) aCurrentShaper
{
    [aCurrentShaper retain];
    [currentShaper release];
    currentShaper = aCurrentShaper;
}

- (NSMutableArray *) tubeArray
{
    return tubeArray; 
}

- (void) setTubeArray: (NSMutableArray *) aTubeArray
{
    [aTubeArray retain];
    [tubeArray release];
    tubeArray = aTubeArray;
}

- (NSData *) pulserMemento
{
    return pulserMemento; 
}

- (void) setPulserMemento: (NSData *) aPulserMemento
{
    [aPulserMemento retain];
    [pulserMemento release];
    pulserMemento = aPulserMemento;
}


- (NSData *) pdsMemento
{
    return pdsMemento; 
}

- (void) setPdsMemento: (NSData *) aPdsMemento
{
    [aPdsMemento retain];
    [pdsMemento release];
    pdsMemento = aPdsMemento;
}

- (float)amplitude {
	
    return amplitude;
}

- (void)setAmplitude:(float)anAmplitude 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAmplitude:amplitude];
    amplitude = anAmplitude;
    [amplitudeField setFloatValue:amplitude];
    [amplitudeStepper setFloatValue:amplitude];
}


- (float)width
{
    return width;
}

- (void)setWidth:(CGFloat)aWidth 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWidth:width];
    width = aWidth;
    [widthField setFloatValue:width];
    [widthStepper setFloatValue:width];
}


- (int) numPulses
{
	
    return numPulses;
}

- (void) setNumPulses: (int) aNumPulses
{
    if(aNumPulses==0)aNumPulses = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setNumPulses:numPulses];
    numPulses = aNumPulses;
    [numPulsesField setIntValue:numPulses];
    [numPulsesStepper setIntValue:numPulses];
}


- (unsigned short) muxThreshold
{
    return muxThreshold;
}

- (void) setMuxThreshold: (unsigned short) aMuxThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMuxThreshold:muxThreshold];
    muxThreshold = aMuxThreshold;
    [muxThresholdField setIntValue:muxThreshold];
    [muxThresholdStepper setIntValue:muxThreshold];
}



- (unsigned short) shaperThreshold
{
    return shaperThreshold;
}

- (void) setShaperThreshold: (unsigned short) aShaperThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShaperThreshold:shaperThreshold];
    shaperThreshold = aShaperThreshold;
    [shaperThresholdField setIntValue:shaperThreshold];
    [shaperThresholdStepper setIntValue:shaperThreshold];
}

- (NSDate *) lastTime
{
    return lastTime; 
}

- (void) setLastTime: (NSDate *) aLastTime
{
    [aLastTime retain];
    [lastTime release];
    lastTime = aLastTime;
}

- (id) thePDSModel
{
    return thePDSModel; 
}

- (void) setThePDSModel: (id) aThePDSModel
{
    [aThePDSModel retain];
    [thePDSModel release];
    thePDSModel = aThePDSModel;
}


- (id) thePulserModel
{
    return thePulserModel; 
}

- (void) setThePulserModel: (id) aThePulserModel
{
    [aThePulserModel retain];
    [thePulserModel release];
    thePulserModel = aThePulserModel;
}

- (NcdTube *) currentTube
{
    return currentTube; 
}

- (void) setCurrentTube: (NcdTube *) aCurrentTube
{
    [aCurrentTube retain];
    [currentTube release];
    currentTube = aCurrentTube;
}


- (BOOL) verbose
{
    return verbose;
}

- (void) setVerbose: (BOOL) flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVerbose:verbose];
    verbose = flag;
    [verboseButton setState:verbose];
	
}

#pragma mark ¥¥¥Actions

- (IBAction) amplitudeAction:(id)sender
{
    [self setAmplitude:[sender floatValue]];
}

- (IBAction) widthAction:(id)sender
{
    [self setWidth:[sender floatValue]];
}

- (IBAction) numPulsesAction:(id)sender
{
    [self setNumPulses:[sender intValue]];
}

- (IBAction) shaperThresholdAction:(id)sender
{
    [self setShaperThreshold:[sender intValue]];
}

- (IBAction) muxThresholdAction:(id)sender
{
    [self setMuxThreshold:[sender intValue]];
}

- (IBAction) verboseAction:(id)sender
{
    [self setVerbose:[sender intValue]];
}

#pragma mark ¥¥¥Task Methods
- (void) prepare
{
    [super prepare];
    [self clearFailedAlarm];
    passed = YES; //assume the best
    [self setLastTime:[NSDate date]];
    NSArray* objects = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORPulserDistribModel")];
    if([objects count]){
        [self setThePDSModel:[objects objectAtIndex:0]];
        [self setPdsMemento :[thePDSModel memento]];  //save the old values
		
        [thePDSModel setDisableForPulser:YES];
    }
	
    objects = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORHPPulserModel")];
    if([objects count]){
        [self setThePulserModel:[objects objectAtIndex:0]];
        [self setPulserMemento :[thePulserModel memento]];  //save the old values
        [thePulserModel setVoltage:amplitude];
        [thePulserModel setTotalWidth:width];
        [thePulserModel setTriggerSource:kSoftwareTrigger];
        [thePulserModel setSelectedWaveform:kSquareWave1];
        [thePulserModel downloadWaveform];
        [delegate shipPulserRecord:thePulserModel];
        [self setMessage:@"Set up Pulser"];
    }
    phase = kFindObjects;
    [self setTubeArray:[[[[NcdDetector sharedInstance] tubes]mutableCopy] autorelease]];
    
    NSEnumerator* e = [tubeArray objectEnumerator];
    id aTube;
    NSMutableArray* tubesToSkip = [NSMutableArray array];
    while(aTube = [e nextObject]){
        if(![[aTube objectForKey:@"kCableCheck"] boolValue])[tubesToSkip addObject:aTube];
    }
    if([tubesToSkip count]){
        NSLog(@"The following tube%@ flagged to be skipped:\n",[tubesToSkip count]>=2?@"s are":@" is");
        e = [tubesToSkip objectEnumerator];
        while(aTube = [e nextObject])NSLog(@"%@\n",[aTube objectForKey:@"kLabel"]);
        [tubeArray removeObjectsInArray:tubesToSkip];
    }
    
    NSLog(@"Found %d tubes set for checking.\n",[tubeArray count]);
	
    [self setNewValues];
    
    tubeIndex = 0;
}


- (BOOL)  doWork
{
    BOOL isThereMoreToDo;
    [[self undoManager] disableUndoRegistration];
    if(doingFinishUpWork){
        isThereMoreToDo = [thePulserModel loading];
    }
    else {
        isThereMoreToDo = [self _doWork];
    }
    [[self undoManager] enableUndoRegistration];
    return isThereMoreToDo;
}


- (void) finishUp
{
    [super finishUp];
    
	[self setTubeArray:nil];
	[self restoreOldValues];
    
    [self setCurrentShaper:nil];
    [self setCurrentMux:nil];
    [self setCurrentScopes:nil];
    [self setCurrentTube:nil];
    [self setTubeArray:nil];
    
    [self setLastTime:nil];
    
    [self setMessage:@"Restore Pulser"];
    if(thePulserModel){
		@try {
			[thePulserModel restoreFromMemento:pulserMemento];
		}
		@catch(NSException* localException) {
		}
        [self setPulserMemento:nil];
    }
    [self setMessage:@"Restore PDS"];
    if(thePDSModel){
		@try {
			[thePDSModel restoreFromMemento:pdsMemento];
		}
		@catch(NSException* localException) {
		}
        [self setPdsMemento:nil];
    }
    [self setMessage:@"Idle"];
}

- (void) cleanUp
{
    [self setThePulserModel:nil];
    [self setThePDSModel:nil];
    
    if(passed)[self clearFailedAlarm];
    else [self postFailedAlarm];
    [self setMessage:@"Idle"];
}

- (void) setDefaults
{
    [[self undoManager] disableUndoRegistration];
    [self setAmplitude:250];
    [self setWidth:8.2];
    [self setNumPulses:1];
    [self setMuxThreshold:20];
    [self setShaperThreshold:100];
    [[self undoManager] enableUndoRegistration];    
}

- (void) enableGUI:(BOOL)state
{
    [amplitudeField setEnabled:state];
    [amplitudeStepper setEnabled:state];
    [widthField setEnabled:state];
    [widthStepper setEnabled:state];
    [numPulsesField setEnabled:state];
    [numPulsesStepper setEnabled:state];
    [shaperThresholdField setEnabled:state];
    [shaperThresholdStepper setEnabled:state];
    [muxThresholdField setEnabled:state];
    [muxThresholdStepper setEnabled:state];
    [verboseButton setEnabled:state];
}

- (NSString*) description
{
    NSString* s = @"\n";
    s = [s stringByAppendingFormat:@"Pulses/chan: %d\n",numPulses];
    s = [s stringByAppendingFormat:@"Amp: %.2f  Width: %.2f\n\n",amplitude,width];
    s = [s stringByAppendingFormat:@"Shaper Thres: %d  Mux Thres: %d\n\n",shaperThreshold,muxThreshold];
    return s;
}


#pragma mark ¥¥¥Archival
static NSString* NcdCableCheckAmplitude     = @"NcdCableCheckAmplitude";
static NSString* NcdCableCheckWidth         = @"NcdCableCheckWidth";
static NSString* NcdCableCheckNumPulses     = @"NcdCableCheckNumPulses";
static NSString* NcdCableCheckShaperThreshold = @"NcdCableCheckShaperThreshold";
static NSString* NcdCableCheckMuxThreshold  = @"NcdCableCheckMuxThreshold";
static NSString* NcdCableCheckMuxVerbose  = @"NcdCableCheckMuxVerbose";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"NcdCableCheckTask" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"NcdCableCheckTask" owner:self topLevelObjects:&ncdCableCheckTaskObjects];
#endif
    [ncdCableCheckTaskObjects retain];
	
    [[self undoManager] disableUndoRegistration];
	
    if([decoder decodeFloatForKey:NcdCableCheckAmplitude]){
        [self setAmplitude:[decoder decodeFloatForKey:NcdCableCheckAmplitude]];
        [self setWidth:[decoder decodeFloatForKey:NcdCableCheckWidth]];
        [self setNumPulses:[decoder decodeIntForKey:NcdCableCheckNumPulses]];
        [self setShaperThreshold:[decoder decodeIntegerForKey:NcdCableCheckShaperThreshold]];
        [self setMuxThreshold:[decoder decodeIntegerForKey:NcdCableCheckMuxThreshold]];
        [self setVerbose:[decoder decodeBoolForKey:NcdCableCheckMuxVerbose]];
    }
    else {
        [self setDefaults];
    }
    [[self undoManager] enableUndoRegistration];    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:amplitude forKey:NcdCableCheckAmplitude];
    [encoder encodeFloat:width forKey:NcdCableCheckWidth];
    [encoder encodeInteger:numPulses forKey:NcdCableCheckNumPulses];
    [encoder encodeInteger:shaperThreshold forKey:NcdCableCheckShaperThreshold];
    [encoder encodeInteger:muxThreshold forKey:NcdCableCheckMuxThreshold];
    [encoder encodeBool:verbose forKey:NcdCableCheckMuxVerbose];
}
@end

@implementation NcdCableCheckTask (private)
- (BOOL) _doWork
{
    if(![tubeArray count]){
        NSLogColor([NSColor redColor],@"NCD Cable Check Task: No entries in the tube map, so nothing to do!\n");
        return NO;        
    }
    
    if(!thePDSModel){
        NSLogColor([NSColor redColor],@"NCD Cable Check Task: No PDS object in config, so nothing to do!\n");
        return NO;
    }
    if(!thePulserModel){
        NSLogColor([NSColor redColor],@"NCD Cable Check Task: No Pulser object in config, so nothing to do!\n");
        NSLogColor([NSColor redColor],@"NCD Cable Check Task: Start of <%@> aborted!\n",[self title]);
        return NO; //can not run if no pulser object in config
    }
    
    //must wait for the pulser to load waveform
    if([thePulserModel loading])return YES;
	
    BOOL quit = NO;
    
    if(phase == kFindObjects){
        if(tubeIndex >= [tubeArray count]){
            [self finishUp];
            return NO;
        }
        pulseCount = 0;
        [self setCurrentTube:[tubeArray objectAtIndex:tubeIndex]];  //get the next tube to work on
        
        [self setMessage:[NSString stringWithFormat:@" Checking %@ (%d/%d)",[currentTube objectForKey:@"kLabel"],tubeIndex+1,(int)[tubeArray count]]];
		
        [self findShaperForCurrentTube];
        [self findMuxForCurrentTube];
        [self findScopeForCurrentTube];
		
        tubeIndex++;
        
        @try {
            [self loadPDSForCurrentTube];
            //[self pulsePulser];
		}
		@catch(NSException* localException) {
            NSLogColor([NSColor redColor],@"Cable check task quit. Vme exception: %@\n",[localException name]);
            quit = YES;
        }
        
        
        if(quit){
            [self finishUp];
            return NO;
        }
        else {
            unsigned short pdsBoard    = [[currentTube objectForKey:@"kPdsBoardNum"] intValue];
            unsigned short pdsChannel  = [[currentTube objectForKey:@"kPdsChan"] intValue];
            if(!(pdsBoard<4 && pdsChannel<16)){
                
                NSLog(@"%@ skipped (PDS out of range)\n",[currentTube objectForKey:@"kLabel"]);
                [self setCurrentTube:nil];
				
                phase = kFindObjects;
            }
            else {
                phase = kWait;
            }
        }
		
    }
    
    else if(phase == kWait){
        //pause for two seconds to give system time (esp. the scopes) to respond
        NSDate* now = [NSDate date];
        if([now timeIntervalSinceDate:lastTime] >= 2.5){
            [self setLastTime:now];
            if(pulseCount>=numPulses)phase = kCheckObjects;
            else {
                @try {
                    [self pulsePulser];
				}
				@catch(NSException* localException) {
                    NSLogColor([NSColor redColor],@"Cable check task quit because of Vme exception\n");
                    quit = YES;
                }
            }
            
            if(quit){
                [self finishUp];
                return NO;
            }
		}
    }
    
    else if(phase == kCheckObjects){
		
        [self checkCurrentShaper];
        [self checkCurrentMux];
        [self checkCurrentScope];
        if(!verbose){
            NSString* result = [NSString stringWithFormat:@"%@ ",[currentTube objectForKey:@"kLabel"]];
            if(!pdsInRange){
                result = [result stringByAppendingString: @"PDS Out of Range (test skipped)\n"];
            }
            else {
                if(shaperResult == kNoObject){
                    result = [result stringByAppendingString:@"(No shaper) "];
                }
                else {
                    result = [result stringByAppendingString:shaperResult == kPassed?@"(Shaper Passed) ":@"(Shaper FAILED) "];
                }
                if(muxResult == kNoObject){
                    result = [result stringByAppendingString:@"(No mux) "];
                }
                else {
                    result = [result stringByAppendingString:   muxResult == kPassed?@"(Mux Passed) ":@"(Mux FAILED) "];
                }
                if(scopeResult == kNoObject){
                    result = [result stringByAppendingString:@"(No Scope)\n"];
                }
                else {
                    result = [result stringByAppendingString: scopeResult == kPassed?@"(Scope Passed)\n":@"(Scope FAILED)\n"];
                }
            }
            if(shaperResult == kPassed && muxResult == kPassed && scopeResult == kPassed){
                NSLogColor([NSColor colorWithCalibratedRed:0 green:.5 blue:0.0 alpha:1.0],result);
            }
            else NSLogColor([NSColor redColor], result);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORTaskDidStepNotification object:self];
        
        [self setCurrentTube:nil];
        
        phase = kFindObjects;
    }
	
    return YES;
}

-(void) findShaperForCurrentTube
{
    //clear out the old one
    [self setCurrentShaper:nil channel:0];
    
    NSArray* allShapers = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")];
    int slot    = [[currentTube objectForKey:@"kAdcSlot"] intValue];    
    int channel = [[currentTube objectForKey:@"kAdcChannel"] intValue];
    uint32_t address = (uint32_t)strtol([[currentTube objectForKey:@"kAdcHWAddress"] cStringUsingEncoding:NSASCIIStringEncoding],0,16);;
    NSEnumerator* e = [allShapers objectEnumerator];
    ORShaperModel* shaper;
    while(shaper = [e nextObject]){
        if([shaper slot] == slot && [shaper baseAddress] == address){
            [self setCurrentShaper:shaper channel:channel];
            break;
        }
    }
    if(!currentShaper){
        //if it's in the tube map it better a real object in the configuration
        //post error and raise exception
        if(verbose)NSLogColor([NSColor redColor], @"No shaper card found for tube %@\n",[currentTube objectForKey:@"kLabel"]); 
        shaperResult = kNoObject;
        passed = NO;
    }
    else {
        startingShaperCounts = [currentShaper adcCount:channel];
    }
}

- (void) setCurrentShaper:(ORShaperModel*)aShaper channel:(int)aChannel
{
    [aShaper retain];
    [currentShaper release];
    currentShaper = aShaper;
    
    currentShaperChannel = aChannel;
    
}



- (void) checkCurrentShaper
{
    if(currentShaper){
        if(([currentShaper adcCount:currentShaperChannel] - startingShaperCounts)>=numPulses){
            shaperResult = kPassed;
            if(verbose)NSLog(@"%@ Shaper <0x%08x> slot: %d channel: %d passed. (counts: %d)\n",
							 [currentTube objectForKey:@"kLabel"],
							 [currentShaper baseAddress], 
							 [currentShaper slot], 
							 currentShaperChannel,
							 [currentShaper adcCount:currentShaperChannel]-startingShaperCounts);
			
        }
        else {
            shaperResult = kFailed;
            if(verbose)NSLogColor([NSColor redColor],@"%@ Shaper <0x%08x> slot: %d channel: %d FAILED. (counts: %d)\n",
								  [currentTube objectForKey:@"kLabel"],
								  [currentShaper baseAddress], 
								  [currentShaper slot], 
								  currentShaperChannel,
								  [currentShaper adcCount:currentShaperChannel]-startingShaperCounts);
            passed = NO;
        }
    }
}

-(void)findMuxForCurrentTube
{
    //clear out the old one
    [self setCurrentMux:nil channel:0];
    
    NSArray* allMuxes = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"NcdMuxBoxModel")];
	
    int muxBox      = [[currentTube objectForKey:@"kMuxBusNum"] intValue];  //arggggggg!!!! they switched box/bus  
    int muxBus      = [[currentTube objectForKey:@"kMuxBoxNum"] intValue];  //arggggggg!!!! they switched box/bus
    int muxChannel  = [[currentTube objectForKey:@"kMuxChan"] intValue];
    
    NSEnumerator* e = [allMuxes objectEnumerator];
    NcdMuxBoxModel* mux;
    while(mux = [e nextObject]){
        if([mux busNumber] == muxBus && [mux muxID] == muxBox){
            [self setCurrentMux:mux channel:muxChannel];
            break;
        }
    }
    if(!currentMux){
        //if it's in the tube map it better a real object in the configuration
        //post error and raise exception
        if(verbose)NSLogColor([NSColor redColor], @"No Mux found for tube %@\n",[currentTube objectForKey:@"kLabel"]); 
        muxResult = kNoObject;
        passed = NO;
    }
    else {
        startingMuxCounts = [currentMux rateCount:muxChannel];
    }
	
}

- (void) checkCurrentMux
{
    if(currentMux){
        if(([currentMux rateCount:currentMuxChannel] - startingMuxCounts)>=numPulses){
            muxResult = kPassed;
            if(verbose)NSLog(@"%@ Mux <0x%08x>  box: %d channel: %d passed. (counts: %d)\n",
							 [currentTube objectForKey:@"kLabel"],
							 [currentMux busNumber], 
							 [currentMux muxID], 
							 currentMuxChannel,
							 [currentMux rateCount:currentMuxChannel]-startingMuxCounts);
		}
        else {
            muxResult = kFailed;
            if(verbose)NSLogColor([NSColor redColor],@"%@ Mux <0x%08x>  box: %d channel: %d FAILED. (counts: %d)\n",
								  [currentTube objectForKey:@"kLabel"],
								  [currentMux busNumber], 
								  [currentMux muxID], 
								  currentMuxChannel,
								  [currentMux rateCount:currentMuxChannel]-startingMuxCounts);
            passed = NO;
        }
    }
}

- (void) setCurrentMux:(NcdMuxBoxModel*)aMux channel:(int)aChannel;
{
    [aMux retain];
    [currentMux release];
    currentMux = aMux;
    currentMuxChannel = aChannel;
}

- (void) findScopeForCurrentTube
{
    int scopeChannel  = [[currentTube objectForKey:@"kScopeChannel"] intValue];
    NSArray* allScopes = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"OROscBaseModel")];
    [self setCurrentScopes:allScopes channel:scopeChannel];
	
    if([allScopes count]==0){
        //if it's in the tube map it better a real object in the configuration
        //post error and raise exception
        if(verbose)NSLogColor([NSColor redColor], @"No Scopes found for tube %@\n",[currentTube objectForKey:@"kLabel"]); 
        scopeResult = kNoObject;
        passed = NO;
    }
    else {
        NSEnumerator* e = [allScopes objectEnumerator];
        OROscBaseModel* aScope;
        startingScopeCounts = 0;
        while(aScope = [e nextObject]){
            startingScopeCounts += [aScope eventCount:scopeChannel];
        }
    }
	
}

- (void) setCurrentScopes:(NSArray*)someScopes channel:(int)aChannel;
{
    [someScopes retain];
    [currentScopes release];
    currentScopes = someScopes;
    currentScopeChannel = aChannel;
}

- (void) checkCurrentScope
{
    if([currentScopes count]!=0){
        uint32_t currentScopeCounts = 0;
        NSEnumerator* e = [currentScopes objectEnumerator];
        OROscBaseModel* aScope;
        currentScopeCounts = 0;
        while(aScope = [e nextObject]){
            currentScopeCounts += [aScope eventCount:currentScopeChannel];
        }
		
        if((currentScopeCounts - startingScopeCounts)>=numPulses){
            scopeResult = kPassed;
            if(verbose)NSLog(@"%@ Scope channel: %d passed. (counts: %d)\n",
							 [currentTube objectForKey:@"kLabel"],
							 currentScopeChannel, 
							 currentScopeCounts-startingScopeCounts);
        }
        else {
            scopeResult = kFailed;
            if(verbose) NSLogColor([NSColor redColor],@"%@ Scope channel: %d FAILED. (counts: %d)\n",
								   [currentTube objectForKey:@"kLabel"],
								   currentScopeChannel, 
								   currentScopeCounts-startingScopeCounts);
            passed = NO;
        }
    }
}


- (void) postFailedAlarm
{
    if(!failedAlarm){
        failedAlarm = [[ORAlarm alloc] initWithName:@"Cable Check Failed" severity:0];
        [failedAlarm setHelpStringFromFile:@"NcdCableCheckHelp"];
        [failedAlarm setSticky:YES];
    }
    [failedAlarm setAcknowledged:NO];
    [failedAlarm postAlarm];
    passed = NO;
}    

- (void) clearFailedAlarm
{
    [failedAlarm clearAlarm];    
}


- (void) loadPDSForCurrentTube
{
	
    @try {
        NSMutableArray* workingArray = [NSMutableArray arrayWithObjects:
										[NSNumber numberWithLong:0],
										[NSNumber numberWithLong:0],
										[NSNumber numberWithLong:0],
										[NSNumber numberWithLong:0],
										nil];
		
        unsigned short pdsBoard    = [[currentTube objectForKey:@"kPdsBoardNum"] intValue];
        unsigned short pdsChannel  = [[currentTube objectForKey:@"kPdsChan"] intValue];
        if(pdsBoard<4 && pdsChannel<16){
            NSNumber* mask  = [NSNumber numberWithLong:(1L<<pdsChannel)];
            [workingArray replaceObjectAtIndex:pdsBoard withObject:mask]; 
            pdsInRange = YES;
        }
        else {
            //NSLogColor([NSColor redColor],@"Tube %@ has out of range pds params\n",[currentTube objectForKey:@"kLabel"]);
            if(verbose)NSLog(@"Tube %@ has out of range pds params\n",[currentTube objectForKey:@"kLabel"]);
            pdsInRange = NO;
        }
        
        //load the mask to hardware...
        [thePDSModel loadHardware:workingArray];
		
	}
	@catch(NSException* localException) {
        passed = NO;
        NSLogColor([NSColor redColor],@"Vme exception for PDS.\n");
        [localException raise];
    }
}

- (void) pulsePulser
{
    [thePulserModel trigger];
    pulseCount++;
}

- (void) restoreOldValues
{
    NSArray* allShapers = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")];
    [allShapers makeObjectsPerformSelector:@selector(restoreAllThresholds)];
    [allShapers makeObjectsPerformSelector:@selector(loadThresholds)];
	
    NSArray* allMuxes = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"NcdMuxBoxModel")];
    [allMuxes makeObjectsPerformSelector:@selector(restoreAllThresholds)];
    [allMuxes makeObjectsPerformSelector:@selector(loadThresholdDacs)];
}

- (void) setNewValues
{
    NSArray* allShapers = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")];
    [allShapers makeObjectsPerformSelector:@selector(saveAllThresholds)];
    [allShapers makeObjectsPerformSelector:@selector(setAllThresholdsTo:) withObject:[NSNumber numberWithFloat:shaperThreshold]];
    [allShapers makeObjectsPerformSelector:@selector(loadThresholds)];
	
    NSArray* allMuxes = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"NcdMuxBoxModel")];
    [allMuxes makeObjectsPerformSelector:@selector(saveAllThresholds)];
    [allMuxes makeObjectsPerformSelector:@selector(setAllThresholdsTo:) withObject:[NSNumber numberWithFloat:muxThreshold]];
    [allMuxes makeObjectsPerformSelector:@selector(loadThresholdDacs)];
}

@end
