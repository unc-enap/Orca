//
//  ORMJDSource.m
//  Orca
//
//  Created by Mark Howe on Sept 8, 2015.
//  Copyright (c) 2015  University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORMJDSource.h"
#import "MajoranaModel.h"
#import "ORTaskSequence.h"
#import "ORRemoteSocketModel.h"
#import "ORAlarm.h"

#define kFastStepTime       0.1
#define kNormalStepTime     0.3
#define kLongStepTime       1.0
#define kVeryLongStepTime   3.0

//do NOT change this list without changing the enum states in the .h filef
static MJDSourceStateInfo state_info [kMJDSource_NumStates] = {
    { kMJDSource_Idle,                  @"Idle"},
    { kMJDSource_SetupArduinoIO,        @"Setup Arduino I/O"},
    { kMJDSource_SetInitialOutputs,     @"Write Arduino Outputs"},
    { kMJDSource_OpenGV,                @"Opening GV"},
    { kMJDSource_OpenGV1,               @"Open GV - Close 10"},
    { kMJDSource_OpenGV2,               @"Open GV - Open 10"},
    { kMJDSource_GetGVOpenPosition,     @"Checking Gatevalve"},
    { kMJDSource_VerifyGVOpen,          @"Verifying Gatevalve"},
    { kMJDSource_StartDeployment,       @"Deployment Started"},
    { kMJDSource_VerifyMotion,          @"Verifying Motion"},
    { kMJDSource_MonitorDeployment,     @"Monitoring Deployment"},

    { kMJDSource_StartRetraction,       @"Retraction Started"},
    { kMJDSource_MonitorRetraction,     @"Monitoring Retraction"},
    
    { kMJDSource_StopMotion,            @"Stop Motion"},
    { kMJDSource_VerifyStopped,         @"Verifying Stopped"},
    { kMJDSource_StopArduino,           @"Stop Arduino"},
    
    //special (for now)
    { kMJDSource_StartCloseGVSequence,  @"Start Close GV Seq"},
    { kMJDSource_SetupArduinoToCloseGV, @"Setup Arduino For Closing GV"},
    { kMJDSource_GetMirrorTrack,        @"Check Source Out"},
    { kMJDSource_VerifyInMirrorTrack,   @"Verify Source Out"},
    { kMJDSource_CloseGV,               @"Closing GV"},
    { kMJDSource_CloseGV2,              @"Close GV - Close 11"},
    { kMJDSource_CloseGV1,              @"Close GV - Open 11"},
    { kMJDSource_GetGVClosePosition,    @"Checking Gatevalve"},
    { kMJDSource_VerifyGVClosed,        @"Verifying Gatevalve"},
    { kMJDSource_MirrorTrackError,      @"Error"},
    //--------
    
    //GV Check -- manually executed
    { kGVCheckStartArduino,             @"Setup Ardunio for GV Check"},
    { kGVCheckWriteOutputs,             @"Turn on electronics"},
    { kGVCheckReadAdcs,                 @"Reading Adcs"},
    { kGVCheckDone,                     @"Done -- See Status Log"},
    //--------

    { kMJDSource_GVOpenError,           @"Error"},
    { kMJDSource_GVCloseError,          @"Error"},
    { kMJDSource_ConnectionError,       @"Error"},
};

@implementation ORMJDSource

@synthesize delegate,speed,slot,isDeploying,isRetracting,currentState;
@synthesize sourceIsIn,stateStatus,firstTime,order,runningTime,gateValveIsOpen;

NSString* ORMJDSourceModeChanged            = @"ORMJDSourceModeChanged";
NSString* ORMJDSourceStateChanged           = @"ORMJDSourceStateChanged";
NSString* ORMJDSourceIsMovingChanged        = @"ORMJDSourceIsMovingChanged";
NSString* ORMJDSourceIsConnectedChanged     = @"ORMJDSourceIsConnectedChanged";
NSString* ORMJDSourcePatternChanged         = @"ORMJDSourcePatternChanged";
NSString* ORMJDSourceGateValveChanged       = @"ORMJDSourceGateValveChanged";
NSString* ORMJDSourceIsInChanged            = @"ORMJDSourceIsInChanged";

- (id) initWithDelegate:(MajoranaModel*)aDelegate slot:(int)aSlot;
{
    self            = [super init];
    self.slot       = aSlot;
    self.delegate   = aDelegate;
    self.speed      = 250; //default -- used to be 175
   return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.delegate    = nil;
    self.stateStatus = nil;
    self.order       = nil;
    [interlockFailureAlarm clearAlarm];
    [interlockFailureAlarm release];
    [super dealloc];
}

