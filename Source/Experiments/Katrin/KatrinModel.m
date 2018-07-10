//
//  KatrinModel.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 28 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "KatrinModel.h"
#import "KatrinController.h"
#import "ORFPDSegmentGroup.h"
#import "KatrinConstants.h"
#import "ORSocketClient.h"
#import "ORCommandCenter.h"
#import "ORDetectorSegment.h"

NSString* KatrinModelFPDOnlyModeChanged             = @"KatrinModelFPDOnlyModeChanged";
NSString* KatrinModelSlowControlIsConnectedChanged  = @"KatrinModelSlowControlIsConnectedChanged";
NSString* KatrinModelSlowControlNameChanged			= @"KatrinModelSlowControlNameChanged";
NSString* ORKatrinModelViewTypeChanged				= @"ORKatrinModelViewTypeChanged";
NSString* ORKatrinModelSNTablesChanged				= @"ORKatrinModelSNTablesChanged";
NSString* ORKatrinModelHiLimitChanged               = @"ORKatrinModelHiLimitChanged";
NSString* ORKatrinModelLowLimitChanged              = @"ORKatrinModelLowLimitChanged";
NSString* ORKatrinModelSlopeChanged                 = @"ORKatrinModelSlopeChanged";
NSString* ORKatrinModelInterceptChanged             = @"ORKatrinModelInterceptChanged";
NSString* ORKatrinModelMaxValueChanged              = @"ORKatrinModelMaxValueChanged";

static NSString* KatrinDbConnector		= @"KatrinDbConnector";
@interface KatrinModel (private)
- (void) validateSNArrays;
- (NSString*) addOldFPDMapFormat:(NSMutableDictionary*)aDictionary;
- (NSString*) addOldVetoMapFormat:(NSMutableDictionary*)aDictionary;
- (NSString*) auxParamsString:(NSArray*)auxArray keys:(NSArray*)keys;
- (NSString*) mapFileHeader:(int)tag;
@end

@implementation KatrinModel

#pragma mark ¥¥¥Initialization
- (void) wakeUp
{
	[super wakeUp];
	BOOL exists = [[ORCommandCenter sharedCommandCenter] clientWithNameExists:slowControlName];
	[self setSlowControlIsConnected: exists];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"katrin"]];
}

- (void) makeMainController
{
    [self linkToController:@"KatrinController"];
}

- (NSString*) helpURL
{
	return @"KATRIN/Index.html";
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - 35,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:KatrinDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB O' ];
	[ aConnector addRestrictedConnectionType: 'DB I' ]; //can only connect to DB outputs
    [aConnector release];
}

- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(slowControlConnectionChanged:)
                         name : ORCommandClientsChangedNotification
                       object : nil];
	
}

- (void) slowControlConnectionChanged:(NSNotification*)aNote
{
	ORSocketClient* theClient = [[aNote userInfo] objectForKey:@"client"];
	if([[theClient name] isEqualToString:slowControlName]){
		BOOL exists = [[[ORCommandCenter sharedCommandCenter]clients] containsObject:theClient];
		[self setSlowControlIsConnected: [theClient isConnected] && exists];
	}
}

#pragma mark ¥¥¥Accessors

- (BOOL) fpdOnlyMode
{
    return fpdOnlyMode;
}

- (void) setFPDOnlyMode:(BOOL)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFPDOnlyMode:fpdOnlyMode];
    
    fpdOnlyMode = aMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelFPDOnlyModeChanged object:self];
}

- (void) toggleFPDOnlyMode
{
    [self setFPDOnlyMode:!fpdOnlyMode];
    ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:1];
    NSArray* cards = [[(ORAppDelegate*)[NSApp delegate]document] collectObjectsOfClass:NSClassFromString([aGroup adcClassName])];
    for(id aCard in cards){
        if([self fpdOnlyMode]){
            if([aCard respondsToSelector:@selector(disableAllTriggersIfInVetoMode)]){
                [aCard disableAllTriggersIfInVetoMode];
            }
        }
        else {
            if([aCard respondsToSelector:@selector(restoreTriggersIfInVetoMode)]){
                [aCard restoreTriggersIfInVetoMode];
            }
        }
    }
    
}

- (float) lowLimit:(int)i
{
	if(i>=0 && i<2)return lowLimit[i];
	else return 0;
}

