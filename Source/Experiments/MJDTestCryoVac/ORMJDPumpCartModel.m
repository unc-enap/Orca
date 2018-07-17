//
//  ORMJDPumpCartModel.m
//  Orca
//
//  Created by Mark Howe on Mon Aug 13, 2012.
//  Copyright ¬© 2012 CENPA, University of North Carolina. All rights reserved.
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
#import "ORMJDPumpCartModel.h"
#import "ORMJDVacuumView.h"
#import "ORProcessModel.h"
#import "ORAdcModel.h"
#import "ORAdcProcessing.h"
#import "ORMks660BModel.h"
#import "ORRGA300Model.h"
#import "ORTM700Model.h"
#import "ORTPG256AModel.h"
#import "ORLakeShore210Model.h"
#import "ORMJDTestCryostat.h"

@interface ORMJDPumpCartModel (private)
- (void) makeParts;
- (void) makePipes:(VacuumPipeStruct*)pipeList num:(int)numItems;
- (void) makeGateValves:(VacuumGVStruct*)pipeList num:(int)numItems;
- (void) makeStaticLabels:(VacuumStaticLabelStruct*)labelItems num:(int)numItems;
- (void) makeDynamicLabels:(VacuumDynamicLabelStruct*)labelItems num:(int)numItems;
- (void) makeTestStands;
- (void) colorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor;
- (void) recursizelyColorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor;
- (void) resetVisitationFlag;
- (void) disconnectLeftSide;
- (void) connectLeftSideToCryostat:(int)anIndex;
- (void) disconnectRightSide;
- (void) connectRightSideToCryostat:(int)anIndex;

- (double) valueForRegion:(int)aRegion;
- (ORVacuumValueLabel*) regionValueObj:(int)aRegion;
- (BOOL) valueValidForRegion:(int)aRegion;
- (BOOL) region:(int)aRegion valueHigherThan:(double)aValue;

- (ORRGA300Model*)          findRGA;
- (ORTM700Model*)           findTurboPump;
- (ORTPG256AModel*)         findPressureGauge:(int)aSlot;
- (ORLakeShore210Model*)    findTemperatureGauge:(int)aSlot;
- (id) findObject:(NSString*)aClassName;
- (id) findObject:(NSString*)aClassName inSlot:(int)aSlot;
- (void)postCouchRecord;

@end


NSString* ORMJDPumpCartModelShowGridChanged				 = @"ORMJDPumpCartModelShowGridChanged";
NSString* ORMJCTestCryoVacLock                           = @"ORMJCTestCryoVacLock";
NSString* ORMJDPumpCartModelRightSideConnectionChanged   = @"ORMJDPumpCartModelRightSideConnectionChanged";
NSString* ORMJDPumpCartModelLeftSideConnectionChanged    = @"ORMJDPumpCartModelLeftSideConnectionChanged";
NSString* ORMJDPumpCartModelConnectionChanged			 = @"ORMJDPumpCartModelConnectionChanged";

@implementation ORMJDPumpCartModel

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[parts release];
	[partDictionary release];
	[valueDictionary release];
	[testCryostats release];
	[super dealloc];
}


- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"MJDPumpCart.tif"]];
}

- (NSString*) helpURL
{
	return nil;
}

- (void) makeMainController
{
    [self linkToController:@"ORMJDPumpCartController"];
}

