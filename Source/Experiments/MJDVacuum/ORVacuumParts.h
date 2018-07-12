//
//  ORVacuumParts.h
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

@class ORAlarm;


typedef struct  {
	int type;
	int regionTag;
	float x1,y1,x2,y2;
}  VacuumPipeStruct;

typedef struct  {
	int type;
	int partTag;
	NSString* label;
	int controlType;
	float x1,y1;
	int r1,r2;
	int conPref;
}  VacuumGVStruct;

typedef struct  {
	int type;
	int regionTag;
	NSString* label;
	float x1,y1,x2,y2;
}  VacuumStaticLabelStruct;

typedef struct  {
	int type;
	int regionTag;
	int component;
	int channel;
	NSString* label;
	float x1,y1,x2,y2;
}  VacuumDynamicLabelStruct;

typedef struct  {
	int type;
	float x1,y1,x2,y2;
}  VacuumLineStruct;

typedef struct  {
    int type;
    int regionTag;
    int component;
    int channel;
    NSString* label;
    float x1,y1,x2,y2;
}  TempGroup;


#define kNA		 -1
#define kUpToAir -2

#define kVacCorner		0
#define kVacHPipe		1
#define kVacVPipe		2
#define kVacBox			3
#define kVacBigHPipe	4

#define kVacHGateV		5
#define kVacVGateV		6
#define kVacStaticLabel 7
#define kVacPressureItem 8
#define kVacLine		9
#define kGVControl		10
#define kVacStatusItem	11
#define kVacTempItem    12
#define kVacTempGroup   13

#define kGVImpossible				0
#define kGVOpen					    1
#define	kGVClosed					2	
#define kGVChanging					3

#define kGVNoCommandedState			0
#define kGVCommandOpen				1
#define kGVCommandClosed			2



#define PIPECOLOR [NSColor darkGrayColor]
#define kPipeDiameter				12
#define kPipeRadius					(kPipeDiameter/2.)
#define kPipeThickness				2
#define kGateValveWidth				4
#define kGateValveHousingWidth		(kGateValveWidth + (3*kPipeThickness))
//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumPart : NSObject
{
	id dataSource;
	int	regionTag;
	int partTag;
	BOOL visited;
}
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag regionTag:(int)aRegionTag;
- (void) normalize; 
- (void) draw;
@property (nonatomic,assign) id dataSource;
@property (nonatomic,assign) int regionTag;
@property (nonatomic,assign) int partTag;
@property (nonatomic,assign) BOOL visited;
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumPipe : ORVacuumPart
{
	NSPoint startPt;
	NSPoint endPt;
	NSColor* regionColor;
    NSString* rgbString;
}
@property (nonatomic,assign) NSPoint startPt;
@property (nonatomic,assign) NSPoint endPt;
@property (nonatomic,retain) NSColor* regionColor;
@property (nonatomic,copy)   NSString* rgbString;
- (id) initWithDelegate:(id)aDelegate regionTag:(int)aTag startPt:(NSPoint)aStartPt endPt:(NSPoint)anEndPt;
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumHPipe		: ORVacuumPipe  { } @end;
@interface ORVacuumVPipe		: ORVacuumPipe  { } @end;
@interface ORVacuumBigHPipe		: ORVacuumHPipe { } @end;

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumCPipe		: ORVacuumPipe
{ 	
	NSPoint location;
} 
@property (nonatomic,assign) NSPoint location;
- (id) initWithDelegate:(id)aDelegate regionTag:(int)aTag at:(NSPoint)aPoint;
@end

@interface ORVacuumBox		: ORVacuumPipe
{ 	
	NSRect bounds;
} 
@property (nonatomic,assign) NSRect bounds;
- (id) initWithDelegate:(id)aDelegate regionTag:(int)aTag bounds:(NSRect)aRect;
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumStaticLabel : ORVacuumPart
{
	NSString*	label;
	NSRect		bounds;
	NSGradient* gradient;
	NSColor*	controlColor;
}
- (id) initWithDelegate:(id)aDelegate regionTag:(int)aRegionTag label:(NSString*)label bounds:(NSRect)aRect;

