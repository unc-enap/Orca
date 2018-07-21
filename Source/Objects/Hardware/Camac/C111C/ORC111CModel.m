/*
 *  ORC111CModel.h
 *  Orca
 *
 *  Created by Mark Howe on Mon Dec 10, 2007.
 *  Copyright (c) 2007 CENPA, University of Washington. All rights reserved.
 *
 */
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

#import "ORC111CModel.h"
#import "ORCmdHistory.h"
#include <sys/time.h> 
#include <sys/wait.h> 
#include <sys/types.h> 
#include <sys/socket.h> 
#include <sys/stat.h> 
#include <netinet/in.h> 
#include <arpa/inet.h>
#include <sys/ioctl.h>
#include <fcntl.h> 
#import <netdb.h>
#include <time.h> 

#define kTinyDelay 0.0005

NSString* ORC111CModelTrackTransactionsChanged = @"ORC111CModelTrackTransactionsChanged";
NSString* ORC111CModelStationToTestChanged	= @"ORC111CModelStationToTestChanged";
NSString* ORC111CSettingsLock				= @"ORC111CSettingsLock";
NSString* ORC111CConnectionChanged			= @"ORC111CConnectionChanged";
NSString* ORC111CTimeConnectedChanged		= @"ORC111CTimeConnectedChanged";
NSString* ORC111CIpAddressChanged			= @"ORC111CIpAddressChanged";

void IRQHandler(short crate_id, short irq_type, unsigned int irq_data,NSUInteger userInfo)
{
	id obj = (NSDictionary*)userInfo;
	[obj handleIRQ:irq_type data:irq_data];
}

@implementation ORC111CModel
- (id) init
{
	self = [super init];
	socketLock = [[NSLock alloc] init];
	irqLock    = [[NSLock alloc] init];
	return self;
}

-(void) dealloc
{
	[cmdHistory release];
    [ipAddress release];
	[transactionTimer release];
	[socketLock release];
	[irqLock release];  
	
	[self disconnect];
    [super dealloc];
}

- (NSString*) helpURL
{
	return @"CAMAC/C111C.html";
}

#pragma mark ***Accessors
- (ORCmdHistory*) cmdHistory
{
	if(!cmdHistory)cmdHistory = [[ORCmdHistory alloc] init];
	return cmdHistory;
}

- (BOOL) trackTransactions
{
    return trackTransactions;
}

- (void) setTrackTransactions:(BOOL)aTrackTransactions
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrackTransactions:trackTransactions];
    
    trackTransactions = aTrackTransactions;
	
	if(aTrackTransactions){
		transactionTimer = [[ORTimer alloc] init];
		[transactionTimer start];
	}
	else {
		[transactionTimer release];
		transactionTimer = nil;
	}
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORC111CModelTrackTransactionsChanged object:self];
}

- (void) histogramTransactions
{
	float seconds = [transactionTimer seconds];
	if(seconds>0){
		int ts = 1./seconds;
		if(ts>=kMaxNumberC111CTransactionsPerSecond-1)ts = kMaxNumberC111CTransactionsPerSecond-1;
		transactionsPerSecondHistogram[ts]++;
	}
}

- (void) clearTransactions
{
	int i;
	for(i=0;i<kMaxNumberC111CTransactionsPerSecond;i++)transactionsPerSecondHistogram[i] = 0;
}

- (float) transactionsPerSecondHistogram:(int)index
{
	if(index>=kMaxNumberC111CTransactionsPerSecond)index = kMaxNumberC111CTransactionsPerSecond-1;
	return transactionsPerSecondHistogram[index];
}

- (char) stationToTest
{
    return stationToTest;
}

- (void) setStationToTest:(char)aStationToTest
{
	if(aStationToTest==0)aStationToTest=1;
	else if(aStationToTest>25)aStationToTest=25;
	else if(aStationToTest< -1)aStationToTest = -1;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setStationToTest:stationToTest];
    
    stationToTest = aStationToTest;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORC111CModelStationToTestChanged object:self];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		if(ipAddress) [self connect];
	}
	@catch(NSException* localException) {
	}
}


- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"C111C"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORC111CController"];
}

- (NSString*) settingsLock
{
	return ORC111CSettingsLock;
}

- (BOOL) isConnected
{
	return isConnected;
}

- (void) setIsConnected:(BOOL)aNewIsConnected
{
	isConnected = aNewIsConnected;
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName:ORC111CConnectionChanged 
	 object: self];
	
	[self setTimeConnected:isConnected?[NSDate date]:nil];
	
}

