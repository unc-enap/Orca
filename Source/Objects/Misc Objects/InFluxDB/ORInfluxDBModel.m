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

NSString* ORInFluxDBPortNumberChanged           = @"ORInFluxDBPortNumberChanged";
NSString* ORInFluxDBAuthTokenChanged            = @"ORInFluxDBAuthTokenChanged";
NSString* ORInFluxDBOrgChanged                  = @"ORInFluxDBOrgChanged";
NSString* ORInFluxDBBucketChanged               = @"ORInFluxDBBucketChanged";
NSString* ORInFluxDBHostNameChanged             = @"ORInFluxDBHostNameChanged";
NSString* ORInFluxDBModelDBInfoChanged	        = @"ORInFluxDBModelDBInfoChanged";
NSString* ORInFluxDBTimeConnectedChanged        = @"ORInFluxDBTimeConnectedChanged";
NSString* ORInFluxDBLock				        = @"ORInFluxDBLock";

static NSString* ORInFluxDBModelInConnector 	= @"ORInFluxDBModelInConnector";

@interface ORInFluxDBModel (private)
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
    [hostName           release];
	[super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
        //[self createDatabases];
        [self _startAllPeriodicOperations];
        [self registerNotificationObservers];
    }
    [super wakeUp];
}


- (void) sleep
{
    [self _cancelAllPeriodicOperations];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super sleep];
}

- (BOOL) solitaryObject
{
    return YES;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"InFlux"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORInFluxDBController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORInFluxDBModelInConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB I' ];
	[ aConnector addRestrictedConnectionType: 'DB O' ]; //can only connect to DB outputs
	
    [aConnector release];
}

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
    [[ORInFluxDBQueue sharedInFluxDBQueue] cancelAllOperations];
 }

- (void) awakeAfterDocumentLoaded
{
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
    if(aPort == 0)aPort = 5984;
    
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
- (NSString*)   authToken
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
- (NSString*)   org
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
- (void) _cancelAllPeriodicOperations
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) _startAllPeriodicOperations
{
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{    
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setHostName:     [decoder decodeObjectForKey: @"HostName"]];
    [self setPortNumber:   [decoder decodeIntegerForKey:@"PortNumber"]];
    [self setAuthToken:    [decoder decodeObjectForKey:@"Token"]];
    [self setOrg:          [decoder decodeObjectForKey:@"Org"]];
    [self setBucket:       [decoder decodeObjectForKey:@"Bucket"]];
    [[self undoManager] enableUndoRegistration];
	[self registerNotificationObservers];
   return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:portNumber   forKey:@"PortNumber"];
    [encoder encodeObject:hostName      forKey:@"HostName"];
    [encoder encodeObject:authToken     forKey:@"Token"];
    [encoder encodeObject:org           forKey:@"Org"];
    [encoder encodeObject:bucket        forKey:@"Bucket"];
}

- (void) testPost
{
    // Create the request.
    NSString* tokenHeader   = [NSString stringWithFormat:@"Token %@",[self authToken]];
    NSString* requestString = [NSString stringWithFormat:@"http://%@:%ld/api/v2/write?org=%@&bucket=%@&precision=ns",hostName,portNumber,org,bucket];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
        
    // Specify that it will be a POST request
    request.HTTPMethod = @"POST";
        
    // This is how we set header fields
    [request setValue:@"text/plain; charset=utf-8"    forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"text/plain; application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:tokenHeader                     forHTTPHeaderField:@"Authorization"];

    // Convert your data and set your request's HTTPBody property
    NSString *stringData = @"airSensors,sensor_id=TLM0202 temperature=0,humidity=100";
    NSData *requestBodyData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestBodyData;
        
    // Create url connection and fire request
    [[[NSURLConnection alloc] initWithRequest:request delegate:self]autorelease];
}

- (void) clearCounts
{
    [self setTotalSent:0];
    [self setAmountInBuffer:0];
}
- (uint32_t)amountInBuffer
{
    return amountInBuffer;
}

- (void)setAmountInBuffer:(uint32_t)anAmountInBuffer
{
    amountInBuffer = anAmountInBuffer;
}
- (uint64_t)totalSent
{
    return totalSent;
}

- (void)setTotalSent:(uint64_t)aTotalSent
{
    totalSent = (uint32_t)aTotalSent;
}

#pragma mark NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
    NSLog(@"%@",[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
}
@end

//-----------------------------------------------------------
//ORInFluxQueue: A shared queue for InFluxdb access. You should
//never have to use this object directly. It will be created
//on demand when a InFluxDB op is called.
//-----------------------------------------------------------
@implementation ORInFluxDBQueue
SYNTHESIZE_SINGLETON_FOR_ORCLASS(InFluxDBQueue);
+ (NSOperationQueue*) queue             { return [[ORInFluxDBQueue sharedInFluxDBQueue] queue];              }
+ (void) addOperation:(NSOperation*)anOp{ [[ORInFluxDBQueue sharedInFluxDBQueue] addOperation:anOp];         }
+ (NSUInteger) operationCount            { return     [[ORInFluxDBQueue sharedInFluxDBQueue] operationCount];  }
+ (void)       cancelAllOperations       { [[ORInFluxDBQueue sharedInFluxDBQueue] cancelAllOperations]; }

//don't call this unless you're using this class in a special, non-global way.
- (id) init
{
    self = [super init];
    queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:4];

    return self;
}

- (NSOperationQueue*) queue                 { return queue;                     }
- (void) addOperation:(NSOperation*)anOp    { [queue addOperation:anOp];        }
- (void) cancelAllOperations                {[queue cancelAllOperations];       }
- (NSInteger) operationCount                { return [[queue operations]count]; }

@end
