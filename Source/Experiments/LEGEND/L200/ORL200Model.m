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

static NSString* L200DBConnector = @"L200DBConnector";
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
    [super awakeAfterDocumentLoaded];
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
    NSImage* cimage = [NSImage imageNamed:@"L200"];
    NSSize size = [cimage size];
    NSSize newsize;
    newsize.width  = 0.125 * size.width;
    newsize.height = 0.125 * size.height;
    NSImage* image = [[NSImage alloc] initWithSize:newsize];
    [image lockFocus];
    NSRect rect;
    rect.origin = NSZeroPoint;
    rect.size.width  = newsize.width;
    rect.size.height = newsize.height;
    [cimage drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [image unlockFocus];
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
            if(![str isEqualToString:@"--"] && ![str isEqualToString:@""] ||
               ![pos isEqualToString:@"--"] && ![pos isEqualToString:@""])
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
    if(groupIndex == kL200DetType){
        [self setCrateIndex:4   forGroup:groupIndex];
        [self setCardIndex:6    forGroup:groupIndex];
        [self setChannelIndex:7 forGroup:groupIndex];
        keys = [NSArray arrayWithObjects:@"serial", @"det_type",
                @"str_number",     @"str_position",
                @"daq_crate",      @"daq_board_id",     @"daq_board_slot",   @"daq_board_ch",
                @"hv_crate",       @"hv_board_slot",    @"hv_board_chan",    @"hv_cable",
                @"hv_flange_id",   @"hv_flange_pos",
                @"fe_cc4_ch",      @"fe_head_card_ana", @"fe_head_card_dig", @"fe_fanout_card",
                @"fe_raspberrypi", @"fe_lmfe_id", nil];
    }
    else if(groupIndex > kL200DetType && groupIndex < kL200SegmentTypeCount){
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

- (NSString*) reformatSelectionString:(NSString*)aString forSet:(int)aSet
{
    if([aString length] == 0) return @"Not mapped";
    NSArray* parts = [aString componentsSeparatedByString:@"\n"];
    NSMutableString* s = [NSMutableString string];
    if(aSet == kL200DetType)       [s appendString:@"Detector\n"];
    else if(aSet == kL200SiPMType) [s appendString:@"SiPM\n"];
    else if(aSet == kL200PMTType)  [s appendString:@"PMT\n"];
    else if(aSet == kL200AuxType)  [s appendString:@"Aux Chan\n"];
    [s appendFormat:@"            ID: %@\n",     [self valueForLabel:@"Segment"        fromParts:parts]];
    [s appendFormat:@"        Serial: %@\n",     [self valueForLabel:@"erial"          fromParts:parts]];
    if(aSet == kL200DetType){
        [s appendString:@"   String\n"];
        [s appendFormat:@"           Num: %@\n", [self valueForLabel:@"tr_number"      fromParts:parts]];
        [s appendFormat:@"           Pos: %@\n", [self valueForLabel:@"tr_pos"         fromParts:parts]];
    }
    else if(aSet == kL200SiPMType || aSet == kL200PMTType){
        [s appendFormat:@"           Pos: %@\n", [self valueForLabel:@"RingName"        fromParts:parts]];
    }
    [s appendString:@"   DAQ\n"];
    [s appendFormat:@"         Crate: %@\n",     [self valueForLabel:@"aq_crate"        fromParts:parts]];
    [s appendFormat:@"         Board: %@\n",     [self valueForLabel:@"aq_board_id"     fromParts:parts]];
    [s appendFormat:@"          Slot: %@\n",     [self valueForLabel:@"aq_board_slot"   fromParts:parts]];
    [s appendFormat:@"          Chan: %@\n",     [self valueForLabel:@"aq_board_ch"     fromParts:parts]];
    if(aSet == kL200DetType || aSet == kL200PMTType){
        [s appendString:@"   HV\n"];
        [s appendFormat:@"         Crate: %@\n", [self valueForLabel:@"v_crate"         fromParts:parts]];
        [s appendFormat:@"          Slot: %@\n", [self valueForLabel:@"v_board_slot"    fromParts:parts]];
        [s appendFormat:@"          Chan: %@\n", [self valueForLabel:@"v_board_chan"    fromParts:parts]];
    }
    else if(aSet == kL200SiPMType){
        [s appendString:@"   LV\n"];
        [s appendFormat:@"          Crate: %@\n", [self valueForLabel:@"v_crate"        fromParts:parts]];
        [s appendFormat:@"           Slot: %@\n", [self valueForLabel:@"v_board_slot"   fromParts:parts]];
        [s appendFormat:@"           Chan: %@\n", [self valueForLabel:@"v_board_chan"   fromParts:parts]];
    }
    if(aSet == kL200DetType){
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
    return s;
}

- (NSString*) valueForLabel:(NSString*)label fromParts:(NSArray*)parts
{
    for(id line in parts){
        if([line rangeOfString:label].location != NSNotFound){
            NSArray* subParts = [line componentsSeparatedByString:@":"];
            if([subParts count] >= 2) return [subParts objectAtIndex:1];
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
    [dictionary setObject:dict forKey:[self className]];
    return dictionary;
}

- (id) initWithCoder:(NSCoder*)decoder{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setViewType:[decoder decodeIntForKey:@"viewType"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:viewType forKey:@"viewType"];
}

@end

@implementation ORL200HeaderRecordID
- (NSString*) fullID
{
    return @"L200DataHeader";
}
@end
