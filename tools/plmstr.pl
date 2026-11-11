#!/usr/bin/perl
# Dump de l'en-tete et de la table de chaines d'un PLM (PLMB). usage: plmstr.pl file.plm
use strict; use warnings;
my $f = shift or die "usage: $0 fichier.plm\n";
open(my $fh,'<:raw',$f) or die "$f: $!\n"; local $/; my $d=<$fh>;
my @h = unpack('a4 V V f9', substr($d,0,0x30));
printf "magic=%s ver=%d flag=%d bbox=(%s)\n", $h[0],$h[1],$h[2], join(',',@h[3..11]);
my @c = unpack('V16', substr($d,0x30,0x40));
print "hdr: @c\n";
my ($strsz,$nstr)=@c[0,1];
my @s = split(/\0/, substr($d,0x80,$strsz));
printf "%d chaines (attendu %d), fin table=0x%x, taille=%d\n", scalar(@s),$nstr,0x80+$strsz,length($d);
print "$_\n" for @s;
