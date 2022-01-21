#!/usr/bin/env python

import os
import re
from glob import glob

from pygments.formatters.html import HtmlFormatter
from pygments import highlight

from cddl_lexer import CustomLexer as CddlLexer
import openscreen_cddl_dfns

OUTPUT_EXTENSION = ".html"

CDDL_TYPE_KEY_RE = re.compile(r'(<span class="nc">)([A-Za-z0-9-]+)');

class OSPHtmlFormatter(HtmlFormatter):
  def wrap(self, source, outfile):
    return self._wrap_code(source)

  def _wrap_code(self, source):
    yield 0, '<div><pre>'
    for i, t in source:
      if i == 1:
        m = CDDL_TYPE_KEY_RE.search(t)
        if m and m.group(2) in openscreen_cddl_dfns.LINKED_TYPES:
          t = CDDL_TYPE_KEY_RE.sub(r'\g<1><dfn>\g<2></dfn>', t)
        yield 1, t
    yield 0, '</pre></div>'
  

def pygmentize_file(lexer, formatter, filename):
  print("Reading file from: {}".format(filename))
  with open(filename, 'r') as f:
    contents = f.read()

  return_val = highlight(contents, lexer, formatter)
  output_filename = "{}{}".format(os.path.splitext(filename)[0],
                                  OUTPUT_EXTENSION)

  with open(output_filename, 'w') as f:
    print("Pygmentizing output to: {}".format(output_filename))
    f.write(return_val)


def pygmentize_dir(lexer, formatter):
  for filename_match in lexer.filenames:
    for filename in glob(filename_match):
      pygmentize_file(lexer, formatter, filename)

if __name__ == "__main__":
  formatter = OSPHtmlFormatter()

  directory, _ = os.path.split(os.path.abspath(__file__))
  lexer = CddlLexer()

  pygmentize_dir(lexer, formatter)
