//
//  ORiSegHVCard.m
//  Orca
//
//  Created by Mark Howe on Wed Feb 2,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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


#import "ORiSegHVCard.h"
#import "ORDataTypeAssigner.h"
#import "ORMPodProtocol.h"
#import "ORTimeRate.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORSNMP.h"
#import "ORMPodCrate.h"
#import "ORAlarm.h"
#import "ORDataPacket.h"

NSString* ORiSegHVCardShipRecordsChanged		= @"ORiSegHVCardShipRecordsChanged";
NSString* ORiSegHVCardMaxCurrentChanged         = @"ORiSegHVCardMaxCurrentChanged";
NSString* ORiSegHVCardMaxVoltageChanged         = @"ORiSegHVCardMaxVoltageChanged";
NSString* ORiSegHVCardSelectedChannelChanged	= @"ORiSegHVCardSelectedChannelChanged";
NSString* ORiSegHVCardSettingsLock				= @"ORiSegHVCardSettingsLock";
NSString* ORiSegHVCardHwGoalChanged             = @"ORiSegHVCardHwGoalChanged";
NSString* ORiSegHVCardTargetChanged             = @"ORiSegHVCardTargetChanged";
NSString* ORiSegHVCardCurrentChanged			= @"ORiSegHVCardCurrentChanged";
NSString* ORiSegHVCardOutputSwitchChanged		= @"ORiSegHVCardOutputSwitchChanged";
NSString* ORiSegHVCardRiseRateChanged			= @"ORiSegHVCardRiseRateChanged";
NSString* ORiSegHVCardChannelReadParamsChanged  = @"ORiSegHVCardChannelReadParamsChanged";
NSString* ORiSegHVCardExceptionCountChanged     = @"ORiSegHVCardExceptionCountChanged";
NSString* ORiSegHVCardConstraintsChanged		= @"ORiSegHVCardConstraintsChanged";
NSString* ORiSegHVCardRequestHVMaxValues		= @"ORiSegHVCardRequestHVMaxValues";
NSString* ORiSegHVCardChanNameChanged           = @"ORiSegHVCardChanNameChanged";
NSString* ORiSegHVCardDoNotPostSafetyAlarmChanged = @"ORiSegHVCardDoNotPostSafetyAlarmChanged";
NSString* ORiSegHVCardRequestCustomInfo		    = @"ORiSegHVCardRequestCustomInfo";
NSString* ORiSegHVCardCustomInfoChanged         = @"ORiSegHVCardCustomInfoChanged";

@interface ORiSegHVCard (private)
- (void) postHistoryRecord;
@end

@implementation ORiSegHVCard

#define kMaxVoltage 6000
#define kMaxCurrent 1000.

#pragma mark ***Initialization
- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		[voltageHistory[i] release];
		[currentHistory[i] release];
        [rdParams[i] release];
        [chanName[i] release];
	}
    [hvConstraints release];
    [safetyLoopNotGoodAlarm clearAlarm];
    [safetyLoopNotGoodAlarm release];
    [modParams release];
    [lastHistoryPost release];
    
    [super dealloc];
}

- (NSString*) imageName
{
    return nil;
}
- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:[self imageName]];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    
    if([self constraintsInPlace]){
        NSImage* constraintImage = [NSImage imageNamed:@"smallLock"];
        [constraintImage drawAtPoint:NSMakePoint([i size].width/2 - [constraintImage size].width/2,[i size].height-[constraintImage size].height-15) fromRect:[constraintImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    }
    
    [i unlockFocus];
    [self setImage:i];
    [i release];
    
}


- (void) makeMainController
{
    [self linkToController:@"ORiSegHVCardController"];
}

- (NSString*) settingsLock
{
	return @"";  //subclasses should override
}

- (NSString*) name
{
	return @"??"; //subclasses should override
}


- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];
    [notifyCenter addObserver : self
                     selector : @selector(runStarted:)
                         name : ORRunStartedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(productionModeChanged:)
                         name : ORInProductionModeChanged
                       object : nil];
}

- (void) productionModeChanged:(NSNotification*)aNote
{
    BOOL inProductionMode = [[ORGlobal sharedGlobal] inProductionMode];
    if(inProductionMode){
        [self setDoNotPostSafetyLoopAlarm:NO];
   }
}

- (void) runStarted:(NSNotification*)aNote
{
    [self shipDataRecords];
}

#pragma mark ***Accessors

- (BOOL) polarity
{
	return kPositivePolarity;
}

- (int) supplyVoltageLimit
{
    //subclassed should override
    return kMaxVoltage;
}


