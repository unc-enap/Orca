//
//  ORPxi8336MacModel.m
//  Orca
//
//  Created by Mark Howe on Thurs Aug 26 2010
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORPxi8336MacModel.h"

#pragma mark •••Notification Strings
NSString* ORPxi8336MacModelRangeChanged							= @"ORPxi8336MacModelRangeChanged";
NSString* ORPxi8336MacModelDoRangeChanged						= @"ORPxi8336MacModelDoRangeChanged";
NSString* ORPxi8336MacRWAddressChangedNotification				= @"ORPxi8336MacRWAddressChangedNotification";
NSString* ORPxi8336MacWriteValueChangedNotification				= @"ORPxi8336MacWriteValueChangedNotification";
NSString* ORPxi8336MacRWTypeChangedNotification					= @"ORPxi8336MacRWTypeChangedNotification";
NSString* ORPxi8336MacDeviceNameChangedNotification				= @"ORPxi8336MacDeviceNameChangedNotification";

NSString* ORPxi8336MacLock										= @"ORPxi8336MacLock";

@interface ORPxi8336MacModel (private)
- (BOOL) _findDevice;
- (void) _resetNoRaise;
- (kern_return_t) _openUserClient:(io_service_t) serviceObject
                     withDataPort:(io_connect_t) dataPort;
- (kern_return_t) _closeUserClient:(io_connect_t) dataPort;
@end


@implementation ORPxi8336MacModel
#pragma mark •••Inialization
- (id) init
{
    self = [super init];
    theHWLock = [[NSLock alloc] init];    
   	hardwareExists = NO;  
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [theHWLock release];
    [noHardwareAlarm clearAlarm];
    [noHardwareAlarm release];
    [noDriverAlarm clearAlarm];
    [noDriverAlarm release];
    [super dealloc];
}

- (void) makeConnectors
{
    //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the real owner later.
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self];
    [self setConnector: aConnector];
    [aConnector setOffColor:[NSColor darkGrayColor]];
    [aConnector setConnectorType:'PXIA'];
    [aConnector release];
}

- (void) setUpImage
{
    [self loadImage:@"Pxi8336MacCard"];
}

- (void) wakeUp
{
	//we have been restored from limbo. Most likely from a cut/paste op.
    if([self aWake])return;
    [super wakeUp];
    if( !hardwareExists){
        if([self _findDevice]){
            hardwareExists = YES;
            driverExists    = YES;
            NSLog(@"%@ Driver found.\n",[self driverPath]);
            NSLog(@"PXI Hardware found.\n");
            NSLog(@"Bridge Client Created\n");
        }
        else {
            if(!driverExists){
                NSLogColor([NSColor redColor],@"*** Unable To Locate %@ ***\n",[self driverPath]);
                if(!noDriverAlarm){
                    noDriverAlarm = [[ORAlarm alloc] initWithName:@"No PXI8336 Driver Found" severity:0];
                    [noDriverAlarm setSticky:NO];
                    [noDriverAlarm setHelpStringFromFile:@"NoPxi836DriverHelp"];
                }                      
                [noDriverAlarm setAcknowledged:NO];
                [noDriverAlarm postAlarm];
            }
            if(!hardwareExists){
                [self setDeviceName:@"PXI8336"];
                NSLogColor([NSColor redColor],@"*** Unable To Locate PXI8336 Device ***\n");
                if(!noHardwareAlarm){
                    noHardwareAlarm = [[ORAlarm alloc] initWithName:@"No Physical PXI8336 Found" severity:0];
                    [noHardwareAlarm setHelpStringFromFile:@"NoPxiHardwareHelp"];
                    
                    [noHardwareAlarm setSticky:YES];
                }                      
                [noHardwareAlarm setAcknowledged:NO];
                [noHardwareAlarm postAlarm];
            }
        }
    }
    if(hardwareExists) {
         
        @try {
            [self resetContrl];
            NSLog(@"Reset PXI8336 Controller\n");
        }
		@catch(NSException* localException) {
            NSLogColor([NSColor redColor],@"*** Unable to send PXI8336 reset ***\n");
            NSLogColor([NSColor redColor],@"*** Check PXI bus power and/or cables ***\n");
            if(okToShowResetWarning) ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
													 localException);
        }
    }
	[self setUpImage];
}

