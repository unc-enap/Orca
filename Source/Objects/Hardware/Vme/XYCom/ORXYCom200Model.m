//-------------------------------------------------------------------------
//  ORXYCom200Model.h
//
//  Created by Mark A. Howe on Wednesday 9/18/2008.
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
#import "ORXYCom200Model.h"
#import "ORVmeCrateModel.h"

#pragma mark ***Notification Strings
NSString* ORXYCom200ModelSelectedPLTChanged	= @"ORXYCom200ModelSelectedPLTChanged";
NSString* ORXYCom200Lock					= @"ORXYCom200Lock";
NSString* ORXYCom200SelectedRegIndexChanged	= @"ORXYCom200SelectedRegIndexChanged";
NSString* ORXYCom200WriteValueChanged		= @"ORXYCom200WriteValueChanged";
NSString* ORXYCom200SelectedPLTChanged		= @"ORXYCom200SelectedPLTChanged";

@implementation ORXYCom200Model

#pragma mark •••Static Declarations

static struct {
	NSString*	  regName;
	uint32_t addressOffset;
} mIOXY200Reg[kNumRegs]={
{@"General Control",		0x01},
{@"Service Request",		0x03},
{@"A Data Direction",		0x05},
{@"B Data Direction",		0x07},
{@"C Data Direction",		0x09},
{@"Interrupt Vector",		0x0b},
{@"A Control",				0x0d},
{@"B Control",				0x0f},
{@"A Data",					0x11},
{@"B Data",					0x13},
{@"C Data",					0x19},
{@"A Alternate",			0x15},
{@"B Alternate",			0x17},
{@"Status",					0x1b},
{@"Timer Control",			0x21},
{@"Timer Interrupt Vector",	0x23},
{@"Timer Status",			0x35},
{@"Counter Preload High",	0x27},
{@"Counter Preload Mid",	0x29},
{@"Counter Preload Low",	0x2b},
{@"Count High",				0x2f},
{@"Count Mid",				0x31},		
{@"Count Lo",				0x33}		
};	

NSString* mIOXY200SubModeName[4][3] = {
{@"Dbl Buff in, Single Buff out",			@"NonLatched in, Double Buff out",		@"NonLatched in, Single Buff out"},
{@"Double Buffered in, Single Buffered out",@"Non-Latched in, Double Buffered out", @"N/A"},
{@"N/A",									@"N/A",									@"N/A"},
{@"N/A",									@"N/A",									@"N/A"}
};

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x29];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"XYCom200Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORXYCom200Controller"];
}
- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x33);
}
#pragma mark ***Accessors

- (NSArray*) chips
{
	return chips;
}

- (void) setChips:(NSArray*)anArrayOfChips
{
	[anArrayOfChips retain];
	[chips release];
	chips = anArrayOfChips;
}

- (ORPISlashTChip*) chip:(int)anIndex
{
	return [chips objectAtIndex:anIndex];
}

- (int) selectedPLT
{
    return selectedPLT;
}

- (void) setSelectedPLT:(int)aSelectedPLT
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedPLT:selectedPLT];
    
    selectedPLT = aSelectedPLT;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORXYCom200SelectedPLTChanged object:self];
}


- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}

- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:[self selectedRegIndex]];
    
    selectedRegIndex = anIndex;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom200SelectedRegIndexChanged
	 object:self];
}

- (uint32_t) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(uint32_t) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    
    writeValue = aValue;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORXYCom200WriteValueChanged
	 object:self];
}

#pragma mark •••Hardware Access
- (void) read
{
	//read hw based on the dialog settings
    short theRegIndex 		= [self selectedRegIndex];
    unsigned char theValue;
	
    @try {
        
		[self read:theRegIndex returnValue:&theValue chip:selectedPLT];
		
		NSLog(@"XYCom reg [%@]:0x%04lx\n", [self getRegisterName:theRegIndex], theValue);
        
	}
	@catch(NSException* localException) {
		NSLog(@"Can't Read [%@] on the %@.\n",
			  [self getRegisterName:theRegIndex], [self identifier]);
		[localException raise];
	}
}

- (void) write
{
	
 	//write hw based on the dialog settings
	int32_t theValue			=  [self writeValue];
    short theRegIndex 		= [self selectedRegIndex];
    
    @try {
        
        NSLog(@"Register is:%d\n", theRegIndex);
        NSLog(@"Value is   :0x%02x\n", theValue);
        
		[self write:theRegIndex sendValue:(char) theValue chip:selectedPLT];
        
	}
	@catch(NSException* localException) {
		NSLog(@"Can't write 0x%04lx to [%@] on the %@.\n",
			  theValue, [self getRegisterName:theRegIndex],[self identifier]);
		[localException raise];
	}
}


