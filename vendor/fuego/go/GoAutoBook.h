//----------------------------------------------------------------------------
/** @file GoAutoBook.h */
//----------------------------------------------------------------------------

#ifndef GOAUTOBOOK_H
#define GOAUTOBOOK_H

#include <cmath>
#include <iostream>
#include <fstream>
#include <set>
#include <map>
#include "SgBookBuilder.h"
#include "SgThreadedWorker.h"
#include "GoBoard.h"
#include "GoBoardSynchronizer.h"

//----------------------------------------------------------------------------

/** Tracks canonical hash. */
class GoAutoBookState
{
public:
    GoAutoBookState(const GoBoard& brd);

    ~GoAutoBookState();

    GoBoard& Board();

    const GoBoard& Board() const;

    void Play(SgMove move);

    void Undo();

    SgHashCode GetHashCode() const;

    void Synchronize();

private:
    GoBoardSynchronizer m_synchronizer;

    GoBoard m_brd[8]; 

    SgHashCode m_hash;

    void ComputeHashCode();
}; 

inline GoBoard& GoAutoBookState::Board()
{
    return m_brd[0];
}

inline const GoBoard& GoAutoBookState::Board() const
{
    return m_brd[0];
}

//----------------------------------------------------------------------------

typedef enum 
{
    /** Select move with highest count. */
    GO_AUTOBOOK_SELECT_COUNT,

    /** Select move with highest value. */
    GO_AUTOBOOK_SELECT_VALUE

} GoAutoBookMoveSelectType;

struct GoAutoBookParam
{
    /** Requires 'count' before it can be used by the player when
        generating moves. */
    std::size_t m_usageCountThreshold;

    /** Move selection type. */
    GoAutoBookMoveSelectType m_selectType;

    GoAutoBookParam();        
};

//----------------------------------------------------------------------------

/** Simple text-based book format.
    Entire book is loaded into memory. */
class GoAutoBook
{
public:
    GoAutoBook(const std::string& filename,
               const GoAutoBookParam& param);

    ~GoAutoBook();

    /** Read the node at the given state. Returns true if node exists
        in the book, and false otherwise. */
    bool Get(const GoAutoBookState& state, SgBookNode& node) const;

    /** Store the node in the given state. */
    void Put(const GoAutoBookState& state, const SgBookNode& node);

    /** Since there is no cache, same as Save(). */
    void Flush();

    /** Writes book to disk. */
    void Save(const std::string& filename) const;

    /** Helper function: calls FindBestChild() on the given board.*/
    SgMove LookupMove(const GoBoard& brd) const;

    /** Returns the move leading to the best child state. 
        The best child state depends on the move selection criteria.
        See GoAutoBookParam. */
    SgMove FindBestChild(GoAutoBookState& state) const;

    //----------------------------------------------------------------------

    /** Merge this book with given book. 
        Internal nodes in either book become internal nodes in merged
        book, counts are clobbered (max is taken). Leafs in both books
        are leafs in merged book, value is the set to be the average.

        @todo Handle counts properly? Would need to know the original
        book the two books we are merging derived from. */
    void Merge(const GoAutoBook& other);

    /** Add states to be disabled. 
        These states will not be considered for selection in
        FindBestChild() from the parent state.  */
    void AddDisabledLines(const std::set<SgHashCode>& disabled);

    /** Copies a truncated version of the book into other. */
    void TruncateByDepth(int depth, GoAutoBookState& state,
                         GoAutoBook& other) const;

    /** Overwrites values in book by reading stream of (hash, value)
        pairs. */
    void ImportHashValuePairs(std::istream& in);

    /** Exports book states under the given state in GoBook format to
        the given stream. Only the move that would be selected with
        FindBestMove() is given as an option in each state. */
    void ExportToOldFormat(GoAutoBookState& state, std::ostream& os) const;

    //----------------------------------------------------------------------

    /** Parses a worklist from a stream. */
    static std::vector< std::vector<SgMove> > ParseWorkList(std::istream& in);

private:
    typedef std::map<SgHashCode, SgBookNode> Map;

    Map m_data;

    const GoAutoBookParam& m_param;

    std::set<SgHashCode> m_disabled;

    std::string m_filename;

    void TruncateByDepth(int depth, GoAutoBookState& state, 
                         GoAutoBook& other, 
                         std::set<SgHashCode>& seen) const;

    void ExportToOldFormat(GoAutoBookState& state, std::ostream& out,
                           std::set<SgHashCode>& seen) const;

};

inline void GoAutoBook::AddDisabledLines(const std::set<SgHashCode>& disabled)
{
    m_disabled.insert(disabled.begin(), disabled.end());
    SgDebug() << "Disabled " << disabled.size() << " lines.\n";
}

//----------------------------------------------------------------------------

#endif // GOAUTOBOOK_H
