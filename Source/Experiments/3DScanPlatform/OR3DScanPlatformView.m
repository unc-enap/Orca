//
//  OR3DScanPlatformModel.m
//  Orca
//
//  Created by Mark Howe on Tue June 4,2013.
//  Copyright ¬© 2013 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.


#import "OR3DScanPlatformView.h"
#import "OR3DScanPlatformController.h"
#import "ORVXMMotor.h"
#import "OROpenGLObject.h"
#include "math.h"

@implementation OR3DScanPlatformView
-(void) dealloc
{
    [zComponent release];
    [angularComponent release];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    NSBundle* mainBundle = [NSBundle mainBundle];
	NSString* zComponentPath = [mainBundle pathForResource: @"ZComponent" ofType: @"obj"];
    NSString* angularComponentPath = [mainBundle pathForResource:@"AngularComponent" ofType:@"obj"];
    
    zComponent = [[OROpenGLObject alloc] initFromFile:zComponentPath];
    angularComponent = [[OROpenGLObject alloc] initFromFile:angularComponentPath];
}

- (void) resetCamera
{
    camera.aperture = 50;
    camera.rotPoint = gOrigin;
    
    camera.viewPos.x = 3;
    camera.viewPos.y = 0;
    camera.viewPos.z = -10;
    camera.viewDir.x = -2.5;
    camera.viewDir.y = -camera.viewPos.y;
    camera.viewDir.z = -camera.viewPos.z;
    
    camera.viewUp.x = 0;
    camera.viewUp.y = 1;
    camera.viewUp.z = 0;
}

- (void) cubeScaleX:(float)sx scaleY:(float)sy scaleZ:(float)sz
         translateX:(float)tx translateY:(float)ty translateZ:(float)tz
         rotateAngle:(float)ra rotateX:(float)rx rotateY:(float)ry rotateZ:(float)rz
{
    glPushMatrix();
    glRotatef(ra,rx,ry,rz);
    glTranslatef(tx,ty,tz);
    glScalef(sx,sy,sz);
        
    GLfloat vertices[8][3] = {{-1,-1,1},{1,-1,1},{1,1,1},{-1,1,1},
        {-1,-1,-1},{1,-1,-1},{1,1,-1},{-1,1,-1}};
    glEnable(GL_RESCALE_NORMAL);
    GLfloat normals[6][3] = {{0,0,1},{0,0,-1},{-1,0,0},{1,0,0},{0,-1,0},{0,1,0}};
    
    GLint link[6][4] = {{0,1,2,3},{4,7,6,5},{4,0,3,7},{5,6,2,1},{4,5,1,0},{7,3,2,6}};
    
	int i;
	for(i=0; i<6; i++)
	{
        glBegin(GL_POLYGON);
            glNormal3f(normals[i][0],normals[i][1],normals[i][2]);
            glVertex3f(vertices[link[i][0]][0],vertices[link[i][0]][1],vertices[link[i][0]][2]);
            glVertex3f(vertices[link[i][1]][0],vertices[link[i][1]][1],vertices[link[i][1]][2]);
            glVertex3f(vertices[link[i][2]][0],vertices[link[i][2]][1],vertices[link[i][2]][2]);
            glVertex3f(vertices[link[i][3]][0],vertices[link[i][3]][1],vertices[link[i][3]][2]);
        glEnd();
	}
    
    glPopMatrix();
}

//result = v1 x v2
- (void) crossProductVector1:(GLfloat*)v1 vector2:(GLfloat*)v2 result:(GLfloat*)result
{
    result[0] = v1[1]*v2[2] - v1[2]*v2[1];
    result[1] = -1*(v1[0]*v2[2] - v1[2]*v2[0]);
    result[2] = v1[0]*v2[1] - v1[1]*v2[0];
}

//vector1 = point1 to point2, vector2 = point1 to point3, vector1 x vector2 (make sure point order is right)
- (void) unitNormalPoint1:(GLfloat*)p1 point2:(GLfloat*)p2 point3:(GLfloat*)p3 result:(GLfloat*)result
{
    GLfloat v1[3] = {p2[0]-p1[0], p2[1]-p1[1], p2[2]-p1[2]};
    GLfloat v2[3] = {p3[0]-p1[0], p3[1]-p1[1], p3[2]-p1[2]};
    [self crossProductVector1:v1 vector2:v2 result:result];
    double magnitude = sqrtf(result[0]*result[0]+result[1]*result[1]+result[2]*result[2]);
    result[0] /= magnitude;
    result[1] /= magnitude;
    result[2] /= magnitude;
}