- (void) setLowLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:i value:lowLimit[i]];
		
		lowLimit[i] = aValue; 
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelLowLimitChanged object:self];
		
	}
}

- (float) hiLimit:(int)i
{
	if(i>=0 && i<2)return hiLimit[i];
	else return 0;
}

- (void) setHiLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setHiLimit:i value:lowLimit[i]];
		
		hiLimit[i] = aValue; 
			
		[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelHiLimitChanged object:self];
		
	}
}

- (float) maxValue:(int)i
{
	if(i>=0 && i<2)return maxValue[i];
	else return 0;
}

- (void) setMaxValue:(int)i value:(float)aValue
{
	if(i>=0 && i<2){
		[[[self undoManager] prepareWithInvocationTarget:self] setMaxValue:i value:maxValue[i]];
		
		maxValue[i] = aValue; 
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelMaxValueChanged object:self];
		
	}
}

- (NSString*) slowControlName;
{
	if(!slowControlName)return @"";
	return slowControlName;
}

- (void) setSlowControlName:(NSString*)aName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlowControlName:slowControlName];
    
	[slowControlName autorelease];
    slowControlName = [aName copy];    
	
	BOOL exists = [[ORCommandCenter sharedCommandCenter] clientWithNameExists:slowControlName];
	[self setSlowControlIsConnected: exists];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelSlowControlNameChanged object:self];
	
}

- (BOOL) slowControlIsConnected
{
	return slowControlIsConnected;
}

- (void) setSlowControlIsConnected:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlowControlIsConnected:slowControlIsConnected];
    
    slowControlIsConnected = aState;    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:KatrinModelSlowControlIsConnectedChanged object:self];
	
}
- (void) collectRates
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectRates) object:nil];
	if([self guardian]){
		[self collectRatesFromAllGroups];
        
		[[NSNotificationCenter defaultCenter]
         postNotificationName:ExperimentCollectedRates
         object:self];
        
	}
	[self performSelector:@selector(collectRates) withObject:nil afterDelay:1.0];
}
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)aDictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
	
	[[segmentGroups objectAtIndex:0] addParametersToDictionary:objDictionary useName:@"FPDGeometry" addInGroupName:NO];
	[[segmentGroups objectAtIndex:1] addParametersToDictionary:objDictionary useName:@"VetoGeometry2018" addInGroupName:NO];
	
	//NSString* rootMapFile = [[[segmentGroups objectAtIndex:0] mapFile] stringByExpandingTildeInPath];
	//rootMapFile = [rootMapFile stringByDeletingPathExtension];

	//add the FLT/ORB SN
	NSArray* keys = [NSArray arrayWithObjects:@"kFltSlot",@"kFltSN",@"kORBSN",nil];
	[objDictionary setObject:[self auxParamsString:fltSNs keys:keys] forKey:@"FltOrbSNs"];
	
	//add the Preamp SN
	keys = [NSArray arrayWithObjects:@"kPreAmpMod",@"kPreAmpSN",nil];
	[objDictionary setObject:[self auxParamsString:preAmpSNs keys:keys] forKey:@"PreampSNs"];
	
	//add the OSB SN
	keys = [NSArray arrayWithObjects:@"kOSBSlot",@"kOSBSN",nil];
	[objDictionary setObject:[self auxParamsString:osbSNs keys:keys] forKey:@"OsbSNs"];
	
	//add the SLT and Wafer SN
	NSString* keySlt[2] = {@"kSltSN",@"kWaferSN"};
	NSString* result = [NSString string];
	int i;
	for(i=0;i<2;i++){
		id aParam = [otherSNs objectForKey:keySlt[i]];
		if(aParam) result = [result stringByAppendingFormat:@"%@",aParam];
		else result = [result stringByAppendingString:@"--"];
		if(i<1)result = [result stringByAppendingString:@","];
	}
	result = [result stringByAppendingString:@"\n"];
    [objDictionary setObject:result forKey:@"SltWaferSNs"];
	
	//for backward compatibility with the analysis code
	
//    NSMutableDictionary* mapDictionary;
//    mapDictionary = [NSMutableDictionary dictionary];
//    [mapDictionary setObject:[self addOldFPDMapFormat:aDictionary] forKey:@"Geometry"];
//    [objDictionary setObject:mapDictionary forKey:@"Focal Plane"];
 //    mapDictionary = [NSMutableDictionary dictionary];
