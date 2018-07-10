/*
 =======================================================
 JENET CRATE Library
 =======================================================
 Author      : Mauro Vetuschi
 Company     : ZP Engineering srl
 Description : 
 Date        : 14/06/2007
 Version     : 3.00
 Credits     : Sergei Shibaev (Sergei.Shibaev@ukaea.org.uk) 
 Revision    : Added WIN32 support
               Fixed Block transfer read operation bug
 =======================================================
*/

#ifdef WIN32

#include <stdio.h>
#include <time.h>
#include <Winsock2.h>
#else

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <sys/wait.h>
#include <sys/stat.h>

#include <arpa/inet.h>
#include <netinet/in.h>

#include <stdio.h>
#include <stdlib.h> 
#include <fcntl.h> 
#include <string.h> 
#include <errno.h> 
#include <dirent.h> 
#include <signal.h> 
#include <unistd.h> 
#include <ctype.h> 
#include <netdb.h>
#include <sys/time.h> 
#include <sys/wait.h> 
#include <sys/types.h> 
#include <sys/socket.h> 
#include <sys/stat.h> 
#include <netinet/in.h> 
#include <arpa/inet.h>
#include <sys/ioctl.h>
#include <time.h> 

#endif

#include "crate_lib.h"

////////////////////////////////////////////
// PARAMETER Structure 
////////////////////////////////////////////

typedef struct {
	char x[16];
} PARAMETER;

////////////////////////////////////////////
// Variable declaration
////////////////////////////////////////////

static CRATE_INFO crate_info[MAX_CRATE]; 
char CRATE_TxBuffer[256], CRATE_RxBuffer[256];
short tempId[MAX_CRATE];

#ifdef WIN32
	int init_done = 0;
#endif 

////////////////////////////////////////////
//	Socket helper functions implementation
////////////////////////////////////////////

////////////////////////////////////////////
//	csock_connect
////////////////////////////////////////////
SOCKET csock_connect(char *ipAddress, int port)
{
	SOCKET sck = 0;
	struct sockaddr_in target_address;

#ifdef WIN32
	int rc;
	unsigned long non_block;
	fd_set writefds;
	TIMEVAL timeout;
#else
	int  tout, oflag;
	time_t now;
#endif

    // Try to open connection with target
	target_address.sin_family = AF_INET;
	target_address.sin_addr.s_addr = inet_addr(ipAddress);
	target_address.sin_port =  htons((unsigned short)port);

    if ((sck = socket(AF_INET, SOCK_STREAM, 0)) != 0) {
#ifdef WIN32
		non_block = 1;
		ioctlsocket(sck, FIONBIO, &non_block);
		if (connect(sck, (struct sockaddr *) &target_address, sizeof(target_address)) == -1) {
			timeout.tv_usec = 0;
#ifndef CRATE_CONNECT_TIMEOUT
			timeout.tv_sec = 3;
#else
			timeout.tv_sec = CRATE_CONNECT_TIMEOUT;
#endif
			FD_ZERO(&writefds);
			FD_SET(sck, &writefds);
			rc = select(0, NULL, &writefds, NULL, &timeout);
			if (rc != 1)   {
				shutdown(sck, 2);
				closesocket(sck);
				return 0;
			}
        }
		non_block = 0;
		ioctlsocket(sck, FIONBIO, &non_block);
#else
		oflag = fcntl(sck, F_GETFL);
		fcntl(sck, F_SETFL, oflag | O_NONBLOCK);
#ifndef CRATE_CONNECT_TIMEOUT
		tout = 3;
#else
		tout = CRATE_CONNECT_TIMEOUT;
#endif
		now = time(NULL);
		while (connect(sck, (struct sockaddr *) &target_address, sizeof(target_address)) == -1) {
			if(csock_canwrite(sck))break;
			if ((time(NULL) - now) > tout) {
		        return 0;
			}
        }
		
		fcntl(sck, F_SETFL, oflag);
#endif
    }
    else
        return 0;

	return sck;
}

////////////////////////////////////////////
//	csock_udpconnect
////////////////////////////////////////////
SOCKET csock_udpconnect(char *ipAddress, int port, struct sockaddr_in *dest)
{
	SOCKET sck = 0;
	struct sockaddr_in target_address;

    // Try to open connection with target
	target_address.sin_family = AF_INET;
	target_address.sin_addr.s_addr = inet_addr(ipAddress);
	target_address.sin_port = htons((unsigned short)port);
	
    if ((sck = socket(AF_INET, SOCK_DGRAM, 0)) == 0) {
        return 0;
	}

	memcpy(dest, &target_address, sizeof(struct sockaddr_in));
	return sck;
}

////////////////////////////////////////////
// csock_close
////////////////////////////////////////////
int csock_close(SOCKET sck)
{
	shutdown(sck, 2);
	closesocket(sck);
	return 0;
}

////////////////////////////////////////////
// csock_canwrite
////////////////////////////////////////////
int csock_canwrite(SOCKET sck)
{
	fd_set wfds;
	struct timeval tv;
	int retval;

	FD_ZERO(&wfds);
	FD_SET(sck, &wfds);

	tv.tv_sec = 0;
	tv.tv_usec = 0;

	retval = select(sck + 1, NULL, &wfds, NULL, &tv);

	if (retval > 0) {
		if (FD_ISSET(sck, &wfds)) {
      return 1;
		}
	}
	return 0;
}

////////////////////////////////////////////
// csock_canread 
////////////////////////////////////////////
int csock_canread(SOCKET sck)
{
	fd_set rfds;
	struct timeval tv;
	int retval;

	FD_ZERO(&rfds);
	FD_SET(sck, &rfds);

	tv.tv_sec = 0;
	tv.tv_usec = 0;

	retval = select(sck + 1, &rfds, NULL, NULL, &tv);

	if (retval > 0) {
		if (FD_ISSET(sck, &rfds)) {
			return 1;
		}
	}
	return 0;
}


