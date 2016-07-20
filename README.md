# Docker for RRD Sensors

```
docker run -d --name=rrd-sensor -v /opt/rrd-sensor:/data visago/rrd-sensor
```

Reads all sensors and dumps them in /opt/rrd-sensor (on host machine)

