//----------------------------------------------------------------------------
/** @file SpLadderPlayer.cpp
    See SpLadderPlayer.h */
//----------------------------------------------------------------------------

#include "SgSystem.h"
#include "SpLadderPlayer.h"

#include "GoLadder.h"
#include "GoMoveExecutor.h"
#include "GoModBoard.h"
#include "SgConnCompIterator.h"
#include "SgEvaluatedMoves.h"

using GoLadderUtil::LadderStatus;

//----------------------------------------------------------------------------

int SpLadderMoveGenerator::Score(SgPoint p)
{
    SG_UNUSED(p);
    // LadderMoveGenerator uses direct move generation, 
    // it does not work by executing moves and calling Score().
    SG_ASSERT(false);
    return INT_MIN;
}

void SpLadderMoveGenerator::GenerateMoves(SgEvaluatedMoves& eval,
                                          SgBlackWhite toPlay)
{
    GoModBoard modBoard(m_board);
    GoBoard& bd = modBoard.Board();
    // Don't permit player to kill its own groups.
    GoRestoreToPlay restoreToPlay(bd);
    bd.SetToPlay(toPlay);
    GoRestoreSuicide restoreSuicide(bd, false);
    for (SgBlackWhite color = SG_BLACK; color <= SG_WHITE; ++color)
    {
        for (SgConnCompIterator it(bd.All(color), bd.Size());
             it; ++it)
        {
            SgPointSet block(*it);
            SgPoint p = block.PointOf(), toCapture, toEscape; 
            GoLadderStatus st = LadderStatus(bd, p, false, &toCapture,
                                             &toEscape);
            if (st == GO_LADDER_UNSETTLED)
            {
                SgPoint move =
                    color == bd.ToPlay() ? toEscape : toCapture;
                int size = 1000 * block.Size();
                eval.AddMove(move, size);
                if ((color == bd.ToPlay()) && (move == SG_PASS))
                {
                    // try liberties
                    for (GoBoard::LibertyIterator it(bd, p); it; ++it)
                    {
                        SgPoint lib = *it;
                        GoMoveExecutor m(bd, lib, color);
                        if (m.IsLegal() && bd.Occupied(p))
                        {
                            SgPoint toCapture2, toEscape2; 
                            GoLadderStatus st2 =
                                LadderStatus(bd, p, false, &toCapture2,
                                             &toEscape2);
                            if (st2 == GO_LADDER_ESCAPED)
                                eval.AddMove(lib, size);
                        }
                    }
                }
            }
        }
    }
}

//----------------------------------------------------------------------------

