#!/usr/bin/perl
# Reporte les modifications d'une copie du jeu vers une autre (l'instance qu'on lance).
#
#   modsync.pl TT3_SOURCE TT3_CIBLE [--dry]
#
# Pour chaque entree masquee (nom commencant par '#') dans les PKG de la source :
#   - copie le fichier en vrac correspondant vers la cible ;
#   - masque la meme entree dans le PKG de la cible.
# Les entrees masquees dans la cible mais plus dans la source sont restaurees.
# Une entree n'est jamais masquee si son fichier en vrac manque : le jeu plante
# quand il ne trouve un fichier ni dans le PKG ni sur le disque.
# Copie aussi Common/Settings/DUMMY*.DAT s'ils different.
use strict; use warnings; use File::Copy qw(copy); use File::Path qw(make_path); use File::Compare qw(compare);

my ($src, $dst, $flag) = @ARGV;
die "usage: $0 TT3_source TT3_cible [--dry]\n" unless $src && $dst && -d $src && -d $dst;
my $dry = defined $flag && $flag eq '--dry';

sub child {            # sous-element d'un dossier, sans tenir compte de la casse
    my ($dir, $name) = @_;
    return "$dir/$name" if -e "$dir/$name";
    opendir(my $dh, $dir) or return undef;
    my ($hit) = grep { lc $_ eq lc $name } readdir $dh; closedir $dh;
    return defined $hit ? "$dir/$hit" : undef;
}
sub resolve {          # chemin existant, ou undef
    my ($root, @parts) = @_; my $p = $root;
    for my $c (@parts) { $p = child($p, $c) // return undef }
    return $p;
}
sub target {           # chemin a creer : reprend les dossiers existants, quelle que soit la casse
    my ($root, @parts) = @_; my $p = $root;
    for my $c (@parts) { $p = (-d $p ? child($p, $c) : undef) // "$p/$c" }
    return $p;
}
sub index_of {         # nom -> offset du premier caractere du nom dans le fichier
    my $pkg = shift; my %e;
    open(my $fh, '<:raw', $pkg) or die "$pkg: $!\n";
    read($fh, my $h, 0x30); my ($magic, $ver, $n, $isz) = unpack('a4 V V V', $h);
    die "$pkg: pas un PPKG\n" unless $magic eq 'PPKG';
    read($fh, my $idx, $isz); close $fh; my $p = 0;
    for (1 .. $n) { my $l = unpack('V', substr($idx, $p, 4)); $e{ substr($idx, $p + 4, $l) } = 0x30 + $p + 4; $p += 4 + $l + 80 }
    return \%e;
}
sub setbyte { my ($pkg, $off, $ch) = @_; return if $dry;
    open(my $fh, '+<:raw', $pkg) or die "$pkg: $!\n"; seek($fh, $off, 0); print $fh $ch; close $fh }

my $pkgdir = resolve($src, qw(WIN32 PKG CHUNK_0)) // die "pas de dossier PKG dans $src\n";
my ($ncopy, $nhide, $nrest, $nmiss) = (0, 0, 0, 0);
opendir(my $dh, $pkgdir) or die; my @pkgs = sort grep { /\.PKG$/i } readdir $dh; closedir $dh;
for my $pk (@pkgs) {
    my $dpk = resolve($dst, qw(WIN32 PKG CHUNK_0), $pk) // do { warn "absent de la cible: $pk\n"; next };
    my $si = index_of("$pkgdir/$pk"); my $di = index_of($dpk);
    my %hidden = map { $_ => 1 } grep { /^#/ } keys %$si;
    for my $h (sort keys %hidden) {
        my @parts = split /\\/, $h; my $first = shift @parts;      # premier dossier : COMMON ou WIN32
        my $top = $first =~ /^#OMMON$/i ? 'Common' : $first =~ /^#IN32$/i ? 'WIN32' : do { warn "entree ignoree: $h\n"; next };
        my $real = ($top eq 'Common' ? 'C' : 'W') . substr($h, 1);
        my $sf = resolve($src, $top, @parts);
        unless ($sf && -f $sf) { warn "FICHIER EN VRAC MANQUANT dans la source, entree non masquee: $real\n"; $nmiss++; next }
        my $df = target($dst, $top, @parts);
        if (!-f $df || compare($sf, $df) != 0) {
            unless ($dry) { (my $dd = $df) =~ s{/[^/]*$}{}; make_path($dd); copy($sf, $df) or die "copie $df: $!\n" }
            $ncopy++;
        }
        if (exists $di->{$real}) { setbyte($dpk, $di->{$real}, '#'); $nhide++ }
        elsif (!exists $di->{$h}) { warn "entree introuvable dans la cible: $real\n" }
    }
    for my $h (grep { /^#/ && !$hidden{$_} } sort keys %$di) {     # masquee dans la cible seulement
        my $c = $h =~ /^#OMMON\\/i ? 'C' : $h =~ /^#IN32\\/i ? 'W' : next;
        setbyte($dpk, $di->{$h}, $c); $nrest++; print "restaure: $c", substr($h, 1), "\n";
    }
}
if (my $sd = resolve($src, qw(Common Settings))) {
    for my $f (glob("$sd/DUMMY*.DAT")) { (my $b = $f) =~ s{.*/}{};
        my $df = target($dst, 'Common', 'Settings', $b);
        if (!-f $df || compare($f, $df) != 0) { copy($f, $df) unless $dry; $ncopy++; print "config: $b\n" } }
}
printf "%s%d fichier(s) copie(s), %d entree(s) masquee(s), %d restauree(s), %d manquant(s)\n",
    $dry ? '[essai a blanc] ' : '', $ncopy, $nhide, $nrest, $nmiss;
