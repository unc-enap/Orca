//
//  ORMJDVacuumModel.m
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
//  Copyright © 2012 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark •••Imported Files
#import "ORMJDVacuumModel.h"
#import "ORMJDVacuumView.h"
#import "ORProcessModel.h"
#import "ORAdcModel.h"
#import "ORAdcProcessing.h"
#import "ORMks660BModel.h"
#import "ORRGA300Model.h"
#import "ORTM700Model.h"
#import "ORTPG256AModel.h"
#import "ORCP8CryopumpModel.h"
#import "ORLakeShore210Model.h"
#import "ORLakeShore336Model.h"
#import "ORLakeShore336Input.h"
#import "ORAlarm.h"
#import "ORRunningAverageGroup.h"


@interface ORMJDVacuumModel (private)
- (void) makeParts;
- (void) remakeParts;
- (void) makeLines:(VacuumLineStruct*)lineItems num:(int)numItems;
- (void) makePipes:(VacuumPipeStruct*)pipeList num:(int)numItems;
- (void) makeGateValves:(VacuumGVStruct*)pipeList num:(int)numItems;
- (void) makeStaticLabels:(VacuumStaticLabelStruct*)labelItems num:(int)numItems;
- (void) makeDynamicLabels:(VacuumDynamicLabelStruct*)labelItems num:(int)numItems;
- (void) makeTempGroups:(TempGroup*)labelItems num:(int)numItems;
- (void) colorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor;
- (void) recursizelyColorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor;
- (void) resetVisitationFlag;
- (void) addConstraintName:(NSString*)aName reason:(NSString*)aReason toGateValve:(id)aGateValve;
- (void) removeConstraintName:(NSString*)aName fromGateValve:(id)aGateValve;

- (void) onAllGateValvesremoveConstraintName:(NSString*)aConstraintName;
- (void) checkAllConstraints;
- (void) deferredConstraintCheck;
- (void) checkCloseConditionOnCF6;
- (void) checkTurboRelatedConstraints:(ORTM700Model*) turbo;
- (void) checkCryoPumpRelatedConstraints:(ORCP8CryopumpModel*) cryoPump;
- (void) checkRGARelatedConstraints:(ORRGA300Model*) rga;
- (void) checkPressureConstraints;
- (void) checkDetectorConstraints;
- (double) valueForRegion:(int)aRegion;
- (ORVacuumValueLabel*) regionValueObj:(int)aRegion;
- (BOOL) valueValidForRegion:(int)aRegion;
- (BOOL) region:(int)aRegion valueHigherThan:(double)aValue;
- (void) postCouchRecord;
- (void) resetHvTimer;

- (id)                  findLakeShore;
- (ORMks660BModel*)     findBaratron;
- (ORRGA300Model*)      findRGA;
- (ORTM700Model*)       findTurboPump;
- (ORTPG256AModel*)     findPressureGauge;
- (ORCP8CryopumpModel*) findCryoPump;
- (id)                  findObject:(NSString*)aClassName;
@end

NSString* ORMJDVacuumModelNoHvInfoChanged               = @"ORMJDVacuumModelNoHvInfoChanged";
NSString* ORMJDVacuumModelVetoMaskChanged               = @"ORMJDVacuumModelVetoMaskChanged";
NSString* ORMJDVacuumModelShowGridChanged               = @"ORMJDVacuumModelShowGridChanged";
NSString* ORMJCVacuumLock                               = @"ORMJCVacuumLock";
NSString* ORMJDVacuumModelShouldUnbiasDetectorChanged   = @"ORMJDVacuumModelShouldUnbiasDetectorChanged";
NSString* ORMJDVacuumModelOkToBiasDetectorChanged       = @"ORMJDVacuumModelOkToBiasDetectorChanged";
NSString* ORMJDVacuumModelDetectorsBiasedChanged        = @"ORMJDVacuumModelDetectorsBiasedChanged";
NSString* ORMJDVacuumModelConstraintsChanged            = @"ORMJDVacuumModelConstraintsChanged";
NSString* ORMJDVacuumModelNextHvUpdateTimeChanged       = @"ORMJDVacuumModelNextHvUpdateTimeChanged";
NSString* ORMJDVacuumModelLastHvUpdateTimeChanged       = @"ORMJDVacuumModelLastHvUpdateTimeChanged";
NSString* ORMJDVacuumModelHvUpdateTimeChanged           = @"ORMJDVacuumModelHvUpdateTimeChanged";
NSString* ORMJDVacuumModelConstraintsDisabledChanged    = @"ORMJDVacuumModelConstraintsDisabledChanged";
NSString* ORMJDVacuumModelCoolerModeChanged             = @"ORMJDVacuumModelCoolerModeChanged";

NSString* ORMJDVacuumModelSpikeTriggerValueChanged      = @"ORMJDVacuumModelSpikeTriggerValueChanged";

@implementation ORMJDVacuumModel

#pragma mark •••initialization
- (void) wakeUp
{
    [super wakeUp];
	[self registerNotificationObservers];

}

- (void) sleep
{
    [super sleep];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];

}

- (void) dealloc
{
    [nextHvUpdateTime release];
    [lastHvUpdateTime release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[parts release];
	[partDictionary release];
	[adcMapArray release];
	[valueDictionary release];
	[orcaClosedCryoPumpValveAlarm clearAlarm];
	[orcaClosedCryoPumpValveAlarm release];
	[orcaClosedCF6TempAlarm clearAlarm];
	[orcaClosedCF6TempAlarm release];
    [vacuumRunningAverages release];
	[super dealloc];
}

- (void) setVacuumRunningAverages:(ORRunningAverageGroup*)newRunningAverageGroup
{
    [newRunningAverageGroup retain];
    [vacuumRunningAverages release];
    vacuumRunningAverages = newRunningAverageGroup;
}

- (void) vacuumSpikeChanged:(NSNotification*)aNote
{
    ORRunningAveSpike* spikeObj = [[aNote userInfo] objectForKey:@"SpikeObject"];
    int regionIndex = (int)[spikeObj tag];
    if(regionIndex>=0 && regionIndex <kNumberRegions){
        vacuumSpike[regionIndex] = [spikeObj spiked];
    }
}

- (BOOL) vacuumSpike
{
    return vacuumSpike[kRegionCryostat] && vacuumSpike[kRegionRGA] && vacuumSpike[kRegionAboveTurbo];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"MJDVacuum.tif"]];
}

- (NSString*) helpURL
{
	return nil;
}

- (void) makeMainController
{
    [self linkToController:@"ORMJDVacuumController"];
}

- (void) addObjects:(NSArray*)someObjects
{
	[super addObjects:someObjects];
	[self checkAllConstraints];
    [self registerNotificationObservers];
}

- (void) removeObjects:(NSArray*)someObjects
{
	[super removeObjects:someObjects];
	[self checkAllConstraints];
    [self registerNotificationObservers];
}

- (void) registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	//we need to know about a specific set of events in order to handle the constraints
	ORMks660BModel*       baratron  = [self findBaratron];
    id                    lakeShore = [self findLakeShore];
    
    //should have just one or the other..... baratron or lakeshore not both
	if(baratron){
		[notifyCenter addObserver : self
						 selector : @selector(baratronChanged:)
							 name : ORMks660BPressureChanged
						   object : baratron];

		[notifyCenter addObserver : self
						 selector : @selector(baratronChanged:)
							 name : ORSerialPortWithQueueModelIsValidChanged
						   object : baratron];
	}

	if(lakeShore){
        if([lakeShore isKindOfClass:NSClassFromString(@"ORLakeShore336Model")]){
            [notifyCenter addObserver : self
                             selector : @selector(lakeShoreChanged:)
                                 name : ORLakeShore336InputTemperatureChanged
                               object : nil];
            
            [notifyCenter addObserver : self
                             selector : @selector(lakeShoreChanged:)
                                 name : ORLakeShore336IsValidChanged
                               object : lakeShore];
        }
        else {
            [notifyCenter addObserver : self
                             selector : @selector(lakeShoreChanged:)
                                 name : ORLakeShore210TempChanged
                               object : nil];
            
            [notifyCenter addObserver : self
                             selector : @selector(lakeShoreChanged:)
                                 name : ORSerialPortWithQueueModelIsValidChanged
                               object : lakeShore];
           
        }
	}

    
	ORTM700Model* turbo = [self findTurboPump];
	if(turbo){
		[notifyCenter addObserver : self
						 selector : @selector(turboChanged:)
							 name : ORTM700ModelStationPowerChanged
						   object : turbo];
		
		[notifyCenter addObserver : self
						 selector : @selector(turboChanged:)
							 name : ORSerialPortWithQueueModelIsValidChanged
						   object : turbo];
	}
	
	ORTPG256AModel* pressureGauge = [self findPressureGauge];
	if(pressureGauge){
		[notifyCenter addObserver : self
						 selector : @selector(pressureGaugeChanged:)
							 name : ORTPG256APressureChanged
						   object : pressureGauge];
		
		[notifyCenter addObserver : self
						 selector : @selector(pressureGaugeChanged:)
							 name : ORSerialPortWithQueueModelIsValidChanged
						   object : pressureGauge];
	}

	ORCP8CryopumpModel* cryoPump = [self findCryoPump];
	if(cryoPump){
		[notifyCenter addObserver : self
						 selector : @selector(cryoPumpChanged:)
							 name : ORCP8CryopumpModelPumpStatusChanged
						   object : cryoPump];
		
		[notifyCenter addObserver : self
						 selector : @selector(cryoPumpChanged:)
							 name : ORSerialPortWithQueueModelIsValidChanged
						   object : cryoPump];

		[notifyCenter addObserver : self
						 selector : @selector(cryoPumpChanged:)
							 name : ORCP8CryopumpModelSecondStageTempChanged
						   object : cryoPump];
		
	}
	
	ORRGA300Model* rga = [self findRGA];
	if(rga){
		[notifyCenter addObserver : self
						 selector : @selector(rgaChanged:)
							 name : ORRGA300ModelIonizerFilamentCurrentRBChanged
						   object : rga];
		
		[notifyCenter addObserver : self
						 selector : @selector(rgaChanged:)
							 name : ORSerialPortWithQueueModelIsValidChanged
						   object : rga];
	}
	
	[notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORVacuumPartChanged
						object: self];
	
	[notifyCenter addObserver : self
                     selector : @selector(portClosedAfterTimeout:)
                         name : ORSerialPortWithQueueModelPortClosedAfterTimeout
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(vacuumSpikeChanged:)
                         name : ORSpikeStateChangedNotification
                       object : vacuumRunningAverages];
    
}

- (void) portClosedAfterTimeout:(NSNotification*)aNote
{
	if([aNote object] && [aNote object] == [self findCryoPump]){
		//the serial port was closed by ORCA after a timeout. Need to close the GateValve to the cryostat
		ORVacuumGateValve* gv = [self gateValve:3];
		if([gv isOpen]){
			[self closeGateValve:3];
			NSLog(@"ORCA closed the gatevalve between the cryopump and the cryostat because of a serial port timeout\n");
			if(!orcaClosedCryoPumpValveAlarm){
				NSString* alarmName = [NSString stringWithFormat:@"ORCA Closed %@",[gv label]];
				orcaClosedCryoPumpValveAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kHardwareAlarm];
				[orcaClosedCryoPumpValveAlarm setHelpString:@"ORCA closed the valve because of a serial port timeout on the cryopump. Acknowledging this alarm will clear it."];
				[orcaClosedCryoPumpValveAlarm setSticky:NO];
			}
			[orcaClosedCryoPumpValveAlarm postAlarm];
		}
	}
}

- (void) baratronChanged:(NSNotification*)aNote
{
    //if([self coolerMode] == kThermosyphon){ //changed to always display value
        ORMks660BModel* baratron         = [aNote object];
        ORVacuumValueLabel* aRegionlabel = [self regionValueObj:kRegionBaratron];
        [aRegionlabel setValue:  [baratron pressure]];
        [aRegionlabel setIsValid:[baratron isValid]];
    //}
}

