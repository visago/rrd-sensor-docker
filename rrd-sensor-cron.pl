#!/usr/bin/perl
use strict;
use RRDs;

my $datafolder="/data";

#my $time=

#rrd_sensor();
#exit;
cron(300,\&rrd_sensor);

sub rrd_sensor {
  printf "[%s] Running %s\n",datetime(time()),(caller(0))[3];
  my $chip="unknown";
  my $dev="unknown";
  foreach my $l (split("\n",`sensors -A -u`)) {
    if ($l=~ /^\s\s(.+)_(.+): (.+)/i) {
       my $sensor=$1;
       my $type=$2;
       my $value=$3;
       if ($type eq "input") {
         my $id=sprintf("%s_%s_%s",$chip,$dev,$sensor);
#         print "$id=$value\n";
         if (! -f "$datafolder/$id.rrd") {
            initRRD("$datafolder/$id.rrd");
         }        
         updateRRD("$datafolder/$id.rrd",$value);
         graphRRD("$datafolder","$id","$sensor");
       } 
    } elsif ($l=~ /(.+):$/i) {
      $dev=$1;
    } elsif ($l) {
      $chip=$l;
    }
  }
}

sub graphRRD {
  my $folder=shift;
  my $id=shift;
  my $title=shift || $id;
  my $file="$folder/$id.rrd";
  RRDs::graph("$folder/$id.png",
    "--end=now",
    "--start=end-1day",
    "--width=600",
    "--height=200",
    "--full-size-mode",
    "--vertical-label=$title",
    "DEF:ds0=$file:data:LAST",
    "LINE1:ds0#0000FF",
    'GPRINT:ds0:LAST:CURR %6.0lf',
    'GPRINT:ds0:AVERAGE:AVER %6.0lf',
    'GPRINT:ds0:MIN:MIN %6.0lf',
    'GPRINT:ds0:MAX:MAX %6.0lf');
    die "ERROR: ".RRDs::error."\n" if RRDs::error;
}

sub updateRRD {
  my $file=shift;
  my $value=shift;
  RRDs::update($file,"N:$value");
    die "ERROR: ".RRDs::error."\n" if RRDs::error;
}

sub initRRD {
  my $file=shift;
  my $sensor=shift || "data"; 
  my $type=shift || "GAUGE";
  printf "[%s] initRRD %s (%s/%s)\n",datetime(time()),$file,$sensor,$type;
  RRDs::create($file,
    "--step=300",
    "DS:$sensor:$type:600:0:U",
    "RRA:LAST:0.5:1:105120",
    "RRA:MIN:0.5:12:87600",
    "RRA:MAX:0.5:12:87600",
    "RRA:AVERAGE:0.5:12:87600");
    # 1 year of accurate
    # 10 year of hourly min/max
    # 10 year of hourly averages
    die "ERROR: ".RRDs::error."\n" if RRDs::error;
}

sub cron {
  my $timediff=shift;
  my $proc=shift;
  my $title=$0;
  my $now=time();
  my $next=$now+($timediff- ($now % $timediff));  #Set to 0 for first run of now
  $0=sprintf("%s - %s",$title,"First run at ".datetime($next));
  while (getppid>1) { #Check that parent is alive..
    $now=time();
    if ($now>=$next) {
      $0=sprintf("%s - %s",$title,"Start run at ".datetime($now));
      $next=$now+($timediff- ($now % $timediff));
      &$proc();
    }
    $0=sprintf("%s - %s",$title,"Next run at ".datetime($next));
#    sleep int($timediff/60);
    sleep($next-time());
  }
}

sub datetime {  
  my @a=localtime (shift || time());
  my @daylabel=("Sun","Mon","Tue","Wed","Thu","Fri","Sat");
  my @monthname=('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
  return sprintf("%04d-%02d-%02d %02d:%02d:%02d %3s",$a[5]+1900,$a[4]+1,$a[3],$a[2],$a[1],$a[0],$daylabel[$a[6]]);
}
