#include "ORPollingTimeStampReadout.hh"
#include <sys/time.h>

bool ORPollingTimeStampReadout::Readout(SBC_LAM_Data* lamData)
{
    uint32_t dataId  = GetHardwareMask()[0];
    
    ensureDataCanHold(3); //max this card can produce

    data[dataIndex++] = dataId | 3;
    struct timeval ts;
    gettimeofday(&ts,NULL);
    data[dataIndex++] = ts.tv_sec;
    data[dataIndex++] = ts.tv_usec;

    return true;
}
