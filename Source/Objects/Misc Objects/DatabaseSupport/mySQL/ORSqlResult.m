//
//  ORSqlResult.m
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

NSDate* MCPYear0000;

@implementation ORSqlResult

- (id) initWithMySQLPtr:(MYSQL *) mySQLPtr
{
    self = [super init];
    mResult = mysql_store_result(mySQLPtr);
    if (mResult) {
        mNumOfFields = mysql_num_fields(mResult);
    }
    else {
        mNumOfFields = 0;
    }
    return self;
}


- (id) initWithResPtr:(MYSQL_RES *) mySQLResPtr
{
    self = [super init];
    mResult = mySQLResPtr;
    if (mResult) {
        mNumOfFields = mysql_num_fields(mResult);
    }
    else {
        mNumOfFields = 0;
    }
    return self;    
}

- (id) init
{
    self = [super init];
    mNumOfFields = 0;
    return self;    
}

- (uint64_t) numOfRows
{
    if (mResult) {
        return mysql_num_rows(mResult);
    }
    return 0;
}

- (unsigned int) numOfFields
{
    if (mResult) {
        return mNumOfFields = mysql_num_fields(mResult);
    }
    return mNumOfFields = 0;
}

- (void) dataSeek:(uint64_t) row
{
    uint64_t	theRow = row;
    theRow = (theRow < [self numOfRows])? theRow : ([self numOfRows]-1);
    mysql_data_seek(mResult,theRow);
    return;
}