- (void) initBoard
{
	int i;
	for(i=0;i<2;i++){
		[self writePortAData:i];
		[self writePortBData:i];
		[self write:kCData sendValue:0xFF chip:i];	//write 0xff to so no interrupts  generated when dir is changed
		[self writePortCDirection:i];
		[self writeGeneralCR:i];
		[self writePortACR:i];
		[self writePortBCR:i];
		[self writePortADirection:i];
		[self writePortBDirection:i];
		[self writePortCData:i];		
	}
}

- (void) report
{
	unsigned char aValue;
	
	int i;
	NSFont* monoSpacedFont = [NSFont fontWithName:@"Monaco"	size:12];
	for(i=0;i<2;i++){
		NSLog(@"PI/T #%d\n",i+1);
		//the general control reg
		[self read:kGeneralControl returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"Mode    : %d\n", (aValue>>6) & 0x3);
		NSLogFont(monoSpacedFont,@"H12     : %@\n", ((aValue>>4) & 0x1)?@"Enabled":@"Disabled");
		NSLogFont(monoSpacedFont,@"H34     : %@\n", ((aValue>>5) & 0x1)?@"Enabled":@"Disabled");
		NSLogFont(monoSpacedFont,@"H1 Sense: %@\n", ((aValue>>0) & 0x1)?@"Active High":@"Active Low");
		NSLogFont(monoSpacedFont,@"H2 Sense: %@\n", ((aValue>>1) & 0x1)?@"Active High":@"Active Low");
		NSLogFont(monoSpacedFont,@"H3 Sense: %@\n", ((aValue>>2) & 0x1)?@"Active High":@"Active Low");
		NSLogFont(monoSpacedFont,@"H4 Sense: %@\n", ((aValue>>3) & 0x1)?@"Active High":@"Active Low");
		int mode = (aValue>>6) & 0x3;
		
		NSLog(@"Port A\n");
		
		[self read:kAControl returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"SubMode   : %@\n", mIOXY200SubModeName[mode][(aValue>>6) & 0x3]);
		int h = (aValue>>5) & 0x1;
		if(h==0) NSLogFont(monoSpacedFont,@"H2 Control: Edge-sensitive input\n");
		else {
			int v = (aValue>>4) & 03;
			if(v == 0)NSLogFont(monoSpacedFont,@"H2 Control: Output-negated\n");
			else if(v == 0x1)NSLogFont(monoSpacedFont,@"H2 Control: Output-asserted\n");
			else if(v == 0x2)NSLogFont(monoSpacedFont,@"H2 Control: Output-interlocked Handshake\n");
			else if(v == 0x3)NSLogFont(monoSpacedFont,@"H2 Control: Output-pulsed Handshake\n");
		}
		NSLogFont(monoSpacedFont,@"H2 Interrput: %@\n", ((aValue>>2) & 0x1)?@"Enabled":@"Disabled");
		NSLogFont(monoSpacedFont,@"H1 Control  : Interrupt %@\n", ((aValue>>1) & 0x1)?@"enabled":@"enabled");
		
		[self read:kADataDirection returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"Data Dir    : 0x%02x\n", aValue);
		
		[self read:kAData returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"Data Value  : 0x%02x\n", aValue);
		
		NSLog(@"Port B\n");
		
		[self read:kBControl returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"SubMode   : %@\n", mIOXY200SubModeName[mode][(aValue>>6) & 0x3]);
		h = (aValue>>5) & 0x1;
		if(h==0) NSLogFont(monoSpacedFont,@"H2 Control: Edge-sensitive input\n");
		else {
			int v = (aValue>>4) & 03;
			if(v == 0)NSLogFont(monoSpacedFont,@"H2 Control: Output-negated\n");
			else if(v == 0x1)NSLogFont(monoSpacedFont,@"H2 Control: Output-asserted\n");
			else if(v == 0x2)NSLogFont(monoSpacedFont,@"H2 Control: Output-interlocked Handshake\n");
			else if(v == 0x3)NSLogFont(monoSpacedFont,@"H2 Control: Output-pulsed Handshake\n");
		}
		NSLogFont(monoSpacedFont,@"H2 Interrput: %@\n", ((aValue>>2) & 0x1)?@"Enabled":@"Disabled");
		NSLogFont(monoSpacedFont,@"H1 Control  : Interrupt %@\n", ((aValue>>1) & 0x1)?@"enabled":@"enabled");
		
		[self read:kBDataDirection returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"Data Dir    : 0x%02x\n", aValue);
		
		[self read:kBData returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"Data Value  : 0x%02x\n", aValue);
		
		NSLog(@"Port C\n");
		[self read:kCDataDirection returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"Data Dir    : 0x%02x\n", aValue);
		
		[self read:kCData returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"Data Value  : 0x%02x\n", aValue);
		
		NSLog(@"------Timer %d------\n",i);
		[self read:kTimerControl returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"Control Value  : 0x%02x\n", aValue);
		[self read:kTimerStatus returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"Status         : 0x%02x\n", aValue);
		[self read:kCounterPreloadHigh returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"PreLoad High   : 0x%02x\n", aValue);
		[self read:kCounterPreloadMid returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"PreLoad Middle : 0x%02x\n", aValue);
		[self read:kCounterPreloadLow returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"PreLoad Low    : 0x%02x\n", aValue);
		[self read:kCountHigh returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"Count High     : 0x%02x\n", aValue);
		[self read:kCountMid returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"Count Middle   : 0x%02x\n", aValue);
		[self read:kCountLow returnValue:&aValue chip:i];
		NSLogFont(monoSpacedFont,@"Count Low      : 0x%02x\n", aValue);
	}}

