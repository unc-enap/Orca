//
//  Katrin3DView.m
//  Orca
//
//  Created by Mark Howe on 6/3/13.
//
//

#import "Katrin3DView.h"
#import "KatrinConstants.h"
#import "ORSegmentGroup.h"
#import "ORDetectorView.h"
#import "ORColorScale.h"
#import "ORExperimentModel.h"

@implementation Katrin3DView
- (void) draw3D:(NSRect)aRect;
{
    
    glRotatef(180, 0.0f, 1.0f, 0.0f);/* orbit the Y axis */
    glRotatef(-50, 1.0f, 0.0f, 0.0f);/* orbit the Y axis */

    glClearColor(0.9f, 0.9f, 0.9f, 0.0f);
    
    //=========the Focal Plane Part=============
	float r = .3;	//radius of the center focalPlaneSegment NOTE: sets the scale of the whole thing
	float pi = 3.14159;
	float area = 2*pi*r*r;		//area of the center focalPlaneSegment
    int displaySegment = 0;
	area /= 4.;
    
	
	float startAngle;
	float deltaAngle;
	int j;
	r = 0;
    int segmentIndex = 0;
    ORSegmentGroup* segmentGroup = [delegate segmentGroup:displaySegment];
    int displayType = [delegate displayType];
	for(j=0;j<kNumRings;j++){
		
		int i;
		int numSeqPerRings;
		if(j==0){
			numSeqPerRings = 4;
			startAngle = 0.;
		}
		else {
			numSeqPerRings = kNumSegmentsPerRing;
			if(kStaggeredSegments){
				if(!(j%2))startAngle = 0;
				else startAngle = -360./(float)numSeqPerRings/2.;
			}
			else startAngle = 0;
		}
		deltaAngle = 360./(float)numSeqPerRings;
		//calculate the next radius, where the area of each 1/12 of the ring is equal to the center area.
		float r2 = sqrtf(numSeqPerRings*area/(pi*2) + r*r);
		for(i=0;i<numSeqPerRings;i++){
            //get the value of the segment
            //-----
            float displayValue = 0;
           NSColor* pixelColor = [NSColor whiteColor];
 			if([segmentGroup hwPresent:segmentIndex]){
				if([segmentGroup online:segmentIndex]){
					switch(displayType){
						case kDisplayThresholds:	displayValue = [segmentGroup getThreshold:segmentIndex];	break;
						case kDisplayGains:			displayValue = [segmentGroup getGain:segmentIndex];			break;
						case kDisplayTotalCounts:	displayValue = [segmentGroup getTotalCounts:segmentIndex];	break;
						default:					displayValue = [segmentGroup getRate:segmentIndex];			break;
					}
                    pixelColor = [focalPlaneColorScale getColorForValue:displayValue];
				}
			}
			else pixelColor = [NSColor lightGrayColor];
            //-----
            float maxValue = [[focalPlaneColorScale colorAxis] maxValue];
            displayValue = MIN(displayValue,maxValue);
            float scaledValue = MAX(.03,1.*displayValue/maxValue);
            
			[self drawPixelR1: r
                           r2: r2
                   startAngle: startAngle
                   deltaAngle: deltaAngle
                            z: scaledValue
                        color: pixelColor];
            segmentIndex++;
			
			startAngle += deltaAngle;
		}
		
		r = r2;
	}
	r += .2;
	glLineWidth(.1);
	glColor3f (.8, .8, .8);
    float h=0;
    glBegin (GL_LINES);
    
    glVertex3f(-r, -r, h);
    glVertex3f(-r, r, h);
    
    glVertex3f(-r, r, h);
    glVertex3f(r, r, h);
    
    glVertex3f(r, r, h);
    glVertex3f(r, -r, h);
    
    glVertex3f(r, -r, h);
    glVertex3f(-r, -r, h);
    
    
    glVertex3f(-r, 0, h);
    glVertex3f(r, 0, h);
    
    glVertex3f(0, -r, h);
    glVertex3f(0, r, h);
    
    glEnd();
    
}
- (void) drawPixelR1:(GLfloat)r1
                  r2:(GLfloat)r2
          startAngle:(float)startAngle
          deltaAngle:(float)deltaAngle
                   z:(GLfloat) z
               color: (NSColor*)color
{
#define kNumPoints 80
    CGFloat endRed;
    CGFloat endGreen;
    CGFloat endBlue;
    CGFloat alpha;
    NSColor* convertedColor = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    [convertedColor getRed:&endRed green:&endGreen blue:&endBlue alpha:&alpha];

	CGFloat startRed   = endRed/5.;
	CGFloat startGreen = endGreen/5.;
	CGFloat startBlue  = endBlue/5.;
	GLfloat xInner[kNumPoints];
	GLfloat yInner[kNumPoints];
	GLfloat xOuter[kNumPoints];
	GLfloat yOuter[kNumPoints];
   
	float endAngle = startAngle + deltaAngle;
	float delta = (endAngle-startAngle)/(float)(kNumPoints-1);
	int i;
	for(i=0;i<kNumPoints;i++){
		xInner[i] = r1*cos((startAngle+(delta*i))*3.14159/180.);
		yInner[i] = r1*sin((startAngle+(delta*i))*3.14159/180.);
	}
    
	delta = (endAngle-startAngle)/(float)(kNumPoints-1);
	for(i=0;i<kNumPoints;i++){
		xOuter[i] = r2*cos((startAngle+(delta*i))*3.14159/180.);
		yOuter[i] = r2*sin((startAngle+(delta*i))*3.14159/180.);
	}
    
	//draw the top
	glBegin (GL_TRIANGLE_STRIP);
	glColor3f (endRed, endGreen, endBlue);
	for(i=0;i<kNumPoints;i++){
		glVertex3f(xInner[i], yInner[i], z);
		glVertex3f(xOuter[i], yOuter[i], z);
	}
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], z);
	glEnd();
    
	//draw the bottom
	glBegin (GL_TRIANGLE_STRIP);
	glColor3f (endRed, endGreen, endBlue);
	for(i=kNumPoints-1;i>=0;i--){
		glVertex3f(xInner[i], yInner[i], 0);
		glVertex3f(xOuter[i], yOuter[i], 0);
	}
	glEnd();
    
	
	//draw the start angle side
	glBegin(GL_QUADS);
	glColor3f (endRed, endGreen, endBlue);
	glVertex3f(xOuter[0], yOuter[0], z); //top
	glVertex3f(xInner[0], yInner[0], z); //top
	glColor3f (startRed, startGreen, startBlue);
	glVertex3f(xInner[0], yInner[0], 0); //bott
	glVertex3f(xOuter[0], yOuter[0], 0); //bott
	glEnd();
	
	//draw the end angle side
	glBegin(GL_QUADS);
	glColor3f (endRed, endGreen, endBlue);
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], z); //top
	glVertex3f(xOuter[kNumPoints-1], yOuter[kNumPoints-1], z); //top
	glColor3f (startRed, startGreen, startBlue);
	glVertex3f(xOuter[kNumPoints-1], yOuter[kNumPoints-1], 0); //bott
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], 0); //bott
	glEnd();
    
	//inside surface
	glBegin (GL_QUAD_STRIP);
	for(i=0;i<kNumPoints;i++){
		glColor3f (startRed, startGreen, startBlue);
		glVertex3f(xInner[i], yInner[i], 0);
		glColor3f (endRed, endGreen, endBlue);
		glVertex3f(xInner[i], yInner[i], z);
	}
	glEnd();
	
	//outside surface
	glBegin (GL_QUAD_STRIP);
	for(i=0;i<kNumPoints;i++){
		glColor3f (endRed, endGreen, endBlue);
		glVertex3f(xOuter[i], yOuter[i], z);
		glColor3f (startRed, startGreen, startBlue);
		glVertex3f(xOuter[i], yOuter[i], 0);
	}
	glEnd();
	
	//lines
	glEnable (GL_LINE_SMOOTH);
	//glEnable (GL_BLEND);
    //glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glHint (GL_LINE_SMOOTH_HINT, GL_NICEST);
	glLineWidth(1.1);
	//top
	glColor3f (0.5, 0.5, 0.5);
	glBegin (GL_LINES);
	glVertex3f(xInner[0], yInner[0], z);
	glVertex3f(xOuter[0], yOuter[0], z);
	for(i=0;i<kNumPoints-1;i++){
		glVertex3f(xOuter[i], yOuter[i], z);
		glVertex3f(xOuter[i+1], yOuter[i+1], z);
	}
	glVertex3f(xOuter[kNumPoints-1], yOuter[kNumPoints-1], z);
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], z);
	for(i=kNumPoints-1;i>0;i--){
		glVertex3f(xInner[i], yInner[i], z);
		glVertex3f(xInner[i-1], yInner[i-1], z);
	}
	glEnd();
	
	glBegin (GL_LINES);
	glVertex3f(xInner[0], yInner[0], 0);
	glVertex3f(xOuter[0], yOuter[0], 0);
	for(i=0;i<kNumPoints-1;i++){
		glVertex3f(xOuter[i], yOuter[i], 0);
		glVertex3f(xOuter[i+1], yOuter[i+1], 0);
	}
	glVertex3f(xOuter[kNumPoints-1], yOuter[kNumPoints-1], 0);
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], 0);
	for(i=kNumPoints-1;i>0;i--){
		glVertex3f(xInner[i], yInner[i], 0);
		glVertex3f(xInner[i-1], yInner[i-1], 0);
	}
	glEnd();
	
	//draw the start angle side
	glBegin(GL_LINES);
	glVertex3f(xOuter[0], yOuter[0], z); //top
	glVertex3f(xOuter[0], yOuter[0], 0); //bott
	glVertex3f(xInner[0], yInner[0], z); //top
	glVertex3f(xInner[0], yInner[0], 0); //bott
	glEnd();
	
	//draw the start angle side
	glBegin(GL_LINES);
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], z); //top
	glVertex3f(xInner[kNumPoints-1], yInner[kNumPoints-1], 0); //bott
	glVertex3f(xOuter[kNumPoints-1], yOuter[kNumPoints-1], z); //top
	glVertex3f(xOuter[kNumPoints-1], yOuter[kNumPoints-1], 0); //bott
	glEnd();
	
}
@end
