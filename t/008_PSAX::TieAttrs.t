use Test::More qw( no_plan);
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok 'XML::PSAX::TieAttrs';
}
my $t1_elemnt = {
    'Prefix'     => undef,
    'LocalName'  => 'p',
    'Attributes' => {
        '{http://www.w3.org/1999/xlink}attr' => {
            'LocalName'    => 'attr',
            'Prefix'       => 'xlink',
            'Value'        => '1',
            'Name'         => 'xlink:attr',
            'NamespaceURI' => 'http://www.w3.org/1999/xlink'
        },
        '{}defaulttest' => {
            'LocalName'    => 'defaulttest',
            'Prefix'       => undef,
            'Value'        => '1',
            'Name'         => 'defaulttest',
            'NamespaceURI' => undef
        }
    },
    'Name'         => 'p',
    'NamespaceURI' => undef
};
my $attr_converted =
  &XML::PSAX::TieAttrs::attr_from_sax2( $t1_elemnt->{Attributes} );
my %attr_by_name = ();
my $obj = tie %attr_by_name, 'XML::PSAX::TieAttrs', $attr_converted,
  by       => 'Prefix',
  value    => 'xlink',
  template => {
    Value        => '',
    NamespaceURI => 'http://www.w3.org/1999/xlink',
    Name         => '',
    LocalName    => '',
    Prefix       => ''
  };
my $test_attr = 'attr';
my $test_val  = 2;

#diag Dumper( [ keys %attr_by_name ] );
ok $attr_by_name{$test_attr} == 1, "check default value";
$attr_by_name{$test_attr} = $test_val;
ok $attr_by_name{$test_attr} == $test_val, "check set new value";
ok exists $attr_by_name{$test_attr}, "check exists attr_by_name{$test_attr}";
ok !exists $attr_by_name{ $test_attr . "TEST" }, "check not exists test key";
ok delete $attr_by_name{$test_attr} == $test_val,
  'check return value if delete';
ok !exists $attr_by_name{$test_attr}, "check delete";
$attr_by_name{$test_attr} = $test_val;
ok exists $attr_by_name{$test_attr},
  "check exists after create attr_by_name{$test_attr}";
ok $attr_by_name{$test_attr} eq $test_val, "check set value to $test_val";
%attr_by_name = ( attr2 => 123, 'er' => 1 );

my $attr_converted1 =
  &XML::PSAX::TieAttrs::attr_from_sax2( $t1_elemnt->{Attributes} );
my %attr_by_name1 = ();
my $obj1 = tie %attr_by_name1, 'XML::PSAX::TieAttrs', $attr_converted1,
  by       => 'NamespaceURI',
  value    => 'http://www.w3.org/1999/xlink',
  template => {
    Value        => '',
    NamespaceURI => '',
    Name         => '',
    LocalName    => '',
    Prefix       => 'xlink'
  };
is_deeply ['attr'],[ keys %attr_by_name1], "check keys";
