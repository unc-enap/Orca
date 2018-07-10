/***************************************************************************
    ipe4reader5.h  -  description: header file  for the IPE4 Edelweiss firmware readout loop
    
	history: see *.cpp file

    begin                : Jan 07 2012
    copyright            : (C) 2012 by Till Bergmann, KIT
    email                : Till.Bergmann@kit.edu
 ***************************************************************************/

//This is the version of the IPE4 readout code (display is: version/1000, so cew_controle will e.g. display 1934003 as 1934.003) -tb-

// update 2013-01-03 -tb-

/*--------------------------------------------------------------------
  includes
  --------------------------------------------------------------------*/
  #include <stdint.h>  //for uint32_t etc.

//networking / UDP includes
#include <arpa/inet.h>
#include <netinet/in.h>
//#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <sys/time.h> //for gettimeofday


#if 0 //TODO: remove, moved to ipe4structure.h -tb-
/*--------------------------------------------------------------------
 *    UDP packed definitions
 *       data, IPE crate status  -tb-
 *--------------------------------------------------------------------*/ //-tb-

//size: id + header + 21*16 + UDPFIFOmap + IPmap = (1 + 8 + 336 + 5 + 20) 32-bit words = 1480 bytes
#define MAX_NUM_FLT_CARDS 20
#define IPE_BLOCK_SIZE    16
  //TODO: is also defined in EdelweissSLTv4_HW_Definitions.h, remove one of them -tb-

#define SIZEOF_UDPStructIPECrateStatus 1480

typedef struct{
    //identification
    union {
	    uint32_t		id4;  //packet header: 16 bit id=0xFFD0 + 16 bit reserved
	    struct {
	        uint16_t id0; 
	        uint16_t id1;};
	};
	
    //header
	uint32_t		presentFLTMap;
	uint32_t		reserved0;
	uint32_t		reserved1;
	
	//SLT info (16 words)
	uint32_t    SLT[IPE_BLOCK_SIZE];                   //one 16 word32 block for the SLT

    //FLT info (20x16 = 320 words)
	uint32_t    FLT[MAX_NUM_FLT_CARDS][IPE_BLOCK_SIZE];//twenty FLTs, one 16 word32 block per each FLT
    
    //IP Adress Map (20 words)
	uint32_t		IPAdressMap[MAX_NUM_FLT_CARDS];    //IP address map associated to the according SLT/HW FIFO
    //Port Map      (10 words)
	uint16_t		PortMap[MAX_NUM_FLT_CARDS];        //IP address map associated to the according SLT/HW FIFO
}
UDPStructIPECrateStatus;


UDPStructIPECrateStatus IPECrateStatusPacket;


//struct def of UDPStructIPECrateStatus in human readable format
//----------------------------------------------------------------
typedef struct{
    uint32_t  SLTControlReg;
    uint32_t  SLTStatusReg;
    uint32_t  SLTVersionReg;
    uint32_t  SLTPixbusEnableReg;
    uint32_t  SLTTimeLowReg;
    uint32_t  SLTTimeHighReg;
    uint32_t  word6;
    uint32_t  word7;
    uint32_t  word8;
    uint32_t  word9;
    uint32_t  word10;
    uint32_t  word11;
    uint32_t  word12;
    uint32_t  word13;
    uint32_t  word14;
    uint32_t  word15;
}
SLTBlock;

typedef struct{
    uint32_t  FLTStatusReg;
    uint32_t  FLTControlReg;
    uint32_t  FLTVersionReg;
    uint32_t  FLTFiberSet_1Reg;
    uint32_t  FLTFiberSet_2Reg;
    uint32_t  FLTStreamMask_1Reg;
    uint32_t  FLTStreamMask_2Reg;
    uint32_t  FLTTriggerMask_1Reg;
    uint32_t  FLTTriggerMask_2Reg;
    uint32_t  word9;
    uint32_t  word10;
    uint32_t  word11;
    uint32_t  word12;
    uint32_t  word13;
    uint32_t  word14;
    uint32_t  word15;
}
FLTBlock;



typedef struct{
	uint16_t id0;   //=0xFFD0
	uint16_t id1;
	
    //header
	uint32_t		presentFLTMap;
	uint32_t		reserved0;
	uint32_t		reserved1;
	
	
	//SLT info
	SLTBlock    SLT;            //one 16 word32 block for the SLT

    //FLT info
	FLTBlock    FLT[MAX_NUM_FLT_CARDS];//twenty FLTs, one 16 word32 block per each FLT
    
    
    //IP Adress Map (20 words)
	uint32_t		IPAdressMap[MAX_NUM_FLT_CARDS];    //IP address map associated to the according SLT/HW FIFO
    //Port Map      (10 words)
	uint16_t		PortMap[MAX_NUM_FLT_CARDS];        //IP address map associated to the according SLT/HW FIFO
    
}
UDPStructIPECrateStatus2;


#endif








/*--------------------------------------------------------------------
 *    function prototypes
 *        
 *--------------------------------------------------------------------*/ //-tb-
int sendChargeBBStatus(uint32_t prog_status,int numFifo);
void chargeBBWithFile(char * filename, int fromFifo=-1);
void handleKCommand(char *buffer, int len, struct sockaddr_in *sockaddr_from, int fromFifo=-1);
int readConfigFile(char *filename);
int parseConfigFileLine(char *line, int flags=0);
#define kCheckFIFOREADERState 0x00000001

