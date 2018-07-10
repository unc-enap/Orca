//
//  OReCPU147Model.m
//  Orca
//
//  Created by Mark Howe on Tue Mar 25 2003.
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
#import "OReCPU147Config.h"
#import "OReCPU147Model.h"
#import "ORCircularBufferReader.h"
#import "ORReadOutList.h"
#import "ORVmeCrateModel.h"
#import "ORCircularBufferTypeDefs.h"
#import "VME_eCPU_Config.h"

#pragma mark •••Definitions
#define kDefaultBaseAddress				0x8000000

#pragma mark •••Notification Strings
NSString* OReCPU147FileNameChanged						= @"eCPU 147 File Changed";
NSString* OReCPU147UpdateIntervalChangedNotification	= @"OReCPU147UpdateIntervalChangedNotification";
NSString* OReCPU147StructureUpdated						= @"OReCPU147StructureUpdated";
NSString* OReCPU147QueChanged							= @"OReCPU147QueChanged";

#define	ER_NOERROR		0
#define ER_NOT_A_167	1
#define ER_CB_FULL		2
#define	ER_NO_CARDS		3
#define ER_CHKSUM_CARDS	4
#define	ER_RD_ERR		5
#define	ER_WR_ERR		6
#define MSG_GEN			7
#define CB_WRITE_DONE	8
#define MSG_RD			9
#define MSG_WR			10

#define NUM_MSG_PARAMS 5
#define NUM_ERR_PARAMS 5

// Error messages - only used in MAC
const struct {
	short	error_type;
	NSString* message;
	
} ecpu_err[]={
{ER_NOERROR,		 	@"---"}, 						// no error
{ER_NOT_A_167,		 	@"HW Requires a MVME167"},		// Not a VME167 eCPU
{ER_CB_FULL,		 	@"DPM CB FULL. "},		
{ER_NO_CARDS,		 	@"Invalid Number of Unique HW Cards "},
{ER_CHKSUM_CARDS,	 	@"Invalid Total number of HW Cards "},
{ER_RD_ERR,			 	@"HW Rd Err"},
{ER_WR_ERR,			 	@"HW Wr Err"},		
{MSG_GEN,			 	@"Generic"},		
{CB_WRITE_DONE,		 	@"CB Write Done"},			
{MSG_RD,				@"HW Read"},			
{MSG_WR,				@"HW Write"},			
};




@implementation OReCPU147Model

#pragma mark •••Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setBaseAddress:kDefaultBaseAddress];
	
	ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
	[self setReadOutGroup:readList];
	[readList release];
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [fileName release];
    [circularBufferReader release];
	[lastQueUpdate release];
	[eCpuDeadAlarm clearAlarm];
	[eCpuDeadAlarm release];
    [eCpuNoStartAlarm clearAlarm];
    [eCpuNoStartAlarm release];
	
    [super dealloc];
}

- (void) sleep
{
    [super sleep];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"eCPU147"]];
}

- (void) makeMainController
{
    [self linkToController:@"OReCPU147Controller"];
}

- (NSString*) helpURL
{
	return @"VME/MVE147_165.html";
}

#pragma mark •••Notifications
-(void)registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver: self
                     selector: @selector(vmePowerFailed:)
                         name: @"VmePowerFailedNotification"
                       object: nil];
    
}

-(void)vmePowerFailed:(NSNotification*)aNotification
{
    powerFailed = YES;
}

#pragma mark •••Accessors

- (NSDate*) lastQueUpdate
{
	return lastQueUpdate;
}
- (void) setLastQueUpdate:(NSDate*)aDate
{
	[aDate retain];
	[lastQueUpdate release];
	lastQueUpdate = aDate;
}

- (NSString*) fileName
{
	return fileName;
}

- (void) setFileName:(NSString*)aFile
{
	[[[self undoManager] prepareWithInvocationTarget:self] setFileName:[self fileName]];
	
	[fileName autorelease];
	fileName = [aFile copy];
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:OReCPU147FileNameChanged
	 object:self];
	
}

- (unsigned long)codeLength
{
	return codeLength;
}

- (ORCircularBufferReader*) circularBufferReader
{
	return circularBufferReader;
}

