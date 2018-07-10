//
//  ORGretina4ARegisters.m
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

#import "ORGretina4ARegisters.h"

typedef struct gretina4ARegNamesStruct {
    unsigned long   offset;
    NSString*       regName;
    short           accessType;
    unsigned short  enumCheckValue;
} gretina4ARegNamesStruct;

static gretina4ARegNamesStruct reg4A[kNumberOfGretina4ARegisters] = {
    { 0x0000,	@"Board Id",                kReadOnly,             kBoardId              },
    { 0x0004,	@"Programming Done",        kReadWrite,            kProgrammingDone      },
    { 0x0008,	@"External Discrim Src",    kReadWrite,            kExternalDiscSrc      },
    { 0x0020,	@"Hardware Status",         kReadOnly,             kHardwareStatus       },
    { 0x0024,	@"User Package Data",       kReadWrite,            kUserPackageData      },
    { 0x0028,	@"Window Comp Min",         kReadWrite,            kWindowCompMin        },
    { 0x002C,	@"Window Comp Max",         kReadWrite,            kWindowCompMax        },
    { 0x0040,	@"Channel Control",         kReadWrite | kChanReg, kChannelControl       },
    { 0x0080,	@"Led Threshold",           kReadWrite | kChanReg, kLedThreshold         },
    { 0x00C0,	@"CFD Fraction",            kReadWrite | kChanReg, kCFDFraction          },
    { 0x0100,	@"Raw Data Length",         kReadWrite | kChanReg, kRawDataLength        },
    { 0x0140,	@"Raw Data Window",         kReadWrite | kChanReg, kRawDataWindow        },
    { 0x0180,	@"D Window",                kReadWrite | kChanReg, kDWindow              },
    { 0x01C0,	@"K Window",                kReadWrite | kChanReg, kKWindow              },
    { 0x0200,	@"M Window",                kReadWrite | kChanReg, kMWindow              },
    { 0x0240,	@"D3 Window",               kReadWrite | kChanReg, kD3Window             },
    { 0x0280,	@"Disc Width",              kReadWrite | kChanReg, kDiscWidth            },
    { 0x02C0,	@"Baseline Start",          kReadWrite | kChanReg, kBaselineStart        },
    { 0x0300,	@"P1 Delay",                kReadWrite | kChanReg, kP1Window             },
    { 0x0400,	@"Dac",                     kReadWrite,            kDac                  },
    { 0x0404,	@"P2 Delay",                kReadWrite,            kP2Window             },
    { 0x0408,	@"Ila Config",              kReadWrite,            kIlaConfig            },
    { 0x040C,	@"Channel Pulsed Control",	kReadWrite,            kChannelPulsedControl },
    { 0x0410,	@"Diag Mux Control",        kReadWrite,            kDiagMuxControl       },
    { 0x0414,	@"Holdoff Control",         kReadWrite,            kHoldoffControl       },
    { 0x0418,	@"Baseline Delay",          kReadWrite,            kBaselineDelay        },
    { 0x041C,	@"Diag Channel Input",      kReadWrite,            kDiagChannelInput     },
    { 0x0420,	@"Ext Discriminator Mode",  kReadWrite,            kExternalDiscMode     },
    { 0x0424,	@"Rj45 Spare Dout Control",	kReadWrite,            kRj45SpareDoutControl },
    { 0x0428,	@"Led Status",              kReadOnly,             kLedStatus            },
    { 0x0434,	@"Downsample Holdoff",      kReadWrite,            kDownSampleHoldOffTime},
    { 0x0480,	@"Lat Timestamp Lsb",       kReadOnly,             kLatTimestampLsb      },
    { 0x0488,	@"Lat Timestamp Msb",       kReadOnly,             kLatTimestampMsb      },
    { 0x048C,	@"Live Timestamp Lsb",      kReadOnly,             kLiveTimestampLsb     },
    { 0x0490,	@"Live Timestamp Msb",      kReadOnly,             kLiveTimestampMsb     },
    { 0x0494,	@"Veto Gate Width",         kReadWrite,            kVetoGateWidth        },
    { 0x0500,	@"Master Logic Status",     kReadWrite,            kMasterLogicStatus    },
    { 0x0504,	@"Trigger Config",          kReadWrite,            kTriggerConfig        },
    { 0x0508,	@"Phase Error Count",       kReadOnly,             kPhaseErrorCount      },
    { 0x050C,	@"Phase Value",             kReadOnly,             kPhaseValue           },
    { 0x0510,	@"Phase Offset0",           kReadOnly,             kPhaseOffset0         },
    { 0x0514,	@"Phase Offset1",           kReadOnly,             kPhaseOffset1         },
    { 0x0518,	@"Phase Offset2",           kReadOnly,             kPhaseOffset2         },
    { 0x051C,	@"Serdes Phase Value",      kReadOnly,             kSerdesPhaseValue     },
    { 0x0600,	@"Code Revision",           kReadOnly,             kCodeRevision         },
    { 0x0604,	@"Code Date",               kReadOnly,             kCodeDate             },
    { 0x0608,	@"TS Err Cnt Enable",       kReadWrite,            kTSErrCntEnable       },
    { 0x060C,	@"TS Error Count",          kReadOnly,             kTSErrorCount         },
    { 0x0700,	@"Dropped Event Count",     kReadOnly  | kChanReg, kDroppedEventCount    },
    { 0x0740,	@"Accepted Event Count",	kReadOnly  | kChanReg, kAcceptedEventCount   },
    { 0x0780,	@"Ahit Count",              kReadOnly  | kChanReg, kAhitCount            },
    { 0x07C0,	@"Disc Count",              kReadOnly  | kChanReg, kDiscCount            },
    { 0x0800,	@"Aux IO Read",             kReadWrite | kChanReg, kAuxIORead            },
    { 0x0804,	@"Aux IO Write",            kReadWrite | kChanReg, kAuxIOWrite           },
    { 0x0808,	@"Aux IO Config",           kReadWrite | kChanReg, kAuxIOConfig          },
    { 0x0848,	@"Sd Config",               kReadWrite,            kSdConfig             },
    { 0x1000,	@"Fifo",                    kNoAccess,             kFifo                 },
};


