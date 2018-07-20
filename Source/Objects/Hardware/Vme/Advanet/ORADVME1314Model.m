//
//  ORADVME1314Model.m
//  Orca
//
//  Created by Michael Marino on Mon 6 Feb 2012 
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORADVME1314Model.h"
#import "ORVmeCrateModel.h"
#import "ORVmeBusProtocol.h"


#define  kADVME1314DigitalOutputBase	0x10
#define  kADVME1314ModuleID             0x38

NSString* ORADVME1314WriteMaskChangedNotification 		= @"ADVME1314 WriteMask Changed Notification";
NSString* ORADVME1314WriteValueChangedNotification		= @"ADVME1314 WriteValue Changed Notification";;

@interface ORADVME1314Model (private)
- (ADVME1314ChannelDat) readHardwareState;
@end

@implementation ORADVME1314Model

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    hwLock = [[NSLock alloc] init];
    [self setAddressModifier:0x29];
    [[self undoManager] enableUndoRegistration];
	[self registerNotificationObservers];
	
	
    return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [hwLock release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"ADVME1314"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORADVME1314Controller"];
}

- (NSString*) helpURL
{
	return @"VME/ADVME1314.html";
}

- (NSString*)backgroundImagePath 
{
    return nil;
}

- (int)scaleFactor 
{
    return 100;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    
    [notifyCenter addObserver : self
                     selector : @selector(runStarting:)
                         name : ORRunAboutToStartNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStopping:)
                         name : ORRunAboutToStopNotification
                       object : nil];
    
}

- (void) runStarting:(NSNotification*)aNote
{
	//here to make things work for the process bit protocol
	[hwLock lock];	
	cachedController = [[self crate] controllerCard];
	[hwLock unlock];	
}

- (void) runStopping:(NSNotification*)aNote
{
	//here to make things work for the process bit protocol
	[hwLock lock];	
	cachedController = nil;
	[hwLock unlock];	
}


#pragma mark ¥¥¥Accessors


- (ADVME1314ChannelDat) writeMask
{
    return writeMask;
}

- (void) setWriteMask:(ADVME1314ChannelDat)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteMask:[self writeMask]];
    
    writeMask = aMask;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORADVME1314WriteMaskChangedNotification
	 object:self];
}

- (ADVME1314ChannelDat) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(ADVME1314ChannelDat)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    writeValue = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORADVME1314WriteValueChangedNotification
	 object:self];
}


#pragma mark ¥¥¥Hardware Access

- (void) syncWithHardware
{
    [self setWriteValue:[self readHardwareState]];
}

