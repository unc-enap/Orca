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
#import "ORFileMover.h"
#import "ORTaskSequence.h"
#import "NSFileManager+Extensions.h"

NSString* ORFileMoverIsDoneNotification = @"ORFileMover Is Done Notification";
NSString* ORFileMoverCopiedFile         = @"ORFileMoverCopiedFile";
NSString* ORFileMoverPercentDoneChanged = @"ORFileMoverPercentDoneChanged";

@implementation ORFileMover

- (id) init
{
    self = [super init];
    [self setTransferType: eUseSCP];
    
    allOutput = [[NSMutableString stringWithCapacity:512] retain];
	moveFilesToSentFolder = YES; //default
	useTempFile			  = YES; //default
    return self;
}

- (void) dealloc
{        
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    if (delegate){
        [nc removeObserver:delegate name:nil object:self];
    }
    [nc removeObserver:self name:nil object:nil];
	
    if([task isRunning]){
        [task terminate];
    }
    [task release];
    
    [readHandle closeFile];
    [readHandle release];
    
    [fileName release];
    [scriptFilePath release];
    [remoteHost release];
    [remotePath release];
    [remoteUserName release];
    [fullPath release];
    [remotePassWord release];
    [allOutput release];
    
    [super dealloc];
}

#pragma mark •••Accessors
- (id) delegate
{
    return delegate;
}

- (void) setDelegate:(id)newDelegate
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    if (delegate){
        [nc removeObserver:delegate name:nil object:self];
    }
    
    delegate = newDelegate; //don't retain delegates
    
    // repeat  the following for each notification
    if ([delegate respondsToSelector:@selector(fileMoverIsDone:)]){
        [nc addObserver:delegate selector:@selector(fileMoverIsDone:)
                   name:ORFileMoverIsDoneNotification object:self];
    }
    if ([delegate respondsToSelector:@selector(fileMoverPercentChanged:)]){
        [nc addObserver:delegate selector:@selector(fileMoverPercentChanged:)
                   name:ORFileMoverPercentDoneChanged object:self];
    }
    if ([delegate respondsToSelector:@selector(taskCompleted:)]){
		[nc addObserver : self
			   selector : @selector(taskCompleted:)
				   name : NSTaskDidTerminateNotification
				 object : self];
	}
}

- (NSString*) fileName
{
    return fileName;
}
- (void) setFileName:(NSString*)newFileName
{
    [fileName autorelease];
    fileName=[newFileName copy];
}


- (NSTask*) task
{
    return task;
}
- (void) setTask:(NSTask*)newTask
{
    [task autorelease];
    task=[newTask retain];
}
- (NSString*) scriptFilePath
{
    return scriptFilePath;
}
- (void) setScriptFilePath:(NSString*)newScriptFilePath
{
    [scriptFilePath autorelease];
    scriptFilePath=[newScriptFilePath copy];
}
- (NSString*) remotePath
{
    return remotePath;
}
- (void) setRemotePath:(NSString*)newRemotePath
{
    [remotePath autorelease];
    remotePath=[newRemotePath copy];
}

- (NSString*) remoteHost
{
    return remoteHost;
}

- (void) setRemoteHost:(NSString*)newRemoteHost
{
    [remoteHost autorelease];
    remoteHost=[newRemoteHost copy];
}

- (NSString*) remoteUserName
{
    return remoteUserName;
}
- (void) setRemoteUserName:(NSString*)newRemoteUserName
{
    [remoteUserName autorelease];
    remoteUserName=[newRemoteUserName copy];
}

- (eFileTransferType) transferType
{
    return transferType;
}
- (void) setTransferType:(eFileTransferType)newTransferType
{
    transferType=newTransferType;
}

- (BOOL) verbose
{
    return verbose;
}
- (void) setVerbose:(BOOL)newVerbose
{
    verbose=newVerbose;
}

- (void) setMoveParams:(NSString*)aFullPath 
                    to:(NSString*)aRemoteFilePath 
            remoteHost:(NSString*)aRemoteHost 
              userName:(NSString*)aRemoteUserName 
              passWord:(NSString*)aPassWord
{
    [self setFileName:[aFullPath lastPathComponent]];
    [self setFullPath:(NSString*)aFullPath];
    [self setRemotePath:aRemoteFilePath];
    [self setRemoteHost:aRemoteHost];
    [self setRemoteUserName:aRemoteUserName];
    [self setRemotePassWord:aPassWord];
}
- (void) setRemotePassWord:(NSString*)aPassWord
{
    [remotePassWord autorelease];
    remotePassWord = [aPassWord copy];
}
- (void) setFullPath:(NSString*)aFullPath
{
    [fullPath autorelease];
    fullPath = [aFullPath copy];
}

- (int) percentDone
{
    return percentDone;
}

- (void) setPercentDone: (int) aPercentDone
{
    percentDone = aPercentDone;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFileMoverPercentDoneChanged object:self];
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
- (void) launch
{
	[self doMove];
}

