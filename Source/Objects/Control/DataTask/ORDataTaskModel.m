//
//  ORDataTaskModel.m
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
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

#pragma mark ¥¥¥Imported Files
#import "ORDataTaskModel.h"
#import "ORDataTaker.h"
#import "ORReadOutList.h"
#import "ORDataSet.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"
#import "ORDecoder.h"
#import "ORDataProcessing.h"

#pragma mark ¥¥¥Local Strings
NSString* ORDataTaskModelRefreshRateChanged = @"ORDataTaskModelRefreshRateChanged";
static NSString* ORDataTaskInConnector 	= @"Data Task In Connector";
static NSString* ORDataTaskDataOut      = @"Data Task Data Out Connector";

NSString* ORDataTaskQueueCountChangedNotification	= @"Data Task Queue Count Changed Notification";
NSString* ORDataTaskTimeScalerChangedNotification	= @"ORDataTaskTimeScalerChangedNotification";
NSString* ORDataTaskListLock						= @"ORDataTaskListLock";
NSString* ORDataTaskCycleRateChangedNotification	= @"ORDataTaskCycleRateChangedNotification";
NSString* ORDataTaskModelTimerEnableChanged			= @"ORDataTaskModelTimerEnableChanged";

#define kMaxQueueSize   10*1024
#define kQueueHighWater kMaxQueueSize*.90
#define kQueueLowWater  kQueueHighWater*.90
#define kProcessingBusy 1
#define kProcessingDone 0

@interface ORDataTaskModel (private)
- (void)   sendDataFromQueue;
- (void) shipPendingRecords:(ORDataPacket*)aDataPacket;
- (NSMutableArray*) readoutInfo:(id)anItem array:(NSMutableArray*)anArray;
@end

@implementation ORDataTaskModel

#pragma mark ¥¥¥initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setReadOutList:[[[ORReadOutList alloc] initWithIdentifier:@"Data Task ReadOut"]autorelease]];
    [[self undoManager] enableUndoRegistration];
	timerLock = [[NSLock alloc] init];
    [self registerNotificationObservers];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [timerLock release];
    	
    if(transferQueue){
        [transferQueue release];
        transferQueue = nil;
    }
    [dataTimer release];
    [mainTimer release];
	
    [queueFullAlarm clearAlarm];
    [queueFullAlarm release];
    [readOutList release];
    [dataTakers release];
	[theDecoder release];
    [recordsPending release];
    [lastFile release];
    [super dealloc];
}

- (void) sleep
{
    [super sleep];
    
    [queueFullAlarm clearAlarm];
    [queueFullAlarm release];
    queueFullAlarm = nil;
    
}

- (BOOL) solitaryObject
{
    return YES;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"DataTask"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORDataTaskController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Data_Read_out.html";
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(8,[self frame].size.height-[self frame].size.height/2+kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORDataTaskInConnector];
    [aConnector setOffColor:[NSColor purpleColor]];
    [aConnector setConnectorType:'RUNC'];
    [aConnector release];
    
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize-2,[self frame].size.height-[self frame].size.height/2+kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORDataTaskDataOut];
	[aConnector setIoType:kOutputConnector];
    [aConnector release];
    
}


-(void)registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[notifyCenter removeObserver:self];
    
    [notifyCenter addObserver: self
                     selector: @selector(queueRecordForShipping:)
                         name: ORQueueRecordForShippingNotification
                       object: nil];
    
}
#pragma mark ¥¥¥Accessors
- (int) refreshRate
{
    return refreshRate;
}

- (void) setRefreshRate:(int)aRefreshRate
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRefreshRate:refreshRate];
    
    refreshRate = aRefreshRate;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataTaskModelRefreshRateChanged object:self];
}
- (short) timeScaler
{
	return timeScaler;
}
- (void) setTimeScaler:(short)aValue
{
	if(aValue == 0)aValue = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeScaler:timeScaler];
    
	timeScaler = aValue;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDataTaskTimeScalerChangedNotification
	 object:self];
	
}

- (ORReadOutList*) readOutList
{
    return readOutList;
}

- (void) setReadOutList:(ORReadOutList*)someDataTakers
{
    [someDataTakers retain];
    [readOutList release];
    readOutList = someDataTakers;
}

