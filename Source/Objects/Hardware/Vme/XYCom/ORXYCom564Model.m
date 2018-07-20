//-------------------------------------------------------------------------
//  ORXYCom564Model.h
//
//  Created by Michael G. Marino on 10/21/1011
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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
#import "ORXYCom564Model.h"
#import "ORVmeCrateModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "SBC_Cmds.h"
#import "ORVmecpuModel.h"
#import "VME_HW_Definitions.h"

#pragma mark ***Notification Strings
NSString* ORXYCom564Lock					= @"ORXYCom564Lock";
NSString* ORXYCom564ReadoutModeChanged      = @"ORXYCom564ReadoutModeChanged";
NSString* ORXYCom564OperationModeChanged    = @"ORXYCom564OperationModeChanged";
NSString* ORXYCom564AutoscanModeChanged     = @"ORXYCom564AutoscanModeChanged";
NSString* ORXYCom564ChannelGainChanged      = @"ORXYCom564ChannelGainChanged";
NSString* ORXYCom564ADCValuesChanged        = @"ORXYCom564ADCValuesChanged";
NSString* ORXYCom564PollingActivityChanged  = @"ORXYCom564PollingActivityChanged"; 
NSString* ORXYCom564ShipRecordsChanged      = @"ORXYCom564ShipRecordsChanged";
NSString* ORXYCom564AverageValueNumberHasChanged = @"ORXYCom564AverageValueNumberHasChanged";
NSString* ORXYCom564PollingSpeedHasChanged  = @"ORXYCom564PollingSpeedHasChanged";
NSString* ORXYCom564InterpretADCHasChanged  = @"ORXYCom564InterpretADCHasChanged";

@interface ORXYCom564Model (private)
- (void) _setChannelGains:(NSMutableArray*)gains;
- (void) _setUpPolling:(BOOL)verbose;
- (void) _stopPolling;
- (void) _startPolling;
- (void) _pollAllChannels;
- (void) _setChannelADCValues:(NSData*)vals withNotify:(BOOL)notify;
- (void) _shipRawValues:(ORDataPacket*)dataPacket;
- (void) _addAverageValues:(NSData*)vals;
- (void) _setAverageADCValues:(uint32_t*)array withLength:(int)length;
- (void) _pollingThread;
- (void) _createArrays;
- (void) _readAllAdcChannels;
- (void) _setPollingSpeed:(NSTimeInterval)aTime;
- (double) _interpretADCValue:(uint16_t)adc;
- (uint16_t) _recenterValue:(uint16_t)adc;
@end

@implementation ORXYCom564Model

#pragma mark •••Static Declarations
typedef struct {
	uint32_t offset;
	NSString* name;
} XyCom564RegisterInformation;

#define kXVME564_SizeOfModuleIDData 0x14
#define kXVME564_NumAutoScanChannelsPerGroup 8


static XyCom564RegisterInformation mIOXY564Reg[kNumberOfXyCom564Registers] = {
    {0x01,  @"Module ID"},
    {0x81,  @"Status/Control"},     
    {0x101,  @"Interrupt Timer"},  
    {0x103,  @"Interrupt Vector"},      
    {0x111,  @"Autoscan Control"},         
    {0x180,  @"A/D Mode"},             
    {0x181,  @"A/D Status/Control"},
    {0x183,  @"End of Conversion Vector"},
    {0x184,  @"A/D Gain Channel High"},
    {0x185,  @"A/D Gain Channel Low"},    
    {0x200,  @"A/D Scan"}
};

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self _createArrays];
    [self _setChannelGains:nil];
    [self setAddressModifier:0x29];
    [self setShipRecords:NO];
    [self setOperationMode:kAutoscanning];
    [self setAutoscanMode:k0to64];   
    [self _stopPolling];


    [[self undoManager] enableUndoRegistration];
    [self setAverageValueNumber:1];
    return self;
}

- (void) dealloc 
{
    [self _stopPolling];
    [channelGains release];
    [chanADCVals release];
    [chanADCAverageVals release];
    [chanADCAverageValsCache release];
    [userLocked release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"XYCom564Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORXYCom564Controller"];
}
#pragma mark ***Accessors
- (uint32_t) dataId 
{
    return dataId;
}
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (void) setReadoutMode:(EXyCom564ReadoutMode) aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setReadoutMode:[self readoutMode]];
    switch (aMode) {
        case kA16:
            [self setAddressModifier:0x29];
            break;
        case kA24:
            [self setAddressModifier:0x39];
            break;            
        default:
            break;
    }    
    [[NSNotificationCenter defaultCenter]
	      postNotificationOnMainThreadWithName:ORXYCom564ReadoutModeChanged
	 object:self];

}

