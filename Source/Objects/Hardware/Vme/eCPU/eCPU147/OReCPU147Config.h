

/*
 *	File:			OReCPU147Config.h
 *
 *	Description:		Common configuration parameters for generating and downloading code
 *				resources to the MVME 147 and 167 eCPU units (using the Bit 3 VME adapter)
 *				Contains: 	absolute memory addresses for the eCPU units
 *						eCPU "user" flag definitions
 *
 *				This file is and should be kept independent of application specific code
 *
 *	Author:			F. McGirt and J. Wilkerson
 *
 *	Revision History:	10/28/92 - original (was configureVmeTasks.h)
 *				01/15/94 - ethernet support added, changed USER_CODE_ADDRESS
 *									to 0x00010000 to allow room for new ethernet loader at 4200
 *				10/04/95 - added support for MVME 167 cpu
 *				01/30/98 - revised for SNO by JFW.  For ease in understanding DPM
 * 									moved all DPM info to the configER2aTask.h file and
 *									it is included in this file.
 *
 *				06/07/02 - cleanup, relocated non-eCPU related definitions
 *				03/27/03 - MAH. imported into the ORCA project  
 *
 *
 * 
 */
 
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

// address definitions ( as viewed from vme cpu and bit 3 bus master ) 
#define	BOOT_ADDRESS			0x00004000L			/* start of boot code area in vme cpu */
#define	USER_DATA_ADDRESS		0x00004100L			/* start of user data area in vme cpu */
#define	USER_CODE_ADDRESS		0x00010000L			/* start of executable user code in vme cpu */
#define	USER_START_CODE_ADDRESS		USER_CODE_ADDRESS		/* go address in vme cpu (after download) */

// user flag area (in user data area) address definitions ( as viewed from vme cpu and bit 3 bus master ) */
#define	USER_STOP_CODE_FLAG		(USER_DATA_ADDRESS + 0L)	/* flag(short) to stop user code execution */
#define	USER_DATA_OLD_VECT		(USER_DATA_ADDRESS + 2L)	/* address(long) of saved interrupt vector */
#define	USER_DATA_OLD_STATUS		(USER_DATA_ADDRESS + 6L)	/* value(short) of saved status register */
#define	USER_START_CODE_FLAG		(USER_DATA_ADDRESS + 8L)	/* flag(short) to verify start of user code execution */
#define	USER_HARDWARE_EXIST_FLAG	(USER_DATA_ADDRESS + 10L)	/* flag(short) to verify existance of vme hardware */
#define	USER_START_DAQ_FLAG			(USER_DATA_ADDRESS + 12L)	/* flag(short) to cause start of user code daq */
#define	USER_OS_CMD					(USER_DATA_ADDRESS + 14L)	/* value(short) of os command */
#define	USER_OS_CMD_RESPONSE		(USER_DATA_ADDRESS + 16L)	/* value(short) of os command response */
#define	USER_LANCE_CMD				(USER_DATA_ADDRESS + 18L)	/* value(short) of lance command */
#define	USER_LANCE_CMD_RESPONSE		(USER_DATA_ADDRESS + 20L)	/* value(long) of lance command response */
#define	USER_LANCE_CMD_DATA			(USER_DATA_ADDRESS + 24L)	/* data(14 bytes) for lance command */
#define USER_MAC_ETHERNET_ADDRESS	(USER_DATA_ADDRESS + 38L)	/* hardware mac ethernet address(6 bytes) */
#define USER_MAC_IP_ADDRESS			(USER_DATA_ADDRESS + 44L)	/* hardware mac ip address(4 bytes) */
#define USER_VME_ETHERNET_ADDRESS	(USER_DATA_ADDRESS + 48L)	/* hardware vme ethernet address(6 bytes) */
#define USER_VME_IP_ADDRESS			(USER_DATA_ADDRESS + 54L)	/* hardware vme ip address(4 bytes) */
#define USER_WATCHDOG_FLAG_ADDRESS	(USER_DATA_ADDRESS + 58L)	/* flag(long) to verify cpu task is running */
#define USER_UNUSED1				(USER_DATA_ADDRESS + 62L)   	/* unused bytes */
#define USER_SUSPEND_DONE_FLAG		(USER_DATA_ADDRESS + 64L)	/* flag(short) to stop suspend operation */
#define USER_UNUSED2				(USER_DATA_ADDRESS + 66L)   	/* unused bytes */
#define USER_INTERNAL_HEARTBEAT		(USER_DATA_ADDRESS + 68L)	/* value(long) of suspended heartbeat */
#define USER_RESERVED				(USER_DATA_ADDRESS + 72L)	/* reserved up to USER_CODE_ADDRESS */
			
// user flag values 
#define	STOP_FLAG					0x0a05
#define	OVERFLOW_FLAG				0x050a
#define	MESSAGE_FLAG				0x55aa
#define MESSAGE_STATUS_INFO			'I'
#define MESSAGE_STATUS_FATAL_ERROR	'F'
#define	HARDWARE_FLAG				0x0a15
#define	HARDWARE_NOT_EXISTS_FLAG	0x0b16




