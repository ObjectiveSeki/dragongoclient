//----------------------------------------------------------------------------
/** @file SgMpiSynchronizer.cpp */
//----------------------------------------------------------------------------

#include "SgSystem.h"
#include "SgMpiSynchronizer.h"

using namespace std;

//-----------------------------------------------------------------------------

SgMpiSynchronizer::~SgMpiSynchronizer()
{
}

//-----------------------------------------------------------------------------

SgMpiNullSynchronizer::SgMpiNullSynchronizer() 
{
}

SgMpiNullSynchronizer::~SgMpiNullSynchronizer()
{
}

SgMpiSynchronizerHandle SgMpiNullSynchronizer::Create()
{
    return SgMpiSynchronizerHandle(new SgMpiNullSynchronizer());
}


string SgMpiNullSynchronizer::ToNodeFilename(const string &filename) const
{
    return filename;
}

bool SgMpiNullSynchronizer::IsRootProcess() const
{
    return true;
}

void SgMpiNullSynchronizer::OnStartSearch(SgUctSearch &search)
{
    SG_UNUSED(search);
}

void SgMpiNullSynchronizer::OnEndSearch(SgUctSearch &search)
{
    SG_UNUSED(search);
}

void SgMpiNullSynchronizer::OnThreadStartSearch(SgUctSearch &search, 
                                                SgUctThreadState &state)
{
    SG_UNUSED(search);
    SG_UNUSED(state);
}

void SgMpiNullSynchronizer::OnThreadEndSearch(SgUctSearch &search, 
                                              SgUctThreadState &state)
{
    SG_UNUSED(search);
    SG_UNUSED(state);
}

void SgMpiNullSynchronizer::OnSearchIteration(SgUctSearch &search, 
                                              SgUctValue gameNumber, 
                                              int threadId, 
                                              const SgUctGameInfo& info)
{
    SG_UNUSED(search);
    SG_UNUSED(gameNumber);
    SG_UNUSED(threadId);
    SG_UNUSED(info);
}

void SgMpiNullSynchronizer::OnStartPonder()
{
}

void SgMpiNullSynchronizer::OnEndPonder()
{
}

void SgMpiNullSynchronizer::WriteStatistics(ostream& out) const
{
    SG_UNUSED(out);
}

void SgMpiNullSynchronizer::SynchronizeUserAbort(bool &flag)
{
    SG_UNUSED(flag);
}

void SgMpiNullSynchronizer::SynchronizePassWins(bool &flag)
{
    SG_UNUSED(flag);
}


void SgMpiNullSynchronizer::SynchronizeEarlyPassPossible(bool &flag)
{
    SG_UNUSED(flag);
}


void SgMpiNullSynchronizer::SynchronizeMove(SgMove &move)
{
    SG_UNUSED(move);
}

void SgMpiNullSynchronizer::SynchronizeValue(SgUctValue &value)
{
    SG_UNUSED(value);
}

void SgMpiNullSynchronizer::SynchronizeSearchStatus(SgUctValue &value, 
                                                    bool &earlyAbort, 
                                                    SgUctValue &rootMoveCount)
{
    SG_UNUSED(value);
    SG_UNUSED(earlyAbort);
    SG_UNUSED(rootMoveCount);
}

//-----------------------------------------------------------------------------
