//
//  ORMPodCModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
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

#pragma mark ¥¥¥Imported Files
#import "ORMPodCModel.h"
#import "ORMPodCrate.h"
#import "ORTaskSequence.h"
#import "ORSNMP.h"
#import "ORiSegHVCard.h"

NSString* ORMPodCModelVerboseChanged		 = @"ORMPodCModelVerboseChanged";
NSString* ORMPodCModelCrateStatusChanged	 = @"ORMPodCModelCrateStatusChanged";
NSString* ORMPodCModelLock					 = @"ORMPodCModelLock";
NSString* ORMPodCPingTask					 = @"ORMPodCPingTask";
NSString* MPodCIPNumberChanged				 = @"MPodCIPNumberChanged";
NSString* ORMPodCModelSystemParamsChanged	 = @"ORMPodCModelSystemParamsChanged";
NSString* MPodPowerFailedNotification		 = @"MPodPowerFailedNotification";
NSString* MPodPowerRestoredNotification		 = @"MPodPowerRestoredNotification";
NSString* ORMPodCQueueCountChanged			 = @"ORMPodCQueueCountChanged";

#define kSNMPWalk 1

@implementation ORMPodCModel

- (void) dealloc
{
	[[ORSNMPQueue queue] cancelAllOperations];
	[connectionHistory release];
    [IPNumber release];
    [parameterDictionary release];
	
	@try {
        [[ORSNMPQueue queue] removeObserver:self forKeyPath:@"operationCount"];
    }
    @catch (NSException* e){
        
    }
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) wakeUp
{
    firstPowerCheck = YES;
    if([self aWake])return;
    [super wakeUp];
	[[ORSNMPQueue queue] addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
	[self pollHardwareAfterDelay];
}

- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[ORSNMPQueue queue] removeObserver:self forKeyPath:@"operationCount"];
	[[ORSNMPQueue queue] cancelAllOperations];
	[super sleep];
}
- (NSString*) helpURL
{
	return @"MPod/MPodC.html";
}
#pragma mark ¥¥¥Initialization
- (void) makeMainController
{
    [self linkToController:@"ORMPodCController"];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MPodC"]];
}

- (void) setGuardian:(id)aGuardian
{
    if(aGuardian){
		if([aGuardian adapter] == nil){
			[aGuardian setAdapter:self];			
		}
	}
    else [[self guardian] setAdapter:nil];
	
    [super setGuardian:aGuardian];
}

- (void) initConnectionHistory
{
	ipNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.%d.IPNumberIndex",[self className],[self slot]]];
	if(!connectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey: [NSString stringWithFormat:@"orca.%@.%d.ConnectionHistory",[self className],[self slot]]];
		connectionHistory = [his mutableCopy];
	}
	if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
}

#pragma mark ***Accessors
- (BOOL) verbose
{
    return verbose;
}

- (void) setVerbose:(BOOL)aVerbose
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVerbose:verbose];
    verbose = aVerbose;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCModelVerboseChanged object:self];
}

- (BOOL) power
{
    NSDictionary* systemParams = [parameterDictionary objectForKey:@"0"];
    return[[[systemParams objectForKey:@"sysMainSwitch"] objectForKey:@"Value"] boolValue];

}

- (id) systemParam:(NSString*)name
{
    NSDictionary* systemParams = [parameterDictionary objectForKey:@"0"];
    id theValue =  [[systemParams objectForKey:name] objectForKey:@"Value"];
	if(theValue)return theValue;
    else return @"";
}

- (int) systemParamAsInt:(NSString*)name
{
    NSDictionary* systemParams = [parameterDictionary objectForKey:@"0"];
    return  [[[systemParams objectForKey:name] objectForKey:@"Value"] intValue];
}

- (void) clearHistory
{
	[connectionHistory release];
	connectionHistory = nil;
	
	[self setIPNumber:[self IPNumber]];
}

- (NSUInteger) connectionHistoryCount
{
	return [connectionHistory count];
}

- (id) connectionHistoryItem:(NSUInteger)index
{
	if(connectionHistory && index<[connectionHistory count])return [connectionHistory objectAtIndex:index];
	else return nil;
}

