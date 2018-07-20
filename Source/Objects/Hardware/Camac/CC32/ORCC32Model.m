/*
 
 File:		ORCC32Model.cpp
 
 Usage:		Implementation for the ARW PCI-CAMAC
 I/O Kit Kernel Extension (KEXT) Functions
 
 Author:		F. McGirt
 
 Copyright:		Copyright 2003 F. McGirt.  All rights reserved.
 
 Change History:	1/20/03
 07/29/03 MAH CENPA. Converted to Obj-C for the ORCA project.
 
 
 Notes:		617 PCI Matching is done with
 Vendor ID 0x10b5 and Device ID 0x2258
 Subsystem Vendor ID 0x9050
 Subsystem Device ID 0x2258
 
 
 There are two "features" of the ARE PCI-CAMAC hardware to
 be aware of:
 
 The hardware as delivered may come configured for use with
 MS-DOS and force all memory accesses to lie below 1MB. This
 will not work for either Mac or Win OSs and must be changed
 using the PLX tools for re-programming the EEPROM on board
 the PCI card.
 
 The PCI-CAMAC hardware forces all NAF command writes to set
 the F16 bit to a 1 and all NAF command reads to set the F16
 bit to 0.  Therefore all F values from F0 through F15 MUST
 be used with CAMAC bus read accesses and all F values from
 F16 through F31 MUST be used with CAMAC bus write accesses.
 
 
 At times delays must be used between a sequence
 of NAF commands or the CC32 status returns
 will not reflect the current status - but usually
 that of the previous NAF command.  (See the
 ORCC32ModelTest object.)  This may possibly
 be due to the design of the controller hardware, 
 the speed of the PowerMac G4, or to the use of an
 optimizing compiler which may relocate memory
 accesses.   In an effort to alleviate this problem
 all variables used to access PCI-CAMAC memory spaces
 are declared volatile.
 
 
 -----------------------------------------------------------
 This program was prepared for the Regents of the University of 
 Washington at the Center for Experimental Nuclear Physics and 
 Astrophysics (CENPA) sponsored in part by the United States 
 Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
 The University has certain rights in the program pursuant to 
 the contract and the program should not be copied or distributed 
 outside your organization.  The DOE and the University of 
 Washington reserve all rights in the program. Neither the authors,
 University of Washington, or U.S. Government make any warranty, 
 express or implied, or assume any liability or responsibility 
 for the use of this software.
 -------------------------------------------------------------
 
 
 */

#import "ORCC32Model.h"
#import "ORPCICamacModel.h"
#import "ORReadOutList.h"

#define kDelay		.005 // NAF command sequence delay

#define OExceptionCamacPowerError    @"OExceptionCamacPowerError"
#define OExceptionCamacAccessError   @"OExceptionCamacAccessError"

#define OExceptionCamacPowerErrorDescription    @"No Camac Crate Power"
#define OExceptionCamacAccessErrorDesciption 	@"Camac Access Error"

NSString* ORCC32SettingsLock			= @"ORCC32SettingsLock";

@implementation ORCC32Model
- (id) init
{
    self = [super init];
    
    ORReadOutList* r1 = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut"];
    [self setReadOutGroup:r1];
    [r1 release];
	
    return self;
}

