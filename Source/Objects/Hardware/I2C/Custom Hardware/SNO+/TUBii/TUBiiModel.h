//
//  TUBiiModel.h
//  Orca
//
//  Created by Ian Coulter on 9/15/15.
//  Largely written by Eric Marzec marzece@gmail.com
//  Last edited on Jan 23 2016
//  See comments in TUBiiModel.m for the deets
#pragma mark •••Imported Files
#import "OrcaObject.h"

@class RedisClient; //Forward declaration

typedef NS_OPTIONS(uint8_t, CAEN_CHANNEL_MASK) {
    channelSel_0 = 1<<3,
    channelSel_1 = 1<<0,
    channelSel_2 = 1<<1,
    channelSel_3 = 1<<2
};
typedef NS_OPTIONS(uint8_t,CAEN_GAIN_MASK)
{
    gainSel_0 = 1<<0,
    gainSel_1 = 1<<2,
    gainSel_2 = 1<<7,
    gainSel_3 = 1<<5,
    gainSel_4 = 1<<1,
    gainSel_5 = 1<<3,
    gainSel_6 = 1<<6,
    gainSel_7 = 1<<4
};
//The reason the bit to label mapping may seem weird is b/c
//the hardware was designed so that the PCB traces were in order
//unfortunately to do so the bit# to function# correspondece had
//to be muddied up a bit.

typedef NS_OPTIONS(uint8_t,CONTROL_REG_MASK)
{
    clkSel_Bit = 1<<0,      //1 indicates FOX is default clk TUB is backup. O is vice versa
    lockoutSel_Bit = 1<<1,  //1 indicates MTCD supplies LO. 0 means TUBii supplies it.
    ecalEnable_Bit = 1<<2,  //1 is for when an ECAL is being done. GT is routed to MTCD's EXT_Async
    scalerLZB_Bit = 1<<3,  //Scaler Lead Zero Blanking
    scalerT_Bit = 1<<4,    //Scaler Test* when low scaler is test mode
    scalerI_Bit = 1<<5    //Scaler Inhibit* when low counting is inhibited
};
typedef NS_OPTIONS(uint32_t, TRIG_MASK)
{
    ExtTrig0 = 1<<0,
    ExtTrig1 = 1<<1,
    ExtTrig2 = 1<<2,
    ExtTrig3 = 1<<3,
    ExtTrig4 = 1<<4,
    ExtTrig5 = 1<<5,
    ExtTrig6 = 1<<6,
    ExtTrig7 = 1<<7,
    ExtTrig8 = 1<<8,
    ExtTrig9 = 1<<9,
    ExtTrig10 = 1<<10,
    ExtTrig11 = 1<<11,
    ExtTrig12 = 1<<12,
    ExtTrig13 = 1<<13,
    ExtTrig14 = 1<<14,
    ExtTrig15 = 1<<15,
    Mimic1 = 1<<16,
    Mimic2 = 1<<17,
    Burst = 1<<18,
    Combo = 1<<19,
    Prescale = 1<<20,
    Button = 1<<21,
    Tellie = 1<<22,
    Smellie = 1<<23,
    GT = 1<<24
};

struct TUBiiState { //A struct that allows users of TUBiiModel to get/set all of TUBii's state at once.
    float smellieRate;
    float tellieRate;
    float pulserRate;
    float TUBiiPGT_Rate;
    float smelliePulseWidth;
    float telliePulseWidth;
    float pulserPulseWidth;
    int smellieNPulses;
    int tellieNPulses;
    int pulserNPulses;
    uint64_t tellieDelay;
    uint64_t smellieDelay;
    uint64_t genericDelay;
    CAEN_CHANNEL_MASK CaenChannelMask;
    CAEN_GAIN_MASK CaenGainMask;
    uint8_t DGT_Bits;
    uint8_t LO_Bits;
    uint32_t speakerMask;
    uint32_t counterMask;
    uint32_t syncTrigMask;
    uint32_t asyncTrigMask;
    CONTROL_REG_MASK controlReg;
    NSUInteger MTCAMimic1_ThresholdInBits;
    BOOL CounterMode;
};