- (void) startPollingActivity
{
    [self _startPolling];
    
}
- (void) stopPollingActivity
{
    [self _stopPolling];    
}

#pragma mark •••Hardware Access

- (void) initBoard
{
    [self resetBoard];
    [self programGains];
    [self programReadoutMode];
}

- (void) programReadoutMode
{
    uint8_t val = 0x0;
    if ([self operationMode] == kAutoscanning) {
        val = 0x80 + (uint8_t)[self autoscanMode];
        
    } 
    // Disables if we are not in autoscanning mode
    [self write:val atRegisterIndex:kAutoscanControl];
    
    // Write the mode to the card
    val = [self operationMode];
    [self write:val atRegisterIndex:kADMode];

}
- (void) programGains
{
    uint8_t oldMode = 0x0;
    uint8_t programMode = kProgramGain;    
    // read the old Mode
    [self read:&oldMode atRegisterIndex:kADMode];
    // set to programming mode
    [self write:programMode atRegisterIndex:kADMode];
    int i;
    for (i=0;i<[self getNumberOfChannels];i++) {
        programMode = (uint8_t)[[channelGains objectAtIndex:i] intValue];
        [self write:programMode atRegisterIndex:kGainChannelHigh];        
        [self write:(uint8_t)i+1 atRegisterIndex:kGainChannelLow];
    }
    [self write:oldMode atRegisterIndex:kADMode];    
}

- (void) resetBoard
{
    uint8_t val = 0x3;
    // reset the LEDs
    [self write:val atRegisterIndex:kStatusControl];
    // Reset the IRQs
    val = 0x0;
    [self write:val atRegisterIndex:kInterruptTimer];    
    // reset the A/D
    val = 0x10;
    [self write:val atRegisterIndex:kADStatusControl];
    val = 0x00;
    [self write:val atRegisterIndex:kADStatusControl];
}

- (void) report
{
    NSString* output = @"";
    uint8_t val = 0x10;
    int i;
    for (i=0; i<kXVME564_SizeOfModuleIDData; i++) {
        [[self adapter] readByteBlock:&val 
                            atAddress:[self baseAddress] + mIOXY564Reg[kModuleID].offset + 2*i
                            numToRead:1 
                           withAddMod:[self addressModifier] 
                        usingAddSpace:0x01];
        output = [output stringByAppendingFormat:@"%c",(char)val];
        
    }
    NSLog(@"VME-564 Crate %i: Slot: %i\n",[self crateNumber],[self slot]);
    NSLog(@"  Module ID: %@\n",output);
}

- (void) read:(uint8_t*) aval atRegisterIndex:(EXyCom564Registers)index 
{
    *aval = 0;
    [[self adapter] readByteBlock:aval 
                        atAddress:[self baseAddress] + mIOXY564Reg[index].offset 
                        numToRead:1 
                       withAddMod:[self addressModifier] 
                    usingAddSpace:0x01];
}

- (void) setGain:(EXyCom564ChannelGain) gain 
{
    
    [[[self undoManager] prepareWithInvocationTarget:self] 
      _setChannelGains:[NSMutableArray arrayWithArray:channelGains]];
    short i;
    for (i=0;i < [channelGains count];i++) {
        [channelGains replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:gain]];        
    }

    [[NSNotificationCenter defaultCenter]
	      postNotificationOnMainThreadWithName:ORXYCom564ChannelGainChanged
	 object:self];    
    
}

- (void) setGain:(EXyCom564ChannelGain) gain channel:(unsigned short) aChannel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:[self getGain:aChannel] channel:aChannel];
    
    [channelGains replaceObjectAtIndex:aChannel withObject:[NSNumber numberWithInt:gain]];
    
    [[NSNotificationCenter defaultCenter]
	      postNotificationOnMainThreadWithName:ORXYCom564ChannelGainChanged
	 object:self];    

}
    
- (EXyCom564ChannelGain) getGain:(unsigned short) aChannel;
{
    return [[channelGains objectAtIndex:aChannel] intValue];
}
 
