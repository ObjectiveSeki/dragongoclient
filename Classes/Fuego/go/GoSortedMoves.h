//----------------------------------------------------------------------------
/** @file GoSortedMoves.h
    Specialization of SgSortedMoves for Go: move = SgMove, value = int.

    Move tables are used to store a small number of best moves. They
    have the usual operations Insert, Delete, etc.
*/
//----------------------------------------------------------------------------
#ifndef GO_SORTEDMOVES_H
#define GO_SORTEDMOVES_H

#include "SgMove.h"
#include "SgSortedMoves.h"

#define normalRange 3
#define maxMoveRange 20

/** Specialization of SgSortedMoves for Go: move = SgMove, value = int */
class GoSortedMoves : public SgSortedMoves<SgMove, int, maxMoveRange>
{
public:
    GoSortedMoves() :
        SgSortedMoves<SgMove, int, maxMoveRange>(normalRange)
    {
        SetInitLowerBound(1);
        SetLowerBound(1);
    }
    explicit GoSortedMoves(int maxNuMoves) : 
        SgSortedMoves<SgMove, int, maxMoveRange>(maxNuMoves)
    {
        SetInitLowerBound(1);
        SetLowerBound(1);
    }
    
    void Clear()
    {
        SgSortedMoves<SgMove, int, maxMoveRange>::Clear();
        SetInitLowerBound(1);
        SetLowerBound(1);
    }
};

#endif // GO_SORTEDMOVES_H

