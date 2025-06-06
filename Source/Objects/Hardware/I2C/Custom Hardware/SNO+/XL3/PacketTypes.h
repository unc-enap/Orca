#ifndef __XL3_TYPES
#define __XL3_TYPES

#include <stdint.h>
#include "DB.h"

#define XL3_PACKET_SIZE 1444

#define XL3_HEADER_SIZE 4
#define XL3_PAYLOAD_SIZE (XL3_PACKET_SIZE - XL3_HEADER_SIZE)

#define MB_HEADER_SIZE 12
#define MB_PAYLOAD_SIZE ((XL3_PAYLOAD_SIZE-MB_HEADER_SIZE)/4)

#define MAX_BUNDLES_PER_MINI 118
#define MAX_ACKS_PER_PACKET 80


/*! \name packetType
 *  Types of packets that will be received by the xl3 from the daq
 */
//@{
// ML403 Level Tasks
#define DAQ_QUIT_ID               (0x00) //!< disconnect from the daq
#define PONG_ID                   (0x01) //!< daq is alive
#define CHANGE_MODE_ID            (0x02) //!< change to INIT or NORMAL mode
#define STATE_MACHINE_RESET_ID    (0x03) //!< reset the state machine
#define DEBUGGING_MODE_ID         (0x04) //!< turn on verbose printout
#define CHECK_STATE_MACHINE_ID    (0x05) //!< Read the state machine status regs
#define CHECK_XL3_STATE_ID        (0x06) //!< Get the mode, slot mask, clock
// XL3/FEC Level Tasks
#define FAST_CMD_ID               (0x20) //!< do one command in recv callback, immediately respond with same packet (daq numbered)
#define MULTI_FAST_CMD_ID         (0x21) //!< do multiple commands in recv callback, immediately respond with same packet (daq numbered)
#define QUEUE_CMDS_ID             (0x22) //!< add multiple cmds to cmd_queue, done at xl3's liesure, respond in cmd_ack packets (xl3 numbered)
#define CRATE_INIT_ID             (0x23) //!< one of the 17 packets containing the crate settings info from the database 
#define FEC_LOAD_CRATE_ADD_ID     (0x24) //!< load crate address into FEC general csr
#define SET_CRATE_PEDESTALS_ID    (0x25) //!< Sets the pedestal enables on all connected fecs either on or off
#define BUILD_CRATE_CONFIG_ID     (0x26) //!< Updates the xl3's knowledge of the mb id's and db id's
#define LOADSDAC_ID               (0x27) //!< Load a single fec dac
#define MULTI_LOADSDAC_ID         (0x28) //!< Load multiple dacs
#define DESELECT_FECS_ID          (0x29) //!< deselect all fecs in vhdl
#define READ_PEDESTALS_ID         (0x2A) //!< queue any number of memory reads into cmd queue
#define LOAD_TACBITS_ID           (0x2B) //!< loads tac bits on fecs
#define RESET_FIFOS_ID            (0x2C) //!< resets all the fec fifos
#define READ_LOCAL_VOLTAGE_ID		  (0x2D) //!< read a single voltage on XL3 
#define CHECK_TOTAL_COUNT_ID	    (0x2E) //!< readout cmos total count register	
#define SET_ALARM_DAC_ID          (0x2F) //!< Set one or many of the voltage alarm dacs
#define SET_ALARM_LEVELS_ID       (0x30) //!< Set one or many of the voltage alarm dacs
#define MULTI_SET_CRATE_PEDS_ID   (0x31) //!< Unlike set_crate_pedestals_id, allows different mask per slot, and doesn't change slots not in the mask
#define BOARD_ID_WRITE_ID         (0x32)
#define SET_SEQUENCER_ID          (0x33) //!< Set the sequencer
/* RESET_CRATE_ID resets the crate, loads XL3 clocks and dacs, tries to load
 * Xilinx in all the FEC slots, and loads the default values for the FEC dacs,
 * shift registers, and sequencers (not HV or data safe). It then returns a list
 * of which slots are present and the IDs of all MBs, DBs, and PMTICs. So you
 * would first run RESET_CRATE_ID and then you would do a CRATE_INIT without
 * Xilinx to load the non-default values into the FEC. */
