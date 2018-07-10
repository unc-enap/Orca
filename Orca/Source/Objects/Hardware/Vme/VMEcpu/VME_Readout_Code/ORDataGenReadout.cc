#include "ORDataGenReadout.hh"
#include <cmath>
#include <cstdlib>  
#include <sys/time.h>

bool ORDataGenReadout::Start() {
	struct timeval tv;
	struct timezone tz;
	gettimeofday(&tv, &tz);
	uint32_t usec = tv.tv_sec*1000000 + tv.tv_usec;
	nextBurst = usec+ (rand() % 3000000 + 1000000);
	nextBigBurst = usec+(rand() % 100000000 + 10000000);;
	return true;
}	

bool ORDataGenReadout::Readout(SBC_LAM_Data* /*lamData*/)
{
    uint32_t dataId1D       = GetHardwareMask()[0];
    uint32_t dataId2D       = GetHardwareMask()[1];
    uint32_t dataIdWaveform = GetHardwareMask()[2];
    uint32_t burstDataId	= GetHardwareMask()[3];
    
    if(rand()%500 > 495 ){
      
        uint32_t card = rand()%2;
        uint32_t chan = rand()%8;
        uint32_t aValue = (100*chan) + ((rand()%500 + rand()%500 + rand()%500)/3);
        if(card==0 && chan ==0)aValue = 100;
        
        ensureDataCanHold(5); 
        
        data[dataIndex++] = dataId1D | 2;
        data[dataIndex++] = (card<<16) | (chan << 12) | (aValue & 0x0fff);
        
        data[dataIndex++] = dataId2D | 3;
        aValue = 64 + ((rand()%128 + rand()%128 + rand()%128)/3);
        data[dataIndex++] = (aValue & 0x0fff); //card 0, chan 0
        aValue = 64 + ((rand()%64 + rand()%64 + rand()%64)/3);
        data[dataIndex++] = (aValue & 0x0fff);
    }
    
    if(rand()%20000 > 19998 ){
      
        ensureDataCanHold(2 * (2048+2));
        
        data[dataIndex++] = dataIdWaveform | (2048+2);
        data[dataIndex++] = 0x00001000; //card 0, chan 1
        float radians = 0;
        float delta = 2*3.141592/360.;
        int32_t i;
        for(i=0;i<2048;i++){
            data[dataIndex++] = (int32_t)(2*sin(4*radians));
            radians += delta;
        }  
        
        data[dataIndex++] = dataIdWaveform | (2048+2);
        data[dataIndex++] = 0; //card 0, chan 0
        int32_t a1 = (rand()%20);
        int32_t a2 = (rand()%20);
        for(i=0;i<2048;i++){
            data[dataIndex++] = (int32_t)((a1*sin(radians)) + (a2*sin(2*radians)));
            radians += delta;
        }
    }
	
	struct timeval tv;
	struct timezone tz;
	gettimeofday(&tv, &tz);
	uint32_t usec = tv.tv_sec*1000000 + tv.tv_usec;

	if( usec >= nextBurst){
		int32_t n = 1;
		bool doBigBurst = false;
		if( usec >= nextBigBurst){
			doBigBurst = true;
			n = (rand() % 1000 + 10);
		}

		for(int32_t i=0;i<n;i++){ 
			
			int32_t aValue = 100 + ((rand()%500 + rand()%500 + rand()%500)/3);
			
			ensureDataCanHold(3); 
			
			data[dataIndex++] = burstDataId | 3;
			data[dataIndex++] = (aValue & 0x0fff);
			data[dataIndex++] = usec;
			
		}
		nextBurst += (rand() % 3000000 + 1000000);
		if(doBigBurst) nextBigBurst += (rand() % 100000000 + 10000000);
	}
	
	
    return true; 
}
