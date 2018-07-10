#include "ORVProcess.hh"
#include <cstring>
extern "C" {
#include "SBC_Readout.h"
}

ORAllProcesses& ORAllProcesses::GetAllProcesses()
{
  // Get the singleton object
  static ORAllProcesses* gAllProc = new ORAllProcesses();
  return *gAllProc;
}

void ORAllProcesses::RegisterProcess(const std::string& procName,
                                     ORVSingleProcess* proc)
{
  // Actually register a particular process
  GetAllProcesses()._procMap[procName] = proc;
}

void ORAllProcesses::RegisterProcessClass(ORVProcess* proc)
{
  // Actually register a particular process
  GetAllProcesses()._procSet.insert(proc);
}

void ORAllProcesses::UnRegisterProcessClass(ORVProcess* proc)
{
  // Actually register a particular process
  GetAllProcesses()._procSet.erase(proc);
}

void ORAllProcesses::SocketClose()
{
  // Actually register a particular process
  ProcSet& ps = GetAllProcesses()._procSet;
  ProcSet::iterator iter = ps.begin();
  for (;iter != ps.end();iter++) (*iter)->CallOnSocketClose();
}

void ORAllProcesses::CallProcess(const std::string& procName,
                                 SBC_Packet* packet)
{
  // Call the process, if it's been registered
  ORAllProcesses::ProcMap& pm = GetAllProcesses()._procMap;
  if (pm.find(procName) != pm.end()) {
    pm[procName]->Call(packet);
  } else {
    std::string error_msg = procName + " not found!";
    size_t save_len = (error_msg.size() + 1 > sizeof(packet->message)) ?
      sizeof(packet->message) : error_msg.size() + 1;
    strncpy(packet->message, error_msg.c_str(), save_len);
  }
  writeBuffer(packet);
}

extern "C" void doGenericJob(SBC_Packet* packet)
{
  // We grab the name from the message, note this should be of the form:
  //
  // ClassName::FuncName
  ORAllProcesses::CallProcess(packet->message, packet);
}

extern "C" void doGenericJobSocketClose()
{
  // We grab the name from the message, note this should be of the form:
  //
  // ClassName::FuncName
  ORAllProcesses::SocketClose();
}
