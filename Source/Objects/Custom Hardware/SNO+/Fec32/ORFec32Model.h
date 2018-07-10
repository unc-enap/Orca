//
//  ORSNOCard.h
//  Orca
//
//  Created by Mark Howe on Wed Oct 15,2008.
//  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORSNOCard.h"
#import "OROrderedObjHolding.h"
#import "Sno_Monitor_Adcs.h"
#import "ORXL3Model.h"
#import "ORHWWizard.h"

@class ORFecDaughterCardModel;
@class ORCommandList;
@class ORPQDetectorDB;

#define kISetA1 0
#define kISetA0	1
#define kISetM1	2
#define kISetM0	3
#define kTACRef	4
#define kVMax	5

#define kCmosMin		0.0
#define kCmosMax		5.0
#define kCmosStep 		((kCmosMax-kCmosMin)/255.0)

#define kVResMin		0.0
#define kVResMax		5.0
#define kVResStep 		((kVResMax-kVResMin)/255.0)

#define kHVRefMin		0.0
#define kHVRefMax		5.0
#define kHVResStep 		((kHVRefMax-kHVRefMin)/255.0)


// SNTR CSR register, bit masks
#define FEC32_CSR_ZERO					0x00000000
#define FEC32_CSR_SOFT_RESET			0x00000001
#define FEC32_CSR_FIFO_RESET			0x00000002
#define FEC32_CSR_SEQ_RESET				0x00000004
#define FEC32_CSR_CMOS_RESET			0x00000008
#define FEC32_CSR_FULL_RESET			0x0000000F
#define FEC32_CSR_TESTMODE1				0x00000010
#define FEC32_CSR_TESTMODE2				0x00000020
#define FEC32_CSR_TESTMODE3				0x00000040
#define FEC32_CSR_TESTMODE4				0x00000080
#define FEC32_CSR_SPARE1				0x00000100
#define FEC32_CSR_SPARE2				0x00000200
#define FEC32_CSR_CAL_DAC_ENA			0x00000400
#define FEC32_CSR_CRATE_ADD				0x0000F800
#define FEC32_CSR_CGT24ERR1				0x00004000
#define FEC32_CSR_CGT24ERR2				0x00008000
#define FEC32_CSR_CGT24ERR3				0x00010000
#define FEC32_CSR_PULSERTESTPT			0x00020000
// BOARD ID register for all cards
#define BOARD_ID_REG_NUMBER		15  			// Register 15 on the Board ID chip stores the four letter board code

// Bit shift values
#define FEC32_CSR_CRATE_BITSIFT					11

// Fec32 Discrete and Sequencer register offsets 
#define FEC32_GENERAL_CS_REG					128
#define FEC32_ADC_VALUE_REG						132
#define FEC32_VOLTAGE_MONITOR_REG				136
#define FEC32_PEDESTAL_ENABLE_REG				140
#define FEC32_DAC_PROGRAM_REG					144
#define FEC32_CALIBRATION_DAC_PROGRAM_REG		148
#define FEC32_HVC_CS_REG						152
#define FEC32_CMOS_SPY_OUTPUT_REG				156
#define FEC32_CMOS_FULL_REG						160
#define FEC32_CMOS_SELECT_REG					164
#define FEC32_CMOS_1_16_REG						168
#define FEC32_CMOS_17_32_REG					172
#define FEC32_CMOS_LGISEL_SET_REG				176
#define FEC32_BOARD_ID_REG						180

#define FEC32_SEQ_OUTPUT_CS_REG					512
#define FEC32_SEQ_INTPUT_CS_REG					528
#define FEC32_CMOS_DATA_AVAIL_REG				544
#define FEC32_CMOS_CHIP_SELECT_REG				560
#define FEC32_CMOS_CHIP_DISABLE_REG				576
#define FEC32_CMOS_DATA_OUTPUT_REG				592
#define FEC32_FIFO_READ_POINTER_REG				624
#define FEC32_FIFO_WRITE_POINTER_REG			628
#define FEC32_FIFO_POINTER_DIFF_REG				632

