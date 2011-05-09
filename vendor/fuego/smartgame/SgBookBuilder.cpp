//----------------------------------------------------------------------------
/** @file SgBookBuilder.cpp  */
//----------------------------------------------------------------------------

#include "SgSystem.h"
#include "SgBookBuilder.h"

#include <sstream>
#include <boost/numeric/conversion/bounds.hpp>
#include "SgDebug.h"
#include "SgPoint.h"
#include "SgTimer.h"

//----------------------------------------------------------------------------

const float SgBookNode::LEAF_PRIORITY = 0.0;

bool SgBookNode::IsTerminal() const
{
    if (m_value < -100 || m_value > 100)
        return true;
    return false;
}

bool SgBookNode::IsLeaf() const
{
    return m_count == 0;
}

std::string SgBookNode::ToString() const
{
    std::ostringstream os;
    os << std::showpos << std::fixed << std::setprecision(6);
    os << "Val " << m_value;
    os << std::noshowpos << " ExpP " << m_priority;
    os << std::showpos << " Heur " << m_heurValue << " Cnt " << m_count;
    return os.str();
}

void SgBookNode::FromString(const std::string& str)
{
    std::istringstream is(str);
    std::string dummy;
    is >> dummy;
    is >> m_value;
    is >> dummy;
    is >> m_priority;
    is >> dummy;
    is >> m_heurValue;
    is >> dummy;
    is >> m_count;
}

//----------------------------------------------------------------------------

SgBookBuilder::SgBookBuilder()
    : m_alpha(50),
      m_useWidening(true),
      m_expandWidth(16),
      m_expandThreshold(1000),
      m_flushIterations(100)
{
}

SgBookBuilder::~SgBookBuilder()
{
}

//----------------------------------------------------------------------------

void SgBookBuilder::StartIteration()
{
    // DEFAULT IMPLEMENTATION DOES NOTHING
}

void SgBookBuilder::EndIteration()
{
    // DEFAULT IMPLEMENTATION DOES NOTHING
}

void SgBookBuilder::BeforeEvaluateChildren()
{
    // DEFAULT IMPLEMENTATION DOES NOTHING
}

void SgBookBuilder::AfterEvaluateChildren()
{
    // DEFAULT IMPLEMENTATION DOES NOTHING
}

void SgBookBuilder::Init()
{
    // DEFAULT IMPLEMENTATION DOES NOTHING
}

void SgBookBuilder::Fini()
{
    // DEFAULT IMPLEMENTATION DOES NOTHING
}

void SgBookBuilder::Expand(int numExpansions)
{
    m_numEvals = 0;
    m_numWidenings = 0;

    SgTimer timer;
    Init();
    EnsureRootExists();
    int num = 0;
    for (; num < numExpansions; ++num) 
    {
        {
            std::ostringstream os;
            os << "\n--Iteration " << num << "--\n";
            PrintMessage(os.str());
        }
        {
            SgBookNode root;
            GetNode(root);
            if (root.IsTerminal()) 
            {
                PrintMessage("Root is terminal!\n");
                break;
            }
        }
        StartIteration();
        std::vector<SgMove> pv;
        DoExpansion(pv);
        EndIteration();

        if (num && (num % m_flushIterations) == 0) 
            FlushBook();
    }
    FlushBook();
    Fini();
    timer.Stop();
    double elapsed = timer.GetTime();
    std::ostringstream os;
    os << '\n'
       << "Statistics\n"
       << "Total Time     " << elapsed << '\n'
       << "Expansions     " << num 
       << std::fixed << std::setprecision(2) 
       << " (" << (num / elapsed) << "/s)\n"
       << "Evaluations    " << m_numEvals 
       << std::fixed << std::setprecision(2)
       << " (" << (double(m_numEvals) / elapsed) << "/s)\n"
       << "Widenings      " << m_numWidenings << '\n';
    PrintMessage(os.str());
}

