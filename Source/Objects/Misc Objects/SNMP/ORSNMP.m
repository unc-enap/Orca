//
//  ORSNMP.m
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

#import "ORSNMP.h"
#import "NSString+Extensions.h"
#import "SynthesizeSingleton.h"

@implementation ORSNMP
- (id) initWithMib:(NSString*)aMibName
{
	self = [super init];
	mibName = [aMibName copy];
	return self;
}

- (void) dealloc
{
	[self closeSession];
	[mibName release];
	[super dealloc];
}

- (void) openGuruSession:(NSString*)ip  
{
	[self openSession:ip community:@"guru"];
}

- (void) openPublicSession:(NSString*)ip  
{
	[self openSession:ip community:@"public"];
}

- (void) openSession:(NSString*)ip community:(NSString*)aCommunity
{
	@synchronized(self){
		if(!sessionHandle){
			init_snmp("APC Check");
			snmp_sess_init(&session);
			session.version			= SNMP_VERSION_1;
			session.community		= (unsigned char*)[aCommunity cStringUsingEncoding:NSASCIIStringEncoding];
			session.community_len	= strlen((const char *)session.community);
			session.peername		= (char*)[ip cStringUsingEncoding:NSASCIIStringEncoding];
			sessionHandle			= snmp_open(&session);
		}
	}
}

- (NSArray*) readValue:(NSString*)anObjId
{
	NSArray* result;
	@synchronized(self){
		result =  [self readValues:[NSArray arrayWithObject:anObjId]];
	}
	return result;
}

- (NSArray*) readValues:(NSArray*)someObjIds
{
	NSMutableArray* resultArray = [NSMutableArray array];
	@synchronized(self){
		if(sessionHandle){

			size_t id_len = MAX_OID_LEN;
			oid id_oid[MAX_OID_LEN];
			
			for(id anObjID in someObjIds){
				anObjID = [mibName stringByAppendingFormat:@"::%@",anObjID];
				struct snmp_pdu* pdu = snmp_pdu_create(SNMP_MSG_GET);
				const char* obj_id = [anObjID cStringUsingEncoding:NSASCIIStringEncoding];
				read_objid(obj_id, id_oid, &id_len);
				snmp_add_null_var(pdu, id_oid, id_len);
				NSMutableDictionary* responseDictionary = [NSMutableDictionary dictionary];
				struct snmp_pdu* response;
				int status = snmp_synch_response(sessionHandle, pdu, &response);
				if(status == STAT_SUCCESS){
					if (response->errstat == SNMP_ERR_NOERROR){
						struct variable_list* vars;   
						for(vars = response->variables; vars; vars = vars->next_variable){
							char buf[1024];
							snprint_variable(buf, sizeof(buf), vars->name, vars->name_length,vars);
							NSString* s = [NSString stringWithUTF8String:buf];
							[self topLevelParse:s intoDictionary:responseDictionary];
						}
					}
					else {
						[responseDictionary setObject:[NSString stringWithFormat:@"Error in packet.\nReason: %s\n",snmp_errstring((int)response->errstat)] forKey:@"Error"];
						[resultArray addObject:responseDictionary];
						break;
					}
				}
				else if (status == STAT_TIMEOUT){
					[responseDictionary setObject:[NSString stringWithFormat:@"SNMP Timeout: No Response from %s\n",sessionHandle->peername] forKey:@"Error"];
					[resultArray addObject:responseDictionary];
					break;
				}
				else {
					[responseDictionary setObject:@"SNMP response error" forKey:@"Error"];
					[resultArray addObject:responseDictionary];
					break;
				}
				
				if(responseDictionary)[resultArray addObject:responseDictionary];
				
				if (response)snmp_free_pdu(response);				
			}
		}
	}
	return resultArray;
}

- (NSArray*) writeValue:(NSString*)anObjId
{
	NSArray* result;
	@synchronized(self){
		result =  [self writeValues:[NSArray arrayWithObject:anObjId]];
	}
	return result;
}

