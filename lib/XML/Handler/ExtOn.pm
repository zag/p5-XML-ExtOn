package XML::Handler::ExtOn;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use XML::NamespaceSupport;
use XML::SAX::Base;
use XML::Handler::ExtOn::Element;
use base 'XML::SAX::Base';
use vars qw( $AUTOLOAD);

sub start_document {
    my ( $self, $document ) = @_;
    $self->{__xmlns} = XML::NamespaceSupport->new( { xmlns => 1 } );
    $self->SUPER::start_document($document);
}

sub mk_element {
    my $self = shift;
    my $name = shift;
    my %args = @_;
    my $elem = new XML::Handler::ExtOn::Element::
      name  => $name,
      %args,
      xmlns => $self->{__xmlns};
    return $elem;
}

sub __mk_element_from_sax2 {
    my $self = shift;
    my $data = shift;
    my $elem = $self->mk_element( $data->{LocalName}, sax2=> $data );
    return $elem;
}

sub __exp_element_to_sax2 {
    my $self = shift;
    my $elem = shift;
    my $data = {
        Prefix     => $elem->set_prefix,
        LocalName  => $elem->local_name,
        Attributes => $elem->attrs_to_sax2,
        Name       => $elem->set_prefix
        ? $elem->set_prefix() . ":" . $elem->name
        : $elem->name,
        NamespaceURI => $elem->set_ns_uri,
    };
    return $data;
}

sub start_element {
    my $self = shift;
    my $data = shift;
    $self->{__xmlns}->push_context;
    return $self->SUPER::start_element($data)
      unless $self->can('on_start_element');
    my $elem     = $self->__mk_element_from_sax2($data);
    my $res_element = $self->on_start_element($elem);
    my $res_data = $self->__exp_element_to_sax2($res_element);
    return $self->SUPER::start_element($res_data);
}

sub AUTOLOAD {
    my $self = shift;
    my $data = shift;
    my $call = $AUTOLOAD;
    $call =~ s/^.*:://;
    return if $call eq 'DESTROY';

    #    warn Dumper($data);
    $call = "SUPER::$call";
    return $self->$call($data);
}
1;
