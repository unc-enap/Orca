//
//  ORSqlModel.m
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

#import "ORSqlModel.h"
#import "ORRunModel.h"
#import "OR1DHisto.h"
#import "OR2DHisto.h"
#import "ORMaskedWaveform.h"
#import "ORSqlConnection.h"
#import "ORSqlResult.h"
#import "ORAlarm.h"
#import "ORAlarmCollection.h"
#import "ORExperimentModel.h"
#import "ORSegmentGroup.h"
#import "ORProcessModel.h"
#import "MemoryWatcher.h"
#import "NSNotifications+Extensions.h"
#import "Utilities.h"
#import "ORStatusController.h"
#import "ORDataProcessing.h"

NSString* ORSqlModelStealthModeChanged = @"ORSqlModelStealthModeChanged";
NSString* ORSqlDataBaseNameChanged	= @"ORSqlDataBaseNameChanged";
NSString* ORSqlPasswordChanged		= @"ORSqlPasswordChanged";
NSString* ORSqlUserNameChanged		= @"ORSqlUserNameChanged";
NSString* ORSqlHostNameChanged		= @"ORSqlHostNameChanged";
NSString* ORSqlConnectionValidChanged	= @"ORSqlConnectionValidChanged";
NSString* ORSqlLock					= @"ORSqlLock";

static NSString* ORSqlModelInConnector 	= @"ORSqlModelInConnector";

@interface ORSqlModel (private)
- (ORSqlConnection*) sqlConnection;
- (void) updateDataSets;
- (void) updateExperiment;
- (void) addMachineName;
- (void) removeMachineName;
- (void) updateUptime;
- (void) postRunState:(NSNotification*)aNote;
- (void) postRunTime:(NSNotification*)aNote;
- (void) postRunOptions:(NSNotification*)aNote;
- (void) objectCountChanged:(NSNotification*)aNote;
- (void) statusLogChanged:(NSNotification*)aNote;
- (void) updateStatus;
- (void) collectProcesses;
- (void) collectSegmentMap;
- (void) collectAlarms;
- (void) alarmPosted:(NSNotification*)aNote;
- (void) alarmCleared:(NSNotification*)aNote;
- (void) createMachinesTableInDataBase:(NSString*)aDataBase;
- (void) createAlarmsTableInDataBase:(NSString*)aDataBase;
- (void) createProcessTableInDataBase:(NSString*)aDataBase;
- (void) createExperimentTableInDataBase:(NSString*)aDataBase;
- (void) createHistogram1DTableInDataBase:(NSString*)aDataBase;
- (void) createHistogram2DTableInDataBase:(NSString*)aDataBase;
- (void) createRunsTableInDataBase:(NSString*)aDataBase;
- (void) createSegmentMapTableInDataBase:(NSString*)aDataBase;
- (void) createWaveformsTableInDataBase:(NSString*)aDataBase;
- (void) createStatusLogTableInDataBase:(NSString*)aDataBase;
- (void) createPushTableInDataBase:(NSString*)aDataBase;
@end

@implementation ORSqlModel

#pragma mark ***Initialization
- (id) init
{
	self=[super init];
 //   [[self undoManager] disableUndoRegistration];
//	[self registerNotificationObservers];
//    [[self undoManager] enableUndoRegistration];
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [dataBaseName release];
    [password release];
    [userName release];
    [hostName release];
	[super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
		[self registerNotificationObservers];
		[self addMachineName];
    }
    [super wakeUp];
}


- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(!stealthMode)[self removeMachineName];
    [[ORSqlDBQueue queue]cancelAllOperations];
	[[ORSqlDBQueue queue] waitUntilAllOperationsAreFinished];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super sleep];
}

- (void) awakeAfterDocumentLoaded
{
	[self addMachineName];

}
- (BOOL) solitaryObject
{
    return YES;
}
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Sql"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORSqlController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORSqlModelInConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB I' ];
	[ aConnector addRestrictedConnectionType: 'DB O' ]; //can only connect to DB outputs
	
    [aConnector release];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[notifyCenter removeObserver:self];
	
    [notifyCenter addObserver : self
                     selector : @selector(applicationIsTerminating:)
                         name : @"ORAppTerminating"
                       object : (ORAppDelegate*)[NSApp delegate]];
	
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(postRunTime:)
                         name : ORRunElapsedTimesChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmPosted:)
                         name : ORAlarmWasPostedNotification
                       object : nil];	
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmCleared:)
                         name : ORAlarmWasClearedNotification
                       object : nil];	

	[notifyCenter addObserver : self
                     selector : @selector(postRunOptions:)
                         name : ORRunQuickStartChangedNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(postRunOptions:)
                         name : ORRunTimedRunChangedNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(postRunOptions:)
                         name : ORRunRepeatRunChangedNotification
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(postRunOptions:)
                         name : ORRunTimeLimitChangedNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(postRunOptions:)
                         name : ORRunOfflineRunNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(collectProcesses)
                         name : ORProcessRunningChangedNotification
                       object : nil];	
	
	[notifyCenter addObserver : self
                     selector : @selector(objectCountChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];	
	
	[notifyCenter addObserver : self
                     selector : @selector(objectCountChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];	
	
	[notifyCenter addObserver : self
                     selector : @selector(collectSegmentMap)
                         name : ORSegmentGroupMapReadNotification
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(statusLogChanged:)
                         name : ORStatusLogUpdatedNotification
                       object : nil];		
	
}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
	[self removeMachineName];
}


#pragma mark ***Accessors
- (id) nextObject
{
	return [self objectConnectedTo:ORSqlModelInConnector];
}

- (BOOL) stealthMode
{
    return stealthMode;
}

- (void) setStealthMode:(BOOL)aStealthMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStealthMode:stealthMode];
    stealthMode = aStealthMode;
	if(stealthMode){
		[self removeMachineName];
	}
	else {
		[self addMachineName];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSqlModelStealthModeChanged object:self];
}

- (NSString*) dataBaseName
{
    return dataBaseName;
}

- (void) setDataBaseName:(NSString*)aDataBaseName
{
	if(aDataBaseName){
		[[[self undoManager] prepareWithInvocationTarget:self] setDataBaseName:dataBaseName];
		
		[dataBaseName autorelease];
		dataBaseName = [aDataBaseName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlDataBaseNameChanged object:self];
	}
}

- (NSString*) password
{
    return password;
}

- (void) setPassword:(NSString*)aPassword
{
	if(aPassword){
		[[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
		
		[password autorelease];
		password = [aPassword copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlPasswordChanged object:self];
	}
}

- (NSString*) userName
{
    return userName;
}

- (void) setUserName:(NSString*)aUserName
{
	if(aUserName){
		[[[self undoManager] prepareWithInvocationTarget:self] setUserName:userName];
		
		[userName autorelease];
		userName = [aUserName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlUserNameChanged object:self];
	}
}

- (NSString*) hostName
{
    return hostName;
}

- (void) setHostName:(NSString*)aHostName
{
	if(aHostName){
		[[[self undoManager] prepareWithInvocationTarget:self] setHostName:hostName];
		
		[hostName autorelease];
		hostName = [aHostName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlHostNameChanged object:self];
	}
}

- (void) createDatabase
{
	//assumes that mysql is running on the host
	//assumes that the user specified in the dialog exists and has the priveleges needed to create things. 
	//You'd  run the following command from a mySQL command line to grant all privileges:
	//GRANT ALL PRIVILEGES ON *.* TO userName @ hostName IDENTIFIED BY PASSWORD aPassword

	@try{ [self createMachinesTableInDataBase:dataBaseName]; }		@catch(NSException* e){}
	@try{ [self createRunsTableInDataBase:dataBaseName]; }			@catch(NSException* e){}
	@try{ [self createAlarmsTableInDataBase:dataBaseName]; }		@catch(NSException* e){}
	@try{ [self createProcessTableInDataBase:dataBaseName]; }		@catch(NSException* e){}
	@try{ [self createExperimentTableInDataBase:dataBaseName]; }	@catch(NSException* e){}
	@try{ [self createHistogram1DTableInDataBase:dataBaseName]; }	@catch(NSException* e){}
	@try{ [self createHistogram2DTableInDataBase:dataBaseName]; }	@catch(NSException* e){}
	@try{ [self createSegmentMapTableInDataBase:dataBaseName]; }	@catch(NSException* e){}
	@try{ [self createWaveformsTableInDataBase:dataBaseName]; }		@catch(NSException* e){}
	@try{ [self createStatusLogTableInDataBase:dataBaseName]; }		@catch(NSException* e){}
	
	@try{ [self createPushTableInDataBase:dataBaseName]; }		    @catch(NSException* e){}
}

- (void) dropAllTables
{
	@try{[self dropTable:@"Histogram1Ds"]; }	@catch(NSException* e){}
	@try{[self dropTable:@"Histogram2Ds"]; }	@catch(NSException* e){}
	@try{[self dropTable:@"Processes"]; }		@catch(NSException* e){}
	@try{[self dropTable:@"alarms"]; }			@catch(NSException* e){}
	@try{[self dropTable:@"experiment"]; }		@catch(NSException* e){}
	//@try{[self dropTable:@"pushInfo"]; }		@catch(NSException* e){}
	@try{[self dropTable:@"runs"]; }			@catch(NSException* e){}
	@try{[self dropTable:@"segmentMap"]; }		@catch(NSException* e){}
	@try{[self dropTable:@"statuslog"]; }		@catch(NSException* e){}
	@try{[self dropTable:@"waveforms"]; }		@catch(NSException* e){}
	@try{[self dropTable:@"machines"]; }		@catch(NSException* e){}
}

- (void) dropTable:(NSString*) aTableName
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection selectDB:dataBaseName]){
				NSString*	s = [NSString stringWithFormat:@"Drop table %@",aTableName];
				[aConnection queryString:s];
				NSLog(@"Dropped Table %@ from the SQL database\n",aTableName);
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
	
	
}

