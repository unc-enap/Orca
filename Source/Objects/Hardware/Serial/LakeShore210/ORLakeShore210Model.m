//--------------------------------------------------------
// ORLakeShore210Model
// Created by Mark  A. Howe on Fri Jul 22 2005
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

#import "ORLakeShore210Model.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORTimeRate.h"

#pragma mark ***External Strings
NSString* ORLakeShore210ModelShipTemperaturesChanged	= @"ORLakeShore210ModelShipTemperaturesChanged";
NSString* ORLakeShore210ModelUnitsTypeChanged			= @"ORLakeShore210ModelUnitsTypeChanged";
NSString* ORLakeShore210ModelPollTimeChanged			= @"ORLakeShore210ModelPollTimeChanged";
NSString* ORLakeShore210TempArrayChanged				= @"ORLakeShore210TempArrayChanged";
NSString* ORLakeShore210TempChanged						= @"ORLakeShore210TempChanged";
NSString* ORLakeShore210ModelHighLimitChanged           = @"ORLakeShore210ModelHighLimitChanged";
NSString* ORLakeShore210ModelHighAlarmChanged           = @"ORLakeShore210ModelHighAlarmChanged";
NSString* ORLakeShore210ModelLowLimitChanged            = @"ORLakeShore210ModelLowLimitChanged";
NSString* ORLakeShore210ModelLowAlarmChanged            = @"ORLakeShore210ModelLowAlarmChanged";

NSString* ORLakeShore210Lock = @"ORLakeShore210Lock";

@interface ORLakeShore210Model (private)
- (void) runStarted:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;
- (void) timeout;
- (void) processOneCommandFromQueue;
- (void) process_xrdg_response:(NSString*)theResponse args:(NSArray*)cmdArgs;
- (void) pollTemps;
- (void) postCouchDBRecord;
@end

@implementation ORLakeShore210Model
- (id) init
{
	self = [super init];
    int i;
	for(i=0;i<8;i++){
		lowLimit[i]  = 0; 
		highLimit[i] = 400.0;
		lowAlarm[i]  = 0; 
		highAlarm[i] = 300.0; 
	}	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [buffer release];
	[cmdQueue release];
	[lastRequest release];
 	int i;
	for(i=0;i<8;i++){
		[timeRates[i] release];
	}

	[super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"LakeShore210.tif"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORLakeShore210Controller"];
}

- (NSString*) helpURL
{
	return @"RS232/LakeShore_210.html";
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver: self
                     selector: @selector(runStarted:)
                         name: ORRunStartedNotification
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(runStopped:)
                         name: ORRunStoppedNotification
                       object: nil];
    [super registerNotificationObservers];
}

- (void) dataReceived:(NSNotification*)note
{
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
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
				NSArray* lastCmdParts = [lastRequest componentsSeparatedByString:@" "];
				NSString* lastCmd = [lastCmdParts objectAtIndex:0];

				if([lastCmd isEqualToString: @"SRDG?"])      [self process_xrdg_response:theResponse args:lastCmdParts];
				else if([lastCmd isEqualToString: @"KRDG?"]) [self process_xrdg_response:theResponse args:lastCmdParts];
				else if([lastCmd isEqualToString: @"CRDG?"]) [self process_xrdg_response:theResponse args:lastCmdParts];
		
				[self setLastRequest:nil];			 //clear the last request
				[self processOneCommandFromQueue];	 //do the next command in the queue
            }
        } while([buffer rangeOfString:@"\r"].location!= NSNotFound);
	}
}


- (void) shipTemps
{
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		uint32_t data[18];
		data[0] = dataId | 18;
		data[1] = ((unitsType&0x3)<<16) | ([self uniqueIdNumber]&0x0000fffff);
		
		union {
			float asFloat;
			uint32_t asLong;
		}theData;
		int index = 2;
		int i;
		for(i=0;i<8;i++){
			theData.asFloat = temp[i];
			data[index] = theData.asLong;
			index++;
			
			data[index] = timeMeasured[i];
			index++;
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(int32_t)*18]];
	}
}


#pragma mark ***Accessors

- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
	return [super acceptsGuardian:aGuardian] ||
    [aGuardian isMemberOfClass:NSClassFromString(@"ORMJDVacuumModel")] ||
    [aGuardian isMemberOfClass:NSClassFromString(@"ORMJDPumpCartModel")];
}

- (ORTimeRate*)timeRate:(int)index
{
	return timeRates[index];
}

- (BOOL) shipTemperatures
{
    return shipTemperatures;
}

- (void) setShipTemperatures:(BOOL)aShipTemperatures
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipTemperatures:shipTemperatures];
    shipTemperatures = aShipTemperatures;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore210ModelShipTemperaturesChanged object:self];
}

- (int) unitsType
{
    return unitsType;
}

- (void) setUnitsType:(int)aType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUnitsType:unitsType];
    unitsType = aType;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore210ModelUnitsTypeChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore210ModelPollTimeChanged object:self];

	if(pollTime){
		[self performSelector:@selector(pollTemps) withObject:nil afterDelay:2];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollTemps) object:nil];
	}
}

