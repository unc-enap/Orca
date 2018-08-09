/*---------------------------------------------------------------------------
/    SBC_Readout.c
/
/    09/09/07 Mark A. Howe
/    CENPA, University of Washington. All rights reserved.
/    ORCA project
/  ---------------------------------------------------------------------------
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
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <signal.h>
#include "CircularBuffer.h"
#include <pthread.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <net/if.h>   //ifreq
#include "SBC_Readout.h"
#include "HW_Readout.h"
#include "ORVProcess.hh"
#include "readout_code.h"
#include "SBC_Job.h"

#define BACKLOG 1     // how many pending connections queue will hold
#ifndef TRUE
#define TRUE  1
#endif
#ifndef FALSE
#define FALSE 0
#endif

#define kCBBufferSize 1024*1024*64

void* readoutThread (void* p);
void* jobThread (void* p);
void* irqAckThread (void* p);
char startRun (void);
void stopRun (void);
char pauseRun(void);
char resumeRun(void);
void sendRunInfo(void);
void sendErrorInfo(void);
void sendCBRecord(void);
void runCBTest(SBC_Packet* aPacket);
void setPacketOptions(SBC_Packet* aPacket);

/*----globals----*/
char                timeToExit;
SBC_crate_config    crate_config;
SBC_info_struct     run_info;
SBC_error_struct    error_info;
SBC_LAM_info_struct lam_info[kMaxNumberLams];
time_t              lastTime;

pthread_t readoutThreadId;
pthread_t irqAckThreadId;
pthread_attr_t readoutThreadAttr;
pthread_mutex_t runInfoMutex;
pthread_mutex_t lamInfoMutex;
pthread_mutex_t jobInfoMutex;

//the following hw mutex can be turned on in the hardware specific make file
//it is not used by default
#if NeedHwMutex
pthread_mutex_t hwMutex;
#endif

int32_t  workingSocket;
int32_t  workingIRQSocket;
char needToSwap;
uint32_t minCycleTime;

//as the hw is read out, the data is put into the following temp buffer, at the end
//of the readout cycle, it is dumped into the CB
int32_t  dataIndex = 0;
int32_t* data = 0;
int32_t  maxPacketSize;

SBC_JOB	 sbc_job;

/*---------------*/

void sigchld_handler(int32_t s)
{
    while(waitpid(-1, NULL, WNOHANG) > 0);
}

int32_t main(int32_t argc, char *argv[])
{
    signal (SIGPIPE, SIG_IGN); // ignore SIGPIPE
    
    int32_t sockfd,irqfd;                // listen on sock_fd, new connection on workingSocket
    struct sockaddr_in my_addr;            // my address information
    struct sockaddr_in their_addr;        // connector's address information
    socklen_t sin_size;
    struct sigaction sa;
    int32_t yes=1;
    timeToExit = 0;
    maxPacketSize = kSBC_MaxPayloadSizeBytes;
	
    if (argc != 2) {
        exit(1);
    }
    
    int32_t thePort = atoi(argv[1]);
    while(1){
        if ((sockfd = socket(PF_INET, SOCK_STREAM, 0)) == -1) exit(1);
        if ((irqfd  = socket(PF_INET, SOCK_STREAM, 0)) == -1) exit(1);
        
        if (setsockopt(sockfd,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof(int)) == -1) exit(1);
        if (setsockopt(irqfd,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof(int)) == -1)  exit(1);
        
        my_addr.sin_family = AF_INET;         // host byte order
        my_addr.sin_addr.s_addr = INADDR_ANY; // automatically fill with my IP
        memset(my_addr.sin_zero, '\0', sizeof my_addr.sin_zero);
        
        my_addr.sin_port = htons(thePort);     // short, network byte order
        if (bind(sockfd, (struct sockaddr *)&my_addr, sizeof(struct sockaddr))== -1) exit(1);

        my_addr.sin_port = htons(thePort+1);     // short, network byte order
        if (bind(irqfd, (struct sockaddr *)&my_addr, sizeof(struct sockaddr))== -1) exit(1);
        
        if (listen(sockfd, BACKLOG) == -1) exit(1);
        if (listen(irqfd, BACKLOG) == -1 )  exit(1);
        
        sa.sa_handler = sigchld_handler; // reap all dead processes
        sigemptyset(&sa.sa_mask);
        sa.sa_flags = SA_RESTART;
        if (sigaction(SIGCHLD, &sa, NULL) == -1) exit(1);

        FindHardware();
    
        //the order is important here... ORCA will connect with the regular socket first, -then- the irq socket
        sin_size = sizeof(struct sockaddr_in);
        if ((workingSocket    = accept(sockfd, (struct sockaddr *)&their_addr, &sin_size)) == -1) exit(1);
        if ((workingIRQSocket = accept(irqfd, (struct sockaddr *)&their_addr, &sin_size)) == -1) exit(1);
        
        //don't need this socket anymore
        close(sockfd);
        close(irqfd);
    
        //the first word sent is a test word to determine endian-ness
        int32_t testWord;
        needToSwap = FALSE;
        int32_t n = read(workingSocket,&testWord, 4);
        if(n <= 0) return n; //disconnected or error -- exit
        if(testWord == 0xBADC0000) {
            needToSwap = TRUE;
        } else if (testWord != 0x000DCBA) {
            /* Unrecognized service trying to connect? */
            exit(2);
        }
        //end of swap test

        //Note that we don't fork, only one connection is allowed.
        /*-------------------------------*/
        /*initialize our global variables*/
        pthread_attr_init(&readoutThreadAttr);
        pthread_attr_setdetachstate(&readoutThreadAttr, PTHREAD_CREATE_JOINABLE);
        pthread_mutex_init(&runInfoMutex, NULL);
        pthread_mutex_lock (&runInfoMutex);  //begin critical section
        run_info.statusBits        &= ~kSBC_ConfigLoadedMask;  //clr bit
        run_info.statusBits        &= ~kSBC_RunningMask;       //clr bit
        run_info.statusBits        &= ~kSBC_PausedMask;        //clr bit
        run_info.statusBits        &= ~kSBC_ThrottledMask;     //clr bit
        run_info.readCycles         = 0;
        run_info.busErrorCount      = 0;
        run_info.err_count          = 0;
        run_info.msg_count          = 0;
        run_info.err_buf_index      = 0;
        run_info.msg_buf_index      = 0;
        run_info.pollingRate      = 0;
        
        minCycleTime                = 0;
        
        int32_t i;
        for(i=0;i<MAX_CARDS;i++){
            error_info.card[i].busErrorCount = 0;
            error_info.card[i].errorCount    = 0;
            error_info.card[i].messageCount  = 0;
        }

        pthread_mutex_unlock (&runInfoMutex);//end critical section
		
        
        pthread_attr_init(&sbc_job.jobThreadAttr);
        pthread_attr_setdetachstate(&sbc_job.jobThreadAttr, PTHREAD_CREATE_JOINABLE);
		pthread_mutex_init(&jobInfoMutex, NULL);

        
        pthread_mutex_init(&lamInfoMutex, NULL);
        pthread_mutex_lock (&lamInfoMutex);  //begin critical section
        memset(&lam_info ,0,sizeof(SBC_LAM_info_struct)*kMaxNumberLams);
        pthread_mutex_unlock (&lamInfoMutex);//end critical section

#if NeedHwMutex
        pthread_mutex_init(&hwMutex, NULL);
#endif
        /*-------------------------------*/

        data = (int32_t*)malloc(kMaxDataBufferSizeLongs*sizeof(int32_t) + 1024); //test ... add 1K

        SBC_Packet aPacket;
        int32_t numRead = 0;
        while(!timeToExit){
            if (workingSocket < 0 || workingIRQSocket < 0) {
                /* This indicates one of the sockets has been closed, don't continue. */
                break;
            }
            numRead = readBuffer(&aPacket);
            if(numRead == 0) break;
            if (numRead > 0) {
				processBuffer(&aPacket,kReply);
           } else {
              /* if numRead is less than 0, then an error occurred.  We'll try to continue. */
               LogError("Error reading buffer: %s", strerror(errno));
            }
       }
        
        if(run_info.statusBits & kSBC_RunningMask) {
            /* The data process is still running, we need to stop it. */
            /* This generally happens if an error occurs on the Orca side and
                the socket is broken. */
			stopRun();
            /* We should exit, too, as who knows what kind of failures exist. */
            timeToExit=1;
        }
        free(data);
        
        /* Close the open sockets. */
        if (workingSocket >= 0) {
          close(workingSocket);
          workingSocket = -1;
        }
        if (workingIRQSocket >= 0) {
          close(workingIRQSocket);
          workingIRQSocket = -1;
        }

        /* Clean up circular buffer. */
        CB_cleanup();

        /* Take care of pthread variables. */
        pthread_mutex_destroy(&runInfoMutex);
#if NeedHwMutex
        pthread_mutex_destroy(&hwMutex);
#endif
        pthread_attr_destroy(&readoutThreadAttr);
        pthread_mutex_destroy(&jobInfoMutex);
        pthread_attr_destroy(&sbc_job.jobThreadAttr);

        /* This releases hardware. */
        ReleaseHardware();

		/* Calls any generic jobs that have requested notification on socket
         * close. */
		doGenericJobSocketClose();

        /* Test to see if we're exitting completely. */
        if(timeToExit)break;    
    }
    
    
    return 0;
} 

