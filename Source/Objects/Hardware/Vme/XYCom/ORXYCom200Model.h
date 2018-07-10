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
#import "ORVmeIOCard.h"

@class ORPISlashTChip;

#pragma mark •••Register Definitions
enum {
	kMode0,
	kMode1,
	kMode2,
	kMode3
};

enum {
	kGeneralControl,
	kServiceRequest,
	kADataDirection,
	kBDataDirection,
	kCDataDirection,
	kInterruptVector,
	kAControl,
	kBControl,
	kAData,
	kBData,
	kCData,
	kAAlternate,
	kBAlternate,
	kStatus,
	kTimerControl,
	kTimerInterruptVector,
	kTimerStatus,
	kCounterPreloadHigh,
	kCounterPreloadMid,
	kCounterPreloadLow,
	kCountHigh,
	kCountMid,
	kCountLow,
	kNumRegs
};

@interface ORXYCom200Model : ORVmeIOCard
{
  @private
	int selectedPLT;
	unsigned short  selectedRegIndex;
    unsigned long   writeValue;
	NSArray*		chips;
}
#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (int) selectedPLT;
- (void) setSelectedPLT:(int)aSelectedPLT;

#pragma mark ••• accessors
- (NSArray*) chips;
- (void) setChips:(NSArray*)anArrayOfChips;
- (ORPISlashTChip*) chip:(int)anIndex;
- (unsigned short) 	selectedRegIndex;
- (void)			setSelectedRegIndex: (unsigned short) anIndex;
- (unsigned long) 	writeValue;
- (void)			setWriteValue: (unsigned long) anIndex;

#pragma mark •••Hardware Access
- (void) read;
- (void) write;
- (void) read:(unsigned short) pReg returnValue:(void*) pValue chip:(int)chipIndex;
- (void) write: (unsigned short) pReg sendValue: (unsigned char) pValue chip:(int)chipIndex;

- (void) initBoard;
- (void) report;

- (void) writeGeneralCR:(int)anIndex;

- (void) writePortADirection:(int)anIndex;
- (void) writePortACR:(int)anIndex;
- (void) writePortAData:(int)anIndex;

- (void) writePortBCR:(int)anIndex;
- (void) writePortBData:(int)anIndex;
- (void) writePortBDirection:(int)anIndex;

- (void) writePortCDirection:(int)anIndex;
- (void) writePortCData:(int)anIndex;

- (void) writeTimerData:(int)anIndex;
- (void) initOutA:(int) i;
- (void) initOutB:(int) i;
- (void) initSqWave:(int)index;

#pragma mark ***Register - Register specific routines
- (short)			getNumberRegisters;
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
@end

#pragma mark •••External String Definitions
extern NSString* ORXYCom200SelectedPLTChanged;
extern NSString* ORXYCom200SelectedRegIndexChanged;
extern NSString* ORXYCom200Lock;
extern NSString* ORXYCom200WriteValueChanged;

#pragma mark ------------------------------
#pragma mark •••PI/T Chip
@interface ORPISlashTChip : NSObject {
	@private
		int				chipIndex;
		//Gen Reg
		int				mode;
		BOOL			H34Enable;
		BOOL			H12Enable;
		BOOL			H4Sense;
		BOOL			H3Sense;
		BOOL			H2Sense;
		BOOL			H1Sense;
		
		//Port A
		int				portASubMode;
		int				portAH2Control;
		int				portAH2Interrupt;
		int				portAH1Control;
		int				portADirection;
		int				portATransceiverDir;
		unsigned char	portAData;
		
		//Port B
		int				portBSubMode;
		int				portBH2Control;
		int				portBH2Interrupt;
		int				portBH1Control;
		int				portBDirection;
		int				portBTransceiverDir;
		unsigned char	portBData;
		
		//PortC
		int				portCDirection;
		unsigned char	portCData;
		
		//Timer
		int timerControl;
		int preloadHigh;
		int preloadMiddle;
		int preloadLow;
		int period;

}

- (id) initChip:(int)aChipIndex;
- (NSString*) subModeName:(int)subModeIndex;

