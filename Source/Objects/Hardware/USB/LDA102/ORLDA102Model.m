//
//  ORLDA102Model.m
//  Orca
//
//  USB Relay I/O Interface
//
//  Created by Mark Howe on Wed Feb 18, 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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
#import "ORLDA102Model.h"
#import "ORUSBInterface.h"

NSString* ORLDA102ModelRampRunningChanged = @"ORLDA102ModelRampRunningChanged";
NSString* ORLDA102ModelRepeatRampChanged	= @"ORLDA102ModelRepeatRampChanged";
NSString* ORLDA102ModelIdleTimeChanged		= @"ORLDA102ModelIdleTimeChanged";
NSString* ORLDA102ModelDwellTimeChanged		= @"ORLDA102ModelDwellTimeChanged";
NSString* ORLDA102ModelRampEndChanged		= @"ORLDA102ModelRampEndChanged";
NSString* ORLDA102ModelRampStartChanged		= @"ORLDA102ModelRampStartChanged";
NSString* ORLDA102ModelStepSizeChanged		= @"ORLDA102ModelStepSizeChanged";
NSString* ORLDA102ModelAttenuationChanged	= @"ORLDA102ModelAttenuationChanged";
NSString* ORLDA102ModelSerialNumberChanged	= @"ORLDA102ModelSerialNumberChanged";
NSString* ORLDA102ModelUSBInterfaceChanged	= @"ORLDA102ModelUSBInterfaceChanged";
NSString* ORLDA102ModelRampValueChanged		= @"ORLDA102ModelRampValueChanged";
NSString* ORLDA102USBInConnection			= @"ORLDA102USBInConnection";
NSString* ORLDA102USBNextConnection			= @"ORLDA102USBNextConnection";
NSString* ORLDA102ModelLock					= @"ORLDA102ModelLock";

#define kLDA102DriverPath @"/System/Library/Extensions/LDA102.kext"
#define kdBPerValue 4

//set commands
#define kSetAttenuation 0x8D
#define kSetDwellTime   0xB3
#define kSetStartAtt    0xB0
#define kSetStopAtt     0xB1
#define kSetStepSize    0xB2
#define kSetWaitTime    0xB6
#define kSetRampState	0x89

//ramp state
#define kSingleRamp		0x01
#define kStopRamp		0x00
#define kContinousRamp	0x02

//read commands
#define kGetAttenuation 0x0D
#define kGetDwellTime   0x33
#define kGetStartAtt    0x30
#define kGetStopAtt     0x31
#define kGetStepSize    0x32
#define kGetWaitTime    0x36
#define kGetRampState	0x09
#define kGetMaxAtt		0x35

//response commands
#define kAttStatus	0x04

@implementation ORLDA102Model
- (void) makeConnectors
{
	ORConnector* connectorObj1 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( 0, [self frame].size.height-20 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj1 forKey: ORLDA102USBInConnection ];
	[ connectorObj1 setConnectorType: 'USBI' ];
	[ connectorObj1 addRestrictedConnectionType: 'USBO' ]; //can only connect to usb outputs
	[connectorObj1 setOffColor:[NSColor yellowColor]];
	[ connectorObj1 release ];
	
	ORConnector* connectorObj2 = [[ ORConnector alloc ] 
								  initAt: NSMakePoint( [self frame].size.width-kConnectorSize, 10 )
								  withGuardian: self];
	[[ self connectors ] setObject: connectorObj2 forKey: ORLDA102USBNextConnection ];
	[ connectorObj2 setConnectorType: 'USBO' ];
	[ connectorObj2 addRestrictedConnectionType: 'USBI' ]; //can only connect to usb inputs
	[connectorObj2 setOffColor:[NSColor yellowColor]];
	[ connectorObj2 release ];
}

- (void) makeMainController
{
    [self linkToController:@"ORLDA102Controller"];
}

- (NSString*) helpURL
{
	return @"USB/LDA120.html";
}


- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[noUSBAlarm clearAlarm];
	[noUSBAlarm release];
    [noDriverAlarm clearAlarm];
    [noDriverAlarm release];
    [serialNumber release];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		[self connectionChanged];
		
		//make sure the driver is installed.
		NSFileManager* fm = [NSFileManager defaultManager];
		if(![fm fileExistsAtPath:kLDA102DriverPath]){
			NSLogColor([NSColor redColor],@"*** Unable To Locate LDA102 Driver ***\n");
			if(!noDriverAlarm){
				noDriverAlarm = [[ORAlarm alloc] initWithName:@"No LDA102 Driver Found" severity:0];
				[noDriverAlarm setSticky:NO];
				[noDriverAlarm setHelpStringFromFile:@"NoLDA102DriverHelp"];
			}                      
			[noDriverAlarm setAcknowledged:NO];
			[noDriverAlarm postAlarm];
		}
	}
	@catch(NSException* localException) {
	}
}

- (void) connectionChanged
{
	NSArray* interfaces = [[self getUSBController] interfacesForVender:[self vendorID] product:[self productID]];
	NSString* sn = serialNumber;
	if([interfaces count] == 1 && ![sn length]){
		sn = [[interfaces objectAtIndex:0] serialNumber];
	}
	[self setSerialNumber:sn]; //to force usbinterface at doc startup
	[self checkUSBAlarm];
	[[self objectConnectedTo:ORLDA102USBNextConnection] connectionChanged];
}

- (void) setGuardian:(id)aGuardian
{
	[super setGuardian:aGuardian];
	[self checkUSBAlarm];

}

-(void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so we can draw into it.
    //---------------------------------------------------------------------------------------------------
	NSImage* aCachedImage = [NSImage imageNamed:@"LDA102"];
    if(!usbInterface){
		NSSize theIconSize = [aCachedImage size];

		NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
		[i lockFocus];
		
        [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];		
		if(!usbInterface || ![self getUSBController]){
			NSBezierPath* path = [NSBezierPath bezierPath];
			[path moveToPoint:NSMakePoint(20,10)];
			[path lineToPoint:NSMakePoint(40,30)];
			[path moveToPoint:NSMakePoint(40,10)];
			[path lineToPoint:NSMakePoint(20,30)];
			[path setLineWidth:3];
			[[NSColor redColor] set];
			[path stroke];
		}    
		
		[i unlockFocus];
		
		[self setImage:i];
		[i release];
    }
	else {
		[ self setImage: aCachedImage];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORForceRedraw object: self];
}

- (NSString*) title 
{
	return [NSString stringWithFormat:@"LDA102 (Serial# %@)",[usbInterface serialNumber]];
}

- (NSUInteger) vendorID
{
	return 0x041F;
}

- (NSUInteger) productID
{
	return 0x1207;	//LDA102 ID
}

- (id) getUSBController
{
	id obj = [self objectConnectedTo:ORLDA102USBInConnection];
	id cont =  [ obj getUSBController ];
	return cont;
}

#pragma mark ***Accessors

- (BOOL) rampRunning
{
    return rampRunning;
}

- (void) setRampRunning:(BOOL)aRampRunning
{
    rampRunning = aRampRunning;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLDA102ModelRampRunningChanged object:self];
}

- (float) rampValue
{
    return rampValue;
}

- (void) setRampValue:(float)aRampValue
{
    rampValue = aRampValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLDA102ModelRampValueChanged object:self];
	
}

- (BOOL) repeatRamp
{
    return repeatRamp;
}

- (void) setRepeatRamp:(BOOL)aRepeatRamp
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatRamp:repeatRamp];
    repeatRamp = aRepeatRamp;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLDA102ModelRepeatRampChanged object:self];
}

- (int) idleTime
{
    return idleTime;
}

- (void) setIdleTime:(int)aIdleTime
{
	if(aIdleTime<0)			aIdleTime = 0;
	else if(aIdleTime>255)	aIdleTime = 255;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setIdleTime:idleTime];
    idleTime = aIdleTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLDA102ModelIdleTimeChanged object:self];
}

- (short) dwellTime
{
    return dwellTime;
}

- (void) setDwellTime:(short)aDwellTime
{
	if(aDwellTime<10)			aDwellTime = 10;
	else if(aDwellTime>20000)	aDwellTime = 20000;
    [[[self undoManager] prepareWithInvocationTarget:self] setDwellTime:dwellTime];
    dwellTime = aDwellTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLDA102ModelDwellTimeChanged object:self];
}

- (float) rampEnd
{
    return rampEnd;
}