//****this should probably be somewhere else. MAH 04/03/03
// ------------------------------------------------------------
// ----------------------------------------------------------------------------
//	 SBS Bit3 VME controller DUAL PORT RAM PARAMETER BLOCK HW definitions
//		(set by jumpers on Bit 3 VME cards)
#define MAC_BIT3_DPM_BASE	0x08000000L
#define VME_DUAL_RAM_SIZE	0x00800000L	// 8 mbyte DRAM

//	 Bit3 DUAL PORT RAM PARAMETER BLOCK relative addresses
#define CONTROL_ADDRESS_START	0x00000L		// address for control or arbitration structure (256 bytes total)
#define COMM_ADDRESS_START		0x00100L		// address for communications structure (1280 bytes total)
#define CHW_CONFIG_START		0x00600L		// start of Crate Hardware Config buffer (2560 bytes total) 
#define ECPU_WRITE_LAM_START    0x01000L        // eCPU write only LAM memory
#define MAC_WRITE_LAM_START     0x02000L        // eCPU read only LAM memory
#define DATA_CIRC_BUF_START		0x03000L		// CB data buffer start (rest of memory)

// use remaining Bit3 memory for combined circular buffer
#define DATA_CIRC_BUF_SIZE_BYTE	(VME_DUAL_RAM_SIZE - DATA_CIRC_BUF_START)

// Macros for setting MAC specific DPM addresses
#define MAC_DPM(x)			((x) + MAC_BIT3_DPM_BASE)

#define DPM_MON_BUF_SIZE	12	// NOTE IF YOU CHANGE THIS VALUE IT CHANGES THE SIZE OF THE STRUCTURE
                                // BELOW AND THE AMOUNT OF DPM THAT MUST BE ALLOCATED FOR THIS STRUCTURE

#define HW_MAX_COUNT	    20	//

// user computer - eCPU computer control variables that reside in Dual Port Memory
//					this structure is considered read only by eCPU
//					Current size is 40 bytes out of 128 bytes
typedef struct {

	unsigned long ro_control_rqst;		// readout and pause control request flag
	unsigned long ro_mod_rqst;			// readout modification control request flag
	unsigned long ecpu_dbg_level;		// eCPU debug level message flag
	unsigned long run_start_time;		// start time of this run in Mac time_t
	unsigned long disable_eCPU_delay;	// disable the eCPU pause routine
	unsigned long disable_CB_updates;	// disable the writing of CB header and block/bytes written flags

} eCPUDualPortControl;

// Current memory size = 876 bytes out of 2560 bytes	** for DPM_MON_BUF_SIZE	= 12 **

typedef struct  {

	unsigned long sentinel_value;			// sentinel_value = 0x55378008 for good DPM
	unsigned long version;                  // code version i.e. '1.0a'
	unsigned long ecpu_status;				// eCPU status
	unsigned long heartbeat;				// eCPU heartbeat counter
	unsigned long data_words_transferred;	// amount of data in words transferred last control loop
	unsigned long control_loop_delay;		// control loop delay (ms)
	unsigned long ro_mod_ack_cnt;			// readout modification control acknowledge counter
	

	unsigned long tot_err_cnt;				// eCPU total error counter
	unsigned long err_buf_cnt;				// eCPU error array index
	unsigned long msg_buf_cnt;				// eCPU error array index
	unsigned long data_head_ptr;			// data CB head pointer
	unsigned long data_tail_ptr;			// data CB tail pointer

	unsigned long CB_err_dpm_buf_full_cnt;	// CB full error counter
 
	unsigned long rd_error_cnt[HW_MAX_COUNT];
	unsigned long loop_cnt[HW_MAX_COUNT];			// number of Clock loops in hw readout
	unsigned long total_rate_cnt[HW_MAX_COUNT];		// number of Clock loops in hw readout

	unsigned long error_value[DPM_MON_BUF_SIZE];	// eCPU recent errors array
	unsigned long er_parm0[DPM_MON_BUF_SIZE];	// eCPU error associated parameter
	unsigned long er_parm1[DPM_MON_BUF_SIZE];	// eCPU error associated parameter
	unsigned long er_parm2[DPM_MON_BUF_SIZE];	// eCPU error associated parameter
	unsigned long er_parm3[DPM_MON_BUF_SIZE];	// eCPU error associated parameter
	unsigned long er_parm4[DPM_MON_BUF_SIZE];	// eCPU error associated parameter
	unsigned long msg_value[DPM_MON_BUF_SIZE];	// eCPU msg array
	unsigned long msg_parm0[DPM_MON_BUF_SIZE];	// eCPU msg associated parameter
	unsigned long msg_parm1[DPM_MON_BUF_SIZE];	// eCPU msg associated parameter
	unsigned long msg_parm2[DPM_MON_BUF_SIZE];	// eCPU msg associated parameter
	unsigned long msg_parm3[DPM_MON_BUF_SIZE];	// eCPU msg associated parameter
	unsigned long msg_parm4[DPM_MON_BUF_SIZE];	// eCPU msg associated parameter
}eCPU_MAC_DualPortComm;

typedef struct {
    unsigned long  lamFired_counter;
    unsigned long  numberUserInfoWords;
    unsigned long  userInfoWord[10];
    unsigned long  numberDataWords;
    unsigned long  formatedDataWord[10];
} EcpuWriteLAMStruct;

typedef struct {
    unsigned long  lamAcknowledged_counter;  
} MacWriteLAMStruct;

