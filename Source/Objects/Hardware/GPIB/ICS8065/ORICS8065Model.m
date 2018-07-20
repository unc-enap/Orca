//
//  ORICS8065Model.m
//  Orca
//
//  Created by Mark Howe on Friday, June 20, 2008.
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
//for the use of this softwagre.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#include <stdio.h>
#import "ORICS8065Model.h"

#pragma mark ***Defines
#define k8065CorePort 5555

NSString*   ORICS8065ModelCommandChanged		= @"ORICS8065ModelCommandChanged";
NSString*   ORICS8065PrimaryAddressChanged		= @"ORICS8065PrimaryAddressChanged";
NSString*	ORICS8065Connection					= @"ICS865OutputConnector";
NSString*	ORICS8065TestLock					= @"ORICS8065TestLock";
NSString*	ORGpib1MonitorNotification			= @"ORGpib1MonitorNotification";
NSString*	ORGpib1Monitor						= @"ORGpib1Monitor";
NSString*	ORGPIB1BoardChangedNotification		= @"ORGPIB1BoardChangedNotification";
NSString*	ORICS8065ModelIsConnectedChanged	= @"ORICS8065ModelIsConnectedChanged";
NSString*	ORICS8065ModelIpAddressChanged		= @"ORICS8065ModelIpAddressChanged";

@implementation ORICS8065Model
#pragma mark ***Initialization
- (void) commonInit
{
    short 	i;
    
	theHWLock = [[NSRecursiveLock alloc] init];    
    
    mErrorMsg = [[NSMutableString alloc] initWithFormat: @""];
    
    for ( i = 0; i < kMaxGpibAddresses; i++ ){
        memset(&mDeviceLink[i],0,sizeof(Create_LinkResp));
    } 
  	[self registerNotificationObservers];
   
}

- (id) init
{
    self = [super init];
    
    [self commonInit];
    
    return self;   
}


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [command release];
	int i;
    for ( i = 0; i < kMaxGpibAddresses; i++ ){
        if ( mDeviceLink[i].lid != 0 ){
			[self deactivateDevice:i];
		}
	} 
	
	if(rpcClient)clnt_destroy(rpcClient);
    [theHWLock release];
    [mErrorMsg release];
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

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[notifyCenter removeObserver:self];
	
    [notifyCenter addObserver : self
                     selector : @selector(applicationIsTerminating:)
                         name : @"ORAppTerminating"
                       object : (ORAppDelegate*)[NSApp delegate]];
}	

- (void) applicationIsTerminating:(NSNotification*)aNote
{
	if(rpcClient)clnt_destroy(rpcClient);
}

- (void) setUpImage
{
    NSImage* aCachedImage = [NSImage imageNamed:@"ICS8065Box"];
    NSImage* i = [[[NSImage alloc] initWithSize:[aCachedImage size]]autorelease];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];    
    if(![self isEnabled]){
        NSBezierPath* path = [NSBezierPath bezierPath];
        [path moveToPoint:NSZeroPoint];
        [path lineToPoint:NSMakePoint([self frame].size.width,[self frame].size.height)];
        [path moveToPoint:NSMakePoint([self frame].size.width,0)];
        [path lineToPoint:NSMakePoint(0,[self frame].size.height)];
        [path setLineWidth:2];
        [[NSColor redColor] set];
        [path stroke];
    }
    [i unlockFocus];
    
    [self setImage:i];
}

- (void) makeConnectors
{
	ORConnector* connectorObj = [[ORConnector alloc] initAt: NSMakePoint([self frame].size.width - kConnectorSize, 20 ) withGuardian: self];
	[connectorObj setConnectorType: 'GPI2'];
	[connectorObj addRestrictedConnectionType: 'GPI1']; //can only connect to gpib inputs
	[[self connectors] setObject: connectorObj forKey: ORICS8065Connection];
	[connectorObj release];
}

- (void) makeMainController
{
    [self linkToController: @"ORICS8065Controller"];
}

#pragma mark ***Accessors

- (NSString*) command
{
	if(!command)return @""; 
    else return command;
}

- (void) setCommand:(NSString*)aCommand
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCommand:command];
    
    [command autorelease];
    command = [aCommand copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORICS8065ModelCommandChanged object:self];
}

