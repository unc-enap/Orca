//
//  NcdMuxModel.cp
//  Orca
//
//  Created by Mark Howe on Thurs Feb 20 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "NcdMuxModel.h"
#import "NcdMuxHWModel.h"

#import "NcdMuxBoxModel.h"
#import "ORDataPacket.h"
#import "ORReadOutList.h"
#import "OROscBaseModel.h"
#import "NcdDetector.h"
#import "ORDataTypeAssigner.h"


#pragma mark ¥¥¥Connection Strings
static NSString* NcdMux408Connector 	= @"Ncd Mux to 408 Connector";
static NSString* NcdHV408Connector  	= @"Ncd HV to 408 Connector";
static NSString* NcdMuxToHVConnector  	= @"Ncd Mux to HV Connector";

#pragma mark ¥¥¥Static Definitions
static NSString* NcdMuxConnectors[8] = {
@"MuxBox0 Connector", @"MuxBox1 Connector", @"MuxBox2 Connector",
@"MuxBox3 Connector", @"MuxBox4 Connector", @"MuxBox5 Connector",
@"MuxBox6 Connector", @"MuxBox7 Connector",
};
static NSString* selectError[8] = {
@"Getting Selected Mux 0", @"Getting Selected Mux 1", @"Getting Selected Mux 2",
@"Getting Selected Mux 3", @"Getting Selected Mux 4", @"Getting Selected Mux 5",
@"Getting Selected Mux 6", @"Getting Selected Mux 7",
};

#pragma mark ¥¥¥Notification Strings
NSString* NcdMuxScopeSelectionChangedNotification 	= @"Mux Scope Selection Changed Notification";
NSString* NcdMuxErrorCountChangedNotification 		= @"NcdMuxErrorCountChangedNotification";

@implementation NcdMuxModel

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setMuxBoxHw:[[[NcdMuxHWModel alloc] init] autorelease]];
    [self setHvHw: [[[NcdMuxHWModel alloc] init] autorelease]];
    [self setScopeSelection: 3]; //toggle
    
    [self setTrigger1Group:[[[ORReadOutList alloc] initWithIdentifier:@"Scope A"]autorelease]];
    [self setTrigger2Group:[[[ORReadOutList alloc] initWithIdentifier:@"Scope B"]autorelease]];
    muxLock = [[NSLock alloc] init];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [muxLock release];
    [detector release];
    [trigger1Group release];
    [trigger2Group release];
    [muxBoxHw release];
    [hvHw release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"NcdMux"]];
}

- (void) makeConnectors
{
    int i;
    for(i=0;i<4;i++){
        ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(62,
																		  [self frame].size.height - 15-i*(kConnectorSize+.5)) withGuardian:self withObjectLink:[self muxBoxHw]];
        [[self connectors] setObject:aConnector forKey:NcdMuxConnectors[i]];
        [aConnector setIdentifer:i];
		[aConnector setConnectorType: 'MuxO' ];
		[aConnector addRestrictedConnectionType: 'MuxI' ]; //can only connect to MuxBox inputs
        [aConnector release];
    }
    
    for(i=0;i<4;i++){
        ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(85, [self frame].size.height - 15-i*(kConnectorSize+.5)) withGuardian:self withObjectLink:[self muxBoxHw]];
        [[self connectors] setObject:aConnector forKey:NcdMuxConnectors[i+4]];
        [aConnector setIdentifer:i+4];
		[aConnector setConnectorType: 'MuxO' ];
		[aConnector addRestrictedConnectionType: 'MuxI' ]; //can only connect to MuxBox inputs
        [aConnector release];
    }
    
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(16, 20) withGuardian:self withObjectLink:[self muxBoxHw]];
    [aConnector setConnectorImageType:kVerticalRect];
    [[self connectors] setObject:aConnector forKey:NcdMux408Connector];
    [[self muxBoxHw] setConnectorTo408:aConnector];
	[ aConnector setConnectorType: 'IP1 ' ];
	[ aConnector addRestrictedConnectionType: 'IP2 ' ]; //can only connect to IP inputs
    [aConnector release];
    
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint(40, 20) withGuardian:self withObjectLink:[self hvHw]];
    [aConnector setConnectorImageType:kVerticalRect];
    [[self hvHw] setConnectorTo408:aConnector];
    [[self connectors] setObject:aConnector forKey:NcdHV408Connector];
	[ aConnector setConnectorType: 'IP1 ' ];
	[ aConnector addRestrictedConnectionType: 'IP2 ' ]; //can only connect to IP inputs
    [aConnector release];
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint(37, 4) withGuardian:self withObjectLink:self];
    [aConnector setConnectorType:'HVCN'];
    [[self connectors] setObject:aConnector forKey:NcdMuxToHVConnector];
    [aConnector release];
}

