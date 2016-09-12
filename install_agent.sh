#!/bin/sh

# wget -qO install_agent.sh release.ghostcloud.cn/install/install_agent.sh 7fd37fcf658f
# chmod +x install_agent.sh
# ./install_agent.sh key

# Remote
GC_INSTALL_URL='http://release.ghostcloud.cn'

# Local
GC_ROOT='/root/.ghostcloud'
GC_CONF="$GC_ROOT/conf"
GC_BIN="$GC_ROOT/bin"
GC_LOG="$GC_ROOT/log"

GC_INSTALL_LOCKER="/tmp/gc_install.lock"
LOG_FILE="$GC_LOG/install.$(date "+%Y%m%d-%H%M%S").log"

# Docker
DOCKER_VERSION='1.10.3'
APT_DOCKER_VERSION="${DOCKER_VERSION}-0~trusty"
YUM_DOCKER_PACKAGE="docker-engine-${DOCKER_VERSION}"

# apt
APT_URL="http://apt.ghostcloud.cn"
APT_GC_SOURCE_FILE="/etc/apt/sources.list.d/ghostcloud.list"

usage() {
    echo "Usage: install_agent <key> [<bandwidth>]"
    echo "  key : The installation key, generate by the www.ghostcloud.cn"
    echo "  bandwidth : The host bandwidth"
    exit 1
}

command_exists() {
    command -v "$@" > /dev/null
}

COL_BLACK="$(tput setaf 9)"
COL_RED="$(tput setaf 1)"
COL_GREEN="$(tput setaf 2)"
COL_YELLOW="$(tput setaf 3)"
print_msg() {
    #echo "${COL_GREEN}[Info]${COL_BLACK} : $1" >&3
    echo "[Info] : $1" >&3
}

print_warn() {
    #echo "${COL_YELLOW}[Warn]${COL_BLACK} : $1" >&4
    echo "[Warn] : $1" >&4
}

print_error() {
    #echo "${COL_RED}[Error]${COL_BLACK} : $1" >&4
    echo "[Error] : $1" >&4
}

print_error2() {
    echo "${COL_RED}[Error]${COL_BLACK} : $1"
}

pre_check() {
    case "$(uname -m)" in
        *64)
        ;;
        *)
            print_error2 "You are not using a 64bit platform."
            print_error2 "Docker currently only supports 64bit platforms."
            exit 1
        ;;
    esac

    local user="$(id -un 2>/dev/null || true)"
    if [ "$user" != "root" ]; then
        print_error2 "The current user is not root."
        print_error2 "The installation must be run with root account."
        exit 1
    fi
}

pre_install() {
    local list="$GC_CONF $GC_BIN $GC_LOG"
    for d in $list; do
        if [ ! -d "$d" ]; then
            mkdir -p $d
        fi
    done

    exec 3>&1
    exec 4>&2

    exec 1>$LOG_FILE
    exec 2>$LOG_FILE

    set -x
}

post_install() {
    set +x

    exec 1>&3
    exec 2>&4

    exec 3>&-
    exec 4>&-
}

roll_back() {
    case "$LSB_DIST" in
        ubuntu)
            if [ -e ${APT_GC_SOURCE_FILE} ]; then
                rm -f ${APT_GC_SOURCE_FILE}
            fi

            if [ -e "/etc/apt/sources.list.gcbak" ]; then
                mv /etc/apt/sources.list.gcbak /etc/apt/sources.list
            fi
        ;;
        centos)
            if [ -e "/etc/systemd/system.conf.gcbak" ]; then
                mv /etc/systemd/system.conf.gcbak /etc/systemd/system.conf
                systemctl daemon-reload
            fi
        ;;
    esac

    rm -f $GC_INSTALL_LOCKER
}

get_user_choose() {
    local promotion="$1"

    local choose=''
    while [ 1 -eq 1 ]; do
        print_msg "$promotion"
        read choose

        choose=$(echo $choose | tr "[:upper:]" "[:lower:]" )

        case "$choose" in
            yes)
                break
            ;;
            no)
                print_msg "Exit install."
                roll_back
                exit 0
            ;;
            *)
                print_msg "Invalid input."
                continue
            ;;
        esac
    done
}

