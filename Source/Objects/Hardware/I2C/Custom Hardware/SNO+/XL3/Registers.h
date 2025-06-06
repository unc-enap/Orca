/*! \file Registers.h
 *  \brief register map for xl3, fec, ctc
 */

#ifndef __REGISTERS
#define __REGISTERS

/////Register space////////////////////////////
///////////////////////////////////////////////
/*! \name XL3 registers */
//@{
#define RESET_REG (0x02000000)
#define DATA_AVAIL_REG (0x02000001)
#define XL3_CS_REG (0x02000002)
#define XL3_MASK_REG (0x02000003)
#define XL3_CLOCK_REG (0x02000004)
#define RELAY_REG (0x02000005)
#define XL3_XLCON_REG (0x02000006)
#define TEST_REG (0x02000007)
#define HV_CS_REG (0x02000008)
#define HV_SETPOINTS (0x02000009)
#define HV_VR_REG (0x0200000A)
#define HV_CR_REG (0x0200000B)
#define XL3_VM_REG (0x0200000C)
#define XL3_VR_REG (0x0200000E)
//@}

/*! \name FEC registers */
//@{
//Discrete
#define GENERAL_CSR (0x00000020)
#define ADC_VALUE_REG (0x00000021)
#define VOLTAGE_MONITOR (0x00000022)
#define PEDESTAL_ENABLE (0x00000023)
#define DAC_PROGRAM (0x00000024)
#define CALDAC_PROGRAM (0x00000025)
#define FEC_HV_CSR (0x00000026)
#define CMOS_PROG_LOW (0x0000002A)
#define CMOS_PROG_HIGH (0x0000002B)
#define CMOS_LGISEL (0x0000002C)
#define BOARD_ID_REG (0x0000002D)
//Sequencer
#define SEQ_OUT_CSR (0x00000080)
#define CMOS_CHIP_DISABLE (0x00000090)
#define FIFO_READ_PTR (0x0000009c)
#define FIFO_WRITE_PTR (0x0000009d)
#define FIFO_DIFF_PTR (0x0000009e)
//CMOS internal
#define CMOS_INTERN_TEST(num) (0x00000100 + 0x00000004 + 0x00000008*num)
#define CMOS_INTERN_TOTAL(num) (0x00000100 + 0x00000003 + 0x00000008*num)  
//@}

/*! \name CTC registers */
//@{
#define CTC_DELAY_REG (0x00000004)
//@}
/////////////////////////////////////////////////
/////////////////////////////////////////////////

// add to register value
#define READ_MEM (0x30000000)
#define READ_REG (0x10000000)
#define WRITE_MEM (0x20000000)
#define WRITE_REG (0x00000000)

#define FEC_SEL (0x00100000) // to select board #i, (0..15), use FEC_SEL * i
#define CTC_SEL (0x01000000)
#define XL3_SEL (0x02000000)


// XL3 CLOCK STUFF
#define MASTER_CLOCK_EN (0x00008000)
#define MEM_CLOCK_DATA (0x00000002)
#define MEM_CLOCK_CLK (0x00000001)
#define MEM_CLOCK_STROBE (0x00000008)
#define MEM_CLOCK_EN (0x00000004)
#define SEQ_CLOCK_DATA (0x00000040)
#define SEQ_CLOCK_CLK (0x00000020)
#define SEQ_CLOCK_STROBE (0x00000080)
#define SEQ_CLOCK_EN (0x00000100)
#define ADC_CLOCK_DATA (0x00000800)
#define ADC_CLOCK_CLK (0x00000400)
#define ADC_CLOCK_STROBE (0x00001000)
#define ADC_CLOCK_EN (0x00002000)

// HV READOUT STUFF
#define UNPK_ADC(a) ((a & 0x00000800) == 0x800 ? (a & 0x000007FF) : (a & 0x000007FF) + 2048)
#define GET_UPPER(a) (0xFFF & (a >> 16))
#define V_SLOPE (0.9299665)
#define V_INTERCEPT (-360.19)
#define I_SLOPE (-1.0)
#define I_INTERCEPT (0.0)