- (void) removeOrcaObject:(id)anObject
{
    [readOutList removeOrcaObject:anObject];
}

- (unsigned long)cycleRate
{
	return cycleRate;
}
- (void) setCycleRate:(unsigned long)aRate
{
	cycleRate = cycleCount;
	cycleCount = 0;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDataTaskCycleRateChangedNotification
	 object:self];
}

// ===========================================================
// - queueCount:
// ===========================================================
- (unsigned long)queueCount
{
    return queueCount;
}

// ===========================================================
// - setQueueCount:
// ===========================================================
- (void)setQueueCount:(unsigned long)aQueueCount
{
    queueCount = aQueueCount;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDataTaskQueueCountChangedNotification
	 object:self];
    
}

- (unsigned long) queueMaxSize
{
    return kMaxQueueSize;
}

- (NSString *)lastFile
{
    return lastFile;
}

- (void)setLastFile:(NSString *)aLastFile
{
    [lastFile autorelease];
    lastFile = [aLastFile copy];
}

- (unsigned long) dataTimeHist:(int)index
{
    return dataTimeHist[index];
}
- (unsigned long) processingTimeHist:(int)index
{
    return processingTimeHist[index];
}

- (void) clearTimeHistogram
{
    memset(processingTimeHist,0,kTimeHistoSize*sizeof(unsigned long));
    memset(dataTimeHist,0,kTimeHistoSize*sizeof(unsigned long));
}

- (BOOL) timerEnabled
{
	return enableTimer;
}

- (void) setEnableTimer:(int)aState
{
	[timerLock lock];	//start critical section
	enableTimer = aState;
	if(enableTimer){
		[self clearTimeHistogram];
		if(!dataTimer)dataTimer = [[ORTimer alloc]init];
		if(!mainTimer)mainTimer = [[ORTimer alloc]init];
		[dataTimer start];
		[mainTimer start];
	}
	else {
		[dataTimer release];
		[mainTimer release];
		dataTimer = nil;
		mainTimer = nil;
	}
	[timerLock unlock];	//end critical section
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDataTaskModelTimerEnableChanged object:self];
}


#pragma mark ¥¥¥Run Management
- (void) runTaskStarted:(NSDictionary*)userInfo
{
	ORDataPacket* aDataPacket = [userInfo objectForKey:kDataPacket];
	if(processThreadRunning){
		NSLogColor([NSColor redColor],@"Processing Thread still running from last run\n");
	}
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCycleRate) object:nil];
	[self clearTimeHistogram];
    
    runStartTime = times(&runStartTmsTime); 
	
	if(enableTimer){
		[timerLock lock];	//start critical section
		if(!dataTimer) dataTimer = [[ORTimer alloc]init];
		if(!mainTimer) mainTimer = [[ORTimer alloc]init];
		[dataTimer start];
		[mainTimer start];
		[timerLock unlock];	//end critical section
	}
    
    //tell all data takers to get ready
	dataTakers = [[readOutList allObjects] retain];
    
	if([dataTakers count] == 0){
		NSLogColor([NSColor redColor],@"----------------------------------------------------------\n");
		NSLogColor([NSColor redColor],@"Warning: Run Started with empty readout list.\n");
		NSLogColor([NSColor redColor],@"----------------------------------------------------------\n");
	}
	
    cachedNumberDataTakers = [dataTakers count];

    if(cachedNumberDataTakers) cachedDataTakers = (id*)malloc(cachedNumberDataTakers * sizeof(id));
	
    int i;
    for(i=0;i<cachedNumberDataTakers;i++){
		id obj = [dataTakers objectAtIndex:i];
 		cachedDataTakers[i] = [obj retain];
		[obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
    
    
    //tell objects to add any additional data descriptions into the data description header.
    NSArray* objectList = [NSArray arrayWithArray:[[self document]collectObjectsRespondingTo:@selector(appendDataDescription:userInfo:)]];
    NSEnumerator* e = [objectList objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj appendDataDescription:aDataPacket userInfo:userInfo];
    }
	
	//---------------------------------------------------
	// comment out some in-development code.....
	NSMutableDictionary* eventDictionary = [NSMutableDictionary dictionary];
	[readOutList appendEventDictionary:eventDictionary topLevel:eventDictionary];
	if([eventDictionary count]){
		[aDataPacket addEventDescriptionItem:eventDictionary];
	}
	//---------------------------------------------------	
	
	if([dataTakers count]){
		[aDataPacket addReadoutDescription:[self readoutInfo:readOutList array:[NSMutableArray array]]];
	}
	
	[theDecoder release];
	theDecoder = [[ORDecoder alloc] initWithHeader:[aDataPacket fileHeader]];
		
	if(!transferQueue){
        transferQueue       = [[ORSafeQueue alloc] init];
    }
    
    //cache the next object
    nextObject =  [self objectConnectedTo: ORDataTaskDataOut];
    [nextObject runTaskStarted:userInfo];
	[nextObject setInvolvedInCurrentRun:YES];
	
	timeToStopProcessThread = NO;
    [NSThread detachNewThreadSelector:@selector(sendDataFromQueue) toTarget:self withObject:nil];
    
	cycleCount = 0;
	cycleRate  = 0;
    [self performSelector:@selector(doCycleRate) withObject:nil afterDelay:1];
	[aDataPacket startFrameTimer];
}