- (id)	adapter
{
	id anAdapter = [guardian adapter];
	if(anAdapter)return anAdapter;
	else {
		NSLogColor([NSColor redColor],@"You must place a MPod adaptor card into the crate.\n");
		//[NSException raise:@"No adapter" format:@"You must place a MPod adaptor card into the crate."];
	}
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
     postNotificationName:ORiSegHVCardExceptionCountChanged
     object:self];
}

- (void)incExceptionCount
{
    ++exceptionCount;
    
	[[NSNotificationCenter defaultCenter]
     postNotificationName:ORiSegHVCardExceptionCountChanged
     object:self];
}

- (BOOL) doNotPostSafetyLoopAlarm
{
    return doNotPostSafetyLoopAlarm;
}

- (void) setDoNotPostSafetyLoopAlarm:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoNotPostSafetyLoopAlarm:doNotPostSafetyLoopAlarm];
    doNotPostSafetyLoopAlarm = aState;
    if(aState){
        [safetyLoopNotGoodAlarm clearAlarm];
        [safetyLoopNotGoodAlarm release];
        safetyLoopNotGoodAlarm = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardDoNotPostSafetyAlarmChanged object:self];
}
- (void) makeCurrentHistory:(short)i
{
    if(currentHistory[i] == nil) currentHistory[i] = [[ORTimeRate alloc] init];
}
- (void) setRdParamsFrom:(NSDictionary*)aDictionary
{
    @try {
        int numChannels = [self numberOfChannels];
        int i;
        for(i=0;i<numChannels;i++){
            id oldOnOffState	= [[[[rdParams[i] objectForKey:@"outputSwitch"] objectForKey:@"Value"] copy] autorelease];

            NSString* aChannelKey = [NSString stringWithFormat:@"u%d",[self slotChannelValue:i]];
            id params = [aDictionary objectForKey:aChannelKey];
            [rdParams[i] release];
            rdParams[i] = [params retain];

            id currentOnOffState	 = [[rdParams[i] objectForKey:@"outputSwitch"] objectForKey:@"Value"];
            int oldState	 = [oldOnOffState intValue];
            int currentState = [currentOnOffState intValue];
            
            if(oldOnOffState && currentOnOffState && (oldState != currentState)){
                NSLog(@"MPod (%lu), Card %d Channel %d changed state from %@ to %@\n",[[self guardian]uniqueIdNumber],[self slot], i,oldState?@"ON":@"OFF",currentState?@"ON":@"OFF");
            }
            
            
            if(voltageHistory[i] == nil) voltageHistory[i] = [[ORTimeRate alloc] init];
            if(currentHistory[i] == nil) currentHistory[i] = [[ORTimeRate alloc] init];
            [voltageHistory[i] addDataToTimeAverage:[self channel:i readParamAsFloat:@"outputMeasurementSenseVoltage"]];
            [currentHistory[i] addDataToTimeAverage:[self channel:i readParamAsFloat:@"outputMeasurementCurrent"]*1000000];
            
        }

        NSString* moduleID = [self getModuleString];
        id params = [aDictionary objectForKey:moduleID];
        id currentEventStatus = [params objectForKey:@"moduleEventStatus"];
        NSString* newModuleStatus = (NSString*)[currentEventStatus objectForKey:@"Names"];
        
        [modParams release];
        modParams = [[aDictionary objectForKey:moduleID] retain];

        int moduleEvents = [self moduleFailureEvents];
        
        if(!doNotPostSafetyLoopAlarm && (moduleEvents & moduleEventSafetyLoopNotGood)){
            if(!safetyLoopNotGoodAlarm){
                NSString* s = [NSString stringWithFormat:@"%@ Safety Loop Not Good", [self fullID] ];
                safetyLoopNotGoodAlarm = [[ORAlarm alloc] initWithName:s  severity: kHardwareAlarm];
                [safetyLoopNotGoodAlarm setSticky: YES];
                [safetyLoopNotGoodAlarm setHelpString:@"No current is going into the SL connector on the HV card. Apply current to SL input and clear events to clear alarm."];
            
                [safetyLoopNotGoodAlarm postAlarm];
                NSLog(@"MPod Module Status Events: %@\n", newModuleStatus);
            }
        }
        else if( safetyLoopNotGoodAlarm ){
            [safetyLoopNotGoodAlarm clearAlarm];
            [safetyLoopNotGoodAlarm release];
            safetyLoopNotGoodAlarm = nil;
        }
        
        
        if(shipRecords) [self shipDataRecords];
        
        if([[self adapter] respondsToSelector:@selector(power)]){
            if(![[self adapter] power]){
                int i;
                for(i=0;i<[self numberOfChannels];i++){
                    [rdParams[i] release];
                    rdParams[i] = nil;
                }
            }
        }
        
        NSDate* now = [NSDate date];
        if([now timeIntervalSinceDate:lastHistoryPost]>=60){
            [lastHistoryPost release];
            lastHistoryPost = [now retain];
            [self postHistoryRecord];
        }
        
	}
    @catch(NSException* e){
        
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardChannelReadParamsChanged object:self];
	
}
- (NSDictionary*) modParams
{
    return modParams;
}

