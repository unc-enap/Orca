//
//  ORHVRampModel.m
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
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

#pragma mark ¥¥¥Imported Files
#import "ORHVRampModel.h"
#import "ORHVSupply.h"
#import "ORDataPacket.h"


#pragma mark ¥¥¥Notification Strings
NSString* ORHVRampModelCurrentFileChanged		= @"ORHVRampModelCurrentFileChanged";
NSString* ORHVRampModelSaveCurrentToFileChanged = @"ORHVRampModelSaveCurrentToFileChanged";
NSString* HVPollingStateChangedNotification		= @"HVPollingStateChanged";
NSString* HVStateFileDirChangedNotification		= @"HVStateFileDirChanged";
NSString* HVRampStartedNotification				= @"HVRampStartedNotification";
NSString* HVRampStoppedNotification				= @"HVRampStoppedNotification";
NSString* HVRampCalibrationLock					= @"HVRampCalibrationLock";
NSString* HVRampLock							= @"HVRampLock";
NSString* ORHVRampModelUpdatedTrends			= @"ORHVRampModelUpdatedTrends";

#pragma mark ¥¥¥Local Strings
static NSString* ORHVRampConnector				= @"HV Ramp Connector";

@interface ORHVRampModel (private)
- (void) _setUpPolling;
- (void) _doRamp;
- (void) addCurrentToTrend:(ORHVSupply*)aSupply;
- (void) slowPoll;
- (void) postCouchDBRecord;
@end

#define kDeltaTime 0.5

@implementation ORHVRampModel

#pragma mark ¥¥¥initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	[self setDirName:@"~"];
    [self makeSupplies];
    [[self undoManager] enableUndoRegistration];
    return self;
}


#pragma mark ***Accessors

- (NSMutableArray*) currentTrends
{
    return currentTrends;
}

- (void) setCurrentTrends:(NSMutableArray*)aCurrentTrends
{
    [aCurrentTrends retain];
    [currentTrends release];
    currentTrends = aCurrentTrends;
}

- (NSString*) currentFile
{
    return currentFile;
}

- (void) setCurrentFile:(NSString*)aCurrentFile
{
	if(!aCurrentFile)aCurrentFile = @"~/HVCurrents.txt";
    [[[self undoManager] prepareWithInvocationTarget:self] setCurrentFile:currentFile];
    
    [currentFile autorelease];
    currentFile = [aCurrentFile copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHVRampModelCurrentFileChanged object:self];
}

- (BOOL) saveCurrentToFile
{
    return saveCurrentToFile;
}

- (void) setSaveCurrentToFile:(BOOL)aSaveCurrentToFile
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSaveCurrentToFile:saveCurrentToFile];
    
    saveCurrentToFile = aSaveCurrentToFile;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHVRampModelSaveCurrentToFileChanged object:self];
}

- (void) dealloc
{
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [rampTimer invalidate];
    [rampTimer release];
    rampTimer = nil;
    
    [supplies release];
    [hvPowerCycleAlarm clearAlarm];
    [hvPowerCycleAlarm release];
    
    [hvNoCurrentCheckAlarm clearAlarm];
    [hvNoCurrentCheckAlarm release];
    
    [hvNoLowPowerAlarm clearAlarm];
    [hvNoLowPowerAlarm release];
	
	[currentTrends release];
    [currentFile release];
	[lastTrendSnapShot release];
	
    [dirName release];
    [super dealloc];
}

- (void) wakeUp
{
	[self _setUpPolling];
	[super wakeUp];
    [self slowPoll];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [hvPowerCycleAlarm clearAlarm];
    [hvPowerCycleAlarm release];
    hvPowerCycleAlarm = nil;
    
    [hvNoCurrentCheckAlarm clearAlarm];
    [hvNoCurrentCheckAlarm release];
    hvNoCurrentCheckAlarm = nil;
    
    [hvNoLowPowerAlarm clearAlarm];
    [hvNoLowPowerAlarm release];
    hvNoLowPowerAlarm = nil;
	
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"HVRamp"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORHVRampController"];
}

- (NSString*) helpURL
{
	return @"NCD/HV_Control.html";
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(2,[self frame].size.height - kConnectorSize-2) withGuardian:self withObjectLink:self];
	[aConnector setConnectorType:'HVCN'];
    [[self connectors] setObject:aConnector forKey:ORHVRampConnector];
    [aConnector release];
    
}