////////////////////////////////////////////
//	csock_send
////////////////////////////////////////////
int csock_send(SOCKET sck, void *buffer, int size)
{
	int ret = 0;
	int pos = 0;
	char* p = (char*)buffer;
	while (size) {
		//if (csock_canwrite(sck)){
			ret =  send(sck, &p[pos], size, 0);
			pos += ret;
			size -= ret;
			if(size<=0)break;
		//}
	}
	return ret;
}

////////////////////////////////////////////
//	csock_sendto
////////////////////////////////////////////
int csock_sendto(SOCKET sck, void *buffer, int size, struct sockaddr *dest)
{ 
	return sendto(sck, (char *) buffer, size, 0, dest, sizeof(struct sockaddr_in));
}

////////////////////////////////////////////
//	csock_recv
////////////////////////////////////////////
int csock_recv(SOCKET sck, void *buffer, int size)
{
	return recv(sck, (char *) buffer, size, 0);
}

////////////////////////////////////////////
//	csock_recvfrom
////////////////////////////////////////////
int csock_recvfrom(SOCKET sck, void *buffer, int size, struct sockaddr *dest)
{
#ifdef WIN32
	int addr_len = sizeof(struct sockaddr_in);
#else
	socklen_t addr_len = sizeof(struct sockaddr_in);
#endif
	return recvfrom(sck, (char *) buffer, size, 0, dest, &addr_len);
}

////////////////////////////////////////////
//	csock_recv_t
////////////////////////////////////////////
int csock_recv_t(SOCKET sck, void *buffer, int size, int timeout)
{
	int rp, pos;
	time_t now = time(NULL);
	char *buf = (char *) buffer;

	pos = 0;
	buf[pos] = '\0';

	while (pos < size) {
		//if (csock_canread(sck)) {
			rp = recv(sck, &buf[pos], size, 0);
			if (rp < 0) return -1;
			pos+=rp;
			size-=rp;
		//}
		if(size==0)break;
		if ((time(NULL) - now) > timeout) {
			buf[pos] = '@';
			return -3;
		}
	}
	return pos;
}

////////////////////////////////////////////
//	csock_recvline
////////////////////////////////////////////
int csock_recvline(SOCKET sck, char *buffer, int size)
{
	int rp, pos;
	
	pos = 0;
	buffer[pos] = '\0';
	
	while (pos < size)  {
		rp = recv(sck, &buffer[pos], 1, 0);
		printf("rp: %d %d %c\n",rp,buffer[pos],buffer[pos]);
		if (rp > 0) {
			buffer[pos + 1] = '\0';

			// Clear new line from buffer
			if (buffer[pos] == '\r') {
				buffer[pos] = '\0';
				pos--;
			}
			
			if (buffer[pos] == '\n') {
				buffer[pos] = '\0';
				return (pos);
			}
			
			pos++;

			if (pos > size)
				return -2;
		}
		else {
			return -1;
		}
	}
	return 0;
}

////////////////////////////////////////////
//	csock_recvline_f
////////////////////////////////////////////
int csock_recvline_f(SOCKET sck, char *buffer, int size)
{
	int rp, pos;
	
	pos = 0;
	buffer[pos] = '\0';
	
	while (pos < size)  {
		rp = recv(sck, &buffer[pos], 1, 0);
		if (rp > 0) {
			buffer[pos + 1] = '\0';

			// Clear new line from buffer
			if (buffer[pos] == '\r') {
				buffer[pos] = '\0';
				pos--;
			}
			
			if (buffer[pos] == '\n') {
				buffer[pos] = '\0';
				csock_flush(sck);
				return (pos);
			}

			pos++;

			if (pos > size)
				return -2;
		}
		else {
			return -1;
		}
	}
	return 0;
}

////////////////////////////////////////////
//	csock_recvline_t
////////////////////////////////////////////
int csock_recvline_t(SOCKET sck, char *buffer, int size, int timeout)
{
	int rp, pos;
	time_t now = time(NULL);

	pos = 0;
	buffer[pos] = '\0';
	
	while (pos < size) {
		if (csock_canread(sck)) {
			rp = recv(sck, &buffer[pos], 1, 0);
			if (rp > 0) {
				buffer[pos + 1] = '\0';

				// Clear new line from buffer
				if (buffer[pos] == '\r') {
					buffer[pos] = '\0';
					pos--;
				}
				
				if (buffer[pos] == '\n') {
					buffer[pos] = '\0';
					return (pos);
				}
				
				pos++;

				if (pos > size)
					return -2;
			}
			else {
				return -1;
			}
		}
		
		if ((time(NULL) - now) > timeout) {
			buffer[pos] = '@';
			return -3;
		}
	}
	return 0;
}

////////////////////////////////////////////
//	csock_recv_nb
////////////////////////////////////////////
int csock_recv_nb(SOCKET sck, void *buffer, int size)
{

	int rp = 0;
	int oflag = 0;
	
	memset(buffer, 0, size);
	
#ifdef WIN32
#else
	if (csock_canread(sck))  {
		oflag = fcntl(sck, F_GETFL);
		fcntl(sck, F_SETFL, oflag | O_NONBLOCK);
		rp = recv(sck, (char *) buffer, size, 0);
		fcntl(sck, F_SETFL, oflag);
	}
#endif
	return rp;
}

////////////////////////////////////////////
//	csock_flush
////////////////////////////////////////////
int csock_flush(SOCKET sck)
{
	char buffer;
	while (csock_canread(sck)) 
		csock_recv(sck, &buffer, 1);
	return 0;
}

