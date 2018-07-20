//--------------------------------------------------------------------------------
/*!\class	ORCaen775Model
 * \brief	Handles all access to CAEN CV775 TDC module.
 * \methods
 *			\li \b 			- Constructor
 *			\li \b 
 * \note
 * \author	Jan M. Wouters
 * \history	2002-02-25 (mh) - Original
 *			2002-11-18 (jmw) - Modified for ORCA.
 *			2003-07-01 (jmw) - Rewritten for new CAEN base class.
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

#import "ORCaenCardModel.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"

#define kCommonStopMode (0x1<<10)

// Declaration of constants for module.
enum {
	kOutputBuffer,
	kFirmWareRevision,
	kGeoAddress,
	kMCST_CBLTAddress,
	kBitSet1,
	kBitClear1,
	kInterrupLevel,
	kInterrupVector,
	kStatusRegister1,
	kControlRegister1,
	kADERHigh,
	kADERLow,
	kSingleShotReset,
	kMCST_CBLTCtrl,
	kEventTriggerReg,
	kStatusRegister2,
	kEventCounterL,
	kEventCounterH,
	kIncrementEvent,
	kIncrementOffset,
	kLoadTestRegister,
	kFCLRWindow,
	kBitSet2,
	kBitClear2,
	kWMemTestAddress,
	kMemTestWord_High,
	kMemTestWord_Low,
	kCrateSelect,
	kTestEventWrite,
	kEventCounterReset,
	kFullScaleRange,
	kRTestAddress,
	kSWComm,
	kSlideConstant,
	kADD,
	kBADD,
	kThresholds,
	kNumRegisters
};


// Size of output buffer
#define kTDCOutputBufferSize 0x1000
#define kModel775  0
#define kModel775N 1

// Class definition
@interface ORCaen775Model : ORCaenCardModel <ORDataTaker,ORHWWizard,ORHWRamping>
{
    int modelType;
	uint32_t   onlineMask;
	//cached values for speed.
	uint32_t statusAddress;
	uint32_t dataBufferAddress;
	uint32_t location;
	uint32_t dataIdN;
    BOOL commonStopMode;
    uint32_t fullScaleRange;
}


#pragma mark ¥¥¥Accessors
- (unsigned short) fullScaleRange;
- (void) setFullScaleRange:(unsigned short)aFullScaleRange;
- (BOOL) commonStopMode;
- (void) setCommonStopMode:(BOOL)aCommonStopMode;
- (int) modelType;
- (void) setModelType:(int)aModelType;
- (uint32_t)onlineMask;
- (void)			setOnlineMask:(uint32_t)anOnlineMask;
- (BOOL)			onlineMaskBit:(int)bit;
- (void)			setOnlineMaskBit:(int)bit withValue:(BOOL)aValue;
- (uint32_t) dataIdN;
- (void) setDataIdN: (uint32_t) DataId;

#pragma mark ¥¥¥Register - General routines
- (short) 			getNumberRegisters;
- (uint32_t) 	getBufferOffset;
- (unsigned short) 	getDataBufferSize;
- (uint32_t) 	getThresholdOffset:(int)aChan;
- (short) 			getStatusRegisterIndex: (short) aRegister;
- (short)			getThresholdIndex;
- (short)			getOutputBufferIndex;

#pragma mark ***Register - Register specific routines
- (void)			initBoard;
- (void)			writeFullScaleRange:(unsigned short)aValue;
- (unsigned short)   readFullScaleRange;
- (NSString*) 		getRegisterName: (short) anIndex;
- (uint32_t) 	getAddressOffset: (short) anIndex;
- (short)  			getAccessType: (short) anIndex;
- (short)  			getAccessSize: (short) anIndex;
- (BOOL)  			dataReset: (short) anIndex;
- (BOOL)  			swReset: (short) anIndex;
- (BOOL)  			hwReset: (short) anIndex;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORCaen775ModelFullScaleRangeChanged;
extern NSString* ORCaen775ModelCommonStopModeChanged;
extern NSString* ORCaen775ModelModelTypeChanged;
extern NSString* ORCaen775ModelOnlineMaskChanged;
