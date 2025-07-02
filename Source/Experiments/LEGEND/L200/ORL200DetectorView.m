//  Orca
//  ORL200DetectorView.m
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

#import "ORL200DetectorView.h"
#import "ORL200SegmentGroup.h"
#import "ORFlashCamADCModel.h"
#import "ORDetectorSegment.h"
#import "ORColorScale.h"
#import "ORAxis.h"
#import "ORLNGSSlowControlsModel.h"
#import "ORAppDelegate.h"
#import "NSNotifications+Extensions.h"

#define kL200CrateWidth         (31 * [self bounds].size.width  / (2*32+1))
#define kL200CrateXSpacing           ([self bounds].size.width  / (2*32+1))
#define kL200CrateHeight        (31 * [self bounds].size.height / (2*32+1))
#define kL200CrateYSpacing           ([self bounds].size.height / (2*32+1))
#define kL200CrateInsideX       (0.069 * kL200CrateWidth)
#define kL200CrateInsideY       (0.081 * kL200CrateHeight)
#define kL200CrateInsideWidth   (kL200CrateWidth  - 2*kL200CrateInsideX)
#define kL200CrateInsideHeight  (kL200CrateHeight - 2*kL200CrateInsideY)
#define kL200DetViewWidth       (0.80 * [self bounds].size.width)
#define kL200AuxViewWidth       ([self bounds].size.width - kL200DetViewWidth)
#define kL200DetViewHeight      (0.7 * [self bounds].size.height)
#define kL200SiPMViewHeight     (0.4 * ([self bounds].size.height - kL200DetViewHeight) / 2)
#define kL200PMTViewHeight      (0.6 * ([self bounds].size.height - kL200DetViewHeight) / 2)
#define kL200CC4XOffset         0
#define kL200CC4Size            11
#define kL200CC4StartAngle      105
#define kL200CC4Offset          60
#define kL200CC4InnerR          (kL200CC4Offset*2-5)
#define kL200CC4OuterR          (kL200CC4Offset*2 + 2*kL200CC4Size*7+10)
#define kL200CC4DeltaAngle      (360/kNumCC4Positions)
static NSInteger NumberofTimesCall = 0;

@interface ORL200DetectorView (private)
- (void) makeAllSegments;
- (void) makeDets;
- (void) makeSIPMs;
- (void) makePMTs;
- (void) makeCC4s;
- (void) makeAuxChans;
- (void) makeDummySet;
- (void) drawLabels;
- (void) drawGeDetectorLabels;
- (void) drawSiPMLabels;
- (void) drawPMTLabels;
- (void) drawSourceLabel;
- (void) drawCC4Background;
- (void) drawAuxChanLabels;
- (void) makeSource;
- (void) makeSourcesTube;
@end

@implementation ORL200DetectorView

- (id) initWithFrame:(NSRect)frameRect
{
    detOutlines = nil;
    detOutlines1 = nil;
    for(int i=0; i<kL200DetectorStrings; i++) strLabel[i] = nil;
    for(int i=0; i<kL200SiPMRings; i++)      sipmLabel[i] = nil;
    for(int i=0; i<kL200PMTRings; i++)        pmtLabel[i] = nil;
    for(int i=0; i<kL200AuxLabels; i++)       auxLabel[i] = nil;
    for(int i=0; i<kL200NumCC4s; i++)       cc4Label[i] = nil;
    for(int i=0; i<kL200MaxSISChans; i++)       sisLabel[i] = nil;
    strLabelAttr  = nil;
    sourceLabelAttr = nil;
    sipmLabelAttr = nil;
    pmtLabelAttr  = nil;
    auxLabelAttr  = nil;
    self = [super initWithFrame:frameRect];
    return self;
}

- (void) dealloc
{
    [detOutlines release];
    [detOutlines1 release];
    [slowControls release];
    for(int i=0; i<kL200DetectorStrings; i++) [strLabel[i]  release];
    for(int i=0; i<kL200SiPMRings; i++)       [sipmLabel[i] release];
    for(int i=0; i<kL200PMTRings; i++)        [pmtLabel[i]  release];
    for(int i=0; i<kL200AuxLabels; i++)       [auxLabel[i]  release];
    for(int i=0; i<kL200NumCC4s; i++)         [cc4Label[i]  release];
    for(int i=0; i<kL200MaxSISChans; i++)     [sisLabel[i] release];
    [strLabelAttr  release];
    [sourceLabelAttr release];
    [sipmLabelAttr release];
    [pmtLabelAttr  release];
    [auxLabelAttr  release];
    [cc4LabelAttr  release];
    [super dealloc];
}
- (void) awakeFromNib
{
    [super awakeFromNib];
    [[detColorScale     colorAxis] setLabel:@"Detectors"];
    [[sipmColorScale    colorAxis] setLabel:@"SiPMs"];
    [[pmtColorScale     colorAxis] setLabel:@"PMTs"];
    [[auxChanColorScale colorAxis] setLabel:@"Aux Chans"];
    [detColorScale     setExcludeZero:YES];
    [sipmColorScale    setExcludeZero:YES];
    [pmtColorScale     setExcludeZero:YES];
    [auxChanColorScale setExcludeZero:YES];
}

- (void) setViewType:(int)type
{
    viewType = type;
}

- (void) makeCrateImage
{
    if(!crateImage){
        crateImage = [[NSImage imageNamed:@"flashcam_crate"] copy];
        [crateImage setSize:NSMakeSize(kL200CrateWidth, kL200CrateHeight)];
    }
}