void processBuffer(SBC_Packet* aPacket, uint8_t reply)
{
    /*look at the first word to get the destination*/
    int32_t destination = aPacket->cmdHeader.destination;

    switch(destination){
        case kSBC_Process:
            processSBCCommand(aPacket,reply);
            break;
        default:
#if NeedHwMutex
            pthread_mutex_lock(&hwMutex); //added this missing lock MAH 10/26
#endif

            processHWCommand(aPacket);
            
#if NeedHwMutex
            pthread_mutex_unlock(&hwMutex);
#endif
            break;
    }
}

void processSBCCommand(SBC_Packet* aPacket,uint8_t reply)
{
    switch(aPacket->cmdHeader.cmdID){
        case kSBC_WriteBlock:        
#if NeedHwMutex
           pthread_mutex_lock(&hwMutex);
#endif
            doWriteBlock(aPacket,reply);
#if NeedHwMutex
            pthread_mutex_unlock(&hwMutex);
#endif
            break;
        
        case kSBC_ReadBlock:
#if NeedHwMutex
           pthread_mutex_lock(&hwMutex);
#endif
            doReadBlock(aPacket,reply);
#if NeedHwMutex
            pthread_mutex_unlock(&hwMutex);
#endif
            break;
		
		case kSBC_GeneralWrite:        
#if NeedHwMutex
            pthread_mutex_lock(&hwMutex);
#endif
            doGeneralWriteOp(aPacket,reply);
#if NeedHwMutex
            pthread_mutex_unlock(&hwMutex);
#endif
            break;
        
        case kSBC_GeneralRead:
#if NeedHwMutex
            pthread_mutex_lock(&hwMutex);
#endif
            doGeneralReadOp(aPacket,reply);
#if NeedHwMutex
            pthread_mutex_unlock(&hwMutex);
#endif
            break;
          
        case kSBC_LoadConfig:
            if(needToSwap)SwapLongBlock(aPacket->payload,sizeof(SBC_crate_config)/sizeof(int32_t));
            memcpy(&crate_config, aPacket->payload, sizeof(SBC_crate_config));
            run_info.statusBits    |= kSBC_ConfigLoadedMask;
            break;
			
		case kSBC_CmdBlock:
			processCmdBlock(aPacket);
            break;
			
		case kSBC_TimeDelay:
			processTimeDelay(aPacket,reply);
            break;
			
        case kSBC_MacAddressRequest:
            processMacAddressRequest(aPacket);
            break;
            
        case kSBC_PauseRun:			doRunCommand(aPacket);		break;
        case kSBC_ResumeRun:		doRunCommand(aPacket);		break;
        case kSBC_StartRun:			doRunCommand(aPacket);		break;
        case kSBC_StopRun:          doRunCommand(aPacket);		break;
        case kSBC_SetPollingDelay:	doRunCommand(aPacket);		break;
        case kSBC_RunInfoRequest:   sendRunInfo();				break;
        case kSBC_ErrorInfoRequest: sendErrorInfo();			break;
        case kSBC_CBRead:           sendCBRecord();				break;
		case kSBC_CBTest:			runCBTest(aPacket);			break;
		case kSBC_PacketOptions:	setPacketOptions(aPacket);	break;
		case kSBC_KillJob:			killJob(aPacket);			break;
		case kSBC_JobStatus:		jobStatus(aPacket);			break;
		case kSBC_GenericJob:		doGenericJob(aPacket);		break;
        case kSBC_GetTimeRequest:   sendTime();                 break;
        case kSBC_GetAccurateTime:  sendAccurateTime();         break;

        case kSBC_Exit:             timeToExit = 1;				break;
    }
}