// destructor
-(void) dealloc
{
    [readOutGroup release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"CC32Card"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORCC32Controller"];
}

- (NSString*) helpURL
{
	return @"CAMAC/CC32.html";
}

- (short) numberSlotsUsed
{
    return 2;
}

- (void) makeConnectors
{	
	//make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    [connector setOffColor:[NSColor blueColor]];
	[connector setConnectorType:'CamA'];
}

- (NSString*) settingsLock
{
	return ORCC32SettingsLock;
}

#pragma mark ¥¥¥Accessors
- (ORReadOutList*) readOutGroup
{
    return readOutGroup;
}

- (void) setReadOutGroup:(ORReadOutList*)newReadOutGroup
{
    [readOutGroup autorelease];
    readOutGroup=[newReadOutGroup retain];
}

- (NSMutableArray*) children {
    //methods exists to give common interface across all objects for display in lists
    return [NSMutableArray arrayWithObjects:readOutGroup,nil];
}
- (NSString*) shortName
{
	return @"CC32";
}
// initialize controller - enable CC32 with no autoread
- (unsigned short)  initializeContrl	
{    
    [[self controller] writeLCRegister:kLCRCntrlOffset data:kEnableCC32];
    [[self controller] writeLCRegister:kLCRIntCSROffset data:kDisableAllInterrupts];
    return [[self controller] readLCRegister:kLCRCntrlOffset];
}

// initialize controller - enable CC32 with autoread
- (unsigned short)  initializeContrlAuto
{
    [[self controller] writeLCRegister:kLCRCntrlOffset data:kEnableCC32AutoRead];
    [[self controller] writeLCRegister:kLCRIntCSROffset data:kDisableAllInterrupts];
    return [[self controller] readLCRegister:kLCRCntrlOffset];
}

// disable controller - disable CC32
- (unsigned short)  disableContrl
{    
    [[self controller] writeLCRegister:kLCRCntrlOffset data:kDisableCC32];
    [[self controller] writeLCRegister:kLCRIntCSROffset data:kDisableAllInterrupts];
    return [[self controller] readLCRegister:kLCRCntrlOffset];
}

- (unsigned short) camacStatus
{
    unsigned short theStatus = [[self controller] camacStatus];
    [self decodeStatus:theStatus];
    return theStatus;
}

- (void)  checkCratePower
{   
    [[self controller] checkCratePower];
}


- (unsigned short)  resetContrl
{   
    unsigned short statusCC32 =  [[self controller] camacShortNAF:31 a:0 f:17];
    //if( ( statusCC32 & kInitialCC32Status ) != kInitialCC32Status ) {
    //    [[NSNotificationCenter defaultCenter] postNotificationName:@"CamacResetFailedNotification" object:self];
    //    [NSException raise: OExceptionNoCamacReset format:OExceptionNoCamacReset];
    //}
    return statusCC32; 
}

- (unsigned short)  setCrateInhibit:(BOOL)state
{   
    return [[self controller] camacShortNAF:27 a:!state f:17];
}

- (unsigned short)  readCrateInhibit:(unsigned short*)state
{   
    return [[self controller] camacShortNAF:27 a:0 f:0 data:state];
}


- (uint32_t) setLAMMask:(uint32_t) mask
{
    return [[self controller] camacLongNAF:28 a:1 f:17 data:&mask]; //fx (bit 16 ==1 for write
}

- (unsigned short)  readLAMMask:(uint32_t *)mask
{
    uint32_t temp;
    unsigned short status =  [[self controller] camacLongNAF:28 a:1 f:0 data:&temp];
	*mask = temp & 0xffffff;
	return status;
} 

- (unsigned short)  readLAMStations:(uint32_t *)stations
{
	uint32_t temp;
    unsigned short status =  [[self controller] camacLongNAF:28 a:4 f:0 data:&temp];
	*stations = temp & 0xffffff;
	return status;
}

- (uint32_t) readLEDs
{
    return [[self controller] readLEDs];
}

- (unsigned short)	generateQAndX
{
	unsigned short tempTest = 0;
	return [self camacShortNAF:([self slot]+1) a:0 f:16 data:&tempTest];	
}

- (unsigned short)  executeCCycle
{
    return [[self controller] camacShortNAF:0 a:0 f:0];
}

- (unsigned short)  executeZCycle
{
    return [[self controller] camacShortNAF:0 a:1 f:0];
}

- (unsigned short)  executeCCycleIOff
{   
    return [[self controller] camacShortNAF:0 a:2 f:0];
}

- (unsigned short)  executeZCycleIOn
{
    return [[self controller] camacShortNAF:0 a:3 f:0];
}

- (unsigned short)  resetLAMFF
{   
    return [[self controller] camacShortNAF:28 a:0 f:17];
}

- (unsigned short)  readLAMFFStatus:(unsigned short*)value
{
    return [[self controller] camacShortNAF:28 a:0 f:0 data:value];
}


- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f
							 data:(unsigned short*) data
{
    return  [[self controller] camacShortNAF:n a:a f:f data:data];
}

- (unsigned short)  camacShortNAF:(unsigned short) n 
								a:(unsigned short) a 
								f:(unsigned short) f;
{
	unsigned short dummy;
    return  [[self controller] camacShortNAF:n a:a f:f data:&dummy];
}

- (unsigned short)  camacLongNAF:(unsigned short) n 
							   a:(unsigned short) a 
							   f:(unsigned short) f
							data:(uint32_t*) data
{
    return  [[self controller] camacLongNAF:n a:a f:f data:data];
}


- (unsigned short)  camacShortNAFBlock:(unsigned short) n 
									 a:(unsigned short) a 
									 f:(unsigned short) f
								  data:(unsigned short*) data
                                length:(uint32_t)    numWords
{
    return  [[self controller] camacShortNAFBlock:n a:a f:f data:data length:numWords];
}

- (unsigned short)  camacLongNAFBlock:(unsigned short) n 
									a:(unsigned short) a 
									f:(unsigned short) f
								 data:(uint32_t*) data
							   length:(uint32_t)    numWords
{
    return  [[self controller] camacLongNAFBlock:n a:a f:f data:data length:numWords];
}


- (void) delay:(float)delayValue
{
    [NSThread sleepUntilDate:[[NSDate date] dateByAddingTimeInterval:delayValue]];
}

- (unsigned short) execute
{
    unsigned short data = cmdWriteValue; //copy it so we don't changed the orginal value
	BOOL access = cmdSelection<16?kCamacReadAccess:kCamacWriteAccess;
	if(access == kCamacWriteAccess){
		NSLog(@"Executed NAF write command:%d Station:%d Subaddress:%d Value:%d\n",cmdSelection,cmdStation,cmdSubAddress,cmdWriteValue);
	}
	else {
		NSLog(@"Executed NAF read command:%d Station:%d Subaddress:%d\n",cmdSelection,cmdStation,cmdSubAddress);
	}
    unsigned short theStatus = [[self controller] camacShortNAF:cmdStation a:cmdSubAddress f:cmdSelection data:&data];
    [self decodeStatus:theStatus];
	
	BOOL CC32LAM = lookAtMe;
	uint32_t theStations;
	[self readLAMStations:&theStations];
	lookAtMe = (theStations >> (cmdStation-1)) & 0x1;
	
	uint32_t theMask;
	theStatus = [self readLAMMask:&theMask]; 
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORCamacControllerCmdValuesChangedNotification
	 object:self];
    
    
	NSLog(@"CC32:         LAM:%@ Mask:0x%x LAMs(ALL):0x%x\n",CC32LAM?@"Set":@"Clr",theMask,theStations);
    NSLog(@"Station %2d:  LAM:%@ Q:%d X:%d I:%d  Value:0x%08x\n",cmdStation,lookAtMe?@"Set":@"Clr",cmdResponse,cmdAccepted,inhibit,data);
    return theStatus;
}


