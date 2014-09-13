use strict;
use warnings;
use Lock::Socket;
use Test::More;
use Test::Fatal;

# First of all test the Error class
my $error = Lock::Socket::Error->new( msg => 'usage error' );
isa_ok $error , 'Lock::Socket::Error';
is "$error", 'usage error', 'error stringification';

like exception { Lock::Socket->new }, qr/required/, 'required attributes';

my $PORT1 = 14414;
my $PORT2 = 24414;

# Now take a lock
my $sock = Lock::Socket->new( port => $PORT1 );
isa_ok $sock, 'Lock::Socket';

ok !$sock->is_locked, 'new not locked';
ok $sock->lock,      'lock';
ok $sock->is_locked, 'is_locked';
ok $sock->lock,      'lock ok when locked';
ok $sock->unlock,    'unlock ok';
ok $sock->unlock,    'unlock still ok';
ok $sock->lock,      're-lock ok';

# Cannot take the same lock
my $e = exception {
    Lock::Socket->new( port => $PORT1 )->lock;
};
isa_ok $e, 'Lock::Socket::Error::Bind', $e;

# Can try to take the lock
ok !Lock::Socket->new( port => $PORT1 )->try_lock;

# But can take a different lock port
my $sock2 = Lock::Socket->new( port => $PORT2 );
ok $sock2->lock, 'lock 2';

# And can get it by trying
$sock2 = undef;
$sock2 = Lock::Socket->new( port => $PORT2 );
ok $sock2->try_lock, 'try_lock 2';

# We can also take the same port at a different address
my $sock3 = Lock::Socket->new( port => $PORT2, addr => '127.0.0.2' );
ok $sock3->lock, 'lock 3';

# But we can't take that lock again either
$e = exception {
    Lock::Socket->new(
        port => $PORT2,
        addr => '127.0.0.2'
    )->lock;
};
isa_ok $e, 'Lock::Socket::Error::Bind', $e;

# Confirm that a lock disappears with the object
undef $sock;
my $sock4 = Lock::Socket->new( port => $PORT1 );
ok $sock4->lock, 'lock 4';

done_testing();
