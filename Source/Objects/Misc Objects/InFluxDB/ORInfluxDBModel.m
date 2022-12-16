//
//  ORInFluxDBModel.m
//  Orca
//
//  Created by Mark Howe on 12/7/2022.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORInFluxDBModel.h"
#import "NSNotifications+Extensions.h"
#import "SynthesizeSingleton.h"
#import "Utilities.h"
#import "ORSafeQueue.h"

NSString* ORInFluxDBPortNumberChanged      = @"ORInFluxDBPortNumberChanged";
NSString* ORInFluxDBAuthTokenChanged       = @"ORInFluxDBAuthTokenChanged";
NSString* ORInFluxDBOrgChanged             = @"ORInFluxDBOrgChanged";
NSString* ORInFluxDBBucketChanged          = @"ORInFluxDBBucketChanged";
NSString* ORInFluxDBHostNameChanged        = @"ORInFluxDBHostNameChanged";
NSString* ORInFluxDBModelDBInfoChanged	   = @"ORInFluxDBModelDBInfoChanged";
NSString* ORInFluxDBTimeConnectedChanged   = @"ORInFluxDBTimeConnectedChanged";
NSString* ORInFluxDBAccessTypeChanged      = @"ORInFluxDBAccessTypeChanged";
NSString* ORInFluxDBSocketStatusChanged    = @"ORInFluxDBSocketStatusChanged";
NSString* ORInFluxDBRateChanged            = @"ORInFluxDBRateChanged";
NSString* ORInFluxDBLock				   = @"ORInFluxDBLock";

static NSString* ORInFluxDBModelInConnector = @"ORInFluxDBModelInConnector";

@interface ORInFluxDBModel (private)
//only for the telegraf socket mode with inFluxDB line format
- (void) setUpInFluxSocket;
- (void) openInFluxSocket;
- (void) closeInFluxSocket;
- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)event;
- (void) readIn:(NSString *)s;
- (void) writeOut:(NSString *)s;
@end

@implementation ORInFluxDBModel

#pragma mark ***Initialization

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [responseData release];
    [hostName      release];
    [tags          release];
    [processThread release];
    [timer         invalidate];
    [timer         release];

	[super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
        [self registerNotificationObservers];
    }
    [super wakeUp];
}

- (void) sleep
{
    canceled = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super sleep];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"InFlux"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORInFluxDBController"];
}

//- (void) makeConnectors
//{
//    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
//    [[self connectors] setObject:aConnector forKey:ORInFluxDBModelInConnector];
//    [aConnector setOffColor:[NSColor brownColor]];
//    [aConnector setOnColor:[NSColor magentaColor]];
//	[ aConnector setConnectorType: 'DB I' ];
//	[ aConnector addRestrictedConnectionType: 'DB O' ]; //can only connect to DB outputs
//	
//    [aConnector release];
//}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[notifyCenter removeObserver:self];
	
    [notifyCenter addObserver : self
                     selector : @selector(applicationIsTerminating:)
                         name : @"ORAppTerminating"
                       object : (ORAppDelegate*)[NSApp delegate]];
}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
 }

- (void) awakeAfterDocumentLoaded
{
    [self startTimer];
}

#pragma mark ***Accessors
- (id) nextObject
{
	return [self objectConnectedTo:ORInFluxDBModelInConnector];
}

- (NSUInteger) portNumber
{
    return portNumber;
}

- (void) setPortNumber:(NSUInteger)aPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortNumber:portNumber];
    if(aPort == 0)aPort = 8086;
    portNumber = aPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBPortNumberChanged object:self];
}

- (NSString*) hostName
{
    return hostName;
}

- (void) setHostName:(NSString*)aHostName
{
    if(!aHostName)aHostName = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setHostName:hostName];
    
    [hostName autorelease];
    hostName = [aHostName copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBHostNameChanged object:self];	
}

- (NSString*) authToken
{
    return authToken;
}

- (void) setAuthToken:(NSString*)aAuthToken
{
    if(!aAuthToken)aAuthToken = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setAuthToken:authToken ];
    
    [authToken autorelease];
    authToken = [aAuthToken copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBAuthTokenChanged object:self];
}

- (NSInteger) accessType
{
    return accessType;
}

- (void) setAccessType:(NSInteger)anAccessType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAccessType:accessType ];
    if(accessType != anAccessType){
        if(accessType==kUseInFluxHttpProtocol){
            if(inputStream)[self closeInFluxSocket];
            [self setPortNumber:8094];
            [self setUpInFluxSocket];
        }
        else {
            [self setPortNumber:8086];
            [self closeInFluxSocket];
        }
    }
    accessType = anAccessType;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBAccessTypeChanged object:self];
}

- (NSString*) org
{
    return org;
}