- (void)sleep
{
	//we have been deleted from the config. But since we were retained somewhere we still exist in limbo
    [super sleep];
    
    [noHardwareAlarm clearAlarm];
    [noHardwareAlarm release];
    noHardwareAlarm = nil;
	
    [noDriverAlarm clearAlarm];
    [noDriverAlarm release];
    noDriverAlarm = nil;
	
	//unmap the driver
}

- (void) makeMainController
{
    [self linkToController:@"ORPxi8336MacController"];
}

- (unsigned short) vendorID
{
	//**** change for PXI
	return 0x108a;  //<<===== put in correct vendor ID for matching to the driver
}

- (const char*) serviceClassName
{
	return "edu_unc_physics_driver_PXI8336Driver";
}

- (NSString*) driverPath
{
	return @"/System/Library/Extensions/PXI8336Driver.kext";
}


#pragma mark •••Accessors
- (void) setDeviceName: (NSString *) aDeviceName
{
    [deviceName autorelease];
    deviceName = [aDeviceName copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPxi8336MacDeviceNameChangedNotification object:self];
}

- (NSString *) deviceName
{
    return deviceName; 
}

- (unsigned short) rangeToDo
{
    return rangeToDo;
}

- (void) setRangeToDo:(unsigned short)aRange
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRangeToDo:rangeToDo];
    rangeToDo = aRange;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPxi8336MacModelRangeChanged object:self];
}

- (BOOL) doRange
{
    return doRange;
}

- (void) setDoRange:(BOOL)aDoRange
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoRange:doRange];
    doRange = aDoRange;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPxi8336MacModelDoRangeChanged object:self];
}

- (uint32_t) rwAddress
{
    return rwAddress;
}

- (void) setRwAddress:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRwAddress:[self rwAddress]];
    rwAddress = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPxi8336MacRWAddressChangedNotification object:self];
}

- (uint32_t) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    writeValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPxi8336MacWriteValueChangedNotification object:self];
}

- (unsigned int) readWriteType
{
    return readWriteType;
}

- (void) setReadWriteType:(unsigned int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setReadWriteType:readWriteType];
    readWriteType = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPxi8336MacRWTypeChangedNotification object:self];
}

#pragma mark •••Hardware Access
- (void)  checkCratePower
{
	if(hardwareExists){
	}
}

- (void) checkStatusErrors
{    
	if(hardwareExists){
	}
}

- (void) resetContrl
{
	if(hardwareExists){
	}
}

- (void) pxiSysReset:(unsigned char *)status
{
}

- (void) readLongBlock:(uint32_t *) readAddress
             atAddress:(uint32_t) pxiAddress
             numToRead:(uint32_t) numberLongs
{
    @try {
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){
			//insert call to driver to read int32_t(s)
        }
		else *readAddress = 0;
    }
	@catch(NSException* localException) {
        [self _resetNoRaise];
	}
	@finally {
        [theHWLock unlock];   //-----end critical section
	}
}

//a special read for reading fifos that reads one address multiple times
- (void) readLong:(uint32_t *) readAddress
		atAddress:(uint32_t) pxiAddress
	  timesToRead:(uint32_t) numberLongs

{
    @try {
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){           
			//insert call to driver to read int32_t(s). In this case the address should not be
			//incremented. Use for reading an autoincrementingin fifo.
        }
		else *readAddress = 0;
    }
	@catch(NSException* localException) {
        [self _resetNoRaise];
	}
	@finally {
        [theHWLock unlock];   //-----end critical section
	}
}

- (void) writeLongBlock:(uint32_t *) writeAddress
              atAddress:(uint32_t) pxiAddress
             numToWrite:(uint32_t) numberLongs
{
    @try {
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){            
 			//insert call to driver to write int32_t(s)
       }
    }
	@catch(NSException* localException) {
        [self _resetNoRaise];
	}
	@finally {
        [theHWLock unlock];   //-----end critical section
	}
}

- (void) readByteBlock:(unsigned char *) readAddress
             atAddress:(uint32_t) pxiAddress
             numToRead:(uint32_t) numberBytes
{
    @try {
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){
 			//insert call to driver to read byte(s)
       }
		else *readAddress = 0;
    }
	@catch(NSException* localException) {
        [self _resetNoRaise];
	}
	@finally {
        [theHWLock unlock];   //-----end critical section
	}
}