#define FEC32_CMOS_MISSED_COUNT_OFFSET		   1028
#define FEC32_CMOS_BUSY_REG_OFFSET			   1032
#define FEC32_CMOS_TOTALS_COUNTER_OFFSET	   1036
#define FEC32_CMOS_TEST_ID_OFFSET			   1040
#define FEC32_CMOS_SHIFT_REG_OFFSET			   1044
#define FEC32_CMOS_ARRAY_POINTER_OFFSET		   1048
#define FEC32_CMOS_COUNT_INFO_OFFSET		   1052

// CMOS Shoft Register defintions
#define FEC32_CMOS_SHIFT_SERSTROB		0x00000001
#define FEC32_CMOS_SHIFT_CLOCK			0x00000002

#define NS20_MASK_BITS				0
#define NS_MASK_BITS				0
#define TACTRIM_BITS				3
#define NS20_DELAY_BITS				3
#define NS20_WIDTH_BITS				4
#define NS100_DELAY_BITS			5

// CMOS Shift Register Item
#define TAC_TRIM1	0
#define TAC_TRIM0	1
#define NS20_MASK	2
#define NS20_WIDTH	3
#define NS20_DELAY	4
#define NS100_MASK	5
#define NS100_DELAY	6

// Board ID Masks
#define	BOARD_ID_WDS		0x00000100 			// 100 00 xxxx
#define	BOARD_ID_WEN		0x00000130 			// 100 11 xxxx
#define BOARD_ID_WRITE		0x00000140 			// 101 00 0000
#define	BOARD_ID_READ  		0x00000180 			// 110 00 0000

#define	BOARD_ID_PREN  		0x00000130 			// 100 11 xxxx
#define	BOARD_ID_PRCLEAR 	0x000001FF			// 111 11 1111
#define	BOARD_ID_PRREAD  	0x00000180 			// 110 00 0000
#define	BOARD_ID_PRWRITE 	0x00000140 			// 101 00 0000

#define	BOARD_ID_SK 		0x00000001			
#define	BOARD_ID_DI 		0x00000080			
#define	BOARD_ID_PRE 		0x00000100			
#define	BOARD_ID_PE 		0x00000200			
#define	BOARD_ID_DO 		0x00000400	

// HV Supply Definitions ...TBD move to HV when available....

#define	HIGH_VOLTAGE_A					0
#define	HIGH_VOLTAGE_B					1

#define HV_CSR_CLK						0x1UL	  	//added for HV Current read routines
#define HV_CSR_DATIN            		0x2UL
#define HV_CSR_LOAD             		0x4UL
#define HV_CSR_DATOUT           		0x8UL

#define HV_A_SETPOINT_MASK				0x00000FFF
#define HV_B_SETPOINT_MASK				0x0FFF0000

#define HIGH_VOLTAGE_A_SWITCH			0x00000001
#define HIGH_VOLTAGE_B_SWITCH			0x00010000

#define HV_INTERLOCK_BIT_MASK			0x00000004

#define HV_RELAY_DATA_CLOSE				0x00000000
#define HV_RELAY_DATA_OPEN				0x00000002
#define HV_RELAY_DATA_LOAD				0x00000004
#define HV_RELAY_DATA_CLOCK				0x00000008

#define kCMOSRateUnmeasured		 -1
#define kCMOSRateBusyRead		 -2
#define kCMOSRateBusError		 -3
#define kCMOSRateCorruptRead	 -4
#define kMaxTimeDiff			100.0	// don't calculate rates over longer times than this

typedef struct Fec32CmosShiftReg{
	unsigned short	cmos_shift_item[7];
} aFec32CmosShiftReg;

@interface ORFec32Model :  ORSNOCard <OROrderedObjHolding, ORHWWizard>
{
	unsigned char	cmos[6];	//board related	0-ISETA1 1-ISETA0 2-ISETM1 3-ISETM0 4-TACREF 5-VMAX
	unsigned char	vRes;		//VRES for bipolar chip
	unsigned char	hVRef;		//HVREF for high voltage
    NSString*		comments;
    BOOL			showVolts;	
	unsigned long   onlineMask;
    unsigned long   pedEnabledMask;
    
