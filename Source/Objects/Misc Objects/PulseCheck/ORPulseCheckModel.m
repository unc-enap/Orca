//
//  ORPulseCheckModel.m
//  Orca
//
//  Created by Mark Howe on Monday Apr 4,2016.
//  Copyright (c) 2016 University of North Carolina. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORPulseCheckModel.h"
#import "ORAlarm.h"
#import "ORFileGetterOp.h"
#import "NSDate+Extensions.h"

#pragma mark •••Local Strings
NSString* ORPulseCheckModelLastFileChanged	= @"ORPulseCheckModelLastFileChanged";
NSString* ORPulseCheckMachineAdded          = @"ORPulseCheckMachineAdded";
NSString* ORPulseCheckMachineRemoved        = @"ORPulseCheckMachineRemoved";
NSString* ORPulseCheckListLock              = @"ORPulseCheckListLock";
NSString* ORPulseCheckModelReloadTable      = @"ORPulseCheckModelReloadTable";

#define kCheckMachineTime 3*60

#define kIpNumber       @"kIpNumber"
#define kUserName       @"kUserName"
#define kPassword       @"kPassword"
#define kLastChecked    @"kLastChecked"
#define kMachineStatus  @"kMachineStatus"
#define kHeartbeatPath  @"kHeartbeatPath"

@implementation ORPulseCheckModel

@synthesize lastFile,machines;

#pragma mark •••initialization
- (void) dealloc
{
    [notificationTimer invalidate];
    [notificationTimer release];
    
    //properties can be released like this:
    self.lastFile   = nil;
    self.machines   = nil;
    
    [fileQueue cancelAllOperations];
    [fileQueue release];

    [super dealloc];
}

- (void) setUpImage         { [self setImage:[NSImage imageNamed:@"PulseCheck"]]; }
- (void) makeMainController { [self linkToController:@"ORPulseCheckController"];  }

- (void) awakeAfterDocumentLoaded
{
    if(!notificationTimer){
        notificationTimer   = [[NSTimer scheduledTimerWithTimeInterval:kCheckMachineTime target:self selector:@selector(checkMachines:) userInfo:nil repeats:YES] retain];
    }
}
#pragma mark ***Accessors

- (void) setLastFile:(NSString*)aPath
{
    [lastFile autorelease];
    lastFile = [aPath copy];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulseCheckModelLastFileChanged object:self];
}


- (void) addMachine
{
    [machines addObject:[ORMachineToCheck machineToCheck]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulseCheckMachineAdded object:self];
}

- (void) removeMachineAtIndex:(NSInteger) anIndex
{
    if(anIndex < [machines count]){
        ORMachineToCheck* aMachine = [machines objectAtIndex:anIndex];
        [aMachine clearHeartbeatAlarm];
        [machines removeObjectAtIndex:anIndex];
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:anIndex] forKey:@"Index"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORPulseCheckMachineRemoved object:self userInfo:userInfo];
   }
}

- (ORMachineToCheck*) machineAtIndex:(NSInteger)anIndex
{
	if(anIndex>=0 && anIndex<[machines count])return [machines objectAtIndex:anIndex];
	else return nil;
}

- (NSInteger) machineCount
{
    return [machines count];
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setLastFile:  [decoder decodeObjectForKey:@"lastFile"]];
    self.machines =     [decoder decodeObjectForKey:@"machines"];
    [machines makeObjectsPerformSelector:@selector(resetStatus)];
    if([lastFile length] == 0)self.lastFile = @"";
    
    [[self undoManager] enableUndoRegistration];
    
    if(!machines)self.machines = [NSMutableArray array];

    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject:lastFile    forKey:@"lastFile"];
    [encoder encodeObject:machines    forKey:@"machines"];
}

- (void) saveToFile:(NSString*)aPath
{
    [self setLastFile:aPath];
    [NSKeyedArchiver archiveRootObject:machines toFile:aPath];
}

- (void) restoreFromFile:(NSString*)aPath
{
	[self setLastFile:aPath];
    NSArray* contents = [NSKeyedUnarchiver unarchiveObjectWithFile:[aPath stringByExpandingTildeInPath]];
    [machines release];
    machines = [contents mutableCopy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulseCheckModelReloadTable object:self];
}

- (void) checkMachines:(NSTimer*)aTimer
{
    [self setUpQueue];
    if([fileQueue operationCount] == 0) {

        for(ORMachineToCheck* aMachine in machines){
            [aMachine doCheck:fileQueue];
        }
    }
}

- (void) setUpQueue
{
    if(!fileQueue){
        fileQueue = [[NSOperationQueue alloc] init];
        [fileQueue setMaxConcurrentOperationCount:10];
    }
}



@end

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------
@implementation ORMachineToCheck
@synthesize data;

