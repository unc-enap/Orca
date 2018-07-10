//
//  ORTristanFLTModel.m
//  Orca
//
//  Created by Mark Howe on 1/23/18.
//  Copyright 2018, University of North Carolina. All rights reserved.
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

#import "ORTristanFLTModel.h"
#import "ORIpeCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORDataTypeAssigner.h"
#import "ORTimeRate.h"
#import "ORDataTaskModel.h"

NSString* ORTristanFLTModelEnabledChanged            = @"ORTristanFLTModelEnabledChanged";
NSString* ORTristanFLTModelShapingLengthChanged      = @"ORTristanFLTModelShapingLengthChanged";
NSString* ORTristanFLTModelGapLengthChanged          = @"ORTristanFLTModelGapLengthChanged";
NSString* ORTristanFLTModelThresholdsChanged         = @"ORTristanFLTModelThresholdsChanged";
NSString* ORTristanFLTModelPostTriggerTimeChanged    = @"ORTristanFLTModelPostTriggerTimeChanged";
NSString* ORTristanFLTModelFrameSizeChanged          = @"ORTristanFLTModelFrameSizeChanged";
NSString* ORTristanFLTModelRunningChanged            = @"ORTristanFLTModelRunningChanged";
NSString* ORTristanFLTModelUdpFrameSizeChanged       = @"ORTristanFLTModelUdpFrameSizeChanged";
NSString* ORTristanFLTModelHostNameChanged           = @"ORTristanFLTModelHostNameChanged";
NSString* ORTristanFLTModelPortChanged               = @"ORTristanFLTModelPortChanged";
NSString* ORTristanFLTModelUdpConnectedChanged       = @"ORTristanFLTModelUdpConnectedChanged";
NSString* ORTristanFLTSettingsLock                   = @"ORTristanFLTSettingsLock";

@interface ORTristanFLTModel (private)
- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(bool*)anArray forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary longArray:(unsigned long*)anArray forKey:(NSString*)aKey;
- (int)  restrictIntValue:(int)aValue min:(int)aMinValue max:(int)aMaxValue;
@end
@implementation ORTristanFLTModel

- (id) init
{
    self = [super init];
    return self;
}
  

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [client release];
	[super dealloc];
}

- (void) sleep
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) wakeUp
{
    [super wakeUp];
    [self registerNotificationObservers];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"TristanFLTCard"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORTristanFLTController"];
}

- (Class) guardianClass 
{
	return NSClassFromString(@"ORIpeV4CrateModel");
}

//'stationNumber' returns the logical number of the FLT (FLT#) (1...20),
//method 'slot' returns index (0...9,11-20) of the FLT, so it represents the position of the FLT in the crate. 
- (int) stationNumber
{
	//is it a minicrate?
	if([[[self crate] class]  isSubclassOfClass: NSClassFromString(@"ORIpeV4MiniCrateModel")]){
		if([self slot]<3)   return [self slot]+1;
		else                return [self slot]; //there is a gap at slot 3 (for the SLT) -tb-
	}
	//... or a full crate?
	if([[[self crate] class]  isSubclassOfClass: NSClassFromString(@"ORIpeV4CrateModel")]){
		if([self slot]<11)  return [self slot]+1;
		else                return [self slot]; //there is a gap at slot 11 (for the SLT) -tb-
	}
	//fallback
	return [self slot]+1;
}

- (ORTimeRate*) totalRate   { return totalRate; }

- (ORUDPConnection*) client
{
    if(client==nil){
        client = [[ORUDPConnection alloc] init];
    }
    return client;
}

- (void) setClient:(ORUDPConnection*)aClient
{
    [aClient retain];
    [client release];
    client = aClient;
}
- (NSString*) hostName
{
    if(!hostName)return @"";
    else return hostName;
}

- (void) setHostName:(NSString*)aString
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHostName:hostName];
    [hostName autorelease];
    hostName = [aString copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTristanFLTModelHostNameChanged object:self];
}

