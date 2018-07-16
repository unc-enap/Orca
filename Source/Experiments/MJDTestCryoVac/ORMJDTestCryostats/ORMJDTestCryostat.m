//
//  ORMJDTestCryostat.m
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
#import "ORMJDTestCryostat.h"
#import "ORMJDVacuumView.h"
#import "ORTPG256AModel.h"
#import "ORMJDPumpCartModel.h"
#import "ORLakeShore210Model.h"

@interface ORMJDTestCryostat (private)
- (void) _makeParts;
- (void) makePipes:(VacuumPipeStruct*)pipeList num:(int)numItems;
- (void) makeGateValves:(VacuumGVStruct*)pipeList num:(int)numItems;
- (void) makeStaticLabels:(VacuumStaticLabelStruct*)labelItems num:(int)numItems;
- (void) makeDynamicLabels:(VacuumDynamicLabelStruct*)labelItems num:(int)numItems;
- (void) colorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor;
- (void) recursizelyColorRegionsConnectedTo:(int)aRegion withColor:(NSColor*)aColor;
- (void) resetVisitationFlag;

- (double) valueForRegion:(int)aRegion;
- (ORVacuumDynamicLabel*) regionValueObj:(int)aRegion;
- (BOOL) valueValidForRegion:(int)aRegion;
- (BOOL) region:(int)aRegion valueHigherThan:(double)aValue;

- (ORTPG256AModel*)    findPressureGauge:(int)aSlot;
- (id) findObject:(NSString*)aClassName inSlot:(int)aSlot;

@end

NSString* ORMJDTestCryoConnectionChanged = @"ORMJDTestCryoConnectionChanged";

@implementation ORMJDTestCryostat

#pragma mark •••initialization

- (void) setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}
- (id) model { return self; }

- (BOOL) showGrid {return [delegate showGrid];}

- (void) dealloc
{
	[parts release];
	[partDictionary release];
	[valueDictionary release];
	[super dealloc];
}

- (void) pressureGaugeChanged:(NSNotification*)aNote
{
	ORTPG256AModel* pressureGauge = [aNote object];
	int chan = [[[aNote userInfo] objectForKey:@"Channel"]intValue];
	int componentTag = (int)[pressureGauge tag];
	ORVacuumDynamicLabel*  aLabel = [self regionValueObj:kRegionNegPump];
	if([aLabel channel ] == chan && [aLabel component] == componentTag){
		[aLabel setIsValid:[pressureGauge isValid]]; 
		[aLabel setValue:[pressureGauge pressure:[aLabel channel]]]; 
	}
}

- (void) temperatureGaugeChanged:(NSNotification*)aNote
{
    ORLakeShore210Model* tempGauge = [aNote object];
    int componentTag = (int)[tempGauge tag];
    int chan         = [[[aNote userInfo] objectForKey:@"Channel"]intValue];
    //get the right region/channel etc...
    //cryo 1,3,..     cryo 2,4,..
    //chan0->TempA  chan4->TempA
    //chan1->TempB  chan5->TempB
    //chan2->TempC  chan6->TempC
    //chan3->TempD  chan7->TempD
    
    int componentOffset[7]={0,0,1,1,2,2,3}; //by stc
    int channelOffset[7]  ={0,4,0,4,0,4,0}; //by stc
    
    int tagIndex = (int)[self tag];
    
    if(tagIndex<7 && chan<8){
        
        ORVacuumDynamicLabel*  aLabel = [self regionValueObj:kRegionTempA+chan%4];
    
        //each cryostat needs a different temp gauge component based on its cryostat #
        int labelChannel   = [aLabel channel]   + channelOffset[tagIndex];
        int labelComponent = [aLabel component] + componentOffset[tagIndex];
        
        if(labelComponent == componentTag){
            if(labelChannel == chan){
                [aLabel setIsValid:[tempGauge isValid]];
                [aLabel setValue:[tempGauge temp:chan]];
            }
        }
    }
}

#pragma mark ***Accessors
- (int) connectionStatus
{
	return connectionStatus;
}

- (void) setConnectionStatus:(int) aState
{
	connectionStatus = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDTestCryoConnectionChanged object:self];
}

