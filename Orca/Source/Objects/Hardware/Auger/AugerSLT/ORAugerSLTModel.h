//
//  ORAugerSLTModel.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORAugerFireWireCard.h"
#import "ORDataTaker.h"

@class ORFireWireInterface;

#define SLT_TRIGGER_SW    0x01  // Software
#define SLT_TRIGGER_I_N   0x07  // Internal + Neighbors
#define SLT_TRIGGER_LEFT  0x04  // left neighbor
#define SLT_TRIGGER_RIGHT 0x02  // right neighbor
#define SLT_TRIGGER_INT   0x08  // Internal only
#define SLT_TRIGGER_EXT   0x10  // External

#define SLT_INHIBIT_SW    0x01  // Software
#define SLT_INHIBIT_INT   0x02  // Internal
#define SLT_INHIBIT_EXT   0x04  // External
#define SLT_INHIBIT_ALL   0x07  // Internal + External
#define SLT_INHIBIT_NO    0x01  // None of both (only Software)

// not required any more !
#define SLT_NXPG_INT      0x00   // Internal
#define SLT_NXPG_EXT      0x01   // External
#define SLT_NXPG_SW       0x01   // Software

#define SLT_TESTPULS_NO   0x00   // None
#define SLT_TESTPULS_EXT  0x02   // External
#define SLT_TESTPULS_SW   0x01   // Software

#define SLT_SECSTROBE_INT 0x00   // Internal SecStrobe Signal
#define SLT_SECSTROBE_EXT 0x01   // Extern
#define SLT_SECSTROBE_SW  0x00   // Software - not available -
#define SLT_SECSTROBE_CAR 0x00   // Carry of Subsecond Counter
                                 //   - not available -

// called also watchdog in the slt hardware documentation
#define SLT_WATCHDOGSTART_INT   0x02   // Start with internal second strobe
#define SLT_WATCHDOGSTART_EXT   0x00   // External  - not available -
#define SLT_WATCHDOGSTART_SW    0x01   // Software

// Declaration of reg constants for module.
enum {
    kOutputBuffer,			// 0000
    kFirmWareRevision,		// 1000
    kGeoAddress,			// 1002
    kMCST_CBLTAddress,		// 1004
};

@interface ORAugerSLTModel : ORAugerFireWireCard 
{
	@private
		//control reg 
		BOOL veto;
		BOOL extInhibit;
		BOOL nopgInhibit;
		BOOL swInhibit;
		BOOL inhibit;
		BOOL resetTriggerFPGA;
		BOOL resetFLT;
		BOOL standbyFLT;
		BOOL suspendPLL;
		BOOL suspendClock;

		//status reg
		BOOL ledInhibit;
		BOOL ledVeto;
		int triggerSource;
		int inhibitSource;
		int testPulseSource;
		int secStrobeSource;
		int watchDogStart;
		int enableDeadTimeCounter;

		//pulser generation
		float pulserAmp;
		float pulserDelay;

		// Register information
		unsigned short  selectedRegIndex;
		unsigned long   writeValue;

		//multiplicity trigger
		unsigned short nHit;
		unsigned short nHitThreshold;
		float fpgaVersion;
}

#pragma mark ¥¥¥Initialization
- (id)   init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) findInterface;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) serviceChanged:(NSNotification*)aNote;
- (void) checkAndLoadFPGAs;
- (void) runIsAboutToStart:(NSNotification*)aNote;
- (void) runIsStopped:(NSNotification*)aNote;

#pragma mark ¥¥¥Accessors
- (float) fpgaVersion;
- (void) setFpgaVersion:(float)aFpgaVersion;
- (unsigned short) nHitThreshold;
- (void) setNHitThreshold:(unsigned short)aNHitThreshold;
- (unsigned short) nHit;
- (void) setNHit:(unsigned short)aNHit;
- (float) pulserDelay;
- (void) setPulserDelay:(float)aPulserDelay;
- (float) pulserAmp;
- (void) setPulserAmp:(float)aPulserAmp;
- (short) getNumberRegisters;			
- (NSString*) getRegisterName: (short) anIndex;
- (unsigned long) getAddressOffset: (short) anIndex;
- (short) getAccessType: (short) anIndex;

