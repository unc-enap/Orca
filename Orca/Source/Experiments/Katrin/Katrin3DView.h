//
//  Katrin3DView.h
//  Orca
//
//  Created by Mark Howe on 6/3/13.
//
//

#import "ORBasicOpenGLView.h"
@class ORColorScale;

@interface Katrin3DView : ORBasicOpenGLView
{
    IBOutlet ORColorScale* focalPlaneColorScale;
}

- (void) draw3D:(NSRect)aRect;
- (void) drawPixelR1:(GLfloat)r1
                  r2:(GLfloat)r2
          startAngle:(float)startAngle
          deltaAngle:(float)deltaAngle
                   z:(GLfloat) z
               color:(NSColor*)color;


@end
