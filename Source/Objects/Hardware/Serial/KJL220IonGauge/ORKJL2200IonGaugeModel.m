//--------------------------------------------------------
// ORKJL2200IonGaugeModel
// Created by Mark  A. Howe on Fri Jul 22 2005
// Created by Mark  A. Howe on Thurs Apr 22 2010
// Copyright (c) 2010 University of North Caroline. All rights reserved.
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

#import "ORKJL2200IonGaugeModel.h"
#import "ORSerialPort.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORTimeRate.h"

#pragma mark ***External Strings
NSString* ORKJL2200IonGaugeModelSetPointReadChanged = @"ORKJL2200IonGaugeModelSetPointReadChanged";
NSString* ORKJL2200IonGaugeModelDegasTimeReadChanged = @"ORKJL2200IonGaugeModelDegasTimeReadChanged";
NSString* ORKJL2200IonGaugeModelEmissionReadChanged = @"ORKJL2200IonGaugeModelEmissionReadChanged";
NSString* ORKJL2200IonGaugeModelSensitivityReadChanged = @"ORKJL2200IonGaugeModelSensitivityReadChanged";
NSString* ORKJL2200IonGaugeModelDegasTimeChanged		= @"ORKJL2200IonGaugeModelDegasTimeChanged";
NSString* ORKJL2200IonGaugeModelEmissionCurrentChanged	= @"ORKJL2200IonGaugeModelEmissionCurrentChanged";
NSString* ORKJL2200IonGaugeModelSensitivityChanged		= @"ORKJL2200IonGaugeModelSensitivityChanged";
NSString* ORKJL2200IonGaugeModelSetPointChanged			= @"ORKJL2200IonGaugeModelSetPointChanged";
NSString* ORKJL2200IonGaugeModelSetPointReadBackChanged			= @"ORKJL2200IonGaugeModelSetPointReadBackChanged";
NSString* ORKJL2200IonGaugePressureChanged				= @"ORKJL2200IonGaugePressureChanged";
NSString* ORKJL2200IonGaugeShipPressureChanged			= @"ORKJL2200IonGaugeShipPressureChanged";
NSString* ORKJL2200IonGaugePollTimeChanged				= @"ORKJL2200IonGaugePollTimeChanged";
NSString* ORKJL2200IonGaugeSerialPortChanged			= @"ORKJL2200IonGaugeSerialPortChanged";
NSString* ORKJL2200IonGaugePortNameChanged				= @"ORKJL2200IonGaugePortNameChanged";
NSString* ORKJL2200IonGaugePortStateChanged				= @"ORKJL2200IonGaugePortStateChanged";
NSString* ORKJL2200IonGaugeModelStateMaskChanged		= @"ORKJL2200IonGaugeModelStateMaskChanged";
NSString* ORKJL2200IonGaugeLock							= @"ORKJL2200IonGaugeLock";
NSString* ORKJL2200IonGaugeModelPressureScaleChanged	= @"ORKJL2200IonGaugeModelPressureScaleChanged";
NSString* ORKJL2200IonGaugeModelQueCountChanged			= @"ORKJL2200IonGaugeModelQueCountChanged";

@interface ORKJL2200IonGaugeModel (private)
- (void) runStarted:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;
- (void) decodeCommand:(NSString*)aCmd;
- (void) timeout;
- (void) processOneCommandFromQueue;
@end

@implementation ORKJL2200IonGaugeModel
- (id) init
{
	self = [super init];
    [self registerNotificationObservers];

	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [portName release];
	
    if([serialPort isOpen]){
        [serialPort close];
    }
    [serialPort release];
	[timeRate release];
    [buffer release];
	[cmdQueue release];
	[lastRequest release];

	[super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"KJL2200IonGauge"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORKJL2200IonGaugeController"];
}

//- (NSString*) helpURL
//{
//	return @"RS232/LakeShore_210.html";
//}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(dataReceived:)
                         name : ORSerialPortDataReceived
                       object : nil];

    [notifyCenter addObserver: self
                     selector: @selector(runStarted:)
                         name: ORRunStartedNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStopped:)
                         name: ORRunStoppedNotification
                       object: nil];

}

