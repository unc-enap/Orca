//
//  ORFileMover.m
//  Orca
//
//  Created by Mark Howe on Tue Jul 29 2003.
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


#pragma mark •••Imported Files
#import "ORFileMoverOp.h"
#import "ORTaskSequence.h"
#import "NSNotifications+Extensions.h"
#import "NSFileManager+Extensions.h"

@implementation ORFileMoverOp

@synthesize fileName,task,scriptFilePath,remoteHost;
@synthesize remoteUserName,remotePath,fullPath;
@synthesize remotePassWord,transferType,verbose,delegate;

- (id) init
{
    self = [super init];
    self.transferType = eOpUseSCP;
    
    allOutput = [[NSMutableString stringWithCapacity:512] retain];
	moveFilesToSentFolder = YES; //default
	useTempFile			  = YES; //default

    return self;
}

- (void) dealloc
{        	
    self.fileName           = nil;
    self.scriptFilePath     = nil;
    self.remoteHost         = nil;
    self.remotePath         = nil;
    self.remoteUserName     = nil;
    self.fullPath           = nil;
    self.remotePassWord     = nil;
    @try {
        [task terminate];
    }
    @catch (NSException* e){
        
    }
    self.task               = nil;
    [allOutput release];
    
    [super dealloc];
}

#pragma mark •••Accessors

- (void) setMoveParams:(NSString*)aFullPath 
                    to:(NSString*)aRemoteFilePath 
            remoteHost:(NSString*)aRemoteHost 
              userName:(NSString*)aRemoteUserName
              passWord:(NSString*)aPassWord
{
    self.fileName       = [aFullPath lastPathComponent];
    self.fullPath       = (NSString*)aFullPath;
    self.remotePath     = aRemoteFilePath;
    self.remoteHost     = aRemoteHost;
    self.remoteUserName = aRemoteUserName;
    self.remotePassWord = aPassWord;
}

- (void) setPercentDone: (int) aPercentDone
{
    if ([delegate respondsToSelector:@selector(setPercentDone:)]){
        [delegate performSelectorOnMainThread:@selector(setPercentDone:) withObject:[NSNumber numberWithInt:aPercentDone] waitUntilDone:NO];
    }
}

- (void) doNotUseTempFile
{
	useTempFile = NO;
}

- (void) doNotMoveFilesToSentFolder
{
	moveFilesToSentFolder = NO;
}

- (void) moveFilesToSentFolder
{
	moveFilesToSentFolder = YES;
}

