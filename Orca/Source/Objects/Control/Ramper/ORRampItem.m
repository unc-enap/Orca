//
//  ORRampItem.m
//  test
//
//  Created by Mark Howe on 3/29/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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


#import "ORRampItem.h"
#import "ORRamperModel.h"
#import "ORRamperController.h"
#import "ORReadOutList.h"
#import "ORHWWizard.h"
#import "ORHWWizParam.h"
#import "ORRampItemController.h"
#import "ORCard.h"
#import "ORAxis.h"

NSString* ORRampItemDownRampPathChanged		= @"ORRampItemDownRampPathChanged";
NSString* ORRampItemDownRateChanged			= @"ORRampItemDownRateChanged";
NSString* ORRampItemParametersChanged		= @"ORRampItemParametersChanged";
NSString* ORRampItemRunningChanged			= @"ORRampItemRunningChanged";
NSString* ORRampItemInc						= @"ORRampItemInc";
NSString* ORRampItemChannelChanged			= @"ORRampItemChannelChanged";
NSString* ORRampItemForceUpdate				= @"ORRampItemForceUpdate";
NSString* ORRampItemVisibleChanged			= @"ORRampItemVisibleChanged";
NSString* ORRampItemMiscAttributesChanged	= @"ORMiscRampItemAttributesChanged";
NSString* ORRampItemMiscAttributeKey		= @"ORMiscRampItemAttributeKey";
NSString* ORRampItemTargetNameChanged		= @"ORRampItemTargetNameChanged";
NSString* ORRampItemParameterNameChanged	= @"ORRampItemParameterNameChanged";
NSString* ORRampItemCrateNumberChanged		= @"ORRampItemCrateNumberChanged";
NSString* ORRampItemCardNumberChanged		= @"ORRampItemCardNumberChanged";
NSString* ORRampItemChannelNumberChanged	= @"ORRampItemChannelNumberChanged";
NSString* ORRamperModelParametersChanged	= @"ORRamperModelParametersChanged";
NSString* ORRampItemGlobalEnabledChanged	= @"ORRampItemGlobalEnabledChanged";
NSString* ORRampItemRampTargetChanged		= @"ORRampItemRampTargetChanged";
NSString* ORRampItemCurrentValueChanged		= @"ORRampItemCurrentValueChanged";
NSString* ORRampItemTargetChanged			= @"ORRampItemTargetChanged";

#define kPanicRate 200

@implementation ORRampItem

#pragma mark •••Initialization
- (id) initWithOwner:(id)anOwner;
{
	self = [super init];
	owner = anOwner;
	[self setWayPoints:[NSMutableArray array]];
	
	int i;
	for(i=0;i<5;i++){
		ORWayPoint* p = [[ORWayPoint alloc] initWithPosition:NSMakePoint(i*50,i*50)];
		[wayPoints addObject:p];
		[p release];
	}
	
	currentWayPoint = [[ORWayPoint alloc] initWithPosition:NSMakePoint(0,0)];
	[self loadProxyObjects];
	[self placeCurrentValue];
	
	return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    id obj = [[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]] retain];
	[obj setOwner:owner];
	[obj setChannelNumber:channelNumber+1];
	[obj loadProxyObjects];
	[obj placeCurrentValue];
	return obj;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[wayPoints release];
	[currentWayPoint release];
	[miscAttributes release];
	[targetName release];
	[parameterName release];
	[parameterList release];
	[super dealloc];
}

- (ORRampItemController*) makeController:(id)anOwner
{
	ORRampItemController* theController =  [[ORRampItemController alloc] initWithNib:[anOwner rampItemNibFileName]];
	[theController setOwner:anOwner];
	[theController setModel:self];
	return [theController autorelease];
}


#pragma mark •••Accessors
- (id) owner
{
	return owner;
}

- (void) setOwner:(id)anObj
{
	owner = anObj;
}

- (void) removeSelf
{
	[owner removeRampItem:self];
}

- (BOOL) globalEnabled
{
	return globalEnabled;
}

