package Lock::Socket::Mo;

#<<< Do not perltidy this
BEGIN {
# use Mo qw'builder default import required';
#   The following line of code was produced from the previous line by
#   Mo::Inline version 0.39
no warnings;my$M=__PACKAGE__.'::';*{$M.Object::new}=sub{my$c=shift;my$s=bless{@_},$c;my%n=%{$c.::.':E'};map{$s->{$_}=$n{$_}->()if!exists$s->{$_}}keys%n;$s};*{$M.import}=sub{import warnings;$^H|=1538;my($P,%e,%o)=caller.'::';shift;eval"no Mo::$_",&{$M.$_.::e}($P,\%e,\%o,\@_)for@_;return if$e{M};%e=(extends,sub{eval"no $_[0]()";@{$P.ISA}=$_[0]},has,sub{my$n=shift;my$m=sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}};@_=(default,@_)if!($#_%2);$m=$o{$_}->($m,$n,@_)for sort keys%o;*{$P.$n}=$m},%e,);*{$P.$_}=$e{$_}for keys%e;@{$P.ISA}=$M.Object};*{$M.'builder::e'}=sub{my($P,$e,$o)=@_;$o->{builder}=sub{my($m,$n,%a)=@_;my$b=$a{builder}or return$m;my$i=exists$a{lazy}?$a{lazy}:!${$P.':N'};$i or ${$P.':E'}{$n}=\&{$P.$b}and return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$_[0]->$b:$m->(@_)}}};*{$M.'default::e'}=sub{my($P,$e,$o)=@_;$o->{default}=sub{my($m,$n,%a)=@_;exists$a{default}or return$m;my($d,$r)=$a{default};my$g='HASH'eq($r=ref$d)?sub{+{%$d}}:'ARRAY'eq$r?sub{[@$d]}:'CODE'eq$r?$d:sub{$d};my$i=exists$a{lazy}?$a{lazy}:!${$P.':N'};$i or ${$P.':E'}{$n}=$g and return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$g->(@_):$m->(@_)}}};my$i=\&import;*{$M.import}=sub{(@_==2 and not$_[1])?pop@_:@_==1?push@_,grep!/import/,@f:();goto&$i};*{$M.'required::e'}=sub{my($P,$e,$o)=@_;$o->{required}=sub{my($m,$n,%a)=@_;if($a{required}){my$C=*{$P."new"}{CODE}||*{$M.Object::new}{CODE};no warnings 'redefine';*{$P."new"}=sub{my$s=$C->(@_);my%a=@_[1..$#_];if(!exists$a{$n}){require Carp;Carp::croak($n." required")}$s}}$m}};@f=qw[builder default import required];use strict;use warnings;
$INC{'Lock/Socket/Mo.pm'} = __FILE__;
}
1;
#>>>

package Lock::Socket::Error;
use Lock::Socket::Mo;
use overload '""' => sub { $_[0]->msg }, fallback => 1;

has msg => (
    is       => 'ro',
    required => 1,
);

1;

package Lock::Socket;
use strict;
use warnings;
use Carp ();
use Lock::Socket::Mo;
use Socket;

our @VERSION = '0.0.3_2';

@Lock::Socket::Error::Bind::ISA   = ('Lock::Socket::Error');
@Lock::Socket::Error::Socket::ISA = ('Lock::Socket::Error');
@Lock::Socket::Error::Usage::ISA  = ('Lock::Socket::Error');
@Lock::Socket::Error::Import::ISA = ('Lock::Socket::Error');

sub import {
    my $class  = shift;
    my $caller = caller;
    no strict 'refs';

    foreach my $token (@_) {
        if ( $token eq 'lock_socket' ) {
            *{ $caller . '::lock_socket' } = sub {
                my $port = shift
                  || __PACKAGE__->err( 'Usage', 'usage: lock_socket($PORT)' );
                my $addr = shift;
                my $sock = Lock::Socket->new(
                    port => $port,
                    defined $addr ? ( addr => $addr ) : (),
                );
                $sock->lock;
                return $sock;
            };
        }
        elsif ( $token eq 'try_lock_socket' ) {
            *{ $caller . '::try_lock_socket' } = sub {
                my $port = shift
                  || __PACKAGE__->err( 'Usage',
                    'usage: try_lock_socket($PORT)' );
                my $addr = shift;
                my $sock = Lock::Socket->new(
                    port => $port,
                    defined $addr ? ( addr => $addr ) : (),
                );
                $sock->try_lock;
                return $sock if $sock->_is_locked;
                return undef;
              }
        }
        else {
            __PACKAGE__->err( 'Import',
                'not exported by Lock::Socket: ' . $token );
        }
    }
}

has port => (
    is       => 'ro',
    required => 1,
);

has addr => (
    is      => 'ro',
    default => sub {
        join( '.', 127, unpack( 'C2', pack( "n", $< ) ), 1 );
    },
);

has _inet_addr => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        return inet_aton( $self->addr );
    },
);

