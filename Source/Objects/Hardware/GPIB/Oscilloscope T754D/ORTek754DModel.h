//--------------------------------------------------------------------------------
/*!\class	ORTek754DModel
 * \brief	This class the hardware interaction with the Tektronix 754D oscilloscope.
 * \methods
 *			\li \b 	init						- Constructor - Default first time
 *											      object is created
 *			\li \b 	dealloc						- Unregister messages, cleanup.
 * \private
 * \note	1) The hardware access methods use the internally stored state
 *			   to actually set the hardware.  Thus one first has to use the
 *			   accessor methods prior to setting the oscilloscope hardware.
 *			
 * \author	Jan M. Wouters
 * \history	2003-02-14 (jmw) - Original.
 * \history 2003-06-27 (mh)  - Added thread capability.
 * \history 2003-12-02 (jmw) - Added scope type and version information to header.
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

#import "OROscBaseModel.h"
#import "ORTek754DData.h"
#import "OROscDecoder.h"

#define ORTEKc754D 1
#define ORTEKc754A 2
#define ORTEKc744A 3

// Interface description of ORTek754DModel oscilloscope.
@interface ORTek754DModel : OROscBaseModel {
    @private
	ORTek754DData*		mDataObj[ kMaxOscChnls ];       // Pointers channel data.
	int32_t			mFastframeCount;					// Number of wavelengths in fastframe.
	int32_t			mFastframeRef;						// The reference frame.
	bool			mFastframeState;					// 1 - Fastframe is on.
	bool			mFastframeTimestampState;			// 1 - Fastframe timestamp is on.
	int32_t			mFastframeRecLength;				// Fastframe record length - must be
														//   mFastframeCount * mFastframeRecLength   
														//    = mWaveformLength
	unsigned short  mChannelMask;						// Mask of channels being acquired.
}

#pragma mark ***Initialization
- (id) 		init;
- (void) 	dealloc;
- (void)	setUpImage;
- (void)	makeMainController;

#pragma mark ***Hardware - General
- (short)	oscScopeId;
- (bool) 	oscBusy;
- (int32_t)	oscGetDateTime;
- (void)	oscSetDateTime: (time_t) aTime;
- (void)	oscLockPanel: (bool) aFlag;
- (void)	oscResetOscilloscope;
- (void)	oscSendTextMessage: (NSString*) aMessage;
- (void)	oscSetQueryFormat: (short) aFormat;
- (void)	oscSetScreenDisplay: (bool) aDisplayOn;

#pragma mark ***Hardware - Channel
- (void)	oscGetChnlAcquire: (short) aChnl;
- (void)	oscSetChnlAcquire;
- (void)	oscGetChnlCoupling: (short) aChnl;
- (void)	oscSetChnlCoupling: (short) aChnl;
- (void)	oscGetChnlPos: (short) aChnl;
- (void)	oscSetChnlPos: (short) aChnl;
- (void)	oscGetChnlScale: (short) aChnl;
- (void)	oscSetChnlScale: (short) aChnl;

#pragma mark ***Hardware - Horizontal settings
- (void)	osc754GetHorizontalFastframeSetup;
- (void) 	osc754SetHorizontalFastframeSetup;
- (void)	osc754GetHorizontalFastframeState;
- (void)	osc754SetHorizontalFastframeState;
- (void)	oscGetHorizontalPos;
- (void)	oscSetHorizontalPos;
- (void)	oscGetHorizontalScale;
- (void)	oscSetHorizontalScale;
- (void)	oscGetWaveformRecordLength;
- (void)	oscSetWaveformRecordLength;

#pragma mark ***Hardware - Trigger
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

#pragma mark ***Get and set oscilloscope specific settings.
- (void)	oscGetOscSpecificSettings;
- (void)	oscSetOscSpecificSettings;

#pragma mark ***Hardware - Data Acquisition
- (BOOL)	runInProgress;
- (void)	oscArmScope;
- (void)	oscGetHeader;
- (void)	oscGetWaveform: (unsigned short) aMask;
- (void) 	oscGetWaveformTime: (unsigned short) aMask;
- (void)	oscRunOsc: (NSString*) aStartMsg;
- (void)	oscSetAcqMode: (short) aMode;
- (void)	oscSetDataReturnMode;
- (void) 	oscSet754WaveformAcq:(unsigned short)aMask;
- (void)	oscStopAcquisition;
                                                    
#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) 	runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (void)	takeDataTask:(NSDictionary*)userInfo;
- (void) 	runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark ***Specialty routines.
- (void) 	osc754ConvertTime: (uint64_t*) a10MHzTime timeToConvert: (char*) aCharTime;

/*- 
- 
- (BOOL)	OscResetOscilloscope;	
- (BOOL)	OscWait;
*/

@end

@interface ORTek754DDecoderForScopeData : OROscDecoder
{}
@end

@interface ORTek754DDecoderForScopeGTID : OROscDecoder
{} 
@end

@interface ORTek754DDecoderForScopeTime : OROscDecoder
{}
@end

extern NSString* ORTek754Lock;
extern NSString* ORTek754GpibLock;
