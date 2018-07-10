//
//  OROpenGLObject.hm
//  ORCA
//
//  Created by Laura Wendlandt on 6/28/13.
//
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

#import "OROpenGLObject.h"
#include <GLUT/glut.h>                  //Allows access to the glut library

@implementation OROpenGLObject

- (id) initFromFile:(NSString*)inputFile
{
    self = [super init];
    
    vertices = [[NSMutableArray alloc] init];
    faces = [[NSMutableArray alloc] init];
    faceNormals = [[NSMutableArray alloc] init];
    faceColors = [[NSMutableArray alloc] init];
    normals = [[NSMutableArray alloc] init];
    
    colors = [[NSMutableDictionary alloc] init];
    
    orientAngle = 0;
    orientX = 0;
    orientY = 0;
    orientZ = 0;
    
    int i,j; //loop variables
    
    NSMutableString* inputData = [NSMutableString stringWithContentsOfFile:inputFile encoding:NSASCIIStringEncoding error:nil];
    if(inputData == nil)
    {
        NSLog(@"Error: nothing in file\n");
        return self;
    }
 
//delete comments
    int start, end;
    for(i=0; i<[inputData length]; i++)
    {
        if([inputData characterAtIndex:i] == '#')
        {
            start = i;
            while([inputData characterAtIndex:i] != '\n')
                i++;
            end = i;
            [inputData deleteCharactersInRange:NSMakeRange(start, (end-start)+1)];
        }
    }

    NSArray* lines = [inputData componentsSeparatedByString:@"\n"];
    NSMutableArray* words = [NSMutableArray arrayWithCapacity:[lines count]];
    for(i=0; i<[lines count]; i++)
    {
        NSMutableArray* a = [[NSMutableArray alloc] initWithArray:[[lines objectAtIndex:i] componentsSeparatedByString:@" "]];
        [words insertObject:a atIndex:i];
        [a release];
    }
    
    ORVertex* defaultColor = [[ORVertex alloc] initWithX:[[NSNumber numberWithInt:128] floatValue] Y:[[NSNumber numberWithInt:255] floatValue] Z:[[NSNumber numberWithInt:0] floatValue]];
    [colors setObject:defaultColor forKey:@"default"];
    [defaultColor release];
    NSMutableString* currentColor = [[NSMutableString alloc] initWithString:@"default"];
    
    NSArray* commands = [NSArray arrayWithObjects:@"mtllib",@"usemtl",@"v",@"vn",@"f", nil];
    NSArray* commandLengths = [NSArray arrayWithObjects:[NSNumber numberWithInt:1],[NSNumber numberWithInt:1],[NSNumber numberWithInt:3],[NSNumber numberWithInt:3],[NSNumber numberWithInt:3], nil]; //minimum number of arguments that must follow a certain command
    NSDictionary* lengths = [NSDictionary dictionaryWithObjects:commandLengths forKeys:commands];
    
    //remove blank words
    for(i=0; i<[words count]; i++)
    {
        for(j=0; j<[[words objectAtIndex:i] count];)
        {
            if(![[[words objectAtIndex:i] objectAtIndex:j] length])
                [[words objectAtIndex:i] removeObjectAtIndex:j];
            else j++;
        }
    }
        
    for(i=0; i<[words count]; i++)
    {        
        if([[words objectAtIndex:i] count] == 0)
            continue;
        
        if([lengths objectForKey:[[words objectAtIndex:i] objectAtIndex:0]] == nil) //ignore unknown commands
            continue;
        
        if([[words objectAtIndex:i] count] < [[lengths objectForKey:[[words objectAtIndex:i] objectAtIndex:0]] intValue] + 1)
        {
            NSLog(@"Error: not enough arguments following command %@\n",[[words objectAtIndex:i] objectAtIndex:0]);
            [currentColor release];
            return self;
        }
  
        if([[[words objectAtIndex:i] objectAtIndex:0] isEqualToString:@"mtllib"])
        {
            if(![self importColors:[[words objectAtIndex:i] objectAtIndex:1]])
            {
                NSLog(@"Error: invalid file following mtllib command\n");
                [currentColor release];
                return self;
            }
        }
        else if([[[words objectAtIndex:i] objectAtIndex:0] isEqualToString:@"usemtl"])
        {
            [currentColor setString:[[words objectAtIndex:i] objectAtIndex:1]];
        }
        else if([[[words objectAtIndex:i] objectAtIndex:0] isEqualToString:@"v"])
        {
            ORVertex* v = [[ORVertex alloc] initWithX:[[[words objectAtIndex:i] objectAtIndex:1] floatValue] Y:[[[words objectAtIndex:i] objectAtIndex:2] floatValue] Z:[[[words objectAtIndex:i] objectAtIndex:3] floatValue]];
            [vertices addObject:v];
            [v release];
        }
        else if([[[words objectAtIndex:i] objectAtIndex:0] isEqualToString:@"vn"])
        {
            ORVertex* v = [[ORVertex alloc] initWithX:[[[words objectAtIndex:i] objectAtIndex:1] floatValue] Y:[[[words objectAtIndex:i] objectAtIndex:2] floatValue] Z:[[[words objectAtIndex:i] objectAtIndex:3] floatValue]];
            [normals addObject:v];
            [v release];
        }
        else if([[[words objectAtIndex:i] objectAtIndex:0] isEqualToString:@"f"])
        {
            if(![self parseFaces:[words objectAtIndex:i] color:currentColor])
            {
                NSLog(@"Error in parsing faces\n");
                [currentColor release];
                return self;
            }
        }
    }
    
    [self divideByLargest:vertices];
    [self divideByLargest:normals];
    
    [currentColor release];
    return self;
}

