//----------------------------------------------------------------------------
/** @file SgUctSearch.cpp */
//----------------------------------------------------------------------------

#include "SgSystem.h"
#include "SgUctSearch.h"

#include <algorithm>
#include <cmath>
#include <iomanip>
#include <boost/format.hpp>
#include <boost/io/ios_state.hpp>
#include <boost/version.hpp>
#include "SgDebug.h"
#include "SgHashTable.h"
#include "SgMath.h"
#include "SgPlatform.h"
#include "SgWrite.h"

using namespace std;
using boost::barrier;
using boost::condition;
using boost::format;
using boost::mutex;
using boost::shared_ptr;
using boost::io::ios_all_saver;

#define BOOST_VERSION_MAJOR (BOOST_VERSION / 100000)
#define BOOST_VERSION_MINOR (BOOST_VERSION / 100 % 1000)

//----------------------------------------------------------------------------

namespace {

const bool DEBUG_THREADS = false;

/** Get a default value for lock-free mode.
    Lock-free mode works only on IA-32/Intel-64 architectures or if the macro
    ENABLE_CACHE_SYNC from Fuego's configure script is defined. The
    architecture is determined by using the macro HOST_CPU from Fuego's
    configure script. On Windows, an Intel architecture is always assumed. */
bool GetLockFreeDefault()
{
#if defined(WIN32) || defined(ENABLE_CACHE_SYNC)
    return true;
#elif defined(HOST_CPU)
    string hostCpu(HOST_CPU);
    return hostCpu == "i386" || hostCpu == "i486" || hostCpu == "i586"
        || hostCpu == "i686" || hostCpu == "x86_64";
#else
    return false;
#endif
}

/** Get a default value for the tree size.
    The default value is that both trees used by SgUctSearch take no more than
    half of the total amount of memory on the system (but no less than
    384 MB and not more than 1 GB). */
size_t GetMaxNodesDefault()
{
    size_t totalMemory = SgPlatform::TotalMemory();
    SgDebug() << "SgUctSearch: system memory ";
    if (totalMemory == 0)
        SgDebug() << "unknown";
    else
        SgDebug() << totalMemory;
    // Use half of the physical memory by default but at least 284K and not
    // more than 1G
    size_t searchMemory = totalMemory / 2;
    if (searchMemory < 384000000)
        searchMemory = 384000000;
    if (searchMemory > 1000000000)
        searchMemory = 1000000000;
    size_t memoryPerTree = searchMemory / 2;
    size_t nodesPerTree = memoryPerTree / sizeof(SgUctNode);
    SgDebug() << ", using " << searchMemory << " (" << nodesPerTree
              << " nodes)\n";
    return nodesPerTree;
}

void Notify(mutex& aMutex, condition& aCondition)
{
    mutex::scoped_lock lock(aMutex);
    aCondition.notify_all();
}

} // namespace

//----------------------------------------------------------------------------

void SgUctGameInfo::Clear(std::size_t numberPlayouts)
{
    m_nodes.clear();
    m_inTreeSequence.clear();
    if (numberPlayouts != m_sequence.size())
    {
        m_sequence.resize(numberPlayouts);
        m_skipRaveUpdate.resize(numberPlayouts);
        m_eval.resize(numberPlayouts);
        m_aborted.resize(numberPlayouts);
    }
    for (size_t i = 0; i < numberPlayouts; ++i)
    {
        m_sequence[i].clear();
        m_skipRaveUpdate[i].clear();
    }
}

//----------------------------------------------------------------------------

SgUctThreadState::SgUctThreadState(unsigned int threadId, int moveRange)
    : m_threadId(threadId),
      m_isSearchInitialized(false),
      m_isTreeOutOfMem(false)
{
    if (moveRange > 0)
    {
        m_firstPlay.reset(new size_t[moveRange]);
        m_firstPlayOpp.reset(new size_t[moveRange]);
    }
}

SgUctThreadState::~SgUctThreadState()
{
}

void SgUctThreadState::EndPlayout()
{
    // Default implementation does nothing
}

void SgUctThreadState::GameStart()
{
    // Default implementation does nothing
}

void SgUctThreadState::StartPlayout()
{
    // Default implementation does nothing
}

void SgUctThreadState::StartPlayouts()
{
    // Default implementation does nothing
}

//----------------------------------------------------------------------------

SgUctThreadStateFactory::~SgUctThreadStateFactory()
{
}

//----------------------------------------------------------------------------

SgUctSearch::Thread::Function::Function(Thread& thread)
    : m_thread(thread)
{
}

void SgUctSearch::Thread::Function::operator()()
{
    m_thread();
}

SgUctSearch::Thread::Thread(SgUctSearch& search,
                            auto_ptr<SgUctThreadState> state)
    : m_state(state),
      m_search(search),
      m_quit(false),
      m_threadReady(2),
      m_playFinishedLock(m_playFinishedMutex),
#if BOOST_VERSION_MAJOR == 1 && BOOST_VERSION_MINOR <= 34
      m_globalLock(search.m_globalMutex, false),
#else
      m_globalLock(search.m_globalMutex, boost::defer_lock),
#endif
      m_thread(Function(*this))
{
    m_threadReady.wait();
}

SgUctSearch::Thread::~Thread()
{
    m_quit = true;
    StartPlay();
    m_thread.join();
}

void SgUctSearch::Thread::operator()()
{
    if (DEBUG_THREADS)
        SgDebug() << "SgUctSearch::Thread: starting thread "
                  << m_state->m_threadId << '\n';
    mutex::scoped_lock lock(m_startPlayMutex);
    m_threadReady.wait();
    while (true)
    {
        m_startPlay.wait(lock);
        if (m_quit)
            break;
        m_search.SearchLoop(*m_state, &m_globalLock);
        Notify(m_playFinishedMutex, m_playFinished);
    }
    if (DEBUG_THREADS)
        SgDebug() << "SgUctSearch::Thread: finishing thread "
                  << m_state->m_threadId << '\n';
}

void SgUctSearch::Thread::StartPlay()
{
    Notify(m_startPlayMutex, m_startPlay);
}

void SgUctSearch::Thread::WaitPlayFinished()
{
    m_playFinished.wait(m_playFinishedLock);
}

//----------------------------------------------------------------------------

void SgUctSearchStat::Clear()
{
    m_time = 0;
    m_knowledge = 0;
    m_gamesPerSecond = 0;
    m_gameLength.Clear();
    m_movesInTree.Clear();
    m_aborted.Clear();
}

