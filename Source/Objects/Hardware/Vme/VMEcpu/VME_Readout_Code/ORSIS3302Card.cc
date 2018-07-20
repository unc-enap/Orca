#include "ORSIS3302Card.hh"
#include <errno.h>
#include <unistd.h>

ORSIS3302Card::ORSIS3302Card(SBC_card_info* ci) :
ORVVmeCard(ci), 
fBankOneArmed(false),
fWaitCount(0)
{
}

uint32_t ORSIS3302Card::GetPreviousBankSampleRegisterOffset(size_t channel) 
{
    switch (channel) {
        case 0: return 0x02000018;
        case 1: return 0x0200001c;
        case 2: return 0x02800018;
        case 3: return 0x0280001c;
        case 4: return 0x03000018;
        case 5: return 0x0300001c;
        case 6: return 0x03800018;
        case 7: return 0x0380001c;
    }
    return (uint32_t)-1;
}

uint32_t ORSIS3302Card::GetADCBufferRegisterOffset(size_t channel) 
{
    switch (channel) {
        case 0: return 0x04000000;
        case 1: return 0x04800000;
        case 2: return 0x05000000;
        case 3: return 0x05800000;
        case 4: return 0x06000000;
        case 5: return 0x06800000;
        case 6: return 0x07000000;
        case 7: return 0x07800000;
    }
    return (uint32_t)-1;
}

bool ORSIS3302Card::Start()
{
	//---------------------------------------------------------------------------
	//special mode. 
	fProcessPulse = false;
	fPulseMode = GetDeviceSpecificData()[6];
	//---------------------------------------------------------------------------
	
	DisarmAndArmBank(2);
	DisarmAndArmBank(1);
	//bank one is armed are taking data
	return true;
}

bool ORSIS3302Card::Stop()
{
	//read out the last buffer, if there's a problem, just continue
	//if (!DisarmAndArmNextBank())return true;
	//usleep(50);
	//for( size_t i=0;i<GetNumberOfChannels();i++) {
	//	ReadOutChannel(i);
	//}	
	return true;
}

bool ORSIS3302Card::Resume()
{
	//---------------------------------------------------------------------------
	//reset special mode. 
	fProcessPulse = true;
	//---------------------------------------------------------------------------
	return true;
}

bool ORSIS3302Card::IsEvent()
{
	uint32_t addr = GetBaseAddress() + GetAcquisitionControl(); 
    uint32_t data_rd = 0;
    if (VMERead(addr,GetAddressModifier(),4,data_rd) != sizeof(data_rd)) { 
		LogBusErrorForCard(GetSlot(),"Bank Arm Err: SIS3302 0x%04x %s", GetBaseAddress(),strerror(errno));
    	return false;
    }
	uint32_t bankMask = fBankOneArmed?0x10000:0x20000;
	return  ((data_rd & 0x80000) == 0x80000) &&  
			((data_rd & bankMask) == bankMask);
}

bool ORSIS3302Card::SetupPageReg()
{
	uint32_t data_wr;				
	if (fBankOneArmed)  data_wr = 0x4;	// Bank 1 is armed and bank two must be read 
	else				data_wr = 0x0;	// Bank 2 is armed and bank one must be read
	uint32_t addr = GetBaseAddress() + GetADCMemoryPageRegister() ;
	if (VMEWrite(addr,GetAddressModifier(), GetDataWidth(),data_wr) != sizeof(data_wr)){
		LogBusErrorForCard(GetSlot(),"Page Reg Err: SIS3302 0x%04x %s", GetBaseAddress(),strerror(errno));
		return false;
	}
	else return true;
}

bool ORSIS3302Card::resetSampleLogic()
{
	uint32_t data_wr = 0;				
	uint32_t addr = GetBaseAddress() + 0x404 ;
	if (VMEWrite(addr , GetAddressModifier(), GetDataWidth(),data_wr) != sizeof(data_wr)){
		LogBusErrorForCard(GetSlot(),"Logic Reset Err: SIS3302 0x%04x %s", GetBaseAddress(),strerror(errno));
		return false;
	}
	return DisarmAndArmNextBank();
}