- (void) read:(unsigned short) pReg returnValue:(void*) pValue chip:(int)chipIndex
{
    // Make sure that register is valid
    if (pReg >= [self getNumberRegisters]) {
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    
	unsigned char aValue;
	[[self adapter] readByteBlock:&aValue
                        atAddress:[self baseAddress] + [self getAddressOffset:pReg] + (chipIndex*0x40)
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
	
	*((unsigned char*)pValue) = aValue;
}

- (void) write:(unsigned short) pReg sendValue:(unsigned char) pValue chip:(int)chipIndex
{
    // Check that register is a valid register.
    if (pReg >= [self getNumberRegisters]){
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
	unsigned char aValue = pValue;
	[[self adapter] writeByteBlock:&aValue
						 atAddress:[self baseAddress] + [self getAddressOffset:pReg] + (chipIndex*0x40)
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
}

- (void) writeGeneralCR:(int)anIndex
{
	ORPISlashTChip* chip = [chips objectAtIndex:anIndex];
	unsigned char aValue = 0;
	aValue |= (([chip H1Sense]   & 0x1)<<0);	//H1 Sense
	aValue |= (([chip H2Sense]   & 0x1)<<1);	//H2 Sense
	aValue |= (([chip H3Sense]   & 0x1)<<2);	//H3 Sense
	aValue |= (([chip H4Sense]   & 0x1)<<3);	//H4 Sense
	aValue |= (([chip H12Enable] & 0x1)<<4);	//H12 Enable
	aValue |= (([chip H34Enable] & 0x1)<<5);	//H34 Enable
	aValue |= (([chip opMode]      & 0x3)<<6);	//Port Mode
	
	[self write:kGeneralControl sendValue:aValue chip:anIndex];
}

- (void) writePortADirection:(int)anIndex
{
	ORPISlashTChip* chip = [chips objectAtIndex:anIndex];	
	[self write:kADataDirection sendValue:[chip portADirection] chip:anIndex];
}
- (void) writePortACR:(int)anIndex
{
	ORPISlashTChip* chip = [chips objectAtIndex:anIndex];
	unsigned char aValue = 0;
	
	//special case for H1 Control
	unsigned char h1Control;
	if([chip portAH1Control] == 0)	h1Control = 0;
	else							h1Control = 0x2;
	
	aValue |= ((h1Control				& 0x3)<<0);		//H1 Control
	aValue |= (([chip portAH2Interrupt] & 0x1)<<2);		//H2 Interrupt
	if([chip portAH2Control]) {
		aValue |= (([chip portAH2Control]-1   & 0x3)<<3);	//H2 Control (note the -1 to correct for PU index
	}
	aValue |= (([chip portASubMode]     & 0x3)<<6);		//Sub Mode
	
	[self write:kAControl sendValue:aValue chip:anIndex];
}

- (void) writePortAData:(int)anIndex
{
	ORPISlashTChip* chip = [chips objectAtIndex:anIndex];	
	[self write:kAData sendValue:[chip portAData] chip:anIndex];
}

- (void) writePortBDirection:(int)anIndex
{
	ORPISlashTChip* chip = [chips objectAtIndex:anIndex];	
	[self write:kADataDirection sendValue:[chip portBDirection] chip:anIndex];
}

- (void) writePortBCR:(int)anIndex
{
	ORPISlashTChip* chip = [chips objectAtIndex:anIndex];
	unsigned char aValue = 0;
	
	//special case for H1 Control
	unsigned char h1Control;
	if([chip portBH1Control] == 0)	h1Control = 0;
	else							h1Control = 0x2;
	
	aValue |= ((h1Control				& 0x3)<<0);	//H1 Control
	aValue |= (([chip portBH2Interrupt] & 0x1)<<2);	//H2 Interrupt
	aValue |= (([chip portBH2Control]   & 0x7)<<3);	//H2 Control
	aValue |= (([chip portBSubMode]     & 0x3)<<6);	//Sub Mode
	
	[self write:kBControl sendValue:aValue chip:anIndex];
}

- (void) writePortBData:(int)anIndex
{
	ORPISlashTChip* chip = [chips objectAtIndex:anIndex];	
	[self write:kBData sendValue:[chip portBData] chip:anIndex];
}

- (void) writePortCDirection:(int)anIndex
{
	ORPISlashTChip* chip = [chips objectAtIndex:anIndex];	
	[self write:kCDataDirection sendValue:[chip portCDirection] chip:anIndex];
}

- (void) writePortCData:(int)anIndex
{
	ORPISlashTChip* chip = [chips objectAtIndex:anIndex];	
	[self write:kCData sendValue:[chip portCData] chip:anIndex];
}

- (void) writeTimerData:(int)anIndex
{
	ORPISlashTChip* chip = [chips objectAtIndex:anIndex];	
	[self write:kTimerControl sendValue:[chip timerControl] chip:anIndex];
	[self write:kCounterPreloadHigh sendValue:[chip preloadHigh] chip:anIndex];
	[self write:kCounterPreloadMid sendValue:[chip preloadMiddle] chip:anIndex];
	[self write:kCounterPreloadLow sendValue:[chip preloadLow] chip:anIndex];
}

- (short) getNumberRegisters
{
	return kNumRegs;
}

- (NSString*) getRegisterName:(short) anIndex
{
    return mIOXY200Reg[anIndex].regName;
}

- (uint32_t) getAddressOffset:(short) anIndex
{
    return mIOXY200Reg[anIndex].addressOffset;
}


- (void) initOutA:(int) i
{
	ORPISlashTChip* chip = [chips objectAtIndex:i];	
	[chip setPortAData:0x00];			// all A output lines will be low
	[chip setPortCData:0xf];			// all C (control) output lines will be high
	[chip setPortCDirection:0x1b];		// manual rec. for control register direction
	[chip setOpMode:0x00];
	[chip setH34Enable:0x00];
	[chip setH12Enable:0x00];
	[chip setH1Sense:0x00];
	[chip setH2Sense:0x00];
	[chip setH3Sense:0x00];
	[chip setH4Sense:0x00];
	[chip setPortASubMode:0x2];		//submode 1x, output negated
	[chip setPortAH2Control:0x01];	//output negated
	[chip setPortAH2Interrupt:0x0];	//Disabled
	[chip setPortAH1Control:0x0];	//Disabled
	[chip setPortADirection:0xff];  //output
	[chip setPortCData:0x00];
	
	[self initBoard];
}

- (void) initOutB:(int) i
{
	ORPISlashTChip* chip = [chips objectAtIndex:i];	
	[chip setPortBData:0x00];			// all A output lines will be low
	[chip setPortCData:0xf];			// all C (control) output lines will be high
	[chip setPortCDirection:0x1b];		// manual rec. for control register direction
	[chip setOpMode:0x00];
	[chip setH34Enable:0x00];
	[chip setH12Enable:0x00];
	[chip setH1Sense:0x00];
	[chip setH2Sense:0x00];
	[chip setH3Sense:0x00];
	[chip setH4Sense:0x00];
	[chip setPortBSubMode:0x2];		//submode 1x, output negated
	[chip setPortBH2Control:0x1];	//output negated
	[chip setPortBH2Interrupt:0x0];	//Disabled
	[chip setPortBH1Control:0x0];	//Disabled
	[chip setPortBDirection:0xff];  //output
	[chip setPortCData:0x00];
	
	[self initBoard];
}

// Function:	InitSqWave
// Description: Setup the Xycom clock on the I/O Register to run as a square wave
//              the period is based on the internal VME clock speed
//				The period should be passed as a unsigned short in 10ths of seconds
//              The fundamental clock period is 8 micro seconds per "tick" where
//               a tick is for the Preload Low.  Hence for the mid value, a tick
//               is worth 2.048 msecs.  So to convert 10ths of seconds to ticks
//               one multiplies by 48.828125
//              The tick is for the complete square wave period.
- (void) initSqWave:(int)i
{
	
	ORPISlashTChip* chip = [chips objectAtIndex:i];	
	int period = [chip period];
	
	@try {
		[self initOutA:i];
	}
	@catch(NSException* localException) {
	}
	
	// convert time to upper and lower ticks
	const double kTICKConv = 48.828125;
	double d_ticks = (double) period * kTICKConv + 0.5;
	unsigned char CounterLoadVal = (unsigned char) d_ticks;
	unsigned char CounterValHigh = ((0xff00 & CounterLoadVal) >> 8);
	unsigned char CounterValMid = CounterLoadVal;
	
	[chip setPreloadLow:0x0];							
	[chip setPreloadMiddle:CounterValMid];	
	[chip setPreloadHigh:CounterValHigh];	
	[chip setTimerControl:0x41];  // init for clock and start
	[self writeTimerData:i];
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setSelectedPLT:		[decoder decodeIntForKey:@"selectedPLT"]];
	[self setChips:				[decoder decodeObjectForKey:@"chips"]];
    [[self undoManager] enableUndoRegistration];
	
 	if(!chips){
		chips = [[NSArray arrayWithObjects:
				  [[[ORPISlashTChip alloc] initChip:0] autorelease],
				  [[[ORPISlashTChip alloc] initChip:1] autorelease],
				  nil] retain];
	}
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInteger:selectedPLT		forKey:@"selectedPLT"];
	[encoder encodeObject:chips			forKey:@"chips"];
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[chips makeObjectsPerformSelector:@selector(addParametersToDictionary:) withObject:objDictionary];
	
    return objDictionary;
}

@end


#pragma mark •••PI/T Chip
//gen reg
NSString* ORPISlashTChipModeChanged				= @"ORPISlashTChipModeChanged";
NSString* ORPISlashTChipH1SenseChanged			= @"ORPISlashTChipH2SenseChanged";
NSString* ORPISlashTChipH2SenseChanged			= @"ORPISlashTChipH2SenseChanged";
NSString* ORPISlashTChipH3SenseChanged			= @"ORPISlashTChipH3SenseChanged";
NSString* ORPISlashTChipH4SenseChanged			= @"ORPISlashTChipH4SenseChanged";
NSString* ORPISlashTChipH12EnableChanged		= @"ORPISlashTChipH12EnableChanged";
NSString* ORPISlashTChipH34EnableChanged		= @"ORPISlashTChipH34EnableChanged";

//port A
NSString* ORPISlashTChipPortASubModeChanged		= @"ORPISlashTChipPortASubModeChanged";
NSString* ORPISlashTChipPortAH1ControlChanged	= @"ORPISlashTChipPortAH1ControlChanged";
NSString* ORPISlashTChipPortAH2InterruptChanged	= @"ORPISlashTChipPortAH2InterruptChanged";
NSString* ORPISlashTChipPortAH2ControlChanged	= @"ORPISlashTChipPortAH2ControlChanged";
NSString* ORPISlashTChipPortADirectionChanged	= @"ORPISlashTChipPortADirectionChanged";
NSString* ORPISlashTChipPortATransceiverDirChanged	= @"ORPISlashTChipPortATransceiverDirChanged";
NSString* ORPISlashTChipPortADataChanged		= @"ORPISlashTChipPortADataChanged";

//port B
NSString* ORPISlashTChipPortBSubModeChanged		= @"ORPISlashTChipPortBSubModeChanged";
NSString* ORPISlashTChipPortBH1ControlChanged	= @"ORPISlashTChipPortBH1ControlChanged";
NSString* ORPISlashTChipPortBH2InterruptChanged	= @"ORPISlashTChipPortBH2InterruptChanged";
NSString* ORPISlashTChipPortBH2ControlChanged	= @"ORPISlashTChipPortBH2ControlChanged";
NSString* ORPISlashTChipPortBDirectionChanged	= @"ORPISlashTChipPortBDirectionChanged";
NSString* ORPISlashTChipPortBTransceiverDirChanged	= @"ORPISlashTChipPortBTransceiverDirChanged";
NSString* ORPISlashTChipPortBDataChanged		= @"ORPISlashTChipPortBDataChanged";

//port C
NSString* ORPISlashTChipPortCDirectionChanged	= @"ORPISlashTChipPortCDirectionChanged";
NSString* ORPISlashTChipPortCDataChanged		= @"ORPISlashTChipPortCDataChanged";

//Timer
NSString* ORPISlashTChipPreloadLowChanged		= @"ORPISlashTChipPreloadLowChanged";
NSString* ORPISlashTChipPreloadMiddleChanged	= @"ORPISlashTChipPreloadMiddleChanged";
NSString* ORPISlashTChipPreloadHighChanged		= @"ORPISlashTChipPreloadHighChanged";
NSString* ORPISlashTChipTimerControlChanged		= @"ORXYCom200ModelTimerControlChanged";
NSString* ORPISlashTChipPeriodChanged			= @"ORPISlashTChipPeriodChanged";

@implementation ORPISlashTChip
- (id) initChip:(int)aChipIndex
{
	self = [super init];
	chipIndex = aChipIndex;
	[self setPortATransceiverDir:1];
	[self setPortBTransceiverDir:1];
	[self setPortCData:0x3];
	return self;
}

- (NSUndoManager*) undoManager
{
	return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

- (int) opMode
{
    return opMode;
}

- (void) setOpMode:(int)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOpMode:opMode];
    opMode = aMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipModeChanged object:self];
}

