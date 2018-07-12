//
//  ORHWWizSelection.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 30 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORHWWizSelection.h"
#import "ORHWWizard.h"

@implementation ORHWWizSelection

+ (id) itemAtLevel:(eSelectionLevel)aLevel name:(NSString*)aName className:(NSString*)aClassName
{
  ORHWWizSelection* selection = [[ORHWWizSelection alloc] init];
  [selection setLevel:aLevel];
  [selection setName:aName];
  [selection setSelectionClass:NSClassFromString(aClassName)];
  [selection scanConfiguration];
  return [selection autorelease];
}


- (void)dealloc
{
    [name release];
    [super dealloc];
}

- (NSString *)name
{
    return name; 
}

- (void)setName:(NSString *)aName
{
    [name autorelease];
    name = [aName copy];
}


- (eSelectionLevel)level
{
    return level;
}

- (void)setLevel:(eSelectionLevel)aLevel
{
    level = aLevel;
}

- (Class) selectionClass
{
    return selectionClass;
}
- (void) setSelectionClass:(Class)aClass
{
    selectionClass = aClass;
}

- (int) numberOfItems
{
    return numberOfItems;
}

- (void) setNumberOfItems:(int)aNumberOfItems
{
    numberOfItems = aNumberOfItems;
}

- (int) maxValue
{
    return maxValue;
}

- (void) setMaxValue:(int)aMaxValue
{
    maxValue = aMaxValue;
}

- (void) scanConfiguration
{
    NSArray* objects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:selectionClass];
    [self setNumberOfItems:(int)[objects count]];
    
    if(level == kContainerLevel){
        if([objects count]){
            [self setMaxValue:(int)[objects count]-1];
        }
    }
    else if(level == kChannelLevel){
        if([objects count]){
            id <ORHWWizard> obj = [objects objectAtIndex:0];
            [self setMaxValue:[obj numberOfChannels]-1];
            [self setNumberOfItems:[obj numberOfChannels]];
        }
    }
    else if(level == kObjectLevel){
        NSEnumerator* e = [objects objectEnumerator];
        OrcaObject<ORHWWizard>* obj;
        while(obj = [e nextObject]){
            int objectTag = (int)[obj stationNumber]; //some objs, i.e. CAMAC objects aren't zero based.;
            if(objectTag > maxValue){
                [self setMaxValue:objectTag];
            }
        }
    }
}


@end