- (void) startDeployment
{
    NSLog(@"Module %d Source deployment started\n",slot+1);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.order          = nil;
    self.isDeploying    = YES;
    self.isRetracting   = NO;
    self.firstTime      = YES;
    self.runningTime    = 0;
    self.order          = [NSMutableString stringWithString:@""];
    counter             = 0;
    elapsedTime         = 0;
    [self setCurrentState:kMJDSource_SetupArduinoIO];
    [self performSelector:@selector(step) withObject:nil afterDelay:.1];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceModeChanged object:self];
}

- (void) startRetraction
{
    NSLog(@"Module %d Source retraction started\n",slot+1);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.isDeploying  = NO;
    self.isRetracting = YES;
    self.firstTime    = YES;
    self.runningTime  = 0;
    self.order        = [NSMutableString stringWithString:@""];
    counter           = 0;
    elapsedTime          = 0;
   
    [self setCurrentState:kMJDSource_SetupArduinoIO];
    [self performSelector:@selector(step) withObject:nil afterDelay:0];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceModeChanged object:self];
}

- (void) closeGateValve
{
    NSLog(@"Module %d Source GV Close sequence started\n",slot+1);
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.isDeploying  = NO;
    self.isRetracting = NO;
    self.runningTime  = 0;
    self.order        = [NSMutableString stringWithString:@""];
    counter           = 0;
    elapsedTime          = 0;
    
    [self setCurrentState:kMJDSource_StartCloseGVSequence];
    [self performSelector:@selector(step) withObject:nil afterDelay:0];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceModeChanged object:self];

}

- (void) stopSource
{
    //only called by a manual stop
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if(isDeploying){
        self.order = [NSMutableString stringWithString:@"Partially Deployed"];
        NSLog(@"Module %d Source movement manually stopped. Source only partially deployed\n",slot+1);
    }
    else if(isRetracting){
        self.order = [NSMutableString stringWithString:@"Partially Retracted"];
        NSLog(@"Module %d Source movement manually stopped. Source only partially retracted\n",slot+1);
    }

    [self setCurrentState:kMJDSource_StopMotion];
    [self performSelector:@selector(step) withObject:nil afterDelay:0];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceModeChanged object:self];
}

- (void) setCurrentState:(int)aState
{
    if(aState == kMJDSource_Idle) NSLog(@"Module %d Source State Machine Idle\n",slot+1);

    currentState  = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceStateChanged object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceModeChanged object:self];
}

- (void) setupStateArray
{
    [stateStatus release];
    stateStatus = [[NSMutableArray array] retain];
    int i;
    for(i=0;i<kMJDSource_NumStates;i++){
        NSMutableDictionary* anEntry = [NSMutableDictionary dictionary];
        [anEntry setObject:@"--" forKey:@"status"];
        [stateStatus addObject:anEntry];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceStateChanged object:self];
}

- (NSString*) stateName:(int)anIndex
{
    if(anIndex<kMJDSource_NumStates){
        //double check the array
        if(state_info[anIndex].state == anIndex){
            return state_info[anIndex].name;
        }
        else {
            NSLogColor([NSColor redColor],@"MJDSource Programmer Error: Struct entry mismatch: (enum)%d != (struct)%d\n",anIndex,state_info[anIndex].state);
            return @"Program Error";
        }
    }
    else {
        return @"";
    }
}

- (void) setGateValveIsOpen:(int)aState
{
    gateValveIsOpen = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceGateValveChanged object:self];
}

- (void) setOrder:(NSMutableString*)aString
{
    NSMutableString* newString = [aString mutableCopy];
    [order release];
    order = newString;;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourcePatternChanged object:self];
}

- (void) setSourceIsIn:(int)aState
{
    sourceIsIn = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceIsInChanged object:self];
}

- (NSString*) currentStateName
{
    if(currentState<kMJDSource_NumStates)return state_info[currentState].name;
    else return @"?";
}

- (void) setState:(int)aState status:(id)aString color:(NSColor*)aColor
{
    NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:aColor,NSForegroundColorAttributeName,nil];
    NSAttributedString* s = [[[NSAttributedString alloc] initWithString:aString attributes:attrsDictionary] autorelease];

    NSMutableDictionary* anEntry = [NSMutableDictionary dictionary];
    [anEntry setObject:s forKey:@"status"];
    [stateStatus replaceObjectAtIndex:aState withObject:anEntry];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceStateChanged object:self];
}

- (NSString*) stateStatus:(int)aStateIndex
{
    if(aStateIndex < [stateStatus count]){
        return [[stateStatus objectAtIndex:aStateIndex] objectForKey:@"status"];
    }
    else return @"";
}