- (void) lakeShoreChanged:(NSNotification*)aNote
{
    id lakeShore = [self findLakeShore];
    if([lakeShore isKindOfClass:NSClassFromString(@"ORLakeShore336Model")]){
        if([aNote object] == [(ORLakeShore336Model*)lakeShore input:0]){ //make sure the value is coming from input A
            ORVacuumValueLabel* aRegionlabel    = [self regionValueObj:kRegionLakeShore];
            [aRegionlabel setValue:  [(ORLakeShore336Model*)lakeShore convertedValue:0]];
            [aRegionlabel setIsValid:[(ORLakeShore336Model*)lakeShore isValid]];
        }
    }
    else {
        if([aNote object] == (ORLakeShore210Model*)lakeShore){
            ORVacuumValueLabel* aRegionlabel    = [self regionValueObj:kRegionLakeShore];
            [aRegionlabel setValue:  [(ORLakeShore210Model*)lakeShore convertedValue:7]];
            [aRegionlabel setIsValid:[(ORLakeShore210Model*)lakeShore isValid]];

            ORVacuumTempGroup* aTempGroup    = (ORVacuumTempGroup*)[self regionValueObj:kLakeShoreTemps];
            int i;
            for(i=0;i<8;i++){
                [aTempGroup setTemp:i  value:[(ORLakeShore210Model*)lakeShore convertedValue:i]];
                [aTempGroup setIsValid:[(ORLakeShore210Model*)lakeShore isValid]];
            }
        }
    }
}


- (void) turboChanged:(NSNotification*)aNote
{
	ORTM700Model* turboPump = [aNote object];
    ORVacuumStatusLabel* turboRegionObj = [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionAboveTurbo]];
	[turboRegionObj setIsValid:[turboPump isValid]];
	[turboRegionObj setStatusLabel:[turboPump auxStatusString:0]];	

	[self checkTurboRelatedConstraints:turboPump];
}

- (void) pressureGaugeChanged:(NSNotification*)aNote
{
	ORTPG256AModel* pressureGauge = [aNote object];
	int chan = [[[aNote userInfo] objectForKey:@"Channel"]intValue];
	int componentTag = (int)[pressureGauge tag];
	int aRegion;
	for(aRegion=0;aRegion<kNumberRegions;aRegion++){
		ORVacuumValueLabel*  aLabel = [self regionValueObj:aRegion]; 
		if([aLabel channel] == chan && [aLabel component] == componentTag){
			[aLabel setIsValid:[pressureGauge isValid]];
            float thePressure = [pressureGauge pressure:chan];
			[aLabel setValue: thePressure];
            [vacuumRunningAverages addNewValue:thePressure toIndex:chan];
		}
	}
	//special case... if the cryo roughing valve is open set the diaphram pump pressure to the cryopump region
	//other wise set it to 2 Torr
	ORVacuumGateValve* gv = [self gateValve:5];
	ORVacuumValueLabel* aRegionlabel = [self regionValueObj:kRegionDiaphramPump];
	if([gv isClosed]){
		[aRegionlabel setValue:2.0];
		[aRegionlabel setIsValid:YES];
	}
	[self checkPressureConstraints];
	[self checkDetectorConstraints];
}

- (void) cryoPumpChanged:(NSNotification*)aNote
{
	ORCP8CryopumpModel* cryopump = [aNote object];
	ORVacuumStatusLabel* cryoRegionObj = [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionCryoPump]];
	[cryoRegionObj setIsValid:[cryopump isValid]];
	[cryoRegionObj setStatusLabel:[cryopump auxStatusString:0]];	
	[self checkCryoPumpRelatedConstraints:cryopump];
	[self checkPressureConstraints];
}

- (void) rgaChanged:(NSNotification*)aNote
{
	ORRGA300Model* rga = [aNote object];
	ORVacuumStatusLabel* rgaRegionObj = [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionRGA]];
	[rgaRegionObj setIsValid:[rga isValid]];
	[rgaRegionObj setStatusLabel:[rga auxStatusString:0]];	
	[self checkRGARelatedConstraints:rga];
}

- (void) stateChanged:(NSNotification*)aNote
{
	[self  checkAllConstraints];
}

#pragma mark ***Accessors
- (int) coolerMode
{
    return coolerMode;
}

- (void) setCoolerMode:(int)aCoolerMode
{
    if(aCoolerMode!=coolerMode){
        [[[self undoManager] prepareWithInvocationTarget:self] setCoolerMode:coolerMode];
        coolerMode = aCoolerMode;
        //[self remakeParts];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelCoolerModeChanged object:self];
    }
}

- (BOOL)    noHvInfo         { return noHvInfo;         }
- (NSDate*) nextHvUpdateTime { return nextHvUpdateTime; }
- (NSDate*) lastHvUpdateTime { return lastHvUpdateTime; }
- (int)     hvUpdateTime     { return hvUpdateTime;     }

- (void)    setNoHvInfo      { [self setNoHvInfo:YES];  }
- (void)    clearNoHvInfo    { [self setNoHvInfo:NO];   }

- (void) setNoHvInfo:(BOOL)aNoHvInfo
{
    noHvInfo = aNoHvInfo;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelNoHvInfoChanged object:self];
}

- (void) setNextHvUpdateTime:(NSDate*)aNextHvUpdateTime
{
    [aNextHvUpdateTime retain];
    [nextHvUpdateTime release];
    nextHvUpdateTime = aNextHvUpdateTime;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelNextHvUpdateTimeChanged object:self];
}

- (void) setLastHvUpdateTime:(NSDate*)aLastHvUpdateTime
{
    [aLastHvUpdateTime retain];
    [lastHvUpdateTime release];
    lastHvUpdateTime = aLastHvUpdateTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelLastHvUpdateTimeChanged object:self];
}


- (void) setHvUpdateTime:(int)aHvUpdateTime
{
    hvUpdateTime = aHvUpdateTime;
    [self resetHvTimer];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelHvUpdateTimeChanged object:self];
}

- (BOOL)    shouldUnbiasDetector	{ return [continuedBiasConstraints count] != 0; }
- (BOOL)    okToBiasDetector		{ return [okToBiasConstraints count] == 0; }
//- (BOOL)    shouldUnbiasDetector	{ return NO; }  //for testing
//- (BOOL)    okToBiasDetector		{ return YES; } //for testing
- (BOOL)    detectorsBiased         { return detectorsBiased;       }

//-------------------------------------------------------------------
//This method is typically only called from a remote ORCA to tell us
//the state of the HV so we will use it to clear a deadman timeout
- (void) setDetectorsBiased:(BOOL)aState
{
    NSDate* now = [NSDate date];
    [self setLastHvUpdateTime:now];
 
    [self resetHvTimer];

	if(detectorsBiased!=aState){
		detectorsBiased = aState;
		[self checkDetectorConstraints];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelDetectorsBiasedChanged object:self];
	}
}
//-------------------------------------------------------------------

- (uint32_t) vetoMask { return vetoMask; }

- (void) setVetoMask:(uint32_t)aVetoMask
{
	if(vetoMask != aVetoMask){
		vetoMask = aVetoMask;
		NSArray* gateValves = [self gateValves];
		for(ORVacuumGateValve* aGateValve in gateValves){
			int tag = [aGateValve partTag];
			if(vetoMask & (0x1<<tag))aGateValve.vetoed = YES;
			else aGateValve.vetoed = NO;
		}
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORMJDVacuumModelVetoMaskChanged object:self];
	}
}

- (void) toggleGrid { [self setShowGrid:!showGrid]; }
- (BOOL) showGrid   { return showGrid; }

- (void) setShowGrid:(BOOL)aShowGrid
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowGrid:showGrid];
    showGrid = aShowGrid;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelShowGridChanged object:self];
}

- (float) spikeTriggerValue
{
    return spikeTriggerValue;
}

- (void)  setSpikeTriggerValue:(float)aValue
{
    if(aValue<100)aValue = 115;
    [[[self undoManager] prepareWithInvocationTarget:self] setSpikeTriggerValue:spikeTriggerValue];
    spikeTriggerValue = aValue;
    [vacuumRunningAverages setTriggerValue:spikeTriggerValue];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelSpikeTriggerValueChanged object:self];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setCoolerMode:        [decoder decodeIntForKey:@"coolerMode"]];
	[self setShowGrid:          [decoder decodeBoolForKey:	@"showGrid"]];
    [self setSpikeTriggerValue: [decoder decodeFloatForKey: @"spikeTriggerValue"]];
	[self makeParts];
	[self registerNotificationObservers];
	
	[[self undoManager] enableUndoRegistration];
    

    [self setVacuumRunningAverages:[[[ORRunningAverageGroup alloc] initGroup:kNumberRegions groupTag:0 withLength:10] autorelease]];
    
    [vacuumRunningAverages resetCounters:0];
    [vacuumRunningAverages setTriggerType:kRASpikeOnRatio];
    [vacuumRunningAverages setTriggerValue:spikeTriggerValue]; //++++++++anything below 1 is for TEST since it will alway fire
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:coolerMode           forKey:@"coolerMode"];
    [encoder encodeBool:showGrid            forKey: @"showGrid"];
    [encoder encodeFloat:spikeTriggerValue  forKey: @"spikeTriggerValue"];
}

- (NSArray*) parts
{
	return parts;
}

- (NSArray*) gateValvesConnectedTo:(int)aRegion
{
	NSMutableArray* gateValves	= [NSMutableArray array];
	NSArray* allGateValves		= [self gateValves];
	for(id aGateValve in allGateValves){
		if([aGateValve connectingRegion1] == aRegion || [aGateValve connectingRegion2] == aRegion){
			if([aGateValve controlType] != kManualOnlyShowClosed && [aGateValve controlType] != kManualOnlyShowChanging){
				[gateValves addObject:aGateValve];
			}
		}
	}
	return gateValves;
}

- (int) stateOfGateValve:(int)aTag
{
	return [[self gateValve:aTag] state];
}

- (NSArray*) pipesForRegion:(int)aTag
{
	return [[partDictionary objectForKey:@"Regions"] objectForKey:[NSNumber numberWithInt:aTag]];
}

- (ORVacuumPipe*) onePipeFromRegion:(int)aTag
{
	NSArray* pipes = [[partDictionary objectForKey:@"Regions"] objectForKey:[NSNumber numberWithInt:aTag]];
	if([pipes count])return [pipes objectAtIndex:0];
	else return nil;
}

- (NSArray*) gateValves
{
	return [partDictionary objectForKey:@"GateValves"];
}

- (ORVacuumGateValve*) gateValve:(int)index
{
	NSArray* gateValues = [partDictionary objectForKey:@"GateValves"];
	if(index<[gateValues count]){
		return [[partDictionary objectForKey:@"GateValves"] objectAtIndex:index];
	}
	else return nil;
}

- (NSArray*) valueLabels
{
	return [partDictionary objectForKey:@"ValueLabels"];
}

- (NSArray*) statusLabels
{
	return [partDictionary objectForKey:@"StatusLabels"];
}

- (NSString*) valueLabel:(int)region
{
	NSArray* labels = [partDictionary objectForKey:@"ValueLabels"];
	for(ORVacuumValueLabel* theLabel in labels){
		if(theLabel.regionTag == region)return [theLabel displayString];
	}
	return @"No Value Available";
}

- (NSString*) statusLabel:(int)region
{
	NSArray* labels = [partDictionary objectForKey:@"StatusLabels"];
	for(ORVacuumStatusLabel* theLabel in labels){
		if(theLabel.regionTag == region)return [theLabel displayString];
	}
	return @"No Value Available";
}


- (NSArray*) staticLabels
{
	return [partDictionary objectForKey:@"StaticLabels"];
}

- (NSColor*) colorOfRegion:(int)aRegion
{
	return [[self onePipeFromRegion:aRegion] regionColor];
}