# Check if this is a forked Linux distro
check_forked() {
    # Check for lsb_release command existence, it usually exists in forked distros
    if command_exists lsb_release; then
        # Check if the `-u` option is supported
        lsb_release -a -u > /dev/null

        # Check if the command has exited successfully, it means we're in a forked distro
        if [ $? -eq 0 ]; then
            # Get the upstream release info
            LSB_DIST=$(lsb_release -a -u 2>&1 | tr '[:upper:]' '[:lower:]' | grep -E 'id' | cut -d ':' -f 2 | tr -d '[[:space:]]')
            DIST_VERSION=$(lsb_release -a -u 2>&1 | tr '[:upper:]' '[:lower:]' | grep -E 'codename' | cut -d ':' -f 2 | tr -d '[[:space:]]')
        fi
    fi
}

LSB_DIST=''
DIST_VERSION=''
get_dist_version() {
    # perform some very rudimentary platform detection
    if command_exists lsb_release; then
        LSB_DIST="$(lsb_release -si)"
    fi
    if [ -z "$LSB_DIST" ] && [ -r /etc/lsb-release ]; then
        LSB_DIST="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
    fi
    if [ -z "$LSB_DIST" ]; then
        if [ -r /etc/centos-release ] || [ -r /etc/redhat-release ]; then
            LSB_DIST='centos'
        fi
    fi

    LSB_DIST="$(echo "$LSB_DIST" | tr '[:upper:]' '[:lower:]')"

    case "$LSB_DIST" in
        ubuntu)
            if command_exists lsb_release; then
                DIST_VERSION="$(lsb_release --codename | cut -f2)"
            fi
            if [ -z "$DIST_VERSION" ] && [ -r /etc/lsb-release ]; then
                DIST_VERSION="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
            fi
        ;;
        centos)
            DIST_VERSION="$(rpm -q --whatprovides redhat-release --queryformat "%{VERSION}\n" | sed 's/\/.*//' | sed 's/\..*//' | uniq)"
        ;;
        *)
            print_error "Currently, the GCSAgent only support Ubuntu 12.04, Ubuntu 14.04 and CentOS7."
            roll_back
            exit 1
        ;;
    esac

    # Check if this is a forked Linux distro
    check_forked
    if [ -z "$LSB_DIST" -o -z "$DIST_VERSION" ]; then
        print_msg "Can't get the OS($LSB_DIST) and version($DIST_VERSION)"
        roll_back
        exit 1
    fi
    print_msg "The OS is $LSB_DIST, and the version is $DIST_VERSION"
}

uninstall_docker() {
    print_msg "Uninstall the current docker."
    case "$LSB_DIST" in
        ubuntu)
            apt-get purge -y -q docker-engine
        ;;
        centos)
            yum -y -q remove docker-engine
        ;;
    esac
}

DOCKER_IS_INSTALLED=1
check_docker_exist () {
    case "$LSB_DIST" in
        ubuntu)
            dpkg -l docker-engine 2>&1 >/dev/null
            if [ $? -eq 0 ]; then
                local docker_versoin=$(dpkg -l docker-engine | awk '/^[hi]i/{print $3}' | cut -d '-' -f 1)
                if [ "$docker_versoin" = "$DOCKER_VERSION" ]; then
                    print_msg "The docker $DOCKER_VERSION is installed, skip the docker install."
                    DOCKER_IS_INSTALLED=0
                    return
                else
                    print_error "The docker command appears to already exist on this system."
                    print_error "And the version is not $DOCKER_VERSION."

                    get_user_choose "Do you want to uninstall current docker($docker_versoin) and install docker-$DOCKER_VERSION ?[YES|NO]"

                    uninstall_docker
                fi
            fi
        ;;
        centos)
            yum list installed docker-engine 2>&1 >/dev/null
            if [ $? -eq 0 ]; then
                local docker_versoin=$(yum list installed docker-engine | awk '/^docker-engine.*/{print $2}' | cut -d '-' -f 1)
                if [ "$docker_versoin" = "$DOCKER_VERSION" ]; then
                    print_msg "The docker $DOCKER_VERSION is installed, skip the docker install."
                    DOCKER_IS_INSTALLED=0
                    return
                else
                    print_error "The docker command appears to already exist on this system."
                    print_error "And the version is not $DOCKER_VERSION."

                    get_user_choose "Do you want to uninstall current docker($docker_versoin) and install docker-$DOCKER_VERSION ?[YES|NO]"

                    uninstall_docker
                fi
            fi
        ;;
    esac