- (void) setGlobalEnabled:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGlobalEnabled:globalEnabled];
	globalEnabled = flag;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemGlobalEnabledChanged object:self];
}

- (BOOL) visible
{
	return visible;
}

- (void) setVisible:(BOOL)flag
{
	visible = flag;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemVisibleChanged object:self];
}

- (BOOL) targetSelected
{
	return targetSelected;
}

- (void) setTargetSelected:(BOOL)flag
{
	targetSelected = flag;
}

- (int) direction
{
	return dir;
}

- (int) downRampPath
{
    return downRampPath;
}

- (void) setDownRampPath:(int)aDownRampPath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDownRampPath:downRampPath];
    
    downRampPath = aDownRampPath;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemDownRampPathChanged object:self];
}

- (float) downRate
{
    return downRate;
}

- (void) setDownRate:(float)aDownRate
{
	if(aDownRate<=0)aDownRate = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setDownRate:downRate];
    
    downRate = aDownRate;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemDownRateChanged object:self];
}

- (NSUndoManager*) undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

- (void) checkTargetObject
{
	[self loadTargetObject];
	[self loadParameterObject];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemForceUpdate object:self];
}


- (BOOL) isRunning
{
	return running;
}

- (void) setTargetObject:(id)aTarget
{
	//don't retain.....
	targetObject = aTarget;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemTargetChanged object:self];
}

- (id) targetObject
{
	return targetObject;
}


- (void) setProxyObject:(id)aTarget
{
	//the proxy is any object of the target class.. can't be used for parameter access
	//don't retain.....
	proxyObject = aTarget;
}

- (id) proxyObject
{
	return proxyObject;
}

- (void) setParameterObject:(id)aParameter
{
	//don't retain.....
	parameterObject = aParameter;
}

- (id) parameterObject
{
	return parameterObject;
}


- (float) maxValueForParameter
{
	return [parameterObject upperLimit];
}

- (int) maxNumberChannels
{
	if(targetObject)return [targetObject numberOfChannels];
	else if(proxyObject)return [proxyObject numberOfChannels];
	else return 99;
}


- (float) rampTarget
{
	return rampTarget;
}

- (void) setRampTarget:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRampTarget:rampTarget];
	rampTarget = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemForceUpdate object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemRampTargetChanged object:self];
}

- (NSMutableArray*) wayPoints
{
	return wayPoints;
}

- (void) setWayPoints:(NSMutableArray*)someWayPoints
{
	[someWayPoints retain];
	[wayPoints release];
	wayPoints = someWayPoints;
}

- (ORWayPoint*) wayPoint:(int)index
{
	return [wayPoints objectAtIndex:index];
}
- (NSUInteger) wayPointCount
{
	return [wayPoints count];
}

- (void) removeWayPoint:(id)aWayPoint
{
	[wayPoints removeObject:aWayPoint];
}
- (ORWayPoint*) currentWayPoint
{
	return currentWayPoint;
}

- (NSString*) targetName
{
	return targetName;
}
- (void) setTargetName:(NSString*)aName
{
	[[[self undoManager] prepareWithInvocationTarget:self] setTargetName:targetName];
	
	[targetName autorelease];
	targetName = [aName copy];
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRampItemTargetNameChanged
	 object:self];
}

- (NSString*) parameterName
{
	return parameterName;
}
- (void) setParameterName:(NSString*)aName
{
	[[[self undoManager] prepareWithInvocationTarget:self] setParameterName:parameterName];
	
	[parameterName autorelease];
	parameterName = [aName copy];
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRampItemParameterNameChanged
	 object:self];
}

- (int) crateNumber
{
	return crateNumber;
}

- (void) setCrateNumber:(int)num
{
	[[[self undoManager] prepareWithInvocationTarget:self] setCrateNumber:crateNumber];
	
	crateNumber = num;
	
	[self checkTargetObject];
	[self placeCurrentValue];
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRampItemCrateNumberChanged
	 object:self];
}

- (int) cardNumber
{
	return cardNumber;
}

