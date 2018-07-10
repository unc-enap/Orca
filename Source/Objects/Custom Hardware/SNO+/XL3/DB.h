#ifndef __DB
#define __DB

#include <stdint.h>

#pragma pack(1)

typedef struct
{
  uint16_t mbID;
  uint16_t dbID[4];
  uint16_t pmticID;
} FECConfiguration;

typedef struct {
  /* index definitions [0=ch0-3; 1=ch4-7; 2=ch8-11, etc] */
  uint8_t     rmp[8];    //!< back edge timing ramp    
  uint8_t     rmpup[8];  //!< front edge timing ramp    
  uint8_t     vsi[8];    //!< short integrate voltage     
  uint8_t     vli[8];    //!< long integrate voltage
} TDisc; //!< discriminator timing dacs

typedef struct {
  /* the folowing are motherboard wide constants */
  uint8_t     vMax;           //!< upper TAC reference voltage
  uint8_t     tacRef;         //!< lower TAC reference voltage
  uint8_t     isetm[2];       //!< primary   timing current [0= tac0; 1= tac1]
  uint8_t     iseta[2];       //!< secondary timing current [0= tac0; 1= tac1]
  /* there is one uint8_t of TAC bits for each channel */
  uint8_t     tacShift[32];  //!< TAC shift register load bits 
} TCmos; //!< cmos timing

/* CMOS shift register 100nsec trigger setup */
typedef struct {
  uint8_t      mask[32]; //!< 
  uint8_t      tDelay[32]; //!< tr100 width
} Tr100; //!< nhit 100 trigger

/* CMOS shift register 20nsec trigger setup */
typedef struct {
  uint8_t      mask[32]; //!<
  uint8_t      tWidth[32]; //!< tr20 width
  uint8_t      tDelay[32]; //!< tr20 delay
} Tr20; //!< nhit 20 trigger


typedef struct {
  uint16_t mbID; //!< 
  uint16_t dbID[4]; //!<
  uint8_t vBal[2][32]; //!<
  uint8_t vThr[32]; //!<
  TDisc tDisc; //!< 
  TCmos tCmos; //!<
  uint8_t vInt; //!< integrator output voltage 
  uint8_t hvRef; //!<  MB control voltage 
  Tr100 tr100; //!< 
  Tr20 tr20; //!< 
  uint16_t sCmos[32]; //!<
  uint32_t  disableMask; //!<
} MB; //!< all database values for one fec

typedef struct
{
  MB mb[16]; //!< all 16 fec database values
  uint16_t pmticID[16]; //!< All 16 PMTIC IDs. Not stored in MB for compatibility
  uint32_t ctcDelay; //!< ctc based trigger delay
  uint32_t relays_known; //!< stores if the relays have been set successfully
  uint32_t hv_relay1; //!< stores the (lower) relays
  uint32_t hv_relay2; //!< stores the (upper) relays
} Crate; //!< all database values for the crate

Crate crate; //!< Current configuration

#pragma pack()

#endif
