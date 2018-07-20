//--------------------------------------------------------------------------------
/*!\class	OROscBaseModel
 * \brief	This class handles actual communication between the 
 * \methods
 *			\li \b 	chnlAcquire					- Determine if chnl is acquiring.
 *			\li \b 	setChnlAcquire				- Set whether chnl acquires.
 * \private
 *			\li \b	checkChnlNum				- Check if valid channel.
 * \note	
 *			
 * \author	Jan M. Wouters
 * \history	2003-02-16 (jmw) - Original.
 * \history 2003-12-01 (jmw) - Added instance variables and methods for scope type
 *								and version.  Changed all doubles to floats.
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
#pragma mark ***Imported Files

#import "ORDataPacket.h"
#import "ORDataTaker.h"
#import "ORGpibDeviceModel.h"

@class ORDataPacket;

#pragma mark ***Definitions
#define kMaxOscChnls 			4
#define kMaxGPIBReturn		16384

// Oscilloscope operation mode
#define kNormalTrigger			0			
#define kSingleWaveform			1

// Coupling indecies - These values must be in the order of the NSStrings listed below
#define kChnlCouplingACIndex	 	0
#define kChnlCouplingDCIndex 		1
#define kChnlCouplingGNDIndex 		2
#define kChnlCouplingDC50Index 		3

// Channel coupling constants
#define kCouplingChnlAC		@"AC"
#define kCouplingChnlDC		@"DC"
#define kCouplingChnlGND	@"GND"
#define kCouplingChnlDC50	@"DC 50"

// Trigger coupling constants
#define kTriggerAC  		0
#define kTriggerDC			1
#define kTriggerHFRej		2
#define kTriggerLFRej		3
#define kTriggerNOISERej	4

// Trigger Mode
#define kTriggerAuto		0
#define kTriggerNormal		1
#define kTriggerSingle 		2
#define kTriggerStop		3

// Trigger source constants
#define kTriggerAuxilary	0
#define kTriggerLine		1
#define kTriggerCH1 		2
#define kTriggerCH2 		3
#define kTriggerCH3 		4
#define kTriggerCH4			5

// Format constants
#define	kNoLabel			0
#define	kShortLabel			1
#define kLongLabel			2

// Errors
#define OExceptionOscError	@"OscError"

//#pragma mark ***Protocol
//@interface OscBase ( OscBasicCommands )
//- (void) oscSetChnlOn: (short) aChnl state: (short) aState;
//@end

typedef struct Channels {
        float	chnlPos;
        float	chnlScale;
        short	chnlCoupling;
        BOOL	chnlAcquire;
} Channels; 

@interface OROscBaseModel : ORGpibDeviceModel <ORDataTaker>
{
// Current Osc settings
    uint32_t		mScopeType;
    uint32_t		mScopeVersion;
    float			mHorizPos;
    float			mHorizScale;
    float			mTriggerLevel;
    short			mTriggerCoupling;
    short			mTriggerMode;
    float			mTriggerPos;
    short			mTriggerSource;
//    int32_t			mActualWaveformLength;
    int32_t			mWaveformLength;
    bool			mTriggerSlopeIsPos;
    struct	Channels	mChannels[ kMaxOscChnls ];
    
// Support variables
    uint32_t		firstEvent;
    char			mReturnData[ kMaxGPIBReturn + 1 ];
    bool			mRunInProgress;
    bool			mModelReflectsHardware;
        
    BOOL			mDataThreadRunning;
    BOOL			mDoFullInit;
    uint32_t   dataId;
    uint32_t   gtidDataId;
    uint32_t   clockDataId;
    uint32_t   eventCount[kMaxOscChnls];
    
    //locks used to do thread communication
    NSConditionLock*		_cancelled;
	NSConditionLock*		_okToGo;
    NSMutableDictionary*	threadParams;
}

#pragma mark ***Initialization
- (uint32_t) scopeType;
- (uint32_t) scopeVersion;

#pragma mark ***Accessors
- (int)     numberChannels;
- (bool) 	chnlAcquire: (short) aChnl;
- (void) 	setChnlAcquire: (short) aChnl setting: (bool) aState;
- (short)	chnlCoupling: (short) aChnl;
- (void)	setChnlCoupling: (short) aChnl coupling: (short) aValue;
- (float)	chnlPos: (short) aChnl;
- (void)	setChnlPos: (short) aChnl position: (float) aValue;
- (float)	chnlScale: (short) aChnl;
- (void)	setChnlScale: (short) aChnl scale: (float) aValue;

- (float)	horizontalPos;
- (void)	setHorizontalPos: (float) aHorizontalPos;
- (float)	horizontalScale;
- (void)	setHorizontalScale: (float) aHorizontalScale;
- (int32_t)	waveformLength;
- (void)	setWaveformLength: (int32_t) aWaveformLength;

- (short)	triggerCoupling;
- (void)	setTriggerCoupling: (short) aTriggerCoupling;
- (float)	triggerLevel;
- (void)	setTriggerLevel: (float) aTriggerLevel;
- (short)	triggerMode;
- (void)	setTriggerMode: (short) aTriggerMode;
- (float)	triggerPos;
- (void)	setTriggerPos: (float) aTriggerPos;
- (bool)	triggerSlopeIsPos;
- (void)	setTriggerSlopeIsPos: (bool) aTriggerSlope;
- (short)	triggerSource;
- (void)	setTriggerSource: (short) aTriggerSource;
- (bool)	modelReflectsHardware;
- (void) 	setModelReflectsHardware: (bool) aState;
- (BOOL)	doFullInit;
- (void)	setDoFullInit:(BOOL)aState;
- (uint32_t)   dataId;
- (void)            setDataId: (uint32_t) DataId;
- (uint32_t)   gtidDataId;
- (void)            setGtidDataId: (uint32_t) GtidDataId;
- (uint32_t)   clockDataId;
- (void)            setClockDataId: (uint32_t) ClockDataId;
- (void)    setDataIds:(id)assigner;
- (void)    syncDataIdsWith:(id)anotherShaper;
- (void) incEventCount:(int)aChannel;
- (uint32_t) eventCount:(int)aChannel;
- (void)	takeDataTask:(NSDictionary*)userInfo;

#pragma mark ***Commands
- (void) 	setOscFromModel;
- (void) 	setModelFromOsc;

#pragma mark ***Oscilloscope Methods
- (void)	oscGetStandardSettings;
- (void)	oscSetStandardSettings;
- (void) 	oscInitializeForDataTaking: (NSString*) aStartMsg;

#pragma mark ***Abstract Methods - General
- (short)   oscScopeId;
- (bool) 	oscBusy;
- (int32_t)	oscGetDateTime;
- (void)	oscSetDateTime: (int32_t) aTime;
- (void)	oscLockPanel: (bool) aFlag;
- (void)	oscResetOscilloscope;
- (void)	oscSendTextMessage: (NSString*) aMessage;
- (void)	oscSetQueryFormat: (short) aFormat;
- (void)	oscSetScreenDisplay: (bool) aDisplayOn;

#pragma mark ***Abstract Methods - Channel
- (void) 	oscGetChnlAcquire: (short) aChnl;
- (void) 	oscSetChnlAcquire;
- (void)	oscGetChnlCoupling: (short) aChnl;
- (void)	oscSetChnlCoupling: (short) aChnl;
- (void)	oscGetChnlPos: (short) aChnl;
- (void)	oscSetChnlPos: (short) aChnl;
- (void)	oscGetChnlScale: (short) aChnl;
- (void)	oscSetChnlScale: (short) aChnl;

#pragma mark ***Abstract Methods - Horizontal settings
- (void)	oscGetHorizontalPos;
- (void)	oscSetHorizontalPos;
- (void)	oscGetHorizontalScale;
- (void)	oscSetHorizontalScale;
- (void)	oscGetWaveformRecordLength;
- (void)	oscSetWaveformRecordLength;

#pragma mark ***Abstract Methods - Trigger
- (void)	oscGetTriggerCoupling;
- (void)	oscSetTriggerCoupling;
- (void)	oscGetTriggerLevel;
- (void)	oscSetTriggerLevel;
- (void)	oscGetTriggerMode;
- (void)	oscSetTriggerMode;
- (void)	oscGetTriggerPos;
- (void)	oscSetTriggerPos;
- (void)	oscGetTriggerSlopeIsPos;
- (void)	oscSetTriggerSlopeIsPos;
- (void)	oscGetTriggerSource;
- (void)	oscSetTriggerSource;

#pragma mark ***Abstract Methods - Data Acquisition
- (void)	oscArmScope;
- (void)	oscRunOsc: (NSString*) aMsg;
- (void)	oscSetAcqMode: (short) aMode;
- (void)	oscSetDataReturnMode;
- (void)	oscStopAcquisition;

#pragma mark ¥¥¥DataTaker
- (void) 	runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;

- (void) 	takeData: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) 	runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (void)	markAsCancelled;
- (BOOL)	cancelled;



#pragma mark ***Get and set oscilloscope specific settings.
- (void)	oscGetOscSpecificSettings;
- (void)	oscSetOscSpecificSettings;

#pragma mark ***Support
- (bool) checkChnlNum: (short) aChnl;

@end

#pragma mark ***Notification string definitions.
extern NSString*	OROscChnlAcqChangedNotification;
extern NSString*	OROscChnlCouplingChangedNotification;
extern NSString*	OROscChnlPosChangedNotification;
extern NSString*	OROscChnlScaleChangedNotification;

extern NSString*	OROscHorizPosChangedNotification;
extern NSString*	OROscPulseLengthChangedNotification;
extern NSString*	OROscHorizScaleChangedNotification;

extern NSString*	OROscTriggerCouplingChangedNotification;
extern NSString*	OROscTriggerLevelChangedNotification;
extern NSString*	OROscTriggerModeChangedNotification;
extern NSString*	OROscTriggerPosChangedNotification;
extern NSString*	OROscTriggerSlopeChangedNotification;
extern NSString*	OROscTriggerSourceChangedNotification;

extern NSString*	OROscModelReflectsHardwareChangedNotification;

#pragma mark ***Other string definitions.
extern NSString* OROscChnl;