- (int) primaryAddress
{
    return primaryAddress;
}

- (void) setPrimaryAddress:(int)aPrimaryAddress
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPrimaryAddress:primaryAddress];
    
    primaryAddress = aPrimaryAddress;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORICS8065PrimaryAddressChanged object:self];
}

- (BOOL) isEnabled
{
    return YES;
}

- (CLIENT*) rpcClient
{
	return rpcClient;
}

- (void) setRpcClient:(CLIENT*)anRpcClient
{
	if(rpcClient)clnt_destroy(rpcClient);
	
	rpcClient = anRpcClient;
}

- (void) setIsConnected:(BOOL)aFlag
{
    isConnected = aFlag;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORICS8065ModelIsConnectedChanged object:self];
}

- (NSString*) ipAddress
{
	if(!ipAddress)return @"";
    else return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
	if(!aIpAddress)aIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
    
    [ipAddress autorelease];
    ipAddress = [aIpAddress copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORICS8065ModelIpAddressChanged object:self];
}

- (void) dropConnection
{
	if(!isConnected)return;
	
	int i;
	for( i=0; i<kMaxGpibAddresses; i++ ){
		if(mDeviceLink[i].lid != 0){
			[self deactivateDevice:i];
		}
	} 
	[self setRpcClient:nil];	
	[self setIsConnected:rpcClient!=nil];
}

- (void) connect
{
	if(!isConnected){
		//not connected
		CLIENT* aClient = clnt_create((char*)[ipAddress cStringUsingEncoding:NSASCIIStringEncoding],DEVICE_CORE,DEVICE_CORE_VERSION, "TCP");
		if(aClient){
			[self setRpcClient:aClient];	
			[self setIsConnected: aClient!=nil];
		}
		else {
			NSLog(@"unable to connect IC8065 to device\n");
		}
	}
	else {
		[self dropConnection];
	}
}

- (BOOL) isConnected
{
	return isConnected;
}


- (NSMutableString*) errorMsg
{
    return( mErrorMsg );
}

#pragma mark ***Basic commands
- (void) changeState: (short) aPrimaryAddress online: (BOOL) aState
{
}

