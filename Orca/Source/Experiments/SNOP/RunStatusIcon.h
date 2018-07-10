//
//  RunStatusIcon.h
//  Orca
//
//  Created by Eric Marzec on 12/6/16.
//
//  This class acts as a controller for a menu bar icon.
//  Currently the icon is an image of a dog, which can be animated
//  to appear running.
//  This was inspired by SHARC's much beloved running dog.
//  Hopefully this class can be expanded to other species (maybe a swimming orca?)
//
//

#import <Foundation/Foundation.h>

@interface RunStatusIcon : NSObject {
    // Doggy
    NSStatusItem *statusIcon;
    NSTimer* animate_timer;
    int current_dog_frame;
    int n_frames;
    BOOL isRunning;
    
}
- (void) start_animation;
- (void) stop_animation;
- (void) animate_icon;

@end
