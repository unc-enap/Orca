//
//  ORNPLCommBoardModel.m
//  Orca
//
//  Created by Mark Howe on Fri Jun 13 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORNPLCommBoardModel.h"
#import "NetSocket.h"

NSString* ORNPLCommBoardModelControlRegChanged		= @"ORNPLCommBoardModelControlRegChanged";
NSString* ORNPLCommBoardModelCmdStringChanged       = @"ORNPLCommBoardModelCmdStringChanged";
NSString* ORNPLCommBoardModelNumBytesToSendChanged  = @"ORNPLCommBoardModelNumBytesToSendChanged";
NSString* ORNPLCommBoardModelWriteValueChanged		= @"ORNPLCommBoardModelWriteValueChanged";
NSString* ORNPLCommBoardModelFunctionChanged		= @"ORNPLCommBoardModelFunctionChanged";
NSString* ORNPLCommBoardModelBlocChanged			= @"ORNPLCommBoardModelBlocChanged";
NSString* ORNPLCommBoardModelBoardChanged			= @"ORNPLCommBoardModelBoardChanged";
NSString* ORNPLCommBoardModelIsConnectedChanged		= @"ORNPLCommBoardModelIsConnectedChanged";
NSString* ORNPLCommBoardModelIpAddressChanged		= @"ORNPLCommBoardModelIpAddressChanged";
NSString* ORNPLCommBoardLock						= @"ORNPLCommBoardLock";

static NSString* NPLComConnectors[8] = {
@"NPLCom0 Connector", @"NPLCom1 Connector", @"NPLCom2 Connector",
@"NPLCom3 Connector", @"NPLCom4 Connector", @"NPLCom5 Connector",
@"NPLCom6 Connector", @"NPLCom7 Connector",
};

@implementation ORNPLCommBoardModel
- (void) makeMainController
{
    [self linkToController:@"ORNPLCommBoardController"];
}

- (void) dealloc
{
    [cmdString release];
	[socket close];
    [socket setDelegate:nil];
	[socket release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		[self connect];
		[self connectionChanged];
	}
	@catch(NSException* localException) {
	}
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"NPLCommBoardIcon"]];
}

- (void) makeConnectors
{
	int conv[8] = {7,5,3,1,6,4,2,0};
    int i;
    for(i=0;i<8;i++){
        ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - (i<4 ? (2*kConnectorSize + 5) : ((2*kConnectorSize + 27))),
																		  [self frame].size.height - 62-(i<4?i:i-4)*11.5) withGuardian:self withObjectLink:self];
        [[self connectors] setObject:aConnector forKey:NPLComConnectors[conv[i]]];
        [aConnector setIdentifer:conv[i]];
		[aConnector setConnectorType: 'NCmO' ];
		[aConnector setIoType:kOutputConnector];
		[aConnector addRestrictedConnectionType: 'NSLV' ]; //can only connect to Slave Boards
        [aConnector release];
    }
}

#pragma mark ***Accessors

- (int) controlReg
{
    return controlReg;
}

- (void) setControlReg:(int)aControlReg
{
	if(aControlReg<0)		 aControlReg = 0;
	else if(aControlReg>255) aControlReg = 255;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setControlReg:controlReg];
    
    controlReg = aControlReg;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelControlRegChanged object:self];
}

- (void) formatCmdString
{
	
	char bytes[3];
	if(numBytesToSend == 5){
		bytes[0] = (writeValue>>16 & 0xf);
		bytes[1] = (writeValue>>8 & 0xf); 
		bytes[2] = writeValue & 0xf; 
	}
	else if(numBytesToSend == 4){
		bytes[0] = (writeValue>>8 & 0xf);
		bytes[1] = (writeValue & 0xf); 
		bytes[2] = 0;
	}
	else if(numBytesToSend == 3){
		bytes[0] = (writeValue & 0xf); 
		bytes[1] = 0;
		bytes[2] = 0;
	}
	NSString* s = [NSString stringWithFormat:@"0x%02x 0x%02x 0x%02x",
				   numBytesToSend,
				   (([self board] & 0xf)<<4) | (([self bloc] & 0x3)<<2) | ([self functionNumber] & 0x3),
				   [self controlReg]];
	int i;
	for(i=0;i<numBytesToSend-2;i++){
		s = [s stringByAppendingFormat:@" 0x%02x",(unsigned char)bytes[i]];
	}
	[self setCmdString:s];
}

- (NSString*) cmdString
{
    return cmdString;
}

- (void) setCmdString:(NSString*)aCmdString
{
    [cmdString autorelease];
    cmdString = [aCmdString copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelCmdStringChanged object:self];
}

- (int) numBytesToSend
{
    return numBytesToSend;
}

