#!/usr/bin/perl
# Lecture et modification des scenes PLM (magic PLMB, version 12) de TT3.
#
#   plm.pl dump  FICHIER.PLM [regex]     arbre des entites, composants et proprietes
#   plm.pl tree  FICHIER.PLM [regex]     arbre des entites seulement
#   plm.pl subs  FICHIER.PLM             sous-niveaux references (tuiles, circuits...)
#   plm.pl set   ENTREE.PLM SORTIE.PLM MODIF [MODIF...]
#
# MODIF :
#   ENTITE:Classe.Propriete=valeur    ex.  'RaceInitializer:GPRaceInitializerComponent.NbLaps=3'
#   ENTITE:Propriete=valeur           si la propriete n'existe que dans un composant de l'entite
#   ENTITE:pos=x,y,z   ENTITE:rot=x,y,z   ENTITE:scale=x,y,z
# ENTITE = nom de l'entite, ou #identifiant (8 chiffres hexa affiches par dump) si le nom
# n'est pas unique. Classe = fin du nom de classe (ex. "Mesh").
#
# Format du fichier : voir docs/formats/plm.md
use strict; use warnings; no warnings 'recursion';

my $cmd = shift // ''; my $file = shift;
die "usage: $0 dump|tree|subs FICHIER.PLM [regex]\n       $0 set ENTREE.PLM SORTIE.PLM MODIF...\n"
    unless $file && $cmd =~ /^(dump|tree|subs|set)$/;

open(my $fh, '<:raw', $file) or die "$file: $!\n"; my $d; { local $/; $d = <$fh>; } close $fh;
die "$file: pas un PLMB\n" unless substr($d, 0, 4) eq 'PLMB';
my ($ver, $flag) = unpack('V V', substr($d, 4, 8));
my @bb = unpack('f9', substr($d, 0x0c, 36));
my ($ss, $nn, $nsz, $ng, $maxp, $h5, $nsub, $maxd) = unpack('V8', substr($d, 0x30, 32));
die "$file: version $ver non geree\n" unless $ver == 12;
die "$file: taille de noeud inattendue\n" unless $nsz == $nn * 69;
my $st = substr($d, 0x80, $ss);
sub S { my $o = shift; return "?$o" if $o >= length($st); my $e = index($st, "\0", $o); substr($st, $o, $e - $o) }
sub num { my $s = sprintf('%.6g', $_[0]); $s eq '-0' ? '0' : $s }

# --- sous-niveaux
my $p = 0x80 + $ss; my @subs;
for my $i (0 .. $nsub - 1) {
    my ($type, $path, $x, $y, $z, $fl) = unpack('V V f3 V', substr($d, $p + 24 * $i, 24));
    push @subs, { type => $type, path => S($path), pos => [$x, $y, $z], flag => $fl };
}
$p += 24 * $nsub;

# --- noeuds (entites)
my (@nodes, %byid, %kids, @roots); my $nodes_off = $p;
for my $i (0 .. $nn - 1) {
    my $o = $p + 69 * $i; my $r = substr($d, $o, 69);
    my ($name, $id, $u, $par) = unpack('V4', $r);
    my @t = unpack('f9', substr($r, 24, 36));
    my ($cc, $ncomp, $depth, $fl) = unpack('V v v C', substr($r, 60));
    my $n = { off => $o, name => S($name), id => $id, parent => $par, t => \@t, layer => $u, flags => $fl, comps => [] };
    push @nodes, $n; $byid{$id} = $n;
    if ($par && $i) { push @{ $kids{$par} }, $n } else { push @roots, $n }
}
$p += $nsz;

# --- composants
sub block {   # bloc = en-tete 10 octets, noms, instances
    my ($q, $class, $gid, $lvl) = @_;
    my ($np, $ns, $u, $nc, $cnt) = unpack('v5', substr($d, $q, 10)); $q += 10;
    my @pn = map { S($_) } unpack("V$np", substr($d, $q, 4 * $np)); $q += 4 * $np;
    my @inst;
    for (1 .. $cnt) {
        my ($id, $sz) = unpack('V V', substr($d, $q, 8)); my $e = $q + $sz;
        my $in = { class => $class, gid => $gid, id => $id, props => [], subs => [] };
        for my $k (0 .. $ns - 1) {
            my $vo = $q + 8 + 4 * $k;
            push @{ $in->{props} }, { name => $pn[$k], voff => $vo, val => S(unpack('V', substr($d, $vo, 4))) };
        }
        my $r = $q + 8 + 4 * $ns;
        for my $k (0 .. $nc - 1) {
            my ($list, $r2) = block($r + 8, $pn[$ns + $k], $gid, $lvl + 1);
            push @{ $in->{subs} }, { name => $pn[$ns + $k], items => $list }; $r = $r2;
        }
        die sprintf("%s: structure inattendue dans %s (offset %d)\n", $file, $class, $q) if $r != $e;
        push @inst, $in; $q = $e + 8;
    }
    return (\@inst, $q);
}
my $comps_off = $p;
for (1 .. $ng) {
    my ($gid, $gsz, $ncl) = unpack('l V V', substr($d, $p, 12)); my $q = $p + 12;
    for (1 .. $ncl) {
        my $class = S(unpack('V', substr($d, $q, 4)));
        my ($list, $q2) = block($q + 4, $class, $gid, 0); $q = $q2;
        for my $in (@$list) {
            my $n = $byid{ $in->{id} };
            if ($n) { push @{ $n->{comps} }, $in } else { warn sprintf("composant %s sans entite (#%08x)\n", $class, $in->{id}) }
        }
    }
    die "$file: fin de groupe inattendue\n" if $q != $p + 12 + $gsz;
    $p = $q;
}

