//
//  orca_t7.h
//  Orca functions for LabJack T7-Pro
//
//  Created by Jan Behrens on Fri May 22, 2020.
//-----------------------------------------------------------

#include <sys/time.h>
#include <assert.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>

// For the LabJackM library
#include <LabJackM.h>

// For LabJackM helper functions, such as OpenOrDie, PrintDeviceInfoFromHandle,
// ErrorCheck, etc.
#include "LJM_Utilities.h"

// Enable for standard error checks
//#define LJM_CHECK

// Enable for additional output on read/write
#define LJM_DEBUG

#include "orca_t7.h"

int openLabJack(int* hDevice, const char* identifier)
{
    int err = 0;

    EnableLoggingLevel(LJM_TRACE);
    SetConfigValue(LJM_OPEN_TCP_DEVICE_TIMEOUT_MS, 500);
    SetConfigValue(LJM_SEND_RECEIVE_TIMEOUT_MS, 500);

    if (identifier)
        err = LJM_Open(LJM_dtT7, LJM_ctANY, identifier, hDevice);  // see LabJackM.h
    else
        err = LJM_Open(LJM_dtT7, LJM_ctANY, "ANY", hDevice);  // see LabJackM.h
#ifdef LJM_CHECK
    ErrorCheck(err, "LJM_Open");
#endif

#ifdef LJM_DEBUG
    PrintDeviceInfoFromHandle(*hDevice);
#endif

    return err;
}

int closeLabJack(int hDevice)
{
    int err = 0;

    err = LJM_Close(hDevice);
#ifdef LJM_CHECK
    ErrorCheck(err, "LJM_Close");
#endif

    return err;
}

int findLabJacks(int* hDevice)
{
    int err = 0;

    int numFound = 0;
    int aDeviceTypes[LJM_LIST_ALL_SIZE];
    int aConnectionTypes[LJM_LIST_ALL_SIZE];
    int aSerialNumbers[LJM_LIST_ALL_SIZE];
    int aIPAddresses[LJM_LIST_ALL_SIZE];

    err = LJM_ListAll(LJM_dtT7, LJM_ctANY, &numFound,
                      aDeviceTypes, aConnectionTypes, aSerialNumbers, aIPAddresses);
#ifdef LJM_CHECK
    ErrorCheck(err, "LJM_ListAll");
#endif

#ifdef LJM_DEBUG
    int i;
    for (i=0; i<numFound; i++)
        printf("LabJack device found: 0x%x (%s, %s)\n",
               aSerialNumbers[i],
               NumberToDeviceType(aDeviceTypes[i]),
               NumberToConnectionType(aConnectionTypes[i]));
#endif

    if (hDevice && numFound > 0)
        *hDevice = aSerialNumbers[0];

    return err;
}

int getConfig(int hDevice, DeviceConfigT7* confInfo)
{
    if( confInfo == NULL )
    {
        printf("getConfigInfo error: Invalid config information.\n");
        return 255;
    }

    int err = 0, i;
    int errorAddress = INITIAL_ERR_ADDRESS;

    enum { NUM_VALUES = 8 };
    int ADRESSES[NUM_VALUES] = {55100, 60000, 60002, 60004, 60006, 60008, 60010, 60028};
    int TYPES[NUM_VALUES] = {LJM_UINT32, LJM_FLOAT32, LJM_FLOAT32, LJM_FLOAT32, LJM_FLOAT32, LJM_FLOAT32, LJM_FLOAT32, LJM_UINT32};
    double aValues[NUM_VALUES] = {0, 0, 0, 0, 0, 0, 0, 0};

    err = LJM_eReadAddresses(hDevice, NUM_VALUES, ADRESSES, TYPES, aValues,
            &errorAddress);
#ifdef LJM_CHECK
    ErrorCheckWithAddress(err, errorAddress, "LJM_eReadAddresses");
#endif

    assert( aValues[0] == 0x00112233 );  // magic number
    assert( aValues[1] == 7 );  // T7 or T7-Pro

    float * conf = (float *)confInfo;
    for (i=1; i<NUM_VALUES; i++)
        conf[i-1] = aValues[i];

#ifdef LJM_DEBUG
    printf("Conf values:\n");
    printf("  ProductID     : %.0f\n", confInfo->prodID);
    printf("  HW version    : %.3f\n", confInfo->hwVersion);
    printf("  FW version    : %.3f\n", confInfo->fwVersion);
    printf("  Boot version  : %.3f\n", confInfo->bootVersion);
    printf("  WiFi version  : %.3f\n", confInfo->wifiVersion);
    printf("  HW installed  : %.0f\n", confInfo->hwInstalled);
    printf("  Serial number : %.0f\n", confInfo->serial);
#endif

    return err;
}

