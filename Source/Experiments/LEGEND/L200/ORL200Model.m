//  Orca
//  ORL200Model.m
//
//  Created by Tom Caldwell on Monday Mar 21, 2022
//  Copyright (c) 2022 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORL200Model.h"
#import "ORL200SegmentGroup.h"
#import "ORDetectorSegment.h"
#import "SynthesizeSingleton.h"
#import "ORFlashCamADCModel.h"
#import "ORAlarm.h"
#import "ORTimeRate.h"
#import "ORRunModel.h"
#import "ORCouchDBModel.h"
#import "ORFlashCamCrateModel.h"

static NSString* L200DBConnector     = @"L200DBConnector";
NSString* ORL200ModelViewTypeChanged = @"ORL200ModelViewTypeChanged";

@implementation ORL200Model

#pragma mark •••Initialization

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
    [self getRunType:nil];
    [self findInFluxDB];
    [super awakeAfterDocumentLoaded];
}

- (void) findInFluxDB
{
    influxDB = [[self document] findObjectWithFullID:@"ORInFluxDBModel,1"];
}

- (void) updateMachineRecord
{
//    influxIndex++;
//    [influxDB setTags:@"host=MarksLaptop"];
//    [influxDB startMeasurement:@"L200Data"];
//    [influxDB addDouble:@"Test1" withValue:random_range(0,100)];
//    [influxDB addDouble:@"Test2" withValue:random_range(0,100)];
//    [influxDB endMeasurement];
//
//    [self performSelector:@selector(updateMachineRecord) withObject:nil afterDelay:.1];

//    [self startMeasurement:@"CPU1"];
//    [self addLong:@"Memory" withValue:12];
//    [self addLong:@"RamUsed" withValue:200.2];
//    [self endMeasurement];
//    [influxDB push];
}

/*- (void) wakeUp
{
    [super wakeUp];
    if(pollTime){
        [self checkConstraints];
    }
}*/

- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super sleep];
}

- (void) setUpImage {
    NSImage* image = [NSImage imageNamed:@"L200"];
    [self setImage:image];
}

- (void) makeMainController
{
    [self linkToController:@"ORL200Controller"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,2)
                                             withGuardian:self
                                           withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:L200DBConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
    [aConnector setConnectorType:'DB O'];
    [aConnector addRestrictedConnectionType:'DB I'];
    [aConnector release];
}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(runTypeChanged:)
                         name : ORRunTypeChangedNotification
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(awakeAfterDocumentLoaded)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(linkCC4sToDetectors)
                         name : ORRelinkSegments
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(awakeAfterDocumentLoaded)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
}

- (void) runTypeChanged:(NSNotification*) aNote
{
    [self getRunType:[aNote object]];
}


#pragma mark •••Accessors

- (int) viewType
{
    return viewType;
}

- (void) getRunType:(ORRunModel*)rc
{
    if(!rc){
        NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
        if([objs count]) runType = [[objs objectAtIndex:0] runType];
        else runType = 0x0;
    }
    else runType = [rc runType];
}

- (void) setViewType:(int)type
{
    [[[self undoManager] prepareWithInvocationTarget:self] setViewType:type];
    viewType = type;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL200ModelViewTypeChanged object:self userInfo:nil];
}

- (void) setDetectorStringPositions
{
    ORSegmentGroup* group = [self segmentGroup:kL200DetType];
    for(int i=0; i<[self numberSegmentsInGroup:kL200DetType]; i++){
        NSString* str = [[group segment:i] objectForKey:@"str_number"];
        NSString* pos = [[group segment:i] objectForKey:@"str_position"];
        NSString* strName = @"-";
        if(pos && str){
            if((![str hasPrefix:@"-"] && ![str isEqualToString:@""]) ||
               (![pos hasPrefix:@"-"] && ![pos isEqualToString:@""]))
                strName = [NSString stringWithFormat:@"Ge%@", str];
        }
        [group setSegment:i object:strName forKey:@"kStringName"];
    }
}

