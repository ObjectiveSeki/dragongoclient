//----------------------------------------------------------------------------
/** @file SgException.h
    Base class for exceptions. */
//----------------------------------------------------------------------------

#ifndef SG_EXCEPTION_H
#define SG_EXCEPTION_H

#include <exception>
#include <string>
#include <boost/format.hpp>

//----------------------------------------------------------------------------

/** Base class for exceptions. */
class SgException
    : public std::exception
{
public:
    /** Construct with no message. */
    SgException();

    /** Construct with message. */
    SgException(const std::string& message);

    SgException(const boost::format& f);

    /** Destructor. */
    virtual ~SgException() throw();

    /** Implementation of std::exception::what(). */
    const char* what() const throw();

private:
    std::string m_message;
};

//----------------------------------------------------------------------------

#endif // SG_EXCEPTION_H
