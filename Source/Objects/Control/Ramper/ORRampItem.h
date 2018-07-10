//
//  ORRampItem.h
//  ORRampItem
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


#import <Cocoa/Cocoa.h>

@class ORWayPoint;
@class ORRampItemController;

@interface ORRampItem : NSObject <NSCopying>{
	id					owner;
	id					proxyObject;
	id					targetObject;
	id					parameterObject;
	NSString*			parameterName;
	NSString*			targetName;
	int					crateNumber;
	int					cardNumber;
	int					channelNumber;
	NSMutableArray*		wayPoints;
	float				rampTarget;					//in y-axis coords
	BOOL				targetSelected;
	ORWayPoint*			currentWayPoint;		//x in non-conveted time, y in y-axis coord frame
	id					controller;
	BOOL				running;
	float				startTime;
	int					dir;
	NSDate*				startDate;
    NSString*			objName;
	NSArray*			parameterList;
	int					numberChannels;
	float				oldMaxValue;
	NSInvocation*		invocationForSetter;
	NSInvocation*		invocationForGetter;
	NSInvocation*		invocationForInit;
    float				downRate;
    int					downRampPath;
	BOOL				visible;
	BOOL				globalEnabled;
	NSMutableDictionary* miscAttributes;
	BOOL				panic;
}

#pragma mark •••Initialization
- (id) initWithOwner:(id)anOwner;
- (id) copyWithZone:(NSZone *)zone;

- (void) placeCurrentValue;
- (NSUndoManager *)undoManager;
- (ORRampItemController*) makeController:(id)anOwner;

#pragma mark •••Accessors
- (id) owner;
- (void) setOwner:(id)anObj;
- (void) removeSelf;
- (int) direction;
- (BOOL) globalEnabled;
- (void) setGlobalEnabled:(BOOL)flag;
- (BOOL) visible;
- (void) setVisible:(BOOL)flag;
- (BOOL) targetSelected;
- (void) setTargetSelected:(BOOL)flag;
- (int) downRampPath;
- (void) setDownRampPath:(int)aDownRampPath;
- (float) downRate;
- (void) setDownRate:(float)aDownRate;
- (float) oldMaxValue;
- (float) maxValueForParameter;
- (int) maxNumberChannels;
- (void) setTargetObject:(id)aTarget;
- (id) targetObject;
- (void) setProxyObject:(id)aTarget;
- (id) proxyObject;
- (void) setParameterObject:(id)aTarget;
- (id) parameterObject;
- (NSArray*) parameterList;
- (void) setParameterList:(NSArray*)anArrayOfParameters;
- (float) rampTarget;
- (void) setRampTarget:(float)aValue;
- (NSMutableArray*) wayPoints;
- (void) setWayPoints:(NSMutableArray*)someWayPoints;
- (ORWayPoint*) wayPoint:(int)index;
- (NSUInteger) wayPointCount;
- (void) removeWayPoint:(id)aWayPoint;
- (ORWayPoint*) currentWayPoint;
- (BOOL) isRunning;
- (NSString*) parameterName;
- (void) setParameterName:(NSString*)aName;
- (NSString*) targetName;
- (void) setTargetName:(NSString*)aName;
- (int) crateNumber;
- (void) setCrateNumber:(int)num;
- (int) cardNumber;
- (void) setCardNumber:(int)num;
- (int) channelNumber;
- (void) setChannelNumber:(int)num;
- (void) checkTargetObject;

- (void) loadProxyObjects;
- (void) loadTargetObject;
- (void) loadParameterObject;
- (void) loadParams:(id)anObject;
- (void) startGlobalRamp;
- (void) stopGlobalRamp;
- (float) valueAtTime:(float)time;
- (float) timeAtValue:(float)value;
- (void) scaleToMaxTime:(float)aMaxTime;
- (void) rescaleToTarget;
- (void) rescaleToMax;
- (void) rescaleTo:(float)aMax scaleTarget:(BOOL)scaleTarget;
- (void) scaleFromOldMax;
- (void) prepareForScaleChange;
- (void) makeLinear;
- (void) makeLog;
- (NSMutableDictionary*) miscAttributesForKey:(NSString*)aKey;
- (void) setMiscAttributes:(NSMutableDictionary*)someAttributes forKey:(NSString*)aKey;
- (void) setXAxisIgnoreMouse:(BOOL)flag;
- (NSArray*) rampableParametersForTarget:(id)aTarget;

- (void) startRamper;
- (void) incTime;
- (void) stopRamper;
- (void) loadHardware;
- (void) turnOff;
- (NSString*) itemName;
- (void) panic;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end



extern NSString* ORRampItemDownRampPathChanged;
extern NSString* ORRampItemDownRateChanged;
extern NSString* ORRampItemForceUpdate;
extern NSString* ORRampItemParametersChanged;
extern NSString* ORRampItemRunningChanged;
extern NSString* ORRampItemInc;
extern NSString* ORRampItemVisibleChanged;
extern NSString* ORRampItemMiscAttributesChanged;
extern NSString* ORRampItemMiscAttributeKey;
extern NSString* ORRampItemTargetNameChanged;
extern NSString* ORRampItemChannelNumberChanged;
extern NSString* ORRampItemCardNumberChanged;
extern NSString* ORRampItemCrateNumberChanged;
extern NSString* ORRampItemParameterNameChanged;
extern NSString* ORRamperModelParametersChanged;
extern NSString* ORRampItemGlobalEnabledChanged;
extern NSString* ORRampItemRampTargetChanged;
extern NSString* ORRampItemCurrentValueChanged;
extern NSString* ORRampItemTargetChanged;


@interface ORWayPoint : NSObject {
	NSPoint xyPosition;
}
- (id) initWithPosition:(NSPoint)aPoint;
- (NSPoint) xyPosition;
- (void) setXyPosition:(NSPoint)aPoint;
@end

@interface NSObject (ORRampitem)
- (void) turnOff;
@end

extern NSString* ORWayPointChanged;


