//
//  ORHWWizParam.m
//  Orca
//
//  Created by Mark Howe on Wed Jan 28 2004.
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


#import "ORHWWizParam.h"

@implementation ORHWWizParam
+(id) boolParamWithName:(NSString*)aName setter:(SEL)setter getter:(SEL)getter
{
    ORHWWizParam* p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:aName];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:setter getMethod:getter];
    [p setActionMask:kAction_Set_Mask | kAction_Restore_Mask | kAction_Restore_All_Mask];
    return p;
}

- (id) init
{
    self = [super init];
    useValue = YES;
	canBeRamped = NO;
    enabledWhileRunning = YES;
    return self;
}

- (void) dealloc
{
    [name release];
    [units release];
    [format release];
    [formatter release];
    [super dealloc];
}

- (BOOL) canBeRamped
{
	return canBeRamped;
}

- (void) setCanBeRamped:(BOOL)flag
{
	canBeRamped = flag;
}

- (NSString*) name
{
    return name; 
}

- (void) setName:(NSString*)aName
{
    [name autorelease];
    name = [aName copy];
}

- (NSString*) units
{
    return units; 
}

- (void) setUnits:(NSString*)anUnits
{
    [units autorelease];
    units = [anUnits copy];
}

- (NSString*) format
{
    return format; 
}

- (void) setFormat:(NSString*)aFormat
{
    [format autorelease];
    format = [aFormat copy];
}
- (BOOL)useValue {

    return useValue;
}

- (void)setUseValue:(BOOL)flag {
    useValue = flag;
}
- (BOOL)oncePerCard {
    
    return oncePerCard;
}

- (void)setOncePerCard:(BOOL)flag {
    oncePerCard = flag;
}

- (SEL) selector
{

    return selector;
}

- (void) setSelector:(SEL)aSelector
{
    selector = aSelector;
}

- (float) upperLimit
{

    return upperLimit;
}

- (void) setUpperLimit:(float)anUpperLimit
{
    upperLimit = anUpperLimit;
}

- (float) lowerLimit
{

    return lowerLimit;
}

- (void) setLowerLimit:(float)aLowerLimit
{
    lowerLimit = aLowerLimit;
}


- (float) stepSize
{

    return stepSize;
}


- (void) setStepSize:(float)aStepSize
{
    stepSize = aStepSize;
}

- (void) setFormat:(NSString*)aFormat upperLimit:(float)anUpperLimit lowerLimit:(float)aLowerLimit stepSize:(float)step units:(NSString*)unitString
{
    [self setFormat:aFormat];
    [self setUpperLimit:anUpperLimit];
    [self setLowerLimit:aLowerLimit];
    [self setStepSize:step];
    [self setUnits:unitString];
}

- (NSFormatter *)formatter {
    return formatter; 
}

- (void)setFormatter:(NSFormatter *)aFormatter {
    [aFormatter retain];
    [formatter release];
    formatter = aFormatter;
}


- (SEL)setMethodSelector
{
    return setMethodSelector; 
}

- (void)setSetMethodSelector:(SEL)aSetMethodSelector
{
    setMethodSelector = aSetMethodSelector;
}

- (SEL)getMethodSelector
{
    return getMethodSelector; 
}

- (void)setGetMethodSelector:(SEL)aGetMethodSelector
{
    getMethodSelector = aGetMethodSelector;
}

- (void) setSetMethod:(SEL)aSetMethodSelector getMethod:(SEL)aGetMethodSelector
{
    [self setSetMethodSelector:aSetMethodSelector];
    [self setGetMethodSelector:aGetMethodSelector];
}

- (SEL)initMethodSelector
{
	return initMethodSelector;
}
- (void)setInitMethodSelector:(SEL)anInitMethodSelector
{
	initMethodSelector = anInitMethodSelector;
}

- (BOOL) enabledWhileRunning
{
    return enabledWhileRunning;
}

- (void) setEnabledWhileRunning:(BOOL)state
{
    enabledWhileRunning = state;
}

- (unsigned short)actionMask 
{
    return actionMask;
}

- (void)setActionMask:(unsigned short)anActionMask 
{
    actionMask = anActionMask;
}

- (void) setUseFixedChannel:(int)aChannel
{
    useFixedChannel = YES;
    fixedChannel = aChannel;
}

- (BOOL) useFixedChannel
{
    return useFixedChannel;
}
- (int) fixedChannel
{
    return fixedChannel;
}
@end