int getCalibration(int hDevice, DeviceCalibrationT7* calInfo)
{
    if( calInfo == NULL )
    {
        printf("getCalibrationInfo error: Invalid calibration information.\n");
        return 255;
    }

    int err = 0, i;
    int errorAddress = INITIAL_ERR_ADDRESS;

    const double EFAdd_CalValues = 0x3C4000;  // TODO: what is this?

    const int FLASH_PTR_ADDRESS = 61810;  // INTERNAL_FLASH_READ_POINTER
    const int FLASH_PTR_TYPE = LJM_UINT32;

    // 3 frames of 13 values, one frame of 2 values
    enum { NUM_FRAMES = 4 };
    int FLASH_READ_ADDRESSES[1] = {61812};  // INTERNAL_FLASH_READ
    int FLASH_READ_TYPES[1] = {LJM_FLOAT32};
    int FLASH_READ_DIRECTIONS[1] = {LJM_READ};
    int FLASH_READ_NUM_VALUES[NUM_FRAMES] = {13, 13, 13, 2};
    enum { NUM_VALUES = 41 };
    double aValues[NUM_VALUES] = {0.0};

    for (i=0; i<NUM_FRAMES; i++) {
        // Set the pointer. This indicates which part of the memory we want to read
        err = LJM_eWriteAddress(hDevice, FLASH_PTR_ADDRESS, FLASH_PTR_TYPE, EFAdd_CalValues + i * 13 * 4);
#ifdef LJM_CHECK
        ErrorCheck(err, "LJM_eWriteAddress(..., %d, %d, %f)", FLASH_PTR_ADDRESS, FLASH_PTR_TYPE,
                EFAdd_CalValues);
#endif
        err = LJM_eAddresses(hDevice, 1, FLASH_READ_ADDRESSES, FLASH_READ_TYPES,
                FLASH_READ_DIRECTIONS, &(FLASH_READ_NUM_VALUES[i]), aValues + i * 13,
                &errorAddress);
#ifdef LJM_CHECK
        ErrorCheckWithAddress(err, errorAddress, "LJM_eAddresses");
#endif
    }

    // Copy to our cal constants structure
    float * cal = (float *)calInfo;
    for (i=0; i<NUM_VALUES; i++)
        cal[i] = aValues[i];

#ifdef LJM_DEBUG
    printf("Cal values:\n");
    for (i=0; i<4; i++) {
        printf("  HS[%d]:\n", i);
        printf("    PSlope : %+.10f\n", calInfo->HS[i].PSlope);
        printf("    NSlope : %+.10f\n", calInfo->HS[i].NSlope);
        printf("    Center : %+f\n", calInfo->HS[i].Center);
        printf("    Offset : %+f\n", calInfo->HS[i].Offset);
    }

    for (i=0; i<4; i++) {
        printf("  HR[%d]:\n", i);
        printf("    PSlope : %+.10f\n", calInfo->HR[i].PSlope);
        printf("    NSlope : %+.10f\n", calInfo->HR[i].NSlope);
        printf("    Center : %+f\n", calInfo->HR[i].Center);
        printf("    Offset : %+f\n", calInfo->HR[i].Offset);
    }

    for (i=0; i<2; i++) {
        printf("  DAC[%d]:\n", i);
        printf("    Slope  : %+f\n", calInfo->DAC[i].Slope);
        printf("    Offset : %+f\n", calInfo->DAC[i].Offset);
    }

    printf("  Temp:\n");
    printf("    Temp_Slope  : %+f\n", calInfo->Temp_Slope);
    printf("    Temp_Offset : %+f\n", calInfo->Temp_Offset);

    printf("  ISource:\n");
    printf("    ISource_10u  : %+.10f\n", calInfo->ISource_10u);
    printf("    ISource_200u : %+.10f\n", calInfo->ISource_200u);

    printf("  I_Bias : %+.10f\n", calInfo->I_Bias);
#endif

    return err;
}

/*
 * Current sources
 *   @see https://labjack.com/support/datasheets/t-series/200ua-and-10ua
 *
 * The T7 has 2 fixed current source terminals useful for measuring resistance (thermistors, RTDs, resistors).
 * The factory value of each current source is noted during calibration and stored with the calibration constants on the device.
 *
 * CURRENT_SOURCE_10UA_CAL_VALUE - Address: 1900
 * CURRENT_SOURCE_200UA_CAL_VALUE - Address: 1902
 *    Fixed current source value in Amps for the 10UA/200UA terminal.
 */
int getCurrentValues(int hDevice, double* Current10u, double* Current200u)
{
    int err = 0;
    int errorAddress = INITIAL_ERR_ADDRESS;

    // Set up for reading CS calibration
    enum { NUM_FRAMES = 2 };
    int ADDRESSES[NUM_FRAMES] = {1900, 1902};
    int TYPES[NUM_FRAMES] = {LJM_FLOAT32, LJM_FLOAT32};
    double aValues[NUM_FRAMES] = {0, 0};

    err = LJM_eReadAddresses(hDevice, NUM_FRAMES, ADDRESSES, TYPES, aValues,
            &errorAddress);
#ifdef LJM_CHECK
    ErrorCheckWithAddress(err, errorAddress, "LJM_eReadAddresses");
#endif

#ifdef LJM_DEBUG
    printf("\nCS  10uA calibration : %f\n", aValues[0]);
    printf("\nCS 200uA calibration : %f\n", aValues[1]);
#endif

    if( Current10u != NULL)
        *Current10u = aValues[0];
    if( Current200u != NULL)
        *Current200u = aValues[1];

    return err;
}