- (NSUInteger) tag
{
	return tag;
}
- (void) setTag:(NSUInteger)aValue
{
	tag = aValue;
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

- (void) openDialogForComponent:(int)i
{
	/*
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj tag] == i){
			[anObj makeMainController];
			break;
		}
	}
	 */
}

- (NSString*) regionName:(int)i
{
	switch(i){
		default: return nil;
	}
}

- (void) makeParts
{
	[self _makeParts];
}

@end


@implementation ORMJDTestCryostat (private)
- (ORTPG256AModel*)     findPressureGauge:(int)aSlot   { return [self findObject:@"ORTPG256AModel" inSlot:aSlot];     }

- (id) findObject:(NSString*)aClassName inSlot:(int)aSlot
{
	for(OrcaObject* anObj in [delegate orcaObjects]){
		if([anObj isKindOfClass:NSClassFromString(aClassName)]){
			if([anObj tag] == aSlot)return anObj;
		}
	}
	return nil;
}



- (void) _makeParts
{
#define kNumVacPipes		6
	VacuumPipeStruct vacPipeList[kNumVacPipes] = {
		//region 0 pipes
		{ kVacBox,	  kRegionCryostat, 70,			   100,			130,				180 },
		{ kVacVPipe,  kRegionCryostat, 100,				50,			100,				100 }, 
		{ kVacHPipe,  kRegionCryostat, 100+kPipeRadius,				75,			135+kPipeRadius,	75 },
		
		//region 1 pipes
		{ kVacVPipe,  kRegionNegPump, 100,				0,			100,				50 }, 
		{ kVacHPipe,  kRegionNegPump, 100+kPipeRadius,	30,			120,				30}, 
		{ kVacHPipe,  kRegionNegPump, 120,				30,			140,				30 }, 

	};
	
#define kNumStaticLabelItems	1
	VacuumStaticLabelStruct staticLabelItems[kNumStaticLabelItems] = {
		{kVacStaticLabel, kRegionNegPump,			@"NEG\nPump",	135,  15,	195, 45},
	};	
	
#define kNumStatusItems	5
	VacuumDynamicLabelStruct dynamicLabelItems[kNumStatusItems] = {
		//type,	region, component, channel
        {kVacPressureItem, kRegionNegPump,	2, 3,  @"PKR G1",	135, 60,	195,   90}, //The component, channel are first ones. The actual values are offset using the stand number.
        {kVacTempItem,     kRegionTempA,    4, 0,  @"Temp A",	10,  130,	 60,  160}, //The component, channel are first ones. The actual component and channel will be computed by the object
        {kVacTempItem,     kRegionTempB,    4, 1,  @"Temp B",	10,   90,	 60,  120}, //The component, channel are first ones.
        {kVacTempItem,     kRegionTempC,    4, 2,  @"Temp C",	10,   50,	 60,   80}, //The component, channel are first ones.
        {kVacTempItem,     kRegionTempD,    4, 3,  @"Temp D",	10,   10,	 60,   40}, //The component, channel are first ones.

    
    };
		
#define kNumVacGVs			3
	VacuumGVStruct gvList[kNumVacGVs] = {
		{kVacHGateV, 0,	@"V1",			kManualOnlyShowChanging,	100, 5,		kRegionNegPump,		kRegionNegPump,			kControlNone},	//Manual N2 supply
		{kVacHGateV, 1,	@"V2",			kManualOnlyShowChanging,	100, 50,	kRegionNegPump,		kRegionCryostat,		kControlNone},	//Manual N2 supply
		{kVacVGateV, 2,	@"V3",			kManualOnlyShowChanging,	120, 30,	kRegionNegPump,		kRegionNegPump,			kControlNone},	//Manual N2 supply
	};
	
	[self makePipes:vacPipeList					num:kNumVacPipes];
	[self makeGateValves:gvList					num:kNumVacGVs];
	[self makeStaticLabels:staticLabelItems		num:kNumStaticLabelItems];
	[self makeDynamicLabels:dynamicLabelItems	num:kNumStatusItems];
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
        int component	= labelItems[i].component;
        if(labelItems[i].type == kVacPressureItem){
            int channel		= (int)(labelItems[i].channel + [self tag]);
            //the pressure gauge has six channels. Our pump stands start at the first pressure gauge, channel 3 and are offset from there
            if(channel>5){
                channel   = (int)([self tag]-3);
                component+=1;
            }
            NSRect theBounds = NSMakeRect(labelItems[i].x1,labelItems[i].y1,labelItems[i].x2-labelItems[i].x1,labelItems[i].y2-labelItems[i].y1);
            [[[ORVacuumValueLabel alloc] initWithDelegate:self regionTag:labelItems[i].regionTag component:component channel:channel label:labelItems[i].label bounds:theBounds] autorelease];
        }
        else if(labelItems[i].type == kVacTempItem){
            int channel		= labelItems[i].channel;
            NSRect theBounds = NSMakeRect(labelItems[i].x1,labelItems[i].y1,labelItems[i].x2-labelItems[i].x1,labelItems[i].y2-labelItems[i].y1);
            [[[ORTemperatureValueLabel alloc] initWithDelegate:self regionTag:labelItems[i].regionTag component:component channel:channel label:labelItems[i].label bounds:theBounds] autorelease];
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
    else if([aPart isKindOfClass:NSClassFromString(@"ORTemperatureValueLabel")]){
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

- (ORVacuumDynamicLabel*) regionValueObj:(int)aRegion
{
	return [valueDictionary objectForKey:[NSNumber numberWithInt:aRegion]];
}


- (BOOL) regionColor:(int)r1 sameAsRegion:(int)r2
{
	NSColor* c1	= [self colorOfRegion:r1];
	NSColor* c2	= [self colorOfRegion:r2];
	return [c1 isEqual:c2];
}
			 
@end
