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
WITH ( KAFKA_TOPIC = 'clickstream', VALUE_FORMAT='AVRO');


CREATE STREAM clickstream_200 AS
    SELECT ip, userid, remote_user, time, request, status, bytes, referrer, agent
    FROM clickstream 
    WHERE status = '200';

CREATE TABLE bytes_by_user_by_min AS 
    SELECT userid, 
        SUM(CAST(bytes as INT)) AS min_bytes_sum, 
        WINDOWSTART() as window_start_time, 
        WINDOWEND() as window_end_time 
    FROM clickstream_200 
    WINDOW TUMBLING (SIZE 1 MINUTES) 
    GROUP BY userid;


CREATE TABLE bytes_by_user_by_hour AS 
    SELECT userid, 
        SUM(CAST(bytes as INT)) AS hour_bytes_sum, 
        WINDOWSTART() as window_start_time, 
        WINDOWEND() as window_end_time 
    FROM clickstream_200 
    WINDOW TUMBLING (SIZE 1 HOURS) 
    GROUP BY userid;

CREATE STREAM logins AS 
    SELECT userid, time 
    FROM clickstream_200 
    WHERE request = 'GET /site/login.html HTTP/1.1';

CREATE TABLE sessions AS 
    SELECT CAST(c.userId AS STRING) + '-' + CAST(MIN(CAST(c.time AS INT)) AS STRING) user_session_id, 
        MIN(CAST(c.time AS INT)) AS session_start, 
        c.userid as user_id, 
        COUNT(c.userid) AS request_count 
    FROM logins l 
    INNER JOIN clickstream c WITHIN 10 MINUTES  
    ON l.userid = c.userid 
    GROUP BY c.userid;