#pragma mark •••Move Methods
- (void) main
{
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
    if(![self isCancelled]){
    
        [self setPercentDone:0];

        NSDictionary* defaultEnvironment = [[NSProcessInfo processInfo] environment];
        NSMutableDictionary* environment = [[[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment] autorelease];
        [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
        
        self.task = [[[NSTask alloc] init] autorelease];

        [task setEnvironment: environment];
        NSString* tmpRemotePath;
        if(useTempFile && [remotePath length]) tmpRemotePath = [remotePath stringByAppendingPathExtension:@"tmp"];
        else			tmpRemotePath = remotePath;
        if([self transferType] == eOpUseCURL){
            
            [task setLaunchPath:@"/usr/bin/curl"];
            
            NSMutableArray* params = [NSMutableArray array];
            [params addObject:@"-T"];
            [params addObject:[NSString stringWithFormat:@"%@",[fullPath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]]];
            [params addObject:@"-u"];
            [params addObject:[NSString stringWithFormat:@"%@:%@",remoteUserName,remotePassWord]];
            [params addObject:[NSString stringWithFormat:@"sftp://%@/%@",remoteHost,tmpRemotePath]];
            //[params addObject:@"--create-dirs"];
            
            if(verbose)[params addObject:@"-v"];
            
            [task setArguments:params];
            
        }
        else {
            //make temp file for the script NOTE: expect must be installed!
            NSString* tempFolder = [[ApplicationSupport sharedApplicationSupport] applicationSupportFolder:@"Scripts"];
            NSString* scriptPath = [NSFileManager tempPathForFolder:tempFolder usingTemplate:@"OrcaScriptXXX"];
            BOOL isDir = NO;
            [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir];
            if(scriptPath){
                [self setScriptFilePath:scriptPath];            
                switch ([self transferType]) {
                    case eOpUseSCP:
                    {
                        NSString* bp = [[NSBundle mainBundle ]resourcePath];
                        NSMutableString* theScript = [NSMutableString stringWithContentsOfFile:[bp stringByAppendingPathComponent:@"scpExpectScript"] encoding:NSASCIIStringEncoding error:nil];
                        [theScript replace:@"<isDir>" with:isDir?@"-r":@""];
                        [theScript replace:@"<verbose>" with:@""]; // High verbosity messes up the expect.
                        [theScript replace:@"<sourcePath>" with:[fullPath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]];
                        [theScript replace:@"<userName>" with:remoteUserName];
                        [theScript replace:@"<host>" with:remoteHost];
                        [theScript replace:@"<destinationPath>" with:tmpRemotePath];
                        [theScript replace:@"<password>" with:remotePassWord];
                        [theScript writeToFile:scriptPath atomically:YES encoding:NSASCIIStringEncoding error:nil];
                    }
                        break;
                        
                    case eOpUseSFTP:
                    case eOpUseFTP:
                    {
                        NSString* bp = [[NSBundle mainBundle ]resourcePath];
                        NSMutableString* theScript = [NSMutableString stringWithContentsOfFile:[bp stringByAppendingPathComponent:@"ftpExpectScript"] encoding:NSASCIIStringEncoding error:nil];
                        
                        [theScript replace:@"<ftp>" with:[self transferType] == eOpUseSFTP?@"sftp":@"ftp"];
                        [theScript replace:@"<user>" with:remoteUserName];
                        [theScript replace:@"<host>" with:remoteHost];
                        [theScript replace:@"<password>" with:remotePassWord];
                        [theScript replace:@"<sourcePath>" with:[fullPath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]];
                        [theScript replace:@"<destinationPath>" with:tmpRemotePath];
                        [theScript writeToFile:scriptPath atomically:YES encoding:NSASCIIStringEncoding error:nil];
                    }
                        break;
                        
                    case eOpUseCURL:
                        break;
                }
                
                //make the script executable
                NSFileManager     *fileManager = [NSFileManager defaultManager];
                BOOL fileOK = [fileManager fileExistsAtPath: fullPath];
                if ( fileOK ) {
                    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:0777], NSFilePosixPermissions, NSFileTypeRegular, NSFileType,nil];
                    [fileManager setAttributes:dict ofItemAtPath:scriptPath error:nil];
                    [task setLaunchPath:scriptPath];
                    NSLog(@"Trying to send <%@> to %@%@%@\n",[fullPath stringByAbbreviatingWithTildeInPath],remoteHost,remotePath?@":":@"",remotePath?remotePath:@"");
                }
            }
        }
        @try {
            NSPipe *newPipe = [NSPipe pipe];
            [task setStandardOutput:newPipe];
            [task setStandardError:newPipe];
            NSFileHandle *readHandle = [newPipe fileHandleForReading];
            [task launch];
            
            [self readOutput:readHandle];
            [self checkOutput];
            if ([delegate respondsToSelector:@selector(fileMoverIsDone)]){
                [delegate performSelectorOnMainThread:@selector(fileMoverIsDone) withObject:nil waitUntilDone:NO];
            }
            [readHandle closeFile];
        }
        @catch (NSException* e){
            NSLog(@"File Mover exception.. stopped during launch\n");
        }
    }
    [thePool release];
}

