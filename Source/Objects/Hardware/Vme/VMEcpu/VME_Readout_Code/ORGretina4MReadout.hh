#ifndef _ORGretina4MReadout_hh_
#define _ORGretina4MReadout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORGretina4MReadout : public ORVVmeCard
{
  public:
    ORGretina4MReadout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORGretina4MReadout() {} 
    virtual bool Readout(SBC_LAM_Data*);
    virtual void clearFifo(uint32_t fifoClearAddress);    
};

#endif /* _ORGretinaReadout_hh_*/