- (void) dataReceived:(NSNotification*)note
{
    if([note object] == serialPort){
		//if(!lastRequest)return;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
        NSString* theString = [[[[NSString alloc] initWithData:[[note userInfo] objectForKey:@"data"] 
												      encoding:NSASCIIStringEncoding] autorelease] uppercaseString];

		//the serial port may break the data up into small chunks, so we have to accumulate the chunks until
		//we get a full piece.
        theString = [[theString componentsSeparatedByString:@"\n"] componentsJoinedByString:@""];
        if(!buffer)buffer = [[NSMutableString string] retain];
        [buffer appendString:theString];					
		
        do {
            NSRange lineRange = [buffer rangeOfString:@"\r"];
            if(lineRange.location!= NSNotFound){
                NSMutableString* theResponse = [[[buffer substringToIndex:lineRange.location+1] mutableCopy] autorelease];
                [buffer deleteCharactersInRange:NSMakeRange(0,lineRange.location+1)];      //take the cmd out of the buffer
				[self decodeCommand:theResponse];
            }
        } while([buffer rangeOfString:@"\r"].location!= NSNotFound);
	}
}


- (void) shipPressureValue
{
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		uint32_t data[4];
		data[0] = dataId | 4;
		data[1] =  ([self uniqueIdNumber]&0x0000fffff);
		
		union {
			float asFloat;
			uint32_t asLong;
		}theData;
		theData.asFloat = pressure;
		data[2] = theData.asLong;
		data[3] = timeMeasured;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(int32_t)*4]];
	}
}


#pragma mark ***Accessors

- (int) degasTimeRead
{
    return degasTimeRead;
}

- (void) setDegasTimeRead:(int)aDegasTimeRead
{
    degasTimeRead = aDegasTimeRead;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelDegasTimeReadChanged object:self];
}

- (float) emissionRead
{
    return emissionRead;
}

- (void) setEmissionRead:(float)aEmissionRead
{
    emissionRead = aEmissionRead;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelEmissionReadChanged object:self];
}

- (int) sensitivityRead
{
    return sensitivityRead;
}

- (void) setSensitivityRead:(int)aSensitivityRead
{
    sensitivityRead = aSensitivityRead;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelSensitivityReadChanged object:self];
}
- (NSUInteger) queCount
{
	return [cmdQueue count];
}
- (float) pressureScaleValue
{
	return pressureScaleValue;
}

- (int) pressureScale
{
    return pressureScale;
}

- (void) setPressureScale:(int)aPressureScale
{
	if(aPressureScale<0)aPressureScale=0;
	else if(aPressureScale>11)aPressureScale=11;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setPressureScale:pressureScale];
    
    pressureScale = aPressureScale;
	
	pressureScaleValue = powf(10.,(float)pressureScale);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelPressureScaleChanged object:self];
}

- (void) setStateMask:(unsigned short)aMask
{
	stateMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelStateMaskChanged object:self];
}

- (unsigned short)stateMask
{
	return stateMask;
}

- (int) degasTime
{
    return degasTime;
}

- (void) setDegasTime:(int)aDegasTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDegasTime:degasTime];
    
    degasTime = aDegasTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelDegasTimeChanged object:self];
}

- (float) emissionCurrent
{
    return emissionCurrent;
}

- (void) setEmissionCurrent:(float)aValue
{
	if(aValue<1)aValue = 1;
	else if(aValue>25.5)aValue=25.5;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setEmissionCurrent:emissionCurrent];
    
    emissionCurrent = aValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelEmissionCurrentChanged object:self];
}

- (int) sensitivity
{
    return sensitivity;
}

- (void) setSensitivity:(int)aValue
{
	if(aValue<1)aValue = 1;
	else if(aValue>80)aValue=80;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setSensitivity:sensitivity];
    
    sensitivity = aValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelSensitivityChanged object:self];
}

- (float) setPoint:(int)index
{
	if(index>=0 && index<4)return setPoint[index];
	else return 0;
}