- (void) checkOutput
{
    BOOL transferOK = NO;
    [[NSFileManager defaultManager] removeItemAtPath:scriptFilePath error:nil];
    NSRange range;
    switch ([self transferType]) {
        case eOpUseSCP:
            range = [allOutput rangeOfString:@"%"];
            if(range.location  != NSNotFound){
                range = [allOutput rangeOfString:@"100%"];
                if(range.location  != NSNotFound)transferOK = YES;
                else {
                    NSLogColor([NSColor redColor],@"Partial transfer only!\n");
                }
            }
            break;
            
        case eOpUseFTP:
            range = [allOutput rangeOfString:@"%"];
            if(range.location  != NSNotFound){
                range = [allOutput rangeOfString:@"100%"];
                if(range.location  != NSNotFound)transferOK = YES;
                else {
                    NSLogColor([NSColor redColor],@"Partial transfer only!\n");
                }
            }
            break;
            
        case eOpUseSFTP:
            range = [allOutput rangeOfString:@"Host is down"];
            if(range.location  != NSNotFound){
                NSLogColor([NSColor redColor], @"Host (%@) is down",remoteHost);
                break;
            }
            range = [allOutput rangeOfString:@"No route to host"];
            if(range.location  != NSNotFound){
                NSLogColor([NSColor redColor], @"No route to %@",remoteHost);
                break;
            }
            range = [allOutput rangeOfString:@"%"];
            if(range.location  != NSNotFound){
                range = [allOutput rangeOfString:@"100%"];
                if(range.location  != NSNotFound)transferOK = YES;
                else {
                    NSLogColor([NSColor redColor],@"Partial transfer only!\n");	
                }
            }
            break;
            
        case eOpUseCURL:
             break;
    }
    
    if(transferOK){
        NSLog(@"%@ copied to %@@%@%@%@\n",[fullPath stringByAbbreviatingWithTildeInPath],remoteUserName,remoteHost,remotePath?@":":@"",remotePath?remotePath:@"");	
        if ([delegate respondsToSelector:@selector(shouldRemoveFile:)]){
            if([delegate shouldRemoveFile:fullPath]){
                [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
                NSLog(@"%@ deleted from local host\n",[fullPath stringByAbbreviatingWithTildeInPath]);
            }
            else [self moveToSentFolder];
        }
        else [self moveToSentFolder];

        if(useTempFile){
            NSString* tmpRemotePath = [remotePath stringByAppendingPathExtension:@"tmp"];
            ORTaskSequence* aSequence;	
            NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
            aSequence = [ORTaskSequence taskSequenceWithDelegate:self];
            [aSequence addTask:[resourcePath stringByAppendingPathComponent:@"loginExpectScript"] 
                     arguments:[NSArray arrayWithObjects:remoteUserName,remotePassWord,remoteHost,@"mv",tmpRemotePath,remotePath,nil]];
            
            [aSequence setVerbose:YES];
            [aSequence setTextToDelegate:YES];
            
            [aSequence launch];
        }
    }
    else {
        NSLogColor([NSColor redColor],@"FAILED to copy %@ to %@@%@:%@\n",[fullPath stringByAbbreviatingWithTildeInPath],remoteUserName,remoteHost,remotePath);
        if([delegate respondsToSelector:@selector(stopTheQueue)]){
            [delegate stopTheQueue];
        }
    }
    
    if(verbose || !transferOK){
        NSLog(@"Transfer Log:\n");
        NSLogFont([NSFont fontWithName:@"Courier New" size:12],
                            @"-----------------------------\n%@\n-----------------------------\n",allOutput);
    }
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
            NSString *incomingText = [[NSString alloc] initWithData:incomingData encoding:NSASCIIStringEncoding];
            
            [allOutput appendString:incomingText];
            
            NSArray* lines = [incomingText componentsSeparatedByString:@"\r"];
            for(NSString* aLine in lines){
                aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSScanner* aScanner = [NSScanner scannerWithString:aLine];
                NSString* percentString;
                if(transferType != eOpUseCURL){
                    [aScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
                    if([aScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&percentString]){
                        [self setPercentDone:[percentString intValue]];
                    }	
                }
            }
            [incomingText release];
        }
        else break;
    }while(true);
}

- (void) moveToSentFolder
{
    if(!moveFilesToSentFolder)return;
	
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* dirPath = [fullPath stringByDeletingLastPathComponent];
    dirPath = [dirPath stringByAppendingPathComponent:@"sentFiles"];
    NSString* destination = [dirPath stringByAppendingPathComponent:[fullPath lastPathComponent]];
	[fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:NO attributes:nil error:nil];
    [fileManager moveItemAtPath:fullPath toPath:destination  error:nil];
}


- (void) cleanSentFolder:(NSString*)dirPath
{
    dirPath = [dirPath stringByAppendingPathComponent:@"sentFiles"];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:dirPath error:nil];
    NSLog(@"removed folder: %@\n",dirPath);
}

@end
