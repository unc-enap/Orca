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
#import "ORFlashCamADCModel.h"
#import "ORDetectorSegment.h"
#import "ORDetectorView.h"
#import "ORTimeLinePlot.h"
#import "ORCompositePlotView.h"
#import "OR1DHistoPlot.h"
#import "ORTimeAxis.h"
#import "ORColorScale.h"
#import "ORRunModel.h"


@implementation ORL200Controller

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"L200"];
    return self;
}

- (void) dealloc
{
    [rc release];
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
- (NSString*) defaultCC4MapFilePath
{
    return @"~/L200CC4ChanMap.json";
}

- (NSString*) defaultADCSerialMapFilePath
{
    return @"~/L200ADCSerialMap.json";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [self populateClassNamePopup:sipmAdcClassNamePopup];
    [self populateClassNamePopup:pmtAdcClassNamePopup];
    [self populateClassNamePopup:auxChanAdcClassNamePopup];
    [self populateClassNamePopup:cc4AdcClassNamePopup];
    
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
//    OR1DHistoPlot* auxHist = [[OR1DHistoPlot alloc] initWithTag:10+kL200AuxType andDataSource:self];
//    [auxHist setLineColor:[NSColor systemOrangeColor]];
//    [auxHist setName:@"AuxChans"];
    
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
                     selector : @selector(populateDataTypePopup)
                         name : ORDocumentLoadedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(populateDataTypePopup)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(populateDataTypePopup)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(l200FileNameChanged:)
                         name : ORL200ModelL200FileNameChanged
                       object : nil];

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
    [notifyCenter addObserver : self
                     selector : @selector(cc4ChanMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
                        object: [model segmentGroup:kL200CC4Type]];
    [notifyCenter addObserver : self
                     selector : @selector(cc4ChanAdcClassNameChanged:)
                         name : ORSegmentGroupAdcClassNameChanged
                        object: [model segmentGroup:kL200CC4Type]];
    [notifyCenter addObserver : self
                     selector : @selector(adcSerialMapFileChanged:)
                         name : ORSegmentGroupMapFileChanged
                       object : self];
    [notifyCenter addObserver : self
                     selector : @selector(dataCycleChanged:)
                         name : ORL200ModelDataCycleChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(dataPeriodChanged:)
                         name : ORL200ModelDataPeriodChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(dataTypeChanged:)
                         name : ORL200ModelDataTypeChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(customTypeChanged:)
                         name : ORL200ModelCustomTypeChanged
                       object : nil];
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
    [self cc4ChanMapFileChanged:nil];
    [self cc4ChanAdcClassNameChanged:nil];
    [self adcSerialMapFileChanged:nil];
    [self dataCycleChanged:nil];
    [self dataPeriodChanged:nil];
    [self dataTypeChanged:nil];
    [self customTypeChanged:nil];
    [self l200FileNameChanged:nil];
}

- (void) populateDataTypePopup
{
    //called after document is loaded or configchanged
    [dataTypePopup removeAllItems];
    if(!rc){
        rc = [[[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORRunModel,1"] retain];
    }
    NSArray* types = [rc runTypeNames];
    int count = 0;
    for(int i=0;i<32;i++){
        NSString* anItem = [types objectAtIndex:i];
        if(i<[types count] &&
           i>=2            &&
           [anItem length] <= 3 ){
            [dataTypePopup addItemWithTitle:anItem];
            [[dataTypePopup itemAtIndex:count] setTag:i];
            count++;
        }
    }
    //special case
    [dataTypePopup addItemWithTitle:@"Custom"];
    [[dataTypePopup itemAtIndex:count] setTag:32];
    [self dataTypeChanged:nil];
}

- (void) l200FileNameChanged:(NSNotification*) aNote
{
    [l200FileNameField setStringValue:[model l200FileName]];
}

- (void) dataCycleChanged:(NSNotification*) aNote
{
    [dataCycleField setIntValue:[model dataCycle]];
}

- (void) dataPeriodChanged:(NSNotification*) aNote
{
    [dataPeriodField setIntValue:[model dataPeriod]];
}

- (void) dataTypeChanged:(NSNotification*) aNote
{
    [dataTypePopup selectItemWithTag:[model dataType]];
    if([dataTypePopup selectedTag]==32){
        [customTypeLabel setHidden:NO];
        [customTypeField setHidden:NO];
    }
    else {
        [customTypeLabel setHidden:YES];
        [customTypeField setHidden:YES];
    }
}

- (void) customTypeChanged:(NSNotification*) aNote
{
    [customTypeField setStringValue:[model customType]];
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

- (void) cc4ChanAdcClassNameChanged:(NSNotification*)note
{
    [cc4AdcClassNamePopup selectItemWithTitle:[[model segmentGroup:kL200CC4Type] adcClassName]];
}

- (void) auxChanMapFileChanged:(NSNotification*)note
{
    NSString* s = [[[model segmentGroup:kL200AuxType] mapFile] stringByAbbreviatingWithTildeInPath];
    if(!s) s = @"--";
    [auxChanMapFileTextField setStringValue:s];
}

- (void) cc4ChanMapFileChanged:(NSNotification*)note
{
    NSString* s = [[[model segmentGroup:kL200CC4Type] mapFile] stringByAbbreviatingWithTildeInPath];
    if(!s) s = @"--";
    [cc4ChanMapFileTextField setStringValue:s];
}

- (void) adcSerialMapFileChanged:(NSNotification*)note
{
    NSString* s = [[[model segmentGroup:kL200ADCType] mapFile] stringByAbbreviatingWithTildeInPath];
    if(!s) s = @"--";
    [adcSerialFileTextView setStringValue:s];
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
            case kDisplayThresholds:  val = [[model segmentGroup:sg] getThreshold:i];   break;
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

- (IBAction) saveCC4ChanMapFileAction:(id)sender
{
    [self saveMapFile:kL200CC4Type withDefaultPath:[self defaultCC4MapFilePath]];
}

- (IBAction) readCC4ChanMapFileAction:(id)sender
{
    [self readMapFile:kL200CC4Type intoTable:cc4TableView];
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

- (IBAction) cc4AdcClassNameAction:(id)sender
{
    [[model segmentGroup:kL200CC4Type] setAdcClassName:[sender titleOfSelectedItem]];
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

- (IBAction) saveADCSerialMapFileAction:(id)sender
{
    [self saveMapFile:kL200ADCType withDefaultPath:[self defaultADCSerialMapFilePath]];
}

- (IBAction) readADCSerialMapFileAction:(id)sender
{
    [self readMapFile:kL200ADCType intoTable:adcSerialTableView];
}

- (IBAction) dataCycleAction:(id)sender
{
    [model setDataCycle:[sender intValue]];
}

- (IBAction) dataPeriodAction:(id)sender
{
    [model setDataPeriod:[sender intValue]];
}
- (IBAction) bumpDataPeriod:(id)sender
{
    int aValue = [model dataPeriod];
    if([sender intValue]==1)aValue++;
    else aValue--;
    [model setDataPeriod:aValue];
}
- (IBAction) bumpDataCycle:(id)sender
{
    int aValue = [model dataCycle];
    if([sender intValue]==1)aValue++;
    else aValue--;
    [model setDataCycle:aValue];
}

- (void) controlTextDidChange: (NSNotification *)note {
    NSTextField * field = [note object];
    if(field==customTypeField){
        [model setCustomType:[field stringValue]];
    }
}

- (IBAction) customTypeAction:(id)sender
{
    [model setCustomType:[sender stringValue]];
}

- (IBAction) dataTypePopupAction:(id)sender
{
    [model setDataType:(int)[sender selectedTag]];
}

#pragma mark •••Interface Management

- (int) segmentTypeFromTableView:(NSTableView*)view
{
    if(view == primaryTableView)        return kL200DetType;
    else if(view == sipmTableView)      return kL200SiPMType;
    else if(view == pmtTableView)       return kL200PMTType;
    else if(view == auxChanTableView)   return kL200AuxType;
    else if(view == cc4TableView)       return kL200CC4Type;
    else if(view == adcSerialTableView) return kL200ADCType;
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
    if(type >= 0 && type < kL200CC4Type) return [[model segmentGroup:type] numSegments];
    else if(type == kL200CC4Type)        return kNumCC4Positions;
    else if(type == kL200ADCType)        return [[model segmentGroup:type] numSegments];
    else if(aTableView)                  return kL200MaxDetsPerString;
    else return 0;
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)aRowIndex
{
    int type = [self segmentTypeFromTableView:aTableView];
    if(type >= 0 || type < kL200SegmentTypeCount){
        if(type==kL200CC4Type){
            if([[aTableColumn identifier]isEqualToString:@"cc4_position"]){
                return [NSString stringWithFormat:@"%ld",aRowIndex+1];
            }
            else if([[aTableColumn identifier]isEqualToString:@"cc4_slota"]){
                return [self getCC4Name:(int)aRowIndex slot:0];
            }
            else if([[aTableColumn identifier]isEqualToString:@"cc4_slotb"]){
                return [self getCC4Name:(int)aRowIndex slot:1];
            }
            else return nil;
        }
        else return [[model segmentGroup:type] segment:(int)aRowIndex objectForKey:[aTableColumn identifier]];
    }
    else return nil;
}

- (void) tableView:(NSTableView*)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)aRowIndex
{
    if(!anObject) anObject = @"--";
    int type = [self segmentTypeFromTableView:aTableView];
    if(type >= 0 || type < kL200SegmentTypeCount){
        if(type==kL200CC4Type){
            int aSlot= [[aTableColumn identifier] isEqualToString:@"cc4_slota"]?0:1;
            [self setCC4:(int)aRowIndex slot:aSlot name:anObject];
        }
        else {
            ORDetectorSegment* segment = [[model segmentGroup:type] segment:(int)aRowIndex];
            [segment setObject:anObject forKey:[aTableColumn identifier]];
            // add the ADC daughter card serial numbers to the channel maps
            if(type == kL200ADCType){
                NSString* identifier = [aTableColumn identifier];
                if([identifier isEqualTo:@"adc_serial_0"] || [identifier isEqualTo:@"adc_serial_1"]){
                    NSString* serial = (NSString*) anObject;
                    if(serial){
                        if([serial length] > 0 && [serial rangeOfString:@"-"].location == NSNotFound){
                            id crate = [self tableView:aTableView
                             objectValueForTableColumn:[aTableView tableColumnWithIdentifier:@"daq_crate"]
                                                   row:aRowIndex];
                            id addr =  [self tableView:aTableView
                             objectValueForTableColumn:[aTableView tableColumnWithIdentifier:@"daq_board_id"]
                                                   row:aRowIndex];
                            id slot  = [self tableView:aTableView
                             objectValueForTableColumn:[aTableView tableColumnWithIdentifier:@"daq_board_slot"]
                                                   row:aRowIndex];
                            id ser0  = [self tableView:aTableView
                             objectValueForTableColumn:[aTableView tableColumnWithIdentifier:@"adc_serial_0"]
                                                   row:aRowIndex];
                            id ser1 = [self tableView:aTableView
                            objectValueForTableColumn:[aTableView tableColumnWithIdentifier:@"adc_serial_1"]
                                                  row:aRowIndex];
                            for(int itype=kL200DetType; itype<=kL200AuxType; itype++){
                                int nchan = (itype == kL200PMTType) ? kFlashCamADCStdChannels/2 : kFlashCamADCChannels/2;
                                for(int iseg=0; iseg<[[model segmentGroup:itype] numSegments]; iseg++){
                                    ORDetectorSegment* segment = [[model segmentGroup:itype] segment:iseg];
                                    if([[segment objectForKey:@"daq_crate"]        isEqualToString:crate] &&
                                       [[segment objectForKey:@"daq_board_id"]     isEqualToString:addr]  &&
                                       [[segment objectForKey:@"daq_board_slot"]   isEqualToString:slot]){
                                        if([[segment objectForKey:@"daq_board_ch"] intValue]  < nchan)
                                            [segment  setObject:ser0 forKey:@"adc_serial"];
                                        else [segment setObject:ser1 forKey:@"adc_serial"];
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
        }
        [[model segmentGroup:type] configurationChanged:nil];
    }
}

- (NSIndexPath*) tableView:(NSTableView*)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath*)sourceIndexPath
                         toProposedIndexPath:(NSIndexPath*)proposedDestinationIndexPath
{
    return sourceIndexPath;
}

- (void) setCC4:(int)aPosition slot:(int)aSlot name:(NSString*)aName
{
    //-----map entry changed
    ORSegmentGroup* group = [model segmentGroup:kL200CC4Type];
    int segNum = aPosition*14;
    if(aSlot==1) segNum+=7;
    for(int i=0;i<7;i++){
        NSMutableDictionary* params = [NSMutableDictionary dictionary];
        [params setObject:aName                                       forKey:@"cc4_name"];
        [params setObject:[NSString stringWithFormat:@"%d",aPosition] forKey:@"cc4_position"];
        [params setObject:[NSString stringWithFormat:@"%d",i]         forKey:@"cc4_chan"];
        [params setObject:[NSString stringWithFormat:@"%d",aSlot]     forKey:@"cc4_slot"];
        [[group segment:segNum+i] setParams:params];
    }
}

- (NSString*) getCC4Name:(int)aPosition slot:(int)aSlot
{
    //this is a map table request
    ORSegmentGroup* group = [model segmentGroup:kL200CC4Type];
    int segNum = aPosition*14;
    if(aSlot==1) segNum+=7;
    NSDictionary* params = [[group segment:segNum] params];
    return [params objectForKey:@"cc4_name"];
}

@end
