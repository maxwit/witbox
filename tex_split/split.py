#!/usr/bin/python

import os,sys,re
from optparse import OptionParser

def split(path):
	print 'splitting %s ...' % path

	fd_src = open(path)

	basename = os.path.basename(path)
	dirname = os.path.dirname(path)

	fd_begin = open('article_begin.tmpl')
	str_begin = fd_begin.read()
	fd_begin.close()

	fd_end = open('article_end.tmpl')
	str_end = fd_end.read()
	fd_end.close()

	fd_ch = None
	ch = 0
	for line in fd_src:
		match = re.search(r'^\\chapter{(.*)}', line)
		if match:
			if ch > 0:
				fd_ch.write(str_end)
				fd_ch.close()

			ch += 1
			fd_ch = open(dirname + '/chapter%d.tex' % ch, 'w+')
			chapter = match.groups()[0]
			fd_ch.write(str_begin.replace('_TITLE_', chapter))

		elif fd_ch <> None:
			if re.match(r'^\s*\\end{document}\s*\n', line) == None:
				print line
				fd_ch.write(line)

	if fd_ch <> None:
		fd_ch.write(str_end)
		fd_ch.close()

	fd_src.close()


if __name__ == "__main__":
	parser = OptionParser()
	parser.add_option('-f', '--file', dest='path',
					  default=False, action='store_true',
					  help="path to the file to be splitted")

	(options, args) = parser.parse_args()

	if options.path:
		split(args[0])
		exit()

	print 'usage: ...!'
