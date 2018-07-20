/*
 File:		ORTRS1Model.cpp
 
 Description:	CAMAC LeCroy TR8818 Transient Recorder System
 with MM8106 memory Object Implementation
 
 SUPERCLASS = CCamacIO
 
 Author:		F. McGirt
 
 Copyright:		Copyright 2003 F. McGirt.  All rights reserved.
 
 Change History:	2/3/03, First Version
 12/27/04 Converted to ObjC for use in the ORCA project. MAH CENPA, University of Washington
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
#import "ORTRS1Model.h"
#import "ORDataTypeAssigner.h"

#import "ORCamacControllerCard.h"

// definitions
#define DEFAULT_DATA_SIZE           8192L
#define DEFAULT_CONTROL_REGISTER	0x0000
#define DEFAULT_OFFSET_REGISTER		0
#define RecodeSizeInLongs (3*sizeof(int32_t) + (expectedNumberDataBytes + sizeof(int32_t))/sizeof(int32_t))


NSString* ORTRS1ModelOffsetRegisterChanged = @"ORTRS1ModelOffsetRegisterChanged";
NSString* ORTRS1ModelControlRegisterChanged = @"ORTRS1ModelControlRegisterChanged";

@implementation ORTRS1Model

#pragma mark ¥¥¥Initialization
- (id) init
{		
    self = [super init];
    
    [self setControlRegister:DEFAULT_CONTROL_REGISTER];     // initialize default control register
    [self setOffsetRegister: DEFAULT_OFFSET_REGISTER];      // initialize default offset register
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"TRS1Card"]];
}


- (void) makeMainController
{
    [self linkToController:@"ORTRS1Controller"];
}

- (NSString*) helpURL
{
	return @"CAMAC/TRS1.html";
}

- (short) numberSlotsUsed
{
    return 3;
}

#pragma mark ¥¥¥Accessors
- (NSString*) shortName
{
	return @"TRS1";
}
- (unsigned short) offsetRegister
{
    return offsetRegister;
}

- (void) setOffsetRegister:(unsigned short)aOffsetRegister
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOffsetRegister:offsetRegister];
    
    offsetRegister = aOffsetRegister;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTRS1ModelOffsetRegisterChanged object:self];
}

- (unsigned short) controlRegister
{
    return controlRegister;
}

- (void) setControlRegister:(unsigned short)aControlRegister
{
    [[[self undoManager] prepareWithInvocationTarget:self] setControlRegister:controlRegister];
    
    controlRegister = aControlRegister;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTRS1ModelControlRegisterChanged object:self];
}


#pragma mark ¥¥¥HW Access
- (void) initBoard
{
	[self writeControlRegister:controlRegister];
	[self writeOffsetRegister:offsetRegister];
	
	unsigned short theControlReg = [self readControlRegister];
	unsigned short theOffsetReg = [self readOffsetRegister];
	if(theControlReg != controlRegister)NSLog(@"TR8818 Init failed: control Reg readback didn't match (%d != %d)\n",theControlReg,controlRegister);
	if(theOffsetReg != offsetRegister)NSLog(@"TR8818 Init failed: offset Reg readback didn't match (%d != %d)\n",theOffsetReg,offsetRegister);
}

// digitize waveform, internal stop trigger
- (BOOL) digitizeWaveform:(unsigned short*)data dataSize:(unsigned int) dataSize
{
    BOOL state = YES;
    @try {
        [self armTrigger];
        [self enableRead];
        
        // calculate max data size
        const unsigned int maxDataSize = 8L * 1024L * (((controlRegister >> 8) & 0xff) + 1);
        if(dataSize > maxDataSize/2L){
            state = NO;
        }
        // read data
        else [self readDigitizer:data maxLength:dataSize];
    }
	@catch(NSException* localException) {
        state = NO;
    }
    return state;
}

// write TR8818 control register
- (void) writeControlRegister:(unsigned short) theControlRegister
{
	[[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:16  data:&theControlRegister];    
}

// read TR8818 control register
- (unsigned short) readControlRegister
{
	unsigned short theControlRegister = 0;
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:0  data:&theControlRegister];
	return theControlRegister;
}

// read TR8818 offset register
- (unsigned short) readOffsetRegister
{	
    unsigned short rdata = 0;
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:1  data:&rdata];
    return (unsigned char)( ( rdata >> 8 ) & 0x00ff );
}


// write TR8818 offset register
- (void) writeOffsetRegister:(unsigned char) theOffsetRegister
{
    unsigned short wdata = (unsigned short)theOffsetRegister;
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:19  data:&wdata];
}


// read single sample from TR8818
- (void) readSingleSample:(unsigned char*) aSingleSample
{
    unsigned short rdata;
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:1  data:&rdata];
    *aSingleSample = (unsigned char)( rdata & 0x00ff );
}

// read TR8818 module id
- (unsigned char) readModuleID
{
    unsigned short rdata;
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:3  data:&rdata];
    return rdata & 0x00ff;
}

- (void) armTrigger
{
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:9];
}

- (void) internalTrigger
{
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:25];
}


// enable readout of TR8818 memory
- (void) enableRead
{
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:17];
}

// read TR8818 digitizer memory
- (void) readDigitizer:(unsigned short*)theData maxLength:(unsigned int) theLength
{
    unsigned short n = [self stationNumber]+1;
    unsigned short *ptrData = theData;
    int ii;
    for(ii = 0; ii < theLength; ii++ ) {
        unsigned short theStatus = [[self adapter] camacShortNAF:n a:0 f:2  data:ptrData++];
        [self decodeStatus:theStatus];
        if( !cmdResponse ) break;
    }
}

// enable TR8818 LAM
- (void) enableLAM
{
    [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:26];
}

// disable TR8818 LAM
- (void) disableLAM
{
	[[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:24];
}

// test TR8818 LAM (F27)
- (BOOL) testLAM
{
    unsigned short theStatus = [[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:27];
    return isQbitSet(theStatus);
}


// clear TR8818 LAM
- (void) clearLAM
{
	[[self adapter] camacShortNAF:[self stationNumber]+1 a:0 f:10];
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

#pragma mark ¥¥¥DataTaker

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (void) reset
{
	[self initBoard];    
}

- (NSDictionary*) dataRecordDescription
{
	
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"OR8818DecoderForWaveform",                    @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:YES],                  @"variable",
								 [NSNumber numberWithLong:-1],					@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
    return dataDictionary;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	
    if(![self adapter]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI-CAMAC Controller (i.e. a CC32)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORAD3511Model"];    
    
    //----------------------------------------------------------------------------------------
    controller = [[self adapter] controller]; //cache the controller for alittle bit more speed.
    crateAndStationId   = (([self crateNumber]&0xf)<<21) | ((((uint32_t)[self stationNumber]+1)& 0x0000001f)<<16); //doesn't change so do it here.
	cachedStation = [self stationNumber]+1;
    [self clearExceptionCount];
	[self initBoard];
	
	// calculate max data size
	expectedNumberDataBytes = 8L * 1024L * (((controlRegister >> 8) & 0xff) + 1);
	
	
    dataBuffer = (uint32_t*)malloc(RecodeSizeInLongs * sizeof(uint32_t));
	firstTime = YES;
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    @try {
        
		if(!firstTime){
			unsigned short status = [controller camacShortNAF:cachedStation a:0 f:27];
			if(isQbitSet(status)) { //LAM status comes back in the Q bit
				dataBuffer[0] = dataId | RecodeSizeInLongs;
				dataBuffer[1] = crateAndStationId;
				dataBuffer[2] = expectedNumberDataBytes; 
				
				unsigned char* bytePtr = (unsigned char*) (&dataBuffer[3]);
				int ii;
				int actualByteCount = 0;
				for(ii = 0; ii < expectedNumberDataBytes; ii++ ) {
					unsigned short data;
					unsigned short theStatus = [[self adapter] camacShortNAF:cachedStation a:0 f:2  data:&data];
					if(isQbitSet(theStatus))break;
					else {
						actualByteCount++;
						if(actualByteCount <= expectedNumberDataBytes){
							*bytePtr++ = data & 0xff;
						}
						else break;
					}
				}
				
				if(actualByteCount <= expectedNumberDataBytes){
					dataBuffer[2] = actualByteCount; 
					[aDataPacket addLongsToFrameBuffer:dataBuffer length:RecodeSizeInLongs];
				}
				[self armTrigger];
				[self enableRead];
			}
		}
		else {
			firstTime = NO;
			[self enableRead];
			[self enableLAM];
			[self armTrigger];
		}
  		
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"8818 Card Error",nil);
		[self incExceptionCount];
		[localException raise];
	}
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	free(dataBuffer);
	[self disableLAM];
}


#pragma mark ¥¥¥Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
    [self setOffsetRegister:[decoder decodeIntegerForKey:@"ORTRS1ModelOffsetRegister"]];
    [self setControlRegister:[decoder decodeIntegerForKey:@"ORTRS1ModelControlRegister"]];
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:offsetRegister forKey:@"ORTRS1ModelOffsetRegister"];
    [encoder encodeInteger:controlRegister forKey:@"ORTRS1ModelControlRegister"];
}

@end