#    if command_exists docker; then
#	    local docker_versoin=$(docker version --format={{.Server.Version}})
#        if [ "$docker_versoin" = "$DOCKER_VERSION" ]; then
#            print_msg "The docker $DOCKER_VERSION is installed, skip the docker install."
#            return
#        else
#            print_error "The docker command appears to already exist on this system."
#            print_error "And the version is not $DOCKER_VERSION."
#            print_error "Please uninstall current docker, and then install with the script."
#            roll_back
#            exit 1
#        fi
#    fi
}

delete_ecs_route() {
    case "$LSB_DIST" in
        ubuntu)
            ecs_route=$(sed -n 's/^up route add \(-net 172.16.0.0*.*\)/\1/p' /etc/network/interfaces)
            if [ ! -z "$ecs_route" ]; then
                sed -i 's/\(^up route add -net 172.16.0.0*.*\)/#\1/' /etc/network/interfaces
                print_msg "Comment the up route in /etc/network/interfaces"

                route del $ecs_route
                print_msg "route del $ecs_route"
            fi
        ;;
        #centos)
        #	dest='172.16.0.0/12'
        #	gw=$(sed -n 's/^172.16.0.0\/12 via \([0-9.]\{7,15\}\) dev eth0/\1/p' /etc/sysconfig/network-scripts/route-eth0)
        #	if [ ! -z "$gw" ]; then
        #		sed -i 's/^172.16.0.0\/12 via \([0-9.]\{7,15\}\) dev eth0/#\1/p' /etc/sysconfig/network-scripts/route-eth0
        #		route del -net $dest gw $gw eth0
        #	fi
        #;;
    esac
}
did_apt_get_update=''
apt_get_update() {
    if [ -z "$did_apt_get_update" ]; then
        sleep 3
        apt-get update
        did_apt_get_update=1
    fi
}