- (NSDictionary*) rdParams:(int)i
{
    if(i>=0 && i<[self numberOfChannels]){
        return rdParams[i];
    }
    else return nil;
}

- (BOOL) shipRecords
{
    return shipRecords;
}

- (void) setShipRecords:(BOOL)aShipRecords
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipRecords:shipRecords];
    shipRecords = aShipRecords;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardShipRecordsChanged object:self];
}

- (BOOL) channelInBounds:(short)aChan
{
	if(aChan>=0 && aChan<[self numberOfChannels])return YES;
	else return NO;
}

- (int) selectedChannel
{
    return selectedChannel;
}

- (void) setSelectedChannel:(int)aSelectedChannel
{
    if(aSelectedChannel<0)aSelectedChannel=0;
    else if(aSelectedChannel>[self numberOfChannels])aSelectedChannel=[self numberOfChannels];
    
    if(aSelectedChannel != selectedChannel){
    
        selectedChannel = aSelectedChannel;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardSelectedChannelChanged object:self];
        
        [self requestMaxValues:selectedChannel];
        [self requestCustomInfo:selectedChannel];
        
    }
}
- (void) requestMaxValues:(int)aChannel
{
 	if([self channelInBounds:aChannel]){
        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:[self crateNumber]],      @"crate",
                                  [NSNumber numberWithInt:[self slot]],             @"card",
                                  [NSNumber numberWithInt:aChannel],                @"channel",
                                  nil];
        [self setMaxVoltage:aChannel withValue:[self supplyVoltageLimit]]; //assume no request returned
        [[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardRequestHVMaxValues object:self userInfo:userInfo];
    }
}

- (void) requestCustomInfo:(int)aChannel
{
    if([self channelInBounds:aChannel]){
        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:[self crateNumber]],      @"crate",
                                  [NSNumber numberWithInt:[self slot]],             @"card",
                                  [NSNumber numberWithInt:aChannel],                @"channel",
                                  nil];
        [self setCustomInfo:aChannel string:@""]; //assume no request returned
        [[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardRequestCustomInfo object:self userInfo:userInfo];
    }
}


- (NSString*) getModuleString
{
	return [NSString stringWithFormat:@"ma%i", ([self slot]-1) ];
}

- (int) channel:(short)i readParamAsInt:(NSString*)name
{
    if([self channelInBounds:i]){
        return [[[rdParams[i] objectForKey:name] objectForKey:@"Value"] intValue];
    }
    
    return 0;
}

- (float) channel:(short)i readParamAsFloat:(NSString*)name
{
    if([self channelInBounds:i]){
           return [[[rdParams[i] objectForKey:name] objectForKey:@"Value"] floatValue];
    }
    return 0;
}

- (id) channel:(short)i readParamAsValue:(NSString*)name
{
    if([self channelInBounds:i]){
        return  [[rdParams[i] objectForKey:name] objectForKey:@"Value"];
    }
    return 0;
}

- (id) channel:(short)i readParamAsObject:(NSString*)name
{
    if([self channelInBounds:i]){
            return [rdParams[i] objectForKey:name];
    }
    else return 0;
}

- (void) syncDialog
{	
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		
		float readBackVoltage = [self channel:i readParamAsFloat:@"outputMeasurementSenseVoltage"];
		int theTarget = fabs(readBackVoltage)+ 0.5;
		[self setTarget:i withValue:theTarget];

		//if([name isEqualToString:@"outputCurrent"])	[self setMaxCurrent:theChannel withValue:[[anEntry objectForKey:@"Value"] floatValue]*1000000.];
	}
}

- (NSArray*) addChannelNumbersToParams:(NSArray*)someChannelParams
{
	NSMutableArray* convertedArray = [NSMutableArray array];
	for(id aParam in someChannelParams){
		int i;
		for(i=0;i<[self numberOfChannels];i++){
			[convertedArray addObject:[aParam stringByAppendingFormat:@".u%d",[self slotChannelValue:i]]];
		}
	}
	return convertedArray;
}

- (int) slotChannelValue:(int)aChannel
{
	return ([self slot]-1) * 100 + aChannel;
}

- (NSArray*) addChannel:(int)i toParams:(NSArray*)someChannelParams
{
	NSMutableArray* convertedArray = [NSMutableArray array];
	for(id aParam in someChannelParams){
		[convertedArray addObject:[aParam stringByAppendingFormat:@".u%d",[self slotChannelValue:i]]];
	}
	return convertedArray;
}