void doRunCommand(SBC_Packet* aPacket)
{
    //future options will be decoded here, are not any so far so the code is commented out
    SBC_CmdOptionStruct* p = (SBC_CmdOptionStruct*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_CmdOptionStruct)/sizeof(int32_t));
    // option1 = p->option[0];
    // option2 = p->option[1];
    //....
    int32_t result = 0;
    if(aPacket->cmdHeader.cmdID == kSBC_StartRun)           result = startRun();
    else if(aPacket->cmdHeader.cmdID == kSBC_StopRun)       stopRun();
	else if(aPacket->cmdHeader.cmdID == kSBC_PauseRun)      result = pauseRun();
	else if(aPacket->cmdHeader.cmdID == kSBC_ResumeRun)     result = resumeRun();
	else if(aPacket->cmdHeader.cmdID == kSBC_SetPollingDelay){
        if(p->option[0]>0){
            minCycleTime = 1E6/p->option[0]; //we got it in Hz, convert to microseconds
            run_info.statusBits &= kSBC_ThrottledMask;     //set bit
            result = p->option[0];
        }
        else {
            minCycleTime = 0;
            run_info.statusBits &= ~kSBC_ThrottledMask;    //clr bit
            result = 0;
        }
        run_info.pollingRate = p->option[0];
    }
    SBC_CmdOptionStruct* op = (SBC_CmdOptionStruct*)aPacket->payload;
    op->option[0] = result;
    if(needToSwap)SwapLongBlock(op,sizeof(SBC_CmdOptionStruct)/sizeof(int32_t));
    sendResponse(aPacket);
}

void killJob(SBC_Packet* aPacket)
{
    aPacket->cmdHeader.cmdID = kSBC_JobStatus;
	
	pthread_mutex_lock (&jobInfoMutex);     //begin critical section
	sbc_job.killJobNow = 1;
    pthread_mutex_unlock (&jobInfoMutex);	//end critical section
	
    pthread_join(sbc_job.jobThreadId, NULL);		//block until job exits -- would be better to have some timout here
													//but if the thread doesn't exit the whole thing is screwed anyway.
	jobStatus(aPacket);
}

void jobStatus(SBC_Packet* aPacket)
{
    aPacket->cmdHeader.cmdID = kSBC_JobStatus;
    SBC_JobStatusStruct* p = (SBC_JobStatusStruct*)aPacket->payload;
 
	pthread_mutex_lock (&jobInfoMutex);                //begin critical section
	p->running		= sbc_job.running;
	p->finalStatus	= sbc_job.finalStatus; 
	p->progress		= sbc_job.progress;
	strncpy(aPacket->message,sbc_job.message,256);
    pthread_mutex_unlock (&jobInfoMutex);             //end critical section

    aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_JobStatusStruct);
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_JobStatusStruct)/sizeof(int32_t));
    if (writeBuffer(aPacket) < 0) { 
        LogError("sendResponse Error: %s", strerror(errno));   
    }
}

void startJob(void(*jobFunction)(SBC_Packet*),SBC_Packet* aPacket)
{
	//----------------------------------------------------------------------------
	//Start a Job, we return a packet immediately with the thread creation status
	//ORCA should check periodically on the job status
	//Another job can not be launched until this one is done.
	//----------------------------------------------------------------------------
	pthread_mutex_lock (&jobInfoMutex);				//begin critical section
	char job_running = sbc_job.running;
	if(!job_running){
		memcpy(&sbc_job.workingPacket,aPacket,sizeof(SBC_Packet));
		sbc_job.running = 1;					
	}
    pthread_mutex_unlock (&jobInfoMutex);          //end critical section
	char started = 0;
	if(!job_running){
        started = !pthread_create(&sbc_job.jobThreadId,&sbc_job.jobThreadAttr, jobThread, jobFunction);
	}
	
    aPacket->cmdHeader.cmdID = kSBC_JobStatus;
    SBC_JobStatusStruct* p = (SBC_JobStatusStruct*)aPacket->payload;
	
	//we load up the fact that the job is done, but ORCA will ask for the status 
	pthread_mutex_lock (&jobInfoMutex);		//begin critical section
	p->running		= started;
	p->finalStatus	= 0; 
	p->progress		= 0;
    pthread_mutex_unlock (&jobInfoMutex);   //end critical section

	jobStatus(aPacket);

}

//---------------------------
//-----Job Thread -----------
//---------------------------
void* jobThread (void* aFunction)
{
	void(*jobFunction)(SBC_Packet*);
	jobFunction = aFunction;
	
    pthread_mutex_lock (&jobInfoMutex);     //begin critical section
    sbc_job.running  = 1;					//should have been set already, but....
	sbc_job.progress = 0;
	sbc_job.killJobNow = 0;
    pthread_mutex_unlock (&jobInfoMutex);   //end critical section
	
	jobFunction(&sbc_job.workingPacket);	//we don't return until done.
	
    pthread_exit((void *) 0);
	
    pthread_mutex_lock (&jobInfoMutex);     //begin critical section
    sbc_job.running  = 0;					
	sbc_job.progress = 100;
	sbc_job.killJobNow  = 0;
	//final status was set by the job
    pthread_mutex_unlock (&jobInfoMutex);   //end critical section
}
//---------------------------
//---------------------------

void sendResponse(SBC_Packet* aPacket)
{
    aPacket->cmdHeader.numberBytesinPayload = sizeof(SBC_CmdOptionStruct);
    
    SBC_CmdOptionStruct* p = (SBC_CmdOptionStruct*)aPacket->payload;        
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_CmdOptionStruct)/sizeof(int32_t));
    if (writeBuffer(aPacket) < 0) { 
        LogError("sendResponse Error: %s", strerror(errno));   
    }
}