- (float) temp:(int)index
{
	if(index>=0 && index<8)return temp[index];
	else return 0.0;
}

- (uint32_t) timeMeasured:(int)index
{
	if(index>=0 && index<8)return timeMeasured[index];
	else return 0;
}

- (void) setTemp:(int)index value:(float)aValue;
{
	if(index>=0 && index<8){
		temp[index] = aValue;
		//get the time(UT!)
		time_t	ut_Time;
		time(&ut_Time);
		//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		timeMeasured[index] = (uint32_t)ut_Time;

		[[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore210TempChanged 
															object:self 
														userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:@"Channel"]];

		if(timeRates[index] == nil) timeRates[index] = [[ORTimeRate alloc] init];
		[timeRates[index] addDataToTimeAverage:aValue];

	}
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


- (void) setUpPort
{
    [serialPort setSpeed:9600];
    [serialPort setParityOdd];
    [serialPort setStopBits2:1];
    [serialPort setDataBits:7];
}

- (double) lowLimit:(int)aChan
{
	if(aChan>=0 && aChan<8)return lowLimit[aChan];
	else return 1;
}

- (void) setLowLimit:(int)aChan value:(double)aValue
{
	if(aChan>=0 && aChan<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:aChan value:lowLimit[aChan]];
		lowLimit[aChan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore210ModelLowLimitChanged object:self];
	}
}
- (double) highLimit:(int)aChan
{
	if(aChan>=0 && aChan<8)return highLimit[aChan];
	else return 100;
}

- (void) setHighLimit:(int)aChan value:(double)aValue
{
	if(aChan>=0 && aChan<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setHighLimit:aChan value:highLimit[aChan]];
		highLimit[aChan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore210ModelHighLimitChanged object:self];
	}
}
- (double) lowAlarm:(int)aChan
{
	if(aChan>=0 && aChan<8)return lowAlarm[aChan];
	else return 300;
}

- (void) setLowAlarm:(int)aChan value:(double)aValue
{
	if(aChan>=0 && aChan<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setHighAlarm:aChan value:lowAlarm[aChan]];
		lowAlarm[aChan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore210ModelLowAlarmChanged object:self];
	}
}

- (double) highAlarm:(int)aChan
{
	if(aChan>=0 && aChan<8)return highAlarm[aChan];
	else return 1;
}

- (void) setHighAlarm:(int)aChan value:(double)aValue
{
	if(aChan>=0 && aChan<8){
		[[[self undoManager] prepareWithInvocationTarget:self] setHighAlarm:aChan value:highAlarm[aChan]];
		highAlarm[aChan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore210ModelHighAlarmChanged object:self];
	}
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	
	BOOL oldUnits = [decoder containsValueForKey:	@"ORLakeShore210ModelDegreesInKelvin"];
	if(oldUnits) [self setUnitsType: [decoder decodeBoolForKey: @"ORLakeShore210ModelDegreesInKelvin"]];
	else		 [self setUnitsType: [decoder decodeIntForKey:	 @"unitsType"]];
	
	[self setShipTemperatures:	[decoder decodeBoolForKey:	@"ORLakeShore210ModelShipTemperatures"]];
	[self setPollTime:			[decoder decodeIntForKey:	@"ORLakeShore210ModelPollTime"]];
	[[self undoManager] enableUndoRegistration];
	int i;
	for(i=0;i<8;i++){
        timeRates[i] = [[ORTimeRate alloc] init];
		[self setLowAlarm:i value:[decoder decodeDoubleForKey: [NSString stringWithFormat:@"lowAlarm%d",i]]];
		[self setHighAlarm:i value:[decoder decodeDoubleForKey: [NSString stringWithFormat:@"highAlarm%d",i]]];
		[self setLowLimit:i value:[decoder decodeDoubleForKey: [NSString stringWithFormat:@"lowLimit%d",i]]];
		[self setHighLimit:i value:[decoder decodeDoubleForKey: [NSString stringWithFormat:@"highLimit%d",i]]];
    }
    [self registerNotificationObservers];

	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:shipTemperatures	forKey: @"ORLakeShore210ModelShipTemperatures"];
    [encoder encodeInteger:unitsType			forKey: @"unitsType"];
    [encoder encodeInteger: pollTime			forKey: @"ORLakeShore210ModelPollTime"];
	int i;
	for(i=0;i<8;i++){
		[encoder encodeDouble:lowAlarm[i] forKey: [NSString stringWithFormat:@"lowAlarm%d",i]];
		[encoder encodeDouble:lowLimit[i] forKey: [NSString stringWithFormat:@"lowLimit%d",i]];
		[encoder encodeDouble:highAlarm[i] forKey: [NSString stringWithFormat:@"highAlarm%d",i]];
		[encoder encodeDouble:highLimit[i] forKey: [NSString stringWithFormat:@"highLimit%d",i]];
	}
}

#pragma mark *** Commands
- (void) addCmdToQueue:(NSString*)aCmd
{
    if([serialPort isOpen]){ 
		[self enqueueCmd:aCmd];
		if(!lastRequest){
			[self processOneCommandFromQueue];
		}
	}
}

