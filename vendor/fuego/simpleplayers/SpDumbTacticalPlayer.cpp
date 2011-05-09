//----------------------------------------------------------------------------
/** @file SpDumbTacticalPlayer.cpp
    See SpDumbTacticalPlayer.h */
//----------------------------------------------------------------------------

#include "SgSystem.h"
#include "SpDumbTacticalPlayer.h"

#include "GoBensonSolver.h"
#include "GoBoardUtil.h"
#include "GoLadder.h"
#include "GoModBoard.h"
#include "SgEvaluatedMoves.h"
#include "SgNbIterator.h"

using GoLadderUtil::LadderStatus;

//----------------------------------------------------------------------------

SpDumbTacticalMoveGenerator::SpDumbTacticalMoveGenerator(const GoBoard& board)
    : SpStaticMoveGenerator(board), m_useLadders(false)
{ }
    
int SpDumbTacticalMoveGenerator::Score(SgPoint p)
{
    SG_UNUSED(p);
    // DumbTacticalMoveGenerator uses whole-board move generation, 
    // it does not work by scoring individual moves.
    SG_ASSERT(false);
    return INT_MIN; 
}

void SpDumbTacticalMoveGenerator::GenerateMoves(SgEvaluatedMoves& eval,
                                                SgBlackWhite toPlay)
{
    GoModBoard modBoard(m_board);
    GoBoard& bd = modBoard.Board();
    GoRestoreToPlay restoreToPlay(bd);
    bd.SetToPlay(toPlay);
    // Don't permit player to kill its own groups.
    GoRestoreSuicide restoreSuicide(bd, false);
    GenerateDefendMoves(eval);
    GenerateAttackMoves(eval);
    // Otherwise make a random legal move that doesn't fill own eye
    // This will be done automatically by the simple player if no moves
    // have been generated.
}

void SpDumbTacticalMoveGenerator::GenerateDefendMoves(SgEvaluatedMoves& eval)
{
    const int stoneweight = 1000;
    // Do any of own blocks have just one liberty?
    for (GoBlockIterator anchorit(m_board); anchorit; ++anchorit)
    {
        // Ignore opponent blocks
        if (m_board.IsColor(*anchorit, m_board.Opponent()))
            continue;

        // Try to save blocks in atari
        if (! m_board.InAtari(*anchorit))
            continue;
        
        // Don't waste saving blocks that will be laddered to death anyway
        if (m_useLadders)
        {
            GoLadderStatus status = LadderStatus(m_board, *anchorit, false);
            if (status == GO_LADDER_CAPTURED)
                continue;
        }
        
        int score = stoneweight * m_board.NumStones(*anchorit);

        // Generate liberty
        eval.AddMove(m_board.TheLiberty(*anchorit), score);
        
        // Generate any captures that will save the group
        for (GoAdjBlockIterator<GoBoard> adjbit(m_board, *anchorit, 1);
             adjbit; ++adjbit)
        {
            int bonus = stoneweight * m_board.NumStones(*adjbit);
            if (m_board.InAtari(*adjbit)) 
            // should always be true but just in case
            {
                eval.AddMove(m_board.TheLiberty(*adjbit), score + bonus);
            }
        }
    }
}

void SpDumbTacticalMoveGenerator::GenerateAttackMoves(SgEvaluatedMoves& eval)
{
    const int capturestoneweight = 100;
    const int firstlibweight = 100;
    const int secondlibweight = 20;
    const int stoneweight = 1;

    // Do Benson life test
    SgBWSet safepoints;
    GoModBoard modBoard(m_board);
    GoBoard& bd = modBoard.Board();
    GoBensonSolver benson(bd);
    benson.FindSafePoints(&safepoints);
    
    // Find opponent blocks without two eyes (using Benson algorithm)
    for (GoBlockIterator anchorit(bd); anchorit; ++anchorit)
    {
        // Ignore own blocks
        if (bd.IsColor(*anchorit, bd.ToPlay()))
            continue;
        
        // Ignore opponent blocks that are unconditionally alive
        if (safepoints[bd.Opponent()].Contains(*anchorit))
            continue;

        // Generate all ladder captures
        if (m_useLadders)
        {
            SgPoint tocapture, toescape;
            GoLadderStatus status = LadderStatus(bd, *anchorit, false,
                                                 &tocapture, &toescape);
            if (status == GO_LADDER_CAPTURED)
            {
                int score = bd.NumStones(*anchorit) * capturestoneweight;
                eval.AddMove(tocapture, score);
            }
        }
            
        // Score according to:
        // 1. -First liberties
        // 2. +Second liberties
        // 3. +Size of group
        // [4]. Own liberties?
        int firstlibs = bd.NumLiberties(*anchorit);
        int size = bd.NumStones(*anchorit);
        for (GoBoard::LibertyIterator libit(bd, *anchorit); libit;
             ++libit)
        {
            int secondlibs = 0;
            for (SgNb4Iterator nbit(*libit); nbit; ++nbit)
            {
                if (bd.IsValidPoint(*nbit) && bd.IsEmpty(*nbit))
                {
                    secondlibs++;
                }
            }
            int score   = size * stoneweight
                        + secondlibs * secondlibweight
                        - firstlibs * firstlibweight;
            eval.AddMove(*libit, score);
        }
    }
}