	unsigned long   seqDisabledMask;
    unsigned long   trigger20nsDisabledMask;
    unsigned long   trigger100nsDisabledMask;
    unsigned long	cmosReadDisabledMask;

    unsigned long   lastSeqDisabledMask;
    unsigned long   lastTrigger100nsDisabledMask;
    unsigned long   lastTrigger20nsDisabledMask;
    unsigned long   lastCmosReadDisabledMask;

    unsigned long   seqPendingDisabledMask;
    unsigned long   trigger20nsPendingDisabledMask;
    unsigned long   trigger100nsPendingDisabledMask;
    unsigned long	cmosReadPendingDisabledMask;

    
	unsigned long   dirtyMask;
	unsigned long   thresholdToMax;
    float			baseCurrent[32];
	NSDate*			cmosCountTimeStamp;
	unsigned long	cmosCount[32];
    long			cmosRate[32];
	BOOL			qllEnabled;
	BOOL			dcPresent[4];
	ORFecDaughterCardModel* dc[4]; //cache the dc's
	aFec32CmosShiftReg	cmosShiftRegisterValue[16];
	int workingSlot;
	BOOL working;
	SEL resumeSelectorInGuardian;
	float			  adcVoltage[kNumFecMonitorAdcs]; 				//converted voltage
	eFecMonitorState  adcVoltageStatusOfCard;
	eFecMonitorState  adcVoltageStatus[kNumFecMonitorAdcs];
    int variableDisplay;

    // variables used during Hardware Wizard actions
    unsigned long   startSeqDisabledMask;
    unsigned long   startPedEnabledMask;
    unsigned long   startTrigger20nsDisabledMask;
    unsigned long   startTrigger100nsDisabledMask;
    unsigned long   startOnlineMask;
    BOOL            cardChangedFlag;
    NSObject*       hwWizard;
}

- (void) setUpImage;
- (void) makeMainController;

#pragma mark •••Accessors
- (uint32_t) boardIDAsInt;
- (int)             stationNumber;
- (long)			cmosRate:(short)index;
- (void)			setCmosRate:(short)index withValue:(long)aCmosRate;
- (id)				xl1;
- (id)				xl2;
- (BOOL)			dcPresent:(unsigned short)index;
- (ORFecDaughterCardModel*) dc:(unsigned short)index;
- (float)			baseCurrent:(short)index;
- (void)			setBaseCurrent:(short)idex withValue:(float)aBaseCurrent;
- (int)				variableDisplay;
- (void)			setVariableDisplay:(int)aVariableDisplay;
- (unsigned long)	pedEnabledMask;
- (void)			setPedEnabledMask:(unsigned long) aMask;
- (void)            setPed:(short)chan enabled:(short)state;
- (BOOL)            pedEnabled:(short)chan;
- (unsigned long)	onlineMask;
- (void)			setOnlineMask:(unsigned long) aMask;
- (void)			setOnlineMaskNoInit:(unsigned long) aMask;
- (BOOL)            getOnline:(short)chan;
- (void)            setOnline:(short)chan enabled:(short)state;

- (unsigned long)	seqDisabledMask;
- (void)			setSeqDisabledMask:(unsigned long) aMask;
- (void)			setSeq:(short)chan enabled:(short)state;
- (BOOL)			seqDisabled:(short)chan;
- (BOOL)			seqEnabled:(short)chan;
- (BOOL)            seqPendingEnabled:(short)chan;
- (BOOL)            seqPendingDisabled:(short)chan;
- (void)            togglePendingSeq:(short)chan;
- (void)            makeAllSeqPendingStatesSameAs:(short)chan;

- (unsigned long)	trigger20nsDisabledMask;
- (void)			setTrigger20nsDisabledMask:(unsigned long) aMask;
- (void)            setTrigger20ns:(short)chan enabled:(short)state;
- (void)			setTrigger20ns:(short) chan disabled:(short)state;
- (BOOL)			trigger20nsEnabled:(short)chan;
- (BOOL)			trigger20nsDisabled:(short)chan;
- (void)            togglePendingTrigger20ns:(short)chan;
- (BOOL)			trigger20nsPendingEnabled:(short)chan;
- (BOOL)			trigger20nsPendingDisabled:(short)chan;
- (void)            makeAll20nsPendingStatesSameAs:(short)chan;