- (void) setSiPMPositions
{
    ORSegmentGroup* group = [self segmentGroup:kL200SiPMType];
    for(int i=0; i<[self numberSegmentsInGroup:kL200SiPMType]; i++){
        NSString* serial = [[group segment:i] objectForKey:@"serial"];
        NSString* name = @"-";
        if([serial length] > 1 && [[serial lowercaseString] hasPrefix:@"s"]){
            name = [serial substringWithRange:NSMakeRange(1, [serial length]-1)];
            while([name length] > 1 && [name hasPrefix:@"0"])
                name = [name substringWithRange:NSMakeRange(1, [name length]-1)];
        }
        [group setSegment:i object:name forKey:@"kStringName"];
        int index = [name intValue];
        if(index < kL200SiPMInnerChans){
            if(index%2){
                [group setSegment:i object:[NSNumber numberWithInt:1] forKey:@"kRing"];
                [group setSegment:i object:@"bottom inner"            forKey:@"kRingName"];
                [group setSegment:i object:@"Bot IB"                  forKey:@"kRingLabel"];
            }
            else{
                [group setSegment:i object:[NSNumber numberWithInt:0] forKey:@"kRing"];
                [group setSegment:i object:@"top inner"               forKey:@"kRingName"];
                [group setSegment:i object:@"Top IB"                  forKey:@"kRingLabel"];
            }
        }
        else{
            if(index%2){
                [group setSegment:i object:[NSNumber numberWithInt:3] forKey:@"kRing"];
                [group setSegment:i object:@"bottom outer"            forKey:@"kRingName"];
                [group setSegment:i object:@"Bot OB"                  forKey:@"kRingLabel"];
            }
            else{
                [group setSegment:i object:[NSNumber numberWithInt:2] forKey:@"kRing"];
                [group setSegment:i object:@"top outer"               forKey:@"kRingName"];
                [group setSegment:i object:@"Top OB"                  forKey:@"kRingLabel"];
            }
        }
    }
}

- (void) setPMTPositions
{
    ORSegmentGroup* group = [self segmentGroup:kL200PMTType];
    for(int i=0; i<[self numberSegmentsInGroup:kL200PMTType]; i++){
        NSString* serial = [[group segment:i] objectForKey:@"serial"];
        NSString* name = @"-";
        if([serial length] > 4 && [[serial lowercaseString] hasPrefix:@"pmt-"]){
            name = [serial substringWithRange:NSMakeRange(4, [serial length]-4)];
            while([name length] > 1 && [name hasPrefix:@"0"])
                name = [name substringWithRange:NSMakeRange(1, [name length]-1)];
        }
        [group setSegment:i object:name forKey:@"kStringName"];
        int index = [name intValue]/100 - 1;
        [group setSegment:i object:[NSNumber numberWithInt:index] forKey:@"kRing"];
        if(index == 0){
            [group setSegment:i object:@"pillbox"    forKey:@"kRingName"];
            [group setSegment:i object:@"Pillbox"    forKey:@"kRingLabel"];
        }
        else if(index == 1){
            [group setSegment:i object:@"floor inner" forKey:@"kRingName"];
            [group setSegment:i object:@"inner"       forKey:@"kRingLabel"];
        }
        else if(index == 2){
            [group setSegment:i object:@"floor outer" forKey:@"kRingName"];
            [group setSegment:i object:@"outer"       forKey:@"kRingLabel"];
        }
        else if(index == 3){
            [group setSegment:i object:@"2 m level"   forKey:@"kRingName"];
            [group setSegment:i object:@"2m"          forKey:@"kRingLabel"];
        }
        else if(index == 4){
            [group setSegment:i object:@"3.5 m level" forKey:@"kRingName"];
            [group setSegment:i object:@"3.5m"        forKey:@"kRingLabel"];
        }
        else if(index == 5){
            [group setSegment:i object:@"5 m level"   forKey:@"kRingName"];
            [group setSegment:i object:@"5m"          forKey:@"kRingLabel"];
        }
        else if(index == 6){
            [group setSegment:i object:@"6.5 m level" forKey:@"kRingName"];
            [group setSegment:i object:@"6.5m"        forKey:@"kRingLabel"];
        }
    }
}

- (void) setAuxChanPositions
{
    ORSegmentGroup* group = [self segmentGroup:kL200AuxType];
    for(int i=0; i<[self numberSegmentsInGroup:kL200AuxType]; i++){
        NSString* serial = [[group segment:i] objectForKey:@"serial"];
        NSString* name = @"-";
        if([serial length] > 4 && [[serial lowercaseString] hasPrefix:@"aux-"]){
            name = [serial substringWithRange:NSMakeRange(4, [serial length]-4)];
            while([name length] > 1 && [name hasPrefix:@"0"])
                name = [name substringWithRange:NSMakeRange(1, [name length]-1)];
        }
        [group setSegment:i object:name forKey:@"kStringName"];
    }
}

