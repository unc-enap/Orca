//
//  ThresholdCalibrationChannel.m
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


#import "ThresholdCalibrationChannel.h"
#import "ThresholdCalibrationTask.h"

#import "ORRateGroup.h"

static NSString* thresholdCalibrationStateNames[kNumStates]={
@"Idle",
@"Starting",
@"Search",
@"Down",
@"Integrate",
@"Up",
@"Tweak Dn",
@"Integrate",
@"Tweak Up",
@"Finishing",
@"Done",
@"Failed",
};

#define kNoiseGoal 10

@implementation ThresholdCalibrationChannel
- (id) init
{
	self = [super init];
	state = kIdle;
	return self;
}

- (id) delegate
{
    return delegate;
}

- (void) setOwner:(ThresholdCalibrationTask*)anOwner
{
    owner = anOwner;
    [[owner delegate] setThresholdCalibration:channel state:@"idle"];
}

- (int)channel 
{
    return channel;
}

- (void)setChannel:(int)aChannel 
{
    channel = aChannel;
}

- (int)threshold 
{
    return threshold;
}

- (void)setThreshold:(int)aThreshold 
{
    lastThreshold = threshold;
    threshold = aThreshold;
}

- (NSString*) reason
{
	return reason;
}
- (void) setReason:(NSString*)aReason
{
	[reason autorelease];
	reason = [aReason copy];
}

- (BOOL) isDone
{
    return isDone;
}

- (void) stepCalibration
{
	int delta;
	float rate = 0.0;
	if([[owner delegate] respondsToSelector:@selector(rateGroup)]){
		rate = [[[[owner delegate] rateGroup]rateObject:channel] rate];
	}
	else {
		if([[owner delegate] respondsToSelector:@selector(rate:)]){
			rate = [[owner delegate] rate:channel];
		}
		else state = kFailed;
	}
	@try {
		
		switch(state){
				
			case kIdle:
				originalThreshold = [[owner delegate] thresholdDac:channel];
				state = kStarting;
				bottomSearchCount = 0;
				break;
				
			case kStarting:
				[self setThreshold:0x00];
				state = kBottomSearch;
				break;
				
			case kBottomSearch:
				[self setThreshold:threshold+1];
				if(threshold>0x40 && bottomSearchCount<2){
					state = kStarting;
					bottomSearchCount++;
				}
				else if(bottomSearchCount>=2){
					[self setReason:@"No Noise"];
					state = kFailed;
				}
				else if(rate>kNoiseGoal*2){
					baseThreshold = threshold;
					noiseBottom = baseThreshold;
					state = kIntegrating;
					[self setThreshold:[owner maxThreshold]-1];
				}
				else if(threshold >= [owner maxThreshold]){
					[self setReason:@"No Noise"];
					state = kFailed;
				}
				break;
				
			case kIteratingDown:
				stateCount = 0;
				delta = abs(threshold-baseThreshold)/2;
				if(threshold - delta < baseThreshold){
					threshold = baseThreshold;
				}
				if(delta==0)state = kIntegrating1;
				else {
					[self setThreshold:threshold - delta];
					state = kIntegrating;
				}
				break;
				
			case kIteratingUp:
				stateCount = 0;
				delta = abs(threshold-baseThreshold)/2;
				if(threshold + delta > [owner maxThreshold]){
					threshold = baseThreshold;
				}
				if(delta==0)state = kIntegrating1;
				else {
					[self setThreshold:threshold + delta];
					state = kIntegrating;
				}
				break;
				
			case kIntegrating:
				if(++stateCount>=2){
					if(rate < kNoiseGoal){
						if(lastIteratingState == kIteratingUp){
							baseThreshold = lastThreshold;
						}
						state = kIteratingDown;
						lastIteratingState = state;
					}
					else  {
						if(threshold != [owner maxThreshold]){
							if(lastIteratingState == kIteratingDown){
								baseThreshold = lastThreshold;
							}
							state = kIteratingUp;
							lastIteratingState = state;
						}
					}
				}
				break;
				
			case kIntegrating1:
				if(++stateCount>=2){
					if(rate > 1.0){
						if(lastIteratingState == kTweakDown){
							//hit the noise coming down
							[self setThreshold:threshold + 1];
							state = kFinishing;
						}
						else {
							lastIteratingState = kTweakUp;
							state = kTweakUp;
						}
					}
					else  {
						if(lastIteratingState == kTweakUp){
							//left the noise going up
							state = kFinishing;
						}
						else {						
							lastIteratingState = kTweakDown;
							state = kTweakDown;
						}
					}
				}
				break;
				
			case kTweakDown:
				stateCount = 0;
				if(threshold < noiseBottom){
					[self setThreshold:noiseBottom];
					state = kFinishing;
				}
				else {
					state = kIntegrating1;
					[self setThreshold:(threshold - 1)];
				}
				break;
				
			case kTweakUp:
				stateCount = 0;
				if(threshold >= [owner maxThreshold]){
					[self setReason:@"No Noise"];
					state = kFailed;
				}
				else {
					[self setThreshold:(threshold + 1)];
					state = kIntegrating1;
				}
				break;
				
				
			case kFinishing:
				[self setThreshold:threshold + [[owner delegate] calibrationFinalDelta]];
				state = kDone;
				break;
				
			case kFailed:
				[[owner delegate] setThresholdDac:channel withValue:originalThreshold];
				isDone = YES;
				break;
			case kDone:
				isDone = YES;
				break;
		}
		
		[[owner delegate] setThresholdDac:channel withValue:threshold];
		NSString* string = thresholdCalibrationStateNames[state];
		if(state==kDone){
			int delta = threshold-originalThreshold;
			if(delta > 0)string = [NSString stringWithFormat:@"(+%d)",delta];
			else string = [NSString stringWithFormat:@"(%d)",delta];
		}
		[[owner delegate] setThresholdCalibration:channel state:string];
		
	}
	@catch(NSException* localException) {
	}
	if(threshold>[owner maxThreshold])NSLog(@"*************** >%x\n",[owner maxThreshold]);
}

- (void) printReport
{
	NSString* string = @"(0)";
	int delta = threshold-originalThreshold;
	if(delta > 0)string = [NSString stringWithFormat:@"(+%d)",delta];
	else string = [NSString stringWithFormat:@"(%d)",delta];
	
	if(state != kFailed){
		NSLog(@"%02d threshold was: 0x%02X now: 0x%02X  %@\n",channel,originalThreshold,threshold,string);
	}
	else {
		NSLogColor([NSColor redColor],@"%02d threshold was: 0x%02X now: 0x%02x  %@ Failed: %@\n",channel,originalThreshold,threshold,string,reason);
	}
}



@end