void SgUctSearchStat::Write(std::ostream& out) const
{
    ios_all_saver saver(out);
    out << SgWriteLabel("Time") << setprecision(2) << m_time << '\n'
        << SgWriteLabel("GameLen") << fixed << setprecision(1);
    m_gameLength.Write(out);
    out << '\n'
        << SgWriteLabel("InTree");
    m_movesInTree.Write(out);
    out << '\n'
        << SgWriteLabel("Aborted")
        << static_cast<int>(100 * m_aborted.Mean()) << "%\n"
        << SgWriteLabel("Games/s") << fixed << setprecision(1)
        << m_gamesPerSecond << '\n';
}

//----------------------------------------------------------------------------

SgUctSearch::SgUctSearch(SgUctThreadStateFactory* threadStateFactory,
                         int moveRange)
    : m_threadStateFactory(threadStateFactory),
      m_logGames(false),
      m_rave(false),
      m_knowledgeThreshold(),
      m_moveSelect(SG_UCTMOVESELECT_COUNT),
      m_raveCheckSame(false),
      m_randomizeRaveFrequency(20),
      m_lockFree(GetLockFreeDefault()),
      m_weightRaveUpdates(true),
      m_pruneFullTree(true),
      m_checkFloatPrecision(true),
      m_numberThreads(1),
      m_numberPlayouts(1),
      m_maxNodes(GetMaxNodesDefault()),
      m_pruneMinCount(16),
      m_moveRange(moveRange),
      m_maxGameLength(numeric_limits<size_t>::max()),
      m_expandThreshold(numeric_limits<SgUctValue>::is_integer ? (SgUctValue)1 : numeric_limits<SgUctValue>::epsilon()),
      m_biasTermConstant(0.7f),
      m_firstPlayUrgency(10000),
      m_raveWeightInitial(0.9f),
      m_raveWeightFinal(20000),
      m_virtualLoss(false),
      m_logFileName("uctsearch.log"),
      m_fastLog(10),
      m_mpiSynchronizer(SgMpiNullSynchronizer::Create())
{
    // Don't create thread states here, because the factory passes the search
    // (which is not fully constructed here, because the subclass constructors
    // are not called yet) as an argument to the Create() function
}

SgUctSearch::~SgUctSearch()
{
    DeleteThreads();
}

void SgUctSearch::ApplyRootFilter(vector<SgUctMoveInfo>& moves)
{
    // Filter without changing the order of the unfiltered moves
    vector<SgUctMoveInfo> filteredMoves;
    for (vector<SgUctMoveInfo>::const_iterator it = moves.begin();
         it != moves.end(); ++it)
        if (find(m_rootFilter.begin(), m_rootFilter.end(), it->m_move)
            == m_rootFilter.end())
            filteredMoves.push_back(*it);
    moves = filteredMoves;
}

SgUctValue SgUctSearch::GamesPlayed() const
{
    return m_tree.Root().MoveCount() - m_startRootMoveCount;
}

bool SgUctSearch::CheckAbortSearch(SgUctThreadState& state)
{
    if (SgUserAbort())
    {
        Debug(state, "SgUctSearch: abort flag");
        return true;
    }
    const SgUctNode& root = m_tree.Root();
    if (! SgUctValueUtil::IsPrecise(root.MoveCount()) && m_checkFloatPrecision)
    {
        Debug(state, "SgUctSearch: floating point type precision reached");
        return true;
    }
    SgUctValue rootCount = root.MoveCount();
    if (rootCount >= m_maxGames)
    {
        Debug(state, "SgUctSearch: max games reached");
        return true;
    }
    if (root.IsProven())
    {
        if (root.IsProvenWin())
            Debug(state, "SgUctSearch: root is proven win!");
        else 
            Debug(state, "SgUctSearch: root is proven loss!");
        return true;
    }
    const bool isEarlyAbort = CheckEarlyAbort();
    if (   isEarlyAbort
        && m_earlyAbort->m_reductionFactor * rootCount >= m_maxGames
       )
    {
        Debug(state, "SgUctSearch: max games reached (early abort)");
        m_wasEarlyAbort = true;
        return true;
    }
    if (m_numberGames >= m_nextCheckTime)
    {
        m_nextCheckTime = m_numberGames + m_checkTimeInterval;
        double time = m_timer.GetTime();
        if (time > m_maxTime)
        {
            Debug(state, "SgUctSearch: max time reached");
            return true;
        }
        if (isEarlyAbort
            && m_earlyAbort->m_reductionFactor * time > m_maxTime)
        {
            Debug(state, "SgUctSearch: max time reached (early abort)");
            m_wasEarlyAbort = true;
            return true;
        }
        UpdateCheckTimeInterval(time);
        if (m_moveSelect == SG_UCTMOVESELECT_COUNT)
        {
            double remainingGamesDouble = m_maxGames - rootCount - 1;
            // Use time based count abort, only if time > 1, otherwise
            // m_gamesPerSecond is unreliable
            if (time > 1.)
            {
                double remainingTime = m_maxTime - time;
                remainingGamesDouble =
                    min(remainingGamesDouble,
                        remainingTime * m_statistics.m_gamesPerSecond);
            }
            SgUctValue uctCountMax = numeric_limits<SgUctValue>::max();
            SgUctValue remainingGames;
            if (remainingGamesDouble >= static_cast<double>(uctCountMax - 1))
                remainingGames = uctCountMax;
            else
                remainingGames = SgUctValue(remainingGamesDouble);
            if (CheckCountAbort(state, remainingGames))
            {
                Debug(state, "SgUctSearch: move cannot change anymore");
                return true;
            }
        }
    }
    return false;
}

bool SgUctSearch::CheckCountAbort(SgUctThreadState& state,
                                  SgUctValue remainingGames) const
{
    const SgUctNode& root = m_tree.Root();
    const SgUctNode* bestChild = FindBestChild(root);
    if (bestChild == 0)
        return false;
    SgUctValue bestCount = bestChild->MoveCount();
    vector<SgMove>& excludeMoves = state.m_excludeMoves;
    excludeMoves.clear();
    excludeMoves.push_back(bestChild->Move());
    const SgUctNode* secondBestChild = FindBestChild(root, &excludeMoves);
    if (secondBestChild == 0)
        return false;
    SgUctValue secondBestCount = secondBestChild->MoveCount();
    SG_ASSERT(secondBestCount <= bestCount || m_numberThreads > 1);
    return (remainingGames <= bestCount - secondBestCount);
}

bool SgUctSearch::CheckEarlyAbort() const
{
    const SgUctNode& root = m_tree.Root();
    return   m_earlyAbort.get() != 0
          && root.HasMean()
          && root.MoveCount() > m_earlyAbort->m_minGames
          && root.Mean() > m_earlyAbort->m_threshold;
}