- (void) subRunTaskStarted:(NSDictionary*)userInfo
{
    nextObject =  [self objectConnectedTo: ORDataTaskDataOut];
    [nextObject subRunTaskStarted:userInfo];
}

- (void) setRunMode:(int)runMode
{
    nextObject =  [self objectConnectedTo: ORDataTaskDataOut];
	[nextObject setRunMode:runMode];
}

//-------------------------------------------------------------------------
//putDataInQueue -- operates out of the data taking thread it should not be
//called from anywhere else.
//-------------------------------------------------------------------------
- (void) putDataInQueue:(ORDataPacket*)aDataPacket force:(BOOL)forceAdd
{
	[aDataPacket addFrameBuffer:forceAdd];
    
    if([aDataPacket dataCount]){
        if([transferQueue count] < kQueueHighWater){
			BOOL result = [transferQueue tryEnqueueArray:[aDataPacket dataArray]];
			if(result) [aDataPacket clearData]; //remove old data
			else if(forceAdd){
				[transferQueue enqueueArray:[aDataPacket dataArray]];
                [aDataPacket clearData]; //remove old data
            }
        }
		else  [aDataPacket clearData]; //que is full throw it away.
		
    }
}
//-------------------------------------------------------------------------

//takeData...
//this operates out of the data taking thread. It should not be called from anywhere else.
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	
	//ship pending records.
	if(areRecordsPending){
		id rec;
		while((rec = [recordsPending dequeue])){
			[aDataPacket addData:rec];
		}
		areRecordsPending = NO;
	}
    
    int i=0;
	while(i<cachedNumberDataTakers){
        [cachedDataTakers[i] takeData:aDataPacket userInfo:userInfo];
		++i;
    }
    
	
    [aDataPacket addCachedData];
   //[self putDataInQueue:aDataPacket force:NO];
    [self putDataInQueue:aDataPacket force:YES];
	
	if(enableTimer){
		[timerLock lock];	//start critical section
		long delta = [dataTimer microseconds];
		if(timeScaler==0)timeScaler=1;
		if((delta/timeScaler) < kTimeHistoSize)dataTimeHist[(int)delta/timeScaler]++;
		else dataTimeHist[kTimeHistoSize-1]++;
		[dataTimer reset];
		[timerLock unlock];	//end critical section
	}
	++cycleCount;
}

- (void) runIsStopping:(NSDictionary*)userInfo
{
	ORDataPacket* aDataPacket = [userInfo objectForKey:kDataPacket];
    int i;
    for(i=0;i<cachedNumberDataTakers;i++){
		if([cachedDataTakers[i] respondsToSelector:@selector(runIsStopping:userInfo:)]){
			[cachedDataTakers[i] runIsStopping:aDataPacket userInfo:userInfo];
		}
	}
}

