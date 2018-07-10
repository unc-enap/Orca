#ifndef _ScopedLock_hh_
#define _ScopedLock_hh_
#include <pthread.h>

/*
 Usage is simply to define at the beginning of a function.
 e.g.
 pthread_mutex_t myMut;

 void Func()
 {
   ScopedLock sL(myMut);
   ..
 }

 Scoping rules will ensure that the mutex is released when the function is
 exited.

 */
class ScopedLock {
  public:
    ScopedLock(pthread_mutex_t& mut) :
      _mutex(mut)
    {
      pthread_mutex_lock(&_mutex);
    }

    ~ScopedLock()
    {
      pthread_mutex_unlock(&_mutex);
    }

  private:
    pthread_mutex_t& _mutex;
};

#endif
