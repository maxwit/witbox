#!/usr/bin/python

import os,sys,re
from optparse import OptionParser

def split(path):
	print 'splitting %s ...' % path

	fd_src = open(path)

	basename = os.path.basename(path)
	dirname = os.path.dirname(path)

	fd_dst = open(dirname + '/split_' + basename, 'w+')
	fd_dst.write('\def\inmaxwitbook{}\n\n')

	fd_begin = open('article_begin.tmpl')
	str_begin = fd_begin.read()
	fd_begin.close()

	fd_end = open('article_end.tmpl')
	str_end = fd_end.read()
	fd_end.close()

	ch_fd = None
	ch_no = 0

	for line in fd_src:
		match = re.search(r'^\\chapter{(.*)}', line)
		if match:
			if ch_fd <> None:
				ch_fd.write(str_end)
				ch_fd.close()

			ch_no += 1
			ch_fn = 'chapter%d.tex' % ch_no
			print ch_fn

			ch_fd = open(dirname + '/' + ch_fn, 'w+')
			chapter = match.groups()[0]
			ch_fd.write(str_begin.replace('_TITLE_', chapter))

			###
			fd_dst.write(line)
			fd_dst.write('\\input{%s}\n\n' % ch_fn)
		else:
			if re.match(r'^\s*\\end{document}\s*\n', line) <> None:
				fd_dst.write(line)
				break

			if ch_fd <> None:
				ch_fd.write(line)
			else:
				fd_dst.write(line)

	if ch_fd <> None:
		ch_fd.write(str_end)
		ch_fd.close()

	fd_src.close()
	fd_dst.close()

if __name__ == "__main__":
	parser = OptionParser()
	parser.add_option('-f', '--file', dest='path',
					  default=True, action='store_true',
					  help="path to the file to be splitted")

	(options, args) = parser.parse_args()

	if options.path:
		split(args[0])
		exit()

	print 'usage: ...!'