@implementation ORGretina4ARegisters
+ (ORGretina4ARegisters*) sharedRegSet
{
    //A singleton so that all the FLTs can expose the registers from this object
    if(!sharedGretina4ARegisters){
        sharedGretina4ARegisters = [[ORGretina4ARegisters alloc] init];
    }
    return sharedGretina4ARegisters;
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
    for(i=0;i<kNumberOfGretina4ARegisters;i++){
        if(reg4A[i].enumCheckValue != i){
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
    [sharedGretina4ARegisters release];
    sharedGretina4ARegisters = nil;
    [super dealloc];
}

- (int) numRegisters
{
    return kNumberOfGretina4ARegisters;
}

- (BOOL) hasChannels:(unsigned short) anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return reg4A[anIndex].accessType & kChanReg;
}

- (BOOL) regIsReadable:(unsigned short) anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return reg4A[anIndex].accessType & kRead;
}

- (BOOL) regIsWriteable:(unsigned short) anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return reg4A[anIndex].accessType & kWrite;
}

- (NSString*) registerName: (unsigned short) anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return reg4A[anIndex].regName;
}

- (short) accessType: (unsigned short) anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return reg4A[anIndex].accessType;
}

- (unsigned long) offsetforReg:(unsigned short)anIndex chan:(unsigned short)aChannel
{
    [self checkIndex:  anIndex]; //will throw if out of bounds
    [self checkChannel:aChannel]; //will throw if out of bounds
    return reg4A[anIndex].offset + (4 * aChannel);
}

- (unsigned long) offsetforReg:(unsigned short)anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return reg4A[anIndex].offset;
}

- (unsigned long) address:(unsigned long)baseAddress forReg:(unsigned short)anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return baseAddress+ reg4A[anIndex].offset;
}

- (unsigned long) address:(unsigned long)baseAddress forReg:(unsigned short)anIndex chan:(unsigned short)aChannel
{
    [self checkIndex:  anIndex]; //will throw if out of bounds
    [self checkChannel:aChannel]; //will throw if out of bounds
    return baseAddress+ reg4A[anIndex].offset + (4*aChannel);
}