- (NSArray*) writeValues:(NSArray*)someObjIds
{
	NSMutableArray* resultArray = [NSMutableArray array];
	@synchronized(self){
		//the objID must have the form param.i t val
		//example: outputSwitch.u7 i 1
		if (sessionHandle){
			struct snmp_pdu* response = nil;
					
			oid    anOID[MAX_OID_LEN];
			size_t anOID_len = MAX_OID_LEN;
			
			for(id anObjID in someObjIds){
				NSMutableDictionary* responseDictionary = [NSMutableDictionary dictionary];
				anObjID = [mibName stringByAppendingFormat:@"::%@",anObjID];
				struct snmp_pdu* pdu = snmp_pdu_create(SNMP_MSG_SET);
				NSArray* parts = [anObjID tokensSeparatedByCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]];
				if([parts count] == 3){
					const char* intoid = [[parts objectAtIndex:0] cStringUsingEncoding:NSASCIIStringEncoding];
					const char type    = [[parts objectAtIndex:1] characterAtIndex:0];
					const char* val    = [[parts objectAtIndex:2] cStringUsingEncoding:NSASCIIStringEncoding];

					if (snmp_parse_oid(intoid, anOID, &anOID_len) == NULL){
						[responseDictionary setObject:@"snmp_parse_oid reports bad parameter" forKey:@"Error"];
						[resultArray addObject:responseDictionary];
						break;
					}
					if (snmp_add_var(pdu, anOID, anOID_len, type, val)){
						[responseDictionary setObject:@"snmp_add_var reports error" forKey:@"Error"];
						[resultArray addObject:responseDictionary];
						break;
					}
					
					int status = snmp_synch_response(sessionHandle, pdu, &response);
					
					if (status == STAT_SUCCESS){
						if (response->errstat != SNMP_ERR_NOERROR){
							[responseDictionary setObject:[NSString stringWithFormat:@"Error in packet: %s",snmp_errstring((int)response->errstat)] forKey:@"Error"];
							[resultArray addObject:responseDictionary];
							break;
						}
					}
					else if (status == STAT_TIMEOUT){
						[responseDictionary setObject:[NSString stringWithFormat:@"SNMP Timeout: No Response from %s\n",sessionHandle->peername] forKey:@"Error"];
						[resultArray addObject:responseDictionary];
						break;
					}
					else {
						[responseDictionary setObject:@"SNMP response error" forKey:@"Error"];
						[resultArray addObject:responseDictionary];
						break;
					}
				}
				if(responseDictionary)[resultArray addObject:responseDictionary];
				if (response)snmp_free_pdu(response);				
			}
		}
	}
	return resultArray;
}	

- (void) closeSession
{
	if(sessionHandle) {
		@synchronized(self){
			snmp_close(sessionHandle);
			sessionHandle = nil;
		}
	}	
}

- (void) topLevelParse:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary
{
	//split out the name from the value part
	NSArray* parts = [s componentsSeparatedByString:@"="];
	if([parts count] == 2){
		[self parseParmAndMibName:[parts objectAtIndex:0] intoDictionary:aDictionary];
		NSString* valuePart = [[parts objectAtIndex:1] stringByReplacingOccurrencesOfString:@"Opaque:" withString:@""];
		[self parseParamTypeAndValue:valuePart intoDictionary:aDictionary];
	}
	else [aDictionary removeAllObjects];
}

- (void) parseParmAndMibName:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary
{
	NSArray* parts = [s componentsSeparatedByString:@"::"];
	if([parts count] == 2) {
		[aDictionary setObject:  [[parts objectAtIndex:0] trimSpacesFromEnds] forKey:@"Mib"];
		[self parseParameterName: [parts objectAtIndex:1] intoDictionary:aDictionary];
	}
	else [aDictionary removeAllObjects];
}

- (void) parseParameterName:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary
{
	//Example: "outputCurrentRiseRate.u0"
	NSArray* parts = [s componentsSeparatedByString:@"."];
	if([parts count] == 2) {
		[aDictionary setObject:[[parts objectAtIndex:0] trimSpacesFromEnds]  forKey:@"Name"];
		NSString* partAfterDot = [[parts objectAtIndex:1] trimSpacesFromEnds];
		if([partAfterDot hasPrefix:@"u"]){
			int value     = [[partAfterDot substringFromIndex:1] intValue];
			[aDictionary setObject:[NSNumber numberWithInt:(value / 100)+1]  forKey:@"Slot"];
			[aDictionary setObject:[NSNumber numberWithInt:value % 100]      forKey:@"Channel"];
		}
		else {
			int value     = [[partAfterDot substringFromIndex:1] intValue];
			[aDictionary setObject:[NSNumber numberWithInt:value]  forKey:@"SystemIndex"];
		}
	}
	else [aDictionary removeAllObjects];

}
- (void) parseParamTypeAndValue:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary
{
	NSArray* parts = [s componentsSeparatedByString:@":"];
	if([parts count] == 2) {
		[aDictionary setObject:[[parts objectAtIndex:0] trimSpacesFromEnds] forKey:@"Type"];
		[self parseParamValue:[parts objectAtIndex:1] intoDictionary:aDictionary];
	}
	else [aDictionary removeAllObjects];
}

