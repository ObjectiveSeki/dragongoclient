//----------------------------------------------------------------------------
/** @file SgBookBuilder.h */
//----------------------------------------------------------------------------

#ifndef SG_BOOKBUILDER_HPP
#define SG_BOOKBUILDER_HPP

#include <cmath>
#include <iostream>
#include <iomanip>
#include <vector>
#include "SgMove.h"

//----------------------------------------------------------------------------

/** @defgroup sgopeningbook Automatic Opening Book Construction
    Game independent Opening Book Construction.

    Code is based on Thomas R. Lincke's paper "Strategies for the
    Automatic Construction of Opening Books" published in 2001.
    
    We make the following adjustments:
    - Neither side is assumed to be the book player, so the expansion
      formula is identical for all nodes (see page 80 of the paper). In other
      words, both sides can play sub-optimal moves.
    - A single node for each state is stored, such that transpositions
      are not re-computed. Hence the book forms a DAG of states, not a tree.
    - Progressive widening is used on internal nodes to restrict the 
      search initially. 

    We also think there is a typo with respect to the formula of epo_i on
    page 80. Namely, since p_i is the negamax of p_{s_j}s, then we should
    sum the values to find the distance from optimal, not subtract. That is,
    we use epo_i = 1 + min(s_j) (epb_{s_j} + alpha*(p_i + p_{s_j}) instead. */

//----------------------------------------------------------------------------

/** State in the Opening Book.
    @ingroup sgopeningbook */
class SgBookNode
{
public:
    //------------------------------------------------------------------------

    /** Priority of newly created leaves. */
    static const float LEAF_PRIORITY;

    //------------------------------------------------------------------------

    /** Heuristic value of this state. */
    float m_heurValue;

    /** Minmax value of this state. */
    float m_value;

    /** Expansion priority. */
    float m_priority;

    /** Number of times this node was explored. */
    unsigned m_count;
    
    //------------------------------------------------------------------------

    SgBookNode();

    /** Creates a leaf with the given heuristic value. */
    SgBookNode(float heuristicValue);

    /** Creates a node from data in string. Uses same format as
        ToString(). */
    SgBookNode(const std::string& str);

    /** Returns true if this node is a leaf in the opening book, ie,
        its count is zero. */
    bool IsLeaf() const;

    /** Returns true if propagated value is a win or a loss. */
    bool IsTerminal() const;

    /** Increment the node's counter. */
    void IncrementCount();

    /** Outputs node in string form. */
    std::string ToString() const;

private:
    void FromString(const std::string& str);
};

inline SgBookNode::SgBookNode()
{
}

inline SgBookNode::SgBookNode(float heuristicValue)
    : m_heurValue(heuristicValue),
      m_value(heuristicValue),
      m_priority(LEAF_PRIORITY),
      m_count(0)
{
}

inline SgBookNode::SgBookNode(const std::string& str)
{
    FromString(str);
}

inline void SgBookNode::IncrementCount()
{
    m_count++;
}

/** Extends standard stream output operator for SgBookNodes. */
inline std::ostream& operator<<(std::ostream& os, const SgBookNode& node)
{
    os << node.ToString();
    return os;
}

//----------------------------------------------------------------------------

/** @page bookrefresh Book Refresh
    @ingroup sgopeningbook

    Due to transpositions, it is possible that a node's value changes,
    but because the node has not been revisited yet the information is
    not passed to its parent. Refreshing the book forces these
    propagations.

    SgBookBuilder::Refresh() computes the correct propagation value for
    all internal nodes given the current set of leaf nodes. A node in
    which SgBookNode::IsLeaf() is true is treated as a leaf even
    if it has children in the book (ie, children from transpositions) */

/** @page bookcover "Book Cover
    @ingroup sgopeningbook

    The book cover operation ensures that a given set of lines is
    covered with the required number of expansions. When completed,
    each position in each line will have had at least the required
    number of expansions performed from it. 
    
    For each line, each position is processed in order. Expansions are
    performed until the required number are obtained (nothing is done
    if it already has enough). Then the next position in the line is
    processed.  

    If the additive flag is true, then the given number of expansions
    are added to the node no matter how many expansions it has already
    received.

    A book refresh should be performed after this operation. */

//----------------------------------------------------------------------------

/** Base class for automated book building.
    @ingroup sgopeningbook */
class SgBookBuilder
{
public:
    SgBookBuilder();

    virtual ~SgBookBuilder();

    //---------------------------------------------------------------------

    /** Expands the book by expanding numExpansions leaves. */
    void Expand(int numExpansions);

    /** Ensures each node in each line has at least the given number
        of expansions. 
        @ref bookcover. */
    void Cover(int requiredExpansions, bool additive, 
               const std::vector< std::vector<SgMove> >& lines);

    /** Propagates leaf values up through the entire tree.  
        @ref bookrefresh. */
    void Refresh();

    /** Performs widening on all internal nodes that require it. Use
        this after increasing ExpandWidth() or decreasing
        ExpandThreshold() on an already existing book to update all
        the internal nodes with the new required width. Will do
        nothing unless parameters were changed accordingly.
        
        Does not propagate values up tree, run Refresh() afterwards to
        do so. */
    void IncreaseWidth();

    //---------------------------------------------------------------------    

    /** The parameter alpha controls state expansion (big values give
        rise to deeper lines, while small values perform like a
        BFS). */
    float Alpha() const;