- (unsigned long)	trigger100nsDisabledMask;
- (void)			setTrigger100nsDisabledMask:(unsigned long) aMask;
- (void)            setTrigger100ns:(short)chan enabled:(short)state;
- (void)			setTrigger100ns:(short) chan disabled:(short)state;
- (BOOL)			trigger100nsEnabled:(short)chan;
- (BOOL)			trigger100nsDisabled:(short)chan;
- (void)            togglePendingTrigger100ns:(short)chan;
- (BOOL)			trigger100nsPendingEnabled:(short)chan;
- (BOOL)			trigger100nsPendingDisabled:(short)chan;
- (void)            makeAll100nsPendingStatesSameAs:(short)chan;

- (unsigned long)	cmosReadDisabledMask;
- (void)			setCmosReadDisabledMask:(unsigned long) aMask;
- (void)            setCmosRead:(short)chan enabled:(short)state;
- (void)			setCmosRead:(short) chan disabled:(short)state;
- (BOOL)			cmosReadEnabled:(short)chan;
- (BOOL)			cmosReadDisabled:(short)chan;
- (void)            togglePendingCmosRead:(short)chan;
- (BOOL)			cmosReadPendingEnabled:(short)chan;
- (BOOL)			cmosReadPendingDisabled:(short)chan;
- (void)            makeAllCmosPendingStatesSameAs:(short)chan;
- (void)            loadHardware;
- (uint32_t) boardIDAsInt;
- (void) checkConfig: (FECConfiguration *) config;

- (void)            setTrigger20ns100ns:(short)chan enabled:(short)state;
- (BOOL)			trigger20ns100nsEnabled:(short)chan;

- (BOOL)			qllEnabled;
- (void)			setQllEnabled:(BOOL) aState;
- (short)           getVth:(short)chan;
- (void)            setVth:(short)chan withValue:(short)aValue;
- (void)            setVthToEcal:(short)chan;
- (void)            setVthToMax:(short)chan;
- (short)           getVThAboveZero:(short)chan;
- (void)            setVThAboveZero:(short)chan withValue:(unsigned char)aValue;

- (int)				globalCardNumber;
- (NSComparisonResult) globalCardNumberCompare:(id)aCard;
- (BOOL)			showVolts;
- (void)			setShowVolts:(BOOL)aShowVolts;
- (NSString*)		comments;
- (void)			setComments:(NSString*)aComments;
- (unsigned char)	cmos:(short)anIndex;
- (void)			setCmos:(short)anIndex withValue:(unsigned char)aValue;
- (float)			vRes;
- (void)			setVRes:(float)aValue;
- (float)			hVRef;
- (void)			setHVRef:(float)aValue;
- (BOOL)			pmtOnline:(unsigned short)index;
- (float)			adcVoltage:(int)index;
- (void)			setAdcVoltage:(int)index withValue:(float)aValue;
- (eFecMonitorState)adcVoltageStatus:(int)index;
- (void)			setAdcVoltageStatus:(int)index withValue:(eFecMonitorState)aState;
- (eFecMonitorState)adcVoltageStatusOfCard;
- (void)			setAdcVoltageStatusOfCard:(eFecMonitorState)aState;


#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) detectorStateChanged:(NSNotification*)aNote;
- (void) hwWizardActionBegin:(NSNotification*)aNote;
- (void) hwWizardActionEnd:(NSNotification*)aNote;
- (void) hwWizardActionFinal:(NSNotification*)aNote;
- (void) hwWizardWaitingForDatabase;
- (void) _detDbCallback:(ORPQDetectorDB*)data;
- (void) _continueHWWizard:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _continueHWWizard;