- (NSUInteger) ipNumberIndex
{
	return ipNumberIndex;
}

- (NSString*) IPNumber
{
	if(!IPNumber)return @"";
    return IPNumber;
}

- (void) setIPNumber:(NSString*)aIPNumber
{
	if([aIPNumber length]){
		
		[[[self undoManager] prepareWithInvocationTarget:self] setIPNumber:IPNumber];
		
		[IPNumber autorelease];
		IPNumber = [aIPNumber copy];    
		
		if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
		if(![connectionHistory containsObject:IPNumber]){
			[connectionHistory addObject:IPNumber];
		}
		ipNumberIndex = [connectionHistory indexOfObject:aIPNumber];
		
		[[NSUserDefaults standardUserDefaults] setObject:connectionHistory forKey:[NSString stringWithFormat:@"orca.%@.%d.ConnectionHistory",[self className],[self slot]]];
		[[NSUserDefaults standardUserDefaults] setInteger:ipNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.%d.IPNumberIndex",[self className],[self slot]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:MPodCIPNumberChanged object:self];
	}
}

- (void) pollHardware
{
    if([IPNumber length]){		
		ORSNMPShellOp* anOp = [[ORSNMPShellOp alloc] 
							   initWithCmd:@"/usr/bin/snmpwalk" 
							   arguments:[NSArray arrayWithObjects:@"-v2c", @"-m", @"+WIENER-CRATE-MIB", @"-c", @"public", IPNumber, @"crate",nil] 
							   delegate:self 
							   tag:kSNMPWalk];
		[[ORSNMPQueue queue] addOperation:anOp];
		[anOp release];
    }
}

- (void) pollHardwareAfterDelay
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:5];
}

- (void) setSNMP:(int)aTag result:(NSString*)theResult
{
	switch(aTag){
		case kSNMPWalk:
			[self decodeWalk:theResult];
			break;
	}
}
- (void) decodeWalk:(NSString*)theWalk
{
	ORSNMPWalkDecodeOp* anOp = [[ORSNMPWalkDecodeOp alloc] 
								initWithWalk:theWalk 
								delegate:self ];
	[[ORSNMPQueue queue] addOperation:anOp];
	[anOp release];
}

- (NSDictionary*) parameterDictionary
{
	return parameterDictionary;
}

