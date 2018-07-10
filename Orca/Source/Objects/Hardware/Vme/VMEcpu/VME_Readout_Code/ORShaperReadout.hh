#ifndef _ORShaperReadout_hh_
#define _ORShaperReadout_hh_
#include "ORVVmeCard.hh"

class ORShaperReadout : public ORVVmeCard
{
  public:
    ORShaperReadout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORShaperReadout() {} 
    virtual bool Readout(SBC_LAM_Data*);
};

#endif /* _ORShaperReadout_hh_*/
