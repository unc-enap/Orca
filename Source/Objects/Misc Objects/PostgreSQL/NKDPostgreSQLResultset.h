// -----------------------------------------------------------------------------------
// NKDPostgreSQLResultset.h
// -----------------------------------------------------------------------------------
//  Created by Jeff LaMarche on Sat Jul 13 2002.
//  ©2002 Naked Software. All rights reserved.
// -----------------------------------------------------------------------------------
// THIS	SOURCE CODE IS PROVIDED AS-IS WITH NO WARRANTY OF ANY KIND
// -----------------------------------------------------------------------------------
// You may use and redistribute this source code without the following limitations
// -----------------------------------------------------------------------------------
#import <Cocoa/Cocoa.h>
#import "libpq-fe.h"

/*!
@header NKDPostgreSQLResultset.h
 This is a Cocoa-wrapper around the libcpg functions concerning tuples.
 */

/*!
@class NKDPostgreSQLResultset
  This is a Cocoa-wrapper around the libcpg functions concerning tuples. The data is stored in NSArrays stored in an NSDictionary. Each array contains all the values corresponding to a given field, in the order returned. There is one NSArray in the NSDictionary for each field in the original tuples. There is a second NSDictionary used to keep track of which fieldnames correspond to which field index in the original tuples.
*/
@interface NKDPostgreSQLResultset : NSObject <NSCopying, NSCoding>
{
    NSDictionary	*results;	/* Contains the data returned by the query. Each column of data is stored in an NSArray
                                           which is stored in this NSDictionary keyed off of fieldname.*/
    NSDictionary	*fieldMappings;	/* Maps each field by name to the field number from the original query */
}
/*!
 @method resultSetWithPGresult:
 @abstract Convenience class method to create an NKDPostgreSQLResultset from the tuples in a PGresult pointer.
 @param inRes PGResult pointer returned as the result of executing a query
 @result Initialized NKDPostgreSQLResultset.h
 */
+(id)resultsetWithPGresult: (PGresult *)inRes;

-(NSDictionary *)_results;
-(NSDictionary *)_fieldMappings;
-(void)_setResults:(NSDictionary *)inResults;
-(void)_setFieldMappings:(NSDictionary *)inMappings;

/*!
 @method fields
 @abstract Returns the number of fields in the result set
 @result An integer representing the number of colums of data in the result set
 */
-(int)fields;

/*!
 @method rows
 @abstract The number of rows in the result set
 @result An integer representing the number of rows of data in the result set
 */
-(int)rows;

/*!
 @method fieldNameAtIndex:
 @abstract Gives the name of a field of a given number, calculated from the original tuples and zero-indexed.
 @param index the index number of the field you want the name for
 @result NSString object containing the name of the field
 */
-(NSString *)fieldNameAtIndex:(int)index;

/*!
 @method fieldNames
 @abstract Returns an enumerator with all the fieldnames in the result set
 @result NSEnumerator containing the names of all fields as NSString objects
 */
-(NSEnumerator *)fieldNames;

/*!
 @method dataForRow:
 @abstract Returns all of the data for a single row of the result set. Rows are indexed from zero.
 @param row The number of the row requested
 @result NSDictionary containing all of the data for the requested row. The NSDictionary contains one entry keyed off of each fieldname; the object it points to is the data.
 */
-(NSDictionary *)dataForRow:(int)row;

/*!
 @method dataForFieldAtIndex: row:
 @abstract Returns the data for a specific column and row
 @param index The column number of the data requested
 @param row The row number of the data requested
 @result An NSString object representing the data at the specified juncture of row and column
 */
-(NSString *)dataForFieldAtIndex:(int)index row:(int)row;

/*!
 @method dataForFieldOfName: row:
 @abstract Returns the data for a specific named column and row
 @param field NSString containing the field name of the column requested
 @param row The row number of the data requested
 @result An NSString object representing the data at the specified juncture of row and column
 */
-(NSString *)dataForFieldOfName:(NSString *)field row:(int)row;

/*!
 @method columnForFieldName:
 @abstract Returns an enumerator containing all the data for a given column referenced by name
 @param inName NSString containing the field name of the column being requested
 @result An NSEnumerator with the data for the requested column
 */
-(NSEnumerator *)columnForFieldName:(NSString *)inName;

/*!
 @method columnForFieldAtIndex:
 @abstract Returns an enumerator containing all the data for a given column referenced by number
 @param index Integer representing the index of the column being requested
 @result An NSEnumerator with the data for the requested column
 */
-(NSEnumerator *)columnForFieldAtIndex:(int)index;

/*!
 @method numberOfRowsInTableView:
 @abstract Partial implementation of NSTableDataSource informal protocol allows the result set to be used (read-only) in an NSTableView
 @param aTableView Ignored
 @result The number of rows in the result set
 */
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;

/*!
 @method tableView: objectValueForTableColumn: row:
 @abstract  Partial implementation of NSTableDataSource informal protocol allows the result set to be used (read-only) in an NSTableView
 @param aTableView Ignored
 @param aTableColumn Used to grab the column identifier. The column identifier must match up <i>exactly</i> with the field name of a column. The comparison is case sensitive.
 @param rowIndex The row that the value is being requested for
 @result NSString object containing the data for the requested row
 */
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;


@end
