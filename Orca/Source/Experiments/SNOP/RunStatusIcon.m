//
//  RunStatusIcon.m
//  Orca
//
//  Created by Eric Marzec on 12/6/16.
//
//

#import "RunStatusIcon.h"

@implementation RunStatusIcon

- (id) init
{
    self = [super init];
    current_dog_frame=0;
    n_frames = 7;
    isRunning = NO;
    statusIcon = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];

    [statusIcon setImage:[NSImage imageNamed:@"waiting_dog.tiff"]];
    [statusIcon setHighlightMode:NO];
    [statusIcon setEnabled:NO];
    [statusIcon setTarget:self];

    animate_timer = nil;

    return self;
}

- (void) dealloc
{
    [statusIcon release];
    [super dealloc];
}

- (void) start_animation
{
    if([statusIcon image])
    {
        //Timer doggy
        if (!animate_timer) {
            animate_timer = [NSTimer scheduledTimerWithTimeInterval:1.0/20.0 target:self selector:@selector(animate_icon) userInfo:nil repeats:YES];
        }
        isRunning =true;
        [statusIcon setEnabled:YES];

    }
}

- (void) stop_animation
{
    if(isRunning)
    {
        [animate_timer invalidate];
        animate_timer = nil;
        isRunning = NO;
        [statusIcon setImage:[NSImage imageNamed:@"waiting_dog.tiff"]];
        [statusIcon setEnabled:NO];

    }
}

- (void) animate_icon
{
    [statusIcon setImage:[NSImage imageNamed:[NSString stringWithFormat:@"run_dog_frame_%i.tiff",current_dog_frame]]];
    current_dog_frame++;
    if(current_dog_frame % n_frames == 0)//There's 7 frames
    {
        current_dog_frame = 0;
    }
    
}

@end
