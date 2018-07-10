//
//  ORM321Model.cp
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
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
#import "ORM321Model.h"
#import "ORIPCarrierModel.h"
#import "ORMotorPattern.h"
#import "ORMotorSweeper.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORMotorModel.h"

#define kM321DualPortMemoryOffset   0x00
#define kM321PageRegOffset          0x80
#define kM321ControlRegOffset       0x82
#define kM321EEPROMOffset           0xFE

NSString* ORM321FourPhaseChangedNotification		= @"ORM321FourPhaseChangedNotification";

@interface ORM321Model (private)
- (void) sendCmd:(m321Cmd*)aCmd  result:(m321Cmd*)result numInArgs:(int)ni numOutArgs:(int)no;
- (BOOL) waitForCmdToFinish;
- (void) motorStarted:(id)aMotor;
- (void) pollMotorStatus;
@end


@implementation ORM321Model

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    hwLock = [[NSLock alloc] init];
    
    [[self undoManager] enableUndoRegistration];
    return self;
}

-(void)dealloc
{
    [hwLock release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    [self registerNotificationObservers];
    [self performSelector:@selector(checkHardwareConfig:) withObject:nil afterDelay:5];
}

- (void)sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super sleep];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"M321"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORM321Controller"];
}

- (NSString*) helpURL
{
	return @"VME/M321.html";
}

- (void) makeConnectors
{
    //make and cache our connectors. However these connector will be 'owned' by another object (the crate)
    //so we don't add them to our list of connectors. they will be added to the true owner later.
    [self setConnector:  [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    
    [[self connector] setConnectorImageType:kDefaultImage];
    [[self connector] setOffColor:[NSColor blueColor]];
    [[self connector] setConnectorType: 'M2  ' ];
    [[self connector] addRestrictedConnectionType: 'M1  ' ]; //can only connect to M Carrier inputs
    
    [self makeConnector2];
}

- (void) makeConnector2
{
    [self setConnector2: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    [[self connector2] setConnectorImageType:kDefaultImage];
    [[self connector2] setOffColor:[NSColor blueColor]];
    [[self connector2] setConnectorType: 'M2  ' ];
    [[self connector2] addRestrictedConnectionType: 'M1  ' ]; //can only connect to M Carrier inputs
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [super guardian:aGuardian positionConnectorsForCard:aCard];
    [aGuardian connector:[self connector2] tweakPositionByX:0 byY:-10];
}


- (void)assignTag:(id)aMotor
{
    if([connector connectedObject] == aMotor)[aMotor setTag:0];
    else if([connector2 connectedObject] == aMotor)[aMotor setTag:1];
    else [aMotor setTag:-1];
    
}

- (void) calcBaseAddress
{
	[self setBaseAddress: [[self guardian] baseAddress]+ [self slot] * 0x200];
	
}

#pragma mark ¥¥¥Notifications
-(void)registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver: self
                     selector: @selector(checkHardwareConfig:)
                         name: @"VmePowerRestoredNotification"
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(checkHardwareConfig:)
                         name: ORDocumentLoadedNotification
                       object: nil];
    
}


- (void) checkHardwareConfig:(NSNotification*)aNote
{
    [hwLock lock];
    
    m321Cmd theCmd;
    theCmd.cmd = kM361_Version;
    
    @try {
        [self sendCmd:&theCmd result:&theCmd numInArgs:0 numOutArgs:3];
        [self setFourPhase:theCmd.paramList[2]];
        
        
    }
	@catch(NSException* localException) {
	}
	
	[hwLock unlock];
	
	@try {    
		id motorA = [connector connectedObject];
		id motorB = [connector2 connectedObject];
		[self readMotor:motorA];
		
		if(!fourPhase){
			[self readMotor:motorB];
			if(![self connector2]){
				[self makeConnector2];
				[[guardian guardian] assumeDisplayOf:[self connector2]];
				[self setGuardian:guardian];
				
			}
		}
		else {
			[[self undoManager] disableUndoRegistration];
			[motorB disconnectOtherMotors];
			[[[self guardian] guardian] removeDisplayOf:[self connector2]];
			[[self connector2] disconnect];
			[self setConnector2:nil];
			[[self undoManager] enableUndoRegistration];
		}
	}
	@catch(NSException* localException) {
	}
	
}

#pragma mark ¥¥¥Accessors
- (BOOL)fourPhase
{
    return fourPhase;
}
- (void)setFourPhase:(BOOL)flag
{
    fourPhase = flag;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORM321FourPhaseChangedNotification
	 object:self];
}

