//
//  ThresholdCalibrationTask.m
//  Orca
//
//  Created by Mark Howe on Tue Mar 23 2004.
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


#import "ThresholdCalibrationTask.h"
#import "ORRateGroup.h"
#import "ThresholdCalibrationChannel.h"

@implementation ThresholdCalibrationTask
- (id) init
{
    self = [super init];
	[self setName:@"Threshold Calibration"];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [channelArray release];
	[reportArray release];
	
    [super dealloc];
}

- (NSString*) name
{
	return name;
}
- (void) setName:(NSString*)aName
{
	[name autorelease];
	name = [aName copy];
}


- (id) delegate
{
    return delegate;
}
- (void) setDelegate:(id)aDelegate
{
    delegate = aDelegate;
}

- (NSMutableArray *)channelArray {
    return channelArray; 
}

- (void)setChannelArray:(NSMutableArray *)someChannels {
    [someChannels retain];
    [channelArray release];
    channelArray = someChannels;
}

- (ORRateGroup*) rateGroup
{
	return rateGroup;
}

- (void) setRateGroup:(ORRateGroup*)aRateGroup
{
    rateGroup = aRateGroup;
}
- (int) tag
{
	return tag;
}

- (void) setTag:(int)aTag
{
    tag = aTag;
}
- (float) stepTime
{
	if(stepTime==0)return .4;
	else return stepTime;
}

- (void) setStepTime:(float)aTime
{
	stepTime = aTime;
}

- (unsigned int)maxThreshold
{
	if(maxThreshold==0)return 0xff;
	else return maxThreshold;
}

- (void) setMaxThreshold:(unsigned int)aValue
{
	maxThreshold = aValue;
}

- (void) start:(int)num enabledMask:(unsigned long)enabledMask rateGroup:(ORRateGroup*)aRateGroup tag:(int)aTag
{ 
    numChannels = num;
	
    [self setRateGroup:aRateGroup];
    [self setTag:aTag];
    
    NSLog(@"%@ <%d>: started.\n",name,tag);
	
	[[NSNotificationCenter defaultCenter] addObserver : self
											 selector : @selector(runStatusChanged:)
												 name : ORRunStatusChangedNotification
											   object : nil];
	
    savedIntegrationTime = [aRateGroup integrationTime];
    [aRateGroup setIntegrationTime:.2];
    int i;
    [reportArray release];
	reportArray = [[NSMutableArray array] retain];
	[channelArray removeAllObjects];
    [self setChannelArray:[NSMutableArray array]];
    for(i=0;i<numChannels;i++){
		[delegate setThresholdCalibration:i state:@"---"];
		if(enabledMask & (1<<i)){
			ThresholdCalibrationChannel* aChannel = [[ThresholdCalibrationChannel alloc] init];
			[aChannel setOwner:self];
			[aChannel setChannel:i];
			[channelArray addObject:aChannel];
			[aChannel release];
		}
		[reportArray addObject:[NSNull null]];
    }
    [self stepCalibration];
    
}

- (void) stepCalibration
{
    NSMutableArray* doneChannels = [NSMutableArray array];
    NSEnumerator* e = [channelArray objectEnumerator];
    ThresholdCalibrationChannel* aChannel;
    while(aChannel = [e nextObject]){
		if([aChannel isDone]){
			//this channel is done, add to remove list
			[doneChannels addObject:aChannel];
		}
		else [aChannel stepCalibration];
    } 
	
	//load the hw with the last set values
    [delegate loadCalibrationValues];
	@try {
		if([delegate respondsToSelector:@selector(reArm)]){
			[delegate reArm];
		}
	}
	@catch(NSException* localException) {
	}
	
    //remove all done channels.
    [channelArray removeObjectsInArray:doneChannels];
	
	//add done channels to the report Array
	e = [doneChannels objectEnumerator];
    while(aChannel = [e nextObject]){
		[reportArray replaceObjectAtIndex:[aChannel channel] withObject:aChannel];
	}
	
    if([channelArray count]){
		//there are channels left to do so schedule another step.
		[self performSelector:@selector(stepCalibration) withObject:nil afterDelay:[self stepTime]];
    }
    else {
		//all done, finish up.
		NSLog(@"%@ <%d>: Finished. Final Report:\n",name,tag);
		e = [reportArray objectEnumerator];
		while(aChannel = [e nextObject]){
			if([aChannel class] == [ThresholdCalibrationChannel class]){
				[aChannel printReport];
			}
		}
		NSLog(@"---------------------------\n",name,tag);
		[self stop];
    }
}

- (void) runStatusChanged:(NSNotification*)aNote
{
    if(![gOrcaGlobals runInProgress]){
		NSLogColor([NSColor redColor],@"%@ <%d>: No run in progress.\n",name,tag);
		[self abort];
    }
}

- (void)abort
{
    NSLogColor([NSColor redColor],@"%@ <%d>: Stopped before finished.\n",name,tag);
    int i;
    for(i=0;i<numChannels;i++){
		[delegate setThresholdCalibration:i state:@"aborted"];
    }
    [self stop];
}

- (void) stop
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [channelArray release];
    channelArray = nil;
    [rateGroup setIntegrationTime:savedIntegrationTime];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [delegate setCalibrationTask:nil];
}


@end

