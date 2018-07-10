//
//  ORHV4032Model.m
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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

#pragma mark ¥¥¥Imported Files
#import "ORHV4032Model.h"
#import "ORHV2132Model.h"
#import "ORHV4032Supply.h"
#import "ORDataPacket.h"

#pragma mark ¥¥¥Local Strings
NSString* ORHV4032ModelHvStateChanged = @"ORHV4032ModelHvStateChanged";
static NSString* ORHV4032ConnectorIn 	= @"ORHV4032ConnectorIn";
static NSString* ORHV4032ConnectorOut 	= @"ORHV4032ConnectorOut";

#pragma mark ¥¥¥Notification Strings
NSString* HV4032PollingStateChangedNotification	= @"HVPollingStateChanged";
NSString* HV4032StartedNotification		= @"HV4032StartedNotification";
NSString* HV4032StoppedNotification		= @"HV4032StoppedNotification";
NSString* HV4032CalibrationLock			= @"HV4032CalibrationLock";
NSString* HV4032Lock					= @"HV4032Lock";


@interface ORHV4032Model (private)
- (void) _setUpPolling;
- (void) _doRamp;
@end

#define kDeltaTime 0.5

@implementation ORHV4032Model

#pragma mark ¥¥¥initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self makeSupplies];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		NSEnumerator* e = [supplies objectEnumerator];
		id s;
		while(s = [e nextObject]){
			int theVoltage = 0; 
			[[self getHVController] readVoltage:&theVoltage mainFrame:[self mainFrameID] channel:[s supply]];
			[s setAdcVoltage:theVoltage];
			[s setDacValue:theVoltage];
		}
	}
	@catch(NSException*localException) {
	}
}


- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(voltageChangedAtController:)
                         name : ORHV2132VoltageChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(onOffStateChangedAtController:)
                         name : ORHV2132OnOffChanged
						object: nil];
}


- (void) voltageChangedAtController:(NSNotification*)aNote
{
	ORHV2132Model* hvObj = [aNote object];
	if(hvObj == [self getHVController]){
		int theMainFrame = [[[aNote userInfo] objectForKey:@"MainFrame"] intValue];
		if(theMainFrame == [self mainFrameID]){
			int theChannel   = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
			int theVoltage     = [[[aNote userInfo] objectForKey:@"Voltage"] intValue];
			[[self supply:theChannel] setDacValue:theVoltage];
		}
	}
}

- (void) onOffStateChangedAtController:(NSNotification*)aNote
{
	ORHV2132Model* hvObj = [aNote object];
	if(hvObj == [self getHVController]){
		int theMainFrame = [[[aNote userInfo] objectForKey:@"MainFrame"] intValue];
		int theState     = [[[aNote userInfo] objectForKey:@"State"] intValue];
		if(theMainFrame == [self mainFrameID]){
			[self saveHVParams];
			[self setHvState:theState];
			[self setUpImage];
		}
	}
}

- (NSString*) helpURL
{
	return @"CAMAC/HV2132_4032.html";
}

#pragma mark ***Accessors

- (BOOL) hvState
{
    return hvState;
}

- (void) setHvState:(BOOL)aHvState
{
    hvState = aHvState;
	
	[self performSelector:@selector(setUpImage) withObject:nil afterDelay:0];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORHV4032ModelHvStateChanged object:self];
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [rampTimer invalidate];
    [rampTimer release];
    rampTimer = nil;
    
    [supplies release];
    
    [hvNoPollingAlarm clearAlarm];
    [hvNoPollingAlarm release];
    
    [super dealloc];
}

- (void) wakeUp
{
	[self _setUpPolling];
	[self registerNotificationObservers];
	[super wakeUp];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [hvNoPollingAlarm clearAlarm];
    [hvNoPollingAlarm release];
    hvNoPollingAlarm = nil;
	
}


- (id) getHVController
{
	//chain up the connections to the main HV controller
	id obj = [self objectConnectedTo:ORHV4032ConnectorIn];
	return [ obj getHVController ];
}

-(void)setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
    
    NSImage* aCachedImage;
	if([self hvOn]) aCachedImage = [NSImage imageNamed:@"HV4032Off"];
	else aCachedImage = [NSImage imageNamed:@"HV4032On"];
    NSSize theIconSize = [aCachedImage size];
    
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    NSAttributedString* n;
	NSString* s;
	if([self mainFrameID]== 0xffffffff) s = @"--";
	else s = [NSString stringWithFormat:@"%lu",[self mainFrameID]];
	n = [[NSAttributedString alloc] 
		 initWithString:s
		 attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont labelFontOfSize:10],NSFontAttributeName,
					 [NSColor yellowColor],NSForegroundColorAttributeName,
					 nil]];
	if([self mainFrameID]<10 || ![self mainFrameID])[n drawInRect:NSMakeRect(29,8,20,10)];
	else [n drawInRect:NSMakeRect(26,8,20,10)];
	[n release];
	
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORForceRedraw
	 object: self];
    
}