- (NSString*) namesOfRegionsWithColor:(NSColor*)aColor
{
	NSMutableString* theRegions = [NSMutableString string];
	int i;
	for(i=0;i<8;i++){
		if([aColor isEqual:[self colorOfRegion:i]]){
			[theRegions appendFormat:@"%@%@,",i!=0?@" ":@"",[self regionName:i]];
		}
	}
	
	if([theRegions hasSuffix:@","]) return [theRegions substringToIndex:[theRegions length]-1];
	else return theRegions;
}

#pragma mark ***AdcProcessor Protocol
- (void) processIsStarting
{
	[self setVetoMask:0xffffffff];
	involvedInProcess = YES;
}

- (void) processIsStopping
{
	[self setVetoMask:0xffffffff];
	involvedInProcess = NO;
}

- (void) startProcessCycle
{
}

- (void) endProcessCycle
{
}

- (double) setProcessAdc:(int)channel value:(double)aValue isLow:(BOOL*)isLow isHigh:(BOOL*)isHigh
{
	return 0.0;
}

- (BOOL) setProcessBit:(int)channel value:(int)value
{
	ORVacuumGateValve* gv = [self gateValve:(int)channel];
	if([gv controlType] == k1BitReadBack){
		if(value==1)[gv setState:kGVClosed];
		else		[gv setState:kGVOpen];
	}
	else {
		if(value==3)		[gv setState:kGVChanging];
		else if(value==1)	[gv setState:kGVOpen];
		else if(value==2)	[gv setState:kGVClosed];
		else                [gv setState:kGVImpossible];
	}
	
	//special case... if the cryo roughing valve is open set the diaphram pump pressure to the cryopump region
	//other wise set it to 1 Torr
	if(channel == 5){
		ORVacuumValueLabel* aRegionlabel = [self regionValueObj:kRegionDiaphramPump];
		if([gv isOpen]) [aRegionlabel setValue:[self valueForRegion:kRegionCryoPump]];
		else		    [aRegionlabel setValue:2.0];
		[aRegionlabel setIsValid:[aRegionlabel isValid]];
	}

	return value;
}

- (NSString*) processingTitle
{
	return [NSString stringWithFormat:@"MJD Vac,%u",[self uniqueIdNumber]];
}

- (void) mapChannel:(int)aChannel toHWObject:(NSString*)objIdentifier hwChannel:(int)hwChannel;
{
	ORVacuumGateValve* aGateValve = [self gateValve:aChannel];
	aGateValve.controlObj		  = objIdentifier;
	aGateValve.controlChannel	  = hwChannel;
}

- (void) unMapChannel:(int)aChannel fromHWObject:(NSString*)objIdentifier hwChannel:(int)aHWChannel;
{
	ORVacuumGateValve* aGateValve = [self gateValve:aChannel];
	aGateValve.controlObj		  = nil;
}

- (void) vetoChangesOnChannel:(int)aChannel state:(BOOL)aState
{
	if(aChannel>=0 && aChannel<32){
		uint32_t newMask = vetoMask;
		if(aState) newMask |= (0x1<<aChannel);
		else newMask &= ~(0x1<<aChannel);
		if(newMask != vetoMask)[self setVetoMask:newMask];
	}
}

#pragma mark •••CardHolding Protocol
- (int) maxNumberOfObjects	{ return 6; }	//default
- (int) objWidth			{ return 80; }	//default
- (int) groupSeparation		{ return 0; }	//default
- (NSString*) nameForSlot:(int)aSlot	
{ 
    return [NSString stringWithFormat:@"Slot %d",aSlot]; 
}

- (NSRange) legalSlotsForObj:(id)anObj
{
	if([anObj isKindOfClass:NSClassFromString(@"ORTM700Model")])			return NSMakeRange(0,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORRGA300Model")])		return NSMakeRange(1,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORCP8CryopumpModel")]) return NSMakeRange(2,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORTPG256AModel")])		return NSMakeRange(3,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORMks660BModel")])		return NSMakeRange(4,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORLakeShore336Model")])return NSMakeRange(5,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORLakeShore210Model")])return NSMakeRange(5,1);
    else return NSMakeRange(0,0);
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj 
{ 
	if(aSlot == 0      && [anObj isKindOfClass:NSClassFromString(@"ORTM700Model")])		  return NO;
	else if(aSlot == 1 && [anObj isKindOfClass:NSClassFromString(@"ORRGA300Model")])	  return NO;
	else if(aSlot == 2 && [anObj isKindOfClass:NSClassFromString(@"ORCP8CryopumpModel")]) return NO;
	else if(aSlot == 3 && [anObj isKindOfClass:NSClassFromString(@"ORTPG256AModel")])	  return NO;
	else if(aSlot == 4 && [anObj isKindOfClass:NSClassFromString(@"ORMks660BModel")])     return NO;
	else if(aSlot == 5 && [anObj isKindOfClass:NSClassFromString(@"ORLakeShore336Model")])return NO;
	else if(aSlot == 5 && [anObj isKindOfClass:NSClassFromString(@"ORLakeShore210Model")])return NO;
    else return YES;
}

- (int) slotAtPoint:(NSPoint)aPoint 
{
	return floor(((int)aPoint.y)/[self objWidth]);
}

- (NSPoint) pointForSlot:(int)aSlot 
{
	return NSMakePoint(0,aSlot*[self objWidth]);
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
    [anObj setTag:aSlot];
	NSPoint slotPoint = [self pointForSlot:aSlot];
	[anObj moveTo:slotPoint];
}

- (int) slotForObj:(id)anObj
{
    return (int)[anObj tag];
}

- (int) numberSlotsNeededFor:(id)anObj
{
	return 1;
}

- (void) openDialogForComponent:(int)i
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj tag] == i){
			[anObj makeMainController];
			break;
		}
	}
}

- (NSString*) regionName:(int)i
{
	switch(i){
		case kRegionAboveTurbo:		return @"Above Turbo";
		case kRegionRGA:			return @"RGA";
		case kRegionCryostat:		return @"Cryostat";
		case kRegionCryoPump:		return @"CryoPump";
		case kRegionBaratron:		return @"Baratron";
		case kRegionDryN2:			return @"Dry N2";
		case kRegionNegPump:		return @"Neg Pump";
		case kRegionDiaphramPump:	return @"Diaphram Pump";
		case kRegionBelowTurbo:		return @"Below Turbo";
        case kRegionLakeShore:		return @"LakeShore";
        case kLakeShoreTemps:		return @"LakeShoreTemps";
		default: return nil;
	}
}

#pragma mark •••Constraints
- (void) addOkToBiasConstraints:(NSString*)aName reason:(NSString*)aReason
{
	if(!okToBiasConstraints)okToBiasConstraints = [[NSMutableDictionary dictionary] retain];
    if(![okToBiasConstraints objectForKey:aName]) NSLog(@"Added bias constraint: %@: %@\n",aName,aReason);
	[okToBiasConstraints setObject:aReason forKey:aName];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelConstraintsChanged object:self];
	
}

- (void) removeOkToBiasConstraints:(NSString*)aName
{
    if([okToBiasConstraints objectForKey:aName]) NSLog(@"Removed bias constraint: %@: %@\n",aName);
	[okToBiasConstraints removeObjectForKey:aName];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelConstraintsChanged object:self];
}

- (void) addContinuedBiasConstraints:(NSString*)aName reason:(NSString*)aReason
{
	if(!continuedBiasConstraints)continuedBiasConstraints = [[NSMutableDictionary dictionary] retain];
    if(![continuedBiasConstraints objectForKey:aName]) NSLog(@"Added continued bias constraint: %@: %@\n",aName,aReason);
	[continuedBiasConstraints setObject:aReason forKey:aName];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelConstraintsChanged object:self];
}

- (void) removeContinuedBiasConstraints:(NSString*)aName
{
    if([continuedBiasConstraints objectForKey:aName]) NSLog(@"Removed continued bias constraint: %@: %@\n",aName);
	[continuedBiasConstraints removeObjectForKey:aName];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelConstraintsChanged object:self];
}

- (NSDictionary*) okToBiasConstraints       { return okToBiasConstraints;      }
- (NSDictionary*) continuedBiasConstraints  { return continuedBiasConstraints; }

- (void) disableConstraintsFor60Seconds
{
    disableConstraints = YES;
    
    [[self findTurboPump] disableConstraints];
    [[self findCryoPump] disableConstraints];
    [[self findRGA] disableConstraints];

    [self performSelector:@selector(enableConstraints) withObject:nil afterDelay:60];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelConstraintsDisabledChanged object:self];
}

- (void) enableConstraints
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(enableConstraints) object:nil];
    disableConstraints = NO;

    [[self findTurboPump] enableConstraints];
    [[self findCryoPump] enableConstraints];
    [[self findRGA] enableConstraints];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDVacuumModelConstraintsDisabledChanged object:self];
}

- (BOOL) disableConstraints
{
    return disableConstraints;
}

- (void) reportConstraints
{
    NSLog(@"------------------------------------------------------------\n");
    NSLog(@"---------------    Constraint Report    --------------------\n");
    NSLog(@"------------------------------------------------------------\n");
    NSUInteger n = [continuedBiasConstraints count];
    if(n){
        NSLog(@"There %@ %d constraint%@ against continued bias of the detectors\n",n>1?@"are":@"is",n,n>1?@"s":@"");
        for(id aKey in [continuedBiasConstraints allKeys]){
            NSLog(@"%@: %@\n",aKey,[continuedBiasConstraints objectForKey:aKey]);
        }
    }
    else NSLog(@"There are no constraints against continued bias of the detectors\n");

    n = [okToBiasConstraints count];
    if(n){
        NSLog(@"There %@ %d constraint%@ against biasing the detectors\n",n>1?@"are":@"is",n,n>1?@"s":@"");
        for(id aKey in [okToBiasConstraints allKeys]){
            NSLog(@"%@: %@\n",aKey,[okToBiasConstraints objectForKey:aKey]);
        }
    }
    else NSLog(@"There are no constraints against biasing the detectors\n");

    //----RGA------
    NSLog(@"--RGA--\n");
    ORRGA300Model* rga =  [self findRGA];
    NSDictionary* aDict = [rga filamentConstraints];
    n = [aDict count];
    if(n){
        NSLog(@"There %@ %d constraint%@ against RGA filament\n",n>1?@"are":@"is",n,n>1?@"s":@"");
        NSLog(@"%@",[rga filamentConstraintReport]);
    }
    else NSLog(@"There are no constraints against the RGA filament\n");
    
    aDict = [rga cemConstraints];
    n = [aDict count];
    if(n){
        NSLog(@"There %@ %d constraint%@ against RGA CEM\n",n>1?@"are":@"is",n,n>1?@"s":@"");
        NSLog(@"%@",[rga filamentConstraintReport]);
    }
    else NSLog(@"There are no constraints against the RGA CEM\n");
    
    //----Turbo
    NSLog(@"--Turbo Pump--\n");
    ORTM700Model* turbo =  [self findTurboPump];
    aDict = [turbo pumpOffConstraints];
    n = [aDict count];
    if(n){
        NSLog(@"There %@ %d constraint%@ against Turbo Pump\n",n>1?@"are":@"is",n,n>1?@"s":@"");
        NSLog(@"%@",[turbo pumpOffConstraintReport]);
    }
    else NSLog(@"There are no constraints against the Turbo Pump\n");

    //----Cryo
    NSLog(@"--Cryopump--\n");
    ORCP8CryopumpModel* cryo =  [self findCryoPump];
    uint32_t pmpOffCount = (uint32_t)[[cryo pumpOffConstraints] count];
    uint32_t pmpOnCount = (uint32_t)[[cryo pumpOnConstraints] count];
    if(pmpOffCount + pmpOnCount){
        NSLog(@"%@",[cryo pumpOnOffConstraintReport]);
    }
    else NSLog(@"There are no constraints against the Cryo Pump On/Off\n");

    aDict = [cryo purgeOpenConstraints];
    n = [aDict count];
    if(n){
        NSLog(@"There %@ %d constraint%@ against Cryo Purge Valve\n",n>1?@"are":@"is",n,n>1?@"s":@"");
        NSLog(@"%@",[cryo purgeOpenConstraintReport]);
    }
    else NSLog(@"There are no constraints against the Cryo Purge Valve\n");

    
    aDict = [cryo roughingOpenConstraints];
    n = [aDict count];
    if(n){
        NSLog(@"There %@ %d constraint%@ against Cryo Roughing Valve\n",n>1?@"are":@"is",n,n>1?@"s":@"");
        NSLog(@"%@",[cryo roughingOpenConstraintReport]);
    }
    else NSLog(@"There are no constraints against the Cryo Roughing Valve\n");
    
    //Gate Valves
    NSArray* gateValves = [self gateValves];
    for(ORVacuumGateValve* aGateValve in gateValves){
        NSDictionary* constraintDict = [aGateValve constraints];
        if(constraintDict){
            NSUInteger n = [constraintDict count];
            if(n){
                NSLog(@"There %@ %d constraint%@ against changing gatevalve %@\n",n>1?@"are":@"is",n,n>1?@"s":@"",[aGateValve label]);
                for(id aKey in [constraintDict allKeys]){
                    NSLog(@"%@: %@\n",aKey,[constraintDict objectForKey:aKey]);
                }
            }
            else NSLog(@"No constraints against gatevalve %@\n",[aGateValve label]);
        }
    }
    NSLog(@"------------------------------------------------------------\n");
}

