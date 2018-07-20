//
//  ORMotorModel.cp
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
#import "ORMotorModel.h"
#import "ORMotorPattern.h"
#import "ORMotorSweeper.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"

NSString* ORMotorRiseFreqChangedNotification		= @"ORMotorRiseFreqChangedNotification";
NSString* ORMotorDriveFreqChangedNotification		= @"ORMotorDriveFreqChangedNotification";
NSString* ORMotorAccelerationChangedNotification	= @"ORMotorAccelerationChangedNotification";
NSString* ORMotorPositionChangedNotification		= @"ORMotorPositionChangedNotification";
NSString* ORMotorWhichMotorChangedNotification		= @"ORMotorWhichMotorChangedNotification";
NSString* ORMotorAbsoluteMotionChangedNotification	= @"ORMotorAbsoluteMotionChangedNotification";
NSString* ORMotorMultiplierChangedNotification		= @"ORMotorMultiplierChangedNotification";
NSString* ORMotorRisingEdgeChangedNotification		= @"ORMotorRisingEdgeChangedNotification";
NSString* ORMotorStepModeChangedNotification		= @"ORMotorStepModeChangedNotification";
NSString* ORMotorBreakPointChangedNotification		= @"ORMotorBreakPointChangedNotification";
NSString* ORMotorAbsoluteBrkPtChangedNotification	= @"ORMotorAbsoluteBrkPtChangedNotification";
NSString* ORMotorHoldCurrentChangedNotification	    = @"ORMotorHoldCurrentChangedNotification";
NSString* ORMotorStepCountChangedNotification		= @"ORMotorStepCountChangedNotification";
NSString* ORMotorFourPhaseChangedNotification		= @"ORMotorFourPhaseChangedNotification";
NSString* ORMotorMotorRunningChangedNotification	= @"ORMotorMotorRunningChangedNotification";
NSString* ORMotorMotorPositionChangedNotification	= @"ORMotorMotorPositionChangedNotification";
NSString* ORMotorHomeDetectedChangedNotification	= @"ORMotorHomeDetectedChangedNotification";
NSString* ORMotorSeekAmountChangedNotification		= @"ORMotorSeekAmountChangedNotification";
NSString* ORMotorPatternChangedNotification         = @"ORMotorPatternChangedNotification";
NSString* ORMotorPatternFileNameChangedNotification = @"ORMotorPatternFileNameChangedNotification";
NSString* ORMotorUsePatternFileChangedNotification  = @"ORMotorUsePatternFileChangedNotification";
NSString* ORMotorMotorWorkerChangedNotification		= @"ORMotorMotorWorkerChangedNotification";
NSString* ORMotorOptionsMaskChangedNotification		= @"ORMotorOptionsMaskChangedNotification";
NSString* ORMotorPatternTypeChangedNotification		= @"ORMotorPatternTypeChangedNotification";
NSString* ORMotorMotorNameChangedNotification		= @"ORMotorMotorNameChangedNotification";


static NSString *ORMotorControlConnection = @"ORMotorControlConnection";
static NSString *ORMotorLinkOutConnection = @"ORMotorLinkOutConnection";
static NSString *ORMotorLinkInConnection = @"ORMotorLinkInConnection";

@implementation ORMotorModel

#pragma mark ¥¥¥Initialization
- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAbsoluteMotion:YES];
    [self setMultiplierX:1];
    [self setRiseFreq:15];
    [self setDriveFreq:15];
    [self setAcceleration:10000];
    [self setAbsoluteBrkPt:YES];
    [self setBreakPoint:-100];
    [self setSeekAmount:-100];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)dealloc
{
    [breakPointAlarm clearAlarm];
    [breakPointAlarm release];
    [patternFileName release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    [self registerNotificationObservers];
}

- (void)sleep
{
    [super sleep];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
	[[self motorController] assignTag:self];
}
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Motor"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORMotorController"];
}

- (NSString*) helpURL
{
	return @"VME/Motor.html";
}