- (void) registerNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	//we need to know about a specific set of events in order to handle the constraints
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
	
	ORTPG256AModel* pressureGauge1 = [self findPressureGauge:2];
	ORTPG256AModel* pressureGauge2 = [self findPressureGauge:3];
	if(pressureGauge1){
		[notifyCenter addObserver : self
						 selector : @selector(pressureGaugeChanged:)
							 name : ORTPG256APressureChanged
						   object : pressureGauge1];
		
		[notifyCenter addObserver : self
						 selector : @selector(pressureGaugeChanged:)
							 name : ORSerialPortWithQueueModelIsValidChanged
						   object : pressureGauge1];
	}
	if(pressureGauge2){
		[notifyCenter addObserver : self
						 selector : @selector(pressureGaugeChanged:)
							 name : ORTPG256APressureChanged
						   object : pressureGauge2];
		
		[notifyCenter addObserver : self
						 selector : @selector(pressureGaugeChanged:)
							 name : ORSerialPortWithQueueModelIsValidChanged
						   object : pressureGauge2];
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
    
    ORLakeShore210Model* temperatureGauge1 = [self findTemperatureGauge:4];
    ORLakeShore210Model* temperatureGauge2 = [self findTemperatureGauge:5];
    ORLakeShore210Model* temperatureGauge3 = [self findTemperatureGauge:6];
    ORLakeShore210Model* temperatureGauge4 = [self findTemperatureGauge:7];
    if(temperatureGauge1){
        [notifyCenter addObserver : self
                         selector : @selector(temperatureGaugeChanged:)
                             name : ORLakeShore210TempChanged
                           object : temperatureGauge1];
        
        [notifyCenter addObserver : self
                         selector : @selector(temperatureGaugeChanged:)
                             name : ORSerialPortWithQueueModelIsValidChanged
                           object : temperatureGauge1];
    }
    
    if(temperatureGauge2){
        [notifyCenter addObserver : self
                         selector : @selector(temperatureGaugeChanged:)
                             name : ORLakeShore210TempChanged
                           object : temperatureGauge2];
        
        [notifyCenter addObserver : self
                         selector : @selector(temperatureGaugeChanged:)
                             name : ORSerialPortWithQueueModelIsValidChanged
                           object : temperatureGauge2];
    }
    if(temperatureGauge3){
        [notifyCenter addObserver : self
                         selector : @selector(temperatureGaugeChanged:)
                             name : ORLakeShore210TempChanged
                           object : temperatureGauge3];
        
        [notifyCenter addObserver : self
                         selector : @selector(temperatureGaugeChanged:)
                             name : ORSerialPortWithQueueModelIsValidChanged
                           object : temperatureGauge3];
    }
    if(temperatureGauge4){
        [notifyCenter addObserver : self
                         selector : @selector(temperatureGaugeChanged:)
                             name : ORLakeShore210TempChanged
                           object : temperatureGauge4];
        
        [notifyCenter addObserver : self
                         selector : @selector(temperatureGaugeChanged:)
                             name : ORSerialPortWithQueueModelIsValidChanged
                           object : temperatureGauge4];
    }
}

- (BOOL) detectorsBiased		{ return NO; }

- (void) turboChanged:(NSNotification*)aNote
{
	ORTM700Model* turboPump = [aNote object];
    ORVacuumStatusLabel* turboRegionObj = [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionAboveTurbo]];
	[turboRegionObj setIsValid:[turboPump isValid]];
	[turboRegionObj setStatusLabel:[turboPump auxStatusString:0]];	
}

- (void) pressureGaugeChanged:(NSNotification*)aNote
{
	ORTPG256AModel* pressureGauge = [aNote object];
	int chan = [[[aNote userInfo] objectForKey:@"Channel"]intValue];
	int componentTag = (int)[pressureGauge tag];
	int aRegion;
	for(aRegion=0;aRegion<kNumberRegions;aRegion++){
		ORVacuumValueLabel*  aLabel = [self regionValueObj:aRegion]; 
		if([aLabel channel ] == chan && [aLabel component] == componentTag){
			[aLabel setIsValid:[pressureGauge isValid]]; 
			[aLabel setValue:[pressureGauge pressure:[aLabel channel]]]; 
		}
	}
	
	for(id aCryostat in testCryostats){
		[aCryostat pressureGaugeChanged:aNote];
	}
}

- (void) temperatureGaugeChanged:(NSNotification*)aNote
{
    for(id aCryostat in testCryostats){
        [aCryostat temperatureGaugeChanged:aNote];
    }
}

- (void) rgaChanged:(NSNotification*)aNote
{
	ORRGA300Model* rga = [aNote object];
	ORVacuumStatusLabel* rgaRegionObj = [statusDictionary objectForKey:[NSNumber numberWithInt:kRegionRGA]];
	[rgaRegionObj setIsValid:[rga isValid]];
	[rgaRegionObj setStatusLabel:[rga auxStatusString:0]];	
}

#pragma mark ***Accessors
- (BOOL) showGrid
{
    return showGrid;
}

- (void) setShowGrid:(BOOL)aShowGrid
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowGrid:showGrid];
    showGrid = aShowGrid;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPumpCartModelShowGridChanged object:self];
}

