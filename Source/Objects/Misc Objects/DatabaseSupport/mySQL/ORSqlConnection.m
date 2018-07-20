//
//  ORSqlConnection.m
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


#import "ORSqlConnection.h"
#import "ORSqlResult.h"
#import "SynthesizeSingleton.h"

@interface ORSqlConnection (private)
- (NSString*) prepareBinaryData:(NSData *) theData;
- (NSString*) prepareString:(NSString *) theString;
@end

@implementation ORSqlConnection

- (id) init
{   
	self = [super init];
	mConnection = nil;
	return self;
}

- (void) dealloc
{
	[self disconnect];
	[super dealloc];
}

- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord dataBase:(NSString*)aDataBase
{
	return [self connectToHost:aHostName userName:aUserName passWord:aPassWord dataBase:aDataBase verbose:YES];
}

- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord dataBase:(NSString*)aDataBase verbose:(BOOL)verbose
{
	@synchronized(self){
		if(!mConnection && [aHostName length] && [aUserName length] && [aPassWord length] && [aDataBase length]){
			mConnection = mysql_init (NULL);
			if(mConnection){
				MYSQL* result = mysql_real_connect (mConnection, [aHostName UTF8String], [aUserName UTF8String], [aPassWord UTF8String],[aDataBase UTF8String], 0, nil, 0);
				if ( result != mConnection){
					if(verbose){
						NSLog(@"mysql_real_connect() failed: %u\n",mysql_errno (mConnection));
						NSLog(@"Error: (%s)\n",mysql_error (mConnection));
					}
					[self disconnect];
					return NO;
				}
				if([aDataBase length]){
					[self selectDB:aDataBase];
				}
			}
			else {
				if(verbose){
					NSLog(@"ORSql: mysql_init() failed\n");
				}
			}
		}
	}
	return mConnection!=nil;
}

- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord
{
	@synchronized(self){
		if(!mConnection && [aHostName length] && [aUserName length] && [aPassWord length] ){
			mConnection = mysql_init (NULL);
			if(mConnection){
				MYSQL* result = mysql_real_connect (mConnection,[aHostName UTF8String], [aUserName UTF8String], [aPassWord UTF8String],NULL, 0, NULL, 0);
				if ( result && (result != mConnection)){
					NSLog(@"mysql_real_connect() failed: %u\n",mysql_errno (result));
					NSLog(@"Error: (%s)\n",mysql_error (result));
					[self disconnect];
					return NO;
				}
			}
			else {
				NSLog(@"ORSql: mysql_init() failed\n");
			}
		}
	}
	return mConnection!=nil;
}

- (void) disconnect
{
	@synchronized(self){
		if (mConnection) {
			mysql_close(mConnection);
            mysql_library_end();
			mConnection = nil;
		}
	}
}

- (BOOL) selectDB:(NSString *) dbName
{
	BOOL result = NO;
	@synchronized(self){
		if(mConnection){
			if ([dbName length]) {
				if (mysql_select_db(mConnection, [dbName UTF8String]) == 0) {
					result =  YES;
				}
			}
		}
	}

    return result;
}


- (NSString *) getLastErrorMessage
{
	NSString* result = @"";
	@synchronized(self){
		if (mConnection) result= [NSString stringWithCString:mysql_error(mConnection) encoding:NSISOLatin1StringEncoding];
		else			 result= @"No connection initailized yet (MYSQL* still NULL)\n";
	}
	return result;
}

- (unsigned int) getLastErrorID
{
	unsigned int result = 666;
	@synchronized(self){
		if (mConnection) result =  mysql_errno(mConnection);
	}
	return result;
}

- (BOOL) isConnected
{
    return mConnection != nil;
}

- (BOOL) checkConnection
{
	BOOL result = NO;
	@synchronized(self){
		result = mysql_ping(mConnection);
	}
	return result;
}

