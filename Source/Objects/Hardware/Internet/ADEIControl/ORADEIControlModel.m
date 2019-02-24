//--------------------------------------------------------
// ORADEIControlModel
// Created by A. Kopmann on Feb 8, 2019
// Copyright (c) 2017, University of North Carolina. All rights reserved.
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
#import "ORADEIControlModel.h"
#import "ORSafeQueue.h"
#import "NetSocket.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORADEIControlDefs.h"


#pragma mark ***External Strings
NSString* ORADEIControlModelSensorGroupChanged           = @"ORADEIControlModelSensorGroupChanged";
NSString* ORADEIControlModelIsConnectedChanged           = @"ORADEIControlModelIsConnectedChanged";
NSString* ORADEIControlModelIpAddressChanged             = @"ORADEIControlModelIpAddressChanged";
NSString* ORADEIControlModelSetPointChanged              = @"ORADEIControlModelSetPointChanged";
NSString* ORADEIControlModelReadBackChanged              = @"ORADEIControlModelReadBackChanged";
NSString* ORADEIControlModelQueCountChanged              = @"ORADEIControlModelQueCountChanged";
NSString* ORADEIControlModelSetPointsChanged             = @"ORADEIControlModelSetPointsChanged";
NSString* ORADEIControlModelMeasuredValuesChanged        = @"ORADEIControlModelMeasuredValuesChanged";
NSString* ORADEIControlModelSetPointFileChanged          = @"ORADEIControlModelSetPointFileChanged";
NSString* ORADEIControlModelPostRegulationFileChanged    = @"ORADEIControlModelPostRegulationFileChanged";
NSString* ORADEIControlModelVerboseChanged               = @"ORADEIControlModelVerboseChanged";
NSString* ORADEIControlModelWarningsChanged              = @"ORADEIControlModelWarningsChanged";
NSString* ORADEIControlModelShowFormattedDatesChanged    = @"ORADEIControlModelShowFormattedDatesChanged";
NSString* ORADEIControlModelPostRegulationPointAdded     = @"ORADEIControlModelPostRegulationPointAdded";
NSString* ORADEIControlModelPostRegulationPointRemoved   = @"ORADEIControlModelPostRegulationPointRemoved";
NSString* ORADEIControlModelUpdatePostRegulationTable    = @"ORADEIControlModelUpdatePostRegulationTable";
NSString* ORADEIControlModelPollTimeChanged              = @"ORADEIControlModelPollTimeChanged";

NSString* ORADEIControlLock						         = @"ORADEIControlLock";



@interface ORADEIControlModel (private)
- (void) timeout;
- (void) processNextCommandFromQueue;
- (void) pollMeasuredValues;
@end

#define kADEIControlValue -999
#define kADEIControlPort 12340

@implementation ORADEIControlModel

- (void) dealloc
{
    [setPointFile release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [buffer release];
	[cmdQueue release];
	[lastRequest release];
    [setPoints release];
    [postRegulationArray release];
    [measuredValues release];
    if([self isConnected]){
        [socket close];
        [socket setDelegate:nil];
        [socket release];
    }
    [shipValueDictionary release];
    [ipAddress release];
	
	[super dealloc];
}
- (void) wakeUp
{
    if(pollTime){
        [self performSelector:@selector(pollMeasuredValues) withObject:nil afterDelay:2];
    }
    [super wakeUp];
    
    numSetpointsDiffer = 0;
}

- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super sleep];
}
- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"ADEIControl.png"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORADEIControlController"];
}

#pragma mark ***Accessors
- (void) setSetPoint: (int)aIndex withValue: (double)value
{
    NSNumber* oldValue = [[setPoints objectAtIndex:aIndex] objectForKey:@"setPoint"];
    [[[self undoManager] prepareWithInvocationTarget:self] setSetPoint:aIndex withValue:[oldValue floatValue]];
    [[setPoints objectAtIndex:aIndex] setObject:[NSString stringWithFormat:@"%.6f",value] forKey:@"setPoint"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelSetPointsChanged object:self];
}

- (void) setSetPointReadback: (int)aIndex withValue: (double)value
{
    [[setPoints objectAtIndex:aIndex] setObject:[NSString stringWithFormat:@"%.6f",value] forKey:@"readBack"];
    //[[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelSetPointsChanged object:self];
}

- (void) setMeasuredValue: (int)aIndex withValue: (double)value
{
    [[measuredValues objectAtIndex:aIndex] setObject:[NSString stringWithFormat:@"%lf",value] forKey:@"value"];
    //[[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelMeasuredValuesChanged object:self];
    
}

- (void) createSetPointArray
{
    if(setPoints)[setPoints release];
    setPoints = [[NSMutableArray array] retain];
    int index = 0;
    for(;;) {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [dict setObject:setPointList[index++]   forKey:@"uid"];
        [dict setObject:setPointList[index++]   forKey:@"name"];
        [dict setObject:@"0"   forKey:@"setPoint"];
        [dict setObject:@"?" forKey:@"readBack"];
        [setPoints addObject:dict];
        if([setPointList[index] isEqualToString:@""])break;
    }
}