//    [mapDictionary setObject:[self addOldVetoMapFormat:aDictionary] forKey:@"Geometry"];
//    [objDictionary setObject:mapDictionary forKey:@"Veto"];
	
    [aDictionary setObject:objDictionary forKey:[self className]];
    return aDictionary;
}


#pragma mark ¥¥¥Segment Group Methods
- (void) makeSegmentGroups
{
    ORFPDSegmentGroup* group = [[ORFPDSegmentGroup alloc] initWithName:@"Focal Plane" numSegments:kNumFocalPlaneSegments mapEntries:[self setupMapEntries:0]];
	[self addGroup:group];
	[group release];
	
    ORSegmentGroup* group2 = [[ORSegmentGroup alloc] initWithName:@"Veto" numSegments:kNumVetoSegments mapEntries:[self setupMapEntries:1]];
	[self addGroup:group2];
	[group2 release];
}

- (NSMutableArray*) setupMapEntries:(int)index
{
    [self setCardIndex:kCardSlot];
    [self setChannelIndex:kChannel];
	if(index==1){ //veto map
		NSMutableArray* mapEntries = [NSMutableArray array];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSlot",			@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"PanelSN",        @"key", [NSNumber numberWithInt:0],    @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"VetoSumChannel",    @"key", [NSNumber numberWithInt:0],    @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"AmpBoardNum",    @"key", [NSNumber numberWithInt:0],    @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"AmpChannel",        @"key", [NSNumber numberWithInt:0],    @"sortType", nil]];
		return mapEntries;
	}
	else {
		NSMutableArray* mapEntries = [NSMutableArray array];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSegmentNumber",	@"key", [NSNumber numberWithInt:0], @"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kSlot",			@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
		[mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kChannel",		@"key", [NSNumber numberWithInt:0],	@"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreampModule",    @"key", [NSNumber numberWithInt:0],    @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kPreampChannel",    @"key", [NSNumber numberWithInt:0],    @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kOSBSlot",        @"key", [NSNumber numberWithInt:0],    @"sortType", nil]];
        [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"kOSBChannel",    @"key", [NSNumber numberWithInt:0],    @"sortType", nil]];
		return mapEntries;
	}
}

- (int)  maxNumSegments
{
	return kNumFocalPlaneSegments;
}


- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
	if(aSet == 0){
		//the focal plane
		NSString* finalString = @"";
		NSArray* parts = [aString componentsSeparatedByString:@"\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@"Focal Plane" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Segment" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[[self getPartStartingWith:@" Slot"    parts:parts]stringByReplacingOccurrencesOfString:@"    Slot" withString:@"FLT Slot"]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[[self getPartStartingWith:@" Channel" parts:parts]stringByReplacingOccurrencesOfString:@"    Channel" withString:@"FLT Channel"]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Threshold" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Gain" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" PreampModule" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" PreampChannel" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" OSBSlot" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@",[self getPartStartingWith:@" OSBChannel" parts:parts]];
		return finalString;
	}
	else {
		//the veto
		//the focal plane
		NSString* finalString = @"";
		NSArray* parts = [aString componentsSeparatedByString:@"\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@"Veto" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Segment" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[[self getPartStartingWith:@" Slot"    parts:parts]stringByReplacingOccurrencesOfString:@"    Slot" withString:@"FLT Slot"]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[[self getPartStartingWith:@" Channel" parts:parts]stringByReplacingOccurrencesOfString:@"    Channel" withString:@"FLT Channel"]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Threshold" parts:parts]];
		finalString = [finalString stringByAppendingFormat:@"%@\n",[self getPartStartingWith:@" Gain" parts:parts]];
		finalString = [finalString stringByAppendingString:@"-----------------------\n"];
		return finalString;
	}
}

- (NSString*) getPartStartingWith:(NSString*)aLabel parts:(NSArray*)parts
{
	for(id aLine in parts){
		if([aLine rangeOfString:aLabel].location != NSNotFound) return aLine;
	}
	return @"";
}


- (void) showDataSetForSet:(int)aSet segment:(int)index
{ 
	if(aSet>=0 && aSet < [segmentGroups count]){
		ORSegmentGroup* aGroup = [segmentGroups objectAtIndex:aSet];
		NSString* cardName = [aGroup segment:index objectForKey:@"kCardSlot"];
		NSString* chanName = [aGroup segment:index objectForKey:@"kChannel"];
		if(cardName && chanName && ![cardName hasPrefix:@"-"] && ![chanName hasPrefix:@"-"]){
			ORDataSet* aDataSet = nil;
			[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
			NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
			if([objs count]){
				NSArray* arrayOfHistos = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
				if([arrayOfHistos count]){
					id histoObj = [arrayOfHistos objectAtIndex:0];
				//	if([[aGroup adcClassName] isEqualToString:@"ORKatrinFLTModel"] || [[aGroup adcClassName] isEqualToString:@"ORIpeV4FLTModel"]){
						aDataSet = [histoObj objectForKeyArray:[NSMutableArray arrayWithObjects:@"FLT", @"Energy", @"Crate  0",
																[NSString stringWithFormat:@"Station %2d",[cardName intValue]], 
																[NSString stringWithFormat:@"Channel %2d",[chanName intValue]],
																nil]];
			//		}
					
					[aDataSet doDoubleClick:nil];
				}
			}
		}
	}
}

- (NSString*) dataSetNameGroup:(int)aGroup segment:(int)index
{
	ORSegmentGroup* theGroup = [segmentGroups objectAtIndex:aGroup];

	NSString* crateName = [theGroup segment:index objectForKey:@"kCrate"];
	NSString* cardName  = [theGroup segment:index objectForKey:@"kCardSlot"];
	NSString* chanName  = [theGroup segment:index objectForKey:@"kChannel"];
	
	return [NSString stringWithFormat:@"FLT,Energy,Crate %2d,Station %2d,Channel %2d",[crateName intValue],[cardName intValue],[chanName intValue]];
}

- (int) numberSegmentsInGroup:(int)aGroup
{
	if(aGroup == 0)		 return kNumFocalPlaneSegments;
	else if(aGroup == 1) return kNumVetoSegments;
	else return 0;
}


#pragma mark ¥¥¥Specific Dialog Lock Methods
- (NSString*) experimentMapLock
{
	return @"KatrinMapLock";
}
- (NSString*) vetoMapLock
{
	return @"VetoMapLock";
}
- (NSString*) experimentDetectorLock
{
	return @"KatrinDetectorLock";
}

- (NSString*) experimentDetailsLock	
{
	return @"KatrinDetailsLock";
}

- (void) setViewType:(int)aViewType
{
	[[[self undoManager] prepareWithInvocationTarget:self] setViewType:aViewType];
	viewType = aViewType;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelViewTypeChanged object:self userInfo:nil];
}

- (int) viewType
{
	return viewType;
}

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	//backward compatibility check
    if([segmentGroups count]>1){
		NSObject* firstSegmentGroup = [segmentGroups objectAtIndex:0];
		if(![firstSegmentGroup isKindOfClass:NSClassFromString(@"ORFPDSegmentGroup")]){
			ORFPDSegmentGroup* group = [[ORFPDSegmentGroup alloc] initWithName:@"Focal Plane" numSegments:kNumFocalPlaneSegments mapEntries:[self setupMapEntries:0]];
			[segmentGroups replaceObjectAtIndex:0 withObject:group];
			[group release];
		}
	}
    [self setSlowControlName:[decoder decodeObjectForKey:@"slowControlName"]];
    [self setViewType:[decoder decodeIntForKey:@"viewType"]];
	fltSNs		= [[decoder decodeObjectForKey:@"fltSNs"] retain];
	preAmpSNs	= [[decoder decodeObjectForKey:@"preAmpSNs"] retain];
	osbSNs		= [[decoder decodeObjectForKey:@"osbSNs"] retain];
	otherSNs	= [[decoder decodeObjectForKey:@"otherSNs"] retain];
	int i;
	for(i=0;i<2;i++) {
		[self setMaxValue:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"maxValue%d",i]]];
		[self setLowLimit:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"lowLimit%d",i]]];
		[self setHiLimit:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"hiLimit%d",i]]];
	}
	
	
	[self validateSNArrays];
	[[self undoManager] enableUndoRegistration];

    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
    [encoder encodeObject:slowControlName	forKey: @"slowControlName"];
    [encoder encodeInt:viewType				forKey: @"viewType"];
    [encoder encodeObject:fltSNs			forKey: @"fltSNs"];
    [encoder encodeObject:preAmpSNs			forKey: @"preAmpSNs"];
    [encoder encodeObject:osbSNs			forKey: @"osbSNs"];
    [encoder encodeObject:otherSNs			forKey: @"otherSNs"];
	int i;
	for(i=0;i<2;i++) {
		[encoder encodeFloat:lowLimit[i] forKey:[NSString stringWithFormat:@"lowLimit%d",i]];
		[encoder encodeFloat:hiLimit[i] forKey:[NSString stringWithFormat:@"hiLimit%d",i]];
		[encoder encodeFloat:maxValue[i] forKey:[NSString stringWithFormat:@"maxValue%d",i]];
	}}