////////////////////////////////////////////
//	csock_sendrecvline
////////////////////////////////////////////
int csock_sendrecvline(SOCKET sck, char *cmd, char* response, int size)
{
	int resp;
	
	resp = csock_send(sck, cmd, strlen(cmd));
	if (resp <= 0) {
		return 1;
	}
	
	resp = csock_recvline(sck, response, size);
	if (resp <= 0) {
		return 2;
	}

	return 0;
}

////////////////////////////////////////////
//	csock_sendrecvline_t
////////////////////////////////////////////
int csock_sendrecvline_t(SOCKET sck, char *cmd, char* response, int size, int timeout)
{
	int resp;
	
	resp = csock_send(sck, cmd, strlen(cmd));
	if (resp <= 0) {
		return 1;
	}
	
	resp = csock_recvline_t(sck, response, size, timeout);
	if (resp <= 0) {
		return 2;
	}

	return 0;
}

////////////////////////////////////////////
//	Private Function implementation
////////////////////////////////////////////

////////////////////////////////////////////
//	FindFreeId
////////////////////////////////////////////
short FindFreeId()
{
	short i;
	for (i = 0; i < MAX_CRATE; i++) {
		if (crate_info[i].connected == 0)
			return i;
	}
	return -1;
}

////////////////////////////////////////////
//	BIN_ShowData
////////////////////////////////////////////
void BIN_ShowData(unsigned char *bin_buf, int size)
{
	int i;
	for (i = 0;i < size;i++) 
	   printf("%02x ",bin_buf[i]);
	printf("\n");
}

////////////////////////////////////////////
//	BIN_Response
////////////////////////////////////////////
int BIN_Response(short crate_id, unsigned char *buffer, int size)
{
	int res, pos = 0, stuff = 0;
	short etx_found = 0;
	unsigned char buf;

	while (etx_found == 0) {
		if (crate_info[crate_id].tout_ticks == 0)
			res = csock_recv(crate_info[crate_id].sock_bin, &buf, 1);
		else
			res = csock_recv_t(crate_info[crate_id].sock_bin, &buf, 1, crate_info[crate_id].tout_ticks);
		
		if (res > 0) {
			if (buf == STX) {
				pos = 0;
				stuff = 0;
				buffer[pos++] = buf;
			}
			else if (pos) {
				if (buf == STUFF) {
					stuff = 1;
				}
				else if (buf == ETX) {
					buffer[pos++] = buf;
					etx_found = 1;
				}
				else {
					if (pos < size) {
						if (stuff) {
							buffer[pos++] = buf - 0x80;
						}
						else {
							buffer[pos++] = buf;
						}
					}
					stuff = 0;
				}

			}
		}
		else
			return 0;
	}
	return pos;
}

////////////////////////////////////////////
//	BIN_AdjustFrame
////////////////////////////////////////////
int BIN_AdjustFrame(unsigned char *buff, int lenght)
{
    unsigned char frame[32];
    int i, pos, changed = 0;
    
	pos = 0;
    
	for (i = 0; i < lenght; i++) {
		if (buff[i] == STX) {
			frame[pos] = STUFF;
			pos++;
			frame[pos] = (unsigned char)(0x80 | STX);
			changed = 1;
		}
		else if (buff[i] == ETX) {
			frame[pos] = STUFF;
			pos++;
			frame[pos] = (unsigned char)(0x80 | ETX);	    
			changed = 1;
		}
		else if (buff[i] == STUFF) {
			frame[pos] = STUFF;
			pos++;
			frame[pos] = (unsigned char)(0x80 | STUFF);	    
			changed = 1;
		}
		else
			frame[pos] = buff[i];
		pos++;
    }

    if (changed) {
		for (i = 0; i < pos; i++) {
			buff[i] = frame[i];
		}
    }

    return pos;
}

////////////////////////////////////////////
//	GetParam
////////////////////////////////////////////
short GetParam(char *buffer,PARAMETER *param)
{
   	char *token, seps[] = " \0";
	short cPar = 0;
	if (buffer != NULL) {
		token = strtok(buffer, seps);
		while (token != NULL) {

			strcpy(param[cPar].x,token);
			cPar++;
			token = strtok(NULL, seps);
		}
	}
	return cPar;
}

////////////////////////////////////////////
// IRQ_Handler ***** Separate thread
////////////////////////////////////////////
#ifdef WIN32
DWORD WINAPI IRQ_Handler(void *arg)
#else
void* IRQ_Handler(void *arg)
#endif
{
    short crate_id = *((short *)arg);
    char cmd[256], resp[2];
	short irq_type = 0, res;
	unsigned int irq_data =  0;;
    resp[0] = 'A';
    resp[1] = '\r';
    
    while (crate_info[crate_id].connected) { 
        if (crate_info[crate_id].sock_irq) {
			
			if( csock_canread(crate_info[crate_id].sock_irq)){
				cmd[0] = '\0';
				res = csock_recv(crate_info[crate_id].sock_irq, cmd, 255);
		
				if (res > 0) {
					cmd[res] = '\0';
					if (crate_info[crate_id].irq_callback != NULL) {
						switch (cmd[0]) {
							case 'L':
								irq_type = LAM_INT;
								irq_data = strtoul(&cmd[2], 0, 16);
								break;
							case 'C':
								irq_type = COMBO_INT;
								irq_data = strtoul(&cmd[2], 0, 16);
								break;
							case 'D':
								irq_type = DEFAULT_INT;
								irq_data = strtoul(&cmd[2], 0, 16);
								break;
						}
						crate_info[crate_id].irq_callback((short)crate_id, irq_type, irq_data, crate_info[crate_id].userInfo);
					}
					csock_send(crate_info[crate_id].sock_irq, resp, 2);
				}
				else break;
			}
		}
		else break;
    }
    crate_info[crate_id].irq_tid = 0;
#ifdef WIN32
    return 0;                    
#else
    return NULL;                    
#endif
}