- (NSString*) subModeName:(int)subModeIndex
{
	return mIOXY200SubModeName[opMode][subModeIndex];
}

#pragma mark --------------------
#pragma mark •••PortA
- (int) portASubMode { return portASubMode; }

- (void) setPortASubMode:(int)aPortASubMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortASubMode:portASubMode];
    portASubMode = aPortASubMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortASubModeChanged object:self];
}

- (int) portAH1Control { return portAH1Control; }

- (void) setPortAH1Control:(int)aPortAH1Control
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortAH1Control:portAH1Control];
	portAH1Control = aPortAH1Control;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortAH1ControlChanged object:self];
}

- (int) portAH2Interrupt { return portAH2Interrupt; }

- (void) setPortAH2Interrupt:(int)aPortAH2Interrupt
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortAH2Interrupt:portAH2Interrupt];    
    portAH2Interrupt = aPortAH2Interrupt;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortAH2InterruptChanged object:self];
}

- (int) portAH2Control { return portAH2Control;}

- (void) setPortAH2Control:(int)aPortAH2Control
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortAH2Control:portAH2Control];    
    portAH2Control = aPortAH2Control;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortAH2ControlChanged object:self];
}

- (int) portADirection { return portADirection; }

- (void) setPortADirection:(int)aPortADirection
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortADirection:portADirection];
	portADirection = aPortADirection;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortADirectionChanged object:self];
}
- (int) portATransceiverDir { return portATransceiverDir; }

