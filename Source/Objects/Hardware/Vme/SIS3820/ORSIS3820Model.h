//-------------------------------------------------------------------------
//  ORSIS3820Model.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "SBC_Config.h"

@class ORAlarm;

#define kNumSIS3820Channels			32 

@interface ORSIS3820Model : ORVmeIOCard <ORDataTaker,ORHWWizard>
{
  @private
	int				pollTime;
	BOOL			isRunning;
 	unsigned short	moduleID;
 	unsigned short	majorRevision;
 	unsigned short	minorRevision;
	uint32_t   dataId;
	uint32_t	counts[32];
	NSString*		channelName[32];
	uint32_t   timeMeasured;
	uint32_t   lastTimeMeasured;
    uint32_t	countEnableMask;
    uint32_t	overFlowMask;
	
    int lemoInMode;
    BOOL enable25MHzPulses;
    BOOL enableCounterTestMode;
    BOOL enableReferencePulser;
    BOOL clearOnRunStart;
    BOOL syncWithRun;
    BOOL isCounting;
    int lemoOutMode;
    BOOL invertLemoIn;
    BOOL invertLemoOut;
    BOOL shipAtRunEndOnly;
	BOOL endOfRun;
    int deadTimeRefChannel;
    BOOL showDeadTime;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark ***Accessors
- (BOOL) showDeadTime;
- (void) setShowDeadTime:(BOOL)aShowDeadTime;
- (int) deadTimeRefChannel;
- (void) setDeadTimeRefChannel:(int)aDeadTimeRefChannel;
- (NSString*) channelName:(int)i;
- (void) setChannel:(int)i name:(NSString*)aName;
- (BOOL) shipAtRunEndOnly;
- (void) setShipAtRunEndOnly:(BOOL)aShipAtRunEndOnly;
- (BOOL) invertLemoOut;
- (void) setInvertLemoOut:(BOOL)aInvertLemoOut;
- (BOOL) invertLemoIn;
- (void) setInvertLemoIn:(BOOL)aInvertLemoIn;
- (int) lemoOutMode;
- (void) setLemoOutMode:(int)aLemoOutMode;
- (BOOL) isCounting;
- (void) setIsCounting:(BOOL)aIsCounting;
- (BOOL) syncWithRun;
- (void) setSyncWithRun:(BOOL)aSyncWithRun;
- (BOOL) clearOnRunStart;
- (void) setClearOnRunStart:(BOOL)aClearOnRunStart;
- (float) convertedPollTime;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;

- (BOOL) enableReferencePulser;
- (void) setEnableReferencePulser:(BOOL)aEnableReferencePulser;
- (BOOL) enableCounterTestMode;
- (void) setEnableCounterTestMode:(BOOL)aState;
- (BOOL) enable25MHzPulses;
- (void) setEnable25MHzPulses:(BOOL)aEnable25MHzPulses;

- (int) lemoInMode;
- (void) setLemoInMode:(int)aLemoInMode;
- (uint32_t) counts:(int)i;
- (uint32_t) countEnableMask;
- (void) setCountEnableMask:(uint32_t)aCountEnableMask;
- (BOOL) countEnabled:(short)chan;
- (void) setCountEnabled:(short)chan withValue:(BOOL)aValue;	
- (uint32_t) overFlowMask;
- (void) setOverFlowMask:(uint32_t)aMask;
- (void) dumpCounts;


- (void) setDefaults;
- (unsigned short) moduleID;
- (unsigned short) majorRevision;

#pragma mark •••Hardware Access
- (void) initBoard;
- (void) clockShadow;
- (void) readModuleID:(BOOL)verbose;
- (void) arm;
- (void) readStatusRegister;
- (void) writeControlRegister;
- (void) writeAcquisitionRegister;
- (void) setLed:(BOOL)state;
- (void) startCounting;
- (void) stopCounting;
- (void) readCounts:(BOOL)clear;
- (void) clearAll;
- (void) clearCounter:(int)i;
- (void) enableReferencePulser:(BOOL)state;
- (void) clearAllOverFlowFlags;
- (void) readOverFlowRegister;
- (void) timeToPoll;
- (void) writeCountEnableMask;
- (void) generateTestPulse;

#pragma mark •••Data Taker
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark •••HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORSIS3820ModelShowDeadTimeChanged;
extern NSString* ORSIS3820ModelDeadTimeRefChannelChanged;
extern NSString* ORSIS3820ChannelNameChanged;
extern NSString* ORSIS3820ModelShipAtRunEndOnlyChanged;
extern NSString* ORSIS3820ModelInvertLemoOutChanged;
extern NSString* ORSIS3820ModelInvertLemoInChanged;
extern NSString* ORSIS3820ModelLemoOutModeChanged;
extern NSString* ORSIS3820ModelIsCountingChanged;
extern NSString* ORSIS3820ModelSyncWithRunChanged;
extern NSString* ORSIS3820ModelClearOnRunStartChanged;
extern NSString* ORSIS3820ModelEnableReferencePulserChanged;
extern NSString* ORSIS3820ModelEnableCounterTestModeChanged;
extern NSString* ORSIS3820ModelEnable25MHzPulsesChanged;
extern NSString* ORSIS3820ModelLemoInModeChanged;
extern NSString* ORSIS3820ModelCountEnableMaskChanged;
extern NSString* ORSIS3820SettingsLock;
extern NSString* ORSIS3820ModelIDChanged;
extern NSString* ORSIS3820CountersChanged;
extern NSString* ORSIS3820ModelOverFlowMaskChanged;
extern NSString* ORSIS3820PollTimeChanged;