#pragma mark •••Gen Reg
- (int) mode;
- (void) setMode:(int)aMode;
- (BOOL) H1Sense;
- (void) setH1Sense:(BOOL)aH1Sense;
- (BOOL) H2Sense;
- (void) setH2Sense:(BOOL)aH2Sense;
- (BOOL) H3Sense;
- (void) setH3Sense:(BOOL)aH3Sense;
- (BOOL) H4Sense;
- (void) setH4Sense:(BOOL)aH4Sense;
- (BOOL) H12Enable;
- (void) setH12Enable:(BOOL)aH12Enable;
- (BOOL) H34Enable;
- (void) setH34Enable:(BOOL)aH34Enable;

#pragma mark •••Port A
- (int) portASubMode;
- (void) setPortASubMode:(int)aSubMode;
- (int) portAH1Control;
- (void) setPortAH1Control:(int)aH1Control;
- (int) portAH2Interrupt;
- (void) setPortAH2Interrupt:(int)aH2Interrupt;
- (int) portAH2Control;
- (void) setPortAH2Control:(int)aH2Control;
- (int) portADirection;
- (void) setPortADirection:(int)aPortADirection;
- (int) portATransceiverDir;
- (void) setPortATransceiverDir:(int)aPortADirection;
- (unsigned char) portAData;
- (void) setPortAData:(unsigned char)aPortAData;

#pragma mark •••Port B
- (int) portBSubMode;
- (void) setPortBSubMode:(int)aSubMode;
- (int) portBH1Control;
- (void) setPortBH1Control:(int)aH1Control;
- (int) portBH2Interrupt;
- (void) setPortBH2Interrupt:(int)aH2Interrupt;
- (int) portBH2Control;
- (void) setPortBH2Control:(int)aH2Control;
- (int) portBDirection;
- (void) setPortBDirection:(int)aPortBDirection;
- (int) portBTransceiverDir;
- (void) setPortBTransceiverDir:(int)aPortBDirection;
- (unsigned char) portBData;
- (void) setPortBData:(unsigned char)aPortBData;

#pragma mark •••Port C
- (int) portCDirection;
- (void) setPortCDirection:(int)aPortCDirection;
- (unsigned char) portCData;
- (void) setPortCData:(unsigned char)aPortCData;

#pragma mark •••Timer
- (int) period;
- (void) setPeriod:(int)aPeriod;
- (int) preloadLow;
- (void) setPreloadLow:(int)aPreloadLow;
- (int) preloadMiddle;
- (void) setPreloadMiddle:(int)aPreloadMiddle;
- (int) preloadHigh;
- (void) setPreloadHigh:(int)aPreloadHigh;
- (int) timerControl;
- (void) setTimerControl:(int)aTimerControl;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
@end

#pragma mark •••External String Definitions
//Gen Reg
extern NSString* ORPISlashTChipModeChanged;
extern NSString* ORPISlashTChipH1SenseChanged;
extern NSString* ORPISlashTChipH2SenseChanged;
extern NSString* ORPISlashTChipH3SenseChanged;
extern NSString* ORPISlashTChipH4SenseChanged;
extern NSString* ORPISlashTChipH12EnableChanged;
extern NSString* ORPISlashTChipH34EnableChanged;

//Port A
extern NSString* ORPISlashTChipPortASubModeChanged;
extern NSString* ORPISlashTChipPortAH1ControlChanged;
extern NSString* ORPISlashTChipPortAH2InterruptChanged;
extern NSString* ORPISlashTChipPortAH2ControlChanged;
extern NSString* ORPISlashTChipPortADirectionChanged;
extern NSString* ORPISlashTChipPortATransceiverDirChanged;
extern NSString* ORPISlashTChipPortADataChanged;

//Port B
extern NSString* ORPISlashTChipPortBSubModeChanged;
extern NSString* ORPISlashTChipPortBH1ControlChanged;
extern NSString* ORPISlashTChipPortBH2InterruptChanged;
extern NSString* ORPISlashTChipPortBH2ControlChanged;
extern NSString* ORPISlashTChipPortBDirectionChanged;
extern NSString* ORPISlashTChipPortBTransceiverDirChanged;
extern NSString* ORPISlashTChipPortBDataChanged;

//Port C
extern NSString* ORPISlashTChipPortCDirectionChanged;
extern NSString* ORPISlashTChipPortCDataChanged;

//Timer
extern NSString* ORPISlashTChipPreloadLowChanged;
extern NSString* ORPISlashTChipPreloadMiddleChanged;
extern NSString* ORPISlashTChipPreloadHighChanged;
extern NSString* ORPISlashTChipTimerControlChanged;
extern NSString* ORPISlashTChipPeriodChanged;