- (void) setPortATransceiverDir:(int)aPortATransceiverDir
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortATransceiverDir:portATransceiverDir];    
    portATransceiverDir = aPortATransceiverDir;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortATransceiverDirChanged object:self];
}

- (unsigned char) portAData { return portAData; }

- (void) setPortAData:(unsigned char)aPortAData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortAData:portAData];    
    portAData = aPortAData;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortADataChanged object:self];
}

#pragma mark --------------------
#pragma mark •••PortB
- (int) portBSubMode { return portBSubMode; }

- (void) setPortBSubMode:(int)aPortBSubMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortBSubMode:portBSubMode];
    portBSubMode = aPortBSubMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortBSubModeChanged object:self];
}

- (int) portBH1Control { return portBH1Control; }

- (void) setPortBH1Control:(int)aPortBH1Control
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortBH1Control:portBH1Control];
	portBH1Control = aPortBH1Control;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortBH1ControlChanged object:self];
}

- (int) portBH2Interrupt { return portBH2Interrupt; }

- (void) setPortBH2Interrupt:(int)aPortBH2Interrupt
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortBH2Interrupt:portBH2Interrupt];    
    portBH2Interrupt = aPortBH2Interrupt;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortBH2InterruptChanged object:self];
}

