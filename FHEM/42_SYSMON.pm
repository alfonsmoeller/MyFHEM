################################################################
#
#  Copyright notice
#
#  (c) 2013 Alexander Schulz
#
#  This script is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  The GNU General Public License can be found at
#  http://www.gnu.org/copyleft/gpl.html.
#  A copy is found in the textfile GPL.txt and important notices to the license
#  from the author is found in LICENSE.txt distributed with these scripts.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  This copyright notice MUST APPEAR in all copies of the script!
#
################################################################

# $Id$

package main;

use strict;
use warnings;

my $VERSION = "1.1.0";

use constant {
  UPTIME          => "uptime",
  UPTIME_TEXT     => "uptime_text",
  FHEMUPTIME      => "fhemuptime",
  FHEMUPTIME_TEXT => "fhemuptime_text",
  IDLETIME        => "idletime",
  IDLETIME_TEXT   => "idletime_text"
};

use constant {
  CPU_FREQ     => "cpu_freq",
  CPU_TEMP     => "cpu_temp",
  CPU_TEMP_AVG => "cpu_temp_avg",
  LOADAVG      => "loadavg"
};

use constant {
  RAM  => "ram",
  SWAP => "swap"
};

use constant {
  ETH0        => "eth0",
  WLAN0       => "wlan0",
  DIFF_SUFFIX => "_diff"
};

use constant FS_PREFIX => "~ ";
use constant FS_PREFIX_N => "fs_";

sub
SYSMON_Initialize($)
{
  my ($hash) = @_;

  Log 5, "SYSMON Initialize";

  $hash->{DefFn}    = "SYSMON_Define";
  $hash->{UndefFn}  = "SYSMON_Undefine";
  $hash->{GetFn}    = "SYSMON_Get";
  $hash->{SetFn}    = "SYSMON_Set";
  $hash->{AttrFn}   = "SYSMON_Attr";
  $hash->{AttrList} = "filesystems network-interfaces disable:0,1 ".
                       $readingFnAttributes;
}

sub
SYSMON_Define($$)
{
  my ($hash, $def) = @_;

  logF($hash, "Define", "$def");

  my @a = split("[ \t][ \t]*", $def);

  return "Usage: define <name> SYSMON [M1 [M2 [M3 [M4]]]]"  if(@a < 2);

  if(int(@a)>=3)
  {
    my @na = @a[2..scalar(@a)-1];
  	SYSMON_setInterval($hash, @na);
  } else {
    SYSMON_setInterval($hash, undef);
  }

  $hash->{STATE} = "Initialized";

  $hash->{DEF_TIME} = time() unless defined($hash->{DEF_TIME});

  RemoveInternalTimer($hash);
  InternalTimer(gettimeofday()+$hash->{INTERVAL_BASE}, "SYSMON_Update", $hash, 0);

  #$hash->{LOCAL} = 1;
  #SYSMON_Update($hash); #-> so nicht. hat im Startvorgang gelegentlich (oft) den Server 'aufgehaengt'
  #delete $hash->{LOCAL};

  return undef;
}

sub
SYSMON_setInterval($@)
{
	my ($hash, @a) = @_;

	my $interval = 60;
	$hash->{INTERVAL_BASE} = $interval;

	my $p1=1;
	my $p2=1;
	my $p3=1;
	my $p4=10;

	if(defined($a[0]) && int($a[0]) eq $a[0]) {$p1 = $a[0];}
	if(defined($a[1]) && int($a[1]) eq $a[1]) {$p2 = $a[1];} else {$p2 = $p1;}
	if(defined($a[2]) && int($a[2]) eq $a[2]) {$p3 = $a[2];} else {$p3 = $p1;}
	if(defined($a[3]) && int($a[3]) eq $a[3]) {$p4 = $a[3];} else {$p4 = $p1*10;}

	$hash->{INTERVAL_MULTIPLIERS} = $p1." ".$p2." ".$p3." ".$p4;
}


my $cur_readings_map;
sub
SYSMON_updateCurrentReadingsMap($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
  my $rMap;
  
  # Map aktueller Namen erstellen
	
	# Feste Werte
	if(SYSMON_isCPUFreqRPiBBB($hash)) {
	  #$rMap->{"cpu_freq"}        = "CPU Frequenz";
	  $rMap->{"cpu_freq"}        = "CPU frequency";
	}
	if(SYSMON_isCPUTempRPi($hash) || SYSMON_isCPUTempBBB($hash)) {
    #$rMap->{"cpu_temp"}        = "CPU Temperatur";
    #$rMap->{"cpu_temp_avg"}    = "Durchschnittliche CPU Temperatur";
    $rMap->{"cpu_temp"}        = "CPU temperature";
    $rMap->{"cpu_temp_avg"}    = "Average CPU temperature";
  }
  #$rMap->{"fhemuptime"}      = "Betriebszeit FHEM";
  #$rMap->{"fhemuptime_text"} = "Betriebszeit FHEM";
  #$rMap->{"idletime"}        = "Leerlaufzeit";
  #$rMap->{"idletime_text"}   = "Leerlaufzeit";
  #$rMap->{"loadavg"}         = "Durchschnittliche Auslastung";
  #$rMap->{"ram"}             = "RAM";
  #$rMap->{"swap"}            = "Swap";
  #$rMap->{"uptime"}          = "Betriebszeit";
  #$rMap->{"uptime_text"}     = "Betriebszeit";
  $rMap->{"fhemuptime"}      = "System up time";
  $rMap->{"fhemuptime_text"} = "System up time";
  $rMap->{"idletime"}        = "Idle time";
  $rMap->{"idletime_text"}   = "Idle time";
  $rMap->{"loadavg"}         = "Load average";
  $rMap->{"ram"}             = "RAM";
  $rMap->{"swap"}            = "swap";
  $rMap->{"uptime"}          = "System up time";
  $rMap->{"uptime_text"}     = "System up time";

	# Filesystems
	my $filesystems = AttrVal($name, "filesystems", undef);
  if(defined $filesystems) {
    my @filesystem_list = split(/,\s*/, trim($filesystems));
    foreach (@filesystem_list) {
      
    }
  }
	
	# Networkadapters
	
	# User defined
	
  $cur_readings_map = $rMap;
  return $rMap;
}