void SgUctSearch::CreateThreads()
{
    DeleteThreads();
    for (unsigned int i = 0; i < m_numberThreads; ++i)
    {
        auto_ptr<SgUctThreadState> state(
                                      m_threadStateFactory->Create(i, *this));
        shared_ptr<Thread> thread(new Thread(*this, state));
        m_threads.push_back(thread);
    }
    m_tree.CreateAllocators(m_numberThreads);
    m_tree.SetMaxNodes(m_maxNodes);

    m_searchLoopFinished.reset(new barrier(m_numberThreads));
}

/** Write a debugging line of text from within a thread.
    Prepends the line with the thread number if number of threads is greater
    than one. Also ensures that the line is written as a single string to
    avoid intermingling of text lines from different threads.
    @param state The state of the thread (only used for state.m_threadId)
    @param textLine The line of text without trailing newline character. */
void SgUctSearch::Debug(const SgUctThreadState& state,
                        const std::string& textLine)
{
    if (m_numberThreads > 1)
    {
        // SgDebug() is not necessarily thread-safe
        GlobalLock lock(m_globalMutex);
        SgDebug() << (format("[%1%] %2%\n") % state.m_threadId % textLine);
    }
    else
        SgDebug() << (format("%1%\n") % textLine);
}

void SgUctSearch::DeleteThreads()
{
    m_threads.clear();
}

/** Expand a node.
    @param state The thread state with state.m_moves already computed.
    @param node The node to expand. */
void SgUctSearch::ExpandNode(SgUctThreadState& state, const SgUctNode& node)
{
    unsigned int threadId = state.m_threadId;
    if (! m_tree.HasCapacity(threadId, state.m_moves.size()))
    {
        Debug(state, str(format("SgUctSearch: maximum tree size %1% reached")
                         % m_tree.MaxNodes()));
        state.m_isTreeOutOfMem = true;
        m_isTreeOutOfMemory = true;
        SgSynchronizeThreadMemory();
        return;
    }
    m_tree.CreateChildren(threadId, node, state.m_moves);
}

const SgUctNode*
SgUctSearch::FindBestChild(const SgUctNode& node,
                           const vector<SgMove>* excludeMoves) const
{
    if (! node.HasChildren())
        return 0;
    const SgUctNode* bestChild = 0;
    SgUctValue bestValue = 0;
    for (SgUctChildIterator it(m_tree, node); it; ++it)
    {
        const SgUctNode& child = *it;
        if (excludeMoves != 0)
        {
            vector<SgMove>::const_iterator begin = excludeMoves->begin();
            vector<SgMove>::const_iterator end = excludeMoves->end();
            if (find(begin, end, child.Move()) != end)
                continue;
        }
        if (  ! child.HasMean()
           && ! (  (  m_moveSelect == SG_UCTMOVESELECT_BOUND
                   || m_moveSelect == SG_UCTMOVESELECT_ESTIMATE
                   )
                && m_rave
                && child.HasRaveValue()
                )
            )
            continue;
        if (child.IsProvenLoss()) // Always choose winning move!
        {
            bestChild = &child;
            break;
        }
        SgUctValue value;
        switch (m_moveSelect)
        {
        case SG_UCTMOVESELECT_VALUE:
            value = InverseEstimate((SgUctValue)child.Mean());
            break;
        case SG_UCTMOVESELECT_COUNT:
            value = child.MoveCount();
            break;
        case SG_UCTMOVESELECT_BOUND:
            value = GetBound(m_rave, node, child);
            break;
        case SG_UCTMOVESELECT_ESTIMATE:
            value = GetValueEstimate(m_rave, child);
            break;
        default:
            SG_ASSERT(false);
            value = SG_UCTMOVESELECT_VALUE;
        }
        if (bestChild == 0 || value > bestValue)
        {
            bestChild = &child;
            bestValue = value;
        }
    }
    return bestChild;
}

void SgUctSearch::FindBestSequence(vector<SgMove>& sequence) const
{
    sequence.clear();
    const SgUctNode* current = &m_tree.Root();
    while (true)
    {
        current = FindBestChild(*current);
        if (current == 0)
            break;
        sequence.push_back(current->Move());
        if (! current->HasChildren())
            break;
    }
}

void SgUctSearch::GenerateAllMoves(std::vector<SgUctMoveInfo>& moves)
{
    if (m_threads.size() == 0)
        CreateThreads();
    moves.clear();
    OnStartSearch();
    SgUctThreadState& state = ThreadState(0);
    state.StartSearch();
    SgUctProvenType type;
    state.GenerateAllMoves(0, moves, type);
}

SgUctValue SgUctSearch::GetBound(bool useRave, const SgUctNode& node,
                                 const SgUctNode& child) const
{
    SgUctValue posCount = node.PosCount();
    int virtualLossCount = node.VirtualLossCount();
    if (virtualLossCount > 0)
    {
        posCount += SgUctValue(virtualLossCount);
    }
    return GetBound(useRave, Log(posCount), child);
}

SgUctValue SgUctSearch::GetBound(bool useRave, SgUctValue logPosCount,
                                 const SgUctNode& child) const
{
    SgUctValue value;
    if (useRave)
        value = GetValueEstimateRave(child);
    else
        value = GetValueEstimate(false, child);
    if (m_biasTermConstant == 0.0)
        return value;
    else
    {
        SgUctValue moveCount = static_cast<SgUctValue>(child.MoveCount());
        SgUctValue bound =
            value + m_biasTermConstant * sqrt(logPosCount / (moveCount + 1));
        return bound;
    }
}

SgUctTree& SgUctSearch::GetTempTree()
{
    m_tempTree.Clear();
    // Use NumberThreads() (not m_tree.NuAllocators()) and MaxNodes() (not
    // m_tree.MaxNodes()), because of the delayed thread (and thereby
    // allocator) creation in SgUctSearch
    if (m_tempTree.NuAllocators() != NumberThreads())
    {
        m_tempTree.CreateAllocators(NumberThreads());
        m_tempTree.SetMaxNodes(MaxNodes());
    }
    else if (m_tempTree.MaxNodes() != MaxNodes())
    {
        m_tempTree.SetMaxNodes(MaxNodes());
    }
    return m_tempTree;
}

