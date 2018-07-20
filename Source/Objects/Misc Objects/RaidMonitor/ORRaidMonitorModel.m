//-------------------------------------------------------------------------
//  ORRaidMonitorModel.m
//
//  Created by Mark Howe on Saturday 12/21/2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORRaidMonitorModel.h"
#import "ORFileGetterOp.h"
#import "ORFileMoverOp.h"

NSString* ORRaidMonitorModelResultDictionaryChanged = @"ORRaidMonitorModelResultDictionaryChanged";
NSString* ORRaidMonitorModelLocalPathChanged    = @"ORRaidMonitorModelLocalPathChanged";
NSString* ORRaidMonitorModelRemotePathChanged   = @"ORRaidMonitorModelRemotePathChanged";
NSString* ORRaidMonitorIpAddressChanged         = @"ORRaidMonitorIpAddressChanged";
NSString* ORRaidMonitorPasswordChanged          = @"ORRaidMonitorPasswordChanged";
NSString* ORRaidMonitorUserNameChanged          = @"ORRaidMonitorUserNameChanged";
NSString* ORRaidMonitorLock                     = @"ORRaidMonitorLock";

@interface ORRaidMonitorModel (private)
- (void) postCouchDBRecord;
@end

@implementation ORRaidMonitorModel

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    return self;
}

- (void) dealloc 
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:nil object:nil];
    [localPath release];
    [remotePath release];
    [ipAddress release];
    [password release];
    [userName release];
    [fileQueue cancelAllOperations];
    [fileQueue release];
    [allOutput release];
    [resultDict release];
	[noConnectionAlarm release];
	[diskFullAlarm release];
    [scriptNotRunningAlarm release];
    [dateFormatter release];
    [badDiskAlarm release];
    [dateConvertFormatter release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"RaidMonitor"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORRaidMonitorController"];
}

#pragma mark ***Accessors

- (NSDictionary*) resultDictionary
{
    return resultDict;
}

- (NSString*) localPath
{
    if(!localPath)return @"";
    else return localPath;
}

- (void) setLocalPath:(NSString*)aLocalPath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLocalPath:localPath];
    
    [localPath autorelease];
    localPath = [aLocalPath copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRaidMonitorModelLocalPathChanged object:self];
}

- (NSString*) remotePath
{
    if(!remotePath)return @"";
    else return remotePath;
}

- (void) setRemotePath:(NSString*)aRemotePath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRemotePath:remotePath];
    
    [remotePath autorelease];
    remotePath = [aRemotePath copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRaidMonitorModelRemotePathChanged object:self];
}

- (NSString*) ipAddress
{
    if(!ipAddress)return @"";
    else return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
    
    [ipAddress autorelease];
    ipAddress = [aIpAddress copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRaidMonitorIpAddressChanged object:self];
}

- (NSString*) password
{
    if(!password)return @"";
    else return password;
}

- (void) setPassword:(NSString*)aPassword
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
    
    [password autorelease];
    password = [aPassword copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRaidMonitorPasswordChanged object:self];
}

- (NSString*) userName
{
    if(!userName)return @"";
    else return userName;
}

