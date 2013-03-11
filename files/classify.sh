#!/bin/bash

/opt/puppet/bin/puppet node classify\
  --node-group="Tomcat Jenkins"\
  --enc-server=localhost\
  --enc-port=443\
  --enc-ssl\
  --enc-auth-user="admin@puppetlabs.com"\
  --enc-auth-passwd="puppetlabs"\
  $1