# --- commandes
if ($cmd eq 'subs') {
    printf "%d sous-niveaux\n", scalar @subs;
    printf "type=%d flag=%d pos=(%s)  %s\n", $_->{type}, $_->{flag}, join(', ', map { num($_) } @{ $_->{pos} }), $_->{path} for @subs;
    exit 0;
}

if ($cmd eq 'dump' || $cmd eq 'tree') {
    my $re = shift; $re = qr/$re/im if defined $re;
    printf "# %s : version %d, %d entites, %d sous-niveaux, bornes (%s)\n", $file, $ver, $nn, $nsub, join(', ', map { num($_) } @bb);
    my $subitems; $subitems = sub {
        my ($in, $ind) = @_; my $out = '';
        $out .= sprintf("%s%s = %s\n", $ind, $_->{name}, $_->{val}) for @{ $in->{props} };
        for my $s (@{ $in->{subs} }) {
            $out .= sprintf("%s%s [%d]\n", $ind, $s->{name}, scalar @{ $s->{items} });
            my $i = 0; for my $it (@{ $s->{items} }) { $out .= sprintf("%s  - %d\n", $ind, $i++) . $subitems->($it, "$ind      ") }
        }
        return $out;
    };
    my $show; $show = sub {
        my ($n, $ind, $path) = @_;
        my $full = "$path/$n->{name}";
        my $txt = sprintf("%s[#%08x] %s", $ind, $n->{id}, $n->{name});
        my @t = @{ $n->{t} };
        $txt .= sprintf("  pos=(%s)", join(',', map { num($_) } @t[0 .. 2])) if grep { $_ != 0 } @t[0 .. 2];
        $txt .= sprintf("  rot=(%s)", join(',', map { num($_) } @t[3 .. 5])) if grep { $_ != 0 } @t[3 .. 5];
        $txt .= sprintf("  scale=(%s)", join(',', map { num($_) } @t[6 .. 8])) if grep { $_ != 1 } @t[6 .. 8];
        $txt .= "\n";
        if ($cmd eq 'dump') {
            for my $c (@{ $n->{comps} }) { $txt .= "$ind    <$c->{class}>\n" . $subitems->($c, "$ind      ") }
        } else {
            $txt .= "$ind    <$_->{class}>\n" for @{ $n->{comps} };
        }
        print $txt if !defined $re || "$full\n$txt" =~ $re;
        $show->($_, "$ind  ", $full) for @{ $kids{ $n->{id} } || [] };
    };
    $show->($_, '', '') for @roots;
    exit 0;
}

# --- set
my $out = shift; my @mods = @ARGV;
die "usage: $0 set ENTREE.PLM SORTIE.PLM MODIF...\n" unless $out && @mods;
my $rest = substr($d, 0x80 + $ss); my $base = 0x80 + $ss;    # tout ce qui suit la table de chaines
my %sidx; { my $o = 0; for my $s (split /\0/, $st, -1) { $sidx{$s} //= $o; $o += length($s) + 1 } }
my $newst = $st;
sub stroff { my $s = shift; return $sidx{$s} if exists $sidx{$s}; my $o = length($newst); $newst .= "$s\0"; $sidx{$s} = $o; return $o }

for my $m (@mods) {
    my ($ent, $key, $val) = $m =~ /^(.+?):([^=]+)=(.*)$/s or die "modification illisible: $m\n";
    my @cand = $ent =~ /^#([0-9a-fA-F]{1,8})$/ ? grep { $_->{id} == hex($1) } @nodes : grep { $_->{name} eq $ent } @nodes;
    die "entite introuvable: $ent\n" unless @cand;
    die "nom d'entite ambigu: $ent -> " . join(' ', map { sprintf '#%08x', $_->{id} } @cand) . "\n" if @cand > 1;
    my $n = $cand[0];
    if ($key =~ /^(pos|rot|scale)$/) {
        my @v = split /[,;]/, $val; die "$key attend 3 nombres: $m\n" unless @v == 3;
        my $i = { pos => 0, rot => 3, scale => 6 }->{$key};
        substr($rest, $n->{off} - $base + 24 + 4 * $i, 12) = pack('f3', @v);
        printf "%s (#%08x) %s : (%s) -> (%s)\n", $n->{name}, $n->{id}, $key, join(',', map { num($_) } @{ $n->{t} }[$i .. $i + 2]), join(',', @v);
        next;
    }
    my ($cls, $prop) = $key =~ /^(.*?)\.(.+)$/ ? ($1, $2) : (undef, $key);
    my @hit;
    for my $c (@{ $n->{comps} }) {
        next if defined $cls && $c->{class} !~ /(?:^|::)\Q$cls\E$/;
        push @hit, [$c, $_] for grep { $_->{name} eq $prop } @{ $c->{props} };
    }
    die "propriete introuvable: $m\n" unless @hit;
    die "propriete ambigue, preciser la classe: " . join(' ', map { $_->[0]{class} } @hit) . "\n" if @hit > 1;
    my ($c, $pr) = @{ $hit[0] };
    substr($rest, $pr->{voff} - $base, 4) = pack('V', stroff($val));
    printf "%s (#%08x) <%s> %s : %s -> %s\n", $n->{name}, $n->{id}, $c->{class}, $prop, $pr->{val}, $val;
}
my $head = substr($d, 0, 0x80); substr($head, 0x30, 4) = pack('V', length($newst));
open(my $o, '>:raw', $out) or die "$out: $!\n"; print $o $head, $newst, $rest; close $o;
printf "ecrit: %s (%d octets, table de chaines +%d)\n", $out, 0x80 + length($newst) + length($rest), length($newst) - $ss;
