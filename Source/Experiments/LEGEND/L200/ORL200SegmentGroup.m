//  Orca
//  ORL200SegmentGroup.m
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

#import "ORL200SegmentGroup.h"
#import "ORDetectorSegment.h"
#import "ORFlashCamADCModel.h"

NSString* ORRelinkSegments   = @"ORRelinkSegments";

@implementation ORL200SegmentGroup

#pragma mark •••Accessors

- (unsigned int) type
{
    return type;
}

- (void) setType:(unsigned int)segType
{
    if(segType < kL200SegmentTypeCount) type = segType;
}

- (float) waveformRate
{
    float rate = 0.0;
    for(int i=0; i<[segments count]; i++) rate += [self getWaveformRate:i];
    return rate;
}

- (float) getWaveformRate:(int)index
{
    if(index < 0 || index >= [segments count]) return 0.0;
    ORDetectorSegment* segment = [segments objectAtIndex:index];
    id card = [segment hardwareCard];
    if(![card respondsToSelector:@selector(getWFrate:)]) return 0.0;
    return [card getWFrate:[segment channel]];
    
}

- (float) getWaveformCounts:(int)index
{
    if(index < 0 || index >= [segments count]) return 0.0;
    ORDetectorSegment* segment = [segments objectAtIndex:index];
    id card = [segment hardwareCard];
    if(![card respondsToSelector:@selector(wfCount:)]) return 0.0;
    return [card wfCount:[segment channel]];
}

- (double) getBaseline:(int)index
{
    if(index < 0 || index >= [segments count]) return 0.0;
    ORDetectorSegment* segment = [segments objectAtIndex:index];
    id card = [segment hardwareCard];
    if(![card respondsToSelector:@selector(baselineHistory:)]) return 0.0;
    if(![card enableBaselineHistory] || ![card isRunning]) return 0.0;
    ORTimeRate* baseHistory = [card baselineHistory:[segment channel]];
    return [baseHistory valueAtIndex:[baseHistory count]-1];
}

#pragma mark •••Map Methods