- (void) makeMainController
{
    [self linkToController:@"NcdMuxController"];
}

- (NSString*) helpURL
{
	return @"NCD/Mux.html";
}

#pragma mark ¥¥¥Notification
- (void) registerNotificationObservers
{    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(disableScopes:)
                         name : ORHardwareEnvironmentNoisy
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(reArmScopes:)
                         name : ORHardwareEnvironmentQuiet
                       object : nil];
}

#pragma mark ¥¥¥Accessors
- (NcdMuxHWModel*) muxBoxHw
{
    return muxBoxHw;
}
- (void) setMuxBoxHw:(NcdMuxHWModel*)hw
{
    [hw retain];
    [muxBoxHw release];
    muxBoxHw = hw;
}

- (NcdMuxHWModel*) hvHw
{
    return hvHw;
}

- (void) setHvHw:(NcdMuxHWModel*)hw
{
    [hw retain];
    [hvHw release];
    hvHw = hw;
    
    [hvHw setDoNotWaitForCSBLow:YES];
}

- (ORReadOutList*) trigger1Group
{
    return trigger1Group;
}
- (void) setTrigger1Group:(ORReadOutList*)newTrigger1Group
{
    [trigger1Group autorelease];
    trigger1Group=[newTrigger1Group retain];
}

- (ORReadOutList*) trigger2Group
{
    return trigger2Group;
}
- (void) setTrigger2Group:(ORReadOutList*)newTrigger2Group
{
    [trigger2Group autorelease];
    trigger2Group=[newTrigger2Group retain];
}

- (NcdDetector*) detector
{
    return detector;
}
- (void) setDetector:(NcdDetector*)newDetector
{
    [detector autorelease];
    detector=[newDetector retain];
}

- (uint32_t) eventReadError
{
    return eventReadError;
}

- (uint32_t) armError
{
    return armError;
}



#pragma mark ¥¥¥HV Control Methods
- (int) numberOfSupplies
{
    return kNumNcdSupplies;
}



- (int) scopeSelection
{
    return [muxBoxHw scopeSelection];
}

- (void) setScopeSelection:(int)newScopeSelection
{
    [[[self undoManager] prepareWithInvocationTarget:self] setScopeSelection:[muxBoxHw scopeSelection]];
    
    [muxBoxHw setScopeSelection:newScopeSelection];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:NcdMuxScopeSelectionChangedNotification
	 object:self];
}


#pragma mark ¥¥¥HV Hardware Access
- (void) turnOnSupplies:(NSArray*)someSupplies state:(BOOL)aState;
{
    [hvHw turnOnSupplies:someSupplies state:aState];
}

- (void) writeDac:(int)aValue supply:(id)aSupply
{
    [hvHw writeDac:aValue supply:aSupply];
}

- (void) readAdc:(id)aSupply
{
    [hvHw readAdc:aSupply];
}

- (void) readDac:(id)aSupply
{
    [hvHw readDac:aSupply];
}


- (void) readCurrent:(id)aSupply
{
    [hvHw readCurrent:aSupply];
}

- (uint32_t) readRelayMask
{
    return [hvHw readRelayMask];
}

