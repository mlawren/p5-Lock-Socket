package Lock::Socket;
use strict;
use warnings;
use Carp ();
use Socket;

our @VERSION = '0.0.1_1';

@Lock::Socket::Error::Bind::ISA   = ('Lock::Socket::Error');
@Lock::Socket::Error::Socket::ISA = ('Lock::Socket::Error');
@Lock::Socket::Error::Usage::ISA  = ('Lock::Socket::Error');

sub err {
    return Lock::Socket::Error->new(@_);
}

sub new {
    my ( $class, $port, $addr ) = @_;

    Carp::croak( err ( 'Usage', 'usage: Lock::Socket->new($PORT)' ) )
      unless $port;

    $addr = join( '.', 127, $< % 255, $> % 255, 1 )
      unless $addr;

    socket( my $lock, PF_INET, SOCK_STREAM, getprotobyname('tcp') )
      || Carp::croak( err ( 'Socket', "socket: $!" ) );

    bind( $lock, pack_sockaddr_in( $port, inet_aton($addr) ) )
      || Carp::croak( err ( 'Bind', "bind: $!" ) );

    # Unset close-on-exec?
    # $^F = 10;

    return bless $lock, $class;
}

1;

package Lock::Socket::Error;
use strict;
use warnings;
use overload '""' => sub { ${ $_[0] } }, fallback => 1;
use Carp ();

@Lock::Socket::Error::Unknown::ISA = ('Lock::Socket::Error');

sub new {
    my ( $base, $error, $msg ) = @_;
    my $class = $base . '::' . $error;

    return bless \$msg, $class if $class->isa(__PACKAGE__);
    Carp::croak( __PACKAGE__->new( 'Unknown', 'unknown error' ) );
}

1;

=head1 NAME

Lock::Socket - application lock/mutex module based on sockets

=head1 VERSION

0.0.1_1 (2014-09-13) development release.

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Lock::Socket;

    my $lock = Lock::Socket->new(15151);

    # Fails with an exception
    my $lock2 = Lock::Socket->new(15151);

    # When $lock goes out of scope so does the lock
    undef $lock

    # Now this will succeed
    $lock2 = Lock::Socket->new(15151);

=head1 DESCRIPTION

B<Lock::Socket> provides inter-process locking for applications that
need to ensure only a single process is running or accessing a resource
at any one time.  There are many other locking modules available on
CPAN, but most of them use some kind of file-based locking with various
issues. This module instead works by binding to a socket on a loopback
(127/8) address.

    Lock::Socket->new($PORT, [$ADDRESS]) -> Lock::Socket

For the constructor the C<$PORT> is required, and on most systems
needs to be greater than 1024 unless you are running as root. If
C<$ADDRESS> is not given then it is calculated as follows, which
provides automatic per-user namespacing:

    Octet   Value
    ------  ------------------------------
    1       127
    2       Real user ID, modulo 255
    3       Effective user ID, modulo 255
    4       1

If you want a system-wide namespace you can manually specify the
address as well as the required port number.

As soon as the B<Lock::Socket> object goes out of scope the port is
closed and the lock can be obtained by someone else.

This module is based on the
L<solo.pl|https://github.com/andres-erbsen/solo> script by Andres
Erbsen.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