void sendRunInfo(void)
{
    SBC_Packet aPacket;
    aPacket.cmdHeader.destination          = kSBC_Process;
    aPacket.cmdHeader.cmdID                = kSBC_RunInfoRequest;
    aPacket.cmdHeader.numberBytesinPayload = sizeof(SBC_info_struct);
    
    SBC_info_struct* runInfoPtr = (SBC_info_struct*)aPacket.payload;

    memcpy(runInfoPtr, &run_info, sizeof(SBC_info_struct));    //make copy

    BufferInfo cbInfo;
    CB_getBufferInfo(&cbInfo);
    runInfoPtr->readIndex      = cbInfo.readIndex;
    runInfoPtr->writeIndex     = cbInfo.writeIndex;
    runInfoPtr->lostByteCount  = cbInfo.lostByteCount;
    runInfoPtr->amountInBuffer = cbInfo.amountInBuffer;
    runInfoPtr->wrapArounds    = cbInfo.wrapArounds;
            
    if(needToSwap)SwapLongBlock(runInfoPtr,kSBC_NumRunInfoValuesToSwap);
    if (writeBuffer(&aPacket) < 0) {
        LogError("sendRunInfo Error: %s", strerror(errno));   
    }

}

void sendErrorInfo(void)
{
    SBC_Packet aPacket;
    aPacket.cmdHeader.destination          = kSBC_Process;
    aPacket.cmdHeader.cmdID                = kSBC_ErrorInfoRequest;
    aPacket.cmdHeader.numberBytesinPayload = sizeof(SBC_error_struct);
    
    SBC_error_struct* errorInfoPtr = (SBC_error_struct*)aPacket.payload;
    
    memcpy(errorInfoPtr, &error_info, sizeof(SBC_error_struct));    //make copy
    
    if(needToSwap)SwapLongBlock(errorInfoPtr,sizeof(SBC_error_struct));
    if (writeBuffer(&aPacket) < 0) {
        LogError("sendErrorInfo Error: %s", strerror(errno));
    }
}

void sendAccurateTime(void)
{
    SBC_Packet aPacket;
    aPacket.cmdHeader.destination          = kSBC_Process;
    aPacket.cmdHeader.cmdID                = kSBC_GetAccurateTime;
    aPacket.cmdHeader.numberBytesinPayload = sizeof(SBC_accurate_time_struct);
    
    SBC_accurate_time_struct* p  = (SBC_accurate_time_struct*)aPacket.payload;
    struct timeval t;
    gettimeofday(&t,NULL);
    p->seconds = t.tv_sec;
    p->microSeconds = t.tv_usec;
    if(needToSwap) SwapLongBlock(p,sizeof(SBC_accurate_time_struct));
    if (writeBuffer(&aPacket) < 0) {
        LogError("sendAccurateTime Error: %s", strerror(errno));
    }
}



void sendTime(void)
{
    SBC_Packet aPacket;
    aPacket.cmdHeader.destination          = kSBC_Process;
    aPacket.cmdHeader.cmdID                = kSBC_GetTimeRequest;
    aPacket.cmdHeader.numberBytesinPayload = sizeof(SBC_time_struct);
    
    SBC_time_struct* p  = (SBC_time_struct*)aPacket.payload;
    time_t seconds      = time(NULL);
    p->unixTime         = (uint32_t)seconds;
    if(needToSwap) SwapLongBlock(p,sizeof(SBC_time_struct));
    if (writeBuffer(&aPacket) < 0) {
        LogError("sendTime Error: %s", strerror(errno));
    }
}

void sendCBRecord(void)
{
    //create an empty packet
    SBC_Packet aPacket;
    aPacket.cmdHeader.destination = kSBC_Process;
    aPacket.cmdHeader.cmdID       = kSBC_CBBlock;
    aPacket.message[0] = '\0';
    aPacket.cmdHeader.numberBytesinPayload    = 0;

    //point to the payload
    int32_t* dataPtr = (int32_t*)aPacket.payload;    
    
    int32_t recordCount = 0;
	
    //put data from the circular buffer into the payload until either, 1)the payload is full, or 2)the CB is empty.
    do {
        int32_t nextBlockSize = CB_nextBlockSize();
        if(nextBlockSize == 0)break;
		if(nextBlockSize > (kSBC_MaxPayloadSizeBytes/sizeof(int32_t))){
			//disaster! Flush the entire CB and notify the user.
			LogError("CB Error: Block too large to ship (flushing)!");   
			CB_flush();
			break;
		}
		if((recordCount == 0) && (nextBlockSize > maxPacketSize/sizeof(int32_t))){
			//adjust the packetsize if needed.
			maxPacketSize = nextBlockSize*sizeof(int32_t);
		}
        if((aPacket.cmdHeader.numberBytesinPayload + nextBlockSize*sizeof(int32_t)) <= maxPacketSize){
            int32_t maxToRead        = (maxPacketSize - aPacket.cmdHeader.numberBytesinPayload)/sizeof(int32_t);
            if(!CB_readNextDataBlock(dataPtr,maxToRead)) break;
            aPacket.cmdHeader.numberBytesinPayload    += nextBlockSize*sizeof(int32_t);
            dataPtr += nextBlockSize;
            recordCount++;
        }
        else break;
    } while (1);
    
    run_info.recordsTransfered        += recordCount;

    if (writeBuffer(&aPacket) < 0) {
        LogError("sendCBRecord Error: %s", strerror(errno));   
    }
}

