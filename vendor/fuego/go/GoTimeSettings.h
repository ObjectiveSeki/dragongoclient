//----------------------------------------------------------------------------
/** @file GoTimeSettings.h
    Time settings for a Go game. */
//----------------------------------------------------------------------------

#ifndef GO_TIMESETTINGS_H
#define GO_TIMESETTINGS_H

//----------------------------------------------------------------------------

/** Time settings for a Go game. */
class GoTimeSettings
{
public:
    /** Construct time settings with no time limit. */
    GoTimeSettings();

    GoTimeSettings(double mainTime);

    /** Construct time settings.
        Currently supports Canadian byo yomi, including absolute time (no byo
        yomi) as a special case.
        @param mainTime Main time measured in seconds.
        @param overtime Byo yomi time measured in seconds.
        @param overtimeMoves Number of stones per byo yomi period. */
    GoTimeSettings(double mainTime, double overtime, int overtimeMoves);

    bool operator==(const GoTimeSettings& timeSettings) const;

    double MainTime() const;

    double Overtime() const;

    int OvertimeMoves() const;

    bool IsUnknown() const;

private:
    /** Main time measured in seconds. */
    double m_mainTime;

    /** Byo yomi time measured in seconds. */
    double m_overtime;

    /** Number of stones per byo yomi period. */
    int m_overtimeMoves;
};

inline double GoTimeSettings::MainTime() const
{
    return m_mainTime;
}

inline double GoTimeSettings::Overtime() const
{
    return m_overtime;
}

inline int GoTimeSettings::OvertimeMoves() const
{
    return m_overtimeMoves;
}

//----------------------------------------------------------------------------

#endif // GO_TIMESETTINGS_H