- (void) setCircularBufferReader:(ORCircularBufferReader*)cb
{
	[cb retain];
	[circularBufferReader release];
	circularBufferReader = cb;
	
	[circularBufferReader setBaseAddress: MAC_DPM(DATA_CIRC_BUF_START)];
    
}




- (ORReadOutList*) readOutGroup
{
	return readOutGroup;
}
- (void) setReadOutGroup:(ORReadOutList*)newReadOutGroup
{
	[readOutGroup autorelease];
	readOutGroup=[newReadOutGroup retain];
}

- (NSTimeInterval) updateInterval
{
	return updateInterval;
}

- (void) setUpdateInterval:(NSTimeInterval)newUpdateInterval
{
    
    [[[self undoManager] prepareWithInvocationTarget:self] setUpdateInterval:updateInterval];
    
	updateInterval=newUpdateInterval;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:OReCPU147UpdateIntervalChangedNotification
	 object: self];
    
	[self update];
}


- (NSMutableArray*) children {
	//method exists to give common interface across all objects for display in lists
	return [NSMutableArray arrayWithObject:readOutGroup];
}


- (eCPU_MAC_DualPortComm) communicationBlock
{
	return communicationBlock;
}

- (SCBHeader) cbControlBlockHeader
{
	return cbControlBlockHeader;
}

- (eCPUDualPortControl) dualPortControl
{
	return dualPortControl;
}

#pragma mark •••Downloading
- (void) startUserCodeWithRetries:(int)num
{
    
	int tryCount = 0;
	@try {
        BOOL successfullyStarted = NO; //assume the worst
		do {
            
			if(tryCount>0){
				NSLog(@"eCPU failed to start! Try again....\n");
				[self downloadUserCode];
			}
            
            
			// reset stop flag
			unsigned short ival = 0x0000;
			
			[[self adapter] writeWordBlock:&ival
								 atAddress:USER_STOP_CODE_FLAG
								numToWrite:1
								withAddMod:0x39
							 usingAddSpace:kAccessRemoteRAM];
			
			// set start flag - vme cpu will then reset this flag to 0x5555 when remote code started
			// this flag is reset to 0x0000 whenever user code is downloaded (in DownloadUserCode)
			ival = 0xaaaa;
			
			[[self adapter] writeWordBlock:&ival
								 atAddress:USER_START_CODE_FLAG
								numToWrite:1
								withAddMod:0x39
							 usingAddSpace:kAccessRemoteRAM];
			
			double t0 = [NSDate timeIntervalSinceReferenceDate];
			
			while(1){
				[[self adapter] readWordBlock:&ival
									atAddress:USER_START_CODE_FLAG
									numToRead:1
								   withAddMod:0x39
								usingAddSpace:kAccessRemoteRAM];
				if(ival == 0x5555){
					successfullyStarted = YES;
					break;
				}
				
				if([NSDate timeIntervalSinceReferenceDate]-t0 >= 2.0){
					successfullyStarted = NO;
					break;
				}
			}
			if(successfullyStarted)break;
		} while(tryCount++ < num);
        
		if(!successfullyStarted){
			[NSException raise:@"Time Out" format:@"Waited until time-out for User Code to start."];
		}
        
		
		NSLog(@"eCPU code started. File: <%@>\n",fileName);
        if([eCpuNoStartAlarm isPosted]){
            [eCpuNoStartAlarm clearAlarm];
            [eCpuNoStartAlarm release];
            eCpuNoStartAlarm = nil;
        }
        
	}
	@catch(NSException* localException) {
		NSLog(@"Could not start user code in eCPU.\n");
		NSLog(@"You may have to do a VME sysReset or push the reset button on the eCPU front panel.\n");
		if(!eCpuNoStartAlarm){
			eCpuNoStartAlarm = [[ORAlarm alloc] initWithName:@"eCPU didn't start" severity:kRunInhibitorAlarm];
			[eCpuNoStartAlarm setSticky:YES];
			[eCpuNoStartAlarm setHelpStringFromFile:@"eCPUNoStartHelp"];
		}
		if(![eCpuNoStartAlarm isPosted]){
			[eCpuNoStartAlarm setAcknowledged:NO];
			[eCpuNoStartAlarm postAlarm];
		}
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:@"forceRunStopNotification"
		 object:self];
		
		//[localException raise];
	}
}