SgUctValue SgUctSearch::GetValueEstimate(bool useRave, const SgUctNode& child) const
{
    SgUctValue value = 0;
    SgUctValue weightSum = 0;
    bool hasValue = false;

    SgUctStatistics uctStats;
    if (child.HasMean())
    {
        uctStats.Initialize(child.Mean(), child.MoveCount());
    }
    int virtualLossCount = child.VirtualLossCount();
    if (virtualLossCount > 0)
    {
        uctStats.Add(InverseEstimate(0), SgUctValue(virtualLossCount));
    }

    if (uctStats.IsDefined())
    {
        SgUctValue weight = static_cast<SgUctValue>(uctStats.Count());
        value += weight * InverseEstimate((SgUctValue)uctStats.Mean());
        weightSum += weight;
        hasValue = true;
    }

    if (useRave)
    {
        SgUctStatistics raveStats;
        if (child.HasRaveValue())
        {
            raveStats.Initialize(child.RaveValue(), child.RaveCount());
        }
        if (virtualLossCount > 0)
        {
            raveStats.Add(0, SgUctValue(virtualLossCount));
        }
        if (raveStats.IsDefined())
        {
            SgUctValue raveCount = raveStats.Count();
            SgUctValue weight =
                raveCount
                / (  m_raveWeightParam1
                     + m_raveWeightParam2 * raveCount
                     );
            value += weight * raveStats.Mean();
            weightSum += weight;
            hasValue = true;
        }
    }
    if (hasValue)
        return value / weightSum;
    else
        return m_firstPlayUrgency;
}

/** Optimized version of GetValueEstimate() if RAVE and not other
    estimators are used.
    Previously there were more estimators than move value and RAVE value,
    and in the future there may be again. GetValueEstimate() is easier to
    extend, this function is more optimized for the special case. */
SgUctValue SgUctSearch::GetValueEstimateRave(const SgUctNode& child) const
{
    SG_ASSERT(m_rave);
    SgUctValue value;
    SgUctStatistics uctStats;
    if (child.HasMean())
    {
        uctStats.Initialize(child.Mean(), child.MoveCount());
    }
    SgUctStatistics raveStats;
    if (child.HasRaveValue())
    {
        raveStats.Initialize(child.RaveValue(), child.RaveCount());
    }
    int virtualLossCount = child.VirtualLossCount();
    if (virtualLossCount > 0)
    {
        uctStats.Add(InverseEstimate(0), SgUctValue(virtualLossCount));
        raveStats.Add(0, SgUctValue(virtualLossCount));
    }
    bool hasRave = raveStats.IsDefined();
    
    if (uctStats.IsDefined())
    {
        SgUctValue moveValue = InverseEstimate((SgUctValue)uctStats.Mean());
        if (hasRave)
        {
            SgUctValue moveCount = uctStats.Count();
            SgUctValue raveCount = raveStats.Count();
            SgUctValue weight =
                raveCount
                / (moveCount
                   * (m_raveWeightParam1 + m_raveWeightParam2 * raveCount)
                   + raveCount);
            value = weight * raveStats.Mean() + (1.f - weight) * moveValue;
        }
        else
        {
            // This can happen only in lock-free multi-threading. Normally,
            // each move played in a position should also cause a RAVE value
            // to be added. But in lock-free multi-threading it can happen
            // that the move value was already updated but the RAVE value not
            SG_ASSERT(m_numberThreads > 1 && m_lockFree);
            value = moveValue;
        }
    }
    else if (hasRave)
        value = raveStats.Mean();
    else
        value = m_firstPlayUrgency;
    SG_ASSERT(m_numberThreads > 1
              || fabs(value - GetValueEstimate(m_rave, child)) < 1e-3/*epsilon*/);
    return value;
}

string SgUctSearch::LastGameSummaryLine() const
{
    return SummaryLine(LastGameInfo());
}

SgUctValue SgUctSearch::Log(SgUctValue x) const
{
#if SG_UCTFASTLOG
    return SgUctValue(m_fastLog.Log(float(x)));
#else
    return log(x);
#endif
}

/** Creates the children with the given moves and merges with existing
    children in the tree. */
void SgUctSearch::CreateChildren(SgUctThreadState& state, 
                                 const SgUctNode& node,
                                 bool deleteChildTrees)
{
    unsigned int threadId = state.m_threadId;
    if (! m_tree.HasCapacity(threadId, state.m_moves.size()))
    {
        Debug(state, str(format("SgUctSearch: maximum tree size %1% reached")
                         % m_tree.MaxNodes()));
        state.m_isTreeOutOfMem = true;
        m_isTreeOutOfMemory = true;
        SgSynchronizeThreadMemory();
        return;
    }
    m_tree.MergeChildren(threadId, node, state.m_moves, deleteChildTrees);
}

bool SgUctSearch::NeedToComputeKnowledge(const SgUctNode* current)
{
    if (m_knowledgeThreshold.empty())
        return false;
    for (std::size_t i = 0; i < m_knowledgeThreshold.size(); ++i)
    {
        const SgUctValue threshold = m_knowledgeThreshold[i];
        if (current->KnowledgeCount() < threshold)
        {
            if (current->MoveCount() >= threshold)
            {
                // Mark knowledge computed immediately so other
                // threads fall through and do not waste time
                // re-computing this knowledge.
                m_tree.SetKnowledgeCount(*current, threshold);
                SG_ASSERT(current->MoveCount());
                return true;
            }
            return false;
        }
    }
    return false;
}

void SgUctSearch::OnStartSearch()
{
    m_mpiSynchronizer->OnStartSearch(*this);
}

void SgUctSearch::OnEndSearch()
{
    m_mpiSynchronizer->OnEndSearch(*this);
}

/** Print time, mean, nodes searched, and PV */
void SgUctSearch::PrintSearchProgress(double currTime) const
{
    const int MAX_SEQ_PRINT_LENGTH = 15;
    const SgUctValue MIN_MOVE_COUNT = 10;
    SgUctValue rootMoveCount = m_tree.Root().MoveCount();
    SgUctValue rootMean = m_tree.Root().Mean();
    ostringstream out;
    const SgUctNode* current = &m_tree.Root();
    out << (format("%s | %.3f | %.0f ")
            % SgTime::Format(currTime, true) % rootMean % rootMoveCount);
    for (int i = 0; i <= MAX_SEQ_PRINT_LENGTH && current->HasChildren(); ++i)
    {
        current = FindBestChild(*current);
        if (current == 0 || current->MoveCount() < MIN_MOVE_COUNT)
            break;
        if (i == 0)
            out << "|";
        if (i < MAX_SEQ_PRINT_LENGTH)
            out << " " << MoveString(current->Move());
        else
            out << " *";
    }
    SgDebug() << out.str() << endl;
}

void SgUctSearch::OnSearchIteration(SgUctValue gameNumber,
                                    unsigned int threadId,
                                    const SgUctGameInfo& info)
{
    const int DISPLAY_INTERVAL = 5;

    m_mpiSynchronizer->OnSearchIteration(*this, gameNumber, threadId, info);
    double currTime = m_timer.GetTime();

    if (threadId == 0 && currTime - m_lastScoreDisplayTime > DISPLAY_INTERVAL)
    {
        PrintSearchProgress(currTime);
        m_lastScoreDisplayTime = currTime;
    }
}