- (uint32_t) lowPowerOn
{
    return [hvHw lowPowerOn];
}


- (void) resetAdcs
{
    [hvHw resetAdcs];
}

- (uint32_t) muxEventDataId { return muxEventDataId; }
- (void) setMuxEventDataId: (uint32_t) MuxEventDataId
{
    muxEventDataId = MuxEventDataId;
}


- (uint32_t) muxDataId { return muxDataId; }
- (void) setMuxDataId: (uint32_t) MuxDataId
{
    muxDataId = MuxDataId;
}

- (void) setDataIds:(id)assigner
{
    muxEventDataId      = [assigner assignDataIds:kShortForm]; //short form preferred
    muxDataId           = [assigner assignDataIds:kShortForm];
}

- (void) syncDataIdsWith:(id)anotherMux
{
    [self setMuxEventDataId:[anotherMux muxEventDataId]];
    [self setMuxDataId:[anotherMux muxDataId]];
}

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"NcdMuxDecoderForMuxEventReg",             @"decoder",
								 [NSNumber numberWithLong:muxEventDataId],   @"dataId",
								 [NSNumber numberWithBool:NO],               @"variable",
								 [NSNumber numberWithLong:IsShortForm(muxEventDataId)?1:2],@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"MuxEventReg"];
    
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"NcdMuxDecoderForMux",                     @"decoder",
				   [NSNumber numberWithLong:muxDataId],        @"dataId",
				   [NSNumber numberWithBool:NO],               @"variable",
				   [NSNumber numberWithLong:IsShortForm(muxDataId)?1:2],@"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"Mux"];
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
    NSMutableArray* eventGroup = [NSMutableArray array];
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"MuxEventReg",								@"name",
				   [NSNumber numberWithLong:muxEventDataId],   @"dataId",
				   nil];
	[eventGroup addObject:aDictionary];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"Mux",									@"name",		
				   [NSNumber numberWithLong:muxDataId],	@"dataId",
				   [NSNumber numberWithLong:4],			@"maxChannels",
				   nil];
	[eventGroup addObject:aDictionary];
	
	[anEventDictionary setObject:eventGroup forKey:@"NcdMux"];
	
	//these are async scope readouts so add separatly
	if([dataTakers1 count])		[[dataTakers1 objectAtIndex:0] appendEventDictionary:topLevel topLevel:topLevel];
	else if([dataTakers2 count])[[dataTakers2 objectAtIndex:0] appendEventDictionary:topLevel topLevel:topLevel];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"NcdMuxModel"];
    
    //----------------------------------------------------------------------------------------
    //then package our hardware settings...
    short box;
    for(box=0;box<8;box++){
        NcdMuxBoxModel* muxBoxModel = [self objectConnectedTo: NcdMuxConnectors[box]];
        if(muxBoxModel){
            int muxBox = [muxBoxModel muxID];
            [muxBoxModel  startRates];
            
            if([[userInfo objectForKey:@"doinit"]intValue]){
                [muxBoxModel  loadThresholdDacs];
                NSLog(@"Loaded Mux %d Thresholds\n",muxBox);
                [muxBoxModel readThresholds];
                [muxBoxModel statusQuery];
            }
            
            short scopeChannel = [muxBoxModel scopeChan];
            if(scopeChannel == -1){
                NSLog(@"Mux %d will use the scope channel value in the Tube Map\n",muxBox);
            }
            else {
                NSLog(@"Mux %d is connected to scope channel %d\n",muxBox,scopeChannel);
                NSLog(@"Mux %d is ignoring the tube map.\n",muxBox);
            }
            
        }
    }
    
    //have the hv write out
    [[self objectConnectedTo:NcdMuxToHVConnector] runTaskStarted:aDataPacket userInfo:userInfo];
    
    
    dataTakers1 = [[trigger1Group allObjects] retain];	//cache of data takers.
    dataTakers2 = [[trigger2Group allObjects] retain];  //cache of data takers.
    
    
    timingEvent[0] = NO;
    timingEvent[1] = NO;
    badCount = 0;
    
    NSEnumerator* e = [dataTakers1 objectEnumerator];
    id obj;
    while(obj=[e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
    
    e = [dataTakers2 objectEnumerator];
    while(obj=[e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
    
	[self performSelector:@selector(reArm) withObject:nil afterDelay:0];
	NSString* selString;
	switch([muxBoxHw scopeSelection]){
		case 0: selString = @"None"; break;
		case 1: selString = @"A"; break;
		case 2: selString = @"B"; break;
		case 3: selString = @"Toggle"; break;
		default: selString = @"?"; break;
	}
	NSLog(@"Mux controller armed. Scope selection set to: %@\n",selString);
    
    
}


//----------mux global record-----------------------------------
// 0000 0000 0000 0000 0000 0000 0000 0000   32 bit uint32_t
// ^^^^-^------------------------------------ kMuxGType (device type)
//                     ^^^^ ^^^^ ^^^^ ^^^^--- global event register
//--------------------------------------------------------------

//----------mux event record-----------------------------------
// 0000 0000 0000 0000 0000 0000 0000 0000   32 bit uint32_t
// ^^^^-^------------------------------------ kMuxType (device type + 1)
//       ^----------------------------------- spare
//        ^^ ^------------------------------- muxbox
//            ^^^ ^^^------------------------ scope bits from event register
//                   ^ ^^^^------------------ spare
//                          ^^^^ ^^^^ ^^^^--- chan hit register for this mux
//--------------------------------------------------------------
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    id scopeA = [dataTakers1 lastObject];
    id scopeB = [dataTakers2 lastObject];
    NSString* errorLocation = @"No Error";
    
    @try { 
        
		
		NSNumber* isSAMEventNumber= [userInfo objectForKey:@"MSAMEvent"];
		int mSamPrescale = [[userInfo objectForKey:@"MSAMPrescale"] intValue];
		if(mSamPrescale==0)mSamPrescale = 50;
		
		BOOL usingSAM = (isSAMEventNumber!=nil);
		BOOL isSAMEvent = NO;
		if(usingSAM)isSAMEvent = [isSAMEventNumber boolValue];
		
		//read the event reg to see if a mux box has fired.
		unsigned short aHitDR = 0;
		unsigned short aSelectedMuxDR;
		errorLocation = @"reading Event Register";
		if ([muxBoxHw getEventRegister:&aHitDR] == kEventHeaderToDr) {
			if (aHitDR & kDataByteMask){
				uint32_t dataWord[2];
				//pack the mux global event reg using the first device type
                uint32_t len;
                if(IsShortForm(muxEventDataId)){
                    dataWord[0] = muxEventDataId | aHitDR;
                    len = 1;
                }
                else {
                    len = 2;
                    dataWord[0] = muxEventDataId | len;
                    dataWord[1] = aHitDR;
                }
                [aDataPacket addLongsToFrameBuffer:dataWord length:len];
				//ok, a box has fired, now see which channels fired. use the second device type
				uint32_t scopeBitsMask = (aHitDR & 0x00003f00)<<9;
				short bus;
				for (bus=0; bus<8; bus++){
					if (aHitDR & (1<<bus)) {
						NcdMuxBoxModel* muxBoxModel = [self objectConnectedTo: NcdMuxConnectors[bus]];
						if(muxBoxModel){
							errorLocation = selectError[bus];
							if ([muxBoxHw getSelectedMux:&aSelectedMuxDR mux:bus] == kSingleDataToDr){
								unsigned short chanHitMask = ((kChanHitRegisterMask & ~aSelectedMuxDR) & 0x00000fff);
								if(IsShortForm(muxDataId)){
                                    len = 1;
                                    dataWord[0] = muxDataId | ((bus & 0x00000007)<<kMuxBusNumberDataRecordShift) | scopeBitsMask | chanHitMask;
								}
                                else {
                                    len = 2;
                                    dataWord[0] = muxDataId | len;
                                    dataWord[1] = ((bus & 0x00000007)<<kMuxBusNumberDataRecordShift) | scopeBitsMask | chanHitMask;
                                }
                                [aDataPacket addLongsToFrameBuffer:dataWord length:len];
								
								[muxBoxModel incChanCounts:chanHitMask];
							}
							else {
								NSLogError(@"",@"Mux Error",@"Reading Mux Box.",nil);
								[NSException raise:@"Mux Error" format:@"Reading Mux Box"];
							}
						}
						else {
							eventReadError++;
							NSLogError(@"",@"Mux Error",[NSString stringWithFormat:@"Non-Existent Box on bus: (%d)",bus],nil);
							//[NSException raise:@"Mux Error" format:@"Reading Event Reg"];
						}
						
						
					}
					
				}
                
				if(aHitDR == 0){
					NSLogError(@"",@"Mux Error",@"Global Reg == 0!",nil);
				}
				
				BOOL readScope;
				
				readScope = NO;
				if((aHitDR & kScopeATrigMask)){
					if(usingSAM){
						if(isSAMEvent){
							readScope = YES;
						}
						else {
							if(badCount>=mSamPrescale){
								readScope = YES;
								badCount = 0;
							}
							else{
								badCount++;
								if(![scopeA runInProgress])[scopeA oscArmScope];
							}
						}
					}
					else {
						readScope = YES;
					}
				}
				
				if(readScope){
					if(![scopeA runInProgress]){
						[self readOutScope:0 usingPacket:aDataPacket hitDR:aHitDR userInfo:userInfo];
					}
					/*else {
					 //should not happen very often
					 NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];
					 while([scopeA runInProgress]){
					 //wait for the scope to finish, but not forever.
					 if([NSDate timeIntervalSinceReferenceDate]-t1 > .2){
					 NSLogError(@"",@"Mux Error",@"Scope A thread busy timeout!",nil);
					 break;
					 }
					 }
					 if(![scopeA runInProgress]){
					 [self readOutScope:0 usingPacket:aDataPacket hitDR:aHitDR userInfo:userInfo];
					 }
					 else NSLogError(@"",@"Mux Error",@"Scope A busy/Thread busy conflict!",nil);
					 }*/
				}
				else {
					if(!usingSAM && !(aHitDR & kScopeBTrigMask)){
						if(timingEvent[0] && [NSDate timeIntervalSinceReferenceDate] - timeOfLastScopeEvent[0] > 5){
							[scopeA oscArmScope];
							NSLogError(@"",@"Mux Error",@"Forced rearm of ScopeA!",nil);
							timingEvent[0] = NO;
						}
					}
				}
				
				
				readScope = NO;
				if((aHitDR & kScopeBTrigMask)){
					if(usingSAM){
						if(isSAMEvent){
							readScope = YES;
						}
						else {
							if(badCount>=mSamPrescale){
								readScope = YES;
								badCount = 0;
							}
							else{
								badCount++;
								if(![scopeB runInProgress])[scopeB oscArmScope];
							}
						}
					}
					else {
						readScope = YES;
					}
				}
				
				if(readScope){
					if(![scopeB runInProgress]){
						[self readOutScope:1 usingPacket:aDataPacket hitDR:aHitDR userInfo:userInfo];
					}
					/*else {
					 //should not happen very often
					 NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];
					 while([scopeB runInProgress]){
					 //wait for the scope to finish, but not forever.
					 if([NSDate timeIntervalSinceReferenceDate]-t1 > .2){
					 NSLogError(@"",@"Mux Error",@"Scope B thread busy timeout!",nil);
					 break;
					 }
					 }
					 if(![scopeB runInProgress]){
					 [self readOutScope:1 usingPacket:aDataPacket hitDR:aHitDR userInfo:userInfo];
					 }
					 else NSLogError(@"",@"Mux Error",@"Scope B busy/Thread busy conflict!",nil);
					 }*/
				}
				else if(!usingSAM && !(aHitDR & kScopeATrigMask)){
					if(timingEvent[1] && [NSDate timeIntervalSinceReferenceDate] - timeOfLastScopeEvent[1] > 5){
						[scopeB oscArmScope];
						NSLogError(@"",@"Mux Error",@"Forced rearm of ScopeB!",nil);
						timingEvent[1] = NO;
					}
				}
				
				if((aHitDR & kScopeATrigMask) && (aHitDR & kScopeBTrigMask)){
					//error that should never happen
					NSLogError(@"",@"Mux Error",@"Both scope A and B selected at same time!",nil);
				}
				
				//done with read so rearm the mux box.
				[self reArm];
			}
		}
		else {
			eventReadError++;
			[[NSNotificationCenter defaultCenter]
			 postNotificationName:NcdMuxErrorCountChangedNotification
			 object:self];
			NSLogError(@"",@"Mux Error",@"Event Reg Read Failed.",nil);
			[NSException raise:@"Mux Error" format:@"Reading Event Reg"];
		}
		
		
	}
	@catch(NSException* localException) { 
		NSLogError(@"",@"Mux Error",errorLocation,nil);
		[self reArm];
		[localException raise];
		
    }
    
}

- (void) readOutScope:(int)scope usingPacket:(ORDataPacket*)aDataPacket hitDR:(unsigned short)aHitDR userInfo:(NSDictionary*)userInfo
{
    unsigned char aMask;
    id theScopeObject;
    if(scope ==0)	theScopeObject = [dataTakers1 lastObject];
    else 		theScopeObject = [dataTakers2 lastObject];
    
    if([self getScopeMask:&aMask forScope:scope eventReg:aHitDR]){
        NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithChar:aMask],@"ChannelMask",[userInfo objectForKey:@"GTID"],@"GTID",nil];
        [self takeScopeData:aDataPacket onScope:theScopeObject userInfo:params];
    }
    timeOfLastScopeEvent[scope] = [NSDate timeIntervalSinceReferenceDate];
    timingEvent[scope] = YES;
}


