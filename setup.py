from setuptools import setup
from distutils.extension import Extension
from Cython.Build import cythonize

extensions = [
  Extension(
    "*",
    ["leaf_ordering/pgm/*.pyx"],
    language = "c"
  ),
  Extension(
    "*",
    ["leaf_ordering/tree/*.pyx"],
    language="c"
  )
]

setup(
  name="leaf-ordering",
  version="0.1",
  author = "Toni Barth, Max Haarbach",
  author_email = "software@satoprogs.de",
  description = "An example leaf-ordering algorithm in cython",
  ext_modules = cythonize(extensions),
  packages = [
    "leaf_ordering",
    "leaf_ordering/pgm",
    "leaf_ordering/tree"
  ],
  zip_safe=False
)
