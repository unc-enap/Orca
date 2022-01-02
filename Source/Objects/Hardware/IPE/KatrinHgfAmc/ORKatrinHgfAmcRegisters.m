//
//  ORKatrinHgfAmcRegisters.m
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
#import "ORKatrinHgfAmcRegisters.h"

/** Bit field definition to transfer the hardware address to the SBC readout PC */
typedef union {
  struct {
    unsigned int addr : 24;
    unsigned int dev : 7;
    unsigned int fe : 1;
  } bits;
  uint32_t data;
} addressType;

typedef struct KatrinHgfAmcRegNamesStruct {
    NSString*            regName;
    uint32_t 	         addressOffset;
    short		         accessType;
    eKatrinHgfAmcRegEnum enumCheckValue;
} KatrinHgfAmcRegNamesStruct;

static KatrinHgfAmcRegNamesStruct regKatrinHgfAmc[kFLTV4NumRegs] = {

    {@"Status",			 0x0000, kReadOnly,               kFLTV4StatusReg          },
    {@"Control",		 0x0004, kReadWrite,              kFLTV4ControlReg         },
    {@"Command",		 0x0008, kReadWrite,              kFLTV4CommandReg         },
    {@"Version",	     0x0000, kReadOnly,               kFLTV4VersionReg         },
    {@"BoardIDLSB",      0x0014, kReadOnly,               kFLTV4BoardIDLsbReg      },
    {@"BoardIDMSB",      0x0018, kReadOnly,               kFLTV4BoardIDMsbReg      },
    {@"InterruptMask",   0x001C, kReadWrite,              kFLTV4InterruptMaskReg   },
    {@"HrMeasEnable",    0x0024, kReadWrite,              kFLTV4HrMeasEnableReg    },
    {@"EventFifoStatus", 0x002C, kReadOnly,               kFLTV4EventFifoStatusReg },
    {@"PixelSettings1",  0x0030, kReadWrite,              kFLTV4PixelSettings1Reg  },
    {@"PixelSettings2",  0x0034, kReadWrite,              kFLTV4PixelSettings2Reg  },
    {@"RunControl",      0x0038, kReadWrite,              kFLTV4RunControlReg      },
    {@"HistgrSettings",  0x003c, kReadWrite,              kFLTV4HistgrSettingsReg  },
    {@"AccessTest",      0x0040, kReadWrite,              kFLTV4AccessTestReg      },
    {@"SecondCounter",   0x0044, kReadWrite,              kFLTV4SecondCounterReg   },
    {@"HrControl",       0x0048, kReadWrite,              kFLTV4HrControlReg       },
    {@"HistMeasTime",    0x004C, kReadWrite,              kFLTV4HistMeasTimeReg    },
    {@"HistRecTime",     0x0050, kReadOnly,               kFLTV4HistRecTimeReg     },
    {@"HistNumMeas",     0x0054, kReadOnly,               kFLTV4HistNumMeasReg     },
    {@"PostTrigger",     0x0058, kReadWrite,              kFLTV4PostTriggerReg     },
    {@"EnergyOffset",	 0x005C, kReadWrite,              kFLTV4EnergyOffsetReg    },
    {@"LostEventsLSB",   0x0060, kReadWrite,              kFLTV4FIFOLostCounterLsbReg },
    {@"LostEventsMSB",   0x0064, kReadWrite,              kFLTV4FIFOLostCounterMsbReg },
    {@"LostEventsTrLSB", 0x0068, kReadWrite,              kFLTV4FIFOLostCounterTrLsbReg },
    {@"LostEventsTrMSB", 0x006C, kReadWrite,              kFLTV4FIFOLostCounterTrMsbReg },
    {@"Threshold",       0x2080, kReadWrite | kChanReg,   kFLTV4ThresholdReg       },
    {@"pStatusA",        0x2000, kReadWrite | kChanReg,   kFLTV4pStatusAReg        },
    {@"pStatusB",        0x12000,kReadOnly,               kFLTV4pStatusBReg        },
    {@"pStatusC",        0x52000,kReadOnly,               kFLTV4pStatusCReg        },
    {@"Analog Offset",   0x1000, kReadOnly,               kFLTV4AnalogOffsetReg    },
    {@"Gain",			 0x1004, kReadWrite | kChanReg,   kFLTV4GainReg            },
    {@"Hit Rate",		 0x1100, kReadOnly  | kChanReg,   kFLTV4HitRateReg         },
    {@"Event FIFO1",	 0x1800, kReadOnly,               kFLTV4EventFifo1Reg      },
    {@"Event FIFO2",	 0x1804, kReadOnly,               kFLTV4EventFifo2Reg      },
    {@"Event FIFO3",	 0x1808, kReadOnly  | kChanReg,   kFLTV4EventFifo3Reg      },
    {@"Event FIFO4",	 0x180C, kReadOnly  | kChanReg,   kFLTV4EventFifo4Reg      },
    {@"HistPageN",		 0x200C, kReadOnly,               kFLTV4HistPageNReg       },
    {@"HistLastFirst",	 0x2044, kReadOnly,               kFLTV4HistLastFirstReg   },
    {@"TestPattern",	 0x1400, kReadWrite,              kFLTV4TestPatternReg     },
};

@implementation ORKatrinHgfAmcRegisters
+ (ORKatrinHgfAmcRegisters*) sharedRegSet
{
    //A singleton so that all the FLTs can expose the registers from this object
    if(!sharedKatrinHgfAmcRegisters){
        sharedKatrinHgfAmcRegisters = [[ORKatrinHgfAmcRegisters alloc] init];
    }
    return sharedKatrinHgfAmcRegisters;
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
    for(i=0;i<kFLTV4NumRegs;i++){
        if(regKatrinHgfAmc[i].enumCheckValue != i){
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
    [sharedKatrinHgfAmcRegisters release];
    sharedKatrinHgfAmcRegisters = nil;
    [super dealloc];
}

- (int)       numRegisters
{
    return kFLTV4NumRegs;
}

- (NSString*) registerName: (short) anIndex
{
    if([self indexInRange:anIndex]) return regKatrinHgfAmc[anIndex].regName;
    else                            return @"Illegal";
}
- (short) addressOffset: (short) anIndex
{
    if([self indexInRange:anIndex]) return regKatrinHgfAmc[anIndex].addressOffset;
    else                            return 0x0;
}
- (short) accessType: (short) anIndex
{
    if([self indexInRange:anIndex]) return regKatrinHgfAmc[anIndex].accessType;
    else                            return 0x0;
}

- (uint32_t) addressForStation:(int)aStation registerIndex:(int)anIndex chan:(int)aChannel
{
    if([self indexInRange:anIndex]){
        //return (aStation << 17) | (aChannel << 12) | (regKatrinHgfAmc[anIndex].addressOffset>>2);
        return (aChannel << 12) | (regKatrinHgfAmc[anIndex].addressOffset>>2);
    }
    else return 0x0;
}

- (uint32_t) addressForStation:(int)aStation registerIndex:(int)anIndex
{
    addressType addr;
  
    if([self indexInRange:anIndex]){
        
        addr.bits.addr = regKatrinHgfAmc[anIndex].addressOffset>>2;
        addr.bits.dev = aStation;
        addr.bits.fe = 0;
        
        return(addr.data);
     
        //return (aStation << 24) | (regKatrinHgfAmc[anIndex].addressOffset>>2);
        //return (regKatrinHgfAmc[anIndex].addressOffset>>2);
    }
    else return 0x0;
}

- (BOOL) indexInRange:(short)anIndex
{
    return anIndex>=0 && anIndex<kFLTV4NumRegs;
}
@end
