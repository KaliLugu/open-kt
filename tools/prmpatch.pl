#!/usr/bin/perl
# Deplace la geometrie visible d'un .PRM de route (RIFF PA__ / PROAD) de TT3.
#
#   prmpatch.pl ENTREE.PRM SORTIE.PRM --move dx,dy,dz
#   prmpatch.pl ENTREE.PRM                      # affiche le contenu
#
# Les sommets sont en coordonnees du monde (Z = hauteur, en metres). Tous les niveaux
# de detail sont deplaces, ainsi que les volumes englobants des blocs Mesh.
# Le bloc Phys (collision PhysX) est deplace aussi : sommets, arbre de recherche et
# boite englobante de chaque maillage de collision. --visual le laisse intact.
use strict; use warnings;

my ($in, $out, @opt) = @ARGV;
die "usage: $0 entree.prm [sortie.prm --move dx,dy,dz]\n" unless $in;
my @mv; my $visual = 0;
if ($out) {
    @opt = grep { $_ eq "--visual" ? do { $visual = 1; 0 } : 1 } @opt;
    die "usage: $0 entree.prm sortie.prm --move dx,dy,dz [--visual]\n" unless @opt == 2 && $opt[0] eq "--move";
    @mv = split /,/, $opt[1]; die "--move attend 3 nombres\n" unless @mv == 3;
}
open(my $fh, '<:raw', $in) or die "$in: $!\n"; my $d; { local $/; $d = <$fh>; } close $fh;
die "$in: pas un RIFF PA__\n" unless substr($d, 0, 4) eq 'RIFF' && substr($d, 8, 4) eq 'PA__';

my ($nmesh, $nvpos, $nverts, $lod) = (0, 0, 0, -1); my $nphys = 0;
# Bloc Phys : u32 nombre de maillages, puis pour chacun u32 present ; si present :
# u32 taille, maillage PhysX cuit (NXS MESH v14), chaine du materiau physique.
sub phys {
    my ($pb, $ps) = @_; my $q = $pb; my $n = unpack("V", substr($d, $q, 4)); $q += 4;
    for my $m (1 .. $n) {
        my $present = unpack("V", substr($d, $q, 4)); $q += 4; next unless $present;
        my $sz = unpack("V", substr($d, $q, 4)); $q += 4; my $s = $q;
        my ($mag, $ver, $mid, $fl, $nv, $nt) = unpack("a8 V V V V V", substr($d, $q, 28)); $q += 28;
        die "$in: maillage de collision $m non reconnu\n" unless $mag eq "NXS\x01MESH" && $ver == 14 && $mid == 0;
        my $vo = $q; $q += 12 * $nv;
        $q += (($fl & 4) ? 1 : ($fl & 8) ? 2 : 4) * 3 * $nt;
        $q += 2 * $nt if $fl & 1;
        if ($fl & 2) { my $max = unpack("V", substr($d, $q, 4)); $q += 4 + ($max <= 0xff ? 1 : $max <= 0xffff ? 2 : 4) * $nt }
        $q += 12 * $nt if $fl & 16;
        die "$in: arbre RTRE absent du maillage de collision $m\n" unless substr($d, $q, 4) eq "RTRE";
        my $ro = $q + 8; my $npages = unpack("N", substr($d, $ro + 80, 4));     # arbre en gros-boutiste
        my $po = $ro + 88; my $bo = $po + 112 * $npages + 4;                   # +4 : epsilon
        my $nx = unpack("V", substr($d, $bo + 24, 4));
        die "$in: taille du maillage de collision $m incoherente\n" unless $bo + 28 + $nx - $s == $sz;
        $nphys++;
        if (@mv && !$visual) {
            my @v = unpack("f<*", substr($d, $vo, 12 * $nv));
            for (my $i = 0; $i < @v; $i += 3) { $v[$i + $_] += $mv[$_] for 0..2 }
            substr($d, $vo, 12 * $nv) = pack("f<*", @v);
            for my $o ($ro, $ro + 16) { my @b = unpack("f>3", substr($d, $o, 12)); substr($d, $o, 12) = pack("f>3", map { $b[$_] + $mv[$_] } 0..2) }
            for my $pg (0 .. $npages - 1) {      # page : minx[4] miny[4] minz[4] maxx[4] maxy[4] maxz[4] ptrs[4]
                my @f = unpack("f>24", substr($d, $po + 112 * $pg, 96));
                for my $k (0 .. 23) { $f[$k] += $mv[int($k / 4) % 3] if abs($f[$k]) < 1e30 }   # cases vides : +-FLT_MAX
                substr($d, $po + 112 * $pg, 96) = pack("f>24", @f);
            }
            my @lb = unpack("f<6", substr($d, $bo, 24)); substr($d, $bo, 24) = pack("f<6", map { $lb[$_] + $mv[$_ % 3] } 0..5);
        } elsif (!@mv) { printf "Collision %d : %d sommets, %d triangles, %d pages d arbre\n", $m, $nv, $nt, $npages }
        $q = $s + $sz; $q += 4 + unpack("V", substr($d, $q, 4));
    }
}
sub walk {
    my ($p, $end) = @_;
    while ($p + 8 <= $end) {
        my ($id, $sz) = unpack('a4 V', substr($d, $p, 8));
        last unless $id =~ /^[A-Za-z0-9_ ]{4}$/;
        my $b = $p + 8;
        if ($id eq 'LIST') { walk($b + 4, $b + $sz) }
        elsif ($id eq 'Mesh' && $sz >= 140) {
            # matrice 4x4, axes 3x3, centre, demi-tailles, centre de sphere, rayon
            my @c = unpack('f3', substr($d, $b + 100, 12)); my @h = unpack('f3', substr($d, $b + 112, 12));
            my @s = unpack('f4', substr($d, $b + 124, 16)); $nmesh++;
            if (@mv) {
                substr($d, $b + 100, 12) = pack('f3', map { $c[$_] + $mv[$_] } 0..2);
                substr($d, $b + 124, 12) = pack('f3', map { $s[$_] + $mv[$_] } 0..2);
            } else { printf "Mesh %d : centre (%.2f, %.2f, %.2f), demi-tailles (%.2f, %.2f, %.2f), rayon %.2f\n", $nmesh, @c, @h, $s[3] }
        }
        elsif ($id eq 'LdHe') { $lod = unpack('V', substr($d, $b, 4)) }
        elsif ($id eq 'SuGe' && !@mv) { printf "  LOD %d : %d sommets, %d triangles\n", $lod, unpack('V V', substr($d, $b, 8)) }
        elsif ($id eq 'vpos') {
            die "bloc vpos de taille inattendue\n" if $sz % 12;
            $nvpos++; $nverts += $sz / 12;
            if (@mv) {
                my @v = unpack('f*', substr($d, $b, $sz));
                for (my $i = 0; $i < @v; $i += 3) { $v[$i + $_] += $mv[$_] for 0..2 }
                substr($d, $b, $sz) = pack('f*', @v);
            }
        }
        elsif ($id eq "Phys") { phys($b, $sz) }
        $p = $b + $sz;
    }
}
walk(12, length($d));
exit 0 unless @mv;
die "$in: aucun bloc vpos\n" unless $nvpos;
open(my $of, '>:raw', $out) or die "$out: $!\n"; print $of $d; close $of;
printf "ecrit: %s (%d blocs de sommets, %d maillages, %d collisions %s)\n", $out, $nvpos, $nmesh, $nphys, $visual ? "laissees" : "deplacees";