- (void) partialConeInnerRadiusLower:(float)irLower outerRadiusLower:(float)orLower 
                    innerRadiusUpper:(float)irUpper outerRadiusUpper:(float)orUpper height:(float)height
                          translateX:(float)tx translateY:(float)ty translateZ:(float)tz
{
    glPushMatrix();
    //glRotatef(ra,rx,ry,rz);
    glTranslatef(tx,ty,tz);
    //glScalef(sx,sy,sz);
    
	const GLint NUMVERTS = 50;
	GLfloat outerCircleLower[NUMVERTS][2], innerCircleLower[NUMVERTS][2], 
        outerCircleUpper[NUMVERTS][2], innerCircleUpper[NUMVERTS][2]; //x and z coordinates
	GLdouble y1 = -height/2, y2 = height/2;
    
    glEnable(GL_RESCALE_NORMAL);
    
    const GLdouble PI = 3.14159265359;
    
	GLdouble theta = 0;
    int i;
	for(i=0; i<NUMVERTS; i++)
	{
		outerCircleLower[i][0] = orLower*cosf(theta);
		outerCircleLower[i][1] = orLower*sinf(theta);
		theta += (2*PI) / (NUMVERTS-1); //necessary so that both end points are included
	}
    
	theta = 0;
	for(i=0; i<NUMVERTS; i++)
	{
		innerCircleLower[i][0] = irLower*cosf(theta);
		innerCircleLower[i][1] = irLower*sinf(theta);
		theta += (2*PI) / (NUMVERTS-1); 
	}
    
    for(i=0; i<NUMVERTS; i++)
	{
		outerCircleUpper[i][0] = orUpper*cosf(theta);
		outerCircleUpper[i][1] = orUpper*sinf(theta);
		theta += (2*PI) / (NUMVERTS-1);
	}
    
	theta = 0;
	for(i=0; i<NUMVERTS; i++)
	{
		innerCircleUpper[i][0] = irUpper*cosf(theta);
		innerCircleUpper[i][1] = irUpper*sinf(theta);
		theta += (2*PI) / (NUMVERTS-1); 
	}    
    
	//bottom strip
    glBegin(GL_QUAD_STRIP);
    glNormal3f(0,-1,0);
	for(i=0; i<NUMVERTS; i++)
	{
        glVertex3f(innerCircleLower[i][0],y1,innerCircleLower[i][1]);
		glVertex3f(outerCircleLower[i][0],y1,outerCircleLower[i][1]);
	}
	glEnd();
    
	//top strip
    glNormal3f(0,1,0);
	glBegin(GL_QUAD_STRIP);
	for(i=0; i<NUMVERTS; i++)
	{
        glVertex3f(outerCircleUpper[i][0],y2,outerCircleUpper[i][1]);
        glVertex3f(innerCircleUpper[i][0],y2,innerCircleUpper[i][1]);
	}
	glEnd();
    
	//side strip: inner
	glBegin(GL_TRIANGLE_STRIP);
    GLfloat result[3], point1[3], point2[3], point3[3];
	for(i=0; i<NUMVERTS; i++)
	{
        point1[0] = innerCircleUpper[i][0];
        point1[1] = y2;
        point1[2] = innerCircleUpper[i][1];
        
        point2[0] = innerCircleLower[i][0];
        point2[1] = y1;
        point2[2] = innerCircleLower[i][1];
        if(i==0)
        {
            point3[0] = innerCircleLower[NUMVERTS-2][0];
            point3[1] = y1;
            point3[2] = innerCircleLower[NUMVERTS-2][1];
            [self unitNormalPoint1:point1 point2:point2 point3:point3 result:result];
        }
        else
        {
            point3[0] = innerCircleLower[i-1][0];
            point3[1] = y1;
            point3[2] = innerCircleLower[i-1][1];
            [self unitNormalPoint1:point1 point2:point2 point3:point3 result:result];
        }
        glNormal3f(result[0],result[1],result[2]);
        glVertex3f(point1[0],point1[1],point1[2]);
		glVertex3f(point2[0],point2[1],point2[2]);
	}
	glEnd();
    
	//side strip: outer
	glBegin(GL_TRIANGLE_STRIP);
    
    for(i=0; i<NUMVERTS; i++)
	{
        point1[0] = outerCircleLower[i][0];
        point1[1] = y1;
        point1[2] = outerCircleLower[i][1];
        
        point2[0] = outerCircleUpper[i][0];
        point2[1] = y2;
        point2[2] = outerCircleUpper[i][1];
        if(i==0)
        {
            point3[0] = outerCircleUpper[NUMVERTS-2][0];
            point3[1] = y2;
            point3[2] = outerCircleUpper[NUMVERTS-2][1];
            [self unitNormalPoint1:point1 point2:point3 point3:point2 result:result];
        }
        else
        {
            point3[0] = outerCircleUpper[i-1][0];
            point3[1] = y2;
            point3[2] = outerCircleUpper[i-1][1];
            [self unitNormalPoint1:point1 point2:point3 point3:point2 result:result];
        }
        glNormal3f(result[0],result[1],result[2]);
        glVertex3f(point1[0],point1[1],point1[2]);
		glVertex3f(point2[0],point2[1],point2[2]);
	}
	glEnd();
    
    glPopMatrix();
    
}

