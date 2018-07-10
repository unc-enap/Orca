/*
 File:		ORUSBInterface.m
 
 Synopsis: 	ObjC class to represent an device on the USB bus. Corresponds
 to IOUSBDeviceInterface.
 
 Note: converted to ObjC from the C++ version in Apples example code.
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

#import "ORUSBInterface.h"

void MyCallBackFunction(void *dummy, IOReturn result, void *arg0)
{    
    printf("MyCallbackfunction: %d, 0x%x, %d\n", (int)dummy, (int)result, (int)arg0);
}

void _interruptRecieved(void *refCon, IOReturn result, int len) 
{
	[((ORUSBInterface*) refCon) interruptRecieved:result length:len];
}



NSString* ORUSBRegisteredObjectChanged	= @"ORUSBRegisteredObjectChanged";

@implementation ORUSBInterface

- (id) init
{
	self=[super init];
	interface = nil;
	tag = 5;
	usbLock = [[NSRecursiveLock alloc] init];
	return self;
}

- (void) dealloc
{ 
	if(interface) {
		(*interface)->USBInterfaceClose(interface);
		(*interface)->Release(interface);
	}
	[serialNumber release];
	[deviceName release];
	[connectionState release];
	[usbLock release];
	[super dealloc];
}

#pragma mark ¥¥¥Accessors
- (UInt16) product
{
    return product;
}

- (void) setProduct:(UInt16)aProduct
{
    product = aProduct;
}

- (UInt16) vendor
{
    return vendor;
}

- (void) setVendor:(UInt16)aVendor
{
    vendor = aVendor;
}

- (UInt32) locationID
{
    return locationID;
}

- (void) setLocationID:(UInt32)aLocationID
{
    locationID = aLocationID;
}

- (NSString*) deviceName
{
    return deviceName;
}

- (void) setDeviceName:(NSString*)aDeviceName
{
    [deviceName autorelease];
    deviceName = [aDeviceName copy];    
}

- (NSString*) serialNumber
{
	if([serialNumber isEqualToString:@"0"])return [NSString stringWithFormat:@"0x%8lx", locationID];
    else return serialNumber;
}

- (void) setSerialNumber:(NSString*)aSerialString
{
    [serialNumber autorelease];
    serialNumber = [aSerialString copy];    
}

- (io_object_t) notification
{
    return notification;
}

- (void) setNotification:(io_object_t)aNotification
{
    notification = aNotification;
}

- (void) setRegisteredObject:(id)anObj
{
	//don't retain
	registeredObject = anObj;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORUSBRegisteredObjectChanged object:self userInfo:nil];
}

- (id) registeredObject
{
	return registeredObject;
}

- (id) callBackObject
{
	return callBackObject;
}

- (void) setCallBackObject:(id)anObj
{
	//don't retain;
	callBackObject = anObj;
}

- (void) setUsePipeType:(UInt8)aTransferType
{
	transferType = aTransferType;
}

- (UInt8) usingPipeType
{
	return transferType;
}


- (void) setInterface:(IOUSBInterfaceInterface197**)anInterface
{
	if(interface) {
		(*interface)->USBInterfaceClose(interface);
		(*interface)->Release(interface);
	}
	interface = anInterface;
	
	if(interface){
		IOReturn kr = (*interface)->USBInterfaceOpen(interface);
		if(kr)NSLog(@"USB: Open Error: 0x%x\n",kr);
		(void) (*interface)->AddRef(interface);
		
		kr = (int)(*interface)->GetPipeStatus(interface, outPipes[0]);
		if (kr == kIOUSBPipeStalled) {
			NSLog(@"pipe stalled. (%d)\n", (int)kr);
			kr = (int)(*interface)->ClearPipeStall (interface, outPipes[0]); 		
			NSLog(@"cleared. (%d)\n", (int)kr);
		}
		(void) (*interface)->AddRef(interface);
		[self setUsePipeType:kUSBBulk];
		//unsigned char theSpeed;
		//kr = (*interface)->GetDeviceSpeed(interface,&theSpeed);
		//if(kr == kIOReturnSuccess){
		//	NSLog(@"Device Speed: %d\n",theSpeed);
		//}
		
		//(*interface)->ResetPipe(interface,outPipe);
		//(*interface)->ResetPipe(interface,inPipe);
		
		//startUp Interrupt handling
		//UInt32 numBytesRead = sizeof(_recieveBuffer); // leave one byte at the end for NUL termination
		//bzero(&_recieveBuffer, numBytesRead);
		//kr = (*interface)->ReadPipeAsync(interface, inPipe, &_recieveBuffer, numBytesRead, (IOAsyncCallback1)_interruptRecieved, self);
		
		//if (kIOReturnSuccess != kr) {
		//	NSLog(@"unable to do async interrupt read (%08x)\n", kr);
		//	(void) (*interface)->USBInterfaceClose(interface);
		//	(void) (*interface)->Release(interface);
		//}
	}
}

- (void) startReadingInterruptPipe
{
	UInt8 pipe;
	if(transferType == kUSBBulk)		 pipe = inPipes[0];
	else if(transferType == kUSBInterrupt) pipe = interruptInPipes[0];
	else pipe  = inPipes[0];
    
	IOReturn kr;
    (*interface)->ClearPipeStallBothEnds(interface, pipe);
	kr = (*interface)->ResetPipe(interface,pipe);

	//startUp Interrupt handling
	UInt32 numBytesRead = 1024; // leave one byte at the end for NUL termination
	bzero(receiveBuffer, numBytesRead);
	kr = (*interface)->ReadPipeAsync(interface,pipe, receiveBuffer, numBytesRead, (IOAsyncCallback1)_interruptRecieved, self);
	
	if (kIOReturnSuccess != kr) {
		NSLog(@"unable to do async interrupt read (%08x)\n", kr);
		//(void) (*interface)->USBInterfaceClose(interface);
		//(void) (*interface)->Release(interface);
	}
}

-(void) interruptRecieved:(IOReturn) result length:(int) len
{
    IOReturn                    kr;   
    NSLog(@"interruptRecieved.\n");
    if (kIOReturnSuccess != result) {
		NSLog(@"error from async interruptRecieved (%08x)\n", result);
        if (result != (IOReturn)0xe00002ed) {
			goto readon;
        }
    }
	
readon:
    bzero(receiveBuffer, 1024);
    kr = (*interface)->ReadPipeAsync(interface, inPipes[0], receiveBuffer, 1024, (IOAsyncCallback1)_interruptRecieved, self);
    if (kIOReturnSuccess != kr) {
        NSLog(@"unable to do async interrupt read (%08x). this means the card is stopped!\n", kr);
    }
	
}


- (IOUSBInterfaceInterface197**) interface
{
	return interface;
}

- (void) writeString:(NSString*)aCommand
{
	[usbLock lock];
	UInt8 pipe;
	if(transferType == kUSBBulk)		 pipe = outPipes[0];
	else if(transferType == kUSBInterrupt) pipe = interruptOutPipes[0];
	else pipe  = outPipes[0];
    
	char* p = (char*)[aCommand cStringUsingEncoding:NSASCIIStringEncoding];
	IOReturn kr = (*interface)->WritePipe(interface, pipe, p, strlen(p));
	if(kr)	{
		[usbLock unlock];
		[NSException raise:@"USB Write" format:@"ORUSBInterface.m %u: WritePipe failed for <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
	}
	[usbLock unlock];
}

- (void) writeUSB488Command:(NSString*)aCommand eom:(BOOL)eom
{
	
	[usbLock lock];
	@try {
		char buffer[512];
		USB488Header* hp;
		
		unsigned int commandLength =  [aCommand length];
		
		unsigned long unpaddedLength = commandLength + sizeof(USB488Header);
		unsigned long paddedLength;
		if(unpaddedLength%4 != 0){
			paddedLength = ((unpaddedLength + 4)/4)*4;	
		}
		else {
			paddedLength = unpaddedLength;
		}
		
		if(paddedLength%4!=0)NSLog(@"USB command NOT padded to long word size\n");
		memset(buffer,0,paddedLength);
		
		hp = (USB488Header*)buffer;
		hp->messageID = 0x01;
		hp->bTag = tag;
		hp->bTagInverse = ~tag;
		hp->transferLength = CFSwapInt32HostToLittle(commandLength);
		hp->eom = eom; //1 == last byte is end of message
		tag++;
		
		strncpy(&buffer[sizeof(USB488Header)],[aCommand cStringUsingEncoding:NSASCIIStringEncoding],commandLength);
		
		[self writeBytes:buffer length:paddedLength];
	}
	@catch(NSException* localException) {
		[usbLock unlock];
		[localException raise];
	}
	
	[usbLock unlock];
}

- (void) writeBytes:(void*)bytes length:(int)length
{
	[self writeBytes:bytes length:length pipe:0];
}

- (void) writeBytes:(void*)bytes length:(int)length pipe:(int)aPipeIndex
{
	[usbLock lock];
	UInt8 pipe;
	pipe = outPipes[aPipeIndex];
	IOReturn kr = (*interface)->WritePipeTO(interface, pipe, bytes, length,5000,5000);
	if(kr)	{
		kr = (*interface)->GetPipeStatus(interface, pipe);
		if(kr == kIOUSBPipeStalled){
			kr = (*interface)->ClearPipeStallBothEnds(interface, pipe);
			if(kr){
				[usbLock unlock];
				[NSException raise:@"USB Write" format:@"ORUSBInterface.m %u: WritePipe stalled and unable to clear for <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
			}
			else {
				kr = (*interface)->WritePipeTO(interface, pipe, bytes, length,5000,5000);
				if(kr){
					[usbLock unlock];
					[NSException raise:@"USB Write" format:@"ORUSBInterface.m %u: WritePipe failed on second try <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
				}
			}
		}
		else {
			[usbLock unlock];
			[NSException raise:@"USB Write" format:@"ORUSBInterface.m %u: WritePipe failed for <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
		}
	}
	[usbLock unlock];
}


- (int) readUSB488:(char*)resultData length:(unsigned long)amountRead
{
	int bytesRead = 0;
	[usbLock lock];
	@try {
		char buffer[amountRead];
		USB488Header* hp = (USB488Header*)buffer;
		//unsigned long len = amountRead;
		memset(buffer,0,amountRead);
		hp->messageID = 0x02;
		hp->bTag = tag;
		hp->bTagInverse = ~tag;
		hp->transferLength = CFSwapInt32HostToLittle(amountRead);
		hp->eom = 0x00;
		tag++;
		
		[self writeBytes:buffer length:sizeof(USB488Header)];
		
		bytesRead = [self readBytes:buffer length:amountRead];
		
		if(bytesRead>sizeof(USB488Header)){
			memcpy(resultData,&buffer[sizeof(USB488Header)],bytesRead - sizeof(USB488Header));
		}
	}
	@catch(NSException* localException) {
		[usbLock unlock];
		[localException raise];
	}
	[usbLock unlock];
	return bytesRead;
}

- (int) readBytes:(void*)bytes length:(int)length
{
	return [self readBytes:bytes length:length pipe:0];
}

- (int) readBytes:(void*)bytes length:(int)amountRead pipe:(int)aPipeIndex
{
	int result;
    [usbLock lock];
	unsigned long actualRead = amountRead;
	UInt8 pipe = inPipes[aPipeIndex];
	
	IOReturn kr = (*interface)->ReadPipeTO(interface, pipe, bytes, &actualRead, 1000, 1000);
	if(kr)	{
		kr = (*interface)->GetPipeStatus(interface, pipe);
		if(kr == kIOUSBPipeStalled){
			kr = (*interface)->ClearPipeStallBothEnds(interface, pipe);
			if(kr){
				[usbLock unlock];
				[NSException raise:@"USB Read" format:@"ORUSBInterface.m %u: ReadPipe stalled and unable to clear for <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
			}
			else {
				kr = (*interface)->ReadPipeTO(interface, pipe, bytes, &actualRead,1000,1000);
				if(kr){
					[usbLock unlock];
					[NSException raise:@"USB Read" format:@"ORUSBInterface.m %u: ReadPipe failed on second try <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
				}
			}
		}
		else {
			[usbLock unlock];
			[NSException raise:@"USB Read" format:@"ORUSBInterface.m %u: ReadPipe failed for <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
		}
	}
	result = actualRead;
	[usbLock unlock];
	
	return result;
}


- (int) readBytesOnInterruptPipe:(void*)bytes length:(int)amountRead
{
	int result;
    [usbLock lock];
	unsigned long actualRead = amountRead;
	UInt8 pipe;
	if(transferType == kUSBBulk)		 pipe = inPipes[0];
	else if(transferType == kUSBInterrupt) pipe = interruptInPipes[0];
	else pipe = inPipes[0];
	IOReturn kr = (*interface)->ReadPipe(interface, pipe, bytes, &actualRead);
	if(kr)	{
		kr = (*interface)->GetPipeStatus(interface, pipe);
		if(kr == kIOUSBPipeStalled){
			kr = (*interface)->ClearPipeStallBothEnds(interface, pipe);
			if(kr){
				[usbLock unlock];
				[NSException raise:@"USB Write" format:@"ORUSBInterface.m %u: ReadPipe stalled and unable to clear for <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
			}
			else {
				kr = (*interface)->ReadPipe(interface, pipe, bytes, &actualRead);
				if(kr){
					[usbLock unlock];
					[NSException raise:@"USB Read" format:@"ORUSBInterface.m %u: ReadPipe failed on second try <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
				}
			}
		}
		else {
			[usbLock unlock];
			[NSException raise:@"USB Read" format:@"ORUSBInterface.m %u: ReadPipe failed for <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
		}
	}
	result = actualRead;
	[usbLock unlock];
	
	return result;
}
- (int) readBytesOnInterruptPipeNoLock:(void*)bytes length:(int)amountRead
{
	int result;
	unsigned long actualRead = amountRead;
	UInt8 pipe;
	if(transferType == kUSBBulk)		 pipe = inPipes[0];
	else if(transferType == kUSBInterrupt) pipe = interruptInPipes[0];
	else pipe = inPipes[0];
	IOReturn kr = (*interface)->ReadPipe(interface, pipe, bytes, &actualRead);
	if(kr)	{
		kr = (*interface)->GetPipeStatus(interface, pipe);
		if(kr == kIOUSBPipeStalled){
			kr = (*interface)->ClearPipeStallBothEnds(interface, pipe);
			if(kr){
				[NSException raise:@"USB Write" format:@"ORUSBInterface.m %u: ReadPipe stalled and unable to clear for <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
			}
			else {
				kr = (*interface)->ReadPipe(interface, pipe, bytes, &actualRead);
				if(kr){
					[NSException raise:@"USB Read" format:@"ORUSBInterface.m %u: ReadPipe failed on second try <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
				}
			}
		}
		else {
			[NSException raise:@"USB Read" format:@"ORUSBInterface.m %u: ReadPipe failed for <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
		}
	}
	result = actualRead;
	
	return result;
}

- (void) writeBytesOnInterruptPipe:(void*)bytes length:(int)length
{
	[usbLock lock];
	UInt8 pipe;
	if(transferType == kUSBBulk)		 pipe = outPipes[0];
	else if(transferType == kUSBInterrupt) pipe = interruptOutPipes[0];	
    else pipe = outPipes[0];
    
	IOReturn kr = (*interface)->WritePipe(interface, pipe, bytes, length);
	if(kr)	{
		kr = (*interface)->GetPipeStatus(interface, pipe);
		if(kr == kIOUSBPipeStalled){
			kr = (*interface)->ClearPipeStallBothEnds(interface, pipe);
			if(kr){
				[usbLock unlock];
				[NSException raise:@"USB Write" format:@"ORUSBInterface.m %u: WritePipe stalled and unable to clear for <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
			}
			else {
				kr = (*interface)->WritePipe(interface, pipe, bytes, length);
				if(kr){
					[usbLock unlock];
					[NSException raise:@"USB Write" format:@"ORUSBInterface.m %u: WritePipe failed on second try <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
				}
			}
		}
		else {
			[usbLock unlock];
			[NSException raise:@"USB Write" format:@"ORUSBInterface.m %u: WritePipe failed for <%@> error: 0x%x\n", __LINE__,NSStringFromClass([self class]),kr];
		}
	}
	[usbLock unlock];
}


- (int) readBytesFastNoThrow:(void*)bytes length:(int)amountRead
{
	int result;
	[usbLock lock];
	UInt8 pipe;
	pipe = inPipes[0];
	unsigned long actualRead = amountRead;
	IOReturn kr = (*interface)->ReadPipeTO(interface, pipe, bytes, &actualRead, 10, 10);
	if(kr)	{
		kr = (*interface)->GetPipeStatus(interface, pipe);
		if(kr == kIOUSBPipeStalled){
			(*interface)->ClearPipeStallBothEnds(interface, pipe);
		}
		actualRead = 0;
	}
	result = actualRead;
	[usbLock unlock];
	return result;
}

- (void) setInPipes:(unsigned char*)aPipeRef numberPipes:(int)n
{
	int i;
	for(i=0;i<n;i++)inPipes[i] = aPipeRef[i];
}

- (void) setOutPipes:(unsigned char*)aPipeRef numberPipes:(int)n
{
	int i;
	for(i=0;i<n;i++)outPipes[i] = aPipeRef[i];
}

- (void) setControlPipes:(unsigned char*)aPipeRef numberPipes:(int)n
{
	int i;
	for(i=0;i<n;i++)controlPipes[i] = aPipeRef[i];
}

- (void) setInterruptInPipes:(unsigned char*)aPipeRef numberPipes:(int)n
{
	int i;
	for(i=0;i<n;i++)interruptInPipes[i] = aPipeRef[i];
}

- (void) setInterruptOutPipes:(unsigned char*)aPipeRef numberPipes:(int)n
{
	int i;
	for(i=0;i<n;i++)interruptOutPipes[i] = aPipeRef[i];
}

- (NSString*)   connectionState
{
	return @"--";
}
- (void) setConnectionState:(NSString*)aState
{
    [connectionState autorelease];
    connectionState = [aState copy];    
	
}

- (NSString*) description
{
	NSString* s = [NSString stringWithFormat:@"HW Object: %@\n",deviceName];
	if(registeredObject){
		s = [s stringByAppendingFormat:@"SW Object: %@\n",[registeredObject className]];
	}
	else      s = [s stringByAppendingString:@"SW Object: ---\n"];
	s = [s stringByAppendingFormat:@"Location : 0x%lx\n",locationID];
	if(serialNumber){
		s = [s stringByAppendingFormat:@"Serial # : %@\n",serialNumber];
	}
	if(inPipes[0]){
		s = [s stringByAppendingFormat:@"In Pipe  : 0x%x\n",inPipes[0]];
	}
	else	  s = [s stringByAppendingString:@"In Pipe  : ?\n"];
	if(outPipes[0]){
		s = [s stringByAppendingFormat:@"Out Pipe : 0x%x\n",outPipes[0]];
	}
	else	  s = [s stringByAppendingString:@"Out Pipe : ?\n"];
	if(controlPipes[0]){
		s = [s stringByAppendingFormat:@"Control Pipe : 0x%x\n",outPipes[0]];
	}
	else	  s = [s stringByAppendingString:@"Control Pipe : ?\n"];
	return s;
}



#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super init];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
}

@end