bool ORSIS3302Card::Readout(SBC_LAM_Data* /*lam_data*/) 
{		
	//---------------------------------------------------------------------------
	//special run mode. If in the pulse mode we will only read one bank one time the SBC is unpaused.
	if(fPulseMode && !fProcessPulse)return true;
	//---------------------------------------------------------------------------
	
	if(!fWaitingForSomeChannels){
		time_t theTime;
		time(&theTime);
		if(((theTime - fLastBankSwitchTime) < 2) && !IsEvent())	return false; //not going to readout so return
		if(!DisarmAndArmNextBank())								return false; //error in switching so return
		fWaitCount = 0;
	}
	
	//if we get here, there may be something to read out
	for( size_t i=0;i<GetNumberOfChannels();i++) {
		if ( fChannelsToReadMask & (1<<i)){
			ReadOutChannel(i);
		}
	}
	
	fWaitingForSomeChannels = (fChannelsToReadMask!=0);
	
	if(fWaitingForSomeChannels){
		//if we wait too int32_t, do a logic reset
		fWaitCount++;
		if(fWaitCount > 1000){
			LogErrorForCard(GetSlot(),"SIS3302 0x%x Rd delay reset:  0x%02x", GetBaseAddress(),fChannelsToReadMask);
			
			ensureDataCanHold(3);
			data[dataIndex++] = GetHardwareMask()[1] | 3; 
			data[dataIndex++] = ((GetCrate()     & 0x0000000f) << 21) | 
								((GetSlot()      & 0x0000001f) << 16) | 1; //1 == reset event
			data[dataIndex++] = fChannelsToReadMask<<16;
			resetSampleLogic();
		}
	}
	else {
		//---------------------------------------------------------------------------
		//special run mode.
		if(fPulseMode){
			fProcessPulse = false;
			//go back to bank 1
			DisarmAndArmNextBank();
		}
		//---------------------------------------------------------------------------
	}
	
	return true;
}

