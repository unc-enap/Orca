//
//  ORPQConnection.h
//
//  2016-06-01 Created by Phil Harvey (Based on ORSqlConnection.h by M.Howe)
//

#import "libpq-fe.h"

@class ORPQResult;

@interface ORPQConnection : NSObject {
	@protected
		PGconn* mConnection;
}

- (id) init;
- (void) dealloc;
- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord dataBase:(NSString*)aDataBase verbose:(BOOL)verbose;
- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord dataBase:(NSString*)aDataBase;
- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord;
- (void) disconnect;
- (NSString*) getLastErrorMessage;
- (int) getLastErrorID;
- (BOOL) isConnected;
- (BOOL) checkConnection;
- (NSString *) quoteObject:(id) theObject;
- (ORPQResult*) queryString:(NSString *) query;
@end

//a thin wrapper around NSOperationQueue to make a shared queue for Sql access
@interface ORPQDBQueue : NSObject {
    NSOperationQueue* queue;
}
+ (ORPQDBQueue*) sharedPQDBQueue;
+ (void) addOperation:(NSOperation*)anOp;
+ (NSOperationQueue*) queue;
+ (NSUInteger) operationCount;
- (void) addOperation:(NSOperation*)anOp;
- (NSOperationQueue*) queue;
- (NSInteger) operationCount;

@end