- (void) setCardNumber:(int)num
{
	[[[self undoManager] prepareWithInvocationTarget:self] setCardNumber:cardNumber];
	
	cardNumber = num;
    
	[self checkTargetObject];
	[self placeCurrentValue];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRampItemCardNumberChanged
	 object:self];
	
}

- (int) channelNumber
{
	return channelNumber;
}

- (void) setChannelNumber:(int)num
{
	[[[self undoManager] prepareWithInvocationTarget:self] setChannelNumber:channelNumber];
	
	if(num<0)num = 0;
	if(num > [self maxNumberChannels])num = [self maxNumberChannels];
	channelNumber = num;
    
	[self placeCurrentValue];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRampItemChannelNumberChanged
	 object:self];
}

- (NSArray*) parameterList
{
	return parameterList;
}

- (void) setParameterList:(NSArray*)anArrayOfParameters
{
	[anArrayOfParameters retain];
	[parameterList release];
	parameterList = anArrayOfParameters;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemParametersChanged object:self];
}

- (void) loadProxyObjects
{
	if(!targetName){
		NSArray* wizObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsConformingTo:@protocol(ORHWWizard)];
		OrcaObject* obj;
		NSEnumerator* objEnumy = [wizObjects objectEnumerator];
		while(obj = [objEnumy nextObject]){
			NSArray* parameters = [self rampableParametersForTarget:obj];
			if([parameters count]){
				[self setTargetName:[obj className]];
				[self loadParams:obj];
				[self setParameterName:[[parameterList objectAtIndex:0] name]];
				break;
			}
		}
	}
	
	
	NSArray* objects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(targetName)];
	if([objects count]){
		[self loadParams:[objects lastObject]];
		[self setProxyObject:[objects lastObject]];
	}
	[self loadParameterObject];
	
}

- (void) loadTargetObject
{
	NSArray* objects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(targetName)];
	id obj;
	BOOL found = NO;
	NSEnumerator* e = [objects objectEnumerator];
	while(obj = [e nextObject]){
		if([obj respondsToSelector:@selector(crateNumber)] && [obj crateNumber] == crateNumber){
			if([obj respondsToSelector:@selector(slot)] && [obj slot] == cardNumber){
				found = YES;
				[self setTargetObject:obj];
			}
		}
	}
	if(!found)	[self setTargetObject:nil];
}

- (void) loadParameterObject
{
	NSEnumerator* e = [parameterList objectEnumerator];
	ORHWWizParam* p;
	BOOL found = NO;
	while(p = [e nextObject]){
		if([[p name] isEqualToString: parameterName]){
			[self setParameterName:[p name]];
			[self setParameterObject:p];
			found = YES;
		}
	}
	if(!found)	[self setParameterObject:nil];
}

- (void) loadParams:(id)anObj
{
	if([anObj respondsToSelector:@selector(wizardParameters)]){
		NSArray* allParams = [anObj wizardParameters];
		NSMutableArray* revelantParameters = [NSMutableArray array];
		NSEnumerator* e = [allParams objectEnumerator];
		ORHWWizParam* p;
		while(p = [e nextObject]){
			if([p canBeRamped]){
				[revelantParameters addObject:p];
			}
		}
		if([revelantParameters count])[self setParameterList:revelantParameters];
		else [self setParameterList:nil];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRamperModelParametersChanged object:self];
	
}

- (NSArray*) rampableParametersForTarget:(id)aTarget
{
	NSMutableArray* rampableParameters = nil;
	if([aTarget respondsToSelector:@selector(wizardParameters)]){
		NSArray* allParameters = [aTarget wizardParameters]; 
		rampableParameters = [NSMutableArray array]; 
		ORHWWizParam* p;
		NSEnumerator* e = [allParameters objectEnumerator];
		while(p = [e nextObject]){
			if([p canBeRamped]){
				if(!rampableParameters) rampableParameters = [NSMutableArray array]; 
				[rampableParameters addObject:p];
			}
		}
	}
	return rampableParameters;
}

