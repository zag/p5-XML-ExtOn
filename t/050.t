use Test::More qw( no_plan);
use strict;
use warnings;

BEGIN {
    use_ok 'XML::Handler::ExtOn';
    use_ok 'XML::Filter::SAX1toSAX2';
    use_ok 'XML::Parser::PerlSAX';
    use_ok 'XML::SAX::Writer';
}
my $str1;
my $w1          = XML::SAX::Writer->new( Output         => \$str1 );
my $psax_filter = MyHandler->new( Handler               => $w1 );
my $sax2_filter = XML::Filter::SAX1toSAX2->new( Handler => $psax_filter );
my $parser      = XML::Parser::PerlSAX->new( Handler    => $sax2_filter );
my $xml         = &return_xml();
my $result = $parser->parse( Source => { String => "$xml" } );
diag $str1;
exit;

sub return_xml {
    return <<EOT;
<?xml version="1.0"?>
<Document xmlns="http://test.com/defaultns" xmlns:nodef='http://zag.ru' xmlns:xlink='http://www.w3.org/1999/xlink'>
    <nodef:p xlink:xtest="1" attr="1">test</nodef:p>
    <p defaulttest="1" xlink:attr="1" xlink:attr2="1">test</p>
</Document>
EOT
}

package MyHandler;
use Data::Dumper;
use strict;
use warnings;
use base 'XML::Handler::ExtOn';

sub on_start_element {
    my ( $self, $elem ) = @_;
    warn Dumper($elem);
#    warn Dumper(
#        { 'Element' => ref $elem, '*:xml' => $elem->attrs_by_prefix('xlink'), 'attr'=>$elem->{__attrs} }
#    );
    return $elem;
}