- (void) drawRect:(NSRect)rect
{
    if([self selectedSet] >= 0){
        if(selectedSet >= [segmentPathSet count]) [self clrSelection];
        else if(selectedPath >= [[segmentPathSet objectAtIndex:selectedSet] count]) [self clrSelection];
    }
    [[NSColor colorWithCalibratedRed:0.88 green:0.88 blue:0.88 alpha:1] set];
    [NSBezierPath fillRect:rect];
    
    if(viewType == kL200CrateView){
        [self makeCrateImage];
        NSFont* font = [NSFont systemFontOfSize:9.0];
        NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil];
        for(int icrate=0; icrate<4; icrate++){
            //draw the crate
            float xoff = kL200CrateXSpacing + (icrate%2)*([crateImage imageRect].size.width+kL200CrateXSpacing);
            float yoff = kL200CrateYSpacing + (icrate/2)*([crateImage imageRect].size.height+kL200CrateYSpacing);
            NSRect destRect = NSMakeRect(xoff, yoff,
                                         [crateImage imageRect].size.width,
                                         [crateImage imageRect].size.height);
            [crateImage drawInRect:destRect
                          fromRect:[crateImage imageRect]
                         operation:NSCompositingOperationSourceOver
                          fraction:1.0];
            // draw the inside of the crate
            [[NSColor blackColor] set];
            NSRect inside = NSMakeRect(xoff+kL200CrateInsideX, yoff+kL200CrateInsideY,
                                       kL200CrateInsideWidth, kL200CrateInsideHeight);
            [NSBezierPath fillRect:inside];
            // draw the slot separators
            [[NSColor grayColor] set];
            float dx = inside.size.width / 14;
            [NSBezierPath setDefaultLineWidth:0.5];
            for(int i=0; i<=14; i++){
                [NSBezierPath strokeLineFromPoint:NSMakePoint(inside.origin.x+i*dx, inside.origin.y)
                                          toPoint:NSMakePoint(inside.origin.x+i*dx,
                                                              inside.origin.y+inside.size.height)];
            }
            // draw the slot labels
            for(int i=0; i<14; i++){
                NSAttributedString* s = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", i] attributes:attrs];
                [s drawAtPoint:NSMakePoint(xoff+kL200CrateInsideX+dx*(i+0.5)-[s size].width/2,
                                           yoff+kL200CrateInsideY-[s size].height+1)];
                [s release];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(inside.origin.x+i*dx, inside.origin.y)
                                          toPoint:NSMakePoint(inside.origin.x+i*dx,
                                                              inside.origin.y+inside.size.height)];
            }
            // draw the crate label
            NSString* crateLabel = @"";
            if(icrate == 0)      crateLabel = @"Ge Crate 0";
            else if(icrate == 1) crateLabel = @"Ge Crate 1";
            else if(icrate == 2) crateLabel = @"SiPM Crate";
            else if(icrate == 3) crateLabel = @"Veto Crate";
            NSAttributedString* s = [[NSAttributedString alloc] initWithString:crateLabel attributes:attrs];
            [s drawAtPoint:NSMakePoint(xoff+kL200CrateInsideX+kL200CrateInsideWidth/2 - [s size].width/2,
                                       yoff+kL200CrateInsideY+kL200CrateInsideHeight+1)];
            [s release];
        }
    }
    else if(viewType == kL200DetectorView){
        [[NSColor darkGrayColor] set];
        for(id det in detOutlines) [det fill];
        [self drawLabels];
        [[NSColor blueColor] set];
        for(id det_s in detOutlines1) [det_s fill];
    }
    
    else if(viewType == kL200CC4View){
        [self drawLabels];
        [[NSColor blueColor] set];
        for(id det_s in detOutlines1) [det_s fill];
    }
    [super drawRect:rect];
}

- (NSColor*) getColorForSet:(int)setIndex value:(float)aValue
{
    if (NumberofTimesCall==1000){ //only calling to make source once in 1000 times
        [self makeSource];
        NumberofTimesCall=0;
    }
    NumberofTimesCall++;
    if(setIndex == kL200DetType)       return [detColorScale     getColorForValue:aValue];
    else if(setIndex == kL200SiPMType) return [sipmColorScale    getColorForValue:aValue];
    else if(setIndex == kL200PMTType)  return [pmtColorScale     getColorForValue:aValue];
    else if(setIndex == kL200AuxType)  return [auxChanColorScale getColorForValue:aValue];
    else if(setIndex == kL200CC4Type)  return [detColorScale     getColorForValue:aValue];
    else return [NSColor darkGrayColor];
}

- (void) downArrow
{
    int n = (int) [detOutlines count];
    if(n == 0) return;
    selectedPath++;
    if(selectedSet == 0) selectedPath %= n;
}

- (void) upArrow
{
    int n = (int) [detOutlines count];
    if(n == 0) return;
    selectedPath --;
    if(selectedSet == 0 && selectedPath < 0) selectedPath = n-1;
}

- (void) mouseDown:(NSEvent*)anEvent
{
    NSPoint localPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    selectedSet  = -1;
    selectedPath = -1;
    for(int setIndex = 0;setIndex<[segmentPathSet count];setIndex++){
        int segmentIndex;
        NSArray* arrayOfPaths = [segmentPathSet objectAtIndex:setIndex];
        for(segmentIndex = 0;segmentIndex<[arrayOfPaths count];segmentIndex++){
            NSBezierPath* aPath = [arrayOfPaths objectAtIndex:segmentIndex];
            if([aPath containsPoint:localPoint]){
                selectedSet  = setIndex;
                selectedPath = segmentIndex;
                break;
            }
        }
        if(selectedSet >=0 ) break;
    }
    [delegate selectedSet:selectedSet segment:selectedPath];
    if(selectedSet >= 0 && selectedPath >= 0 && [anEvent clickCount] >= 2){
        if([anEvent modifierFlags] & NSEventModifierFlagControl)
            [delegate showDataSet:@"Waveforms" forSet:selectedSet segment:selectedPath];
        else if([anEvent modifierFlags] & NSEventModifierFlagOption)
            [delegate showDataSet:@"Baseline" forSet:selectedSet segment:selectedPath];
        else if([anEvent modifierFlags] & NSEventModifierFlagCommand)
            [delegate showDataSet:@"Energy" forSet:selectedSet segment:selectedPath];
        else
            [delegate showDialogForSet:selectedSet segment:selectedPath];
    }
    [self setNeedsDisplay:YES];
}

@end

@implementation ORL200DetectorView (private)

