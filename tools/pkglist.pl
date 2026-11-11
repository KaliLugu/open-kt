#!/usr/bin/perl
# Liste l'index d'une archive PPKG (KT Engine). usage: pkglist.pl FILE.PKG
use strict; use warnings;
my $f = shift or die "usage: $0 file.pkg\n";
open(my $fh, '<:raw', $f) or die "$f: $!";
read($fh, my $h, 0x30);
my ($magic, $ver, $count, $isize) = unpack('a4 V V V', $h);
die "pas un PPKG\n" unless $magic eq 'PPKG';
print STDERR "version=$ver count=$count index_size=$isize\n";
read($fh, my $idx, $isize);
my $p = 0;
for my $i (1..$count) {
    my $nl = unpack('V', substr($idx, $p, 4)); $p += 4;
    my $name = substr($idx, $p, $nl); $p += $nl;
    my ($crc, $off, $ft, $csz, $usz, $comp, $h1, $h2) = unpack('V Q< Q< Q< Q< V V V', substr($idx, $p, 48)); $p += 48;
    my $rest = unpack('H*', substr($idx, $p, 32)); $p += 32;
    printf "%s\t%d\t%d\t%d\t%d\t%08x\t%s\n", $name, $off, $csz, $usz, $comp, $crc, ($rest =~ /^0+$/ ? '' : $rest);
}
print STDERR "fin index: $p / $isize\n";