#pragma mark ¥¥¥SN Access Methods
- (id) fltSN:(int)i objectForKey:(id)aKey
{
	if(i>=0 && i<8){
		return [[fltSNs objectAtIndex:i] objectForKey:aKey];
	}
	else return @"";
}

- (void) fltSN:(int)i setObject:(id)anObject forKey:(id)aKey
{
	if(i>=0 && i<8){
		id entry = [fltSNs objectAtIndex:i];
		id oldValue = [self fltSN:i objectForKey:aKey];
		if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] fltSN:i setObject:oldValue forKey:aKey];
		[entry setObject:anObject forKey:aKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelSNTablesChanged object:self userInfo:nil];
		
	}
}

- (id) preAmpSN:(int)i objectForKey:(id)aKey
{
	if(i>=0 && i<24){
		return [[preAmpSNs objectAtIndex:i] objectForKey:aKey];
	}
	else return @"";
}
- (void) preAmpSN:(int)i setObject:(id)anObject forKey:(id)aKey
{
	if(i>=0 && i<24){
		id entry = [preAmpSNs objectAtIndex:i];
		id oldValue = [self preAmpSN:i objectForKey:aKey];
		if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] preAmpSN:i setObject:oldValue forKey:aKey];
		[entry setObject:anObject forKey:aKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelSNTablesChanged object:self userInfo:nil];
	}
}

- (id) osbSN:(int)i objectForKey:(id)aKey
{
	if(i>=0 && i<4){
		return [[osbSNs objectAtIndex:i] objectForKey:aKey];
	}
	else return @"";
}
- (void) osbSN:(int)i setObject:(id)anObject forKey:(id)aKey
{
	if(i>=0 && i<4){
		id entry = [osbSNs objectAtIndex:i];
		id oldValue = [self osbSN:i objectForKey:aKey];
		if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] osbSN:i setObject:oldValue forKey:aKey];
		[entry setObject:anObject forKey:aKey];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelSNTablesChanged object:self userInfo:nil];
	}
}
- (id) otherSNForKey:(id)aKey
{
	return [otherSNs objectForKey:aKey];
}

- (void) setOtherSNObject:(id)anObject forKey:(id)aKey
{
	id oldValue = [self otherSNForKey:aKey];
	if(oldValue)[[[self undoManager] prepareWithInvocationTarget:self] setOtherSNObject:oldValue forKey:aKey];
	[otherSNs setObject:anObject forKey:aKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKatrinModelSNTablesChanged object:self userInfo:nil];
}


- (void) handleOldPrimaryMapFormats:(NSString*)aPath
{
	//the old format had the preamp s/n included.
	NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
	contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
	contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
    NSArray*  lines = [contents componentsSeparatedByString:@"\n"];
    for(id aLine in lines){
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        if([aLine length] && [aLine characterAtIndex:0] != '#'){
			NSArray* parts =  [aLine componentsSeparatedByString:@","];
			if([parts count] != 13) break;
			if(![aLine hasPrefix:@"--"]){
				int preAmpModule = [[parts objectAtIndex:6] intValue];
				NSString* preAmpSN = [parts objectAtIndex:8];
				if(preAmpModule < [preAmpSNs count]){
					id entry = [preAmpSNs objectAtIndex:preAmpModule];
					[entry setObject:preAmpSN forKey:@"kPreAmpSN"];
				}
			}
        }
    }	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSegmentGroupMapReadNotification object:self];
}

- (NSString*) validateHWMapPath:(NSString*)aPath
{
	if([aPath hasSuffix:@"_FltOrbSN"])	 return [aPath substringToIndex:[aPath length]-9];
	if([aPath hasSuffix:@"_PreampSN"])	 return [aPath substringToIndex:[aPath length]-9];
	if([aPath hasSuffix:@"_OsbSN"])		 return [aPath substringToIndex:[aPath length]-6];
	if([aPath hasSuffix:@"_SltWaferSN"]) return [aPath substringToIndex:[aPath length]-11];
	return aPath;
}

