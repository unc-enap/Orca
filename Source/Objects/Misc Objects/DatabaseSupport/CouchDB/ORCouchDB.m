//
//  ORCouch.m
//  Orca
//
//  Created by Mark Howe on 02/19/11.
//  Copyright 20011, University of North Carolina
//-------------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORCouchDB.h"
//#import <YAJL/NSObject+YAJL.h>
//#import <YAJL/YAJLDocument.h>
#import "SynthesizeSingleton.h"

@implementation ORCouchDB

@synthesize database,host,port,queue,delegate,username,pwd;

+ (id) couchHost:(NSString*)aHost port:(NSUInteger)aPort username:(NSString*)aUsername pwd:(NSString*)aPwd database:(NSString*)aDatabase delegate:(id)aDelegate
{
	return [[[ORCouchDB alloc] initWithHost:aHost port:aPort username:aUsername pwd:aPwd database:aDatabase delegate:aDelegate] autorelease];
}

+ (id) couchHost:(NSString*)aHost port:(NSUInteger)aPort database:(NSString*)aDatabase delegate:(id)aDelegate
{
	return [[[ORCouchDB alloc] initWithHost:aHost port:aPort database:aDatabase delegate:aDelegate] autorelease];
}

- (id) initWithHost:(NSString*)aHost port:(NSUInteger)aPort database:(NSString*)aDatabase delegate:(id)aDelegate
{
	return [self initWithHost:aHost port:aPort username:nil pwd:nil database:aDatabase delegate:aDelegate];
}

- (id) initWithHost:(NSString*)aHost port:(NSUInteger)aPort username:(NSString*)aUsername pwd:(NSString*)aPwd database:(NSString*)aDatabase delegate:(id)aDelegate
{
	self = [super init];
	self.delegate = aDelegate;
	self.database = aDatabase;
	self.host = aHost;
	self.port = aPort;
	self.username = aUsername;
    self.pwd = aPwd;
	return self;
}

- (void) dealloc
{
	self.username	= nil;
	self.pwd		= nil;
    self.host       = nil;
	self.database	= nil;
	self.queue      = nil;
	[super dealloc];
}

- (void) version:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBVersionOp* anOp = [[ORCouchDBVersionOp alloc] initWithHost:host username:username pwd:pwd port:port database:nil delegate:aDelegate tag:aTag];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

#pragma mark •••DataBase API