#pragma mark Converted Data Methods
- (void)	setCmosVoltage:(short)anIndex withValue:(float) value;
- (float)	cmosVoltage:(short) n;
- (void)	setVResVoltage:(float) value;
- (float)	vResVoltage;
- (void)	setHVRefVoltage:(float) value;
- (float)	hVRefVoltage;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Hardware Access
- (unsigned long) fec32RegAddress:(unsigned long)aRegOffset;
- (NSString*) performBoardIDRead:(short) boardIndex;
- (void) writeToFec32Register:(unsigned long) aRegister value:(unsigned long) aBitPattern;
- (void) setFec32RegisterBits:(unsigned long) aRegister bitMask:(unsigned long) bits_to_set;
- (void) clearFec32RegisterBits:(unsigned long) aRegister bitMask:(unsigned long) bits_to_clear;
- (void) readVoltages;
- (void) parseVoltages:(VMonResults*)result;
- (unsigned long) readFromFec32Register:(unsigned long) Register;
- (void) readBoardIds;
- (void) boardIDOperation:(unsigned long)theDataValue boardSelectValue:(unsigned long) boardSelectVal beginIndex:(short) beginIndex;
- (void) autoInit;
- (void) initTheCard:(BOOL) flgAutoInit;
- (void) fullResetOfCard;
- (void) resetFifo;
- (void) resetSequencer;
- (void) loadCrateAddress;
- (void) loadAllDacs;
- (void) setPedestals;
- (void) performPMTSetup:(BOOL) aTriggersDisabled;
- (void) scan:(SEL)aResumeSelectorInGuardian; 
- (void) scanWorkingSlot;
- (BOOL) readCMOSCounts:(BOOL)calcRates channelMask:(unsigned long) aChannelMask;
- (BOOL) processCMOSCounts:(unsigned long*)rates calcRates:(BOOL)aCalcRates withChannelMask:(unsigned long) aChannelMask;
- (unsigned long) channelsWithCMOSRateHigherThan:(unsigned long)cmosRateLimit;
- (unsigned long) channelsWithErrorCMOSRate;

//Added by Christopher Jones
-(NSMutableDictionary*) pullFecForOrcaDB;

#pragma mark •••Hw Access Helpers
- (id) writeToFec32RegisterCmd:(unsigned long) aRegister value:(unsigned long) aBitPattern;
- (id) readFromFec32RegisterCmd:(unsigned long) aRegister;
- (void) executeCommandList:(ORCommandList*)aList;
- (id) delayCmd:(unsigned long) milliSeconds;

#pragma mark •••OROrderedObjHolding Protocal
- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) groupSeparation;
- (NSRange) legalSlotsForObj:(id)anObj;
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj;
- (int)slotAtPoint:(NSPoint)aPoint; 
- (NSPoint) pointForSlot:(int)aSlot; 
- (void) place:(id)aCard intoSlot:(int)aSlot;
- (NSString*) nameForSlot:(int)aSlot;
- (int) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;

@end


extern NSString* ORFec32ModelCmosReadDisabledMaskChanged;
extern NSString* ORFec32ModelCmosRateChanged;
extern NSString* ORFec32ModelBaseCurrentChanged;
extern NSString* ORFec32ModelVariableDisplayChanged;
extern NSString* ORFec32ModelEverythingChanged;
extern NSString* ORFecShowVoltsChanged;
extern NSString* ORFecCommentsChanged;
extern NSString* ORFecCmosChanged;
extern NSString* ORFecVResChanged;
extern NSString* ORFecHVRefChanged;
extern NSString* ORFecOnlineMaskChanged;
extern NSString* ORFecPedEnabledMaskChanged;
extern NSString* ORFecSeqDisabledMaskChanged;
extern NSString* ORFecTrigger20nsDisabledMaskChanged;
extern NSString* ORFecTrigger100nsDisabledMaskChanged;
extern NSString* ORFecCmosReadDisabledMaskChanged;
extern NSString* ORFecQllEnabledChanged;
extern NSString* ORFec32ModelAdcVoltageChanged;
extern NSString* ORFec32ModelAdcVoltageStatusChanged;
extern NSString* ORFec32ModelAdcVoltageStatusOfCardChanged;

extern NSString* ORFecLock;


@interface NSObject (ORFec32Model)
- (void) writeHardwareRegister:(unsigned long) anAddress value:(unsigned long) aValue;
- (unsigned long) readHardwareRegister:(unsigned long) regAddress;
@end