/*--------------------------------------------------------------------
  globals and functions for hardware access
  --------------------------------------------------------------------*/
  //this is for the global K command UDP server (write requests) and the client (read requests)
	//open port to listen for / server port
	//    use netcat to test the commans: eg. nc -u 192.168.1.105 9940
	//    means: connect to crate with IP 192.168.1.105 listening on port 9940;
	//    now type any string in the netcat console, it will be sent to the crate
	int  GLOBAL_UDP_SERVER_SOCKET=-1;
	int  GLOBAL_UDP_SERVER_PORT=9940;
	char  GLOBAL_UDP_SERVER_IP_ADDR[1024]="0.0.0.0";
	uint32_t  GLOBAL_UDP_SERVER_IP=0;
    struct sockaddr_in GLOBAL_servaddr;
    struct sockaddr_in sockaddr_from;
    socklen_t sockaddr_fromLength;
    
	//open port to write for / client port
	int  GLOBAL_UDP_CLIENT_SOCKET;
	int  GLOBAL_UDP_CLIENT_PORT=9940;
	char  GLOBAL_UDP_CLIENT_IP_ADDR[1024]="0.0.0.0";
	uint32_t  GLOBAL_UDP_CLIENT_IP;
    //struct sockaddr_in GLOBAL_clientaddr;
    struct sockaddr_in GLOBAL_sockaddrin_to;
    socklen_t  GLOBAL_sockaddrin_to_len;//=sizeof(GLOBAL_sockin_to);
    
    struct sockaddr sock_to;
    int sock_to_len;//=sizeof(si_other);

//static client ----------
// not used any more ...
  //struct sockaddr_in si_other;
  //int si_other_len;//=sizeof(si_other);

//states for FifoReader: FifoReaderState
enum FIFOREADERSTATE {
    frUNDEF       = 0,
    frIDLE        = 1,
    frINITIALIZED = 2,
    frSTREAMING   = 3
 };
 
//bitmasks for some registers
const int kVetoFlagMask =    0x80000000;
const int kFiberEnableMask = 0x003f0000;  //TODO: make global!!! -tb-
const int kFLTModeMask =     0x00000030;  //TODO: make global!!! -tb-
const int kFLTtpixMask =     0x00000040;  //TODO: make global!!! -tb-
const int kBBversionMask =   0x00003f00;  //TODO: make global!!! -tb-

// aux definitions
uint32_t bit0  = 0x00000001;
uint32_t bit1  = 0x00000002;
uint32_t bit2  = 0x00000004;
uint32_t bit3  = 0x00000008;
uint32_t bit4  = 0x00000010;
uint32_t bit5  = 0x00000020;
uint32_t bit6  = 0x00000040;
uint32_t bit7  = 0x00000080;
uint32_t bit8  = 0x00000100;
uint32_t bit9  = 0x00000200;
uint32_t bit10 = 0x00000400;
uint32_t bit11 = 0x00000800;
uint32_t bit12 = 0x00001000;
uint32_t bit13 = 0x00002000;
uint32_t bit14 = 0x00004000;
uint32_t bit15 = 0x00008000;

uint32_t bit16 = 0x00010000;
uint32_t bit17 = 0x00020000;
uint32_t bit18 = 0x00040000;
uint32_t bit19 = 0x00080000;
uint32_t bit20 = 0x00100000;
uint32_t bit21 = 0x00200000;
uint32_t bit22 = 0x00400000;
uint32_t bit23 = 0x00800000;
uint32_t bit24 = 0x01000000;
uint32_t bit25 = 0x02000000;
uint32_t bit26 = 0x04000000;
uint32_t bit27 = 0x08000000;
uint32_t bit28 = 0x10000000;
uint32_t bit29 = 0x20000000;
uint32_t bit30 = 0x40000000;
uint32_t bit31 = 0x80000000;

uint32_t bit[32] = {
   0x00000001,
   0x00000002,
   0x00000004,
   0x00000008,
   0x00000010,
   0x00000020,
   0x00000040,
   0x00000080,
   0x00000100,
   0x00000200,
   0x00000400,
   0x00000800,
   0x00001000,
   0x00002000,
   0x00004000,
   0x00008000,

   0x00010000,
   0x00020000,
   0x00040000,
   0x00080000,
   0x00100000,
   0x00200000,
   0x00400000,
   0x00800000,
   0x01000000,
   0x02000000,
   0x04000000,
   0x08000000,
   0x10000000,
   0x20000000,
   0x40000000,
   0x80000000,
};

    /*--------------------------------------------------------------------
      functions:
      --------------------------------------------------------------------*/
void StopSLTFIFO();
void InitHardwareFIFOs(int warmStart=0);
      
      
    /*--------------------------------------------------------------------
      classes:
      --------------------------------------------------------------------*/
const int ascii=0, binary=1;
	const int buflen=30000;
	char buf_status284[buflen];
	int buf_status284_len=0;
	const uint32_t Preferred_FIFObuf8len = 1200016 * 2 * 6 * 20;  //1200000 = max. number of ADC data in 1 sec (BB2) + 4 x word32 (sec strobe pattern); ... 
	                                                              //1200000 on one fiber per sec; 6 fibers per FLT; 20 FLTs per crate; 2 - some spare space in buffer
                                                                


    #if 0 //is now member of class FIFOREADER - remove -tb-
	const uint32_t FIFObuf8len =  1200016 * 2 * 6 * 20;  //1200000 = max. number of ADC data in 1 sec (BB2) + 4 x word32 (sec strobe pattern)
	                                                    //1200000 on one fiber per sec; 6 fibers per FLT; 20 FLTs per crate; 2 - some spare space in buffer
	const uint32_t FIFObuf16len = FIFObuf8len / 2;
	const uint32_t FIFObuf32len = FIFObuf8len / 4;
    #endif

	const uint32_t FIFOBlockSize = 8 * 1024; //TODO: FIFOBlockSize: <------ adjust to your needs; later go to 8192 (the maximum) -tb- 