- (void) takeScopeData:(ORDataPacket*)aDataPacket onScope:(id)scope userInfo:(NSDictionary*)userInfo
{
    @try {
        [scope takeData:aDataPacket userInfo:userInfo];
	}
	@catch(NSException* localException) {
        NSLogError(@"",@"Mux Error",@"Scope Read Exception.",nil);
        [localException raise];
    }
}

//for testing only
- (void) readAndDumpEvent
{
    
    @try { 
		
		//read the event reg to see if a mux box has fired.
		unsigned short aHitDR = 0;
		unsigned short aSelectedMuxDR;
		if ([muxBoxHw getEventRegister:&aHitDR] == kEventHeaderToDr) {
			if (aHitDR & kDataByteMask){
				NSLog(@"hit reg: 0x%0x\n",(aHitDR & 0x0000ffff));
				//ok, a box has fired, now see which channels fired. use the second device type
				uint32_t scopeBitsMask = (aHitDR & 0x00003f00)<<9;
				short box;
				for (box=0; box<8; box++){
					if (aHitDR & (1<<box)) {
                        NcdMuxBoxModel* muxBoxModel = [self objectConnectedTo: NcdMuxConnectors[box]];
						if(muxBoxModel){
							if ([muxBoxHw getSelectedMux:&aSelectedMuxDR mux:box] == kSingleDataToDr){
								unsigned short chanHitMask = ((kChanHitRegisterMask & ~aSelectedMuxDR) & 0x00000fff);
								NSLog(@"Mux %2d ScopeBits: 0x0x%x chanHitMask: 0x%0x\n",box,scopeBitsMask,chanHitMask);
							}
						}
						else {
							eventReadError++;
							NSLogError(@"",@"Mux Error",@"Event Reg Read Failed.",nil);
							[NSException raise:@"Mux Error" format:@"Reading Event Reg"];
						}
					}
					
				}
				
				if(aHitDR & kScopeATrigMask){
					unsigned char aMask;
					if([self getScopeMask:&aMask forScope:0 eventReg:aHitDR]){
						NSLog(@"Scope A channel Mask: 0x0x\n",aMask);
					}
					else {
						NSLog(@"No scope defined in the hw map\n");
					}
				}
				
				else if(aHitDR & kScopeBTrigMask){
					unsigned char aMask;
					if([self getScopeMask:&aMask forScope:1 eventReg:aHitDR]){
						NSLog(@"Scope B channel Mask: 0x0x\n",aMask);
					}
					else {
						NSLog(@"No scope defined in the hw map\n");
					}
				}
				
				//rearm the mux box.
				[self reArm];
			}
			else NSLog(@"no event\n");
		}
		else {
			eventReadError++;
			[[NSNotificationCenter defaultCenter]
			 postNotificationName:NcdMuxErrorCountChangedNotification
			 object:self];
			NSLogError(@"",@"Mux Error",@"Event Reg Read Failed.",nil);
			[NSException raise:@"Mux Error" format:@"Reading Event Reg"];
		}
		
		
	}
	@catch(NSException* localException) { 
		[self reArm];
		[localException raise];
		
    }
}

