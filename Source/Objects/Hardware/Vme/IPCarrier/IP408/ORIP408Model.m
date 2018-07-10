//
//  ORIP408Model.cp
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
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
#import "ORIP408Model.h"
#import "ORIPCarrierModel.h"
#import "ORVmeCrateModel.h"
#import "ORDataPacket.h"
#import "ObjectFactory.h"

#define kORIP408RecordLength 7

#define  kIP408DigitalInputA15_0	0x00
#define  kIP408DigitalInputA15_8	0x00
#define  kIP408DigitalInputA7_0		0x01
#define  kIP408DigitalInputB31_16	0x02
#define  kIP408DigitalInputB31_24	0x02
#define  kIP408DigitalInputB23_16	0x03
#define  kIP408DigitalOutputA15_0 	0x04
#define  kIP408DigitalOutputA15_8	0x04
#define  kIP408DigitalOutputA7_0	0x05
#define  kIP408DigitalOutputB31_16	0x06
#define  kIP408DigitalOutputB31_24	0x06
#define  kIP408DigitalOutputB23_16	0x07

NSString* ORIP408WriteMaskChangedNotification 		= @"IP408 WriteMask Changed Notification";
NSString* ORIP408WriteValueChangedNotification		= @"IP408 WriteValue Changed Notification";
NSString* ORIP408ReadMaskChangedNotification 		= @"IP408 ReadMask Changed Notification";
NSString* ORIP408ReadValueChangedNotification		= @"IP408 ReadValue Changed Notification";

@interface ORIP408Model (private)
- (unsigned char) read408Register:(unsigned long) aRegister;
- (void) write408Register:(unsigned long) aRegister value:(unsigned char) aValue;
@end


@implementation ORIP408Model

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    hwLock = [[NSLock alloc] init];
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
    [self setImage:[NSImage imageNamed:@"IP408"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORIP408Controller"];
}

- (NSString*) helpURL
{
	return @"VME/IP408.html";
}


- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    
    [[self connector] setConnectorImageType:kVerticalRect];
    
	[ [self connector] setConnectorType: 'IP2 ' ];
	[ [self connector] addRestrictedConnectionType: 'IP1 ' ]; //can only connect to IP inputs
    
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
	cachedController = [[guardian crate] controllerCard];
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


- (unsigned long) writeMask
{
    return writeMask;
}

- (void) setWriteMask:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteMask:[self writeMask]];
    
    writeMask = aMask;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIP408WriteMaskChangedNotification
	 object:self];
}

- (unsigned long) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(unsigned long)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    writeValue = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIP408WriteValueChangedNotification
	 object:self];
}

- (unsigned long) readMask
{
    return readMask;
}

- (void) setReadMask:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setReadMask:[self readMask]];
    
    readMask = aMask;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIP408ReadMaskChangedNotification
	 object:self];
}


- (unsigned long) readValue
{
    return readValue;
}

- (void) setReadValue:(unsigned long)aValue
{
    
    readValue = aValue;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORIP408ReadValueChangedNotification
	 object:self];
}


#pragma mark ¥¥¥Hardware Access
- (unsigned long) getInputWithMask:(unsigned long) aChannelMask
{
    unsigned long aReturnValue = 0L;
    unsigned short theChannels;
    [hwLock lock];
    @try {
        for(theChannels=0; theChannels<32; theChannels+=8 ) {
            if(aChannelMask & (0x000000ff<<theChannels)){
                unsigned long theRegister;
                if( theChannels < 8 ) theRegister = kIP408DigitalInputA7_0;
                else if( theChannels < 16 ) theRegister = kIP408DigitalInputA15_8;
                else if( theChannels < 24 ) theRegister = kIP408DigitalInputB23_16;
                else theRegister = kIP408DigitalInputB31_24;
                if( aChannelMask & (0xff << theChannels)) {
                    unsigned long theResult = [self read408Register:theRegister];
                    aReturnValue |= (theResult << theChannels);
                }
            }
        }
        
	}
	@catch(NSException* localException) {
	}
	[hwLock unlock];
	
	return aReturnValue;
}