- (void) makeAllSegments
{
    [super makeAllSegments];
    
    if(detOutlines) [detOutlines removeAllObjects];
    else detOutlines = [[NSMutableArray array] retain];
    if(detOutlines1) [detOutlines1 removeAllObjects];
    else detOutlines1 = [[NSMutableArray array] retain];
    if(viewType == kL200CrateView){
        [self makeCrateImage];
        float dx = kL200CrateInsideWidth / 14;
        for(int iset=0; iset<[delegate numberOfSegmentGroups]; iset++){
            int nchan = kFlashCamADCChannels;
            if(iset == kL200PMTType) nchan = kFlashCamADCStdChannels;
            float dy = kL200CrateInsideHeight / nchan;
            NSMutableArray* segmentPaths = [NSMutableArray array];
            NSMutableArray* errorPaths   = [NSMutableArray array];
            ORSegmentGroup* group = [delegate segmentGroup:iset];
            for(int i=0; i<[group numSegments]; i++){
                ORDetectorSegment* segment = [group segment:i];
                int crate = [[segment objectForKey:[segment mapEntry:[segment crateIndex] forKey:@"key"]] intValue];
                int cardSlot = [segment cardSlot];
                int channel  = [segment channel];
                BOOL drawOnScreen = YES;
                if(channel < 0 || crate < 0) drawOnScreen = NO;
                float xoffset = -5000, yoffset = -5000;
                if(drawOnScreen){
                    xoffset = (crate%2)*([crateImage imageRect].size.width+kL200CrateXSpacing) +
                                kL200CrateXSpacing + kL200CrateInsideX + 2;
                    yoffset = (crate/2)*([crateImage imageRect].size.height+kL200CrateYSpacing) +
                                kL200CrateYSpacing + kL200CrateInsideY + 2;
                }
                NSRect chanRect = NSMakeRect(xoffset+cardSlot*dx, yoffset+(nchan-1-channel)*dy, dx-4, dy-4);
                [segmentPaths addObject:[NSBezierPath bezierPathWithRect:chanRect]];
                [errorPaths addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(chanRect, 4, 4)]];
            }
            [segmentPathSet addObject:segmentPaths];
            [errorPathSet addObject:errorPaths];
        }
    }
    else if(viewType == kL200DetectorView){
        [self makeDets];
        [self makeSIPMs];
        [self makePMTs];
        [self makeAuxChans];
        [self makeDummySet]; //place holder for CC4s
        [self makeSourcesTube];
        [self makeSource];
    }
    else if(viewType == kL200CC4View){
        [self makeDummySet];//place holder for Dets
        [self makeCC4sSiPMS];
        [self makePMTs];
        [self makeDummySet];//place holder for AuxChans
        [self makeCC4s];
        [self makeSourcesTube];
        [self makeSource];
    }
    [self setNeedsDisplay:YES];
}

- (void) drawLabels
{
    switch (viewType){
        case kL200DetectorView:
            [self drawGeDetectorLabels];
            [self drawSiPMLabels];
            [self drawPMTLabels];
            [self drawSourceLabel];
            [self drawAuxChanLabels];
            break;
        case kL200CC4View:
            [self drawCC4Background];
            //[self drawSiPMLabels];
            [self drawPMTLabels];
            //[self drawSourceLabel];
            //[self drawAuxChanLabels];
            break;
        default:
            break;
    }
}

- (void) drawGeDetectorLabels
{
    // draw the Ge detector labels above each string
    if(!strLabelAttr){
        NSFont* font = [NSFont fontWithName:@"Geneva" size:8];
        strLabelAttr = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                         [NSColor systemBlueColor], NSForegroundColorAttributeName, nil] retain];
    }
    for(int i=0; i<kL200DetectorStrings; i++){
        if(!strLabel[i]){
            strLabel[i] = [@"" copy];
            continue;
        }
        NSAttributedString* s = [[NSAttributedString alloc] initWithString:strLabel[i] attributes:strLabelAttr];
        [s drawAtPoint:NSMakePoint(strLabelX[i]-[s size].width/2, -[s size].height+
                                   kL200PMTViewHeight+kL200SiPMViewHeight+kL200DetViewHeight)];
        [s release];
    }
}

- (void) drawSiPMLabels
{
    // draw the SiPM labels, top and bottom for inner and outer barrels in the right margin
    if(!sipmLabelAttr){
        NSFont* font = [NSFont fontWithName:@"Geneva" size:8];
        sipmLabelAttr = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                          [NSColor systemGreenColor], NSForegroundColorAttributeName, nil] retain];
    }
    for(int i=0; i<kL200SiPMRings; i++){
        if(!sipmLabel[i]){
            sipmLabel[i] = [@"" copy];
            continue;
        }
        NSAttributedString* s = [[NSAttributedString alloc] initWithString:sipmLabel[i] attributes:sipmLabelAttr];
        [s drawAtPoint:NSMakePoint(kL200DetViewWidth, sipmLabelY[i]-[s size].height/2)];
        [s release];
    }
}

- (void) drawPMTLabels
{
    // draw the PMT labels, one for each ring in the right margin
    if(!pmtLabelAttr){
        NSFont* font = [NSFont fontWithName:@"Geneva" size:8];
        pmtLabelAttr = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                         [NSColor systemRedColor], NSForegroundColorAttributeName, nil] retain];
    }
    for(int i=0; i<kL200PMTRings; i++){
        if(!pmtLabel[i]){
            pmtLabel[i] = [@"" copy];
            continue;
        }
        NSAttributedString* s = [[NSAttributedString alloc] initWithString:pmtLabel[i] attributes:pmtLabelAttr];
        [s drawAtPoint:NSMakePoint(kL200DetViewWidth, pmtLabelY[i]-[s size].height/2)];
        [s release];
    }
}
- (void) drawAuxChanLabels
{
    // draw the aux channel label, stacked labels centered in the right margin above the aux channels
    if(!auxLabelAttr){
        NSFont* font = [NSFont fontWithName:@"Geneva" size:8];
        auxLabelAttr = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                         [NSColor systemOrangeColor], NSForegroundColorAttributeName, nil] retain];
    }
    float auxOffset = 0.0;
    for(int i=kL200AuxLabels-1; i>=0; i--){
        if(!auxLabel[i]) auxLabel[0] = [@"" copy];
        if([auxLabel[i] length] == 0) continue;
        NSAttributedString* s = [[NSAttributedString alloc] initWithString:auxLabel[i] attributes:auxLabelAttr];
        [s drawAtPoint:NSMakePoint(kL200DetViewWidth*0.92+kL200AuxViewWidth/2-[s size].width/2, auxLabelY+auxOffset)];
        auxOffset += [s size].height;
        [s release];
    }
}

