//----------------------------------------------------------------------------
/** @file GoGame.h
    GoGame class, play and replay moves in a game tree. */
//----------------------------------------------------------------------------

#ifndef GO_GAME_H
#define GO_GAME_H

#include <string>
#include "GoBoard.h"
#include "GoBoardUpdater.h"
#include "GoBoardUtil.h"
#include "GoTimeSettings.h"
#include "SgNode.h"
#include "SgPoint.h"
#include "SgTimeRecord.h"

class SgSearchStatistics;

//----------------------------------------------------------------------------

/** Game state and move history including variations.
    Contains a game tree, a pointer to a current node, a board and information
    of the time left. The current node is always a valid node of the tree and
    the board and time records reflect the game state at the current node.
    @todo Remove non-const function Time() and decouple time measurement from
    tracking the time left at a node. This class should not have to deal with
    time measurement, instead add a time parameter to AddMove() that informs
    the game about the time that needs to be subtracted from the time left.
    @todo Also ensure in GoGame that the time settings and time left records
    always reflect the state at the current node. This should be implemented
    in GoBoardUpdater::Update(), which is used by GoGame. */
class GoGame
{
public:
    /** Create a game record for replaying games on the given board. */
    explicit GoGame(int boardSize = GO_DEFAULT_SIZE);

    ~GoGame();

    /** Init from an existing game tree.
        Takes the ownership of the tree. */
    void Init(SgNode* root);

    /** Delete the old game record and start with a fresh one.
        Init the board with the given parameters, and create a root node
        to start with. */
    void Init(int size, const GoRules& rules);

    /** Get the board associated with this game record. */
    const GoBoard& Board() const;

    /** Return the root of this tree. */
    const SgNode& Root() const;

    const GoTimeSettings& TimeSettings() const;

    /** Set handicap stones at explicitely given points.
        If the current node alread has children, a new child is created with
        the handicap setup (and made the current node), otherwise the
        handicap stones are added to the current node.
        @pre Board is empty */
    void PlaceHandicap(const SgVector<SgPoint>& stones);

    /** Set up a position on the board.
        Creates a new child node of the current node and adds the appropriate
        AB, AW and AE properties to change the board position to the
        position defined by the given stone lists. Makes the new child node
        the current node. */
    void SetupPosition(const SgBWArray<SgPointSet>& stones);

    /** Add move to the game record and make it the current node.
        Add move as the next move at the current position.
        If a node with that move already exists, then don't add a new one.
        Return the node with that move.
        Also add any statistics from 'stat' and time left to that node. */
    void AddMove(SgMove move, SgBlackWhite player,
                 const SgSearchStatistics* stat = 0,
                 bool makeMainVariation = true);

    /** Add a comment to the current node. */
    void AddComment(const std::string& comment);

    /** Add a comment to any node. */
    void AddComment(const SgNode& node, const std::string& comment);

    /** Add a node with a comment that a player resigned.
        For informational purposes only, the resign node will not be made
        the current node. */
    const SgNode& AddResignNode(SgBlackWhite player);

    /** Append a node as a new child to the current node.
        @param child The new child. The ownership is transfered. The user is
        responsible that the subtree is consistent and contains no lines with
        illegal moves with respect to the position at the current node. */
    void AppendChild(SgNode* child);

    /** Play to the given node.
        @c dest must be in this tree, or 0.
        Also updates the clock. */
    void GoToNode(const SgNode* dest);

    /** Play to the next node in the given direction. */
    void GoInDirection(SgNode::Direction dir);

    /** Return whether there is a next node in the given direction. */
    bool CanGoInDirection(SgNode::Direction dir) const;

    /** Set the current player.
        Same meaning as the SGF property PL. */
    void SetToPlay(SgBlackWhite toPlay);

    /** Return whether the game is finished. */
    bool EndOfGame() const;

    /** Deprecated.
        Non-const access to time left records will be removed in the future
        because its part of the class invariants of this class that they
        reflect the state corresponding to the current node. */
    SgTimeRecord& Time();