- (void) removeEntry
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection selectDB:dataBaseName]){
				NSString* hw_address	 = macAddress();
				NSString*	s = [NSString stringWithFormat:@"Delete from machines where hw_address=%@",
												[sqlConnection quoteObject:hw_address]];
				[aConnection queryString:s];
				[self addMachineName];
				NSLog(@"Removed and reloaded this machine's entry in the SQL DB\n");
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
	
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{    
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setDataBaseName:[decoder decodeObjectForKey:@"DataBaseName"]];
    [self setPassword:[decoder decodeObjectForKey:@"Password"]];
    [self setUserName:[decoder decodeObjectForKey:@"UserName"]];
    [self setHostName:[decoder decodeObjectForKey:@"HostName"]];
    [self setStealthMode:[decoder decodeBoolForKey:@"stealthMode"]];
    [[self undoManager] enableUndoRegistration];    
	[self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:stealthMode forKey:@"stealthMode"];
    [encoder encodeObject:dataBaseName forKey:@"DataBaseName"];
    [encoder encodeObject:password forKey:@"Password"];
    [encoder encodeObject:userName forKey:@"UserName"];
    [encoder encodeObject:hostName forKey:@"HostName"];
}

#pragma mark ***SQL Access
- (BOOL) testConnection
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	if(!sqlConnection) sqlConnection = [[ORSqlConnection alloc] init];
	if([sqlConnection isConnected]){
		[sqlConnection disconnect];
	} 
	
	if([sqlConnection connectToHost:hostName userName:userName passWord:password dataBase:dataBaseName]){
		[self addMachineName];
	}
	else {
		[self disconnectSql];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlConnectionValidChanged object:self];
	

	return [sqlConnection isConnected];
}

- (void) disconnectSql
{
	if(sqlConnection){
		[sqlConnection disconnect];
		[sqlConnection release];
		sqlConnection = nil;
		if([dataBaseName length] && [hostName length])NSLog(@"Disconnected from DataBase %@ on %@\n",dataBaseName,hostName);
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlConnectionValidChanged object:self];
	}
}

- (BOOL) connectioned
{
	return [sqlConnection isConnected];
}

- (void) logQueryException:(NSException*)e
{
	//assert(![NSThread isMainThread]);
	NSLogError([e reason],@"SQL",@"Query Problem",nil);
	[sqlConnection release];
	sqlConnection = nil;
}

@end

@implementation ORSqlModel (private)

- (void) createPushTableInDataBase:(NSString*)aDataBase
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection createDBWithName:aDataBase]){
				if([aConnection selectDB:aDataBase]){
					NSString*	s = @"CREATE TABLE pushInfo (";
					s = [s stringByAppendingString:@"push_id int(11) NOT NULL AUTO_INCREMENT,"];
					s = [s stringByAppendingString:@"hw_address varchar(32) NOT NULL,"];
					s = [s stringByAppendingString:@"deviceName varchar(100) NOT NULL,"];	 
					s = [s stringByAppendingString:@"deviceToken varchar(100) NOT NULL,"]; //apns token for this mobile device
					s = [s stringByAppendingString:@"alarmMask int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"PRIMARY KEY (push_id)"];
					s = [s stringByAppendingString:@") ENGINE=InnoDB"];
					
					[aConnection queryString:s];
					NSLog(@"Created Table PushInfo in Database %@\n",aDataBase);
				}
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
}


- (void) createMachinesTableInDataBase:(NSString*)aDataBase
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection createDBWithName:aDataBase]){
				if([aConnection selectDB:aDataBase]){
					NSString*	s = @"CREATE TABLE machines (";
					s = [s stringByAppendingString:@"machine_id int(11) NOT NULL AUTO_INCREMENT,"];
					s = [s stringByAppendingString:@"name varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"hw_address varchar(32) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"ip_address varchar(64) NOT NULL,"];
					s = [s stringByAppendingString:@"password varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"uptime varchar(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"version varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"PRIMARY KEY (machine_id),"];
					s = [s stringByAppendingString:@"UNIQUE KEY hw_address (hw_address)"];
					s = [s stringByAppendingString:@") ENGINE=InnoDB"];
					[aConnection queryString:s];
					NSLog(@"Created Table machines in Database %@\n",aDataBase);
				}
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
}

- (void) createRunsTableInDataBase:(NSString*)aDataBase
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection createDBWithName:aDataBase]){
				if([aConnection selectDB:aDataBase]){
					NSString*	s = @"CREATE TABLE runs (";
					s = [s stringByAppendingString:@"run_id int(11) NOT NULL AUTO_INCREMENT,"];
					s = [s stringByAppendingString:@"run int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"subrun int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"state int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"machine_id int(11) NOT NULL,"];
					s = [s stringByAppendingString:@"experiment varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"startTime varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"elapsedTime int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"timeToGo int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"elapsedSubRunTime int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"elapsedBetweenSubRunTime int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"timeLimit int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"quickStart tinyint(1) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"repeatRun tinyint(1) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"offline tinyint(1) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"timedRun tinyint(1) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"PRIMARY KEY (run_id),"];
					s = [s stringByAppendingString:@"KEY machine_id (machine_id),"];
					s = [s stringByAppendingString:@"FOREIGN KEY (machine_id) REFERENCES machines (machine_id) ON DELETE CASCADE ON UPDATE CASCADE) ENGINE=InnoDB"];
					
					[aConnection queryString:s];
					NSLog(@"Created Table Runs in Database %@\n",aDataBase);
				}
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
}
- (void) createStatusLogTableInDataBase:(NSString*)aDataBase
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection createDBWithName:aDataBase]){
				if([aConnection selectDB:aDataBase]){
					NSString*	s = @"CREATE TABLE statuslog (";
					s = [s stringByAppendingString:@"statuslog_id int(11) NOT NULL AUTO_INCREMENT,"];
					s = [s stringByAppendingString:@"machine_id int(11) NOT NULL,"];
					s = [s stringByAppendingString:@"statuslog longblob DEFAULT NULL,"];
					s = [s stringByAppendingString:@"PRIMARY KEY (statuslog_id),"];
					s = [s stringByAppendingString:@"KEY machine_id (machine_id),"];
					s = [s stringByAppendingString:@"FOREIGN KEY (machine_id) REFERENCES machines (machine_id) ON DELETE CASCADE ON UPDATE CASCADE) ENGINE=InnoDB"];
					
					[aConnection queryString:s];
					NSLog(@"Created Table StatusLog in Database %@\n",aDataBase);
				}
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
}

- (void) createAlarmsTableInDataBase:(NSString*)aDataBase
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection createDBWithName:aDataBase]){
				if([aConnection selectDB:aDataBase]){
					NSString*	s = @"CREATE TABLE alarms (";
					s = [s stringByAppendingString:@"alarm_id int(11) NOT NULL AUTO_INCREMENT,"];
					s = [s stringByAppendingString:@"machine_id int(11) NOT NULL,"];
					s = [s stringByAppendingString:@"timePosted varchar(64) NOT NULL,"];
					s = [s stringByAppendingString:@"severity int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"name varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"help varchar(1024) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"PRIMARY KEY (alarm_id),"];
					s = [s stringByAppendingString:@"KEY machine_id (machine_id),"];
					s = [s stringByAppendingString:@"FOREIGN KEY (machine_id) REFERENCES machines (machine_id) ON DELETE CASCADE ON UPDATE CASCADE) ENGINE=InnoDB"];
					[aConnection queryString:s];
					NSLog(@"Created Table Alarms in Database %@\n",aDataBase);
				}
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
}

- (void) createExperimentTableInDataBase:(NSString*)aDataBase
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection createDBWithName:aDataBase]){
				if([aConnection selectDB:aDataBase]){
					NSString*	s = @"CREATE TABLE experiment (";
					s = [s stringByAppendingString:@"experiment_id int(11) NOT NULL AUTO_INCREMENT,"];
					s = [s stringByAppendingString:@"machine_id int(11) NOT NULL,"];
					s = [s stringByAppendingString:@"experiment varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"numberSegments int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"rates mediumblob,"];
					s = [s stringByAppendingString:@"totalCounts mediumblob,"];
					s = [s stringByAppendingString:@"thresholds mediumblob,"];
					s = [s stringByAppendingString:@"gains mediumblob,"];
					s = [s stringByAppendingString:@"ratesstr mediumblob,"];
					s = [s stringByAppendingString:@"totalCountsstr mediumblob,"];
					s = [s stringByAppendingString:@"thresholdsstr mediumblob,"];
					s = [s stringByAppendingString:@"gainsstr mediumblob,"];
					s = [s stringByAppendingString:@"PRIMARY KEY (experiment_id),"];
					s = [s stringByAppendingString:@"KEY machine_id (machine_id),"];
					s = [s stringByAppendingString:@"FOREIGN KEY (machine_id) REFERENCES machines (machine_id) ON DELETE CASCADE ON UPDATE CASCADE) ENGINE=InnoDB"];
					[aConnection queryString:s];
					NSLog(@"Created Table Experiment in Database %@\n",aDataBase);
				}
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
}