- (void) drawCC4Background
{
    //----------draw the outlines-----------------
    float xc         = [self bounds].size.width/2+kL200CC4XOffset;
    float yc         = [self bounds].size.height/2;
    [[NSColor blackColor] set];
    NSBezierPath* circPaths = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-kL200CC4InnerR/2,-kL200CC4InnerR/2,kL200CC4InnerR,kL200CC4InnerR)];
    [circPaths appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-kL200CC4OuterR/2,-kL200CC4OuterR/2,kL200CC4OuterR,kL200CC4OuterR)]];
    
    [circPaths appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-(kL200CC4OuterR+kL200CC4InnerR/2)/2, -(kL200CC4OuterR+kL200CC4InnerR/2)/2, kL200CC4OuterR+kL200CC4InnerR/2, kL200CC4OuterR+kL200CC4InnerR/2)]];
    
    [circPaths appendBezierPath:[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-((kL200CC4InnerR-kL200CC4InnerR/3)/2), -((kL200CC4InnerR-kL200CC4InnerR/3)/2),kL200CC4InnerR-kL200CC4InnerR/3, kL200CC4InnerR-kL200CC4InnerR/3)]];
    
    NSAffineTransform* transform = [NSAffineTransform transform];
    [transform translateXBy:xc yBy:yc];
    [circPaths transformUsingAffineTransform: transform];
    [circPaths stroke];

    float angle = kL200CC4StartAngle+kL200CC4DeltaAngle/2.;
    for(int i=0;i<kNumCC4Positions;i++){
        NSBezierPath* aLineSeg = [NSBezierPath bezierPath];
        [aLineSeg moveToPoint:NSMakePoint((kL200CC4InnerR-kL200CC4InnerR/3)/2,0)];
        [aLineSeg lineToPoint:NSMakePoint((kL200CC4OuterR+kL200CC4InnerR/2)/2,0)];
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy:xc yBy:yc];
        [transform rotateByDegrees:angle];
        [aLineSeg transformUsingAffineTransform: transform];
        [aLineSeg stroke];
        angle += kL200CC4DeltaAngle;
    }
    
    //----------draw the CC4 position labels-----------------
    if(!cc4LabelAttr){
        NSMutableParagraphStyle* style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease ];
        style.alignment = NSTextAlignmentCenter;
        NSFont* font = [NSFont fontWithName:@"Geneva" size:10];
        cc4LabelAttr = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                          [NSColor blueColor], NSForegroundColorAttributeName,style,NSParagraphStyleAttributeName,nil] retain];
    }
    if(!cc4LabelAttr1){
        NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        style.alignment = NSTextAlignmentCenter;
        NSFont* font = [NSFont fontWithName:@"Geneva" size:10];
        cc4LabelAttr1 = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                          [NSColor redColor], NSForegroundColorAttributeName,style,NSParagraphStyleAttributeName,nil] retain];
    }

    angle = kL200CC4StartAngle+15;
    float tRadius = kL200CC4OuterR+75;
    float nRadius = kL200CC4OuterR-20+75;
    float aRadius = kL200CC4OuterR-20;
    for(int i=0; i<kNumCC4Positions; i++){
        //----outer ring numbers
        NSAttributedString* s = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",i+1] attributes:cc4LabelAttr];
        float rad = angle * M_PI/180.;
        NSRect tRect = NSMakeRect(xc + tRadius/2*cosf(rad)-[s size].width/2,
                                  yc + tRadius/2*sinf(rad)-[s size].height/2,
                                  [s size].width,
                                  [s size].height);
        [s drawInRect:tRect];
        [s release];
        
        if(i==9){
            float radN2 = (angle-25) * M_PI/180.;
            s = [[NSAttributedString alloc] initWithString:@"North" attributes:cc4LabelAttr];
            tRect = NSMakeRect( xc + nRadius/2*cosf(radN2)-50,
                               yc + nRadius/2*sinf(radN2)+13,
                               [s size].width,
                               [s size].height);
            [s drawInRect:tRect];
            [s release];
            s = [[NSAttributedString alloc] initWithString:@"(LVD)" attributes:cc4LabelAttr];
            tRect = NSMakeRect( xc + nRadius/2*cosf(radN2)-50,
                               yc + nRadius/2*sinf(radN2)+3,
                               [s size].width,
                               [s size].height);
            [s drawInRect:tRect];
            [s release];
        }
        //----------Inner labels-----------
        float radN1 = (angle-5) * M_PI/180.;
        NSString* label = cc4Label[i*2];
        if(label){
            s = [[NSAttributedString alloc] initWithString:label attributes:cc4LabelAttr1];
            tRect = NSMakeRect( xc + aRadius/2*cosf(radN1)-[s size].width/2,
                               yc + aRadius/2*sinf(radN1)-[s size].height/2,
                               [s size].width,
                               [s size].height);
            [s drawInRect:tRect];
            [s release];
        }
        label = cc4Label[i*2+1];
        if(label){
            float radN2 = (angle-25) * M_PI/180.;
            s = [[NSAttributedString alloc] initWithString:label attributes:cc4LabelAttr1];
            tRect = NSMakeRect( xc + aRadius/2*cosf(radN2)-[s size].width/2,
                               yc + aRadius/2*sinf(radN2)-[s size].height/2,
                               [s size].width,
                               [s size].height);
            [s drawInRect:tRect];
            [s release];
        }
        angle -= kL200CC4DeltaAngle;
    }
}