- (void) processWriteResponseArray:(NSArray*)response
{
	[super processWriteResponseArray:response];
	for(id anEntry in response){
		NSString* anError = [anEntry objectForKey:@"Error"];
		if([anError length]){
			if([anError rangeOfString:@"Timeout"].location != NSNotFound){
				//time out so flush the queue
				[[ORSNMPQueue queue] cancelAllOperations];
				NSLogError(@"TimeOut",[NSString stringWithFormat:@"MPod Crate %d\n",[self crateNumber]],[NSString stringWithFormat:@"HV Card %d\n",[self slot]],nil);
				[[NSNotificationCenter defaultCenter] postNotificationName:@"Timeout" object:self];
				break;
			}
		}
	}
}

- (int) numberChannelsOn
{
	int count = 0;
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		int state = [self channel:i readParamAsInt:@"outputSwitch"];
		if(state == kiSegHVCardOutputOn)count++;
	}
	return count;
}
- (unsigned long) channelStateMask
{
	unsigned long mask = 0x0;
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		int state = [self channel:i readParamAsInt:@"outputSwitch"];
		mask |= (1L<<state);
	}
	return mask;
}

- (BOOL) channelIsRamping:(short)chan
{
	int state = [self channel:chan readParamAsInt:@"outputStatus"];
	if(state & outputOnMask){
		if(state & outputRampUpMask)return YES;
		else if(state & outputRampDownMask)return YES;
	}
	return NO;
}

- (int) numberChannelsRamping
{
	int count = 0;
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		if([self channelIsRamping:i])count++;
	}
	return count;
}

- (int) numberChannelsWithNonZeroVoltage
{
	int count = 0;
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		float voltage	= [self channel:i readParamAsFloat:@"outputMeasurementSenseVoltage"];
        int state       = [self channel:i readParamAsInt:@"outputSwitch"];
		if((state == kiSegHVCardOutputOn) && (fabs(voltage) > 1))count++;
	}
	return count;
}

- (int) numberChannelsWithNonZeroHwGoal
{
	int count = 0;
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		if(hwGoal[i] > 0)count++;
	}
	return count;
}

- (void)  commitTargetsToHwGoals
{
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		[self commitTargetToHwGoal:i];
	}
}

- (void) commitTargetToHwGoal:(short)channel
{
	if([self channelInBounds:channel]){
		hwGoal[channel] = target[channel];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardChannelReadParamsChanged object:self];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardHwGoalChanged object:self];
	}
}
- (void) loadValues:(short)channel
{
	if([self channelInBounds:channel]){
		[self commitTargetToHwGoal:selectedChannel];
		[self writeRiseTime];
		[self writeMaxCurrent:channel];
		[self writeVoltage:channel];
	}
}

- (void) writeRiseTime
{
	[self writeRiseTime:riseRate];
}

- (void) writeRiseTime:(float)aValue
{
	int channel = 0; //in this firmware version all the risetimes and falltimes get set to this value. So no need to send for all channels.
	NSString* cmd = [NSString stringWithFormat:@"outputVoltageRiseRate.u%d F %f",[self slotChannelValue:channel],aValue];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
}

- (void) writeVoltage:(short)channel
{
	if([self channelInBounds:channel]){
		NSString* cmd = [NSString stringWithFormat:@"outputVoltage.u%d F %f",[self slotChannelValue:channel],(float)hwGoal[channel]];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
    }
}

- (void) writeMaxCurrent:(short)channel
{
	if([self channelInBounds:channel]){
		NSString* cmd = [NSString stringWithFormat:@"outputCurrent.u%d F %f",[self slotChannelValue:channel],maxCurrent[channel]/1000000.];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
    }
}

- (void) setPowerOn:(short)channel withValue:(BOOL)aValue
{
	if(aValue) [self turnChannelOn:channel];
	else [self turnChannelOff:channel];
}

- (void) turnChannelOn:(short)channel
{
    if([self isOn:channel])return; //don't mess with channels already on.
    
	[self setHwGoal:channel withValue:0];
	[self writeVoltage:channel];
	
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kiSegHVCardOutputOn];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
    NSLog(@"Turned ON MPod (%lu), Card %d Channel %d\n",[[self guardian]uniqueIdNumber],[self slot], channel);
}

- (void) turnChannelOff:(short)channel
{
	[self setHwGoal:channel withValue:0];
	[self writeVoltage:channel];
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kiSegHVCardOutputOff];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
    NSLog(@"Turned OFF MPod (%lu), Card %d Channel %d\n",[[self guardian]uniqueIdNumber],[self slot], channel);
}

