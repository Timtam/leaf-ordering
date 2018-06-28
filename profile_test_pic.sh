#!/usr/bin/env bash
echo t1:
echo 10:
python profile.py -d "datasets/test_picture/t1_10x7.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
echo 50:
python profile.py -d "datasets/test_picture/t1_50x36.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
echo 100:
python profile.py -d "datasets/test_picture/t1_100x71.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"

echo t2:
echo 10:
python profile.py -d "datasets/test_picture/t2_10x8.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
echo 50:
python profile.py -d "datasets/test_picture/t2_50x38.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
echo 100:
python profile.py -d "datasets/test_picture/t2_100x75.pgm" | grep -E "^Overall .*|\(sort_a\)|\(sort_b\)"
