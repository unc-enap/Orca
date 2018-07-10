//
//  ORHWWizParam.h
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




typedef enum  {
    kAction_Set,
    kAction_Inc,
    kAction_Dec,
    kAction_Scale,
    kAction_Restore,
    kAction_Restore_All,
    kNumActions      //must be last
}eAction;

typedef enum  {
    kAction_Set_Mask		 = 1<<0,
    kAction_Inc_Mask		 = 1<<1,
    kAction_Dec_Mask		 = 1<<2,
    kAction_Scale_Mask		 = 1<<3,
    kAction_Restore_Mask	 = 1<<4,
    kAction_Restore_All_Mask = 1<<5
}eActionMask;

@interface ORHWWizParam : NSObject {
    SEL       selector;
    NSString* name;
    NSString* units;
    NSString* format;
    float     upperLimit;
    float     lowerLimit;
    float     stepSize;
    BOOL      useValue;
    BOOL      oncePerCard;
    SEL setMethodSelector;
    SEL getMethodSelector;
    NSFormatter* formatter;
    BOOL enabledWhileRunning;
    BOOL useFixedChannel;
    int  fixedChannel;
    unsigned short actionMask;
	BOOL canBeRamped;
    SEL initMethodSelector; //if a special init selector is used. Otherwise a selector named 'init' will be used as default.
}

+(id) boolParamWithName:(NSString*)name setter:(SEL)setter getter:(SEL)getter;

- (BOOL) canBeRamped;
- (void) setCanBeRamped:(BOOL)flag;
- (NSString*) name;
- (void) setName:(NSString*)aName;
- (NSString*) units;
- (void) setUnits:(NSString*)anUnits;
- (NSString*) format;
- (void) setFormat:(NSString*)aFormat;
- (SEL) selector;
- (void) setSelector:(SEL)aSelector;
- (float) upperLimit;
- (void) setUpperLimit:(float)anUpperLimit;
- (float) lowerLimit;
- (void) setLowerLimit:(float)aLowerLimit;
- (float) stepSize;
- (void) setStepSize:(float)aStepSize;
- (BOOL)useValue;
- (void)setUseValue:(BOOL)flag;
- (BOOL)oncePerCard;
- (void)setOncePerCard:(BOOL)flag;
- (void) setFormat:(NSString*)aFormat upperLimit:(float)anUpperLimit lowerLimit:(float)aLowerLimit stepSize:(float)step units:(NSString*)units;
- (SEL)setMethodSelector;
- (void)setSetMethodSelector:(SEL)anInitMethodSelector;
- (SEL)initMethodSelector;
- (void)setInitMethodSelector:(SEL)anInitMethodSelector;
- (BOOL) enabledWhileRunning;
- (void) setEnabledWhileRunning:(BOOL)state;
- (unsigned short)actionMask;
- (void)setActionMask:(unsigned short)anActionMask;
- (void) setUseFixedChannel:(int)aChannel;
- (BOOL) useFixedChannel;
- (int) fixedChannel;

- (SEL)getMethodSelector;
- (void)setGetMethodSelector:(SEL)aGetMethodSelector;
- (NSFormatter *)formatter;
- (void)setFormatter:(NSFormatter *)aFormatter;
- (void) setSetMethod:(SEL)aSetMethodSelector getMethod:(SEL)aGetMethodSelector;

@end
