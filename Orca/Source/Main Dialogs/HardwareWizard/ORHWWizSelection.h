//
//  ORHWWizSelection.h
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




typedef enum  {
    kContainerLevel,
    kObjectLevel,
    kChannelLevel,
    kSelectionLevel_Null = 0xffff
}eSelectionLevel;

typedef enum  {
    kSearchLogic_And,
    kSearchLogic_Or,
}eSelectionLogic;

typedef enum  {
    kSearchAction_IsAnything,
    kSearchAction_Is,
    kSearchAction_IsLessThan,
    kSearchAction_IsGreatherThan,
    kSearchAction_IsNot,
    kSearchAction_IsMultipleOf,
    kSearchAction_IsNotMultipleOf,
}eSelectionAction;


@interface ORHWWizSelection : NSObject {
    NSString* name;
    Class     selectionClass;
    int       level;
    int       maxValue;
    int       numberOfItems;
}

+ (id) itemAtLevel:(eSelectionLevel)aLevel name:(NSString*)aName className:(NSString*)aClassName;

- (NSString*) name;
- (void)  setName:(NSString *)aName;
- (eSelectionLevel)level;
- (void)  setLevel:(eSelectionLevel)aLevel;
- (Class) selectionClass;
- (void)  setSelectionClass:(Class)aClass;
- (int)   numberOfItems;
- (void)  setNumberOfItems:(int)aNumberOfItems;
- (int)   maxValue;
- (void)  setMaxValue:(int)aMaxValue;
- (void)  scanConfiguration;

@end

@interface NSObject (WizSelection)
- (int) minSlot;
@end