sub
SYSMON_getObsoleteReadingsMap($) {
	my ($hash) = @_;
	my $name = $hash->{NAME};
	
	my $rMap;
	
	# alle READINGS durchgehen
	my @cKeys=keys (%{$defs{$name}{READINGS}});
  foreach my $aName (@cKeys) {
    if(defined ($aName)) {
    	# alles hinzufügen, was nicht in der Aktuellen Liste ist
    	if(!$cur_readings_map->{$aName}) {
    		$rMap->{$aName} = 1;
    	}
    }
  }
	
	return $rMap;
}

sub
SYSMON_Undefine($$)
{
  my ($hash, $arg) = @_;

  logF($hash, "Undefine", "");

  RemoveInternalTimer($hash);
  return undef;
}

sub
SYSMON_Get($@)
{
  my ($hash, @a) = @_;

  my $name = $a[0];

  if(@a < 2)
  {
  	logF($hash, "Get", "@a: get needs at least one parameter");
    return "$name: get needs at least one parameter";
  }

  my $cmd= $a[1];

  logF($hash, "Get", "@a");

  if($cmd eq "update")
  {
  	#$hash->{LOCAL} = 1;
  	SYSMON_Update($hash, 1);
  	#delete $hash->{LOCAL};
  	return undef;
  }

  if($cmd eq "list") {
    my $map = SYSMON_obtainParameters($hash, 1);
    my $ret = "";
    foreach my $name (keys %{$map}) {
  	  my $value = $map->{$name};
  	  $ret = "$ret\n".sprintf("%-20s %s", $name, $value);
    }
    return $ret;
  }

  if($cmd eq "version")
  {
  	return $VERSION;
  }

  if($cmd eq "interval_base")
  {
  	return $hash->{INTERVAL_BASE};
  }

  if($cmd eq "interval_multipliers")
  {
  	return $hash->{INTERVAL_MULTIPLIERS};
  }

  return "Unknown argument $cmd, choose one of list:noArg update:noArg interval_base:noArg interval_multipliers:noArg version:noArg";
}

sub
SYSMON_Set($@)
{
  my ($hash, @a) = @_;

  my $name = $a[0];

  if(@a < 2)
  {
  	logF($hash, "Set", "@a: set needs at least one parameter");
    return "$name: set needs at least one parameter";
  }

  my $cmd= $a[1];

  logF($hash, "Set", "@a");

  if($cmd eq "interval_multipliers")
  {
  	if(@a < 3) {
  		logF($hash, "Set", "$name: not enought parameters");
      return "$name: not enought parameters";
  	}

  	my @na = @a[2..scalar(@a)-1];
  	SYSMON_setInterval($hash, @na);
  	return $cmd ." set to ".($hash->{INTERVAL_MULTIPLIERS});
  }

  if($cmd eq "clean")
  {
  	#my $subcmd = my $cmd= $a[2];
  	#if(defined $subcmd) {
  	#	if($subcmd eq "readings") {
    #    $defs{$name}{READINGS} = ();
    #  }
    #}

    my @cKeys=keys (%{$defs{$name}{READINGS}});
    foreach my $aName (@cKeys) {
      if(defined ($aName) && (index($aName, FS_PREFIX) == 0 || index($aName, FS_PREFIX_N) == 0)) {
        delete $defs{$name}{READINGS}{$aName};
      }
    }

    return;
  }

  return "Unknown argument $cmd, choose one of interval_multipliers clean:noArg";
}

sub
SYSMON_Attr($$$)
{
  my ($cmd, $name, $attrName, $attrVal) = @_;

  Log 5, "SYSMON Attr: $cmd $name $attrName $attrVal";

  $attrVal= "" unless defined($attrVal);
  my $orig = AttrVal($name, $attrName, "");

  if( $cmd eq "set" ) {# set, del
    if( $orig ne $attrVal ) {

    	if($attrName eq "disable")
      {
        my $hash = $main::defs{$name};
        RemoveInternalTimer($hash);
      	if($attrVal ne "0")
      	{
      		InternalTimer(gettimeofday()+$hash->{INTERVAL_BASE}, "SYSMON_Update", $hash, 0);
      	}
       	#$hash->{LOCAL} = 1;
  	    SYSMON_Update($hash);
  	    #delete $hash->{LOCAL};
      }

      $attr{$name}{$attrName} = $attrVal;
      #return $attrName ." set to ". $attrVal;
      return undef;
    }
  }
  return;
}

my $u_first_mark = undef;

sub
SYSMON_Update($@)
{
  my ($hash, $refresh_all) = @_;

  logF($hash, "Update", "");

  my $name = $hash->{NAME};

  if(!$hash->{LOCAL}) {
    RemoveInternalTimer($hash);
    InternalTimer(gettimeofday()+$hash->{INTERVAL_BASE}, "SYSMON_Update", $hash, 1);
  }

  readingsBeginUpdate($hash);

  if( AttrVal($name, "disable", "") eq "1" )
  {
  	logF($hash, "Update", "disabled");
  	$hash->{STATE} = "Inactive";
  } else {
	  # Beim ersten mal alles aktualisieren!
	  if(!$u_first_mark) {
	    $u_first_mark = 1;
	    $refresh_all = 1;
	  }

	  # Parameter holen
    my $map = SYSMON_obtainParameters($hash, $refresh_all);

    # Existierende Schluessel merken
    my @cKeys=keys (%{$defs{$name}{READINGS}});

    $hash->{STATE} = "Active";
    #my $state = $map->{LOADAVG};
    #readingsBulkUpdate($hash,"state",$state);

    foreach my $aName (keys %{$map}) {
  	  my $value = $map->{$aName};
  	  # Nur aktualisieren, wenn ein gueltiges Value vorliegt
  	  if(defined $value) {
  	    readingsBulkUpdate($hash,$aName,$value);
  	  }

  	  # Vorhandene Keys aus der Merkliste loeschen
  	  my $i=0;
  	  foreach my $bName (@cKeys) {
  	  	if(defined $bName) {
  	  	  if($bName eq $aName) {
  	        delete $cKeys[$i];
  	        last;
  	      }
  	    }
  	    $i=$i+1;
  	  }
    }

    # Ueberfluessige Readings loeschen
    # (Es geht darum, die Filesystem-Readings entfernen, wenn diese nicht mehr meht angefordert werden,
    # da sie im Atribut 'filesystems' nicht mehr vorkommen.)
    foreach my $aName (@cKeys) {
    	# nur Filesystem-Readings loeschen. Alle anderen sind ja je immer da.
    	if(defined ($aName) && (index($aName, FS_PREFIX) == 0 || index($aName, FS_PREFIX_N) == 0)) {
        delete $defs{$name}{READINGS}{$aName};
      }
    }
  }

  readingsEndUpdate($hash,defined($hash->{LOCAL} ? 0 : 1));
}