- (int) numStates { return kMJDSource_NumStates;}

- (void) step
{
    float nextTime = kNormalStepTime;
    
    if(counter++ % 10 == 0){
        if((currentState == kMJDSource_MonitorDeployment) ||
           (currentState == kMJDSource_MonitorRetraction))      [self setRunningTime:elapsedTime];
        else                                                    [self setRunningTime:0];
        [self queryMotion];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(step) object:nil];
    switch (currentState){
        case kMJDSource_SetupArduinoIO:
            [self setUpArduinoIO];
            [self setCurrentState:kMJDSource_SetInitialOutputs];   //it should be open already. verify it.
            nextTime = kLongStepTime;
           break;
        
        case kMJDSource_SetInitialOutputs:
            [self setArduinoOutputs];
            if(self.isDeploying)[self setCurrentState:kMJDSource_OpenGV]; //start GV opening sequence
            else                [self setCurrentState:kMJDSource_GetGVOpenPosition];   //it should be open already. verify it.
            nextTime = kVeryLongStepTime;
        break;

        case kMJDSource_OpenGV:
            [self turnOnGVPower];
            [self setCurrentState:kMJDSource_OpenGV1];
            nextTime = kLongStepTime;
            break;

        case kMJDSource_OpenGV1:
            [self openGateValveStepOne];
            [self setCurrentState:kMJDSource_OpenGV2];
            nextTime = kLongStepTime;
            break;

        case kMJDSource_OpenGV2:
            [self openGateValveStepTwo];
            [self setCurrentState:kMJDSource_GetGVOpenPosition];
            nextTime = kNormalStepTime;
            elapsedTime = 0;
            break;

        case kMJDSource_GetGVOpenPosition:
            nextTime = kLongStepTime; //allow some more time before the next step
            [self readArduino];
            [self setCurrentState:kMJDSource_VerifyGVOpen];
            break;
            
        case kMJDSource_VerifyGVOpen:
            if(gateValveIsOpen != kMJDSource_Unknown){
                nextTime = kNormalStepTime; //go back to the faster stepping
                if(gateValveIsOpen == kMJDSource_True){
                    NSLog(@"Module %d GV appears to be OPEN\n",slot+1);
                    [self turnOffGVPower];
                    if(isRetracting)[self setCurrentState:kMJDSource_StartRetraction];
                    else            [self setCurrentState:kMJDSource_StartDeployment];
                    nextTime = 3;
                }
                else {
                    if(elapsedTime>5) [self setCurrentState:kMJDSource_GVOpenError];
                    else            [self setCurrentState:kMJDSource_GetGVOpenPosition];
                }
            }
            else if(elapsedTime>5)[self setCurrentState:kMJDSource_GVOpenError];
            break;
           
        case kMJDSource_StartDeployment:
            [self sendDeploymentCommand];
            [self setCurrentState:kMJDSource_VerifyMotion];
            break;
            
        case kMJDSource_StartRetraction:
            [self sendRetractionCommand];
            [self setCurrentState:kMJDSource_VerifyMotion];
            break;

        case kMJDSource_StopMotion:
            [self stopMotion];
            [self setCurrentState:kMJDSource_VerifyStopped];
            break;
            
        case kMJDSource_VerifyMotion:
            if(isMoving == kMJDSource_True){
                if(isDeploying) [self setCurrentState:kMJDSource_MonitorDeployment];
                else            [self setCurrentState:kMJDSource_MonitorRetraction];
            }
            break;
            
        case kMJDSource_VerifyStopped:
            if(isMoving == kMJDSource_False)[self setCurrentState:kMJDSource_StopArduino];
            break;
            
        case kMJDSource_StopArduino:
            [self stopArduino];
            [self setCurrentState:kMJDSource_Idle];
            break;
           
        case kMJDSource_MonitorDeployment:
            [self readArduino];
            nextTime = kFastStepTime;
            break;
            
        case kMJDSource_MonitorRetraction:
           [self readArduino];
            nextTime = kFastStepTime;
            break;
            
        //special (for now NOT integrated into the full state machine)
        case kMJDSource_StartCloseGVSequence:
            [self setUpArduinoIO];
            nextTime = kVeryLongStepTime;
            elapsedTime = 0;
            [self setCurrentState:kMJDSource_SetupArduinoToCloseGV];
            break;

        case kMJDSource_SetupArduinoToCloseGV:
            [self setArduinoOutputs];
            nextTime = kVeryLongStepTime;
            elapsedTime = 0;
            [self setCurrentState:kMJDSource_GetMirrorTrack];
        break;

        
        case kMJDSource_GetMirrorTrack:
            nextTime = kLongStepTime; //allow some more time before the next step
            [self readArduino];
            [self setCurrentState:kMJDSource_VerifyInMirrorTrack];
            break;
            
        case kMJDSource_VerifyInMirrorTrack:
            if(sourceIsIn != kMJDSource_Unknown){
                nextTime = kNormalStepTime; //go back to the faster stepping
                if(sourceIsIn == kMJDSource_False){
                    [self setCurrentState:kMJDSource_CloseGV];
                }
                else {
                    if(elapsedTime>5) [self setCurrentState:kMJDSource_MirrorTrackError];
                    else              [self setCurrentState:kMJDSource_GetMirrorTrack];
                }
            }
            else if(elapsedTime>5)[self setCurrentState:kMJDSource_MirrorTrackError];
            break;

        case kMJDSource_CloseGV:
            nextTime = kLongStepTime;
            [self turnOnGVPower];
            [self setCurrentState:kMJDSource_CloseGV1];
            break;
            
        case kMJDSource_CloseGV1:
            nextTime = kLongStepTime;
            [self closeGateValveStepOne];
            [self setCurrentState:kMJDSource_CloseGV2];
           break;
            
        case kMJDSource_CloseGV2:
            nextTime = kVeryLongStepTime;
            [self closeGateValveStepTwo];
            [self setCurrentState:kMJDSource_GetGVClosePosition];
            elapsedTime = 0;
           break;

        case kMJDSource_GetGVClosePosition:
            nextTime = kLongStepTime; //allow some more time before the next step
            [self readArduino];
            [self setCurrentState:kMJDSource_VerifyGVClosed];
            break;
            
        case kMJDSource_VerifyGVClosed:
            if(gateValveIsOpen != kMJDSource_Unknown){
                nextTime = kNormalStepTime; //go back to the faster stepping
                if(gateValveIsOpen == kMJDSource_False){
                    [self turnOffGVPower];
                    [self setCurrentState:kMJDSource_StopArduino];
                }
                else {
                    if(elapsedTime>5) [self setCurrentState:kMJDSource_GVCloseError];
                    else              [self setCurrentState:kMJDSource_GetGVClosePosition];
                }
            }
            else if(elapsedTime>5)[self setCurrentState:kMJDSource_GVCloseError];
            break;

            
        //---
        
        //--Check GV States
        case kGVCheckStartArduino:
            [self setUpArduinoIO];
            [self setCurrentState:kGVCheckWriteOutputs];
            break;
        
        case kGVCheckWriteOutputs:
            nextTime = kVeryLongStepTime; //allow some more time before the next step
            [self setArduinoOutputs];
            [self setCurrentState:kGVCheckReadAdcs];
            break;
        
        case kGVCheckReadAdcs:
            NSLog(@"Module %d Getting Arduino ADC values\n",slot+1);
            nextTime = kLongStepTime; //allow some more time before the next step
            oneTimeGVVerbose = YES;
            [self readArduino];
            [self setCurrentState:kGVCheckDone];
            break;
        
        case kGVCheckDone:
            nextTime = kLongStepTime; //allow some more time before the next step
            [self stopArduino];
            [self setCurrentState:kMJDSource_Idle];
            break;

        //-----------------
        
        
        
        
        //Error Conditions
        case kMJDSource_GVOpenError:
            [self resetFlags];
            [self turnOffGVPower];
            [self stopArduino];
            if(self.isDeploying)self.order = [NSMutableString stringWithString:@"Deployment Aborted"];
            else                self.order = [NSMutableString stringWithString:@"Retraction Aborted"];
            NSLogColor([NSColor redColor],@"Module %d Source gatevalve is Closed. Source can not be moved.\n",slot+1);
            [self setCurrentState:kMJDSource_Idle];
           break;
 
        case kMJDSource_GVCloseError:
            [self resetFlags];
            [self turnOffGVPower];
            [self stopArduino];
            self.gateValveIsOpen = kMJDSource_Unknown;
            self.order = [NSMutableString stringWithString:@"GV Close Error"];
            NSLogColor([NSColor redColor],@"Module %d Source could not verify GV closed.\n",slot+1);
            [self setCurrentState:kMJDSource_Idle];
           break;

        case kMJDSource_ConnectionError:
            [self resetFlags];
            [self stopArduino];
            self.gateValveIsOpen = kMJDSource_Unknown;
            self.order = [NSMutableString stringWithString:@"Connection Lost"];
            NSLogColor([NSColor redColor],@"Module %d Connection Lost. Source can not be controlled.\n",slot+1);
            [self setCurrentState:kMJDSource_Idle];
            break;
 
        case kMJDSource_MirrorTrackError:
            [self resetFlags];
            [self stopArduino];
            self.order = [NSMutableString stringWithString:@"Not In Mirror Track"];
            NSLogColor([NSColor redColor],@"Module %d Source not in mirror track. GV could not be closed.\n",slot+1);
            [self setCurrentState:kMJDSource_Idle];
            break;

    }
    
    if(currentState != kMJDSource_Idle){
        [self performSelector:@selector(step) withObject:nil afterDelay:nextTime];
        elapsedTime += nextTime;
    }
}