- (id)   motorController
{
    return [self objectConnectedTo:ORMotorControlConnection];
}

-(void)makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height-kConnectorSize)withGuardian:self withObjectLink:self];
    [ aConnector setConnectorType: 'M1  ' ];
    [ aConnector addRestrictedConnectionType: 'M2  ' ]; //can only connect to M Carrier inputs
    [aConnector setOffColor:[NSColor blueColor]];
    [[self connectors] setObject:aConnector forKey:ORMotorControlConnection];
    [aConnector release];
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - 2*kConnectorSize-5,[self frame].size.height-kConnectorSize-15)withGuardian:self withObjectLink:self];
    [ aConnector setConnectorType: 'PAT1' ];
    [ aConnector addRestrictedConnectionType: 'PAT2' ]; //can only connect to M Carrier inputs
    [aConnector setOffColor:[NSColor cyanColor]];
    [[self connectors] setObject:aConnector forKey:ORMotorLinkInConnection];
    [aConnector release];
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - 2*kConnectorSize-5,0)withGuardian:self withObjectLink:self];
    [ aConnector setConnectorType: 'PAT2' ];
    [ aConnector addRestrictedConnectionType: 'PAT1' ]; //can only connect to M Carrier inputs
    [aConnector setOffColor:[NSColor cyanColor]];
    [[self connectors] setObject:aConnector forKey:ORMotorLinkOutConnection];
    [aConnector release];
}

- (void) disconnectOtherMotors
{
	[[self undoManager] disableUndoRegistration];
	[[[self connectors] objectForKey:ORMotorLinkInConnection] disconnect];
	[[[self connectors] objectForKey:ORMotorLinkOutConnection] disconnect];
	[[self undoManager] enableUndoRegistration];
}

#pragma mark ¥¥¥Notifications
-(void)registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStarted:)
                         name: ORRunStartedNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStopped:)
                         name: ORRunStoppedNotification
                       object: nil];
}

- (void) connectionChanged
{
    if([self motorController]){
        [[self motorController] assignTag:self];
        @try {
            [[self motorController] readMotor:self];
		}
		@catch(NSException* localException) {
            NSBeep();
            NSLog(@"%@\n",localException);
        }
    }
    else {
        [self setTag:-1];
    }
}


#pragma mark ¥¥¥Accessors
- (NSString *)motorName
{
    if(motorName)return motorName; 
    else return @"Stepper";
}
- (void)setMotorName:(NSString *)aMotorName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMotorName:motorName];
    
    if(!aMotorName)aMotorName = @"Stepper";
    
    [motorName autorelease];
    motorName = [aMotorName copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorMotorNameChangedNotification
	 object:self];
    
}

- (BOOL)useFileForPattern
{
    return useFileForPattern;
}
- (void)setUseFileForPattern:(BOOL)flag 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseFileForPattern:useFileForPattern];
    useFileForPattern = flag;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorUsePatternFileChangedNotification
	 object:self];
}

- (NSString *)patternFileName
{
    if(patternFileName)return patternFileName; 
    else return @"";
}
- (void)setPatternFileName:(NSString *)aPatternFileName 
{
    if(aPatternFileName == nil)aPatternFileName = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternFileName:patternFileName];
    [patternFileName autorelease];
    patternFileName = [aPatternFileName copy];
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorPatternFileNameChangedNotification
	 object:self];
}

- (int)  patternStartCount
{
    return patternStartCount;
}

- (void) setPatternStartCount:(int)aCount 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternStartCount:patternStartCount];
    
    patternStartCount = aCount;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorPatternChangedNotification
	 object:self];
}

- (int)  patternEndCount
{
    return patternEndCount;
}

- (void) setPatternEndCount:(int)aCount 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternEndCount:patternEndCount];
    
    patternEndCount = aCount;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorPatternChangedNotification
	 object:self];
}

