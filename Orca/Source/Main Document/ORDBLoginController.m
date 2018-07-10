//
//  ORDBLoginController.m
//  Orca
//
//  Created by Mark Howe on Tue Feb 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ORDBLoginController.h"
#import "NKDPostgreSQLConnection.h"
#import "NKDPostgreSQLResultset.h"
#import "StatusLog.h"

@implementation ORDBLoginController

#pragma mark •••Accessors
- (NSWindow*) mainWindow
{
	return mainWindow;
}

- (NSPanel*) dbLogInSheet
{
	return dbLogInSheet;
}


- (IBAction) startLoginSheet:(id)sender
{
	[NSApp beginSheet:[self dbLogInSheet]
				modalForWindow:[self mainWindow]
				 modalDelegate:self
				didEndSelector:NULL
					  contextInfo:nil];
	
}

- (IBAction) endLoginSheet:(id)sender
{

	 NKDPostgreSQLConnection *nConn;
	 nConn = [NKDPostgreSQLConnection connectionWithDatabaseName: [dbTextField stringValue]
															User: [userTextField stringValue]
														Password: [passwordTextField stringValue]];
	 
	 // Bring up an alert panel to show status
	 if ([nConn isConnected]) {
		 NSRunAlertPanel(@"Good", @"Connection is up", nil, nil,nil);
		 //[loginSheet orderOut:nil];

		 // Prepare for executing and logging for connection
		 //[self fetchTypes];
		 //PQsetNoticeProcessor(connection, handle_notice, self);
		 NS_DURING
			 NSString	*query = @"select * from users;";  
			 NKDPostgreSQLResult *nRes = [nConn executeQuery:query];
			 if ([nRes wasError]) NSLog(@"Query error: %@\n", [nRes errorMessage]);

			 if (![nRes wasFatalError]){
				 if ([nRes hasResultset]){
					 NKDPostgreSQLResultset *rset = [nRes resultset];

					 NSLog(@"There is a result set\n");
					 NSLog(@"\tThere are %d fields\n", [rset fields]);
					 NSLog(@"\tThere are %d rows\n", [rset rows]);
					 short i,j;
					 for (i = 0; i < [rset rows]; i++){
						 NSLog(@"Row %d\n", i);
						 for (j=0; j< [rset fields];j++){
							 NSLog(@"%@: %@\n", [rset fieldNameAtIndex:j], [rset dataForFieldAtIndex:j row:i]);
						 }
					 }
				 }
				 else NSLog(@"There is no result set\n");
			 }
			 else NSLog(@"Fatal error on query\n");
		 NS_HANDLER
			 NSLog(@"PostgreSQL: %@\n", [localException userInfo]);
		 NS_ENDHANDLER
		 
		 // Hide the sheet
		 [[self dbLogInSheet] orderOut:nil];
		 [NSApp endSheet:[self dbLogInSheet]];
		 
	 }  else {
		 NSRunAlertPanel(@"Bad", @"Connection not up = %d", nil, nil,nil, [nConn errorMessage]);

		 // Give them another chance (clear connection, don't hide sheet)
		// [self disconnect];
	 }


}


@end