has fh => (
    is      => 'ro',
    lazy    => 0,
    builder => '_fh_builder',
);

sub _fh_builder {
    my $self = shift;
    socket( my $fh, PF_INET, SOCK_STREAM, getprotobyname('tcp') )
      || $self->err( 'Socket', "socket: $!" );
    return $fh;
}

has _is_locked => (
    is      => 'rw',
    lazy    => 0,
    default => sub { 0 },
);

sub err {
    my $self  = shift;
    my $class = 'Lock::Socket::Error::' . $_[0];
    die $class->new(
        msg => sprintf( "%s at %s line %d\n", $_[1], ( caller(2) )[ 1, 2 ] ) );
}

sub is_locked {
    $_[0]->_is_locked;
}

sub lock {
    my $self = shift;
    return 1 if $self->_is_locked;

    bind( $self->fh, pack_sockaddr_in( $self->port, $self->_inet_addr ) )
      || $self->err( 'Bind',
        sprintf( 'bind: %s (%s:%d)', $!, $self->addr, $self->port ) );

    $self->_is_locked(1);
}

sub try_lock {
    my $self = shift;
    return eval { $self->lock } || 0;
}

sub unlock {
    my $self = shift;
    return 1 unless $self->_is_locked;
    close( $self->fh );
    $self->fh( $self->_fh_builder );
    $self->_is_locked(0);
    return 1;
}

1;

__END__
=head1 NAME

Lock::Socket - application lock/mutex module based on sockets

=head1 VERSION

0.0.3_2 (yyyy-mm-dd) development release.

=head1 SYNOPSIS

    ### Function API
    use Lock::Socket qw/lock_socket try_lock_socket/;

    # Raises exception if cannot lock
    my $lock = lock_socket(15151);

    # Or just return undef
    my $lock2 = try_lock_socket(15151) or
        die "handle your own error";


    ### Object API
    use Lock::Socket;

    # Create a socket
    my $sock = Lock::Socket->new(port => 15151);

    # Lock or raise an exception
    $sock->lock;

    # Can check its status in case you forgot
    my $status = $sock->is_locked; # 1 (or 0)

    # Re-locking changes nothing
    $sock->lock;

    # New lock on same port fails
    my $sock2 = Lock::Socket->new(port => 15151);
    eval { $sock2->lock }; # exception

    # But trying to get a lock is ok
    my $status = $sock2->try_lock;       # 0
    my $same_status = $sock2->is_locked; # 0

    # If you need the underlying filehandle
    my $fh = $sock->fh;

    # You can manually unlock
    $sock->unlock;
    # ... or unlocking is automatic on scope exit
    undef $sock;

=head1 DESCRIPTION

B<Lock::Socket> provides cooperative inter-process locking for
applications that need to ensure that only one process is running at a
time.  This module works by binding to a port on a loopback (127/8)
address, which the operating system conveniently restricts to a single
process.

Both C<lock_socket> and C<try_lock_socket> take a mandatory port number
and an optional IP address as arguments, and return a B<Lock::Socket>
object on success. C<lock_socket> will raise an exception if the lock
cannot be taken and C<try_lock_socket> will return undef. Objects are
instantiated manually as follows:

    Lock::Socket->new(
        port => $PORT, # required
        addr => $ADDR, # defaults to 127.X.Y.1
    );

On most systems the port number needs to be greater than 1024 unless
you are running as root. If C<addr> is not given then it is calculated
as follows, which provides automatic per-user namespacing up to a
maximum user ID of 65536:

    Octet   Value
    ------  ------------------------------
    1       127
    2       First byte of user ID
    3       Second byte of user ID
    4       1

The calculated address can be read back from C<< $sock->addr >>.  If
you want a system-wide namespace you can manually specify the address
as well as the required port number.

As soon as the B<Lock::Socket> object goes out of scope the port is
closed and the lock can be obtained by someone else.

If you want to keep holding onto a lock socket after a call to C<exec>
(perhaps after forking) read about the C<$^F> variable in L<perlvar>,
as you have to set it B<before> creating a lock socket to ensure the it
will not be closed on exec.  See the F<example/solo> file in the
distribution for a demonstration:

    usage: solo PORT COMMAND...

    # terminal 1
    example solo 1414 sleep 10  # Have lock on 127.3.232.1:1414

    # terminal 2
    example/solo 1414 sleep 10  # bind error

=head1 SEE ALSO

There are many other locking modules available on CPAN, but most of
them use some kind of file or flock-based locking.

=head1 BUGS

At the moment all of the tests fail on FreeBSD systems. Anyone with a
clue or a box to test with please get in touch.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>. This module was inspired by the
L<solo.pl|https://github.com/andres-erbsen/solo> script by Andres
Erbsen.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

