//--------------------------------------------------------------------------------
/*!\class	ORCaen785Model
 * \brief	Handles all access to CAEN CV785 ADC module.
 * \methods
 *			\li \b 			- Constructor
 *			\li \b 
 * \note
 * \author	Jan M. Wouters
 * \history	2003-06-25 (jmw) - Original
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

// Declaration of constants for module.
enum {
    kOutputBuffer,		// 0000
    kFirmWareRevision,		// 1000
    kGeoAddress,		// 1002
    kMCST_CBLTAddress,		// 1004
    kBitSet1,			// 1006
    kBitClear1,			// 1008
    kInterrupLevel,		// 100A
    kInterrupVector,		// 100C
    kStatusRegister1,		// 100E
    kControlRegister1,		// 1010
    kADERHigh,			// 1012
    kADERLow,			// 1014
    kSingleShotReset,		// 1016
    kMCST_CBLTCtrl,		// 101A
    kEventTriggerReg,		// 1020
    kStatusRegister2,		// 1022
    kEventCounterL,		// 1024
    kEventCounterH,		// 1026
    kIncrementEvent,		// 1028
    kIncrementOffset,		// 102A
    kLoadTestRegister,		// 102C
    kFCLRWindow,		// 102E
    kBitSet2,			// 1032
    kBitClear2,			// 1034
    kWMemTestAddress,		// 1036
    kMemTestWord_High,		// 1038
    kMemTestWord_Low,		// 103A
    kCrateSelect,		// 103C
    kTestEventWrite,		// 103E
    kEventCounterReset,		// 1040
    kRTestAddress,		// 1064
    kSWComm,			// 1068
    kSlideConsReg,		// 106A
    kADD,			// 1070
    kBADD,			// 1072
    kThresholds,		// 1080
    kNumRegisters
};


// Size of output buffer
#define kADCOutputBufferSize 0x0800

#define kModel785  0
#define kModel785N 1

// Class definition
@interface ORCaen785Model : ORCaenCardModel <ORDataTaker,ORHWWizard,ORHWRamping>
{
    int modelType;
	unsigned long   onlineMask;
	//cached values for speed.
	unsigned long statusAddress;
	unsigned long dataBufferAddress;
	unsigned long location;
	unsigned long dataIdN;
}

#pragma mark ***Accessors
- (int) modelType;
- (void) setModelType:(int)aModelType;
- (unsigned long)onlineMask;
- (void)			setOnlineMask:(unsigned long)anOnlineMask;
- (BOOL)			onlineMaskBit:(int)bit;
- (void)			setOnlineMaskBit:(int)bit withValue:(BOOL)aValue;
- (unsigned long) dataIdN;
- (void) setDataIdN: (unsigned long) DataId;

#pragma mark ***Register - General routines
- (short)		getNumberRegisters;
- (unsigned long) 	getBufferOffset;
- (unsigned short) 	getDataBufferSize;
- (unsigned long) 	getThresholdOffset:(int)aChan;
- (short)		getStatusRegisterIndex: (short) aRegister;
- (short)		getThresholdIndex;
- (short)		getOutputBufferIndex;

#pragma mark ***Register - Register specific routines
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;
- (short)		getAccessType: (short) anIndex;
- (short)		getAccessSize: (short) anIndex;
- (BOOL)		dataReset: (short) anIndex;
- (BOOL)		swReset: (short) anIndex;
- (BOOL)		hwReset: (short) anIndex;
- (void)		reset;


#pragma mark ***Hardware Access

@end

extern NSString* ORCaen785ModelModelTypeChanged;
extern NSString* ORCaen785ModelOnlineMaskChanged;


