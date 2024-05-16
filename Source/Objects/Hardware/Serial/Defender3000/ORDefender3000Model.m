//--------------------------------------------------------
// ORDefender3000Model
//  Orca
//
//  Created by Mark Howe on 05/14/2024.
//  Copyright 2024 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------
#pragma mark ***Imported Files

#import "ORDefender3000Model.h"
#import "ORSerialPort.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORTimeRate.h"

#pragma mark ***External Strings
NSString* ORDefender3000ModelShipWeightChanged = @"ORDefender3000ModelShipWeightChanged";
NSString* ORDefender3000ModelPollTimeChanged   = @"ORDefender3000ModelPollTimeChanged";
NSString* ORDefender3000ModelSerialPortChanged = @"ORDefender3000ModelSerialPortChanged";
NSString* ORDefender3000ModelPortNameChanged   = @"ORDefender3000ModelPortNameChanged";
NSString* ORDefender3000ModelPortStateChanged  = @"ORDefender3000ModelPortStateChanged";
NSString* ORDefender3000WeightArrayChanged	   = @"ORDefender3000WeightArrayChanged";
NSString* ORDefender3000WeightChanged		   = @"ORDefender3000WeightChanged";
NSString* ORDefender3000PrintIntervalChanged   = @"ORDefender3000PrintIntervalChanged";
NSString* ORDefender3000UnitsChanged           = @"ORDefender3000UnitsChanged";
NSString* ORDefender3000CommandChanged         = @"ORDefender3000CommandChanged";
NSString* ORDefender3000TareChanged         = @"ORDefender3000TareChanged";
NSString* ORDefender3000Lock                   = @"ORDefender3000Lock";

@interface ORDefender3000Model (private)
- (void) runStarted:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;
- (void) timeout;
- (void) processOneCommandFromQueue;
- (void) process_response:(NSString*)theResponse;
- (void) pollWeight;
@end

@implementation ORDefender3000Model
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
    [buffer release];
	[cmdQueue release];
	[lastRequest release];
    [portName release];
    if([serialPort isOpen]){
        [serialPort close];
    }
    [serialPort release];
	[timeRate release];
	

	[super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"Defender3000.tif"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORDefender3000Controller"];
}

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
				
				[self process_response:theResponse];
				
				[self setLastRequest:nil];			 //clear the last request
				[self processOneCommandFromQueue];	 //do the next command in the queue
            }
        } while([buffer rangeOfString:@"\r"].location!= NSNotFound);
	}
}

- (void) shipWeightData
{
    //-----------------------------------------------------------------------------------
    // Data Format
    //xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
    //^^^^ ^^^^ ^^^^ ^^-----------------------data id
    //                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
    // xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
    //                     ^^^^ ^^^^ ^^^^ ^^^^- device id
    // xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  weight  encoded as a float
    // xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time weight taken in seconds since Jan 1, 1970
    // xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  format data
    //                                       ^- 0:unstable,1:stable
    //                                    ^^^-- 1:g,2:kg,3:lb,4:oz,5:lb:oz
    //                                ^^^------ 0:Gross,1:NET,2:PreTare
    //-------------------------------------------------------------------------------------
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		uint32_t data[5];
		data[0] = dataId | 5;
		data[1] = ([self uniqueIdNumber]&0x0000fffff);
		
		union {
			float asFloat;
			uint32_t asLong;
		}theData;
		
		theData.asFloat = weight;
		data[2] = theData.asLong;
        data[3] = timeMeasured;
        
        data[4] =   (stabilityData & 0x1)  | //0:unstable,1:stable
                    (unitData  & 0x7) << 1 | //1:g,2:kg,3:lb,4:oz,5:lb:oz
                    (legendData& 0x7) << 4 ; //0:Gross,1:NET,2:PreTare

		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(int32_t)*4]];
	}
}


#pragma mark ***Accessors
- (ORTimeRate*)timeRate
{
	return timeRate;
}

- (BOOL) shipWeight
{
    return shipWeight;
}

- (void) setShipWeight:(BOOL)aShipWeight
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipWeight:shipWeight];
    
    shipWeight = aShipWeight;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORDefender3000ModelShipWeightChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDefender3000ModelPollTimeChanged object:self];

	if(pollTime){
		[self performSelector:@selector(pollWeight) withObject:nil afterDelay:2];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollWeight) object:nil];
	}
}