- (void) setSetPoint:(int)index withValue:(float)aSetPoint
{
	if(index>=0 && index<4){
		[[[self undoManager] prepareWithInvocationTarget:self] setSetPoint:index withValue:setPoint[index]];
    
		setPoint[index] = aSetPoint;

		[[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelSetPointChanged object:self];
	}
}

- (float) setPointReadBack:(int)index
{
	if(index>=0 && index<4)return setPointReadBack[index];
	else return 0;
}

- (void) setSetPointReadBack:(int)index withValue:(float)aSetPoint
{
	if(index>=0 && index<4){
		setPointReadBack[index] = aSetPoint;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelSetPointReadBackChanged object:self];
	}
}

- (float) pressure
{
    return pressure;
}

- (void) setPressure:(float)aPressure
{
    pressure = aPressure;
	//get the time(UT!)
	time_t	ut_Time;
	time(&ut_Time);
	//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
	timeMeasured = (uint32_t)ut_Time;
		
	if(timeRate == nil) timeRate = [[ORTimeRate alloc] init];
	[timeRate addDataToTimeAverage:aPressure];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugePressureChanged object:self];
}

- (void) readPressure
{
	[self enqueCmdData:@"=RV\r"];
}
- (void) getStatus
{
	[self enqueCmdData:@"=R*\r"];
}

- (ORTimeRate*)timeRate
{
	return timeRate;
}

- (BOOL) shipPressure
{
    return shipPressure;
}

- (void) setShipPressure:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipPressure:shipPressure];
    
    shipPressure = aFlag;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeShipPressureChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugePollTimeChanged object:self];

	if(pollTime){
		[self performSelector:@selector(pollPressure) withObject:nil afterDelay:2];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollPressure) object:nil];
	}
}

- (void) pollPressure
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollPressure) object:nil];
	[self getStatus];
	[self readPressure];
	if(pollTime){
		[self performSelector:@selector(pollPressure) withObject:nil afterDelay:pollTime];
	}
}


- (uint32_t) timeMeasured
{
	return timeMeasured;
}
- (NSString*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(NSString*)aRequest
{
    [lastRequest autorelease];
    lastRequest = [aRequest copy];
}

- (BOOL) portWasOpen
{
    return portWasOpen;
}

- (void) setPortWasOpen:(BOOL)aPortWasOpen
{
    portWasOpen = aPortWasOpen;
}

- (NSString*) portName
{
    return portName;
}

- (void) setPortName:(NSString*)aPortName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortName:portName];
    
    if(![aPortName isEqualToString:portName]){
        [portName autorelease];
        portName = [aPortName copy];    

        BOOL valid = NO;
        NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
        ORSerialPort *aPort;
        while ((aPort = [enumerator nextObject])) {
            if([portName isEqualToString:[aPort name]]){
                [self setSerialPort:aPort];
                if(portWasOpen){
                    [self openPort:YES];
                 }
                valid = YES;
                break;
            }
        } 
        if(!valid){
            [self setSerialPort:nil];
        }       
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugePortNameChanged object:self];
}

- (ORSerialPort*) serialPort
{
    return serialPort;
}

- (void) setSerialPort:(ORSerialPort*)aSerialPort
{
    [aSerialPort retain];
    [serialPort release];
    serialPort = aSerialPort;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeSerialPortChanged object:self];
}

