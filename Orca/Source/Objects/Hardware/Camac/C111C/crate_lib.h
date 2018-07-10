/*
 =======================================================
 JENET CRATE Library
 =======================================================
 Author      : Mauro Vetuschi
 Company     : ZP Engineering srl
 Description : 
 Date        : 14/06/2007
 Version     : 03.00 
 Credits     : Sergei Shibaev (Sergei.Shibaev@ukaea.org.uk) 

 Revision    : 03.00 - Added WIN32 support
                       Fixed Block transfer read operation
					   (added ascii_transf in Block transfer structure)
		     : 02.07 - Adapted for new firmware
             : 02.06 - Corrected BLKTRANSF bug 
             : 02.05 - Improved IRQ Notify 
             : 02.04 - added TIMEOUT managing and 
			           CRTOUT function      
             : 02.03 - csocket_lib imported in crate_lib  
             : 02.02 - 
             : 02.01 - 
 =======================================================
*/

#ifndef CRATE_LIB_H
#define CRATE_LIB_H

#ifdef WIN32

#include <windows.h>

#else

#include <pthread.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define  SOCKET       int
#define  HANDLE       pthread_t
#define  closesocket  close

#endif

////////////////////////////////////////////
//	Defines
////////////////////////////////////////////

#define MAX_CRATE               128
#define MAX_PAR					16

#define CMD_PORT				2000
#define BIN_PORT				2001
#define IRQ_PORT				2002

////////////////////////////////////////////
//	Return Codes
////////////////////////////////////////////

#define CRATE_OK		        0
#define CRATE_ERROR		        -1
#define CRATE_CONNECT_ERROR		-2
#define CRATE_IRQ_ERROR			-3
#define CRATE_BIN_ERROR			-4
#define CRATE_CMD_ERROR			-5
#define CRATE_ID_ERROR			-6
#define CRATE_MEMORY_ERROR		-7

////////////////////////////////////////////
//	BLK_TRANSF Opcode Defines
////////////////////////////////////////////

#define OP_BLKSS				0x0
#define OP_BLKFS				0x1
#define OP_BLKSR				0x2
#define OP_BLKFR				0x3
#define OP_BLKSA				0x4
#define OP_BLKFA				0x5

////////////////////////////////////////////
//	IRQ Type Defines
////////////////////////////////////////////

#define LAM_INT					0x1
#define COMBO_INT				0x2
#define DEFAULT_INT				0x3

////////////////////////////////////////////
//	Defines for BIN Protocol
////////////////////////////////////////////

#define STX						0x2
#define ETX						0x4
#define STUFF					0x10
#define CMD_ERROR				0xCE
#define PAR_ERROR				0xCF

#define BIN_CFSA_CMD			0x20
#define BIN_CSSA_CMD			0x21
#define BIN_CCCZ_CMD			0x22
#define BIN_CCCC_CMD			0x23
#define BIN_CCCI_CMD			0x24
#define BIN_CTCI_CMD			0x25
#define BIN_CTLM_CMD			0x26
#define BIN_CCLWT_CMD			0x27
#define BIN_LACK_CMD			0x28
#define BIN_CTSTAT_CMD			0x29
#define BIN_CLMR_CMD			0x2A
#define BIN_CSCAN_CMD			0x2B

#define BIN_NIM_SETOUTS_CMD		0x30

#define NO_BIN_RESPONSE			0xA0

////////////////////////////////////////////
//	BLK_TRANSF_INFO Structure
////////////////////////////////////////////

typedef struct {
    short opcode;
    short F;
    short N;
    short A;
    unsigned short totsize;
	unsigned short blksize;
	unsigned short timeout;
	short ascii_transf;
} BLK_TRANSF_INFO;

////////////////////////////////////////////
//	CRATE_INFO Structure
////////////////////////////////////////////

typedef void (*IRQ_CALLBACK) (short, short, unsigned int, unsigned long);

