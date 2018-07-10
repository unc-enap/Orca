/***************************************************************************
    ORAugerFLTDefs.h  -  description

    begin                : Tue Jul 18 2000
    copyright            : (C) 2000 by Andreas Kopmann
    email                : kopmann@hpe.fzk.de
 ***************************************************************************/

//Adress model
#define FLT_ADDRSP 21   // Address Space Switch bits 22..21 (shortend!)
#define FLT_CHADDR 16   // Channel Address      bits 20..16
#define FLT_PAGENR 10   // Page Number          bits 14..10
#define FLT_REGID 0     // Register Id          bits 14.. 0

#define FLT_SLOTID_ALL 0x1f // broadcast to all FLT boards
#define FLT_CHADDR_ALL 0x1f // broadcast to all Channels

#define SELECT_ALL_SLOTS	  ((0x1F <<24) + (0x1F <<16))
#define SELECT_ALL_CHANNELS ( 0x1F <<16)


#define kNumFLTChannels 22

#define FLT_PAGE_SIZE 1000

#define FLT_PAGES 64

// Position of the bit fields
#define FLT_CNTRL_VERSION       29
#define FLT_CNTRL_VERSION_Mask  0x7
#define FLT_CNTRL_CardID		24
#define FLT_CNTRL_CardID_Mask   0x1f
#define FLT_CNTRL_BufState		22   
#define FLT_CNTRL_Mode			20
#define FLT_CNTRL_Mode_Mask		0x3
#define FLT_CNTRL_WritePtr		11
#define FLT_CNTRL_Write_Mask	0x1ff
#define FLT_CNTRL_ReadPtr		0
#define FLT_CNTRL_ReadPtr_Mask	0x1ff


#define FLT_DEBUG_MODE		0
#define FLT_RUN_MODE		1
#define FLT_MEASURE_MODE	2
#define FLT_TEST_MODE		3

#define FLT_INTACK   0x40000000
#define FLT_READ	 0x80000000
#define FLT_TP_CNTRL 0x02000000
#define FLT_TP_END   0x01000000
#define FLT_EC2      0x00800000
#define FLT_EC1      0x00400000
#define FLT_PATMASK  0x003FFFFF
#define FLT_TP_RESET 0x00000010

enum {
	kFLTControlReg,
	kFLTTimeCounter,
	kFLTTriggerControl,
	kFLTThreshold,
	kFLTHitrateControl,
	kFLTHitrate,
	kFLTGain,
	kFLTTriggerData,
	kFLTTriggerEnergy,
	kFLTNumRegs					//must be last
};


/** KATRIN event structure. 
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
} eventData;


typedef struct {
	// Added reset time stamp, ak 2.7.07
	unsigned long resetSec;
	unsigned long resetSubSec;
} debugData;


typedef struct {
	unsigned long channelMap; // 8bit channel + 24 channelMap
	unsigned long threshold;   
	unsigned long hitrate;
} hitRateData;