- (void) makeMainController
{
    [self linkToController:@"ORHV4032Controller"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(15,15) withGuardian:self withObjectLink:self];
	[aConnector setConnectorType:'403I'];
	[aConnector addRestrictedConnectionType: '403O' ]; //can only connect to 4032 outputs
    [[self connectors] setObject:aConnector forKey:ORHV4032ConnectorIn];
    [aConnector release];
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint(15,2) withGuardian:self withObjectLink:self];
	[aConnector setConnectorType:'403O'];
	[aConnector addRestrictedConnectionType: '403I' ]; //can only connect to 4032 inputs
    [[self connectors] setObject:aConnector forKey:ORHV4032ConnectorOut];
    [aConnector release];
	
	
}

- (void) connectionChanged
{
	id obj = [self objectConnectedTo: ORHV4032ConnectorIn];
	if(!obj)[self setMainFrameID:0xffffffff];
	else if(![obj isKindOfClass:[self class]])[self setMainFrameID:0];
	else [self setMainFrameID:[obj mainFrameID]+1];
	[self performSelector:@selector(setUpImage) withObject:nil afterDelay:0];
}

- (void) setMainFrameID:(unsigned long)anIdNumber
{
	[self setUniqueIdNumber:anIdNumber];
	[[self objectConnectedTo: ORHV4032ConnectorOut] setMainFrameID:anIdNumber+1];
	[self performSelector:@selector(setUpImage) withObject:nil afterDelay:0];
}

- (unsigned long) mainFrameID
{
	return [self uniqueIdNumber];
}

- (void) makeSupplies
{
    [self setSupplies:[NSMutableArray arrayWithCapacity:kHV4032NumberSupplies]];
    int i;
    for(i=0;i<kHV4032NumberSupplies;i++){
        ORHV4032Supply* aSupply = [[ORHV4032Supply alloc] initWithOwner:self supplyNumber:i];
        [supplies addObject:aSupply];
        [aSupply release];
    }
}

- (void) initializeStates
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHV4032Supply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply controlled]){
            NSComparisonResult direction = [aSupply dacValue] - [aSupply targetVoltage];
            if(direction<0) 	 [aSupply setRampState:kHV4032Up];
            else if(direction>0) [aSupply setRampState:kHV4032Down];
            else 				 [aSupply setRampState:kHV4032Idle];
        }
        else [aSupply setRampState:kHV4032Idle];
    }
}


- (void) setPollingState:(NSTimeInterval)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollingState:pollingState];
    
    pollingState = aState;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:HV4032PollingStateChangedNotification
	 object: self];
    
    [self performSelector:@selector(_setUpPolling) withObject:nil afterDelay:0.5];
}


- (NSTimeInterval)	pollingState
{
    return pollingState;
}

- (ORHV4032Supply*) supply:(int)index
{
    return [supplies objectAtIndex:index];
}

- (NSMutableArray*)supplies
{	
    return supplies;
}

- (void) setSupplies:(NSMutableArray*)someSupplies
{
    [someSupplies retain];
    [supplies release];
    supplies = someSupplies;
}

- (void) setStates:(int)aState onlyControlled:(BOOL)onlyControlled
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHV4032Supply* aSupply;
    while(aSupply = [e nextObject]){
        if(onlyControlled && ![aSupply controlled])continue;
        [aSupply setRampState:aState];
    }
}



// ===========================================================
// - rampTimer:
// ===========================================================
- (NSTimer *)rampTimer
{
    return rampTimer; 
}

- (BOOL) hasBeenPolled 
{ 
    return hasBeenPolled;
}


#pragma mark ¥¥¥Hardware Access
- (void) turnHVOn:(BOOL)aState
{
    [[self getHVController] setHV:aState mainFrame:[self mainFrameID]];
    [self pollHardware];
}


- (void) pollHardware
{
    @try { 
        id hvController = [self getHVController];
        if(hvController){ //no sense in doing anything if not connected.
            hasBeenPolled = YES;
			int theState; 
			unsigned short failedMask = 0;
			[ hvController readStatus:&theState failedMask:&failedMask mainFrame:[self mainFrameID]];
			[self setHvState:theState];
			
            NSEnumerator* e = [supplies objectEnumerator];
            ORHV4032Supply* aSupply;
            while(aSupply = [e nextObject]){
				if(failedMask & (0x1<<[aSupply supply])){
					[aSupply setIsPresent:NO];
				}
				else {
					[aSupply setIsPresent:YES];
					[self checkAdcDacMismatch:aSupply];
				}
            }
        }
		
    }
	@catch(NSException*localException) {
		NSLog(@"HV4032 %d polling turned off due to timeout\n",[self mainFrameID]);
		[self setPollingState:0];
		
    }
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollingState!=0){
		[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollingState];
	}
}


