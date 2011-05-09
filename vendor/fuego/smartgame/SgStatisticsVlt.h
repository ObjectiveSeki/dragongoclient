//----------------------------------------------------------------------------
/** @file SgStatisticsVlt.h
    Specialized versions of some classes in SgStatistics.h for volatile
    member variables. Previous versions of Fuego used instantiations like
    @c SgStatisticsBase<volatile double,volatile double>, but this has the
    effect that local variables in member functions and types in explicit
    conversions also use the volatile qualifier, and it caused a warning with
    Visual C++ (C4197: top-level volatile in cast is ignored). Unfortunately,
    the only way to avoid this is to create exact copies of the classes in
    SgStatistics with the only difference that the member variables are
    declared volatile. */
//----------------------------------------------------------------------------

#ifndef SG_STATISTICSVLT_H
#define SG_STATISTICSVLT_H

#include <cmath>
#include <iostream>
#include <limits>
#include <map>
#include <sstream>
#include <string>
#include <vector>
#include "SgException.h"
#include "SgWrite.h"

//----------------------------------------------------------------------------

/** Specialized version of SgStatisticsBase for volatile member variables.
    @see SgStatisticsVlt.h SgStatisticsBase */
template<typename VALUE, typename COUNT>
class SgStatisticsVltBase
{
public:
    SgStatisticsVltBase();

    /** Create statistics initialized with values.
        Note that value must be initialized to 0 if count is 0.
        Equivalent to creating a statistics and calling @c count times
        Add(val) */
    SgStatisticsVltBase(VALUE val, COUNT count);

    void Add(VALUE val);

    void Remove(VALUE val);

    /** Add a value n times */
    void Add(VALUE val, COUNT n);

    /** Remove a value n times. */
    void Remove(VALUE val, COUNT n);

    void Clear();

    COUNT Count() const;

    /** Initialize with values.
        Equivalent to calling Clear() and calling @c count times
        Add(val) */
    void Initialize(VALUE val, COUNT count);

    /** Check if the mean value is defined.
        The mean value is defined, if the count if greater than zero. The
        result of this function is equivalent to <tt>Count() > 0</tt>, for
        integer count types and <tt>Count() > epsilon()</tt> for floating
        point count types. */
    bool IsDefined() const;

    VALUE Mean() const;

    /** Write in human readable format. */
    void Write(std::ostream& out) const;

    /** Save in a compact platform-independent text format.
        The data is written in a single line, without trailing newline. */
    void SaveAsText(std::ostream& out) const;

    /** Load from text format.
        See SaveAsText() */
    void LoadFromText(std::istream& in);

private:
    volatile COUNT m_count;

    volatile VALUE m_mean;
};

template<typename VALUE, typename COUNT>
inline SgStatisticsVltBase<VALUE,COUNT>::SgStatisticsVltBase()
{
    Clear();
}

template<typename VALUE, typename COUNT>
inline SgStatisticsVltBase<VALUE,COUNT>::SgStatisticsVltBase(VALUE val, COUNT count)
    : m_count(count),
      m_mean(val)
{
}

template<typename VALUE, typename COUNT>
void SgStatisticsVltBase<VALUE,COUNT>::Add(VALUE val)
{
    // Write order dependency: at least one class (SgUctSearch in lock-free
    // mode) uses SgStatisticsVltBase concurrently without locking and assumes
    // that m_mean is valid, if m_count is greater zero
    COUNT count = m_count;
    ++count;
    SG_ASSERT(! std::numeric_limits<COUNT>::is_exact
              || count > 0); // overflow
    val -= m_mean;
    m_mean +=  val / VALUE(count);
    m_count = count;
}

template<typename VALUE, typename COUNT>
void SgStatisticsVltBase<VALUE,COUNT>::Remove(VALUE val)
{
    // Write order dependency: at least on class (SgUctSearch in lock-free
    // mode) uses SgStatisticsVltBase concurrently without locking and assumes
    // that m_mean is valid, if m_count is greater zero
    COUNT count = m_count;
    if (count > 1) 
    {
        --count;
        m_mean += (m_mean - val) / VALUE(count);
        m_count = count;
    }
    else
        Clear();
}

template<typename VALUE, typename COUNT>
void SgStatisticsVltBase<VALUE,COUNT>::Remove(VALUE val, COUNT n)
{
    // Write order dependency: at least on class (SgUctSearch in lock-free
    // mode) uses SgStatisticsVltBase concurrently without locking and assumes
    // that m_mean is valid, if m_count is greater zero
    COUNT count = m_count;
    if (count > n) 
    {
        count -= n;
        m_mean += VALUE(n) * (m_mean - val) / VALUE(count);
        m_count = count;
    }
    else
        Clear();
}

template<typename VALUE, typename COUNT>
void SgStatisticsVltBase<VALUE,COUNT>::Add(VALUE val, COUNT n)
{
    // Write order dependency: at least one class (SgUctSearch in lock-free
    // mode) uses SgStatisticsVltBase concurrently without locking and assumes
    // that m_mean is valid, if m_count is greater zero
    COUNT count = m_count;
    count += n;
    SG_ASSERT(! std::numeric_limits<COUNT>::is_exact
              || count > 0); // overflow
    val -= m_mean;
    m_mean +=  VALUE(n) * val / VALUE(count);
    m_count = count;
}

template<typename VALUE, typename COUNT>
inline void SgStatisticsVltBase<VALUE,COUNT>::Clear()
{
    m_count = 0;
    m_mean = 0;
}

template<typename VALUE, typename COUNT>
inline COUNT SgStatisticsVltBase<VALUE,COUNT>::Count() const
{
    return m_count;
}

template<typename VALUE, typename COUNT>
inline void SgStatisticsVltBase<VALUE,COUNT>::Initialize(VALUE val, COUNT count)
{
    SG_ASSERT(count > 0);
    m_count = count;
    m_mean = val;
}

template<typename VALUE, typename COUNT>
inline bool SgStatisticsVltBase<VALUE,COUNT>::IsDefined() const
{
    if (std::numeric_limits<COUNT>::is_exact)
        return m_count > 0;
    else
        return m_count > std::numeric_limits<COUNT>::epsilon();
}

template<typename VALUE, typename COUNT>
void SgStatisticsVltBase<VALUE,COUNT>::LoadFromText(std::istream& in)
{
    in >> m_count >> m_mean;
}

template<typename VALUE, typename COUNT>
inline VALUE SgStatisticsVltBase<VALUE,COUNT>::Mean() const
{
    SG_ASSERT(IsDefined());
    return m_mean;
}

template<typename VALUE, typename COUNT>
void SgStatisticsVltBase<VALUE,COUNT>::Write(std::ostream& out) const
{
    if (IsDefined())
        out << Mean();
    else
        out << '-';
}

template<typename VALUE, typename COUNT>
void SgStatisticsVltBase<VALUE,COUNT>::SaveAsText(std::ostream& out) const
{
    out << m_count << ' ' << m_mean;
}

//----------------------------------------------------------------------------

#endif // SG_STATISTICSVLT_H