- (void) setParameterDictionary:(NSDictionary*)aParameterDictionary
{
    @try {
        [aParameterDictionary retain];
        [parameterDictionary release];
        parameterDictionary = aParameterDictionary;
            
        //pass the info to each of the cards. They will keep a copy of their values
        NSArray* cards = [[self crate] orcaObjects];
        for(id aCard in cards){
            if(aCard == self)continue;
            if([aCard isKindOfClass:NSClassFromString(@"ORiSegHVCard")]){
                [(ORiSegHVCard*)aCard setRdParamsFrom:parameterDictionary];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCModelSystemParamsChanged object:self];
    }
    @catch(NSException* e){
        
    }
}

- (void) togglePower
{
    BOOL powerState = [self power];
    NSLog(@"MPod (%d) main power switched %@\n",[self uniqueIdNumber],!powerState?@"ON":@"OFF");
	NSString* cmd = [NSString stringWithFormat:@"sysMainSwitch.0 i %d",!powerState];
	[[self adapter] writeValue:cmd target:self selector:@selector(processSystemResponseArray:)];
    if(!powerState){
        [self writeMaxTemperature];
        [self writeMaxTerminalVoltage];
    }
}

#pragma mark ¥¥¥Hardware Access
- (void)  checkCratePower
{
	NSString* noteName;
	BOOL currentPower = [self power];
	if(firstPowerCheck || (currentPower != oldPower)){
        firstPowerCheck = NO;
        if(doNotSkipPowerCheck){
			NSLog(@"MPod (%d) power changed state from %@ to %@\n",[self uniqueIdNumber],
              oldPower?@"ON":@"OFF",currentPower?@"ON":@"OFF");
		}
		doNotSkipPowerCheck = YES;
		if([self power]) noteName = MPodPowerRestoredNotification;
		else			 noteName = MPodPowerFailedNotification;
		[[NSNotificationCenter defaultCenter] postNotificationName:noteName object:self];
	}
	oldPower = currentPower;
}

- (void) writeMaxTerminalVoltage
{
    [[self adapter] writeValue:@"outputConfigMaxTerminalVoltage F 5000.0" target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
}

- (void) writeMaxTemperature
{
    [[self adapter] writeValue:@"outputSupervisionMaxTemperature i 5000" target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
}

- (void) writeValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector priority:(NSOperationQueuePriority)aPriority
{
    [self writeValues:[NSArray arrayWithObject:aCmd] target:aTarget selector:aSelector priority:aPriority];
}

- (void) writeValue:(NSString*)aCmd target:(id)aTarget selector:(SEL)aSelector
{
	[self writeValues:[NSArray arrayWithObject:aCmd] target:aTarget selector:aSelector priority:NSOperationQueuePriorityLow];
}

- (void) writeValues:(NSArray*)cmds target:(id)aTarget selector:(SEL)aSelector priority:(NSOperationQueuePriority)aPriority
{	 
	ORSNMPWriteOperation* aWriteOP = [[ORSNMPWriteOperation alloc] initWithDelegate:self];	
	for(id aCmd in cmds){
		
		aWriteOP.mib		= @"WIENER-CRATE-MIB";
		aWriteOP.target		= aTarget;
		aWriteOP.ipNumber	= IPNumber;
		aWriteOP.selector	= aSelector;
		aWriteOP.cmds		= [NSArray arrayWithObject:aCmd];
		aWriteOP.verbose	= verbose;
		aWriteOP.queuePriority	= aPriority;
		[ORSNMPQueue addOperation:aWriteOP];
		[aWriteOP release];
	}
}

- (void) callBackToTarget:(id)aTarget selector:(SEL)aSelector userInfo:(NSDictionary*)userInfo
{
	//just a fancy way to sync something back in the target with activities in the queue
	ORSNMPCallBackOperation* anOP = [[ORSNMPCallBackOperation alloc] initWithDelegate:self];
	anOP.target		= aTarget;
	anOP.userInfo	= userInfo;
	anOP.selector	= aSelector;
	anOP.verbose	= verbose;
	[ORSNMPQueue addOperation:anOP];
	[anOP release];
	
}

#pragma mark ¥¥¥Tasks
- (void) taskFinished:(ORPingTask*)aTask
{
	if(aTask == pingTask){
		[pingTask release];
		pingTask = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCPingTask object:self];
	}
}

- (void) ping
{
	if(!pingTask){
        
        pingTask = [[ORPingTask pingTaskWithDelegate:self] retain];
        
        pingTask.launchPath= @"/sbin/ping";
        pingTask.arguments = [NSArray arrayWithObjects:@"-c",@"5",@"-t",@"10",@"-q",IPNumber,nil];
        
        pingTask.verbose = YES;
        pingTask.textToDelegate = YES;
        [pingTask ping];
        
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCPingTask object:self];
	}
}

- (BOOL) pingTaskRunning
{
	return pingTask != nil;
}

- (void) taskData:(NSDictionary*)taskData
{
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
	NSOperationQueue* queue = [[ORSNMPQueue sharedSNMPQueue] queue];
    if (object == queue && [keyPath isEqual:@"operationCount"]) {
		NSNumber* n = [NSNumber numberWithInt:[[[ORSNMPQueue queue] operations] count]];
		[self performSelectorOnMainThread:@selector(setQueCount:) withObject:n waitUntilDone:NO];
		if ([[queue operations] count] == 0) {
			[self performSelectorOnMainThread:@selector(pollHardwareAfterDelay) withObject:nil waitUntilDone:NO];
		}
	}
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) setQueCount:(NSNumber*)n
{
	queueCount = [n intValue];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORMPodCQueueCountChanged object:self];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self initConnectionHistory];
	[self setIPNumber:		[decoder decodeObjectForKey:@"IPNumber"]];
	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
 	[encoder encodeObject:IPNumber		forKey:@"IPNumber"];
}

