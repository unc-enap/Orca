//  Orca
//  ORL200Controller.m
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

#import "ORL200Controller.h"
#import "ORL200Model.h"
#import "ORL200SegmentGroup.h"
#import "ORDetectorView.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "OR1DHistoPlot.h"
#import "ORTimeAxis.h"
#import "ORColorScale.h"


@implementation ORL200Controller

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"L200"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (NSString*) defaultPrimaryMapFilePath
{
    return @"~/L200DetectorMap.json";
}

- (NSString*) defaultSiPMMapFilePath
{
    return @"~/L200SiPMMap.json";
}

- (NSString*) defaultPMTMapFilePath
{
    return @"~/L200PMTMap.json";
}

- (NSString*) defaultAuxChanMapFilePath
{
    return @"~/L200AuxChanMap.json";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [self populateClassNamePopup:sipmAdcClassNamePopup];
    [self populateClassNamePopup:pmtAdcClassNamePopup];
    [self populateClassNamePopup:auxChanAdcClassNamePopup];
    
    [(ORPlot*) [ratePlot plotWithTag:kL200DetType] setLineColor:[NSColor systemBlueColor]];
    ORTimeLinePlot* sipmPlot = [[ORTimeLinePlot alloc] initWithTag:kL200SiPMType andDataSource:self];
    [sipmPlot setLineColor:[NSColor systemGreenColor]];
    [ratePlot addPlot:sipmPlot];
    [sipmPlot release];
    ORTimeLinePlot* pmtPlot = [[ORTimeLinePlot alloc] initWithTag:kL200PMTType andDataSource:self];
    [pmtPlot setLineColor:[NSColor systemRedColor]];
    [ratePlot addPlot:pmtPlot];
    [pmtPlot release];
    ORTimeLinePlot* auxPlot = [[ORTimeLinePlot alloc] initWithTag:kL200AuxType andDataSource:self];
    [auxPlot setLineColor:[NSColor systemOrangeColor]];
    [ratePlot addPlot:auxPlot];
    [auxPlot release];
    
    [(ORPlot*) [valueHistogramsPlot plotWithTag:10+kL200DetType] setLineColor:[NSColor systemBlueColor]];
    [(ORPlot*) [valueHistogramsPlot plotWithTag:10+kL200DetType] setName:@"Detectors"];
    OR1DHistoPlot* sipmHist = [[OR1DHistoPlot alloc] initWithTag:10+kL200SiPMType andDataSource:self];
    [sipmHist setLineColor:[NSColor systemGreenColor]];
    [sipmHist setName:@"SiPMs"];
    [valueHistogramsPlot addPlot:sipmHist];
    [sipmHist release];
    OR1DHistoPlot* pmtHist = [[OR1DHistoPlot alloc] initWithTag:10+kL200PMTType andDataSource:self];
    [pmtHist setLineColor:[NSColor systemRedColor]];
    [pmtHist setName:@"PMTs"];
    [valueHistogramsPlot addPlot:pmtHist];
    [pmtHist release];
    OR1DHistoPlot* auxHist = [[OR1DHistoPlot alloc] initWithTag:10+kL200AuxType andDataSource:self];
    [auxHist setLineColor:[NSColor systemOrangeColor]];
    [auxHist setName:@"AuxChans"];
    
    [primaryColorScale setSpectrumRange:0.7];
    [sipmColorScale    setSpectrumRange:0.7];
    [pmtColorScale     setSpectrumRange:0.7];
    [auxChanColorScale setSpectrumRange:0.7];
    [[primaryColorScale colorAxis] setRngLimitsLow:0 withHigh:128000 withMinRng:0.01];
    [[primaryColorScale colorAxis] setRngDefaultsLow:0 withHigh:128000];
    [[sipmColorScale    colorAxis] setNeedsDisplay:YES];
    [[sipmColorScale    colorAxis] setRngLimitsLow:0 withHigh:128000 withMinRng:0.01];
    [[sipmColorScale    colorAxis] setRngDefaultsLow:0 withHigh:128000];
    [[pmtColorScale     colorAxis] setNeedsDisplay:YES];
    [[pmtColorScale     colorAxis] setRngLimitsLow:0 withHigh:128000 withMinRng:0.01];
    [[pmtColorScale     colorAxis] setRngDefaultsLow:0 withHigh:128000];
    [[auxChanColorScale colorAxis] setNeedsDisplay:YES];
    [[auxChanColorScale colorAxis] setRngLimitsLow:0 withHigh:128000 withMinRng:0.01];
    [[auxChanColorScale colorAxis] setRngDefaultsLow:0 withHigh:128000];
}