- (void) disableScopes:(NSNotification*)aNote
{
    [muxLock lock];
    
    if([muxBoxHw disableScopes] != kControllerReset){
        if([muxBoxHw disableScopes] != kControllerReset){
            armError++;
            [[NSNotificationCenter defaultCenter]
			 postNotificationName:NcdMuxErrorCountChangedNotification
			 object:self];
            NSLogError(@"",@"Mux Error",@"DisAarm error.",nil);
            [muxLock unlock];
            [NSException raise:@"Mux Error" format:@"DisAarm Error"];
        }
    }
    [muxLock unlock];	
}

- (void) reArmScopes:(NSNotification*)aNote
{
	[self reArm];
}


- (void) reset
{
    [self reArm];
}

- (void) reArm
{
    [muxLock lock];
    
    if([muxBoxHw armScopeSelection] != kControllerReset){
        if([muxBoxHw armScopeSelection] != kControllerReset){
            armError++;
            [[NSNotificationCenter defaultCenter]
			 postNotificationName:NcdMuxErrorCountChangedNotification
			 object:self];
            NSLogError(@"",@"Mux Error",@"Rearm error.",nil);
            [muxLock unlock];
            [NSException raise:@"Mux Error" format:@"Arm Error"];
        }
    }
    [muxLock unlock];
    
}

