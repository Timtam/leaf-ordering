import pstats, cProfile

from main import main

cProfile.runctx("main('datasets/gradient/g1_100x100.pgm')", globals(), locals(), "Profile.prof")

s = pstats.Stats("Profile.prof")
s.strip_dirs().sort_stats("time").print_stats()