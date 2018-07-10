//
//  ORTimedTextField.m
//  Orca
//
//  Created by Mark Howe on Mon Mar 15 2004.
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


#import "ORTimedTextField.h"

@interface ORTimedTextField (private)
- (void) clearField;
- (void) startTimeOut;
@end

@implementation ORTimedTextField

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];   
    [super dealloc];
}

- (void)setStringValue:(NSString *)aString
{
    if(!aString){
        aString=@"";
    }
    [super setStringValue:aString];
    [self startTimeOut];
}

- (void)setIntValue:(int) aValue
{
    [super setIntValue:aValue];
    [self startTimeOut];
}

- (void)setDoubleValue:(double) aValue
{
    [super setDoubleValue:aValue];
    [self startTimeOut];
}

- (void)setObjectValue:(id) aValue
{
    [super setObjectValue:aValue];
    [self startTimeOut];
}

- (NSTimeInterval)timeOut 
{
    return timeOut;
}

- (void)setTimeOut:(NSTimeInterval)aTimeOut 
{
    timeOut = aTimeOut;
}
@end

@implementation ORTimedTextField (private)
- (void) clearField
{
    [self setStringValue:@""];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearField) object:nil];
}

- (void) startTimeOut
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearField) object:nil];
    if(timeOut<=0)timeOut = 5;
    [self performSelector:@selector(clearField) withObject:nil afterDelay:timeOut];
}
@end