sub
SYSMON_obtainParameters($$)
{
	my ($hash, $refresh_all) = @_;
	my $name = $hash->{NAME};

	my $map;

	my $base=0;
	my $im = "1 1 1 10";
	# Wenn wesentliche Parameter nicht definiert sind, soll ktualisierung immer vorgenommen werden
	if((defined $hash->{INTERVAL_BASE}) && (defined $hash->{INTERVAL_MULTIPLIERS})) {
  	$base = $hash->{INTERVAL_BASE};
  	$im = $hash->{INTERVAL_MULTIPLIERS};
  }

  my $ref =  int(time()/$base);
	my ($m1, $m2, $m3, $m4) = split(/\s+/, $im);

	# immer aktualisieren: uptime, uptime_text, fhemuptime, fhemuptime_text, idletime, idletime_text
  $map = SYSMON_getUptime($hash, $map);
  $map = SYSMON_getFHEMUptime($hash, $map);

  if($m1 gt 0) { # Nur wenn > 0
    # M1: cpu_freq, cpu_temp, cpu_temp_avg, loadavg
    if($refresh_all || ($ref % $m1) eq 0) {
    	#Log 3, "SYSMON -----------> DEBUG: read CPU-Temp"; 
    	if(SYSMON_isCPUTempRPi($hash)) { # Rasp
    		 $map = SYSMON_getCPUTemp_RPi($hash, $map);
      } 
      if (SYSMON_isCPUTempBBB($hash)) {
        $map = SYSMON_getCPUTemp_BBB($hash, $map);
      }
      if(SYSMON_isCPUFreqRPiBBB($hash)) {
        $map = SYSMON_getCPUFreq($hash, $map);
      }
      $map = SYSMON_getLoadAvg($hash, $map);
    }
  }

  if($m2 gt 0) { # Nur wenn > 0
    # M2: ram, swap
    if($refresh_all || ($ref % $m2) eq 0) {
      $map = SYSMON_getRamAndSwap($hash, $map);
    }
  }

  if($m3 gt 0) { # Nur wenn > 0
    # M3: eth0, eth0_diff, wlan0, wlan0_diff
    if($refresh_all || ($ref % $m3) eq 0) {
    	if(SYSMON_isFB($hash)) { 
    		$map = SYSMON_getNetworkInfo($hash, $map, "ath0");
    		$map = SYSMON_getNetworkInfo($hash, $map, "ath1");
    		$map = SYSMON_getNetworkInfo($hash, $map, "cpmac0");
    		$map = SYSMON_getNetworkInfo($hash, $map, "dsl");
    		$map = SYSMON_getNetworkInfo($hash, $map, "eth0");
    		$map = SYSMON_getNetworkInfo($hash, $map, "guest");
    		$map = SYSMON_getNetworkInfo($hash, $map, "hotspot");
    		$map = SYSMON_getNetworkInfo($hash, $map, "lan");
    		$map = SYSMON_getNetworkInfo($hash, $map, "vdsl");
    	} else {
        $map = SYSMON_getNetworkInfo($hash, $map, ETH0);
        $map = SYSMON_getNetworkInfo($hash, $map, WLAN0);
      }
    }
  }

  if($m4 gt 0) { # Nur wenn > 0
    # M4: Filesystem-Informationen
    my $update_fs = ($refresh_all || ($ref % $m4) eq 0);
    my $filesystems = AttrVal($name, "filesystems", undef);
    if($update_fs) {
      if(defined $filesystems)
      {
        my @filesystem_list = split(/,\s*/, trim($filesystems));
        foreach (@filesystem_list)
        {
        	my $fs = $_;
        	$map = SYSMON_getFileSystemInfo($hash, $map, $fs);
        }
      } else {
        $map = SYSMON_getFileSystemInfo($hash, $map, "/");
      }
    } else {
    	# Workaround: Damit die Readings zw. den Update-Punkten nicht geloescht werden, werden die Schluessel leer angelegt
    	# Wenn noch keine Update notwendig, dan einfach alte Schluessel (mit undef als Wert) angeben,
    	# damit werden die Readings in der Update-Methode nicht geloescht.
    	# Die ggf. notwendige Loeschung findet nur bei tatsaechlichen Update statt.
    	my @cKeys=keys (%{$defs{$name}{READINGS}});
      foreach my $aName (@cKeys) {
    	  if(defined ($aName) && (index($aName, FS_PREFIX) == 0 || index($aName, FS_PREFIX_N) == 0)) {
          $map->{$aName} = undef;
        }
      }
    }
  }

  return $map;
}

#------------------------------------------------------------------------------
# leifert Zeit seit dem Systemstart
#------------------------------------------------------------------------------
sub
SYSMON_getUptime($$)
{
	my ($hash, $map) = @_;

	#my $uptime_str = qx(cat /proc/uptime );
	my $uptime_str = SYSMON_execute($hash, "cat /proc/uptime");
  my ($uptime, $idle) = split(/\s+/, trim($uptime_str));
  my $idle_percent = $idle/$uptime*100;

	$map->{+UPTIME}=sprintf("%d",$uptime);
	#$map->{+UPTIME_TEXT} = sprintf("%d days, %02d hours, %02d minutes, %02d seconds",SYSMON_decode_time_diff($uptime));
	$map->{+UPTIME_TEXT} = sprintf("%d days, %02d hours, %02d minutes",SYSMON_decode_time_diff($uptime));

  $map->{+IDLETIME}=sprintf("%d %.2f %%",$idle, $idle_percent);
	$map->{+IDLETIME_TEXT} = sprintf("%d days, %02d hours, %02d minutes",SYSMON_decode_time_diff($idle)).sprintf(" (%.2f %%)",$idle_percent);
	#$map->{+IDLETIME_PERCENT} = sprintf ("%.2f %",$idle_percent);

	return $map;
}

