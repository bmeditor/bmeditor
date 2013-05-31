#!/usr/bin/perl
use utf8;
use warnings;
use strict;
use Getopt::Long;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN, ':encoding(UTF-8)';
                              #expected input format:
#  1    Introduction                                                      3
#     1.1   Just what is LATEX? . . . . .
#     1.2   Markup Languages . . . .             .   .   .  .   .   .   .    4
#     1.3   TEX and its oﬀspring . . .           .   .   .  .   .   .   .    6
#     1.4   How to use this book . . .           .   .   .  .   .   .   .   10
#     1.5 Basics of a LATEX ﬁle . . . .
#     1.6   TEX processing procedure             .   .   .  .   .   .   .   14
#       2    Text, Symbols, and Commands                                      17
#     2.1   Command names and arguments                     .   .   .   .   17
#     2.2   Environments . . . . . . . . . . . .            .   .   .   .   19
#     2.3   Declarations . . . . . . . . . . . . .          .   .   .   .   20
#     2.4   Lengths . . . . . . . . . . . . . . . .         .   .   .   .   21
#       2.5   Special characters . . . . . . . . . .          .   .   .   .   22
#     2.6   Exercises . . . . . . . . . . . . . . .         .   .   .   .   27
#     2.7   Fine-tuning text . . . . . . . . . . .          .   .   .   .   28
#     2.8   Word division . . . . . . . . . . . .           .   .   .   .   34
#     3    Document Layout and Organization                                 37
#  3.1   Document class . . . .       .   .   .   .   .  .   .   .   .   37
#     3.2   Page style . . . . . . . .   .   .   .   .   .  .   .   .   .   42
#     3.3   Parts of the document        .   .   .   .   .  .   .   .   .       52
#     3.4   Table of contents . . .      .   .   .   .   .  .   .   .   .   58

#open file handle for output of bookmarks file
#open PDFMARKS, '>', "pdfmarks"; 
my $use_unicode = 0;
my $use_nested = 0;
my $difference = 0;
if (!GetOptions(
	 #'unicode!' => \$use_unicode,
	 #'nested!' => \$use_nested,
	 'difference=i' => \$difference
    )){ die "could not parse options";}

if (! ($difference =~ /\A-?\d+\z/)) {die "need a number as first argument";}

my @Array = <STDIN>;
my $last = $#Array;
my $separator = "[ \.\t]{3,}";
my $nested_match = qr/\A *(?<number>((\d|[A-Z])+\.?)+) +(?<title>.+?)($separator)(?<page>\d+) *\Z/;  

# main loop: convert lines in @Array
if ($use_nested) {
    for (my $i = 0; $i <= $last; ++$i) {
	if ($Array[$i] =~ /$nested_match/){	
	    my $count = 0;
	    my $number_of_dots = $+{'number'} =~ tr/.//; 
	    my $number = $+{'number'};
	    #print "i=$i\n";
	    #print "number_of_dots=$number_of_dots\n";	
	    # look-ahead to find value of /Count	
	    for (my $j = $i+1; $j<=$last;++$j) {
		#print "j=$j\n";
		
		if ($Array[$j] =~ /$nested_match/) {
		    my $current_number_of_dots = $+{'number'} =~ tr/.//;
		    if ($current_number_of_dots == $number_of_dots+1) {
			# check number
			if ($Array[$j] =~ /\A *(((\d|[A-Z])+\.)*?(\d|[A-Z])+)\.(\d|[A-Z])+ /) {
			    my $first_part_of_number = $1;
			    #print "anfang von number: $first_part_of_number\n";
			    if ($first_part_of_number eq $number) { ++$count;}
			} else {
			    print STDERR "error checking number\n";
			}		    		    
		    }
		} else {
		    print STDERR "no pattern match in look-ahead: $Array[$j]\n\n";
		}
	    }	
	    # layout: [/Title (Title Page) /Page 1 /OUT pdfmark
	    my $title = $+{'number'}." ".$+{'title'};
	    #print STDERR "title = $title\n";
	    if ($use_unicode) {
		$title = &utf8_to_adobe($title);
		$title = '<'.$title.'>';
	    }
	    else {
		$title = '('.$title.')';
	    }
	    #print STDERR "unicodestring = <$unicodestring>\n";
	    
	    my $Page = $+{'page'} + $difference;	
	    die "encounted negative or zero page number: $Page" if ($Page <= 0);
	    my $string = "[/Count -$count /Title $title /Page $Page /OUT pdfmark\n";
	    print $string;
	    #print "Punkte=$number_of_dots\n";
	}
	else {
	    print STDERR "no pattern match: $Array[$i]\n\n";
	}
    }
} else { # do not use the count tag
    print "(bookmarks\n";
    for (my $i = 0; $i <= $last; ++$i) {
	if ($Array[$i] =~ /(?<title>.*?)([ \.\t]+)(?<page>\d+) *\Z/){ # only requirement: some page number at end of line
	    my $title = $+{'title'};
	    my $Page = $+{'page'} + $difference;
	    if ($use_unicode) {
		$title = &utf8_to_adobe($title);
		$title = '<'.$title.'>';
	    }
	    print "(\"$title\" \"#$Page\")\n";
	} else {
	    print STDERR "no pattern match: $Array[$i]\n\n";
	}
    }
    print")\n";
}

sub utf8_to_adobe{
    if ($#_ != 0) {
	die "utf8_to_adobe needs exactly 1 argument";
    }    
    my $arg = $_[0];
    my $retval = "FEFF";
    for(my $i=0; $i < length($arg); ++$i) {
	# get codepoint
	my $character = substr($arg,$i,1);
	my $codepoint = sprintf("%X",ord $character);
	# adjust length to 4
	$codepoint = "0"x(4-length($codepoint)) . "$codepoint";
	$retval .= " $codepoint";	
    }
    return $retval;    
}
