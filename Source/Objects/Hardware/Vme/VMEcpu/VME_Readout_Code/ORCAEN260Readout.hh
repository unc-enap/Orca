#ifndef _ORCAEN260Readout_hh_
#define _ORCAEN260Readout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORCAEN260Readout : public ORVVmeCard
{
  public:
    ORCAEN260Readout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORCAEN260Readout() {} 
	virtual bool Start();
    virtual bool Readout(SBC_LAM_Data*);
	
	unsigned long lastScalerValue;
};

#endif /* _ORCAEN260Readout_hh_*/
