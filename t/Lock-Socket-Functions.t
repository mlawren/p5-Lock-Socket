use strict;
use warnings;
use Lock::Socket qw/lock_socket try_lock_socket/;
use Test::More;
use Test::Fatal;

my $PORT1 = 14414;
my $PORT2 = 24414;

# Now take a lock
my $sock = lock_socket($PORT1);
isa_ok $sock, 'Lock::Socket';

is $sock->is_locked, 1, 'new is locked';
is $sock->unlock,    1, 'unlock still ok';
is $sock->lock,      1, 're-lock ok';

# Cannot take the same lock
my $e = exception {
    lock_socket($PORT1);
};
isa_ok $e, 'Lock::Socket::Error::Bind', $e;

# Can try to take the lock
is( try_lock_socket($PORT1), 0, 'try fail' );

# But can take a different lock port
my $sock2 = lock_socket($PORT2);
isa_ok $sock2, 'Lock::Socket';
is $sock2->is_locked, 1, 'lock 2';

# And can get it by trying
$sock2 = undef;
$sock2 = try_lock_socket($PORT2);
isa_ok $sock2, 'Lock::Socket';
is $sock2->is_locked, 1, 'try_lock 2';

# We can also take the same port at a different address
my $sock3 = try_lock_socket( $PORT2, '127.0.0.2' );
is $sock3->is_locked, 1, 'lock 3';

# But we can't take that lock again either
$e = exception {
    lock_socket( $PORT2, '127.0.0.2' )->lock;
};
isa_ok $e, 'Lock::Socket::Error::Bind', $e;

# Confirm that a lock disappears with the object
undef $sock;
my $sock4 = lock_socket($PORT1);
is $sock4->lock, 1, 'lock 4';

done_testing();