- (NSMutableDictionary*) miscAttributesForKey:(NSString*)aKey
{
	return [miscAttributes objectForKey:aKey];
}

- (void) setMiscAttributes:(NSMutableDictionary*)someAttributes forKey:(NSString*)aKey
{
	if(!aKey || !someAttributes)return;
	
	if(!miscAttributes)  miscAttributes = [[NSMutableDictionary alloc] init];
	
	NSMutableDictionary* oldAttrib = [miscAttributes objectForKey:aKey];
	if(oldAttrib){
		[[[self undoManager] prepareWithInvocationTarget:self] setMiscAttributes:[[oldAttrib copy] autorelease] forKey:aKey];
	}
	[miscAttributes setObject:someAttributes forKey:aKey];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemMiscAttributesChanged 
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:aKey forKey:ORRampItemMiscAttributeKey]];    
}
- (void) setXAxisIgnoreMouse:(BOOL)flag
{
	[[self undoManager] disableUndoRegistration];
	NSMutableDictionary* attrib = [self miscAttributesForKey:@"xAxis"];
    [attrib setObject:[NSNumber numberWithBool:flag] forKey:ORAxisIgnoreMouse];
	[self setMiscAttributes:attrib forKey:@"xAxis"];
	[[self undoManager] enableUndoRegistration];
}

