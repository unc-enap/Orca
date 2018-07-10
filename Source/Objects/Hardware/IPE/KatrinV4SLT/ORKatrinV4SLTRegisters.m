//
//  ORKatrinv4Registers.m
//  Orca
//
//  Created by Mark Howe on Sun June 4, 2017.
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
#import "ORKatrinV4SLTRegisters.h"

typedef struct KatrinV4SLTRegisterNamesStruct {
    NSString*       regName;
    unsigned long 	addressOffset;
    int				length;
    short			accessType;
    eKatriV4SLTEnum enumCheckValue;
} KatrinV4SLTRegisterNamesStruct;

static KatrinV4SLTRegisterNamesStruct regV4SLT[kKatrinV4SLTNumRegs] = {
    {@"Control",			0xa80000,	1,		kReadWrite, kKatrinV4SLTControlReg          },
    {@"Status",				0xa80004,	1,		kReadWrite, kKatrinV4SLTStatusReg           },
    {@"Command",			0xa80008,	1,		kWriteOnly, kKatrinV4SLTCommandReg          },
    {@"Interrupt Reguest",	0xA8000C,	1,		kReadOnly,  kKatrinV4SLTInterruptReguestReg },
    {@"Interrupt Mask",		0xA80010,	1,		kReadWrite, kKatrinV4SLTInterruptMaskReg    },
    {@"Request Semaphore",	0xA80014,	3,		kReadOnly,  kKatrinV4SLTRequestSemaphoreReg },
    {@"HWRevision",			0xa80020,	1,		kReadOnly,  kKatrinV4SLTHWRevisionReg       },
    {@"Pixel Bus Error",	0xA80024,	1,		kReadOnly,  kKatrinV4SLTPixelBusErrorReg    },
    {@"Pixel Bus Enable",	0xA80028,	1, 		kReadWrite, kKatrinV4SLTPixelBusEnableReg   },
    {@"Veto Counter (MSB)",	0xA80080, 	1,		kReadOnly,  kKatrinV4SLTVetoCounterHiReg    },
    {@"Veto Counter (LSB)",	0xA80084,	1,		kReadOnly,  kKatrinV4SLTVetoCounterLoReg    },
    {@"Dead Counter (MSB)",	0xA80088, 	1,		kReadOnly,  kKatrinV4SLTDeadTimeCounterHiReg},
    {@"Dead Counter (LSB)",	0xA8008C, 	1,		kReadOnly,  kKatrinV4SLTDeadTimeCounterLoReg},
    {@"Run Counter  (MSB)",	0xA80090,	1,		kReadOnly,  kKatrinV4SLTRunCounterHiReg     },
    {@"Run Counter  (LSB)",	0xA80094, 	1,		kReadOnly,  kKatrinV4SLTRunCounterLoReg     },
    {@"Lost Events  (MSB)", 0xa80098,   1,      kReadOnly,  kKatrinV4SLTLostEventsCountHiReg  },
    {@"Lost Events  (LSB)", 0xa8009C,   1,      kReadOnly,  kKatrinV4SLTLostEventsCountLoReg  },
    {@"Second Set",			0xB00000,  	1, 		kReadWrite, kKatrinV4SLTSecondSetReg        },
    {@"Second Counter",		0xB00004, 	1,		kReadOnly,  kKatrinV4SLTSecondCounterReg    },
    {@"Sub-second Counter",	0xB00008, 	1,		kReadOnly,  kKatrinV4SLTSubSecondCounterReg },
    {@"Page Select",		0xB80008, 	1,		kReadOnly,  kKatrinV4SLTPageSelectReg       },
    {@"TP Timing",			0xC80000,   128,	kReadWrite, kKatrinV4SLTTPTimingReg         },
    {@"TP Shape",			0xC81000,   512,	kReadWrite, kKatrinV4SLTTPShapeReg          },
    {@"I2C Command",		0xC00000,	1,		kReadOnly,  kKatrinV4SLTi2cCommandReg       },
    {@"EPC Command",		0xC00004,	1,		kReadWrite, kKatrinV4SLTepcsCommandReg      },
    {@"Board ID (LSB)",		0xC00008,	1,		kReadOnly,  kKatrinV4SLTBoardIDLoReg        },
    {@"Board ID (MSB)",		0xC0000C,	1,		kReadOnly,  kKatrinV4SLTBoardIDHiReg        },
    {@"PROMs Control",		0xC00010,	1,		kReadWrite, kKatrinV4SLTPROMsControlReg     },
    {@"PROMs Buffer",		0xC00100,	256,	kReadWrite, kKatrinV4SLTPROMsBufferReg      },
    {@"DataFIFO",		    0xD00000,   0x10000,kReadWrite, kKatrinV4SLTDataFIFOReg         },
    {@"FIFO Mode",			0xE00000,   1,	    kReadWrite, kKatrinV4SLTFIFOModeReg         },
    {@"FIFO Status",		0xE00004,   1,	    kReadWrite, kKatrinV4SLTFIFOStatusReg       },
    {@"PAE Offset",		    0xE00008,   1,	    kReadWrite, kKatrinV4SLTPAEOffsetReg        },
    {@"PAF Offset",		    0xE0000C,   1,	    kReadWrite, kKatrinV4SLTPAFOffsetReg        },
    {@"FIFO Csr",		    0xE00010,   1,	    kReadWrite, kKatrinV4SLTFIFOCsrReg          },
    {@"FIFOx Request",		0xE00014,   1,	    kReadWrite, kKatrinV4SLTFIFOxRequestReg     },
    {@"FIFO Mask",		    0xE00018,   1,	    kReadWrite, kKatrinV4SLTFIFOMaskReg         },
};


