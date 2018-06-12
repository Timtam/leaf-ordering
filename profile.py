import argparse
import os.path
import pstats, cProfile

from main import main

parser = argparse.ArgumentParser()
parser.add_argument('-d', '--dataset', help='path to the pgm file to use', type=str, default=os.path.join(os.path.dirname(__file__), 'datasets', 'gradient/g1_100x100.pgm'))

args = parser.parse_args()

path = args.dataset
if not os.path.exists(path):
  print('This file doesn\'t exist')
  sys.exit()

cProfile.runctx("main('" + path + "')", globals(), locals(), "Profile.prof")

s = pstats.Stats("Profile.prof")
s.strip_dirs().sort_stats("time").print_stats()