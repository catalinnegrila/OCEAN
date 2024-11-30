#!/bin/bash
# /Volumes/sci/shipside/SKQ202417S/cpies/download_currents.sh
# From: https://gist.github.com/vratiu/9780109
RED_BOLD="\033[1;31m"
BOLD="\033[1m"
NORM="\033[0m"
if [ $# -ne 1 ]; then
    printf "${RED_BOLD} ERROR: missing command line parameters${NORM}\n\n"
    printf "${BOLD} Usage:${NORM} $0 <wpN>\n"
    printf "${BOLD} Example:${NORM} $0 wp2\n"
else
    script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    for s in wh300 os38nb os75nb
    do
        png_path="${script_dir}/${1}_${s}.png"
        png_url="https://web.sikuliaq.alaska.edu/adcp/figures/${s}_lastens.png"
        if test -f ${png_path}; then
            printf "${RED_BOLD} ERROR: ${png_path} already exists!\n"
        else
            printf "${BOLD}${png_path}${NORM}\n" 
            curl ${png_url} -o ${png_path}
        fi
    done
fi

