#ifndef _ORCAEN1730Readout_hh_
#define _ORCAEN1730Readout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORCAEN1730Readout : public ORVVmeCard
{
public:
    ORCAEN1730Readout(SBC_card_info* ci) : ORVVmeCard(ci) {}
    virtual ~ORCAEN1730Readout() {}
    virtual bool Start();
    virtual bool Readout(SBC_LAM_Data*);
private:
    uint32_t userBLTEventsNumber;
    uint32_t currentBLTEventsNumber;
};

#endif /* _ORCAEN1730Readout_hh_*/