- (void) createSegmentMapTableInDataBase:(NSString*)aDataBase
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection createDBWithName:aDataBase]){
				if([aConnection selectDB:aDataBase]){
					NSString*	s = @"CREATE TABLE segmentMap (";
					s = [s stringByAppendingString:@"segment_id int(11) NOT NULL AUTO_INCREMENT,"];
					s = [s stringByAppendingString:@"machine_id int(11) NOT NULL,"];
					s = [s stringByAppendingString:@"monitor_id int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"segment int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"histogram1DName varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"crate int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"card int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"channel int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"PRIMARY KEY (segment_id),"];
					s = [s stringByAppendingString:@"KEY machine_id (machine_id),"];
					s = [s stringByAppendingString:@"FOREIGN KEY (machine_id) REFERENCES machines (machine_id) ON DELETE CASCADE ON UPDATE CASCADE) ENGINE=InnoDB"];
					[aConnection queryString:s];
					NSLog(@"Created Table SegmentMap in Database %@\n",aDataBase);
				}
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
}

- (void) createProcessTableInDataBase:(NSString*)aDataBase
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection createDBWithName:aDataBase]){
				if([aConnection selectDB:aDataBase]){
					NSString*	s = @"CREATE TABLE Processes (";
					s = [s stringByAppendingString:@"process_id int(11) NOT NULL AUTO_INCREMENT,"];
					s = [s stringByAppendingString:@"machine_id int(11) NOT NULL,"];
					s = [s stringByAppendingString:@"name varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"timeStamp varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"data mediumblob,"];
					s = [s stringByAppendingString:@"title varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"state int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"PRIMARY KEY (process_id),"];
					s = [s stringByAppendingString:@"KEY machine_id (machine_id),"];
					s = [s stringByAppendingString:@"FOREIGN KEY (machine_id) REFERENCES machines (machine_id) ON DELETE CASCADE ON UPDATE CASCADE) ENGINE=InnoDB"];
					
					[aConnection queryString:s];
					NSLog(@"Created Table Processes in Database %@\n",aDataBase);
				}
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
}

- (void) createWaveformsTableInDataBase:(NSString*)aDataBase
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection createDBWithName:aDataBase]){
				if([aConnection selectDB:aDataBase]){
					NSString*	s = @"CREATE TABLE waveforms (";
					s = [s stringByAppendingString:@"dataset_id int(11) NOT NULL AUTO_INCREMENT,"];
					s = [s stringByAppendingString:@"name varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"counts int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"machine_id int(11) NOT NULL,"];
					s = [s stringByAppendingString:@"monitor_id int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"type int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"unitsize int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"mask int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"bitmask int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"offset int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"length int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"data mediumblob,"];
					s = [s stringByAppendingString:@"PRIMARY KEY (dataset_id),"];
					s = [s stringByAppendingString:@"KEY machine_id (machine_id),"];
					s = [s stringByAppendingString:@"FOREIGN KEY (machine_id) REFERENCES machines (machine_id) ON DELETE CASCADE ON UPDATE CASCADE) ENGINE=InnoDB"];
					
					[aConnection queryString:s];
					NSLog(@"Created Table waveforms in Database %@\n",aDataBase);
				}
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
}

- (void) createHistogram1DTableInDataBase:(NSString*)aDataBase
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection createDBWithName:aDataBase]){
				if([aConnection selectDB:aDataBase]){
					NSString*	s = @"CREATE TABLE Histogram1Ds (";
					s = [s stringByAppendingString:@"dataset_id int(11) NOT NULL AUTO_INCREMENT,"];
					s = [s stringByAppendingString:@"name varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"counts int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"machine_id int(11) NOT NULL,"];
					s = [s stringByAppendingString:@"monitor_id int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"type int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"length int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"start int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"end int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"data mediumblob,"];
					s = [s stringByAppendingString:@"datastr mediumblob,"];
					s = [s stringByAppendingString:@"PRIMARY KEY (dataset_id),"];
					s = [s stringByAppendingString:@"KEY machine_id (machine_id),"];
					s = [s stringByAppendingString:@"FOREIGN KEY (machine_id) REFERENCES machines (machine_id) ON DELETE CASCADE ON UPDATE CASCADE) ENGINE=InnoDB"];
					
					[aConnection queryString:s];
					NSLog(@"Created Table Histogram1Ds in Database %@\n",aDataBase);
				}
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
}

- (void) createHistogram2DTableInDataBase:(NSString*)aDataBase
{
	ORSqlConnection* aConnection = [[ORSqlConnection alloc] init];
	@try {
		if([aConnection connectToHost:hostName userName:userName passWord:password]){
			if([aConnection createDBWithName:aDataBase]){
				if([aConnection selectDB:aDataBase]){
					NSString*	s = @"CREATE TABLE Histogram2Ds (";
					s = [s stringByAppendingString:@"dataset_id int(11) NOT NULL AUTO_INCREMENT,"];
					s = [s stringByAppendingString:@"name varchar(64) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"counts int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"machine_id int(11) NOT NULL,"];
					s = [s stringByAppendingString:@"monitor_id int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"type int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"length int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"binsperside int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"minX int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"minY int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"maxX int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"maxY int(11) DEFAULT NULL,"];
					s = [s stringByAppendingString:@"data mediumblob,"];
					s = [s stringByAppendingString:@"PRIMARY KEY (dataset_id),"];
					s = [s stringByAppendingString:@"KEY machine_id (machine_id),"];
					s = [s stringByAppendingString:@"FOREIGN KEY (machine_id) REFERENCES machines (machine_id) ON DELETE CASCADE ON UPDATE CASCADE) ENGINE=InnoDB"];
					
					[aConnection queryString:s];
					NSLog(@"Created Table Histogram2Ds in Database %@\n",aDataBase);
				}
			}
		}
	}
	@finally {
		[aConnection disconnect];
		[aConnection release];
	}
}


/*
 +------------+-------------+------+-----+---------+----------------+
 | Field      | Type        | Null | Key | Default | Extra          |
 +------------+-------------+------+-----+---------+----------------+
 | process_id | int(11)     | NO   | PRI | NULL    | auto_increment |
 | machine_id | int(11)     | NO   | MUL | NULL    |                |
 | name       | varchar(64) | YES  |     | NULL    |                |
 | timeStamp  | varchar(64) | YES  |     | NULL    |                |
 | data       | mediumblob  | YES  |     | NULL    |                |
 | title      | varchar(64) | YES  |     | NULL    |                |
 +------------+-------------+------+-----+---------+----------------+
 */
- (void) collectProcesses
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectProcesses) object:nil];
		NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORProcessModel")];
		ORProcessDataOp* anOp = [[ORProcessDataOp alloc] initWithDelegate:self];
		[anOp setProcesses:objs];
		[ORSqlDBQueue addOperation:anOp];
		[anOp release];
		[self performSelector:@selector(collectProcesses) withObject:nil afterDelay:30];	
	}
}

/*
 +------------+---------------+------+-----+---------+----------------+
 | Field      | Type          | Null | Key | Default | Extra          |
 +------------+---------------+------+-----+---------+----------------+
 | alarm_id   | int(11)       | NO   | PRI | NULL    | auto_increment |
 | machine_id | int(11)       | NO   | MUL | NULL    |                |
 | timePosted | varchar(64)   | NO   |     | NULL    |                |
 | severity   | int(11)       | YES  |     | NULL    |                |
 | name       | varchar(64)   | YES  |     | NULL    |                |
 | help       | varchar(1024) | YES  |     | NULL    |                |
 +------------+---------------+------+-----+---------+----------------+
*/
- (void) collectAlarms
{
	if(!stealthMode){
		NSArray* alarms = [[ORAlarmCollection sharedAlarmCollection] alarms];
		for(id anAlarm in alarms){
			ORPostAlarmOp* anOp = [[ORPostAlarmOp alloc] initWithDelegate:self];
			[anOp postAlarm:anAlarm];
			[ORSqlDBQueue addOperation:anOp];
			[anOp release];
		}
	}
}
/*
+-----------------+-------------+------+-----+---------+----------------+
| Field           | Type        | Null | Key | Default | Extra          |
+-----------------+-------------+------+-----+---------+----------------+
| segment_id      | int(11)     | NO   | PRI | NULL    | auto_increment |
| machine_id      | int(11)     | NO   | MUL | NULL    |                |
| monitor_id      | int(11)     | YES  |     | NULL    |                |
| segment         | int(11)     | YES  |     | NULL    |                |
| histogram1DName | varchar(64) | YES  |     | NULL    |                |
| crate           | int(11)     | YES  |     | NULL    |                |
| card            | int(11)     | YES  |     | NULL    |                |
| channel         | int(11)     | YES  |     | NULL    |                |
+-----------------+-------------+------+-----+---------+----------------+
 */