- (void) cylinderInnerRadius:(float)ir outerRadius:(float)or height:(float)height 
         translateX:(float)tx translateY:(float)ty translateZ:(float)tz
{    
    [self partialConeInnerRadiusLower:ir outerRadiusLower:or innerRadiusUpper:ir outerRadiusUpper:or 
                               height:height translateX:tx translateY:ty translateZ:tz];
}

- (void) draw3D:(NSRect)aRect
{
    double rot = [delegate getRotation];
    double trans = [delegate getTrans];
    
    glRotatef(170, 0.0f, 1.0f, 0.0f); //orbit the Y axis
    glRotatef(45, 1.0f, 0.0f, 0.0f); //orbit the X axis

    glClearColor(0.93f, 0.93f, 0.93f, 0.0f);
    
    [self addLighting];
    [self shinyLighting];
    
    glColor3f(191.0/255,193.0/255,194.0/255); //detector
    [self cylinderInnerRadius:0 outerRadius:.5 height:2.57 translateX:0 translateY:0 translateZ:0];
     
    glColor3f(135.0/255,115.0/255,85.0/255); //cone on top of dewar
    [self partialConeInnerRadiusLower:0 outerRadiusLower:2.57 innerRadiusUpper:0 outerRadiusUpper:.55 height:2 translateX:0 translateY:-2.2 translateZ:0];
    glColor3f(135.0/255,115.0/255,85.0/255); //dewar
    [self cylinderInnerRadius:0 outerRadius:2.57 height:4.29 translateX:0 translateY:-5.3 translateZ:0];
    
    [self regularLighting];
    
    [zComponent drawScaleX:1 scaleY:1 scaleZ:1 translateX:1.8 translateY:.82+trans translateZ:0 rotateAngle:rot rotateX:0 rotateY:1 rotateZ:0];
    [angularComponent drawScaleX:2.5 scaleY:2.5 scaleZ:2.5 translateX:2.8 translateY:.15 translateZ:.65 rotateAngle:rot rotateX:0 rotateY:1 rotateZ:0];
    
    glColor3f(204.0/255,204.0/255,204.0/255); //line at 0
    [self cubeScaleX:1.25 scaleY:.001 scaleZ:.01 translateX:1.25 translateY:.2 translateZ:0 rotateAngle:0 rotateX:0 rotateY:0 rotateZ:0];
    glColor3f(204.0/255,204.0/255,204.0/255); //line at detector
    [self cubeScaleX:1.25 scaleY:.001 scaleZ:.01 translateX:1.25 translateY:.2 translateZ:0 rotateAngle:rot rotateX:0 rotateY:1 rotateZ:0];
    
    glColor3f(150.0/255,150.0/255,150.0/255); //trackOuter
	[self cylinderInnerRadius:2.35 outerRadius:2.5 height:.17 translateX:0 translateY:0 translateZ:0];
    glColor3f(194.0/255,194.0/255,194.0/255); //trackMiddle
	[self cylinderInnerRadius:2.05 outerRadius:2.35 height:.05 translateX:0 translateY:0 translateZ:0];
    glColor3f(150.0/255,150.0/255,150.0/255); //trackInner
	[self cylinderInnerRadius:1.9 outerRadius:2.05 height:.17 translateX:0 translateY:0 translateZ:0];
}
@end