-(void) doMove
{
    NSTask *t = [[NSTask alloc] init];
    [self setTask:t];
    [t release];
    
    NSPipe *newPipe = [NSPipe pipe];
    readHandle = [[newPipe fileHandleForReading] retain];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	
    [nc addObserver:self 
           selector:@selector(taskDataAvailable:) 
               name:NSFileHandleReadCompletionNotification 
             object:readHandle];
    
    [nc addObserver : self
           selector : @selector(taskCompleted:)
               name : NSTaskDidTerminateNotification
             object : task];
    
    [readHandle readInBackgroundAndNotify];
    
    NSDictionary* defaultEnvironment = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary* environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
    [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
    [task setEnvironment: environment];
    NSString* tmpRemotePath;
	if(useTempFile && [remotePath length]) tmpRemotePath = [remotePath stringByAppendingPathExtension:@"tmp"];
	else			tmpRemotePath = remotePath;
    if([self transferType] == eUseCURL){
		
        [task setLaunchPath:@"/opt/bin/curl"];
		
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
                case eUseSCP:
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
                    
                case eUseSFTP:
                case eUseFTP:
				{
					NSString* bp = [[NSBundle mainBundle ]resourcePath];
					NSMutableString* theScript = [NSMutableString stringWithContentsOfFile:[bp stringByAppendingPathComponent:@"ftpExpectScript"] encoding:NSASCIIStringEncoding error:nil];
					
					[theScript replace:@"<ftp>" with:[self transferType] == eUseSFTP?@"sftp":@"ftp"];
					[theScript replace:@"<user>" with:remoteUserName];
					[theScript replace:@"<host>" with:remoteHost];
					[theScript replace:@"<password>" with:remotePassWord];
					[theScript replace:@"<sourcePath>" with:[fullPath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]];
					[theScript replace:@"<destinationPath>" with:tmpRemotePath];
					[theScript writeToFile:scriptPath atomically:YES encoding:NSASCIIStringEncoding error:nil];
				}
                    break;
                    
                case eUseCURL:
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
    
    [task setStandardOutput:newPipe];
    [task setStandardError:newPipe];
    [task launch];
    [environment release];
    
}

- (void) stop
{
    if([task isRunning]){
        [task terminate];
    }
}

- (void) tasksCompleted:(id)sender;
{
}

- (void) taskCompleted: (NSNotification*)aNote
{
    if([aNote object] == task){
        BOOL transferOK = NO;
        [[NSFileManager defaultManager] removeItemAtPath:scriptFilePath error:nil];
		int exitCode = [task terminationStatus];
        if( exitCode == 0) {
            //probable success.. but let's make sure
            NSRange range;
            switch ([self transferType]) {
                case eUseSCP:
					range = [allOutput rangeOfString:@"%"];
                    if(range.location  != NSNotFound){
						range = [allOutput rangeOfString:@"100%"];
						if(range.location  != NSNotFound)transferOK = YES;
						else {
							NSLogColor([NSColor redColor],@"Partial transfer only!\n");
						}
					}
					break;
					
                case eUseFTP:
					range = [allOutput rangeOfString:@"%"];
                    if(range.location  != NSNotFound){
						range = [allOutput rangeOfString:@"100%"];
						if(range.location  != NSNotFound)transferOK = YES;
						else {
							NSLogColor([NSColor redColor],@"Partial transfer only!\n");
						}
					}
                    //range = [allOutput rangeOfString:@"Transfer complete"];
                    //if(range.location  != NSNotFound)transferOK = YES;
					break;
					
                case eUseSFTP:
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
					//  range = [allOutput rangeOfString:@"Failure"];
					// if(range.location  == NSNotFound)transferOK = YES;
					break;
					
                case eUseCURL:
                    if([task terminationStatus] == 0)transferOK = YES;
                    else {
                        transferOK = NO;
                        NSLog(@"task return status: %d\n",[task terminationStatus]);
                    }
					break;
            }
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
			NSLogColor([NSColor redColor],@"Error code: %d\n",exitCode);
        }
        
 		if(verbose || !transferOK){
			NSLog(@"Transfer Log:\n");
            NSLogFont([NSFont fontWithName:@"Courier New" size:12],
                      @"-----------------------------\n%@\n-----------------------------\n",allOutput);
		}
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:NSTaskDidTerminateNotification object:self];
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        if(transferOK) [userInfo setObject:@"Success" forKey:@"Status"];
        else           [userInfo setObject:@"Failed" forKey:@"Status"];
        [nc postNotificationName:ORFileMoverIsDoneNotification object:self userInfo:userInfo];
	}

}

- (void)taskDataAvailable:(NSNotification*)aNotification
{
    NSData *incomingData = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    if (incomingData && [incomingData length]) {
        // Note:  if incomingData is nil, the filehandle is closed.
        NSString *incomingText = [[NSString alloc] initWithData:incomingData encoding:NSASCIIStringEncoding];
		
        [allOutput appendString:incomingText];
        
		NSArray* lines = [incomingText lines];
		NSEnumerator* e = [lines objectEnumerator];
		NSString* aLine;
		while(aLine = [e nextObject]){
            aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSScanner* aScanner = [NSScanner scannerWithString:aLine];
			NSString* percentString;
			if(transferType != eUseCURL){
				[aScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
				if([aScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&percentString]){
					[self setPercentDone:[percentString intValue]];
				}	
			}
			
		}
		
        [[aNotification object] readInBackgroundAndNotify];  // go back for more.
        [incomingText release];
    }
    else if(!incomingData){
        [task terminate];
    }
    
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
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:ORFileMoverIsDoneNotification object:self];
}

@end