#------------------------------------------------------------------------------
# leifert Zeit seit FHEM-Start
#------------------------------------------------------------------------------
sub
SYSMON_getFHEMUptime($$)
{
	my ($hash, $map) = @_;

	if(defined ($hash->{DEF_TIME})) {
	  my $fhemuptime = time()-$hash->{DEF_TIME};
	  $map->{+FHEMUPTIME} = sprintf("%d",$fhemuptime);
	  $map->{+FHEMUPTIME_TEXT} = sprintf("%d days, %02d hours, %02d minutes",SYSMON_decode_time_diff($fhemuptime));
  }

	return $map;
}

#------------------------------------------------------------------------------
# leifert CPU-Auslastung
#------------------------------------------------------------------------------
sub
SYSMON_getLoadAvg($$)
{
	my ($hash, $map) = @_;

	#my $la_str = qx(cat /proc/loadavg );
	my $la_str = SYSMON_execute($hash, "cat /proc/loadavg");
  my ($la1, $la5, $la15, $prc, $lastpid) = split(/\s+/, trim($la_str));

	$map->{+LOADAVG}="$la1 $la5 $la15";
  #$map->{"load"}="$la1";
	#$map->{"load5"}="$la5";
	#$map->{"load15"}="$la15";

	return $map;
}

#------------------------------------------------------------------------------
# leifert CPU Temperature (Raspberry Pi)
#------------------------------------------------------------------------------
sub
SYSMON_getCPUTemp_RPi($$)
{
	
	my ($hash, $map) = @_;
  my $val = SYSMON_execute($hash, "cat /sys/class/thermal/thermal_zone0/temp 2>&1");  
  $val = int($val);
  my $val_txt = sprintf("%.2f", $val/1000);
  $map->{+CPU_TEMP}="$val_txt";
  my $t_avg = sprintf( "%.1f", (3 * ReadingsVal($hash->{NAME},CPU_TEMP_AVG,$val_txt) + $val_txt ) / 4 );
  $map->{+CPU_TEMP_AVG}="$t_avg";
	return $map;
}

#------------------------------------------------------------------------------
# leifert CPU Temperature (BeagleBone Black)
#------------------------------------------------------------------------------
sub
SYSMON_getCPUTemp_BBB($$)
{
	my ($hash, $map) = @_;
 	my $val = SYSMON_execute($hash, "cat /sys/class/hwmon/hwmon0/device/temp1_input 2>&1");
 	$val = int($val);
  my $val_txt = sprintf("%.2f", $val/1000);
  $map->{+CPU_TEMP}="$val_txt";
  my $t_avg = sprintf( "%.1f", (3 * ReadingsVal($hash->{NAME},CPU_TEMP_AVG,$val_txt) + $val_txt ) / 4 );
  $map->{+CPU_TEMP_AVG}="$t_avg";  
	return $map;
}

#------------------------------------------------------------------------------
# leifert CPU Frequenz (Raspberry Pi, BeagleBone Black)
#------------------------------------------------------------------------------
sub
SYSMON_getCPUFreq($$)
{
	my ($hash, $map) = @_;
	my $val = SYSMON_execute($hash, "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>&1");
	$val = int($val);
	my $val_txt = sprintf("%d", $val/1000);
  $map->{+CPU_FREQ}="$val_txt";
	return $map;
}

#------------------------------------------------------------------------------
# Liefert Werte fuer RAM und SWAP (Gesamt, Verwendet, Frei).
#------------------------------------------------------------------------------
sub SYSMON_getRamAndSwap($$)
{
  my ($hash, $map) = @_;

  #my @speicher = qx(free -m);
  my @speicher = SYSMON_execute($hash, "free");

  shift @speicher;
  my ($fs_desc, $total, $used, $free, $shared, $buffers, $cached) = split(/\s+/, trim($speicher[0]));
  shift @speicher;
  my ($fs_desc2, $total2, $used2, $free2, $shared2, $buffers2, $cached2) = split(/\s+/, trim($speicher[0]));

  if($fs_desc2 ne "Swap:")
  {
    shift @speicher;
    ($fs_desc2, $total2, $used2, $free2, $shared2, $buffers2, $cached2) = split(/\s+/, trim($speicher[0]));
  }

  my $ram;
  my $swap;
  #my $percentage_ram;
  #my $percentage_swap;
  
  $total   = $total / 1024;
  $used    = $used / 1024;
  $free    = $free / 1024;
  $buffers = $buffers / 1024;
  $cached  = $cached / 1024;
  
  #$percentage_ram = sprintf ("%.2f", (($used - $buffers - $cached) / $total * 100), 0);
  #$ram = "Total: ".$total." MB, Used: ".($used - $buffers - $cached)." MB, ".$percentage_ram." %, Free: ".($free + $buffers + $cached)." MB";

  $ram = sprintf("Total: %.2f MB, Used: %.2f MB, %.2f %%, Free: %.2f MB", $total, ($used - $buffers - $cached), (($used - $buffers - $cached) / $total * 100), ($free + $buffers + $cached));

  $map->{+RAM} = $ram;

  # wenn kein swap definiert ist, ist die Groesse (total2) gleich Null. Dies wuerde eine Exception (division by zero) ausloesen
  if($total2 > 0)
  {
  	$total2   = $total2 / 1024;
    $used2    = $used2 / 1024;
    $free2    = $free2 / 1024;
  
    #$percentage_swap = sprintf ("%.2f", ($used2 / $total2 * 100));
    #$swap = "Total: ".$total2." MB, Used: ".$used2." MB,  ".$percentage_swap." %, Free: ".$free2." MB";
    $swap = sprintf("Total: %.2f MB, Used: %.2f MB,  %.2f %%, Free: %.2f MB", $total2, $used2, ($used2 / $total2 * 100), $free2);
  }
  else
  {
    $swap = "n/a"
  }

  $map->{+SWAP} = $swap;

  return $map;
}

