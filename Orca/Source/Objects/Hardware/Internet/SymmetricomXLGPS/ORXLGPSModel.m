//
//  ORXLGPSModel.m
//  Orca
//
//  Created by Jarek Kaspar on November 2, 2010.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORXLGPSModel.h"
#import "NetSocket.h"
#import "ORTaskSequence.h"

#pragma mark •••Definitions
#define kGPSPort 23

NSString* ORXLGPSModelLock			= @"ORXLGPSModelLock";
NSString* ORXLGPSIPNumberChanged		= @"ORXLGPSIPNumberChanged";
NSString* ORXLGPSModelUserNameChanged		= @"ORXLGPSModelUserNameChanged";
NSString* ORXLGPSModelPasswordChanged		= @"ORXLGPSModelPasswordChanged";
NSString* ORXLGPSModelTimeOutChanged		= @"ORXLGPSModelTimeOutChanged";
NSString* ORXLGPSModelOpsRunningChanged		= @"ORXLGPSModelOpsRunningChanged";
NSString* ORXLGPSModelCommandChanged		= @"ORXLGPSModelCommandChanged";
NSString* ORXLGPSModelPpoCommandChanged		= @"ORXLGPSModelPpoCommandChanged";
NSString* ORXLGPSModelPpsCommandChanged		= @"ORXLGPSModelPpsCommandChanged";
NSString* ORXLGPSModelIsPpoChanged		= @"ORXLGPSModelIsPpoChanged";
NSString* ORXLGPSModelPpoTimeChanged		= @"ORXLGPSModelPpoTimeChanged";
NSString* ORXLGPSModelPpoTimeOffsetChanged	= @"ORXLGPSModelPpoTimeOffsetChanged";
NSString* ORXLGPSModelPpoPulseWidthChanged	= @"ORXLGPSModelPpoPulseWidthChanged";
NSString* ORXLGPSModelPpoPulsePeriodChanged	= @"ORXLGPSModelPpoPulsePeriodChanged";
NSString* ORXLGPSModelPpoRepeatsChanged		= @"ORXLGPSModelPpoRepeatsChanged";

@interface ORXLGPSModel (private)
- (void) login:(NSNumber*)phase;
- (void) gpsTimeOut;
- (void) logout:(NSNumber*)phase;
- (void) log:(id)aObject;
- (void) kill;
- (void) doSend:(NSString*)aCommand;
- (void) testFinished;
- (void) doReport:(NSNumber*)phase;
- (void) reportFinished;
- (void) doIsLocked:(NSNumber*)phase;
- (void) isLockedFinished;
- (void) doTime:(NSNumber*)phase;
- (void) timeFinished;
@end

@implementation ORXLGPSModel
@synthesize IPNumberIndex, isConnected, isLoggedIn, socket, dateToDisconnect, processDict, postLoginCmd, postLoginSel, gpsTimer;

#pragma mark •••Initialization
- (id) init
{
	self = [super init];
	userName = @"operator";	//default from the public user guide
	password = @"janus";	//default from the public user guide
	IPNumber = @"";
	timeOut = 0;
	return self;
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"XLGPSIcon"]];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[connectionHistory release];
	[IPNumber release];
	[userName release];
	[password release];
	timeOut = 0;
	[socket setDelegate:nil];
	[socket release];
	[gpsInBuffer release];
	[command release];
	[ppoCommand release];
	[ppsCommand release];
    [processDict release];
    [postLoginCmd release];
    [gpsTimer release];
    [dateToDisconnect release];
    [postLoginSel release];
	[super dealloc];
}

- (void) wakeUp 
{
	[super wakeUp];
}

- (void) sleep 
{
	//disconnect?
	[super sleep];
}	

- (void) makeMainController
{
	[self linkToController:@"ORXLGPSController"];
}

- (void) initConnectionHistory
{
	IPNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.IPNumberIndex",[self className]]];
	if(!connectionHistory){
		NSArray* his = [[NSUserDefaults standardUserDefaults] objectForKey: [NSString stringWithFormat:@"orca.%@.ConnectionHistory",[self className]]];
		connectionHistory = [his mutableCopy];
	}
	if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
}

#pragma mark •••Accessors
- (void) clearConnectionHistory
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
		IPNumberIndex = [connectionHistory indexOfObject:aIPNumber];
		
		[[NSUserDefaults standardUserDefaults] setObject:connectionHistory forKey:[NSString stringWithFormat:@"orca.%@.ConnectionHistory",[self className]]];
		[[NSUserDefaults standardUserDefaults] setInteger:IPNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.IPNumberIndex",[self className]]];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSIPNumberChanged object:self];
	}
}

- (NSString*) userName
{
	return userName;
}

- (void) setUserName:(NSString*)aUserName
{
	[[[self undoManager] prepareWithInvocationTarget:self] setUserName:userName];
	
	[userName autorelease];
	userName = [aUserName copy];    
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelPasswordChanged object:self];
}

- (NSString*) password
{
	return password;
}