#define RESET_CRATE_ID            (0x34) 
/* Set the sequencer mask for multiple slots at a time. */
#define MULTI_SET_CRATE_SEQUENCERS_ID (0x35)
/* Set the trigger mask for multiple slots at a time. */
#define MULTI_SET_CRATE_TRIGGERS_ID   (0x36)
// HV Tasks
#define SET_HV_RELAYS_ID          (0x40) //!< turns on/off hv relays
#define GET_HV_RELAYS_ID          (0x41) //!< returns the stored relay values
#define HV_READBACK_ID			      (0x42) //!< reads voltage and current	
#define READ_PMT_CURRENT_ID	      (0x43) //!< reads pmt current from FEC hv csr	
#define SETUP_CHARGE_INJ_ID		    (0x44) //!< setup charge injection in FEC hv csr
#define MULTI_SETUP_CHARGE_INJ_ID (0x45) //!< setup charge injection for multiple fecs and set dac level
#define DO_PANIC_DOWN             (0x46) //!< Ramps crate HV to zero
// Tests
#define FEC_TEST_ID               (0x60) //!< check read/write to FEC registers
#define MEM_TEST_ID               (0x61) //!< check read/write to FEC ram, address lines
#define VMON_ID                   (0x62) //!< reads FEC voltages
#define BOARD_ID_READ_ID          (0x63) //!< reads id of fec,dbs,hvc
#define ZDISC_ID                  (0x64) //!< zeroes discriminators
#define CALD_TEST_ID              (0x65) //!< checks adcs with calibration dac
#define CRATE_NOISE_RATE_ID       (0x66) //!< check the noise rate in a slot			
#define LOCAL_VMON_ID             (0x68)
//@}


#define CALD_RESPONSE_ID 0xAA
#define PING_ID 0xBB
#define MEGA_BUNDLE_ID 0xCC
#define CMD_ACK_ID 0xDD
#define TEST_ACK_ID 0xDE
#define MESSAGE_ID 0xEE
#define ERROR_ID 0xFE
#define SCREWED_ID 0xFF

#pragma pack(1)

typedef struct
{
  uint16_t packetNum;
  uint8_t packetType;
  uint8_t numBundles;
} XL3CommandHeader;

typedef struct
{
  XL3CommandHeader header;
  char payload[XL3_PAYLOAD_SIZE];
} XL3Packet;

typedef struct
{
  uint32_t info; // bits 0-23: number of 32 bit words in mb payload, bits 24-28: crate num, bits 29-31:0
  uint32_t passMin;
  uint32_t xl3Clock;
} MegaBundleHeader;

typedef struct
{
  uint32_t info; // bits 0-23: number of 32 bit words in mini payload, bits 24-27: card number, bits 28-30: 0, bit 31 = 0 if normal minibundle, 1 if passcur minibundle
} MiniBundleHeader;

typedef struct
{
  uint32_t cmdNum;
  uint16_t packetNum;
  uint16_t flags;
  uint32_t address;
  uint32_t data;
} Command;

typedef struct
{
	uint32_t howMany;
	Command cmd[MAX_ACKS_PER_PACKET];
} MultiCommand; //!< many register reads or writes


typedef struct
{
  uint32_t word1;
  uint32_t word2;
  uint32_t word3;
} PMTBundle;

typedef struct
{
  uint32_t fecMemLevel[16];
  uint32_t mbqLevel;
} PingPacket;

typedef struct
{
  uint32_t cmdRejected;
  uint32_t transferError;
  uint32_t xl3DataAvailUnknown;
  uint32_t fecBundleReadError[16];
  uint32_t fecBundleResyncError[16];
  uint32_t fecMemLevelUnknown[16];
} ErrorPacket;

typedef struct
{
  uint32_t fecScrewed[16];
} ScrewedPacket;

typedef struct{
  uint16_t slot;
  uint16_t point[100];
  uint16_t adc0[100];
  uint16_t adc1[100];
  uint16_t adc2[100];
  uint16_t adc3[100];
} CaldResponsePacket;

// recieve types

typedef struct{
  uint32_t mode;
  uint32_t dataAvailMask;
} ChangeModeArgs;

typedef struct{
  uint32_t errorFlags;
} ChangeModeResults;

typedef struct{
  uint32_t errorFlags;
} StateMachineResetResults;