#pragma mark •••Notifications

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(viewTypeChanged:)
                         name : ORL200ModelViewTypeChanged
                        object: model];
    [notifyCenter addObserver : self
                     selector : @selector(sipmColorAxisAttributesChanged:)
                         name : ORAxisRangeChangedNotification
                       object : [sipmColorScale colorAxis]];
    [notifyCenter addObserver : self
                     selector : @selector(sipmAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
                        object: [model segmentGroup:kL200SiPMType]];
    [notifyCenter addObserver : self
                     selector : @selector(sipmMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
                        object: [model segmentGroup:kL200SiPMType]];
    [notifyCenter addObserver : self
                     selector : @selector(pmtColorAxisAttributesChanged:)
                         name : ORAxisRangeChangedNotification
                       object : [pmtColorScale colorAxis]];
    [notifyCenter addObserver : self
                     selector : @selector(pmtAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
                        object: [model segmentGroup:kL200PMTType]];
    [notifyCenter addObserver : self
                     selector : @selector(pmtMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
                        object: [model segmentGroup:kL200PMTType]];
    [notifyCenter addObserver : self
                     selector : @selector(auxChanColorAxisAttributesChanged:)
                         name : ORAxisRangeChangedNotification
                       object : [auxChanColorScale colorAxis]];
    [notifyCenter addObserver : self
                     selector : @selector(auxChanAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
                        object: [model segmentGroup:kL200AuxType]];
    [notifyCenter addObserver : self
                     selector : @selector(auxChanMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
                        object: [model segmentGroup:kL200AuxType]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self viewTypeChanged:nil];
    [self colorScaleTypeChanged:nil];
    [self sipmColorAxisAttributesChanged:nil];
    [self sipmAdcClassNameChanged:nil];
    [self sipmMapFileChanged:nil];
    [self pmtColorAxisAttributesChanged:nil];
    [self pmtAdcClassNameChanged:nil];
    [self pmtMapFileChanged:nil];
    [self auxChanColorAxisAttributesChanged:nil];
    [self auxChanAdcClassNameChanged:nil];
    [self auxChanMapFileChanged:nil];
}

-(void) groupChanged:(NSNotification*)note
{
    //if(note == nil || [note object] == model || [[note object] guardian] == model){
    //    [subComponentsView setNeedsDisplay:YES];
    //}
}

-(void) segmentGroupChanged:(NSNotification*)note
{
    [super segmentGroupChanged:note];
    [detectorView makeAllSegments];
}

- (void) viewTypeChanged:(NSNotification*)note
{
    [viewTypePopup selectItemAtIndex:[model viewType]];
    [(ORL200DetectorView*) detectorView setViewType:[model viewType]];
    [detectorView makeAllSegments];
}

- (void) colorScaleTypeChanged:(NSNotification*)note{
    [super colorScaleTypeChanged:note];
    [[self viewToDisplay] setNeedsDisplay:YES];
    [sipmColorScale    setStartColor:[primaryColorScale startColor]];
    [sipmColorScale      setEndColor:[primaryColorScale endColor]];
    [sipmColorScale    setUseRainBow:[primaryColorScale useRainBow]];
    [pmtColorScale     setStartColor:[primaryColorScale startColor]];
    [pmtColorScale       setEndColor:[primaryColorScale endColor]];
    [pmtColorScale     setUseRainBow:[primaryColorScale useRainBow]];
    [auxChanColorScale setStartColor:[primaryColorScale startColor]];
    [auxChanColorScale   setEndColor:[primaryColorScale endColor]];
    [auxChanColorScale setUseRainBow:[primaryColorScale useRainBow]];
}

- (void) customColor1Changed:(NSNotification*)note
{
    [sipmColorScale    setStartColor:[model customColor1]];
    [pmtColorScale     setStartColor:[model customColor1]];
    [auxChanColorScale setStartColor:[model customColor1]];
    [super customColor1Changed:note];
}

- (void) customColor2Changed:(NSNotification*)note
{
    [sipmColorScale    setEndColor:[model customColor2]];
    [pmtColorScale     setEndColor:[model customColor2]];
    [auxChanColorScale setEndColor:[model customColor2]];
    [super customColor2Changed:note];
}

- (void) sipmColorAxisAttributesChanged:(NSNotification*)note
{
    BOOL log = [[sipmColorScale colorAxis] isLog];
    [sipmColorAxisLogCB setState:log];
    [[model segmentGroup:kL200SiPMType] setColorAxisAttributes:[[sipmColorScale colorAxis] attributes]];
}

- (void) sipmAdcClassNameChanged:(NSNotification*)note
{
    [sipmAdcClassNamePopup selectItemWithTitle:[[model segmentGroup:kL200SiPMType] adcClassName]];
}

- (void) sipmMapFileChanged:(NSNotification*)note
{
    NSString* s = [[[model segmentGroup:kL200SiPMType] mapFile] stringByAbbreviatingWithTildeInPath];
    if(!s) s = @"--";
    [sipmMapFileTextField setStringValue:s];
}

- (void) pmtColorAxisAttributesChanged:(NSNotification*)note
{
    BOOL log = [[pmtColorScale colorAxis] isLog];
    [pmtColorAxisLogCB setState:log];
    [[model segmentGroup:kL200PMTType] setColorAxisAttributes:[[pmtColorScale colorAxis] attributes]];
}

- (void) pmtAdcClassNameChanged:(NSNotification*)note
{
    [pmtAdcClassNamePopup selectItemWithTitle:[[model segmentGroup:kL200PMTType] adcClassName]];
}

- (void) pmtMapFileChanged:(NSNotification*)note
{
    NSString* s = [[[model segmentGroup:kL200PMTType] mapFile] stringByAbbreviatingWithTildeInPath];
    if(!s) s = @"--";
    [pmtMapFileTextField setStringValue:s];
}

- (void) auxChanColorAxisAttributesChanged:(NSNotification*)note
{
    BOOL log = [[auxChanColorScale colorAxis] isLog];
    [auxChanColorAxisLogCB setState:log];
    [[model segmentGroup:kL200AuxType] setColorAxisAttributes:[[auxChanColorScale colorAxis] attributes]];
}

- (void) auxChanAdcClassNameChanged:(NSNotification*)note
{
    [auxChanAdcClassNamePopup selectItemWithTitle:[[model segmentGroup:kL200AuxType] adcClassName]];
}

- (void) auxChanMapFileChanged:(NSNotification*)note
{
    NSString* s = [[[model segmentGroup:kL200AuxType] mapFile] stringByAbbreviatingWithTildeInPath];
    if(!s) s = @"--";
    [auxChanMapFileTextField setStringValue:s];
}


#pragma mark •••Actions

- (IBAction) viewTypeAction:(id)sender
{
    [model setViewType:(int)[sender indexOfSelectedItem]];
}

- (void) autoscale:(ORColorScale*)colorScale forSegmentGroup:(int)sg
{
    int n = [[model segmentGroup:sg] numSegments];
    float maxVal = -99999;
    for(int i=0; i<n; i++){
        float val = maxVal;
        switch([model displayType]){
            case kDisplayRates:       val = [[model segmentGroup:sg] getRate:i];        break;
            case kDisplayTotalCounts: val = [[model segmentGroup:sg] getTotalCounts:i]; break;
            default: break;
        }
        maxVal = MAX(maxVal, val);
    }
    if(maxVal != -99999){
        maxVal += maxVal * 0.2;
        [[colorScale colorAxis] setRngLow:0 withHigh:maxVal];
    }
}

- (void) saveMapFile:(int)sg withDefaultPath:(NSString*)defaultPath
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:@"Save As"];
    [savePanel setCanCreateDirectories:YES];
    NSString* startingDir;
    NSString* defaultFile;
    NSString* fullPath = [[[model segmentGroup:sg] mapFile] stringByExpandingTildeInPath];
    if(fullPath){
        startingDir = [fullPath stringByDeletingLastPathComponent];
        defaultFile = [fullPath lastPathComponent];
    }
    else {
        startingDir = NSHomeDirectory();
        defaultFile = defaultPath;
        
    }
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [savePanel setNameFieldLabel:defaultFile];
    [savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [(ORL200SegmentGroup*) [model segmentGroup:sg] saveMapFileAs:[[savePanel URL] path]];
        }
    }];
}

- (void) readMapFile:(int)sg intoTable:(NSTableView*)view
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Choose"];
    NSString* startingDir;
    NSString* fullPath = [[[model segmentGroup:sg] mapFile] stringByExpandingTildeInPath];
    if(fullPath) startingDir = [fullPath stringByDeletingLastPathComponent];
    else startingDir = NSHomeDirectory();
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:startingDir]];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [(ORL200SegmentGroup*) [model segmentGroup:sg] readMap:[[openPanel URL] path]];
            [view reloadData];
        }
    }];
}