- (void) checkAdcDacMismatch:(ORHV4032Supply*) aSupply
{
	int adcVoltage;
	[[self getHVController] readVoltage:&adcVoltage mainFrame:[self mainFrameID] channel:[aSupply supply]];
	[aSupply setAdcVoltage:adcVoltage];
    [aSupply checkAdcDacMismatch:self pollingTime:pollingState];
}

- (void)saveHVParams
{
	[[self getHVController] saveHVParams];
}

- (void)loadHVParams
{
	[[self getHVController] loadHVParams];
}


#pragma mark ¥¥¥Status
- (BOOL) hvOn
{
	int value = 0;
	unsigned short failed = 0;
	[[self getHVController] readStatus:&value failedMask:&failed mainFrame:[self mainFrameID]];
	return value;
}

-(BOOL) significantVoltagePresent
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHV4032Supply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply significantVoltagePresent])return YES;
    }
    return NO;
}


-(BOOL) anyControlledSupplies
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHV4032Supply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply controlled])return YES;
    }
    return NO;
}


-(BOOL) voltageOnAllControlledSupplies
{
    BOOL atLeastOne = NO;
    NSEnumerator* e = [supplies objectEnumerator];
    ORHV4032Supply* aSupply;
    while(aSupply = [e nextObject]){
        if([aSupply controlled]){
            if(([aSupply adcVoltage]<=5))return NO;
            else atLeastOne = YES;
        }
    }
    return atLeastOne;
}


// read/write status access methods
- (BOOL) controlled:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] controlled];
}

- (void) setControlled:(short) aSupplyIndex value:(BOOL)aState
{
    [[supplies objectAtIndex:aSupplyIndex] setControlled:aState];
}

- (int)  rampTime:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] rampTime];
}

- (void)  setRampTime:(short) aSupplyIndex value:(int)aValue
{
    [[supplies objectAtIndex:aSupplyIndex] setRampTime:aValue];
}

- (int)  targetVoltage:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] targetVoltage];
}

- (void)  setTargetVoltage:(short) aSupplyIndex value:(int)aValue
{
    [[supplies objectAtIndex:aSupplyIndex] setTargetVoltage:aValue];
}

//read only supply methods
- (int)  dacValue:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] dacValue];
}

- (int)  adcVoltage:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] adcVoltage];
}

- (int) rampState:(short) aSupplyIndex
{
    return [[supplies objectAtIndex:aSupplyIndex] rampState];
}


#pragma mark ¥¥¥Polling
- (void) _setUpPolling
{
    if(pollingState!=0){        
        NSLog(@"Polling HV every %.0f seconds.\n",pollingState);
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollingState];
		[self pollHardware];
		[hvNoPollingAlarm clearAlarm];
    }
    else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
    	NSLog(@"HV NOT being Polled.\n");
		if(!hvNoPollingAlarm){
			NSString* theName = [NSString stringWithFormat:@"HV4032-%lu Polling Off",[self mainFrameID]];
			hvNoPollingAlarm = [[ORAlarm alloc] initWithName:theName severity:1];
			[hvNoPollingAlarm setSticky:YES];
			[hvNoPollingAlarm setHelpStringFromFile:@"HVNotPollingHelp"];
		}                      
		[hvNoPollingAlarm setAcknowledged:NO];
		[hvNoPollingAlarm postAlarm];
        
    }
}

#pragma mark ¥¥¥Archival

static NSString *ORHVSupplies 		= @"ORHVSupplies";
static NSString *ORHVPollingState 	= @"ORHVPollingState";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setSupplies:[decoder decodeObjectForKey:ORHVSupplies]];
    [self setPollingState:[decoder decodeIntForKey:ORHVPollingState]];
	if(!supplies){
		[self makeSupplies];
	}
	
    NSEnumerator* e = [supplies objectEnumerator];
    id s;
    while(s = [e nextObject]){
        [s setOwner:self];
    }
    
    
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[self supplies] forKey:ORHVSupplies];
    [encoder encodeInt:[self pollingState] forKey:ORHVPollingState];
}



- (void) wakeup
{
    [super wakeUp];
    [[self undoManager] disableUndoRegistration];
    [[self getHVController] loadHVParams];
    [[self undoManager] enableUndoRegistration];
}


#pragma mark ¥¥¥Safety Check
- (BOOL) checkActualVsSetValues
{
    BOOL allOK = YES;
    NSEnumerator* e = [supplies objectEnumerator];
    ORHV4032Supply* aSupply;
    while(aSupply = [e nextObject]){
        if(![aSupply checkActualVsSetValues]){
            allOK = NO;
            break;
        }
    }
    return allOK;
}

