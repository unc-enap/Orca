//
//  ORDGF4cModel.h
//  Orca
//
//  Created by Mark Howe on Wed Dec 29 2004.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORCamacIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"


#pragma mark ¥¥¥Definitions
#define kDefaultParamFile		@"ORDGF4cDefaultParams"
#define kBaseFirmwareFileName	"dgf4c"
#define kDataStartAddress		0x4000
#define kEventBufferLength		2048
#define kLinearBufferSize		8192
#define kMaxHistogramLength		32768	/* Maximum MCA histogram length */
#define kBufferHeaderLength		6
#define kEventHeaderLength		3
#define kNumRepeatedTauRuns		10		/* Number of repeated tau runs */

enum {
	kListMode					= 0x100,
	kListModeCompression1		= 0x101,
	kListModeCompression2		= 0x102,
	kListModeCompression3		= 0x103,
	kFastListMode				= 0x200,
	kFastListModeCompression1	= 0x201,
	kFastListModeCompression2	= 0x202,
	kFastListModeCompression3	= 0x203,
	kMCAMode					= 0x301
};

static union {
	uint32_t asLong;
	double asDouble;
} packedDGF4LiveTime;


@interface ORDGF4cModel : ORCamacIOCard <ORDataTaker,ORHWWizard,ORHWRamping> {
    @private
		uint32_t dataId;
		uint32_t liveTimeId;
		uint32_t mcaDataId;
		NSString* firmWarePath;
		NSString* dspCodePath;
		NSString* lastParamPath;
		NSString* lastNewSetPath;
		NSMutableDictionary* params;
		NSMutableDictionary* lookUpTable;
		short revision;
		short channel;
		
		//read in at start of run
		unsigned short linearDataBufferStart;
		unsigned short linearDataBufferSize;
		short maxEvents;
		
		//place to cache some stuff for alittle more speed.
		uint32_t 	unChangingDataPart;
		unsigned short cachedStation;
		BOOL firstTime;
		unsigned short csrValueForResuming;

		//user params
		uint32_t runBehaviorMask; //synchwait, insynch, etc.
		short decimation;
		int32_t numOscPoints;
		unsigned short oscModeData[4][8192];
		int oscEnabledMask;
		float energyRiseTime[4];
		float energyFlatTop[4];
		float triggerRiseTime[4];
		float triggerFlatTop[4];
		float triggerThreshold[4];
		float vGain[4];
		float vOffset[4];
		unsigned short traceLength[4];
		float traceDelay[4];
		float psaStart[4];
		float psaEnd[4];
		unsigned short eMin[4];
		unsigned short binFactor[4];
		double tau[4];
		double tauSigma[4];
		unsigned short runTask;
        unsigned short xwait[4];

		BOOL sampleWaveforms;
		NSLock* oscLock;
		BOOL okToLoadWhileRunning;
		NSLock* paramLoadLock;	
}

#pragma mark ¥¥¥Initialization
- (id) init;
- (void) dealloc;

#pragma mark ¥¥¥Accessors
- (uint32_t) runBehaviorMask;
- (void) setRunBehaviorMask:(uint32_t)aRunBehaviorMask;
- (void) setSyncWait:(BOOL)state;
- (BOOL) syncWait;
- (void) setInSync:(BOOL)state;
- (BOOL) inSync;
- (unsigned short) xwait:(short)chan;
- (void) setXwait:(short)chan withValue:(unsigned short)aXwait;
- (BOOL) sampleWaveforms;
- (void) setSampleWaveforms:(BOOL)state;
- (unsigned short) runTask;
- (void) setRunTask:(unsigned short)aRunTask;
- (double) tau:(short)chan;
- (void) setTauSigma:(short)chan withValue:(double)aTau;
- (double) tauSigma:(short)chan;
- (void) setTau:(short)chan withValue:(double)aTau;
- (unsigned short) binFactor:(short)chan;
- (void) setBinFactor:(short)chan withValue:(unsigned short)aBinFactor;
- (unsigned short) eMin:(short)chan;
- (void) setEMin:(short)channel withValue:(unsigned short)aEMin;
- (float) psaEnd:(short)chan;
- (void) setPsaEnd:(short)chan withValue:(float)aPsaEnd;
- (float) psaStart:(short)chan;
- (void) setPsaStart:(short)chan withValue:(float)aPsaStart;
- (float) traceDelay:(short)chan;
- (void) setTraceDelay:(short)chan withValue:(float)aTraceDelay;
- (float) traceLength:(short)chan;
- (void) setTraceLength:(short)chan withValue:(unsigned short)aTraceLength;
- (float) vOffset:(short)chan;
- (void) setVOffset:(short)chan withValue:(float)aVOffset;
- (float) vGain:(short)chan;
- (void) setVGain:(short)chan withValue:(float)aVGain;
- (float) triggerThreshold:(short)chan;
- (void) setTriggerThreshold:(short)chan withValue:(float)aTriggerThreshold;
- (float) triggerFlatTop:(short)chan;
- (void) setTriggerFlatTop:(short)chan withValue:(float)aTriggerFlatTop;
- (float) triggerRiseTime:(short)chan;
- (void) setTriggerRiseTime:(short)chan withValue:(float)aTriggerRiseTime;
- (float) energyFlatTop:(short)chan;
- (void) setEnergyFlatTop:(short)chan withValue:(float)aEnergyFlatTop;
- (float) energyRiseTime:(short)chan;
- (void) setEnergyRiseTime:(short)chan withValue:(float)aEnergyRiseTime;
- (unsigned short) oscEnabledMask;
- (void) setOscEnabledMask:(unsigned short)aMask;
- (void) setOscChanEnabledBit:(short)aBit withValue:(BOOL)aValue;