#pragma mark •••Segment Group Methods

- (NSMutableArray*) setupMapEntries:(int)groupIndex
{
    NSArray* keys = nil;
    if(groupIndex == kL200CC4Type){
        [self setCrateIndex:4   forGroup:groupIndex];
        [self setCardIndex:5    forGroup:groupIndex];
        [self setChannelIndex:6 forGroup:groupIndex];
        keys = [NSArray arrayWithObjects:@"cc4_name",  @"cc4_position", @"cc4_slot", @"cc4_chan",
                                         @"daq_crate", @"daq_board_slot",     @"daq_board_ch", nil];
    }
    else {
        if(groupIndex == kL200DetType){
            [self setCrateIndex:4   forGroup:groupIndex];
            [self setCardIndex:6    forGroup:groupIndex];
            [self setChannelIndex:7 forGroup:groupIndex];
            keys = [NSArray arrayWithObjects:@"serial",     @"det_type",
                    @"str_number",     @"str_position",
                    @"daq_crate",      @"daq_board_id",     @"daq_board_slot",   @"daq_board_ch",
                    @"hv_crate",       @"hv_board_slot",    @"hv_board_chan",    @"hv_cable",
                    @"hv_flange_id",   @"hv_flange_pos",
                    @"fe_cc4_ch",      @"fe_head_card_ana", @"fe_head_card_dig", @"fe_fanout_card",
                    @"fe_raspberrypi", @"fe_lmfe_id", nil];
        }
        else if(groupIndex > kL200DetType && groupIndex < kL200CC4Type){
            [self setCrateIndex:2   forGroup:groupIndex];
            [self setCardIndex:4    forGroup:groupIndex];
            [self setChannelIndex:5 forGroup:groupIndex];
            if(groupIndex == kL200SiPMType)
                keys = [NSArray arrayWithObjects:@"serial",  @"det_type",
                        @"daq_crate", @"daq_board_id",  @"daq_board_slot", @"daq_board_ch",
                        @"lv_crate",  @"lv_board_slot", @"lv_board_chan", nil];
            else if(groupIndex == kL200PMTType)
                keys = [NSArray arrayWithObjects:@"serial",  @"det_type",
                        @"daq_crate", @"daq_board_id",  @"daq_board_slot", @"daq_board_ch",
                        @"hv_crate",  @"hv_board_slot", @"hv_baord_chan", nil];
            else if(groupIndex == kL200AuxType)
                keys = [NSArray arrayWithObjects:@"serial", @"det_type",
                        @"daq_crate", @"daq_board_id",  @"daq_board_slot", @"daq_board_ch", nil];
        }
    }
    NSMutableArray* mapEntries = [NSMutableArray array];
    if(keys) for(id key in keys) [mapEntries addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        key, @"key",
                                                        [NSNumber numberWithInt:0], @"sortType", nil]];
    return mapEntries;
}

- (void) makeSegmentGroups
{
    ORL200SegmentGroup* dets = [[ORL200SegmentGroup alloc] initWithName:@"Detectors"
                                                            numSegments:kL200DetectorStrings*kL200MaxDetsPerString
                                                             mapEntries:[self setupMapEntries:kL200DetType]];
    [dets setType:kL200DetType];
    [self addGroup:dets];
    [dets release];
    
    ORL200SegmentGroup* sipms = [[ORL200SegmentGroup alloc] initWithName:@"SiPMs"
                                                             numSegments:kL200SiPMInnerChans+kL200SiPMOuterChans
                                                              mapEntries:[self setupMapEntries:kL200SiPMType]];
    [sipms setType:kL200SiPMType];
    [self addGroup:sipms];
    [sipms release];
    
    ORL200SegmentGroup* pmts = [[ORL200SegmentGroup alloc] initWithName:@"PMTs"
                                                            numSegments:kL200MuonVetoChans
                                                             mapEntries:[self setupMapEntries:kL200PMTType]];
    [pmts setType:kL200PMTType];
    [self addGroup:pmts];
    [pmts release];
    
    ORL200SegmentGroup* aux = [[ORL200SegmentGroup alloc] initWithName:@"AuxChans"
                                                           numSegments:kL200MaxAuxChans
                                                            mapEntries:[self setupMapEntries:kL200AuxType]];
    [aux setType:kL200AuxType];
    [self addGroup:aux];
    [aux release];
    
    ORL200SegmentGroup* cc4 = [[ORL200SegmentGroup alloc] initWithName:@"CC4Chans"
                                                           numSegments:kL200MaxCC4s
                                                            mapEntries:[self setupMapEntries:kL200CC4Type]];
    [cc4 setType:kL200CC4Type];
    [self addGroup:cc4];
    [cc4 release];
}