- (void) setOrg:(NSString*)anOrg
{
    if(!anOrg)anOrg = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setOrg:org ];
    
    [org autorelease];
    org = [anOrg copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBOrgChanged object:self];
}

- (NSString*)   bucket
{
    return bucket;
}

- (void) setBucket:(NSString*)aBucket
{
    if(!aBucket)aBucket = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setBucket:bucket ];
    
    [bucket autorelease];
    bucket = [aBucket copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBBucketChanged object:self];
}

- (BOOL) isConnected
{
    return isConnected;
}

- (void) setIsConnected:(BOOL)aNewIsConnected
{
    isConnected = aNewIsConnected;
}

- (void) startTimer
{
    [timer invalidate];
    [timer release];
    timer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(calcRate)userInfo:nil repeats:YES] retain];
}

- (void) calcRate
{
    messageRate = totalSent;
    totalSent = 0;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORInFluxDBRateChanged object:self];
}

- (NSInteger) messageRate        { return messageRate; }
- (BOOL)      cancelled       { return canceled; }
- (void)      markAsCanceled  { canceled = YES;  }


#pragma mark ***Measurements
- (void) setTags:(NSString*) someTags
{
    //example: "crate=1,card=0"
    [tags autorelease];
    tags = [someTags copy];

}
- (void) startMeasurement:(NSString*)aSection
{
    outputBuffer = [[NSMutableString alloc]init];
    [outputBuffer appendFormat:@"%@,%@ ",aSection,tags];
 }

//----------------measurement format----------------------
// airSensors,sensor_id=TLM0201 temperature=90.0,humidity=40.2
// airSensors,sensor_id=TLM0202 temperature=20,humidity=30.6
//--------------------------------------------------------

- (void) endMeasurement
{
    [self removeEndingComma];
    [outputBuffer appendFormat:@"   \n"];
}

- (void) removeEndingComma
{
    NSRange lastComma = [outputBuffer rangeOfString:@"," options:NSBackwardsSearch];

    if(lastComma.location == [outputBuffer length]-1) {
        [outputBuffer replaceCharactersInRange:lastComma
                                           withString: @""];
    }
}

- (void) addLong:(NSString*)aValueName withValue:(long)aValue
{
    [outputBuffer appendFormat:@"%@=%ld,",aValueName,aValue];
}

- (void) addDouble:(NSString*)aValueName withValue:(double)aValue
{
    [outputBuffer appendFormat:@"%@=%f,",aValueName,aValue];
}

- (void) addString:(NSString*)aValueName withValue:(NSString*)aValue
{
    [outputBuffer appendFormat:@"%@=%@,",aValueName,aValue];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{    
    self = [super initWithCoder:decoder];
    [[self undoManager]  disableUndoRegistration];
    [self setHostName:   [decoder decodeObjectForKey: @"HostName"]];
    [self setPortNumber: [decoder decodeIntegerForKey:@"PortNumber"]];
    [self setAccessType: [decoder decodeIntegerForKey:@"AccessType"]];
    [self setAuthToken:  [decoder decodeObjectForKey:@"Token"]];
    [self setOrg:        [decoder decodeObjectForKey:@"Org"]];
    [self setBucket:     [decoder decodeObjectForKey:@"Bucket"]];
    [[self undoManager]  enableUndoRegistration];
	[self registerNotificationObservers];
   return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:portNumber   forKey:@"PortNumber"];
    [encoder encodeInteger:accessType   forKey:@"AccessType"];
    [encoder encodeObject:hostName      forKey:@"HostName"];
    [encoder encodeObject:authToken     forKey:@"Token"];
    [encoder encodeObject:org           forKey:@"Org"];
    [encoder encodeObject:bucket        forKey:@"Bucket"];
}

- (void) testPost
{
    [self setTags:@"host=MarksLaptop,type=Mac"];
    [self startMeasurement:@"CPU"];
    [self addDouble:@"Val1" withValue:random_range(0,100)];
    [self addDouble:@"Val2" withValue:random_range(0,100)];
    [self endMeasurement];
    
        
//    [self startMeasurement:@"CPU1"];
//    [self addLong:@"Memory" withValue:12];
//    [self addLong:@"RamUsed" withValue:200.2];
//    [self endMeasurement];
    [self push];
}

- (void) push
{
    if(!processThread){
        processThread = [[NSThread alloc] initWithTarget:self selector:@selector(sendMeasurments) object:nil];
        [processThread start];
    }
    if(!messageQueue){
        messageQueue = [[ORSafeQueue alloc] init];
    }
    [messageQueue enqueue:[outputBuffer dataUsingEncoding:NSASCIIStringEncoding]];

    [outputBuffer release];
    outputBuffer = nil;
}

#pragma mark NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [responseData release];
    responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to the instance variable you declared
    [responseData appendData:data];
    NSLog(@"%@\n",[[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]autorelease]);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    return nil; // Not need to cache response
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [responseData release];
    responseData = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@\n",error);
}

