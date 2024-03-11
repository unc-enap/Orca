//
//  ORLNGSSlowControlsModel.m
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORLNGSSlowControlsModel.h"
#import "ORSafeQueue.h"

NSString* ORLNGSSlowControlsPollTimeChanged	 = @"ORLNGSSlowControlsPollTimeChanged";
NSString* ORLNGSSlowControlsLock			 = @"ORLNGSSlowControlsLock";
NSString* ORL200SlowControlsUserNameChanged  = @"ORL200SlowControlsUserNameChanged";
NSString* ORL200SlowControlsCmdPathChanged   = @"ORL200SlowControlsCmdPathChanged";
NSString* ORL200SlowControlsIPAddressChanged = @"ORL200SlowControlsIPAddressChanged";
NSString* ORL200SlowControlsStatusChanged    = @"ORL200SlowControlsStatusChanged";
NSString* ORL200SlowControlsInFluxChanged    = @"ORL200SlowControlsInFluxChanged";
NSString* ORL200SlowControlsDataChanged      = @"ORL200SlowControlsDataChanged";

@implementation ORLNGSSlowControlsModel


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    canceled = YES;
	[cmdQueue       release];
    [processThread  release];
    [userName       release];
    [cmdPath        release];
    [cmdStatus      release];
    [cmdList        release];
    [inFluxDB       release];
    [super dealloc];
}

- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super sleep];
}

- (void) awakeAfterDocumentLoaded
{
    @try{
        [self registerNotificationObservers];
        [self findInfluxDB];
    }
    @catch(NSException* localException){ }
}

- (void) makeMainController
{
    [self linkToController:@"ORLNGSSlowControlsController"];
}