- (void) readTemps
{
	switch(unitsType){
		case kLakeShore210Kelvin:	  [self addCmdToQueue:@"KRDG? 0"]; break;
		case kLakeShore210Centigrade: [self addCmdToQueue:@"CRDG? 0"]; break;
		case kLakeShore210Raw:		  [self addCmdToQueue:@"SRDG? 0"]; break;
	}
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

- (void) syncDataIdsWith:(id)anotherLakeShore210
{
    [self setDataId:[anotherLakeShore210 dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"LakeShore210Model"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORLakeShore210DecoderForTemperature",@"decoder",
        [NSNumber numberWithLong:dataId],   @"dataId",
        [NSNumber numberWithBool:NO],       @"variable",
        [NSNumber numberWithLong:18],       @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Temperatures"];
    
    return dataDictionary;
}
#pragma mark •••Adc Processing Protocol
- (void) processIsStarting { }
- (void) processIsStopping { }
- (void) startProcessCycle { }
- (void) endProcessCycle   { }

- (NSString*) identifier
{
	NSString* s;
 	@synchronized(self){
		s= [NSString stringWithFormat:@"LakeShore210,%u",[self uniqueIdNumber]];
	}
	return s;
}

- (NSString*) processingTitle
{
	NSString* s;
 	@synchronized(self){
		s= [self identifier];
	}
	return s;
}

- (double) convertedValue:(int)aChan
{
	double theValue = 0;
	@synchronized(self){
		if(aChan>=0 && aChan<8)theValue =  temp[aChan];
 	}
	return theValue;
}

- (double) maxValueForChan:(int)aChan
{
	double theValue;
	@synchronized(self){
        if(aChan>=0 && aChan<8) theValue = highLimit[aChan];
		else         theValue = 1.0;
	}
	return theValue;
}

- (double) minValueForChan:(int)aChan
{
	double theValue;
	@synchronized(self){
        if(aChan>=0 && aChan<8) theValue = lowLimit[aChan];
		else         theValue = 1.0;
	}
	return theValue;
}

- (void) getAlarmRangeLow:(double*)theLowAlarm high:(double*)theHighAlarm channel:(int)aChan
{
	@synchronized(self){
        if(aChan>=0 && aChan<8) {
            *theLowAlarm   = lowAlarm[aChan];
            *theHighAlarm = highAlarm[aChan];
        }
        else {
			*theLowAlarm = 0;
            *theHighAlarm = 1E-4;
        }
	}
}

- (BOOL) processValue:(int)aChan
{
	BOOL r = 0;
	@synchronized(self){
		if(aChan>=0 && aChan<8)r =  temp[aChan];
    }
	return r;
}

- (void) setProcessOutput:(int)channel value:(int)value { }
@end

@implementation ORLakeShore210Model (private)
- (void) runStarted:(NSNotification*)aNote
{
}

- (void) runStopped:(NSNotification*)aNote
{
}

- (void) timeout
{
	NSLogError(@"command timeout",@"Lake Shore 210",nil);
	[self setLastRequest:nil];
	[self processOneCommandFromQueue];	 //do the next command in the queue
}

- (void) processOneCommandFromQueue
{
	NSString* aCmd = [self nextCmd];
	if(aCmd){
        if([aCmd rangeOfString:@"?"].location != NSNotFound){
            [self setLastRequest:aCmd];
            [self performSelector:@selector(timeout) withObject:nil afterDelay:3];
        }
        if(![aCmd hasSuffix:@"\r\n"]) aCmd = [aCmd stringByAppendingString:@"\r\n"];
        [serialPort writeString:aCmd];
        if(!lastRequest){
            [self performSelector:@selector(processOneCommandFromQueue) withObject:nil afterDelay:.01];
        }
    }
}

- (void) process_xrdg_response:(NSString*)theResponse args:(NSArray*)cmdArgs
{
	NSArray* t = [theResponse componentsSeparatedByString:@","];
	int i;
	for(i=0;i<[t count];i++){
		[self setTemp:i value:[[t objectAtIndex:i] floatValue]];
	}
    [self setIsValid:YES];
	if(shipTemperatures) [self shipTemps];
}

- (void) pollTemps
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollTemps) object:nil];
	[self readTemps];
	[self postCouchDBRecord];
	[self performSelector:@selector(pollTemps) withObject:nil afterDelay:pollTime];
}
- (void) postCouchDBRecord
{
    NSDictionary* values = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSArray arrayWithObjects:
                             [NSNumber numberWithInt:temp[0]],
                             [NSNumber numberWithInt:temp[1]],
                             [NSNumber numberWithInt:temp[2]],
                             [NSNumber numberWithInt:temp[3]],
                             [NSNumber numberWithInt:temp[4]],
                             [NSNumber numberWithInt:temp[5]],
                             [NSNumber numberWithInt:temp[6]],
                             [NSNumber numberWithInt:temp[7]],
                             nil], @"temperatures",
                            [NSNumber numberWithInt:    unitsType],    @"unitType",
                            [NSNumber numberWithInt:    pollTime],     @"pollTime",
                            nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
}

@end
