//
//  ORFileGetterOp.m
//  Orca
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


#pragma mark •••Imported Files
#import "ORFileGetterOP.h"
#import "ORTaskSequence.h"
#import "NSNotifications+Extensions.h"
#import "NSFileManager+Extensions.h"

@implementation ORFileGetterOp

@synthesize task,scriptFilePath,ipAddress;
@synthesize userName,remotePath,localPath,fullPath;
@synthesize passWord,delegate,useFTP,doneSelectorName;

- (id) init
{
    self = [super init];
    
    allOutput = [[NSMutableString stringWithCapacity:512] retain];

    return self;
}

- (void) dealloc
{        	
    self.ipAddress          = nil;
    self.remotePath         = nil;
    self.localPath          = nil;
    self.userName           = nil;
    self.fullPath           = nil;
    self.passWord           = nil;
    self.doneSelectorName   = nil;
    
    @try {
        [task terminate];
    }
    @catch (NSException* e){
    }
    self.task           = nil;
    
    [allOutput release];
    self.scriptFilePath = nil;

    [super dealloc];
}

#pragma mark •••Accessors

- (void) setParams:(NSString*)aRemoteFilePath
         localPath:(NSString*)aLocalPath
         ipAddress:(NSString*)anIpAddress
              userName:(NSString*)aUserName
              passWord:(NSString*)aPassWord
{
    self.remotePath = aRemoteFilePath;
    self.localPath  = aLocalPath;
    self.ipAddress  = anIpAddress;
    self.userName   = aUserName;
    self.passWord   = aPassWord;
}

#pragma mark •••Move Methods
- (void) main
{
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];

    if(![self isCancelled]){
        
        NSDictionary* defaultEnvironment = [[NSProcessInfo processInfo] environment];
        NSMutableDictionary* environment = [[[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment] autorelease];
        [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
        
        self.task = [[[NSTask alloc] init] autorelease];

        [task setEnvironment: environment];
        
          //make temp file for the script NOTE: expect must be installed!
        NSString* tempFolder = [[ApplicationSupport sharedApplicationSupport] applicationSupportFolder:@"Scripts"];
        NSString* scriptPath = [NSFileManager tempPathForFolder:tempFolder usingTemplate:@"OrcaScriptXXX"];
        if(scriptPath){
            [self setScriptFilePath:scriptPath];            
            NSString* bp = [[NSBundle mainBundle ]resourcePath];
            if(useFTP){
                NSMutableString* theScript = [NSMutableString stringWithContentsOfFile:[bp stringByAppendingPathComponent:@"ftpExpectGetScript"] encoding:NSASCIIStringEncoding error:nil];
                [theScript replace:@"<remotePath>" with:remotePath];
                [theScript replace:@"<userName>"   with:userName];
                [theScript replace:@"<host>"       with:ipAddress];
                [theScript replace:@"<localPath>"  with:[localPath stringByExpandingTildeInPath]];
                [theScript replace:@"<password>"   with:passWord];
                [theScript writeToFile:scriptPath atomically:YES encoding:NSASCIIStringEncoding error:nil];
            }
            else {
                NSMutableString* theScript = [NSMutableString stringWithContentsOfFile:[bp stringByAppendingPathComponent:@"scpExpectGetScript"] encoding:NSASCIIStringEncoding error:nil];
                [theScript replace:@"<remotePath>" with:remotePath];
                [theScript replace:@"<userName>"   with:userName];
                [theScript replace:@"<host>"       with:ipAddress];
                [theScript replace:@"<localPath>"  with:[localPath stringByExpandingTildeInPath]];
                [theScript replace:@"<password>"   with:passWord];
                [theScript writeToFile:scriptPath atomically:YES encoding:NSASCIIStringEncoding error:nil];
           }
            
        }
            
        //make the script executable
        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSError* err = nil;
        [fileManager removeItemAtPath:[localPath stringByExpandingTildeInPath] error:&err];
        BOOL fileOK = [fileManager fileExistsAtPath: scriptPath];
        if ( fileOK ) {
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0777], NSFilePosixPermissions, NSFileTypeRegular, NSFileType,nil];
            [fileManager setAttributes:dict ofItemAtPath:scriptPath error:nil];
            [task setLaunchPath:scriptPath];
        }
        @try {
            NSPipe* newPipe = [NSPipe pipe];
            [task setStandardOutput:newPipe];
            [task setStandardError:newPipe];
            NSFileHandle *readHandle = [newPipe fileHandleForReading];
            [task launch];
            
            [self readOutput:readHandle];
            [readHandle closeFile];
            [[NSFileManager defaultManager] removeItemAtPath:scriptFilePath error:nil];

            SEL theDoneSelector = NSSelectorFromString(doneSelectorName);
            if ([delegate respondsToSelector:theDoneSelector]){
                [delegate performSelectorOnMainThread:theDoneSelector withObject:nil waitUntilDone:NO];
            }            
        }
        @catch (NSException* e){
            NSLog(@"File Getter exception.. stopped during launch\n");
        }
    }
    [thePool release];
}

- (void) readOutput:(NSFileHandle*)fileHandle
{
    do {
        if([self isCancelled]){
            [task terminate];
            break;
        }
        
        NSData* incomingData = [fileHandle availableData];
        
        if (incomingData && [incomingData length]) {
            // Note:  if incomingData is nil, the filehandle is closed.
            NSString* incomingText = [[NSString alloc] initWithData:incomingData encoding:NSASCIIStringEncoding];
            [allOutput appendString:incomingText];
            [incomingText release];
        }
        else break;
    } while(true);
}


@end