- (void) makeSupplies
{
    [self setSupplies:[NSMutableArray arrayWithCapacity:8]];
    int i;
    for(i=0;i<8;i++){
        ORHVSupply* aSupply = [[ORHVSupply alloc] initWithOwner:self supplyNumber:i];
        [supplies addObject:aSupply];
        [aSupply release];
    }
}

- (void) initializeStates
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply controlled]){
            NSComparisonResult direction = [aSupply dacValue] - [aSupply targetVoltage];
            if(direction<0) 	 [aSupply setRampState:kHVRampUp];
            else if(direction>0) [aSupply setRampState:kHVRampDown];
            else 				 [aSupply setRampState:kHVRampIdle];
        }
        else [aSupply setRampState:kHVRampIdle];
    }
}


- (void) setPollingState:(NSTimeInterval)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollingState:pollingState];
    
    pollingState = aState;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:HVPollingStateChangedNotification
	 object: self];
    
    [self performSelector:@selector(_setUpPolling) withObject:nil afterDelay:0.5];
}


- (NSTimeInterval)	pollingState
{
    return pollingState;
}

- (ORHVSupply*) supply:(int)index
{
    return [supplies objectAtIndex:index];
}

- (NSMutableArray*)supplies
{	
    return supplies;
}

- (void) setSupplies:(NSMutableArray*)someSupplies
{
    [someSupplies retain];
    [supplies release];
    supplies = someSupplies;
}

- (void) setStates:(int)aState onlyControlled:(BOOL)onlyControlled
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if(onlyControlled && ![aSupply controlled])continue;
        [aSupply setRampState:aState];
    }
}

- (id) interfaceObj
{
    return [self objectConnectedTo:ORHVRampConnector];
}

- (void) setDirName:(NSString*)aDirName
{
	[[[self undoManager] prepareWithInvocationTarget:self] setDirName:[self dirName]];
    
	[dirName autorelease];
    dirName = [aDirName copy];
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:HVStateFileDirChangedNotification
	 object: self];
    
}

- (NSString*)dirName
{
	return dirName;
}


// ===========================================================
// - rampTimer:
// ===========================================================
- (NSTimer *)rampTimer
{
    return rampTimer; 
}

- (BOOL) hasBeenPolled 
{ 
    return hasBeenPolled;
}


#pragma mark ¥¥¥Hardware Access
- (void) turnOnSupplies:(BOOL)aState
{
    NSMutableArray* someSupplies = nil;
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply controlled]){
            if(!someSupplies){
                someSupplies = [NSMutableArray arrayWithCapacity:16];
            }
            [someSupplies addObject:aSupply];
        }
    }
    [[self interfaceObj] turnOnSupplies:someSupplies state:aState];
    [self pollHardware:self];
}


- (void) turnOffAllSupplies
{
    [[self interfaceObj] turnOnSupplies:supplies state:NO];
}

- (void) resetAdcs
{
    [[self interfaceObj] resetAdcs];
}

