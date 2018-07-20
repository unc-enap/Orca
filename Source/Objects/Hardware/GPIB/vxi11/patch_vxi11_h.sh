#!/bin/sh
INPUTFILE=$1
sed -e 's|\(#include <rpc/rpc.h>\)|\1                                               \
\
#define VXI_OK           0   /* no error */                                         \
#define VXI_SYNERR       1   /* syntax error */                                     \
#define VXI_NOACCESS     3   /* device not accessible */                            \
#define VXI_INVLINK      4   /* invalid link identifier */                          \
#define VXI_PARAMERR     5   /* parameter error */                                  \
#define VXI_NOCHAN       6   /* channel not established */                          \
#define VXI_NOTSUPP      8   /* operation not supported */                          \
#define VXI_NORES        9   /* out of resources */                                 \
#define VXI_DEVLOCK      11  /* device locked by another link */                    \
#define VXI_NOLOCK       12  /* no lock held by this link */                        \
#define VXI_IOTIMEOUT    15  /* I/O timeout */                                      \
#define VXI_IOERR        17  /* I/O error */                                        \
#define VXI_INVADDR      21  /* invalid address */                                  \
#define VXI_ABORT        23  /* abort */                                            \
#define VXI_CHANEXIST    29  /* channel already established */                      \
                                                                                    \
/* VXI-11 flags  */                                                                 \
                                                                                    \
#define VXI_WAITLOCK     1   /* block the operation on a locked device */           \
#define VXI_ENDW         8   /* device_write: mark last char with END indicator */  \
#define VXI_TERMCHRSET   128 /* device_read: stop on termination character */       \
                                                                                    \
/* VXI-11 read termination reasons */                                               \
                                                                                    \
#define VXI_REQCNT       1   /* requested # of bytes have been transferred */       \
#define VXI_CHR          2   /* termination character matched */                    \
#define VXI_ENDR         4   /* END indicator read */                               \
|g' \
-e 's/typedef long Device_Link;/                                         \
#ifdef __LP64__                                                          \
typedef int Device_Link;                                                 \
#else                                                                    \
typedef long Device_Link;                                                \
#endif                                                                   \
/g' \
-e 's/typedef long Device_ErrorCode;/                                    \
#ifdef __LP64__                                                          \
typedef int Device_ErrorCode;                                            \
#else                                                                    \
typedef long Device_ErrorCode;                                           \
#endif                                                                   \
/g' \
-e 's/typedef long Device_Flags;/                                        \
#ifdef __LP64__                                                          \
typedef int Device_Flags;                                                \
#else                                                                    \
typedef long Device_Flags;                                               \
#endif                                                                   \
/g' \
-e 's/\(.*\)u_long \(.*\);/                                              \
#ifdef __LP64__                                                          \
\1unsigned int \2;                                                       \
#else                                                                    \
\1u_long \2;                                                             \
#endif                                                                   \
/g' \
-e 's/\(	\)long \(.*\);/                                          \
#ifdef __LP64__                                                          \
\1int \2;                                                                \
#else                                                                    \
\1long \2;                                                               \
#endif                                                                   \
/g' \
$INPUTFILE 