#pragma mark ¥¥¥Hardware Access
- (void) status
{
    
    @try {
        [hwLock lock];
        unsigned short aValue;
        [[guardian adapter] readWordBlock:&aValue
								atAddress:[self baseAddress] + kM361_ControlRegister
								numToRead:1
							   withAddMod:[guardian addressModifier]
							usingAddSpace:kAccessRemoteIO];
        
        
        NSLog(@"M361 %@ Status: 0x%0x\n",[self identifier],aValue&0xf);
        
        unsigned short irq = [self readIRQ];
        if(irq == kM361_IrqBlank)	 NSLog(@"IRQ is blank, nothing to report\n");
        if(irq & kM361_IrqCmdDone)	 NSLog(@"IRQ: Cmd executed\n");
        if(irq & kM361_IrqBreakPtA)	 NSLog(@"IRQ: Breakpoint Motor A\n");
        if(irq & kM361_IrqBreakPtB)	 NSLog(@"IRQ: Breakpoint Motor B\n");
        if(irq & kM361_IrqTrajA)	 NSLog(@"IRQ: Trajectory Complete Motor A\n");
        if(irq & kM361_IrqTrajB)	 NSLog(@"IRQ: Trajectory Complete Motor B\n");
        if(irq & kM361_IrqHomeA)	 NSLog(@"IRQ: Home Dectected Motor A\n");
        if(irq & kM361_IrqHomeB)	 NSLog(@"IRQ: Home Dectected Motor B\n");
        if(irq & kM361_IrqException) NSLog(@"IRQ: Internal Exception Error\n");
        [hwLock unlock];
    }
	@catch(NSException* localException) {
        [hwLock unlock];
        [localException raise];
    }
}

- (void) probe
{
    @try {
        [hwLock lock];
        NSLog(@"Probing M Carrier Board %@ at <0x%08x>\n",[self identifier],[self baseAddress]);
        m321Cmd theCmd;
        theCmd.cmd = kM361_Version;
        
        [self sendCmd:&theCmd result:&theCmd numInArgs:0 numOutArgs:3];
        NSLog(@"Firmware Version: %d.%d\n",theCmd.paramList[0]/10,theCmd.paramList[0]%10);
        NSLog(@"Module Type     : %d\n",theCmd.paramList[1]);
        NSLog(@"Control Mode    : %@ Mode\n",theCmd.paramList[2]?@"4-Phase Mode":@"2-Phase");
        
        [self setFourPhase:theCmd.paramList[2]];
        [hwLock unlock];
    }
	@catch(NSException* localException) {
        [hwLock unlock];
        [localException raise];
    }
}

- (void) sync
{
    @try {
        [hwLock lock];
        m321Cmd theCmd;
        theCmd.cmd = kM361_Sync;
        
        [self sendCmd:&theCmd result:&theCmd numInArgs:0 numOutArgs:1];
        NSLog(@"%@ (M361) Appears Alive\n",[self identifier]);
        [hwLock unlock];
    }
	@catch(NSException* localException) {
        [hwLock unlock];
        [localException raise];
    }
    
}

- (void) loadBreakPoint:(int)amount absolute:(BOOL)useAbs motor:(id)aMotor
{
    
    @try {
        [hwLock lock];
        m321Cmd theCmd;
        if([aMotor tag] == kMotorA){
            theCmd.cmd  = useAbs ? kM361_SetBrkAbsA : kM361_SetBrkRelA;
        }
        else {
            theCmd.cmd  = useAbs ? kM361_SetBrkAbsB : kM361_SetBrkRelB;
        }
        theCmd.paramList[0] = (amount & 0xFFFF0000) >> 16; //MSB part
        theCmd.paramList[1] = amount & 0x0000FFFF; //LSB part
        
        [self sendCmd:&theCmd result:&theCmd numInArgs:2 numOutArgs:0];
        [hwLock unlock];
    }
	@catch(NSException* localException) {
        [hwLock unlock];
        [localException raise];
    }
}


