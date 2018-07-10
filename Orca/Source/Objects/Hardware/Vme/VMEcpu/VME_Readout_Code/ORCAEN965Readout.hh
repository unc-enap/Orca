#ifndef _ORCAEN965Readout_hh_
#define _ORCAEN965Readout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORCaen965Readout : public ORVVmeCard
{
  public:
    ORCaen965Readout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORCaen965Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);
  protected:
	virtual void FlushDataBuffer();
};

#endif /* _ORCaen965Readout_hh_*/
