//
//  ORSqlConnection.h
//  Orca
//
//  Created by Mark Howe on 10/18/06.
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


#import "mysql.h"

@class ORSqlResult;

@interface ORSqlConnection : NSObject {
	@protected
		MYSQL* mConnection;
}

- (id) init;
- (void) dealloc;
- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord dataBase:(NSString*)aDataBase verbose:(BOOL)verbose;
- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord dataBase:(NSString*)aDataBase;
- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord;
- (void) disconnect;
- (BOOL) selectDB:(NSString *) dbName;
- (NSString*) getLastErrorMessage;
- (unsigned int) getLastErrorID;
- (BOOL) isConnected;
- (BOOL) checkConnection;
- (NSString *) quoteObject:(id) theObject;
- (ORSqlResult*) queryString:(NSString *) query;
- (unsigned long long) affectedRows;
- (unsigned long long) insertId;
- (ORSqlResult *)listDBs;
- (ORSqlResult*) listTables;
- (ORSqlResult*) listTablesFromDB:(NSString *) dbName;
- (ORSqlResult*) listFieldsFromTable:(NSString *)tableName;
- (NSString*)  clientInfo;
- (NSString*)  hostInfo;
- (NSString*)  serverInfo;
- (NSNumber*)  protoInfo;
- (ORSqlResult*) listProcesses;
- (BOOL)createDBWithName:(NSString *)dbName;
//- (BOOL)dropDBWithName:(NSString *)dbName;
- (BOOL) killProcess:(unsigned long) pid;
@end

//a thin wrapper around NSOperationQueue to make a shared queue for Sql access
@interface ORSqlDBQueue : NSObject {
    NSOperationQueue* queue;
}
+ (ORSqlDBQueue*) sharedSqlDBQueue;
+ (void) addOperation:(NSOperation*)anOp;
+ (NSOperationQueue*) queue;
+ (NSUInteger) operationCount;
- (void) addOperation:(NSOperation*)anOp;
- (NSOperationQueue*) queue;
- (NSInteger) operationCount;

@end