- (NSString *) quoteObject:(id) theObject
/*" Use the class of the theObject to know how it should be prepared for usage with the database.
 If theObject is a string, this method will put single quotes to both its side and escape any necessary
 character using prepareString: method. If theObject is NSData, the prepareBinaryData: method will be
 used instead.
 For NSNumber object, the number is just quoted, for calendar dates, the calendar date is formatted in
 the preferred format for the database.
 "*/
{
	NSString* result;
	@synchronized(self){
		if (!theObject) {
			return @"NULL";
		}
		else if ([theObject isKindOfClass:[NSData class]]) {
			result = [NSString stringWithFormat:@"'%@'",[self prepareBinaryData:(NSData *) theObject]];
		}
		else if ([theObject isKindOfClass:[NSString class]]) {
			result = [NSString stringWithFormat:@"'%@'", [self prepareString:(NSString *) theObject]];
		}
		else if ([theObject isKindOfClass:[NSNumber class]]) {
			result = [NSString stringWithFormat:@"%@", theObject];
		}
		else if ([theObject isKindOfClass:[NSDate class]]) {
			result = [NSString stringWithFormat:@"'%@'", [(NSDate *)theObject descriptionFromTemplate:@"yy-MM-dd HH:mm:ss"]];
		}
		else if ((nil == theObject) || ([theObject isKindOfClass:[NSNull class]])) {
			result = @"NULL";
		}
		// Default : quote as string:
		else result = [NSString stringWithFormat:@"'%@'", [self prepareString:[theObject description]]];
	}
	return result;
}


- (ORSqlResult*) queryString:(NSString *) query
{
	ORSqlResult*	theResult = nil;
    if([query length]==0)return theResult;
    
	NSException* e;
	@synchronized(self){
        if(mConnection){
            const char*	theCQuery = [query UTF8String];
            int         theQueryCode;
            if ((theQueryCode = mysql_query(mConnection, theCQuery)) == 0) {
                if (mysql_field_count(mConnection) != 0) {
                    theResult = [[[ORSqlResult alloc] initWithMySQLPtr:mConnection]autorelease];
                }
            }
            else {
                NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Problem in queryString error code is : %d, query is : %s -in ObjC : %@-\n", theQueryCode, theCQuery, query] forKey:@"Description"];
                e = [NSException exceptionWithName: @"SQL Exception"
                                                         reason: [self getLastErrorMessage]
                                                       userInfo: userInfo];
                @throw e;			
            }
        }
	}
    return theResult ;
}

- (uint64_t) affectedRows
{
	uint64_t num = 0;
	@synchronized(self){
		if (mConnection) {
			num = mysql_affected_rows(mConnection);
		}
	}
    return num;
}


- (uint64_t) insertId
/*"
 If the last query was an insert in a table having a autoindex column, returns the id (autoindexed field) of the last row inserted.
 "*/
{
	uint64_t num = 0;
	@synchronized(self){
		if (mConnection) {
			num = mysql_insert_id(mConnection);
		}
	}
    return num;
}

- (ORSqlResult *) listDBs
{
    ORSqlResult*  theResult = nil;
	@synchronized(self){
        if(mConnection){
            MYSQL_RES*	theResPtr = mysql_list_dbs(mConnection, NULL);
        
            if (theResPtr) {
                theResult = [[[ORSqlResult alloc]initWithResPtr: theResPtr]autorelease];
            }
        }
	}
    return theResult;
}


- (ORSqlResult*) listTables
{
    ORSqlResult* theResult = nil;
 	@synchronized(self){
        if(mConnection){
            MYSQL_RES* theResPtr = mysql_list_tables(mConnection, NULL);
        
            if (theResPtr) {
                theResult = [[[ORSqlResult alloc] initWithResPtr: theResPtr]autorelease];
            }
        }
	}
    return theResult;
}


- (ORSqlResult *) listTablesFromDB:(NSString *) dbName 
{	
	ORSqlResult* theResult = nil;
	@synchronized(self){
        if(mConnection){
            NSString* theQuery   = [NSString stringWithFormat:@"SHOW TABLES FROM %@", dbName];
            theResult = [self queryString:theQuery];
        }
	}
    return theResult;
}


- (ORSqlResult*)listFieldsFromTable:(NSString *)tableName
{	
	ORSqlResult* theResult = nil;
	@synchronized(self){
		NSString*  theQuery = [NSString stringWithFormat:@"SHOW COLUMNS FROM %@", tableName];
		theResult = [self queryString:theQuery];
	}
    return theResult;
}