- (void) readMap:(NSString*)aPath
{
    // get the json dictionary
    [self setMapFile:aPath];
    NSData* data = [NSData dataWithContentsOfFile:aPath];
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    // reset the detector segments
    for(ORDetectorSegment* segment in segments){
        [segment setHwPresent:NO];
        [segment setParams:nil];
    }
    // get the list of string number/position or serial number and sort
    NSMutableArray* channels = [NSMutableArray array];
    NSArray* chans = nil;
    if(type == kL200DetType){
        for(id key in dict){
            NSMutableDictionary* d = [NSMutableDictionary dictionary];
            [d setObject:key forKey:@"key"];
            [d setObject:[[dict objectForKey:key] objectForKey:@"string"] forKey:@"value"];
            [channels addObject:d];
        }
        chans = [channels sortedArrayUsingComparator:^NSComparisonResult(id obj0, id obj1) {
            NSString* s0 = [[obj0 objectForKey:@"value"] objectForKey:@"number"];
            NSString* s1 = [[obj1 objectForKey:@"value"] objectForKey:@"number"];
            if([s0 intValue] == [s1 intValue]){
                NSString* p0 = [[obj0 objectForKey:@"value"] objectForKey:@"position"];
                NSString* p1 = [[obj1 objectForKey:@"value"] objectForKey:@"position"];
                if([p0 intValue] == [p1 intValue])
                    return [[obj0 objectForKey:@"key"] compare:[obj1 objectForKey:@"key"]
                                                       options:NSCaseInsensitiveSearch];
                int vp0 = 0, vp1 = 0;
                NSScanner* sp0 = [NSScanner scannerWithString:p0];
                if(![sp0 scanInt:&vp0] || ![sp0 isAtEnd]) return 1;
                NSScanner* sp1 = [NSScanner scannerWithString:p1];
                if(![sp1 scanInt:&vp1] || ![sp1 isAtEnd]) return -1;
                return vp0 > vp1;
            }
            int vs0 = 0, vs1 = 0;
            NSScanner* ss0 = [NSScanner scannerWithString:s0];
            if(![ss0 scanInt:&vs0] || ![ss0 isAtEnd]) return 1;
            NSScanner* ss1 = [NSScanner scannerWithString:s1];
            if(![ss1 scanInt:&vs1] || ![ss1 isAtEnd]) return -1;
            return vs0 > vs1;
        }];
    }
    else{
        for(id key in dict) [channels addObject:[NSString stringWithString:key]];
        chans = [NSArray array];
        chans = [channels sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        if(type == kL200CC4Type){
            for(id aPosition in chans){
                NSDictionary* segInfo = [[dict objectForKey:aPosition]objectForKey:@"cc4"];
                int pos  = [[segInfo objectForKey:@"cc4_position"] intValue];
                int slot = [[segInfo objectForKey:@"cc4_slot"]     intValue];
                int segNum = pos*14;
                if(slot==1)  segNum+=7;
                for(int chan=0;chan<7;chan++){
                    NSString* line = [NSString stringWithFormat:@"%@,%@,%@,%d",
                                      [segInfo objectForKey:@"cc4_name"],
                                      [segInfo objectForKey:@"cc4_position"],
                                      [segInfo objectForKey:@"cc4_slot"],
                                      chan];
                    ORDetectorSegment* segment = [segments objectAtIndex:segNum+chan];
                    [segment decodeLine:line];
                }
            }
        }
        else if(type == kL200ADCType){
            int index = -1;
            for(id adc in chans){
                index ++;
                NSDictionary* adcInfo = [[dict objectForKey:adc] objectForKey:@"daq"];
                NSString* line = [NSString stringWithFormat:@"%@,%@,%@,%@,%@",
                                  [adcInfo objectForKey:@"daq_crate"],
                                  [adcInfo objectForKey:@"daq_board_id"],
                                  [adcInfo objectForKey:@"daq_board_slot"],
                                  [adcInfo objectForKey:@"adc_serial_0"],
                                  [adcInfo objectForKey:@"adc_serial_1"]];
                ORDetectorSegment* segment = [segments objectAtIndex:index];
                [segment decodeLine:line];
            }
        }
    }
    // get the parameters from the json data
    if(type != kL200CC4Type){
        int index = -1;
        for(id chan in chans){
            index++;
            NSString* key;
            
            if(type == kL200DetType) key = [chan objectForKey:@"key"];
            else key = [NSString stringWithString:chan];
            NSDictionary*  ch_dict = [dict    objectForKey:key];
            NSDictionary* daq_dict = [ch_dict objectForKey:@"daq"];
            NSString* ch  = [NSString stringWithFormat:@"%@,%@,", key,
                             [ch_dict  objectForKey:@"det_type"]];
            NSMutableString* daq = [NSMutableString stringWithFormat:@"%@,%@,%@,%@,",
                             [daq_dict objectForKey:@"crate"],
                             [daq_dict objectForKey:@"board_id"],
                             [daq_dict objectForKey:@"board_slot"],
                             [daq_dict objectForKey:@"board_ch"]];
            if([daq_dict objectForKey:@"adc_serial"])
                [daq appendFormat:@"%@,", [daq_dict objectForKey:@"adc_serial"]];
            else [daq appendString:@"--,"];
            NSString* line = @"";
            if(type == kL200DetType){
                NSDictionary* str_dict = [ch_dict objectForKey:@"string"];
                NSDictionary*  hv_dict = [ch_dict objectForKey:@"high_voltage"];
                NSDictionary*  fe_dict = [ch_dict objectForKey:@"electronics"];
                NSString* str = [NSString stringWithFormat:@"%@,%@,",
                                 [str_dict objectForKey:@"number"],
                                 [str_dict objectForKey:@"position"]];
                NSString* hv  = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,",
                                 [hv_dict  objectForKey:@"crate"],
                                 [hv_dict  objectForKey:@"board_slot"],
                                 [hv_dict  objectForKey:@"board_chan"],
                                 [hv_dict  objectForKey:@"cable"],
                                 [hv_dict  objectForKey:@"flange_id"],
                                 [hv_dict  objectForKey:@"flange_pos"]];
                NSString* fe  = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@",
                                 [fe_dict  objectForKey:@"cc4_ch"],
                                 [fe_dict  objectForKey:@"head_card_ana"],
                                 [fe_dict  objectForKey:@"head_card_dig"],
                                 [fe_dict  objectForKey:@"fanout_card"],
                                 [fe_dict  objectForKey:@"raspberrypi"],
                                 [fe_dict  objectForKey:@"lmfe_id"]];
                line = [NSString stringWithFormat:@"%@%@%@%@%@", ch, str, daq, hv, fe];
            }
            else if(type == kL200SiPMType){
                NSDictionary* lv_dict = [ch_dict objectForKey:@"low_voltage"];
                NSString* lv = [NSString stringWithFormat:@"%@,%@,%@",
                                [lv_dict objectForKey:@"crate"],
                                [lv_dict objectForKey:@"board_slot"],
                                [lv_dict objectForKey:@"board_chan"]];
                line = [NSString stringWithFormat:@"%@%@%@", ch, daq, lv];
                
            }
            else if(type == kL200PMTType){
                NSDictionary* hv_dict = [ch_dict objectForKey:@"high_voltage"];
                NSString* hv = [NSString stringWithFormat:@"%@,%@,%@",
                                [hv_dict objectForKey:@"crate"],
                                [hv_dict objectForKey:@"board_slot"],
                                [hv_dict objectForKey:@"board_chan"]];
                line = [NSString stringWithFormat:@"%@%@%@", ch, daq, hv];
            }
            else if(type == kL200AuxType){
                line = [NSString stringWithFormat:@"%@%@", ch, daq];
            }
            else return;
            ORDetectorSegment* segment = [segments objectAtIndex:index];
            if(type == kL200DetType){
                [segment setCrateIndex:4];
                [segment setCardIndex:6];
                [segment setChannelIndex:7];
            }
            else{
                [segment setCrateIndex:2];
                [segment setCardIndex:4];
                [segment setChannelIndex:5];
            }
            [segment decodeLine:line];
            [segment setObject:[NSNumber numberWithInt:index] forKey:@"kSegmentNumber"];
            [segment setObject:key forKey:@"kDetector"];
        }
    }
    [self configurationChanged:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSegmentGroupMapReadNotification object:self];
}