int32_t readBuffer(SBC_Packet* aPacket)
{ 
    if (workingSocket < 0) return 0; // Socket unavailable
    int32_t numberBytesinPacket;
    int32_t bytesRead = read(workingSocket, &numberBytesinPacket, sizeof(int32_t));
    if(bytesRead<=0) return bytesRead; //disconnected or error, return as such
    if(needToSwap)SwapLongBlock(&numberBytesinPacket,1);    
    aPacket->numBytes = numberBytesinPacket;
    int32_t returnValue = numberBytesinPacket;
    numberBytesinPacket -= sizeof(int32_t);
    char* p = (char*)&aPacket->cmdHeader;
    while(numberBytesinPacket){
        bytesRead = read(workingSocket, p, numberBytesinPacket);
        if(bytesRead <= 0) return bytesRead;    //connection disconnected or error.
        p += bytesRead;
        numberBytesinPacket -= bytesRead;
    }
    if (!(aPacket->cmdHeader.destination == kSBC_Command && 
          aPacket->cmdHeader.cmdID == kSBC_GenericJob )) {
      aPacket->message[0] = '\0';
    }
    if(needToSwap){
        //only swap the size and the header struct
        //the payload will be swapped by the user routines as needed.
        SwapLongBlock((int32_t*)&(aPacket->cmdHeader),sizeof(SBC_CommandHeader)/sizeof(int32_t));
    }

    return returnValue;
}

int32_t writeBuffer(SBC_Packet* aPacket)
{ 
    /* writeBuffer returns -1 if an error.  errno shoulc be set appropriately. */
    if(workingSocket < 0) return -1;
    aPacket->numBytes =  sizeof(int32_t) + sizeof(SBC_CommandHeader) + kSBC_MaxMessageSizeBytes + aPacket->cmdHeader.numberBytesinPayload; 
    int32_t numBytesToSend = aPacket->numBytes;

    if(needToSwap)SwapLongBlock(aPacket,sizeof(SBC_CommandHeader)/sizeof(int32_t)+1);
    char* p = (char*)aPacket;
    while (numBytesToSend) {       
        int32_t bytesWritten = write(workingSocket,p,numBytesToSend);
        /* Negative socket value indicates an error, pass it along. */
        if (bytesWritten <= 0) {
            if (errno == EPIPE) {
                /* Socket was closed mid-write. */
                close(workingSocket);
                workingSocket = -1;
            }
            return -1; 
        }
        p += bytesWritten;
        numBytesToSend -= bytesWritten;
    }
    return numBytesToSend;
}

//----------------------------------------------------------------------------------------------
//writeIRQ, readIRQ... Private functions. Don't call them. They should only be called from the irqAckThread
int32_t writeIRQ(int n)
{ 
    if(workingIRQSocket < 0)     return -1;
    if(n<0 || n>=kMaxNumberLams) return -1;
    
    SBC_Packet* aPacket = &lam_info[n].lam_Packet;
    aPacket->numBytes =  sizeof(int32_t) + sizeof(SBC_CommandHeader) + kSBC_MaxMessageSizeBytes + aPacket->cmdHeader.numberBytesinPayload; 
    int32_t numBytesToSend = aPacket->numBytes; 
    if(needToSwap)SwapLongBlock(aPacket,sizeof(SBC_CommandHeader)/sizeof(int32_t)+1);
    char* p = (char*)aPacket;
    while (numBytesToSend) {       
        int32_t bytesWritten = write(workingIRQSocket,p,numBytesToSend);
        /* Negative socket value indicates an error, pass it along. */
        if (bytesWritten <= 0) { 
            if (errno == EPIPE) {
                /* Socket was closed mid-write. */
                close(workingIRQSocket);
                workingIRQSocket = -1;
            }
            return -1;
        }
        p += bytesWritten;
        numBytesToSend -= bytesWritten;
    }
    return numBytesToSend;
}

int32_t readIRQ(SBC_Packet* aPacket)
{ 
    if (workingIRQSocket < 0) return 0;
    int32_t numberBytesinPacket;
    int32_t bytesRead = read(workingIRQSocket, &numberBytesinPacket, sizeof(int32_t));
    if(bytesRead <= 0) return bytesRead; //disconnected or error
    if(needToSwap)SwapLongBlock(&numberBytesinPacket,1);    
    aPacket->numBytes = numberBytesinPacket;
    numberBytesinPacket -= sizeof(int32_t);
    int32_t returnValue = numberBytesinPacket;
    char* p = (char*)&aPacket->cmdHeader;
    while(numberBytesinPacket){
        bytesRead = read(workingIRQSocket, p, numberBytesinPacket);
        if(bytesRead <= 0) return bytesRead;    //connection disconnected or error.
        p += bytesRead;
        numberBytesinPacket -= bytesRead;
    }
    aPacket->message[0] = '\0';
    if(needToSwap){
        //only swap the size and the header struct
        //the payload will be swapped by the user routines as needed.
        SwapLongBlock((int32_t*)&(aPacket->cmdHeader),sizeof(SBC_CommandHeader)/sizeof(int32_t));
    }

    return returnValue;
}

//----------------------------------------------------------------------------------------------
char startRun (void)
{    
    /*---------------------------------*/
    /* setup the circular buffer       */
    /* and init our run Info struct    */
    /*---------------------------------*/
    CB_initialize(kCBBufferSize);
    time(&lastTime); 
    
    run_info.bufferSize        = kCBBufferSize;
    run_info.readCycles        = 0;
    run_info.recordsTransfered = 0;
    run_info.wrapArounds       = 0;
    run_info.busErrorCount     = 0;
    run_info.err_count         = 0;
    run_info.msg_count         = 0;
    run_info.err_buf_index     = 0;
    run_info.msg_buf_index     = 0;
    int32_t i;
    for(i=0;i<MAX_CARDS;i++){
        error_info.card[i].busErrorCount = 0;
        error_info.card[i].errorCount    = 0;
        error_info.card[i].messageCount  = 0;
    }

    if(run_info.statusBits | kSBC_ConfigLoadedMask){

        initializeHWRun(&crate_config);
        startHWRun(&crate_config);

        if( pthread_create(&readoutThreadId,&readoutThreadAttr, readoutThread, 0) == 0){
            return 1;
        }
        else exit(-1);
        
    }
    else return 0;
}

void stopRun()
{
    pthread_mutex_lock(&runInfoMutex);
    run_info.statusBits        &= ~kSBC_RunningMask;        //clr bit
    run_info.statusBits        &= ~kSBC_PausedMask;			//clr bit
    run_info.statusBits        &= ~kSBC_ConfigLoadedMask;	//clr bit
    pthread_mutex_unlock(&runInfoMutex);

    // block until return
    pthread_join(readoutThreadId, NULL);

    pthread_mutex_lock(&runInfoMutex);
    run_info.readCycles = 0;
    pthread_mutex_unlock(&runInfoMutex);

    stopHWRun(&crate_config);
	commitData();
    cleanupHWRun(&crate_config);
    memset(&crate_config,0,sizeof(SBC_crate_config));
    //CB_cleanup();
}