- (IBAction) savePrimaryMapFileAction:(id)sender
{
    [self saveMapFile:kL200DetType withDefaultPath:[self defaultPrimaryMapFilePath]];
}

- (IBAction) readPrimaryMapFileAction:(id)sender
{
    [self readMapFile:kL200DetType intoTable:primaryTableView];
}

- (IBAction) sipmAdcClassNameAction:(id)sender
{
    [[model segmentGroup:kL200SiPMType] setAdcClassName:[sender titleOfSelectedItem]];
}

- (IBAction) saveSIPMMapFileAction:(id)sender
{
    [self saveMapFile:kL200SiPMType withDefaultPath:[self defaultSiPMMapFilePath]];
}

- (IBAction) readSIPMMapFileAction:(id)sender
{
    [self readMapFile:kL200SiPMType intoTable:sipmTableView];
}

- (IBAction) autoscaleSIPMColorScale:(id)sender
{
    [self autoscale:sipmColorScale forSegmentGroup:kL200SiPMType];
}

- (IBAction) pmtAdcClassNameAction:(id)sender
{
    [[model segmentGroup:kL200PMTType] setAdcClassName:[sender titleOfSelectedItem]];
}

- (IBAction) savePMTMapFileAction:(id)sender
{
    [self saveMapFile:kL200PMTType withDefaultPath:[self defaultPMTMapFilePath]];
}