// XL3 VMON STUFF
#define XL3_VMON_CLK (0x00000001) 
#define XL3_VMON_LDAC (0x00000002) 
#define XL3_VMON_SYNC(num) (0x00000004 << num) 
#define XL3_VMON_D(num) (0x00000020 << num) 
#define XL3_VMON_DO(num) (0x00000001 << num) 
#define XL3_VMON_SEL_0 (0x00)
#define XL3_VMON_SEL_1 (0x80)
#define XL3_VMON_SEL_2 (0x40)
#define XL3_VMON_SEL_3 (0xC0)
#define XL3_VMON_SEL_ALL (0x20)

// RELAY STUFF
#define RLY_DATIN (0x2)
#define RLY_CLK (0x8)
#define RLY_LOAD (0x4)
#define RLY_DATOUT (0x1)

// FEC XILINX STUFF
// csr reg
#define XL_ACTIVE (0x00000001)
#define XL_CLOCK (0x00000002)
#define XL_DATA_IN (0x00000004)
#define XL_DONE_PROG (0x00000008)
//xlcon
#define XL_PERMIT (0x000000A0)
#define XL_FEC_DP_EN (0x00000008)
#define XL_FEC_DP_DIS (0x00000004)


// BOARD ID STUFF
#define BOARD_ID_CLOCK (0x00000001)
#define BOARD_ID_D_IN (0x00000080)
//#define BOARD_ID_PRE (0x00000100)
//#define BOARD_ID_PE (0x00000200)
#define BOARD_ID_D_OUT (0x00000400)
#define BOARD_ID_CMD_READ (0x180)
#define BOARD_ID_CMD_WRITE (0x140)
#define BOARD_ID_CMD_WRITE_ENABLE (0x130)
#define BOARD_ID_CMD_WRITE_DISABLE (0x100)
#define ID_REG (15)

//FEC VOLTAGE MONITOR STUFF
#define FEC_VMON_SEL_OFFSET (9)
#define FEC_VMON_CS (0x1 << 14) // 0x00004000
#define FEC_VMON_RD (0x1 << 15) // 0x00008000
#define VMON_BUSY_BIT (0x00000100)

//FEC HV STUFF
//#define HV_CSR_CLK	 (0x1)
//#define HV_CSR_DATIN  (0x2)
//#define HV_CSR_LOAD   (0x4)
//#define HV_CSR_DATOUT (0x8)

//FEC GENERAL CSR STUFF
#define FEC_CSR_CRATE_OFFSET (11)
#define GEN_CSR_TM2 (0x1 << 5)
#define GEN_CSR_CALDAC_EN (0x1 << 10)

//DAC LOADING STUFF
//dac select bits
#define DACSEL_SET (0x0)
#define DACSEL_MASK (0x7FFFC)
#define DACSEL_CLK (0x1)
#define DACSEL_OFF (0x2)
//which dacs to load mask
#define DMASK_VBAL (0x01)
#define DMASK_VTHR (0x02)
#define DMASK_TDISC (0x04)
#define DMASK_TCMOS (0x08)
#define DMASK_VINT (0x10)
#define DMASK_CHINJ (0x20)
//register bit offsets
#define BOFF_VBAL (9)
#define BOFF_VTHR (5)
#define BOFF_TDISC1 (2)
#define BOFF_TDISC2 (17)
#define BOFF_TCMOS (18)
#define BOFF_VINT (18)
#define BOFF_CHINJ (18)

//CMOS PROGRAMMING
#define CMOS_PROG_CLOCK (0x00000002)
#define CMOS_PROG_SERSTOR (0x00000001)
#define CMOS_PROG_DATA_OFFSET (2)

//CMOS TEST REGISTER STUFF
#define CMOS_TESTID_VALUE  (0x70aa550f)

//CALDAC CSR STUFF
#define ADC_ENABLE_ADC_OUTS_13 (0xFFFFAA02)
#define ADC_ENABLE_ADC_OUTS_24 (0xFFFFCA02)
#define ADC_DAC_TO_ADC_0 (0x1 << 12)
#define ADC_DAC_TO_ADC_1 (0x2 << 12)
#define ADC_DAC_TO_ADC_2 (0x4 << 12)
#define ADC_DAC_TO_ADC_3 (0x8 << 12)

//SEQUENCER CSR STUFF
#define ADC_CONVERT_START_BAR (0xFFFFF802)
#define ADC_CONVERT_START_DONE  (0xFFFFFA02)
#define ADC_LATCH_ADC_VALS (0x1 << 8)



#endif