class FIFOREADER{
public:
    //ctor
    FIFOREADER(){
	    initVars();
	}
    
    //destructor not implemented ...
    //TODO: dealloc FIFObuf8; ...
	
	//FIFO data handling
	void readFIFOtoFIFObuffer(void);
    void scanFIFObuffer(void);	
    int rereadNumADCsInDataStream();
    int fifoReadsFLTIndex(int fltIndex);
    int openAsciiFile(int udpdataSec, int write2file_len_sec);
    int openBinaryFile(int utc, int write2file_len_sec);
    int writeToAsciiFile(const char *buf, size_t n, int udpdataSec);
	
	//UDP packet handling
	void addUDPClient(int port,int numRequestedPackets);
    void endUDPClientSockets();
    static void endAllUDPClientSockets();
    int initUDPClientSocket(void);
    int sendtoClient(const void *buffer, size_t length);
	void endUDPClientSocket(void);
    int sendtoUDPClients(int flag, const void *buffer, size_t length);

    int initUDPServerSocket(void);
    int myUDPServerSocket(void);
    int isConnectedUDPServerSocket(void);
    int recvfromServer(unsigned char *readBuffer, int maxSizeOfReadbuffer);
    void endUDPServerSocket(void);
    static void initAllUDPServerSockets(void);
    static void endAllUDPServerSockets(void);

	
	void initVars(){//called from the ctor!
		//globals for config file options
		readfifo=0;  //set to 1 to activate readout
		numfifo=0;   //my index
	    //show_debug_info=0;
        isWaitingToClearAfterDelay=0;// ... 0 = not waiting
		
		write2file=0;  // 0 = don't write to file; 1 = write file
		write2file_len_sec=5;
		write2file_format=0;
		pFile =0;
		
        AddrLength = 0;
		
        MY_UDP_SERVER_SOCKET = -1;
		MY_UDP_SERVER_IP = INADDR_ANY;
		strcpy(MY_UDP_SERVER_IP_ADDR, "0.0.0.0");
	    NB_CLIENT_UDP=0;		
	    
	    //int		numPacketsClient[_nb_max_clients_UDP] = {0,0,0,0,0,0,0,0,0,0,    0,0,0,0,0,0,0,0,0,0};
	    //int		status_client[_nb_max_clients_UDP]    = {0,0,0,0,0,0,0,0,0,0,    0,0,0,0,0,0,0,0,0,0};
	    for(int i=0; i<_nb_max_clients_UDP; i++){ numPacketsClient[i]=0; status_client[i]=0; }
		
		
		//'static' client, configured in the config file
		use_static_udp_client = 0;
        //static client ----------
        //struct sockaddr_in si_other;
		si_other_len=sizeof(si_other);
        
		max_udp_size_config = 1444;
        
		send_status_udp_packet = 1;
		skip_num_status_bits = 0; //skip this number of status bits (we observed offsets between 0 and 2)
		
		//for use of dummy status bits
		use_dummy_status_bits = 0;
		
        //init with 0
	    FIFObuf8 = (char *)0;
	    FIFObuf16 = (uint16_t *)FIFObuf8;
	    FIFObuf32 = (uint32_t *)FIFObuf8;
        FIFObuf8len = 0;
        FIFObuf16len = FIFObuf8len / 2;
        FIFObuf32len = FIFObuf8len / 4;
	    popIndexFIFObuf32=0;
	    pushIndexFIFObuf32=0;
	    FIFObuf32avail=0;
	    FIFObuf32counter=0;
	    FIFObuf32counterlast=0;
        synchroWordPosHint=0;

        //maxUdpDataPacketSize = 1444; static const 
        defaultUdpDataPacketSize = 1444;
	    udpdata16 = (uint16_t *)udpdata;
	    udpdata32 = (uint32_t *)udpdata;
	    udpdataCounter = 0;
		udpdataSec     = 0;
	    numSent = 0;
        udpdataByteCounter	 = 0;
        numADCsInDataStream =0;
	
	    globalHeaderWordCounter = 0; //TODO: globalHeaderWordCounter for testing -tb- 
		
	    mon_indice_status_bbv2 = 0;// <----   each FIFO (in multi-FIFO readout) needs own counter!

	    flagToSendDataAndResetBuffer = 0;//TODO: remove it, unused -tb-
        waitingForSynchroWord = 0;       //TODO: still needed? -tb-

        isSynchronized = 0;
	}
	
    
    int allocateFIFOBufferBytes(uint32_t preferredSizeInBytes){
        if(FIFObuf8len>0 || FIFObuf8!=NULL){
            printf("FIFOREADER::allocateFIFOBufferBytes: WARNING - buffer for FIFO %i already allocated!\n",numfifo);
            return FIFObuf8len;
        }
        
		//FIFO buffer in RAM (malloc: request space; if failed try to alloc the half of this space etc. )
        //old:  uint32_t  i,size=Preferred_FIFObuf8len;
        uint32_t  i,size=preferredSizeInBytes;
        for(i=0;i<10;i++){// try to allocate preferred memory; whwn failed, try to allocate the half size - up to ten tries
                printf("FIFOREADER::allocateFIFOBufferBytes: try to allocate %u byte (of %u requested bytes)\n",size, Preferred_FIFObuf8len);
	        FIFObuf8=(char *)malloc(sizeof(char)*size);
            if(FIFObuf8==NULL){//failed
                size = size/2;
                size = (size/4)*4;//multiple of 4 as we want to store uint32_t's
                if(size==0){ printf("FIFOREADER::allocateFIFOBufferBytes: ERROR: Failed with malloc(...), exiting!\n"); exit(123); }
            }else{//success
                printf("FIFOREADER::allocateFIFOBufferBytes: allocated %u byte (of %u requested bytes) for FIFO %i - OK\n",size, Preferred_FIFObuf8len,numfifo);
                FIFObuf8len=size;
                if(size<0x10000){ printf("WARNING:   !!! allocated memory is <65536; BUFFER (probably) TOO SMALL!!\n"); /*exit(123);*/ }
                break;
            }
        }
	    FIFObuf16 = (uint16_t *)FIFObuf8;
	    FIFObuf32 = (uint32_t *)FIFObuf8;
        FIFObuf16len = FIFObuf8len / 2;
        FIFObuf32len = FIFObuf8len / 4;
	    popIndexFIFObuf32=0;
	    pushIndexFIFObuf32=0;
	    FIFObuf32avail=0;
	    FIFObuf32counter=0;
	    FIFObuf32counterlast=0;
        synchroWordPosHint=0;
        
        return FIFObuf8len;
    }
    
    
	//FIFOREADER as state machine: the state
    static int	State;
     