void SgUctSearch::PlayGame(SgUctThreadState& state, GlobalLock* lock)
{
    state.m_isTreeOutOfMem = false;
    state.GameStart();
    SgUctGameInfo& info = state.m_gameInfo;
    info.Clear(m_numberPlayouts);
    bool isTerminal;
    bool abortInTree = ! PlayInTree(state, isTerminal);

    // The playout phase is always unlocked
    if (lock != 0)
        lock->unlock();

    if (!info.m_nodes.empty() && isTerminal)
    {
        const SgUctNode& terminalNode = *info.m_nodes.back();
        SgUctValue eval = state.Evaluate();
        if (eval > 0.6) 
            m_tree.SetProvenType(terminalNode, SG_PROVEN_WIN);
        else if (eval < 0.6)
            m_tree.SetProvenType(terminalNode, SG_PROVEN_LOSS);
        PropagateProvenStatus(info.m_nodes);
    }

    size_t nuMovesInTree = info.m_inTreeSequence.size();

    // Play some "fake" playouts if node is a proven node
    if (! info.m_nodes.empty() && info.m_nodes.back()->IsProven())
    {
        for (size_t i = 0; i < m_numberPlayouts; ++i)
        {
            info.m_sequence[i] = info.m_inTreeSequence;
            info.m_skipRaveUpdate[i].assign(nuMovesInTree, false);
            SgUctValue eval = info.m_nodes.back()->IsProvenWin() ? 1 : 0;
            size_t nuMoves = info.m_sequence[i].size();
            if (nuMoves % 2 != 0)
                eval = InverseEval(eval);
            info.m_aborted[i] = abortInTree || state.m_isTreeOutOfMem;
            info.m_eval[i] = eval;
        }
    }
    else 
    {
        state.StartPlayouts();
        for (size_t i = 0; i < m_numberPlayouts; ++i)
        {
            state.StartPlayout();
            info.m_sequence[i] = info.m_inTreeSequence;
            // skipRaveUpdate only used in playout phase
            info.m_skipRaveUpdate[i].assign(nuMovesInTree, false);
            bool abort = abortInTree || state.m_isTreeOutOfMem;
            if (! abort && ! isTerminal)
                abort = ! PlayoutGame(state, i);
            SgUctValue eval;
            if (abort)
                eval = UnknownEval();
            else
                eval = state.Evaluate();
            size_t nuMoves = info.m_sequence[i].size();
            if (nuMoves % 2 != 0)
                eval = InverseEval(eval);
            info.m_aborted[i] = abort;
            info.m_eval[i] = eval;
            state.EndPlayout();
            state.TakeBackPlayout(nuMoves - nuMovesInTree);
        }
    }
    state.TakeBackInTree(nuMovesInTree);

    // End of unlocked part if ! m_lockFree
    if (lock != 0)
        lock->lock();

    UpdateTree(info);
    if (m_rave)
        UpdateRaveValues(state);
    UpdateStatistics(info);
}

/** Backs up proven information. Last node of nodes is the newly
    proven node. */
void SgUctSearch::PropagateProvenStatus(const vector<const SgUctNode*>& nodes)
{
    if (nodes.size() <= 1) 
        return;
    size_t i = nodes.size() - 2;
    while (true)
    {
        const SgUctNode& parent = *nodes[i];
        SgUctProvenType type = SG_PROVEN_LOSS;
        for (SgUctChildIterator it(m_tree, parent); it; ++it)
        {
            const SgUctNode& child = *it;
            if (!child.IsProven())
                type = SG_NOT_PROVEN;
            else if (child.IsProvenLoss())
            {
                type = SG_PROVEN_WIN;
                break;
            }
        }
        if (type == SG_NOT_PROVEN)
            break;
        else
            m_tree.SetProvenType(parent, type);
        if (i == 0)
            break;
        --i;
    }
}

/** Play game until it leaves the tree.
    @param state
    @param[out] isTerminal Was the sequence terminated because of a real
    terminal position (GenerateAllMoves() returned an empty list)?
    @return @c false, if game was aborted due to maximum length */
bool SgUctSearch::PlayInTree(SgUctThreadState& state, bool& isTerminal)
{
    vector<SgMove>& sequence = state.m_gameInfo.m_inTreeSequence;
    vector<const SgUctNode*>& nodes = state.m_gameInfo.m_nodes;
    const SgUctNode* root = &m_tree.Root();
    const SgUctNode* current = root;
    if (m_virtualLoss && m_numberThreads > 1)
        m_tree.AddVirtualLoss(*current);
    nodes.push_back(current);
    bool breakAfterSelect = false;
    isTerminal = false;
    bool deepenTree = false;
    while (true)
    {
        if (sequence.size() == m_maxGameLength)
            return false;
        if (current->IsProven())
            break;
        if (! current->HasChildren())
        {
            state.m_moves.clear();
            SgUctProvenType provenType = SG_NOT_PROVEN;
            state.GenerateAllMoves(0, state.m_moves, provenType);
            if (current == root)
                ApplyRootFilter(state.m_moves);
            if (provenType != SG_NOT_PROVEN)
            {
                m_tree.SetProvenType(*current, provenType);
                PropagateProvenStatus(nodes);
                break;
            }
            if (state.m_moves.empty())
            {
                isTerminal = true;
                break;
            }
            if (  deepenTree
               || current->MoveCount() >= m_expandThreshold
               )
            {
                deepenTree = false;
                ExpandNode(state, *current);
                if (state.m_isTreeOutOfMem)
                    return true;
                if (! deepenTree)
                    breakAfterSelect = true;
            }
            else
                break;
        }
        else if (NeedToComputeKnowledge(current))
        {
            m_statistics.m_knowledge++;
            deepenTree = false;
            SgUctProvenType provenType = SG_NOT_PROVEN;
            bool truncate = state.GenerateAllMoves(current->KnowledgeCount(), 
                                                   state.m_moves,
                                                   provenType);
            if (current == root)
                ApplyRootFilter(state.m_moves);
            CreateChildren(state, *current, truncate);
            if (provenType != SG_NOT_PROVEN)
            {
                m_tree.SetProvenType(*current, provenType);
                PropagateProvenStatus(nodes);
                break;
            }
            if (state.m_moves.empty())
            {
                isTerminal = true;
                break;
            }
            if (state.m_isTreeOutOfMem)
                return true;
            if (! deepenTree)
                breakAfterSelect = true;
        }
        current = &SelectChild(state.m_randomizeCounter, *current);
        if (m_virtualLoss && m_numberThreads > 1)
            m_tree.AddVirtualLoss(*current);
        nodes.push_back(current);
        SgMove move = current->Move();
        state.Execute(move);
        sequence.push_back(move);
        if (breakAfterSelect)
            break;
    }
    return true;
}