- (void) linkCC4sToDetectors
{
    ORSegmentGroup* cc4Group;
    if([segmentGroups count]>kL200CC4Type){
        cc4Group = [segmentGroups objectAtIndex:kL200CC4Type];
    }
    else {
        ORL200SegmentGroup* cc4 = [[ORL200SegmentGroup alloc] initWithName:@"CC4Chans"
                                                               numSegments:kL200MaxCC4s
                                                                mapEntries:[self setupMapEntries:kL200CC4Type]];
        [cc4 setType:kL200CC4Type];
        [self addGroup:cc4];
        cc4Group = cc4;
        [cc4 release];

    }
    ORSegmentGroup* detGroup = [segmentGroups objectAtIndex:kL200DetType];
    //make a look up table of the detector segments to speed up the linking
    NSMutableDictionary* detDict = [NSMutableDictionary dictionary];
    for(int detIndex=0;detIndex<[[detGroup segments] count];detIndex++){
        NSString* name          = [detGroup segment:detIndex objectForKey:@"fe_cc4_ch"];
        ORDetectorSegment* aSeg = [detGroup segment:detIndex];
        if(name)[detDict setObject:aSeg forKey:name];
    }
    //ok have the lookup table, do the linkage. Now it's O(n) instead of O(n^2)
    for(int cc4Index=0;cc4Index<[[cc4Group segments] count];cc4Index++){
        NSString* name    = [cc4Group segment:cc4Index objectForKey:@"cc4_name"];
        NSString* chan    = [cc4Group segment:cc4Index objectForKey:@"cc4_chan"];
        NSString* cc4Name = [NSString stringWithFormat:@"%@-%@",name,[chan removeSpaces]];
        ORDetectorSegment* detSeg = [detDict objectForKey:cc4Name];
        if(detSeg){
            NSString* crate = [detSeg objectForKey:@"daq_crate"];
            NSString* slot  = [detSeg objectForKey:@"daq_board_slot"];
            NSString* chan  = [detSeg objectForKey:@"daq_board_ch"];
            [[cc4Group segment:cc4Index] setObject:crate forKey:@"daq_crate"];
            [[cc4Group segment:cc4Index] setObject:slot  forKey:@"daq_board_slot"];
            [[cc4Group segment:cc4Index] setObject:chan  forKey:@"daq_board_ch"];
        }
    }
}

- (int) maxNumSegments
{
    return kL200DetectorStrings*kL200MaxDetsPerString;
}

- (int) numberSegmentsInGroup:(int)aGroup
{
    if(aGroup == kL200DetType) return [self maxNumSegments];
    else if(aGroup == kL200SiPMType) return kL200SiPMInnerChans+kL200SiPMOuterChans;
    else if(aGroup == kL200PMTType) return kL200MuonVetoChans;
    else if(aGroup == kL200AuxType) return kL200MaxAuxChans;
    else if(aGroup == kL200CC4Type) return kL200MaxCC4s;
    else return 0;
}

- (void) showDataSet:(NSString*)name forSet:(int)aSet segment:(int)index
{
    if(aSet >= 0 && aSet < [segmentGroups count]){
        ORSegmentGroup* group = [segmentGroups objectAtIndex:aSet];
        NSString* crate = [group segment:index objectForKey:@"daq_crate"];
        NSString* card  = [group segment:index objectForKey:@"daq_board_slot"];
        NSString* chan  = [group segment:index objectForKey:@"daq_board_ch"];
        if(!crate || !card || !chan) return;
        if([crate hasPrefix:@"-"] || [card hasPrefix:@"-"] || [chan hasPrefix:@"-"]) return;
        ORDataSet* dataSet = nil;
        [[[self document] collectObjectsOfClass:NSClassFromString(@"OrcaObject")] makeObjectsPerformSelector:@selector(clearLoopChecked)];
        NSArray* objs = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
        if([objs count]){
            NSArray* hists = [[objs objectAtIndex:0] collectConnectedObjectsOfClass:NSClassFromString(@"ORHistoModel")];
            if([hists count]){
                NSString* objName = [self objectNameForCrate:crate andCard:card];
                if(objName){
                    id hist = [hists objectAtIndex:0];
                    dataSet = [hist objectForKeyArray:[NSMutableArray arrayWithObjects:objName, name,
                                                       [NSString stringWithFormat:@"Crate %2d",  [crate intValue]],
                                                       [NSString stringWithFormat:@"Card %2d",   [card intValue]],
                                                       [NSString stringWithFormat:@"Channel %2d",[chan intValue]],
                                                       nil]];
                    [dataSet doDoubleClick:nil];

                }
            }
        }
    }
}