@end


@implementation ORMJDVacuumModel (private)
- (id)findLakeShore
{
    id lakeShore336 = [self findObject:@"ORLakeShore336Model"];
    if(lakeShore336)return lakeShore336;
    
    id lakeShore210 = [self findObject:@"ORLakeShore210Model"];
    if(lakeShore210)return lakeShore210;
    
    return nil;
 
}
- (ORMks660BModel*)     findBaratron		{ return [self findObject:@"ORMks660BModel"];     }
- (ORRGA300Model*)      findRGA				{ return [self findObject:@"ORRGA300Model"];      }
- (ORTM700Model*)       findTurboPump		{ return [self findObject:@"ORTM700Model"];       }
- (ORTPG256AModel*)     findPressureGauge   { return [self findObject:@"ORTPG256AModel"];     }
- (ORCP8CryopumpModel*) findCryoPump		{ return [self findObject:@"ORCP8CryopumpModel"]; }

- (id) findObject:(NSString*)aClassName
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj isKindOfClass:NSClassFromString(aClassName)])return anObj;
	}
	return nil;
}

- (void) resetHvTimer
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setNoHvInfo) object:nil];
    [self clearNoHvInfo];
    if(hvUpdateTime>0) {
        [self setNextHvUpdateTime:[NSDate dateWithTimeIntervalSinceNow:hvUpdateTime*60]];
        //set the deadman to 3x the time sent from DAQ
        [self performSelector:@selector(setNoHvInfo) withObject:nil afterDelay:3*(hvUpdateTime*60)];
    }
    else {
        [self setNextHvUpdateTime:nil];
    }
}

- (void) remakeParts
{
    [partDictionary removeAllObjects];
    [partDictionary release];
    partDictionary = nil;

    [valueDictionary removeAllObjects];
    [valueDictionary release];
    valueDictionary = nil;

    [statusDictionary removeAllObjects];
    [statusDictionary release];
    statusDictionary = nil;

    [parts removeAllObjects];
    [parts release];
    parts = nil;

    [self makeParts];
}

- (void) makeParts
{
#define kNumVacPipes		61
	VacuumPipeStruct vacPipeList[kNumVacPipes] = {
		//region 0 pipes
		{ kVacVPipe,  kRegionAboveTurbo, 50,			 260,				50,					450 }, 
		{ kVacHPipe,  kRegionAboveTurbo, 50+kPipeRadius, 400,				180+kPipeRadius,	400 },
		
		//region 1 pipes
		{ kVacCorner, kRegionRGA,		500,			  200,				kNA,				kNA },
		{ kVacVPipe,  kRegionRGA,		500,			  200+kPipeRadius,	 500,				250 },
		{ kVacHPipe,  kRegionRGA,		180,			  400,				350,				400 },
		{ kVacHPipe,  kRegionRGA,		200,			  200,				500-kPipeRadius,	200 },
		{ kVacVPipe,  kRegionRGA,		280,			  200+kPipeRadius,	280,				400-kPipeRadius },
		{ kVacVPipe,  kRegionRGA,		280,			  400+kPipeRadius,	280,				420 },
		{ kVacVPipe,  kRegionRGA,		230,			  400+kPipeRadius,	230,				450 },
		{ kVacHPipe,  kRegionRGA,		230,			  350,				280-kPipeRadius,	350 },
		
		//region 2 pipes (cyrostat)
		{ kVacBox,	   kRegionCryostat, 475,			  500,				525,				555 },
		{ kVacBox,	   kRegionCryostat, 600,			  435,				700,				555 },
		{ kVacBigHPipe,kRegionCryostat, 525,			  530,		        600,				530 },
		{ kVacCorner,  kRegionCryostat, 700,			  400,				kNA,				kNA },
		{ kVacVPipe,   kRegionCryostat, 700,			   70,				700,				400-kPipeRadius },
		{ kVacHPipe,   kRegionCryostat, 350,			  400,				700-kPipeRadius,	400 },
		{ kVacVPipe,   kRegionCryostat, 600,			  350,				600,				400-kPipeRadius },
		{ kVacVPipe,   kRegionCryostat, 500,			  350,				500,				400-kPipeRadius },
		{ kVacCorner,  kRegionCryostat, 400,			  300,				kNA,				kNA },
		{ kVacVPipe,   kRegionCryostat, 400,			  300+kPipeRadius,	400,				400-kPipeRadius },
		{ kVacHPipe,   kRegionCryostat, 350,			  300,				400-kPipeRadius,	300 },
		{ kVacHPipe,   kRegionCryostat, 350,			  350,				400-kPipeRadius,	350 },
		{ kVacVPipe,   kRegionCryostat, 400,			  400+kPipeRadius,	400,				450 },
		{ kVacVPipe,   kRegionCryostat, 500,			  400+kPipeRadius,	500,				500 },
        
		//region 3 pipes
		{ kVacVPipe,  kRegionCryoPump,	600,			  230,				600,				350 },
		{ kVacHPipe,  kRegionCryoPump,	600+kPipeRadius, 300,				620,				300 },
		{ kVacVPipe,  kRegionCryoPump,	580,			  70,				580,				200 },
		{ kVacHPipe,  kRegionCryoPump,	530,			  150,				580-kPipeRadius,	150 },
		{ kVacCorner, kRegionCryoPump,	620,			  150,				kNA,				kNA },
		{ kVacVPipe,  kRegionCryoPump,	620,			  150+kPipeRadius,	620,				200 },
		{ kVacHPipe,  kRegionCryoPump,	620+kPipeRadius, 150,				640,				150 },
        
		//region 4 pipes
		{ kVacBox,	  kRegionBaratron,  470,			  570,				530,				620 },
		{ kVacBox,	  kRegionBaratron,  270,			  570,				330,				620 },
		{ kVacCorner, kRegionBaratron,  500,			  535,				kNA,				kNA },
		{ kVacCorner, kRegionBaratron,  680,			  535,				kNA,				kNA },
		{ kVacHPipe,  kRegionBaratron,  500+kPipeRadius,  535,				680-kPipeRadius,	535 },
		{ kVacVPipe,  kRegionBaratron,  500,			  535+kPipeRadius,	500,				570 },
		{ kVacHPipe,  kRegionBaratron,  330,			  600,				400,				600 },
		{ kVacHPipe,  kRegionBaratron,  400,			  600,				470,				600 },
		{ kVacVPipe,  kRegionBaratron,  360,			  540,				360,				600-kPipeRadius },
        
		//region 5 pipes
		{ kVacCorner, kRegionDryN2,		150,			  30,				kNA,				kNA },
		{ kVacCorner, kRegionDryN2,		700,			  30,				kNA,				kNA },
		{ kVacCorner, kRegionDryN2,		150,			  200,				kNA,				kNA },
		{ kVacVPipe,  kRegionDryN2,		150,			  30+kPipeRadius,	150,				200-kPipeRadius },
		{ kVacHPipe,  kRegionDryN2,		150+kPipeRadius, 30,				700-kPipeRadius,	30 },
		{ kVacHPipe,  kRegionDryN2,		150+kPipeRadius, 200,				200,				200 },
		{ kVacVPipe,  kRegionDryN2,		700,			  30+kPipeRadius,	700,				70 },
		{ kVacVPipe,  kRegionDryN2,		580,			  30+kPipeRadius,	580,				70 },
		{ kVacCorner, kRegionDryN2,		330,			  80,				kNA,				kNA },
		{ kVacVPipe,  kRegionDryN2,		330,			  30+kPipeRadius,	330,				80-kPipeRadius },
		{ kVacHPipe,  kRegionDryN2,		310,			  80,				330-kPipeRadius,	80 },
		{ kVacHPipe,  kRegionDryN2,		280,			  80,				310,				80 },
		{ kVacVPipe,  kRegionDryN2,		400,			  30+kPipeRadius,	400,				50 },

		//region 6 pipes
		{ kVacVPipe,  kRegionNegPump,	500,			  250,				500,				350 },
		{ kVacHPipe,  kRegionNegPump,	460,			  300,				500-kPipeRadius,	300 },
		//region 7 pipes
		{ kVacVPipe,  kRegionDiaphramPump, 50,			  100,				50,					200 }, 
		{ kVacHPipe,  kRegionDiaphramPump, 50+kPipeRadius,150,				530,				150 },
		{ kVacVPipe,  kRegionDiaphramPump, 400,			  130,				400,				150-kPipeRadius }, 
		//region 8 pipes
		{ kVacVPipe,  kRegionBelowTurbo, 50,			  200,				50,					260 }, 
		
        //region 9 pipes
		{ kVacCorner, kRegionLakeShore,  680,			  525,				kNA,				kNA },
		{ kVacHPipe,  kRegionLakeShore,  460+kPipeRadius, 525,				680-kPipeRadius,	525 },

	};
	
#define kNumStaticLabelItems	3
	VacuumStaticLabelStruct staticLabelItems[kNumStaticLabelItems] = {
		{kVacStaticLabel, kRegionDryN2,			@"Dry N2\nSupply",	200,  60,	280, 100},
		{kVacStaticLabel, kRegionNegPump,		@"NEG Pump",		420, 285,	480, 315},
		{kVacStaticLabel, kRegionDiaphramPump,	@"Diaphragm\nPump",	 20,  80,	 80, 110},
	};	
	
#define kNumStatusItems	11
	VacuumDynamicLabelStruct dynamicLabelItems[kNumStatusItems] = {
		//type,	region, component, channel
		{kVacStatusItem,   kRegionAboveTurbo,	0, 5,  @"Turbo",	20,	 242,	80,	 268},
		{kVacStatusItem,   kRegionRGA,			1, 6,  @"RGA",		260, 417,	300, 443},
		{kVacStatusItem,   kRegionCryoPump,		2, 7,  @"Cryo Pump",560, 200,	640, 230},
		{kVacPressureItem, kRegionAboveTurbo,	3, 0,  @"PKR G1",	20,	 450,	80,	 480},
		{kVacPressureItem, kRegionRGA,			3, 1,  @"PKR G2",	200, 450,	260, 480},
		{kVacPressureItem, kRegionCryostat,		3, 2,  @"PKR G3",	370, 450,	430, 480},
		{kVacPressureItem, kRegionCryoPump,		3, 3,  @"PKR G4",	620, 285,	680, 315},
		{kVacPressureItem, kRegionBaratron,		4, 0,  @"Baratron",	330, 510,	390, 540},
		{kVacPressureItem, kRegionDiaphramPump,	3, 3,  @"Assumed",	370, 100,	430, 130},
		{kVacPressureItem, kRegionDryN2,		99, 99,@"Assumed",	370, 50,	430, 80},
        {kVacPressureItem, kRegionLakeShore,    9, 0,  @"LakeShore",405, 510,	465, 540}
	};
	
#define kNumVacLines 10
	VacuumLineStruct vacLines[kNumVacLines] = {
		{kVacLine, 180,400,180,420},  //V1
		{kVacLine, 350,400,350,420},  //V2
		{kVacLine, 600,350,620,350},  //V3
		{kVacLine, 480,350,500,350},  //V4
		{kVacLine, 480,250,500,250},  //V5
		{kVacLine, 530,130,530,140},  //V6
		
		{kVacLine, 200,200,200,220},  //B1
		{kVacLine, 560,70,580,70},    //B3
		{kVacLine, 680,70,700,70},    //B4
		{kVacLine, 60,200,70,200},    //B5
	};
	
#define kNumVacGVs			18
	VacuumGVStruct gvList[kNumVacGVs] = {
		{kVacVGateV, 0,		@"V1",			k2BitReadBack,				180, 400,	kRegionAboveTurbo,	kRegionRGA,				kControlAbove},	//V1. Control + read back
		{kVacVGateV, 1,		@"V2",			k2BitReadBack,				350, 400,	kRegionRGA,			kRegionCryostat,		kControlAbove},	//V2. Control + read back
		{kVacHGateV, 2,		@"V3",			k2BitReadBack,				500, 350,	kRegionCryostat,	kRegionNegPump,			kControlLeft},	//V4. Control + read back
		{kVacHGateV, 3,		@"V4",			k2BitReadBack,				600, 350,	kRegionCryostat,	kRegionCryoPump,		kControlRight},	//V3. Control + read back
		{kVacHGateV, 4,		@"V5",			k2BitReadBack,				500, 250,	kRegionRGA,			kRegionNegPump,			kControlLeft},	//V5. Control + read back
		{kVacVGateV, 5,		@"Roughing",	k1BitReadBack,				530, 150,	kRegionDiaphramPump,kRegionCryoPump,		kControlBelow},   //V6. Control + read back
		
		{kVacVGateV, 6,		@"B1",			k1BitReadBack,				200, 200,	kRegionRGA,			kRegionDryN2,			kControlAbove},	//Control only
		{kVacHGateV, 7,		@"Spare-Ignore",kSpareValve,				150, 300,	kSpareValve,		kSpareValve,			kControlNone},	//Spare. 
		{kVacHGateV, 8,		@"Purge",		k1BitReadBack,				580, 70,	kRegionCryoPump,	kRegionDryN2,			kControlLeft},	//Control only 
		{kVacHGateV, 9,		@"B4",			k1BitReadBack,				700, 70,	kRegionCryostat,	kRegionDryN2,			kControlLeft},	//Control only 
		
		{kVacVGateV, 10,	@"Burst",		kManualOnlyShowClosed,		350, 300,	kRegionCryostat,	kUpToAir,				kControlNone},	//burst
		{kVacVGateV, 11,	@"N2 Manual",	kManualOnlyShowChanging,	310, 80,	kRegionDryN2,		kUpToAir,				kControlNone},	//Manual N2 supply
		{kVacVGateV, 12,	@"PRV",			kManualOnlyShowClosed,		640, 150,	kRegionCryoPump,	kUpToAir,				kControlNone},	//PRV
		{kVacVGateV, 13,	@"PRV",			kManualOnlyShowClosed,		350, 350,	kRegionCryostat,	kUpToAir,				kControlNone},	//PRV
		{kVacVGateV, 14,	@"C1",			kManualOnlyShowChanging,	400, 600,	kRegionBaratron,	kRegionBaratron,		kControlNone},	//Manual only
		{kVacHGateV, 15,	@"B5",			k1BitReadBack,				50, 200,	kRegionDiaphramPump,kRegionBelowTurbo,		kControlRight},	//future control
		{kVacHGateV, 16,	@"Turbo",		k1BitReadBack,				50, 260,	kRegionAboveTurbo,	kRegionBelowTurbo,		kControlNone},	//this is a virtual valve-- really the turbo on/off
		{kVacVGateV, 17,	@"PRV",			kManualOnlyShowClosed,		230, 350,	kRegionRGA,			kUpToAir,				kControlNone},	//PRV
	};
    
    #define kNumTempGroups 1
    TempGroup temperatureGroup[kNumTempGroups] = {
        {kVacTempGroup, kLakeShoreTemps,    9, 0,  @"Temps (K)",130, 250,	190, 380},
    };
    
	[self makeLines:vacLines					num:kNumVacLines];
	[self makePipes:vacPipeList					num:kNumVacPipes];
	[self makeGateValves:gvList					num:kNumVacGVs];
	[self makeStaticLabels:staticLabelItems		num:kNumStaticLabelItems];
	[self makeDynamicLabels:dynamicLabelItems	num:kNumStatusItems];
    [self makeTempGroups:temperatureGroup       num:kNumTempGroups];
}