- (void) collectSegmentMap
{		
	if(!stealthMode){
		
		[[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
		NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
		if([runObjects count]){
            ORPostSegmentMapOp* anOp = [[ORPostSegmentMapOp alloc] initWithDelegate:self];
			NSArray* arrayOfHistos = [[runObjects objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
			if([arrayOfHistos count]){
				id histoObj = [arrayOfHistos objectAtIndex:0];
				//assume first one in the data chain
				[anOp setDataMonitorId:(int)[histoObj uniqueIdNumber]];
				[ORSqlDBQueue addOperation:anOp];
			}
			[anOp release];
		}
	}
}

- (ORSqlConnection*) sqlConnection
{
	@synchronized(self){
		BOOL oldConnectionValid = [sqlConnection isConnected];
		BOOL newConnectionValid = oldConnectionValid;
		if(!sqlConnection) sqlConnection = [[ORSqlConnection alloc] init];
		if(![sqlConnection isConnected]){
			newConnectionValid = [sqlConnection connectToHost:hostName userName:userName passWord:password dataBase:dataBaseName verbose:NO];
		}
	
		if(newConnectionValid != oldConnectionValid){
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORSqlConnectionValidChanged object:self];
		}
	}
	return [sqlConnection isConnected]?sqlConnection:nil;
}


/* Table: machines
 +------------+-------------+------+-----+---------+----------------+
 | Field      | Type        | Null | Key | Default | Extra          |
 +------------+-------------+------+-----+---------+----------------+
 | machine_id | int(11)     | NO   | PRI | NULL    | auto_increment |
 | name       | varchar(64) | YES  |     | NULL    |                |
 | hw_address | varchar(32) | YES  | UNI | NULL    |                |
 | ip_address | varchar(64) | NO   |     | NULL    |                |
 | password   | varchar(64) | YES  |     | NULL    |                |
 | version    | varchar(64) | YES  |     | NULL    |                |
 | uptime     | int(11)     | YES  |     | NULL    |                |
 +------------+-------------+------+-----+---------+----------------+
 */
- (void) addMachineName
{
	if(!stealthMode){
		ORPostMachineNameOp* anOp = [[ORPostMachineNameOp alloc] initWithDelegate:self];
		[ORSqlDBQueue addOperation:anOp];
		[anOp release];

		//[self postRunState:nil];
		NSDictionary* runInfo = nil;
		NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
		if([runObjects count]){
			ORRunModel* rc = [runObjects objectAtIndex:0];
			runInfo = [rc runInfo];
		}
		else {
			runInfo =  [NSMutableDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithLong:0],kRunNumber,
									  [NSNumber numberWithLong:0],kSubRunNumber,
									  [NSNumber numberWithLong:eRunStopped],  kRunMode,
									  nil];
			
		}
		if(runInfo){
		  [self postRunState:[NSNotification notificationWithName:@"DoesNotMatter" object:nil userInfo:runInfo]];
		}
		[self performSelector:@selector(collectAlarms) withObject:nil afterDelay:2];
		[self performSelector:@selector(collectProcesses) withObject:nil afterDelay:2];
		[self performSelector:@selector(collectSegmentMap) withObject:nil afterDelay:2];
		[self performSelector:@selector(updateUptime) withObject:nil afterDelay:2];
		[self performSelector:@selector(updateStatus) withObject:nil afterDelay:2];
	}
}

- (void) removeMachineName
{
	ORDeleteMachineNameOp* anOp = [[ORDeleteMachineNameOp alloc] initWithDelegate:self];
	[ORSqlDBQueue addOperation:anOp];
	[anOp release];	
}

- (void) updateUptime
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateUptime) object:nil];
		ORUpdateUptime* anOp = [[ORUpdateUptime alloc] initWithDelegate:self];
		[ORSqlDBQueue addOperation:anOp];
		[anOp release];
		[self performSelector:@selector(updateUptime) withObject:nil afterDelay:5];	
	}
}

- (void) statusLogChanged:(NSNotification*)aNote
{
	if(!stealthMode){
		if(!statusUpdateScheduled){
			[self performSelector:@selector(updateStatus) withObject:nil afterDelay:10];
			statusUpdateScheduled = YES;
		}
	}
}

/* Table: statuslog
 +--------------------------+-------------+------+-----+---------+----------------+
 | Field                    | Type        | Null | Key | Default | Extra          |
 +--------------------------+-------------+------+-----+---------+----------------+
 | statuslog_id             | int(11)     | NO   | PRI | NULL    | auto_increment |
 | machine_id               | int(11)     | NO   | MUL | NULL    |                |
 | statuslog                | longblob    | YES  |     | NULL    |                |
 +--------------------------+-------------+------+-----+---------+----------------+
*/
- (void) updateStatus
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateStatus) object:nil];
	statusUpdateScheduled = NO;
	NSString* s = [[ORStatusController sharedStatusController] contents];	
	ORPostStatusLogOp* anOp = [[ORPostStatusLogOp alloc] initWithDelegate:self];
	[anOp setStatusLog:s];
	[ORSqlDBQueue addOperation:anOp];
	[anOp release];
	
}


/* Table: runs
 +--------------------------+-------------+------+-----+---------+----------------+
 | Field                    | Type        | Null | Key | Default | Extra          |
 +--------------------------+-------------+------+-----+---------+----------------+
 | run_id                   | int(11)     | NO   | PRI | NULL    | auto_increment |
 | run                      | int(11)     | YES  |     | NULL    |                |
 | subrun                   | int(11)     | YES  |     | NULL    |                |
 | state                    | int(11)     | YES  |     | NULL    |                |
 | machine_id               | int(11)     | NO   | MUL | NULL    |                |
 | experiment               | varchar(64) | YES  |     | NULL    |                |
 | startTime                | varchar(64) | YES  |     | NULL    |                |
 | elapsedTime              | int(11)     | YES  |     | NULL    |                |
 | timeToGo                 | int(11)     | YES  |     | NULL    |                |
 | elapsedSubRunTime        | int(11)     | YES  |     | NULL    |                |
 | elapsedBetweenSubRunTime | int(11)     | YES  |     | NULL    |                |
 | timeLimit                | int(11)     | YES  |     | NULL    |                |
 | quickStart               | tinyint(1)  | YES  |     | NULL    |                |
 | repeatRun                | tinyint(1)  | YES  |     | NULL    |                |
 | offline                  | tinyint(1)  | YES  |     | NULL    |                |
 | timedRun                 | tinyint(1)  | YES  |     | NULL    |                |
 +--------------------------+-------------+------+-----+---------+----------------+
 run types:
	0 stopped
	1 running
	2 starting
	3 stopping
	4 between subruns
 */
- (void) postRunState:(NSNotification*)aNote
{
	if(!stealthMode){
		id nextObject = [self objectConnectedTo:ORSqlModelInConnector];
		NSString* experimentName;
		if(!nextObject)	experimentName = @"TestStand";
		else {
			experimentName = [nextObject className];
			if([experimentName hasPrefix:@"OR"])experimentName = [experimentName substringFromIndex:2];
			if([experimentName hasSuffix:@"Model"])experimentName = [experimentName substringToIndex:[experimentName length] - 5];
		}
		ORPostRunStateOp* anOp = [[ORPostRunStateOp alloc] initWithDelegate:self];
		[anOp setRunModel:[aNote object]];
		[anOp setExperimentName:experimentName];
		[ORSqlDBQueue addOperation:anOp];
		[anOp release];
	}
}

- (void) postRunTime:(NSNotification*)aNote
{
	if(!stealthMode){
		ORPostRunTimesOp* anOp = [[ORPostRunTimesOp alloc] initWithDelegate:self];
		[anOp setRunModel:[aNote object]];
		[ORSqlDBQueue addOperation:anOp];
		[anOp release];
	}
}

- (void) postRunOptions:(NSNotification*)aNote
{
	if(!stealthMode){
		ORPostRunOptions* anOp = [[ORPostRunOptions alloc] initWithDelegate:self];
		[anOp setRunModel:[aNote object]];
		[ORSqlDBQueue addOperation:anOp];
		[anOp release];
	}
}

- (void) objectCountChanged:(NSNotification*)aNote
{
	if(!stealthMode){
		NSArray* objects = [[aNote userInfo] objectForKey:ORGroupObjectList];
		for(NSObject* obj in objects){
			if([obj isKindOfClass:NSClassFromString(@"ORProcessModel")]){
				[self performSelector:@selector(collectProcesses) withObject:nil afterDelay:3];
				break;
			}
		}
	}
}

- (void) runStatusChanged:(NSNotification*)aNote
{
	if(!stealthMode){
		id pausedKeyIncluded = [[aNote userInfo] objectForKey:@"ORRunPaused"];
		if(!pausedKeyIncluded){
			@try {
				int runState     = [[[aNote userInfo] objectForKey:ORRunStatusValue] intValue];
				
				[self postRunState:aNote];
				[self postRunTime:aNote];
				[self postRunOptions:aNote];
				if(runState == eRunInProgress){
					if(!dataMonitors)dataMonitors = [[NSMutableArray array] retain];
					NSArray* list = [[self document] collectObjectsOfClass:NSClassFromString(@"ORHistoModel")];
					for(ORDataChainObject* aDataMonitor in list){
						if([aDataMonitor involvedInCurrentRun]){
							[dataMonitors addObject:aDataMonitor];
						}
					}
					[self updateExperiment];
					[self updateDataSets];
				}
				else if(runState == eRunStopped){
					//[self postRunTime:aNote];
					[dataMonitors release];
					dataMonitors = nil;
					[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDataSets) object:nil];
					[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateExperiment) object:nil];
				}
				[self collectAlarms];
			}
			@catch (NSException* e) {
				//silently catch and continue
			}
		}
	}
}

