#ifndef _ORCAEN1721Readout_hh_
#define _ORCAEN1721Readout_hh_
#include "ORVVmeCard.hh"
#include <iostream>

class ORCAEN1721Readout : public ORVVmeCard
{
  public:
    ORCAEN1721Readout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
    virtual ~ORCAEN1721Readout() {} 
	virtual bool Start();
    virtual bool Readout(SBC_LAM_Data*);
private:
	uint32_t userBLTEventsNumber;
	uint32_t currentBLTEventsNumber;
	uint32_t fixedEventSize;
    uint32_t firmwareBugZero;
};

#endif /* _ORCAEN1721Readout_hh_*/
