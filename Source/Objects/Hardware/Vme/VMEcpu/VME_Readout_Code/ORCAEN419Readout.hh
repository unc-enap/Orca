#ifndef _ORCAEN419Readout_hh_
#define _ORCAEN419Readout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORCAEN419Readout : public ORVVmeCard
{
  public:
    ORCAEN419Readout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORCAEN419Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);
};

#endif /* _ORCAEN419Readout_hh_*/
