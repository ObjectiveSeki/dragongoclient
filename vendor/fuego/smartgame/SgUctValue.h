//----------------------------------------------------------------------------
/** @file SgUctValue.h
    Defines the floating point type used in SgUctSearch */
//----------------------------------------------------------------------------

#ifndef SG_UCTVALUE_H
#define SG_UCTVALUE_H

#include <cmath>
#include <limits>
#include <boost/static_assert.hpp>
#include "SgStatistics.h"
#include "SgStatisticsVlt.h"

//----------------------------------------------------------------------------

/** @typedef SgUctValue
    The floating type used for mean values and counts in SgUctSearch.
    The default type is @c double, but it is possible to use @c float to reduce
    the node size and to get some performance gains (especially on 32-bit
    systems). However, using @c float sets a practical limit on the number of
    simulations before the count and mean values go into "saturation". This
    maximum is given by 2^d-1 with d being the digits in the mantissa (=23 for
    IEEE 754 float's). The search will terminate when this number is
    reached. */

#ifdef SG_UCT_VALUE_TYPE
typedef SG_UCT_VALUE_TYPE SgUctValue;
#else
typedef double SgUctValue;
#endif

BOOST_STATIC_ASSERT(! std::numeric_limits<SgUctValue>::is_integer);

typedef SgStatisticsBase<SgUctValue,SgUctValue> SgUctStatistics;

typedef SgStatisticsVltBase<SgUctValue,SgUctValue> SgUctStatisticsVolatile;

//----------------------------------------------------------------------------

namespace SgUctValueUtil
{

/** Check if floating point value is a precise representation of an integer.
    When SgUctValue is used for counts, the search should abort when the
    value is no longer precise, because incrementing it further will not
    change its value anymore.
    @tparam T The floating point type
    @return @c true if value is less or equal @f$ r^d - 1 @f$ (<i>r</i>:
    radix, <i>d</i>: number of the digits in the mantissa of the type) */
template<typename T>
inline bool IsPrecise(T val)
{
    const int radix = std::numeric_limits<T>::radix;
    const int digits = std::numeric_limits<T>::digits;
    const T max = std::pow(T(radix), digits) - 1;
    return val <= max;
}

}

//----------------------------------------------------------------------------

#endif // SG_UCTVALUE_H