- (void) makePipes:( VacuumPipeStruct*)pipeList num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		switch(pipeList[i].type){
			case kVacCorner:
				[[[ORVacuumCPipe alloc] initWithDelegate:self regionTag:pipeList[i].regionTag at:NSMakePoint(pipeList[i].x1, pipeList[i].y1)] autorelease];
				break;
				
			case kVacVPipe:
				[[[ORVacuumVPipe alloc] initWithDelegate:self regionTag:pipeList[i].regionTag startPt:NSMakePoint(pipeList[i].x1, pipeList[i].y1) endPt:NSMakePoint(pipeList[i].x2, pipeList[i].y2)] autorelease];
				break;
				
			case kVacHPipe:
				[[[ORVacuumHPipe alloc] initWithDelegate:self regionTag:pipeList[i].regionTag startPt:NSMakePoint(pipeList[i].x1, pipeList[i].y1) endPt:NSMakePoint(pipeList[i].x2, pipeList[i].y2)] autorelease];
				break;
				
			case kVacBigHPipe:
				[[[ORVacuumBigHPipe alloc] initWithDelegate:self regionTag:pipeList[i].regionTag startPt:NSMakePoint(pipeList[i].x1, pipeList[i].y1) endPt:NSMakePoint(pipeList[i].x2, pipeList[i].y2)] autorelease];
				break;
				
			case kVacBox:
				[[[ORVacuumBox alloc] initWithDelegate:self regionTag:pipeList[i].regionTag bounds:NSMakeRect(pipeList[i].x1, pipeList[i].y1,pipeList[i].x2-pipeList[i].x1,pipeList[i].y2-pipeList[i].y1)] autorelease];
				break;
		}
	}
}

- (void) makeGateValves:( VacuumGVStruct*)gvList num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		ORVacuumGateValve* gv= nil;
		switch(gvList[i].type){
			case kVacVGateV:
				gv = [[[ORVacuumVGateValve alloc] initWithDelegate:self partTag:gvList[i].partTag  label:gvList[i].label controlType:gvList[i].controlType at:NSMakePoint(gvList[i].x1, gvList[i].y1) connectingRegion1:gvList[i].r1 connectingRegion2:gvList[i].r2] autorelease];
				break;
				
			case kVacHGateV:
				gv = [[[ORVacuumHGateValve alloc] initWithDelegate:self partTag:gvList[i].partTag label:gvList[i].label controlType:gvList[i].controlType at:NSMakePoint(gvList[i].x1, gvList[i].y1) connectingRegion1:gvList[i].r1 connectingRegion2:gvList[i].r2] autorelease];
				break;
		}
		if(gv){
			gv.controlPreference = gvList[i].conPref;
		}
	}
}

- (void) makeStaticLabels:(VacuumStaticLabelStruct*)labelItems num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		NSRect theBounds = NSMakeRect(labelItems[i].x1,labelItems[i].y1,labelItems[i].x2-labelItems[i].x1,labelItems[i].y2-labelItems[i].y1);
		ORVacuumStaticLabel* aLabel = [[ORVacuumStaticLabel alloc] initWithDelegate:self regionTag:labelItems[i].regionTag label:labelItems[i].label bounds:theBounds];
		[aLabel release];
	}
}

- (void)  makeDynamicLabels:(VacuumDynamicLabelStruct*)labelItems num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){

		NSRect theBounds = NSMakeRect(labelItems[i].x1,labelItems[i].y1,labelItems[i].x2-labelItems[i].x1,labelItems[i].y2-labelItems[i].y1);
		if(labelItems[i].type == kVacPressureItem){
			[[[ORVacuumValueLabel alloc] initWithDelegate:self regionTag:labelItems[i].regionTag component:labelItems[i].component channel:labelItems[i].channel label:labelItems[i].label bounds:theBounds] autorelease];			
		}
		if(labelItems[i].type == kVacStatusItem){
			[[[ORVacuumStatusLabel alloc] initWithDelegate:self regionTag:labelItems[i].regionTag component:labelItems[i].component channel:labelItems[i].channel label:labelItems[i].label bounds:theBounds] autorelease];
		}
	}
	ORVacuumValueLabel* aLabel = [self regionValueObj:kRegionDryN2];
	[aLabel setIsValid:YES];
	[aLabel setValue:1.0E3];
}

- (void)  makeTempGroups:(TempGroup*)labelItems num:(int)numItems
{
    int i;
    for(i=0;i<numItems;i++){
        NSRect theBounds = NSMakeRect(labelItems[i].x1,labelItems[i].y1,labelItems[i].x2-labelItems[i].x1,labelItems[i].y2-labelItems[i].y1);
        [[[ORVacuumTempGroup alloc] initWithDelegate:self regionTag:labelItems[i].regionTag component:labelItems[i].component channel:labelItems[i].channel label:labelItems[i].label bounds:theBounds] autorelease];
    }
}

- (void) makeLines:( VacuumLineStruct*)lineItems num:(int)numItems
{
	int i;
	for(i=0;i<numItems;i++){
		[[[ORVacuumLine alloc] initWithDelegate:self startPt:NSMakePoint(lineItems[i].x1, lineItems[i].y1) endPt:NSMakePoint(lineItems[i].x2, lineItems[i].y2)] autorelease];
	}
}

- (void) colorRegions
{
	#define kNumberPriorityRegions 10
	int regionPriority[kNumberPriorityRegions] = {9,4,6,1,0,3,8,7,2,5}; //lowest to highest
					
	NSColor* regionColor[kNumberPriorityRegions] = {
		[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.7 alpha:1.0], //Region 0 Above Turbo
		[NSColor colorWithCalibratedRed:1.0 green:0.7 blue:1.0 alpha:1.0], //Region 1 RGA
		[NSColor colorWithCalibratedRed:0.8 green:0.8 blue:1.0 alpha:1.0], //Region 2 Cryostat
		[NSColor colorWithCalibratedRed:0.7 green:1.0 blue:0.7 alpha:1.0], //Region 3 Cryo pump
		[NSColor colorWithCalibratedRed:0.6 green:0.6 blue:1.0 alpha:1.0], //Region 4 Thermosyphon
		[NSColor colorWithCalibratedRed:1.0 green:0.5 blue:0.5 alpha:1.0], //Region 5 N2
		[NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.4 alpha:1.0], //Region 6 NEG Pump
		[NSColor colorWithCalibratedRed:0.4 green:0.6 blue:0.7 alpha:1.0], //Region 7 Diaphragm pump
		[NSColor colorWithCalibratedRed:0.5 green:0.9 blue:0.3 alpha:1.0], //Region 8 Below Turbo
		[NSColor colorWithCalibratedRed:0.6 green:0.8 blue:0.8 alpha:1.0], //Region 9 LakeShore
	};
	int i;
	for(i=0;i<kNumberPriorityRegions;i++){
		int region = regionPriority[i];
		[self colorRegionsConnectedTo:region withColor:regionColor[region]];
	}
	
	NSArray* staticLabels = [self staticLabels];
	for(ORVacuumStaticLabel* aLabel in staticLabels){
		int region = [aLabel regionTag];
		if(region<kNumberPriorityRegions){
			[aLabel setControlColor:regionColor[region]];
		}
	}
	
	NSArray* statusLabels = [self statusLabels];
	for(ORVacuumStatusLabel* aLabel in statusLabels){
		int regionTag = [aLabel regionTag];
		if(regionTag<kNumberPriorityRegions){
			[aLabel setControlColor:regionColor[regionTag]];
		}
	}
    
    if(!couchPostScheduled){
        couchPostScheduled = YES;
        [self performSelector:@selector(postCouchRecord) withObject:nil afterDelay:5];
    }
}