- (void) loadStepCount:(long)amount motor:(id)aMotor
{
    @try {
        [hwLock lock];
        m321Cmd theCmd;
        theCmd.cmd =  ([aMotor tag] ? kM361_SetPosB : kM361_SetPosA);
        theCmd.paramList[0] = (amount & 0xFFFF0000) >> 16; //MSB part
        theCmd.paramList[1] = amount & 0x0000FFFF; //LSB part
        
        [self sendCmd:&theCmd result:&theCmd numInArgs:2 numOutArgs:0];
        [hwLock unlock];
    }
	@catch(NSException* localException) {
        [hwLock unlock];
        [localException raise];
    }
}

- (void) readMotor:(id)aMotor
{
    @try {
        [hwLock lock];
        m321Cmd theCmd;
        theCmd.cmd =  ([aMotor tag] ? kM361_GetPosB : kM361_GetPosA);
        [self sendCmd:&theCmd result:&theCmd numInArgs:0 numOutArgs:2];
        [aMotor setMotorPosition: (unsigned long)theCmd.paramList[0]<<16 | theCmd.paramList[1]];
        [hwLock unlock];
    }
	@catch(NSException* localException) {
        [hwLock unlock];
        [localException raise];
    }
}

- (BOOL) isMotorMoving:(id)aMotor
{
    return !([self readIRQ] & ([aMotor tag]==kMotorA ? kM361_IrqTrajA : kM361_IrqTrajB));
}

- (void) moveMotor:(id)aMotor amount:(long)amount;
{
    unsigned short theCommand = ([aMotor tag] ? kM361_ProfileRelB : kM361_ProfileRelA);
    [self executeMotorCmd:theCommand
                    motor:aMotor
                 riseFreq:[aMotor riseFreq]
                driveFreq:[aMotor driveFreq]
             acceleration:[aMotor acceleration]
                    steps:amount];
}

- (void) moveMotor:(id)aMotor to:(long)aPosition
{
    unsigned short theCommand = ([aMotor tag] ? kM361_ProfileAbsB : kM361_ProfileAbsA);
    [self executeMotorCmd:theCommand
                    motor:aMotor
                 riseFreq:[aMotor riseFreq]
                driveFreq:[aMotor driveFreq]
             acceleration:[aMotor acceleration]
                    steps:aPosition];
}


- (void) seekHome:(long)amount motor:(id)aMotor;
{
    if(amount==0)return;
    
    [self resetIRQ:aMotor];
    [self loadStepMode:[aMotor stepMode] motor:aMotor];
    [self loadHoldCurrent:[aMotor holdCurrent] motor:aMotor];
    [self loadBreakPoint:[aMotor breakPoint] absolute:[aMotor absoluteBrkPt] motor:aMotor];
    
    @try {
        [hwLock lock];
        m321Cmd theCmd;
        theCmd.cmd  = ([aMotor tag] ? kM361_SeekHomeB : kM361_SeekHomeA);
        
        unsigned long riseFreq = [aMotor riseFreq];
        theCmd.paramList[0] = (riseFreq & 0xFFFF0000) >> 16; //MSB part
        theCmd.paramList[1] = riseFreq & 0x0000FFFF; //LSB part
        
        unsigned long driveFreq = [aMotor driveFreq];
        theCmd.paramList[2] = (driveFreq & 0xFFFF0000) >> 16; //MSB part
        theCmd.paramList[3] = driveFreq & 0x0000FFFF; //LSB part
        
        unsigned long acceleration = [aMotor acceleration];
        theCmd.paramList[4] = (acceleration & 0xFFFF0000) >> 16; //MSB part
        theCmd.paramList[5] = acceleration & 0x0000FFFF; //LSB part
        
        long seekAmount = [aMotor seekAmount];
        theCmd.paramList[6] = (seekAmount & 0xFFFF0000) >> 16; //MSB part
        theCmd.paramList[7] = seekAmount & 0x0000FFFF; //LSB part
        
        theCmd.paramList[8] = [aMotor risingEdge]; 
        
        [self sendCmd:&theCmd result:&theCmd numInArgs:9 numOutArgs:0];
        [hwLock unlock];
        
        [self motorStarted:aMotor];
    }
	@catch(NSException* localException) {
        [hwLock unlock];
        [localException raise];
    }
}

