//--------------------------------------------------------------------------------
// CLASS:		ORCaenDataDecoder
// Purpose:		Handles decoding of data from CAEN VME module.  
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

#import "ORCaenDataDecoder.h"
#import "ORDataSet.h"

@implementation ORCaenDataDecoder

#pragma mark ***Initialization
- (id) init
{
    self = [super init];
    [self initStructs];
    
    return self;
}

//--------------------------------------------------------------------------------
/*!
* \method	initStructs
 * \brief	Initializes the static structures used by this class.
 * \note	The data consists of three components:
 *			1) A single int32_t as header.  We overwrite the Geo portion with our record identifier.
 *			2) The data word - One for each channel of device that fired.
 *			3) The end of block - Contains the number of this event.
 * \note	Two status registers are used to determine the status of the device
 *			1) Register 1 contains the data ready and device busy flags.
 *			2) Register 2 contains the buffer empty, buffer full flags.
 */
//--------------------------------------------------------------------------------
- (void) initStructs
{
    // Output buffer format.
    static CaenOutputFormats caenOutputFormats[kNumOutputFormats] = {
    { "Geo",		 0xf8000000, 27 },	// Header
    { "WordType",    0x07000000, 24 },
    { "Crate",		 0x00ff0000, 16 },
    { "ChanCount",   0x00003f00, 8 },	
    { "ChanNum",	 0x003f0000, 16 },	// Data word format including data.
    { "UnderThres",  0x00002000, 13 },
    { "Overflow",    0x00001000, 12 },
    { "Data",		 0x00000fff,  0 },
    { "EventCounter",0x00ffffff,  0 }	// The End of Block
	}; 
    
    mCaenOutputFormats = caenOutputFormats;
    
    // CAEN Status Register.
    static CaenStatusRegFormats caenStatusRegFormats[kNumStatusRegFormats] = {
    { "BufferEmpty",	0x0002,	1},
    { "BufferFull",		0x0004,	2 },
    { "DSel0",			0x0010,	4 },
    { "DSel1",			0x0020,	5 },
    { "CSel0",			0x0040,	6 },
    { "CSel1",			0x0080,	7 },
    { "Busy",			0x0004,	0 },
    { "DataReady",		0x0001,	0 },
	};
    
    mCaenStatusRegFormats = caenStatusRegFormats;
}

#pragma mark ***General routines for any data word
- (BOOL) isHeader: (uint32_t) pDataValue
{
    return( [self decodeValueOutput: pDataValue ofType: kCaen_WordType] == kCaen_Header );
}

- (BOOL) isEndOfBlock: (uint32_t) pDataValue
{
    return( [self decodeValueOutput: pDataValue ofType: kCaen_WordType] == kCaen_EndOfBlock );
}

- (BOOL) isValidDatum: (uint32_t) pDataValue
{
    return( [self decodeValueOutput: pDataValue ofType: kCaen_WordType] == kCaen_ValidDatum );
}

- (BOOL) isNotValidDatum: (uint32_t) pDataValue
{
    return( [self decodeValueOutput: pDataValue ofType: kCaen_WordType] == kCaen_NotValidDatum );
}

- (unsigned short) geoAddress: (uint32_t) pDataValue
{
    return [self decodeValueOutput: pDataValue ofType: kCaen_GeoAddress];
}

#pragma mark ***Header decoders
- (unsigned short) crate: (uint32_t) pHeader
{
    return [self decodeValueOutput: pHeader ofType: kCaen_Crate];
}

- (unsigned short) numMemorizedChannels: (uint32_t) pHeader
{
    return [self decodeValueOutput: pHeader ofType: kCaen_ChanCount];
}

#pragma mark ***Data word decoders
- (unsigned short) channel: (uint32_t) pDataValue
{
    return( [self decodeValueOutput: pDataValue ofType: kCaen_ChanNumber] );
}

- (uint32_t) adcValue: (uint32_t) pDataValue
{
    return( [self decodeValueOutput: pDataValue ofType: kCaen_Data] );
}


#pragma mark ***Status Register 1
- (BOOL) isBusy: (unsigned short) pStatusReg1
{
    return [self decodeValueStatusReg: pStatusReg1 ofType: kCaen_Busy];
}

- (BOOL) isDataReady: (unsigned short) pStatusReg1
{
    return [self decodeValueStatusReg: pStatusReg1 ofType: kCaen_DataReady];
}

#pragma mark ***Status Register 2
- (BOOL) isBufferEmpty: (unsigned short) pStatusReg2
{
    return [self decodeValueStatusReg: pStatusReg2 ofType: kCaen_BufferEmpty];
}

-(BOOL) isBufferFull:( unsigned short) pStatusReg2
{
    return [self decodeValueStatusReg: pStatusReg2 ofType: kCaen_BufferFull];
}

#pragma mark ***Support functions.
- (unsigned short) decodeValueStatusReg: (unsigned short) pStatusRegValue
                                 ofType: (unsigned short) pType
{
    unsigned short val =  ( pStatusRegValue & mCaenStatusRegFormats[pType].mask ) >> mCaenStatusRegFormats[pType].shift;
    return val;
}

