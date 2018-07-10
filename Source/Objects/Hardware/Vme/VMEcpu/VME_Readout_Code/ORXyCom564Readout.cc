#include "ORXyCom564Readout.hh"
#include <iostream>
#include <algorithm>
#include <sys/time.h>

void recenterValue(uint16_t& raw)
{
  // first thing, centering so that 0x8000 is 0.
  if (raw < 0x8000) {
      // Really positive numbers
      raw += 0x8000;
  } else {
      // really negative numbers
      raw -= 0x8000;
  }
}

void ORXyCom564Readout::ShipData()
{
  // Note, this is only thread safe in the run thread.
  ensureDataCanHold(_avgSaveCache.size()+4);
  uint32_t dataId   = GetHardwareMask()[0];
  uint32_t slot     = GetSlot();
  uint32_t crate    = GetCrate();
  uint32_t location = ((crate&0x0000000f)<<21) | ((slot& 0x0000001f)<<16);
  data[dataIndex++] = dataId | (_avgSaveCache.size() + 4);
  data[dataIndex++] = location;

  struct timeval ut_time;
  gettimeofday(&ut_time, NULL);
  data[dataIndex++] = ut_time.tv_sec;	//seconds since 1970
  data[dataIndex++] = ut_time.tv_usec;	//seconds since 1970
  for(size_t i=0;i<_avgSaveCache.size();i++) {
    data[dataIndex++] = (i & 0xff) << 16 | (_avgSaveCache[i] & 0xffff);
  }
}

void ORXyCom564Readout::AddDataValues(const ReadinVec& vec)
{
  for(size_t i=0;i<vec.size();i++) {
    _avgCache[i] += vec[i];
  }
  _currentInVector++;

  if (_currentInVector == _averagingLength) {
    _avgSaveCache = _avgCache;
    if (_averagingLength > 1) {
      for(size_t i=0;i<_avgSaveCache.size();i++) {
        _avgSaveCache[i] /= _averagingLength;
      }
    }
    std::fill(_avgCache.begin(), _avgCache.end(), 0);
    if (_addDataToStream) ShipData();
    _currentInVector = 0;
  }
}

bool ORXyCom564Readout::Start()
{
  uint32_t chanToRead = GetDeviceSpecificData()[1];
  _averagingLength    = GetDeviceSpecificData()[2];
  _addDataToStream    = GetDeviceSpecificData()[3] != 0;
  if (_averagingLength < 1) _averagingLength = 1;
  _currentInVector = 0;
  _readInCache.resize(chanToRead);
  _avgCache.resize(chanToRead);
  std::fill(_avgCache.begin(), _avgCache.end(), 0);
  return true;
}

bool ORXyCom564Readout::Readout(SBC_LAM_Data*)
{
    uint32_t baseAddress   = GetBaseAddress();
    uint32_t adScanAddress = GetDeviceSpecificData()[0];

    uint32_t bytesToRead = _readInCache.size()*sizeof(_readInCache[0]);
    if ( VMERead(baseAddress + adScanAddress,
                 GetAddressModifier(),
                 sizeof(_readInCache[0]),
                 (uint8_t*) &_readInCache[0],
                 bytesToRead) < 0 ) return false;

    std::for_each(_readInCache.begin(), _readInCache.end(), recenterValue);
    AddDataValues(_readInCache);
    return true;
}