- (int) averageValueNumber
{
    return averageValueNumber;
}

- (NSTimeInterval) pollSpeed
{
    return pollSpeed;
}

- (void) setAverageValueNumber:(int)aValue
{
    @synchronized(self) {
        if (aValue == averageValueNumber) return;
        if (aValue < 1) aValue = 1;
        averageValueNumber = aValue;
        currentAverageState = 0;
        memset((void*)[chanADCAverageValsCache bytes], 0, [chanADCAverageValsCache length]);
    }
    [[NSNotificationCenter defaultCenter]
	      postNotificationOnMainThreadWithName:ORXYCom564AverageValueNumberHasChanged
	 object:self];    
}
    
- (void) write:(uint8_t) aval atRegisterIndex:(EXyCom564Registers)index;
{
    [[self adapter] writeByteBlock:&aval 
                        atAddress:[self baseAddress] + mIOXY564Reg[index].offset 
                        numToWrite:1 
                       withAddMod:[self addressModifier] 
                    usingAddSpace:0x01];
}

- (short) getNumberRegisters
{
	return kNumberOfXyCom564Registers;
}

- (short) getNumberOperationModes
{
	return kNumberOfOpModes;
}

- (short) getNumberAutoscanModes
{
	return kNumberOfAutoscanModes;
}

- (short) getNumberGainModes
{
	return kNumberOfGains;
}

- (NSString*) getRegisterName:(EXyCom564Registers) anIndex
{
    return mIOXY564Reg[anIndex].name;
}

- (uint32_t) getAddressOffset:(EXyCom564Registers) anIndex
{
    return mIOXY564Reg[anIndex].offset;
}

- (NSString*) getOperationModeName: (EXyCom564OperationMode) anIndex
{
    switch (anIndex) {
        case kSingleChannel:
            return @"Single Channel";
        case kSequentialChannel:
            return @"Sequential Channel";
        case kRandomChannel:
            return @"Random Channel";
        case kExternalTrigger:
            return @"External Trigger";
        case kAutoscanning:
            return @"Autoscanning";
        case kProgramGain:
            return @"Program Gains";
        default:
            return @"Error";
    }
}

- (NSString*) getAutoscanModeName:(EXyCom564AutoscanMode)aMode
{
    switch (aMode) {
        case k0to8:
            return @"Chan 0 -> 8";
        case k0to16:
            return @"Chan 0 -> 16";
        case k0to32:
            return @"Chan 0 -> 32";
        case k0to64:
            return @"Chan 0 -> 64";
        default:
            return @"Error";
    }
}

- (NSString*) getChannelGainName:(EXyCom564ChannelGain)aMode
{
    switch (aMode) {
        case kGainOne:
            return @"1x";
        case kGainTwo:
            return @"2x";
        case kGainFive:
            return @"5x";
        case kGainTen:
            return @"10x";
        default:
            return @"Error";
    }
}

- (uint16_t) getAdcValueAtChannel:(int)chan
{
    if (chan >= [self getNumberOfChannels]) return 0;
    uint16_t raw = 0;
    [self getAdcValues:&raw range:NSMakeRange(chan, 1)];
    return raw;
}

- (uint16_t) getAdcAverageValueAtChannel:(int)chan
{
    if (chan >= [self getNumberOfChannels]) return 0;
    uint16_t raw = 0;
    [self getAdcAverageValues:&raw range:NSMakeRange(chan, 1)];
    return raw;
}

- (EXyCom564ReadoutMode) readoutMode
{
    assert([self addressModifier] == 0x29 || [self addressModifier] == 0x39);
    if ([self addressModifier] == 0x29) return kA16;
    else return kA24;
}

- (EXyCom564OperationMode) 	operationMode
{
    return operationMode;
}

- (void) setOperationMode: (EXyCom564OperationMode) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOperationMode:[self operationMode]];
    
    operationMode = anIndex;
    
    [[NSNotificationCenter defaultCenter]
	      postNotificationOnMainThreadWithName:ORXYCom564OperationModeChanged
	 object:self];
}

- (EXyCom564AutoscanMode) autoscanMode
{
    return autoscanMode;
}

- (void) setAutoscanMode: (EXyCom564AutoscanMode) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoscanMode:[self autoscanMode]];
    
    autoscanMode = anIndex;
    
    [[NSNotificationCenter defaultCenter]
	      postNotificationOnMainThreadWithName:ORXYCom564AutoscanModeChanged
	 object:self];    
}