void SgBookBuilder::Cover(int requiredExpansions, bool additive, 
                          const std::vector< std::vector<SgMove> >& lines)
{
    m_numEvals = 0;
    m_numWidenings = 0;
    std::size_t newLines = 0;
    SgTimer timer;
    Init();
    int num = 0;
    for (std::size_t i = 0; i < lines.size(); ++i)
    {
        const std::size_t size = lines[i].size();
        std::vector<SgMove> played;
        for (std::size_t j = 0; j <= size; ++j)
        {
            int expansionsToDo = requiredExpansions;
            SgBookNode node;
            if (GetNode(node))
            {
                if (!additive)
                    expansionsToDo = requiredExpansions - node.m_count;
            }
            else
            {
                EnsureRootExists();
                GetNode(node);
                newLines++;
            }
            if (node.IsTerminal())
                break;
            for (int k = 0; k < expansionsToDo; ++k)
            {
                {
                    std::ostringstream os;
                    os << "\n--Iteration " << num << ": " 
                       << (i + 1) << '/' << lines.size() << ' '
                       << (j + 1) << '/' << (size + 1) << ' '
                       << (k + 1) << '/' << expansionsToDo << "--\n";
                    PrintMessage(os.str());
                }

                StartIteration();
                std::vector<SgMove> pv;
                DoExpansion(pv);
                EndIteration();

                num++;
                if (num % m_flushIterations == 0)
                    FlushBook();
            }
            if (j < lines[i].size())
            {
                PlayMove(lines[i][j]);
                played.push_back(lines[i][j]);
            }
        }
        for (std::size_t j = 0; j < played.size(); ++j)
        {
            UndoMove(played[played.size() - 1 - j]);
            SgBookNode node;
            GetNode(node);
            UpdateValue(node);
            UpdatePriority(node);
        }
    }
    FlushBook();
    Fini();
    timer.Stop();
    double elapsed = timer.GetTime();
    std::ostringstream os;
    os << '\n'
       << "Statistics\n"
       << "Total Time     " << elapsed << '\n'
       << "Expansions     " << num 
       << std::fixed << std::setprecision(2) 
       << " (" << (num / elapsed) << "/s)\n"
       << "Evaluations    " << m_numEvals 
       << std::fixed << std::setprecision(2)
       << " (" << (double(m_numEvals) / elapsed) << "/s)\n"
       << "Widenings      " << m_numWidenings << '\n'
       << "New Lines      " << newLines << '\n';
    PrintMessage(os.str());
}

void SgBookBuilder::Refresh()
{
    m_numEvals = 0;
    m_numWidenings = 0;
    m_valueUpdates = 0;
    m_priorityUpdates = 0;
    m_internalNodes = 0;
    m_leafNodes = 0;
    m_terminalNodes = 0;

    SgTimer timer;
    Init();
    ClearAllVisited();
    Refresh(true);
    FlushBook();
    Fini();
    timer.Stop();

    double elapsed = timer.GetTime();
    std::ostringstream os;
    os << '\n'
       << "Statistics\n"
       << "Total Time       " << elapsed << '\n'
       << "Value Updates    " << m_valueUpdates << '\n'
       << "Priority Updates " << m_priorityUpdates << '\n'
       << "Internal Nodes   " << m_internalNodes << '\n'
       << "Terminal Nodes   " << m_terminalNodes << '\n'
       << "Leaf Nodes       " << m_leafNodes << '\n'
       << "Evaluations      " << m_numEvals 
       << std::fixed << std::setprecision(2)
       << " (" << (double(m_numEvals) / elapsed) << "/s)\n"
       << "Widenings        " << m_numWidenings << '\n';
    PrintMessage(os.str());
}

void SgBookBuilder::IncreaseWidth()
{
    if (!m_useWidening)
    {
        PrintMessage("Widening not enabled!\n");
        return;
    }

    m_numEvals = 0;
    m_numWidenings = 0;

    SgTimer timer;
    Init();
    ClearAllVisited();
    IncreaseWidth(true);
    FlushBook();
    Fini();
    timer.Stop();
    double elapsed = timer.GetTime();

    std::ostringstream os;
    os << '\n'
       << "Statistics\n"
       << "Total Time     " << elapsed << '\n'
       << "Widenings      " << m_numWidenings << '\n'
       << "Evaluations    " << m_numEvals 
       << std::fixed << std::setprecision(2)
       << " (" << (double(m_numEvals) / elapsed) << "/s)\n";
    PrintMessage(os.str());
}

//----------------------------------------------------------------------------

/** Creates a node for each of the leaf's first count children that
    have not been created yet. Returns true if at least one new node
    was created, false otherwise. */