- (void) setPassword:(NSString*)aPassword
{
	[[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
	
	[password autorelease];
	password = [aPassword copy];    
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelPasswordChanged object:self];
}

- (NSUInteger) timeOut
{
	return timeOut;
}

- (void) setTimeOut:(NSUInteger)aTimeOut
{
	timeOut = aTimeOut;
	if (isConnected) {
		[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:timeOut]];
		[self performSelector:@selector(disconnect) withObject:nil afterDelay:0.1];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelTimeOutChanged object:self];
}

- (NSString*) command
{
	return command;
}

- (void) setCommand:(NSString*)aCommand
{
	[[[self undoManager] prepareWithInvocationTarget:self] setCommand:command];
	
	[command autorelease];
	command = [aCommand copy];    
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelCommandChanged object:self];
}

- (NSString*) ppoCommand
{
	return ppoCommand;
}

- (void) setPpoCommand:(NSString*)aPpoCommand
{
	[[[self undoManager] prepareWithInvocationTarget:self] setPpoCommand:ppoCommand];
	
	[ppoCommand autorelease];
	ppoCommand = [aPpoCommand copy];    
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelPpoCommandChanged object:self];
}

- (NSDate*) ppoTime
{
	return ppoTime;
}

- (void) setPpoTime:(NSDate*)aPpoTime
{
	[[[self undoManager] prepareWithInvocationTarget:self] setPpoTime:ppoTime];
	
	[ppoTime autorelease];
	ppoTime = [aPpoTime retain];    
	[self updatePpoCommand];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelPpoTimeChanged object:self];
}

- (NSUInteger) ppoTimeOffset
{
	return ppoTimeOffset;
}

- (void) setPpoTimeOffset:(NSUInteger)aPpoTimeOffset
{
	[[[self undoManager] prepareWithInvocationTarget:self] setPpoTimeOffset:ppoTimeOffset];
	
	ppoTimeOffset = aPpoTimeOffset;
	[self updatePpoCommand];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelPpoTimeOffsetChanged object:self];
}

- (NSUInteger) ppoPulseWidth
{
	return ppoPulseWidth;
}

- (void) setPpoPulseWidth:(NSUInteger)aPpoPulseWidth
{
	[[[self undoManager] prepareWithInvocationTarget:self] setPpoPulseWidth:ppoPulseWidth];
	
	ppoPulseWidth = aPpoPulseWidth;
	[self updatePpoCommand];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelPpoPulseWidthChanged object:self];
}

- (NSUInteger) ppoPulsePeriod
{
	return ppoPulsePeriod;
}

- (void) setPpoPulsePeriod:(NSUInteger)aPpoPulsePeriod
{
	[[[self undoManager] prepareWithInvocationTarget:self] setPpoPulsePeriod:ppoPulsePeriod];
	
	ppoPulsePeriod = aPpoPulsePeriod;
	[self updatePpoCommand];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelPpoPulsePeriodChanged object:self];
}

- (BOOL) ppoRepeats
{
	return ppoRepeats;
}

- (void) setPpoRepeats:(BOOL)aPpoRepeats
{
	[[[self undoManager] prepareWithInvocationTarget:self] setPpoRepeats:aPpoRepeats];
	
	ppoRepeats = aPpoRepeats;
	[self updatePpoCommand];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelPpoRepeatsChanged object:self];
}

- (void) updatePpoCommand
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
#else
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
#endif
	NSDateFormatter* frmt = [[[NSDateFormatter alloc] init] autorelease];
	NSDate* ppoDate = [[[NSDate alloc] initWithTimeInterval:(ppoTimeOffset - [[NSTimeZone systemTimeZone] secondsFromGMT]) sinceDate:ppoTime] autorelease];
	[frmt setDateFormat:@"D"];
	int day = [[frmt stringFromDate:ppoDate] intValue];

#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSDateComponents *componentsPpo = [gregorian components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)
						       fromDate:ppoDate];
#else 
	NSDateComponents *componentsPpo = [gregorian components:(NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit)
                                                   fromDate:ppoDate];
#endif
	NSString* time = [NSString stringWithFormat:@"%03d:%02d:%02d:%02d", day, [componentsPpo hour], [componentsPpo minute], [componentsPpo second]];

	if ([self ppoRepeats]) {
		NSRange ppoMask = {0, 12};
		switch ([self ppoPulsePeriod]) {
			case 1:
				time = [time stringByReplacingCharactersInRange:ppoMask withString:@"XXX:XX:XX:XX"];
				break;
			case 10:
				time = [time stringByReplacingCharactersInRange:ppoMask withString:@"XXX:XX:XX:X0"];
				break;
			case 60:
				time = [time stringByReplacingCharactersInRange:ppoMask withString:@"XXX:XX:XX:00"];
				break;
			case 600:
				time = [time stringByReplacingCharactersInRange:ppoMask withString:@"XXX:XX:X0:00"];
				break;
			case 3600:
				ppoMask.length = 6;
				time = [time stringByReplacingCharactersInRange:ppoMask withString:@"XXX:XX"];
				break;
			case 86400:
				ppoMask.length = 3;
				time = [time stringByReplacingCharactersInRange:ppoMask withString:@"XXX"];
				break;
			default:
				break;
		}
	}
	
	NSString* cmd = [NSString stringWithFormat:@"PPO %@.000000 %@.%06d", time, time, [self ppoPulseWidth]];
	[self setPpoCommand:cmd];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelPpoCommandChanged object:self];
}