- (NSInteger) numSetPoints
{
    return [setPoints count];
}
- (void) createMeasuredValueArray
{
    if(measuredValues)[measuredValues release];
    measuredValues = [[NSMutableArray array] retain];
    int index = 0;
    for(;;) {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [dict setObject:measuredValueList[index++]   forKey:@"uid"];
        [dict setObject:measuredValueList[index++]   forKey:@"name"];
        [dict setObject:@"?" forKey:@"value"];
        [measuredValues addObject:dict];
        if([measuredValueList[index] isEqualToString:@""])break;
    }
}

- (NSString *) measuredValueName:(NSUInteger)anIndex
{
    [self checkShipValueDictionary];
    NSString* aKey = [NSString stringWithFormat:@"%d",(int)anIndex];
    NSString* aName = [shipValueDictionary objectForKey:aKey];
    if(aName){
        return aName;
    }
    else if(anIndex < [measuredValues count]){
        NSString* part1 = [[measuredValues objectAtIndex:anIndex] objectForKey:@"uid"];
        NSString* part2 = [[measuredValues objectAtIndex:anIndex] objectForKey:@"name"];
        return [part1 stringByAppendingFormat:@" %@",part2];
    }
    return [NSString stringWithFormat:@"Index %d",(int)anIndex];
}

- (NSUInteger) numMeasuredValues
{
    return [measuredValues count];
}

- (void) setSetPoints:(NSMutableArray*)anArray
{
    [anArray retain];
    [setPoints release];
    setPoints = anArray;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelSetPointsChanged object:self];
}

- (void) setMeasuredValues:(NSMutableArray*)anArray
{
    [anArray retain];
    [measuredValues release];
    measuredValues = anArray;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelMeasuredValuesChanged object:self];
}
- (id) setPointAtIndex:(int)i
{
    if(i<[setPoints count]){
        return [[setPoints objectAtIndex:i] objectForKey:@"setPoint"];
    }
    else return nil;
}
- (id) setPointReadBackAtIndex:(int)i
{
    if(i<[setPoints count]){
        return [[setPoints objectAtIndex:i] objectForKey:@"readBack"];
    }
    else return nil;
}
- (id) setPointItem:(int)i forKey:(NSString*)aKey
{
    if(i<[setPoints count]){
        return [[setPoints objectAtIndex:i] objectForKey:aKey];
    }
    else return nil;
}

- (id) measuredValueItem:(int)i forKey:(NSString*)aKey
{
    if(i<[measuredValues count]){
        return [[measuredValues objectAtIndex:i] objectForKey:aKey];
    }
    else return nil;
}

- (id) measuredValueAtIndex:(int)i
{
    if(i<[measuredValues count]){
        return [[measuredValues objectAtIndex:i] objectForKey:@"value"];
    }
    else return nil;
}

- (int) getIndexOfSetPoint:(NSString *) aUID
{
    int row = -1;
    
    for (int i = 0; i < [setPoints count]; i++)
    {
        NSString *uidSensor = (NSString *) [self setPointItem:i forKey:@"uid"];
        if ([uidSensor isEqualToString:aUID])
        {
            row = i;
        }
    }
    
    return row;
}

- (int) getIndexOfMeasuredValue:(NSString *) aUID
{
    int row = -1;
    
    for (int i = 0; i < [measuredValues count]; i++)
    {
        NSString *uidSensor = (NSString *) [self measuredValueItem:i forKey:@"uid"];
        if ([uidSensor isEqualToString:aUID])
        {
            row = i;
        }
    }
    
    return row;
}

- (void) setSetPointWithUID: (NSString *)aUID withValue: (double)value
{
   [self setSetPoint:[self getIndexOfSetPoint:aUID] withValue:value];
}

- (void) setSetPointReadbackWithUID: (NSString *)aUID withValue: (double)value
{
   [self setSetPointReadback:[self getIndexOfSetPoint:aUID] withValue:value];
}

- (id) setPointWithUID:(NSString *)aUID
{
   return ([self setPointAtIndex:[self getIndexOfSetPoint:aUID]]);
}

- (id) setPointReadBackWithUID:(NSString *)aUID
{
   return ([self setPointReadBackAtIndex:[self getIndexOfSetPoint:aUID]]);
}

- (id) measuredValueWithUID:(NSString *)aUID
{
   return ([self measuredValueAtIndex:[self getIndexOfMeasuredValue:aUID]]);
}

- (NSString*) title
{
    return [NSString stringWithFormat:@"%@ (%@)",[self fullID],[self ipAddress]];
}

- (BOOL) wasConnected
{
    return wasConnected;
}

- (void) setWasConnected:(BOOL)aState
{
    wasConnected = aState;
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
    [self setWasConnected:isConnected];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelIsConnectedChanged object:self];
}

- (void) connect
{
	if(!isConnected && [ipAddress length]){
        NSLog(@"%@: trying to connect\n",[self fullID]);
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:kADEIControlPort]];
        [self setIsConnected:[socket isConnected]];
	}
	else {
        NSLog(@"%@: trying to disconnect\n",[self fullID]);
		[self setSocket:nil];
        [self setIsConnected:[socket isConnected]];
	}
}

