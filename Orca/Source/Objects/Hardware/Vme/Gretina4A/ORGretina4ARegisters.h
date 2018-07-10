//
//  ORGretina4ARegisters.h
//  Orca
//
//  Created by Mark Howe on Sun June 5, 2017.
//  Copyright (c) 2017 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina  sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#define kNumGretina4AChannels		10

#define kNoAccess  0x0
#define kRead      0x1
#define kWrite     0x2
#define kChanReg   0x4
#define kReadOnly  kRead
#define kWriteOnly kWrite
#define kReadWrite kRead|kWrite

@class ORGretina4ARegisters;
@class ORGretina4AFPGARegisters;

#define Gretina4ARegisters      [ORGretina4ARegisters     sharedRegSet]
#define Gretina4AFPGARegisters  [ORGretina4AFPGARegisters sharedRegSet]

static ORGretina4ARegisters*        sharedGretina4ARegisters;
static ORGretina4AFPGARegisters*    sharedGretina4AFPGARegisters;

#pragma mark •••Register Definitions
enum {
    kBoardId,               //0x0000    board_id
    kProgrammingDone,       //0x0004	programming_done
    kExternalDiscSrc,       //0x0008    external Discriminator Src
    kHardwareStatus,        //0x0020	hardware_status
    kUserPackageData,       //0x0024	user_package_data
    kWindowCompMin,         //0x0028    window comparison min
    kWindowCompMax,         //0x002C    window comparison max
    kChannelControl,        //0x0040	channel_control0
    kLedThreshold,          //0x0080	led_threshold0
    kCFDFraction,           //0x00C0	CFD_fraction0
    kRawDataLength,         //0x0100	raw_data_length0 (waveform offset)
    kRawDataWindow,         //0x0140	raw_data_window0
    kDWindow,               //0x0180	d_window0
    kKWindow,               //0x01C0	k_window0
    kMWindow,               //0x0200	m_window0
    kD3Window,              //0x0240	d2_window0
    kDiscWidth,             //0x0280	disc_width0
    kBaselineStart,         //0x02C0	baseline_start0
    kP1Window,              //0x0300    p1_window
    kDac,                   //0x0400	dac
    kP2Window,              //0x0404    p2_window
    kIlaConfig,             //0x0408	ila_config
    kChannelPulsedControl,	//0x040C	channel_pulsed_control
    kDiagMuxControl,        //0x0410	diag_mux_control
    kHoldoffControl,        //0x0414	holdoff_Control
    kBaselineDelay,         //0x418     baseline delay
    kDiagChannelInput,      //0x041C	diag_channel_input
    kExternalDiscMode,      //0x0420	ext_desc_mode
    kRj45SpareDoutControl,	//0x0424	rj45_spare_dout_control
    kLedStatus,             //0x0428	led_status
    kDownSampleHoldOffTime, //0x0434    downsample holdoff
    kLatTimestampLsb,       //0x0480	lat_timestamp_lsb
    kLatTimestampMsb,       //0x0488	lat_timestamp_msb
    kLiveTimestampLsb,      //0x048C	live_timestamp_lsb
    kLiveTimestampMsb,      //0x0490	live_timestamp_msb
    kVetoGateWidth,         //0x0494	time window for slave accepts vetos
    kMasterLogicStatus,     //0x0500	master_logic_status
    kTriggerConfig,         //0x0504	trigger_config
    kPhaseErrorCount,       //0x0508	Phase_Error_count
    kPhaseValue,            //0x050C	Phase_Value
    kPhaseOffset0,          //0x0510	phase_offset0
    kPhaseOffset1,          //0x0510	phase_offset1
    kPhaseOffset2,          //0x0510	phase_offset2
    kSerdesPhaseValue,      //0x051C	Serdes_Phase_Value
    kCodeRevision,          //0x0600	code_revision
    kCodeDate,              //0x0604	code_date
    kTSErrCntEnable,        //0x0608	TS_err_cnt_enable
    kTSErrorCount,          //0x060C	TS_error_count
    kDroppedEventCount,     //0x0700	dropped_event_count0
    kAcceptedEventCount,	//0x0740	accepted_event_count0
    kAhitCount,             //0x0780	ahit_count0
    kDiscCount,             //0x07C0	disc_count0
    kAuxIORead,             //0x0800	aux_io_read
    kAuxIOWrite,            //0x0804	aux_io_write
    kAuxIOConfig,           //0x0808	aux_io_config
    kSdConfig,              //0x0848    serdes config
    kFifo,                  //0x1000	fifo
    kNumberOfGretina4ARegisters         //must be last
};


