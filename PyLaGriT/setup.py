from distutils.core import setup
import os

setup(name='pylagrit',
	version='1.0.0',
	description='Python interface for LaGriT',
	author='Dylan R. Harp',
	author_email='dharp@lanl.gov',
	url='lagrit.lanl.gov',
	license='LGPL',
	install_requires=[
		'pexpect==4.6.0',
		'numpy',
		],
	packages=[
		'pylagrit',]
	)