- (BOOL) isConnected
{
    return isConnected;
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelIpAddressChanged object:self];
}

- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:YES];
        NSLog(@"%@: Connected\n",[self fullID]);
        
        [cmdQueue removeAllObjects];
        [self setLastRequest:nil];
    }
}

- (BOOL) expertPCControlOnly    {return expertPCControlOnly;}
- (BOOL) zeusHasControl         {return zeusHasControl;}
- (BOOL) orcaHasControl         {return orcaHasControl;}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
    if(inNetSocket == socket){
		NSString* theString = [[[[NSString alloc] initWithData:[inNetSocket readData] encoding:NSASCIIStringEncoding] autorelease] uppercaseString];
        
        if(verbose){
            NSLog(@"ADEIControl received data:\n");
            NSLog(@"%@\n",theString);
        }

        if(!stringBuffer) stringBuffer = [[NSMutableString stringWithString:theString] retain];
        else [stringBuffer appendString:theString];
        if([stringBuffer rangeOfString:@":done\n" options:NSCaseInsensitiveSearch].location != NSNotFound){
            if(verbose){
                NSLog(@"ADEIControl got end of string delimiter and will now parse the incoming string.\n");
            }
            [stringBuffer replaceOccurrencesOfString:@"+"         withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0,1)];//remove leading '+' if there
            [stringBuffer replaceOccurrencesOfString:@"readssps"  withString:cmdReadSetpoints options:NSCaseInsensitiveSearch range:NSMakeRange(0,[stringBuffer length])];
            [stringBuffer replaceOccurrencesOfString:@"readsmvs"  withString:cmdReadActualValues options:NSCaseInsensitiveSearch range:NSMakeRange(0,[stringBuffer length])];
            [stringBuffer replaceOccurrencesOfString:@"writessps" withString:cmdWriteSetpoints options:NSCaseInsensitiveSearch range:NSMakeRange(0,[stringBuffer length])];
            [stringBuffer replaceOccurrencesOfString:@"s:done"    withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[stringBuffer length])];
            [stringBuffer replaceOccurrencesOfString:@":done"     withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[stringBuffer length])];       
            [stringBuffer replaceOccurrencesOfString:@"\n"     withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0,[stringBuffer length])];
            [self parseString:stringBuffer];
            [stringBuffer release];
            stringBuffer = nil;
        }
    }
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:NO];
        NSLog(@"%@: Disconnected\n",[self fullID]);
		[socket autorelease];
		socket = nil;
        [cmdQueue removeAllObjects];
        [self setLastRequest:nil];
    }
}

- (void) flushQueue
{
    [cmdQueue removeAllObjects];
    [self setLastRequest:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelQueCountChanged object: self];
}