typedef struct{
  uint32_t mode;
} DebuggingModeArgs;

typedef struct{
  uint32_t cState;
  uint32_t nState;
} CheckStateMachineResults;

typedef struct{
  Command command;
} FastCmdArgs;

typedef struct{
  Command command;
} FastCmdResults;

typedef struct{
  MultiCommand commands;
} MultiFastCmdArgs;

typedef struct{
  MultiCommand commands;
} MultiFastCmdResults;

typedef struct{
  MultiCommand commands;
} QueueCmdsArgs;

typedef struct{
  uint32_t errorFlags;
} QueueCmdsResults;

typedef struct{
  uint32_t mbNum;
  MB settings;
} CrateInitSetupArgs;

typedef struct{
  uint32_t mbNum;
  uint32_t slotMask;
  uint32_t ctcDelay;
} CrateInitArgs;

typedef struct{
  uint32_t errorFlags;
  uint32_t fecPresent; // each bit is 1 if that slot as a FEC, 0 if not
  FECConfiguration hwareVals[16];
} CrateInitResults;

typedef struct{
  uint32_t slotMask;
  uint32_t crateNum;
} FECLoadCrateAddArgs;

typedef struct{
  uint32_t errorFlags;
} FECLoadCrateAddResults;

typedef struct{
  uint32_t slotMask;
  uint32_t pattern;
} SetCratePedestalsArgs;

typedef struct{
  uint32_t errorMask;
} SetCratePedestalsResults;

typedef struct{
  uint32_t slotMask;
} BuildCrateConfigArgs;

typedef struct{
  uint32_t errorFlags;
  uint32_t fecPresent; // each bit is 1 if that slot as a FEC, 0 if not
  FECConfiguration hwareVals[16];
} BuildCrateConfigResults;

typedef struct{
  uint32_t slotNum;
  uint32_t dacNum;
  uint32_t dacValue;
} LoadsDacArgs;

typedef struct{
  uint32_t errorFlags;
} LoadsDacResults;

typedef struct{
  uint32_t numDacs;
  LoadsDacArgs dacs[50];
} MultiLoadsDacArgs;

typedef struct{
  uint32_t errorFlags;
} MultiLoadsDacResults;

typedef struct{
  uint32_t slot;
  uint32_t reads;
} ReadPedestalsArgs;

typedef struct{
  uint32_t readsQueued;
} ReadPedestalsResults;

typedef struct{
  uint32_t crateNum;
  uint32_t selectReg;
  uint16_t tacBits[32];
} LoadTacBitsArgs;

typedef struct{
  uint32_t errorFlags;
} LoadTacBitsResults;

typedef struct{
  uint32_t slotMask;
} ResetFifosArgs;

typedef struct{
  uint32_t errorFlags;
} ResetFifosResults;

typedef struct{
  uint32_t voltageSelect;
} ReadLocalVoltageArgs;

typedef struct{
  uint32_t errorFlags;
  float voltage;
} ReadLocalVoltageResults;

typedef struct{
  uint32_t slotMask;
  uint32_t channelMasks[32];
} CheckTotalCountArgs;

typedef struct{
  uint32_t errorFlags;
  uint32_t count[8*32];
  uint32_t busyFlags[16];
} CheckTotalCountResults;

typedef struct{
  uint32_t dacs[3];
} SetAlarmDacArgs;

typedef struct{
  float highLevels[6];
  float lowLevels[6];
} SetAlarmLevelsArgs;

typedef struct{
  uint32_t errorFlags;
} SetAlarmLevelsResults;

typedef struct{
  uint32_t mask1;
  uint32_t mask2;
} SetHVRelaysArgs;

typedef struct{
  uint32_t errorFlags;
} SetHVRelaysResults;

typedef struct{
  uint32_t mask1;
  uint32_t mask2;
  uint32_t relays_known;
} GetHVRelaysResults;

typedef struct{
  float voltageA;
  float voltageB;
  float currentA;
  float currentB;
  uint32_t errorFlags;
} HVReadbackResults;

typedef struct{
  uint32_t slotMask; 
  uint32_t channelMask[16];
} ReadPMTCurrentArgs;

