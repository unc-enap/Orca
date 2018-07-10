//
//  ORCouchDB.h
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

//Modes for Changesfeed
#define kPolling        @"kPolling"
#define kContinuousFeed  @"kContinuousPolling"

@interface ORCouchDB : NSObject {
	id					delegate;
	NSOperationQueue*	queue;
	NSString*			username;
	NSString*			pwd;
	NSString*			host;
	NSString*			database;
	NSUInteger			port;
}
+ (id) couchHost:(NSString*)aHost port:(NSUInteger)aPort username:(NSString*)aUsername pwd:(NSString*)aPwd database:(NSString*)aDatabase delegate:(id)aDelegate;
+ (id) couchHost:(NSString*)aHost port:(NSUInteger)aPort database:(NSString*)aDatabase delegate:(id)aDelegate;

- (id) initWithHost:(NSString*)aHost port:(NSUInteger)aPort username:(NSString*)aUsername pwd:(NSString*)aPwd database:(NSString*)aDatabase delegate:(id)aDelegate;
- (id) initWithHost:(NSString*)aHost port:(NSUInteger)aPort database:(NSString*)aDatabase delegate:(id)aDelegate;

- (void) dealloc;
- (void) compactDatabase:(id)aDelegate tag:(NSString*)aTag;
- (void) version:(id)aDelegate tag:(NSString*)aTag;
- (void) listDatabases:(id)aDelegate tag:(NSString*)aTag;
- (void) databaseInfo:(id)aDelegate tag:(NSString*)aTag;
- (void) createDatabase:(NSString*)aTag views:(NSDictionary*)theViews;
- (void) addUpdateHandler:(NSString*)aTag updateHandler:(NSString*)anUpdateHandler;
- (void) replicateLocalDatabase:(NSString*)aTag continous:(BOOL)continuous;
- (void) deleteDatabase:(NSString*)aTag;
- (void) addDocument:(NSDictionary*)aDict tag:(NSString*)aTag;
- (void) addDocument:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;
- (void) getDocumentId:(NSString*)anId tag:(NSString*)aTag;
- (void) updateDocument:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;
- (void) updateDocument:(NSDictionary*)aDict documentId:(NSString*)anId attachmentData:(NSData*)someData attachmentName:(NSString*)aName tag:(NSString*)aTag;
- (void) updateDocument:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag informingDelegate:(BOOL)ok;
- (void) updateLowPriorityDocument:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;
- (void) deleteDocumentId:(NSString*)anId tag:(NSString*)aTag;
- (void) listTasks:(id)aDelegate tag:(NSString*)aTag;
- (void) updateEventCatalog:(NSDictionary*)aDict documentId:(NSString*)anId tag:(NSString*)aTag;
- (NSOperation*) changesFeedMode:(NSString*)mode tag:(NSString*)aTag;
- (NSOperation*) changesFeedMode:(NSString*)mode heartbeat:(NSUInteger)heartbeat tag:(NSString*)aTag;
- (NSOperation*) changesFeedMode:(NSString*)mode heartbeat:(NSUInteger)heartbeat tag:(NSString*)aTag filter:(NSString*)filter;

#pragma mark ***CouchDB Checks

@property (assign)	id					delegate;
@property (retain)	NSOperationQueue*	queue;
@property (copy)	NSString*			host;
@property (copy)	NSString*			database;
@property (assign)  NSUInteger			port;
@property (copy)	NSString*			username;
@property (copy)	NSString*			pwd;
@end

@interface ORCouchDBOperation : NSOperation
{
	id					delegate;
	NSString*			database;
	NSString*			host;
	NSString*			username;
    NSString*           pwd;
    NSString*           httpType;
	NSUInteger			port;
	id					tag;
	NSHTTPURLResponse*	response;
}
- (id) initWithHost:(NSString*)aHost port:(NSInteger)aPort database:(NSString*)database delegate:(id)aDelegate tag:(NSString*)aTag;
- (id) initWithHost:(NSString*)aHost username:(NSString*)aUN pwd:(NSString*)aPwd port:(NSInteger)aPort database:(NSString*)database delegate:(id)aDelegate tag:(NSString*)aTag;
- (void) dealloc;
- (id) send:(NSString*)httpString;
- (id) send:(NSString*)httpString type:(NSString*)aType;
- (id) send:(NSString*)httpString type:(NSString*)aType body:(NSDictionary*)aBody;
- (NSString*) revision:(NSString*)anID;
- (NSString*) database;
@property (copy) NSString*    httpType;
@property (copy) NSString*    username;
@property (copy) NSString*    pwd;

@end

#pragma mark •••Database API
@interface ORCouchDBCompactDBOp : ORCouchDBOperation
-(void) main;
@end