- (void)postCouchRecord
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(postCouchRecord) object:nil];

    couchPostScheduled = NO;
    NSMutableDictionary* values = [NSMutableDictionary dictionary];
    NSMutableArray* regionColors = [NSMutableArray array];
    int i;
    for(i=0;i<kNumberPriorityRegions;i++){
        NSArray* pipes = [self pipesForRegion:i];
        for(id aPipe in pipes){
            [regionColors addObject:[aPipe rgbString]];
        }
    }
    
    NSMutableArray* gvStates = [NSMutableArray array];
    for(ORVacuumGateValve* aGateValve in [self gateValves]){
        [gvStates addObject:[NSArray arrayWithObjects:
                             [NSNumber numberWithInteger:[aGateValve state]],
                             [NSNumber numberWithInteger:[aGateValve constraintCount]],
                             nil]];
    }
    
    NSMutableArray* valueLabels = [NSMutableArray array];
    for(ORVacuumStatusLabel* aLabel in [self statusLabels]){
        [valueLabels addObject:[NSArray arrayWithObjects:[aLabel label],[aLabel displayString],nil]];
    }
    for(ORVacuumDynamicLabel* aLabel in [self valueLabels]){
        [valueLabels addObject:[NSArray arrayWithObjects:[aLabel label],[aLabel displayString],nil]];
    }
    
    [values setObject: valueLabels          forKey:@"DynamicLabels"];
    [values setObject: regionColors         forKey:@"RegionColors"];
    [values setObject: gvStates             forKey:@"GateValves"];
    [values setObject: [NSNumber numberWithBool:[self detectorsBiased]]      forKey:@"DetectorsBiased"];
    [values setObject: [NSNumber numberWithBool:[self shouldUnbiasDetector]] forKey:@"ShouldUnbiasDetector"];
    [values setObject: [NSNumber numberWithBool:[self okToBiasDetector]]     forKey:@"OKToBiasDetector"];
    [values setObject: [NSNumber numberWithInt: [self coolerMode]]           forKey:@"CoolerMode"];
 
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
    [self performSelector:@selector(postCouchRecord) withObject:nil afterDelay:5];
}

- (void) colorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor
{
	[self resetVisitationFlag];
	[self recursizelyColorRegionsConnectedTo:aRegion withColor:aColor];
}

- (void) recursizelyColorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor
{
	//this routine is called recursively, so do not reset the visitation flag in this routine.
	NSArray* pipes = [self pipesForRegion:aRegion];
	for(id aPipe in pipes){
		if([aPipe visited])return;
		[aPipe setRegionColor:aColor];
		[aPipe setVisited:YES];
	}

	NSArray* gateValves = [self gateValvesConnectedTo:(int)aRegion];
	for(id aGateValve in gateValves){
		if([aGateValve isOpen]){
			int r1 = [aGateValve connectingRegion1];
			int r2 = [aGateValve connectingRegion2];
			if(r1!=aRegion){
				[self recursizelyColorRegionsConnectedTo:r1 withColor:aColor];
			}
			if(r2!=aRegion){
				[self recursizelyColorRegionsConnectedTo:r2 withColor:aColor];
			}
		}
	}
}

- (void) resetVisitationFlag
{
	for(id aPart in parts)[aPart setVisited:NO];
}

- (void) addPart:(id)aPart
{
	if(!aPart)return;
	
	//the parts array contains all parts
	if(!parts)parts = [[NSMutableArray array] retain];
	[parts addObject:aPart];
	
	//we keep a separate dicionary of various categories of parts for convenience
	if(!partDictionary){
		partDictionary = [[NSMutableDictionary dictionary] retain];
		[partDictionary setObject:[NSMutableDictionary dictionary] forKey:@"Regions"];
		[partDictionary setObject:[NSMutableArray array] forKey:@"GateValves"];		
		[partDictionary setObject:[NSMutableArray array] forKey:@"ValueLabels"];		
		[partDictionary setObject:[NSMutableArray array] forKey:@"StatusLabels"];		
        [partDictionary setObject:[NSMutableArray array] forKey:@"StaticLabels"];
	}
	if(!valueDictionary){
		valueDictionary = [[NSMutableDictionary dictionary] retain];
	}
	if(!statusDictionary){
		statusDictionary = [[NSMutableDictionary dictionary] retain];
	}
	
	NSNumber* thePartKey = [NSNumber numberWithInt:[aPart regionTag]];
	if([aPart isKindOfClass:NSClassFromString(@"ORVacuumPipe")]){
		NSMutableArray* aRegionArray = [[partDictionary objectForKey:@"Regions"] objectForKey:thePartKey];
		if(!aRegionArray)aRegionArray = [NSMutableArray array];
		[aRegionArray addObject:aPart];
		[[partDictionary objectForKey:@"Regions"] setObject:aRegionArray forKey:thePartKey];
	}
	else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumGateValve")]){
		[[partDictionary objectForKey:@"GateValves"] addObject:aPart];
	}
    else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumValueLabel")]){
        [[partDictionary objectForKey:@"ValueLabels"] addObject:aPart];
        [valueDictionary setObject:aPart forKey:[NSNumber numberWithInt:[aPart regionTag]]];
    }
    else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumTempGroup")]){
        [[partDictionary objectForKey:@"ValueLabels"] addObject:aPart];
        [valueDictionary setObject:aPart forKey:[NSNumber numberWithInt:[aPart regionTag]]];
    }
	else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumStatusLabel")]){
		[[partDictionary objectForKey:@"StatusLabels"] addObject:aPart];
		[statusDictionary setObject:aPart forKey:[NSNumber numberWithInt:[aPart regionTag]]];
	}
	else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumStaticLabel")]){
		[[partDictionary objectForKey:@"StaticLabels"] addObject:aPart];
	}
}

- (void) closeGateValve:(int)aGateValveTag
{
	if((vetoMask & (0x1<<aGateValveTag)) == 0 ){
		ORVacuumGateValve* aGateValve = [self gateValve:aGateValveTag];
		id aController = [self findGateValveControlObj:aGateValve];
		[aController setOutputBit:aGateValve.controlChannel value:0];
		[aGateValve setCommandedState:kGVCommandClosed];
        NSLog(@"Valve %@ commanded to close\n",[aGateValve label]);
	}
}

- (void) openGateValve:(int)aGateValveTag
{
	if((vetoMask & (0x1<<aGateValveTag)) == 0 ){
		ORVacuumGateValve* aGateValve = [self gateValve:aGateValveTag];
		id aController = [self findGateValveControlObj:aGateValve];
		[aController setOutputBit:aGateValve.controlChannel value:1];
		[aGateValve setCommandedState:kGVCommandOpen];
        NSLog(@"Valve %@ commanded to open\n",[aGateValve label]);
	}
}

- (id) findGateValveControlObj:(ORVacuumGateValve*)aGateValve
{
	NSArray* objs = [[self document] collectObjectsConformingTo:@protocol(ORBitProcessing)];
	NSString* objLabel	= aGateValve.controlObj;
	
	for(id anObj in objs){
		if([[anObj processingTitle] isEqualToString:objLabel]){
			return anObj;
		}
	}
	return nil;
}

- (BOOL) region:(int)aRegion valueHigherThan:(double)aValue
{
	if(aRegion == kRegionNegPump){
		if([[self gateValve:2] isOpen])		 return [[self regionValueObj:kRegionCryostat] valueHigherThan:aValue];
		else if([[self gateValve:4] isOpen]) return [[self regionValueObj:kRegionRGA] valueHigherThan:aValue];
		else return 0.0;
	}
	else return [[self regionValueObj:aRegion] valueHigherThan:aValue];
}

- (BOOL) valueValidForRegion:(int)aRegion
{
	if(aRegion == kRegionNegPump)return YES;
	else return [[self regionValueObj:aRegion] isValid];
}

- (double) valueForRegion:(int)aRegion
{	
	if(aRegion == kRegionNegPump){
		if([[self gateValve:2] isOpen])		 return [self valueForRegion:kRegionCryostat];
		else if([[self gateValve:4] isOpen]) return [self valueForRegion:kRegionRGA];
		else return 0.0;
	}
	else return [[self regionValueObj:aRegion] value];
}

- (ORVacuumValueLabel*) regionValueObj:(int)aRegion
{
	return [valueDictionary objectForKey:[NSNumber numberWithInt:aRegion]];
}

- (id) component:(int)aComponentTag
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj tag] == aComponentTag)return anObj;
	}
	return nil;
}

- (BOOL) regionColor:(int)r1 sameAsRegion:(int)r2
{
	NSColor* c1	= [self colorOfRegion:r1];
	NSColor* c2	= [self colorOfRegion:r2];
	return [c1 isEqual:c2];
}
			 
- (void) onAllGateValvesremoveConstraintName:(NSString*)aConstraintName
{
	for(ORVacuumGateValve* aGateValve in [self gateValves]){
		[self removeConstraintName:aConstraintName fromGateValve:aGateValve];
	}
}

- (void)  checkAllConstraints
{
	if(!constraintCheckScheduled){
		constraintCheckScheduled = YES;
		[self performSelector:@selector(deferredConstraintCheck) withObject:nil afterDelay:.5];
	}
}
- (void) deferredConstraintCheck
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(deferredConstraintCheck) object:nil];

	[self checkTurboRelatedConstraints:[self findTurboPump]];
	[self checkRGARelatedConstraints:  [self findRGA]];
	[self checkCryoPumpRelatedConstraints:[self findCryoPump]];
	[self checkPressureConstraints];
	[self checkDetectorConstraints];
	constraintCheckScheduled = NO;
}