@end


@implementation ORSNMPWalkDecodeOp

- (id) initWithWalk:(NSString*)aWalk delegate:(id)aDelegate;
{
    self = [super init];
	delegate = aDelegate;
	theWalk = [aWalk copy];
    return self;
}

- (void) dealloc
{        	
    delegate      = nil; 
	[theWalk release];
	theWalk = nil;
	[dictionaryFromWalk release];
	dictionaryFromWalk = nil;
    [super dealloc];
}

- (void) main
{
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
    if(![self isCancelled]){
        NSArray* allLines = [theWalk componentsSeparatedByString:@"\n"];
        for(id aLine in allLines){
            NSRange headerRange = [aLine rangeOfString:@"WIENER-CRATE-MIB::"];
            if(headerRange.location!= NSNotFound){
                NSString* s = [aLine substringFromIndex:headerRange.length];
                [self decodeValueArray:[s componentsSeparatedByString:@"="]];
            }   
        }
        
        [delegate performSelectorOnMainThread:@selector(setParameterDictionary:) withObject:dictionaryFromWalk waitUntilDone:YES];
    }
    [thePool release];
}

- (void)decodeValueArray:(NSArray*)parts
{
	if([parts count] == 2){
		[self decode:[parts objectAtIndex:0] value:[parts objectAtIndex:1]];
	}
}

- (void) decode:(NSString*)aName value:(NSString*)aValue
{
	if([aName hasPrefix:@"outputNumber"])return; //ignore
	if([aName hasPrefix:@"outputIndex"])return; //ignore
	if([aName hasPrefix:@"outputName"])return; //ignore
	if([aName hasPrefix:@"outputGroup"])return; //ignore
	if([aName hasPrefix:@"moduleIndex"])return; //ignore
	if([aName hasPrefix:@"groupsNumber"])return; //ignore
	if([aName hasPrefix:@"groupsIndex"])return; //ignore
	if([aName hasPrefix:@"groupsSwitch"])return; //ignore
	if([aName hasPrefix:@"moduleNumber"])return; //ignore
	if([aName hasPrefix:@"psAuxiliaryNumber"])return; //ignore
	if([aName hasPrefix:@"psAuxiliaryIndex"])return; //ignore
	
	if(!dictionaryFromWalk)dictionaryFromWalk = [[NSMutableDictionary dictionary] retain];
	
	NSArray* nameParts = [aName componentsSeparatedByString:@"."];
	if([nameParts count]==2){
		
		id channelKey = [[nameParts objectAtIndex:1]trimSpacesFromEnds];
		id parameterName = [nameParts objectAtIndex:0];
		
		id theDecodedValue = [self decodeValue:aValue name:parameterName];
		if(theDecodedValue){
			
			NSMutableDictionary* channelDictionary = [dictionaryFromWalk objectForKey:channelKey];
			if(!channelDictionary){
				channelDictionary = [NSMutableDictionary dictionary];
				[dictionaryFromWalk setObject:channelDictionary forKey:channelKey];
				if([channelKey hasPrefix:@"u"]){
					int chanId = [[channelKey substringFromIndex:1] intValue]%100;
					int slot = [[channelKey substringFromIndex:1] intValue]/100 + 1;
					
					[channelDictionary setObject:[NSString stringWithFormat:@"%d",chanId] forKey:@"Channel"];
					[channelDictionary setObject:[NSString stringWithFormat:@"%d",slot] forKey:@"Slot"];
				}
                else if([channelKey hasPrefix:@"ma"]){
                    int moduleId =[[channelKey substringFromIndex: 2] intValue];
                    [channelDictionary setObject:[NSString stringWithFormat:@"ma%d",moduleId] forKey:@"ModuleSlot"];
                }
				[channelDictionary setObject:channelKey forKey:@"ChannelSlotId"];
			}
			
			[channelDictionary setObject:theDecodedValue forKey:parameterName];
		}
	}
}

