/***************************************************************************
    ORKatrinFLTDefs.h  -  description

    begin                : Tue Jul 18 2000
    copyright            : (C) 2000 by Andreas Kopmann
    email                : kopmann@hpe.fzk.de
 ***************************************************************************/

//Adress model
#define kKatrinFlt_AddressSpace 21		// Address Space Switch bits 23..21 (shortend!)
#define kKatrinFlt_ChannelAddress 16	// Channel Address      bits 20..16
#define kKatrinFlt_PageNumber 10		// Page Number          bits 14..10
#define kKatrinFlt_RegId 0				// Register Id          bits 15.. 0

#define kKatrinFlt_SlotId_All 0x1f // broadcast to all FLT boards
#define kKatrinFlt_ChannelAddress_All 0x1f // broadcast to all Channels

#define kKatrinFlt_Select_All_Slots	  ((0x1F <<24) + (0x1F <<16))
#define kKatrinFlt_Select_All_Channels ( 0x1F <<16)

#define kNumFLTChannels 22

#define kKatrinFlt_Page_Size 1000

#define kKatrinFlt_Pages 64

// Position of the bit fields
#define kKatrinFlt_Cntl_Version_Shift		29     //!< This is obsolete since FPGA firmware 3.x -tb-
#define kKatrinFlt_Cntl_Version_Mask		0x7    //!< This is obsolete since FPGA firmware 3.x -tb-
#define kKatrinFlt_Cntrl_CardID_Shift		24
#define kKatrinFlt_Cntrl_CardID_Mask		0x1f
#define kKatrinFlt_Cntrl_BufState_Shift		22     //!<In the FLT manual of Denis this is also called "FifoState".
#define kKatrinFlt_Cntrl_BufState_Mask		0x3   
#define kKatrinFlt_Cntrl_Mode_Shift			20
#define kKatrinFlt_Cntrl_Mode_Mask			0x3
#define kKatrinFlt_Cntrl_Write_Shift		11
#define kKatrinFlt_Cntrl_Write_Mask			0x1ff
#define kKatrinFlt_Cntrl_ReadPtr_Shift		0
#define kKatrinFlt_Cntrl_ReadPtr_Mask		0x1ff


// this are the flt run modes (fltRunMode; hardware modes)
#define kKatrinFlt_Debug_Mode		0
#define kKatrinFlt_Run_Mode			1
#define kKatrinFlt_Measure_Mode		2
#define kKatrinFlt_Test_Mode		3

//the daq run modes (daqRunMode) (see in the FLT Settings)
//see setDaqRunMode for the according fltModes
#define kKatrinFlt_DaqEnergyTrace_Mode		0
#define kKatrinFlt_DaqEnergy_Mode			1
#define kKatrinFlt_DaqHitrate_Mode          2
#define kKatrinFlt_DaqThresholdScan_Mode	4
#define kKatrinFlt_DaqTest_Mode             3
#define kKatrinFlt_DaqHistogram_Mode        5
#define kKatrinFlt_DaqVeto_Mode             6

#define kKatrinFlt_Intack			 0x40000000
#define kKatrinFlt_Read				 0x80000000
#define kKatrinFlt_TP_Control		 0x02000000
#define kKatrinFlt_TP_End			 0x01000000
#define kKatrinFlt_Ec2				 0x00800000
#define kKatrinFlt_Ec1				 0x00400000
#define kKatrinFlt_PatternMask		 0x003FFFFF
#define kKatrinFlt_TestPattern_Reset 0x00000010


/** Katrin event structure. 
  *
  * TODO: Again test in simulation mode...
  */
typedef struct {
	unsigned long sec;
	unsigned long subSec;
	unsigned long channelMap; // 8bit channel + 24 channelMap
	                          // <--actually redundant like to remove. MAH 7/20/07
	unsigned long eventID;    // 16bit number of pages in buffer + 16bit eventId
	unsigned long energy;
} katrinEventDataStruct;

/** Katrin event structure. 
  *
  *  
  */
typedef struct {
	unsigned long sec;
	unsigned long hitrate;
} katrinHitRateDataStruct;


typedef struct {
	// Added reset time stamp, ak 2.7.07
	unsigned long resetSec;
	unsigned long resetSubSec;
} katrinDebugDataStruct;


typedef struct {
	unsigned long channelMap; // 8bit channel + 24 channelMap
	unsigned long threshold;   
	unsigned long hitrate;
} katrinThresholdScanDataStruct;

typedef struct { // -tb- 2008-02-27
	long readoutSec;
	long recordingTimeSec;  //! this holds the refresh time -tb-
	long firstBin;
	long lastBin;
	long histogramLength; //don't use unsigned! - it may become negative, at least temporaryly -tb-
    long maxHistogramLength;
    long binSize;
    long offsetEMin;
} katrinHistogramDataStruct;

