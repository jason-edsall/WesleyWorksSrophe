#!/busybox/sh
# force update
GITHUB_ORG="ecds"
GITHUB_REPOSITORY="WesleyWorks-data"

# remove any old auto deploy
rm -rf autodeploy
# create an autodeploy folder
mkdir autodeploy

echo "Running app build ..."
ant
echo "Ran app build successfully"

echo "Fetching the data repository to build a data xar"
git clone https://github.com/$GITHUB_ORG/$GITHUB_REPOSITORY

cd $GITHUB_REPOSITORY && rm -rf build && mkdir build
echo "Running data build ..."
ant
echo "Ran data build successfully"

cd ..

# move the xar from build to autodeploy
mv build/*.xar autodeploy/
mv $GITHUB_REPOSITORY/build/*.xar autodeploy/

rm -rf $GITHUB_REPOSITORY

# GET the version of the project from the expath-pkg.xml
VERSION=$(cat expath-pkg.xml | grep package | grep version=  | awk -F'version="' '{ print $2 }' | awk -F'"' '{ print $1 }')
# GET the package name of the project from the expath-pkg.xml file
PACKAGE_NAME=$(cat expath-pkg.xml | grep package | grep version=  | awk -F'abbrev="' '{ print $2 }' | awk -F'"' '{ print tolower($1) }')

server_startup () {
    java org.exist.start.Main jetty | tee startup.log
}

password_change() {
    while true; do
        tail -n 20 startup.log | grep "Jetty server started" && break
        sleep 5
    done

    echo "running password change"
    java org.exist.start.Main client \
    --no-gui \
    -u admin -P '' \
    -x "sm:passwd('admin', '$ADMIN_PASSWORD')"
    echo "ran password change"
}

server_startup &
password_change
wait