void ORSIS3302Card::ReadOutChannel(size_t channel) 
{	
	uint32_t addr = GetBaseAddress() + GetPreviousBankSampleRegisterOffset(channel) ; 
	uint32_t endSampleAddress = 0;
	
	if (VMERead(addr,GetAddressModifier(),GetDataWidth(),(uint8_t*)&endSampleAddress,sizeof(uint32_t)) != sizeof(uint32_t)) { 
		LogBusErrorForCard(GetSlot(),"Rd NextSpl Err: SIS3302 0x%04x %s", GetBaseAddress(),strerror(errno));
		return;
	}
	usleep(1);
	//bit 24 is the bank bit. It must match the bank that we are reading out or chaos will result. 
	if (((endSampleAddress >> 24) & 0x1) ==  (fBankOneArmed ? 1:0)) { 
		//The bit matches, we will flag this channel as having been read out.
		fChannelsToReadMask &= ~(1<<channel);
		
		//endSampleAddress is num of shorts so  strip off bit 24 and convert to bytes
		uint32_t numberBytesToRead		= (endSampleAddress & 0xffffff) * 2;
		
		if(numberBytesToRead){
			size_t group					= channel/2;
			uint32_t addr					= GetBaseAddress() + GetADCBufferRegisterOffset(channel);
			size_t numberLongsInRawData		= GetDeviceSpecificData()[group];
			size_t numberLongsInEnergyData	= GetDeviceSpecificData()[4];
			size_t bufferWrapMask			= GetDeviceSpecificData()[5];
			
			//calculate the record size.
			//the header size changes if the wrap mode is selected for a group
			size_t sisHeaderSize;						
			bool bufferWrap = (bufferWrapMask & (1L<<group))!=0;
			if(bufferWrap) sisHeaderSize = kHeaderSizeInLongsWrap;
			else		   sisHeaderSize = kHeaderSizeInLongsNoWrap;
			
			uint32_t sizeOfRecord	=	sisHeaderSize		 + 
										kTrailerSizeInLongs  + 
										numberLongsInRawData + 
										numberLongsInEnergyData;
			//the card may write past the 8MB page boundary. If it does, we flag those as lost
			uint32_t numRecordsLost = 0;
			uint32_t sizeOfRecordBytes = sizeOfRecord*sizeof(uint32_t);
			if(numberBytesToRead > 0x800000){
				uint32_t oldSize  = numberBytesToRead;
				numberBytesToRead = sizeOfRecordBytes * (0x800000/sizeOfRecordBytes);
				numRecordsLost	  = (oldSize - numberBytesToRead)/sizeOfRecordBytes;
				LogMessageForCard(GetSlot(),"ch%d>8MB: %u %u (lost: %u)",channel,numberBytesToRead, sizeOfRecordBytes,numRecordsLost);
				
				ensureDataCanHold(3);
				data[dataIndex++] = GetHardwareMask()[1] | 3; 
				data[dataIndex++] = ((GetCrate()     & 0x0000000f) << 21) | 
									((GetSlot()      & 0x0000001f) << 16) | 
									((channel        & 0x000000ff) << 8)  ;
				data[dataIndex++] = numRecordsLost;
			}
			
			//OK, the numberBytesToRead should be set to the last record that fits in the 8MB buffer (at most)
			size_t numLongsToRead = numberBytesToRead/4;
			
			int32_t error = DMARead(addr, 
									(uint32_t)0x08, // Address Modifier, request MBLT 
									(uint32_t)8,	// Read 64-bits at a time (redundant request)
									(uint8_t*)dmaBuffer,  
									numberBytesToRead);
			
			if (error != (int32_t) numberBytesToRead) { 
				if(error > 0) LogErrorForCard(GetSlot(),"DMA:SIS3302 0x%04x %d!=%d", GetBaseAddress(),error,numberBytesToRead);
				return;
			}
			
			// Put the data into the data stream
			for (size_t i = 0; i < numLongsToRead; i += sizeOfRecord) {
				if(dmaBuffer[i+sizeOfRecord-1] == 0xdeadbeef){
					ensureDataCanHold(sizeOfRecord + 4);
					data[dataIndex++] = GetHardwareMask()[0] | (sizeOfRecord+4); 
					data[dataIndex++] = ((GetCrate()     & 0x0000000f) << 21) | 
										((GetSlot()      & 0x0000001f) << 16) | 
										((channel        & 0x000000ff) << 8)  |
										bufferWrap;
					data[dataIndex++] = numberLongsInRawData;
					data[dataIndex++] = numberLongsInEnergyData;
					memcpy(data + dataIndex, &dmaBuffer[i], sizeOfRecord*sizeof(uint32_t));
						
					dataIndex += sizeOfRecord;
				}
				else {
					break;
				}
			}
		}
	}
}

bool ORSIS3302Card::DisarmAndArmBank(size_t bank) 
{
	time(&fLastBankSwitchTime);
	fWaitingForSomeChannels = true;
	fChannelsToReadMask = 0xff;
    uint32_t addr;
	fBankOneArmed = (bank==1);
    if (bank==1) addr = GetBaseAddress() + 0x420;
    else		 addr = GetBaseAddress() + 0x424;
	
    if (VMEWrite(addr, GetAddressModifier(), GetDataWidth(), (uint32_t) 0x0) == sizeof(uint32_t)){
		return SetupPageReg();
	}
	else {
		LogBusErrorForCard(GetSlot(),"Bank Arm Err: SIS3302 0x%04x %s", GetBaseAddress(),strerror(errno));
		return false;
	}
	
	
}

bool ORSIS3302Card::DisarmAndArmNextBank()
{ 	
	if(fBankOneArmed)	return DisarmAndArmBank(2);
	else				return DisarmAndArmBank(1);
}