- (int) portBH2Control { return portBH2Control;}

- (void) setPortBH2Control:(int)aPortBH2Control
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortBH2Control:portBH2Control];    
    portBH2Control = aPortBH2Control;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortBH2ControlChanged object:self];
}

- (int) portBDirection { return portBDirection; }

- (void) setPortBDirection:(int)aPortBDirection
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortBDirection:portBDirection];    
    portBDirection = aPortBDirection;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortBDirectionChanged object:self];
}

- (int) portBTransceiverDir { return portBTransceiverDir; }

- (void) setPortBTransceiverDir:(int)aPortBTransceiverDir
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortBTransceiverDir:portBTransceiverDir];    
    portBTransceiverDir = aPortBTransceiverDir;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortBTransceiverDirChanged object:self];
}

- (unsigned char) portBData { return portBData;}

- (void) setPortBData:(unsigned char)aPortBData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortBData:portBData];
    portBData = aPortBData;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortBDataChanged object:self];
}

#pragma mark --------------------
#pragma mark •••PortC

- (int) portCDirection { return portCDirection; }

- (void) setPortCDirection:(int)aPortCDirection
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortCDirection:portCDirection];
    portCDirection = aPortCDirection;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortCDirectionChanged object:self];
}

- (unsigned char) portCData { return portCData;}

- (void) setPortCData:(unsigned char)aPortCData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortCData:portCData];
    portCData = aPortCData;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPortCDataChanged object:self];
}

#pragma mark --------------------
#pragma mark •••General Control Reg
- (BOOL) H1Sense { return H1Sense; }

- (void) setH1Sense:(BOOL)aH1Sense
{
    [[[self undoManager] prepareWithInvocationTarget:self] setH1Sense:H1Sense];
    H1Sense = aH1Sense;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipH1SenseChanged object:self];
}

- (BOOL) H2Sense { return H2Sense; }

- (void) setH2Sense:(BOOL)aH2Sense
{
    [[[self undoManager] prepareWithInvocationTarget:self] setH2Sense:H2Sense];
    H2Sense = aH2Sense;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipH2SenseChanged object:self];
}

- (BOOL) H3Sense { return H3Sense; }

- (void) setH3Sense:(BOOL)aH3Sense
{
    [[[self undoManager] prepareWithInvocationTarget:self] setH3Sense:H3Sense];
    H3Sense = aH3Sense;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipH3SenseChanged object:self];
}

- (BOOL) H4Sense { return H4Sense; }

- (void) setH4Sense:(BOOL)aH4Sense
{
    [[[self undoManager] prepareWithInvocationTarget:self] setH4Sense:H4Sense];
    H4Sense = aH4Sense;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipH4SenseChanged object:self];
}

- (BOOL) H12Enable { return H12Enable; }

- (void) setH12Enable:(BOOL)aH12Enable
{
    [[[self undoManager] prepareWithInvocationTarget:self] setH12Enable:H12Enable];
    H12Enable = aH12Enable;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipH12EnableChanged object:self];
}

- (BOOL) H34Enable { return H34Enable; }