- (void) setRunningTime:(float)aValue
{
    runningTime = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceModeChanged object:self];
}

- (void) setRemoteOpStatus:(NSDictionary*)aDictionary
{
    //the socket to source controller has returned something. See what it is.
    
    [super setRemoteOpStatus:aDictionary];
    
    //socket still connected?
    if([remoteOpStatus objectForKey:@"connected"]){
        BOOL connected = [[remoteOpStatus objectForKey:@"connected"] boolValue];
        if(connected)   [self setIsConnected:kMJDSource_True];
        else {
            [self setIsConnected:kMJDSource_False];
            [self setCurrentState:kMJDSource_ConnectionError];
        }
    }

    //vxm moving?
    if([remoteOpStatus objectForKey:@"sourceMoving"]){
        BOOL moving = [[remoteOpStatus objectForKey:@"sourceMoving"] boolValue];
        if(moving)  [self setIsMoving:kMJDSource_True];
        else        [self setIsMoving:kMJDSource_False];
    }


    //position and gatevalve info
    if([remoteOpStatus objectForKey:@"A"] &&
       [remoteOpStatus objectForKey:@"B"] &&
       [remoteOpStatus objectForKey:@"C"] &&
       [remoteOpStatus objectForKey:@"GV"] &&
       [remoteOpStatus objectForKey:@"CV0"] &&
       [remoteOpStatus objectForKey:@"CV1"] &&
       [remoteOpStatus objectForKey:@"LED"]
       ){
 
        //float kGVAdcOffset = 0.3; -- old
        float kGVAdcOffset = 1.0;
        
        float  gvAdc = [[remoteOpStatus objectForKey:@"GV"]floatValue];
        if((gvAdc - kGVAdcOffset)>0.1)  self.gateValveIsOpen = kMJDSource_True;
        else {
            self.gateValveIsOpen = kMJDSource_False;
            if(self.isMoving == kMJDSource_True){
                [self setCurrentState:kMJDSource_GVOpenError];
            }
        }
        
        //float kLEDAdcOffset = 1.6; -- old
        float kLEDAdcOffset = 1.0;
        float  ledAdc = [[remoteOpStatus objectForKey:@"LED"]floatValue];
        //if((ledAdc - kLEDAdcOffset)>0.2) self.sourceIsIn = kMJDSource_True; --old
        if((ledAdc - kLEDAdcOffset)<0.2) self.sourceIsIn = kMJDSource_True;
        else                             self.sourceIsIn = kMJDSource_False;
        
        if(oneTimeGVVerbose){
            if(gateValveIsOpen == kMJDSource_True)NSLog(@"Module %d Source GV is OPEN\n",slot+1);
            else if(gateValveIsOpen == kMJDSource_False)NSLog(@"Module %d Source GV is CLOSED\n",slot+1);
            else    NSLog(@"Module %d Source GV state is UNKNOWN\n",slot+1);
            NSLog(@"Module %d Source GV adc value: %.2f\n",slot+1,gvAdc);
            if(sourceIsIn == kMJDSource_True)NSLog(@"Module %d Source is IN\n",slot+1);
            else if(sourceIsIn == kMJDSource_False)NSLog(@"Module %d Source is OUT\n",slot+1);
            else    NSLog(@"Module %d Source state is UNKNOWN\n",slot+1);
            NSLog(@"Module %d Source Track adc value: %.2f\n",slot+1,ledAdc);
            self.order = nil;
            oneTimeGVVerbose = NO;
        }
        

        stateA = [[remoteOpStatus objectForKey:@"A"]intValue];
        stateB = [[remoteOpStatus objectForKey:@"B"]intValue];
        stateC = [[remoteOpStatus objectForKey:@"C"]intValue];
        state0 = [[remoteOpStatus objectForKey:@"CV0"]intValue];
        state1 = [[remoteOpStatus objectForKey:@"CV1"]intValue];
      
        if(firstTime){
            firstTime = NO;
            stateAOld = stateA;
            stateBOld = stateB;
            stateCOld = stateC;
            state0Old = state0;
            state1Old = state1;
            self.order = [NSMutableString string];
        }
        else {
            if ((stateA != stateAOld) && (stateAOld > 0)){
                [order appendString:@"A"];
                NSLog(@"Module %d %@ source, Sensor: %@\n",slot+1,isDeploying==kMJDSource_True?@"Deploying":@"Retracting",order);
            }
            if ((stateB != stateBOld) && (stateBOld > 0)){
                [order appendString:@"B"];
                NSLog(@"Module %d %@ source, Sensor: %@\n",slot+1,isDeploying==kMJDSource_True?@"Deploying":@"Retracting",order);
            }
            if ((stateC != stateCOld) && (stateCOld > 0)){
                [order appendString:@"C"];
                NSLog(@"Module %d %@ source, Sensor: %@\n",slot+1,isDeploying==kMJDSource_True?@"Deploying":@"Retracting",order);
            }
            if (state1Old != state1){
                NSLog(@"Module %d %@ source, CustomValue: %d\n",slot+1,isDeploying==kMJDSource_True?@"Deploying":@"Retracting",state1);
            }
            
            if ((state0 != state0Old)){
                NSString*            s = @"[State Unknown]";
                if(state0 == 1)      s = @"Deployed";
                else if(state0 == 2) s = @"Moving";
                else if(state0 == 3) s = @"Retracted";
                NSLog(@"Module %d source %@, CustomValue: %d\n",slot+1,s,state0);
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourcePatternChanged object:self];
            
            stateAOld = stateA;
            stateBOld = stateB;
            stateCOld = stateC;
            state0Old = state0;
            state1Old = state1;
            
            if(state0!=2){
                if(isRetracting){
                    if (state0 == 3){
                    //if((state1 == 99636) ||
                    //   (state1 == 96936) ||
                   //    state0 == 3){
                        [self setCurrentState:kMJDSource_StopMotion];
                        NSLog(@"Module %d Source fully retracted\n",slot+1);
                        self.order = [NSMutableString stringWithString:@"RETRACTED"];
                    }
                }
                else {
                    if (state0 == 1){
                    //if((state1 == 63969)|| state0 == 1){ //new longer source 7/5/16
                    //if((state1 == 36396)||
                    //   (state1 == 36936)||
                    //   state0 == 1){
                        [self setCurrentState:kMJDSource_StopMotion];
                        NSLog(@"Module %d Source fully deployed\n",slot+1);
                        self.order = [NSMutableString stringWithString:@"DEPLOYED"];
                    }
                }
            }
            /*  //not needed anymore RM, 
            else if([order length]>=5){
                if(isRetracting){
                    if([[order substringFromIndex: [order length] - 5] isEqualToString: @"CCBAB"]){
                        [self setCurrentState:kMJDSource_StopMotion];
                        NSLog(@"Module %d Source fully retracted\n",slot+1);
                        self.order = [NSMutableString stringWithString:@"RETRACTED"];
                   }
                }
                else {
                    if([[order substringFromIndex: [order length] - 5] isEqualToString: @"BACBC"] ){ //new longer source 7/5/16
                        
//                    if(([[order substringFromIndex: [order length] - 5] isEqualToString: @"ABACB"] )||
//                       ([[order substringFromIndex: [order length] - 5] isEqualToString: @"ABCAB" ])){
                        [self setCurrentState:kMJDSource_StopMotion];
                        NSLog(@"Module %d Source fully deployed\n",slot+1);
                        self.order = [NSMutableString stringWithString:@"DEPLOYED"];
                   }
                }
            }
            */
        }
    }
}