- (void) parseString:(NSString*)aLine
{
    int n;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
    
    n = 0;
    aLine = [aLine trimSpacesFromEnds];
    aLine = [aLine lowercaseString];
    if([aLine hasPrefix:cmdWriteSetpoints]) {
        aLine = [aLine substringFromIndex:cmdWriteSetpoints.length+1]; // also remove colon here !!!
        NSArray* theParts = [aLine componentsSeparatedByString:@","];
        n = (int) [theParts count];
        
        if (n+spOffset < [setPoints count]) {
            NSLog(@"Error: The number of setpoints returned is too low: recv %d < send %d\n", n+spOffset, [setPoints count]);
            NSLog(@"Turn on <verbose> and resend data. It's possible that the buffer in the Fieldpoint device is too small\n");
            NSLog(@"It's also possible that the sensor list has changed.\n");
        }
        
        /*
        int i;
        for(i=0;i<n;i++){
            if(i<[setPoints count]){
                float aValue = [[theParts objectAtIndex:i] floatValue];
                //[self setSetPoint:i+spOffset withValue:aValue];
            
                // Compare with setpoints send?!
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelSetPointsChanged object: self];
         */
        
        [self setLastRequest:nil];

    }
    else if([aLine hasPrefix:cmdReadSetpoints]) {
        aLine = [aLine substringFromIndex:cmdReadSetpoints.length];
        NSArray* theParts = [aLine componentsSeparatedByString:@","];
        n = (int) [theParts count];
        int i=0;
        for(i=0;i<n;i++){
            if(i<[setPoints count]){
                double readBack = [[theParts objectAtIndex:i]doubleValue];
                [self setSetPointReadback:i withValue:readBack];
            }
        }

        [self setLastRequest:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelReadBackChanged object: self];
    }
    
    else if([aLine hasPrefix:cmdReadActualValues]) {
        aLine = [aLine substringFromIndex:cmdReadActualValues.length];
        NSArray* theParts = [aLine componentsSeparatedByString:@","];
        n = (int) [theParts count];
        int i;
        for(i=0;i<n;i++){
            if(i<[measuredValues count]){
                [self setMeasuredValue:i withValue:[[theParts objectAtIndex:i]doubleValue]];
                
            }
        }
        [self shipRecords];
        [self setLastRequest:nil];
        
        // Parse control flags
        if (localControlIndex > 1)
             expertPCControlOnly = [[[measuredValues objectAtIndex:localControlIndex] objectForKey:@"value"] boolValue];
        if (zeusControlIndex > 1)
             zeusHasControl      = [[[measuredValues objectAtIndex:zeusControlIndex] objectForKey:@"value"] boolValue];
        if (orcaControlIndex > 1)
             orcaHasControl      = [[[measuredValues objectAtIndex:orcaControlIndex] objectForKey:@"value"] boolValue];
        if ((zeusControlIndex >1) && (orcaControlIndex == 0))
             orcaHasControl      = ![[[measuredValues objectAtIndex:zeusControlIndex] objectForKey:@"value"] boolValue];

        [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelMeasuredValuesChanged object: self];
    }
    
    if(verbose){
        NSLog(@"N = %d\n", n);
    }

    
    [self processNextCommandFromQueue];
}
#pragma mark ***Data Records
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId   = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anOtherDevice
{
    [self setDataId:[anOtherDevice dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ADEIControl"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"ORADEIControlDecoderForAdc",@"decoder",
                                 [NSNumber numberWithLong:dataId],   @"dataId",
                                 [NSNumber numberWithBool:NO],       @"variable",
                                 [NSNumber numberWithLong:kADEIControlRecordSize],       @"length",
                                 nil];
    [dataDictionary setObject:aDictionary forKey:@"Temperatures"];
    
    return dataDictionary;
}

- (void) checkShipValueDictionary
{
    if(!shipValueDictionary){
        shipValueDictionary = [[NSMutableDictionary dictionary] retain];
        int i;
        int index=0;
        for(i=0;i<kNumToShip;i++){
            NSString* itemIndex = itemsToShip[index++];
            NSString* itemName  = itemsToShip[index++];
            NSString* aName = [NSString stringWithFormat:@"(%@) %@",itemIndex,itemName];
            [shipValueDictionary setObject:aName forKey:itemIndex];
        }
    }
}

- (void) shipRecords
{
    [self checkShipValueDictionary];

    time_t    ut_Time;
    time(&ut_Time);
    time_t  timeMeasured = ut_Time;

    for(NSString* aKey in shipValueDictionary){
        int j = [aKey intValue];
        if(j<[measuredValues count]){
            if([[ORGlobal sharedGlobal] runInProgress]){
                uint32_t record[kADEIControlRecordSize];
                record[0] = dataId | kADEIControlRecordSize;
                record[1] = ([self uniqueIdNumber] & 0x0000fffff);
                record[2] = (uint32_t)timeMeasured;
                record[3] = j;

                union {
                    double asDouble;
                    uint32_t asLong[2];
                } theData;
                NSString* s = [[measuredValues objectAtIndex:j]objectForKey:@"value"];
                double aValue = [s doubleValue];
                theData.asDouble = aValue;
                record[4] = theData.asLong[0];
                record[5] = theData.asLong[1];
                record[6] = 0; //spares
                record[7] = 0;
                record[8] = 0;

                [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification
                                                                    object:[NSData dataWithBytes:record length:sizeof(int32_t)*kADEIControlRecordSize]];
            }
        }
    }
}

- (NSString*) setPointFile
{
    if(setPointFile==nil)return @"";
    else return setPointFile;
}

- (void) setSetPointFile:(NSString*)aPath
{
    [setPointFile autorelease];
    setPointFile = [aPath copy];
}

- (NSUInteger) queCount
{
	return [cmdQueue count];
}

- (BOOL) isBusy
{
    BOOL busy;
    busy = [self queCount]!=0 || lastRequest!=nil;
    
    if (verbose){
        NSString* lastCmd = lastRequest;
        if ([lastCmd hasPrefix:cmdWriteSetpoints]) lastCmd = cmdWriteSetpoints;
        NSLog(@"ADEIControl is busy = %d, commands in queue = %d, waitin for msg = %@ ====\n", busy, [self queCount], lastCmd);
    }
    return busy;
}

- (NSString*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(NSString*)aRequest
{
	[aRequest retain];
	[lastRequest release];
	lastRequest = aRequest;    
}

- (NSString*) commonScriptMethods
{
    NSArray* selectorArray = [NSArray arrayWithObjects:
                              @"isBusy",
                              @"writeSetpoints",
                              @"readBackSetpoints",
                              @"readMeasuredValues",
                              @"readSetPointsFile:(NSString*)",
                              @"setSetPoint:(int) withValue:(float)",
                              @"setSetPointWithUID:(string) withValue:(float)",
                              @"setPointAtIndex:(int)",
                              @"setPointWithUID:(string)",
                              @"setPointReadBackAtIndex:(int)",
                              @"setPointReadBackWithUID:(string)",
                              @"measuredValueAtIndex:(int)",
                              @"measuredValueWithUID:(string)",
                              @"pushReadBacksToSetPoints",
                              @"getIndexOfSetPoint:(string)",
                              @"getIndexOfMeasuredValue:(string)",
                              nil];
    
    return [selectorArray componentsJoinedByString:@"\n"];
}

- (void) setVerbose:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVerbose:verbose];
    verbose = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelVerboseChanged object:self];
}

