//  Orca
//  ORURLSession.m
//
//  Created by Tom Caldwell on March 27, 2020
//  Copyright (c) 2020 University of North Carolina. All rights reserved.
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

#import "ORURLSession.h"

@implementation ORURLSession

/*  The method below implements a deprecated NSURLConnection method using an NSURLSession.
    In general, the asynchronous NSURLSession methods should be used instead of this method.
    This is meant only for cases where switching to an asynchronous method would require
    a significant code rewrite.  Based on https://forums.developer.apple.com/thread/11519 */

+ (NSData*) sendSynchronousRequest:(NSURLRequest*)request
                 returningResponse:(NSURLResponse **)responsePtr
                             error:(NSError **)errorPtr
{
    dispatch_semaphore_t sem;
    __block NSData* result;
    result = nil;
    sem = dispatch_semaphore_create(0);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData* data,
                                                                                    NSURLResponse* response,
                                                                                    NSError* error){
        if(errorPtr    != NULL) *errorPtr    = error;
        if(responsePtr != NULL) *responsePtr = response;
        if(error == nil) result = [data retain];
        dispatch_semaphore_signal(sem);
    }] resume];
    
    /*  This really should not be necessary, but about 1 in a million times without this small delay
        the decrement below gives an EXC_BAD_INSTRUCTION exception due to the semaphore being unbalanced.
        The 1 us delay is overkill, but will leave for now unless it becomes a problem since Orca crashes
        if the exception is thrown. */
    [NSThread sleepForTimeInterval:1.0e-6];

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    dispatch_release(sem);

    return result;
}

@end
