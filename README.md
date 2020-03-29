# Stream Processing Challenge

## Deployment

My solution to the stream processing challenge makes use of ksql. To do this start by bringing up the Kafka environment in docker exactly as shown in the setup instruction section of the [ challenge description](./challenge_description.rst).

To deploy the requested streams run the following command.

> sh deploy.sh

The contents [deploy.sh](deploy.sh) curl the ksql REST API with the SQL found in [./src/streams.sql](./src/streams.sql).

## Solution

I added the ksql server and cli service to the docker compose file. The cli is only for development.

```yml
  ksql-server:
    image: confluentinc/cp-ksql-server:5.4.0
    depends_on:
      - broker
      - schema-registry
    ports:
      - "8088:8088"
    environment:
      KSQL_BOOTSTRAP_SERVERS: broker:29092
      KSQL_LISTENERS: http://0.0.0.0:8088
      KSQL_KSQL_SCHEMA_REGISTRY_URL: http://schema-registry:8081
      KSQL_KSQL_CONNECT_URL: "http://connect:8083"
      KSQL_KSQL_SERVICE_ID: test

  ksql-cli:
    image: confluentinc/cp-ksql-cli:5.4.0
    depends_on:
      - ksql-server
    entrypoint: /bin/sh
    tty: true
```

The SQL for each challenge can be found in [./src/streams.sql](./src/streams.sql). I have included the queries here with comments.

```sql
-- Register the already existing clickstream topic.
CREATE STREAM clickstream (
  ip VARCHAR,
  userid INT,
  remote_user VARCHAR,
  time VARCHAR,
  request VARCHAR,
  status VARCHAR,
  bytes VARCHAR,
  referrer VARCHAR,
  agent VARCHAR)
WITH (KAFKA_TOPIC='clickstream', VALUE_FORMAT='AVRO');


-- ----------------------------------------------------------------------------
-- Challenge A - Filtering
--
-- Process the stream into a new Kafka topic to filter out any status that is not 200.
CREATE STREAM clickstream_200 AS
    SELECT ip, userid, remote_user, time, request, status, bytes, referrer, agent
    FROM clickstream
    WHERE status = '200';

-- ----------------------------------------------------------------------------
-- Challenge B - Sum
--
-- Process the stream into 2 new streams that shows total bytes transferred
-- for each user by minute and hour.


-- Part 1
--
-- The first stream should be a 1 minute sum of bytes and look like this:
-- {
--   "userid": "<userid>",
--   "min_bytes_sum": "<sum of bytes transferred in a 1 minute window>",
--   "window_start_time": "<the time the window opened for this calculation>",
--   "window_end_time": "<the time the window closed for this calculation>"
-- }

CREATE TABLE bytes_by_user_by_min AS
    SELECT userid,
        SUM(CAST(bytes as INT)) AS min_bytes_sum,
        WINDOWSTART() as window_start_time,
        WINDOWEND() as window_end_time
    FROM clickstream_200
    WINDOW TUMBLING (SIZE 1 MINUTES)
    GROUP BY userid;


-- Part 2
--
-- The second stream should be a 1 hour sum of the first stream and look like this:
-- {
--   "userid": "<userid>",
--   "hour_bytes_sum": "<sum of bytes transferred in a 1 hour window>",
--   "window_start_time": "<the time the window opened for this calculation>",
--   "window_end_time": "<the time the window closed for this calculation>"
-- }

CREATE TABLE bytes_by_user_by_hour AS
    SELECT userid,
        SUM(CAST(bytes as INT)) AS hour_bytes_sum,
        WINDOWSTART() as window_start_time,
        WINDOWEND() as window_end_time
    FROM clickstream_200
    WINDOW TUMBLING (SIZE 1 HOURS)
    GROUP BY userid;


-- ----------------------------------------------------------------------------
-- Challenge C - Sessions
-- Process the stream into a new Kafka topic that is session aggregation of request counts beginning with a request of 'GET /site/login.html HTTP/1.1' and ending 10 minutes after the first event.

-- The session message should look like:

-- {
--   "user_session_id": "<a unique id>",
--   "session_start": "<start time of session>",
--   "user_id": "<userid>",
--   "request_count": "<count of all requests in a session>"
-- }


-- First put all login events into a stream.
CREATE STREAM logins AS
    SELECT userid, time
    FROM clickstream_200
    WHERE request = 'GET /site/login.html HTTP/1.1';

-- Now enrich the login events to represent each session.
-- The uniqu id is a composite key made from the user id and the timestamp
CREATE TABLE sessions AS
    SELECT CAST(c.userId AS STRING) + '-' + CAST(MIN(CAST(c.time AS INT)) AS STRING) user_session_id,
        MIN(CAST(c.time AS INT)) AS session_start,
        c.userid as user_id,
        COUNT(c.userid) AS request_count
    FROM logins l
    INNER JOIN clickstream c WITHIN 10 MINUTES
    ON l.userid = c.userid
    GROUP BY c.userid;
```