- (void)  readHome:(id)aMotor
{
    @try {
        [hwLock lock];
        m321Cmd theCmd;
        
        theCmd.cmd  = ([aMotor tag] ? kM361_ReadHomeB : kM361_ReadHomeA);
        [self sendCmd:&theCmd result:&theCmd numInArgs:0 numOutArgs:1];
        [aMotor setHomeDetected:theCmd.paramList[1]];
        [hwLock unlock];
    }
	@catch(NSException* localException) {
        [hwLock unlock];
        [localException raise];
    }
}

- (void) stopMotor:(id)aMotor
{
    [aMotor motorStopped];	
    [self resetIRQ:aMotor];
    
    @try {
        [hwLock lock];
        m321Cmd theCmd;
        theCmd.cmd  = ([aMotor tag]? kM361_AbortB : kM361_AbortA);
        [self sendCmd:&theCmd result:&theCmd numInArgs:0 numOutArgs:0];
        [hwLock unlock];
    }
	@catch(NSException* localException) {
        [hwLock unlock];
        [localException raise];
    }
    
}

- (void) startMotor:(id)aMotor
{
    [self readMotor:aMotor];
    if(![aMotor absoluteMotion] && [aMotor xyPosition]==0)return;
    if([aMotor absoluteMotion] && [aMotor xyPosition]==[aMotor motorPosition])return;
    
    unsigned short theCommand;
    if([aMotor tag] == kMotorA){
        theCommand  = [aMotor absoluteMotion] ? kM361_ProfileAbsA : kM361_ProfileRelA;
    }
    else {
        theCommand  = [aMotor absoluteMotion] ? kM361_ProfileAbsB : kM361_ProfileRelB;
    }
    [self executeMotorCmd:theCommand
                    motor:aMotor
                 riseFreq:[aMotor riseFreq]
                driveFreq:[aMotor driveFreq]
             acceleration:[aMotor acceleration]
                    steps:[aMotor xyPosition]];
    
}



- (void) executeMotorCmd:(unsigned short) theCommand 
                   motor:(id)aMotor
                riseFreq:(unsigned long) theRiseFreq 
               driveFreq:(unsigned long) theDriveFreq
            acceleration:(unsigned long) theAcceleration
                   steps:(long)thePosition
{
    
    unsigned long ulValue;
    m321Cmd theCmd;
    theCmd.cmd = theCommand;
    
    [self resetIRQ:aMotor];
    [self loadStepMode:[aMotor stepMode] motor:aMotor];
    [self loadHoldCurrent:[aMotor holdCurrent] motor:aMotor];
    [self loadBreakPoint:[aMotor breakPoint] absolute:[aMotor absoluteBrkPt] motor:aMotor];
    
    @try {
        [hwLock lock];
        ulValue = theRiseFreq;
        theCmd.paramList[0] = (ulValue & 0xFFFF0000) >> 16; //MSB part
        theCmd.paramList[1] = ulValue & 0x0000FFFF; //LSB part
        
        ulValue = theDriveFreq;
        theCmd.paramList[2] = (ulValue & 0xFFFF0000) >> 16; //MSB part
        theCmd.paramList[3] = ulValue & 0x0000FFFF; //LSB part
        
        ulValue = theAcceleration;
        theCmd.paramList[4] = (ulValue & 0xFFFF0000) >> 16; //MSB part
        theCmd.paramList[5] = ulValue & 0x0000FFFF; //LSB part
        
        theCmd.paramList[6] = (thePosition & 0xFFFF0000) >> 16; //MSB part
        theCmd.paramList[7] = thePosition & 0x0000FFFF; //LSB part
        
        [self sendCmd:&theCmd result:&theCmd numInArgs:8 numOutArgs:0];
        
        [hwLock unlock];
        
        [self motorStarted:aMotor];
        
    }
	@catch(NSException* localException) {
        [hwLock unlock];
        [localException raise];
    }
}

- (void) loadHoldCurrent:(long)amount motor:(id)aMotor;
{
    @try {
        [hwLock lock];
        
        m321Cmd theCmd;
        theCmd.cmd  = ([aMotor tag] ? kM361_SetHoldCurrB : kM361_SetHoldCurrA);
        theCmd.paramList[0] = amount;
        
        [self sendCmd:&theCmd result:&theCmd numInArgs:1 numOutArgs:0];
        [hwLock unlock];
    }
	@catch(NSException* localException) {
        [hwLock unlock];
        [localException raise];
    }
}