- (void) toggleGrid
{
	[self setShowGrid:!showGrid];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	[self setShowGrid:	[decoder decodeBoolForKey:	@"showGrid"]];

	[self makeParts];

	[self setLeftSideConnection:	[decoder decodeIntForKey:	@"leftSideConnection"]];
	[self setRightSideConnection:	[decoder decodeIntForKey:	@"rightSideConnection"]];
	
	[self registerNotificationObservers];
	
	[[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:showGrid				forKey: @"showGrid"];
    [encoder encodeInteger:leftSideConnection		forKey: @"leftSideConnection"];
    [encoder encodeInteger:rightSideConnection		forKey: @"rightSideConnection"];
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

- (int) leftSideConnection
{
	return leftSideConnection;
}

- (void) setLeftSideConnection:(int)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLeftSideConnection:leftSideConnection];
	if(aState == 0)[self disconnectLeftSide];
	else [self connectLeftSideToCryostat:aState-1];
    leftSideConnection = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPumpCartModelLeftSideConnectionChanged object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPumpCartModelConnectionChanged object:self];
    if(!couchPostScheduled){
        couchPostScheduled = YES;
        [self performSelector:@selector(postCouchRecord) withObject:nil afterDelay:10];
    }
}

- (int) rightSideConnection
{
	return rightSideConnection;
}

- (void) setRightSideConnection:(int)aState
{
	[[[self undoManager] prepareWithInvocationTarget:self] setRightSideConnection:rightSideConnection];
	if(aState == 0)[self disconnectRightSide];
	else [self connectRightSideToCryostat:aState-1];
	rightSideConnection = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPumpCartModelRightSideConnectionChanged object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDPumpCartModelConnectionChanged object:self];
    
    if(!couchPostScheduled){
        couchPostScheduled = YES;
        [self performSelector:@selector(postCouchRecord) withObject:nil afterDelay:10];
    }
}


#pragma mark •••CardHolding Protocol
- (int) maxNumberOfObjects	{ return 8;  }
- (int) objWidth			{ return 60; }
- (int) groupSeparation		{ return 0;  }	
- (NSString*) nameForSlot:(int)aSlot	
{ 
    return [NSString stringWithFormat:@"Slot %d",aSlot]; 
}

- (NSRange) legalSlotsForObj:(id)anObj
{
	if([anObj isKindOfClass:NSClassFromString(@"ORTM700Model")])                return NSMakeRange(0,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORRGA300Model")])          return NSMakeRange(1,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORTPG256AModel")])         return NSMakeRange(2,1);
    else if([anObj isKindOfClass:NSClassFromString(@"ORTPG256AModel")])         return NSMakeRange(3,1);
    else if([anObj isKindOfClass:NSClassFromString(@"ORLakeShore210Model")])	return NSMakeRange(4,4);
	else return NSMakeRange(0,0);
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj 
{ 
	if(aSlot == 0      && [anObj isKindOfClass:NSClassFromString(@"ORTM700Model")])         return NO;
	else if(aSlot == 1 && [anObj isKindOfClass:NSClassFromString(@"ORRGA300Model")])        return NO;
	else if(aSlot == 2 && [anObj isKindOfClass:NSClassFromString(@"ORTPG256AModel")])       return NO;
    else if(aSlot == 3 && [anObj isKindOfClass:NSClassFromString(@"ORTPG256AModel")])       return NO;
    else if(aSlot >= 4 && [anObj isKindOfClass:NSClassFromString(@"ORLakeShore210Model")])	return NO;
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
		case kRegionDryN2:			return @"Dry N2";
		case kRegionDiaphramPump:	return @"Diaphram Pump";
		case kRegionBelowTurbo:		return @"Below Turbo";
		default: return nil;
	}
}
- (ORMJDTestCryostat*) testCryoStat:(int)i
{
	if(i < [testCryostats count]){
		return [testCryostats objectAtIndex:i];
	}
	else return nil;
}

@end


@implementation ORMJDPumpCartModel (private)
- (ORRGA300Model*)      findRGA                         { return [self findObject:@"ORRGA300Model"];      }
- (ORTM700Model*)       findTurboPump                   { return [self findObject:@"ORTM700Model"];       }
- (ORTPG256AModel*)     findPressureGauge:(int)aSlot    { return [self findObject:@"ORTPG256AModel"      inSlot:aSlot];     }
- (ORLakeShore210Model*)findTemperatureGauge:(int)aSlot { return [self findObject:@"ORLakeShore210Model" inSlot:aSlot];     }

- (id) findObject:(NSString*)aClassName
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj isKindOfClass:NSClassFromString(aClassName)])return anObj;
	}
	return nil;
}

- (id) findObject:(NSString*)aClassName inSlot:(int)aSlot
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj isKindOfClass:NSClassFromString(aClassName)]){
			if([anObj tag] == aSlot)return anObj;
		}
	}
	return nil;
}


