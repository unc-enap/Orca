//--------------------------------------------------------------------------------
/*!\class	ORCaenCard
 * \brief	Handles basic routines for accessing and controlling a CAEN VME module.
 * \methods
 *			\li \b 			- Constructor
 *			\li \b 
 * \note
 * \author	Jan M. Wouters
 * \history	2002-02-25 (mh) - Original
 *		2002-11-18 (jmw) - Modified for ORCA.
 *		2004-03-04 (mh) - added data taking code for ORCA version.
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

#import "ORVmeIOCard.h"
#import "ORCaenDataDecoder.h"
#import "ORDataPacket.h"
#import "SBC_Config.h"
#import "VME_HW_Definitions.h"


enum {
	kReadOnly,
	kWriteOnly,
	kReadWrite
};

// Word size
#define kD16 2
#define kD32 4

// Structure used to describe characteristics of hardware register.
typedef struct RegisterNamesStruct {
	NSString*       regName;
	bool		dataReset;
	bool		softwareReset;
	bool		hwReset;
	uint32_t 	addressOffset;
	short		accessType;
	short		size;
} RegisterNamesStruct; 
 
@class ORCaenDataDecoder;
 
// Class declaration.
@interface ORCaenCardModel : ORVmeIOCard  {
// Error handling
    uint32_t   	errorCount;
    uint32_t       totalEventCounter;
    uint32_t       eventCounter[ 32 ];
    
// Register information
    unsigned short  selectedRegIndex;
    unsigned short  selectedChannel;
    uint32_t   writeValue;
    
// Threshold information
    unsigned short  thresholds[ 32 ];
    uint32_t dataId;
    ORCaenDataDecoder* dataDecoder;

//data buffer
    uint32_t* dataBuffer;
}
				
#pragma mark ***Initialization
#pragma mark ***Accessors
- (uint32_t) 	errorCount;
- (uint32_t)	getTotalEventCount;
- (uint32_t) 	getEventCount: (unsigned short) i;
- (unsigned short) 	selectedRegIndex;
- (void)		setSelectedRegIndex: (unsigned short) anIndex;
- (unsigned short) 	selectedChannel;
- (void)		setSelectedChannel: (unsigned short) anIndex;
- (uint32_t) 	writeValue;
- (void)		setWriteValue: (uint32_t) anIndex;
- (unsigned short)	threshold: (unsigned short) anIndex;
- (void)		setThreshold: (unsigned short ) anIndex threshold: (unsigned short) aValue;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherObj;

#pragma mark ***CAEN commands
- (void)		read;
- (void)		write;
- (void)		read: (unsigned short) pReg returnValue: (void*) pValue;
- (void)		write: (unsigned short) pReg sendValue: (uint32_t) pValue;

- (void)		readThresholds;
- (void)		writeThresholds;
- (void)		caenInitializeForDataTaking;
- (void)		logThresholds;
- (NSString*)       decodeManufacturerCode:(short)aCode;
- (NSString*)       decodeModuleCode:(short)aCode;

#pragma mark ***Support Hardware Functions
- (void)		readThreshold: (unsigned short) pChan; 
- (void)		writeThreshold: (unsigned short) pChan;


// Methods that subclasses should define.
#pragma mark ¥¥¥Register - General routines
- (short)		getNumberRegisters;
- (uint32_t) 	getBufferOffset;
- (uint32_t) 	getThresholdOffset;
- (unsigned short) 	getDataBufferSize;
- (short)		getStatusRegisterIndex: (short) aRegister;
- (short)		getThresholdIndex;
- (short)		getOutputBufferIndex;


#pragma mark ***Register - Register specific routines
- (NSString*) 		getRegisterName: (short) anIndex;
- (uint32_t) 	getAddressOffset: (short) anIndex;
- (short)		getAccessType: (short) anIndex;
- (short)		getAccessSize: (short) anIndex;
- (BOOL)		dataReset: (short) anIndex;
- (BOOL)		swReset: (short) anIndex;
- (BOOL)		hwReset: (short) anIndex;
#pragma mark ***Misc routines
- (uint32_t*)	getDataBuffer;
- (void) flushBuffer;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) 	runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (void)	takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) 	runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark ¥¥¥HW Wizard
- (BOOL) hasParmetersToRamp;
- (void) reset;
- (int) numberOfChannels;
- (NSArray*) wizardSelections;
- (NSArray*) wizardParameters;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

@end

#pragma mark ¥¥¥External String Definitions
extern NSString* 	caenSelectedRegIndexChanged;
extern NSString* 	caenSelectedChannelChanged;
extern NSString* 	caenWriteValueChanged;
extern NSString*	caenChnlThresholdChanged;

extern NSString* 	caenChnl;