typedef struct {
	unsigned char		connected;

	SOCKET				sock_ascii;
	SOCKET				sock_bin;
	SOCKET				sock_irq;
	
	unsigned char		no_bin_resp;
	unsigned char		tout_mode;
	unsigned int		tout_ticks;

	IRQ_CALLBACK		irq_callback;
	HANDLE				irq_tid;
	unsigned long		userInfo;
} CRATE_INFO;

////////////////////////////////////////////
//	CRATE_OP Structure
////////////////////////////////////////////

typedef struct {
	char F;
	char N;
	char A;
	char Q;
	char X;
	int  DATA;
} CRATE_OP;



#ifdef cplusplus
extern "C" {
#else
#ifdef __cplusplus
extern "C" {
#endif
#endif
////////////////////////////////////////////
//	Socket functions helper
////////////////////////////////////////////

SOCKET csock_connect	(char *ipAddress, int port);
SOCKET csock_udpconnect	(char *ipAddress, int port, struct sockaddr_in *dest);

int csock_close			(SOCKET sck);

int csock_canwrite		(SOCKET sck);
int csock_canread		(SOCKET sck);
int csock_send			(SOCKET sck, void *buffer, int size);
int csock_sendto		(SOCKET sck, void *buffer, int size, struct sockaddr *dest);

int csock_recv			(SOCKET sck, void *buffer, int size);
int csock_recvfrom		(SOCKET sck, void *buffer, int size, struct sockaddr *dest);

int csock_recv_nb       (SOCKET sck, void *buffer, int size);
int csock_recv_t		(SOCKET sck, void *buffer, int size, int timeout);

int csock_recvline		(SOCKET sck, char *buffer, int size);
int csock_recvline_f	(SOCKET sck, char *buffer, int size);
int csock_recvline_t	(SOCKET sck, char *buffer, int size, int timeout);

int csock_sendrecvline  (SOCKET sck, char *cmd, char* response, int size);
int csock_sendrecvline_t(SOCKET sck, char *cmd, char* response, int size, int timeout);

int csock_flush			(SOCKET sck);

////////////////////////////////////////////
//	Config Functions declaration
////////////////////////////////////////////

short CROPEN	(char *address);
short CRCLOSE	(short crate_id);

short CRIRQ		(short crate_id, IRQ_CALLBACK irq_callback, unsigned long userInfo);

short CRGET		(short crate_id, CRATE_INFO *cr_info);
short CRSET		(short crate_id, CRATE_INFO *cr_info);

short CRTOUT	(short crate_id, unsigned int tout);

short CBINR		(short crate_id, short enable_resp);

////////////////////////////////////////////
//	ESONE Functions declaration
////////////////////////////////////////////

short CFSA		(short crate_id, CRATE_OP *cr_op);
short CSSA		(short crate_id, CRATE_OP *cr_op);

short CCCZ		(short crate_id);
short CCCC		(short crate_id);
short CCCI		(short crate_id, char data_in);
short CTCI		(short crate_id, char *res);

short CTLM		(short crate_id, char slot, char *res);
short CCLWT		(short crate_id, char slot);
short LACK		(short crate_id);
short CLMR		(short crate_id, unsigned int *reg);

short CTSTAT	(short crate_id, char *Q, char *X);

short CSCAN		(short crate_id, unsigned int *scan_res);

short BLKBUFFS	(short crate_id, short value);
short BLKTRANSF	(short crate_id, BLK_TRANSF_INFO *blk_info, unsigned int *buffer);

////////////////////////////////////////////
//	NIM OUT Function implementation
////////////////////////////////////////////

short NOSOS		(short crate_id, char nimo, char value);

////////////////////////////////////////////
//	CMD Function implementation
////////////////////////////////////////////

short CMDS		(short crate_id, char *cmd, int size);
short CMDR		(short crate_id, char *resp, int size);
short CMDSR		(short crate_id, char *cmd, char *resp, int size);

#ifdef cplusplus
}
#else
#ifdef __cplusplus
}
#endif
#endif

#endif


