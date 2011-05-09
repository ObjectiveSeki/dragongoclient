//----------------------------------------------------------------------------
/** @file GoUctDefaultPriorKnowledge.cpp
    See GoUctDefaultPriorKnowledge.h */
//----------------------------------------------------------------------------

#include "SgSystem.h"
#include "GoUctDefaultPriorKnowledge.h"

using namespace std;

//----------------------------------------------------------------------------

namespace {

bool SetsAtari(const GoBoard& bd, SgPoint p)
{
    SG_ASSERT(bd.IsEmpty(p)); // Already checked
    SgBlackWhite opp = SgOppBW(bd.ToPlay());
    if (bd.NumNeighbors(p, opp) == 0)
        return false;
    if (! bd.IsBorder(p + SG_NS) && bd.GetColor(p + SG_NS) == opp
        && bd.NumLiberties(p + SG_NS) == 2)
        return true;
    if (! bd.IsBorder(p - SG_NS) && bd.GetColor(p - SG_NS) == opp
        && bd.NumLiberties(p - SG_NS) == 2)
        return true;
    if (! bd.IsBorder(p + SG_WE) && bd.GetColor(p + SG_WE) == opp
        && bd.NumLiberties(p + SG_WE) == 2)
        return true;
    if (! bd.IsBorder(p - SG_WE) && bd.GetColor(p - SG_WE) == opp
        && bd.NumLiberties(p - SG_WE) == 2)
        return true;
    return false;
}

} // namespace

//----------------------------------------------------------------------------

GoUctKnowledge::GoUctKnowledge(const GoBoard& bd)
    : m_bd(bd)
{
}

GoUctKnowledge::~GoUctKnowledge()
{
}

void GoUctKnowledge::Add(SgPoint p, SgUctValue value, SgUctValue count)
{
    m_values[p].Add(value, count);
}

void GoUctKnowledge::Initialize(SgPoint p, SgUctValue value, SgUctValue count)
{
    m_values[p].Initialize(value, count);
}

void GoUctKnowledge::ClearValues()
{
    for (int i = 0; i < SG_PASS + 1; ++i)
        m_values[i].Clear();
}

void GoUctKnowledge::TransferValues(std::vector<SgUctMoveInfo>& outmoves) const
{
    for (std::size_t i = 0; i < outmoves.size(); ++i) 
    {
        SgMove p = outmoves[i].m_move;
        if (m_values[p].IsDefined())
        {
            outmoves[i].m_count = m_values[p].Count();
            outmoves[i].m_value =
                 SgUctSearch::InverseEstimate(m_values[p].Mean());
            outmoves[i].m_raveCount = m_values[p].Count();
            outmoves[i].m_raveValue = m_values[p].Mean();
        }
    }
}

//----------------------------------------------------------------------------

GoUctDefaultPriorKnowledge::GoUctDefaultPriorKnowledge(const GoBoard& bd,
                              const GoUctPlayoutPolicyParam& param)
    : GoUctKnowledge(bd),
      m_policy(bd, param)
{
}

void GoUctDefaultPriorKnowledge::AddLocalityBonus(GoPointList& emptyPoints,
                                                  bool isSmallBoard)
{
    SgPoint last = m_bd.GetLastMove();
    if (last != SG_NULLMOVE && last != SG_PASS)
    {
        SgPointArray<int> dist = GoBoardUtil::CfgDistance(m_bd, last, 3);
        const SgUctValue count = (isSmallBoard ? 4 : 5);
        for (GoPointList::Iterator it(emptyPoints); it; ++it)
        {
            const SgPoint p = *it;
            switch (dist[p])
            {
            case 1:
                Add(p, SgUctValue(1.0), count);
                break;
            case 2:
                Add(p, SgUctValue(0.6), count);
                break;
            case 3:
                Add(p, SgUctValue(0.6), count);
                break;
            default:
                Add(p, SgUctValue(0.1), count);
                break;
            }
        }
        Add(SG_PASS, SgUctValue(0.1), count);
    }
}