- (void) makeDets
{
    [delegate setDetectorStringPositions];
    NSMutableArray* segmentPaths = [NSMutableArray array];
    NSMutableArray* errorPaths   = [NSMutableArray array];
    ORSegmentGroup* group = [delegate segmentGroup:kL200DetType];
    for(int i=0; i<kL200DetectorStrings; i++){
        [strLabel[i] autorelease];
        strLabel[i] = [@"" copy];
    }
    if(!strLabelAttr){
        NSFont* font = [NSFont fontWithName:@"Geneva" size:8];
        strLabelAttr = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                         [NSColor blueColor], NSForegroundColorAttributeName, nil] retain];
    }
    NSAttributedString* s = [[NSAttributedString alloc] initWithString:@"Ge" attributes:strLabelAttr];
    const float lbly  = [s size].height * 1.1;
    [s release];
    const float yoff  = kL200PMTViewHeight + kL200SiPMViewHeight;
    const float detx  = 3*kL200DetViewWidth / (kL200DetectorStrings*4+1);
    const float detdx =   kL200DetViewWidth / (kL200DetectorStrings*4+1);
    const float dety  = 6*(kL200DetViewHeight-lbly) / (kL200MaxDetsPerString*7+1);
    const float detdy =   (kL200DetViewHeight-lbly) / (kL200MaxDetsPerString*7+1);
    const float inset = MIN(0.05*detx, 0.05*dety);
    const float bevel = 0.08 * detx;
    const float wellx = 0.08 * detx;
    const float welly = 0.35;
    const float begey = 0.8  * dety;
    const float ppcy  = 0.9  * dety;
    const float coaxy = dety;
    for(int i=0; i<[group numSegments]; i++){
        ORDetectorSegment* segment = [group segment:i];
        const int str = [[segment objectForKey:@"str_number"] intValue];
        const int pos = [[segment objectForKey:@"str_position"] intValue];
        NSBezierPath* p = nil;
        if(str > 0 && str <= kL200DetectorStrings && pos > 0 && pos <= kL200MaxDetsPerString){
            if([delegate validateDetector:i]){
                NSString* strName = [segment objectForKey:@"kStringName"];
                NSString* type = [[segment objectForKey:@"det_type"] lowercaseString];
                const float x = detdx + (detx + detdx) * (str - 1);
                const float y = yoff + (kL200DetViewHeight-lbly) - (dety + detdy) * (pos - 1) - dety;
                if([type isEqualToString:@"bege"]){
                    NSRect r = NSMakeRect(x, y, detx, begey);
                    p = [NSBezierPath bezierPathWithRect:r];
                    [segmentPaths addObject:p];
                    [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -inset, -inset)]];
                }
                else if([type isEqualToString:@"ppc"]){
                    p = [NSBezierPath bezierPath];
                    [p moveToPoint:NSMakePoint(x+bevel, y)];
                    [p lineToPoint:NSMakePoint(x+detx-bevel, y)];
                    [p lineToPoint:NSMakePoint(x+detx, y+bevel)];
                    [p lineToPoint:NSMakePoint(x+detx, y+ppcy)];
                    [p lineToPoint:NSMakePoint(x, y+ppcy)];
                    [p lineToPoint:NSMakePoint(x, y+bevel)];
                    [p closePath];
                    [p moveToPoint:NSMakePoint(x+bevel, y)];
                    [segmentPaths addObject:p];
                    p = [NSBezierPath bezierPath];
                    [p moveToPoint:NSMakePoint(x+bevel-inset, y-inset)];
                    [p lineToPoint:NSMakePoint(x+detx-bevel+inset, y-inset)];
                    [p lineToPoint:NSMakePoint(x+detx+inset, y+bevel)];
                    [p lineToPoint:NSMakePoint(x+detx+inset, y+ppcy+inset)];
                    [p lineToPoint:NSMakePoint(x-inset, y+ppcy+inset)];
                    [p lineToPoint:NSMakePoint(x-inset, y+bevel)];
                    [p closePath];
                    [p moveToPoint:NSMakePoint(x+bevel-inset, y-inset)];
                    [errorPaths addObject:p];
                }
                else if([type isEqualToString:@"coax"]){
                    p = [NSBezierPath bezierPath];
                    [p moveToPoint:NSMakePoint(x, y)];
                    [p lineToPoint:NSMakePoint(x+detx/2-wellx, y)];
                    [p lineToPoint:NSMakePoint(x+detx/2-wellx, y+(1-welly)*begey)];
                    [p lineToPoint:NSMakePoint(x+detx/2+wellx, y+(1-welly)*begey)];
                    [p lineToPoint:NSMakePoint(x+detx/2+wellx, y)];
                    [p lineToPoint:NSMakePoint(x+detx, y)];
                    [p lineToPoint:NSMakePoint(x+detx, y+coaxy)];
                    [p lineToPoint:NSMakePoint(x, y+coaxy)];
                    [p closePath];
                    [p moveToPoint:NSMakePoint(x, y)];
                    [segmentPaths addObject:p];
                    p = [NSBezierPath bezierPath];
                    [p moveToPoint:NSMakePoint(x-inset, y-inset)];
                    [p lineToPoint:NSMakePoint(x+detx/2-wellx+inset, y-inset)];
                    [p lineToPoint:NSMakePoint(x+detx/2-wellx+inset, y+(1-welly)*begey-inset)];
                    [p lineToPoint:NSMakePoint(x+detx/2+wellx-inset, y+(1-welly)*begey-inset)];
                    [p lineToPoint:NSMakePoint(x+detx/2+wellx-inset, y-inset)];
                    [p lineToPoint:NSMakePoint(x+detx+inset, y-inset)];
                    [p lineToPoint:NSMakePoint(x+detx+inset, y+coaxy+inset)];
                    [p lineToPoint:NSMakePoint(x-inset, y+coaxy+inset)];
                    [p closePath];
                    [p moveToPoint:NSMakePoint(x-inset, y-inset)];
                    [errorPaths addObject:p];
                }
                else if([type isEqualToString:@"icpc"]){
                    p = [NSBezierPath bezierPath];
                    [p moveToPoint:NSMakePoint(x, y)];
                    [p lineToPoint:NSMakePoint(x+detx, y)];
                    [p lineToPoint:NSMakePoint(x+detx, y+dety)];
                    [p lineToPoint:NSMakePoint(x+detx/2+wellx, y+dety)];
                    [p lineToPoint:NSMakePoint(x+detx/2+wellx, y+welly*dety)];
                    [p lineToPoint:NSMakePoint(x+detx/2-wellx, y+welly*dety)];
                    [p lineToPoint:NSMakePoint(x+detx/2-wellx, y+dety)];
                    [p lineToPoint:NSMakePoint(x, y+dety)];
                    [p closePath];
                    [p moveToPoint:NSMakePoint(x, y)];
                    [segmentPaths addObject:p];
                    p = [NSBezierPath bezierPath];
                    [p moveToPoint:NSMakePoint(x-inset, y-inset)];
                    [p lineToPoint:NSMakePoint(x+detx+inset, y-inset)];
                    [p lineToPoint:NSMakePoint(x+detx+inset, y+dety+inset)];
                    [p lineToPoint:NSMakePoint(x+detx/2+wellx-inset, y+dety+inset)];
                    [p lineToPoint:NSMakePoint(x+detx/2+wellx-inset, y+welly*dety+inset)];
                    [p lineToPoint:NSMakePoint(x+detx/2-wellx+inset, y+welly*dety+inset)];
                    [p lineToPoint:NSMakePoint(x+detx/2-wellx+inset, y+dety+inset)];
                    [p lineToPoint:NSMakePoint(x-inset, y+dety+inset)];
                    [p closePath];
                    [p moveToPoint:NSMakePoint(x-inset, y-inset)];
                    [errorPaths addObject:p];
                }
                if([strLabel[str-1] isEqualToString:@""]){
                    strLabelX[str-1] = detdx*str + detx*(str-0.5);
                    [strLabel[str-1] autorelease];
                    if([strName length] == 0 || [strName hasPrefix:@"-"])
                        strLabel[str-1] = [[NSString stringWithFormat:@"Ge%d", str] retain];
                    else
                        strLabel[str-1] = [[NSString stringWithString:strName] retain];
                }
            }
        }
        if(!p){
            NSRect r = NSMakeRect(-5000, -5000-dety, detx, dety);
            [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
            [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -inset, -inset)]];
        }
    }
    [segmentPathSet addObject:segmentPaths];
    [errorPathSet addObject:errorPaths];
    [detOutlines addObjectsFromArray:errorPaths];
    [self setNeedsDisplay:YES];
}