- (NSArray*) linesInFile:(NSString*)aPath
{
	NSString* contents = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
	contents = [[contents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
	contents = [[contents componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
    return [contents componentsSeparatedByString:@"\n"];
}

- (void) readAuxFiles:(NSString*)aPath 
{
	aPath = [aPath stringByDeletingPathExtension];
		
	NSFileManager* fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:FLTORBSNFILE(aPath)]){
		//read in the FLT/ORB Serial Numbers
		NSArray* lines  = [self linesInFile:FLTORBSNFILE(aPath)];
		for(id aLine in lines){
			if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
				NSArray* parts =  [aLine componentsSeparatedByString:@","];
				if([parts count]>=3){
					int index = [[parts objectAtIndex:0] intValue]-2;
					if(index<8){
						NSMutableDictionary* dict = [fltSNs objectAtIndex:index];
						[dict setObject:[parts objectAtIndex:0] forKey:@"kFltSlot"];
						[dict setObject:[parts objectAtIndex:1] forKey:@"kFltSN"];
						[dict setObject:[parts objectAtIndex:2] forKey:@"kORBSN"];
					}
				}
			}
		}
	}
	if([fm fileExistsAtPath:OSBSNFILE(aPath)]){
		//read in the OSB Serial Numbers
		NSArray* lines  = [self linesInFile:OSBSNFILE(aPath)];
		for(id aLine in lines){
			if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
				NSArray* parts =  [aLine componentsSeparatedByString:@","];
				if([parts count]>=2){
					int index = [[parts objectAtIndex:0] intValue];
					if(index<4){
						NSMutableDictionary* dict = [osbSNs objectAtIndex:index];
						[dict setObject:[parts objectAtIndex:0] forKey:@"kOSBSlot"];
						[dict setObject:[parts objectAtIndex:1] forKey:@"kOSBSN"];
					}
				}
			}
		}
	}
	if([fm fileExistsAtPath:PREAMPSNFILE(aPath)]){
		//read in the PreAmp Serial Numbers
		NSArray* lines  = [self linesInFile:PREAMPSNFILE(aPath)];
		for(id aLine in lines){
			if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
				NSArray* parts =  [aLine componentsSeparatedByString:@","];
				if([parts count]>=2){
					int index = [[parts objectAtIndex:0] intValue];
					if(index<24){
						NSMutableDictionary* dict = [preAmpSNs objectAtIndex:index];
						[dict setObject:[parts objectAtIndex:0] forKey:@"kPreAmpMod"];
						[dict setObject:[parts objectAtIndex:1] forKey:@"kPreAmpSN"];
					}
				}
			}
		}
	}
	if([fm fileExistsAtPath:SLTWAFERSNFILE(aPath)]){
		//read in the Slt and Wafer Serial Numbers
		NSArray* lines  = [self linesInFile:SLTWAFERSNFILE(aPath)];
		for(id aLine in lines){
			if([aLine length] && [aLine characterAtIndex:0] != '#'){ //skip comments
				NSArray* parts =  [aLine componentsSeparatedByString:@","];
				if([parts count]>=2){
					[otherSNs setObject:[parts objectAtIndex:0] forKey:@"kSltSN"];
					[otherSNs setObject:[parts objectAtIndex:1] forKey:@"kWaferSN"];
				}
			}
		}
	}
}
- (void) saveAuxFiles:(NSString*)aPath 
{
	NSLog(@"Saved FPD HW Map: %@\n",aPath);
	aPath = [aPath stringByDeletingPathExtension];
	NSFileManager* fm = [NSFileManager defaultManager];
	NSMutableString* contents = [NSMutableString string];
	//save the FLT/ORB Serial Numbers
	if([fm fileExistsAtPath: FLTORBSNFILE(aPath)])[fm removeItemAtPath:FLTORBSNFILE(aPath) error:nil];
	for(id item in fltSNs)[contents appendFormat:@"%@,%@,%@\n",[item objectForKey:@"kFltSlot"],[item objectForKey:@"kFltSN"],[item objectForKey:@"kORBSN"]];
	NSData* data = [contents dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:FLTORBSNFILE(aPath) contents:data attributes:nil];
	NSLog(@"Saved FLT/ORB SerialNumbers: %@\n",FLTORBSNFILE(aPath));
	
	//save the OSB Serial Numbers
	contents = [NSMutableString string];
	if([fm fileExistsAtPath: OSBSNFILE(aPath)])[fm removeItemAtPath:OSBSNFILE(aPath) error:nil];
	for(id item in osbSNs)[contents appendFormat:@"%@,%@\n",[item objectForKey:@"kOSBSlot"],[item objectForKey:@"kOSBSN"]];
	data = [contents dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:OSBSNFILE(aPath) contents:data attributes:nil];
	NSLog(@"Saved OSB SerialNumbers: %@\n",OSBSNFILE(aPath));
	
	//save the Preamp Serial Numbers
	contents = [NSMutableString string];
	if([fm fileExistsAtPath: PREAMPSNFILE(aPath)])[fm removeItemAtPath:PREAMPSNFILE(aPath) error:nil];
	for(id item in preAmpSNs)[contents appendFormat:@"%@,%@\n",[item objectForKey:@"kPreAmpMod"],[item objectForKey:@"kPreAmpSN"]];
	data = [contents dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:PREAMPSNFILE(aPath) contents:data attributes:nil];
	NSLog(@"Saved Preamp SerialNumbers: %@\n",PREAMPSNFILE(aPath));
	
	//save the Slt and Wafer Serial Numbers
	contents = [NSMutableString string];
	if([fm fileExistsAtPath: SLTWAFERSNFILE(aPath)])[fm removeItemAtPath:SLTWAFERSNFILE(aPath) error:nil];
	[contents appendFormat:@"%@,%@\n",[otherSNs objectForKey:@"kSltSN"],[otherSNs objectForKey:@"kWaferSN"]];
	data = [contents dataUsingEncoding:NSASCIIStringEncoding];
	[fm createFileAtPath:SLTWAFERSNFILE(aPath) contents:data attributes:nil];
	NSLog(@"Saved Slt/Wafer SerialNumbers: %@\n",SLTWAFERSNFILE(aPath));
	
}