char pauseRun()
{
    pthread_mutex_lock(&runInfoMutex);
    run_info.statusBits |= kSBC_PausedMask; 
    pthread_mutex_unlock(&runInfoMutex);

	pauseHWRun(&crate_config);
	return 0; //could return something in the future
}

char resumeRun()
{
    pthread_mutex_lock(&runInfoMutex);
    run_info.statusBits &= ~kSBC_PausedMask; 
    pthread_mutex_unlock(&runInfoMutex);

	resumeHWRun(&crate_config);
	return 0; //could return something in the future
}


void postLAM(SBC_Packet* lamPacket)
{
    char needToRunAckThread = 0;
    pthread_mutex_lock (&lamInfoMutex);        //begin critical section
    SBC_LAM_Data* p = (SBC_LAM_Data*)(lamPacket->payload);
    int32_t n = p->lamNumber;
    if(!lam_info[n].isValid){
        if(needToSwap){
            SwapLongBlock((int32_t*)&(p->lamNumber),sizeof(int32_t));
            int32_t num = p->numFormatedWords;
            SwapLongBlock((int32_t*)&(p->numFormatedWords),sizeof(int32_t));
            int32_t i;
            for(i=0;i<num;i++)SwapLongBlock((int32_t*)&(p->formatedWords[i]),sizeof(int32_t));
            num = p->numberLabeledDataWords;
            SwapLongBlock((int32_t*)&(p->numberLabeledDataWords),sizeof(int32_t));
            for(i=0;i<num;i++)SwapLongBlock((int32_t*)&(p->labeledData[i].data),sizeof(int32_t));
        }
        memcpy(&lam_info[n].lam_Packet, &lamPacket, sizeof(SBC_Packet));
        lam_info[n].isValid = TRUE;
        needToRunAckThread = TRUE;
    }
    
    pthread_mutex_unlock (&lamInfoMutex);   //end critical section
    
    if(needToRunAckThread && irqAckThreadId==0){
        if( pthread_create(&irqAckThreadId,NULL, irqAckThread, 0) == 0){
            pthread_detach(irqAckThreadId);
        }
    }
}

void* readoutThread (void* p)
{
    size_t cycles = 0;
    pthread_mutex_lock (&runInfoMutex);                //begin critical section
    run_info.statusBits |= kSBC_RunningMask;        //set bit
    pthread_mutex_unlock (&runInfoMutex);            //end critical section

    dataIndex = 0;
    int32_t index = 0;
    uint32_t statusBits = 0;
    struct timeval ts1;
    struct timeval ts2;
    
    gettimeofday(&ts1,NULL);
    char timeToCycle = 1;
        
    while(((statusBits = run_info.statusBits) & kSBC_RunningMask) != 0) {
        if((statusBits & kSBC_PausedMask) != kSBC_PausedMask){
            if (cycles % 10000 == 0 ) {
                int m_err;
                m_err = pthread_mutex_trylock(&runInfoMutex);  //begin critical section
                if (m_err == 0) {
                    run_info.readCycles = cycles;
                    pthread_mutex_unlock (&runInfoMutex);  //end critical section
                }
                //todo else EBUSY is ok, EINVAL and EFAULT are really bad
            }
            
            if(minCycleTime>0){
                gettimeofday(&ts2,NULL);
                uint32_t timePast = (uint32_t)(((ts2.tv_sec - ts1.tv_sec) + ( ts2.tv_usec - ts1.tv_usec )/1E6) * 1E6);//microseconds
                if(timePast > minCycleTime){
                    ts1         = ts2;
                    timeToCycle = 1;
                }
                else timeToCycle = 0;
            }
            
            
            if(timeToCycle){
#if NeedHwMutex
                pthread_mutex_lock(&hwMutex);
#endif
                index = readHW(&crate_config,index,0); //nil for the lam data
#if NeedHwMutex
                pthread_mutex_unlock(&hwMutex);
#endif
                cycles++;
                commitData();
            }
            
            if(index>=crate_config.total_cards || index<0){
                index = 0;
            }
        }
    }

    pthread_exit((void *) 0);
}

void commitData()
{
	if(dataIndex>0){
		if(needToSwap)SwapLongBlock(data, dataIndex);
		CB_writeDataBlock(data,dataIndex);
		dataIndex = 0;
	}
}

void ensureDataCanHold(int numLongsRequired)
{
	if(dataIndex + numLongsRequired + 1024 >= kMaxDataBufferSizeLongs){
		commitData();
	}
}

void* irqAckThread (void* p)
{
    int i;
    struct timeval tv;
    tv.tv_sec  = 0;
    tv.tv_usec = 1000;
    while(run_info.statusBits & kSBC_RunningMask){
        int busyCount = 0;
        for(i=0;i<kMaxNumberLams;i++){
            if(!lam_info[i].isWaitingForAck && lam_info[i].isValid){
                writeIRQ(i);
                lam_info[i].isWaitingForAck = TRUE;
            }
            if(lam_info[i].isWaitingForAck) busyCount++;
        }
        
        if(busyCount){
            fd_set fds;
            FD_ZERO(&fds);
            FD_SET(workingIRQSocket, &fds);
            
            /* wait until timeout or data received*/
            int  selectionResult = select(workingIRQSocket+1, &fds, NULL, NULL, &tv);
            if(selectionResult > 0){
                SBC_Packet lamAckPacket;
                if(readIRQ(&lamAckPacket) > 0){
                    SBC_LamAckStruct* p = (SBC_LamAckStruct*)lamAckPacket.payload;
                    char numberToAck = p->numToAck; 
                    char* lamPtr = (char*)p++;
                    int n;
                    pthread_mutex_lock (&lamInfoMutex);                //begin critical section
                    for(n=0;n<numberToAck;n++){
                        if(lamPtr[n]>=0 && lamPtr[n]<kMaxNumberLams){
                            int index = lamPtr[n];
                            lam_info[index].isWaitingForAck = FALSE;
                            lam_info[index].isValid            = FALSE;
                        }
                    }
                    pthread_mutex_unlock (&lamInfoMutex);            //end critical section
                }
            }
        }
        else {
            /*nothing waiting to be acked, so exit*/
            break;
        }
    }
    
    irqAckThreadId = 0;
    
    return NULL;
}