- (void) stopUserCode
{
	@try {
        
		int i;
		for(i=0;i<6;i++){
			//try to stop the eCPU, try multiple times if needed until the heartbeat stops.
			unsigned long heartBeat;
			unsigned short ival = STOP_FLAG;
			[[self adapter] writeWordBlock:&ival
                                 atAddress:USER_STOP_CODE_FLAG
								numToWrite:1
                                withAddMod:0x39
                             usingAddSpace:kAccessRemoteRAM];
            
			[NSThread sleepUntilDate:[[NSDate date] dateByAddingTimeInterval:.1]];
			[[self adapter] readLongBlock:(unsigned long*)&communicationBlock
                                atAddress:MAC_DPM(COMM_ADDRESS_START)
                                numToRead:sizeof(eCPU_MAC_DualPortComm)/4
                               withAddMod:0x09
                            usingAddSpace:kAccessRemoteDRAM];
            
			heartBeat = communicationBlock.heartbeat;
			
			[NSThread sleepUntilDate:[[NSDate date] dateByAddingTimeInterval:.1]];
			
			[[self adapter] readLongBlock:(unsigned long*)&communicationBlock
                                atAddress:MAC_DPM(COMM_ADDRESS_START)
                                numToRead:sizeof(eCPU_MAC_DualPortComm)/4
                               withAddMod:0x09
                            usingAddSpace:kAccessRemoteDRAM];
			if(heartBeat == communicationBlock.heartbeat)break;
		}
        
		NSLog(@"eCPU code stopped. File: <%@>\n",fileName);
	}
	@catch(NSException* localException) {
		NSLog(@"Exception thrown trying to stop user code.\n");
		ORRunAlertPanel([localException name], @"%@\nCould not stop user code in eCPU.", @"OK", nil, nil,
                        localException);
	}
}


/* 	DownloadUserCode - Download user code to a Motorola 147S VME CPU object */
/*
 *
 *	Download Instructions:
 *			Build either a single-segment or multi-segment pure code resource, choosing
 *			the Custom Header Option in the Set Project Type Menu.  Choose Code Resource,
 *			Type = CODE, File Type = 'DOWN'.  Creator, ID, and Attrs are optional.
 *			Generate the code to be downloaded using the file, vme_generate.c, as a template.
 *			The files, configureIOXY.h and startupCPUM.h, MUST be included at SAME positions
 *			as in the example.  Then use vme_download to download the generated code to the VME
 *			module.  The code resource will contain the	global data and jmp table. This
 *			means that the total global data and jmp table entries are limited to 32k.
 *
 *
 *	Memory Map Of Downloaded Code (as viewed by MV147 CPU):
 *
 *			BOOT_ADDRESS		->	----------------	0x4000
 *
 *			USER_DATA_ADDRESS	->	----------------	0x4100
 *
 *			USER_CODE_ADDRESS	->	----------------	0x10000 -> A4
 *									CODE Resource
 *									header()
 *									main()
 *									Globals
 *									Jump Table
 *			Code Resources			----------------
 *									CCOD Resource 1
 *									----------------
 *											:
 *									----------------
 *									CCOD Resource N
 *									----------------
 *
 *
 *
 *	NOTE 1: After download of the boot and user code is complete, execution of the user code
 *		    may be controlled from either the 147 front panel or from the mac.  From the front
 *		    panel the user code execution may be stopped using the ABORT switch and started
 *		    (from the beginning) using the RESET switch.  The bit3 start_user_code and
 *		    stop_user_code perform the same functions under program control on the mac.
 *	             The function stop_user_code stops execution of the user code by setting a flag
 *		    in the user data area.  This flag is check periodically by the user code and if
 *		    set will exit the user code to the cpu monitor program, 147bug.  The function
 *		    start_user_code starts execution of the user code by causing the sysreset signal
 *		    to be asserted using the bit 3 reset function.
 *
 */