////////////////////////////////////////////
//	Config Function implementation
////////////////////////////////////////////

////////////////////////////////////////////
//	CROPEN
////////////////////////////////////////////
short CROPEN(char *address)
{
#ifdef WIN32
	WSADATA data;
	int ret;
#endif 

	short crate_id;
	
#ifdef WIN32
	if (init_done == 0) {
		ret = WSAStartup(2, &data);
		if (ret) {
			return CRATE_CONNECT_ERROR;
		}
		init_done = 1;
	}
#endif // WIN32
	crate_id = FindFreeId();
	if (crate_id == -1)
		return CRATE_MEMORY_ERROR;

	crate_info[crate_id].connected = 0;

	crate_info[crate_id].sock_ascii = csock_connect(address, CMD_PORT); 
	if (crate_info[crate_id].sock_ascii == 0) return CRATE_CONNECT_ERROR;

	crate_info[crate_id].sock_bin = csock_connect(address, BIN_PORT);
	if (crate_info[crate_id].sock_bin == 0) {
		csock_close(crate_info[crate_id].sock_ascii);
		return CRATE_BIN_ERROR;
	}
	crate_info[crate_id].sock_irq = csock_connect(address, IRQ_PORT); 
	if (crate_info[crate_id].sock_irq == 0) {
		csock_close(crate_info[crate_id].sock_ascii);
		csock_close(crate_info[crate_id].sock_bin);
		return CRATE_IRQ_ERROR;
	}
	
	
	crate_info[crate_id].no_bin_resp = 0;
	crate_info[crate_id].tout_mode = 0;
	crate_info[crate_id].tout_ticks = 0;

	crate_info[crate_id].irq_callback = NULL;
	crate_info[crate_id].irq_tid = 0;

	crate_info[crate_id].connected = 1;

	return crate_id;
}

////////////////////////////////////////////
//	CRCLOSE
////////////////////////////////////////////
short CRCLOSE(short crate_id)
{
	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	if (crate_info[crate_id].connected) {
		if (crate_info[crate_id].sock_ascii) 
			csock_close(crate_info[crate_id].sock_ascii);
		if (crate_info[crate_id].sock_bin)
			csock_close(crate_info[crate_id].sock_bin);
		if (crate_info[crate_id].sock_irq)
			csock_close(crate_info[crate_id].sock_irq);

		crate_info[crate_id].no_bin_resp = 0;
		crate_info[crate_id].tout_mode = 0;
		crate_info[crate_id].tout_ticks = 0;

		crate_info[crate_id].irq_callback = NULL;
		crate_info[crate_id].irq_tid = 0;
		
		crate_info[crate_id].connected = 0;
#ifdef WIN32
		Sleep(1);
#else
		usleep(1000);
#endif
        if(crate_info[crate_id].irq_tid != 0){
#ifdef WIN32
            TerminateThread(crate_info[crate_id].irq_tid, 0);
            CloseHandle(crate_info[crate_id].irq_tid);
#else
            pthread_cancel(crate_info[crate_id].irq_tid);
#endif
        }
	}

	return CRATE_OK;
}

////////////////////////////////////////////
//	CRGET
////////////////////////////////////////////
short CRGET(short crate_id, CRATE_INFO *cr_info)
{
	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;
	
	memcpy(cr_info, &crate_info[crate_id], sizeof(CRATE_INFO));

	return CRATE_OK;
}

////////////////////////////////////////////
//	CRSET
////////////////////////////////////////////
short CRSET(short crate_id, CRATE_INFO *cr_info)
{
	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;
	
	memcpy(&crate_info[crate_id], cr_info, sizeof(CRATE_INFO));

	return CRATE_OK;
}

////////////////////////////////////////////
//	CRTOUT
////////////////////////////////////////////
short CRTOUT(short crate_id, unsigned int tout)
{
	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;
	
	crate_info[crate_id].tout_ticks = tout;

	return CRATE_OK;
}


////////////////////////////////////////////
//	CRIRQ
////////////////////////////////////////////
short CRIRQ(short crate_id, IRQ_CALLBACK irq_callback, unsigned long userInfo)
{
	short retcode = CRATE_OK;
#ifdef WIN32
	DWORD pid;
#endif
	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;
	
	tempId[crate_id] = crate_id;	
	
	crate_info[crate_id].irq_callback = irq_callback;
	crate_info[crate_id].userInfo = userInfo;
	
#ifdef WIN32
	crate_info[crate_id].irq_tid = CreateThread(0, 0, IRQ_Handler, &tempId[crate_id], 0, &pid);
	if(!crate_info[crate_id].irq_tid) {
		retcode = CRATE_IRQ_ERROR;
	}
#else
	pthread_create(&crate_info[crate_id].irq_tid, NULL, &IRQ_Handler, &tempId[crate_id]);
#endif
	return retcode;
}

////////////////////////////////////////////
//	CBINR
////////////////////////////////////////////
short CBINR(short crate_id, short enable_resp)
{
	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	if (enable_resp)
		crate_info[crate_id].no_bin_resp = 0;
	else
		crate_info[crate_id].no_bin_resp = NO_BIN_RESPONSE;
	
	return CRATE_OK;
}

////////////////////////////////////////////
//	ESONE Function implementation
////////////////////////////////////////////