- (void) setIsMoving:(int)aState
{
    isMoving = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceIsMovingChanged object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceModeChanged object:self];
}

- (int) isMoving    {   return isMoving; }

- (NSString*) movingState
{
    NSString* s = @"?";
    switch (isMoving){
        case kMJDSource_True:  s = @"Moving";  break;
        case kMJDSource_False: s = @"Stopped"; break;
        default:               s = @"?";       break;
    }
    return s;
}

//a manual call
- (void) checkGateValve
{
    NSLog(@"Module %d Checking Status\n",slot+1);
    self.sourceIsIn         = kMJDSource_Unknown;
    self.gateValveIsOpen    = kMJDSource_Unknown;
    [self setCurrentState:kGVCheckStartArduino];
    [self performSelector:@selector(step) withObject:nil afterDelay:.1];
}

- (void) turnOffGVPower
{
    NSLog(@"Module %d Turn OFF Source GV power\n",slot+1);
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"[ORArduinoUNOModel,1 setPin:10 type:1];",         //set to output
                            @"[ORArduinoUNOModel,1 writeOutput:10 state:0];",   //power off the gate valve
                            @"[ORArduinoUNOModel,1 initHardware];",
                            nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
}

- (void) turnOnGVPower
{
    NSLog(@"Module %d Turn ON Source GV power\n",slot+1);
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"[ORArduinoUNOModel,1 setPin:10 type:1];",         //set to output
                            @"[ORArduinoUNOModel,1 writeOutput:10 state:1];",   //power ON the gate valve
                            @"[ORArduinoUNOModel,1 initHardware];",
                           nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
}