- (void) setH34Enable:(BOOL)aH34Enable
{
    [[[self undoManager] prepareWithInvocationTarget:self] setH34Enable:H34Enable];
    H34Enable = aH34Enable;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipH34EnableChanged object:self];
}

#pragma mark --------------------
#pragma mark •••Timer Control
- (int) period { return period; }

- (void) setPeriod:(int)aPeriod
{
	if(aPeriod==0)aPeriod = 1;
    [[[self undoManager] prepareWithInvocationTarget:self] setPeriod:period];
    period = aPeriod;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPeriodChanged object:self];
}

- (int) preloadLow { return preloadLow; }

- (void) setPreloadLow:(int)aPreloadLow
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPreloadLow:preloadLow];
    preloadLow = aPreloadLow;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPreloadLowChanged object:self];
}

- (int) preloadMiddle { return preloadMiddle; }

- (void) setPreloadMiddle:(int)aPreloadMiddle
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPreloadMiddle:preloadMiddle];
    preloadMiddle = aPreloadMiddle;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPreloadMiddleChanged object:self];
}

- (int) preloadHigh { return preloadHigh; }

- (void) setPreloadHigh:(int)aPreloadHigh
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPreloadHigh:preloadHigh];
    preloadHigh = aPreloadHigh;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipPreloadHighChanged object:self];
}

- (int) timerControl { return timerControl; }