- (void) checkTurboRelatedConstraints:(ORTM700Model*) turbo
{
	BOOL turboIsOn;
	if(![turbo isValid]) turboIsOn = YES;
	else turboIsOn = [turbo stationPower];
	//
	if(turboIsOn){
		for(ORVacuumGateValve* aGateValve in [self gateValves]){
			//---------------------------------------------------------------------------
			//Opening valve will expose turbo pump to potentially damaging pressures.
			if([aGateValve isClosed]){
				int side1				= [aGateValve connectingRegion1];
				int side2				= [aGateValve connectingRegion2];
				
				if([self regionColor:side1 sameAsRegion:side2]){
					[self removeConstraintName:kTurboOnPressureConstraint fromGateValve:aGateValve];
				}
				else if([self regionColor:side1 sameAsRegion:kRegionAboveTurbo] && [self region:side2 valueHigherThan:1.0E-1] ){
					[self addConstraintName:kTurboOnPressureConstraint reason:kTurboOnPressureConstraintReason toGateValve:aGateValve];
				}
				else if([self regionColor:side1 sameAsRegion:kRegionBelowTurbo] && [self region:side2 valueHigherThan:5]){
					[self addConstraintName:kTurboOnPressureConstraint reason:kTurboOnPressureConstraintReason toGateValve:aGateValve];
				}
				else if([self regionColor:side2 sameAsRegion:kRegionAboveTurbo] && [self region:side1 valueHigherThan:1.0E-1]){
					[self addConstraintName:kTurboOnPressureConstraint reason:kTurboOnPressureConstraintReason toGateValve:aGateValve];
				}
				else if([self regionColor:side2 sameAsRegion:kRegionBelowTurbo] && [self region:side1 valueHigherThan:5]){
					[self addConstraintName:kTurboOnPressureConstraint reason:kTurboOnPressureConstraintReason toGateValve:aGateValve];
				}
				else [self removeConstraintName:kTurboOnPressureConstraint  fromGateValve:aGateValve];
			}
			else [self removeConstraintName:kTurboOnPressureConstraint  fromGateValve:aGateValve];
		}
		
		//---------------------------------------------------------------------------
		//the next constraints involve the vacSentry and the cryoRoughing valve
		ORVacuumGateValve* vacSentryValve    = [self gateValve:15];
		ORVacuumGateValve* cryoRoughingValve = [self gateValve:5];
		BOOL PKRG2PressureHigh				 = [self region:kRegionCryoPump valueHigherThan:5];

		//---------------------------------------------------------------------------
		//Opening cryopump roughing valve could expose turbo pump to potentially damaging pressures.
		if([vacSentryValve isOpen] && [cryoRoughingValve isClosed]){
			[self addConstraintName:kTurboOnSentryOpenConstraint reason:kTurboOnSentryOpenConstraintReason toGateValve:cryoRoughingValve];
		}
		else {
			[self removeConstraintName:kTurboOnSentryOpenConstraint fromGateValve:cryoRoughingValve];
		}
		
		//---------------------------------------------------------------------------
		//Opening vacuum sentry could expose turbo pump to potentially damaging pressures.
		if([vacSentryValve isClosed]){
			if([cryoRoughingValve isOpen] && PKRG2PressureHigh){
				[self addConstraintName:kTurboOnCryoRoughingOpenG4HighConstraint reason:kTurboOnCryoRoughingOpenG4HighReason toGateValve:vacSentryValve];
			}
			else [self removeConstraintName:kTurboOnCryoRoughingOpenG4HighConstraint fromGateValve:vacSentryValve];
		}
		else [self removeConstraintName:kTurboOnCryoRoughingOpenG4HighConstraint fromGateValve:vacSentryValve];
	}
	else {
		ORVacuumGateValve* vacSentryValve    = [self gateValve:15];
		ORVacuumGateValve* cryoRoughingValve = [self gateValve:5];
		[self onAllGateValvesremoveConstraintName: kTurboOnPressureConstraint];
		[self removeConstraintName:kTurboOnCryoRoughingOpenG4HighConstraint fromGateValve:vacSentryValve];
		[self removeConstraintName:kTurboOnSentryOpenConstraint fromGateValve:cryoRoughingValve];
		for(ORVacuumGateValve* aGateValve in [self gateValves]){
			[self removeConstraintName:kTurboOnPressureConstraint  fromGateValve:aGateValve];
		}
	}	
}

- (void) addConstraintName:(NSString*)aName reason:(NSString*)aReason toGateValve:(id)aGateValve
{
	[aGateValve addConstraintName:aName reason:aReason];
	if([aGateValve partTag] == 8)		[[self findCryoPump] addPurgeConstraint:aName reason:aReason];
	else if([aGateValve partTag] == 5)	[[self findCryoPump] addRoughingConstraint:aName reason:aReason];
}

- (void) removeConstraintName:(NSString*)aName fromGateValve:(id)aGateValve
{
	[aGateValve removeConstraintName:aName];
	if([aGateValve partTag] == 8)		[[self findCryoPump] removePurgeConstraint:aName];
	else if([aGateValve partTag] == 5)	[[self findCryoPump] removeRoughingConstraint:aName];
}


- (void) checkCryoPumpRelatedConstraints:(ORCP8CryopumpModel*) cryoPump
{
	ORVacuumGateValve* cryoRoughingValve = [self gateValve:5];
	ORVacuumGateValve* cryoPurgeValve    = [self gateValve:8];
	ORVacuumGateValve* CF6Valve			 = [self gateValve:3];
	ORVacuumStatusLabel* cryoRegionObj = [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionCryoPump]];

	BOOL cryoPumpEnabled;
	if(![cryoPump isValid]) cryoPumpEnabled = YES;
	else cryoPumpEnabled = [cryoPump pumpStatus];
		
	//---------------------------------------------------------------------------
	//Opening purge or roughing valve could cause excessive gas condensation on cryo pump.
	if(cryoPumpEnabled){
		if([cryoRoughingValve isClosed]) [self addConstraintName:kCryoCondensationConstraint reason:kCryoCondensationReason toGateValve:cryoRoughingValve];
		else							 [self removeConstraintName:kCryoCondensationConstraint fromGateValve:cryoRoughingValve];
		
		if([cryoPurgeValve isClosed])    [self	addConstraintName:kCryoCondensationConstraint reason:kCryoCondensationReason toGateValve:cryoPurgeValve];
		else							 [self  removeConstraintName:kCryoCondensationConstraint fromGateValve:cryoPurgeValve];
	}
	else {
		[self removeConstraintName:kCryoCondensationConstraint fromGateValve:cryoPurgeValve];
		[self removeConstraintName:kCryoCondensationConstraint fromGateValve:cryoRoughingValve];
		[cryoPump removePumpOnConstraint:kRgaOnOpenToCryoConstraint];
		[cryoRegionObj removeConstraintName:kRgaOnOpenToCryoConstraint];
	}
	
	if([cryoRoughingValve isOpen] && !cryoPumpEnabled){
		[cryoPump addPumpOnConstraint:kRoughingValveOpenCryoConstraint reason:kRoughingValveOpenCryoReason];
		[cryoRegionObj addConstraintName:kRoughingValveOpenCryoConstraint reason:kRoughingValveOpenCryoReason];
	}
	else {
		[cryoPump removePumpOnConstraint:kRoughingValveOpenCryoConstraint];
		[cryoRegionObj removeConstraintName:kRoughingValveOpenCryoConstraint];
	}

	//---------------------------------------------------------------------------
	//Turning Cryopump OFF will expose system to cryo pump evaporation.
	if([CF6Valve isOpen] && cryoPumpEnabled){
		[cryoPump addPumpOffConstraint:k6CFValveOpenCryoConstraint reason:k6CFValveOpenCryoReason];
		[cryoRegionObj addConstraintName:k6CFValveOpenCryoConstraint reason:k6CFValveOpenCryoReason];
	}
	else {
		[cryoPump removePumpOffConstraint:k6CFValveOpenCryoConstraint];
		[cryoRegionObj removeConstraintName:k6CFValveOpenCryoConstraint];
	}
	
	//---------------------------------------------------------------------------
	//If Cryopump is OFF forbid connection of cryopump to detector region
	//loop over all valves if one side is cryo and one side is detector, then put in constraint
	for(ORVacuumGateValve* aGateValve in [self gateValves]){
		if([aGateValve isClosed] && !cryoPumpEnabled){
			int side1				= [aGateValve connectingRegion1];
			int side2				= [aGateValve connectingRegion2];
			
			if([self regionColor:side1 sameAsRegion:side2]){
				[self removeConstraintName:kCryoOffDetectorConstraint fromGateValve:aGateValve];
			}
			else if(([self regionColor:side1 sameAsRegion:kRegionCryostat] && [self regionColor:side2 sameAsRegion:kRegionCryoPump]) ||
					([self regionColor:side2 sameAsRegion:kRegionCryostat] && [self regionColor:side2 sameAsRegion:kRegionCryoPump]) ){
				[self addConstraintName:kCryoOffDetectorConstraint reason:kCryoOffDetectorReason toGateValve:aGateValve];
			}
			else [self removeConstraintName:kCryoOffDetectorConstraint  fromGateValve:aGateValve];
		}
		else [self removeConstraintName:kCryoOffDetectorConstraint  fromGateValve:aGateValve];
	}
	
	if(checkCF6Now)	[self checkCloseConditionOnCF6];
	else				[self performSelector:@selector(checkCloseConditionOnCF6) withObject:nil afterDelay:60];
}

- (void) checkCloseConditionOnCF6
{
	checkCF6Now = YES;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkCloseConditionOnCF6) object:nil];
	ORCP8CryopumpModel* cryoPump = [self findCryoPump];
	BOOL cryoPumpEnabled;
	if(![cryoPump isValid]) cryoPumpEnabled = YES;
	else cryoPumpEnabled = [cryoPump pumpStatus];
	
	ORVacuumGateValve* CF6Valve			 = [self gateValve:3];
	
	//---------------------------------------------------------------------------
	//If Cryopump temp is >20K close the CF6 valve
	float secondStateTempHigh = [cryoPump secondStageTemp]>20;
	if(!cryoPumpEnabled || secondStateTempHigh){
		if([CF6Valve isOpen]){
			[self closeGateValve:3];
			NSLog(@"ORCA closed the gatevalve between cryopump and cryostat because cryopump >20K or temperature is unknown\n");
			if(!orcaClosedCF6TempAlarm){
				NSString* alarmName = [NSString stringWithFormat:@"ORCA Closed %@",[CF6Valve label]];
				orcaClosedCF6TempAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kHardwareAlarm];
				[orcaClosedCF6TempAlarm setHelpString:@"ORCA closed the valve because cryopump temp >20K or unknown. Acknowledging this alarm will clear it."];
				[orcaClosedCF6TempAlarm setSticky:NO];
			}
			[orcaClosedCF6TempAlarm postAlarm];
		}
	}	
}

- (void) checkRGARelatedConstraints:(ORRGA300Model*) rga
{
	BOOL rgaIsOn;
    //if(![rga isValid]) rgaIsOn = YES;
    if(![rga isValid]) rgaIsOn = NO;  //Matt Green asked that this be changed to NO 4/2/16
	else rgaIsOn = [rga filamentIsOn];
	
	ORVacuumStatusLabel* turboRegionObj	= [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionAboveTurbo]];
	ORVacuumStatusLabel* cryoRegionObj	= [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionCryoPump]];
	ORCP8CryopumpModel*  cryoPump		= [self findCryoPump];
	ORTM700Model*		 turboPump		= [self findTurboPump];
	//Do the gatevalves first
	if(rgaIsOn){
		//---------------------------------------------------------------------------
		//Opening valve will expose RGA to potentially damaging pressures.
		for(ORVacuumGateValve* aGateValve in [self gateValves]){
			//check kRgaOnConstraint
			if([aGateValve isClosed]){
				int side1				= [aGateValve connectingRegion1];
				int side2				= [aGateValve connectingRegion2];
				BOOL side1High			= [self region:side1 valueHigherThan:1.0E-5];
				BOOL side2High			= [self region:side2 valueHigherThan:1.0E-5];
				
				if([self regionColor:side1 sameAsRegion:side2]){
					[aGateValve removeConstraintName:kRgaOnConstraint];
				}
				else if([self regionColor:side1 sameAsRegion:kRegionRGA] && side2High ){
					[self addConstraintName:kRgaOnConstraint reason:kRgaConstraintReason toGateValve:aGateValve];
				}
				else if([self regionColor:side2 sameAsRegion:kRegionRGA] && side1High){
					[self addConstraintName:kRgaOnConstraint reason:kRgaConstraintReason toGateValve:aGateValve];
				}
				else [self removeConstraintName:kRgaOnConstraint fromGateValve:aGateValve];
			}
			else [self removeConstraintName:kRgaOnConstraint fromGateValve:aGateValve];
		}
		
		//---------------------------------------------------------------------------
		//Turning cryopump OFF will expose RGA to potentially damaging pressures
		if([self regionColor:kRegionRGA sameAsRegion:kRegionCryoPump]){
			[cryoPump addPumpOffConstraint:kRgaOnOpenToCryoConstraint reason:kRgaOnOpenToCryoReason];
			[cryoRegionObj addConstraintName:kRgaOnOpenToCryoConstraint reason:kRgaOnOpenToCryoReason];
		}
		else {
			[cryoPump removePumpOffConstraint:kRgaOnOpenToCryoConstraint];
			[cryoRegionObj removeConstraintName:kRgaOnOpenToCryoConstraint];
		}
		
		//---------------------------------------------------------------------------
		//Turning Turbopump OFF would expose RGA filament to potentially damaging pressures
		if([self regionColor:kRegionRGA sameAsRegion:kRegionAboveTurbo]){
			[turboPump addPumpOffConstraint:kRgaOnOpenToTurboConstraint reason:kRgaOnOpenToTurboReason];
			[turboRegionObj addConstraintName:kRgaOnOpenToTurboConstraint reason:kRgaOnOpenToTurboReason];
		}
		else {
			[turboPump removePumpOffConstraint:kRgaOnOpenToTurboConstraint];
			[turboRegionObj removeConstraintName:kRgaOnOpenToTurboConstraint];
		}
		//---------------------------------------------------------------------------
	}
	else {
		[self onAllGateValvesremoveConstraintName: kRgaOnConstraint];
		[cryoPump removePumpOffConstraint:kRgaOnOpenToCryoConstraint];
		[cryoRegionObj removeConstraintName:kRgaOnOpenToCryoConstraint];
		
		[turboPump removePumpOffConstraint:kRgaOnOpenToTurboConstraint];
		[turboRegionObj removeConstraintName:kRgaOnOpenToTurboConstraint];
	}	
}