- (void) makeSIPMs
{
    if(!strLabelAttr){
        NSFont* font = [NSFont fontWithName:@"Geneva" size:8];
        strLabelAttr = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                         [NSColor blueColor], NSForegroundColorAttributeName, nil] retain];
    }
    [delegate setSiPMPositions];
    NSMutableArray* segmentPaths = [NSMutableArray array];
    NSMutableArray* errorPaths   = [NSMutableArray array];
    ORSegmentGroup* group = [delegate segmentGroup:kL200SiPMType];
    for(int i=0; i<kL200SiPMRings; i++){
        [sipmLabel[i] autorelease];
        sipmLabel[i] = [@"" copy];
    }
    const float byoff = kL200PMTViewHeight;
    const float tyoff = kL200PMTViewHeight + kL200SiPMViewHeight + kL200DetViewHeight;
    const float ix    = 3*kL200DetViewWidth / (kL200SiPMInnerChans/2*4+1);
    const float idx   =   kL200DetViewWidth / (kL200SiPMInnerChans/2*4+1);
    const float ox    = 3*kL200DetViewWidth / (kL200SiPMOuterChans/2*4+1);
    const float odx   =   kL200DetViewWidth / (kL200SiPMOuterChans/2*4+1);
    const float sy    = 4*kL200SiPMViewHeight / (2*5+1);
    const float sdy   =   kL200SiPMViewHeight / (2*5+1);
    const float inset = MIN(MIN(0.05*ix, 0.05*ox), 0.05*sy);
    for(int i=0; i<[group numSegments]; i++){
        ORDetectorSegment* segment = [group segment:i];
        // Extract the SiPM (Silicon Photomultiplier) ID and relevant positional data
        const int sipm = [[segment objectForKey:@"kStringName"] intValue];
        const int sip_barrel_pos = [[segment objectForKey:@"lv_board_B_pos"] intValue];
        const int sip_loc = [[segment objectForKey:@"lv_board_string"] intValue];
        //if no sipms
        if (sipm<=0) continue;
        // Validate the SiPM with the delegate method
        if ([delegate validateSiPM:i]) {
            // Initialize variables for position and size
            // Default position is top outer barrel
            float x = odx;
            float dx = 0;
            float y = tyoff + 2 * sdy + sy;
            // Calculate position and size based on barrel position
            switch (sip_barrel_pos) {
                case 1: // Top outer barrel
                    x = odx + (ox + ox) * (sip_loc - 1) / 1.5;
                    y = tyoff + 2 * sdy + sy;
                    dx = ox;
                    break;
                case 2: // Top inner barrel
                    x = idx + (ix + idx) * (sip_loc - 1);
                    y = tyoff + sdy;
                    dx = ix;
                    break;
                case 3: // Bottom inner barrel
                    x = idx + (ix + idx) * (sip_loc - 1);
                    y = byoff + 2 * sdy + sy;
                    dx = ix;
                    break;
                case 4: // Bottom outer barrel
                    x = odx + (ox + ox) * (sip_loc - 1) / 1.6;
                    y = byoff + sdy;
                    dx = ox;
                    break;
                default:
                    // Handle unexpected barrel positions gracefully
                    NSLog(@"Unexpected sip_barrel_pos: %d", sip_barrel_pos);
                    continue;
            }
            // Create a rectangle representing the detector element
            NSRect rect = NSMakeRect(x, y, dx, sy);
            // Add the rectangle to the segmentPaths and errorPaths collections
            [segmentPaths addObject:[NSBezierPath bezierPathWithRect:rect]];
            [errorPaths addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(rect, -inset, -inset)]];
            // Handle ring-specific labeling
            int iring = [[segment objectForKey:@"kRing"] intValue];
            if ([sipmLabel[iring] isEqualToString:@""]) {
                // Update the label position and content
                sipmLabelY[iring] = y + sy / 2;
                [sipmLabel[iring] release];
                sipmLabel[iring] = [[segment objectForKey:@"kRingLabel"] copy];
            }
        }
    }
    [segmentPathSet addObject:segmentPaths];
    [errorPathSet   addObject:errorPaths];
    [detOutlines    addObjectsFromArray:errorPaths];
    [self setNeedsDisplay:YES];
}

