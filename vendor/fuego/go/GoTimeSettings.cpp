//----------------------------------------------------------------------------
/** @file GoTimeSettings.cpp
    See GoTimeSettings.h */
//----------------------------------------------------------------------------

#include "SgSystem.h"
#include "GoTimeSettings.h"

//----------------------------------------------------------------------------

GoTimeSettings::GoTimeSettings()
    : m_mainTime(0),
      m_overtime(1),
      m_overtimeMoves(0)
{
    SG_ASSERT(IsUnknown());
}

GoTimeSettings::GoTimeSettings(double mainTime)
    : m_mainTime(mainTime),
      m_overtime(0)
{
}

GoTimeSettings::GoTimeSettings(double mainTime, double overtime,
                               int overtimeMoves)
    : m_mainTime(mainTime),
      m_overtime(overtime),
      m_overtimeMoves(overtimeMoves)
{
    SG_ASSERT(mainTime >= 0);
    SG_ASSERT(overtime >= 0);
    SG_ASSERT(overtimeMoves >= 0);
}

bool GoTimeSettings::operator==(const GoTimeSettings& timeSettings)
    const
{
    return (timeSettings.m_mainTime == m_mainTime
            && timeSettings.m_overtime == m_overtime
            && timeSettings.m_overtimeMoves == m_overtimeMoves);
}

bool GoTimeSettings::IsUnknown() const
{
    return (m_overtime > 0 && m_overtimeMoves == 0);
}

//----------------------------------------------------------------------------