/**
 * Analog input (commonly referred to as AIN or AI).
 *   @see https://labjack.com/support/datasheets/t-series/ain
 *
 * The LabJack T7 has 14 built-in analog inputs, readable as AIN0-13:
 *   AIN0-AIN3 are available on the screw terminals and on the DB37 connector.
 *   AIN4-AIN13 are available only on the DB37 connector.
 * For command-response communication, analog input calibration is automatically applied by firmware and the AIN#
 * registers return calibrated voltages. The AIN#_BINARY registers will return binary values from the converter.
 *
 * AIN#(0:13) - Starting Address: 0
 *   Returns the voltage of the specified analog input.
 *   AIN14 is internally connected to an internal temperature sensor.
 *   AIN15 is internally connected to GND.  Useful for measuring noise or looking at offset error.
 *   AIN16-AIN47 are optional extended channels that can be created with custom analog input muxing circuitry.
 *   AIN48-AIN127 are extended channels that are available when using a Mux80.
 * AIN#(0:13)_RANGE - Starting Address: 40000
 *   Valid values/ranges: 0.0=Default => +/-10V; 10.0 => +/-10V, 1.0 => +/-1V, 0.1 => +/-0.1V, or 0.01 => +/-0.01V.
 * AIN#(0:13)_NEGATIVE_CH - Starting Address: 41000
 *   Specifies the negative channel to be used for each positive channel. 199=Default => Single-Ended.
 *   T7: For base differential channels, positive must be an even channel from 0-12 and negative must be positive+1.
 * AIN#(0:13)_RESOLUTION_INDEX - Starting Address: 41500
 *   The resolution index for command-response and AIN-EF readings.
 *   T7: Valid values:  0=Default => 8 or 9; 0-8 for T7, or 0-12 for T7-Pro.
 * AIN#(0:13)_SETTLING_US - Starting Address: 42000
 *   T7: 0 = Auto. Max is 50000 (microseconds).
 * AIN#(0:13)_BINARY - Starting Address: 50000
 *   Returns the 24-bit binary representation of the specified analog input.
 */
int readAIN(int hDevice, DeviceCalibrationT7* CalibrationInfo,
             int ChannelP, int ChannelN, double* Voltage, double* Temperature,
             double Range, long Resolution, double Settling, int Binary)
{
    if( CalibrationInfo == NULL )
    {
        printf("eAIN error: Invalid calibration information.\n");
        return 255;
    }

    //Checking if acceptable positive channel
    if( ChannelP < 0 || ChannelP > 143 )
    {
        printf("eAIN error: Invalid ChannelP value.\n");
        return 255;
    }

    //Checking if single ended or differential readin
    if( ChannelN < 0 || ChannelN == 15 )
    {
        //Single ended reading
        ChannelN = 199;  // Negative channel = single ended (199)
    }
    else if( (ChannelN&1) == 1 && ChannelN == ChannelP + 1 )
    {
        //Differential reading
    }
    else
    {
        printf("eAIN error: Invalid ChannelN value.\n");
        return 255;
    }

    if( Range < 0 || Range > 10)
    {
        printf("eAIN error: Invalid Range value\n");
        return 255;
    }

    if( Resolution < 0 || Resolution > 12 )
    {
        printf("eAIN error: Invalid Resolution value\n");
        return 255;
    }

    if( Settling < 0 && Settling > 50000 )
    {
        printf("eAIN error: Invalid Settling value\n");
        return 255;
    }

    int err = 0;
    int errorAddress = INITIAL_ERR_ADDRESS;

    // Set up for configuring the AINs
    enum { NUM_FRAMES_CONFIG = 4 };
    int ADRESSES_CONFIG[NUM_FRAMES_CONFIG] = {41000 + ChannelP,       // AIN#_NEGATIVE_CH: 41000, 41001, ...
                                              41500 + ChannelP,       // AIN#_RESOLUTION_INDEX: 41500, 41501, ...
                                              40000 + ChannelP * 2,   // AIN#_RANGE: 40000, 40002, ...
                                              42000 + ChannelP * 2};  // AIN#_SETTLING_US: 42000, 42002, ...
    int TYPES_CONFIG[NUM_FRAMES_CONFIG] = {LJM_UINT16, LJM_UINT16, LJM_FLOAT32, LJM_FLOAT32};
    double aValuesConfig[NUM_FRAMES_CONFIG] = {ChannelN, Resolution, Range, Settling};

    err = LJM_eWriteAddresses(hDevice, NUM_FRAMES_CONFIG, ADRESSES_CONFIG, TYPES_CONFIG, aValuesConfig,
            &errorAddress);
#ifdef LJM_CHECK
    ErrorCheckWithAddress(err, errorAddress, "LJM_eWriteAddresses");
#endif

#ifdef LJM_DEBUG
    printf("\nAIN#%d configuration:\n", ChannelP);
    printf("    NEGATIVE_CH      : %f\n", aValuesConfig[0]);
    printf("    RESOLUTION_INDEX : %f\n", aValuesConfig[1]);
    printf("    RANGE            : %f\n", aValuesConfig[2]);
    printf("    SETTLING_US      : %f\n", aValuesConfig[3]);
#endif

    // Set up for reading AIN state
    int ADDRESS, TYPE;
    if( Binary == 0 ) {
        ADDRESS = 0 + ChannelP * 2; // AIN#: 0, 2, ...
        TYPE = LJM_FLOAT32;
    }
    else {
        ADDRESS = 50000 + ChannelP * 2; // AIN#_BINARY: 50000, 50002, ...
        TYPE = LJM_UINT32;
    }
    double value = 0;
    double tempK = 0;

    err = LJM_eReadAddress(hDevice, ADDRESS, TYPE, &value);
#ifdef LJM_CHECK
    ErrorCheck(err, "LJM_eReadAddress");
#endif

#ifdef LJM_DEBUG
    printf("\nAIN#%d state : %f\n", ChannelP, value);
#endif

    if( Voltage != NULL )
        *Voltage = value;

    if( ChannelP == 14 ) {
        tempK = value * -92.6 + 467.6;  // Device temperature K
#ifdef LJM_DEBUG
        printf("\nAIN#%d temperature : %f K\n", ChannelP, tempK);
#endif
        if( Temperature != NULL )
            *Temperature = tempK;
    }

    return err;
}

