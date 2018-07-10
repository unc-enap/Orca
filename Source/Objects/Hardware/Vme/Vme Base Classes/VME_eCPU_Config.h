// ---------------------------------------------------------------------------- 
//	Generic hardware configuration structure used by both Mac and eCPU code.
//	Note this information is passed via the DPM
//	Special notes - the size required is based on these two defined constants
//		current space (with 10 and 16 is 920 bytes)
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

#define MAX_CARDS			21
 
typedef struct {
    unsigned long total_cards;					// total sum of all cards
    struct {									// structure required for card
        unsigned long	hw_type_id;				// unique hardware identifier code
        unsigned long	hw_mask[10];			// hardware identifier mask to OR into data word
        unsigned long	slot;					// slot identifier
        unsigned long	add_mod;				// VME address modifier for this hardware object
		unsigned long	base_add;				// base addresses for each card
		unsigned long	deviceSpecificData[5];	// a card can use this block as needed.
		unsigned long	next_Card_Index;		// next card_info index to be read after this one.		
		unsigned long 	num_Trigger_Indexes;	// number of triggers for this card
		unsigned long	next_Trigger_Index[3];	//card_info index for device specific trigger
	} card_info[MAX_CARDS];
} VME_crate_config;

@interface NSObject (VME_eCPU_ext)
- (int) load_eCPU_HW_Config_Structure:(VME_crate_config*)configStruct index:(int)index;
@end