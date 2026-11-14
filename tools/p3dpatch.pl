#!/usr/bin/perl
# Retouche un modele P3D de TT3 : ne change que la position des sommets (et les boites
# englobantes), tout le reste du fichier est conserve a l'identique.
#
#   p3dpatch.pl ENTREE.P3D SORTIE.P3D --scale sx,sy,sz [--part REGEX]
#   p3dpatch.pl ENTREE.P3D SORTIE.P3D --move  dx,dy,dz [--part REGEX]
#   p3dpatch.pl ENTREE.P3D SORTIE.P3D --obj MODIFIE.OBJ
#
# --scale / --move : appliques aux coordonnees locales du modele (Z = hauteur, en metres).
# --part           : limite aux parties dont le nom correspond (voir p3d2obj.pl pour les noms).
# --obj            : reprend les positions d'un OBJ produit par p3d2obj.pl puis modifie dans
#                    un logiciel 3D. Meme nombre de sommets, dans le meme ordre : on peut
#                    deplacer des sommets, pas en ajouter ni en supprimer.
# Non mis a jour : normales (eclairage), collision.
use strict; use warnings;

my ($in, $out, @opt) = @ARGV;
my (%o); while (@opt) { my $k = shift @opt; die "option inconnue: $k\n" unless $k =~ /^--(scale|move|obj|part)$/; $o{$1} = shift @opt // die "valeur manquante pour $k\n" }
die "usage: $0 entree.p3d sortie.p3d --scale sx,sy,sz | --move dx,dy,dz | --obj fichier.obj [--part regex]\n"
    unless $in && $out && (grep { $o{$_} } qw(scale move obj));
my @sc = $o{scale} ? split(/,/, $o{scale}) : (1, 1, 1); die "--scale attend 3 nombres\n" unless @sc == 3;
my @mv = $o{move}  ? split(/,/, $o{move})  : (0, 0, 0); die "--move attend 3 nombres\n"  unless @mv == 3;
my $partre = defined $o{part} ? qr/$o{part}/i : undef;

open(my $fh, '<:raw', $in) or die "$in: $!\n"; my $d; { local $/; $d = <$fh>; } close $fh;
die "$in: pas un RIFF PA__\n" unless substr($d, 0, 4) eq 'RIFF' && substr($d, 8, 4) eq 'PA__';

# --- lecture de l'OBJ : sommets regroupes par objet
my (@objs, %objbyname);
if ($o{obj}) {
    open(my $f, '<', $o{obj}) or die "$o{obj}: $!\n"; my $cur;
    while (<$f>) {
        if (/^o\s+(\S+)/) { $cur = { name => $1, v => [] }; push @objs, $cur; $objbyname{$1} = $cur }
        elsif (/^v\s+(\S+)\s+(\S+)\s+(\S+)/) { $cur //= do { my $c = { name => '', v => [] }; push @objs, $c; $c }; push @{ $cur->{v} }, [$1, $2, $3] }
    }
}

my @ident = (1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1);
sub mul { my ($a, $b) = @_; my @r;
    for my $i (0..3) { for my $j (0..3) { my $s = 0; $s += $a->[4*$i+$_] * $b->[4*$_+$j] for 0..3; $r[4*$i+$j] = $s } } \@r }
sub inverse {   # inverse d'une matrice affine (vecteurs ligne, translation en derniere ligne)
    my $m = shift; my ($a,$b,$c,$d2,$e,$f,$g,$h,$i) = @$m[0,1,2,4,5,6,8,9,10];
    my $det = $a*($e*$i-$f*$h) - $b*($d2*$i-$f*$g) + $c*($d2*$h-$e*$g); die "matrice de noeud non inversible\n" if abs($det) < 1e-12;
    my @r = (($e*$i-$f*$h)/$det, ($c*$h-$b*$i)/$det, ($b*$f-$c*$e)/$det,
             ($f*$g-$d2*$i)/$det, ($a*$i-$c*$g)/$det, ($c*$d2-$a*$f)/$det,
             ($d2*$h-$e*$g)/$det, ($b*$g-$a*$h)/$det, ($a*$e-$b*$d2)/$det);
    my @t = @$m[12,13,14];
    return [@r[0..2],0, @r[3..5],0, @r[6..8],0,
            -($t[0]*$r[0]+$t[1]*$r[3]+$t[2]*$r[6]), -($t[0]*$r[1]+$t[1]*$r[4]+$t[2]*$r[7]), -($t[0]*$r[2]+$t[1]*$r[5]+$t[2]*$r[8]), 1];
}

my ($nparts, $changed, $mesh, $sub, $index) = (0, 0, undef, undef, 0);
sub flush_mesh {    # ecrit la boite et la sphere englobantes du maillage courant
    return unless $mesh && $mesh->{n};
    my @mn = @{ $mesh->{mn} }; my @mx = @{ $mesh->{mx} }; my @c = map { ($mn[$_] + $mx[$_]) / 2 } 0..2;
    my $r = sqrt(($mx[0]-$c[0])**2 + ($mx[1]-$c[1])**2 + ($mx[2]-$c[2])**2);
    substr($d, $mesh->{off} + 5, 24) = pack('f6', @mn, @mx);
    substr($d, $mesh->{off} + 33, 16) = pack('f4', @c, $r) if $mesh->{size} >= 49;
    $mesh = undef;
}
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
        elsif ($id eq 'Mesh') { flush_mesh(); $mesh = { off => $b, size => $sz, n => 0 } }
        elsif ($id eq 'SuGe') { my ($t, $nv, $nt) = unpack('v V V', substr($d, $b, 10)); $sub = { nv => $nv, name => $path, done => 0 } }
        elsif ($id eq 'vpos' && $sub && !$sub->{done}) {
            $sub->{done} = 1; $nparts++;
            my $nv = $sub->{nv}; die "$sub->{name}: bloc vpos de taille inattendue\n" unless $sz == 12 * $nv;
            my @v = unpack('f*', substr($d, $b, $sz)); my $touch = !$partre || $sub->{name} =~ $partre;
            if ($touch && $o{obj}) {
                (my $n = $sub->{name}) =~ s/\s+/_/g;
                my $ob = $objbyname{$n} // (@objs > $index ? $objs[$index] : undef);
                die "$sub->{name}: partie absente de l'OBJ\n" unless $ob;
                die sprintf("%s: %d sommets dans l'OBJ, %d dans le P3D (il faut garder le meme nombre et le meme ordre)\n", $sub->{name}, scalar @{ $ob->{v} }, $nv) unless @{ $ob->{v} } == $nv;
                my $im = inverse($mat);
                for my $i (0 .. $nv - 1) {
                    my ($x, $y, $z) = @{ $ob->{v}[$i] };
                    @v[3*$i .. 3*$i+2] = ($x*$im->[0] + $y*$im->[4] + $z*$im->[8] + $im->[12],
                                           $x*$im->[1] + $y*$im->[5] + $z*$im->[9] + $im->[13],
                                           $x*$im->[2] + $y*$im->[6] + $z*$im->[10] + $im->[14]);
                }
            } elsif ($touch) {
                for my $i (0 .. $nv - 1) { $v[3*$i+$_] = $v[3*$i+$_] * $sc[$_] + $mv[$_] for 0..2 }
            }
            if ($touch) { substr($d, $b, $sz) = pack('f*', @v); $changed++; printf "modifie : %s (%d sommets)\n", $sub->{name}, $nv }
            $index++;
            if ($mesh) { for my $i (0 .. $nv - 1) { for my $k (0..2) { my $x = $v[3*$i+$k];
                $mesh->{mn}[$k] = $x if !$mesh->{n} || $x < $mesh->{mn}[$k]; $mesh->{mx}[$k] = $x if !$mesh->{n} || $x > $mesh->{mx}[$k] } $mesh->{n}++ } }
        }
        $p = $b + $sz;
    }
}
walk(12, length($d), \@ident, ''); flush_mesh();
die "aucune partie modifiee\n" unless $changed;
open(my $of, '>:raw', $out) or die "$out: $!\n"; print $of $d; close $of;
printf "ecrit: %s (%d partie(s) modifiee(s) sur %d, %d octets)\n", $out, $changed, $nparts, length($d);
