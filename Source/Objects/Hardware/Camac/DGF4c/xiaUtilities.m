/*
 *  xiaUtilities.c
 *  Orca
 *
 *  Created by Mark A. Howe on 6/20/05. From XIA's Utilities.c
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

#import  "xiaUtilities.h"
#import <math.h>
#import <stdlib.h>

/****************************************************************
 *	Tau_Fit function:											*
 *		Exponential fit of the ADC trace.						*
 *																*
 *		Return Value:											*
 *					 											*
 *																*
 ****************************************************************/

double Tau_Fit(unsigned int* Trace, long kmin, long kmax, double dt){

	double mutop,mubot,valbot,eps,dmu,mumid,valmid;
	 long count;

	eps=1e-3;
	mutop=10e6; /* begin the search at tau=100ns (=1/10e6) */
	//valtop=Phi_Value(Trace,exp(-mutop*dt),kmin,kmax);
	mubot=mutop;
	count=0;
	do{				// geometric progression search
		mubot=mubot/2.0;
		valbot=Phi_Value(Trace,exp(-mubot*dt),kmin,kmax);
		count+=1;
		if(count>20) {return(-1); }	/* Geometric search did not find an enclosing interval */ 
	} while(valbot>0);	/* tau exceeded 100ms */

	mutop=mubot*2.0;
	//valtop=Phi_Value(Trace,exp(-mutop*dt),kmin,kmax);
	count=0;
	do{			// binary search
		mumid=(mutop+mubot)/2.0;
		valmid=Phi_Value(Trace,exp(-mumid*dt),kmin,kmax);
		if(valmid>0)
			mutop=mumid;
		else
			mubot=mumid;

		dmu=mutop-mubot;
		count+=1;
		if(count>20)		  
			return(-2);  /* Binary search could not find small enough interval */
  
	} while(fabs(dmu/mubot) > eps);

	return(1/mutop);  /* success */
}

/****************************************************************
 *	Phi_Value function:											*
 *		geometric progression search.							*
 *																*
 *		Return Value:											*
 *					 											*
 *																*
 ****************************************************************/

double Phi_Value(unsigned int* ydat,double qq, long kmin, long kmax){

	long ndat,k;
	double s0,s1,s2,qp;
	double A,B,Fk,F2k,Dk,Ek,val;
  
	ndat=kmax-kmin+1;
	s0=0; s1=0; s2=0;
	qp=1;

	for(k=kmin;k<=kmax;k+=1){
		s0+=ydat[k];
		s1+=qp*ydat[k];
		s2+=qp*ydat[k]*(k-kmin)/qq;
		qp*=qq;

	}

	Fk=(1-pow(qq,ndat))/(1-qq);
	F2k=(1-pow(qq,(2*ndat)))/(1-qq*qq);
	Dk=-(ndat-1)*pow(qq,(2*ndat-1))/(1-qq*qq)+qq*(1-pow(qq,(2*ndat-2)))/pow((1-qq*qq),2);	// correct
	Ek=-(ndat-1)*pow(qq,(ndat-1))/(1-qq)+(1-pow(qq,(ndat-1)))/pow((1-qq),2);				// correct
	A=(ndat*s1-Fk*s0)/(ndat*F2k-Fk*Fk) ;
	B=(s0-A*Fk)/ndat;

	val=s2-A*Dk-B*Ek;

	return(val);

} 

/****************************************************************
 *	Thresh_Finder function:										*
 *		Threshold finder used for Tau Finder function.			*
 *																*
 *		Return Value:											*
 *					 											*
 *																*
 ****************************************************************/

double Thresh_Finder(unsigned int* Trace, double Tau, double* FF, double* FF2, long FL, long FG,unsigned short Xwait){

	long ndat,kmin,k,ndev,n,m;
	double dt,xx,c0,sum0,sum1,deviation,threshold;

	ndev=8;
	ndat=8192;


	dt=Xwait/SYSTEM_CLOCK_MHZ*1e-6;
	xx=dt/Tau;
	c0=exp(-xx*(FL+FG));

	kmin=2*FL+FG;
	/* zero out the initial part,where the true filter values are unknown */
	for(k=0;k<kmin;k+=1)
		FF[k]=0;

    for(k=kmin;k<ndat;k+=1){
		sum0=0;	sum1=0;
		for(n=0;n<FL;n++){
			sum0+=Trace[k-kmin+n];
			sum1+=Trace[k-kmin+FL+FG+n];
		}
		FF[k]=sum1-sum0*c0;
	}

	/* zero out the initial part,where the true filter values are unknown */
	for(k=0;k<kmin;k+=1)
		FF2[k]=0;
	
    for(k=kmin;k<ndat;k+=1){
		sum0=0;	sum1=0;
		for(n=0;n<FL;n++){
			sum0+=Trace[k-kmin+n];
			sum1+=Trace[k-kmin+FL+FG+n];
		}
		FF2[k]=(sum0-sum1)/FL;
	}

	deviation=0;
	for(k=0;k<ndat;k+=2)
		deviation+=fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]]);

	deviation/=(ndat/2);
	threshold=ndev/2*deviation/2;

	m=0; deviation=0;
	for(k=0;k<ndat;k+=2){
		if(fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]])<threshold){
			m+=1;
			deviation+=fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]]);
		}
	}
	deviation/=m;
	deviation*=sqrt(3.1415927)/2;
	threshold=ndev*deviation;
	
	m=0; deviation=0;
	for(k=0;k<ndat;k+=2){
		if(fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]])<threshold){
			m+=1;
			deviation+=fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]]);
		}
	}

	deviation/=m;
	deviation*=sqrt(3.1415927)/2;
	threshold=ndev*deviation;
	
	m=0; deviation=0;
	for(k=0;k<ndat;k+=2){
		if(fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]])<threshold){
			m+=1;
			deviation+=fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]]);
		}
	}
	deviation/=m;
	deviation*=sqrt(3.1415927)/2;
	threshold=ndev*deviation;

    return(threshold);
}


long RandomSwap() {
	
	long rshift,Ncards;
	long k,MixLevel,imin,imax;
	unsigned short a;

	for(k=0; k<8192; k++)
		Random_Set[k]=(unsigned short)k;

	Ncards=8192;
	rshift= (long)(log((double)(0xffffffff/8192))/log(2.0));
	MixLevel=5;
	
	for(k=0;k<MixLevel*Ncards;k+=1) {
	   imin=(rand()>>rshift); 
	   imax=(rand()>>rshift);

       a=Random_Set[imax];
       Random_Set[imax]=Random_Set[imin];
       Random_Set[imin]=a;
	}

	return(0);
}

long linefit (double* data, double* coeff)
{

	unsigned long i;
	unsigned long ndata;

	double sxx, sx, sy, syx;

	sxx   = 0.;
	sx    = 0.;
	sy    = 0.;
	syx   = 0.;
	ndata = 0;

	for(i = (unsigned long) coeff[0]; i < (unsigned long) coeff[1]; i++){

		if(data[i] <= 0){
			continue;
		}
		sx  += i;
		sxx += i*i;
		sy  += data[i];
		syx += data[i]*i;
		ndata++;
	}

	if(ndata > 1){
		coeff[1] = (syx - ((sx * sy) / ((double) ndata))) / (sxx - ((sx * sx) / ((double) ndata)));
		coeff[0] = (sy - (coeff[1] * sx)) / ((double) ndata);
		return 0; /* fit ok */
	}
	else{
		return -1; /* no fit */
	}
}