#------------------------------------------------------------------------------
# Liefert Fuellstand fuer das angegebene Dateisystem (z.B. '/dev/root', '/dev/sda1' (USB stick)).
# Eingabeparameter: HASH; MAP; FS-Bezeichnung
#------------------------------------------------------------------------------
sub SYSMON_getFileSystemInfo ($$$)
{
	my ($hash, $map, $fs) = @_;
	
	# Neue Syntax: benannte Filesystems: <name>:<definition>
	my($fName, $fDef) = split(/:/, $fs);
	#Log 3, "SYSMON >>>>>>>>>>>>>>> [$fs][$fName|$fDef]";
	if(defined $fDef) {
		$fs = $fDef;
	}

  my $disk = "df ".$fs." -m 2>&1"; # in case of failure get string from stderr

  #my @filesystems = qx($disk);
  my @filesystems = SYSMON_execute($hash, $disk);

  shift @filesystems;
  if (index($filesystems[0], $fs) >= 0) # check if filesystem available -> gives failure on console
  {
    my ($fs_desc, $total, $used, $available, $percentage_used, $mnt_point) = split(/\s+/, $filesystems[0]);
    $percentage_used =~ /^(.+)%$/;
    $percentage_used = $1;
    my $out_txt = "Total: ".$total." MB, Used: ".$used." MB, ".$percentage_used." %, Available: ".$available." MB at ".$mnt_point;
    if(defined $fDef) {
    	$map->{+FS_PREFIX_N.$fName} = $out_txt;
    } else {
      $map->{+FS_PREFIX.$mnt_point} = $out_txt;
    }
  } else {
  	if(defined $fDef) {
  		$map->{+FS_PREFIX_N.$fName} = "not available";
  	} else {
  	  $map->{+FS_PREFIX.$fs} = "not available";
  	}
  }

  return $map;
}

#------------------------------------------------------------------------------
# Liefert Netztwerkinformationen
# Parameter: HASH; MAP; DEVICE (eth0 or wlan0)
#------------------------------------------------------------------------------
sub SYSMON_getNetworkInfo ($$$)
{
	my ($hash, $map, $device) = @_;

  # in case of network not present get failure from stderr (2>&1)
  my $cmd="ifconfig ".$device." 2>&1";

  #my @dataThroughput = qx($cmd);
  my @dataThroughput = SYSMON_execute($hash, $cmd);

  # check if network available
  #if (not grep(/Fehler/, $dataThroughput[0]) && not grep(/error/, $dataThroughput[0]))
  if (index($dataThroughput[0], 'Fehler') < 0 && index($dataThroughput[0], 'error') < 0)
  {
    # perform grep from above
    #@dataThroughput = grep(/RX bytes/, @dataThroughput); # reduce more than one line to only one line
    # change array into scalar variable
    #my $dataThroughput = $dataThroughput[0];
    
    my $dataThroughput = undef;
    foreach (@dataThroughput) {
      if(index($_, 'RX bytes') >= 0) {
        $dataThroughput = $_;
      }
    }

    if(defined $dataThroughput) {
      # remove RX bytes or TX bytes from string
      $dataThroughput =~ s/RX bytes://;
      $dataThroughput =~ s/TX bytes://;
      $dataThroughput = trim($dataThroughput);

      @dataThroughput = split(/ /, $dataThroughput); # return of split is array
    }

    my $rxRaw = 0;
    $rxRaw = $dataThroughput[0] / 1024 / 1024 if(defined $dataThroughput[0]);
    my $txRaw = 0;
    $txRaw = $dataThroughput[4] / 1024 / 1024 if(defined $dataThroughput[4]);
    my $rx = sprintf ("%.2f", $rxRaw);
    my $tx = sprintf ("%.2f", $txRaw);
    my $totalRxTx = $rx + $tx;

    my $out_txt = "RX: ".$rx." MB, TX: ".$tx." MB, Total: ".$totalRxTx." MB";
    $map->{$device} = $out_txt;

    my $lastVal = ReadingsVal($hash->{NAME},$device,"RX: 0 MB, TX: 0 MB, Total: 0 MB");
    my ($d0, $o_rx, $d1, $d2, $o_tx, $d3, $d4, $o_tt, $d5) = split(/\s+/, trim($lastVal));

    my $d_rx = $rx-$o_rx;
    if($d_rx<0) {$d_rx=0;}
    my $d_tx = $tx-$o_tx;
    if($d_tx<0) {$d_tx=0;}
    my $d_tt = $totalRxTx-$o_tt;
    if($d_tt<0) {$d_tt=0;}
    my $out_txt_diff = "RX: ".sprintf ("%.2f", $d_rx)." MB, TX: ".sprintf ("%.2f", $d_tx)." MB, Total: ".sprintf ("%.2f", $d_tt)." MB";
    $map->{$device.DIFF_SUFFIX} = $out_txt_diff;
  } else {
  	$map->{$device} = "not available";
  	$map->{$device.DIFF_SUFFIX} = "not available";
  }

  return $map;
}

#------------------------------------------------------------------------------
# Systemparameter als HTML-Tabelle ausgeben
# Parameter: Name des SYSMON-Geraetes (muss existieren), dessen Daten zur Anzeige gebracht werden sollen.
#------------------------------------------------------------------------------
sub SYSMON_ShowValuesHTML ($)
{
	my ($name) = @_;
	my $hash = $main::defs{$name};

	# Array mit anzuzeigenden Parametern (Prefix, Name (in Map), Postfix)
	my @dataDescription =
  (
    ["Date", undef, ""],
    ["CPU temperature", CPU_TEMP, " &deg;C"],
    ["CPU frequency", CPU_FREQ, " MHz"],
    ["System up time", UPTIME_TEXT, ""],
    ["FHEM up time", FHEMUPTIME_TEXT, ""],
    ["Load average", LOADAVG, ""],
    ["RAM", RAM, ""],
    ["Swap", SWAP, ""],
    #["File system", ?, ""],
    #["USB stick", ?, ""],
    ["Ethernet", ETH0, ""],
    ["WLAN", WLAN0, ""],
  );

  my $map = SYSMON_obtainParameters($hash, 1);

  my $div_class="";

  my $htmlcode = "<div  class='".$div_class."'><table>";

  # Datum anzeigen
  $htmlcode .= "<tr><td valign='top'>Date:&nbsp;</td><td>".strftime("%d.%m.%Y %H:%M:%S", localtime())."</td></tr>";

  # oben definierte Werte anzeigen
  my $ref_zeile;
  foreach $ref_zeile (@dataDescription) {
    #foreach my $spalte (@$ref_zeile) {
    #	print "$spalte "
    #}
    my $tName = @$ref_zeile[1];
    if(defined $tName) {
      $htmlcode .= "<tr><td valign='top'>".@$ref_zeile[0].":&nbsp;</td><td>".$map->{$tName}.@$ref_zeile[2]."</td></tr>";
    }
  }

  # File systems
  foreach my $aName (sort keys %{$map}) {
  	#if(index($aName, "fs[") == 0) {
  	if(defined ($aName) && index($aName, FS_PREFIX) == 0) {
      #$aName =~ /fs\[(.+)\]/;
      $aName =~ /^~ (.+)/;
      #my $dName=$1;
  	  $htmlcode .= "<tr><td valign='top'>File System: ".$1."&nbsp;</td><td>".$map->{$aName}."</td></tr>";
    }
  }

  # named file systems
  foreach my $aName (sort keys %{$map}) {
  	if(defined ($aName) && index($aName, FS_PREFIX_N) == 0) {
      my $fsVal = $map->{$aName};
      #$fsVal = ~ /.*at\s(.+)/;
  	  $htmlcode .= "<tr><td valign='top'>File System: ".$aName."&nbsp;</td><td>".$fsVal."</td></tr>";
    }
  }
  
  $htmlcode .= "</table></div><br>";

  return $htmlcode;
}