- (void) makePMTs
{
    [delegate setPMTPositions];
    NSMutableArray* segmentPaths = [NSMutableArray array];
    NSMutableArray* errorPaths   = [NSMutableArray array];
    ORSegmentGroup* group = [delegate segmentGroup:kL200PMTType];
    for(int i=0; i<kL200PMTRings; i++){
        [pmtLabel[i] autorelease];
        pmtLabel[i] = [@"" copy];
    }
    const int npmt[kL200PMTRings]     = {  6, 8, 12, 10,  10, 10,  10};
    const int start[kL200PMTRings]    = {  6, 8, 12,  6,   5,  6,   5};
    const float offset[kL200PMTRings] = {0.5, 0,  0,  0, 0.5,  0, 0.5};
    const float diam = 4*kL200PMTViewHeight / (3*5+1);
    const float bdy  =   kL200PMTViewHeight / (3*5+1);
    const float tdy  = (kL200PMTViewHeight - 4*diam) / 5;
    const float boff = kL200PMTViewHeight + 2*kL200SiPMViewHeight + kL200DetViewHeight;
    const float inset = 0.05 * diam;
    for(int i=0; i<[group numSegments]; i++){
        ORDetectorSegment* segment = [group segment:i];
        const int pmt = [[segment objectForKey:@"kStringName"] intValue];
        const int iring = [[segment objectForKey:@"kRing"] intValue];
        const int ipmt  = (pmt % 100) - 1;
        if(iring >= 0 && iring < kL200PMTRings){
            if(ipmt >= 0 && ipmt < npmt[iring] && [delegate validatePMT:i]){
                int jpmt = (2*npmt[iring] - ipmt - start[iring]) % npmt[iring];
                float x, dx, y;
                dx = (kL200DetViewWidth - 2*tdy - npmt[iring]*diam) / npmt[iring];
                x = tdy + offset[iring]*dx + jpmt*(diam+dx);
                if(iring < 3) y = bdy + (3-iring-1)*(diam+bdy);
                else          y = tdy + (iring-3)*(diam+tdy) + boff;
                NSRect r = NSMakeRect(x, y, diam, diam);
                [segmentPaths addObject:[NSBezierPath bezierPathWithOvalInRect:r]];
                [errorPaths addObject:[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(r, -inset, -inset)]];
                if([pmtLabel[iring] isEqualToString:@""]){
                    pmtLabelY[iring] = y + diam/2;
                    pmtLabel[iring] = [[segment objectForKey:@"kRingLabel"] copy];
                }
            }
        }
    }
    [segmentPathSet addObject:segmentPaths];
    [errorPathSet addObject:errorPaths];
    [detOutlines addObjectsFromArray:errorPaths];
    [self setNeedsDisplay:YES];
}
- (void) makeCC4sSiPMS
{
    if(!strLabelAttr){
        NSFont* font = [NSFont fontWithName:@"Geneva" size:8];
        strLabelAttr = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                         [NSColor blueColor], NSForegroundColorAttributeName, nil] retain];
    }
    for(int i=0; i<kL200SiPMRings; i++){
        [sipmLabel[i] autorelease];
        sipmLabel[i] = [@"" copy];
    }
    
    float xc     = [self bounds].size.width/2+kL200CC4XOffset;
    float yc     = [self bounds].size.height/2;
    
    [delegate setSiPMPositions];
    NSMutableArray* segmentPaths   = [NSMutableArray array];
    NSMutableArray* errorPaths     = [NSMutableArray array];
    ORSegmentGroup* group = [delegate segmentGroup:kL200SiPMType];
    
    int SIPMs_i_cha=kL200SiPMInnerChans;
    int SIPMs_o_cha=kL200SiPMOuterChans;
    
    for(int i=0; i<[group numSegments]; i++){
        ORDetectorSegment* segment = [group segment:i];
        const int sipm = [[segment objectForKey:@"kStringName"] intValue];
        const int sip_barrel_pos = [[segment objectForKey:@"lv_board_B_pos"] intValue];
        int sip_barrel_loc = [[segment objectForKey:@"lv_board_string"] intValue];
        
        if (sipm<=0) continue;
        if (sip_barrel_pos > 1 && sip_barrel_pos < 4){
            if (sip_barrel_pos==3){
                sip_barrel_loc=sip_barrel_loc+SIPMs_i_cha/2;
            }
            NSRect        segRect   = NSMakeRect(29,29,8,8);
            NSBezierPath* segPath   = [NSBezierPath bezierPathWithRect:segRect];
            NSAffineTransform* transform = [NSAffineTransform transform];
            [transform translateXBy:xc yBy:yc];
            [transform rotateByDegrees:80-360/SIPMs_i_cha*sip_barrel_loc];
            [segPath   transformUsingAffineTransform: transform];
            [segmentPaths addObject:segPath];
            
            NSBezierPath* errPath = [NSBezierPath bezierPathWithRect:NSInsetRect(segRect, -1, -1)];
            [errorPaths   addObject:errPath];
            [detOutlines  addObject:errPath];
        }
        else{
            if (sip_barrel_pos==4){
                sip_barrel_loc=sip_barrel_loc+SIPMs_o_cha/2;
            }
            NSRect        segRect   = NSMakeRect(103,103,20,10);
            NSBezierPath* segPath   = [NSBezierPath bezierPathWithRect:segRect];
            NSAffineTransform* transform = [NSAffineTransform transform];
            [transform translateXBy:xc yBy:yc];
            [transform rotateByDegrees:80-360/SIPMs_o_cha*sip_barrel_loc];
            
            [segPath   transformUsingAffineTransform: transform];
            [segmentPaths addObject:segPath];
            
            NSBezierPath* errPath = [NSBezierPath bezierPathWithRect:NSInsetRect(segRect, -1, -1)];
            [errorPaths   addObject:errPath];
            [detOutlines  addObject:errPath];
        }
        int iring = [[segment objectForKey:@"kRing"] intValue];
        if ([sipmLabel[iring] isEqualToString:@""]) {
            // Update the label position and content
            //sipmLabelY[iring] = y + sy / 2;
            [sipmLabel[iring] release];
            sipmLabel[iring] = [[segment objectForKey:@"kRingLabel"] copy];
        }
    }
    
    [segmentPathSet addObject:segmentPaths];
    [errorPathSet   addObject:errorPaths];
    [detOutlines addObjectsFromArray:errorPaths];
    [self setNeedsDisplay:YES];
}

- (void) makeCC4s
{
    NSMutableArray* segmentPaths = [NSMutableArray array];
    NSMutableArray* errorPaths   = [NSMutableArray array];
    ORSegmentGroup* group        = [delegate segmentGroup:kL200CC4Type];
    float xc     = [self bounds].size.width/2+kL200CC4XOffset;
    float yc     = [self bounds].size.height/2;
    int sIndex = 0;
    for(int i=0;i<kNumCC4Positions;i++){
        [cc4Label[i]  release];
        cc4Label[i] = nil;
    }
    int cc4 = 0;
    NSArray* segments = [group segments];
    for(int aPos=0; aPos<kL200NumCC4s; aPos++){
        NSMutableDictionary* params = [[segments objectAtIndex:cc4] params];
        [cc4Label[sIndex] release];
        cc4Label[sIndex] = [[params objectForKey:@"cc4_name"] copy];
        sIndex++;
        for(int chan=0;chan<7;chan++){
            [[segments objectAtIndex:cc4] setHwPresent:[delegate validateCC4:cc4]];
            NSRect        segRect   = NSMakeRect(kL200CC4Offset+kL200CC4Size*chan,aPos%2==0?0:-kL200CC4Size,kL200CC4Size,kL200CC4Size);
            NSBezierPath* segPath   = [NSBezierPath bezierPathWithRect:segRect];
            NSAffineTransform* transform = [NSAffineTransform transform];
            [transform translateXBy:xc yBy:yc];
            [transform rotateByDegrees:kL200CC4StartAngle - aPos/2*kL200CC4DeltaAngle];
            [segPath   transformUsingAffineTransform: transform];
            [segmentPaths addObject:segPath];
            NSBezierPath* errPath = [NSBezierPath bezierPathWithRect:NSInsetRect(segRect, -1, -1)];
            [errorPaths   addObject:errPath];
            [detOutlines  addObject:errPath];
            cc4++;
        }
    }
    [segmentPathSet addObject:segmentPaths];
    [errorPathSet   addObject:errorPaths];
    [self setNeedsDisplay:YES];
}


