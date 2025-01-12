#!/usr/bin/env bash

working_dir=`pwd`

#Get namesapce variable
tenant='lobo2'

## Create jmeter database automatically in Influxdb

echo "Creating Influxdb jmeter Database"

##Wait until Influxdb Deployment is up and running
##influxdb_status=`microk8s kubectl get po -n $tenant | grep influxdb-jmeter | awk '{print $2}' | grep Running

influxdb_pod=`microk8s kubectl get po -n $tenant | grep influxdb-jmeter | awk '{print $1}'`
microk8s kubectl exec -ti -n $tenant $influxdb_pod -- influx -execute 'CREATE DATABASE jmeter'

## Create the influxdb datasource in Grafana

echo "Creating the Influxdb data source"
grafana_pod=`microk8s kubectl get po -n $tenant | grep jmeter-grafana | awk '{print $1}'`

## Make load test script in Jmeter master pod executable

#Get Master pod details

master_pod=`microk8s kubectl get po -n $tenant | grep jmeter-master | awk '{print $1}'`

microk8s kubectl exec -ti -n $tenant $master_pod -- cp -r /load_test /jmeter/load_test

microk8s kubectl exec -ti -n $tenant $master_pod -- chmod 755 /jmeter/load_test

##microk8s kubectl cp $working_dir/influxdb-jmeter-datasource.json -n $tenant $grafana_pod:/influxdb-jmeter-datasource.json

microk8s kubectl exec -ti -n $tenant $grafana_pod -- curl 'http://admin:admin@127.0.0.1:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"jmeterdb","type":"influxdb","url":"http://jmeter-influxdb:8086","access":"proxy","isDefault":true,"database":"jmeter","user":"admin","password":"admin"}'
