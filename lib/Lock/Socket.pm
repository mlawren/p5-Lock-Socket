package Lock::Socket::Mo;

BEGIN {
#<<< Do not perltidy this
# use Mo qw'build builder default import required';
#   The following line of code was produced from the previous line by
#   Mo::Inline version 0.39
no warnings;my$M=__PACKAGE__.'::';*{$M.Object::new}=sub{my$c=shift;my$s=bless{@_},$c;my%n=%{$c.::.':E'};map{$s->{$_}=$n{$_}->()if!exists$s->{$_}}keys%n;$s};*{$M.import}=sub{import warnings;$^H|=1538;my($P,%e,%o)=caller.'::';shift;eval"no Mo::$_",&{$M.$_.::e}($P,\%e,\%o,\@_)for@_;return if$e{M};%e=(extends,sub{eval"no $_[0]()";@{$P.ISA}=$_[0]},has,sub{my$n=shift;my$m=sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}};@_=(default,@_)if!($#_%2);$m=$o{$_}->($m,$n,@_)for sort keys%o;*{$P.$n}=$m},%e,);*{$P.$_}=$e{$_}for keys%e;@{$P.ISA}=$M.Object};*{$M.'build::e'}=sub{my($P,$e)=@_;$e->{new}=sub{$c=shift;my$s=&{$M.Object::new}($c,@_);my@B;do{@B=($c.::BUILD,@B)}while($c)=@{$c.::ISA};exists&$_&&&$_($s)for@B;$s}};*{$M.'builder::e'}=sub{my($P,$e,$o)=@_;$o->{builder}=sub{my($m,$n,%a)=@_;my$b=$a{builder}or return$m;my$i=exists$a{lazy}?$a{lazy}:!${$P.':N'};$i or ${$P.':E'}{$n}=\&{$P.$b}and return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$_[0]->$b:$m->(@_)}}};*{$M.'default::e'}=sub{my($P,$e,$o)=@_;$o->{default}=sub{my($m,$n,%a)=@_;exists$a{default}or return$m;my($d,$r)=$a{default};my$g='HASH'eq($r=ref$d)?sub{+{%$d}}:'ARRAY'eq$r?sub{[@$d]}:'CODE'eq$r?$d:sub{$d};my$i=exists$a{lazy}?$a{lazy}:!${$P.':N'};$i or ${$P.':E'}{$n}=$g and return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$g->(@_):$m->(@_)}}};my$i=\&import;*{$M.import}=sub{(@_==2 and not$_[1])?pop@_:@_==1?push@_,grep!/import/,@f:();goto&$i};*{$M.'required::e'}=sub{my($P,$e,$o)=@_;$o->{required}=sub{my($m,$n,%a)=@_;if($a{required}){my$C=*{$P."new"}{CODE}||*{$M.Object::new}{CODE};no warnings 'redefine';*{$P."new"}=sub{my$s=$C->(@_);my%a=@_[1..$#_];if(!exists$a{$n}){require Carp;Carp::croak($n." required")}$s}}$m}};@f=qw[build builder default import required];use strict;use warnings;
    $INC{'Lock/Socket/Mo.pm'} = __FILE__;
}
1;
package Lock::Socket::Error;
use Lock::Socket::Mo;
use overload '""' => sub { $_[0]->msg }, fallback => 1;
use Carp ();

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

our @VERSION = '0.0.1_2';

@Lock::Socket::Error::Bind::ISA   = ('Lock::Socket::Error');
@Lock::Socket::Error::Socket::ISA = ('Lock::Socket::Error');

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

# Unset close-on-exec?
# $^F = 10;

has _inet_addr => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        return inet_aton( $self->addr );
    },
);

has _sock => (
    is      => 'ro',
    lazy    => 0,
    builder => '_sock_builder',
);

sub _sock_builder {
    my $self = shift;
    socket( my $sock, PF_INET, SOCK_STREAM, getprotobyname('tcp') )
      || Carp::croak( $self->err( 'Socket', "socket: $!" ) );
    return $sock;
}

has _is_locked => (
    is      => 'rw',
    lazy    => 0,
    default => sub { 0 },
);

sub err {
    my $self = shift;
    my $class = 'Lock::Socket::Error::'.$_[0];
    return $class->new( msg => $_[1] );
}

sub is_locked {
    $_[0]->_is_locked;
}

sub lock {
    my $self = shift;
    return 1 if $self->_is_locked;

    bind( $self->_sock, pack_sockaddr_in( $self->port, $self->_inet_addr ) )
      || Carp::croak( $self->err ( 'Bind', "bind: $!" ) );

    $self->_is_locked(1);
}

sub try_lock {
    my $self = shift;
    return eval { $self->lock } || 0;
}

sub unlock {
    my $self = shift;
    return 1 unless $self->_is_locked;
    close( $self->_sock );
    $self->_sock($self->_sock_builder);
    $self->_is_locked(0);
    return 1;
}

sub DESTROY {
    $_[0]->unlock;
}

1;




=head1 NAME

Lock::Socket - application lock/mutex module based on sockets

=head1 VERSION

0.0.1_2 (yyyy-mm-dd) development release.

=head1 SYNOPSIS

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
    my $status = $sock2->try_lock;

    # You can manually unlock
    $sock->unlock;
    # ... or unlocking is automatic on scope exit
    undef $sock;

    ### Function API
    use Lock::Socket qw/lock_socket try_lock_socket/;

    # Fails if cannot lock
    my $lock = lock_socket(15151);

    # Or just return undef
    my $lock2 = try_lock_socket(15151) or
        die "handle your own error";

=head1 DESCRIPTION

B<Lock::Socket> provides cooperative inter-process locking for
applications that need to ensure that only one process is running at a
time.  This module works by binding to a socket on a loopback (127/8)
address/port combination, which the operating system conveniently
restricts to a single process.

    Lock::Socket->new(
        port => $PORT, # required
        addr => $ADDR, # defaults to 127.X.Y.1
    );

For the constructor C<port> is required, and on most systems needs to
be greater than 1024 unless you are running as root. If C<addr> is not
given then it is calculated as follows, which provides automatic
per-user namespacing up to a maximum user ID of 65536:

    Octet   Value
    ------  ------------------------------
    1       127
    2       First byte of user ID
    3       Second byte of user ID
    4       1

If you want a system-wide namespace you can manually specify the
address as well as the required port number.

As soon as the B<Lock::Socket> object goes out of scope the port is
closed and the lock can be obtained by someone else.

=head1 SEE ALSO

There are many other locking modules available on CPAN, but most of
them use some kind of file or flock-based locking with various issues.

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