- (NSDictionary*) decodeValue:(NSString*)aValue name:(NSString*)aName
{
	if([aValue hasPrefix:@" Opaque: Float:"]){
		return [self decodeFloat:[aValue substringFromIndex:15]];
	}
	else if([aValue hasPrefix:@" INTEGER:"]){
		return [self decodeInteger:[aValue substringFromIndex:9]];
	}
	else if([aValue hasPrefix:@" BITS:"]){
		return [self decodeBits:[aValue substringFromIndex:6] name:aName];
	}
	else if([aValue hasPrefix:@" STRING:"]){
		return [self decodeString:[aValue substringFromIndex:8] name:aName];
	}
    else if([aValue hasPrefix:@" IpAddress:"]){
        return [self decodeString:[aValue substringFromIndex:11] name:aName];
    }
	else if([aValue hasPrefix:@" Hex-STRING:"]){
		return [self decodeString:[aValue substringFromIndex:12] name:aName];
	}
	
	
	
	else return nil;
}

- (NSDictionary*) decodeFloat:(NSString*)aValue
{
	NSArray*  parts  = [[aValue trimSpacesFromEnds] componentsSeparatedByString:@" "];
    if([parts count]!=0){
        NSString* number = [parts objectAtIndex:0];
        NSString* units = @"";
        if([parts count]==2){
            units = [parts objectAtIndex:1];
            if([units hasSuffix:@"C"])units = [units substringFromIndex:[units length]-1];
            
            if([units isEqualToString:@"mV"]){
                float theValue = [number floatValue];
                theValue = theValue/1000.;
                number = [NSString stringWithFormat:@"%f",theValue];
                units    = @"V";
            }
            else if([units isEqualToString:@"nA"]){
                float theValue = [number floatValue];
                theValue = theValue/1000.;
                number = [NSString stringWithFormat:@"%f",theValue];
                units    = @"uA";
            }
            else if([units isEqualToString:@"mA"]){
                float theValue = [number floatValue];
                theValue = theValue*1000.;
                number = [NSString stringWithFormat:@"%f",theValue];
                units    = @"uA";
            }
        }
        return [NSDictionary dictionaryWithObjectsAndKeys:units,@"Units",number,@"Value", nil];
		
	}
	else return nil;
}

- (NSDictionary*) decodeString:(NSString*)aValue  name:(NSString*)aName;
{
	return [NSDictionary dictionaryWithObject:[aValue trimSpacesFromEnds] forKey:@"Value"];
}

- (NSDictionary*) decodeInteger:(NSString*)aValue
{
	aValue = [aValue trimSpacesFromEnds];
    if([aValue hasPrefix:@"on"])		return [NSDictionary dictionaryWithObject:@"1" forKey:@"Value"];
	else if([aValue hasPrefix:@"off"])	return [NSDictionary dictionaryWithObject:@"0" forKey:@"Value"];
	else {
		NSArray* parts = [aValue componentsSeparatedByString:@" "];
		if([parts count]==2){
            return [NSDictionary dictionaryWithObjectsAndKeys:[parts objectAtIndex:0],@"Value",[parts objectAtIndex:1],@"Units", nil];
		}
		else {
            return [NSDictionary dictionaryWithObject:aValue forKey:@"Value"];
		}
	}
    return nil;
}

- (NSDictionary*) decodeBits:(NSString*)aValue name:(NSString*)aName
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	aValue = [aValue trimSpacesFromEnds];
	unsigned long bitMask = 0;
	NSArray* parts = [aValue componentsSeparatedByString:@" "];
	NSMutableArray* descriptionArray = [NSMutableArray array];
	for(NSString* aPart in parts){
		NSRange parRange = [aPart rangeOfString:@"("];
		if(parRange.location != NSNotFound){
			int setBitLocation = [[aPart substringFromIndex:parRange.location+1]intValue];
			bitMask |= (0x1L << setBitLocation);
			[descriptionArray addObject:[aPart substringToIndex:parRange.location]];
		}
	}
	
	[dict setObject:[NSString stringWithFormat:@"%lu",bitMask] forKey:@"Value"];
	if([descriptionArray count])[dict setObject:descriptionArray forKey:@"Names"];
	return dict;
}

@end



