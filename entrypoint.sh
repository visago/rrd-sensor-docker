#!/bin/bash
yes "" | sensors-detect
exec /rrd-sensor-cron.pl