	//globals for config file options
	int readfifo;
	int numfifo;
	//int simulation_send_dummy_udp;
	//int run_main_readout_loop; is global!
	//int show_debug_info;
    
    //handle dely between FIFO disable and FIFO clear (reset pointers mres, pres) command
    int isWaitingToClearAfterDelay;//need to wait 1 sec between FIFO disable and FIFO clear (WARNING: otherwise shuffling may occur 2014-11) -tb-
	struct timeval timeOfDisableFIFOcmd;
    
    
	int write2file;  // 0 = don't write to file; 1 = write file
	int write2file_len_sec;
	int write2file_format;
	FILE * pFile ;
	
	
	//open port to listen for / server port
	int  MY_UDP_SERVER_SOCKET;
	int  MY_UDP_SERVER_PORT;
	uint32_t  MY_UDP_SERVER_IP; //obsolete, use MY_UDP_SERVER_IP_ADDR 
	char MY_UDP_SERVER_IP_ADDR[1024];
    struct sockaddr_in servaddr;
    socklen_t AddrLength;
	
    // 'dynamic' clients ----------
	int		NB_CLIENT_UDP;							//  serveur UDP
	//_nb_max_clients_UDP defined in structure.h, default: 20
	int		UDP_CLIENT_SOCKET[_nb_max_clients_UDP];
	struct	sockaddr_in clientaddr_list[_nb_max_clients_UDP];
	int		numPacketsClient[_nb_max_clients_UDP];// = {0,0,0,0,0,0,0,0,0,0,    0,0,0,0,0,0,0,0,0,0};
	int		status_client[_nb_max_clients_UDP];//    = {0,0,0,0,0,0,0,0,0,0,    0,0,0,0,0,0,0,0,0,0};
	
	//'static' client, configured in the config file (DEPRECATED, use dynamic client)
	int  use_static_udp_client;
	int		MY_UDP_CLIENT_SOCKET;
	struct	sockaddr_in cliaddr;
	char MY_UDP_CLIENT_IP[1024];
	int  MY_UDP_CLIENT_PORT;
	//used in initUDPClientSocket, sendtoClient: could use local vars? -tb-
    struct sockaddr_in si_other;
    int si_other_len;//=sizeof(si_other);
	
	
	int max_udp_size_config;  //max. size of UDP (data) packet: default 1444; 0=default; -1=automatic detection ("only send full samples in one packet"); 
                              //                                other values: use exactly this value, take 4 byte header into account
	int skip_num_status_bits; //skip this number of status bits (we observed offsets between 0 and 2)

	int send_status_udp_packet;
	
	
	//for use of dummy status bits
	int use_dummy_status_bits;
	
	
	Structure_trame_status Trame_status_udp; //this is the deprecated OPERA status packet -tb- 2013
	
	/*--------------------------------------------------------------------
	 vars and functions for FIFO buffer
	 --------------------------------------------------------------------*/
    static int isConnectedUDPServerSocketForFIFO(int i){
        if(i>=0 && i<FIFOREADER::availableNumFIFO){ 
            return FIFOREADER::FifoReader[i].isConnectedUDPServerSocket();
        }
        return 0;
    }
    
    static int initUDPServerSocketForFIFO(int i){
        if(i>=0 && i<FIFOREADER::availableNumFIFO){ 
            return FIFOREADER::FifoReader[i].initUDPServerSocket();
        }
        return 0;
    }
    
    
    static void startFIFO(int i){
        if(i>=0 && i<FIFOREADER::availableNumFIFO){ 
            if(FIFOREADER::FifoReader[i].readfifo){
                //FIFO i is already running
                printf("WARNING:   FIFO %i already running!\n",i);
            }
            else
            {
                FifoReader[i].readfifo=1;
                //FifoReader[i].allocateFIFOBufferBytes(Preferred_FIFObuf8len);//allocateFIFOBufferBytes or initBuffer ...
                FifoReader[i].initBuffer();
                FifoReader[i].clearFifoBuf32();
                FifoReader[i].resetSynchronizingAndPackaging();
            }
        }
    }
    
    static int isRunningFIFO(int i){
        if(i>=0 && i<FIFOREADER::availableNumFIFO){ 
            return FifoReader[i].readfifo;
        }
        return 0;
    }
    