- (void) roundPatternEnd 
{
    if(patternDeltaSteps){
        int d = (patternEndCount-patternStartCount)/patternDeltaSteps;
        patternEndCount =  patternStartCount + d * patternDeltaSteps;
        
        d = abs(patternDeltaSteps);
        d *= patternEndCount>=patternStartCount?1:-1;
        patternDeltaSteps = d;
        
        [[NSNotificationCenter defaultCenter]
		 postNotificationName:ORMotorPatternChangedNotification
		 object:self];
    }
}

- (int)  patternDeltaSteps
{
    return patternDeltaSteps;
}

- (void) setPatternDeltaSteps:(int)aCount 
{
    if(aCount==0)aCount = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternDeltaSteps:patternDeltaSteps];
    
    patternDeltaSteps = aCount;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorPatternChangedNotification
	 object:self];
}
- (int)  patternNumSweeps
{
    return patternNumSweeps;
}
- (void) setPatternNumSweeps:(int)count 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternNumSweeps:patternNumSweeps];
    
    patternNumSweeps = count;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorPatternChangedNotification
	 object:self];
}

- (int)  patternType
{
    return patternType;
}
- (void) setPatternType:(int)count 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternType:patternType];
    
    patternType = count;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorPatternTypeChangedNotification
	 object:self];
}


- (float)  patternDwellTime
{
    return patternDwellTime;
}

- (void) setPatternDwellTime:(float)aTime 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternDwellTime:patternDwellTime];
    
    patternDwellTime = aTime;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorPatternChangedNotification
	 object:self];
}

- (BOOL) motorRunning
{
    return motorRunning;
}

- (BOOL) homeDetected
{
    return homeDetected;
}

- (int32_t) motorPosition
{
    return motorPosition;
}


- (int)multiplierX
{
    return multiplierX;
}
- (void)setMultiplierX:(int)aMultiplier
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMultiplierX:multiplierX];
    
    if(aMultiplier <= 0)aMultiplier = 1;
    else if(aMultiplier >1000)aMultiplier = 1000;
    
    multiplierX = aMultiplier;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorMultiplierChangedNotification
	 object:self];
}

- (BOOL) absoluteMotion
{
    return absoluteMotion;
}

- (void) setAbsoluteMotion:(BOOL)absMot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAbsoluteMotion:absoluteMotion];
    absoluteMotion = absMot;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorAbsoluteMotionChangedNotification
	 object:self];
}

//=========================================================== 
//  riseFreq 
//=========================================================== 
- (int)riseFreq
{
    return riseFreq; 
}
- (void)setRiseFreq:(int)aRiseFreq
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRiseFreq:riseFreq];
    
    riseFreq = aRiseFreq;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorRiseFreqChangedNotification
	 object:self];
}

//=========================================================== 
//  driveFreq
//=========================================================== 
- (int)driveFreq
{
    return driveFreq; 
}
- (void)setDriveFreq:(int)aDriveFreq
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDriveFreq:driveFreq];
    
    driveFreq = aDriveFreq;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorDriveFreqChangedNotification
	 object:self];
}

//=========================================================== 
//  acceleration 
//=========================================================== 
- (int)acceleration
{
    return acceleration; 
}
- (void)setAcceleration:(int)anAcceleration
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAcceleration:acceleration];
    
    acceleration = anAcceleration;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorAccelerationChangedNotification
	 object:self];
}

//=========================================================== 
//  position
//=========================================================== 
- (int) xyPosition
{
    return xyPosition; 
}
- (void)setXyPosition:(int)aPosition 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setXyPosition:xyPosition];
    
    xyPosition = aPosition;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorPositionChangedNotification
	 object:self];
}

- (int)  seekAmount
{
    return seekAmount;
}
- (void) setSeekAmount:(int)anAmount 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSeekAmount:xyPosition];
    
    seekAmount = anAmount;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorSeekAmountChangedNotification
	 object:self];
}