- (void) forceDacToAdc
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHV4032Supply* aSupply;
    while(aSupply = [e nextObject]){
        [aSupply resolveActualVsSetValueProblem];
    }
}

- (void) resolveActualVsSetValueProblem 
{
    NSEnumerator* e = [supplies objectEnumerator];
    ORHV4032Supply* aSupply;
    while(aSupply = [e nextObject]){
        if(![aSupply checkActualVsSetValues]){
            [aSupply resolveActualVsSetValueProblem];
        }
    }
}

#pragma mark ¥¥¥Run Data

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class])        forKey:@"Class Name"];
    [supplies makeObjectsPerformSelector:@selector(addParametersToDictionary:) withObject:objDictionary];
    
    [dictionary setObject:objDictionary forKey:@"High Voltage"];
    
    
    return objDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    
    
}

- (void) startRamping
{
    
    if(!rampTimer){
		
        rampTimer = [[NSTimer scheduledTimerWithTimeInterval:kDeltaTime target:self selector:@selector(doRamp) userInfo:nil repeats:YES] retain];
        [[NSNotificationCenter defaultCenter]
		 postNotificationName:HV4032StartedNotification
		 object: self];
    }
}

- (void) stopRamping
{
    [rampTimer invalidate];
    [rampTimer release];
    rampTimer = nil;
    [self setStates:kHV4032Idle onlyControlled:NO];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:HV4032StoppedNotification
	 object: self];
    
	[[self getHVController] saveHVParams];
	
}

- (void) doRamp
{
    
    int unitStep;
    
    NSEnumerator* e = [supplies objectEnumerator];
    ORHV4032Supply* hvSupply;
    BOOL atLeastOne = NO;
    
    while(hvSupply = [e nextObject]){ 
        int totalRampTime 	 = [hvSupply rampTime];
        int theDACVoltage 	 = [hvSupply dacValue];
        int theTargetVoltage = [hvSupply targetVoltage];			
        int theState = [hvSupply rampState];
		int theValueToSet = 0;
		
		if(theTargetVoltage==0 && theState != kHV4032Panic && theState != kHV4032Done){
			theState = kHV4032Zero;
		}
		
        if(theState == kHV4032Up || theState == kHV4032Down ){
			float voltsToGo = (theTargetVoltage- theDACVoltage);
			float timeToGo = totalRampTime * voltsToGo/theTargetVoltage;
			if(timeToGo!=0){
				unitStep = (kDeltaTime * voltsToGo/timeToGo)+.5;
				if(unitStep<1)unitStep=1;
			}
			else unitStep = 1;
			
			if(theState == kHV4032Up ){
				theValueToSet = theDACVoltage + unitStep;
				
				if( theValueToSet >= theTargetVoltage ) {
					theValueToSet = theTargetVoltage;
					[hvSupply setRampState:kHV4032Done];
				}
			}
			else if(theState == kHV4032Down ){
				theValueToSet = theDACVoltage - unitStep;
				
				if( theValueToSet <= theTargetVoltage ) {
					theValueToSet = theTargetVoltage;
					[hvSupply setRampState:kHV4032Done];
				}
			}
			atLeastOne	= YES;
			[self setVoltage:theValueToSet supply:hvSupply];
		}
		else if(theState == kHV4032Panic || theState == kHV4032Zero){
			//with panic or ramp to zero we'll try to go down in ten seconds
			unitStep = (kDeltaTime * theDACVoltage/10)+.5;
            if(unitStep<10)unitStep = 10;
			
            theValueToSet = theDACVoltage - unitStep;
            
            if( theValueToSet <= 0 ) {
                theValueToSet = 0;
                [hvSupply setRampState:kHV4032Done];
            }
			
            atLeastOne = YES;
            [self setVoltage:theValueToSet supply:hvSupply];
        }
        [self readAdc:hvSupply];
    }
    
    [self pollHardware];
    
    if(!atLeastOne){
        [self stopRamping];
		[[self getHVController] saveHVParams];
    }
}

- (void) readAdc:(ORHV4032Supply*)aSupply
{
	int theValue;
	[[self getHVController] readVoltage:&theValue mainFrame:[self mainFrameID] channel:[aSupply supply]];
	[aSupply setAdcVoltage:theValue];
}
- (void) setVoltage:(int)aVoltage supply:(ORHV4032Supply*)aSupply
{
	[[self getHVController] setVoltage:aVoltage mainFrame:[self mainFrameID] channel:[aSupply supply]];
	[aSupply setDacValue:aVoltage];
}

//a no-checks panic method, mainly included for use by remote systems.
- (void) panic
{
    [self setStates:kHV4032Panic onlyControlled:NO];
    [self startRamping];
}


@end
