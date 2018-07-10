/*
    File:		ORPciBit3Commands.h
    
    Usage:		User Client Data Structures for PCIFMDriver
    
    Author:		FM
    
    Copyright:		Copyright 2001-2002 F. McGirt.  All rights reserved.
    
    Change History:	1/22/02, 2/2/02, 2/8/02 - 1.0.0d1, Initial Version
                        2/18/02 - 1.0.0d2, Workloop, Cmd Gate Version
                        3/1/02  - number of transfers <= 4096 bytes
                        
                        According to Apple, currently the IOKit and IOUserClient
                        (IOConnectMethodxx) do not support the transfer of single
                        blocks larger than 4096 bytes (a memory page) between user
                        space and kernel space.  Thus any larger block must be
                        transferred in chunks of 4096 bytes or less.
    
                        5/22/02 - open/close methods added
                        5/29/02 - data read/write methods removed
                        12/11/02 -MAH converted to Obj-C and added to Orca project
 
    Note:		PCI Matching is done with
                            Vendor ID 0x108a and Device ID 0x0001
                            
    Caution:		*** The Mother of all Disclaimers ***
                        Pay careful attention to any data retrieved from VME using
                        this software because of potential byte and word swapping
                        problems.   To write data to VME from the Mac at least two
                        swaps may take place since one is going from big endian on
                        the Mac to little endian on PCI back to big endian on VME.
                        For example, even if one reads back from VME exactly what
                        was written, the data could still have been stored in VME 
                        as swapped values.  Experimental data generated from sources
                        resident on VME must be checked for validity before use.
                        
                        Bit 3 is also not consistent when dealing with this problem
                        as the Bit3 CSR Register set does not appear to require swapping
                        on either reads or writes to these registers.  However, the
                        Mapping Registers do require that values be swapped before
                        being stored in these registers.
                        
-----------------------------------------------------------
This program was prepared for the Regents of the University of 
Washington at the Center for Experimental Nuclear Physics and 
Astrophysics (CENPA) sponsored in part by the United States 
Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
The University has certain rights in the program pursuant to 
the contract and the program should not be copied or distributed 
outside your organization.  The DOE and the University of 
Washington reserve all rights in the program. Neither the authors,
University of Washington, or U.S. Government make any warranty, 
express or implied, or assume any liability or responsibility 
for the use of this software.
-------------------------------------------------------------

    
*/
    

enum Bit3UserClientCommandCodes {
    kBit3UserClientOpen,		// kIOUCScalarIScalarO,  0, 0
    kBit3UserClientClose,		// kIOUCScalarIScalarO,  0, 0
    kBit3ReadPCIConfig,			// kIOUCScalarIScalarO,  1, 1
    kBit3WritePCIConfig,		// kIOUCScalarIScalarO,  2, 0
    kBit3GetPCIConfig,			// kIOUCScalarIStructO,	 1, 1
    kBit3GetPCIBusNumber,		// kIOUCScalarIScalarO,  0, 1
    kBit3GetPCIDeviceNumber,	// kIOUCScalarIScalarO,  0, 1
    kBit3GetPCIFunctionNumber,	// kIOUCScalarIScalarO,  0, 1
    kBit3NumCommands
};


typedef struct PCIConfigStruct
{
    UInt32 int32[64];
} PCIConfigStruct;

// Bit3 CSR definitions - offsets from I/O base address
#define	PCIVME_CSR_LOCAL_COMMAND_OFFSET			0x00
#define	PCIVME_CSR_LOCAL_INT_CONTROL_OFFSET		0x01
#define	PCIVME_CSR_LOCAL_STATUS_OFFSET			0x02
#define	PCIVME_CSR_LOCAL_INT_STATUS_OFFSET		0x03
#define	PCIVME_CSR_LOCAL_PCI_CONTROL_OFFSET		0x04
//#define	Reserved			0x05
//#define	Reserved			0x06
//#define	Reserved			0x07
#define	PCIVME_CSR_REMOTE_COMMAND_1_OFFSET		0x08
#define	PCIVME_CSR_REMOTE_STATUS_OFFSET			0x08
#define	PCIVME_CSR_REMOTE_COMMAND_2_OFFSET		0x09
//#define	Reserved			0x0a
//#define	Reserved			0x0b
#define	PCIVME_CSR_REMOTE_ADAPTER_ID_OFFSET		0x0c
#define	PCIVME_CSR_REMOTE_VME_ADD_MOD_OFFSET		0x0d
#define	PCIVME_CSR_REMOTE_IACK_READ_LOW_OFFSET		0x0e
#define	PCIVME_CSR_REMOTE_IACK_READ_HIGH_OFFSET		0x0f

// Bit3 DMA definitions - offsets from I/O base address
#define	PCIVME_DMA_LOCAL_COMMAND_OFFSET			0x10
#define	PCIVME_DMA_LOCAL_REMAINDER_COUNT_OFFSET		0x11
#define	PCIVME_DMA_LOCAL_PACKET_COUNT_0_7_OFFSET	0x12
#define	PCIVME_DMA_LOCAL_PACKET_COUNT_8_15_OFFSET	0x13
#define	PCIVME_DMA_LOCAL_PCI_ADDRESS_0_7_OFFSET		0x14
#define	PCIVME_DMA_LOCAL_PCI_ADDRESS_8_15_OFFSET	0x15
#define	PCIVME_DMA_LOCAL_PCI_ADDRESS_16_23_OFFSET	0x16
//#define	Reserved			0x17
#define	PCIVME_DMA_REMOTE_REMAINDER_COUNT_OFFSET	0x18
//#define	Reserved			0x19
#define	PCIVME_DMA_REMOTE_VME_ADDRESS_16_23_OFFSET	0x1a
#define	PCIVME_DMA_REMOTE_VME_ADDRESS_24_31_OFFSET	0x1b
#define	PCIVME_DMA_REMOTE_VME_ADDRESS_0_7_OFFSET	0x1c
#define	PCIVME_DMA_REMOTE_VME_ADDRESS_8_15_OFFSET	0x1d
#define	PCIVME_DMA_REMOTE_SLAVE_STATUS_OFFSET		0x1e
//#define	Reserved			0x1f

