#ifndef _ORGretina4AReadout_hh_
#define _ORGretina4AReadout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORGretina4AReadout : public ORVVmeCard
{
  public:
    ORGretina4AReadout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORGretina4AReadout() {} 
    virtual bool Readout(SBC_LAM_Data*);
    virtual void clearFifo(uint32_t fifoClearAddress);    
};

#endif /* _ORGretinaReadout_hh_*/
