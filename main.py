# imports
import os.path
import random
import sys

try:
  from leaf_ordering.tree.graph import Graph
  from leaf_ordering.pgm.reader import PGMReader
  from leaf_ordering.pgm.writer import PGMWriter
except ImportError:
  print("""
  Imports failed!
  You've probably forgotten to run python setup.py build_ext --inplace
  """)
  sys.exit()

# creating the graph
graph = Graph()

# loading the first test dataset
reader = PGMReader(os.path.join(os.path.dirname(__file__), 'datasets', 'test_3_1280.pgm').encode('utf-8'))

# reading and processing the data
dataset = reader.read()

# we shuffle the dataset randomly
random.shuffle(dataset)

# build the graph from the dataset
graph.build(dataset)

# sorting
graph.sort_a()
