use strict;
use warnings;
use Term::ProgressBar;
use Tie::File;

#init globals
my $lplfile = "";
my $system = "";
my $substringh = "-h";
#my $substringr = "-r";
my $remove = "FALSE";
my @lineslpl = "";
my @lineslplpath = "";
my @lineslplext = "";
my @lineslplgame = "";
my @lineslplcrc32 = "";

#check command line
foreach my $argument (@ARGV) {
  if ($argument =~ /$substringh/) {
    print "m3umap v0.5 -   Generate m3u files for mulit-disc games in the game directory,\n";
	print "                and create a new playlist file\n";
	print "\n";
	print "       with m3umap [lpl file ...] [system]\n";
    print "\n";
	print "Example:\n";
	print '              m3umap "D:/RetroArch/playlists/Atari - 2600.lpl" "Atari - 2600"' . "\n";
	print "\n";
	print "Author:\n";
	print "   Discord - Romeo#3620\n";
	print "\n";
    exit;
  }
}

#set paths and system variables
if (scalar(@ARGV) < 2 or scalar(@ARGV) > 2) {
  print "Invalid command line.. exit\n";
  print "use: m3umap -h\n";
  print "\n";
  exit;
}
$lplfile = $ARGV[-2];
$system = $ARGV[-1];

#exit no parameters
if ($lplfile eq "" or $system eq "") {
  print "Invalid command line.. exit\n";
  print "use: m3umap -h\n";
  print "\n";
  exit;
}

#debug
print "lpl file: $lplfile\n";
print "system: $system\n";

#read playlist file
open(FILE, "<", $lplfile) or die "Could not open $lplfile\n";
while (my $readline = <FILE>) {
  push(@lineslpl, $readline);
}
close (FILE);

#init globals
my $gamename = "";
my $extname = "";
my $crc = "";
my $resultgamestart = "";
my $resultgameend = "";
my $resultcrcstart = "";
my $resultlplstart = "";
my @crclines;
my $crcline = "";
my $lplcrc = "";

