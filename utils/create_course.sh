#!/bin/bash

if [ "$#" != "2" ] ; then
   echo "With VIRTUAL_ENV loaded"
   echo "Usage: $0 new_course_slug database_name"
   exit 1
fi

if test -z "$VIRTUAL_ENV"; then
   echo "VIRTUAL_ENV is not loaded, please load it"
   exit 1
fi

COURSE_SKEL=${COURSE_SKEL:-'/home/mooc/askbot-openmooc/courses_examples/courses/skel'}

COURSE=$1
DB_NAME=$2

echo "This scripts is interactive, need mysql password and django askbot admin/password"

set -e
echo "Mysql root password to create database $DB_NAME"
echo "CREATE DATABASE $DB_NAME ; GRANT ALL PRIVILEGES ON $DB_NAME.* TO 'askbot'@'localhost'; FLUSH PRIVILEGES;" | mysql -u root -p
echo "DATABASE $DB_NAME CREATED"

echo "Creating directories"
cd $HOME
cp -av $COURSE_SKEL courses/$COURSE
chmod 755 courses/$COURSE

mkdir -p courses/$COURSE/upfiles


cd courses/$COURSE

sed "s/^DATABASE_NAME.*$/DATABASE_NAME = '$DB_NAME'/g" -i course_settings.py
if [ -d fixtures ]; then
        python manage.py syncdb --migrate --noinput
        find fixtures -type f -exec python manage.py loaddata {} \;
else
        python manage.py syncdb --migrate --noinput
fi

echo "Give user/teacher (email) moderator"
read -p Email: EMAIL

python manage.py add_askbot_user --email "$EMAIL" --user-name "$EMAIL"
python manage.py set_moderator "$EMAIL"

set +e

echo "Updating SP grouo metadata"
cd ~/askbot-openmooc/
python manage.py update_entries_metadata

