//--------------------------------------------------------------------------------
/*!\class	ORCaenDataDecoder
 * \brief	Handles unpacking of data from CAEN VME module.  See the appropriate
 *			hardware manual to understand the data format.
 * \methods
 *			\li \b 			- Constructor
 *			\li \b 
 * \note
 * \author	Jan M. Wouters
 * \history	2002-02-25 (mh) - Original
 *			2002-11-18 (jmw) - Modified for ORCA.
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

#import "ORVmeCardDecoder.h"
//--------------------------------------------------------------------------------
// Important constants.
//--------------------------------------------------------------------------------
	#define kCaen_Header 		 0x2
	#define kCaen_ValidDatum 	 0x0
	#define kCaen_EndOfBlock 	 0x4
	#define kCaen_NotValidDatum  0x6    

// CAEN Output data interpreter
	enum {
		kCaen_GeoAddress = 0,
		kCaen_WordType,
		kCaen_Crate,
		kCaen_ChanCount,
		kCaen_ChanNumber,
		kCaen_UnderThreshold,
		kCaen_Overflow,
		kCaen_Data,
		kCaen_EventCounter,
		kNumOutputFormats    //must be last
	};

// Output data structure
	struct CaenOutputFormatsStruct {
		char*		name;
		unsigned long 	mask;
		unsigned short 	shift;
    };
    
    typedef struct CaenOutputFormatsStruct CaenOutputFormats;
    
// Status Register 2 interpreter
	enum {
		kCaen_BufferEmpty = 0,
		kCaen_BufferFull,
		kCaen_DSel0,
		kCaen_DSel1,
		kCaen_CSel0,
		kCaen_CSel1,
		kCaen_Busy,
		kCaen_DataReady,
		kNumStatusRegFormats    //must be last
	};
	
//
	struct CaenStatusRegFormatsStruct {
		char* name;
		unsigned short mask;
		unsigned short shift;
	};
    
    typedef struct CaenStatusRegFormatsStruct CaenStatusRegFormats;

//--------------------------------------------------------------------------------
// Class ORCaenDataDecoder
//--------------------------------------------------------------------------------
@interface ORCaenDataDecoder : ORVmeCardDecoder {
    CaenOutputFormats		*mCaenOutputFormats;
    CaenStatusRegFormats	*mCaenStatusRegFormats;
}

#pragma mark ***Initialization
- (void) 			initStructs;

#pragma mark ***General routines for any data word
- (BOOL) 			isHeader: (unsigned long) pDataValue;
- (BOOL) 			isEndOfBlock: (unsigned long) pDataValue;
- (BOOL) 			isValidDatum: (unsigned long) pDataValue;
- (BOOL) 			isNotValidDatum: (unsigned long) pDataValue;
- (unsigned short) 	geoAddress: (unsigned long) pDataValue;

#pragma mark ***Header decoders
- (unsigned short) 	crate: (unsigned long) pHeader;
- (unsigned short) 	numMemorizedChannels: (unsigned long) pHeader;

#pragma mark ***Data word decoders	
- (unsigned short) 	channel: (unsigned long) pDataValue;
- (unsigned long) 	adcValue: (unsigned long) pDataValue;

#pragma mark ***Status Register 1
- (BOOL) 			isDataReady: (unsigned short) pStatusReg1;
- (BOOL) 			isBusy: (unsigned short) pStatusReg1;

#pragma mark *** Status Register 2
- (BOOL) 			isBufferEmpty: (unsigned short) pStatusReg2;
- (BOOL) 			isBufferFull: (unsigned short) pStatusReg2;

#pragma mark ***Support functions.
- (unsigned short) 	decodeValueStatusReg: ( unsigned short) pDataValue
                                  ofType: (unsigned short) pType;
- (unsigned long) 	decodeValueOutput: (unsigned long) pDataValue
                               ofType: (unsigned short) pType;

- (void) printData: (NSString*) pName data:(void*) aSomeData;
- (NSString*) identifier;

@end