    /** See Alpha() */
    void SetAlpha(float alpha);

    /** Expand only the top ExpandWidth() children of a node
        initially, and after every ExpansionThreshold() visits add
        ExpandWidth() more children. */
    bool UseWidening() const;

    /** See UseWidening() */
    void SetUseWidening(bool flag);
    
    /** See UseWidening() */
    std::size_t ExpandWidth() const;

    /** See UseWidening() */
    void SetExpandWidth(std::size_t width);

    /** See UseWidening() */
    std::size_t ExpandThreshold() const;

    /** See UseWidening() */
    void SetExpandThreshold(std::size_t threshold);

    //---------------------------------------------------------------------    

    /** Computes the expansion priority for the child using Alpha(),
        the value of the parent, and the provided values of child. */
    float ComputePriority(const SgBookNode& parent, const float childValue,
                          const float childPriority) const;

    //---------------------------------------------------------------------    

    /** Returns the evaluation from other player's perspective. */
    virtual float InverseEval(float eval) const = 0;

    /** Returns true if the eval is a loss. */
    virtual bool IsLoss(float eval) const = 0;

    /** Returns the value of the state according this node.
        Ie, takes into account swap moves, etc. */
    virtual float Value(const SgBookNode& node) const = 0;

protected:
    /** See Alpha() */
    float m_alpha;

    /** See UseWidening() */
    bool m_useWidening;

    /** See UseWidening() */
    std::size_t m_expandWidth;

    /** See UseWidening() */
    std::size_t m_expandThreshold;
    
    /** Number of iterations after which the db is flushed to disk. */
    std::size_t m_flushIterations;

    //------------------------------------------------------------------------

    /** Converts move to a string (game dependent). */
    virtual std::string MoveString(SgMove move) const = 0;

    /** Print a message to a log/debug stream. */
    virtual void PrintMessage(std::string msg) = 0;

    /** Plays a move. */
    virtual void PlayMove(SgMove move) = 0;

    /** Undo last move. */
    virtual void UndoMove(SgMove move) = 0;

    /** Reads node. Returns false if node does not exist. */
    virtual bool GetNode(SgBookNode& node) const = 0;

    /** Writes node. */
    virtual void WriteNode(const SgBookNode& node) = 0;

    /** Save the book. */
    virtual void FlushBook() = 0;

    /** If current state does not exist, evaluate it and store in the
        book. */
    virtual void EnsureRootExists() = 0;

    /** Generates the set of moves to use in the book for this state. */
    virtual bool GenerateMoves(std::vector<SgMove>& moves, float& value) = 0;

    /** Returns all legal moves; should be a superset of those moves 
        returned by GenerateMoves() */
    virtual void GetAllLegalMoves(std::vector<SgMove>& moves) = 0;

    /** Evaluate the children of the current state, return the values
        in a vector of pairs. */
    virtual void EvaluateChildren(const std::vector<SgMove>& childrenToDo,
                    std::vector<std::pair<SgMove, float> >& scores) = 0;

    /** Hook function: called before any work is done. 
        Default implementation does nothing. */
    virtual void Init();

    /** Hook function: called after all work is complete. 
        Default implementation does nothing. */
    virtual void Fini();

    /** Hook function: called at start of iteration.
        Default implementation does nothing. */
    virtual void StartIteration();
    
    /** Hook function: called at end of iteration. 
        Default implementation does nothing. */
    virtual void EndIteration();

    virtual void BeforeEvaluateChildren();

    virtual void AfterEvaluateChildren();

    virtual void ClearAllVisited() = 0;

    virtual void MarkAsVisited() = 0;
    
    virtual bool HasBeenVisited() = 0;

private:
    std::size_t m_numEvals;

    std::size_t m_numWidenings;

    std::size_t m_valueUpdates;

    std::size_t m_priorityUpdates;

    std::size_t m_internalNodes;

    std::size_t m_leafNodes;

    std::size_t m_terminalNodes;

    //---------------------------------------------------------------------

    std::size_t NumChildren(const std::vector<SgMove>& legal);

    void UpdateValue(SgBookNode& node, const std::vector<SgMove>& legal);

    void UpdateValue(SgBookNode& node);

    SgMove UpdatePriority(SgBookNode& node);

    void DoExpansion(std::vector<SgMove>& pv);

    bool Refresh(bool root);

    void IncreaseWidth(bool root);
    
    bool ExpandChildren(std::size_t count);
};

//----------------------------------------------------------------------------

inline float SgBookBuilder::Alpha() const
{
    return m_alpha;
}

inline void SgBookBuilder::SetAlpha(float alpha)
{
    m_alpha = alpha;
}

inline bool SgBookBuilder::UseWidening() const
{
    return m_useWidening;
}

inline void SgBookBuilder::SetUseWidening(bool flag)
{
    m_useWidening = flag;
}

inline std::size_t SgBookBuilder::ExpandWidth() const
{
    return m_expandWidth;
}

inline void SgBookBuilder::SetExpandWidth(std::size_t width)
{
    m_expandWidth = width;
}

inline std::size_t SgBookBuilder::ExpandThreshold() const
{
    return m_expandThreshold;
}

inline void SgBookBuilder::SetExpandThreshold(std::size_t threshold)
{
    m_expandThreshold = threshold;
}

//----------------------------------------------------------------------------

#endif // SG_BOOKBUILDER_HPP