- (void) setRampEnd:(float)aRampEnd
{
	if(aRampEnd<0)			aRampEnd = 0;
	else if(aRampEnd>63)	aRampEnd = 63;
    [[[self undoManager] prepareWithInvocationTarget:self] setRampEnd:rampEnd];
    rampEnd = aRampEnd;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLDA102ModelRampEndChanged object:self];
}

- (float) rampStart
{
    return rampStart;
}

- (void) setRampStart:(float)aRampStart
{
	if(aRampStart<0)			aRampStart = 0;
	else if(aRampStart>63)	aRampStart = 63;
    [[[self undoManager] prepareWithInvocationTarget:self] setRampStart:rampStart];
    rampStart = aRampStart;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLDA102ModelRampStartChanged object:self];
}

- (float) stepSize
{
    return stepSize;
}

- (void) setStepSize:(float)aStepSize
{
	if(aStepSize<.5)		aStepSize = .5;
	else if(aStepSize>63)	aStepSize = 63;
    [[[self undoManager] prepareWithInvocationTarget:self] setStepSize:stepSize];
    stepSize = aStepSize;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLDA102ModelStepSizeChanged object:self];
}

- (float) attenuation
{
    return attenuation;
}

- (void) setAttenuation:(float)aAttenuation
{
	if(aAttenuation<0)			aAttenuation = 0;
	else if(aAttenuation>63)	aAttenuation = 63;
    [[[self undoManager] prepareWithInvocationTarget:self] setAttenuation:attenuation];
    attenuation = aAttenuation;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLDA102ModelAttenuationChanged object:self];
}

- (NSString*) serialNumber
{
    return serialNumber;
}

- (void) setSerialNumber:(NSString*)aSerialNumber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSerialNumber:serialNumber];
    
    [serialNumber autorelease];
    serialNumber = [aSerialNumber copy];    
	
	
	if(!serialNumber){
		[[self getUSBController] releaseInterfaceFor:self];
	}
	else {
		[[self getUSBController] claimInterfaceWithSerialNumber:serialNumber for:self];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLDA102ModelSerialNumberChanged object:self];
}

- (ORUSBInterface*) usbInterface
{
	return usbInterface;
}

- (void) setUsbInterface:(ORUSBInterface*)anInterface
{
	
	[usbInterface release];
	usbInterface = anInterface;
	[usbInterface retain];
	[usbInterface setUsePipeType:kUSBInterrupt];
	//[usbInterface setUsePipeType:kUSBBulk];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName: ORLDA102ModelUSBInterfaceChanged
	 object: self];
	[self checkUSBAlarm];
}

- (void) checkUSBAlarm
{
	if((usbInterface && [self getUSBController]) || !guardian){
		[self startReadThread];
		[noUSBAlarm clearAlarm];
		[noUSBAlarm release];
		noUSBAlarm = nil;
	}
	else {
		if(guardian){
			[self stopReadThread];
			if(!noUSBAlarm){
				noUSBAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"No USB for LDA102"] severity:kHardwareAlarm];
				[noUSBAlarm setSticky:YES];		
			}
			[noUSBAlarm setAcknowledged:NO];
			[noUSBAlarm postAlarm];
		}
	}
	[self setUpImage];
}

- (void) interfaceAdded:(NSNotification*)aNote
{
	[[aNote object] claimInterfaceWithSerialNumber:[self serialNumber] for:self];
}

- (void) interfaceRemoved:(NSNotification*)aNote
{
	ORUSBInterface* theInterfaceRemoved = [[aNote userInfo] objectForKey:@"USBInterface"];
	if((usbInterface == theInterfaceRemoved) && serialNumber){
		[self setUsbInterface:nil];
	}
}

- (NSString*) usbInterfaceDescription
{
	if(usbInterface)return [usbInterface description];
	else return @"?";
}

- (void) registerWithUSB:(id)usb
{
	[usb registerForUSBNotifications:self];
}

- (NSString*) hwName
{
	if(usbInterface)return [usbInterface deviceName];
	else return @"?";
}

- (void) makeUSBClaim:(NSString*)aSerialNumber
{
}

#pragma mark ***Thread methods
- (void) startReadThread
{
	timeToStop = NO;
	[NSThread detachNewThreadSelector:@selector(responseThread) toTarget:self withObject:(id)nil];
}