//the first 8 bits in the eventRegister represent Mux boxes with events.  A 1 in bit X indicates an
//event on Mux X
- (BOOL) getScopeMask:(unsigned char*)aMask forScope:(short) scope eventReg:(unsigned short) aMuxEventRegister
{
    unsigned char theMask = 0;
    short mux;
    for(mux=0;mux<8;mux++){
        if((aMuxEventRegister>>mux) & 0x1){
            NcdMuxBoxModel* muxBoxModel = [self objectConnectedTo: NcdMuxConnectors[mux]];
            if(muxBoxModel){
                short channel = [muxBoxModel scopeChan];
                if(channel == -1){
                    channel = [detector getScopeChannelForMux:mux scope:scope];
                }
                if((channel>=0) && (channel<=3)){
                    theMask |= 1<<channel;
                }
                else return NO;
            }
            else return NO;
        }
    }
    *aMask = theMask;
    return YES;
}



- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    
	//  [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    NSEnumerator* e = [dataTakers1 objectEnumerator];
    id obj;
    while(obj=[e nextObject]){
        [obj runTaskStopped:aDataPacket userInfo:userInfo];
    }
    
    e = [dataTakers2 objectEnumerator];
    while(obj=[e nextObject]){
        [obj runTaskStopped:aDataPacket userInfo:userInfo];
    }
    
    [dataTakers1 release];
    [dataTakers2 release];
    dataTakers1 = nil;
	dataTakers2 = nil;
	
    short box;
    for(box=0;box<8;box++){
        NcdMuxBoxModel* muxBoxModel = [self objectConnectedTo: NcdMuxConnectors[box]];
        if(muxBoxModel){
            [muxBoxModel  stopRates];
        }
    }
}