- (BOOL)risingEdge
{
    return risingEdge;
}
- (void)setRisingEdge:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRisingEdge:risingEdge];
    risingEdge = flag;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorRisingEdgeChangedNotification
	 object:self];
}

- (int)stepMode
{
    return stepMode;
}
- (void)setStepMode:(int)aStepMode  
{
    if(aStepMode == 0)aStepMode = 0x001;
    [[[self undoManager] prepareWithInvocationTarget:self] setStepMode:stepMode];
    stepMode = aStepMode;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorStepModeChangedNotification
	 object:self];
}

- (int)holdCurrent
{
    return holdCurrent;
}
- (void)setHoldCurrent:(int)aHoldCurrent 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHoldCurrent:holdCurrent];
    holdCurrent = aHoldCurrent;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorHoldCurrentChangedNotification
	 object:self];
}

- (BOOL) absoluteBrkPt
{
    return absoluteBrkPt;
}


- (void) setAbsoluteBrkPt:(BOOL)flag 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAbsoluteBrkPt:absoluteBrkPt];
    absoluteBrkPt = flag;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorAbsoluteBrkPtChangedNotification
	 object:self];
}

- (int)  breakPoint
{
    return breakPoint;
}

- (void) setBreakPoint:(int)aPosition 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBreakPoint:breakPoint];
    breakPoint = aPosition;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorBreakPointChangedNotification
	 object:self];
}


- (int)  stepCount
{
    return stepCount;
}

- (void) setStepCount:(int)aPosition 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStepCount:stepCount];
    stepCount = aPosition;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorStepCountChangedNotification
	 object:self];
}

- (BOOL) patternInProgress
{
    return motorWorker!=nil;
}

- (id)   motorWorker
{
    return motorWorker;
}

- (void) setMotorWorker:(id)aWorker 
{
    [aWorker retain];
    [motorWorker release];
    motorWorker = aWorker;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorMotorWorkerChangedNotification
	 object:self];
}

- (uint32_t)  optionMask
{
    return optionMask;
}

- (void) setOptionMask:(uint32_t)aMask 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOptionMask:optionMask];
    optionMask = aMask;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorOptionsMaskChangedNotification
	 object:self];
}


- (void) setOption:(int)anOption 
{
    int32_t aMask = optionMask;
    aMask |= (0x1L<<anOption);
    [self setOptionMask:aMask];
}

- (void) clearOption:(int)anOption 
{
    int32_t aMask = optionMask;
    aMask &= ~(0x1L<<anOption);
    [self setOptionMask:aMask];
}

- (BOOL) optionSet:(int)anOption 
{
    return (optionMask & (0x1L<<anOption))!=0;
}

- (BOOL) fourPhase
{
    return [[self motorController] fourPhase];
}

#pragma mark ¥¥¥Hardware Access


- (void) loadStepCount
{
    //controller load stepCount
    [[self motorController] loadStepCount:stepCount motor:self];
}


- (void) loadBreakPoint
{
    //controller load breakPoint
    [[self motorController] loadBreakPoint:breakPoint absolute:absoluteBrkPt motor:self];
}


- (int32_t) readMotor
{
    [[self motorController] readMotor:self];
    return motorPosition;
}

- (BOOL) isMotorMoving
{
    return [[self motorController] isMotorMoving:self];
}

- (void) incMotor
{
    [self moveMotor:self amount:multiplierX];
}

- (void) decMotor
{
    [self  moveMotor:self amount:-multiplierX];
    
}

- (void) moveMotor:(id)aMotor amount:(int32_t)amount
{
    [[self motorController]  moveMotor:self amount:amount];
}

- (void) moveMotor:(id)aMotor to:(int32_t)aPosition
{
    [[self motorController]  moveMotor:self to:aPosition];
}

- (void) seekHome
{
    [[self motorController] seekHome:seekAmount motor:self];
}

- (void)  readHome
{
    [[self motorController] readHome:self];
}

- (void) stopMotor
{
    [[self motorController] stopMotor:self];
}