- (void) parseParamValue:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary
{
	NSString* type = [aDictionary objectForKey:@"Type"];
	s = [s trimSpacesFromEnds];
	if([type isEqualToString:@"STRING"]) {
		NSString* result = [s stringByReplacingOccurrencesOfString:@"\"" withString:@""];
		if([result length])[aDictionary setObject:result forKey:@"Value"];
	}
	else if([type isEqualToString:@"BITS"]){
		//Example: "BITS: 80 04 outputOn(0) outputEnableKill(13)"
		//NOTE: *****the order is from left to right, i.e. bit 0 is the left most bit in the string
		NSArray* parts = [s componentsSeparatedByString:@" "];
		NSString* theValue = @"";
		NSMutableArray* onBitNames = [NSMutableArray array];
		for(id aPart in parts){
			if([aPart rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == 0){
				theValue = [theValue stringByAppendingString:aPart];
			}
			else {
				NSRange rangeOfParen = [aPart rangeOfString:@"("];
				if(rangeOfParen.location != NSNotFound) [onBitNames addObject:[aPart substringToIndex:rangeOfParen.location]];
				else [onBitNames addObject:aPart];
			}
		}
		if([theValue length]){			
			[aDictionary setObject:[NSNumber numberWithUnsignedLong:[self convertBitString:theValue]] forKey:@"Value"];
			if([onBitNames count])[aDictionary setObject:onBitNames forKey:@"OnBits"];
		}
	}
	else if([type isEqualToString:@"INTEGER"]){
		[self parseNumberWithUnits:s intoDictionary:aDictionary];
	}
	else if([type isEqualToString:@"Float"]){
		[self parseNumberWithUnits:s intoDictionary:aDictionary];
	}
	else if([type isEqualToString:@"Hex-STRING"]){
		[aDictionary setObject:s forKey:@"Value"];
	}
	else if([type isEqualToString:@"IpAddress"]){
		[aDictionary setObject:s forKey:@"Value"];
	}
	
	else [aDictionary removeAllObjects];
}

- (void) parseNumberWithUnits:(NSString*)s intoDictionary:(NSMutableDictionary*)aDictionary
{
	//Example: "1600 RPM"     --has units
	//Example: "64"  --no units
	//Example: "xxxx(100)  -no units but has a string prefix
	NSArray* parts = [s componentsSeparatedByString:@" "];
	if([parts count] == 2){
		[aDictionary setObject:[NSNumber numberWithFloat:[s floatValue]] forKey:@"Value"];
		[aDictionary setObject:[parts objectAtIndex:1] forKey:@"Units"];
	}
	else {
		NSArray* parts = [s componentsSeparatedByString:@"("];
		if([parts count] == 2){
			[aDictionary setObject:[NSNumber numberWithFloat:[[parts objectAtIndex:1] floatValue]] forKey:@"Value"];
		}
		else [aDictionary setObject:[NSNumber numberWithFloat:[s floatValue]] forKey:@"Value"];
	}
}
- (uint32_t) convertBitString:(NSString*)s
{
	uint32_t finalReversedValue = 0;
	NSUInteger n = [s length];
	NSInteger i;
	for(i=n-1 ; i>=0 ; i--){
		NSScanner* scanner = [NSScanner scannerWithString:[s substringWithRange:NSMakeRange(i,1)]];
		unsigned unreversedHexByte;
		[scanner scanHexInt:&unreversedHexByte];
		int j;
		//flip the bits
		uint32_t reversedHexByte = 0;
		for(j=0;j<4;j++){
			if(unreversedHexByte & 0x1) reversedHexByte |= (0x8>>j);
			unreversedHexByte >>= 1;
		}
		finalReversedValue += reversedHexByte << (i*4);
	}
	return finalReversedValue;
}
@end

//-----------------------------------------------------------
//ORSqlQueue: A shared queue for SNMP access. You should 
//never have to use this object directly. It will be created
//on demand when a SNMP op is called.
//-----------------------------------------------------------
@implementation ORSNMPQueue
SYNTHESIZE_SINGLETON_FOR_ORCLASS(SNMPQueue);
+ (NSOperationQueue*) queue				 { return [[ORSNMPQueue sharedSNMPQueue] queue]; }
+ (void) addOperation:(NSOperation*)anOp { return [[ORSNMPQueue sharedSNMPQueue] addOperation:anOp]; }
+ (NSUInteger) operationCount			 { return 	[[ORSNMPQueue sharedSNMPQueue] operationCount]; }

//don't call this unless you're using this class in a special, non-global way.
- (id) init
{
	self = [super init];
	queue = [[NSOperationQueue alloc] init];
	[queue setMaxConcurrentOperationCount:1];
    return self;
}

- (NSOperationQueue*) queue					{ return queue; }
- (void) addOperation:(NSOperation*)anOp	{ [queue addOperation:anOp]; }
- (NSInteger) operationCount				{ return [[queue operations]count]; }

@end

//-----------------------------------------------------------
// Generic SNMP Operation. Does nothing. Subclasses to actual work
//-----------------------------------------------------------
@implementation ORSNMPOperation

@synthesize cmds,selector,ipNumber,mib,target,verbose;

- (id)	 initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
	return self;
}