- (void) setTimerControl:(int)aTimerControl
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimerControl:timerControl];
    timerControl = aTimerControl;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPISlashTChipTimerControlChanged object:self];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
	
	//Gen Cntrl Reg
    [self setOpMode:				[decoder decodeIntForKey:@"mode"]];
    [self setH1Sense:			[decoder decodeBoolForKey:@"H1Sense"]];
    [self setH2Sense:			[decoder decodeBoolForKey:@"H2Sense"]];
    [self setH3Sense:			[decoder decodeBoolForKey:@"H3Sense"]];
    [self setH4Sense:			[decoder decodeBoolForKey:@"H4Sense"]];
    [self setH12Enable:			[decoder decodeBoolForKey:@"H12Enable"]];
    [self setH34Enable:			[decoder decodeBoolForKey:@"H34Enable"]];
	
	//Port A
 	[self setPortASubMode:		[decoder decodeIntForKey:@"portASubMode"]];
	[self setPortAH1Control:	[decoder decodeIntForKey:@"portAH1Control"]];
    [self setPortAH2Interrupt:	[decoder decodeIntForKey:@"portAH2Interrupt"]];
    [self setPortAH2Control:	[decoder decodeIntForKey:@"portAH2Control"]];
    [self setPortADirection:	[decoder decodeIntForKey:@"portADirection"]];
 	[self setPortATransceiverDir:	[decoder decodeIntForKey:@"portATransceiverDir"]];
	[self setPortAData:			[decoder decodeIntegerForKey:@"portAData"]];
	
	//Port B
	[self setPortBSubMode:		[decoder decodeIntForKey:@"portBSubMode"]];
	[self setPortBH1Control:	[decoder decodeIntForKey:@"portBH1Control"]];
    [self setPortBH2Interrupt:	[decoder decodeIntForKey:@"portBH2Interrupt"]];
    [self setPortBH2Control:	[decoder decodeIntForKey:@"portBH2Control"]];
	[self setPortBDirection:	[decoder decodeIntForKey:@"portBDirection"]];
	[self setPortBTransceiverDir:	[decoder decodeIntForKey:@"portBTransceiverDir"]];
    [self setPortBData:			[decoder decodeIntegerForKey:@"portBData"]];
	
	//Port B
    [self setPortCDirection:	[decoder decodeIntForKey:@"portCDirection"]];
    [self setPortCData:			[decoder decodeIntegerForKey:@"portCData"]];
	
	//Timer
	[self setPreloadLow:		[decoder decodeIntForKey:@"preloadLow"]];
    [self setPreloadMiddle:		[decoder decodeIntForKey:@"preloadMiddle"]];
    [self setPreloadHigh:		[decoder decodeIntForKey:@"preloadHigh"]];
    [self setTimerControl:		[decoder decodeIntForKey:@"timerControl"]];
    [self setPeriod:			[decoder decodeIntForKey:@"period"]];
	
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	//Gen Cntrl Reg
	[encoder encodeInteger:opMode			forKey:@"mode"];
	[encoder encodeBool:H1Sense			forKey:@"H1Sense"];
	[encoder encodeBool:H2Sense			forKey:@"H2Sense"];
	[encoder encodeBool:H3Sense			forKey:@"H3Sense"];
	[encoder encodeBool:H4Sense			forKey:@"H4Sense"];
	[encoder encodeBool:H12Enable		forKey:@"H12Enable"];
	[encoder encodeBool:H34Enable		forKey:@"H34Enable"];
	
	//Port A
	[encoder encodeInteger:portASubMode		forKey:@"portASubMode"];
	[encoder encodeInteger:portAH1Control	forKey:@"portAH1Control"];
	[encoder encodeInteger:portAH2Interrupt	forKey:@"portAH2Interrupt"];
	[encoder encodeInteger:portAH2Control	forKey:@"portAH2Control"];
	[encoder encodeInteger:portADirection	forKey:@"portADirection"];
	[encoder encodeInteger:portATransceiverDir	forKey:@"portATransceiverDir"];
	[encoder encodeInteger:portAData		forKey:@"portAData"];
	
	//Port B
	[encoder encodeInteger:portBSubMode		forKey:@"portBSubMode"];
	[encoder encodeInteger:portBH1Control	forKey:@"portBH1Control"];
	[encoder encodeInteger:portBH2Interrupt	forKey:@"portBH2Interrupt"];
	[encoder encodeInteger:portBH2Control	forKey:@"portBH2Control"];
	[encoder encodeInteger:portBDirection	forKey:@"portBDirection"];
	[encoder encodeInteger:portBTransceiverDir	forKey:@"portBTransceiverDir"];
	[encoder encodeInteger:portBData		forKey:@"portBData"];
	
	//Port C
	[encoder encodeInteger:portCDirection	forKey:@"portCDirection"];
 	[encoder encodeInteger:portCData		forKey:@"portCData"];
	
	//Timer
	[encoder encodeInteger:preloadLow		forKey:@"preloadLow"];
	[encoder encodeInteger:preloadMiddle	forKey:@"preloadMiddle"];
	[encoder encodeInteger:preloadHigh		forKey:@"preloadHigh"];
	[encoder encodeInteger:timerControl		forKey:@"timerControl"];
	[encoder encodeInteger:period			forKey:@"period"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];
	
	//Gen Cntrl Reg
    [objDictionary setObject:[NSNumber numberWithInt:opMode]				forKey:@"mode"];
    [objDictionary setObject:[NSNumber numberWithBool:H1Sense]			forKey:@"H1Sense"];
    [objDictionary setObject:[NSNumber numberWithBool:H2Sense]			forKey:@"H2Sense"];
    [objDictionary setObject:[NSNumber numberWithBool:H3Sense]			forKey:@"H3Sense"];
    [objDictionary setObject:[NSNumber numberWithBool:H4Sense]			forKey:@"H4Sense"];
    [objDictionary setObject:[NSNumber numberWithInt:H12Enable]			forKey:@"H12Enable"];
    [objDictionary setObject:[NSNumber numberWithInt:H34Enable]			forKey:@"H34Enable"];
	
	//Port A
    [objDictionary setObject:[NSNumber numberWithInt:portASubMode]		forKey:@"portASubMode"];
    [objDictionary setObject:[NSNumber numberWithInt:portAH1Control]	forKey:@"portAH1Control"];
    [objDictionary setObject:[NSNumber numberWithInt:portAH2Interrupt]	forKey:@"portAH2Interrupt"];
    [objDictionary setObject:[NSNumber numberWithInt:portAH2Control]	forKey:@"portAH2Control"];
    [objDictionary setObject:[NSNumber numberWithInt:portADirection]	forKey:@"portADirection"];
    [objDictionary setObject:[NSNumber numberWithInt:portATransceiverDir]	forKey:@"portATransceiverDir"];
    [objDictionary setObject:[NSNumber numberWithInt:portAData]			forKey:@"portAData"];
	
	//Port B
    [objDictionary setObject:[NSNumber numberWithInt:portBSubMode]		forKey:@"portBSubMode"];
    [objDictionary setObject:[NSNumber numberWithInt:portBH1Control]	forKey:@"portBH1Control"];
    [objDictionary setObject:[NSNumber numberWithInt:portBH2Interrupt]	forKey:@"portBH2Interrupt"];
    [objDictionary setObject:[NSNumber numberWithInt:portBH2Control]	forKey:@"portBH2Control"];
    [objDictionary setObject:[NSNumber numberWithInt:portBDirection]	forKey:@"portBDirection"];
	[objDictionary setObject:[NSNumber numberWithInt:portBTransceiverDir]	forKey:@"portBTransceiverDir"];
	[objDictionary setObject:[NSNumber numberWithInt:portBData]			forKey:@"portBData"];
	
	//Port C
    [objDictionary setObject:[NSNumber numberWithInt:portCDirection]	forKey:@"portCDirection"];
    [objDictionary setObject:[NSNumber numberWithInt:portCData]			forKey:@"portCData"];
	
	//Timer
    [objDictionary setObject:[NSNumber numberWithInt:preloadLow]		forKey:@"preloadLow"];
    [objDictionary setObject:[NSNumber numberWithInt:preloadMiddle]		forKey:@"preloadMiddle"];
    [objDictionary setObject:[NSNumber numberWithInt:preloadHigh]		forKey:@"preloadHigh"];
    [objDictionary setObject:[NSNumber numberWithInt:timerControl]		forKey:@"timerControl"];
    [objDictionary setObject:[NSNumber numberWithInt:period]			forKey:@"period"];
	
    return objDictionary;
}

@end

