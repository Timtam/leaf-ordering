import os
import os.path

from distutils.core import setup
from distutils.command.build_ext import build_ext
from distutils.extension import Extension
try:
  from Cython.Build import cythonize
  HAVE_CYTHON = True
except ImportError:
  HAVE_CYTHON = False

USE_CYTHON = HAVE_CYTHON
DEBUG_MODE = False

if 'USE_CYTHON' in os.environ:
  USE_CYTHON = os.environ['USE_CYTHON'].lower() in ('1', 'yes')

if 'DEBUG' in os.environ:
  DEBUG_MODE = os.environ['DEBUG'].lower() in ('1', 'yes')

if USE_CYTHON and not HAVE_CYTHON:
  raise RuntimeError("cython not found")

OPENMP = [
  "leaf_ordering.pgm.writer",
  "leaf_ordering.tree.graph"
]

class build_ext_compiler_check(build_ext):
  def build_extensions(self):
    compiler = self.compiler.compiler_type
    for ext in self.extensions:
      comp_args = []
      link_args = []
      if compiler == 'mingw32' or compiler == 'unix' or compiler == 'cygwin':
        comp_args += ['-ffast-math']
        if ext.name in OPENMP:
          comp_args.append('-fopenmp')
          link_args.append('-fopenmp')
        if DEBUG_MODE:
          comp_args += ['-g', '-O0']
      elif compiler == 'msvc':
        comp_args.append("/fp:fast")
        if ext.name in OPENMP:
          comp_args.append('/openmp')
        if DEBUG_MODE:
          comp_args += ['/Od', '-Zi']
          link_args.append('-debug')
      ext.extra_compile_args = comp_args
      ext.extra_link_args = link_args
    build_ext.build_extensions(self)

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
      "leaf_ordering/tree/graph.pyx",
      "leaf_ordering/tree/matrix.c"
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
  Extension(
    "leaf_ordering.tree.validator",
    [
      "leaf_ordering/tree/validator.pyx"
    ],
    language = "c"
  ),
  Extension(
    "leaf_ordering.shuffle",
    [
      "leaf_ordering/shuffle.pyx"
    ],
    language = "c"
  ),
]

if USE_CYTHON:
  extensions = cythonize(
    extensions,
    gdb_debug = DEBUG_MODE
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
  cmdclass = {
    'build_ext': build_ext_compiler_check
  }
)
