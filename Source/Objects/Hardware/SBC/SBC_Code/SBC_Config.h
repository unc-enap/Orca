
#ifndef _H_SBC_CONFIG_
#define _H_SBC_CONFIG_
#include <sys/types.h>
#include <stdint.h>
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

// ---------------------------------------------------------------------------- 
//    Generic hardware configuration structure used by both Mac and eCPU code.
#define MAX_CARDS            21
typedef struct {							// structure required for card
        uint32_t hw_type_id;                // unique hardware identifier code
        uint32_t hw_mask[10];				// hardware identifier mask to OR into data word
        uint32_t slot;						// slot identifier
        uint32_t crate;						// crate identifier
        uint32_t base_add;					// base addresses for each card
        uint32_t add_mod;					// address modifier (if needed)
        uint32_t deviceSpecificData[256];	// a card can use this block as needed.
        uint32_t next_Card_Index;			// next card_info index to be read after this one.        
        uint32_t num_Trigger_Indexes;		// number of triggers for this card
        uint32_t next_Trigger_Index[3];		//card_info index for device specific trigger
} SBC_card_info;

typedef struct {
    uint32_t header;
    int32_t total_cards;                   // total sum of all cards
    SBC_card_info
    card_info[MAX_CARDS];
} SBC_crate_config;

#define kSBC_CrateConfigSizeLongs sizeof(SBC_crate_config)/sizeof(uint32_t)
#define kSBC_CrateConfigSizeBytes sizeof(SBC_crate_config)
#define kSBC_MaxErrorBufferSize 8
#define kSBC_MaxStrSize 64

#define	kSBC_Success			0
#define	kSBC_WriteError			1
#define	kSBC_ReadError			2

#define	kSBC_NumRunInfoValuesToSwap	15

typedef struct {
    uint32_t statusBits;
    uint32_t readCycles;
    uint32_t bufferSize;
    uint32_t readIndex;
    uint32_t writeIndex;
    uint32_t lostByteCount;
    uint32_t amountInBuffer;
    uint32_t recordsTransfered;
    uint32_t wrapArounds;
	uint32_t busErrorCount;
	
	uint32_t err_count;
	uint32_t msg_count;
	uint32_t err_buf_index;
	uint32_t msg_buf_index;
    uint32_t pollingRate;
    
	//the following --DON'T-- have to be swapped-- put these last and 
	//bump the kSBC_NumRunInfoValuesToSwap if you add any other values to the above set
	char errorStrings[kSBC_MaxErrorBufferSize][kSBC_MaxStrSize];	// eCPU recent errors array
	char messageStrings[kSBC_MaxErrorBufferSize][kSBC_MaxStrSize];// eCPU recent messages array
} SBC_info_struct;

typedef struct {
    struct {
        uint32_t busErrorCount;
        uint32_t errorCount;
        uint32_t messageCount;
        uint32_t spares[10]; //use up if needed.
    } card[MAX_CARDS];
} SBC_error_struct;

#define kSBC_ConfigLoadedMask  (0x1 << 0)
#define kSBC_RunningMask       (0x1 << 1)
#define kSBC_PausedMask        (0x1 << 2)
#define kSBC_ThrottledMask     (0x1 << 3)

#define kSBC_InfoStructSizeLongs sizeof(SBC_info_struct)/sizeof(uint32_t)
#define kSBC_InfoStructSizeBytes sizeof(SBC_info_struct)

#endif