- (short) decimation;
- (void) setDecimation:(short)aDecimation;
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (uint32_t) liveTimeId;
- (void) setLiveTimeId: (uint32_t) aDataId;
- (uint32_t) mcaDataId;
- (void) setMcaDataId: (uint32_t) DataId;
- (short) revision;
- (void) setRevision:(short)aValue;
- (NSString *) firmWarePath;
- (void) setFirmWarePath: (NSString *) aFirmWarePath;
- (NSString *) dspCodePath;
- (void) setDSPCodePath: (NSString *) aDSPCodePath;
- (NSString *) lastParamPath;
- (void) setLastParamPath: (NSString *) aLastParamPath;
- (NSMutableDictionary *) params;
- (void) setParams: (NSMutableDictionary *) aParams;
- (NSString *)lastNewSetPath;
- (void)setLastNewSetPath:(NSString *)aLastNewSetPath;

- (void) setParam:(NSString*)aParamName value:(unsigned short)aValue;
- (unsigned short)   paramValue:(NSString*)aParamName;
- (void) setParam:(NSString*)aParamName value:(unsigned short)aValue channel:(int)aChannel;
- (unsigned short) paramValue:(NSString*)aParamName channel:(int)aChannel;


- (id) param:(NSString*)arrayName index:(NSUInteger)index forKey:(NSString*)aKey;
- (void) set:(NSString*)arrayName index:(NSUInteger)index toObject:(id)anObject forKey:(NSString*)aKey;


- (NSUInteger) countForArray:(NSString*)anArrayName;
- (short)channel;
- (void)setChannel:(short)aChannel;

- (NSMutableDictionary *)lookUpTable;
- (void)setLookUpTable:(NSMutableDictionary *)aLookUpTable;

- (int32_t) numOscPoints;
- (int32_t) oscData:(short)set value:(short)x;

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (NSArray*) valueArrayFor:(SEL)sel;

#pragma mark ¥¥¥Hardware Access
- (void) fullInit;
- (void) loadSystemFPGA;
- (void) bootDSP;
- (void) loadParams;
- (void) loadParamsWithReadBack:(BOOL)readBack;
- (void) setParam:(NSString*)paramName to:(unsigned short)aValue;
- (short) readParam:(NSString*)paramName;
- (unsigned short) readCSR;
- (void) writeCSR:(unsigned short)aValue;
- (void) writeICSR:(unsigned short)aValue;
- (void) loadSystemFPGA:(NSString*)filePath;
- (BOOL) loadFilterTriggerFPGAs:(NSString*)filePath;
- (void) writeDSPProgramWord:(uint32_t)data;
- (uint32_t) readDSPProgramWord;
- (void) setCSRBit:(unsigned short)bitMask;
- (void) clearCSRBit:(unsigned short)bitMask;
- (void) waitForNotActive:(NSTimeInterval)seconds reason:(NSString*)aReason;
- (void) executeTask:(int)aTask;
- (void) readParams;
- (void) readMCA:(ORDataPacket*)aDataPacket channel:(short)aChannel;
- (void) sampleChannel:(short)aChannel;
- (void) runBaselineCuts;
- (void) runBaselineCut:(short)aChannel;
- (void) calcOffsets;
- (void) runTauFinder:(short)chan;
- (double) tauFinder:(double)Tau channel:(short)chan;

#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) reset;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (void) shipLiveTime;

#pragma mark ¥¥¥Parmlist management
- (void) createNewVarList:(NSString*)aFilePath;
- (void) saveSetToPath:(NSString*)aPath;
- (void) loadSetFromPath:(NSString*)aPath;
- (void) loadDefaults;

#pragma mark ¥¥¥HW Wizard
- (NSArray*) wizardSelections;
- (NSArray*) wizardParameters;
- (int) numberOfChannels;

@end

extern NSString* ORDGF4cModelRunBehaviorMaskChanged;
extern NSString* ORDGF4cModelXwaitChanged;
extern NSString* ORDGF4cModelRunTaskChanged;
extern NSString* ORDGF4cModelTauChanged;
extern NSString* ORDGF4cModelBinFactorChanged;
extern NSString* ORDGF4cModelEMinChanged;
extern NSString* ORDGF4cModelPsaEndChanged;
extern NSString* ORDGF4cModelPsaStartChanged;
extern NSString* ORDGF4cModelTraceDelayChanged;
extern NSString* ORDGF4cModelTraceLengthChanged;
extern NSString* ORDGF4cModelVOffsetChanged;
extern NSString* ORDGF4cModelVGainChanged;
extern NSString* ORDGF4cModelTriggerThresholdChanged;
extern NSString* ORDGF4cModelTriggerFlatTopChanged;
extern NSString* ORDGF4cModelTriggerRiseTimeChanged;
extern NSString* ORDGF4cModelEnergyFlatTopChanged;
extern NSString* ORDGF4cModelEnergyRiseTimeChanged;
extern NSString* ORDFG4cFirmWarePathChangedNotification;
extern NSString* ORDFG4cDSPCodePathChangedNotification;
extern NSString* ORDFG4cDSPSettingsLock;
extern NSString* ORDFG4cParamChangedNotification;
extern NSString* ORDFG4cChannelChangedNotification;
extern NSString* ORDFG4cRevisionChangedNotification;
extern NSString* ORDFG4cDecimationChangedNotification;
extern NSString* ORDFG4cOscEnabledMaskChangedNotification;
extern NSString* ORDFG4cSampleWaveformChangedNotification;
extern NSString* ORDFG4cWaveformChangedNotification;
extern NSString* ORDGF4cModelTauSigmaChanged;

extern NSString* kDGF4cParamNotFound;
