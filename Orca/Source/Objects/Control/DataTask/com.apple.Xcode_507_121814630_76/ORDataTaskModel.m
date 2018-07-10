//
//  ORDataTaskModel.m
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//
#pragma mark ¥¥¥Imported Files
#import "ORDataTaskModel.h"
#import "ORConnector.h"
#import "ORGroup.h"
#import "ORDataTaker.h"
#import "StatusLog.h"
#import "ORReadOutList.h"
#import "ORAlarm.h"
#import "ORGlobal.h"
#import "ORDataSet.h"
#import "ORDataPacket.h"
#import "ORHeaderSection.h"
#import "ORDataDescriptionItem.h"
#import "ORTimer.h"
#import "ORDataTypeAssigner.h"
#import "ThreadWorker.h"

#pragma mark ¥¥¥Local Strings
static NSString* ORDataTaskInConnector 	= @"Data Task In Connector";
static NSString* ORDataTaskDataOut      = @"Data Task Data Out Connector";

NSString* ORDataTaskCollectModeChangedNotification = @"Data Task Mode Changed Notification";
NSString* ORDataTaskQueueCountChangedNotification = @"Data Task Queue Count Changed Notification";
NSString* ORDataTaskTimeScalerChangedNotification = @"ORDataTaskTimeScalerChangedNotification";
NSString* ORDataTaskListLock		= @"ORDataTaskListLock";

#define HAS_DATA        0
#define HAS_NO_DATA     1

#define kMaxQueueSize   1024*1024
#define kQueueHighWater kMaxQueueSize*.90
#define kQueueLowWater  kQueueHighWater*.90

@interface ORDataTaskModel (private)
- (void) postQueueUpdate:(NSTimer*)aTimer;
- (void) sendDataFromQueue;
- (void) flushDataFromQueue;
- (void) shipPendingRecords:(ORDataPacket*)aDataPacket;
@end

@implementation ORDataTaskModel

#pragma mark ¥¥¥initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setReadOutList:[[[ORReadOutList alloc] initWithIdentifier:@"Data Task ReadOut"]autorelease]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [queueUpdateTimer invalidate];
    [queueUpdateTimer release];
    queueUpdateTimer = nil;
    
    [queueFullAlarm clearAlarm];
    [queueFullAlarm release];
    [readOutList release];
    [dataTakers release];
    [_privateLock release];
    [super dealloc];
}

- (void) sleep
{
    [super sleep];
    
    [queueUpdateTimer invalidate];
    [queueUpdateTimer release];
    queueUpdateTimer = nil;
    
    [queueFullAlarm clearAlarm];
    [queueFullAlarm release];
    queueFullAlarm = nil;
    
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"DataTask"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORDataTaskController"];
}


- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height-[self frame].size.height/2) withParent:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORDataTaskInConnector];
    [aConnector release];
    
    
    aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,[self frame].size.height-30 ) withParent:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORDataTaskDataOut];
    [aConnector release];
    
}


-(void)registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver: self
                     selector: @selector(queueRecordForShipping:)
                         name: ORQueueRecordForShippingNotification
                       object: nil];
    
}
#pragma mark ¥¥¥Accessors
- (short) timeScaler
{
	return timeScaler;
}
- (void) setTimeScaler:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeScaler:timeScaler];

	timeScaler = aValue;
	
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORDataTaskTimeScalerChangedNotification
                      object:self
                    userInfo: [NSDictionary dictionaryWithObject: self
                                                          forKey:ORNotificationSender]];
	
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

- (BOOL) collectMode
{
    return collectMode;
}
- (void) setCollectMode:(BOOL)newMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCollectMode:[self collectMode]];
    collectMode=newMode;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORDataTaskCollectModeChangedNotification
                      object:self
                    userInfo: [NSDictionary dictionaryWithObject: self
                                                          forKey:ORNotificationSender]];
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
    
    if(!queueUpdateTimer){
        queueUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(postQueueUpdate:) userInfo:nil repeats:NO] retain];
    }
}

- (float) mainThreadCpuTime
{
    return mainThreadCpuTime;
}

- (float) dataThreadCpuTime
{
    [ _privateLock lock];   
    float temp = dataThreadCpuTime;
    [ _privateLock unlock];   
    
    return temp;
}

