//
//  orca_t7.h
//  Orca functions for LabJack T7-Pro
//
//  Created by Jan Behrens on Fri May 22, 2020.
//-----------------------------------------------------------


#ifndef _ORCA_LABJACKT7_H
#define _ORCA_LABJACKT7_H

#ifdef __cplusplus
extern "C"{
#endif

typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int uint32;

/*
 * Structure for storing calibration constants
 */
typedef struct {
    float PSlope;
    float NSlope;
    float Center;
    float Offset;
}Cal_Set;
typedef struct {
    float Slope;
    float Offset;
}Cal_Dac;
typedef struct{
    /*
        Calibration constants order:
        0 - AIN +-10V Slope, GainIndex=0
        1 - AIN +-10V Offset, GainIndex=0
        2 - AIN +-10V Neg. Slope, GainIndex=0
        3 - AIN +-10V Center Pt., GainIndex=0
        4 - AIN +-1V Slope, GainIndex=1
        5 - AIN +-1V Offset, GainIndex=1
        6 - AIN +-1V Neg. Slope, GainIndex=1
        7 - AIN +-1V Center Pt., GainIndex=1
        8 - AIN +-100mV Slope, GainIndex=2
        9 - AIN +-100mV Offset, GainIndex=2
        10 - AIN +-100mV Neg. Slope, GainIndex=2
        11 - AIN +-100mV Center Pt., GainIndex=2
        12 - AIN +-10mV Slope, GainIndex=3
        13 - AIN +-10mV Offset, GainIndex=3
        14 - AIN +-10mV Neg. Slope, GainIndex=3
        15 - AIN +-10mV Center Pt., GainIndex=3

        High Resolution:
        16 - AIN +-10V Slope, GainIndex=0
        17 - AIN +-10V Offset, GainIndex=0
        18 - AIN +-1V Slope, GainIndex=1
        19 - AIN +-1V Offset, GainIndex=1
        20 - AIN +-100mV Slope, GainIndex=2
        21 - AIN +-100mV Offset, GainIndex=2
        22 - AIN +-10mV Slope, GainIndex=3
        23 - AIN +-10mV Offset, GainIndex=3
        24 - AIN +-10V Neg. Slope, GainIndex=0
        25 - AIN +-10V Center Pt., GainIndex=0
        26 - AIN +-1V Neg. Slope, GainIndex=1
        27 - AIN +-1V Center Pt., GainIndex=1
        28 - AIN +-100mV Neg. Slope, GainIndex=2
        29 - AIN +-100mV Center Pt., GainIndex=2
        30 - AIN +-10mV Neg. Slope, GainIndex=3
        31 - AIN +-10mV Center Pt., GainIndex=3

        32 - DAC0 Slope
        33 - DAC0 Offset
        34 - DAC1 Slope
        35 - DAC1 Offset
        36 - Temperature Slope
        37 - Temperature Offset
        38 - Current Output 0
        39 - Current Output 1
        40 - Current Bias
    */
    Cal_Set HS[4];
    Cal_Set HR[4];
    Cal_Dac DAC[2];

    float Temp_Slope;
    float Temp_Offset;

    float ISource_10u;
    float ISource_200u;

    float I_Bias;
}DeviceCalibrationT7;

typedef struct {
    float prodID;
    float hwVersion;
    float fwVersion;
    float bootVersion;
    float wifiVersion;
    float hwInstalled;
    float serial;
}DeviceConfigT7;

/*
 * "Easy access" function declarations
 */

int openLabJack(int* hDevice, const char* identifier);

int closeLabJack(int hDevice);

int findLabJacks(int* hDevice);

int getConfig(int hDevice, DeviceConfigT7* confInfo);

int getCalibration(int hDevice, DeviceCalibrationT7* calInfo);

int getCurrentValues(int hDevice, double* Current10u, double* Current200u);

int readAIN(int hDevice, DeviceCalibrationT7* CalibrationInfo,
             int ChannelP, int ChannelN, double* Voltage, double* Temperature,
             double Range, long Resolution, double Settling, int Binary);

int writeDAC(int hDevice, DeviceCalibrationT7* CalibrationInfo,
              int Channel, unsigned Voltage);

int readDI(int hDevice, int Channel, long* State);

int writeDO(int hDevice, int Channel, long State);

int readRtc(int hDevice, unsigned* Seconds);

int setupClock(int hDevice, int Clock, int Enable,
                long Divisor, long RollValue, int External);

int readClock(int hDevice, int Clock, long* Count);

int setupPwm(int hDevice, int Channel, int Enable,
              int Clock, long DutyCycle);

int enableCounter(int hDevice, int Channel);

int disableCounter(int hDevice, int Channel);

int readCounter(int hDevice, int Channel, int Reset, long* Count);

int enableFreqIn(int hDevice, int Channel, int Clock,
                  int EdgeIndex, int Continuous);

int readFreqIn(int hDevice, int Channel, double ClockFreq,
                double* Period, double* Frequency);

#ifdef __cplusplus
}
#endif

#endif  // _ORCA_LABJACKT7_H