- (NSString*) ppsCommand
{
	return ppsCommand;
}

- (void) setPpsCommand:(NSString*)aPpsCommand
{
	[[[self undoManager] prepareWithInvocationTarget:self] setPpsCommand:ppsCommand];
	
	[ppsCommand autorelease];
	ppsCommand = [aPpsCommand copy];    
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelPpsCommandChanged object:self];
}

- (BOOL) isPpo
{
	return isPpo;
}

- (void) setIsPpo:(BOOL)aIsPpo
{
	[[[self undoManager] prepareWithInvocationTarget:self] setIsPpo:isPpo];
	
	isPpo = aIsPpo;    
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelIsPpoChanged object:self];
}

- (BOOL) gpsOpsRunningForKey:(id)aKey
{
	return [[gpsOpsRunning objectForKey:aKey] boolValue];
}

- (void) setGpsOpsRunning:(BOOL)aGpsOpsRunning forKey:(id)aKey
{
	[[[self undoManager] prepareWithInvocationTarget:self] setGpsOpsRunning:NO forKey:aKey];
	[gpsOpsRunning setObject:[NSNumber numberWithBool:aGpsOpsRunning] forKey:aKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORXLGPSModelOpsRunningChanged object:self];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	[self initConnectionHistory];
	
	[self setUserName:	[decoder decodeObjectForKey:@"userName"]];
	[self setPassword:	[decoder decodeObjectForKey:@"password"]];
	[self setIPNumber:	[decoder decodeObjectForKey:@"IPNumber"]];
	[self setTimeOut:	[decoder decodeIntForKey:@"timeOut"]];
	[self setCommand:	[decoder decodeObjectForKey:@"command"]];
	[self setPpoCommand:	[decoder decodeObjectForKey:@"ppoCommand"]];
	[self setPpsCommand:	[decoder decodeObjectForKey:@"ppsCommand"]];
	[self setIsPpo:		[decoder decodeBoolForKey:@"isPpo"]];
	[self setPpoTime:	[decoder decodeObjectForKey:@"ppoTime"]];
	[self setPpoTimeOffset:	[decoder decodeIntForKey:@"ppoTimeOffset"]];	
	[self setPpoPulseWidth:	[decoder decodeIntForKey:@"ppoPulseWidth"]];	
	[self setPpoPulsePeriod:[decoder decodeIntForKey:@"ppoPulsePeriod"]];
	[self setPpoRepeats:	[decoder decodeBoolForKey:@"ppoRepeats"]];
	
	if (![self ppoTime]) [self setPpoTime:[NSDate date]];
	if (![self ppoPulseWidth]) [self setPpoPulseWidth:1];
	if (![self ppoPulsePeriod]) [self setPpoPulsePeriod:1];
	if (!gpsOpsRunning) gpsOpsRunning = [[NSMutableDictionary alloc] init];

	[[self undoManager] enableUndoRegistration];
	return self;	
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:userName		forKey:@"userName"];
	[encoder encodeObject:password		forKey:@"password"];
	[encoder encodeObject:IPNumber		forKey:@"IPNumber"];
	[encoder encodeInt:timeOut		forKey:@"timeOut"];	
	[encoder encodeObject:command		forKey:@"command"];
	[encoder encodeObject:ppoCommand	forKey:@"ppoCommand"];
	[encoder encodeObject:ppsCommand	forKey:@"ppsCommand"];
	[encoder encodeObject:ppoTime		forKey:@"ppoTime"];
	[encoder encodeInt:ppoTimeOffset	forKey:@"ppoTimeOffset"];
	[encoder encodeInt:ppoPulseWidth	forKey:@"ppoPulseWidth"];
	[encoder encodeInt:ppoPulsePeriod	forKey:@"ppoPulsePeriod"];
	[encoder encodeBool:ppoRepeats		forKey:@"ppoRepeats"];
	[encoder encodeBool:isPpo		forKey:@"isPpo"];
}

#pragma mark •••Hardware Access
// GPS allows single "telnet" connection only, but connecting requires parsing the text messages from the GPS unit
// so we control the connection by short timeOut (2 sec), and automatically disconnect as soon as possible.
// the timeOut hardwired in the GPS unit is 15 minutes. If we fail to disconnect, nobody will be able to use GPS for 15 minutes.
// to disconnect means to send the "quit" command. Dropping the connection is not enough.
// outgoing commands should be separated by "\n", incoming messages are separated by "\n\r"
- (void) connect
{
	if(![IPNumber length]){
		NSLog(@"GPS connection failed, no IP number\n");
		return;
	}
	
	if(!isConnected){
		[self setIsLoggedIn:NO];
		if (gpsInBuffer) {
			[gpsInBuffer release]; gpsInBuffer = nil;
		}
		gpsInBuffer = [[NSMutableString alloc] init];
		if (processDict) {
			[processDict release]; processDict = nil;
		}
		processDict = [[NSMutableDictionary alloc] init];
		[processDict setObject:[NSString stringWithFormat:@"login:"] forKey:@"selector"];
		[processDict setObject:[NSNumber numberWithInt:0] forKey:@"phase"];
		
		[self setSocket:[NetSocket netsocketConnectedToHost:IPNumber port:kGPSPort]];
		[socket scheduleOnCurrentRunLoop];
		[socket setDelegate:self];
		//[self setIsConnected:[socket isConnected]];
	}
	else {
		NSLog(@"GPS error: only single connection allowed\n");
		return;
	}	
}

