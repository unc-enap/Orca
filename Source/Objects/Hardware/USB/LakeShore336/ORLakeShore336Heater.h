//
//  ORLakeShore336Heater.h
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

@interface ORLakeShore336Heater : NSObject
{
    int             channel;
    NSString*       label;
    float           output;
    int             resistance;
    int             maxCurrent;
    float           maxUserCurrent;
    int             currentOrPower;
    double          lowLimit;
    double          highLimit;
    double          minValue;
    double          maxValue;
    ORTimeRate*		timeRate;
    time_t          timeMeasured;
    BOOL            userMaxCurrentEnabled;
    int             type;
    int             opMode;
    int             input;
    BOOL            powerUpEnable;
    
    //pid control values
    float           pValue;
    float           iValue;
    unsigned short  dValue;
}

- (NSUndoManager*) undoManager;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

- (NSUInteger)  numberPointsInTimeRate;
- (void) timeRateAtIndex:(int)i x:(double*)xValue y:(double*)yValue;
- (NSString*) heaterSetupString;
- (NSString*) pidSetupString;
- (NSString*) outputSetupString;

@property (copy,nonatomic)   NSString*      label;
@property (assign,nonatomic) int            channel;
@property (assign,nonatomic) float          output;
@property (assign,nonatomic) int            resistance;
@property (assign,nonatomic) int            maxCurrent;
@property (assign,nonatomic) float          maxUserCurrent;
@property (assign,nonatomic) double         lowLimit;
@property (assign,nonatomic) double         highLimit;
@property (assign,nonatomic) double         minValue;
@property (assign,nonatomic) double         maxValue;
@property (assign,nonatomic) int            currentOrPower;
@property (assign,nonatomic) BOOL           userMaxCurrentEnabled;
@property (assign,nonatomic) int            opMode;
@property (assign,nonatomic) int            input;
@property (assign,nonatomic) BOOL           powerUpEnable;
@property (assign,nonatomic) float          pValue;
@property (assign,nonatomic) float          iValue;
@property (assign,nonatomic) unsigned short dValue;

@property (retain)           ORTimeRate*    timeRate;
@property (assign)           time_t  timeMeasured;

@end

extern NSString* ORLakeShore336OutputChanged;
extern NSString* ORLakeShore336InputChanged;