@interface TUBiiModel : OrcaObject{
@private
    float smellieRate;
    float tellieRate;
    float pulserRate;
    float smelliePulseWidth;
    float telliePulseWidth;
    float pulserPulseWidth;
    int smellieNPulses;
    int tellieNPulses;
    int pulserNPulses;
    BOOL CounterMode_memoryVal;//Hack b/c tubii server doesn't yet have GetCounterMode command

    RedisClient *connection;
    int portNumber;
    NSString* strHostName;//"192.168.80.25";
    NSThread* _keepAliveThread;
@public
    struct TUBiiState currentModelState;
}
@property (readonly) BOOL solitaryObject; //Prevents there from being two TUBiis
@property (nonatomic) int portNumber;
@property (nonatomic,retain) NSString* strHostName;
@property (nonatomic) NSUInteger smellieDelay;
@property (nonatomic) NSUInteger tellieDelay;
@property (nonatomic) float TUBiiPGT_Rate;
@property (nonatomic) NSUInteger genericDelay;
@property (nonatomic) NSUInteger MTCAMimic1_ThresholdInBits;
@property (nonatomic) float MTCAMimic1_ThresholdInVolts;
@property (nonatomic) BOOL ECALMode;
@property (nonatomic,readonly) CAEN_CHANNEL_MASK caenChannelMask;
@property (nonatomic,readonly) CAEN_GAIN_MASK caenGainMask;
@property (nonatomic,readonly) NSUInteger DGTBits;
@property (nonatomic,readonly) NSUInteger LODelayBits;
@property (nonatomic,readonly) int LODelayInNS;
@property (nonatomic,readonly) int DGTInNS;
@property (nonatomic) NSUInteger speakerMask;
@property (nonatomic) NSUInteger counterMask;
@property (nonatomic,readonly) NSUInteger syncTrigMask;
@property (nonatomic,readonly) NSUInteger asyncTrigMask;
@property (nonatomic) CONTROL_REG_MASK controlReg;
@property (nonatomic) BOOL TUBiiIsDefaultClock;
@property (nonatomic) BOOL TUBiiIsLOSrc;
@property (nonatomic) BOOL CounterMode;
@property (nonatomic,retain) NSThread* keepAliveThread;

#pragma mark •••Initialization
- (id) init;
- (id) initWithCoder:(NSCoder *)aCoder;
- (void) setUpImage;
- (void) makeMainController;
- (void) encodeWithCoder:(NSCoder *)aCoder;
- (void) dealloc;
- (BOOL) solitaryObject;

- (float) ConvertBitsToValue:(NSUInteger)bits NBits: (int) nBits MinVal: (float) minVal MaxVal: (float) maxVal;
- (NSUInteger) ConvertValueToBits: (float) value NBits: (int) nBits MinVal: (float) minVal MaxVal: (float) maxVal;