my $sys_cpu_temp_rpi = undef;
sub
SYSMON_isCPUTempRPi($) {
	my ($hash) = @_;
	if(!defined $sys_cpu_temp_rpi) {
	  $sys_cpu_temp_rpi = int(SYSMON_execute($hash, "[ -f /sys/class/thermal/thermal_zone0/temp ] && echo 1 || echo 0"));
  }

	return $sys_cpu_temp_rpi;
}

my $sys_cpu_temp_bbb = undef;
sub
SYSMON_isCPUTempBBB($) {
	my ($hash) = @_;
	if(!defined $sys_cpu_temp_bbb) {
	  $sys_cpu_temp_bbb = int(SYSMON_execute($hash, "[ -f /sys/class/hwmon/hwmon0/device/temp1_input ] && echo 1 || echo 0"));
  }

	return $sys_cpu_temp_bbb;
}

my $sys_cpu_freq_rpi_bbb = undef;
sub
SYSMON_isCPUFreqRPiBBB($) {
	my ($hash) = @_;
	if(!defined $sys_cpu_freq_rpi_bbb) {
	  $sys_cpu_freq_rpi_bbb = int(SYSMON_execute($hash, "[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ] && echo 1 || echo 0"));
  }

	return $sys_cpu_freq_rpi_bbb;
}

my $sys_fb = undef;
sub
SYSMON_isFB($) {
	my ($hash) = @_;
	if(!defined $sys_fb) {
	  $sys_fb = int(SYSMON_execute($hash, "[ -f /usr/bin/ctlmgr_ctl ] && echo 1 || echo 0"));
  } 
	return $sys_fb;
}

sub
SYSMON_execute($$)
{
	my ($hash, $cmd) = @_;
  return qx($cmd);
}

#------------------------------------------------------------------------------
# Uebersetzt Sekunden (Dauer) in Tage/Stunden/Minuten/Sekunden
#------------------------------------------------------------------------------
sub SYSMON_decode_time_diff($)
{
  my $s = shift;

  my $d = int($s/86400);
  $s -= $d*86400;
  my $h = int($s/3600);
  $s -= $h*3600;
  my $m = int($s/60);
  $s -= $m*60;

  return ($d,$h,$m,$s);
}

#------------------------------------------------------------------------------
# Logging: Funkrionsaufrufe
#   Parameter: HASH, Funktionsname, Message
#------------------------------------------------------------------------------
sub logF($$$)
{
	my ($hash, $fname, $msg) = @_;
  #Log 5, "SYSMON $fname (".$hash->{NAME}."): $msg";
  Log 5, "SYSMON $fname $msg";
}

sub trim($)
{ 
   my $string = shift;
   $string =~ s/^\s+//;
   $string =~ s/\s+$//;
   return $string;
}

1;

=pod
=begin html


=end html
=begin html_DE