- (void) disconnect
{
	if (gpsTimer) [gpsTimer invalidate];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disconnect) object:nil];
	NSDate* now = [NSDate date];
	
	if ([now compare:dateToDisconnect] != NSOrderedAscending) {
		if (isConnected) {
			//send quit and schedule kill
			[self logout:[NSNumber numberWithInt:0]];
			[self performSelector:@selector(kill) withObject:nil afterDelay:0.2];
			NSLog(@"GPS disconnecting.\n");
		}
		else
			NSLog(@"GPS warning: request to disconnect arrived when disconnected.\n");
	}
	else {
		[self performSelector:@selector(disconnect) withObject:nil afterDelay:[dateToDisconnect timeIntervalSinceNow] + 0.1];
	}
}

- (void) test
{
	[self setGpsOpsRunning:YES forKey:@"telnetTest"];
	[self setPostLoginSel:@"testFinished"];
	[self connect];

	[self performSelector:@selector(testFinished) withObject:nil afterDelay:1.0];
}

- (void) ping
{
	if(!pingTask){
		[self setGpsOpsRunning:YES forKey:@"telnetPing"];

        
        pingTask = [[ORPingTask pingTaskWithDelegate:self] retain];
        
        pingTask.launchPath= @"/sbin/ping";
        pingTask.arguments = [NSArray arrayWithObjects:@"-c",@"5",@"-t",@"10",@"-q",IPNumber,nil];
        
        pingTask.verbose = YES;
        pingTask.textToDelegate = YES;
        [pingTask ping];

 	}
}

- (void) taskFinished:(ORPingTask*)aTask
{
	if(aTask == pingTask){
		[pingTask release];
		pingTask = nil;
		[self setGpsOpsRunning:NO forKey:@"telnetPing"];
	}
}

- (void) send
{
	[self setGpsOpsRunning:YES forKey:@"basicSend"];
	[self doSend:command];
	[self setGpsOpsRunning:NO forKey:@"basicSend"];	
}

- (void) send:(NSString*)aCommand
{
	[self doSend:aCommand];
}

- (NSDate*) time
{
	[self setGpsOpsRunning:YES forKey:@"basicTime"];

	if (timeOut > 0)
		[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:timeOut]];
	
	if (!isConnected) {
		[self setPostLoginSel:nil];
		[self setPostLoginCmd:nil];
		[self connect];
		
		[self setGpsTimer:[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(gpsTimeOut) userInfo:nil repeats:NO]];
		while (![self isLoggedIn] && [gpsTimer isValid]) {
			//NSLog(@"debug isLoggedIn: %@, timer: %@\n", [self isLoggedIn]?@"YES":@"NO", [gpsTimer isValid]?@"YES":@"NO");
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		}
		if ([gpsTimer isValid]) [gpsTimer invalidate];
		[self setGpsTimer:nil];
	}
	
	if (!isConnected || !isLoggedIn) {
		[self setGpsOpsRunning:NO forKey:@"basicTime"];
		return [NSDate distantPast];
	}

	if (isLoggedIn) {
		if (timeOut > 0)
			[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:timeOut]];
		if (postLoginSel) [self setPostLoginSel:nil];
		[processDict removeObjectForKey:@"time"];
		[self doTime:[NSNumber numberWithInt:0]];
		
		//clean UI
		[self performSelector:@selector(timeFinished) withObject:nil afterDelay:2.0];
		
		//wait for the resp or timeout
		[self setGpsTimer:[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(gpsTimeOut) userInfo:nil repeats:NO]];
		while ([self gpsOpsRunningForKey:@"basicTime"] && [gpsTimer isValid]) {
			//NSLog(@"debug isConnected: %@, timer: %@\n", [self isConnected]?@"YES":@"NO", [gpsTimer isValid]?@"YES":@"NO");
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
		}
		if ([gpsTimer isValid]) [gpsTimer invalidate];
		[self setGpsTimer:nil];
		
		//if ([processDict objectForKey:@"time"]) return [processDict objectForKey:@"time"];
		//return [NSDate distantFuture];
		return [processDict objectForKey:@"time"];
	}
	
	return [NSDate distantPast];
}