- (void) sendOkCmd:(NSString* const)aCmd;
- (int) sendIntCmd:(NSString* const)aCmd;
- (NSUInteger) MTCAMimic_VoltsToBits: (float) VoltageValue;
- (float) MTCAMimic_BitsToVolts: (NSUInteger) BitValue;
- (void) Initialize;
- (void) Ping;
- (struct TUBiiState) currentModelState;
- (NSMutableDictionary*) serializeToDictionary;
- (bool) sendCurrentModelStateToHW;
- (void) loadFromSerialization:(NSMutableDictionary*)settingsDict;
- (void) setTrigMask:(NSUInteger)trigMask setAsyncMask:(NSUInteger)asyncMask;
- (void) setTrigMaskInState:(NSUInteger)trigMask setAsyncMask:(NSUInteger)asyncMask;
- (void) setBurstTrigger;
- (void) setComboTrigger_EnableMask:(uint32_t) enableMask TriggerMask:(uint32_t) triggerMask;
- (void) setPrescaleTrigger_Mask: (uint32_t) mask ByFactor:(uint32_t) factor;
- (void) setTUBiiPGT_Rate: (float) rate;
- (void) setTUBiiPGT_RateInState: (float) rate;
- (void) setSmellieRate: (float) _rate;
- (void) setTellieRate: (float) _rate;
- (void) setPulserRate: (float) _rate;
- (void) setSmelliePulseWidth: (double) _pulseWidth;
- (void) setTelliePulseWidth: (double) _pulseWidth;
- (void) setPulseWidth: (double) _pulseWidth;
- (void) setSmellieNPulses: (int) _NPulses;
- (void) setTellieNPulses: (int) _NPulses;
- (void) setNPulses: (int) _NPulses;
- (void) fireSmelliePulser;
- (void) fireTelliePulser;
- (void) setTellieMode: (BOOL) _tellieMode;
- (void) firePulser;
- (void) stopSmelliePulser;
- (void) stopTelliePulser;
- (void) stopPulser;
- (void) fireSmelliePulser_rate: (float)rate pulseWidth:(double)_pulseWidth NPulses:(int)_NPulses;
- (void) fireTelliePulser_rate: (float)rate pulseWidth:(double)_pulseWidth NPulses:(int)_NPulses;
- (void) firePulser_rate: (float)rate pulseWidth:(double)_pulseWidth NPulses:(int)_NPulses;
- (void) setDataReadout: (BOOL) val;
- (void) ResetFifo;
- (void) setCaenMasks: (CAEN_CHANNEL_MASK)aChannelMask
             GainMask:(CAEN_GAIN_MASK) aGainMask;
- (void) setCaenMasksInState: (CAEN_CHANNEL_MASK)aChannelMask
             GainMask:(CAEN_GAIN_MASK) aGainMask;
- (void) setSpeakerMask:(NSUInteger)_counterMask;
- (void) setSpeakerMaskInState:(NSUInteger)_counterMask;
- (void) setCounterMask:(NSUInteger)_counterMask;
- (void) setCounterMaskInState:(NSUInteger)_counterMask;
- (void) setControlRegInState:(CONTROL_REG_MASK)_controlReg;
- (void) setCounterModeInState:(BOOL)mode;
- (void) setMTCAMimic1_ThresholdInBitsInState:(NSUInteger)_MTCAMimic1_ThresholdInBits;
- (void) setGTDelaysBitsInState:(NSUInteger)aDGTMask LOBits:(NSUInteger)aLOMask;
- (void) setTUBiiIsLOSrcInState:(BOOL)isSrc;
- (void) setTUBiiIsDefaultClockInState: (BOOL) IsDefault;
- (void) ResetClock;
- (void) setGTDelaysBits:(NSUInteger)aDGTMask LOBits:(NSUInteger)aLOMask;
- (void) setGTDelaysInNS:(int)DGT LOValue:(int)LO;
- (int) LODelay_BitsToNanoSeconds: (NSUInteger)Bits;
- (NSUInteger) LODelay_NanoSecondsToBits: (int) Nanoseconds;
- (int) DGT_BitsToNanoSeconds: (NSUInteger) Bits;
- (NSUInteger) DGT_NanoSecondsToBits: (int) Nanoseconds;
- (CONTROL_REG_MASK) CraftControlReg_isClkSrc:(bool) ClkSrc
                                      isLOSrc: (bool) LOsrc
                                       EcalOn: (bool)EcalOn
                                   CounterLZBOn: (bool) LZB
                                  CounterTestOn: (bool) TestMode
                               CounterInhibitOn: (bool) Inhibit;
-(void)activateKeepAlive;
-(void)pulseKeepAlive:(id)passed;
-(void)killKeepAlive:(NSNotification*)aNote;
@end

extern NSString* ORTubiiLockNotification;
extern NSString* ORTubiiSettingsChangedNotification;
