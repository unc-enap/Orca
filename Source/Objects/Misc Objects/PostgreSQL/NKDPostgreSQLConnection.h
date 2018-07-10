// -----------------------------------------------------------------------------------
// NKDPostgreSQLConnection.h
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
#import "NKDPostgreSQLResult.h"

/*!
@header NKDPostgreSQLConnection.h
 This is a Cocoa-wrapper around the libcpg functions for connecting to a PostgreSQL database.
 */

/*!
@class NKDPostgreSQLConnection
@discussion This is a Cocoa-wrapper around the libcpg functions for connecting to a PostgreSQL database. It currently only supports creating connections from scratch with no support for resetting connections or using the same connection to connect to a different database.
*/
@interface NKDPostgreSQLConnection : NSObject
{
    PGconn		*conn;
}

// Convenience methods - new Connection object should only be created using one of these class methods
/*!
 @method ConnectionWithHost: HostAddress: Port: DatabaseName: User: Password: RequiresSSL:
 @abstract Class "convenience" method that takes all possible options for creating the connection.
 @discussion This class, being just a wrapper around the libcpq, there are no init methods, but this is the equivalent of a designated initializer. Provide nil for any object that is not relevant.
 @result An initialized NKDPostgreSQLConnection object
 */
+(id)connectionWithHost: (NSString *)inHost
            HostAddress: (NSString *)inHostAddress
                   Port: (NSString *)inPort
           DatabaseName: (NSString *)inDBName
                   User: (NSString *)inUser
               Password: (NSString *)inPassword;

/*!
 @method connectionWithDatabaseName: User: Password:
 @abstract Convenience class method for establishing a connection to a database on the same machine
 @result An initialized NKDPostgreSQLConnection object
 */
+(id)connectionWithDatabaseName: (NSString *)inDBName
                           User: (NSString *)inUser
                       Password: (NSString *)inPassword;

/*!
 @method connectionWithHost: DatabaseName: User: Password:
 @abstract Convenience class method for establishing a connection to a database by hostname
 @result An initialized NKDPostgreSQLConnection object
*/
+(id)connectionWithHost: (NSString *)inHost
           DatabaseName: (NSString *)inDBName
                   User: (NSString *)inUser
               Password: (NSString *)inPassword;

/*!
 @method connectionWithHostAddress: Port: DatabaseName: User: Password:
 @abstract Convenience class method for establishing a connection to a database by host address and port
 @result An initialized NKDPostgreSQLConnection object
*/
+(id)connectionWithHostAddress: (NSString *)inHostAddress
                          Port: (NSString *)inPort
                  DatabaseName: (NSString *)inDBName
                          User: (NSString *)inUser
                      Password: (NSString *)inPassword;

// Private Accessor/Settor Functions
-(PGconn *)_conn;
-(void)_setConn:(PGconn *)inConn;

// Accessor functions
/*!
 @method host
 @abstract Returns the value of host name of the PostgreSQL database connected to.
 @result An NSString object representing the value of this connection's host if used 
 */
-(NSString *)host;

/*!
 @method port
 @abstract Accessor method for the port of the PostgreSQL server connected to
 @result NSString object containing a representation of the port that the object is connected to the server on.
 */
-(NSString *)port;

/*!
 @method databaseName
 @abstract Accessor method for the name of the database attached to
 @result NSString object containing a representation of the database name
 */
-(NSString *)databaseName;

/*!
 @method user
 @abstract Accessor method for the name of the user used in the connection
 @result NSString object containing a representation of the user
 */
-(NSString *)user;

/*!
 @method password
 @abstract Accessor method for the password being used to connect to the database
 @result NSString object containing a representation of the password
 */
-(NSString *)password;

/*!
 @method isConnected
 @abstract Tells if the connection was successfully established or not
 @result YES if we are connected to the database, NO otherwise
 */
-(BOOL)isConnected;

/*!
 @method isConnectionBad
 @abstract Tells us if we were unable to establish a connection
 @discussion isConnected will return NO if a connection is currently being negotiated. If isConnected is NO, then this method should be used to differentiate between bad connections, and those that are merely in progress
 @result YES if the attempt to connect failed.
 */
-(BOOL)isConnectionBad;
/*!
 @method errorMessage
 @abstract If the connection is bad, this method will tell why
 @result NSString object with a message telling why the connection wasn't made correctly, nil if connection is good.
 */
-(NSString *)errorMessage;

/*!
 @method executeQuery:
 @abstract Executes a SQL query or update on the database we're connected to. When a database error is encountered, executeQuery will raise an NSException with the message from the database passed as an NSString in the userInfo.
 @param query NSString representing the SQL to run against the database
 @result an NKDPostgreSQLResult object representing the result and (if applicable) data
 */
-(NKDPostgreSQLResult *)executeQuery: (NSString *)query;

/*!
 @method executeUpdate:
 @abstract Executes a SQL update on the database we're connected to and consumes the response. This is simply a convenience method for when you're not too concerned about the status of the udpate. It will throw an exception if an error condition occurs. Since updates don't generate a ResultSet, this method simplifies the process of hitting the database with an update. In the thrown exception, the actual error message generated by the database will be passed as an NSString in the userInfo of the NSException.
 @param query NSString representing the SQL to run against the database
 @result an NKDPostgreSQLResult object representing the result and (if applicable) data
*/
-(void)executeUpdate: (NSString *)query;
@end