- (void) openPort:(BOOL)state
{
    if(state) {
		[serialPort open];
		[serialPort setParityNone];
		[serialPort setStopBits2:0];
		[serialPort setDataBits:8];
		[serialPort setSpeed:2400];
		[serialPort commitChanges];
	}

    else  {
		[serialPort close];
	}
    portWasOpen = [serialPort isOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugePortStateChanged object:self];
    
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	[self setPressureScale:[decoder decodeIntForKey:@"pressureScale"]];
	[self setDegasTime:		 [decoder decodeIntForKey:@"degasTime "]];
	[self setEmissionCurrent:[decoder decodeFloatForKey:@"emissionCurrent"]];
	[self setSensitivity:	 [decoder decodeIntForKey:@"sensitivity"]];
	[self setShipPressure:	 [decoder decodeBoolForKey:@"shipPressure"]];
	[self setPollTime:		 [decoder decodeIntForKey:@"pollTime"]];
	[self setPortWasOpen:	 [decoder decodeBoolForKey:@"portWasOpen"]];
    [self setPortName:		 [decoder decodeObjectForKey: @"portName"]];
	[[self undoManager] enableUndoRegistration];
	timeRate = [[ORTimeRate alloc] init];
	
	int i;
	for(i=0;i<4;i++){
		[self setSetPoint:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"setPoint%d",i]]];
	}
		 
    [self registerNotificationObservers];

	return self;
}
- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:pressureScale forKey:@"pressureScale"];
    [encoder encodeInteger:degasTime forKey:@"degasTime "];
    [encoder encodeFloat:emissionCurrent forKey:@"emissionCurrent"];
    [encoder encodeInteger:sensitivity forKey:@"sensitivity"];
    [encoder encodeBool:shipPressure forKey:@"shipPressure"];
    [encoder encodeInteger:pollTime		forKey:@"pollTime"];
    [encoder encodeBool:portWasOpen forKey:@"portWasOpen"];
    [encoder encodeObject:portName	forKey: @"portName"];
	int i;
	for(i=0;i<4;i++){
		[encoder encodeFloat:setPoint[i] forKey:[NSString stringWithFormat:@"setPoint%d",i]];
	}
}

#pragma mark *** Commands
- (void) enqueCmdData:(NSString*)aCommand
{
	if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
	
	[cmdQueue addObject:[[aCommand copy] autorelease]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelQueCountChanged object: self];
	if(!lastRequest)[self processOneCommandFromQueue];
}

- (void) initBoard
{
	NSString* aCmd;
	[self enqueCmdData:[NSString stringWithFormat:@"=SS:%d\r",sensitivity]];
	[self enqueCmdData:[NSString stringWithFormat:@"=SE:%.1f\r",emissionCurrent]];
	[self enqueCmdData:[NSString stringWithFormat:@"=ST:%.0f\r",degasTime]];
	int i;
	for(i=0;i<4;i++){
		if([self setPoint:i]!=0) aCmd = [NSString stringWithFormat:@"=S%d:%.1E\r",i+1,setPoint[i]];
		else aCmd = [NSString stringWithFormat:@"=S%d:0.0E-00\r",i+1];
		aCmd = [aCmd stringByReplacingOccurrencesOfString:@"E-" withString:@"-"];
		[self enqueCmdData:aCmd];
	}
	[self getStatus];
	[self readSettings];

}

- (void) readSettings
{
	[self enqueCmdData:@"=RS\r"];
	[self enqueCmdData:@"=RE\r"];
	[self enqueCmdData:@"=RT\r"];
	[self enqueCmdData:@"=R1\r"];
	[self enqueCmdData:@"=R2\r"];
	[self enqueCmdData:@"=R3\r"];
	[self enqueCmdData:@"=R4\r"];
}

- (void) turnOn
{
	[self enqueCmdData:@"=SF1\r"];
}

- (void) turnOff
{
	[self enqueCmdData:@"=SF0\r"];
}

- (void) turnDegasOn
{
	[self enqueCmdData:@"=SD1\r"];
}

- (void) turnDegasOff
{
	[self enqueCmdData:@"=SD0\r"];
}

- (void) sendReset
{
	[cmdQueue removeAllObjects];
	[self setLastRequest:nil];
	[self enqueCmdData:@"=X\r"];
}