- (void) pollHardware:(ORHVRampModel*)theModel
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware:) object:self];

    @try { 
        
        if([self interfaceObj]){ //no sense in doing anything if not connected.
            hasBeenPolled = YES;
            
            if([self powerCycled]){
                //this means that the power has been cycled on the HV electronics
                //must reset the adcs...
                [self resetAdcs];
                
                if(!hvPowerCycleAlarm){
                    hvPowerCycleAlarm = [[ORAlarm alloc] initWithName:@"HV Power Cycled" severity:kHardwareAlarm];
                    [hvPowerCycleAlarm setSticky:NO];
                    [hvPowerCycleAlarm setHelpStringFromFile:@"HVPowerCycledHelp"];
                    [hvPowerCycleAlarm setAcknowledged:NO];
                    [hvPowerCycleAlarm postAlarm];
                    NSEnumerator* e = [[theModel supplies] objectEnumerator];
                    ORHVSupply* aSupply;
                    while(aSupply = [e nextObject]){
                        [aSupply setDacValue:0];
                        [aSupply setAdcVoltage:0];
                    }
                } 
            }
            else {
                if(hvPowerCycleAlarm && [hvPowerCycleAlarm acknowledged]){
                    [hvPowerCycleAlarm clearAlarm];
                    [hvPowerCycleAlarm release];
                    hvPowerCycleAlarm = nil;
                }
            }
            
            uint32_t aMask = [[self interfaceObj] readRelayMask];
            
			NSString* currentRecord = @"";
			if(saveCurrentToFile){
				NSDate* theDate = [NSDate date];
				currentRecord = [NSString stringWithFormat:@"%@ ",[theDate descriptionFromTemplate:@"dd/MM/yy HH:mm:ss"]];
			}
            NSEnumerator* e = [[theModel supplies] objectEnumerator];
            ORHVSupply* aSupply;
            while(aSupply = [e nextObject]){
                [aSupply setActualRelay:(aMask&(1L<<[aSupply supply]))!=0];
                if(hvPowerCycleAlarm) [aSupply setRelay:(aMask&(1L<<[aSupply supply]))!=0];
				[self checkAdcDacMismatch:aSupply];
                if([aSupply adcVoltage] < ([aSupply voltageAdcOffset]+[aSupply voltageAdcSlope]-500)){
                    [self checkCurrent:aSupply];
                }
				if(saveCurrentToFile){
					currentRecord = [currentRecord stringByAppendingFormat:@"%2d ",[aSupply current]];
				}
				
				[self addCurrentToTrend:aSupply];
				
            }
			if(![[self interfaceObj] lowPowerOn]){
				if(!hvNoLowPowerAlarm){
					hvNoLowPowerAlarm = [[ORAlarm alloc] initWithName:@"HV No Low Power" severity:kHardwareAlarm];
					[hvNoLowPowerAlarm setSticky:YES];
					[hvNoLowPowerAlarm setAcknowledged:NO];
					[hvNoLowPowerAlarm postAlarm];
				}
			}
			else {
				if(hvNoLowPowerAlarm){
					[hvNoLowPowerAlarm clearAlarm];
					[hvNoLowPowerAlarm release];
					hvNoLowPowerAlarm = nil;
				}
			}
			
			if(saveCurrentToFile){
				NSDate* now = [NSDate date];
				if(!lastTrendSnapShot || [now timeIntervalSinceDate:lastTrendSnapShot] >= 60){
					[lastTrendSnapShot release];
					lastTrendSnapShot = [now retain];
					NSFileManager* fm = [NSFileManager defaultManager];
					NSString* fullPath = [currentFile stringByExpandingTildeInPath];
					if(![fm fileExistsAtPath:fullPath]){
						[fm createFileAtPath:fullPath contents:nil attributes:nil];
					}
					NSFileHandle* fh = [NSFileHandle fileHandleForUpdatingAtPath:fullPath];
					[fh seekToEndOfFile];
					currentRecord = [currentRecord stringByAppendingString:@"\n"];
					[fh writeData:[currentRecord dataUsingEncoding:NSASCIIStringEncoding]];
					[[NSNotificationCenter defaultCenter]
					 postNotificationName:ORHVRampModelUpdatedTrends
					 object: self];
				}
			}
        }
    }
	
	@catch(NSException* localException) {  
        //catch this here to prevent it from falling thru, but nothing to do.
		
	}
	if(pollingState!=0){
		[self performSelector:@selector(pollHardware:) withObject:self afterDelay:pollingState];
	}
}

- (void) checkCurrent:(ORHVSupply*) aSupply
{
    [[self interfaceObj] readCurrent:aSupply];
    if([aSupply currentIsHigh:self pollingTime:pollingState]){
        
        NSLog(@"Supply %d panic to zero due to high current\n",[aSupply supply]);
        [aSupply  setRampState:kHVRampPanic];
        [self startRamping];	
    }
}

- (void) checkAdcDacMismatch:(ORHVSupply*) aSupply
{
    [[self interfaceObj] readAdc:aSupply];
    [aSupply checkAdcDacMismatch:self pollingTime:pollingState];
}


- (int) currentTrendCount:(int)index 
{
	return (int)[[currentTrends objectAtIndex:index] count];
}

- (float) currentValue:(int)index supply:(int)aSupplyIndex
{
	return [[[currentTrends objectAtIndex:aSupplyIndex] objectAtIndex:index] floatValue];
}


#pragma mark ¥¥¥Status

