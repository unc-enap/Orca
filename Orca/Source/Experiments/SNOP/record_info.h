#ifndef __RECORD_INFO_H
#define __RECORD_INFO_H

#include <stdint.h>

#define RECORD_VERSION 0

#pragma pack(1)

struct GenericRecordHeader {
    uint32_t RecordID;
    uint32_t RecordLength;
    uint32_t RecordVersion;
};

//   Master Trigger Card data 
typedef struct MTCReadoutData {
  //   word 0 
  uint32_t Bc10_1          :32;
  //   word 1 
  uint32_t Bc10_2          :21;
  uint32_t Bc50_1          :11;
  //   word 2 
  uint32_t Bc50_2          :32;
  //   word 3 
  uint32_t BcGT            :24; //   LSB 
  unsigned Nhit_100_Lo          :1;
  unsigned Nhit_100_Med         :1;
  unsigned Nhit_100_Hi          :1;
  unsigned Nhit_20              :1;
  unsigned Nhit_20_LB           :1;
  unsigned ESum_Lo              :1;
  unsigned ESum_Hi              :1;
  unsigned Owln                 :1; //   MSB 

  //   word 4 
  unsigned Owle_Lo              :1;
  unsigned Owle_Hi              :1;
  unsigned Pulse_GT             :1;
  unsigned Prescale             :1;
  unsigned Pedestal             :1;
  unsigned Pong                 :1;
  unsigned Sync                 :1;
  unsigned Ext_Async            :1;
  unsigned Hydrophone           :1;
  unsigned Ext_3                :1;
  unsigned Ext_4                :1;
  unsigned Ext_5                :1;
  unsigned Ext_6                :1;
  unsigned NCD_Shaper           :1;
  unsigned Ext_8                :1;
  unsigned Special_Raw          :1;
  unsigned NCD_Mux              :1;
  unsigned Soft_GT              :1;
  unsigned Miss_Trig            :1;
  unsigned Peak                 :10;
  unsigned Diff_1               :3;

  //  word 5 
  unsigned Diff_2               :7;
  unsigned Int                  :10;
  unsigned TestGT               :1;
  unsigned Test50               :1;
  unsigned Test10               :1;
  unsigned TestMem1             :1;
  unsigned TestMem2             :1;
  unsigned SynClr16             :1;
  unsigned SynClr16_wo_TC16     :1;
  unsigned SynClr24             :1;
  unsigned SynClr24_wo_TC24     :1;
  unsigned FIFOsNotAllEmpty     :1;
  unsigned FIFOsNotAllFull      :1;
  unsigned FIFOsAllFull         :1;
  unsigned Unused1              :1;
  unsigned Unused2              :1;
  unsigned Unused3              :1;

} aMTCReadoutData, *aMTCReadoutDataPtr;

struct RunRecord {
    uint32_t Date;
    uint32_t Time;
    uint32_t SubFile;
    uint32_t RunNumber;
    uint32_t CalibrationTrialNumber;
    uint32_t SourceMask;
    uint32_t RunMask;
    uint32_t GTCrateMask;
    uint32_t FirstGTID;
    uint32_t ValidGTID;
    uint32_t Spares[8];
};

struct TriggerInfo {
    uint32_t TriggerMask;      //  which triggers were set? 
    uint32_t n100lo;           // trigger Threshold settings
    uint32_t n100med;          // these are longs cuz Josh is a weenie.
    uint32_t n100hi;
    uint32_t n20;
    uint32_t n20lb;
    uint32_t esumlo;
    uint32_t esumhi;
    uint32_t owln;
    uint32_t owlelo;
    uint32_t owlehi;
    uint32_t n100_mask;        // MTCA+ relay masks
    uint32_t n20_mask;
    uint32_t esumlo_mask;
    uint32_t esumhi_mask;
    uint32_t owlelo_mask;
    uint32_t owlehi_mask;
    uint32_t owln_mask;
    uint32_t Spares[3];
    uint32_t PulserRate;       //  MTC local pulser 
    uint32_t ControlRegister;  //  MTC control register status 
    uint32_t LockoutWidth;     //  min. time btwn global triggers 
    uint32_t Prescale;         //  how many nhit_100_lo triggers to take 
    uint32_t GTID;             //  to keep track of where I am in the world
};

struct EPEDRecord {
    uint32_t pedestal_width;
    uint32_t pedestal_delay_coarse;
    uint32_t pedestal_delay_fine;
    uint32_t qinj_dacsetting;
    uint32_t half_crate_id;
    uint32_t calibration_type;
    uint32_t gtid;
    uint32_t flags;
};

