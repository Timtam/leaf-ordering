import os
import os.path

from setuptools import setup
from distutils.extension import Extension
try:
  from Cython.Build import cythonize
  HAVE_CYTHON = True
except ImportError:
  HAVE_CYTHON = False

USE_CYTHON = HAVE_CYTHON

if 'USE_CYTHON' in os.environ:
  USE_CYTHON = os.environ['USE_CYTHON'].lower() in ('1', 'yes')

if USE_CYTHON and not HAVE_CYTHON:
  raise RuntimeError("cython not found")

def no_cythonize(extensions, **_ignore):
  for extension in extensions:
    sources = []
    for sfile in extension.sources:
      path, ext = os.path.splitext(sfile)
      if ext in ('.pyx', '.py'):
        if extension.language == 'c++':
          ext = '.cpp'
        else:
          ext = '.c'
        sfile = path + ext
      sources.append(sfile)
    extension.sources[:] = sources
  return extensions

extensions = [
  Extension(
    "leaf_ordering.pgm.reader",
    [
      "leaf_ordering/pgm/reader.pyx"
    ],
    language = "c"
  ),
  Extension(
    "leaf_ordering.pgm.writer",
    [
      "leaf_ordering/pgm/writer.pyx"
    ],
    language = "c"
  ),
  Extension(
    "leaf_ordering.tree.graph",
    [
      "leaf_ordering/tree/graph.pyx"
    ],
    language="c"
  ),
  Extension(
    "leaf_ordering.tree.node",
    [
      "leaf_ordering/tree/node.pyx"
    ],
    language = "c"
  ),
]

if USE_CYTHON:
  extensions = cythonize(
    extensions
  )
else:
  extensions = no_cythonize(extensions)

setup(
  name="leaf-ordering",
  version="0.1",
  author = "Toni Barth, Max Haarbach",
  author_email = "software@satoprogs.de",
  description = "An example leaf-ordering algorithm in cython",
  ext_modules = extensions,
  packages = [
    "leaf_ordering",
    "leaf_ordering/pgm",
    "leaf_ordering/tree"
  ],
  zip_safe=False
)