- (NSUInteger) port
{
    return port;
}

- (void) setPort:(NSUInteger)aValue
{
    [(ORTristanFLTModel*)[[self undoManager] prepareWithInvocationTarget:self] setPort:port];
    port = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTristanFLTModelPortChanged object:self];
}

#pragma mark ***Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
 	[notifyCenter removeObserver:self]; //guard against a double register
   
    [notifyCenter addObserver : self
                     selector : @selector(runIsAboutToStop:)
                         name : ORRunAboutToStopNotification
                       object : nil];
}

- (void) reset
{
}

#pragma mark ***Accessors
- (BOOL) udpConnected
{
    return udpConnected;
}
- (void) setUpdConnected:(BOOL)aState
{
    udpConnected = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTristanFLTModelUdpConnectedChanged object:self];
}

- (unsigned short) shapingLength
{
    return shapingLength;
}

- (void) setShapingLength:(unsigned short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShapingLength:shapingLength];
    shapingLength = [self restrictIntValue:aValue min:0 max:0xf];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTristanFLTModelShapingLengthChanged object:self];
}

- (int) gapLength
{
    return gapLength;
}

- (void) setGapLength:(int)aGapLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGapLength:gapLength];
    gapLength = [self restrictIntValue:aGapLength min:0 max:0xF];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTristanFLTModelGapLengthChanged object:self];
}

- (unsigned short) postTriggerTime
{
    return postTriggerTime;
}

- (void) setPostTriggerTime:(unsigned short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTriggerTime:postTriggerTime];
    postTriggerTime = [self restrictIntValue:aValue min:0 max:0xffff];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTristanFLTModelPostTriggerTimeChanged object:self];
}
- (unsigned short) udpFrameSize
{
    return udpFrameSize;
}

- (void) setUdpFrameSize:(unsigned short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUdpFrameSize:udpFrameSize];
    udpFrameSize = [self restrictIntValue:aValue min:0 max:0xffff];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTristanFLTModelUdpFrameSizeChanged object:self];
}

- (BOOL) enabled:(unsigned short) aChan
{
    if(aChan<kNumTristanFLTChannels)return enabled[aChan];
    else return NO;
}

- (void) setEnabled:(unsigned short) aChan withValue:(BOOL) aState
{
    if(aChan>=kNumTristanFLTChannels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:aChan withValue:enabled[aChan]];
    enabled[aChan] = aState;
    [[NSNotificationCenter defaultCenter]postNotificationName:ORTristanFLTModelEnabledChanged object:self];
}

- (unsigned long) threshold:(unsigned short)aChan
{
    if(aChan<kNumTristanFLTChannels)return threshold[aChan];
    else return NO;
}

-(void) setThreshold:(unsigned short) aChan withValue:(unsigned long) aValue
{
    if(aChan>=kNumTristanFLTChannels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:threshold[aChan]];
    threshold[aChan] = aValue;
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: @"Channel"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTristanFLTModelThresholdsChanged object:self userInfo: userInfo];
}

- (void) setTotalRate:(ORTimeRate*)newTimeRate
{
	[totalRate autorelease];
	totalRate=[newTimeRate retain];
}

- (void) setToDefaults
{
}

- (void) initBoard
{
    [self loadThresholds];
    [self loadTraceControl];
    [self loadFilterParameters];
}

#pragma mark Data Taking
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) aDataId
{
    dataId = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId      = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORTristanFLTDecoderForTrace",		    @"decoder",
								 [NSNumber numberWithLong:dataId],		@"dataId",
								 [NSNumber numberWithBool:NO],			@"variable",
								 [NSNumber numberWithLong:7],			@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"TristanFLTTrace"];
    
    return dataDictionary;
}