void LogMessage (const char *format,...)
{
    if(strlen(format) > kSBC_MaxStrSize*.75) return; //not a perfect check, but it will have to do....

    //we misuse the runInfoMutex to sync threads, on purpose
    pthread_mutex_lock(&runInfoMutex);
    va_list ap;
    va_start (ap, format);
    vsprintf (run_info.messageStrings[run_info.msg_buf_index], format, ap);
    run_info.msg_buf_index = (run_info.msg_buf_index + 1 ) % kSBC_MaxErrorBufferSize;
    run_info.msg_count++;
    va_end (ap);
    pthread_mutex_unlock(&runInfoMutex);
}

void LogError (const char *format,...)
{
    //we misuse the runInfoMutex to sync threads, on purpose
    pthread_mutex_lock(&runInfoMutex);
    va_list ap;
    va_start (ap, format);
	int32_t len = strlen(format);
    if(len > kSBC_MaxStrSize-1) {
		len = kSBC_MaxStrSize-1;
	}
	char finalStr[kSBC_MaxStrSize];
	strncpy(finalStr,format,len);
	finalStr[len] = '\0';
    vsprintf (run_info.errorStrings[run_info.err_buf_index], finalStr, ap);
    run_info.err_buf_index = (run_info.err_buf_index + 1 ) % kSBC_MaxErrorBufferSize;
    run_info.err_count++;
    va_end (ap);
    pthread_mutex_unlock(&runInfoMutex);
}

void LogBusError (const char *format,...)
{
    //we misuse the runInfoMutex to sync threads, on purpose
    pthread_mutex_lock(&runInfoMutex);
    va_list ap;
    va_start (ap, format);
	int32_t len = strlen(format);
    if(len > kSBC_MaxStrSize-1) { 
		len = kSBC_MaxStrSize-1;
	}
	char finalStr[kSBC_MaxStrSize];
	strncpy(finalStr,format,len);
	finalStr[len] = '\0';
    vsprintf (run_info.errorStrings[run_info.err_buf_index], finalStr, ap);
    run_info.err_buf_index = (run_info.err_buf_index + 1 ) % kSBC_MaxErrorBufferSize;
    run_info.err_count++;
    run_info.busErrorCount++;
    va_end (ap);
    pthread_mutex_unlock(&runInfoMutex);
}

void LogMessageForCard (uint32_t card,const char *format,...)
{
    if(strlen(format) > kSBC_MaxStrSize*.75) return; //not a perfect check, but it will have to do....
    
    //we misuse the runInfoMutex to sync threads, on purpose
    pthread_mutex_lock(&runInfoMutex);
    va_list ap;
    va_start (ap, format);
    vsprintf (run_info.messageStrings[run_info.msg_buf_index], format, ap);
    run_info.msg_buf_index = (run_info.msg_buf_index + 1 ) % kSBC_MaxErrorBufferSize;
    run_info.msg_count++;
    error_info.card[card].messageCount++;
    va_end (ap);
    pthread_mutex_unlock(&runInfoMutex);
}

void LogErrorForCard (uint32_t card,const char *format,...)
{
    //we misuse the runInfoMutex to sync threads, on purpose
    pthread_mutex_lock(&runInfoMutex);
    va_list ap;
    va_start (ap, format);
    int32_t len = strlen(format);
    if(len > kSBC_MaxStrSize-1) {
        len = kSBC_MaxStrSize-1;
    }
    char finalStr[kSBC_MaxStrSize];
    strncpy(finalStr,format,len);
    finalStr[len] = '\0';
    vsprintf (run_info.errorStrings[run_info.err_buf_index], finalStr, ap);
    run_info.err_buf_index = (run_info.err_buf_index + 1 ) % kSBC_MaxErrorBufferSize;
    run_info.err_count++;
    error_info.card[card].errorCount++;

    va_end (ap);
    pthread_mutex_unlock(&runInfoMutex);
}

void LogBusErrorForCard (uint32_t card,const char *format,...)
{
    //we misuse the runInfoMutex to sync threads, on purpose
    pthread_mutex_lock(&runInfoMutex);
    va_list ap;
    va_start (ap, format);
    int32_t len = strlen(format);
    if(len > kSBC_MaxStrSize-1) {
        len = kSBC_MaxStrSize-1;
    }
    char finalStr[kSBC_MaxStrSize];
    strncpy(finalStr,format,len);
    finalStr[len] = '\0';
    vsprintf (run_info.errorStrings[run_info.err_buf_index], finalStr, ap);
    run_info.err_buf_index = (run_info.err_buf_index + 1 ) % kSBC_MaxErrorBufferSize;
    run_info.err_count++;
    run_info.busErrorCount++;
    
    error_info.card[card].busErrorCount++;

    va_end (ap);
    pthread_mutex_unlock(&runInfoMutex);
}


/*---------------------------------*/
/*-------Helper Utilities----------*/
/*---------------------------------*/
void SwapLongBlock(void* p, int32_t n)
{
    int32_t* lp = (int32_t*)p;
    int32_t i;
    for(i=0;i<n;i++){
        int32_t x = *lp;
        *lp =  (((x) & 0x000000FF) << 24) |    
               (((x) & 0x0000FF00) <<  8) |    
               (((x) & 0x00FF0000) >>  8) |    
               (((x) & 0xFF000000) >> 24);
        lp++;
    }
}
void SwapShortBlock(void* p, int32_t n)
{
    int16_t* sp = (int16_t*)p;
    int32_t i;
    for(i=0;i<n;i++){
        int16_t x = *sp;
        *sp =  ((x & 0x00FF) << 8) |    
               ((x & 0xFF00) >> 8) ;
        sp++;
    }
}

