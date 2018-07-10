//
//  SourceMask.m
//  Orca
//
//  Created by Mark Howe on 4/22/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "SourceMask.h"

@implementation SourceMask

// Predefined global list of categories
+ (NSArray *)allSourceMasks
{
    static NSArray *sourceMasks;
    if (!sourceMasks){
		sourceMasks = [[NSArray alloc] initWithObjects:
			[SourceMask sourceMaskWithTitle:@"ROTATING" andValue:0],
            [SourceMask sourceMaskWithTitle:@"LASER" andValue:1],
            [SourceMask sourceMaskWithTitle:@"SONO" andValue:2],
            [SourceMask sourceMaskWithTitle:@"N16" andValue:3],
            [SourceMask sourceMaskWithTitle:@"N17" andValue:4], 
            [SourceMask sourceMaskWithTitle:@"NAI" andValue:5], 
            [SourceMask sourceMaskWithTitle:@"LI8" andValue:6], 
            [SourceMask sourceMaskWithTitle:@"PT" andValue:7], 
            [SourceMask sourceMaskWithTitle:@"CF_HI" andValue:8], 
            [SourceMask sourceMaskWithTitle:@"CF_LO" andValue:9], 
            [SourceMask sourceMaskWithTitle:@"TH" andValue:10], 
            [SourceMask sourceMaskWithTitle:@"P_LI7" andValue:11], 
            [SourceMask sourceMaskWithTitle:@"WATER SAMPLER" andValue:12], 
            [SourceMask sourceMaskWithTitle:@"PROP COUNTER" andValue:13], 
            [SourceMask sourceMaskWithTitle:@"SINGLE NCD" andValue:14], 
            [SourceMask sourceMaskWithTitle:@"SELF CALIB" andValue:15], 
            [SourceMask sourceMaskWithTitle:@"Spare1" andValue:16], 
            [SourceMask sourceMaskWithTitle:@"Low Cerenkov" andValue:17], 
            [SourceMask sourceMaskWithTitle:@"RADON" andValue:18], 
            [SourceMask sourceMaskWithTitle:@"Spare4" andValue:19], 
            [SourceMask sourceMaskWithTitle:@"Spare5" andValue:20], 
            [SourceMask sourceMaskWithTitle:@"AmBe" andValue:21], 
            [SourceMask sourceMaskWithTitle:@"Spare7" andValue:22], 
            nil];
    }
    return sourceMasks;
}

// Retrieve sourceMasks with given value from 'allSourceMasks'
// (see NSCoding methods).
+ (SourceMask *)sourceMaskForValue:(unsigned long)theValue
{
	NSEnumerator *sourceMaskEnumerator = [[SourceMask allSourceMasks] objectEnumerator];
	SourceMask *sourceMask;
	while (sourceMask = [sourceMaskEnumerator nextObject]){
		if (theValue == [sourceMask value]){
			return sourceMask;			
		}
	}
	return nil;
}


// Convenience constructor
+ (id)sourceMaskWithTitle:(NSString *)aTitle andValue:(unsigned long)aValue
{
    SourceMask* newSourceMask = [[[self alloc] init] autorelease];
    [newSourceMask setTitle:aTitle];
    [newSourceMask setValue:aValue];
    
    return newSourceMask;
}

- (void)dealloc
{
    [self setTitle:nil];   
    [super dealloc];
}
/*
 NSCoding methods
 To encode, simply save 'value'; on decode, replace self with
 the existing instance from 'allSourceMasks' with the same value
 */
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInt: value forKey:@"value"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	unsigned long theValue = 0;
    theValue = [decoder decodeIntForKey:@"value"];
	[self autorelease];
	// returning "static" object from init method -- ensure retain count maintained
	return [[SourceMask sourceMaskForValue:theValue] retain];
}


// Accessors
- (NSString *)title
{
    return title;
}

- (void)setTitle:(NSString *)aTitle
{
    if (title != aTitle){
		[title release];
		title = [aTitle copy];
    }
    return;
}

- (unsigned long)value
{
    return value;
}
- (void)setValue:(unsigned long)aValue
{
    value = aValue;
}




@end