- (void) setDataThreadCpuTime: (float) DataThreadCpuTime
{
    [ _privateLock lock];   
    dataThreadCpuTime = DataThreadCpuTime;
    [ _privateLock unlock];   
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

- (void) setEnableTimer:(int)aState
{
	enableTimer = aState;
	if(enableTimer){
		[self clearTimeHistogram];
		dataTimer = [[ORTimer alloc]init];
		mainTimer = [[ORTimer alloc]init];
		[dataTimer start];
		[mainTimer start];
	}
	else {
		[dataTimer release];
		[mainTimer release];
		dataTimer = nil;
		mainTimer = nil;
	}
}


#pragma mark ¥¥¥Run Management
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	[self clearTimeHistogram];
    
    runStartTime = times(&runStartTmsTime); 
    
	dataThreadCpuTime = 0; 
	mainThreadCpuTime = 0; 
    
	if(enableTimer){
		dataTimer = [[ORTimer alloc]init];
		mainTimer = [[ORTimer alloc]init];
		[dataTimer start];
		[mainTimer start];
	}
    
    //tell all data takers to get ready
    if(collectMode == kDataTaskAutoCollect){
        NSMutableArray* classList = [NSMutableArray arrayWithArray:[[self document]  collectObjectsConformingTo:@protocol(ORDataTaker)]];
        dataTakers = [classList retain];
        
    }
    else {
        dataTakers = [[readOutList allObjects] retain];
    }
    
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStarted:aDataPacket userInfo:userInfo];
    }
 
    //tell objects to add any additional data descriptions into the data description header.
    NSArray* objectList = [NSArray arrayWithArray:[[self document]collectObjectsRespondingTo:@selector(appendDataDescription:userInfo:)]];
    e = [objectList objectEnumerator];
    while(obj = [e nextObject]){
        [obj appendDataDescription:aDataPacket userInfo:userInfo];
    }
    
    [aDataPacket generateObjectLookup];	 //MUST be done before data header will work.
    
    //cache the next object
    nextObject =  [[[[self connectors] objectForKey: ORDataTaskDataOut]connector] objectLink];
    [nextObject runTaskStarted:aDataPacket userInfo:userInfo];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendDataFromQueue) object:nil];
    
    if(transferQueue){
        [transferQueue release];
        transferQueue = nil;
    }
    transferDataPacket  = [[aDataPacket copy]retain];
    [transferDataPacket generateObjectLookup];	 //MUST be done before data header will work.
    
    [aDataPacket clearData];
    
    transferQueue       = [[ORSafeQueue alloc] init];
        
    [self performSelector:@selector(sendDataFromQueue) withObject:nil afterDelay:0];
    
}

//takeData...
//this operates out of the data taking thread. It should not be called from anywhere else.
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{

    
    [self shipPendingRecords:aDataPacket];

    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj takeData:aDataPacket userInfo:userInfo];
    }
    
    [aDataPacket addCachedData];	 //data from other threads
    
    [self putDataInQueue:aDataPacket];
    
	if(enableTimer){
		float temp = [self  dataThreadCpuTime]; 
		float delta = [dataTimer microseconds];
		if(delta/[self timeScaler]<kTimeHistoSize)dataTimeHist[(int)delta/[self timeScaler]]++;
		else dataTimeHist[kTimeHistoSize-1]++;
		temp += delta/1000000.;
		[self setDataThreadCpuTime:temp];
		[dataTimer reset];
	}
}

//putDataInQueue -- operates out of the data thread
- (void) putDataInQueue:(ORDataPacket*)aDataPacket
{
	[aDataPacket addFrameBuffer];

    if([[aDataPacket dataArray] count]){
        if([transferQueue count] < kMaxQueueSize){
            if([transferQueue tryEnqueueArray:[aDataPacket dataArray]]){
                [aDataPacket clearData]; //remove old data
            }
        }
    }
}

//putDataInQueue -- operates out of the GUI thread


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [obj runTaskStopped:aDataPacket userInfo:userInfo];
    }
    
    
    [nextObject runTaskStopped:aDataPacket userInfo:userInfo];

    [self shipPendingRecords:aDataPacket];

    [self flushDataFromQueue];      //flush the queue (gets cached data from other threads)
    [self putDataInQueue:aDataPacket];	//last data packet for this run
    [self flushDataFromQueue];      //flush it out.
    
    [self setQueueCount:[transferQueue count]];

}

- (void) closeOutRun:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    NSLog(@"Flushing data queues\n");
    [self putDataInQueue:aDataPacket];	//last data packet for this run
    
    //tell everyone it's over and done.
    [self flushDataFromQueue];          //flush it out.
    [nextObject closeOutRun:aDataPacket userInfo:userInfo];
    [self setQueueCount:[transferQueue count]];
    
    [transferDataPacket release];
    transferDataPacket = nil;
    [transferQueue release];
    transferQueue = nil;
    nextObject = nil;

    [dataTakers release];
    dataTakers = nil;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendDataFromQueue) object:nil];

	if(enableTimer){
		[dataTimer release];
		[mainTimer release];
        dataTimer = nil;
        mainTimer = nil;
	}
}


- (void) processData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    id obj =  [[[[self connectors] objectForKey: ORDataTaskDataOut]connector] objectLink];
    [obj processData:aDataPacket userInfo:userInfo];
}

