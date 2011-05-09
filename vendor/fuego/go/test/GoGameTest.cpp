//----------------------------------------------------------------------------
/** @file GoGameTest.cpp
    Unit tests for GoGame. */
//----------------------------------------------------------------------------

#include "SgSystem.h"

#include <boost/test/auto_unit_test.hpp>
#include <boost/test/floating_point_comparison.hpp>
#include "GoGame.h"

using namespace std;
using SgPointUtil::Pt;

//----------------------------------------------------------------------------

namespace {

//----------------------------------------------------------------------------

/** Test executing and undoing a node with setup stones. */
BOOST_AUTO_TEST_CASE(GoGameTest_SetupPosition)
{
    GoGame game;
    SgBWArray<SgPointSet> stones;
    stones[SG_BLACK].Include(Pt(1, 1));
    stones[SG_WHITE].Include(Pt(2, 2));
    stones[SG_WHITE].Include(Pt(3, 3));
    game.SetupPosition(stones);
    const GoBoard& bd = game.Board();
    BOOST_CHECK_EQUAL(SG_BLACK, bd.GetColor(Pt(1, 1)));
    BOOST_CHECK_EQUAL(SG_WHITE, bd.GetColor(Pt(2, 2)));
    BOOST_CHECK_EQUAL(SG_WHITE, bd.GetColor(Pt(3, 3)));
    game.GoToNode(game.CurrentNode()->Father());
    BOOST_CHECK_EQUAL(SG_EMPTY, bd.GetColor(Pt(1, 1)));
    BOOST_CHECK_EQUAL(SG_EMPTY, bd.GetColor(Pt(2, 2)));
    BOOST_CHECK_EQUAL(SG_EMPTY, bd.GetColor(Pt(3, 3)));
}

//----------------------------------------------------------------------------

} // namespace
