//--------------------------------------------------------------------------------
/*!\class	ORLC950DModel
 * \brief	This class the hardware interaction with the LeCroy 950 oscilloscope.
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
 * \history	2004-21-04 (jmw) - Original.
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
#import "ORLC950Data.h"
#import "OROscDecoder.h"

#define ORLC950 1
#define ORLCMaxRecSize 50000
#define ORLCMaxSampleRate 0.125e-9;

// Interface description of ORLC950Model oscilloscope.
@interface ORLC950Model : OROscBaseModel {
    @private
	ORLC950Data*		mDataObj[ kMaxOscChnls ];       // Pointers channel data.
}

#pragma mark ***Initialization
- (id) 		init;
- (void) 	dealloc;
- (void)	setUpImage;
- (void)	makeMainController;

#pragma mark ***Hardware - General
- (short)	oscScopeId;
- (bool) 	oscBusy;
- (long)	oscGetDateTime;
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
//- (void) 	oscSetWaveformAcq:(unsigned short)aMask;
- (void)	oscStopAcquisition;
                                                    
#pragma mark ¥¥¥DataTaker
- (NSDictionary*) dataRecordDescription;
- (void) 	runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (void)	takeDataTask:(NSDictionary*)userInfo;
- (void) 	runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark ***Specialty routines.
- (NSString*) 	triggerSourceAsString;
- (void)	osc950ConvertTime: (unsigned long long*) a10MhzTime timeToConvert: (char*) aCharTime;

/*- 
- 
- (BOOL)	OscResetOscilloscope;	
- (BOOL)	OscWait;
*/

@end

@interface ORLC950DecoderForScopeData : OROscDecoder
{}
@end

@interface ORLC950DecoderForScopeGTID : OROscDecoder
{} 
@end

@interface ORLC950DecoderForScopeTime : OROscDecoder
{}
@end

extern NSString* ORLC950Lock;
extern NSString* ORLC950GpibLock;