@interface ORCouchDBCreateDBOp : ORCouchDBOperation
{
	NSDictionary* views;
}
-(void) main;
@property (retain)	NSDictionary*	views;
@end

@interface ORCouchDBAddUpdateHandlerOp : ORCouchDBOperation
{
    NSString* updateHandler;
}
-(void) main;
@property (copy) NSString* updateHandler;
@end


@interface ORCouchDBDeleteDBOp : ORCouchDBOperation
-(void) main;
@end

@interface ORCouchDBReplicateDBOp : ORCouchDBOperation
{
	BOOL	continuous;
}
-(void) main;
@property (assign)	BOOL continuous;
@end

@interface ORCouchDBVersionOp :ORCouchDBOperation
- (void) main;
@end

@interface ORCouchDBListDocsOp:ORCouchDBOperation
-(void) main;
@end


@interface ORCouchDBListDBOp :ORCouchDBOperation
- (void) main;
@end

@interface ORCouchDBListTasksOp :ORCouchDBOperation
- (void) main;
@end

@interface ORCouchDBInfoDBOp : ORCouchDBOperation
-(void) main;
@end

#pragma mark •••Document API
@interface ORCouchDBPutDocumentOp :ORCouchDBOperation
{
	NSString*		documentId;
	NSDictionary*	document;
	NSData*			attachmentData;
	NSString*		attachmentName;
}
- (void) setDocument:(NSDictionary*)aDocument documentID:(NSString*)anID;
- (void) setAttachment:(NSData*)someData;
- (void) setAttachmentName:(NSString*)aName;
- (void) main;
- (id) addAttachement;
@end

@interface ORCouchDBUpdateDocumentOp :ORCouchDBPutDocumentOp
{
    BOOL    informDelegate;
}
- (void) main;
- (void) setInformDelegate:(BOOL)ok;
@end

@interface ORCouchDBUpdateEventCatalogOp :ORCouchDBPutDocumentOp
- (void) main;
@end

@interface ORCouchDBGetDocumentOp :ORCouchDBOperation
{
	NSString* documentId;
	BOOL getRevisionCount;
	BOOL getInfo;
	NSString* revision;
	
}
- (void) setDocumentId:(NSString*)anID;
- (void) main;
@end

@interface ORCouchDBDeleteDocumentOp :ORCouchDBGetDocumentOp
- (void) main;
@end

#pragma mark ***Changes API
@interface ORCouchDBChangesfeedOp : ORCouchDBOperation 
{
@private
    NSMutableData* _inputBuffer;
    int _status;
    BOOL _waitingForResponse;
    CFHTTPMessageRef _currentRequest;

    NSString*  listeningMode;
    NSUInteger heartbeat;
    NSString*  filter;
    
}
- (void) main;

- (BOOL) isWaitingForResponse;
- (void) streamReceivedResponse:(CFHTTPMessageRef)aResponse;
- (void) streamReceivedData:(NSData *)data;
- (void) streamFailedWithError:(NSError *)error;
- (void) streamFinished;

@property (copy) NSString* listeningMode;
@property (copy) NSString* filter;
@property (assign) NSUInteger heartbeat;


@end

//a thin wrapper around NSOperationQueue to make a shared queue for couch access
@interface ORCouchDBQueue : NSObject {
    NSOperationQueue* queue;
    NSOperationQueue* lowPriorityQueue;
    NSOperationQueue* changesFeedQueue;
}
+ (ORCouchDBQueue*) sharedCouchDBQueue;
+ (void) addOperation:(NSOperation*)anOp;
+ (void) addLowPriorityOperation:(NSOperation*)anOp;
+ (void) addChangeFeedOperation:(ORCouchDBChangesfeedOp*)feedOp;
+ (NSOperationQueue*) queue;
+ (NSOperationQueue*) lowPriorityQueue;
+ (NSOperationQueue*) changesFeedQueue;
+ (NSUInteger) operationCount;
+ (void) cancelAllOperations;
- (void) addOperation:(NSOperation*)anOp;
- (void) addLowPriorityOperation:(NSOperation*)anOp;
- (void) addChangesFeedOperation:(ORCouchDBChangesfeedOp*)feedOp;
- (NSOperationQueue*) queue;
- (NSOperationQueue*) lowPriorityQueue;
- (NSOperationQueue*) changesFeedQueue;
- (void) cancelAllOperations;
- (NSInteger) operationCount;
- (NSInteger) lowPriorityOperationCount;
@end

@interface NSObject (ORCouchDB)
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp;
- (void) startingSweep;
- (void) sweepDone;
- (void) incChangeCounter;
- (BOOL) usingUpdateHandler;
- (BOOL) useHttps;
@end


