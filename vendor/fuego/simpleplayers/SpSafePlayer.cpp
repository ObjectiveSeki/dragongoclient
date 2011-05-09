//----------------------------------------------------------------------------
/** @file SpSafePlayer.cpp
    See SpSafePlayer.h */
//----------------------------------------------------------------------------

#include "SgSystem.h"
#include "SpSafePlayer.h"

#include "GoModBoard.h"
#include "GoSafetySolver.h"

//----------------------------------------------------------------------------

int SpSafeMoveGenerator::Evaluate()
{   
    GoModBoard modBoard(m_board);
    GoBoard& bd = modBoard.Board();
    GoSafetySolver s(bd);
    SgBWSet safe;
    s.FindSafePoints(&safe);
    
    // We are Opponent since this is after executing our move
    SgBlackWhite player = m_board.Opponent();
    return safe[player].Size() - safe[SgOppBW(player)].Size();
}


