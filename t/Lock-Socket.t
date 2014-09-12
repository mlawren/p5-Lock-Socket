use strict;
use warnings;
use Lock::Socket;
use Test::More;
use Test::Fatal;

# First of all test the Error class
my $error = Lock::Socket::Error->new( 'Usage', 'usage error' );
isa_ok $error , 'Lock::Socket::Error::Usage';
is $error, 'usage error';

isa_ok exception { Lock::Socket::Error->new( 'junk', 'some message' ) },
  'Lock::Socket::Error::Unknown';

isa_ok exception { Lock::Socket->new }, 'Lock::Socket::Error::Usage';

my $PORT1 = 14414;
my $PORT2 = 24414;

# Now take a lock
my $lock = Lock::Socket->new($PORT1);
isa_ok $lock, 'Lock::Socket';

# Cannot take the same lock
isa_ok exception { Lock::Socket->new($PORT1) }, 'Lock::Socket::Error::Bind';

# But can take a different lock port
my $lock2 = Lock::Socket->new($PORT2);
isa_ok $lock2, 'Lock::Socket';

# We can also take the same port at a different address
my $lock3 = Lock::Socket->new( $PORT2, '127.0.0.2' );
isa_ok $lock3, 'Lock::Socket';

# But we can't take that lock again either
isa_ok exception { Lock::Socket->new( $PORT2, '127.0.0.2' ) },
  'Lock::Socket::Error::Bind';

# Confirm that a lock disappears with the object
undef $lock;
my $lock4 = Lock::Socket->new($PORT1);
isa_ok $lock4, 'Lock::Socket';

done_testing();