- (NSDate*) timeConnected
{
	return timeConnected;
}

- (void) setTimeConnected:(NSDate*)newTimeConnected
{
	[timeConnected autorelease];
	timeConnected=[newTimeConnected retain];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORC111CTimeConnectedChanged object:self];
}

- (NSString*) ipAddress
{
    return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
	if(!aIpAddress)aIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
    
    [ipAddress autorelease];
    ipAddress = [aIpAddress copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORC111CIpAddressChanged object:self];
}

- (NSString*) crateName
{
	NSString* crateName = [[self guardian] className];
	if(crateName){
		if([crateName hasPrefix:@"OR"])crateName = [crateName substringFromIndex:2];
		if([crateName hasSuffix:@"Model"])crateName = [crateName substringToIndex:[crateName length]-5];
	}
	else {
		crateName = [[ipAddress copy] autorelease];
	}
	return crateName;
}

- (id) controller
{
    return self;
}
- (unsigned short) camacStatus
{
    return 0;
}

- (void)  checkCratePower
{   
    //[[self controller] checkCratePower];
}


- (void) connect
{
	if(!isConnected){
		crate_id = CROPEN((char*)[ipAddress cStringUsingEncoding:NSASCIIStringEncoding]);
		if (crate_id < 0) { 
			NSLog(@"Error %d opening connection with CAMAC Controller", crate_id); 
		}
		else {
			int res = CRGET(crate_id, &cr_info);
			if(res == CRATE_OK){
				[self setIsConnected: YES];
				cr_info.tout_ticks = 1000; 
				CRSET(crate_id, &cr_info);
				[ORTimer delay:.3];
				CRIRQ(crate_id,(IRQ_CALLBACK)IRQHandler,(uint32_t)(self));
			}
		}
	}
}

- (void) disconnect
{
	if(isConnected){
		CRCLOSE(crate_id);		
		[self setIsConnected: NO];
		NSLog(@"Disconnected from %@ <%@>\n",[self crateName],ipAddress);
	}	
}

- (NSString*) shortName
{
	return @"C111C";
}

- (unsigned short)  executeCCycle
{
	short res;
	[socketLock lock];		//begin critical section
	res = CCCC(crate_id);
	[socketLock unlock];	//end critical section
	
	return res;
}

- (unsigned short)  executeZCycle
{
	short res;
	[socketLock lock];		//begin critical section
	res=CCCZ(crate_id);
	if(res==CRATE_CONNECT_ERROR){
		[self setIsConnected:NO];
	}
	[socketLock unlock];	//end critical section
	return res;	
}

- (unsigned short)  resetContrl
{   
	NSLog(@"C111C doesn't support a controller reset function\n");
    return 1;
}
- (uint32_t) setLAMMask:(uint32_t) mask
{
	NSLog(@"C111C doesn't support a set LAM mask function\n");
    return 1;
}

- (unsigned short)  readLAMMask:(uint32_t *)mask
{
	NSLog(@"C111C doesn't support a read LAM mask function\n");
	
	*mask = 0;
	return 1;
} 

- (unsigned short)  readLAMFFStatus:(unsigned short*)value
{
	NSLog(@"C111C doesn't support a read LAMFF Status function\n");
	
	*value = 0;
	return 1;
}

- (unsigned short) testLAMForStation:(char)aStation value:(char*)result
{
	short res;
	[socketLock lock];		//begin critical section
	res = CTLM(crate_id,aStation,result);
	if(res==CRATE_CONNECT_ERROR){
		[self setIsConnected:NO];
	}
	[socketLock unlock];	//end critical section
	return res;
}

- (unsigned short)  resetLAMFF
{
	short res;
	[socketLock lock];		//begin critical section
	res = LACK(crate_id);
	if(res==CRATE_CONNECT_ERROR){
		[self setIsConnected:NO];
	}
	[socketLock unlock];	//end critical section
	return res;
}


- (unsigned short)  readLAMStations:(uint32_t *)stations
{
	short res;
	unsigned int mask;
	[socketLock lock];		//begin critical section
	res = CLMR(crate_id,&mask);
	if(res==CRATE_CONNECT_ERROR){
		*stations = 0;
		[self setIsConnected:NO];
	}
	else *stations = mask&0x0FFFFFF;
	[socketLock unlock];	//end critical section
	return res;
}

