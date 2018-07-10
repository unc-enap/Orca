#ifndef ORXyCom564Readout_hh
#define ORXyCom564Readout_hh
#include "ORVVmeCard.hh"
#include <vector>

class ORXyCom564Readout: public ORVVmeCard
{
public:
    typedef std::vector<uint16_t> ReadinVec;
    typedef std::vector<uint32_t> AvgVec;
    ORXyCom564Readout(SBC_card_info* ci) :
      ORVVmeCard(ci),
      _averagingLength(1),
      _addDataToStream(true) {}

    bool Start();
    bool Readout(SBC_LAM_Data*);
    void Print(SBC_Packet*);

    const AvgVec& GetAverageData() const
    {
      return _avgSaveCache;
    }

protected:

    void AddDataValues(const ReadinVec& vec);
    void ShipData();

    ReadinVec _readInCache;
    AvgVec    _avgCache;
    AvgVec    _avgSaveCache;
    uint32_t  _averagingLength;
    uint32_t  _currentInVector;
    bool      _addDataToStream;

};
#endif