/**
 * Analog outputs (commonly referred to as DAC)
 *   @see https://labjack.com/support/datasheets/t-series/dac
 *
 * There are two DACs (digital-to-analog converters, also known as analog outputs) on T-series devices.
 * Each DAC can be set to a voltage between about 0 and 5 volts with 12 bits of resolution (T7).
 *
 * DAC#(0:1) - Starting Address: 51000
 *   Writes binary values to the DACs. 0 = lowest output, 65535 = highest output.
 */
int writeDAC(int hDevice, DeviceCalibrationT7* CalibrationInfo,
              int Channel, unsigned Voltage)
{
    if( CalibrationInfo == NULL )
    {
        printf("eDAC error: Invalid calibration information.\n");
        return 255;
    }

    if( Channel < 0 || Channel > 1 )
    {
        printf("eDAC error: Invalid Channel.\n");
        return 255;
    }

    int err = 0;

    // Set up for reading DIO state
    int ADDRESS = 51000 + Channel * 2; // DAC#: 51000, 51002
    int TYPE = LJM_UINT32;
    uint32_t value = Voltage;

    err = LJM_eWriteAddress(hDevice, ADDRESS, TYPE, value);
#ifdef LJM_CHECK
    ErrorCheck(err, "LJM_eWriteAddress");
#endif

#ifdef LJM_DEBUG
    printf("\nDAC#%d state : %u\n", Channel, value);
#endif

    return err;
}

/**
 * Digital inputs
 *   @see https://labjack.com/support/datasheets/t-series/digital-io
 *
 * An digital I/O is an digital input or output. DIO is a generic name used for all digital I/O.
 * The LabJack T7 has 23 built-in digital input/output lines. They can be written/read as registers named DIO0-DIO22.
 *
 * DIO#(0:22) - Starting Address: 2000
 *    Read or set the state of 1 bit of digital I/O.
 */
int readDI(int hDevice, int Channel, long* State)
{
    if( Channel < 0 || Channel > 22 )
    {
        printf("eDI error: Invalid Channel.\n");
        return 255;
    }

    int err = 0;

    // Set up for reading DIO state
    int ADDRESS = 2000 + Channel; // DIO#: 2000, 2001, ...
    int TYPE = LJM_UINT16;
    double value = 0;

    err = LJM_eReadAddress(hDevice, ADDRESS, TYPE, &value);
#ifdef LJM_CHECK
    ErrorCheck(err, "LJM_eReadAddress");
#endif

#ifdef LJM_DEBUG
    printf("\nDIO#%d state : %f\n", Channel, value);
#endif

    if( State != NULL )
        *State = (long)value;

    return err;
}

/*
 * Digital outputs
 *   @see https://labjack.com/support/datasheets/t-series/digital-io
 *
 * An digital I/O is an digital input or output. DIO is a generic name used for all digital I/O.
 * The LabJack T7 has 23 built-in digital input/output lines. They can be written/read as registers named DIO0-DIO22.
 *
 * DIO#(0:22) - Starting Address: 2000
 *    Read or set the state of 1 bit of digital I/O.
 */
int writeDO(int hDevice, int Channel, long State)
{
    if( Channel < 0 || Channel > 22 )
    {
        printf("eDI error: Invalid Channel.\n");
        return 255;
    }

    int err = 0;

    // Set up for reading DIO state
    int ADDRESS = 2000 + Channel; // DIO#: 2000, 2001, ...
    int TYPE = LJM_UINT16;
    double value = (double)State;

    err = LJM_eWriteAddress(hDevice, ADDRESS, TYPE, value);
#ifdef LJM_CHECK
    ErrorCheck(err, "LJM_eWriteAddress");
#endif

#ifdef LJM_DEBUG
    printf("\nDIO#%d state : %f\n", Channel, value);
#endif

    return err;
}

/**
 * RTC (real-time clock)
 *  @see https://labjack.com/support/datasheets/t-series/rtc
 *
 * The T7-Pro has a battery-backed RTC (real-time clock).
 * The system time is stored in seconds since 1970, also known as the Epoch and Unix timestamp.
 *
 * RTC_TIME_S - Address 61500
 *   Read the current time in seconds since Jan, 1970, aka Epoch or Unix time.
 */