- (void) downloadUserCode
{
	double t0;
	
	@try {
		
		NSData *theCodeData = [self codeAsData];
		codeLength = *((unsigned long*)[theCodeData bytes] + 0x100/4);
		unsigned char* code_start_ptr = (unsigned char*)[theCodeData bytes] + 0x100 + sizeof(unsigned long);
        
		// stop any user code currently running
		unsigned short ival = STOP_FLAG;
		[[self adapter] writeWordBlock:&ival
                             atAddress:USER_STOP_CODE_FLAG
							numToWrite:1
                            withAddMod:0x39
                         usingAddSpace:kAccessRemoteRAM];
        
		t0 = [NSDate timeIntervalSinceReferenceDate];
		while([NSDate timeIntervalSinceReferenceDate]-t0 < .01);
        
        
		// reset start code flag -must use addressmodifier 0x39)
		ival = 0x0000;
		[[self adapter] writeWordBlock:&ival
                             atAddress:USER_START_CODE_FLAG
                            numToWrite:1
                            withAddMod:0x39
                         usingAddSpace:kAccessRemoteRAM];
        
		t0 = [NSDate timeIntervalSinceReferenceDate];
		while([NSDate timeIntervalSinceReferenceDate]-t0 < .01);
		
		NSLog(@"Downloading <%@> code Length: %d into eCPU.\n",[self fileName],codeLength);
        
		unsigned long i;
		for(i=0;i<codeLength;i++){
			[[self adapter] writeByteBlock:(unsigned char*)(code_start_ptr+i)
                                 atAddress:(USER_CODE_ADDRESS+i)
                                numToWrite:1
                                withAddMod:0x39
                             usingAddSpace:kAccessRemoteRAM];
		}
		NSLog(@"checking code\n");
		unsigned long errors = 0;
		for(i=0;i<codeLength;i++){
			unsigned char val;
			[[self adapter] readByteBlock:&val
                                atAddress:(USER_CODE_ADDRESS+i)
                                numToRead:1
                               withAddMod:0x39
                            usingAddSpace:kAccessRemoteRAM];
			if(val != *(code_start_ptr+i)){
				errors++;
			}
		}
		NSLog(@"Comparison of eCPU memory and file shows %d Errors\n",errors);
	}
	@catch(NSException* localException) {
		NSLog(@"Could not download eCpu code. Vme exception.\n");
		[localException raise];
	}
}

- (NSData*) codeAsData
{
	// check that default download file exists and setup reply record
	NSFileManager* manager = [NSFileManager defaultManager];
	NSString* theFile = [[self fileName] stringByExpandingTildeInPath];
	if(![manager fileExistsAtPath:theFile]){
		[NSException raise:@"No DownLoad File" format:@"Couldn't Find: <%@>",[self fileName]];
	}
	NSData* theCodeAsData = [NSMutableData dataWithContentsOfFile:[theFile stringByAppendingString:@"/rsrc"]];	
	if(!theCodeAsData){
		//oh-oh! There is something serious going on......
		//try again
		theCodeAsData = [NSMutableData dataWithContentsOfFile:[theFile stringByAppendingString:@"/rsrc"]];	
		if(!theCodeAsData){
			//give up
			[NSException raise:@"No DownLoad File" format:@"Couldn't Open: <%@>",[self fileName]];
		}
	}
	return theCodeAsData;
}

- (NSData*) dumpCodeFrom:(unsigned long)startAddress length:(unsigned long)numBytes
{
    int i;
    NSMutableData* buffer = [NSMutableData dataWithCapacity:4096];
    for(i=0;i<numBytes;i++){
		unsigned char val;
		[[self adapter] readByteBlock:&val
                            atAddress:(startAddress+i)
                            numToRead:1
                           withAddMod:0x39
                        usingAddSpace:kAccessRemoteRAM];
		[buffer appendBytes:&val length:1];
    }
	return buffer;
}

