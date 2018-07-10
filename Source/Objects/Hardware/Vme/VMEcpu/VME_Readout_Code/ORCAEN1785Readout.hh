#ifndef _ORCAEN1785Readout_hh_
#define _ORCAEN1785Readout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORCAEN1785Readout : public ORVVmeCard
{
  public:
    ORCAEN1785Readout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORCAEN1785Readout() {} 
    virtual bool Readout(SBC_LAM_Data*);
  protected:
	virtual void FlushDataBuffer();
};

#endif /* _ORCAEN1785Readout_hh_*/
