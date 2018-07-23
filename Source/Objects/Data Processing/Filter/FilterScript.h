//
//  FilterScript.h
//  Orca
//
//  Created by Mark Howe on Fri Jan 25 2008.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#ifndef FilterScript_h
#define  FilterScript_h

extern int FilterScriptYYINPUT(char* theBuffer,unsigned long maxSize);
#undef YY_INPUT
#define YY_INPUT(b,r,s) (r = FilterScriptYYINPUT(b,s))

typedef enum nodeEnum { typeCon, typeId, typeOpr } nodeEnum;

typedef enum nodetype {startNodeType,filterNodeType,finishNodeType} nodetype;

enum {
	kPostInc,
	kPreInc,
	kPostDec,
	kPreDec,
	kConditional,
	kArrayListAssign,
	kDefineArray,
	kLeftArray,
	kArrayElement,
	kMakeArgList,
	kArrayAssign
};

/* constants */
typedef struct {
    uint32_t value;                  /* value of constant */
} conNodeType;

/* identifiers */
typedef struct {
    char key[100];                      /* key into hash table */
} idNodeType;

typedef struct {
    char cString[100];                      /* key into hash table */
} strNodeType;


/* operators */
typedef struct {
    int oper;                   /* operator */
    int nops;                   /* number of operands */
    struct nodeTypeTag *op[4];  /* operands (expandable) */
} oprNodeType;

typedef struct nodeTypeTag {
    nodeEnum type;              /* type of node */

    /* union must be last entry in nodeType */
    /* because operNodeType may dynamically increase */
    union {
        conNodeType con;        /* constants */
        idNodeType ident;       /* identifiers */
        oprNodeType opr;        /* operators */
		strNodeType str;
    };
} nodeType;

#endif