- (void) verifyCode
{
	NSData *theCodeData = [self codeAsData];
	codeLength = *((unsigned long*)[theCodeData bytes] + 0x100/4);
	unsigned char* code_start_ptr = (unsigned char*)[theCodeData bytes] + 0x100 + sizeof(unsigned long);
    
	NSLog(@"checking code\n");
	unsigned long errors = 0;
	short i;
	for(i=0;i<codeLength;i++){
		unsigned char val;
		[[self adapter] readByteBlock:&val
                            atAddress:(USER_CODE_ADDRESS+i)
                            numToRead:1
                           withAddMod:0x39
                        usingAddSpace:kAccessRemoteRAM];
		if(val != *(code_start_ptr+i)){
			errors++;
		}
	}
	NSLog(@"Comparison of eCPU memory and file shows %d Errors\n",errors);
    
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    
    powerFailed = NO;
    
    if(![[self adapter] controllerCard]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
	unsigned short ival;
	[[self adapter] readWordBlock:&ival
                        atAddress:USER_STOP_CODE_FLAG
                        numToRead:1
                       withAddMod:0x39
					usingAddSpace:kAccessRemoteRAM];
	if(ival != STOP_FLAG){
		[[self adapter] readWordBlock:&ival
                            atAddress:USER_START_CODE_FLAG
                            numToRead:1
                           withAddMod:0x39
                        usingAddSpace:kAccessRemoteRAM];
		if(ival == 0x5555){
			NSLog(@"eCPU code already running.\n");
			[self stopUserCode];
		}
	}
    
	dataTakers = [[readOutGroup allObjects] retain];	//cache of data takers.
    
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
    
    //download the eCPU code, but don't start it yet. the start is
    //actually done in the takedata loop to ensure that all the
    //initialization of all the other cards is done before the eCPU
    //starts taking data.
	//if([[userInfo objectForKey:@"doinit"]intValue]){
    [self downloadUserCode];
	//}
	//else {
	//	NSLog(@"eCPU code download skipped for quickstart\n");
	//}
	
    //zero out the critical data structures in the DPM. Note that the eCPU is not
    //running at this time.
	memset(&communicationBlock,0,sizeof(eCPU_MAC_DualPortComm));
	memset(&dualPortControl,0,sizeof(eCPUDualPortControl));
	
    [[self adapter] writeLongBlock:(unsigned long*)&communicationBlock
                         atAddress:MAC_DPM(COMM_ADDRESS_START)
                        numToWrite:sizeof(eCPU_MAC_DualPortComm)/4
                        withAddMod:0x09
                     usingAddSpace:kAccessRemoteDRAM];
	
	[[self adapter] writeLongBlock:(unsigned long*)&dualPortControl
                         atAddress:MAC_DPM(CONTROL_ADDRESS_START)
                        numToWrite:sizeof(eCPUDualPortControl)/sizeof(long)
                        withAddMod:0x09
                     usingAddSpace:kAccessRemoteDRAM];
	
    //load all the data needed for the eCPU to do the HW read-out.
	[self load_HW_Config];
	
    startedCode = NO;    
	
	if(![self circularBufferReader]){
		ORCircularBufferReader* cb = [[ORCircularBufferReader alloc] init];
		[self setCircularBufferReader:cb];
		[cb setAdapter:[self adapter]];
		[cb clear];
		[cb release];
	}
	
	[eCpuDeadAlarm clearAlarm];
	missedHeartBeat = 0;
	isRunning = YES;
	
	[self update];
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(startedCode){
        if([circularBufferReader takeData:aDataPacket userInfo:userInfo]){
            if(!lastQueUpdate || fabs([lastQueUpdate timeIntervalSinceNow]) > 1){
                [self setLastQueUpdate:[NSDate date]];
                [[NSNotificationCenter defaultCenter]
				 postNotificationName:OReCPU147QueChanged
				 object:self];
                
            }
        }
    }
    else {
		startedCode = YES;
		//[self performSelectorOnMainThread:@selector(downloadWithRetryAndStart) withObject:nil waitUntilDone:YES];
		[self startUserCodeWithRetries:1];
    }
}

- (void) downloadWithRetryAndStart
{
	[self startUserCodeWithRetries:1];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    startedCode = NO;
	isRunning = NO;
	if(!powerFailed){
        [self stopUserCode];
    }
    
	[circularBufferReader runTaskStopped:aDataPacket userInfo:(NSDictionary*)userInfo];
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:OReCPU147QueChanged
	 object:self];
    
    
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStopped:aDataPacket userInfo:userInfo];
    }
	[self update];
	[self setCircularBufferReader:nil];
}

- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [readOutGroup saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setReadOutGroup:[[[ORReadOutList alloc] initWithIdentifier:@"Scope A"]autorelease]];
    [readOutGroup loadUsingFile:aFile];
}

- (void) reset
{
}

