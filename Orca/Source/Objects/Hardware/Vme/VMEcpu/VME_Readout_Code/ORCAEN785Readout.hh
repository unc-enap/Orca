#ifndef _ORCAEN785Readout_hh_
#define _ORCAEN785Readout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORCaen785Readout : public ORVVmeCard
{
  public:
    ORCaen785Readout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORCaen785Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);
  protected:
	virtual void FlushDataBuffer();
};

#endif /* _ORCaen785Readout_hh_*/