//this goes to the Run header ...
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    //TO DO....other things need to be added here.....
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [self addCurrentState:objDictionary boolArray:(bool*)enabled       forKey:@"enabled"];
    [self addCurrentState:objDictionary longArray:threshold            forKey:@"threshold"];

    [objDictionary setObject:[NSNumber numberWithInt:shapingLength]    forKey:@"shapingLength"];
    [objDictionary setObject:[NSNumber numberWithInt:gapLength]        forKey:@"gapLength"];
    [objDictionary setObject:[NSNumber numberWithInt:postTriggerTime]  forKey:@"postTriggerTime"];

	return objDictionary;
}

#pragma mark ***Data Taking
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // Add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORTristanFLTModel"];    
    //----------------------------------------------------------------------------------------	
    firstTime = YES;

    [self initBoard];
}

//-------------------------------------------------------------
//The data taking process is called from a thread.
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(firstTime){
        [self enableChannels];
    }
    firstTime = NO;
}
//-------------------------------------------------------------

- (void) runIsAboutToStop:(NSNotification*)aNote
{
    [self disableAllChannels];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
}

//not used, but need the method so just return the given index
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	return index;
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(channel>=0 && channel<kNumTristanFLTChannels){
        ++eventCount[channel];
    }
    return YES;
}

#pragma mark ***HW Wizard
- (BOOL) hasParmetersToRamp
{
	return NO;
}

- (int) numberOfChannels
{
    return kNumTristanFLTChannels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
		
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0.00" upperLimit:0xfffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
		
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enable"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setEnabled:withValue:) getMethod:@selector(enabled:)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Post Trigger Delay"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPostTriggerTime:) getMethod:@selector(postTriggerTime)];
    [a addObject:p];
	

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gap Length"];
    [p setFormat:@"##0" upperLimit:0xf lowerLimit:0 stepSize:1 units:@""];//TODO: change it/add new class field! -tb-
    [p setSetMethod:@selector(setGapLength:) getMethod:@selector(gapLength)];
    [a addObject:p];			

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Shaping Length"];
    [p setFormat:@"##0" upperLimit:0xf lowerLimit:2 stepSize:1 units:@""];
    [p setSetMethod:@selector(setShapingLength:) getMethod:@selector(shapingLength)];
    [a addObject:p];
	//----------------

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORIpeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"ORTristanFLTModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORTristanFLTModel"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:     @"Threshold"])	        return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Enabled"])		        return [[cardDictionary objectForKey:@"enabled"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Post Trigger Time"])	return [cardDictionary objectForKey: @"postTriggerTime"];
    else if([param isEqualToString:@"Gap Length"])			return [cardDictionary objectForKey: @"gapLength"];
    else if([param isEqualToString:@"Shaping Length"])		return [cardDictionary objectForKey: @"shapingLength"];
	
	//------------------
	//added MAH 11/09/11
    else if([param isEqualToString:@"Refresh Time"])		return [cardDictionary objectForKey:@"histMeasTime"];
    else if([param isEqualToString:@"Energy Offset"])		return [cardDictionary objectForKey:@"histEMin"];
    else if([param isEqualToString:@"Bin Width"])			return [cardDictionary objectForKey:@"histEBin"];
    else if([param isEqualToString:@"Ship Sum Histo"])		return [cardDictionary objectForKey:@"shipSumHistogram"];
    else if([param isEqualToString:@"Histo Mode"])			return [cardDictionary objectForKey:@"histMode"];
    else if([param isEqualToString:@"Histo Clr Mode"])		return [cardDictionary objectForKey:@"histClrMode"];
	//------------------
	
	else return nil;
}

#pragma mark ***HW Access
- (void) enableChannels
{
    unsigned long data = 0x0;
    int i;
    for(i=0;i<kNumTristanFLTChannels;i++){
        data |= ((enabled[i]&0x1)<<i);
    }
    NSString* cmd = [NSString stringWithFormat:@"w_%08x_%08lx\r",kTristanFltTriggerDisable,~data]; //???inverted to disable
    
    NSData* cmdAsData = [cmd dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendData:cmdAsData];

    
    NSLog(@"Trigger Disable: %@",cmd);
}