- (void) setWarnings:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWarnings:warnings];
    warnings = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelWarningsChanged object:self];
}

- (BOOL) showFormattedDates
{
    return showFormattedDates;
}
- (void) setShowFormattedDates:(BOOL)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShowFormattedDates:showFormattedDates];
    showFormattedDates = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelShowFormattedDatesChanged object:self];
}

- (BOOL) verbose
{
    return verbose;
}

- (BOOL) warnings
{
    return warnings;
}

- (void) pushReadBacksToSetPoints
{
    int i;
    for(i=2;i<[setPoints count];i++){
        double theReadBack = [[self setPointReadBackAtIndex:i] doubleValue];
        [self setSetPoint:i withValue:theReadBack];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelSetPointsChanged object: self];
}

- (int) compareSetPoints
{
    int n = 0;
    for (int i=0; i<[setPoints count]; i++){
        double readBack = [[[setPoints objectAtIndex:i] objectForKey:@"readBack"] doubleValue];
        double setValue  = [[[setPoints objectAtIndex:i] objectForKey:@"setPoint"] doubleValue];
    
        double diff = fabs(setValue-readBack);
        if((i>=2) && (diff > 0.00001)){
            n = n+1;
        }
    }
    
    // Display list of potentially changed setpoint in the Orca log
    if ((warnings) && (n != numSetpointsDiffer)){
       for (int i=0; i<[setPoints count]; i++){
           double readBack = [[[setPoints objectAtIndex:i] objectForKey:@"readBack"] doubleValue];
           double setValue  = [[[setPoints objectAtIndex:i] objectForKey:@"setPoint"] doubleValue];
           
           double diff = fabs(setValue-readBack);
           if((i>=2) && (diff > 0.00001)){
               NSLog(@"ADEIControl WARNING: index %i: setPoint-readBack > 0.00001 (abs(%f-%f) = %f)\n",i,setValue,readBack,diff);
           }
       }
       
       numSetpointsDiffer = n;
    }
    
    return(n);
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelPollTimeChanged object:self];
    
    if(pollTime){
        [self performSelector:@selector(pollMeasuredValues) withObject:nil afterDelay:.2];
    }
    else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollMeasuredValues) object:nil];
    }
}


- (int) sensorGroup
{
    return sensorGroup;
}

- (NSString*) sensorGroupName;
{
    return sensorGroupName;
}

- (void) setSensorGroup:(int)aGroup
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSensorGroup:sensorGroup];
    sensorGroup = aGroup;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelSensorGroupChanged object:self];
    
    //NSLog(@"Sensor group is %d\n", sensorGroup);

    // Load sensor list of the selected group
    if (sensorGroup == 0){
        sensorGroupName = @"113-RS e-gun cRIO";
        // Set sensor lists (setpoints, measured vcalues, archival)
        setPointList = setPointList_RS1;
        measuredValueList = measuredValueList_RS1;
        kNumToShip = kNumToShip_RS1;
        itemsToShip = itemsToShip_RS1;

        // Define command strings used in Fieldpoint implementation
        cmdReadSetpoints = @"get gains";
        cmdWriteSetpoints = @"set gains";
        cmdReadActualValues = @"get temperatures";
        spOffset = 2;
    
        localControlIndex = 0;
        zeusControlIndex = 140;
        orcaControlIndex = 0;
    }
    
    if (sensorGroup == 1){
        sensorGroupName = @"113-RS e-gun enbedded PC";
        // Set sensor lists (setpoints, measured vcalues, archival)
        setPointList = setPointList_RS2;
        measuredValueList = measuredValueList_RS2;
        kNumToShip = kNumToShip_RS2;
        itemsToShip = itemsToShip_RS2;

        // Define command strings used in Fieldpoint implementation
        cmdReadSetpoints = @"get gains";
        cmdWriteSetpoints = @"set gains";
        cmdReadActualValues = @"get temperatures";
        spOffset = 2;
        
        localControlIndex = 0;
        zeusControlIndex = 0;
        orcaControlIndex = 0;
    }
    
     if (sensorGroup == 2){
        sensorGroupName = @"436-MS high voltage";
        // Set sensor lists (setpoints, measured vcalues, archival)
        setPointList = setPointList_HV;
        measuredValueList = measuredValueList_HV;
        kNumToShip = kNumToShip_HV;
        itemsToShip = itemsToShip_HV;

        // Define command strings used in Fieldpoint implementation
        cmdReadSetpoints = @"read sp";
        cmdWriteSetpoints = @"write sp";
        cmdReadActualValues = @"read mv";
        spOffset = 0;
        
        localControlIndex = 146;
        zeusControlIndex = 147;
        orcaControlIndex = 148;
    }
    
    
    // Load sensor list of the selected group
    if (sensorGroup == 3){
        sensorGroupName = @"DAQ-lab";
        // Set sensor lists (setpoints, measured vcalues, archival)
        setPointList = setPointList_DAQlab;
        measuredValueList = measuredValueList_DAQlab;
        kNumToShip = kNumToShip_DAQlab;
        itemsToShip = itemsToShip_DAQlab;
        
        // Define command strings used in Fieldpoint implementation
        cmdReadSetpoints = @"get gains";
        cmdWriteSetpoints = @"set gains";
        cmdReadActualValues = @"get temperatures";
        spOffset = 2;
        
        localControlIndex = 0;
        zeusControlIndex = 2;
        orcaControlIndex = 0;
    }
    
    
    [self createSetPointArray];
    [self createMeasuredValueArray];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelShowFormattedDatesChanged object:self];

}