    /** The time left in the game at the current position. */
    const SgTimeRecord& Time() const;

    /** Return the current position in the tree.
        @todo changed from protected to public because of getting
        the current time left. */
    const SgNode* CurrentNode() const;

    /** Return the move of the current node.
        Return NullMove if no current move. */
    SgMove CurrentMove() const;

    /** Get the number of moves since root or last node with setup
        properties. */
    int CurrentMoveNumber() const;


    /** @name Query or change game info properties */
    // @{

    /** Set komi property in the root node and delete all komi properties
        in the tree. */
    void SetKomiGlobal(GoKomi komi);

    /** Set time settings properties in the root node and delete all such
        properties in the rest of the tree.
        @param timeSettings
        @param overhead See SgTimeRecord */
    void SetTimeSettingsGlobal(const GoTimeSettings& timeSettings,
                               double overhead = 0);

    /** Get the player name.
        Searches to nearest game info node on the path to the root node that
        has a player property. Returns an empty string if unknown. */
    std::string GetPlayerName(SgBlackWhite player) const;

    /** Set the player name at root node or most recent node with this
        property. */
    void UpdatePlayerName(SgBlackWhite player, const std::string& name);

    /** Set the date at root node or most recent node with this property. */
    void UpdateDate(const std::string& date);

    /** Get the game result.
        Searches to nearest game info node on the path to the root node that
        has a result property. Returns an empty string if unknown. */
    std::string GetResult() const;

    /** Set the result at root node or most recent node with this property. */
    void UpdateResult(const std::string& result);

    /** Get the game name.
        Searches to nearest game info node on the path to the root node that
        has a game name property. Returns an empty string if unknown. */
    std::string GetGameName() const;

    /** Set the game name at root node or most recent node with this
        property. */
    void UpdateGameName(const std::string& name);

    void SetRulesGlobal(const GoRules& rules);

    // @} // name

private:
    GoBoard m_board;

    /** The root node of the current tree. */
    SgNode* m_root;

    /** The position in the current tree. */
    SgNode* m_current;

    GoBoardUpdater m_updater;

    GoTimeSettings m_timeSettings;

    /** A record of the clock settings and time left. */
    SgTimeRecord m_time;

    /** Moves inserted into a line of play instead of added at the end. */
    int m_numMovesToInsert;

    /** Not implemented. */
    GoGame(const GoGame&);

    /** Not implemented. */
    GoGame& operator=(const GoGame&);

    std::string GetGameInfoStringProp(SgPropID id) const;

    void InitHandicap(const GoRules& rules, SgNode* root);

    SgNode* NonConstNodePtr(const SgNode* node) const;

    SgNode& NonConstNodeRef(const SgNode& node) const;

    void UpdateGameInfoStringProp(SgPropID id, const std::string& value);
};

inline void GoGame::AddComment(const std::string& comment)
{
    m_current->AddComment(comment);
}

inline const GoBoard& GoGame::Board() const
{
    return m_board;
}

inline const SgNode& GoGame::Root() const
{
    return *m_root;
}

inline SgTimeRecord& GoGame::Time()
{
    return m_time;
}

inline const SgTimeRecord& GoGame::Time() const
{
    return m_time;
}

inline const GoTimeSettings& GoGame::TimeSettings() const
{
    return m_timeSettings;
}

inline const SgNode* GoGame::CurrentNode() const
{
    return m_current;
}

//----------------------------------------------------------------------------

/** Utility functions for GoGame. */
namespace GoGameUtil
{
    /** Goto last node in main variation before move number.
        This function can be used for implementing the loadsgf GTP command.
        @param game (current node must be root)
        @param moveNumber move number (-1 means goto last node in main
        variation)
        @return false if moveNumber greater than moves in main variation */
    bool GotoBeforeMove(GoGame* game, int moveNumber);
}

//----------------------------------------------------------------------------

#endif // GO_GAME_H

