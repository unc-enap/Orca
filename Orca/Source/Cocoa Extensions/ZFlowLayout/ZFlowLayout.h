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


//No spring will let elements stretch to fit width
//
//Left spring will push elements to right side,
//with no stretching
//
//Right spring will push elements to left side,
//with no stretching.

typedef enum _ZFlowLayoutSpring {
    ZNoSpring = 0,
    ZSpringLeft = 1,
    ZSpringRight = 2,
    ZSpringLeftRight = 3,
} ZFlowLayoutSpring;

typedef struct _ZFlowLayoutSizing {
    NSSize minSize;
    int padding;
    int spring; 
    bool oneColumn;
} ZFlowLayoutSizing;

ZFlowLayoutSizing ZMakeFlowLayoutSizing( NSSize minSize, int padding,
    int spring, BOOL oneColumn );

/**********************************************************************
ZFlowLayout
**********************************************************************/

@interface ZFlowLayout : NSView
{
    ZFlowLayoutSizing _sizing;
    NSSize _lastSize;
    int _numElements;
    unsigned int _gridMask;
    BOOL _ignoreThisLayoutPass, _alternatingRowColors;
    NSColor *_backgroundColor, *_gridColor;
}

- (void) setSizing: (ZFlowLayoutSizing) sizing;
- (ZFlowLayoutSizing) sizing;

/*
Draw a solid background color
*/
- (void) setBackgroundColor: (NSColor *) color;
- (NSColor *) backgroundColor;

/*
Draw background using system alternating row colors
*/
- (void) setUsesAlternatingRowBackgroundColors:
    (BOOL) useAlternatingRowColors;

- (BOOL) usesAlternatingRowBackgroundColors;

- (void) setGridStyleMask:(unsigned int)gridType;
- (unsigned int) gridStyleMask;

- (void) setGridColor:(NSColor *)aColor;
- (NSColor *) gridColor;

@end

@interface NSView (ZFlowLayout)
- (void) setSizing: (ZFlowLayoutSizing) sizing;
@end