#pragma mark ***Data Records
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherKJL2200IonGauge
{
    [self setDataId:[anotherKJL2200IonGauge dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"KJL2200IonGaugeModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORKJL2200IonGaugeDecoderForPressure",@"decoder",
        [NSNumber numberWithLong:dataId],   @"dataId",
        [NSNumber numberWithBool:NO],       @"variable",
        [NSNumber numberWithLong:18],       @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Pressure"];
    
    return dataDictionary;
}

@end

@implementation ORKJL2200IonGaugeModel (private)
- (void) runStarted:(NSNotification*)aNote
{
}

- (void) runStopped:(NSNotification*)aNote
{
}

- (void) decodeCommand:(NSString*)aCmd
{
	BOOL commandEcho = NO;
	aCmd = [aCmd stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	if([aCmd hasPrefix:@"="]){
		commandEcho = YES;
	}
	else if([aCmd hasPrefix:@"V="]){
		NSString* value = [[aCmd substringFromIndex:2] stringByReplacingOccurrencesOfString:@"-" withString:@"E-"];
		[self setPressure:[value floatValue]];
		[self shipPressure];
	}
	else if([aCmd hasPrefix:@"*="]){
		aCmd = [aCmd substringFromIndex:2];
		int i;
		int n = (int)[aCmd length];
		unsigned short aMask = 0;
		for(i=0;i<n;i++){
			if([aCmd characterAtIndex:i] == '1'){
				aMask |= (1<<i);
			}
		}
		[self setStateMask:aMask];
	}
	else if([aCmd hasPrefix:@"F="]){
		[self performSelector:@selector(pollPressure) withObject:nil afterDelay:10];
	}
	else if([aCmd hasPrefix:@"D="]){
		[self performSelector:@selector(pollPressure) withObject:nil afterDelay:10];
	}
	else if([aCmd hasPrefix:@"S="]){
		[self setSensitivityRead:[[aCmd substringFromIndex:2] intValue]];
		[self performSelector:@selector(pollPressure) withObject:nil afterDelay:10];
	}
	else if([aCmd hasPrefix:@"E="]){
		[self setEmissionRead:[[aCmd substringFromIndex:2] floatValue]];
	}
	else if([aCmd hasPrefix:@"T="]){
		[self setDegasTimeRead:[[aCmd substringFromIndex:2] intValue]];
	}
	else if([aCmd hasPrefix:@"1="]){
		NSString* value = [[aCmd substringFromIndex:2] stringByReplacingOccurrencesOfString:@"-" withString:@"E-"];
		[self setSetPointReadBack:0 withValue:[value floatValue]];
	}
	else if([aCmd hasPrefix:@"2="]){
		NSString* value = [[aCmd substringFromIndex:2] stringByReplacingOccurrencesOfString:@"-" withString:@"E-"];
		[self setSetPointReadBack:1 withValue:[value floatValue]];
	}
	else if([aCmd hasPrefix:@"3="]){
		NSString* value = [[aCmd substringFromIndex:2] stringByReplacingOccurrencesOfString:@"-" withString:@"E-"];
		[self setSetPointReadBack:2 withValue:[value floatValue]];
	}
	else if([aCmd hasPrefix:@"4="]){
		NSString* value = [[aCmd substringFromIndex:2] stringByReplacingOccurrencesOfString:@"-" withString:@"E-"];
		[self setSetPointReadBack:3 withValue:[value floatValue]];
	}
	else if([aCmd hasSuffix:@"OK"]){
	}
	else if([aCmd hasSuffix:@"On"]){
	}
	else if([aCmd hasSuffix:@"Off"]){
	}
	else if([aCmd hasPrefix:@"Error 1"]){
	}
	else if([aCmd hasPrefix:@"Error 2"]){
	}
	else if([aCmd hasPrefix:@"Error 3"]){
	}
	else if([aCmd hasPrefix:@"IGS"]){
	}
	
	if(!commandEcho){
		[self setLastRequest:nil];			 //clear the last request
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
		[self processOneCommandFromQueue];	 //do the next command in the queue
	}
}

- (void) timeout
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"command timeout",@"KJL IonGauge",nil);
	[self setLastRequest:nil];
	[cmdQueue removeAllObjects]; //if we timeout we just flush the queue
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelQueCountChanged object: self];
}

- (void) processOneCommandFromQueue
{
	if([cmdQueue count] == 0) return;
	NSString* aCommand = [[[cmdQueue objectAtIndex:0] retain] autorelease];
	[cmdQueue removeObjectAtIndex:0];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORKJL2200IonGaugeModelQueCountChanged object: self];
	
	[self setLastRequest:aCommand];
	[serialPort writeString:aCommand];

	[self performSelector:@selector(timeout) withObject:nil afterDelay:1];
	
}
@end