<a name="SYSMON"></a>
<h3>SYSMON</h3>
<ul>
  Dieses Modul liefert diverse Informationen und Statistiken zu dem System, auf dem FHEM-Server ausgef&uuml;hrt wird.
  Es werden nur Linux-basierte Systeme unterst&uuml;tzt. Manche Informationen sind hardwarespezifisch und sind daher nicht auf jeder Plattform 
  verf&uuml;gbar.
  Bis jetzt wurde dieses Modul auf folgenden Systemen getestet: Raspberry Pi (Debian Wheezy), BeagleBone Black, FritzBox 7390 (keine CPU-Daten).
  <br><br>
  <b>Define</b>
  <br><br>
    <code>define <name> SYSMON [&lt;M1&gt;[ &lt;M2&gt;[ &lt;M3&gt;[ &lt;M4&gt;]]]]</code><br>
    <br>
    Diese Anweisung erstellt eine neue SYSMON-Instanz.
    Die Parameter M1 bis M4 legen die Aktualisierungsintervale f&uuml;r verschiedenen Readings (Statistiken) fest.
    Die Parameter sind als Multiplikatoren f&uuml;r die Zeit, die durch INTERVAL_BASE definiert ist, zu verstehen.
    Da diese Zeit fest auf 60 Sekunden gesetzt ist, k&ouml;nnen die Mx-Parameters als Zeitintervale in Minuten angesehen werden.<br>
    Wird einer (oder mehrere) Multiplikator auf Null gesetzt werden, wird das entsprechende Readings deaktiviert.<br>
    <br>
    Die Parameter sind f&uuml;r die Aktualisierung der Readings nach folgender Schema zust&auml;ndig:
    <ul>
     <li>M1: (Default-Wert: 1)<br>
     cpu_freq, cpu_temp, cpu_temp_avg, loadavg<br><br>
     </li>
     <li>M2: (Default-Wert: M1)<br>
     ram, swap<br>
     </li>
     <li>M3: (Default-Wert: M1)<br>
     eth0, eth0_diff, wlan0, wlan0_diff<br><br>
     </li>
     <li>M4: (Default-Wert: 10*M1)<br>
     Filesystem-Informationen<br><br>
     </li>
     <li>folgende Parameter werden immer anhand des Basisintervalls (unabh&auml;ngig von den Mx-Parameters) aktualisiert:<br>
     fhemuptime, fhemuptime_text, idletime, idletime_text, uptime, uptime_text<br><br>
     </li>
    </ul>
  <br>

  <b>Readings:</b>
  <br><br>
  <ul>
    <li>cpu_freq<br>
        CPU-Frequenz
    </li>
    <br>
    <li>cpu_temp<br>
        CPU-Temperatur
    </li>
    <br>
    <li>cpu_temp_avg<br>
        Durchschnitt der CPU-Temperatur, gebildet &uuml;ber die letzten 4 Werte.
    </li>
    <br>
    <li>eth0<br>
    		Menge der &Uuml;betragenen Daten &uuml;ber die Schnittstelle eth0.
    </li>
    <br>
    <li>eth0_diff<br>
    	 &Auml;nderung der &uuml;betragenen Datenmenge in Bezug auf den vorherigen Aufrung (f&uuml; eth0).
    </li>
    <br>
    <li>fhemuptime<br>
    		Zeit (in Sekunden) seit dem Start des FHEM-Servers.
    </li>
    <br>
    <li>fhemuptime_text<br>
    		Zeit seit dem Start des FHEM-Servers: Menschenlesbare Ausgabe (texttuelle Darstellung).
    </li>
    <br>
    <li>idletime<br>
    		Zeit (in Sekunden und in Prozent), die das System (nicht der FHEM-Server!)
    		seit dem Start in dem Idle-Modus verbracht hat. Also die Zeit der Inaktivit&auml;t.
    </li>
    <br>
    <li>idletime_text<br>
    		Zeit der Inaktivit&auml;t des Systems seit dem Systemstart in menschenlesbarer Form.
    </li>
    <br>
    <li>loadavg<br>
        Ausgabe der Werte f&uuml;r die Systemauslastung (load average): 1 Minute-, 5 Minuten- und 15 Minuten-Werte.
    </li>
    <br>
    <li>ram<br>
       Ausgabe der Speicherauslastung.
    </li>
    <br>
    <li>swap<br>
    		Benutzung und Auslastung der SWAP-Datei (bzw. Partition).
    </li>
    <br>
    <li>uptime<br>
    		Zeit (in Sekenden) seit dem Systemstart.
    </li>
    <br>
    <li>uptime_text<br>
    		Zeit seit dem Systemstart in menschenlesbarer Form.
    </li>
    <br>
    <li>wlan0<br>
        Menge der &Uuml;betragenen Daten &uuml;ber die Schnittstelle wlan0.
    </li>
    <br>
    <li>wlan0_diff<br>
    		&Auml;nderung der &uuml;betragenen Datenmenge in Bezug auf den vorherigen Aufrung (f&uuml; wlan0).
    </li>
    <br>
    <li>Dateisysteminformationen (z.B. ~ /)<br>
    		Informationen zu der Gr&ouml;&szlig;e und der Belegung der gew&uuml;nschten Dateisystemen.<br>
    		Seit Version 1.1.0 k&ouml;nnen Dateisysteme auch benannt werden (s.u.). <br>
    		In diesem Fall werden diese Readings auf folgende Weise benannt: fs_&lt;name&gt;.<br>
    		Dies soll die &Uuml;bersicht verbessern und die Erstellung von Plots erleichten.
    </li>
    <br>
  <br>
  </ul>

  Beispiel-Ausgabe:<br>
  <ul>