- (BOOL) shipRecords
{
    return shipRecords;
}

- (void) setShipRecords:(BOOL)ship
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipRecords:[self shipRecords]];
    
    shipRecords = ship;
    
    [[NSNotificationCenter defaultCenter]
	      postNotificationOnMainThreadWithName:ORXYCom564ShipRecordsChanged
	 object:self];    
}

- (EInterpretXy564ADC) interpretADC
{
    return interpretADC;
}

- (void) setInterpretADC: (EInterpretXy564ADC)anInt
{
    if (anInt == interpretADC) return;
    interpretADC = anInt;
    [[NSNotificationCenter defaultCenter]
     postNotificationOnMainThreadWithName:ORXYCom564InterpretADCHasChanged
	 object:self];
}


- (BOOL) userLocked
{
    return userLocked != nil;
}

- (NSString*) userLockedString
{
    if (userLocked == nil) return @"";
    return userLocked;
}

- (BOOL) setUserLock:(BOOL)lock withString:(NSString *)lockString
{
    // Tries to set or unset lock, returns YES on success, NO on failure.
    
    // am I locked?
    if (userLocked != nil) {
        if ([userLocked isEqualToString:lockString]) {
            // Means we are already locked, can only unlock
            if (!lock) {
                [userLocked release];
                userLocked = nil;
                [[NSNotificationCenter defaultCenter]
                      postNotificationOnMainThreadWithName:ORXYCom564Lock
                 object:self];
            }
            return YES;
        }
        return NO;
    }
    if (!lock) {
        // Trying to unlock without a already having a lock?
        return YES;
    }
    
    [lockString retain];
    [userLocked release];
    userLocked = lockString;
    
    [[NSNotificationCenter defaultCenter]
          postNotificationOnMainThreadWithName:ORXYCom564Lock
     object:self];
    
    return YES;
}

#pragma mark ***Card qualities
- (short) getNumberOfChannels
{
    return 64;
}

#pragma mark ***ORAdcProcessing protocol
- (void) startProcessCycle
{
	//[self _stopPolling];
}
- (void) endProcessCycle
{
    
}

- (void)processIsStarting
{
	//[self _stopPolling];
}

- (void)processIsStopping
{
	//[self _startPolling];
}

- (BOOL) processValue:(int)channel
{
    return YES;
}

- (int) numberOfChannels
{
    return [self getNumberOfChannels];
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    
}

- (NSString*) processingTitle
{
    return [NSString stringWithFormat:@"XVME-564,%d,%d",[self crateNumber],[self slot]];
}

- (void) convertedValues:(double*)ptr range:(NSRange)aRange
{
    uint16_t temp[aRange.length];
    if (averageValueNumber != 1) {
        [self getAdcAverageValues:temp range:aRange];
    } else {
        [self getAdcValues:temp range:aRange];
    }
    NSUInteger i;
    for (i=0;i<aRange.length;i++) {
        ptr[i] = [self _interpretADCValue:temp[i]];
    }
}

- (void) getAdcValues:(uint16_t*)ptr range:(NSRange)range
{
    if (range.location + range.length > [self getNumberOfChannels]) return;
    NSUInteger i;
    @synchronized(self) {
        uint16_t* byte_ptr = (uint16_t*)[chanADCVals bytes];
        for (i=0;i<range.length;i++) {
            ptr[i] = byte_ptr[range.location + i];
        }
    }
}

- (void) getAdcAverageValues:(uint16_t*)ptr range:(NSRange)range
{
    if (range.location + range.length > [self getNumberOfChannels]) return;
    NSUInteger i;
    @synchronized(self) {
        uint16_t* byte_ptr = (uint16_t*)[chanADCAverageVals bytes];
        for (i=0;i<range.length;i++) {
            ptr[i] = byte_ptr[range.location + i];
        }
    }
    
}

- (double) convertedValue:(int)channel
{
    double raw;
    [self convertedValues:&raw range:NSMakeRange(channel, 1)];
    return raw;
}

- (double) maxValueForChan:(int)channel
{
    return [self _interpretADCValue:0xFFFF];
}

- (double) minValueForChan:(int)channel
{
    return [self _interpretADCValue:0x0000];
}

- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit  channel:(int)channel
{
    
}

#pragma mark •••Polling
- (BOOL) isPolling
{
    return pollRunning;
}