- (void) writeByteBlock:(unsigned char *) writeAddress
              atAddress:(uint32_t) pxiAddress
             numToWrite:(uint32_t) numberBytes
 {	
    @try {        
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){
 			//insert call to driver to write byte(s)
       }        
    }
	@catch(NSException* localException) {
        [self _resetNoRaise];
	}
	@finally {
        [theHWLock unlock];   //-----end critical section
	}
}

-  (void) readWordBlock:(unsigned short *) readAddress
              atAddress:(uint32_t) pxiAddress
              numToRead:(uint32_t) numberWords
{	
    @try {
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){            
			//insert call to driver to read short(s)
        }
		else *readAddress = 0;
    }
	@catch(NSException* localException) {
        [self _resetNoRaise];
 	}
	@finally {
        [theHWLock unlock];   //-----end critical section
	}
}

-  (void) writeWordBlock:(unsigned short *) writeAddress
               atAddress:(uint32_t) pxiAddress
              numToWrite:(uint32_t) numberWords
{	
    
    @try {        
        [theHWLock lock];   //-----begin critical section
        if(hardwareExists){			
			//insert call to driver to write short(s)
        }        
    }
	@catch(NSException* localException) {
        [self _resetNoRaise];
 	}
	@finally {
        [theHWLock unlock];   //-----end critical section
	}
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    theHWLock = [[NSLock alloc] init];    
    
    [[self undoManager] disableUndoRegistration];
    
    [self setRangeToDo:[decoder decodeIntegerForKey:@"rangeToDo"]];
    [self setDoRange:[decoder decodeBoolForKey:@"doRange"]];
    [self setRwAddress:[decoder decodeIntForKey:@"rwAddress"]];
    [self setWriteValue:[decoder decodeIntForKey:@"writeValue"]];
    [self setReadWriteType:[decoder decodeIntForKey:@"readWriteType"]];	
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:rangeToDo forKey:@"rangeToDo"];
    [encoder encodeBool:doRange forKey:@"doRange"];
	[encoder encodeInt:rwAddress forKey:@"rwAddress"];
    [encoder encodeInt:writeValue forKey:@"writeValue"];
    [encoder encodeInteger:readWriteType forKey:@"readWriteType"];
}

#pragma mark •••NSOrderedObjHolding Protocol
- (int) maxNumberOfObjects						{ return 10; }
- (int) objWidth								{ return 16; }
- (int) groupSeparation							{ return 0; }
- (NSString*) nameForSlot:(int)aSlot			{ return [NSString stringWithFormat:@"LAM Slot %d",aSlot]; }
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj	{ return NO; }
- (NSRange) legalSlotsForObj:(id)anObj			{ return NSMakeRange(0,[self maxNumberOfObjects]); }
- (int) slotAtPoint:(NSPoint)aPoint				{ return floor(((int)aPoint.y)/[self objWidth]); }
- (int) slotForObject:(id)anObj					{ return [anObj slot]; }
- (NSPoint) pointForSlot:(int)aSlot				{ return NSMakePoint(0,aSlot*[self objWidth]); }
- (int) slotForObj:(id)anObj					{ return [anObj slot]; }
- (int) numberSlotsNeededFor:(id)anObj			{ return [anObj numberSlotsUsed]; }

- (void) place:(id)anObj intoSlot:(int)aSlot
{
	[anObj setSlot: aSlot];
	[anObj moveTo:[self pointForSlot:aSlot]];
}
@end

@implementation ORPxi8336MacModel (private)
- (BOOL) _findDevice
{
	// locate PXI device in the registry and open user client in driver
	// return YES on success
	return NO;
}

- (void) _resetNoRaise
{
	//insert call for a reset. Don't throw.
}

- (kern_return_t) _openUserClient:(io_service_t) serviceObject withDataPort:(io_connect_t) aDataPort
{
	kern_return_t kernResult = 0;
	//add PXI driver open code
	return kernResult;
}

// call Close method in user client - but currently appears to do nothing
- (kern_return_t) _closeUserClient:(io_connect_t) aDataPort
{
	kern_return_t kernResult = 0;
	//add PXI driver close code
	return kernResult;
}
@end
