# imports
import argparse
import os.path
import sys

try:
  from leaf_ordering.tree.graph import Graph
  from leaf_ordering.pgm.reader import PGMReader
  from leaf_ordering.pgm.writer import PGMWriter
  from leaf_ordering.tree.validator import Validator
  from leaf_ordering.shuffle import random_shuffle_dataset
except ImportError:
  print("""
  Imports failed!
  You've probably forgotten to run python setup.py build_ext --inplace
  """)
  sys.exit()

# creating argument parser and adding some arguments
parser = argparse.ArgumentParser()
parser.add_argument('-d', '--dataset', help='path to the pgm file to use', type=str, default=os.path.join(os.path.dirname(__file__), 'datasets', 'test_3_1280.pgm'))

args = parser.parse_args()
path = args.dataset
if not os.path.exists(path):
  print('This file doesn\'t exist')
  sys.exit()

def main(path):

  # creating the graph
  graph = Graph()

  # loading the first test dataset
  reader = PGMReader(path.encode('utf-8'))

  # reading and processing the data
  dataset = reader.read()

  # we shuffle the dataset randomly
  dataset = random_shuffle_dataset(dataset)

  # build the graph from the dataset
  graph.build(dataset)

  # printing the overall distance before sorting
  print("Overall distance before ordering with first heuristic: {0}".format(graph.get_distance()))

  # sorting
  graph.sort_a()

  # validation of the graph
  validator = Validator()
  validator.check_cycle(graph)

  # printing the overall distance after sorting
  print("Overall distance after ordering with first heuristic: {0}".format(graph.get_distance()))

  # retrieving the ordered data from the graph
  data = graph.get_data()

  # initializing the writer and writing test data to disk
  writer = PGMWriter(reader.maximum_gray)
  writer.write("test_a.pgm".encode('utf-8'), data)

  # clearing the graph
  graph.clear()

  # build the graph from the dataset
  graph.build(dataset)

  # printing the overall distance before sorting
  print("Overall distance before ordering with second heuristic: {0}".format(graph.get_distance()))

  # sorting
  graph.sort_b()

  # validation of the graph
  validator = Validator()
  validator.check_cycle(graph)

  # printing the overall distance after sorting
  print("Overall distance after ordering with second heuristic: {0}".format(graph.get_distance()))

  # retrieving the ordered data from the graph
  data = graph.get_data()

  # initializing the writer and writing test data to disk
  writer = PGMWriter(reader.maximum_gray)
  writer.write("test_b.pgm".encode('utf-8'), data)

if __name__ == '__main__':
  main(path)