/*Table: Histogram1Ds
 +------------+-------------+------+-----+---------+----------------+
 | Field      | Type        | Null | Key | Default | Extra          |
 +------------+-------------+------+-----+---------+----------------+
 | dataset_id | int(11)     | NO   | PRI | NULL    | auto_increment |
 | name       | varchar(64) | YES  |     | NULL    |                |
 | counts     | int(11)     | YES  |     | NULL    |                |
 | machine_id | int(11)     | NO   | MUL | NULL    |                |
 | monitor_id | int(11)     | YES  |     | NULL    |                |
 | type       | int(11)     | YES  |     | NULL    |                |
 | length     | int(11)     | YES  |     | NULL    |                |
 | start      | int(11)     | YES  |     | NULL    |                |
 | end        | int(11)     | YES  |     | NULL    |                |
 | data       | mediumblob  | YES  |     | NULL    |                |
 | datastr    | mediumblob  | YES  |     | NULL    |                |
 +------------+-------------+------+-----+---------+----------------+
 
 Table: waveforms
 +------------+-------------+------+-----+---------+----------------+
 | Field      | Type        | Null | Key | Default | Extra          |
 +------------+-------------+------+-----+---------+----------------+
 | dataset_id | int(11)     | NO   | PRI | NULL    | auto_increment |
 | name       | varchar(64) | YES  |     | NULL    |                |
 | counts     | int(11)     | YES  |     | NULL    |                |
 | machine_id | int(11)     | NO   | MUL | NULL    |                |
 | monitor_id | int(11)     | YES  |     | NULL    |                |
 | type       | int(11)     | YES  |     | NULL    |                |
 | unitsize   | int(11)     | YES  |     | NULL    |                |
 | mask       | int(11)     | YES  |     | NULL    |                |
 | bitmask    | int(11)     | YES  |     | NULL    |                |
 | offset     | int(11)     | YES  |     | NULL    |                |
 | length     | int(11)     | YES  |     | NULL    |                |
 | data       | mediumblob  | YES  |     | NULL    |                |
 +------------+-------------+------+-----+---------+----------------+
 
Table: Histogram2Ds
 +-------------+-------------+------+-----+---------+----------------+
 | Field       | Type        | Null | Key | Default | Extra          |
 +-------------+-------------+------+-----+---------+----------------+
 | dataset_id  | int(11)     | NO   | PRI | NULL    | auto_increment |
 | name        | varchar(64) | YES  |     | NULL    |                |
 | counts      | int(11)     | YES  |     | NULL    |                |
 | machine_id  | int(11)     | NO   | MUL | NULL    |                |
 | monitor_id  | int(11)     | YES  |     | NULL    |                |
 | type        | int(11)     | YES  |     | NULL    |                |
 | length      | int(11)     | YES  |     | NULL    |                |
 | binsperside | int(11)     | YES  |     | NULL    |                |
 | minX        | int(11)     | YES  |     | NULL    |                |
 | minY        | int(11)     | YES  |     | NULL    |                |
 | maxX        | int(11)     | YES  |     | NULL    |                |
 | maxY        | int(11)     | YES  |     | NULL    |                |
 | data        | mediumblob  | YES  |     | NULL    |                |
 +-------------+-------------+------+-----+---------+----------------+
 
 type field is a double check that the data is the right type for the table:
 0 undefined
 1 1DHisto
 2 2DHisto
 3 Waveform
*/ 
- (void) updateDataSets
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateDataSets) object:nil];
		ORPostDataOp* anOp = [[ORPostDataOp alloc] initWithDelegate:self];
		[anOp setDataMonitors:[[dataMonitors copy]autorelease]];
		[ORSqlDBQueue addOperation:anOp];
		[anOp release];
		[self performSelector:@selector(updateDataSets) withObject:nil afterDelay:10];
	}
}

/*Table: Experiment
 +----------------+-------------+------+-----+---------+----------------+
 | Field          | Type        | Null | Key | Default | Extra          |
 +----------------+-------------+------+-----+---------+----------------+
 | experiment_id  | int(11)     | NO   | PRI | NULL    | auto_increment |
 | machine_id     | int(11)     | NO   | MUL | NULL    |                |
 | experiment     | varchar(64) | YES  |     | NULL    |                |
 | numberSegments | int(11)     | YES  |     | NULL    |                |
 | rates          | mediumblob  | YES  |     | NULL    |                |
 | totalCounts    | mediumblob  | YES  |     | NULL    |                |
 | thresholds     | mediumblob  | YES  |     | NULL    |                |
 | gains          | mediumblob  | YES  |     | NULL    |                |
 | ratesstr       | mediumblob  | YES  |     | NULL    |                |
 | totalCountsstr | mediumblob  | YES  |     | NULL    |                |
 | thresholdsstr  | mediumblob  | YES  |     | NULL    |                |
 | gainsstr       | mediumblob  | YES  |     | NULL    |                |
 +----------------+-------------+------+-----+---------+----------------+
 */ 
- (void) updateExperiment
{
	if(!stealthMode){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateExperiment) object:nil];
		id nextObject = [self objectConnectedTo:ORSqlModelInConnector];
		if(nextObject){
			ORPostExperimentOp* anOp = [[ORPostExperimentOp alloc] initWithDelegate:self];
			[anOp setExperiment:nextObject];
			[ORSqlDBQueue addOperation:anOp];
			[anOp release];
		}
		
		[self performSelector:@selector(updateExperiment) withObject:nil afterDelay:10];
	}
}

/*
+------------+---------------+------+-----+---------+----------------+
| Field      | Type          | Null | Key | Default | Extra          |
+------------+---------------+------+-----+---------+----------------+
| alarm_id   | int(11)       | NO   | PRI | NULL    | auto_increment |
| machine_id | int(11)       | NO   | MUL | NULL    |                |
| timePosted | date          | NO   |     | NULL    |                |
| serverity  | int(11)       | YES  |     | NULL    |                |
| name       | varchar(64)   | YES  |     | NULL    |                |
| help       | varchar(1024) | YES  |     | NULL    |                |
+------------+---------------+------+-----+---------+----------------+
*/
- (void) alarmPosted:(NSNotification*)aNote
{
	if(!stealthMode){
		ORPostAlarmOp* anOp = [[ORPostAlarmOp alloc] initWithDelegate:self];
		[anOp postAlarm:[aNote object]];
		[ORSqlDBQueue addOperation:anOp];
		[anOp release];
	}
}

- (void) alarmCleared:(NSNotification*)aNote
{
	if(!stealthMode){
		ORPostAlarmOp* anOp = [[ORPostAlarmOp alloc] initWithDelegate:self];
		[anOp clearAlarm:[aNote object]];
		[ORSqlDBQueue addOperation:anOp];
		[anOp release];
	}
}
@end

@implementation ORSqlOperation
- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (NSString*) manglePw
{
	NSString* pw =  [[NSUserDefaults standardUserDefaults] objectForKey:OROrcaPassword];
	int i;
	for(i=0;i<[pw length];i++){
		char c = [pw characterAtIndex:i];
		pw = [pw stringByReplacingCharactersInRange:NSMakeRange(i,1) withString:[NSString stringWithFormat:@"%c",c+1]];
	}
	return pw;
}

@end

@implementation ORPostMachineNameOp
- (void) main
{
    if([self isCancelled])return;
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
		ORSqlConnection* sqlConnection = [[delegate sqlConnection] retain];
		if([sqlConnection isConnected]){
			NSString* name			 = computerName();
			NSString* hw_address	 = macAddress();
			NSString* thisHostAdress = @"";
			NSArray* names =  [[NSHost currentHost] addresses];
			NSEnumerator* e = [names objectEnumerator];
			id aName;
			while(aName = [e nextObject]){
				if([aName rangeOfString:@"::"].location == NSNotFound){
					if([aName rangeOfString:@".0.0."].location == NSNotFound){
						thisHostAdress = aName;
						break;
					}
				}
			}
			
			NSString* query = [NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",
									[sqlConnection quoteObject:hw_address]];
			ORSqlResult* theResult = [sqlConnection queryString:query];
			id d = [theResult fetchRowAsDictionary];
			if(!d){
				NSString* mangledPw = [self manglePw];
				NSString* query = [NSString stringWithFormat:@"INSERT INTO machines (name,hw_address,ip_address,password,version) VALUES (%@,%@,%@,%@,%@)",
									[sqlConnection quoteObject:name],
									[sqlConnection quoteObject:hw_address],
									[sqlConnection quoteObject:thisHostAdress],
									[sqlConnection quoteObject:mangledPw],
								    [sqlConnection quoteObject:fullVersion()]];
				[sqlConnection queryString:query];
			}
		}
		[sqlConnection release];

	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
    @finally {
        [thePool release];
    }
}

@end

