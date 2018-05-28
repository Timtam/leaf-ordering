# Leaf ordering of hierarchical clustered trees

A project during summer semester 2018 at the Martin-Luther-University Halle-Wittenberg in the subject Algorithm Engineering

By: Toni Barth, Max Haarbach

## Overview

This project should discover fast and optimal heuristics for ordering leafs of hierachical clustered binar trees. 

Originally this algorithm is meant to work with gene expression data, which should be available as those trees. But for know, we need to use the columns of pictures as test data. These pictures are converted to PGM files (**P**ortable **G**ray**m**ap), which mainly just store the gray values besides some other information.

As a measure for similarity we use the euclidean distance between the column vectors. Through the fact those vectors are no hierachical clustered binary trees, we also need to do the clustering and the tree-building before we can start the ordering. 

## Instructions

1. run `python setup.py build_ext --inplace` to compile all `.pyx`-files to `.c`-files (only **_once_**)
2. run `python main.py`

* input: `test_xyz.pgm` (directory `datasets`)
* output: `test_a.pgm` (**main** directory)
* heuristic 1 can be found in method `sort_a` from class `Graph` in `graph.pyx`
* heuristic 2 can be found in method `sort_b` from class `Graph` in `graph.pyx`