- (void) disableAllChannels
{
    NSString* cmd = [NSString stringWithFormat:@"w_%08x_%08x\r",kTristanFltTriggerDisable,0xFF]; //??? high disables ???
    NSData* cmdAsData = [cmd dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:cmdAsData];
    NSLog(@"Trigger Disable: %@",cmd);
}

- (void) loadThresholds
{
    //eventually there will be 8 channels. this test version only sends the first channel
    NSString* cmd = [NSString stringWithFormat:@"w_%08x_%08lx\r",kTristanFltThreshold,threshold[0]];
    NSData* cmdAsData = [cmd dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:cmdAsData];
    NSLog(@"Threshold Cmd: %@",cmd);
}

- (void) forceTrigger
{
    NSString* cmd = [NSString stringWithFormat:@"w_%08x_%08x\r",kTristanFltCommand,kTristanFLTSW];
    NSData* cmdAsData = [cmd dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:cmdAsData];
    NSLog(@"SW Trigger Cmd: %@",cmd);
}

- (void) loadFilterParameters
{
    unsigned long data = ((gapLength&0xf)<<4) | (shapingLength & 0xf);
    NSString* cmd = [NSString stringWithFormat:@"w_%08x_%08lx\r",kTristanFltFilterSet,data];
    NSData* cmdAsData = [cmd dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:cmdAsData];
    NSLog(@"Filter Cmd: %@",cmd);
}

- (void) loadTraceControl
{
    unsigned long data = ((postTriggerTime&0xffff)<<8) | (udpFrameSize & 0xffff);
    NSString* cmd = [NSString stringWithFormat:@"w_%08x_%08lx\r",kTristanFltTraceCntrl,data];
    NSData* cmdAsData = [cmd dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:cmdAsData];
    NSLog(@"Trace Cmd: %@",cmd);
}
- (void) startClient
{
    if(!udpConnected)[client startConnectedToHostName:hostName port:port];
    else [client stop];
}

- (void) sendData:(NSData*)someData
{
     if(udpConnected){
        [client sendData:someData];
    }
}

- (NSString *) DisplayStringFromData:(NSData *)data
// Returns a human readable string for the given data.
{
    NSMutableString *   result;
    NSUInteger          dataLength;
    NSUInteger          dataIndex;
    const uint8_t *     dataBytes;
    
    assert(data != nil);
    
    dataLength = [data length];
    dataBytes  = [data bytes];
    
    result = [NSMutableString stringWithCapacity:dataLength];
    assert(result != nil);
    
    [result appendString:@"\""];
    for (dataIndex = 0; dataIndex < dataLength; dataIndex++) {
        uint8_t     ch;
        
        ch = dataBytes[dataIndex];
        if (ch == 10) {
            [result appendString:@"\n"];
        } else if (ch == 13) {
            [result appendString:@"\r"];
        } else if (ch == '"') {
            [result appendString:@"\\\""];
        } else if (ch == '\\') {
            [result appendString:@"\\\\"];
        } else if ( (ch >= ' ') && (ch < 127) ) {
            [result appendFormat:@"%c", (int) ch];
        } else {
            [result appendFormat:@"\\x%02x", (unsigned int) ch];
        }
    }
    [result appendString:@"\""];
    
    return result;
}

- (void) udpConnection:(ORUDPConnection*)echo didReceiveData:(NSData*)udpData fromAddress:(NSData*)addr
{
    NSLog(@"got %d bytes (%d longs). FrameSize: %d\n",[udpData length],[udpData length]/4,[self udpFrameSize]);
    NSLog(@"%@\n",[self DisplayStringFromData:udpData]);
    
    //only data so far is the trace....
    unsigned long len = ([udpData length]/sizeof(unsigned long)) + 2;
    unsigned long data[len];
    data[0] = dataId | len;
    data[1] =    (([self crateNumber] & 0x0000000f)<<21) | (([self stationNumber] & 0x0000001f)<<16);
    unsigned long ptr = (unsigned long*)[udpData bytes];
    int i;
    int n = [udpData length]/sizeof(unsigned long);
    for(i=0;i<n;i++){
        data[2+i] = ptr++;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification
                                                        object:[NSData dataWithBytes:data length:len]];
}

