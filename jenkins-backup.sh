#!/bin/bash -xe

##################################################################################
function usage(){
  echo "usage: $(basename $0) /path/to/jenkins_home"
}
##################################################################################

readonly JENKINS_HOME=$1
readonly GIT_SERVICE="bitbucket"
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
readonly TMP_DIR="$CUR_DIR/backup"
readonly ARC_NAME="jenkins-$GIT_SERVICE-backup"
readonly ARC_DIR="$TMP_DIR/$ARC_NAME"

if [ -z "$JENKINS_HOME" ] ; then
  usage >&2
  exit 1
fi

mkdir -p "$ARC_DIR/"{plugins,jobs,users,secrets}

cp "$JENKINS_HOME/"*.xml "$ARC_DIR"

cp "$JENKINS_HOME/plugins/"*.[hj]pi "$ARC_DIR/plugins"
hpi_pinned_count=$(find $JENKINS_HOME/plugins/ -name *.hpi.pinned | wc -l)
jpi_pinned_count=$(find $JENKINS_HOME/plugins/ -name *.jpi.pinned | wc -l)
if [ $hpi_pinned_count -ne 0 -o $jpi_pinned_count -ne 0 ]; then
  cp "$JENKINS_HOME/plugins/"*.[hj]pi.pinned "$ARC_DIR/plugins"
fi

if [ -d "$JENKINS_HOME/users/" ] ; then
  cp -R "$JENKINS_HOME/users/"* "$ARC_DIR/users"
fi

if [ -d "$JENKINS_HOME/secrets/" ] ; then
  cp -R "$JENKINS_HOME/secrets/"* "$ARC_DIR/secrets"
fi

if [ -d "$JENKINS_HOME/jobs/" ] ; then
  cd "$JENKINS_HOME/jobs/"
  ls -1 | while read job_name ; do
    mkdir -p "$ARC_DIR/jobs/$job_name/"
    find "$JENKINS_HOME/jobs/$job_name/" -maxdepth 1 -name "*.xml" | xargs -I {} cp {} "$ARC_DIR/jobs/$job_name/"
  done
  cd $JENKINS_HOME
fi

cd "$TMP_DIR"
git add -A "$ARC_NAME/"
git commit -m "Jenkins backup at $(date +%Y%m%d_%H%M)"
git push

exit 0
