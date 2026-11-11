#!/usr/bin/perl
# Masque (ou restaure) une entree dans l'index d'un PPKG en remplacant le 1er caractere
# de son nom par '#'. Le moteur cherche les fichiers par nom : une entree masquee n'est
# plus trouvee dans le PKG et le fichier "en vrac" du meme chemin (TT3/WIN32/... ou
# TT3/Common/...) est utilise a la place. Modifie le PKG sur place (1 octet) : reversible.
# usage: pkghide.pl FILE.PKG 'WIN32\LEVELS\...\X.PLM' [--restore]
use strict; use warnings;
my ($f, $want, $opt) = @ARGV; die "usage: $0 file.pkg nom [--restore]\n" unless $want;
my $restore = defined $opt && $opt eq '--restore';
$want =~ s{/}{\\}g; $want = uc $want;
(my $hidden = $want) =~ s/^./#/;
open(my $fh, '+<:raw', $f) or die "$f: $!";
read($fh, my $h, 0x30);
my ($magic, $ver, $count, $isize) = unpack('a4 V V V', $h);
die "pas un PPKG\n" unless $magic eq 'PPKG';
read($fh, my $idx, $isize);
my $p = 0;
for (1..$count) {
    my $nl = unpack('V', substr($idx, $p, 4));
    my $name = substr($idx, $p + 4, $nl);
    if ($name eq ($restore ? $hidden : $want)) {
        seek($fh, 0x30 + $p + 4, 0);
        print $fh ($restore ? substr($want, 0, 1) : '#');
        close $fh; print(($restore ? "restaure" : "masque"), ": $want\n"); exit 0;
    }
    $p += 4 + $nl + 80;
}
die "entree introuvable: " . ($restore ? $hidden : $want) . "\n";
