#!/usr/bin/python

fd_src = open('cpio_vol3.tex')
fd_dst = open('cpio_vol3_split.tex', 'w+')

for line in fd_src:
	fd_dst.write(line)

fd_dst.close()
fd_src.close()
