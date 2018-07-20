//--------------------------------------------------------------------------------
//ORCV977Model.h
//Mark A. Howe 20013-09-26
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORCaenCardModel.h"

// Declaration of constants for module.
enum {
	kInputSet,           //0x0000
	kInputMask,          //0x0002
	kInputRead,          //0x0004
	kSingleHitRead,      //0x0006
	kMultihitRead,       //0x0008
	kOutputSet,          //0x000A
	kOutputMask,         //0x000C
	kInterruptMask,      //0x000E
	kClearOutput,        //0x0010
	kSinglehitReadClear, //0x0016
	kMultihitReadClear,  //0x0018
	kTestControl,        //0x001A
	kInterruptLevel,     //0x0020
	kInterruptVector,    //0x0022
	kSerialNumber,       //0x0024
	kFirmwareRevision,   //0x0026
	kControlRegister,    //0x0028
	kSoftwareReset,      //0x002E
    kNumRegisters        //must be last
};

typedef struct V977NamesStruct {
	NSString*       regName;
	uint32_t 	addressOffset;
	short           accessType;
} V977NamesStruct;

@interface ORCV977Model : ORVmeIOCard
{
    unsigned short  selectedRegIndex;
    unsigned short  selectedChannel;
    uint32_t   writeValue;
	uint32_t   inputSet;
	uint32_t   inputMask;
	uint32_t   outputSet;
	uint32_t   outputMask;
	uint32_t   interruptMask;
    BOOL            patternBit;
    BOOL            gateMaskBit;
    BOOL            orMaskBit;
}

- (void) registerNotificationObservers;
- (void) runAboutToStart:(NSNotification*)aNote;

#pragma mark ***Accessors
- (BOOL)            orMaskBit;
- (void)            setOrMaskBit:(BOOL)aOrMaskBit;
- (BOOL)            gateMaskBit;
- (void)            setGateMaskBit:(BOOL)aGateMaskBit;
- (BOOL)            patternBit;
- (void)            setPatternBit:(BOOL)aPatternBit;
- (uint32_t)   inputSet;
- (void)			setInputSet:(uint32_t)aValue;
- (BOOL)			inputSetBit:(int)bit;
- (void)			setInputSetBit:(int)bit withValue:(BOOL)aValue;

- (uint32_t)   inputMask;
- (void)			setInputMask:(uint32_t)aValue;
- (BOOL)			inputMaskBit:(int)bit;
- (void)			setInputMaskBit:(int)bit withValue:(BOOL)aValue;

- (uint32_t)   outputSet;
- (void)			setOutputSet:(uint32_t)aValue;
- (BOOL)			outputSetBit:(int)bit;
- (void)			setOutputSetBit:(int)bit withValue:(BOOL)aValue;

- (uint32_t)   outputMask;
- (void)			setOutputMask:(uint32_t)aValue;
- (BOOL)			outputMaskBit:(int)bit;
- (void)			setOutputMaskBit:(int)bit withValue:(BOOL)aValue;

- (uint32_t)   interruptMask;
- (void)			setInterruptMask:(uint32_t)aValue;
- (BOOL)			interruptMaskBit:(int)bit;
- (void)			setInterruptMaskBit:(int)bit withValue:(BOOL)aValue;


#pragma mark *** Hardware Access
- (void)    read;
- (void)    write;
- (void)    read: (unsigned short) pReg returnValue: (void*) pValue;
- (void)    write: (unsigned short) pReg sendValue: (uint32_t) pValue;
- (void)    clearOutputRegister;
- (void)    clearSingleHitRegister;
- (void)    clearMultiHitRegister;
- (void)    readVersion;
- (void)    writeControlReg;
- (void)    writeInputSetReg;
- (void)    writeInputMaskReg;
- (void)    writeOutputSetReg;
- (void)    writeOutputMaskReg;
- (void)    writeInterruptMaskReg;
- (void)    reset;
- (void)    initBoard;

#pragma mark ***Register - General routines
- (short)           getNumberRegisters;

#pragma mark ***Register - Register specific routines
- (NSString*) 		getRegisterName: (short) anIndex;
- (uint32_t) 	getAddressOffset: (short) anIndex;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


#pragma mark •••External String Definitions
extern NSString* ORCV977ModelOrMaskBitChanged;
extern NSString* ORCV977ModelGateMaskBitChanged;
extern NSString* ORCV977ModelPatternBitChanged;
extern NSString* ORCV977ModelSelectedRegIndexChanged;
extern NSString* ORCV977ModelWriteValueChanged;
extern NSString* ORCV977ModelInputSetChanged;
extern NSString* ORCV977ModelInputMaskChanged;
extern NSString* ORCV977ModelOutputSetChanged;
extern NSString* ORCV977ModelOutputMaskChanged;
extern NSString* ORCV977ModelInterruptMaskChanged;

extern NSString* ORCV977BasicOpsLock;
extern NSString* ORCV977LowLevelOpsLock;

