#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

set -e

# first arg is `-something` or `+something`
if [ "${1#-}" != "$1" ] || [ "${1#+}" != "$1" ]; then
    set -- /opt/couchdb/bin/couchdb "$@"
fi

# first arg is the bare word `couchdb`
if [ "$1" = 'couchdb' ]; then
    shift
    set -- /opt/couchdb/bin/couchdb "$@"
fi

if [ "$1" = '/opt/couchdb/bin/couchdb' ]; then

    # Check that we own everything in /opt/couchdb and fix if necessary. We also
    # add the `-f` flag in all the following invocations because there may be
    # cases where some of these ownership and permissions issues are non-fatal
    # (e.g. a config file owned by root with o+r is actually fine), and we don't
    # to be too aggressive about crashing here ...
    find /opt/couchdb \! \( -user couchdb -group couchdb \) -exec chown -f couchdb:couchdb '{}' +

    # Ensure that data files have the correct permissions. We were previouslyclustered_couchdb1_1
    # preventing any access to these files outside of couchdb:couchdb, but it
    # turns out that CouchDB itself does not set such restrictive permissions
    # when it creates the files. The approach taken here ensures that the
    # contents of the datadir have the same permissions as they had when they
    # were initially created. This should minimize any startup delay.
    find /opt/couchdb/data -type d ! -perm 0755 -exec chmod -f 0755 '{}' +
    find /opt/couchdb/data -type f ! -perm 0644 -exec chmod -f 0644 '{}' +

    # Do the same thing for configuration files and directories. Technically
    # CouchDB only needs read access to the configuration files as all online
    # changes will be applied to the "docker.ini" file below, but we set 644
    # for the sake of consistency.
    find /opt/couchdb/etc -type d ! -perm 0755 -exec chmod -f 0755 '{}' +
    find /opt/couchdb/etc -type f ! -perm 0644 -exec chmod -f 0644 '{}' +

    # Ensure that CouchDB will write custom settings in this file
    touch /opt/couchdb/etc/local.d/cluster-credentials.ini

    if [ "$COUCHDB_USER" ] && [ "$COUCHDB_PASSWORD" ]; then
        # Create admin only if not already present
        if ! grep -Pzoqr "\[admins\]\n$COUCHDB_USER =" /opt/couchdb/etc/local.d/*.ini; then
            printf "\n[admins]\n%s = %s\n" "$COUCHDB_USER" "$COUCHDB_PASSWORD" >> /opt/couchdb/etc/local.d/cluster-credentials.ini
        fi

    fi

    if [ "$COUCHDB_SECRET" ]; then
        # Set secret only if not already present
        if ! grep -Pzoqr "\[chttpd_auth\]\nsecret =" /opt/couchdb/etc/local.d/*.ini; then
            printf "\n[chttpd_auth]\nsecret = %s\n" "$COUCHDB_SECRET" >> /opt/couchdb/etc/local.d/cluster-credentials.ini
        fi
    fi



    if [ "$COUCHDB_UUID" ]; then
        # Set uuid only if not already present
        if ! grep -Pzoqr "\[couchdb\]\nuuid =" /opt/couchdb/etc/local.d/*.ini; then
            printf "\n[couchdb]\nuuid = %s\n" "$COUCHDB_UUID" >> /opt/couchdb/etc/local.d/cluster-credentials.ini
        fi
    fi


    if [ "$NODENAME" ]; then
        # Set node name it has not been set for clustered operations this value needs to change
        # Since changing this name after it has been set can mess up clustering, this can only run once  so a new node name can not be set on subsequent runs
        if  grep "127.0.0.1" /opt/couchdb/etc/vm.args; then
            sed -i "s/127.0.0.1/$NODENAME/" "/opt/couchdb/etc/vm.args"
        fi
    fi

    if [ "$COUCHDB_LOG_LEVEL" ]; then
        if ! grep -Pzoqr "\[log\]\nlevel =" /opt/couchdb/etc/local.d/*.ini; then
            printf "\n[log]\nlevel = %s\n" "$COUCHDB_LOG_LEVEL" >> /opt/couchdb/etc/local.d/cluster-credentials.ini
        fi
    fi

    #Start clustering after UUID, Secret and Nodename are written. 
    /bin/bash /opt/couchdb/etc/set-up-cluster.sh

    chown -f couchdb:couchdb /opt/couchdb/etc/local.d/cluster-credentials.ini || true

    su -c "ulimit -n 100000 && exec $@" couchdb
fi

exec "$@"