    static void stopFIFO(int i){
        if(i>=0 && i<FIFOREADER::availableNumFIFO){ 
            if(!FIFOREADER::FifoReader[i].readfifo){
                //FIFO i is not running
                printf("WARNING:  FIFOREADER::stopFIFO: FIFO %i is not running!\n",i);
            }
            else
            {
                FifoReader[i].clearFifoBuf32();
                FifoReader[i].resetSynchronizingAndPackaging();
                FifoReader[i].freeBuffer();
                FifoReader[i].readfifo=0;
            }
        }
    }
    
    static void markFIFOforClearAfterDelay(int i){
        if(i>=0 && i<FIFOREADER::availableNumFIFO){ 
            FifoReader[i].isWaitingToClearAfterDelay = 1;
            gettimeofday(&FifoReader[i].timeOfDisableFIFOcmd,NULL);
        }
    }

    static void unmarkFIFOforClearAfterDelay(int i){
        if(i>=0 && i<FIFOREADER::availableNumFIFO){ 
            FifoReader[i].isWaitingToClearAfterDelay = 0;
            gettimeofday(&FifoReader[i].timeOfDisableFIFOcmd,NULL);
        }
    }

    static int isMarkedToClearAfterDelay(int i){
        if(i>=0 && i<FIFOREADER::availableNumFIFO)
            return FifoReader[i].isWaitingToClearAfterDelay;
        return 0;
    }

    static int64_t usecElapsedDelaySinceMarkToClear(int i){
        if(!  (i>=0 && i<FIFOREADER::availableNumFIFO))  return 0;
        int64_t timeDiff=0;
        struct timeval now;
        gettimeofday(&now,NULL);
        timeDiff = (now.tv_usec - FifoReader[i].timeOfDisableFIFOcmd.tv_usec) + (now.tv_sec - FifoReader[i].timeOfDisableFIFOcmd.tv_sec)*1000000;
        
        return timeDiff;
    }


    static void resetAllSynchronizingAndPackaging(){
        int i=0;
        for(i=0; i<FIFOREADER::availableNumFIFO; i++) 
            if(FIFOREADER::FifoReader[i].readfifo) FIFOREADER::FifoReader[i].resetSynchronizingAndPackaging();
    }
    
    static void clearAllFifoBuf32(){
        int i=0;
        for(i=0; i<FIFOREADER::availableNumFIFO; i++) 
            if(FIFOREADER::FifoReader[i].readfifo) FIFOREADER::FifoReader[i].clearFifoBuf32();
    }
    
    void resetSynchronizingAndPackaging(){
        isSynchronized = 0;
        udpdataCounter = 0;
    }
    
    void clearFifoBuf32(){
        waitingForSynchroWord = 0;
        synchroWordPosHint=0;
	    popIndexFIFObuf32=0;
	    pushIndexFIFObuf32=0;
	    FIFObuf32avail=0;
	    //FIFObuf32counter;     //TODO: needs check -tb-
	    //FIFObuf32counterlast; //TODO: needs check -tb-
        
   		udpdataByteCounter=0;//TODO: belongs this to the sw buffer?
    }
    
    int pushFifoBuf32(uint32_t *data, int len){//append data to FIFO buffer
        int i;
        //TODO: 1) check: enough memory available?
        //TODO: 2) make circular buffer
        for(i=0;i<len;i++){
            FIFObuf32[pushIndexFIFObuf32+i]=data[i];
        }
        pushIndexFIFObuf32+=len;
        return 0;
    }
    uint32_t* ptrToFifoBufPushPos32(){
        return &FIFObuf32[pushIndexFIFObuf32]; 
    }
    
	uint32_t FIFObuf8len;// see Preferred_FIFObuf8len
	uint32_t FIFObuf16len;// = FIFObuf8len / 2;
	uint32_t FIFObuf32len;// = FIFObuf8len / 4;

	//char * FIFObuf8[FIFObuf8len];
	char * FIFObuf8;
	uint16_t * FIFObuf16;// = (int16_t *)FIFObuf8;
	uint32_t * FIFObuf32;// = (int32_t *)FIFObuf8;
	uint32_t popIndexFIFObuf32;
	uint32_t pushIndexFIFObuf32;
	uint32_t FIFObuf32avail;
	int64_t FIFObuf32counter;
	int64_t FIFObuf32counterlast;
	//synchro word (is the header/"magic pattern"/0x3117/mot synchro which is written to the data stream every 1 second)
	int32_t synchroWordPosHint; //TODO: globalHeaderWordCounter for testing -tb- 
	int32_t synchroWordBufferPosHint; //TODO: globalHeaderWordCounter for testing -tb- 
    
	uint32_t globalHeaderWordCounter; //TODO: globalHeaderWordCounter for testing -tb- (header is the "magic pattern"/0x3117/mot synchro)
	
	//scanning status bits
	int mon_indice_status_bbv2;// <----   each FIFO (in multi-FIFO readout) needs own counter! //TODO: obsolete, remove! -tb-
    
    //misc vars
    int flagToSendDataAndResetBuffer;//TODO: obsolete - unused - remove flagToSendDataAndResetBuffer everywhere-tb-
    int waitingForSynchroWord;
    int isSynchronized; //means: has received a TS pattern in the data stream (will be set to false e.g. at start/stop StreamLoop)
	
	/*--------------------------------------------------------------------
	 vars for UDP packets
	 --------------------------------------------------------------------*/
	