- (NSString*) objectNameForCrate:(NSString*)crateName andCard:(NSString*)cardName
{
    NSArray* crates = [[self document] collectObjectsOfClass:NSClassFromString(@"ORFlashCamCrateModel")];
    for(ORFlashCamCrateModel* crate in crates){
        if([crate crateNumber] == [crateName intValue]){
            NSArray* cards = [crate orcaObjects];
            for(id card in cards){
                if([card slot] == [cardName intValue]){
                    NSString* objName  = [[card className] stringByReplacingOccurrencesOfString:@"OR"
                                                                                     withString:@""];
                    return [objName stringByReplacingOccurrencesOfString:@"Model" withString:@""];
                }
            }
        }
    }
    return nil;
}

- (BOOL) validateDetector:(int)index
{
    if(index < 0 || index >= [self numberSegmentsInGroup:kL200DetType]) return NO;
    NSDictionary* params = [[[self segmentGroup:kL200DetType] segment:index] params];
    if(!params) return NO;
    NSString* crate = [params objectForKey:@"daq_crate"];
    NSString* card  = [params objectForKey:@"daq_board_slot"];
    NSString* chan  = [params objectForKey:@"daq_board_ch"];
    NSString* ser   = [params objectForKey:@"serial"];
    NSString* type  = [params objectForKey:@"det_type"];
    if(!crate || !card || !chan || !ser || !type) return NO;
    if([crate length] == 0 || [crate rangeOfString:@"-"].location != NSNotFound) return NO;
    if([card  length] == 0 || [card  rangeOfString:@"-"].location != NSNotFound) return NO;
    if([chan  length] == 0 || [chan  rangeOfString:@"-"].location != NSNotFound) return NO;
    if([ser   length] == 0 || [ser   rangeOfString:@"-"].location != NSNotFound) return NO;
    if([type  length] == 0 || [ser   rangeOfString:@"-"].location != NSNotFound) return NO;
    return YES;
}

- (BOOL) validateSiPM:(int)index
{
    if(index < 0 || index >= [self numberSegmentsInGroup:kL200SiPMType]) return NO;
    NSDictionary* params = [[[self segmentGroup:kL200SiPMType] segment:index] params];
    if(!params) return NO;
    NSString* crate = [params objectForKey:@"daq_crate"];
    NSString* card  = [params objectForKey:@"daq_board_slot"];
    NSString* chan  = [params objectForKey:@"daq_board_ch"];
    NSString* ser   = [params objectForKey:@"serial"];
    if(!crate || !card || !chan || !ser) return NO;
    if([crate length] == 0 || [crate rangeOfString:@"-"].location != NSNotFound) return NO;
    if([card length]  == 0 || [card  rangeOfString:@"-"].location != NSNotFound) return NO;
    if([chan length]  == 0 || [chan  rangeOfString:@"-"].location != NSNotFound) return NO;
    if([ser length]   == 0 || [ser   rangeOfString:@"-"].location != NSNotFound) return NO;
    return YES;
}

- (BOOL) validatePMT:(int)index
{
    if(index < 0 || index >= [self numberSegmentsInGroup:kL200PMTType]) return NO;
    NSDictionary* params = [[[self segmentGroup:kL200PMTType] segment:index] params];
    if(!params) return NO;
    NSString* crate = [params objectForKey:@"daq_crate"];
    NSString* card  = [params objectForKey:@"daq_board_slot"];
    NSString* chan  = [params objectForKey:@"daq_board_ch"];
    NSString* ser   = [params objectForKey:@"serial"];
    if(!crate || !card || !chan || !ser) return NO;
    if([crate length] == 0 || [crate rangeOfString:@"-"].location != NSNotFound) return NO;
    if([card length]  == 0 || [card  rangeOfString:@"-"].location != NSNotFound) return NO;
    if([chan length]  == 0 || [chan  rangeOfString:@"-"].location != NSNotFound) return NO;
    if([ser length]   == 0 || [ser       hasPrefix:@"-"]) return NO;
    return YES;
}

