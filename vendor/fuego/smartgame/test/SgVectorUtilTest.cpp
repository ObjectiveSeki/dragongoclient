//----------------------------------------------------------------------------
/** @file SgVectorUtilTest.cpp
    Unit tests for SgVectorUtil. */
//----------------------------------------------------------------------------

#include "SgSystem.h"

#include <boost/test/auto_unit_test.hpp>
#include "SgVectorUtil.h"

//----------------------------------------------------------------------------

namespace {

//----------------------------------------------------------------------------

void AddToVector(int from, int to, SgVector<int>& vector)
{
    for (int i = from; i <= to; ++i)
        vector.PushBack(i);
}

//----------------------------------------------------------------------------

BOOST_AUTO_TEST_CASE(SgVectorUtilTest_Difference)
{
    SgVector<int> a;
    a.PushBack(5);
    a.PushBack(6);
    a.PushBack(7);
    a.PushBack(8);
    a.PushBack(-56);
    a.PushBack(9);
    a.PushBack(10);
    SgVector<int> b;
    b.PushBack(8);
    b.PushBack(-56);
    b.PushBack(9);
    b.PushBack(10);
    b.PushBack(11);
    b.PushBack(12);
    SgVectorUtil::Difference(&a, b);
    BOOST_CHECK_EQUAL(a.Length(), 3);
    BOOST_CHECK_EQUAL(a[0], 5);
    BOOST_CHECK_EQUAL(a[1], 6);
    BOOST_CHECK_EQUAL(a[2], 7);
}

BOOST_AUTO_TEST_CASE(SgVectorUtilTest_Intersection)
{
    SgVector<int> a;
    AddToVector(5,10,a);
    SgVector<int> b;
    AddToVector(8,12,b);
    SgVectorUtil::Intersection(&a, b);
    BOOST_CHECK_EQUAL(a.Length(), 3);
    BOOST_CHECK_EQUAL(a[0], 8);
    BOOST_CHECK_EQUAL(a[1], 9);
    BOOST_CHECK_EQUAL(a[2], 10);
}

//----------------------------------------------------------------------------

} // namespace

//----------------------------------------------------------------------------