	//global vars for udp packet handling
    static const int maxUdpDataPacketSize = 1444;//max, packet size (to avoid UDP packed splitting, must be <1480!, 1444 to be on the safe side)
    int defaultUdpDataPacketSize;//packet size (variable, must be <1480!)
	static const int udpdatalen = 2*1500;//buffer size
	char udpdata[udpdatalen];
	uint16_t *udpdata16;// = (int16_t *)udpdata;
	uint32_t *udpdata32;// = (int32_t *)udpdata;
	int udpdataCounter; //counts number of sent UDP packets
	int udpdataByteCounter; //counts number of bytes of sent UDP packets
	int udpdataSec ;    //second got from pattern 0x31170000....
	int numSent ;
    int numADCsInDataStream;
	

    void setUdpDataPacketSize(int size){
        defaultUdpDataPacketSize=size;
        if(defaultUdpDataPacketSize %4 != 0) printf("ERROR: setUdpPacketSize: must be multiple of 4!\n");
    }
    void setUdpDataPacketPayloadSize(int size){ setUdpDataPacketSize(size+4); }
    int udpDataPacketSize(){ return defaultUdpDataPacketSize;}
    int udpDataPacketPayloadSize(){ return defaultUdpDataPacketSize-4;}
    int udpDataPacketPayloadSize32(){ return udpDataPacketPayloadSize()/4;}
    
	/*--------------------------------------------------------------------
	 vars for FIFO list and initialization
	 --------------------------------------------------------------------*/
	 static void initFIFOREADERList(){
         availableNumFIFO = 0;
	     FifoReader = new FIFOREADER[maxNumFIFO];
		 if(FifoReader==0){ printf("initFIFOREADERList: cannot allocate memory!\n"); exit(1); }
		 
		 for(int i=0; i<maxNumFIFO; i++){
		     //no, ctor calls initVars ... FifoReader[i].initVars();
			 FifoReader[i].numfifo=i;
	     }
	 }

	 int initBuffer(){
         int i=numfifo;
         int retval=0;
			 if(readfifo){
                 if(numfifo<0 || numfifo>=availableNumFIFO){
                     printf("FIFOREADER::initBuffer: ERROR: FIFO w. index %i NOT AVAILABLE - DISABLED FIFO %i... check your configuration!\n",i,i);
                     readfifo = 0; //disabling this FIFO
                     return 0;
                 }
                 retval=FifoReader[i].allocateFIFOBufferBytes(Preferred_FIFObuf8len);
                 printf("FIFOREADER::initBuffer: use FIFO w. index %i - allocated buffer with %i bytes ...\n",i,retval);
             }else{
                 printf("FIFOREADER::initBuffer: FIFO  %i - not activated\n",i);
             }

         return retval;
     }

	 void freeBuffer(){
        //if(show_debug_info>=1) 
        printf("FIFOREADER::freeBuffer:  FIFO w. index %i - free buffer with %i bytes ...\n",numfifo,FIFObuf8len);
        free(FIFObuf8);
        //init with 0
	    FIFObuf8 = (char *)0;
	    FIFObuf16 = (uint16_t *)FIFObuf8;
	    FIFObuf32 = (uint32_t *)FIFObuf8;
        FIFObuf8len = 0;
        FIFObuf16len = FIFObuf8len / 2;
        FIFObuf32len = FIFObuf8len / 4;
	    popIndexFIFObuf32=0;
	    pushIndexFIFObuf32=0;
	    FIFObuf32avail=0;
	    FIFObuf32counter=0;
	    FIFObuf32counterlast=0;
        synchroWordPosHint=0;
        if(readfifo) readfifo = 0;
     }
     
     
	 static void initFIFOREADERBuffers(){
		 for(int i=0; i<maxNumFIFO; i++){
		     //no, ctor calls initVars ... FifoReader[i].initVars();
			 //if(FifoReader[i].readfifo){  //initFIFOREADERBuffer will check this ...
                 //printf("FIFOREADER::initFIFOREADERBuffers: use FIFO w. index %i - allocate buffer ...\n",i);
                 FifoReader[i].initBuffer();
             //}
	     }
         //FifoReader[0].initBuffer();// test to allocate buffer twice, should be refused ...  -tb-
         //exit(9);
     }

     static FIFOREADER	* FifoReader;
	 static const int maxNumFIFO = 16; //FIFOREADER::maxNumFIFO
	 static int availableNumFIFO; //FIFOREADER::maxNumFIFO
     
	 //results in following error: static int maxNumFIFO = 1; //FIFOREADER::maxNumFIFO
     //ipe4reader.h:560: error: ISO C++ forbids in-class initialization of non-const static member ‘maxNumFIFO’
};





/*--------------------------------------------------------------------
  globals and functions for hardware access
  --------------------------------------------------------------------*/
  
  //TODO: make presentFLTMap a static member of FLTSETTINGS -tb-
  
class SLTSETTINGS{
public:
    SLTSETTINGS(){
	    initVars();
	}
    uint32_t PixbusEnable;
    int      sltTimerSetting;
    int      utcTimeOffset;
    int      utcTimeCorrection100kHz;
    uint32_t numHWFifos;
	void initVars(){
		//
		PixbusEnable=0x0;
        numHWFifos=0;
        
        sltTimerSetting=-1;
        utcTimeOffset=0;
        utcTimeCorrection100kHz=0;
        
    }
    
    static void initSLTSETTINGS(){
	     SLT = new SLTSETTINGS;
		 if(SLT==0){ printf("initSLTSETTINGS: cannot allocate memory!\n"); exit(1); }
		 
	 }
    static SLTSETTINGS * SLT;
};
	


  
class FLTSETTINGS{
public:
    FLTSETTINGS(){
	    initVars();
	}
	