- (void) openGateValveStepOne
{
    NSLog(@"Module %d Opening Source GV. Closing Relay 11\n",slot+1);
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"[ORProXR16SSRModel,1 closeRelay:11];", //it's a relay. close it.
                            nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
}

- (void) openGateValveStepTwo
{
    NSLog(@"Module %d Opening Source GV. Opening Relay 11\n",slot+1);
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"[ORProXR16SSRModel,1 openRelay:11];", //it's a relay. Open it.
                            nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
}

- (void) closeGateValveStepOne
{
    NSLog(@"Module %d Closing Source GV. Closing Relay 11\n",slot+1);
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"[ORProXR16SSRModel,1 closeRelay:10];", //it's a relay. close it.
                            nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
}

- (void) closeGateValveStepTwo
{
    NSLog(@"Module %d Closing Source GV. Opening Relay 11\n",slot+1);
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"[ORProXR16SSRModel,1 openRelay:10];", //it's a relay. Open it.
                            nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
}

- (NSString*) gateValveState
{
    NSString* s = @"?";
    switch (gateValveIsOpen){
        case kMJDSource_True:  s = @"Open";   break;
        case kMJDSource_False: s = @"Closed"; break;
        default:               s = @"????";   break;
    }
    return s;
}

- (NSString*) sourceIsInState
{
    NSString* s = @"?";
    switch (sourceIsIn){
        case kMJDSource_True:  s = @"In";   break;
        case kMJDSource_False: s = @"Out"; break;
        default:               s = @"????";   break;
    }
    return s;
}