install_docker() {
    print_msg "Begin to install docker."
    curl=''
    if command_exists curl; then
        curl='curl -sSL'
    elif command_exists wget; then
        curl='wget -qO-'
    elif command_exists busybox && busybox --list-modules | grep -q wget; then
        curl='busybox wget -qO-'
    fi

    # check to see which repo they are trying to install from
    repo='main'

    # Run setup for each distro accordingly
    case "$LSB_DIST" in
        ubuntu)
            export DEBIAN_FRONTEND=noninteractive

            mv /etc/apt/sources.list /etc/apt/sources.list.gcbak

            mkdir -p /etc/apt/sources.list.d
            echo "deb ${APT_URL}/repo ${LSB_DIST}-${DIST_VERSION} ${repo}" > ${APT_GC_SOURCE_FILE}
            echo "deb http://mirrors.163.com/ubuntu/ ${DIST_VERSION} ${repo}" >> ${APT_GC_SOURCE_FILE}

            curl -sS ${APT_URL}/gpg | apt-key add -

            apt_get_update

            # aufs is preferred over devicemapper; try to ensure the driver is available.
            if ! grep -q aufs /proc/filesystems && ! modprobe aufs; then
                if uname -r | grep -q -- '-generic' && dpkg -l 'linux-image-*-generic' | grep -q '^ii' 2>/dev/null; then
                    kern_extras="linux-image-extra-$(uname -r) linux-image-extra-virtual"

                    apt_get_update
                    ( sleep 3; apt-get install -y -q "$kern_extras" ) || true

                    if ! grep -q aufs /proc/filesystems && ! modprobe aufs; then
                        print_warn "Tried to install '$kern_extras' (for AUFS)"
                        print_warn "But we still have no AUFS. Docker may not work. Proceeding anyways!"
                        ( set -x; sleep 5 )
                    fi
                else
                    print_warn 'Current kernel is not supported by the linux-image-extra-virtual'
                    print_warn ' package.  We have no AUFS support.  Consider installing the packages'
                    print_warn ' linux-image-virtual kernel and linux-image-extra-virtual for AUFS support.'
                    ( set -x; sleep 5 )
                fi
            fi

            # install apparmor utils if they're missing and apparmor is enabled in the kernel
            # otherwise Docker will fail to start
            if [ "$(cat /sys/module/apparmor/parameters/enabled)" = 'Y' ]; then
                if command_exists apparmor_parser; then
                    print_msg 'apparmor is enabled in the kernel and apparmor utils were already installed'
                else
                    print_msg 'apparmor is enabled in the kernel, but apparmor_parser missing'
                    apt_get_update
                    ( sleep 3; apt-get install -y -q apparmor )
                fi
            fi

            if [ ! -e /usr/lib/apt/methods/https ]; then
                apt_get_update
                ( sleep 3; apt-get install -y -q apt-transport-https ca-certificates )
            fi

            if [ -z "$curl" ]; then
                apt_get_update
                ( sleep 3; apt-get install -y -q curl ca-certificates )
                curl='curl -sSL'
            fi

            (
                apt-get install -y -q docker-engine=$APT_DOCKER_VERSION
                if [ $? -ne 0 ]; then
                    print_error "Fail to install docker-engine"
                    roll_back
                    exit 1
                fi
            )

            rm -f ${APT_GC_SOURCE_FILE}
            mv /etc/apt/sources.list.gcbak /etc/apt/sources.list
        ;;

        centos)
            cat >/etc/yum.repos.d/docker-${repo}.repo <<-EOF
[docker-${repo}-repo]
name=Docker ${repo} Repository
baseurl=http://yum.ghostcloud.cn/repo/${repo}/${LSB_DIST}/${DIST_VERSION}
enabled=1
gpgcheck=1
gpgkey=http://yum.ghostcloud.cn/gpg
EOF
            if [ "$LSB_DIST" = "fedora" ] && [ "$DIST_VERSION" -ge "22" ]; then
                sleep 3
                dnf -y -q install docker-engine
                if [ $? -ne 0 ]; then
                    print_error "Fail to install docker-engine."
                    roll_back
                    exit 1
                fi
            else
                (
                    sleep 3; yum -y -q remove lvm2
                )

                sleep 3
                yum -y -q install device-mapper-event-libs
                if [ $? -ne 0 ]; then
                    print_error "Fail to install device-mapper-event-libs."
                    roll_back
                    exit 1
                fi

                sleep 3
                yum -y -q install $YUM_DOCKER_PACKAGE
                if [ $? -ne 0 ]; then
                    print_error "Fail to install docker-engine."
                    roll_back
                    exit 1
                fi
            fi
        ;;
    esac
}

check_docker_status() {
    case "$LSB_DIST" in
        ubuntu)
            status=$(status docker)
            if ! echo $status | grep -q "running"; then
                restart docker
                sleep 3
                status=$(status docker)
                if ! echo $status | grep -q "running"; then
                    print_error "Fail to start the docker daemon in $LSB_DIST $DIST_VERSION"
                    roll_back
                    exit 1
                fi
            fi
        ;;
        centos)
            status=$(systemctl status docker | sed -n 's/Active: .*(\(.*\)).*/\1/p' | sed 's/[[:space:]]//g')
            if [ "$status" != "running" ]; then
                # change the systemd default timeout
                mv /etc/systemd/system.conf /etc/systemd/system.conf.gcbak
                cat > /etc/systemd/system.conf <<-EOF