@implementation ORDeleteMachineNameOp
- (void) main
{
    if([self isCancelled])return;
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
		ORSqlConnection* sqlConnection = [[delegate sqlConnection] retain];
		if([sqlConnection isConnected]){
			[sqlConnection queryString:[NSString stringWithFormat:@"DELETE from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
			[sqlConnection release];
		}
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
    @finally {
        [thePool release];
    }
}
@end

@implementation ORUpdateUptime
- (void) main
{
    if([self isCancelled])return;
   NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
		ORSqlConnection* sqlConnection = [[delegate sqlConnection] retain];
		if([sqlConnection isConnected]){
			uint32_t uptime = (uint32_t)[[(ORAppDelegate*)[NSApp delegate] memoryWatcher] accurateUptime];
			NSString* hw_address = macAddress();
		
			NSString* mangledPw = [self manglePw];
			NSString* theQuery = [NSString stringWithFormat:@"UPDATE machines SET uptime=%u,password=%@ WHERE hw_address=%@",
								uptime,	
								[sqlConnection quoteObject:mangledPw],
								[sqlConnection quoteObject:hw_address]];
						
			[sqlConnection queryString:theQuery];
			[sqlConnection release];
		}
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
    @finally {
        [thePool release];
    }
}
@end



@implementation ORPostRunStateOp
- (void) dealloc
{
	[runModel release];
	[experimentName release];
	[super dealloc];
}

- (void) setRunModel:(ORRunModel*)aRunModel;
{
	runModel = [aRunModel retain];
}

- (void) setExperimentName:(NSString*)anExperiment
{
	[experimentName autorelease];
	experimentName = [anExperiment copy];
}

- (void) main
{
    if([self isCancelled])return;
   NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
		ORSqlConnection* sqlConnection = [[delegate sqlConnection] retain];
		if([sqlConnection isConnected]){
			//get our machine id using our MAC Address
			ORSqlResult* theResult = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
			id row				   = [theResult fetchRowAsDictionary];
			
			//get the entry for our run state using our machine_id
			id machine_id	= [row objectForKey:@"machine_id"];
			if(machine_id){
				theResult		= [sqlConnection queryString:[NSString stringWithFormat:@"SELECT run_id,state,experiment from runs where machine_id = %@",[sqlConnection quoteObject:machine_id]]];
				id ourRunEntry	= [theResult fetchRowAsDictionary];
				id oldExperiment = [ourRunEntry objectForKey:@"experiment"];
				
				//if we have a run entry, update it. Otherwise create it.
				if(ourRunEntry){
					[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE runs SET run=%u, subrun=%d, state=%d  WHERE machine_id=%@",
												[runModel runNumber],
												[runModel subRunNumber],
												[runModel runningState],
												[sqlConnection quoteObject:machine_id]
												]];

				}
				else {
					[sqlConnection queryString:[NSString stringWithFormat:@"INSERT INTO runs (run,subrun,state,machine_id) VALUES (%u,%d,%d,%@)",
												[runModel runNumber],
												[runModel subRunNumber],
												[runModel runningState],
												[sqlConnection quoteObject:machine_id]
												]];
				}
				
				if([runModel runningState] == eRunInProgress){
					[sqlConnection queryString:[NSString stringWithFormat:@"DELETE FROM Histogram1Ds WHERE machine_id=%@",[sqlConnection quoteObject:machine_id]]];
				}
				if( ![oldExperiment isEqual:experimentName]){
					[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE runs SET experiment=%@ WHERE machine_id=%@",
												[sqlConnection quoteObject:experimentName], 
												[sqlConnection quoteObject:machine_id]]];
				}
			}
			[sqlConnection release];
		}
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
    @finally {
        [thePool release];
    }

}
@end

@implementation ORPostRunTimesOp
- (void) dealloc
{
	[runModel release];
	[super dealloc];
}

- (void) setRunModel:(ORRunModel*)aRunModel;
{
	runModel = [aRunModel retain];
}

- (void) main
{
    if([self isCancelled])return;
   NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
		ORSqlConnection* sqlConnection = [[delegate sqlConnection] retain];
		if([sqlConnection isConnected]){
			//get our machine id using our MAC Address
			ORSqlResult* theResult = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
			id row				   = [theResult fetchRowAsDictionary];
			
			//get the entry for our run state using our machine_id
			id machine_id	= [row objectForKey:@"machine_id"];
			if(machine_id){
				theResult		= [sqlConnection queryString:[NSString stringWithFormat:@"SELECT run_id from runs where machine_id = %@",[sqlConnection quoteObject:machine_id]]];
				id ourRunEntry	= [theResult fetchRowAsDictionary];
				
				//if we have a run entry, update it. Otherwise ignore it.
				if(ourRunEntry){
					[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE runs SET startTime=%@,elapsedTime=%d,elapsedSubRunTime=%d,elapsedBetweenSubRunTime=%d,timeToGo=%d  WHERE machine_id=%@",
												[sqlConnection quoteObject:[runModel startTimeAsString]],
												(int)[runModel elapsedRunTime],
												(int)[runModel elapsedSubRunTime],
												(int)[runModel elapsedBetweenSubRunTime],
												(int)[runModel timeToGo],
												[sqlConnection quoteObject:machine_id]
												]];
				}		
			}
			[sqlConnection release];
		}
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
    @finally {
        [thePool release];
    }

}
@end

@implementation ORPostRunOptions
- (void) dealloc
{
	[runModel release];
	[super dealloc];
}

- (void) setRunModel:(ORRunModel*)aRunModel;
{
	runModel = [aRunModel retain];
}

- (void) main
{
    if([self isCancelled])return;
   NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
		ORSqlConnection* sqlConnection = [[delegate sqlConnection] retain];
		if([sqlConnection isConnected]){
			//get our machine id using our MAC Address
			ORSqlResult* theResult = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
			id row				   = [theResult fetchRowAsDictionary];
			
			//get the entry for our run state using our machine_id
			id machine_id	= [row objectForKey:@"machine_id"];
			if(machine_id){
				theResult		= [sqlConnection queryString:[NSString stringWithFormat:@"SELECT run_id from runs where machine_id = %@",[sqlConnection quoteObject:machine_id]]];
				id ourRunEntry	= [theResult fetchRowAsDictionary];
				
				//if we have a run entry, update it. Otherwise ignore it.
				if(ourRunEntry){
					[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE runs SET quickStart=%d,repeatRun=%d,offline=%d,timedRun=%d,timeLimit=%d  WHERE machine_id=%@",
												(int)[runModel quickStart],
												(int)[runModel repeatRun],
												(int)[runModel offlineRun],
												(int)[runModel timedRun],
												(int)[runModel timeLimit],
												[sqlConnection quoteObject:machine_id]
												]];
				}
			}
			[sqlConnection release];
		}
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
    @finally {
        [thePool release];
    }
}
@end

@implementation ORPostStatusLogOp
- (void) dealloc
{
	[statusLog release];
	[super dealloc];
}

- (void) setStatusLog:(NSString*)s;
{
	[statusLog autorelease];
    statusLog = [s copy];
}

- (void) main
{
    if([self isCancelled])return;
   NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
		ORSqlConnection* sqlConnection = [[delegate sqlConnection] retain];
		if([sqlConnection isConnected]){
			//get our machine id using our MAC Address
			ORSqlResult* theResult = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
			id row				   = [theResult fetchRowAsDictionary];
			
			//get the entry for our run state using our machine_id
			id machine_id	= [row objectForKey:@"machine_id"];
			if(machine_id){
				theResult		= [sqlConnection queryString:[NSString stringWithFormat:@"SELECT statuslog_id from statuslog where machine_id = %@",[sqlConnection quoteObject:machine_id]]];
				id ourStatusLogID	= [theResult fetchRowAsDictionary];
				
				//if we have a run entry, update it. Otherwise create an entry
				if(ourStatusLogID){
					[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE statuslog SET statuslog=%@  WHERE machine_id=%@",
												[sqlConnection quoteObject:statusLog],
												[sqlConnection quoteObject:machine_id]
												]];
				}
				else {
					[sqlConnection queryString:[NSString stringWithFormat:@"INSERT INTO statuslog (machine_id,statuslog) VALUES (%@,%@)",
												[sqlConnection quoteObject:machine_id],
												[sqlConnection quoteObject:statusLog]]];
				}
			}
			[sqlConnection release];
		}
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
    @finally {
        [thePool release];
    }
}
@end

@implementation ORPostDataOp
- (void) dealloc
{
	[dataMonitors release];
	[super dealloc];
}

- (void) setDataMonitors:(id)someMonitors
{
	[someMonitors retain];
	[dataMonitors release];
	dataMonitors = someMonitors;
}