enum {
    kMainFPGAControl,			//0x0900 Main Digitizer FPGA config register
    kMainFPGAStatus,			//0x0904 Main Digitizer FPGA status register
    kAuxStatus,                 //0x0908 VME temp and status
    kVMEGPControl,				//0x0910 General Purpose VME Control Settings
    kVMETimeoutValue,			//0x0914 VME Timeout Value Register
    kVMEFPGAVersionStatus,		//0x0920 VME Version/Status
    kVMEFPGADate,
    kVMEFPGASandbox1,			//0x0930 VME Sandbox1
    kVMEFPGASandbox2,			//0x0934 VME Sandbox2
    kVMEFPGASandbox3,			//0x0938 VME Sandbox3
    kVMEFPGASandbox4,			//0x093C VME Sandbox4
    kNumberOfFPGARegisters
};
#define kGretina4AFIFOEmpty			0x100000
#define kGretina4AFIFOAlmostEmpty	0x400000
#define kGretina4AFIFOAlmostFull	0x800000
#define kGretina4AFIFOAllFull		0x1000000

#define kGretina4APacketSeparator    0xAAAAAAAA

#define kGretina4ANumberWordsMask	0x7FF0000

#define kGretina4AFlashMaxWordCount	0xF
#define kGretina4AFlashBlockSize		( 128 * 1024 )
#define kGretina4AFlashBlocks		128
#define kGretina4AUsedFlashBlocks	32
#define kGretina4AFlashBufferBytes	32
#define kGretina4ATotalFlashBytes	( kGretina4AFlashBlocks * kGretina4AFlashBlockSize)
#define kFlashBusy                  0x80
#define kGretina4AFlashEnableWrite	0x10
#define kGretina4AFlashDisableWrite	0x0
#define kGretina4AFlashConfirmCmd	0xD0
#define kGretina4AFlashWriteCmd		0xE8
#define kGretina4AFlashBlockEraseCmd	0x20
#define kGretina4AFlashReadArrayCmd	0xFF
#define kGretina4AFlashStatusRegCmd	0x70
#define kGretina4AFlashClearSRCmd	0x50

#define kGretina4AResetMainFPGACmd	0x30
#define kGretina4AReloadMainFPGACmd	0x3
#define kGretina4AMainFPGAIsLoaded	0x41


#define kSPIData	    0x2
#define kSPIClock	    0x4
#define kSPIChipSelect	0x8
#define kSPIRead        0x10
#define kSDLockBit      (0x1<<17)
#define kSDLostLockBit  (0x1<<24)



@interface ORGretina4ARegisters : NSObject
{
    BOOL printedOnce;
}

+ (ORGretina4ARegisters*) sharedRegSet;
- (id) init;
- (void) dealloc;
- (BOOL) checkRegisterTable;

- (int)           numRegisters;
- (BOOL)          regIsReadable:  (unsigned short) anIndex;
- (BOOL)          hasChannels:    (unsigned short) anIndex;
- (BOOL)          regIsWriteable: (unsigned short) anIndex;
- (NSString*)     registerName:   (unsigned short) anIndex;
- (short)         accessType:     (unsigned short) anIndex;
- (unsigned long) address:(unsigned long)baseAddress forReg:(unsigned short)anIndex;
- (unsigned long) address:(unsigned long)baseAddress forReg:(unsigned short)anIndex chan:(unsigned short)aChannel;
- (unsigned long) offsetforReg:(unsigned short)anIndex;
- (unsigned long) offsetforReg:(unsigned short)anIndex chan:(unsigned short)aChannel;
- (void)          checkChannel:(unsigned short)aChannel;
- (void)          checkIndex:(unsigned short)anIndex;
@end


@interface ORGretina4AFPGARegisters : NSObject
{
    BOOL printedOnce;
}

+ (ORGretina4AFPGARegisters*) sharedRegSet;
- (id) init;
- (void) dealloc;
- (BOOL) checkRegisterTable;

- (int)           numRegisters;
- (BOOL)          regIsReadable:  (unsigned short) anIndex;
- (BOOL)          regIsWriteable: (unsigned short) anIndex;
- (NSString*)     registerName:   (unsigned short) anIndex;
- (short)         accessType:     (unsigned short) anIndex;
- (unsigned long) offsetforReg:(unsigned short)anIndex;
- (unsigned long) address:(unsigned long)baseAddress forReg:(unsigned short)anIndex;
- (void)          checkIndex:(unsigned short)anIndex;

@end
