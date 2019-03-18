#!/usr/bin/env python

import os
from glob import glob

from pygments.formatters.html import HtmlFormatter
from pygments.lexers import load_lexer_from_file
from pygments import highlight

LEXER_FILENAME = "cddl_lexer.py"
OUTPUT_EXTENSION = ".html"

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
  formatter = HtmlFormatter()

  directory, _ = os.path.split(os.path.abspath(__file__))
  lexer = load_lexer_from_file(os.path.join(directory, LEXER_FILENAME))

  pygmentize_dir(lexer, formatter)