bool SgBookBuilder::ExpandChildren(std::size_t count)
{
    // It is possible the state is determined, even though it was
    // already evaluated. This can happen in Hex: it is not very likey
    // if the evaluation function is reasonably heavyweight, but if
    // just using fillin and vcs, it is possible that the fillin
    // prevents a winning vc from being created.
    float value = 0;
    std::vector<SgMove> children;
    if (GenerateMoves(children, value))
    {
        PrintMessage("ExpandChildren: State is determined!\n");
        WriteNode(SgBookNode(value));
        return false;
    }
    std::size_t limit = std::min(count, children.size());
    std::vector<SgMove> childrenToDo;
    for (std::size_t i = 0; i < limit; ++i)
    {
        PlayMove(children[i]);
        SgBookNode child;
        if (!GetNode(child))
            childrenToDo.push_back(children[i]);
        UndoMove(children[i]);
    }
    if (!childrenToDo.empty())
    {
        BeforeEvaluateChildren();
        std::vector<std::pair<SgMove, float> > scores;
        EvaluateChildren(childrenToDo, scores);
        AfterEvaluateChildren();
        for (std::size_t i = 0; i < scores.size(); ++i)
        {
            PlayMove(scores[i].first);
            WriteNode(scores[i].second);
            UndoMove(scores[i].first);
        }
        m_numEvals += childrenToDo.size();
        return true;
    }
    else
        PrintMessage("Children already evaluated.\n");
    return false;
}

std::size_t SgBookBuilder::NumChildren(const std::vector<SgMove>& legal)
{
    std::size_t num = 0;
    for (size_t i = 0; i < legal.size(); ++i) 
    {
    PlayMove(legal[i]);
    SgBookNode child;
        if (GetNode(child))
            ++num;
        UndoMove(legal[i]);
    }
    return num;
}

void SgBookBuilder::UpdateValue(SgBookNode& node, 
                                const std::vector<SgMove>& legal)
{
    bool hasChild = false;
    float bestValue = boost::numeric::bounds<float>::lowest();
    for (std::size_t i = 0; i < legal.size(); ++i)
    {
    PlayMove(legal[i]);
    SgBookNode child;
        if (GetNode(child))
        {
            hasChild = true;
            float value = InverseEval(Value(child));
            if (value > bestValue)
        bestValue = value;
        }
        UndoMove(legal[i]);
    }
    if (hasChild)
        node.m_value = bestValue;
}

/** Updates the node's value, taking special care if the value is a
    loss. In this case, widenings are performed until a non-loss child
    is added or no new children are added. The node is then set with
    the proper value. */
void SgBookBuilder::UpdateValue(SgBookNode& node)
{
    while (true)
    {
        std::vector<SgMove> legal;
        GetAllLegalMoves(legal);
        UpdateValue(node, legal);
        if (!IsLoss(Value(node)))
            break;
        // Round up to next nearest multiple of m_expandWidth that is
        // larger than the current number of children.
        std::size_t numChildren = NumChildren(legal);
        std::size_t width = (numChildren / m_expandWidth + 1) 
            * m_expandWidth;
        {
            std::ostringstream os;
            os << "Forced Widening[" << numChildren << "->" << width << "]\n";
            PrintMessage(os.str());
        }
        if (!ExpandChildren(width))
            break;
        ++m_numWidenings;
    }
}

float SgBookBuilder::ComputePriority(const SgBookNode& parent,
                                     const float childValue,
                                     const float childPriority) const
{
    float delta = parent.m_value - InverseEval(childValue);
    SG_ASSERT(delta >= 0.0);
    return m_alpha * delta + childPriority + 1;
}

/** Re-computes node's priority and returns the best child to
    expand. Requires that UpdateValue() has been called on this
    node. Returns SG_NULLMOVE if node has no children. */