- (NSMutableArray*) children {
    //methods exists to give common interface across all objects for display in lists
    return [NSMutableArray arrayWithObjects:trigger1Group,trigger2Group,nil];
}


- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [trigger1Group saveUsingFile:aFile];
    [trigger2Group saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setTrigger1Group:[[[ORReadOutList alloc] initWithIdentifier:@"Scope A"]autorelease]];
    [self setTrigger2Group:[[[ORReadOutList alloc] initWithIdentifier:@"Scope B"]autorelease]];
    [trigger1Group loadUsingFile:aFile];
    [trigger2Group loadUsingFile:aFile];
}


#pragma mark ¥¥¥Archival
static NSString *NcdMuxMuxBoxHw 	 = @"Ncd Mux Mux Box Hardware";
static NSString *NcdMuxHVHw 		 = @"Ncd Mux HV Hardware";
static NSString *NcdMuxScopeSel 	 = @"Ncd Mux Scope Selection";
static NSString *NcdMuxTriggerGroup1 = @"NcdMux Trigger Group 1";
static NSString *NcdMuxTriggerGroup2 = @" NcdMuxTrigger Group 2";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setMuxBoxHw:[decoder decodeObjectForKey:NcdMuxMuxBoxHw]];
    [self setHvHw:[decoder decodeObjectForKey:NcdMuxHVHw]];
    [self setScopeSelection:[decoder decodeIntForKey:NcdMuxScopeSel]];
    
    [self setTrigger1Group:[decoder decodeObjectForKey:NcdMuxTriggerGroup1]];
    [self setTrigger2Group:[decoder decodeObjectForKey:NcdMuxTriggerGroup2]];
    
    [self setDetector:[NcdDetector sharedInstance]];
	// [detector setDelegate:self];
    muxLock = [[NSLock alloc] init];
	[self registerNotificationObservers];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:[self scopeSelection] forKey:NcdMuxScopeSel];
    [encoder encodeObject:[self muxBoxHw] forKey:NcdMuxMuxBoxHw];
    [encoder encodeObject:[self hvHw] forKey:NcdMuxHVHw];
    [encoder encodeObject:[self trigger1Group] forKey:NcdMuxTriggerGroup1];
    [encoder encodeObject:[self trigger2Group] forKey:NcdMuxTriggerGroup2];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
    id scopeA = [[trigger1Group allObjects] lastObject];
    id scopeB = [[trigger2Group allObjects] lastObject];
    if(scopeA){
		NSMutableDictionary* scopeADictionary = [NSMutableDictionary dictionary];
        [scopeADictionary setObject:@"ScopeMapping" forKey:@"Class Name"];
		[scopeADictionary setObject:[NSNumber numberWithInt:[scopeA primaryAddress]]  forKey:@"primaryAddress"];
		[scopeADictionary setObject:[NSNumber numberWithInt:0]  forKey:@"scopeNumber"];
		[objDictionary setObject:scopeADictionary forKey:@"ScopeA"];
	}
    if(scopeB){
		NSMutableDictionary* scopeBDictionary = [NSMutableDictionary dictionary];
        [scopeBDictionary setObject:@"ScopeMapping" forKey:@"Class Name"];
		[scopeBDictionary setObject:[NSNumber numberWithInt:[scopeB primaryAddress]]  forKey:@"primaryAddress"];
		[scopeBDictionary setObject:[NSNumber numberWithInt:1]  forKey:@"scopeNumber"];
		[objDictionary setObject:scopeBDictionary forKey:@"ScopeB"];
	}
    [dictionary setObject:objDictionary forKey:NSStringFromClass([self class])];
    return objDictionary;
}


@end
