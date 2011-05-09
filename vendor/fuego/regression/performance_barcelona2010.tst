#-----------------------------------------------------------------------------
# Tests from games played at Barcelona 2010 man-machine competition
# @todo Add the tests.
# For now, this is mainly a placeholder file
#-----------------------------------------------------------------------------

loadsgf sgf/games/2010/FuegoGB-Barcelona/Tsai-FuegoGB.sgf 24
10 reg_genmove b
#? [L10]*
# joseki, must block after 3-3 invasion

#-----------------------------------------------------------------------------
loadsgf sgf/games/2010/FuegoGB-Barcelona/Chou4p-FuegoGB.sgf 5
1010 reg_genmove b
#? [! G7]
# @todo: I think G7 is bad but do not know the best move

#-----------------------------------------------------------------------------
loadsgf sgf/games/2010/FuegoGB-Barcelona/FuegoGB-Chou4p.sgf 24
2010 reg_genmove w
#? [G7]*

#-----------------------------------------------------------------------------

loadsgf sgf/games/2010/FuegoGB-Barcelona/Chou9p-FuegoGB.sgf 8
3010 reg_genmove w
#? [F7]*

#-----------------------------------------------------------------------------
loadsgf sgf/games/2010/FuegoGB-Barcelona/FuegoGB-Chou9p.sgf 40
4010 reg_genmove w
#? [J5]*

#-----------------------------------------------------------------------------

loadsgf sgf/games/2010/FuegoGB-Barcelona/Yen-FuegoGB.sgf 14
5010 reg_genmove b
#? [C10]*
