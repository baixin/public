#! /usr/bin/perl -w
#
# columnize the input file, ignoring a few comment line
#
# author: xin.bai@gmail.com
#
# > col.pl <input_file>

# line indicator:
#  0 : normal line, should be processed
# 10 : comment line, print out without any processing
# 20 : first pure space line
# 21 : consecutvie pure space line

use strict;
use Data::Dumper;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

# ---------------------------------------------------------------------
# get options
# ---------------------------------------------------------------------

use Getopt::Long;

my $debug  = 0;
my $help   = undef;
my $lang   = undef;
my $file   = undef;
my $inline = undef;

GetOptions ( "debug:i"         	  => \$debug,   # debug mode
	     "help:s"          	  => \$help,    # print help
	     "lang|format|fmt=s"  => \$lang,    # language
	     "file=s"             => \$file,    # input file
	     "inline:s"           => \$inline,  # inline processing, higher prio over input file
	   )
or die BOLD RED "Error in command line arguments/options!";

# mandatory options (!)
die BOLD RED "Error: please either provide input file or inline option!"  unless defined $file or defined $inline or defined $help;

# ---------------------------------------------------------------------
# print help
# ---------------------------------------------------------------------

use Pod::Text;

if ( defined $help ) {
    pod2text $0;
    exit 0;
}

# ---------------------------------------------------------------------
# variables
# ---------------------------------------------------------------------

my @lines  	        = undef; # store the input lines, complicated data structure
my @length 	        = undef; # store line segment length
my $previous_line_empty = 0;	 # set to 1 when encountered a pure space line

# set comment delimiter according to language
my $cm1                  = "#";  # default new line comment mark
my $cm2                  = "#";  # default in-line comment mark
$lang = "no" unless defined $lang;
if ( $lang =~ /c/ ) {
  $cm1 = "//";
  $cm2 = "//";
} elsif ( $lang =~ /codi|vory/i  ) {
  $cm1 = "#";
  $cm2 = "##";
} elsif ( $lang =~ /vhdl?/i  ) {
  $cm1 = "--";
  $cm2 = "--";
} elsif ( $lang =~ /ganove|sig/i  ) {
  $cm1 = '(\+\+|--)';    # treat ++ as leading comment as well
  $cm2 = "##";
}

# ---------------------------------------------------------------------
# read and analyze data
# ---------------------------------------------------------------------

my $INPUT = undef;
if (defined $inline) {
  $INPUT = "STDIN";
} elsif (defined $file) {
  open $INPUT, "<", $file;
}

while (<$INPUT>) {
  chomp;
  s|^\s+||g;                    # remove leading spaces
  s|\s+$||g;                    # remove trailing spaces
  # comment line
  if ( m%^\s*$cm1% ) {
    $lines[$.-1][0] 	 = 10;  # indicate comment line
    $lines[$.-1][1] 	 = $_;
    $previous_line_empty = 0;
  }
  # pure space line
  elsif ( m/^\s*$/ ) {
    if ($previous_line_empty) {	# previous line is also empty
      $lines[$.-1][0] 	   = 21; # consecutive pure space line
      $lines[$.-1][1] 	   = ""; # empty string
      $previous_line_empty = 1;
    } else {			#
      $lines[$.-1][0] 	   = 20; # first pure space line
      $lines[$.-1][1] 	   = ""; # empty string
      $previous_line_empty = 1;
    }
  }
  # normal line
  else {
    $lines[$.-1][0] = 0;	# indicate normal line
    my $cmt = ""; $cmt = $1 if $_ =~ m|$cm2+\s*(.+)$|;
    s|\s*$cm2.+$||;             # remove comment
    my @words = split;		# split with space
    # analyze line segment length
    for (my $i=0; $i<=$#words; $i++) {
      my $len = length $words[$i];
      if (defined $length[$i]) { # length available
	$length[$i] = $len if $len > $length[$i]; # store new length if bigger
      } else {			# no length yet
	$length[$i] = $len;	# just save
      }
    }
    # indicate normal line and store words
    @{$lines[$.-1]} = (0, @words);
    push @{$lines[$.-1]}, "$cm2 ".$cmt if $cmt !~ /^\s*$/;
    $previous_line_empty = 0;
  }
}

close $INPUT if defined $file;

# ---------------------------------------------------------------------
# print
# ---------------------------------------------------------------------

for (my $i=0; $i<=$#lines; $i++) {
  # normal line
  if ($lines[$i][0] == 0) {
    my @line = @{$lines[$i]};	# shift out line indicator bit
    shift @line;
    for (my $j=0; $j<=$#line-1; $j++) {
      my $len = $length[$j]+1;
      printf "%-${len}s", $line[$j];
    }
    my $len = $length[-1];
    printf "%-${len}s", $line[-1];
    print "\n";
  }
  # comment line
  elsif ($lines[$i][0] == 10) {
    print $lines[$i][1], "\n";
  }
  # first pure space line
  elsif ($lines[$i][0] == 20) {
    print "\n";			# print newline
  }
  # consecutive pure space line
  elsif ($lines[$i][0] == 21) {
    # do not print consecutive line
  }
  # unknown line type! please check!
  else {
    die "unknown line type! please check!";
  }
}

# ---------------------------------------------------------------------
# END
# ---------------------------------------------------------------------

__END__

=head1 NAMES

col.pl - column align input file

=head1 GENERAL OPTIONS

S<[ B<-help> ]>
S<[ B<-file> input file ]>
S<[ B<-language|format|fmt> ]>

=head1 DESCRIPTION


=head1 KNOWN LIMITATIONS


=head1 EXAMPLES

=head1 AUTHOR

xin.bai@gmail.com
