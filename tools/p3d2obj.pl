#!/usr/bin/perl
# Convertit un modele P3D de TT3 en Wavefront OBJ (positions, UV, triangles).
#   p3d2obj.pl MODELE.P3D [SORTIE.OBJ]      sans sortie : affiche seulement le contenu
#   p3d2obj.pl --terrain DOSSIER SORTIE.OBJ assemble tous les HEIGHTMAP_xx_yy.P3D du dossier,
#                                           chacun place a sa position dans le monde
# Le P3D est un conteneur RIFF ; format decrit dans docs/formats/p3d.md.
# Repere du jeu : Z vers le haut, 1 unite = 1 metre.
use strict; use warnings;

my $terrain = (@ARGV && $ARGV[0] eq '--terrain') ? shift : undef;
my ($in, $out) = @ARGV; die "usage: $0 modele.p3d [sortie.obj]\n       $0 --terrain dossier sortie.obj\n" unless $in && (!$terrain || $out);
my $d;

my @ident = (1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1);
sub mul { my ($a, $b) = @_; my @r;        # r = a * b (vecteurs ligne)
    for my $i (0..3) { for my $j (0..3) { my $s = 0; $s += $a->[4*$i+$_] * $b->[4*$_+$j] for 0..3; $r[4*$i+$j] = $s } } \@r }

my (@parts, $cur);
sub walk {
    my ($p, $end, $mat, $path) = @_;
    while ($p + 8 <= $end) {
        my ($id, $sz) = unpack('a4 V', substr($d, $p, 8));
        last unless $id =~ /^[A-Za-z0-9_ ]{4}$/;
        my $b = $p + 8;
        if ($id eq 'LIST') { walk($b + 4, $b + $sz, $mat, $path) }
        elsif ($id eq 'NoHe') {
            my $nl = unpack('V', substr($d, $b + 2, 4)); my $name = substr($d, $b + 6, $nl);
            my @m = unpack('f16', substr($d, $b + 8 + $nl, 64));
            $mat = mul(\@m, $mat); $path = $path eq '' ? $name : "$path/$name";
        }
        elsif ($id eq 'SuGe') {
            my ($t, $nv, $nt) = unpack('v V V', substr($d, $b, 10));
            $cur = { name => $path, nv => $nv, nt => $nt, mat => $mat }; push @parts, $cur;
        }
        elsif ($cur && $id eq 'vpos' && !$cur->{pos}) { $cur->{pos} = substr($d, $b, $sz) }
        elsif ($cur && $id eq 'vuvs' && !$cur->{uv})  { $cur->{uv} = substr($d, $b, $sz); $cur->{uvstride} = $cur->{nv} ? $sz / $cur->{nv} : 0 }
        elsif ($cur && $id eq 'indx' && !$cur->{idx}) { $cur->{idx} = substr($d, $b, $sz) }
        elsif ($id eq 'EndG') { $cur = undef }
        $p = $b + $sz;
    }
}
sub load {
    my ($f, $m) = @_;
    open(my $fh, '<:raw', $f) or die "$f: $!\n"; { local $/; $d = <$fh>; } close $fh;
    die "$f: pas un RIFF PA__\n" unless substr($d, 0, 4) eq 'RIFF' && substr($d, 8, 4) eq 'PA__';
    $cur = undef; walk(12, length($d), $m, '');
}
if ($terrain) {
    opendir(my $dh, $in) or die "$in: $!\n";
    for my $f (sort grep { /^HEIGHTMAP_(\d+)_(\d+)\.P3D$/i } readdir $dh) {
        my ($i, $j) = $f =~ /_(\d+)_(\d+)\./;
        load("$in/$f", [1,0,0,0, 0,1,0,0, 0,0,1,0, -16384 + 1024 * $i, -16384 + 1024 * $j, 0, 1]);
    }
} else { load($in, \@ident) }

my ($tv, $tt) = (0, 0);
for my $s (@parts) {
    my $w = ($s->{idx} && length($s->{idx}) == $s->{nt} * 12) ? 4 : 2; $s->{iw} = $w;
    printf "%-50s %7d sommets %7d triangles (indices %d bits)\n", $s->{name}, $s->{nv}, $s->{nt}, 8 * $w;
    $tv += $s->{nv}; $tt += $s->{nt};
}
printf "total: %d parties, %d sommets, %d triangles\n", scalar @parts, $tv, $tt;
exit 0 unless $out;

open(my $o, '>', $out) or die "$out: $!\n";
print $o "# converti depuis $in\n";
my $base = 1;
for my $s (@parts) {
    next unless $s->{pos} && $s->{idx} && length($s->{pos}) == 12 * $s->{nv};
    (my $n = $s->{name}) =~ s/\s+/_/g; print $o "o $n\n";
    my @v = unpack('f*', $s->{pos}); my $m = $s->{mat};
    for my $i (0 .. $s->{nv} - 1) {
        my ($x, $y, $z) = @v[3*$i .. 3*$i+2];
        printf $o "v %.5f %.5f %.5f\n",
            $x*$m->[0] + $y*$m->[4] + $z*$m->[8]  + $m->[12],
            $x*$m->[1] + $y*$m->[5] + $z*$m->[9]  + $m->[13],
            $x*$m->[2] + $y*$m->[6] + $z*$m->[10] + $m->[14];
    }
    my $hasuv = $s->{uv} && $s->{uvstride} >= 4;
    if ($hasuv) {
        for my $i (0 .. $s->{nv} - 1) {
            my ($u, $w) = unpack('s2', substr($s->{uv}, $i * $s->{uvstride}, 4));
            printf $o "vt %.5f %.5f\n", $u / 4096, 1 - $w / 4096;
        }
    }
    my @ix = unpack(($s->{iw} == 4 ? 'V*' : 'v*'), $s->{idx});
    for (my $i = 0; $i + 2 < @ix; $i += 3) {
        my @f = map { $_ + $base } @ix[$i .. $i+2];
        print $o 'f ', join(' ', map { $hasuv ? "$_/$_" : $_ } @f), "\n";
    }
    $base += $s->{nv};
}
close $o; print "ecrit: $out\n";