#pragma mark ¥¥¥Bit Processing Protocol
- (void) processIsStarting
{
	//nothing to do in this case
}

- (void) processIsStopping
{
	//nothing to do in this case
}

//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{    
	//nothing to do in this case
}

- (void) endProcessCycle
{
	//nothing to do in this case
}

- (NSString*) identifier
{
	NSString* s;
 	@synchronized(self){
		s= [NSString stringWithFormat:@"Katrin,%lu",[self uniqueIdNumber]];
	}
	return s;
}

- (NSString*) processingTitle
{
	NSString* s;
 	@synchronized(self){
		s= [self identifier];
	}
	return s;
}

- (NSString*)adcName:(int)aChan
{
    switch (aChan){
        case 0: return @"FPD Rate"; 
        case 1: return @"Veto Rate"; 
        default: return @"";
    }
}

- (double) convertedValue:(int)aChan
{
	double theValue;
	@synchronized(self){
        switch (aChan){
            case 0: theValue =  [[self segmentGroup:0] rate];  break;
            case 1: theValue =  [[self segmentGroup:1] rate];  break;
			default:theValue = 0;                       break;
        }
	}
	return theValue;
}

- (double) maxValueForChan:(int)aChan
{
	double theValue;
	@synchronized(self){
		theValue = (double)[self maxValue:aChan]; 
	}
	return theValue;
}

- (double) minValueForChan:(int)aChan
{
	return 0;
}

- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)aChan
{
	@synchronized(self){
		*theLowLimit  =  [self lowLimit:aChan]; 
		*theHighLimit =  [self hiLimit:aChan]; 
	}		
}

- (BOOL) processValue:(int)channel
{
	BOOL r;
	@synchronized(self){
		r = YES;    //process bool doesn't have a real meaning for this object
	}
	return r;}

- (void) setProcessOutput:(int)channel value:(int)value
{
    //nothing to do. not used in adcs. really shouldn't be in the protocol
}

@end

@implementation KatrinModel (private)

- (NSString*) mapFileHeader:(int)tag
{
	if(tag==0)return @"Pixel,FLTSlot,FLTChan,PreampMod,PreampChan,OSBSlot,OSBChan";
	else if(tag==1)return @"Seg,FLTSlot,FLTChan";
	else return nil;
}