- (void) setUpImage {
    NSImage* image = [NSImage imageNamed:@"LNGSSlowControls"];
    [self setImage:image];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(configurationChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
}

- (void) configurationChanged:(NSNotification*)aNote
{
    [self findInfluxDB];
}

- (void) findInfluxDB
{
    [inFluxDB release];
    inFluxDB = [[[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORInFluxDBModel,1"]retain];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL200SlowControlsInFluxChanged object:self];
    
}

- (bool) inFluxDBAvailable
{
    return inFluxDB != nil;
}

#pragma mark ***Accessors
- (NSString*) ipAddress
{
    return ipAddress!=nil?ipAddress:@"";

}

- (void) setIPAddress:(NSString*)anIP
{
    if(!anIP)anIP = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIPAddress:ipAddress];
    [ipAddress autorelease];
    ipAddress = [anIP copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL200SlowControlsIPAddressChanged object:self];
}

- (NSString*) userName
{
    return userName!=nil?userName:@"";
}

- (void) setUserName:(NSString*)aName
{
    if(!aName)aName = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setUserName:userName];
    [userName autorelease];
    userName = [aName copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL200SlowControlsUserNameChanged object:self];
}

- (NSString*) cmdPath
{
    return cmdPath!=nil?cmdPath:@"";
}

- (void) setCmdPath:(NSString*)aPath
{
    if(!aPath)aPath = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setCmdPath:cmdPath];
    [cmdPath autorelease];
    cmdPath = [aPath copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL200SlowControlsCmdPathChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLNGSSlowControlsPollTimeChanged object:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
    if(pollTime)[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
    [self pollHardware];
}

- (void) pollHardware
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
    if([cmdQueue count]==0){
        [self setUpCmdStatus];
        for(id aCmd in cmdStatus){
            [self putRequestInQueue:aCmd];
        }
    }
    if(pollTime)[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (NSString*) lockName
{
	return ORLNGSSlowControlsLock;
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [self setUpCmdStatus];
    
    [[self undoManager] disableUndoRegistration];

    [self setPollTime:    [decoder decodeIntForKey:    @"pollTime"]];
    [self setUserName:    [decoder decodeObjectForKey: @"userName"]];
    [self setCmdPath:     [decoder decodeObjectForKey: @"cmdPath"]];
    [self setIPAddress:   [decoder decodeObjectForKey: @"ipAddress"]];
    
    [[self undoManager] enableUndoRegistration];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:pollTime   forKey: @"pollTime"];
    [encoder encodeObject:userName    forKey: @"userName"];
    [encoder encodeObject:cmdPath     forKey: @"cmdPath"];
    [encoder encodeObject:ipAddress   forKey: @"ipAddress"];
}

- (void) putRequestInQueue:(NSString*)aCmd
{
    if(!processThread){
        processThread = [[NSThread alloc] initWithTarget:self selector:@selector(processQueue) object:nil];
        [processThread start];
    }
    if(!cmdQueue){
        cmdQueue = [[ORSafeQueue alloc] init];
    }
    [cmdQueue enqueue:[NSString stringWithFormat:@"%@",aCmd]];
}

#pragma mark ***Cmds and Status
- (void) setUpCmdStatus
{
    NSArray* expectedArgCounts = @[@10,@3,@5,@1,@3]; //must be same order as below
    if(!cmdList){
        cmdList = [@[@"Diode",       //crate,slot,channel,status,vSet,vMon,rampUp,rampDown,iMon,iSet
                     @"Muon",        //slot,chan,vset
                     @"SiPM",        //board,channel,status,progress,voltage
                     @"Llama",       //status
                     @"Source"       //source,status,position
                   ] retain];
    }
    
    if(!cmdStatus){
        cmdStatus = [[NSMutableDictionary dictionary]retain];
        int i = 0;
        for(id aCmd in cmdList){
            [cmdStatus setObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             @"?",                  kCmdStatus,
                                             @"?",                  kCmdTime,
                                             [NSMutableArray array],kCmdData,
                                             [expectedArgCounts objectAtIndex:i],   kNumArgs,
                                             nil]
                          forKey:aCmd];
            i++;
        }
    }
}

- (void) setCmd:(NSString*)aCmd key:(id)aKey value:(id)aValue
{
    @synchronized (self) {
        [[cmdStatus objectForKey:aCmd] setObject:aValue forKey:aKey];
    }
}

- (id) cmdValue:(id)aCmd key:(id)aKey
{
    id aValue = @"";
    @synchronized (self) {
        aValue = [[cmdStatus objectForKey:aCmd]  objectForKey:aKey];
    }
    return aValue;
}

- (id) cmd:(id)aCmd dataAtRow:(int)row column:(int)col
{
    NSString* aValue = @"";
    @synchronized (self) {
        NSArray* dataArray = [[cmdStatus objectForKey:aCmd]  objectForKey:kCmdData];
        if([dataArray count]>0 && [dataArray count]>=row){
            NSArray* aRow  = [dataArray objectAtIndex:row];
            if([aRow count]>0 && [aRow count]>=col){
                aValue         = [aRow objectAtIndex:col];
            }
        }
    }
    return aValue;
}

- (NSString*) cmdAtIndex:(NSInteger)i
{
    return [cmdList objectAtIndex:i];
}

- (NSInteger) cmdListCount
{
    return [cmdList count];
}

#pragma mark ***Thread
- (void) processQueue
{
    NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
    
    if(!cmdQueue) cmdQueue = [[ORSafeQueue alloc] init];
    ORTimer* timer = [[ORTimer alloc]init];

    do {
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        id aCmd = [cmdQueue dequeue];
        if(aCmd!=nil){
            [self setCmd:aCmd key:kCmdStatus value:@"Execute"];
            [self setCmd:aCmd key:kCmdTime   value:@"-"];
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORL200SlowControlsStatusChanged object:self userInfo:nil waitUntilDone:YES];
            
            [timer reset];
            [timer start];
            NSTask* task = [[NSTask alloc] init];
            [task setLaunchPath:@"/usr/bin/ssh"];

            NSArray* arguments = [NSArray arrayWithObjects:
                        [NSString stringWithFormat:@"%@@%@",userName,ipAddress],
                        [NSString stringWithFormat:@"%@get%@",cmdPath,aCmd], nil];
            [task setArguments: arguments];

            NSPipe* out = [NSPipe pipe];
            [task setStandardOutput:out];

            [task launch];
            
            NSFileHandle* read   = [out fileHandleForReading];
            NSData*   dataRead   = [read readDataToEndOfFile];
            [task waitUntilExit];
            [task release];
        
            NSString* result = [[[NSString alloc] initWithData:dataRead encoding:NSUTF8StringEncoding] autorelease];
            [timer stop];
            [self setCmd:aCmd key:kCmdTime   value:[NSString stringWithFormat:@"%.2f",[timer seconds]]];
            if([result length] &&
               [result rangeOfString: @"No"].location==NSNotFound &&
               [result rangeOfString:@"Err"].location==NSNotFound ){
                [self setCmd:aCmd key:kCmdStatus value:@"OK"];
                [self setCmd:aCmd key:kCmdData value:result];
                [self handle:aCmd data:result];
                [self sendToInFlux:aCmd];
            }
            else {
                [self setCmd:aCmd key:kCmdStatus value:@"?"];
                [self setCmd:aCmd key:kCmdData   value:@""];
                [self handle:aCmd data:result];
            }
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORL200SlowControlsStatusChanged object:self userInfo:nil waitUntilDone:YES];
        }
        [pool release];
        [NSThread sleepForTimeInterval:.1];
    } while(!canceled);
    [timer release];
    [outerPool release];
}

