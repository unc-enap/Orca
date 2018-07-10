//-------------------------------------------------------------------------
//  MemoryWatcher.m
//
//  Created by Mark Howe on Friday 05/13/2005.
//  Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files

#import "MemoryWatcher.h"
#import "ORTimeRate.h"
#import "NSString+Extensions.h"
#import <mach/host_info.h>
#import <mach/mach_host.h>
#import <mach/task_info.h>
#import <mach/task.h>

@interface MemoryWatcher (private)
- (void) processResult;
@end

NSString* MemoryWatcherUpTimeChanged         = @"MemoryWatcherUpTimeChanged";
NSString* MemoryWatcherChangedNotification   = @"MemoryWatcherChangedNotification";
NSString* MemoryWatcherTaskIntervalNotification = @"MemoryWatcherTaskIntervalNotification";

enum {
    kCPU,
    kRSize
};

@implementation MemoryWatcher

#pragma mark ***Initialization
- (id) init
{
    self = [super init];
    [self setTaskInterval:3*60];
    [self setLaunchTime:[NSDate date]];
    [self launchTask];
    return self;
}

- (void) dealloc
{
    [launchTime release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
 
    [opQueue cancelAllOperations];
    [opQueue release];

    int i;
    for(i=0;i<kNumWatchedValues;i++){
        [timeRate[i] release];
    }
    [super dealloc];
}
- (void) setUpQueue
{
    if(!opQueue){
        opQueue = [[NSOperationQueue alloc] init];
        [opQueue setMaxConcurrentOperationCount:10];
    }
}
#pragma mark ***Accessors
- (NSTimeInterval) accurateUptime
{
    return [[NSDate date] timeIntervalSinceDate:launchTime];
}


- (NSTimeInterval) upTime
{
    return upTime;
}

- (void) setUpTime:(NSTimeInterval)aUpTime
{
    upTime = aUpTime;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MemoryWatcherUpTimeChanged object:self];
}

- (NSDate*) launchTime
{
    return launchTime;
}

- (void) setLaunchTime:(NSDate*)aLaunchTime
{
    [aLaunchTime retain];
    [launchTime release];
    launchTime = aLaunchTime;
}

- (NSTimeInterval) taskInterval
{
    return taskInterval;
}

- (void) setTaskInterval:(NSTimeInterval)aTaskInterval
{
    if(aTaskInterval<1)aTaskInterval = 1;
    taskInterval = aTaskInterval;
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:MemoryWatcherTaskIntervalNotification
     object:self];
}

- (NSUInteger) timeRateCount:(int)rateIndex
{
    if(rateIndex<kNumWatchedValues)return [timeRate[rateIndex] count];
    else return 0;
}

- (float) timeRate:(int)rateIndex value:(int)valueIndex
{
    if(rateIndex<kNumWatchedValues)return [timeRate[rateIndex] valueAtIndex:valueIndex];
    else return 0;
}

- (void) launchTask
{
    [self setUpQueue];
    [opQueue cancelAllOperations];
    int i;
    for(i=0;i<kNumWatchedValues;i++){
        if(!timeRate[i])timeRate[i] = [[ORTimeRate alloc] init];
    }
    
    ORTopShellOp* anOp = [[ORTopShellOp alloc] initWithDelegate:self];
    [opQueue addOperation:anOp];
    [anOp release];
    
    [self setUpTime:[[NSDate date] timeIntervalSinceDate:launchTime]];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(launchTask) object:nil];
    [self performSelector:@selector(launchTask) withObject:nil afterDelay:taskInterval];

}


- (float) convertValue:(float)aValue withMultiplier:(NSString*)aMultiplier
{
    if([aMultiplier hasPrefix:@"M"])return aValue;
    else if([aMultiplier hasPrefix:@"K"])return aValue/1000.;
    else return aValue/1000000.;
}

