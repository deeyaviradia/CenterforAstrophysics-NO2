#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (viradiadeeya): " username
    username=${username:-viradiadeeya}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2012/OMI-Aura_L3-OMNO2d_2012m1231_v003-2019m1231t092946.he5"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2012/OMI-Aura_L3-OMNO2d_2012m1231_v003-2019m1231t092946.he5 -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2012/OMI-Aura_L3-OMNO2d_2012m1231_v003-2019m1231t092946.he5 | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0426_v003-2019m1121t234446.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0425_v003-2019m1121t234312.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0424_v003-2019m1121t234332.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0423_v003-2019m1122t000903.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0422_v003-2019m1121t234508.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0421_v003-2019m1121t234223.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0420_v003-2019m1121t234157.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0419_v003-2019m1121t233024.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0418_v003-2019m1121t232117.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0417_v003-2019m1121t232103.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0416_v003-2019m1121t233018.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0415_v003-2019m1121t232027.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0414_v003-2019m1121t232051.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0413_v003-2019m1121t232108.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0412_v003-2019m1121t232044.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0411_v003-2019m1121t232107.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0410_v003-2019m1121t232211.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0409_v003-2019m1121t232235.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0408_v003-2019m1121t231411.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0407_v003-2019m1121t232128.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0406_v003-2019m1121t234449.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0405_v003-2019m1121t231402.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0404_v003-2019m1121t231415.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0403_v003-2019m1121t232151.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0402_v003-2019m1121t232150.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0401_v003-2019m1121t231414.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0331_v003-2019m1121t232249.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0330_v003-2019m1121t231018.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0329_v003-2019m1121t230940.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0328_v003-2019m1121t231353.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0327_v003-2019m1121t225449.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0326_v003-2019m1121t230951.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0325_v003-2019m1121t231359.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0324_v003-2019m1121t230234.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0323_v003-2019m1121t230328.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0322_v003-2019m1121t232140.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0321_v003-2019m1121t225339.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0320_v003-2019m1121t231520.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0319_v003-2019m1121t230437.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0318_v003-2019m1121t225646.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0317_v003-2019m1121t225418.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0316_v003-2019m1121t230417.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0315_v003-2019m1121t225430.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0314_v003-2019m1121t225424.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0313_v003-2019m1121t225358.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0312_v003-2019m1121t225414.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0311_v003-2019m1121t225441.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0310_v003-2019m1121t225411.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0309_v003-2019m1121t230426.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0308_v003-2019m1121t225638.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0307_v003-2019m1121t224704.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0306_v003-2019m1121t225335.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0305_v003-2019m1121t224743.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0304_v003-2019m1121t225444.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0303_v003-2019m1121t224307.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0302_v003-2019m1121t225634.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0301_v003-2019m1121t223903.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0228_v003-2019m1121t223914.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0227_v003-2019m1121t223915.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0226_v003-2019m1121t224741.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0225_v003-2019m1121t223905.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0224_v003-2019m1121t223428.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0223_v003-2019m1121t224123.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0222_v003-2019m1121t223235.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0221_v003-2019m1121t225715.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0220_v003-2019m1121t223655.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0219_v003-2019m1121t223005.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0218_v003-2019m1121t222731.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0217_v003-2019m1121t223516.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0216_v003-2019m1121t222649.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0215_v003-2019m1121t223058.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0214_v003-2019m1121t222446.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0213_v003-2019m1121t222432.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0212_v003-2019m1121t222735.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0211_v003-2019m1121t223518.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0210_v003-2019m1121t224232.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0209_v003-2019m1121t223250.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0208_v003-2019m1121t221506.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0207_v003-2019m1121t220912.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0206_v003-2019m1121t222342.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0205_v003-2019m1121t221840.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0204_v003-2019m1121t221508.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0203_v003-2019m1121t221133.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0202_v003-2019m1121t223851.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0201_v003-2019m1121t220603.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0131_v003-2019m1121t220553.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0130_v003-2019m1121t223009.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0129_v003-2019m1121t221524.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0128_v003-2019m1121t222020.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0127_v003-2019m1121t220842.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0126_v003-2019m1121t222146.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0125_v003-2019m1121t221111.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0124_v003-2019m1121t214833.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0123_v003-2019m1121t222158.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0122_v003-2019m1121t215901.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0121_v003-2019m1121t221832.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0120_v003-2019m1121t220001.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0119_v003-2019m1121t221658.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0118_v003-2019m1121t220001.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0117_v003-2019m1121t215908.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0116_v003-2019m1121t220128.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0115_v003-2019m1121t220101.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0114_v003-2019m1121t215527.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0113_v003-2019m1121t215833.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0112_v003-2019m1121t215521.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0111_v003-2019m1121t215817.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0110_v003-2019m1121t215537.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0109_v003-2019m1121t215536.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0108_v003-2019m1121t214824.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0107_v003-2019m1121t214827.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0106_v003-2019m1121t214819.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0105_v003-2019m1121t215814.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0104_v003-2019m1121t215627.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0103_v003-2019m1121t215527.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0102_v003-2019m1121t214907.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2010/OMI-Aura_L3-OMNO2d_2010m0101_v003-2019m1121t214817.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1231_v003-2019m1121t214826.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1230_v003-2019m1121t214904.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1229_v003-2019m1121t214829.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1228_v003-2019m1121t214827.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1227_v003-2019m1121t214924.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1226_v003-2019m1121t214819.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1225_v003-2019m1121t214821.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1224_v003-2019m1121t214827.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1223_v003-2019m1121t214358.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1222_v003-2019m1121t214249.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1221_v003-2019m1121t214823.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1220_v003-2019m1121t214341.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1219_v003-2019m1121t214249.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1218_v003-2019m1121t214201.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1217_v003-2019m1121t213740.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1216_v003-2019m1121t214416.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1215_v003-2019m1121t214244.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1214_v003-2019m1121t214340.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1213_v003-2019m1121t213833.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1212_v003-2019m1121t214400.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1211_v003-2019m1121t213819.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1210_v003-2019m1121t214416.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1209_v003-2019m1121t213726.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1208_v003-2019m1121t214339.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1207_v003-2019m1121t214340.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1206_v003-2019m1121t213320.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1205_v003-2019m1121t214249.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1204_v003-2019m1121t213859.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1203_v003-2019m1121t214249.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1202_v003-2019m1121t213245.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1201_v003-2019m1121t214247.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1130_v003-2019m1121t213730.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1129_v003-2019m1121t213732.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1128_v003-2019m1121t213733.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1127_v003-2019m1121t213203.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1126_v003-2019m1121t213204.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1125_v003-2019m1231t092854.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1124_v003-2019m1121t213829.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1123_v003-2019m1121t213836.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1122_v003-2019m1121t213724.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1121_v003-2019m1121t213321.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1120_v003-2019m1121t213753.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1119_v003-2019m1121t213826.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1118_v003-2019m1121t213835.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1117_v003-2019m1121t213249.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1116_v003-2019m1121t213201.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1115_v003-2019m1121t213210.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1114_v003-2019m1121t213204.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1113_v003-2019m1121t213256.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1112_v003-2019m1121t213153.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1111_v003-2019m1121t212811.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1110_v003-2019m1121t213338.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1109_v003-2019m1121t213255.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1108_v003-2019m1121t213251.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1107_v003-2019m1121t212841.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1106_v003-2019m1121t212630.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1105_v003-2019m1121t212733.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1104_v003-2019m1121t213200.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1103_v003-2019m1121t212839.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1102_v003-2019m1121t212242.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1101_v003-2019m1121t212718.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1031_v003-2019m1121t212720.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1030_v003-2019m1121t212718.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1029_v003-2019m1121t212834.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1028_v003-2019m1121t212258.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1027_v003-2019m1121t212734.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1026_v003-2019m1121t212309.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1025_v003-2019m1121t212306.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1024_v003-2019m1121t212248.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1023_v003-2019m1121t212638.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1022_v003-2019m1121t212252.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1021_v003-2019m1121t212841.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1020_v003-2019m1121t212738.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1019_v003-2019m1121t212254.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1018_v003-2019m1121t212641.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1017_v003-2019m1121t212118.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1016_v003-2019m1121t212121.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1015_v003-2019m1121t212609.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1014_v003-2019m1121t212135.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1013_v003-2019m1121t212256.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1012_v003-2019m1121t212125.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1011_v003-2019m1121t212237.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1010_v003-2019m1121t211035.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1009_v003-2019m1121t211040.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1008_v003-2019m1121t211031.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1007_v003-2019m1121t211216.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1006_v003-2019m1121t212237.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1005_v003-2019m1121t211205.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1004_v003-2019m1121t212330.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1003_v003-2019m1121t210313.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1002_v003-2019m1121t210331.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m1001_v003-2019m1121t210320.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0930_v003-2019m1121t210353.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0929_v003-2019m1121t210322.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0928_v003-2019m1121t205854.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0927_v003-2019m1121t205827.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0926_v003-2019m1121t205821.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0925_v003-2019m1121t210404.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0924_v003-2019m1121t205238.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0923_v003-2019m1121t205748.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0922_v003-2019m1121t205739.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0921_v003-2019m1121t205333.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0920_v003-2019m1121t204800.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0919_v003-2019m1121t205821.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0918_v003-2019m1121t205820.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0917_v003-2019m1121t205815.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0916_v003-2019m1121t205810.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0915_v003-2019m1121t205324.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0914_v003-2019m1121t205344.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0913_v003-2019m1121t205155.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0912_v003-2019m1121t205153.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0911_v003-2019m1121t205329.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0910_v003-2019m1121t205251.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0909_v003-2019m1121t204813.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0908_v003-2019m1121t205323.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0907_v003-2019m1121t205359.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0906_v003-2019m1121t205259.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0905_v003-2019m1121t204800.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0904_v003-2019m1121t204801.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0903_v003-2019m1121t205243.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0902_v003-2019m1121t204801.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0901_v003-2019m1121t205242.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0831_v003-2019m1121t204826.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0830_v003-2019m1121t205345.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0829_v003-2019m1121t204813.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0828_v003-2019m1121t204310.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0827_v003-2019m1121t205248.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0826_v003-2019m1121t204748.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0825_v003-2019m1121t204501.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0824_v003-2019m1121t204341.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0823_v003-2019m1121t204308.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0822_v003-2019m1121t204806.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0821_v003-2019m1121t204809.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0820_v003-2019m1121t204314.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0819_v003-2019m1121t204315.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0818_v003-2019m1121t204457.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0817_v003-2019m1121t204439.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0816_v003-2019m1121t204452.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0815_v003-2019m1121t204530.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0814_v003-2019m1121t204529.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0813_v003-2019m1121t204801.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0812_v003-2019m1121t204024.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0811_v003-2019m1121t204105.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0810_v003-2019m1121t203811.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0809_v003-2019m1121t200405.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0808_v003-2019m1121t203822.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0807_v003-2019m1121t203726.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0806_v003-2019m1121t203841.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0805_v003-2019m1121t203907.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0804_v003-2019m1121t203733.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0803_v003-2019m1121t203014.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0802_v003-2019m1121t203841.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0801_v003-2019m1121t203841.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0731_v003-2019m1121t200954.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0730_v003-2019m1121t203227.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0729_v003-2019m1121t203803.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0728_v003-2019m1121t200500.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0727_v003-2019m1121t203007.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0726_v003-2019m1121t200906.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0725_v003-2019m1121t200458.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0724_v003-2019m1121t203013.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0723_v003-2019m1121t201128.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0722_v003-2019m1121t200857.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0721_v003-2019m1121t203226.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0720_v003-2019m1121t201103.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0719_v003-2019m1121t200433.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0718_v003-2019m1121t195909.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0717_v003-2019m1121t200310.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0716_v003-2019m1121t200411.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0715_v003-2019m1121t200357.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0714_v003-2019m1121t200317.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0713_v003-2019m1121t200424.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0712_v003-2019m1121t200306.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0711_v003-2019m1121t200334.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0710_v003-2019m1121t200342.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0709_v003-2019m1121t200317.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0708_v003-2019m1121t195333.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0707_v003-2019m1121t200514.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0706_v003-2019m1121t195925.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0705_v003-2019m1121t195811.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0704_v003-2019m1121t195807.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0703_v003-2019m1121t195911.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0702_v003-2019m1121t195803.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0701_v003-2019m1121t200432.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0630_v003-2019m1121t195137.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0629_v003-2019m1121t195758.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0628_v003-2019m1121t195906.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0627_v003-2019m1121t195132.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0626_v003-2019m1121t195816.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0625_v003-2019m1121t195239.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0624_v003-2019m1121t195921.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0623_v003-2019m1121t195916.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0622_v003-2019m1121t195333.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0621_v003-2019m1121t195810.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0620_v003-2019m1121t195935.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0619_v003-2019m1121t195807.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0618_v003-2019m1121t195341.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0617_v003-2019m1121t195132.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0616_v003-2019m1121t194631.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0615_v003-2019m1121t195136.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0614_v003-2019m1121t195757.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0613_v003-2019m1121t195236.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0612_v003-2019m1121t195141.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0611_v003-2019m1121t194632.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0610_v003-2019m1121t194726.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0609_v003-2019m1121t195117.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0608_v003-2019m1121t195117.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0607_v003-2019m1121t194641.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0606_v003-2019m1121t195138.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0605_v003-2019m1121t195242.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0604_v003-2019m1121t194636.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0603_v003-2019m1121t195343.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0602_v003-2019m1121t194631.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0601_v003-2019m1121t194048.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0531_v003-2019m1121t194645.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0530_v003-2019m1121t194745.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0529_v003-2019m1121t194631.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0528_v003-2019m1121t194641.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0527_v003-2019m1121t194642.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0526_v003-2019m1121t194249.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0525_v003-2019m1121t194209.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0524_v003-2019m1121t194754.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0523_v003-2019m1121t194642.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0522_v003-2019m1121t194214.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0521_v003-2019m1121t194641.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0520_v003-2019m1121t194051.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0519_v003-2019m1121t194100.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0518_v003-2019m1121t193700.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0517_v003-2019m1121t194100.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0516_v003-2019m1121t193639.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0515_v003-2019m1121t194732.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0514_v003-2019m1121t194243.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0513_v003-2019m1121t194249.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0512_v003-2019m1121t194103.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0511_v003-2019m1121t194109.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0510_v003-2019m1121t193647.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0509_v003-2019m1121t193649.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0508_v003-2019m1121t194044.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0507_v003-2019m1121t194145.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0506_v003-2019m1121t193137.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0505_v003-2019m1121t194208.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0504_v003-2019m1121t193801.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0503_v003-2019m1121t194206.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0502_v003-2019m1121t193648.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0501_v003-2019m1121t193146.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0430_v003-2019m1121t193138.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0429_v003-2019m1121t193714.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0428_v003-2019m1121t193715.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0427_v003-2019m1121t193648.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0426_v003-2019m1121t193718.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0425_v003-2019m1121t193716.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0424_v003-2019m1121t193141.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0423_v003-2019m1121t193738.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0422_v003-2019m1121t193211.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0421_v003-2019m1121t193134.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0420_v003-2019m1121t193730.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0419_v003-2019m1121t193125.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0418_v003-2019m1121t193204.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0417_v003-2019m1121t193136.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0416_v003-2019m1121t193146.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0415_v003-2019m1121t193210.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0414_v003-2019m1121t193158.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0413_v003-2019m1121t192705.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0412_v003-2019m1121t193157.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0411_v003-2019m1121t192656.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0410_v003-2019m1121t192625.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0409_v003-2019m1121t193435.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0408_v003-2019m1121t192640.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0407_v003-2019m1121t192622.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0406_v003-2019m1121t192441.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0405_v003-2019m1121t192541.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0404_v003-2019m1121t192658.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0403_v003-2019m1121t193218.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0402_v003-2019m1121t192700.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0401_v003-2019m1121t192629.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0331_v003-2019m1121t192709.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0330_v003-2019m1121t192156.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0329_v003-2019m1121t192210.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0328_v003-2019m1121t192124.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0327_v003-2019m1121t192654.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0326_v003-2019m1121t192746.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0325_v003-2019m1121t192704.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0324_v003-2019m1121t191630.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0323_v003-2019m1121t192126.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0322_v003-2019m1121t190638.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0321_v003-2019m1121t192830.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0320_v003-2019m1121t192200.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0319_v003-2019m1121t190707.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0318_v003-2019m1121t191653.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0317_v003-2019m1121t192144.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0316_v003-2019m1121t191138.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0315_v003-2019m1121t190656.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0314_v003-2019m1121t182631.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0313_v003-2019m1121t192052.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0312_v003-2019m1121t182634.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0311_v003-2019m1121t182221.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0310_v003-2019m1121t180615.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0309_v003-2019m1121t191128.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0308_v003-2019m1121t182737.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0307_v003-2019m1121t182732.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0306_v003-2019m1121t181524.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0305_v003-2019m1121t180403.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0304_v003-2019m1121t182635.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0303_v003-2019m1121t180614.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0302_v003-2019m1121t182222.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0301_v003-2019m1121t180633.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0228_v003-2019m1121t181143.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0227_v003-2019m1121t182223.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0226_v003-2019m1121t180536.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0225_v003-2019m1121t180658.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0224_v003-2019m1121t182736.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0223_v003-2019m1121t182222.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0222_v003-2019m1121t180621.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0221_v003-2019m1121t182221.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0220_v003-2019m1121t180648.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0219_v003-2019m1121t180652.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0218_v003-2019m1121t180046.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0217_v003-2019m1121t180610.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0216_v003-2019m1121t175938.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0215_v003-2019m1121t180100.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0214_v003-2019m1121t180104.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0213_v003-2019m1121t180110.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0212_v003-2019m1121t180734.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0211_v003-2019m1121t180640.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0210_v003-2019m1121t180035.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0209_v003-2019m1121t180006.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0208_v003-2019m1121t175452.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0207_v003-2019m1121t175504.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0206_v003-2019m1121t175532.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0205_v003-2019m1121t175443.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0204_v003-2019m1121t175523.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0203_v003-2019m1121t175931.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0202_v003-2019m1121t180743.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0201_v003-2019m1121t175348.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0131_v003-2019m1121t175419.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0130_v003-2019m1121t175511.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0129_v003-2019m1121t175452.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0128_v003-2019m1121t180047.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0127_v003-2019m1121t175443.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0126_v003-2019m1121t175434.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0125_v003-2019m1121t180006.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0124_v003-2019m1121t175022.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0123_v003-2019m1121t174929.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0122_v003-2019m1121t175434.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0121_v003-2019m1121t174956.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0120_v003-2019m1121t175002.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0119_v003-2019m1121t175544.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0118_v003-2019m1121t175002.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0117_v003-2019m1121t175005.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0116_v003-2019m1121t174959.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0115_v003-2019m1121t174935.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0114_v003-2019m1121t174936.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0113_v003-2019m1121t174930.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0112_v003-2019m1121t175015.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0111_v003-2019m1121t175028.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0110_v003-2019m1121t174959.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0109_v003-2019m1121t174929.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0108_v003-2019m1121t173925.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0107_v003-2019m1121t175426.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0106_v003-2019m1121t174400.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0105_v003-2019m1121t174407.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0104_v003-2019m1121t174406.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0103_v003-2019m1121t174415.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0102_v003-2019m1121t174431.he5
https://acdisc.gesdisc.eosdis.nasa.gov/data//Aura_OMI_Level3/OMNO2d.003/2009/OMI-Aura_L3-OMNO2d_2009m0101_v003-2019m1121t174432.he5
EDSCEOF