void setPacketOptions(SBC_Packet* aPacket)
{
    SBC_CmdOptionStruct* p = (SBC_CmdOptionStruct*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_CmdOptionStruct)/sizeof(int32_t));
    maxPacketSize = p->option[0];

	if(maxPacketSize<=0)maxPacketSize = kSBC_MaxPayloadSizeBytes;
	else if(maxPacketSize > kSBC_MaxPayloadSizeBytes)maxPacketSize = kSBC_MaxPayloadSizeBytes;

	p->option[0] = 1;	//response...
    sendResponse(aPacket);
}

void runCBTest(SBC_Packet* aPacket)
{
	char runInProgress = run_info.statusBits & kSBC_RunningMask;
	//send back a response, doesn't really matter what
    SBC_CmdOptionStruct* op = (SBC_CmdOptionStruct*)aPacket->payload;
    op->option[0] = !runInProgress;
    sendResponse(aPacket);

	run_info.bufferSize        = kCBBufferSize;
    run_info.readCycles        = 0;
    run_info.recordsTransfered = 0;
    run_info.wrapArounds       = 0;
	run_info.busErrorCount     = 0;
	run_info.err_count         = 0;
	run_info.msg_count         = 0;
	run_info.err_buf_index     = 0;
	run_info.msg_buf_index     = 0;
	run_info.lostByteCount	   = 0;
	
    struct timeval t;
	gettimeofday(&t, NULL);
	if(!runInProgress){
		//fill the CB
		CB_initialize(kCBBufferSize);
		BufferInfo cbInfo;
		srandom(t.tv_usec);
		while(1){
			dataIndex = 0;
			int i;
			int recordSize = rand() % 2000 + 1;
			data[dataIndex++] = recordSize;
			for(i=1;i<recordSize;i++){
				data[dataIndex++] = i;
			}
			
			if(needToSwap)SwapLongBlock(data, dataIndex);
			
			CB_writeDataBlock(data,dataIndex);
			CB_getBufferInfo(&cbInfo);
			
			if(cbInfo.amountInBuffer >= kCBBufferSize-10000){
				break;
			}
		}
	}
}

void processTimeDelay(SBC_Packet* aPacket,uint8_t reply)
{
	SBC_TimeDelay* p = (SBC_TimeDelay*)aPacket->payload;
    if(needToSwap)SwapLongBlock(p,sizeof(SBC_TimeDelay)/sizeof(int32_t));
	uint32_t sleepTime = p->milliSecondDelay*1000;
	usleep(sleepTime);
	if(reply)sendResponse(aPacket);
}


void processMacAddressRequest(SBC_Packet* aPacket)
{
    aPacket->cmdHeader.cmdID = kSBC_MacAddressRequest;
    SBC_MAC_AddressStruct* p = (SBC_MAC_AddressStruct*)aPacket->payload;
    
    struct ifreq ifr;
    char* iface = "eth0";
    uint32_t fd    = socket(AF_INET, SOCK_DGRAM, 0);
    
    ifr.ifr_addr.sa_family = AF_INET;
    strncpy(ifr.ifr_name , iface , IFNAMSIZ-1);
    
    ioctl(fd, SIOCGIFHWADDR, &ifr);
    
    close(fd);
    
    char* mac = (char*)ifr.ifr_hwaddr.sa_data;
        
    p->macAddress[0] = mac[0];
    p->macAddress[1] = mac[1];
    p->macAddress[2] = mac[2];
    p->macAddress[3] = mac[3];
    p->macAddress[4] = mac[4];
    p->macAddress[5] = mac[5];
    
    
    //no need to swap... just characters
    if (writeBuffer(aPacket) < 0) {
        LogError("Mac Address Error: %s", strerror(errno));
    }

}

void processCmdBlock(SBC_Packet* aPacket)
{
	uint32_t totalBytes = aPacket->cmdHeader.numberBytesinPayload;	//total for all enclosed cmd packets
	uint32_t* theCmdPacket = (uint32_t*)aPacket->payload;
	while(totalBytes>0){
		//might have to swap the first part of the payload which is really a size and an SBC_CommandHeader
		//each cmd payload will be swapped if needed by routines that know how what the contents are 
		if(needToSwap)SwapLongBlock(theCmdPacket,1+sizeof(SBC_CommandHeader)/sizeof(int32_t));
		uint32_t bytesInThisCmd = ((SBC_Packet*)theCmdPacket)->numBytes;
		if(!bytesInThisCmd)break;
		processBuffer((SBC_Packet*)theCmdPacket,kNoReply); //we'll do the reply, so tell them not to.
		//swap back the size and the SBC_CommandHeader
		if(needToSwap)SwapLongBlock(theCmdPacket,1+sizeof(SBC_CommandHeader)/sizeof(int32_t));
		theCmdPacket += bytesInThisCmd/sizeof(uint32_t);
		totalBytes -= bytesInThisCmd;
	}
	//echo the block back as a response
	writeBuffer(aPacket);
}

void initializeHWRun(SBC_crate_config* config)
{
    int32_t index = 0;
    while(index<config->total_cards){
        if (load_card(&config->card_info[index], index) != 1) {
            // Error
        }
        index++;
    }
}

void startHWRun (SBC_crate_config* config)
{    
    int32_t index = 0;
    while(index<config->total_cards){
        if (start_card(index) != 1) {
            // Error
        }
        index++;
    }
}

void pauseHWRun (SBC_crate_config* config)
{    
    int32_t index = 0;
    while(index<config->total_cards){
        if (pause_card(index) != 1) {
            // Error
        }
        index++;
    }
}

int32_t readHW(SBC_crate_config* config,int32_t index, SBC_LAM_Data* lamData)
{
    if(index<config->total_cards && index>=0) {
        return readout_card(index, lamData);
    }
    return -1;
}

void resumeHWRun (SBC_crate_config* config)
{    
    int32_t index = 0;
    while(index<config->total_cards){
        if (resume_card(index) != 1) {
            // Error
        }
        index++;
    }
}

void stopHWRun (SBC_crate_config* config)
{
    int32_t index = 0;
    while(index<config->total_cards){
        if (stop_card(index) != 1) {
            // Error
        }
        index++;
    }
}

void cleanupHWRun (SBC_crate_config* config)
{
    int32_t index = 0;
    while(index<config->total_cards){
        if (remove_card(index) != 1) {
            // Error
        }
        index++;
    }
}