-(unsigned short) relayOnMask
{
    unsigned short mask = 0;
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply actualRelay]){
            mask |= (1<<[aSupply supply]);
        }
    }
    return mask;
}
-(BOOL) anyRelaysSetOn
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply actualRelay])return YES;
    }
    return NO;
}

-(BOOL) anyRelaysSetOnControlledSupplies
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply controlled] && [aSupply actualRelay])return YES;
    }
    return NO;
}

-(BOOL) anyVoltageOnControlledSupplies
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply controlled] && ([aSupply adcVoltage]>30))return YES;
    }
    return NO;
}

-(BOOL) anyVoltageOn
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply adcVoltage]>30)return YES;
    }
    return NO;
}


-(BOOL) anyControlledSupplies
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply controlled])return YES;
    }
    return NO;
}


-(BOOL) voltageOnAllControlledSupplies
{
    BOOL atLeastOne = NO;
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply controlled]){
            if(([aSupply adcVoltage]<=5))return NO;
            else atLeastOne = YES;
        }
    }
    return atLeastOne;
}

-(BOOL) allRelaysSetOnControlledSupplies
{
    BOOL atLeastOne = NO;
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply controlled]){
            if(![aSupply actualRelay])return NO;
            else atLeastOne = YES;
        }
    }
    return atLeastOne;
}

-(BOOL) allRelaysOffOnControlledSupplies
{
    BOOL atLeastOne = NO;
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply controlled]){
            if([aSupply actualRelay])return NO;
            else atLeastOne = YES;
        }
    }
    return atLeastOne;
}

-(BOOL) powerCycled
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply adcVoltage] > ([aSupply voltageAdcOffset]+[aSupply voltageAdcSlope]-50)){
            return YES;
        }
    }
    return NO;
}

// read/write status access methods
- (BOOL) controlled:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] controlled];
}

- (void) setControlled:(short) aSupplyIndex value:(BOOL)aState
{
    [[supplies objectAtIndex:aSupplyIndex] setControlled:aState];
}

- (int)  rampTime:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] rampTime];
}

- (void)  setRampTime:(short) aSupplyIndex value:(int)aValue
{
    [[supplies objectAtIndex:aSupplyIndex] setRampTime:aValue];
}

- (int)  targetVoltage:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] targetVoltage];
}

- (void)  setTargetVoltage:(short) aSupplyIndex value:(int)aValue
{
    [[supplies objectAtIndex:aSupplyIndex] setTargetVoltage:aValue];
}

//read only supply methods
- (int)  dacValue:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] dacValue];
}

- (int)  adcVoltage:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] adcVoltage];
}

- (int)  current:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] current];
}

- (int) rampState:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] rampState];
}

- (void) addCurrentToTrend:(ORHVSupply*)aSupply
{
	if(!currentTrends){
		[self setCurrentTrends:[NSMutableArray array]];
		int i;
		for(i=0;i<8;i++)[currentTrends addObject:[NSMutableArray array]];
	}
	[[currentTrends objectAtIndex:[aSupply supply]] addObject:[NSNumber numberWithInt:[aSupply current]]];
	if([[currentTrends objectAtIndex:[aSupply supply]] count] > 2000){
		[[currentTrends objectAtIndex:[aSupply supply]] removeObjectsInRange:NSMakeRange(0,500)];
	}
}

#pragma mark ¥¥¥Polling
- (void) _setUpPolling
{
    if(pollingState!=0){        
        NSLog(@"Polling HV every %.0f seconds.\n",pollingState);
		[self pollHardware:self];
		[hvNoCurrentCheckAlarm clearAlarm];
    }
    else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
    	NSLog(@"HV NOT being Polled.\n");
		if(!hvNoCurrentCheckAlarm){
			hvNoCurrentCheckAlarm = [[ORAlarm alloc] initWithName:@"HV Current Not Checked (Polling Off)" severity:kSetupAlarm];
			[hvNoCurrentCheckAlarm setSticky:YES];
			[hvNoCurrentCheckAlarm setHelpStringFromFile:@"HVNotPollingHelp"];
		}                      
		[hvNoCurrentCheckAlarm setAcknowledged:NO];
		[hvNoCurrentCheckAlarm postAlarm];
        
    }
}

