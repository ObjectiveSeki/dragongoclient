//----------------------------------------------------------------------------
/** @file SpMoveGenerator.cpp
    See SpMoveGenerator.h */
//----------------------------------------------------------------------------

#include "SgSystem.h"
#include "SpMoveGenerator.h"

#include <limits>
#include "GoMoveExecutor.h"
#include "GoModBoard.h"
#include "SgEvaluatedMoves.h"

using namespace std;

//----------------------------------------------------------------------------

void SpMoveGenerator::GenerateMoves(SgEvaluatedMoves& eval,
                                    SgBlackWhite toPlay)
{
    GoModBoard modBoard(m_board);
    GoBoard& bd = modBoard.Board();
    GoRestoreToPlay restoreToPlay(bd);
    bd.SetToPlay(toPlay);
    GoRestoreSuicide restoreSuicide(bd, false);
    for (SgSetIterator it(eval.Relevant()); it; ++it)
    {
        SgPoint p(*it);
        int score = EvaluateMove(p);
        if (score > numeric_limits<int>::min())
            eval.AddMove(p, score);
    }
}

int Sp1PlyMoveGenerator::EvaluateMove(SgPoint p)
{
    GoModBoard modBoard(m_board);
    GoBoard& bd = modBoard.Board();
    GoMoveExecutor execute(bd, p);
    if (execute.IsLegal())
        return Evaluate();
    else
        return numeric_limits<int>::min();
}

int SpStaticMoveGenerator::EvaluateMove(SgPoint p)
{
    if (m_board.IsLegal(p))
        return Score(p);
    else
        return numeric_limits<int>::min();
}


//----------------------------------------------------------------------------