- (void) setNumBytesToSend:(int)aNumBytesToSend
{
	if(aNumBytesToSend<3)		aNumBytesToSend = 3;
	else if(aNumBytesToSend>5)	aNumBytesToSend = 5;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setNumBytesToSend:numBytesToSend];
    
    numBytesToSend = aNumBytesToSend;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelNumBytesToSendChanged object:self];
	[self formatCmdString];
}

- (NSString*) lockName
{
	return ORNPLCommBoardLock;
}

- (int) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(int)aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:writeValue];
    
    writeValue = aWriteValue;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelWriteValueChanged object:self];
	[self formatCmdString];
}

- (int) functionNumber
{
    return functionNumber;
}

- (void) setFunctionNumber:(int)aFunction
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFunctionNumber:functionNumber];
    
    functionNumber = aFunction;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelFunctionChanged object:self];
	[self formatCmdString];
}

- (int) bloc
{
    return bloc;
}

- (void) setBloc:(int)aBloc
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBloc:bloc];
    
    bloc = aBloc;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelBlocChanged object:self];
	[self formatCmdString];
}

- (int) board
{
    return board;
}

- (void) setBoard:(int)aBoard
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBoard:board];
    
    board = aBoard;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelBoardChanged object:self];
	[self formatCmdString];
}

- (NetSocket*) socket
{
	return socket;
}

- (void) setSocket:(NetSocket*)aSocket
{
	if(aSocket != socket)[socket close];
	[aSocket retain];
	[socket release];
	socket = aSocket;
    [socket setDelegate:self];
}

- (void) setIsConnected:(BOOL)aFlag
{
    isConnected = aFlag;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelIsConnectedChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNPLCommBoardModelIpAddressChanged object:self];
}


- (void) connect
{
	if(!isConnected){
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:kNPLCommBoardPort]];	
        [self setIsConnected:[socket isConnected]];
	}
	else {
		[self setSocket:nil];	
        [self setIsConnected:[socket isConnected]];
	}
}

- (BOOL) isConnected
{
	return isConnected;
}


#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
{
    if(inNetSocket == socket){
		NSData* theData = [inNetSocket readData];
		char* theBytes = (char*)[theData bytes];
		int i;
		for(i=0;i<[theData length];i++){
			NSLog(@"Received [%d]: 0x%02x\n",i,(unsigned char)theBytes[i]);
		}
	}
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:NO];
		[socket autorelease];
		socket = nil;
    }
}


#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setControlReg:	[decoder decodeIntForKey:	@"controlReg"]];
    [self setNumBytesToSend:[decoder decodeIntForKey:	@"numBytesToSend"]];
    [self setWriteValue:	[decoder decodeIntForKey:	@"writeValue"]];
    [self setFunctionNumber:[decoder decodeIntForKey:	@"function"]];
    [self setBloc:			[decoder decodeIntForKey:	@"bloc"]];
    [self setBoard:			[decoder decodeIntForKey:	@"board"]];
	[self setIpAddress:		[decoder decodeObjectForKey:@"ipAddress"]];
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:controlReg		forKey: @"controlReg"];
    [encoder encodeInt:numBytesToSend	forKey: @"numBytesToSend"];
    [encoder encodeInt:writeValue		forKey: @"writeValue"];
    [encoder encodeInt:functionNumber	forKey: @"function"];
    [encoder encodeInt:bloc				forKey: @"bloc"];
    [encoder encodeInt:board			forKey: @"board"];
    [encoder encodeObject:ipAddress		forKey: @"ipAddress"];
}

- (void) sendBoard:(int)b bloc:(int)s function:(int)f controlReg:(int)aReg value:(int)aValue cmdLen:(int)aLen
{
	//send the values from the basic ops
	char bytes[6];
	bytes[0] = aLen;
	bytes[1] = ((b & 0xf)<<4) | ((s & 0x3)<<2) | (f & 0x3);
	bytes[2] = aReg;	
	if(aLen == 5){
		bytes[3] = (writeValue>>16 & 0xf);
		bytes[4] = (writeValue>>8 & 0xf); 
		bytes[5] = writeValue & 0xf; 
	}
	else if(aLen == 4){
		bytes[3] = (writeValue>>8 & 0xf);
		bytes[4] = (writeValue & 0xf); 
	}
	else if(aLen == 3){
		bytes[3] = (writeValue & 0xf); 
	}
	
	int i;
	for(i=0;i< 1 + aLen;i++){
		NSLog(@"%d: 0x%0x\n",i,bytes[i]);
	}
	
	[socket write:bytes length:aLen + 1];
	
}

- (void) sendCmd
{	
	[self sendBoard: [self board] 
			   bloc: [self bloc] 
		   function: [self functionNumber] 
		 controlReg: [self controlReg] 
			  value: [self writeValue]
		     cmdLen: [self numBytesToSend]]; 
}

@end
