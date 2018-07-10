//--------------------------------------------------------------------------------
/*!\class	LC950Data
 * \brief	This class handles the data from the LeCroy 950 oscilloscope. 
 * \methods
 * \private
 * \note	1) The LeCroy data structure is always of the same format.  This format is:
 *          xxxx,#9yyyyyyyyy  where xxxx is some label and yyyyyyyyy is the length
 *          of the data in bytes.
 *			
 * \author	Jan M. Wouters
 * \history	1997-09-24 (jmw) - Original.
 * \history 2001-09-17 (jmw) - changed constructor to use SHDScopeHardwareData.
 * \history 2001-10-01 (jmw) - New method SHDConvertHeaders which converts data
 *											and stores header info in internal variables.
 * \history 2004-04-20 (jmw) - Modified for ORCA.
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

@class OROscBaseModel;

// Definitions.
//	const int	 HEADER_OFFSET = 16;		// Offset to header.

// enumerated types
/*	enum 	CommType { byte = 0, word };				// Data type
	enum 	CommOrder { hiFirst = 0, loFirst };		// Byte order
	enum	RecordType { singleSweep = 0, interleaved, histogram, trend, 
	                     filterCoeffecient, complexFreqDom, extremaEnvDisplay, Sequence };
	enum	ProcessingDone { noProcessing = 0, fir_filter, interpolated, 
	                         autoscaled, noResult, rolling, cumulative };
	enum	TimeBase { ps1 = 0, ps2, ps5, ps10, ps20, ps50, ps100, ps200, ps500,
	                       ns1, ns2, ns5, ns10, ns20, ns50, ns100, ns200, ns500,
	                       us1, us2, us5, us10, us20, us50, us100, us200, us500,
	                       ms1, ms2, ms5, ms10, ms20, ms50, ms100, ms200, ms500,
	                       s1, s2, s5, s10, s20, s50, s100, s200, s500,
	                       ks1, ks2, ks3, external };
	enum	VertCoupling { dc50Ohms = 0, ground1, dc1MOhm, ground2, ac1MOhm };
	enum	FixedVertGain { uV1 = 0, uV2, uV5, uV10, uV20, uV50, uV100, uV200, uV500,
							    mV1, mV2, mV5, mV10, mV20, mV50, mV100, mV200, mV500,
								V1, V2, V5, V10, V20, V50, V100, V200, V500,
								kV1 };
	enum	BandwidthLimit { off = 0, on };
	enum	WaveSource { channel1 = 0, channel2, channel3, channel4 };							
*/							
// IDEF header information for the L950
typedef struct L950IDefHeader
{
	char 	mDataLabel[ 4 ];					// Label for data
	char	mJunk[ 3 ];							// ",#9"
	char	mDataLength[  9 ];					// Data length
} L950IDefHeaderStruct;
	
