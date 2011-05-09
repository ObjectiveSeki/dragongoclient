//----------------------------------------------------------------------------
/** @file SgTime.cpp
    See SgTime.h. */
//----------------------------------------------------------------------------

#include "SgSystem.h"
#include "SgTime.h"

#include <cstring>
#include <ctime>
#include <iomanip>
#include <limits>
#include <iostream>
#include <sstream>
#include <errno.h>
#if WIN32
#include <Windows.h>
#else
#include <sys/times.h>
#include <unistd.h>
#endif
#include <boost/date_time/posix_time/posix_time.hpp>
#include "SgException.h"

using namespace std;
using boost::posix_time::microsec_clock;
using boost::posix_time::ptime;
using boost::posix_time::time_duration;

//----------------------------------------------------------------------------

namespace {

SgTimeMode g_defaultMode = SG_TIME_REAL;

bool g_isInitialized = false;

ptime g_start;

#if ! WIN32
clock_t g_ticksPerSecond;

clock_t g_ticksPerMinute;
#endif

void Init()
{
#if ! WIN32
    long ticksPerSecond = sysconf(_SC_CLK_TCK);
    if (ticksPerSecond < 0) // Shouldn't happen
        throw SgException("Could not get _SC_CLK_TCK.");
    g_ticksPerSecond = static_cast<clock_t>(ticksPerSecond);
    g_ticksPerMinute = 60 * g_ticksPerSecond;
#endif
    g_start = microsec_clock::universal_time();
    g_isInitialized = true;
}

} // namespace

//----------------------------------------------------------------------------

string SgTime::Format(double time, bool minsAndSecs)
{
    ostringstream out;
    if (minsAndSecs)
    {
        int mins = static_cast<int>(time / 60);
        int secs = static_cast<int>(time - mins * 60);
        out << setw(2) << mins << ':' << setw(2) << setfill('0') 
            << secs;
    }
    else
        out << setprecision(2) << fixed << time;
    return out.str();
}

double SgTime::Get()
{
    return Get(g_defaultMode);
}

double SgTime::Get(SgTimeMode mode)
{
    if (! g_isInitialized)
        Init();
    switch (mode)
    {
    case SG_TIME_CPU:
        {
#if WIN32
            FILETIME creationTime;
            FILETIME exitTime;
            FILETIME kernelTime;
            FILETIME userTime;
            HANDLE handle = GetCurrentProcess();
            if (! GetProcessTimes(handle, &creationTime, &exitTime, &kernelTime, &userTime))
                throw SgException("GetProcessTimes() returned an error");
            // Do not cast FILETIME to ULARGE_INTEGER because it can cause alignment
            // faults on 64-bit Windows (according to MSDN docs)
            ULARGE_INTEGER kernelInteger;
            kernelInteger.LowPart = kernelTime.dwLowDateTime;
            kernelInteger.HighPart = kernelTime.dwHighDateTime;
            ULARGE_INTEGER userInteger;
            userInteger.LowPart = userTime.dwLowDateTime;
            userInteger.HighPart = userTime.dwHighDateTime;
            ULARGE_INTEGER totalTime;
            totalTime.QuadPart= kernelInteger.QuadPart + userInteger.QuadPart;
            return double(totalTime.QuadPart * 1e-7);
#else
            // Implementation using POSIX functions
            struct tms buf;
            if (times(&buf) == static_cast<clock_t>(-1))
            {
                std::cerr << "Time measurement overflow.\n";
                return 0;
            }
            clock_t clockTicks =
                buf.tms_utime + buf.tms_stime
                + buf.tms_cutime + buf.tms_cstime;
            return double(clockTicks) / double(g_ticksPerSecond);
#endif
        }
    case SG_TIME_REAL:
        {
            time_duration diff = microsec_clock::universal_time() - g_start;
            return double(diff.total_nanoseconds()) * 1e-9;
        }
    default:
        SG_ASSERT(false);
        return 0;
    }
}

SgTimeMode SgTime::DefaultMode()
{
    return g_defaultMode;
}

void SgTime::SetDefaultMode(SgTimeMode mode)
{
    g_defaultMode = mode;
}

string SgTime::TodaysDate()
{
    time_t systime = time(0);
    struct tm* currtime = localtime(&systime);
    const int BUF_SIZE = 14;
    char buf[BUF_SIZE];
    strftime(buf, BUF_SIZE - 1, "%Y-%m-%d", currtime);
    return string(buf);
}

//----------------------------------------------------------------------------