#pragma mark •••Data records
- (void) setDataIds:(id)assigner
{
    dataId          = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];	
    return objDictionary;
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORXYCom564Model"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"ORXYCom564Decoder",                                               @"decoder",
                                 [NSNumber numberWithLong:dataId],@"dataId",
                                 [NSNumber numberWithBool:YES],@"variable",
                                 [NSNumber numberWithLong:-1],@"length",
                                 nil];
    [dataDictionary setObject:aDictionary forKey:@"XYCom564"];
    
    return dataDictionary;
}
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a Controller."];
    }
    if ([self operationMode] != kAutoscanning) {
        [NSException raise:@"Not in autoscanning mode" format:@"You must be in autoscanning mode to run in the loop."];
    }
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    isRunning = YES;
    [self _stopPolling];
    [self appendDataDescription:aDataPacket userInfo:userInfo];
    
    //cache some stuff
    [self initBoard];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    assert(!pollRunning);
    [self _readAllAdcChannels];
    [self _shipRawValues:aDataPacket];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    isRunning = NO;
}

- (void) reset
{
}


- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{

    /* The current hardware specific data is:               *
     *                                                      *
     * 0: ADScan offset from base                           *
     * 1: number of channels                                *
     * 2: how many points to average                        *
     * 3: ship data (yes when running, no when polling)     */

    configStruct->total_cards++;
    configStruct->card_info[index].hw_type_id	= kXyCom564; //should be unique
    configStruct->card_info[index].hw_mask[0] 	= dataId; //better be unique
    configStruct->card_info[index].slot			= [self slot];
    configStruct->card_info[index].crate		= [self crateNumber];
    configStruct->card_info[index].add_mod		= [self addressModifier];
    configStruct->card_info[index].base_add		= [self baseAddress];
    configStruct->card_info[index].deviceSpecificData[0]	= mIOXY564Reg[kADScan].offset; // autoreadout register
    configStruct->card_info[index].deviceSpecificData[1]	= kXVME564_NumAutoScanChannelsPerGroup << ([self autoscanMode]); //numberOfChannelsToRead
    configStruct->card_info[index].deviceSpecificData[2]	= [self averageValueNumber]; // how many points to average
    configStruct->card_info[index].deviceSpecificData[3]	= !pollRunning; // When we are polling, do not ship data

    configStruct->card_info[index].next_Card_Index 	= index+1;

    return index+1;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self _createArrays];
    [self _setChannelGains:[decoder decodeObjectForKey:@"kORXYCom564chanGains"]];
    // The super decoder handles the address Modifier output
    if ([self addressModifier] == 0x29) {
        [self setReadoutMode:kA16];
    } else {
        [self setReadoutMode:kA24];
    }

    [self setOperationMode:[decoder decodeIntForKey:@"kORXYCom564OperationMode"]];
    [self setAverageValueNumber:[decoder decodeIntForKey:@"kORXYCom564AvgValNumber"]];
    [self setAutoscanMode:[decoder decodeIntForKey:@"kORXYCom564AutoscanMode"]];
    [self setShipRecords:[decoder decodeBoolForKey:@"kORXYCom564ShipRecords"]];
    [self setInterpretADC:[decoder decodeIntForKey:@"kORXYCom564InterpretADC"]];
    NSString* ul = [decoder decodeObjectForKey:@"kORXYCom564UL"];
    if (ul != nil) [self setUserLock:YES withString:ul];
    
    [[self undoManager] enableUndoRegistration];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:channelGains forKey:@"kORXYCom564chanGains"];
    [encoder encodeInteger:[self operationMode] forKey:@"kORXYCom564OperationMode"];    
    [encoder encodeInteger:[self autoscanMode] forKey:@"kORXYCom564AutoscanMode"];
    [encoder encodeInteger:[self averageValueNumber] forKey:@"kORXYCom564AvgValNumber"];
    [encoder encodeBool:shipRecords forKey:@"kORXYCom564ShipRecords"];
    [encoder encodeInteger:interpretADC forKey:@"kORXYCom564InterpretADC"];
    [encoder encodeObject:userLocked forKey:@"kORXYCom564UL"];
}

@end

@implementation ORXYCom564Model (private)

