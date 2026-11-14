#!/usr/bin/perl
# Remplit une texture PTX (RIFF PATX, format DXT1) d'une couleur unie, tous niveaux de
# mipmap compris. Sert a rendre un objet immediatement reconnaissable pour un test en jeu.
#   ptxfill.pl ENTREE.PTX SORTIE.PTX [RRGGBB]      couleur par defaut : ff00ff (magenta)
use strict; use warnings;
my ($in, $out, $rgb) = @ARGV; die "usage: $0 entree.ptx sortie.ptx [RRGGBB]\n" unless $out;
$rgb //= 'ff00ff'; die "couleur attendue sous la forme RRGGBB\n" unless $rgb =~ /^[0-9a-fA-F]{6}$/;
open(my $fh, '<:raw', $in) or die "$in: $!\n"; my $d; { local $/; $d = <$fh>; } close $fh;
die "$in: pas une texture RIFF PATX\n" unless substr($d, 0, 4) eq 'RIFF' && substr($d, 20, 4) eq 'PATX';
die "$in: seul le format DXT1 est gere\n" unless substr($d, 0x3c, 4) eq 'DXT1';
my ($r, $g, $b) = map { hex } $rgb =~ /(..)(..)(..)/;
my $c = (($r >> 3) << 11) | (($g >> 2) << 5) | ($b >> 3);
my $block = pack('v v V', $c, $c, 0);      # bloc DXT1 : deux couleurs identiques, indices a 0
my ($n, $lv) = (0, 0);
sub walk { my ($p, $end) = @_;
    while ($p + 8 <= $end) {
        my ($id, $sz) = unpack('a4 V', substr($d, $p, 8)); last unless $id =~ /^[A-Za-z0-9_ ]{4}$/; my $s = $p + 8;
        if ($id eq 'LIST') { walk($s + 4, $s + $sz) }
        elsif ($id eq 'Pixl') { substr($d, $s, $sz) = $block x ($sz / 8); $n += $sz / 8; $lv++ }
        $p = $s + $sz;
    }
}
walk(12, length($d));
die "aucun bloc de pixels trouve\n" unless $n;
open(my $o, '>:raw', $out) or die "$out: $!\n"; print $o $d; close $o;
print "ecrit: $out ($lv niveaux, $n blocs, couleur #$rgb)\n";