- (void) reset
{
    uint8_t temp = 0;
    [[self adapter] writeByteBlock:&temp 
                         atAddress:[self baseAddress] + 0x21 
                        numToWrite:1 
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) dump
{
    uint8_t boardID;
    [[self adapter] readByteBlock:&boardID
                         atAddress:[self baseAddress] + 0x1
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    if(boardID != kADVME1314ModuleID){
        NSLogColor([NSColor redColor], @"Warning: HW mismatch. 1314 ID object is 0x%x HW, expected 0x%x\n",boardID,kADVME1314ModuleID);       
        return;
    }
    ADVME1314ChannelDat currentState = [self readHardwareState];
    int chanBlock;   
    NSFont* font = [NSFont fontWithName:@"Monaco" size:11];    
    NSLogFont(font,@"ADVME 1314 Output, BoardID: 0x%x, Crate: %d, Slot: %d\n",boardID,[self crateNumber],[self slot]);
    NSLogFont(font,@"  Mask State:\n");
    for (chanBlock=0; chanBlock<kADVME1314Number32ChannelSets; chanBlock++) {    
        NSLogFont(font,@"  [0x%8x]: \n",writeMask.channelDat[chanBlock]);
    }    
    NSLogFont(font,@"  I/O Hardware State:\n");    
    for (chanBlock=0; chanBlock<kADVME1314Number32ChannelSets; chanBlock++) {    
        NSLogFont(font,@"  [0x%8x]: \n",currentState.channelDat[chanBlock]);
    }
}

- (void) setOutputWithMask:(ADVME1314ChannelDat) aChannelMask value:(ADVME1314ChannelDat) aMaskValue
{
    [hwLock lock];
    ADVME1314ChannelDat currentState = [self readHardwareState];
    @try {
        int chanBlock;        
        for (chanBlock=0; chanBlock<kADVME1314Number32ChannelSets; chanBlock++) {    
            uint16_t temp = currentState.channelDat[chanBlock] & 0xFFFF;
            // Reverse all the bits that we want to set 
            temp &= ~(writeMask.channelDat[chanBlock] & 0xFFFF);
            // Now set the bits we want to set
            temp |= ((writeValue.channelDat[chanBlock] & writeMask.channelDat[chanBlock]) & 0xFFFF);
            [[self adapter] writeWordBlock:&temp
                                atAddress: [self baseAddress] + kADVME1314DigitalOutputBase + 
                                    chanBlock*sizeof(writeValue.channelDat[0])
                               numToWrite: 1
                               withAddMod: [self addressModifier]
                            usingAddSpace: 0x01];           
            temp = currentState.channelDat[chanBlock] >> 16;
            // Reverse all the bits that we want to set 
            temp &= ~(writeMask.channelDat[chanBlock] >> 16);
            // Now set the bits we want to set
            temp |= ((writeValue.channelDat[chanBlock] & writeMask.channelDat[chanBlock]) >> 16);            
            [[self adapter] writeWordBlock:&temp
                                atAddress:[self baseAddress] + kADVME1314DigitalOutputBase +
                                    chanBlock*sizeof(writeValue.channelDat[0]) + sizeof(temp)
                               numToWrite:1
                               withAddMod:[self addressModifier]
                               usingAddSpace:0x01];      
        }       
	}
	@catch(NSException* localException) {
	}
	[hwLock unlock];
}

#pragma mark ¥¥¥Archival
static NSString *ORADVME1314WriteMask 		= @"ADVME1314 WriteMask";
static NSString *ORADVME1314WriteValue 		= @"ADVME1314 WriteValue";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    NSUInteger temp;
    ADVME1314ChannelDat* dat = (ADVME1314ChannelDat*)[decoder decodeBytesForKey:ORADVME1314WriteMask returnedLength:&temp];
    if (temp == sizeof(writeMask)) {
        [self setWriteMask:*dat];
    }
    dat = (ADVME1314ChannelDat*)[decoder decodeBytesForKey:ORADVME1314WriteValue returnedLength:&temp];
    if (temp == sizeof(writeValue)) {
        [self setWriteValue:*dat];
    }
    
    [[self undoManager] enableUndoRegistration];
    
    hwLock = [[NSLock alloc] init];
    [self registerNotificationObservers];
    	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeBytes:(const uint8_t*)&writeMask  length:sizeof(writeMask) forKey:ORADVME1314WriteMask];
    [encoder encodeBytes:(const uint8_t*)&writeValue length:sizeof(writeValue) forKey:ORADVME1314WriteValue];
}

#pragma mark ¥¥¥Bit Processing Protocol
- (void)processIsStarting
{
}

- (void)processIsStopping
{
}

- (void) startProcessCycle
{
	//grab the bit pattern at the start of the cycle. it
	//will not be changed during the cycle.
	memset(&processOutputMask, 0, sizeof(processOutputMask));
}

- (void) endProcessCycle
{
	//write out the output bit pattern result.
	[self setOutputWithMask:processOutputMask value:processOutputValue];
}

- (BOOL) processValue:(int)channel
{
	return YES;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
    int channelArrayNum = (channel % sizeof(processOutputMask.channelDat[0]));
    int channelBitPos = (channel / sizeof(processOutputMask.channelDat[0]));    
	processOutputMask.channelDat[channelArrayNum] |= (1L<<channelBitPos);
	if(value)	processOutputValue.channelDat[channelArrayNum] |= (1L<<channelBitPos);
	else		processOutputValue.channelDat[channelArrayNum] &= ~(1L<<channelBitPos);
}

- (NSString*) processingTitle
{
    return [NSString stringWithFormat:@"ADVME 1314 %d,%d",[self crateNumber],[self slot]];
}

@end

@implementation ORADVME1314Model (private)

- (ADVME1314ChannelDat) readHardwareState
{
    ADVME1314ChannelDat returnDat={};
    int chanBlock;
    for (chanBlock=0; chanBlock<kADVME1314Number32ChannelSets; chanBlock++) {    
        uint16_t temp;
        [[self adapter] readWordBlock:&temp 
                            atAddress:[self baseAddress]+kADVME1314DigitalOutputBase + chanBlock*sizeof(returnDat.channelDat[0]) 
                            numToRead:1 
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        returnDat.channelDat[chanBlock] = temp;
        [[self adapter] readWordBlock:&temp 
                            atAddress:[self baseAddress]+kADVME1314DigitalOutputBase + chanBlock*sizeof(returnDat.channelDat[0]) + sizeof(temp) 
                            numToRead:1 
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];        
        returnDat.channelDat[chanBlock] |= (temp << 16);        
    }
    return returnDat;
}

@end