- (void) panicChannel:(short)channel
{
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kiSegHVCardOutputSetEmergencyOff];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
}

- (void) clearPanicChannel:(short)channel
{
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kiSegHVCardOutputResetEmergencyOff];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
    NSLog(@"Clear Panic MPod (%lu), Card %d Channel %d\n",[[self guardian]uniqueIdNumber],[self slot], channel);
}

- (void) clearEventsChannel:(short)channel
{
	NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i %d",[self slotChannelValue:channel],kiSegHVCardOutputClearEvents];
	[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
    NSLog(@"Clear Events MPod (%lu), Card %d Channel %d\n",[[self guardian]uniqueIdNumber],[self slot], channel);
}

- (void) stopRamping:(short)channel
{
	if([self channelInBounds:channel]){
		//the only way to stop a ramp is to change the hwGoal to be the actual voltage
		float voltageNow = [self channel:channel readParamAsFloat:@"outputMeasurementSenseVoltage"];
		if(fabs(voltageNow-(float)hwGoal[channel])>5){
			[self setHwGoal:channel withValue:voltageNow];
			[self writeVoltage:channel];
		}
	}
}

- (void) rampToZero:(short)channel
{
	if([self channelInBounds:channel]){
		[self setHwGoal:channel withValue:0];
		[self writeVoltage:channel];
	}
}

- (void) panic:(short)channel
{
	if([self channelInBounds:channel]){
		[self setHwGoal:channel withValue:0];
		[self writeVoltage:channel];
		[self panicChannel:channel];
	}
}

- (BOOL) isOn:(short)aChannel
{
	if([self channelInBounds:aChannel]){
		int outputSwitch = [self channel:aChannel readParamAsInt:@"outputSwitch"];
		return outputSwitch==kiSegHVCardOutputOn;
	}
	else return NO;
}

- (BOOL) hvOnAnyChannel
{
 	int i;
	for(i=0;i<[self numberOfChannels];i++){
        if([self isOn:i] || [self voltage:i]>10)return YES;
    }
    return NO;
}

- (void) turnAllChannelsOn
{
	int i;
	for(i=0;i<[self numberOfChannels];i++)[self turnChannelOn:i];
	[[self adapter] pollHardware];
}

- (void) turnAllChannelsOff
{
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		[self turnChannelOff:i];
	}
	[[self adapter] pollHardware];

}

- (void) panicAllChannels
{
	int i;
	for(i=0;i<[self numberOfChannels];i++)[self panic:i];
}

- (void) clearAllPanicChannels
{
	int i;
	for(i=0;i<[self numberOfChannels];i++)[self clearPanicChannel:i];
}

- (void) clearAllEventsChannels
{
	int i;
	for(i=0;i<[self numberOfChannels];i++)[self clearEventsChannel:i];
}

- (void) stopAllRamping
{
	int i;
	for(i=0;i<[self numberOfChannels];i++)[self stopRamping:i];
}

- (void) rampAllToZero
{
	int i;
	for(i=0;i<[self numberOfChannels];i++)[self rampToZero:i];
}

- (void) panicAll
{
	int i;
	for(i=0;i<[self numberOfChannels];i++)[self panic:i];
}

- (void) clearModule
{
	NSString* clearCmd =[NSString stringWithFormat:@"moduleDoClear.%@ i %d",[self getModuleString] ,1];
	[[self adapter] writeValue:clearCmd target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
	NSLog(@"Clear Module Events, Card %d \n",[self slot]);
}

- (unsigned long) failureEvents:(short)channel
{
	int events = [self channel:selectedChannel readParamAsInt:@"outputStatus"];
	events &= (outputFailureMinSenseVoltageMask    | outputFailureMaxSenseVoltageMask |
			   outputFailureMaxTerminalVoltageMask | outputFailureMaxCurrentMask |
			   outputFailureMaxTemperatureMask     | outputFailureMaxPowerMask |
			   outputFailureTimeoutMask            | outputCurrentLimitedMask |
			   outputEmergencyOffMask);
	return events;
}

- (unsigned long) failureEvents
{
	unsigned long failEvents = 0;
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		failEvents |= [self failureEvents:i];
	}
	return failEvents;
}
- (unsigned long) moduleFailureEvents
{
    id oldModuleEventStatus = [[[modParams objectForKey:@"moduleEventStatus"] copy] autorelease];
    int events = [[oldModuleEventStatus objectForKey:@"Value"] intValue];
    events &= ( moduleEventPowerFail    |   moduleEventLiveInsertion            |
                moduleEventService      |   moduleHardwareLimitVoltageNotGood   |
                moduleEventInputError   |   moduleEventSafetyLoopNotGood        |
                moduleEventSupplyNotGood|   moduleEventTemperatureNotGood       );
    return events;
}

