#include "ORVVmeCard.hh"
#include <time.h>
#include <sys/time.h>

class ORSIS3316Card: public ORVVmeCard
{
public:
	ORSIS3316Card(SBC_card_info* card_info);
	virtual ~ORSIS3316Card() {}
	
	virtual bool Start();
	virtual bool Readout(SBC_LAM_Data* /* lam_data*/);  
	virtual bool Resume();
	virtual bool Stop();
protected:
    void SwitchBanks();
    void ArmBank1();
    void ArmBank2();
    void ResetFSM(uint32_t iGroup);
    void ReadHistograms();
    void ReadStatistics();
    
    uint32_t currentBank;
	uint32_t previousBank;
    uint32_t chanEnabledMask;
    uint32_t histoEnabledMask;
    uint32_t writeEventsEnabledMask;
    uint32_t currentSec;
    
};