- (void) saveMapFileAs:(NSString*)newFileName
{
    NSData* data = [self jsonMap];
    if(data){
        NSFileManager* fmanager = [NSFileManager defaultManager];
        if([fmanager fileExistsAtPath:newFileName]) [fmanager removeItemAtPath:newFileName error:nil];
        [fmanager createFileAtPath:newFileName contents:data attributes:nil];
        [self setMapFile:newFileName];
    }
    else NSLogColor([NSColor redColor], @"ORL200SegmentGroup: failed to save map file %d\n", type);
}

- (NSDictionary*) dictMap
{
    // build the json data
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    if(type == kL200CC4Type){
        int index = 0;
        for(NSUInteger i=0; i<[segments count]; i+=7){
            ORDetectorSegment* segment = [segments objectAtIndex:i];
            NSArray* params = [[segment paramsAsString] componentsSeparatedByString:@","];
            if([params count] == 0) continue;
            if([[params objectAtIndex:0] isEqualToString:@""] ||
               [[params objectAtIndex:0] hasPrefix:@"-"]) continue;
            NSDictionary* ch_dict = nil;
            NSDictionary* daq_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [params objectAtIndex:0], @"cc4_name",
                                      [params objectAtIndex:1], @"cc4_position",
                                      [params objectAtIndex:2], @"cc4_slot",
                                      nil];
            ch_dict = [NSDictionary dictionaryWithObjectsAndKeys: @"cc4", @"system", daq_dict, @"cc4", nil];
            if(ch_dict) [dict setObject:ch_dict forKey:[NSString stringWithFormat:@"%d",index++]];
        }
    }
    else {
        for(NSUInteger i=0; i<[segments count]; i++){
            ORDetectorSegment* segment = [segments objectAtIndex:i];
            NSArray* params = [[segment paramsAsString] componentsSeparatedByString:@","];
            if([params count] == 0) continue;
            if([[params objectAtIndex:0] isEqualToString:@""] ||
               [[params objectAtIndex:0] hasPrefix:@"-"]) continue;
            NSDictionary* ch_dict = nil;
            
            if(type == kL200DetType){
                NSDictionary* str_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [params objectAtIndex:2], @"number",
                                          [params objectAtIndex:3], @"position", nil];
                NSMutableDictionary* daq_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                 [params objectAtIndex:4], @"crate",
                                                 [params objectAtIndex:5], @"board_id",
                                                 [params objectAtIndex:6], @"board_slot",
                                                 [params objectAtIndex:7], @"board_ch",
                                                 [params objectAtIndex:8], @"adc_serial", nil];
                NSDictionary* hv_dict  = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [params objectAtIndex:9], @"crate",
                                          [params objectAtIndex:10], @"board_slot",
                                          [params objectAtIndex:11], @"board_chan",
                                          [params objectAtIndex:12], @"cable",
                                          [params objectAtIndex:13], @"flange_id",
                                          [params objectAtIndex:14], @"flange_pos", nil];
                NSDictionary* fe_dict  = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [params objectAtIndex:15], @"cc4_ch",
                                          [params objectAtIndex:16], @"head_card_ana",
                                          [params objectAtIndex:17], @"head_card_dig",
                                          [params objectAtIndex:18], @"fanout_card",
                                          [params objectAtIndex:19], @"raspberrypi",
                                          [params objectAtIndex:20], @"lmfe_id", nil];
                ch_dict  = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"ged", @"system",
                            [params objectAtIndex:1], @"det_type",
                            str_dict, @"string",       daq_dict, @"daq",
                            hv_dict,  @"high_voltage", fe_dict,  @"electronics", nil];
            }
            else if(type > kL200DetType && type < kL200SegmentTypeCount){
                NSDictionary* daq_dict;
                if(type == kL200ADCType) daq_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     [params objectAtIndex:0], @"crate",
                                                     [params objectAtIndex:1], @"board_id",
                                                     [params objectAtIndex:2], @"board_slot",
                                                     [params objectAtIndex:3], @"adc_serial_0",
                                                     [params objectAtIndex:4], @"adc_serial_1", nil];
                else daq_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [params objectAtIndex:2], @"crate",
                                 [params objectAtIndex:3], @"board_id",
                                 [params objectAtIndex:4], @"board_slot",
                                 [params objectAtIndex:5], @"board_ch",
                                 [params objectAtIndex:6], @"adc_serial", nil];
                if(type == kL200SiPMType || type == kL200PMTType){
                    NSDictionary* v_dict  = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [params objectAtIndex:7], @"crate",
                                             [params objectAtIndex:8], @"board_slot",
                                             [params objectAtIndex:9], @"board_chan", nil];
                    if(type == kL200SiPMType)
                        ch_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"spm", @"system",
                                   [params objectAtIndex:1], @"det_type",
                                   daq_dict, @"daq", v_dict, @"low_voltage", nil];
                    else if(type == kL200PMTType)
                        ch_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"pmt", @"system",
                                   [params objectAtIndex:1], @"det_type",
                                   daq_dict, @"daq", v_dict, @"high_voltage", nil];
                }
                else if(type == kL200AuxType)
                    ch_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"aux", @"system",
                               [params objectAtIndex:1], @"det_type",
                               daq_dict, @"daq", nil];
                else if(type == kL200ADCType)
                    ch_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"adc", @"system",
                                @"FlashCamADC", @"det_type",
                                daq_dict, @"adc", nil];
            }
            
            if(ch_dict) [dict setObject:ch_dict forKey:[params objectAtIndex:0]];
        }
    }
    return [NSDictionary dictionaryWithDictionary:dict];
}