////////////////////////////////////////////
//	CFSA
//  Executes a 24-bit CAMAC command; 
//  returns Q, X and DATA
////////////////////////////////////////////
short CFSA(short crate_id, CRATE_OP *cr_op)
{
    unsigned char bin_cmd[16];
    unsigned char bin_rcv[8] = {0, 0, 0, 0, 0, 0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_CFSA_CMD;
	bin_cmd[2] = cr_op->F;
	bin_cmd[3] = cr_op->N;
	bin_cmd[4] = cr_op->A;
	bin_cmd[5] = (cr_op->DATA & 0xFF);
	bin_cmd[6] = ((cr_op->DATA >> 8) & 0xFF);
	bin_cmd[7] = ((cr_op->DATA >> 16) & 0xFF);
	bin_cmd[8] = crate_info[crate_id].no_bin_resp;

	msgsize = 2;
	msgsize += BIN_AdjustFrame(&bin_cmd[msgsize], 7);
	bin_cmd[msgsize++] = ETX;
	
	//BIN_ShowData(bin_cmd, msgsize);

	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, msgsize) <= 0)
		return CRATE_BIN_ERROR;

	if (crate_info[crate_id].no_bin_resp != NO_BIN_RESPONSE) {
		msgsize = BIN_Response(crate_id, bin_rcv, 8);
		
		//BIN_ShowData(bin_rcv, 8);
		if ((bin_rcv[1] != BIN_CFSA_CMD) || (msgsize != 8))
			return CRATE_BIN_ERROR;

		cr_op->Q    = bin_rcv[2];
		cr_op->X    = bin_rcv[3];
		cr_op->DATA = bin_rcv[4] | (bin_rcv[5] << 8) | (bin_rcv[6] << 16);
	}
	else {
		cr_op->Q    = 0;
		cr_op->X    = 0;
	}

	return CRATE_OK;
}

////////////////////////////////////////////
//	CSSA
//  Executes a 16-bit CAMAC command; 
//  returns Q, X and DATA
////////////////////////////////////////////
short CSSA(short crate_id, CRATE_OP *cr_op)
{
    unsigned char bin_cmd[15];
    unsigned char bin_rcv[7] = {0, 0, 0, 0, 0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_CSSA_CMD;
	bin_cmd[2] = cr_op->F;
	bin_cmd[3] = cr_op->N;
	bin_cmd[4] = cr_op->A;
	bin_cmd[5] = (cr_op->DATA & 0xFF);
	bin_cmd[6] = ((cr_op->DATA >> 8) & 0xFF);
	bin_cmd[7] = crate_info[crate_id].no_bin_resp;

	msgsize = 2;
	msgsize += BIN_AdjustFrame(&bin_cmd[msgsize], 6);
	bin_cmd[msgsize++] = ETX;
	
	//BIN_ShowData(bin_cmd, msgsize);

	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, msgsize) <= 0)
		return CRATE_BIN_ERROR;
	
	if (crate_info[crate_id].no_bin_resp != NO_BIN_RESPONSE) {
		msgsize = BIN_Response(crate_id, bin_rcv, 7);
		
		if ((bin_rcv[1] != BIN_CSSA_CMD) || (msgsize != 7))
			return CRATE_BIN_ERROR;
		
		//BIN_ShowData(bin_rcv, 9);

		cr_op->Q    = bin_rcv[2];
		cr_op->X    = bin_rcv[3];
		cr_op->DATA = bin_rcv[4] | (bin_rcv[5] << 8);
	} 
	else {
		cr_op->Q    = 0;
		cr_op->X    = 0;
	}

	return CRATE_OK;
}

////////////////////////////////////////////
//	CCCZ
//  Generate Dataway Init
////////////////////////////////////////////
short CCCZ(short crate_id)
{
    unsigned char bin_cmd[4];
    unsigned char bin_rcv[3] = {0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_CCCZ_CMD;
	bin_cmd[2] = crate_info[crate_id].no_bin_resp;
	bin_cmd[3] = ETX;

	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, 4) <= 0)
		return CRATE_BIN_ERROR;

	if (crate_info[crate_id].no_bin_resp != NO_BIN_RESPONSE) {
		msgsize = BIN_Response(crate_id, bin_rcv, 3);
		
		if ((bin_rcv[1] != BIN_CCCZ_CMD) || (msgsize != 3))
			return CRATE_BIN_ERROR;
	} 

	return CRATE_OK;
}

////////////////////////////////////////////
//	
//  Generate Crate Clear
////////////////////////////////////////////
short CCCC(short crate_id)
{
    unsigned char bin_cmd[4];
    unsigned char bin_rcv[3] = {0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_CCCC_CMD;
	bin_cmd[2] = crate_info[crate_id].no_bin_resp;
	bin_cmd[3] = ETX;

	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, 4) <= 0)
		return CRATE_BIN_ERROR;

	if (crate_info[crate_id].no_bin_resp != NO_BIN_RESPONSE) {
		msgsize = BIN_Response(crate_id, bin_rcv, 3);
		
		if ((bin_rcv[1] != BIN_CCCC_CMD) || (msgsize != 3))
			return CRATE_BIN_ERROR;
	} 

	return CRATE_OK;
}

////////////////////////////////////////////
//	CCCI
//  Change Dataway Inhibit to specified value 
//  data_in can be 0 or 1
////////////////////////////////////////////
short CCCI(short crate_id, char data_in)
{
    unsigned char bin_cmd[5];
    unsigned char bin_rcv[3] = {0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_CCCI_CMD;
	bin_cmd[2] = data_in;
	bin_cmd[3] = crate_info[crate_id].no_bin_resp;
	bin_cmd[4] = ETX;

	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, 5) <= 0)
		return CRATE_BIN_ERROR;

	if (crate_info[crate_id].no_bin_resp != NO_BIN_RESPONSE) {
		msgsize = BIN_Response(crate_id, bin_rcv, 3);
		
		if ((bin_rcv[1] != BIN_CCCI_CMD) || (msgsize != 3))
			return CRATE_BIN_ERROR;
	} 

	return CRATE_OK;
}