#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];

	[[self undoManager] disableUndoRegistration];
    
	[self setWasConnected:      [decoder decodeBoolForKey:	 @"wasConnected"]];
    [self setIpAddress:         [decoder decodeObjectForKey: @"ORADEIControlModelIpAddress"]];
    [self setSetPointFile:      [decoder decodeObjectForKey: @"setPointFile"]];
    [self setVerbose:           [decoder decodeBoolForKey:   @"verbose"]];
    [self setWarnings:          [decoder decodeBoolForKey:   @"warnings"]];
    [self setShowFormattedDates:[decoder decodeBoolForKey:   @"showFormattedDates"]];
    [self setPostRegulationFile:[decoder decodeObjectForKey: @"postRegulationFile"]];
    [self setPostRegulationArray:[decoder decodeObjectForKey:@"postRegulationArray"]];
    [self setPollTime:          [decoder decodeIntForKey:@"pollTime"]];

    // Note: Sensor group needs to be defined before loading setpoints!!!
    [self setSensorGroup:       [decoder decodeIntForKey:@"sensorGroup"]];
    [self setSetPoints:         [decoder decodeObjectForKey: @"setPoints"]];

    if(wasConnected)[self connect];
    
	[[self undoManager] enableUndoRegistration];

	return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:setPointFile        forKey:@"setPointFile"];
    [encoder encodeBool:  wasConnected        forKey:@"wasConnected"];
    [encoder encodeBool:  verbose             forKey:@"verbose"];
    [encoder encodeBool:  warnings            forKey:@"warnings"];
    [encoder encodeObject:ipAddress           forKey:@"ORADEIControlModelIpAddress"];
    [encoder encodeObject:setPoints           forKey:@"setPoints"];
    [encoder encodeBool:showFormattedDates    forKey:@"showFormattedDates"];
    [encoder encodeObject:postRegulationFile  forKey: @"postRegulationFile"];
    [encoder encodeObject:postRegulationArray forKey: @"postRegulationArray"];
    [encoder encodeInteger:pollTime           forKey: @"pollTime"];
    [encoder encodeInteger:sensorGroup        forKey: @"sensorGroup"];
}

#pragma mark *** Commands
- (void) writeSetpoints
{
    if([self isConnected]){
        NSMutableString* cmd = [NSMutableString stringWithString:cmdWriteSetpoints];
        [cmd appendString:@":"];
        int i;
        int maxIndex = (int)[setPoints count];
        if (verbose) NSLog(@"N = %d\n", maxIndex);
        for(i=spOffset;i<maxIndex;i++){
            float valueToWrite = [[[setPoints objectAtIndex:i] objectForKey:@"setPoint"] floatValue];
            [cmd appendFormat:@"%f",valueToWrite];
            if(i != maxIndex-1)[cmd appendString:@","];
        }
        [self writeCmdString:cmd];
    }
}

- (void) readBackSetpoints
{
    if([self isConnected]){
        [self writeCmdString:@"get gains"];
    }
}

- (void) readMeasuredValues
{
    if([self isConnected]){
        [self writeCmdString:cmdReadActualValues];
    }
}

- (void) writeCmdString:(NSString*)aCommand
{
	if(!cmdQueue)cmdQueue = [[ORSafeQueue alloc] init];
    aCommand = [aCommand removeNLandCRs]; //no LF or CR as per KIT request
    if(verbose)NSLog(@"ADEIControl enqueued cmd: %@\n",aCommand);
	[cmdQueue enqueue:aCommand];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelQueCountChanged object: self];
	[self processNextCommandFromQueue];
}

- (void) readSetPointsFile:(NSString*) aPath
{
    [setPoints release];
    setPoints = [[NSMutableArray array] retain];
    
	[self setSetPointFile:aPath];
    NSMutableArray* anArray = [[NSArray arrayWithContentsOfFile:aPath]mutableCopy];
    [self setSetPoints: anArray];
    [anArray release];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelSetPointFileChanged object:self];
}

- (void) saveSetPointsFile:(NSString*) aPath
{
	NSString* fullFileName = [aPath stringByExpandingTildeInPath];
	NSString* s = [NSString stringWithFormat:@"%@",setPoints];
	[s writeToFile:fullFileName atomically:NO encoding:NSASCIIStringEncoding error:nil];
}

