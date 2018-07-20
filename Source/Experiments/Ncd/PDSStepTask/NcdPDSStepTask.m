//
//  NcdPDSStepTask.m
//  Orca
//
//  Created by Mark Howe on July 1, 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


#import "NcdPDSStepTask.h"
#import "ORPulserDistribModel.h"
#import "NcdTube.h"
#import "NcdDetector.h"

@interface NcdPDSStepTask (private)
- (BOOL)  _doWork;
@end

@implementation NcdPDSStepTask
-(id)	init
{
    if( self = [super init] ){
#if !defined(MAC_OS_X_VERSION_10_9)
        [NSBundle loadNibNamed:@"NcdPDSStepTask" owner:self];
#else
        [[NSBundle mainBundle] loadNibNamed:@"NcdPDSStepTask" owner:self topLevelObjects:&stepTaskObjects];
#endif
        [stepTaskObjects retain];

        
        [self setTitle:@"PDS Step Thru"];
        [self setPatternArray:[NSMutableArray arrayWithObjects:
							   [NSNumber numberWithLong:0],
							   [NSNumber numberWithLong:0],
							   [NSNumber numberWithLong:0],
							   [NSNumber numberWithLong:0],
							   nil]];
        
        [self registerNotificationObservers];
    }
    return self;
}

-(void)	dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [lastTime release];
    [patternArray release];
    [stepTaskObjects release];

    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self addExtraPanel:extraView];
    if(!patternArray){
    	[self setPatternArray:[NSMutableArray arrayWithObjects:
							   [NSNumber numberWithLong:0],
							   [NSNumber numberWithLong:0],
							   [NSNumber numberWithLong:0],
							   [NSNumber numberWithLong:0],
							   nil]];
        
    }
    [self distributionPatternChanged:nil];
    [self tubeMapChanged:nil];
    [self updateButtons];
}


#pragma mark ¥¥¥Accessors




// ===========================================================
// - patternArray:
// ===========================================================
- (NSMutableArray *)patternArray
{
    return patternArray; 
}

// ===========================================================
// - setPatternArray:
// ===========================================================
- (void)setPatternArray:(NSMutableArray *)aPatternArray
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternArray:patternArray];
    
    [aPatternArray retain];
    [patternArray release];
    patternArray = aPatternArray;
    
    [self patternChanged:nil];
}

// ===========================================================
// - reloadPDS:
// ===========================================================
- (BOOL)reloadPDS
{
    return reloadPDS;
}

// ===========================================================
// - setReloadPDS:
// ===========================================================
- (void)setReloadPDS:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setReloadPDS:reloadPDS];
    reloadPDS = flag;
    [reloadPDSButton setState:reloadPDS];
    [self setEnabledStates];
}

// ===========================================================
// - ignorePDS:
// ===========================================================
- (BOOL)ignorePDS
{
    return ignorePDS;
}

// ===========================================================
// - setIgnorePDS:
// ===========================================================
- (void)setIgnorePDS:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnorePDS:ignorePDS];
    ignorePDS = flag;
    [ignorePDSButton setState:ignorePDS];
    [self setEnabledStates];
}


- (uint32_t)patternMaskForArray:(int)arrayIndex
{
    return (uint32_t)[[patternArray objectAtIndex:arrayIndex] longValue];
}

- (void) setPatternMaskForArray:(int)arrayIndex to:(uint32_t)aValue
{
    int32_t currentValue = [self patternMaskForArray:arrayIndex];
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternMaskForArray:arrayIndex to:currentValue];
	
    [patternArray replaceObjectAtIndex:arrayIndex withObject:[NSNumber numberWithLong:aValue]];
    
    [self patternChanged:nil];
}

- (int)timeOnOneChannel {
    
    return timeOnOneChannel;
}

- (void)setTimeOnOneChannel:(int)aTimeOnOneChannel {
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeOnOneChannel:timeOnOneChannel];
    timeOnOneChannel = aTimeOnOneChannel;
    if(timeOnOneChannel<1)timeOnOneChannel=1;
    [timeField setIntValue:timeOnOneChannel];
    [timeStepper setIntValue:timeOnOneChannel];
}