- (void) processTopResult:(NSString*)taskResult
{
    NSArray* lines = [taskResult componentsSeparatedByString:@"\n"];
    NSString* goodLine = @"";
    for(id aLine in [lines reverseObjectEnumerator]){
        if([aLine rangeOfString:@"Orca "].location != NSNotFound){
            goodLine = aLine;
            break;
        }
    }
    if([goodLine length]){
        //should now have a line that looks like "Orca 0.2 40M+"
        NSScanner* scanner = [[NSScanner alloc] initWithString:goodLine];
        if([scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil]){
            float value;
            //scan in cpu
            [scanner scanFloat:&value];
            [timeRate[kCPU] addDataToTimeAverage:value];
            
            //scan in RSIZE
            NSString* multiplier;
            [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
            [scanner scanFloat:&value];
            if([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&multiplier]){
                orcaMemory = [self convertValue:value withMultiplier:multiplier];
                [timeRate[kRSize] addDataToTimeAverage:orcaMemory];
            }
        }
        [scanner release];
    }
}

- (void) processVmStatResult:(NSString*)taskResult
{
    NSMutableDictionary* resultDict = [NSMutableDictionary dictionary];
    NSScanner* scanner = [[NSScanner alloc] initWithString:taskResult];
    NSString* aKey;
    while([scanner scanUpToString:@":" intoString:&aKey]){
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
        double value;
        if([scanner scanDouble:&value]){
            [resultDict setObject:[NSNumber numberWithDouble:value] forKey:aKey];
        }
    }
    [scanner release];

    pageSize    = [[resultDict objectForKey: @"Mach Virtual Memory Statistics"] unsignedLongValue];
    
    totalMemory = [[resultDict objectForKey: @"free"]        unsignedLongValue] +
                   [[resultDict objectForKey: @"active"]      unsignedLongValue] +
                   [[resultDict objectForKey: @"wired down"]  unsignedLongValue] +
                   [[resultDict objectForKey: @"inactive"]    unsignedLongValue];
    
    freeMemory  = [[resultDict objectForKey: @"free"]        unsignedLongValue] +
                   [[resultDict objectForKey: @"inactive"]    unsignedLongValue] +
                   [[resultDict objectForKey: @"speculative"] unsignedLongValue];

    
}

- (void) postUpdate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:MemoryWatcherChangedNotification object:self];
}

- (void) postCouchDBRecord
{
 
    NSDictionary* aRecord = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithUnsignedLong: pageSize],     @"pageSize",
                                [NSNumber numberWithUnsignedLong: totalMemory], @"totalMemory",
                                [NSNumber numberWithUnsignedLong: freeMemory],  @"freeMemory",
                                [NSNumber numberWithUnsignedLong: orcaMemory],  @"orcaMB",
                                   nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord"     object:self userInfo:aRecord];
}
- (NSString*) fullID
{
    return @"MemoryWatcher";
}
@end

//--------------------------------------------------
// ORTopShellOp
// run top
//--------------------------------------------------
@implementation ORTopShellOp
- (id) initWithDelegate:(id)aDelegate
{
    self = [super init];
    delegate    = aDelegate;
    return self;
}

- (void) main
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        if(![self isCancelled]){
            [self runTop];
            [self runVmStat];
            if([delegate respondsToSelector:@selector(postUpdate)]){
                [delegate performSelectorOnMainThread:@selector(postUpdate) withObject:nil waitUntilDone:YES];
            }
            
            if([delegate respondsToSelector:@selector(postCouchDBRecord)]){
                [delegate performSelectorOnMainThread:@selector(postCouchDBRecord) withObject:nil waitUntilDone:YES];
            }
        }
    }
    @catch(NSException* e){
    }
    @finally{
        [pool release];
    }
}
- (void) runTop
{
    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/top"];
    
    [task setArguments: [NSArray arrayWithObjects:@"-l",@"2",@"-i",@"1",@"-stats",@"command,cpu,rsize",nil]];
    
    NSPipe* pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle* file = [pipe fileHandleForReading];
    [task launch];
    
    NSData* data = [file readDataToEndOfFile];
    if(data){
        NSString* result = [[[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding] autorelease];
        if([result length]){
            if([delegate respondsToSelector:@selector(processTopResult:)]){
                [delegate performSelectorOnMainThread:@selector(processTopResult:) withObject:result waitUntilDone:YES];
            }
        }
    }
    [task release];
    [file closeFile];
}
- (void) runVmStat
{
    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/vm_stat"];
    
    NSPipe* pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle* file = [pipe fileHandleForReading];
    [task launch];
    
    NSData* data = [file readDataToEndOfFile];
    if(data){
        NSString* result = [[[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding] autorelease];
        result = [result stringByReplacingOccurrencesOfString:@"Pages " withString:@""];
        result = [result stringByReplacingOccurrencesOfString:@" bytes)" withString:@""];
        if([result length]){
            if([delegate respondsToSelector:@selector(processVmStatResult:)]){
                [delegate performSelectorOnMainThread:@selector(processVmStatResult:) withObject:result waitUntilDone:YES];
            }
        }
    }
    [task release];
    [file closeFile];
}
@end

