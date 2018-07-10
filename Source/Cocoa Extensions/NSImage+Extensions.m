/*
	NSImage+Extensions.m
*/
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

@implementation NSImage (OrcaExtensions)
- (NSImage *) rotateIndividualImage: (NSImage *)image angle:(float)anAngle
{
    NSImage *existingImage = image;
    NSSize existingSize;
	NSImageRep* imageRep;
	
	imageRep = [existingImage bestRepresentationForRect:NSMakeRect(0,0,[self size].width,[self size].height) context:nil hints:nil];
	
    existingSize.width = [imageRep pixelsWide];
    existingSize.height = [imageRep pixelsHigh];
    NSSize newSize = NSMakeSize(existingSize.height, existingSize.width);
    NSImage *rotatedImage = [[NSImage alloc] initWithSize:newSize];

    [rotatedImage lockFocus];

    NSAffineTransform *rotateTF = [NSAffineTransform transform];
    NSPoint centerPoint = NSMakePoint(newSize.width / 2, newSize.height / 2);

    [rotateTF translateXBy: centerPoint.x yBy: centerPoint.y];
    [rotateTF rotateByDegrees: anAngle];
    [rotateTF translateXBy: -centerPoint.y yBy: -centerPoint.x];
    [rotateTF concat];

    NSRect r1 = NSMakeRect(0, 0, newSize.height, newSize.width);
	imageRep = [existingImage bestRepresentationForRect:NSMakeRect(0,0,[self size].width,[self size].height) context:nil hints:nil];

    [imageRep drawInRect: r1];

    [rotatedImage unlockFocus];

    return [rotatedImage autorelease];
}

- (NSRect) imageRect
{
    return NSMakeRect(0,0,[self size].width,[self size].height);
}

@end
