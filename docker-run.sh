#!/bin/sh

#cd /app/client
#export NODE_OPTIONS=--max_old_space_size=4000
#REACT_APP_BUILD_NUMBER=$BUILD_NUMBER REACT_APP_PORTAL_SERVICE=$PORTAL_URL REACT_APP_PROJECTS_SERVICE=$PROJECTS_URL REACT_APP_FLEET_ANALYSIS_SERVICE=$FLEET_ANALYSIS_URL REACT_APP_CONFIG_SERVICE=$CONFIG_URL yarn run build
#cd /app
#cp -Rf /app/client/build/* /app/public/

bundle exec ./bin/rake db:prepare
foreman start -m web=1,worker=1