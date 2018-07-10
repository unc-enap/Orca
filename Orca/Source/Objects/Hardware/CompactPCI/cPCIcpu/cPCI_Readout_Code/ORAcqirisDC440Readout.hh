#ifndef _ORAcqirisDC440Readout_hh_
#define _ORAcqirisDC440Readout_hh_
#ifdef __cplusplus
#include "ORVCard.hh"

class ORAcqirisDC440Readout : public ORVCard
{
  public:
    ORAcqirisDC440Readout(SBC_card_info* ci) : ORVCard(ci) {} 
    virtual ~ORAcqirisDC440Readout() {} 
    virtual bool Start();
    virtual bool Readout(SBC_LAM_Data*);
    virtual bool Stop();

  protected:
    SBC_Packet fSendPacket;
};

extern "C" {
#endif /* __cplusplus */
// Legacy function for backwards compatibility
int32_t Readout_DC440(uint32_t boardID, uint32_t numberSamples,
                      uint32_t enableMask, uint32_t dataID,
                      uint32_t location, char autoRestart,
                      char useCircularBuffer);
#ifdef __cplusplus
}
#endif /* __cplusplus */
#endif /* _ORAcqirisDC440Readout_hh_*/