#pragma mark ¥¥¥Archival

static NSString *ORHVSupplies 		= @"ORHVSupplies";
static NSString *ORHVPollingState 	= @"ORHVPollingState";
static NSString *ORHVDirName 		= @"ORHVDirName";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setCurrentFile:[decoder decodeObjectForKey:@"ORHVRampModelCurrentFile"]];
    [self setSaveCurrentToFile:[decoder decodeBoolForKey:@"ORHVRampModelSaveCurrentToFile"]];
    [self setSupplies:[decoder decodeObjectForKey:ORHVSupplies]];
    [self setPollingState:[decoder decodeIntegerForKey:ORHVPollingState]];
    [self setDirName:[decoder decodeObjectForKey:ORHVDirName]];
    if(dirName == nil){
        [self setDirName:@"~"];
    }
    NSEnumerator* e = [supplies objectEnumerator];
    id s;
    while(s = [e nextObject]){
        [s setOwner:self];
    }
    
    
    [self loadHVParams];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:currentFile forKey:@"ORHVRampModelCurrentFile"];
    [encoder encodeBool:saveCurrentToFile forKey:@"ORHVRampModelSaveCurrentToFile"];
    [encoder encodeObject:[self supplies] forKey:ORHVSupplies];
    [encoder encodeInteger:[self pollingState] forKey:ORHVPollingState];
    [encoder encodeObject:[self dirName] forKey:ORHVDirName];
}



- (void) wakeup
{
    [super wakeUp];
    [[self undoManager] disableUndoRegistration];
    [self loadHVParams];
    [[self undoManager] enableUndoRegistration];
}

//special archiving for the target values and dac values. There are kept separate from
//the regular document. these values are saved whenever there is change in the HV state.

- (void)loadHVParams
{	
    
    NSString* fullFileName = [[[self dirName]stringByExpandingTildeInPath] 
							  stringByAppendingPathComponent:[self stateFileName]];
    NSData*		data 	= [NSData dataWithContentsOfFile:fullFileName];
    
    if(data){
        NSKeyedUnarchiver*  decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        NSEnumerator* e = [supplies objectEnumerator];
        ORHVSupply* aSupply;
        while(aSupply = [e nextObject]){
            [aSupply loadHVParams:decoder];
        }
        
        [decoder finishDecoding];
        [decoder release];
    }
}

- (void)saveHVParams
{
    
    NSMutableData*   data 	 = [NSMutableData data];
    NSKeyedArchiver* encoder = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        [aSupply saveHVParams:encoder];
    }
    [encoder finishEncoding];
    
    NSString* fullFileName = [[[self dirName]stringByExpandingTildeInPath] stringByAppendingPathComponent:[self stateFileName]];
    [data writeToFile:fullFileName atomically:YES];
    [encoder release];
    
}

- (NSString*) stateFileName
{
    return [NSString stringWithFormat:@"HVState%u",[self uniqueIdNumber]];
}

#pragma mark ¥¥¥Safety Check
- (BOOL) checkActualVsSetValues
{
    BOOL allOK = YES;
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if(![aSupply checkActualVsSetValues]){
            allOK = NO;
            break;
        }
    }
    return allOK;
}

- (void) forceDacToAdc
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        [aSupply resolveActualVsSetValueProblem];
    }
}

- (void) resolveActualVsSetValueProblem 
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    while(aSupply = [e nextObject]){
        if(![aSupply checkActualVsSetValues]){
            [aSupply resolveActualVsSetValueProblem];
        }
    }
}

#pragma mark ¥¥¥Run Data

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class])        forKey:@"Class Name"];
    [supplies makeObjectsPerformSelector:@selector(addParametersToDictionary:) withObject:objDictionary];
    
    [dictionary setObject:objDictionary forKey:@"High Voltage"];
    
    
    return objDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    
    
}

- (void) startRamping
{
    
    if(!rampTimer){
        
        [self resetAdcs];
        
        rampTimer = [[NSTimer scheduledTimerWithTimeInterval:kDeltaTime target:self selector:@selector(doRamp) userInfo:nil repeats:YES] retain];
        [[NSNotificationCenter defaultCenter]
		 postNotificationName:HVRampStartedNotification
		 object: self];
    }
}