- (void) placeCurrentValue
{
	
	if(!targetObject)[self loadTargetObject];
	if(!parameterObject)[self loadParameterObject];
	
	if(!parameterObject || !targetObject) return;
	
	int n = [wayPoints count];
	int i;
	
	SEL targetGetter = [parameterObject getMethodSelector];
	
	NSInvocation* invGet = [NSInvocation invocationWithMethodSignature:[targetObject methodSignatureForSelector:targetGetter]];
	[invGet setSelector:targetGetter];
	[invGet setTarget:targetObject];
	[invGet setArgument:0 to:[NSNumber numberWithInt:channelNumber]];
	[invGet invoke];
	float theValue = [[invGet returnValue] floatValue];
	
	if((running && dir<0 && downRampPath==0) || panic){
		[currentWayPoint setXyPosition:NSMakePoint([self timeAtValue:theValue],theValue)];
	}
	else {
		[currentWayPoint setXyPosition: NSMakePoint([[wayPoints objectAtIndex:n-1] xyPosition].x,theValue)];
		float yc = [currentWayPoint xyPosition].y;
		for(i=1;i<n;i++){
			ORWayPoint* aWayPoint1 = [wayPoints objectAtIndex:i-1];
			ORWayPoint* aWayPoint2 = [wayPoints objectAtIndex:i];
			float x1 = [aWayPoint1 xyPosition].x;
			float y1 = [aWayPoint1 xyPosition].y;
			float x2 = [aWayPoint2 xyPosition].x;
			float y2 = [aWayPoint2 xyPosition].y;
			if(yc>=y1 && yc<y2){
				if((x2-x1) == 0){
					[currentWayPoint setXyPosition:NSMakePoint(x2,yc)];
				}
				else {
					float slope		= (y2-y1)/(x2-x1);
					float intercept = (x2*y1 - x1*y2)/(x2-x1);
					if(slope!=0){
						float xc = (yc - intercept)/slope;
						[currentWayPoint setXyPosition:NSMakePoint(xc,yc)];
					}
					else {
						[currentWayPoint setXyPosition:NSMakePoint(x2,yc)];
					}
				}
				break;
			}
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemCurrentValueChanged object:self];
}

- (void) scaleToMaxTime:(float)aMaxTime
{
	int n = [wayPoints count];
	int i;
	ORWayPoint* aWayPoint = [wayPoints objectAtIndex:n-1];
	float scaleFactor = aMaxTime/[aWayPoint xyPosition].x;
	
	for(i=0;i<n;i++){
		aWayPoint = [wayPoints objectAtIndex:i];
		float oldTime = [aWayPoint xyPosition].x;
		float oldY = [aWayPoint xyPosition].y;
		[aWayPoint setXyPosition:NSMakePoint(oldTime * scaleFactor,oldY)];
	}
	[self placeCurrentValue];
}

- (void) rescaleToMax
{
	if(proxyObject){
		[self rescaleTo:[self maxValueForParameter] scaleTarget:YES];
	}
}

- (void) rescaleToTarget
{
	if(rampTarget>0){
		[self rescaleTo:rampTarget scaleTarget:NO];
	}
}

- (void) rescaleTo:(float)aMax scaleTarget:(BOOL)scaleTarget
{
	int n = [wayPoints count];
	int i;
	ORWayPoint* aWayPoint = [wayPoints objectAtIndex:n-1];
	float scaleFactor = aMax / [aWayPoint xyPosition].y;
	
	for(i=0;i<n;i++){
		aWayPoint  = [wayPoints objectAtIndex:i];
		float oldY = [aWayPoint xyPosition].y;
		float oldX = [aWayPoint xyPosition].x;
		[aWayPoint setXyPosition:NSMakePoint(oldX,oldY * scaleFactor)];
	}
	if(scaleTarget)[self setRampTarget:rampTarget*scaleFactor];
	
	[self placeCurrentValue];	
}

- (void) scaleFromOldMax
{
	int n = [wayPoints count];
	int i;
	ORWayPoint* aWayPoint;
	float scaleFactor = [self maxValueForParameter]/[self oldMaxValue];
	
	for(i=0;i<n;i++){
		aWayPoint  = [wayPoints objectAtIndex:i];
		float oldY = [aWayPoint xyPosition].y;
		float oldX = [aWayPoint xyPosition].x;
		[aWayPoint setXyPosition:NSMakePoint(oldX,oldY * scaleFactor)];
	}
	[self setRampTarget:rampTarget*scaleFactor];
	[self placeCurrentValue];	
}

- (float) oldMaxValue
{
	if(oldMaxValue == 0)oldMaxValue = [self maxValueForParameter];
	return oldMaxValue;
}

- (void) prepareForScaleChange
{
	oldMaxValue = [self maxValueForParameter];
}

- (void) stopGlobalRamp
{
	if(globalEnabled && running)[self stopRamper];
}

- (void) startGlobalRamp
{
	if(globalEnabled && !running)[self startRamper];
}

- (void) startGlobalPanic
{
	if(globalEnabled){
		[self panic];
	}
}

- (void) panic
{
	if([self isRunning])[self stopRamper];
	panic = YES;
	dir = -1;
	[self startRamper];
}

- (void) startRamper
{
	if([self isRunning])return;
	
	if(!targetObject)[self loadTargetObject];
	if(!parameterObject)[self loadParameterObject];
	
	if(!parameterObject || !targetObject) return;
	
	running = YES;
	if(panic || rampTarget < [currentWayPoint xyPosition].y)dir = -1;
	else dir = 1;
	[self placeCurrentValue];
	startTime = [currentWayPoint xyPosition].x;
	startDate = [[NSDate date] retain];
	//cache the target, the selectors that we need....
	
	SEL targetIniter = [parameterObject initMethodSelector];
	if(!targetIniter && [targetObject respondsToSelector:@selector(wizardParameters)]){
		NSArray* allParams = [targetObject wizardParameters];
		int n = [allParams count];
		int i;
		for(i=0;i<n;i++){
			ORHWWizParam* aParam = [allParams objectAtIndex:i];
			if([[aParam name] isEqualToString:@"Init"]){
				targetIniter = [aParam setMethodSelector];
				break;
			}
		}
	}
	if(targetIniter){
		invocationForInit = [[NSInvocation invocationWithMethodSignature:[targetObject methodSignatureForSelector:targetIniter]] retain];
		[invocationForInit setSelector:targetIniter];
		[invocationForInit setTarget:targetObject];		
	}
	
	
	SEL targetSetter = [parameterObject setMethodSelector];
	invocationForSetter = [[NSInvocation invocationWithMethodSignature:[targetObject methodSignatureForSelector:targetSetter]] retain];
	[invocationForSetter setSelector:targetSetter];
	[invocationForSetter setTarget:targetObject];
	
	SEL targetGetter = [parameterObject getMethodSelector];
	invocationForGetter = [[NSInvocation invocationWithMethodSignature:[targetObject methodSignatureForSelector:targetGetter]] retain];
	[invocationForGetter setSelector:targetGetter];
	[invocationForGetter setTarget:targetObject];
		
	[owner startRamping:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemRunningChanged object:self];
}

- (void) incTime
{
	if(!parameterObject || !targetObject){
		[self stopRamper];
		return;
	}
	NSTimeInterval dt = dir * [[NSDate date] timeIntervalSinceDate:startDate];
	float t = startTime + dt;
	float maxTime = [[wayPoints objectAtIndex:[wayPoints count]-1] xyPosition].x;
	float newValue = [self valueAtTime:t];
	BOOL done = NO;
	if(panic){
		if(t<=0){
			newValue = 0;
			t = [self timeAtValue:newValue];
			done = YES;
		}
		else if(newValue <= 0 ){
			newValue = 0;
			t = [self timeAtValue:newValue];
			done = YES;
		}
	}
	else {
		if(dir > 0 ){
			if(t>=maxTime){
				t = maxTime-.01;
				newValue = [self valueAtTime:t-.01];
				t = [self timeAtValue:newValue];
				done = YES;
			}
			else if(newValue >= rampTarget ){
				newValue = rampTarget;
				t = [self timeAtValue:newValue];
				done = YES;
			}
		}
		else if(dir < 0){
			if(t<=0){
				newValue = rampTarget;
				t = [self timeAtValue:newValue];
				done = YES;
			}
			else if(newValue <= rampTarget ){
				newValue = rampTarget;
				t = [self timeAtValue:newValue];
				done = YES;
			}
		}
	}
	[currentWayPoint setXyPosition:NSMakePoint(t,newValue)];
	
	[invocationForSetter setArgument:0 to:[NSNumber numberWithInt:channelNumber]];
	[invocationForSetter setArgument:1 to:[NSNumber numberWithFloat:newValue]];
	[invocationForSetter invoke];
	
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemInc object:self];
	if(done)[self stopRamper];
	else 	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemCurrentValueChanged object:self];
	
}