[Manager]
DefaultTimeoutStartSec=300s
EOF
                systemctl daemon-reload
                systemctl start docker
                sleep 3
                status=$(systemctl status docker | sed -n 's/Active: .*(\(.*\)).*/\1/p' | sed 's/[[:space:]]//g')
                if [ "$status" != "running" ]; then
                    print_error "Fail to start the docker daemon in $LSB_DIST $DIST_VERSION"
                    roll_back
                    exit 1
                fi
                mv /etc/systemd/system.conf.gcbak /etc/systemd/system.conf
                systemctl daemon-reload
            fi
        ;;
    esac

    print_msg "docker is running."
}

DOCKER_DAEMON_IP='127.0.0.1'
DOCKER_DAEMON_PORT='2376'

CA_KEY="$GC_CONF/ca.key"
CA_CERT="$GC_CONF/ca.crt"
SERVER_KEY="$GC_CONF/server.key"
SERVER_CSR="$GC_CONF/server.csr"
SERVER_CERT="$GC_CONF/server.crt"
CLIENT_KEY="$GC_CONF/client.key"
CLIENT_CSR="$GC_CONF/client.csr"
CLIENT_CERT="$GC_CONF/client.crt"
NUMBITS='4096'
EXTFILE="$GC_CONF/extfile.cnf"
setup_openssl() {
    openssl genrsa -out $CA_KEY $NUMBITS >/dev/null

    openssl req -x509 -sha256 -batch -subj '/C=CN/ST=Sichuan/L=Chengdu/O=Chengdu Ghostcloud Co.,Ltd/OU=Development/CN=www.ghostcloud.cn' -new -days 365 -key $CA_KEY -out $CA_CERT >/dev/null

    openssl genrsa -out $SERVER_KEY $NUMBITS >/dev/null

    openssl req -subj '/CN=DockerDaemon' -sha256 -new -key $SERVER_KEY -out $SERVER_CSR >/dev/null

    echo subjectAltName = IP:$DOCKER_DAEMON_IP > $EXTFILE
    openssl x509 -req -days 365 -sha256 -in $SERVER_CSR -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial -out $SERVER_CERT -extfile $EXTFILE >/dev/null

    openssl genrsa -out $CLIENT_KEY $NUMBITS >/dev/null

    openssl req -subj '/CN=DockerClient' -new -key $CLIENT_KEY -out $CLIENT_CSR >/dev/null

    echo extendedKeyUsage = clientAuth > $EXTFILE
    openssl x509 -req -days 365 -sha256 -in $CLIENT_CSR -CA $CA_CERT -CAkey $CA_KEY -CAcreateserial -out $CLIENT_CERT -extfile $EXTFILE >/dev/null

    rm $CLIENT_CSR $SERVER_CSR $EXTFILE

    chmod 0400 $CA_KEY $CLIENT_KEY $SERVER_KEY
    chmod 0444 $CA_CERT $SERVER_CERT $CLIENT_CERT

    GC_DOCKER_DAEMON_OPTS="--tlsverify --tlscacert=$CA_CERT --tlscert=$SERVER_CERT --tlskey=$SERVER_KEY -H=tcp://$DOCKER_DAEMON_IP:$DOCKER_DAEMON_PORT"
    GC_DOCKER_DAEMON_OPTS="$GC_DOCKER_DAEMON_OPTS --registry-mirror=http://mirror.ghostcloud.cn --insecure-registry=hub.ghostcloud.cn"

    print_msg "Restart docker daemon with TLS enabled."
    case "$LSB_DIST" in
        ubuntu)
            sed -i '/^DOCKER_OPTS/d' /etc/default/docker
            cat >> /etc/default/docker <<-EOF
