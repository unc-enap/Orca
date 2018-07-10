#include <stdint.h>
#include "SBC_Config.h"
#include "SBC_Cmds.h"
#ifdef __cplusplus
extern "C" {
class ORVCard;
#else
struct ORVCard;
#endif

// Returns number of cards loaded.
int32_t load_card(SBC_card_info* card_info, int32_t index);
int32_t start_card(int32_t index);
int32_t readout_card(int32_t index, SBC_LAM_Data* lam_data);
int32_t stop_card(int32_t index);
int32_t remove_card(int32_t index);
int32_t pause_card(int32_t index);
int32_t resume_card(int32_t index);
	// Returns the ORVCard* at the index
// NULL if cannot find
#ifndef __cplusplus
struct
#endif
ORVCard* peek_at_card(int32_t index);

#ifdef __cplusplus
}
#endif


