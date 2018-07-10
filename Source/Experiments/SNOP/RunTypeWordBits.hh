//////////////////////////////////////////////////////////////////////
/// \class RunTypeWordBits
///
/// \brief Hold Run Type Word Bit mnemonics
///
/// \author Javier Caravaca <jcaravaca@berkeley.edu>
///
/// REVISION HISTORY:\n
///     07 Jan  2017 : Javier Caravaca --- First version.\n
///     27 July 2017 : Tony LaTorre    --- added AV Recirculation bit.\n
///
/// \details  Reference for the run type word bits positions
///           and names. This piece is shared with the ORCA
///           code so it needs to be simple and free of
///           dependencies.
///
//////////////////////////////////////////////////////////////////////

#ifndef __RAT_DU_RunTypeWordBits__
#define __RAT_DU_RunTypeWordBits__

static char *RunTypeWordBitNames[32] = {
    "Maintenance",
    "Transition",
    "Physics",
    "Deployed Source",
    "External Source",
    "ECA",
    "Diagnostic",
    "Experimental",
    "Supernova",
    "Spare",
    "Spare",
    "TELLIE",
    "SMELLIE",
    "AMELLIE",
    "PCA",
    "ECAPDST",
    "ECATSLP",
    "Spare",
    "Embedded Peds.",
    "Spare",
    "Spare",
    "DCR Activity",
    "Comp. Coils OFF",
    "PMTs OFF",
    "Bubblers ON",
    "Cavity Recirculation ON",
    "SLAssay",
    "Unusual Activity",
    "AV Recirculation ON",
    "Spare",
    "Spare",
    "Spare"
};

enum RunTypeWordBits {
    /* mutually exclusive run types */
    kMaintenanceRun=0x1,
    kTransitionRun=0x2,
    kPhysicsRun=0x4,
    kDeployedSourceRun=0x8,
    kExternalSourceRun=0x10,
    kECARun=0x20,
    kDiagnosticRun=0x40,
    kExperimentalRun=0x80,
    kSupernovaRun=0x100,
    /* calibration */
    kTELLIERun=0x800,
    kSMELLIERun=0x1000,
    kAMELLIERun=0x2000,
    kPCARun=0x4000,
    kECAPedestalRun=0x8000,
    kECATSlopeRun=0x10000,
    kEmbeddedPeds=0x40000,
    /* detector state */
    kDCRActivityRun=0x200000,
    kCompCoilsOFFRun=0x400000,
    kPMTOFFRun=0x800000,
    kBubblersONRun=0x1000000,
    kRecirculationRun=0x2000000,
    kSLAssayRun=0x4000000,
    kUnusualActivityRun=0x8000000
};

#endif
