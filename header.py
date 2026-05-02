#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# ------------------ Simple ASCII mapping ------------------
ASCII_MAP = {
    "A": [],
    "M": [],
    "H": [],
    "D": [],
    "I": [],
}

def generate_ascii_word(word):
    # Split each letter into lines
    lines_per_letter = [ASCII_MAP[c] for c in word]
    # Combine letter lines horizontally
    ascii_lines = []
    for i in range(len(lines_per_letter[0])):
        line = "  ".join(letter[i] for letter in lines_per_letter)
        ascii_lines.append(line)
    return ascii_lines

# ------------------ 42-style banner ------------------
PROJECT_NAME = "Inception of Things"
AUTHOR = "aamhamdi"
EMAIL = "aamhamdi1337@gmail.com"
CREATED = "2026/03/30"
QUOTE = '"Code. Break. Fix. Repeat."'
BANNER_WIDTH = 80

def pad_line(left, right, total_width=BANNER_WIDTH):
    space = total_width - len(left) - len(right)
    if space < 1: space = 1
    return left + " " * space + " " + right

def main():
    ascii_lines = generate_ascii_word("AAMHAMDI")
    banner = []
    banner.append("/*" + "*" * (BANNER_WIDTH-4) + " */")
    banner.append("/*" + " " * (BANNER_WIDTH-4) + " */")
    
    # Project name line
    left = f"   ### {PROJECT_NAME}"
    right = ascii_lines[0] if ascii_lines else ""
    banner.append(pad_line("/*" + left, right + " */"))
    
    # Info lines + remaining ASCII
    info_lines = [
        f"     - Author  : {AUTHOR} ",
        f"     - Email   : {EMAIL} ",
        f"     - Created : {CREATED} ",
    ]

    banner.append("/*" + " " * (BANNER_WIDTH-4) + " */")
    
    for i in range(max(len(info_lines), len(ascii_lines)-1)):
        left = info_lines[i] if i < len(info_lines) else ""
        banner.append(pad_line("/*" + left, "        */"))
    
    banner.append("/*" + " " * (BANNER_WIDTH-4) + " */")
    
    # Quote line
    banner.append(pad_line("/*" + "   " + QUOTE, "" + " */"))
    
    banner.append("/*" + " " * (BANNER_WIDTH-4) + " */")
    banner.append("/*" + "*" * (BANNER_WIDTH-4) + " */")
    
    # Print banner
    for line in banner:
        print(line)

if __name__ == "__main__":
    main()