#pragma mark ***Private
- (void) _addAverageValues:(NSData *)vals
{

    int numChans = [self getNumberOfChannels];
    uint32_t* averageValPtr = (uint32_t*)[chanADCAverageValsCache bytes];
    uint16_t* inputPtr = (uint16_t*)[vals bytes];
    int i;
    @synchronized(self) {
        for (i=0;i<numChans;i++) {
            averageValPtr[i] += inputPtr[i];
        }
        currentAverageState++;
        if (currentAverageState == averageValueNumber) {
            for (i=0;i<numChans;i++) {
                averageValPtr[i] /= averageValueNumber;
            }
            [self _setAverageADCValues:averageValPtr withLength:numChans];
            memset(averageValPtr, 0, [chanADCAverageValsCache length]);
            currentAverageState = 0;
        }
    }
    
}

- (void) _setAverageADCValues:(uint32_t *)array withLength:(int)length
{
    assert([chanADCAverageVals length] == length*sizeof(uint16_t));
    uint16_t* valPtr = (uint16_t*)[chanADCAverageVals bytes];
    int i;
    for (i=0;i<length;i++) {
        valPtr[i] = array[i];
    }
}

- (void) _setChannelGains:(NSMutableArray *)gains
{
    [gains retain];
    [channelGains release];
    channelGains = gains;
    if (channelGains == nil) {
        int i;
        channelGains = [[NSMutableArray array] retain];
        for (i=0;i<[self getNumberOfChannels];i++) {
            [channelGains addObject:[NSNumber numberWithInt:kGainOne]];
        }
    }
    
    [[NSNotificationCenter defaultCenter]
	      postNotificationOnMainThreadWithName:ORXYCom564ChannelGainChanged
	 object:self];
    
}

- (void) _setChannelADCValues:(NSData *)vals withNotify:(BOOL)notify
{
    [vals retain];
    [chanADCVals release];
    chanADCVals = vals;
    if (notify) {
        [[NSNotificationCenter defaultCenter]
              postNotificationOnMainThreadWithName:ORXYCom564ADCValuesChanged
         object:self];
    }    
}

#pragma mark •••Polling
- (void) _stopPolling
{
    pollStopRequested = YES;
}

- (void) _startPolling
{
	[self _setUpPolling:YES];
}

- (void) _setUpPolling:(BOOL)verbose
{
    if(pollRunning)return;
    if (isRunning) {
        if(verbose) NSLog(@"XVME564,%d,%d, can not poll while it is in the run loop\n",[self crateNumber],[self slot]);
        return;
    }
    if ([self operationMode] != kAutoscanning) {
        if(verbose) NSLog(@"XVME564,%d,%d, must be in autoscan mode to poll\n",[self crateNumber],[self slot]);
        return;
    }
    pollStopRequested = NO;

    [NSThread detachNewThreadSelector:@selector(_pollingThread)
                             toTarget:self
                           withObject:nil];

}

- (void) _pollAllChannels
{
    [self _readAllAdcChannels];
    if ([self shipRecords]) {
        [self _shipRawValues:nil];
    }
}

- (void) _pollingThread
{
    NSLog(@"Beginning thread: %@, (Crate %d Slot %d) \n",[self objectName],[self crateNumber],[self slot]);
    @synchronized(self) {
        if (pollRunning) return;
        pollRunning = YES;
    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationOnMainThreadWithName:ORXYCom564PollingActivityChanged
                                   object:self];

    // perform the run loop
    int tryTime = 0;
    NSDate* start = [[NSDate alloc] init];
    @try{
        [self initBoard];
        while(!pollStopRequested){
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            [self _pollAllChannels];
	        tryTime += 1;
            if (tryTime == 1000) {
                NSDate* tmp = [[NSDate alloc] init];
                [self _setPollingSpeed:[tmp timeIntervalSinceDate:start]/1000];
                [start release];
                start = tmp;
                tryTime = 0;
                [NSThread sleepForTimeInterval:0.001];
            }
            [pool release];
        }
    } @catch (NSException* e) {
        [self _stopPolling];
        NSLogColor([NSColor redColor], @"Exception at (%@, Crate %d, Slot %d) readout thread, stopping.\n",
                   [self objectName],[self crateNumber],[self slot]);
        NSLogColor([NSColor redColor], @"%@\n",e);
    }
    pollRunning = NO;
    [start release];
    [self _setPollingSpeed:0.0];
    [[NSNotificationCenter defaultCenter]
     postNotificationOnMainThreadWithName:ORXYCom564PollingActivityChanged
                                   object:self];
    
   NSLog(@"Ending thread: %@ (Crate %d, Slot %d) \n",[self objectName],[self crateNumber],[self slot]);
}