/** Finish the game using GeneratePlayoutMove().
    @param state The thread state.
    @param playout The number of the playout.
    @return @c false if game was aborted */
bool SgUctSearch::PlayoutGame(SgUctThreadState& state, std::size_t playout)
{
    SgUctGameInfo& info = state.m_gameInfo;
    vector<SgMove>& sequence = info.m_sequence[playout];
    vector<bool>& skipRaveUpdate = info.m_skipRaveUpdate[playout];
    while (true)
    {
        if (sequence.size() == m_maxGameLength)
            return false;
        bool skipRave = false;
        SgMove move = state.GeneratePlayoutMove(skipRave);
        if (move == SG_NULLMOVE)
            break;
        state.ExecutePlayout(move);
        sequence.push_back(move);
        skipRaveUpdate.push_back(skipRave);
    }
    return true;
}

SgUctValue SgUctSearch::Search(SgUctValue maxGames, double maxTime,
                               vector<SgMove>& sequence,
                               const vector<SgMove>& rootFilter,
                               SgUctTree* initTree,
                               SgUctEarlyAbortParam* earlyAbort)
{
    m_timer.Start();
    m_rootFilter = rootFilter;
    if (m_logGames)
    {
        m_log.open(m_mpiSynchronizer->ToNodeFilename(m_logFileName).c_str());
        m_log << "StartSearch maxGames=" << maxGames << '\n';
    }
    m_maxGames = maxGames;
    m_maxTime = maxTime;
    m_earlyAbort.reset(0);
    if (earlyAbort != 0)
        m_earlyAbort.reset(new SgUctEarlyAbortParam(*earlyAbort));

    for (size_t i = 0; i < m_threads.size(); ++i)
    {
        m_threads[i]->m_state->m_isSearchInitialized = false;
    }
    StartSearch(rootFilter, initTree);
    SgUctValue pruneMinCount = m_pruneMinCount;
    while (true)
    {
        m_isTreeOutOfMemory = false;
        SgSynchronizeThreadMemory();
        for (size_t i = 0; i < m_threads.size(); ++i)
            m_threads[i]->StartPlay();
        for (size_t i = 0; i < m_threads.size(); ++i)
            m_threads[i]->WaitPlayFinished();
        if (m_aborted || ! m_pruneFullTree)
            break;
        else
        {
            double startPruneTime = m_timer.GetTime();
            SgDebug() << "SgUctSearch: pruning nodes with count < "
                  << pruneMinCount << " (at time " << fixed << setprecision(1)
                  << startPruneTime << ")\n";
            SgUctTree& tempTree = GetTempTree();
            m_tree.CopyPruneLowCount(tempTree, pruneMinCount, true);
            int prunedSizePercentage =
                static_cast<int>(tempTree.NuNodes() * 100 / m_tree.NuNodes());
            SgDebug() << "SgUctSearch: pruned size: " << tempTree.NuNodes()
                      << " (" << prunedSizePercentage << "%) time: "
                      << (m_timer.GetTime() - startPruneTime) << "\n";
            if (prunedSizePercentage > 50)
                pruneMinCount *= 2;
            else
                 pruneMinCount = m_pruneMinCount; 
            m_tree.Swap(tempTree);
        }
    }
    EndSearch();
    m_statistics.m_time = m_timer.GetTime();
    if (m_statistics.m_time > numeric_limits<double>::epsilon())
        m_statistics.m_gamesPerSecond = GamesPlayed() / m_statistics.m_time;
    if (m_logGames)
        m_log.close();
    FindBestSequence(sequence);
    return (m_tree.Root().MoveCount() > 0) ? (SgUctValue)m_tree.Root().Mean() : (SgUctValue)0.5;
}

/** Loop invoked by each thread for playing games. */
void SgUctSearch::SearchLoop(SgUctThreadState& state, GlobalLock* lock)
{
    if (! state.m_isSearchInitialized)
    {
        OnThreadStartSearch(state);
        state.m_isSearchInitialized = true;
    }

    if (NumberThreads() == 1 || m_lockFree)
        lock = 0;
    if (lock != 0)
        lock->lock();
    state.m_isTreeOutOfMem = false;
    while (! state.m_isTreeOutOfMem)
    {
        PlayGame(state, lock);
        OnSearchIteration(m_numberGames + 1, state.m_threadId,
                          state.m_gameInfo);
        if (m_logGames)
            m_log << SummaryLine(state.m_gameInfo) << '\n';
        ++m_numberGames;
        if (m_isTreeOutOfMemory)
            break;
        if (m_aborted || CheckAbortSearch(state))
        {
            m_aborted = true;
            SgSynchronizeThreadMemory();
            break;
        }
    }
    if (lock != 0)
        lock->unlock();

    m_searchLoopFinished->wait();
    if (m_aborted || ! m_pruneFullTree)
        OnThreadEndSearch(state);
}

void SgUctSearch::OnThreadStartSearch(SgUctThreadState& state)
{
    m_mpiSynchronizer->OnThreadStartSearch(*this, state);
}

void SgUctSearch::OnThreadEndSearch(SgUctThreadState& state)
{
    m_mpiSynchronizer->OnThreadEndSearch(*this, state);
}

SgPoint SgUctSearch::SearchOnePly(SgUctValue maxGames, double maxTime,
                                  SgUctValue& value)
{
    if (m_threads.size() == 0)
        CreateThreads();
    OnStartSearch();
    // SearchOnePly is not multi-threaded.
    // It uses the state of the first thread.
    SgUctThreadState& state = ThreadState(0);
    state.StartSearch();
    vector<SgUctMoveInfo> moves;
    SgUctProvenType provenType;
    state.GameStart();
    state.GenerateAllMoves(0, moves, provenType);
    vector<SgUctStatistics> statistics(moves.size());
    SgUctValue games = 0;
    m_timer.Start();
    SgUctGameInfo& info = state.m_gameInfo;
    while (games < maxGames && m_timer.GetTime() < maxTime && ! SgUserAbort())
    {
        for (size_t i = 0; i < moves.size(); ++i)
        {
            state.GameStart();
            info.Clear(1);
            SgMove move = moves[i].m_move;
            state.Execute(move);
            info.m_inTreeSequence.push_back(move);
            info.m_sequence[0].push_back(move);
            info.m_skipRaveUpdate[0].push_back(false);
            state.StartPlayouts();
            state.StartPlayout();
            bool abortGame = ! PlayoutGame(state, 0);
            SgUctValue eval;
            if (abortGame)
                eval = UnknownEval();
            else
                eval = state.Evaluate();
            state.EndPlayout();
            state.TakeBackPlayout(info.m_sequence[0].size() - 1);
            state.TakeBackInTree(1);
            statistics[i].Add(info.m_sequence[0].size() % 2 == 0 ?
                              eval : InverseEval(eval));
            OnSearchIteration(games + 1, 0, info);
            games += 1;
        }
    }
    SgMove bestMove = SG_NULLMOVE;
    for (size_t i = 0; i < moves.size(); ++i)
    {
        SgDebug() << MoveString(moves[i].m_move) 
                  << ' ' << statistics[i].Mean() << '\n';
        if (bestMove == SG_NULLMOVE || statistics[i].Mean() > value)
        {
            bestMove = moves[i].m_move;
            value = statistics[i].Mean();
        }
    }
    return bestMove;
}

