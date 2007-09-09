package XML::Handler::ExtOn::Element;
use strict;
use warnings;

use XML::NamespaceSupport;
use Carp;
use Data::Dumper;
use XML::Handler::ExtOn::TieAttrs;

sub new {
    my ( $class, %attr ) = @_;
    my $self = bless {}, $class;
    my $name = $attr{name};
    my $attr = {};
    if ( $attr{sax2} ) {
        $attr =
          &XML::Handler::ExtOn::TieAttrs::attr_from_sax2( $attr{sax2}->{Attributes} );
        my $sax2_attr = $attr{sax2} || {};
        $name ||= $sax2_attr->{Name};
        warn Dumper($attr);
    }
    $self->{__xmlns} = $attr{xmlns} || die "not exists xmlns parametr";
    $self->_set_name($name);
    $self->{__attrs} = $attr;
    return $self;
}

sub _set_name {
    my $self = shift;
    $self->{__name} = shift || return $self->{__name};
}

sub set_prefix {
    my $self = shift;
    $self->{__prefix} = shift if @_;
    $self->{__prefix}
}

sub set_ns_uri {
    my $self = shift;
    $self->{__ns_iri} = shift if @_;
    $self->{__ns_iri}
}

sub name {
    return $_[0]->_set_name();
}

sub attrs_from_sax2 {
    my $self = shift;
    my $attr = &XML::Handler::ExtOn::TieAttrs::attr_from_sax2(shift);
    $self->{__attrs} = $attr;
}
sub attrs_to_sax2 {
    my $self = shift;
    $self->{__attrs}
}
sub attrs_by_prefix {
    my $self   = shift;
    my $prefix = shift;
    my %hash   = ();
    my $ns_uri = $self->{__xmlns}->get_uri($prefix)
      or die "get_uri($prefix) return undef";
    tie %hash, 'XML::Handler::ExtOn::TieAttrs', $self->{__attrs},
      by       => 'Prefix',
      value    => $prefix,
      template => {
        Value        => '',
        NamespaceURI => $ns_uri,
        Name         => '',
        LocalName    => '',
        Prefix       => ''
      };
    return \%hash;
}

sub attrs_by_ns_uri {
    my $self   = shift;
    my $ns_uri = shift;
    my %hash   = ();
    my $prefix = $self->{__xmlns}->get_prefix($ns_uri)
      or die "get_prefix($ns_uri) return undef";
    tie %hash, 'XML::Handler::ExtOn::TieAttrs', $self->{__attrs},
      by       => 'Prefix',
      value    => $prefix,
      template => {
        Value        => '',
        NamespaceURI => $ns_uri,
        Name         => '',
        LocalName    => '',
        Prefix       => ''
      };
    return \%hash

}
1;