////////////////////////////////////////////
//	CTCI
//  CAMAC test Inhibit; returns 0 or 1
////////////////////////////////////////////
short CTCI(short crate_id, char *res)
{
    unsigned char bin_cmd[3];
    unsigned char bin_rcv[4] = {0, 0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_CTCI_CMD;
	bin_cmd[2] = ETX;

	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, 3) <= 0)
		return CRATE_BIN_ERROR;

	msgsize = BIN_Response(crate_id, bin_rcv, 4);
	
	if ((bin_rcv[1] != BIN_CTCI_CMD) || (msgsize != 4))
		return CRATE_BIN_ERROR;
	
	*res = bin_rcv[2];

	return CRATE_OK;
}

////////////////////////////////////////////
//	CTLM
//  CAMAC test LAM on specified slot = 1..23; 
//  if slot = 0xFF perform a test for any LAM event
////////////////////////////////////////////
short CTLM(short crate_id, char slot, char *res)
{
    unsigned char bin_cmd[5];
    unsigned char bin_rcv[4] = {0, 0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_CTLM_CMD;
	bin_cmd[2] = slot;
	msgsize = 2;
	msgsize += BIN_AdjustFrame(&bin_cmd[msgsize], 1);
	bin_cmd[msgsize++] = ETX;

	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, msgsize) <= 0)
		return CRATE_BIN_ERROR;

	msgsize = BIN_Response(crate_id, bin_rcv, 4);

	if ((bin_rcv[1] != BIN_CTLM_CMD) || (msgsize != 4))
		return CRATE_BIN_ERROR;

	*res = bin_rcv[2];

	return CRATE_OK;
}

////////////////////////////////////////////
//	CCLWT
//  CAMAC wait for LAM on specified slot; 
//  if N = -1 perform a wait for any LAM event
////////////////////////////////////////////
short CCLWT(short crate_id, char slot)
{
    unsigned char bin_cmd[5];
    unsigned char bin_rcv[4] = {0, 0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_CCLWT_CMD;
	bin_cmd[2] = slot;
	msgsize = 2;
	msgsize += BIN_AdjustFrame(&bin_cmd[msgsize], 1);
	bin_cmd[msgsize++] = ETX;

	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, msgsize) <= 0)
		return CRATE_BIN_ERROR;

	msgsize = BIN_Response(crate_id, bin_rcv, 3);

	if ((bin_rcv[1] != BIN_CCLWT_CMD) || (msgsize != 3))
		return CRATE_BIN_ERROR;

	return CRATE_OK;
}

////////////////////////////////////////////
//	CTSTAT
//  Returns Q and X values (from last access on bus)
////////////////////////////////////////////
short CTSTAT(short crate_id, char *Q, char *X)
{
    unsigned char bin_cmd[3];
    unsigned char bin_rcv[5] = {0, 0, 0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_CTSTAT_CMD;
	bin_cmd[2] = ETX;

	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, 3) <= 0)
		return CRATE_BIN_ERROR;

	msgsize = BIN_Response(crate_id, bin_rcv, 5);

	if ((bin_rcv[1] != BIN_CTSTAT_CMD) || (msgsize != 5))
		return CRATE_BIN_ERROR;

	*Q = bin_rcv[2];
	*X = bin_rcv[3];

	return CRATE_OK;
}

////////////////////////////////////////////
//	CLMR
//  Returns current LAM register, in hex
////////////////////////////////////////////
short CLMR(short crate_id, unsigned int *reg)
{
    unsigned char bin_cmd[3];
    unsigned char bin_rcv[7] = {0, 0, 0, 0, 0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_CLMR_CMD;
	bin_cmd[2] = ETX;

	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, 3) <= 0)
		return CRATE_BIN_ERROR;

	msgsize = BIN_Response(crate_id, bin_rcv, 7);
	
	if ((bin_rcv[1] != BIN_CLMR_CMD) || (msgsize != 7))
		return CRATE_BIN_ERROR;
	
	*reg = bin_rcv[2] | (bin_rcv[3] << 8) | (bin_rcv[4] << 16) | (bin_rcv[5] << 24);

	return CRATE_OK;
}

////////////////////////////////////////////
//	CSCAN
//  Returns current slot filled in hex
////////////////////////////////////////////
short CSCAN(short crate_id, unsigned int *scan_res)
{
    unsigned char bin_cmd[3];
    unsigned char bin_rcv[7] = {0, 0, 0, 0, 0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_CSCAN_CMD;
	bin_cmd[2] = ETX;

	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, 3) <= 0)
		return CRATE_BIN_ERROR;

	msgsize = BIN_Response(crate_id, bin_rcv, 7);
	
	if ((bin_rcv[1] != BIN_CSCAN_CMD) || (msgsize != 7))
		return CRATE_BIN_ERROR;
	
	*scan_res = bin_rcv[2] | (bin_rcv[3] << 8) | (bin_rcv[4] << 16) | (bin_rcv[5] << 24);

	return CRATE_OK;
}

////////////////////////////////////////////
//	LACK
//  Performs a LAM Acknowledge
////////////////////////////////////////////
short LACK(short crate_id)
{
    unsigned char bin_cmd[4];
    unsigned char bin_rcv[3] = {0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_LACK_CMD;
	bin_cmd[2] = (crate_info[crate_id].no_bin_resp & 0xFF);
	bin_cmd[3] = ETX;

	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, 4) <= 0)
		return CRATE_BIN_ERROR;

	if (crate_info[crate_id].no_bin_resp != NO_BIN_RESPONSE) {
		msgsize = BIN_Response(crate_id, bin_rcv, 3);
		
		if ((bin_rcv[1] != BIN_LACK_CMD) || (msgsize != 3))
			return CRATE_BIN_ERROR;
	} 

	return CRATE_OK;
}