- (void) checkPressureConstraints
{
	ORCP8CryopumpModel* cryopump = [self findCryoPump];
	ORRGA300Model*	    rga		 = [self findRGA];
	
	BOOL cryoIsOn;
	if(![cryopump isValid]) cryoIsOn = YES;
	else cryoIsOn = [cryopump pumpStatus];
	
	ORVacuumStatusLabel* cryoRegionObj = [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionCryoPump]];
	//BOOL  cryoPressureIsHigh = [self region:kRegionCryoPump valueHigherThan:2.0E0];
	BOOL  cryoPressureIsHigh = [self region:kRegionCryoPump valueHigherThan:5.0E0];
	
	//---------------------------------------------------------------------------
	//Turning Cryopump ON could cause excessive gas condensation on cryo pump
	if(!cryoIsOn &&  cryoPressureIsHigh){
		[cryoRegionObj addConstraintName:kPressureTooHighForCryoConstraint reason:kPressureTooHighForCryoReason];
		[cryopump addPumpOnConstraint:kPressureTooHighForCryoConstraint reason:kPressureTooHighForCryoReason];
	}
	else {
		[cryoRegionObj removeConstraintName:kPressureTooHighForCryoConstraint];
		[cryopump removePumpOnConstraint:kPressureTooHighForCryoConstraint];
	}
	
	//---------------------------------------------------------------------------
	ORVacuumStatusLabel* rgaRegionObj	= [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionRGA]];
	//PKR G2>1E-5: Filament could be damaged.
	if([rga ionizerFilamentCurrentRB]==0 && [self region:kRegionRGA valueHigherThan:1E-5]){
		[rga addFilamentConstraint:kRgaFilamentConstraint reason:kRgaFilamentReason];
		[rgaRegionObj addConstraintName:kRgaFilamentConstraint reason:kRgaFilamentReason];
	}
	else {
		[rga removeFilamentConstraint:kRgaFilamentConstraint];
		[rgaRegionObj removeConstraintName:kRgaFilamentConstraint];
	}

	//---------------------------------------------------------------------------
	//PKR G2>5E-7: CEM could be damaged.
	if([rga electronMultiOption] && [rga elecMultHVBiasRB]==0 && [self region:kRegionRGA valueHigherThan:5E-7]){
		[rga addCEMConstraint:kRgaCEMConstraint reason:kRgaCEMReason];
		[rgaRegionObj addConstraintName:kRgaCEMConstraint reason:kRgaCEMReason];
	}
	else {
		[rga removeCEMConstraint:kRgaCEMConstraint];
		[rgaRegionObj removeConstraintName:kRgaCEMConstraint];
	}
	
	for(ORVacuumGateValve* aGateValve in [self gateValves]){
		if([aGateValve isClosed]){
			int side1		= [aGateValve connectingRegion1];
			int side2		= [aGateValve connectingRegion2];
			BOOL side1High	= [self region:side1 valueHigherThan:1.0E-4];
			BOOL side2High	= [self region:side2 valueHigherThan:1.0E-4];
			
			if([self regionColor:side1 sameAsRegion:side2]){
				[aGateValve removeConstraintName:kNegPumpPressConstraint];
			}
			else if([self regionColor:side1 sameAsRegion:kRegionNegPump] && side2High ){
				[self addConstraintName:kNegPumpPressConstraint reason:kNegPumpPressReason toGateValve:aGateValve];
			}
			else if([self regionColor:side2 sameAsRegion:kRegionNegPump] && side1High){
				[self addConstraintName:kNegPumpPressConstraint reason:kNegPumpPressReason toGateValve:aGateValve];
			}
			else [self removeConstraintName:kNegPumpPressConstraint fromGateValve:aGateValve];
		}
		else [self removeConstraintName:kNegPumpPressConstraint fromGateValve:aGateValve];
	}
}

- (void) checkDetectorConstraints
{
	//---------------------------------------------------------------------------
	//Detector Biased: Detector must be protected from regions with pressure higher than 1E-5
    if([self detectorsBiased] || [self noHvInfo]){
        for(ORVacuumGateValve* aGateValve in [self gateValves]){
            if([aGateValve isClosed]){
                int side1		= [aGateValve connectingRegion1];
                int side2		= [aGateValve connectingRegion2];
                BOOL side1High	= [self region:side1 valueHigherThan:1.0E-5];
                BOOL side2High	= [self region:side2 valueHigherThan:1.0E-5];
                
                if([self regionColor:side1 sameAsRegion:side2]){
                    [aGateValve removeConstraintName:kDetectorBiasedConstraint];
                    [aGateValve removeConstraintName:kHVStatusIsUnknownConstraint];
                }
                else if([self regionColor:side1 sameAsRegion:kRegionCryostat] && side2High ){
                    if([self detectorsBiased])[self addConstraintName:kDetectorBiasedConstraint    reason:kDetectorBiasedReason    toGateValve:aGateValve];
					else if([self noHvInfo])  [self addConstraintName:kHVStatusIsUnknownConstraint reason:kHVStatusIsUnknownReason toGateValve:aGateValve];
                }
                else if([self regionColor:side2 sameAsRegion:kRegionCryostat] && side1High){
                    if([self detectorsBiased])[self addConstraintName:kDetectorBiasedConstraint    reason:kDetectorBiasedReason    toGateValve:aGateValve];
					else if([self noHvInfo])  [self addConstraintName:kHVStatusIsUnknownConstraint reason:kHVStatusIsUnknownReason toGateValve:aGateValve];
                }
                else {
					[self removeConstraintName:kDetectorBiasedConstraint    fromGateValve:aGateValve];
					[self removeConstraintName:kHVStatusIsUnknownConstraint fromGateValve:aGateValve];
				}
            }
            else {
				[self removeConstraintName:kDetectorBiasedConstraint    fromGateValve:aGateValve];
				[self removeConstraintName:kHVStatusIsUnknownConstraint fromGateValve:aGateValve];
			}
        }
    }
    else {
		[self onAllGateValvesremoveConstraintName:kDetectorBiasedConstraint];
		[self onAllGateValvesremoveConstraintName:kHVStatusIsUnknownConstraint];
	}
	
	//---------------------------------------------------------------------------
	//PKR G3>1E-5: Should unbias, PKR G3>1E-6: Forbid biasing
	//baratron must be >.75  and <2.0Bar if baratron is used
    //LakeShore A must be >100K is baratron is NOT used
	//Note: the bias info can only get back to the DAQ via the DAQ system script
	double			cyrostatPress		= [self valueForRegion:kRegionCryostat];
	
	//baratron operational?
    if([self coolerMode] == kThermosyphon){
        //these don't count in thermosyphon mode
        [self removeContinuedBiasConstraints:kLakeShoreHighConstraint];
        [self removeOkToBiasConstraints:     kLakeShoreHighConstraint];
        
        ORMks660BModel* baratron			= [self findBaratron];
        float			baratronPressure	= [baratron pressure];
        //in Torr
        float           kLowValue  = 0.7;
        float           kHighValue = 0.9;
        //in Bar
        //float          kLowValue  = 0.9;
        //float          kHighValue = 1.1;
        
        if((baratronPressure >= kLowValue) && (baratronPressure <= kHighValue)){
            //pressure OK, remove constraints
            [self removeContinuedBiasConstraints:kBaratronTooHighConstraint];
            [self removeOkToBiasConstraints:     kBaratronTooHighConstraint];
            [self removeContinuedBiasConstraints:kBaratronTooLowConstraint];
            [self removeOkToBiasConstraints:     kBaratronTooLowConstraint];
        }
        else {
            //nope, not operational
            if(baratronPressure < kLowValue) {
                [self addContinuedBiasConstraints:kBaratronTooLowConstraint  reason:[kBaratronTooLowReason stringByAppendingFormat:@" %.1f",kLowValue]];
                [self addOkToBiasConstraints:     kBaratronTooLowConstraint  reason:[kBaratronTooLowReason stringByAppendingFormat:@" %.1f",kLowValue]];
            }
            else if(baratronPressure > kHighValue)	{
                [self addContinuedBiasConstraints:kBaratronTooHighConstraint reason:[kBaratronTooHighReason stringByAppendingFormat:@" %.1f",kHighValue]];
                [self addOkToBiasConstraints:     kBaratronTooHighConstraint reason:[kBaratronTooHighReason stringByAppendingFormat:@" %.1f",kHighValue]];
            }
        }
	}
    else {
        //these don't count in pulse-tube cooler mode
        [self removeContinuedBiasConstraints:kBaratronTooHighConstraint];
        [self removeOkToBiasConstraints:     kBaratronTooHighConstraint];
        [self removeContinuedBiasConstraints:kBaratronTooLowConstraint];
        [self removeOkToBiasConstraints:     kBaratronTooLowConstraint];

        id lakeShore			= [self findLakeShore];
        float lakeShoreTemp;
        BOOL  isValid;
        if([lakeShore isKindOfClass:NSClassFromString(@"ORLakeShore336Model")]){
            lakeShoreTemp = [(ORLakeShore336Model*)lakeShore convertedValue:0];
            isValid = [(ORLakeShore336Model*)lakeShore isValid];
        }
        else {
            lakeShoreTemp = [(ORLakeShore210Model*)lakeShore convertedValue:7];
            isValid = [(ORLakeShore210Model*)lakeShore isValid];
       }
        if((lakeShoreTemp <=100) && isValid){ //cold enough?
            [self removeContinuedBiasConstraints:kLakeShoreHighConstraint];
            [self removeOkToBiasConstraints:kLakeShoreHighConstraint];
         }
        else {
            [self addContinuedBiasConstraints:kLakeShoreHighConstraint  reason:kLakeShoreHighReason];
            [self addOkToBiasConstraints:     kLakeShoreHighConstraint  reason:kLakeShoreHighReason];
        }
    }
	//cryostat region pressure must be <1E-5 to stay biased (also must be non-zero -- zero indicates no data)
    
    if(cyrostatPress==0){
        [self addContinuedBiasConstraints:kG3NoDataConstraint  reason:kG3NoDataReason];
        [self addOkToBiasConstraints:     kG3NoDataConstraint  reason:kG3NoDataReason];
    }
    else {
        //there is data on G3, so remove these constrainst. The pressure may be bad so continue check.
        [self removeContinuedBiasConstraints: kG3NoDataConstraint];
        [self removeOkToBiasConstraints:      kG3NoDataConstraint];

        if(cyrostatPress>1E-5) [self addContinuedBiasConstraints:kG3WayHighConstraint  reason:kG3WayHighReason];
        else                   [self removeContinuedBiasConstraints:kG3WayHighConstraint];
        
        //cryostat region pressure must be <1E-6 to allow biasing
        if(cyrostatPress>1E-6) [self addOkToBiasConstraints:kG3HighConstraint  reason:kG3HighReason];
        else                   [self removeOkToBiasConstraints:kG3HighConstraint];
    }
}

@end
