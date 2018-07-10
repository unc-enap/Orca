//
//  OHexFormatter.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 16 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#import "OHexFormatter.h"

@implementation OHexFormatter

-(NSString*) stringForObjectValue:(id)obj
{
    return [NSString stringWithFormat:@"0x%lX", (unsigned long)[obj integerValue]];
}

-(BOOL) getObjectValue:(id *)obj forString:(NSString*)string errorDescription:(NSString **)error
{
    char s[255];
	[string getCString:s maxLength:255 encoding:NSASCIIStringEncoding];	// NO return if conversion not possible due to encoding errors or too small of a buffer. The buffer should include room for maxBufferCount bytes plus the NULL termination character, which this method adds. (So pass in one less than the size of the buffer.)
    *obj = [NSNumber numberWithUnsignedLong:strtoul(s,0,16)];
    return YES;
}

@end
