/**
 * Name: read_cal.c
 * Desc: Reads and displays device calibration information
**/

// For printf
#include <stdio.h>

// For sleep
#include <unistd.h>

// For assert
#include <assert.h>

// For the LabJackM library
#include <LabJackM.h>

#include "orca_t7.h"

#define kNumT7DacChannels 2
#define kNumT7AdcChannels 14
#define kNumT7IOChannels  23
#define kNumT7ClockSources 3
#define kNumT7Timers 2
#define kNumT7Counters 4

int main()
{
    int handle, err = 0;
    DeviceCalibrationT7 calInfo;
    DeviceConfigT7 confInfo;

    unsigned timeValue;
    long digitalValue;
    double analogValue, analogValue2;

    int i, j;

    // Open first found LabJack T7
    err += openLabJack(&handle, NULL);

    sleep(2);
    printf("\n-- BASIC CONFIG --\n");

    // Get config info
    err += getConfig(handle, &confInfo);

    // Get calibration info
    err += getCalibration(handle, &calInfo);

    // Read RTC
    {
        timeValue = 0;
        err += readRtc(handle, &timeValue);
    }

    // Read 10uA/200uA current source calibration from the LabJack
    {
        analogValue = 0; analogValue2 = 0;
        err += getCurrentValues(handle, &analogValue, &analogValue2);
    }

    sleep(2);
    printf("\n-- ANALOG IN/OUT --\n");

    // Set DAC value on the LabJack
    for(i=0;i<kNumT7DacChannels;i++) {
        analogValue = (double)i/10.;
        err += writeDAC(handle, &calInfo, i, analogValue);
    }

    // Read single-ended ADC value from the LabJack
    for(i=0;i<kNumT7AdcChannels;i++) {
        analogValue = 0;
        err += readAIN(handle, &calInfo, i, -1, &analogValue, NULL, 0, 0, 0, 0);
    }

    // Read temperature and noise ADC value (channels 14/15) from the LabJack
    {
        analogValue = 0;
        err += readAIN(handle, &calInfo, 14, -1, NULL, &analogValue, 0, 0, 0, 0);

        analogValue = 0;
        err += readAIN(handle, &calInfo, 15, -1, &analogValue, NULL, 0, 0, 0, 0);
    }

    // Read differential ADC value from the LabJack
    for(i=0;i<kNumT7AdcChannels;i+=2) {
        analogValue = 0;
        err += readAIN(handle, &calInfo, i, i+1, &analogValue, NULL, 0, 0, 0, 0);  // pos/neg channel
    }

    sleep(2);
    printf("\n-- DIGITAL IN/OUT --\n");

    // Set DIO state on the LabJack
    for(i=0;i<kNumT7IOChannels;i++) {
        digitalValue = i%2;
        err += writeDO(handle, i, digitalValue);
    }

    // Read DIO state from the LabJack
    for(i=0;i<kNumT7IOChannels;i++) {
        digitalValue = 0;
        err += readDI(handle, i, &digitalValue);
    }

    sleep(2);
    printf("\n-- COUNTERS --\n");

    // Setup precision counters on the LabJack
    for(i=0;i<kNumT7Counters;i++) {
        err += enableCounter(handle, i);
    }

    // Read precision counters on the LabJack
    for(j=0;j<3;j++) {
        for(i=0;i<kNumT7Counters;i++) {
            digitalValue = 0;
            err += readCounter(handle, i, i%2==0, &digitalValue);  // reset = 0/1
        }
        sleep(1);  // wait for one second
    }

    // Disable precision counters
    for(i=0;i<kNumT7Counters;i++) {
        disableCounter(handle, i);
    }

    sleep(2);
    printf("\n-- CLOCKS --\n");

    // Read clock sources from the LabJack
    for(i=0;i<kNumT7ClockSources;i++) {
        err += setupClock(handle, i, 1, 8<<i, 0, 0);  // divisor = 8,16,32,...

        for(j=0;j<3;j++) {
            digitalValue = 0;
            err += readClock(handle, i, &digitalValue);
            sleep(1);  // wait for one second
        }
    }

    sleep(2);
    printf("\n-- FREQUENCY --\n");

    // Read frequency counters on the LabJack
    // Note: we always use clock 0 here and thus cannot use CIO#0/1
    err += setupClock(handle, 0, 1, 8, 0, 0);  // clock = 0, divisor = 8

    for(i=2;i<kNumT7Counters;i++) {
        err += enableFreqIn(handle, i, 0, 3, 1);  // clock = 0, edge index = 3/4, continuous=1

        for(j=0;j<3;j++) {
            analogValue = 0;
            readFreqIn(handle, i, 80e6/8, NULL, &analogValue);  // clock freq. = 80M/divisor
            sleep(1);  // wait for one second
        }
    }

    sleep(2);
    printf("\n-- GOODBYE --\n");

    // Close LabJack
    err += closeLabJack(handle);

    return err;
}