/** Find global moves that match a playout pattern or set a block into atari.
    @param[out] pattern
    @param[out] atari
    @param[out] empty As a side effect, this function finds all empty points
    on the board
    @return @c true if any such moves was found */
bool GoUctDefaultPriorKnowledge::FindGlobalPatternAndAtariMoves(
                                                     SgPointSet& pattern,
                                                     SgPointSet& atari,
                                                     GoPointList& empty) const
{
    SG_ASSERT(empty.IsEmpty());
    const GoUctPatterns<GoBoard>& patterns = m_policy.Patterns();
    bool result = false;
    for (GoBoard::Iterator it(m_bd); it; ++it)
        if (m_bd.IsEmpty(*it))
        {
            empty.PushBack(*it);
            if (patterns.MatchAny(*it))
            {
                pattern.Include(*it);
                result = true;
            }
            if (SetsAtari(m_bd, *it))
            {
                atari.Include(*it);
                result = true;
            }
        }
    return result;
}

void 
GoUctDefaultPriorKnowledge::ProcessPosition(std::vector<SgUctMoveInfo>& outmoves)
{
    m_policy.StartPlayout();
    m_policy.GenerateMove();
    GoUctPlayoutPolicyType type = m_policy.MoveType();
    bool isFullBoardRandom =
        (type == GOUCT_RANDOM || type == GOUCT_FILLBOARD);
    SgPointSet pattern;
    SgPointSet atari;
    GoPointList empty;
    bool anyHeuristic = FindGlobalPatternAndAtariMoves(pattern, atari, empty);

    // The initialization values/counts are mainly tuned by selfplay
    // experiments and games vs MoGo Rel 3 and GNU Go 3.6 on 9x9 and 19x19.
    // If different values are used for the small and large board, the ones
    // from the 9x9 experiments are used for board sizes < 15, the ones from
    // 19x19 otherwise.
    const bool isSmallBoard = (m_bd.Size() < 15);

    Initialize(SG_PASS, 0.1f, isSmallBoard ? 9 : 18);
    if (isFullBoardRandom && ! anyHeuristic)
    {
        for (GoBoard::Iterator it(m_bd); it; ++it)
        {
            SgPoint p = *it;
            if (! m_bd.IsEmpty(p))
                continue;
            if (GoBoardUtil::SelfAtari(m_bd, *it))
                Initialize(*it, 0.1f, isSmallBoard ? 9 : 18);
            else
                m_values[p].Clear(); // Don't initialize
        }
    }
    else if (isFullBoardRandom && anyHeuristic)
    {
        for (GoBoard::Iterator it(m_bd); it; ++it)
        {
            SgPoint p = *it;
            if (! m_bd.IsEmpty(p))
                continue;
            if (GoBoardUtil::SelfAtari(m_bd, *it))
                Initialize(*it, 0.1f, isSmallBoard ? 9 : 18);
            else if (atari[*it])
                Initialize(*it, 1.0f, 3);
            else if (pattern[*it])
                Initialize(*it, 0.9f, 3);
            else
                Initialize(*it, 0.5f, 3);
        }
    }
    else
    {
        for (GoBoard::Iterator it(m_bd); it; ++it)
        {
            SgPoint p = *it;
            if (! m_bd.IsEmpty(p))
                continue;
            if (GoBoardUtil::SelfAtari(m_bd, *it))
                Initialize(*it, 0.1f, isSmallBoard ? 9 : 18);
            else if (atari[*it])
                Initialize(*it, 0.8f, isSmallBoard ? 9 : 18);
            else if (pattern[*it])
                Initialize(*it, 0.6f, isSmallBoard ? 9 : 18);
            else
                Initialize(*it, 0.4f, isSmallBoard ? 9 : 18);
        }
        GoPointList moves = m_policy.GetEquivalentBestMoves();
        for (GoPointList::Iterator it(moves); it; ++it)
            Initialize(*it, 1.0, isSmallBoard ? 9 : 18);
    }
    AddLocalityBonus(empty, isSmallBoard);
    m_policy.EndPlayout();

    TransferValues(outmoves);
}

//----------------------------------------------------------------------------
