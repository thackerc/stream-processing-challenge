===========================
Stream Processing Challenge
===========================

This challenge is meant to show-off your stream processing skills.  It was designed to be completed within a couple hours.

Requirements
============

- Installation and understanding of `docker` and `docker-compose`
- A way to perform stream processing of Kafka topics with Avro serialized data. Examples: kafka-stream, ksql, flink, spark


Setup Instructions
==================

1. Run Kafka from this docker-compose file

.. code:: bash

   docker-compose up


2. Confirm that Kafka is up and available by browsing to http://localhost:9021/

.. HINT::

   It will take between 2 to 3 minutes after docker-compose up completes before Kafka will be ready.


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


4.  Confirm the challenge environment is setup by checking for the existence of the `clickstream` topic in the Control Center http://localhost:9021/

    CO Cluster 1 -> Topics -> clickstream


Challenge Instructions
======================

Author a stream processing application using a common method of your choice.  Examples: kafka-streams, ksql, flink, spark, kinesis analytics.  Your response to each challenge should include any code and steps used (if not obvious) to re-create your solution.

The connector setup in the previous steps created a topic called `clickstream`.  This topic will be used in all of the below challenges.

Here is a sample message from the `clickstream` topic:

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

   This topic is Avro serialized and must be deserialized to process.


Challenge A - Filtering
-----------------------

Process the stream into a new Kafka topic to filter out any `status` that is not `200`.


Challenge B - Sum
-----------------

Process the stream into 2 new streams that shows total bytes transferred for each user by minute and hour.

The first stream should be a 1 minute sum of bytes and look like this:

.. code:: json

   {
     "userid": "<userid>",
     "min_bytes_sum": "<sum of bytes transferred in a 1 minute window>",
     "window_start_time": "<the time the window opened for this calculation>",
     "window_end_time": "<the time the window closed for this calculation>"
   }


The second stream should be a 1 hour sum of the first stream and look like this:

.. code:: json

   {
     "userid": "<userid>",
     "hour_bytes_sum": "<sum of bytes transferred in a 1 hour window>",
     "window_start_time": "<the time the window opened for this calculation>",
     "window_end_time": "<the time the window closed for this calculation>"
   }


Challenge C - Sessions
----------------------

Process the stream into a new Kafka topic that is session aggregation of request counts beginning with a request of `'GET /site/login.html HTTP/1.1'` and ending 10 minutes after the first event.

The session message should look like:

.. code:: json

   {
     "user_session_id": "<a unique id>",
     "session_start": "<start time of session>",
     "user_id": "<userid>",
     "request_count": "<count of all requests in a session>"
   }
