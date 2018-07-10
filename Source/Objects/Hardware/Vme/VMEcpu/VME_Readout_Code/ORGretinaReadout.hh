#ifndef _ORGretinaReadout_hh_
#define _ORGretinaReadout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORGretinaReadout : public ORVVmeCard
{
  public:
    ORGretinaReadout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORGretinaReadout() {} 
    virtual bool Readout(SBC_LAM_Data*);
};

#endif /* _ORGretinaReadout_hh_*/