- (void) load_HW_Config
{
	NSEnumerator* e = [dataTakers objectEnumerator];
	id obj;
	int index = 0;
	VME_crate_config configStruct;
	
	configStruct.total_cards = 0;
    
	while(obj = [e nextObject]){
		if([obj respondsToSelector:@selector(load_eCPU_HW_Config_Structure:index:)]){
			index = [obj load_eCPU_HW_Config_Structure:&configStruct index:index];
		}
	}
    
    
	[[self adapter] writeLongBlock:(unsigned long*)&configStruct
                         atAddress:MAC_DPM(CHW_CONFIG_START)
                        numToWrite:sizeof(VME_crate_config)/sizeof(long)
                        withAddMod:0x09
                     usingAddSpace:kAccessRemoteDRAM];
}

#pragma mark •••Archival
static NSString *OReCPUDownLoadFileName 	= @"download file name";
static NSString *OReCPUReadOutGroup1		= @"OReCPU ReadOut Group 1";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	
    [self setFileName:[decoder decodeObjectForKey:OReCPUDownLoadFileName]];
	[self setReadOutGroup:[decoder decodeObjectForKey:OReCPUReadOutGroup1]];
	
    [[self undoManager] enableUndoRegistration];
	
    [self registerNotificationObservers];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[self fileName] forKey:OReCPUDownLoadFileName];
	[encoder encodeObject:[self readOutGroup] forKey:OReCPUReadOutGroup1];
}

#pragma mark •••Updating

- (void) update
{
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(update) object:nil];
    
	@try {
		[[self adapter] readLongBlock:(unsigned long*)&communicationBlock
                            atAddress:MAC_DPM(COMM_ADDRESS_START)
                            numToRead:sizeof(eCPU_MAC_DualPortComm)/4
                           withAddMod:0x09
                        usingAddSpace:kAccessRemoteDRAM];
        
		cbControlBlockHeader = [circularBufferReader readControlBlockHeader];
        
		[self readDualPortControl];
        
        
        if(isRunning){
            if(communicationBlock.heartbeat == oldHeartBeat){
                if(++missedHeartBeat == 3){
                    if(!eCpuDeadAlarm){
                        eCpuDeadAlarm = [[ORAlarm alloc] initWithName:@"eCPU appears dead" severity:kDataFlowAlarm];
                        [eCpuDeadAlarm setSticky:NO];
                        [eCpuDeadAlarm setHelpStringFromFile:@"eCPUDeadHelp"];
                    }
                    if(![eCpuDeadAlarm isPosted]){
                        [eCpuDeadAlarm setAcknowledged:NO];
                        [eCpuDeadAlarm postAlarm];
                    }
                }
            }
            else {
                oldHeartBeat = communicationBlock.heartbeat;
                missedHeartBeat = 0;
            }	
        }
        
        
        
	}
	@catch(NSException* localException) {
		memset(&communicationBlock,0,sizeof(eCPU_MAC_DualPortComm));
	}
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:OReCPU147StructureUpdated
	 object:self];
	
	
	if([self updateInterval] && isRunning){
		[self performSelector:@selector(update) withObject:nil afterDelay:[self updateInterval]];
	}
}

- (void) incDebugLevel
{
    
	[self readDualPortControl];
	
	dualPortControl.ecpu_dbg_level = (dualPortControl.ecpu_dbg_level+1)%4;
    
	[self writeDualPortControl];
}


- (void) readDualPortControl
{
	[[self adapter] readLongBlock:(unsigned long*)&dualPortControl
                        atAddress:MAC_DPM(CONTROL_ADDRESS_START)
                        numToRead:sizeof(eCPUDualPortControl)/sizeof(long)
                       withAddMod:0x09
                    usingAddSpace:kAccessRemoteDRAM];
	
}

- (void) writeDualPortControl
{
	[[self adapter] writeLongBlock:(unsigned long*)&dualPortControl
                         atAddress:MAC_DPM(CONTROL_ADDRESS_START)
                        numToWrite:sizeof(eCPUDualPortControl)/sizeof(long)
                        withAddMod:0x09
                     usingAddSpace:kAccessRemoteDRAM];
	
}