- (void) dealloc
{
    [vertices release];
    [faces release];
    [faceNormals release];
    [faceColors release];
    [normals release];
    
    [colors release];
    
    [super dealloc];
}

- (BOOL) parseFaces:(NSArray*)currentLine color:(NSString*)currentColor
{ 
    NSMutableArray *faceNumbers = [NSMutableArray arrayWithCapacity:[currentLine count]];
    NSMutableArray *faceNormalNumbers = [NSMutableArray arrayWithCapacity:[currentLine count]];

//check to see if faces are in correct format
    int i;
    for(i=1; i<[currentLine count]; i++)
    {
        
        NSArray *components = [[currentLine objectAtIndex:i] componentsSeparatedByString:@"/"];
 
        NSScanner *scan1 = [[NSScanner alloc] initWithString:[components objectAtIndex:0]];
        int myInt;
        [scan1 scanInt:&myInt];
        [faceNumbers insertObject:[NSNumber numberWithInt:myInt-1] atIndex:i-1]; //re-index at 0
        [scan1 release];
        
        NSScanner *scan2 = [[NSScanner alloc] initWithString:[components objectAtIndex:2]];
        [scan2 scanInt:&myInt];
        [faceNormalNumbers insertObject:[NSNumber numberWithInt:myInt-1] atIndex:i-1];
        [scan2 release];
    }
    
    [faces addObject:faceNumbers];
    [faceNormals addObject:faceNormalNumbers];

    [faceColors addObject:[colors valueForKey:currentColor]];
    
    return YES;
}
 
- (void) divideByLargest:(NSMutableArray*)v
{
    float largest = [[v objectAtIndex:0] largestAbsolute];
    int i;
    for(i=1; i<[v count]; i++)
    {
        if([[v objectAtIndex:i] largestAbsolute] > largest)
            largest = [[v objectAtIndex:i] largestAbsolute];
    }
 
    for(i=0; i<[v count]; i++)
        [[v objectAtIndex:i] divideAllBy:largest];
}

- (BOOL) importColors:(NSString*)file
{    
    NSRange dot = [file rangeOfString:@"."];
    NSString* fileName = [[NSString alloc] initWithString:[file substringWithRange:NSMakeRange(0, dot.location)]];
    
    NSBundle* mainBundle = [NSBundle mainBundle];
	NSString* fullPath = [mainBundle pathForResource:fileName ofType: @"mtl"];
    
    NSMutableString* inputData = [NSMutableString stringWithContentsOfFile:fullPath encoding:NSASCIIStringEncoding error:nil];
    if(inputData == nil)
    {
        [fileName release];
        return NO;
    }
    
    [inputData replaceOccurrencesOfString:@"\n" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[inputData length])];
    NSArray* tokens = [inputData componentsSeparatedByString:@" "];
    
    NSEnumerator* enumerator = [tokens objectEnumerator];
    id anObject;
    while(anObject = [enumerator nextObject])
    {
        if([anObject isEqualToString:@"newmtl"])
        {
            NSString* name = [enumerator nextObject];
            int i;
            for(i=0; i<5; i++)
                [enumerator nextObject]; //skip to diffuse light numbers
            ORVertex* tempColors = [[ORVertex alloc] initWithX:[[enumerator nextObject] floatValue] Y:[[enumerator nextObject] floatValue] Z:[[enumerator nextObject] floatValue]];
            [colors setObject:tempColors forKey:name];
            [tempColors release];
        }
    }
    
    [fileName release];

    return YES;
}

- (void) orientAngle:(float)angle x:(float)x y:(float)y z:(float)z
{
    orientAngle = angle;
    orientX = x;
    orientY = y;
    orientZ = z;
}

- (void) drawScaleX:(float)sx scaleY:(float)sy scaleZ:(float)sz
         translateX:(float)tx translateY:(float)ty translateZ:(float)tz
        rotateAngle:(float)ra rotateX:(float)rx rotateY:(float)ry rotateZ:(float)rz
{
    
    glPushMatrix();
    glRotatef(ra,rx,ry,rz); //OpenGL multiplies matrices from the right (backwards order)
    glTranslatef(tx,ty,tz);
    glRotatef(orientAngle,orientX,orientY,orientZ);
    glScalef(sx,sy,sz);
    
    int i,j;
    for(i=0; i<[faces count]; i++)
    {
        glColor3f([[faceColors objectAtIndex:i] getX], [[faceColors objectAtIndex:i] getY], [[faceColors objectAtIndex:i] getZ]);
        glBegin(GL_POLYGON);
        
        for(j=0; j<[[faces objectAtIndex:i] count]; j++)
        {
            glNormal3f([[normals objectAtIndex:[[[faceNormals objectAtIndex:i] objectAtIndex:j] intValue]] getX],[[normals objectAtIndex:[[[faceNormals objectAtIndex:i] objectAtIndex:j] intValue]] getY],[[normals objectAtIndex:[[[faceNormals objectAtIndex:i] objectAtIndex:j] intValue]] getZ]);
            glVertex3f([[vertices objectAtIndex:[[[faces objectAtIndex:i] objectAtIndex:j] intValue]] getX],[[vertices objectAtIndex:[[[faces objectAtIndex:i] objectAtIndex:j] intValue]] getY],[[vertices objectAtIndex:[[[faces objectAtIndex:i] objectAtIndex:j] intValue]] getZ]);
        }

        glEnd();
    }
    
    glPopMatrix();
}

@end