@property (nonatomic,assign) NSRect bounds;
@property (nonatomic,retain) NSGradient* gradient;
@property (nonatomic,retain) NSColor* controlColor;
@property (nonatomic,copy) NSString* label;
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumDynamicLabel : ORVacuumStaticLabel
{
	BOOL isValid;
	int component;
	int channel;
    double value;
}
- (id) initWithDelegate:(id)aDelegate regionTag:(int)aRegionTag component:(int)aComponent channel:(int)aChannel label:(NSString*)label bounds:(NSRect)aRect;
- (NSString*) displayString;
- (BOOL) valueHigherThan:(double)aValue;
@property (nonatomic,assign) int channel;
@property (nonatomic,assign) int component;
@property (nonatomic,assign) BOOL isValid;
@property (nonatomic,assign) double value;
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumValueLabel : ORVacuumDynamicLabel
{
}
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumTempGroup : ORVacuumDynamicLabel
{
    double temp[8];
}
- (NSString*) displayTemp:(int)chan;
- (double) temp:(int)chan;
- (void)   setTemp:(int)chan value:(double)aValue;
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORTemperatureValueLabel : ORVacuumDynamicLabel
{
}
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumStatusLabel : ORVacuumDynamicLabel
{
	NSString* statusLabel;
	NSMutableDictionary* constraints;
}
- (NSDictionary*) constraints;
- (void) addConstraintName:(NSString*)aName reason:(NSString*)aReason;
- (void) removeConstraintName:(NSString*)aName;
@property (nonatomic,copy) NSString* statusLabel;
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
#define kControlAbove 1
#define kControlBelow 2
#define kControlRight 3
#define kControlLeft  4
#define kControlNone  5

#define kManualOnlyShowClosed	  0
#define kManualOnlyShowChanging	  1
#define k2BitReadBack			  2
#define k1BitReadBack			  3
#define kSpareValve				  4

@interface ORVacuumGateValve : ORVacuumPart
{
	NSPoint location;
	NSString* label;
	int controlType;
	int connectingRegion1;
	int connectingRegion2;
	int	controlPreference;
	ORAlarm* valveAlarm;
	BOOL logState;
	NSString* controlObj;
	int controlChannel;
	BOOL vetoed;
	int commandedState;
	int state;
	NSMutableDictionary* constraints;
}
@property (nonatomic,assign) int state;
@property (nonatomic,copy)   NSString* controlObj;
@property (nonatomic,assign) int controlChannel;
@property (nonatomic,copy)   NSString* label;
@property (nonatomic,assign) NSPoint   location;
@property (nonatomic,assign) int commandedState;
@property (nonatomic,assign) int connectingRegion1;
@property (nonatomic,assign) int controlType;
@property (nonatomic,assign) int connectingRegion2;
@property (nonatomic,assign) int controlPreference;
@property (nonatomic,assign) BOOL vetoed;
@property (nonatomic,retain) ORAlarm* valveAlarm;

- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag  label:(NSString*)label controlType:(int)aControlType at:(NSPoint)aPoint connectingRegion1:(int)aRegion1 connectingRegion2:(int)aRegion2;
- (void) checkState;
- (void) startStuckValveTimer;
- (void) cancelStuckValveTimer;
- (void) clearAlarmState;
- (void) timeout;
- (NSDictionary*) constraints;
- (void) addConstraintName:(NSString*)aName reason:(NSString*)aReason;
- (void) removeConstraintName:(NSString*)aName;
- (BOOL) isClosed;
- (BOOL) isOpen;
- (NSUInteger) constraintCount;
- (NSString*) stateName:(int)aValue;
@end

@interface ORVacuumVGateValve	: ORVacuumGateValve { } @end;
@interface ORVacuumHGateValve	: ORVacuumGateValve { } @end;

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORVacuumLine : ORVacuumPart
{
	NSPoint startPt;
	NSPoint endPt;	
}
- (id) initWithDelegate:(id)aDelegate startPt:(NSPoint)aStartPt endPt:(NSPoint)anEndPt;
@property (nonatomic,assign) NSPoint startPt;
@property (nonatomic,assign) NSPoint endPt;
@end

//----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------
@interface ORGateValveControl : ORVacuumPart
{
	NSPoint location;
}
@property (nonatomic,assign) NSPoint location;
- (id) initWithDelegate:(id)aDelegate partTag:(int)aTag at:(NSPoint)aPoint;
@end

extern NSString* ORVacuumPartChanged;
extern NSString* ORVacuumConstraintChanged;


@interface NSObject (VacuumParts)
- (BOOL) showGrid;
- (BOOL) disableConstraints;
- (void) addPart:(id)aPart;
- (void) colorRegions;
- (NSString*) auxStatusString:(int)aChannel;
@end