	//FLT Control register
	uint32_t fiberEnable;
	uint32_t fiberBlockOutMask;//FiberOutMask register
	uint32_t BBversionMask;
	uint32_t controlVetoFlag;
	uint32_t mode; // tramp,tord = 00: Normal; 01: TM-Order; 10: TM-Ramp; 11: Ramp Ordered
	//FLT registers
	uint32_t fiberSet1;
	uint32_t fiberSet2;
	uint32_t streamMask1;
	uint32_t streamMask2;
	uint32_t triggerMask1;
	uint32_t triggerMask2;
	
    //configuration of readout loop
	uint32_t sendBBstatusMask;
	uint32_t sendLegacyBBstatusMask;//send the OPERA style status packet (sendBBstatusMask then should be 0)
	
    //aux vars
	int32_t fltID;
    int isPresent;

	void initVars(){
		// FLT registers (HW)
		fiberEnable=0x0;
        fiberBlockOutMask=0x3f;
		BBversionMask=0x0;
        controlVetoFlag =0x0;
		mode =0x0;
		fiberSet1   =0x0;
		fiberSet2   =0x0;
	    streamMask1 =0x0;
	    streamMask2 =0x0;
	    triggerMask1=0x0;
	    triggerMask2=0x0;
	    
        // SW
	    sendBBstatusMask=0x0;
        sendLegacyBBstatusMask=0x0;
        
        //aux vars
        isPresent = 0;
    }
    
    
    
    static void initFLTSETTINGSList(){
	     FLT = new FLTSETTINGS[maxNumFLT];
		 if(FLT==0){ printf("initFLTSETTINGSList: cannot allocate memory!\n"); exit(1); }
		 
		 for(int i=0; i<maxNumFLT; i++){
		     //no, ctor calls initVars ... FLT[i].initVars();
			 FLT[i].fltID=i+1;
	     }
	 }

    
    static FLTSETTINGS * FLT;
	static const int maxNumFLT = MAX_NUM_FLT_CARDS; //FLTSETTINGS::maxNumFLT
    
    static int isPresentFLTIndex(int i){
        if(i<0 || i>=maxNumFLT) return 0;
        if(FLT==0) return 0; //not yet initialized
        return FLT[i].isPresent;
        return 0;
    }
    static int isPresentFLTID(int id){
        return isPresentFLTIndex(id-1);
    }

};



/*--------------------------------------------------------------------
  aux class to pack status packets
  --------------------------------------------------------------------*/
//#define UDPStatusPacketSize 1480
#define UDPStatusPacketSize MAX_UDP_STATUSPACKET_SIZE

// Class to assemble (status) UDP packets, controlling the current buffer size, packing additional packets as needed.
//
//   Stores the header in 'headerBuf'; collects data (header+status structs) in payload buffer 'buf';
//     method 'appendDataSendIfFull' handles sending of UDP packets (i.e. sends UDP packet if 'buf' is full, clears buffer and restarts filling 'buf')
//     method 'sendScheduledData()' appends 0 to the packet and sends all buffered data; should be called after the last call to 'appendDataSendIfFull' to send pending data
//     ('appendDataSendIfFull' uses 'sendScheduledData()')
class UDPPacketScheduler{
public:
    //ctor
    UDPPacketScheduler(FIFOREADER *fr):len(0),headerLen(0),sizeofLen(sizeof(uint32_t)),sendPacketCounter(0)
        { myFiforeader=fr; /*sizeofLen=sizeof(uint32_t);*/ bufHeaderLen=0; }
    char buf[UDPStatusPacketSize];
    char header[UDPStatusPacketSize];
    //char headerBuf[UDPStatusPacketSize];
    int len;//total length of data
    int headerLen;//length of header (which will be fixed for one series of packets)
    int bufHeaderLen;//length of header (which will be fixed for one series of packets)
    int sizeofLen;//=integer (currently 4 byte, 2 byte would be sufficient); each UDP packet ends with a 0 of this size (2 or 4 bytes)
    int sendPacketCounter;//for debugging
    FIFOREADER *myFiforeader; //used for sending out UDP packets
    
    //methods
    void resetBuf(){ len=0; headerLen=0; }
    void resetPayloadBuf(){ len=0; bufHeaderLen=0;  }
    int setHeader(char *data, int length){//store the header (the stored header will be used automatically after sending a packet (eg. appendDataSendIfFull))
        if(length>(UDPStatusPacketSize-sizeofLen)){ printf("ERROR in UDPPacketScheduler::setHeader: header size exceeds UDP packet size!\n"); return 1; }
        headerLen=length;
        for(int i=0;i<headerLen;i++) header[i]=data[i];
        return 0;
    }
    int writeHeaderToPayload(){
        if(len!=0) printf("ERROR in UDPPacketScheduler::writeHeaderToPayload(): payload not empty!\n");
        for(int i=0;i<headerLen;i++) buf[i]=header[i];
        len=headerLen;
        bufHeaderLen=headerLen;
        return 0;
    }
    int appendDataSendIfFull(char *data, int length){
        if(length>(UDPStatusPacketSize-headerLen-sizeofLen)){ printf("ERROR in UDPPacketScheduler::appendData: data exceeds UDP packet size!\n"); return 1; }
        if(headerLen==0) printf("WARNING in UDPPacketScheduler::appendData: headerLen is 0\n");
        if(!canHoldNumBytes(length)){//full, send current buffer
            sendScheduledData();
        }
        if(!canHoldNumBytes(length)){//full, send current buffer
            //we cleared the payload buf previously, still no place => header + data exceeds max. packet size => ERROR
            printf("ERROR in UDPPacketScheduler::appendDataSendIfFull: header+data size exceeds UDP packet size!\n"); return 1;
        }
        //append the data
        for(int i=0;i<length;i++) buf[len+i]=data[i];
        len+=length;
        return 0;
    }
    int canHoldNumBytes(int NumBytes){ if(UDPStatusPacketSize >= sizeofLen+len+NumBytes) return 1; else return 0; }// we need place for one additional uint32_t -> sizeof(uint32_t)
    int bodyLen(){ return len-headerLen; }
    int appendZeroBytes(int num){ for(int i=0; i<num; i++) buf[len+i]=0; len +=num; return 0; }
    void sendScheduledData(){
        if(len<=bufHeaderLen) return;//payload empty ('<' would be enough)
            //append 0, adjust len, send data
            appendZeroBytes(sizeofLen);
            sendOutUDPPacket();
            resetPayloadBuf();
            writeHeaderToPayload();
    }
    void sendOutUDPPacket(){
        myFiforeader->sendtoUDPClients(0,buf,len);
        sendPacketCounter++;
    }
};