@implementation ORKatrinV4SLTRegisters
+ (ORKatrinV4SLTRegisters*) sharedRegSet
{
    //A singleton so that all the SLTs can expose the registers from this object
    if(!sharedKatrinV4SLTRegisters){
        sharedKatrinV4SLTRegisters = [[ORKatrinV4SLTRegisters alloc] init];
    }
    return sharedKatrinV4SLTRegisters;
}

- (id) init
{
    self = [super init];
    [self checkRegisterTable];
    return self;
}

- (BOOL) checkRegisterTable
{
    int i;
    for(i=0;i<kKatrinV4SLTNumRegs;i++){
        if(regV4SLT[i].enumCheckValue != i){
            if(printedOnce){
                NSLogColor([NSColor redColor],@"KATRIN V4 Register table has error at index: %d\n",i);
                printedOnce = YES;
            }
            return NO;
        }
    }
    return YES;
}

- (void) dealloc
{
    [sharedKatrinV4SLTRegisters release];
    sharedKatrinV4SLTRegisters = nil;
    [super dealloc];
}

- (int)       numRegisters                  { return kKatrinV4SLTNumRegs; }

- (NSString*) registerName: (short) anIndex
{
    if(anIndex>=0 && anIndex<kKatrinV4SLTNumRegs) return regV4SLT[anIndex].regName;
    else return @"Illegal";
}

- (short)     accessType: (short) anIndex
{
   if(anIndex>=0 && anIndex<kKatrinV4SLTNumRegs) return regV4SLT[anIndex].accessType;
   else                                          return kNoAccess;
}

- (BOOL)      isWritable:   (short) anIndex
{
    if(anIndex>=0 && anIndex<kKatrinV4SLTNumRegs) return regV4SLT[anIndex].accessType & kWrite;
    else                                          return NO;
}

- (BOOL)      isReadable:   (short) anIndex
{
    if(anIndex>=0 && anIndex<kKatrinV4SLTNumRegs) return regV4SLT[anIndex].accessType & kRead;
    else                                          return NO;
}

- (unsigned long) address: (short) anIndex
{
    if(anIndex>=0 && anIndex<kKatrinV4SLTNumRegs) return (regV4SLT[anIndex].addressOffset>>2);
    else                                          return 0x0;
}



@end
