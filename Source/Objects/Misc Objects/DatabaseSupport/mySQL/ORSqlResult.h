//
//  ORSqlResult.h
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

typedef enum {
    MCPTypeArray = 1,
    MCPTypeDictionary = 2,
    MCPTypeFlippedArray = 3,
    MCPTypeFlippedDictionary = 4
} MCPReturnType;

@interface ORSqlResult : NSObject {
@protected
	MYSQL_RES*		mResult;	/*"The MYSQL_RES structure of the C API"*/
	NSArray*		mNames;	/*"An NSArray holding the name of the columns"*/
    NSDictionary*	mMySQLLocales;	/*"A Locales dictionary to define the locales of MySQL"*/
    unsigned int    mNumOfFields;	/*"The number of fields in the result"*/
}

- (id) initWithMySQLPtr:(MYSQL*) mySQLPtr;
- (id) initWithResPtr:(MYSQL_RES*) mySQLResPtr;
- (id) init;
- (void) dealloc;
- (unsigned long long) numOfRows;
- (unsigned int) numOfFields;
- (void) dataSeek:(unsigned long long) row;
- (id) fetchRowAsType:(MCPReturnType) aType;
- (NSArray *) fetchRowAsArray;
- (NSDictionary *) fetchRowAsDictionary;
- (NSArray *) fetchFieldsName;
- (id) fetchTypesAsType:(MCPReturnType) aType;
- (NSArray *) fetchTypesAsArray;
- (NSDictionary*) fetchTypesAsDictionary;
- (unsigned int) fetchFlagsAtIndex:(unsigned int) index;
- (unsigned int) fetchFlagsForKey:(NSString *) key;
- (BOOL) isBlobAtIndex:(unsigned int) index;
- (BOOL) isBlobForKey:(NSString *) key;
- (NSString *) stringWithText:(NSData *) theTextData;
- (NSString *) description;

@end