- (void) udpConnection:(ORUDPConnection*)echo didReceiveError:(NSError*)error
{
}

- (void) udpConnection:(ORUDPConnection*)echo didSendData:(NSData*)data toAddress:(NSData*)addr
{
}

- (void) udpConnection:(ORUDPConnection*)echo didFailToSendData:(NSData*)data toAddress:(NSData*)addr error:(NSError*)error
{
}

- (void)echoDidStop:(ORUDPConnection *)echo
{
    [self setUpdConnected:NO];
}

- (void) udpConnection:(ORUDPConnection*)echo didStartWithAddress:(NSData*)address
{
    [self setUpdConnected:YES];
}

- (void) udpConnection:(ORUDPConnection*)echo didStopWithError:(NSError*)error
{
    [self setUpdConnected:NO];
}

#pragma mark ***archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setPort:              [decoder decodeIntForKey:@"port"]];
    [self setHostName:          [decoder decodeObjectForKey:@"hostName"]];

    [self setShapingLength:     [decoder decodeIntForKey:   @"shapingLength"]];
    [self setGapLength:         [decoder decodeIntForKey:   @"gapLength"]];
    [self setPostTriggerTime:   [decoder decodeIntForKey:   @"postTriggerTime"]];
    [self setUdpFrameSize:      [decoder decodeIntForKey:   @"udpFrameSize"]];
    int i;
    for(i=0;i<kNumTristanFLTChannels;i++) {
        [self setThreshold:i withValue:[decoder decodeInt32ForKey: [NSString stringWithFormat:@"threshold%d",i]]];
        [self setEnabled:i   withValue:[decoder decodeBoolForKey:  [NSString stringWithFormat:@"enabled%d",i]]];
    }
    
    if(!client){
        ORUDPConnection* aClient = [[ORUDPConnection alloc] init];
        [aClient setDelegate:self];
        [self setClient:aClient];
        [aClient release];
    }
    
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeInt:port                forKey:@"port"];
    [encoder encodeObject:hostName         forKey:@"hostName"];
    [encoder encodeInt:shapingLength       forKey:@"shapingLength"];
    [encoder encodeInt:gapLength           forKey:@"gapLength"];
    [encoder encodeInt:postTriggerTime     forKey:@"postTriggerTime"];
    [encoder encodeInt:udpFrameSize        forKey:@"udpFrameSize"];
    int i;
    for(i=0;i<kNumTristanFLTChannels;i++) {
        [encoder encodeInt32: threshold[i] forKey:[NSString stringWithFormat:@"threshold%d",i]];
        [encoder encodeBool:  enabled[i]   forKey:[NSString stringWithFormat:@"enabled%d",i]];
    }
}
@end

@implementation ORTristanFLTModel (private)
- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(bool*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumTristanFLTChannels;i++){
        [ar addObject:[NSNumber numberWithBool:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary longArray:(unsigned long*)anArray forKey:(NSString*)aKey
{
    NSMutableArray* ar = [NSMutableArray array];
    int i;
    for(i=0;i<kNumTristanFLTChannels;i++){
        [ar addObject:[NSNumber numberWithUnsignedLong:anArray[i]]];
    }
    [dictionary setObject:ar forKey:aKey];
}

- (int) restrictIntValue:(int)aValue min:(int)aMinValue max:(int)aMaxValue
{
    if(aValue<aMinValue)return aMinValue;
    else if(aValue>aMaxValue)return aMaxValue;
    else return aValue;
}
@end