- (void) compactDatabase:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBCompactDBOp* anOp = [[ORCouchDBCompactDBOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:aDelegate tag:aTag];
    [self setHttpTypeForOp:anOp delegate:aDelegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) setHttpTypeForOp:(ORCouchDBOperation*)anOp delegate:(id)aDelegate
{
    if([aDelegate respondsToSelector:@selector(useHttps)]){
        if([aDelegate useHttps])[anOp setHttpType:@"https:"];
        else [anOp setHttpType:@"http:"];
    }
    else [anOp setHttpType:@"http:"];
}
- (void) databaseInfo:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBInfoDBOp* anOp = [[ORCouchDBInfoDBOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:aDelegate tag:aTag];
    [self setHttpTypeForOp:anOp delegate:aDelegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) listDatabases:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBListDBOp* anOp = [[ORCouchDBListDBOp alloc] initWithHost:host username:username pwd:pwd port:port database:nil delegate:aDelegate tag:aTag];
    [self setHttpTypeForOp:anOp delegate:aDelegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) listTasks:(id)aDelegate tag:(NSString*)aTag
{
	ORCouchDBListTasksOp* anOp = [[ORCouchDBListTasksOp alloc] initWithHost:host username:username pwd:pwd port:port database:nil delegate:aDelegate tag:aTag];
    [self setHttpTypeForOp:anOp delegate:aDelegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}
- (void) createDatabase:(NSString*)aTag views:(NSDictionary*)theViews
{
	ORCouchDBCreateDBOp* anOp = [[ORCouchDBCreateDBOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag];
	if(theViews)[anOp setViews:theViews];
    [self setHttpTypeForOp:anOp delegate:delegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) addUpdateHandler:(NSString*)aTag updateHandler:(NSString*)anUpdateHandler
{
	ORCouchDBAddUpdateHandlerOp* anOp = [[ORCouchDBAddUpdateHandlerOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag];
	if(anUpdateHandler)[anOp setUpdateHandler:anUpdateHandler];
    [self setHttpTypeForOp:anOp delegate:delegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}


- (void) deleteDatabase:(NSString*)aTag;
{
	ORCouchDBDeleteDBOp* anOp = [[ORCouchDBDeleteDBOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag];
    [self setHttpTypeForOp:anOp delegate:delegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) replicateLocalDatabase:(NSString*)aTag continous:(BOOL)continuous
{
	ORCouchDBReplicateDBOp* anOp = [[ORCouchDBReplicateDBOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag];
    [self setHttpTypeForOp:anOp delegate:delegate];
	[anOp setContinuous:continuous];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}


#pragma mark •••Document API
- (void) deleteDocumentId:(NSString*)anId tag:(NSString*)aTag;
{
	ORCouchDBDeleteDocumentOp* anOp = [[ORCouchDBDeleteDocumentOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag];
	[anOp setDocumentId:anId];
    [self setHttpTypeForOp:anOp delegate:delegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) addDocument:(NSDictionary*)aDict tag:(NSString*)aTag;
{
	[self addDocument:aDict documentId:nil tag:aTag];
}

- (void) addDocument:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;
{
	ORCouchDBPutDocumentOp* anOp = [[ORCouchDBPutDocumentOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag];
	[anOp setDocument:aDict documentID:anId];
    [self setHttpTypeForOp:anOp delegate:delegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) updateLowPriorityDocument:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;
{
    ORCouchDBUpdateDocumentOp* anOp = [[ORCouchDBUpdateDocumentOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag];
    [anOp setDocument:aDict documentID:anId];
    [ORCouchDBQueue addLowPriorityOperation:anOp];
    [anOp release];
}


- (void) updateDocument:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;
{
	ORCouchDBUpdateDocumentOp* anOp = [[ORCouchDBUpdateDocumentOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag];
	[anOp setDocument:aDict documentID:anId];
    [self setHttpTypeForOp:anOp delegate:delegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) updateDocument:(NSDictionary*)aDict documentId:(NSString*)anId attachmentData:(NSData*)someData attachmentName:(NSString*)aName tag:(NSString*)aTag;
{
	ORCouchDBUpdateDocumentOp* anOp = [[ORCouchDBUpdateDocumentOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag];
	[anOp setDocument:aDict documentID:anId];
	[anOp setAttachment:someData];
	[anOp setAttachmentName:aName];
    [self setHttpTypeForOp:anOp delegate:delegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) updateDocument:(NSDictionary *)aDict documentId:(NSString *)anId tag:(NSString *)aTag informingDelegate:(BOOL)ok
{
    ORCouchDBUpdateDocumentOp* anOp = [[ORCouchDBUpdateDocumentOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag];
	[anOp setDocument:aDict documentID:anId];
    [anOp setInformDelegate:ok];
    [self setHttpTypeForOp:anOp delegate:delegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}
- (void) updateEventCatalog:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;
{
	ORCouchDBUpdateEventCatalogOp* anOp = [[ORCouchDBUpdateEventCatalogOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag];
	[anOp setDocument:aDict documentID:anId];
    [self setHttpTypeForOp:anOp delegate:delegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

- (void) getDocumentId:(NSString*)anId  tag:(NSString*)aTag
{
	ORCouchDBGetDocumentOp* anOp = [[ORCouchDBGetDocumentOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag];
	[anOp setDocumentId:anId];
    [self setHttpTypeForOp:anOp delegate:delegate];
	[ORCouchDBQueue addOperation:anOp];
	[anOp release];
}

#pragma mark ***Changes API
- (NSOperation*) changesFeedMode:(NSString*)mode tag:(NSString*)aTag
{
    return [self changesFeedMode:mode heartbeat:(NSUInteger)5000 tag:aTag];
}

- (NSOperation*) changesFeedMode:(NSString*)mode heartbeat:(NSUInteger)heartbeat tag:(NSString*)aTag
{
    return [self changesFeedMode:mode heartbeat:heartbeat  tag:aTag filter:nil];
}

- (NSOperation*) changesFeedMode:(NSString*)mode heartbeat:(NSUInteger)heartbeat tag:(NSString*)aTag filter:(NSString*)filter
{
    ORCouchDBChangesfeedOp* anOp=[[[ORCouchDBChangesfeedOp alloc] initWithHost:host username:username pwd:pwd port:port database:database delegate:delegate tag:aTag] autorelease];
    [anOp setListeningMode:mode];
    [anOp setHeartbeat:heartbeat];
    [anOp setFilter:filter];
	[ORCouchDBQueue addChangeFeedOperation:anOp];
	return anOp;
}

#pragma mark ***CouchDB Checks

@end

#pragma mark •••Threaded Ops
@interface ORCouchDBOperation (private)
- (void) _updateAuthentication:(NSMutableURLRequest*)request;
@end

@implementation ORCouchDBOperation (private)
- (void) _updateAuthentication:(NSMutableURLRequest*)request
{
 	if(username && pwd){
        // Add username/password to header
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, pwd];
        NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
        NSString *authValue = [authData base64Encoding];
        [request setValue:[NSString stringWithFormat:@"Basic %@",authValue] forHTTPHeaderField:@"Authorization"];
	}
}
@end
@implementation ORCouchDBOperation

@synthesize username,pwd,httpType;

- (id) initWithHost:(NSString*)aHost username:(NSString*)aUN pwd:(NSString*)aPwd port:(NSInteger)aPort database:(NSString*)aDB delegate:(id)aDelegate tag:(NSString*)aTag
{
	self = [super init];
	//normally a delegate would not be retained. In this case, we have
	//to ensure that the delegate is still around when the op executes
	//out of a thread
	delegate = [aDelegate retain];
	database = [aDB copy];
	tag		 = [aTag copy];
	host	 = [aHost copy];
	port	 = aPort;
	pwd      = [aPwd copy];
	username = [aUN copy];
    httpType = [@"http:" copy]; //default
    [self  setQueuePriority:NSOperationQueuePriorityHigh];

	return self;
}

- (id) initWithHost:(NSString*)aHost port:(NSInteger)aPort database:(NSString*)aDatabase delegate:(id)aDelegate tag:(NSString*)aTag;
{
    return [self initWithHost:aHost username:nil pwd:nil port:aPort database:aDatabase delegate:aDelegate tag:aTag];
}

- (void) dealloc
{
    [httpType release];
    [username release];
	[pwd release];
	[host release];
	[tag release];
	[database release];
	[delegate release];
	[super dealloc];
}

- (id) send:(NSString*)httpString
{
	return [self send:httpString type:nil body:nil];
}

- (id) send:(NSString*)httpString type:(NSString*)aType
{
	return [self send:httpString type:aType body:nil];
}

- (id) send:(NSString*)httpString type:(NSString*)aType body:(NSDictionary*)aBody
{
    id result = nil;
    @try {
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:httpString]];
        //[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
        
        if(aType){
            [request setHTTPMethod:aType];
            if([aType isEqualToString:@"POST"]){
                [request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"]];
            }
        }
        if(aBody){
            NSData* adat=nil;
            @try {
                //adat = [[aBody yajl_JSONString] dataUsingEncoding:NSASCIIStringEncoding];
                adat = [NSJSONSerialization dataWithJSONObject:aBody options:NSJSONWritingPrettyPrinted error:nil];
            }
            @catch (NSException *exc) {
                NSLogColor([NSColor redColor],
                           @"ORCouchDB JSON parse failure (%@)\n",exc);
                //adat = [[aBody yajl_JSONStringWithOptions:YAJLGenOptionsIgnoreUnknownTypes
                //                                     indentString:@""]
                //                dataUsingEncoding:NSASCIIStringEncoding];
            }
            @finally {
                if (adat) [request setHTTPBody:adat];
            }
        }
        [self _updateAuthentication:request];
        NSData *data = [[[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil] retain] autorelease];
        
        if (data) {
            //YAJLDocument *document = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
            result =  [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        }
    }
    @catch(NSException* e){
        NSLog(@"couch exception\n");
    }
	return result;
}

- (void) sendToDelegate:(id)obj
{
	if(obj && [delegate respondsToSelector:@selector(couchDBResult:tag:op:)]){
		[delegate couchDBResult:obj tag:tag op:self];
	}
}	
- (NSString*)database
{
    return database;
}
- (NSString*) revision:(NSString*)anID
{
	NSString *httpString = [NSString stringWithFormat:@"%@//%@:%u/%@/%@", httpType,host, (int)port, database, anID];
	id result = [self send:httpString];
	return [result objectForKey:@"_rev"];
}
@end

#pragma mark •••Database API


@implementation ORCouchDBCompactDBOp
-(void) main
{	
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
        NSString* httpString = [NSString stringWithFormat:@"%@//%@:%u/%@/_compact", httpType,host, (int)port,database];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:httpString]];
        [request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"]];
        [request setHTTPMethod:@"POST"];
        [self _updateAuthentication:request];
        NSData *data = [[[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil] retain] autorelease];	
        //YAJLDocument *document = nil;
        if (data) {
            //document = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
            [self sendToDelegate:[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]];
        }
    }
    [thePool release];
}
@end

@implementation ORCouchDBListDBOp
-(void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
        id result = [self send:[NSString stringWithFormat:@"%@//%@:%u/_all_dbs", httpType,host, (int)port]];
        for(id name in result){
            NSLog([NSString stringWithFormat:@"%@\n",name]);
        }
        [self sendToDelegate:result];
    }
    [thePool release];
}
@end


@implementation ORCouchDBListDocsOp
-(void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
        id result = [self send:[NSString stringWithFormat:@"%@//%@:%u/%@/_all_docs", httpType,host, (int)port,database]];
        [self sendToDelegate:result];
    }
    [thePool release];
}
@end

@implementation ORCouchDBListTasksOp
-(void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
        id result = [self send:[NSString stringWithFormat:@"%@//%@:%u/_active_tasks", httpType,host, (int)port]];
        [self sendToDelegate:result];
    }
    [thePool release];
}
@end
@implementation ORCouchDBVersionOp
- (void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
        id result = [self send:[NSString stringWithFormat:@"%@//%@:%u", httpType,host, (int)port]];
        [self sendToDelegate:result];
    }
    [thePool release];
}

@end

@implementation ORCouchDBInfoDBOp
-(void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
        id result = [self send:[NSString stringWithFormat:@"%@//%@:%u/%@/", httpType,host, (int)port,database]];
        [self sendToDelegate:result];
    }
    [thePool release];
}
@end

@implementation ORCouchDBCreateDBOp
@synthesize views;
- (void) dealloc
{
	self.views = nil;
	[super dealloc];
}

-(void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
       // NSString *escaped = [database stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *escaped = [database stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        id result = [self send:[NSString stringWithFormat:@"%@//%@:%u/_all_dbs",httpType, host, (int)port]];
        if(![result containsObject:database]){
            result = [self send:[NSString stringWithFormat:@"%@//%@:%u/%@", httpType,host, (int)port, escaped] type:@"PUT"];
            if([response statusCode] != 201)  result = [NSDictionary dictionaryWithObjectsAndKeys:
                                                       [NSString stringWithFormat:@"[%@] creation FAILED",database],
                                                       @"Message",
                                                       [NSString stringWithFormat:@"Error Code: %d",(int)[response statusCode]],
                                                       @"Reason",
                                                       nil];
            else {
                if(views){
                    NSMutableDictionary* allMaps = [NSMutableDictionary dictionary];

                    NSDictionary* viewDictionary = [views objectForKey:@"views"];
                    for(id aViewKey in viewDictionary){
                        
                        NSMutableDictionary* aNewView = [[[viewDictionary objectForKey:aViewKey] mutableCopy] autorelease];
                                        
                        id mapName = [[[aNewView objectForKey:@"mapName"] retain] autorelease];
                        if(![mapName length])mapName = database;
                        else [aNewView removeObjectForKey:@"mapName"];
                        
                        if(![allMaps objectForKey:mapName]){
                            [allMaps setObject:[NSMutableDictionary dictionary] forKey:mapName];
                            [[allMaps objectForKey:mapName] setObject:@"javascript" forKey:@"language"];
                            [[allMaps objectForKey:mapName] setObject:[NSMutableDictionary dictionary] forKey:@"views"];
                        }
                        
                        [[[allMaps objectForKey:mapName] objectForKey:@"views"] setObject:aNewView forKey:aViewKey];
                     }
                     for(id aMapName in allMaps){
                        NSString *httpString = [NSString stringWithFormat:@"%@//%@:%u/%@/_design/%@", httpType,host, (int)port, database, aMapName];
                        /*id result = */[self send:httpString type:@"PUT" body:[allMaps objectForKey:aMapName]];
                     }
                }
                
            }
        }
        else {
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      @"Did not create new database", @"Message",
                      [NSString stringWithFormat:@"[%@] already exists",database],
                      @"Reason",nil];
        }
        [self sendToDelegate:result];
    }
    [thePool release];
}
@end

@implementation ORCouchDBAddUpdateHandlerOp

@synthesize updateHandler;

- (void) dealloc
{
	self.updateHandler = nil;
	[super dealloc];
}

-(void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
        NSString* httpString = [NSString stringWithFormat:@"%@//%@:%u/%@/_design/default",httpType,host, (int)port, database];
        NSDictionary* doc = [NSDictionary dictionaryWithObject:updateHandler forKey:@"replaceDoc"];
        NSDictionary* aDict = [NSDictionary dictionaryWithObject:doc forKey:@"updates"];
        id result = [self send:httpString type:@"PUT" body:aDict];
        [self sendToDelegate:result];
    }
    [thePool release];

}
@end

@implementation ORCouchDBDeleteDBOp
-(void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
        
       // NSString *escaped = [database stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *escaped = [database stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
       id result = [self send:[NSString stringWithFormat:@"%@//%@:%u/_all_dbs", httpType,host, (int)port]];
        if([result containsObject:database]){
            result = [self send:[NSString stringWithFormat:@"%@//%@:%u/%@", httpType,host, (int)port, escaped] type:@"DELETE"];
            if([response statusCode] != 200) result = [NSDictionary dictionaryWithObjectsAndKeys:
                                                       [NSString stringWithFormat:@"[%@] deletion FAILED",database],
                                                       @"Message",
                                                       [NSString stringWithFormat:@"Error Code: %d",(int)[response statusCode]],
                                                       @"Reason",
                                                       nil];
        }
        else result = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"[%@] didn't exist",database],@"Message",nil];
        [self sendToDelegate:result];
    }
    [thePool release];
    
}
@end

@implementation ORCouchDBReplicateDBOp
@synthesize continuous;
- (void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
       // NSString* escaped   = [database stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *escaped = [database stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
       NSString* httpString = [NSString stringWithFormat:@"%@//127.0.0.1:%u/_replicate",httpType, (int)port];
        
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:httpString]];
        [self _updateAuthentication:request];
        [request setHTTPMethod:@"POST"];
        [request setAllHTTPHeaderFields:[NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"]];
        NSString* target = [NSString stringWithFormat:@"%@//%@:%d/%@",httpType,host,(int)port,escaped];
        NSDictionary* aBody;
        if(continuous) aBody= [NSDictionary dictionaryWithObjectsAndKeys:escaped,@"source",target,@"target",[NSNumber numberWithBool:1],@"continuous",nil];
        else           aBody = [NSDictionary dictionaryWithObjectsAndKeys:escaped,@"source",target,@"target",nil];
        //NSString* s = [aBody yajl_JSONString];
        //NSData* asData = [s dataUsingEncoding:NSASCIIStringEncoding];
        [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:aBody options:NSJSONWritingPrettyPrinted error:nil]];
        NSData *data = [[[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil] retain] autorelease];
        
        id result = nil;
        if (data) {
            //YAJLDocument *document = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
            result= [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        }
        
        [self sendToDelegate:result];
    }
    [thePool release];
}

@end


#pragma mark •••Document API
@implementation ORCouchDBPutDocumentOp
- (void) dealloc 
{
	[document release];
	[documentId release];
	[attachmentData release];
	[attachmentName release];
	[super dealloc];
}

- (void) setDocument:(NSDictionary*)aDocument documentID:(NSString*)anID
{
	
	[aDocument retain];
	[document release];
	document = aDocument;
	
	[documentId autorelease];
	documentId = [anID copy];
}

- (void) setAttachmentName:(NSString*)aName
{
	[attachmentName autorelease];
	attachmentName = [aName copy];
}
- (void) setAttachment:(NSData*)someData
{
	[someData retain];
	[attachmentData release]; 
	attachmentData = someData;
}

- (void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
        NSString* httpString;
        NSString* action;
        if(documentId){
            action = @"PUT";
            httpString = [NSString stringWithFormat:@"%@//%@:%u/%@/%@", httpType,host, (int)port, database, documentId];
        }
        else {
            action = @"POST";
            httpString = [NSString stringWithFormat:@"%@//%@:%u/%@", httpType,host, (int)port, database];
        }
        id result = [self send:httpString type:action body:document];
        if(!result){
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSString stringWithFormat:@"[%@] timeout",
                       database],@"Message",nil];
            [self sendToDelegate:result];
        }	
        else {
            if(attachmentData){
                [self addAttachement];
            }
        }
        
        [self sendToDelegate:result];
    }
    [thePool release];
	
}

- (id) addAttachement
{
	NSString* rev = [self revision:documentId];
	if(rev){
		NSString *httpString = [NSString stringWithFormat:@"%@//%@:%u/%@/%@", httpType,host, (int)port, database, documentId];
		httpString = [httpString stringByAppendingFormat:@"/%@?rev=%@",attachmentName,rev];
		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:httpString]];
        [self _updateAuthentication:request];
		[request setHTTPMethod:@"PUT"];
		[request setHTTPBody:attachmentData];
		
		NSData *data = [[[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil] retain] autorelease];
		
		
		if (data) {
			//YAJLDocument *result = [[[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:nil] autorelease];
			return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
		}
		else {
			return [NSDictionary dictionaryWithObjectsAndKeys:
					[NSString stringWithFormat:@"[%@] timeout",
					 database],@"Message",nil];
		}
		
	}
	return nil;
}

@end

//-------------------------

@implementation ORCouchDBUpdateDocumentOp
- (void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
        if([delegate respondsToSelector:@selector(usingUpdateHandler)] && [delegate usingUpdateHandler]){
            NSString *httpString = [NSString stringWithFormat:@"%@//%@:%u/%@/_design/default/_update/replaceDoc/%@", httpType,host, (int)port, database, documentId];
            id theDoc = document;
            if(documentId && ![[document objectForKey:@"_id"] isEqualToString:documentId]){
                NSMutableDictionary* mDict = [NSMutableDictionary dictionaryWithDictionary:document];
                [mDict setObject:documentId forKey:@"_id"];
                theDoc = mDict;
            }
            id result = [self send:httpString type:@"PUT" body:theDoc];
            if(![result objectForKey:@"error"] && attachmentData){
                [self addAttachement];
            }
            
        
            
        }
        else {
            //check for an existing document
            NSString *httpString = [NSString stringWithFormat:@"%@//%@:%u/%@/%@", httpType,host, (int)port, database, documentId];
            id result = [self send:httpString];
            if(!result){
                result = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSString stringWithFormat:@"[%@] timeout",
                           database],@"Message",nil];
                informDelegate=YES;
            }
            else if([result objectForKey:@"error"]){
                //document doesn't exist. So just add it.
                result = [self send:httpString type:@"PUT" body:document];
                if(![result objectForKey:@"error"] && attachmentData){
                    [self addAttachement];
                }
            }
            else {
                //it already exists. insert the rev number into the document and put it back
                id rev = [result objectForKey:@"_rev"];
                if(rev){
                    NSMutableDictionary* newDocument = [NSMutableDictionary dictionaryWithDictionary:document];
                    [newDocument setObject:rev forKey:@"_rev"];
                    result = [self send:httpString type:@"PUT" body:newDocument];
                    if(![result objectForKey:@"error"] && attachmentData){
                        [self addAttachement];
                    }
                }
            }
            if (informDelegate) [self sendToDelegate:result];
        }
    }
    [thePool release];
}
- (void) setInformDelegate:(BOOL)ok
{
    informDelegate = ok;
}
@end

@implementation ORCouchDBUpdateEventCatalogOp
- (void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
	if(![self isCancelled]){
        //check for an existing document
        NSString *httpString = [NSString stringWithFormat:@"%@//%@:%u/%@/%@",httpType, host, (int)port, database, documentId];
        id result = [self send:httpString];
        if(!result){
            result = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSString stringWithFormat:@"[%@] timeout",
                       database],@"Message",nil];
            [self sendToDelegate:result];
        }
        else if([result objectForKey:@"error"]){
            //document doesn't exist. So just add it.
            NSArray* anEvent = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:[document objectForKey:@"time"] forKey:[document objectForKey:@"name"]]];
            NSDictionary* newDocument = [NSDictionary dictionaryWithObjectsAndKeys:@"EventCatalog",@"name", @"Event Catalog",@"title",anEvent,@"events",nil];
            result = [self send:httpString type:@"PUT" body:newDocument];
            if(![result objectForKey:@"error"] && attachmentData){
                [self addAttachement];
            }
        }
        else {
            //it already exists. insert the rev number into the document and put it back
            id rev = [result objectForKey:@"_rev"];
            if(rev){
                NSString* eventNameForCatalog = [document objectForKey:@"name"];
                NSMutableDictionary* newDocument = [NSMutableDictionary dictionaryWithDictionary:result];
                NSArray* eventsAlreadyInCatalog = [result objectForKey:@"events"];
                for(id anEntry in eventsAlreadyInCatalog){
                    if([anEntry objectForKey:eventNameForCatalog]){
                        [thePool release];
                        return; //alreay there
                    }
                }
                //if we get here, it's not in the list of events already
                NSArray* newArray = [[result objectForKey:@"events"] arrayByAddingObject:[NSDictionary dictionaryWithObject:[document objectForKey:@"time"] forKey:eventNameForCatalog]];
                [newDocument setObject:newArray forKey:@"events"];
                [newDocument setObject:rev forKey:@"_rev"];
                [self send:httpString type:@"PUT" body:newDocument];
            }
        }
    }
    [thePool release];
}
@end

