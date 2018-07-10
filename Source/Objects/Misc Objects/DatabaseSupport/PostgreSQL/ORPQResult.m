//
//  ORPQResult.m
//
//  2016-06-01 Created by Phil Harvey (Based on ORSqlResult.m by M.Howe)
//
// Ref: https://www.postgresql.org/docs/9.5/static/libpq-exec.html
//

#import "ORPQConnection.h"
#import "ORPQResult.h"

// (constants are from postgresql/src/include/catalog/pg_type.h,
//  but that header doesn't compile, so define them here instead - PH)
enum {
    kPQTypeBool     = 16,   // 8 bit boolean
    kPQTypeByte     = 17,   // variable-length string with binary characters escaped
    kPQTypeChar     = 18,   // single 8 bit character
    kPQTypeName     = 19,   // 63-byte name
    kPQTypeInt64    = 20,   // 8-byte integer
    kPQTypeInt16    = 21,   // 2-byte integer
    kPQTypeVector16 = 22,   // vector of 2-byte integers
    kPQTypeInt32    = 23,   // 4-byte integer
    kPQTypeFloat4   = 700,  // 4-byte single precision float
    kPQTypeFloat8   = 701,  // 8-byte double precision float
    kPQTypeString   = 25,   // variable-length string
    kPQTypeArrayChar= 1002, // array of 8-bit characters
    kPQTypeArray16  = 1005, // array of 2-byte integers
    kPQTypeArray32  = 1007, // array of 4-byte integers
    kPQTypeArray64  = 1016, // array of 8-byte integers
};

@implementation ORPQResult

- (id) initWithResPtr:(PGresult *) PQResPtr
{
    self = [super init];
    mResult = PQResPtr;
    if (mResult) {
        mNumOfFields = PQnfields(mResult);
        mNumOfRows = PQntuples(mResult);
    }
    else {
        mNumOfFields = mNumOfRows = 0;
    }
    return self;    
}

- (id) init
{
    self = [super init];
    mNumOfFields = mNumOfRows = 0;
    return self;    
}

- (unsigned long long) numOfRows
{
    if (mResult) {
        return mNumOfRows = PQntuples(mResult);
    }
    return mNumOfRows = 0;
}

- (unsigned int) numOfFields
{
    if (mResult) {
        return mNumOfFields = PQnfields(mResult);
    }
    return mNumOfFields = 0;
}

- (id) fetchRowAsType:(MCPReturnType) aType
{
    return [self fetchRowAsType:aType row:0];
}

- (id) fetchRowAsType:(MCPReturnType)aType row:(int)aRow
{
    int		i;
    id		theReturn;

    if (mResult == NULL || !mNumOfRows) {
        return nil;
    }

    switch (aType) {
        default :
            NSLog (@"Unknown type : %d, will return an Array!\n", aType);
            // fall through!
        case MCPTypeArray:
            theReturn = [NSMutableArray arrayWithCapacity:mNumOfFields];
            break;
        case MCPTypeDictionary:
            if (mNames == nil) {
                [self fetchFieldsName];
            }
            theReturn = [NSMutableDictionary dictionaryWithCapacity:mNumOfFields];
            break;
    }

    for (i=0; i<mNumOfFields; i++) {
        Oid type = PQftype(mResult,i);
        id	theCurrentObj = nil;
        if (!PQgetisnull(mResult,aRow,i)) {
            char *pt = PQgetvalue(mResult,aRow,i);
            switch (type) {
                case kPQTypeBool:
                    if (*pt == 'f') {
                        theCurrentObj = [NSNumber numberWithInt:0];
                    } else if (*pt == 't') {
                        theCurrentObj = [NSNumber numberWithInt:1];
                    }
                    break;
                case kPQTypeByte:
                case kPQTypeString:
                    theCurrentObj = [NSString stringWithCString:pt encoding:NSISOLatin1StringEncoding];
                    break;
                case kPQTypeChar:
                case kPQTypeInt64:
                case kPQTypeInt16:
                case kPQTypeInt32:
                    theCurrentObj = [NSNumber numberWithLong:strtoll(pt, NULL, 0)];
                    break;
                case kPQTypeFloat4:
                    theCurrentObj = [NSNumber numberWithFloat:strtof(pt,NULL)];
                    break;
                case kPQTypeFloat8:
                    theCurrentObj = [NSNumber numberWithDouble:strtod(pt,NULL)];
                    break;
                case kPQTypeArrayChar:
                case kPQTypeArray16:
                case kPQTypeArray32:
                case kPQTypeArray64: {
                    int len = PQgetlength(mResult,aRow,i);
                    if (!len) break;
                    NSMutableArray *array = [NSMutableArray arrayWithCapacity:32];
                    char *tmp = (char *)malloc(len+1);
                    memcpy(tmp, pt, len);
                    tmp[len] = '\0';    // (add null terminator just to be safe)
                    char *last;
                    char *tok = strtok_r(tmp, "{}, ", &last);
                    while (tok) {
                        [array addObject:[NSNumber numberWithLong:strtoll(tok, NULL, 0)]];
                        tok = strtok_r(NULL, "{}, ", &last);
                    }
                    free(tmp);
                    theCurrentObj = array;
                } break;
            }
        }
        if (theCurrentObj == nil) {
            theCurrentObj = [NSNull null];
        }
        switch (aType) {
            case MCPTypeDictionary :
                [theReturn setObject:theCurrentObj forKey:[mNames objectAtIndex:i]];
                break;
            default :
                [theReturn addObject:theCurrentObj];
                break;
        }
    }
    return theReturn;
}