- (BOOL) isLocked;
{
	[self setGpsOpsRunning:YES forKey:@"basicIsLocked"];
	
	if (timeOut > 0)
		[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:timeOut]];
	
	if (!isConnected) {
		[self setPostLoginSel:nil];
		[self setPostLoginCmd:nil];
		[self connect];

		[self setGpsTimer:[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(gpsTimeOut) userInfo:nil repeats:NO]];
		while (![self isLoggedIn] && [gpsTimer isValid]) {
			//NSLog(@"debug isLoggedIn: %@, timer: %@\n", [self isLoggedIn]?@"YES":@"NO", [gpsTimer isValid]?@"YES":@"NO");
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		}
		if ([gpsTimer isValid]) [gpsTimer invalidate];
		[self setGpsTimer:nil];
	}

	if (!isConnected || !isLoggedIn) {
		[self setGpsOpsRunning:NO forKey:@"basicIsLocked"];
		return NO;
	}
	
	if (isLoggedIn) {
		if (timeOut > 0)
			[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:timeOut]];
		if (postLoginSel) [self setPostLoginSel:nil];
		[processDict removeObjectForKey:@"isLocked"];
		[self doIsLocked:[NSNumber numberWithInt:0]];

		//clean UI
		[self performSelector:@selector(isLockedFinished) withObject:nil afterDelay:2.0];

		//wait for the resp or timeout
		[self setGpsTimer:[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(gpsTimeOut) userInfo:nil repeats:NO]];
		while ([self gpsOpsRunningForKey:@"basicIsLocked"] && [gpsTimer isValid]) {
			//NSLog(@"debug isConnected: %@, timer: %@\n", [self isConnected]?@"YES":@"NO", [gpsTimer isValid]?@"YES":@"NO");
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
		}
		if ([gpsTimer isValid]) [gpsTimer invalidate];
		[self setGpsTimer:nil];
		
		NSLog(@"GPS is%@locked.\n", [[processDict objectForKey:@"isLocked"] boolValue]?@" ":@" NOT ");
		return [[processDict objectForKey:@"isLocked"] boolValue];
	}

	return NO;
}

- (void) report
{
	[self setGpsOpsRunning:YES forKey:@"basicReport"];

	if (timeOut > 0)
		[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:timeOut]];

	if (!isConnected) {
		[self setPostLoginSel:@"report"];
		[self setPostLoginCmd:nil];
		[self connect];
	}
	
	if (isConnected) {
		[self doReport:[NSNumber numberWithInt:0]];
		if (postLoginSel) [self setPostLoginSel:nil];
	}
	//clean UI
	[self performSelector:@selector(reportFinished) withObject:nil afterDelay:4.0];
}

- (void) satellites
{
	[self setGpsOpsRunning:YES forKey:@"basicSatellites"];	
	[self doSend:@"F60 ALL"];
	[self setGpsOpsRunning:NO forKey:@"basicSatellites"];
}

- (void) selfTest
{
	[self setGpsOpsRunning:YES forKey:@"basicSelfTest"];
	[self doSend:@"F100 ST"];
	[self setGpsOpsRunning:NO forKey:@"basicSelfTest"];
}

- (void) getPpo
{
	[self setGpsOpsRunning:YES forKey:@"ppoGet"];
	[self doSend:@"F111"];
	[self setGpsOpsRunning:NO forKey:@"ppoGet"];
}

- (void) setPpo
{
	[self setGpsOpsRunning:YES forKey:@"ppoSet"];
	
	if (isPpo)
		[self doSend:[NSString stringWithFormat:@"F111 %@", ppoCommand]];
	else
		[self doSend:[NSString stringWithFormat:@"F111 %@", ppsCommand]];

	[self setGpsOpsRunning:NO forKey:@"ppoSet"];
}

//schedule a single shot pulse about a day ago
- (void) turnOffPpo
{
	[self setGpsOpsRunning:YES forKey:@"ppoTurnOff"];

	NSDateFormatter* frmt = [[[NSDateFormatter alloc] init] autorelease];
	[frmt setDateFormat:@"D"];
	int day = [[frmt stringFromDate:[NSDate dateWithTimeIntervalSinceNow:-24*3600]] intValue];

	NSString* cmd = [NSString stringWithFormat:@"F111 PPO %03d:00:00:00.000000 %03d:00:00:00.000001", day, day];
	[self doSend:cmd];
		
	[self setGpsOpsRunning:NO forKey:@"ppoTurnOff"];
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
	if(inNetSocket == socket){
		[self setIsConnected:[socket isConnected]];
		if(isConnected){
			//NSLog(@"GPS connection ok.\n");
			[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:2.0]];
			[self performSelector:@selector(disconnect) withObject:nil afterDelay:1.0];
		}
		else {
			NSLog(@"GPS connection failed.\n");
		}
	}
}

- (void) netsocket:(NetSocket*)inNetSocket connectionTimedOut:(NSTimeInterval)inTimeout;
{
	if(inNetSocket == socket){
		NSLog(@"GPS connection timed out\n");
		[self kill];
	}
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
	if (![self isLoggedIn]) NSLog(@"GPS connection failed\n");
	else NSLog(@"GPS disconnected.\n");
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disconnect) object:nil];
	[self kill];
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
	if(inNetSocket == socket){
		NSString* theString = [[[NSString alloc] initWithData:[inNetSocket readData] encoding:NSASCIIStringEncoding] autorelease];
		[gpsInBuffer appendString:theString];
		char lastChar = [gpsInBuffer characterAtIndex:[gpsInBuffer length] - 1];
		if (lastChar == '\n' || lastChar == '\r' || lastChar == ' ' || lastChar == '>' || lastChar == 'E') {
			[self performSelector:NSSelectorFromString([processDict objectForKey:@"selector"]) withObject:[processDict objectForKey:@"phase"]];
		}
		else {
			//NSLog(@"GPS warning: an incomplete chunk of data recieved,\nlast char: %d\n gpsBuffer: %@\n", lastChar, gpsInBuffer);

		}

	}
}
@end

