#! /bin/sh

set -e
set -o pipefail

if [ "${S3_ACCESS_KEY_ID}" = "**None**" ]; then
  echo "You need to set the S3_ACCESS_KEY_ID environment variable."
  exit 1
fi

if [ "${S3_SECRET_ACCESS_KEY}" = "**None**" ]; then
  echo "You need to set the S3_SECRET_ACCESS_KEY environment variable."
  exit 1
fi

if [ "${S3_BUCKET}" = "**None**" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${MYSQL_HOST}" == "**None**" ]; then
  echo "You need to set the MYSQL_HOST environment variable."
  exit 1
fi

if [ "${MYSQL_USER}" == "**None**" ]; then
  echo "You need to set the MYSQL_USER environment variable."
  exit 1
fi

if [ "${MYSQL_PASSWORD}" == "**None**" ]; then
  echo "You need to set the MYSQL_PASSWORD environment variable or link to a container named MYSQL."
  exit 1
fi

# env vars needed for aws tools
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

MYSQL_HOST_OPTS="--host=$MYSQL_HOST --port=$MYSQL_PORT --user=$MYSQL_USER --password=$MYSQL_PASSWORD"

if [ "${S3_ENDPOINT}" == "**None**" ]; then
  AWS_ARGS=""
else
  AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi


echo "Finding latest backup"

LATEST_BACKUP=$(aws ${AWS_ARGS} s3 ls s3://$S3_BUCKET/$S3_PREFIX/$MYSQLDUMP_DATABASE --recursive | sort | tail -n 1 | awk '{ print $4 }')
DUMP_FILE="/tmp/dump.sql.gz"
DUMP_FILE_SQL="/tmp/dump.sql"

rm -rf ${DUMP_FILE}
rm -rf ${DUMP_FILE_SQL}

echo "Fetching ${LATEST_BACKUP} from S3"

aws ${AWS_ARGS} s3 cp s3://${S3_BUCKET}/${LATEST_BACKUP} ${DUMP_FILE}
gzip -d ${DUMP_FILE}

echo "Restoring ${LATEST_BACKUP}"

mysql ${MYSQL_HOST_OPTS} -D ${MYSQLDUMP_DATABASE} < ${DUMP_FILE_SQL}

echo "Restore complete"

