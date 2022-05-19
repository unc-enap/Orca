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

@implementation ORL200SegmentGroup

#pragma mark •••Map Methods

- (void) readMap:(NSString*)aPath forType:(int)type
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
    // get the list of channel indices and sort
    NSMutableArray* channels = [NSMutableArray array];
    for(id key in dict) [channels addObject:[NSNumber numberWithUnsignedInt:[key unsignedIntValue]]];
    NSSortDescriptor* sd = [[NSSortDescriptor alloc] initWithKey:nil ascending:YES];
    NSArray* chans = [NSArray array];
    chans = [channels sortedArrayUsingDescriptors:@[sd]];
    // get the parameters from the json data
    int index = -1;
    for(id chan in chans){
        index ++;
        NSString* key = [chan stringValue];
        NSDictionary*  ch_dict = [dict    objectForKey:key];
        NSDictionary* daq_dict = [ch_dict objectForKey:@"daq"];
        NSString* ch  = [NSString stringWithFormat:@"%@,%@,%@,",
                         [ch_dict  objectForKey:@"system"],
                         [ch_dict  objectForKey:@"det_name"],
                         [ch_dict  objectForKey:@"det_type"]];
        NSString* daq = [NSString stringWithFormat:@"%@,%@,%@,%@,",
                         [daq_dict objectForKey:@"crate"],
                         [daq_dict objectForKey:@"board_id"],
                         [daq_dict objectForKey:@"board_slot"],
                         [daq_dict objectForKey:@"board_ch"]];
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
            [segment setCrateIndex:5];
            [segment setCardIndex:7];
            [segment setChannelIndex:8];
        }
        else{
            [segment setCrateIndex:3];
            [segment setCardIndex:5];
            [segment setChannelIndex:6];
        }
        [segment decodeLine:line];
        [segment setObject:[NSNumber numberWithInt:index] forKey:@"kSegmentNumber"];
        [segment setObject:key forKey:@"kDetector"];
    }
    [self configurationChanged:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSegmentGroupMapReadNotification object:self];
}

- (void) saveMapFileAs:(NSString*)newFileName forType:(int)type
{
    // build the json data
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    for(NSUInteger i=0; i<[segments count]; i++){
        ORDetectorSegment* segment = [segments objectAtIndex:i];
        NSArray* params = [[segment paramsAsString] componentsSeparatedByString:@","];
        if([params count] == 0) continue;
        if([[params objectAtIndex:0] isEqualToString:@""] ||
           [[params objectAtIndex:0] hasPrefix:@"-"]) continue;
        NSDictionary* ch_dict = nil;
        if(type == kL200DetType){
            NSDictionary* str_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [params objectAtIndex:3], @"number",
                                      [params objectAtIndex:4], @"position", nil];
            NSDictionary* daq_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [params objectAtIndex:5], @"crate",
                                      [params objectAtIndex:6], @"board_id",
                                      [params objectAtIndex:7], @"board_slot",
                                      [params objectAtIndex:8], @"board_ch", nil];
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
                        [params objectAtIndex:1], @"det_name",
                        [params objectAtIndex:2], @"det_type",
                        str_dict, @"string",       daq_dict, @"daq",
                        hv_dict,  @"high_voltage", fe_dict,  @"electronics", nil];
        }
        else if(type >= 0 && type < kL200SegmentTypeCount){
            NSDictionary* daq_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [params objectAtIndex:3], @"crate",
                                      [params objectAtIndex:4], @"board_id",
                                      [params objectAtIndex:5], @"board_slot",
                                      [params objectAtIndex:6], @"board_ch", nil];
            if(type == kL200SiPMType || type == kL200PMTType){
                NSDictionary* v_dict  = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [params objectAtIndex:7], @"crate",
                                         [params objectAtIndex:8], @"board_slot",
                                         [params objectAtIndex:9], @"board_chan", nil];
                if(type == kL200SiPMType)
                    ch_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"spm", @"system",
                               [params objectAtIndex:1], @"det_name",
                               [params objectAtIndex:2], @"det_type",
                               daq_dict, @"daq", v_dict, @"low_voltage", nil];
                else if(type == kL200PMTType)
                    ch_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"pmt", @"system",
                               [params objectAtIndex:1], @"det_name",
                               [params objectAtIndex:2], @"det_type",
                               daq_dict, @"daq", v_dict, @"high_voltage", nil];
            }
            else if(type == kL200AuxType)
                ch_dict = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"aux", @"system",
                           [params objectAtIndex:1], @"det_name",
                           [params objectAtIndex:2], @"det_type",
                           daq_dict, @"daq", nil];
        }
        if(ch_dict) [dict setObject:ch_dict
                             forKey:[NSString stringWithFormat:@"%d", [[params objectAtIndex:0] intValue]]];
    }
    // write the dictionary to the specified filename
    if([NSJSONSerialization isValidJSONObject:dict]){
        NSError* error = nil;
        NSData* data = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
        if(error) NSLogColor([NSColor redColor],
                             @"ORL200SegmentGroup error saving map file:\n%@\n",
                             [error localizedDescription]);
        NSFileManager* fmanager = [NSFileManager defaultManager];
        if([fmanager fileExistsAtPath:newFileName])
            [fmanager removeItemAtPath:newFileName error:nil];
        [fmanager createFileAtPath:newFileName contents:data attributes:nil];
        [self setMapFile:newFileName];
    }
    else NSLogColor([NSColor redColor], @"ORL200SegmentGroup: error saving map file, invalid JSON data\n");
}