DOCKER_OPTS="$GC_DOCKER_DAEMON_OPTS -H=unix:///var/run/docker.sock"
EOF

            # Restart the docker daemon
            restart docker
            sleep 5
        ;;
        centos)
            # Create a systemd drop-in directory for the docker service
            DOCKER_SERVICE_D="/etc/systemd/system/docker.service.d"
            DOCKER_SERVICE_CONF="$DOCKER_SERVICE_D/gcdocker.conf"
            if [ ! -d "$DOCKER_SERVICE_D" ]; then
                mkdir -p $DOCKER_SERVICE_D
            fi

            cat > $DOCKER_SERVICE_CONF <<-EOF
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// $GC_DOCKER_DAEMON_OPTS
EOF
            # Restart the docker daemon
            systemctl daemon-reload
            systemctl restart docker

            systemctl enable docker
            sleep 5
        ;;
    esac
}

AGENT_BIN_URL="$GC_INSTALL_URL/bin/gcagent.tar.gz"
AGENT_LOCAL_TAR="$GC_BIN/gcagent.tar.gz"
AGENT_LOCAL_BIN="/usr/local/bin/gcagent"

AGENTD_BIN_URL="$GC_INSTALL_URL/bin/gcagentd.tar.gz"
AGENTD_LOCAL_TAR="$GC_BIN/gcagentd.tar.gz"
AGENTD_LOCAL_BIN="/usr/local/bin/gcagentd"

AGENT_LOG="$GC_LOG/gcagent.log"
check_agent_exist() {
    if [ -e "$AGENT_LOCAL_BIN" ]; then
        print_error "The $AGENT_LOCAL_BIN existed, if you want to re-install, please uninstall it first."
        print_msg "Download the uninstall script and run it in your host."
        print_msg "curl -s -o uninstall_agent.sh $GC_INSTALL_URL/install/uninstall_agent.sh"
        print_msg "sudo sh uninstall_agent.sh"
        roll_back
        exit 1
    fi
}

UUID_URL="http://console.ghostcloud.cn/api/v1/system/getConf"
AGENT_CONF="$GC_CONF/agent.yml"
AGENT_LOG_DIR="$GC_LOG/agent"
generate_agent_conf() {
    local install_info=$(curl -sSL $UUID_URL/$INSTALL_KEY | grep ConfScript | sed -n s'/\w*\"ConfScript\": \(.*\)/\1/p' | sed -n s'/"//gp' | sed -n s'/ //gp')
    if [ -z "$install_info" ]; then
        print_error "Can't get the install info."
        print_error "The install key is invalid."
        roll_back
        exit 1
    fi

    i=1
    while [ 1 -eq 1 ]; do
        local split=$(echo $install_info | cut -d "," -f$i)
        if [ ! -z "$split" ]; then
            local name=$(echo $split | cut -d ":" -f1)
            local value=$(echo $split | cut -d ":" -f2)
            case $name in
                "hostidhome")
                    INSTALL_HOST_ID_HOME=${value}
                ;;
                "gchome")
                    INSTALL_GC_HOME=${value}
                ;;
                "gchomeport")
                    INSTALL_GC_HOME_PORT=${value}
                ;;
                "hostidsvr")
                    INSTALL_HOST_ID_SERVER=${value}
                ;;
                "gcsvrip")
                    INSTALL_GC_SERVER_IP=${value}
                ;;
                "gcsvrport")
                    INSTALL_GC_SERVER_PORT=${value}
                ;;
                "hostidagent")
                    INSTALL_HOST_ID_AGENT=${value}
                ;;
                "userid")
                    INSTALL_USER_ID=${value}
                ;;
                "hosttype")
                    INSTALL_HOST_TYPE=${value}
                ;;
                "installkey")
                    INSTALL_HOST_KEY=${value}
                ;;
                *)
                ;;
            esac
            i=`expr $i + 1`
        else
            break
        fi
    done

    cat > $AGENT_CONF <<-EOF
dockerca: $CA_CERT
clientcert: $CLIENT_CERT
clientkey: $CLIENT_KEY
dockerserver: $DOCKER_DAEMON_IP
dockerserverport: $DOCKER_DAEMON_PORT
logdir: $AGENT_LOG_DIR
installkey: $INSTALL_HOST_KEY

