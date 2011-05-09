//----------------------------------------------------------------------------
/** @file GtpInputStream.h */
//----------------------------------------------------------------------------

#ifndef GTP_INPUTSTREAM_H
#define GTP_INPUTSTREAM_H

#include <iostream>
#include <string>

//----------------------------------------------------------------------------

/** Base class for input streams used by GtpEngine.
    This implementation only forwards calls to std::istream.
    @todo Why does it need this class if users can write their own streams
    compatible with the standard library? See also
    https://sourceforge.net/apps/trac/fuego/ticket/66 */
class GtpInputStream
{
public:
    GtpInputStream(std::istream &in);

    virtual ~GtpInputStream();

    virtual bool EndOfInput();

    virtual bool GetLine(std::string &line);

private:
    std::istream &m_in;
};

//----------------------------------------------------------------------------

#endif // GTP_INPUTSTREAM_H
