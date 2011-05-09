//----------------------------------------------------------------------------
/** @file SpCapturePlayer.h
    Simple player that captures whenever possible, otherwise plays randomly */
//----------------------------------------------------------------------------

#ifndef SP_CAPTUREPLAYER_H
#define SP_CAPTUREPLAYER_H

#include "SpSimplePlayer.h"
#include "SpMoveGenerator.h"

//----------------------------------------------------------------------------

/** Simple player that captures whenever possible, otherwise plays randomly */
class SpCaptureMoveGenerator
    : public Sp1PlyMoveGenerator
{
public:
    explicit SpCaptureMoveGenerator(const GoBoard& board)
        : Sp1PlyMoveGenerator(board)
    { }

    int Evaluate();
};

//----------------------------------------------------------------------------

/** Simple player using SpCaptureMoveGenerator */
class SpCapturePlayer
    : public SpSimplePlayer
{
public:
    SpCapturePlayer(const GoBoard& board)
        : SpSimplePlayer(board, new SpCaptureMoveGenerator(board))
    { }

    std::string Name() const
    {
        return "Capture";
    }
};

//----------------------------------------------------------------------------

#endif // SP_CAPTUREPLAYER_H