@implementation ORXLGPSModel (private)

- (void) login:(NSNumber*)phase
{
	if (!isConnected) {
		NSLog(@"GPS lost connection during login:\n%@\n", gpsInBuffer);
		[gpsInBuffer setString:@""];
		[processDict setObject:[NSString stringWithFormat:@"login:"] forKey:@"selector"];
		return;
	}
	
	NSString* theString = nil;
	NSArray* lines = nil;

	switch ([phase intValue]) {
		case 0: //username request
			if (![gpsInBuffer length]) {
				NSLog(@"GPS: %@\nGPS error: no user name request received\n", gpsInBuffer);
				[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
				return;
			}
			//check it's the username request, it's preceeded with "\n\r\r"
			theString = [[NSString stringWithString:gpsInBuffer] uppercaseString];
			lines = [theString componentsSeparatedByString:@"\n\r"];
			if (![[lines lastObject] isEqualToString:@"\rUSER NAME: "]) {
				NSLog(@"GPS error: unknown request from GPS, user name request expected.\n%@\n", gpsInBuffer);
				[gpsInBuffer setString:@""];
				[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
				return;
			}
			//send the userName, wait for ack and password request
			[gpsInBuffer setString:@""];
			[processDict setObject:[NSNumber numberWithInt:1] forKey:@"phase"];
			[socket writeString:[NSString stringWithFormat:@"%@\n", userName] encoding:NSASCIIStringEncoding];
			break;

		case 1: //password request
			if (![gpsInBuffer length]) {
				NSLog(@"GPS error: no password request received\n");
				[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
				return;
			}	
			//check it is the password request
			theString = [[NSString stringWithString:gpsInBuffer] uppercaseString];
			lines = [theString componentsSeparatedByString:@"\n\r"];
			if (![[lines lastObject] isEqualToString:@"PASSWORD: "]) {
				NSLog(@"GPS error: unknown request from GPS, password request expected.\n%@\n", gpsInBuffer);
				[gpsInBuffer setString:@""];
				[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
				[self setDateToDisconnect:[NSDate date]];
				[self performSelector:@selector(disconnect) withObject:nil afterDelay:0.1];
				return;
			}
			//send the password, wait for ack and welcome message
			[gpsInBuffer setString:@""];
			[processDict setObject:[NSNumber numberWithInt:2] forKey:@"phase"];
			[socket writeString:[NSString stringWithFormat:@"%@\n", password] encoding:NSASCIIStringEncoding];
			break;
			
		case 2: //password ack, welcome
			if (![gpsInBuffer length]) {
				NSLog(@"GPS error: no password ack received\n");
				[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
				return;
			}	
			//first line is the acknowledged password
			theString = [NSString stringWithString:gpsInBuffer];
			NSMutableArray* mlines = [[[theString componentsSeparatedByString:@"\n\r"] mutableCopy]autorelease];
			if (![[mlines objectAtIndex:0] isEqualToString:password]) {
				NSLog(@"GPS error: Password wasn't accepted.\n");
				[gpsInBuffer setString:@""];
				[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
				return;
			}	
			[mlines removeObjectAtIndex:0];
			for (NSString* msg in mlines) NSLog(@"GPS: %@\n", msg);
			//if success then the last line should be
			if (![[mlines objectAtIndex:[mlines count] - 2] isEqualToString:@"\rLOGIN SUCCESSFUL!"]){
				NSLog(@"GPS error: Login wasn't successful.\n@%\n", [mlines componentsJoinedByString:@"\n"]);
				[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
				NSLog(@"GPS: trying to quit the connection now\n");
				[self setDateToDisconnect:[NSDate date]];
				[self performSelector:@selector(disconnect) withObject:nil afterDelay:0.1];
				return;
			}
			//set the regular time out
			if (timeOut > 0) 
				[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:timeOut]];
			else
				[self setDateToDisconnect:[NSDate distantFuture]];
			
			[self setIsLoggedIn:YES];
			if (postLoginSel) [self performSelector:NSSelectorFromString(postLoginSel) withObject:postLoginCmd];
			return;
			break;
			
		default:
			break;
	}
	//time out for the next login step
	[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:2]];
}

- (void) gpsTimeOut {
	if (gpsTimer) {
		[gpsTimer invalidate];
	}
	NSLog(@"GPS timeout\n");
}

- (void) log:(id)aObject
{
	
	NSLog(@"GPS log: %@\n", [gpsInBuffer stringByReplacingOccurrencesOfString:@"\r" withString:@""]);
	[gpsInBuffer setString:@""];
}

- (void) logout:(NSNumber*)phase
{
	if (!isConnected) {
		NSLog(@"GPS lost connection during logout:\n%@\n", gpsInBuffer);
		[gpsInBuffer setString:@""];
		[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
		return;
	}
		
	switch ([phase intValue]) {
		case 0: //send quit command
			[gpsInBuffer setString:@""];
			[processDict setObject:[NSString stringWithFormat:@"logout:"] forKey:@"selector"];
			[processDict setObject:[NSNumber numberWithInt:1] forKey:@"phase"];
			[socket writeString:[NSString stringWithFormat:@"QUIT\n"] encoding:NSASCIIStringEncoding];
			break;

		case 1:
			[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
			NSLog(@"GPS log: %@\n", [gpsInBuffer stringByReplacingOccurrencesOfString:@"\r" withString:@""]);
			[self kill];
			break;
		
		default:
			break;
	}
	//timeout for the next logout step
	[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:2]];
}

- (void)kill
{
	if (processDict && [[processDict objectForKey:@"selector"] isEqualToString:@"logout:"]) {
		NSLog(@"GPS warning: killing the connection.\n");
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(kill) object:nil];
	[self setIsLoggedIn:NO];
	[self setIsConnected:NO];
	if (socket) {
		[socket setDelegate:nil];
		[socket autorelease];
		socket = nil;
	}
	if (gpsInBuffer) {
		[gpsInBuffer release];
		gpsInBuffer = nil;
	}
	if (processDict) {
		[processDict release];
		processDict = nil;
	}
	NSLog(@"GPS: connection closed.\n");
}	

- (void) doSend:(NSString*)aCommand
{
	if (!isConnected) {
		[self setPostLoginSel:@"doSend:"];
		[self setPostLoginCmd:aCommand];
		[self connect];
		return;
	}

	if (postLoginSel) [self setPostLoginSel:nil];
	if (timeOut > 0) 
		[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:timeOut]];

	[gpsInBuffer setString:@""];
	[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
	[socket writeString:[NSString stringWithFormat:@"%@\n", aCommand] encoding:NSASCIIStringEncoding];
}

- (void) testFinished
{
	[NSThread cancelPreviousPerformRequestsWithTarget:self selector:@selector(testFinished) object:nil];
	
	if (isConnected) { //force disconnect
		[self setDateToDisconnect:[NSDate date]];
		[self disconnect];
	}
	
	[self setGpsOpsRunning:NO forKey:@"telnetTest"];
}

- (void) doReport:(NSNumber*)phase
{
	if (!isConnected) {
		NSLog(@"GPS lost connection during report:\n%@\n", gpsInBuffer);
		[gpsInBuffer setString:@""];
		[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
		return;
	}
		
	switch ([phase intValue]) {
		case 0:	//f50 send
			[processDict setObject:[NSString stringWithFormat:@"doReport:"] forKey:@"selector"];
			[processDict setObject:[NSNumber numberWithInt:1] forKey:@"phase"];
			NSLog(@"GPS position:\n");
			[gpsInBuffer setString:@""];
			[socket writeString:[NSString stringWithFormat:@"F50 LLA\n"] encoding:NSASCIIStringEncoding];
			break;
		case 1:	//f50 ack
			[processDict setObject:[NSNumber numberWithInt:2] forKey:@"phase"];
			[gpsInBuffer setString:@""];
			break;
		case 2: //f50 resp
			NSLog(@"GPS: %@\n", gpsInBuffer);
			[processDict setObject:[NSNumber numberWithInt:3] forKey:@"phase"];
			[gpsInBuffer setString:@""];
			break;
		case 3: //unit ready, f51 send
			NSLog(@"GPS antenna delay:\n");
			[processDict setObject:[NSNumber numberWithInt:4] forKey:@"phase"];
			[gpsInBuffer setString:@""];
			[socket writeString:[NSString stringWithFormat:@"F51\n"] encoding:NSASCIIStringEncoding];
			break;
		case 4: //f51 ack and resp
			NSLog(@"GPS: %@\n", gpsInBuffer);
			[processDict setObject:[NSNumber numberWithInt:5] forKey:@"phase"];
			[gpsInBuffer setString:@""];
			break;
		case 5: //unit ready, f52 send
			NSLog(@"GPS 10 Mhz PPS cable delay:\n");
			[processDict setObject:[NSNumber numberWithInt:6] forKey:@"phase"];
			[gpsInBuffer setString:@""];
			[socket writeString:[NSString stringWithFormat:@"F52\n"] encoding:NSASCIIStringEncoding];
			break;
		case 6: //f52 ack and response
			NSLog(@"GPS: %@\n", gpsInBuffer);
			[processDict setObject:[NSNumber numberWithInt:7] forKey:@"phase"];
			[gpsInBuffer setString:@""];
			break;
		case 7: //unit ready, f53 send
			NSLog(@"GPS operation mode (static desired):\n");
			[processDict setObject:[NSNumber numberWithInt:8] forKey:@"phase"];
			[gpsInBuffer setString:@""];
			[socket writeString:[NSString stringWithFormat:@"F53\n"] encoding:NSASCIIStringEncoding];
			break;
		case 8: //f53 ack and response
			NSLog(@"GPS: %@\n", gpsInBuffer);
			[processDict setObject:[NSNumber numberWithInt:9] forKey:@"phase"];
			[gpsInBuffer setString:@""];
			break;
		case 9: //unit ready, f69 send
			NSLog(@"GPS time mode:\n");
			[processDict setObject:[NSNumber numberWithInt:10] forKey:@"phase"];
			[gpsInBuffer setString:@""];
			[socket writeString:[NSString stringWithFormat:@"F69\n"] encoding:NSASCIIStringEncoding];
			break;
		case 10: //f52 ack and response
			NSLog(@"GPS 10: %@\n", gpsInBuffer);
			[gpsInBuffer setString:@""];
			[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
			[self reportFinished];
			break;
			
		default:
			break;
			
	}
	[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:timeOut]];
}

- (void) reportFinished
{
	[NSThread cancelPreviousPerformRequestsWithTarget:self selector:@selector(reportFinished) object:nil];
	if (!isConnected) {
		NSLog(@"GPS: report failed\n");
	}
	[self setGpsOpsRunning:NO forKey:@"basicReport"];
}

- (void) doIsLocked:(NSNumber*)phase
{
	if (!isConnected) {
		NSLog(@"GPS lost connection during report:\n%@\n", gpsInBuffer);
		[gpsInBuffer setString:@""];
		[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
		return;
	}
	
	switch ([phase intValue]) {
		case 0:	//f119
			[processDict setObject:[NSString stringWithFormat:@"doIsLocked:"] forKey:@"selector"];
			[processDict setObject:[NSNumber numberWithInt:1] forKey:@"phase"];
			[gpsInBuffer setString:@""];
			[socket writeString:[NSString stringWithFormat:@"F119 S\n"] encoding:NSASCIIStringEncoding];
			break;
		case 1:	//f119 ack
			[processDict setObject:[NSNumber numberWithInt:2] forKey:@"phase"];
			[gpsInBuffer setString:@""];
			break;
		case 2:	//f119 resp
			NSLog(@"GPS: %@\n", gpsInBuffer);
			NSString* theString = [NSString stringWithString:gpsInBuffer];
			NSMutableArray* mlines = [[[theString componentsSeparatedByString:@"\n\r"] mutableCopy] autorelease];
			if ([mlines objectAtIndex:3]){
				if ([[mlines objectAtIndex:3] rangeOfString:@"LOCKED"].location == NSNotFound) {
					NSLog(@"GPS isLocked error: lock information not found\n");
					[processDict removeObjectForKey:@"isLocked"];
				}
				else if ([[mlines objectAtIndex:3] rangeOfString:@"UNLOCKED"].location == NSNotFound) {
					[processDict setObject:[NSNumber numberWithBool:YES] forKey:@"isLocked"];
					NSLog(@"GPS Locked\n");
				}
				else {
					[processDict setObject:[NSNumber numberWithBool:NO] forKey:@"isLocked"];
					NSLog(@"GPS Unlocked\n");
				}
			}	
			else {
				NSLog(@"GPS isLocked error: lock information not found\n");
				[processDict removeObjectForKey:@"isLocked"];
			}

			[gpsInBuffer setString:@""];
			[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
			[self isLockedFinished];
			break;
		default:
			break;
	}
	[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:timeOut]];
}

- (void) isLockedFinished
{
	[NSThread cancelPreviousPerformRequestsWithTarget:self selector:@selector(isLockedFinished) object:nil];
	if (!isConnected) {
		NSLog(@"GPS: isLocked failed.\n");
	}
	[self setGpsOpsRunning:NO forKey:@"basicIsLocked"];
}

- (void) doTime:(NSNumber*)phase
{
	if (!isConnected) {
		NSLog(@"GPS lost connection during report:\n%@\n", gpsInBuffer);
		[gpsInBuffer setString:@""];
		[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
		return;
	}
	
	switch ([phase intValue]) {
		case 0:	//F3
			[processDict setObject:[NSString stringWithFormat:@"doTime:"] forKey:@"selector"];
			[processDict setObject:[NSNumber numberWithInt:1] forKey:@"phase"];
			[gpsInBuffer setString:@""];
			[socket writeString:[NSString stringWithFormat:@"F3\n"] encoding:NSASCIIStringEncoding];
			break;
		case 1:	//F3 ack
			NSLog(@"time resp: %@\n", gpsInBuffer);
			[processDict setObject:[NSDate dateWithNaturalLanguageString:gpsInBuffer] forKey:@"time"];
			[gpsInBuffer setString:@""];
			[processDict setObject:[NSString stringWithFormat:@"log:"] forKey:@"selector"];
			[self timeFinished];
			break;
			//F9, T, T, T, ^C, and back...
		default:
			break;
	}	
	[self setDateToDisconnect:[NSDate dateWithTimeIntervalSinceNow:timeOut]];
}


- (void) timeFinished
{
	[NSThread cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeFinished) object:nil];
	if (!isConnected) {
		NSLog(@"GPS: time command failed.\n");
	}
	[self setGpsOpsRunning:NO forKey:@"basicTime"];
}

@end
