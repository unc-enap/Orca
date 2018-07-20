//
//  ORSNMP.h
//  Orca
//
//  Created by Mark Howe on Tues Jan 11,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#include <net-snmp/net-snmp-config.h>
#include <net-snmp/net-snmp-includes.h>

@interface ORSNMP : NSObject {
	struct snmp_session session; 
	struct snmp_session* sessionHandle;
	NSString* mibName;
}
- (id) initWithMib:(NSString*)aMibName;
- (void) dealloc;
- (void) openGuruSession:(NSString*)ip;  
- (void) openPublicSession:(NSString*)ip;  
- (void) openSession:(NSString*)ip community:(NSString*)aCommunity;
- (NSArray*) readValue:(NSString*)anObjId;
- (NSArray*) readValues:(NSArray*)someObjIds;
- (NSArray*) writeValue:(NSString*)anObjId;
- (NSArray*) writeValues:(NSArray*)someObjIds;
- (void) closeSession;

- (void) topLevelParse:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary;
- (void) parseParmAndMibName:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary;
- (void) parseParameterName:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary;
- (void) parseParamTypeAndValue:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary;
- (void) parseParamValue:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary;
- (void) parseNumberWithUnits:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary;
- (uint32_t) convertBitString:(NSString*)s;

@end


//a thin wrapper around NSOperationQueue to make a shared queue for SNMP access
@interface ORSNMPQueue : NSObject {
    NSOperationQueue* queue;
}
+ (ORSNMPQueue*) sharedSNMPQueue;
+ (void) addOperation:(NSOperation*)anOp;
+ (NSOperationQueue*) queue;
+ (NSUInteger) operationCount;
- (void) addOperation:(NSOperation*)anOp;
- (NSOperationQueue*) queue;
- (NSInteger) operationCount;
@end

@interface ORSNMPOperation : NSOperation
{
	NSString*	mib;
	NSString*	ipNumber;
	BOOL		verbose;
	SEL			selector;
	id			delegate;
	id			target;
	NSArray*	cmds;
}

- (id)	 initWithDelegate:(id)aDelegate;
- (void) dealloc;
- (void) main;
@property (nonatomic,copy)		NSString*	mib;
@property (nonatomic,copy)		NSString*	ipNumber;
@property (nonatomic,retain)	NSArray*	cmds;
@property (nonatomic,retain)	id			target;
@property (nonatomic,assign)	SEL			selector;
@property (nonatomic,assign)	BOOL		verbose;
@end

@interface ORSNMPWriteOperation : ORSNMPOperation
- (void) main;
@end

@interface ORSNMPReadOperation : ORSNMPOperation
- (void) main;
@end

@interface ORSNMPCallBackOperation : ORSNMPOperation
{
	id			userInfo;
}
- (void) main;
@property (nonatomic,retain)	id			userInfo;
@end

//--------------------------------------------------
// ORSNMPShellOp
// An easier way to use SNMP by just executing shell
// scripts and having the result go back to the delegate
//--------------------------------------------------
@interface ORSNMPShellOp : NSOperation
{
	id          delegate;
    int         tag;
    NSString*   command;
    NSArray*    arguments;
}
- (id) initWithCmd:(NSString*)aCmd arguments:(NSArray*)theArgs delegate:(id)aDelegate tag:(int)aTag;
- (void) main;
@end

@interface NSObject (ORSNMPShellOp)
- (void) setSNMP:(int)aTag result:(NSString*)theResult;
@end;