- (void) setUserName:(NSString*)aUserName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUserName:userName];
    
    [userName autorelease];
    userName = [aUserName copy];    

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRaidMonitorUserNameChanged object:self];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setLocalPath: [decoder decodeObjectForKey:@"localPath"]];
    [self setRemotePath:[decoder decodeObjectForKey:@"remotePath"]];
    [self setIpAddress: [decoder decodeObjectForKey:@"ipAddress"]];
    [self setPassword:  [decoder decodeObjectForKey:@"password"]];
    [self setUserName:  [decoder decodeObjectForKey:@"userName"]];
    [[self undoManager] enableUndoRegistration];
    
    [self performSelector:@selector(getStatus) withObject:nil afterDelay:20];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:localPath  forKey:@"localPath"];
    [encoder encodeObject:remotePath forKey:@"remotePath"];
    [encoder encodeObject:ipAddress  forKey:@"ipAddress"];
    [encoder encodeObject:password   forKey:@"password"];
    [encoder encodeObject:userName   forKey:@"userName"];
}
#pragma mark •••scp 
- (void) shutdown
{
    //assumes that a cron job is running on the RAID system that is watching for a file to exist
    //if it is found, it deletes the file and executes a shutdown -h now
    if(!fileQueue){
        fileQueue = [[NSOperationQueue alloc] init];
        [fileQueue setMaxConcurrentOperationCount:1];
        [fileQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    }
    
    fileMover = [[ORFileMoverOp alloc] init];
    
    [fileMover setDelegate:self];
    NSString* contents = @"Please Kill me now!!";
    NSString* path = [@"~/shutmedown.tempfile" stringByExpandingTildeInPath];
    [contents writeToFile:path atomically:NO encoding:NSASCIIStringEncoding error:nil];
    
    [fileMover setMoveParams:path
                          to:@"~/shutmedown.tempfile"
                  remoteHost:[self ipAddress]
                    userName:[self userName]
                    passWord:[self password]];
    
    [fileMover setVerbose:YES];
    [fileMover doNotMoveFilesToSentFolder];
    [fileMover setTransferType:eOpUseSCP];
    [fileQueue addOperation:fileMover];
}
     
- (void) fileMoverIsDone
{
    if ([[fileMover task] terminationStatus] == 0) {
        NSLog(@"Transferred file: %@ to %@:~/shutmedown.tempfile\n",[fileMover fileName],[fileMover remoteHost]);
    }
    else {
        NSLogColor([NSColor redColor], @"Failed to transfer file to %@\n",[fileMover remoteHost]);
    }
    
    [fileMover release];
    fileMover  = nil;
}

- (void) getStatus
{
    if(running)return;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if(!fileQueue){
        fileQueue = [[NSOperationQueue alloc] init];
        [fileQueue setMaxConcurrentOperationCount:1];
        [fileQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    }

    if(mover)[mover cancel];
    else {
        mover = [[ORFileGetterOp alloc] init];
        mover.delegate     = self;

        [mover setParams:remotePath localPath:localPath ipAddress:ipAddress userName:userName passWord:password];
        [mover setDoneSelectorName:@"fileGetterIsDone"];
        [fileQueue addOperation:mover];
    }
    [self performSelector:@selector(getStatus) withObject:nil afterDelay:60*60];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == fileQueue && [keyPath isEqual:@"operations"]) {
        if([fileQueue operationCount]==0){
            running = NO;
        }
        else {
            running = YES;
        }
    }
}

- (void) fileGetterIsDone
{
    [mover release];
    mover = nil;
    
    NSString* fullLocalPath = [localPath stringByExpandingTildeInPath];
    NSString* contents = [NSString stringWithContentsOfFile:fullLocalPath encoding:NSASCIIStringEncoding error:nil];

    if([contents length]==0){
        [resultDict release];
        resultDict = nil;
        if(!noConnectionAlarm){
            NSString* alarmName = [NSString stringWithFormat:@"No RAID%d Status Data",[self uniqueIdNumber]];
            noConnectionAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kDataFlowAlarm];
            [noConnectionAlarm setSticky:YES];
            [noConnectionAlarm setHelpString:@"Could not retrieve status from RAID drive."];
            [noConnectionAlarm postAlarm];
        }
    }
    else {
        [noConnectionAlarm clearAlarm];
        [noConnectionAlarm release];
        noConnectionAlarm = nil;
    }
    
    [resultDict removeObjectForKey:@"MountPoints"];
    [resultDict removeObjectForKey:@"scriptRan"];
    
    if(!dateFormatter){
        dateFormatter = [[NSDateFormatter alloc] init];
        if(!dateFormatter)NSLog(@"nil dateFormatter\n");
        dateFormatter.dateFormat = @"yyyy/MM/dd HH:mm:ss";
    }
    if(!dateConvertFormatter){
        dateConvertFormatter = [[NSDateFormatter alloc] init];
        dateConvertFormatter.dateFormat = @"eee MMM dd HH:mm:ss zzz yyyy";
    }

    if(!resultDict) resultDict = [[NSMutableDictionary dictionary]retain];
    
    
    NSArray* subParts = [contents componentsSeparatedByString:@"}"];
    for(id aChunk in subParts){
        aChunk = [aChunk stringByReplacingOccurrencesOfString:@"," withString:@"\n"];
        aChunk = [aChunk stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        aChunk = [aChunk stringByReplacingOccurrencesOfString:@"{" withString:@""];
        NSArray* lines  = [aChunk componentsSeparatedByString:@"\n"];
        NSMutableDictionary* chunkDict = [NSMutableDictionary dictionary];
        NSString* mainKey = nil;
        int i;
        int j=0;
        for(i=0;i<[lines count];i++){
            NSString* aLine = [lines objectAtIndex:i];
            if([aLine rangeOfString:@"Date"].location != NSNotFound){
                NSString* ds = [aLine substringFromIndex:7];
                NSDate* scriptLastRan = [dateConvertFormatter dateFromString:ds];
                NSString* scriptLastRanString = [dateFormatter stringFromDate:scriptLastRan];
                if(scriptLastRanString)[resultDict setObject:scriptLastRanString forKey:@"scriptRan"];
                NSString* s =[dateFormatter stringFromDate:[NSDate date]];
                if(s)[resultDict setObject:s forKey:@"lastChecked"];
            }
            else {
                NSArray* parts = [aLine componentsSeparatedByString:@":"];
                if([parts count]>=2){
                    NSString* key = [parts objectAtIndex:0];
                    NSString* value = [parts objectAtIndex:1];
                    value = [value stringByReplacingOccurrencesOfString:@"Enclosure#2 " withString:@""];
                    value = [value stringByReplacingOccurrencesOfString:@"Slot" withString:@"Disk"];
                    if(![key isEqualToString:@"Date"]) value = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
                    key = [key stringByReplacingOccurrencesOfString:@"Slot" withString:@"Disk"];
                    key = [key stringByReplacingOccurrencesOfString:@" " withString:@""];
                    [chunkDict setObject:value forKey:key];
                    if(j==0){
                        //keys are Data,Mount_Point,Disk
                        j++;
                        if([key isEqualToString:@"Disk"]){
                            key = value;
                            if([key isEqualToString:@"Disk"]){
                                NSArray*  parts = [key componentsSeparatedByString:@"Disk"];
                                if([parts count]==2)key = [parts objectAtIndex:1];
                            }
                        }
                        else {
                            key = value;
                        }
                        mainKey = key;
                    }
                }
            }
        }
        if(chunkDict && mainKey)[resultDict setObject:chunkDict forKey:mainKey];
    }
    
    [self checkAlarms];
    
    [self postCouchDBRecord];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRaidMonitorModelResultDictionaryChanged object:self];
}

