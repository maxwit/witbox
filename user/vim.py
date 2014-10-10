def config(user, conf):
	rc = user.home + '/.vimrc'
	dst = open(rc, 'w+')
	src = open('user/vim/vimrc')
	for line in src:
		dst.write(line)
	src.close()
	dst.close()

	return [rc]