- (NSString*) clientInfo
{
	NSString* result = nil;
	@synchronized(self){
		result =  [NSString stringWithCString:mysql_get_client_info() encoding:NSISOLatin1StringEncoding];
	}
	return result;
}

- (NSString *) hostInfo
/*"
 Returns a string giving information on the host of the DB server.
 "*/
{
	NSString* result = nil;
	@synchronized(self){
		if (mConnection) {
			result = [NSString stringWithCString:mysql_get_host_info(mConnection) encoding:NSISOLatin1StringEncoding];
		}
	}
	return result;
}


- (NSString *) serverInfo
{
 	NSString* result = nil;
	@synchronized(self){
		if (mConnection) {
			result = [NSString stringWithCString: mysql_get_server_info(mConnection) encoding:NSISOLatin1StringEncoding];
		}
	}
    return result;
}

- (NSNumber*) protoInfo
{
	NSNumber* result = nil;
 	@synchronized(self){
		if (mConnection) {
			result= [NSNumber numberWithUnsignedInt:mysql_get_proto_info(mConnection) ];
		}
	}
	return result;
}


- (ORSqlResult *) listProcesses
{
    ORSqlResult* theResult = nil;
	@synchronized(self){
        if(mConnection){
            MYSQL_RES* theResPtr = mysql_list_processes(mConnection);
	
            if (theResPtr) {
                theResult = [[[ORSqlResult alloc] initWithResPtr:theResPtr] autorelease];
            }
        }
	}
    return theResult;
}

- (BOOL)createDBWithName:(NSString *)dbName
{
	
	if ((mConnection) && (![self queryString: [NSString stringWithFormat:@"create database if not exists %@",dbName]])) {
		return YES;
	}
	return NO;
}
 /*
 - (BOOL)dropDBWithName:(NSString *)dbName
 {
 const char	*theDBName = [dbName UTF8String];
 if ((mConnection) && (! mysql_drop_db(mConnection, theDBName))) {
 return YES;
 }
 return NO;
 }
 */

- (BOOL) killProcess:(uint32_t) pid
{	
    int theErrorCode = 0; 
	@synchronized(self){
        if(mConnection){
            theErrorCode = mysql_kill(mConnection, pid);
        }
	}
    return (theErrorCode) ? NO : YES;
}
@end

@implementation ORSqlConnection (private)
- (NSString*) prepareBinaryData:(NSData *) theData
{
	return [theData base64Encoding]; 
}

- (NSString *) prepareString:(NSString *) theString
{
    const char*	 theCStringBuffer = [theString UTF8String];
    
	if(!mConnection)return nil;
    
    if ([theString length]==0) return @"";
    
    uint32_t theLength = (uint32_t)strlen(theCStringBuffer);
    char* theCEscBuffer = (char *)calloc(sizeof(char),(theLength * 2) + 1);
    mysql_real_escape_string(mConnection, theCEscBuffer, theCStringBuffer, theLength);
    NSString*  theReturn = [NSString stringWithCString:theCEscBuffer encoding:NSISOLatin1StringEncoding];
    free (theCEscBuffer);
    return theReturn;    
}
@end

//-----------------------------------------------------------
//ORSqlQueue: A shared queue for Sqldb access. You should 
//never have to use this object directly. It will be created
//on demand when a SqlDB op is called.
//-----------------------------------------------------------
@implementation ORSqlDBQueue
SYNTHESIZE_SINGLETON_FOR_ORCLASS(SqlDBQueue);
+ (NSOperationQueue*) queue
{
	return [[ORSqlDBQueue sharedSqlDBQueue] queue];
}

+ (void) addOperation:(NSOperation*)anOp
{
	return [[ORSqlDBQueue sharedSqlDBQueue] addOperation:anOp];
}

+ (NSUInteger) operationCount
{
	return 	[[ORSqlDBQueue sharedSqlDBQueue] operationCount];
}

//don't call this unless you're using this class in a special, non-global way.
- (id) init
{
	self = [super init];
	queue = [[NSOperationQueue alloc] init];
	[queue setMaxConcurrentOperationCount:1];
	
    return self;
}
- (NSOperationQueue*) queue
{
	return queue;
}
- (void) addOperation:(NSOperation*)anOp
{
	[queue addOperation:anOp];
}
- (NSInteger) operationCount
{
	return [[queue operations]count];
}
@end