- (void) setIsConnected:(int)aState
{
    isConnected = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceIsConnectedChanged object:self];
}

- (int) isConnected    {   return isConnected; }

- (NSString*) connectedState
{
    NSString* s = @"?";
    switch (isConnected){
        case kMJDSource_True:  s = @"Connected";  break;
        case kMJDSource_False: s = @"Not Connected"; break;
        default:               s = @"?";       break;
    }
    return s;
}

- (NSString*) modeString
{
    NSString* s = @"";
    if(isMoving == kMJDSource_True){
        if(isDeploying       && !isRetracting)  s = @"Deploying";
        else if(isRetracting && !isDeploying)   s = @"Retracting";
        if(runningTime > 0) return [NSString stringWithFormat:@"%@ (%.0f sec)",s,runningTime];
    }
    
    return s;
}

- (void) sendDeploymentCommand
{
    NSLog(@"Module %d Starting source deployment at %d steps/sec\n",slot+1,self.speed);
    NSString* motionCmd = [NSString stringWithFormat:@"PM-1,C,SA1M%d,LM0,I1M-45000,L0,R",self.speed];
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"[ORVXMModel,1 enableMotor:0];",
                            @"[ORVXMModel,1 setUseCmdQueue:0];",
                            [NSString stringWithFormat:@"[ORVXMModel,1 setCustomCmd:%@];",motionCmd],
                            @"[ORVXMModel,1 addCustomCmd];",
                            nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
}

- (void) sendRetractionCommand
{
    NSLog(@"Module %d Starting source retraction at %d steps/sec\n",slot+1,self.speed);
    NSString* motionCmd = [NSString stringWithFormat:@"PM-1,C,SA1M%d,LM0,I1M45000,L0,R",self.speed];
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"[ORVXMModel,1 enableMotor:0];",
                            @"[ORVXMModel,1 setUseCmdQueue:0];",
                            [NSString stringWithFormat:@"[ORVXMModel,1 setCustomCmd:%@];",motionCmd],
                            @"[ORVXMModel,1 addCustomCmd];",
                            nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
}

- (void) resetFlags
{
    self.isDeploying  = NO;
    self.isRetracting = NO;
    counter           = 0;
    self.runningTime  = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDSourceModeChanged object:self];
}

