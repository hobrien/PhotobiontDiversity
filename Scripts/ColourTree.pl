#!/usr/bin/perl -w
use warnings;
use strict;
use autodie qw(open close);

my %lichen_colors = ('Collema', '#ED99AA',
            'Degelia', '#D5A971',
            'Leptogium', '#9DBB6A',
            'Lobaria', '#4BC49E',
            'Massalongia', '#45C0D4',
            'Nephroma', '#A7ACEC',
            'Pannaria', '#E298D6',
            'Parmeliella', '#890939',
            'Peltigera', '#6A3B00',
            'Protopannaria', '#285000',
            'Pseudocyphellaria', '#005C26',
            'Stereocaulon', '#005D77',
            'Sticta', '#28399F'
            );

my %taxonomy = ('Collema', 'Collemataceae',
            'Degelia', 'Pannariaceae',
            'Leptogium', 'Collemataceae',
            'Lobaria', 'Lobariaceae',
            'Massalongia', 'unknown',
            'Nephroma', 'Nephromataceae',
            'Pannaria', 'Pannariaceae',
            'Parmeliella', 'Pannariaceae',
            'Peltigera', 'Peltigeraceae',
            'Protopannaria', 'Pannariaceae',
            'Pseudocyphellaria', 'Lobariaceae',
            'Stereocaulon', 'Stereocaulaceae',
            'Sticta', 'Lobariaceae'
            );

my %host = ('Collema', 'Lichen',
            'Degelia', 'Lichen',
            'Leptogium', 'Lichen',
            'Lobaria', 'Lichen',
            'Massalongia', 'Lichen',
            'Nephroma', 'Lichen',
            'Pannaria', 'Lichen',
            'Parmeliella', 'Lichen',
            'Peltigera', 'Lichen',
            'Protopannaria', 'Lichen',
            'Pseudocyphellaria', 'Lichen',
            'Stereocaulon', 'Lichen',
            'Sticta', 'Lichen',
            'Anthoceros', 'Plant',
            'Blasia', 'Plant',
            'Cylindrospermum', 'Free-living',
            'Encephalartos', 'Plant',
            'Geosiphon', 'Other',
            'Macrozamia', 'Plant',
            'Nostoc', 'Free-living'
         );
            

my %host_colors = ('Plant', '#7CDC00',
                'Free-living', '#00AAB7',
                'Lichen', '#C86DD7',
                'Other', '#E14A46'
                );
                

my %family_colors = ('Collemataceae', '#C87A8A',
                  'Pannariaceae', '#AE8B50',
                  'Lobariaceae', '#729C55',
                  'unknown', '#000000',
                  'Nephromataceae', '#00A38F',
                  'Peltigeraceae', '#4C99BE',
                  'Stereocaulaceae', '#A782C3'
            );

my @colors = ('#C87A8A', '#AE8B50', '#729C55', '#00A38F', '#4C99BE', '#A782C3');

my $metadatafile = shift;
my $treefilename = shift;
my $comparison = shift;
my %custom;
if ( $comparison =~ /custom/i ) {
  foreach ( @ARGV ) { $custom{$_} = shift(@colors); }
}

open(my $metadata, "<", $metadatafile );
my %colours;
while (<$metadata>){
  my @fields = split(/\s*\t\s*/, $_);
  $fields[3] =~ /^(\w+)/;
  my $genus = $1;
  #print "$genus\n";
  $colours{$fields[0]} = $host_colors{$host{$genus}};
}
close($metadata);

open(my $treefile, "<", $treefilename );
my $tax_labels = 0;
my $trees = 0;
while (my $line = <$treefile>){
  chomp($line);
  if ( $line =~ /^\s*;\s*/ ) { print "$line\n"; next; }
  if ( $line =~ /^\s*taxlabels\s*$/ ) { $tax_labels = 1; }
  if ( $line =~ /^begin trees;$/ ) { $trees = 1; }
  if ( $line =~ /^\s*end;\s*/ ) { $tax_labels = 0; $trees = 0;}
  if ( $tax_labels ) { $line = ColorTaxa($line, $comparison); }
  if ( $trees ) { $line = AddSig($line); }
  print "$line\n";
}
  
sub ColorTaxa {
  my $line = shift;
  my $comparison = shift;
  my $multiple = 0;
  my $group;
  while ( $line =~ /([A-Z][a-z]+) /g ) {
    my $genus = $1;
    if ( $1 eq 'Group' ) {next; }
    if ( $group and $group ne $host_colors{$host{$genus}} ) { $multiple = 1; }
    if ( $comparison =~ /host/i ) { 
      if ( $host{$genus} and $host_colors{$host{$genus}} ) {
        if ( $group and $group ne $host_colors{$host{$genus}} ) { $multiple = 1; }
        $group = $host_colors{$host{$genus}}; 
      }
    }
    elsif ( $comparison =~ /family/i ) { 
      if ( $taxonomy{$genus} and $family_colors{$taxonomy{$genus}} ) {
        if ( $group and $group ne $family_colors{$taxonomy{$genus}} ) { $multiple = 1; }
        $group = $family_colors{$taxonomy{$genus}}; 
      }
    }
    elsif ( $comparison =~ /genus/i ) { 
      if ( $lichen_colors{$genus} ) {
        if ( $group and $group ne $lichen_colors{$genus} ) { $multiple = 1; }
        $group = $lichen_colors{$genus}; 
      }
    }
    elsif ( $comparison =~ /custom/i ) {
      if ( $custom{$genus} ) {
        if ( $group and $group ne $custom{$genus} ) { $multiple = 1; }
        $group = $custom{$genus}; 
      }
    }  
    elsif ( $comparison =~ /none/i ) { $group = '#000000'; }
    else { die "Colouring scheme $comparison not recognized. Use 'host', 'family' or 'genus' or 'custom'\n"; }
  }
  if ( $multiple ) { $line .=  "[&!color=#000000]"; }
  elsif ( $group ){ $line .=  "[&!color=$group]"; }
  else { $line .=  "[&!color=#A0A0A0]"; }
  return $line;
}

sub AddSig {
  my $line = shift;
  my $out_line;
  my @fields = split(/\[&label=/, $line);
  $out_line .= shift(@fields);
  foreach ( @fields ) { 
    $_ =~ s/(0.\d+)\]//;
    if ( $1 >= 0.9 ) { $out_line .= '[&label=1]'; }
    else { $out_line .= '[&label=0]'; }
    $out_line .= $_;
  }
  return $out_line;
}
