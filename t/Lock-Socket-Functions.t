use strict;
use warnings;
use Lock::Socket qw/lock_socket try_lock_socket uid_ip uid_port/;
use Test::More;
use Test::Fatal;

my $e = exception {
    lock_socket();
};
isa_ok $e, 'Lock::Socket::Error::Usage';

$e = exception {
    try_lock_socket();
};
isa_ok $e, 'Lock::Socket::Error::Usage';

$e = exception {
    Lock::Socket->import('unknown');
};
isa_ok $e, 'Lock::Socket::Error::Import';

like uid_ip, qr/^127\.(\d+)\.(\d+)\.1$/, 'uid_ip gives ' . uid_ip;
is uid_port(1), 1 + $<, 'uid_port adds UID';

my $PORT1 = 14414 + int( rand(1000) );
my $PORT2 = 24414 + int( rand(1000) );

# Now take a lock
my $sock = lock_socket($PORT1);
isa_ok $sock, 'Lock::Socket';

is $sock->is_locked, 1, 'new is locked';
is $sock->unlock,    1, 'unlock still ok';
is $sock->lock,      1, 're-lock ok';

# Cannot take the same lock
$e = exception {
    lock_socket($PORT1);
};
isa_ok $e, 'Lock::Socket::Error::Bind';

# Can try to take the lock
is( try_lock_socket($PORT1), undef, 'try fail' );

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

# 127.0.0.2 doesn't exist on BSDs
if ($sock3) {
    is $sock3->is_locked, 1, 'lock 3';

    # But we can't take that lock again either
    $e = exception {
        lock_socket( $PORT2, '127.0.0.2' )->lock;
    };
    isa_ok $e, 'Lock::Socket::Error::Bind';
}

# Confirm that a lock disappears with the object
undef $sock;
my $sock4 = lock_socket($PORT1);
is $sock4->lock, 1, 'lock 4';

done_testing();
