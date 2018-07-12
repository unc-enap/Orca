//
//  ORDataSetController.m
//  Orca
//
//  Created by Mark Howe on Thurs Feb 20 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark ¥¥¥Imported Files
#import "ORDataSetController.h"
#import "ORDataSet.h"

#import "ORSubPlotController.h"
#import "ORPlotView.h"
#import "ORAxis.h"
#import "ORHistoModel.h"
#import "ZFlowLayout.h"

#pragma mark ¥¥¥Definitions

@interface ORDataSetController (private)
- (void) addSubController:(ORSubPlotController*)aController;
- (void) removeSubPlotViews;
- (void) setUpViews;
@end

@implementation ORDataSetController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"DataSet"];
    return self;
}

- (void) dealloc
{
    [subControllers release];
    [super dealloc];
}

- (void) setModel:(id)aModel
{
    if(!aModel){
        NSUInteger i;
        NSUInteger n = [model numberOfChildren];
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        for(i=0;i<n;i++){
            id oldModel = [(ORDataSet*)[model childAtIndex:i]data];
            [nc postNotificationName:@"DecoderNotWatching" object:[oldModel dataSet] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[oldModel shortName],@"DataSetKey",nil]];
        }
    }

    [super setModel:aModel];
    if(inited){
		[self removeSubPlotViews];
        NSString* windowTitle = [model shortName];
        if(windowTitle)[[self window] setTitle:windowTitle];
        else [[self window] setTitle:@"---"];
		[self modelChanged:nil];
		[self setUpViews];
    }
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    inited = YES;
	[self removeSubPlotViews];
	[[self window] setTitle:[model shortName]];
	[self modelChanged:nil];
    [maxXValueField setIntValue:[model maxX]];
    [maxYValueField setIntValue:[model maxY]];
    [minYValueField setIntValue:[model minY]];
    [minXValueField setIntValue:[model minX]];
    
	//[self setUpViews];
}

- (void) setUpViews
{
    int i;
    NSUInteger n = [model numberOfChildren];
    for(i=0;i<n;i++){ 
		ORSubPlotController* subPlotController = [ORSubPlotController panel];
		[self addSubController:subPlotController];
		[subPlotController  setModel:[(ORDataSet*)[model childAtIndex:i]data]];
	}
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{	

    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(dataSetRemoved:)
                         name : ORDataSetRemoved
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(forcedLimitsMaxXChanged:)
                         name : ORForceLimitsMaxXChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(forcedLimitsMinXChanged:)
                         name : ORForceLimitsMinXChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(forcedLimitsMaxYChanged:)
                         name : ORForceLimitsMaxYChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(forcedLimitsMinYChanged:)
                         name : ORForceLimitsMinYChanged
                       object : model];

}

- (void) modelChanged:(NSNotification*)aNotification
{    
    NSEnumerator* e = [subControllers objectEnumerator];
   id obj;
   while(obj = [e nextObject]){
       [[obj plotView] setNeedsDisplay:YES];
    }
}

- (void) dataSetRemoved:(NSNotification*)aNote
{
    if([aNote object] == model){
		[self setModel:nil];
		[[self window] close];
    }
}

- (void) forcedLimitsMaxXChanged:(NSNotification*)aNote
{
    [maxXValueField setIntValue:[model maxX]];
    [self setXLimits];
}
- (void) forcedLimitsMinXChanged:(NSNotification*)aNote
{
    [minXValueField setIntValue:[model minX]];
    [self setXLimits];
}
- (void) forcedLimitsMaxYChanged:(NSNotification*)aNote
{
    [maxYValueField setIntValue:[model maxY]];
    [self setYLimits];
}
- (void) forcedLimitsMinYChanged:(NSNotification*)aNote
{
    [minYValueField setIntValue:[model minY]];
    [self setYLimits];
}


#pragma mark ¥¥¥Accessors
- (NSMutableArray*) subControllers
{
    return subControllers;
}

- (void) setSubControllers:(NSMutableArray*)newSubControllers
{
    [newSubControllers retain];
    [subControllers release];
    subControllers=newSubControllers;
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
   [self modelChanged:nil];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
}

#pragma mark ¥¥¥Actions
- (IBAction) reLoad:(id)sender
{
    [self setModel:model];
}

- (IBAction) centerOnPeak:(id)sender
{
   [subControllers makeObjectsPerformSelector:@selector(centerOnPeak:) withObject:sender]; 
}

- (IBAction) autoScaleX:(id)sender
{

    [subControllers makeObjectsPerformSelector:@selector(autoScaleX:) withObject:sender]; 
}

- (IBAction) autoScaleY:(id)sender
{
	
    [subControllers makeObjectsPerformSelector:@selector(autoScaleY:) withObject:sender]; 
}


- (IBAction) toggleLog:(id)sender
{
    NSEnumerator* e = [subControllers objectEnumerator];
    ORSubPlotController* obj;
    while(obj = [e nextObject]){
        [[[obj plotView] yScale] setLog:![[[obj plotView]yScale] isLog]];
    }
}

- (IBAction) forceLimitsNowAction:(id)sender
{
    [model setMaxX:[maxXValueField floatValue]];
    [model setMaxY:[maxYValueField floatValue]];
    [model setMinX:[minXValueField floatValue]];
    [model setMinY:[minYValueField floatValue]];
}

- (IBAction) forceLimitsAction:(id)sender
{
    [model setMaxX:[maxXValueField floatValue]];
    [model setMaxY:[maxYValueField floatValue]];
    [model setMinX:[minXValueField floatValue]];
    [model setMinY:[minYValueField floatValue]];
}

- (void) setXLimits
{
    float maxXValue = [model maxX];
    float minXValue = [model minX];
    if((maxXValue!=0) && (maxXValue!=minXValue)){
        float x1 = MIN(minXValue,maxXValue);
        float x2 = MAX(minXValue,maxXValue);
        
        for(id obj in subControllers){
            [[[obj plotView] xScale] setRngLow:x1 withHigh:x2];
        }
    }
}

- (void) setYLimits
{
    float maxYValue = [model maxY];
    float minYValue = [model minY];
    if((maxYValue !=0) && (maxYValue!=minYValue)){
        float y1 = MIN(minYValue,maxYValue);
        float y2 = MAX(minYValue,maxYValue);
        
        for(id obj in subControllers){
            [[[obj plotView] yScale] setRngLow:y1 withHigh:y2];
        }
    }
}
#pragma mark ¥¥¥Private

- (void) removeSubPlotViews
{
    [subControllers removeAllObjects];
}

- (void) addSubController:(ORSubPlotController*)aController
{
    if(!subControllers)[self setSubControllers:[NSMutableArray array]];
    [subControllers addObject:aController];
    [view setSizing:ZMakeFlowLayoutSizing( [[aController view] frame].size, 5, ZSpringRight, NO )];
    [view addSubview:[aController view]];
}



@end
