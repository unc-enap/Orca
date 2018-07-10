#ifndef _ORVProcess_hh_
#define _ORVProcess_hh_

#ifdef __cplusplus
extern "C" {
#include "SBC_Cmds.h"
#endif
void doGenericJob(SBC_Packet*);
void doGenericJobSocketClose();
#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
#include <string>
#include <map>
#include <set>
#include <cxxabi.h>
#include <cstdlib>

/*
 Single process virtual base class that defines an interface for calling
 a function.  Users will likely not need to use this directly.
 See ORVProcess.
*/
class ORVSingleProcess
{
  public:
    virtual void Call(SBC_Packet*) = 0;
    virtual ~ORVSingleProcess() {}
};

/*
 Template class that handles wrapping class member functions to be called using
 the ORVSingleProcess interace.  See ORVProcess
*/
template<class T>
class ORTSingleProcess : public ORVSingleProcess
{
  public:
    typedef void (T::*memPtr) (SBC_Packet*);
    ORTSingleProcess(T* var, memPtr fn) :
      _this(var),
      _fn(fn) {}

    virtual void Call(SBC_Packet* packet)
    {
      (_this->*_fn)(packet);
    }

  protected:
    T* _this;
    memPtr _fn;

};

/*
 Singleton class that registers all available "job" functions.  See ORVProcess.
*/
class ORVProcess;
class ORAllProcesses
{
  friend class ORVProcess;
  friend void doGenericJob(SBC_Packet*);
  friend void doGenericJobSocketClose();
  protected:
    static void CallProcess(const std::string& procName, SBC_Packet* packet);
    static void RegisterProcess(const std::string& procName, ORVSingleProcess* proc);

    static void RegisterProcessClass(ORVProcess* proc);
    static void UnRegisterProcessClass(ORVProcess* proc);

    static void SocketClose();

  private:
    static ORAllProcesses& GetAllProcesses();
    ORAllProcesses() {}
    ORAllProcesses(const ORAllProcesses&);
    ORAllProcesses& operator=(const ORAllProcesses&);
    typedef std::map<std::string, ORVSingleProcess*> ProcMap;
    typedef std::set<ORVProcess*> ProcSet;
    ProcMap _procMap;
    ProcSet _procSet;
};

/*
 Base class for all classes that define job functions.

 How to use:

   Define your class as deriving from ORVProcess:

   class MyProcessClass : public ORVProcess {

    public:
      MyProcessClass();

      void JobOne(SBC_Packet*);
      void JobTwo(SBC_Packet*);

      void CallOnSocketClose()
      {
		// This function will be called whenever a socket is closed.
		// This can be useful to cleanup e.g. processes that were still
		// running.
	  }

   };

   In the class implementation (.cc) file, you must do the following:

   // Instantiate the class globally, the static here ensures that the name is
   // not exported
   static MyProcessClass gMyProcClass;

   // Register the available functions in the constructor
   MyProcessClass::MyProcessClass()
   {
     RegisterJob("JobOne", &MyProcessClass::JobOne);
     RegisterJob("JobTwo", &MyProcessClass::JobTwo);
   }


   Now, in ORCA code, you can call this by doing the following:

    SBC_Packet aPacket;
    aPacket.cmdHeader.destination	= kSBC_Command;
    aPacket.cmdHeader.cmdID			= kSBC_GenericJob;
    strcpy(aPacket.message,"MyProcessClass::JobOne");
    [[[self adapter] sbcLink] send:&aPacket receive:&aPacket];

   Note, that the SBC_Packet passed in to the functions (e.g. JobOne and/or
   JobTwo in this example) will be passed back to ORCA so any response should
   be written in this.

*/

class ORVProcess
{
  protected:
    friend class ORAllProcesses;
    template< class T >
    void RegisterJob(const std::string& name,
                     void (T::*fn)(SBC_Packet*))
    {
      // Register a job (member function of a class)
	  // Note, this must be called in the constructor of a global class!
	  int status;
      char * demangled = abi::__cxa_demangle(typeid(T).name(),0,0,&status);
      ORAllProcesses::RegisterProcess(std::string(demangled) + "::" + name,
                                      new ORTSingleProcess<T>((T*)this, fn));
      free(demangled);
    }

    ORVProcess() { ORAllProcesses::RegisterProcessClass(this); }
    virtual ~ORVProcess() { ORAllProcesses::UnRegisterProcessClass(this); }
    virtual void CallOnSocketClose() {}
  private:
    // Force all derived classes to be singletons
    ORVProcess(const ORVProcess& other);
    ORVProcess& operator=(const ORVProcess& other);
};
#endif /* __cplusplus */

#endif /* _ORVProcess_hh_ */