- (NSArray *) fetchRowAsArray
{
    NSMutableArray		*theArray = [self fetchRowAsType:MCPTypeArray];
    if (theArray) {
        return [NSArray arrayWithArray:theArray];
    }
    else {
        return nil;
    }
}


- (NSDictionary *) fetchRowAsDictionary
{
    NSMutableDictionary		*theDict = [self fetchRowAsType:MCPTypeDictionary];
    if (theDict) {
        return [NSDictionary dictionaryWithDictionary:theDict];
    }
    else {
        return nil;
    }
}


- (NSArray *) fetchFieldsName
{
    unsigned int	theNumFields;
    int				i;
    NSMutableArray	*theNamesArray;

    if (mNames) {
        return mNames;
    }
    if (mResult == NULL) {
// If no results, give an empty array. Maybe it's better to give a nil pointer?
        return (mNames = [[NSArray array] retain]);
    }
    
    theNumFields = [self numOfFields];
    theNamesArray = [NSMutableArray arrayWithCapacity: theNumFields];
    for (i=0; i<theNumFields; i++) {
        NSString	*theName = [NSString stringWithCString:PQfname(mResult, i) encoding:NSISOLatin1StringEncoding];
        if ((theName) && (![theName isEqualToString:@""])) {
            [theNamesArray addObject:theName];
        }
        else {
            [theNamesArray addObject:[NSString stringWithFormat:@"Column %d", i]];
        }
    }
    
    return (mNames = [[NSArray arrayWithArray:theNamesArray] retain]);
}

// (returns 0 if there is no value at those coordinates)
- (int64_t) getInt64atRow:(int)aRow column:(int)aColumn
{
    int64_t val = kPQBadValue;
    if (mResult && aRow<mNumOfRows && aColumn<mNumOfFields) {
        Oid type = PQftype(mResult,aColumn);
        if (!PQgetisnull(mResult,aRow,aColumn)) {
            char *pt = PQgetvalue(mResult,aRow,aColumn);
            switch (type) {
                case kPQTypeChar:
                case kPQTypeInt16:
                case kPQTypeInt32:
                case kPQTypeInt64: {
                    char *end;
                    val = strtoll(pt, &end, 0);
                    if (*pt == 0 || *end != 0) {
                        val = kPQBadValue;
                    }
                }   break;
                case kPQTypeBool:
                    if (*pt == 't') {
                        val = 1;
                    } else if (*pt == 'f') {
                        val = 0;
                    }
                    break;
            }
        }
    }
    return val;
}

- (NSMutableData *) getInt64arrayAtRow:(int)aRow column:(int)aColumn
{
    NSMutableData *theData = nil;
    int64_t val;
    if (mResult && aRow<mNumOfRows && aColumn<mNumOfFields) {
        Oid type = PQftype(mResult,aColumn);
        if (!PQgetisnull(mResult,aRow,aColumn)) {
            theData = [[[NSMutableData alloc] initWithLength:0] autorelease];
            char *pt = PQgetvalue(mResult,aRow,aColumn);
            switch (type) {
                case kPQTypeChar:
                case kPQTypeInt16:
                case kPQTypeInt32:
                case kPQTypeInt64: {
                    val = (int64_t)strtoll(pt, NULL, 0);
                    [theData appendBytes:&val length:sizeof(int64_t)];
                    break;
                }
                case kPQTypeBool:
                    if (*pt == 'f') {
                        val = 0;
                    } else if (*pt == 't') {
                        val = 1;
                    } else {
                        break;
                    }
                    [theData appendBytes:&val length:sizeof(int64_t)];
                    break;
                case kPQTypeArrayChar:
                case kPQTypeArray16:
                case kPQTypeArray32:
                case kPQTypeArray64: {
                    int len = PQgetlength(mResult,aRow,aColumn);
                    if (!len) break;
                    char *tmp = (char *)malloc(len+1);
                    memcpy(tmp, pt, len);
                    tmp[len] = '\0';    // (add null terminator just to be safe)
                    char *last;
                    char *tok = strtok_r(tmp, "{}, ", &last);
                    while (tok) {
                        char *end;
                        val = strtoll(tok, &end, 0);
                        if (*tok == 0 || *end != 0) {
                            val = kPQBadValue;
                        }
                        [theData appendBytes:&val length:sizeof(int64_t)];
                        tok = strtok_r(NULL, "{}, ", &last);
                    }
                    free(tmp);
                    break;
                }
            }
        }
    }
    return theData;
}

