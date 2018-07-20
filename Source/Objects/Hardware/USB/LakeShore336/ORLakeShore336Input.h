//
//  ORLakeShore336Input.h
//  Orca
//
//  Created by Mark Howe on Mon, May 6, 2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
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

@class ORTimeRate;

@interface ORLakeShore336Input : NSObject
{
    int             channel;
    NSString*       label;
    float           temperature;
    BOOL            autoRange;
    int             range;
    BOOL            compensation;
    int             units;
    float           setPoint;
    double          lowLimit;
    double          highLimit;
    double          minValue;
    double          maxValue;
    ORTimeRate*		timeRate;
    time_t          timeMeasured;
    int             sensorType;
    NSArray*        rangeStrings;
}

- (NSUndoManager*) undoManager;
- (NSUInteger) numberPointsInTimeRate;
- (void) timeRateAtIndex:(int)i x:(double*)xValue y:(double*)yValue;
- (BOOL) sensorEnabled;
- (NSString*) inputSetupString;
- (NSString*) setPointString;

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@property (copy,nonatomic) NSString*      label;
@property (assign,nonatomic) int            channel;
@property (assign,nonatomic) float          temperature;
@property (assign,nonatomic) BOOL           autoRange;
@property (assign,nonatomic) int            range;
@property (assign,nonatomic) BOOL           compensation;
@property (assign,nonatomic) int            units;
@property (assign,nonatomic) double         lowLimit;
@property (assign,nonatomic) double         highLimit;
@property (assign,nonatomic) double         minValue;
@property (assign,nonatomic) double         maxValue;
@property (retain)           ORTimeRate*    timeRate;
@property (assign)           time_t  timeMeasured;
@property (assign,nonatomic) float          setPoint;
@property (assign,nonatomic) int            sensorType;
@property (retain)           NSArray*       rangeStrings;

@end

extern NSString* ORLakeShore336InputTemperatureChanged;
