#!/usr/bin/perl
# Chiffre/dechiffre les fichiers Lua de TT3/Common/Settings/DUMMY*.DAT (XOR symetrique,
# PlayAll::Core::VirtualFile::EncryptDecrypt). Le meme appel fait les deux sens.
# usage: settings_crypt.pl ENTREE SORTIE
#   DUMMYS.DAT  = config moteur (table Engine, dont Engine.UsePkg / Engine.AllowMenuDebug)
#   DUMMYCM.DAT = mapping des chunks PKG ; DUMMYCL.DAT = ContentLocks
use strict; use warnings;
my ($in, $out) = @ARGV; die "usage: $0 entree sortie\n" unless $out;
my @k = unpack('C*', '14F5FsyDFFUC4NVANPpYggyakreWkJfy');
open(my $f, '<:raw', $in) or die "$in: $!"; local $/; my $d = <$f>; close $f;
my $i = 0; $d =~ s/(.)/chr(ord($1) ^ $k[$i++ & 31])/ges;
open(my $o, '>:raw', $out) or die "$out: $!"; print $o $d; close $o;
