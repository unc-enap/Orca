//  Orca
//  ORL200DetectorView.h
//
//  Created by Tom Caldwell on Tuesday Apr 26, 2022
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

#import "ORDetectorView.h"
#import "ORL200Model.h"

@class ORColorScale;

#define kL200CrateView    0
#define kL200DetectorView 1
#define kL200CC4View      2

#define kL200SiPMRings    4
#define kL200PMTRings     7
#define kNumCC4Positions 12
#define kL200AuxLabels    2
#define kL200NumCC4s     24

@interface ORL200DetectorView : ORDetectorView {
    IBOutlet ORColorScale* detColorScale;
    IBOutlet ORColorScale* sipmColorScale;
    IBOutlet ORColorScale* pmtColorScale;
    IBOutlet ORColorScale* auxChanColorScale;
    int viewType;
    NSMutableArray* detOutlines;
    NSString* strLabel[kL200DetectorStrings];
    NSString* sipmLabel[kL200SiPMRings];
    NSString* pmtLabel[kL200PMTRings];
    NSString* auxLabel[kL200AuxLabels];
    NSString* cc4Label[kL200NumCC4s];
    float strLabelX[kL200DetectorStrings];
    float sipmLabelY[kL200SiPMRings];
    float pmtLabelY[kL200PMTRings];
    float auxLabelY;
    NSDictionary* strLabelAttr;
    NSDictionary* sipmLabelAttr;
    NSDictionary* pmtLabelAttr;
    NSDictionary* auxLabelAttr;
    NSDictionary* cc4LabelAttr;
    NSDictionary* cc4LabelAttr1;
}
- (void) setViewType:(int)type;
@end