- (int) numberEnabledChannels
{
    id patternObj;
    NSEnumerator* e = [patternArray objectEnumerator];
    int count = 0;
    while(patternObj = [e nextObject]){
        short bit;
        for(bit=0;bit< 16;bit++){
            if([patternObj longValue] & (1L<<bit)) ++count;
        }
    }
    return count;
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{	
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(distributionPatternChanged:)
                         name : ORPulserDistribPatternBitChangedNotification
                       object : nil];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(distributionPatternChanged:)
                         name : ORDocumentLoadedNotification
                       object : nil];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(distributionPatternChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(distributionPatternChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(tubeMapChanged:)
                         name : ORNcdTubeMapReadNotification
                       object : nil];
    
    
}

- (void) updateView
{
    [self patternChanged:nil];
    [self updateButtons];    
}

- (void) tubeMapChanged:(NSNotification*)aNotification
{
	/*    NSEnumerator* e = [[[NcdDetector sharedInstance] tubes] objectEnumerator];
	 NcdTube* tube;
	 while(tube = [e nextObject]){
	 NSString* pBoard = [tube objectForKeyIndex:kPdsBoardNum]; 
	 NSString* pChan = [tube objectForKeyIndex:kPdsChan];
	 if(pBoard && pChan){
	 int board = [pBoard intValue];
	 int chan  = [pChan intValue];
	 NSMatrix* matrix;
	 if(board == 0)matrix = patternMatrix0;
	 else if(board == 1)matrix = patternMatrix1;
	 else if(board == 2)matrix = patternMatrix2;
	 else if(board == 3)matrix = patternMatrix3;
	 //[matrix setToolTip:[tube objectForKeyIndex:kLabel] forCell:[matrix cellWithTag:chan]];
	 } 
	 }
	 */
}

- (void) distributionPatternChanged:(NSNotification*)aNotification
{
    [self setEnabledStates];
    [self updateButtons];    
}

- (void) setEnabledinMatrix:(NSMatrix*)aMatrix usingMask:(uint32_t)aMask
{
    short bit;
    for(bit=0;bit< [aMatrix numberOfColumns];bit++){
        [[aMatrix cellWithTag:bit] setEnabled:(aMask&(1L<<bit)) > 0L];
    }
}

- (void) patternChanged:(NSNotification*)aNotification
{
    NSArray* patternMatrixArray = [self patternMatrixArray];
    id patternMatrixObj;
    NSEnumerator* e = [patternMatrixArray objectEnumerator];
    int i=0;
    while(patternMatrixObj = [e nextObject]){
        uint32_t patternMask = (uint32_t)[[patternArray objectAtIndex:i] longValue];
        short bit;
        for(bit=0;bit< [patternMatrixObj numberOfColumns];bit++){
            [[patternMatrixObj cellWithTag:bit] setState:(patternMask&(1L<<bit)) > 0L];
        }
        ++i;
    }    
}

- (BOOL) okToRun
{
    return [self numberEnabledChannels] > 0;
}

#pragma mark ¥¥¥Actions
- (IBAction) setAllAction:(id)sender
{
    [self setAllEnabled:patternMatrix0 to:NSOnState];
    [self setAllEnabled:patternMatrix1 to:NSOnState];
    [self setAllEnabled:patternMatrix2 to:NSOnState];
    [self setAllEnabled:patternMatrix3 to:NSOnState];
    [self updateButtons];    
}


- (IBAction) clrAllAction:(id)sender
{
    [self setAllEnabled:patternMatrix0 to:NSOffState];
    [self setAllEnabled:patternMatrix1 to:NSOffState];
    [self setAllEnabled:patternMatrix2 to:NSOffState];
    [self setAllEnabled:patternMatrix3 to:NSOffState];
}

- (void) setAllEnabled:(NSMatrix*)sender to:(BOOL)state
{
    uint32_t aMask = 0; 
    if(state){
        int bit;
        for(bit=0;bit< [sender numberOfColumns];bit++){
            if([[sender cellWithTag:bit] isEnabled]){
                aMask |= (1L<<bit);
            }
        }
    }
    [self setPatternMaskForArray:(int)[sender tag] to:aMask];
}

- (IBAction) timeAction:(id)sender
{
    [self setTimeOnOneChannel:[sender intValue]];
}

- (IBAction) patternAction:(id)sender
{
    uint32_t aMask = 0; 
    int bit;
    for(bit=0;bit< [sender numberOfColumns];bit++){
        if([[sender cellWithTag:bit] state]){
            aMask |= (1L<<bit);
        }
    }
    [self setPatternMaskForArray:(int)[sender tag] to:aMask];
    [self updateButtons];    
}

