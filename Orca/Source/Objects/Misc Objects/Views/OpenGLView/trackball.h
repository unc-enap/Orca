/*
    trackball.h
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

#ifndef __trackball_h__
#define __trackball_h__

#ifdef __cplusplus
extern "C" {
#endif

// called with the start position and the window origin + size
void startTrackball (long x, long y, long originX, long originY, long width, long height);

// calculated rotation based on current mouse position
void rollToTrackball (long x, long y, float rot [4]); // rot is output rotation angle

// add a GL rotation (dA) to an existing GL rotation (A)
void addToRotationTrackball (float * dA, float * A);

#ifdef __cplusplus
}
#endif

#endif