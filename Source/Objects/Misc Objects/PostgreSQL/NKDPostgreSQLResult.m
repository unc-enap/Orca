// -----------------------------------------------------------------------------------
// NKDPostgreSQLResult.m
// -----------------------------------------------------------------------------------
//  Created by Jeff LaMarche on Sat Jul 13 2002.
//  �2002 Naked Software. All rights reserved.
// -----------------------------------------------------------------------------------
// THIS	SOURCE CODE IS PROVIDED AS-IS WITH NO WARRANTY OF ANY KIND
// -----------------------------------------------------------------------------------
// You may use and redistribute this source code without the following limitations
// -----------------------------------------------------------------------------------
#import "NKDPostgreSQLResult.h"

@implementation NKDPostgreSQLResult
// -----------------------------------------------------------------------------------
+(id)resultWithPGresult:(PGresult *)inRes
// -----------------------------------------------------------------------------------
{
    NKDPostgreSQLResult	*result = [[NKDPostgreSQLResult alloc] init];

    [result _setRes:inRes];

    if (PQresultStatus(inRes) == PGRES_TUPLES_OK)
        [result _setResultset:[NKDPostgreSQLResultset resultsetWithPGresult:inRes]];


    return [result autorelease];
}
// -----------------------------------------------------------------------------------
-(PGresult *)_res
// -----------------------------------------------------------------------------------
{
    return res;
}
// -----------------------------------------------------------------------------------
-(void)_setRes: (PGresult *)inRes
// -----------------------------------------------------------------------------------
{
    res = inRes;
}
// -----------------------------------------------------------------------------------
-(void)_setResultset:(NKDPostgreSQLResultset *)inSet
// -----------------------------------------------------------------------------------
{
    [resultset autorelease];
    resultset = [inSet retain];
}
// -----------------------------------------------------------------------------------
-(BOOL)hasResultset
// -----------------------------------------------------------------------------------
{
    return [self resultset] != nil;
}
// -----------------------------------------------------------------------------------
-(NKDPostgreSQLResultset *)resultset
// -----------------------------------------------------------------------------------
{
    return resultset;
}
// -----------------------------------------------------------------------------------
-(BOOL)wasError
// -----------------------------------------------------------------------------------
{
    int stat = PQresultStatus(res);
    return ( (stat == PGRES_BAD_RESPONSE) ||
             (stat == PGRES_NONFATAL_ERROR) ||
             (stat == PGRES_FATAL_ERROR) );
}
// -----------------------------------------------------------------------------------
-(BOOL)wasFatalError
// -----------------------------------------------------------------------------------
{
    int stat = PQresultStatus(res);
    return ( (stat == PGRES_BAD_RESPONSE) ||
             (stat == PGRES_FATAL_ERROR) );
}
// -----------------------------------------------------------------------------------
-(NSString *)errorMessage
// -----------------------------------------------------------------------------------
{
    return [NSString stringWithCString: PQresultErrorMessage(res) encoding:NSASCIIStringEncoding];
}
// -----------------------------------------------------------------------------------
-(void)dealloc
// -----------------------------------------------------------------------------------
{
    PQclear(res);
    [resultset release];
	[super dealloc];
}
@end