- (void) stopReadThread
{
	timeToStop = YES;
	//wait for thread to stop
	float timeOut = 1;
	while(threadRunning){
		[ORTimer delay:.01];
		timeOut -= .01;
		if(timeOut<=0)break;
	}
}

- (void) responseThread
{
	threadRunning = YES;
	
	do {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		if(usbInterface && [self getUSBController]){
			//unsigned char data[8];
			//int amountRead = [usbInterface readBytesFastNoThrow:data length:8];
			//if(amountRead == 8){
			//	[self decodeResponse:data];
			//}
		}
		[pool release];
	} while(!timeToStop);
	
	threadRunning = NO;
}

- (void) decodeResponse:(unsigned char*)data
{
	switch(data[0]){
		case kAttStatus:
			[self setRampValue:data[7]/kdBPerValue];
		break;
	}
}

#pragma mark ***HW Access
- (void) loadAttenuation
{
	[self writeCommand:kSetAttenuation count:1 value:attenuation*kdBPerValue];
}

- (void) startRamp
{
	[self setRampRunning:YES];
	[self writeCommand:kSetStartAtt	 count:4 value:rampStart*kdBPerValue];
	[self writeCommand:kSetStopAtt	 count:4 value:rampEnd*kdBPerValue];
	[self writeCommand:kSetStepSize  count:4 value:stepSize*kdBPerValue];
	[self writeCommand:kSetDwellTime count:4 value:dwellTime];
	if(repeatRamp){
		[self writeCommand:kSetWaitTime  count:1 value:idleTime];
		[self writeCommand:kSetRampState  count:1 value:kContinousRamp];
	}
	else {
		[self writeCommand:kSetRampState  count:1 value:kSingleRamp];
	}
}

- (void) stopRamp
{
	[self writeCommand:kSetRampState  count:1 value:kStopRamp];
	[self setRampRunning:NO];
}

- (void) writeCommand:(unsigned char)cmdWord count:(unsigned char)count value:(uint32_t)aValue
{
	if(usbInterface && [self getUSBController]){
		unsigned char data[8];
		memset(data,0,8);
		data[0] = cmdWord;
		data[1] = count;
		[self packData:&data[2] withLong:aValue];
		int i;
		NSLog(@"0: 0x%0x\n",data[0]);
		NSLog(@"1: 0x%0x\n",data[1]);
		for(i=0;i<count;i++){
			NSLog(@"%d: 0x%0x\n",i+2,data[2+i]);
		}
		@try{
			[usbInterface writeBytesOnInterruptPipe:data length:8];
			[ORTimer delay:.03]; //must delay 30ms between commands
		}
		@catch (NSException* localException){
			NSLog(@"USB exception: %@\n",localException);
		}
	}
}

- (void) packData:(unsigned char*)data withLong:(uint32_t)aValue
{
	data[0] = aValue & 0xff;
	data[1] = (aValue>>8) & 0xff;
	data[2] = (aValue>>16) & 0xff;
	data[3] = (aValue>>24) & 0xff;
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setRepeatRamp:	[decoder decodeBoolForKey:@"repeatRamp"]];
    [self setIdleTime:		[decoder decodeIntForKey:	@"idleTime"]];
    [self setDwellTime:		[decoder decodeIntegerForKey:	@"dwellTime"]];
    [self setRampEnd:		[decoder decodeFloatForKey:	@"rampEnd"]];
    [self setRampStart:		[decoder decodeFloatForKey:	@"rampStart"]];
    [self setStepSize:		[decoder decodeFloatForKey:	@"stepSize"]];
    [self setAttenuation:	[decoder decodeIntegerForKey:	@"attenuation"]];
    [self setSerialNumber:	[decoder decodeObjectForKey:@"serialNumber"]];
    [[self undoManager] enableUndoRegistration];    
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:repeatRamp		forKey:@"repeatRamp"];
    [encoder encodeInteger:idleTime			forKey: @"idleTime"];
    [encoder encodeInteger:dwellTime		forKey: @"dwellTime"];
    [encoder encodeFloat:rampEnd		forKey: @"rampEnd"];
    [encoder encodeFloat:rampStart		forKey: @"rampStart"];
    [encoder encodeFloat:stepSize		forKey: @"stepSize"];
    [encoder encodeInteger:attenuation		forKey: @"attenuation"];
    [encoder encodeObject:serialNumber	forKey: @"serialNumber"];
}

@end