- (void) _shipRawValues:(ORDataPacket*)dataPacket
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
	
	if(!runInProgress) return;
    int channelsToRead =kXVME564_NumAutoScanChannelsPerGroup << ([self autoscanMode]);
    int headernumber = 4;
    uint32_t data[headernumber+channelsToRead];
    
    data[1] = (([self crateNumber]&0x01e)<<21) |  (([self slot]&0x1f) << 16);
    
    //get the time(UT!)
    struct timeval ut_time;
    gettimeofday(&ut_time, NULL);
    data[2] = (uint32_t)ut_time.tv_sec;	//seconds since 1970
    data[3] = (uint32_t)ut_time.tv_usec;	//seconds since 1970
    int index = headernumber;
    int i;
    for(i=0;i<channelsToRead;i++){
        uint16_t val = [self getAdcValueAtChannel:i];
        data[index++] = (i&0xff)<<16 | (val & 0xffff);
    }
    data[0] = dataId | index;
    
    if(dataPacket != nil) {
        [dataPacket addLongsToFrameBuffer:data length:index];
    } else if(index>headernumber){
        //the full record goes into the data stream via a notification
        [[NSNotificationCenter defaultCenter]
         postNotificationOnMainThreadWithName:ORQueueRecordForShippingNotification
                                        object:[NSData dataWithBytes:data length:sizeof(data[0])*index]];
    }
}

- (void) _createArrays
{
    chanADCAverageValsCache = [[NSMutableData dataWithLength:[self getNumberOfChannels]*sizeof(uint32_t)] retain];
    chanADCVals = [[NSMutableData dataWithLength:[self getNumberOfChannels]*sizeof(uint16_t)] retain];
    chanADCAverageVals = [[NSMutableData dataWithLength:[self getNumberOfChannels]*sizeof(uint16_t)] retain];
}

#pragma mark ***Readout

- (void) _readAllAdcChannels
{
    @synchronized(self) {
        if (operationMode != kAutoscanning) {
            [NSException raise:@"XVME-564 Exception" format:@"XVME not in autoscanning mode"];
        }
        int channelsToRead = kXVME564_NumAutoScanChannelsPerGroup << ([self autoscanMode]);
        
        uint16_t* readOut = (uint16_t*)[chanADCVals bytes];
        uint16_t scratchOut[channelsToRead];
        assert([chanADCVals length] == channelsToRead*sizeof(readOut[0]));
        
        [[self adapter]
                 readWordBlock:scratchOut
                     atAddress:[self baseAddress] + mIOXY564Reg[kADScan].offset
                     numToRead:channelsToRead
                    withAddMod:[self addressModifier]
                 usingAddSpace:0x01];
        int i;
        for (i=0;i<channelsToRead;i++) readOut[i] = [self _recenterValue:scratchOut[i]];
    }
    [self _addAverageValues:chanADCVals];
    
}

- (void) _setPollingSpeed:(NSTimeInterval)aTime
{
    if (pollSpeed == aTime) return;
    pollSpeed = aTime;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORXYCom564PollingSpeedHasChanged
                                                        object:self];
}

- (double) _interpretADCValue:(uint16_t)raw
{
    // we assume value is recentered.
    
    double volrange = 20; // +-10V
    double adcrange = (double)(0xFFFF + 1); // 16bit
    double _offset = 0;
    
    switch ([self interpretADC]) {
        case kRawADC: return raw;
        case k0to5Volts:
            volrange = 5.; break;
        case k0to10Volts:
            volrange = 10.; break;
        case kPlusMinus5Volts:
            volrange = 10.;
            _offset = (double) 0x8000;
            break;
        case kPlusMinus10Volts:
            volrange = 20.;
            _offset = (double) 0x8000;
            break;
        default: break;
    }
    double vol = raw - _offset; // offset
    return vol * volrange / adcrange; //scaling
}

- (uint16_t) _recenterValue:(uint16_t)raw
{
    // first thing, centering so that 0x8000 is 0.
    if (raw < 0x8000) {
        // Really positive numbers
        raw += 0x8000;
    } else {
        // really negative numbers
        raw -= 0x8000;
    }
    return raw;
}

@end