/*--------------------------------------------------------------------
  unused
  --------------------------------------------------------------------*/


#if 0
	//TODO: GLOBAL VARIABLES LIST
	//globals for config file options
	int numfifo=0;
	int RECORDING_SEC=0;
	int simulation_send_dummy_udp=0;
	int run_main_readout_loop=1;
	int show_debug_info=0;

	int write2file=0;  // 0 = don't write to file; 1 = write file
	int write2file_len_sec=5;
	int write2file_format=0;
	const int ascii=0, binary=1;
	FILE * pFile =0;


	//open port to listen for / server port
	int  MY_UDP_SERVER_SOCKET;
	int  MY_UDP_SERVER_PORT;
	uint32_t  MY_UDP_SERVER_IP = INADDR_ANY;

	//'static' client, configured in the config file
	int  use_static_udp_client = 0;
	int		MY_UDP_CLIENT_SOCKET;
	struct	sockaddr_in cliaddr;
	char MY_UDP_CLIENT_IP[1024];
	int  MY_UDP_CLIENT_PORT;

	int send_status_udp_packet = 1;
	int skip_num_status_bits = 0; //skip this number of status bits (we observed offsets between 0 and 2)

	//for use of dummy status bits
	int use_dummy_status_bits = 0;
		const int buflen=30000;
		char buf_status284[buflen];
		int buf_status284_len=0;


	Structure_trame_status MY_STATUS;
	Structure_trame_status *myStatusPtr;

	//spike finder
	int use_spike_finder = 1;
	int32_t countSpikes=0;
	int32_t secCountSpikes=0;
	int32_t countSpikesChan[6]={0,0,0,0,0,0};
	int32_t countSpikesVal[6]={0,0,0,0,0,0};//250-400, 400-1000, >1000
	/*--------------------------------------------------------------------
	  globals for FIFO buffer
	  --------------------------------------------------------------------*/
	const uint32_t FIFObuf8len = 1200016 * 8;  //1200000 = max. number of ADC data in 1 sec (BB2) + 4 x word32 (sec strobe pattern)
	const uint32_t FIFObuf16len = FIFObuf8len / 2;
	const uint32_t FIFObuf32len = FIFObuf8len / 4;
	char * FIFObuf8[FIFObuf8len];
	int16_t * FIFObuf16 = (int16_t *)FIFObuf8;
	int32_t * FIFObuf32 = (int32_t *)FIFObuf8;
	uint32_t popIndexFIFObuf32=0;
	uint32_t pushIndexFIFObuf32=0;
	uint32_t FIFObuf32avail=0;
	int64_t FIFObuf32counter=0;
	int64_t FIFObuf32counterlast=0;

	uint32_t FIFOBlockSize = 4 * 1024; //TODO: FIFOBlockSize: later go to 8192 -tb- 

	uint32_t globalHeaderWordCounter = 0; //TODO: globalHeaderWordCounter for testing -tb- 

	// globals for sending commands (from cew.c)
	//  par defaut, pour l'envoie de la premiere commande horloge : une bbv1 autonome
	//  modifie par les valeurs du fichier config		
	int	X=21;
	int	Retard=16;
	int	Masque_BB=2;
	int	Nb_mots_lecture=3;					//is 3 for BB2, 2 for BBv21 mode!!!!!!!!!! -tb-    //marche pour un seul bolo	// nombre de mots total relut dans les data de la fifo:   -tb- d.h. Anzahl 32-bit-Worte(FIFO-Worte) pro (Time-)Sample (Sample=alle ADC-Kanaele
	//int	Nb_mots_lecture=2;					//marche pour un seul bolo	// nombre de mots total relut dans les data de la fifo:
	//int	Code_acqui=code_acqui_EDW_BB1;
	int	Code_acqui=code_acqui_EDW_BB2;   // I prefer BB2 -tb-
	int	Code_synchro=code_synchro_100000;	//+code_synchro_esclave_synchro+code_synchro_esclave_temps;
	int	Nb_synchro=100000;					//  nombre d'echantillons entre 2 synchros
#endif







/*--------------------------------------------------------------------
  UDP communication
  --------------------------------------------------------------------*/

/*--------------------------------------------------------------------
  UDP communication - 1.) client communication
  --------------------------------------------------------------------*/


/*--------------------------------------------------------------------
 *    function:     
 *    purpose:      
 *    author:       Till Bergmann, 2011
 *--------------------------------------------------------------------*/ //-tb-
