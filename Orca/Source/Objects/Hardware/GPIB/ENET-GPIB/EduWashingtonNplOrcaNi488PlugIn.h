//
//  ORGpibEnet.h
//  Orca Bundle
//
//  Created by Michael Marino on Sat 8 Dec 2007.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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





#pragma mark ***Class Definition
@interface EduWashingtonNplOrcaNi488PlugIn : NSObject {
    BOOL isLoaded;
}

#pragma mark ***Initialization.
- (id) 		init;

- (BOOL) isLoaded;

#pragma mark ***Accessors

- (unsigned short) unl;
- (unsigned short) unt;
- (unsigned short) gtl;
- (unsigned short) sdc;
- (unsigned short) ppc;
- (unsigned short) get;
- (unsigned short) tct;
- (unsigned short) llo;
- (unsigned short) dcl;
- (unsigned short) ppu;
- (unsigned short) spe;
- (unsigned short) spd;
- (unsigned short) ppe;
- (unsigned short) ppd;




- (unsigned short) err;
- (unsigned short) timo;
- (unsigned short) end;
- (unsigned short) srqi;
- (unsigned short) rqs;
- (unsigned short) cmpl;
- (unsigned short) lok;
- (unsigned short) rem;
- (unsigned short) cic;
- (unsigned short) atn;
- (unsigned short) tacs;
- (unsigned short) lacs;
- (unsigned short) dtas;
- (unsigned short) dcas;


- (unsigned short) edvr;
- (unsigned short) ecic;
- (unsigned short) enol;
- (unsigned short) eadr;
- (unsigned short) earg;
- (unsigned short) esac;
- (unsigned short) eabo;
- (unsigned short) eneb;
- (unsigned short) edma;
- (unsigned short) eoip;
             
- (unsigned short) ecap;
- (unsigned short) efso;
- (unsigned short) ebus;
- (unsigned short) estb;
- (unsigned short) esrq;
- (unsigned short) etab;
- (unsigned short) elck;
- (unsigned short) earm;
- (unsigned short) ehdl;
- (unsigned short) ewip;
- (unsigned short) erst;
             


- (unsigned short) wcfg;


- (unsigned short) bin;
- (unsigned short) xeos;
- (unsigned short) reos;


- (unsigned short) tnone;
- (unsigned short) t10us;
- (unsigned short) t30us;
- (unsigned short) t100us;
- (unsigned short) t300us;
- (unsigned short) t1ms;
- (unsigned short) t3ms;
- (unsigned short) t10ms;
- (unsigned short) t30ms;
- (unsigned short) t100ms;
- (unsigned short) t300ms;
- (unsigned short) t1s;
- (unsigned short) t3s;
- (unsigned short) t10s;
- (unsigned short) t30s;
- (unsigned short) t100s;
- (unsigned short) t300s;
- (unsigned short) t1000s;

- (unsigned short) no_sad;
- (unsigned short) all_sad;

- (unsigned short) ibcpad;
- (unsigned short) ibcsad;
- (unsigned short) ibctmo;
- (unsigned short) ibceot;
- (unsigned short) ibcppc;
- (unsigned short) ibcreaddr;
- (unsigned short) ibcautopoll;
- (unsigned short) ibccicprot;
- (unsigned short) ibcirq;
- (unsigned short) ibcsc;
- (unsigned short) ibcsre;
- (unsigned short) ibceosrd;
- (unsigned short) ibceoswrt;
- (unsigned short) ibceoscmp;
- (unsigned short) ibceoschar;
- (unsigned short) ibcpp2;
- (unsigned short) ibctiming;
- (unsigned short) ibcdma;
- (unsigned short) ibcreadadjust;
- (unsigned short) ibcwriteadjust;
- (unsigned short) ibcsendllo;
- (unsigned short) ibcspolltime;
- (unsigned short) ibcppolltime;
- (unsigned short) ibcendbitisnormal;
- (unsigned short) ibcunaddr;
- (unsigned short) ibcsignalnumber;
- (unsigned short) ibcblockiflocked;
- (unsigned short) ibchscablelength;
- (unsigned short) ibcist;
- (unsigned short) ibcrsv;
- (unsigned short) ibclon;

- (unsigned short) ibabna;


- (unsigned short) nullend;
- (unsigned short) nlend;
- (unsigned short) dabend;

