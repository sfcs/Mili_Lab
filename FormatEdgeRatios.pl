#!/usr/bin/perl
#
# FormatEdgeRatios.pl
#
# Takes output from the ImageJ Edge Ratio Macro and formats
# it nicely.
#
# Pass Results.xls file on STDIN, formatted results printed to STDOUT
#
# Sarah Clatterbuck Soper 
# 2014.08.27

$debug = 0;

LINE:
while (<>) {
  #$debug && print "-> $_";
  # if the line matches "MASK" it is not the header line
  if (/MASK/) {
    # strips trailing EOL
    chomp;
    s/[\n\r]//;
    # Split the columns into an array
    @cols = split /\t/;
    $debug && print "$cols[1]\n";
    ($stripped, $junk) = split /\./, $cols[1]; 
    ($half,$file) = split /MASK-/, $stripped;
    if ($half =~ /RESULT/) {
      chop $half;
      $debug && print "1: File is $file\n";
      $data{$file}->{$half} = $cols[3];
      if ($half =~ /INNER/) {
	next LINE;
      } elsif ($half =~ /^C1/) {
	$channels{$file} += 8;
      } elsif ($half =~ /^C2/) {
	$channels{$file} += 4;
      } elsif ($half =~ /^C3/) {
	$channels{$file} += 2;
      } elsif ($half =~ /^C4/) {
	$channels{$file} += 1;
      } else {
	$channels{$file} += 8;
      }
    } elsif ($half =~ /INNER/) {
      $data{$file}->{'INNER'} = $cols[2];
    } else {
      $data{$file}->{'FULL'} = $cols[2];
    }
  }
}

@files = sort (keys %channels);
foreach $file (@files) { 
  $debug && print "2: File is $file\n";
  push @{$channelList[$channels{$file}]}, $file;
}

# Go through all 16 possible combinations of channels
for ($i=0; $i<=15; $i++) {
  $debug && print "Channel combo $i\n";
  # See if there are files listed for this combination of channels
  if ($channelList[$i][0]) {
    # Figure out which channels
    my $binaryList = sprintf("%04b", $i);
    $debug && print "binary list is $binaryList\n";
    print "Filename\tArea\tEdge area\tArea Ratio";
    @onChannels =(split //, $binaryList);
    for ($j=0; $j<=3; $j++) {
      if ($onChannels[$j]) {
	$myChannel = $j + 1;
	print "\tChannel $myChannel Total\tChannel $myChannel Inner\tChannel $myChannel Edge Ratio\tChannel $myChannel Ratio Normalized";
      }
    }
    print "\n";
    for ($j=0; $j<(scalar @{$channelList[$i]}); $j++) {
      $file = $channelList[$i][$j];
      $debug && print "3: File is $file\n";
      $data{$file}->{'OUTER'} = $data{$file}{'FULL'} - $data{$file}{'INNER'};
      $data{$file}->{'RATIO'} = $data{$file}->{'OUTER'} / $data{$file}{'FULL'};
      print "$file\t$data{$file}{'FULL'}\t$data{$file}{'OUTER'}\t$data{$file}{'RATIO'}";
      for ($k=0; $k<=3; $k++) {
	if ($onChannels[$k]) {
	  # $i == 8 is the special case of only one channel, so no "C[1-4]-" identifier
	  if ($i == 8) {
	    $myChannel = "";
	  } else {
	    $myChannel = "C" . ($k + 1) . "-";
	  }
	  $total = $myChannel."RESULT";
	  $inner = $myChannel."RESULT-INNER";
	  $edgeRatio = $myChannel."Ratio";
	  $normedRatio = $myChannel."Normed";
	  if ($data{$file}{$total}) {
	    $data{$file}->{$edgeRatio} = ($data{$file}{$total}-$data{$file}{$inner})/$data{$file}{$total};
	    $data{$file}->{$normedRatio} =  $data{$file}{$edgeRatio}/$data{$file}{'RATIO'};
	    print "\t$data{$file}{$total}\t $data{$file}{$inner}\t$data{$file}{$edgeRatio}\t$data{$file}{$normedRatio}";
	  }
	}
      }
      print "\n";
    }
  }
}

 