- (void) loadHardware
{
	if(invocationForInit){
		//load to hardware
		@try {
			[invocationForInit invoke];
		}
		@catch(NSException* localException) {
			[self stopRamper];
			ORRunAlertPanel([localException name], @"%@\n\nRamp Stopped for %@", @"OK", nil, nil,
								localException,[self itemName]);
		}
	}
}
- (void) turnOff
{
	if([targetObject respondsToSelector:@selector(turnOff)]){
		//load to turnOff the hardware
		@try {
			[targetObject turnOff];
		}
		@catch(NSException* localException) {
			ORRunAlertPanel([localException name], @"%@\n\nUnable to turn off %@", @"OK", nil, nil,
							localException,[self itemName]);
		}
	}
	
}

- (void) stopRamper
{
	if(running){
		[startDate release];
		startDate = nil;
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		
		[owner stopRamping:self turnOff:panic == YES];
		
		running = NO;
		panic = NO;
		
		[self placeCurrentValue];

		[invocationForGetter release];
		invocationForGetter = nil;
		
		[invocationForSetter release];
		invocationForSetter = nil;
		
		[invocationForInit release];
		invocationForInit = nil;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemRunningChanged object:self];
	}
}

- (NSString*) itemName
{
	NSString* ident = [NSString stringWithFormat:@"%@",targetName];
	if( (targetObject && [targetObject isKindOfClass:NSClassFromString(@"ORCard")]) || 
	   (proxyObject && [proxyObject isKindOfClass:NSClassFromString(@"ORCard")])){
		ident = [ident stringByAppendingFormat:@",%d,%d,%d",crateNumber,cardNumber,channelNumber];
	}
	else ident = [ident stringByAppendingFormat:@",%d",crateNumber];
	
	return ident;
}