+ (id) machineToCheck
{
    ORMachineToCheck* aMachine = [[ORMachineToCheck alloc] init];
    NSMutableDictionary* someData        = [NSMutableDictionary dictionary];
    [someData setObject:@"ipNumber"         forKey:kIpNumber];
    [someData setObject:@"username"         forKey:kUserName];
    [someData setObject:@"••••"             forKey:kPassword];
    [someData setObject:@"Never"            forKey:kLastChecked];
    [someData setObject:@"?"                forKey:kMachineStatus];
    [someData setObject:@"heartbeatPath"    forKey:kHeartbeatPath];
    aMachine.data = someData;
    return [aMachine autorelease];
}
- (void) dealloc
{
    self.data = nil;
    [noHeartbeatAlarm clearAlarm];
    [noHeartbeatAlarm release];
    [super dealloc];
}

- (void) setValue:(id)anObject forKey:(NSString*)aKey
{
    if(!anObject)anObject = @"";
    [[[[ORGlobal sharedGlobal] undoManager] prepareWithInvocationTarget:self] setValue:[data objectForKey:aKey] forKey:aKey];

    [data setObject:anObject forKey:aKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPulseCheckModelReloadTable object:self];
}

- (id) valueForKey:(NSString*)aKey
{
    return [data objectForKey:aKey];
}

- (NSString*) ipNumber       { return [self valueForKey:kIpNumber];         }
- (NSString*) username       { return [self valueForKey:kUserName];         }
- (NSString*) password       { return [self valueForKey:kPassword];         }
- (NSString*) heartbeatPath  { return [self valueForKey:kHeartbeatPath];    }
- (NSString*) lastChecked    { return [self valueForKey:kLastChecked];      }
- (NSString*) status         { return [self valueForKey:kMachineStatus];    }

- (void) setStatus:(NSString*)aString
{
    if(!aString)aString = @"";
    [self setValue:aString forKey:kMachineStatus];
}

- (void) setLastChecked:(NSString*)aDate
{
    if(!aDate)aDate = @"?";
    [self setValue:aDate forKey:kLastChecked];
}

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    self.data    = [decoder decodeObjectForKey:@"data"];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:data  forKey:@"data"];
}

- (id) copyWithZone:(NSZone *)zone
{
    ORMachineToCheck* copy = [[ORMachineToCheck alloc] init];
    copy.data = [[data copyWithZone:zone] autorelease];
    return copy;
}

- (void) doCheck:(NSOperationQueue*)fileQueue
{
    [[NSFileManager defaultManager] removeItemAtPath:[self localPath] error:nil];
    if(mover){
        [mover cancel];
        [mover release];
        mover = nil;
    }
    
    mover = [[ORFileGetterOp alloc] init];
    mover.delegate     = self;
    
    [mover setParams: [self heartbeatPath]
           localPath: [self localPath]
           ipAddress: [self ipNumber]
            userName: [self username]
            passWord: [self password]];
    
    [mover setDoneSelectorName:@"fileGetterIsDone"];
    [fileQueue addOperation:mover];
    
}

- (NSString*)localPath
{
    NSString* ipString = [[self ipNumber] stringByReplacingOccurrencesOfString:@"." withString:@"-"];
    return [[NSString stringWithFormat:@"~/%@Heartbeat.txt",ipString] stringByExpandingTildeInPath];
}

- (void) fileGetterIsDone
{
    @synchronized (self) {
        [mover release];
        mover = nil;
        [self setLastChecked:[[NSDate date]stdDescription]];
        NSString* contents = [NSString stringWithContentsOfFile:[self localPath] encoding:NSASCIIStringEncoding error:nil];
        if([contents length] == 0){
            [self setStatus:@"No File"];
            //[self postHeartbeatAlarm];
        }
        else {
            NSArray* lines = [contents componentsSeparatedByString:@"\n"];
            if([lines count]==1){
                if([[lines objectAtIndex:0] rangeOfString:@"Quit:"].location != NSNotFound){
                    [self setStatus:@"Quit"];
                    [self clearHeartbeatAlarm];
                }
                else  {
                    [self setStatus:@"Bad File"];
                    [self postHeartbeatAlarm];
                }
            }
            else if([lines count]>=2){
                time_t postTime = [[[lines objectAtIndex:0] substringFromIndex:5] unsignedLongValue];
                time_t nextTime = [[[lines objectAtIndex:1] substringFromIndex:5] unsignedLongValue];
                time_t delta  = labs(nextTime - postTime);
                time_t overDue  = nextTime + 6*delta;
                //if the postTime is older than the delta, then something is wrong
                time_t	now;
                time(&now);
                if(now < overDue){
                    [self setStatus:@"OK"];
                    [self clearHeartbeatAlarm];
                }
                else {
                    [self setStatus:@"No Pulse"];
                    [self postHeartbeatAlarm];
                }
            }
         }
    }
}

- (void) postHeartbeatAlarm
{
    if(!noHeartbeatAlarm){
        NSString* alarmName = [NSString stringWithFormat:@"%@ %@",[self ipNumber],[self status]];
        noHeartbeatAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kImportantAlarm];
        [noHeartbeatAlarm setHelpString:@"Processing the heartbeat file indicates a problem.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
        [noHeartbeatAlarm postAlarm];
    }
}

- (void) clearHeartbeatAlarm
{
    if(noHeartbeatAlarm){
        [noHeartbeatAlarm clearAlarm];
        [noHeartbeatAlarm release];
        noHeartbeatAlarm = nil;
    }
}
- (void) resetStatus
{
    [self setStatus:@"?"];
}
@end