- (void) makeParts
{
#define kNumVacPipes		20
	VacuumPipeStruct vacPipeList[kNumVacPipes] = {
		//region 0 pipes
		{ kVacVPipe,  kRegionDiaphramPump, 250,				70,				250,					100 }, 
		
		//region 1 pipes
		{ kVacVPipe,  kRegionBelowTurbo, 250,				100,			250,					150 }, 
		
		//region 2 pipes
		{ kVacVPipe,  kRegionAboveTurbo, 250,				150,			250,					300 }, 
		{ kVacHPipe,  kRegionAboveTurbo, 200,				215,			250-kPipeRadius,		215 },
		{ kVacHPipe,  kRegionAboveTurbo, 250+kPipeRadius,	215,			280,					215 },
		{ kVacHPipe,  kRegionAboveTurbo, 280,				215,			300,					215 },
		{ kVacHPipe,  kRegionAboveTurbo, 250+kPipeRadius,	335,			280,					335 },
		
		{ kVacHPipe,  kRegionAboveTurbo, 250+kPipeRadius,	270,			300,					270 },
		{ kVacHPipe,  kRegionAboveTurbo, 200,				270,			250-kPipeRadius,		270 },

		//region 3 pipes
		{ kVacVPipe,  kRegionRGA,		250,				300,			250,				320 },
	
		//region 5 pipes
		{ kVacCorner, kRegionLeftSide, 100,					270,			kNA,				kNA },
		{ kVacHPipe,  kRegionLeftSide, 100+kPipeRadius,		270,			200,				270 },
		{ kVacVPipe,  kRegionLeftSide, 100,					270+kPipeRadius,100,				405 },
		{ kVacHPipe,  kRegionLeftSide, 100+kPipeRadius,		335,			140,				335 },
		{ kVacHPipe,  kRegionLeftSide, 75,					335,			100-kPipeRadius,	335 },

		//region 6 pipes
		{ kVacCorner, kRegionRightSide, 400,				270,			kNA,				kNA },
		{ kVacHPipe,  kRegionRightSide, 300,				270,			400,				270 },
		{ kVacVPipe,  kRegionRightSide, 400,				270+kPipeRadius,400,				405 },
		{ kVacHPipe,  kRegionRightSide, 360,				335,			400-kPipeRadius,	335 },
		{ kVacHPipe,  kRegionRightSide, 400+kPipeRadius,	335,			425,				335 },
	};
	
#define kNumStaticLabelItems	2
	VacuumStaticLabelStruct staticLabelItems[kNumStaticLabelItems] = {
		{kVacStaticLabel, kRegionDryN2,			@"Dry N2\nSupply",	300,  200,	360, 230},
		{kVacStaticLabel, kRegionDiaphramPump,	@"Diaphragm\nPump",	 220,  40,	 280, 70},
	};	
	
#define kNumStatusItems	5
	VacuumDynamicLabelStruct dynamicLabelItems[kNumStatusItems] = {
		//type,	region, component, channel
		{kVacStatusItem,   kRegionAboveTurbo,	0, 5,  @"Turbo",	220, 135,	280, 165},
		{kVacStatusItem,   kRegionRGA,			1, 6,  @"RGA",		220, 320,	280, 350},
		{kVacPressureItem, kRegionAboveTurbo,	2, 0,  @"PKR G1",	140, 200,	200, 230},
		{kVacPressureItem, kRegionLeftSide,		2, 1,  @"PKR G2",	140, 320,	200, 350},
		{kVacPressureItem, kRegionRightSide,	2, 2,  @"PKR G3",	300, 320,	360, 350},
	};	
		
#define kNumVacGVs			10
	VacuumGVStruct gvList[kNumVacGVs] = {
		{kVacVGateV, 0,	@"N2 Manual",	kManualOnlyShowChanging,	280, 215,	kRegionDryN2,		kRegionAboveTurbo,		kControlNone},	//Manual N2 supply
		{kVacHGateV, 1,	@"Turbo",		k1BitReadBack,				250, 150,	kRegionAboveTurbo,	kRegionBelowTurbo,		kControlNone},	//this is a virtual valve-- really the turbo on/off
		{kVacHGateV, 2,	@"Sentry",		kManualOnlyShowChanging,	250, 100,	kRegionDiaphramPump,kRegionBelowTurbo,		kControlNone},	//future control
		{kVacHGateV, 3,	@"RGA",			kManualOnlyShowChanging,	250, 300,	kRegionRGA,			kRegionAboveTurbo,		kControlNone},	
		{kVacVGateV, 4,	@"",			kManualOnlyShowChanging,	200, 270,	kRegionRGA,			kRegionAboveTurbo,		kControlNone},	
		{kVacVGateV, 5,	@"",			kManualOnlyShowChanging,	300, 270,	kRegionRGA,			kRegionAboveTurbo,		kControlNone},	
		{kVacVGateV, 6,	@"",			kManualOnlyShowClosed,		75,  335,	kRegionLeftSide,	kUpToAir,				kControlNone},	
		{kVacVGateV, 7,	@"",			kManualOnlyShowClosed,		425, 335,	kRegionRightSide,	kUpToAir,				kControlNone},	
		{kVacHGateV, 8,	@"",			kManualOnlyShowClosed,		100, 405,	kRegionRightSide,	kUpToAir,				kControlNone},	
		{kVacHGateV, 9,	@"",			kManualOnlyShowClosed,		400, 405,	kRegionRightSide,	kUpToAir,				kControlNone},	
	};
	
	[self makePipes:vacPipeList					num:kNumVacPipes];
	[self makeGateValves:gvList					num:kNumVacGVs];
	[self makeStaticLabels:staticLabelItems		num:kNumStaticLabelItems];
	[self makeDynamicLabels:dynamicLabelItems	num:kNumStatusItems];
	
	[self makeTestStands];
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

- (void) makeTestStands
{
	if(!testCryostats){
		testCryostats = [[NSMutableArray array]retain];
		int i;
		for(i=0;i<7;i++){
			ORMJDTestCryostat* aTestCryostat = [[ORMJDTestCryostat alloc] init];
			[testCryostats addObject:aTestCryostat];
			[aTestCryostat setDelegate:self];
			[aTestCryostat setTag:i];
			[aTestCryostat makeParts];
			[aTestCryostat release];
		}
	}
}

- (void) colorRegions
{
	#define kNumberPriorityRegions 9
	int regionPriority[kNumberPriorityRegions] = {4,6,1,0,3,8,7,2,5}; //lowest to highest
					
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
    if(!couchPostScheduled){
        couchPostScheduled = YES;
        [self performSelector:@selector(postCouchRecord) withObject:nil afterDelay:10];
    }
}

- (void)postCouchRecord
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(postCouchRecord) object:nil];
    
    couchPostScheduled = NO;

    if([[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORCouchDBModel")] count]>0){

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
        [values setObject: [NSNumber numberWithInt:leftSideConnection]                   forKey:@"LeftSideConnection"];
        [values setObject: [NSNumber numberWithInt:rightSideConnection]                    forKey:@"RightSideConnection"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
    }
    [self performSelector:@selector(postCouchRecord) withObject:nil afterDelay:10];
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
	else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumStatusLabel")]){
		[[partDictionary objectForKey:@"StatusLabels"] addObject:aPart];
		[statusDictionary setObject:aPart forKey:[NSNumber numberWithInt:[aPart regionTag]]];
	}
	else if([aPart isKindOfClass:NSClassFromString(@"ORVacuumStaticLabel")]){
		[[partDictionary objectForKey:@"StaticLabels"] addObject:aPart];
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
	return [[self regionValueObj:aRegion] valueHigherThan:aValue];
}

- (BOOL) valueValidForRegion:(int)aRegion
{
	return [[self regionValueObj:aRegion] isValid];
}

- (double) valueForRegion:(int)aRegion
{	
	return [[self regionValueObj:aRegion] value];
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

- (void) disconnectLeftSide
{
	for(id aCryostat in testCryostats){
		if([aCryostat connectionStatus] == kConnectedToLeftSide)[aCryostat setConnectionStatus:kNotConnected];
	}
}

- (void) connectLeftSideToCryostat:(int)anIndex
{
	for(id aCryostat in testCryostats){
		if([aCryostat connectionStatus] == kConnectedToLeftSide && [aCryostat tag] != anIndex)[aCryostat setConnectionStatus:kNotConnected];
		if([aCryostat tag] == anIndex) [aCryostat setConnectionStatus:kConnectedToLeftSide];
	}
}

- (void) disconnectRightSide
{
	for(id aCryostat in testCryostats){
		if([aCryostat connectionStatus] == kConnectedToRightSide)[aCryostat setConnectionStatus:kNotConnected];
	}
}

- (void) connectRightSideToCryostat:(int)anIndex
{
	for(id aCryostat in testCryostats){
		if([aCryostat connectionStatus] == kConnectedToRightSide && [aCryostat tag] != anIndex)[aCryostat setConnectionStatus:kNotConnected];
		if([aCryostat tag] == anIndex) [aCryostat setConnectionStatus:kConnectedToRightSide];
	}
}

@end
