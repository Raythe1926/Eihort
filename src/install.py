#!/usr/bin/env python

import os, os.path, shutil

def copy(src, dest, mode):
	# For now.. copy & change mode
	shutil.copy(src, dest)
	os.chmod(dest, mode)

def mkdir_p(dest, mode):
	# Something to do?
	if dest and not os.path.exists(dest):
		# Create parent
		mkdir_p(os.path.dirname(dest), mode)
		# Create directory & change mode
		os.mkdir(dest)
		os.chmod(dest, mode)

def install_file(src, dest, **options):
	# Create necessary directories
	mkdir_p(os.path.dirname(dest), mode = options['dirmode'] & ~options['umask'])
	# Copy file
	copy(src, dest, mode = options['mode'] & ~options['umask'])

def install_as(src, dest, **options):
	# Is a directory?
	if os.path.isdir(src):
		# Install components
		for arg in os.listdir(src):
			install_as(os.path.join(src, arg), os.path.join(dest, arg), **options)
	else:
		# Install a file
		install_file(src, dest, **options)

def install(sources, dest, **options):
	# Check destination
	if dest.endswith('/'):
		for src in sources:
			install_as(src, os.path.join(dest, os.path.basename(src)), **options)
	else:
		for src in sources:
			install_as(src, dest, **options)

if __name__ == '__main__':
	import getopt, sys

	# Parse arguments
	try:
		opts, args = getopt.getopt(sys.argv[1:], '', ('dirmode=', 'mode=',
			'umask='))
		opts = dict(opts)

		if len(args) < 1:
			raise getopt.GetoptError('missing destination')

	except getopt.GetoptError, error:
		sys.stderr.write('{}: {}\n'.format(sys.argv[0], error))
		sys.exit(1)

	# Translate options
	options = {'dirmode': 0o777, 'mode': 0o666, 'umask': 0o22}
	for mode in ('dirmode', 'mode', 'umask'):
		if '--{}'.format(mode) in opts:
			options[mode] = int(opts['--{}'.format(mode)], 8)

	# Install 
	install(args[:-1], args[-1], **options)