- (void) checkIndex:(unsigned short)anIndex
{
    if(anIndex >= kNumberOfGretina4ARegisters){
        NSString* reason = [NSString stringWithFormat:@"Index out of bounds: %d. Valid Range: 0 - %d",anIndex,kNumberOfGretina4ARegisters-1];
        @throw([NSException exceptionWithName:@"Index Out of Bounds" reason:reason userInfo:nil]);
    };
}

- (void) checkChannel:(unsigned short)aChannel
{
    if(aChannel >= kNumGretina4AChannels){
        NSString* reason = [NSString stringWithFormat:@"Channel out of bounds: %d. Valid Range: 0 - 9",aChannel];
        @throw([NSException exceptionWithName:@"Channel Out of Bounds" reason:reason userInfo:nil]);
    };
}

@end


static gretina4ARegNamesStruct fpga_reg4A[kNumberOfFPGARegisters] = {
    {0x900,	@"FPGA configuration register", kReadWrite,    kMainFPGAControl     },
    {0x904,	@"VME Status register",         kReadOnly,     kMainFPGAStatus      },
    {0x908,	@"VME Aux Status",              kReadOnly,     kAuxStatus           },
    {0x910,	@"VME General Purpose Control", kReadWrite,    kVMEGPControl        },
    {0x914,	@"VME Timeout Value Register",  kReadWrite,    kVMETimeoutValue     },
    {0x920,	@"VME Version/Status",          kReadOnly,     kVMEFPGAVersionStatus},
    {0x928,	@"VME FPGA Date    ",           kReadOnly,     kVMEFPGADate         },
    {0x930,	@"VME Sandbox Register1",       kReadWrite,    kVMEFPGASandbox1     },
    {0x934,	@"VME Sandbox Register2",       kReadWrite,    kVMEFPGASandbox2     },
    {0x938,	@"VME Sandbox Register3",       kReadWrite,    kVMEFPGASandbox3     },
    {0x93C,	@"VME Sandbox Register3",       kReadWrite,    kVMEFPGASandbox4     },
};


@implementation ORGretina4AFPGARegisters
+ (ORGretina4AFPGARegisters*) sharedRegSet
{
    //A singleton so that all the FLTs can expose the registers from this object
    if(!sharedGretina4AFPGARegisters){
        sharedGretina4AFPGARegisters = [[ORGretina4AFPGARegisters alloc] init];
    }
    return sharedGretina4AFPGARegisters;
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
    for(i=0;i<kNumberOfFPGARegisters;i++){
        if(fpga_reg4A[i].enumCheckValue != i){
            if(printedOnce){
                NSLogColor([NSColor redColor],@"KATRIN V4 FPGA Register table has error at index: %d\n",i);
                printedOnce = YES;
            }
            return NO;
        }
    }
    return YES;
}

- (void) dealloc
{
    [sharedGretina4ARegisters release];
    sharedGretina4ARegisters = nil;
    [super dealloc];
}

- (int)       numRegisters                  { return kNumberOfFPGARegisters; }

- (BOOL) regIsReadable:(unsigned short) anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return fpga_reg4A[anIndex].accessType & kRead;
}

- (BOOL) regIsWriteable:(unsigned short) anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return fpga_reg4A[anIndex].accessType & kWrite;
}

- (NSString*) registerName: (unsigned short) anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return fpga_reg4A[anIndex].regName;
}

- (short) accessType: (unsigned short) anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return fpga_reg4A[anIndex].accessType;
}

- (unsigned long) offsetforReg:(unsigned short)anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return fpga_reg4A[anIndex].offset;
}

- (unsigned long) address:(unsigned long)baseAddress forReg:(unsigned short)anIndex
{
    [self checkIndex:anIndex]; //will throw if out of bounds
    return baseAddress+ fpga_reg4A[anIndex].offset;
}

- (void) checkIndex:(unsigned short)anIndex
{
    if(anIndex > kNumberOfFPGARegisters){
        NSString* reason = [NSString stringWithFormat:@"Index: %d. Valid Range: 0 - %d",anIndex,kNumberOfFPGARegisters-1];
        @throw([NSException exceptionWithName:@"Index Out of Bounds" reason:reason userInfo:nil]);
    };
}
@end