int readRtc(int hDevice, unsigned* Seconds)
{
    int err = 0;

    // Set up for reading RTC
    int ADDRESS = 61500;
    int TYPE = LJM_UINT32;
    double value = 0;

    err = LJM_eReadAddress(hDevice, ADDRESS, TYPE, &value);
#ifdef LJM_CHECK
    ErrorCheck(err, "LJM_eReadAddress");
#endif

#ifdef LJM_DEBUG
    printf("\nRTC state : %f\n", value);
#endif

    if( Seconds != NULL )
        *Seconds = (unsigned)value;

    return err;
}


/**
 * Clock sources
 *  @see https://labjack.com/support/datasheets/t-series/digital-io/extended-features/ef-clock-source
 *
 * Clock source settings produce the reference frequencies used to generate output waveforms and measure input waveforms.
 * There are 3 DIO-EF clock sources available. Each clock source has an associated bit size and several mutual exclusions.
 *     CLOCK0: 32-bit. Mutual Exclusions: CLOCK1, CLOCK2, COUNTER_A (CIO0), COUNTER_B(CIO1)
 *     CLOCK1: 16-bit. Mutual Exclusions: CLOCK0, COUNTER_A (CIO0)
 *     CLOCK2: 16-bit. Mutual Exclusions: CLOCK0, COUNTER_B (CIO1)
 *
 */
int setupClock(int hDevice, int Clock, int Enable,
                long Divisor, long RollValue, int External)
{
    if( Clock < 0 || Clock > 3 )
    {
        printf("setupClock error: Invalid Clock channel.\n");
        return 255;
    }

    if( Divisor < 0 || Divisor > 256)
    {
        printf("setupClock error: Invalid Divisor value\n");
        return 255;
    }

    if( RollValue < 0 )
    {
        printf("setupClock error: Invalid Roll value\n");
        return 255;
    }

    if( External < 0 || External > 1)
    {
        printf("setupClock error: Invalid External value\n");
        return 255;
    }

    int err = 0;
    int errorAddress = INITIAL_ERR_ADDRESS;

    // Enable or disable shared clock sources / counters, if necessary
    if( Clock == 0 ) {
        enum { NUM_FRAMES_CLOCKS = 4 };
        int ADRESSES_CLOCKS[NUM_FRAMES_CLOCKS]= {44910, 44920,   // CL1 enable: 44910, CL2 enable: 44920
                                                 44032, 44034};  // CIO0 enable: 44032, CIO1 enable: 44034
        int TYPES_CLOCKS[NUM_FRAMES_CLOCKS] = {LJM_UINT16, LJM_UINT16, LJM_UINT32, LJM_UINT32};
        double aClocksEnable[NUM_FRAMES_CLOCKS] = {0, 0, 0, 0};

        err = LJM_eWriteAddresses(hDevice, NUM_FRAMES_CLOCKS, ADRESSES_CLOCKS, TYPES_CLOCKS, aClocksEnable,
                &errorAddress);
#ifdef LJM_CHECK
        ErrorCheckWithAddress(err, errorAddress, "LJM_eWriteAddresses");
#endif

#ifdef LJM_DEBUG
        printf("\nCL#1+2 disabled : %.0f %.0f\n", aClocksEnable[0], aClocksEnable[1]);
        printf("\nCIO#0+1 disabled : %.0f %.0f\n", aClocksEnable[2], aClocksEnable[3]);
#endif
    }
    else if( Clock == 1 || Clock == 2 ) {
        int cio2 = Clock - 1;
        enum { NUM_FRAMES_CLOCKS = 2 };
        int ADRESSES_CLOCKS[NUM_FRAMES_CLOCKS]= {44900,  // CL0 enable: 44900
                                                 44032 + cio2 * 2 };  // CIO0 enable: 44032, CIO1 enable: 44034
        int TYPES_CLOCKS[NUM_FRAMES_CLOCKS] = {LJM_UINT16, LJM_UINT32};
        double aClocksEnable[NUM_FRAMES_CLOCKS] = {0, 0};

        err = LJM_eWriteAddresses(hDevice, NUM_FRAMES_CLOCKS, ADRESSES_CLOCKS, TYPES_CLOCKS, aClocksEnable,
                &errorAddress);
#ifdef LJM_CHECK
        ErrorCheckWithAddress(err, errorAddress, "LJM_eWriteAddresses");
#endif

#ifdef LJM_DEBUG
        printf("\nCL#0 disabled : %.0f\n", aClocksEnable[0]);
        printf("\nCIO#%d disabled : %.0f\n", cio2, aClocksEnable[1]);
#endif
    }

    // Set up for configuring the clock
    enum { NUM_FRAMES_CONFIG = 5 };
    int ADRESSES_CONFIG[NUM_FRAMES_CONFIG]= {44900 + Clock * 10,   // CL# enable:   44900, 44910, 44920
                                             44901 + Clock * 10,   // CL# divisor:  44901, 44911, 44921
                                             44902 + Clock * 10,   // CL# options:  44902, 44912, 44922
                                             44904 + Clock * 10,   // CL# roll_val: 44904, 44914, 44924
                                             44900 + Clock * 10};  // CL# enable:   44900, 44910, 44920
    int TYPES_CONFIG[NUM_FRAMES_CONFIG] = {LJM_UINT16, LJM_UINT16, LJM_UINT32, LJM_UINT32, LJM_UINT16};
    double aValuesConfig[NUM_FRAMES_CONFIG] = {0, Divisor, External, RollValue, Enable};

    err = LJM_eWriteAddresses(hDevice, NUM_FRAMES_CONFIG, ADRESSES_CONFIG, TYPES_CONFIG, aValuesConfig,
            &errorAddress);
#ifdef LJM_CHECK
    ErrorCheckWithAddress(err, errorAddress, "LJM_eWriteAddresses");
#endif

#ifdef LJM_DEBUG
    printf("\nCL#%d configuration:\n", Clock);
    printf("    ENABLED    : %.0f\n", aValuesConfig[4]);
    printf("    DIVISOR    : %f\n", aValuesConfig[1]);
    printf("    OPTIONS    : %f\n", aValuesConfig[2]);
    printf("    ROLL_VALUE : %f\n", aValuesConfig[3]);
#endif

    return err;
}