- (void) handle:(NSString*)aCmd data:(NSString*)result
{
    [[cmdStatus objectForKey:aCmd] removeObjectForKey:kCmdData]; //delete the old data

    if([result length]){
        int expectedNumArgs = [[[cmdStatus objectForKey:aCmd] objectForKey:kNumArgs] intValue];
        if(expectedNumArgs){
            NSMutableArray* data  = [NSMutableArray array];
            NSArray*        lines = [result componentsSeparatedByString:@"\n"];
            for(NSString* aLine in lines){
                NSArray* fields = [aLine componentsSeparatedByString:@","];
                if([fields count] == expectedNumArgs){
                    [data addObject:fields];
                }
            }
            [[cmdStatus objectForKey:aCmd] setObject:data forKey:kCmdData];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORL200SlowControlsDataChanged object:self userInfo:nil waitUntilDone:YES];
}

- (void) sendToInFlux:(NSString*)aDataCmd
{
    NSArray* data = [[cmdStatus objectForKey:aDataCmd] objectForKey:kCmdData];
    if(!data)return;
    
    double aTimeStamp = [[NSDate date]timeIntervalSince1970];
    
    if([aDataCmd isEqualToString:@"Muon"]){
        //slot,chan,vSet
        for(id aRow in data){
            ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement measurementForBucket:@"SlowControls" org:[inFluxDB org]];
            [aCmd start : aDataCmd];
            [aCmd addTag:@"slot"     withString:[aRow objectAtIndex:0]];
            [aCmd addTag:@"chan"     withString:[aRow objectAtIndex:1]];
            [aCmd addField: @"vSet"  withDouble:[[aRow objectAtIndex:2] doubleValue]];
            [aCmd setTimeStamp:aTimeStamp];
            [inFluxDB executeDBCmd:aCmd];
        }
    }
    else if([aDataCmd isEqualToString:@"Diode"]){
        //crate,slot,chan,status,vSet,vMon,rmpUp,rmpDown,iMon,iSet
        for(id aRow in data){
            ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement measurementForBucket:@"SlowControls" org:[inFluxDB org]];
            [aCmd start : aDataCmd];
            [aCmd addTag:@"crate"      withString:[aRow objectAtIndex:0]];
            [aCmd addTag:@"slot"       withString:[aRow objectAtIndex:1]];
            [aCmd addTag:@"chan"       withString:[aRow objectAtIndex:2]];
            [aCmd addField:@"status"   withDouble:[[aRow objectAtIndex:3] doubleValue]];
            [aCmd addField:@"vSet"     withDouble:[[aRow objectAtIndex:4] doubleValue]];
            [aCmd addField:@"vMon"     withDouble:[[aRow objectAtIndex:5] doubleValue]];
            [aCmd addField:@"rampUp"   withDouble:[[aRow objectAtIndex:6] doubleValue]];
            [aCmd addField:@"rampDown" withDouble:[[aRow objectAtIndex:7] doubleValue]];
            [aCmd addField:@"iMon"     withDouble:[[aRow objectAtIndex:8] doubleValue]];
            [aCmd addField:@"iSet"     withDouble:[[aRow objectAtIndex:39] doubleValue]];
            [aCmd setTimeStamp:aTimeStamp];
            [inFluxDB executeDBCmd:aCmd];
        }
    }
    else if([aDataCmd isEqualToString:@"SiPM"]){
        //board,chan,status,progress,voltage
        for(id aRow in data){
            ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement measurementForBucket:@"SlowControls" org:[inFluxDB org]];
            [aCmd start : aDataCmd];
            [aCmd addTag:@"board"      withString:[aRow objectAtIndex:0]];
            [aCmd addTag:@"chan"       withString:[data objectAtIndex:1]];
            [aCmd addField:@"status"   withDouble:[[aRow objectAtIndex:2] doubleValue]];
            [aCmd addField:@"progress" withDouble:[[aRow objectAtIndex:3] doubleValue]];
            [aCmd addField:@"voltage"  withDouble:[[aRow objectAtIndex:4] doubleValue]];
            [aCmd setTimeStamp:aTimeStamp];
            [inFluxDB executeDBCmd:aCmd];
        }
    }
    else if([aDataCmd isEqualToString:@"Source"]){
        //source,status,position
        for(id aRow in data){
            ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement measurementForBucket:@"SlowControls" org:[inFluxDB org]];
            [aCmd start : aDataCmd];
            [aCmd addTag:@"source"      withString:[aRow objectAtIndex:0]];
            [aCmd addTag:@"status"      withString:[aRow objectAtIndex:1]];
            [aCmd addField:@"position"  withDouble:[[aRow objectAtIndex:2] doubleValue]];
            [aCmd setTimeStamp:aTimeStamp];
            [inFluxDB executeDBCmd:aCmd];
        }
    }
    else if([aDataCmd isEqualToString:@"Llama"]){
        //just one entry for this one
        //state
        ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement measurementForBucket:@"SlowControls" org:[inFluxDB org]];
        [aCmd start : aDataCmd];
        [aCmd addField:@"state" withBoolean:[[[data objectAtIndex:0] objectAtIndex:0] boolValue]];
        [aCmd setTimeStamp:aTimeStamp];
        [inFluxDB executeDBCmd:aCmd];
    }
}
@end

