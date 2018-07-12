
#import <Cocoa/Cocoa.h>

@interface ORLineMarker : NSRulerMarker
{
	NSUInteger		lineNumber;
}

- (id) initWithRulerView:(NSRulerView *)aRulerView lineNumber:(float)line image:(NSImage *)anImage imageOrigin:(NSPoint)imageOrigin;
- (void) setLineNumber:(NSUInteger)line;
- (NSUInteger) lineNumber;

@end
