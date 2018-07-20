//
//  ORPQResult.h
//
//  2016-06-01 Created by Phil Harvey (Based on ORSqlResult.h by M.Howe)
//
#import "libpq-fe.h"

#define kPQBadValue 0x80000000ffffffffll

typedef enum {
    MCPTypeArray = 1,
    MCPTypeDictionary = 2,
    MCPTypeFlippedArray = 3,
    MCPTypeFlippedDictionary = 4
} MCPReturnType;

@interface ORPQResult : NSObject {
@protected
	PGresult*		mResult;	    /*"The GPresult structure of the libpq API"*/
	NSArray*		mNames;	        /*"An NSArray holding the name of the columns"*/
    NSDictionary*	mPQLocales;	    /*"A Locales dictionary to define the locales of PQ"*/
    unsigned int    mNumOfFields;	/*"The number of fields in the result"*/
    unsigned int    mNumOfRows;     /*"The number of rows in the result"*/
}

- (id) initWithResPtr:(PGresult *) PQResPtr;
- (id) init;
- (void) dealloc;
- (uint64_t) numOfRows;
- (unsigned int) numOfFields;
- (id) fetchRowAsType:(MCPReturnType) aType;
- (id) fetchRowAsType:(MCPReturnType) aType row:(int)aRow;
- (NSArray *) fetchRowAsArray;
- (NSDictionary *) fetchRowAsDictionary;
- (NSArray *) fetchFieldsName;
- (int64_t) getInt64atRow:(int)aRow column:(int)aColumn;
- (NSMutableData *) getInt64arrayAtRow:(int)aRow column:(int)aColumn;
- (NSDate *) getDateAtRow:(int)aRow column:(int)aColumn;
- (BOOL) isNullAtRow:(int)aRow column:(int)aColumn;
- (id) fetchTypesAsType:(MCPReturnType) aType;
- (NSArray *) fetchTypesAsArray;
- (NSDictionary*) fetchTypesAsDictionary;
- (NSString *) stringWithText:(NSData *) theTextData;
- (NSString *) description;
- (Boolean) isOK;

@end
