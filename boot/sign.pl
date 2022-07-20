#!/usr/bin/perl

open(BB, $ARGV[0]) || die "open $ARGV[0]: $!";

binmode BB;
my $buf;
read(BB, $buf, 1000);
$n = length($buf);

if($n > 510){
	print STDERR "boot block too large: $n bytes (max 510)\n";
	exit 1;
}

print STDERR "boot block is $n bytes (max 510)\n";

# pad 0 for 512 byte as mbr block, the end two is \x55\xAA
$buf .= "\0" x (510-$n);
$buf .= "\x55\xAA";

open(BB, ">$ARGV[0]") || die "open >$ARGV[0]: $!";
binmode BB;
print BB $buf;
close BB;