- (NSString*) auxParamsString:(NSArray*)auxArray keys:(NSArray*)keys
{
	NSString* result = [NSString string];
	
	for(id aKey in keys){
		result = [result stringByAppendingFormat:@"%@,",aKey];
	}
	result = [result substringToIndex:[result length]-1];
	result = [result stringByAppendingString:@"\n"];
	for(id anItem in auxArray){
		int n = [keys count];
		int i;
		for(i=0;i<n;i++){
			id aParam = [anItem objectForKey:[keys objectAtIndex:i]];
			if(aParam) result = [result stringByAppendingFormat:@"%@",aParam];
			else result = [result stringByAppendingString:@"--"];
			if(i<n-1)result = [result stringByAppendingString:@","];
		}
		result = [result stringByAppendingString:@"\n"];
	}
	return result;
}

- (NSString*) addOldFPDMapFormat:(NSMutableDictionary*)aDictionary
{
	//NSMutableString* result = [NSMutableString stringWithString:@"Pixel,FLT Card,FLT Ch,kname,Quad,Carousel,Mod. Addr.,Preamp,Preamp SN,OTB Card,OTB Ch,ORB Card,ORB Ch\n"];
	NSMutableString* result = [NSMutableString string];
	id segments = [[segmentGroups objectAtIndex:0] segments];
	for(id segment in segments){
		NSArray* parts = [[segment paramsAsString] componentsSeparatedByString:@","];
		if([parts count]>=7){
			[result appendFormat:@"%@,%@,%@,%@,%@,%d,%@,%@,%@,%@,%@,%@,%@\n",
			 [parts objectAtIndex:0], //pixel
			 [parts objectAtIndex:1], //FLT Card
			 [parts objectAtIndex:2], //FLT Chan
			 @"",					  //kname
			 [parts objectAtIndex:5], //Quad
			 [[parts objectAtIndex:3]intValue]+1, //Carousel
			 [parts objectAtIndex:3], //Module Address
			 [parts objectAtIndex:4], //preamp
			 @"",					  //preamp SN
			 [parts objectAtIndex:5], //OTB Card
			 [parts objectAtIndex:6], //OTB Chan
			 [parts objectAtIndex:1], //ORB Card
			 [parts objectAtIndex:2] //ORB Chan
			 ];
			
			//new format: Pixel,FLT Slot, FLT Chan, Preamp Mod, Preamp Chan, OSB Slot, OSB Chan
		}
	}
	if(result)return result;
	else return @"NONE";
}

- (NSString*) addOldVetoMapFormat:(NSMutableDictionary*)aDictionary
{
	NSMutableString* result = [NSMutableString string];
	id segments = [[segmentGroups objectAtIndex:1] segments];
	for(id segment in segments){
		NSArray* parts = [[segment paramsAsString] componentsSeparatedByString:@","];
		if([parts count]>=3){
			[result appendFormat:@"%@,%@,%@,%@\n",
				[parts objectAtIndex:0], //pixel
				[parts objectAtIndex:1], //FLT Card
				[parts objectAtIndex:2], //FLT Chan
				@"-"
			 ];			
		}
	}
	if(result)return result;
	else return @"NONE";
}

- (void) validateSNArrays
{
	if(!fltSNs){
		fltSNs = [[NSMutableArray array] retain];
		int i;
		for(i=0;i<8;i++){
			[fltSNs addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:i+2], @"kFltSlot",
							   @"-",						 @"kFltSN",
							   @"-",						 @"kORBSN", nil]];
		}
	}
	if(!preAmpSNs){
		preAmpSNs = [[NSMutableArray array] retain];
		int i;
		for(i=0;i<24;i++){
			[preAmpSNs addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt:i], @"kPreAmpMod",
								  @"-",					   @"kPreAmpSN", nil]];
		}
	}
	if(!osbSNs){
		osbSNs = [[NSMutableArray array] retain];
		int i;
		for(i=0;i<4;i++){
			[osbSNs addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							   [NSNumber numberWithInt:i], @"kOSBSlot",
							   @"-",						@"kOSBSN", nil]];
		}
	}
	if(!otherSNs){
		otherSNs = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
					 @"-",			@"kSltSN",
					 @"-",			@"kWaferSN", nil] retain];
	}
}

@end