const SgUctNode& SgUctSearch::SelectChild(int& randomizeCounter, 
                                          const SgUctNode& node)
{
    bool useRave = m_rave;
    if (m_randomizeRaveFrequency > 0 && --randomizeCounter == 0)
    {
        useRave = false;
        randomizeCounter = m_randomizeRaveFrequency;
    }
    SG_ASSERT(node.HasChildren());
    SgUctValue posCount = node.PosCount();
    int virtualLossCount = node.VirtualLossCount();
    if (virtualLossCount > 1)
    {
        // Note: must remove the virtual loss already added to
        // node for the current thread.
        posCount += SgUctValue(virtualLossCount - 1);
    }

    if (posCount == 0)
        // If position count is zero, return first child
        return *SgUctChildIterator(m_tree, node);
    SgUctValue logPosCount = Log(posCount);
    const SgUctNode* bestChild = 0;
    SgUctValue bestUpperBound = 0;
    const SgUctValue epsilon = SgUctValue(1e-7);
    for (SgUctChildIterator it(m_tree, node); it; ++it)
    {
        const SgUctNode& child = *it;
        if (!child.IsProvenWin()) // Avoid losing moves
        {
            SgUctValue bound = GetBound(useRave, logPosCount, child);
            // Compare bound to best bound using a not too small epsilon
            // because the unit tests rely on the fact that the first child is
            // chosen if children have the same bounds and on some platforms
            // the result of the comparison is not well-defined and depends on
            // the compiler settings and the type of SgUctValue even if count
            // and value of the children are exactly the same.
            if (bestChild == 0 || bound > bestUpperBound + epsilon)
            {
                bestChild = &child;
                bestUpperBound = bound;
            }
        }
    }
    if (bestChild != 0)
        return *bestChild;
    // It can happen with multiple threads that all children are losing
    // in this state but this thread got in here before that information
    // was propagated up the tree. So just return the first child
    // in this case.
    return *node.FirstChild();
}

void SgUctSearch::SetNumberThreads(unsigned int n)
{
    SG_ASSERT(n >= 1);
    if (m_numberThreads == n)
        return;
    m_numberThreads = n;
    CreateThreads();
}

void SgUctSearch::SetRave(bool enable)
{
    if (enable && m_moveRange <= 0)
        throw SgException("RAVE not supported for this game");
    m_rave = enable;
}

void SgUctSearch::SetThreadStateFactory(SgUctThreadStateFactory* factory)
{
    SG_ASSERT(m_threadStateFactory.get() == 0);
    m_threadStateFactory.reset(factory);
    DeleteThreads();
    // Don't create states here, because this function could be called in the
    // constructor of the subclass, and the factory passes the search (which
    // is not fully constructed) as an argument to the Create() function
}

void SgUctSearch::StartSearch(const vector<SgMove>& rootFilter,
                              SgUctTree* initTree)
{
    if (m_threads.size() == 0)
        CreateThreads();
    if (m_numberThreads > 1 && SgTime::DefaultMode() == SG_TIME_CPU)
        // Using CPU time with multiple threads makes the measured time
        // and games/sec not very meaningful; the total cputime is not equal
        // to the total real time, even if there is no other load on the
        // machine, because the time, while threads are waiting for a lock
        // does not contribute to the cputime.
        SgWarning() << "SgUctSearch: using cpu time with multiple threads\n";
    m_raveWeightParam1 = (SgUctValue)(1.0 / m_raveWeightInitial);
    m_raveWeightParam2 = (SgUctValue)(1.0 / m_raveWeightFinal);
    if (initTree == 0)
        m_tree.Clear();
    else
    {
        m_tree.Swap(*initTree);
        if (m_tree.HasCapacity(0, m_tree.Root().NuChildren()))
            m_tree.ApplyFilter(0, m_tree.Root(), rootFilter);
        else
            SgWarning() <<
                "SgUctSearch: "
                "root filter not applied (tree reached maximum size)\n";
    }
    m_statistics.Clear();
    m_aborted = false;
    m_wasEarlyAbort = false;
    m_checkTimeInterval = 1;
    m_numberGames = 0;
    m_lastScoreDisplayTime = m_timer.GetTime();
    OnStartSearch();
    
    m_nextCheckTime = (SgUctValue)m_checkTimeInterval;
    m_startRootMoveCount = m_tree.Root().MoveCount();

    for (unsigned int i = 0; i < m_threads.size(); ++i)
    {
        SgUctThreadState& state = ThreadState(i);
        state.m_randomizeCounter = m_randomizeRaveFrequency;
        state.StartSearch();
    }
}

void SgUctSearch::EndSearch()
{
    OnEndSearch();
}

string SgUctSearch::SummaryLine(const SgUctGameInfo& info) const
{
    ostringstream buffer;
    const vector<const SgUctNode*>& nodes = info.m_nodes;
    for (size_t i = 1; i < nodes.size(); ++i)
    {
        const SgUctNode* node = nodes[i];
        SgMove move = node->Move();
        buffer << ' ' << MoveString(move) << " (" << fixed << setprecision(2)
               << node->Mean() << ',' << node->MoveCount() << ')';
    }
    for (size_t i = 0; i < info.m_eval.size(); ++i)
        buffer << ' ' << fixed << setprecision(2) << info.m_eval[i];
    return buffer.str();
}

