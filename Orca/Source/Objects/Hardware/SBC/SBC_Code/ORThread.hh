#ifndef ORThread_hh
#define ORThread_hh
#include <pthread.h>

/*
 Virtual class defining an interface for threading. Note, see ORThread
 if you just want to bind a class member function!

 To use, derive from this class and overload InternalThreadEntry, e.g.

 class MyThreadClass : public ORVThread
 {
    ..
    protected:
      void InternalThreadEntry() {
        // Do Some work
      }
 };

 ...

  MyThreadClass c;
  c.StartInternalThread();

  // Wait for completion
  c.WaitForInternalThreadToExit();
*/
class ORVThread
{
public:
  virtual ~ORVThread(){}

  /** Returns true if the thread was successfully started, false if there was
  * an error starting the thread */
  bool StartInternalThread();
  /** Will not return until the internal thread has exited. */
  void WaitForInternalThreadToExit();
protected:
  /** Implement this method in your subclass with the code you want your
  * thread to run. */
  virtual void InternalThreadEntry() = 0;
  pthread_t _thread;

  static void *InternalThreadEntryFunc(void * This)
  {
   ((ORVThread *)This)->InternalThreadEntry();
   return NULL;
  }
};

/*
  Bind class member function to thread and execute.

  Usage:

  class MyClass {
    public:
      void Hello();
  };

  MyClass x;

  ORThread thread(&x, &MyClass::Hello);

  // Start
  thread.StartInternalThread();

  // Wait for completion.
  thread.WaitForInternalThreadToExit();
*/
template<class T>
class ORThread : public ORVThread
{
  public:
    typedef void (T::*memPtr) ();
    ORThread(T* var, memPtr fn) :
      _this(var),
      _fn(fn) {}

  protected:
    void InternalThreadEntry()
    {
      (*_this).*_fn();
    }
    T* _this;
    memPtr _fn;
};


#endif /* ORThread_hh */
