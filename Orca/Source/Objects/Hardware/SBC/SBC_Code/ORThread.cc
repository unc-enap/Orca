#include "ORThread.hh"

bool ORVThread::StartInternalThread()
{
   return (pthread_create(&_thread, NULL, InternalThreadEntryFunc, this) == 0);
}

void ORVThread::WaitForInternalThreadToExit()
{
   (void) pthread_join(_thread, NULL);
}