gchome: $INSTALL_GC_HOME
gchomeport: $INSTALL_GC_HOME_PORT
gcsvr: $INSTALL_GC_SERVER_IP
gcsvrport: $INSTALL_GC_SERVER_PORT
hostidhome: $INSTALL_HOST_ID_HOME
hostidsvr: $INSTALL_HOST_ID_SERVER
hostidagent: $INSTALL_HOST_ID_AGENT
userid: $INSTALL_USER_ID
hosttype: $INSTALL_HOST_TYPE
EOF

	if [ ! -z "$BAND_WIDTH" ]; then
		echo "bandwidth: $BAND_WIDTH" >> $AGENT_CONF
	fi
}

install_agent() {
    print_msg "Begin to install the agent."
    curl -sS -o $AGENT_LOCAL_TAR $AGENT_BIN_URL
    tar -xzf $AGENT_LOCAL_TAR -C /usr/local/bin
    rm -f $AGENT_LOCAL_TAR
    chmod +x $AGENT_LOCAL_BIN

    curl -sS -o $AGENTD_LOCAL_TAR $AGENTD_BIN_URL
    tar -xzf $AGENTD_LOCAL_TAR -C /usr/local/bin
    rm -f $AGENTD_LOCAL_TAR
    chmod +x $AGENTD_LOCAL_BIN

    if [ -e "$AGENT_LOG" ]; then
        rm -f $AGENT_LOG
    fi

    nohup $AGENTD_LOCAL_BIN -f $AGENT_CONF >> $AGENT_LOG 2>&1 &

    # add auto start script
    case "$LSB_DIST" in
        ubuntu)
            AUTO_SCRIPT="/etc/init.d/gcagent"
            { \
                echo "#!/bin/sh"; \
                echo "if ! ps -ef | grep -v grep |grep -q $AGENTD_LOCAL_BIN; then"; \
                echo "    nohup $AGENTD_LOCAL_BIN -f $AGENT_CONF >> $AGENT_LOG 2>&1 &"; \
                echo "fi"; \
            } > $AUTO_SCRIPT

            chmod 755 $AUTO_SCRIPT
            update-rc.d gcagent defaults 90
        ;;
        centos)
            AUTO_SCRIPT="/etc/init.d/gcagent"
            { \
                echo "#!/bin/sh"; \
                echo "#add for chkconfig"; \
                echo "#chkconfig: 234 70 90"; \
                echo "#description: auto start gcagent"; \
                echo "#processname: gcagent"; \
                echo ""; \
                echo "if ! ps -ef | grep -v grep |grep -q $AGENTD_LOCAL_BIN; then"; \
                echo "    nohup $AGENTD_LOCAL_BIN -f $AGENT_CONF >> $AGENT_LOG 2>&1 &"; \
                echo "fi"; \
            } > $AUTO_SCRIPT

            chmod 755 $AUTO_SCRIPT
            chkconfig --add gcagent
        ;;
    esac

    print_msg "Succeed to install the agent."
}

# main
if [ -z "$1" ]; then
    echo "Invalid parameters."
    usage
elif [ "$1" = "--help" ]; then
    usage
fi
INSTALL_KEY=$1
BAND_WIDTH=$2

if [ -f $GC_INSTALL_LOCKER ]; then
    echo "Failed to acquire lockfile: $GC_INSTALL_LOCKER."
    echo "Held by $(cat $GC_INSTALL_LOCKER)"
    exit 1
fi

echo "$$" > "$GC_INSTALL_LOCKER"

trap 'rm -f "$GC_INSTALL_LOCKER"; exit $?' INT TERM EXIT

pre_check
pre_install

get_dist_version

# check docker and agent
check_agent_exist
check_docker_exist

# install docker
if [ $DOCKER_IS_INSTALLED -ne 0 ]; then
    delete_ecs_route
    install_docker
    check_docker_status
    print_msg "Succeed to install docker."
fi

setup_openssl
check_docker_status

# install agent
generate_agent_conf
install_agent

post_install

rm -f $GC_INSTALL_LOCKER

exit 0
