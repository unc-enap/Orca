//  Orca
//  FlashCamUtils.m
//
//  Created by Tom Caldwell on Sep 24, 2021
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
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

#import "FlashCamUtils.h"

void mergeRunFlags(NSMutableArray* flags)
{
    // setup dictionaries for initial set of options
    NSMutableArray* opts = [NSMutableArray array];
    for(NSUInteger i=0; i<[flags count]; i++){
        NSString* f = [flags objectAtIndex:i];
        if([f length] < 2) continue;
        if([f characterAtIndex:0] != '-') continue;
        if(![[NSCharacterSet letterCharacterSet] characterIsMember:[f characterAtIndex:1]]) continue;
        NSArray* a = [[flags objectAtIndex:i+1] componentsSeparatedByString:@","];
        if([a count] != 3) continue;
        if([[a objectAtIndex:1] intValue] < 0 || [[a objectAtIndex:2] intValue] < 0) continue;
        NSMutableDictionary* d = [NSMutableDictionary dictionary];
        [d setObject:f forKey:@"flag"];
        [d setObject:[NSNumber numberWithUnsignedInteger:i] forKey:@"index"];
        [d setObject:[NSNumber numberWithBool:NO] forKey:@"merge"];
        [d setObject:[[a objectAtIndex:0] lowercaseString] forKey:@"value"];
        [d setObject:[NSNumber numberWithUnsignedInt:[[a objectAtIndex:1] unsignedIntValue]] forKey:@"start"];
        [d setObject:[NSNumber numberWithUnsignedInt:[[a objectAtIndex:2] unsignedIntValue] +
                      [[d objectForKey:@"start"] unsignedIntValue] - 1] forKey:@"end"];
        [opts addObject:d];
    }
    // loop through set of options until none can be merged
    NSMutableArray* removed = [NSMutableArray array];
    BOOL merged = YES;
    while(merged){
        merged = NO;
        for(NSUInteger i=0; i<[opts count]; i++){
            NSMutableDictionary* d0 = [opts objectAtIndex:i];
            for(NSUInteger j=0; j<[opts count]; j++){
                NSMutableDictionary* d1 = [opts objectAtIndex:j];
                if(d0 == d1) continue;
                if(![[d0 objectForKey:@"flag"] isEqualToString:[d1 objectForKey:@"flag"]])  continue;
                NSCharacterSet* chars = [NSCharacterSet characterSetWithCharactersInString:@"abcdef"];
                NSString* value = [d0 objectForKey:@"value"];
                if([value rangeOfCharacterFromSet:chars].location == NSNotFound &&
                   [[d1 objectForKey:@"value"] rangeOfCharacterFromSet:chars].location == NSNotFound){
                    if([value doubleValue] != [[d1 objectForKey:@"value"] doubleValue]) continue;
                }
                else{
                    NSScanner* scan0 = [NSScanner scannerWithString:value];
                    NSScanner* scan1 = [NSScanner scannerWithString:[d1 objectForKey:@"value"]];
                    unsigned int val0 = 0, val1 = 0;
                    [scan0 scanHexInt:&val0];
                    [scan1 scanHexInt:&val1];
                    if(val0 != val1) continue;
                }
                unsigned int s0 = [[d0 objectForKey:@"start"] unsignedIntValue];
                unsigned int e0 = [[d0 objectForKey:@"end"]   unsignedIntValue];
                unsigned int s1 = [[d1 objectForKey:@"start"] unsignedIntValue];
                unsigned int e1 = [[d1 objectForKey:@"end"]   unsignedIntValue];
                if((s0 > 0 && e1 < s0-1) || s1 > e0+1) continue;
                [d0 setObject:[NSNumber numberWithUnsignedInt:MIN(s0, s1)] forKey:@"start"];
                [d0 setObject:[NSNumber numberWithUnsignedInt:MAX(e0, e1)] forKey:@"end"];
                [d0 setObject:[NSNumber numberWithBool:YES]                forKey:@"merge"];
                [removed addObject:[NSNumber numberWithUnsignedInteger:[[d1 objectForKey:@"index"] unsignedIntegerValue]]];
                [removed addObject:[NSNumber numberWithUnsignedInteger:[[d1 objectForKey:@"index"] unsignedIntegerValue]+1]];
                [opts removeObjectAtIndex:j];
                j --;
                if(j < i) i --;
                merged = YES;
            }
        }
    }
    // adjust the option string for items that were merged into
    for(NSMutableDictionary* d in opts){
        if(![[d objectForKey:@"merge"] boolValue]) continue;
        NSUInteger index = [[d objectForKey:@"index"] unsignedIntegerValue] + 1;
        NSString* value = [[[flags objectAtIndex:index] componentsSeparatedByString:@","] objectAtIndex:0];
        unsigned int start = [[d objectForKey:@"start"] unsignedIntValue];
        unsigned int count = [[d objectForKey:@"end"] unsignedIntValue] - start + 1;
        [flags setObject:[NSString stringWithFormat:@"%@,%d,%d", value, start, count] atIndexedSubscript:index];
    }
    // finally, remove the items that were merged with others
    for(NSUInteger i=0; i<[removed count]; i++){
        NSNumber* n = [removed objectAtIndex:i];
        [flags removeObjectAtIndex:[n unsignedIntegerValue]];
        for(NSUInteger j=i+1; j<[removed count]; j++){
            NSNumber* m = [removed objectAtIndex:j];
            if([n unsignedIntegerValue] < [m unsignedIntegerValue])
                [removed setObject:[NSNumber numberWithUnsignedInteger:[m unsignedIntegerValue]-1]
                atIndexedSubscript:j];
        }
    }
}