- (void) setPostRegulationArray:(NSMutableArray*)anArray
{
    [anArray retain];
    [postRegulationArray release];
    postRegulationArray = anArray;
}

- (void) readPostRegulationFile:(NSString*) aPath
{
    [self setPostRegulationFile:aPath];
    [postRegulationArray release];
    postRegulationArray = [[NSMutableArray array] retain];
    NSString* s = [NSString stringWithContentsOfFile:[aPath stringByExpandingTildeInPath]  encoding:NSASCIIStringEncoding error:nil];
    NSArray* lines = [s componentsSeparatedByString:@"\n"];
    for(NSString* aLine in lines){
        NSArray* parts = [aLine componentsSeparatedByString:@","];
        NSString* vess      = @"";
        NSString* post      = @"";
        NSString* offset    = @"";
        if([parts count]>=1)vess    = [parts objectAtIndex:0];
        if([parts count]>=2)post    = [parts objectAtIndex:1];
        if([parts count]>=3)offset  = [parts objectAtIndex:2];

        [postRegulationArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:vess,kVesselVoltageSetPt,post, kPostRegulationScaleFactor,offset, kPowerSupplyOffset,nil]];
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelUpdatePostRegulationTable object:self];
}

- (void) savePostRegulationFile:(NSString*) aPath
{
    NSString* fullFileName = [aPath stringByExpandingTildeInPath];
    NSString* s = @"";
    for(NSDictionary* anEntry in postRegulationArray){
        s = [s stringByAppendingFormat:@"%f,%f,%f\n",[[anEntry objectForKey:kVesselVoltageSetPt]doubleValue],[[anEntry objectForKey:kPostRegulationScaleFactor]doubleValue],[[anEntry objectForKey:kPowerSupplyOffset]doubleValue]];
    }
    [s writeToFile:fullFileName atomically:YES encoding:NSASCIIStringEncoding error:nil];
    [self setPostRegulationFile:fullFileName];
}

- (NSString*) postRegulationFile
{
    if(!postRegulationFile)return @"";
    else return postRegulationFile;
}

- (void) setPostRegulationFile:(NSString*)aPath
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostRegulationFile:postRegulationFile];
    [aPath retain];
    [postRegulationFile release];
    postRegulationFile = aPath;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelPostRegulationFileChanged object:self];
}

- (void) addPostRegulationPoint
{
    if(!postRegulationArray)postRegulationArray = [[NSMutableArray array] retain];
    [postRegulationArray addObject:[ScriptingParameter postRegulationPoint]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelPostRegulationPointAdded object:self];
}

- (void) removeAllPostRegulationPoints
{
    [postRegulationArray release];
    postRegulationArray = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelUpdatePostRegulationTable object:self];
}

- (void) removePostRegulationPointAtIndex:(int) anIndex
{
    if(anIndex < [postRegulationArray count]){
        [postRegulationArray removeObjectAtIndex:anIndex];
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Index"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelPostRegulationPointRemoved object:self userInfo:userInfo];
    }
}

- (uint32_t) numPostRegulationPoints
{
    return (uint32_t)[postRegulationArray count];
}

- (id) postRegulationPointAtIndex:(int)anIndex
{
    if(anIndex>=0 && anIndex<[postRegulationArray count])return [postRegulationArray objectAtIndex:anIndex];
    else return nil;
}
//script convenience methods
- (double) vesselVoltageSetPoint:(int)anIndex
{
    if(anIndex<[postRegulationArray count]){
        NSDictionary* anEntry = [postRegulationArray objectAtIndex:anIndex];
        return [[anEntry objectForKey:kVesselVoltageSetPt] doubleValue];
    }
    return 0;
}

- (double) postRegulationScaleFactor:(int)anIndex
{
    if(anIndex<[postRegulationArray count]){
        NSDictionary* anEntry = [postRegulationArray objectAtIndex:anIndex];
        return [[anEntry objectForKey:kPostRegulationScaleFactor] doubleValue];
    }
    return 0;
}

- (double) powerSupplyOffset:(int)anIndex
{
    if(anIndex<[postRegulationArray count]){
        NSDictionary* anEntry = [postRegulationArray objectAtIndex:anIndex];
        return [[anEntry objectForKey:kPowerSupplyOffset] doubleValue];
    }
    return 0;
}
- (void) setPostRegulationScaleFactor:(int)anIndex withValue:(double)aValue
{
    NSMutableDictionary* anEntry = nil;
    if(anIndex<[postRegulationArray count]){
        anEntry = [postRegulationArray objectAtIndex:anIndex];
    }
    else {
        anEntry = [NSMutableDictionary dictionary];
        [postRegulationArray addObject:anEntry];

    }
    [anEntry setObject:[NSNumber numberWithDouble:aValue] forKey:kPostRegulationScaleFactor];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelUpdatePostRegulationTable object:self];
}