- (NSString*) channelState:(short)channel
{
	int outputSwitch = [self channel:channel readParamAsInt:@"outputSwitch"];
	int outputStatus = [self channel:channel readParamAsInt:@"outputStatus"];
	
	if(outputSwitch == kiSegHVCardOutputSetEmergencyOff)	return @"PANICKED";
	else {
		if(outputStatus & kiSegHVCardProblemMask)			return @"PROBLEM";
		else if(outputStatus & outputRampUpMask)			return @"RAMP UP";
		else if(outputStatus & outputRampDownMask)			return @"RAMP DN";
		else {
			switch(outputSwitch){
				case kiSegHVCardOutputOff:					return @"OFF";
				case kiSegHVCardOutputOn:					return @"ON";
				case kiSegHVCardOutputResetEmergencyOff:	return @"PANIC CLR";
				case kiSegHVCardOutputSetEmergencyOff:		return @"PANICKED";
				case kiSegHVCardOutputClearEvents:			return @"EVENT CLR";
				default:									return @"?";
			}
		}
	}
}


- (float) riseRate{ return riseRate; }
- (void) setRiseRate:(float)aValue
{
	if(aValue<2)aValue=2;
	else if(aValue>1200)aValue=1200; //20% of max
    [[[self undoManager] prepareWithInvocationTarget:self] setRiseRate:riseRate];
	riseRate = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardRiseRateChanged object:self];
}

- (int) hwGoal:(short)chan
{
	if([self channelInBounds:chan])return hwGoal[chan];
	else return 0;
}
- (void) setHwGoal:(short)chan withValue:(int)aValue
{
	if([self channelInBounds:chan]){
		if(aValue<0)aValue=0;
		else {
            int theMax = MIN([self supplyVoltageLimit],[self maxVoltage:chan]);
            if(aValue>theMax)aValue = theMax;
        }
		hwGoal[chan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardHwGoalChanged object:self];
	}
}

- (NSString*) hwGoalString:(short)chan
{
	if([self channelInBounds:chan]){
		return [NSString stringWithFormat:@"Goal: %d",hwGoal[chan]];
	}
	else return @"";
}

- (float) maxCurrent:(short)chan
{
	if([self channelInBounds:chan])return maxCurrent[chan];
	else return 0;
}

- (void) setMaxCurrent:(short)chan withValue:(float)aValue
{
	if([self channelInBounds:chan]){
		if(aValue<0)aValue=0;
		else if(aValue>kMaxCurrent)aValue = kMaxCurrent;
		[[[self undoManager] prepareWithInvocationTarget:self] setMaxCurrent:chan withValue:maxCurrent[chan]];
		maxCurrent[chan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardMaxCurrentChanged object:self];
	}
}
- (NSString*) chanName:(short)chan
{
    if([self channelInBounds:chan]){
        if(chanName[chan])return chanName[chan];
        else return @"";
    }
    return @"";
}

- (void) setChan:(short)chan name:(NSString*)aName
{
    if([self channelInBounds:chan]){
        [chanName[chan] autorelease];
        chanName[chan] = [aName copy];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardChanNameChanged object:self];
    }
}


- (int) maxVoltage:(short)chan
{
	if([self channelInBounds:chan])return MIN([self supplyVoltageLimit],maxVoltage[chan]);
	else return 0;
}

- (void) setMaxVoltage:(short)chan withValue:(int)aValue
{
	if([self channelInBounds:chan]){
		if(aValue<0)aValue=0;
		else if(aValue>[self supplyVoltageLimit])aValue = [self supplyVoltageLimit];
		maxVoltage[chan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardMaxVoltageChanged object:self];
	}
}
- (NSString*) customInfo:(short)chan
{
   	if([self channelInBounds:chan]){
        if([customInfo[chan] length])return customInfo[chan];
    }
    return @"";
}

- (void) setCustomInfo:(short)chan string:(NSString*)aString
{
    if([self channelInBounds:chan]){
        if([aString length]==0)aString=@"";
        [customInfo[chan] autorelease];
        customInfo[chan] = [aString copy];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardCustomInfoChanged object:self];
    }
}
- (int) target:(short)chan
{
	if([self channelInBounds:chan])return target[chan];
	else return 0;
}
- (void) setTarget:(short)chan withValue:(int)aValue
{
	if([self channelInBounds:chan]){
        
        [self requestMaxValues:chan];

		if(aValue<0)aValue = -aValue;
		else {
            int theMax = MIN([self supplyVoltageLimit],[self maxVoltage:chan]);
            if(aValue>theMax)aValue = theMax;
        }
		[[[self undoManager] prepareWithInvocationTarget:self] setTarget:chan withValue:target[chan]];
		target[chan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardTargetChanged object:self];
	}
}