- (void) makeAuxChans
{
    [delegate setAuxChanPositions];
    NSMutableArray* segmentPaths = [NSMutableArray array];
    NSMutableArray* errorPaths   = [NSMutableArray array];
    ORSegmentGroup* group = [delegate segmentGroup:kL200AuxType];
    for(int i=0; i<kL200AuxLabels; i++){
        [auxLabel[i] autorelease];
        auxLabel[i] = [@"" copy];
    }
    const float xoff = kL200AuxViewWidth*0.25 / 2;
    const float yoff = kL200PMTViewHeight + kL200SiPMViewHeight + kL200DetViewHeight*0.05;
    const float ytot = kL200DetViewHeight * 0.3;
    //const float cx   = kL200AuxViewWidth - 2*xoff;
    const float cx   = 20;
    const float cy   = 4*ytot / (kL200MaxAuxChans*5+1);
    const float dy   =   ytot / (kL200MaxAuxChans*5+1);
    const float inset = MIN(0.05*cx, 0.05*cy);
    for(int i=0; i<[group numSegments]; i++){
        ORDetectorSegment* segment = [group segment:i];
        const int aux = [[segment objectForKey:@"kStringName"] intValue];
        if([delegate validateAuxChan:i]){
            float y = yoff + dy + (kL200MaxAuxChans-aux-1)*(cy+dy)-i*20;
            NSRect r = NSMakeRect(xoff+kL200DetViewWidth, y, cx, cy);
            [segmentPaths addObject:[NSBezierPath bezierPathWithRect:r]];
            [errorPaths   addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(r, -inset, -inset)]];
            if([auxLabel[0] isEqualToString:@""] || [auxLabel[1] isEqualToString:@""]){
                auxLabel[0] = [@"Aux"  retain];
                auxLabel[1] = [@"Chan" retain];
                auxLabelY = yoff + kL200MaxAuxChans*(cy+dy) + dy;
            }
        }
    }
    [segmentPathSet addObject:segmentPaths];
    [errorPathSet addObject:errorPaths];
    [detOutlines addObjectsFromArray:errorPaths];
    [self setNeedsDisplay:YES];
}
-(void) makeSourcesTube
{
    NSMutableArray* segmentPaths = [NSMutableArray array];
    NSMutableArray* errorPaths   = [NSMutableArray array];
    [delegate makeSegmentGroupsSis];
    for (int i=0; i<4; i++){
        NSRect tubeFrame = NSMakeRect(kL200DetViewWidth*1.1+i*20, 50+5, 10, 355-5);
        // Draw bottom ellipse
        NSRect bottomEllipse = NSMakeRect(kL200DetViewWidth*1.1+i*20, 50, 10, 10);
        // Draw top ellipse
        NSRect topEllipse = NSMakeRect(kL200DetViewWidth*1.1+i*20, 50+355-5, 10, 10);
            
        [segmentPaths addObject:[NSBezierPath bezierPathWithRect:tubeFrame]];
        [segmentPaths addObject:[NSBezierPath bezierPathWithOvalInRect:bottomEllipse]];
        [segmentPaths addObject:[NSBezierPath bezierPathWithOvalInRect:topEllipse]];
    }
    [segmentPathSet addObject:segmentPaths];
    //[errorPathSet addObject:errorPaths];
    [detOutlines addObjectsFromArray:errorPaths];
    [self setNeedsDisplay:YES];
}
-(void) makeSource
{
        NSMutableArray* errorPaths1   = [NSMutableArray array];
        [detOutlines1 release];
        detOutlines1 = [[NSMutableArray alloc] init];
        ORSegmentGroup* group = [delegate segmentGroup:kL200SISType];
        
        slowControls = [[[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORLNGSSlowControlsModel,1"]retain];
        
        for (int i=0; i<4; i++){
            float aPos = [[slowControls cmd:@"Source" dataAtRow:i column:2] floatValue];
            int name = [[slowControls cmd:@"Source" dataAtRow:i column:0] intValue];
            if (name<=0) continue; //when slow control is not loaded, we get 0 otherwise source name is 1,2,3,4
            NSString *sourcePos = [NSString stringWithFormat:@"Source Position %d", (int)aPos];
            NSString *sourceName = [NSString stringWithFormat:@"Source %i", name];
            int index=(name-1)*3; //one unit have 3 segment
            [group setSegment:index object:sourcePos forKey:@"kSourcePos"];
            [group setSegment:index object:sourceName forKey:@"kSourceName"];
            
            NSRect topEllipse = NSMakeRect(kL200DetViewWidth*1.1+(name-1)*20, 50+355-5-(aPos/25.8), 10, 10);
            [errorPaths1 addObject:[NSBezierPath bezierPathWithRect:NSInsetRect(topEllipse, -1, -1)]];
        }
        [errorPathSet addObject:errorPaths1];
        [detOutlines1 addObjectsFromArray:errorPaths1];
        [slowControls release];
        [self setNeedsDisplay:YES];
}
-(void)drawSourceLabel{
    NSFont* font = [NSFont fontWithName:@"Geneva" size:7];
    sourceLabelAttr = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                     [NSColor systemRedColor], NSForegroundColorAttributeName, nil] retain];
    for(int i=0; i<4; i++){
        NSString *sisLabel = [NSString stringWithFormat:@"SIS%i",i+1];
        NSAttributedString* s = [[NSAttributedString alloc] initWithString:sisLabel attributes:sourceLabelAttr];
        [s drawAtPoint:NSMakePoint(kL200DetViewWidth*1.095+i*20, 417)];
        [s release];
    }
}
- (void) makeDummySet
{
    NSMutableArray* segmentPaths = [NSMutableArray array];
    NSMutableArray* errorPaths   = [NSMutableArray array];
    [segmentPathSet addObject:segmentPaths];
    [errorPathSet addObject:errorPaths];
    [detOutlines addObjectsFromArray:errorPaths];
}

- (NSColor*) outlineColor:(int)aSet
{
    if(aSet == kL200DetType) return [NSColor grayColor];
    else return [NSColor lightGrayColor];
}

@end
