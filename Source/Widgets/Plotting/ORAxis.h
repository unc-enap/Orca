//
//  ORAxis.h
//  Orca
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
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

#define		kMaxLongTicks	100

int32_t roundToLong(double x);

@interface ORAxis : NSView <NSCoding>
{
	IBOutlet NSView*	    viewToScale;
    BOOL                    ownViewToScale;
	int						gridCount;
	float					gridArray[kMaxLongTicks];	// array for storing int32_t tick locations
	int						lowOffset;					// pixel position of scale start
	int						highOffset;					// pixel position of scale end
	NSMutableDictionary*    attributes;
	NSMutableDictionary*    labelAttributes;
	id      preferenceController;
	double  fscl;			// scaling factor
	double  pinVal;			// scale value at pin point
	double  pinPix;			// pixel position of pointpoint during grab
	int		dpos;			// highOffset - lowOffset
	BOOL	xaxis;			// flag for x scale (1=x, 0=y)
	BOOL	pinned;			// flag for scale pinned
	BOOL	invertPin;		// flag to invert the sense of pinned flag
	int		nearPinFlag;	// -1/0/1 = below/at/above pin point for cursor
	BOOL	dragFlag;		// flag pressed if option is down during drag
	BOOL	saveRng;
	double  mGrabValue;
	BOOL	mDragInProgress;
    NSNumber* markerBeingDragged;
	BOOL    firstDrag;
	
	//cache some variables that are heavily used in tight loops.
	BOOL   isMinPadCached;
	BOOL   isLogCached;
	BOOL   isIntegerCached;
	double cachedMinPad;
	BOOL   cachedIsLog;
	BOOL   cachedInteger;
}

- (id) initWithFrame:(NSRect)aFrame;
- (void) awakeFromNib;
- (void) drawGridInFrame:(NSRect)aFrame usingColor:(NSColor*)aColor;
- (void) drawMarker:(float)val axisPosition:(int)axisPosition;
- (void) drawMarkInFrame:(NSRect)aFrame usingColor:(NSColor*)aColor;
- (void) drawMark:(NSNumber*)markerNumber inFrame:(NSRect)aFram usingColor:(NSColor*)aColor;
- (void) drawTitle;

- (void) dealloc;
- (void) setPreferenceController:(id)aController;
- (void) setDefaults;
- (void) drawRect:(NSRect)rect;
- (void) markClick:(NSPoint)mouseLoc;
- (void) mouseDown:(NSEvent*)theEvent;
- (void) mouseDragged:(NSEvent*)theEvent;
- (void) mouseUp:(NSEvent*)theEvent;
- (BOOL) ignoreMouse;
- (void) setIgnoreMouse:(BOOL) ignore;
- (void) setAllowShifts:(BOOL) allow;
- (BOOL) allowShifts;
- (void) setAllowNegativeValues:(BOOL) allow;
- (BOOL) allowNegativeValues;
- (BOOL) oppositePosition;
- (void) setOppositePosition:(BOOL)state;
- (id)   calibration;
- (BOOL) isXAxis;
- (BOOL) checkRngLow:(double *)low withHigh:(double *)high;
- (BOOL) setRngLow:(double)low withHigh:(double) high;
- (int) setDefaultRng;
- (int) setFullRng;
- (float) lowOffset;
- (float) highOffset;
- (NSFont*) textFont;
- (void) setTextFont:(NSFont*) font;
- (NSColor*) color;
- (void) setColor:(NSColor*)aColor;
- (void) saveRng;
- (int) restoreRng;
- (int) setOrigin:(double) low;
- (int) shiftOrigin:(double) delta;
- (void)  setRngLimitsLow:(double)low withHigh:(double) high withMinRng:(double) min_rng;
- (void) setRngDefaultsLow:(double)aLow withHigh:(double)aHigh;
- (void) setLog:(BOOL)isLog;
- (BOOL) log;
- (BOOL) isLog;
- (double) padding;
- (void) setPadding:(double) p;
- (void) setPin:(double) p;
- (void) clearPin;
- (BOOL) integer;
- (void) setInteger:(BOOL) isInt;
- (double) optimalLabelSeparation;
- (void) setMinValue:(double)aValue;
- (double) minValue;
- (double) maxValue;
- (void) setMaxValue:(double)aValue;
- (void) setMinLimit:(double)aValue;
- (double) minLimit;
- (double) maxLimit;
- (void) setMaxLimit:(double)aValue;
- (double) defaultRangeLow;
- (void) setDefaultRangeLow:(double)aValue;
- (double) defaultRangeHigh;
- (void) setDefaultRangeHigh:(double)aValue;
- (void)setMinimumRange:(double)aValue;
- (double) minimumRange;
- (double) valueRange;
- (double) minPad;
- (void) setMinPad:(double)aValue;
- (double) maxPad;
- (void) setMaxPad:(double)aValue;
- (void) setTempLabel:(NSString*)aString;
- (void) setLabel:(NSString*)aString;
- (NSString*) label;
- (NSString*) units;
- (void) setViewToScale:(id)aView;
- (double) minSave;
- (void) setMinSave:(double)aValue;
- (double) maxSave;
- (void) setMaxSave:(double)aValue;
- (void) checkForCalibrationAdjustment;