- (BOOL) constraintsInPlace
{
    return ([[(ORMPodCrate*)[self crate] hvConstraints] count] != 0) || ([[self hvConstraints] count] !=0);
}

#pragma mark ¥¥¥Hardware Access
- (void) loadAllValues
{
    if(![self constraintsInPlace]){
        [self commitTargetsToHwGoals];
        [self writeRiseTime];
        [self writeMaxCurrents];
        [self writeVoltages];
    }
}

- (void) writeVoltages
{
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		[self writeVoltage:i];
	}
}

- (void) writeMaxCurrents
{
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		[self writeMaxCurrent:i];
	}
}

#pragma mark ¥¥¥Data Taker
- (unsigned long) dataId { return dataId; }

- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:[self className]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORiSegHVCardDecoderForHV",			@"decoder",
								 [NSNumber numberWithLong:dataId],      @"dataId",
								 [NSNumber numberWithBool:YES],         @"variable",
								 [NSNumber numberWithLong:-1],			@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"State"];
    
    return dataDictionary;
}

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setShipRecords:		[decoder decodeBoolForKey:	@"shipRecords"]];
    [self setSelectedChannel:	[decoder decodeIntForKey:	@"selectedChannel"]];
    [self setRiseRate:			[decoder decodeFloatForKey:	@"riseRate"]];
    
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		[self setTarget:i withValue: [decoder decodeIntForKey:		[@"target" stringByAppendingFormat:@"%d",i]]];
		[self setMaxCurrent:i withValue:[decoder decodeFloatForKey: [@"maxCurrent" stringByAppendingFormat:@"%d",i]]];
	}
    
    [lastHistoryPost release];
    lastHistoryPost = [[NSDate date] retain];
    
	[[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
	[encoder encodeBool:shipRecords                 forKey:@"shipRecords"];
	[encoder encodeInt:selectedChannel              forKey:@"selectedChannel"];
    [encoder encodeFloat:riseRate                   forKey:@"riseRate"];
    
	int i;
 	for(i=0;i<[self numberOfChannels];i++){
		[encoder encodeInt:target[i] forKey:[@"target" stringByAppendingFormat:@"%d",i]];
		[encoder encodeFloat:maxCurrent[i] forKey:[@"maxCurrent" stringByAppendingFormat:@"%d",i]];
	}
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[self addCurrentState:objDictionary cIntArray:target forKey:@"targets"];
	[self addCurrentState:objDictionary cFloatArray:maxCurrent forKey:@"maxCurrents"];
    [objDictionary setObject:[NSNumber numberWithFloat:riseRate] forKey:@"riseRate"];
	
    return objDictionary;
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cIntArray:(short*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		[ar addObject:[NSNumber numberWithInt:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cBoolArray:(BOOL*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		[ar addObject:[NSNumber numberWithBool:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cFloatArray:(float*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		[ar addObject:[NSNumber numberWithFloat:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

#pragma mark ¥¥¥Trends
- (ORTimeRate*) voltageHistory:(short)index
{
	return voltageHistory[index];
}

- (ORTimeRate*) currentHistory:(short)index
{
	return currentHistory[index];
}

- (void) shipDataRecords;
{
	if([[ORGlobal sharedGlobal] runInProgress]){
		//get the time(UT!)
		time_t	ut_Time;
		time(&ut_Time);
		
        
        
		int i;
        unsigned long onMask = 0x0;
        for(i=0;i<[self numberOfChannels];i++){
            if([self isOn:i])onMask |= (0x1<<i);
        }
        int n = 5+[self numberOfChannels]*2;

		unsigned long data[n];
		data[0] = dataId | n;
		data[1] = (([self crateNumber] & 0xf) << 20) |
        (([self slot]&0xf)<<16)            |
        (([self numberOfChannels])<<4)     |
        ([self polarity] & 0x1);
        data[2] = onMask;
		data[3] = 0x0; //spare
		data[4] = ut_Time;
		
		union {
			float asFloat;
			unsigned long asLong;
		}theData;
		for(i=0;i<[self numberOfChannels];i++){
			theData.asFloat = [self channel:i readParamAsFloat:@"outputMeasurementSenseVoltage"];
			data[5+i] = theData.asLong;
			
			theData.asFloat = [self channel:i readParamAsFloat:@"outputMeasurementCurrent"];
			data[6+i] = theData.asLong;
		}
        [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification
                                                            object:[NSData dataWithBytes:data length:sizeof(long)*n]];	}
}
#pragma mark ¥¥¥Convenience Methods
- (float) voltage:(short)aChannel
{
	if([self channelInBounds:aChannel]){
		return [self channel:aChannel readParamAsFloat:@"outputMeasurementSenseVoltage"];
	}
	else return 0;
}

- (float) current:(short)aChannel
{
	if([self channelInBounds:aChannel]){
		return [self channel:aChannel readParamAsFloat:@"outputMeasurementCurrent"];
	}
	else return 0;
}

#pragma mark ¥¥¥HW Wizard

- (int) numberOfChannels
{
    return 8; //default... subclasses can override (max 16)
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Turn On"];
    [p setUseValue:NO];
    [p setSetMethod:@selector(turnChannelOn:) getMethod:nil];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Turn Off"];
    [p setUseValue:NO];
    [p setSetMethod:@selector(turnChannelOff:) getMethod:nil];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
    
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clear Events"];
    [p setUseValue:NO];
    [p setSetMethod:@selector(clearEventsChannel:) getMethod:nil];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Target Voltage"];
    [p setFormat:@"##0" upperLimit:6000 lowerLimit:0 stepSize:1 units:[NSString stringWithFormat:@"%cV",[self polarity]?'+':'-']];
    [p setSetMethod:@selector(setTarget:withValue:) getMethod:@selector(target:)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Max Current"];
    [p setFormat:@"##0" upperLimit:1000 lowerLimit:0 stepSize:1 units:@"uA"];
    [p setSetMethod:@selector(setMaxCurrent:withValue:) getMethod:@selector(maxCurrent:)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Ramp Rate"];
    [p setFormat:@"##0" upperLimit:500 lowerLimit:2 stepSize:1 units:[NSString stringWithFormat:@"%cV/s",[self polarity]?'+':'-']];
    [p setSetMethod:@selector(setRiseRate:) getMethod:@selector(riseRate)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Load & Ramp"];
    [p setSetMethodSelector:@selector(loadAllValues)];
    [a addObject:p];
    
    return a;
}



- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:@"Target Voltage"])return [[cardDictionary objectForKey:@"targets"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Max Current"]) return [cardDictionary objectForKey:@"maxCurrents"];
    else if([param isEqualToString:@"Ramp Rate"]) return [cardDictionary objectForKey:@"riseRate"];
    else return nil;
}
- (NSArray*) wizardSelections
{
    return nil; //subclasses MUST override
}
#pragma mark ¥¥¥Constraints
- (void) addHvConstraint:(NSString*)aName reason:(NSString*)aReason
{
	if(!hvConstraints)hvConstraints = [[NSMutableDictionary dictionary] retain];
    if(![hvConstraints objectForKey:aName]){
        [hvConstraints setObject:aReason forKey:aName];
        [self setUpImage];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardConstraintsChanged object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCrateConstraintsChanged object:self];
        NSLogColor([NSColor redColor],@"%@: HV constraint added: %@ -- %@\n",[self fullID],aName,aReason);
    }
}
- (void) removeHvConstraint:(NSString*)aName
{
    if([hvConstraints objectForKey:aName]){
        [hvConstraints removeObjectForKey:aName];
        [self setUpImage];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORiSegHVCardConstraintsChanged object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCrateConstraintsChanged object:self];
        NSLog(@"%@: HV constraint removed: %@\n",[self fullID],aName);
    }
}

- (NSDictionary*)hvConstraints		 { return hvConstraints;}

- (NSString*) constraintReport
{
    NSString* s = [(ORMPodCrate*)[self crate] constraintReport] ;
    for(id aKey in hvConstraints){
        s = [s stringByAppendingFormat:@"%@ : %@\n",aKey,[hvConstraints objectForKey:aKey]];
    }
    return s;
}
@end

@implementation ORiSegHVCard (private)
- (void) postHistoryRecord
{
    int channel;
    NSMutableArray* voltages = [NSMutableArray arrayWithCapacity:[self numberOfChannels]];
    NSMutableArray* currents = [NSMutableArray arrayWithCapacity:[self numberOfChannels]];
    for(channel= 0; channel<[self numberOfChannels]; channel++){
        [voltages addObject:[NSNumber numberWithFloat:[self channel:channel readParamAsFloat:@"outputMeasurementSenseVoltage"]]];
        [currents addObject:[NSNumber numberWithFloat:[self channel:channel readParamAsFloat:@"outputMeasurementCurrent"]*1000000.]];
    }
    
    NSDictionary* historyRecord = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [self fullID],                               @"name",
                                   @"HV",                                       @"title",
                                   [NSNumber numberWithInt:[self crateNumber]], @"crate",
                                   [NSNumber numberWithInt:[self slot]],        @"slot",
                                   voltages,                                    @"voltages",
                                   currents,                                    @"currents",
                                   nil
                                   ];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddHistoryAdcRecord" object:self userInfo:historyRecord];
}
@end