- (unsigned short) stopend;


- (unsigned short) getPAD: (unsigned short) val;
- (unsigned short) getSAD: (unsigned short) val;

/* iblines constants */

- (unsigned short) valideoi;
- (unsigned short) validatn;
- (unsigned short) validsrq;
- (unsigned short) validren;
- (unsigned short) validifc;
- (unsigned short) validnrfd;
- (unsigned short) validndac;
- (unsigned short) validdav;
- (unsigned short) buseoi;
- (unsigned short) busatn;
- (unsigned short) bussrq;
- (unsigned short) busren;
- (unsigned short) busifc;
- (unsigned short) busnrfd;
- (unsigned short) busndac;
- (unsigned short) busdav;

- (unsigned short) timmediate;
- (unsigned short) tinfinite;
- (unsigned short) max_locksharename_length;

- (int) ibsta;
- (int) iberr;
- (long) ibcntl;

- (int) ibfind:(char*) udname;
- (int) ibbna:(int) ud udname:(char*) udname;
- (int) ibrdf:(int) ud filename:(char*) filename;
- (int) ibwrtf:(int) ud filename:(char*) filename;

- (int) ibask:(int) ud option:(int) option  v:(int*) v;
- (int) ibcac:(int) ud v:(int) v;
- (int) ibclr:(int) ud;
- (int) ibcmd:(int) ud buf:(void*) buf  cnt:(long) cnt;
- (int) ibcmda:(int) ud buf:(void*) buf  cnt:(long) cnt;
- (int) ibconfig:(int) ud option:(int) option  v:(int) v;
- (int) ibdev:(int) boardID  pad:(int) pad  sad:(int) sad  tmo:(int) tmo  eot:(int) eot  eos:(int) eos;
- (int) ibdiag:(int) ud buf:(void*) buf  cnt:(long) cnt;
- (int) ibdma:(int) ud v:(int) v;
- (int) ibexpert:(int) ud option:(int) option  Input:(void*) Input  Output:(void*) Output;
- (int) ibeos:(int) ud v:(int) v;
- (int) ibeot:(int) ud v:(int) v;
- (int) ibgts:(int) ud v:(int) v;
- (int) ibist:(int) ud v:(int) v;
- (int) iblck:(int) ud v:(int) v  LockWaitTime:(unsigned int) LockWaitTime  Reserved:(void*) Reserved;
- (int) iblines:(int) ud result:(short*)  result;
- (int) ibln:(int) ud pad:(int) pad  sad:(int) sad  listen:(short*)  listen;
- (int) ibloc:(int) ud;
- (int) ibonl:(int) ud v:(int) v;
- (int) ibpad:(int) ud v:(int) v;
- (int) ibpct:(int) ud;
- (int) ibpoke:(int) ud option:(long) option  v:(long) v;
- (int) ibppc:(int) ud v:(int) v;
- (int) ibrd:(int) ud buf:(void*) buf  cnt:(long) cnt;
- (int) ibrda:(int) ud buf:(void*) buf  cnt:(long) cnt;
- (int) ibrpp:(int) ud ppr:(char*) ppr;
- (int) ibrsc:(int) ud v:(int) v;
- (int) ibrsp:(int) ud spr:(char*) spr;
- (int) ibrsv:(int) ud v:(int) v;
- (int) ibsad:(int) ud v:(int) v;
- (int) ibsic:(int) ud;
- (int) ibsre:(int) ud v:(int) v;
- (int) ibstop:(int) ud;
- (int) ibtmo:(int) ud v:(int) v;
- (int) ibtrg:(int) ud;
- (int) ibwait:(int) ud mask:(int) mask;
- (int) ibwrt:(int) ud buf:(void*) buf  cnt:(long) cnt;
- (int) ibwrta:(int) ud buf:(void*) buf  cnt:(long) cnt;


// GPIB-ENET only functions to support locking across machines
// Deprecated - Use iblck
- (int)  iblock:(int) ud;
- (int)  ibunlock:(int) ud;

/**************************************************************************/
/*  Functions to access Thread-Specific copies of the GPIB global vars */

- (int)   ThreadIbsta;
- (int)   ThreadIberr;
- (int)   ThreadIbcnt;
- (long)  ThreadIbcntl;


/**************************************************************************/
/*  NI-488.2 Function Prototypes  */

@end

#pragma mark ***Commands