- (NSString*) segmentLocation:(int)aSegmentIndex forType:(int)type
{
    ORDetectorSegment* segment = [segments objectAtIndex:aSegmentIndex];
    NSArray* params = [[segment paramsAsString] componentsSeparatedByString:@","];
    if(type == kL200DetType){
        return [NSString stringWithFormat:@"%@,%@,%@",
                [params objectAtIndex:5],   // flashcam crate
                [params objectAtIndex:7],   // flashcam board slot
                [params objectAtIndex:8]];  // flashcam board channel
    }
    else if(type > kL200DetType && type < kL200SegmentTypeCount){
        return [NSString stringWithFormat:@"%@,%@,%@",
                [params objectAtIndex:3],   // flashcam crate
                [params objectAtIndex:5],   // flashcam board slot
                [params objectAtIndex:6]];  // flashcam board channel
    }
    else return @"-1,-1,-1";
}

- (NSString*) paramsAsString
{
    NSMutableString* params = [NSMutableString string];
    bool header = false;
    for(ORDetectorSegment* segment in segments){
        if(!header){
            [params appendString:[segment paramHeader]];
            header = true;
        }
        [params appendString:[NSString stringWithFormat:@"%@\n", [segment paramsAsString]]];
    }
    if([params length] >= 2){
        if([[params substringWithRange:NSMakeRange([params length]-2, 2)] isEqualToString:@"\n"])
            return [params substringWithRange:NSMakeRange([params length]-2, 2)];
        else return params;
    }
    else return params;
}

- (void) registerForRates
{
    id document = [(ORAppDelegate*) [NSApp delegate] document];
    NSArray* adcs = [document collectObjectsOfClass:NSClassFromString(@"ORFlashCamADCModel")];
    [segments makeObjectsPerformSelector:@selector(registerForRates:) withObject:adcs];
}

- (void) configurationChanged:(NSNotification*)aNote
{
    if(!aNote || [[aNote object] isKindOfClass:NSClassFromString(@"ORGroup")]){
        id document = [(ORAppDelegate*) [NSApp delegate] document];
        NSArray* adcs = [document collectObjectsOfClass:NSClassFromString(@"ORFlashCamADCModel")];
        [segments makeObjectsPerformSelector:@selector(configurationChanged:) withObject:adcs];
        [self registerForRates];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSegmentGroupConfiguationChanged
                                                            object:self];
    }
}

@end