- (id) fetchRowAsType:(MCPReturnType) aType
{
    MYSQL_ROW		theRow;
    unsigned long*	theLengths;
    MYSQL_FIELD*	theField;
    int				i;
    id				theReturn;
    if (mResult == NULL) {
        return nil;
    }

    theRow = mysql_fetch_row(mResult);
    if (theRow == NULL) {
        return nil;
    }

    switch (aType) {
        case MCPTypeArray:
            theReturn = [NSMutableArray arrayWithCapacity:mNumOfFields];
            break;
        case MCPTypeDictionary:
            if (mNames == nil) {
                [self fetchFieldsName];
            }
            theReturn = [NSMutableDictionary dictionaryWithCapacity:mNumOfFields];
            break;
        default :
            NSLog (@"Unknown type : %d, will return an Array!\n", aType);
            theReturn = [NSMutableArray arrayWithCapacity:mNumOfFields];
            break;
    }

    theLengths = mysql_fetch_lengths(mResult);
    theField = mysql_fetch_fields(mResult);
    for (i=0; i<mNumOfFields; i++) {
        id	theCurrentObj;

        if (theRow[i] == NULL) {
            theCurrentObj = [NSNull null];
        }
        else {
            char*	theData = calloc(sizeof(char),theLengths[i]+1);
            memcpy(theData, theRow[i],theLengths[i]);
            theData[theLengths[i]] = '\0';

            switch (theField[i].type) {
                case FIELD_TYPE_TINY:
                case FIELD_TYPE_SHORT:
                case FIELD_TYPE_INT24:
                case FIELD_TYPE_LONG:
                    theCurrentObj = (theField[i].flags & UNSIGNED_FLAG) ? [NSNumber numberWithUnsignedLong:strtoul(theData, NULL, 0)] : [NSNumber numberWithLong:strtol(theData, NULL, 0)];
						 break;
                case FIELD_TYPE_LONGLONG:
                   theCurrentObj = (theField[i].flags & UNSIGNED_FLAG) ? [NSNumber numberWithUnsignedLongLong:strtoull(theData, NULL, 0)] : [NSNumber numberWithLongLong:strtoll(theData, NULL, 0)];
                    break;
                case FIELD_TYPE_DECIMAL:
                case FIELD_TYPE_FLOAT:
                case FIELD_TYPE_DOUBLE:
                    theCurrentObj = [NSNumber numberWithDouble:atof(theData)];
                    break;
                case FIELD_TYPE_TIMESTAMP:
                    //------------------------
                    //deprecated method
                    // theCurrentObj = [NSDate dateFromString:[NSString stringWithUTF8String:theData] calendarFormat:@"%Y%m%d%H%M%S"];
                    //[theCurrentObj setCalendarFormat:@"%Y-%m-%d %H:%M:%S"];
                    //------------------------

                    //replacement:
                    {
                        NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                        [dateFormatter setDateFormat:@"%Y%m%d%H%M%S"];
                        NSDate* tempDate = [dateFormatter dateFromString:[NSString stringWithUTF8String:theData]];
                    
                        [dateFormatter setDateFormat:@"%Y-%m-%d %H:%M:%S"];
                        theCurrentObj = [dateFormatter dateFromString:[dateFormatter stringFromDate:tempDate]];
                    }
                    //------------------------
                   break;
                case FIELD_TYPE_DATE:
                    //------------------------
                    //deprecated method
                    //theCurrentObj = [NSDate dateFromString:[NSString stringWithUTF8String:theData] calendarFormat:@"%Y-%m-%d"];
                    //[theCurrentObj setCalendarFormat:@"%Y-%m-%d"];
                    //------------------------
                    //replacement:
                    {
                        NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                        [dateFormatter setDateFormat:@"%Y-%m-%d"];
                        NSDate* tempDate = [dateFormatter dateFromString:[NSString stringWithUTF8String:theData]];
                    
                        [dateFormatter setDateFormat:@"%Y-%m-%d"];
                        theCurrentObj = [dateFormatter dateFromString:[dateFormatter stringFromDate:tempDate]];
                    }
                    break;
                case FIELD_TYPE_TIME:
                    theCurrentObj = [NSString stringWithUTF8String:theData];
				    break;
                case FIELD_TYPE_DATETIME:
                    //------------------------
                    //deprecated method
                    //theCurrentObj = [NSDate dateFromString:[NSString stringWithCString:theData encoding:NSISOLatin1StringEncoding] calendarFormat:@"%Y-%m-%d %H:%M:%S"];
                    //[theCurrentObj setCalendarFormat:@"%Y-%m-%d %H:%M:%S"];
                    //------------------------
                    //replacement:
                    {
                        NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                        [dateFormatter setDateFormat:@"%Y-%m-%d %H:%M:%S"];
                        NSDate* tempDate = [dateFormatter dateFromString:[NSString stringWithUTF8String:theData]];
                    
                        [dateFormatter setDateFormat:@"%Y-%m-%d %H:%M:%S"];
                        theCurrentObj = [dateFormatter dateFromString:[dateFormatter stringFromDate:tempDate]];
                    }

                    break;
                case FIELD_TYPE_YEAR:
                    //------------------------
                    //deprecated method
                   // theCurrentObj = [NSDate dateFromString:[NSString stringWithCString:theData encoding:NSISOLatin1StringEncoding] calendarFormat:@"%Y"];
                    //[theCurrentObj setCalendarFormat:@"%Y"];
                    //------------------------
                    //replacement:
                    {
                        NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                        [dateFormatter setDateFormat:@"%Y"];
                        NSDate* tempDate = [dateFormatter dateFromString:[NSString stringWithUTF8String:theData]];
                    
                        [dateFormatter setDateFormat:@"%Y"];
                        theCurrentObj = [dateFormatter dateFromString:[dateFormatter stringFromDate:tempDate]];
                    }
                    if (!theCurrentObj) {
                        theCurrentObj = MCPYear0000;
                    }
                    break;
                case FIELD_TYPE_VAR_STRING:
                case FIELD_TYPE_STRING:
					theCurrentObj = [NSString stringWithCString:theData encoding:NSISOLatin1StringEncoding];
                    break;
                case FIELD_TYPE_TINY_BLOB:
                case FIELD_TYPE_BLOB:
                case FIELD_TYPE_MEDIUM_BLOB:
                case FIELD_TYPE_LONG_BLOB:
                    theCurrentObj = [NSString stringWithUTF8String:theData];
                   if (!(theField[i].flags & BINARY_FLAG)) { 
                      theCurrentObj = [self stringWithText:theCurrentObj];
                   }
                    break;
                case FIELD_TYPE_SET:
					theCurrentObj = [NSString stringWithCString:theData encoding:NSISOLatin1StringEncoding];
                    break;
                case FIELD_TYPE_ENUM:
					theCurrentObj = [NSString stringWithCString:theData encoding:NSISOLatin1StringEncoding];
                    break;
                case FIELD_TYPE_NULL:
				   theCurrentObj = [NSNull null];
                    break;
                case FIELD_TYPE_NEWDATE:
					theCurrentObj = [NSString stringWithCString:theData encoding:NSISOLatin1StringEncoding];
                    break;
                default:
                    NSLog (@"in fetchRowAsDictionary : Unknown type : %d for column %d, send back a NSData object", (int)theField[i].type, (int)i);
                    theCurrentObj = [NSData dataWithBytes:theData length:theLengths[i]];
                    break;
            }
            free(theData);
            if (theCurrentObj == nil) {
                theCurrentObj = [NSNull null];
            }
        }
        switch (aType) {
            case MCPTypeArray :
                [theReturn addObject:theCurrentObj];
                break;
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
    unsigned int		theNumFields;
    int				i;
    NSMutableArray		*theNamesArray;
    MYSQL_FIELD			*theField;

    if (mNames) {
        return mNames;
    }
    if (mResult == NULL) {
// If no results, give an empty array. Maybe it's better to give a nil pointer?
        return (mNames = [[NSArray array] retain]);
    }
    
    theNumFields = [self numOfFields];
    theNamesArray = [NSMutableArray arrayWithCapacity: theNumFields];
    theField = mysql_fetch_fields(mResult);    
    for (i=0; i<theNumFields; i++) {
        NSString	*theName = [NSString stringWithCString:theField[i].name encoding:NSISOLatin1StringEncoding];
        if ((theName) && (![theName isEqualToString:@""])) {
            [theNamesArray addObject:theName];
        }
        else {
            [theNamesArray addObject:[NSString stringWithFormat:@"Column %d", i]];
        }
    }
    
    return (mNames = [[NSArray arrayWithArray:theNamesArray] retain]);
}


- (id) fetchTypesAsType:(MCPReturnType) aType
{
    int				i;
    id				theTypes;
    MYSQL_FIELD			*theField;

    if (mResult == NULL) {
        return nil;
    }

    switch (aType) {
        case MCPTypeArray:
            theTypes = [NSMutableArray arrayWithCapacity:mNumOfFields];
            break;
        case MCPTypeDictionary:
            if (mNames == nil) {
                [self fetchFieldsName];
            }
            theTypes = [NSMutableDictionary dictionaryWithCapacity:mNumOfFields];
            break;
        default :
            NSLog (@"Unknown type : %d, will return an Array!\n", aType);
            theTypes = [NSMutableArray arrayWithCapacity:mNumOfFields];
            break;
    }
    theField = mysql_fetch_fields(mResult);
    for (i=0; i<mNumOfFields; i++) {
        NSString	*theType;
        switch (theField[i].type) {
            case FIELD_TYPE_TINY:
                theType = @"tiny";
                break;
            case FIELD_TYPE_SHORT:
                theType = @"short";
                break;
            case FIELD_TYPE_LONG:
                theType = @"int32_t";
                break;
            case FIELD_TYPE_INT24:
                theType = @"int24";
                break;
            case FIELD_TYPE_LONGLONG:
                theType = @"longlong";
                break;
            case FIELD_TYPE_DECIMAL:
                theType = @"decimal";
                break;
            case FIELD_TYPE_FLOAT:
                theType = @"float";
                break;
            case FIELD_TYPE_DOUBLE:
                theType = @"double";
                break;
            case FIELD_TYPE_TIMESTAMP:
                theType = @"timestamp";
                break;
            case FIELD_TYPE_DATE:
                theType = @"date";
                break;
            case FIELD_TYPE_TIME:
                theType = @"time";
                break;
            case FIELD_TYPE_DATETIME:
                theType = @"datetime";
                break;
            case FIELD_TYPE_YEAR:
                theType = @"year";
                break;
            case FIELD_TYPE_VAR_STRING:
                theType = @"varstring";
                break;
            case FIELD_TYPE_STRING:
                theType = @"string";
                break;
            case FIELD_TYPE_TINY_BLOB:
                theType = @"tinyblob";
                break;
            case FIELD_TYPE_BLOB:
                theType = @"blob";
                break;
            case FIELD_TYPE_MEDIUM_BLOB:
                theType = @"mediumblob";
                break;
            case FIELD_TYPE_LONG_BLOB:
                theType = @"longblob";
                break;
            case FIELD_TYPE_SET:
                theType = @"set";
                break;
            case FIELD_TYPE_ENUM:
                theType = @"enum";
                break;
            case FIELD_TYPE_NULL:
                theType = @"null";
                break;
            case FIELD_TYPE_NEWDATE:
                theType = @"newdate";
                break;
            default:
                theType = @"unknown";
                NSLog (@"in fetchTypesAsArray : Unknown type for column %d of the ORSqlResult, type = %d", (int)i, (int)theField[i].type);
                break;
        }
        switch (aType) {
            case MCPTypeArray :
                [theTypes addObject:theType];
                break;
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


- (unsigned int) fetchFlagsAtIndex:(unsigned int) index
{
   unsigned int      theRet;
   unsigned int		theNumFields;
   MYSQL_FIELD			*theField;
   
   if (mResult == NULL) {
      return (0);
   }
   
   theNumFields = [self numOfFields];
   theField = mysql_fetch_fields(mResult);
   if (index >= theNumFields) {
      theRet = 0;
   }
   else {
      theRet = theField[index].flags;
   }
   return theRet;
}

- (unsigned int) fetchFlagsForKey:(NSString *) key
{
   unsigned int     theRet;
   NSUInteger		index;
   MYSQL_FIELD*		theField;

   if (mResult == NULL) {
      return (0);
   }

   if (mNames == NULL) {
      [self fetchFieldsName];
   }

   theField = mysql_fetch_fields(mResult);
   if ((index = [mNames indexOfObject:key]) == NSNotFound) {
      theRet = 0;
   }
   else {
      theRet = theField[index].flags;
   }
   return theRet;
}

- (BOOL) isBlobAtIndex:(unsigned int) index
{
    BOOL			theRet;
    unsigned int		theNumFields;
    MYSQL_FIELD			*theField;

    if (mResult == NULL) {
// If no results, give an empty array. Maybe it's better to give a nil pointer?
        return (NO);
    }

    theNumFields = [self numOfFields];
    theField = mysql_fetch_fields(mResult);
    if (index >= theNumFields) {
        theRet = NO;
    }
    else {
        switch(theField[index].type) {
            case FIELD_TYPE_TINY_BLOB:
            case FIELD_TYPE_BLOB:
            case FIELD_TYPE_MEDIUM_BLOB:
            case FIELD_TYPE_LONG_BLOB:
                theRet = (theField[index].flags & BINARY_FLAG);
                break;
            default:
                theRet = NO;
                break;
        }
    }
    return theRet;
}

- (BOOL) isBlobForKey:(NSString *) key
{
    BOOL			theRet;
    NSInteger	index;
    MYSQL_FIELD*	theField;

    if (mResult == NULL) {
        return (NO);
    }

    if (mNames == NULL) {
        [self fetchFieldsName];
    }

    theField = mysql_fetch_fields(mResult);
    if ((index = [mNames indexOfObject:key]) == NSNotFound) {
        theRet = NO;
    }
    else {
        switch(theField[index].type) {
            case FIELD_TYPE_TINY_BLOB:
            case FIELD_TYPE_BLOB:
            case FIELD_TYPE_MEDIUM_BLOB:
            case FIELD_TYPE_LONG_BLOB:
                theRet = (theField[index].flags & BINARY_FLAG);
                break;
            default:
                theRet = NO;
                break;
        }
    }
    return theRet;
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
        return @"This is an empty ORSqlResult\n";
    }
    else {
        NSMutableString		*theString = [NSMutableString stringWithCapacity:0];
        int			i;
        NSArray			*theRow;
        MYSQL_ROW_OFFSET	thePosition;

        [theString appendFormat:@"ORSqlResult: (dim %d x %d)\n",(int32_t)mNumOfFields, (int32_t)[self numOfRows]];
        [self fetchFieldsName];
        for (i=0; i<(mNumOfFields-1); i++) {
            [theString appendFormat:@"%@\t", [mNames objectAtIndex:i]];
        }
        [theString appendFormat:@"%@\n", [mNames objectAtIndex:i]];
        thePosition = mysql_row_tell(mResult);
        [self dataSeek:0];
        for (;(theRow = [self fetchRowAsArray]);) {
            for (i=0; i<(mNumOfFields - 1); i++) {
                [theString appendFormat:@"%@\t", [theRow objectAtIndex:i]];
            }
            [theString appendFormat:@"%@\n", [theRow objectAtIndex:i]];
        }
        mysql_row_seek(mResult,thePosition);
        return theString;
    }
}


- (void) dealloc
{
    if (mResult) {
        mysql_free_result(mResult);
    }
	
    if (mNames) {
        [mNames autorelease];
    }
    
    [super dealloc];
    return;
}
@end