- (void) loadStepMode:(int)mode motor:(id)aMotor;
{
    @try {
        [hwLock lock];
        m321Cmd theCmd;
        theCmd.cmd  = ([aMotor tag] ? kM361_SetModeB : kM361_SetModeA);
        theCmd.paramList[0] = mode;
        
        [self sendCmd:&theCmd result:&theCmd numInArgs:1 numOutArgs:0];
        [hwLock unlock];
    }
	@catch(NSException* localException) {
        [hwLock unlock];
        [localException raise];
    }
}

- (void)resetIRQ:(id)aMotor
{
    unsigned short irqValue = [self readIRQ];
    int theMotorTag = [aMotor tag];
    unsigned short mask;
    if(theMotorTag==0){
        mask = kM361_IrqBreakPtA | kM361_IrqTrajA | kM361_IrqHomeA;
    }
    else {
        mask = kM361_IrqBreakPtB | kM361_IrqTrajB | kM361_IrqHomeB;
    }
    irqValue &= ~mask;
    [[guardian adapter] writeWordBlock:&irqValue
							 atAddress:[self baseAddress] + kM361_IrqOffset
							numToWrite:1
							withAddMod:[guardian addressModifier]
						 usingAddSpace:kAccessRemoteIO];
}

- (unsigned short) readIRQ
{
    unsigned short aValue = 0;
    [[guardian adapter] readWordBlock:&aValue
							atAddress:[self baseAddress] + kM361_IrqOffset
							numToRead:1
						   withAddMod:[guardian addressModifier]
						usingAddSpace:kAccessRemoteIO];
    
    return aValue & 0x00ff;
}

- (NSString*) translatedErrorCode:(unsigned short)aCode
{
    switch(aCode){
        case kM361_NoError:           return@"No error ";  
        case kM361_Violation:         return@"Protocal Violation"; 
        case kM361_UnknownCmd:        return@"Unknown Cmd";    
        case kM361_PRange:            return@"Param Out Of Range"; 
        case kM361_ExcpError:         return@"General Exception Error"; 
        case kM361_LocalBusError:     return@"Local Bus Error"; 
        case kM361_LocalAddError:     return@"Local Address Error"; 
        case kM361_LocIll:            return@"Illegal Instruction"; 
        case kM361_SpurInt:           return@"Spurious Interrupt"; 
        case kM361_InvReq:            return@"Invalid Request"; 
        case kM361_Busy:              return@"Waiting For External Triggering"; 
        case kM361_ProfError:         return@"Error In Motion Profile"; 
        case kM361_FlashError:        return@"Flash Program Error"; 
        case kM361_TimeOut:           return@"Locally Defined Timeout"; 
        default:                      return [NSString stringWithFormat:@"unknown error code: 0x%04x",aCode];
    }
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setFourPhase:[decoder decodeIntForKey:@"FourPhase"]];
    [[self undoManager] enableUndoRegistration];
    
    hwLock = [[NSLock alloc] init];
    
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:fourPhase forKey:@"FourPhase"];
}

@end