- (unsigned short)  setCrateInhibit:(BOOL)state
{   
	short res;
	[socketLock lock];		//begin critical section
	res = CCCI(crate_id,state);
	if(res==CRATE_CONNECT_ERROR){
		[self setIsConnected:NO];
	}
	[socketLock unlock];	//end critical section
	return res;
}

- (unsigned short)  readCrateInhibit:(unsigned short*)state
{   
 	short res;
	char inhibitValue;
	[socketLock lock];		//begin critical section
	res = CTCI(crate_id,&inhibitValue);
	if(res==CRATE_CONNECT_ERROR){
		[self setIsConnected:NO];
	}
	else *state = inhibitValue;
	[socketLock unlock];	//end critical section
	return res;
}


- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f
							 data:(unsigned short*) data
{
	short result;
	[socketLock lock];		//begin critical section
	CRATE_OP cr_op;
	cr_op.F = f;
	cr_op.N = n;
	cr_op.A = a;
	cr_op.DATA = *data;
	if(trackTransactions)[transactionTimer reset];
	result = CSSA(crate_id,&cr_op);
	[ORTimer delay:kTinyDelay]; //without this to flush the event loop, the rate is 1/sec
	if(result==CRATE_OK){
		if(trackTransactions)[self histogramTransactions];
		cmdResponse		= cr_op.Q;
		cmdAccepted		= cr_op.X;
		*data			= cr_op.DATA;
	}
	else if(result==CRATE_CONNECT_ERROR){
		cmdResponse		= 0;
		cmdAccepted		= 0;
		*data			= 0;
		[self setIsConnected:NO];
	}
	[socketLock unlock];	//end critical section
	return result;
}

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f;
{
	short result;
	[socketLock lock];		//begin critical section
	CRATE_OP cr_op;
	cr_op.F = f;
	cr_op.N = n;
	cr_op.A = a;
	cr_op.DATA = 0;
	if(trackTransactions)[transactionTimer reset];
	result = CSSA(crate_id,&cr_op);
	[ORTimer delay:kTinyDelay]; //without this to flush the event loop, the rate is 1/sec
	if(trackTransactions)[self histogramTransactions];
	if(result==CRATE_OK){
		cmdResponse		= cr_op.Q;
		cmdAccepted		= cr_op.X;
	}
	else if(result==CRATE_CONNECT_ERROR){
		cmdResponse		= 0;
		cmdAccepted		= 0;
		[self setIsConnected:NO];
	}
	[socketLock unlock];	//end critical section
	return result;
}

- (unsigned short)  camacLongNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(uint32_t*) data
{
	short result;
	[socketLock lock];		//begin critical section
    int* pp = (int*)data;
	CRATE_OP cr_op;
	cr_op.F = f;
	cr_op.N = n;
	cr_op.A = a;
	cr_op.DATA = *pp;
	if(trackTransactions)[transactionTimer reset];
	result = CFSA(crate_id,&cr_op);
	[ORTimer delay:kTinyDelay]; //without this to flush the event loop, the rate is 1/sec
	if(trackTransactions)[self histogramTransactions];
	if(result==CRATE_OK){
		cmdResponse		= cr_op.Q;
		cmdAccepted		= cr_op.X;
		*data			= cr_op.DATA;
	}
	else if(result==CRATE_CONNECT_ERROR){
		cmdResponse		= 0;
		cmdAccepted		= 0;
		*data			= 0;
		[self setIsConnected:NO];
	}
	[socketLock unlock];	//end critical section
	return result;
}


- (unsigned short)  camacShortNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned short*) data
                                length:(uint32_t) numWords
{
	short result;
	[socketLock lock];		//begin critical section
	BLK_TRANSF_INFO blk_info;
	blk_info.opcode = OP_BLKSR; 
	blk_info.F = f; 
	blk_info.N = n; 
	blk_info.A = a; 
	blk_info.blksize = 256;  
	blk_info.totsize = numWords;  
    blk_info.ascii_transf = 0;	
	blk_info.timeout = 0;
	unsigned int* buffer = (unsigned int*)malloc(numWords*sizeof(unsigned int));
	if(trackTransactions)[transactionTimer reset];
	int i;
	if(f < 16){
		//CAMAC Read
		result = BLKTRANSF(crate_id, &blk_info, buffer);
		[ORTimer delay:kTinyDelay]; //without this to flush the event loop, the rate is 1/sec
		if(result==CRATE_OK){
			unsigned int* dp = buffer;
			for(i=0;i<numWords;i++)*data++ = *dp++;
		}
	}
	else {
		//CAMAC write
		unsigned int* dp = buffer;
		for(i=0;i<numWords;i++) *dp++ = *data++;
		result = BLKTRANSF(crate_id, &blk_info, buffer);
	}
	if(trackTransactions)[self histogramTransactions];
	
	if(result==CRATE_CONNECT_ERROR){
		[self setIsConnected:NO];
	}
	free(buffer);
	[socketLock unlock];	//end critical section
  	return result;
}

