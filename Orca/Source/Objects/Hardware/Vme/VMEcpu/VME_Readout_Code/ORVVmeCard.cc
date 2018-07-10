
#include "ORVVmeCard.hh"
#include "TUVMEDeviceManager.hh"
#include "TUVMEDevice.hh"
#include <unistd.h>
#include "ORScopedLock.hh"

TUVMEDevice* ORVVmeCard::fDevice = NULL;
ORVVmeCard::DeviceSet* ORVVmeCard::fAllDevices = new ORVVmeCard::DeviceSet();
pthread_mutex_t ORVVmeCard::fMutex = PTHREAD_MUTEX_INITIALIZER;

ORVVmeCard::ORVVmeCard(SBC_card_info* ci)
: ORVCard(ci)
{
    ScopedLock sL(fMutex);
    if (fAllDevices->size() == 0) {
        /* First time to initialize */
        fDevice =
          TUVMEDeviceManager::GetDeviceManager()->GetDevice(0x0, 0x9, 4, 0x0);
        /* Don't check if it's NULL*/
    }
    fAllDevices->insert(this);
}

ORVVmeCard::~ORVVmeCard()
{
    ScopedLock sL(fMutex);
    fAllDevices->erase(this);
    if (fAllDevices->size() == 0) {
        /* Close the device. */
        TUVMEDeviceManager::GetDeviceManager()->CloseDevice(fDevice);
        fDevice = NULL;
    }
}

int32_t ORVVmeCard::DMARead(uint32_t vme_address,
                            uint32_t address_modifier,
                            uint32_t data_width,
                            uint8_t* buffer,
                            uint32_t number_of_bytes,
                            bool auto_increment)
{
    ScopedLock sL(fMutex);
    if(!fDevice) return 0;
    TUVMEDevice* dma_device =
      TUVMEDeviceManager::GetDeviceManager()->GetDMADevice(vme_address,
                                                            address_modifier,
                                                            data_width,
                                                            auto_increment);
    if (!dma_device) {
		//try one more time after a very short delay
		usleep(1);
		dma_device = TUVMEDeviceManager::GetDeviceManager()->GetDMADevice(vme_address,
															 address_modifier,
															 data_width,
															 auto_increment);
		if (!dma_device) return -1;
	}
    int32_t bytes_read = dma_device->Read((char*)buffer,
										  number_of_bytes,
										  0x0);
    TUVMEDeviceManager::GetDeviceManager()->ReleaseDMADevice();
    if (bytes_read != (int32_t)number_of_bytes) return -1;
    return bytes_read;
}

int32_t ORVVmeCard::DMAWrite(uint32_t vme_address,
                             uint32_t address_modifier,
                             uint32_t data_width,
                             uint8_t* buffer,
                             uint32_t number_of_bytes,
                             bool auto_increment)
{
    ScopedLock sL(fMutex);
    TUVMEDevice* dma_device =
      TUVMEDeviceManager::GetDeviceManager()->GetDMADevice(vme_address,
                                                            address_modifier,
                                                            data_width,
                                                            auto_increment);
    if (!dma_device) return -1;
    int32_t bytes_written = dma_device->Write((char*)buffer,
		                           number_of_bytes,
					   0x0);
    TUVMEDeviceManager::GetDeviceManager()->ReleaseDMADevice();
    if (bytes_written != (int32_t)number_of_bytes) return -1;
    return bytes_written;
}
int32_t ORVVmeCard::VMERead(uint32_t vme_address,
                         uint32_t address_modifier,
                         uint32_t data_width,
                         uint8_t* buffer,
                         uint32_t number_of_bytes)
{
    ScopedLock sL(fMutex);
    if (!fDevice) return -1;
    /* Make sure things are aligned correctly. */
    uint32_t base_address = vme_address & 0xFFFF0000;
    uint32_t offset = vme_address & 0x0000FFFF;
    fDevice->SetWithAddressModifier(address_modifier);
    fDevice->SetVMEAddress(base_address);
    fDevice->SetDataWidth((TUVMEDevice::ETUVMEDeviceDataWidth)data_width);
    if (fDevice->Read((char*)buffer, number_of_bytes, offset)
     	     != (int32_t)number_of_bytes) return -1;
    return number_of_bytes;
}

int32_t ORVVmeCard::VMEWrite(uint32_t vme_address,
                          uint32_t address_modifier,
                          uint32_t data_width,
                          uint8_t* buffer,
                          uint32_t number_of_bytes)
{
    ScopedLock sL(fMutex);
    if (!fDevice) return -1;
    /* Make sure things are aligned correctly. */
    uint32_t base_address = vme_address & 0xFFFF0000;
    uint32_t offset = vme_address & 0x0000FFFF;
    fDevice->SetWithAddressModifier(address_modifier);
    fDevice->SetVMEAddress(base_address);
    fDevice->SetDataWidth((TUVMEDevice::ETUVMEDeviceDataWidth)data_width);
    if (fDevice->Write((char*)buffer, number_of_bytes, offset)
     	      != (int32_t)number_of_bytes) return -1;
    return number_of_bytes;
}
int32_t ORVVmeCard::VMERead(uint32_t vme_address,
                         uint32_t address_modifier,
                         uint32_t data_width,
                         uint32_t& buffer)
    { return VMERead(vme_address,
                     address_modifier,
                     data_width,
                     (uint8_t*) &buffer,
                     sizeof(buffer)); }

int32_t ORVVmeCard::VMERead(uint32_t vme_address,
                         uint32_t address_modifier,
                         uint32_t data_width,
                         uint16_t& buffer)
    { return VMERead(vme_address,
                     address_modifier,
                     data_width,
                     (uint8_t*) &buffer,
                     sizeof(buffer)); }

int32_t ORVVmeCard::VMERead(uint32_t vme_address,
                         uint32_t address_modifier,
                         uint32_t data_width,
                         uint8_t& buffer)
    { return VMERead(vme_address,
                     address_modifier,
                     data_width,
                     (uint8_t*) &buffer,
                     sizeof(buffer)); }

int32_t ORVVmeCard::VMEWrite(uint32_t vme_address,
                          uint32_t address_modifier,
                          uint32_t data_width,
                          uint32_t buffer)
    { return VMEWrite(vme_address,
                      address_modifier,
                      data_width,
                      (uint8_t*) &buffer,
                      sizeof(buffer)); }

int32_t ORVVmeCard::VMEWrite(uint32_t vme_address,
                          uint32_t address_modifier,
                          uint32_t data_width,
                          uint16_t buffer)
    { return VMEWrite(vme_address,
                      address_modifier,
                      data_width,
                      (uint8_t*) &buffer,
                      sizeof(buffer)); }

int32_t ORVVmeCard::VMEWrite(uint32_t vme_address,
                          uint32_t address_modifier,
                          uint32_t data_width,
                          uint8_t buffer)
    { return VMEWrite(vme_address,
                      address_modifier,
                      data_width,
                      (uint8_t*) &buffer,
                      sizeof(buffer)); }