- (BOOL) validateAuxChan:(int)index
{
    if(index < 0 || index >= [self numberSegmentsInGroup:kL200AuxType]) return NO;
    NSDictionary* params = [[[self segmentGroup:kL200AuxType] segment:index] params];
    if(!params) return NO;
    NSString* crate = [params objectForKey:@"daq_crate"];
    NSString* card  = [params objectForKey:@"daq_board_slot"];
    NSString* chan  = [params objectForKey:@"daq_board_ch"];
    NSString* ser   = [params objectForKey:@"serial"];
    if(!crate || !card || !chan || !ser) return NO;
    if([crate length] == 0 || [crate rangeOfString:@"-"].location != NSNotFound) return NO;
    if([card length]  == 0 || [card  rangeOfString:@"-"].location != NSNotFound) return NO;
    if([chan length]  == 0 || [chan  rangeOfString:@"-"].location != NSNotFound) return NO;
    if([ser length]   == 0 || [ser       hasPrefix:@"-"]) return NO;
    return YES;
}

- (BOOL) validateCC4:(int)index
{
    if(index < 0 || index >= [self numberSegmentsInGroup:kL200CC4Type]) return NO;
    NSDictionary* params = [[[self segmentGroup:kL200CC4Type] segment:index] params];
    if(!params) return NO;
    NSString* name      = [params objectForKey:@"cc4_name"];
    NSString* position  = [params objectForKey:@"cc4_position"]; //1...12
    NSString* slot      = [params objectForKey:@"cc4_slot"];     //0,1
    if(!position || !slot ) return NO;
    if([name length]      == 0 || [name      rangeOfString:@"-"].location != NSNotFound) return NO;
    if([position length]  == 0 || [position  rangeOfString:@"-"].location != NSNotFound) return NO;
    if([slot length]      == 0 || [slot      rangeOfString:@"-"].location != NSNotFound) return NO;
    return YES;
}

- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
    if([aString length] == 0) return @"Not mapped";
    NSArray* parts = [aString componentsSeparatedByString:@"\n"];
    NSMutableString* s = [NSMutableString string];

    if(aSet == kL200DetType)       [s appendString:@"Detector\n"];
    else if(aSet == kL200SiPMType) [s appendString:@"SiPM\n"];
    else if(aSet == kL200PMTType)  [s appendString:@"PMT\n"];
    else if(aSet == kL200AuxType)  [s appendString:@"Aux Chan\n"];
    else if(aSet == kL200CC4Type)  [s appendString:@"CC4\n"];

    if(aSet == kL200DetType){
        [s appendString:@"   String\n"];
        [s appendFormat:@"           Num: %@\n", [self valueForLabel:@"tr_number"      fromParts:parts]];
        [s appendFormat:@"           Pos: %@\n", [self valueForLabel:@"tr_pos"         fromParts:parts]];
    }
    else if(aSet == kL200SiPMType || aSet == kL200PMTType){
        [s appendFormat:@"           Pos: %@\n", [self valueForLabel:@"RingName"        fromParts:parts]];
    }
    if(aSet != kL200CC4Type){
        [s appendFormat:@"            ID: %@\n",     [self valueForLabel:@"Segment"        fromParts:parts]];
        [s appendFormat:@"        Serial: %@\n",     [self valueForLabel:@"erial"          fromParts:parts]];
        [s appendString:@"   DAQ\n"];
        [s appendFormat:@"         Crate: %@\n",     [self valueForLabel:@"aq_crate"        fromParts:parts]];
        [s appendFormat:@"         Board: %@\n",     [self valueForLabel:@"aq_board_id"     fromParts:parts]];
        [s appendFormat:@"          Slot: %@\n",     [self valueForLabel:@"aq_board_slot"   fromParts:parts]];
        [s appendFormat:@"          Chan: %@\n",     [self valueForLabel:@"aq_board_ch"     fromParts:parts]];
    }
    if(aSet == kL200DetType || aSet == kL200PMTType){
        [s appendString:@"   HV\n"];
        [s appendFormat:@"         Crate: %@\n", [self valueForLabel:@"v_crate"         fromParts:parts]];
        [s appendFormat:@"          Slot: %@\n", [self valueForLabel:@"v_board_slot"    fromParts:parts]];
        [s appendFormat:@"          Chan: %@\n", [self valueForLabel:@"v_board_chan"    fromParts:parts]];
    }
    if(aSet == kL200SiPMType){
        [s appendString:@"   LV\n"];
        [s appendFormat:@"          Crate: %@\n", [self valueForLabel:@"v_crate"        fromParts:parts]];
        [s appendFormat:@"           Slot: %@\n", [self valueForLabel:@"v_board_slot"   fromParts:parts]];
        [s appendFormat:@"           Chan: %@\n", [self valueForLabel:@"v_board_chan"   fromParts:parts]];
    }
    else if(aSet == kL200DetType){
        [s appendFormat:@"         Cable: %@\n", [self valueForLabel:@"v_cable"         fromParts:parts]];
        [s appendFormat:@"   HV Flange\n"];
        [s appendFormat:@"            ID: %@\n", [self valueForLabel:@"v_flange_id"     fromParts:parts]];
        [s appendFormat:@"           Pos: %@\n", [self valueForLabel:@"v_flange_pos"    fromParts:parts]];
        [s appendString:@"   Front-End\n"];
        [s appendFormat:@"        CC4 Ch: %@\n", [self valueForLabel:@"e_cc4_ch"        fromParts:parts]];
        [s appendFormat:@"      Head Ana: %@\n", [self valueForLabel:@"e_head_card_ana" fromParts:parts]];
        [s appendFormat:@"      Head Dig: %@\n", [self valueForLabel:@"e_head_card_dig" fromParts:parts]];
        [s appendFormat:@"        Fanout: %@\n", [self valueForLabel:@"e_fanout_card"   fromParts:parts]];
        [s appendFormat:@"           RPi: %@\n", [self valueForLabel:@"e_raspberrypi"   fromParts:parts]];
        [s appendFormat:@"          LMFE: %@\n", [self valueForLabel:@"e_lmfe_id"       fromParts:parts]];
    }
    else if(aSet==kL200CC4Type){
        if([[self valueForLabel:@"c4_position"   fromParts:parts]length]){
            [s appendFormat:@"      Position: %@\n",   [self valueForLabel:@"c4_position"   fromParts:parts]];
            [s appendFormat:@"          Slot: %@\n",   [self valueForLabel:@"c4_slot"       fromParts:parts]];
            [s appendFormat:@"          Chan: %@\n",   [self valueForLabel:@"c4_chan"       fromParts:parts]];
            [s appendFormat:@"          Name: %@-%@\n",[self valueForLabel:@"c4_name"       fromParts:parts],
                                                       [self valueForLabel:@"c4_chan"       fromParts:parts]];
            
            //NSString* name = [self valueForLabel:@"c4_name" fromParts:parts];
            [s appendString:@"      DAQ\n"];
            if([[self valueForLabel:@"aq_crate"    fromParts:parts] length]){
                [s appendFormat:@"         Crate: %@\n",     [self valueForLabel:@"aq_crate"    fromParts:parts]];
                [s appendFormat:@"          Slot: %@\n",     [self valueForLabel:@"aq_board_slot"     fromParts:parts]];
                [s appendFormat:@"          Chan: %@\n",     [self valueForLabel:@"aq_board_ch"     fromParts:parts]];
            }
            else {
                [s appendFormat:@"         Crate: -\n"];
                [s appendFormat:@"          Slot: -\n"];
                [s appendFormat:@"          Chan: -\n"];
            }
        }
        else  [s appendFormat:@"Not Mapped\n"];
    }
    return s;
}

- (NSString*) valueForLabel:(NSString*)label fromParts:(NSArray*)parts
{
    for(id line in parts){
        if([line rangeOfString:label].location != NSNotFound){
            NSArray* subParts = [line componentsSeparatedByString:@":"];
            if([subParts count] >= 2) return [[subParts objectAtIndex:1]trimSpacesFromEnds];
        }
    }
    return @"";
}

    
#pragma mark •••Archival

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [[self segmentGroup:kL200DetType]  addParametersToDictionary:dict useName:@"DetectorMap" addInGroupName:NO];
    [[self segmentGroup:kL200SiPMType] addParametersToDictionary:dict useName:@"SiPMMap"     addInGroupName:NO];
    [[self segmentGroup:kL200PMTType]  addParametersToDictionary:dict useName:@"PMTMap"      addInGroupName:NO];
    [[self segmentGroup:kL200AuxType]  addParametersToDictionary:dict useName:@"AuxChanMap"  addInGroupName:NO];
    [[self segmentGroup:kL200CC4Type]  addParametersToDictionary:dict useName:@"CC4Map"      addInGroupName:NO];
    [dictionary setObject:dict forKey:[self className]];
    return dictionary;
}

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setViewType:[decoder decodeIntForKey:@"viewType"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:viewType forKey:@"viewType"];
}

