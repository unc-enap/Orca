#include "ORLAMData.hh"
#include <errno.h>
bool ORLAMData::Readout(SBC_LAM_Data* lamData)
{
    //this is a pseudo object that doesn't read any hardware, it just passes information back to ORCA
    lamData->lamNumber = GetSlot(); 

    SBC_Packet lamPacket;
    lamPacket.cmdHeader.destination           = kSBC_Process;
    lamPacket.cmdHeader.cmdID                 = kSBC_LAM;
    lamPacket.cmdHeader.numberBytesinPayload  = sizeof(SBC_LAM_Data);
    
    memcpy(&lamPacket.payload, lamData, sizeof(SBC_LAM_Data));
    postLAM(&lamPacket);
    
    return true; 
}
