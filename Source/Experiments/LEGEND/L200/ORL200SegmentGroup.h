//  Orca
//  ORL200SegmentGroup.h
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

#import "ORSegmentGroup.h"

enum ORL200SegmentType{ kL200DetType, kL200SiPMType, kL200PMTType, kL200AuxType,
    kL200CC4Type, kL200ADCType, kL200SegmentTypeCount};

@interface ORL200SegmentGroup : ORSegmentGroup {
    unsigned int type;
}

#pragma mark •••Accessors
- (unsigned int) type;
- (void) setType:(unsigned int)segType;
- (float) waveformRate;
- (float) getWaveformRate:(int)index;
- (float) getWaveformCounts:(int)index;
- (double) getBaseline:(int)index;

#pragma mark •••Map Methods
- (void) readMap:(NSString*)aPath;
- (void) saveMapFileAs:(NSString*)newFileName;
- (NSDictionary*) dictMap;
- (NSData*) jsonMap;
- (NSString*) segmentLocation:(int)aSegmentIndex;

@end

extern NSString* ORRelinkSegments;