struct MTCDStatus {
    uint32_t gtid;
    uint32_t clock10_0_31;
    uint32_t clock10_32_52;
    uint32_t read_ptr;
    uint32_t write_ptr;
};

struct FIFOLevels {
    uint32_t crate;
    uint32_t mem_level[16];
    uint32_t xl3_level;
};

struct CMOSLevels {
    uint32_t crate;
    uint32_t slotMask;
    uint32_t channelMasks[16];
    uint32_t errorFlags;
    uint32_t counts[8*32];
    uint32_t busyFlags[16];
};

struct BaseCurrentLevels {
    uint32_t crate;
    uint32_t slotMask;
    uint32_t channelMasks[16];
    uint32_t errorFlags;
    uint8_t pmtCurrent[16*32];
    uint8_t busyFlags[16*32];
};

struct TubiiRecord {
    uint32_t TrigWord;
    uint32_t GTID;
};

struct TubiiMegaRecord {
    uint32_t size;
    struct TubiiRecord array[1000];
};

struct TubiiStatus {
    uint32_t Clock;
    uint32_t GTID_out;
    uint32_t GTID_in;
    uint32_t FIFO;
};

enum RecordTypes {
    RHDR_RECORD    = 0x52484452,
    EPED_RECORD    = 0x45504544,
    CAEN_RECORD    = 0x4341454e,
    MTCD_RECORD    = 0x4d544344,
    MEGA_BUNDLE    = 0x4d454741,
    MTCD_STATUS    = 0x4d545354,
    TRIG_RECORD    = 0x54524947,
    FIFO_LEVELS    = 0x4649464f,
    CMOS_LEVELS    = 0x434d4f53,
    BASE_LEVELS    = 0x42415345,
    TUBI_RECORD    = 0x54554232,
    TUBI_STATUS    = 0x54554253,
    NHIT_RECORD    = 0x4e484954,
};

//   RunMask... 
/* mutually exclusive run types */
#define MAINTENANCE_RUN         0x1
#define TRANSITION_RUN          0x2
#define PHYSICS_RUN             0x4
#define DEPLOYED_SOURCE_RUN     0x8
#define EXTERNAL_SOURCE_RUN     0x10
#define ECA_RUN                 0x20
#define DIAGNOSTIC_RUN          0x40
#define EXPERIMENTAL_RUN        0x80
#define SUPERNOVA_RUN           0x100
/* calibration */
#define TELLIE_RUN              0x800
#define SMELLIE_RUN             0x1000
#define AMELLIE_RUN             0x2000
#define PCA_RUN                 0x4000
#define ECA_PDST_RUN            0x8000
#define ECA_TSLP_RUN            0x10000
/* detector state */
#define DCR_ACTIVITY_RUN        0x200000
#define COMP_COILS_OFF_RUN      0x400000
#define PMT_OFF_RUN             0x800000
#define BUBBLERS_RUN            0x1000000
#define RECIRCULATION_RUN       0x2000000
#define SLASSAY_RUN             0x4000000
#define UNUSUAL_ACTIVITY_RUN    0x8000000

//   Source... 
enum SourceType {
    NO_SRC,
    ROTATING_SRC,
    //SONO_SRC,
    N16_SRC,
    N17_SRC,
    NAI_SRC,
    //LI8_SRC,
    //PT_SRC,
    //CF_HI_SRC,
    //CF_LO_SRC,
    CF_SRC,
    U_SRC,
    TH_SRC,
    P_LI7_SRC,
    WATER_SAMPLER,
    PROP_COUNTER_SRC,
    //SINGLE_NCD_SRC,
    SELF_CALIB_SRC,
    Y88_SRC,
    /* SNO+ sources */
    AMBE_H20_SRC,
    AMBE_SRC,
    CO60_SRC,
    CO57_SRC,
    SC48_SRC,
    NA24_SRC,
    ZN65_SRC,
    RN_SRC,
    CHERENKOV_SRC,
    LASER_SRC,
    SUPERNOVA_SRC,
    TELLIE_SRC,
    AMELLIE_SRC,
    SMELLIE_SRC
};

#define kBuilderRecordType 0x424c4452
#define kBuilderEndRun     0x0000000a

/* Header record type used to send command to data server. */
#define kSCmd 0x53436d64
/* Header record type used to send reply back from data server. */
#define kSRsp 0x53527370

/* Header version used to send subscription to data server. */
#define kSub  0
/* Header version used to send ID string to data server. */
#define kId   0x4944

#pragma pack()

#endif