- (uint32_t) queueMaxSize
{
    return 1000;
}

#pragma mark ***Thread
- (void)sendMeasurments
{
    NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
    if(!messageQueue){
        messageQueue = [[ORSafeQueue alloc] init];
    }

    do {
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        NSData* theData = [messageQueue dequeue];
        if(theData){
            NSString* measurements = [[[NSString alloc] initWithData:theData encoding:NSASCIIStringEncoding]autorelease];
            if(accessType == kUseInFluxHttpProtocol){
                //-----access type is via inFluxDB http format-----
                NSString* tokenHeader   = [NSString stringWithFormat:@"Token %@",[self authToken]];
                NSString* requestString = [NSString stringWithFormat:@"http://%@:%ld/api/v2/write?org=%@&bucket=%@&precision=ns",hostName,portNumber,org,bucket];
                NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
                request.HTTPMethod = @"POST";
                [request setValue:@"text/plain; charset=utf-8"    forHTTPHeaderField:@"Content-Type"];
                [request setValue:@"text/plain; application/json" forHTTPHeaderField:@"Accept"];
                [request setValue:tokenHeader                     forHTTPHeaderField:@"Authorization"];
                
                NSData *requestBodyData = [measurements dataUsingEncoding:NSUTF8StringEncoding];
                request.HTTPBody = requestBodyData;

                // Create url connection and fire request
                [[[NSURLConnection alloc] initWithRequestinitWithRequest:request delegate:self]autorelease];
                totalSent += [measurements length];

            }
            else {
                //-----access type is via telegraf socket-----
                if(!inputStream) [self setUpInFluxSocket];
                [self writeOut:measurements];
            }
        }
        [NSThread sleepForTimeInterval:.001];
        [pool release];
    }while(!canceled);
    [self closeInFluxSocket];
    [outerPool release];
}

#pragma mark ***Access Via Telegraf thread
- (short) socketStatus
{
    return socketStatus;
}
- (void) setSocketStatus:(short)aState
{
    socketStatus = aState;
    if( socketStatus == NSStreamStatusNotOpen ||
        socketStatus == NSStreamStatusOpening ||
        socketStatus == NSStreamStatusClosed  ||
        socketStatus == NSStreamStatusError) {
            [self setIsConnected:NO];
    }
    else [self setIsConnected:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBSocketStatusChanged object:self];
}

- (void) setUpInFluxSocket
{
    NSString* finalHost = [[hostName copy]autorelease];
    if(![finalHost hasPrefix:@"http://"]){
        finalHost = [NSString stringWithFormat:@"http://%@",finalHost];
    }
    NSURL *url = [NSURL URLWithString:finalHost];
    
    NSLog(@"Setting up connection to Telegraf at %@ : %d\n", [url absoluteString], portNumber);
    
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (CFStringRef)[url host], (uint32_t)portNumber, &readStream, &writeStream);
    
    if(!CFWriteStreamOpen(writeStream)) {
        NSLog(@"Error, telegraf writeStream not open\n");
        return;
    }
    [self openInFluxSocket];
    [self setSocketStatus:[outputStream streamStatus]];
}

- (void)openInFluxSocket
{
    inputStream = (NSInputStream *)readStream;
    outputStream = (NSOutputStream *)writeStream;
    
    [inputStream retain];
    [outputStream retain];
    
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    [outputStream open];
    [self setSocketStatus:[outputStream streamStatus]];
}

- (void)closeInFluxSocket
{
    NSLog(@"Closing InFluxDB\n");
    
    [inputStream  close];
    [outputStream close];
    
    [inputStream  removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream setDelegate:nil];
    [outputStream setDelegate:nil];
    
    [inputStream release];
    [outputStream release];
    
    inputStream  = nil;
    outputStream = nil;
    [self setSocketStatus:NSStreamStatusClosed];
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event
{
    switch(event) {
        case NSStreamEventHasSpaceAvailable: {
            if(stream == outputStream) {
            }
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            if(stream == inputStream) {
                uint8_t buf[1024];
                NSInteger len = [inputStream read:buf maxLength:1024];
                
                if(len > 0) {
                    NSMutableData* data=[[NSMutableData alloc] initWithLength:0];
                    [data appendBytes: (const void *)buf length:len];
                    NSString *s = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                    
                    [self readIn:s];
                    [data release];
                }
            }
            break;
        }
        default: {
            [self setSocketStatus:[outputStream streamStatus]];
            break;
        }
    }
}

- (void)readIn:(NSString *)s
{
    NSLog(@"InFluxDB Socket: %@\n", s);
}

- (void)writeOut:(NSString *)s
{
    uint8_t *buf = (uint8_t *)[s UTF8String];
    [outputStream write:buf maxLength:strlen((char *)buf)];
    totalSent += [s length];
    //NSLog(@"%@", s);
}

@end
