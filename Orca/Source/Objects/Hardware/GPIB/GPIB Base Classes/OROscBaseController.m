//
//  OROscBaseController.m
//  Orca
//
//  Created by Jan Wouters on Wed Feb 19 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//

#import "OROscBaseController.h"
#import "OROscBaseModel.h"


@implementation OROscBaseController

#pragma mark ***Initialization
- (id) initWithWindowNibName: (NSString*) aNibName
{
    self = [ super initWithWindowNibName: aNibName ];
    return self;
}


- (void) dealloc
{
    [ super dealloc ];
}


- (void) awakeFromNib
{
    [ super awakeFromNib ];
}

#pragma mark ***Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];
    
    [ notifyCenter addObserver: self
                      selector: @selector( oscChnlAcquireChanged: )
                          name: OROscAcqChnlChangedNotification
                        object: [[ self model ] document ]];
}

#pragma mark ***Interface Management
- (void) updateWindow
{
    [ self oscChnlAcquireChanged: nil ];
}
                        
- (void) oscChnlAcquireChanged: (NSNotification*) aNotification
{
    short 		i;
    
    for ( i = 0; i < kMaxOscChnls; i++ )
    {
        [[ mChnlAcquire cellAtRow: i column: 0 ] setIntValue: [[ self model ] chnlAcquire: i ]];
    }
}


#pragma mark ***Commands
- (IBAction) loadOscFromDialog: (id) aSender
{
    short 		i;
    
    for ( i = 0; i < kMaxOscChnls; i++ )
    {
        [[ self model ] setChnlAcquire: i setting: [[ mChnlAcquire cellAtRow: i column: 0 ] intValue ]];
    }
}

@end
