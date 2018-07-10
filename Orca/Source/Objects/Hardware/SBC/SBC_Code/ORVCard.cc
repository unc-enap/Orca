#include "ORVCard.hh"

int32_t ORVCard::ReadoutAndGetNextIndex(SBC_LAM_Data* lam_data)
{
    Readout(lam_data);
    return GetNextCardIndex();
}