// masks for local command register - 8 bit, read/write
#define LOCAL_CMD_IER		0x20		// send PT interrupt
#define LOCAL_CMD_IE		0x40		// clear PR interrupt
#define LOCAL_CMD_CLRST		0x80		// clear local status register error bits

// masks for local interrupt control register - 8 bit, read/write
#define LOCAL_ICMD_CINTS0		0x01	// PT cint sel0
#define LOCAL_ICMD_CINTS1		0x02	// PT cint sel1
#define LOCAL_ICMD_CINTS2		0x04	// PT cint sel2
#define LOCAL_ICMD_ERIE			0x20	// error interrupt enable
#define LOCAL_ICMD_NMIE			0x40	// normal interrupt enable
#define LOCAL_ICMD_INTA			0x80	// interrupt active status

// masks for local status register - 8 bit, read only
#define LOCAL_STATUS_NOPOWER	0x01	// remote node power off
#define LOCAL_STATUS_LRC		0x02	// longitudinal redundancy error
#define LOCAL_STATUS_IFTO		0x04	// interface timeout
#define LOCAL_STATUS_RXPRI		0x20	// receiving PR interrupt
#define LOCAL_STATUS_VMEBERR	0x40	// remote node bus error
#define LOCAL_STATUS_IFPE		0x80	// interface parity error
#define STATUS_PROBLEM			0xE7	//OR of the above bits

// masks for local interrupt status register - 8 bit, read only
#define LOCAL_ISTATUS_INT1		0x02	// cable interrupt source cint1
#define LOCAL_ISTATUS_INT2		0x04	// cable interrupt source cint2
#define LOCAL_ISTATUS_INT3		0x08	// cable interrupt source cint3
#define LOCAL_ISTATUS_INT4		0x10	// cable interrupt source cint4
#define LOCAL_ISTATUS_INT5		0x20	// cable interrupt source cint5
#define LOCAL_ISTATUS_INT6		0x40	// cable interrupt source cint6
#define LOCAL_ISTATUS_INT7		0x80	// cable interrupt source cint7

// masks for local PCI command register - 8 bit, read/write
#define LOCAL_PCMD_TABT			0x01	// generate pci target abort cycle

// masks for remote command register 1 - 8 bit, write only
#define REMOTE_CMD1_IACK0		0x01	// IACK Address Bit 0
#define REMOTE_CMD1_IACK1		0x02	// IACK Address Bit 1
#define REMOTE_CMD1_IACK2		0x04	// IACK Address Bit 2
#define REMOTE_CMD1_LOCKVME		0x10	// lock vme bus
#define REMOTE_CMD1_SENDPR		0x20	// send PR interrupt
#define REMOTE_CMD1_CLRPT		0x40	// clear PT interrupt
#define REMOTE_CMD1_RESETVME	0x80	// reset vme bus (and assert sysreset)

// masks for remote status register - 8 bit, read only
#define REMOTE_STATUS_IACK0		0x01	// IACK Address Bit 0
#define REMOTE_STATUS_RXPTI		0x02	// receiving PT interrupt
#define REMOTE_STATUS_IACK2		0x04	// IACK Address Bit 2
#define REMOTE_STATUS_LOCKVME	0x10	// vme bus not locked
#define REMOTE_STATUS_TXPRI		0x20	// PR interrupt was sent
#define REMOTE_STATUS_IACK1		0x40	// IACK Address Bit 1
#define REMOTE_STATUS_RESETVME	0x80	// vme bus was reset

// masks for remote command register 2 - 8 bit, write only
#define REMOTE_CMD2_DISINT		0x10	// disable remote interrupt passing to local
#define REMOTE_CMD2_DMABLK		0x20	// select vme dma block mode
#define REMOTE_CMD2_DMAPAUSE	0x80	// dma pause after 16 transfers

// masks for local dma command register - 8 bit, read/write
#define LOCAL_DMACMD_ACTIVE		0x01	// DMA active
#define LOCAL_DMACMD_DONE		0x02	// DMA done
#define LOCAL_DMACMD_ENABLEI	0x04	// enable done interrupt
#define LOCAL_DMACMD_WDSEL		0x10	// word/long select
#define LOCAL_DMACMD_DIRECT		0x20	// direction
#define LOCAL_DMACMD_DPRAM		0x40	// dual port ram
#define LOCAL_DMACMD_START		0x80	// start dma

// other definitions
#define kDualPortAddress		0x08000000
#define kDualPortSize			0x00800000

#define kRemoteIOAddressModifier		0x29
#define kRemoteRAMAddressModifier		0x39
#define kRemoteDualPortAddressModifier	0x09

// vme access types for mapping registers
#define	kAccessRemoteIO		0x01
#define	kAccessRemoteRAM	0x02
#define	kAccessRemoteDRAM	0x03

// vme access widths
#define	ACCESS_REMOTE_LONG		'L'
#define	ACCESS_REMOTE_WORD		'W'
#define	ACCESS_REMOTE_BYTE		'B'


