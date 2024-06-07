# Copyright (c) 2024 Fries_I23
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import os
import sys

def replace_path_in_lcov(input_file, current_path, output_file):
    with open(input_file, 'r', encoding='utf-8') as file:
        lines = file.readlines()

    with open(output_file, 'w', encoding='utf-8') as file:
        for line in lines:
            if line.startswith("SF:"):
                path = line.split(":", maxsplit=1)[1]
                if (os.path.isabs(path)):
                    line = "SF:" + os.path.relpath(path, current_path)
            file.write(line)

if __name__ == "__main__":
    lvoc_path = sys.argv[1]
    current_path = os.path.abspath(os.getcwd())

    replace_path_in_lcov(lvoc_path, current_path, lvoc_path)
    print(f"{current_path} format {lvoc_path} Done!")
