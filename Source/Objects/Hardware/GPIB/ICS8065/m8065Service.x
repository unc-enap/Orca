/* Types */ 
typedef int32_t Device_Link; 
enum Device_AddrFamily {     /* used by interrupts */ 
    DEVICE_TCP, 
    DEVICE_UDP 
}; 
typedef int32_t Device_Flags; 
/*  Error types  */ 
typedef int32_t Device_ErrorCode; 
struct Device_Error { 
    Device_ErrorCode   error; 
}; 
struct Create_LinkParms { 
    int32_t          clientId;     /* implementation specific value */ 
    bool          lockDevice;   /* attempt to lock the device */ 
    uint32_t lock_timeout; /* time to wait on a lock */ 
    string        device<>;     /* name of device */ 
}; 
struct Create_LinkResp { 
    Device_ErrorCode  error; 
    Device_Link       lid; 
    unsigned short    abortPort;   /* for the abort RPC */ 
    uint32_t     maxRecvSize; /* specifies max data size in bytes 
                                      device will accept on a write */ 
}; 
struct Device_WriteParms { 
    Device_Link       lid;          /* link id from create_link */ 
    uint32_t     io_timeout;   /* time to wait for I/O */ 
    uint32_t     lock_timeout; /* time to wait for lock */ 
    Device_Flags      flags; 
    opaque            data<>;  /* the data length and the data itself */ 
}; 
struct Device_WriteResp  { 
    Device_ErrorCode  error; 
    uint32_t     size;    /* Number of bytes written */ 
}; 
struct Device_ReadParms { 
    Device_Link      lid;          /* link id from create_link */ 
    uint32_t    requestSize;  /* Bytes requested */ 
    uint32_t    io_timeout;   /* time to wait for I/O */ 
    uint32_t    lock_timeout; /* time to wait for lock */ 
    Device_Flags     flags; 
    char             termChar;     /* valid if flags & termchrset */
}; 
struct Device_ReadResp { 
    Device_ErrorCode  error; 
    int32_t              reason;  /* Reason(s) read completed */ 
    opaque            data<>;  /* data.len and data.val */ 
}; 
struct Device_ReadStbResp { 
    Device_ErrorCode  error;   /* error code */ 
    unsigned char     stb;     /* the returned status byte */ 
}; 
struct Device_GenericParms { 
    Device_Link     lid;          /* Device_Link id from connect call */ 
    Device_Flags    flags;        /* flags with options */ 
    uint32_t   lock_timeout; /* time to wait for lock */ 
    uint32_t   io_timeout;   /* time to wait for I/O */ 
}; 
struct Device_RemoteFunc { 
    uint32_t    hostAddr;      /* Host servicing Interrupt */ 
    unsigned short   hostPort;      /* valid port # on client */ 
    uint32_t    progNum;       /* DEVICE_INTR */ 
    uint32_t    progVers;      /* DEVICE_INTR_VERSION */ 
    Device_AddrFamily   progFamily; /* DEVICE_UDP | DEVICE_TCP */ 
}; 
struct Device_EnableSrqParms    { 
    Device_Link           lid; 
    bool                  enable;     /* Enable or disable interrupts */ 
    opaque                handle<40>; /* Host specific data */ 
}; 
struct Device_LockParms { 
    Device_Link    lid;           /* link id from create_link */ 
    Device_Flags   flags;         /* Contains the waitlock flag */ 
    uint32_t  lock_timeout;  /* time to wait to acquire lock */ 
}; 
struct Device_DocmdParms { 
    Device_Link    lid;           /* link id from create_link */ 
    Device_Flags   flags;         /* flags specifying various options */ 
    uint32_t  io_timeout;    /* time to wait for I/O to complete */ 
    uint32_t  lock_timeout;  /* time to wait on a lock */ 
    int32_t           cmd;           /* which command to execute */ 
    bool           network_order; /* client's byte order */ 
    int32_t           datasize;      /* size of individual data elements */ 
    opaque         data_in<>;     /* docmd data parameters */ 
}; 
struct Device_DocmdResp { 
    Device_ErrorCode   error;       /* returned status */ 
    opaque             data_out<>;  /* returned data parameter */ 
}; 
program DEVICE_ASYNC{ 
    version DEVICE_ASYNC_VERSION { 
       Device_Error      device_abort (Device_Link)            = 1; 
     } = 1; 
} = 0x0607B0; 
program DEVICE_CORE { 
  version DEVICE_CORE_VERSION { 
    Create_LinkResp    create_link        (Create_LinkParms)      = 10; 
    Device_WriteResp   device_write       (Device_WriteParms)     = 11; 
    Device_ReadResp    device_read        (Device_ReadParms)      = 12; 
    Device_ReadStbResp device_readstb     (Device_GenericParms)   = 13;
    Device_Error       device_trigger     (Device_GenericParms)   = 14; 
    Device_Error       device_clear       (Device_GenericParms)   = 15; 
    Device_Error       device_remote      (Device_GenericParms)   = 16; 
    Device_Error       device_local       (Device_GenericParms)   = 17; 
    Device_Error       device_lock        (Device_LockParms)      = 18; 
    Device_Error       device_unlock      (Device_Link)           = 19; 
    Device_Error       device_enable_srq  (Device_EnableSrqParms) = 20; 
    Device_DocmdResp   device_docmd       (Device_DocmdParms)     = 22; 
    Device_Error       destroy_link       (Device_Link)           = 23; 
    Device_Error       create_intr_chan   (Device_RemoteFunc)     = 25; 
    Device_Error       destroy_intr_chan  (void)                  = 26; 
     } = 1; 
} = 0x0607AF; 

/* Types */ 
struct Device_SrqParms { 
 opaque handle<>; 
}; 
program DEVICE_INTR { 
  version DEVICE_INTR_VERSION { 
    void               device_intr_srq      (Device_SrqParms)     = 30; 
     }=1; 
}= 0x0607B1;

