//
//  ORPlotSubview.h
//  Orca
//
//  Created by Mark Howe on Mon Nov 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ORSubPlotController;

@interface ORPlotSubview : NSView {
    @private
        IBOutlet ORSubPlotController*    owner;
}

@end