////////////////////////////////////////////
//	BLKBUFFS
////////////////////////////////////////////
short BLKBUFFS(short crate_id, short value)
{
	//short retcode = CRATE_ERROR;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	sprintf(CRATE_TxBuffer,"BLKBUFFS %d\r", value);
	csock_sendrecvline(crate_info[crate_id].sock_ascii, CRATE_TxBuffer, CRATE_RxBuffer, 255);
	
	return atoi(CRATE_RxBuffer);
}

////////////////////////////////////////////
//	BLKTRANSF
////////////////////////////////////////////
short BLKTRANSF(short crate_id, BLK_TRANSF_INFO *blk_info, unsigned int *buffer)
{
	int i, j, bytes_per_row, bytes_received, bytes_sent, rows;
	int resp = 0;
	short retcode = CRATE_OK;
	char blk_ascii_buf[4096];
	unsigned int row_buf[2048], transf_res;
	//PARAMETER lParam[MAX_PAR];

	if ((crate_id > MAX_CRATE) || (crate_id < 0))			return CRATE_ID_ERROR;
	if (crate_info[crate_id].connected == 0)				return CRATE_CONNECT_ERROR;
	if (BLKBUFFS(crate_id, blk_info->blksize) != CRATE_OK)	return CRATE_ERROR;

	//set up the ascii block transfer command
	switch (blk_info->opcode) {
	
		case OP_BLKSS:
			sprintf(CRATE_TxBuffer,"BLKSS %d %d %d %d", blk_info->F, blk_info->N, blk_info->A, blk_info->totsize);
		break;
		
		case OP_BLKSR:
			sprintf(CRATE_TxBuffer,"BLKSR %d %d %d %d %d", blk_info->F, blk_info->N, blk_info->A, blk_info->totsize, blk_info->timeout);
		break;
		
		case OP_BLKSA:
			sprintf(CRATE_TxBuffer,"BLKSA %d %d %d", blk_info->F, blk_info->N, blk_info->totsize);
		break;
		
		case OP_BLKFS:
			sprintf(CRATE_TxBuffer,"BLKFS %d %d %d %d", blk_info->F, blk_info->N, blk_info->A, blk_info->totsize);
		break;
		
		case OP_BLKFR:
			sprintf(CRATE_TxBuffer,"BLKFR %d %d %d %d %d", blk_info->F, blk_info->N, blk_info->A, blk_info->totsize, blk_info->timeout);
		break;
		
		case OP_BLKFA:
			sprintf(CRATE_TxBuffer,"BLKFA %d %d %d", blk_info->F, blk_info->N, blk_info->totsize);
		break;
		
		default: 
		break;
	}

	switch (blk_info->F >> 3) {
		case 0: //Read Operation

			if (blk_info->ascii_transf == 0) strcat(CRATE_TxBuffer, " bin");
			strcat(CRATE_TxBuffer, "\r");
			buffer[0] = 0;

			csock_sendrecvline(crate_info[crate_id].sock_ascii, CRATE_TxBuffer, CRATE_RxBuffer, 255);
			if (atoi(CRATE_RxBuffer) != CRATE_OK) return CRATE_ERROR;

			if (blk_info->ascii_transf == 0) bytes_per_row = ((blk_info->blksize + 1) * 4);
			else							 bytes_per_row = (4 + (blk_info->blksize * 7));

			rows = (blk_info->totsize / blk_info->blksize) + 1;
			
			if (blk_info->totsize % blk_info->blksize) rows++;

			for (i = 0; i < rows; i++) {
				bytes_received = 0;
				while (bytes_received < bytes_per_row) {
					if (blk_info->ascii_transf == 0) {
						resp = csock_recv(crate_info[crate_id].sock_ascii, (char *)&row_buf[bytes_received], bytes_per_row - bytes_received);
					}
					else {
						resp = csock_recv(crate_info[crate_id].sock_ascii, (char *)&blk_ascii_buf[bytes_received], bytes_per_row - bytes_received);
						blk_ascii_buf[bytes_received + resp] = 0;
					}

					if (resp <= 0) {
						return CRATE_ERROR;
					}
					bytes_received += resp;
				}
				
				if (blk_info->ascii_transf == 0) {
					for (j = 0; j < blk_info->blksize;j++) {
						if (row_buf[0] > 0) {
							buffer[(i * blk_info->blksize) + j] = row_buf[j + 1];
						}
					}
				}
				else {
					for (j = 0; j < blk_info->blksize; j++) {
						if (row_buf[0] > 0) {
							buffer[(i * blk_info->blksize) + j] = strtoul((char *)&blk_ascii_buf[4 + (j * 7)], 0, 16) & 0xFFFFFF;
						}
					}
				}
				
				// Check transfer end
				if (blk_info->ascii_transf == 0) {
					if (row_buf[0] <= 0) {
						blk_info->totsize = row_buf[1];
						retcode = row_buf[0];
						break;
					}
				}
				else {
					transf_res = strtoul((char *)&blk_ascii_buf[0], 0, 10);
					if (transf_res <= 0) {
						blk_info->totsize = (short) strtoul((char *)&blk_ascii_buf[4], 0, 16);
						retcode = (short) transf_res;
						break;
					}
				}
				
			}

			csock_recvline(crate_info[crate_id].sock_ascii, CRATE_RxBuffer, 255);

			break;

		case 2: //Write Operation

			//NOTE: ALWAYS ascii
			strcat(CRATE_TxBuffer, "\r");
			
			//send the block transfer command
			csock_sendrecvline(crate_info[crate_id].sock_ascii, CRATE_TxBuffer, CRATE_RxBuffer, 255);
			printf("%s",CRATE_TxBuffer);
			if (atoi(CRATE_RxBuffer) != CRATE_OK) return CRATE_ERROR;

			
			//each transmitted packet is formatted as hdr %06X %06X .... where hdr is number of values
			int buf_index = 0;
			int numValuesRemaining = blk_info->totsize;
			int numToSend;
			int ccc = 0;
			int t = 0;
			do {			
				if(numValuesRemaining > blk_info->blksize) numToSend = blk_info->blksize;
				else numToSend = numValuesRemaining;
				
				sprintf(&blk_ascii_buf[0], "%03d", numToSend);
				for (j = 0; j < blk_info->blksize; j++) {
					if(j<numToSend) {
						sprintf(&blk_ascii_buf[3 + (j * 7)], " %06X", (buffer[buf_index++] & 0xFFFFFF));
						t++;
					}
					else			sprintf(&blk_ascii_buf[3 + (j * 7)], " 000000");
				}	
				strcat(blk_ascii_buf, "\r");
				
				bytes_sent = 0;
				int bytesToSend = strlen(blk_ascii_buf);
				while (bytes_sent < bytesToSend) {
					resp = csock_send(crate_info[crate_id].sock_ascii, &blk_ascii_buf[bytes_sent], bytesToSend - bytes_sent);
					if (resp < 0)return CRATE_ERROR;
					else if (resp > 0) bytes_sent += resp;
				}
				usleep(100);
				printf("buffer: %d ret: %d  %d/%d\n",ccc,resp,t,blk_info->totsize);
				ccc++;
				
				numValuesRemaining -= numToSend;
			} while(numValuesRemaining>0);
						
			//get a reponse
			csock_recvline(crate_info[crate_id].sock_ascii, CRATE_RxBuffer, 255);
			//the following doesn't appear to follow what actually comes back from the device
			//if (GetParam(CRATE_RxBuffer,lParam)==0) {
			//	retcode = atoi(lParam[0].x);
			//	blk_info->totsize = atoi(lParam[1].x);
			//	printf("total written: %d\n",blk_info->totsize);
			//}

			csock_recvline(crate_info[crate_id].sock_ascii, CRATE_RxBuffer, 255);

		break;
		default:
		break;
	}
	printf("final code: %d\n",retcode);
	return retcode;
}

