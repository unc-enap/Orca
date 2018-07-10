//-------------------------------------------------------------------------
//  ORCouchDBListenerModel.h
//
//  Created by Thomas Stolz on 05/20/13.
//  Copyright (c) 2006 CENPA, University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
@class ORScriptRunner;
@class ORCouchDB;

@interface ORCouchDBListenerModel : OrcaObject {
    
    //Message Section
    NSMutableString* statusLogString;
    
    //CouchDB Configuration
    NSString* hostName;
    NSUInteger portNumber;
    NSString* databaseName;
    NSString* userName;
    NSString* password;
    NSOperation* runningChangesfeed;
    NSArray* databaseList;
    NSUInteger heartbeat;
    
    //Script Section
    BOOL scriptSectionReady;
    NSString* scriptDocName;
    NSString* commandDoc;
    ORScriptRunner* scriptRunner;
    NSString* script;
    
    //Command Section
    BOOL cmdSectionReady;
    NSString* cmdDocName;
    NSArray* objectList;
    NSMutableArray* cmdTableArray;
    BOOL commonMethodsOnly;
    NSMutableDictionary* cmdDict;
    BOOL listenOnStart;
    BOOL saveHeartbeatsWhileListening;
    
    NSString* updatePath;
    
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

#pragma mark ***Notifications
- (void) registerNotificationObservers;

#pragma mark ***Accessors

//Message Section
- (NSString*) statusLog;
- (void) setStatusLog:(NSString*)log;
- (void) appendStatusLog:(NSString *)log;
- (void) log:(NSString*)message;

//CouchDb Config
- (void) setDatabaseName:(NSString*)name;
- (void) setHostName:(NSString*)name;
- (void) setPortNumber:(NSUInteger)aPort;
- (void) setUserName:(NSString*)name;
- (void) setPassword:(NSString*)pwd;
- (void) setUpdatePath:(NSString*)aPath;
- (NSArray*) databaseList;
- (NSString*) database;
- (NSUInteger) heartbeat;
- (NSString*) hostName;
- (NSUInteger) portNumber;
- (NSString*) userName;
- (NSString*) password;
- (NSString*) updatePath;
- (BOOL) isListening;
- (void) setHeartbeat:(NSUInteger)beat;
- (void) setSaveHeartbeatsWhileListening:(BOOL)save;
- (BOOL) saveHeartbeatsWhileListening;


//Command Section
- (void) setCommonMethods:(BOOL)only;
- (NSArray*) objectList;
- (NSArray*) getMethodListForObjectID:(NSString*)objID;
- (BOOL) commonMethodsOnly;
- (NSDictionary*) cmdDict;
- (BOOL) listenOnStart;
- (void) setListenOnStart:(BOOL)alist;

#pragma mark ***DB Access
- (void) startStopSession;
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp;
- (void) listDatabases;
- (void) sectionReady;

#pragma mark ***Command Section
- (void) updateObjectList;
- (BOOL) executeCommand:(NSString*)key arguments:(NSArray*)val returnVal:(id*)retVal;
- (void) setCommands:(NSMutableArray*)anArray;
- (void) setDefaults;
- (NSDictionary*) commandAtIndex:(int)index;
- (NSUInteger) commandCount;
- (void) addCommand:(NSString*)obj label:(NSString*)lab selector:(NSString*)sel info:(NSString*)info value:(NSString*)val;
- (void) removeCommand:(int)index;
//DB Interaction

#pragma mark ***Script Section
- (BOOL) runScript:(NSString*) aScript;
- (void) scriptRunnerDidFinish:(BOOL)finished returnValue:(NSNumber*)val;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORCouchDBListenerModelDatabaseListChanged;
extern NSString* ORCouchDBListenerModelListeningChanged;
extern NSString* ORCouchDBListenerModelObjectListChanged;
extern NSString* ORCouchDBListenerModelCommandsChanged;
extern NSString* ORCouchDBListenerModelStatusLogChanged;
extern NSString* ORCouchDBListenerModelStatusLogAppended;
extern NSString* ORCouchDBListenerModelHostChanged;
extern NSString* ORCouchDBListenerModelPortChanged;
extern NSString* ORCouchDBListenerModelDatabaseChanged;
extern NSString* ORCouchDBListenerModelUsernameChanged;
extern NSString* ORCouchDBListenerModelPasswordChanged;
extern NSString* ORCouchDBListenerModelListeningStatusChanged;
extern NSString* ORCouchDBListenerModelHeartbeatChanged;
extern NSString* ORCouchDBListenerModelUpdatePathChanged;
extern NSString* ORCouchDBListenerModelListenOnStartChanged;
extern NSString* ORCouchDBListenerModelSaveHeartbeatsWhileListeningChanged;