- (void) postCouchDBRecord
{
    NSMutableDictionary* values  = [NSMutableDictionary dictionary];
    NSMutableDictionary* history = [NSMutableDictionary dictionary];
    NSString* s = [NSString stringWithFormat:@"%@,%u", [self className], [self uniqueIdNumber]];
    [history setObject:s forKey:@"name"];
    [history setObject:s forKey:@"title"];
    for(int itype=0; itype<kL200SegmentTypeCount; itype++){
        NSMutableDictionary* dict        = [NSMutableDictionary dictionary];
        NSMutableDictionary* hist        = [NSMutableDictionary dictionary];
        NSMutableDictionary* id_to_index = [NSMutableDictionary dictionary];
        NSMutableArray* thresholds = [NSMutableArray array];
        NSMutableArray* trigCounts = [NSMutableArray array];
        NSMutableArray* trigRates  = [NSMutableArray array];
        NSMutableArray* wfCounts   = [NSMutableArray array];
        NSMutableArray* wfRates    = [NSMutableArray array];
        NSMutableArray* baseline   = [NSMutableArray array];
        NSMutableArray* online     = [NSMutableArray array];
        ORL200SegmentGroup* group = (ORL200SegmentGroup*) [self segmentGroup:itype];
        NSDictionary* chanMap = [group dictMap];
        NSArray* totalRate = [[group totalRate] ratesAsArray];
        for(int iseg=0; iseg<[self numberSegmentsInGroup:itype]; iseg++){
            ORDetectorSegment* segment = [group segment:iseg];
            NSArray* params = [[segment paramsAsString] componentsSeparatedByString:@","];
            if([params count] == 0) continue;
            if([[params objectAtIndex:0] isEqualToString:@""] ||
               [[params objectAtIndex:0] hasPrefix:@"-"]) continue;
            [id_to_index setObject:[NSNumber numberWithUnsignedLong:[thresholds count]]
                            forKey:[params objectAtIndex:0]];
            [thresholds addObject:[NSNumber numberWithFloat:[group getThreshold:iseg]]];
            [trigCounts addObject:[NSNumber numberWithFloat:[group getTotalCounts:iseg]]];
            [trigRates  addObject:[NSNumber numberWithFloat:[group getRate:iseg]]];
            [wfCounts   addObject:[NSNumber numberWithFloat:[group getWaveformCounts:iseg]]];
            [wfRates    addObject:[NSNumber numberWithFloat:[group getWaveformRate:iseg]]];
            [baseline   addObject:[NSNumber numberWithDouble:[group getBaseline:iseg]]];
            [online     addObject:[NSNumber numberWithFloat:[group online:iseg]]];
        }
        [dict setObject:id_to_index forKey:@"serialToIndex"];
        if(chanMap)             [dict setObject:chanMap   forKey:@"chanMap"];
        if(totalRate)           [dict setObject:totalRate forKey:@"totalRate"];
        if([thresholds count]) [dict setObject:thresholds forKey:@"thresholds"];
        if([trigCounts count]) [dict setObject:trigCounts forKey:@"trigCounts"];
        if([trigRates  count]) [dict setObject:trigRates  forKey:@"trigRates"];
        if([wfCounts   count]) [dict setObject:wfCounts   forKey:@"wfCounts"];
        if([wfRates    count]) [dict setObject:wfRates    forKey:@"wfRates"];
        if([baseline   count]) [dict setObject:baseline   forKey:@"baseline"];
        if([online     count]) [dict setObject:online     forKey:@"online"];
        [values setObject:dict forKey:[group groupName]];
        [hist setObject:id_to_index forKey:@"serialToIndex"];
        if([trigRates  count]) [hist setObject:trigRates  forKey:@"trigRates"];
        if([wfRates    count]) [hist setObject:wfRates    forKey:@"wfRates"];
        if([baseline   count]) [hist setObject:baseline   forKey:@"baseline"];
        [history setObject:hist forKey:[group groupName]];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord"
                                                        object:self
                                                      userInfo:values];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddHistoryAdcRecord"
                                                        object:self
                                                      userInfo:history];
}
@end

@implementation ORL200HeaderRecordID
- (NSString*) fullID
{
    return @"L200DataHeader";
}
@end
