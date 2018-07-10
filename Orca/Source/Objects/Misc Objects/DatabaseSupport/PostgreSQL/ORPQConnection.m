//
//  ORPQConnection.m
//
//  2016-06-01 Created by Phil Harvey (Based on ORSqlConnection.m by M.Howe)
//


#import "ORPQConnection.h"
#import "ORPQResult.h"
#import "SynthesizeSingleton.h"

@interface ORPQConnection (private)
- (NSString*) prepareBinaryData:(NSData *) theData;
- (NSString*) prepareString:(NSString *) theString;
@end

@implementation ORPQConnection

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

- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord
{
    return [self connectToHost:aHostName userName:aUserName passWord:aPassWord dataBase:@"detector" verbose:YES];
}

- (BOOL) connectToHost:(NSString*)aHostName userName:(NSString*)aUserName passWord:(NSString*)aPassWord dataBase:(NSString*)aDataBase verbose:(BOOL)verbose
{
    @synchronized(self){
        if(!mConnection && [aHostName length] && [aUserName length] && [aPassWord length] && [aDataBase length]) {
            NSArray *parts = [aHostName componentsSeparatedByString:@":"];
            NSString *conninfo;
            if ([parts count] > 1) {
                conninfo = [NSString stringWithFormat:@"host='%@' port='%@' user='%@' password='%@' dbname='%@'",
                            (NSString*)parts[0], (NSString *)parts[1], aUserName, aPassWord, aDataBase];
            } else {
                conninfo = [NSString stringWithFormat:@"host='%@' user='%@' password='%@' dbname='%@'",
                                  aHostName, aUserName, aPassWord, aDataBase];
            }
            mConnection = PQconnectdb([conninfo UTF8String]);
            if (!mConnection || PQstatus(mConnection) != CONNECTION_OK){
                if (verbose) {
                    NSLog(@"PostgreSQL db connection failed: %s\n", PQerrorMessage(mConnection));
                }
                [self disconnect];
            }
        }
    }
    return mConnection!=nil;
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


- (void) disconnect
{
	@synchronized(self){
		if (mConnection) {
			PQfinish(mConnection);
			mConnection = nil;
		}
	}
}

- (NSString *) getLastErrorMessage
{
	NSString* result = @"";
	@synchronized(self){
		if (mConnection) result= [NSString stringWithCString:PQerrorMessage(mConnection) encoding:NSISOLatin1StringEncoding];
		else			 result= @"No connection initailized\n";
	}
	return result;
}

- (int) getLastErrorID
{
	unsigned int result = -1;
	@synchronized(self){
		if (mConnection) result =  PQstatus(mConnection);
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
		PGresult *res = PQexec(mConnection,"select 1 limit 0");
		if (PQresultStatus(res) == PGRES_TUPLES_OK) {
		    result = YES;
		}
	}
	return result;
}

- (ORPQResult*) queryString:(NSString *) query
{
	ORPQResult*	theResult = nil;
    if([query length]==0)return theResult;
    
	NSException* e;
	@synchronized(self){
        if(mConnection){
            const char*	theCQuery = [query UTF8String];
            PGresult *  res = PQexec(mConnection, theCQuery);
            if (PQresultStatus(res) == PGRES_COMMAND_OK || PQresultStatus(res) == PGRES_TUPLES_OK) {
                theResult = [[[ORPQResult alloc] initWithResPtr:res] autorelease];
            } else {
                NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Postgres error %s in %s -in ObjC : %@-\n", PQresultErrorMessage(res), theCQuery, query] forKey:@"Description"];
                e = [NSException exceptionWithName: @"Posgres Exception"
                                            reason: [self getLastErrorMessage]
                                          userInfo: userInfo];
                PQclear(res);
                @throw e;			
            }
        }
	}
    return theResult ;
}


@end

@implementation ORPQConnection (private)
- (NSString*) prepareBinaryData:(NSData *) theData
{
	return [theData base64Encoding]; 
}

- (NSString *) prepareString:(NSString *) theString
{
    const char*	 theCStringBuffer = [theString UTF8String];
    
	if(!mConnection)return nil;
    
    if ([theString length]==0) return @"";
    
    unsigned int theLength = strlen(theCStringBuffer);
    char *theCEscStr = PQescapeLiteral(mConnection, theCStringBuffer, theLength);
    NSString *theReturn = [NSString stringWithCString:theCEscStr encoding:NSISOLatin1StringEncoding];
    PQfreemem(theCEscStr);
    return theReturn;    
}
@end

//-----------------------------------------------------------
//ORPQQueue: A shared queue for PQDB access. You should 
//never have to use this object directly. It will be created
//on demand when a PQDB op is called.
//-----------------------------------------------------------
@implementation ORPQDBQueue
SYNTHESIZE_SINGLETON_FOR_ORCLASS(PQDBQueue);
+ (NSOperationQueue*) queue
{
	return [[ORPQDBQueue sharedPQDBQueue] queue];
}

+ (void) addOperation:(NSOperation*)anOp
{
	return [[ORPQDBQueue sharedPQDBQueue] addOperation:anOp];
}

+ (NSUInteger) operationCount
{
	return 	[[ORPQDBQueue sharedPQDBQueue] operationCount];
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