- (void) getQueMinValue:(unsigned long*)aMinValue maxValue:(unsigned long*)aMaxValue head:(unsigned long*)aHeadValue tail:(unsigned long*)aTailValue
{
	unsigned char offsetToFirstCBWord = sizeof(SCBHeader)-sizeof(tCBWord);
	*aMinValue = MAC_DPM(DATA_CIRC_BUF_START)+offsetToFirstCBWord;
	*aMaxValue = MAC_DPM(DATA_CIRC_BUF_START)+DATA_CIRC_BUF_SIZE_BYTE-offsetToFirstCBWord;
    
	if(circularBufferReader)[circularBufferReader getQueHead:aHeadValue tail:aTailValue];
	else {
		*aHeadValue = 0;
		*aTailValue = 0;
	}
}


- (NSString*) messageString:(short) error_index
{
	short error_type = communicationBlock.msg_value[error_index]; //get the error type (used as index)
	short i;
	NSMutableString* aString = [NSMutableString stringWithCapacity:512];
	if(error_type>=0 && error_type<=10){
		[aString appendFormat:@"%2d %@ ",error_index,ecpu_err[error_type].message];
		for(i=0;i<NUM_MSG_PARAMS;i++){
			[self addParamsToMessage:aString index:error_index paramIndex:i];
		}
		[aString appendString:@"\n"];
	}
	else {
		[aString appendFormat:@"%2d Illegal error_type: %d\n",error_index,error_type];
	}
	return aString;
}

- (NSString*) errorString:(short) error_index
{
	short error_type = communicationBlock.error_value[error_index]; //get the error type (used as index)
	short i;
	NSMutableString* aString = [NSMutableString stringWithCapacity:512];
	if(error_type>=0 && error_type<=10){
		[aString appendFormat:@"%2d %@ ",error_index,ecpu_err[error_type].message];
		for(i=0;i<NUM_ERR_PARAMS;i++){
			[self addParamsToError:aString index:error_index paramIndex:i];
		}
		[aString appendString:@"\n"];
	}
	else{
		[aString appendFormat:@"%2d Illegal error_type: %d\n",error_index,error_type];
	}
	return aString;
}

- (void) addParamsToMessage:(NSMutableString*)aString index:(unsigned short) an_Index paramIndex:(unsigned short) aParamIndex
{
	switch(aParamIndex){
		case 0: if(communicationBlock.msg_parm0[an_Index]!=0){
            [aString appendFormat:@" [%@]",[[[NSString alloc] initWithBytes:&communicationBlock.msg_parm0[an_Index] length:4 encoding:NSASCIIStringEncoding]autorelease]];
        }
		else [aString appendFormat:@" [%lu]",communicationBlock.msg_parm0[an_Index]];
            break;
		case 1: [aString appendFormat:@" [%lu]",communicationBlock.msg_parm1[an_Index]];break;
		case 2: [aString appendFormat:@" [%lu]",communicationBlock.msg_parm2[an_Index]];break;
		case 3: [aString appendFormat:@" [%lu]",communicationBlock.msg_parm3[an_Index]];break;
		case 4: [aString appendFormat:@" [0x%lx]",communicationBlock.msg_parm4[an_Index]];break;
		default: return;
	}
}

- (void) addParamsToError:(NSMutableString*)aString index:(unsigned short) an_Index paramIndex:(unsigned short) aParamIndex
{
	switch(aParamIndex){
		case 0: if(communicationBlock.er_parm0[an_Index]!=0){
            [aString appendFormat:@" [%@]",[[[NSString alloc] initWithBytes:&communicationBlock.er_parm0[an_Index] length:4 encoding:NSASCIIStringEncoding]autorelease]];
        }
		else [aString appendFormat:@" [%lu]",communicationBlock.er_parm0[an_Index]];
            break;
		case 1: [aString appendFormat:@" [%lu]",communicationBlock.er_parm1[an_Index]];break;
		case 2: [aString appendFormat:@" [%lu]",communicationBlock.er_parm2[an_Index]];break;
		case 3: [aString appendFormat:@" [%lu]",communicationBlock.er_parm3[an_Index]];break;
		case 4: [aString appendFormat:@" [0x%lx]",communicationBlock.er_parm4[an_Index]];break;
		default: return;
	}
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:fileName?fileName:@"" forKey:@"fileName"];
    return objDictionary;
}
@end