- (float) getPixAbsFast:(double)val log:(BOOL)aLog integer:(BOOL)aInt minPad:(double)aMinPad;
- (NSData*) getManyPixAbsFast:(double*)val count:(NSUInteger)length log:(BOOL)aLog integer:(BOOL)aInt minPad:(double)aMinPad;
- (float) getPixAbs:(double) val;		// convert absolute value to pixel position
- (float) getPixRel:(double) val;		// convert relative value to pixel position

- (double) getValAbs:(int) pix;		// convert from pixel disp. to absolute value
- (double) getValRel:(int) pix;		// convert from pixel disp. to relative value
- (void)  saveRngOnChange;		// save current range if next setRngLow() changes it
- (double)convertPoint:(double)pix;

- (void) setAttributes:(NSMutableDictionary*)someAttributes;
- (NSMutableDictionary*) attributes;
- (NSMutableDictionary*) labelAttributes;
- (void) setLabelAttributes:(NSMutableDictionary*)someAttributes;

- (id)	 initWithCoder:(NSCoder*)coder;
- (void) encodeWithCoder:(NSCoder*)coder;
- (BOOL) dragInProgress;
- (void)  rangingDonePostChange;				// end drag procedure

- (int32_t) axisMinLimit;
- (void) setAxisMinLimit:(int32_t)aValue;
- (int32_t) axisMaxLimit;
- (void) setAxisMaxLimit:(int32_t)aValue;
- (NSString*) markerLabel:(NSNumber*)markerNumber;

- (IBAction) setLogScale:(id)sender;
- (IBAction) shiftLeft:(id)sender;
- (IBAction) shiftRight:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;
@end

@interface NSView (dataSource)
- (id) dataSource;
- (id) model;
@end

//attributes
extern NSString* ORAxisMinValue;
extern NSString* ORAxisMaxValue;
extern NSString* ORAxisMinLimit;
extern NSString* ORAxisMaxLimit;
extern NSString* ORAxisUseLog;
extern NSString* ORAxisColor;
extern NSString* ORAxisDefaultRangeHigh;
extern NSString* ORAxisDefaultRangeLow;
extern NSString* ORAxisInteger;
extern NSString* ORAxisIgnoreMouse;
extern NSString* ORAxisMinimumRange;
extern NSString* ORAxisMinPad;
extern NSString* ORAxisMaxPad;
extern NSString* ORAxisPadding;
extern NSString* ORAxisMinSave;
extern NSString* ORAxisMaxSave;
extern NSString* ORAxisLabel;
extern NSString* ORAxisTempLabel;
extern NSString* ORAxisMarker;  //old, single marker
extern NSString* ORAxisMarkers; //new, mulitple markers

extern NSString* ORAxisAllowShifts;
extern NSString* ORAxisAllowNegative;
extern NSString* ORAxisFont;
extern NSString* ORAxisIsOpposite;

//notifications
extern NSString* ORAxisRangeChangedNotification;
extern NSString* ORAxisLabelChangedNotification;