- (void) startMotor
{
    [[self motorController] startMotor:self];
}

- (void)loadHoldCurrent
{
    [[self motorController] loadHoldCurrent:holdCurrent motor:self];
}

- (void)loadStepMode
{
    [[self motorController] loadStepMode:stepMode motor:self];
}



#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setStepMode:[decoder decodeIntForKey:@"StepMode"]];
    [self setXyPosition:[decoder decodeIntForKey:@"Position"]];
    [self setHoldCurrent:[decoder decodeIntForKey:@"HoldCurrent"]];
    [self setRisingEdge:[decoder decodeIntegerForKey:@"RisingEdge"]];
    [self setBreakPoint:[decoder decodeIntForKey:@"BreakPoint"]];
    [self setAbsoluteBrkPt:[decoder decodeIntegerForKey:@"AbsBreakPoint"]];
    [self setStepCount:[decoder decodeIntForKey:@"StepCount"]];
    [self setSeekAmount:[decoder decodeIntForKey:@"SeekAmount"]];
    
    [self setPatternStartCount:[decoder decodeIntForKey:@"PatternStartCount"]];
    [self setPatternEndCount:[decoder decodeIntForKey:@"PatternEndCount"]];
    [self setPatternDeltaSteps:[decoder decodeIntForKey:@"PatternDeltaSteps"]];
    [self setPatternDwellTime:[decoder decodeFloatForKey:@"PatternDwellTime"]];
    [self setPatternNumSweeps:[decoder decodeIntForKey:@"PatternNumSweeps"]];
    [self setPatternType:[decoder decodeIntForKey:@"PatternType"]];
    [self setOptionMask:[decoder decodeIntForKey:@"OptionMask"]];
    [self setUseFileForPattern:[decoder decodeIntegerForKey:@"UsePatternFileName"]];
    [self setPatternFileName:[decoder decodeObjectForKey:@"PatternFileName"]];
    
    [self roundPatternEnd];
    
    [self setMultiplierX:[decoder decodeIntForKey:@"Multiplier"]];
    [self setAbsoluteMotion:[decoder decodeIntegerForKey:@"AbsoluteMotion"]];
    [self setRiseFreq:[decoder decodeIntForKey:@"RiseFreq"]];
    [self setDriveFreq:[decoder decodeIntForKey:@"DriveFreq"]];
    [self setAcceleration:[decoder decodeIntForKey:@"Acceration"]];
    [self setMotorName:[decoder decodeObjectForKey:@"MotorName"]];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeInteger:stepCount forKey:@"StepCount"];
    [encoder encodeInteger:holdCurrent forKey:@"HoldCurrent"];
    [encoder encodeInteger:xyPosition forKey:@"Position"];
    [encoder encodeInteger:stepMode forKey:@"StepMode"];
    [encoder encodeInteger:risingEdge forKey:@"RisingEdge"];
    [encoder encodeInteger:breakPoint forKey:@"BreakPoint"];
    [encoder encodeInteger:absoluteBrkPt forKey:@"AbsBreakPoint"];
    [encoder encodeInteger:seekAmount forKey:@"SeekAmount"];
    
    [encoder encodeInteger:patternStartCount forKey:@"PatternStartCount"];
    [encoder encodeInteger:patternEndCount forKey:@"PatternEndCount"];
    [encoder encodeInteger:patternDeltaSteps forKey:@"PatternDeltaSteps"];
    [encoder encodeFloat:patternDwellTime forKey:@"PatternDwellTime"];
    [encoder encodeInteger:patternNumSweeps forKey:@"PatternNumSweeps"];
    [encoder encodeInteger:patternType forKey:@"PatternType"];
    [encoder encodeInt:optionMask forKey:@"OptionMask"];
    [encoder encodeInteger:useFileForPattern forKey:@"UsePatternFileName"];
    [encoder encodeObject:patternFileName forKey:@"PatternFileName"];
    
    [encoder encodeInteger:multiplierX forKey:@"Multiplier"];
    [encoder encodeInteger:absoluteMotion forKey:@"AbsoluteMotion"];
    [encoder encodeInteger:riseFreq forKey:@"RiseFreq"];
    [encoder encodeInteger:driveFreq forKey:@"DriveFreq"];
    [encoder encodeInteger:acceleration forKey:@"Acceration"];
    [encoder encodeObject:motorName forKey:@"MotorName"];
    
    
}