- (NSData*) jsonMap
{
    NSDictionary* dict = [self dictMap];
    if([NSJSONSerialization isValidJSONObject:dict]){
        NSError* error = nil;
        NSData* data = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
        if(error) NSLogColor([NSColor redColor],
                             @"ORL200SegmentGroup error converting map %d to json:\n%@\n",
                             type, [error localizedDescription]);
        return data;
    }
    else{
        NSLogColor([NSColor redColor], @"ORL200SegmentGroup: error converting map, invalid JSON data\n");
        return nil;
    }
}

- (NSString*) segmentLocation:(int)aSegmentIndex
{
    ORDetectorSegment* segment = [segments objectAtIndex:aSegmentIndex];
    NSArray* params = [[segment paramsAsString] componentsSeparatedByString:@","];
    if(type == kL200DetType){
        return [NSString stringWithFormat:@"%@,%@,%@",
                [params objectAtIndex:4],   // flashcam crate
                [params objectAtIndex:6],   // flashcam board slot
                [params objectAtIndex:7]];  // flashcam board channel
    }
    else if(type > kL200DetType && type < kL200SegmentTypeCount){
        return [NSString stringWithFormat:@"%@,%@,%@",
                [params objectAtIndex:2],   // flashcam crate
                [params objectAtIndex:4],   // flashcam board slot
                [params objectAtIndex:5]];  // flashcam board channel
    }
    else return @"-1,-1,-1";
}

- (NSString*) paramsAsString
{
    NSData* data = [self jsonMap];
    if(!data) return @"";
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

- (void) registerForRates
{
    id document = [(ORAppDelegate*) [NSApp delegate] document];
    NSArray* adcs = [document collectObjectsOfClass:NSClassFromString([self adcClassName])];
    [segments makeObjectsPerformSelector:@selector(registerForRates:) withObject:adcs];
}

- (void) configurationChanged:(NSNotification*)aNote
{
    if(!aNote || [[aNote object] isKindOfClass:NSClassFromString(@"ORGroup")]){
        id document = [(ORAppDelegate*) [NSApp delegate] document];
        NSArray* adcs = [document collectObjectsOfClass:NSClassFromString([self adcClassName])];
        [segments makeObjectsPerformSelector:@selector(configurationChanged:) withObject:adcs];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORRelinkSegments object:self];
        [self registerForRates];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSegmentGroupConfiguationChanged
                                                            object:self];
    }
}

#pragma mark •••Archival

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setType:[[decoder decodeObjectForKey:@"segmentType"] unsignedIntValue]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[NSNumber numberWithUnsignedInt:type] forKey:@"segmentType"];
}

@end