@implementation ORCouchDBDeleteDocumentOp
- (void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
    if(![self isCancelled]){
        //check for an existing document
        NSString *httpString = [NSString stringWithFormat:@"%@//%@:%u/%@/%@",httpType, host, (int)port, database, documentId];
        id result = [self send:httpString];
        id rev = [result objectForKey:@"_rev"];
        if(rev){
            httpString = [httpString stringByAppendingFormat:@"?rev=%@",rev];
            [self send:httpString type:@"DELETE"];
        }
    }
    [thePool release];
}
@end

@implementation ORCouchDBGetDocumentOp
- (void) dealloc 
{
	[documentId release];
	[super dealloc];
}

- (void) setDocumentId:(NSString*)anID
{
	[documentId autorelease];
	documentId = [anID copy];
}

- (void) main
{
    NSAutoreleasePool *thePool = [[NSAutoreleasePool alloc] init];
    if(![self isCancelled]){
        NSString* escaped = [documentId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *httpString = [NSString stringWithFormat:@"%@//%@:%u/%@/%@", httpType,host, (int)port, database, escaped];
        id result = [self send:httpString];
        [self sendToDelegate:result];
    }
    [thePool release];
}
@end


static void ORCouchDB_Feed_callback(CFReadStreamRef stream,
                                    CFStreamEventType type,
                                    ORCouchDBChangesfeedOp* delegate)
{
    
    uint8_t data[1024];
    CFHTTPMessageRef aResponse;
    CFIndex len;
    switch(type){
        case kCFStreamEventHasBytesAvailable:
            if([delegate isWaitingForResponse]){
                aResponse = (CFHTTPMessageRef)CFReadStreamCopyProperty(stream, kCFStreamPropertyHTTPResponseHeader);
                if (CFHTTPMessageIsHeaderComplete(aResponse)){
                    [delegate streamReceivedResponse:aResponse];
                }
                CFRelease(aResponse);
                break;
                
            }
            len=CFReadStreamRead(stream, data, sizeof(data));
            if (len < 0) {
                [delegate streamFailedWithError:[(NSError*) CFReadStreamCopyError(stream) autorelease]];
            }
            [delegate streamReceivedData:[NSData dataWithBytes:data length:len]];
            break;
        case kCFStreamEventErrorOccurred:
            [delegate streamFailedWithError:[(NSError*) CFReadStreamCopyError(stream) autorelease]];
            break;
        case kCFStreamEventEndEncountered:
            [delegate streamFinished];
            break;
        default:break;
    }
}

@interface ORCouchDBChangesfeedOp (private)
- (void) _startConnection;
- (void) _clearConnection;
- (void) _stop;
- (void) _performContinuousFeed;
- (void) _performPolling;
@end

@implementation ORCouchDBChangesfeedOp (private)
-(void) _clearConnection
{
    [self sendToDelegate:[NSString stringWithFormat:@"%@: Stopped", self]];
    [_inputBuffer release];
    _inputBuffer = nil;
    _status = 0;
}

-(void) _startConnection
{
    if([self isCancelled]){
        [self _clearConnection];
        return;
    }
    
    // get the current last_seq so we only receive changes from now on. if we want the complete history, set last_seq to 0
    NSString *httpString = [NSString stringWithFormat:@"%@//%@:%u/%@/_changes",httpType,host,(int)port,database];
    NSNumber* last_seq = [[self send:httpString] objectForKey:@"last_seq"];
    
    if (heartbeat==0) heartbeat=(NSUInteger) 5000;
    
    NSString *options=[NSString stringWithFormat:@"?heartbeat=%u&feed=continuous&since=%@", (int)heartbeat, last_seq];
    if (filter) {
        options = [options stringByAppendingString:[NSString stringWithFormat:@"&filter=%@", filter]];
    }
    httpString = [httpString stringByAppendingString:options];
    
    CFURLRef theURL = CFURLCreateWithString(NULL,
                                            (CFStringRef)httpString,
                                            NULL);
    
    _currentRequest = CFHTTPMessageCreateRequest(NULL,
                                                 CFSTR("GET"),
                                                 theURL,
                                                 kCFHTTPVersion1_1);
    CFDataRef bodyData = CFStringCreateExternalRepresentation(NULL,
                                                              CFSTR(""),
                                                              kCFStringEncodingUTF8,
                                                              0);
    CFHTTPMessageSetBody(_currentRequest, bodyData);
    CFHTTPMessageSetHeaderFieldValue(_currentRequest,
                                     CFSTR("content-type"),
                                     CFSTR("text/json"));

    while (![self isCancelled]) {
        CFReadStreamRef _stream = CFReadStreamCreateForHTTPRequest(NULL,
                                                                   _currentRequest);
        
        CFStreamClientContext theContext={0,self,NULL,NULL,NULL};
        
        CFReadStreamSetClient(_stream,
                              kCFStreamEventHasBytesAvailable |
                              kCFStreamEventErrorOccurred |
                              kCFStreamEventEndEncountered,
                              (CFReadStreamClientCallBack) &ORCouchDB_Feed_callback,
                              &theContext);
        
        NSRunLoop* rl = [NSRunLoop currentRunLoop];
        CFReadStreamScheduleWithRunLoop(_stream, [rl getCFRunLoop], kCFRunLoopDefaultMode);
        
        _waitingForResponse=TRUE;
        _status = 0;
        
        CFReadStreamOpen(_stream);
        while((![self isCancelled] &&
               _status != 401 && _status != 407) &&
              [rl runMode:NSDefaultRunLoopMode
               beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]);
        
        // The close of the stream removes it from the run list.
        CFReadStreamClose(_stream);
        CFRelease(_stream);
    }
    CFRelease(bodyData);
    CFRelease(theURL);
    CFRelease(_currentRequest);
    // When we reach here, we have been cancelled.

    
}

-(void) _performContinuousFeed
{
    [self _startConnection];
    [self _stop];
}


- (void) _stop
{
    [self _clearConnection];
    [self cancel];
}

-(void) _performPolling
{
	if([self isCancelled])return;
	id result = [self send:[NSString stringWithFormat:@"%@//%@:%u/%@/_changes", httpType,host, (int)port,database]];
    NSNumber* last_seq=[result objectForKey:@"last_seq"];
    
    while (![self isCancelled]) {
        id result=[self send:[NSString stringWithFormat:@"%@//%@:%u/%@/_changes?since=%@", httpType,host, (int)port,database,last_seq]];
        last_seq=[result objectForKey:@"last_seq"];
        
        NSArray* query_results=[result objectForKey:@"results"];
        if ([query_results count]){
            for (id aChange in query_results) {
                [self sendToDelegate:aChange];
            }
        }
        sleep(10);
    }
}

@end

@implementation ORCouchDBChangesfeedOp

@synthesize listeningMode,filter,heartbeat;

-(void) main
{
    if([listeningMode isEqualToString:kContinuousFeed]){
        [self _performContinuousFeed];
    }
    else if([listeningMode isEqualToString:kPolling]){
        [self _performPolling];
    }
    else{
    [self _performContinuousFeed]; // insert default here
    }
}

-(BOOL) isWaitingForResponse
{
    return _waitingForResponse;
}

- (void)streamReceivedResponse:(CFHTTPMessageRef)aResponse
{
    _waitingForResponse=FALSE;
    _status = (int) CFHTTPMessageGetResponseStatusCode(aResponse);
    int tempStatus = _status;
    if (_status == 401 || _status == 407) {
        if (!CFHTTPMessageAddAuthentication(_currentRequest,
                                            aResponse,
                                            (CFStringRef)username,
                                            (CFStringRef)pwd,
                                            kCFHTTPAuthenticationSchemeBasic,
                                            FALSE)) {
            [self sendToDelegate:[NSString stringWithFormat:@"%@: Authentication failed", self]];
            [self _stop];
        }

    } else {
        if (_status >= 300) {
            [self _stop];
        }
    }
    [self sendToDelegate:[NSString stringWithFormat:@"%@: Got response, status %d", self,tempStatus]];
}

- (void)streamReceivedData:(NSData *)data
{
    if ([self isCancelled]){
        [self _stop];
        return;
    }
    
    if (_inputBuffer == nil) {
        _inputBuffer = [[NSMutableData alloc] init];
    }
    [_inputBuffer appendData: data];
    
    // In continuous mode, break input into lines and parse each as JSON:
    const char* start = _inputBuffer.bytes;
    const char* eol;
    NSUInteger totalLengthProcessed = 0;
    NSUInteger bufferLength = _inputBuffer.length;
    
    // Remove empty lines
    while ((bufferLength - totalLengthProcessed) > 0 && start[0] == '\n') {
        totalLengthProcessed++;
        start++;
    }
    
    while ((eol = strnstr(start, "\n", bufferLength-totalLengthProcessed)) != nil){
    // Only if we have a complete line
        ptrdiff_t lineLength = eol - start;
        totalLengthProcessed += lineLength + 1;
        if (lineLength > 0) {
            // Only parse lines with > 0 length, others are the heartbeats.
            NSData* chunk = [NSData dataWithBytes:start length:lineLength];
            
            // Parse the line and send to delegate:
            if (chunk) {
                //YAJLDocument *document = [[[YAJLDocument alloc] initWithData:chunk parserOptions:YAJLParserOptionsNone error:nil] autorelease];
                [self sendToDelegate:[NSJSONSerialization JSONObjectWithData:chunk options:NSJSONReadingMutableContainers error:nil]];
            }
        }
        // Move the pointer
        start += totalLengthProcessed;
    }
    
    // Remove the processed bytes from the buffer.
    [_inputBuffer replaceBytesInRange:NSMakeRange(0, totalLengthProcessed)
                            withBytes: NULL
                               length: 0];
}

- (void) dealloc
{
    self.listeningMode = nil;
    self.filter = nil;
    [super dealloc];
}

- (void)streamFailedWithError:(NSError *)error
{
    NSLog(@"%@: Got error %@\n", self, error);
    [self _stop];
}

- (void)streamFinished
{
    NSLog(@"%@ connection ended\n", self);
    [self _stop];
}

@end

//-----------------------------------------------------------
//ORCouchQueue: A shared queue for couchdb access. You should 
//never have to use this object directly. It will be created
//on demand when a couchDB op is called.
//-----------------------------------------------------------
@implementation ORCouchDBQueue
SYNTHESIZE_SINGLETON_FOR_ORCLASS(CouchDBQueue);
+ (NSOperationQueue*) queue             { return [[ORCouchDBQueue sharedCouchDBQueue] queue];              }
+ (NSOperationQueue*) lowPriorityQueue  { return [[ORCouchDBQueue sharedCouchDBQueue] lowPriorityQueue];   }
+ (NSOperationQueue*) changesFeedQueue  { return [[ORCouchDBQueue sharedCouchDBQueue] changesFeedQueue];   }
+ (void) addOperation:(NSOperation*)anOp{ [[ORCouchDBQueue sharedCouchDBQueue] addOperation:anOp];         }

+ (void) addLowPriorityOperation:(NSOperation*)anOp              { [[ORCouchDBQueue sharedCouchDBQueue] addLowPriorityOperation:anOp];   }
+ (void) addChangeFeedOperation:(ORCouchDBChangesfeedOp *)feedOp { [[ORCouchDBQueue sharedCouchDBQueue] addChangesFeedOperation:feedOp]; }

+ (NSUInteger) operationCount            { return 	[[ORCouchDBQueue sharedCouchDBQueue] operationCount];  }
+ (NSUInteger) lowPriorityOperationCount { return 	[[ORCouchDBQueue sharedCouchDBQueue] lowPriorityOperationCount];}
+ (void)       cancelAllOperations       { [[ORCouchDBQueue sharedCouchDBQueue] cancelAllOperations]; }

//don't call this unless you're using this class in a special, non-global way.
- (id) init
{
    self = [super init];
    queue = [[NSOperationQueue alloc] init];
	[queue setMaxConcurrentOperationCount:4];

    lowPriorityQueue = [[NSOperationQueue alloc] init];
    [lowPriorityQueue setMaxConcurrentOperationCount:1];

    changesFeedQueue = [[NSOperationQueue alloc] init];
    return self;
}

- (NSOperationQueue*) queue                         { return queue;             }
- (NSOperationQueue*) lowPriorityQueue              { return lowPriorityQueue;  }
- (NSOperationQueue*) changesFeedQueue              { return changesFeedQueue;  }
- (void) addOperation:(NSOperation*)anOp            { [queue addOperation:anOp];            }
- (void) addLowPriorityOperation:(NSOperation*)anOp
{
    [anOp setQueuePriority:NSOperationQueuePriorityVeryLow];
    [lowPriorityQueue addOperation:anOp];
}

- (void) addChangesFeedOperation:(ORCouchDBChangesfeedOp *)feedOp
{
    @synchronized(self){
        // Add a make sure it can execute.
        NSUInteger count = [changesFeedQueue operationCount];
        if (count >= [changesFeedQueue maxConcurrentOperationCount]) {
            [changesFeedQueue setMaxConcurrentOperationCount:[changesFeedQueue maxConcurrentOperationCount]+1];
        }
        [changesFeedQueue addOperation:feedOp];
    }
}

- (void) cancelAllOperations
{
    [queue cancelAllOperations];
    [lowPriorityQueue cancelAllOperations];
    [changesFeedQueue cancelAllOperations];
}
			 
- (NSInteger) operationCount            { return [[queue operations]count];            }
- (NSInteger) lowPriorityOperationCount { return [[lowPriorityQueue operations]count]; }

@end
