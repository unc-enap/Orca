//
//  ORPxiIOCard.m
//  Orca
//
//  Created by Mark Howe on Thurs Aug 26 2010
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark ¥¥¥Imported Files
#import "ORPxiIOCard.h"

#pragma mark ¥¥¥Notification Strings
NSString* ORPxiIOCardBaseAddressChanged			= @"ORPxiIOCardBaseAddressChanged";
NSString* ORPxiIOCardExceptionCountChanged 		= @"ORPxiIOCardExceptionCountChanged";

@implementation ORPxiIOCard

#pragma mark ¥¥¥Accessors
- (void) setBaseAddress:(unsigned long) address
{
	[[[self undoManager] prepareWithInvocationTarget:self] setBaseAddress:[self baseAddress]];
    baseAddress = address;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORPxiIOCardBaseAddressChanged
					   object:self]; 
}

- (unsigned long) baseAddress
{
    return baseAddress;
}

- (NSRange)	memoryFootprint
{
	//subclasses should overide to provide an accurate memory range
	return NSMakeRange(baseAddress,1*sizeof(long));
}

- (BOOL) memoryConflictsWith:(NSRange)aRange
{
	return NSIntersectionRange(aRange,[self memoryFootprint]).length != 0;
}

- (id)	adapter
{
	id anAdapter = [guardian adapter];
	if(anAdapter)return anAdapter;
	else [NSException raise:@"No adapter" format:@"You must place a Pxi adaptor card into the crate."];
	return nil;
}

- (unsigned long)   exceptionCount
{
    return exceptionCount;
}

- (void)clearExceptionCount
{
    exceptionCount = 0;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORPxiIOCardExceptionCountChanged
					   object:self]; 
    
}

- (void)incExceptionCount
{
    ++exceptionCount;
    
	[[NSNotificationCenter defaultCenter]
         postNotificationName:ORPxiIOCardExceptionCountChanged
					   object:self]; 
}


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	[self setBaseAddress:[decoder decodeInt32ForKey:@"baseAddress"]];
	[[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInt32:baseAddress forKey:@"baseAddress"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithLong:baseAddress] forKey:@"baseAddress"];
    return objDictionary;
}



@end