- (float) weight
{
	return weight;
}

- (uint32_t) timeMeasured
{
	return timeMeasured;
}

- (void) setWeight:(float)aValue;
{
	weight = aValue;
	//get the time(UT!)
	time_t	ut_Time;
	time(&ut_Time);
	//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
	timeMeasured = (uint32_t)ut_Time;

	[[NSNotificationCenter defaultCenter] postNotificationName:ORDefender3000WeightChanged
														object:self];

	if(timeRate == nil) timeRate = [[ORTimeRate alloc] init];
	[timeRate addDataToTimeAverage:aValue];
}

- (uint8_t) command
{
    return command;
}

- (void) setCommand:(uint8_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCommand:command];
    
    if(command>11)command=11;
    
    command = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDefender3000CommandChanged
                                                        object:self];
}

- (uint16_t) printInterval
{
    return printInterval;
}

- (void) setPrintInterval:(uint16_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPrintInterval:printInterval];
    
    if(aValue>3600)aValue = 3600;
    
    printInterval = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDefender3000PrintIntervalChanged
                                                        object:self];
}

- (uint8_t) units
{
    return units;
}

- (void) setUnits:(uint8_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUnits:units];
    
    if(units<1)     units = 1;
    else if(units>5)units = 5;
    
    units = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDefender3000UnitsChanged
                                                        object:self];
}
- (uint16_t) tare
{
    return tare;
}

- (void) setTare:(uint16_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTare:tare];
        
    tare = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDefender3000TareChanged
                                                        object:self];
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
        while (aPort = [enumerator nextObject]) {
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORDefender3000ModelPortNameChanged object:self];
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

    [[NSNotificationCenter defaultCenter] postNotificationName:ORDefender3000ModelSerialPortChanged object:self];
}

- (void) openPort:(BOOL)state
{
    if(state) {
        [serialPort open];
		[serialPort setSpeed:9600];
		[serialPort setParityNone];
		[serialPort setStopBits2:1];
		[serialPort setDataBits:8];
		[serialPort commitChanges];
    }
    else      [serialPort close];
    portWasOpen = [serialPort isOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDefender3000ModelPortStateChanged object:self];
    
}


#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	[self setShipWeight: [decoder decodeBoolForKey:  @"shipWeight"]];
	[self setPollTime:   [decoder decodeIntForKey:   @"pollTime"]];
	[self setPortWasOpen:[decoder decodeBoolForKey:  @"portWasOpen"]];
    [self setPortName:   [decoder decodeObjectForKey:@"portName"]];
    [self setUnits:      [decoder decodeIntForKey:   @"units"]];
    [self setTare:       [decoder decodeIntForKey:   @"tare"]];
    [self setCommand:    [decoder decodeIntForKey:   @"command"]];
    [self setPrintInterval: [decoder decodeIntForKey:   @"printInterval"]];
	[[self undoManager] enableUndoRegistration];
	timeRate = [[ORTimeRate alloc] init];

    [self registerNotificationObservers];

	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:shipWeight          forKey:@"shipWeight"];
    [encoder encodeInteger:pollTime         forKey:@"pollTime"];
    [encoder encodeBool:portWasOpen         forKey:@"portWasOpen"];
    [encoder encodeObject:portName          forKey:@"portName"];
    [encoder encodeInteger:units            forKey:@"units"];
    [encoder encodeInteger:command          forKey:@"command"];
    [encoder encodeInteger:tare             forKey:@"tare"];
    [encoder encodeInteger:printInterval    forKey:@"printInterval"];
}

#pragma mark *** Commands
- (void) addCmdToQueue:(NSString*)aCmd
{
    if([serialPort isOpen]){ 
		if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
		[cmdQueue addObject:aCmd];
		if(!lastRequest){
			[self processOneCommandFromQueue];
		}
	}
}

- (void) readWeight
{
	[self addCmdToQueue:@"P"];
	[self addCmdToQueue:@"++ShipRecords"];
}