- (float) valueAtTime:(float)time
{
	float newValue = 0;
	if(panic){
		newValue = time*[self maxValueForParameter]/100.;
	}
	else if(running && dir<0 && downRampPath == 0){
		newValue = time*downRate;
	}
	else {
		int n = [wayPoints count];
		int i;
		for(i=1;i<n;i++){
			ORWayPoint* aWayPoint1 = [wayPoints objectAtIndex:i-1];
			ORWayPoint* aWayPoint2 = [wayPoints objectAtIndex:i];
			float x1 = [aWayPoint1 xyPosition].x;
			float y1 = [aWayPoint1 xyPosition].y;
			float x2 = [aWayPoint2 xyPosition].x;
			float y2 = [aWayPoint2 xyPosition].y;
			if(time>=x1 && time<x2){
				if((x2-x1) == 0){
					newValue = y2;
				}
				else {
					float slope		= (y2-y1)/(x2-x1);
					float intercept = (x2*y1 - x1*y2)/(x2-x1);
					newValue = slope*time + intercept;
				}
				break;
			}
		}
	}
	return newValue;
}

- (float) timeAtValue:(float)value
{
	float newTime = 0.0;
	if(panic){
		newTime = value/([self maxValueForParameter]/100.);
	}
	else if(running && dir<0 && downRampPath == 0){
		newTime = value/downRate;
	}
	else {
		int n = [wayPoints count];
		int i;
		for(i=1;i<n;i++){
			ORWayPoint* aWayPoint1 = [wayPoints objectAtIndex:i-1];
			ORWayPoint* aWayPoint2 = [wayPoints objectAtIndex:i];
			float x1 = [aWayPoint1 xyPosition].x;
			float y1 = [aWayPoint1 xyPosition].y;
			float x2 = [aWayPoint2 xyPosition].x;
			float y2 = [aWayPoint2 xyPosition].y;
			if(value>=y1 && value<y2){
				if(x2-x1 != 0){
					float slope		= (y2-y1)/(x2-x1);
					float intercept = (x2*y1 - x1*y2)/(x2-x1);
					newTime = (value-intercept)/slope;
				}
				else newTime = y2;
				break;
			}
		}
	}
	return newTime;
}

- (void) makeLinear
{
	int n = [wayPoints count];
	if(n<=2)return;
	
	int i;
	ORWayPoint* aWayPoint0 = [wayPoints objectAtIndex:0];
	ORWayPoint* aWayPointn = [wayPoints objectAtIndex:n-1];
	float x1 = [aWayPoint0 xyPosition].x;
	float y1 = [aWayPoint0 xyPosition].y;
	float x2 = [aWayPointn xyPosition].x;
	float y2 = [aWayPointn xyPosition].y;
	float deltaX = (x2-x1)/(float)(n-1);
	float startX = x1;
	if(x2-x1 != 0){
		float slope		= (y2-y1)/(x2-x1);
		float intercept = (x2*y1 - x1*y2)/(x2-x1);
		
		for(i=1;i<n-1;i++){
			ORWayPoint* aWayPoint1 = [wayPoints objectAtIndex:i];
			float x = startX + (deltaX * i);
			float y = slope*x + intercept;
			
			[aWayPoint1 setXyPosition:NSMakePoint(x,y)];
		}
	}	
	[self placeCurrentValue];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemForceUpdate object:self];
}

