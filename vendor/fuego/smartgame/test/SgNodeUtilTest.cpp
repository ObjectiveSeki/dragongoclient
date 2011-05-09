//----------------------------------------------------------------------------
/** @file SgNodeUtilTest.cpp
    Unit tests for SgNodeUtil. */
//----------------------------------------------------------------------------

#include "SgSystem.h"

#include <boost/test/auto_unit_test.hpp>
#include "SgNode.h"
#include "SgNodeUtil.h"

//----------------------------------------------------------------------------

namespace {

//----------------------------------------------------------------------------

BOOST_AUTO_TEST_CASE(SgNodeUtilTest_RemovePropInSubtree)
{
    SgNode root;
    SgNode* node1 = root.NewRightMostSon();
    SgNode* node2 = root.NewRightMostSon();
    SgNode* node3 = node1->NewRightMostSon();
    SgNode* node4 = node3->NewRightMostSon();
    const SgPropID id = SG_PROP_COMMENT;
    root.SetStringProp(id, "");
    node2->SetStringProp(id, "");
    node4->SetStringProp(id, "");
    SgNodeUtil::RemovePropInSubtree(root, id);
    BOOST_CHECK(! root.HasProp(id));
    BOOST_CHECK(! node2->HasProp(id));
    BOOST_CHECK(! node4->HasProp(id));
    root.DeleteSubtree();
}

//----------------------------------------------------------------------------

} // namespace

