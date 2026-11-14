#!/usr/bin/perl
# Extrait des fichiers d'une archive PPKG (KT Engine / TT3).
# usage: pkgextract.pl FILE.PKG OUTDIR [regex_nom]
# Format: "PPKG" u32 ver u32 count u32 index_size, pad -> 0x30, puis entrees:
#   u32 namelen, name, u32 crc, u64 offset, u64 filetime, u64 csize, u64 usize, u32 comp, 8o hash, 32o zero
# Donnees: "PKGB" + (comp=2: frame LZ4 | comp=0: brut) + "PKGE"
#   derniers champs de l'entree: crc32 des donnees stockees, crc32 des donnees decompressees
use strict; use warnings;
my ($f, $out, $re) = @ARGV; die "usage: $0 file.pkg outdir [regex]\n" unless $out;
open(my $fh, '<:raw', $f) or die "$f: $!";
read($fh, my $h, 0x30);
my ($magic, $ver, $count, $isize) = unpack('a4 V V V', $h);
die "pas un PPKG\n" unless $magic eq 'PPKG';
read($fh, my $idx, $isize);
my $p = 0; my $n = 0;
for my $i (1..$count) {
    my $nl = unpack('V', substr($idx, $p, 4)); $p += 4;
    my $name = substr($idx, $p, $nl); $p += $nl;
    my ($crc, $off, $ft, $csz, $usz, $comp, $c1, $c2) = unpack('V Q< Q< Q< Q< V V V', substr($idx, $p, 48)); $p += 80;
    next if defined $re && $name !~ /$re/i;
    seek($fh, $off, 0); read($fh, my $d, $csz + 8);
    my $data;
    if ($comp == 2) {
        die "$name: pas de PKGB\n" unless substr($d, 0, 4) eq 'PKGB';
        $data = lz4frame(substr($d, 4));
    } else { $data = substr($d, 4, $usz); }
    warn sprintf("%s: taille %d != %d\n", $name, length($data), $usz) if length($data) != $usz;
    warn "$name: CRC incorrect\n" if crc32($data) != $c2;
    (my $path = "$out/$name") =~ s{\\}{/}g;
    (my $dir = $path) =~ s{/[^/]*$}{};
    system('mkdir', '-p', $dir) unless -d $dir;
    open(my $o, '>:raw', $path) or die "$path: $!"; print $o $data; close $o; $n++;
}
print STDERR "$n fichiers extraits\n";

my @crct;
sub crc32 {
    @crct = map { my $c = $_; $c = ($c & 1) ? (0xEDB88320 ^ ($c >> 1)) : ($c >> 1) for 1..8; $c } 0..255 unless @crct;
    my $c = 0xFFFFFFFF; $c = $crct[($c ^ $_) & 255] ^ ($c >> 8) for unpack('C*', $_[0]); $c ^ 0xFFFFFFFF
}

sub lz4frame {
    my ($s) = @_;
    die "magic LZ4 invalide\n" unless unpack('V', $s) == 0x184D2204;
    my $flg = ord(substr($s, 4, 1)); my $q = 6;
    $q += 8 if $flg & 0x08; $q += 4 if $flg & 0x01; $q += 1;
    my $bchk = $flg & 0x10; my $indep = $flg & 0x20;
    my $out = '';
    while (1) {
        my $bs = unpack('V', substr($s, $q, 4)); $q += 4;
        last if $bs == 0;
        my $raw = $bs & 0x80000000; $bs &= 0x7fffffff;
        if ($raw) { $out .= substr($s, $q, $bs); }
        else { lz4block(\$s, $q, $bs, \$out, $indep ? length($out) : 0); }
        $q += $bs; $q += 4 if $bchk;
    }
    return $out;
}
sub lz4block {
    my ($sr, $q, $len, $or, $base) = @_;
    my $end = $q + $len;
    while ($q < $end) {
        my $t = ord(substr($$sr, $q++, 1));
        my $ll = $t >> 4;
        if ($ll == 15) { my $b; do { $b = ord(substr($$sr, $q++, 1)); $ll += $b } while $b == 255; }
        $$or .= substr($$sr, $q, $ll); $q += $ll;
        last if $q >= $end;
        my $o = unpack('v', substr($$sr, $q, 2)); $q += 2;
        my $ml = ($t & 15);
        if ($ml == 15) { my $b; do { $b = ord(substr($$sr, $q++, 1)); $ml += $b } while $b == 255; }
        $ml += 4;
        my $st = length($$or) - $o;
        if ($o >= $ml) { $$or .= substr($$or, $st, $ml); }
        else { my $pat = substr($$or, $st, $o); $$or .= substr($pat x (int($ml / $o) + 1), 0, $ml); }
    }
}