////////////////////////////////////////////
//	NIM Function implementation
////////////////////////////////////////////

////////////////////////////////////////////
//	NOSOS
//  Nim Out Set Out Single
////////////////////////////////////////////
short NOSOS(short crate_id, char nimo, char value)
{
    unsigned char bin_cmd[8];
    unsigned char bin_rcv[3] = {0, 0, 0};
	short msgsize;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	bin_cmd[0] = STX;
	bin_cmd[1] = BIN_NIM_SETOUTS_CMD;
	bin_cmd[2] = nimo;
	bin_cmd[3] = value;
	bin_cmd[4] = crate_info[crate_id].no_bin_resp;

	msgsize = 2;
	msgsize += BIN_AdjustFrame(&bin_cmd[msgsize], 3);
	bin_cmd[msgsize++] = ETX;

	//BIN_ShowData(bin_cmd, msgsize);
	if (csock_send(crate_info[crate_id].sock_bin, bin_cmd, msgsize) <= 0)	
		return CRATE_BIN_ERROR;

	if (crate_info[crate_id].no_bin_resp != NO_BIN_RESPONSE) {
		msgsize = BIN_Response(crate_id, bin_rcv, 3);
		//BIN_ShowData(bin_rcv, 3);
		if ((bin_rcv[1] != BIN_NIM_SETOUTS_CMD) || (msgsize != 3))
			return CRATE_BIN_ERROR;
	}
	return CRATE_OK;

}

////////////////////////////////////////////
//	CMD Function implementation
////////////////////////////////////////////

////////////////////////////////////////////
//	CMDS
////////////////////////////////////////////
short CMDS(short crate_id, char *cmd, int size)
{
	int res;
	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;
	
	res = csock_send(crate_info[crate_id].sock_ascii, cmd, size);
	if (res)
		return CRATE_OK;
	
	return CRATE_CMD_ERROR;
}

////////////////////////////////////////////
//	CMDR
////////////////////////////////////////////
short CMDR(short crate_id, char *resp, int size)
{
	int res;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	if (crate_info[crate_id].tout_ticks == 0)
		res = csock_recvline(crate_info[crate_id].sock_bin, resp, size);
	else
		res = csock_recvline_t(crate_info[crate_id].sock_bin, resp, size, crate_info[crate_id].tout_ticks);

	if (res >= 0)
		return CRATE_OK;

	return CRATE_CMD_ERROR;
}

////////////////////////////////////////////
//	CMDSR
////////////////////////////////////////////
short CMDSR(short crate_id, char *cmd, char *resp, int size)
{
	int res;

	if ((crate_id > MAX_CRATE) || (crate_id < 0))
		return CRATE_ID_ERROR;

	if (crate_info[crate_id].connected == 0)
		return CRATE_CONNECT_ERROR;

	if (crate_info[crate_id].tout_ticks == 0)
		res = csock_sendrecvline(crate_info[crate_id].sock_ascii, cmd, resp, size);
	else
		res = csock_sendrecvline_t(crate_info[crate_id].sock_ascii, cmd, resp, size, crate_info[crate_id].tout_ticks);

	if (res == 0)
		return CRATE_OK;

	return CRATE_CMD_ERROR;
}
