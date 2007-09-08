use Test::More qw( no_plan);
use strict;
use warnings;
BEGIN {
    use_ok 'XML::PSAX';
    use_ok 'XML::Filter::SAX1toSAX2';
    use_ok('XML::Filter::PSAXtoSAX2');
    use_ok 'XML::Parser::PerlSAX';
    use_ok 'XML::SAX::Writer';
    use_ok 'XML::Filter::SAX2toPSAX';
}
my $str1;
my $w1           = XML::SAX::Writer->new( Output         => \$str1 );
my $psax2sax2_filter  = XML::Filter::PSAXtoSAX2->new( Handler => $w1 );
my $psax_filter  = XML::Filter::SAX2toPSAX->new( Handler => $psax2sax2_filter );
my $sax2_filter = XML::Filter::SAX1toSAX2->new( Handler => $psax_filter );
my $parser      = XML::Parser::PerlSAX->new( Handler    => $sax2_filter );
my $xml         = &return_xml();
my $result = $parser->parse( Source => { String => "$xml" } );
diag $str1;
exit;
my $str;
my $w = XML::SAX::Writer->new( Output => \$str );
my $site_parser = $w;
$site_parser->start_document;
$site_parser->start_prefix_mapping(
    { Prefix => 'xlink', NamespaceURI => 'http://www.w3.org/1999/xlink' } );
$site_parser->start_prefix_mapping(
    { Prefix => '', NamespaceURI => 'http://zag.ru' } );
$site_parser->start_element( { Name => "Document" } );
$site_parser->start_element( { Name=>"p",});
$site_parser->characters({Data=>"test"});    
$site_parser->end_element( { Name=>"p"});
$site_parser->end_element( { Name => "Document" } );
$site_parser->end_document;
#diag $str;

sub return_xml {
 return <<EOT;
<?xml version="1.0"?>
<Document xmlns="http://test.com/defaultns" xmlns:nodef='http://zag.ru' xmlns:xlink='http://www.w3.org/1999/xlink'>
    <nodef:p xlink:xtest="1" attr="1">test</nodef:p>
    <p defaulttest="1" xlink:attr="1" xlink:attr2="1">test</p>
</Document>
EOT
}

