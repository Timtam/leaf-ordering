#!/usr/bin/env bash
echo g1:
echo 10:
python profile.py -d "datasets/gradient/g1_10x10.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
echo 50:
python profile.py -d "datasets/gradient/g1_50x50.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
echo 100:
python profile.py -d "datasets/gradient/g1_100x100.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"

echo g2:
echo 10:
python profile.py -d "datasets/gradient/g2_10x7.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
echo 50:
python profile.py -d "datasets/gradient/g2_50x33.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
echo 100:
python profile.py -d "datasets/gradient/g2_100x67.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