- (void) setOutputWithMask:(unsigned long) aChannelMask value:(unsigned long) aMaskValue
{
    [hwLock lock];
    @try {
		unsigned short theChannels;
		for( theChannels=0; theChannels<32; theChannels+=8 ) {
			if(aChannelMask & (0x000000ff<<theChannels)){
				unsigned long theRegister;
				if( theChannels < 8 ) theRegister = kIP408DigitalOutputA7_0;
				else if( theChannels < 16 ) theRegister = kIP408DigitalOutputA15_8;
				else if( theChannels < 24 ) theRegister = kIP408DigitalOutputB23_16;
				else theRegister = kIP408DigitalOutputB31_24;
				if( aChannelMask & (0xff << theChannels)) {
					unsigned long theResult = [self read408Register:theRegister];
					theResult &= ~(unsigned char)((aChannelMask>>theChannels) & 0xff);
					theResult |= (unsigned char)(((aChannelMask & aMaskValue)>>theChannels) & 0xff);
					[self write408Register:theRegister value:theResult];
				}
			}
		}
	}
	@catch(NSException* localException) {
	}
	[hwLock unlock];
}


#pragma mark ¥¥¥Archival
static NSString *ORIP408WriteMask 		= @"IP408 WriteMask";
static NSString *ORIP408WriteValue 		= @"IP408 WriteValue";
static NSString *ORIP408ReadMask 		= @"IP408 ReadMask";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setWriteMask:[decoder decodeIntForKey:ORIP408WriteMask]];
    [self setReadMask:[decoder decodeIntForKey:ORIP408ReadMask]];
    [self setWriteValue:[decoder decodeIntForKey:ORIP408WriteValue]];
   
    [[self undoManager] enableUndoRegistration];
    
    hwLock = [[NSLock alloc] init];
    [self registerNotificationObservers];
    	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    
    [encoder encodeInt:[self writeMask] forKey:ORIP408WriteMask];
    [encoder encodeInt:[self readMask] forKey:ORIP408ReadMask];
    [encoder encodeInt:[self writeValue] forKey:ORIP408WriteValue];
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
	processInputValue = 0L;
	processInputValue =  [self getInputWithMask:0xffffffff];
	processOutputMask = 0L;
}

- (void) endProcessCycle
{
	//write out the output bit pattern result.
	[self setOutputWithMask:processOutputMask value:processOutputValue];
}

- (BOOL) processValue:(int)channel
{
	return (processInputValue & (1L<<channel)) > 0;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
	processOutputMask |= (1L<<channel);
	if(value)	processOutputValue |= (1L<<channel);
	else		processOutputValue &= ~(1L<<channel);
}

- (NSString*) processingTitle
{
    return [NSString stringWithFormat:@"%d,%d,%@",[self crateNumber],[guardian slot],[self identifier]];
}

@end

@implementation ORIP408Model (private)
/* read IP408 register */
-(unsigned char) read408Register:(unsigned long) aRegister
{
    unsigned char aValue = 0;
	id theController;
	if(cachedController)theController =  cachedController;
	else theController = [guardian adapter];
	[theController readByteBlock:&aValue
					   atAddress:[self baseAddress] + aRegister
					   numToRead:1L
					  withAddMod:[guardian addressModifier]
				   usingAddSpace:kAccessRemoteIO];
    
    return aValue;
}

- (void) write408Register:(unsigned long) aRegister value:(unsigned char) aValue
{
    /* setup address for read operation */
	id theController;
	if(cachedController)theController =  cachedController;
	else theController = [guardian adapter];
	[theController writeByteBlock:&aValue
						atAddress:[self baseAddress] + aRegister
					   numToWrite:1L
					   withAddMod:[guardian addressModifier]
					usingAddSpace:kAccessRemoteIO];
	
    
}

@end