- (void) makeLog
{
	int n = [wayPoints count];
	if(n<=2)return;
	
	int i;
	ORWayPoint* aWayPoint0 = [wayPoints objectAtIndex:0];
	ORWayPoint* aWayPointn = [wayPoints objectAtIndex:n-1];
	float x1 = [aWayPoint0 xyPosition].x;
	float y1 = [aWayPoint0 xyPosition].y;
	float x2 = [aWayPointn xyPosition].x;
	float y2 = [aWayPointn xyPosition].y;
	float deltaY = (y2-y1)/2;
	float e = n-2;
	float deltaX = (x2-x1)/pow(2.,e);
	float startX = x1;	
	float startY = y1;
	float x = startX + deltaX;
	for(i=1;i<n-1;i++){
		ORWayPoint* aWayPoint1 = [wayPoints objectAtIndex:i];
		float y = startY + deltaY;
		startY += deltaY;
		[aWayPoint1 setXyPosition:NSMakePoint(x,y)];
		deltaY = deltaY/2.;
		e--;
		x = startX + (x2-x1)/pow(2.,e);
	}	
	[self placeCurrentValue];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRampItemForceUpdate object:self];
	
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];
	//owner = [decoder decodeObjectForKey:@"owner"];
	
    [self setDownRampPath:[decoder decodeIntForKey:@"downRampPath"]];
    [self setDownRate:[decoder decodeFloatForKey:@"downRate"]];
	[self setWayPoints:[decoder decodeObjectForKey:@"waypoints"]];
    [self setTargetName:[decoder decodeObjectForKey:@"targetName"]];
    [self setParameterName:[decoder decodeObjectForKey:@"parameterName"]];
	[self loadProxyObjects];
	
    [self setCrateNumber:[decoder decodeIntForKey:@"crateNumber"]];
    [self setCardNumber:[decoder decodeIntForKey:@"cardNumber"]];
    [self setChannelNumber:[decoder decodeIntForKey:@"channelNumber"]];
    [self setRampTarget:[decoder decodeFloatForKey:@"rampTarget"]];
    [self setVisible:[decoder decodeBoolForKey:@"visible"]];
    [self setGlobalEnabled:[decoder decodeBoolForKey:@"globalEnabled"]];
    miscAttributes = [[decoder decodeObjectForKey:@"miscAttributes"] retain];
	
    [[self undoManager] enableUndoRegistration];
	
	if(!wayPoints){
		[self setWayPoints:[NSMutableArray array]];
		
		int i;
		for(i=0;i<5;i++){
			ORWayPoint* p = [[ORWayPoint alloc] initWithPosition:NSMakePoint(i*50,i*50)];
			[wayPoints addObject:p];
			[p release];
		}
	}
	
	currentWayPoint = [[ORWayPoint alloc] initWithPosition:NSMakePoint(0,0)];
	[self placeCurrentValue];
	
	//[self setRampTarget:0];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    //[encoder encodeObject:owner forKey:@"owner"];
    [encoder encodeInt:downRampPath forKey:@"downRampPath"];
    [encoder encodeFloat:downRate forKey:@"downRate"];
    [encoder encodeObject:targetName forKey:@"targetName"];
    [encoder encodeObject:parameterName forKey:@"parameterName"];
    [encoder encodeInt:crateNumber forKey:@"crateNumber"];
    [encoder encodeInt:cardNumber forKey:@"cardNumber"];
    [encoder encodeInt:channelNumber forKey:@"channelNumber"];
    [encoder encodeFloat:rampTarget forKey:@"rampTarget"];
    [encoder encodeObject:wayPoints forKey:@"waypoints"];
    [encoder encodeBool:visible forKey:@"visible"];
    [encoder encodeBool:globalEnabled forKey:@"globalEnabled"];
	[encoder encodeObject:miscAttributes forKey:@"miscAttributes"];
	
	[self loadProxyObjects];
	
}

@end

@implementation ORWayPoint

NSString* ORWayPointChanged = @"ORWayPointChanged";

- (id) initWithPosition:(NSPoint)aPoint
{
	self=[super init];
	[self setXyPosition:aPoint];
	return self;
}

- (NSPoint) xyPosition
{
	return xyPosition;
}

- (void) setXyPosition:(NSPoint)aPoint
{
	xyPosition = aPoint;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
	
	xyPosition.x = [decoder decodeFloatForKey:@"positionX"];
	xyPosition.y = [decoder decodeFloatForKey:@"positionY"];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	
    [encoder encodeFloat:xyPosition.x forKey:@"positionX"];
    [encoder encodeFloat:xyPosition.y forKey:@"positionY"];
}

@end
