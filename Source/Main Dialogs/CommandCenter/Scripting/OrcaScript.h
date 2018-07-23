extern int OrcaScriptYYINPUT(char* theBuffer,unsigned long maxSize);
#undef YY_INPUT
#define YY_INPUT(b,r,s) (r = OrcaScriptYYINPUT(b,s))


typedef enum { typeCon, typeId, typeOpr, typeSelVar, typeStr, typeArray, typeArg, typeOperationSymbol} nodeEnum;

enum {
	kPostInc,
	kPreInc,
	kPostDec,
	kPreDec,
	kAppend,
	kTightAppend,
	kObjList,
	kDefineArray,
	kLeftArray,
	kRightArray,
	kSelName,
	kFuncCall,
	kMakeArgList,
	kConditional,
	kArrayListAssign,
	kArrayAssign,
	kWaitTimeOut,
    kConfirmTimeOut,
    kGlobal,
    kGlobalVar,
    kGlobalAssign,
    kSelfFunction,
    kBitExtract,
    kCaseRange,
    kCaseRange1,
    kCaseGtE,
    kCaseLtE,
    kCaseLt,
    kCaseGt
};
