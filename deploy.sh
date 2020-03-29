
# Get the statements
statements=$(< src/streams.sql)

# Create the post data
json='{"ksql":"'$statements'", "streamsProperties": {}}'

# make the request 
echo $json | curl -X "POST" "http://localhost:8088/ksql" -H "Content-Type: application/vnd.ksql.v1+json; charset=utf-8" -d @- | jq

