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
    [inFlux         release];
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
    [inFlux release];
    inFlux = [[[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORInFluxDBModel,1"]retain];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL200SlowControlsInFluxChanged object:self];
    
}

- (bool) inFluxDBAvailable
{
    return inFlux != nil;
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
    [cmdQueue enqueue:[NSString stringWithFormat:@"get%@",aCmd]];
}

#pragma mark ***Cmds and Status
- (void) setUpCmdStatus
{
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
        for(id aCmd in cmdList){
            [cmdStatus setObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:@"?",kCmdStatus,
                                             @"?",kCmdTime,
                                             [NSMutableArray array],kCmdData,
                                             nil]
                          forKey:aCmd];
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
        NSArray* aRow      = [dataArray objectAtIndex:row];
        aValue   = [aRow objectAtIndex:col];
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
                        [NSString stringWithFormat:@"%@%@",cmdPath,aCmd], nil];
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
            if([result length]){//<<======add extra error checking
                [self setCmd:aCmd key:kCmdStatus value:@"OK"];
                [self setCmd:aCmd key:kCmdData value:result];
                [self handle:aCmd data:result];
            }
            else {
                [self setCmd:aCmd key:kCmdStatus value:@"?"];
                [self setCmd:aCmd key:kCmdData value:@""];
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
        int expectedNumArgs = 0;
        
        if(     [aCmd isEqualToString:@"getMuon"])  expectedNumArgs =  3; //slot,cha,vSet
        else if([aCmd isEqualToString:@"getDiode"]) expectedNumArgs = 10; //crate,slot,chan,status,vSet,vMon,rmpUp,rmpDown,iMon,iSet
        else if([aCmd isEqualToString:@"getSiPM"])  expectedNumArgs =  5; //board,chan,status,progress,voltage
        else if([aCmd isEqualToString:@"getLlama"]) expectedNumArgs =  1; //state
        else if([aCmd isEqualToString:@"getSource"])expectedNumArgs =  3; //source,status,position

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
}

@end