- (void) stopRamping
{
    [rampTimer invalidate];
    [rampTimer release];
    rampTimer = nil;
    [self setStates:kHVRampIdle onlyControlled:NO];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:HVRampStoppedNotification
	 object: self];
    
}

- (void) doRamp
{
    
    int unitStep;
    
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* hvSupply;
    BOOL atLeastOne = NO;
    
    while(hvSupply = [e nextObject]){
        
        int totalRampTime 	 = [hvSupply rampTime];
        int theDACVoltage 	 = [hvSupply dacValue];
        int theTargetVoltage = [hvSupply targetVoltage];			
        int theState = [hvSupply rampState];
        if(theState == kHVRampUp ){
            if(theTargetVoltage!=0){
                float voltsToGo = (theTargetVoltage- theDACVoltage);
                float timeToGo = totalRampTime * voltsToGo/theTargetVoltage;
                if(timeToGo!=0){
                    unitStep = (kDeltaTime * voltsToGo/timeToGo)+.5;
                    if(unitStep<1)unitStep=1;
                }
                else unitStep = 1;
            }
            else unitStep = 10;
            
            int theValueToSet = theDACVoltage + unitStep;
            
            if( theValueToSet >= theTargetVoltage ) {
                theValueToSet = theTargetVoltage;
                [hvSupply setRampState:kHVRampDone];
            }
            atLeastOne	= YES;
            [[self interfaceObj] writeDac:theValueToSet supply:hvSupply];
        }
        else if(theState == kHVRampDown || theState == kHVRampPanic || theState == kHVRampZero){
            int theTargetVoltage;
            
            if(theState == kHVRampDown){
                theTargetVoltage = [hvSupply targetVoltage];
                unitStep = 10;
            }
            else {
                theTargetVoltage = 0;
                unitStep = 10;
            }
            
            int theValueToSet = theDACVoltage - unitStep;
            
            if( theValueToSet <= theTargetVoltage ) {
                theValueToSet = theTargetVoltage;
                [[self interfaceObj] writeDac:theValueToSet supply:hvSupply];
                if(theState == kHVRampPanic){
                    [hvSupply setRampState:kHVWaitForAdc];
                }
                else [hvSupply setRampState:kHVRampDone];
            }
            else [[self interfaceObj] writeDac:theValueToSet supply:hvSupply];
            
            atLeastOne = YES;
        }
        else if(theState == kHVWaitForAdc){
            if([hvSupply adcVoltage]<22){
                [[self interfaceObj] turnOnSupplies:[NSArray arrayWithObject:hvSupply] state:NO];
                [hvSupply setRampState:kHVRampDone];
            }
            else atLeastOne = YES;
        }
        [[self interfaceObj] readAdc:hvSupply];
        [self checkCurrent:hvSupply];
    }
    
    [self pollHardware:self];
    [self saveHVParams];
    
    if(!atLeastOne){
        [self stopRamping];
    }
    
    
}

//a no-checks panic method, mainly included for use by remote systems.
- (void) panic
{
    [self setStates:kHVRampPanic onlyControlled:NO];
    [self startRamping];
}

- (void) slowPoll
{
    [self postCouchDBRecord];
    [self performSelector:@selector(slowPoll) withObject:nil afterDelay:30.0];
}

- (void) postCouchDBRecord
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHVSupply* aSupply;
    NSMutableArray* theSupplies = [NSMutableArray array];
    
    while(aSupply = [e nextObject]){
        [theSupplies addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSNumber numberWithInteger:[aSupply actualRelay]],@"relayState",
          [NSNumber numberWithInteger:[aSupply rampState]],@"rampState",
          [NSNumber numberWithInteger:[aSupply rampTime]],@"rampTime",
          [NSNumber numberWithInteger:[aSupply targetVoltage]],@"targetVoltage",
          [NSNumber numberWithInteger:[aSupply dacValue]],@"daqValue",
          [NSNumber numberWithInteger:[aSupply adcVoltage]],@"adcVoltage",
          [NSNumber numberWithInteger:[aSupply current]],@"current",
        nil]];
    }
    
    NSDictionary* values = [NSDictionary dictionaryWithObjectsAndKeys:
                            theSupplies, @"supplies",
                            [NSNumber numberWithBool:[self anyVoltageOn]],@"HvStatus",
                            nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
}

@end
