// -----------------------------------------------------------------------------------
// NKDPostgreSQLResultset.m
// -----------------------------------------------------------------------------------
//  Created by Jeff LaMarche on Sat Jul 13 2002.
//  �2002 Naked Software. All rights reserved.
// -----------------------------------------------------------------------------------
// THIS	SOURCE CODE IS PROVIDED AS-IS WITH NO WARRANTY OF ANY KIND
// -----------------------------------------------------------------------------------
// You may use and redistribute this source code without the following limitations
// -----------------------------------------------------------------------------------
#import "NKDPostgreSQLResultset.h"


@implementation NKDPostgreSQLResultset
// -----------------------------------------------------------------------------------
+(id)resultsetWithPGresult: (PGresult *)inRes
// -----------------------------------------------------------------------------------
{
    int 			row, field;
    int				numRows = PQntuples(inRes);
    int				numFields = PQnfields(inRes);
    NSMutableDictionary 	*columns, *fields;
    NKDPostgreSQLResultset	*rset = [[NKDPostgreSQLResultset alloc] init];
    
    columns = [NSMutableDictionary dictionaryWithCapacity: numFields];
    fields = [NSMutableDictionary dictionaryWithCapacity: numFields];
    
    for (field=0; field <numFields; field++)
    {
        NSMutableArray    *array = [NSMutableArray arrayWithCapacity:numRows];
        [fields setObject:[NSString stringWithCString: PQfname(inRes, field) encoding:NSASCIIStringEncoding] forKey: [NSNumber numberWithInt:field]];

        for (row=0;row < numRows; row++)
	    if (! PQgetisnull(inRes, row, field))
		[array addObject:[NSString stringWithCString:PQgetvalue(inRes, row, field) encoding:NSASCIIStringEncoding]];
	    else
		[array addObject:[NSNull null]];
	

        [columns setObject:array forKey:[NSString stringWithCString: PQfname(inRes, field) encoding:NSASCIIStringEncoding]];
    }

    [rset _setResults:columns];
    [rset _setFieldMappings:fields];

    return [rset autorelease];
}
// -----------------------------------------------------------------------------------
-(NSDictionary *)_results
// -----------------------------------------------------------------------------------
{
    return results;
}
// -----------------------------------------------------------------------------------
-(NSDictionary *)_fieldMappings
// -----------------------------------------------------------------------------------
{
    return fieldMappings;
}
// -----------------------------------------------------------------------------------
-(void)_setResults:(NSDictionary *)inResults
// -----------------------------------------------------------------------------------
{
    [results autorelease];
    results = [inResults retain];
}
// -----------------------------------------------------------------------------------
-(void)_setFieldMappings:(NSDictionary *)inMappings
// -----------------------------------------------------------------------------------
{
    [fieldMappings autorelease];
    fieldMappings = [inMappings retain];
}
// -----------------------------------------------------------------------------------
-(int)fields
// -----------------------------------------------------------------------------------
{
    return [fieldMappings count];
}
// -----------------------------------------------------------------------------------
-(int)rows
// -----------------------------------------------------------------------------------
{
    NSArray *col = [results objectForKey:[fieldMappings objectForKey:[NSNumber numberWithInt:0]]];
    return (col == nil) ? 0 : [col count];
}
// -----------------------------------------------------------------------------------
-(NSString *)fieldNameAtIndex:(int)index
// -----------------------------------------------------------------------------------
{
    return (NSString *)[fieldMappings objectForKey:[NSNumber numberWithInt:index]];
}
// -----------------------------------------------------------------------------------
-(NSEnumerator *)fieldNames
// -----------------------------------------------------------------------------------
{
    return [results keyEnumerator];
}
// -----------------------------------------------------------------------------------
-(NSDictionary *)dataForRow:(int)row
// -----------------------------------------------------------------------------------
{
    int		i;
    NSMutableDictionary	*dic = [NSMutableDictionary dictionaryWithCapacity:[self fields]];

    for (i = 0; i < [self fields]; i++)
    {
        NSArray *col = [results objectForKey:[fieldMappings objectForKey:[NSNumber numberWithInt:i]]];
        [dic setObject:[col objectAtIndex:row] forKey:[self fieldNameAtIndex:i]];
    }
    return dic;
}
// -----------------------------------------------------------------------------------
-(NSString *)dataForFieldAtIndex:(int)index row:(int)row
// -----------------------------------------------------------------------------------
{
    return [self dataForFieldOfName:[fieldMappings objectForKey:[NSNumber numberWithInt:index]] row:row];
}
// -----------------------------------------------------------------------------------
-(NSString *)dataForFieldOfName:(NSString *)field row:(int)row
// -----------------------------------------------------------------------------------
{
    return [[results objectForKey:field] objectAtIndex:row];
}
// -----------------------------------------------------------------------------------
-(NSEnumerator *)columnForFieldName:(NSString *)inName
// -----------------------------------------------------------------------------------
{
    return [[results objectForKey:inName] objectEnumerator];
}
// -----------------------------------------------------------------------------------
-(NSEnumerator *)columnForFieldAtIndex:(int)index
// -----------------------------------------------------------------------------------
{
    return [self columnForFieldName:[fieldMappings objectForKey:[NSNumber numberWithInt:index]]];
}
// -----------------------------------------------------------------------------------
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
// -----------------------------------------------------------------------------------
{
    return [self rows];
}
// -----------------------------------------------------------------------------------
- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
                      row:(int)rowIndex
// -----------------------------------------------------------------------------------
{
    // We expect the column identifier to match the field name
    return [self dataForFieldOfName:[aTableColumn identifier] row:rowIndex];
}
// -----------------------------------------------------------------------------------
-(NSString *)description
// -----------------------------------------------------------------------------------
{
    // *** TO DO: Override to give a useful description of the object
    return [super description];
}
// -----------------------------------------------------------------------------------
- (id)copyWithZone:(NSZone *)zone
// -----------------------------------------------------------------------------------
{
    NKDPostgreSQLResultset *ret =  [[self class] alloc];
    [ret _setResults:[self _results]];
    [ret _setFieldMappings:[self _fieldMappings]];
     return ret;
} 
// -----------------------------------------------------------------------------------
- (id)initWithCoder:(NSCoder *)coder
// -----------------------------------------------------------------------------------
{
    // Since we subclass NSObject, this call to super
    // init is not necessary, but it's good form to
    // include it, as it is possible that someday
    // NSObject's -init method will do something
    // -----------------------------------------------
    self = 	[super init];
    [self _setResults:[coder decodeObject]];
    [self _setFieldMappings:[coder decodeObject]];

    return self;
}
//----------------------------------------------------------------------
- (void) encodeWithCoder: (NSCoder *)coder
//----------------------------------------------------------------------
{    
    [coder encodeObject:[self _results]];
    [coder encodeObject:[self _fieldMappings]];
} 
// -----------------------------------------------------------------------------------
-(void)dealloc
// -----------------------------------------------------------------------------------
{
    [results release];
    [fieldMappings release];
	[super dealloc];
}
@end