- (void) stopMotion
{
    [self resetFlags];

    NSLog(@"Module %d stopping source movement\n",slot+1);
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"[ORVXMModel,1 stopAllMotion];",
                             nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
}

- (void) setUpArduinoIO
{
    NSLog(@"Module %d configure Arduino I/O\n",slot+1);
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"[ORArduinoUNOModel,1 setCustomValue:0 withValue:2];",    //set custom value to 2
                            @"[ORArduinoUNOModel,1 setCustomValue:1 withValue:0];",    //set custom value to 2
                            @"[ORArduinoUNOModel,1 setPin:3  type:0];",         //set to input
                            @"[ORArduinoUNOModel,1 setPin:4  type:1];",         //set to output
                            @"[ORArduinoUNOModel,1 setPin:5  type:1];",         //set to output
                            @"[ORArduinoUNOModel,1 setPin:6  type:0];",         //set to input
                            @"[ORArduinoUNOModel,1 setPin:9  type:0];",         //set to input
                            @"[ORArduinoUNOModel,1 setPin:7  type:1];",         //set to output
                            @"[ORArduinoUNOModel,1 setPin:8  type:1];",         //set to output
                            @"[ORArduinoUNOModel,1 setPin:10 type:1];",         //set to output
                            @"[ORArduinoUNOModel,1 setPollTime:9999];",          //fastest polling
                            nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]]; //call twice to add in some delay
}


- (void) setArduinoOutputs
{
    NSLog(@"Module %d set Arduino outputs\n",slot+1);
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"[ORArduinoUNOModel,1 writeOutput:4 state:1];",    //switch it on, gives 5V to emitter
                            @"[ORArduinoUNOModel,1 writeOutput:5 state:1];",    //switch it on, gives 5V to collector
                            @"[ORArduinoUNOModel,1 writeOutput:7 state:1];",    //switch it on, gives 5V to emitter
                            @"[ORArduinoUNOModel,1 writeOutput:8 state:1];",    //switch it on, gives 5V to collector
                            @"[ORArduinoUNOModel,1 writeOutput:10 state:0];",   //power off the gate valve
                            @"[ORArduinoUNOModel,1 initHardware];",
                            nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]]; //call twice to add in some delay
}


- (void) stopArduino
{
    NSLog(@"Module %d turn off Arduino outputs\n",slot+1);
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"[ORArduinoUNOModel,1 writeOutput:4 state:0];",    //switch off emitter
                            @"[ORArduinoUNOModel,1 writeOutput:5 state:0];",    //switch off collector
                            @"[ORArduinoUNOModel,1 writeOutput:7 state:0];",    //switch off emitter
                            @"[ORArduinoUNOModel,1 writeOutput:8 state:0];",    //switch off collector
                            @"[ORArduinoUNOModel,1 initHardware];"
                            @"[ORArduinoUNOModel,1 setPin:4  type:0];",         //set to input
                            @"[ORArduinoUNOModel,1 setPin:5  type:0];",         //set to input
                            @"[ORArduinoUNOModel,1 setPin:7  type:0];",         //set to input
                            @"[ORArduinoUNOModel,1 setPin:8  type:0];",         //set to input
                            @"[ORArduinoUNOModel,1 setPin:10 type:0];",         //set to input
                            @"[ORArduinoUNOModel,1 setPollTime:1];",         //stop polling
                            nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
}




- (void) readArduino
{
    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:
                            @"A = [ORArduinoUNOModel,1 pinStateIn:3];",
                            @"B = [ORArduinoUNOModel,1 pinStateIn:6];",
                            @"C = [ORArduinoUNOModel,1 pinStateIn:9];",
                            @"CV0 = [ORArduinoUNOModel,1 customValue:0];",
                            @"CV1 = [ORArduinoUNOModel,1 customValue:1];",
                            @"GV = [ORArduinoUNOModel,1 adc:0];",
                            @"LED =[ORArduinoUNOModel,1 adc:5];",
                            nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
}

- (void) queryMotion
{

    NSMutableArray* cmds = [NSMutableArray arrayWithObjects:@"sourceMoving = [ORVXMModel,1 isMoving];", nil];
    [self sendCommands:cmds remoteSocket:[delegate remoteSocket:slot]];
}

- (NSNumber*) sourceMovingResponse
{
    return [remoteOpStatus objectForKey:@"sourceMoving"];
}

- (void) postInterlockFailureAlarm:(NSString*)reason
{
}

- (void) clearInterlockFailureAlarm
{
    if(interlockFailureAlarm){
        [interlockFailureAlarm clearAlarm];
        [interlockFailureAlarm release];
        interlockFailureAlarm = nil;
    }
}
@end

