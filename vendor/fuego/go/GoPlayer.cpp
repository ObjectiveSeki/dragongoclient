//----------------------------------------------------------------------------
/** @file GoPlayer.cpp
    See GoPlayer.h */
//----------------------------------------------------------------------------

#include "SgSystem.h"
#include "GoPlayer.h"

#include <limits>
#include "GoBoard.h"
#include "SgNode.h"

using namespace std;

//----------------------------------------------------------------------------

GoPlayer::GoPlayer(const GoBoard& bd)
    : GoBoardSynchronizer(bd),
      m_currentNode(0),
      m_bd(bd.Size(), GoSetup(), bd.Rules()),
      m_variant(0)
{
    SetSubscriber(m_bd);
    ClearSearchTraces();
}

GoPlayer::~GoPlayer()
{
    if (m_currentNode != 0)
        m_currentNode->DeleteTree();
}

void GoPlayer::ClearSearchTraces()
{
    if (m_currentNode != 0)
        m_currentNode->DeleteTree();
    m_currentNode = new SgNode();
    m_currentNode->AddComment("Search traces");
}

int GoPlayer::MoveValue(SgPoint p)
{
    SG_UNUSED(p);
    return numeric_limits<int>::min();
}

std::string GoPlayer::Name() const
{
    return "Unknown";
}

void GoPlayer::OnGameFinished()
{
}

void GoPlayer::OnNewGame()
{
}

void GoPlayer::Ponder()
{
}

SgNode* GoPlayer::TransferSearchTraces()
{
    SgNode* node = m_currentNode;
    if (node->NumSons() == 0)
        return 0;
    m_currentNode = 0;
    ClearSearchTraces();
    return node;
}

//----------------------------------------------------------------------------