- (BOOL) doneTakingData
{
	BOOL allDone = NO;
	if(!cachedNumberDataTakers)return YES;
    int i;
    for(i=0;i<cachedNumberDataTakers;i++){
        allDone |= [cachedDataTakers[i] doneTakingData];
    }
	return allDone;
}

- (void) runTaskStopped:(NSDictionary*)userInfo
{
	ORDataPacket* aDataPacket = [userInfo objectForKey:kDataPacket];
    int i;
    for(i=0;i<cachedNumberDataTakers;i++){
        [cachedDataTakers[i] runTaskStopped:aDataPacket userInfo:userInfo];
		[cachedDataTakers[i] release];
    }
    if(cachedNumberDataTakers) free(cachedDataTakers);
    [self putDataInQueue:aDataPacket force:YES];	//last data packet for this run
    [aDataPacket addCachedData];					//data from other threads
    [self shipPendingRecords:aDataPacket];
    [self putDataInQueue:aDataPacket force:YES];	//last data packet for this run
	
	[nextObject runTaskStopped:userInfo];
	//wait for the processing queu to clear.
	float totalTime = 0;
    while([transferQueue count]){
		[ORTimer delay:1];
		totalTime += 1;
		if(totalTime > 8){
			NSLogColor([NSColor redColor], @"Continuing after data que didn't flush after 8 seconds.\n");
			break;
		}
	}	
	
	[nextObject endOfRunCleanup:userInfo];

    [self setQueueCount:[transferQueue count]];
	[self setCycleRate:0];
}

- (void) preCloseOut:(NSDictionary*)userInfo
{
    //a chance to do a preclean of the pending records
    ORDataPacket* aDataPacket = [userInfo objectForKey:kDataPacket];
    [self shipPendingRecords:aDataPacket];
}

- (void) closeOutRun:(NSDictionary*)userInfo
{
	ORDataPacket* aDataPacket = [userInfo objectForKey:kDataPacket];
    [self shipPendingRecords:aDataPacket];
    [self putDataInQueue:aDataPacket force:YES];	//last data packet for this run

    
    //issue a final call for actions at end of run time.
    NSDictionary* statusInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSNumber numberWithInt:eRunStopped], ORRunStatusValue,
								@"Last Call",                         ORRunStatusString,
								aDataPacket,                          @"DataPacket",
								nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRunFinalCallNotification
                                                        object: self
                                                      userInfo: statusInfo];
	
 	//wait for the processing queu to clear.
	if([transferQueue count])NSLog(@"Waiting on %d records in transfer queue\n",[transferQueue count]);
	float totalTime = 0;
    while([transferQueue count]){
		[ORTimer delay:.1];
		totalTime += .1;
		if(totalTime > 8){
			NSLogColor([NSColor redColor], @"Continuing after data que didn't flush after 8 seconds.\n");
			break;
		}
	}	
	if([transferQueue count]==0)NSLog(@"Transfer queue cleared successfully\n");
    else {
        NSLog(@"Transfer queue NOT clear -- Forcing a flush\n");
        [transferQueue removeAllObjects];
    }
	
	//wait for the processing thread to exit.
	if(processThreadRunning)NSLog(@"Waiting for transfer thread to exit\n");
	totalTime = 0;
    while(processThreadRunning){
		timeToStopProcessThread = YES;
		[ORTimer delay:.1];
		totalTime += .1;
		if(totalTime > 4){
			NSLogColor([NSColor redColor], @"Transfer Thread Failed to stop.....You should stop and restart ORCA!\n");
			break;
		}
	}	
	
	if(!processThreadRunning)NSLog(@"Transfer thread exited\n");
    //tell everyone it's over and done.
    [nextObject closeOutRun:userInfo];
	[nextObject setInvolvedInCurrentRun:NO];
	
	
	NSLog(@"Final end of run cleanup\n");
    nextObject = nil;
    
    [dataTakers release];
    dataTakers = nil;
    cachedNumberDataTakers = 0; 
    
    
	if(enableTimer){
		[timerLock lock];	//start critical section
		[dataTimer release];
		[mainTimer release];
        dataTimer = nil;
        mainTimer = nil;
		[timerLock unlock];	//end critical section
	}
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCycleRate) object:nil];
	[aDataPacket stopFrameTimer];
	[self setCycleRate:0];
	[self setQueueCount:0];
	
}