- (void) checkAlarms
{
    
    NSTimeInterval dt = -[[resultDict objectForKey:@"scriptRanNSDate"] timeIntervalSinceNow];
    if(fabs(dt)>60*60){
        if(!scriptNotRunningAlarm){
            NSString* alarmName = [NSString stringWithFormat:@"RAID%d Status Script NOT Running",[self uniqueIdNumber]];
            scriptNotRunningAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kDataFlowAlarm];
            [scriptNotRunningAlarm setSticky:YES];
            [scriptNotRunningAlarm setHelpString:@"Check the status script on the RAID system. It has not reported status more than an hour."];
            [scriptNotRunningAlarm postAlarm];
        }
        else {
            [scriptNotRunningAlarm clearAlarm];
            [scriptNotRunningAlarm release];
            scriptNotRunningAlarm = nil;
        }
    }
    NSDictionary* homeDisk = [resultDict objectForKey:@"/home"];
    float usedPercent = [[homeDisk objectForKey:@"Used_percent"]floatValue];
    if(usedPercent>=90){
        if(!diskFullAlarm){
            NSString* alarmName = [NSString stringWithFormat:@"RAID%d > 90%% Used",[self uniqueIdNumber]];
            diskFullAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kDataFlowAlarm];
            [diskFullAlarm setSticky:YES];
            [diskFullAlarm setHelpString:@"Clear space from the RAID drive."];
            [diskFullAlarm postAlarm];
        }
    }
    else {
        [diskFullAlarm clearAlarm];
        [diskFullAlarm release];
        diskFullAlarm = nil;
    }

    int criticalCount = [[resultDict objectForKey:@"Critical Disks"]intValue];
    int failedCount   = [[resultDict objectForKey:@"Failed Disks"]intValue];
    int degradedCount = [[resultDict objectForKey:@"Degraded"]intValue];
    
    if( (criticalCount>1) || (failedCount>1) || (degradedCount>1)){
        if(!badDiskAlarm){
            NSString* alarmName = [NSString stringWithFormat:@"RAID%d Disk Problems",[self uniqueIdNumber]];
            badDiskAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kDataFlowAlarm];
            [badDiskAlarm setSticky:YES];
            [badDiskAlarm setHelpString:@"The RAID system has one or more degraded, critical, or failed drives. Replace them with a spare."];
            [badDiskAlarm postAlarm];
        }
    }
    else {
        [badDiskAlarm clearAlarm];
        [badDiskAlarm release];
        badDiskAlarm = nil;
    }

}
@end

@implementation ORRaidMonitorModel (private)
- (void) postCouchDBRecord
{
    NSMutableDictionary* values = [NSMutableDictionary dictionaryWithDictionary:resultDict];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
}


@end