- (void) main
{
    if([self isCancelled])return;
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
		ORSqlConnection* sqlConnection = [[delegate sqlConnection] retain];
		if([sqlConnection isConnected]){
			//get our machine_id using our MAC Address
			ORSqlResult* theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
			id row				    = [theResult fetchRowAsDictionary];
			id machine_id			= [row objectForKey:@"machine_id"];		
			if(machine_id){
				//do 1D Histograms first
				for(id aMonitor in dataMonitors){
					NSArray* objs1d = [[aMonitor  collectObjectsOfClass:[OR1DHisto class]] retain];
					@try {
						for(OR1DHisto* aDataSet in objs1d){
							ORSqlResult* theResult	 = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT dataset_id,counts from Histogram1Ds where (machine_id=%@ and name=%@ and monitor_id=%u)",
																				   [sqlConnection quoteObject:machine_id],
																				   [sqlConnection quoteObject:[aDataSet fullName]],
																				   [aMonitor uniqueIdNumber]]];
							id dataSetEntry			 = [theResult fetchRowAsDictionary];
							id dataset_id			 = [dataSetEntry objectForKey:@"dataset_id"];
							uint32_t lastCounts = (uint32_t)[[dataSetEntry objectForKey:@"counts"] longValue];
							uint32_t countsNow  = [aDataSet totalCounts];
							uint32_t start,end;
							if(dataset_id) {
								if(lastCounts != countsNow){
									NSData* theData = [aDataSet getNonZeroRawDataWithStart:&start end:&end];
                                    //also need it as a string for couchdb
                                    int n = (int)[theData length]/4;
                                    NSMutableString* dataStr = [NSMutableString stringWithCapacity:n*64];
                                    uint32_t* dataPtr = (uint32_t*)[theData bytes];
                                    if(dataPtr){
                                        int i;
                                        for(i=0;i<n;i++)[dataStr appendFormat:@"%u,",dataPtr[i]];
                                        if([dataStr length]>0)[dataStr deleteCharactersInRange:NSMakeRange([dataStr length]-1,1)];
                                    }
                                    if([dataStr length]==0)[dataStr appendString: @"0"];
                                    
                                    
									NSString* convertedData = [sqlConnection quoteObject:theData];
									NSString* theQuery = [NSString stringWithFormat:@"UPDATE Histogram1Ds SET counts=%u,start=%u,end=%u,data=%@,datastr=%@ WHERE dataset_id=%@",
														  [aDataSet totalCounts],
														  start,end,
														  convertedData,
														  [sqlConnection quoteObject:dataStr],
														  [sqlConnection quoteObject:dataset_id]];
									[sqlConnection queryString:theQuery];
								}
							}
							else {
								NSData* theData = [aDataSet getNonZeroRawDataWithStart:&start end:&end];
								NSString* convertedData = [sqlConnection quoteObject:theData];
								NSString* dataStr = [aDataSet getnonZeroDataAsStringWithStart:&start end:&end];
								NSString* theQuery = [NSString stringWithFormat:@"INSERT INTO Histogram1Ds (monitor_id,machine_id,name,counts,type,start,end,length,data,datastr) VALUES (%u,%@,%@,%u,1,%u,%u,%d,%@,%@)",
													  [aMonitor uniqueIdNumber],
													  [sqlConnection quoteObject:machine_id],
													  [sqlConnection quoteObject:[aDataSet fullName]],
													  [aDataSet totalCounts],
													  start,end,
													  [aDataSet numberBins],
													  convertedData,
													  [sqlConnection quoteObject:dataStr]];
								[sqlConnection queryString:theQuery];
							}
						}
					}
					@catch(NSException* e){
						@throw;
					}
					@finally {
						[objs1d release];
					}
				}
				//do 2D Histograms
				for(id aMonitor in dataMonitors){
					NSArray* objs1d = [[aMonitor  collectObjectsOfClass:[OR2DHisto class]] retain];
					@try {
						for(id aDataSet in objs1d){
							ORSqlResult* theResult	 = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT dataset_id,counts from Histogram2Ds where (machine_id=%@ and name=%@ and monitor_id=%u)",
																				   [sqlConnection quoteObject:machine_id],
																				   [sqlConnection quoteObject:[aDataSet fullName]],
																				   [aMonitor uniqueIdNumber]]];
							id dataSetEntry			  = [theResult fetchRowAsDictionary];
							id dataset_id			  = [dataSetEntry objectForKey:@"dataset_id"];
							uint32_t lastCounts  = (uint32_t)[[dataSetEntry objectForKey:@"counts"] longValue];
							uint32_t countsNow   = [aDataSet totalCounts];
							uint32_t binsPerSide = [aDataSet numberBinsPerSide];
							unsigned short minX,maxX,minY,maxY;
							[aDataSet getXMin:&minX xMax:&maxX yMin:&minY yMax:&maxY];
							if(dataset_id) {
								if(lastCounts != countsNow){
									NSData* theData = [aDataSet rawData];
									NSString* convertedData = [sqlConnection quoteObject:theData];
									NSString* theQuery = [NSString stringWithFormat:@"UPDATE Histogram2Ds SET counts=%u,data=%@ WHERE dataset_id=%@",
														  [aDataSet totalCounts],
														  convertedData,
														  [sqlConnection quoteObject:dataset_id]];
									[sqlConnection queryString:theQuery];
								}
							}
							else {
								NSData* theData = [aDataSet rawData];
								NSString* convertedData = [sqlConnection quoteObject:theData];
								NSString* theQuery = [NSString stringWithFormat:@"INSERT INTO Histogram2Ds (monitor_id,machine_id,name,counts,type,binsperside,minX,maxX,minY,maxY,length,data) VALUES (%u,%@,%@,%u,2,%u,%d,%d,%d,%d,%d,%@)",
													  [aMonitor uniqueIdNumber],
													  [sqlConnection quoteObject:machine_id],
													  [sqlConnection quoteObject:[aDataSet fullName]],
													  [aDataSet totalCounts],
													  binsPerSide,
													  minX,maxX,minY,maxY,
													  (int)[aDataSet numberBins],
													  convertedData];
								[sqlConnection queryString:theQuery];
							}
						}
					}
					@catch(NSException* e){
						@throw;
					}
					@finally {
						[objs1d release];
					}
	
				}
				//do waveforms
				for(id aMonitor in dataMonitors){
					NSArray* objsWaveform = [[aMonitor  collectObjectsOfClass:[ORWaveform class]] retain];
					@try {
						for(ORWaveform* aDataSet in objsWaveform){
							ORSqlResult* theResult	 = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT dataset_id,counts from waveforms where (machine_id=%@ and name=%@ and monitor_id=%u)",
																				   [sqlConnection quoteObject:machine_id],
																				   [sqlConnection quoteObject:[aDataSet fullName]],
																				   [aMonitor uniqueIdNumber]]];
							id dataSetEntry			 = [theResult fetchRowAsDictionary];
							id dataset_id			 = [dataSetEntry objectForKey:@"dataset_id"];
							uint32_t lastCounts = (uint32_t)[[dataSetEntry objectForKey:@"counts"] longValue];
							uint32_t countsNow  = [aDataSet totalCounts];
							if(dataset_id) {
								if(lastCounts != countsNow){
									NSString* convertedData = [sqlConnection quoteObject:[aDataSet rawData]];
									NSString* theQuery = [NSString stringWithFormat:@"UPDATE waveforms SET counts=%u,unitsize=%d,mask=%u,bitmask=%u,offset=%u,length=%d,data=%@ WHERE dataset_id=%@",
														  [aDataSet totalCounts],
														  [aDataSet unitSize],
														  [aDataSet mask],
														  [aDataSet specialBitMask],
														  [aDataSet dataOffset],
														  (int)[aDataSet numberBins],
														  convertedData,
														  [sqlConnection quoteObject:dataset_id]];
									[sqlConnection queryString:theQuery];
								}
							}
							else {
								NSString* convertedData = [sqlConnection quoteObject:[aDataSet rawData]];
								NSString* theQuery = [NSString stringWithFormat:@"INSERT INTO waveforms (monitor_id,machine_id,name,counts,unitsize,mask,bitmask,offset,type,length,data) VALUES (%u,%@,%@,%u,%d,%u,%u,%u,3,%d,%@)",
													  [aMonitor uniqueIdNumber],
													  [sqlConnection quoteObject:machine_id],
													  [sqlConnection quoteObject:[aDataSet fullName]],
													  [aDataSet totalCounts],
													  [aDataSet unitSize],
													  [aDataSet mask],
													  [aDataSet specialBitMask],
													  [aDataSet dataOffset],
													  (int)[aDataSet numberBins],
													  convertedData];
								[sqlConnection queryString:theQuery];
							}
						}
					}
					@catch(NSException* e){
						@throw;
					}
					@finally {
						[objsWaveform release];
					}
					
				}
			}
			[sqlConnection release];
		}
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
    @finally {
        [thePool release];
    }
}
@end

@implementation ORPostExperimentOp
- (void) dealloc
{
	[experiment release];
	[super dealloc];
}

- (void) setExperiment:(id)anExperiment
{
	[anExperiment retain];
	[experiment release];
	experiment = anExperiment;
}

- (void) main
{
    if([self isCancelled])return;
   NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
		ORSqlConnection* sqlConnection = [[delegate sqlConnection] retain];
		if([sqlConnection isConnected]){
			if([experiment isKindOfClass:NSClassFromString(@"ORExperimentModel")]) {
				NSString* experimentName = [experiment className];
				if([experimentName hasPrefix:@"OR"])    experimentName = [experimentName substringFromIndex:2];
				if([experimentName hasSuffix:@"Model"]) experimentName = [experimentName substringToIndex:[experimentName length] - 5];

				//get our machine_id using our MAC Address
				ORSqlResult* theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
				id row				    = [theResult fetchRowAsDictionary];
				id machine_id			= [row objectForKey:@"machine_id"];
				if(machine_id){
					theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT experiment_id from experiment where (machine_id = %@ and experiment = %@)",[sqlConnection quoteObject:machine_id],[sqlConnection quoteObject:experimentName]]];
					row				    = [theResult fetchRowAsDictionary];
					id experiment_id		= [row objectForKey:@"experiment_id"];

				
					//if we have a run entry, update it. Otherwise create it.
					if(experiment_id){
						[sqlConnection queryString:[NSString stringWithFormat:@"UPDATE experiment SET thresholds=%@,gains=%@,totalCounts=%@,rates=%@,thresholdsstr=%@,gainsstr=%@,totalCountsstr=%@,ratesstr=%@ WHERE machine_id=%@",
													[sqlConnection quoteObject:[experiment thresholdDataForSet:0]],
													[sqlConnection quoteObject:[experiment gainDataForSet:0]],
													[sqlConnection quoteObject:[experiment totalCountDataForSet:0]],
													[sqlConnection quoteObject:[experiment rateDataForSet:0]],
													[sqlConnection quoteObject:[experiment thresholdDataAsStringForSet:0]],
													[sqlConnection quoteObject:[experiment gainDataAsStringForSet:0]],
													[sqlConnection quoteObject:[experiment totalCountDataAsStringForSet:0]],
													[sqlConnection quoteObject:[experiment rateDataAsStringForSet:0]],
													[sqlConnection quoteObject:machine_id]]];
					}
					else  {
						int numberSegments = [experiment maxNumSegments];
						[sqlConnection queryString:[NSString stringWithFormat:@"INSERT INTO experiment (machine_id,experiment,numberSegments,thresholds,gains,totalCounts,rates,thresholdsstr,gainsstr,totalCountsstr,ratesstr) VALUES (%@,%@,%d,%@,%@,%@,%@,%@,%@,%@,%@)",
													[sqlConnection quoteObject:machine_id],
													[sqlConnection quoteObject:experimentName],
													numberSegments,
													[sqlConnection quoteObject:[experiment thresholdDataForSet:0]],
													[sqlConnection quoteObject:[experiment gainDataForSet:0]],
													[sqlConnection quoteObject:[experiment totalCountDataForSet:0]],
													[sqlConnection quoteObject:[experiment rateDataForSet:0]],
													[sqlConnection quoteObject:[experiment thresholdDataAsStringForSet:0]],
													[sqlConnection quoteObject:[experiment gainDataAsStringForSet:0]],
													[sqlConnection quoteObject:[experiment totalCountDataAsStringForSet:0]],
													[sqlConnection quoteObject:[experiment rateDataAsStringForSet:0]]]];
					}
				}
			}
			[sqlConnection release];
		}
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
    @finally {
        [thePool release];
    }
}
@end