- (void) processData:(NSArray*)dataArray decoder:(ORDecoder*)aDecoder
{
    id obj =  [self objectConnectedTo: ORDataTaskDataOut];
    [obj processData:dataArray decoder:aDecoder];
}

#pragma mark ¥¥¥Archival
static NSString *ORDataTaskReadOutList 		= @"ORDataTask ReadOutList";
static NSString *ORDataTaskLastFile 		= @"ORDataTask LastFile";
static NSString *ORDataTaskTimeScaler		= @"ORDataTaskTimeScaler";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setRefreshRate:[decoder decodeIntForKey:@"ORDataTaskModelRefreshRate"]];
    [self setReadOutList:[decoder decodeObjectForKey:ORDataTaskReadOutList]];
    [self setLastFile:[decoder decodeObjectForKey:ORDataTaskLastFile]];
    [self setTimeScaler:[decoder decodeIntForKey:ORDataTaskTimeScaler]];
    [[self undoManager] enableUndoRegistration];
  	if(timeScaler==0)timeScaler = 1;
    
    timerLock = [[NSLock alloc] init];
    [self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:refreshRate forKey:@"ORDataTaskModelRefreshRate"];
    [encoder encodeObject:readOutList forKey:ORDataTaskReadOutList];
    [encoder encodeObject:lastFile forKey:ORDataTaskLastFile];
    [encoder encodeInt:timeScaler forKey:ORDataTaskTimeScaler];
}


#pragma mark ¥¥¥Save/Restore
- (void) saveReadOutListTo:(NSString*)fileName
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:fileName])[fileManager removeItemAtPath:fileName error:nil];
    [fileManager createFileAtPath:fileName contents:nil attributes:nil];
    NSFileHandle* theFile = [NSFileHandle fileHandleForWritingAtPath:fileName];
    [readOutList saveUsingFile:theFile];
    [theFile closeFile];
    NSLog(@"Saved ReadOut List to: %@\n",[fileName stringByAbbreviatingWithTildeInPath]);
}

- (void) loadReadOutListFrom:(NSString*)fileName
{
    
    [self setReadOutList:[[[ORReadOutList alloc] initWithIdentifier:@"Data Task ReadOut"]autorelease]];
    
    NSFileHandle* theFile = [NSFileHandle fileHandleForReadingAtPath:fileName];
    [readOutList loadUsingFile:theFile];
    [theFile closeFile];
    NSLog(@"Loaded ReadOut List from: %@\n",[fileName stringByAbbreviatingWithTildeInPath]);
}

- (void) queueRecordForShipping:(NSNotification*)aNote
{
    if(!recordsPending){
        recordsPending = [[ORSafeQueue alloc] init];
    }
    [recordsPending enqueue:[aNote object]];
	areRecordsPending = YES;
}

- (void) doCycleRate
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCycleRate) object:nil];
	[self setCycleRate:cycleCount];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDataTaskQueueCountChangedNotification
	 object:self];
    [self performSelector:@selector(doCycleRate) withObject:nil afterDelay:1];
}
@end

@implementation ORDataTaskModel (private)

