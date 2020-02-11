===========================
Stream Processing Challenge
===========================

This challenge is meant to show-off your stream processing skills.  It was designed to be completed within a couple hours.


Setup Instructions
==================

1. Run Kafka from this docker-compose file

.. code:: bash

   docker-compose up


2. Confirm that Kafka is up and available by browsing to http://localhost:9021/


3. Run this command below to generate a sample topic data.  Max topic size is 100MB and Max retention is 12 hours.

.. code:: bash

   curl -X POST -H "Content-Type: application/json" --data '
   {
     "name": "clickstream_generator",
     "config": {
   	"name": "clickstream_generator",
   	"connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
   	"tasks.max": "1",
   	"key.converter": "org.apache.kafka.connect.storage.StringConverter",
   	"kafka.topic": "clickstream",
   	"quickstart": "clickstream"
     }
   }' http://localhost:8083/connectors


Challenge Instructions
======================

Author a stream processing application using a common method of your choice (kafka-streams, flink, spark, AWS Kinesis Analytics.)  Your response to each challenge should include any code and steps used (if not obvious) to re-create your solution.

The connector that was created in the above setup has created a topic called `clickstream`.  This topic will be used in all of the below challenges.

A sample message from the `clickstream` topic:

.. code:: json

   {
     "ip": "111.90.225.227",
     "userid": 23,
     "remote_user": "-",
     "time": "11791",
     "_time": 11791,
     "request": "GET /site/login.html HTTP/1.1",
     "status": "407",
     "bytes": "4196",
     "referrer": "-",
     "agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36"
   }


.. HINT::

   This topic is Avro seralized and must be deserilaized to process.


Challenge A - Filtering
-----------------------

Process the stream into a new Kafka topic to filter out any `status` that is not `200`.


Challenge B - Sum
-----------------

Process the stream into 2 new streams that shows total bytes transferred for each user by minute and hour.

The first stream should will be a 1 minute sum of bytes and should look like this:

.. code:: json

   {
     "userid": "<userid>",
     "min_bytes_sum": "<sum of bytes transferred in a 1 minute window>",
     "window_start_time": "<the time the window opened for this calculation>",
     "window_end_time": "<the time the window closed for this calculation>"
   }


The second stream should be a 1 hour sum of the first stream and should look like this:

.. code:: json

   {
     "userid": "<userid>",
     "hour_bytes_sum": "<sum of bytes transferred in a 1 hour window>",
     "window_start_time": "<the time the window opened for this calculation>",
     "window_end_time": "<the time the window closed for this calculation>"
   }


Challenge C - Sessions
----------------------

Process the stream into a new Kafka topic to create user sessions based on a custom window aggregation which begins after a user requests to `'GET /site/login.html HTTP/1.1'` and ends 10 minutes after the first event.

The session message should look like:

.. code:: json

   {
     "user_session_id": "<a unique id>",
     "session_start": "<start time of session>",
     "user_id": "<userid>",
     "request_count": "<count of all requests in a session>"
   }