- (unsigned short)  camacLongNAFBlock:(unsigned short) n 
									a:(unsigned short) a 
									f:(unsigned short) f
								 data:(uint32_t*) data
							   length:(uint32_t)    numWords
{
	short result = 0;
	[socketLock lock];		//begin critical section
	BLK_TRANSF_INFO blk_info;
	blk_info.opcode = OP_BLKSA; 
	blk_info.F = f; 
	blk_info.N = n; 
	blk_info.A = a; 
	blk_info.blksize = 24; //16 bit word size  
	blk_info.totsize = numWords;  	
	blk_info.timeout = 0;
	unsigned int* buffer = (unsigned int*)malloc(numWords*sizeof(unsigned int));
	if(trackTransactions)[transactionTimer reset];
	int i;
	if(f < 16){
		//CAMAC Read
		result = BLKTRANSF(crate_id, &blk_info, buffer);
		[ORTimer delay:kTinyDelay]; //without this to flush the event loop, the rate is 1/sec
		if(result==CRATE_OK){
			unsigned int* dp = buffer;
			for(i=0;i<numWords;i++)*data++ = *dp++;
		}
	}
	else {
		//CAMAC write
		unsigned int* dp = buffer;
        unsigned int* pp = (unsigned int*)data;
		for(i=0;i<numWords;i++) *dp++ = *pp++;
		result = BLKTRANSF(crate_id, &blk_info, buffer);
	}
	if(trackTransactions)[self histogramTransactions];
	
	if(result==CRATE_CONNECT_ERROR){
		[self setIsConnected:NO];
	}
	free(buffer);
	[socketLock unlock];	//end critical section
  	return result;
}

- (void) handleIRQ:(short)irq_type data:(unsigned int)irq_data
{
	[irqLock lock];		//begin critical section
	switch (irq_type) { 
		case LAM_INT: 
			lamMask = irq_data;
			break; 
			
		case COMBO_INT: 
			NSLog(@"got combo irq\n");
			// Do something when a COMBO event occurs 
			// Write your code here 
			break; 
			
		case DEFAULT_INT:
			NSLog(@"got default irq\n");
			// Do something when the 'DEFAULT' button is pressed  
			// Write your code here 
			break; 
	} 
	[irqLock unlock];		//end critical section
}


- (void) sendCmd:(NSString*)aCmd verbose:(BOOL)verbose
{
	int res;
	char response[32];
	[socketLock lock];		//begin critical section
	if(![aCmd hasSuffix:@"\r"])aCmd = [aCmd stringByAppendingString:@"\r"];
	res = CMDSR(crate_id,(char*)[aCmd cStringUsingEncoding:NSASCIIStringEncoding], response, 32);
	[ORTimer delay:kTinyDelay]; //without this to flush the event loop, the rate is 1/sec
	if(res==CRATE_OK){
		if(verbose){
			NSLog(@"C111C Response: %s\n",response);
		}
	}
	else {
		[self setIsConnected:NO];
	}
	[socketLock unlock];	//end critical section
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setStationToTest:[decoder decodeIntegerForKey:@"ORC111CModelStationToTest"]];
	[self setIpAddress:[decoder decodeObjectForKey:@"IpAddress"]];
    [[self undoManager] enableUndoRegistration];
	
	socketLock = [[NSLock alloc] init];
	irqLock    = [[NSLock alloc] init];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:stationToTest forKey:@"ORC111CModelStationToTest"];
    [encoder encodeObject:ipAddress forKey:@"IpAddress"];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{	
	[irqLock lock];		//begin critical section
	if(lamMask) {
		int i;
		for(i=0;i<25;i++){
			if(lamMask & (0x1L<<i)){
				[dataTakers[i] takeData:aDataPacket userInfo:userInfo];
			}
		}
		LACK(crate_id);
	}
	[irqLock unlock];		//end critical section
}

@end