SgMove SgBookBuilder::UpdatePriority(SgBookNode& node)
{
    bool hasChild = false;
    float bestPriority = boost::numeric::bounds<float>::highest();
    SgMove bestChild = SG_NULLMOVE;
    std::vector<SgMove> legal;
    GetAllLegalMoves(legal);
    for (std::size_t i = 0; i < legal.size(); ++i)
    {
    PlayMove(legal[i]);
    SgBookNode child;
        if (GetNode(child))
        {
            hasChild = true;
            // Must adjust child value for swap, but not the parent
            // because we are comparing with the best child's value,
            // ie, the minmax value.
            float childValue = Value(child);
            float childPriority = child.m_priority;
            float priority = ComputePriority(node, childValue, childPriority);
            if (priority < bestPriority)
            {
                bestPriority = priority;
                bestChild = legal[i];
            }
        }
        UndoMove(legal[i]);
    }
    if (hasChild)
        node.m_priority = bestPriority;
    return bestChild;
}

void SgBookBuilder::DoExpansion(std::vector<SgMove>& pv)
{
    SgBookNode node;
    if (!GetNode(node))
        SG_ASSERT(false);
    if (node.IsTerminal())
        return;
    if (node.IsLeaf())
    {
        ExpandChildren(m_expandWidth);
    }
    else
    {
        // Widen this non-terminal non-leaf node if necessary
        if (m_useWidening && (node.m_count % m_expandThreshold == 0))
        {
            std::size_t width = (node.m_count / m_expandThreshold + 1)
                              * m_expandWidth;
            ++m_numWidenings;
            ExpandChildren(width);
        }
        // Compute value and priority. It's possible this node is newly
        // terminal if one of its new children is a winning move.
        GetNode(node);
        UpdateValue(node);
        SgMove mostUrgent = UpdatePriority(node);
        WriteNode(node);

        // Recurse on most urgent child only if non-terminal.
        if (!node.IsTerminal())
        {
            PlayMove(mostUrgent);
            pv.push_back(mostUrgent);
            DoExpansion(pv);
            pv.pop_back();
            UndoMove(mostUrgent);
        }
    }
    GetNode(node);
    UpdateValue(node);
    UpdatePriority(node);
    node.IncrementCount();
    WriteNode(node);
}

//----------------------------------------------------------------------------

/** Refresh's each child of the given state. UpdateValue() and
    UpdatePriority() are called on internal nodes. Returns true if
    state exists in book.  
    @ref bookrefresh */
bool SgBookBuilder::Refresh(bool root)
{
    if (HasBeenVisited())
        return true;
    MarkAsVisited();
    SgBookNode node;
    if (!GetNode(node))
        return false;
    if (node.IsLeaf())
    {
        m_leafNodes++;
        if (node.IsTerminal())
            m_terminalNodes++;
        return true;
    }
    double oldValue = Value(node);
    double oldPriority = node.m_priority;
    std::vector<SgMove> legal;
    GetAllLegalMoves(legal);
    for (std::size_t i = 0; i < legal.size(); ++i)
    {
        PlayMove(legal[i]);
        Refresh(false);
        if (root)
        {
            std::ostringstream os;
            os << "Finished " << MoveString(legal[i]) << '\n';
            PrintMessage(os.str());
        }
        UndoMove(legal[i]);
    }
    UpdateValue(node);
    UpdatePriority(node);
    if (fabs(oldValue - Value(node)) > 0.0001)
        m_valueUpdates++;
    if (fabs(oldPriority - node.m_priority) > 0.0001)
        m_priorityUpdates++;
    WriteNode(node);
    if (node.IsTerminal())
        m_terminalNodes++;
    else
        m_internalNodes++;
    return true;
}

//----------------------------------------------------------------------------

void SgBookBuilder::IncreaseWidth(bool root)
{
    if (HasBeenVisited())
        return;
    MarkAsVisited();
    SgBookNode node;
    if (!GetNode(node))
        return;
    if (node.IsTerminal() || node.IsLeaf())
        return;
    std::vector<SgMove> legal;
    GetAllLegalMoves(legal);
    for (std::size_t i = 0; i < legal.size(); ++i)
    {
        PlayMove(legal[i]);
        IncreaseWidth(false);
        if (root)
        {
            std::ostringstream os;
            os << "Finished " << MoveString(legal[i]) << '\n';
            PrintMessage(os.str());
        }
        UndoMove(legal[i]);
    }
    std::size_t width = (node.m_count / m_expandThreshold + 1)
        * m_expandWidth;
    if (ExpandChildren(width))
        ++m_numWidenings;
}

//----------------------------------------------------------------------------