- (unsigned short) 	selectedRegIndex;
- (void)		setSelectedRegIndex: (unsigned short) anIndex;
- (unsigned long) 	writeValue;
- (void)		setWriteValue: (unsigned long) anIndex;

//status reg assess
- (BOOL) suspendClock;
- (void) setSuspendClock:(BOOL)aSuspendClock;
- (BOOL) suspendPLL;
- (void) setSuspendPLL:(BOOL)aSuspendPLL;
- (BOOL) standbyFLT;
- (void) setStandbyFLT:(BOOL)aStandbyFLT;
- (BOOL) resetFLT;
- (void) setResetFLT:(BOOL)aResetFLT;
- (BOOL) resetTriggerFPGA;
- (void) setResetTriggerFPGA:(BOOL)aResetTriggerFPGA;
- (BOOL) inhibit;
- (void) setInhibit:(BOOL)aInhibit;
- (BOOL) swInhibit;
- (void) setSwInhibit:(BOOL)aSwInhibit;
- (BOOL) nopgInhibit;
- (void) setNopgInhibit:(BOOL)aNopgInhibit;
- (BOOL) extInhibit;
- (void) setExtInhibit:(BOOL)aExtInhibit;
- (BOOL) veto;
- (void) setVeto:(BOOL)aVeto;

//control reg access
- (BOOL) ledInhibit;
- (void) setLedInhibit:(BOOL)aState;
- (BOOL) ledVeto;
- (void) setLedVeto:(BOOL)aState;
- (BOOL) enableDeadTimeCounter;
- (void) setEnableDeadTimeCounter:(BOOL)aState;
- (int) watchDogStart;
- (void) setWatchDogStart:(int)aWatchDogStart;
- (int) secStrobeSource;
- (void) setSecStrobeSource:(int)aSecStrobeSource;
- (int) testPulseSource;
- (void) setTestPulseSource:(int)aTestPulseSource;
- (int) inhibitSource;
- (void) setInhibitSource:(int)aInhibitSource;
- (int) triggerSource;
- (void) setTriggerSource:(int)aTriggerSource;
- (void) releaseSwInhibit;
- (void) setSwInhibit;

- (BOOL) usingNHitTriggerVersion;

#pragma mark ***HW Access
//note that most of these method can raise 
//exceptions either directly or indirectly
- (void)		  checkPresence;
- (unsigned long) readControlReg;
- (void)		  writeControlReg;
- (unsigned long) readStatusReg;
- (void)		  writeStatusReg;
- (void)		  writeReg:(unsigned short)index value:(unsigned long)aValue;
- (unsigned long) readReg:(unsigned short) index;
- (float)		  readVersion;
- (unsigned long long) readDeadTime;
- (unsigned long long) readVetoTime;
- (void)		reset;
- (void)		hw_reset;
- (void)		hw_config;
- (void)		hw_configure;
- (void)		loadPulseAmp;
- (void)		pulseOnce;
- (void)		loadPulserValues;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end


extern NSString* ORAugerSLTModelFpgaVersionChanged;
extern NSString* ORAugerSLTModelNHitThresholdChanged;
extern NSString* ORAugerSLTModelNHitChanged;
extern NSString* ORAugerSLTPulserDelayChanged;
extern NSString* ORAugerSLTPulserAmpChanged;
extern NSString* ORAugerSLTSelectedRegIndexChanged;
extern NSString* ORAugerSLTWriteValueChanged;
extern NSString* ORAugerSLTSettingsLock;
extern NSString* ORAugerSLTStatusRegChanged;
extern NSString* ORAugerSLTControlRegChanged;