#pragma mark ***Data Records
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherDefender3000
{
    [self setDataId:[anotherDefender3000 dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"Defender3000Model"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORDefender3000DecoderForWeight",@"decoder",
        [NSNumber numberWithLong:dataId],   @"dataId",
        [NSNumber numberWithBool:NO],       @"variable",
        [NSNumber numberWithLong:4],       @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Weights"];
    
    return dataDictionary;
}

- (void) sendAllCommands
{
    [self addCmdToQueue:[NSString stringWithFormat:@"%dP",printInterval]];
    [self addCmdToQueue:[NSString stringWithFormat:@"%dT",tare]];
    [self addCmdToQueue:[NSString stringWithFormat:@"%dU",units]];
}

- (void) sendCommand
{
    //format the command
    switch(command){
        case 0: [self addCmdToQueue:@"P"]; break;
        case 1:
            [self addCmdToQueue:[NSString stringWithFormat:@"%dP",printInterval]];
            [self addCmdToQueue:@"P"];
        break;
        case 2: [self addCmdToQueue:@"Z"];  break;
        case 3: [self addCmdToQueue:@"T"];  break;
        case 4:
            [self addCmdToQueue:[NSString stringWithFormat:@"%dT",tare]];
        break;
        case 5:
            [self addCmdToQueue:[NSString stringWithFormat:@"%dU",units]];
        break;
        case 6:  [self addCmdToQueue:@"PU"];  break;
        case 7: [self addCmdToQueue:@"PV"];  break;
        case 8:
            [self addCmdToQueue:[NSString stringWithFormat:@"%cR",0x1B]];
        break;
    }
}

@end

@implementation ORDefender3000Model (private)
- (void) runStarted:(NSNotification*)aNote
{
}

- (void) runStopped:(NSNotification*)aNote
{
}

- (void) timeout
{
	NSLogError(@"command timeout",@"Defender 3000",nil);
	[self setLastRequest:nil];
	[self processOneCommandFromQueue];	 //do the next command in the queue
}

- (void) processOneCommandFromQueue
{
	if([cmdQueue count] == 0) return;
	NSString* aCmd = [[[cmdQueue objectAtIndex:0] retain] autorelease];
	[cmdQueue removeObjectAtIndex:0];
	if([aCmd isEqualToString:@"++ShipRecords"]){
		if(shipWeight) [self shipWeightData];
	}
	else {
		[self setLastRequest:aCmd];
		[self performSelector:@selector(timeout) withObject:nil afterDelay:3];
		aCmd = [aCmd stringByAppendingString:@"\r\n"];
        NSLog(@"%@",aCmd);

		[serialPort writeString:aCmd];
		if(!lastRequest){
			[self performSelector:@selector(processOneCommandFromQueue) withObject:nil afterDelay:.01];
		}
	}
}

- (void) process_response:(NSString*)theResponse
{	//012345678901234567890
    //P_NNNNNNN_UUUUUSLLLrn
    NSLog(@"%@",theResponse);

    NSString* wt        = @"";
//    NSString* theUnit   = @"";
//    NSString* stable    = @"";

    if([lastRequest isEqualToString:@"PV"]){
    }
    else if([theResponse hasPrefix:@"OK"]){
    }
    else {
        NSInteger len = [theResponse length];
        wt       = [theResponse substringWithRange:NSMakeRange(2,7)];
//        if(len>=16)theUnit  = [theResponse substringWithRange:NSMakeRange(11,5)];
//        if(len>=16)stable   = [theResponse substringWithRange:NSMakeRange(15,1)];
		[self setWeight:[wt floatValue]];
        
//        stabilityData = 0;
//        if([stable isEqualToString:@"?"]) stabilityData = 0;

//        unitData = 0;
//        if([theUnit isEqualToString:     @"g    "])unitData = 1;
//        else if([theUnit isEqualToString:@"kg   "])unitData = 2;
//        else if([theUnit isEqualToString:@"lb   "])unitData = 3;
//        else if([theUnit isEqualToString:@"oz   "])unitData = 4;
//        else if([theUnit isEqualToString:@"lb:oz"])unitData = 5;
	}
}

- (void) pollWeight
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollWeight) object:nil];
	[self readWeight];
	[self performSelector:@selector(pollWeight) withObject:nil afterDelay:pollTime];
}

@end
