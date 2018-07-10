#ifndef _ORCAEN830Readout_hh_
#define _ORCAEN830Readout_hh_
#include "ORVVmeCard.hh"

class ORCAEN830Readout : public ORVVmeCard
{
  public:
    ORCAEN830Readout(SBC_card_info* ci) : ORVVmeCard(ci) {} 
	virtual bool Start();
    virtual ~ORCAEN830Readout() {}
    virtual bool Readout(SBC_LAM_Data*);
private:
    bool     chan0Enabled;
    uint32_t errorCount;
    uint32_t goodCount;

};

#endif /* _ORCAEN830Readout_hh_*/