<table style="border: 1px solid black;">
<tr><td style="border-bottom: 1px solid black;"><div class="dname">cpu_freq</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>900</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">cpu_temp</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>49.77</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">cpu_temp_avg</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>49.7</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">eth0</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>RX: 2954.22 MB, TX: 3469.21 MB, Total: 6423.43 MB</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">eth0_diff</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>RX: 6.50 MB, TX: 0.23 MB, Total: 6.73 MB</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">fhemuptime</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>11231</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">fhemuptime_text&nbsp;&nbsp;</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>0 days, 03 hours, 07 minutes</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">idletime</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>931024 88.35 %</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">idletime_text</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>10 days, 18 hours, 37 minutes (88.35 %)</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">loadavg</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>0.14 0.18 0.22</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">ram</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>Total: 485 MB, Used: 140 MB, 28.87 %, Free: 345 MB</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">swap</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>n/a</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">uptime</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>1053739</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">uptime_text</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>12 days, 04 hours, 42 minutes</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">wlan0</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>RX: 0.00 MB, TX: 0.00 MB, Total: 0 MB</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">wlan0_diff</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>RX: 0.00 MB, TX: 0.00 MB, Total: 0.00 MB</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">fs_root</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>Total: 7404 MB, Used: 3533 MB, 50 %, Available: 3545 MB at /</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td style="border-bottom: 1px solid black;"><div class="dname"><div class="dname">~ /boot</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>Total: 56 MB, Used: 19 MB, 33 %, Available: 38 MB at /boot</div></td>
<td style="border-bottom: 1px solid black;"><div class="dname"><div>2013-11-27 00:05:36</div></td>
</tr>
<tr><td><div class="dname">~ /media/usb1</div></td>
<td><div>Total: 30942 MB, Used: 6191 MB, 21 %, Available: 24752 MB at /media/usb1&nbsp;&nbsp;</div></td>
<td><div>2013-11-27 00:05:36</div></td>
</tr>
</table>
  </ul><br>

  <b>Get:</b><br><br>
    <ul>
    <li>interval<br>
    Listet die bei der Definition angegebene Polling-Intervale auf.
    </li>
    <br>
    <li>list<br>
    Gibt alle Readings aus.
    </li>
    <br>
    <li>update<br>
    Aktualisiert alle Readings. Alle Werte werden neu abgefragt.
    </li>
    <br>
    <li>version<br>
    Zeigt die Version des SYSMON-Moduls.
    </li>
    <br>
    </ul><br>

  <b>Set:</b><br><br>
    <ul>
    <li>interval_multipliers<br>
    Definiert Multipliers (wie bei der Definition des Ger&auml;tes).
    </li>
    <br>
    <li>clean<br>
    L&ouml;scht benutzerdefinierbare Readings. Nach einem Update (oder nach der automatischen Aktualisierung) werden neue Readings generiert.<br>
    </li>
    <br>
    </ul><br>

  <b>Attributes:</b><br><br>
    <ul>
    <li>filesystems<br>
    Gibt die zu &uuml;berwachende Dateisysteme an. Es wird eine kommaseparierte Liste erwartet.<br>
    Jeder angegebene Wert muss entweder direkt den gew&uuml;nschten Mountpoint benennen, oder ein durch ein Doppelpunkt getrenntes Paar &lt;name&gt;:&lt;mountpoint&gt;.
    Der Name wird bei der Anzeige und Logging verwendet.<br>
    Beispiel: <code>/boot,/,/media/usb1</code><br>
    oder: <code>boot:/boot,root:/,USB-Stick:/media/usb1</code><br>
    Die Liste kann gleichzeitig benannte und unbenannte Angaben enthalten. Im Sinne der besseren &Uuml;bersicht ist das jedoch eher nicht zu empfehlen.
    </li>
    <br>
    <li>disable<br>
    M&ouml;gliche Werte: <code>0,1</code>. Bei <code>1</code> wird die Aktualisierung gestoppt.
    </li>
    <br>
    </ul><br>

  <b>Plots:</b><br><br>
    <ul>
    F&uuml;r dieses Modul sind bereits einige gplot-Dateien vordefiniert:<br>
     <ul>
      <code>
       mySMRAM.gplot<br>
       mySMCPUTemp.gplot<br>
       mySMFS_Root.gplot<br>
       mySMFS_usb1.gplot<br>
       mySMLoad.gplot<br>
       mySMNetworkEth0.gplot<br>
       mySMNetworkEth0t.gplot<br>
      </code>
     </ul>
    </ul><br>

  <b>HTML-Ausgabe-Methode (f&uuml;r ein Weblink): SYSMON_ShowValuesHTML</b><br><br>
    <ul>
    Das Modul definiert eine Funktion, die ausgew&auml;hlte Readings in HTML-Format ausgibt. <br>
    Als Parameter wird der Name des definierten SYSMON-Ger&auml;ten erwartet.<br><br>
    <code>define SysValues weblink htmlCode {SYSMON_ShowValuesHTML('sysmon')}</code>
    </ul><br>

  <b>Beispiele:</b><br><br>
    <ul>
    <code>
      # Modul-Definition<br>
      define sysmon SYSMON 1 1 1 10<br>
      #attr sysmon event-on-update-reading cpu_temp,cpu_temp_avg,cpu_freq,eth0_diff,loadavg,ram,^~ /.*usb.*,~ /$<br>
      attr sysmon event-on-update-reading cpu_temp,cpu_temp_avg,cpu_freq,eth0_diff,loadavg,ram,fs_.*<br>
      attr sysmon filesystems boot:/boot,root:/,USB-Stick:/media/usb1<br>
      attr sysmon group RPi<br>
      attr sysmon room 9.03_Tech<br>
      <br>
      # Log<br>
      define FileLog_sysmon FileLog ./log/sysmon-%Y-%m.log sysmon<br>
      attr FileLog_sysmon group RPi<br>
      attr FileLog_sysmon logtype mySMCPUTemp:Plot,text<br>
      attr FileLog_sysmon room 9.03_Tech<br>
      <br>
      # Visualisierung: CPU-Temperatur<br>
      define wl_sysmon_temp SVG FileLog_sysmon:mySMCPUTemp:CURRENT<br>
      attr wl_sysmon_temp group RPi<br>
      attr wl_sysmon_temp label "CPU Temperatur: Min $data{min2}, Max $data{max2}, Last $data{currval2}"<br>
      attr wl_sysmon_temp room 9.03_Tech<br>
      <br>
      # Visualisierung: Netzwerk-Daten&uuml;bertragung f&uuml; eth0<br>
      define wl_sysmon_eth0 SVG FileLog_sysmon:mySMNetworkEth0:CURRENT<br>
      attr wl_sysmon_eth0 group RPi<br>
      attr wl_sysmon_eth0 label "Netzwerk-Traffic eth0: $data{min1}, Max: $data{max1}, Aktuell: $data{currval1}"<br>
      attr wl_sysmon_eth0 room 9.03_Tech<br>
      <br>
      # Visualisierung: CPU-Auslastung (load average)<br>
      define wl_sysmon_load SVG FileLog_sysmon:mySMLoad:CURRENT<br>
      attr wl_sysmon_load group RPi<br>
      attr wl_sysmon_load label "Load Min: $data{min1}, Max: $data{max1}, Aktuell: $data{currval1}"<br>
      attr wl_sysmon_load room 9.03_Tech<br>
      <br>
      # Visualisierung: RAM-Nutzung<br>
      define wl_sysmon_ram SVG FileLog_sysmon:mySMRAM:CURRENT<br>
      attr wl_sysmon_ram group RPi<br>
      attr wl_sysmon_ram label "RAM-Nutzung Total: $data{max1}, Min: $data{min2}, Max: $data{max2}, Aktuell: $data{currval2}"<br>
      attr wl_sysmon_ram room 9.03_Tech<br>
      <br>
      # Visualisierung: Dateisystem: Root-Partition<br>
      define wl_sysmon_fs_root SVG FileLog_sysmon:mySMFS_Root:CURRENT<br>
      attr wl_sysmon_fs_root group RPi<br>
      attr wl_sysmon_fs_root label "Root Partition Total: $data{max1}, Min: $data{min2}, Max: $data{max2}, Aktuell: $data{currval2}"<br>
      attr wl_sysmon_fs_root room 9.03_Tech<br>
      <br>
      # Visualisierung: Dateisystem: USB-Stick<br>
      define wl_sysmon_fs_usb1 SVG FileLog_sysmon:mySMFS_usb1:CURRENT<br>
      attr wl_sysmon_fs_usb1 group RPi<br>
      attr wl_sysmon_fs_usb1 label "USB1 Total: $data{max1}, Min: $data{min2}, Max: $data{max2}, Aktuell: $data{currval2}"<br>
      attr wl_sysmon_fs_usb1 room 9.03_Tech<br>
      <br>
      # Anzeige der Readings zum Einbinden in ein 'Raum'.<br>
      define SysValues weblink htmlCode {SYSMON_ShowValuesHTML('sysmon')}<br>
      attr SysValues group RPi<br>
      attr SysValues room 9.03_Tech<br>
    </code>
    </ul>

  </ul>

=end html_DE
=cut