//-----------------------------------------------------------
//sendDataFromQueue runs out of the processing thread
//-----------------------------------------------------------
- (void) sendDataFromQueue
{
	NSAutoreleasePool *threadPool = [[NSAutoreleasePool allocWithZone:nil] init];
	[NSThread setThreadPriority:.8];
    id theNextObject =  [self objectConnectedTo: ORDataTaskDataOut];
	BOOL flushMessagePrintedOnce = NO;
    BOOL timeToQuit              = NO;
	processThreadRunning = YES;
	BOOL singleProcessor = [[ORGlobal sharedGlobal]cpuCount] == 1;
    do {
		NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:nil] init];
 		unsigned long qc = [transferQueue count];
		if(qc){
			queueCount = qc;
			
			if(queueCount > kQueueHighWater ){
				if(!queueFullAlarm){
					NSLogColor([NSColor redColor],@"Data Queue > 90%% full!\n");
					NSLogError(@"Queue Filled",@"Data Read_out",nil);
					
					queueFullAlarm = [[ORAlarm alloc] initWithName:@"Data Queue Full" severity:kDataFlowAlarm];
					[queueFullAlarm setSticky:YES];
					[queueFullAlarm setAcknowledged:NO];
					[queueFullAlarm postAlarm];
				}
			}
			else if(queueFullAlarm && (queueCount < kQueueLowWater)){
				NSLog(@"Data Queue clearing.\n");
				[queueFullAlarm clearAlarm];
				[queueFullAlarm release];
				queueFullAlarm = nil;
			}
			
			@try { 
				NSArray* theDataArray = [transferQueue dequeueArray];
				if(theDataArray){
					[theNextObject processData:theDataArray decoder:theDecoder];
				}
			}
			@catch(NSException* localException) {
				NSLogError(@"Main Queue Exception",@"Data Read_out",nil);
			}
		}
		else {
			if(singleProcessor)[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		}
		
		if(enableTimer){
			[timerLock lock];	//start critical section
			float delta = [mainTimer microseconds];
			if(timeScaler==0)timeScaler = 1;
			if(delta/timeScaler<kTimeHistoSize)processingTimeHist[(int)delta/timeScaler]++;
			else processingTimeHist[kTimeHistoSize-1]++;
			[mainTimer reset];
			[timerLock unlock];	//end critical section
		}
		
		
		if(timeToStopProcessThread){
			queueCount = [transferQueue count];
			if(!flushMessagePrintedOnce){
				if(queueCount){
					NSLog(@"flushing %d block%@from processing queue\n",queueCount,(queueCount>1)?@"s ":@" ");
				}
				flushMessagePrintedOnce = YES;						
			}
			if(queueCount == 0)timeToQuit = YES;
		}
		[pool release];
	} while(!timeToQuit);
    processThreadRunning = NO;

	[threadPool	release];
	
}

- (void) shipPendingRecords:(ORDataPacket*)aDataPacket
{
	if(areRecordsPending){
		id rec;
		while((rec = [recordsPending dequeue])){
			[aDataPacket addData:rec];
		}
		areRecordsPending = NO;
	}
}

//recursively walk the readout list and produce a description that is used in the run header
- (NSMutableArray*) readoutInfo:(id)anItem array:(NSMutableArray*)anArray
{
	NSArray* someChildren;
	if([[anItem class] isSubclassOfClass: NSClassFromString(@"ORReadOutList")]){
		someChildren = [anItem children];
		if([someChildren count]){
			id aChild;
			NSEnumerator* e = [someChildren objectEnumerator];
			while(aChild = [e nextObject]){
				[self readoutInfo:aChild array:anArray];
			} 
		}
	}
	else if([[anItem class] isSubclassOfClass: NSClassFromString(@"ORReadOutObject")]){
		id anObj = [anItem object];
        //temp check for nil obj
        if(anObj){
            NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
            [objDictionary setObject:[anObj className] forKey:@"name"];
            id objGuardian = [anObj guardian];
            if([objGuardian isKindOfClass:NSClassFromString(@"ORCrate")]){
                [objDictionary setObject:[NSNumber numberWithInt:[anObj crateNumber]] forKey:@"crate"];
                if([anObj respondsToSelector:@selector(stationNumber)]){
                    [objDictionary setObject:[NSNumber numberWithInt:[anObj stationNumber]] forKey:@"station"];
                }
                else if([anObj respondsToSelector:@selector(slot)]){
                    [objDictionary setObject:[NSNumber numberWithInt:[anObj slot]] forKey:@"slot"];
                }
            }
            else {
                [objDictionary setObject:[NSNumber numberWithInt:[anObj uniqueIdNumber]] forKey:@"uniqueID"];
            }
            someChildren = [anObj children];
            if([someChildren count]){
                NSMutableArray* theChildArray = [NSMutableArray array];
                id aChild;
                NSEnumerator* e = [someChildren objectEnumerator];
                while(aChild = [e nextObject]){
                    [self readoutInfo:aChild array:theChildArray];
                } 
                [objDictionary setObject:theChildArray forKey:@"children"];
            }
            [anArray addObject:objDictionary];
        }
	}
	return anArray;
}

@end