- (IBAction) reloadPDS:(id)sender
{
    [self setReloadPDS:[sender state]];
}
- (IBAction) ignorePDS:(id)sender
{
    [self setIgnorePDS:[sender state]];
}


- (void) loadMaskForChannelIndex:(int) index
{
	
    int count = 0;
    //find the bit to set
    id patternObj;
    NSEnumerator* e = [patternArray objectEnumerator];
    BOOL done = NO;
    NSMutableArray* workingArray = [NSMutableArray array];
    int i;
    //init an array of bits to zero.
    for(i=0;i<[patternArray count];i++){
        [workingArray addObject:[NSNumber numberWithLong:0L]];
    }
    
    //the following will set ONE bit in the array
    int totalChanCount = 0;
    while(patternObj = [e nextObject]){
        short bit;
        for(bit=0;bit< 16;bit++){
            if([patternObj longValue] & (1<<bit)){
                if(count == index){
                    done = YES;
                    [workingArray replaceObjectAtIndex:totalChanCount/16  withObject:[NSNumber numberWithLong:1<<bit]];
                    break;
                }
                ++count;
			}
			++totalChanCount;
        }
        if(done)break;
    }
    //load the mask to hardware...
    NSArray* thePDSObjs = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORPulserDistribModel")];
    if([thePDSObjs count]){
        ORPulserDistribModel* aPulserModel = [thePDSObjs objectAtIndex:0];
        [aPulserModel loadHardware:workingArray];
    }
}

- (NSArray*) patternMatrixArray
{
    return [NSArray arrayWithObjects:patternMatrix0,patternMatrix1,patternMatrix2,patternMatrix3,nil];
}

- (void) enableGUI:(BOOL)state
{
    if(!state){
        NSArray* patternMatrixArray = [self patternMatrixArray];
        id patternMatrixObj;
        NSEnumerator* e = [patternMatrixArray objectEnumerator];
        while(patternMatrixObj = [e nextObject]){
            [patternMatrixObj setEnabled:NO];
        }
    }
    else {
        [self setEnabledStates];
    }
}

- (void) setEnabledStates
{
    NSArray* thePDSObjs = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORPulserDistribModel")];
    if(ignorePDS){
        [self setEnabledinMatrix: patternMatrix0 usingMask:0xffffffff];
        [self setEnabledinMatrix: patternMatrix1 usingMask:0xffffffff];
        [self setEnabledinMatrix: patternMatrix2 usingMask:0xffffffff];
        [self setEnabledinMatrix: patternMatrix3 usingMask:0xffffffff];
    }
    else {
        if([thePDSObjs count]){
            ORPulserDistribModel* aPulserModel = [thePDSObjs objectAtIndex:0];
            [self setEnabledinMatrix: patternMatrix0 usingMask:[aPulserModel patternMaskForArray:0]];
            [self setEnabledinMatrix: patternMatrix1 usingMask:[aPulserModel patternMaskForArray:1]];
            [self setEnabledinMatrix: patternMatrix2 usingMask:[aPulserModel patternMaskForArray:2]];
            [self setEnabledinMatrix: patternMatrix3 usingMask:[aPulserModel patternMaskForArray:3]];
        }
        else {
            [self setEnabledinMatrix: patternMatrix0 usingMask:0L];
            [self setEnabledinMatrix: patternMatrix1 usingMask:0L];
            [self setEnabledinMatrix: patternMatrix2 usingMask:0L];
            [self setEnabledinMatrix: patternMatrix3 usingMask:0L];
        }
    }
}

- (void) stopTask
{
    [super stopTask];
    if(reloadPDS){
        NSArray* thePDSObjs = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORPulserDistribModel")];
        if([thePDSObjs count]){
            ORPulserDistribModel* aPulserModel = [thePDSObjs objectAtIndex:0];
            [aPulserModel loadHardware:[aPulserModel patternArray]];
        }
    }
}

#pragma mark ¥¥¥Archival
static NSString* NcdPDSStepTaskPatternArray   = @"NcdPDSStepTaskPatternArray";
static NSString* NcdPDSStepTaskReloadPDS      = @"NcdPDSStepTaskReloadPDS";
static NSString* NcdPDSStepTaskIgnorePDS      = @"NcdPDSStepTaskIgnorePDS";
static NSString* NcdPDSStepTaskTime  = @"NcdPDSStepTaskTime";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
  
#if !defined(MAC_OS_X_VERSION_10_9)
    [NSBundle loadNibNamed:@"NcdPDSStepTask" owner:self];
