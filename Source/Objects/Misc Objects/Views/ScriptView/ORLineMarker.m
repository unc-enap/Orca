
#import "ORLineMarker.h"

#define CORNER_RADIUS	3.0
#define MARKER_HEIGHT	13.0

@implementation ORLineMarker

- (id) initWithRulerView:(NSRulerView *)aRulerView lineNumber:(float)line image:(NSImage *)anImage imageOrigin:(NSPoint)imageOrigin
{
	if ((self = [super initWithRulerView:aRulerView markerLocation:0.0 image:anImage imageOrigin:imageOrigin]) != nil) {
		lineNumber = line;
	}
	return self;
}

- (void) setLineNumber:(NSUInteger)line
{
	lineNumber = line;
}

- (NSUInteger) lineNumber
{
	return lineNumber;
}

#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    lineNumber = [[decoder decodeObjectForKey:@"line"] unsignedIntValue];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];	
    [encoder encodeObject:[NSNumber numberWithInteger:lineNumber] forKey:@"line"];
}


#pragma mark NSCopying methods
- (id)copyWithZone:(NSZone *)zone
{	
	id copy = [super copyWithZone:zone];
	[copy setLineNumber:lineNumber];
	return copy;
}


@end
