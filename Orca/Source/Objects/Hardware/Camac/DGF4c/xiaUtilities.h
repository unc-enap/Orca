/*
 *  xiaUtilities.h
 *  Orca
 *
 *  Created by Mark A. Howe on 6/20/05. From XIA's Utilities.h
 *  Copyright 2005 CENPA, University of Washington. All rights reserved.
 *
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

#define SYSTEM_CLOCK_MHZ		40		//in MHz

unsigned short Random_Set[8192];	/* Random indices used by TauFinder and BLCut */

double Tau_Finder(double Tau);
double Tau_Fit(unsigned int* Trace, long kmin, long kmax, double dt);
double Phi_Value(unsigned int* ydat,double qq, long kmin, long kmax);
double Thresh_Finder(unsigned int* Trace, double Tau, double* FF, double* FF2, long FL, long FG, unsigned short Xwait);
long RandomSwap();
long linefit (double* data, double* coeff);