void SgUctSearch::UpdateCheckTimeInterval(double time)
{
    if (time < numeric_limits<double>::epsilon())
        return;
    // Dynamically update m_checkTimeInterval (see comment at definition of
    // m_checkTimeInterval)
    double wantedTimeDiff = (m_maxTime > 1 ? 0.1 : 0.1 * m_maxTime);
    if (time < wantedTimeDiff / 10)
    {
        // Computing games per second might be unreliable for small times
        m_checkTimeInterval *= 2;
        return;
    }
    m_statistics.m_gamesPerSecond = GamesPlayed() / time;
    double gamesPerSecondPerThread =
        m_statistics.m_gamesPerSecond / double(m_numberThreads);
    m_checkTimeInterval = SgUctValue(wantedTimeDiff * gamesPerSecondPerThread);
    if (m_checkTimeInterval == 0)
        m_checkTimeInterval = 1;
}

/** Update the RAVE values in the tree for both players after a game was
    played.
    @see SgUctSearch::Rave() */
void SgUctSearch::UpdateRaveValues(SgUctThreadState& state)
{
    for (size_t i = 0; i < m_numberPlayouts; ++i)
        UpdateRaveValues(state, i);
}

void SgUctSearch::UpdateRaveValues(SgUctThreadState& state,
                                   std::size_t playout)
{
    SgUctGameInfo& info = state.m_gameInfo;
    const vector<SgMove>& sequence = info.m_sequence[playout];
    if (sequence.size() == 0)
        return;
    SG_ASSERT(m_moveRange > 0);
    size_t* firstPlay = state.m_firstPlay.get();
    size_t* firstPlayOpp = state.m_firstPlayOpp.get();
    fill_n(firstPlay, m_moveRange, numeric_limits<size_t>::max());
    fill_n(firstPlayOpp, m_moveRange, numeric_limits<size_t>::max());
    const vector<const SgUctNode*>& nodes = info.m_nodes;
    const vector<bool>& skipRaveUpdate = info.m_skipRaveUpdate[playout];
    SgUctValue eval = info.m_eval[playout];
    SgUctValue invEval = InverseEval(eval);
    size_t nuNodes = nodes.size();
    size_t i = sequence.size() - 1;
    bool opp = (i % 2 != 0);

    // Update firstPlay, firstPlayOpp arrays using playout moves
    for ( ; i >= nuNodes; --i)
    {
        SG_ASSERT(i < skipRaveUpdate.size());
        SG_ASSERT(i < sequence.size());
        if (! skipRaveUpdate[i])
        {
            SgMove mv = sequence[i];
            size_t& first = (opp ? firstPlayOpp[mv] : firstPlay[mv]);
            if (i < first)
                first = i;
        }
        opp = ! opp;
    }

    while (true)
    {
        SG_ASSERT(i < skipRaveUpdate.size());
        SG_ASSERT(i < sequence.size());
        // skipRaveUpdate currently not used in in-tree phase
        SG_ASSERT(i >= info.m_inTreeSequence.size() || ! skipRaveUpdate[i]);
        if (! skipRaveUpdate[i])
        {
            SgMove mv = sequence[i];
            size_t& first = (opp ? firstPlayOpp[mv] : firstPlay[mv]);
            if (i < first)
                first = i;
            if (opp)
                UpdateRaveValues(state, playout, invEval, i,
                                 firstPlayOpp, firstPlay);
            else
                UpdateRaveValues(state, playout, eval, i,
                                 firstPlay, firstPlayOpp);
        }
        if (i == 0)
            break;
        --i;
        opp = ! opp;
    }
}

void SgUctSearch::UpdateRaveValues(SgUctThreadState& state,
                                   std::size_t playout, SgUctValue eval,
                                   std::size_t i,
                                   const std::size_t firstPlay[],
                                   const std::size_t firstPlayOpp[])
{
    SG_ASSERT(i < state.m_gameInfo.m_nodes.size());
    const SgUctNode* node = state.m_gameInfo.m_nodes[i];
    if (! node->HasChildren())
        return;
    size_t len = state.m_gameInfo.m_sequence[playout].size();
    for (SgUctChildIterator it(m_tree, *node); it; ++it)
    {
        const SgUctNode& child = *it;
        SgMove mv = child.Move();
        size_t first = firstPlay[mv];
        SG_ASSERT(first >= i);
        if (first == numeric_limits<size_t>::max())
            continue;
        if  (m_raveCheckSame && SgUtil::InRange(firstPlayOpp[mv], i, first))
            continue;
        SgUctValue weight;
        if (m_weightRaveUpdates)
            weight = 2 - SgUctValue(first - i) / SgUctValue(len - i);
        else
            weight = 1;
        m_tree.AddRaveValue(child, eval, weight);
    }
}

void SgUctSearch::UpdateStatistics(const SgUctGameInfo& info)
{
    m_statistics.m_movesInTree.Add(
                            static_cast<float>(info.m_inTreeSequence.size()));
    for (size_t i = 0; i < m_numberPlayouts; ++i)
    {
        m_statistics.m_gameLength.Add(
                               static_cast<float>(info.m_sequence[i].size()));
        m_statistics.m_aborted.Add(info.m_aborted[i] ? 1.f : 0.f);
    }
}

void SgUctSearch::UpdateTree(const SgUctGameInfo& info)
{
    SgUctValue eval = 0;
    for (size_t i = 0; i < m_numberPlayouts; ++i)
        eval += info.m_eval[i];
    eval /= SgUctValue(m_numberPlayouts);
    SgUctValue inverseEval = InverseEval(eval);
    const vector<const SgUctNode*>& nodes = info.m_nodes;
    SgUctValue count = SgUctValue(m_numberPlayouts);
    for (size_t i = 0; i < nodes.size(); ++i)
    {
        const SgUctNode& node = *nodes[i];
        const SgUctNode* father = (i > 0 ? nodes[i - 1] : 0);
        m_tree.AddGameResults(node, father, i % 2 == 0 ? eval : inverseEval,
                              count);
        // Remove the virtual loss
        if (m_virtualLoss && m_numberThreads > 1)
            m_tree.RemoveVirtualLoss(node);
    }
}

void SgUctSearch::WriteStatistics(ostream& out) const
{
    out << SgWriteLabel("Count") << m_tree.Root().MoveCount() << '\n'
        << SgWriteLabel("GamesPlayed") << GamesPlayed() << '\n'
        << SgWriteLabel("Nodes") << m_tree.NuNodes() << '\n';
    if (!m_knowledgeThreshold.empty())
        out << SgWriteLabel("Knowledge") 
            << m_statistics.m_knowledge << " (" << fixed << setprecision(1) 
            << m_statistics.m_knowledge * 100.0 / m_tree.Root().MoveCount()
            << "%)\n";
    m_statistics.Write(out);
    m_mpiSynchronizer->WriteStatistics(out);
}

//----------------------------------------------------------------------------