typedef struct{
  uint32_t errorFlags;
  uint8_t pmtCurrent[16*32];
  uint8_t busyFlags[16*32];
} ReadPMTCurrentResults;

typedef struct{
  uint32_t slotNum;
  uint32_t channelMask;
} SetUpChargeInjArgs;

typedef struct{
  uint32_t errorFlags;
} SetUpChargeInjResults;

typedef struct{
    uint32_t errorFlags;
}DoPanicDownResults;

typedef struct{
  uint32_t slotMask;
} FECTestArgs;

typedef struct{
  uint32_t errorFlags;
  uint32_t discreteRegErrors[16]; 
  uint32_t cmosTestRegErrors[16];
} FECTestResults;

typedef struct{
  uint32_t slotNum;
} MemTestArgs;

typedef struct{
  uint32_t errorFlags;
  uint32_t addressBitFailures;
  uint32_t errorLocation;
  uint32_t expectedData;
  uint32_t readData;
} MemTestResults;

typedef struct{
  uint32_t slotNum;
} VMonArgs;

typedef struct{
  float voltages[21];
} VMonResults;

typedef struct{
  uint32_t slot;
  uint32_t chip;
  uint32_t reg;
} BoardIDReadArgs;

typedef struct{
  uint32_t id;
  uint32_t busErrors;
} BoardIDReadResults;

typedef struct{
  uint32_t id;
  uint32_t slot;
  uint32_t chip;
  uint32_t reg;
} BoardIDWriteArgs;

typedef struct{
  uint32_t busErrors;
} BoardIDWriteResults;

typedef struct {
  uint32_t xilFile; // 1 to load normal Xilinx, anything else to load charge injection xilinx
} ResetCrateArgs;

typedef struct {
  uint32_t errors;
  uint32_t fecPresent; // each bit is 1 if that slot as a FEC, 0 if not
  FECConfiguration hwareVals[16];
} ResetCrateResults;

typedef struct {
  uint32_t slotMask;
  uint32_t channelMasks[16];
} MultiSetCrateSequencersArgs;

typedef struct {
  uint32_t errorMask;
} MultiSetCrateSequencersResults;

typedef struct {
  uint32_t slotMask;
  uint32_t tr100Masks[16];
  uint32_t tr20Masks[16];
} MultiSetCrateTriggersArgs;

typedef struct {
  uint32_t errorMask;
} MultiSetCrateTriggersResults;

typedef struct{
    uint32_t slot;
    uint32_t channelMask;
} SetSequencerArgs;

typedef struct{
    uint32_t errors;
} SetSequencerResults;

typedef struct{
  uint32_t slotNum;
  uint32_t offset;
  float rate;
} ZDiscArgs;

typedef struct{
  uint32_t errorFlags;
  float maxRate[32];
  float upperRate[32];
  float lowerRate[32];
  uint8_t maxDacSetting[32];
  uint8_t zeroDacSetting[32];
  uint8_t upperDacSetting[32];
  uint8_t lowerDacSetting[32];
} ZDiscResults;

typedef struct{
  uint32_t slotMask;
  uint32_t numPoints;
  uint32_t samples;
  uint32_t upper;
  uint32_t lower;
} CaldTestArgs;

typedef struct{
  uint32_t errorFlags;
} CaldTestResults;

typedef struct{
  uint32_t slotMask;
  uint32_t channelMask[16];
  uint32_t period;
} CrateNoiseRateArgs;

typedef struct{
  uint32_t errorFlags;
  float rates[8*32]; 
} CrateNoiseRateResults;

typedef struct{
  float voltages[8];
} LocalVMonResults;

typedef struct{
  uint32_t mode;
  uint32_t debuggingMode;
  uint32_t dataAvailMask;
  uint64_t xl3Clock; 
  uint32_t initialized;
} CheckXL3StateResults;

typedef struct{
  uint32_t slotMask;
	uint32_t channelMasks[16];
} MultiSetCratePedsArgs;

typedef struct{
  uint32_t errorMask;
} MultiSetCratePedsResults;

typedef struct{
  uint32_t slotMask;
  uint32_t channelMasks[16];
  uint32_t dacValues[16];
} MultiSetUpChargeInjArgs;

typedef struct{
  uint32_t errorFlags;
} MultiSetUpChargeInjResults;

#pragma pack()

#endif
