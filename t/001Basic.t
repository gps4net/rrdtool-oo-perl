
use Test::More qw(no_plan);
use RRDTool::OO;

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level => $DEBUG, layout => "%L: %m%n", 
#                          file => 'stdout'});

my $rrd;

######################################################################
    # constructor missing mandatory parameter
eval { $rrd = RRDTool::OO->new(); };
like($@, qr/Mandatory parameter 'file' not set/, "new without file");

    # constructor featuring illegal parameter
eval { $rrd = RRDTool::OO->new( file => 'file', foobar => 'abc' ); };
like($@, qr/Illegal parameter 'foobar' in new/, "new with illegal parameter");

    # Legal constructor
$rrd = RRDTool::OO->new( file => 'foo' );

######################################################################
    # create missing everything
eval { $rrd->create(); };
like($@, qr/Mandatory parameter/, "create missing everything");

    # create missing data_source
eval { $rrd->create( archive => {} ); };
like($@, qr/Mandatory parameter/, "create missing data_source");

    # create missing archive
eval { $rrd->create( data_source => {} ); };
like($@, qr/Mandatory parameter/, "create missing archive");

    # create missing heartbeat
eval { $rrd->create(
    data_source => { name      => 'foobar',
                     type      => 'foo',
                     # heartbeat => 10,
                   },
    archive     => { cf    => 'abc',
                     xff   => '0.5',
                     steps => 5,
                     rows  => 10,
                   },
) };

like($@, qr/Mandatory parameter/, "create missing hearbeat");

    # legal create
my $rc = $rrd->create(
    start     => time() - 3600,
    step      => 10,
    data_source => { name      => 'foobar',
                     type      => 'GAUGE',
                     heartbeat => 100,
                   },
    archive     => { cf    => 'MAX',
                     xff   => '0.5',
                     steps => 1,
                     rows  => 100,
                   },
);

is($rc, 1, "create ok");
ok(-f "foo", "RRD exists");

######################################################################

for(my $i=100; $i >= 0; $i -= 5) {
    my $time  = time() - $i;
    my $value = 1000 + $i;
    ok($rrd->update(value => $value, time => $time), "update $time:$value");
}

$rrd->fetch_start(start => time() - 100, cf => 'MAX');
$rrd->fetch_skip_undef();
my $count = 0;
while(my $val = $rrd->fetch_next()) {
    $count++;
}
is($count, 10, "10 items found");

END { unlink('foo'); }