- (uint32_t) decodeValueOutput: (uint32_t) pOutputValue
                             ofType: (unsigned short) pType
{
    uint32_t val =  ( pOutputValue & mCaenOutputFormats[pType].mask ) >> mCaenOutputFormats[pType].shift;
    return val;
}

- (void) printData: (NSString*) pName data:(void*) theData
{
    short i;
    int32_t* ptr = (int32_t*)theData;
    
	int32_t length = ExtractLength(*ptr);
	++ptr; //point to the header word with the crate and channel info
	NSString* crateKey = [self getCrateKey:(*ptr >> 21)&0x0000000f];
	NSString* cardKey  = [self getCardKey: (*ptr >> 16)&0x0000001f];

    if( length == 0 ) NSLog( @"%@ Data Buffer is empty.\n", pName );
    else {
        NSLog(@"crate: %@ card: %@\n",crateKey,cardKey);
        ++ptr; //point past the header
        
        for( i = 0; i < length; i++ ){
            if( [self isHeader: ptr[i]] ){
                NSLog( @"--%@ Header\n", pName );
                NSLog( @"Geo Address  : 0x%x\n", [self decodeValueOutput: ptr[i] ofType: kCaen_GeoAddress] );
                NSLog( @"Crate        : 0x%x\n", [self decodeValueOutput: ptr[i] ofType: kCaen_Crate] );
                NSLog( @"Num Chans    : 0x%x\n", [self decodeValueOutput: ptr[i] ofType: kCaen_ChanCount] );
            }
            else if( [self isValidDatum: ptr[i]] ){
                NSLog( @"--Data Block\n");
                NSLog( @"Geo Address  : 0x%x\n", [self decodeValueOutput: ptr[i] ofType: kCaen_GeoAddress] );
                NSLog( @"Channel      : 0x%x  (un:%d ov:%d)\n", [self channel: ptr[i]],
                       [self decodeValueOutput: ptr[i] 
                                        ofType: kCaen_UnderThreshold],
                       [self decodeValueOutput: ptr[i] 
                                        ofType: kCaen_Overflow] );
                NSLog( @"Adc Value    : 0x%x\n", [self adcValue: ptr[i]] );
            }
            else if( [self isEndOfBlock: ptr[i]] ){
                NSLog( @"Geo Address  : 0x%x\n", [self decodeValueOutput: ptr[i] ofType: kCaen_GeoAddress] );
                NSLog( @"Event Counter: 0x%x\n", [self decodeValueOutput: ptr[i] ofType: kCaen_EventCounter] );
                NSLog( @"--End of Block");
            }
            else if( [self isNotValidDatum: ptr[i]] ){
                NSLog( @"xxx Invalid Data at [%d]\n", i );
                
            }
        }
    }
}

- (uint32_t) decodeData:(void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*) aDataSet
{
    short i;
    int32_t* ptr = (int32_t*) aSomeData;
    int32_t length;
    NSString* crateKey;
    NSString* cardKey;
	length = *ptr & 0x3ffff;
	++ptr; //point to the header word with the crate and channel info
	crateKey = [self getCrateKey:(*ptr >> 21)&0x0000000f];
	cardKey  = [self getCardKey: (*ptr >> 16)&0x0000001f];
            
    ++ptr; //point past the header
    for( i = 0; i < length-2; i++ ){
        if( [self isHeader: *ptr] ){
            //ignore the header for now
        }
        else if( [self isValidDatum: *ptr] ){
            [aDataSet histogram:[self adcValue: *ptr] numBins:4096 sender:self 
                withKeys:[self identifier],
                crateKey,
                cardKey,
                [self getChannelKey:[self channel: *ptr]],
                nil];
        }
        else if( [self isEndOfBlock: *ptr] ){
            //ignore end of block for now
        }
        else if( [self isNotValidDatum: *ptr] ){
            NSLogError(@"",[NSString stringWithFormat:@"%@ Data Record Error",[self identifier]],crateKey,cardKey,nil);
        }
		++ptr;
    }
    return length;
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t length = (ptr[0] & 0x003ffff);

    NSString* title= [NSString stringWithFormat:@"%@ Record\n\n",[self identifier]];
    
    NSString* len =[NSString stringWithFormat:   @"Record Length = %u\n",length-2];
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(ptr[1] >> 21)&0x0000000f];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(ptr[1] >> 16)&0x0000001f];
    NSString* timeStamp = @"No Timestamp\n";
    int firstDataIndex = 2;
    if(ptr[1] & 0x1){
        timeStamp  = [NSString stringWithFormat:@"TimeStamp = %u.%u\n",ptr[2],ptr[3]];
        firstDataIndex = 4;
    }
    
    
    NSString* restOfString = [NSString string];
    int i;
    for( i = firstDataIndex; i < length; i++ ){
         if( [self isValidDatum: ptr[i]] ){
            restOfString = [restOfString stringByAppendingFormat:@"Chan  = %d  Value = %d\n",[self channel: ptr[i]],[self adcValue: ptr[i]]];
        }
    }

    return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,len,crate,card,timeStamp,restOfString];
}


- (NSString*) identifier
{
    return @"CAEN Card";
}
@end