int readClock(int hDevice, int Clock, long* Count)
{
    if( Clock < 0 || Clock > 3 )
    {
        printf("readClock error: Invalid Clock channel.\n");
        return 255;
    }

    int err = 0;

    int ADDRESS = 44908 + Clock * 10;  // CL# count: 44908, 44918, 44928
    int TYPE = LJM_UINT32;
    double value = 0;

    err = LJM_eReadAddress(hDevice, ADDRESS, TYPE, &value);
#ifdef LJM_CHECK
    ErrorCheck(err, "LJM_eReadAddress");
#endif

#ifdef LJM_DEBUG
    printf("\nCL#%d count : %f\n", Clock, value);
#endif

    if( Count != NULL )
        *Count = (long)value;

    return err;
}

int setupPwm(int hDevice, int Channel, int Enable,
             int Clock, long RollValue)
{
    if( Channel < 0 || Channel == 1 || Channel > 5 )
    {
        printf("setupPwm error: Invalid Channel.\n");
        return 255;
    }

    if( Clock < 0 || Clock > 3 )
    {
        printf("setupPwm error: Invalid Clock channel.\n");
        return 255;
    }

    int err = 0;
    int errorAddress = INITIAL_ERR_ADDRESS;

    // Set up for configuring the pwm source
    enum { NUM_FRAMES_CONFIG = 5 };
    int ADRESSES_CONFIG[NUM_FRAMES_CONFIG]= {44000 + Channel * 2,   // DIO# enable:  44000, 44002, ...
                                             44100 + Channel * 2,   // DIO# index:  44100, 44102, ...
                                             44200 + Channel * 2,   // DIO# options:  44200, 44202, ...
                                             44300 + Channel * 2,   // DIO# config A:  44300, 44302, ...
                                             44100 + Channel * 2};  // DIO# enable:  44000, 44002, ...
    int TYPES_CONFIG[NUM_FRAMES_CONFIG] = {LJM_UINT32, LJM_UINT32, LJM_UINT32, LJM_UINT32, LJM_UINT32};
    double aValuesConfig[NUM_FRAMES_CONFIG] = {0, 0, Clock, RollValue, Enable};

    err = LJM_eWriteAddresses(hDevice, NUM_FRAMES_CONFIG, ADRESSES_CONFIG, TYPES_CONFIG, aValuesConfig,
                              &errorAddress);
#ifdef LJM_CHECK
    ErrorCheckWithAddress(err, errorAddress, "LJM_eWriteAddresses");
#endif

#ifdef LJM_DEBUG
    printf("\nDIO#%d PWM configuration:\n", Channel);
    printf("    ENABLED    : %.0f\n", aValuesConfig[4]);
    printf("    CLOCK_SRC  : %f\n", aValuesConfig[2]);
    printf("    ROLL_VALUE : %f\n", aValuesConfig[3]);
#endif

    return err;
}

/*
 * High-Speed counters
 *   @see https://labjack.com/support/datasheets/t-series/digital-io/extended-features/high-speed-counter
 *
 * T-series devices support up to 4 high-speed rising-edge counters that use hardware to achieve high count rates.
 * These counters are shared with other resources as follows:
 *     CounterA (DIO16/CIO0): Used by EF Clock0 & Clock1.
 *     CounterB (DIO17/CIO1): Used by EF Clock0 & Clock2.
 *     CounterC (DIO18/CIO2): Always available.
 *     CounterD (DIO19/CIO3): Used by stream mode.
 *
 * DIO#_EF_READ_A - Starting Address: 3000
 *     Returns the current count which is incremented on each rising edge.
 * DIO#_EF_READ_A_AND_RESET - Starting Address: 3100
 *     Reads the same value as DIO#_EF_READ_A and forces a reset.
 * DIO#_EF_ENABLE - Starting Address: 44000
 *     1 = enabled. 0 = disabled. Must be disabled during configuration.
 * DIO#_EF_INDEX - Starting Address: 44100
 */