#pragma mark ¥¥¥RunControl Ops
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherM361
{
    [self setDataId:[anotherM361 dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"OR361Model"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORMotorDecoderForMotor",                      @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:NO],                   @"variable",
								 [NSNumber numberWithLong:4],                    @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Stepper"];
    
    return dataDictionary;
}


- (void) runStarted:(NSNotification*)aNote
{
    if([self optionSet:kSyncWithRunOption]){
        id lastMotor = [self objectConnectedTo:ORMotorLinkInConnection];
        if(!lastMotor)[self startPatternRun:self];
    }
}

- (void) runStopped:(NSNotification*)aNote
{
    if([self optionSet:kSyncWithRunOption]){
        [self stopPatternRun:self];
    }
}

- (void) startPatternRun:(id)sender
{
    patternStarter = sender;
    
    //make the pattern worker
    [self setMotorWorker:[self makeWorker]];
    
    //tell the next motor to start the pattern. note the the next work may be nil
    id nextMotor = [self objectConnectedTo:ORMotorLinkOutConnection];
    [nextMotor startPatternRun:sender];
    
    if(!nextMotor){
        //if the nextMotor is nil, then we are the last in the chain and can start work.
        //Workers up the chain will be inhibited at this point.
        [motorWorker setInhibited:NO];
    }
    [motorWorker startWork];
}

- (void) stopPatternRun:(id)sender
{
    [motorWorker stopWork];
    [self setMotorWorker:nil];
    id nextMotor = [self objectConnectedTo:ORMotorLinkOutConnection];
    [nextMotor stopPatternRun:self];
}


- (id) makeWorker
{
    id aWorker = nil;
    if(useFileForPattern){
        NSString* fileContents = [NSString stringWithContentsOfFile:[patternFileName stringByExpandingTildeInPath] encoding:NSASCIIStringEncoding error:nil];
        if(fileContents){
            //get rid of \r's
            NSString* processedContent = [[fileContents componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"];
            processedContent = [[processedContent componentsSeparatedByString:@"\n\n"] componentsJoinedByString:@"\n"];
            NSArray* lines = [processedContent componentsSeparatedByString:@"\n"];
            int numSweeps = [[lines objectAtIndex:0] intValue];
            NSMutableArray* somePositions = [NSMutableArray array];
            NSMutableArray* someDwells = [NSMutableArray array];
            int i;
            for(i=1;i<[lines count]; i++){
                NSArray* items = [[lines objectAtIndex:i]componentsSeparatedByString:@","];
                [somePositions addObject:[items objectAtIndex:0]];
                [someDwells addObject:[items objectAtIndex:1]];
            }
            
            aWorker = [ORMotorPattern motorPattern:self 
                                         positions:somePositions
                                            dwells:someDwells
                                        sweepsToDo:numSweeps];
        }
    }
    else {
        aWorker =  [ORMotorPattern motorPattern:self 
                                          start:patternStartCount
                                            end:patternEndCount
                                          delta:patternDeltaSteps
                                          dwell:patternDwellTime
                                     sweepsToDo:patternNumSweeps
                                         raster:patternType];
    }
    [aWorker setInhibited:YES];
    return aWorker;
}

- (BOOL)inhibited
{
    return [motorWorker inhibited];
}
- (void)setInhibited:(BOOL)aFlag
{
    [motorWorker setInhibited:aFlag];
}

- (void) finishedStep
{
    id nextMotor = [self objectConnectedTo:ORMotorLinkOutConnection];
    if(nextMotor){
        [motorWorker setInhibited:YES];
        [[nextMotor motorWorker] setInhibited:NO];
    }
}

- (void) finishedWork
{
    if(patternStarter == self){
        [self stopPatternRun:self];
        //[self setMotorWorker:nil];
        id nextMotor = [self objectConnectedTo:ORMotorLinkOutConnection];
        [nextMotor stopPatternRun:self];
        
        if( [self optionSet:kSyncWithRunOption] && [self optionSet:kStopRunOption]){
            NSString* reason = [NSString stringWithFormat:@"%@  Pattern Finished",[self  motorName]];
            [[NSNotificationCenter defaultCenter]
			 postNotificationName:ORRequestRunHalt
			 object:self
			 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:reason,@"Reason",nil]];
        }
    }
    else {
        [motorWorker setInhibited:YES];
        [motorWorker startWork];
        id lastMotor = [self objectConnectedTo:ORMotorLinkInConnection];
        [lastMotor setInhibited:NO];
    }
}

- (void) shipMotorState:(id)aWorker
{
    if([[ORGlobal sharedGlobal] runInProgress]){
        if([self optionSet:kShipPositionOption]){
            //get the time(UT!)
            time_t	ut_time;
            time(&ut_time);
            //struct tm* theTimeGMTAsStruct = gmtime(&theTime);
            //time_t ut_time = mktime(theTimeGMTAsStruct);
            
            uint32_t data[4];
            data[0] = dataId | 4;
            data[1] = (uint32_t)ut_time;
            data[2] = (uint32_t)(([[self motorController] crateNumber]&0x0000000f) << 28 |
			([[[self motorController] guardian] slot] & 0x0000001f) << 23     |
			([[self motorController] slot]          & 0x00000007) << 20		|
			([[aWorker motor] tag]   & 0x00000003) << 16		|
			([aWorker stateId]    & 0x0000000F) << 12);
            
            data[3] = [self motorPosition];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
                                                                object:[NSData dataWithBytes:data length:sizeof(int32_t)*4]];
        }
    }
}

- (void) motorStarted
{
    [breakPointAlarm clearAlarm];	
    [breakPointAlarm release];
    breakPointAlarm = nil;
    [self setHomeDetected:NO];
    
    [self setMotorRunning:YES];
}

- (void) motorStopped
{
    [self setMotorRunning:NO];
    [self readMotor];
}

- (void) setHomeDetected:(BOOL)flag 
{
    //not undoable
    homeDetected = flag;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorHomeDetectedChangedNotification
	 object:self];
    
}

- (void) setMotorRunning:(BOOL)flag 
{
    //not undoable
    motorRunning = flag;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorMotorRunningChangedNotification
	 object:self];
}

- (void) setMotorPosition:(int32_t)aValue 
{
    //not undoable
    motorPosition = aValue;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORMotorMotorPositionChangedNotification
	 object:self];
}

- (void) postBreakPointAlarm
{
    NSLogColor([NSColor redColor],@"*** %@ hit software limit <%d>!***\n",[self  motorName],breakPoint);
    if(!breakPointAlarm){
        breakPointAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"SW limit: %@",[self  motorName]] severity:kHardwareAlarm];
        [breakPointAlarm setSticky:NO];
        [breakPointAlarm setHelpStringFromFile:@"MotorBreakpointHelp"];
    }                      
    [breakPointAlarm setAcknowledged:NO];
    [breakPointAlarm postAlarm];
    if([self patternInProgress]){
        [self stopPatternRun:self];
    }
    if([self optionSet:kSyncWithRunOption]){
        NSString* reason = [NSString stringWithFormat:@"%@ SW BreakPoint Hit",[self  motorName]];
        
        [[NSNotificationCenter defaultCenter]
		 postNotificationName:ORRequestRunHalt
		 object:self
		 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:reason,@"Reason",nil]];
        
    }
}


@end

