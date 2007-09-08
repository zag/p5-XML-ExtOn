use Test::More qw( no_plan);
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok 'XML::PSAX::Element';
    use_ok 'XML::NamespaceSupport';
}

=pod
<?xml version="1.0"?>
<Document xmlnsw="http://test.com/defaultns" xmlns:nodef='http://zag.ru' xmlns:xlink='http://www.w3.org/1999/xlink'>
    <nodef:p xlink:xtest="1" attr="1">test</nodef:p>
    <p defaulttest="1" xlink:attr="1">test</p>
</Document>

=cut

my $ns1 = new XML::NamespaceSupport:: { xmlns => 1, fatal_errors => 0 };
diag $ns1;
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
my ( $prefix1, $uri1 ) = ( 'xlink', 'http://www.w3.org/1999/xlink' );
$ns1->declare_prefix( $prefix1, $uri1 );
diag $ns1->get_uri('xlink');
$ns1->declare_prefix( 'test', 'http://www.w3.org/TR/REC-html40' );
diag $ns1->get_uri('test');
my $element = new XML::PSAX::Element::
  name  => "p",
  xmlns => $ns1;
$element->attrs_from_sax2($t1_elemnt->{Attributes});
ok my $ref_by_pref = $element->attrs_by_prefix($prefix1), "get attr by prefix: $prefix1";
$ref_by_pref->{test} = 1;
ok my $ref_by_uri = $element->attrs_by_ns_uri($uri1), "get attr by uri: $uri1";
is_deeply $ref_by_pref,$ref_by_uri,'check by pref and by uri';
#diag Dumper($ref_by_pref);

#diag Dumper ( (tied %{$ref_by_pref} )->_orig_hash );