int enableCounter(int hDevice, int Channel)
{
    if( Channel < 0 || Channel > 3 )
    {
        printf("enableCounter error: Invalid Channel.\n");
        return 255;
    }

    int err = 0;
    int errorAddress = INITIAL_ERR_ADDRESS;

    // Disable shared clock sources, if necessary
    if( Channel == 0 || Channel == 1 ) {
        int clock = Channel + 1;  // CIO0 shares CL1, CIO1 shares CL2
        enum { NUM_FRAMES_CLOCKS = 2 };
        int ADRESSES_CLOCKS[NUM_FRAMES_CLOCKS]= {44900,   // CL0 enable: 44900
                                                 44900 + clock * 10};   // CL1 enable: 44910, CL2 enable: 44920
        int TYPES_CLOCKS[NUM_FRAMES_CLOCKS] = {LJM_UINT16, LJM_UINT16};
        double aClocksEnable[NUM_FRAMES_CLOCKS] = {0, 0};

        err = LJM_eWriteAddresses(hDevice, NUM_FRAMES_CLOCKS, ADRESSES_CLOCKS, TYPES_CLOCKS, aClocksEnable,
                &errorAddress);
#ifdef LJM_CHECK
        ErrorCheckWithAddress(err, errorAddress, "LJM_eWriteAddresses");
#endif

#ifdef LJM_DEBUG
        printf("\nCL#0+%d disabled : %.0f %.0f\n", clock, aClocksEnable[0], aClocksEnable[1]);
#endif
    }

    // Set up for configuring the counter
    int ch = Channel + 16;  // CIO#0=DIO#16, ...
    enum { NUM_FRAMES_CONFIG = 3 };
    int ADRESSES_CONFIG[NUM_FRAMES_CONFIG]= {44000 + ch * 2,   // CIO# enable: 44032, 44034, ...
                                             44100 + ch * 2,   // CIO# index:  44132, 44134, ...
                                             44000 + ch * 2};  // CIO# enable: 44032, 44034, ...
    int TYPES_CONFIG[NUM_FRAMES_CONFIG] = {LJM_UINT32, LJM_UINT32, LJM_UINT32};
    double aValuesConfig[NUM_FRAMES_CONFIG] = {0, 7, 1};  // enable=0, index=7, enable=1

    err = LJM_eWriteAddresses(hDevice, NUM_FRAMES_CONFIG, ADRESSES_CONFIG, TYPES_CONFIG, aValuesConfig,
            &errorAddress);
#ifdef LJM_CHECK
    ErrorCheckWithAddress(err, errorAddress, "LJM_eWriteAddresses");
#endif

#ifdef LJM_DEBUG
    printf("\nCIO#%d configuration:\n", Channel);
    printf("    INDEX   : %f\n", aValuesConfig[1]);
    printf("    ENABLED : %f\n", aValuesConfig[2]);
#endif

    return err;
}

int disableCounter(int hDevice, int Channel)
{
    if( Channel < 0 || Channel > 4 )
    {
        printf("disableCounter error: Invalid Channel.\n");
        return 255;
    }

    int err = 0;
    int errorAddress = INITIAL_ERR_ADDRESS;

    // Set up for configuring the counter
    int ch = Channel + 16;  // CIO#0=DIO#16, ...
    enum { NUM_FRAMES_CONFIG = 1 };
    int ADRESSES_CONFIG[NUM_FRAMES_CONFIG]= {44000 + ch * 2};  // CIO#: 44032, 44034, ...
    int TYPES_CONFIG[NUM_FRAMES_CONFIG] = {LJM_UINT32};
    double aValuesConfig[NUM_FRAMES_CONFIG] = {0};  // enable=0

    err = LJM_eWriteAddresses(hDevice, NUM_FRAMES_CONFIG, ADRESSES_CONFIG, TYPES_CONFIG, aValuesConfig,
            &errorAddress);
#ifdef LJM_CHECK
    ErrorCheckWithAddress(err, errorAddress, "LJM_eWriteAddresses");
#endif

#ifdef LJM_DEBUG
    printf("\nCIO#%d configuration:\n", Channel);
    printf("    ENABLED : %f\n", aValuesConfig[0]);
#endif

    return err;
}

int readCounter(int hDevice, int Channel, int Reset, long* Count)
{
    if( Channel < 0 || Channel > 4 )
    {
        printf("readCounter error: Invalid Channel.\n");
        return 255;
    }

    int err = 0;

    // Set up for reading (and resetting) the counter
    int ch = Channel + 16;  // CIO#0=DIO#16, ...
    int ADDRESS = 3000 + ch * 2;  // CIO#: 3032, 3034, ...
    if( Reset != 0 )
        ADDRESS += 100;  // CIO#: 3132, 3134, ...
    int TYPE = LJM_UINT32;
    double value = 0;

    err = LJM_eReadAddress(hDevice, ADDRESS, TYPE, &value);
#ifdef LJM_CHECK
    ErrorCheck(err, "LJM_eReadAddress");
#endif

#ifdef LJM_DEBUG
    printf("\nCIO#%d state : %f\n", Channel, value);
#endif

    if( Count != NULL )
        *Count = value;

    return 0;
}

