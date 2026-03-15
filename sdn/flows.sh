#!/bin/bash

echo "Adding flow to allow h1 to ping h2"

curl -X POST -d '{
  "dpid": 1,
  "match": {
    "in_port": 1
  },
  "actions": [
    {
      "type": "OUTPUT",
      "port": 2
    }
  ]
}' http://localhost:8080/stats/flowentry/add

curl -X POST -d '{
  "dpid": 1,
  "match": {
    "in_port": 2
  },
  "actions": [
    {
      "type": "OUTPUT",
      "port": 1
    }
  ]
}' http://localhost:8080/stats/flowentry/add
#!/bin/bash

echo "Adding flow to allow h1 to ping h2"

curl -X POST -d '{
  "dpid": 1,
  "match": {
    "in_port": 1
  },
  "actions": [
    {
      "type": "OUTPUT",
      "port": 2
    }
  ]
}' http://localhost:8080/stats/flowentry/add

curl -X POST -d '{
  "dpid": 1,
  "match": {
    "in_port": 2
  },
  "actions": [
    {
      "type": "OUTPUT",
      "port": 1
    }
  ]
}' http://localhost:8080/stats/flowentry/add

