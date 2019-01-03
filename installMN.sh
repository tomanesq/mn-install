#/bin/bash
clear
RED='\033[0;31m'
GREEN='\033[0;32m'
BCyan='\033[1;36m'
NC='\033[0m'
IP=$(curl -s4 api.ipify.org)
PORT=6610
CONF_DIR=~/.sovranocoin
COINKEY=MN

cd ~
mkdir -p $CONF_DIR
echo && echo && echo -e "${BCyan}"
echo " "
echo " "
echo "This script will install and configure your SovranoCoin masternode"
echo " "
echo " "
echo && echo && echo -e "${NC}"

echo "Do you want to install all needed dependencies (no if you did it before)? [y/n]"
read DOSETUP

if [[ $DOSETUP =~ "y" ]] ; then
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
  sudo apt-get install -y nano htop git
  sudo apt-get install -y software-properties-common
  sudo apt-get install -y build-essential libtool autotools-dev pkg-config libssl-dev
  sudo apt-get install -y libboost-all-dev
  sudo apt-get install -y libevent-dev
  sudo apt-get install -y libminiupnpc-dev
  sudo apt-get install -y autoconf
  sudo apt-get install -y automake unzip
  sudo add-apt-repository  -y  ppa:bitcoin/bitcoin
  sudo apt-get update
  sudo apt-get install -y libdb4.8-dev libdb4.8++-dev

  cd /var
  sudo touch swap.img
  sudo chmod 600 swap.img
  sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
  sudo mkswap /var/swap.img
  sudo swapon /var/swap.img
  sudo free
  sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
  cd

  wget https://genesisblock.eu/res/svr/SovranoCoin-qt-linux.zip
  unzip SovranoCoin-*.zip
  chmod 755 ./sovranocoin*
  mv sovranocoi* /usr/local/bin/

  sudo apt-get install -y ufw
  sudo ufw allow ssh/tcp
  sudo ufw limit ssh/tcp
  sudo ufw logging on
  sudo ufw allow $PORT/tcp
  echo "y" | sudo ufw enable
  sudo ufw status
fi

function create_key() {
  clear
  echo -e "Enter your ${BCyan}sovranocoin masternode private key${NC}. Leave it blank to generate a new ${BCyan}masternode private key${NC} for you:"
  read -e COINKEY
  if [[ -z "$COINKEY" ]]; then
    echo -e "Configuring, please wait..."
    /usr/local/bin/sovranocoind -daemon
    sleep 60
    if [ -z "$(ps axo cmd:100 | grep sovranocoind)" ]; then
      echo -e "${RED}sovranocoin server couldn not start. Check /var/log/syslog for errors.${$NC}"
      exit 1
    fi
    COINKEY=$(/usr/local/bin/sovranocoin-cli masternode genkey)
    if [ "$?" -gt "0" ]; then
      echo -e "${RED}Wallet not fully loaded. Let us wait and try again to generate the private key${NC}"
      sleep 60
      COINKEY=$(/usr/local/bin/sovranocoin-cli masternode genkey)
    fi
    /usr/local/bin/sovranocoin-cli stop
    sleep 10
  fi
}  

function create_conf() {
  echo "rpcuser=U"`shuf -i 10000000-99999999 -n 1` >> sovranocoin.conf_TEMP
  echo "rpcpassword=P"`shuf -i 10000000-99999999 -n 1` >> sovranocoin.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> sovranocoin.conf_TEMP
  echo "rpcport=6611" >> sovranocoin.conf_TEMP
  echo "listen=1" >> sovranocoin.conf_TEMP
  echo "server=1" >> sovranocoin.conf_TEMP
  echo "daemon=1" >> sovranocoin.conf_TEMP
  echo "logtimestamps=1" >> sovranocoin.conf_TEMP
  echo "maxconnections=256" >> sovranocoin.conf_TEMP
  echo "masternode=1" >> sovranocoin.conf_TEMP
  echo "externalip=$IP:$PORT" >> sovranocoin.conf_TEMP
  echo "port=$PORT" >> sovranocoin.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> sovranocoin.conf_TEMP
  echo "masternodeprivkey=$COINKEY" >> sovranocoin.conf_TEMP
  mv sovranocoin.conf_TEMP $CONF_DIR/sovranocoin.conf
}

function create_tmp() {
  echo "rpcuser=tu"`shuf -i 100000-10000000 -n 1` >> sovranocoin.conf_TEMP
  echo "rpcpassword=tp"`shuf -i 100000-10000000 -n 1` >> sovranocoin.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> sovranocoin.conf_TEMP
  echo "listen=1" >> sovranocoin.conf_TEMP
  echo "server=1" >> sovranocoin.conf_TEMP
  echo "daemon=1" >> sovranocoin.conf_TEMP
  mv sovranocoin.conf_TEMP $CONF_DIR/sovranocoin.conf
}

create_tmp
create_key
create_conf
sleep 3
clear
/usr/local/bin/sovranocoind -daemon -reindex
echo ""
echo -e " "
echo -e "SovranoCoin masternode is up and running listening on port ${BCyan}$PORT${NC}."
echo -e "Configuration file is: ${BCyan}sovranocoin.conf${NC}"
echo -e "Start: ${BCyan}sovranocoind${NC}"
echo -e "Stop: ${BCyan}sovranocoin-cli stop${NC}"
echo -e "VPS_IP:PORT ${BCyan}$IP:$PORT${NC}"
echo -e "MASTERNODE PRIVATEKEY is: ${BCyan}$COINKEY${NC}"
echo -e "Please check ${BCyan}$COIN_NAME${NC} daemon is running with the following command: ${BCyan}sovranocoin-cli getinfo${NC}"
echo -e "Use ${BCyan}sovranocoin-cli masternode status${NC} to check your MN."
if [[ -n $SENTINEL_REPO  ]]; then
echo -e "${BCyan}Sentinel${NC} is installed in ${BCyan}/root/.sovranocoin/sentinel${NC}"
echo -e "Sentinel logs is: ${BCyan}/root/.sovranocoin/sentinel.log${NC}"
fi
echo -e " "
