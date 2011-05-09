#-----------------------------------------------------------------------------
# Tests with large Semeai.
#-----------------------------------------------------------------------------

loadsgf sgf/games/2011/KGS-January/PueGo-pachi2.sgf 190
10 reg_genmove w
#? [M13]*
# extend to avoid a lost semeai.

loadsgf sgf/games/2011/KGS-January/PueGo-pachi2.sgf 191
20 reg_genmove b
#? [M13]*
# surround and win semeai.

