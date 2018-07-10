// -----------------------------------------------------------------------------------
// NKDPostgreSQLResult.h
// -----------------------------------------------------------------------------------
//  Created by Jeff LaMarche on Sat Jul 13 2002.
//  ©2002 Naked Software. All rights reserved.
// -----------------------------------------------------------------------------------
// THIS	SOURCE CODE IS PROVIDED AS-IS WITH NO WARRANTY OF ANY KIND
// -----------------------------------------------------------------------------------
// You may use and redistribute this source code without the following limitations
// -----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "libpq-fe.h"
#import "NKDPostgreSQLResultset.h"

/*!
@header NKDPostgreSQLResult.h
 This is a Cocoa-wrapper around the libcpg functions representing a query result against a PostgreSQL database.
 */

/*!
@class NKDPostgreSQLResult
@discussion  This is a Cocoa-wrapper around the libcpg functions representing a query result against a PostgreSQL database.
*/

@interface NKDPostgreSQLResult : NSObject
{
    PGresult			*res;
    NKDPostgreSQLResultset 	*resultset;
}

// Convenience class methods
/*!
 @method resultWithPGresult:
 @abstract Convenience class method that returns an autoreleased NKDPostgreSQLResult object based on a provided PGresult pointer
 @param inRes PGresult pointer returned from executing a query
 @result Autoreleased NKDPostgreSQLResult object
 */
+(id)resultWithPGresult:(PGresult *)inRes;

// Private accessor / settor methods - Not included in HeaderDoc
-(PGresult *)_res;
-(void)_setRes: (PGresult *)inRes;
-(void)_setResultset:(NKDPostgreSQLResultset *)inSet;

// Public accessors - wrappers for PGresult functions
/*!
 @method hasResultset
 @abstract Tells if there is a set of data resulting from this query or update
 @result YES if there is data that can be retrieved as an NKDPostgreSQLResultset
 */
-(BOOL)hasResultset;

/*!
 @method resultset
 @abstract Accessor method for getting the results of the query
 @result NKDPostgreSQLResultset object containing returned data, or NIL if query returned no data
 */
-(NKDPostgreSQLResultset *)resultset;

/*!
 @method wasError
 @abstract Tells if an error (fatal or non-fatal) was encountered executing the query/update
 @result YES if there was an error
 */
-(BOOL)wasError;

/*!
 @method wasFatalError
 @abstract Tells if a fatal error was encountered executing the query/update
 @result YES if a fatal error was encountered
 */
-(BOOL)wasFatalError;

/*!
 @method errorMessage
 @abstract Gives more information about any error received
 @result NSString object containing a message about the received error, or nil if no error received or no information about the error available.
 */
-(NSString *)errorMessage;
@end
