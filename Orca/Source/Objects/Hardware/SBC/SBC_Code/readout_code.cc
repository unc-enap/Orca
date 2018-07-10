#include "readout_code.h"
#include <map>
std::map<int32_t, ORVCard*> gSetOfCards;
std::map<int32_t, ORVCard*>::iterator gCardIterator;

// Following file pulls in the necessary readout initialization for this code
#include "HW_Specific.icc"

// Returns number of cards loaded.
int32_t readout_card(int32_t index, SBC_LAM_Data* lam_data)
{
  gCardIterator = gSetOfCards.find(index); 
  if (gCardIterator == gSetOfCards.end()) return -1;
  return (gCardIterator->second->ReadoutAndGetNextIndex(lam_data));
  
}

// Returns number of cards started.
int32_t start_card(int32_t index)
{
  gCardIterator = gSetOfCards.find(index); 
  if (gCardIterator == gSetOfCards.end()) return 0;
  gCardIterator->second->Start();
  return 1;
}

// Returns number of cards stopped.
int32_t stop_card(int32_t index)
{
  gCardIterator = gSetOfCards.find(index); 
  if (gCardIterator == gSetOfCards.end()) return 0;
  gCardIterator->second->Stop();
  return 1;
}

// Returns number of cards Paused.
int32_t pause_card(int32_t index)
{
	gCardIterator = gSetOfCards.find(index); 
	if (gCardIterator == gSetOfCards.end()) return 0;
	gCardIterator->second->Pause();
	return 1;
}
// Returns number of cards Paused.
int32_t resume_card(int32_t index)
{
	gCardIterator = gSetOfCards.find(index); 
	if (gCardIterator == gSetOfCards.end()) return 0;
	gCardIterator->second->Resume();
	return 1;
}

// Returns number of cards removed.
int32_t remove_card(int32_t index)
{
  gCardIterator = gSetOfCards.find(index); 
  if (gCardIterator == gSetOfCards.end()) return 0;
  delete gCardIterator->second;
  gSetOfCards.erase(gCardIterator);
  return 1;
}

ORVCard* peek_at_card(int32_t index)
{
  gCardIterator = gSetOfCards.find(index); 
  if (gCardIterator == gSetOfCards.end()) return NULL;
  return (gCardIterator->second);
}