// get date from database assuming time is a local sudbury time
// (returns nil if there is no valid date at those coordinates)
- (NSDate *) getDateAtRow:(int)aRow column:(int)aColumn
{
    NSDate *date = nil;
    if (mResult && aRow<mNumOfRows && aColumn<mNumOfFields) {
        char *pt = PQgetvalue(mResult,aRow,aColumn);
        NSString *val = [NSString stringWithCString:pt encoding:NSASCIIStringEncoding];
        NSTimeZone *localZone = [NSTimeZone timeZoneWithName:@"America/Toronto"];
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        [formatter setTimeZone:localZone];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSSSS"];
        date = [formatter dateFromString:val];
    }
    return date;
}

- (BOOL) isNullAtRow:(int)aRow column:(int)aColumn
{
    if (mResult && aRow<mNumOfRows && aColumn<mNumOfFields) {
        return PQgetisnull(mResult,aRow,aColumn);
    }
    return YES;
}

- (id) fetchTypesAsType:(MCPReturnType) aType
{
    int				i;
    id				theTypes;

    if (mResult == NULL) {
        return nil;
    }

    switch (aType) {
        default :
            NSLog (@"Unknown type : %d, will return an Array!\n", aType);
            // fall through!
        case MCPTypeArray:
            theTypes = [NSMutableArray arrayWithCapacity:mNumOfFields];
            break;
        case MCPTypeDictionary:
            if (mNames == nil) {
                [self fetchFieldsName];
            }
            theTypes = [NSMutableDictionary dictionaryWithCapacity:mNumOfFields];
            break;
    }
    for (i=0; i<mNumOfFields; i++) {
        NSString	*theType;
        Oid ftype = PQftype(mResult,i);
        switch (ftype) {
            case kPQTypeBool:
                theType = @"bool";
                break;
            case kPQTypeByte:
            case kPQTypeString:
                theType = @"byte";
                break;
            case kPQTypeChar:
                theType = @"char";
                break;
            case kPQTypeName:
                theType = @"name";
                break;
            case kPQTypeInt16:
                theType = @"int2";
                break;
            case kPQTypeInt32:
                theType = @"int4";
                break;
            case kPQTypeInt64:
                theType = @"int8";
                break;
            case kPQTypeFloat4:
                theType = @"float4";
                break;
            case kPQTypeFloat8:
                theType = @"float8";
                break;
            default:
                theType = @"unknown";
                NSLog (@"in fetchTypesAsArray : Unknown type for column %d of the ORPQResult, type = %d", (int)i, (int)ftype);
                break;
        }
        switch (aType) {
            case MCPTypeDictionary :
                [theTypes setObject:theType forKey:[mNames objectAtIndex:i]];
                break;
            default :
                [theTypes addObject:theType];
                break;
        }
    }

    return theTypes;
}


- (NSArray *) fetchTypesAsArray
{
    NSMutableArray		*theArray = [self fetchTypesAsType:MCPTypeArray];
    if (theArray) {
        return [NSArray arrayWithArray:theArray];
    }
    else {
        return nil;
    }
}


- (NSDictionary*) fetchTypesAsDictionary
{
    NSMutableDictionary		*theDict = [self fetchTypesAsType:MCPTypeDictionary];
    if (theDict) {
        return [NSDictionary dictionaryWithDictionary:theDict];
    }
    else {
        return nil;
    }
}


- (NSString *) stringWithText:(NSData *) theTextData
{
    if (theTextData == nil) return nil;
    NSString* theString = [[NSString alloc] initWithData:theTextData encoding:NSISOLatin1StringEncoding];				
    return [theString autorelease];
}


- (NSString *) description
{
    if (mResult == NULL) {
        return @"This is an empty ORPQResult\n";
    }
    else {
        NSMutableString		*theString = [NSMutableString stringWithCapacity:0];
        int			i, j;

        [theString appendFormat:@"ORPQResult: (%ld fields)\n",(long)mNumOfFields];
        [self fetchFieldsName];
        for (i=0; i<(mNumOfFields-1); i++) {
            [theString appendFormat:@"%@\t", [mNames objectAtIndex:i]];
        }
        [theString appendFormat:@"%@\n", [mNames objectAtIndex:i]];
        for (i=0; i<PQntuples(mResult); ++i) {
            for (j=0; j<(mNumOfFields - 1); ++j) {
                [theString appendFormat:@"%s\t", PQgetvalue(mResult, i, j)];
            }
            [theString appendFormat:@"%s\n", PQgetvalue(mResult, i, j)];
        }
        return theString;
    }
}

- (Boolean) isOK
{
    return (mResult && (PQresultStatus(mResult) == PGRES_COMMAND_OK || PQresultStatus(mResult) == PGRES_TUPLES_OK));
}

- (void) dealloc
{
    if (mResult) {
        PQclear(mResult);
        mResult = nil;
    }
	
    if (mNames) {
        [mNames autorelease];
    }
    
    [super dealloc];
    return;
}
@end