- (IBAction) readPMTMapFileAction:(id)sender
{
    [self readMapFile:kL200PMTType intoTable:pmtTableView];
}

- (IBAction) autoscalePMTColorScale:(id)sender
{
    [self autoscale:pmtColorScale forSegmentGroup:kL200PMTType];
}

- (IBAction) auxChanAdcClassNameAction:(id)sender
{
    [[model segmentGroup:kL200AuxType] setAdcClassName:[sender titleOfSelectedItem]];
}

- (IBAction) saveAuxChanMapFileAction:(id)sender
{
    [self saveMapFile:kL200AuxType withDefaultPath:[self defaultAuxChanMapFilePath]];
}

- (IBAction) readAuxChanMapFileAction:(id)sender
{
    [self readMapFile:kL200AuxType intoTable:auxChanTableView];
}

- (IBAction) autoscaleAuxChanColorScale:(id)sender
{
    [self autoscale:auxChanColorScale forSegmentGroup:kL200AuxType];
}


#pragma mark •••Interface Management

- (int) segmentTypeFromTableView:(NSTableView*)view
{
    if(view == primaryTableView)      return kL200DetType;
    else if(view == sipmTableView)    return kL200SiPMType;
    else if(view == pmtTableView)     return kL200PMTType;
    else if(view == auxChanTableView) return kL200AuxType;
    else return -1;
}

- (void) newTotalRateAvailable:(NSNotification*)aNotification
{
    [sipmRateField setFloatValue:[[model segmentGroup:kL200SiPMType] rate]];
    [pmtRateField setFloatValue:[[model segmentGroup:kL200PMTType] rate]];
    [auxChanRateField setFloatValue:[[model segmentGroup:kL200AuxType] rate]];
    [super newTotalRateAvailable:aNotification];
}


#pragma mark •••Table Data Source

- (NSInteger) numberOfRowsInTableView:(NSTableView*)aTableView
{
    int type = [self segmentTypeFromTableView:aTableView];
    if(type >= 0 && type < kL200SegmentTypeCount) return [[model segmentGroup:type] numSegments];
    else if(aTableView == stringMapTableView) return kL200MaxDetsPerString;
    else return 0;
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)aRowIndex
{
    int type = [self segmentTypeFromTableView:aTableView];
    if(type >= 0 || type < kL200SegmentTypeCount)
        return [[model segmentGroup:type] segment:(int)aRowIndex objectForKey:[aTableColumn identifier]];
    else if(aTableView == stringMapTableView) return nil;
    else return nil;
}

- (void) tableView:(NSTableView*)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)aRowIndex
{
    if(!anObject) anObject = @"--";
    int type = [self segmentTypeFromTableView:aTableView];
    if(type >= 0 || type < kL200SegmentTypeCount){
        ORDetectorSegment* segment = [[model segmentGroup:type] segment:(int)aRowIndex];
        [segment setObject:anObject forKey:[aTableColumn identifier]];
        [[model segmentGroup:type] configurationChanged:nil];
    }
}

- (NSIndexPath*) tableView:(NSTableView*)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)sourceIndexPath
                         toProposedIndexPath:(NSIndexPath*)proposedDestinationIndexPath
{
    return sourceIndexPath;
}


@end