- (void) dealloc
{
	self.target		= nil;
	self.ipNumber	= nil;
	self.mib		= nil;
	self.cmds		= nil;
	[super dealloc];
}

- (void) main
{
	//do nothing... subclasses must override to get anything done.
}
@end

//-----------------------------------------------------------
// An SNMP Write OP
//-----------------------------------------------------------
@implementation ORSNMPWriteOperation
- (void) main
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    if([self isCancelled]){
        [pool release];
        return;
    }
	
	ORSNMP* ss = [[ORSNMP alloc] initWithMib:mib];
	[ss openGuruSession:ipNumber];
	if(verbose)for(id aCmd in cmds) NSLog(@"SNMP Setting: %@\n",aCmd);
	NSArray* response = [ss writeValues:cmds];
	if(verbose)for(id anEntry in response) NSLog(@"Reponse: %@\n",anEntry);
	[delegate performSelectorOnMainThread:selector withObject:response waitUntilDone:YES];
	[ss release];
	//[ORTimer delay:.05];
    [pool release];
}

@end


//-----------------------------------------------------------
// An SNMP Read OP
//-----------------------------------------------------------
@implementation ORSNMPReadOperation
- (void) main
{	
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    if([self isCancelled]){
        [pool release];
        return;
    }
	ORSNMP* ss = [[ORSNMP alloc] initWithMib:mib];
	[ss openPublicSession:ipNumber];
	if(verbose)for(id aCmd in cmds) NSLog(@"SNMP Getting: %@\n",aCmd);
	NSArray* response = [ss readValues:cmds];
	if(verbose)for(id anEntry in response) NSLog(@"Reponse: %@\n",anEntry);
	[delegate performSelectorOnMainThread:selector withObject:response waitUntilDone:YES];
	[ss release];
	//[ORTimer delay:.05];
    [pool release];
}
@end

//-----------------------------------------------------------
// An SNMP Callback OP
//-----------------------------------------------------------
@implementation ORSNMPCallBackOperation

@synthesize userInfo;

- (void) main
{	
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    if([self isCancelled]){
        [pool release];
        return;
    }
	if(verbose)NSLog(@"CallBack to %@: %@ with %@\n",[target className], NSStringFromSelector(selector),userInfo);
	[target performSelectorOnMainThread:selector withObject:userInfo waitUntilDone:YES];
	//[ORTimer delay:.1];
    [pool release];
}
- (void) dealloc
{
    [userInfo release];
    [super dealloc];
}
@end

//--------------------------------------------------
// ORSNMPShellOp
// An easier way to use SNMP by just executing shell
// scripts and having the result go back to the delegate
//--------------------------------------------------
@implementation ORSNMPShellOp
- (id) initWithCmd:(NSString*)aCmd arguments:(NSArray*)theArgs delegate:(id)aDelegate tag:(int)aTag
{
	self = [super init];
    tag         = aTag;
	delegate    = aDelegate;
	command     = [aCmd copy];
    arguments   = [theArgs retain];
    return self;
}

- (void) dealloc
{
	[command release];
	[arguments release];
	[super dealloc];
}

- (void) main
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	@try {
		if(command && ![self isCancelled]){
			NSTask* task = [[NSTask alloc] init];
			[task setLaunchPath: command];
			[task setArguments: arguments];
			
			NSPipe* pipe = [NSPipe pipe];
			[task setStandardOutput: pipe];
			
			NSFileHandle* file = [pipe fileHandleForReading];
			[task launch];
            
			NSData* data = [file readDataToEndOfFile];
			if(data){
				NSString* result = [[[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding] autorelease];
				if([result length]){
                    if([delegate respondsToSelector:@selector(setSNMP:result:)]){
                        [delegate setSNMP:tag result:result];
                    }
                }
			}
			[task release];
            [file closeFile];
        }
	}
	@catch(NSException* e){
	}
    @finally{
        [pool release];
    }
}

@end