// L950 Header definition
struct L950Header
{
//	L950IDefHeader mDataHeader;					// should be "DESC,#9000000346"
	char	mDescriptorName[ 16 ];				//"WAVEDESC"
	char	mTemplateName[ 16 ];				// Template name
	short	mCommType;							// Data Type  enum CommType
	short	mCommOrder;							// Byte order enum CommOrder
	long	mWaveDescriptor;					// length in bytes of this header
	long	mUserText;							// Length in bytes of userText
	long	mResDesc1;							// ?
	long	mTrigTimeArray;						// Length in bytes of TRIGTIME array
	long	mRisTimeArray;						// Length in bytes of RIS_TIME array.
	long	mResArray1;							// Not used
	long	mWaveArray1;						// Length in bytes of actual data
	long	mWaveArray2;						// Not used
	long	mResArray2;							// Not used
	long	mResArray3;							// Not used
	char	mInstrumentName[ 16 ];				// Name of instrument
	long	mInstrumentNumber;					// Number of instrument
	char	mTraceLabel[ 16 ];					// Identifies the waveform
	short	mReserved1;							// Not used
	short	mReserved2;							// Not used
	long	mWaveArrayCount;					// No points in the data array.
	long	mPntsPerScreen;						// nominal no. of data points on screen.
	long	mFirstValidPnt;						// count of no. pts to skip before first good point.
	long	mLastValidPnt;						// index of last good data point.
	long	mFirstPoint;						// For input indicates the offset relative to beginning of trace buffer.
	long	mSparsingFactor;					// Sparsing of transmitted data block.
	long	SegmentIndex;						// Index of transmitted index.
	long	mSubarrayCount;						// Acquired segment count.
	long	mSweepsPerAcq;						// Number of sweeps acquired when averaging.
	short	mPointsPerPair;						// Not used.
	short   mPairOffset;						// Not used.
	float	mVerticalGain;						// Vertical gain. val = verticalGain * data - verticalOffset
	float	mVerticalOffset;					// Vertical offset
	float	mMaxValue;							// Maximum allowed value.
	float	mMinvalue;							// minimum allowed value.
	short	mNominalBits;						// Resolution of ADC (8 bits)
	short	mNomSubArrayCount;					// Not used
	float	mHorizInterval;						// Not used
	double	mHorizOffset;						// Trigger offset.
	double	mPixelOffset;						// Not used
	char	mVerUnit[ 48 ];						// Units for vertical axis.
	char	mHorUnit[ 48 ];						// Units for horizontal axis.
	float	mHorUncertainty;					// Not used
	char	mTriggerTime[ 16 ];					// Time of trigger.
	float	mAcqDuration;						// Duration of acquisition in seconds
	short 	mRecordType;						// Type of record
	short	mProcessingDone;					// Type of processing done to acquire data.
	short	mReserved5;							// Not used
	short	mRisSweeps;							// Not used
	short	mTimeBase;							// Time base used
	short	mVertCoupling;						// Signal coupling to scope
	float	mProbeAtt;							// Probe attenuation factor
	short	mFixedVertGain;						// vertical gain setting
	short	mBandwidthLimit;					// Reduction of bandwidth
	float	mVerticalVernier;					// Vertical vernier setting
	float	mAcqVertOffset;						// Vertical offset setting
	short	msWaveSource;						// which channel	
};

#define kSize950Header 346

struct L950ShortHeader
{
    long			nrPts;   			// Number of points in waveform
    float			yOff;				// Vertical position of the waveform.
    float			yMult;				// Vertical scale factor in yUnit/data point value.
    float			xIncr;				// Time sampling interval.
    long			ptOff;				// Trigger point in waveform
    char			xUnit[ 20 ];		// Time units.
    char			yUnit[ 20 ];		// Vertical units.
};


// L9450 data class definition
@interface ORLC950Data : NSObject
{
	struct L950Header		mHeader;				// Pointers to the actual headers.
	struct L950ShortHeader  mHeaderShort;			// Header information.
	NSMutableData*			mGtid;					// Pointer to gtid data.
	NSMutableData*			mData;					// Pointer to actual waveform data.
	NSMutableData*			mTime;					// Pointer to time packet.
	long					mMaxSizeWaveform;		// Size of mData
	long					mActualSizeWaveform;	// Actual size of waveform stored in mData.
	unsigned long			mHeaderBaseGtidInfo[2];	// Record number for GTID record.
	unsigned long			mHeaderBaseInfo[2];		// The header non changing info attached to 
												//   each waveform.
	unsigned long			mHeaderBaseTimeInfo;	// The header non changing info attached to
												//	 each time record.
	short					mAddress;				// GPIB primary address.
	short					mChannel;				// The channel number.
}
		
#pragma mark ***Initialization
- (id)				initWithWaveformModel: (OROscBaseModel*) aModel channel: (short) aChannel;
- (void)			dealloc;

#pragma mark ***Accessors
- (long)			actualWaveformSize;
- (void)			setActualWaveformSize: (unsigned long) aWaveformSize;
- (long)			maxWaveformSize;
- (NSMutableData*)  rawData;
- (NSMutableData*)	timeData;
- (char*)			rawHeader;

#pragma mark ***Data Routines
- (void)			setGtid: (unsigned long) aGtid;
- (char*)			createDataStorage;
- (char*)			createTimeStorage;
- (void)			setDataPacketData: (ORDataPacket*) aDataPacket timeData: (NSData*) aTimeData
																includeGTID: (BOOL) aFlag;
- (NSData*)			timePacketData: (ORDataPacket*) aDataPacket channel: (unsigned short) aChannel;

#pragma mark ***Misc
- (void)			convertHeader;

@end