#else
    [[NSBundle mainBundle] loadNibNamed:@"NcdPDSStepTask" owner:self topLevelObjects:&pdsStepTaskObjects];
#endif
    
    [pdsStepTaskObjects retain];

    
    [self loadMemento:decoder];
    
    [self registerNotificationObservers];
    [self updateView];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [self saveMemento:encoder];
}

- (void)loadMemento:(NSCoder*)decoder
{
    [super loadMemento:decoder];
    [[self undoManager] disableUndoRegistration];
    
    [self setPatternArray:[decoder decodeObjectForKey:NcdPDSStepTaskPatternArray]];
    [self setReloadPDS:[decoder decodeBoolForKey:NcdPDSStepTaskReloadPDS]];
    [self setIgnorePDS:[decoder decodeBoolForKey:NcdPDSStepTaskIgnorePDS]];
    int aTime = [decoder decodeIntForKey:NcdPDSStepTaskTime];
    if(aTime==0)aTime=30;
    [self setTimeOnOneChannel:aTime];
    [[self undoManager] enableUndoRegistration];    
}

- (void)saveMemento:(NSCoder*)encoder
{
    [super saveMemento:encoder];
    [encoder encodeObject:patternArray forKey:NcdPDSStepTaskPatternArray];
    [encoder encodeBool:reloadPDS forKey:NcdPDSStepTaskReloadPDS];
    [encoder encodeBool:ignorePDS forKey:NcdPDSStepTaskIgnorePDS];
    [encoder encodeInteger:timeOnOneChannel forKey:NcdPDSStepTaskTime];
}

#pragma mark ¥¥¥Task Methods
- (void) prepare
{
    [super prepare];
    workingChannelIndex = 0;
    lastTime = [[NSDate date] retain];
    NSArray* objects = [[(ORAppDelegate*)[NSApp delegate]  document] collectObjectsOfClass:NSClassFromString(@"ORPulserDistribModel")];
    if([objects count]){
        thePDSModel = [objects objectAtIndex:0];
        //tbd.. put in a locking mechanism for running tasks
        totalChannels = [self numberEnabledChannels];
    }
}

- (BOOL)  doWork
{
    [[self undoManager] disableUndoRegistration];
    BOOL isThereMoreToDo = [self _doWork];
    [[self undoManager] enableUndoRegistration];
    return isThereMoreToDo;
}

- (BOOL)  _doWork
{
    if(!thePDSModel){
        NSLogColor([NSColor redColor],@"NCD PDS Step Task: No PDS object in config, so nothing to do!\n");
        NSLogColor([NSColor redColor],@"NCD PDS Step Task: Start of <%@> aborted!\n",[self title]);
        [self hardHaltTask];
        return NO; //can not run if no pds object in config
    }
    if(!totalChannels){
        NSLogColor([NSColor redColor],@"NCD PDS Step Task: No Channels selected, so nothing to do!\n");
        NSLogColor([NSColor redColor],@"NCD PDS Step Task: Start of <%@> aborted!\n",[self title]);
        [self hardHaltTask];
        return NO; //can not run if no pds object in config
    }
    NSDate* now = [NSDate date];
    if([now timeIntervalSinceDate:lastTime] >= [self timeOnOneChannel] || workingChannelIndex == 0){
        [lastTime release];
        lastTime = [now retain];
        
        if(workingChannelIndex>=totalChannels){
            workingChannelIndex = 0;
            [self setMessage:@"finished"];
            return NO; //return NO when done
        }
        else {
            [self setMessage:[NSString stringWithFormat:@"Working on: %d/%d",workingChannelIndex+1, totalChannels]];
            @try {
                [self loadMaskForChannelIndex:workingChannelIndex];
            }
			@catch(NSException* localException) {
                NSLog(@"\n");
                NSLogColor([NSColor redColor],@"NCD PDS Step Task: Exception thrown! %@\n",localException);
                NSLogColor([NSColor redColor],@"NCD PDS Step Task: Calibration Task skipped chan %d!\n",workingChannelIndex);
                //abort = YES;
            }
            workingChannelIndex++;
            [[NSNotificationCenter defaultCenter] postNotificationName:ORTaskDidStepNotification object:self];
            return YES;
        }
    }
    else return YES;
}

- (void) cleanUp
{
    [self setMessage:@""];
    [lastTime release];
    lastTime = nil;
    workingChannelIndex = 0;
    thePDSModel = nil;
    [self setMessage:@"Idle"];
	
}


@end
