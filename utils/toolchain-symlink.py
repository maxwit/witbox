import os

for fn in os.listdir('.'):
	tool = fn.split('-')
	del tool[3], tool[1]
	fm = '-'.join(tool)
	os.symlink(fn, fm)
