#-----------------------------------------------------------------------------
# Tests involving seki for static safety solver
# @todo Currently, there is no static seki recognition, so just
# recognizes the territories
#-----------------------------------------------------------------------------

loadsgf sgf/seki/seki-eye-vs-eye.1.sgf

10 go_safe static black
#? [0]
# full answer with seki detection: 16

11 go_safe static white
#? [16 .*]
# full answer with seki detection: 19

12 go_safe_dame_static
#? []

# 13 go_safe_shared_liberties_in_seki
# B5

loadsgf sgf/seki/seki-eye-vs-no-eye.1.sgf

20 go_safe static black
#? [0]
# full answer with seki detection: 12

21 go_safe static white
#? [16 .*]
# full answer with seki detection: 22

22 go_safe_dame_static
#? []

# 23 go_safe_shared_liberties_in_seki
# B5 E2

loadsgf sgf/seki/static-safety-seki-bug.sgf

30 go_safe benson black
#? [18 .*]

31 go_safe benson white
#? [16 .*]

40 go_safe static black
#? [48]*
# misclassifies seki as safe black
# 25 pts for top left, 5 pts for seki stones

41 go_safe static white
#? [30 .*]*

42 go_safe_dame_static
#? [E6]*

# 43 go_safe_shared_liberties_in_seki
# F9 J7
