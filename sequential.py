import multiprocessing
import math
from itertools import starmap
import time
import sys

def sum_of_divisors(n):
	i = 2
	summation = 1
	while i <= math.sqrt(n):
		if n % i == 0:
			if n / i == i:
				# i == n / i, same numbers, e.g. 8 * 8 = 64
				summation += i
			else:
				summation += i
				summation += int(n / i)
		i += 1
	return summation

def amicable(x,y):
	return {"x": x, "y": y, "amicable": sum_of_divisors(x)==y and sum_of_divisors(y)==x}

def print_pairs(results):
	for result in results:
		if result["amicable"] == True:
			print(f'{result["x"]} and {result["y"]} are amicable')

if __name__ == '__main__':
	args = sys.argv
	if len(args) != 6:
		sys.exit(f'error, {len(args)} args in mproc.py')
	t1 = time.time()
	xstart = int(args[1])
	xstop = int(args[2])
	ystart = int(args[3])
	ystop = int(args[4])
	granularity = int(args[5])
	X = [n for n in range(xstart, xstop + 1)]
	Y = [n for n in range(ystart, ystop + 1)]
	results = starmap(amicable, [(x,y) for x in X for y in Y if x < y])
	print_pairs(results)
	t2 = time.time()
	print(f'compute time {t2 - t1} s')