/**
 * Frequency In
 *  @see https://labjack.com/support/datasheets/t-series/digital-io/extended-features/frequency
 *
 * Measure the period/frequency of a digital input signal by counting the number of clock source ticks between two edges.
 * CoreFrequency is always 80 MHz at this time.
 * Roll value for this feature would typically be left at the default of 0, which is the max value (2^32 for the 32-bit Clock0).
 *    Clock#Frequency = CoreFrequency / DIO_EF_CLOCK#_DIVISOR    //typically 80M/Divisor
 *    Period (s) = DIO#_EF_READ_A / Clock#Frequency
 *    Frequency (Hz) = Clock#Frequency / DIO#_EF_READ_A
 *    Resolution(s) = 1 / Clock#Frequency
 *    Max Period(s) = DIO_EF_CLOCK#_ROLL_VALUE / Clock#Frequency
 */
int enableFreqIn(int hDevice, int Channel, int Clock,
                  int EdgeIndex, int Continuous)
{
    if( Channel < 0 || Channel > 3 )
    {
        printf("enableFreqIn error: Invalid Channel.\n");
        return 255;
    }

    if( Clock < 0 || Clock > 2 )
    {
        printf("enableFreqIn error: Invalid Clock Channel.\n");
        return 255;
    }

    if( EdgeIndex < 3 || EdgeIndex > 4 )
    {
        printf("enableFreqIn error: Invalid EdgeIndex value.\n");
        return 255;
    }

    if( Continuous < 0 || Continuous > 1 )
    {
        printf("enableFreqIn error: Invalid Continuous value.\n");
        return 255;
    }

    int err;
    int errorAddress = INITIAL_ERR_ADDRESS;

    // Enable clock source - for other settings, see setupClock()
    int ADRESS_CLOCK = 44900 + (Clock * 10);  // CL0 enable: 44900, CL1 enable: 44910, CL2 enable: 44920
    int TYPE_CLOCK = {LJM_UINT16};

    err = LJM_eWriteAddress(hDevice, ADRESS_CLOCK, TYPE_CLOCK, 1);  // enable=1
#ifdef LJM_CHECK
    ErrorCheck(err, "LJM_eWriteAddress");
#endif

    // Set up for configuring the frequency counter
    int ch = Channel + 16;  // CIO#0=DIO#16, ...
    enum { NUM_FRAMES_CONFIG = 5 };
    int ADRESSES_CONFIG[NUM_FRAMES_CONFIG]= {44000 + ch * 2,   // CIO# enable:  44032, 44034, ...
                                             44100 + ch * 2,   // CIO# index:   44132, 44134, ...
                                             44200 + ch * 2,   // CIO# options: 44232, 44234, ...
                                             44300 + ch * 2,   // CIO# configA: 44332, 44334, ...
                                             44000 + ch * 2};  // CIO# enable:  44032, 44034, ...
    int TYPES_CONFIG[NUM_FRAMES_CONFIG] = {LJM_UINT32, LJM_UINT32, LJM_UINT32};
    double aValuesConfig[NUM_FRAMES_CONFIG] = {0, EdgeIndex, Clock, Continuous, 1};  // enable=0, index=3/4, clock=0/1/2, configA=0/1, enable=1

    err = LJM_eWriteAddresses(hDevice, NUM_FRAMES_CONFIG, ADRESSES_CONFIG, TYPES_CONFIG, aValuesConfig,
            &errorAddress);
#ifdef LJM_CHECK
    ErrorCheckWithAddress(err, errorAddress, "LJM_eWriteAddresses");
#endif

#ifdef LJM_DEBUG
    printf("\nCIO#%d freq-in configuration:\n", Channel);
    printf("    INDEX    : %f\n", aValuesConfig[1]);
    printf("    CLOCK    : %f\n", aValuesConfig[2]);
    printf("    CONFIG_A : %f\n", aValuesConfig[3]);
    printf("    ENABLED  : %f\n", aValuesConfig[4]);
#endif

    return err;
}

int readFreqIn(int hDevice, int Channel, double ClockFreq,
                double* Period, double* Frequency)
{
    if( Channel < 0 || Channel > 4 )
    {
        printf("readFreqIn error: Invalid Channel.\n");
        return 255;
    }

    if( ClockFreq <= 0 )
    {
        printf("readFreqIn error: Invalid ClockFreq value.\n");
        return 255;
    }

    int err = 0;

    // Set up for reading the frequency
    int ch = Channel + 16;  // CIO#0=DIO#16, ...
    int ADDRESS = 3000 + ch * 2;  // CIO#: 3032, 3034, ...
    int TYPE = LJM_UINT32;
    double value = 0;

    err = LJM_eReadAddress(hDevice, ADDRESS, TYPE, &value);
#ifdef LJM_CHECK
    ErrorCheck(err, "LJM_eReadAddress");
#endif

#ifdef LJM_DEBUG
    printf("\nCIO#%d freq-in state : %f\n", Channel, value);
#endif

    if( Period != NULL )
        *Period = value / ClockFreq;
    if( Frequency != NULL )
        *Frequency = ClockFreq / value;

    return err;
}