#pragma mark ¥¥¥Archival
static NSString *ORDataTaskReadOutList 		= @"ORDataTask ReadOutList";
static NSString *ORDataTaskCollectMode 		= @"ORDataTask CollectMode";
static NSString *ORDataTaskLastFile 		= @"ORDataTask LastFile";
static NSString *ORDataTaskTimeScaler		= @"ORDataTaskTimeScaler";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setReadOutList:[decoder decodeObjectForKey:ORDataTaskReadOutList]];
    [self setCollectMode:[decoder decodeBoolForKey:ORDataTaskCollectMode]];
    [self setLastFile:[decoder decodeObjectForKey:ORDataTaskLastFile]];
    [self setTimeScaler:[decoder decodeIntForKey:ORDataTaskTimeScaler]];
    [[self undoManager] enableUndoRegistration];
  	if(timeScaler=0)timeScaler = 1;
  
    
    [self registerNotificationObservers];
    _privateLock = [[NSLock alloc] init];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:readOutList forKey:ORDataTaskReadOutList];
    [encoder encodeBool:collectMode forKey:ORDataTaskCollectMode];
    [encoder encodeObject:lastFile forKey:ORDataTaskLastFile];
    [encoder encodeInt:timeScaler forKey:ORDataTaskTimeScaler];
}


#pragma mark ¥¥¥Save/Restore
- (void) saveReadOutListTo:(NSString*)fileName
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:fileName])[fileManager removeFileAtPath:fileName handler:nil];
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
        recordsPending = [[NSMutableArray alloc] initWithCapacity:256];
    }
    [recordsPending addObject:[aNote object]];
}
 

- (void) sendWorkerExited:(id)userInfo
{
    [senderThread release];
    senderThread = nil;
}

- (void)sendDataWorker:(id)userInfo thread:(id)tw
{
    NS_DURING
        
		
        //[self performSelector:@selector(sendDataFromQueue) withObject:nil afterDelay:0];
        
        [self setQueueCount:[transferQueue count]];
        
		if(queueCount){
            if(queueCount > kQueueHighWater ){
                if(!queueFullAlarm){
                    NSLogColor([NSColor redColor],@"Data Queue > 90%% full!\n");
                    NSLogError(@"Queue Filled",@"Data Read_out",nil);
                    
                    queueFullAlarm = [[ORAlarm alloc] initWithName:@"Data Queue Full" severity:0];
                    [queueFullAlarm setSticky:YES];
                    [queueFullAlarm setAcknowledged:NO];
                    [queueFullAlarm postAlarm];
                }
            }
            else if([transferQueue count] < kQueueLowWater){
                if(queueFullAlarm){
                    NSLog(@"Data Queue clearing.\n");
                    [queueFullAlarm clearAlarm];
                    [queueFullAlarm release];
                    queueFullAlarm = nil;
                }
            }
            
            [transferDataPacket addDataFromArray:[transferQueue dequeueArray]];
            [nextObject processData:transferDataPacket userInfo:nil];
            [transferDataPacket clearData];
        }
		
		if(enableTimer){
			float delta = [mainTimer microseconds];
			if(delta/[self timeScaler]<kTimeHistoSize)processingTimeHist[(int)delta/[self timeScaler]]++;
			else processingTimeHist[kTimeHistoSize-1]++;
			mainThreadCpuTime += delta/1000000.;
		}
		
		if(enableTimer)[mainTimer reset];


    NS_HANDLER
        NSLogError(@"Main Queue Exception",@"Data Read_out",nil);
    NS_ENDHANDLER
}


@end

@implementation ORDataTaskModel (private)

- (void) postQueueUpdate:(NSTimer*)aTimer
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORDataTaskQueueCountChangedNotification
                      object:self
                    userInfo: [NSDictionary dictionaryWithObject: self
                                                          forKey:ORNotificationSender]];
    
    
    [queueUpdateTimer invalidate];
    [queueUpdateTimer release];
    queueUpdateTimer = nil;
    
}
- (void) flushDataFromQueue
{
    while([transferQueue count]){
        [self sendDataFromQueue];
    }
}


- (void) sendDataFromQueue
{
    if(!senderThread){
        senderThread = [[ThreadWorker workOn:self withSelector:@selector(sendDataWorker:thread:)
                           withObject:nil
                       didEndSelector:@selector(sendWorkerExited:)] retain];
    }
}



- (void) shipPendingRecords:(ORDataPacket*)aDataPacket
{
    if([recordsPending count]){
        NSEnumerator* e = [recordsPending objectEnumerator];
        NSData* someData;
        while(someData = [e nextObject]){
            [aDataPacket addData:someData];
        }
        [recordsPending removeAllObjects];
    }
}
@end