@implementation ORM321Model (private)
-(void) sendCmd:(m321Cmd*)aCmd result:(m321Cmd*)result numInArgs:(int)numInputs numOutArgs:(int)numOutputs
{
    
    unsigned short aValue;
    
    //write '1' to polling bit in Control Reg to clear polling bit.
    aValue = kM361_PollBit;
    [[guardian adapter] writeWordBlock:&aValue
							 atAddress:[self baseAddress] + kM361_ControlRegister
							numToWrite:1L
							withAddMod:[guardian addressModifier]
						 usingAddSpace:kAccessRemoteIO];
    
    //then set the DPM window to the cmd page.
    aValue = kM361_CmdPage;
    [[guardian adapter] writeWordBlock:&aValue
							 atAddress:[self baseAddress] + kM321PageRegOffset
							numToWrite:1L
							withAddMod:[guardian addressModifier]
						 usingAddSpace:kAccessRemoteIO];
    
    if(numInputs){
        //write the params first
        [[guardian adapter] writeWordBlock:&aCmd->paramList[0]
								 atAddress:[self baseAddress] + kM361_ParamListOffset 
								numToWrite:numInputs
								withAddMod:[guardian addressModifier]
							 usingAddSpace:kAccessRemoteIO];
    }
    
    //write the cmd last
    [[guardian adapter] writeWordBlock:&aCmd->cmd
							 atAddress:[self baseAddress] + kM361_CmdOffset
							numToWrite:1
							withAddMod:[guardian addressModifier]
						 usingAddSpace:kAccessRemoteIO];
    
    if([self waitForCmdToFinish]){
        
        result->cmd = aCmd->cmd;
        //OK the command is done. get the result
        [[guardian adapter] readWordBlock:&result->result
								atAddress:[self baseAddress] + kM361_ResultOffset
								numToRead:1
							   withAddMod:[guardian addressModifier]
							usingAddSpace:kAccessRemoteIO];
        
        [[guardian adapter] readWordBlock:&result->irqstat
								atAddress:[self baseAddress] + kM361_IrqOffset
								numToRead:1
							   withAddMod:[guardian addressModifier]
							usingAddSpace:kAccessRemoteIO];
        
        
        if(result->result != kM361_NoError){
            [NSException raise:@"M361 Cmd Failed" format:@"Error: %@",[self translatedErrorCode:result->result]];
        }
        else if(numOutputs){
            //grab the result output
            [[guardian adapter] readWordBlock:&result->paramList[0]
									atAddress:[self baseAddress] + kM361_ParamListOffset 
									numToRead:numOutputs
								   withAddMod:[guardian addressModifier]
								usingAddSpace:kAccessRemoteIO];
        }
    }
    else {
        result->cmd = kM361_TimeOut;
        [NSException raise:@"M361 Cmd Failed" format:@"Error: %@",[self translatedErrorCode:kM361_TimeOut]];
    }   		
}

- (BOOL) waitForCmdToFinish
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    BOOL completed = NO;
    do {
        unsigned short aValue;
        [[guardian adapter] readWordBlock:&aValue
								atAddress:[self baseAddress] + kM361_ControlRegister
								numToRead:1
							   withAddMod:[guardian addressModifier]
							usingAddSpace:kAccessRemoteIO];
        
        if(aValue & kM361_PollBit){
            completed = YES;
            break;
        }
        else if([NSDate timeIntervalSinceReferenceDate]-start > .5){
            break;
        }
        
    }while (1);
    
    return completed;
}

- (void) motorStarted:(id)aMotor
{
    [aMotor setHomeDetected:NO];
    [aMotor setMotorRunning:YES];
    if(!lastPollTime){
        lastPollTime = [NSDate timeIntervalSinceReferenceDate];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollMotorStatus) object:nil];
    [self performSelector:@selector(pollMotorStatus) withObject:nil];
}

- (void) motorStopped:(id)aMotor
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollMotorStatus) object:nil];
    [aMotor setMotorRunning:NO];
    [self readMotor:aMotor];
}

- (void) pollMotorStatus
{
    unsigned short irq = 0;
    @try {
        irq = [self readIRQ];
    }
	@catch(NSException* localException) {
	}
	
	id motorA = [connector connectedObject];
	id motorB = [connector2 connectedObject];
	
	BOOL timeToGetPosition = ([NSDate timeIntervalSinceReferenceDate] - lastPollTime) > 1.0;
	if([motorA motorRunning]){
		if(irq & kM361_IrqBreakPtA){
			[motorA stopMotor];
			[motorA postBreakPointAlarm];
		}
		if(irq & kM361_IrqTrajA){
			[self motorStopped:motorA];
		}
		if(irq & kM361_IrqHomeA){
			[motorA setHomeDetected:YES];
		}
		
		if(timeToGetPosition)[self readMotor:motorA];
	}
	if([motorB motorRunning]){
		if(irq & kM361_IrqBreakPtB){
			[self stopMotor:motorB];
			[motorB postBreakPointAlarm];
		}
		if(irq & kM361_IrqTrajB){
			[self motorStopped:motorB];
		} 
		if(irq & kM361_IrqHomeB){
			[motorB setHomeDetected:YES];
		}
		if(timeToGetPosition)[self readMotor:motorB];
	}
	
	if([motorA motorRunning] || [motorB motorRunning]){
		if(timeToGetPosition){
			lastPollTime = [NSDate timeIntervalSinceReferenceDate];
		}
		[self performSelector:@selector(pollMotorStatus) withObject:nil afterDelay:.1];
	}
	else {
		lastPollTime = 0;
	}
	
}


@end