#parse the extension, game name and crc32 from playlist
foreach my $lplline (@lineslpl) {
  if ($lplline =~ m/"path": /) {
    #parse extension name and path
	$resultgameend = index($lplline, '",');
	if ($lplline =~ m/[#]/) {
	  $extname = ".zip";
	} else {
	  $extname  = substr($lplline, $resultgameend -4, 4);
	}
	$resultgamestart = index($lplline, '"path": ');
	$resultgameend = rindex($lplline, '/');
	my $length = ($resultgameend)  - ($resultgamestart + 9) ;
	my $path = substr($lplline, $resultgamestart + 9, $length + 1);
    push(@lineslplext, $extname);
	push(@lineslplpath, $path);
  }
  if ($lplline =~ m/"label": "/) {
    #parse game name
	$resultgamestart = index($lplline, '"label": "');
	$resultgameend = index($lplline, '",');
	my $length = ($resultgameend)  - ($resultgamestart + 10) ;
    $gamename  = substr($lplline, $resultgamestart + 10, $length);
    push(@lineslplgame, $gamename);
  }
  if ($lplline =~ /"crc32": "/) {
    #parse crc
	$resultlplstart = index($lplline, '"crc32": "');
    $lplcrc  = uc substr($lplline, $resultlplstart + 10, 8);
    push(@lineslplcrc32, $lplcrc);  
  }
}

#init globals
my @linessimilargame = "";
my @linessimilargamepath = "";
my @linesmapgame = @lineslplgame;
my $count = 0;
my $i = 0;
my $j = 0;
my $k = 0;
my @matches = "";
my @gamesdone = "";
my @gamesdonepath = "";

my $max = scalar(@lineslplgame);
my $progress = Term::ProgressBar->new({name => 'progress', count => $max});

#write similar names to an array
open(LOG, ">", "log_" . "$system" . ".txt") or die "Could not open log.txt\n";
OUTER: foreach my $checklpl (@lineslplgame) {
  $progress->update($_);
  $count++;
  $i = 0;
  $j = 0;
  INNER: foreach my $checkmap (@linesmapgame) {
	 if ($checkmap =~ m/\(Disk/i or $checkmap =~ m/\(Disc/i) {
       $i = 0;
       my $mask = $checklpl ^ $checkmap;
       while ($mask =~ /[^\0]/g) {
         $i++;
	   }
	   
       if ($i == 1) {
	     #we have a similarity of 1 character different
		 if (($checklpl =~ m/\(Disc 1/i and $checkmap =~ m/\(Disc 2/i) or ($checklpl =~ m/\(Disk 1/i and $checkmap =~ m/\(Disk 2/i)) {
		   if ($checkmap ne "" and $checklpl ne "") {
		     my $t1 = "$checklpl" . "$lineslplext[$count]";
			 my $t2 = "$checkmap" . "$lineslplext[$count + 1]";
			 my $t3 = "$lineslplpath[$count]";
			 my $t4 = "$lineslplpath[$count + 1]";
			 if ($t1 ne $checklpl) {
			   push(@linessimilargame, $t1);
		     }
			 if ($t2 ne $checkmap) {
			   push(@linessimilargame, $t2);
			 }
			 push(@linessimilargamepath, $t3);
			 push(@linessimilargamepath, $t4);
		     $j = 1;
			 next;
		   }
		 } else {
		   $j++;
		   $k = $j+1;
		   if (($checklpl =~ m/\(Disc $j/i and $checkmap =~ m/\(Disc $k/i) or ($checklpl =~ m/\(Disk $j/i and $checkmap =~ m/\(Disk $k/i)) {
		     if ($checkmap ne "") {
			   my $t5 = "$checkmap" . "$lineslplext[$count]";
			   my $t6 = "$lineslplpath[$count]";
			   if ($t5 ne $checkmap) {
			     push(@linessimilargame, $t5);
			   }
			   push(@linessimilargamepath, $t6);
		     }
		   }
	     }
	   }
	 }
   }
   my $countpath = -1;
   foreach my $element (@linessimilargame) {
     $countpath++;
     my $compare = substr($element, -4);
	 if ($compare ne "") {
	   push (@gamesdone, $element);
	   push (@gamesdonepath, $linessimilargamepath[$countpath]);
	 }
   }
   @linessimilargame = "";
}

#init globals
my @linesm3u = @gamesdone;
my $m3ufilename = "";
my @filenames = "";
my @filenamesorg = "";
my @filenamespath = "";
my $gdcount = -1;

#parse output m3u file name
foreach my $element2 (@gamesdone) {
  $gdcount++;
  if (($element2 =~  m/\(Disc 1/i) or ($element2 =~  m/\(Disk 1/i)) {
    $resultgamestart = 0;
	$resultgameend = length($element2) + $resultgamestart - 5;
	my $length = ($resultgameend)  - ($resultgamestart) + 1;
    $m3ufilename  = substr($element2, $resultgamestart, $length);
	my $m3ufilenameorg = $m3ufilename;
	$m3ufilename =~ s/ \(Disc \d\)|\(Disc \d of \d\)//gi;
	$m3ufilename =~ s/ \(Disk \d\)|\(Disk \d of \d\)//gi;
	push (@filenames, $m3ufilename);
	push (@filenamesorg, $m3ufilenameorg);
	push (@filenamespath, $gamesdonepath[$gdcount]);
  }
}
#foreach my $debug (@filenames) {
#  print "$debug\n";
#}
#foreach my $debug (@gamesdone) {
#  print "$debug\n";
#}

#init globals
$gdcount = -1;
my $newopenout = "";
my $openout = "";
my $tempele = "";

#write m3u map to files and create new playlist with m3u entities
open(INFILE, '<', $lplfile) or die "Could not open file '$lplfile' $!";
open(NEWFILE, '>', "new_$system.lpl") or die "Could not open file 'new_$system.lpl' $!";
while (my $line = <INFILE>){
  print NEWFILE $line;
  if($line =~ m/"items": /) {
    foreach my $elementout (@filenames) {
	  $gdcount++;
      #write current m3u file
      if ($elementout ne "") {
	    $openout = "$filenamespath[$gdcount]" . "$elementout" . ".m3u";
	    $newopenout = $openout =~ s/..//r;
        open(FILE, ">", $newopenout) or die "Could not open $newopenout\n";
        foreach my $element3 (@gamesdone) {
		  $tempele = $element3;
		  $tempele =~ s/ \(Disc \d\)|\(Disc \d of \d\)//gi;
		  $tempele =~ s/ \(Disk \d\)|\(Disk \d of \d\)//gi;
		  $tempele = substr($tempele, 0, length($tempele) - 4);
		  my $a = index($element3, $elementout);
		  if ($element3 eq $elementout) {
	        print LOG "Wrote: $element3 to $newopenout\n";
		    print FILE "$element3\n";
	      } elsif ($tempele eq $elementout) {
		  	print LOG "Wrote: $element3 to $newopenout\n";
		    print FILE "$element3\n";
		  }
        }
        close FILE;
      
        my $path = '      "path": ' . '"' . "$openout" . '",';
        my $name = $elementout;
        my $label = '      "label": "' . "$name" . ' (m3u)"' . ',';
        my $core_path = '      "core_path": "DETECT",';
        my $core_name = '      "core_name": "DETECT",';
        my $crc32 = '      "crc32": "' . "00000000" . '|crc"' . ',';
        my $db_name = '      "db_name": "' . "$system" . '.rdb"';
	    print NEWFILE "    {\n";
        print NEWFILE "$path\n";
        print NEWFILE "$label\n";
        print NEWFILE "$core_path\n";
        print NEWFILE "$core_name\n";
        print NEWFILE "$crc32\n";
        print NEWFILE "$db_name\n";
	    print NEWFILE "    },\n";
	    print LOG "Inserted: ..$newopenout to new_$system.lpl\n";
	  }
	}
  }
}
close INFILE;
close NEWFILE;
close LOG;

my $newlplname = "new_$system.lpl";
print "\nnew playlist file: $newlplname\n";
print "log file: log_" . "$system" . ".txt\n";