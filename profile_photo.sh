#!/usr/bin/env bash
echo p1:
echo 10:
python profile.py -d "datasets/photo/p1_10x7.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
echo 50:
python profile.py -d "datasets/photo/p1_50x33.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
echo 100:
python profile.py -d "datasets/photo/p1_100x67.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"

echo p2:
echo 10:
python profile.py -d "datasets/photo/p2_10x7.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
echo 50:
python profile.py -d "datasets/photo/p2_50x33.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
echo 100:
python profile.py -d "datasets/photo/p2_100x67.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
