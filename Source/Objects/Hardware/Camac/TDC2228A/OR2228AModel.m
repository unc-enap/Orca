/*
 *  OR2228AModel.cpp
 *  Orca
 *
 *  Created by Mark Howe on 6/30/05.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
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

#pragma mark ¥¥¥Imported Files
#import "OR2228AModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORCamacControllerCard.h"
#import "ORCamacCrateModel.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"

NSString* OR2228AModelOverFlowCheckTimeChanged = @"OR2228AModelOverFlowCheckTimeChanged";
NSString* OR2228AOnlineMaskChangedNotification		= @"OR2228AOnlineMaskChangedNotification";
NSString* OR2228ASettingsLock						= @"OR2228ASettingsLock";
NSString* OR2228ASuppressZerosChangedNotification   = @"OR2228ASuppressZerosChangedNotification";

@interface OR2228AModel (private)
- (void) _checkForOverFlow;
@end

@implementation OR2228AModel

#pragma mark ¥¥¥Initialization
- (id) init
{		
    self = [super init];
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [overflowAlarm clearAlarm];
    [overflowAlarm release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"2228ACard"]];
}

- (void) makeMainController
{
    [self linkToController:@"OR2228AController"];
}

- (NSString*) helpURL
{
	return @"CAMAC/2228A.html";
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"2228";
}

- (unsigned short) overFlowCheckTime
{
    return overFlowCheckTime;
}

- (void) setOverFlowCheckTime:(unsigned short)aOverFlowCheckTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOverFlowCheckTime:overFlowCheckTime];
	
	if(aOverFlowCheckTime<10)aOverFlowCheckTime = 10;
    
    overFlowCheckTime = aOverFlowCheckTime;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:OR2228AModelOverFlowCheckTimeChanged object:self];
}
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (unsigned char)onlineMask {
	
    return onlineMask;
}

- (void)setOnlineMask:(unsigned char)anOnlineMask {
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:[self onlineMask]];
	
    onlineMask = anOnlineMask;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:OR2228AOnlineMaskChangedNotification
	 object:self];
	
}

- (BOOL)onlineMaskBit:(int)bit
{
	return onlineMask&(1<<bit);
}

- (void) setOnlineMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned char aMask = onlineMask;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setOnlineMask:aMask];
}

- (BOOL) suppressZeros
{
	return suppressZeros;
}
- (void) setSuppressZeros:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSuppressZeros:suppressZeros];
	
    suppressZeros = aFlag;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:OR2228ASuppressZerosChangedNotification
	 object:self];
    
}

#pragma mark ¥¥¥DataTaker

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kShortForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (void) reset
{
	//[self initBoard];    
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"OR2228ADecoderForTdc",                        @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:NO],                   @"variable",
								 [NSNumber numberWithLong:IsShortForm(dataId)?1:2],@"length",
								 [NSNumber numberWithBool:YES],                  @"canBeGated",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"tdc"];
    return dataDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	
    if(![self adapter]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI-CAMAC Controller (i.e. a CC32)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"OR2228AModel"];    
    
    //----------------------------------------------------------------------------------------
    controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
    unChangingDataPart   = (([self crateNumber]&0xf)<<21) | (([self stationNumber]& 0x0000001f)<<16); //doesn't change so do it here.
	cachedStation = [self stationNumber];
    [self clearExceptionCount];
    
	//[self initBoard];
    
    int i;
	onlineChannelCount = 0;
    for(i=0;i<8;i++){
        if(onlineMask & (0x1<<i)){
            onlineList[onlineChannelCount] = i;
            onlineChannelCount++;
        }
    }
    
	
    //if([[userInfo objectForKey:@"doinit"]intValue]){
	//	[self generalReset];
    //}
    //[self resetLAM];
	firstTime = YES;
	[self disableLAMEnableLatch];
	[self resetLAM];
	
	[self performSelector:@selector(_checkForOverFlow) withObject:nil afterDelay:[self overFlowCheckTime]];
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    NSString* errorLocation = @"";
    @try {
        
		if(!firstTime){
			//check the LAM
			unsigned short dummy;
			unsigned short status = [controller camacShortNAF:cachedStation a:0 f:8 data:&dummy];
			if(isQbitSet(status)) { //LAM status comes back in the Q bit
				if(onlineChannelCount){
					int i;
					for(i=0;i<onlineChannelCount;i++){
						//read one tdc channnel
						unsigned short tdcValue;
						[controller camacShortNAF:cachedStation a:onlineList[i] f:0 data:&tdcValue];
						if(!(suppressZeros && tdcValue==0)){
							if(IsShortForm(dataId)){
								unsigned long data = dataId | unChangingDataPart | (onlineList[i]&0xf)<<12 | (tdcValue & 0xfff);
								[aDataPacket addLongsToFrameBuffer:&data length:1];
							}
							else {
								unsigned long data[2];
								data[0] =  dataId | 2;
								data[1] =  unChangingDataPart | (onlineList[i]&0xf)<<12 | (tdcValue & 0xfff);
								[aDataPacket addLongsToFrameBuffer:data length:2];
							}
						}
					}
				}
				[controller camacShortNAF:[self stationNumber] a:0 f:9 data:&dummy];
			}
		}
		else {
			[self generalReset];
			[self enableLAMEnableLatch];
			[self resetLAM];			
			unsigned short dummy;
			[controller camacShortNAF:cachedStation a:7 f:2 data:&dummy];
			firstTime = NO;
		}
	}
	@catch (NSException* localException){
	
		NSLogError(@"",@"2228A Card Error",errorLocation,nil);
		[self incExceptionCount];
		[localException raise];
	}
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [overflowAlarm clearAlarm];
    [overflowAlarm release];
	overflowAlarm = nil;
	[self performSelector:@selector(_checkForOverFlow) withObject:nil afterDelay:[self overFlowCheckTime]];
}


#pragma mark ¥¥¥Hardware Test functions
- (void) readNoReset
{
    if(onlineMask){
        NSLog(@"2228A Read/No reset for Station %d\n",[self stationNumber]);
        int i;
        for(i=0;i<8;i++){
            //read one tdc channnel
            if(onlineMask & (0x1<<i)){
                unsigned short tdcValue;
                [[self adapter] camacShortNAF:[self stationNumber] a:i f:0 data:&tdcValue];
                
                NSLog(@"chan: %d  tdcValue:%d\n",i,tdcValue);
            }
        }
    }
    else NSLog(@"No channels online for 2228A Station %d\n",[self stationNumber]);
}

- (void) readReset
{
    if(onlineMask){
        BOOL resetDone = NO;
        NSLog(@"2228A Read/Reset for Station %d\n",[self stationNumber]);
        int i;
        for(i=0;i<8;i++){
            //read one tdc channnel
            if(onlineMask & (0x1<<i)){
                unsigned short tdcValue;
                [[self adapter] camacShortNAF:[self stationNumber] a:i f:2 data:&tdcValue];
                if(i==7)resetDone = YES;
                NSLog(@"chan: %d  tdcValue:%d\n",i,tdcValue);
            }
        }
        if(!resetDone){
            unsigned short dummy;
            [[self adapter] camacShortNAF:[self stationNumber] a:7 f:2 data:&dummy]; //force reset
        }
    }
    else NSLog(@"No channels online for 2228A Station %d\n",[self stationNumber]);
}

- (void) testLAM
{
    unsigned short dummy;
    unsigned short status = [[self adapter] camacShortNAF:[self stationNumber] a:0 f:8 data:&dummy];
    NSLog(@"LAM %@ set\n",isQbitSet(status)?@"is":@"is not");
}
- (void) resetLAM
{
    unsigned short dummy;
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:10 data:&dummy];
}

- (void) generalReset;
{
    unsigned short dummy;
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:9 data:&dummy];
}

- (void) disableLAMEnableLatch
{
    unsigned short dummy;
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:24 data:&dummy];
}

- (void) enableLAMEnableLatch
{
    unsigned short dummy;
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:26 data:&dummy];
}

- (void) testAllChannels
{
    unsigned short dummy;
    [[self adapter] camacShortNAF:[self stationNumber] a:0 f:25 data:&dummy];
    [self readReset];
}

#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setOverFlowCheckTime:[decoder decodeIntForKey:@"OR2228AModelOverFlowCheckTime"]];
    [self setOnlineMask:[decoder decodeIntForKey:@"OR2228OnlineMask"]];
    [self setSuppressZeros:[decoder decodeIntForKey:@"OR2228SuppressZeros"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:overFlowCheckTime forKey:@"OR2228AModelOverFlowCheckTime"];
    [encoder encodeInt:onlineMask forKey:@"OR2228OnlineMask"];
    [encoder encodeInt:suppressZeros forKey:@"OR22281SuppressZeros"];
	
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithInt:onlineMask] forKey:@"onlineMask"];
    [objDictionary setObject:[NSNumber numberWithBool:suppressZeros] forKey:@"suppressZeros"];
    [objDictionary setObject:[NSNumber numberWithInt:overFlowCheckTime] forKey:@"overFlowCheckTime"];
    return objDictionary;
}


#pragma mark ¥¥¥HW Wizard

- (int) numberOfChannels
{
    return 12;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Online"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setOnlineMaskBit:withValue:) getMethod:@selector(onlineMaskBit:)];
    [p setActionMask:kAction_Set_Mask|kAction_Restore_Mask];
    [a addObject:p];
	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Clear"];
    [p setSetMethodSelector:@selector(readReset)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORCamacCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Station" className:@"OR2228AModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"OR2228AModel"]];
    return a;
	
}
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"OnlineMask"]) return [cardDictionary objectForKey:@"onlineMask"];
    else return nil;
}

@end

@implementation OR2228AModel (private)
- (void) _checkForOverFlow
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_checkForOverFlow) object:nil];
    if(onlineMask){
		unsigned short tdcValue;
        int i;
		int overflowCount = 0;
		int onlinecount = 0;
        for(i=0;i<8;i++){
            //read one tdc channnel
            if(onlineMask & (0x1<<i)){
				onlinecount++;
                [[self adapter] camacShortNAF:[self stationNumber] a:i f:0 data:&tdcValue];
				if(tdcValue & 0x800){
					overflowCount++;
				}
            }
        }
		if(overflowCount == onlinecount){
			[[self adapter] camacShortNAF:[self stationNumber] a:7 f:2 data:&tdcValue];
			[self resetLAM];
			if(!overflowAlarm){
				overflowAlarm = [[ORAlarm alloc] initWithName:@"2228A TDC Overflow" severity:kDataFlowAlarm];
				[overflowAlarm setSticky:NO];
			}
			[overflowAlarm setAcknowledged:NO];
			[overflowAlarm postAlarm];
            NSLogError(@"Over Flow",@"2228A TDC",[NSString stringWithFormat:@"Station %d",[self stationNumber]],nil);
		}
    }
	
	
	
	[self performSelector:@selector(_checkForOverFlow) withObject:nil afterDelay:[self overFlowCheckTime]];
}



@end
