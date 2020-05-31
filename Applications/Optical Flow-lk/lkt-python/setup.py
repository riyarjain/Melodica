#!/usr/bin/env python
req=['nose','scipy','numpy','matplotlib']

import pip
try:
    import conda.cli
    conda.cli.main('install',*req)
except Exception as e:
    pip.main(['install'] + req)

# %%
from setuptools import setup

setup(name='pyOpticalFlow',
      packages=['pyOpticalFlow'],
      author='Michael Hirsch',
      install_requires=req,
	  )