@implementation ORPostAlarmOp
- (void) dealloc
{
	[alarm release];
	[super dealloc];
}

- (void) postAlarm:(id)anAlarm
{
	[anAlarm retain];
	[alarm release];
	alarm = anAlarm;
	opType = kPost;
}

- (void) clearAlarm:(id)anAlarm
{
	[anAlarm retain];
	[alarm release];
	alarm = anAlarm;
	opType = kClear;
}

- (void) main
{
    if([self isCancelled])return;
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
		ORSqlConnection* sqlConnection = [[delegate sqlConnection] retain];
		if([sqlConnection isConnected]){
			//get our machine_id using our MAC Address
			ORSqlResult* theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
			id row				    = [theResult fetchRowAsDictionary];
			id machine_id			= [row objectForKey:@"machine_id"];
			
			if(machine_id){
				if(opType == kPost){
					theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT alarm_id from alarms where (machine_id = %@ and name = %@)",[sqlConnection quoteObject:machine_id],[sqlConnection quoteObject:[alarm name]]]];
					row				= [theResult fetchRowAsDictionary];
					id alarm_id		= [row objectForKey:@"alarm_id"];
					if(!alarm_id){
						[sqlConnection queryString:[NSString stringWithFormat:@"INSERT INTO alarms (machine_id,timePosted,severity,name,help) VALUES (%@,%@,%d,%@,%@)",
													[sqlConnection quoteObject:machine_id],
													[sqlConnection quoteObject:[alarm timePosted]],
													[alarm severity],
													[sqlConnection quoteObject:[alarm name]],
													[sqlConnection quoteObject:[alarm helpString]]]];
					}
				}
				else {
					[sqlConnection queryString:[NSString stringWithFormat:@"DELETE FROM alarms where (machine_id=%@ AND name=%@)",
												[sqlConnection quoteObject:machine_id],
												[sqlConnection quoteObject:[alarm name]]]];
				}
			}		
			[sqlConnection release];
		}
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
    @finally {
        [thePool release];
    }
}
@end

@implementation ORPostSegmentMapOp
- (void) dealloc
{
	[super dealloc];
}

- (void) setDataMonitorId:(int)anID
{
	monitor_id = anID;
}

- (void) main
{
    if([self isCancelled])return;
   NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
    ORExperimentModel* experiment = (ORExperimentModel*)[[delegate nextObject] retain];
    @try {			
        ORSqlConnection* sqlConnection = [[delegate sqlConnection] retain];
        if([sqlConnection isConnected]){
            //get our machine_id using our MAC Address
            ORSqlResult* theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
            id row				    = [theResult fetchRowAsDictionary];
            id machine_id			= [row objectForKey:@"machine_id"];
            
            if(machine_id){
                //since we only update this map on demand (i.e. if it changes) we'll just delete and start over
                [sqlConnection queryString:[NSString stringWithFormat:@"DELETE FROM segmentMap where machine_id=%@",
                                            [sqlConnection quoteObject:machine_id]]];
                
                ORSegmentGroup* theGroup = [experiment segmentGroup:0];
                NSArray* segments = [theGroup segments];
                int segmentNumber = 0;
                for(id aSegment in segments){
                    NSString* crateName		= [aSegment objectForKey:@"kCrate"];
                    NSString* cardName		= [aSegment objectForKey:@"kCardSlot"];
                    NSString* chanName		= [aSegment objectForKey:@"kChannel"];
                    NSString* dataSetName   = [experiment dataSetNameGroup:0 segment:segmentNumber];
                    [sqlConnection queryString:[NSString stringWithFormat:@"INSERT INTO segmentMap (machine_id,monitor_id,segment,histogram1DName,crate,card,channel) VALUES (%@,%d,%d,%@,%@,%@,%@)",
                                                [sqlConnection quoteObject:machine_id],
                                                monitor_id,
                                                segmentNumber,
                                                [sqlConnection quoteObject:dataSetName],
                                                [sqlConnection quoteObject:crateName],
                                                [sqlConnection quoteObject:cardName],
                                                [sqlConnection quoteObject:chanName]]];
                    segmentNumber++;
                }
            }	
            [sqlConnection release];
        }
    }
    @catch(NSException* e){
        [delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
    }
    @finally {
        [experiment release];
        [thePool release];
    }
    
}
@end

@implementation ORProcessDataOp
- (void) dealloc
{
	[processes release];
	[super dealloc];
}

- (void) setProcesses:(id)someProcesses
{
	[someProcesses retain];
	[processes release];
	processes = someProcesses;
}

- (void) main
{
    if([self isCancelled])return;
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
    @try {
        //get our machine_id using our MAC Address
        ORSqlConnection* sqlConnection = [[delegate sqlConnection] retain];
        if([sqlConnection isConnected]){		ORSqlResult* theResult  = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT machine_id from machines where hw_address = %@",[sqlConnection quoteObject:macAddress()]]];
            id row			= [theResult fetchRowAsDictionary];
            id machine_id	= [row objectForKey:@"machine_id"];
            if(machine_id) {
                //collect the existing DB entries for a sweep of deleted objects
                theResult				= [sqlConnection queryString:[NSString stringWithFormat:@"SELECT name from Processes where machine_id=%@",machine_id]];	
                NSMutableArray* allEntries = [NSMutableArray array];
                id anEntry;
                while((anEntry = [theResult fetchRowAsDictionary]))[allEntries addObject:anEntry];

                //do 1D Histograms first
                for(id aProcess in processes){
                    @synchronized(aProcess){

                        ORSqlResult* theResult	 = [sqlConnection queryString:[NSString stringWithFormat:@"SELECT process_id from Processes where (machine_id=%@ and name=%@)",
                                                                               machine_id,
                                                                               [sqlConnection quoteObject:[aProcess fullID]]
                                                                               ]];
                        id anEntry			= [theResult fetchRowAsDictionary];
                        id process_id		= [anEntry objectForKey:@"process_id"];
                        if(process_id) {
                            //already exists... just update
                            NSString* theQuery = [NSString stringWithFormat:@"UPDATE Processes SET name=%@,title=%@,timeStamp=%@,data=%@,state=%d WHERE process_id=%@",
                                                  [sqlConnection quoteObject:[aProcess fullID]],
                                                  [sqlConnection quoteObject:[aProcess shortName]],
                                                  [sqlConnection quoteObject:[aProcess lastSampleTime]],
                                                  [sqlConnection quoteObject:[aProcess report]],
                                                  [aProcess processRunning],
                                                  [sqlConnection quoteObject:process_id]];
                            [sqlConnection queryString:theQuery];
                        }
                        else {
                            //have to add a new entry
                            NSString* theQuery = [NSString stringWithFormat:@"INSERT INTO Processes (machine_id,name,title,timeStamp,data,state) VALUES (%@,%@,%@,%@,%@,%d)",
                                                  [sqlConnection quoteObject:machine_id],
                                                  [sqlConnection quoteObject:[aProcess fullID]],
                                                  [sqlConnection quoteObject:[aProcess shortName]],
                                                  [sqlConnection quoteObject:[aProcess lastSampleTime]],
                                                  [sqlConnection quoteObject:[aProcess report]],
                                                  [aProcess processRunning]];
                            [sqlConnection queryString:theQuery];
                        }
                        for(id anEntry in allEntries){
                            NSString* aName = [anEntry objectForKey:@"name"];
                            if([aName isEqualToString:[aProcess fullID]]){
                                [allEntries removeObject:anEntry];
                                break;
                            }
                        }
                    }
                }
                //clean out any deleted items
                for(id anEntry in allEntries){
                    NSString* aName = [anEntry objectForKey:@"name"];
                    [sqlConnection queryString:[NSString stringWithFormat:@"DELETE FROM Processes where (machine_id=%@ AND name=%@)",
                                                [sqlConnection quoteObject:machine_id],
                                                [sqlConnection quoteObject:aName]]];
                }
            }
            [sqlConnection release];
        }
        
    }
    @catch(NSException* e){
        [delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
    }
    @finally {
        [thePool release];
    }

}
@end