- (BOOL) checkAddress: (short) aPrimaryAddress
{
    BOOL  bRetVal = false;
    if ( ! [self isEnabled]) return bRetVal;
    @try {
        [theHWLock lock];   //-----begin critical section
        // Check if device has been setup.
        if ( mDeviceLink[aPrimaryAddress].lid != 0 ){
            bRetVal = true;
        }
		
        [theHWLock unlock];   //-----end critical section
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
    return( bRetVal );    
}


- (void) enableEOT:(short)aPrimaryAddress state: (BOOL) state
{
	
}

- (void) resetDevice: (short) aPrimaryAddress
{
}

- (void) setGPIBMonitorRead: (bool) aMonitorRead
{
	mMonitorRead = aMonitorRead;
}

- (void) setGPIBMonitorWrite: (bool) aMonitorWrite
{
	mMonitorWrite = aMonitorWrite;
}

- (void) 	setupDevice: (short) aPrimaryAddress secondaryAddress: (short) aSecondaryAddress
{
	[self setupDevice:aPrimaryAddress];
}

- (void) setupDevice: (short) aPrimaryAddress
{  
    if(![self isEnabled])return;
	
    @try {
		if(mDeviceLink[aPrimaryAddress].lid != 0) {
			[self deactivateDevice:aPrimaryAddress];
		}
		
        [theHWLock lock];   //-----begin critical section
		
		Create_LinkParms crlp;
		crlp.clientId = (int)rpcClient;
		crlp.lockDevice = 0;
		crlp.lock_timeout = 10000;
		char device[64];
		sprintf(device,"gpib0,%d",aPrimaryAddress);
		crlp.device = device;
		if(rpcClient){
			Create_LinkResp* src = create_link_1(&crlp, rpcClient);
			if(src){
				memcpy(&mDeviceLink[aPrimaryAddress], src,sizeof(Create_LinkResp));
			}
		}
		else {
			NSLog(@"unable to setup IC8065. Power may be off.\n");
		}
        [theHWLock unlock];   //-----end critical section
		
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
}

- (void) deactivateDevice: (short) aPrimaryAddress
{
    if( ![self isEnabled]) return;
    @try {
        [theHWLock lock];   //-----begin critical section
		
		if ( mDeviceLink[aPrimaryAddress].lid != 0 && rpcClient!=0){
			// Deactivate the device
			destroy_link_1(&mDeviceLink[aPrimaryAddress].lid,rpcClient);
			memset(&mDeviceLink[aPrimaryAddress],0,sizeof(Create_LinkResp));
		}
		
        [theHWLock unlock];   //-----end critical section
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
}

- (int32_t) readFromDevice: (short) aPrimaryAddress data: (char*) data maxLength: (int32_t) aMaxLength
{
	
    if ( ! [self isEnabled] || !rpcClient) return 0;
    
	int32_t nReadBytes = 0;
    @try {
        // Make sure that device is initialized.
        [theHWLock lock];   //-----begin critical section
		if ( mDeviceLink[aPrimaryAddress].lid == 0 ){
			[self setupDevice:aPrimaryAddress];
		}
		
		Device_ReadParms  devReadP; 
		Device_ReadResp*  dwrrPtr;
		int  thisRead;
		
		do {
	        thisRead = -1;
			// Perform the read.				
			devReadP.lid = mDeviceLink[aPrimaryAddress].lid; 
			devReadP.requestSize = (unsigned int)aMaxLength;
			devReadP.io_timeout = 1000; 
			devReadP.lock_timeout = 10000;
			devReadP.flags = 0;
			//devReadP.flags = 0;
			devReadP.termChar = '\n';
			dwrrPtr = device_read_1(&devReadP, rpcClient); 
			if(dwrrPtr){
				
				if (dwrrPtr->error != 0) {
					[mErrorMsg setString:  @"***Error: read"];
					[self gpibError: mErrorMsg number:dwrrPtr->error]; 
					[NSException raise: OExceptionGpibError format: @"%@",mErrorMsg];
				}
				
				thisRead = dwrrPtr->data.data_len;
				if(thisRead>0){
					memcpy(data, dwrrPtr->data.data_val, thisRead);
					nReadBytes += thisRead;
					data  += thisRead;
					aMaxLength -= thisRead;
				}
			}
			else break;
		} while(!dwrrPtr->reason && thisRead>0);
		
		data[nReadBytes] = '\0';
		
		// Allow monitoring of commands.
		if ( mMonitorRead ) {
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];	
			NSString* dataStr = [[NSString alloc] initWithBytes: data length: nReadBytes encoding: NSASCIIStringEncoding];
			[userInfo setObject: [NSString stringWithFormat: @"Read - Address: %d length: %d data: %@\n", 
								  aPrimaryAddress, nReadBytes, dataStr] 
						 forKey: ORGpib1Monitor]; 
			
			[[NSNotificationCenter defaultCenter]
			 postNotificationName: ORGpib1MonitorNotification
			 object: self
			 userInfo: userInfo];
			[dataStr release];
		}
		
        [theHWLock unlock];   //-----end critical section
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
	
    return nReadBytes;
}



- (void) writeToDevice: (short) aPrimaryAddress command: (NSString*) aCommand
{
    if ( ! [self isEnabled] || !rpcClient) return;
    @try {
        [theHWLock lock];   //-----begin critical section
		// Make sure that device is initialized.
		if ( mDeviceLink[aPrimaryAddress].lid == 0 ){
			[self setupDevice:aPrimaryAddress];
		}
        
        // Allow monitoring of commands.
        if ( mMonitorWrite ) {
            NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
            [userInfo setObject: [NSString stringWithFormat: @"Write - Address: %d Comm: %s\n", aPrimaryAddress, [aCommand cStringUsingEncoding:NSASCIIStringEncoding]] 
						 forKey: ORGpib1Monitor]; 
            
            [[NSNotificationCenter defaultCenter]
			 postNotificationName: ORGpib1MonitorNotification
			 object: self
			 userInfo: userInfo];
        }
        
        //	printf( "Command %s\n", [aCommand cString] );
        
        // Write to device.
		
		Device_WriteParms  devReadP; 
		Device_WriteResp*  dwrr; 
		devReadP.lid = mDeviceLink[aPrimaryAddress].lid; 
		devReadP.io_timeout = 1000; 
		devReadP.lock_timeout = 10000;
		devReadP.flags = 0;
		if(![aCommand hasSuffix:@"\n"])aCommand = [aCommand stringByAppendingString:@"\n"];
		devReadP.data.data_len = (unsigned int)[aCommand length];
		devReadP.data.data_val = (char *)[aCommand cStringUsingEncoding:NSASCIIStringEncoding];
		dwrr = device_write_1(&devReadP, rpcClient); 
		if(dwrr == 0){
			[self disconnect]; //toggle the connection
			[self connect];
			[self setupDevice:aPrimaryAddress];
			devReadP.lid = mDeviceLink[aPrimaryAddress].lid; 
			dwrr = device_write_1(&devReadP, rpcClient); 
		}
        if (dwrr &&  dwrr->error != 0 ) {
            [mErrorMsg setString:  @"***Error: write"];
            [self gpibError: mErrorMsg number: dwrr->error]; 
            [NSException raise: OExceptionGpibError format: @"%@",mErrorMsg];
        }  
        [theHWLock unlock];   //-----end critical section
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }  
	
}


- (int32_t) writeReadDevice: (short) aPrimaryAddress command: (NSString*) aCommand data: (char*) aData
               maxLength: (int32_t) aMaxLength
{
    int32_t retVal = 0;
    if ( ! [self isEnabled]) return -1;
    @try {
        
        [theHWLock lock];   //-----begin critical section
        [self writeToDevice: aPrimaryAddress command: aCommand];
        retVal = [self readFromDevice: aPrimaryAddress data: aData maxLength: aMaxLength];
        
        [theHWLock unlock];   //-----end critical section
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
    return( retVal );
}

- (void) wait: (short) aPrimaryAddress mask: (short) aWaitMask
{
}

#pragma mark ***Support Methods
- (id) getGpibController
{
	return self;
}

- (void) gpibError: (NSMutableString*) aMsg number:(int)anErrorNum
{
    if ( ! [self isEnabled]) return;
    @try {
        // Handle the master error register and extract error.
        //[theHWLock unlock];   //-----end critical section
        [aMsg appendString: [NSString stringWithFormat:  @" e = %d < ", anErrorNum]];
        
        NSMutableString *errorType = [[NSMutableString alloc] initWithFormat: @""];
        
        if (anErrorNum == 4 )  [errorType appendString: @" invalid link identifier "];
        else if (anErrorNum == 11 )  [errorType appendString: @" device locked by another link "];
        else if (anErrorNum == 15 )  [errorType appendString: @" I/O timeout "];
        else if (anErrorNum == 17 )  [errorType appendString: @" I/O error "];
        else if (anErrorNum == 23 )  [errorType appendString: @" abort "];
        
        [aMsg appendString: errorType];
        [errorType release];
        
		
        //[theHWLock unlock];   //-----end critical section
		// Call ibonl to take the device and interface offline
		//    ibonl( Device, 0 );
		//    ibonl( BoardIndex, 0 );
    }
	@catch(NSException* localException) {
        [theHWLock unlock];   //-----end critical section
        [localException raise];
    }
    
}

#pragma mark •••Archival
- (id) initWithCoder: (NSCoder*) decoder
{
    self = [super initWithCoder: decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self commonInit];
    [self setCommand:		[decoder decodeObjectForKey:@"command"]];
 	[self setIpAddress:		[decoder decodeObjectForKey:@"ipAddress"]];
	[self setPrimaryAddress:[decoder decodeIntForKey:   @"primaryAddress"]];
	
    [[self undoManager] enableUndoRegistration];
   
    return self;
}

- (void) encodeWithCoder: (NSCoder*) encoder
{
    [super encodeWithCoder: encoder];
	[encoder encodeObject:command		forKey: @"command"];
	[encoder encodeObject:ipAddress		forKey: @"ipAddress"];
	[encoder encodeInteger:primaryAddress	forKey: @"primaryAddress"];
}

@end

