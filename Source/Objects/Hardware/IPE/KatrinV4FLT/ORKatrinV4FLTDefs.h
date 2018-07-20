/***************************************************************************
    ORKatrinV4FLTDefs.h  -  description

    begin                : Tue Jul 18 2000
    copyright            : (C) 2000 by Andreas Kopmann
    email                : kopmann@hpe.fzk.de
 ***************************************************************************/

//Adress model
#define kIpeFlt_AddressSpace 21		// Address Space Switch bits 22..21 (shortend!)
#define kIpeFlt_ChannelAddress 16   // Channel Address      bits 20..16
#define kIpeFlt_PageNumber 10		// Page Number          bits 14..10
#define kIpeFlt_RegId 0				// Register Id          bits 14.. 0

#define kNumV4FLTChannels 24

#define kIpeFlt_Page_Size 1000

#define kIpeFlt_Pages 64

// Position of the bit fields
#define kIpeFlt_Cntl_InterruptMask_Shift	8
#define kIpeFlt_Cntl_InterruptMask_Mask		0xff

#define kIpeFlt_Cntl_LedOff_Shift			17
#define kIpeFlt_Cntl_LedOff_Mask			0x1

#define kIpeFlt_Cntl_HitRateLength_Shift	18   
#define kIpeFlt_Cntl_HitRateLength_Mask		0x7 

#define kIpeFlt_Cntl_ErrFlag_Shift			21   
#define kIpeFlt_Cntl_ErrFlag_Mask			0x1 

#define kIpeFlt_Cntl_Mode_Shift				16
#define kIpeFlt_Cntl_Mode_Mask				0x1

#define kIpeFlt_Cntl_Version_Shift			23
#define kIpeFlt_Cntl_Version_Mask			0xf

#define kIpeFlt_Cntl_CardID_Shift			27
#define kIpeFlt_Cntl_CardID_Mask			0x1f


#define kIpeFlt_Cntl_InterruptSources_Shift	0
#define kIpeFlt_Cntl_InterruptSources_Mask	0xff


//Command register (kFLTV4CommandReg) pattern
#define kIpeFlt_Cmd_LoadGains	            0x100
#define kIpeFlt_SW_Trigger					0x80000000
//#define kIpeFlt_Reset_All			0x18010 I added the resetPage flag -tb-
//#define kIpeFlt_Reset_All			0x38010 flag 15 isn't defined -tb-
#define kIpeFlt_Reset_All			0x30010 //=rstPg, rPoint, rstTP

#define kIpeFlt_Periph_CoinTme_Shift		0
#define kIpeFlt_Periph_CoinTme_Mask			0x1ff

#define kIpeFlt_Periph_Mode_Shift			14
#define kIpeFlt_Periph_Mode_Mask			0x1

#define kIpeFlt_Periph_LedOff_Shift			15
#define kIpeFlt_Periph_LedOff_Mask			0x1

#define kIpeFlt_Periph_ThresDelta_Shift		16
#define kIpeFlt_Periph_ThresDelta_Mask		0xf

#define kIpeFlt_Periph_Integration_Shift	20
#define kIpeFlt_Periph_Integration_Mask		0xf

#if 0 //moved to SLTv4_HW_Definitions.h - names have changed -tb-
//run modes set by user in popup
#define kIpeFlt_EnergyMode		0
#define kIpeFlt_EnergyTrace		1
#define kIpeFlt_Histogram_Mode	2
...
#endif

#define kIpeFlt_Intack				0x40000000
#define kIpeFlt_READ				0x80000000
#define kIpeFlt_TP_Control			0x02000000
#define kIpeFlt_TP_End				0x01000000
#define kIpeFlt_Ec2					0x00800000
#define kIpeFlt_Ec1					0x00400000
#define kIpeFlt_PatternMask			0xffffffff // 22bit + Multiplicity
#define kIpeFlt_TestPattern_Reset	0x00000010


#define kSetStandBy		1
#define kReleaseStandBy 0

#define kFifoEnableOverFlow 0
#define kFifoStopOnFull     1

#define kFifoLength512		0
#define kFifoLength64		1

#define SELECT_ALL_CHANNELS ( 0x1F <<16) // ak, 7.10.07

#if 0 //is already in ORIpeV4FLTDefs.h -tb-
typedef struct {
	uint32_t channelMap; // 8bit channel + 24 channelMap
	uint32_t threshold;   
	uint32_t hitrate;
} ipeFltHitRateDataStruct;
#endif

#if 0
typedef struct { // -tb- 2008-02-27
	int32_t readoutSec;
	int32_t recordingTimeSec;  //! this holds the refresh time -tb-
	int32_t firstBin;
	int32_t lastBin;
	int32_t histogramLength; //don't use unsigned! - it may become negative, at least temporaryly -tb-
    int32_t maxHistogramLength;
    int32_t binSize;
    int32_t offsetEMin;
} ipcFltV4HistogramDataStruct;
#endif