- (void) setPowerSupplyOffset:(int)anIndex withValue:(double)aValue
{
    NSMutableDictionary* anEntry = nil;
    if(anIndex<[postRegulationArray count]){
        anEntry = [postRegulationArray objectAtIndex:anIndex];
    }
    else {
        anEntry = [NSMutableDictionary dictionary];
        [postRegulationArray addObject:anEntry];
        
    }
    [anEntry setObject:[NSNumber numberWithDouble:aValue] forKey:kPowerSupplyOffset];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelUpdatePostRegulationTable object:self];
}

- (void) setVesselVoltageSetPoint:(int)anIndex withValue:(double)aValue
{
    NSMutableDictionary* anEntry = nil;
    if(anIndex<[postRegulationArray count]){
        anEntry = [postRegulationArray objectAtIndex:anIndex];
    }
    else {
        anEntry = [NSMutableDictionary dictionary];
        [postRegulationArray addObject:anEntry];
    }
    [anEntry setObject:[NSNumber numberWithDouble:aValue] forKey:kVesselVoltageSetPt];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelUpdatePostRegulationTable object:self];
}


#pragma mark •••Adc or Bit Processing Protocol
- (void) processIsStarting
{
    //called when processing is started. nothing to do for now.
    //called at the HW polling rate in the process dialog.
    //For now we just use the local polling
}

- (void)processIsStopping
{
    //called when processing is stopping. nothing to do for now.
}

- (void) startProcessCycle
{
    //called at the HW polling rate in the process dialog.
    //ignore for now.
}

- (void) endProcessCycle
{
}

- (NSString*) processingTitle
{
    NSString* s =  [[self fullID] substringFromIndex:2];
    s = [s stringByReplacingOccurrencesOfString:@"Model" withString:@""];
    return s;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    //nothing to do
}

- (BOOL) processValue:(int)channel
{
    return [self convertedValue:channel]!=0;
}

//!convertedValue: and valueForChan: are the same.
- (double) convertedValue:(int)channel
{
    return [[self measuredValueAtIndex:channel] doubleValue];
}

- (double) maxValueForChan:(int)channel
{
    return 1000; // return something if channel number out of range
}

- (double) lowAlarm:(int)channel
{
    return 0;
}

- (double) highAlarm:(int)channel
{
    return 0;
}

- (double) minValueForChan:(int)channel
{
    return 0; // return something if channel number out of range
}

//alarm limits for the processing framework.
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel
{
    *theLowLimit  =  0 ;
    *theHighLimit = 0 ;
}
@end


@implementation ORADEIControlModel (private)
- (void) timeout
{
	@synchronized (self){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
		NSLogError(@"command timeout",@"ADEIControl",nil);
		[self setLastRequest:nil];
        [stringBuffer release];
        stringBuffer = nil;
		[cmdQueue removeAllObjects]; //if we timeout we just flush the queue
		[[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelQueCountChanged object: self];
	}
}

- (void) processNextCommandFromQueue
{
    if(lastRequest)return;
	if([cmdQueue count] > 0){
		NSString* cmd = [cmdQueue dequeue];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelQueCountChanged object: self];
        [self setLastRequest:cmd];
        [socket writeString:cmd encoding:NSASCIIStringEncoding];
        if(verbose)NSLog(@"ADEIControl sent cmd: %@\n",cmd);
        [self performSelector:@selector(timeout) withObject:nil afterDelay:10];//<----timeout !!!!!!!!!!!!!!!!!!!!
	}
}

- (void) pollMeasuredValues
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollMeasuredValues) object:nil];
    [self readMeasuredValues];
    [self readBackSetpoints];
    if(pollTime)[self performSelector:@selector(pollMeasuredValues) withObject:nil afterDelay:pollTime];
}
@end

//------------------------------------------------------------------------

@implementation ScriptingParameter
@synthesize data;

+ (id) postRegulationPoint
{
    ScriptingParameter* aPoint = [[ScriptingParameter alloc] init];
    return [aPoint autorelease];
}

- (id) init
{
    self = [super init];
    NSMutableDictionary* data        = [NSMutableDictionary dictionary];
    [data setObject:@"" forKey:kVesselVoltageSetPt];
    [data setObject:@"" forKey:kPostRegulationScaleFactor];
    [data setObject:@"" forKey:kPowerSupplyOffset];
    self.data = data;
    return self;
}

- (void) dealloc
{
    self.data = nil;
    [super dealloc];
}


- (id) copyWithZone:(NSZone *)zone
{
    ScriptingParameter* copy = [[ScriptingParameter alloc] init];
    copy.data = [[data copyWithZone:zone] autorelease];
    return copy;
}

- (void) setValue:(id)anObject forKey:(id)aKey
{
    if(!anObject)anObject = @"";
    [[[[ORGlobal sharedGlobal] undoManager] prepareWithInvocationTarget:self] setValue:[data objectForKey:aKey] forKey:aKey];
    
    [data setObject:anObject forKey:aKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORADEIControlModelUpdatePostRegulationTable object:self];
}

- (id) objectForKey:(id)aKey
{
    id obj =  [data objectForKey:aKey];
    if(!obj)return @"-";
    else return obj;
}

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    self.data    = [decoder decodeObjectForKey:@"data"];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:data  forKey:@"data"];
}

@end


