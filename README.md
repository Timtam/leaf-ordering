# Leaf ordering of hierarchical clustered trees

A project during summer semester 2018 at the Martin-Luther-University Halle-Wittenberg in the subject Algorithm Engineering

By: Toni Barth, Max Haarbach

## Overview

This project should discover fast and optimal heuristics for ordering leafs of hierachical clustered binar trees. 

Originally this algorithm is meant to work with gene expression data, which should be available as those trees. But for know, we need to use the columns of pictures as test data. These pictures are converted to PGM files (**P**ortable **G**ray**m**ap), which mainly just store the gray values besides some other information.

As a measure for similarity we use the euclidean distance between the column vectors. Through the fact those vectors are no hierachical clustered binary trees, we also need to do the clustering and the tree-building before we can start the ordering. 

## Instructions

1. run `python setup.py build_ext --inplace` to compile all `.pyx`-files to `.c`-files (only **_once_**)

2. run `python main.py`, optionally with option `-d` and your chosen dataset (default is `'gradient/g1_100x100.pgm'`)  
   * for instance use `python main.py -d 'datasets/gradient/g1_10x10.pgm'`
   * `main.py` will output the overall (sum of) distances for each heuristic
   
3. you can also run `python profile.py | grep '^Overall|\(sort_a\)|\(sort_b\)'` for profiling the runtimes for each heuristic  
   * also with option `-d` like the `main.py` and the same default:  
     `python profile.py -d 'datasets/gradient/g1_10x10.pgm' | grep '^Overall|\(sort_a\)|\(sort_b\)'`

4. for profiling whole sets of one kind of datasets (as `gradient`, `photo` or `test_picture`) you can run the bash scripts `profile_gradient.sh`, `profile_photo.sh` or `profile_test_pic.sh` after the command `sh`  
   * these scripts are limited up to the test instances of size 100

* heuristic 1 can be found in method `sort_a` from class `Graph` in `graph.pyx`
* heuristic 2 can be found in method `sort_b` from class `Graph` in `graph.pyx`
* input: see directory `datasets/gradient/`, `datasets/photo/` and `datasets/test_picture/`
* output: `test_a.pgm` (from `sort_a`) + `test_b.pgm` (from `sort_b`) (in **main** directory)