#pragma mark ¥¥¥Test Methods
- (void) test
{
    // initialize controller - no auto read
    NSLog(@"Initialize Controller - LCR CNTRL Status: 0x%04x\n",[self initializeContrl]);
    
    [self delay:kDelay];		// use delays between calls to CC32 to get correct status
    
    // check crate power function
    @try {
        [[self controller] checkCratePower];
        NSLog(@"CheckCratePower() Finds Power ON\n");
    }
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"****** Controller Not Available ******\n");
        NSLogColor([NSColor redColor],@"****** Check Crate Power and Cable ******\n");
    }    
    if(![[self controller] powerOK])return;
    
    [self delay:kDelay];
    
    
    unsigned short statusLCRI = [[self controller] readLCRegister:kLCRIntCSROffset];
    NSLog(@"LCR INTCSR Status: 0x%04x\n",statusLCRI);
    
    [self delay:kDelay];		// use delays between calls to CC32 to get correct status
    
	// generate Q & X
	unsigned short statusCC32 = [self generateQAndX];
	[self decodeStatus:statusCC32];
    NSLog(@"Generate Q & X, Q:%d, X:%d, I:%d, LAM:%d\n", cmdResponse, cmdAccepted, inhibit, lookAtMe);
    
    [self delay:kDelay];
    
    NSLog(@"Q & X - CC32 Status: 0x%04x\n",[self camacStatus]);
    
    [self delay:kDelay];
	
    NSLog(@"LEDs: 0x%08x\n",[self readLEDs]);
    
    [self delay:kDelay];
    
    
    // reset controller
    statusCC32 = [self initializeContrl];
    
    [self delay:kDelay];
    
    NSLog(@"LEDs: 0x%08x\n",[self readLEDs]);
    
    [self delay:kDelay];
    
    // check pciadr status
    statusLCRI = [[self controller] readLCRegister:kLCRCntrlOffset];
    NSLog(@"CNTRL Status: 0x%04x\n",statusLCRI);
    
    [self delay:kDelay];
    
    statusLCRI = [[self controller] readLCRegister:kLCRIntCSROffset];
    NSLog(@"INTCSR Status: 0x%04x\n",statusLCRI);
    
    [self delay:kDelay];
    
    
    // execute C cycle
    NSLog(@"Execute C Cycle - CC32 Status: 0x%04x\n",[self executeCCycle]);
    
    [self delay:kDelay];
    
    NSLog(@"LEDs: 0x%08x\n",[self readLEDs]);
    
    [self delay:kDelay];
    
    
    // execute Z cycle
    NSLog(@"Execute Z Cycle - CC32 Status: 0x%04x\n",[self executeZCycle]);
    
    [self delay:kDelay];
    
    NSLog(@"LEDs: 0x%08x\n",[self readLEDs]);
    
    [self delay:kDelay];
    
    
    // assert crate inhibit
    NSLog(@"Assert Crate Inhibit - CC32 Status: 0x%04x\n",[self setCrateInhibit:YES]);
    
    [self delay:kDelay];
    
    NSLog(@"LEDs: 0x%08x\n",[self readLEDs]);
    
    [self delay:kDelay];
    
    
    // deassert crate inhibit
    NSLog(@"Deassert Crate Inhibit - CC32 Status: 0x%04x\n",[self setCrateInhibit:NO]);
    
    [self delay:kDelay];
    
    NSLog(@"LEDs: 0x%08x\n",[self readLEDs]);
    
    [self delay:kDelay];
    
    
    NSLog(@"LEDs: 0x%08x\n",[self readLEDs]);
    
    [self delay:kDelay];
    
    
    // execute C cycle
    NSLog(@"Execute C Cycle - CC32 Status: 0x%04x\n",[self executeCCycle]);
    
    [self delay:kDelay];
    
    
    // test dataway LAMs using internal CC32 LAM generation
    NSLog(@"Test Dataway LAMs, Reset LAM FF - CC32 Status: 0x%04x\n",[self resetLAMFF]);
    
    [self delay:kDelay];
    
    NSLog(@"Set LAM Mask - CC32 Status: 0x%08x\n",[self setLAMMask:0x00ffffff]);
    
    [self delay:kDelay];
    
    uint32_t theMask;
    unsigned int status = [self  readLAMMask:&theMask];
    NSLog(@"LAM Mask: 0x%08x, CC32 Status: 0x%04x\n",theMask,status);
    
    [self delay:kDelay];
    
    statusLCRI = [[self controller] readLCRegister:kLCRIntCSROffset];
    NSLog(@"INTCSR Status: 0x%04x\n",statusLCRI);
    
    [self delay:kDelay];
    
    unsigned short rdata = 5;
    statusCC32 = [self camacShortNAF:([self slot]+1) a:0 f:16 data:&rdata];
	[self decodeStatus:statusCC32];
    NSLog(@"Generate Q, X & LAM On Dataway, Q:%d, X:%d, I:%d, LAM:%d\n",
          cmdResponse, cmdAccepted, inhibit, lookAtMe);
    // this will not generate a lam state but a lam pulse and thus will not be detected
    // by ReadLAMStations() method below
    
    [self delay:kDelay];
    
    statusLCRI = [[self controller] readLCRegister:kLCRIntCSROffset];
    NSLog(@"INTCSR Status: 0x%04x\n",statusLCRI);
    
    [self delay:kDelay];
    
    NSLog(@"Q & X - CC32 Status: 0x%04x\n",[self camacStatus]);
    
    [self delay:kDelay];
    
    NSLog(@"LEDs: 0x%08x\n",[self readLEDs]);
    
    [self delay:kDelay];
    
    unsigned short theFFState;
    statusCC32 =[self  readLAMFFStatus:&theFFState];
    NSLog(@"LAM FF State: 0x%04x\n",theFFState);
    
    [self delay:kDelay];
    
    uint32_t theStations;
    [self  readLAMStations:&theStations];
    NSLog(@"LAM Stations: 0x%08x\n",theStations);
    // this will not detect lam generated by (n-1,0,16) <- 5 above since
    // only a lam pulse is generated - not a lam state
    
    [self delay:kDelay];
    
    [self  readLAMMask:&theMask];
    NSLog(@"LAM Mask: 0x%08x\n",theMask);
    
    [self delay:kDelay];
    
    NSLog(@"Clear LAM Mask - CC32 Status: 0x%04x\n",[self  setLAMMask:0x0000]);
    
    [self delay:kDelay];
    
    NSLog(@"LAM Mask: 0x%08x\n",[self  readLAMMask:&theMask]);
    
    [self delay:kDelay];
    
    NSLog(@"Reset LAM FF - CC32 Status: 0x%04x\n",[self  resetLAMFF]);
    
    [self delay:kDelay];
    
    // execute C cycle
    NSLog(@"Execute C Cycle - CC32 Status: 0x%04x\n",[self executeCCycle]);
    
    [self delay:kDelay];
}

#pragma mark ¥¥¥DataTaker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	//cach the dataTakers by stationNumber;
	int i;
	for(i=0;i<25;i++)dataTakers[i] = nil;
	
    NSArray* cardList = [[readOutGroup allObjects] retain];	//cache of data takers.
	id aCard;
	NSEnumerator* e = [cardList objectEnumerator];
	while(aCard = [e nextObject]){
		NSUInteger aSlot = [aCard stationNumber];
		if(aSlot<25){
			dataTakers[aSlot] = aCard;
		}
	}
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	uint32_t lamStations = 0;
	[self readLAMStations:&lamStations];
	if(lamStations){
		int i;
		for(i=0;i<25;i++){ //skip station zero
			if(lamStations & (0x1L<<i)){
				[dataTakers[i] takeData:aDataPacket userInfo:userInfo];
			}
		}
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
}

- (int) reset
{
	return 1;
}

- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [readOutGroup saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setReadOutGroup:[[[ORReadOutList alloc] initWithIdentifier:@"ReadOut"]autorelease]];
    [readOutGroup loadUsingFile:aFile];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setReadOutGroup:[decoder decodeObjectForKey:@"readOutGroup"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:readOutGroup forKey:@"readOutGroup"];
}

@end
